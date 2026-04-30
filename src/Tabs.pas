{*******************************************************}
{       Free Vision - Tabbed Group Unit                }
{       Ported to Modern Delphi                        }
{*******************************************************}

{
  TTab provides a tabbed group container for dialogs.
  Each tab can contain different views that are shown/hidden
  when the user switches between tabs.
}

unit Tabs;

interface

uses
  Objects, FVCommon, FVConsts, Drivers, Views, FVBoxChars;

type
  PTabItem = ^TTabItem;
  TTabItem = record
    Next: PTabItem;
    View: TView;
    Dis: Boolean;
  end;

  PTabDef = ^TTabDef;
  TTabDef = record
    Next: PTabDef;
    Name: string;
    Items: PTabItem;
    DefItem: TView;
    ShortCut: Char;
    Visible: Boolean;
  end;

  TTab = class(TGroup)
  private
    FTabDefs: PTabDef;
    FActiveDef: SmallInt;
    FDefCount: Word;
    FInDraw: Boolean;
    FContentBorder: Boolean;
    FFillBackground: Boolean;
    FSkipRedrawInDraw: Boolean;
    function FirstSelectable: TView;
    function LastSelectable: TView;
    function NextVisibleTab(FromIndex: SmallInt): SmallInt;
    function PrevVisibleTab(FromIndex: SmallInt): SmallInt;
    function NearestVisibleTab(FromIndex: SmallInt): SmallInt;
  public
    function IsTabVisible(Index: SmallInt): Boolean;
    constructor Create(var Bounds: TRect; ATabDef: PTabDef); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    function AtTab(Index: SmallInt): PTabDef; virtual;
    procedure SelectTab(Index: SmallInt); virtual;
    procedure SetTabVisible(Index: SmallInt; AVisible: Boolean); virtual;
    { Delphi port extensions - not in original FPC Free Vision }
    procedure AddTab(ATabDef: PTabDef); virtual;
    procedure RemoveTab(Index: SmallInt); virtual;
    { End extensions }
    procedure Store(var S: TFVStream);
    function TabCount: SmallInt;
    function Valid(Command: Word): Boolean; override;
    procedure ChangeBounds(var Bounds: TRect); override;
    procedure HandleEvent(var Event: TEvent); override;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    function DataSize: Word; override;
    procedure SetData(var Rec); override;
    procedure GetData(var Rec); override;
    procedure SetState(AState: Word; Enable: Boolean); override;
    destructor Destroy; override;
    property TabDefs: PTabDef read FTabDefs write FTabDefs;
    property ActiveDef: SmallInt read FActiveDef write FActiveDef;
    property DefCount: Word read FDefCount write FDefCount;
    property ContentBorder: Boolean read FContentBorder write FContentBorder;
    property FillBackground: Boolean read FFillBackground write FFillBackground;
    property SkipRedrawInDraw: Boolean read FSkipRedrawInDraw write FSkipRedrawInDraw;
  end;

function NewTabItem(AView: TView; ANext: PTabItem): PTabItem;
procedure DisposeTabItem(P: PTabItem);
function NewTabDef(const AName: string; ADefItem: TView; AItems: PTabItem; ANext: PTabDef): PTabDef;
procedure DisposeTabDef(P: PTabDef);

procedure RegisterTab;

const
  RTab: TStreamRec = (
    ObjType: idTab;
    VmtLink: nil;
    Load: @TTab.Load;
    Store: @TTab.Store
  );

implementation

uses
  System.SysUtils, Dialogs;

{ TTab }

constructor TTab.Create(var Bounds: TRect; ATabDef: PTabDef);
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick or ofPreProcess or ofPostProcess;
  GrowMode := gfGrowHiX + gfGrowHiY + gfGrowRel;
  FContentBorder := True;
  FFillBackground := True;
  FTabDefs := ATabDef;
  FActiveDef := -1;
  SelectTab(0);
  ReDraw;
end;

