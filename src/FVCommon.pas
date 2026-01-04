{*******************************************************}
{       Free Vision Common Types and Utilities          }
{       Delphi-compatible version                       }
{*******************************************************}

unit FVCommon;

{$I platform.inc}

interface

uses
  {$IFDEF OS_WINDOWS}
  Winapi.Windows,
  {$ENDIF}
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

  { String types (non-Unicode mode for compatibility) }
  Sw_String = ShortString;
  Sw_Char = AnsiChar;
  Sw_PString = PShortString;

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

const
  Sw_PString_Empty: Sw_PString = nil;

var
  ErrorCode: LongInt = errOk;
  ErrorInfo: Pointer = nil;

implementation

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
