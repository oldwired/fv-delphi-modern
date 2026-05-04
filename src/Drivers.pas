{*******************************************************}
{       Free Vision Drivers Unit                        }
{       Delphi-compatible version                       }
{*******************************************************}

unit Drivers;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.SyncObjs,
  Objects, FVScreen, FVCommon, fvconsts, FVUTF8;

{***************************************************************************}
{                              PUBLIC CONSTANTS                             }
{***************************************************************************}

const
  { Event type masks }
  evMouseDown = $0001;
  evMouseUp   = $0002;
  evMouseMove = $0004;
  evMouseAuto = $0008;
  evKeyDown   = $0010;
  evKeyUp     = $0020;
  evCommand   = $0100;
  evBroadcast = $0200;
  evTerminal  = $1000;   { Terminal/ConPTY events }

  { Event code masks }
  evNothing   = $0000;
  evMouse     = $000F;
  evKeyboard  = $0030;
  evMessage   = $FF00;

  { Terminal event commands }
  cmTerminalData = 100;  { Data available from PTY }
  cmTerminalExit = 101;  { PTY process has exited }

  { Extended key codes }
  kbNoKey       = $0000;  kbAltEsc      = $0100;  kbEsc         = $011B;
  kbAltSpace    = $0200;  kbCtrlIns     = $0400;  kbShiftIns    = $0500;
  kbCtrlDel     = $0600;  kbShiftDel    = $0700;  kbAltBack     = $0800;
  kbAltShiftBack= $0900;  kbBack        = $0E08;  kbCtrlBack    = $0E7F;
  kbShiftTab    = $0F00;  kbTab         = $0F09;  kbAltQ        = $1000;
  kbCtrlQ       = $1011;  kbAltW        = $1100;  kbCtrlW       = $1117;
  kbAltE        = $1200;  kbCtrlE       = $1205;  kbAltR        = $1300;
  kbCtrlR       = $1312;  kbAltT        = $1400;  kbCtrlT       = $1414;
  kbAltY        = $1500;  kbCtrlY       = $1519;  kbAltU        = $1600;
  kbCtrlU       = $1615;  kbAltI        = $1700;  kbCtrlI       = $1709;
  kbAltO        = $1800;  kbCtrlO       = $180F;  kbAltP        = $1900;
  kbCtrlP       = $1910;  kbAltLftBrack = $1A00;  kbAltRgtBrack = $1B00;
  kbCtrlEnter   = $1C0A;  kbEnter       = $1C0D;  kbAltA        = $1E00;
  kbCtrlA       = $1E01;  kbAltS        = $1F00;  kbCtrlS       = $1F13;
  kbAltD        = $2000;  kbCtrlD       = $2004;  kbAltF        = $2100;
  kbCtrlF       = $2106;  kbAltG        = $2200;  kbCtrlG       = $2207;
  kbAltH        = $2300;  kbCtrlH       = $2308;  kbAltJ        = $2400;
  kbCtrlJ       = $240A;  kbAltK        = $2500;  kbCtrlK       = $250B;
  kbAltL        = $2600;  kbCtrlL       = $260C;  kbAltSemiCol  = $2700;
  kbAltQuote    = $2800;  kbAltOpQuote  = $2900;  kbAltBkSlash  = $2B00;
  kbAltZ        = $2C00;  kbCtrlZ       = $2C1A;  kbAltX        = $2D00;
  kbCtrlX       = $2D18;  kbAltC        = $2E00;  kbCtrlC       = $2E03;
  kbAltV        = $2F00;  kbCtrlV       = $2F16;  kbAltB        = $3000;
  kbCtrlB       = $3002;  kbAltN        = $3100;  kbCtrlN       = $310E;
  kbAltM        = $3200;  kbCtrlM       = $320D;  kbAltComma    = $3300;
  kbAltPeriod   = $3400;  kbAltSlash    = $3500;  kbAltGreyAst  = $3700;
  kbSpaceBar    = $3920;  kbF1          = $3B00;  kbF2          = $3C00;
  kbF3          = $3D00;  kbF4          = $3E00;  kbF5          = $3F00;
  kbF6          = $4000;  kbF7          = $4100;  kbF8          = $4200;
  kbF9          = $4300;  kbF10         = $4400;  kbHome        = $4700;
  kbUp          = $4800;  kbPgUp        = $4900;  kbGrayMinus   = $4A2D;
  kbLeft        = $4B00;  kbCenter      = $4C00;  kbRight       = $4D00;
  kbAltGrayPlus = $4E00;  kbGrayPlus    = $4E2B;  kbEnd         = $4F00;
  kbDown        = $5000;  kbPgDn        = $5100;  kbIns         = $5200;
  kbDel         = $5300;  kbShiftF1     = $5400;  kbShiftF2     = $5500;
  kbShiftF3     = $5600;  kbShiftF4     = $5700;  kbShiftF5     = $5800;
  kbShiftF6     = $5900;  kbShiftF7     = $5A00;  kbShiftF8     = $5B00;
  kbShiftF9     = $5C00;  kbShiftF10    = $5D00;  kbCtrlF1      = $5E00;
  kbCtrlF2      = $5F00;  kbCtrlF3      = $6000;  kbCtrlF4      = $6100;
  kbCtrlF5      = $6200;  kbCtrlF6      = $6300;  kbCtrlF7      = $6400;
  kbCtrlF8      = $6500;  kbCtrlF9      = $6600;  kbCtrlF10     = $6700;
  kbAltF1       = $6800;  kbAltF2       = $6900;  kbAltF3       = $6A00;
  kbAltF4       = $6B00;  kbAltF5       = $6C00;  kbAltF6       = $6D00;
  kbAltF7       = $6E00;  kbAltF8       = $6F00;  kbAltF9       = $7000;
  kbAltF10      = $7100;  kbCtrlPrtSc   = $7200;  kbCtrlLeft    = $7300;
  kbCtrlRight   = $7400;  kbCtrlEnd     = $7500;  kbCtrlPgDn    = $7600;
  kbCtrlHome    = $7700;  kbAlt1        = $7800;  kbAlt2        = $7900;
  kbAlt3        = $7A00;  kbAlt4        = $7B00;  kbAlt5        = $7C00;
  kbAlt6        = $7D00;  kbAlt7        = $7E00;  kbAlt8        = $7F00;
  kbAlt9        = $8000;  kbAlt0        = $8100;  kbAltMinus    = $8200;
  kbAltEqual    = $8300;  kbCtrlPgUp    = $8400;  kbF11         = $8500;
  kbF12         = $8600;  kbShiftF11    = $8700;  kbShiftF12    = $8800;
  kbCtrlF11     = $8900;  kbCtrlF12     = $8A00;  kbAltF11      = $8B00;
  kbAltF12      = $8C00;  kbCtrlUp      = $8D00;  kbCtrlMinus   = $8E00;
  kbCtrlCenter  = $8F00;  kbCtrlGreyPlus= $9000;  kbCtrlDown    = $9100;
  kbCtrlTab     = $9400;  kbAltHome     = $9700;  kbAltUp       = $9800;
  kbAltPgUp     = $9900;  kbAltLeft     = $9B00;  kbAltRight    = $9D00;
  kbAltEnd      = $9F00;  kbAltDown     = $A000;  kbAltPgDn     = $A100;
  kbAltIns      = $A200;  kbAltDel      = $A300;  kbAltTab      = $A500;

  { Keyboard state and shift masks }
  kbRightShift  = $0001;
  kbLeftShift   = $0002;
  kbCtrlShift   = $0004;
  kbAltShift    = $0008;
  kbScrollState = $0010;
  kbNumState    = $0020;
  kbCapsState   = $0040;
  kbInsState    = $0080;
  kbBothShifts  = kbRightShift + kbLeftShift;

  { Mouse button state masks }
  mbLeftButton      = $01;
  mbRightButton     = $02;
  mbMiddleButton    = $04;
  mbScrollWheelDown = $08;
  mbScrollWheelUp   = $10;

  { Screen CRT mode constants }
  smBW80    = $0002;
  smCO80    = $0003;
  smMono    = $0007;
  smFont8x8 = $0100;

{***************************************************************************}
{                          PUBLIC TYPE DEFINITIONS                          }
{***************************************************************************}

{ TWordArray, PWordArray, TByteArray, PByteArray are defined in FVCommon.pas }

