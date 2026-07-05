{*********************************************************}
{                                                         }
{       Free Vision - Golden-File Test Session            }
{                                                         }
{       TGoldenSession owns the headless lifecycle and    }
{       gives tests a small API:                          }
{                                                         }
{         StartScreen / TeardownScreen                    }
{         PostKey / PostChar / PostCommand                }
{         Draw (callback that mutates Screen)             }
{         Tick / DrainIdle                                }
{         AdvanceClock (fake-clock helper)                }
{         Snapshot('group\name')                          }
{                                                         }
{       Set FV_UPDATE_GOLDEN=1 to regenerate fixtures     }
{       instead of asserting against them.                }
{                                                         }
{*********************************************************}

unit GoldenHelper;

interface

uses
  System.SysUtils,
  Drivers;

type
  TDrawProc = reference to procedure;

  TGoldenSession = class
  private
    FW, FH: Integer;
    FActive: Boolean;
    FGoldenRoot: string;
    procedure EnsureGoldenRoot;
  public
    constructor Create(W: Integer = 80; H: Integer = 25);
    destructor Destroy; override;

    procedure StartScreen;
    procedure TeardownScreen;

    procedure PostKey(KeyCode: Word; ShiftState: Byte = 0);
    procedure PostChar(Ch: Char);
    procedure PostCommand(Cmd: Word);
    procedure PostMouse(X, Y: Integer; Buttons: Byte; What: Word);

    procedure Draw(const Proc: TDrawProc);
    procedure Tick;
    procedure DrainIdle(MaxTicks: Integer = 50);

    procedure AdvanceClock(DeltaMs: UInt64);
    procedure ResetClock(InitialMs: UInt64 = 0);

    procedure Snapshot(const GoldenName: string);
    procedure SnapshotVTCapture(const GoldenName: string);
    function  CaptureGrid: string;
    function  CaptureCellsJSONL: string;

    property Width:  Integer read FW;
    property Height: Integer read FH;
    property GoldenRoot: string read FGoldenRoot;
  end;

function ShouldUpdateGoldens: Boolean;
function ResolveGoldenRoot: string;

implementation

uses
  System.IOUtils,
  FVHeadless, FVClock, FVScreen,
  GridSerializer;

function ShouldUpdateGoldens: Boolean;
begin
  Result := SameText(GetEnvironmentVariable('FV_UPDATE_GOLDEN'), '1') or
            SameText(GetEnvironmentVariable('FV_UPDATE_GOLDEN'), 'true');
end;

function ResolveGoldenRoot: string;
var
  Dir, Candidate: string;
  I: Integer;
begin
  { Walk up from the test exe directory until we find a sibling 'golden' folder. }
  Dir := ExtractFilePath(ParamStr(0));
  for I := 0 to 8 do begin
    Candidate := IncludeTrailingPathDelimiter(Dir) + 'golden';
    if DirectoryExists(Candidate) then
      Exit(IncludeTrailingPathDelimiter(Candidate));
    Candidate := IncludeTrailingPathDelimiter(Dir) + 'Tests\golden';
    if DirectoryExists(Candidate) then
      Exit(IncludeTrailingPathDelimiter(Candidate));
    Dir := ExtractFilePath(ExcludeTrailingPathDelimiter(Dir));
    if Dir = '' then Break;
  end;
  Result := '';
end;

{ TGoldenSession }

constructor TGoldenSession.Create(W: Integer = 80; H: Integer = 25);
begin
  inherited Create;
  FW := W;
  FH := H;
  FActive := False;
  EnsureGoldenRoot;
end;

destructor TGoldenSession.Destroy;
begin
  if FActive then
    TeardownScreen;
  inherited Destroy;
end;

procedure TGoldenSession.EnsureGoldenRoot;
begin
  FGoldenRoot := ResolveGoldenRoot;
  if FGoldenRoot = '' then
    raise Exception.Create(
      'TGoldenSession: cannot locate Tests\golden directory. ' +
      'Run from Tests\ or a child of it, or commit the golden folder.');
end;

