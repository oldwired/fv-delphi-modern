{*******************************************************}
{       Free Vision Common Types and Utilities          }
{       Delphi-compatible version                       }
{*******************************************************}

unit FVCommon;

interface

uses
  Winapi.Windows,
  System.SysUtils;

{***************************************************************************}
{                              PUBLIC CONSTANTS                             }
{***************************************************************************}

const
  { Error base constants }
  errOk           = 0;
  errVioBase      = 1000;
  errKbdBase      = 1010;
  errFileCtrlBase = 1020;
  errMouseBase    = 1030;

  { Maximum data sizes for 32/64 bit }
  MaxBytes = 128 * 1024 * 1024;
  MaxWords = MaxBytes div SizeOf(Word);
  MaxInts  = MaxBytes div SizeOf(SmallInt);
  MaxLongs = MaxBytes div SizeOf(LongInt);
  MaxPtrs  = MaxBytes div SizeOf(Pointer);

{***************************************************************************}
{                          PUBLIC TYPE DEFINITIONS                          }
{***************************************************************************}

type
  { CPU-native types }
  CPUWord = NativeUInt;
  CPUInt = NativeInt;

  { Switched types for 32/64 bit compatibility }
  Sw_Word = Cardinal;
  Sw_Integer = LongInt;

  { Modern Unicode string types }
  Sw_String = string;           // UnicodeString (was ShortString)
  Sw_Char = Char;               // WideChar (was AnsiChar)
  FVString = string;            // UnicodeString - preferred alias
  FVChar = Char;                // WideChar - preferred alias

  { Screen cell for VT-based virtual screen buffer }
  TScreenCell = record
    Ch: string;                // Grapheme cluster (1+ code points)
    FG: Byte;                  // Foreground color (0-15 classic, 0-255 extended)
    BG: Byte;                  // Background color (0-15 classic, 0-255 extended)
    Bold: Boolean;
    Underline: Boolean;        // Kept for backward compat (set from UnderlineStyle > 0)
    Inverse: Boolean;
    Italic: Boolean;           // SGR 3
    Strikethrough: Boolean;    // SGR 9
    UnderlineStyle: Byte;      // 0=none, 1=single, 2=double, 3=curly, 4=dotted, 5=dashed
    Dim: Boolean;              // SGR 2 (faint/dim)
    Overline: Boolean;         // SGR 53
    FG_RGB: Cardinal;          // $00RRGGBB, 0 = use FG palette byte
    BG_RGB: Cardinal;          // $00RRGGBB, 0 = use BG palette byte
    UL_RGB: Cardinal;          // $00RRGGBB, 0 = use FG for underline (SGR 58;2;R;G;B)
    HyperlinkURL: string;      // OSC 8 URL (empty = no link)
    class function Empty: TScreenCell; static;
  end;

  { Draw buffer cell for rendering }
  TDrawCell = record
    Ch: string;                // Character/grapheme to display
    Attr: Word;                // Color attribute (legacy format: hi=BG, lo=FG)
    FG_RGB: Cardinal;          // $00RRGGBB, 0 = use Attr palette
    BG_RGB: Cardinal;          // $00RRGGBB, 0 = use Attr palette
    ExtAttrs: Byte;            // Extended attributes (eaItalic, eaStrikethrough, underline style, dim, overline)
    UL_RGB: Cardinal;          // $00RRGGBB, 0 = use FG for underline (SGR 58;2;R;G;B)
    HyperlinkURL: string;      // OSC 8 URL (empty = no link)
    class operator Equal(const A, B: TDrawCell): Boolean;
  end;
  PDrawCell = ^TDrawCell;

  { Path types - using regular string for modern Delphi }
  PathStr = string;
  DirStr = string;
  NameStr = string;
  ExtStr = string;
  FNameStr = string;

  { Pointer-sized integer (FPC compatibility) }
  PtrInt = NativeInt;
  PtrUInt = NativeUInt;

const
  { Extended text attribute flags (for TDrawCell.ExtAttrs) }
  eaItalic        = $01;  { Bit 0: SGR 3 }
  eaStrikethrough = $02;  { Bit 1: SGR 9 }
  eaUnderMask     = $1C;  { Bits 2-4: underline style }
  eaUnderShift    = 2;
  { Underline styles (value in bits 2-4):
    0=none, 1=single(SGR 4), 2=double(SGR 21),
    3=curly(SGR 4:3), 4=dotted(SGR 4:4), 5=dashed(SGR 4:5) }
  eaDim           = $20;  { Bit 5: SGR 2 (faint/dim) }
  eaOverline      = $40;  { Bit 6: SGR 53 }

  { Sixel placeholder character (Private Use Area) }
  SixelPlaceholder = #$E000;

  { File constants }
  FileNameLen = 255;

