{*******************************************************}
{       Turbo Pascal App Unit                           }
{       Compatibility layer for Modern Delphi           }
{       Converted to CLASS syntax                       }
{*******************************************************}

unit App;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  Objects, Drivers, Views, Menus, Dialogs, HistList, fvconsts, FVBoxChars, FVCommon;

const
  CBackground = #1;
  CColor = #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0 +
           #0#0#0#0#0#0#0#0;
  CBlackWhite = #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0;
  CMonochrome = #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0 +
                #0#0#0#0#0#0#0#0;
  CAppColor = #$71#$70#$78#$74#$20#$28#$24#$17#$1F#$1A#$31#$31#$1E#$71#$00 +
              #$37#$3F#$3A#$13#$13#$3E#$21#$00#$70#$7F#$7A#$13#$13#$70#$7F#$00 +
              #$70#$7F#$7A#$13#$13#$70#$70#$7F#$7E#$2F#$2B#$2F#$78#$2E#$70#$30 +
              #$3F#$3E#$1F#$2F#$1A#$20#$72#$31#$31#$30#$2F#$3E#$31#$13#$00#$00;
  CAppBlackWhite = #$70#$70#$78#$7F#$07#$07#$0F#$07#$0F#$07#$70#$70#$07#$70#$00 +
                   #$07#$0F#$07#$70#$70#$07#$70#$00#$70#$7F#$7F#$70#$07#$70#$07#$00 +
                   #$70#$7F#$7F#$70#$07#$70#$70#$7F#$7F#$07#$0F#$0F#$78#$0F#$78#$07 +
                   #$0F#$0F#$0F#$70#$0F#$07#$70#$70#$70#$07#$70#$0F#$07#$07#$00#$00;
  CAppMonochrome = #$70#$07#$07#$0F#$70#$70#$70#$07#$0F#$07#$70#$70#$07#$70#$00 +
                   #$07#$0F#$07#$70#$70#$07#$70#$00#$70#$70#$70#$07#$07#$70#$07#$00 +
                   #$70#$70#$70#$07#$07#$70#$70#$70#$0F#$07#$07#$0F#$70#$0F#$70#$07 +
                   #$0F#$0F#$07#$70#$07#$07#$70#$07#$07#$07#$70#$0F#$07#$07#$00#$00;

type
  TBackground = class(TView)
    Pattern: Char;
    constructor Create(var Bounds: TRect; APattern: Char); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure Store(var S: TFVStream);
  end;

  TDesktop = class(TGroup)
    Background: TBackground;
    TileColumnsFirst: Boolean;
    constructor Create(var Bounds: TRect); override;
    constructor Load(var S: TFVStream); override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure InitBackground; virtual;
    function NewBackground(var Bounds: TRect): TBackground; virtual;
    procedure Store(var S: TFVStream);
    procedure TileError; virtual;
    procedure Tile(var R: TRect); virtual;
    procedure TileHorizontal(var R: TRect); virtual;
    procedure TileVertical(var R: TRect); virtual;
    procedure Cascade(var R: TRect); virtual;
    procedure CascadeNoResize(var R: TRect); virtual;
    procedure CloseAll; virtual;
  end;

  TProgram = class(TGroup)
    constructor Create; reintroduce; virtual;
    destructor Destroy; override;
    function ExecuteDialog(P: TDialog; Data: Pointer): Word;
    function GetPalette: PPalette; override;
    procedure GetEvent(var Event: TEvent); override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Idle; virtual;
    procedure InitDesktop; virtual;
    procedure InitMenuBar; virtual;
    procedure InitScreen; virtual;
    procedure InitStatusLine; virtual;
    procedure OutOfMemory; virtual;
    procedure PutEvent(var Event: TEvent); override;
    procedure Run; virtual;
    procedure SetScreenMode(Mode: Word); virtual;
  end;

  TApplication = class(TProgram)
    constructor Create; override;
    destructor Destroy; override;
    procedure Cascade;
    procedure DosShell;
    procedure GetTileRect(var R: TRect); virtual;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Tile;
    procedure TileHorizontal;
    procedure TileVertical;
    procedure CascadeNoResize;
    procedure CloseAll;
    procedure WindowList;
  end;

