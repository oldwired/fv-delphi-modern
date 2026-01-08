{*******************************************************}
{       Free Vision - Outline/Tree View Unit            }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  Outline viewer for hierarchical data display.
  Based on FPC Free Vision implementation.

  Note: The original FPC version used get_caller_frame for callback
  context. This Delphi port uses a different approach with explicit
  context passing and internal iteration.

  Ported to Delphi: January 2026
}

unit Outline;

interface

uses
  FVCommon, Objects, Drivers, Views, FVBoxChars;

type
  { Forward declarations }
  PNode = ^TNode;
  TOutlineViewer = class;
  TOutline = class;

  { TNode - Tree node record }
  TNode = record
    Next: PNode;
    Text: string;
    ChildList: PNode;
    Expanded: Boolean;
  end;

  { Callback context for iteration }
  PIterContext = ^TIterContext;
  TIterContext = record
    UserData: Pointer;
    Found: Boolean;
    ResultNode: Pointer;
  end;

  { Callback function type - returns True to stop iteration }
  TNodeCallback = function(Node: Pointer; Level, Position: Sw_Integer;
    Lines: LongInt; Flags: Word; Context: PIterContext): Boolean;

  { TOutlineViewer - Base outline viewer }
  TOutlineViewer = class(TScroller)
  private
    FFoc: Sw_Integer;
    procedure SetFocus(AFocus: Sw_Integer);
    function DoRecurse(Callback: TNodeCallback; Context: PIterContext;
      StopIfFound: Boolean): Pointer;
  public
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar); reintroduce; virtual;
    procedure Adjust(Node: Pointer; Expand: Boolean); virtual;
    function CreateGraph(Level: SmallInt; Lines: LongInt; Flags: Word;
      LevWidth, EndWidth: SmallInt; const Chars: string): string;
    procedure Draw; override;
    procedure ExpandAll(Node: Pointer);
    function FirstThat(Callback: TNodeCallback; Context: PIterContext): Pointer;
    procedure Focused(I: Sw_Integer); virtual;
    procedure ForEach(Callback: TNodeCallback; Context: PIterContext);
    function GetChild(Node: Pointer; I: Sw_Integer): Pointer; virtual;
    function GetGraph(Level: SmallInt; Lines: LongInt; Flags: Word): string;
    function GetNode(I: Sw_Integer): Pointer; virtual;
    function GetNumChildren(Node: Pointer): Sw_Integer; virtual;
    function GetPalette: PPalette; override;
    function GetRoot: Pointer; virtual;
    function GetText(Node: Pointer): string; virtual;
    procedure HandleEvent(var Event: TEvent); override;
    function HasChildren(Node: Pointer): Boolean; virtual;
    function IsExpanded(Node: Pointer): Boolean; virtual;
    function IsSelected(I: Sw_Integer): Boolean; virtual;
    procedure Selected(I: Sw_Integer); virtual;
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure Update;
    property Foc: Sw_Integer read FFoc write FFoc;
  end;

  { TOutline - Outline with TNode data }
  TOutline = class(TOutlineViewer)
  private
    FRoot: PNode;
  public
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
      ARoot: PNode); reintroduce; virtual;
    destructor Destroy; override;
    procedure Adjust(Node: Pointer; Expand: Boolean); override;
    function GetChild(Node: Pointer; I: Sw_Integer): Pointer; override;
    function GetNumChildren(Node: Pointer): Sw_Integer; override;
    function GetRoot: Pointer; override;
    function GetText(Node: Pointer): string; override;
    function HasChildren(Node: Pointer): Boolean; override;
    function IsExpanded(Node: Pointer): Boolean; override;
    property Root: PNode read FRoot write FRoot;
  end;

const
  { Flags for node state }
  ovExpanded = $01;
  ovChildren = $02;
  ovLast     = $04;

  { Palette }
  COutlineViewer = CScroller + #8#8;

{ Helper functions }
function NewNode(const AText: string; AChildren, ANext: PNode): PNode;
procedure DisposeNode(Node: PNode);

implementation

uses
  SysUtils;

{****************************************************************************}
{ Helper Functions                                                           }
{****************************************************************************}

