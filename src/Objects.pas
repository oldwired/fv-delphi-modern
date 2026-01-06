{*******************************************************}
{       Turbo Pascal Objects Unit                       }
{       Compatibility layer for Modern Delphi 12+       }
{       MODERNIZED - No TFVObject, uses RTL generics    }
{*******************************************************}

unit Objects;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections;

const
  stOk         =  0;
  stError      = -1;
  stInitError  = -2;
  stReadError  = -3;
  stWriteError = -4;
  stGetError   = -5;
  stPutError   = -6;

type
  { Legacy PString for backward compatibility - DEPRECATED }
  PString = ^ShortString;

  { Callback types for iteration }
  TCallbackProcParam = procedure(Item: Pointer);
  TCallbackFunc = function(Item: Pointer): Boolean;
  CodePointer = Pointer;
  CodePtrInt = NativeInt;

  { Forward declarations }
  TFVStream = class;

  { Stream base class - now inherits directly from TObject }
  TFVStream = class(TObject)
  private
    FStatus: Integer;
    FErrorInfo: Integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Get: TObject; virtual;
    function GetPos: LongInt; virtual;
    function GetSize: LongInt; virtual;
    procedure Put(P: TObject); virtual;
    procedure Read(var Buf; Count: LongInt); virtual;
    function ReadStr: string; deprecated 'Binary serialization is deprecated. Use JSON serialization instead.';
    procedure Reset;
    procedure Seek(Pos: LongInt); virtual;
    procedure Truncate; virtual;
    procedure Write(var Buf; Count: LongInt); virtual;
    procedure WriteStr(const S: string); deprecated 'Binary serialization is deprecated. Use JSON serialization instead.';
    procedure Error(Code, Info: Integer); virtual;
    function Status: Integer;
    function ErrorInfo: Integer;
  end;

  TDosStream = class(TFVStream)
  private
    FHandle: THandle;
    FFileName: string;
  public
    constructor Create(const AFileName: string; Mode: Word); reintroduce; virtual;
    destructor Destroy; override;
    function GetPos: LongInt; override;
    function GetSize: LongInt; override;
    procedure Read(var Buf; Count: LongInt); override;
    procedure Seek(Pos: LongInt); override;
    procedure Truncate; override;
    procedure Write(var Buf; Count: LongInt); override;
  end;

  TBufStream = class(TDosStream)
  private
    FBuffer: Pointer;
    FBufSize: Word;
    FBufPtr: Word;
    FBufEnd: Word;
    FBufDirty: Boolean;
  public
    constructor Create(const AFileName: string; Mode: Word; Size: Word); reintroduce; virtual;
    destructor Destroy; override;
    procedure Flush; virtual;
    function GetPos: LongInt; override;
    function GetSize: LongInt; override;
    procedure Read(var Buf; Count: LongInt); override;
    procedure Seek(Pos: LongInt); override;
    procedure Truncate; override;
    procedure Write(var Buf; Count: LongInt); override;
  end;

  TMemoryStream = class(TFVStream)
  private
    FSize: LongInt;
    FPosition: LongInt;
    FCapacity: LongInt;
    FData: Pointer;
    FBlockSize: Word;
    function ChangeSize(NewSize: LongInt): Boolean;
  public
    constructor Create(ALimit, ABlockSize: Word); reintroduce; virtual;
    destructor Destroy; override;
    function GetPos: LongInt; override;
    function GetSize: LongInt; override;
    procedure Read(var Buf; Count: LongInt); override;
    procedure Seek(Pos: LongInt); override;
    procedure Truncate; override;
    procedure Write(var Buf; Count: LongInt); override;
  end;

  { Legacy stream registration - kept for compatibility, deprecated }
  PStreamRec = ^TStreamRec;
  TStreamRec = record
    ObjType: Word;
    VmtLink: Pointer;
    Load: Pointer;
    Store: Pointer;
    Next: PStreamRec;
  end;

{ Legacy procedures - kept for backward compatibility }
procedure RegisterType(var S: TStreamRec); deprecated 'Use TFVSerializerRegistry.RegisterType instead';

const
  stCreate   = $3C00;
  stOpenRead = $3D00;
  stOpenWrite= $3D01;
  stOpen     = $3D02;

