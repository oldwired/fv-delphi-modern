{*******************************************************}
{       Free Vision Drivers Unit                        }
{       Delphi-compatible version                       }
{*******************************************************}

unit Drivers;

{$I platform.inc}

interface

uses
  {$IFDEF OS_WINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.SysUtils,
  Objects, Video, fvconsts;

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
  evCommand   = $0100;
  evBroadcast = $0200;

  { Event code masks }
  evNothing   = $0000;
  evMouse     = $000F;
  evKeyboard  = $0010;
  evMessage   = $FF00;

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

const
  MaxWords = 16384;
  MaxBytes = 65520;

type
  Sw_Word = Word;
  Sw_Integer = Integer;
  Sw_String = ShortString;

  TWordArray = array[0..MaxWords - 1] of Word;
  PWordArray = ^TWordArray;
  TByteArray = array[0..MaxBytes - 1] of Byte;
  PByteArray = ^TByteArray;

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
        case Integer of
          0: (KeyCode: Word);
          1: (
            CharCode: AnsiChar;
            ScanCode: Byte;
            KeyShift: Word));
      evMessage: (
        Command: Word;
        case Word of
          0: (InfoPtr: Pointer);
          1: (InfoLong: LongInt);
          2: (InfoWord: Word);
          3: (InfoInt: SmallInt);
          4: (InfoByte: Byte);
          5: (InfoChar: AnsiChar));
  end;
  PEvent = ^TEvent;

  TDriversVideoMode = Video.TVideoMode;

  TSysErrorFunc = function(ErrorCode: Integer; Drive: Byte): Integer;

{***************************************************************************}
{                            INTERFACE ROUTINES                             }
{***************************************************************************}

function GetDosTicks: LongInt;
procedure GiveUpTimeSlice;

{ Buffer move routines }
function StrWidth(const S: ShortString): Integer;
function CStrLen(const S: ShortString): Integer;
procedure MoveStr(var Dest; const Str: ShortString; Attr: Byte);
procedure MoveCStr(var Dest; const Str: ShortString; Attrs: Word);
procedure MoveBuf(var Dest, Source; Attr: Byte; Count: Word);
procedure MoveChar(var Dest; C: AnsiChar; Attr: Byte; Count: Word);

{ Keyboard support routines }
function GetAltCode(Ch: AnsiChar): Word;
function GetCtrlCode(Ch: AnsiChar): Word;
function GetAltChar(KeyCode: Word): AnsiChar;
function GetCtrlChar(KeyCode: Word): AnsiChar;
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

{ String format routines }
procedure PrintStr(const S: String);
procedure FormatStr(var Result: ShortString; const Format: ShortString; var Params);

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
  DriversScreenWidth  : Word;
  DriversScreenHeight : Word;
  DriversScreenMode   : TDriversVideoMode;
  MouseWhere   : TPoint;

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
  MaxViewWidth = 255;

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
  ConsoleInput: THandle;
  VideoInitialized: Boolean;
  KeyboardInitialized: Boolean;
  EventsInitialized: Boolean;
  StartupScreenMode: TDriversVideoMode;
  { Resize detection }
  LastScreenWidth: Word;
  LastScreenHeight: Word;

function GetDosTicks: LongInt;
begin
  Result := GetTickCount div 55;
end;

procedure GiveUpTimeSlice;
begin
  SleepEx(10, True);
end;

function StrWidth(const S: ShortString): Integer;
begin
  Result := Length(S);
end;

function CStrLen(const S: ShortString): Integer;
var
  I, J: Integer;
begin
  J := 0;
  for I := 1 to Length(S) do
    if S[I] <> '~' then Inc(J);
  Result := J;
end;

procedure MoveStr(var Dest; const Str: ShortString; Attr: Byte);
var
  I: Word;
  P: PWord;
  Len: Word;
begin
  Len := Length(Str);
  if Len > MaxViewWidth then Len := MaxViewWidth;
  for I := 1 to Len do begin
    P := @TWordArray(Dest)[I - 1];
    P^ := (Word(Attr) shl 8) or Byte(Str[I]);
  end;