function NewNode(const AText: string; AChildren, ANext: PNode): PNode;
begin
  New(Result);
  Result^.Next := ANext;
  Result^.Text := AText;
  Result^.ChildList := AChildren;
  Result^.Expanded := True;
end;

procedure DisposeNode(Node: PNode);
var
  Next: PNode;
begin
  while Node <> nil do
  begin
    DisposeNode(Node^.ChildList);
    { Text is now a managed string - Dispose will finalize it }
    Next := Node^.Next;
    Dispose(Node);
    Node := Next;
  end;
end;

{****************************************************************************}
{ TOutlineViewer Class                                                       }
{****************************************************************************}

constructor TOutlineViewer.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar);
begin
  inherited Create(Bounds, AHScrollBar, AVScrollBar);
  Options := Options or ofFirstClick;
  FFoc := 0;
  GrowMode := gfGrowHiX + gfGrowHiY;
end;

procedure TOutlineViewer.Adjust(Node: Pointer; Expand: Boolean);
begin
  RunError(211);  { Abstract method }
end;

function TOutlineViewer.CreateGraph(Level: SmallInt; Lines: LongInt;
  Flags: Word; LevWidth, EndWidth: SmallInt; const Chars: string): string;
const
  FillerOrBar   = 0;
  YorL          = 2;
  StraightOrTee = 4;
  Retracted     = 6;
var
  Graph: string;
  J, I: Integer;
begin
  { Allocate space for graph }
  SetLength(Graph, Level * LevWidth + EndWidth + 1);
  for I := 1 to Length(Graph) do
    Graph[I] := ' ';

  J := 1;

  { Write bar characters for each level }
  while Level > 0 do
  begin
    if (Lines and 1) <> 0 then
      Graph[J] := Chars[FillerOrBar + 2]
    else
      Graph[J] := Chars[FillerOrBar + 1];
    for I := 1 to LevWidth - 1 do
      if J + I <= Length(Graph) then
        Graph[J + I] := Chars[FillerOrBar + 1];
    Inc(J, LevWidth);
    Dec(Level);
    Lines := Lines shr 1;
  end;

  { Write end characters }
  Dec(EndWidth);
  if EndWidth > 0 then
  begin
    if Flags and ovLast <> 0 then
      Graph[J] := Chars[YorL + 2]
    else
      Graph[J] := Chars[YorL + 1];
    Inc(J);
    Dec(EndWidth);

    if EndWidth > 0 then
    begin
      Dec(EndWidth);
      for I := 1 to EndWidth do
      begin
        if J <= Length(Graph) then
          Graph[J] := Chars[StraightOrTee + 1];
        Inc(J);
      end;

      if J <= Length(Graph) then
      begin
        if (Flags and ovChildren) <> 0 then
          Graph[J] := Chars[StraightOrTee + 2]
        else
          Graph[J] := Chars[StraightOrTee + 1];
      end;
      Inc(J);
    end;

    if J <= Length(Graph) then
    begin
      if Flags and ovExpanded <> 0 then
        Graph[J] := Chars[Retracted + 2]
      else
        Graph[J] := Chars[Retracted + 1];
    end;
  end;

  SetLength(Graph, J);
  Result := Graph;
end;

function TOutlineViewer.DoRecurse(Callback: TNodeCallback; Context: PIterContext;
  StopIfFound: Boolean): Pointer;
var
  Position: Sw_Integer;

  function Recurse(Cur: Pointer; Level: SmallInt; Lines: LongInt;
    LastChild: Boolean): Pointer;
  var
    I, ChildCount: Sw_Integer;
    Child: Pointer;
    Flags: Word;
    Children, Expanded, Found: Boolean;
  begin
    Inc(Position);
    Result := nil;

    Children := HasChildren(Cur);
    Expanded := IsExpanded(Cur);

    { Determine flags }
    Flags := 0;
    if (not Children) or Expanded then
      Inc(Flags, ovExpanded);
    if Children and Expanded then
      Inc(Flags, ovChildren);
    if LastChild then
      Inc(Flags, ovLast);

    { Call the callback function }
    Found := Callback(Cur, Level, Position, Lines, Flags, Context);

    if StopIfFound and Found then
      Result := Cur
    else if Children and Expanded then
    begin
      { Recurse into children }
      if not LastChild then
        Lines := Lines or (1 shl Level);

      ChildCount := GetNumChildren(Cur);
      for I := 0 to ChildCount - 1 do
      begin
        Child := GetChild(Cur, I);
        if (Child <> nil) and (Level < 31) then
          Result := Recurse(Child, Level + 1, Lines, I = ChildCount - 1);
        if Result <> nil then
          Break;
      end;
    end;
  end;

