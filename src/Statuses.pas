{*******************************************************}
{       Free Vision - Status Views Unit                 }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  The Statuses unit implements several views for providing information to
  the user which needs to be updated during program execution, such as a
  progress indicator, gauges, spinners, etc. All status views respond to
  a new message event class, evStatus. An individual status view only
  processes an event with its associated command.

  Original: Written by Brad Williams, DVM
  Ported to Delphi: December 2025
}

unit Statuses;

interface

uses
  FVCommon, FVConsts, Objects, Drivers, Views, Dialogs, FVBoxChars;

const
  { Event class for status views }
  evStatus = $8000;

  { Palette for status views in windows/dialogs }
  CStatus = #1#2#3;

  { Palette for status views in application }
  CAppStatus = #2#5#4;

  { Palette for bar gauge - adds empty and filled bar colors }
  CBarGauge: ShortString = #1#2#3#16#19;

  { Button flags for TStatusDlg }
  sdNone         = $0000;
  sdCancelButton = $0001;
  sdPauseButton  = $0002;
  sdResumeButton = $0004;
  sdAllButtons   = sdCancelButton or sdPauseButton or sdResumeButton;

  { Spinner animation characters: | / - \ using Unicode box drawing }
  SpinChars: string = #$2502'/'#$2500'\';

  { State flag for paused status }
  sfPause = $F000;

type
  { Forward declarations }
  TStatus = class;
  TStatusDlg = class;
  TStatusMessageDlg = class;
  TGauge = class;
  TArrowGauge = class;
  TPercentGauge = class;
  TBarGauge = class;
  TSpinnerGauge = class;
  TAppStatus = class;

  { TStatus - Base status view class }
  TStatus = class(TParamText)
  private
    FCommand: Word;
  public
    constructor Create(var R: TRect; ACommand: Word; const AText: ShortString;
                       AParamCount: SmallInt); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    function Cancel: Boolean; virtual;
    function GetPalette: PPalette; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Pause; virtual;
    procedure Reset; virtual;
    procedure Resume; virtual;
    procedure Store(var S: TFVStream);
    procedure Update(Data: Pointer); virtual;
    property Command: Word read FCommand write FCommand;
  end;

  { TStatusDlg - Dialog with status view and optional buttons }
  TStatusDlg = class(TDialog)
  private
    FStatus: TStatus;
  public
    constructor Create(const ATitle: TTitleStr; AStatus: TStatus; AFlags: Word); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    procedure Cancel(ACommand: Word); override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure InsertButtons(AFlags: Word); virtual;
    procedure Store(var S: TFVStream);
    property Status: TStatus read FStatus write FStatus;
  end;

  { TStatusMessageDlg - Status dialog with message text }
  TStatusMessageDlg = class(TStatusDlg)
  public
    constructor Create(const ATitle: TTitleStr; AStatus: TStatus; AFlags: Word;
                       const AMessage: ShortString); reintroduce; virtual;
  end;

  { TGaugeRec - Record for TGauge data }
  PGaugeRec = ^TGaugeRec;
  TGaugeRec = record
    Min, Max, Current: LongInt;
  end;

  { TGauge - Numerical gauge }
  TGauge = class(TStatus)
  private
    FMin: LongInt;
    FMax: LongInt;
    FCurrent: LongInt;
  public
    constructor Create(var R: TRect; ACommand: Word; AMin, AMax: LongInt); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    procedure Draw; override;
    procedure GetData(var Rec); override;
    procedure Reset; override;
    procedure SetData(var Rec); override;
    procedure Store(var S: TFVStream);
    procedure Update(Data: Pointer); override;
    property Min: LongInt read FMin write FMin;
    property Max: LongInt read FMax write FMax;
    property Current: LongInt read FCurrent write FCurrent;
  end;

  { TArrowGaugeRec - Record for TArrowGauge data }
  PArrowGaugeRec = ^TArrowGaugeRec;
  TArrowGaugeRec = record
    Min, Max, Count: LongInt;
    Right: Boolean;
  end;

  { TArrowGauge - Arrow-based progress indicator }
  TArrowGauge = class(TGauge)
  private
    FRight: Boolean;
  public
    constructor Create(var R: TRect; ACommand: Word; AMin, AMax: Word;
                       RightArrow: Boolean); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    procedure Draw; override;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
    procedure Store(var S: TFVStream);
    property Right: Boolean read FRight write FRight;
  end;

  { TPercentGauge - Percentage display gauge }
  TPercentGauge = class(TGauge)
  public
    function Percent: SmallInt; virtual;
    procedure Draw; override;
  end;

  { TBarGauge - Progress bar with percentage }
  TBarGauge = class(TPercentGauge)
  public
    procedure Draw; override;
    function GetPalette: PPalette; override;
  end;

  { TSpinnerGauge - Spinning animation indicator }
  TSpinnerGauge = class(TGauge)
  public
    constructor Create(X, Y: SmallInt; ACommand: Word); reintroduce; virtual;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Update(Data: Pointer); override;
  end;

  { TAppStatus - Status for application (different palette) }
  TAppStatus = class(TStatus)
  public
    function GetPalette: PPalette; override;
  end;

