{*******************************************************}
{       Terminal - VT100 Terminal Emulator Component    }
{       For Free Vision Text-Mode UI Framework          }
{       Requires ConPTY (Windows 10 1809+)              }
{*******************************************************}

unit Terminal;

{$R-}  { Disable range checking for buffer operations }

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Math,
  System.Generics.Collections,
  System.JSON,
  Objects, Drivers, Views, FVConsts, FVInterfaces, FVCommon, ConPTY, FVUTF8,
  FVClipboard;

{***************************************************************************}
{                              PUBLIC CONSTANTS                             }
{***************************************************************************}

const
  { Terminal default dimensions }
  DefaultTerminalWidth = 80;
  DefaultTerminalHeight = 24;
  DefaultScrollbackLines = 1000;

  { Terminal modes }
  tmNormal  = 0;   { Normal FV event handling }
  tmCapture = 1;   { Modal key capture - all keys to PTY }

  { Default escape key: Ctrl+A (tmux style) }
  DefaultEscapeKey = kbCtrlA;

  { Default attributes }
  DefaultTerminalAttr = $07;  { Light gray on black }

  { ANSI color codes }
  ansiBlack   = 0;
  ansiRed     = 1;
  ansiGreen   = 2;
  ansiYellow  = 3;
  ansiBlue    = 4;
  ansiMagenta = 5;
  ansiCyan    = 6;
  ansiWhite   = 7;

  { Terminal palette }
  CTerminal = #$70#$78#$7F#$70#$7F#$78#$70#$7F;

{***************************************************************************}
{                          PUBLIC TYPE DEFINITIONS                          }
{***************************************************************************}

type
  { Forward declarations }
  TTerminalBuffer = class;
  TTerminalParser = class;
  TTerminalPalette = class;
  TTerminalView = class;
  TTerminalWindow = class;

  { Terminal cell - stores character and attribute }
  TTerminalCell = record
    Ch: Char;      { Unicode character (WideChar) }
    Attr: Byte;
  end;
  PTerminalCell = ^TTerminalCell;

  { Terminal line - array of cells }
  TTerminalLine = array of TTerminalCell;
  PTerminalLine = ^TTerminalLine;

  { Selection point }
  TSelectionPoint = record
    X, Y: Integer;
  end;

  { Selection mode }
  TSelectionMode = (smNone, smChar, smLine);

{***************************************************************************}
{                         TTerminalPalette CLASS                            }
{***************************************************************************}

  TTerminalPalette = class
  private
    FColors: array[0..15] of Byte;

  public
    constructor Create;

    procedure SetColor(Index: Byte; FVColor: Byte);
    function GetColor(Index: Byte): Byte;
    procedure LoadDefault;
    procedure LoadFromJSON(const AJson: TJSONObject);
    function ToJSON: TJSONObject;

    { Map ANSI color to FV attribute }
    function MapForeground(ANSIColor: Byte): Byte;
    function MapBackground(ANSIColor: Byte): Byte;
    function CombineAttr(FG, BG: Byte): Byte;
  end;

{***************************************************************************}
{                          TTerminalBuffer CLASS                            }
{***************************************************************************}

  TTerminalBuffer = class
  private
    FLines: TList<TTerminalLine>;
    FLineWrapped: TList<Boolean>;   { True if line was soft-wrapped (no LF) }
    FWidth: Integer;
    FHeight: Integer;
    FScrollbackSize: Integer;
    FScrollbackStart: Integer;      { Index of first visible line in FLines }
    FScrollbackCount: Integer;      { Number of scrollback lines above visible area }
    FCursorX: Integer;              { 0-based cursor X }
    FCursorY: Integer;              { 0-based cursor Y }
    FCursorVisible: Boolean;
    FCurrentAttr: Byte;
    FReverseVideo: Boolean;
    FSavedCursorX: Integer;
    FSavedCursorY: Integer;
    FSavedAttr: Byte;
    FSavedReverseVideo: Boolean;
    FScrollTop: Integer;            { Scroll region top (0-based) }
    FScrollBottom: Integer;         { Scroll region bottom (0-based) }
    FDirtyTop: Integer;
    FDirtyBottom: Integer;
    FDirtyLeft: Integer;
    FDirtyRight: Integer;
    FAutoWrap: Boolean;
    FInsertMode: Boolean;
    FOriginMode: Boolean;           { Origin mode for cursor addressing }

    function GetLineIndex(Y: Integer): Integer;
    procedure EnsureLineExists(Index: Integer);
    procedure MarkDirty(X1, Y1, X2, Y2: Integer);
    procedure ReflowLines(OldWidth, NewWidth: Integer);
    function GetEffectiveAttr: Byte;

  public
    constructor Create(AWidth, AHeight, AScrollback: Integer);
    destructor Destroy; override;

    { Writing }
    procedure WriteGlyph(const Glyph: string);
    procedure WriteChar(Ch: Char);
    procedure WriteString(const S: string);

    { Cursor control }
    procedure MoveCursor(X, Y: Integer);
    procedure MoveCursorRel(DX, DY: Integer);
    procedure MoveCursorUp(Count: Integer = 1);
    procedure MoveCursorDown(Count: Integer = 1);
    procedure MoveCursorLeft(Count: Integer = 1);
    procedure MoveCursorRight(Count: Integer = 1);
    procedure MoveCursorToColumn(Col: Integer);
    procedure MoveCursorHome;
    procedure SaveCursor;
    procedure RestoreCursor;

    { Line editing }
    procedure InsertLine(Count: Integer = 1);
    procedure DeleteLine(Count: Integer = 1);
    procedure InsertChar(Count: Integer = 1);
    procedure DeleteChar(Count: Integer = 1);

    { Erase operations }
    procedure EraseToEOL;
    procedure EraseFromBOL;
    procedure EraseLine;
    procedure EraseToEOS;
    procedure EraseFromBOS;
    procedure EraseScreen;
    procedure EraseChars(Count: Integer);

    { Scrolling }
    procedure ScrollUp(Count: Integer = 1);
    procedure ScrollDown(Count: Integer = 1);
    procedure SetScrollRegion(Top, Bottom: Integer);
    procedure ResetScrollRegion;

    { Attributes }
    procedure SetAttribute(Attr: Byte);
    procedure SetForeground(Color: Byte);
    procedure SetBackground(Color: Byte);
    procedure SetBold(Enable: Boolean);
    procedure SetReverse(Enable: Boolean);
    procedure ResetAttributes;

    { Tab handling }
    procedure TabForward(Count: Integer = 1);
    procedure TabBackward(Count: Integer = 1);

    { Line feed / carriage return }
    procedure LineFeed;
    procedure ReverseLineFeed;
    procedure CarriageReturn;
    procedure ClearCurrentLineWrap;  { Mark current line as not soft-wrapped }

    { Access }
    function GetCell(X, Y: Integer): TTerminalCell;
    procedure SetCell(X, Y: Integer; const Cell: TTerminalCell);
    function GetLineText(Y: Integer): string;

    { Scrollback access }
    function GetScrollbackLines: Integer;
    function GetCellAtAbsolute(X, AbsY: Integer): TTerminalCell;
    function GetLineTextAbsolute(AbsY: Integer): string;

    { Dirty tracking }
    procedure InvalidateAll;
    procedure ClearDirty;
    function IsDirty: Boolean;
    function GetDirtyRect(out R: TRect): Boolean;

    { Resize }
    procedure Resize(NewWidth, NewHeight: Integer);

    { Reset }
    procedure Reset;

    { Properties }
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property CursorX: Integer read FCursorX;
    property CursorY: Integer read FCursorY;
    property CursorVisible: Boolean read FCursorVisible write FCursorVisible;
    property CurrentAttr: Byte read FCurrentAttr write FCurrentAttr;
    property AutoWrap: Boolean read FAutoWrap write FAutoWrap;
    property InsertMode: Boolean read FInsertMode write FInsertMode;
    property OriginMode: Boolean read FOriginMode write FOriginMode;
    property ScrollTop: Integer read FScrollTop;
    property ScrollBottom: Integer read FScrollBottom;
    property ScrollbackCount: Integer read FScrollbackCount;
  end;