var
  StreamError: Pointer = nil;

implementation

var
  StreamTypes: PStreamRec = nil;

procedure RegisterType(var S: TStreamRec);
begin
  S.Next := StreamTypes;
  StreamTypes := @S;
end;

{ TFVStream }

constructor TFVStream.Create;
begin
  inherited Create;
  FStatus := stOk;
  FErrorInfo := 0;
end;

destructor TFVStream.Destroy;
begin
  inherited Destroy;
end;

function TFVStream.Get: TObject;
begin
  Result := nil;
end;

function TFVStream.GetPos: LongInt;
begin
  Result := 0;
end;

function TFVStream.GetSize: LongInt;
begin
  Result := 0;
end;

procedure TFVStream.Put(P: TObject);
begin
end;

procedure TFVStream.Read(var Buf; Count: LongInt);
begin
end;

function TFVStream.ReadStr: string;
var
  Len: Byte;
  Temp: ShortString;
begin
  Read(Len, SizeOf(Len));
  if Len = 0 then
    Result := ''
  else begin
    SetLength(Temp, Len);
    Read(Temp[1], Len);
    Result := string(Temp);
  end;
end;

procedure TFVStream.Reset;
begin
  FStatus := stOk;
  FErrorInfo := 0;
end;

procedure TFVStream.Seek(Pos: LongInt);
begin
end;

procedure TFVStream.Truncate;
begin
end;

procedure TFVStream.Write(var Buf; Count: LongInt);
begin
end;

procedure TFVStream.WriteStr(const S: string);
var
  Len: Byte;
  Temp: ShortString;
begin
  Temp := ShortString(Copy(S, 1, 255));
  Len := Length(Temp);
  Write(Len, SizeOf(Len));
  if Len > 0 then
    Write(Temp[1], Len);
end;

procedure TFVStream.Error(Code, Info: Integer);
begin
  FStatus := Code;
  FErrorInfo := Info;
end;

function TFVStream.Status: Integer;
begin
  Result := FStatus;
end;

function TFVStream.ErrorInfo: Integer;
begin
  Result := FErrorInfo;
end;

{ TDosStream }

