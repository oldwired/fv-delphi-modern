{*******************************************************}
{       Turbo Pascal Menus Unit                         }
{       Compatibility layer for Modern Delphi           }
{       Converted to CLASS syntax                       }
{*******************************************************}

unit Menus;

{$R-}  { Disable range checking for legacy buffer operations }

interface

uses
  Winapi.Windows,
  System.SysUtils,
  Objects, Drivers, Views, fvconsts, FVBoxChars;

const
  CMenuView   = #2#3#4#5#6#7;
  CStatusLine = #2#3#4#5#6#7;

type
  TMenuStr = string;
  PMenu = ^TMenu;

  PMenuItem = ^TMenuItem;
  TMenuItem = record
    Next: PMenuItem;
    Name: string;
    Command: Word;
    Disabled: Boolean;
    KeyCode: Word;
    HelpCtx: Word;
    Param: string;     { Used when Command <> 0 }
    SubMenu: PMenu;    { Used when Command = 0 }
  end;

  TMenu = record
    Items: PMenuItem;
    Default: PMenuItem;
  end;

  PStatusItem = ^TStatusItem;
  TStatusItem = record
    Next: PStatusItem;
    Text: string;
    KeyCode: Word;
    Command: Word;
  end;

  PStatusDef = ^TStatusDef;
  TStatusDef = record
    Next: PStatusDef;
    Min, Max: Word;
    Items: PStatusItem;
  end;

  TMenuView = class(TView)
    ParentMenu: TMenuView;
    Menu: PMenu;
    Current: PMenuItem;
    OldItem: PMenuItem;
    constructor Create(var Bounds: TRect); override;
    constructor Load(var S: TFVStream); override;
    function Execute: Word; override;
    function GetHelpCtx: Word; override;
    function GetPalette: PPalette; override;
    function FindItem(Ch: Char): PMenuItem;
    function HotKey(KeyCode: Word): PMenuItem;
    function NewSubView(var Bounds: TRect; AMenu: PMenu;
      AParentMenu: TMenuView): TMenuView; virtual;
    procedure Store(var S: TFVStream);
    procedure HandleEvent(var Event: TEvent); override;
    procedure GetItemRect(Item: PMenuItem; var R: TRect); virtual;
  private
    procedure GetItemRectX(Item: PMenuItem; var R: TRect); virtual;
  end;

  TMenuBar = class(TMenuView)
    constructor Create(var Bounds: TRect; AMenu: PMenu); reintroduce; virtual;
    destructor Destroy; override;
    procedure Draw; override;
  private
    procedure GetItemRectX(Item: PMenuItem; var R: TRect); override;
  end;

  TMenuBox = class(TMenuView)
    constructor Create(var Bounds: TRect; AMenu: PMenu; AParentMenu: TMenuView); reintroduce; virtual;
    procedure Draw; override;
  private
    procedure GetItemRectX(Item: PMenuItem; var R: TRect); override;
  end;

  TMenuPopup = class(TMenuBox)
    constructor Create(var Bounds: TRect; AMenu: PMenu); reintroduce; virtual;
    destructor Destroy; override;
    procedure HandleEvent(var Event: TEvent); override;
  end;

  TStatusLine = class(TView)
    Items: PStatusItem;
    Defs: PStatusDef;
    constructor Create(var Bounds: TRect; ADefs: PStatusDef); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    destructor Destroy; override;
    function GetPalette: PPalette; override;
    function Hint(AHelpCtx: Word): string; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    procedure Store(var S: TFVStream);
    procedure HandleEvent(var Event: TEvent); override;
  private
    procedure FindItems;
    procedure DrawSelect(Selected: PStatusItem);
  end;

function NewMenu(Items: PMenuItem): PMenu;
procedure DisposeMenu(Menu: PMenu);
function NewLine(Next: PMenuItem): PMenuItem;
function NewItem(Name, Param: TMenuStr; KeyCode: Word; Command: Word;
  AHelpCtx: Word; Next: PMenuItem): PMenuItem;
function NewSubMenu(Name: TMenuStr; AHelpCtx: Word; SubMenu: PMenu;
  Next: PMenuItem): PMenuItem;
function NewStatusDef(AMin, AMax: Word; AItems: PStatusItem;
  ANext: PStatusDef): PStatusDef;
function NewStatusKey(const AText: string; AKeyCode: Word; ACommand: Word;
  ANext: PStatusItem): PStatusItem;
