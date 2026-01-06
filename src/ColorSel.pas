{*******************************************************}
{       Free Vision - Color Selection Unit             }
{       Ported to Modern Delphi                        }
{*******************************************************}

{
  Color selection dialogs for customizing application palettes.
  Based on original Turbo Vision design.

  Ported to Delphi: January 2026
}

unit ColorSel;

interface

uses
  FVCommon, FVConsts, Objects, Drivers, Views, Dialogs, FVBoxChars;

const
  { Color selector palettes }
  CColorSelector = #6#6#6#6#6#6;
  CMonoSelector = #6#6#6#6#6#6;
  CColorDisplay = #6#6;
  { List palettes: position 1=icon, 2=normal, 3=focused, 4=selected, 5=divider }
  CColorGroupList = #6#6#9#8#6;  { Use distinct colors for focused/selected }
  CColorItemList = #6#6#9#8#6;
  CColorDialog = #32#33#34#35#36#37#38#39#40#41#42#43#44#45#46#47 +
                 #48#49#50#51#52#53#54#55#56#57#58#59#60#61#62#63;

type
  { Forward declarations }
  PColorItem = ^TColorItem;
  PColorGroup = ^TColorGroup;
  TColorSelector = class;
  TMonoSelector = class;
  TColorDisplay = class;
  TColorGroupList = class;
  TColorItemList = class;
  TColorDialog = class;

  { TColorItem - Record for individual color settings }
  TColorItem = record
    Name: string;
    Index: Byte;
    Next: PColorItem;
  end;

  { TColorGroup - Record for groups of color settings }
  TColorGroup = record
    Name: string;
    Index: Byte;
    Items: PColorItem;
    Next: PColorGroup;
  end;

  { TColorSelector - 16-color selector grid }
  TColorSelector = class(TView)
  private
    FColor: Byte;
    FSelType: Byte;  { 0 = foreground, 1 = background }
    function GetPalette: PPalette; override;
  public
    constructor Create(var Bounds: TRect; ASelType: Byte); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Store(var S: TFVStream);
    procedure ColorChanged; virtual;
    property Color: Byte read FColor write FColor;
    property SelType: Byte read FSelType write FSelType;
  end;

  { TMonoSelector - Monochrome attribute selector }
  TMonoSelector = class(TView)
  private
    FColor: Byte;
    FSelType: Byte;
    function GetPalette: PPalette; override;
  public
    constructor Create(var Bounds: TRect; ASelType: Byte); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Store(var S: TFVStream);
    procedure ColorChanged; virtual;
    property Color: Byte read FColor write FColor;
    property SelType: Byte read FSelType write FSelType;
  end;

  { TColorDisplay - Shows current color selection }
  TColorDisplay = class(TView)
  private
    FColor: PByte;
    FText: string;
    function GetPalette: PPalette; override;
  public
    constructor Create(var Bounds: TRect; const AText: string); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetColor(AColor: PByte); virtual;
    procedure Store(var S: TFVStream);
    property Color: PByte read FColor write FColor;
    property Text: string read FText write FText;
  end;

  { TColorGroupList - List of color groups }
  TColorGroupList = class(TListViewer)
  private
    FGroups: PColorGroup;
    function GetPalette: PPalette; override;
    function GetGroup(Item: Integer): PColorGroup;
    function GetNumGroups: Integer;
  public
    constructor Create(var Bounds: TRect; AScrollBar: TScrollBar; AGroups: PColorGroup); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    destructor Destroy; override;
    procedure FocusItem(Item: Integer); override;
    function GetText(Item: Integer; MaxLen: Integer): string; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Store(var S: TFVStream);
    property Groups: PColorGroup read FGroups write FGroups;
  end;

  { TColorItemList - List of items in selected group }
  TColorItemList = class(TListViewer)
  private
    FItems: PColorItem;
    function GetPalette: PPalette; override;
    function GetNumItems: Integer;
  public
    constructor Create(var Bounds: TRect; AScrollBar: TScrollBar); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    procedure FocusItem(Item: Integer); override;
    function GetText(Item: Integer; MaxLen: Integer): string; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetGroupItems(AItems: PColorItem);
    procedure Store(var S: TFVStream);
    function GetItem(Index: Integer): PColorItem;
    property Items: PColorItem read FItems write FItems;
  end;

  { TColorDialog - Main color selection dialog }
  TColorDialog = class(TDialog)
  private
    FGroupList: TColorGroupList;
    FItemList: TColorItemList;
    FForeSel: TColorSelector;
    FBackSel: TColorSelector;
    FDisplay: TColorDisplay;
    FPal: TPalette;
    FGroups: PColorGroup;
    function GetPalette: PPalette; override;
    procedure SetupItems(AGroup: PColorGroup);
  public
    constructor Create(APalette: TPalette; AGroups: PColorGroup); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    destructor Destroy; override;
    function DataSize: Word; override;
    procedure GetData(var Rec); override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetData(var Rec); override;
    procedure Store(var S: TFVStream);
    property GroupList: TColorGroupList read FGroupList write FGroupList;
    property ItemList: TColorItemList read FItemList write FItemList;
    property ForeSel: TColorSelector read FForeSel write FForeSel;
    property BackSel: TColorSelector read FBackSel write FBackSel;
    property Display: TColorDisplay read FDisplay write FDisplay;
    property Pal: TPalette read FPal write FPal;
    property Groups: PColorGroup read FGroups write FGroups;
  end;

