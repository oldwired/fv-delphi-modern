{*********************************************************}
{                                                         }
{       Free Vision - VT Sequence Screen Buffer           }
{                                                         }
{       Modern Unicode-aware console rendering using      }
{       Virtual Terminal (VT/ANSI) escape sequences       }
{                                                         }
{       Replaces the legacy Video.pas unit                }
{                                                         }
{*********************************************************}

unit FVScreen;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  FVCommon;

const
  { VT Mode constants }
  vioOk = 0;
  vioError = 1;

  { Color mapping: Classic FV 4-bit colors to 256-color palette indices }
  { Order: Black, Blue, Green, Cyan, Red, Magenta, Brown, LightGray }
  {        DarkGray, LightBlue, LightGreen, LightCyan, LightRed, LightMagenta, Yellow, White }
  ColorMap: array[0..15] of Byte = (
    0,    // 0: Black
    4,    // 1: Blue
    2,    // 2: Green
    6,    // 3: Cyan
    1,    // 4: Red
    5,    // 5: Magenta
    3,    // 6: Brown/Yellow (dark)
    7,    // 7: Light Gray
    8,    // 8: Dark Gray
    12,   // 9: Light Blue
    10,   // 10: Light Green
    14,   // 11: Light Cyan
    9,    // 12: Light Red
    13,   // 13: Light Magenta
    11,   // 14: Yellow (bright)
    15    // 15: White
  );

