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
  System.Generics.Collections,
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

  { Sixel region descriptor }
  TSixelRegion = record
    ScreenX, ScreenY: Integer;  { Top-left cell (global screen coords) }
    CellW, CellH: Integer;     { Region size in cells }
    SixelData: string;          { Pre-encoded DCS string }
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
    FSixelRegions: TList<TSixelRegion>;        // Registered Sixel regions for current frame
    FSixelPrevRegions: TList<TSixelRegion>;   // Sixel regions from previous frame (for cleanup)
    FSixelSupported: Boolean;                  // True if terminal supports Sixel graphics
    FCellPixelWidth: Integer;                  // Cell width in pixels
    FCellPixelHeight: Integer;                 // Cell height in pixels

    procedure EnableVTMode;
    procedure DisableVTMode;
    procedure DetectSixelSupport;
    procedure DetectCellPixelSize;
    function TryVTCellSizeQuery: Boolean;
    procedure EmitSixelRegions;
    procedure EraseStaleSixelRegions;
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
    procedure SetCellRGB(X, Y: Integer; FG_RGB, BG_RGB: Cardinal);
    function GetCell(X, Y: Integer): TScreenCell;

    { Rendering }
    procedure UpdateScreen(Force: Boolean = False);
    procedure ClearScreen;

    { Sixel support }
    procedure RegisterSixelRegion(ScreenX, ScreenY, CellW, CellH: Integer;
      const SixelData: string);

    { Terminal window title }
    procedure SetWindowTitle(const ATitle: string);

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
    property SixelSupported: Boolean read FSixelSupported;
    property CellPixelWidth: Integer read FCellPixelWidth;
    property CellPixelHeight: Integer read FCellPixelHeight;
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
  { Uses string to support surrogate pairs (emoji) and multi-codepoint graphemes }
  UnicodeCharBuf: array of string;

  { RGB overlay buffers - parallel to VideoBuf for 24-bit color support }
  { Non-zero values override palette colors in rendering }
  FGRGBBuf: array of Cardinal;
  BGRGBBuf: array of Cardinal;

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
  System.Math,
  FVUTF8;

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
  FSixelRegions := TList<TSixelRegion>.Create;
  FSixelPrevRegions := TList<TSixelRegion>.Create;
  FSixelSupported := False;
  FCellPixelWidth := 8;
  FCellPixelHeight := 16;
end;

destructor TScreenBuffer.Destroy;
begin
  if FInitialized then
    Done;
  FSixelPrevRegions.Free;
  FSixelRegions.Free;
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

  { Detect Sixel support and cell pixel size }
  DetectSixelSupport;
  DetectCellPixelSize;

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
            (FCells[Y, X].Inverse <> FOldCells[Y, X].Inverse) or
            (FCells[Y, X].FG_RGB <> FOldCells[Y, X].FG_RGB) or
            (FCells[Y, X].BG_RGB <> FOldCells[Y, X].BG_RGB);
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

  { Foreground: 24-bit RGB if available, else 256-color palette }
  if Cell.FG_RGB <> 0 then
    Result := Result + ';38;2;' +
      IntToStr((Cell.FG_RGB shr 16) and $FF) + ';' +
      IntToStr((Cell.FG_RGB shr 8) and $FF) + ';' +
      IntToStr(Cell.FG_RGB and $FF)
  else
    Result := Result + ';38;5;' + IntToStr(FGIndex);

  { Background: 24-bit RGB if available, else 256-color palette }
  if Cell.BG_RGB <> 0 then
    Result := Result + ';48;2;' +
      IntToStr((Cell.BG_RGB shr 16) and $FF) + ';' +
      IntToStr((Cell.BG_RGB shr 8) and $FF) + ';' +
      IntToStr(Cell.BG_RGB and $FF)
  else
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
  FCells[Y, X].FG_RGB := 0;
  FCells[Y, X].BG_RGB := 0;
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
  FCells[Y, X].FG_RGB := 0;
  FCells[Y, X].BG_RGB := 0;
end;

procedure TScreenBuffer.SetCellRGB(X, Y: Integer; FG_RGB, BG_RGB: Cardinal);
begin
  if not FInitialized then Exit;
  if (X < 0) or (X >= FWidth) or (Y < 0) or (Y >= FHeight) then Exit;
  FCells[Y, X].FG_RGB := FG_RGB;
  FCells[Y, X].BG_RGB := BG_RGB;
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
  IsWide: Boolean;