procedure RegisterMenus;

const
  RMenuBar: TStreamRec = (ObjType: idMenuBar; VmtLink: nil; Load: nil; Store: nil);
  RMenuBox: TStreamRec = (ObjType: idMenuBox; VmtLink: nil; Load: nil; Store: nil);
  RStatusLine: TStreamRec = (ObjType: 42; VmtLink: nil; Load: nil; Store: nil);
  RMenuPopup: TStreamRec = (ObjType: 43; VmtLink: nil; Load: nil; Store: nil);

implementation

uses FVScreen, FVUTF8;

const
  SubMenuChar: array[Boolean] of Char = ('>', SmallArrowRight);

constructor TMenuView.Create(var Bounds: TRect);
begin inherited Create(Bounds); EventMask := EventMask or evBroadcast; end;

constructor TMenuView.Load(var S: TFVStream);
begin inherited Load(S); Menu := nil; end;

function TMenuView.Execute: Word;
type MenuAction = (DoNothing, DoSelect, DoReturn);
var AutoSelect, MouseActive: Boolean; Action: MenuAction; Ch: Char; Res: Word; R: TRect;
  ItemShown, P: PMenuItem; Target: TMenuView; E: TEvent;

  procedure TrackMouse;
  var Mouse: TPoint;
  begin Mouse.X := E.Where.X - Origin.X; Mouse.Y := E.Where.Y - Origin.Y;
    if Menu = nil then begin Current := nil; Exit; end;
    Current := Menu^.Items;
    while Current <> nil do begin GetItemRectX(Current, R); if R.Contains(Mouse) then begin MouseActive := True; Exit; end; Current := Current.Next; end;
  end;

  procedure TrackKey(FindNext: Boolean);
    procedure NextItem; begin Current := Current.Next; if (Current = nil) and (Menu <> nil) then Current := Menu^.Items; end;
    procedure PrevItem; var Prv: PMenuItem; begin Prv := Current; if (Menu <> nil) and (Prv = Menu^.Items) then Prv := nil; repeat NextItem until (Current = nil) or (Current.Next = Prv); end;
  begin if (Current <> nil) and (Menu <> nil) then repeat if FindNext then NextItem else PrevItem until (Current = nil) or (Current.Name <> ''); end;

  function MouseInOwner: Boolean;
  var Mouse: TPoint;
  begin MouseInOwner := False;
    if (ParentMenu <> nil) and (ParentMenu.Size.Y = 1) then begin Mouse.X := E.Where.X - ParentMenu.Origin.X; Mouse.Y := E.Where.Y - ParentMenu.Origin.Y;
      ParentMenu.GetItemRectX(ParentMenu.Current, R); MouseInOwner := R.Contains(Mouse); end;
  end;

  function MouseInMenus: Boolean; var MV: TMenuView;
  begin MV := ParentMenu; while (MV <> nil) and not MV.MouseInView(E.Where) do MV := MV.ParentMenu; MouseInMenus := MV <> nil; end;

  function TopMenu: TMenuView; var MV: TMenuView;
  begin MV := Self; while MV.ParentMenu <> nil do MV := MV.ParentMenu; TopMenu := MV; end;