var
  R: Pointer;
begin
  Position := -1;
  R := GetRoot;
  if R <> nil then
    Result := Recurse(R, 0, 0, True)
  else
    Result := nil;
end;

{ Internal callbacks for Draw }
type
  PDrawContext = ^TDrawContext;
  TDrawContext = record
    Viewer: TOutlineViewer;
    CNormal, CNormalX, CSelect, CFocus: Byte;
    MaxPos: Sw_Integer;
    B: TDrawBuffer;
  end;

function DrawItemCallback(Node: Pointer; Level, Position: Sw_Integer;
  Lines: LongInt; Flags: Word; Context: PIterContext): Boolean;
var
  DC: PDrawContext;
  C: Byte;
  S, T: string;
  I: Integer;
  UnicodeText: string;
begin
  DC := PDrawContext(Context^.UserData);

  { Stop if past visible area }
  Result := Position >= DC^.Viewer.Delta.Y + DC^.Viewer.Size.Y;
  if (Position < DC^.Viewer.Delta.Y) or Result then
    Exit;

  DC^.MaxPos := Position;
  S := DC^.Viewer.GetGraph(Level, Lines, Flags);
  T := DC^.Viewer.GetText(Node);

  { Determine text color }
  if (DC^.Viewer.Foc = Position) and (DC^.Viewer.State and sfFocused <> 0) then
    C := DC^.CFocus
  else if DC^.Viewer.IsSelected(Position) then
    C := DC^.CSelect
  else if Flags and ovExpanded <> 0 then
    C := DC^.CNormalX
  else
    C := DC^.CNormal;

  { Build Unicode text from graph + text, converting placeholder chars to Unicode }
  UnicodeText := '';
  for I := 1 to Length(S) do
  begin
    case S[I] of
      'B': UnicodeText := UnicodeText + BoxVert;       { │ vertical bar }
      'T': UnicodeText := UnicodeText + BoxVertRight;  { ├ tee right }
      'L': UnicodeText := UnicodeText + BoxBottomLeft; { └ corner }
      '-': UnicodeText := UnicodeText + BoxHoriz;      { ─ horizontal }
      'E': UnicodeText := UnicodeText + '+';           { + expand indicator (collapsed only) }
    else
      UnicodeText := UnicodeText + S[I];
    end;
  end;
  UnicodeText := UnicodeText + T;

  { Fill draw buffer using DrawChar/DrawStr for proper Unicode handling }
  { First clear the buffer }
  DrawChar(DC^.B, 0, ' ', C, DC^.Viewer.Size.X);

  { Then draw the visible portion with horizontal scroll offset }
  if DC^.Viewer.Delta.X < Length(UnicodeText) then
  begin
    { Extract visible portion }
    UnicodeText := Copy(UnicodeText, DC^.Viewer.Delta.X + 1, DC^.Viewer.Size.X);
    DrawStr(DC^.B, 0, UnicodeText, C);
  end;

  { Draw the line }
  DC^.Viewer.WriteLine(0, Position - DC^.Viewer.Delta.Y, DC^.Viewer.Size.X, 1, DC^.B);
end;

procedure TOutlineViewer.Draw;
var
  DC: TDrawContext;
  IC: TIterContext;
  I: Integer;
  ClearColor: Byte;
begin
  DC.Viewer := Self;
  { Use same color for normal and collapsed items to avoid black line issue }
  DC.CNormal := GetColor(1);
  DC.CNormalX := GetColor(1);
  DC.CFocus := GetColor(2);
  DC.CSelect := GetColor(3);
  DC.MaxPos := -1;

  { Clear entire view area first to prevent artifacts }
  ClearColor := Lo(GetColor(1));
  DrawChar(DC.B, 0, ' ', ClearColor, Size.X);
  for I := 0 to Size.Y - 1 do
    WriteLine(0, I, Size.X, 1, DC.B);

  IC.UserData := @DC;
  IC.Found := False;
  IC.ResultNode := nil;

  { Draw all visible items on top of cleared background }
  ForEach(DrawItemCallback, @IC);