type

  { General arrays }
  TByteArray = array[0..MaxBytes - 1] of Byte;
  PByteArray = ^TByteArray;

  TWordArray = array[0..MaxWords - 1] of Word;
  PWordArray = ^TWordArray;

  TIntegerArray = array[0..MaxInts - 1] of SmallInt;
  PIntegerArray = ^TIntegerArray;

  TLongIntArray = array[0..MaxLongs - 1] of LongInt;
  PLongIntArray = ^TLongIntArray;

  TPointerArray = array[0..MaxPtrs - 1] of Pointer;
  PPointerArray = ^TPointerArray;

{***************************************************************************}
{                            INTERFACE ROUTINES                             }
{***************************************************************************}

function GetErrorCode: LongInt;
function GetErrorInfo: Pointer;

function Min(I, J: Sw_Integer): Sw_Integer; inline;
function Max(I, J: Sw_Integer): Sw_Integer; inline;
function MinimumOf(A, B: Real): Real;
function MaximumOf(A, B: Real): Real;
function MinIntegerOf(A, B: SmallInt): SmallInt;
function MaxIntegerOf(A, B: SmallInt): SmallInt;
function MinLongIntOf(A, B: LongInt): LongInt;
function MaxLongIntOf(A, B: LongInt): LongInt;

{ Legacy compatibility }
function MemAvail: LongInt;
function MaxAvail: LongInt;


var
  ErrorCode: LongInt = errOk;
  ErrorInfo: Pointer = nil;

implementation

{ TScreenCell }

class function TScreenCell.Empty: TScreenCell;
begin
  Result.Ch := ' ';
  Result.FG := 7;   // Light gray (default foreground)
  Result.BG := 0;   // Black (default background)
  Result.Bold := False;
  Result.Underline := False;
  Result.Inverse := False;
  Result.Italic := False;
  Result.Strikethrough := False;
  Result.UnderlineStyle := 0;
  Result.Dim := False;
  Result.Overline := False;
  Result.FG_RGB := 0;
  Result.BG_RGB := 0;
  Result.UL_RGB := 0;
  Result.HyperlinkURL := '';
end;

{ TDrawCell }

class operator TDrawCell.Equal(const A, B: TDrawCell): Boolean;
begin
  Result := (A.Ch = B.Ch) and (A.Attr = B.Attr) and
            (A.FG_RGB = B.FG_RGB) and (A.BG_RGB = B.BG_RGB) and
            (A.ExtAttrs = B.ExtAttrs) and (A.UL_RGB = B.UL_RGB) and
            (A.HyperlinkURL = B.HyperlinkURL);
end;

function GetErrorCode: LongInt;
begin
  Result := ErrorCode;
  ErrorCode := errOk;
end;

function GetErrorInfo: Pointer;
begin
  Result := ErrorInfo;
end;

function Min(I, J: Sw_Integer): Sw_Integer;
begin
  if I < J then Result := I else Result := J;
end;

function Max(I, J: Sw_Integer): Sw_Integer;
begin
  if I > J then Result := I else Result := J;
end;

function MinimumOf(A, B: Real): Real;
begin
  if B < A then Result := B else Result := A;
end;

function MaximumOf(A, B: Real): Real;
begin
  if B > A then Result := B else Result := A;
end;

function MinIntegerOf(A, B: SmallInt): SmallInt;
begin
  if B < A then Result := B else Result := A;
end;

function MaxIntegerOf(A, B: SmallInt): SmallInt;
begin
  if B > A then Result := B else Result := A;
end;

function MinLongIntOf(A, B: LongInt): LongInt;
begin
  if B < A then Result := B else Result := A;
end;

function MaxLongIntOf(A, B: LongInt): LongInt;
begin
  if B > A then Result := B else Result := A;
end;

function MemAvail: LongInt;
begin
  Result := High(LongInt);
end;

function MaxAvail: LongInt;
begin
  Result := High(LongInt);
end;

end.