begin
  AutoSelect := False; MouseActive := False; Res := 0; ItemShown := nil;
  if Menu <> nil then Current := Menu^.Default else Current := nil;
  repeat Action := DoNothing;
    GetEvent(E);
    case E.What of
      evMouseDown: if MouseInView(E.Where) or MouseInOwner then begin TrackMouse; if Size.Y = 1 then AutoSelect := True; end else Action := DoReturn;
      evMouseUp: begin TrackMouse;
        if MouseInOwner then Current := Menu^.Default
        else if (Current <> nil) and (Current.Name <> '') then Action := DoSelect
        else if MouseActive or MouseInView(E.Where) then Action := DoReturn
        else begin Current := Menu^.Default; if Current = nil then Current := Menu^.Items; Action := DoNothing; end; end;
      evMouseMove: if E.Buttons <> 0 then begin TrackMouse; if not (MouseInView(E.Where) or MouseInOwner) and MouseInMenus then Action := DoReturn; end;
      evKeyDown: case CtrlToArrow(E.KeyCode) of
        kbUp, kbDown: if Size.Y <> 1 then TrackKey(CtrlToArrow(E.KeyCode) = kbDown) else if E.KeyCode = kbDown then AutoSelect := True;
        kbLeft, kbRight: if ParentMenu = nil then TrackKey(CtrlToArrow(E.KeyCode) = kbRight) else Action := DoReturn;
        kbHome, kbEnd: if Size.Y <> 1 then begin Current := Menu^.Items; if E.KeyCode = kbEnd then TrackKey(False); end;
        kbEnter: begin if Size.Y = 1 then AutoSelect := True; Action := DoSelect; end;
        kbEsc: begin Action := DoReturn; if (ParentMenu = nil) or (ParentMenu.Size.Y <> 1) then ClearEvent(E); end;
        else Target := Self; Ch := GetAltChar(E.KeyCode); if Ch = #0 then Ch := Char(E.CharCode) else Target := TopMenu;
          P := Target.FindItem(Ch);
          if P = nil then begin P := TopMenu.HotKey(E.KeyCode); if (P <> nil) and CommandEnabled(P.Command) then begin Res := P.Command; Action := DoReturn; end; end
          else if Target = Self then begin if Size.Y = 1 then AutoSelect := True; Action := DoSelect; Current := P; end
          else if (ParentMenu <> Target) or (ParentMenu.Current <> P) then Action := DoReturn;
        end;
      evCommand: if E.Command = cmMenu then begin AutoSelect := False; if ParentMenu <> nil then Action := DoReturn; end else Action := DoReturn;
    end;
    if ItemShown <> Current then begin OldItem := ItemShown; ItemShown := Current; DrawView; OldItem := nil; end;
    if (Action = DoSelect) or ((Action = DoNothing) and AutoSelect) then if Current <> nil then with Current^ do if Name <> '' then
      if Command = 0 then begin if E.What and (evMouseDown + evMouseMove) <> 0 then PutEvent(E);
        GetItemRectX(Current, R); R.A.X := R.A.X + Origin.X; R.A.Y := R.B.Y + Origin.Y; R.B.X := Owner.Size.X; R.B.Y := Owner.Size.Y;
        Target := TopMenu.NewSubView(R, SubMenu, Self); Res := Owner.ExecView(Target); FreeAndNil(Target);
      end else if Action = DoSelect then Res := Command;
    if (Res <> 0) and CommandEnabled(Res) then begin Action := DoReturn; ClearEvent(E); end else Res := 0;
  until Action = DoReturn;
  if E.What <> evNothing then if (ParentMenu <> nil) or (E.What = evCommand) then PutEvent(E);
  if Current <> nil then begin Menu^.Default := Current; Current := nil; DrawView; end;
  Execute := Res;
end;

function TMenuView.GetHelpCtx: Word;
var C: TMenuView;
begin C := Self; while (C <> nil) and ((C.Current = nil) or (C.Current.HelpCtx = hcNoContext) or (C.Current.Name = '')) do C := C.ParentMenu;
  if C <> nil then GetHelpCtx := C.Current.HelpCtx else GetHelpCtx := hcNoContext; end;

function TMenuView.GetPalette: PPalette; const P: String[Length(CMenuView)] = CMenuView; begin GetPalette := PPalette(@P); end;

function TMenuView.FindItem(Ch: Char): PMenuItem;
var I: SmallInt; P: PMenuItem;
begin Ch := UpCase(Ch); P := Menu^.Items;
  while P <> nil do begin if (P.Name <> '') and (not P.Disabled) then begin I := Pos('~', P.Name);
    if (I <> 0) and (Ch = UpCase(Char(P.Name[I + 1]))) then begin FindItem := P; Exit; end; end; P := P.Next; end;
  FindItem := nil; end;

function TMenuView.HotKey(KeyCode: Word): PMenuItem;
  function FindHotKey(P: PMenuItem): PMenuItem; var T: PMenuItem;
  begin while P <> nil do begin if P.Name <> '' then if P.Command = 0 then begin T := FindHotKey(P.SubMenu^.Items); if T <> nil then begin FindHotKey := T; Exit; end; end
    else if not P.Disabled and (P.KeyCode <> kbNoKey) and (P.KeyCode = KeyCode) then begin FindHotKey := P; Exit; end; P := P.Next; end; FindHotKey := nil; end;
begin HotKey := FindHotKey(Menu^.Items); end;

function TMenuView.NewSubView(var Bounds: TRect; AMenu: PMenu; AParentMenu: TMenuView): TMenuView;
begin NewSubView := TMenuBox.Create(Bounds, AMenu, AParentMenu); end;