{ Helper functions to create color items and groups }
function ColorItem(const Name: string; Index: Byte; Next: PColorItem): PColorItem;
function ColorGroup(const Name: string; Items: PColorItem; Next: PColorGroup): PColorGroup;

{ Dispose functions }
procedure DisposeColorItem(Item: PColorItem);
procedure DisposeColorGroup(Group: PColorGroup);

{ Standard color item builders }
function DesktopColorItems(Next: PColorItem): PColorItem;
function MenuColorItems(Next: PColorItem): PColorItem;
function DialogColorItems(Palette: Word; Next: PColorItem): PColorItem;
function WindowColorItems(Palette: Word; Next: PColorItem): PColorItem;

{ Registration }
procedure RegisterColorSel;

{ Selector types }
const
  csForeground = 0;
  csBackground = 1;

implementation

uses
  System.SysUtils;

{****************************************************************************}
{ Helper Functions                                                           }
{****************************************************************************}

function ColorItem(const Name: string; Index: Byte; Next: PColorItem): PColorItem;
var
  Item: PColorItem;
begin
  New(Item);
  Item^.Name := Name;
  Item^.Index := Index;
  Item^.Next := Next;
  Result := Item;
end;

function ColorGroup(const Name: string; Items: PColorItem; Next: PColorGroup): PColorGroup;
var
  Group: PColorGroup;
begin
  New(Group);
  Group^.Name := Name;
  Group^.Items := Items;
  Group^.Next := Next;
  Group^.Index := 0;
  Result := Group;
end;

procedure DisposeColorItem(Item: PColorItem);
var
  Next: PColorItem;
begin
  while Item <> nil do
  begin
    Next := Item^.Next;
    { Name is now a managed string }
    Dispose(Item);
    Item := Next;
  end;
end;

procedure DisposeColorGroup(Group: PColorGroup);
var
  Next: PColorGroup;
begin
  while Group <> nil do
  begin
    Next := Group^.Next;
    { Name is now a managed string }
    DisposeColorItem(Group^.Items);
    Dispose(Group);
    Group := Next;
  end;
end;

{ Standard color items for Desktop }
function DesktopColorItems(Next: PColorItem): PColorItem;
begin
  Result :=
    ColorItem('Color', 1, Next);
end;