type
  TPoint = record
    X, Y: Integer;
  end;

  TRect = record
    A, B: TPoint;
    procedure Assign(XA, YA, XB, YB: Integer);
    procedure Copy(var Source: TRect);
    procedure Move(ADX, ADY: Integer);
    procedure Grow(ADX, ADY: Integer);
    procedure Intersect(var R: TRect);
    procedure Union(var R: TRect);
    function Contains(P: TPoint): Boolean;
    function Equals(var R: TRect): Boolean;
    function Empty: Boolean;
  end;

  TEvent = record
    What: Word;
    case Word of
      evNothing: ();
      evMouse: (
        Buttons: Byte;
        Double: Boolean;
        Where: TPoint);
      evKeyDown: (
        KeyCode: Word;            { Combined: high byte = scan code, low byte = ASCII char }
        KeyShift: Word;           { Shift state }
        CharCode: AnsiChar;       { ASCII character (copy of Lo(KeyCode) for compatibility) }
        ScanCode: Byte;           { Scan code (copy of Hi(KeyCode) for compatibility) }
        UnicodeChar: Char);       { Full Unicode character }
      evMessage: (
        Command: Word;
        case Word of
          0: (InfoPtr: Pointer);
          1: (InfoLong: LongInt);
          2: (InfoWord: Word);
          3: (InfoInt: SmallInt);
          4: (InfoByte: Byte);
          5: (InfoChar: Char));   { Unicode character }
  end;
  PEvent = ^TEvent;

  TDriversVideoMode = FVScreen.TVideoMode;

  TSysErrorFunc = function(ErrorCode: Integer; Drive: Byte): Integer;

const
  { Maximum width for draw buffers }
  MaxViewWidth = 2048;

type
  { Draw buffer - array of draw cells for line-based drawing }
  { Uses TDrawCell from FVCommon.pas - holds Unicode char and attribute }
  TDrawBuffer = array[0..MaxViewWidth - 1] of TDrawCell;
  PDrawBuffer = ^TDrawBuffer;

{***************************************************************************}
{                            INTERFACE ROUTINES                             }
{***************************************************************************}

function GetDosTicks: LongInt;
{ Draw buffer routines - unified Unicode support }
procedure DrawCell(var Buf: TDrawBuffer; Pos: Integer; Ch: Char; Attr: Byte); inline;
procedure DrawChar(var Buf: TDrawBuffer; Pos: Integer; Ch: Char; Attr: Byte; Count: Integer);
procedure DrawStr(var Buf: TDrawBuffer; Pos: Integer; const S: string; Attr: Byte);
procedure DrawCStr(var Buf: TDrawBuffer; Pos: Integer; const S: string; Attrs: Word);
procedure DrawBuf(var Dest: TDrawBuffer; DestPos: Integer; const Source: TDrawBuffer; SourcePos: Integer; Count: Integer);
procedure DrawRGBCell(var Buf: TDrawBuffer; Pos: Integer;
  const Ch: string; FG_RGB, BG_RGB: Cardinal);
{ Extended attribute drawing }
procedure DrawCharEx(var Buf: TDrawBuffer; Pos: Integer; Ch: Char; Attr: Byte; ExtAttrs: Byte; Count: Integer);
procedure DrawStrEx(var Buf: TDrawBuffer; Pos: Integer; const S: string; Attr: Byte; ExtAttrs: Byte);
procedure DrawHyperlink(var Buf: TDrawBuffer; Pos: Integer; const Text: string; Attr: Byte; const URL: string);
procedure DrawStrRGBEx(var Buf: TDrawBuffer; Pos: Integer; const S: string;
  FG_RGB, BG_RGB, UL_RGB: Cardinal; ExtAttrs: Byte);

{ String measurement }
function StrWidth(const S: string): Integer;
function CStrLen(const S: string): Integer;

{ Keyboard support routines }
function GetAltCode(Ch: Char): Word;
function GetCtrlCode(Ch: Char): Word;
function GetAltChar(KeyCode: Word): Char;
function GetCtrlChar(KeyCode: Word): Char;
function CtrlToArrow(KeyCode: Word): Word;

{ Keyboard control routines }
function GetShiftState: Byte;
procedure GetKeyEvent(var Event: TEvent);

{ Mouse control routines }
procedure ShowMouse;
procedure HideMouse;
procedure GetMouseEvent(var Event: TEvent);
procedure GetSystemEvent(var Event: TEvent);

{ Event handler control routines }
procedure InitEvents;
procedure DoneEvents;
procedure GetEvent(var Event: TEvent);
procedure PutEvent(var Event: TEvent);

{ Video control routines }
procedure InitKeyboard;
procedure DoneKeyboard;
procedure DetectVideo;
function InitDriversVideo: Boolean;
procedure DoneDriversVideo;
procedure ClearScreen;
procedure SetVideoMode(Mode: Word);

{ Error control routines }
procedure InitSysError;
procedure DoneSysError;
function SystemError(ErrorCode: Integer; Drive: Byte): Integer;

{ String output routine }
procedure PrintStr(const S: String);

{ Queued event handler routines }
function PutEventInQueue(var Event: TEvent): Boolean;
procedure NextQueuedEvent(var Event: TEvent);

procedure HideMouseCursor;
procedure ShowMouseCursor;


const
  CheckSnow    : Boolean = False;
  MouseEvents  : Boolean = False;
  MouseReverse : Boolean = False;
  HiResScreen  : Boolean = False;
  CtrlBreakHit : Boolean = False;
  SaveCtrlBreak: Boolean = False;
  SysErrActive : Boolean = False;
  FailSysErrors: Boolean = False;
  ButtonCount  : Byte = 0;
  DoubleDelay  : Word = 8;
  RepeatDelay  : Word = 8;
  SysColorAttr : Word = $4E4F;
  SysMonoAttr  : Word = $7070;
  StartupMode  : Word = $FFFF;
  CursorLines  : Word = $FFFF;
  ScreenBuffer : Pointer = nil;
  SaveInt09    : Pointer = nil;

var
  SysErrorFunc : TSysErrorFunc;
  MouseIntFlag : Byte;
  MouseButtons : Byte;
  { Milliseconds to wait for console input when idle.
    0 = pure polling (highest responsiveness, highest CPU). }
  EventIdleWaitMs: DWORD = 10;
  DriversScreenWidth  : Word;
  DriversScreenHeight : Word;
  DriversScreenMode   : TDriversVideoMode;
  MouseWhere   : TPoint;

  { Full Unicode string for the last key event.
    Supports surrogate pairs (emoji) that can't fit in a single Char.
    When this is non-empty, use it instead of Event.UnicodeChar for text insertion. }
  LastUnicodeStr: string;

  { Accumulated text from paste burst detection.
    When non-empty, GetKeyEvent detected a paste and returned cmPaste.
    ClipPaste checks this before the system clipboard. }
  PasteText: string;

implementation

{ TRect methods }

procedure TRect.Assign(XA, YA, XB, YB: Integer);
begin
  A.X := XA;
  A.Y := YA;
  B.X := XB;
  B.Y := YB;
end;

procedure TRect.Copy(var Source: TRect);
begin
  A := Source.A;
  B := Source.B;
end;

procedure TRect.Move(ADX, ADY: Integer);
begin
  Inc(A.X, ADX);
  Inc(A.Y, ADY);
  Inc(B.X, ADX);
  Inc(B.Y, ADY);
end;

procedure TRect.Grow(ADX, ADY: Integer);
begin
  Dec(A.X, ADX);
  Dec(A.Y, ADY);
  Inc(B.X, ADX);
  Inc(B.Y, ADY);
end;

procedure TRect.Intersect(var R: TRect);
begin
  if R.A.X > A.X then A.X := R.A.X;
  if R.A.Y > A.Y then A.Y := R.A.Y;
  if R.B.X < B.X then B.X := R.B.X;
  if R.B.Y < B.Y then B.Y := R.B.Y;
  if (A.X >= B.X) or (A.Y >= B.Y) then Assign(0, 0, 0, 0);
end;

procedure TRect.Union(var R: TRect);
begin
  if R.A.X < A.X then A.X := R.A.X;
  if R.A.Y < A.Y then A.Y := R.A.Y;
  if R.B.X > B.X then B.X := R.B.X;
  if R.B.Y > B.Y then B.Y := R.B.Y;
end;

function TRect.Contains(P: TPoint): Boolean;
begin
  Result := (P.X >= A.X) and (P.X < B.X) and (P.Y >= A.Y) and (P.Y < B.Y);
end;

function TRect.Equals(var R: TRect): Boolean;
begin
  Result := (A.X = R.A.X) and (A.Y = R.A.Y) and (B.X = R.B.X) and (B.Y = R.B.Y);
end;

function TRect.Empty: Boolean;
begin
  Result := (A.X >= B.X) or (A.Y >= B.Y);
end;