const
  RBackground: TStreamRec = (ObjType: idBackground; VmtLink: nil; Load: nil; Store: nil);
  RDesktop: TStreamRec = (ObjType: idDesktop; VmtLink: nil; Load: nil; Store: nil);

var
  Application: TProgram;
  Desktop: TDesktop;
  StatusLine: TStatusLine;
  MenuBar: TMenuBar;
  AppPalette: Integer;

procedure RegisterApp;

implementation

uses FVScreen, System.Classes;

{ TBackground }

constructor TBackground.Create(var Bounds: TRect; APattern: Char);
begin
  inherited Create(Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
  Pattern := APattern;
end;

constructor TBackground.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(Pattern, SizeOf(Pattern));
end;

function TBackground.GetPalette: PPalette;
const
  P: String[Length(CBackground)] = CBackground;
begin
  GetPalette := PPalette(@P);
end;

procedure TBackground.Draw;
var
  B: TDrawBuffer;
begin
  DrawChar(B, 0, Pattern, GetColor(1), Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TBackground.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(Pattern, SizeOf(Pattern));
end;

{ TDesktop }

constructor TDesktop.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
  TileColumnsFirst := False;
  InitBackground;
  if Background <> nil then Insert(Background);
end;

constructor TDesktop.Load(var S: TFVStream);
begin
  inherited Load(S);
  Background := TBackground(GetSubViewPtr(S, Self));
  S.Read(TileColumnsFirst, SizeOf(TileColumnsFirst));
end;

procedure TDesktop.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then begin
    case Event.Command of
      cmNext: FocusNext(True);
      cmPrev: begin
        { Send current window to back (just above Background), then select topmost }
        if (Current <> nil) and Valid(cmReleasedFocus) and (Background <> nil) then begin
          Current.PutInFrontOf(Background.Next);  { Insert after Background }
          { Select the new topmost selectable window }
          if Last <> nil then
            Last.Select;
        end;
      end;
    else
      Exit;
    end;
    ClearEvent(Event);
  end;
end;

procedure TDesktop.InitBackground;
var
  R: TRect;
begin
  GetExtent(R);
  Background := NewBackground(R);
end;

function TDesktop.NewBackground(var Bounds: TRect): TBackground;
begin
  NewBackground := TBackground.Create(Bounds, BlockLight);
end;

procedure TDesktop.Store(var S: TFVStream);
begin
  inherited Store(S);
  PutSubViewPtr(S, Background);
  S.Write(TileColumnsFirst, SizeOf(TileColumnsFirst));
end;

procedure TDesktop.TileError;
begin
end;

procedure TDesktop.Tile(var R: TRect);
var
  NumCols, NumRows, NumTileable, LeftOver, TileNum: Integer;
  V, L0: TView;
  NR: TRect;
  PState: Word;

  function Tileable(P: TView): Boolean;
  begin
    Result := (P.Options and ofTileable <> 0) and (P.State and sfVisible <> 0);
  end;

  function ISqr(X: Integer): Integer;
  var
    I: Integer;
  begin
    I := 0;
    repeat
      Inc(I);
    until I * I > X;
    Result := I - 1;
  end;

  procedure MostEqualDivisors(N: Integer; var X, Y: Integer; FavorY: Boolean);
  var
    I: Integer;
  begin
    I := ISqr(N);
    if (N mod I) <> 0 then
      if (N mod (I + 1)) = 0 then Inc(I);
    if I < (N div I) then I := N div I;
    if FavorY then begin
      X := N div I;
      Y := I;
    end else begin
      Y := N div I;
      X := I;
    end;
  end;

  function DividerLoc(Lo, Hi, Num, Pos: Integer): Integer;
  begin
    Result := LongInt(LongInt(Hi - Lo) * Pos) div Num + Lo;
  end;

  procedure CalcTileRect(Pos: Integer; var TR: TRect);
  var
    X, Y, D: Integer;
  begin
    D := (NumCols - LeftOver) * NumRows;
    if Pos < D then begin
      X := Pos div NumRows;
      Y := Pos mod NumRows;
    end else begin
      X := (Pos - D) div (NumRows + 1) + (NumCols - LeftOver);
      Y := (Pos - D) mod (NumRows + 1);
    end;
    TR.A.X := DividerLoc(R.A.X, R.B.X, NumCols, X);
    TR.B.X := DividerLoc(R.A.X, R.B.X, NumCols, X + 1);
    if Pos >= D then begin
      TR.A.Y := DividerLoc(R.A.Y, R.B.Y, NumRows + 1, Y);
      TR.B.Y := DividerLoc(R.A.Y, R.B.Y, NumRows + 1, Y + 1);
    end else begin
      TR.A.Y := DividerLoc(R.A.Y, R.B.Y, NumRows, Y);
      TR.B.Y := DividerLoc(R.A.Y, R.B.Y, NumRows, Y + 1);
    end;
  end;

begin
  if Last = nil then Exit;

  { Count tileable views }
  NumTileable := 0;
  V := Last;
  L0 := Last;
  repeat
    V := V.Next;
    if Tileable(V) then Inc(NumTileable);
  until V = L0;

  if NumTileable > 0 then begin
    { Calculate most equal divisors for grid layout }
    MostEqualDivisors(NumTileable, NumCols, NumRows, not TileColumnsFirst);

    { Check if tiles would be zero-sized }
    if ((R.B.X - R.A.X) div NumCols = 0) or
       ((R.B.Y - R.A.Y) div NumRows = 0) then
      TileError
    else begin
      LeftOver := NumTileable mod NumCols;

      { Tile the views }
      TileNum := NumTileable - 1;
      V := Last;
      repeat
        V := V.Next;
        if Tileable(V) then begin
          CalcTileRect(TileNum, NR);
          { Temporarily hide view to prevent flicker during relocation }
          PState := V.State;
          V.State := V.State and not sfVisible;
          V.Locate(NR);
          V.State := PState;
          Dec(TileNum);
        end;
      until V = L0;

      { Redraw desktop after tiling }
      DrawView;
    end;
  end;
end;

procedure TDesktop.Cascade(var R: TRect);
var
  CascadeNum, Cnt: Integer;
  Min, Max: TPoint;
  NR: TRect;
  V, L0: TView;

  function Cascadeable(P: TView): Boolean;
  begin
    Result := (P.Options and ofTileable <> 0) and (P.State and sfVisible <> 0);
  end;

begin
  if Last = nil then Exit;

  { Count cascadeable views }
  CascadeNum := 0;
  V := Last;
  L0 := Last;
  repeat
    V := V.Next;
    if Cascadeable(V) then Inc(CascadeNum);
  until V = L0;

  if CascadeNum > 0 then begin
    if (R.B.X - R.A.X < CascadeNum) or (R.B.Y - R.A.Y < CascadeNum) then
      TileError
    else begin
      { Cascade all cascadeable views }
      Cnt := 0;
      V := Last;
      repeat
        V := V.Next;
        if Cascadeable(V) then begin
          NR.A.X := R.A.X + Cnt;
          NR.A.Y := R.A.Y + Cnt;
          V.SizeLimits(Min, Max);
          NR.B.X := NR.A.X + Max.X;
          if NR.B.X > R.B.X then NR.B.X := R.B.X;
          NR.B.Y := NR.A.Y + Max.Y;
          if NR.B.Y > R.B.Y then NR.B.Y := R.B.Y;
          V.Locate(NR);
          Inc(Cnt);
        end;
      until V = L0;
    end;
  end;
end;

procedure TDesktop.CascadeNoResize(var R: TRect);
var
  CascadeNum, Cnt: Integer;
  V, L0: TView;
  DX, DY: Integer;
  PState: Word;

  function Cascadeable(P: TView): Boolean;
  begin
    Result := (P.Options and ofTileable <> 0) and (P.State and sfVisible <> 0);
  end;

begin
  if Last = nil then Exit;

  { Count cascadeable views }
  CascadeNum := 0;
  V := Last;
  L0 := Last;
  repeat
    V := V.Next;
    if Cascadeable(V) then Inc(CascadeNum);
  until V = L0;

  if CascadeNum > 0 then begin
    { Cascade all cascadeable views - just move, don't resize }
    Cnt := 0;
    V := Last;
    repeat
      V := V.Next;
      if Cascadeable(V) then begin
        { Calculate new position offset from top-left of desktop }
        DX := R.A.X + Cnt - V.Origin.X;
        DY := R.A.Y + Cnt - V.Origin.Y;
        { Temporarily hide view to prevent flicker }
        PState := V.State;
        V.State := V.State and not sfVisible;
        V.MoveTo(V.Origin.X + DX, V.Origin.Y + DY);
        V.State := PState;
        Inc(Cnt);
      end;
    until V = L0;

    DrawView;
  end;
end;

procedure TDesktop.TileHorizontal(var R: TRect);
var
  NumTileable, TileNum: Integer;
  V, L0: TView;
  NR: TRect;
  PState: Word;

  function Tileable(P: TView): Boolean;
  begin
    Result := (P.Options and ofTileable <> 0) and (P.State and sfVisible <> 0);
  end;

  function DividerLoc(Lo, Hi, Num, Pos: Integer): Integer;
  begin
    Result := LongInt(LongInt(Hi - Lo) * Pos) div Num + Lo;
  end;

begin
  if Last = nil then Exit;

  { Count tileable views }
  NumTileable := 0;
  V := Last;
  L0 := Last;
  repeat
    V := V.Next;
    if Tileable(V) then Inc(NumTileable);
  until V = L0;

  if NumTileable > 0 then begin
    { Check if tiles would be zero-sized }
    if (R.B.X - R.A.X) div NumTileable = 0 then
      TileError
    else begin
      { Tile horizontally: single row, N columns }
      TileNum := NumTileable - 1;
      V := Last;
      repeat
        V := V.Next;
        if Tileable(V) then begin
          NR.A.X := DividerLoc(R.A.X, R.B.X, NumTileable, TileNum);
          NR.B.X := DividerLoc(R.A.X, R.B.X, NumTileable, TileNum + 1);
          NR.A.Y := R.A.Y;
          NR.B.Y := R.B.Y;
          { Temporarily hide view to prevent flicker }
          PState := V.State;
          V.State := V.State and not sfVisible;
          V.Locate(NR);
          V.State := PState;
          Dec(TileNum);
        end;
      until V = L0;

      DrawView;
    end;
  end;
end;

procedure TDesktop.TileVertical(var R: TRect);
var
  NumTileable, TileNum: Integer;
  V, L0: TView;
  NR: TRect;
  PState: Word;

  function Tileable(P: TView): Boolean;
  begin
    Result := (P.Options and ofTileable <> 0) and (P.State and sfVisible <> 0);
  end;

  function DividerLoc(Lo, Hi, Num, Pos: Integer): Integer;
  begin
    Result := LongInt(LongInt(Hi - Lo) * Pos) div Num + Lo;
  end;

begin
  if Last = nil then Exit;

  { Count tileable views }
  NumTileable := 0;
  V := Last;
  L0 := Last;
  repeat
    V := V.Next;
    if Tileable(V) then Inc(NumTileable);
  until V = L0;

  if NumTileable > 0 then begin
    { Check if tiles would be zero-sized }
    if (R.B.Y - R.A.Y) div NumTileable = 0 then
      TileError
    else begin
      { Tile vertically: single column, N rows }
      TileNum := NumTileable - 1;
      V := Last;
      repeat
        V := V.Next;
        if Tileable(V) then begin
          NR.A.X := R.A.X;
          NR.B.X := R.B.X;
          NR.A.Y := DividerLoc(R.A.Y, R.B.Y, NumTileable, TileNum);
          NR.B.Y := DividerLoc(R.A.Y, R.B.Y, NumTileable, TileNum + 1);
          { Temporarily hide view to prevent flicker }
          PState := V.State;
          V.State := V.State and not sfVisible;
          V.Locate(NR);
          V.State := PState;
          Dec(TileNum);
        end;
      until V = L0;

      DrawView;
    end;
  end;
end;

procedure TDesktop.CloseAll;
var
  V, NextV, L0: TView;

  function Closeable(P: TView): Boolean;
  begin
    Result := (P.Options and ofTileable <> 0) and (P.State and sfVisible <> 0);
  end;

begin
  if Last = nil then Exit;

  { Close all tileable views - iterate carefully since closing modifies the list }
  L0 := Last;
  V := Last.Next;
  while V <> L0 do begin
    NextV := V.Next;
    if Closeable(V) then begin
      { Send close message to the view }
      Message(V, evCommand, cmClose, nil);
    end;
    V := NextV;
  end;
  { Check the last one too }
  if Closeable(L0) then
    Message(L0, evCommand, cmClose, nil);
end;

{ TProgram }

constructor TProgram.Create;
var
  R: TRect;
begin
  Application := Self;
  InitScreen;
  R.Assign(0, 0, DriversScreenWidth, DriversScreenHeight);
  inherited Create(R);
  State := sfVisible + sfSelected + sfFocused + sfModal + sfExposed;
  Options := 0;
  InitDesktop;
  InitStatusLine;
  InitMenuBar;
  if Desktop <> nil then Insert(Desktop);
  if StatusLine <> nil then Insert(StatusLine);
  if MenuBar <> nil then Insert(MenuBar);
end;

destructor TProgram.Destroy;
begin
  { Note: Do NOT dispose Desktop, MenuBar, StatusLine here.
    They are inserted into this TGroup and will be freed
    by TGroup.Destroy when we call inherited Destroy.
    Manual disposal here would cause a double-free crash. }
  Desktop := nil;
  MenuBar := nil;
  StatusLine := nil;
  inherited Destroy;
  Application := nil;
end;

function TProgram.ExecuteDialog(P: TDialog; Data: Pointer): Word;
var
  C: Word;
begin
  Result := cmCancel;
  if P <> nil then begin
    if Data <> nil then
      P.SetData(Data^);
    if Desktop = nil then
      Exit;
    C := Desktop.ExecView(P);
    if (C <> cmCancel) and (Data <> nil) then
      P.GetData(Data^);
    FreeAndNil(P);
    Result := C;
  end;
end;

function TProgram.GetPalette: PPalette;
const
  P: array[0..2] of String[Length(CAppColor)] = (CAppColor, CAppBlackWhite, CAppMonochrome);
begin
  GetPalette := PPalette(@P[AppPalette]);
end;

procedure TProgram.GetEvent(var Event: TEvent);
begin
  Drivers.GetEvent(Event);
  if Event.What = evNothing then begin
    Idle;
  end;
end;

procedure TProgram.HandleEvent(var Event: TEvent);
var
  Handled: Boolean;
  R: TRect;
  NewWidth, NewHeight: Integer;
  I: Integer;
begin
  Handled := False;
  if Event.What = evKeyDown then begin
    case Event.KeyCode of
      kbAltX: begin Event.Command := cmQuit; Handled := True; end;
      kbAltF3: begin Event.Command := cmClose; Handled := True; end;
      kbF10: begin Event.Command := cmMenu; Handled := True; end;
      kbF5: begin Event.Command := cmZoom; Handled := True; end;
      kbCtrlF5: begin Event.Command := cmResize; Handled := True; end;
      kbF6: begin Event.Command := cmNext; Handled := True; end;
      kbShiftF6: begin Event.Command := cmPrev; Handled := True; end;
      kbAlt0: begin Event.Command := cmWindowList; Handled := True; end;
    end;
    if Handled then begin
      Event.What := evCommand;
      Event.InfoPtr := nil;
      PutEvent(Event);
      ClearEvent(Event);
    end;
    { Alt+1..Alt+9: broadcast cmSelectWindowNum to activate numbered windows }
    if (Event.What = evKeyDown) and
       (Event.KeyCode >= kbAlt1) and (Event.KeyCode <= kbAlt9) then begin
      I := (Event.KeyCode - kbAlt1) div $0100 + 1;  { 1..9 }
      Event.What := evBroadcast;
      Event.Command := cmSelectWindowNum;
      Event.InfoInt := I;
      PutEvent(Event);
      ClearEvent(Event);
    end;
  end;

  { Handle cmResizeApp BEFORE passing to subviews - this is a system event }
  if (Event.What = evCommand) and (Event.Command = cmResizeApp) then begin
    { Extract new dimensions from InfoLong (height in high word, width in low word) }
    NewWidth := Event.InfoLong and $FFFF;
    NewHeight := (Event.InfoLong shr 16) and $FFFF;

    { Resize the video buffer }
    FVScreen.ResizeVideo(NewWidth, NewHeight);

    { Update driver screen dimensions }
    DriversScreenWidth := FVScreen.ScreenWidth;
    DriversScreenHeight := FVScreen.ScreenHeight;

    { Resize the program bounds and all subviews }
    R.Assign(0, 0, DriversScreenWidth, DriversScreenHeight);
    ChangeBounds(R);

    { Force full redraw }
    Draw;
    FVScreen.UpdateScreen(True);

    ClearEvent(Event);
    Exit;
  end;

  { Always call inherited to let subviews process the event }
  inherited HandleEvent(Event);
  if Event.What = evCommand then begin
    case Event.Command of
      cmQuit: EndModal(cmQuit);
    end;
  end;
end;

procedure TProgram.Idle;
begin
  if StatusLine <> nil then StatusLine.Update;
  if CommandSetChanged then begin
    Message(Self, evBroadcast, cmCommandSetChanged, nil);
    CommandSetChanged := False;
  end;
  FVScreen.UpdateScreen(False);
end;

procedure TProgram.InitDesktop;
var
  R: TRect;
begin
  GetExtent(R);
  Inc(R.A.Y);
  Dec(R.B.Y);
  Desktop := TDesktop.Create(R);
end;

procedure TProgram.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := TMenuBar.Create(R, nil);
end;

procedure TProgram.InitScreen;
begin
  if not InitDriversVideo then begin
    WriteLn('Error initializing video');
    Halt(1);
  end;
  InitEvents;
  InitHistory;
end;

procedure TProgram.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := TStatusLine.Create(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      NewStatusKey('~F10~ Menu', kbF10, cmMenu, nil)), nil));
end;

procedure TProgram.OutOfMemory;
begin
end;

procedure TProgram.PutEvent(var Event: TEvent);
begin
  Drivers.PutEvent(Event);
end;

procedure TProgram.Run;
begin
  Draw;
  FVScreen.UpdateScreen(True);
  Execute;
end;

procedure TProgram.SetScreenMode(Mode: Word);
begin
end;

{ TApplication }

constructor TApplication.Create;
begin
  inherited Create;
end;

destructor TApplication.Destroy;
begin
  DoneHistory;
  DoneEvents;
  DoneDriversVideo;
  inherited Destroy;
end;

procedure TApplication.Cascade;
var
  R: TRect;
begin
  GetTileRect(R);
  if Desktop <> nil then Desktop.Cascade(R);
end;

procedure TApplication.DosShell;
begin
end;

procedure TApplication.GetTileRect(var R: TRect);
begin
  if Desktop <> nil then Desktop.GetExtent(R)
  else GetExtent(R);
end;

procedure TApplication.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then begin
    case Event.Command of
      cmTile: Tile;
      cmTileHorizontal: TileHorizontal;
      cmTileVertical: TileVertical;
      cmCascade: Cascade;
      cmCascadeNoResize: CascadeNoResize;
      cmCloseAll: CloseAll;
      cmWindowList: WindowList;
      cmDosShell: DosShell;
    else
      Exit;
    end;
    ClearEvent(Event);
  end;
end;

procedure TApplication.Tile;
var
  R: TRect;
begin
  GetTileRect(R);
  if Desktop <> nil then Desktop.Tile(R);
end;

procedure TApplication.TileHorizontal;
var
  R: TRect;
begin
  GetTileRect(R);
  if Desktop <> nil then Desktop.TileHorizontal(R);
end;

procedure TApplication.TileVertical;
var
  R: TRect;
begin
  GetTileRect(R);
  if Desktop <> nil then Desktop.TileVertical(R);
end;

procedure TApplication.CascadeNoResize;
var
  R: TRect;
begin
  GetTileRect(R);
  if Desktop <> nil then Desktop.CascadeNoResize(R);
end;

procedure TApplication.CloseAll;
begin
  if Desktop <> nil then Desktop.CloseAll;
end;

procedure TApplication.WindowList;
var
  D: TDialog;
  R: TRect;
  SB: TScrollBar;
  LB: TStringListBox;
  SL: TStringList;
  WL: TList;
  V, L0: TView;
  W: TWindow;
  S: string;
  Cmd: Word;
  Idx, I: Integer;

  procedure BuildLists;
  begin
    SL := TStringList.Create;
    WL.Clear;
    if (Desktop = nil) or (Desktop.Last = nil) then Exit;
    V := Desktop.Last;
    L0 := V;
    repeat
      V := V.Next;
      if (V is TWindow) and (V <> D) and
         (V.State and sfVisible <> 0) and
         (V.Options and ofSelectable <> 0) then begin
        W := TWindow(V);
        if W.Number > 0 then
          S := IntToStr(W.Number) + ' - ' + W.GetTitle(255)
        else
          S := '  - ' + W.GetTitle(255);
        SL.Add(S);
        WL.Add(W);
      end;
    until V = L0;
  end;

begin
  if Desktop = nil then Exit;
  if Desktop.Last = nil then Exit;

  { Create dialog }
  R.Assign(0, 0, 42, 16);
  D := TDialog.Create(R, 'Window List');
  D.Options := D.Options or ofCentered;

  { Scrollbar }
  R.Assign(38, 2, 39, 12);
  SB := TScrollBar.Create(R);
  D.Insert(SB);

  { Listbox }
  R.Assign(2, 2, 38, 12);
  LB := TStringListBox.Create(R, 1, SB);
  D.Insert(LB);

  { Buttons }
  R.Assign(2, 13, 14, 15);
  D.Insert(TButton.Create(R, '~S~elect', cmOK, bfDefault));
  R.Assign(15, 13, 27, 15);
  D.Insert(TButton.Create(R, 'Close ~W~in', cmYes, bfNormal));
  R.Assign(28, 13, 40, 15);
  D.Insert(TButton.Create(R, 'Cancel', cmCancel, bfNormal));

  { Build window list }
  WL := TList.Create;
  try
    BuildLists;
    if SL.Count = 0 then begin
      FreeAndNil(SL);
      FreeAndNil(WL);
      FreeAndNil(D);
      Exit;
    end;

    { Pre-select current window }
    Idx := 0;
    if Desktop.Current <> nil then begin
      for I := 0 to WL.Count - 1 do
        if TWindow(WL[I]) = Desktop.Current then begin
          Idx := I;
          Break;
        end;
    end;
    LB.NewList(SL);  { LB takes ownership of SL }
    LB.FocusItem(Idx);

    { Execute dialog in a loop }
    repeat
      Cmd := Desktop.ExecView(D);
      if (Cmd = cmOK) and (LB.Focused < WL.Count) then begin
        W := TWindow(WL[LB.Focused]);
        W.Select;
        Break;
      end else if (Cmd = cmYes) and (LB.Focused < WL.Count) then begin
        W := TWindow(WL[LB.Focused]);
        Message(W, evCommand, cmClose, nil);
        { Rebuild list after closing }
        SL := nil;  { Old SL was freed by NewList }
        BuildLists;
        if SL.Count = 0 then Break;
        Idx := LB.Focused;
        if Idx >= SL.Count then Idx := SL.Count - 1;
        LB.NewList(SL);
        LB.FocusItem(Idx);
      end else
        Break;  { cmCancel or Esc }
    until False;
  finally
    FreeAndNil(WL);
    FreeAndNil(D);
  end;
end;

procedure RegisterApp;
begin
  RegisterType(RBackground);
  RegisterType(RDesktop);
end;

initialization
  AppPalette := 0;
  Application := nil;
  Desktop := nil;
  StatusLine := nil;
  MenuBar := nil;

end.