procedure TMenuView.Store(var S: TFVStream); begin inherited Store(S); end;

procedure TMenuView.HandleEvent(var Event: TEvent);
var CallDraw: Boolean; P: PMenuItem;
  procedure UpdateMenu(AMenu: PMenu); var MI: PMenuItem; CommandState: Boolean;
  begin MI := AMenu^.Items; while MI <> nil do begin if MI.Name <> '' then if MI.Command = 0 then UpdateMenu(MI.SubMenu)
    else begin CommandState := CommandEnabled(MI.Command); if MI.Disabled = CommandState then begin MI.Disabled := not CommandState; CallDraw := True; end; end; MI := MI.Next; end; end;
  procedure DoSelect; begin PutEvent(Event); Event.Command := Owner.ExecView(Self);
    if (Event.Command <> 0) and CommandEnabled(Event.Command) then begin Event.What := evCommand; Event.InfoPtr := nil; PutEvent(Event); end; ClearEvent(Event); end;
begin if Menu <> nil then case Event.What of
  evMouseDown: DoSelect;
  evKeyDown: if FindItem(GetAltChar(Event.KeyCode)) <> nil then DoSelect else begin P := HotKey(Event.KeyCode);
    if (P <> nil) and CommandEnabled(P.Command) then begin Event.What := evCommand; Event.Command := P.Command; Event.InfoPtr := nil; PutEvent(Event); ClearEvent(Event); end; end;
  evCommand: if Event.Command = cmMenu then DoSelect;
  evBroadcast: if Event.Command = cmCommandSetChanged then begin CallDraw := False; UpdateMenu(Menu); if CallDraw then DrawView; end;
end; end;

procedure TMenuView.GetItemRectX(Item: PMenuItem; var R: TRect); begin end;
procedure TMenuView.GetItemRect(Item: PMenuItem; var R: TRect); begin GetItemRectX(Item, R); end;

constructor TMenuBar.Create(var Bounds: TRect; AMenu: PMenu);
begin inherited Create(Bounds); GrowMode := gfGrowHiX; Menu := AMenu; Options := Options or ofPreProcess; end;

destructor TMenuBar.Destroy; begin if Menu <> nil then DisposeMenu(Menu); inherited Destroy; end;

procedure TMenuBar.Draw;
var I, J: Integer; CNormal, CSelect, CNormDisabled, CSelDisabled, Color: Word; P: PMenuItem; B: TDrawBuffer;
begin CNormal := GetColor($0301); CSelect := GetColor($0604); CNormDisabled := GetColor($0202); CSelDisabled := GetColor($0505);
  DrawChar(B, 0, ' ', Byte(CNormal), Size.X);
  if Menu <> nil then begin I := 0; P := Menu^.Items; while P <> nil do begin if P.Name <> '' then begin
    if P.Disabled then begin if P = Current then Color := CSelDisabled else Color := CNormDisabled; end else begin if P = Current then Color := CSelect else Color := CNormal; end;
    J := CStrLen(P.Name);
    if I + J + 2 < MaxViewWidth then begin
      DrawChar(B, I, ' ', Byte(Color), 1); DrawCStr(B, I + 1, P.Name, Color); DrawChar(B, I + 1 + J, ' ', Byte(Color), 1);
    end;
    Inc(I, J + 2); end; P := P.Next; end; end;
  WriteBuf(0, 0, Size.X, 1, B); end;

procedure TMenuBar.GetItemRectX(Item: PMenuItem; var R: TRect);
var I: SmallInt; P: PMenuItem;
begin I := 0; R.Assign(0, 0, 0, 1);
  if Menu = nil then Exit;
  P := Menu^.Items;
  while P <> nil do begin R.A.X := I; if P.Name <> '' then begin R.B.X := R.A.X + CStrLen(P.Name) + 2; I := I + CStrLen(P.Name) + 2; end else R.B.X := R.A.X; if P = Item then Break; P := P.Next; end; end;

