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

{$I platform.inc}

interface

uses
  Objects, FVCommon, FVConsts, Drivers, Views;

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
    Name: Objects.PString;
    Items: PTabItem;
    DefItem: TView;
    ShortCut: AnsiChar;
  end;

  TTab = class(TGroup)
  private
    FTabDefs: PTabDef;
    FActiveDef: SmallInt;
    FDefCount: Word;
    FInDraw: Boolean;
    function FirstSelectable: TView;
    function LastSelectable: TView;
  public
    constructor Create(var Bounds: TRect; ATabDef: PTabDef); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    function AtTab(Index: SmallInt): PTabDef; virtual;
    procedure SelectTab(Index: SmallInt); virtual;
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
  end;

function NewTabItem(AView: TView; ANext: PTabItem): PTabItem;
procedure DisposeTabItem(P: PTabItem);
function NewTabDef(const AName: ShortString; ADefItem: TView; AItems: PTabItem; ANext: PTabDef): PTabDef;
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
      with Cur^ do
      begin
        S.WriteStr(Cur^.Name);
        S.Write(Cur^.ShortCut, SizeOf(Cur^.ShortCut));
        DoStoreTabItems(Items, DefItem);
      end;
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
  PrevDef, ToRemove: PTabDef;
  Item, NextItem: PTabItem;
  I: SmallInt;