{ Standard color items for Menus }
function MenuColorItems(Next: PColorItem): PColorItem;
begin
  Result :=
    ColorItem('Normal', 2,
    ColorItem('Disabled', 3,
    ColorItem('Shortcut', 4,
    ColorItem('Selected', 5,
    ColorItem('Selected disabled', 6,
    ColorItem('Shortcut selected', 7,
    Next))))));
end;

{ Standard color items for Dialogs }
function DialogColorItems(Palette: Word; Next: PColorItem): PColorItem;
var
  Offset: Byte;
begin
  Offset := Palette * 32;
  Result :=
    ColorItem('Frame/background', 32 + Offset,
    ColorItem('Frame icons', 33 + Offset,
    ColorItem('Scroll bar page', 34 + Offset,
    ColorItem('Scroll bar icons', 35 + Offset,
    ColorItem('Static text', 36 + Offset,
    ColorItem('Label normal', 37 + Offset,
    ColorItem('Label highlight', 38 + Offset,
    ColorItem('Label shortcut', 39 + Offset,
    ColorItem('Button normal', 40 + Offset,
    ColorItem('Button default', 41 + Offset,
    ColorItem('Button selected', 42 + Offset,
    ColorItem('Button disabled', 43 + Offset,
    ColorItem('Button shortcut', 44 + Offset,
    ColorItem('Button shadow', 45 + Offset,
    ColorItem('Cluster normal', 46 + Offset,
    ColorItem('Cluster selected', 47 + Offset,
    ColorItem('Cluster shortcut', 48 + Offset,
    ColorItem('Input normal', 49 + Offset,
    ColorItem('Input selected', 50 + Offset,
    ColorItem('Input arrow', 51 + Offset,
    ColorItem('History button', 52 + Offset,
    ColorItem('History sides', 53 + Offset,
    ColorItem('History bar page', 54 + Offset,
    ColorItem('History bar icons', 55 + Offset,
    ColorItem('List normal', 56 + Offset,
    ColorItem('List focused', 57 + Offset,
    ColorItem('List selected', 58 + Offset,
    ColorItem('List divider', 59 + Offset,
    ColorItem('Information pane', 60 + Offset,
    Next)))))))))))))))))))))))))))));
end;

{ Standard color items for Windows }
function WindowColorItems(Palette: Word; Next: PColorItem): PColorItem;
var
  Offset: Byte;
begin
  Offset := Palette * 8;
  Result :=
    ColorItem('Frame passive', 8 + Offset,
    ColorItem('Frame active', 9 + Offset,
    ColorItem('Frame icons', 10 + Offset,
    ColorItem('Scroll bar page', 11 + Offset,
    ColorItem('Scroll bar icons', 12 + Offset,
    ColorItem('Scroller normal', 13 + Offset,
    ColorItem('Scroller selected', 14 + Offset,
    ColorItem('Reserved', 15 + Offset,
    Next))))))));
end;

{****************************************************************************}
{ TColorSelector Class                                                       }
{****************************************************************************}

constructor TColorSelector.Create(var Bounds: TRect; ASelType: Byte);
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := EventMask or evBroadcast;
  FSelType := ASelType;
  FColor := 0;
end;

constructor TColorSelector.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(FColor, SizeOf(FColor));
  S.Read(FSelType, SizeOf(FSelType));
end;

procedure TColorSelector.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(FColor, SizeOf(FColor));
  S.Write(FSelType, SizeOf(FSelType));
end;

function TColorSelector.GetPalette: PPalette;
const
  P: ShortString = CColorSelector;
begin
  Result := PPalette(@P);
end;

procedure TColorSelector.Draw;
const
  Icon: Char = BlockFull;  { Full block character }
var
  B: TDrawBuffer;
  C, I, J: Integer;
  MarkerAttr: Byte;
