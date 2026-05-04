{*******************************************************}
{       Free Vision Dialogs Unit                        }
{       Delphi-compatible version                       }
{       Converted to CLASS syntax                       }
{*******************************************************}

unit Dialogs;

{$R-}

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections,
  FVCommon, Objects, Drivers, Views, fvconsts, Validate, HistList, FVBoxChars;

{***************************************************************************}
{                              PUBLIC CONSTANTS                             }
{***************************************************************************}

const
  { Dialog color palettes }
  CGrayDialog = #32#33#34#35#36#37#38#39#40#41#42#43#44#45#46#47 +
                #48#49#50#51#52#53#54#55#56#57#58#59#60#61#62#63;
  CBlueDialog = #64#65#66#67#68#69#70#71#72#73#74#75#76#77#78#79 +
                #80#81#82#83#84#85#86#87#88#89#90#91#92#92#94#95;
  CCyanDialog = #96#97#98#99#100#101#102#103#104#105#106#107#108 +
                #109#110#111#112#113#114#115#116#117#118#119#120 +
                #121#122#123#124#125#126#127;

  CStaticText    = #6#7#8#9;
  CLabel         = #7#8#9#9;
  CButton        = #10#11#12#13#14#14#14#15;
  CCluster       = #16#17#18#18#31#6;
  CInputLine     = #19#20#20#21#14;  { Passive, Active, Selected, Arrows, Arrows-disabled }
  CHistory       = #22#23;
  CHistoryWindow = #19#19#21#24#25#19#20;
  CHistoryViewer = #6#6#7#6#6;

  CDialog = CGrayDialog;

  { TDialog palette constants }
  dpBlueDialog = 0;
  dpCyanDialog = 1;
  dpGrayDialog = 2;

  { TButton flags }
  bfNormal    = $00;
  bfDefault   = $01;
  bfLeftJust  = $02;
  bfBroadcast = $04;
  bfGrabFocus = $08;

{***************************************************************************}
{                            TYPE DEFINITIONS                               }
{***************************************************************************}

type
  PSItem = ^TSItem;
  TSItem = record
    Value: string;
    Next: PSItem;
  end;

{***************************************************************************}
{                            CLASS DEFINITIONS                              }
{***************************************************************************}

type
  TInputLine = class(TView)
    MaxLen: Integer;
    CurPos: Integer;
    FirstPos: Integer;
    SelStart: Integer;
    SelEnd: Integer;
    Data: string;
    Validator: TValidator;
    constructor Create(var Bounds: TRect; AMaxLen: Integer); reintroduce; virtual;
    destructor Destroy; override;
    function DataSize: Word; override;
    function GetPalette: PPalette; override;
    function Valid(Command: Word): Boolean; override;
    procedure Draw; override;
    procedure DrawCursor; override;
    procedure SelectAll(Enable: Boolean);
    procedure SetValidator(AValid: TValidator);
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
    procedure HandleEvent(var Event: TEvent); override;
  private
    function CanScroll(Delta: Integer): Boolean;
    function ScreenCurPos: Integer;
  end;

  TButton = class(TView)
    AmDefault: Boolean;
    Flags: Byte;
    Command: Word;
    Title: string;
    constructor Create(var Bounds: TRect; ATitle: TTitleStr; ACommand: Word; AFlags: Word); reintroduce; virtual;
    destructor Destroy; override;
    function GetPalette: PPalette; override;
    procedure Press; virtual;
    procedure Draw; override;
    procedure DrawState(Down: Boolean);
    procedure MakeDefault(Enable: Boolean);
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure HandleEvent(var Event: TEvent); override;
  private
    DownFlag: Boolean;
  end;

  TCluster = class(TView)
    Id: Integer;
    Sel: Integer;
    Value: LongInt;
    EnableMask: LongInt;
    Strings: TStringList;
    constructor Create(var Bounds: TRect; AStrings: PSItem); reintroduce; virtual;
    destructor Destroy; override;
    function DataSize: Word; override;
    function GetHelpCtx: Word; override;
    function GetPalette: PPalette; override;
    function Mark(Item: Integer): Boolean; virtual;
    function MultiMark(Item: Integer): Byte; virtual;
    function ButtonState(Item: Integer): Boolean;
    procedure Draw; override;
    procedure Press(Item: Integer); virtual;
    procedure MovedTo(Item: Integer); virtual;
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure DrawMultiBox(const Icon, Marker: string);
    procedure DrawBox(const Icon: string; Marker: Char);
    procedure SetButtonState(AMask: LongInt; Enable: Boolean);
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
    procedure HandleEvent(var Event: TEvent); override;
  private
    function FindSel(P: TPoint): Integer;
    function Row(Item: Integer): Integer;
    function Column(Item: Integer): Integer;
  end;

  TRadioButtons = class(TCluster)
    function Mark(Item: Integer): Boolean; override;
    procedure Draw; override;
    procedure Press(Item: Integer); override;
    procedure MovedTo(Item: Integer); override;
    procedure SetData(var Rec); override;
  end;

  TCheckBoxes = class(TCluster)
    function Mark(Item: Integer): Boolean; override;
    procedure Draw; override;
    procedure Press(Item: Integer); override;
  end;

  TListBox = class(TListViewer)
    List: TObjectList<TObject>;
    constructor Create(var Bounds: TRect; ANumCols: Word; AScrollBar: TScrollBar); reintroduce; virtual;
    function DataSize: Word; override;
    function GetText(Item: Integer; MaxLen: Integer): string; override;
    procedure NewList(AList: TObjectList<TObject>); virtual;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
  end;

  { TStringListBox - A list box specifically for displaying string lists }
  TStringListBox = class(TListViewer)
    Strings: TStringList;
    constructor Create(var Bounds: TRect; ANumCols: Word; AScrollBar: TScrollBar); reintroduce; virtual;
    destructor Destroy; override;
    function DataSize: Word; override;
    function GetText(Item: Integer; MaxLen: Integer): string; override;
    procedure NewList(AStrings: TStringList); virtual;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
  end;

  TStaticText = class(TView)
    Text: string;
    constructor Create(var Bounds: TRect; const AText: string); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    destructor Destroy; override;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure GetText(var S: string); virtual;
    procedure Store(var S: TFVStream);
  end;

  TParamText = class(TStaticText)
    ParamCount: SmallInt;
    ParamList: Pointer;
    constructor Create(var Bounds: TRect; const AText: string; AParamCount: SmallInt); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    function DataSize: Word; override;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
    procedure Store(var S: TFVStream);
    procedure GetText(var S: string); override;
  end;

  TLabel = class(TStaticText)
    Light: Boolean;
    Link: TView;
    constructor Create(var Bounds: TRect; const AText: string; ALink: TView); reintroduce; virtual;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
  end;

  TDialog = class(TWindow)
    constructor Create(var Bounds: TRect; ATitle: TTitleStr); reintroduce; virtual;
    function GetPalette: PPalette; override;
    function Valid(Command: Word): Boolean; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Cancel(ACommand: Word); virtual;
    procedure ChangeTitle(ANewTitle: TTitleStr); virtual;
    procedure FreeSubView(ASubView: TView); virtual;
    procedure FreeAllSubViews; virtual;
    function IsSubView(AView: TView): Boolean; virtual;
    function NewButton(X, Y, W, H: Integer; ATitle: TTitleStr;
      ACommand, AHelpCtx: Word; AFlags: Byte): TButton;
    function NewLabel(X, Y: Integer; const AText: string; ALink: TView): TLabel;
    function NewInputLine(X, Y, W, AMaxLen: Integer; AHelpCtx: Word;
      AValidator: TValidator): TInputLine;
  end;

  { THistoryViewer - displays history list }
  THistoryViewer = class(TListViewer)
    HistoryId: Word;
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
      AHistoryId: Word); reintroduce; virtual;
    function HistoryWidth: Integer;
    function GetPalette: PPalette; override;
    function GetText(Item: Integer; MaxLen: Integer): string; override;
    procedure HandleEvent(var Event: TEvent); override;
  end;

  { THistoryWindow - popup window for history selection }
  THistoryWindow = class(TWindow)
    Viewer: TListViewer;
    constructor Create(var Bounds: TRect; AHistoryId: Word); reintroduce; virtual;
    function GetSelection: string; virtual;
    function GetPalette: PPalette; override;
    procedure InitViewer(AHistoryId: Word); virtual;
  end;

  { THistory - history dropdown button for input lines }
  THistory = class(TView)
    HistoryId: Word;
    Link: TInputLine;
    constructor Create(var Bounds: TRect; ALink: TInputLine; AHistoryId: Word); reintroduce; virtual;
    function GetPalette: PPalette; override;
    function InitHistoryWindow(var Bounds: TRect): THistoryWindow; virtual;
    procedure Draw; override;
    procedure RecordHistory(const S: string); virtual;
    procedure HandleEvent(var Event: TEvent); override;
  end;

