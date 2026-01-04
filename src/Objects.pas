{*******************************************************}
{       Turbo Pascal Objects Unit                       }
{       Compatibility layer for Modern Delphi           }
{       CONVERTED TO CLASS SYNTAX                       }
{*******************************************************}

unit Objects;

{$I platform.inc}

interface

uses
  {$IFDEF OS_WINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.SysUtils, System.Classes;

const
  stOk         =  0;
  stError      = -1;
  stInitError  = -2;
  stReadError  = -3;
  stWriteError = -4;
  stGetError   = -5;
  stPutError   = -6;
  coIndexError = -1;
  coOverflow   = -2;
  MaxCollectionSize = MaxInt div SizeOf(Pointer);

type
  PString = ^ShortString;

  { Forward declarations }
  TFVObject = class;
  TFVStream = class;
  TFVCollection = class;

  { Type aliases for compatibility - these are now class references, not pointers }
  PObject = TFVObject;
  PStream = TFVStream;
  PCollection = TFVCollection;

  TCallbackProcParam = procedure(Item: Pointer);
  TCallbackFunc = function(Item: Pointer): Boolean;
  CodePointer = Pointer;
  CodePtrInt = NativeInt;

  { Base object - renamed to avoid conflict with System.TObject }
  TFVObject = class(TObject)
  public
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  { Stream base class }
  TFVStream = class(TFVObject)
  private
    FStatus: Integer;
    FErrorInfo: Integer;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Get: TFVObject; virtual;
    function GetPos: LongInt; virtual;
    function GetSize: LongInt; virtual;
    procedure Put(P: TFVObject); virtual;
    procedure Read(var Buf; Count: LongInt); virtual;
    function ReadStr: PString;
    procedure Reset;
    procedure Seek(Pos: LongInt); virtual;
    procedure Truncate; virtual;
    procedure Write(var Buf; Count: LongInt); virtual;
    procedure WriteStr(P: PString);
    procedure Error(Code, Info: Integer); virtual;
    function Status: Integer;
    function ErrorInfo: Integer;
  end;

  TDosStream = class;
  PDosStream = TDosStream;
  TDosStream = class(TFVStream)
  private
    FHandle: THandle;
    FFileName: ShortString;
  public
    constructor Create(const AFileName: ShortString; Mode: Word); reintroduce; virtual;
    destructor Destroy; override;
    function GetPos: LongInt; override;
    function GetSize: LongInt; override;
    procedure Read(var Buf; Count: LongInt); override;
    procedure Seek(Pos: LongInt); override;
    procedure Truncate; override;
    procedure Write(var Buf; Count: LongInt); override;
  end;

  TBufStream = class;
  PBufStream = TBufStream;
  TBufStream = class(TDosStream)
  private
    FBuffer: Pointer;
    FBufSize: Word;
    FBufPtr: Word;
    FBufEnd: Word;
    FBufDirty: Boolean;
  public
    constructor Create(const AFileName: ShortString; Mode: Word; Size: Word); reintroduce; virtual;
    destructor Destroy; override;
    procedure Flush; virtual;
    function GetPos: LongInt; override;
    function GetSize: LongInt; override;
    procedure Read(var Buf; Count: LongInt); override;
    procedure Seek(Pos: LongInt); override;
    procedure Truncate; override;
    procedure Write(var Buf; Count: LongInt); override;
  end;

  TMemoryStream = class;
  PMemoryStream = TMemoryStream;
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

  PItemList = ^TItemList;
  TItemList = array[0..MaxCollectionSize - 1] of Pointer;

  TFVCollection = class(TFVObject)
  private
    FItems: PItemList;
    FCount: Integer;
    FLimit: Integer;
    FDelta: Integer;
  public
    constructor Create(ALimit, ADelta: Integer); reintroduce; virtual;
    constructor Load(var S: TFVStream); virtual;
    destructor Destroy; override;
    function At(Index: Integer): Pointer;
    function IndexOf(Item: Pointer): Integer; virtual;
    function GetItem(var S: TFVStream): Pointer; virtual;
    procedure AtDelete(Index: Integer);
    procedure AtFree(Index: Integer);
    procedure AtInsert(Index: Integer; Item: Pointer);
    procedure AtPut(Index: Integer; Item: Pointer);
    procedure Delete(Item: Pointer);
    procedure DeleteAll;
    procedure FreeItem(Item: Pointer); virtual;
    procedure FreeAll;
    procedure ForEach(Action: TCallbackProcParam);
    procedure Insert(Item: Pointer); virtual;
    procedure Pack;
    procedure PutItem(var S: TFVStream; Item: Pointer); virtual;
    procedure SetLimit(ALimit: Integer); virtual;
    procedure Store(var S: TFVStream);
    procedure Error(Code, Info: Integer); virtual;
    function Count: Integer;
  end;

  TSortedCollection = class;
  PSortedCollection = TSortedCollection;
  TSortedCollection = class(TFVCollection)
  private
    FDuplicates: Boolean;
  public
    constructor Create(ALimit, ADelta: Integer); override;
    constructor Load(var S: TFVStream); override;
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    function IndexOf(Item: Pointer): Integer; override;
    function KeyOf(Item: Pointer): Pointer; virtual;
    function Search(Key: Pointer; var Index: Integer): Boolean; virtual;
    procedure Insert(Item: Pointer); override;
    procedure Store(var S: TFVStream);
    property Duplicates: Boolean read FDuplicates write FDuplicates;
  end;

  TStringCollection = class;
  PStringCollection = TStringCollection;
  TStringCollection = class(TSortedCollection)
  public
    function Compare(Key1, Key2: Pointer): Integer; override;
    procedure FreeItem(Item: Pointer); override;
    function GetItem(var S: TFVStream): Pointer; override;
    procedure PutItem(var S: TFVStream; Item: Pointer); override;
  end;

  { Stream registration - kept for compatibility but will be replaced with RTTI }
  PStreamRec = ^TStreamRec;
  TStreamRec = record
    ObjType: Word;
    VmtLink: Pointer;
    Load: Pointer;
    Store: Pointer;
    Next: PStreamRec;
  end;

procedure RegisterType(var S: TStreamRec);
function NewStr(const S: ShortString): PString;
procedure DisposeStr(P: PString);

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

function NewStr(const S: ShortString): PString;
var P: PString;
begin
  if S = '' then Result := nil
  else begin
    System.GetMem(P, Length(S) + 1);
    P^ := S;
    Result := P;
  end;
end;

procedure DisposeStr(P: PString);
begin
  if P <> nil then System.FreeMem(P, Length(P^) + 1);
end;

procedure RegisterType(var S: TStreamRec);
begin
  S.Next := StreamTypes;
  StreamTypes := @S;
end;

{ TFVObject }

constructor TFVObject.Create;
begin
  inherited Create;
end;

destructor TFVObject.Destroy;
begin
  inherited Destroy;
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

function TFVStream.Get: TFVObject;
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

procedure TFVStream.Put(P: TFVObject);
begin
end;

procedure TFVStream.Read(var Buf; Count: LongInt);
begin
end;

function TFVStream.ReadStr: PString;
var
  Len: Byte;
  P: PString;
begin
  Read(Len, SizeOf(Len));
  if Len = 0 then
    Result := nil
  else begin
    System.GetMem(P, Len + 1);
    P^[0] := AnsiChar(Len);
    Read(P^[1], Len);
    Result := P;
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

procedure TFVStream.WriteStr(P: PString);
var
  Len: Byte;
begin
  if P = nil then
    Len := 0
  else
    Len := Length(P^);
  Write(Len, SizeOf(Len));
  if Len > 0 then
    Write(P^[1], Len);
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

constructor TDosStream.Create(const AFileName: ShortString; Mode: Word);
begin
  inherited Create;
  FFileName := AFileName;
  FHandle := INVALID_HANDLE_VALUE;
  case Mode of
    stCreate: FHandle := CreateFileA(PAnsiChar(AnsiString(AFileName)), GENERIC_READ or GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    stOpenRead: FHandle := CreateFileA(PAnsiChar(AnsiString(AFileName)), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    stOpenWrite: FHandle := CreateFileA(PAnsiChar(AnsiString(AFileName)), GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    stOpen: FHandle := CreateFileA(PAnsiChar(AnsiString(AFileName)), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
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

constructor TBufStream.Create(const AFileName: ShortString; Mode: Word; Size: Word);
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

{ TFVCollection }

constructor TFVCollection.Create(ALimit, ADelta: Integer);
begin
  inherited Create;
  FItems := nil;
  FCount := 0;
  FLimit := 0;
  FDelta := ADelta;
  SetLimit(ALimit);
end;

constructor TFVCollection.Load(var S: TFVStream);
var
  I: Integer;
begin
  inherited Create;
  S.Read(FCount, SizeOf(FCount));
  S.Read(FLimit, SizeOf(FLimit));
  S.Read(FDelta, SizeOf(FDelta));
  FItems := nil;
  SetLimit(FLimit);
  for I := 0 to FCount - 1 do
    FItems^[I] := GetItem(S);
end;

destructor TFVCollection.Destroy;
begin
  FreeAll;
  SetLimit(0);
  inherited Destroy;
end;

function TFVCollection.At(Index: Integer): Pointer;
begin
  if (Index < 0) or (Index >= FCount) then begin
    Error(coIndexError, Index);
    Result := nil;
  end else
    Result := FItems^[Index];
end;

function TFVCollection.IndexOf(Item: Pointer): Integer;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    if FItems^[I] = Item then begin
      Result := I;
      Exit;
    end;
  Result := -1;
end;

function TFVCollection.GetItem(var S: TFVStream): Pointer;
begin
  Result := S.Get;
end;

procedure TFVCollection.AtDelete(Index: Integer);
begin
  if (Index < 0) or (Index >= FCount) then
    Error(coIndexError, Index)
  else begin
    Dec(FCount);
    if Index < FCount then
      Move(FItems^[Index + 1], FItems^[Index], (FCount - Index) * SizeOf(Pointer));
  end;
end;

procedure TFVCollection.AtFree(Index: Integer);
var
  Item: Pointer;
begin
  Item := At(Index);
  AtDelete(Index);
  FreeItem(Item);
end;

procedure TFVCollection.AtInsert(Index: Integer; Item: Pointer);
begin
  if (Index < 0) or (Index > FCount) then
    Error(coIndexError, Index)
  else begin
    if FCount = FLimit then
      SetLimit(FLimit + FDelta);
    if Index < FCount then
      Move(FItems^[Index], FItems^[Index + 1], (FCount - Index) * SizeOf(Pointer));
    FItems^[Index] := Item;
    Inc(FCount);
  end;
end;

procedure TFVCollection.AtPut(Index: Integer; Item: Pointer);
begin
  if (Index < 0) or (Index >= FCount) then
    Error(coIndexError, Index)
  else
    FItems^[Index] := Item;
end;

procedure TFVCollection.Delete(Item: Pointer);
begin
  AtDelete(IndexOf(Item));
end;

procedure TFVCollection.DeleteAll;
begin
  FCount := 0;
end;

procedure TFVCollection.FreeItem(Item: Pointer);
begin
  { Note: Assumes Item is a TFVObject descendant. Crashes if not. }
  if (Item <> nil) and (TObject(Item) is TFVObject) then
    TFVObject(Item).Free;
end;

procedure TFVCollection.FreeAll;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
    FreeItem(FItems^[I]);
  FCount := 0;
end;

procedure TFVCollection.ForEach(Action: TCallbackProcParam);
var
  I: Integer;
begin
  if not Assigned(Action) then Exit;
  for I := 0 to FCount - 1 do
    Action(FItems^[I]);
end;

procedure TFVCollection.Insert(Item: Pointer);
begin
  AtInsert(FCount, Item);
end;

procedure TFVCollection.Pack;
var
  I, J: Integer;
begin
  J := 0;
  for I := 0 to FCount - 1 do
    if FItems^[I] <> nil then begin
      FItems^[J] := FItems^[I];
      Inc(J);
    end;
  FCount := J;
end;

procedure TFVCollection.PutItem(var S: TFVStream; Item: Pointer);
begin
  S.Put(TFVObject(Item));
end;

procedure TFVCollection.SetLimit(ALimit: Integer);
var
  NewItems: PItemList;
begin
  if ALimit < FCount then
    ALimit := FCount;
  if ALimit > MaxCollectionSize then
    ALimit := MaxCollectionSize;
  if ALimit <> FLimit then begin
    if ALimit = 0 then
      NewItems := nil
    else begin
      System.GetMem(NewItems, ALimit * SizeOf(Pointer));
      if (FCount > 0) and (FItems <> nil) then
        Move(FItems^, NewItems^, FCount * SizeOf(Pointer));
    end;
    if FItems <> nil then
      System.FreeMem(FItems);
    FItems := NewItems;
    FLimit := ALimit;
  end;
end;

procedure TFVCollection.Store(var S: TFVStream);
var
  I: Integer;
begin
  S.Write(FCount, SizeOf(FCount));
  S.Write(FLimit, SizeOf(FLimit));
  S.Write(FDelta, SizeOf(FDelta));
  for I := 0 to FCount - 1 do
    PutItem(S, FItems^[I]);
end;

procedure TFVCollection.Error(Code, Info: Integer);
begin
end;

function TFVCollection.Count: Integer;
begin
  Result := FCount;
end;

{ TSortedCollection }

constructor TSortedCollection.Create(ALimit, ADelta: Integer);
begin
  inherited Create(ALimit, ADelta);
  FDuplicates := False;
end;

constructor TSortedCollection.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(FDuplicates, SizeOf(FDuplicates));
end;

function TSortedCollection.Compare(Key1, Key2: Pointer): Integer;
begin
  Result := 0;
end;

function TSortedCollection.IndexOf(Item: Pointer): Integer;
var
  I: Integer;
begin
  if Search(KeyOf(Item), I) then begin
    if FDuplicates then
      while (I < FCount) and (Item <> FItems^[I]) do
        Inc(I);
    if I < FCount then begin
      Result := I;
      Exit;
    end;
  end;
  Result := -1;
end;

function TSortedCollection.KeyOf(Item: Pointer): Pointer;
begin
  Result := Item;
end;

function TSortedCollection.Search(Key: Pointer; var Index: Integer): Boolean;
var
  L, H, I, C: Integer;
begin
  Result := False;
  L := 0;
  H := FCount - 1;
  while L <= H do begin
    I := (L + H) shr 1;
    C := Compare(KeyOf(FItems^[I]), Key);
    if C < 0 then
      L := I + 1
    else begin
      H := I - 1;
      if C = 0 then begin
        Result := True;
        if not FDuplicates then
          L := I;
      end;
    end;
  end;
  Index := L;
end;

procedure TSortedCollection.Insert(Item: Pointer);
var
  I: Integer;
begin
  if not Search(KeyOf(Item), I) or FDuplicates then
    AtInsert(I, Item);
end;

procedure TSortedCollection.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(FDuplicates, SizeOf(FDuplicates));
end;

{ TStringCollection }

function TStringCollection.Compare(Key1, Key2: Pointer): Integer;
begin
  Result := CompareStr(PString(Key1)^, PString(Key2)^);
end;

procedure TStringCollection.FreeItem(Item: Pointer);
begin
  DisposeStr(PString(Item));
end;

function TStringCollection.GetItem(var S: TFVStream): Pointer;
begin
  Result := S.ReadStr;
end;

procedure TStringCollection.PutItem(var S: TFVStream; Item: Pointer);
begin
  S.WriteStr(PString(Item));
end;

end.