{***************************************************************************}
{                          TTerminalParser CLASS                            }
{***************************************************************************}

  TParserState = (
    psNormal,       { Normal character output }
    psEscape,       { Received ESC }
    psCSI,          { Received ESC [ }
    psCSIParam,     { Parsing CSI parameters }
    psOSC,          { Operating System Command }
    psDCS,          { Device Control String }
    psSOS,          { Start of String }
    psPM,           { Privacy Message }
    psAPC           { Application Program Command }
  );

  TBellEvent = procedure of object;
  TTitleChangeEvent = procedure(const Title: string) of object;
  TAlternateScreenEvent = procedure(Active: Boolean) of object;

  TTerminalParser = class
  private
    FState: TParserState;
    FParams: array of Integer;
    FParamCount: Integer;
    FIntermediateChars: string;
    FPrivateMarker: Char;
    FBuffer: TTerminalBuffer;
    FPalette: TTerminalPalette;
    FOSCBuffer: string;
    FTitle: string;

    { Callbacks }
    FOnBell: TBellEvent;
    FOnTitleChange: TTitleChangeEvent;
    FOnAlternateScreen: TAlternateScreenEvent;

    { UTF-8 decoding state }
    FUTF8Buffer: array[0..3] of Byte;
    FUTF8BufferLen: Integer;
    FUTF8ExpectedLen: Integer;
    { Mouse tracking modes requested by child app (DECSET/DECRST) }
    FMouseX10Tracking: Boolean;       { ?1000 }
    FMouseButtonTracking: Boolean;    { ?1002 }
    FMouseAnyTracking: Boolean;       { ?1003 }
    FMouseSGRMode: Boolean;           { ?1006 }
    FAlternateScreenActive: Boolean;

    procedure AddParam(Value: Integer);
    function GetParam(Index: Integer; Default: Integer = 0): Integer;
    procedure ClearParams;

    procedure ProcessNormal(Ch: Char);
    procedure ProcessEscape(Ch: Char);
    procedure ProcessCSI(Ch: Char);
    procedure ProcessCSIParam(Ch: Char);
    procedure ProcessOSC(Ch: Char);
    procedure ProcessEscapeSeqByte(B: Byte);

    procedure ExecuteC0(Ch: Char);
    procedure ExecuteEscape(Ch: Char);
    procedure ExecuteCSI(Final: Char);
    procedure ExecuteSGR;
    procedure ExecutePrivateMode(Enable: Boolean);
    procedure ExecuteOSC;
    function GetMouseTrackingEnabled: Boolean;
    procedure SetAlternateScreenActive(Active: Boolean);

  public
    constructor Create(ABuffer: TTerminalBuffer; APalette: TTerminalPalette);
    destructor Destroy; override;

    procedure ProcessChar(Ch: Char);
    procedure ProcessData(const Data: TBytes);
    procedure ProcessString(const S: string);
    procedure Reset;

    property State: TParserState read FState;
    property Buffer: TTerminalBuffer read FBuffer;
    property Title: string read FTitle;
    property MouseTrackingEnabled: Boolean read GetMouseTrackingEnabled;
    property MouseButtonTracking: Boolean read FMouseButtonTracking;
    property MouseAnyTracking: Boolean read FMouseAnyTracking;
    property MouseSGRMode: Boolean read FMouseSGRMode;
    property AlternateScreenActive: Boolean read FAlternateScreenActive;
    property OnBell: TBellEvent read FOnBell write FOnBell;
    property OnTitleChange: TTitleChangeEvent read FOnTitleChange write FOnTitleChange;
    property OnAlternateScreen: TAlternateScreenEvent
      read FOnAlternateScreen write FOnAlternateScreen;
  end;

{***************************************************************************}
{                          TTerminalView CLASS                              }
{***************************************************************************}

  TTerminalView = class(TView)
  private
    FConPTY: TConPTY;
    FBuffer: TTerminalBuffer;
    FParser: TTerminalParser;
    FPalette: TTerminalPalette;
    FMode: Integer;                  { tmNormal or tmCapture }
    FEscapeKey: Word;                { Key to escape capture mode }
    FWaitingEscapeCommand: Boolean;
    FScrollbackPos: Integer;         { Current scroll position }

    { Selection }
    FSelecting: Boolean;
    FSelStart: TSelectionPoint;
    FSelEnd: TSelectionPoint;
    FSelectionMode: TSelectionMode;

    { Config }
    FDefaultShell: string;
    FScrollbackLines: Integer;
    FShowExitMessage: Boolean;
    FVisualBell: Boolean;
    FVisualBellActive: Boolean;
    FVisualBellTicks: Cardinal;

    { Logging }
    FLogStream: TStream;
    FLogFileName: string;

    { Callbacks }
    FOnTitleChange: TNotifyEvent;
    FTitle: string;
    FMousePassthroughEnabled: Boolean;
    FLastMouseButtonCode: Integer;
    FAutoMousePassthroughOnAltScreen: Boolean;
    FAltScreenForcedMouseMode: Boolean;
    FMousePassthroughBeforeAltScreen: Boolean;

    procedure HandleTerminalData;
    procedure HandleBell;
    procedure HandleTitleChange(const NewTitle: string);
    procedure HandleAlternateScreenChange(Active: Boolean);
    procedure HandleTerminalExit;
    procedure PostFVEvent(What, Command: Word; InfoPtr: Pointer);
    function TranslateKey(const Event: TEvent): TBytes;
    procedure SetMousePassthroughEnabled(Enable: Boolean);
    function ShouldForwardMouseToChild: Boolean;
    function MouseButtonCodeFromButtons(Buttons: Byte): Integer;
    function MouseModifierMask: Integer;
    procedure SendMouseSGR(LocalX, LocalY, Cb: Integer; Released: Boolean);
    procedure RenderToDrawBuffer(var Buf: TDrawBuffer; Y: Integer);
    function IsInSelection(X, Y: Integer): Boolean;
    procedure NormalizeSelection(out StartPt, EndPt: TSelectionPoint);
    function GetIsRunning: Boolean;
    procedure UpdatePTYSize;

  protected
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure ChangeBounds(var Bounds: TRect); override;

  public
    constructor Create(var Bounds: TRect); override;
    constructor CreateWithShell(var Bounds: TRect; const Shell: string);
    destructor Destroy; override;

    { Lifecycle }
    function Execute(const CommandLine: string): Boolean; overload;
    function Execute(const Executable: string;
      const Args: array of string): Boolean; overload;
    procedure Terminate;

    { Clipboard }
    procedure StartSelection(X, Y: Integer);
    procedure ExtendSelection(X, Y: Integer);
    procedure SelectWord(X, Y: Integer);
    procedure CopySelection;
    procedure Paste;
    procedure ClearSelection;
    function GetSelectedText: string;

    { Visual bell }
    procedure DoVisualBell;

    { Logging }
    procedure StartLogging(const FileName: string);
    procedure StopLogging;
    function IsLogging: Boolean;

    { Scrollback }
    procedure ScrollTo(Line: Integer);
    procedure ScrollViewUp(Lines: Integer = 1);
    procedure ScrollViewDown(Lines: Integer = 1);
    procedure ScrollToBottom;

    { Mode control }
    procedure EnterCaptureMode;
    procedure ExitCaptureMode;
    procedure ToggleMousePassthrough;

    { IFVDataAware }
    function DataSize: Word; override;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
    function Valid(Command: Word): Boolean; override;

    { Properties }
    property Mode: Integer read FMode;
    property IsRunning: Boolean read GetIsRunning;
    property ConPTY: TConPTY read FConPTY;
    property Buffer: TTerminalBuffer read FBuffer;
    property Palette: TTerminalPalette read FPalette;
    property EscapeKey: Word read FEscapeKey write FEscapeKey;
    property DefaultShell: string read FDefaultShell write FDefaultShell;
    property ScrollbackLines: Integer read FScrollbackLines write FScrollbackLines;
    property ShowExitMessage: Boolean read FShowExitMessage write FShowExitMessage;
    property ScrollbackPos: Integer read FScrollbackPos;
    property VisualBell: Boolean read FVisualBell write FVisualBell;
    property MousePassthroughEnabled: Boolean read FMousePassthroughEnabled write SetMousePassthroughEnabled;
    property AutoMousePassthroughOnAltScreen: Boolean
      read FAutoMousePassthroughOnAltScreen write FAutoMousePassthroughOnAltScreen;
    property OnTitleChange: TNotifyEvent read FOnTitleChange write FOnTitleChange;
    property LogFileName: string read FLogFileName;
    property Title: string read FTitle;
  end;

{***************************************************************************}
{                         TTerminalWindow CLASS                             }
{***************************************************************************}

  TTerminalWindow = class(TWindow)
  private
    FTerminal: TTerminalView;
    FScrollBar: TScrollBar;
    FInterior: TRect;
    FBaseTitle: string;
    procedure UpdateScrollBar;
    procedure HandleTerminalTitleChange(Sender: TObject);
    procedure RefreshWindowTitle;

  protected
    procedure HandleEvent(var Event: TEvent); override;
    procedure SizeLimits(var Min, Max: TPoint); override;

  public
    constructor Create(var Bounds: TRect; const ATitle: string); reintroduce;
    constructor CreateWithShell(var Bounds: TRect; const ATitle, Shell: string);
    destructor Destroy; override;

    function Execute(const CommandLine: string): Boolean; overload;
    function Execute(const Executable: string;
      const Args: array of string): Boolean; overload;

    property Terminal: TTerminalView read FTerminal;
    property ScrollBar: TScrollBar read FScrollBar;
  end;

{***************************************************************************}
{                           UTILITY FUNCTIONS                               }
{***************************************************************************}

{ Create a new terminal window }
function NewTerminalWindow(const Title, CommandLine: string): TTerminalWindow;

implementation

{***************************************************************************}
{                     TTerminalPalette IMPLEMENTATION                       }
{***************************************************************************}

constructor TTerminalPalette.Create;
begin
  inherited Create;
  LoadDefault;
end;

procedure TTerminalPalette.LoadDefault;
begin
  { Standard DOS/ANSI color mapping }
  FColors[0]  := $00;  { Black }
  FColors[1]  := $04;  { Red }
  FColors[2]  := $02;  { Green }
  FColors[3]  := $06;  { Yellow/Brown }
  FColors[4]  := $01;  { Blue }
  FColors[5]  := $05;  { Magenta }
  FColors[6]  := $03;  { Cyan }
  FColors[7]  := $07;  { White/Light Gray }
  { Bright colors }
  FColors[8]  := $08;  { Dark Gray (Bright Black) }
  FColors[9]  := $0C;  { Bright Red }
  FColors[10] := $0A;  { Bright Green }
  FColors[11] := $0E;  { Bright Yellow }
  FColors[12] := $09;  { Bright Blue }
  FColors[13] := $0D;  { Bright Magenta }
  FColors[14] := $0B;  { Bright Cyan }
  FColors[15] := $0F;  { Bright White }
end;

procedure TTerminalPalette.SetColor(Index: Byte; FVColor: Byte);
begin
  if Index < 16 then
    FColors[Index] := FVColor;
end;

function TTerminalPalette.GetColor(Index: Byte): Byte;
begin
  if Index < 16 then
    Result := FColors[Index]
  else
    Result := FColors[Index mod 16];
end;

function TTerminalPalette.MapForeground(ANSIColor: Byte): Byte;
begin
  Result := GetColor(ANSIColor and $0F);
end;

function TTerminalPalette.MapBackground(ANSIColor: Byte): Byte;
begin
  Result := GetColor(ANSIColor and $0F) shl 4;
end;

function TTerminalPalette.CombineAttr(FG, BG: Byte): Byte;
begin
  Result := (MapBackground(BG) and $F0) or (MapForeground(FG) and $0F);
end;

procedure TTerminalPalette.LoadFromJSON(const AJson: TJSONObject);
var
  ColorsArray: TJSONArray;
  I: Integer;
begin
  if AJson = nil then Exit;

  if AJson.TryGetValue<TJSONArray>('colors', ColorsArray) then
  begin
    for I := 0 to Min(15, ColorsArray.Count - 1) do
      FColors[I] := ColorsArray.Items[I].AsType<Integer>;
  end;
end;

function TTerminalPalette.ToJSON: TJSONObject;
var
  ColorsArray: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  ColorsArray := TJSONArray.Create;
  for I := 0 to 15 do
    ColorsArray.Add(FColors[I]);
  Result.AddPair('colors', ColorsArray);
end;

{***************************************************************************}
{                      TTerminalBuffer IMPLEMENTATION                       }
{***************************************************************************}

constructor TTerminalBuffer.Create(AWidth, AHeight, AScrollback: Integer);
begin
  inherited Create;
  FLines := TList<TTerminalLine>.Create;
  FLineWrapped := TList<Boolean>.Create;
  FWidth := AWidth;
  FHeight := AHeight;
  FScrollbackSize := AScrollback;
  FScrollbackStart := 0;
  FScrollbackCount := 0;
  FCursorX := 0;
  FCursorY := 0;
  FCursorVisible := True;
  FCurrentAttr := DefaultTerminalAttr;
  FReverseVideo := False;
  FSavedCursorX := 0;
  FSavedCursorY := 0;
  FSavedAttr := DefaultTerminalAttr;
  FSavedReverseVideo := False;
  FScrollTop := 0;
  FScrollBottom := AHeight - 1;
  FAutoWrap := True;
  FInsertMode := False;
  FOriginMode := False;
  ClearDirty;

  { Initialize with empty lines }
  Reset;
end;

destructor TTerminalBuffer.Destroy;
begin
  FLineWrapped.Free;
  FLines.Free;
  inherited;
end;

function TTerminalBuffer.GetLineIndex(Y: Integer): Integer;
begin
  { Y is 0-based screen coordinate }
  { Convert to absolute line index in FLines }
  Result := FScrollbackStart + Y;
  if Result < 0 then
    Result := 0;
  if Result >= FLines.Count then
    EnsureLineExists(Result);
end;

procedure TTerminalBuffer.EnsureLineExists(Index: Integer);
var
  Line: TTerminalLine;
  I: Integer;
begin
  while FLines.Count <= Index do
  begin
    SetLength(Line, FWidth);
    for I := 0 to FWidth - 1 do
    begin
      Line[I].Ch := ' ';
      Line[I].Attr := DefaultTerminalAttr;
    end;
    FLines.Add(Line);
    FLineWrapped.Add(False);  { New lines are not wrapped by default }
  end;
end;

procedure TTerminalBuffer.MarkDirty(X1, Y1, X2, Y2: Integer);
begin
  if X1 < FDirtyLeft then FDirtyLeft := X1;
  if Y1 < FDirtyTop then FDirtyTop := Y1;
  if X2 > FDirtyRight then FDirtyRight := X2;
  if Y2 > FDirtyBottom then FDirtyBottom := Y2;
end;

function TTerminalBuffer.GetEffectiveAttr: Byte;
var
  FG, BG: Byte;
begin
  if not FReverseVideo then
  begin
    Result := FCurrentAttr;
    Exit;
  end;

  FG := FCurrentAttr and $0F;
  BG := (FCurrentAttr shr 4) and $0F;
  Result := (FG shl 4) or BG;
end;

procedure TTerminalBuffer.WriteGlyph(const Glyph: string);
var
  I: Integer;
begin
  if Glyph = '' then Exit;
  if Length(Glyph) = 1 then
  begin
    WriteChar(Glyph[1]);
    Exit;
  end;

  { Emit multi-code-unit glyphs (e.g. surrogate pairs) as a sequence. }
  for I := 1 to Length(Glyph) do
    WriteChar(Glyph[I]);
end;

procedure TTerminalBuffer.WriteChar(Ch: Char);
var
  LineIdx: Integer;
  I: Integer;
begin
  if FCursorX >= FWidth then
  begin
    if FAutoWrap then
    begin
      { Mark current line as soft-wrapped (continuation) }
      LineIdx := GetLineIndex(FCursorY);
      if LineIdx < FLineWrapped.Count then
        FLineWrapped[LineIdx] := True;
      FCursorX := 0;
      LineFeed;
    end
    else
    begin
      FCursorX := FWidth - 1;
    end;
  end;

  LineIdx := GetLineIndex(FCursorY);
  EnsureLineExists(LineIdx);

  if FInsertMode then
  begin
    { Shift characters right }
    for I := FWidth - 2 downto FCursorX do
      FLines[LineIdx][I + 1] := FLines[LineIdx][I];
  end;

  FLines[LineIdx][FCursorX].Ch := Ch;
  FLines[LineIdx][FCursorX].Attr := GetEffectiveAttr;

  MarkDirty(FCursorX, FCursorY, FCursorX, FCursorY);
  Inc(FCursorX);
end;

procedure TTerminalBuffer.WriteString(const S: string);
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    WriteChar(S[I]);
end;

procedure TTerminalBuffer.MoveCursor(X, Y: Integer);
begin
  if FOriginMode then
  begin
    { Origin mode: relative to scroll region }
    Y := Y + FScrollTop;
    if Y > FScrollBottom then Y := FScrollBottom;
  end;

  if X < 0 then X := 0;
  if X >= FWidth then X := FWidth - 1;
  if Y < 0 then Y := 0;
  if Y >= FHeight then Y := FHeight - 1;

  FCursorX := X;
  FCursorY := Y;
end;

procedure TTerminalBuffer.MoveCursorRel(DX, DY: Integer);
begin
  MoveCursor(FCursorX + DX, FCursorY + DY);
end;

procedure TTerminalBuffer.MoveCursorUp(Count: Integer);
var
  NewY: Integer;
begin
  NewY := FCursorY - Count;
  if NewY < FScrollTop then NewY := FScrollTop;
  FCursorY := NewY;
end;

procedure TTerminalBuffer.MoveCursorDown(Count: Integer);
var
  NewY: Integer;
begin
  NewY := FCursorY + Count;
  if NewY > FScrollBottom then NewY := FScrollBottom;
  FCursorY := NewY;
end;

procedure TTerminalBuffer.MoveCursorLeft(Count: Integer);
begin
  FCursorX := FCursorX - Count;
  if FCursorX < 0 then FCursorX := 0;
end;

procedure TTerminalBuffer.MoveCursorRight(Count: Integer);
begin
  FCursorX := FCursorX + Count;
  if FCursorX >= FWidth then FCursorX := FWidth - 1;
end;

procedure TTerminalBuffer.MoveCursorToColumn(Col: Integer);
begin
  if Col < 0 then Col := 0;
  if Col >= FWidth then Col := FWidth - 1;
  FCursorX := Col;
end;

procedure TTerminalBuffer.MoveCursorHome;
begin
  FCursorX := 0;
  if FOriginMode then
    FCursorY := FScrollTop
  else
    FCursorY := 0;
end;

procedure TTerminalBuffer.SaveCursor;
begin
  FSavedCursorX := FCursorX;
  FSavedCursorY := FCursorY;
  FSavedAttr := FCurrentAttr;
  FSavedReverseVideo := FReverseVideo;
end;

procedure TTerminalBuffer.RestoreCursor;
begin
  FCursorX := FSavedCursorX;
  FCursorY := FSavedCursorY;
  FCurrentAttr := FSavedAttr;
  FReverseVideo := FSavedReverseVideo;
end;

procedure TTerminalBuffer.InsertLine(Count: Integer);
var
  I, J, LineIdx: Integer;
  NewLine: TTerminalLine;
begin
  if (FCursorY < FScrollTop) or (FCursorY > FScrollBottom) then
    Exit;

  for I := 1 to Count do
  begin
    { Delete line at scroll bottom }
    if FScrollBottom < FLines.Count then
    begin
      LineIdx := GetLineIndex(FScrollBottom);
      { Shift lines down }
      for J := FScrollBottom downto FCursorY + 1 do
      begin
        FLines[GetLineIndex(J)] := FLines[GetLineIndex(J - 1)];
      end;
    end;

    { Insert blank line at cursor }
    SetLength(NewLine, FWidth);
    for J := 0 to FWidth - 1 do
    begin
      NewLine[J].Ch := ' ';
      NewLine[J].Attr := GetEffectiveAttr;
    end;
    FLines[GetLineIndex(FCursorY)] := NewLine;
  end;

  MarkDirty(0, FCursorY, FWidth - 1, FScrollBottom);
end;

procedure TTerminalBuffer.DeleteLine(Count: Integer);
var
  I, J, LineIdx: Integer;
  NewLine: TTerminalLine;
begin
  if (FCursorY < FScrollTop) or (FCursorY > FScrollBottom) then
    Exit;

  for I := 1 to Count do
  begin
    { Shift lines up }
    for J := FCursorY to FScrollBottom - 1 do
    begin
      FLines[GetLineIndex(J)] := FLines[GetLineIndex(J + 1)];
    end;

    { Insert blank line at scroll bottom }
    SetLength(NewLine, FWidth);
    for J := 0 to FWidth - 1 do
    begin
      NewLine[J].Ch := ' ';
      NewLine[J].Attr := GetEffectiveAttr;
    end;
    FLines[GetLineIndex(FScrollBottom)] := NewLine;
  end;

  MarkDirty(0, FCursorY, FWidth - 1, FScrollBottom);
end;

procedure TTerminalBuffer.InsertChar(Count: Integer);
var
  LineIdx, I, J: Integer;
begin
  LineIdx := GetLineIndex(FCursorY);
  EnsureLineExists(LineIdx);

  for I := 1 to Count do
  begin
    { Shift characters right }
    for J := FWidth - 2 downto FCursorX do
      FLines[LineIdx][J + 1] := FLines[LineIdx][J];

    { Insert blank at cursor }
    FLines[LineIdx][FCursorX].Ch := ' ';
    FLines[LineIdx][FCursorX].Attr := GetEffectiveAttr;
  end;

  MarkDirty(FCursorX, FCursorY, FWidth - 1, FCursorY);
end;

procedure TTerminalBuffer.DeleteChar(Count: Integer);
var
  LineIdx, I, J: Integer;
begin
  LineIdx := GetLineIndex(FCursorY);
  EnsureLineExists(LineIdx);

  for I := 1 to Count do
  begin
    { Shift characters left }
    for J := FCursorX to FWidth - 2 do
      FLines[LineIdx][J] := FLines[LineIdx][J + 1];

    { Insert blank at end }
    FLines[LineIdx][FWidth - 1].Ch := ' ';
    FLines[LineIdx][FWidth - 1].Attr := GetEffectiveAttr;
  end;

  MarkDirty(FCursorX, FCursorY, FWidth - 1, FCursorY);
end;

procedure TTerminalBuffer.EraseToEOL;
var
  LineIdx, I: Integer;
begin
  LineIdx := GetLineIndex(FCursorY);
  EnsureLineExists(LineIdx);

  for I := FCursorX to FWidth - 1 do
  begin
    FLines[LineIdx][I].Ch := ' ';
    FLines[LineIdx][I].Attr := GetEffectiveAttr;
  end;

  MarkDirty(FCursorX, FCursorY, FWidth - 1, FCursorY);
end;

procedure TTerminalBuffer.EraseFromBOL;
var
  LineIdx, I: Integer;
begin
  LineIdx := GetLineIndex(FCursorY);
  EnsureLineExists(LineIdx);

  for I := 0 to FCursorX do
  begin
    FLines[LineIdx][I].Ch := ' ';
    FLines[LineIdx][I].Attr := GetEffectiveAttr;
  end;

  MarkDirty(0, FCursorY, FCursorX, FCursorY);
end;

procedure TTerminalBuffer.EraseLine;
var
  LineIdx, I: Integer;
begin
  LineIdx := GetLineIndex(FCursorY);
  EnsureLineExists(LineIdx);

  for I := 0 to FWidth - 1 do
  begin
    FLines[LineIdx][I].Ch := ' ';
    FLines[LineIdx][I].Attr := GetEffectiveAttr;
  end;

  MarkDirty(0, FCursorY, FWidth - 1, FCursorY);
end;

procedure TTerminalBuffer.EraseToEOS;
var
  Y: Integer;
begin
  EraseToEOL;
  for Y := FCursorY + 1 to FHeight - 1 do
  begin
    FCursorY := Y;
    EraseLine;
  end;
  FCursorY := FCursorY;  { Restore cursor Y }
end;

procedure TTerminalBuffer.EraseFromBOS;
var
  Y, SaveY: Integer;
begin
  SaveY := FCursorY;
  for Y := 0 to FCursorY - 1 do
  begin
    FCursorY := Y;
    EraseLine;
  end;
  FCursorY := SaveY;
  EraseFromBOL;
end;

procedure TTerminalBuffer.EraseScreen;
var
  Y: Integer;
begin
  for Y := 0 to FHeight - 1 do
  begin
    FCursorY := Y;
    EraseLine;
  end;
  FCursorX := 0;
  FCursorY := 0;
  MarkDirty(0, 0, FWidth - 1, FHeight - 1);
end;

procedure TTerminalBuffer.EraseChars(Count: Integer);
var
  LineIdx, I, EndX: Integer;
begin
  LineIdx := GetLineIndex(FCursorY);
  EnsureLineExists(LineIdx);

  EndX := FCursorX + Count - 1;
  if EndX >= FWidth then EndX := FWidth - 1;

  for I := FCursorX to EndX do
  begin
    FLines[LineIdx][I].Ch := ' ';
    FLines[LineIdx][I].Attr := GetEffectiveAttr;
  end;

  MarkDirty(FCursorX, FCursorY, EndX, FCursorY);
end;

procedure TTerminalBuffer.ScrollUp(Count: Integer);
var
  I, J: Integer;
  NewLine: TTerminalLine;
begin
  for I := 1 to Count do
  begin
    { Full-screen scroll: preserve lines in scrollback }
    if (FScrollTop = 0) and (FScrollBottom = FHeight - 1) then
    begin
      { Add a new blank line at the end }
      SetLength(NewLine, FWidth);
      for J := 0 to FWidth - 1 do
      begin
        NewLine[J].Ch := ' ';
        NewLine[J].Attr := GetEffectiveAttr;
      end;
      FLines.Add(NewLine);
      FLineWrapped.Add(False);  { New line is not wrapped }

      { Move the view down (top line goes into scrollback) }
      Inc(FScrollbackStart);
      Inc(FScrollbackCount);

      { Enforce scrollback limit }
      if FScrollbackCount > FScrollbackSize then
      begin
        FLines.Delete(0);
        if FLineWrapped.Count > 0 then
          FLineWrapped.Delete(0);
        Dec(FScrollbackStart);
        Dec(FScrollbackCount);
      end;
    end
    else
    begin
      { Partial scroll region: shift lines without preserving }
      for J := FScrollTop to FScrollBottom - 1 do
      begin
        FLines[GetLineIndex(J)] := FLines[GetLineIndex(J + 1)];
        if GetLineIndex(J) < FLineWrapped.Count then
          FLineWrapped[GetLineIndex(J)] := FLineWrapped[GetLineIndex(J + 1)];
      end;

      { Insert blank line at bottom of scroll region }
      SetLength(NewLine, FWidth);
      for J := 0 to FWidth - 1 do
      begin
        NewLine[J].Ch := ' ';
        NewLine[J].Attr := GetEffectiveAttr;
      end;
      FLines[GetLineIndex(FScrollBottom)] := NewLine;
      if GetLineIndex(FScrollBottom) < FLineWrapped.Count then
        FLineWrapped[GetLineIndex(FScrollBottom)] := False;
    end;
  end;

  MarkDirty(0, FScrollTop, FWidth - 1, FScrollBottom);
end;

procedure TTerminalBuffer.ScrollDown(Count: Integer);
var
  I, J: Integer;
  NewLine: TTerminalLine;
begin
  for I := 1 to Count do
  begin
    { Move lines down within scroll region }
    for J := FScrollBottom downto FScrollTop + 1 do
    begin
      FLines[GetLineIndex(J)] := FLines[GetLineIndex(J - 1)];
      if GetLineIndex(J) < FLineWrapped.Count then
        FLineWrapped[GetLineIndex(J)] := FLineWrapped[GetLineIndex(J - 1)];
    end;

    { Insert blank line at top of scroll region }
    SetLength(NewLine, FWidth);
    for J := 0 to FWidth - 1 do
    begin
      NewLine[J].Ch := ' ';
      NewLine[J].Attr := GetEffectiveAttr;
    end;
    FLines[GetLineIndex(FScrollTop)] := NewLine;
    if GetLineIndex(FScrollTop) < FLineWrapped.Count then
      FLineWrapped[GetLineIndex(FScrollTop)] := False;
  end;

  MarkDirty(0, FScrollTop, FWidth - 1, FScrollBottom);
end;

procedure TTerminalBuffer.SetScrollRegion(Top, Bottom: Integer);
begin
  if Top < 0 then Top := 0;
  if Bottom >= FHeight then Bottom := FHeight - 1;
  if Top < Bottom then
  begin
    FScrollTop := Top;
    FScrollBottom := Bottom;
  end;
  { Move cursor to home after setting scroll region }
  MoveCursorHome;
end;

procedure TTerminalBuffer.ResetScrollRegion;
begin
  FScrollTop := 0;
  FScrollBottom := FHeight - 1;
end;

procedure TTerminalBuffer.SetAttribute(Attr: Byte);
begin
  FCurrentAttr := Attr;
end;

procedure TTerminalBuffer.SetForeground(Color: Byte);
begin
  FCurrentAttr := (FCurrentAttr and $F0) or (Color and $0F);
end;

procedure TTerminalBuffer.SetBackground(Color: Byte);
begin
  FCurrentAttr := (FCurrentAttr and $0F) or ((Color and $0F) shl 4);
end;

procedure TTerminalBuffer.SetBold(Enable: Boolean);
begin
  if Enable then
    FCurrentAttr := FCurrentAttr or $08
  else
    FCurrentAttr := FCurrentAttr and $F7;
end;

procedure TTerminalBuffer.SetReverse(Enable: Boolean);
begin
  FReverseVideo := Enable;
end;

procedure TTerminalBuffer.ResetAttributes;
begin
  FCurrentAttr := DefaultTerminalAttr;
  FReverseVideo := False;
end;

procedure TTerminalBuffer.TabForward(Count: Integer);
var
  I, NextTab: Integer;
begin
  for I := 1 to Count do
  begin
    { Default tab stops every 8 columns }
    NextTab := ((FCursorX div 8) + 1) * 8;
    if NextTab >= FWidth then
      NextTab := FWidth - 1;
    FCursorX := NextTab;
  end;
end;

procedure TTerminalBuffer.TabBackward(Count: Integer);
var
  I, PrevTab: Integer;
begin
  for I := 1 to Count do
  begin
    if FCursorX > 0 then
    begin
      PrevTab := ((FCursorX - 1) div 8) * 8;
      FCursorX := PrevTab;
    end;
  end;
end;

procedure TTerminalBuffer.LineFeed;
begin
  if FCursorY >= FScrollBottom then
    ScrollUp(1)
  else
    Inc(FCursorY);
end;

procedure TTerminalBuffer.ReverseLineFeed;
begin
  if FCursorY <= FScrollTop then
    ScrollDown(1)
  else
    Dec(FCursorY);
end;

procedure TTerminalBuffer.CarriageReturn;
begin
  FCursorX := 0;
end;

procedure TTerminalBuffer.ClearCurrentLineWrap;
var
  LineIdx: Integer;
begin
  LineIdx := GetLineIndex(FCursorY);
  if (LineIdx >= 0) and (LineIdx < FLineWrapped.Count) then
    FLineWrapped[LineIdx] := False;
end;

function TTerminalBuffer.GetCell(X, Y: Integer): TTerminalCell;
var
  LineIdx: Integer;
begin
  if (X < 0) or (X >= FWidth) or (Y < 0) or (Y >= FHeight) then
  begin
    Result.Ch := ' ';
    Result.Attr := DefaultTerminalAttr;
    Exit;
  end;

  LineIdx := GetLineIndex(Y);
  if LineIdx < FLines.Count then
    Result := FLines[LineIdx][X]
  else
  begin
    Result.Ch := ' ';
    Result.Attr := DefaultTerminalAttr;
  end;
end;

procedure TTerminalBuffer.SetCell(X, Y: Integer; const Cell: TTerminalCell);
var
  LineIdx: Integer;
begin
  if (X < 0) or (X >= FWidth) or (Y < 0) or (Y >= FHeight) then
    Exit;

  LineIdx := GetLineIndex(Y);
  EnsureLineExists(LineIdx);
  FLines[LineIdx][X] := Cell;
  MarkDirty(X, Y, X, Y);
end;

function TTerminalBuffer.GetLineText(Y: Integer): string;
var
  LineIdx, X: Integer;
begin
  SetLength(Result, FWidth);
  LineIdx := GetLineIndex(Y);
  if LineIdx < FLines.Count then
  begin
    for X := 0 to FWidth - 1 do
      Result[X + 1] := FLines[LineIdx][X].Ch;
  end
  else
  begin
    for X := 1 to FWidth do
      Result[X] := ' ';
  end;
end;

function TTerminalBuffer.GetScrollbackLines: Integer;
begin
  Result := FScrollbackCount;
end;

function TTerminalBuffer.GetCellAtAbsolute(X, AbsY: Integer): TTerminalCell;
begin
  { AbsY is absolute line index:
    - Negative values are scrollback lines (e.g., -1 = one line back)
    - 0 to Height-1 are current screen lines }
  if (X < 0) or (X >= FWidth) then
  begin
    Result.Ch := ' ';
    Result.Attr := DefaultTerminalAttr;
    Exit;
  end;

  { Convert to buffer index }
  { Screen Y=0 is at FScrollbackStart, so AbsY=0 maps to FScrollbackStart }
  { AbsY=-1 maps to FScrollbackStart-1, etc. }
  AbsY := FScrollbackStart + AbsY;

  if (AbsY < 0) or (AbsY >= FLines.Count) then
  begin
    Result.Ch := ' ';
    Result.Attr := DefaultTerminalAttr;
  end
  else
    Result := FLines[AbsY][X];
end;

function TTerminalBuffer.GetLineTextAbsolute(AbsY: Integer): string;
var
  X, LineIdx: Integer;
begin
  SetLength(Result, FWidth);
  LineIdx := FScrollbackStart + AbsY;

  if (LineIdx >= 0) and (LineIdx < FLines.Count) then
  begin
    for X := 0 to FWidth - 1 do
      Result[X + 1] := FLines[LineIdx][X].Ch;
  end
  else
  begin
    for X := 1 to FWidth do
      Result[X] := ' ';
  end;
end;

procedure TTerminalBuffer.InvalidateAll;
begin
  FDirtyLeft := 0;
  FDirtyTop := 0;
  FDirtyRight := FWidth - 1;
  FDirtyBottom := FHeight - 1;
end;

procedure TTerminalBuffer.ClearDirty;
begin
  FDirtyLeft := FWidth;
  FDirtyTop := FHeight;
  FDirtyRight := -1;
  FDirtyBottom := -1;
end;

function TTerminalBuffer.IsDirty: Boolean;
begin
  Result := (FDirtyRight >= FDirtyLeft) and (FDirtyBottom >= FDirtyTop);
end;

function TTerminalBuffer.GetDirtyRect(out R: TRect): Boolean;
begin
  Result := IsDirty;
  if Result then
  begin
    R.A.X := FDirtyLeft;
    R.A.Y := FDirtyTop;
    R.B.X := FDirtyRight + 1;
    R.B.Y := FDirtyBottom + 1;
  end;
end;

procedure TTerminalBuffer.ReflowLines(OldWidth, NewWidth: Integer);
var
  OldLines: TList<TTerminalLine>;
  OldWrapped: TList<Boolean>;
  LogicalLine: TTerminalLine;
  NewLines: TList<TTerminalLine>;
  NewWrapped: TList<Boolean>;
  I, J, Pos: Integer;
  Line, NewLine: TTerminalLine;
  IsWrapped: Boolean;
  LogicalLineLen: Integer;
begin
  if (FLines.Count = 0) or (OldWidth = NewWidth) then Exit;

  { Build logical lines by joining wrapped physical lines }
  OldLines := FLines;
  OldWrapped := FLineWrapped;
  NewLines := TList<TTerminalLine>.Create;
  NewWrapped := TList<Boolean>.Create;
  FLines := NewLines;
  FLineWrapped := NewWrapped;

  try
    I := 0;
    while I < OldLines.Count do
    begin
      { Start a new logical line }
      SetLength(LogicalLine, 0);

      { Collect all physical lines that are part of this logical line }
      repeat
        Line := OldLines[I];
        IsWrapped := (I < OldWrapped.Count) and OldWrapped[I];

        { Find the actual length of content (trim trailing spaces for wrapped lines) }
        if IsWrapped then
          LogicalLineLen := OldWidth  { Full width for wrapped lines }
        else
        begin
          { Find last non-space character }
          LogicalLineLen := Length(Line);
          while (LogicalLineLen > 0) and (Line[LogicalLineLen - 1].Ch = ' ') do
            Dec(LogicalLineLen);
        end;

        { Append cells to logical line }
        Pos := Length(LogicalLine);
        SetLength(LogicalLine, Pos + LogicalLineLen);
        for J := 0 to LogicalLineLen - 1 do
          LogicalLine[Pos + J] := Line[J];

        Inc(I);
      until (not IsWrapped) or (I >= OldLines.Count);

      { Now re-wrap the logical line to the new width }
      Pos := 0;
      while Pos < Length(LogicalLine) do
      begin
        { Create a new physical line }
        SetLength(NewLine, NewWidth);
        for J := 0 to NewWidth - 1 do
        begin
          if Pos + J < Length(LogicalLine) then
            NewLine[J] := LogicalLine[Pos + J]
          else
          begin
            NewLine[J].Ch := ' ';
            NewLine[J].Attr := DefaultTerminalAttr;
          end;
        end;

        NewLines.Add(NewLine);

        { Check if this line wraps (more content remaining) }
        if Pos + NewWidth < Length(LogicalLine) then
          NewWrapped.Add(True)
        else
          NewWrapped.Add(False);

        Inc(Pos, NewWidth);
      end;

      { If logical line was empty, add an empty line }
      if Length(LogicalLine) = 0 then
      begin
        SetLength(NewLine, NewWidth);
        for J := 0 to NewWidth - 1 do
        begin
          NewLine[J].Ch := ' ';
          NewLine[J].Attr := DefaultTerminalAttr;
        end;
        NewLines.Add(NewLine);
        NewWrapped.Add(False);
      end;
    end;

    { Update scrollback tracking }
    { Adjust scrollback start to keep cursor at similar position }
    if NewLines.Count > FHeight then
      FScrollbackStart := NewLines.Count - FHeight
    else
      FScrollbackStart := 0;
    FScrollbackCount := FScrollbackStart;

  finally
    OldLines.Free;
    OldWrapped.Free;
  end;
end;

procedure TTerminalBuffer.Resize(NewWidth, NewHeight: Integer);
var
  I, J: Integer;
  Line: TTerminalLine;
  OldWidth: Integer;
begin
  OldWidth := FWidth;

  { Reflow lines if width changed }
  if NewWidth <> OldWidth then
    ReflowLines(OldWidth, NewWidth);

  { Resize existing lines to new width (in case reflow didn't cover all) }
  for I := 0 to FLines.Count - 1 do
  begin
    Line := FLines[I];
    if Length(Line) <> NewWidth then
    begin
      SetLength(Line, NewWidth);
      for J := OldWidth to NewWidth - 1 do
      begin
        if J >= 0 then
        begin
          Line[J].Ch := ' ';
          Line[J].Attr := DefaultTerminalAttr;
        end;
      end;
      FLines[I] := Line;
    end;
  end;

  FWidth := NewWidth;
  FHeight := NewHeight;
  FScrollBottom := NewHeight - 1;

  { Clamp cursor }
  if FCursorX >= FWidth then FCursorX := FWidth - 1;
  if FCursorY >= FHeight then FCursorY := FHeight - 1;

  InvalidateAll;
end;

procedure TTerminalBuffer.Reset;
var
  I: Integer;
begin
  FLines.Clear;
  FLineWrapped.Clear;
  FScrollbackStart := 0;
  FScrollbackCount := 0;
  for I := 0 to FHeight - 1 do
    EnsureLineExists(I);

  FCursorX := 0;
  FCursorY := 0;
  FCursorVisible := True;
  FCurrentAttr := DefaultTerminalAttr;
  FReverseVideo := False;
  FScrollTop := 0;
  FScrollBottom := FHeight - 1;
  FAutoWrap := True;
  FInsertMode := False;
  FOriginMode := False;
  InvalidateAll;
end;

{***************************************************************************}
{                      TTerminalParser IMPLEMENTATION                       }
{***************************************************************************}

constructor TTerminalParser.Create(ABuffer: TTerminalBuffer;
  APalette: TTerminalPalette);
begin
  inherited Create;
  FBuffer := ABuffer;
  FPalette := APalette;
  Reset;
end;

destructor TTerminalParser.Destroy;
begin
  inherited;
end;

procedure TTerminalParser.Reset;
begin
  FState := psNormal;
  ClearParams;
  FIntermediateChars := '';
  FPrivateMarker := #0;
  FOSCBuffer := '';
  FMouseX10Tracking := False;
  FMouseButtonTracking := False;
  FMouseAnyTracking := False;
  FMouseSGRMode := False;
  FAlternateScreenActive := False;
  { Reset UTF-8 decoding state }
  FUTF8BufferLen := 0;
  FUTF8ExpectedLen := 0;
end;

procedure TTerminalParser.AddParam(Value: Integer);
begin
  if FParamCount < Length(FParams) then
  begin
    FParams[FParamCount] := Value;
    Inc(FParamCount);
  end
  else
  begin
    SetLength(FParams, FParamCount + 1);
    FParams[FParamCount] := Value;
    Inc(FParamCount);
  end;
end;

function TTerminalParser.GetParam(Index: Integer; Default: Integer): Integer;
begin
  if (Index >= 0) and (Index < FParamCount) then
  begin
    Result := FParams[Index];
    if Result <= 0 then
      Result := Default;
  end
  else
    Result := Default;
end;

procedure TTerminalParser.ClearParams;
begin
  SetLength(FParams, 16);
  FParamCount := 0;
  FIntermediateChars := '';
  FPrivateMarker := #0;
end;

procedure TTerminalParser.ProcessChar(Ch: Char);
begin
  case FState of
    psNormal:   ProcessNormal(Ch);
    psEscape:   ProcessEscape(Ch);
    psCSI:      ProcessCSI(Ch);
    psCSIParam: ProcessCSIParam(Ch);
    psOSC:      ProcessOSC(Ch);
  else
    FState := psNormal;
    ProcessNormal(Ch);
  end;
end;

procedure TTerminalParser.ProcessData(const Data: TBytes);
var
  I: Integer;
  B: Byte;
  CharLen: Integer;
  DecodedStr: string;
begin
  I := 0;
  while I < Length(Data) do
  begin
    B := Data[I];

    { Escape sequences remain byte-based }
    if FState <> psNormal then
    begin
      ProcessEscapeSeqByte(B);
      Inc(I);
      Continue;
    end;

    { Control characters }
    if B < 32 then
    begin
      ProcessChar(Char(B));
      Inc(I);
      Continue;
    end;

    { DEL character }
    if B = 127 then
    begin
      Inc(I);
      Continue;
    end;

    { UTF-8 decoding using FVUTF8 functions }
    if B < $80 then
    begin
      { ASCII }
      ProcessChar(Char(B));
      Inc(I);
    end
    else
    begin
      { Multi-byte UTF-8 - preserve non-BMP code points (emoji, etc.) }
      DecodedStr := DecodeUTF8ToString(@Data[I], Length(Data) - I, CharLen);
      if CharLen > 0 then
      begin
        if DecodedStr <> '' then
          FBuffer.WriteGlyph(DecodedStr)
        else
          ProcessChar(#$FFFD);
        Inc(I, CharLen);
      end
      else
      begin
        { Invalid UTF-8 - treat as replacement character and skip byte }
        ProcessChar(#$FFFD);  { Unicode replacement character }
        Inc(I);
      end;
    end;
  end;
end;

procedure TTerminalParser.ProcessEscapeSeqByte(B: Byte);
begin
  { Process escape sequence bytes - convert to Char for existing handlers }
  case FState of
    psEscape:   ProcessEscape(Char(B));
    psCSI:      ProcessCSI(Char(B));
    psCSIParam: ProcessCSIParam(Char(B));
    psOSC:      ProcessOSC(Char(B));
  else
    FState := psNormal;
  end;
end;

procedure TTerminalParser.ProcessString(const S: string);
var
  UTF8Bytes: TBytes;
begin
  { Convert string to UTF-8 bytes and process }
  UTF8Bytes := TEncoding.UTF8.GetBytes(S);
  ProcessData(UTF8Bytes);
end;

procedure TTerminalParser.ProcessNormal(Ch: Char);
begin
  if Ord(Ch) < 32 then
    ExecuteC0(Ch)
  else if Ch = #127 then
    { DEL - ignore }
  else
    FBuffer.WriteChar(Ch);
end;

procedure TTerminalParser.ProcessEscape(Ch: Char);
begin
  case Ch of
    '[':
      begin
        FState := psCSI;
        ClearParams;
      end;
    ']':
      begin
        FState := psOSC;
        FOSCBuffer := '';
      end;
    '7':
      begin
        FBuffer.SaveCursor;
        FState := psNormal;
      end;
    '8':
      begin
        FBuffer.RestoreCursor;
        FState := psNormal;
      end;
    'D':
      begin
        FBuffer.LineFeed;
        FState := psNormal;
      end;
    'M':
      begin
        FBuffer.ReverseLineFeed;
        FState := psNormal;
      end;
    'E':
      begin
        FBuffer.CarriageReturn;
        FBuffer.LineFeed;
        FState := psNormal;
      end;
    'c':
      begin
        FBuffer.Reset;
        FState := psNormal;
      end;
    'H':
      begin
        { Set tab stop - ignore for now }
        FState := psNormal;
      end;
    '(':
      begin
        { Character set designation - ignore }
        FState := psNormal;
      end;
    ')':
      begin
        { Character set designation - ignore }
        FState := psNormal;
      end;
  else
    { Unknown escape sequence }
    FState := psNormal;
  end;
end;

procedure TTerminalParser.ProcessCSI(Ch: Char);
begin
  case Ch of
    '0'..'9':
      begin
        AddParam(Ord(Ch) - Ord('0'));
        FState := psCSIParam;
      end;
    ';':
      begin
        AddParam(0);  { Default parameter }
        FState := psCSIParam;
      end;
    '?', '>', '!', '<':
      begin
        FPrivateMarker := Ch;
        FState := psCSIParam;
      end;
    ' ', '"', '''', '*', '+':
      begin
        FIntermediateChars := FIntermediateChars + Ch;
        FState := psCSIParam;
      end;
  else
    if (Ch >= '@') and (Ch <= '~') then
    begin
      ExecuteCSI(Ch);
      FState := psNormal;
    end
    else
      FState := psNormal;
  end;
end;

procedure TTerminalParser.ProcessCSIParam(Ch: Char);
var
  LastParam: Integer;
begin
  case Ch of
    '0'..'9':
      begin
        if FParamCount = 0 then
          AddParam(0);
        LastParam := FParams[FParamCount - 1];
        FParams[FParamCount - 1] := LastParam * 10 + (Ord(Ch) - Ord('0'));
      end;
    ';':
      AddParam(0);
    ' ', '"', '''', '*', '+':
      FIntermediateChars := FIntermediateChars + Ch;
  else
    if (Ch >= '@') and (Ch <= '~') then
    begin
      ExecuteCSI(Ch);
      FState := psNormal;
    end
    else
      FState := psNormal;
  end;
end;

procedure TTerminalParser.ProcessOSC(Ch: Char);
begin
  if (Ch = #7) or (Ch = #$9C) then
  begin
    { End of OSC - process it }
    ExecuteOSC;
    FState := psNormal;
  end
  else if (Ch = #27) then
  begin
    { ESC might start ST (ESC \) }
    ExecuteOSC;
    FState := psNormal;
  end
  else
    FOSCBuffer := FOSCBuffer + Ch;
end;

procedure TTerminalParser.ExecuteOSC;
var
  SemiPos: Integer;
  OSCType: Integer;
  OSCData: string;
begin
  { OSC format: Ps ; Pt ST
    Ps = OSC type number
    Pt = text parameter }
  if FOSCBuffer = '' then Exit;

  SemiPos := Pos(';', FOSCBuffer);
  if SemiPos > 0 then
  begin
    OSCType := StrToIntDef(Copy(FOSCBuffer, 1, SemiPos - 1), -1);
    OSCData := Copy(FOSCBuffer, SemiPos + 1, Length(FOSCBuffer));

    case OSCType of
      0, 1, 2:  { 0=icon+title, 1=icon, 2=title - we treat all as title }
        begin
          FTitle := OSCData;
          if Assigned(FOnTitleChange) then
            FOnTitleChange(FTitle);
        end;
    end;
  end;

  FOSCBuffer := '';
end;

procedure TTerminalParser.ExecuteC0(Ch: Char);
begin
  case Ch of
    #7:   { BEL - bell }
      begin
        if Assigned(FOnBell) then
          FOnBell
        else
          MessageBeep(0);
      end;
    #8:   { BS - backspace }
      FBuffer.MoveCursorLeft(1);
    #9:   { HT - horizontal tab }
      FBuffer.TabForward(1);
    #10:  { LF - line feed }
      begin
        FBuffer.ClearCurrentLineWrap;  { Explicit LF = not wrapped }
        FBuffer.LineFeed;
      end;
    #11:  { VT - vertical tab (same as LF) }
      begin
        FBuffer.ClearCurrentLineWrap;
        FBuffer.LineFeed;
      end;
    #12:  { FF - form feed (same as LF) }
      begin
        FBuffer.ClearCurrentLineWrap;
        FBuffer.LineFeed;
      end;
    #13:  { CR - carriage return }
      FBuffer.CarriageReturn;
    #14:  { SO - shift out (ignore) }
      ;
    #15:  { SI - shift in (ignore) }
      ;
    #24:  { CAN - cancel }
      FState := psNormal;
    #26:  { SUB - substitute }
      FState := psNormal;
    #27:  { ESC }
      FState := psEscape;
  end;
end;

procedure TTerminalParser.ExecuteEscape(Ch: Char);
begin
  { Already handled in ProcessEscape }
end;

procedure TTerminalParser.ExecuteCSI(Final: Char);
begin
  if FPrivateMarker = '?' then
  begin
    case Final of
      'h': ExecutePrivateMode(True);
      'l': ExecutePrivateMode(False);
    end;
    Exit;
  end;

  case Final of
    '@':  { ICH - Insert Character }
      FBuffer.InsertChar(GetParam(0, 1));
    'A':  { CUU - Cursor Up }
      FBuffer.MoveCursorUp(GetParam(0, 1));
    'B':  { CUD - Cursor Down }
      FBuffer.MoveCursorDown(GetParam(0, 1));
    'C':  { CUF - Cursor Forward }
      FBuffer.MoveCursorRight(GetParam(0, 1));
    'D':  { CUB - Cursor Back }
      FBuffer.MoveCursorLeft(GetParam(0, 1));
    'E':  { CNL - Cursor Next Line }
      begin
        FBuffer.MoveCursorDown(GetParam(0, 1));
        FBuffer.CarriageReturn;
      end;
    'F':  { CPL - Cursor Previous Line }
      begin
        FBuffer.MoveCursorUp(GetParam(0, 1));
        FBuffer.CarriageReturn;
      end;
    'G':  { CHA - Cursor Horizontal Absolute }
      FBuffer.MoveCursorToColumn(GetParam(0, 1) - 1);
    'H', 'f':  { CUP/HVP - Cursor Position }
      FBuffer.MoveCursor(GetParam(1, 1) - 1, GetParam(0, 1) - 1);
    'J':  { ED - Erase in Display }
      case GetParam(0, 0) of
        0: FBuffer.EraseToEOS;
        1: FBuffer.EraseFromBOS;
        2, 3: FBuffer.EraseScreen;
      end;
    'K':  { EL - Erase in Line }
      case GetParam(0, 0) of
        0: FBuffer.EraseToEOL;
        1: FBuffer.EraseFromBOL;
        2: FBuffer.EraseLine;
      end;
    'L':  { IL - Insert Lines }
      FBuffer.InsertLine(GetParam(0, 1));
    'M':  { DL - Delete Lines }
      FBuffer.DeleteLine(GetParam(0, 1));
    'P':  { DCH - Delete Character }
      FBuffer.DeleteChar(GetParam(0, 1));
    'S':  { SU - Scroll Up }
      FBuffer.ScrollUp(GetParam(0, 1));
    'T':  { SD - Scroll Down }
      FBuffer.ScrollDown(GetParam(0, 1));
    'X':  { ECH - Erase Character }
      FBuffer.EraseChars(GetParam(0, 1));
    'd':  { VPA - Vertical Position Absolute }
      FBuffer.MoveCursor(FBuffer.CursorX, GetParam(0, 1) - 1);
    'm':  { SGR - Select Graphic Rendition }
      ExecuteSGR;
    'n':  { DSR - Device Status Report }
      { Ignore for now }
      ;
    'r':  { DECSTBM - Set Scrolling Region }
      if FParamCount >= 2 then
        FBuffer.SetScrollRegion(GetParam(0, 1) - 1, GetParam(1, FBuffer.Height) - 1)
      else
        FBuffer.ResetScrollRegion;
    's':  { Save cursor position }
      FBuffer.SaveCursor;
    'u':  { Restore cursor position }
      FBuffer.RestoreCursor;
  end;
end;

procedure TTerminalParser.ExecuteSGR;
var
  I, P: Integer;
  FG, BG: Byte;
  function ClampByte(V: Integer): Integer; inline;
  begin
    if V < 0 then
      Result := 0
    else if V > 255 then
      Result := 255
    else
      Result := V;
  end;
  function RGBToANSIIndex(R, G, B: Integer): Byte;
  var
    MaxC, MinC, N: Integer;
  begin
    R := ClampByte(R);
    G := ClampByte(G);
    B := ClampByte(B);

    MaxC := Max(R, Max(G, B));
    MinC := Min(R, Min(G, B));

    if (MaxC - MinC) < 24 then
    begin
      if MaxC < 48 then
        Exit(0)
      else if MaxC < 170 then
        Exit(8)
      else
        Exit(7);
    end;

    N := 0;
    if R >= 96 then N := N or 1;
    if G >= 96 then N := N or 2;
    if B >= 96 then N := N or 4;
    if N = 0 then
    begin
      if (R >= G) and (R >= B) then
        N := 1
      else if (G >= R) and (G >= B) then
        N := 2
      else
        N := 4;
    end;
    if MaxC >= 192 then
      N := N or 8;
    Result := Byte(N and $0F);
  end;
begin
  if FParamCount = 0 then
  begin
    FBuffer.ResetAttributes;
    Exit;
  end;

  I := 0;
  while I < FParamCount do
  begin
    P := FParams[I];
    case P of
      0:  { Reset }
        FBuffer.ResetAttributes;
      1:  { Bold }
        FBuffer.SetBold(True);
      4:  { Underline - approximate with color }
        ;
      5:  { Blink - ignore }
        ;
      7:  { Reverse }
        FBuffer.SetReverse(True);
      22: { Normal intensity }
        FBuffer.SetBold(False);
      24: { Underline off }
        ;
      25: { Blink off }
        ;
      27: { Reverse off }
        FBuffer.SetReverse(False);
      30..37:  { Foreground color }
        begin
          FG := FPalette.MapForeground(P - 30);
          FBuffer.SetForeground(FG);
        end;
      38:  { Extended foreground color }
        begin
          if (I + 2 < FParamCount) and (FParams[I + 1] = 5) then
          begin
            { 256-color mode: use lower 4 bits }
            FG := FPalette.MapForeground(FParams[I + 2] and $0F);
            FBuffer.SetForeground(FG);
            Inc(I, 2);
          end
          else if (I + 4 < FParamCount) and (FParams[I + 1] = 2) then
          begin
            FG := FPalette.MapForeground(
              RGBToANSIIndex(FParams[I + 2], FParams[I + 3], FParams[I + 4]));
            FBuffer.SetForeground(FG);
            Inc(I, 4);
          end;
        end;
      39: { Default foreground }
        FBuffer.SetForeground(7);
      40..47:  { Background color }
        begin
          BG := FPalette.MapBackground(P - 40);
          FBuffer.SetBackground(BG shr 4);
        end;
      48:  { Extended background color }
        begin
          if (I + 2 < FParamCount) and (FParams[I + 1] = 5) then
          begin
            BG := FPalette.MapBackground(FParams[I + 2] and $0F);
            FBuffer.SetBackground(BG shr 4);
            Inc(I, 2);
          end
          else if (I + 4 < FParamCount) and (FParams[I + 1] = 2) then
          begin
            BG := FPalette.MapBackground(
              RGBToANSIIndex(FParams[I + 2], FParams[I + 3], FParams[I + 4]));
            FBuffer.SetBackground(BG shr 4);
            Inc(I, 4);
          end;
        end;
      49: { Default background }
        FBuffer.SetBackground(0);
      90..97:  { Bright foreground color }
        begin
          FG := FPalette.MapForeground((P - 90) + 8);
          FBuffer.SetForeground(FG);
        end;
      100..107:  { Bright background color }
        begin
          BG := FPalette.MapBackground((P - 100) + 8);
          FBuffer.SetBackground(BG shr 4);
        end;
    end;
    Inc(I);
  end;
end;

procedure TTerminalParser.ExecutePrivateMode(Enable: Boolean);
var
  I, P: Integer;
begin
  for I := 0 to FParamCount - 1 do
  begin
    P := FParams[I];
    case P of
      1:    { DECCKM - Cursor Keys Mode }
        ;   { Affects arrow key encoding }
      6:    { DECOM - Origin Mode }
        FBuffer.OriginMode := Enable;
      7:    { DECAWM - Auto-Wrap Mode }
        FBuffer.AutoWrap := Enable;
      12:   { Cursor blinking }
        ;
      25:   { DECTCEM - Text Cursor Enable Mode }
        FBuffer.CursorVisible := Enable;
      1000: { X11 mouse reporting }
        FMouseX10Tracking := Enable;
      1002: { Button-event mouse reporting (drag) }
        FMouseButtonTracking := Enable;
      1003: { Any-event mouse reporting }
        FMouseAnyTracking := Enable;
      1006: { SGR mouse mode }
        FMouseSGRMode := Enable;
      47, 1047: { Alternate screen buffer (legacy/xterm) }
        begin
          SetAlternateScreenActive(Enable);
          FBuffer.EraseScreen;
        end;
      1049: { Alternate screen buffer }
        begin
          SetAlternateScreenActive(Enable);
          if Enable then
          begin
            FBuffer.SaveCursor;
            FBuffer.EraseScreen;
          end
          else
          begin
            FBuffer.EraseScreen;
            FBuffer.RestoreCursor;
          end;
        end;
    end;
  end;
end;

procedure TTerminalParser.SetAlternateScreenActive(Active: Boolean);
begin
  if FAlternateScreenActive = Active then Exit;
  FAlternateScreenActive := Active;
  if Assigned(FOnAlternateScreen) then
    FOnAlternateScreen(Active);
end;

{***************************************************************************}
{                       TTerminalView IMPLEMENTATION                        }
{***************************************************************************}

constructor TTerminalView.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := evMouseDown or evMouseUp or evMouseMove or evKeyDown or
    evCommand or evBroadcast or evTerminal;
  GrowMode := gfGrowHiX or gfGrowHiY;

  FPalette := TTerminalPalette.Create;
  FBuffer := TTerminalBuffer.Create(Size.X, Size.Y, DefaultScrollbackLines);
  FParser := TTerminalParser.Create(FBuffer, FPalette);
  FParser.OnBell := HandleBell;
  FParser.OnTitleChange := HandleTitleChange;
  FParser.OnAlternateScreen := HandleAlternateScreenChange;
  FConPTY := nil;

  FMode := tmNormal;
  FEscapeKey := DefaultEscapeKey;
  FWaitingEscapeCommand := False;
  FScrollbackPos := 0;

  FSelecting := False;
  FSelectionMode := smNone;

  FDefaultShell := 'cmd.exe';
  FScrollbackLines := DefaultScrollbackLines;
  FShowExitMessage := True;
  FVisualBell := True;  { Visual bell enabled by default }
  FVisualBellActive := False;
  FLogStream := nil;
  FTitle := '';
  FMousePassthroughEnabled := False;  { Start in Mouse:Select mode }
  FLastMouseButtonCode := 3;
  FAutoMousePassthroughOnAltScreen := True;
  FAltScreenForcedMouseMode := False;
  FMousePassthroughBeforeAltScreen := FMousePassthroughEnabled;
end;

constructor TTerminalView.CreateWithShell(var Bounds: TRect;
  const Shell: string);
begin
  Create(Bounds);
  FDefaultShell := Shell;
end;

destructor TTerminalView.Destroy;
begin
  StopLogging;
  if FConPTY <> nil then
  begin
    FConPTY.Terminate;
    FreeAndNil(FConPTY);
  end;
  FreeAndNil(FParser);
  FreeAndNil(FBuffer);
  FreeAndNil(FPalette);
  inherited;
end;

procedure TTerminalView.PostFVEvent(What, Command: Word; InfoPtr: Pointer);
var
  Event: TEvent;
begin
  Event.What := What;
  Event.Command := Command;
  Event.InfoPtr := InfoPtr;
  PutEvent(Event);
end;

function TTerminalView.Execute(const CommandLine: string): Boolean;
begin
  Result := False;

  { Create ConPTY if needed }
  if FConPTY = nil then
  begin
    FConPTY := TConPTY.Create(Size.X, Size.Y);
    FConPTY.OnPostEvent := PostFVEvent;
  end;

  { Reset buffer }
  if FAltScreenForcedMouseMode then
  begin
    SetMousePassthroughEnabled(FMousePassthroughBeforeAltScreen);
    FAltScreenForcedMouseMode := False;
  end;
  FBuffer.Reset;
  FParser.Reset;
  FScrollbackPos := 0;

  { Execute command }
  Result := FConPTY.Execute(CommandLine);
  if Result then
    EnterCaptureMode
  else
  begin
    { Show error in buffer }
    FBuffer.WriteString('Error: ' + FConPTY.LastError);
    FBuffer.LineFeed;
    DrawView;
  end;
end;

function TTerminalView.Execute(const Executable: string;
  const Args: array of string): Boolean;
begin
  Result := Execute(BuildCommandLine(Executable, Args));
end;

procedure TTerminalView.Terminate;
begin
  if FConPTY <> nil then
    FConPTY.Terminate;
end;

procedure TTerminalView.HandleTerminalData;
var
  Data: TBytes;
  WasAtBottom: Boolean;
begin
  if FConPTY <> nil then
  begin
    Data := FConPTY.ReadPendingData;
    if Length(Data) > 0 then
    begin
      { Log data if logging is enabled }
      if FLogStream <> nil then
      try
        FLogStream.WriteBuffer(Data[0], Length(Data));
      except
        { Ignore logging errors }
      end;

      { Remember if we were at the bottom before processing }
      WasAtBottom := (FScrollbackPos = 0);

      FParser.ProcessData(Data);

      { Auto-scroll to bottom only if we were already there }
      if WasAtBottom then
        FScrollbackPos := 0;

      DrawView;
    end;
  end;
end;

procedure TTerminalView.HandleTerminalExit;
begin
  if FAltScreenForcedMouseMode then
  begin
    SetMousePassthroughEnabled(FMousePassthroughBeforeAltScreen);
    FAltScreenForcedMouseMode := False;
  end;
  FMode := tmNormal;
  if FShowExitMessage then
  begin
    FBuffer.LineFeed;
    FBuffer.WriteString('[Process exited with code ');
    FBuffer.WriteString(IntToStr(FConPTY.ExitCode));
    FBuffer.WriteString(']');
    FBuffer.LineFeed;
  end;
  DrawView;
end;

function TTerminalView.TranslateKey(const Event: TEvent): TBytes;

  function EscSeq(const S: AnsiString): TBytes;
  var
    I: Integer;
  begin
    SetLength(Result, Length(S));
    for I := 1 to Length(S) do
      Result[I - 1] := Ord(S[I]);
  end;

begin
  Result := nil;

  { Handle backspace specially - send DEL (#127) for compatibility }
  if (Event.KeyCode = kbBack) or (Event.CharCode = #8) then
  begin
    SetLength(Result, 1);
    Result[0] := $7F;  { DEL character }
    Exit;
  end;

  { Handle character keys - convert to UTF-8 }
  if Event.CharCode <> #0 then
  begin
    Result := TEncoding.UTF8.GetBytes(string(Event.CharCode));
    Exit;
  end;

  { Handle special keys - send as ASCII escape sequences }
  case Event.KeyCode of
    kbUp:       Result := EscSeq(#27'[A');
    kbDown:     Result := EscSeq(#27'[B');
    kbRight:    Result := EscSeq(#27'[C');
    kbLeft:     Result := EscSeq(#27'[D');
    kbHome:     Result := EscSeq(#27'[H');
    kbEnd:      Result := EscSeq(#27'[F');
    kbIns:      Result := EscSeq(#27'[2~');
    kbDel:      Result := EscSeq(#27'[3~');
    kbPgUp:     Result := EscSeq(#27'[5~');
    kbPgDn:     Result := EscSeq(#27'[6~');
    kbF1:       Result := EscSeq(#27'OP');
    kbF2:       Result := EscSeq(#27'OQ');
    kbF3:       Result := EscSeq(#27'OR');
    kbF4:       Result := EscSeq(#27'OS');
    kbF5:       Result := EscSeq(#27'[15~');
    kbF6:       Result := EscSeq(#27'[17~');
    kbF7:       Result := EscSeq(#27'[18~');
    kbF8:       Result := EscSeq(#27'[19~');
    kbF9:       Result := EscSeq(#27'[20~');
    kbF10:      Result := EscSeq(#27'[21~');
    kbF11:      Result := EscSeq(#27'[23~');
    kbF12:      Result := EscSeq(#27'[24~');
    kbBack:     Result := EscSeq(#127);
    kbEnter:    Result := EscSeq(#13);
    kbTab:      Result := EscSeq(#9);
    kbEsc:      Result := EscSeq(#27);
  end;
end;

function TTerminalView.ShouldForwardMouseToChild: Boolean;
begin
  Result := FMousePassthroughEnabled and
    (FConPTY <> nil) and FConPTY.IsRunning and
    (FParser <> nil) and FParser.MouseTrackingEnabled and FParser.MouseSGRMode;
end;

procedure TTerminalView.SetMousePassthroughEnabled(Enable: Boolean);
begin
  if FMousePassthroughEnabled = Enable then Exit;
  FMousePassthroughEnabled := Enable;
  if Assigned(FOnTitleChange) then
    FOnTitleChange(Self);
end;

procedure TTerminalView.ToggleMousePassthrough;
begin
  SetMousePassthroughEnabled(not FMousePassthroughEnabled);
end;

function TTerminalView.MouseButtonCodeFromButtons(Buttons: Byte): Integer;
begin
  if (Buttons and mbLeftButton) <> 0 then
    Result := 0
  else if (Buttons and mbMiddleButton) <> 0 then
    Result := 1
  else if (Buttons and mbRightButton) <> 0 then
    Result := 2
  else
    Result := 3;
end;

function TTerminalView.MouseModifierMask: Integer;
var
  ShiftState: Byte;
begin
  Result := 0;
  ShiftState := GetShiftState;
  if (ShiftState and (kbLeftShift or kbRightShift)) <> 0 then
    Result := Result or 4;
  if (ShiftState and kbAltShift) <> 0 then
    Result := Result or 8;
  if (ShiftState and kbCtrlShift) <> 0 then
    Result := Result or 16;
end;

procedure TTerminalView.SendMouseSGR(LocalX, LocalY, Cb: Integer; Released: Boolean);
var
  Suffix: Char;
begin
  if (FConPTY = nil) or not FConPTY.IsRunning then Exit;
  if LocalX < 0 then LocalX := 0;
  if LocalY < 0 then LocalY := 0;
  if LocalX >= Size.X then LocalX := Size.X - 1;
  if LocalY >= Size.Y then LocalY := Size.Y - 1;
  if Released then
    Suffix := 'm'
  else
    Suffix := 'M';
  FConPTY.WriteString(#27'[<' + IntToStr(Cb) + ';' +
    IntToStr(LocalX + 1) + ';' + IntToStr(LocalY + 1) + Suffix);
end;

procedure TTerminalView.RenderToDrawBuffer(var Buf: TDrawBuffer; Y: Integer);
var
  X: Integer;
  Cell: TTerminalCell;
  Attr: Byte;
  AbsY: Integer;
begin
  { Calculate absolute Y position accounting for scrollback }
  { FScrollbackPos = 0 means live view (no scrollback offset) }
  { FScrollbackPos > 0 means scrolled up into history }
  AbsY := Y - FScrollbackPos;

  for X := 0 to Size.X - 1 do
  begin
    Cell := FBuffer.GetCellAtAbsolute(X, AbsY);
    Attr := Cell.Attr;

    { Highlight selection }
    if IsInSelection(X, Y) then
      Attr := (Attr and $0F) or $70;  { White background for selection }

    { TDrawCell.Ch is string, Cell.Ch is Char }
    Buf[X].Ch := Cell.Ch;
    Buf[X].Attr := Attr;
    Buf[X].FG_RGB := 0;
    Buf[X].BG_RGB := 0;
  end;
end;

function TTerminalParser.GetMouseTrackingEnabled: Boolean;
begin
  Result := FMouseX10Tracking or FMouseButtonTracking or FMouseAnyTracking;
end;

function TTerminalView.IsInSelection(X, Y: Integer): Boolean;
var
  StartPt, EndPt: TSelectionPoint;
begin
  Result := False;
  if FSelectionMode = smNone then Exit;

  NormalizeSelection(StartPt, EndPt);

  case FSelectionMode of
    smChar:
      begin
        if Y < StartPt.Y then Exit;
        if Y > EndPt.Y then Exit;
        if Y = StartPt.Y then
        begin
          if Y = EndPt.Y then
            Result := (X >= StartPt.X) and (X <= EndPt.X)
          else
            Result := X >= StartPt.X;
        end
        else if Y = EndPt.Y then
          Result := X <= EndPt.X
        else
          Result := True;
      end;
    smLine:
      Result := (Y >= StartPt.Y) and (Y <= EndPt.Y);
  end;
end;

procedure TTerminalView.NormalizeSelection(out StartPt, EndPt: TSelectionPoint);
begin
  if (FSelStart.Y < FSelEnd.Y) or
     ((FSelStart.Y = FSelEnd.Y) and (FSelStart.X <= FSelEnd.X)) then
  begin
    StartPt := FSelStart;
    EndPt := FSelEnd;
  end
  else
  begin
    StartPt := FSelEnd;
    EndPt := FSelStart;
  end;
end;

function TTerminalView.GetIsRunning: Boolean;
begin
  Result := (FConPTY <> nil) and FConPTY.IsRunning;
end;

procedure TTerminalView.UpdatePTYSize;
begin
  if (FConPTY <> nil) and FConPTY.IsRunning then
  begin
    FBuffer.Resize(Size.X, Size.Y);
    FConPTY.Resize(Size.X, Size.Y);
  end
  else
    FBuffer.Resize(Size.X, Size.Y);
end;

procedure TTerminalView.Draw;
var
  Y: Integer;
  Buf: TDrawBuffer;
begin
  for Y := 0 to Size.Y - 1 do
  begin
    RenderToDrawBuffer(Buf, Y);
    WriteLine(0, Y, Size.X, 1, Buf);
  end;

  { Show cursor if visible and in capture mode }
  if FBuffer.CursorVisible and (FMode = tmCapture) then
  begin
    SetCursor(FBuffer.CursorX, FBuffer.CursorY);
    ShowCursor;
  end
  else
    HideCursor;
end;

procedure TTerminalView.HandleEvent(var Event: TEvent);
var
  Local: TPoint;
  KeyData: TBytes;
  ShiftDown: Boolean;
  BtnCode: Integer;
  Dragging: Boolean;
  Cb: Integer;
  KeyCh: Char;
  IsMouseToggleKey: Boolean;
begin
  { Handle terminal events first }
  if Event.What = evTerminal then
  begin
    if Event.InfoPtr = FConPTY then
    begin
      case Event.Command of
        cmTerminalData:
          HandleTerminalData;
        cmTerminalExit:
          HandleTerminalExit;
      end;
      ClearEvent(Event);
      Exit;
    end;
  end;

  { Handle capture mode }
  if FMode = tmCapture then
  begin
    if Event.What = evKeyDown then
    begin
      { In Mouse:Select mode, keep typing in capture mode but allow
        local clipboard shortcuts. Ctrl+C still goes to child when no
        selection exists (normal terminal behavior). }
      if not FMousePassthroughEnabled then
      begin
        case Event.KeyCode of
          kbCtrlC, kbCtrlIns:
            begin
              if FSelectionMode <> smNone then
              begin
                CopySelection;
                ClearEvent(Event);
                Exit;
              end;
            end;
          kbCtrlV, kbShiftIns:
            begin
              Paste;
              ClearEvent(Event);
              Exit;
            end;
        end;
      end;

      { Check for escape sequence }
      if Event.KeyCode = FEscapeKey then
      begin
        if FWaitingEscapeCommand then
        begin
          { Ctrl+A Ctrl+A = send literal Ctrl+A to PTY }
          FWaitingEscapeCommand := False;
          if FConPTY <> nil then
            FConPTY.WriteChar(#1);
          ClearEvent(Event);
          Exit;
        end
        else
        begin
          { First Ctrl+A - wait for next key }
          FWaitingEscapeCommand := True;
          ClearEvent(Event);
          Exit;
        end;
      end;

      if FWaitingEscapeCommand then
      begin
        IsMouseToggleKey := False;
        KeyCh := Event.UnicodeChar;
        if KeyCh = #0 then
          KeyCh := Char(Lo(Event.KeyCode));
        if CharInSet(UpCase(KeyCh), ['M']) then
          IsMouseToggleKey := True
        else if Event.ScanCode = Hi(kbAltM) then
          IsMouseToggleKey := True;

        if IsMouseToggleKey then
        begin
          FWaitingEscapeCommand := False;
          ToggleMousePassthrough;
          ClearEvent(Event);
          Exit;
        end;

        { This key is an FV command }
        FWaitingEscapeCommand := False;
        ExitCaptureMode;
        { Don't clear event - let FV handle it }
        Exit;
      end;

      { Shift+PageUp/PageDown for scrollback (even in capture mode) }
      if (GetShiftState and (kbLeftShift or kbRightShift)) <> 0 then
      begin
        case Event.KeyCode of
          kbPgUp:
            begin
              ScrollViewUp(Size.Y - 1);
              ClearEvent(Event);
              Exit;
            end;
          kbPgDn:
            begin
              ScrollViewDown(Size.Y - 1);
              ClearEvent(Event);
              Exit;
            end;
        end;
      end;

      { Normal capture - send to PTY }
      if FConPTY <> nil then
      begin
        KeyData := TranslateKey(Event);
        if Length(KeyData) > 0 then
          FConPTY.Write(KeyData);
      end;
      ClearEvent(Event);
      Exit;
    end;
  end;

  { Handle mouse events for selection }
  case Event.What of
    evMouseDown:
      begin
        MakeLocal(Event.Where, Local);
        ShiftDown := (GetShiftState and (kbLeftShift or kbRightShift)) <> 0;

        if ShouldForwardMouseToChild and not ShiftDown then
        begin
          if FMode = tmNormal then
            EnterCaptureMode;
          if (Event.Buttons and mbScrollWheelUp) <> 0 then
            SendMouseSGR(Local.X, Local.Y, 64 or MouseModifierMask, False)
          else if (Event.Buttons and mbScrollWheelDown) <> 0 then
            SendMouseSGR(Local.X, Local.Y, 65 or MouseModifierMask, False)
          else
          begin
            BtnCode := MouseButtonCodeFromButtons(Event.Buttons);
            if BtnCode <> 3 then
            begin
              FLastMouseButtonCode := BtnCode;
              SendMouseSGR(Local.X, Local.Y, BtnCode or MouseModifierMask, False);
            end;
          end;
          ClearEvent(Event);
          Exit;
        end;

        { Mouse wheel scrolling }
        if (Event.Buttons and mbScrollWheelUp) <> 0 then
        begin
          ScrollViewUp(3);
          ClearEvent(Event);
        end
        else if (Event.Buttons and mbScrollWheelDown) <> 0 then
        begin
          ScrollViewDown(3);
          ClearEvent(Event);
        end
        else if (Event.Buttons and mbRightButton) <> 0 then
        begin
          { Modern terminal behavior:
            - right-click copies current selection
            - right-click with no selection pastes clipboard }
          if FSelectionMode <> smNone then
          begin
            CopySelection;
            ClearSelection;
          end
          else
            Paste;
          ClearEvent(Event);
        end
        else if Event.Buttons = mbLeftButton then
        begin
          if Event.Double then
          begin
            { Double-click selects word }
            SelectWord(Local.X, Local.Y);
          end
          else
          begin
            { Single click behavior:
              - Mouse:Select mode: always start local selection
              - Running + normal mode (Mouse:Pass): enter capture mode
              - Running + capture mode (Mouse:Pass): keep capture (Shift+Click starts selection)
              - Not running: start selection }
            if not FMousePassthroughEnabled then
              StartSelection(Local.X, Local.Y)
            else if (FConPTY <> nil) and FConPTY.IsRunning then
            begin
              if FMode = tmNormal then
                EnterCaptureMode
              else if ShiftDown then
                StartSelection(Local.X, Local.Y);
            end
            else
              StartSelection(Local.X, Local.Y);
          end;
          ClearEvent(Event);
        end;
      end;

    evMouseMove:
      begin
        ShiftDown := (GetShiftState and (kbLeftShift or kbRightShift)) <> 0;
        if ShouldForwardMouseToChild and not ShiftDown then
        begin
          MakeLocal(Event.Where, Local);
          BtnCode := MouseButtonCodeFromButtons(Event.Buttons);
          Dragging := BtnCode <> 3;
          if FParser.MouseAnyTracking or (FParser.MouseButtonTracking and Dragging) then
          begin
            if Dragging then
              FLastMouseButtonCode := BtnCode
            else
              BtnCode := 3;
            Cb := BtnCode or 32 or MouseModifierMask;
            SendMouseSGR(Local.X, Local.Y, Cb, False);
            ClearEvent(Event);
            Exit;
          end;
        end;

        if FSelecting then
        begin
          MakeLocal(Event.Where, Local);
          ExtendSelection(Local.X, Local.Y);
          DrawView;
          ClearEvent(Event);
        end;
      end;

    evMouseUp:
      begin
        ShiftDown := (GetShiftState and (kbLeftShift or kbRightShift)) <> 0;
        if ShouldForwardMouseToChild and not ShiftDown then
        begin
          MakeLocal(Event.Where, Local);
          BtnCode := FLastMouseButtonCode;
          if (BtnCode < 0) or (BtnCode > 3) then
            BtnCode := 3;
          SendMouseSGR(Local.X, Local.Y, BtnCode or MouseModifierMask, True);
          FLastMouseButtonCode := 3;
          ClearEvent(Event);
          Exit;
        end;

        if FSelecting then
        begin
          FSelecting := False;
          ClearEvent(Event);
        end;
      end;

    evKeyDown:
      begin
        { Handle scrollback in normal mode }
        case Event.KeyCode of
          kbPgUp:
            begin
              ScrollViewUp(Size.Y - 1);
              ClearEvent(Event);
            end;
          kbPgDn:
            begin
              ScrollViewDown(Size.Y - 1);
              ClearEvent(Event);
            end;
          kbCtrlC, kbCtrlIns:
            begin
              if FSelectionMode <> smNone then
              begin
                CopySelection;
                ClearEvent(Event);
              end;
            end;
          kbCtrlV, kbShiftIns:
            begin
              Paste;
              ClearEvent(Event);
            end;
          kbEnter, kbEsc:
            begin
              { Enter or Escape re-enters capture mode if child running }
              if (FConPTY <> nil) and FConPTY.IsRunning then
              begin
                EnterCaptureMode;
                ClearEvent(Event);
              end;
            end;
        end;
      end;
  end;

  inherited HandleEvent(Event);
end;

procedure TTerminalView.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState and sfExposed <> 0) and Enable then
    UpdatePTYSize;
end;

procedure TTerminalView.ChangeBounds(var Bounds: TRect);
begin
  inherited ChangeBounds(Bounds);
  UpdatePTYSize;
end;

procedure TTerminalView.StartSelection(X, Y: Integer);
begin
  FSelecting := True;
  FSelectionMode := smChar;
  FSelStart.X := X;
  FSelStart.Y := Y;
  FSelEnd := FSelStart;
  DrawView;
end;

procedure TTerminalView.ExtendSelection(X, Y: Integer);
begin
  if X < 0 then X := 0;
  if X >= Size.X then X := Size.X - 1;
  if Y < 0 then Y := 0;
  if Y >= Size.Y then Y := Size.Y - 1;

  FSelEnd.X := X;
  FSelEnd.Y := Y;
end;

procedure TTerminalView.CopySelection;
var
  Text: string;
begin
  Text := GetSelectedText;
  if Length(Text) > 0 then
    ClipboardSetText(Text);
end;

procedure TTerminalView.Paste;
var
  Text: string;
begin
  if ClipboardHasText then
  begin
    Text := ClipboardGetText;
    if (FConPTY <> nil) and (Length(Text) > 0) then
      FConPTY.WriteString(Text);
  end;
end;

procedure TTerminalView.ClearSelection;
begin
  FSelectionMode := smNone;
  FSelecting := False;
  DrawView;
end;

function TTerminalView.GetSelectedText: string;
var
  StartPt, EndPt: TSelectionPoint;
  Y: Integer;
  Line: string;
begin
  Result := '';
  if FSelectionMode = smNone then Exit;

  NormalizeSelection(StartPt, EndPt);

  for Y := StartPt.Y to EndPt.Y do
  begin
    Line := FBuffer.GetLineTextAbsolute(Y - FScrollbackPos);

    if Y = StartPt.Y then
    begin
      if Y = EndPt.Y then
        Line := Copy(Line, StartPt.X + 1, EndPt.X - StartPt.X + 1)
      else
        Line := Copy(Line, StartPt.X + 1, Length(Line) - StartPt.X);
    end
    else if Y = EndPt.Y then
      Line := Copy(Line, 1, EndPt.X + 1);

    { Trim trailing spaces }
    Line := TrimRight(Line);

    Result := Result + Line;
    if Y < EndPt.Y then
      Result := Result + #13#10;
  end;
end;

procedure TTerminalView.HandleBell;
begin
  if FVisualBell then
    DoVisualBell
  else
    MessageBeep(0);
end;

procedure TTerminalView.HandleTitleChange(const NewTitle: string);
begin
  FTitle := NewTitle;
  if Assigned(FOnTitleChange) then
    FOnTitleChange(Self);
end;

procedure TTerminalView.HandleAlternateScreenChange(Active: Boolean);
begin
  if not FAutoMousePassthroughOnAltScreen then Exit;

  if Active then
  begin
    if not FAltScreenForcedMouseMode then
    begin
      FMousePassthroughBeforeAltScreen := FMousePassthroughEnabled;
      FAltScreenForcedMouseMode := True;
    end;
    SetMousePassthroughEnabled(True);
  end
  else if FAltScreenForcedMouseMode then
  begin
    SetMousePassthroughEnabled(FMousePassthroughBeforeAltScreen);
    FAltScreenForcedMouseMode := False;
  end;
end;

procedure TTerminalView.DoVisualBell;
var
  Y: Integer;
  Buf: TDrawBuffer;
  X: Integer;
  Cell: TTerminalCell;
  Attr: Byte;
begin
  { Invert display briefly for visual bell }
  for Y := 0 to Size.Y - 1 do
  begin
    for X := 0 to Size.X - 1 do
    begin
      Cell := FBuffer.GetCell(X, Y);
      { Invert foreground and background }
      Attr := ((Cell.Attr and $0F) shl 4) or ((Cell.Attr and $F0) shr 4);
      Buf[X].Ch := Cell.Ch;
      Buf[X].Attr := Attr;
      Buf[X].FG_RGB := 0;
      Buf[X].BG_RGB := 0;
    end;
    WriteLine(0, Y, Size.X, 1, Buf);
  end;

  { Brief delay }
  Sleep(50);

  { Restore normal display }
  DrawView;
end;

procedure TTerminalView.SelectWord(X, Y: Integer);
var
  Line: string;
  StartX, EndX: Integer;
  Ch: Char;
begin
  if (Y < 0) or (Y >= Size.Y) then Exit;
  if (X < 0) or (X >= Size.X) then Exit;

  Line := FBuffer.GetLineTextAbsolute(Y - FScrollbackPos);
  if Length(Line) = 0 then Exit;

  { Find word boundaries }
  { A "word" is a sequence of alphanumeric or underscore characters }
  if X >= Length(Line) then X := Length(Line) - 1;
  Ch := Line[X + 1];  { 1-based string }

  { Check if we're on a word character }
  if not CharInSet(Ch, ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
  begin
    { Not on a word - select the single character }
    FSelStart.X := X;
    FSelStart.Y := Y;
    FSelEnd.X := X;
    FSelEnd.Y := Y;
    FSelectionMode := smChar;
    DrawView;
    Exit;
  end;

  { Find start of word }
  StartX := X;
  while (StartX > 0) and CharInSet(Line[StartX], ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
    Dec(StartX);
  if not CharInSet(Line[StartX + 1], ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
    Inc(StartX);

  { Find end of word }
  EndX := X;
  while (EndX < Length(Line) - 1) and
        CharInSet(Line[EndX + 2], ['A'..'Z', 'a'..'z', '0'..'9', '_']) do
    Inc(EndX);

  FSelStart.X := StartX;
  FSelStart.Y := Y;
  FSelEnd.X := EndX;
  FSelEnd.Y := Y;
  FSelectionMode := smChar;
  DrawView;
end;

procedure TTerminalView.StartLogging(const FileName: string);
begin
  StopLogging;  { Close any existing log }

  try
    FLogStream := TFileStream.Create(FileName, fmCreate or fmShareDenyWrite);
    FLogFileName := FileName;
  except
    on E: Exception do
    begin
      FLogStream := nil;
      FLogFileName := '';
    end;
  end;
end;

procedure TTerminalView.StopLogging;
begin
  if FLogStream <> nil then
  begin
    FreeAndNil(FLogStream);
    FLogFileName := '';
  end;
end;

function TTerminalView.IsLogging: Boolean;
begin
  Result := FLogStream <> nil;
end;

procedure TTerminalView.ScrollTo(Line: Integer);
var
  MaxScroll: Integer;
begin
  MaxScroll := FBuffer.ScrollbackCount;
  if Line < 0 then Line := 0;
  if Line > MaxScroll then Line := MaxScroll;
  if FScrollbackPos <> Line then
  begin
    FScrollbackPos := Line;
    DrawView;
  end;
end;

procedure TTerminalView.ScrollViewUp(Lines: Integer);
begin
  { Scroll up into history (increase scrollback position) }
  ScrollTo(FScrollbackPos + Lines);
end;

procedure TTerminalView.ScrollViewDown(Lines: Integer);
begin
  { Scroll down toward live view (decrease scrollback position) }
  ScrollTo(FScrollbackPos - Lines);
end;

procedure TTerminalView.ScrollToBottom;
begin
  if FScrollbackPos <> 0 then
  begin
    FScrollbackPos := 0;
    DrawView;
  end;
end;

procedure TTerminalView.EnterCaptureMode;
begin
  if FSelectionMode <> smNone then
  begin
    FSelectionMode := smNone;
    FSelecting := False;
    DrawView;
  end;
  FMode := tmCapture;
  FWaitingEscapeCommand := False;
  ShowCursor;
end;

procedure TTerminalView.ExitCaptureMode;
begin
  FMode := tmNormal;
  FWaitingEscapeCommand := False;
  HideCursor;
end;

function TTerminalView.DataSize: Word;
begin
  Result := 0;
end;

procedure TTerminalView.GetData(var Rec);
begin
  { No data to get }
end;

procedure TTerminalView.SetData(var Rec);
begin
  { No data to set }
end;

function TTerminalView.Valid(Command: Word): Boolean;
begin
  Result := True;
end;

{***************************************************************************}
{                      TTerminalWindow IMPLEMENTATION                       }
{***************************************************************************}

constructor TTerminalWindow.Create(var Bounds: TRect; const ATitle: string);
var
  R: TRect;
begin
  inherited Create(Bounds, ATitle, wnNoNumber);
  Flags := wfMove or wfGrow or wfClose or wfZoom;
  GrowMode := gfGrowAll;
  FBaseTitle := ATitle;

  { Create interior rect for terminal view (leave room for scrollbar) }
  GetExtent(FInterior);
  FInterior.Grow(-1, -1);
  Dec(FInterior.B.X);  { Leave room for scrollbar }

  FTerminal := TTerminalView.Create(FInterior);
  FTerminal.OnTitleChange := HandleTerminalTitleChange;
  Insert(FTerminal);

  { Create vertical scrollbar to the right of terminal, inside the window }
  R.Assign(FInterior.B.X, FInterior.A.Y, FInterior.B.X + 1, FInterior.B.Y);
  FScrollBar := TScrollBar.Create(R);
  FScrollBar.GrowMode := gfGrowLoX or gfGrowHiX or gfGrowHiY;
  FScrollBar.Options := FScrollBar.Options and not ofSelectable;  { Don't steal focus }
  Insert(FScrollBar);
  FScrollBar.SetRange(0, 0);  { Will be updated when scrollback grows }

  { Ensure terminal has focus }
  FTerminal.Select;
  RefreshWindowTitle;
end;

constructor TTerminalWindow.CreateWithShell(var Bounds: TRect;
  const ATitle, Shell: string);
begin
  Create(Bounds, ATitle);
  FTerminal.DefaultShell := Shell;
end;

destructor TTerminalWindow.Destroy;
begin
  { Terminal view is freed by TGroup.Destroy }
  inherited;
end;

function TTerminalWindow.Execute(const CommandLine: string): Boolean;
begin
  Result := FTerminal.Execute(CommandLine);
end;

function TTerminalWindow.Execute(const Executable: string;
  const Args: array of string): Boolean;
begin
  Result := FTerminal.Execute(Executable, Args);
end;

procedure TTerminalWindow.HandleEvent(var Event: TEvent);
var
  OldScrollPos: Integer;
begin
  { When terminal is in capture mode, intercept keyboard events BEFORE
    inherited handling, so F10 and other hotkeys go to the terminal
    instead of being consumed by the outer application's menu system }
  if (FTerminal.Mode = tmCapture) and (Event.What = evKeyDown) then
  begin
    FTerminal.HandleEvent(Event);
    if Event.What = evNothing then
      Exit;  { Event was handled by terminal }
  end;

  { Remember scroll position before handling event }
  OldScrollPos := FTerminal.ScrollbackPos;

  inherited HandleEvent(Event);

  { Update scrollbar when terminal data arrives }
  if Event.What = evTerminal then
  begin
    if Event.Command in [cmTerminalData, cmTerminalExit] then
      UpdateScrollBar;
  end
  { Update scrollbar when scroll position changed (keyboard/mouse scroll) }
  else if FTerminal.ScrollbackPos <> OldScrollPos then
    UpdateScrollBar;

  { Handle scrollbar changes }
  if (Event.What = evBroadcast) and (Event.Command = cmScrollBarChanged) and
     (Event.InfoPtr = FScrollBar) then
  begin
    { Scrollbar value is inverted: 0 = at bottom (live), max = at top (oldest) }
    FTerminal.ScrollTo(FScrollBar.Max - FScrollBar.Value);
    UpdateScrollBar;  { Sync scrollbar with actual position }
    ClearEvent(Event);
  end;
end;

procedure TTerminalWindow.UpdateScrollBar;
var
  MaxScroll: Integer;
begin
  if FScrollBar = nil then Exit;

  MaxScroll := FTerminal.Buffer.ScrollbackCount;
  if MaxScroll > 0 then
  begin
    { Scrollbar value: Max = at bottom (live view), 0 = at top (oldest) }
    FScrollBar.SetParams(
      MaxScroll - FTerminal.ScrollbackPos,  { Current value }
      0,                                     { Min }
      MaxScroll,                             { Max }
      FTerminal.Size.Y - 1,                  { Page step }
      1                                      { Arrow step }
    );
  end
  else
    FScrollBar.SetParams(1, 0, 1, 1, 1);  { Show thumb at bottom when no scrollback }

  FScrollBar.DrawView;  { Force redraw }
end;

procedure TTerminalWindow.RefreshWindowTitle;
var
  ModeText: string;
  BaseText: string;
begin
  if (FTerminal <> nil) and FTerminal.MousePassthroughEnabled then
    ModeText := 'Mouse:Pass'
  else
    ModeText := 'Mouse:Select';

  BaseText := Trim(FBaseTitle);
  if BaseText = '' then
    BaseText := 'Terminal';

  Title := BaseText + ' [' + ModeText + ' C-A,M]';
  { Redraw frame/title and then child views to avoid blanking the terminal body. }
  if Frame <> nil then
    Frame.DrawView;
  if FTerminal <> nil then
    FTerminal.DrawView;
  if FScrollBar <> nil then
    FScrollBar.DrawView;
end;

procedure TTerminalWindow.HandleTerminalTitleChange(Sender: TObject);
begin
  { Update window title when child title OR local mode changes }
  if (FTerminal <> nil) and (FTerminal.Title <> '') then
    FBaseTitle := FTerminal.Title;
  RefreshWindowTitle;
end;

procedure TTerminalWindow.SizeLimits(var Min, Max: TPoint);
begin
  inherited SizeLimits(Min, Max);
  Min.X := 20;
  Min.Y := 6;
end;

{***************************************************************************}
{                           UTILITY FUNCTIONS                               }
{***************************************************************************}

function NewTerminalWindow(const Title, CommandLine: string): TTerminalWindow;
var
  R: TRect;
begin
  R.Assign(0, 0, 82, 26);
  Result := TTerminalWindow.Create(R, Title);
  if CommandLine <> '' then
    Result.Execute(CommandLine);
end;

end.