begin
  DrawChar(B, 0, ' ', $70, Size.X);
  for I := 0 to Size.Y - 1 do
  begin
    if I < 4 then
    begin
      for J := 0 to 3 do
      begin
        C := I * 4 + J;
        { Each color cell is 3 characters wide }
        DrawChar(B, J * 3, Icon, Byte(C), 3);
        if C = FColor then
        begin
          { Mark selected color with bullet - use DrawChar for proper Unicode }
          if C = 0 then
            MarkerAttr := $70  { Visible marker on black }
          else
            MarkerAttr := Byte(C);
          DrawChar(B, J * 3 + 1, BulletPt, MarkerAttr, 1);
        end;
      end;
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TColorSelector.HandleEvent(var Event: TEvent);
const
  Width = 4;
var
  Mouse: TPoint;
  OldColor: Byte;
  MaxCol: Byte;
begin
  inherited HandleEvent(Event);

  OldColor := FColor;
  if FSelType = csBackground then
    MaxCol := 7
  else
    MaxCol := 15;

  case Event.What of
    evMouseDown:
    begin
      repeat
        if MouseInView(Event.Where) then
        begin
          MakeLocal(Event.Where, Mouse);
          FColor := Mouse.Y * 4 + Mouse.X div 3;
          if FColor > MaxCol then
            FColor := MaxCol;
        end
        else
          FColor := OldColor;
        ColorChanged;
        DrawView;
      until not MouseEvent(Event, evMouseMove);
      ClearEvent(Event);
    end;

    evKeyDown:
    begin
      case CtrlToArrow(Event.KeyCode) of
        kbLeft:
          if FColor > 0 then Dec(FColor) else FColor := MaxCol;
        kbRight:
          if FColor < MaxCol then Inc(FColor) else FColor := 0;
        kbUp:
          if FColor > Width - 1 then
            Dec(FColor, Width)
          else if FColor = 0 then
            FColor := MaxCol
          else
            Inc(FColor, MaxCol - Width);
        kbDown:
          if FColor < MaxCol - (Width - 1) then
            Inc(FColor, Width)
          else if FColor = MaxCol then
            FColor := 0
          else
            Dec(FColor, MaxCol - Width);
      else
        Exit;
      end;
      DrawView;
      ColorChanged;
      ClearEvent(Event);
    end;

    evBroadcast:
      case Event.Command of
        cmColorSet:
        begin
          if FSelType = csBackground then
            FColor := (PByte(Event.InfoPtr)^ shr 4) and $0F
          else
            FColor := PByte(Event.InfoPtr)^ and $0F;
          DrawView;
          Exit;
        end;
      else
        Exit;
      end;
  end;
end;

procedure TColorSelector.ColorChanged;
begin
  if FSelType = csBackground then
    Message(Owner, evBroadcast, cmColorBackgroundChanged, Pointer(NativeUInt(FColor)))
  else
    Message(Owner, evBroadcast, cmColorForegroundChanged, Pointer(NativeUInt(FColor)));
end;

{****************************************************************************}
{ TMonoSelector Class                                                        }
{****************************************************************************}

constructor TMonoSelector.Create(var Bounds: TRect; ASelType: Byte);
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := EventMask or evBroadcast;
  FSelType := ASelType;
  FColor := 0;
end;

constructor TMonoSelector.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(FColor, SizeOf(FColor));
  S.Read(FSelType, SizeOf(FSelType));
end;

procedure TMonoSelector.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(FColor, SizeOf(FColor));
  S.Write(FSelType, SizeOf(FSelType));
end;

function TMonoSelector.GetPalette: PPalette;
const
  P: ShortString = CMonoSelector;
begin
  Result := PPalette(@P);
end;

procedure TMonoSelector.Draw;
const
  Button = ' ( ) ';
var
  B: TDrawBuffer;
  I: Integer;
  S: string;
begin
  DrawChar(B, 0, ' ', $07, Size.X);
  for I := 0 to 4 do
  begin
    if I < Size.Y then
    begin
      DrawChar(B, 0, ' ', $07, Size.X);
      DrawStr(B, 0, Button, $07);
      if I = FColor then
        { Use DrawChar for proper Unicode bullet display }
        DrawChar(B, 2, BulletPt, $07, 1);
      case I of
        0: S := 'Normal';
        1: S := 'Highlight';
        2: S := 'Underline';
        3: S := 'Inverse';
        4: S := 'Inv+High';
      else
        S := '';
      end;
      DrawStr(B, Length(Button), S, $07);
      WriteLine(0, I, Size.X, 1, B);
    end;
  end;