const
  QueueMax = 64;
  EventQSize = 16;

  { Windows console constants not always defined in Delphi }
  MOUSE_WHEELED = $0004;
  DOUBLE_CLICK = $0002;

  AltCodes: array[0..127] of Byte = (
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $82, $00, $00,
    $81, $78, $79, $7A, $7B, $7C, $7D, $7E,
    $7F, $80, $00, $00, $00, $83, $00, $00,
    $00, $1E, $30, $2E, $20, $12, $21, $22,
    $23, $17, $24, $25, $26, $32, $31, $18,
    $19, $10, $13, $1F, $14, $16, $2F, $11,
    $2D, $15, $2C, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00);

var
  HideCount: Integer;
  QueueCount: Word;
  QueueHead: Word;
  QueueTail: Word;
  LastDouble: Boolean;
  LastButtons: Byte;
  DownButtons: Byte;
  EventCount: Word;
  AutoDelay: LongInt;
  DownTicks: LongInt;
  AutoTicks: LongInt;
  LastWhereX: Word;
  LastWhereY: Word;
  DownWhereX: Word;
  DownWhereY: Word;
  LastWhere: TPoint;
  DownWhere: TPoint;
  EventQueue: array[0..EventQSize - 1] of TEvent;
  Queue: array[0..QueueMax - 1] of TEvent;
  QueueLock: TCriticalSection;
  ConsoleInput: THandle;
  VideoInitialized: Boolean;
  KeyboardInitialized: Boolean;
  EventsInitialized: Boolean;
  StartupScreenMode: TDriversVideoMode;
  { Surrogate pair buffering for emoji input }
  PendingHighSurrogate: Char;

  { Resize detection }
  LastScreenWidth: Word;
  LastScreenHeight: Word;
  { Pending VT input sequence (used for SGR mouse parsing from key stream) }
  VTPendingSeq: string;
  VTPendingTick: Cardinal;

const
  VTMouseSeqTimeoutMs = 40;

function GetDosTicks: LongInt;
begin
  Result := GetTickCount div 55;
end;

{ New unified draw buffer routines }

procedure DrawCell(var Buf: TDrawBuffer; Pos: Integer; Ch: Char; Attr: Byte);
begin
  if (Pos >= 0) and (Pos < MaxViewWidth) then
  begin
    Buf[Pos].Ch := Ch;
    Buf[Pos].Attr := Attr;
    Buf[Pos].FG_RGB := 0;
    Buf[Pos].BG_RGB := 0;
    Buf[Pos].ExtAttrs := 0;
    Buf[Pos].UL_RGB := 0;
    Buf[Pos].HyperlinkURL := '';
  end;
end;

procedure DrawChar(var Buf: TDrawBuffer; Pos: Integer; Ch: Char; Attr: Byte; Count: Integer);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if Pos + I >= MaxViewWidth then Break;
    if Pos + I >= 0 then
    begin
      Buf[Pos + I].Ch := Ch;
      Buf[Pos + I].Attr := Attr;
      Buf[Pos + I].FG_RGB := 0;
      Buf[Pos + I].BG_RGB := 0;
      Buf[Pos + I].ExtAttrs := 0;
      Buf[Pos + I].UL_RGB := 0;
      Buf[Pos + I].HyperlinkURL := '';
    end;
  end;
end;

procedure DrawStr(var Buf: TDrawBuffer; Pos: Integer; const S: string; Attr: Byte);
var
  I, Len, Col, W: Integer;
  CP: Cardinal;
  CellStr: string;
  LastCellIdx: Integer;    { last real cell index written; -1 = none yet }
  LastCellWidth: Integer;  { width of that cell so VS16 promotion knows
                             whether to expand it from 1 to 2 }
  JoinNext: Boolean;       { previous code point was ZWJ, so append next
                             visible code point to the same grapheme cell }
begin
  Len := Length(S);
  I := 1;
  Col := 0;
  LastCellIdx := -1;
  LastCellWidth := 0;
  JoinNext := False;
  while I <= Len do
  begin
    if Pos + Col >= MaxViewWidth then Break;
    { Check for surrogate pair }
    if (I < Len) and
       (Ord(S[I]) >= $D800) and (Ord(S[I]) <= $DBFF) and
       (Ord(S[I+1]) >= $DC00) and (Ord(S[I+1]) <= $DFFF) then
    begin
      CP := $10000 + Cardinal((Ord(S[I]) - $D800) shl 10) + Cardinal(Ord(S[I+1]) - $DC00);
      W := CodePointCharWidth(CP);
      CellStr := S[I] + S[I+1]; { Full surrogate pair }
      Inc(I, 2);
    end
    else
    begin
      CP := Ord(S[I]);
      W := CodePointCharWidth(CP);
      CellStr := S[I];
      Inc(I);
    end;

    if W = 0 then
    begin
      { Zero-width: combining mark, variation selector, ZWJ, etc.
        Append onto the most recent real cell so the grapheme cluster
        renders as one. Drop silently if no cell has been written yet. }
      if (LastCellIdx >= 0) and (LastCellIdx < MaxViewWidth) then
      begin
        Buf[LastCellIdx].Ch := Buf[LastCellIdx].Ch + CellStr;
        { VS16 (U+FE0F) forces emoji presentation, which terminals render
          as 2 cells. If the base was width 1, promote it now: write a
          continuation cell at Pos+Col and advance Col by one. }
        if (CP = $FE0F) and (LastCellWidth = 1) and
           (Pos + Col >= 0) and (Pos + Col < MaxViewWidth) then
        begin
          Buf[Pos + Col].Ch := '';
          Buf[Pos + Col].Attr := Buf[LastCellIdx].Attr;
          Buf[Pos + Col].FG_RGB := 0;
          Buf[Pos + Col].BG_RGB := 0;
          Buf[Pos + Col].ExtAttrs := 0;
          Buf[Pos + Col].UL_RGB := 0;
          Buf[Pos + Col].HyperlinkURL := '';
          Inc(Col);
          LastCellWidth := 2;
        end;
        if CP = $200D then
          JoinNext := True;
      end;
      Continue;
    end;

    if JoinNext and (LastCellIdx >= 0) and (LastCellIdx < MaxViewWidth) then
    begin
      Buf[LastCellIdx].Ch := Buf[LastCellIdx].Ch + CellStr;
      if W > LastCellWidth then
      begin
        if (Pos + Col >= 0) and (Pos + Col < MaxViewWidth) then
        begin
          Buf[Pos + Col].Ch := '';
          Buf[Pos + Col].Attr := Buf[LastCellIdx].Attr;
          Buf[Pos + Col].FG_RGB := 0;
          Buf[Pos + Col].BG_RGB := 0;
          Buf[Pos + Col].ExtAttrs := 0;
          Buf[Pos + Col].UL_RGB := 0;
          Buf[Pos + Col].HyperlinkURL := '';
        end;
        Inc(Col, W - LastCellWidth);
        LastCellWidth := W;
      end;
      JoinNext := False;
      Continue;
    end;

    JoinNext := False;
    if Pos + Col >= 0 then
    begin
      Buf[Pos + Col].Ch := CellStr;
      Buf[Pos + Col].Attr := Attr;
      Buf[Pos + Col].FG_RGB := 0;
      Buf[Pos + Col].BG_RGB := 0;
      Buf[Pos + Col].ExtAttrs := 0;
      Buf[Pos + Col].UL_RGB := 0;
      Buf[Pos + Col].HyperlinkURL := '';
      LastCellIdx := Pos + Col;
      LastCellWidth := W;
    end;
    { Fill continuation cell for wide chars }
    if (W = 2) and (Pos + Col + 1 >= 0) and (Pos + Col + 1 < MaxViewWidth) then
    begin
      Buf[Pos + Col + 1].Ch := '';
      Buf[Pos + Col + 1].Attr := Attr;
      Buf[Pos + Col + 1].FG_RGB := 0;
      Buf[Pos + Col + 1].BG_RGB := 0;
      Buf[Pos + Col + 1].ExtAttrs := 0;
      Buf[Pos + Col + 1].UL_RGB := 0;
      Buf[Pos + Col + 1].HyperlinkURL := '';
    end;
    Inc(Col, W);
  end;
end;

procedure DrawCStr(var Buf: TDrawBuffer; Pos: Integer; const S: string; Attrs: Word);
var
  I, Len, Col, W: Integer;
  B: Byte;
  Attr: Byte;
  CP: Cardinal;
  CellStr: string;
  LastCellIdx: Integer;
  LastCellWidth: Integer;
  JoinNext: Boolean;