constructor TDosStream.Create(const AFileName: string; Mode: Word);
begin
  inherited Create;
  FFileName := AFileName;
  FHandle := INVALID_HANDLE_VALUE;
  case Mode of
    stCreate: FHandle := CreateFileW(PChar(AFileName), GENERIC_READ or GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    stOpenRead: FHandle := CreateFileW(PChar(AFileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    stOpenWrite: FHandle := CreateFileW(PChar(AFileName), GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    stOpen: FHandle := CreateFileW(PChar(AFileName), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  end;
  if FHandle = INVALID_HANDLE_VALUE then
    Error(stInitError, GetLastError);
end;

destructor TDosStream.Destroy;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FHandle);
  inherited Destroy;
end;

function TDosStream.GetPos: LongInt;
begin
  if FHandle = INVALID_HANDLE_VALUE then
    Result := 0
  else
    Result := SetFilePointer(FHandle, 0, nil, FILE_CURRENT);
end;

function TDosStream.GetSize: LongInt;
begin
  if FHandle = INVALID_HANDLE_VALUE then
    Result := 0
  else
    Result := GetFileSize(FHandle, nil);
end;

procedure TDosStream.Read(var Buf; Count: LongInt);
var
  BytesRead: DWORD;
begin
  if FHandle = INVALID_HANDLE_VALUE then
    Error(stReadError, 0)
  else if not ReadFile(FHandle, Buf, Count, BytesRead, nil) then
    Error(stReadError, GetLastError)
  else if BytesRead <> DWORD(Count) then
    Error(stReadError, 0);
end;

procedure TDosStream.Seek(Pos: LongInt);
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    SetFilePointer(FHandle, Pos, nil, FILE_BEGIN);
end;

procedure TDosStream.Truncate;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    SetEndOfFile(FHandle);
end;

procedure TDosStream.Write(var Buf; Count: LongInt);
var
  BytesWritten: DWORD;
begin
  if FHandle = INVALID_HANDLE_VALUE then
    Error(stWriteError, 0)
  else if not WriteFile(FHandle, Buf, Count, BytesWritten, nil) then
    Error(stWriteError, GetLastError)
  else if BytesWritten <> DWORD(Count) then
    Error(stWriteError, 0);
end;

{ TBufStream }

constructor TBufStream.Create(const AFileName: string; Mode: Word; Size: Word);
begin
  inherited Create(AFileName, Mode);
  FBufSize := Size;
  System.GetMem(FBuffer, Size);
  FBufPtr := 0;
  FBufEnd := 0;
  FBufDirty := False;
end;

destructor TBufStream.Destroy;
begin
  Flush;
  if FBuffer <> nil then
    System.FreeMem(FBuffer);
  inherited Destroy;
end;

procedure TBufStream.Flush;
var
  BytesWritten: DWORD;
begin
  if FBufDirty and (FHandle <> INVALID_HANDLE_VALUE) then begin
    WriteFile(FHandle, FBuffer^, FBufPtr, BytesWritten, nil);
    FBufDirty := False;
  end;
  FBufPtr := 0;
  FBufEnd := 0;
end;

function TBufStream.GetPos: LongInt;
begin
  Result := inherited GetPos - FBufEnd + FBufPtr;
end;

function TBufStream.GetSize: LongInt;
begin
  Result := inherited GetSize;
end;

procedure TBufStream.Read(var Buf; Count: LongInt);
begin
  inherited Read(Buf, Count);
end;

procedure TBufStream.Seek(Pos: LongInt);
begin
  Flush;
  inherited Seek(Pos);
end;

procedure TBufStream.Truncate;
begin
  Flush;
  inherited Truncate;
end;

procedure TBufStream.Write(var Buf; Count: LongInt);
begin
  inherited Write(Buf, Count);
end;

{ TMemoryStream }

constructor TMemoryStream.Create(ALimit, ABlockSize: Word);
begin
  inherited Create;
  FBlockSize := ABlockSize;
  FSize := 0;
  FPosition := 0;
  FCapacity := 0;
  FData := nil;
  if ALimit > 0 then
    ChangeSize(ALimit);
end;

destructor TMemoryStream.Destroy;
begin
  if FData <> nil then
    System.FreeMem(FData);
  inherited Destroy;
end;

function TMemoryStream.ChangeSize(NewSize: LongInt): Boolean;
var
  NewCapacity: LongInt;
  NewData: Pointer;
begin
  NewCapacity := (NewSize + FBlockSize - 1) div FBlockSize * FBlockSize;
  if NewCapacity <> FCapacity then begin
    if NewCapacity = 0 then begin
      if FData <> nil then
        System.FreeMem(FData);
      FData := nil;
    end else begin
      System.GetMem(NewData, NewCapacity);
      if NewData = nil then begin
        Error(stError, 0);
        Result := False;
        Exit;
      end;
      if FData <> nil then begin
        if FSize < NewCapacity then
          Move(FData^, NewData^, FSize)
        else
          Move(FData^, NewData^, NewCapacity);
        System.FreeMem(FData);
      end;
      FData := NewData;
    end;
    FCapacity := NewCapacity;
  end;
  FSize := NewSize;
  Result := True;
end;

function TMemoryStream.GetPos: LongInt;
begin
  Result := FPosition;
end;

function TMemoryStream.GetSize: LongInt;
begin
  Result := FSize;
end;

procedure TMemoryStream.Read(var Buf; Count: LongInt);
begin
  if FPosition + Count > FSize then begin
    Error(stReadError, 0);
    Exit;
  end;
  Move(PByte(FData)[FPosition], Buf, Count);
  Inc(FPosition, Count);
end;

procedure TMemoryStream.Seek(Pos: LongInt);
begin
  if (Pos < 0) or (Pos > FSize) then
    Error(stError, 0)
  else
    FPosition := Pos;
end;

procedure TMemoryStream.Truncate;
begin
  ChangeSize(FPosition);
end;

procedure TMemoryStream.Write(var Buf; Count: LongInt);
begin
  if FPosition + Count > FCapacity then
    if not ChangeSize(FPosition + Count) then
      Exit;
  Move(Buf, PByte(FData)[FPosition], Count);
  Inc(FPosition, Count);
  if FPosition > FSize then
    FSize := FPosition;
end;

end.