end;

procedure TMonoSelector.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);

  case Event.What of
    evMouseDown:
    begin
      var Mouse: TPoint;
      MakeLocal(Event.Where, Mouse);
      if (Mouse.Y >= 0) and (Mouse.Y < 5) then
      begin
        FColor := Mouse.Y;
        DrawView;
        ColorChanged;
      end;
      ClearEvent(Event);
    end;

    evKeyDown:
    begin
      case CtrlToArrow(Event.KeyCode) of
        kbUp:
          if FColor > 0 then Dec(FColor) else FColor := 4;
        kbDown:
          if FColor < 4 then Inc(FColor) else FColor := 0;
      else
        Exit;
      end;
      DrawView;
      ColorChanged;
      ClearEvent(Event);
    end;
  end;
end;

procedure TMonoSelector.ColorChanged;
begin
  if FSelType = csBackground then
    Message(Owner, evBroadcast, cmColorBackgroundChanged, @FColor)
  else
    Message(Owner, evBroadcast, cmColorForegroundChanged, @FColor);
end;

{****************************************************************************}
{ TColorDisplay Class                                                        }
{****************************************************************************}

constructor TColorDisplay.Create(var Bounds: TRect; const AText: string);
begin
  inherited Create(Bounds);
  EventMask := EventMask or evBroadcast;
  if AText <> '' then
    FText := AText
  else
    FText := 'Text Text ';
  FColor := nil;
end;

constructor TColorDisplay.Load(var S: TFVStream);
begin
  inherited Load(S);
  FText := S.ReadStr;
  if FText = '' then
    FText := 'Text Text ';
  FColor := nil;
end;

procedure TColorDisplay.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.WriteStr(FText);
end;

function TColorDisplay.GetPalette: PPalette;
const
  P: ShortString = CColorDisplay;
begin
  Result := PPalette(@P);
end;

procedure TColorDisplay.Draw;
var
  B: TDrawBuffer;
  C: Byte;
  S: string;
  I, Len: Integer;
begin
  if FColor <> nil then
    C := FColor^
  else
    C := $4E;  { Default: yellow on red (error indicator) }

  if C = 0 then
    C := $4E;  { Error attribute if color is 0 }

  if FText <> '' then
    S := FText
  else
    S := 'Text';

  Len := Length(S);
  if Len = 0 then
  begin
    S := 'Text';
    Len := 4;
  end;

  { Fill buffer by repeating text pattern }
  for I := 0 to (Size.X div Len) do
    DrawStr(B, I * Len, S, C);

  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TColorDisplay.HandleEvent(var Event: TEvent);
var
  ColorValue: Byte;
begin
  inherited HandleEvent(Event);
  if Event.What = evBroadcast then
    case Event.Command of
      cmColorBackgroundChanged:
      begin
        if FColor <> nil then
        begin
          ColorValue := Byte(NativeUInt(Event.InfoPtr));
          FColor^ := (FColor^ and $0F) or ((ColorValue shl 4) and $F0);
          DrawView;
        end;
      end;
      cmColorForegroundChanged:
      begin
        if FColor <> nil then
        begin
          ColorValue := Byte(NativeUInt(Event.InfoPtr));
          FColor^ := (FColor^ and $F0) or (ColorValue and $0F);
          DrawView;
        end;
      end;
    end;
end;

procedure TColorDisplay.SetColor(AColor: PByte);
begin
  FColor := AColor;
  if FColor <> nil then
    Message(Owner, evBroadcast, cmColorSet, Pointer(NativeUInt(FColor^)));
  DrawView;
end;

{****************************************************************************}
{ TColorGroupList Class                                                      }
{****************************************************************************}

