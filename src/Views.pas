{*******************************************************}
{       Free Vision Views Unit                          }
{       Delphi-compatible version                       }
{       CONVERTED TO CLASS SYNTAX                       }
{*******************************************************}

unit Views;

{$I platform.inc}
{$R-}  { Disable range checking for legacy buffer operations }

interface

uses
  {$IFDEF OS_WINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.SysUtils, System.IOUtils,
  Objects, Drivers, Video, FVConsts;



{***************************************************************************}
{                              PUBLIC CONSTANTS                             }
{***************************************************************************}

const
  { TView State masks }
  sfVisible   = $0001;
  sfCursorVis = $0002;
  sfCursorIns = $0004;
  sfShadow    = $0008;
  sfActive    = $0010;
  sfSelected  = $0020;
  sfFocused   = $0040;
  sfDragging  = $0080;
  sfDisabled  = $0100;
  sfModal     = $0200;
  sfDefault   = $0400;
  sfExposed   = $0800;

  { TView Option masks }
  ofSelectable  = $0001;
  ofTopSelect   = $0002;
  ofFirstClick  = $0004;
  ofFramed      = $0008;
  ofPreProcess  = $0010;
  ofPostProcess = $0020;
  ofBuffered    = $0040;
  ofTileable    = $0080;
  ofCenterX     = $0100;
  ofCenterY     = $0200;
  ofCentered    = $0300;
  ofValidate    = $0400;
  ofVersion     = $3000;
  ofVersion10   = $0000;
  ofVersion20   = $1000;

  { TView GrowMode masks }
  gfGrowLoX = $01;
  gfGrowLoY = $02;
  gfGrowHiX = $04;
  gfGrowHiY = $08;
  gfGrowAll = $0F;
  gfGrowRel = $10;

  { TView DragMode masks }
  dmDragMove = $01;
  dmDragGrow = $02;
  dmLimitLoX = $10;
  dmLimitLoY = $20;
  dmLimitHiX = $40;
  dmLimitHiY = $80;
  dmLimitAll = $F0;

  { TWindow flag masks }
  wfMove  = $01;
  wfGrow  = $02;
  wfClose = $04;
  wfZoom  = $08;

  { TWindow palettes }
  wpBlueWindow = 0;
  wpCyanWindow = 1;
  wpGrayWindow = 2;

  { Color palettes }
  CFrame      = #1#1#2#2#3;
  CScrollBar  = #4#5#5;
  CScroller   = #6#7;
  CListViewer = #26#26#27#28#29;
  CBlueWindow = #8#9#10#11#12#13#14#15;
  CCyanWindow = #16#17#18#19#20#21#22#23;
  CGrayWindow = #24#25#26#27#28#29#30#31;

  { TScrollBar part codes }
  sbLeftArrow  = 0;
  sbRightArrow = 1;
  sbPageLeft   = 2;
  sbPageRight  = 3;
  sbUpArrow    = 4;
  sbDownArrow  = 5;
  sbPageUp     = 6;
  sbPageDown   = 7;
  sbIndicator  = 8;

  { TScrollBar options }
  sbHorizontal     = $0000;
  sbVertical       = $0001;
  sbHandleKeyboard = $0002;

  { Window number constants }
  wnNoNumber = 0;

  { Maximum view width }
  MaxViewWidth = 255;

{***************************************************************************}
{                          PUBLIC TYPE DEFINITIONS                          }
{***************************************************************************}

type
  TTitleStr = String[80];
  TCommandSet = set of Byte;
  PCommandSet = ^TCommandSet;
  TPalette = ShortString;
  PPalette = ^TPalette;
  TDrawBuffer = array[0..MaxViewWidth - 1] of Word;
  PDrawBuffer = ^TDrawBuffer;

  { Forward declarations }
  TView = class;
  TGroup = class;
  TFrame = class;
  TScrollBar = class;
  TWindow = class;

  { Type aliases for compatibility - these are now class references }
  PView = TView;
  PGroup = TGroup;
  PFrame = TFrame;
  PScrollBar = TScrollBar;
  PWindow = TWindow;

  SelectMode = (NormalSelect, EnterSelect, LeaveSelect);

  TView = class(TFVObject)
  public
    GrowMode: Byte;
    DragMode: Byte;
    HelpCtx: Word;
    State: Word;
    Options: Word;
    EventMask: Word;
    Origin: TPoint;
    Size: TPoint;
    Cursor: TPoint;
    Next: TView;
    Owner: TGroup;
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    constructor Load(var S: TFVStream); virtual;
    procedure Store(var S: TFVStream);
    destructor Destroy; override;
    function Prev: TView;
    function Execute: Word; virtual;
    function Focus: Boolean;
    function DataSize: Word; virtual;
    function TopView: TView;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    function GetColor(Color: Word): Word;
    function Valid(Command: Word): Boolean; virtual;
    function GetState(AState: Word): Boolean;
    function MouseInView(Point: TPoint): Boolean;
    function CommandEnabled(Command: Word): Boolean;
    function MouseEvent(var Event: TEvent; Mask: Word): Boolean;
    procedure Hide;
    procedure Show;
    procedure Draw; virtual;
    procedure DrawView;
    procedure DrawShadow;
    procedure DrawCursor; virtual;
    procedure Select;
    procedure Awaken; virtual;
    procedure MakeFirst;
    procedure HideCursor;
    procedure ShowCursor;
    procedure BlockCursor;
    procedure NormalCursor;
    procedure ResetCursor; virtual;
    procedure MoveTo(X, Y: Integer);
    procedure GrowTo(X, Y: Integer);
    procedure EndModal(Command: Word); virtual;
    procedure SetCursor(X, Y: Integer);
    procedure PutInFrontOf(Target: TView);
    procedure SetCommands(Commands: TCommandSet);
    procedure EnableCommands(Commands: TCommandSet);
    procedure DisableCommands(Commands: TCommandSet);
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;
    procedure Locate(var Bounds: TRect);
    procedure KeyEvent(var Event: TEvent);
    procedure GetEvent(var Event: TEvent); virtual;
    procedure PutEvent(var Event: TEvent); virtual;
    procedure GetExtent(var Extent: TRect);
    procedure GetBounds(var Bounds: TRect);
    procedure SetBounds(var Bounds: TRect);
    procedure GetClipRect(var Clip: TRect);
    procedure ClearEvent(var Event: TEvent);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure GetCommands(var Commands: TCommandSet);
    procedure CalcBounds(var Bounds: TRect; Delta: TPoint); virtual;
    procedure WriteBuf(X, Y, W, H: Integer; var Buf);
    procedure WriteLine(X, Y, W, H: Integer; var Buf);
    procedure MakeLocal(Source: TPoint; var Dest: TPoint);
    procedure MakeGlobal(Source: TPoint; var Dest: TPoint);
    procedure WriteStr(X, Y: Integer; Str: ShortString; Color: Byte);
    procedure WriteChar(X, Y: Integer; C: AnsiChar; Color: Byte; Count: Integer);
    procedure DragView(Event: TEvent; Mode: Byte; var Limits: TRect;
      MinSize, MaxSize: TPoint);
  end;

  TGroup = class(TView)
  public
    Phase: (phFocused, phPreProcess, phPostProcess);
    EndState: Word;
    Current: TView;
    Last: TView;
    Buffer: PWordArray;
    constructor Create(var Bounds: TRect); override;
    constructor Load(var S: TFVStream); override;
    destructor Destroy; override;
    procedure Store(var S: TFVStream);
    function First: TView;
    function Execute: Word; override;
    function GetHelpCtx: Word; override;
    function DataSize: Word; override;
    function ExecView(P: TView): Word; virtual;
    function Valid(Command: Word): Boolean; override;
    function FocusNext(Forwards: Boolean): Boolean;
    procedure Draw; override;
    procedure Lock;
    procedure UnLock;
    procedure Awaken; override;
    procedure ReDraw;
    procedure Insert(P: TView);
    procedure Delete(P: TView);
    procedure ForEach(P: TCallbackProcParam);
    procedure EndModal(Command: Word); override;
    procedure SelectNext(Forwards: Boolean);
    procedure InsertBefore(P, Target: TView);
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
    procedure EventError(var Event: TEvent); virtual;
    procedure HandleEvent(var Event: TEvent); override;
    procedure ChangeBounds(var Bounds: TRect); override;
  private
    LockFlag: Byte;
    Clip: TRect;
    function IndexOf(P: TView): Integer;
    function FindNext(Forwards: Boolean): TView;
    function FirstMatch(AState: Word; AOptions: Word): TView;
    function LastMatch(AState: Word; AOptions: Word): TView;
    procedure ResetCurrent;
    procedure RemoveView(P: TView);
    procedure InsertView(P, Target: TView);
    procedure SetCurrent(P: TView; Mode: SelectMode);
    procedure DrawSubViews(P, Bottom: TView);
  end;

  TFrame = class(TView)
  public
    constructor Create(var Bounds: TRect); override;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetState(AState: Word; Enable: Boolean); override;
  private
    FrameMode: Word;
    procedure FrameLine(var FrameBuf; Y, N: Integer; Color: Byte);
  end;

  TScrollChars = array[0..4] of AnsiChar;

  TScrollBar = class(TView)
  public
    Value: Integer;
    Min: Integer;
    Max: Integer;
    PgStep: Integer;
    ArStep: Integer;
    constructor Create(var Bounds: TRect); override;
    function GetPalette: PPalette; override;
    function ScrollStep(Part: Integer): Integer; virtual;
    procedure Draw; override;
    procedure ScrollDraw; virtual;
    procedure SetValue(AValue: Integer);
    procedure SetRange(AMin, AMax: Integer);
    procedure SetStep(APgStep, AArStep: Integer);
    procedure SetParams(AValue, AMin, AMax, APgStep, AArStep: Integer);
    procedure HandleEvent(var Event: TEvent); override;
  private
    Chars: TScrollChars;
    function GetPos: Integer;
    function GetSize: Integer;
    procedure DrawPos(Pos: Integer);
  end;

  TScroller = class;
  PScroller = TScroller;
  TScroller = class(TView)
  public
    Delta: TPoint;
    Limit: TPoint;
    HScrollBar: TScrollBar;
    VScrollBar: TScrollBar;
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar); reintroduce; virtual;
    function GetPalette: PPalette; override;
    procedure ScrollDraw; virtual;
    procedure SetLimit(X, Y: Integer);
    procedure ScrollTo(X, Y: Integer);
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure ChangeBounds(var Bounds: TRect); override;
  private
    DrawFlag: Boolean;
    DrawLock: Byte;
    procedure CheckDraw;
  end;

  TListViewer = class;
  PListViewer = TListViewer;
  TListViewer = class(TView)
  public
    NumCols: Integer;
    TopItem: Integer;
    Focused: Integer;
    Range: Integer;
    HScrollBar: TScrollBar;
    VScrollBar: TScrollBar;
    constructor Create(var Bounds: TRect; ANumCols: Word; AHScrollBar, AVScrollBar: TScrollBar); reintroduce; virtual;
    function GetPalette: PPalette; override;
    function IsSelected(Item: Integer): Boolean; virtual;
    function GetText(Item: Integer; MaxLen: Integer): string; virtual;
    procedure Draw; override;
    procedure FocusItem(Item: Integer); virtual;
    procedure SetTopItem(Item: Integer);
    procedure SetRange(ARange: Integer);
    procedure SelectItem(Item: Integer); virtual;
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure ChangeBounds(var Bounds: TRect); override;
    procedure FocusItemNum(Item: Integer); virtual;
  end;

  TWindow = class(TGroup)
  public
    Flags: Byte;
    Number: Integer;
    Palette: Integer;
    ZoomRect: TRect;
    Frame: TFrame;
    Title: PString;
    constructor Create(var Bounds: TRect; ATitle: TTitleStr; ANumber: Integer); reintroduce; virtual;
    destructor Destroy; override;
    function GetPalette: PPalette; override;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    function StandardScrollBar(AOptions: Word): TScrollBar;
    procedure Zoom; virtual;
    procedure Close; virtual;
    procedure InitFrame; virtual;
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SizeLimits(var Min, Max: TPoint); override;
  end;