end;

procedure MoveCStr(var Dest; const Str: ShortString; Attrs: Word);
var
  B: Byte;
  I, J: Word;
  P: PWord;
begin
  J := 0;
  for I := 1 to Length(Str) do begin
    if J >= MaxViewWidth then Break;
    if Str[I] <> '~' then begin
      P := @TWordArray(Dest)[J];
      P^ := (Word(Lo(Attrs)) shl 8) or Byte(Str[I]);
      Inc(J);
    end else begin
      B := Hi(Attrs);
      WordRec(Attrs).Hi := Lo(Attrs);
      WordRec(Attrs).Lo := B;
    end;
  end;
end;

procedure MoveBuf(var Dest, Source; Attr: Byte; Count: Word);
var
  I: Word;
  P: PWord;
  Cnt: Word;
begin
  if Count = 0 then Exit;
  Cnt := Count;
  if Cnt > MaxViewWidth then Cnt := MaxViewWidth;
  for I := 1 to Cnt do begin
    P := @TWordArray(Dest)[I - 1];
    P^ := (Word(Attr) shl 8) or TByteArray(Source)[I - 1];
  end;
end;

procedure MoveChar(var Dest; C: AnsiChar; Attr: Byte; Count: Word);
var
  I: Word;
  P: PWord;
  W: Word;
  Cnt: Word;