constructor TMenuBox.Create(var Bounds: TRect; AMenu: PMenu; AParentMenu: TMenuView);
var W, H, L: SmallInt; P: PMenuItem; R: TRect; S: string;
begin W := 0; H := 2; if AMenu <> nil then begin P := AMenu^.Items;
  while P <> nil do begin if P.Name <> '' then begin S := ' ' + P.Name + ' '; if (P.Command <> 0) and (P.Param <> '') then S := S + ' - ' + P.Param; end;
    L := CStrLen(S); if L > W then W := L; Inc(H); P := P.Next; end; end;
  W := 5 + W; R.Copy(Bounds); if R.A.X + W < R.B.X then R.B.X := R.A.X + W else R.A.X := R.B.X - W; R.B.X := R.A.X + W;
  if R.A.Y + H < R.B.Y then R.B.Y := R.A.Y + H else R.A.Y := R.B.Y - H;
  inherited Create(R); State := State or sfShadow; Options := Options or ofFramed or ofPreProcess; Menu := AMenu; ParentMenu := AParentMenu; end;

procedure TMenuBox.Draw;
var CNormal, CSelect, CSelectDisabled, CDisabled, Color: Word; Index, Y: SmallInt; P: PMenuItem; B: TDrawBuffer; S: string;
    W: Integer;
type FrameLineType = (UpperLine, NormalLine, SeparationLine, LowerLine); FrameLineChars = array[0..2] of Char;
const FrameLines: array[FrameLineType] of FrameLineChars = (
    (BoxTopLeft, BoxHoriz, BoxTopRight),         { UpperLine }
    (BoxVert, ' ', BoxVert),                     { NormalLine }
    (BoxVertRight, BoxHoriz, BoxVertLeft),       { SeparationLine }
    (BoxBottomLeft, BoxHoriz, BoxBottomRight));  { LowerLine }
  procedure CreateBorder(LineType: FrameLineType);
  begin
    if (W < 5) or (W >= MaxViewWidth) then Exit;
    DrawChar(B, 0, ' ', CNormal, 1); DrawChar(B, 1, FrameLines[LineType][0], CNormal, 1);
    if W > 4 then DrawChar(B, 2, FrameLines[LineType][1], Byte(Color), W - 4);
    DrawChar(B, W - 2, FrameLines[LineType][2], CNormal, 1); DrawChar(B, W - 1, ' ', CNormal, 1);
  end;
begin
  W := Size.X;
  if (W < 5) or (W >= MaxViewWidth) then Exit;
  CNormal := GetColor($0301); CSelect := GetColor($0604); CDisabled := GetColor($0202); CSelectDisabled := GetColor($0505);
  Color := CNormal; CreateBorder(UpperLine); WriteBuf(0, 0, W, 1, B); Y := 1;
  if Menu <> nil then begin P := Menu^.Items; while P <> nil do begin Color := CNormal;
    if P.Name <> '' then begin if P.Disabled then begin if P = Current then Color := CSelectDisabled else Color := CDisabled; end else if P = Current then Color := CSelect;
      CreateBorder(NormalLine); Index := 2; S := ' ' + P.Name + ' ';
      if Index < MaxViewWidth then DrawCStr(B, Index, S, Color);
      if P.Command = 0 then begin if W - 4 < MaxViewWidth then DrawChar(B, W - 4, SubMenuChar[LowAscii], Byte(Color), 1); end
      else if (P.Command <> 0) and (P.Param <> '') then begin
        Index := W - 3 - CStrLen(P.Param);
        if (Index > 0) and (Index < MaxViewWidth) then DrawCStr(B, Index, P.Param, Color);
      end;
      if (OldItem = nil) or (OldItem = P) or (Current = P) then WriteBuf(0, Y, W, 1, B);
    end else begin Color := CNormal; CreateBorder(SeparationLine); WriteBuf(0, Y, W, 1, B); end;
    Inc(Y); P := P.Next; end; end;
  Color := CNormal; CreateBorder(LowerLine); WriteBuf(0, Size.Y - 1, W, 1, B); end;

procedure TMenuBox.GetItemRectX(Item: PMenuItem; var R: TRect);
var X, Y: SmallInt; P: PMenuItem;
begin Y := 1; X := 2; R.Assign(X, Y, Size.X - X, Y + 1);
  if Menu = nil then Exit;
  P := Menu^.Items; while (P <> nil) and (P <> Item) do begin Inc(Y); P := P.Next; end;
  R.Assign(X, Y, Size.X - X, Y + 1); end;

constructor TMenuPopup.Create(var Bounds: TRect; AMenu: PMenu); begin inherited Create(Bounds, AMenu, nil); end;
destructor TMenuPopup.Destroy; begin if Menu <> nil then DisposeMenu(Menu); inherited Destroy; end;