procedure TGoldenSession.StartScreen;
begin
  if FActive then Exit;
  FVHeadless.RequestHeadless(FW, FH);
  { Arm the fake clock at 0 before any widget can stamp a timestamp. Without
    this, a widget created before the test's first ResetClock would capture
    the real GetTickCount64 (~system uptime); a later ResetClock(0) then makes
    "Now - stamp" underflow UInt64 — an EIntOverflow crash in the $Q+ Debug
    build. Starting at a known 0 base keeps all time deterministic. }
  FVClock.ResetFakeClock(0);
  { Capture the VT byte stream so SnapshotVTCapture has something to compare.
    Off by default in headless (FlushVT discards), so without this every VT
    capture would be empty and bless vacuous goldens. }
  FVHeadless.EnableVTCapture;
  { InitVideo allocates Screen + VideoBuf + UnicodeCharBuf etc., honoring
    the headless flag for size and skipping the console-output side. Views
    that call WriteSpanToVideoBuf need these buffers to exist. }
  FVScreen.InitVideo;
  FActive := True;
end;

procedure TGoldenSession.TeardownScreen;
begin
  if not FActive then Exit;
  FVScreen.DoneVideo;
  { Drain any events this test posted but never pumped — the queue is a
    process-global ring buffer, so leftovers would otherwise be delivered to
    the next test and contaminate its snapshot. }
  Drivers.FlushEventQueue;
  FVHeadless.LeaveHeadless;
  FVClock.ClearClockOverride;
  FActive := False;
end;

procedure TGoldenSession.PostKey(KeyCode: Word; ShiftState: Byte = 0);
var
  E: TEvent;
begin
  FillChar(E, SizeOf(E), 0);
  E.What := evKeyDown;
  E.KeyCode := KeyCode;
  E.KeyShift := ShiftState;
  Drivers.PutEventInQueue(E);
end;

procedure TGoldenSession.PostChar(Ch: Char);
var
  E: TEvent;
begin
  FillChar(E, SizeOf(E), 0);
  E.What := evKeyDown;
  E.CharCode := AnsiChar(Ch);
  E.UnicodeChar := Ch;
  Drivers.PutEventInQueue(E);
end;

procedure TGoldenSession.PostCommand(Cmd: Word);
var
  E: TEvent;
begin
  FillChar(E, SizeOf(E), 0);
  E.What := evCommand;
  E.Command := Cmd;
  Drivers.PutEventInQueue(E);
end;

procedure TGoldenSession.PostMouse(X, Y: Integer; Buttons: Byte; What: Word);
var
  E: TEvent;
begin
  FillChar(E, SizeOf(E), 0);
  E.What := What;
  E.Buttons := Buttons;
  E.Where.X := X;
  E.Where.Y := Y;
  Drivers.PutEventInQueue(E);
end;

procedure TGoldenSession.Draw(const Proc: TDrawProc);
begin
  { Don't call the global FVScreen.UpdateScreen here: it runs
    SyncVideoBufToScreen which overwrites Screen.FCells from the legacy
    VideoBuf. A callback that wrote directly via Screen.SetCell would then
    snapshot a blank grid (false positive). Tests that need the VideoBuf
    flush use TViewHarness.RenderAndUpdate, which calls the global update
    after Draw, when the legacy buffer actually contains drawn content. }
  if Assigned(Proc) then Proc();
end;

procedure TGoldenSession.Tick;
var
  E: TEvent;
begin
  Drivers.GetEvent(E);
  { In headless mode GetEvent never blocks; nothing more to pump here.
    Tests that need an Application loop should drive HandleEvent themselves. }
  FVScreen.UpdateScreen(False);
end;

procedure TGoldenSession.DrainIdle(MaxTicks: Integer = 50);
var
  I: Integer;
begin
  for I := 1 to MaxTicks do
    Tick;
end;

procedure TGoldenSession.AdvanceClock(DeltaMs: UInt64);
begin
  FVClock.AdvanceFakeClock(DeltaMs);
  { Non-forced update: a forced update runs SyncVideoBufToScreen from the
    legacy VideoBuf, which would overwrite Screen.FCells and wipe content a
    test wrote directly via Screen.SetCell. A view that redrew itself after
    the clock moved has already marked the VideoBuf dirty, so (False) still
    flushes real animation frames while leaving direct-cell content intact. }
  FVScreen.UpdateScreen(False);