begin
  if (Index < 0) or (Index >= FDefCount) or (FDefCount <= 1) then
    Exit;

  { If removing active tab, switch to another first }
  if Index = FActiveDef then begin
    if Index > 0 then
      SelectTab(Index - 1)
    else
      SelectTab(Index + 1);
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
    Objects.DisposeStr(ToRemove^.Name);
    Dispose(ToRemove);
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
        Len := CStrLen(AtTab(I)^.Name^);
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
          if FActiveDef > 0 then
            Index := Pred(FActiveDef)
          else
            Index := Pred(FDefCount);
          ClearEvent(Event);
        end;
      kbCtrlPgDn:
        begin
          if FActiveDef < Pred(FDefCount) then
            Index := Succ(FActiveDef)
          else
            Index := 0;
          ClearEvent(Event);
        end;
    else
      for I := 0 to FDefCount - 1 do
      begin
        if (AtTab(I)^.ShortCut <> #0) and
           (UpCase(GetAltChar(Event.KeyCode)) = AtTab(I)^.ShortCut) then
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
end;

function TTab.GetPalette: PPalette;
begin
  Result := nil;
end;

procedure TTab.Draw;
const
  { Box drawing characters }
  CharTopRight    = #191;  { ┐ }
  CharHoriz       = #196;  { ─ }
  CharTopLeft     = #218;  { ┌ }
  CharVert        = #179;  { │ }
  CharBottomLeft  = #192;  { └ }
  CharBottomRight = #217;  { ┘ }
  CharVertRight   = #195;  { ├ }
  CharVertLeft    = #180;  { ┤ }
  CharHorizUp     = #193;  { ┴ }
  CharHorizDown   = #194;  { ┬ }
var
  B: TDrawBuffer;
  I: SmallInt;
  C1, C2, C3, C: Word;
  HeaderLen: SmallInt;
  X, X2: SmallInt;
  Name: Objects.PString;
  ActiveKPos: SmallInt;
  ActiveVPos: SmallInt;
  FC: AnsiChar;
  TabDef: PTabDef;

  procedure SWriteBuf(AX, AY, W, H: SmallInt; var Buf);
  var
    J: SmallInt;
  begin
    if AY + H > Size.Y then H := Size.Y - AY;
    if AX + W > Size.X then W := Size.X - AX;
    if W <= 0 then Exit;
    if H <= 0 then Exit;
    if Buffer = nil then
      WriteBuf(AX, AY, W, H, Buf)
    else
      for J := 1 to H do
        Move(Buf, Buffer^[AX + (AY + J - 1) * Size.X], W * 2);
  end;

  procedure ClearBuf;
  begin
    MoveChar(B, ' ', C1, Size.X);
  end;

begin
  if FInDraw then
    Exit;
  FInDraw := True;

  C1 := GetColor(1);
  C2 := (GetColor(7) and $F0 or $08) + GetColor(9) * 256;
  C3 := GetColor(8) + GetColor(8) * 256;

  { Calculate the size of the headers }
  HeaderLen := 0;
  for I := 0 to FDefCount - 1 do
    HeaderLen := HeaderLen + CStrLen(AtTab(I)^.Name^) + 3;
  Dec(HeaderLen);
  if HeaderLen > Size.X - 2 then
    HeaderLen := Size.X - 2;

  { Row 1 - Tab names }
  ClearBuf;
  MoveChar(B[0], CharVert, C1, 1);
  MoveChar(B[HeaderLen + 1], CharVert, C1, 1);
  X := 1;
  ActiveKPos := 0;
  ActiveVPos := 0;
  for I := 0 to FDefCount - 1 do
  begin
    TabDef := AtTab(I);
    if TabDef = nil then
      Continue;
    Name := TabDef^.Name;
    if Name = nil then
      Continue;
    X2 := CStrLen(Name^);
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
    MoveCStr(B[X], ' ' + Name^ + ' ', C);
    X := X + X2 + 3;
    MoveChar(B[X - 1], CharVert, C1, 1);
  end;
  SWriteBuf(0, 1, Size.X, 1, B);

  { Row 0 - Top border }
  ClearBuf;
  MoveChar(B[0], CharTopLeft, C1, 1);
  X := 1;
  for I := 0 to FDefCount - 1 do
  begin
    if I < FActiveDef then
      FC := CharTopLeft
    else
      FC := CharTopRight;
    X2 := CStrLen(AtTab(I)^.Name^) + 2;
    MoveChar(B[X + X2], FC, C1, 1);
    if I = FDefCount - 1 then
      X2 := X2 + 1;
    if X2 > 0 then
      MoveChar(B[X], CharHoriz, C1, X2);
    X := X + X2 + 1;
  end;
  MoveChar(B[HeaderLen + 1], CharTopRight, C1, 1);
  MoveChar(B[ActiveKPos], CharTopLeft, C1, 1);
  MoveChar(B[ActiveVPos], CharTopRight, C1, 1);
  SWriteBuf(0, 0, Size.X, 1, B);

  { Row 2 - Line below tabs }
  MoveChar(B[1], CharHoriz, C1, HeaderLen);
  if Size.X - HeaderLen - 3 > 0 then
    MoveChar(B[HeaderLen + 2], CharHoriz, C1, Size.X - HeaderLen - 3);
  MoveChar(B[HeaderLen + 1], CharHorizUp, C1, 1);
  MoveChar(B[ActiveKPos], CharBottomRight, C1, 1);
  if ActiveDef = 0 then
    MoveChar(B[0], CharVert, C1, 1)
  else
    MoveChar(B[0], CharVertRight, C1, 1);
  if ActiveVPos - ActiveKPos - 1 > 0 then
    MoveChar(B[ActiveKPos + 1], ' ', C1, ActiveVPos - ActiveKPos - 1);
  MoveChar(B[ActiveVPos], CharBottomLeft, C1, 1);
  if HeaderLen + 1 < Size.X - 1 then
    MoveChar(B[Size.X - 1], CharTopRight, C1, 1)
  else if FActiveDef = FDefCount - 1 then
    MoveChar(B[Size.X - 1], CharVert, C1, 1)
  else
    MoveChar(B[Size.X - 1], CharVertLeft, C1, 1);
  SWriteBuf(0, 2, Size.X, 1, B);

  { Remaining rows - draw only the side borders, not the content area.
    Children will fill the content area when Redraw is called. }
  for I := 3 to Size.Y - 2 do begin
    MoveChar(B, CharVert, C1, 1);  { Left border only }
    SWriteBuf(0, I, 1, 1, B);
    MoveChar(B, CharVert, C1, 1);  { Right border only }
    SWriteBuf(Size.X - 1, I, 1, 1, B);
  end;

  { Bottom row }
  MoveChar(B[0], CharBottomLeft, C1, 1);
  if Size.X - 2 > 0 then
    MoveChar(B[1], CharHoriz, C1, Size.X - 2);
  MoveChar(B[Size.X - 1], CharBottomRight, C1, 1);
  SWriteBuf(0, Size.Y - 1, Size.X, 1, B);

  { Draw child views }
  if Buffer <> nil then begin
    Lock;
    WriteBuf(0, 0, Size.X, Size.Y, Buffer^);
    Redraw;
    UnLock;
  end else begin
    Redraw;
  end;

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
  PI, NextPI: PTabItem;
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

  { Now dispose all tab definitions and their views }
  P := FTabDefs;
  while P <> nil do
  begin
    NextP := P^.Next;
    { Dispose items and their views }
    PI := P^.Items;
    while PI <> nil do
    begin
      NextPI := PI^.Next;
      FreeAndNil(PI^.View);
      Dispose(PI);
      PI := NextPI;
    end;
    Objects.DisposeStr(P^.Name);
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

function NewTabDef(const AName: ShortString; ADefItem: TView; AItems: PTabItem; ANext: PTabDef): PTabDef;
var
  P: PTabDef;
  X: Byte;
begin
  New(P);
  P^.Next := ANext;
  P^.Name := Objects.NewStr(AName);
  P^.Items := AItems;
  X := Pos('~', AName);
  if (X <> 0) and (X < Length(AName)) then
    P^.ShortCut := UpCase(AName[X + 1])
  else
    P^.ShortCut := #0;
  P^.DefItem := ADefItem;
  Result := P;
end;

procedure DisposeTabDef(P: PTabDef);
var
  PI, X: PTabItem;
begin
  Objects.DisposeStr(P^.Name);
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