{ Stream registration records }
{ Note: Only types with their own Load/Store have registration records }
const
  RStatus: TStreamRec = (
    ObjType: idStatus;
    VmtLink: nil;
    Load: @TStatus.Load;
    Store: @TStatus.Store);

  RStatusDlg: TStreamRec = (
    ObjType: idStatusDlg;
    VmtLink: nil;
    Load: @TStatusDlg.Load;
    Store: @TStatusDlg.Store);

  RGauge: TStreamRec = (
    ObjType: idGauge;
    VmtLink: nil;
    Load: @TGauge.Load;
    Store: @TGauge.Store);

  RArrowGauge: TStreamRec = (
    ObjType: idArrowGauge;
    VmtLink: nil;
    Load: @TArrowGauge.Load;
    Store: @TArrowGauge.Store);

procedure RegisterStatuses;

implementation

uses
  System.SysUtils, MsgBox, App;

{****************************************************************************}
{ TStatus Object                                                             }
{****************************************************************************}

constructor TStatus.Create(var R: TRect; ACommand: Word; const AText: ShortString;
                           AParamCount: SmallInt);
begin
  inherited Create(R, AText, AParamCount);
  EventMask := EventMask or evStatus;
  FCommand := ACommand;
end;

constructor TStatus.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(FCommand, SizeOf(FCommand));
end;

function TStatus.Cancel: Boolean;
begin
  Result := True;
end;

function TStatus.GetPalette: PPalette;
const
  P: ShortString = CStatus;
begin
  Result := PPalette(@P);
end;