end;

procedure TOutlineViewer.ExpandAll(Node: Pointer);
var
  I: Sw_Integer;
begin
  if HasChildren(Node) then
  begin
    for I := 0 to GetNumChildren(Node) - 1 do
      ExpandAll(GetChild(Node, I));
    Adjust(Node, True);
  end;
end;

function TOutlineViewer.FirstThat(Callback: TNodeCallback; Context: PIterContext): Pointer;
begin
  Result := DoRecurse(Callback, Context, True);
end;

procedure TOutlineViewer.Focused(I: Sw_Integer);
begin
  FFoc := I;
end;

procedure TOutlineViewer.ForEach(Callback: TNodeCallback; Context: PIterContext);
begin
  DoRecurse(Callback, Context, False);
end;

function TOutlineViewer.GetChild(Node: Pointer; I: Sw_Integer): Pointer;
begin
  RunError(211);  { Abstract method }
  Result := nil;
end;

function TOutlineViewer.GetGraph(Level: SmallInt; Lines: LongInt; Flags: Word): string;
begin
  { Tree characters use Unicode box drawing chars - but stored as single bytes
    since we'll convert them in DrawItemCallback using the mapping below:
    ' ' = space (filler)
    'B' = BoxVert │ (vertical bar)
    'T' = BoxVertRight ├ (tee right for non-last child)
    'L' = BoxBottomLeft └ (corner for last child)
    '-' = BoxHoriz ─ (horizontal line)
    'E' = Expand indicator '+' (shown only when node is collapsed)
    Output: └─+ for collapsed nodes, └── for expanded/leaf nodes }
  Result := CreateGraph(Level, Lines, Flags, 3, 3, ' BTL--E-');
end;

{ Callback for GetNode }
type
  PGetNodeContext = ^TGetNodeContext;
  TGetNodeContext = record
    TargetPosition: Sw_Integer;
  end;

function GetNodeCallback(Node: Pointer; Level, Position: Sw_Integer;
  Lines: LongInt; Flags: Word; Context: PIterContext): Boolean;
var
  GNC: PGetNodeContext;
begin
  GNC := PGetNodeContext(Context^.UserData);
  Result := Position = GNC^.TargetPosition;
end;

function TOutlineViewer.GetNode(I: Sw_Integer): Pointer;
var
  GNC: TGetNodeContext;
  IC: TIterContext;
begin
  GNC.TargetPosition := I;
  IC.UserData := @GNC;
  IC.Found := False;
  IC.ResultNode := nil;
  Result := FirstThat(GetNodeCallback, @IC);
end;

function TOutlineViewer.GetNumChildren(Node: Pointer): Sw_Integer;
begin
  RunError(211);  { Abstract method }
  Result := 0;
end;

function TOutlineViewer.GetPalette: PPalette;
const
  P: ShortString = COutlineViewer;
begin
  Result := PPalette(@P);
end;

function TOutlineViewer.GetRoot: Pointer;
begin
  RunError(211);  { Abstract method }
  Result := nil;
end;

function TOutlineViewer.GetText(Node: Pointer): string;
begin
  RunError(211);  { Abstract method }
  Result := '';
end;

{ Callback for finding focused node in HandleEvent }
type
  PFindFocusContext = ^TFindFocusContext;
  TFindFocusContext = record
    TargetFoc: Sw_Integer;
    OutLevel: Sw_Integer;
    OutLines: LongInt;
    OutFlags: Word;
  end;

function FindFocusedCallback(Node: Pointer; Level, Position: Sw_Integer;
  Lines: LongInt; Flags: Word; Context: PIterContext): Boolean;
var
  FFC: PFindFocusContext;
begin
  FFC := PFindFocusContext(Context^.UserData);
  Result := Position = FFC^.TargetFoc;
  if Result then
  begin
    FFC^.OutLevel := Level;
    FFC^.OutLines := Lines;
    FFC^.OutFlags := Flags;
  end;
end;