type
  { Legacy video buffer types - for compatibility with existing code }
  TVideoCell = Word;
  PVideoCell = ^TVideoCell;
  TVideoBuf = array[0..32767] of TVideoCell;
  PVideoBuf = ^TVideoBuf;

  { Video mode information }
  TVideoMode = record
    Col: Integer;
    Row: Integer;
    Color: Boolean;
  end;

  { Forward declaration }
  TScreenBuffer = class;

  { Screen buffer class - manages virtual screen and VT output }
  TScreenBuffer = class
  private
    FCells: array of array of TScreenCell;      // Current screen state
    FOldCells: array of array of TScreenCell;   // Previous state for diff
    FWidth: Integer;
    FHeight: Integer;
    FConsoleOutput: THandle;
    FConsoleInput: THandle;
    FCursorX: Integer;
    FCursorY: Integer;
    FCursorVisible: Boolean;
    FInitialized: Boolean;
    FOriginalOutputMode: DWORD;
    FOriginalInputMode: DWORD;
    FOutputBuffer: TStringBuilder;              // Buffer VT sequences for batch output

    procedure EnableVTMode;
    procedure DisableVTMode;
    function CellsDiffer(X, Y: Integer): Boolean;
    procedure WriteVT(const S: string);
    procedure FlushVT;
    function BuildSGR(const Cell: TScreenCell): string;
    function BuildSGRFromAttr(Attr: Word): string;
    procedure MoveCursorVT(X, Y: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    { Initialization }
    procedure Init;
    procedure Done;
    procedure Resize(NewWidth, NewHeight: Integer);

    { Cell access - new Unicode-aware API }
    procedure SetCell(X, Y: Integer; const Ch: string; FG, BG: Byte;
                      Bold: Boolean = False; Underline: Boolean = False;
                      Inverse: Boolean = False);
    procedure SetCellAttr(X, Y: Integer; const Ch: string; Attr: Word);
    function GetCell(X, Y: Integer): TScreenCell;

    { Rendering }
    procedure UpdateScreen(Force: Boolean = False);
    procedure ClearScreen;

    { Cursor }
    procedure SetCursor(X, Y: Integer);
    procedure GetCursor(var X, Y: Integer);
    procedure ShowCursor;
    procedure HideCursor;
    procedure SetCursorType(Shape: Word);

    { Properties }
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Initialized: Boolean read FInitialized;
    property CursorX: Integer read FCursorX;
    property CursorY: Integer read FCursorY;
  end;

var
  { Global screen instance }
  Screen: TScreenBuffer;

  { Legacy compatibility variables - mapped to Screen object }
  ScreenWidth: Word;
  ScreenHeight: Word;
  VideoBufSize: LongInt;
  ErrorCode: Integer;

  { Legacy VideoBuf support - for gradual migration }
  { Views write to this, then we sync to Screen cells }
  VideoBuf: PVideoBuf;
  OldVideoBuf: PVideoBuf;

  { Unicode character buffer - parallel to VideoBuf for full Unicode support }
  { MoveChar stores Unicode chars here, sync reads from here }
  UnicodeCharBuf: array of Char;

{ Legacy API - calls through to Screen object }
procedure InitVideo;
procedure DoneVideo;
procedure UpdateScreen(Force: Boolean);
procedure ClearScreen;
procedure SetCursorPos(X, Y: Word);
procedure GetCursorPos(var X, Y: Word);
procedure SetCursorType(Shape: Word);
procedure ShowCursor;
procedure HideCursor;
procedure SetVideoMode(const Mode: TVideoMode);
procedure GetVideoMode(var Mode: TVideoMode);
function GetCapabilities: Word;
procedure ResizeVideo(NewWidth, NewHeight: Word);

{ Sync legacy VideoBuf to Screen cells }
procedure SyncVideoBufToScreen;

implementation

uses
  System.Math;

const
  { VT Escape sequences }
  VT_ESC = #27;
  VT_CSI = VT_ESC + '[';

  { Console mode flags for VT }
  ENABLE_VIRTUAL_TERMINAL_PROCESSING = $0004;
  DISABLE_NEWLINE_AUTO_RETURN = $0008;
  ENABLE_VIRTUAL_TERMINAL_INPUT = $0200;

var
  LegacyBuf: TVideoBuf;
  LegacyOldBuf: TVideoBuf;

{ TScreenBuffer }

constructor TScreenBuffer.Create;
begin
  inherited Create;
  FWidth := 0;
  FHeight := 0;
  FConsoleOutput := INVALID_HANDLE_VALUE;
  FConsoleInput := INVALID_HANDLE_VALUE;
  FCursorX := 0;
  FCursorY := 0;
  FCursorVisible := True;
  FInitialized := False;
  FOutputBuffer := TStringBuilder.Create(4096);
end;

destructor TScreenBuffer.Destroy;
begin
  if FInitialized then
    Done;
  FOutputBuffer.Free;
  inherited Destroy;
end;

procedure TScreenBuffer.EnableVTMode;
var
  Mode: DWORD;
begin
  { Enable VT processing on stdout }
  FConsoleOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  FConsoleInput := GetStdHandle(STD_INPUT_HANDLE);

  if FConsoleOutput <> INVALID_HANDLE_VALUE then begin
    GetConsoleMode(FConsoleOutput, FOriginalOutputMode);
    Mode := FOriginalOutputMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    { Try to disable newline auto-return for cleaner positioning }
    Mode := Mode or DISABLE_NEWLINE_AUTO_RETURN;
    if not SetConsoleMode(FConsoleOutput, Mode) then begin
      { Fall back without DISABLE_NEWLINE_AUTO_RETURN }
      Mode := FOriginalOutputMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;
      SetConsoleMode(FConsoleOutput, Mode);
    end;
  end;

  { Note: We do NOT enable ENABLE_VIRTUAL_TERMINAL_INPUT because Drivers.pas
    uses Windows Console API to read keyboard events with virtual key codes.
    VT input mode would convert function keys to escape sequences which breaks
    the existing keyboard handling. We only use VT for output. }
  if FConsoleInput <> INVALID_HANDLE_VALUE then
    GetConsoleMode(FConsoleInput, FOriginalInputMode);
end;

procedure TScreenBuffer.DisableVTMode;
begin
  if FConsoleOutput <> INVALID_HANDLE_VALUE then
    SetConsoleMode(FConsoleOutput, FOriginalOutputMode);
  if FConsoleInput <> INVALID_HANDLE_VALUE then
    SetConsoleMode(FConsoleInput, FOriginalInputMode);
end;

procedure TScreenBuffer.Init;
var
  Info: TConsoleScreenBufferInfo;
  X, Y: Integer;
begin
  if FInitialized then Exit;

  FConsoleOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  if FConsoleOutput = INVALID_HANDLE_VALUE then begin
    ErrorCode := vioError;
    Exit;
  end;

  EnableVTMode;

  { Get console dimensions }
  if GetConsoleScreenBufferInfo(FConsoleOutput, Info) then begin
    FWidth := Info.srWindow.Right - Info.srWindow.Left + 1;
    FHeight := Info.srWindow.Bottom - Info.srWindow.Top + 1;
  end else begin
    FWidth := 80;
    FHeight := 25;
  end;

  { Allocate cell arrays }
  SetLength(FCells, FHeight, FWidth);
  SetLength(FOldCells, FHeight, FWidth);

  { Initialize with empty cells }
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do begin
      FCells[Y, X] := TScreenCell.Empty;
      FOldCells[Y, X] := TScreenCell.Empty;
      { Mark old cells as different to force initial draw }
      FOldCells[Y, X].Ch := #0;
    end;

  FCursorX := 0;
  FCursorY := 0;
  FInitialized := True;
  ErrorCode := vioOk;

  { Update legacy variables }
  ScreenWidth := FWidth;
  ScreenHeight := FHeight;
  VideoBufSize := FWidth * FHeight * SizeOf(Word);

  { Use alternate screen buffer for clean UI }
  WriteVT(VT_CSI + '?1049h');  // Enable alternate buffer
  WriteVT(VT_CSI + '?25l');    // Hide cursor initially
  FlushVT;
end;

procedure TScreenBuffer.Done;
begin
  if not FInitialized then Exit;

  { Restore main screen buffer }
  WriteVT(VT_CSI + '?1049l');  // Disable alternate buffer
  WriteVT(VT_CSI + '?25h');    // Show cursor
  WriteVT(VT_CSI + '0m');      // Reset attributes
  FlushVT;

  DisableVTMode;

  SetLength(FCells, 0, 0);
  SetLength(FOldCells, 0, 0);
  FInitialized := False;
end;

procedure TScreenBuffer.Resize(NewWidth, NewHeight: Integer);
var
  X, Y: Integer;
begin
  if not FInitialized then Exit;

  FWidth := NewWidth;
  FHeight := NewHeight;

  SetLength(FCells, FHeight, FWidth);
  SetLength(FOldCells, FHeight, FWidth);

  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do begin
      FCells[Y, X] := TScreenCell.Empty;
      FOldCells[Y, X] := TScreenCell.Empty;
      FOldCells[Y, X].Ch := #0;  // Force redraw
    end;

  ScreenWidth := FWidth;
  ScreenHeight := FHeight;
  VideoBufSize := FWidth * FHeight * SizeOf(Word);
end;

procedure TScreenBuffer.WriteVT(const S: string);
begin
  FOutputBuffer.Append(S);
end;

procedure TScreenBuffer.FlushVT;
var
  S: string;
  Written: DWORD;
begin
  if FOutputBuffer.Length = 0 then Exit;
  S := FOutputBuffer.ToString;
  WriteConsoleW(FConsoleOutput, PChar(S), Length(S), Written, nil);
  FOutputBuffer.Clear;
end;

function TScreenBuffer.CellsDiffer(X, Y: Integer): Boolean;
begin
  Result := (FCells[Y, X].Ch <> FOldCells[Y, X].Ch) or
            (FCells[Y, X].FG <> FOldCells[Y, X].FG) or
            (FCells[Y, X].BG <> FOldCells[Y, X].BG) or
            (FCells[Y, X].Bold <> FOldCells[Y, X].Bold) or
            (FCells[Y, X].Underline <> FOldCells[Y, X].Underline) or
            (FCells[Y, X].Inverse <> FOldCells[Y, X].Inverse);
end;

function TScreenBuffer.BuildSGR(const Cell: TScreenCell): string;
var
  FGIndex, BGIndex: Byte;
begin
  { Map 4-bit colors to 256-color palette }
  if Cell.FG < 16 then
    FGIndex := ColorMap[Cell.FG]
  else
    FGIndex := Cell.FG;

  if Cell.BG < 16 then
    BGIndex := ColorMap[Cell.BG]
  else
    BGIndex := Cell.BG;

  { Build SGR sequence }
  Result := VT_CSI + '0';  // Reset first

  if Cell.Bold then
    Result := Result + ';1';
  if Cell.Underline then
    Result := Result + ';4';
  if Cell.Inverse then
    Result := Result + ';7';

  { 256-color mode }
  Result := Result + ';38;5;' + IntToStr(FGIndex);
  Result := Result + ';48;5;' + IntToStr(BGIndex);

  Result := Result + 'm';
end;

function TScreenBuffer.BuildSGRFromAttr(Attr: Word): string;
var
  FG, BG: Byte;
  FGIndex, BGIndex: Byte;
begin
  { Legacy attribute format: bits 0-3 = FG color, bits 4-7 = BG color }
  FG := Attr and $0F;
  BG := (Attr shr 4) and $0F;

  if FG < 16 then
    FGIndex := ColorMap[FG]
  else
    FGIndex := FG;

  if BG < 16 then
    BGIndex := ColorMap[BG]
  else
    BGIndex := BG;

  Result := VT_CSI + '0';
  Result := Result + ';38;5;' + IntToStr(FGIndex);
  Result := Result + ';48;5;' + IntToStr(BGIndex);
  Result := Result + 'm';
end;

procedure TScreenBuffer.MoveCursorVT(X, Y: Integer);
begin
  { VT uses 1-based coordinates }
  WriteVT(VT_CSI + IntToStr(Y + 1) + ';' + IntToStr(X + 1) + 'H');
end;

procedure TScreenBuffer.SetCell(X, Y: Integer; const Ch: string; FG, BG: Byte;
                                 Bold, Underline, Inverse: Boolean);
begin
  if not FInitialized then Exit;
  if (X < 0) or (X >= FWidth) or (Y < 0) or (Y >= FHeight) then Exit;

  FCells[Y, X].Ch := Ch;
  FCells[Y, X].FG := FG;
  FCells[Y, X].BG := BG;
  FCells[Y, X].Bold := Bold;
  FCells[Y, X].Underline := Underline;
  FCells[Y, X].Inverse := Inverse;
end;

procedure TScreenBuffer.SetCellAttr(X, Y: Integer; const Ch: string; Attr: Word);
var
  FG, BG: Byte;
begin
  if not FInitialized then Exit;
  if (X < 0) or (X >= FWidth) or (Y < 0) or (Y >= FHeight) then Exit;

  { Extract colors from legacy attribute byte }
  { Format: bits 0-3 = FG color, bits 4-7 = BG color }
  FG := Attr and $0F;
  BG := (Attr shr 4) and $0F;

  FCells[Y, X].Ch := Ch;
  FCells[Y, X].FG := FG;
  FCells[Y, X].BG := BG;
  FCells[Y, X].Bold := False;
  FCells[Y, X].Underline := False;
  FCells[Y, X].Inverse := False;
end;

function TScreenBuffer.GetCell(X, Y: Integer): TScreenCell;
begin
  if (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight) then
    Result := FCells[Y, X]
  else
    Result := TScreenCell.Empty;
end;

procedure TScreenBuffer.UpdateScreen(Force: Boolean);
var
  X, Y: Integer;
  LastSGR: string;
  CurrentSGR: string;
  NeedMove: Boolean;
  LastX: Integer;
begin
  if not FInitialized then Exit;

  LastSGR := '';
  LastX := -1;
  NeedMove := True;

  for Y := 0 to FHeight - 1 do begin
    NeedMove := True;
    LastX := -1;
    for X := 0 to FWidth - 1 do begin
      if Force or CellsDiffer(X, Y) then begin
        { Position cursor if needed }
        if NeedMove or (X <> LastX + 1) then begin
          MoveCursorVT(X, Y);
          NeedMove := False;
        end;

        { Set attributes if changed }
        CurrentSGR := BuildSGR(FCells[Y, X]);
        if CurrentSGR <> LastSGR then begin
          WriteVT(CurrentSGR);
          LastSGR := CurrentSGR;
        end;

        { Output character }
        if FCells[Y, X].Ch <> '' then
          WriteVT(FCells[Y, X].Ch)
        else
          WriteVT(' ');

        { Update old buffer }
        FOldCells[Y, X] := FCells[Y, X];
        LastX := X;
      end else begin
        NeedMove := True;
      end;
    end;
  end;

  { Reset attributes and restore cursor }
  WriteVT(VT_CSI + '0m');
  if FCursorVisible then begin
    MoveCursorVT(FCursorX, FCursorY);
    WriteVT(VT_CSI + '?25h');
  end;

  FlushVT;
end;

procedure TScreenBuffer.ClearScreen;
var
  X, Y: Integer;
begin
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
      FCells[Y, X] := TScreenCell.Empty;

  WriteVT(VT_CSI + '0m');       // Reset attributes
  WriteVT(VT_CSI + '2J');       // Clear screen
  WriteVT(VT_CSI + 'H');        // Home cursor
  FlushVT;

  { Mark all cells as needing redraw }
  for Y := 0 to FHeight - 1 do
    for X := 0 to FWidth - 1 do
      FOldCells[Y, X].Ch := #0;
end;

procedure TScreenBuffer.SetCursor(X, Y: Integer);
begin
  FCursorX := X;
  FCursorY := Y;
  if FInitialized and (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight) then begin
    MoveCursorVT(X, Y);
    FlushVT;
  end;
end;

procedure TScreenBuffer.GetCursor(var X, Y: Integer);
begin
  X := FCursorX;
  Y := FCursorY;
end;

procedure TScreenBuffer.ShowCursor;
begin
  FCursorVisible := True;
  if FInitialized then begin
    WriteVT(VT_CSI + '?25h');
    FlushVT;
  end;
end;

procedure TScreenBuffer.HideCursor;
begin
  FCursorVisible := False;
  if FInitialized then begin
    WriteVT(VT_CSI + '?25l');
    FlushVT;
  end;
end;

procedure TScreenBuffer.SetCursorType(Shape: Word);
begin
  if not FInitialized then Exit;
  { VT cursor shapes:
    0 = default, 1 = blinking block, 2 = steady block,
    3 = blinking underline, 4 = steady underline,
    5 = blinking bar, 6 = steady bar }
  case Shape of
    0: WriteVT(VT_CSI + '?25l');  // Hidden
    1..25: WriteVT(VT_CSI + '4 q');  // Underline
    26..50: WriteVT(VT_CSI + '2 q');  // Block (half)
    51..100: WriteVT(VT_CSI + '2 q'); // Block (full)
  else
    WriteVT(VT_CSI + '0 q');  // Default
  end;
  FlushVT;
end;

{ Legacy API implementations }

procedure InitVideo;
var
  BufSize: Integer;
begin
  if Screen = nil then
    Screen := TScreenBuffer.Create;
  Screen.Init;

  { Set up legacy buffer pointers }
  VideoBuf := @LegacyBuf;
  OldVideoBuf := @LegacyOldBuf;
  FillChar(LegacyBuf, SizeOf(LegacyBuf), 0);
  FillChar(LegacyOldBuf, SizeOf(LegacyOldBuf), 0);

  { Initialize Unicode character buffer }
  BufSize := ScreenWidth * ScreenHeight;
  SetLength(UnicodeCharBuf, BufSize);
  for var I := 0 to BufSize - 1 do begin
    LegacyBuf[I] := $0720;
    UnicodeCharBuf[I] := ' ';
  end;
end;

procedure DoneVideo;
begin
  if Screen <> nil then
    Screen.Done;
end;

procedure SyncVideoBufToScreen;
var
  X, Y, I: Integer;
  Cell: Word;
  Ch: Char;
  Attr: Byte;
begin
  if (Screen = nil) or not Screen.Initialized then Exit;

  for Y := 0 to Screen.Height - 1 do begin
    for X := 0 to Screen.Width - 1 do begin
      I := Y * Screen.Width + X;
      if I < Length(LegacyBuf) then begin
        Cell := VideoBuf^[I];
        { Use Unicode char from parallel buffer instead of Lo(Cell) }
        if (I < Length(UnicodeCharBuf)) and (UnicodeCharBuf[I] <> #0) then
          Ch := UnicodeCharBuf[I]
        else
          Ch := Char(Lo(Cell));
        Attr := Hi(Cell);
        Screen.SetCellAttr(X, Y, Ch, Attr);
      end;
    end;
  end;
end;

procedure UpdateScreen(Force: Boolean);
begin
  { Sync legacy buffer to new screen cells }
  SyncVideoBufToScreen;

  { Then update the VT screen }
  if Screen <> nil then
    Screen.UpdateScreen(Force);

  { Copy current to old for legacy diff detection }
  if VideoBuf <> nil then
    Move(VideoBuf^, OldVideoBuf^, ScreenWidth * ScreenHeight * 2);
end;

procedure ClearScreen;
begin
  if Screen <> nil then
    Screen.ClearScreen;
  { Clear legacy buffer too }
  for var I := 0 to ScreenWidth * ScreenHeight - 1 do
    LegacyBuf[I] := $0720;
end;

procedure SetCursorPos(X, Y: Word);
begin
  if Screen <> nil then begin
    Screen.SetCursor(X, Y);
    Screen.ShowCursor;
  end;
end;

procedure GetCursorPos(var X, Y: Word);
var
  IX, IY: Integer;
begin
  if Screen <> nil then begin
    Screen.GetCursor(IX, IY);
    X := IX;
    Y := IY;
  end else begin
    X := 0;
    Y := 0;
  end;
end;

procedure SetCursorType(Shape: Word);
begin
  if Screen <> nil then
    Screen.SetCursorType(Shape);
end;

procedure ShowCursor;
begin
  if Screen <> nil then
    Screen.ShowCursor;
end;

procedure HideCursor;
begin
  if Screen <> nil then
    Screen.HideCursor;
end;

procedure SetVideoMode(const Mode: TVideoMode);
begin
  if Screen <> nil then
    Screen.Resize(Mode.Col, Mode.Row);
end;

procedure GetVideoMode(var Mode: TVideoMode);
begin
  if Screen <> nil then begin
    Mode.Col := Screen.Width;
    Mode.Row := Screen.Height;
    Mode.Color := True;
  end else begin
    Mode.Col := 80;
    Mode.Row := 25;
    Mode.Color := True;
  end;
end;

function GetCapabilities: Word;
begin
  Result := 0;
end;

procedure ResizeVideo(NewWidth, NewHeight: Word);
begin
  if Screen <> nil then
    Screen.Resize(NewWidth, NewHeight);
end;

initialization
  Screen := nil;
  VideoBuf := nil;
  OldVideoBuf := nil;
  ScreenWidth := 80;
  ScreenHeight := 25;

finalization
  if Screen <> nil then begin
    Screen.Free;
    Screen := nil;
  end;

end.