begin
  Len := Length(S);
  Attr := Lo(Attrs);
  Col := 0;
  I := 1;
  LastCellIdx := -1;
  LastCellWidth := 0;
  JoinNext := False;
  while I <= Len do
  begin
    if S[I] = '~' then
    begin
      { Toggle between low and high attribute }
      B := Hi(Attrs);
      Attrs := (Lo(Attrs) shl 8) or B;
      Attr := Lo(Attrs);
      Inc(I);
      Continue;
    end;

    if Pos + Col >= MaxViewWidth then Break;
    { Check for surrogate pair }
    if (I < Len) and
       (Ord(S[I]) >= $D800) and (Ord(S[I]) <= $DBFF) and
       (Ord(S[I+1]) >= $DC00) and (Ord(S[I+1]) <= $DFFF) then
    begin
      CP := $10000 + Cardinal((Ord(S[I]) - $D800) shl 10) + Cardinal(Ord(S[I+1]) - $DC00);
      W := CodePointCharWidth(CP);
      CellStr := S[I] + S[I+1];
      Inc(I, 2);
    end
    else
    begin
      CP := Ord(S[I]);
      W := CodePointCharWidth(CP);
      CellStr := S[I];
      Inc(I);
    end;

    if W = 0 then
    begin
      { Zero-width: append onto previous real cell so the grapheme cluster
        stays together. Drop silently if no cell has been written yet. }
      if (LastCellIdx >= 0) and (LastCellIdx < MaxViewWidth) then
      begin
        Buf[LastCellIdx].Ch := Buf[LastCellIdx].Ch + CellStr;
        { VS16 promotes width-1 base to width 2 (emoji presentation). }
        if (CP = $FE0F) and (LastCellWidth = 1) and
           (Pos + Col >= 0) and (Pos + Col < MaxViewWidth) then
        begin
          Buf[Pos + Col].Ch := '';
          Buf[Pos + Col].Attr := Buf[LastCellIdx].Attr;
          Buf[Pos + Col].FG_RGB := 0;
          Buf[Pos + Col].BG_RGB := 0;
          Buf[Pos + Col].ExtAttrs := 0;
          Buf[Pos + Col].UL_RGB := 0;
          Buf[Pos + Col].HyperlinkURL := '';
          Inc(Col);
          LastCellWidth := 2;
        end;
        if CP = $200D then
          JoinNext := True;
      end;
      Continue;
    end;

    if JoinNext and (LastCellIdx >= 0) and (LastCellIdx < MaxViewWidth) then
    begin
      Buf[LastCellIdx].Ch := Buf[LastCellIdx].Ch + CellStr;
      if W > LastCellWidth then
      begin
        if (Pos + Col >= 0) and (Pos + Col < MaxViewWidth) then
        begin
          Buf[Pos + Col].Ch := '';
          Buf[Pos + Col].Attr := Buf[LastCellIdx].Attr;
          Buf[Pos + Col].FG_RGB := 0;
          Buf[Pos + Col].BG_RGB := 0;
          Buf[Pos + Col].ExtAttrs := 0;
          Buf[Pos + Col].UL_RGB := 0;
          Buf[Pos + Col].HyperlinkURL := '';
        end;
        Inc(Col, W - LastCellWidth);
        LastCellWidth := W;
      end;
      JoinNext := False;
      Continue;
    end;

    JoinNext := False;
    if Pos + Col >= 0 then
    begin
      Buf[Pos + Col].Ch := CellStr;
      Buf[Pos + Col].Attr := Attr;
      Buf[Pos + Col].FG_RGB := 0;
      Buf[Pos + Col].BG_RGB := 0;
      Buf[Pos + Col].ExtAttrs := 0;
      Buf[Pos + Col].UL_RGB := 0;
      Buf[Pos + Col].HyperlinkURL := '';
      LastCellIdx := Pos + Col;
      LastCellWidth := W;
    end;
    if (W = 2) and (Pos + Col + 1 >= 0) and (Pos + Col + 1 < MaxViewWidth) then
    begin
      Buf[Pos + Col + 1].Ch := '';
      Buf[Pos + Col + 1].Attr := Attr;
      Buf[Pos + Col + 1].FG_RGB := 0;
      Buf[Pos + Col + 1].BG_RGB := 0;
      Buf[Pos + Col + 1].ExtAttrs := 0;
      Buf[Pos + Col + 1].UL_RGB := 0;
      Buf[Pos + Col + 1].HyperlinkURL := '';
    end;
    Inc(Col, W);
  end;
end;

procedure DrawBuf(var Dest: TDrawBuffer; DestPos: Integer; const Source: TDrawBuffer; SourcePos: Integer; Count: Integer);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if DestPos + I >= MaxViewWidth then Break;
    if SourcePos + I >= MaxViewWidth then Break;
    if (DestPos + I >= 0) and (SourcePos + I >= 0) then
      Dest[DestPos + I] := Source[SourcePos + I];
  end;
end;

procedure DrawRGBCell(var Buf: TDrawBuffer; Pos: Integer;
  const Ch: string; FG_RGB, BG_RGB: Cardinal);
begin
  if (Pos >= 0) and (Pos < MaxViewWidth) then
  begin
    Buf[Pos].Ch := Ch;
    Buf[Pos].Attr := 0;
    Buf[Pos].FG_RGB := FG_RGB;
    Buf[Pos].BG_RGB := BG_RGB;
    Buf[Pos].ExtAttrs := 0;
    Buf[Pos].UL_RGB := 0;
    Buf[Pos].HyperlinkURL := '';
  end;
end;

procedure DrawCharEx(var Buf: TDrawBuffer; Pos: Integer; Ch: Char; Attr: Byte; ExtAttrs: Byte; Count: Integer);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    if Pos + I >= MaxViewWidth then Break;
    if Pos + I >= 0 then
    begin
      Buf[Pos + I].Ch := Ch;
      Buf[Pos + I].Attr := Attr;
      Buf[Pos + I].FG_RGB := 0;
      Buf[Pos + I].BG_RGB := 0;
      Buf[Pos + I].ExtAttrs := ExtAttrs;
      Buf[Pos + I].HyperlinkURL := '';
    end;
  end;
end;

procedure DrawStrEx(var Buf: TDrawBuffer; Pos: Integer; const S: string; Attr: Byte; ExtAttrs: Byte);
var
  I, Len, Col: Integer;
begin
  { Draw with standard function first, then apply ExtAttrs }
  DrawStr(Buf, Pos, S, Attr);
  { Now set ExtAttrs on the cells we just wrote }
  Len := StringDisplayWidth(S);
  for I := 0 to Len - 1 do begin
    Col := Pos + I;
    if (Col >= 0) and (Col < MaxViewWidth) then
      Buf[Col].ExtAttrs := ExtAttrs;
  end;
end;

procedure DrawHyperlink(var Buf: TDrawBuffer; Pos: Integer; const Text: string; Attr: Byte; const URL: string);
var
  I, Len, Col: Integer;
begin
  DrawStr(Buf, Pos, Text, Attr);
  Len := StringDisplayWidth(Text);
  for I := 0 to Len - 1 do begin
    Col := Pos + I;
    if (Col >= 0) and (Col < MaxViewWidth) then
      Buf[Col].HyperlinkURL := URL;
  end;
end;

procedure DrawStrRGBEx(var Buf: TDrawBuffer; Pos: Integer; const S: string;
  FG_RGB, BG_RGB, UL_RGB: Cardinal; ExtAttrs: Byte);
var
  I, Len, Col: Integer;
begin
  DrawStr(Buf, Pos, S, 0);
  Len := StringDisplayWidth(S);
  for I := 0 to Len - 1 do begin
    Col := Pos + I;
    if (Col >= 0) and (Col < MaxViewWidth) then begin
      Buf[Col].FG_RGB := FG_RGB;
      Buf[Col].BG_RGB := BG_RGB;
      Buf[Col].UL_RGB := UL_RGB;
      Buf[Col].ExtAttrs := ExtAttrs;
    end;
  end;
end;

function StrWidth(const S: string): Integer;
begin
  Result := StringDisplayWidth(S);
end;

function CStrLen(const S: string): Integer;
begin
  Result := CStrDisplayWidth(S);
end;

function GetAltCode(Ch: Char): Word;
begin
  Result := 0;
  Ch := UpCase(Ch);
  if Ord(Ch) < 128 then
    Result := AltCodes[Ord(Ch)] shl 8
  else if Ch = #240 then
    Result := $0200;
end;

function GetCtrlCode(Ch: Char): Word;
begin
  Result := GetAltCode(Ch) or (Ord(Ch) - $40);
end;

function GetAltChar(KeyCode: Word): Char;
var
  I: Integer;