procedure TOutlineViewer.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  Cur: Pointer;
  NewFocus: Sw_Integer;
  Count: Byte;
  Handled, MouseDrag: Boolean;
  Graph: string;
  FFC: TFindFocusContext;
  IC: TIterContext;

  function GraphOfFocus(var OutGraph: string): Pointer;
  begin
    FFC.TargetFoc := Foc;
    IC.UserData := @FFC;
    IC.Found := False;
    IC.ResultNode := nil;
    Result := FirstThat(FindFocusedCallback, @IC);
    OutGraph := GetGraph(FFC.OutLevel, FFC.OutLines, FFC.OutFlags);
  end;

const
  SkipMouseEvents = 3;
begin
  inherited HandleEvent(Event);

  case Event.What of
    evKeyDown:
    begin
      NewFocus := Foc;
      Handled := True;

      case CtrlToArrow(Event.KeyCode) of
        kbUp, kbLeft:
          Dec(NewFocus);
        kbDown, kbRight:
          Inc(NewFocus);
        kbPgDn:
          Inc(NewFocus, Size.Y - 1);
        kbPgUp:
          Dec(NewFocus, Size.Y - 1);
        kbCtrlPgUp:
          NewFocus := 0;
        kbCtrlPgDn:
          NewFocus := Limit.Y - 1;
        kbHome:
          NewFocus := Delta.Y;
        kbEnd:
          NewFocus := Delta.Y + Size.Y - 1;
        kbCtrlEnter, kbEnter:
          Selected(NewFocus);
      else
        case Event.CharCode of
          '-', '+':
          begin
            Adjust(GetNode(NewFocus), Event.CharCode = '+');
            Update;
          end;
          '*':
          begin
            ExpandAll(GetNode(NewFocus));
            Update;
          end;
        else
          Handled := False;
        end;
      end;

      if NewFocus < 0 then
        NewFocus := 0;
      if NewFocus >= Limit.Y then
        NewFocus := Limit.Y - 1;
      if Foc <> NewFocus then
        SetFocus(NewFocus);
      if Handled then
        ClearEvent(Event);
    end;

    evMouseDown:
    begin
      Count := 1;
      MouseDrag := False;
      NewFocus := Foc;

      repeat
        MakeLocal(Event.Where, Mouse);
        if MouseInView(Event.Where) then
          NewFocus := Delta.Y + Mouse.Y
        else
        begin
          Inc(Count, Byte(Event.What = evMouseAuto));
          if Count and SkipMouseEvents = 0 then
          begin
            if Mouse.Y < 0 then
              Dec(NewFocus);
            if Mouse.Y >= Size.Y then
              Inc(NewFocus);
          end;
        end;

        if NewFocus < 0 then
          NewFocus := 0;
        if NewFocus >= Limit.Y then
          NewFocus := Limit.Y - 1;
        if Foc <> NewFocus then
          SetFocus(NewFocus);

        if MouseEvent(Event, evMouseMove + evMouseAuto) then
          MouseDrag := True
        else
          Break;
      until False;

      if Event.Double then
        Selected(Foc)
      else if not MouseDrag then
      begin
        Cur := GraphOfFocus(Graph);
        if Mouse.X < Length(Graph) then
        begin
          Adjust(Cur, not IsExpanded(Cur));
          Update;
        end;
      end;
    end;
  end;
end;

function TOutlineViewer.HasChildren(Node: Pointer): Boolean;
begin
  RunError(211);  { Abstract method }
  Result := False;
end;

function TOutlineViewer.IsExpanded(Node: Pointer): Boolean;
begin
  RunError(211);  { Abstract method }
  Result := False;
end;

function TOutlineViewer.IsSelected(I: Sw_Integer): Boolean;
begin
  Result := FFoc = I;
end;

procedure TOutlineViewer.Selected(I: Sw_Integer);
begin
  { Does nothing by default }
end;

procedure TOutlineViewer.SetFocus(AFocus: Sw_Integer);
begin
  if (AFocus >= 0) and (AFocus < Limit.Y) then
  begin
    Focused(AFocus);
    if AFocus < Delta.Y then
      ScrollTo(Delta.X, AFocus)
    else if AFocus - Size.Y >= Delta.Y then
      ScrollTo(Delta.X, AFocus - Size.Y + 1);
    DrawView;
  end;