constructor TTab.Load(var S: TFVStream);

  function DoLoadTabItems(var XDefItem: TView; ActItem: LongInt): PTabItem;
  var
    Count: LongInt;
    Cur, First: PTabItem;
    Last: ^PTabItem;
  begin
    Cur := nil;
    Last := @First;
    S.Read(Count, SizeOf(Count));
    while Count > 0 do
    begin
      New(Cur);
      Last^ := Cur;
      if Cur <> nil then
      begin
        Last := @Cur^.Next;
        S.Read(Cur^.Dis, SizeOf(Cur^.Dis));
        Cur^.View := TView(S.Get);
        if ActItem = 0 then
          XDefItem := Cur^.View;
      end;
      Dec(Count);
      Dec(ActItem);
    end;
    Last^ := nil;
    Result := First;
  end;

  function DoLoadTabDefs: PTabDef;
  var
    Count: LongInt;
    Cur, First: PTabDef;
    Last: ^PTabDef;
    ActItem: LongInt;
  begin
    Last := @First;
    Count := FDefCount;
    while Count > 0 do
    begin
      New(Cur);
      Last^ := Cur;
      if Cur <> nil then
      begin
        Last := @Cur^.Next;
        Cur^.Name := S.ReadStr;
        S.Read(Cur^.ShortCut, SizeOf(Cur^.ShortCut));
        Cur^.Visible := True;  { Visible not yet serialized - default to True }
        S.Read(ActItem, SizeOf(ActItem));
        Cur^.Items := DoLoadTabItems(Cur^.DefItem, ActItem);
      end;
      Dec(Count);
    end;
    Last^ := nil;
    Result := First;
  end;

begin
  inherited Load(S);
  FFillBackground := True;
  FContentBorder := True;
  S.Read(FDefCount, SizeOf(FDefCount));
  S.Read(FActiveDef, SizeOf(FActiveDef));
  FTabDefs := DoLoadTabDefs;
end;

procedure TTab.Store(var S: TFVStream);

  procedure DoStoreTabItems(Cur: PTabItem; XDefItem: TView);
  var
    Count: LongInt;
    T: PTabItem;
    ActItem: LongInt;
  begin
    Count := 0;
    ActItem := 0;
    T := Cur;
    while T <> nil do
    begin
      if T^.View = XDefItem then
        ActItem := Count;
      Inc(Count);
      T := T^.Next;
    end;
    S.Write(ActItem, SizeOf(ActItem));
    S.Write(Count, SizeOf(Count));
    while Cur <> nil do
    begin
      S.Write(Cur^.Dis, SizeOf(Cur^.Dis));
      S.Put(Cur^.View);
      Cur := Cur^.Next;
    end;
  end;

  procedure DoStoreTabDefs(Cur: PTabDef);
  begin
    while Cur <> nil do
    begin
      S.WriteStr(Cur^.Name);
      S.Write(Cur^.ShortCut, SizeOf(Cur^.ShortCut));
      { Visible not yet serialized - deferred to serialization overhaul }
      DoStoreTabItems(Cur^.Items, Cur^.DefItem);
      Cur := Cur^.Next;
    end;
  end;

begin
  inherited Store(S);
  S.Write(FDefCount, SizeOf(FDefCount));
  S.Write(FActiveDef, SizeOf(FActiveDef));
  DoStoreTabDefs(FTabDefs);
end;

function TTab.TabCount: SmallInt;
var
  I: SmallInt;
  P: PTabDef;
begin
  I := 0;
  P := FTabDefs;
  while P <> nil do
  begin
    Inc(I);
    P := P^.Next;
  end;
  Result := I;
end;

function TTab.AtTab(Index: SmallInt): PTabDef;
var
  I: SmallInt;
  P: PTabDef;
begin
  I := 0;
  P := FTabDefs;
  while I < Index do
  begin
    if P = nil then
    begin
      Result := nil;
      Exit;
    end;
    P := P^.Next;
    Inc(I);
  end;
  Result := P;
end;

procedure TTab.SelectTab(Index: SmallInt);
var
  P: PTabItem;
  V: TView;
  TabDef: PTabDef;