procedure TMenuPopup.HandleEvent(var Event: TEvent);
var P: PMenuItem;
begin case Event.What of evKeyDown: begin P := FindItem(GetCtrlChar(Event.KeyCode)); if P = nil then P := HotKey(Event.KeyCode);
  if (P <> nil) and CommandEnabled(P.Command) then begin Event.What := evCommand; Event.Command := P.Command; Event.InfoPtr := nil; PutEvent(Event); ClearEvent(Event); end
  else if GetAltChar(Event.KeyCode) <> #0 then ClearEvent(Event); end; end;
  inherited HandleEvent(Event); end;

constructor TStatusLine.Create(var Bounds: TRect; ADefs: PStatusDef);
begin inherited Create(Bounds); Options := Options or ofPreProcess; EventMask := EventMask or evBroadcast;
  GrowMode := gfGrowLoY + gfGrowHiX + gfGrowHiY; Defs := ADefs; FindItems; end;

constructor TStatusLine.Load(var S: TFVStream); begin inherited Load(S); Defs := nil; FindItems; end;

destructor TStatusLine.Destroy;
var T: PStatusDef;
  procedure DisposeItems(Item: PStatusItem); var SI: PStatusItem; begin while Item <> nil do begin SI := Item; Item := Item.Next; { Text is now a managed string } Dispose(SI); end; end;
begin while Defs <> nil do begin T := Defs; Defs := Defs.Next; DisposeItems(T.Items); Dispose(T); end; inherited Destroy; end;

function TStatusLine.GetPalette: PPalette; const P: String[Length(CStatusLine)] = CStatusLine; begin GetPalette := PPalette(@P); end;
function TStatusLine.Hint(AHelpCtx: Word): string; begin Result := ''; end;
procedure TStatusLine.Draw; begin DrawSelect(nil); end;

procedure TStatusLine.Update; var H: Word; P: TView;
begin P := TopView; if P <> nil then H := P.GetHelpCtx else H := hcNoContext; if HelpCtx <> H then begin HelpCtx := H; FindItems; DrawView; end; end;

procedure TStatusLine.Store(var S: TFVStream); begin inherited Store(S); end;

procedure TStatusLine.HandleEvent(var Event: TEvent);
var Mouse: TPoint; T, Tt: PStatusItem;
  function ItemMouseIsIn: PStatusItem; var X, Xi: Word; SI: PStatusItem;
  begin ItemMouseIsIn := nil; if (Mouse.Y < 0) or (Mouse.Y > 1) then Exit; X := 0; SI := Items;
    while SI <> nil do begin if SI.Text <> '' then begin Xi := X; X := Xi + CStrLen(' ' + SI.Text + ' ');
      if (Mouse.X >= Xi) and (Mouse.X < X) then begin ItemMouseIsIn := SI; Exit; end; end; SI := SI.Next; end; end;
begin inherited HandleEvent(Event);
  case Event.What of
    evMouseDown: begin T := nil;
      repeat Mouse.X := Event.Where.X - Origin.X; Mouse.Y := Event.Where.Y - Origin.Y; Tt := ItemMouseIsIn; if T <> Tt then DrawSelect(Tt); T := Tt; until not MouseEvent(Event, evMouseMove);
      if (T <> nil) and CommandEnabled(T.Command) then begin Event.What := evCommand; Event.Command := T.Command; Event.InfoPtr := nil; PutEvent(Event); end; ClearEvent(Event); DrawSelect(nil); end;
    evKeyDown: begin T := Items; while T <> nil do begin if (Event.KeyCode = T.KeyCode) and CommandEnabled(T.Command) then begin
      Event.What := evCommand; Event.Command := T.Command; Event.InfoPtr := nil; PutEvent(Event); ClearEvent(Event); Exit; end; T := T.Next; end; end;
    evBroadcast: if Event.Command = cmCommandSetChanged then DrawView;
  end; end;

procedure TStatusLine.FindItems; var P: PStatusDef;
begin P := Defs; while (P <> nil) and ((HelpCtx < P.Min) or (HelpCtx > P.Max)) do P := P.Next; if P = nil then Items := nil else Items := P.Items; end;