constructor TColorGroupList.Create(var Bounds: TRect; AScrollBar: TScrollBar; AGroups: PColorGroup);
var
  G: PColorGroup;
  I: Integer;
begin
  inherited Create(Bounds, 1, nil, AScrollBar);
  FGroups := AGroups;

  { Count groups and assign indices }
  I := 0;
  G := AGroups;
  while G <> nil do
  begin
    G^.Index := I;
    Inc(I);
    G := G^.Next;
  end;

  SetRange(I);
  if I > 0 then FocusItem(0);
end;

constructor TColorGroupList.Load(var S: TFVStream);
begin
  inherited Load(S);
  FGroups := nil;
end;

destructor TColorGroupList.Destroy;
begin
  inherited Destroy;
end;

procedure TColorGroupList.Store(var S: TFVStream);
begin
  inherited Store(S);
end;

function TColorGroupList.GetPalette: PPalette;
const
  P: ShortString = CColorGroupList;
begin
  Result := PPalette(@P);
end;

function TColorGroupList.GetGroup(Item: Integer): PColorGroup;
var
  G: PColorGroup;
  I: Integer;
begin
  Result := nil;
  G := FGroups;
  I := 0;
  while G <> nil do
  begin
    if I = Item then
    begin
      Result := G;
      Exit;
    end;
    Inc(I);
    G := G^.Next;
  end;
end;

function TColorGroupList.GetNumGroups: Integer;
var
  G: PColorGroup;
  Count: Integer;
begin
  Count := 0;
  G := FGroups;
  while G <> nil do
  begin
    Inc(Count);
    G := G^.Next;
  end;
  Result := Count;
end;

function TColorGroupList.GetText(Item: Integer; MaxLen: Integer): string;
var
  G: PColorGroup;
begin
  G := GetGroup(Item);
  if (G <> nil) and (G^.Name <> '') then
    Result := Copy(G^.Name, 1, MaxLen)
  else
    Result := '';
end;

procedure TColorGroupList.FocusItem(Item: Integer);
var
  G: PColorGroup;
begin
  inherited FocusItem(Item);
  G := GetGroup(Item);
  if G <> nil then
    Message(Owner, evBroadcast, cmNewColorItem, G);
end;

procedure TColorGroupList.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evBroadcast then
    if Event.Command = cmSaveColorIndex then
      Event.InfoPtr := FGroups;
end;

{****************************************************************************}
{ TColorItemList Class                                                       }
{****************************************************************************}

constructor TColorItemList.Create(var Bounds: TRect; AScrollBar: TScrollBar);
begin
  inherited Create(Bounds, 1, nil, AScrollBar);
  FItems := nil;
end;

constructor TColorItemList.Load(var S: TFVStream);
begin
  inherited Load(S);
  FItems := nil;
end;

procedure TColorItemList.Store(var S: TFVStream);
begin
  inherited Store(S);
end;

function TColorItemList.GetPalette: PPalette;
const
  P: ShortString = CColorItemList;
begin
  Result := PPalette(@P);
end;

function TColorItemList.GetItem(Index: Integer): PColorItem;
var
  Item: PColorItem;
  I: Integer;
begin
  Result := nil;
  Item := FItems;
  I := 0;
  while Item <> nil do
  begin
    if I = Index then
    begin
      Result := Item;
      Exit;
    end;
    Inc(I);
    Item := Item^.Next;
  end;
end;

function TColorItemList.GetNumItems: Integer;
var
  Item: PColorItem;
  Count: Integer;
begin
  Count := 0;
  Item := FItems;
  while Item <> nil do
  begin
    Inc(Count);
    Item := Item^.Next;
  end;
  Result := Count;
end;

function TColorItemList.GetText(Item: Integer; MaxLen: Integer): string;
var
  P: PColorItem;
begin
  P := GetItem(Item);
  if (P <> nil) and (P^.Name <> '') then
    Result := Copy(P^.Name, 1, MaxLen)
  else
    Result := '';