function NewSItem(const Str: string; ANext: PSItem): PSItem;
function HotKey(const S: string): Char;
procedure RegisterDialogs;

implementation

uses
  FVUTF8;

const
  LeftArr: Char = SmallArrowLeft;
  RightArr: Char = SmallArrowRight;

{***************************************************************************}
{                           Utility Functions                               }
{***************************************************************************}

function NewSItem(const Str: string; ANext: PSItem): PSItem;
var
  P: PSItem;
begin
  New(P);
  P^.Value := string(Str);
  P^.Next := ANext;
  Result := P;
end;

function HotKey(const S: string): Char;
var
  I: Integer;
begin
  Result := #0;
  if S <> '' then begin
    I := Pos('~', S);
    if (I <> 0) and (I < Length(S)) then
      Result := UpCase(Char(S[I + 1]));
  end;
end;

{***************************************************************************}
{                         TInputLine Implementation                         }
{***************************************************************************}

constructor TInputLine.Create(var Bounds: TRect; AMaxLen: Integer);
begin
  inherited Create(Bounds);
  State := State or sfCursorVis;
  Options := Options or ofSelectable or ofFirstClick;
  MaxLen := AMaxLen;
  Data := '';
  CurPos := 0;
  FirstPos := 0;
  SelStart := 0;
  SelEnd := 0;
  Validator := nil;
end;

destructor TInputLine.Destroy;
begin
  { Data is now a managed string - no need to free }
  FreeAndNil(Validator);
  inherited Destroy;
end;

function TInputLine.DataSize: Word;
begin
  Result := MaxLen + 1;
end;

function TInputLine.GetPalette: PPalette;
const
  P: string[Length(CInputLine)] = CInputLine;
begin
  GetPalette := PPalette(@P);
end;

function TInputLine.Valid(Command: Word): Boolean;
begin
  Result := inherited Valid(Command);
  if Result and (Validator <> nil) then begin
    if Command = cmValid then
      Result := Validator.Status = vsOk
    else if Command <> cmCancel then
      if Validator.Options and voOnAppend = 0 then
        Result := Validator.Valid(ShortString(Data));
  end;
end;

function TInputLine.CanScroll(Delta: Integer): Boolean;
begin
  if Delta < 0 then
    Result := FirstPos > 0
  else if Delta > 0 then
    Result := Length(Data) - FirstPos + 2 > Size.X
  else
    Result := False;
end;

function TInputLine.ScreenCurPos: Integer;
begin
  Result := CurPos;
end;

procedure TInputLine.Draw;
var
  Color, ArrowColor: Byte;
  I, L, R: Integer;
  B: TDrawBuffer;
  DataStr: string;
begin
  if Options and ofSelectable = 0 then
    Color := GetColor(5)
  else if State and sfFocused = 0 then
    Color := GetColor(1)
  else
    Color := GetColor(2);
  ArrowColor := GetColor(4);

  { Fill with spaces in the field color }
  DrawChar(B, 0, ' ', Color, Size.X);

  { Show arrows only when content overflows }
  if CanScroll(1) then
    DrawChar(B, Size.X - 1, RightArr, ArrowColor, 1);

  if (State and sfFocused <> 0) and (Options and ofSelectable <> 0) then
    if CanScroll(-1) then
      DrawChar(B, 0, LeftArr, ArrowColor, 1);

  { Draw the data text }
  if Data <> '' then begin
    DataStr := Copy(Data, FirstPos + 1, Size.X - 2);
    DrawStr(B, 1, ShortString(DataStr), Color);
  end;

  { When focused, show selection and cursor }
  if (State and sfFocused <> 0) and (Options and ofSelectable <> 0) then begin
    L := SelStart - FirstPos;
    R := SelEnd - FirstPos;
    if L < 0 then L := 0;
    if R > Size.X - 2 then R := Size.X - 2;
    if L < R then
    begin
      { Change attribute only for selected range — preserve existing characters.
        Classic FV used #0 to mean "keep char, change attr" but modern TDrawCell
        stores Ch as a string, and #0 outputs as NUL to the terminal, causing
        the entire screen row to shift left. }
      for I := L to R - 1 do
        if (I + 1 >= 0) and (I + 1 < Size.X) then
          B[I + 1].Attr := GetColor(3);
    end;
    SetCursor(ScreenCurPos - FirstPos + 1, 0);
  end;
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TInputLine.DrawCursor;
begin
  if State and sfFocused <> 0 then begin
    Cursor.Y := 0;
    Cursor.X := ScreenCurPos - FirstPos + 1;
    ResetCursor;
  end;