procedure TStatusLine.DrawSelect(Selected: PStatusItem);
var I, L: SmallInt; Color, CSelect, CNormal, CSelDisabled, CNormDisabled: Word; B: TDrawBuffer; T: PStatusItem; HintBuf: string;
begin CNormal := GetColor($0301); CSelect := GetColor($0604); CNormDisabled := GetColor($0202); CSelDisabled := GetColor($0505);
  DrawChar(B, 0, ' ', Byte(CNormal), Size.X); T := Items; I := 0; L := 0;
  while T <> nil do begin if T.Text <> '' then begin L := CStrLen(' ' + T.Text + ' ');
    if I + L >= MaxViewWidth then Break; { Prevent buffer overflow }
    if CommandEnabled(T.Command) then begin if T = Selected then Color := CSelect else Color := CNormal; end
    else begin if T = Selected then Color := CSelDisabled else Color := CNormDisabled; end;
    DrawCStr(B, I, ' ' + T.Text + ' ', Color); Inc(I, L); end; T := T.Next; end;
  HintBuf := Hint(HelpCtx);
  if (HintBuf <> '') and (I + 2 + StringDisplayWidth(HintBuf) < MaxViewWidth) then begin
    DrawChar(B, I, BoxVert, Byte(CNormal), 1); Inc(I, 2);
    DrawStr(B, I, HintBuf, Byte(CNormal)); I := I + StringDisplayWidth(HintBuf);
  end;
  WriteLine(0, 0, Size.X, 1, B); end;

function NewMenu(Items: PMenuItem): PMenu; var P: PMenu;
begin New(P); FillChar(P^, SizeOf(TMenu), 0); if P <> nil then begin P^.Items := Items; P^.Default := Items; end; NewMenu := P; end;

procedure DisposeMenu(Menu: PMenu); var P, Q: PMenuItem;
begin if Menu <> nil then begin P := Menu^.Items;
  while P <> nil do begin if P.Name <> '' then begin { Name/Param are now managed strings } if P.Command = 0 then DisposeMenu(P.SubMenu); end;
    Q := P; P := P.Next; Dispose(Q); end; Dispose(Menu); end; end;

function NewLine(Next: PMenuItem): PMenuItem; var P: PMenuItem;
begin New(P); FillChar(P^, SizeOf(TMenuItem), 0); if P <> nil then P.Next := Next; NewLine := P; end;

function NewItem(Name, Param: TMenuStr; KeyCode: Word; Command: Word; AHelpCtx: Word; Next: PMenuItem): PMenuItem;
var P: PMenuItem; R: TRect; T: TView;
begin if (Name <> '') and (Command <> 0) then begin New(P); FillChar(P^, SizeOf(TMenuItem), 0);
  if P <> nil then begin P.Next := Next; P.Name := string(Name); P.Command := Command;
    R.Assign(1, 1, 10, 10); T := TView.Create(R); if T <> nil then begin P.Disabled := not T.CommandEnabled(Command); FreeAndNil(T); end else P.Disabled := True;
    P.KeyCode := KeyCode; P.HelpCtx := AHelpCtx; P.Param := string(Param); end;
  NewItem := P; end else NewItem := Next; end;

function NewSubMenu(Name: TMenuStr; AHelpCtx: Word; SubMenu: PMenu; Next: PMenuItem): PMenuItem;
var P: PMenuItem;
begin if (Name <> '') and (SubMenu <> nil) then begin New(P); FillChar(P^, SizeOf(TMenuItem), 0);
  if P <> nil then begin P.Next := Next; P.Name := string(Name); P.HelpCtx := AHelpCtx; P.SubMenu := SubMenu; end; NewSubMenu := P;
  end else NewSubMenu := Next; end;

function NewStatusDef(AMin, AMax: Word; AItems: PStatusItem; ANext: PStatusDef): PStatusDef;
var T: PStatusDef;
begin New(T); if T <> nil then begin T.Next := ANext; T.Min := AMin; T.Max := AMax; T.Items := AItems; end; NewStatusDef := T; end;

function NewStatusKey(const AText: string; AKeyCode: Word; ACommand: Word; ANext: PStatusItem): PStatusItem;
var T: PStatusItem;
begin New(T); if T <> nil then begin T.Text := AText; T.KeyCode := AKeyCode; T.Command := ACommand; T.Next := ANext; end; Result := T; end;

procedure RegisterMenus; begin RegisterType(RMenuBar); RegisterType(RMenuBox); RegisterType(RStatusLine); RegisterType(RMenuPopup); end;

end.
