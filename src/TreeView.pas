{*******************************************************}
{       Free Vision TreeView Widget                     }
{       Modern class-based tree control                 }
{*******************************************************}

unit TreeView;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  FVCommon, Drivers, Views, FVConsts, FVBoxChars;

const
  cmTreeSelect = 720;
  cmTreeCheck  = 721;

type
  TTreeNode = class;
  TTreeView = class;

  TTreeNode = class
  private
    FText: string;
    FChildren: TObjectList<TTreeNode>;
    FExpanded: Boolean;
    FCheckable: Boolean;
    FChecked: Boolean;
    FIcon: string;
    FData: Pointer;
    FParent: TTreeNode;
    FHasChildrenHint: Boolean;
  public
    constructor Create(const AText: string);
    destructor Destroy; override;
    function Level: Integer;
    function IsLeaf: Boolean;
    function AddChild(const AText: string): TTreeNode;
    property Text: string read FText write FText;
    property Children: TObjectList<TTreeNode> read FChildren;
    property Expanded: Boolean read FExpanded write FExpanded;
    property Checkable: Boolean read FCheckable write FCheckable;
    property Checked: Boolean read FChecked write FChecked;
    property Icon: string read FIcon write FIcon;
    property Data: Pointer read FData write FData;
    property Parent: TTreeNode read FParent;
    property HasChildrenHint: Boolean read FHasChildrenHint write FHasChildrenHint;
  end;

  TTreeGetChildrenEvent = reference to procedure(Sender: TObject; Node: TTreeNode);

  TTreeView = class(TScroller)
  private
    FRoot: TTreeNode;
    FFocused: Integer;
    FCheckboxes: Boolean;
    FOnGetChildren: TTreeGetChildrenEvent;
    FFlatList: TList<TTreeNode>;
    FFlatDirty: Boolean;
    procedure RebuildFlat;
    procedure BuildFlatRecursive(Node: TTreeNode);
    function FlatCount: Integer;
    function NodeAtIndex(I: Integer): TTreeNode;
    procedure ToggleExpand(Node: TTreeNode);
    procedure ToggleCheck(Node: TTreeNode);
    procedure SetFocused(Value: Integer);
    procedure FocusNode(Node: TTreeNode);
    function IsLastChild(Node: TTreeNode): Boolean;
  public
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar); reintroduce; virtual;
    destructor Destroy; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    function AddNode(AParent: TTreeNode; const AText: string): TTreeNode;
    procedure DeleteNode(Node: TTreeNode);
    procedure ExpandAll;
    procedure CollapseAll;
    procedure ExpandAllRecursive(Node: TTreeNode);
    procedure CollapseAllRecursive(Node: TTreeNode);
    function FocusedNode: TTreeNode;
    procedure InvalidateFlat;
    property Root: TTreeNode read FRoot;
    property Checkboxes: Boolean read FCheckboxes write FCheckboxes;
    property OnGetChildren: TTreeGetChildrenEvent read FOnGetChildren write FOnGetChildren;
    property Focused: Integer read FFocused write SetFocused;
  end;

implementation

{ TTreeNode }

constructor TTreeNode.Create(const AText: string);
begin
  inherited Create;
  FText := AText;
  FChildren := TObjectList<TTreeNode>.Create(True);
  FExpanded := False;
  FCheckable := False;
  FChecked := False;
  FIcon := '';
  FData := nil;
  FParent := nil;
  FHasChildrenHint := False;
end;

destructor TTreeNode.Destroy;
begin
  FChildren.Free;
  inherited;
end;

function TTreeNode.Level: Integer;
var
  P: TTreeNode;
begin
  Result := -1;
  P := Self;
  while P <> nil do begin
    Inc(Result);
    P := P.Parent;
  end;
  Dec(Result); { Root is level -1, top-level children are level 0 }
end;

function TTreeNode.IsLeaf: Boolean;
begin
  Result := (FChildren.Count = 0) and not FHasChildrenHint;
end;

function TTreeNode.AddChild(const AText: string): TTreeNode;
begin
  Result := TTreeNode.Create(AText);
  Result.FParent := Self;
  FChildren.Add(Result);
end;

{ TTreeView }

constructor TTreeView.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar);
begin
  inherited Create(Bounds, AHScrollBar, AVScrollBar);
  FRoot := TTreeNode.Create('');
  FRoot.FExpanded := True;
  FFlatList := TList<TTreeNode>.Create;
  FFlatDirty := True;
  FFocused := 0;
  FCheckboxes := False;
  GrowMode := gfGrowHiX or gfGrowHiY;
  Options := Options or ofSelectable or ofFirstClick;
end;

destructor TTreeView.Destroy;
begin
  FFlatList.Free;
  FRoot.Free;
  inherited;
end;

procedure TTreeView.RebuildFlat;
begin
  if not FFlatDirty then Exit;
  FFlatList.Clear;
  BuildFlatRecursive(FRoot);
  FFlatDirty := False;
  SetLimit(Size.X, FFlatList.Count);
end;

procedure TTreeView.BuildFlatRecursive(Node: TTreeNode);
var
  I: Integer;
