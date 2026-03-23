{*******************************************************}
{       Free Vision PopupMenu Widget                    }
{       Reusable filtered popup list                    }
{*******************************************************}

unit PopupMenu;

{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  FVCommon, Drivers, Views, Dialogs, FVConsts, FVBoxChars, FVScreen;

const
  cmPopupSelect = 722;

  CPopupViewer = #6#6#7#6#6;
  CPopupWindow = #19#19#21#24#25#19#20;

type
  TPopupListViewer = class(TListViewer)
  private
    FAllItems: TStringList;
    FFiltered: TList<Integer>;
    FFilter: string;
  public
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
      AItems: TStringList); reintroduce; virtual;
    destructor Destroy; override;
    function GetPalette: PPalette; override;
    function GetText(Item: Integer; MaxLen: Integer): string; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure ApplyFilter(const AFilter: string);
    function SelectedOriginalIndex: Integer;
    function SelectedText: string;
  end;

  TPopupMenu = class(TWindow)
  private
    FViewer: TPopupListViewer;
    FAllItems: TStringList;
  public
    constructor Create(AItems: TStringList; AnchorX, AnchorY: Integer;
      AMaxVisible: Integer = 8); reintroduce; virtual;
    function GetSelection: string;
    function GetSelectionIndex: Integer;
    function GetPalette: PPalette; override;
    procedure Filter(const AText: string);
    property Viewer: TPopupListViewer read FViewer;
  end;

implementation

{ TPopupListViewer }

constructor TPopupListViewer.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
  AItems: TStringList);
var
  I: Integer;
begin
  inherited Create(Bounds, 1, AHScrollBar, AVScrollBar);
  FAllItems := AItems;
  FFiltered := TList<Integer>.Create;
  FFilter := '';
  { Initially show all items }
  if FAllItems <> nil then begin
    for I := 0 to FAllItems.Count - 1 do
      FFiltered.Add(I);
    SetRange(FFiltered.Count);
  end;
end;

destructor TPopupListViewer.Destroy;
begin
  FFiltered.Free;
  inherited;
end;

function TPopupListViewer.GetPalette: PPalette;
const
  P: string[Length(CPopupViewer)] = CPopupViewer;
begin
  GetPalette := PPalette(@P);
end;

function TPopupListViewer.GetText(Item: Integer; MaxLen: Integer): string;
var
  Idx: Integer;
begin
  if (Item >= 0) and (Item < FFiltered.Count) then begin
    Idx := FFiltered[Item];
    if (FAllItems <> nil) and (Idx >= 0) and (Idx < FAllItems.Count) then begin
      Result := Copy(FAllItems[Idx], 1, MaxLen);
      Exit;
    end;
  end;
  Result := '';
end;

procedure TPopupListViewer.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) then begin
    EndModal(cmOk);
    ClearEvent(Event);
  end else if ((Event.What = evKeyDown) and (Event.KeyCode = kbEsc)) or
              ((Event.What = evCommand) and (Event.Command = cmCancel)) then begin
    EndModal(cmCancel);
    ClearEvent(Event);
  end else
    inherited HandleEvent(Event);
end;

procedure TPopupListViewer.ApplyFilter(const AFilter: string);
var
  I: Integer;
  LFilter: string;
begin
  FFilter := AFilter;
  LFilter := LowerCase(AFilter);
  FFiltered.Clear;
  if FAllItems <> nil then begin
    for I := 0 to FAllItems.Count - 1 do begin
      if (LFilter = '') or (Pos(LFilter, LowerCase(FAllItems[I])) > 0) then
        FFiltered.Add(I);
    end;
  end;
  SetRange(FFiltered.Count);
  if Focused >= FFiltered.Count then
    FocusItem(0);
  DrawView;
end;

function TPopupListViewer.SelectedOriginalIndex: Integer;
begin
  if (Focused >= 0) and (Focused < FFiltered.Count) then
    Result := FFiltered[Focused]
  else
    Result := -1;
end;

function TPopupListViewer.SelectedText: string;
var
  Idx: Integer;
begin
  Idx := SelectedOriginalIndex;
  if (Idx >= 0) and (FAllItems <> nil) and (Idx < FAllItems.Count) then
    Result := FAllItems[Idx]
  else
    Result := '';
end;

{ TPopupMenu }

constructor TPopupMenu.Create(AItems: TStringList; AnchorX, AnchorY: Integer;
  AMaxVisible: Integer);
var
  R: TRect;
  W, H, MaxW, I: Integer;
begin
  FAllItems := AItems;

  { Calculate size }
  MaxW := 20;
  if FAllItems <> nil then begin
    for I := 0 to FAllItems.Count - 1 do
      if Length(FAllItems[I]) + 2 > MaxW then
        MaxW := Length(FAllItems[I]) + 2;
    H := FAllItems.Count;
  end else
    H := 0;
  if H > AMaxVisible then H := AMaxVisible;
  if H < 1 then H := 1;
  W := MaxW + 2;  { frame }
  Inc(H, 2);      { frame }

  { Position near anchor }
  R.Assign(AnchorX, AnchorY, AnchorX + W, AnchorY + H);

  { Clip to screen }
  if R.B.X > ScreenWidth then begin
    R.Move(ScreenWidth - R.B.X, 0);
    if R.A.X < 0 then R.A.X := 0;
  end;
  if R.B.Y > ScreenHeight then begin
    { Flip above anchor }
    R.Move(0, -(H + 1));
    if R.A.Y < 0 then R.A.Y := 0;
  end;

  inherited Create(R, '', wnNoNumber);
  Flags := wfClose;

  GetExtent(R);
  R.Grow(-1, -1);
  FViewer := TPopupListViewer.Create(R,
    nil,
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    FAllItems);
  if FViewer <> nil then Insert(FViewer);
end;

function TPopupMenu.GetSelection: string;
begin
  if FViewer <> nil then
    Result := FViewer.SelectedText
  else
    Result := '';
end;

function TPopupMenu.GetSelectionIndex: Integer;
begin
  if FViewer <> nil then
    Result := FViewer.SelectedOriginalIndex
  else
    Result := -1;
end;

function TPopupMenu.GetPalette: PPalette;
const
  P: string[Length(CPopupWindow)] = CPopupWindow;
begin
  GetPalette := PPalette(@P);
end;

procedure TPopupMenu.Filter(const AText: string);
begin
  if FViewer <> nil then
    FViewer.ApplyFilter(AText);
end;

end.