end;

procedure TOutlineViewer.SetState(AState: Word; Enable: Boolean);
begin
  if AState and sfFocused <> 0 then
    DrawView;
  inherited SetState(AState, Enable);
end;

{ Callback for Update }
type
  PUpdateContext = ^TUpdateContext;
  TUpdateContext = record
    Viewer: TOutlineViewer;
    Count: Sw_Integer;
    MaxWidth: Integer;
  end;

function UpdateCallback(Node: Pointer; Level, Position: Sw_Integer;
  Lines: LongInt; Flags: Word; Context: PIterContext): Boolean;
var
  UC: PUpdateContext;
  Width: Integer;
begin
  Result := False;
  UC := PUpdateContext(Context^.UserData);
  Inc(UC^.Count);
  Width := Length(UC^.Viewer.GetText(Node)) +
           Length(UC^.Viewer.GetGraph(Level, Lines, Flags));
  if Width > UC^.MaxWidth then
    UC^.MaxWidth := Width;
end;

procedure TOutlineViewer.Update;
var
  UC: TUpdateContext;
  IC: TIterContext;
  NewFoc: Sw_Integer;
  NewDeltaY: Sw_Integer;
begin
  UC.Viewer := Self;
  UC.Count := 0;
  UC.MaxWidth := 0;

  IC.UserData := @UC;
  IC.Found := False;
  IC.ResultNode := nil;

  ForEach(UpdateCallback, @IC);
  SetLimit(UC.MaxWidth, UC.Count);

  { Clamp focus to valid range }
  NewFoc := FFoc;
  if NewFoc >= UC.Count then
    NewFoc := UC.Count - 1;
  if NewFoc < 0 then
    NewFoc := 0;
  FFoc := NewFoc;

  { Adjust scroll position if content shrunk }
  NewDeltaY := Delta.Y;
  if NewDeltaY + Size.Y > UC.Count then
  begin
    NewDeltaY := UC.Count - Size.Y;
    if NewDeltaY < 0 then
      NewDeltaY := 0;
  end;

  { Scroll to adjusted position if needed }
  if NewDeltaY <> Delta.Y then
    ScrollTo(Delta.X, NewDeltaY);

  { Force complete redraw of owner to prevent buffering artifacts }
  if (Owner <> nil) and (Owner is TGroup) then
    TGroup(Owner).ReDraw
  else
    DrawView;
end;

{****************************************************************************}
{ TOutline Class                                                             }
{****************************************************************************}

constructor TOutline.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
  ARoot: PNode);
begin
  inherited Create(Bounds, AHScrollBar, AVScrollBar);
  FRoot := ARoot;
  Update;
end;

destructor TOutline.Destroy;
begin
  DisposeNode(FRoot);
  inherited Destroy;
end;

procedure TOutline.Adjust(Node: Pointer; Expand: Boolean);
begin
  if Node <> nil then
    PNode(Node)^.Expanded := Expand;
end;

function TOutline.GetChild(Node: Pointer; I: Sw_Integer): Pointer;
begin
  if Node = nil then
  begin
    Result := nil;
    Exit;
  end;

  Result := PNode(Node)^.ChildList;
  while (I > 0) and (Result <> nil) do
  begin
    Dec(I);
    Result := PNode(Result)^.Next;
  end;
end;

function TOutline.GetNumChildren(Node: Pointer): Sw_Integer;
var
  P: PNode;
begin
  Result := 0;
  if Node = nil then
    Exit;

  P := PNode(Node)^.ChildList;
  while P <> nil do
  begin
    Inc(Result);
    P := P^.Next;
  end;
end;

function TOutline.GetRoot: Pointer;
begin
  Result := FRoot;
end;

function TOutline.GetText(Node: Pointer): string;
begin
  if (Node <> nil) and (PNode(Node)^.Text <> '') then
    Result := PNode(Node)^.Text
  else
    Result := '';
end;

function TOutline.HasChildren(Node: Pointer): Boolean;
begin
  Result := (Node <> nil) and (PNode(Node)^.ChildList <> nil);
end;

function TOutline.IsExpanded(Node: Pointer): Boolean;
begin
  Result := (Node <> nil) and PNode(Node)^.Expanded;
end;

end.
