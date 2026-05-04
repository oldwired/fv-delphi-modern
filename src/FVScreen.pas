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

{$R-}  { Disable range checking for legacy buffer operations }

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
    FByteStr: array[0..255] of string;         // Pre-built IntToStr lookup for 0..255

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
    procedure SetCellExtAttrs(X, Y: Integer; ExtAttrs: Byte);
    procedure SetCellHyperlink(X, Y: Integer; const URL: string);
    procedure SetCellULRGB(X, Y: Integer; AUL_RGB: Cardinal);
    function GetCell(X, Y: Integer): TScreenCell;

    { Rendering }
    procedure UpdateScreen(Force: Boolean = False);
    procedure ClearScreen;

    { Sixel support }
    procedure RegisterSixelRegion(ScreenX, ScreenY, CellW, CellH: Integer;
      const SixelData: string);

    { Terminal window title }
    procedure SetWindowTitle(const ATitle: string);

    { Runtime palette manipulation (OSC 4 / 10 / 11 / 104).

      The 16 / 256 colour palettes belong to the terminal, not FV - SGR
      30-37, 90-97 and 38;5;N are abstract slot names whose RGB the
      terminal decides. These helpers ask the terminal to redefine
      individual slots for the lifetime of the session. Widely supported
      (Windows Terminal, xterm, iTerm2, WezTerm, mintty, kitty); silently
      ignored on conhost without VT and on the NoColors profile.

      Pair every EmitPaletteEntry / EmitDefaultFg / EmitDefaultBg with a
      ResetPalette before exiting, otherwise the user's themed palette
      stays redefined until they close the terminal. }
    procedure EmitPaletteEntry(Index: Byte; RGB: Cardinal);
    procedure ResetPaletteEntry(Index: Byte);
    procedure ResetPalette;
    procedure EmitDefaultFg(RGB: Cardinal);
    procedure EmitDefaultBg(RGB: Cardinal);
    procedure ResetDefaultColors;

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

  { Extended text attribute buffer - parallel to VideoBuf }
  ExtAttrsBuf: array of Byte;
  { Hyperlink URL buffer - parallel to VideoBuf for OSC 8 links }
  HyperlinkBuf: array of string;
  { Underline color buffer - parallel to VideoBuf for SGR 58 }
  ULRGBBuf: array of Cardinal;

{ Legacy API - calls through to Screen object }
procedure InitVideo;
procedure DoneVideo;
procedure MarkVideoDirty;
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
  FVUTF8,
  FVProfile;

const
  { VT Escape sequences }
  VT_ESC = #27;
  VT_CSI = VT_ESC + '[';

  { Console mode flags for VT }
  ENABLE_VIRTUAL_TERMINAL_PROCESSING = $0004;
  DISABLE_NEWLINE_AUTO_RETURN = $0008;
  ENABLE_VIRTUAL_TERMINAL_INPUT = $0200;

var
  LegacyBufPtr: PVideoBuf;
  LegacyOldBufPtr: PVideoBuf;
  LegacyBufCells: Integer;
  VideoBufDirty: Boolean;

{ TScreenBuffer }

constructor TScreenBuffer.Create;
var
  I: Integer;
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
  FOutputBuffer := TStringBuilder.Create(256 * 1024);
  FSixelRegions := TList<TSixelRegion>.Create;
  FSixelPrevRegions := TList<TSixelRegion>.Create;
  FSixelSupported := False;
  FCellPixelWidth := 8;
  FCellPixelHeight := 16;
  { Pre-build IntToStr lookup for all byte values }
  for I := 0 to 255 do
    FByteStr[I] := IntToStr(I);
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
  { Enable VT processing on stdout. Capability probe lives in FVProfile —
    if the probe couldn't get the VT bit to stick we still leave the
    handle valid but skip the optional DISABLE_NEWLINE_AUTO_RETURN tweak
    so we don't accumulate flags on a host that ignores them. }
  FConsoleOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  FConsoleInput := GetStdHandle(STD_INPUT_HANDLE);

  if FConsoleOutput <> INVALID_HANDLE_VALUE then begin
    GetConsoleMode(FConsoleOutput, FOriginalOutputMode);
    if ProbeVirtualTerminal(FConsoleOutput) then begin
      Mode := FOriginalOutputMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING
                                  or DISABLE_NEWLINE_AUTO_RETURN;
      if not SetConsoleMode(FConsoleOutput, Mode) then begin
        Mode := FOriginalOutputMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        SetConsoleMode(FConsoleOutput, Mode);
      end;
    end;
    { Populate the singleton profile after the probe so the rest of FV
      (color-system downsampling, hyperlink/Sixel detection, CI awareness)
      sees the post-probe state. }
    InitFVProfile;
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

{ OSC palette helpers. Gated on AnsiSupported AND a color-emitting profile.
  When NO_COLOR=1 is set, AnsiSupported can still be True (so OSC 8 hyperlinks
  and Sixel keep working), but ColorSystem becomes fvcsNoColors - in that
  case we must not recolor the user's terminal via OSC 4 / 10 / 11 / 104.
  The format used here is the 2-hex-digit form ESC]4;N;rgb:RR/GG/BBESC\
  which is accepted by every modern terminal we care about. }

