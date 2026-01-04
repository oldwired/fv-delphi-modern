{*******************************************************}
{       Turbo Pascal HistList Unit                      }
{       Compatibility layer for Modern Delphi           }
{*******************************************************}

unit HistList;

{$I platform.inc}

interface

uses
  System.SysUtils, Objects;

procedure InitHistory;
procedure DoneHistory;
function HistoryCount(Id: Byte): Word;
function HistoryStr(Id: Byte; Index: Integer): ShortString;
procedure ClearHistory;
procedure HistoryAdd(Id: Byte; const Str: ShortString);
function HistoryRemove(Id: Byte; Index: Integer): Boolean;
procedure LoadHistory(var S: TFVStream);
procedure StoreHistory(var S: TFVStream);

const
  HistorySize: Integer = 64 * 1024;
  HistoryUsed: Integer = 0;

var
  HistoryBlock: Pointer;

implementation

var
  CurId: Byte;
  CurString: PShortString;

procedure StartId(Id: Byte);
begin
  CurId := Id;
  CurString := HistoryBlock;
end;

procedure DeleteString;
var
  Len: Integer;
  P, P2: PAnsiChar;
begin
  P := PAnsiChar(CurString);
  P2 := PAnsiChar(CurString);
  Len := PByte(P2)^ + 3;
  Dec(P, 2);
  Inc(P2, PByte(P2)^ + 1);
  Move(P2^, P^, NativeInt(HistoryBlock) + HistoryUsed - NativeInt(P2));
  Dec(HistoryUsed, Len);
end;

procedure AdvanceStringPtr;
var
  P: PAnsiChar;
begin
  while CurString <> nil do begin
    if NativeInt(CurString) >= NativeInt(HistoryBlock) + HistoryUsed then begin
      CurString := nil;
      Exit;
    end;
    Inc(PAnsiChar(CurString), PByte(CurString)^ + 1);
    if NativeInt(CurString) >= NativeInt(HistoryBlock) + HistoryUsed then begin
      CurString := nil;
      Exit;
    end;
    P := PAnsiChar(CurString);
    Inc(PAnsiChar(CurString), 2);
    if P^ <> #0 then
      RunError(215);
    Inc(P);
    if P^ = AnsiChar(CurId) then Exit;
  end;
end;

procedure InsertString(Id: Byte; const Str: ShortString);
var
  P, P1, P2: PAnsiChar;
begin
  while HistoryUsed + Length(Str) + 3 > HistorySize do begin
    P := PAnsiChar(HistoryBlock);
    while NativeInt(P) < NativeInt(HistoryBlock) + HistorySize do begin
      if NativeInt(P) + Length(PShortString(P + 2)^) + 6 + Length(Str) >
         NativeInt(HistoryBlock) + HistorySize then begin
        Dec(HistoryUsed, Length(PShortString(P + 2)^) + 3);
        FillChar(P^, NativeInt(HistoryBlock) + HistorySize - NativeInt(P), #0);
        Break;
      end;
      Inc(P, Length(PShortString(P + 2)^) + 3);
    end;
  end;
  P1 := PAnsiChar(HistoryBlock) + 1;
  P2 := P1 + Length(Str) + 3;
  Move(P1^, P2^, HistoryUsed - 1);
  P1^ := #0;
  Inc(P1);
  P1^ := AnsiChar(Id);
  Inc(P1);
  Move(Str[0], P1^, Length(Str) + 1);
  Inc(HistoryUsed, Length(Str) + 3);
end;

procedure InitHistory;
begin
  if HistorySize > 0 then
    GetMem(HistoryBlock, HistorySize);
  ClearHistory;
end;

procedure DoneHistory;
begin
  if HistoryBlock <> nil then begin
    FreeMem(HistoryBlock);
    HistoryBlock := nil;
  end;
end;

function HistoryCount(Id: Byte): Word;
var
  Count: Word;
begin
  StartId(Id);
  Count := 0;
  if HistoryBlock <> nil then begin
    AdvanceStringPtr;
    while CurString <> nil do begin
      Inc(Count);
      AdvanceStringPtr;
    end;
  end;
  HistoryCount := Count;
end;

function HistoryStr(Id: Byte; Index: Integer): ShortString;
var
  I: Integer;
begin
  StartId(Id);
  if HistoryBlock <> nil then begin
    for I := 0 to Index do AdvanceStringPtr;
    if CurString <> nil then
      HistoryStr := CurString^
    else
      HistoryStr := '';
  end else HistoryStr := '';
end;

procedure ClearHistory;
begin
  if HistoryBlock <> nil then begin
    PAnsiChar(HistoryBlock)^ := #0;
    HistoryUsed := 1;
  end;
end;

procedure HistoryAdd(Id: Byte; const Str: ShortString);
begin
  if Str = '' then Exit;
  if HistoryBlock = nil then Exit;
  StartId(Id);
  AdvanceStringPtr;
  while CurString <> nil do begin
    if Str = CurString^ then DeleteString;
    AdvanceStringPtr;
  end;
  InsertString(Id, Str);
end;

function HistoryRemove(Id: Byte; Index: Integer): Boolean;
var
  I: Integer;
begin
  StartId(Id);
  for I := 0 to Index do
    AdvanceStringPtr;
  if CurString <> nil then begin
    DeleteString;
    HistoryRemove := True;
  end else
    HistoryRemove := False;
end;

procedure LoadHistory(var S: TFVStream);
var
  Size: Integer;
begin
  S.Read(Size, SizeOf(Size));
  if HistoryBlock <> nil then begin
    if Size <= HistorySize then begin
      S.Read(HistoryBlock^, Size);
      HistoryUsed := Size;
    end else S.Seek(S.GetPos + Size);
  end else S.Seek(S.GetPos + Size);
end;

procedure StoreHistory(var S: TFVStream);
var
  Size: Integer;
begin
  if HistoryBlock = nil then Size := 0
  else Size := HistoryUsed;
  S.Write(Size, SizeOf(Size));
  if Size > 0 then S.Write(HistoryBlock^, Size);
end;

end.