begin
  { If requested tab is hidden, find nearest visible }
  if (Index >= 0) and (Index < FDefCount) and not IsTabVisible(Index) then
  begin
    Index := NearestVisibleTab(Index);
    if Index = -1 then
      Exit;
  end;
  if FActiveDef <> Index then
  begin
    if Owner <> nil then Owner.Lock;
    Lock;
    { Update DefCount }
    if FTabDefs <> nil then
    begin
      FDefCount := 1;
      while AtTab(FDefCount - 1)^.Next <> nil do
        Inc(FDefCount);
    end
    else
      FDefCount := 0;
    { Remove old tab's views }
    if FActiveDef <> -1 then
    begin
      TabDef := AtTab(FActiveDef);
      if TabDef <> nil then
      begin
        P := TabDef^.Items;
        while P <> nil do
        begin
          if P^.View <> nil then
            Delete(P^.View);
          P := P^.Next;
        end;
      end;
    end;
    { Insert new tab's views }
    FActiveDef := Index;
    TabDef := AtTab(FActiveDef);
    if TabDef <> nil then
    begin
      P := TabDef^.Items;
      while P <> nil do
      begin
        if P^.View <> nil then
          Insert(P^.View);
        P := P^.Next;
      end;
      { Select default item }
      V := TabDef^.DefItem;
      if V <> nil then
      begin
        V.Select;
        { If we're focused, also give focus to the default item }
        if GetState(sfFocused) then
          V.SetState(sfFocused, True);
      end;
    end;
    ReDraw;
    UnLock;
    if Owner <> nil then Owner.UnLock;
    DrawView;
  end;
end;

{ AddTab - Delphi port extension, not in original FPC Free Vision }
procedure TTab.AddTab(ATabDef: PTabDef);
var
  P: PTabDef;
begin
  if ATabDef = nil then Exit;

  { Link new tab at end of list }
  ATabDef^.Next := nil;
  if FTabDefs = nil then
    FTabDefs := ATabDef
  else begin
    P := FTabDefs;
    while P^.Next <> nil do
      P := P^.Next;
    P^.Next := ATabDef;
  end;

  Inc(FDefCount);
  DrawView;
end;

{ RemoveTab - Delphi port extension, not in original FPC Free Vision }
procedure TTab.RemoveTab(Index: SmallInt);
var
  PrevDef, ToRemove, TabDef: PTabDef;
  Item, NextItem: PTabItem;
  I: SmallInt;
begin
  if (Index < 0) or (Index >= FDefCount) or (FDefCount <= 1) then
    Exit;

  { If removing active tab, switch to another first.
    Mark the tab as hidden so SelectTab won't resolve back to it. }
  if Index = FActiveDef then begin
    AtTab(Index)^.Visible := False;
    if Index > 0 then
      SelectTab(Index - 1)
    else
      SelectTab(Index + 1);
    { If no visible fallback was found, manually remove the views }
    if FActiveDef = Index then
    begin
      TabDef := AtTab(Index);
      if TabDef <> nil then
      begin
        Item := TabDef^.Items;
        while Item <> nil do
        begin
          if Item^.View <> nil then
            Delete(Item^.View);
          Item := Item^.Next;
        end;
      end;
      FActiveDef := -1;
    end;
  end;

  { Find and unlink the tab def }
  ToRemove := nil;
  if Index = 0 then begin
    ToRemove := FTabDefs;
    FTabDefs := FTabDefs^.Next;
  end else begin
    PrevDef := FTabDefs;
    for I := 0 to Index - 2 do
      PrevDef := PrevDef^.Next;
    ToRemove := PrevDef^.Next;
    PrevDef^.Next := ToRemove^.Next;
  end;

  { Adjust ActiveDef if needed }
  if FActiveDef > Index then
    Dec(FActiveDef);

  Dec(FDefCount);

  { Dispose the removed tab's views and structures }
  if ToRemove <> nil then begin
    Item := ToRemove^.Items;
    while Item <> nil do begin
      NextItem := Item^.Next;
      FreeAndNil(Item^.View);
      Dispose(Item);
      Item := NextItem;
    end;
    { Name is now a managed string - Dispose will finalize it }
    Dispose(ToRemove);
  end;

  DrawView;
end;

function TTab.NextVisibleTab(FromIndex: SmallInt): SmallInt;
var
  I: SmallInt;
  P: PTabDef;
begin
  for I := FromIndex + 1 to FDefCount - 1 do
  begin
    P := AtTab(I);
    if (P <> nil) and P^.Visible then
    begin
      Result := I;
      Exit;
    end;
  end;
  Result := -1;
end;

function TTab.PrevVisibleTab(FromIndex: SmallInt): SmallInt;
var
  I: SmallInt;
  P: PTabDef;
begin
  for I := FromIndex - 1 downto 0 do
  begin
    P := AtTab(I);
    if (P <> nil) and P^.Visible then
    begin
      Result := I;
      Exit;
    end;
  end;
  Result := -1;
end;

function TTab.NearestVisibleTab(FromIndex: SmallInt): SmallInt;
var
  Fwd, Bwd: SmallInt;
begin
  Fwd := NextVisibleTab(FromIndex);
  Bwd := PrevVisibleTab(FromIndex);
  if (Fwd = -1) and (Bwd = -1) then
    Result := -1
  else if Fwd = -1 then
    Result := Bwd
  else if Bwd = -1 then
    Result := Fwd
  else if (FromIndex - Bwd) <= (Fwd - FromIndex) then
    Result := Bwd  { prefer earlier tab when equidistant }
  else
    Result := Fwd;
end;

function TTab.IsTabVisible(Index: SmallInt): Boolean;
var
  P: PTabDef;
begin
  P := AtTab(Index);
  Result := (P <> nil) and P^.Visible;
end;

procedure TTab.SetTabVisible(Index: SmallInt; AVisible: Boolean);
var
  TabDef: PTabDef;
  NewActive: SmallInt;
  P: PTabItem;
begin
  if (Index < 0) or (Index >= FDefCount) then Exit;
  TabDef := AtTab(Index);
  if TabDef = nil then Exit;
  if TabDef^.Visible = AVisible then Exit;

  TabDef^.Visible := AVisible;

  if (not AVisible) and (Index = FActiveDef) then
  begin
    { Active tab is being hidden - find nearest visible tab }
    NewActive := NearestVisibleTab(Index);
    if NewActive <> -1 then
      SelectTab(NewActive)
    else
    begin
      { No visible tabs remain - remove current views }
      if Owner <> nil then Owner.Lock;
      Lock;
      TabDef := AtTab(FActiveDef);
      if TabDef <> nil then
      begin
        P := TabDef^.Items;
        while P <> nil do
        begin
          if P^.View <> nil then
            Delete(P^.View);
          P := P^.Next;
        end;
      end;
      FActiveDef := -1;
      ReDraw;
      UnLock;
      if Owner <> nil then Owner.UnLock;
    end;
  end
  else if AVisible and (FActiveDef = -1) then
  begin
    { No tab was active (last visible was hidden earlier and the views were
      torn down). Showing this one again must re-select it, otherwise the
      tab control stays empty until the user clicks a tab manually. }
    SelectTab(Index);
  end;

  DrawView;
end;

procedure TTab.ChangeBounds(var Bounds: TRect);
var
  D: TPoint;
  P: PTabItem;
  I: SmallInt;
  R: TRect;
begin
  D.X := Bounds.B.X - Bounds.A.X - Size.X;
  D.Y := Bounds.B.Y - Bounds.A.Y - Size.Y;
  inherited ChangeBounds(Bounds);
  for I := 0 to TabCount - 1 do
    if I <> FActiveDef then
    begin
      P := AtTab(I)^.Items;
      while P <> nil do
      begin
        if (P^.View <> nil) and (P^.View.Owner <> nil) then
        begin
          P^.View.CalcBounds(R, D);
          P^.View.ChangeBounds(R);
        end;
        P := P^.Next;
      end;
    end;
end;

function TTab.FirstSelectable: TView;
var
  FV: TView;
begin
  FV := First;
  while (FV <> nil) and ((FV.Options and ofSelectable) = 0) and (FV <> Last) do
    FV := FV.Next;
  if FV <> nil then
    if (FV.Options and ofSelectable) = 0 then
      FV := nil;
  Result := FV;
end;

function TTab.LastSelectable: TView;
var
  LV: TView;
begin
  LV := Last;
  while (LV <> nil) and ((LV.Options and ofSelectable) = 0) and (LV <> First) do
    LV := LV.Prev;
  if LV <> nil then
    if (LV.Options and ofSelectable) = 0 then
      LV := nil;
  Result := LV;
end;

procedure TTab.HandleEvent(var Event: TEvent);
var
  Index: SmallInt;
  I: SmallInt;
  X: SmallInt;
  Len: Byte;
  P: TPoint;
  V: TView;
  CallOrig: Boolean;
  LastV: TView;
  FirstV: TView;
  TabDef: PTabDef;
begin
  if (Event.What and evMouseDown) <> 0 then
  begin
    MakeLocal(Event.Where, P);
    if P.Y < 3 then
    begin
      Index := -1;
      X := 1;
      for I := 0 to FDefCount - 1 do
      begin
        TabDef := AtTab(I);
        if (TabDef = nil) or (not TabDef^.Visible) then
          Continue;
        Len := CStrLen(TabDef^.Name);
        if (P.X >= X) and (P.X <= X + Len + 1) then
          Index := I;
        X := X + Len + 3;
      end;
      if Index <> -1 then
        SelectTab(Index);
    end;
  end;
  if Event.What = evKeyDown then
  begin
    Index := -1;
    case Event.KeyCode of
      kbTab, kbShiftTab:
        if GetState(sfSelected) then
        begin
          if Current <> nil then
          begin
            LastV := LastSelectable;
            FirstV := FirstSelectable;
            if ((Current = LastV) or (Current = TLabel(LastV).Link)) and
               (Event.KeyCode = kbShiftTab) then
            begin
              if Owner <> nil then Owner.SelectNext(True);
            end
            else if ((Current = FirstV) or (Current = TLabel(FirstV).Link)) and
                    (Event.KeyCode = kbTab) then
            begin
              Lock;
              if Owner <> nil then Owner.SelectNext(False);
              UnLock;
            end
            else
              SelectNext(Event.KeyCode = kbShiftTab);
            ClearEvent(Event);
          end;
        end;
      kbCtrlPgUp:
        begin
          Index := PrevVisibleTab(FActiveDef);
          if Index = -1 then
            Index := PrevVisibleTab(FDefCount);  { wrap from end }
          if Index <> -1 then
            ClearEvent(Event);
        end;
      kbCtrlPgDn:
        begin
          Index := NextVisibleTab(FActiveDef);
          if Index = -1 then
            Index := NextVisibleTab(-1);  { wrap from beginning }
          if Index <> -1 then
            ClearEvent(Event);
        end;
    else
      for I := 0 to FDefCount - 1 do
      begin
        TabDef := AtTab(I);
        if (TabDef <> nil) and TabDef^.Visible and
           (TabDef^.ShortCut <> #0) and
           (UpCase(GetAltChar(Event.KeyCode)) = TabDef^.ShortCut) then
        begin
          Index := I;
          ClearEvent(Event);
          Break;
        end;
      end;
    end;
    if Index <> -1 then
    begin
      Select;
      SelectTab(Index);
      V := AtTab(FActiveDef)^.DefItem;
      if V <> nil then V.Focus;
    end;
  end;
  CallOrig := True;
  if Event.What = evKeyDown then
  begin
    if ((Owner <> nil) and (Owner.Phase = phPostProcess) and
        (GetAltChar(Event.KeyCode) <> #0)) or GetState(sfFocused) then
      { process }
    else
      CallOrig := False;
  end;
  if CallOrig then
    inherited HandleEvent(Event);

  { Handle Left/Right arrow for tab switching after children had a chance to consume }
  if (Event.What = evKeyDown) and GetState(sfFocused) then
  begin
    Index := -1;
    case Event.KeyCode of
      kbLeft:
        begin
          Index := PrevVisibleTab(FActiveDef);
          if Index = -1 then
            Index := PrevVisibleTab(FDefCount);
        end;
      kbRight:
        begin
          Index := NextVisibleTab(FActiveDef);
          if Index = -1 then
            Index := NextVisibleTab(-1);
        end;
    end;
    if Index <> -1 then
    begin
      Select;
      SelectTab(Index);
      V := AtTab(FActiveDef)^.DefItem;
      if V <> nil then V.Focus;
      ClearEvent(Event);
    end;
  end;
end;

function TTab.GetPalette: PPalette;
begin
  Result := nil;
end;

procedure TTab.Draw;
const
  { Box drawing characters - using Unicode from FVBoxChars }
  CharTopRight    = BoxTopRight;     { ┐ }
  CharHoriz       = BoxHoriz;        { ─ }
  CharTopLeft     = BoxTopLeft;      { ┌ }
  CharVert        = BoxVert;         { │ }
  CharBottomLeft  = BoxBottomLeft;   { └ }
  CharBottomRight = BoxBottomRight;  { ┘ }
  CharVertRight   = BoxVertRight;    { ├ }
  CharVertLeft    = BoxVertLeft;     { ┤ }
  CharHorizUp     = BoxHorizUp;      { ┴ }
  CharHorizDown   = BoxHorizDown;    { ┬ }
var
  B: TDrawBuffer;
  I: SmallInt;
  C1, C2, C3, C: Word;
  HeaderLen: SmallInt;
  X, X2: SmallInt;
  Name: string;
  ActiveKPos: SmallInt;
  ActiveVPos: SmallInt;
  FC: Char;
  TabDef: PTabDef;
  FirstVisibleIdx: SmallInt;
  LastVisibleIdx: SmallInt;
  IsLastVisible: Boolean;

  procedure SWriteBuf(AX, AY, W, H: SmallInt; var Buf);
  begin
    if AY + H > Size.Y then H := Size.Y - AY;
    if AX + W > Size.X then W := Size.X - AX;
    if W <= 0 then Exit;
    if H <= 0 then Exit;
    WriteBuf(AX, AY, W, H, Buf);
  end;

  procedure ClearBuf;
  begin
    DrawChar(B, 0, ' ', C1, Size.X);
  end;

begin
  if FInDraw then
    Exit;
  FInDraw := True;

  C1 := GetColor(1);
  C2 := (GetColor(7) and $F0 or $08) + GetColor(9) * 256;
  C3 := GetColor(8) + GetColor(8) * 256;

  { Determine first and last visible tab indices }
  FirstVisibleIdx := -1;
  LastVisibleIdx := -1;
  for I := 0 to FDefCount - 1 do
  begin
    TabDef := AtTab(I);
    if (TabDef <> nil) and TabDef^.Visible then
    begin
      if FirstVisibleIdx = -1 then
        FirstVisibleIdx := I;
      LastVisibleIdx := I;
    end;
  end;

  { Calculate the size of the headers (visible tabs only) }
  HeaderLen := 0;
  for I := 0 to FDefCount - 1 do
  begin
    TabDef := AtTab(I);
    if (TabDef <> nil) and TabDef^.Visible then
      HeaderLen := HeaderLen + CStrLen(TabDef^.Name) + 3;
  end;
  Dec(HeaderLen);
  if HeaderLen > Size.X - 2 then
    HeaderLen := Size.X - 2;

  { Row 1 - Tab names }
  ClearBuf;
  DrawChar(B, 0, CharVert, C1, 1);
  DrawChar(B, HeaderLen + 1, CharVert, C1, 1);
  X := 1;
  ActiveKPos := 0;
  ActiveVPos := 0;
  for I := 0 to FDefCount - 1 do
  begin
    TabDef := AtTab(I);
    if (TabDef = nil) or (not TabDef^.Visible) then
      Continue;
    Name := TabDef^.Name;
    if Name = '' then
      Continue;
    X2 := CStrLen(Name);
    if I = FActiveDef then
    begin
      ActiveKPos := X - 1;
      ActiveVPos := X + X2 + 2;
      if GetState(sfFocused) then
        C := C3
      else
        C := C2;
    end
    else
      C := C2;
    DrawCStr(B, X, ' ' + Name + ' ', C);
    X := X + X2 + 3;
    DrawChar(B, X - 1, CharVert, C1, 1);
  end;
  SWriteBuf(0, 1, Size.X, 1, B);

  { Row 0 - Top border }
  ClearBuf;
  DrawChar(B, 0, CharTopLeft, C1, 1);
  X := 1;
  for I := 0 to FDefCount - 1 do
  begin
    TabDef := AtTab(I);
    if (TabDef = nil) or (not TabDef^.Visible) then
      Continue;
    if I < FActiveDef then
      FC := CharTopLeft
    else
      FC := CharTopRight;
    X2 := CStrLen(TabDef^.Name) + 2;
    IsLastVisible := (I = LastVisibleIdx);
    DrawChar(B, X + X2, FC, C1, 1);
    if IsLastVisible then
      X2 := X2 + 1;
    if X2 > 0 then
      DrawChar(B, X, CharHoriz, C1, X2);
    X := X + X2 + 1;
  end;
  DrawChar(B, HeaderLen + 1, CharTopRight, C1, 1);
  DrawChar(B, ActiveKPos, CharTopLeft, C1, 1);
  DrawChar(B, ActiveVPos, CharTopRight, C1, 1);
  SWriteBuf(0, 0, Size.X, 1, B);

  { Row 2 - Line below tabs }
  DrawChar(B, 1, CharHoriz, C1, HeaderLen);
  if Size.X - HeaderLen - 3 > 0 then
    DrawChar(B, HeaderLen + 2, CharHoriz, C1, Size.X - HeaderLen - 3);
  DrawChar(B, HeaderLen + 1, CharHorizUp, C1, 1);
  DrawChar(B, ActiveKPos, CharBottomRight, C1, 1);
  if FActiveDef = FirstVisibleIdx then
    DrawChar(B, 0, CharVert, C1, 1)
  else
    DrawChar(B, 0, CharVertRight, C1, 1);
  if ActiveVPos - ActiveKPos - 1 > 0 then
    DrawChar(B, ActiveKPos + 1, ' ', C1, ActiveVPos - ActiveKPos - 1);
  DrawChar(B, ActiveVPos, CharBottomLeft, C1, 1);
  if HeaderLen + 1 < Size.X - 1 then
    DrawChar(B, Size.X - 1, CharTopRight, C1, 1)
  else if FActiveDef = LastVisibleIdx then
    DrawChar(B, Size.X - 1, CharVert, C1, 1)
  else
    DrawChar(B, Size.X - 1, CharVertLeft, C1, 1);
  SWriteBuf(0, 2, Size.X, 1, B);

  { Content area rows }
  if FContentBorder then
    for I := 3 to Size.Y - 2 do begin
      if FFillBackground then begin
        ClearBuf;
        DrawChar(B, 0, CharVert, C1, 1);
        DrawChar(B, Size.X - 1, CharVert, C1, 1);
        SWriteBuf(0, I, Size.X, 1, B);
      end else begin
        DrawChar(B, 0, CharVert, C1, 1);
        SWriteBuf(0, I, 1, 1, B);
        DrawChar(B, 0, CharVert, C1, 1);
        SWriteBuf(Size.X - 1, I, 1, 1, B);
      end;
    end
  else if FFillBackground then
    for I := 3 to Size.Y - 2 do begin
      ClearBuf;
      SWriteBuf(0, I, Size.X, 1, B);
    end;

  { Bottom row }
  if FContentBorder then
  begin
    DrawChar(B, 0, CharBottomLeft, C1, 1);
    if Size.X - 2 > 0 then
      DrawChar(B, 1, CharHoriz, C1, Size.X - 2);
    DrawChar(B, Size.X - 1, CharBottomRight, C1, 1);
    SWriteBuf(0, Size.Y - 1, Size.X, 1, B);
  end;

  { Draw child views (unless suppressed — parent handles ReDraw explicitly) }
  if not FSkipRedrawInDraw then
    Redraw;

  FInDraw := False;
end;

function TTab.Valid(Command: Word): Boolean;
var
  PT: PTabDef;
  PI: PTabItem;
  OK: Boolean;
begin
  OK := True;
  PT := FTabDefs;
  while (PT <> nil) and OK do
  begin
    PI := PT^.Items;
    while (PI <> nil) and OK do
    begin
      if PI^.View <> nil then
        OK := OK and PI^.View.Valid(Command);
      PI := PI^.Next;
    end;
    PT := PT^.Next;
  end;
  Result := OK;
end;

procedure TTab.SetData(var Rec);
type
  TBytes = array[0..65534] of Byte;
var
  I: Word;
  PT: PTabDef;
  PI: PTabItem;
begin
  I := 0;
  PT := FTabDefs;
  while PT <> nil do
  begin
    PI := PT^.Items;
    while PI <> nil do
    begin
      if PI^.View <> nil then
      begin
        PI^.View.SetData(TBytes(Rec)[I]);
        Inc(I, PI^.View.DataSize);
      end;
      PI := PI^.Next;
    end;
    PT := PT^.Next;
  end;
end;

function TTab.DataSize: Word;
var
  I: Word;
  PT: PTabDef;
  PI: PTabItem;
begin
  I := 0;
  PT := FTabDefs;
  while PT <> nil do
  begin
    PI := PT^.Items;
    while PI <> nil do
    begin
      if PI^.View <> nil then
        Inc(I, PI^.View.DataSize);
      PI := PI^.Next;
    end;
    PT := PT^.Next;
  end;
  Result := I;
end;

procedure TTab.GetData(var Rec);
type
  TBytes = array[0..65534] of Byte;
var
  I: Word;
  PT: PTabDef;
  PI: PTabItem;
begin
  I := 0;
  PT := FTabDefs;
  while PT <> nil do
  begin
    PI := PT^.Items;
    while PI <> nil do
    begin
      if PI^.View <> nil then
      begin
        PI^.View.GetData(TBytes(Rec)[I]);
        Inc(I, PI^.View.DataSize);
      end;
      PI := PI^.Next;
    end;
    PT := PT^.Next;
  end;
end;

procedure TTab.SetState(AState: Word; Enable: Boolean);
var
  LastV: TView;
begin
  inherited SetState(AState, Enable);

  { Select first item when sfSelected changes - matches FPC }
  if (AState and sfSelected) <> 0 then begin
    LastV := LastSelectable;
    if LastV <> nil then
      LastV.Select;
  end;
end;

destructor TTab.Destroy;
var
  P, NextP: PTabDef;
  PI, NextPI, QI: PTabItem;
  QD: PTabDef;
  V: TView;
begin
  { Remove all views from current tab from the group (don't dispose - we'll do that below) }
  { We need to manually iterate since nested procedures can't be used as callbacks in Delphi }
  while Last <> nil do
  begin
    V := Last;
    Delete(V);
  end;

  inherited Destroy;

  { Now dispose all tab definitions and their views.
    A view may appear in multiple tab item lists (shared controls),
    so after freeing a view, nil out all other references to it. }
  P := FTabDefs;
  while P <> nil do
  begin
    NextP := P^.Next;
    { Dispose items and their views }
    PI := P^.Items;
    while PI <> nil do
    begin
      NextPI := PI^.Next;
      if PI^.View <> nil then
      begin
        V := PI^.View;
        { Nil out all other references to this view across all tab items }
        QD := P;
        while QD <> nil do
        begin
          if QD = P then
            QI := NextPI  { skip already-disposed items in current tab }
          else
            QI := QD^.Items;
          while QI <> nil do
          begin
            if QI^.View = V then
              QI^.View := nil;
            QI := QI^.Next;
          end;
          QD := QD^.Next;
        end;
        V.Free;
      end;
      Dispose(PI);
      PI := NextPI;
    end;
    { Name is now a managed string - Dispose will finalize it }
    Dispose(P);
    P := NextP;
  end;
end;

{ Helper functions }

function NewTabItem(AView: TView; ANext: PTabItem): PTabItem;
var
  P: PTabItem;
begin
  New(P);
  FillChar(P^, SizeOf(P^), 0);
  P^.Next := ANext;
  P^.View := AView;
  Result := P;
end;

procedure DisposeTabItem(P: PTabItem);
begin
  if P <> nil then
  begin
    FreeAndNil(P^.View);
    Dispose(P);
  end;
end;

function NewTabDef(const AName: string; ADefItem: TView; AItems: PTabItem; ANext: PTabDef): PTabDef;
var
  P: PTabDef;
  X: Integer;
begin
  New(P);
  P^.Next := ANext;
  P^.Name := AName;
  P^.Items := AItems;
  X := Pos('~', AName);
  if (X <> 0) and (X < Length(AName)) then
    P^.ShortCut := UpCase(AName[X + 1])
  else
    P^.ShortCut := #0;
  P^.DefItem := ADefItem;
  P^.Visible := True;
  Result := P;
end;

procedure DisposeTabDef(P: PTabDef);
var
  PI, X: PTabItem;
begin
  { Name is now a managed string - Dispose will finalize it }
  PI := P^.Items;
  while PI <> nil do
  begin
    X := PI^.Next;
    DisposeTabItem(PI);
    PI := X;
  end;
  Dispose(P);
end;

procedure RegisterTab;
begin
  RegisterType(RTab);
end;

end.