end;

procedure TInputLine.SelectAll(Enable: Boolean);
begin
  CurPos := 0;
  FirstPos := 0;
  SelStart := 0;
  if Enable then
    SelEnd := Length(Data)
  else
    SelEnd := 0;
  DrawView;
end;

procedure TInputLine.SetValidator(AValid: TValidator);
begin
  FreeAndNil(Validator);
  Validator := AValid;
end;

procedure TInputLine.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState = sfSelected) or ((AState = sfActive) and (State and sfSelected <> 0)) then
    SelectAll(Enable)
  else if AState = sfFocused then
    DrawView;
end;

procedure TInputLine.GetData(var Rec);
var
  S: ShortString;
begin
  { Convert string to ShortString for backward compatibility }
  FillChar(Rec, DataSize, #0);
  S := ShortString(Copy(Data, 1, MaxLen));
  Move(S, Rec, Length(S) + 1);
end;

procedure TInputLine.SetData(var Rec);
var
  S: ShortString;
begin
  { Read ShortString from Rec and convert to string }
  Move(Rec, S[0], DataSize);
  Data := string(S);
  SelectAll(True);
end;

procedure TInputLine.HandleEvent(var Event: TEvent);
var
  Delta, Anchor: Integer;
  Mouse: TPoint;
  ExtendBlock: Boolean;

  function MouseDelta: Integer;
  begin
    MakeLocal(Event.Where, Mouse);
    if Mouse.X <= 0 then
      Result := -1
    else if Mouse.X >= Size.X - 1 then
      Result := 1
    else
      Result := 0;
  end;

  function MousePos: Integer;
  var
    Pos: Integer;
  begin
    MakeLocal(Event.Where, Mouse);
    if Mouse.X < 1 then Mouse.X := 1;
    Pos := Mouse.X + FirstPos - 1;
    if Pos < 0 then Pos := 0;
    if Pos > Length(Data) then Pos := Length(Data);
    Result := Pos;
  end;

  procedure DeleteSelect;
  begin
    if SelStart <> SelEnd then begin
      System.Delete(Data, SelStart + 1, SelEnd - SelStart);
      CurPos := SelStart;
    end;
  end;

  procedure AdjustSelectBlock;
  begin
    if CurPos < Anchor then begin
      SelStart := CurPos;
      SelEnd := Anchor;
    end else begin
      SelStart := Anchor;
      SelEnd := CurPos;
    end;
  end;

begin
  inherited HandleEvent(Event);
  if State and sfSelected <> 0 then begin
    case Event.What of
      evMouseDown: begin
        Delta := MouseDelta;
        if CanScroll(Delta) then begin
          repeat
            Inc(FirstPos, Delta);
            DrawView;
          until not MouseEvent(Event, evMouseAuto);
        end else if (Event.Buttons and mbLeftButton <> 0) then begin
          Anchor := MousePos;
          repeat
            if Event.Double then SelectAll(True)
            else begin
              CurPos := MousePos;
              if GetShiftState and $03 <> 0 then
                AdjustSelectBlock
              else begin
                SelStart := CurPos;
                SelEnd := CurPos;
              end;
            end;
            DrawView;
          until not MouseEvent(Event, evMouseMove);
        end;
        ClearEvent(Event);
      end;
      evKeyDown: begin
        case CtrlToArrow(Event.KeyCode) of
          kbLeft: if CurPos > 0 then Dec(CurPos);
          kbRight: if CurPos < Length(Data) then Inc(CurPos);
          kbHome: CurPos := 0;
          kbEnd: CurPos := Length(Data);
          kbBack: if CurPos > 0 then begin
            System.Delete(Data, CurPos, 1);
            Dec(CurPos);
            if FirstPos > 0 then Dec(FirstPos);
            SelStart := CurPos;
            SelEnd := CurPos;
          end;
          kbDel: begin
            if SelStart = SelEnd then begin
              if CurPos < Length(Data) then
                System.Delete(Data, CurPos + 1, 1);
            end else
              DeleteSelect;
            SelStart := CurPos;
            SelEnd := CurPos;
          end;
          kbIns: SetState(sfCursorIns, State and sfCursorIns = 0);
        else
          { Use UnicodeChar for full Unicode support }
          if Event.UnicodeChar >= ' ' then begin
            if (State and sfCursorIns <> 0) and (SelStart = SelEnd) and
               (CurPos < Length(Data)) then
              System.Delete(Data, CurPos + 1, 1);
            if SelStart <> SelEnd then DeleteSelect;
            if Length(Data) < MaxLen then begin
              Insert(Event.UnicodeChar, Data, CurPos + 1);
              Inc(CurPos);
            end;
            SelStart := CurPos;
            SelEnd := CurPos;
          end else
            Exit;
        end;
        if FirstPos > CurPos then FirstPos := CurPos;
        if CurPos - FirstPos > Size.X - 3 then FirstPos := CurPos - Size.X + 3;
        DrawView;
        ClearEvent(Event);
      end;
    end;
  end;
end;

{***************************************************************************}
{                         TButton Implementation                            }
{***************************************************************************}

constructor TButton.Create(var Bounds: TRect; ATitle: TTitleStr; ACommand: Word; AFlags: Word);
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick or ofPreProcess or ofPostProcess;
  EventMask := EventMask or evBroadcast;
  if AFlags and bfDefault <> 0 then begin
    AmDefault := True;
  end else
    AmDefault := False;
  Flags := Byte(AFlags);
  Command := ACommand;
  Title := ATitle;
  if not CommandEnabled(Command) then State := State or sfDisabled;
end;

destructor TButton.Destroy;
begin
  { Title is now a managed string - no need to free }
  inherited Destroy;
end;

function TButton.GetPalette: PPalette;
const
  P: string[Length(CButton)] = CButton;
begin
  GetPalette := PPalette(@P);
end;

procedure TButton.Press;
var
  E: TEvent;
begin
  Message(Owner, evBroadcast, cmRecordHistory, nil);
  if Flags and bfBroadcast <> 0 then
    Message(Owner, evBroadcast, Command, Self)
  else begin
    E.What := evCommand;
    E.Command := Command;
    E.InfoPtr := Self;
    PutEvent(E);
  end;
end;

procedure TButton.Draw;
begin
  DrawState(DownFlag);
end;

procedure TButton.DrawState(Down: Boolean);
var
  Bc, CShadow: Word;
  Db: TDrawBuffer;
  I, J, Pos: Integer;
  C: Char;
begin
  { Determine button color based on state }
  if State and sfDisabled <> 0 then
    Bc := GetColor($0404)
  else begin
    Bc := GetColor($0501);
    if State and sfActive <> 0 then begin
      if State and sfSelected <> 0 then
        Bc := GetColor($0703)
      else if AmDefault then
        Bc := GetColor($0602);
    end;
  end;

  CShadow := GetColor(8);

  { Handle empty title case }
  if Title = '' then begin
    DrawChar(Db, 0, ' ', Byte(CShadow), 1);
    for J := Ord(Down) to Size.X - 2 do
      DrawChar(Db, J, ' ', Byte(Bc), 1);
  end
  else begin
    { We have a title }
    if Flags and bfLeftJust = 0 then begin
      I := CStrLen(Title);
      I := (Size.X - I) div 2;
    end
    else
      I := 1;

    if Down then begin
      DrawChar(Db, 0, ' ', Byte(CShadow), 1);
      Pos := 1;
    end
    else
      Pos := 0;

    { Fill before title }
    for J := 0 to I - 1 do
      DrawChar(Db, Pos + J, ' ', Byte(Bc), 1);

    { Draw title }
    DrawCStr(Db, I + Pos, Title, Bc);

    { Fill after title }
    for J := Pos + CStrLen(Title) + I to Size.X - 2 do
      DrawChar(Db, J, ' ', Byte(Bc), 1);
  end;

  { Last column of row 0 }
  if not Down then begin
    { When not down: put block char at rightmost column for shadow effect }
    if Size.Y > 1 then
      DrawChar(Db, Size.X - 1, BlockLower, Byte(CShadow), 1)
    else
      DrawChar(Db, Size.X - 1, ' ', Byte(CShadow), 1);
  end
  else begin
    { When down: rightmost column is button color }
    DrawChar(Db, Size.X - 1, ' ', Byte(Bc), 1);
  end;

  { Write row 0 }
  WriteLine(0, 0, Size.X, 1, Db);

  { Handle second row if button height > 1 }
  if Size.Y > 1 then begin
    { Build bottom shadow row }
    DrawChar(Db, 0, ' ', Byte(CShadow), 1);
    if Down then
      C := ' '
    else
      C := BlockUpper;  { upper half block }
    DrawChar(Db, 1, C, Byte(CShadow), Size.X - 1);
    WriteLine(0, 1, Size.X, 1, Db);
  end;
end;

procedure TButton.MakeDefault(Enable: Boolean);
var
  C: Word;
begin
  if Flags and bfDefault = 0 then begin
    if Enable then
      C := cmGrabDefault
    else
      C := cmReleaseDefault;
    Message(Owner, evBroadcast, C, Self);
    AmDefault := Enable;
    DrawView;
  end;
end;

procedure TButton.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState and (sfSelected + sfActive) <> 0 then
    DrawView;
  if AState and sfFocused <> 0 then
    MakeDefault(Enable);
end;

procedure TButton.HandleEvent(var Event: TEvent);
var
  Down: Boolean;
  C: Char;
  Mouse: TPoint;
  ClickRect: TRect;
begin
  GetExtent(ClickRect);
  Inc(ClickRect.A.X);
  Dec(ClickRect.B.X);
  Dec(ClickRect.B.Y);
  if Event.What = evMouseDown then begin
    MakeLocal(Event.Where, Mouse);
    if not ClickRect.Contains(Mouse) then
      ClearEvent(Event);
  end;
  inherited HandleEvent(Event);
  case Event.What of
    evMouseDown: begin
      if State and sfDisabled = 0 then begin
        DownFlag := True;
        DrawView;
        repeat
          MakeLocal(Event.Where, Mouse);
          Down := ClickRect.Contains(Mouse);
          if Down <> DownFlag then begin
            DownFlag := Down;
            DrawView;
          end;
        until not MouseEvent(Event, evMouseMove);
        if DownFlag then begin
          Press;
          DownFlag := False;
          DrawView;
        end;
      end;
      ClearEvent(Event);
    end;
    evKeyDown: begin
      if Title <> '' then begin
        C := HotKey(Title);
        if (Event.KeyCode = GetAltCode(C)) or
           ((Owner.Phase = phPostProcess) and (C <> #0) and
            (UpCase(Char(Event.CharCode)) = C)) or
           ((State and sfFocused <> 0) and (Event.CharCode = AnsiChar(' '))) then begin
          Press;
          ClearEvent(Event);
        end;
      end;
    end;
    evBroadcast: begin
      case Event.Command of
        cmDefault: if AmDefault and (State and sfDisabled = 0) then begin
          Press;
          ClearEvent(Event);
        end;
        cmGrabDefault, cmReleaseDefault: if Flags and bfDefault <> 0 then begin
          AmDefault := Event.Command = cmReleaseDefault;
          DrawView;
        end;
        cmCommandSetChanged: begin
          SetState(sfDisabled, not CommandEnabled(Command));
          DrawView;
        end;
      end;
    end;
  end;
end;

{***************************************************************************}
{                         TCluster Implementation                           }
{***************************************************************************}

constructor TCluster.Create(var Bounds: TRect; AStrings: PSItem);
var
  P: PSItem;
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick or ofPreProcess or ofPostProcess;
  Strings := TStringList.Create;
  while AStrings <> nil do begin
    P := AStrings;
    Strings.Add(P^.Value);
    AStrings := P^.Next;
    { Value is now a managed string - no need to DisposeStr }
    Dispose(P);
  end;
  Value := 0;
  EnableMask := $FFFFFFFF;
  Sel := 0;
end;

destructor TCluster.Destroy;
begin
  FreeAndNil(Strings);
  inherited Destroy;
end;

function TCluster.DataSize: Word;
begin
  Result := SizeOf(Word);
end;

function TCluster.GetHelpCtx: Word;
begin
  if HelpCtx = hcNoContext then
    Result := hcNoContext
  else
    Result := HelpCtx + Sel;
end;

function TCluster.GetPalette: PPalette;
const
  P: string[Length(CCluster)] = CCluster;
begin
  GetPalette := PPalette(@P);
end;

function TCluster.Mark(Item: Integer): Boolean;
begin
  Result := False;
end;

function TCluster.MultiMark(Item: Integer): Byte;
begin
  if Mark(Item) then Result := 1 else Result := 0;
end;

function TCluster.ButtonState(Item: Integer): Boolean;
begin
  Result := (EnableMask and (1 shl Item)) <> 0;
end;

function TCluster.Row(Item: Integer): Integer;
begin
  Result := Item mod Size.Y;
end;

function TCluster.Column(Item: Integer): Integer;
begin
  Result := Item div Size.Y;
end;

function TCluster.FindSel(P: TPoint): Integer;
var
  I, S, Col: Integer;
begin
  Result := -1;
  MakeLocal(P, P);
  if (P.X >= 0) and (Strings <> nil) then begin
    Col := P.X * (Strings.Count div Size.Y + 1) div Size.X;
    S := Col * Size.Y;
    for I := 0 to Size.Y - 1 do
      if Row(S + I) = P.Y then begin
        if S + I < Strings.Count then
          Result := S + I;
        Exit;
      end;
  end;
end;

procedure TCluster.Draw;
begin
  DrawBox(' ( ) ', #7);
end;

procedure TCluster.DrawBox(const Icon: string; Marker: Char);
var
  I, J, Cur, Col: Integer;
  CNorm, CSel, CDis, Color: Word;
  B: TDrawBuffer;
  S: string;
  StringCount: Integer;
  UnicodeMarker: Char;
begin
  CNorm := GetColor($0301);
  CSel := GetColor($0402);
  CDis := GetColor($0505);

  if Strings <> nil then
    StringCount := Strings.Count
  else
    StringCount := 0;

  { Convert legacy marker to Unicode }
  case Marker of
    #7: UnicodeMarker := BulletPt;  { Unicode bullet for radio buttons }
  else
    UnicodeMarker := Marker;   { Use as-is (e.g., 'X' for checkboxes) }
  end;

  for I := 0 to Size.Y - 1 do begin
    DrawChar(B, 0, ' ', Byte(CNorm), Size.X);
    Col := 0;
    for J := 0 to (StringCount - 1) div Size.Y do begin
      Cur := J * Size.Y + I;
      if Cur < StringCount then begin
        if not ButtonState(Cur) then
          Color := CDis
        else if (Cur = Sel) and (State and sfFocused <> 0) then
          Color := CSel
        else
          Color := CNorm;

        DrawStr(B, Col, Icon, Byte(Color));
        if Mark(Cur) then
          { Use DrawChar to properly update both legacy and Unicode buffers }
          DrawChar(B, Col + 2, UnicodeMarker, Byte(Color), 1);

        S := Strings[Cur];
        DrawCStr(B, Col + CStrLen(Icon), S, Color);
        Inc(Col, CStrLen(Icon) + CStrLen(S) + 2);
      end;
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
  if StringCount > 0 then
    SetCursor(Column(Sel) * (Size.X div ((StringCount - 1) div Size.Y + 1)) + 2, Row(Sel));
end;

procedure TCluster.DrawMultiBox(const Icon, Marker: string);
begin
  if Length(Marker) > 0 then
    DrawBox(Icon, Marker[1])
  else
    DrawBox(Icon, ' ');
end;

procedure TCluster.SetButtonState(AMask: LongInt; Enable: Boolean);
begin
  if Enable then
    EnableMask := EnableMask or AMask
  else
    EnableMask := EnableMask and not AMask;
  DrawView;
end;

procedure TCluster.Press(Item: Integer);
begin
  Value := Value xor (1 shl Item);
end;

procedure TCluster.MovedTo(Item: Integer);
begin
  Sel := Item;
end;

procedure TCluster.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState and sfFocused <> 0 then
    DrawView;
end;

procedure TCluster.GetData(var Rec);
begin
  Word(Rec) := Word(Value);
end;

procedure TCluster.SetData(var Rec);
begin
  Value := Word(Rec);
  DrawView;
end;

procedure TCluster.HandleEvent(var Event: TEvent);
var
  I: Integer;
  S: string;
  C: Char;
  StringCount: Integer;
begin
  inherited HandleEvent(Event);
  if Options and ofSelectable = 0 then Exit;
  if Strings <> nil then
    StringCount := Strings.Count
  else
    StringCount := 0;
  case Event.What of
    evMouseDown: begin
      I := FindSel(Event.Where);
      if (I <> -1) and ButtonState(I) then begin
        Sel := I;
        Press(Sel);
        DrawView;
      end;
      ClearEvent(Event);
    end;
    evKeyDown: begin
      { Only handle arrow keys when we have focus }
      if State and sfFocused <> 0 then
        case CtrlToArrow(Event.KeyCode) of
          kbUp: if Sel > 0 then begin Dec(Sel); Press(Sel); DrawView; ClearEvent(Event); end;
          kbDown: if Sel < StringCount - 1 then begin Inc(Sel); Press(Sel); DrawView; ClearEvent(Event); end;
          kbRight: if Sel + Size.Y < StringCount then begin
            Inc(Sel, Size.Y);
            Press(Sel);
            DrawView;
            ClearEvent(Event);
          end;
          kbLeft: if Sel >= Size.Y then begin
            Dec(Sel, Size.Y);
            Press(Sel);
            DrawView;
            ClearEvent(Event);
          end;
        end;
      if Event.What = evNothing then Exit;
      { Handle hotkeys in any phase }
      for I := 0 to StringCount - 1 do begin
        S := Strings[I];
        C := HotKey(S);
        if (GetAltCode(C) = Event.KeyCode) or
           ((Owner.Phase = phPostProcess) and (C <> #0) and
            (UpCase(Char(Event.CharCode)) = C)) then begin
          if ButtonState(I) then begin
            if Focus then begin
              Sel := I;
              Press(I);
              DrawView;
            end;
          end;
          ClearEvent(Event);
          Exit;
        end;
      end;
      { Handle space only when focused }
      if (State and sfFocused <> 0) and (Event.CharCode = ' ') then begin
        Press(Sel);
        DrawView;
        ClearEvent(Event);
      end;
    end;
  end;
end;

{***************************************************************************}
{                      TRadioButtons Implementation                         }
{***************************************************************************}

function TRadioButtons.Mark(Item: Integer): Boolean;
begin
  Result := Item = Value;
end;

procedure TRadioButtons.Draw;
begin
  DrawBox(' ( ) ', #7);
end;

procedure TRadioButtons.Press(Item: Integer);
begin
  Value := Item;
end;

procedure TRadioButtons.MovedTo(Item: Integer);
begin
  Value := Item;
  inherited MovedTo(Item);
end;

procedure TRadioButtons.SetData(var Rec);
begin
  Sel := Integer(Rec);
  Value := Sel;
  DrawView;
end;

{***************************************************************************}
{                       TCheckBoxes Implementation                          }
{***************************************************************************}

function TCheckBoxes.Mark(Item: Integer): Boolean;
begin
  Result := (Value and (1 shl Item)) <> 0;
end;

procedure TCheckBoxes.Draw;
begin
  DrawBox(' [ ] ', 'X');
end;

procedure TCheckBoxes.Press(Item: Integer);
begin
  Value := Value xor (1 shl Item);
end;

{***************************************************************************}
{                         TListBox Implementation                           }
{***************************************************************************}

constructor TListBox.Create(var Bounds: TRect; ANumCols: Word; AScrollBar: TScrollBar);
begin
  inherited Create(Bounds, ANumCols, nil, AScrollBar);
  List := nil;
end;

function TListBox.DataSize: Word;
begin
  Result := SizeOf(Pointer);
end;

function TListBox.GetText(Item: Integer; MaxLen: Integer): string;
begin
  { Base implementation returns empty string.
    Subclasses (TFileList, TDirListBox) override this to extract text from their items.
    For simple string lists, use TStringListBox instead. }
  Result := '';
end;

procedure TListBox.NewList(AList: TObjectList<TObject>);
begin
  FreeAndNil(List);
  List := AList;
  if AList <> nil then
    SetRange(AList.Count)
  else
    SetRange(0);
  if Range > 0 then
    FocusItem(0);
  DrawView;
end;

procedure TListBox.GetData(var Rec);
begin
  TObjectList<TObject>(Rec) := List;
end;

procedure TListBox.SetData(var Rec);
begin
  NewList(TObjectList<TObject>(Rec));
end;

{***************************************************************************}
{                      TStringListBox Implementation                        }
{***************************************************************************}

constructor TStringListBox.Create(var Bounds: TRect; ANumCols: Word; AScrollBar: TScrollBar);
begin
  inherited Create(Bounds, ANumCols, nil, AScrollBar);
  Strings := nil;
end;

destructor TStringListBox.Destroy;
begin
  FreeAndNil(Strings);
  inherited Destroy;
end;

function TStringListBox.DataSize: Word;
begin
  Result := SizeOf(Pointer);
end;

function TStringListBox.GetText(Item: Integer; MaxLen: Integer): string;
begin
  if (Strings <> nil) and (Item < Strings.Count) then
    Result := CopyDisplayCells(Strings[Item], 0, MaxLen)
  else
    Result := '';
end;

procedure TStringListBox.NewList(AStrings: TStringList);
begin
  FreeAndNil(Strings);
  Strings := AStrings;
  if AStrings <> nil then
    SetRange(AStrings.Count)
  else
    SetRange(0);
  if Range > 0 then
    FocusItem(0);
  DrawView;
end;

procedure TStringListBox.GetData(var Rec);
begin
  TStringList(Rec) := Strings;
end;

procedure TStringListBox.SetData(var Rec);
begin
  NewList(TStringList(Rec));
end;

{***************************************************************************}
{                       TStaticText Implementation                          }
{***************************************************************************}

constructor TStaticText.Create(var Bounds: TRect; const AText: string);
begin
  inherited Create(Bounds);
  Text := string(AText);
end;

constructor TStaticText.Load(var S: TFVStream);
begin
  inherited Load(S);
  Text := S.ReadStr;
end;

destructor TStaticText.Destroy;
begin
  { Text is now a managed string - no need to free }
  inherited Destroy;
end;

function TStaticText.GetPalette: PPalette;
const
  P: string[Length(CStaticText)] = CStaticText;
begin
  GetPalette := PPalette(@P);
end;

procedure TStaticText.GetText(var S: string);
begin
  S := Text;
end;

procedure TStaticText.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.WriteStr(Text);
end;

procedure TStaticText.Draw;
var
  Color: Byte;
  Center: Boolean;
  I, J, L, P, Y: Integer;
  LineWidth: Integer;
  B: TDrawBuffer;
  S: string;
begin
  Color := GetColor(1);
  GetText(S);
  L := Length(S);
  P := 1;
  Y := 0;
  Center := False;
  while Y < Size.Y do begin
    DrawChar(B, 0, ' ', Color, Size.X);
    if P <= L then begin
      if S[P] = #3 then begin
        Center := True;
        Inc(P);
      end;
      I := P;
      repeat
        J := P;
        while (P <= L) and (S[P] = ' ') do Inc(P);
        while (P <= L) and (S[P] <> ' ') and (S[P] <> #13) do Inc(P);
      until (P > L) or (StringDisplayWidth(Copy(S, I, P - I)) >= Size.X) or (S[P] = #13);
      if StringDisplayWidth(Copy(S, I, P - I)) > Size.X then
        if J > I then
          P := J
        else begin
          { Find exact cutoff point by display width }
          P := I;
          while (P <= L) and (StringDisplayWidth(Copy(S, I, P - I + 1)) <= Size.X) do
            Inc(P);
        end;
      LineWidth := StringDisplayWidth(Copy(S, I, P - I));
      if Center then
        J := (Size.X - LineWidth) div 2
      else
        J := 0;
      DrawStr(B, J, Copy(S, I, P - I), Color);
      while (P <= L) and (S[P] = ' ') do Inc(P);
      if (P <= L) and (S[P] = #13) then begin
        Center := False;
        Inc(P);
        if (P <= L) and (S[P] = #10) then Inc(P);
      end;
    end;
    WriteLine(0, Y, Size.X, 1, B);
    Inc(Y);
  end;
end;

{***************************************************************************}
{                         TParamText Implementation                         }
{***************************************************************************}

constructor TParamText.Create(var Bounds: TRect; const AText: string; AParamCount: SmallInt);
begin
  inherited Create(Bounds, AText);
  ParamCount := AParamCount;
  ParamList := nil;
end;

constructor TParamText.Load(var S: TFVStream);
var
  W: Word;
begin
  inherited Load(S);
  S.Read(W, SizeOf(W));
  ParamCount := W;
  ParamList := nil;
end;

function TParamText.DataSize: Word;
begin
  Result := ParamCount * SizeOf(Pointer);
end;

procedure TParamText.GetData(var Rec);
begin
  Pointer(Rec) := @ParamList;
end;

procedure TParamText.SetData(var Rec);
begin
  ParamList := @Rec;
  DrawView;
end;

procedure TParamText.Store(var S: TFVStream);
var
  W: Word;
begin
  inherited Store(S);
  W := ParamCount;
  S.Write(W, SizeOf(W));
end;

procedure TParamText.GetText(var S: string);
begin
  if Text = '' then
    S := ''
  else if ParamList = nil then
    S := Text
  else begin
    { Note: ParamList should be an array of TVarRec for System.Format }
    { For now, just use the text without formatting if ParamList is set }
    S := Text;
  end;
end;

{***************************************************************************}
{                          TLabel Implementation                            }
{***************************************************************************}

constructor TLabel.Create(var Bounds: TRect; const AText: string; ALink: TView);
begin
  inherited Create(Bounds, AText);
  Link := ALink;
  Light := False;
  Options := Options or ofPreProcess or ofPostProcess;
  EventMask := EventMask or evBroadcast;
end;

function TLabel.GetPalette: PPalette;
const
  P: string[Length(CLabel)] = CLabel;
begin
  GetPalette := PPalette(@P);
end;

procedure TLabel.Draw;
var
  Color: Word;
  B: TDrawBuffer;
  SCOff: Byte;
begin
  if Light then begin
    Color := GetColor($0402);
    SCOff := 0;
  end else begin
    Color := GetColor($0301);
    SCOff := 4;
  end;
  DrawChar(B, 0, ' ', Byte(Color), Size.X);
  if Text <> '' then begin
    DrawCStr(B, 1, Text, Color);
    if ShowMarkers then begin
      { Use DrawChar to properly update both legacy and Unicode buffers }
      DrawChar(B, 0, SpecialChars[SCOff], Byte(Color), 1);
    end;
  end;
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TLabel.HandleEvent(var Event: TEvent);
var
  C: Char;
  FocusMe: Boolean;
begin
  inherited HandleEvent(Event);
  if Event.What = evMouseDown then begin
    if Link <> nil then Link.Focus;
    ClearEvent(Event);
  end else if Event.What = evKeyDown then begin
    if Text <> '' then begin
      C := HotKey(Text);
      if (GetAltCode(C) = Event.KeyCode) or
         ((Owner.Phase = phPostProcess) and (C <> #0) and
          (UpCase(Char(Event.CharCode)) = C)) then begin
        if Link <> nil then begin
          Link.Focus;
          ClearEvent(Event);
        end;
      end;
    end;
  end else if Event.What = evBroadcast then begin
    if (Event.Command = cmReceivedFocus) or (Event.Command = cmReleasedFocus) then begin
      if Link <> nil then begin
        FocusMe := (Event.Command = cmReceivedFocus) and (Event.InfoPtr = Pointer(Link));
        Light := FocusMe;
        DrawView;
      end;
    end;
  end;
end;

{***************************************************************************}
{                          TDialog Implementation                           }
{***************************************************************************}

constructor TDialog.Create(var Bounds: TRect; ATitle: TTitleStr);
begin
  inherited Create(Bounds, ATitle, wnNoNumber);
  Options := Options or ofVersion20;
  GrowMode := 0;
  Flags := wfMove + wfClose;
  Palette := dpGrayDialog;
end;

function TDialog.GetPalette: PPalette;
const
  P: array[dpBlueDialog..dpGrayDialog] of string[Length(CBlueDialog)] =
    (CBlueDialog, CCyanDialog, CGrayDialog);
begin
  GetPalette := PPalette(@P[Palette]);
end;

function TDialog.Valid(Command: Word): Boolean;
begin
  if Command = cmCancel then
    Result := True
  else
    Result := inherited Valid(Command);
end;

procedure TDialog.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  case Event.What of
    evNothing: Exit;
    evKeyDown: case Event.KeyCode of
      kbEsc, kbCtrlF4: begin
        Event.What := evCommand;
        Event.Command := cmCancel;
        Event.InfoPtr := nil;
        PutEvent(Event);
        ClearEvent(Event);
      end;
      kbCtrlF5: begin
        if State and sfModal <> 0 then begin
          Event.What := evCommand;
          Event.Command := cmResize;
          Event.InfoPtr := nil;
          PutEvent(Event);
          ClearEvent(Event);
        end;
      end;
      kbEnter: begin
        Event.What := evBroadcast;
        Event.Command := cmDefault;
        Event.InfoPtr := nil;
        PutEvent(Event);
        ClearEvent(Event);
      end;
    end;
    evCommand: case Event.Command of
      cmOk, cmCancel, cmYes, cmNo: if State and sfModal <> 0 then begin
        EndModal(Event.Command);
        ClearEvent(Event);
      end;
    end;
  end;
end;

procedure TDialog.Cancel(ACommand: Word);
begin
  if State and sfModal = sfModal then
    EndModal(ACommand)
  else
    Close;
end;

procedure TDialog.ChangeTitle(ANewTitle: TTitleStr);
begin
  Title := ANewTitle;
  Frame.DrawView;
end;

procedure TDialog.FreeSubView(ASubView: TView);
begin
  if IsSubView(ASubView) then begin
    Delete(ASubView);
    FreeAndNil(ASubView);
    DrawView;
  end;
end;

procedure TDialog.FreeAllSubViews;
var
  P: TView;
begin
  P := First;
  repeat
    P := First;
    if P <> nil then begin
      Delete(P);
      FreeAndNil(P);
    end;
  until P = nil;
  DrawView;
end;

function TDialog.IsSubView(AView: TView): Boolean;
var
  P: TView;
begin
  P := First;
  while (P <> nil) and (P <> AView) do
    P := P.Next;
  Result := (P <> nil) and (P = AView);
end;

function TDialog.NewButton(X, Y, W, H: Integer; ATitle: TTitleStr;
  ACommand, AHelpCtx: Word; AFlags: Byte): TButton;
var
  B: TButton;
  R: TRect;
begin
  R.Assign(X, Y, X + W, Y + H);
  B := TButton.Create(R, ATitle, ACommand, AFlags);
  if B <> nil then begin
    B.HelpCtx := AHelpCtx;
    Insert(B);
  end;
  Result := B;
end;

function TDialog.NewLabel(X, Y: Integer; const AText: string; ALink: TView): TLabel;
var
  L: TLabel;
  R: TRect;
begin
  R.Assign(X, Y, X + CStrDisplayWidth(AText) + 1, Y + 1);
  L := TLabel.Create(R, AText, ALink);
  if L <> nil then
    Insert(L);
  Result := L;
end;

function TDialog.NewInputLine(X, Y, W, AMaxLen: Integer; AHelpCtx: Word;
  AValidator: TValidator): TInputLine;
var
  P: TInputLine;
  R: TRect;
begin
  R.Assign(X, Y, X + W, Y + 1);
  P := TInputLine.Create(R, AMaxLen);
  if P <> nil then begin
    P.SetValidator(AValidator);
    P.HelpCtx := AHelpCtx;
    Insert(P);
  end;
  Result := P;
end;

{***************************************************************************}
{                      THistoryViewer Implementation                        }
{***************************************************************************}

constructor THistoryViewer.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
  AHistoryId: Word);
begin
  inherited Create(Bounds, 1, AHScrollBar, AVScrollBar);
  HistoryId := AHistoryId;
  SetRange(HistoryCount(AHistoryId));
  if Range > 1 then FocusItem(1);
  if HScrollBar <> nil then
    HScrollBar.SetRange(1, HistoryWidth - Size.X + 3);
end;

function THistoryViewer.HistoryWidth: Integer;
var
  Width, T, ACount, I: Integer;
begin
  Width := 0;
  ACount := HistoryCount(HistoryId);
  for I := 0 to ACount - 1 do begin
    T := StringDisplayWidth(HistoryStr(HistoryId, I));
    if T > Width then Width := T;
  end;
  Result := Width;
end;

function THistoryViewer.GetPalette: PPalette;
const
  P: string[Length(CHistoryViewer)] = CHistoryViewer;
begin
  GetPalette := PPalette(@P);
end;

function THistoryViewer.GetText(Item: Integer; MaxLen: Integer): string;
begin
  Result := HistoryStr(HistoryId, Item);
end;

procedure THistoryViewer.HandleEvent(var Event: TEvent);
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

{***************************************************************************}
{                      THistoryWindow Implementation                        }
{***************************************************************************}

constructor THistoryWindow.Create(var Bounds: TRect; AHistoryId: Word);
begin
  inherited Create(Bounds, '', wnNoNumber);
  Flags := wfClose;
  InitViewer(AHistoryId);
end;

function THistoryWindow.GetSelection: string;
begin
  if Viewer = nil then
    Result := ''
  else
    Result := Viewer.GetText(Viewer.Focused, 255);
end;

function THistoryWindow.GetPalette: PPalette;
const
  P: string[Length(CHistoryWindow)] = CHistoryWindow;
begin
  GetPalette := PPalette(@P);
end;

procedure THistoryWindow.InitViewer(AHistoryId: Word);
var
  R: TRect;
begin
  GetExtent(R);
  R.Grow(-1, -1);
  Viewer := THistoryViewer.Create(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    AHistoryId);
  if Viewer <> nil then Insert(Viewer);
end;

{***************************************************************************}
{                         THistory Implementation                           }
{***************************************************************************}

constructor THistory.Create(var Bounds: TRect; ALink: TInputLine; AHistoryId: Word);
begin
  inherited Create(Bounds);
  Options := Options or ofPostProcess;
  EventMask := EventMask or evBroadcast;
  Link := ALink;
  HistoryId := AHistoryId;
end;

function THistory.GetPalette: PPalette;
const
  P: string[Length(CHistory)] = CHistory;
begin
  GetPalette := PPalette(@P);
end;

function THistory.InitHistoryWindow(var Bounds: TRect): THistoryWindow;
var
  W: THistoryWindow;
begin
  W := THistoryWindow.Create(Bounds, HistoryId);
  if (W <> nil) and (Link <> nil) then
    W.HelpCtx := Link.HelpCtx;
  Result := W;
end;

procedure THistory.Draw;
var
  B: TDrawBuffer;
begin
  DrawCStr(B, 0, '[~v~]', GetColor($0102));
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure THistory.RecordHistory(const S: string);
begin
  HistoryAdd(HistoryId, S);
end;

procedure THistory.HandleEvent(var Event: TEvent);
var
  C: Word;
  Rslt: string;
  R, P: TRect;
  HistoryWindow: THistoryWindow;
begin
  inherited HandleEvent(Event);
  if Link = nil then Exit;
  if (Event.What = evMouseDown) or
     ((Event.What = evKeyDown) and
      (CtrlToArrow(Event.KeyCode) = kbDown) and
      (Link.State and sfFocused <> 0)) then begin
    if not Link.Focus then begin
      ClearEvent(Event);
      Exit;
    end;
    RecordHistory(Link.Data);
    Link.GetBounds(R);
    Dec(R.A.X);
    Inc(R.B.X);
    Inc(R.B.Y, 7);
    Dec(R.A.Y, 1);
    Owner.GetExtent(P);
    R.Intersect(P);
    Dec(R.B.Y, 1);
    HistoryWindow := InitHistoryWindow(R);
    if HistoryWindow <> nil then begin
      C := Owner.ExecView(HistoryWindow);
      if C = cmOk then begin
        Rslt := HistoryWindow.GetSelection;
        if Length(Rslt) > Link.MaxLen then
          SetLength(Rslt, Link.MaxLen);
        Link.Data := Rslt;
        Link.SelectAll(True);
        Link.DrawView;
      end;
      FreeAndNil(HistoryWindow);
    end;
    ClearEvent(Event);
  end else if Event.What = evBroadcast then begin
    if ((Event.Command = cmReleasedFocus) and (Event.InfoPtr = Pointer(Link))) or
       (Event.Command = cmRecordHistory) then begin
      RecordHistory(Link.Data);
    end;
  end;
end;

{***************************************************************************}
{                           Registration                                    }
{***************************************************************************}

procedure RegisterDialogs;
begin
  { Stream registration would go here }
end;

end.