end;

procedure TGoldenSession.ResetClock(InitialMs: UInt64 = 0);
begin
  FVClock.ResetFakeClock(InitialMs);
end;

function TGoldenSession.CaptureGrid: string;
begin
  Result := GridSerializer.CellsToGrid(GridSerializer.SnapshotScreen);
end;

function TGoldenSession.CaptureCellsJSONL: string;
begin
  Result := GridSerializer.CellsToJSONL(GridSerializer.SnapshotScreen);
end;

procedure WriteText(const Path, Content: string);
var
  Bytes: TBytes;
begin
  ForceDirectories(ExtractFilePath(Path));
  Bytes := TEncoding.UTF8.GetBytes(Content);
  TFile.WriteAllBytes(Path, Bytes);
end;

function ReadText(const Path: string): string;
var
  Bytes: TBytes;
begin
  Bytes := TFile.ReadAllBytes(Path);
  Result := TEncoding.UTF8.GetString(Bytes);
end;

procedure TGoldenSession.SnapshotVTCapture(const GoldenName: string);
var
  Capture: string;
  Path, ActualPath: string;
begin
  Capture := FVHeadless.TakeCapture;

  { An empty capture means no VT bytes were emitted — usually the test never
    pumped a frame (Tick/AdvanceClock) or capture was not enabled. Fail loudly
    instead of writing/comparing an empty golden that would pass vacuously. }
  if Capture = '' then
    raise Exception.CreateFmt(
      'SnapshotVTCapture(%s): the captured VT stream is empty. Ensure the ' +
      'screen was updated (Tick/AdvanceClock) after StartScreen enabled capture.',
      [GoldenName]);

  Path := FGoldenRoot + StringReplace(GoldenName, '/', '\', [rfReplaceAll]) + '.vt.txt';

  if ShouldUpdateGoldens then begin
    WriteText(Path, Capture);
    Exit;
  end;

  if (not FileExists(Path)) or (ReadText(Path) <> Capture) then begin
    ActualPath := FGoldenRoot + StringReplace(GoldenName, '/', '\', [rfReplaceAll]) + '.actual.vt.txt';
    WriteText(ActualPath, Capture);
    raise Exception.CreateFmt(
      'VT capture mismatch: %s'#13#10 +
      '  expected: %s'#13#10 +
      '  actual  : %s'#13#10 +
      '  diff    : fc "%s" "%s"',
      [GoldenName, Path, ActualPath, Path, ActualPath]);
  end;
end;

procedure TGoldenSession.Snapshot(const GoldenName: string);
var
  Grid, JSONL: string;
  Base, GridPath, JSONLPath: string;
  ActualGrid, ActualJSONL: string;
  GridOk, JSONLOk: Boolean;
  Msg: string;
begin
  Grid  := CaptureGrid;
  JSONL := CaptureCellsJSONL;

  Base := FGoldenRoot + StringReplace(GoldenName, '/', '\', [rfReplaceAll]);
  GridPath  := Base + '.grid.txt';
  JSONLPath := Base + '.cells.jsonl';

  if ShouldUpdateGoldens then begin
    WriteText(GridPath,  Grid);
    WriteText(JSONLPath, JSONL);
    Exit;
  end;

  GridOk := FileExists(GridPath) and (ReadText(GridPath) = Grid);
  JSONLOk := FileExists(JSONLPath) and (ReadText(JSONLPath) = JSONL);

  if (not GridOk) or (not JSONLOk) then begin
    ActualGrid  := Base + '.actual.grid.txt';
    ActualJSONL := Base + '.actual.cells.jsonl';
    WriteText(ActualGrid,  Grid);
    WriteText(ActualJSONL, JSONL);

    Msg := Format(
      'Golden mismatch: %s'#13#10 +
      '  expected grid : %s'#13#10 +
      '  actual grid   : %s'#13#10 +
      '  expected jsonl: %s'#13#10 +
      '  actual jsonl  : %s'#13#10 +
      '  diff hint     : fc "%s" "%s"',
      [GoldenName, GridPath, ActualGrid, JSONLPath, ActualJSONL, GridPath, ActualGrid]);
    raise Exception.Create(Msg);
  end;
end;

end.