end;

procedure TColorItemList.FocusItem(Item: Integer);
var
  P: PColorItem;
begin
  inherited FocusItem(Item);
  P := GetItem(Item);
  if P <> nil then
    Message(Owner, evBroadcast, cmNewColorIndex, @P^.Index);
end;

procedure TColorItemList.SetGroupItems(AItems: PColorItem);
begin
  FItems := AItems;
  SetRange(GetNumItems);
  if Range > 0 then
    FocusItem(0);
  DrawView;  { Always redraw after changing items }
end;

procedure TColorItemList.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);

  case Event.What of
    evBroadcast:
      case Event.Command of
        cmNewColorItem:
          SetGroupItems(PColorGroup(Event.InfoPtr)^.Items);
      end;
  end;
end;

{****************************************************************************}
{ TColorDialog Class                                                         }
{****************************************************************************}

constructor TColorDialog.Create(APalette: TPalette; AGroups: PColorGroup);
var
  R: TRect;
  SB: TScrollBar;
begin
  R.Assign(0, 0, 61, 18);
  inherited Create(R, 'Colors');
  Options := Options or ofCentered;
  FPal := APalette;
  FGroups := AGroups;

  { Group list - left side }
  R.Assign(3, 3, 18, 14);
  SB := StandardScrollBar(sbVertical + sbHandleKeyboard);
  FGroupList := TColorGroupList.Create(R, SB, AGroups);
  Insert(FGroupList);
  R.Assign(2, 2, 18, 3);
  Insert(TLabel.Create(R, '~G~roup', FGroupList));

  { Item list - middle }
  R.Assign(20, 3, 40, 14);
  SB := StandardScrollBar(sbVertical + sbHandleKeyboard);
  FItemList := TColorItemList.Create(R, SB);
  Insert(FItemList);
  R.Assign(19, 2, 40, 3);
  Insert(TLabel.Create(R, '~I~tem', FItemList));

  { Foreground selector - 16 colors in 4x4 grid (12 wide = 4 colors * 3 chars) }
  R.Assign(45, 3, 57, 7);
  FForeSel := TColorSelector.Create(R, csForeground);
  Insert(FForeSel);
  R.Assign(45, 2, 57, 3);
  Insert(TStaticText.Create(R, 'Foreground'));

  { Background selector - 8 colors in 2x4 grid (12 wide = 4 colors * 3 chars) }
  R.Assign(45, 9, 57, 11);
  FBackSel := TColorSelector.Create(R, csBackground);
  Insert(FBackSel);
  R.Assign(45, 8, 57, 9);
  Insert(TStaticText.Create(R, 'Background'));

  { Color display preview }
  R.Assign(44, 12, 58, 14);
  FDisplay := TColorDisplay.Create(R, 'Text Text ');
  Insert(FDisplay);

  { Buttons }
  R.Assign(3, 15, 13, 17);
  Insert(TButton.Create(R, 'O~K~', cmOK, bfDefault));
  R.Assign(15, 15, 27, 17);
  Insert(TButton.Create(R, 'Cancel', cmCancel, bfNormal));

  { Initialize with first group }
  if AGroups <> nil then
    SetupItems(AGroups);
end;

constructor TColorDialog.Load(var S: TFVStream);
var
  Temp: string;
begin
  inherited Load(S);
  Temp := S.ReadStr;
  { TPalette stores color bytes, not text - use AnsiString conversion }
  FPal := AnsiString(Temp);
  FGroups := nil;
end;

destructor TColorDialog.Destroy;
begin
  DisposeColorGroup(FGroups);
  inherited Destroy;
end;

procedure TColorDialog.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.WriteStr(string(FPal));  { TPalette stores color bytes, not text }
end;

function TColorDialog.GetPalette: PPalette;
const
  P: ShortString = CColorDialog;
begin
  Result := PPalette(@P);
end;

function TColorDialog.DataSize: Word;
begin
  Result := Length(FPal);