begin
  Result := #0;
  if Lo(KeyCode) = 0 then begin
    if Hi(KeyCode) <= $83 then begin
      I := 0;
      while (I < 128) and (Hi(KeyCode) <> AltCodes[I]) do Inc(I);
      if I < 128 then Result := Char(I);
    end else if Hi(KeyCode) = $02 then
      Result := #240;
  end;
end;

function GetCtrlChar(KeyCode: Word): Char;
begin
  Result := #0;
  if (Lo(KeyCode) > 0) and (Lo(KeyCode) <= 26) then
    Result := Char(Lo(KeyCode) + $40);
end;

function CtrlToArrow(KeyCode: Word): Word;
const
  NumCodes = 11;
  CtrlCodes: array[0..NumCodes - 1] of Char =
    (#19, #4, #5, #24, #1, #6, #7, #22, #18, #3, #8);
  ArrowCodes: array[0..NumCodes - 1] of Word =
    (kbLeft, kbRight, kbUp, kbDown, kbHome, kbEnd, kbDel, kbIns,
     kbPgUp, kbPgDn, kbBack);
var
  I: Integer;
begin
  Result := KeyCode;
  for I := 0 to NumCodes - 1 do
    if WordRec(KeyCode).Lo = Ord(CtrlCodes[I]) then begin
      Result := ArrowCodes[I];
      Exit;
    end;
end;

function GetShiftState: Byte;
begin
  Result := 0;
  if GetKeyState(VK_RSHIFT) < 0 then Result := Result or kbRightShift;
  if GetKeyState(VK_LSHIFT) < 0 then Result := Result or kbLeftShift;
  if GetKeyState(VK_CONTROL) < 0 then Result := Result or kbCtrlShift;
  if GetKeyState(VK_MENU) < 0 then Result := Result or kbAltShift;
  if GetKeyState(VK_SCROLL) and 1 <> 0 then Result := Result or kbScrollState;
  if GetKeyState(VK_NUMLOCK) and 1 <> 0 then Result := Result or kbNumState;
  if GetKeyState(VK_CAPITAL) and 1 <> 0 then Result := Result or kbCapsState;
  if GetKeyState(VK_INSERT) and 1 <> 0 then Result := Result or kbInsState;
end;

procedure SetVTMouseTracking(Enable: Boolean);
const
  CSI = #27'[';
var
  Seq: string;
  Written: DWORD;
begin
  if Enable then
    Seq := CSI + '?1000h' + CSI + '?1002h' + CSI + '?1006h' + CSI + '?2004h'
  else
    Seq := CSI + '?2004l' + CSI + '?1006l' + CSI + '?1003l' + CSI + '?1002l' + CSI + '?1000l';

  WriteConsoleW(GetStdHandle(STD_OUTPUT_HANDLE), PChar(Seq), Length(Seq), Written, nil);
end;

function MakeKeyEventFromChar(Ch: Char; out Event: TEvent): Boolean;
begin
  FillChar(Event, SizeOf(Event), 0);
  Event.What := evKeyDown;
  if Ch = #27 then
    Event.KeyCode := kbEsc
  else if Ord(Ch) <= 255 then
    Event.KeyCode := Ord(Ch)
  else
    Event.KeyCode := 0;
  Event.CharCode := AnsiChar(Lo(Event.KeyCode));
  Event.ScanCode := Hi(Event.KeyCode);
  Event.UnicodeChar := Ch;
  Result := True;
end;

procedure QueueCharsAsKeyEvents(const S: string);
var
  I: Integer;
  Ev: TEvent;
begin
  for I := 1 to Length(S) do
  begin
    MakeKeyEventFromChar(S[I], Ev);
    PutEventInQueue(Ev);
  end;
end;

procedure ApplyVtMouseState(const Event: TEvent);
begin
  MouseWhere := Event.Where;
  LastWhere := Event.Where;
  case Event.What of
    evMouseDown:
      begin
        if (Event.Buttons and (mbScrollWheelUp or mbScrollWheelDown)) = 0 then
        begin
          LastButtons := Event.Buttons and $07;
          DownButtons := LastButtons;
          DownWhere := Event.Where;
          DownTicks := GetDosTicks;
          AutoTicks := GetDosTicks;
          if AutoTicks = 0 then AutoTicks := 1;
          AutoDelay := RepeatDelay;
        end;
      end;
    evMouseUp:
      begin
        LastButtons := Event.Buttons and $07;
        AutoTicks := 0;
      end;
    evMouseMove:
      LastButtons := Event.Buttons and $07;
  end;
end;

procedure PullVTCharsFromConsole(var Seq: string);
var
  InputRec: TInputRecord;
  NumRead: DWORD;
  Ch: Char;
begin
  while Length(Seq) < 64 do
  begin
    if not PeekConsoleInputW(ConsoleInput, InputRec, 1, NumRead) or (NumRead = 0) then
      Break;
    if InputRec.EventType <> KEY_EVENT then
      Break;

    if not InputRec.Event.KeyEvent.bKeyDown then
    begin
      ReadConsoleInputW(ConsoleInput, InputRec, 1, NumRead);
      Continue;
    end;

    Ch := InputRec.Event.KeyEvent.UnicodeChar;
    if Ch = #0 then
      Break;

    ReadConsoleInputW(ConsoleInput, InputRec, 1, NumRead);
    Seq := Seq + Ch;
    if (Ch = 'M') or (Ch = 'm') then
      Break;
  end;
end;

type
  TVTParseResult = (vprNoMatch, vprNeedMore, vprMatched);

function TryParseVTSGRMouse(const Seq: string; out Consumed: Integer;
  out Event: TEvent): TVTParseResult;
var
  P, L: Integer;
  Cb, Cx, Cy: Integer;
  FinalCh: Char;
  function ParseUInt(out V: Integer): Boolean;
  begin
    V := 0;
    Result := False;
    while (P <= L) and CharInSet(Seq[P], ['0'..'9']) do
    begin
      V := (V * 10) + (Ord(Seq[P]) - Ord('0'));
      Inc(P);
      Result := True;
    end;
  end;
  function BaseButtonsFromCb(Value: Integer): Byte;
  begin
    case (Value and 3) of
      0: Result := mbLeftButton;
      1: Result := mbMiddleButton;
      2: Result := mbRightButton;
    else
      Result := 0;
    end;
  end;
begin
  FillChar(Event, SizeOf(Event), 0);
  Consumed := 0;
  L := Length(Seq);
  if L = 0 then
    Exit(vprNoMatch);

  if (L < 3) and (Copy(Seq, 1, L) = Copy(#27'[<', 1, L)) then
    Exit(vprNeedMore);

  if (L < 3) or (Seq[1] <> #27) or (Seq[2] <> '[') or (Seq[3] <> '<') then
    Exit(vprNoMatch);

  P := 4;
  if P > L then Exit(vprNeedMore);
  if not ParseUInt(Cb) then
  begin
    if P > L then Exit(vprNeedMore);
    Exit(vprNoMatch);
  end;
  if P > L then Exit(vprNeedMore);
  if Seq[P] <> ';' then Exit(vprNoMatch);
  Inc(P);

  if P > L then Exit(vprNeedMore);
  if not ParseUInt(Cx) then
  begin
    if P > L then Exit(vprNeedMore);
    Exit(vprNoMatch);
  end;
  if P > L then Exit(vprNeedMore);
  if Seq[P] <> ';' then Exit(vprNoMatch);
  Inc(P);

  if P > L then Exit(vprNeedMore);
  if not ParseUInt(Cy) then
  begin
    if P > L then Exit(vprNeedMore);
    Exit(vprNoMatch);
  end;
  if P > L then Exit(vprNeedMore);
  FinalCh := Seq[P];
  if not CharInSet(FinalCh, ['M', 'm']) then
    Exit(vprNoMatch);

  Event.What := evMouseDown;
  Event.Double := False;
  Event.Where.X := Cx - 1;
  Event.Where.Y := Cy - 1;
  if Event.Where.X < 0 then Event.Where.X := 0;
  if Event.Where.Y < 0 then Event.Where.Y := 0;

  if (Cb and 64) <> 0 then
  begin
    if (Cb and 1) = 0 then
      Event.Buttons := mbScrollWheelUp
    else
      Event.Buttons := mbScrollWheelDown;
    Event.What := evMouseDown;
  end
  else if FinalCh = 'm' then
  begin
    Event.Buttons := 0;
    Event.What := evMouseUp;
  end
  else if (Cb and 32) <> 0 then
  begin
    Event.Buttons := BaseButtonsFromCb(Cb);
    Event.What := evMouseMove;
  end
  else
  begin
    Event.Buttons := BaseButtonsFromCb(Cb);
    Event.What := evMouseDown;
  end;

  Consumed := P;
  Result := vprMatched;
end;

procedure GetKeyEvent(var Event: TEvent);
var
  InputRec: TInputRecord;
  NumRead: DWORD;
  KeyCode: Word;
  ScanCode: Byte;
  VKey: Word;
  Ctrl, Alt, Shift: Boolean;
  UChar: Char;
  Seq: string;
  ParsedEvent: TEvent;
  ParseResult: TVTParseResult;
  Consumed: Integer;
begin
  Event.What := evNothing;
  if (ConsoleInput = 0) or (ConsoleInput = INVALID_HANDLE_VALUE) then begin
    Exit;
  end;

  if VTPendingSeq <> '' then
  begin
    PullVTCharsFromConsole(VTPendingSeq);
    ParseResult := TryParseVTSGRMouse(VTPendingSeq, Consumed, ParsedEvent);
    case ParseResult of
      vprMatched:
        begin
          if Consumed < Length(VTPendingSeq) then
            QueueCharsAsKeyEvents(Copy(VTPendingSeq, Consumed + 1, MaxInt));
          VTPendingSeq := '';
          ApplyVtMouseState(ParsedEvent);
          Event := ParsedEvent;
          Exit;
        end;
      vprNeedMore:
        if Cardinal(GetTickCount - VTPendingTick) <= VTMouseSeqTimeoutMs then
          Exit;
    end;

    MakeKeyEventFromChar(VTPendingSeq[1], Event);
    if Length(VTPendingSeq) > 1 then
      QueueCharsAsKeyEvents(Copy(VTPendingSeq, 2, MaxInt));
    VTPendingSeq := '';
    Exit;
  end;

  while PeekConsoleInputW(ConsoleInput, InputRec, 1, NumRead) and (NumRead > 0) do begin
    { Only process keyboard events here - leave others for mouse handler }
    if InputRec.EventType <> KEY_EVENT then
      Exit;
    ReadConsoleInputW(ConsoleInput, InputRec, 1, NumRead);
    if InputRec.Event.KeyEvent.bKeyDown then begin
      VKey := InputRec.Event.KeyEvent.wVirtualKeyCode;
      ScanCode := InputRec.Event.KeyEvent.wVirtualScanCode;
      Ctrl := (InputRec.Event.KeyEvent.dwControlKeyState and (LEFT_CTRL_PRESSED or RIGHT_CTRL_PRESSED)) <> 0;
      Alt := (InputRec.Event.KeyEvent.dwControlKeyState and (LEFT_ALT_PRESSED or RIGHT_ALT_PRESSED)) <> 0;
      Shift := (InputRec.Event.KeyEvent.dwControlKeyState and SHIFT_PRESSED) <> 0;

      { Get the Unicode character }
      UChar := InputRec.Event.KeyEvent.UnicodeChar;

      { Parse SGR mouse sequences arriving as VT input chars:
        ESC [ < Cb ; Cx ; Cy (M|m) }
      if UChar = #27 then
      begin
        Seq := #27;
        PullVTCharsFromConsole(Seq);
        ParseResult := TryParseVTSGRMouse(Seq, Consumed, ParsedEvent);
        case ParseResult of
          vprMatched:
            begin
              if Consumed < Length(Seq) then
                QueueCharsAsKeyEvents(Copy(Seq, Consumed + 1, MaxInt));
              ApplyVtMouseState(ParsedEvent);
              Event := ParsedEvent;
              Exit;
            end;
          vprNeedMore:
            begin
              VTPendingSeq := Seq;
              VTPendingTick := GetTickCount;
              Exit;
            end;
        end;

        if Length(Seq) > 1 then
          QueueCharsAsKeyEvents(Copy(Seq, 2, MaxInt));
        MakeKeyEventFromChar(#27, Event);
        Exit;
      end;

      { Handle surrogate pairs (emoji input from paste or emoji picker) }
      { Windows sends high surrogate ($D800-$DBFF) followed by low surrogate ($DC00-$DFFF) }
      if (Ord(UChar) >= $D800) and (Ord(UChar) <= $DBFF) then begin
        { High surrogate - buffer it and wait for the low surrogate }
        PendingHighSurrogate := UChar;
        Continue;
      end;
      if (Ord(UChar) >= $DC00) and (Ord(UChar) <= $DFFF) and (PendingHighSurrogate <> #0) then begin
        { Low surrogate - combine with buffered high surrogate into full string }
        LastUnicodeStr := PendingHighSurrogate + UChar;
        PendingHighSurrogate := #0;
      end else begin
        PendingHighSurrogate := #0;
        LastUnicodeStr := UChar;
      end;

      { Paste burst detection: if many printable chars are queued without
        modifier keys, accumulate as a single paste event instead of
        individual key events. Threshold: 3+ printable key-downs pending. }
      if (Ord(UChar) >= 32) and not Ctrl and not Alt then begin
        var PeekBuf: array[0..3] of TInputRecord;
        var PeekCount: DWORD;
        if PeekConsoleInputW(ConsoleInput, PeekBuf[0], 4, PeekCount) and (PeekCount >= 3) then begin
          var PrintableCount: Integer := 0;
          for var K := 0 to Integer(PeekCount) - 1 do
            if (PeekBuf[K].EventType = KEY_EVENT) and PeekBuf[K].Event.KeyEvent.bKeyDown
               and (Ord(PeekBuf[K].Event.KeyEvent.UnicodeChar) >= 32) then
              Inc(PrintableCount);
          if PrintableCount >= 3 then begin
            { Accumulate all queued printable chars as a single paste }
            var SB := TStringBuilder.Create;
            try
              SB.Append(UChar);
              while PeekConsoleInputW(ConsoleInput, PeekBuf[0], 1, PeekCount) and (PeekCount > 0) do begin
                if PeekBuf[0].EventType <> KEY_EVENT then Break;
                if not PeekBuf[0].Event.KeyEvent.bKeyDown then begin
                  ReadConsoleInputW(ConsoleInput, PeekBuf[0], 1, PeekCount);
                  Continue;
                end;
                var PCh := PeekBuf[0].Event.KeyEvent.UnicodeChar;
                if (Ord(PCh) < 32) and (PCh <> #13) and (PCh <> #10) and (PCh <> #9) then
                  Break;
                ReadConsoleInputW(ConsoleInput, PeekBuf[0], 1, PeekCount);
                { Handle surrogate pairs }
                if (Ord(PCh) >= $D800) and (Ord(PCh) <= $DBFF) then begin
                  if PeekConsoleInputW(ConsoleInput, PeekBuf[0], 1, PeekCount) and (PeekCount > 0)
                     and (PeekBuf[0].EventType = KEY_EVENT) and PeekBuf[0].Event.KeyEvent.bKeyDown then begin
                    ReadConsoleInputW(ConsoleInput, PeekBuf[0], 1, PeekCount);
                    SB.Append(PCh);
                    SB.Append(PeekBuf[0].Event.KeyEvent.UnicodeChar);
                  end;
                  Continue;
                end;
                SB.Append(PCh);
              end;
              PasteText := SB.ToString;
              FillChar(Event, SizeOf(Event), 0);
              Event.What := evCommand;
              Event.Command := cmPaste;
              Exit;
            finally
              SB.Free;
            end;
          end;
        end;
      end;

      { Build KeyCode - for ASCII chars, use the byte value; for Unicode, use 0 in low byte }
      if Ord(UChar) <= 255 then
        KeyCode := (ScanCode shl 8) or Ord(UChar)
      else
        KeyCode := (ScanCode shl 8); { Unicode char stored separately }

      { Handle Alt+letter and Alt+number combinations - clear the low byte }
      if Alt and not Ctrl then begin
        if ((VKey >= Ord('A')) and (VKey <= Ord('Z'))) or
           ((VKey >= Ord('0')) and (VKey <= Ord('9'))) then
          KeyCode := KeyCode and $FF00;
      end;

      { Handle special keys }
      case VKey of
        VK_F1..VK_F10:
          if Alt then KeyCode := $6800 + (VKey - VK_F1) * $100
          else if Ctrl then KeyCode := $5E00 + (VKey - VK_F1) * $100
          else if Shift then KeyCode := $5400 + (VKey - VK_F1) * $100
          else KeyCode := $3B00 + (VKey - VK_F1) * $100;
        VK_F11:
          if Alt then KeyCode := kbAltF11
          else if Ctrl then KeyCode := kbCtrlF11
          else if Shift then KeyCode := kbShiftF11
          else KeyCode := kbF11;
        VK_F12:
          if Alt then KeyCode := kbAltF12
          else if Ctrl then KeyCode := kbCtrlF12
          else if Shift then KeyCode := kbShiftF12
          else KeyCode := kbF12;
        VK_HOME:
          if Ctrl then KeyCode := kbCtrlHome
          else if Alt then KeyCode := kbAltHome
          else KeyCode := kbHome;
        VK_END:
          if Ctrl then KeyCode := kbCtrlEnd
          else if Alt then KeyCode := kbAltEnd
          else KeyCode := kbEnd;
        VK_UP:
          if Ctrl then KeyCode := kbCtrlUp
          else if Alt then KeyCode := kbAltUp
          else KeyCode := kbUp;
        VK_DOWN:
          if Ctrl then KeyCode := kbCtrlDown
          else if Alt then KeyCode := kbAltDown
          else KeyCode := kbDown;
        VK_LEFT:
          if Ctrl then KeyCode := kbCtrlLeft
          else if Alt then KeyCode := kbAltLeft
          else KeyCode := kbLeft;
        VK_RIGHT:
          if Ctrl then KeyCode := kbCtrlRight
          else if Alt then KeyCode := kbAltRight
          else KeyCode := kbRight;
        VK_PRIOR:
          if Ctrl then KeyCode := kbCtrlPgUp
          else if Alt then KeyCode := kbAltPgUp
          else KeyCode := kbPgUp;
        VK_NEXT:
          if Ctrl then KeyCode := kbCtrlPgDn
          else if Alt then KeyCode := kbAltPgDn
          else KeyCode := kbPgDn;
        VK_INSERT:
          if Ctrl then KeyCode := kbCtrlIns
          else if Shift then KeyCode := kbShiftIns
          else if Alt then KeyCode := kbAltIns
          else KeyCode := kbIns;
        VK_DELETE:
          if Ctrl then KeyCode := kbCtrlDel
          else if Shift then KeyCode := kbShiftDel
          else if Alt then KeyCode := kbAltDel
          else KeyCode := kbDel;
        VK_TAB:
          if Shift then KeyCode := kbShiftTab
          else if Ctrl then KeyCode := kbCtrlTab
          else if Alt then KeyCode := kbAltTab
          else KeyCode := kbTab;
        VK_BACK:
          if Alt then KeyCode := kbAltBack
          else if Ctrl then KeyCode := kbCtrlBack
          else KeyCode := kbBack;
        VK_RETURN:
          if Ctrl then KeyCode := kbCtrlEnter
          else KeyCode := kbEnter;
        VK_ESCAPE:
          if Alt then KeyCode := kbAltEsc
          else KeyCode := kbEsc;
        VK_SPACE:
          if Alt then KeyCode := kbAltSpace
          else KeyCode := kbSpaceBar;
      else
        if (KeyCode = 0) and (UChar = #0) then
          Continue; { Skip unknown keys }
      end;

      Event.What := evKeyDown;
      Event.KeyCode := KeyCode;
      Event.CharCode := AnsiChar(Lo(KeyCode));  { Extract ASCII char from KeyCode }
      Event.ScanCode := Hi(KeyCode);            { Extract scan code from KeyCode }
      Event.UnicodeChar := UChar;               { Store full Unicode character }
      Event.KeyShift := GetShiftState;
      Exit;
    end
    else begin
      { Key-up event: report which key was released }
      VKey := InputRec.Event.KeyEvent.wVirtualKeyCode;
      ScanCode := InputRec.Event.KeyEvent.wVirtualScanCode;
      UChar := InputRec.Event.KeyEvent.UnicodeChar;

      { Skip bare modifier releases (Shift/Ctrl/Alt/CapsLock/NumLock/ScrollLock)
        unless the application explicitly wants them - they generate too much noise.
        We still deliver key-up for all normal keys. }
      case VKey of
        VK_SHIFT, VK_LSHIFT, VK_RSHIFT,
        VK_CONTROL, VK_LCONTROL, VK_RCONTROL,
        VK_MENU, VK_LMENU, VK_RMENU,
        VK_CAPITAL, VK_NUMLOCK, VK_SCROLL:
          Continue;  { Skip modifier-only key-up }
      end;

      { Build a simple KeyCode from scan code + Unicode char }
      if Ord(UChar) <= 255 then
        KeyCode := (ScanCode shl 8) or Ord(UChar)
      else
        KeyCode := (ScanCode shl 8);

      Event.What := evKeyUp;
      Event.KeyCode := KeyCode;
      Event.CharCode := AnsiChar(Lo(KeyCode));
      Event.ScanCode := Hi(KeyCode);
      Event.UnicodeChar := UChar;
      Event.KeyShift := GetShiftState;
      Exit;
    end;
  end;
end;

procedure ShowMouse;
begin
  { Windows console mouse is always visible }
end;

procedure HideMouse;
begin
  { Windows console mouse is always visible }
end;

procedure ShowMouseCursor;
begin
  ShowMouse;
end;

procedure HideMouseCursor;
begin
  HideMouse;
end;

procedure GetMouseEvent(var Event: TEvent);
var
  InputRec: TInputRecord;
  NumRead: DWORD;
  NewButtons: Byte;
begin
  FillChar(Event, SizeOf(Event), 0);
  Event.What := evNothing;
  if (ConsoleInput = 0) or (ConsoleInput = INVALID_HANDLE_VALUE) then Exit;
  if not MouseEvents then Exit;

  while PeekConsoleInputW(ConsoleInput, InputRec, 1, NumRead) and (NumRead > 0) do begin
    if InputRec.EventType <> _MOUSE_EVENT then begin
      { Not a mouse event - leave KEY_EVENTs for keyboard handler }
      if InputRec.EventType = KEY_EVENT then
        Exit;
      { Consume the record }
      ReadConsoleInputW(ConsoleInput, InputRec, 1, NumRead);
      { Generate focus events instead of discarding }
      if InputRec.EventType = FOCUS_EVENT then begin
        Event.What := evBroadcast;
        if InputRec.Event.FocusEvent.bSetFocus then
          Event.Command := cmConsoleFocusIn
        else
          Event.Command := cmConsoleFocusOut;
        Event.InfoPtr := nil;
        Exit;
      end;
      { Discard WINDOW_BUFFER_SIZE_EVENT, MENU_EVENT etc. }
      Exit;
    end;

    ReadConsoleInputW(ConsoleInput, InputRec, 1, NumRead);

    NewButtons := 0;
    if (InputRec.Event.MouseEvent.dwButtonState and FROM_LEFT_1ST_BUTTON_PRESSED) <> 0 then
      NewButtons := NewButtons or mbLeftButton;
    if (InputRec.Event.MouseEvent.dwButtonState and RIGHTMOST_BUTTON_PRESSED) <> 0 then
      NewButtons := NewButtons or mbRightButton;
    if (InputRec.Event.MouseEvent.dwButtonState and FROM_LEFT_2ND_BUTTON_PRESSED) <> 0 then
      NewButtons := NewButtons or mbMiddleButton;

    Event.Double := False;

    { Handle button press/release - includes DOUBLE_CLICK events }
    if (InputRec.Event.MouseEvent.dwEventFlags = 0) or
       (InputRec.Event.MouseEvent.dwEventFlags = DOUBLE_CLICK) then begin
      { Button state change }
      if NewButtons > LastButtons then begin
        MouseWhere.X := InputRec.Event.MouseEvent.dwMousePosition.X;
        MouseWhere.Y := InputRec.Event.MouseEvent.dwMousePosition.Y;
        Event.What := evMouseDown;
        { Double-click: either Windows detected it OR timing-based detection }
        if (InputRec.Event.MouseEvent.dwEventFlags = DOUBLE_CLICK) or
           ((DownButtons = NewButtons) and (LastWhere.X = MouseWhere.X) and
            (LastWhere.Y = MouseWhere.Y) and (GetDosTicks - DownTicks <= DoubleDelay)) then
          Event.Double := True;
        DownButtons := NewButtons;
        DownWhere := MouseWhere;
        DownTicks := GetDosTicks;
        AutoTicks := GetDosTicks;
        if AutoTicks = 0 then AutoTicks := 1;
        AutoDelay := RepeatDelay;
      end else if NewButtons < LastButtons then begin
        MouseWhere.X := InputRec.Event.MouseEvent.dwMousePosition.X;
        MouseWhere.Y := InputRec.Event.MouseEvent.dwMousePosition.Y;
        Event.What := evMouseUp;
        AutoTicks := 0;
      end;
    end else if InputRec.Event.MouseEvent.dwEventFlags = MOUSE_MOVED then begin
      { Only generate move event if position actually changed }
      if (InputRec.Event.MouseEvent.dwMousePosition.X <> MouseWhere.X) or
         (InputRec.Event.MouseEvent.dwMousePosition.Y <> MouseWhere.Y) then begin
        MouseWhere.X := InputRec.Event.MouseEvent.dwMousePosition.X;
        MouseWhere.Y := InputRec.Event.MouseEvent.dwMousePosition.Y;
        Event.What := evMouseMove;
      end;
    end else if InputRec.Event.MouseEvent.dwEventFlags = MOUSE_WHEELED then begin
      if SmallInt(HiWord(InputRec.Event.MouseEvent.dwButtonState)) > 0 then
        NewButtons := NewButtons or mbScrollWheelUp
      else
        NewButtons := NewButtons or mbScrollWheelDown;
      Event.What := evMouseDown;
    end;

    if Event.What <> evNothing then begin
      Event.Buttons := NewButtons;
      Event.Where := MouseWhere;
      LastButtons := NewButtons and $07; { Exclude wheel }
      LastWhere := MouseWhere;
      if MouseReverse and ((Event.Buttons and 3) in [1, 2]) then
        Event.Buttons := Event.Buttons xor 3;
      Exit;
    end;
  end;

  { Check for auto repeat }
  if (AutoTicks <> 0) and (GetDosTicks >= AutoTicks + AutoDelay) then begin
    Event.What := evMouseAuto;
    Event.Buttons := LastButtons;
    Event.Where := LastWhere;
    AutoTicks := GetDosTicks;
    AutoDelay := 2;  { ~110ms between auto-repeats (2 ticks * 55ms) }
  end;
end;

procedure GetSystemEvent(var Event: TEvent);
var
  Info: TConsoleScreenBufferInfo;
  NewWidth, NewHeight: Word;
begin
  Event.What := evNothing;

  { Poll for console window resize }
  if GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), Info) then begin
    NewWidth := Info.srWindow.Right - Info.srWindow.Left + 1;
    NewHeight := Info.srWindow.Bottom - Info.srWindow.Top + 1;
    if NewWidth > MaxViewWidth then NewWidth := MaxViewWidth;

    { Check if size changed }
    if (NewWidth <> LastScreenWidth) or (NewHeight <> LastScreenHeight) then begin
      { Generate resize event }
      Event.What := evCommand;
      Event.Command := cmResizeApp;
      Event.InfoLong := (LongInt(NewHeight) shl 16) or LongInt(NewWidth); { Pack new dimensions }

      { Update tracking }
      LastScreenWidth := NewWidth;
      LastScreenHeight := NewHeight;
    end;
  end;
end;

procedure InitEvents;
begin
  if EventsInitialized then Exit;
  ConsoleInput := GetStdHandle(STD_INPUT_HANDLE);
  if ConsoleInput <> INVALID_HANDLE_VALUE then begin
    { Must include ENABLE_WINDOW_INPUT to receive window resize events
      and NOT include ENABLE_PROCESSED_INPUT so we get raw key events }
    SetConsoleMode(ConsoleInput, ENABLE_MOUSE_INPUT or ENABLE_WINDOW_INPUT or ENABLE_EXTENDED_FLAGS);
    ButtonCount := 2;
    MouseEvents := True;
    LastButtons := 0;
    DownButtons := 0;
    MouseWhere.X := 0;
    MouseWhere.Y := 0;
    LastWhere := MouseWhere;
  end;
  VTPendingSeq := '';
  VTPendingTick := 0;
  SetVTMouseTracking(True);
  EventsInitialized := True;
end;

procedure DoneEvents;
begin
  if not EventsInitialized then Exit;
  SetVTMouseTracking(False);
  MouseEvents := False;
  EventsInitialized := False;
end;

procedure PollEventSources(var Event: TEvent);
begin
  NextQueuedEvent(Event);
  if Event.What <> evNothing then
    Exit;
  GetKeyEvent(Event);
  if Event.What <> evNothing then
    Exit;
  GetMouseEvent(Event);
  if Event.What <> evNothing then
    Exit;
  GetSystemEvent(Event);
end;

procedure GetEvent(var Event: TEvent);
begin
  PollEventSources(Event);
  if Event.What <> evNothing then
    Exit;

  { Prevent a hot idle spin: wait briefly for new console input (or APCs),
    then poll once more before returning evNothing to the app idle loop. }
  if (ConsoleInput <> 0) and (ConsoleInput <> INVALID_HANDLE_VALUE) then
    WaitForSingleObjectEx(ConsoleInput, EventIdleWaitMs, True)
  else
    SleepEx(EventIdleWaitMs, True);

  PollEventSources(Event);
end;

procedure PutEvent(var Event: TEvent);
begin
  PutEventInQueue(Event);
end;

procedure InitKeyboard;
begin
  if KeyboardInitialized then Exit;
  ConsoleInput := GetStdHandle(STD_INPUT_HANDLE);
  KeyboardInitialized := True;
end;

procedure DoneKeyboard;
begin
  if not KeyboardInitialized then Exit;
  KeyboardInitialized := False;
end;

procedure DetectVideo;
var
  Info: TConsoleScreenBufferInfo;
begin
  if GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), Info) then begin
    DriversScreenWidth := Info.dwSize.X;
    DriversScreenHeight := Info.srWindow.Bottom - Info.srWindow.Top + 1;
    if DriversScreenWidth > MaxViewWidth then DriversScreenWidth := MaxViewWidth;
    DriversScreenMode.Col := DriversScreenWidth;
    DriversScreenMode.Row := DriversScreenHeight;
    DriversScreenMode.Color := True;
  end;
end;

function InitDriversVideo: Boolean;
begin
  Result := False;
  if VideoInitialized then begin
    FVScreen.DoneVideo;
  end;

  FVScreen.InitVideo;
  if FVScreen.ErrorCode <> vioOk then Exit;

  DriversScreenWidth := FVScreen.ScreenWidth;
  DriversScreenHeight := FVScreen.ScreenHeight;
  if DriversScreenWidth > MaxViewWidth then DriversScreenWidth := MaxViewWidth;

  StartupScreenMode.Col := DriversScreenWidth;
  StartupScreenMode.Row := DriversScreenHeight;
  StartupScreenMode.Color := True;
  DriversScreenMode := StartupScreenMode;

  { Update resize tracking to match actual screen size }
  LastScreenWidth := DriversScreenWidth;
  LastScreenHeight := DriversScreenHeight;

  VideoInitialized := True;
  Result := True;
end;

procedure DoneDriversVideo;
begin
  if not VideoInitialized then Exit;
  FVScreen.DoneVideo;
  VideoInitialized := False;
end;

procedure ClearScreen;
begin
  FVScreen.ClearScreen;
end;

procedure SetVideoMode(Mode: Word);
begin
  { Compatibility stub }
end;

procedure InitSysError;
begin
  SysErrActive := True;
end;

procedure DoneSysError;
begin
  SysErrActive := False;
end;

function SystemError(ErrorCode: Integer; Drive: Byte): Integer;
begin
  if FailSysErrors then
    Result := 1
  else
    Result := 0;
end;

procedure PrintStr(const S: String);
begin
  Write(S);
end;

function PutEventInQueue(var Event: TEvent): Boolean;
begin
  Result := False;
  if QueueLock <> nil then
    QueueLock.Enter;
  try
    if QueueCount < QueueMax then begin
      Queue[QueueHead] := Event;
      Inc(QueueHead);
      if QueueHead = QueueMax then QueueHead := 0;
      Inc(QueueCount);
      Result := True;
    end;
  finally
    if QueueLock <> nil then
      QueueLock.Leave;
  end;
end;

procedure NextQueuedEvent(var Event: TEvent);
begin
  if QueueLock <> nil then
    QueueLock.Enter;
  try
    if QueueCount > 0 then begin
      Event := Queue[QueueTail];
      Inc(QueueTail);
      if QueueTail = QueueMax then QueueTail := 0;
      Dec(QueueCount);
    end else
      Event.What := evNothing;
  finally
    if QueueLock <> nil then
      QueueLock.Leave;
  end;
end;

initialization
  HideCount := 0;
  QueueCount := 0;
  QueueHead := 0;
  QueueTail := 0;
  VideoInitialized := False;
  KeyboardInitialized := False;
  EventsInitialized := False;
  SysErrorFunc := SystemError;
  LastScreenWidth := 0;
  LastScreenHeight := 0;
  QueueLock := TCriticalSection.Create;
  DetectVideo;
  { Initialize resize tracking to current screen size }
  LastScreenWidth := DriversScreenWidth;
  LastScreenHeight := DriversScreenHeight;

finalization
  FreeAndNil(QueueLock);

end.