begin
  if Count = 0 then Exit;
  Cnt := Count;
  if Cnt > MaxViewWidth then Cnt := MaxViewWidth;
  if C = #0 then begin
    { When C is #0, only change the attribute, preserve existing character }
    for I := 0 to Cnt - 1 do begin
      P := @TWordArray(Dest)[I];
      P^ := (Word(Attr) shl 8) or (P^ and $00FF);
    end;
  end else begin
    W := (Word(Attr) shl 8) or Byte(C);
    for I := 0 to Cnt - 1 do begin
      P := @TWordArray(Dest)[I];
      P^ := W;
    end;
  end;
end;

function GetAltCode(Ch: AnsiChar): Word;
begin
  Result := 0;
  Ch := UpCase(Ch);
  if Ch < #128 then
    Result := AltCodes[Ord(Ch)] shl 8
  else if Ch = #240 then
    Result := $0200;
end;

function GetCtrlCode(Ch: AnsiChar): Word;
begin
  Result := GetAltCode(Ch) or (Ord(Ch) - $40);
end;

function GetAltChar(KeyCode: Word): AnsiChar;
var
  I: Integer;
begin
  Result := #0;
  if Lo(KeyCode) = 0 then begin
    if Hi(KeyCode) <= $83 then begin
      I := 0;
      while (I < 128) and (Hi(KeyCode) <> AltCodes[I]) do Inc(I);
      if I < 128 then Result := AnsiChar(I);
    end else if Hi(KeyCode) = $02 then
      Result := #240;
  end;
end;

function GetCtrlChar(KeyCode: Word): AnsiChar;
begin
  Result := #0;
  if (Lo(KeyCode) > 0) and (Lo(KeyCode) <= 26) then
    Result := AnsiChar(Lo(KeyCode) + $40);
end;

function CtrlToArrow(KeyCode: Word): Word;
const
  NumCodes = 11;
  CtrlCodes: array[0..NumCodes - 1] of AnsiChar =
    (#19, #4, #5, #24, #1, #6, #7, #22, #18, #3, #8);
  ArrowCodes: array[0..NumCodes - 1] of Word =
    (kbLeft, kbRight, kbUp, kbDown, kbHome, kbEnd, kbDel, kbIns,
     kbPgUp, kbPgDn, kbBack);
var
  I: Integer;
begin
  Result := KeyCode;
  for I := 0 to NumCodes - 1 do
    if WordRec(KeyCode).Lo = Byte(CtrlCodes[I]) then begin
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

procedure GetKeyEvent(var Event: TEvent);
var
  InputRec: TInputRecord;
  NumRead: DWORD;
  KeyCode: Word;
  ScanCode: Byte;
  VKey: Word;
  Ctrl, Alt, Shift: Boolean;
begin
  Event.What := evNothing;
  if (ConsoleInput = 0) or (ConsoleInput = INVALID_HANDLE_VALUE) then Exit;

  while PeekConsoleInputA(ConsoleInput, InputRec, 1, NumRead) and (NumRead > 0) do begin
    { Only process keyboard events here - leave others for mouse handler }
    if InputRec.EventType <> KEY_EVENT then Exit;
    ReadConsoleInputA(ConsoleInput, InputRec, 1, NumRead);
    if InputRec.Event.KeyEvent.bKeyDown then begin
      VKey := InputRec.Event.KeyEvent.wVirtualKeyCode;
      ScanCode := InputRec.Event.KeyEvent.wVirtualScanCode;
      Ctrl := (InputRec.Event.KeyEvent.dwControlKeyState and (LEFT_CTRL_PRESSED or RIGHT_CTRL_PRESSED)) <> 0;
      Alt := (InputRec.Event.KeyEvent.dwControlKeyState and (LEFT_ALT_PRESSED or RIGHT_ALT_PRESSED)) <> 0;
      Shift := (InputRec.Event.KeyEvent.dwControlKeyState and SHIFT_PRESSED) <> 0;

      KeyCode := (ScanCode shl 8) or Byte(InputRec.Event.KeyEvent.AsciiChar);

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
        if KeyCode = 0 then Continue; { Skip unknown keys }
      end;

      Event.What := evKeyDown;
      Event.KeyCode := KeyCode;
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

  while PeekConsoleInputA(ConsoleInput, InputRec, 1, NumRead) and (NumRead > 0) do begin
    if InputRec.EventType <> _MOUSE_EVENT then begin
      { Not a mouse event, leave it in the queue for keyboard handler }
      if InputRec.EventType <> KEY_EVENT then
        ReadConsoleInputA(ConsoleInput, InputRec, 1, NumRead); { Remove non-key/mouse events }
      Exit;
    end;

    ReadConsoleInputA(ConsoleInput, InputRec, 1, NumRead);

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
      Event.InfoWord := (NewHeight shl 8) or NewWidth; { Pack new dimensions }

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
  EventsInitialized := True;
end;

procedure DoneEvents;
begin
  if not EventsInitialized then Exit;
  MouseEvents := False;
  EventsInitialized := False;
end;

procedure GetEvent(var Event: TEvent);
begin
  if QueueCount > 0 then begin
    NextQueuedEvent(Event);
    Exit;
  end;
  GetKeyEvent(Event);
  if Event.What <> evNothing then Exit;
  GetMouseEvent(Event);
  if Event.What <> evNothing then Exit;
  GetSystemEvent(Event);
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
    Video.DoneVideo;
  end;

  Video.InitVideo;
  if Video.ErrorCode <> vioOk then Exit;

  DriversScreenWidth := Video.ScreenWidth;
  DriversScreenHeight := Video.ScreenHeight;
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
  Video.DoneVideo;
  VideoInitialized := False;
end;

procedure ClearScreen;
begin
  Video.ClearScreen;
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

procedure FormatStr(var Result: ShortString; const Format: ShortString; var Params);
type
  TParamArray = array[0..15] of NativeInt;
  PParamArray = ^TParamArray;
var
  W, ResultLength: Integer;
  FormatIndex, Wth: Integer;
  Justify: Integer;
  Fill: AnsiChar;
  S: ShortString;
  ParamIndex: Integer;
  ParamPtr: PParamArray;
  UseParam: Boolean;

  function LongToStr(L: LongInt; Radix: Byte): ShortString;
  const
    HexChars: array[0..15] of AnsiChar = '0123456789ABCDEF';
  var
    I: LongInt;
    Res: ShortString;
    Sign: ShortString;
  begin
    if L < 0 then begin
      Sign := '-';
      L := Abs(L);
    end else
      Sign := '';
    Res := '';
    repeat
      I := L mod Radix;
      Res := HexChars[I] + Res;
      L := L div Radix;
    until L = 0;
    LongToStr := Sign + Res;
  end;

begin
  Result := '';
  ResultLength := 0;
  FormatIndex := 1;
  ParamIndex := 0;
  ParamPtr := @Params;

  while FormatIndex <= Length(Format) do begin
    if ResultLength >= 255 then Break;

    { Copy characters until we hit '%' }
    while (FormatIndex <= Length(Format)) and (Format[FormatIndex] <> '%') do begin
      Inc(ResultLength);
      Result[ResultLength] := Format[FormatIndex];
      Inc(FormatIndex);
      if ResultLength >= 255 then Break;
    end;

    { Process format specifier }
    if (FormatIndex < Length(Format)) and (Format[FormatIndex] = '%') then begin
      Fill := ' ';
      Justify := 0;
      Wth := 0;
      Inc(FormatIndex);
      UseParam := True;

      { Check for '0' fill }
      if (FormatIndex <= Length(Format)) and (Format[FormatIndex] = '0') then
        Fill := '0';

      { Check for '-' (right justify) }
      if (FormatIndex <= Length(Format)) and (Format[FormatIndex] = '-') then begin
        Justify := 1;
        Inc(FormatIndex);
      end;

      { Parse width }
      while (FormatIndex <= Length(Format)) and
            (Format[FormatIndex] >= '0') and (Format[FormatIndex] <= '9') do begin
        Wth := Wth * 10 + Ord(Format[FormatIndex]) - Ord('0');
        Inc(FormatIndex);
      end;

      { Process format character }
      S := '';
      if FormatIndex <= Length(Format) then begin
        case Format[FormatIndex] of
          '%': begin
            S := '%';
            UseParam := False;
          end;
          'c': S := AnsiChar(ParamPtr^[ParamIndex]);
          'd': S := LongToStr(LongInt(ParamPtr^[ParamIndex]), 10);
          's': begin
            if ParamPtr^[ParamIndex] <> 0 then
              S := PShortString(ParamPtr^[ParamIndex])^
            else
              S := '';
          end;
          'x': S := LongToStr(LongInt(ParamPtr^[ParamIndex]), 16);
        else
          UseParam := False;
        end;
        Inc(FormatIndex);

        { Only increment param index if we used a parameter }
        if UseParam then
          Inc(ParamIndex);

        { Apply width formatting }
        if Wth > 0 then begin
          if Length(S) > Wth then begin
            if Justify = 1 then
              S := Copy(S, Length(S) - Wth + 1, Wth)
            else
              S := Copy(S, 1, Wth);
          end else begin
            if Justify = 1 then begin
              while Length(S) < Wth do S := S + Fill;
            end else begin
              while Length(S) < Wth do S := Fill + S;
            end;
          end;
        end;

        { Append S to Result }
        W := Length(S);
        if W > 0 then begin
          if W + ResultLength > 255 then W := 255 - ResultLength;
          if W > 0 then begin
            Move(S[1], Result[ResultLength + 1], W);
            Inc(ResultLength, W);
          end;
        end;
      end;
    end;
  end;

  Result[0] := AnsiChar(ResultLength);
end;

function PutEventInQueue(var Event: TEvent): Boolean;
begin
  Result := False;
  if QueueCount < QueueMax then begin
    Queue[QueueHead] := Event;
    Inc(QueueHead);
    if QueueHead = QueueMax then QueueHead := 0;
    Inc(QueueCount);
    Result := True;
  end;
end;

procedure NextQueuedEvent(var Event: TEvent);
begin
  if QueueCount > 0 then begin
    Event := Queue[QueueTail];
    Inc(QueueTail);
    if QueueTail = QueueMax then QueueTail := 0;
    Dec(QueueCount);
  end else
    Event.What := evNothing;
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
  DetectVideo;
  { Initialize resize tracking to current screen size }
  LastScreenWidth := DriversScreenWidth;
  LastScreenHeight := DriversScreenHeight;

end.