function PaletteEmitAllowed: Boolean;
var P: TFVProfile;
begin
  P := GetFVProfile;
  Result := P.AnsiSupported and (P.ColorSystem <> fvcsNoColors);
end;

procedure TScreenBuffer.EmitPaletteEntry(Index: Byte; RGB: Cardinal);
const
  Hex: array[0..15] of Char =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
var
  R, G, B: Byte;
  S: string;
begin
  if not PaletteEmitAllowed then Exit;
  R := (RGB shr 16) and $FF;
  G := (RGB shr 8) and $FF;
  B := RGB and $FF;
  S := VT_ESC + ']4;' + IntToStr(Index) + ';rgb:' +
       Hex[R shr 4] + Hex[R and $F] + '/' +
       Hex[G shr 4] + Hex[G and $F] + '/' +
       Hex[B shr 4] + Hex[B and $F] + VT_ESC + '\';
  WriteVT(S);
  FlushVT;
end;

procedure TScreenBuffer.ResetPaletteEntry(Index: Byte);
begin
  if not PaletteEmitAllowed then Exit;
  WriteVT(VT_ESC + ']104;' + IntToStr(Index) + VT_ESC + '\');
  FlushVT;
end;

procedure TScreenBuffer.ResetPalette;
begin
  if not PaletteEmitAllowed then Exit;
  WriteVT(VT_ESC + ']104' + VT_ESC + '\');
  FlushVT;
end;

procedure TScreenBuffer.EmitDefaultFg(RGB: Cardinal);
var
  R, G, B: Byte;
begin
  if not PaletteEmitAllowed then Exit;
  R := (RGB shr 16) and $FF;
  G := (RGB shr 8) and $FF;
  B := RGB and $FF;
  WriteVT(VT_ESC + ']10;rgb:' +
    IntToHex(R, 2) + '/' + IntToHex(G, 2) + '/' + IntToHex(B, 2) +
    VT_ESC + '\');
  FlushVT;
end;

procedure TScreenBuffer.EmitDefaultBg(RGB: Cardinal);
var
  R, G, B: Byte;
begin
  if not PaletteEmitAllowed then Exit;
  R := (RGB shr 16) and $FF;
  G := (RGB shr 8) and $FF;
  B := RGB and $FF;
  WriteVT(VT_ESC + ']11;rgb:' +
    IntToHex(R, 2) + '/' + IntToHex(G, 2) + '/' + IntToHex(B, 2) +
    VT_ESC + '\');
  FlushVT;
end;

procedure TScreenBuffer.ResetDefaultColors;
begin
  if not PaletteEmitAllowed then Exit;
  { OSC 110 / 111 reset default fg / bg respectively. }
  WriteVT(VT_ESC + ']110' + VT_ESC + '\');
  WriteVT(VT_ESC + ']111' + VT_ESC + '\');
  FlushVT;
end;

function TScreenBuffer.CellsDiffer(X, Y: Integer): Boolean;
begin
  Result := (FCells[Y, X].Ch <> FOldCells[Y, X].Ch) or
            (FCells[Y, X].FG <> FOldCells[Y, X].FG) or
            (FCells[Y, X].BG <> FOldCells[Y, X].BG) or
            (FCells[Y, X].Bold <> FOldCells[Y, X].Bold) or
            (FCells[Y, X].Underline <> FOldCells[Y, X].Underline) or
            (FCells[Y, X].Inverse <> FOldCells[Y, X].Inverse) or
            (FCells[Y, X].Italic <> FOldCells[Y, X].Italic) or
            (FCells[Y, X].Strikethrough <> FOldCells[Y, X].Strikethrough) or
            (FCells[Y, X].UnderlineStyle <> FOldCells[Y, X].UnderlineStyle) or
            (FCells[Y, X].Dim <> FOldCells[Y, X].Dim) or
            (FCells[Y, X].Overline <> FOldCells[Y, X].Overline) or
            (FCells[Y, X].FG_RGB <> FOldCells[Y, X].FG_RGB) or
            (FCells[Y, X].BG_RGB <> FOldCells[Y, X].BG_RGB) or
            (FCells[Y, X].UL_RGB <> FOldCells[Y, X].UL_RGB) or
            (FCells[Y, X].HyperlinkURL <> FOldCells[Y, X].HyperlinkURL);
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

procedure TScreenBuffer.SetCellExtAttrs(X, Y: Integer; ExtAttrs: Byte);
begin
  if not FInitialized then Exit;
  if (X < 0) or (X >= FWidth) or (Y < 0) or (Y >= FHeight) then Exit;
  FCells[Y, X].Italic := (ExtAttrs and eaItalic) <> 0;
  FCells[Y, X].Strikethrough := (ExtAttrs and eaStrikethrough) <> 0;
  FCells[Y, X].UnderlineStyle := (ExtAttrs and eaUnderMask) shr eaUnderShift;
  FCells[Y, X].Underline := FCells[Y, X].UnderlineStyle > 0;
  FCells[Y, X].Dim := (ExtAttrs and eaDim) <> 0;
  FCells[Y, X].Overline := (ExtAttrs and eaOverline) <> 0;
end;

procedure TScreenBuffer.SetCellHyperlink(X, Y: Integer; const URL: string);
begin
  if not FInitialized then Exit;
  if (X < 0) or (X >= FWidth) or (Y < 0) or (Y >= FHeight) then Exit;
  FCells[Y, X].HyperlinkURL := URL;
end;

procedure TScreenBuffer.SetCellULRGB(X, Y: Integer; AUL_RGB: Cardinal);
begin
  if not FInitialized then Exit;
  if (X < 0) or (X >= FWidth) or (Y < 0) or (Y >= FHeight) then Exit;
  FCells[Y, X].UL_RGB := AUL_RGB;
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
  IsWide: Boolean;
  { Cursor tracking - skip MoveCursorVT when cells are consecutive }
  ExpectX, ExpectY: Integer;
  CursorKnown: Boolean;
  { Differential SGR - only emit color components that changed }
  PrevFG_RGB, PrevBG_RGB: Cardinal;
  PrevFGIdx, PrevBGIdx: Byte;
  PrevBold, PrevUnder, PrevInv: Boolean;
  PrevItalic, PrevStrike: Boolean;
  PrevDim, PrevOverline: Boolean;
  PrevUnderStyle: Byte;
  PrevUL_RGB: Cardinal;
  PrevHyperlink: string;
  HyperlinkId: Cardinal;
  CurFG_RGB, CurBG_RGB: Cardinal;
  CurFGIdx, CurBGIdx: Byte;
  NeedReset, NeedFG, NeedBG, SGRStarted: Boolean;
  FGDownsampled, BGDownsampled: Boolean;
  ColorSys: TFVColorSystem;
  NoColors: Boolean;
  Legacy16: Boolean;
  CurRegion, PrevRegion: TSixelRegion;
  RegionIdx: Integer;
  FoundRegion: Boolean;

  function QuantizeRGBTo256(RGB: Cardinal): Byte;
  const
    AXIS: array[0..5] of Byte = (0, 95, 135, 175, 215, 255);
    function Level(C: Byte): Byte;
    var I, BestIdx, BestD, D: Integer;
    begin
      BestIdx := 0; BestD := 256;
      for I := 0 to 5 do
      begin
        D := Abs(Integer(C) - Integer(AXIS[I]));
        if D < BestD then begin BestD := D; BestIdx := I; end;
      end;
      Result := BestIdx;
    end;
  var
    R, G, B, Lr, Lg, Lb: Byte;
  begin
    R := (RGB shr 16) and $FF;
    G := (RGB shr 8) and $FF;
    B := RGB and $FF;
    Lr := Level(R); Lg := Level(G); Lb := Level(B);
    Result := 16 + 36 * Lr + 6 * Lg + Lb;
  end;

  function QuantizeRGBTo16(RGB: Cardinal): Byte;
  const
    PALETTE: array[0..15, 0..2] of Byte = (
      (  0,   0,   0),  ( 128,   0,   0),  (   0, 128,   0),  ( 128, 128,   0),
      (  0,   0, 128),  ( 128,   0, 128),  (   0, 128, 128),  ( 192, 192, 192),
      (128, 128, 128),  ( 255,   0,   0),  (   0, 255,   0),  ( 255, 255,   0),
      (  0,   0, 255),  ( 255,   0, 255),  (   0, 255, 255),  ( 255, 255, 255)
    );
  var
    R, G, B: Integer;
    I, BestIdx, BestD, DR, DG, DB, D: Integer;
  begin
    R := (RGB shr 16) and $FF;
    G := (RGB shr 8) and $FF;
    B := RGB and $FF;
    BestIdx := 7; BestD := MaxInt;
    for I := 0 to 15 do
    begin
      DR := R - PALETTE[I, 0];
      DG := G - PALETTE[I, 1];
      DB := B - PALETTE[I, 2];
      D := DR * DR + DG * DG + DB * DB;
      if D < BestD then begin BestD := D; BestIdx := I; end;
    end;
    { PALETTE is in standard ANSI 16-colour order (Black, Red, Green,
      Yellow, Blue, Magenta, Cyan, White, then 8 bright). The xterm-256
      indices 0..15 use the same order, and SGR 30-37 / 90-97 also match,
      so BestIdx directly serves both emit paths. (The earlier
      ColorMap[BestIdx] was wrong - that table is keyed by FV's own
      colour codes, which is a different ordering.) }
    Result := BestIdx;
  end;

begin
  if not FInitialized then Exit;
  HyperlinkId := 0;
  { Cache the profile once per frame: GetFVProfile returns a record value,
    re-evaluating per cell would be wasteful. NoColors=True suppresses both
    the 38;5/48;5 color emits AND the palette-index fallback below, so a
    NO_COLOR profile produces text without any FG/BG colour codes. }
  ColorSys := GetFVProfile.ColorSystem;
  NoColors := ColorSys = fvcsNoColors;
  Legacy16 := ColorSys = fvcsLegacy;

  { Begin synchronized output (DEC mode 2026): the terminal buffers all
    changes and applies them atomically when the end sequence arrives.
    This prevents flicker when sixel pixel data and overlapping text cells
    (e.g., dialog over sixel view) are emitted in the same frame. The
    matching disable sequence runs in the finally block so a mid-frame
    exception doesn't leave the terminal stuck in synchronized mode. }
  WriteVT(VT_CSI + '?2026h');
  try

  { Phase 0: Erase any previous Sixel regions that moved or disappeared }
  if FSixelPrevRegions.Count > 0 then
    EraseStaleSixelRegions;

  { Phase 1: Emit registered Sixel regions (pixel layer underneath text) }
  if FSixelRegions.Count > 0 then
    EmitSixelRegions;

  { Phase 2: Optimized cell rendering with cursor tracking + differential SGR }
  CursorKnown := False;
  PrevFG_RGB := $FFFFFFFF;  { Impossible value forces first emit }
  PrevBG_RGB := $FFFFFFFF;
  PrevFGIdx := 255;
  PrevBGIdx := 255;
  PrevBold := False;
  PrevUnder := False;
  PrevInv := False;
  PrevItalic := False;
  PrevStrike := False;
  PrevDim := False;
  PrevOverline := False;
  PrevUnderStyle := 0;
  PrevUL_RGB := 0;
  PrevHyperlink := '';

  for Y := 0 to FHeight - 1 do begin
    X := 0;
    while X < FWidth do begin
      if Force or CellsDiffer(X, Y) then begin
        { Skip Sixel placeholder cells - they are covered by Sixel pixel data }
        if FCells[Y, X].Ch = SixelPlaceholder then begin
          FOldCells[Y, X] := FCells[Y, X];
          CursorKnown := False;
          Inc(X);
          Continue;
        end;

        { Cursor positioning: skip if cursor is already at correct position
          from the previous character output (terminal auto-advances cursor) }
        if not (CursorKnown and (X = ExpectX) and (Y = ExpectY)) then
          MoveCursorVT(X, Y);

        { Determine current cell's color state. Capability-aware
          downsampling collapses 24-bit RGB to a 256/16 palette index when
          the host terminal can't handle truecolor. }
        CurFG_RGB := FCells[Y, X].FG_RGB;
        CurBG_RGB := FCells[Y, X].BG_RGB;
        FGDownsampled := False;
        BGDownsampled := False;

        case ColorSys of
          fvcsNoColors:
            begin
              { Skip the palette fallback entirely - emitter checks NoColors
                and won't write 38;5/48;5 sequences. }
              CurFG_RGB := 0;
              CurBG_RGB := 0;
              FGDownsampled := True;
              BGDownsampled := True;
            end;
          fvcsEightBit:
            begin
              if CurFG_RGB <> 0 then begin
                CurFGIdx := QuantizeRGBTo256(CurFG_RGB);
                CurFG_RGB := 0;
                FGDownsampled := True;
              end;
              if CurBG_RGB <> 0 then begin
                CurBGIdx := QuantizeRGBTo256(CurBG_RGB);
                CurBG_RGB := 0;
                BGDownsampled := True;
              end;
            end;
          fvcsLegacy:
            begin
              if CurFG_RGB <> 0 then begin
                CurFGIdx := QuantizeRGBTo16(CurFG_RGB);
                CurFG_RGB := 0;
                FGDownsampled := True;
              end;
              if CurBG_RGB <> 0 then begin
                CurBGIdx := QuantizeRGBTo16(CurBG_RGB);
                CurBG_RGB := 0;
                BGDownsampled := True;
              end;
            end;
          fvcsTrueColor: ;  { Pass through }
        end;

        if (CurFG_RGB = 0) and not FGDownsampled then begin
          if FCells[Y, X].FG < 16 then
            CurFGIdx := ColorMap[FCells[Y, X].FG]
          else
            CurFGIdx := FCells[Y, X].FG;
        end;
        if (CurBG_RGB = 0) and not BGDownsampled then begin
          if FCells[Y, X].BG < 16 then
            CurBGIdx := ColorMap[FCells[Y, X].BG]
          else
            CurBGIdx := FCells[Y, X].BG;
        end;

        { Check if we need a full SGR reset: required on first cell, or when
          text attributes (bold/underline/inverse) change — these can't be
          turned off individually without a reset }
        NeedReset := (PrevFG_RGB = $FFFFFFFF) or
          (FCells[Y, X].Bold <> PrevBold) or
          (FCells[Y, X].Dim <> PrevDim) or
          (FCells[Y, X].Italic <> PrevItalic) or
          (FCells[Y, X].Strikethrough <> PrevStrike) or
          (FCells[Y, X].UnderlineStyle <> PrevUnderStyle) or
          (FCells[Y, X].Underline <> PrevUnder) or
          (FCells[Y, X].Inverse <> PrevInv) or
          (FCells[Y, X].Overline <> PrevOverline) or
          (FCells[Y, X].UL_RGB <> PrevUL_RGB);

        if NeedReset then begin
          { Full SGR: reset + all attributes + both colors }
          FOutputBuffer.Append(VT_CSI);
          FOutputBuffer.Append('0');
          if FCells[Y, X].Bold then FOutputBuffer.Append(';1');
          if FCells[Y, X].Dim then FOutputBuffer.Append(';2');
          if FCells[Y, X].Italic then FOutputBuffer.Append(';3');
          case FCells[Y, X].UnderlineStyle of
            1: FOutputBuffer.Append(';4');
            2: FOutputBuffer.Append(';21');
            3: FOutputBuffer.Append(';4:3');
            4: FOutputBuffer.Append(';4:4');
            5: FOutputBuffer.Append(';4:5');
          else
            if FCells[Y, X].Underline then FOutputBuffer.Append(';4');
          end;
          if FCells[Y, X].Inverse then FOutputBuffer.Append(';7');
          if FCells[Y, X].Strikethrough then FOutputBuffer.Append(';9');
          if FCells[Y, X].Overline then FOutputBuffer.Append(';53');

          if not NoColors then begin
            if CurFG_RGB <> 0 then begin
              FOutputBuffer.Append(';38;2;');
              FOutputBuffer.Append(FByteStr[(CurFG_RGB shr 16) and $FF]);
              FOutputBuffer.Append(';');
              FOutputBuffer.Append(FByteStr[(CurFG_RGB shr 8) and $FF]);
              FOutputBuffer.Append(';');
              FOutputBuffer.Append(FByteStr[CurFG_RGB and $FF]);
            end else if Legacy16 then begin
              { Native 16-colour SGR: 30-37 dark, 90-97 bright. Clamp any
                stray 256-palette index back into the 16-colour space. }
              if CurFGIdx > 15 then CurFGIdx := 7;
              FOutputBuffer.Append(';');
              if CurFGIdx < 8 then
                FOutputBuffer.Append(FByteStr[30 + CurFGIdx])
              else
                FOutputBuffer.Append(FByteStr[90 + CurFGIdx - 8]);
            end else begin
              FOutputBuffer.Append(';38;5;');
              FOutputBuffer.Append(FByteStr[CurFGIdx]);
            end;

            if CurBG_RGB <> 0 then begin
              FOutputBuffer.Append(';48;2;');
              FOutputBuffer.Append(FByteStr[(CurBG_RGB shr 16) and $FF]);
              FOutputBuffer.Append(';');
              FOutputBuffer.Append(FByteStr[(CurBG_RGB shr 8) and $FF]);
              FOutputBuffer.Append(';');
              FOutputBuffer.Append(FByteStr[CurBG_RGB and $FF]);
            end else if Legacy16 then begin
              if CurBGIdx > 15 then CurBGIdx := 0;
              FOutputBuffer.Append(';');
              if CurBGIdx < 8 then
                FOutputBuffer.Append(FByteStr[40 + CurBGIdx])
              else
                FOutputBuffer.Append(FByteStr[100 + CurBGIdx - 8]);
            end else begin
              FOutputBuffer.Append(';48;5;');
              FOutputBuffer.Append(FByteStr[CurBGIdx]);
            end;

            { Underline color (SGR 58;2;R;G;B) - only meaningful for
              terminals that handle 24-bit; suppress in NoColors and skip
              entirely in Legacy16 since SGR 58 has no 16-colour form. }
            if (not Legacy16) and (FCells[Y, X].UL_RGB <> 0) then begin
              FOutputBuffer.Append(';58;2;');
              FOutputBuffer.Append(FByteStr[(FCells[Y, X].UL_RGB shr 16) and $FF]);
              FOutputBuffer.Append(';');
              FOutputBuffer.Append(FByteStr[(FCells[Y, X].UL_RGB shr 8) and $FF]);
              FOutputBuffer.Append(';');
              FOutputBuffer.Append(FByteStr[FCells[Y, X].UL_RGB and $FF]);
            end;
          end;

          FOutputBuffer.Append('m');
          PrevBold := FCells[Y, X].Bold;
          PrevUnder := FCells[Y, X].Underline;
          PrevInv := FCells[Y, X].Inverse;
          PrevItalic := FCells[Y, X].Italic;
          PrevStrike := FCells[Y, X].Strikethrough;
          PrevDim := FCells[Y, X].Dim;
          PrevOverline := FCells[Y, X].Overline;
          PrevUnderStyle := FCells[Y, X].UnderlineStyle;
          PrevUL_RGB := FCells[Y, X].UL_RGB;
        end
        else begin
          { Differential SGR: only emit color components that changed.
            In NoColors profile we never emit colour at all - keep both
            flags False so the diff block below is skipped. }
          NeedFG := False;
          NeedBG := False;

          if not NoColors then begin
            if CurFG_RGB <> 0 then begin
              if CurFG_RGB <> PrevFG_RGB then NeedFG := True;
            end else begin
              if (PrevFG_RGB <> 0) or (CurFGIdx <> PrevFGIdx) then NeedFG := True;
            end;

            if CurBG_RGB <> 0 then begin
              if CurBG_RGB <> PrevBG_RGB then NeedBG := True;
            end else begin
              if (PrevBG_RGB <> 0) or (CurBGIdx <> PrevBGIdx) then NeedBG := True;
            end;
          end;

          if NeedFG or NeedBG then begin
            FOutputBuffer.Append(VT_CSI);
            SGRStarted := False;

            if NeedFG then begin
              if CurFG_RGB <> 0 then begin
                FOutputBuffer.Append('38;2;');
                FOutputBuffer.Append(FByteStr[(CurFG_RGB shr 16) and $FF]);
                FOutputBuffer.Append(';');
                FOutputBuffer.Append(FByteStr[(CurFG_RGB shr 8) and $FF]);
                FOutputBuffer.Append(';');
                FOutputBuffer.Append(FByteStr[CurFG_RGB and $FF]);
              end else if Legacy16 then begin
                if CurFGIdx > 15 then CurFGIdx := 7;
                if CurFGIdx < 8 then
                  FOutputBuffer.Append(FByteStr[30 + CurFGIdx])
                else
                  FOutputBuffer.Append(FByteStr[90 + CurFGIdx - 8]);
              end else begin
                FOutputBuffer.Append('38;5;');
                FOutputBuffer.Append(FByteStr[CurFGIdx]);
              end;
              SGRStarted := True;
            end;

            if NeedBG then begin
              if SGRStarted then FOutputBuffer.Append(';');
              if CurBG_RGB <> 0 then begin
                FOutputBuffer.Append('48;2;');
                FOutputBuffer.Append(FByteStr[(CurBG_RGB shr 16) and $FF]);
                FOutputBuffer.Append(';');
                FOutputBuffer.Append(FByteStr[(CurBG_RGB shr 8) and $FF]);
                FOutputBuffer.Append(';');
                FOutputBuffer.Append(FByteStr[CurBG_RGB and $FF]);
              end else if Legacy16 then begin
                if CurBGIdx > 15 then CurBGIdx := 0;
                if CurBGIdx < 8 then
                  FOutputBuffer.Append(FByteStr[40 + CurBGIdx])
                else
                  FOutputBuffer.Append(FByteStr[100 + CurBGIdx - 8]);
              end else begin
                FOutputBuffer.Append('48;5;');
                FOutputBuffer.Append(FByteStr[CurBGIdx]);
              end;
            end;

            FOutputBuffer.Append('m');
          end;
        end;

        { Update SGR tracking state }
        PrevFG_RGB := CurFG_RGB;
        PrevBG_RGB := CurBG_RGB;
        PrevFGIdx := CurFGIdx;
        PrevBGIdx := CurBGIdx;

        { OSC 8 hyperlink: emit open/close when URL changes. The id=N
          parameter keeps multi-cell text wrapped as a single clickable
          region in Windows Terminal, iTerm2, and others - without it,
          each cell becomes its own micro-link and hover/click fragments. }
        if FCells[Y, X].HyperlinkURL <> PrevHyperlink then begin
          if PrevHyperlink <> '' then
            FOutputBuffer.Append(VT_ESC + ']8;;' + VT_ESC + '\');
          if FCells[Y, X].HyperlinkURL <> '' then begin
            Inc(HyperlinkId);
            FOutputBuffer.Append(VT_ESC + ']8;id=' + IntToStr(HyperlinkId) + ';' +
              FCells[Y, X].HyperlinkURL + VT_ESC + '\');
          end;
          PrevHyperlink := FCells[Y, X].HyperlinkURL;
        end;

        { Output character }
        if FCells[Y, X].Ch <> '' then
          FOutputBuffer.Append(FCells[Y, X].Ch)
        else
          FOutputBuffer.Append(' ');

        { Update old buffer }
        FOldCells[Y, X] := FCells[Y, X];

        { Track cursor for sequential detection + handle wide characters }
        IsWide := IsWideString(FCells[Y, X].Ch);
        if IsWide and (X + 1 < FWidth) then begin
          FOldCells[Y, X + 1] := FCells[Y, X + 1];
          Inc(X);  { Skip the continuation cell }
        end;
        ExpectX := X + 1;
        ExpectY := Y;
        CursorKnown := True;
      end
      else
        CursorKnown := False;
      Inc(X);
    end;
  end;

  { Phase 3: Save current Sixel regions for stale detection, then clear.
    Merge instead of replacing: a partial redraw may register only one Sixel
    view while other visible Sixel regions should remain active. }
  if FSixelRegions.Count > 0 then
  begin
    for CurRegion in FSixelRegions do
    begin
      FoundRegion := False;
      for RegionIdx := 0 to FSixelPrevRegions.Count - 1 do
      begin
        PrevRegion := FSixelPrevRegions[RegionIdx];
        if (PrevRegion.ScreenX = CurRegion.ScreenX) and
           (PrevRegion.ScreenY = CurRegion.ScreenY) and
           (PrevRegion.CellW = CurRegion.CellW) and
           (PrevRegion.CellH = CurRegion.CellH) then
        begin
          FSixelPrevRegions[RegionIdx] := CurRegion;
          FoundRegion := True;
          Break;
        end;
      end;
      if not FoundRegion then
        FSixelPrevRegions.Add(CurRegion);
    end;
  end;
  FSixelRegions.Clear;

  { Close any open hyperlink before resetting attributes }
  if PrevHyperlink <> '' then
    WriteVT(VT_ESC + ']8;;' + VT_ESC + '\');

  { Reset attributes and restore cursor }
  WriteVT(VT_CSI + '0m');
  if FCursorVisible then begin
    MoveCursorVT(FCursorX, FCursorY);
    WriteVT(VT_CSI + '?25h');
  end;

  finally
    { End synchronized output: always emit the disable sequence even when
      the body raises, so a mid-frame exception can't leave the terminal
      stuck in synchronized mode (frozen display until the next disable). }
    WriteVT(VT_CSI + '?2026l');
    FlushVT;
  end;
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
  { Delegate to FVProfile so the answer matches what the Capability Showcase
    advertises. FVProfile widens beyond the bare WT_SESSION check to include
    WezTerm, mintty, and xterm-kitty / mlterm via TERM. }
  FSixelSupported := GetFVProfile.SixelSupport;
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
  OverlapsCurrent: Boolean;
  HasActivePlaceholders: Boolean;
  ErasedAnyCell: Boolean;
  SpanStart, SpanLen: Integer;
  Cur: TSixelRegion;
  ErasedIndices: TList<Integer>;

  function SameRegion(const A, B: TSixelRegion): Boolean;
  begin
    Result := (A.ScreenX = B.ScreenX) and (A.ScreenY = B.ScreenY) and
      (A.CellW = B.CellW) and (A.CellH = B.CellH);
  end;

  function RegionsOverlap(const A, B: TSixelRegion): Boolean;
  begin
    Result := (A.ScreenX < B.ScreenX + B.CellW) and
      (A.ScreenX + A.CellW > B.ScreenX) and
      (A.ScreenY < B.ScreenY + B.CellH) and
      (A.ScreenY + A.CellH > B.ScreenY);
  end;

  procedure EraseSpan(AY, AX, AWidth: Integer);
  var
    K: Integer;
  begin
    if (AWidth <= 0) or (AY < 0) or (AY >= FHeight) or
       (AX < 0) or (AX >= FWidth) then
      Exit;
    if AX + AWidth > FWidth then
      AWidth := FWidth - AX;
    if AWidth <= 0 then Exit;

    MoveCursorVT(AX, AY);
    WriteVT(VT_CSI + IntToStr(AWidth) + 'X');
    for K := AX to AX + AWidth - 1 do
      FOldCells[AY, K].Ch := #0;
  end;
begin
  { For each previous Sixel region, check if it's still covered by a current
    region at the same position. If not, the cells at the old position need
    to be force-redrawn so Phase 2 overwrites the stale Sixel pixels. Partial
    redraws may register only the changed Sixel view; unchanged sibling
    regions are preserved while their placeholder cells are still present.
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
        if SameRegion(Cur, Prev) then
        begin
          IsStale := False;
          Break;
        end;
      end;

      if IsStale then
      begin
        { If no current region overlaps the old one, it may still be active -
          Draw just wasn't called for it during this partial redraw. Preserve
          placeholder cells, but erase cells that are now covered by normal
          text/window content so stale Sixel pixels cannot bleed through. }
        OverlapsCurrent := False;
        for Cur in FSixelRegions do
          if RegionsOverlap(Prev, Cur) then
          begin
            OverlapsCurrent := True;
            Break;
          end;

        if not OverlapsCurrent then
        begin
          HasActivePlaceholders := False;
          ErasedAnyCell := False;
          WriteVT(VT_CSI + '0m');
          for Y := Prev.ScreenY to Prev.ScreenY + Prev.CellH - 1 do
          begin
            SpanStart := -1;
            SpanLen := 0;
            for X := Prev.ScreenX to Prev.ScreenX + Prev.CellW - 1 do
            begin
              if (Y < 0) or (Y >= FHeight) or (X < 0) or (X >= FWidth) then
                Continue;
              if FCells[Y, X].Ch = SixelPlaceholder then
              begin
                HasActivePlaceholders := True;
                if SpanStart <> -1 then
                begin
                  EraseSpan(Y, SpanStart, SpanLen);
                  ErasedAnyCell := True;
                  SpanStart := -1;
                  SpanLen := 0;
                end;
              end
              else
              begin
                if SpanStart = -1 then
                begin
                  SpanStart := X;
                  SpanLen := 1;
                end
                else
                  Inc(SpanLen);
              end;
            end;
            if SpanStart <> -1 then
            begin
              EraseSpan(Y, SpanStart, SpanLen);
              ErasedAnyCell := True;
            end;
          end;
          if HasActivePlaceholders then
            Continue;
          if ErasedAnyCell then
          begin
            ErasedIndices.Add(I);
            Continue;
          end;
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

  { Allocate legacy buffers dynamically based on actual screen size }
  BufSize := Integer(ScreenWidth) * Integer(ScreenHeight);
  ReallocMem(LegacyBufPtr, BufSize * SizeOf(TVideoCell));
  ReallocMem(LegacyOldBufPtr, BufSize * SizeOf(TVideoCell));
  LegacyBufCells := BufSize;
  FillChar(LegacyBufPtr^, BufSize * SizeOf(TVideoCell), 0);
  FillChar(LegacyOldBufPtr^, BufSize * SizeOf(TVideoCell), 0);
  VideoBuf := LegacyBufPtr;
  OldVideoBuf := LegacyOldBufPtr;

  { Initialize Unicode character buffer }
  SetLength(UnicodeCharBuf, BufSize);
  SetLength(FGRGBBuf, BufSize);
  SetLength(BGRGBBuf, BufSize);
  SetLength(ExtAttrsBuf, BufSize);
  SetLength(HyperlinkBuf, BufSize);
  SetLength(ULRGBBuf, BufSize);
  for var I := 0 to BufSize - 1 do begin
    VideoBuf^[I] := $0720;
    UnicodeCharBuf[I] := ' ';
    FGRGBBuf[I] := 0;
    BGRGBBuf[I] := 0;
    ExtAttrsBuf[I] := 0;
    HyperlinkBuf[I] := '';
    ULRGBBuf[I] := 0;
  end;
  VideoBufDirty := True;
end;

procedure DoneVideo;
begin
  if Screen <> nil then
    Screen.Done;
  FreeMem(LegacyBufPtr);
  LegacyBufPtr := nil;
  FreeMem(LegacyOldBufPtr);
  LegacyOldBufPtr := nil;
  LegacyBufCells := 0;
  VideoBuf := nil;
  OldVideoBuf := nil;
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
      if I < LegacyBufCells then begin
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
        { Transfer extended attributes }
        if I < Length(ExtAttrsBuf) then
          Screen.SetCellExtAttrs(X, Y, ExtAttrsBuf[I]);
        { Transfer hyperlink URLs }
        if I < Length(HyperlinkBuf) then
          Screen.SetCellHyperlink(X, Y, HyperlinkBuf[I]);
        if I < Length(ULRGBBuf) then
          Screen.SetCellULRGB(X, Y, ULRGBBuf[I]);
      end;
    end;
  end;
end;

procedure MarkVideoDirty;
begin
  VideoBufDirty := True;
end;

procedure UpdateScreen(Force: Boolean);
begin
  if (not Force) and (not VideoBufDirty) then
    Exit;

  { Sync legacy buffer to new screen cells }
  SyncVideoBufToScreen;

  { Then update the VT screen }
  if Screen <> nil then
    Screen.UpdateScreen(Force);

  { Copy current to old for legacy diff detection }
  if VideoBuf <> nil then
    Move(VideoBuf^, OldVideoBuf^, Integer(ScreenWidth) * Integer(ScreenHeight) * 2);

  VideoBufDirty := False;
end;

procedure ClearScreen;
begin
  if Screen <> nil then
    Screen.ClearScreen;
  { Clear legacy buffer too }
  for var I := 0 to LegacyBufCells - 1 do
    VideoBuf^[I] := $0720;
  VideoBufDirty := True;
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
var
  BufSize: Integer;
begin
  if Screen <> nil then begin
    Screen.Resize(NewWidth, NewHeight);

    { Resize parallel legacy buffers to match new screen dimensions }
    BufSize := Integer(ScreenWidth) * Integer(ScreenHeight);
    ReallocMem(LegacyBufPtr, BufSize * SizeOf(TVideoCell));
    ReallocMem(LegacyOldBufPtr, BufSize * SizeOf(TVideoCell));
    LegacyBufCells := BufSize;
    FillChar(LegacyBufPtr^, BufSize * SizeOf(TVideoCell), 0);
    FillChar(LegacyOldBufPtr^, BufSize * SizeOf(TVideoCell), 0);
    VideoBuf := LegacyBufPtr;
    OldVideoBuf := LegacyOldBufPtr;
    SetLength(UnicodeCharBuf, BufSize);
    SetLength(FGRGBBuf, BufSize);
    SetLength(BGRGBBuf, BufSize);
    SetLength(ExtAttrsBuf, BufSize);
    SetLength(HyperlinkBuf, BufSize);
    SetLength(ULRGBBuf, BufSize);
    for var I := 0 to BufSize - 1 do begin
      VideoBuf^[I] := $0720;
      UnicodeCharBuf[I] := ' ';
      FGRGBBuf[I] := 0;
      BGRGBBuf[I] := 0;
      ExtAttrsBuf[I] := 0;
      HyperlinkBuf[I] := '';
      ULRGBBuf[I] := 0;
    end;
    VideoBufDirty := True;
  end;
end;

initialization
  Screen := nil;
  LegacyBufPtr := nil;
  LegacyOldBufPtr := nil;
  LegacyBufCells := 0;
  VideoBuf := nil;
  OldVideoBuf := nil;
  ScreenWidth := 80;
  ScreenHeight := 25;
  VideoBufDirty := True;

finalization
  FreeMem(LegacyBufPtr);
  FreeMem(LegacyOldBufPtr);
  if Screen <> nil then begin
    Screen.Free;
    Screen := nil;
  end;

end.