begin
  if not FInitialized then Exit;

  { Phase 0: Erase any previous Sixel regions that moved or disappeared }
  if FSixelPrevRegions.Count > 0 then
    EraseStaleSixelRegions;

  { Phase 1: Emit registered Sixel regions (pixel layer underneath text) }
  if FSixelRegions.Count > 0 then
    EmitSixelRegions;

  { Phase 2: Normal cell rendering loop }
  LastSGR := '';

  for Y := 0 to FHeight - 1 do begin
    X := 0;
    while X < FWidth do begin
      if Force or CellsDiffer(X, Y) then begin
        { Skip Sixel placeholder cells - they are covered by Sixel pixel data }
        if FCells[Y, X].Ch = SixelPlaceholder then begin
          FOldCells[Y, X] := FCells[Y, X];
          Inc(X);
          Continue;
        end;

        { Position cursor for this cell }
        MoveCursorVT(X, Y);

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

        { Check if this cell contains a wide character (emoji, CJK, etc.)
          If so, skip the next cell - the terminal already used 2 columns
          for this character. Writing the continuation cell would overwrite
          the second visual column of the wide character. }
        IsWide := IsWideString(FCells[Y, X].Ch);
        if IsWide and (X + 1 < FWidth) then begin
          { Mark continuation cell as up-to-date so it won't be redrawn }
          FOldCells[Y, X + 1] := FCells[Y, X + 1];
          Inc(X);  { Skip the continuation cell }
        end;
      end;
      Inc(X);
    end;
  end;

  { Phase 3: Save current Sixel regions for stale detection, then clear.
    Only update prev if new regions were registered this frame - otherwise
    keep prev so stale detection works on idle frames when Draw isn't called. }
  if FSixelRegions.Count > 0 then
  begin
    FSixelPrevRegions.Clear;
    FSixelPrevRegions.AddRange(FSixelRegions);
  end;
  FSixelRegions.Clear;

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

procedure TScreenBuffer.SetWindowTitle(const ATitle: string);
begin
  if FInitialized then begin
    WriteVT(VT_ESC + ']0;' + ATitle + #7);
    FlushVT;
  end;
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

{ Sixel support }

procedure TScreenBuffer.DetectSixelSupport;
begin
  FSixelSupported := GetEnvironmentVariable('WT_SESSION') <> '';
end;

procedure TScreenBuffer.DetectCellPixelSize;
var
  FontInfo: CONSOLE_FONT_INFOEX;
  EnvW, EnvH: string;
  ValW, ValH, Code: Integer;
begin
  FCellPixelWidth := 8;
  FCellPixelHeight := 16;

  { Priority 1: Environment variable override (FV_CELL_W, FV_CELL_H) }
  EnvW := GetEnvironmentVariable('FV_CELL_W');
  EnvH := GetEnvironmentVariable('FV_CELL_H');
  if (EnvW <> '') and (EnvH <> '') then
  begin
    Val(EnvW, ValW, Code);
    if Code = 0 then
    begin
      Val(EnvH, ValH, Code);
      if (Code = 0) and (ValW >= 4) and (ValH >= 4) then
      begin
        FCellPixelWidth := ValW;
        FCellPixelHeight := ValH;
        Exit;
      end;
    end;
  end;

  { Priority 2: VT query CSI 16 t - reports actual cell pixel size.
    Accurate under ConPTY/Windows Terminal even with custom font sizes. }
  if TryVTCellSizeQuery then Exit;

  { Priority 3: Console font API (fallback, inaccurate under ConPTY) }
  if FConsoleOutput <> INVALID_HANDLE_VALUE then
  begin
    FillChar(FontInfo, SizeOf(FontInfo), 0);
    FontInfo.cbSize := SizeOf(FontInfo);
    if GetCurrentConsoleFontEx(FConsoleOutput, False, FontInfo) then
    begin
      if (FontInfo.dwFontSize.X > 0) and (FontInfo.dwFontSize.Y > 0) then
      begin
        FCellPixelWidth := FontInfo.dwFontSize.X;
        FCellPixelHeight := FontInfo.dwFontSize.Y;
      end;
    end;
  end;

  if FCellPixelWidth < 4 then FCellPixelWidth := 8;
  if FCellPixelHeight < 8 then FCellPixelHeight := 16;
end;

function TScreenBuffer.TryVTCellSizeQuery: Boolean;
var
  OldInputMode: DWORD;
  InputRecs: array[0..255] of TInputRecord;
  NumEvents: DWORD;
  Response: string;
  Ch: Char;
  StartTime: Cardinal;
  Idx, Start, I: Integer;
  H, W: Integer;
begin
  Result := False;
  if FConsoleInput = INVALID_HANDLE_VALUE then Exit;
  if FConsoleOutput = INVALID_HANDLE_VALUE then Exit;

  { Temporarily enable VT input so terminal responses come as raw characters }
  if not GetConsoleMode(FConsoleInput, OldInputMode) then Exit;
  if not SetConsoleMode(FConsoleInput, ENABLE_VIRTUAL_TERMINAL_INPUT) then Exit;

  try
    { Flush any pending input }
    FlushConsoleInputBuffer(FConsoleInput);

    { Send CSI 16 t query (xterm: report cell pixel size) }
    WriteVT(VT_CSI + '16t');
    FlushVT;

    { Collect response characters with timeout.
      Expected response: ESC [ 6 ; CellHeight ; CellWidth t }
    Response := '';
    StartTime := GetTickCount;
    while (GetTickCount - StartTime) < 1000 do
    begin
      if WaitForSingleObject(FConsoleInput, 200) <> WAIT_OBJECT_0 then
        Continue;

      NumEvents := 0;
      if not ReadConsoleInputW(FConsoleInput, InputRecs[0], 256, NumEvents) then
        Break;

      for I := 0 to Integer(NumEvents) - 1 do
      begin
        if (InputRecs[I].EventType = KEY_EVENT) and
           InputRecs[I].Event.KeyEvent.bKeyDown then
        begin
          Ch := InputRecs[I].Event.KeyEvent.UnicodeChar;
          if Ch <> #0 then
            Response := Response + Ch;
        end;
      end;

      { Check if we have a complete response (ends with 't') }
      if (Length(Response) > 0) and (Response[Length(Response)] = 't') then
        Break;
    end;

    { Parse ESC [ 6 ; H ; W t }
    Idx := Pos(#27'[6;', Response);
    if Idx = 0 then Exit;

    Start := Idx + 4; { Skip past ESC [ 6 ; }

    { Parse cell height }
    H := 0;
    while (Start <= Length(Response)) and
          (Response[Start] >= '0') and (Response[Start] <= '9') do
    begin
      H := H * 10 + Ord(Response[Start]) - Ord('0');
      Inc(Start);
    end;
    if (Start > Length(Response)) or (Response[Start] <> ';') then Exit;
    Inc(Start); { Skip semicolon }

    { Parse cell width }
    W := 0;
    while (Start <= Length(Response)) and
          (Response[Start] >= '0') and (Response[Start] <= '9') do
    begin
      W := W * 10 + Ord(Response[Start]) - Ord('0');
      Inc(Start);
    end;

    { Validate reasonable cell dimensions }
    if (H >= 4) and (W >= 4) and (H <= 200) and (W <= 200) then
    begin
      FCellPixelHeight := H;
      FCellPixelWidth := W;
      Result := True;
    end;
  finally
    { Restore original input mode and flush leftover VT response data }
    SetConsoleMode(FConsoleInput, OldInputMode);
    FlushConsoleInputBuffer(FConsoleInput);
  end;
end;

procedure TScreenBuffer.RegisterSixelRegion(ScreenX, ScreenY, CellW, CellH: Integer;
  const SixelData: string);
var
  Region: TSixelRegion;
begin
  if SixelData = '' then Exit;
  Region.ScreenX := ScreenX;
  Region.ScreenY := ScreenY;
  Region.CellW := CellW;
  Region.CellH := CellH;
  Region.SixelData := SixelData;
  FSixelRegions.Add(Region);
end;

procedure TScreenBuffer.EraseStaleSixelRegions;
var
  Prev: TSixelRegion;
  X, Y, I, J: Integer;
  StartX, ClampedW: Integer;
  IsStale: Boolean;
  StillActive: Boolean;
  Cur: TSixelRegion;
  ErasedIndices: TList<Integer>;
begin
  { For each previous Sixel region, check if it's still covered by a current
    region at the same position. If not, the cells at the old position need
    to be force-redrawn so Phase 2 overwrites the stale Sixel pixels.
    Erased regions are removed from FSixelPrevRegions so they are not
    re-erased on subsequent frames (which causes visible flicker). }
  ErasedIndices := TList<Integer>.Create;
  try
    for I := 0 to FSixelPrevRegions.Count - 1 do
    begin
      Prev := FSixelPrevRegions[I];
      IsStale := True;
      for Cur in FSixelRegions do
      begin
        if (Cur.ScreenX = Prev.ScreenX) and (Cur.ScreenY = Prev.ScreenY) and
           (Cur.CellW = Prev.CellW) and (Cur.CellH = Prev.CellH) then
        begin
          IsStale := False;
          Break;
        end;
      end;

      if IsStale then
      begin
        { On idle frames (no new regions registered), the old region may still
          be active - Draw just wasn't called. Check if ANY cell in the region
          still has a placeholder. Previously only checked the top-left cell,
          which failed when a menu/window occluded that corner. }
        if (FSixelRegions.Count = 0) then
        begin
          StillActive := False;
          for Y := Prev.ScreenY to Prev.ScreenY + Prev.CellH - 1 do
          begin
            for X := Prev.ScreenX to Prev.ScreenX + Prev.CellW - 1 do
              if (Y >= 0) and (Y < FHeight) and (X >= 0) and (X < FWidth) and
                 (FCells[Y, X].Ch = SixelPlaceholder) then
              begin
                StillActive := True;
                Break;
              end;
            if StillActive then Break;
          end;
          if StillActive then Continue;
        end;

        { Erase the old Sixel region with ECH so terminal clears pixel data.
          Clamp X coordinates to screen bounds - negative values produce
          malformed VT sequences that corrupt the terminal. }
        WriteVT(VT_CSI + '0m');
        for Y := Prev.ScreenY to Prev.ScreenY + Prev.CellH - 1 do
        begin
          if (Y < 0) or (Y >= FHeight) then Continue;
          StartX := Prev.ScreenX;
          ClampedW := Prev.CellW;
          { Clamp left edge to screen boundary }
          if StartX < 0 then
          begin
            ClampedW := ClampedW + StartX;  { Reduce width by off-screen amount }
            StartX := 0;
          end;
          { Clamp right edge to screen boundary }
          if StartX + ClampedW > FWidth then
            ClampedW := FWidth - StartX;
          if (StartX >= FWidth) or (ClampedW <= 0) then Continue;
          MoveCursorVT(StartX, Y);
          WriteVT(VT_CSI + IntToStr(ClampedW) + 'X');
        end;
        { Force Phase 2 to redraw these cells with actual content }
        for Y := Prev.ScreenY to Prev.ScreenY + Prev.CellH - 1 do
          for X := Prev.ScreenX to Prev.ScreenX + Prev.CellW - 1 do
            if (Y >= 0) and (Y < FHeight) and (X >= 0) and (X < FWidth) then
              FOldCells[Y, X].Ch := #0;

        ErasedIndices.Add(I);
      end;
    end;

    { Remove erased regions from prev list (reverse order for stable indices) }
    for J := ErasedIndices.Count - 1 downto 0 do
      FSixelPrevRegions.Delete(ErasedIndices[J]);
  finally
    ErasedIndices.Free;
  end;
end;

procedure TScreenBuffer.EmitSixelRegions;
var
  Region: TSixelRegion;
  X, Y: Integer;
begin
  for Region in FSixelRegions do
  begin
    { Only emit Sixel DCS if the top-left cursor position is on-screen.
      Negative coordinates produce malformed VT sequences that corrupt
      the terminal. When the region extends beyond the right/bottom edge,
      the terminal clips naturally so that case is safe. }
    if (Region.ScreenX >= 0) and (Region.ScreenY >= 0) and
       (Region.ScreenX < FWidth) and (Region.ScreenY < FHeight) then
    begin
      MoveCursorVT(Region.ScreenX, Region.ScreenY);
      WriteVT(Region.SixelData);
    end;

    { Handle cell buffer sync for Phase 2 (always, even if emission skipped) }
    for Y := Region.ScreenY to Region.ScreenY + Region.CellH - 1 do
      for X := Region.ScreenX to Region.ScreenX + Region.CellW - 1 do
        if (Y >= 0) and (Y < FHeight) and (X >= 0) and (X < FWidth) then
        begin
          if FCells[Y, X].Ch = SixelPlaceholder then
            { Placeholder cells: mark as up-to-date so Phase 2 skips them }
            FOldCells[Y, X] := FCells[Y, X]
          else
            { Non-placeholder cells (dialog/menu on top): force redraw
              in Phase 2 so text renders on top of the Sixel pixels }
            FOldCells[Y, X].Ch := #0;
        end;
  end;
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
  SetLength(FGRGBBuf, BufSize);
  SetLength(BGRGBBuf, BufSize);
  for var I := 0 to BufSize - 1 do begin
    LegacyBuf[I] := $0720;
    UnicodeCharBuf[I] := ' ';
    FGRGBBuf[I] := 0;
    BGRGBBuf[I] := 0;
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
  ChStr: string;
  Attr: Byte;
begin
  if (Screen = nil) or not Screen.Initialized then Exit;

  for Y := 0 to Screen.Height - 1 do begin
    for X := 0 to Screen.Width - 1 do begin
      I := Y * Screen.Width + X;
      if I < Length(LegacyBuf) then begin
        Cell := VideoBuf^[I];
        { Use Unicode string from parallel buffer instead of Lo(Cell) }
        if (I < Length(UnicodeCharBuf)) and (UnicodeCharBuf[I] <> '') then
          ChStr := UnicodeCharBuf[I]
        else
          ChStr := Char(Lo(Cell));
        Attr := Hi(Cell);
        Screen.SetCellAttr(X, Y, ChStr, Attr);
        { Transfer RGB overlay from parallel buffers }
        if I < Length(FGRGBBuf) then
          Screen.SetCellRGB(X, Y, FGRGBBuf[I], BGRGBBuf[I]);
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
