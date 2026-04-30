{*********************************************************}
{                                                         }
{       Free Vision - Multi-Select Check-List Box         }
{                                                         }
{       Inspired by VSoft.AnsiConsole Prompts.MultiSelect }
{       (https://github.com/VSoftTechnologies/            }
{        VSoft.AnsiConsole) - MIT licensed                }
{       Copyright (c) 2026 Vincent Parrett                }
{                                                         }
{       Adapted for Free Vision under MIT.                }
{                                                         }
{       Descends from TStringListBox; adds per-row        }
{       Boolean state with [ ] / [x] prefix. Space        }
{       toggles the focused row; Enter still defaults     }
{       to "accept" via the parent dialog.                }
{                                                         }
{*********************************************************}

unit CheckListBox;

{$R-}

interface

uses
  System.Classes,
  System.Generics.Collections,
  Objects, Drivers, Views, Dialogs;

type
  TCheckChangeProc = procedure(Sender: TObject; Index: Integer) of object;

  TCheckListBox = class(TStringListBox)
  private
    FChecked:       TList<Boolean>;
    FOnCheckChange: TCheckChangeProc;
    function GetCheckedCount: Integer;
    procedure SyncCheckedSize;
  protected
    procedure DoCheckChange(Index: Integer); virtual;
  public
    constructor Create(var Bounds: TRect; ANumCols: Word; AScrollBar: TScrollBar); override;
    destructor Destroy; override;

    function GetText(Item: Integer; MaxLen: Integer): string; override;
    procedure NewList(AStrings: TStringList); override;
    procedure HandleEvent(var Event: TEvent); override;

    function IsChecked(Index: Integer): Boolean;
    procedure SetChecked(Index: Integer; Value: Boolean);
    procedure ToggleChecked(Index: Integer);
    procedure CheckAll(Value: Boolean);

    { Builds a string list of the checked items' captions. Caller owns. }
    function CheckedItems: TStringList;

    property Checked[Index: Integer]: Boolean read IsChecked write SetChecked;
    property CheckedCount: Integer read GetCheckedCount;
    property OnCheckChange: TCheckChangeProc read FOnCheckChange write FOnCheckChange;
  end;

implementation

uses
  FVConsts;

constructor TCheckListBox.Create(var Bounds: TRect; ANumCols: Word; AScrollBar: TScrollBar);
begin
  inherited Create(Bounds, ANumCols, AScrollBar);
  FChecked := TList<Boolean>.Create;
end;

destructor TCheckListBox.Destroy;
begin
  FChecked.Free;
  inherited Destroy;
end;

procedure TCheckListBox.SyncCheckedSize;
var
  Target: Integer;
begin
  if Strings = nil then
    Target := 0
  else
    Target := Strings.Count;
  while FChecked.Count < Target do
    FChecked.Add(False);
  while FChecked.Count > Target do
    FChecked.Delete(FChecked.Count - 1);
end;

procedure TCheckListBox.NewList(AStrings: TStringList);
begin
  inherited NewList(AStrings);
  FChecked.Clear;
  SyncCheckedSize;
  DrawView;
end;

function TCheckListBox.GetText(Item: Integer; MaxLen: Integer): string;
var
  Inner: string;
  Marker: string;
  Prefix: Integer;
begin
  if (Strings = nil) or (Item < 0) or (Item >= Strings.Count) then
    Exit('');
  if (Item < FChecked.Count) and FChecked[Item] then
    Marker := '[x] '
  else
    Marker := '[ ] ';
  Prefix := Length(Marker);
  if MaxLen <= Prefix then
    Inner := ''
  else
    Inner := Copy(Strings[Item], 1, MaxLen - Prefix);
  Result := Marker + Inner;
end;

procedure TCheckListBox.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evKeyDown) and (Event.CharCode = ' ') then
  begin
    SyncCheckedSize;
    ToggleChecked(Focused);
    ClearEvent(Event);
    Exit;
  end;
  inherited HandleEvent(Event);
end;

function TCheckListBox.IsChecked(Index: Integer): Boolean;
begin
  SyncCheckedSize;
  if (Index < 0) or (Index >= FChecked.Count) then
    Result := False
  else
    Result := FChecked[Index];
end;

procedure TCheckListBox.SetChecked(Index: Integer; Value: Boolean);
begin
  SyncCheckedSize;
  if (Index < 0) or (Index >= FChecked.Count) then Exit;
  if FChecked[Index] = Value then Exit;
  FChecked[Index] := Value;
  DoCheckChange(Index);
  DrawView;
end;

procedure TCheckListBox.ToggleChecked(Index: Integer);
begin
  SyncCheckedSize;
  if (Index < 0) or (Index >= FChecked.Count) then Exit;
  FChecked[Index] := not FChecked[Index];
  DoCheckChange(Index);
  DrawView;
end;

procedure TCheckListBox.CheckAll(Value: Boolean);
var
  I: Integer;
begin
  SyncCheckedSize;
  for I := 0 to FChecked.Count - 1 do
    FChecked[I] := Value;
  DrawView;
end;

function TCheckListBox.GetCheckedCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  SyncCheckedSize;
  for I := 0 to FChecked.Count - 1 do
    if FChecked[I] then Inc(Result);
end;

function TCheckListBox.CheckedItems: TStringList;
var
  I: Integer;
begin
  Result := TStringList.Create;
  SyncCheckedSize;
  if Strings = nil then Exit;
  for I := 0 to FChecked.Count - 1 do
    if FChecked[I] and (I < Strings.Count) then
      Result.Add(Strings[I]);
end;

procedure TCheckListBox.DoCheckChange(Index: Integer);
begin
  if Assigned(FOnCheckChange) then
    FOnCheckChange(Self, Index);
end;

end.
