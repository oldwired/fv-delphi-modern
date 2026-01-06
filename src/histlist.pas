{*******************************************************}
{       Free Vision - History List Unit                 }
{       Modern Unicode Implementation                   }
{*******************************************************}

unit HistList;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Objects;

procedure InitHistory;
procedure DoneHistory;
function HistoryCount(Id: Byte): Word;
function HistoryStr(Id: Byte; Index: Integer): string;
procedure ClearHistory;
procedure HistoryAdd(Id: Byte; const Str: string);
function HistoryRemove(Id: Byte; Index: Integer): Boolean;
procedure LoadHistory(var S: TFVStream);
procedure StoreHistory(var S: TFVStream);

const
  MaxHistoryItems: Integer = 100;  { Max items per history ID }

implementation

var
  { Dictionary mapping history ID to string list }
  HistoryLists: TObjectDictionary<Byte, TStringList>;

procedure InitHistory;
begin
  if HistoryLists = nil then
    HistoryLists := TObjectDictionary<Byte, TStringList>.Create([doOwnsValues]);
end;

procedure DoneHistory;
begin
  FreeAndNil(HistoryLists);
end;

function GetHistoryList(Id: Byte): TStringList;
begin
  if HistoryLists = nil then
    InitHistory;
  if not HistoryLists.TryGetValue(Id, Result) then begin
    Result := TStringList.Create;
    Result.Duplicates := dupIgnore;
    HistoryLists.Add(Id, Result);
  end;
end;

function HistoryCount(Id: Byte): Word;
var
  List: TStringList;
begin
  if HistoryLists = nil then begin
    Result := 0;
    Exit;
  end;
  if HistoryLists.TryGetValue(Id, List) then
    Result := List.Count
  else
    Result := 0;
end;

function HistoryStr(Id: Byte; Index: Integer): string;
var
  List: TStringList;
begin
  Result := '';
  if HistoryLists = nil then Exit;
  if HistoryLists.TryGetValue(Id, List) then begin
    if (Index >= 0) and (Index < List.Count) then
      Result := List[Index];
  end;
end;

procedure ClearHistory;
begin
  if HistoryLists <> nil then
    HistoryLists.Clear;
end;

procedure HistoryAdd(Id: Byte; const Str: string);
var
  List: TStringList;
  ExistingIndex: Integer;
begin
  if Str = '' then Exit;

  List := GetHistoryList(Id);

  { Remove existing duplicate (case-insensitive) }
  ExistingIndex := List.IndexOf(Str);
  if ExistingIndex >= 0 then
    List.Delete(ExistingIndex);

  { Insert at beginning (most recent first) }
  List.Insert(0, Str);

  { Trim to max size }
  while List.Count > MaxHistoryItems do
    List.Delete(List.Count - 1);
end;

function HistoryRemove(Id: Byte; Index: Integer): Boolean;
var
  List: TStringList;
begin
  Result := False;
  if HistoryLists = nil then Exit;
  if HistoryLists.TryGetValue(Id, List) then begin
    if (Index >= 0) and (Index < List.Count) then begin
      List.Delete(Index);
      Result := True;
    end;
  end;
end;

procedure LoadHistory(var S: TFVStream);
var
  Count: Integer;
begin
  { Legacy binary format - just skip the data }
  { New format would use JSON }
  S.Read(Count, SizeOf(Count));
  if Count > 0 then
    S.Seek(S.GetPos + Count);
end;

procedure StoreHistory(var S: TFVStream);
var
  Zero: Integer;
begin
  { Legacy binary format - write empty }
  { New format would use JSON }
  Zero := 0;
  S.Write(Zero, SizeOf(Zero));
end;

initialization
  HistoryLists := nil;

finalization
  DoneHistory;

end.