begin
  { Don't add the invisible root }
  if Node <> FRoot then
    FFlatList.Add(Node);
  if Node.Expanded then
    for I := 0 to Node.Children.Count - 1 do
      BuildFlatRecursive(Node.Children[I]);
end;

function TTreeView.FlatCount: Integer;
begin
  RebuildFlat;
  Result := FFlatList.Count;
end;

function TTreeView.NodeAtIndex(I: Integer): TTreeNode;
begin
  RebuildFlat;
  if (I >= 0) and (I < FFlatList.Count) then
    Result := FFlatList[I]
  else
    Result := nil;
end;

function TTreeView.IsLastChild(Node: TTreeNode): Boolean;
begin
  if (Node = nil) or (Node.Parent = nil) then
    Result := True
  else
    Result := Node.Parent.Children.Last = Node;
end;

procedure TTreeView.ToggleExpand(Node: TTreeNode);
begin
  if Node = nil then Exit;
  if Node.IsLeaf and not Node.HasChildrenHint then Exit;

  if not Node.Expanded and Node.HasChildrenHint and (Node.Children.Count = 0) then begin
    { Lazy loading }
    if Assigned(FOnGetChildren) then
      FOnGetChildren(Self, Node);
    Node.FHasChildrenHint := False;
  end;

  Node.Expanded := not Node.Expanded;
  InvalidateFlat;
  DrawView;
end;

procedure TTreeView.ToggleCheck(Node: TTreeNode);
begin
  if (Node = nil) or not Node.Checkable then Exit;
  Node.Checked := not Node.Checked;
  Message(Owner, evBroadcast, cmTreeCheck, Node);
  DrawView;
end;

procedure TTreeView.SetFocused(Value: Integer);
begin
  RebuildFlat;
  if Value < 0 then Value := 0;
  if Value >= FFlatList.Count then Value := FFlatList.Count - 1;
  if Value < 0 then Value := 0;
  if Value <> FFocused then begin
    FFocused := Value;
    { Scroll to keep focused visible }
    if FFocused < Delta.Y then
      ScrollTo(Delta.X, FFocused)
    else if FFocused >= Delta.Y + Size.Y then
      ScrollTo(Delta.X, FFocused - Size.Y + 1);
    DrawView;
  end;
end;

procedure TTreeView.FocusNode(Node: TTreeNode);
var
  I: Integer;
begin
  RebuildFlat;
  for I := 0 to FFlatList.Count - 1 do
    if FFlatList[I] = Node then begin
      SetFocused(I);
      Exit;
    end;
end;

procedure TTreeView.InvalidateFlat;
begin
  FFlatDirty := True;
end;

function TTreeView.FocusedNode: TTreeNode;
begin
  Result := NodeAtIndex(FFocused);
end;

function TTreeView.AddNode(AParent: TTreeNode; const AText: string): TTreeNode;
begin
  if AParent = nil then
    AParent := FRoot;
  Result := AParent.AddChild(AText);
  InvalidateFlat;
end;

procedure TTreeView.DeleteNode(Node: TTreeNode);
begin
  if (Node = nil) or (Node = FRoot) then Exit;
  if Node.Parent <> nil then
    Node.Parent.Children.Remove(Node);
  InvalidateFlat;
  if FFocused >= FlatCount then
    FFocused := FlatCount - 1;
  DrawView;
end;

procedure TTreeView.ExpandAll;
begin
  ExpandAllRecursive(FRoot);
  InvalidateFlat;
  DrawView;
end;

procedure TTreeView.CollapseAll;
begin
  CollapseAllRecursive(FRoot);
  InvalidateFlat;
  DrawView;
end;

procedure TTreeView.ExpandAllRecursive(Node: TTreeNode);
var
  I: Integer;
begin
  if Node.Children.Count > 0 then
    Node.Expanded := True;
  for I := 0 to Node.Children.Count - 1 do
    ExpandAllRecursive(Node.Children[I]);
end;

procedure TTreeView.CollapseAllRecursive(Node: TTreeNode);
var
  I: Integer;
begin
  Node.Expanded := False;
  for I := 0 to Node.Children.Count - 1 do
    CollapseAllRecursive(Node.Children[I]);
end;

procedure TTreeView.Draw;
var
  B: TDrawBuffer;
  Y, I, J, Indent, Col: Integer;
  Node, Ancestor: TTreeNode;
  NormColor, FocColor, IconColor: Byte;
  Prefix: string;
  S: string;
  IsLast: Boolean;
  Ancestors: array[0..31] of Boolean; { IsLastChild for each level }
begin
  NormColor := GetColor(1);
  FocColor := GetColor(2);
  IconColor := GetColor(3);
  RebuildFlat;

  for Y := 0 to Size.Y - 1 do begin
    I := Delta.Y + Y;
    DrawChar(B, 0, ' ', NormColor, Size.X);

    if (I >= 0) and (I < FFlatList.Count) then begin
      Node := FFlatList[I];
      Indent := Node.Level;

      { Build ancestor IsLastChild array for tree lines }
      Ancestor := Node;
      for J := Indent downto 0 do begin
        if J <= High(Ancestors) then
          Ancestors[J] := IsLastChild(Ancestor);
        if Ancestor.Parent <> nil then
          Ancestor := Ancestor.Parent;
      end;

      Col := 0;

      { Draw tree connector lines }
      for J := 0 to Indent - 1 do begin
        if J <= High(Ancestors) then begin
          if Ancestors[J] then
            DrawCell(B, Col, ' ', NormColor)
          else
            DrawCell(B, Col, BoxVert, NormColor);
        end;
        DrawCell(B, Col + 1, ' ', NormColor);
        Inc(Col, 2);
      end;

      { Draw expand/collapse indicator }
      if not Node.IsLeaf or Node.HasChildrenHint then begin
        if IsLastChild(Node) then
          DrawCell(B, Col, BoxBottomLeft, NormColor)
        else
          DrawCell(B, Col, BoxVertRight, NormColor);
        Inc(Col);
        if Node.Expanded then
          DrawCell(B, Col, '-', NormColor)
        else
          DrawCell(B, Col, '+', NormColor);
        Inc(Col);
      end else begin
        if IsLastChild(Node) then
          DrawCell(B, Col, BoxBottomLeft, NormColor)
        else
          DrawCell(B, Col, BoxVertRight, NormColor);
        Inc(Col);
        DrawCell(B, Col, BoxHoriz, NormColor);
        Inc(Col);
      end;

      { Draw checkbox }
      if FCheckboxes and Node.Checkable then begin
        if Node.Checked then
          S := '[x] '
        else
          S := '[ ] ';
        DrawStr(B, Col, S, NormColor);
        Inc(Col, 4);
      end;

      { Draw icon }
      if Node.Icon <> '' then begin
        DrawStr(B, Col, Node.Icon + ' ', IconColor);
        Inc(Col, Length(Node.Icon) + 1);
      end;

      { Draw text }
      if I = FFocused then
        DrawStr(B, Col, Node.Text, FocColor)
      else
        DrawStr(B, Col, Node.Text, NormColor);
    end;

    WriteLine(0, Y, Size.X, 1, B);
  end;
end;

procedure TTreeView.HandleEvent(var Event: TEvent);
var
  Node: TTreeNode;
  ClickY, Col: Integer;
  Local: TPoint;
begin
  inherited HandleEvent(Event);

  if Event.What = evKeyDown then begin
    case Event.KeyCode of
      kbUp:
        begin
          SetFocused(FFocused - 1);
          ClearEvent(Event);
        end;
      kbDown:
        begin
          SetFocused(FFocused + 1);
          ClearEvent(Event);
        end;
      kbLeft:
        begin
          Node := FocusedNode;
          if (Node <> nil) and Node.Expanded and not Node.IsLeaf then
            ToggleExpand(Node)
          else if (Node <> nil) and (Node.Parent <> nil) and (Node.Parent <> FRoot) then
            FocusNode(Node.Parent);
          ClearEvent(Event);
        end;
      kbRight:
        begin
          Node := FocusedNode;
          if Node <> nil then begin
            if not Node.Expanded and (not Node.IsLeaf or Node.HasChildrenHint) then
              ToggleExpand(Node)
            else if Node.Expanded and (Node.Children.Count > 0) then
              FocusNode(Node.Children[0]);
          end;
          ClearEvent(Event);
        end;
      kbSpaceBar:
        begin
          if FCheckboxes then begin
            ToggleCheck(FocusedNode);
            ClearEvent(Event);
          end;
        end;
      kbEnter:
        begin
          Node := FocusedNode;
          if Node <> nil then begin
            if not Node.IsLeaf or Node.HasChildrenHint then
              ToggleExpand(Node)
            else
              Message(Owner, evBroadcast, cmTreeSelect, Node);
          end;
          ClearEvent(Event);
        end;
      kbPgUp:
        begin
          SetFocused(FFocused - Size.Y + 1);
          ClearEvent(Event);
        end;
      kbPgDn:
        begin
          SetFocused(FFocused + Size.Y - 1);
          ClearEvent(Event);
        end;
      kbHome:
        begin
          SetFocused(0);
          ClearEvent(Event);
        end;
      kbEnd:
        begin
          SetFocused(FlatCount - 1);
          ClearEvent(Event);
        end;
    end;
  end
  else if Event.What = evMouseDown then begin
    MakeLocal(Event.Where, Local);
    ClickY := Local.Y + Delta.Y;
    if (ClickY >= 0) and (ClickY < FlatCount) then begin
      SetFocused(ClickY);
      Node := NodeAtIndex(ClickY);
      if Node <> nil then begin
        Col := Node.Level * 2 + 1;
        { Click on +/- indicator }
        if (Local.X = Col) and (not Node.IsLeaf or Node.HasChildrenHint) then
          ToggleExpand(Node)
        { Click on checkbox }
        else if FCheckboxes and Node.Checkable and
                (Local.X >= Col + 1) and (Local.X <= Col + 3) then
          ToggleCheck(Node);
      end;
    end;
    ClearEvent(Event);
  end;
end;

end.