{***************************************************************************}
{                            INTERFACE ROUTINES                             }
{***************************************************************************}

function Message(Receiver: TView; What, Command: Word; InfoPtr: Pointer): Pointer;
function GetSubViewPtr(var S: TFVStream; OwnerGroup: TGroup): TView;
procedure PutSubViewPtr(var S: TFVStream; P: TView);
procedure RegisterViews;

{***************************************************************************}
{                        INITIALIZED PUBLIC VARIABLES                       }
{***************************************************************************}

const
  CommandSetChanged: Boolean = False;
  ShowMarkers: Boolean = False;
  ErrorAttr: Byte = $CF;
  PositionalEvents: Word = evMouse;
  FocusedEvents: Word = evKeyboard + evCommand;
  MinWinSize: TPoint = (X: 16; Y: 6);
  ShadowSize: TPoint = (X: 2; Y: 1);
  ShadowAttr: Byte = $08;
  SpecialChars: array[0..5] of AnsiChar = (#175, #174, #26, #27, ' ', ' ');

var
  CurCommandSet: TCommandSet;
  TheTopView: TView;

procedure DebugWrite(const S: string);

implementation

var
  DebugLog: TextFile;
  DebugLogOpen: Boolean = False;

procedure DebugWrite(const S: string);
begin
  if not DebugLogOpen then begin
    AssignFile(DebugLog, 'fvdebug.log');
    Rewrite(DebugLog);
    DebugLogOpen := True;
  end;
  WriteLn(DebugLog, S);
  Flush(DebugLog);
end;

var
  OwnerGroup: TGroup;

{ Helper functions }

function Min(A, B: Integer): Integer;
begin
  if A < B then Result := A else Result := B;
end;

function Max(A, B: Integer): Integer;
begin
  if A > B then Result := A else Result := B;
end;

procedure RectIntersect(var R1: TRect; const R2: TRect);
begin
  if R1.A.X < R2.A.X then R1.A.X := R2.A.X;
  if R1.A.Y < R2.A.Y then R1.A.Y := R2.A.Y;
  if R1.B.X > R2.B.X then R1.B.X := R2.B.X;
  if R1.B.Y > R2.B.Y then R1.B.Y := R2.B.Y;
end;

{***************************************************************************}
{                              TView Object                                 }
{***************************************************************************}

constructor TView.Create(var Bounds: TRect);
begin
  inherited Create;
  Owner := nil;
  Next := nil;
  Origin := Bounds.A;
  Size.X := Bounds.B.X - Bounds.A.X;
  Size.Y := Bounds.B.Y - Bounds.A.Y;
  Cursor.X := 0;
  Cursor.Y := 0;
  GrowMode := 0;
  DragMode := dmLimitLoY;
  HelpCtx := hcNoContext;
  State := sfVisible;
  Options := 0;
  EventMask := evMouseDown + evKeyDown + evCommand;
end;

destructor TView.Destroy;
begin
  Hide;
  if Owner <> nil then Owner.Delete(Self);
  inherited Destroy;
end;

constructor TView.Load(var S: TFVStream);
begin
  inherited Create;
  S.Read(Origin, SizeOf(Origin));
  S.Read(Size, SizeOf(Size));
  S.Read(Cursor, SizeOf(Cursor));
  S.Read(GrowMode, SizeOf(GrowMode));
  S.Read(DragMode, SizeOf(DragMode));
  S.Read(HelpCtx, SizeOf(HelpCtx));
  S.Read(State, SizeOf(State));
  S.Read(Options, SizeOf(Options));
  S.Read(EventMask, SizeOf(EventMask));
  Owner := nil;
  Next := nil;
end;

procedure TView.Store(var S: TFVStream);
begin
  S.Write(Origin, SizeOf(Origin));
  S.Write(Size, SizeOf(Size));
  S.Write(Cursor, SizeOf(Cursor));
  S.Write(GrowMode, SizeOf(GrowMode));
  S.Write(DragMode, SizeOf(DragMode));
  S.Write(HelpCtx, SizeOf(HelpCtx));
  S.Write(State, SizeOf(State));
  S.Write(Options, SizeOf(Options));
  S.Write(EventMask, SizeOf(EventMask));
end;

function TView.Prev: TView;
var
  P: TView;
begin
  Result := Self;
  if Owner <> nil then begin
    P := Self;
    while P.Next <> Self do P := P.Next;
    Result := P;
  end;
end;

function TView.Execute: Word;
begin
  Result := cmCancel;
end;

function TView.Focus: Boolean;
var
  Res: Boolean;
begin
  Res := True;
  if (State and (sfSelected + sfModal)) = 0 then begin
    if Owner <> nil then begin
      Res := Owner.Focus;
      if Res then
        if ((Owner.Current = nil) or
           ((Owner.Current.Options and ofValidate) = 0) or
            (Owner.Current.Valid(cmReleasedFocus))) then
          Select
        else
          Res := False;
    end;
  end;
  Result := Res;
end;

function TView.DataSize: Word;
begin
  Result := 0;
end;

function TView.TopView: TView;
var
  P: TView;
begin
  if TheTopView <> nil then
    Result := TheTopView
  else begin
    P := Self;
    while (P <> nil) and ((P.State and sfModal) = 0) do
      P := P.Owner;
    Result := P;
  end;
end;

function TView.GetHelpCtx: Word;
begin
  if (State and sfDragging) <> 0 then
    Result := hcDragging
  else
    Result := HelpCtx;
end;

function TView.GetPalette: PPalette;
begin
  Result := nil;
end;

function TView.GetColor(Color: Word): Word;
var
  P: PPalette;
  Q: TView;
  ColLo, ColHi: Byte;
begin
  Result := 0;

  { Map Hi byte through palette chain }
  if Hi(Color) > 0 then begin
    ColHi := Hi(Color);
    Q := Self;
    repeat
      P := Q.GetPalette;
      if P <> nil then begin
        if ColHi <= Length(P^) then
          ColHi := Ord(P^[ColHi])
        else
          ColHi := ErrorAttr;
      end;
      Q := Q.Owner;
    until Q = nil;
    Result := Word(ColHi) shl 8;
  end;

  { Map Lo byte through palette chain }
  if Lo(Color) > 0 then begin
    ColLo := Lo(Color);
    Q := Self;
    repeat
      P := Q.GetPalette;
      if P <> nil then begin
        if ColLo <= Length(P^) then
          ColLo := Ord(P^[ColLo])
        else
          ColLo := ErrorAttr;
      end;
      Q := Q.Owner;
    until Q = nil;
    Result := Result or ColLo;
  end;
end;

function TView.Valid(Command: Word): Boolean;
begin
  Result := True;
end;

function TView.GetState(AState: Word): Boolean;
begin
  Result := (State and AState) = AState;
end;

function TView.MouseInView(Point: TPoint): Boolean;
var
  Local: TPoint;
begin
  MakeLocal(Point, Local);
  Result := (Local.X >= 0) and (Local.X < Size.X) and
            (Local.Y >= 0) and (Local.Y < Size.Y);
end;

function TView.CommandEnabled(Command: Word): Boolean;
begin
  Result := (Command > 255) or (Command in CurCommandSet);
end;

function TView.MouseEvent(var Event: TEvent; Mask: Word): Boolean;
begin
  repeat
    GetEvent(Event);
  until (Event.What and (Mask or evMouseUp)) <> 0;
  Result := Event.What <> evMouseUp;
end;

procedure TView.Hide;
begin
  if (State and sfVisible) <> 0 then SetState(sfVisible, False);
end;

procedure TView.Show;
begin
  if (State and sfVisible) = 0 then SetState(sfVisible, True);
end;

procedure TView.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B, ' ', GetColor($01), Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TView.DrawView;
begin
  if (State and sfExposed) <> 0 then begin
    Draw;
    if (State and sfShadow) <> 0 then
      DrawShadow;
    DrawCursor;
  end;
end;

procedure TView.DrawShadow;
var
  GX, GY: Integer;
  V: TView;
  I, J: Integer;
  Target: PWord;
begin
  { Calculate global position }
  GX := Origin.X;
  GY := Origin.Y;
  V := Owner;
  while V <> nil do begin
    Inc(GX, V.Origin.X);
    Inc(GY, V.Origin.Y);
    V := V.Owner;
  end;

  { Draw right shadow (width = ShadowSize.X, height = Size.Y) }
  for I := ShadowSize.Y to Size.Y - 1 do begin
    for J := 0 to ShadowSize.X - 1 do begin
      if (GY + I >= 0) and (GY + I < Video.ScreenHeight) and
         (GX + Size.X + J >= 0) and (GX + Size.X + J < Video.ScreenWidth) then begin
        Target := @VideoBuf^[(GY + I) * Video.ScreenWidth + GX + Size.X + J];
        { Keep the character, change attribute to shadow }
        Target^ := (Target^ and $00FF) or (Word(ShadowAttr) shl 8);
      end;
    end;
  end;

  { Draw bottom shadow (width = Size.X, height = ShadowSize.Y) }
  for I := 0 to ShadowSize.Y - 1 do begin
    for J := ShadowSize.X to Size.X + ShadowSize.X - 1 do begin
      if (GY + Size.Y + I >= 0) and (GY + Size.Y + I < Video.ScreenHeight) and
         (GX + J >= 0) and (GX + J < Video.ScreenWidth) then begin
        Target := @VideoBuf^[(GY + Size.Y + I) * Video.ScreenWidth + GX + J];
        { Keep the character, change attribute to shadow }
        Target^ := (Target^ and $00FF) or (Word(ShadowAttr) shl 8);
      end;
    end;
  end;
end;

procedure TView.DrawCursor;
begin
  if State and sfFocused <> 0 then
    ResetCursor;
end;

procedure TView.Select;
begin
  if (Options and ofSelectable) <> 0 then begin
    if (Options and ofTopSelect) <> 0 then
      MakeFirst;
    { Always set as Current after selecting }
    if Owner <> nil then
      Owner.SetCurrent(Self, NormalSelect);
  end;
end;

procedure TView.Awaken;
begin
end;

procedure TView.MakeFirst;
begin
  { Note: Despite the name, this brings the view to the FRONT (top of Z-order).
    PutInFrontOf(nil) inserts at end of list = Last = drawn last = visually on top. }
  if Owner <> nil then PutInFrontOf(nil);
end;

procedure TView.HideCursor;
begin
  SetState(sfCursorVis, False);
end;

procedure TView.ShowCursor;
begin
  SetState(sfCursorVis, True);
end;

procedure TView.BlockCursor;
begin
  SetState(sfCursorIns, True);
end;

procedure TView.NormalCursor;
begin
  SetState(sfCursorIns, False);
end;

procedure TView.ResetCursor;
const
  sfV_CV_F = sfVisible + sfCursorVis + sfFocused;
var
  P: TView;
  G: TGroup;
  Cur: TPoint;
begin
  if (State and sfV_CV_F) = sfV_CV_F then begin
    P := Self;
    Cur := Cursor;
    while True do begin
      if (Cur.X < 0) or (Cur.X >= P.Size.X) or
         (Cur.Y < 0) or (Cur.Y >= P.Size.Y) then
        Break;
      Inc(Cur.X, P.Origin.X);
      Inc(Cur.Y, P.Origin.Y);
      G := P.Owner;
      if G = nil then begin
        { At top view - set cursor position }
        Video.SetCursorPos(Cur.X, Cur.Y);
        Exit;
      end;
      if (G.State and sfVisible) = 0 then
        Break;
      P := G;
    end;
  end;
  { Hide cursor if we can't show it }
  Video.SetCursorPos(Word(-1), Word(-1));
end;

procedure TView.MoveTo(X, Y: Integer);
var
  R: TRect;
begin
  R.A.X := X;
  R.A.Y := Y;
  R.B.X := X + Size.X;
  R.B.Y := Y + Size.Y;
  Locate(R);
end;

procedure TView.GrowTo(X, Y: Integer);
var
  R: TRect;
begin
  R.A := Origin;
  R.B.X := Origin.X + X;
  R.B.Y := Origin.Y + Y;
  Locate(R);
end;

procedure TView.EndModal(Command: Word);
var
  P: TView;
begin
  P := TopView;
  if P <> nil then P.EndModal(Command);
end;

procedure TView.SetCursor(X, Y: Integer);
begin
  Cursor.X := X;
  Cursor.Y := Y;
  DrawCursor;
end;

procedure TView.PutInFrontOf(Target: TView);
var
  P, LastView: TView;
begin
  if (Owner <> nil) and (Target <> Self) and (Target <> Next) and
     ((Target = nil) or (Target.Owner = Owner)) then begin
    if (State and sfVisible) = 0 then begin
      Owner.RemoveView(Self);
      Owner.InsertView(Self, Target);
    end else begin
      LastView := Next;
      if LastView <> nil then begin
        P := Target;
        while (P <> nil) and (P <> LastView) do P := P.Next;
        if P = nil then LastView := Target;
      end;
      State := State and not sfVisible;
      Owner.Lock;
      Owner.RemoveView(Self);
      Owner.InsertView(Self, Target);
      State := State or sfVisible;
      Owner.UnLock;  { Will trigger redraw }
    end;
  end;
end;

procedure TView.SetCommands(Commands: TCommandSet);
begin
  CurCommandSet := Commands;
  CommandSetChanged := True;
end;

procedure TView.EnableCommands(Commands: TCommandSet);
begin
  CurCommandSet := CurCommandSet + Commands;
  CommandSetChanged := True;
end;

procedure TView.DisableCommands(Commands: TCommandSet);
begin
  CurCommandSet := CurCommandSet - Commands;
  CommandSetChanged := True;
end;

procedure TView.SetState(AState: Word; Enable: Boolean);
var
  Command: Word;
begin
  if Enable then
    State := State or AState
  else
    State := State and not AState;

  if Owner <> nil then begin
    case AState of
      sfVisible: begin
        if Owner.GetState(sfExposed) then
          SetState(sfExposed, Enable);
        if Enable then
          DrawView
        else
          Owner.Draw;  { Redraw owner to fill gap left by hidden view }
        { When a selectable view visibility changes, let ResetCurrent find
          the appropriate view to be Current. FPC always calls ResetCurrent here. }
        if (Options and ofSelectable) <> 0 then
          Owner.ResetCurrent;
      end;
      sfCursorVis, sfCursorIns: DrawCursor;
      sfFocused: begin
        ResetCursor;
        if Enable then
          Command := cmReceivedFocus
        else
          Command := cmReleasedFocus;
        Message(Owner, evBroadcast, Command, Self);
      end;
    end;
  end;
end;

procedure TView.GetData(var Rec);
begin
end;

procedure TView.SetData(var Rec);
begin
end;

procedure TView.Locate(var Bounds: TRect);
var
  MinP, MaxP: TPoint;
  R: TRect;
begin
  SizeLimits(MinP, MaxP);
  if Bounds.B.X - Bounds.A.X < MinP.X then
    Bounds.B.X := Bounds.A.X + MinP.X;
  if Bounds.B.X - Bounds.A.X > MaxP.X then
    Bounds.B.X := Bounds.A.X + MaxP.X;
  if Bounds.B.Y - Bounds.A.Y < MinP.Y then
    Bounds.B.Y := Bounds.A.Y + MinP.Y;
  if Bounds.B.Y - Bounds.A.Y > MaxP.Y then
    Bounds.B.Y := Bounds.A.Y + MaxP.Y;

  GetBounds(R);
  if (Bounds.A.X <> R.A.X) or (Bounds.A.Y <> R.A.Y) or
     (Bounds.B.X <> R.B.X) or (Bounds.B.Y <> R.B.Y) then begin
    ChangeBounds(Bounds);
    if (Owner <> nil) and (State and sfVisible <> 0) then Owner.Draw;
  end;
end;

procedure TView.KeyEvent(var Event: TEvent);
begin
  repeat
    GetEvent(Event);
  until Event.What = evKeyDown;
end;

procedure TView.GetEvent(var Event: TEvent);
begin
  if Owner <> nil then
    Owner.GetEvent(Event)
  else
    Event.What := evNothing;
end;

procedure TView.PutEvent(var Event: TEvent);
begin
  if Owner <> nil then Owner.PutEvent(Event);
end;

procedure TView.GetExtent(var Extent: TRect);
begin
  Extent.A.X := 0;
  Extent.A.Y := 0;
  Extent.B.X := Size.X;
  Extent.B.Y := Size.Y;
end;

procedure TView.GetBounds(var Bounds: TRect);
begin
  Bounds.A := Origin;
  Bounds.B.X := Origin.X + Size.X;
  Bounds.B.Y := Origin.Y + Size.Y;
end;

procedure TView.SetBounds(var Bounds: TRect);
begin
  Origin := Bounds.A;
  Size.X := Bounds.B.X - Bounds.A.X;
  Size.Y := Bounds.B.Y - Bounds.A.Y;
end;

procedure TView.GetClipRect(var Clip: TRect);
begin
  GetExtent(Clip);
  if Owner <> nil then begin
    RectIntersect(Clip, Owner.Clip);
    Clip.A.X := Clip.A.X - Origin.X;
    Clip.A.Y := Clip.A.Y - Origin.Y;
    Clip.B.X := Clip.B.X - Origin.X;
    Clip.B.Y := Clip.B.Y - Origin.Y;
  end;
end;

procedure TView.ClearEvent(var Event: TEvent);
begin
  Event.What := evNothing;
  Event.InfoPtr := Self;
end;

procedure TView.HandleEvent(var Event: TEvent);
begin
  if Event.What = evMouseDown then
    if (State and (sfSelected + sfDisabled)) = 0 then
      if (Options and ofSelectable) <> 0 then
        if not Focus or ((Options and ofFirstClick) = 0) then
          ClearEvent(Event);
end;

procedure TView.ChangeBounds(var Bounds: TRect);
begin
  SetBounds(Bounds);
  DrawView;
end;

procedure TView.SizeLimits(var Min, Max: TPoint);
begin
  Min.X := 0;
  Min.Y := 0;
  if Owner <> nil then
    Max := Owner.Size
  else begin
    Max.X := MaxViewWidth;
    Max.Y := MaxViewWidth;
  end;
end;

procedure TView.GetCommands(var Commands: TCommandSet);
begin
  Commands := CurCommandSet;
end;

procedure TView.CalcBounds(var Bounds: TRect; Delta: TPoint);
var
  S, D: Integer;
  G: Byte;

  procedure Grow(var I: Integer);
  begin
    if (G and gfGrowRel) = 0 then
      Inc(I, D)
    else if S - D <> 0 then
      I := (I * S + (S - D) shr 1) div (S - D);
  end;

begin
  GetBounds(Bounds);
  S := Owner.Size.X;
  D := Delta.X;
  G := GrowMode;
  if (G and gfGrowLoX) <> 0 then Grow(Bounds.A.X);
  if (G and gfGrowHiX) <> 0 then Grow(Bounds.B.X);
  S := Owner.Size.Y;
  D := Delta.Y;
  if (G and gfGrowLoY) <> 0 then Grow(Bounds.A.Y);
  if (G and gfGrowHiY) <> 0 then Grow(Bounds.B.Y);
end;

procedure TView.WriteBuf(X, Y, W, H: Integer; var Buf);
var
  I: Integer;
  Target: PWord;
  Source: PWord;
  GX, GY: Integer;
  V: TView;
  CopyWidth: Integer;
  BufOffset: Integer;
begin
  if (State and sfExposed) <> 0 then begin
    if (W <= 0) or (H <= 0) then Exit;
    for I := 0 to H - 1 do begin
      if (Y + I >= 0) and (Y + I < Size.Y) then begin
        GY := Origin.Y + Y + I;
        GX := Origin.X + X;
        V := Owner;
        while V <> nil do begin
          Inc(GY, V.Origin.Y);
          Inc(GX, V.Origin.X);
          V := V.Owner;
        end;
        if (GY >= 0) and (GY < Video.ScreenHeight) and
           (GX >= 0) and (GX < Video.ScreenWidth) then begin
          BufOffset := I * W;
          if BufOffset >= MaxViewWidth then Continue; { Prevent buffer overrun }
          Target := @VideoBuf^[GY * Video.ScreenWidth + GX];
          Source := @TWordArray(Buf)[BufOffset];
          CopyWidth := Min(W, Video.ScreenWidth - GX);
          if CopyWidth > 0 then
            Move(Source^, Target^, CopyWidth * 2);
        end;
      end;
    end;
  end;
end;

procedure TView.WriteLine(X, Y, W, H: Integer; var Buf);
var
  I: Integer;
begin
  for I := 0 to H - 1 do WriteBuf(X, Y + I, W, 1, Buf);
end;

procedure TView.MakeLocal(Source: TPoint; var Dest: TPoint);
var
  P: TView;
begin
  Dest := Source;
  P := Self;
  while P <> nil do begin
    Dec(Dest.X, P.Origin.X);
    Dec(Dest.Y, P.Origin.Y);
    P := P.Owner;
  end;
end;

procedure TView.MakeGlobal(Source: TPoint; var Dest: TPoint);
var
  P: TView;
begin
  Dest := Source;
  P := Self;
  while P <> nil do begin
    Inc(Dest.X, P.Origin.X);
    Inc(Dest.Y, P.Origin.Y);
    P := P.Owner;
  end;
end;

procedure TView.WriteStr(X, Y: Integer; Str: ShortString; Color: Byte);
var
  B: TDrawBuffer;
  L: Integer;
begin
  L := Length(Str);
  if L > Size.X - X then L := Size.X - X;
  if L > 0 then begin
    MoveStr(B, Str, Color);
    WriteBuf(X, Y, L, 1, B);
  end;
end;

procedure TView.WriteChar(X, Y: Integer; C: AnsiChar; Color: Byte; Count: Integer);
var
  B: TDrawBuffer;
begin
  if Count > 0 then begin
    if Count > Size.X - X then Count := Size.X - X;
    MoveChar(B, C, Color, Count);
    WriteBuf(X, Y, Count, 1, B);
  end;
end;

procedure TView.DragView(Event: TEvent; Mode: Byte; var Limits: TRect;
  MinSize, MaxSize: TPoint);
var
  P, S: TPoint;
  SaveBounds: TRect;
  Finished: Boolean;
  MouseMoved: Boolean;

  procedure MoveGrow(Pos, Sz: TPoint);
  var
    R: TRect;
  begin
    Sz.X := Min(Max(Sz.X, MinSize.X), MaxSize.X);
    Sz.Y := Min(Max(Sz.Y, MinSize.Y), MaxSize.Y);
    Pos.X := Min(Max(Pos.X, Limits.A.X - Sz.X + 1), Limits.B.X - 1);
    Pos.Y := Min(Max(Pos.Y, Limits.A.Y - Sz.Y + 1), Limits.B.Y - 1);
    if (Mode and dmLimitLoX) <> 0 then Pos.X := Max(Pos.X, Limits.A.X);
    if (Mode and dmLimitLoY) <> 0 then Pos.Y := Max(Pos.Y, Limits.A.Y);
    if (Mode and dmLimitHiX) <> 0 then Pos.X := Min(Pos.X, Limits.B.X - Sz.X);
    if (Mode and dmLimitHiY) <> 0 then Pos.Y := Min(Pos.Y, Limits.B.Y - Sz.Y);
    R.A := Pos;
    R.B.X := Pos.X + Sz.X;
    R.B.Y := Pos.Y + Sz.Y;
    Locate(R);
  end;

  procedure Change(DX, DY: Integer);
  begin
    if (Mode and dmDragMove) <> 0 then begin
      Inc(P.X, DX);
      Inc(P.Y, DY);
    end else if (Mode and dmDragGrow) <> 0 then begin
      Inc(S.X, DX);
      Inc(S.Y, DY);
    end;
  end;

  procedure Update(X, Y: Integer);
  begin
    if (Mode and dmDragMove) <> 0 then begin
      P.X := X;
      P.Y := Y;
    end;
  end;

begin
  SetState(sfDragging, True);
  GetBounds(SaveBounds);
  Finished := False;
  MouseMoved := False;

  { Initial mouse drag if started with mouse }
  if Event.What = evMouseDown then begin
    if (Mode and dmDragMove) <> 0 then begin
      { Moving: P = offset from mouse position to window origin }
      P.X := Origin.X - Event.Where.X;
      P.Y := Origin.Y - Event.Where.Y;
      repeat
        Inc(Event.Where.X, P.X);
        Inc(Event.Where.Y, P.Y);
        if (Event.Where.X <> Origin.X) or (Event.Where.Y <> Origin.Y) then
          MouseMoved := True;
        MoveGrow(Event.Where, Size);
      until not MouseEvent(Event, evMouseMove);
      Inc(Event.Where.X, P.X);
      Inc(Event.Where.Y, P.Y);
      MoveGrow(Event.Where, Size);
    end else begin
      { Growing: P = offset from mouse position to window size }
      P.X := Size.X - Event.Where.X;
      P.Y := Size.Y - Event.Where.Y;
      S := Size;  { Save original size }
      repeat
        Inc(Event.Where.X, P.X);
        Inc(Event.Where.Y, P.Y);
        if (Event.Where.X <> S.X) or (Event.Where.Y <> S.Y) then
          MouseMoved := True;
        MoveGrow(Origin, Event.Where);
      until not MouseEvent(Event, evMouseMove);
      Inc(Event.Where.X, P.X);
      Inc(Event.Where.Y, P.Y);
      MoveGrow(Origin, Event.Where);
    end;
    { If mouse was dragged, we're done; otherwise continue to keyboard mode }
    if MouseMoved then
      Finished := True;
  end;

  { Keyboard mode - continues after mouse release (if no drag) or starts directly }
  while not Finished do begin
    P := Origin;
    S := Size;
    GetEvent(Event);
    if Event.What = evMouseDown then begin
      { Another mouse click - do mouse drag }
      MouseMoved := False;
      if (Mode and dmDragMove) <> 0 then begin
        P.X := Origin.X - Event.Where.X;
        P.Y := Origin.Y - Event.Where.Y;
        repeat
          Inc(Event.Where.X, P.X);
          Inc(Event.Where.Y, P.Y);
          if (Event.Where.X <> Origin.X) or (Event.Where.Y <> Origin.Y) then
            MouseMoved := True;
          MoveGrow(Event.Where, Size);
        until not MouseEvent(Event, evMouseMove);
        Inc(Event.Where.X, P.X);
        Inc(Event.Where.Y, P.Y);
        MoveGrow(Event.Where, Size);
      end else begin
        P.X := Size.X - Event.Where.X;
        P.Y := Size.Y - Event.Where.Y;
        S := Size;
        repeat
          Inc(Event.Where.X, P.X);
          Inc(Event.Where.Y, P.Y);
          if (Event.Where.X <> S.X) or (Event.Where.Y <> S.Y) then
            MouseMoved := True;
          MoveGrow(Origin, Event.Where);
        until not MouseEvent(Event, evMouseMove);
        Inc(Event.Where.X, P.X);
        Inc(Event.Where.Y, P.Y);
        MoveGrow(Origin, Event.Where);
      end;
      if MouseMoved then
        Finished := True;
    end else if Event.What = evKeyDown then begin
      case Event.KeyCode of
        kbLeft: Change(-1, 0);
        kbRight: Change(1, 0);
        kbUp: Change(0, -1);
        kbDown: Change(0, 1);
        kbCtrlLeft: Change(-8, 0);
        kbCtrlRight: Change(8, 0);
        kbHome: Update(Limits.A.X, P.Y);
        kbEnd: Update(Limits.B.X - S.X, P.Y);
        kbPgUp: Update(P.X, Limits.A.Y);
        kbPgDn: Update(P.X, Limits.B.Y - S.Y);
        kbEnter: Finished := True;
        kbEsc: begin
          Locate(SaveBounds);
          Finished := True;
        end;
      end;
      MoveGrow(P, S);
    end;
  end;

  SetState(sfDragging, False);
end;

{***************************************************************************}
{                             TGroup Object                                 }
{***************************************************************************}

constructor TGroup.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofBuffered;
  GetExtent(Clip);
  Current := nil;
  Last := nil;
  Buffer := nil;
  Phase := phFocused;
  LockFlag := 0;
  EndState := 0;
end;

constructor TGroup.Load(var S: TFVStream);
begin
  inherited Load(S);
  GetExtent(Clip);
  Current := nil;
  Last := nil;
  Buffer := nil;
  Phase := phFocused;
  LockFlag := 0;
  EndState := 0;
end;

procedure TGroup.Store(var S: TFVStream);
begin
  inherited Store(S);
end;

destructor TGroup.Destroy;
var
  P, T: TView;
begin
  if Last <> nil then begin
    P := Last.Next;
    Last.Next := nil;
    while P <> nil do begin
      T := P.Next;
      P.Owner := nil;  { Prevent TView.Destroy from calling Delete }
      P.Free;
      P := T;
    end;
  end;
  Last := nil;
  Current := nil;
  inherited Destroy;
end;

function TGroup.First: TView;
begin
  if Last = nil then Result := nil else Result := Last.Next;
end;

function TGroup.Execute: Word;
var
  E: TEvent;
begin
  repeat
    EndState := 0;
    repeat
      GetEvent(E);
      HandleEvent(E);
      if E.What <> evNothing then EventError(E);
    until EndState <> 0;
  until Valid(EndState);
  Result := EndState;
end;

function TGroup.GetHelpCtx: Word;
var
  H: Word;
begin
  H := hcNoContext;
  if Current <> nil then H := Current.GetHelpCtx;
  if H = hcNoContext then H := inherited GetHelpCtx;
  Result := H;
end;

function TGroup.DataSize: Word;
var
  T, S: Word;
  V: TView;
begin
  S := 0;
  if Last <> nil then begin
    V := Last;
    repeat
      V := V.Next;
      T := V.DataSize;
      Inc(S, T);
    until V = Last;
  end;
  Result := S;
end;

function TGroup.ExecView(P: TView): Word;
var
  SaveOptions: Word;
  SaveOwner: TGroup;
  SaveCurrent: TView;
  SaveCommands: TCommandSet;
begin
  if P <> nil then begin
    SaveOptions := P.Options;
    SaveOwner := P.Owner;
    SaveCurrent := Current;
    GetCommands(SaveCommands);
    if SaveOwner = nil then Insert(P);
    P.Options := P.Options and not ofSelectable;
    P.SetState(sfModal, True);
    SetCurrent(P, EnterSelect);
    if SaveOwner = nil then P.SetState(sfExposed, True);
    Result := P.Execute;
    P.SetState(sfModal, False);
    SetCurrent(SaveCurrent, LeaveSelect);
    P.Options := SaveOptions;
    SetCommands(SaveCommands);
    if SaveOwner = nil then begin
      Delete(P);
      ReDraw;  { Redraw to remove modal dialog remnants }
    end;
  end else
    Result := cmCancel;
end;

function TGroup.Valid(Command: Word): Boolean;
var
  Ok: Boolean;
  V: TView;
begin
  Ok := True;
  if Command = cmValid then begin
    if Last <> nil then begin
      V := Last;
      repeat
        V := V.Next;
        if not V.Valid(Command) then Ok := False;
      until (V = Last) or not Ok;
    end;
  end;
  Result := Ok;
end;

function TGroup.FocusNext(Forwards: Boolean): Boolean;
var
  P: TView;
begin
  P := FindNext(Forwards);
  Result := True;
  if P <> nil then Result := P.Focus;
end;

procedure TGroup.Draw;
begin
  DrawSubViews(First, nil);
end;

procedure TGroup.Lock;
begin
  Inc(LockFlag);
end;

procedure TGroup.UnLock;
begin
  if LockFlag > 0 then begin
    Dec(LockFlag);
    if LockFlag = 0 then DrawView;
  end;
end;

procedure TGroup.Awaken;
begin
end;

procedure TGroup.ReDraw;
begin
  { Draw all child views - don't call DrawView which would call Draw on self }
  DrawSubViews(First, nil);
  Video.UpdateScreen(True);  { Force immediate screen update }
end;

procedure TGroup.Insert(P: TView);
begin
  InsertBefore(P, nil);  { Insert at end (becomes new Last, drawn on top) }
end;

procedure TGroup.Delete(P: TView);
var
  SaveState: Word;
begin
  if P <> nil then begin
    SaveState := P.State;
    P.Hide;  { Clear sfVisible and sfExposed before removing }
    if Current = P then SetCurrent(P.Next, LeaveSelect);
    RemoveView(P);
    P.Owner := nil;
    P.Next := nil;
    { Restore sfVisible but not sfExposed (no owner to expose it) }
    if (SaveState and sfVisible) <> 0 then P.Show;
  end;
end;

procedure TGroup.ForEach(P: TCallbackProcParam);
var
  Tp, Hp, L0: TView;
begin
  if Last <> nil then begin
    Tp := Last;
    Hp := Tp.Next;  { Start at First }
    L0 := Last;      { Save original Last in case it changes }
    repeat
      Tp := Hp;
      if Tp = nil then Exit;
      Hp := Tp.Next;  { Save next before callback (view might be deleted) }
      P(Tp);
    until Tp = L0;  { Until we've processed original Last }
  end;
end;

procedure TGroup.EndModal(Command: Word);
begin
  if (State and sfModal) <> 0 then
    EndState := Command
  else
    inherited EndModal(Command);
end;

procedure TGroup.SelectNext(Forwards: Boolean);
var
  P: TView;
begin
  P := FindNext(Forwards);
  if P <> nil then P.Select;
end;

procedure TGroup.InsertBefore(P, Target: TView);
var
  SaveState: Word;
begin
  if (P <> nil) and (P.Owner = nil) and
     ((Target = nil) or (Target.Owner = Self)) then begin
    if (P.Options and ofCenterX) <> 0 then
      P.Origin.X := (Size.X - P.Size.X) div 2;
    if (P.Options and ofCenterY) <> 0 then
      P.Origin.Y := (Size.Y - P.Size.Y) div 2;
    SaveState := P.State;
    P.Hide;  { Clear sfVisible before inserting }
    InsertView(P, Target);  { Sets P.Owner }
    if (SaveState and sfVisible) <> 0 then P.Show;  { Triggers ResetCurrent for selectable views }
    if GetState(sfActive) then P.SetState(sfActive, True);
  end;
end;

procedure TGroup.SetState(AState: Word; Enable: Boolean);
var
  V: TView;
begin
  inherited SetState(AState, Enable);
  case AState of
    sfActive, sfDragging: begin
      Lock;
      if Last <> nil then begin
        V := Last;
        repeat
          V := V.Next;
          V.SetState(AState, Enable);
        until V = Last;
      end;
      UnLock;
    end;
    sfFocused: begin
      { Pass focus to current subview }
      if Current <> nil then
        Current.SetState(sfFocused, Enable);
    end;
    sfExposed: begin
      { Set exposed state on visible subviews }
      if Last <> nil then begin
        V := Last;
        repeat
          V := V.Next;
          if (V.State and sfVisible) <> 0 then
            V.SetState(sfExposed, Enable);
        until V = Last;
      end;
    end;
  end;
end;

procedure TGroup.GetData(var Rec);
var
  Total: Word;
  V: TView;
  RecBuf: PByte;
begin
  Total := 0;
  RecBuf := @Rec;
  if Last <> nil then begin
    V := Last;
    repeat
      V := V.Next;
      V.GetData(RecBuf[Total]);
      Inc(Total, V.DataSize);
    until V = Last;
  end;
end;

procedure TGroup.SetData(var Rec);
var
  Total: Word;
  V: TView;
  RecBuf: PByte;
begin
  Total := 0;
  RecBuf := @Rec;
  if Last <> nil then begin
    V := Last;
    repeat
      V := V.Next;
      V.SetData(RecBuf[Total]);
      Inc(Total, V.DataSize);
    until V = Last;
  end;
end;

procedure TGroup.EventError(var Event: TEvent);
begin
  if Owner <> nil then Owner.EventError(Event);
end;

procedure TGroup.HandleEvent(var Event: TEvent);

  function ContainsMouse(P: TView): Boolean;
  begin
    Result := (P.State and sfVisible <> 0) and P.MouseInView(Event.Where);
  end;

var
  V: TView;
begin
  { Call inherited TView.HandleEvent first - this handles focusing the group
    when clicked (for selectable groups like TWindow). }
  inherited HandleEvent(Event);

  { If event was cleared (e.g., by focusing), exit }
  if Event.What = evNothing then Exit;

  { Handle focused events (keyboard) }
  if Event.What and FocusedEvents <> 0 then begin
    Phase := phPreProcess;
    if Last <> nil then begin
      V := Last;
      repeat
        V := V.Next;
        if (V.Options and ofPreProcess <> 0) and (V.State and sfVisible <> 0) then
          V.HandleEvent(Event);
      until (V = Last) or (Event.What = evNothing);
    end;

    Phase := phFocused;
    if (Event.What <> evNothing) and (Current <> nil) then
      Current.HandleEvent(Event);

    Phase := phPostProcess;
    if Event.What <> evNothing then begin
      if Last <> nil then begin
        V := Last;
        repeat
          V := V.Next;
          if (V.Options and ofPostProcess <> 0) and (V.State and sfVisible <> 0) then
            V.HandleEvent(Event);
        until (V = Last) or (Event.What = evNothing);
      end;
    end;
    Exit;
  end;

  { Handle positional events (mouse) - route to first view containing mouse }
  if Event.What and PositionalEvents <> 0 then begin
    Phase := phFocused;
    { Find the topmost view containing the mouse }
    V := nil;
    if Last <> nil then begin
      V := Last;
      while True do begin
        if ContainsMouse(V) then
          Break;  { Found the topmost view containing mouse }
        V := V.Prev;
        if V = Last then begin
          V := nil;  { Wrapped around, nothing found }
          Break;
        end;
      end;
    end;
    if V <> nil then
      V.HandleEvent(Event);
    Exit;
  end;

  { For other events (broadcasts), pass to all views }
  Phase := phFocused;
  if Last <> nil then begin
    V := Last;
    repeat
      V := V.Next;
      if V.State and sfVisible <> 0 then
        V.HandleEvent(Event);
    until (V = Last) or (Event.What = evNothing);
  end;
end;

procedure TGroup.ChangeBounds(var Bounds: TRect);
var
  D: TPoint;
  V: TView;
  R: TRect;
begin
  D.X := (Bounds.B.X - Bounds.A.X) - Size.X;
  D.Y := (Bounds.B.Y - Bounds.A.Y) - Size.Y;
  if (D.X <> 0) or (D.Y <> 0) then begin
    Lock;
    if Last <> nil then begin
      V := Last;
      repeat
        V := V.Next;
        V.CalcBounds(R, D);
        V.ChangeBounds(R);
      until V = Last;
    end;
    UnLock;
  end;
  SetBounds(Bounds);
  GetExtent(Clip);
end;

function TGroup.IndexOf(P: TView): Integer;
var
  V: TView;
  I: Integer;
begin
  Result := 0;
  if Last <> nil then begin
    I := 0;
    V := Last;
    repeat
      V := V.Next;
      Inc(I);
      if V = P then begin
        Result := I;
        Exit;
      end;
    until V = Last;
  end;
end;

function TGroup.FindNext(Forwards: Boolean): TView;
var
  P: TView;
begin
  Result := nil;
  if Current <> nil then begin
    P := Current;
    repeat
      if Forwards then P := P.Next else P := P.Prev;
    until ((P.State and sfVisible <> 0) and (P.Options and ofSelectable <> 0)) or (P = Current);
    if P <> Current then Result := P;
  end;
end;

function TGroup.FirstMatch(AState: Word; AOptions: Word): TView;
var
  P: TView;
begin
  Result := nil;
  if Last <> nil then begin
    P := Last;
    repeat
      P := P.Next;
      if ((P.State and AState) = AState) and
         ((P.Options and AOptions) = AOptions) then begin
        Result := P;
        Exit;
      end;
    until P = Last;
  end;
end;

function TGroup.LastMatch(AState: Word; AOptions: Word): TView;
var
  P: TView;
begin
  { Find the topmost (closest to Last) view matching the criteria }
  Result := nil;
  if Last <> nil then begin
    P := Last;
    repeat
      if ((P.State and AState) = AState) and
         ((P.Options and AOptions) = AOptions) then begin
        Result := P;
        Exit;
      end;
      P := P.Prev;
    until P = Last;
  end;
end;

procedure TGroup.ResetCurrent;
begin
  { Find first visible+selectable view and make it current.
    SetCurrent has `if Current <> P` check, so if the same view is already
    Current, nothing happens. This matches FPC behavior. }
  SetCurrent(FirstMatch(sfVisible, ofSelectable), NormalSelect);
end;

procedure TGroup.RemoveView(P: TView);
var
  V: TView;
begin
  if Last <> nil then begin
    V := Last;
    while (V.Next <> P) and (V.Next <> Last) do V := V.Next;
    if V.Next = P then begin
      V.Next := P.Next;
      if P = Last then begin
        if V = P then Last := nil else Last := V;
      end;
    end;
  end;
end;

procedure TGroup.InsertView(P, Target: TView);
var
  PrevView: TView;
begin
  if P = nil then Exit;
  P.Owner := Self;
  if Target <> nil then begin
    { Insert P before Target }
    PrevView := Target.Prev;
    P.Next := PrevView.Next;  { P.Next = Target }
    PrevView.Next := P;
  end else begin
    { Insert P at end (becomes new Last, on top) }
    if Last <> nil then begin
      P.Next := Last.Next;  { P.Next = First }
      Last.Next := P;
    end else begin
      P.Next := P;  { First view, circular to self }
    end;
    Last := P;  { P is the new Last (topmost) }
  end;
end;

procedure TGroup.SetCurrent(P: TView; Mode: SelectMode);

  procedure SelectView(V: TView; Enable: Boolean);
  begin
    if V <> nil then
      V.SetState(sfSelected, Enable);
  end;

  procedure FocusView(V: TView; Enable: Boolean);
  begin
    { Only propagate focus if this group itself has sfFocused }
    if ((State and sfFocused) <> 0) and (V <> nil) then
      V.SetState(sfFocused, Enable);
  end;

begin
  if Current <> P then begin
    Lock;
    FocusView(Current, False);                        { Defocus old current }
    if Mode <> EnterSelect then
      SelectView(Current, False);                     { Deselect old current (unless EnterSelect) }
    if Mode <> LeaveSelect then
      SelectView(P, True);                            { Select new current }
    FocusView(P, True);                               { Focus new current }
    Current := P;                                     { Set current AFTER state changes }
    UnLock;
  end;
end;

procedure TGroup.DrawSubViews(P, Bottom: TView);
begin
  while P <> Bottom do begin
    P.DrawView;
    P := P.Next;
    if P = First then Break;
  end;
end;

{***************************************************************************}
{                             TFrame Object                                 }
{***************************************************************************}

constructor TFrame.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
  EventMask := EventMask or evBroadcast;
end;

function TFrame.GetPalette: PPalette;
const
  P: ShortString = CFrame;
begin
  Result := @P;
end;

procedure TFrame.Draw;
var
  CFrameColor, CTitle: Word;
  F, I, L, Width: Integer;
  B: TDrawBuffer;
  TitleStr: TTitleStr;
  WinFlags: Byte;
  ZoomChar: AnsiChar;
begin
  if (State and sfDragging) <> 0 then begin
    CFrameColor := $0505;
    CTitle := $0005;
    F := 0;
  end else if (State and sfActive) = 0 then begin
    CFrameColor := $0101;
    CTitle := $0002;
    F := 0;
  end else begin
    CFrameColor := $0503;
    CTitle := $0004;
    F := 9;
  end;

  CFrameColor := GetColor(CFrameColor);
  CTitle := GetColor(CTitle);
  Width := Size.X;
  L := Width - 2;
  if Owner <> nil then
    WinFlags := TWindow(Owner).Flags
  else
    WinFlags := 0;

  FrameLine(B, 0, F, Byte(CFrameColor));

  { Draw close button at position 2 if wfClose flag is set }
  if (WinFlags and wfClose <> 0) and (Width > 4) then begin
    MoveChar(B[2], '[', Byte(CFrameColor), 1);
    MoveChar(B[3], #254, Byte(CFrameColor), 1);  { close icon }
    MoveChar(B[4], ']', Byte(CFrameColor), 1);
  end;

  { Draw zoom button at right side if wfZoom flag is set }
  if (WinFlags and wfZoom <> 0) and (Width > 7) then begin
    { Check if window is currently zoomed (origin at 0,0 means zoomed/maximized) }
    if (Owner.Origin.X = 0) and (Owner.Origin.Y = 0) then
      ZoomChar := #18  { restore icon }
    else
      ZoomChar := #24; { maximize icon }
    MoveChar(B[Width - 5], '[', Byte(CFrameColor), 1);
    MoveChar(B[Width - 4], ZoomChar, Byte(CFrameColor), 1);
    MoveChar(B[Width - 3], ']', Byte(CFrameColor), 1);
  end;

  if (Owner <> nil) and (Width > 10) then begin
    TitleStr := TWindow(Owner).GetTitle(Width - 10);
    if TitleStr <> '' then begin
      L := Length(TitleStr);
      if L > Width - 10 then L := Width - 10;
      if L > 0 then begin
        I := (Width - L) shr 1;
        { Bounds check all array accesses }
        if (I > 0) and (I - 1 < MaxViewWidth) then
          MoveChar(B[I - 1], ' ', Byte(CTitle), 1);
        if (I >= 0) and (I < MaxViewWidth) then
          MoveStr(B[I], TitleStr, Byte(CTitle));
        if (I + L >= 0) and (I + L < MaxViewWidth) then
          MoveChar(B[I + L], ' ', Byte(CTitle), 1);
      end;
    end;
  end;

  WriteLine(0, 0, Width, 1, B);

  for I := 1 to Size.Y - 2 do begin
    FrameLine(B, I, F + 3, Byte(CFrameColor));
    WriteLine(0, I, Width, 1, B);
  end;

  FrameLine(B, Size.Y - 1, F + 6, Byte(CFrameColor));

  { Draw resize corner indicator if wfGrow flag is set }
  if (WinFlags and wfGrow <> 0) and (State and sfActive <> 0) then begin
    MoveChar(B[Width - 1], #188, Byte(CFrameColor), 1);  { resize corner }
  end;

  WriteLine(0, Size.Y - 1, Width, 1, B);
end;

procedure TFrame.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  WinFlags: Byte;
  Limits: TRect;
  MinP, MaxP: TPoint;

  procedure DragWindow(Mode: Byte);
  begin
    { Get limits from owner's owner (the desktop) }
    if Owner.Owner <> nil then
      Owner.Owner.GetExtent(Limits)
    else
      Owner.GetExtent(Limits);
    TWindow(Owner).SizeLimits(MinP, MaxP);
    Owner.DragView(Event, TWindow(Owner).DragMode or Mode, Limits, MinP, MaxP);
    ClearEvent(Event);
  end;

begin
  inherited HandleEvent(Event);
  if (Event.What = evMouseDown) and (Owner <> nil) then begin
    MakeLocal(Event.Where, Mouse);
    WinFlags := TWindow(Owner).Flags;

    if Mouse.Y = 0 then begin
      { Title bar click }
      { Check close button at positions 2-4 }
      if (WinFlags and wfClose <> 0) and (State and sfActive <> 0) and
         (Mouse.X >= 2) and (Mouse.X <= 4) then begin
        Event.What := evCommand;
        Event.Command := cmClose;
        Event.InfoPtr := Owner;
        PutEvent(Event);
        ClearEvent(Event);
      end
      { Check zoom button at positions Width-5 to Width-3 }
      else if (WinFlags and wfZoom <> 0) and (State and sfActive <> 0) and
              (Mouse.X >= Size.X - 5) and (Mouse.X <= Size.X - 3) then begin
        Event.What := evCommand;
        Event.Command := cmZoom;
        Event.InfoPtr := Owner;
        PutEvent(Event);
        ClearEvent(Event);
      end
      { Otherwise, drag move on title bar }
      else if (WinFlags and wfMove <> 0) then begin
        DragWindow(dmDragMove);
      end;
    end
    else if (State and sfActive <> 0) and (Mouse.X >= Size.X - 2) and
            (Mouse.Y >= Size.Y - 1) then begin
      { Bottom-right corner: resize }
      if (WinFlags and wfGrow <> 0) then begin
        DragWindow(dmDragGrow);
      end;
    end;
  end;
end;

procedure TFrame.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState and (sfActive + sfDragging) <> 0 then DrawView;
end;

procedure TFrame.FrameLine(var FrameBuf; Y, N: Integer; Color: Byte);
const
  { Frame characters: 3 chars per row (left, middle, right) }
  FrameChars: array[0..17] of AnsiChar = (
    ' ', ' ', ' ',           { 0,1,2: inactive/drag top }
    #179, ' ', #179,         { 3,4,5: inactive/drag side }
    #192, #196, #217,        { 6,7,8: inactive/drag bottom }
    #201, #205, #187,        { 9,10,11: active top }
    #186, ' ', #186,         { 12,13,14: active side }
    #200, #205, #188         { 15,16,17: active bottom }
  );
var
  Idx, W: Integer;
begin
  W := Size.X;
  if (W < 2) or (W >= MaxViewWidth) then Exit;
  Idx := N;
  if Idx < 0 then Idx := 0;
  if Idx > 15 then Idx := 15;
  MoveChar(TDrawBuffer(FrameBuf)[0], FrameChars[Idx], Color, 1);
  if W > 2 then
    MoveChar(TDrawBuffer(FrameBuf)[1], FrameChars[Idx + 1], Color, W - 2);
  MoveChar(TDrawBuffer(FrameBuf)[W - 1], FrameChars[Idx + 2], Color, 1);
end;

{***************************************************************************}
{                           TScrollBar Object                               }
{***************************************************************************}

constructor TScrollBar.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  Value := 0;
  Min := 0;
  Max := 0;
  PgStep := 1;
  ArStep := 1;
  if Size.X = 1 then begin
    GrowMode := gfGrowLoX + gfGrowHiX + gfGrowHiY;
    Chars[0] := #30;
    Chars[1] := #31;
    Chars[2] := #177;
    Chars[3] := #254;
    Chars[4] := #178;
  end else begin
    GrowMode := gfGrowLoY + gfGrowHiX + gfGrowHiY;
    Chars[0] := #17;
    Chars[1] := #16;
    Chars[2] := #177;
    Chars[3] := #254;
    Chars[4] := #178;
  end;
end;

function TScrollBar.GetPalette: PPalette;
const
  P: ShortString = CScrollBar;
begin
  Result := @P;
end;

function TScrollBar.ScrollStep(Part: Integer): Integer;
var
  Step: Integer;
begin
  Step := 0;
  case Part of
    sbUpArrow, sbLeftArrow: Step := -ArStep;
    sbDownArrow, sbRightArrow: Step := ArStep;
    sbPageUp, sbPageLeft: Step := -PgStep;
    sbPageDown, sbPageRight: Step := PgStep;
  end;
  Result := Step;
end;

procedure TScrollBar.Draw;
begin
  DrawPos(GetPos);
end;

procedure TScrollBar.ScrollDraw;
begin
  Message(Owner, evBroadcast, cmScrollBarChanged, Self);
end;

procedure TScrollBar.SetValue(AValue: Integer);
begin
  if AValue < Min then AValue := Min;
  if AValue > Max then AValue := Max;
  if Value <> AValue then begin
    Value := AValue;
    DrawView;
    ScrollDraw;
  end;
end;

procedure TScrollBar.SetRange(AMin, AMax: Integer);
begin
  Min := AMin;
  { Ensure Max >= Min to prevent negative scroll values }
  if AMax < AMin then
    Max := AMin
  else
    Max := AMax;
  if Value < Min then Value := Min;
  if Value > Max then Value := Max;
  DrawView;
end;

procedure TScrollBar.SetStep(APgStep, AArStep: Integer);
begin
  PgStep := APgStep;
  ArStep := AArStep;
end;

procedure TScrollBar.SetParams(AValue, AMin, AMax, APgStep, AArStep: Integer);
begin
  ArStep := AArStep;
  PgStep := APgStep;
  SetRange(AMin, AMax);
  SetValue(AValue);
end;

procedure TScrollBar.HandleEvent(var Event: TEvent);
var
  OldValue, NewValue: Integer;
  Part: Integer;
  Mouse: TPoint;
begin
  inherited HandleEvent(Event);
  if Event.What = evMouseDown then begin
    { Handle mouse wheel scrolling }
    if Event.Buttons and mbScrollWheelUp <> 0 then begin
      SetValue(Value - PgStep);
      ClearEvent(Event);
      Exit;
    end;
    if Event.Buttons and mbScrollWheelDown <> 0 then begin
      SetValue(Value + PgStep);
      ClearEvent(Event);
      Exit;
    end;
    OldValue := Value;
    MakeLocal(Event.Where, Mouse);
    if Size.X = 1 then begin
      if Mouse.Y = 0 then Part := sbUpArrow
      else if Mouse.Y = Size.Y - 1 then Part := sbDownArrow
      else if Mouse.Y < GetPos then Part := sbPageUp
      else if Mouse.Y > GetPos then Part := sbPageDown
      else Part := sbIndicator;
    end else begin
      if Mouse.X = 0 then Part := sbLeftArrow
      else if Mouse.X = Size.X - 1 then Part := sbRightArrow
      else if Mouse.X < GetPos then Part := sbPageLeft
      else if Mouse.X > GetPos then Part := sbPageRight
      else Part := sbIndicator;
    end;
    if Part = sbIndicator then begin
      repeat
        MakeLocal(Event.Where, Mouse);
        if Size.X = 1 then begin
          if Size.Y > 3 then
            NewValue := Self.Min + ((Mouse.Y - 1) * (Self.Max - Self.Min)) div (Size.Y - 3)
          else
            NewValue := Self.Min;
        end else begin
          if Size.X > 3 then
            NewValue := Self.Min + ((Mouse.X - 1) * (Self.Max - Self.Min)) div (Size.X - 3)
          else
            NewValue := Self.Min;
        end;
        SetValue(NewValue);
      until not MouseEvent(Event, evMouseMove);
    end else begin
      repeat
        MakeLocal(Event.Where, Mouse);
        SetValue(Value + ScrollStep(Part));
      until not MouseEvent(Event, evMouseAuto);
    end;
    ClearEvent(Event);
  end;
end;

function TScrollBar.GetPos: Integer;
var
  R: Integer;
begin
  R := Max - Min;
  if R = 0 then
    Result := 1
  else begin
    if Size.X = 1 then
      Result := ((Value - Min) * (Size.Y - 3)) div R + 1
    else
      Result := ((Value - Min) * (Size.X - 3)) div R + 1;
  end;
end;

function TScrollBar.GetSize: Integer;
begin
  if Size.X = 1 then Result := Size.Y else Result := Size.X;
end;

procedure TScrollBar.DrawPos(Pos: Integer);
var
  S: Integer;
  B: TDrawBuffer;
  C: Word;
begin
  S := GetSize - 1;
  if S < 0 then Exit; { Scrollbar too small to draw }
  C := GetColor($0201);
  { Draw left/top arrow }
  MoveChar(B[0], Chars[0], Byte(C), 1);
  { Draw track - only if there's room }
  if S >= 2 then begin
    MoveChar(B[1], Chars[2], Lo(C), S - 1);
    { Draw thumb }
    if (Pos > 0) and (Pos < S) and (Pos < MaxViewWidth) then begin
      MoveChar(B[Pos], Chars[3], Hi(C), 1);
    end;
  end;
  { Draw right/bottom arrow }
  if S < MaxViewWidth then
    MoveChar(B[S], Chars[1], Byte(C), 1);
  WriteBuf(0, 0, Size.X, Size.Y, B);
end;

{***************************************************************************}
{                            TScroller Object                               }
{***************************************************************************}

constructor TScroller.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar);
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable;
  EventMask := EventMask or evBroadcast;
  HScrollBar := AHScrollBar;
  VScrollBar := AVScrollBar;
  Delta.X := 0;
  Delta.Y := 0;
  Limit.X := 0;
  Limit.Y := 0;
end;

function TScroller.GetPalette: PPalette;
const
  P: ShortString = CScroller;
begin
  Result := @P;
end;

procedure TScroller.ScrollDraw;
begin
  if DrawLock = 0 then DrawView;
  DrawFlag := False;
end;

procedure TScroller.SetLimit(X, Y: Integer);
begin
  Limit.X := X;
  Limit.Y := Y;
  if HScrollBar <> nil then
    HScrollBar.SetParams(Delta.X, 0, X - Size.X, Size.X - 1, 1);
  if VScrollBar <> nil then
    VScrollBar.SetParams(Delta.Y, 0, Y - Size.Y, Size.Y - 1, 1);
end;

procedure TScroller.ScrollTo(X, Y: Integer);
begin
  Inc(DrawLock);
  if HScrollBar <> nil then HScrollBar.SetValue(X);
  if VScrollBar <> nil then VScrollBar.SetValue(Y);
  Dec(DrawLock);
  CheckDraw;
end;

procedure TScroller.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState and (sfSelected + sfActive)) <> 0 then begin
    if HScrollBar <> nil then
      if GetState(sfActive) then HScrollBar.Show else HScrollBar.Hide;
    if VScrollBar <> nil then
      if GetState(sfActive) then VScrollBar.Show else VScrollBar.Hide;
  end;
end;

procedure TScroller.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evMouseDown then begin
    { Handle mouse wheel scrolling }
    if (VScrollBar <> nil) and (Event.Buttons and (mbScrollWheelUp or mbScrollWheelDown) <> 0) then begin
      if Event.Buttons and mbScrollWheelUp <> 0 then
        VScrollBar.SetValue(VScrollBar.Value - VScrollBar.PgStep)
      else
        VScrollBar.SetValue(VScrollBar.Value + VScrollBar.PgStep);
      ClearEvent(Event);
    end;
  end
  else if Event.What = evBroadcast then begin
    if (Event.Command = cmScrollBarChanged) and
       ((Event.InfoPtr = HScrollBar) or (Event.InfoPtr = VScrollBar)) then begin
      if HScrollBar <> nil then Delta.X := HScrollBar.Value;
      if VScrollBar <> nil then Delta.Y := VScrollBar.Value;
      DrawFlag := True;
      CheckDraw;
    end;
  end;
end;

procedure TScroller.ChangeBounds(var Bounds: TRect);
begin
  SetBounds(Bounds);
  DrawLock := 1;
  SetLimit(Limit.X, Limit.Y);
  DrawLock := 0;
  DrawFlag := False;
  DrawView;
end;

procedure TScroller.CheckDraw;
begin
  if (DrawLock = 0) and DrawFlag then ScrollDraw;
end;

{***************************************************************************}
{                            TListViewer Object                             }
{***************************************************************************}

constructor TListViewer.Create(var Bounds: TRect; ANumCols: Word; AHScrollBar, AVScrollBar: TScrollBar);
var
  ArStep, PgStep: Integer;
begin
  inherited Create(Bounds);
  Options := Options or ofFirstClick or ofSelectable;
  EventMask := EventMask or evBroadcast;
  NumCols := ANumCols;
  if AVScrollBar <> nil then begin
    if NumCols = 1 then begin
      PgStep := Size.Y - 1;
      ArStep := 1;
    end else begin
      PgStep := Size.Y * NumCols;
      ArStep := Size.Y;
    end;
    AVScrollBar.SetStep(PgStep, ArStep);
  end;
  if AHScrollBar <> nil then
    AHScrollBar.SetStep(Size.X div NumCols, 1);
  HScrollBar := AHScrollBar;
  VScrollBar := AVScrollBar;
end;

function TListViewer.GetPalette: PPalette;
const
  P: string[Length(CListViewer)] = CListViewer;
begin
  GetPalette := PPalette(@P);
end;

function TListViewer.IsSelected(Item: Integer): Boolean;
begin
  Result := Item = Focused;
end;

function TListViewer.GetText(Item: Integer; MaxLen: Integer): string;
begin
  Result := '';
end;

procedure TListViewer.Draw;
var
  I, J, ColWidth, Item, Indent, CurCol: Integer;
  Color: Word;
  SCOff: Byte;
  Text: ShortString;
  B: TDrawBuffer;
begin
  ColWidth := Size.X div NumCols + 1;
  if HScrollBar = nil then Indent := 0
  else Indent := HScrollBar.Value;

  for I := 0 to Size.Y - 1 do begin
    for J := 0 to NumCols - 1 do begin
      Item := J * Size.Y + I + TopItem;
      CurCol := J * ColWidth;

      if (State and (sfSelected + sfActive) = (sfSelected + sfActive)) and
         (Focused = Item) and (Range > 0) then begin
        Color := GetColor(3);
        SetCursor(CurCol + 1, I);
        SCOff := 0;
      end else if (Item < Range) and IsSelected(Item) then begin
        Color := GetColor(4);
        SCOff := 2;
      end else begin
        Color := GetColor(2);
        SCOff := 4;
      end;

      MoveChar(B[CurCol], ' ', Color, ColWidth);
      if Item < Range then begin
        Text := GetText(Item, ColWidth + Indent);
        Text := Copy(Text, Indent + 1, ColWidth);
        MoveStr(B[CurCol + 1], Text, Color);
        if ShowMarkers then begin
          WordRec(B[CurCol]).Lo := Byte(SpecialChars[SCOff]);
          WordRec(B[CurCol + ColWidth - 2]).Lo := Byte(SpecialChars[SCOff + 1]);
        end;
      end;
      MoveChar(B[CurCol + ColWidth - 1], #179, GetColor(5), 1);
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TListViewer.FocusItem(Item: Integer);
begin
  Focused := Item;
  if VScrollBar <> nil then
    VScrollBar.SetValue(Item);
  if Item < TopItem then begin
    if NumCols = 1 then TopItem := Item
    else TopItem := Item - Item mod Size.Y;
  end else if Item >= TopItem + (Size.Y * NumCols) then begin
    if NumCols = 1 then TopItem := Item - Size.Y + 1
    else TopItem := Item - Item mod Size.Y - (Size.Y * (NumCols - 1));
  end;
end;

procedure TListViewer.SetTopItem(Item: Integer);
begin
  TopItem := Item;
end;

procedure TListViewer.SetRange(ARange: Integer);
begin
  Range := ARange;
  if VScrollBar <> nil then begin
    if Focused > ARange then Focused := 0;
    VScrollBar.SetParams(Focused, 0, ARange - 1, VScrollBar.PgStep, VScrollBar.ArStep);
  end;
end;

procedure TListViewer.SelectItem(Item: Integer);
begin
  Message(Owner, evBroadcast, cmListItemSelected, Self);
end;

procedure TListViewer.SetState(AState: Word; Enable: Boolean);

  procedure ShowSBar(SBar: TScrollBar);
  begin
    if SBar <> nil then begin
      if GetState(sfActive) and GetState(sfVisible) then
        SBar.Show
      else
        SBar.Hide;
    end;
  end;

begin
  inherited SetState(AState, Enable);
  if AState and (sfSelected + sfActive + sfVisible) <> 0 then begin
    DrawView;
    ShowSBar(HScrollBar);
    ShowSBar(VScrollBar);
  end;
end;

procedure TListViewer.HandleEvent(var Event: TEvent);
const
  MouseAutosToSkip = 4;
var
  Oi, Ni: Integer;
  Ct, Cw: Word;
  Mouse: TPoint;

  procedure MoveFocus(Req: Integer);
  begin
    FocusItemNum(Req);
    DrawView;
  end;

begin
  inherited HandleEvent(Event);
  case Event.What of
    evNothing: Exit;
    evKeyDown: begin
      if (Event.CharCode = ' ') and (Focused < Range) then begin
        SelectItem(Focused);
        Ni := Focused;
      end else case CtrlToArrow(Event.KeyCode) of
        kbUp: Ni := Focused - 1;
        kbDown: Ni := Focused + 1;
        kbRight: if NumCols > 1 then Ni := Focused + Size.Y else Exit;
        kbLeft: if NumCols > 1 then Ni := Focused - Size.Y else Exit;
        kbPgDn: Ni := Focused + Size.Y * NumCols;
        kbPgUp: Ni := Focused - Size.Y * NumCols;
        kbHome: Ni := TopItem;
        kbEnd: Ni := TopItem + (Size.Y * NumCols) - 1;
        kbCtrlPgDn: Ni := Range - 1;
        kbCtrlPgUp: Ni := 0;
        else Exit;
      end;
      MoveFocus(Ni);
      ClearEvent(Event);
    end;
    evBroadcast: begin
      if Options and ofSelectable <> 0 then begin
        if (Event.Command = cmScrollBarClicked) and
           ((Event.InfoPtr = HScrollBar) or (Event.InfoPtr = VScrollBar)) then
          Select
        else if Event.Command = cmScrollBarChanged then begin
          if VScrollBar = Event.InfoPtr then
            MoveFocus(VScrollBar.Value)
          else if HScrollBar = Event.InfoPtr then
            DrawView;
        end;
      end;
    end;
    evMouseDown: begin
      { Handle mouse wheel scrolling }
      if Event.Buttons and mbScrollWheelUp <> 0 then begin
        MoveFocus(Focused - 3);
        ClearEvent(Event);
        Exit;
      end;
      if Event.Buttons and mbScrollWheelDown <> 0 then begin
        MoveFocus(Focused + 3);
        ClearEvent(Event);
        Exit;
      end;
      Cw := Size.X div NumCols + 1;
      Oi := Focused;
      MakeLocal(Event.Where, Mouse);
      if MouseInView(Event.Where) then
        Ni := Mouse.Y + (Size.Y * (Mouse.X div Cw)) + TopItem
      else
        Ni := Oi;
      Ct := 0;
      repeat
        if Ni <> Oi then begin
          MoveFocus(Ni);
          Oi := Focused;
        end;
        MakeLocal(Event.Where, Mouse);
        if not MouseInView(Event.Where) then begin
          if Event.What = evMouseAuto then Inc(Ct);
          if Ct = MouseAutosToSkip then begin
            Ct := 0;
            if NumCols = 1 then begin
              if Mouse.Y < 0 then Ni := Focused - 1;
              if Mouse.Y >= Size.Y then Ni := Focused + 1;
            end else begin
              if Mouse.X < 0 then Ni := Focused - Size.Y;
              if Mouse.X >= Size.X then Ni := Focused + Size.Y;
              if Mouse.Y < 0 then Ni := Focused - Focused mod Size.Y;
              if Mouse.Y > Size.Y then Ni := Focused - Focused mod Size.Y + Size.Y - 1;
            end;
          end;
        end else
          Ni := Mouse.Y + (Size.Y * (Mouse.X div Cw)) + TopItem;
      until not MouseEvent(Event, evMouseMove + evMouseAuto);
      if Oi <> Ni then MoveFocus(Ni);
      if Event.Double and (Range > Focused) then
        SelectItem(Focused);
      ClearEvent(Event);
    end;
  end;
end;

procedure TListViewer.ChangeBounds(var Bounds: TRect);
begin
  inherited ChangeBounds(Bounds);
  if HScrollBar <> nil then
    HScrollBar.SetStep(Size.X div NumCols, HScrollBar.ArStep);
  if VScrollBar <> nil then
    VScrollBar.SetStep(Size.Y * NumCols, VScrollBar.ArStep);
end;

procedure TListViewer.FocusItemNum(Item: Integer);
begin
  if Item < 0 then Item := 0
  else if (Item >= Range) and (Range > 0) then Item := Range - 1;
  if Range <> 0 then FocusItem(Item);
end;

{***************************************************************************}
{                            TWindow Object                                 }
{***************************************************************************}

constructor TWindow.Create(var Bounds: TRect; ATitle: TTitleStr; ANumber: Integer);
begin
  inherited Create(Bounds);
  State := State or sfShadow;
  Options := Options or ofSelectable or ofFirstClick or ofTopSelect;
  GrowMode := gfGrowAll + gfGrowRel;
  Flags := wfMove + wfGrow + wfClose + wfZoom;
  Title := NewStr(ATitle);
  Number := ANumber;
  Palette := wpBlueWindow;
  InitFrame;
  if Frame <> nil then Insert(Frame);
  GetBounds(ZoomRect);
end;

destructor TWindow.Destroy;
begin
  DisposeStr(Title);
  inherited Destroy;
end;

function TWindow.GetPalette: PPalette;
const
  P: array[wpBlueWindow..wpGrayWindow] of ShortString =
    (CBlueWindow, CCyanWindow, CGrayWindow);
begin
  Result := @P[Palette];
end;

function TWindow.GetTitle(MaxSize: Integer): TTitleStr;
begin
  if Title <> nil then Result := Title^ else Result := '';
end;

function TWindow.StandardScrollBar(AOptions: Word): TScrollBar;
var
  R: TRect;
  S: TScrollBar;
begin
  GetExtent(R);
  if (AOptions and sbVertical) <> 0 then begin
    R.A.X := R.B.X - 1;
    Inc(R.A.Y);
    Dec(R.B.Y);
  end else begin
    Inc(R.A.X, 2);
    R.B.X := R.B.X - 2;
    R.A.Y := R.B.Y - 1;
  end;
  S := TScrollBar.Create(R);
  Insert(S);
  if (AOptions and sbHandleKeyboard) <> 0 then
    S.Options := S.Options or ofPostProcess;
  Result := S;
end;

procedure TWindow.Zoom;
var
  R: TRect;
  MaxP, MinP: TPoint;
begin
  SizeLimits(MinP, MaxP);
  { Check if window is NOT maximized (size differs from max) }
  if (Size.X <> MaxP.X) or (Size.Y <> MaxP.Y) then begin
    { Save current bounds for later restore }
    GetBounds(ZoomRect);
    { Maximize: set bounds to full area }
    R.A.X := 0;
    R.A.Y := 0;
    R.B := MaxP;
    Locate(R);
  end else begin
    { Already maximized: restore to saved bounds }
    Locate(ZoomRect);
  end;
end;

procedure TWindow.Close;
var
  App: TView;
begin
  if Valid(cmClose) then begin
    { Save reference to the application before freeing }
    App := Owner;
    while (App <> nil) and (App.Owner <> nil) do
      App := App.Owner;
    Free;
    { Redraw the entire application to fix any screen artifacts }
    if App <> nil then App.DrawView;
  end;
end;

procedure TWindow.InitFrame;
var
  R: TRect;
begin
  GetExtent(R);
  Frame := TFrame.Create(R);
end;

procedure TWindow.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState and sfSelected) <> 0 then begin
    SetState(sfActive, Enable);
    if Frame <> nil then Frame.SetState(sfActive, Enable);
  end;
end;

procedure TWindow.HandleEvent(var Event: TEvent);
var
  Limits: TRect;
  MinP, MaxP: TPoint;
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then begin
    case Event.Command of
      cmResize: begin
        if (Flags and wfMove <> 0) or (Flags and wfGrow <> 0) then begin
          if Owner <> nil then Owner.GetExtent(Limits);
          SizeLimits(MinP, MaxP);
          DragView(Event, Byte(Event.InfoInt), Limits, MinP, MaxP);
          ClearEvent(Event);
        end;
      end;
      cmClose: begin
        if (Flags and wfClose <> 0) and
           ((Event.InfoPtr = nil) or (Event.InfoPtr = Self)) then begin
          ClearEvent(Event);
          if (State and sfModal) = 0 then
            Close
          else begin
            Event.What := evCommand;
            Event.Command := cmCancel;
            PutEvent(Event);
            ClearEvent(Event);
          end;
        end;
      end;
      cmZoom: begin
        if ((Flags and wfZoom) <> 0) and
           ((Event.InfoPtr = nil) or (Event.InfoPtr = Self)) then begin
          Zoom;
          ClearEvent(Event);
        end;
      end;
    end;
  end else if Event.What = evKeyDown then begin
    case Event.KeyCode of
      kbTab: begin
        FocusNext(True);
        ClearEvent(Event);
      end;
      kbShiftTab: begin
        FocusNext(False);
        ClearEvent(Event);
      end;
    end;
  end else if Event.What = evBroadcast then begin
    if (Event.Command = cmSelectWindowNum) and
       (Event.InfoInt = Number) and
       (Options and ofSelectable <> 0) then begin
      Select;
      ClearEvent(Event);
    end;
  end;
end;

procedure TWindow.SizeLimits(var Min, Max: TPoint);
begin
  inherited SizeLimits(Min, Max);
  Min := MinWinSize;
end;

{***************************************************************************}
{                          Interface Routines                               }
{***************************************************************************}

function Message(Receiver: TView; What, Command: Word; InfoPtr: Pointer): Pointer;
var
  Event: TEvent;
begin
  Result := nil;
  if Receiver <> nil then begin
    Event.What := What;
    Event.Command := Command;
    Event.InfoPtr := InfoPtr;
    Receiver.HandleEvent(Event);
    if Event.What = evNothing then Result := Event.InfoPtr;
  end;
end;

function GetSubViewPtr(var S: TFVStream; OwnerGroup: TGroup): TView;
var
  Index: Word;
  V: TView;
  I: Word;
begin
  Result := nil;
  S.Read(Index, SizeOf(Index));
  if (Index > 0) and (OwnerGroup <> nil) then begin
    V := OwnerGroup.First;
    for I := 1 to Index - 1 do
      if V <> nil then V := V.Next;
    Result := V;
  end;
end;

procedure PutSubViewPtr(var S: TFVStream; P: TView);
var
  Index: Word;
begin
  if (P = nil) or (P.Owner = nil) then
    Index := 0
  else
    Index := P.Owner.IndexOf(P);
  S.Write(Index, SizeOf(Index));
end;

procedure RegisterViews;
begin
  { Registration stubs for compatibility }
end;

initialization
  CurCommandSet := [0..255];
  TheTopView := nil;
end.