end;

procedure TColorDialog.GetData(var Rec);
begin
  Move(FPal[1], Rec, Length(FPal));
end;

procedure TColorDialog.SetData(var Rec);
begin
  Move(Rec, FPal[1], Length(FPal));
end;

procedure TColorDialog.SetupItems(AGroup: PColorGroup);
begin
  if AGroup <> nil then
    FItemList.SetGroupItems(AGroup^.Items);
end;

procedure TColorDialog.HandleEvent(var Event: TEvent);
var
  C: Byte;
  Index: Byte;
  P: PColorItem;
begin
  { Handle cmNewColorItem BEFORE inherited - like C++ version }
  if (Event.What = evBroadcast) and (Event.Command = cmNewColorItem) then
    SetupItems(PColorGroup(Event.InfoPtr));

  inherited HandleEvent(Event);

  case Event.What of
    evBroadcast:
      case Event.Command of
        cmNewColorIndex:
        begin
          Index := PByte(Event.InfoPtr)^;
          if Index <= Length(FPal) then
          begin
            C := Byte(FPal[Index]);
            FForeSel.Color := C and $0F;
            FBackSel.Color := (C shr 4) and $0F;
            FForeSel.DrawView;
            FBackSel.DrawView;
            FDisplay.SetColor(@FPal[Index]);
          end;
        end;

        cmColorForegroundChanged:
        begin
          if FItemList.Range > 0 then
          begin
            P := FItemList.GetItem(FItemList.Focused);
            if P <> nil then
            begin
              Index := P^.Index;
              if Index <= Length(FPal) then
              begin
                C := Byte(FPal[Index]);
                C := (C and $F0) or (Byte(NativeUInt(Event.InfoPtr)) and $0F);
                FPal[Index] := AnsiChar(C);
                FDisplay.DrawView;
              end;
            end;
          end;
        end;

        cmColorBackgroundChanged:
        begin
          if FItemList.Range > 0 then
          begin
            P := FItemList.GetItem(FItemList.Focused);
            if P <> nil then
            begin
              Index := P^.Index;
              if Index <= Length(FPal) then
              begin
                C := Byte(FPal[Index]);
                C := (C and $0F) or ((Byte(NativeUInt(Event.InfoPtr)) and $0F) shl 4);
                FPal[Index] := AnsiChar(C);
                FDisplay.DrawView;
              end;
            end;
          end;
        end;
      end;
  end;
end;

{****************************************************************************}
{ Registration                                                               }
{****************************************************************************}

const
  RColorSelector: TStreamRec = (
    ObjType: idColorSelector;
    VmtLink: nil;
    Load: @TColorSelector.Load;
    Store: @TColorSelector.Store);

  RMonoSelector: TStreamRec = (
    ObjType: idMonoSelector;
    VmtLink: nil;
    Load: @TMonoSelector.Load;
    Store: @TMonoSelector.Store);

  RColorDisplay: TStreamRec = (
    ObjType: idColorDisplay;
    VmtLink: nil;
    Load: @TColorDisplay.Load;
    Store: @TColorDisplay.Store);

  RColorGroupList: TStreamRec = (
    ObjType: idColorGroupList;
    VmtLink: nil;
    Load: @TColorGroupList.Load;
    Store: @TColorGroupList.Store);

  RColorItemList: TStreamRec = (
    ObjType: idColorItemList;
    VmtLink: nil;
    Load: @TColorItemList.Load;
    Store: @TColorItemList.Store);

  RColorDialog: TStreamRec = (
    ObjType: idColorDialog;
    VmtLink: nil;
    Load: @TColorDialog.Load;
    Store: @TColorDialog.Store);

procedure RegisterColorSel;
begin
  RegisterType(RColorSelector);
  RegisterType(RMonoSelector);
  RegisterType(RColorDisplay);
  RegisterType(RColorGroupList);
  RegisterType(RColorItemList);
  RegisterType(RColorDialog);
end;

end.