procedure TStatus.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evCommand) and (Event.Command = cmStatusPause) then
  begin
    Pause;
    ClearEvent(Event);
  end;

  case Event.What of
    evStatus:
      case Event.Command of
        cmStatusDone:
          if Event.InfoPtr = Self then
          begin
            Message(Owner, evStatus, cmStatusDone, Self);
            ClearEvent(Event);
          end;
        cmStatusUpdate:
          if (Event.InfoWord = FCommand) and ((State and sfPause) = 0) then
          begin
            Update(Event.InfoPtr);
            { Don't clear event so multiple status views can respond }
          end;
        cmStatusResume:
          if (Event.InfoWord = FCommand) and ((State and sfPause) = sfPause) then
          begin
            Resume;
            ClearEvent(Event);
          end;
        cmStatusPause:
          if (Event.InfoWord = FCommand) and ((State and sfPause) = 0) then
          begin
            Pause;
            ClearEvent(Event);
          end;
      end;
  end;

  inherited HandleEvent(Event);
end;

procedure TStatus.Pause;
begin
  SetState(sfPause, True);
end;

procedure TStatus.Reset;
begin
  DrawView;
end;

procedure TStatus.Resume;
begin
  SetState(sfPause, False);
end;

procedure TStatus.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(FCommand, SizeOf(FCommand));
end;

procedure TStatus.Update(Data: Pointer);
begin
  if Data <> nil then
    Text := string(PAnsiChar(Data))
  else
    Text := '';
  DrawView;
end;

{****************************************************************************}
{ TStatusDlg Class                                                           }
{****************************************************************************}

constructor TStatusDlg.Create(const ATitle: TTitleStr; AStatus: TStatus; AFlags: Word);
var
  R: TRect;
begin
  R.A := AStatus.Origin;
  R.B := AStatus.Size;
  Inc(R.B.Y, R.A.Y + 4);
  Inc(R.B.X, R.A.X + 5);

  inherited Create(R, ATitle);
  EventMask := EventMask or evStatus;
  FStatus := AStatus;
  FStatus.MoveTo(2, 2);
  Insert(FStatus);
  InsertButtons(AFlags);
end;

constructor TStatusDlg.Load(var S: TFVStream);
begin
  inherited Load(S);
  FStatus := TStatus(GetSubViewPtr(S, Self));
end;

procedure TStatusDlg.Cancel(ACommand: Word);
begin
  if FStatus.Cancel then
    inherited Cancel(ACommand);
end;

procedure TStatusDlg.HandleEvent(var Event: TEvent);
begin
  case Event.What of
    evStatus:
      case Event.Command of
        cmStatusDone:
          if Event.InfoPtr = FStatus then
          begin
            inherited Cancel(cmOK);
            ClearEvent(Event);
          end;
      end;
    evBroadcast, evCommand:
      case Event.Command of
        cmCancel, cmClose:
          begin
            Cancel(cmCancel);
            ClearEvent(Event);
          end;
        cmStatusPause:
          begin
            FStatus.Pause;
            ClearEvent(Event);
          end;
        cmStatusResume:
          begin
            FStatus.Resume;
            ClearEvent(Event);
          end;
      end;
  end;

  inherited HandleEvent(Event);
end;

procedure TStatusDlg.InsertButtons(AFlags: Word);
var
  P: TButton;
  Buttons: Byte;
  X, Y, Gap: SmallInt;
begin
  Buttons := Byte((AFlags and sdCancelButton) = sdCancelButton);
  { Add 2 for Pause and Resume buttons }
  Inc(Buttons, 2 * Byte((AFlags and sdPauseButton) = sdPauseButton));

  if Buttons > 0 then
  begin
    FStatus.GrowMode := gfGrowHiX;

    { Resize dialog to hold all requested buttons }
    if Size.X < (Buttons * 12) + 2 then
      GrowTo((Buttons * 12) + 2, Size.Y + 2)
    else
      GrowTo(Size.X, Size.Y + 2);

    { Find correct starting position for first button }
    Gap := Size.X - (Buttons * 10) - 2;
    Gap := Gap div (Buttons + 1);
    X := Gap;
    if X < 2 then
      X := 2;
    Y := Size.Y - 3;

    { Insert buttons }
    if (AFlags and sdCancelButton) = sdCancelButton then
    begin
      P := NewButton(X, Y, 10, 2, 'Cancel', cmCancel, hcCancel, bfDefault);
      P.GrowMode := gfGrowHiY or gfGrowLoY;
      Inc(X, 12 + Gap);
    end;

    if (AFlags and sdPauseButton) = sdPauseButton then
    begin
      P := NewButton(X, Y, 10, 2, '~P~ause', cmStatusPause, hcStatusPause, bfNormal);
      P.GrowMode := gfGrowHiY or gfGrowLoY;
      Inc(X, 12 + Gap);
      P := NewButton(X, Y, 10, 2, '~R~esume', cmStatusResume, hcStatusResume, bfBroadcast);
      P.GrowMode := gfGrowHiY or gfGrowLoY;
    end;
  end;

  SelectNext(False);
end;

procedure TStatusDlg.Store(var S: TFVStream);
begin
  inherited Store(S);
  PutSubViewPtr(S, FStatus);
end;

{****************************************************************************}
{ TStatusMessageDlg Class                                                    }
{****************************************************************************}

constructor TStatusMessageDlg.Create(const ATitle: TTitleStr; AStatus: TStatus;
                                     AFlags: Word; const AMessage: ShortString);
var
  P: TStaticText;
  X, Y: SmallInt;
  R: TRect;
begin
  inherited Create(ATitle, AStatus, AFlags);

  FStatus.GrowMode := gfGrowLoY or gfGrowHiY;
  GetExtent(R);

  X := R.B.X - R.A.X;
  if X < Size.X then
    X := Size.X;
  Y := R.B.Y - R.A.Y;
  if Y < Size.Y then
    Y := Size.Y;
  GrowTo(X, Y);

  R.Assign(2, 2, Size.X - 2, Size.Y - 3);
  P := TStaticText.Create(R, AMessage);
  GrowTo(Size.X, Size.Y + P.Size.Y + 1);
  Insert(P);
end;

{****************************************************************************}
{ TGauge Class                                                               }
{****************************************************************************}

constructor TGauge.Create(var R: TRect; ACommand: Word; AMin, AMax: LongInt);
begin
  inherited Create(R, ACommand, '', 1);
  FMin := AMin;
  FMax := AMax;
  FCurrent := FMin;
end;

constructor TGauge.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(FMin, SizeOf(FMin));
  S.Read(FMax, SizeOf(FMax));
  S.Read(FCurrent, SizeOf(FCurrent));
end;

procedure TGauge.Draw;
var
  S: string;
  B: TDrawBuffer;
begin
  { Blank the gauge }
  DrawChar(B, 0, ' ', GetColor(1), Size.X);
  { Write current status }
  S := Format('%d', [FCurrent]);
  DrawStr(B, 0, S, GetColor(1));
  WriteBuf(0, 0, Size.X, Size.Y, B);
end;

procedure TGauge.GetData(var Rec);
begin
  TGaugeRec(Rec).Min := FMin;
  TGaugeRec(Rec).Max := FMax;
  TGaugeRec(Rec).Current := FCurrent;
end;

procedure TGauge.Reset;
begin
  FCurrent := FMin;
  DrawView;
end;

procedure TGauge.SetData(var Rec);
begin
  FMin := TGaugeRec(Rec).Min;
  FMax := TGaugeRec(Rec).Max;
  FCurrent := TGaugeRec(Rec).Current;
end;

procedure TGauge.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(FMin, SizeOf(FMin));
  S.Write(FMax, SizeOf(FMax));
  S.Write(FCurrent, SizeOf(FCurrent));
end;

procedure TGauge.Update(Data: Pointer);
begin
  if FCurrent < FMax then
  begin
    Inc(FCurrent);
    DrawView;
  end
  else
    Message(Self, evStatus, cmStatusDone, Self);
end;

{****************************************************************************}
{ TArrowGauge Class                                                          }
{****************************************************************************}

constructor TArrowGauge.Create(var R: TRect; ACommand: Word; AMin, AMax: Word;
                               RightArrow: Boolean);
begin
  inherited Create(R, ACommand, AMin, AMax);
  FRight := RightArrow;
end;

constructor TArrowGauge.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(FRight, SizeOf(FRight));
end;

procedure TArrowGauge.Draw;
const
  Arrows: array[Boolean] of Char = ('<', '>');
var
  B: TDrawBuffer;
  C: Word;
  Len: SmallInt;
  Range: LongInt;
begin
  C := GetColor(1);
  Range := FMax - FMin;
  if Range <= 0 then Range := 1;
  Len := Round(Size.X * FCurrent / Range);
  if Len > Size.X then Len := Size.X;
  if Len < 0 then Len := 0;

  DrawChar(B, 0, ' ', Byte(C), Size.X);
  if FRight then
    DrawChar(B, 0, Arrows[FRight], Byte(C), Len)
  else
    DrawChar(B, Size.X - Len, Arrows[FRight], Byte(C), Len);
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TArrowGauge.GetData(var Rec);
begin
  TArrowGaugeRec(Rec).Min := FMin;
  TArrowGaugeRec(Rec).Max := FMax;
  TArrowGaugeRec(Rec).Count := FCurrent;
  TArrowGaugeRec(Rec).Right := FRight;
end;

procedure TArrowGauge.SetData(var Rec);
begin
  FMin := TArrowGaugeRec(Rec).Min;
  FMax := TArrowGaugeRec(Rec).Max;
  FCurrent := TArrowGaugeRec(Rec).Count;
  FRight := TArrowGaugeRec(Rec).Right;
end;

procedure TArrowGauge.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(FRight, SizeOf(FRight));
end;

{****************************************************************************}
{ TPercentGauge Class                                                        }
{****************************************************************************}

function TPercentGauge.Percent: SmallInt;
begin
  if FMax = 0 then
    Result := 0
  else
    Result := Round((FCurrent / FMax) * 100);
end;

procedure TPercentGauge.Draw;
var
  B: TDrawBuffer;
  C: Word;
  S: string;
  PercentDone: LongInt;
  CenterPos: SmallInt;
begin
  C := GetColor(1);
  DrawChar(B, 0, ' ', Byte(C), Size.X);
  PercentDone := Percent;
  S := Format('%d%%', [PercentDone]);
  CenterPos := (Size.X - Length(S)) div 2;
  if CenterPos < 0 then CenterPos := 0;
  DrawStr(B, CenterPos, S, Byte(C));
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

{****************************************************************************}
{ TBarGauge Class                                                            }
{****************************************************************************}

procedure TBarGauge.Draw;
var
  B: TDrawBuffer;
  C: Word;
  FillSize: SmallInt;
  PercentDone: LongInt;
  S: string;
  CenterPos: SmallInt;
begin
  { Fill entire view with empty bar color }
  DrawChar(B, 0, ' ', GetColor(4), Size.X);

  { Make progress bar with filled color }
  C := GetColor(5);
  if FMax > 0 then
    FillSize := Round(Size.X * (FCurrent / FMax))
  else
    FillSize := 0;
  if FillSize > Size.X then FillSize := Size.X;
  if FillSize < 0 then FillSize := 0;
  DrawChar(B, 0, ' ', Byte(C), FillSize);

  { Display percent done in center }
  PercentDone := Percent;
  S := Format('%d%%', [PercentDone]);
  { Use empty bar color for text if less than 50% }
  if PercentDone < 50 then
    C := GetColor(4);
  CenterPos := (Size.X - Length(S)) div 2;
  if CenterPos < 0 then CenterPos := 0;
  DrawStr(B, CenterPos, S, Byte(C));

  WriteLine(0, 0, Size.X, Size.Y, B);
end;

function TBarGauge.GetPalette: PPalette;
const
  S: ShortString = #1#2#3#16#19;  { CBarGauge }
begin
  Result := PPalette(@S);
end;

{****************************************************************************}
{ TSpinnerGauge Class                                                        }
{****************************************************************************}

constructor TSpinnerGauge.Create(X, Y: SmallInt; ACommand: Word);
var
  R: TRect;
begin
  R.Assign(X, Y, X + 1, Y + 1);
  inherited Create(R, ACommand, 1, 4);
end;

procedure TSpinnerGauge.Draw;
var
  B: TDrawBuffer;
  C: Word;
begin
  C := GetColor(1);
  DrawChar(B, 0, ' ', Byte(C), Size.X);
  { SpinChars is 1-based, FCurrent ranges from 1 to 4 }
  if (FCurrent >= 1) and (FCurrent <= Length(SpinChars)) then
    DrawChar(B, Size.X div 2, SpinChars[FCurrent], Byte(C), 1);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TSpinnerGauge.HandleEvent(var Event: TEvent);
begin
  { Call inherited HandleEvent to avoid cmStatusDone when FCurrent = FMax }
  inherited HandleEvent(Event);
end;

procedure TSpinnerGauge.Update(Data: Pointer);
begin
  if FCurrent = FMax then
    FCurrent := FMin
  else
    Inc(FCurrent);
  DrawView;
end;

{****************************************************************************}
{ TAppStatus Class                                                           }
{****************************************************************************}

function TAppStatus.GetPalette: PPalette;
const
  P: ShortString = CAppStatus;
begin
  Result := PPalette(@P);
end;

{****************************************************************************}
{ Global procedures                                                          }
{****************************************************************************}

procedure RegisterStatuses;
begin
  RegisterType(RStatus);
  RegisterType(RStatusDlg);
  RegisterType(RGauge);
  RegisterType(RArrowGauge);
end;

end.
