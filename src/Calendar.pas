{*******************************************************}
{       Free Vision - Calendar Unit                    }
{       TCalendarView - Text-mode calendar control     }
{*******************************************************}

unit Calendar;

interface

uses
  FVConsts, Objects, Drivers, Views;

type
  { Day color configuration - one color index per day of week }
  TDayColors = array[0..6] of Byte;  { 0=Sunday, 1=Monday, ..., 6=Saturday }

  { Forward declaration for callback type }
  TCalendarView = class;

  { Callback for date selection events }
  TCalendarDateEvent = procedure(Calendar: TCalendarView) of object;

  TCalendarView = class(TView)
  private
    FYear: Word;
    FMonth: Word;
    FDay: Word;
    FFirstDayOfWeek: Byte;     { 0=Sunday, 1=Monday, etc. }
    FDayColors: TDayColors;    { Color indices for each weekday }
    FUseDayColors: Boolean;    { Whether to use custom day colors }
    FOnDateSelect: TCalendarDateEvent;  { Called when date is selected }
    function DaysInMonth(AYear, AMonth: Word): Word;
    function DayOfWeek(AYear, AMonth, ADay: Word): Word;
    function IsLeapYear(AYear: Word): Boolean;
    procedure SelectDate;
    procedure ClampDay;
    procedure ShowMonthMenu;
    procedure ShowYearMenu;
    function GetDayHeaderStr: string;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    constructor CreateWithDate(var Bounds: TRect; AYear, AMonth, ADay: Word); virtual;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    function GetDate(var AYear, AMonth, ADay: Word): Boolean;
    procedure SetDate(AYear, AMonth, ADay: Word);
    procedure SetFirstDayOfWeek(AFirstDay: Byte);
    procedure SetDayColor(ADayOfWeek: Byte; AColorIndex: Byte);
    procedure NextMonth;
    procedure PrevMonth;
    procedure NextYear;
    procedure PrevYear;
    property Year: Word read FYear write FYear;
    property Month: Word read FMonth write FMonth;
    property Day: Word read FDay write FDay;
    property FirstDayOfWeek: Byte read FFirstDayOfWeek write FFirstDayOfWeek;
    property UseDayColors: Boolean read FUseDayColors write FUseDayColors;
    property OnDateSelect: TCalendarDateEvent read FOnDateSelect write FOnDateSelect;
  end;

const
  CCalendarView = #6#7#8#4#5;  { Normal, Selected, Title, Arrow, Weekend }

  { Short day names for headers }
  DayNamesShort: array[0..6] of string = (
    'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'
  );

implementation

uses
  SysUtils, App;

const
  MonthNames: array[1..12] of string = (
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  );

  DaysPerMonth: array[1..12] of Byte = (
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
  );

type
  { Simple list menu for month/year selection }
  TCalendarMenu = class(TView)
  private
    FItems: array[0..15] of string;
    FItemCount: Integer;
    FSelected: Integer;
    FSelection: Integer;
    FEndState: Word;
  public
    constructor Create(var Bounds: TRect; const AItems: array of string); reintroduce; virtual;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    function Execute: Word; override;
    function GetPalette: PPalette; override;
    property Items: string read FItems[0];
    property ItemCount: Integer read FItemCount write FItemCount;
    property Selected: Integer read FSelected write FSelected;
    property Selection: Integer read FSelection write FSelection;
    property EndState: Word read FEndState write FEndState;
  end;

const
  { Use same palette as menus: indices 2,3,4,5,6,7 from app palette }
  CCalendarMenu = #2#3#4#5#6#7;

constructor TCalendarMenu.Create(var Bounds: TRect; const AItems: array of string);
var
  I: Integer;
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick or ofTopSelect;
  EventMask := evMouseDown or evKeyDown or evCommand;
  State := State or sfModal;
  FItemCount := High(AItems) - Low(AItems) + 1;
  if FItemCount > 16 then FItemCount := 16;
  for I := 0 to FItemCount - 1 do
    FItems[I] := AItems[I];
  FSelected := 0;
  FSelection := -1;
  FEndState := 0;
end;

function TCalendarMenu.Execute: Word;
var
  E: TEvent;
begin
  FEndState := 0;
  repeat
    GetEvent(E);
    HandleEvent(E);
  until FEndState <> 0;
  Result := FEndState;
end;

function TCalendarMenu.GetPalette: PPalette;
const
  P: ShortString = CCalendarMenu;
begin
  GetPalette := @P;
end;

procedure TCalendarMenu.Draw;
var
  B: TDrawBuffer;
  CNormal, CSelect: Word;
  I: Integer;
begin
  { Use menu-style color mapping through palette }
  CNormal := GetColor($0301);  { Normal: indices 1 and 3 }
  CSelect := GetColor($0604);  { Selected: indices 4 and 6 }

  for I := 0 to FItemCount - 1 do begin
    DrawChar(B, 0, ' ', Byte(CNormal), Size.X);
    if I = FSelected then
      DrawStr(B, 1, FItems[I], Byte(CSelect))
    else
      DrawStr(B, 1, FItems[I], Byte(CNormal));
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TCalendarMenu.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
begin
  inherited HandleEvent(Event);

  case Event.What of
    evMouseDown: begin
      MakeLocal(Event.Where, Mouse);
      if (Mouse.Y >= 0) and (Mouse.Y < FItemCount) then begin
        FSelected := Mouse.Y;
        FSelection := FSelected;
        DrawView;
        ClearEvent(Event);
        FEndState := cmOK;
      end else begin
        ClearEvent(Event);
        FEndState := cmCancel;
      end;
    end;

    evKeyDown: begin
      case Event.KeyCode of
        kbUp: begin
          if FSelected > 0 then Dec(FSelected)
          else FSelected := FItemCount - 1;
          DrawView;
          ClearEvent(Event);
        end;
        kbDown: begin
          if FSelected < FItemCount - 1 then Inc(FSelected)
          else FSelected := 0;
          DrawView;
          ClearEvent(Event);
        end;
        kbEnter: begin
          FSelection := FSelected;
          ClearEvent(Event);
          FEndState := cmOK;
        end;
        kbEsc: begin
          FSelection := -1;
          ClearEvent(Event);
          FEndState := cmCancel;
        end;
      end;
    end;

    evCommand: begin
      if Event.Command = cmCancel then begin
        FSelection := -1;
        ClearEvent(Event);
        FEndState := cmCancel;
      end;
    end;
  end;
end;

{ TCalendarView }

constructor TCalendarView.Create(var Bounds: TRect);
var
  Y, M, D: Word;
  I: Integer;
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := EventMask or evMouseDown or evKeyDown;
  DecodeDate(Now, Y, M, D);
  FYear := Y;
  FMonth := M;
  FDay := D;
  FFirstDayOfWeek := 0;  { Sunday }
  FUseDayColors := False;
  FOnDateSelect := nil;
  for I := 0 to 6 do
    FDayColors[I] := 1;  { Default to normal color }
end;

constructor TCalendarView.CreateWithDate(var Bounds: TRect; AYear, AMonth, ADay: Word);
var
  I: Integer;
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := EventMask or evMouseDown or evKeyDown;
  FYear := AYear;
  FMonth := AMonth;
  FDay := ADay;
  FFirstDayOfWeek := 0;  { Sunday }
  FUseDayColors := False;
  FOnDateSelect := nil;
  for I := 0 to 6 do
    FDayColors[I] := 1;
  ClampDay;
end;

function TCalendarView.IsLeapYear(AYear: Word): Boolean;
begin
  Result := ((AYear mod 4 = 0) and (AYear mod 100 <> 0)) or (AYear mod 400 = 0);
end;

function TCalendarView.DaysInMonth(AYear, AMonth: Word): Word;
begin
  Result := DaysPerMonth[AMonth];
  if (AMonth = 2) and IsLeapYear(AYear) then
    Inc(Result);
end;

function TCalendarView.DayOfWeek(AYear, AMonth, ADay: Word): Word;
var
  A, Y, M: Integer;
begin
  { Zeller's congruence for Gregorian calendar }
  A := (14 - AMonth) div 12;
  Y := AYear - A;
  M := AMonth + 12 * A - 2;
  Result := (ADay + (31 * M div 12) + Y + (Y div 4) - (Y div 100) + (Y div 400)) mod 7;
  { Result: 0=Sunday, 1=Monday, ..., 6=Saturday }
end;

procedure TCalendarView.ClampDay;
var
  MaxDay: Word;
begin
  MaxDay := DaysInMonth(FYear, FMonth);
  if FDay > MaxDay then
    FDay := MaxDay;
  if FDay < 1 then
    FDay := 1;
end;

procedure TCalendarView.SetFirstDayOfWeek(AFirstDay: Byte);
begin
  if AFirstDay <= 6 then
    FFirstDayOfWeek := AFirstDay;
  DrawView;
end;

procedure TCalendarView.SetDayColor(ADayOfWeek: Byte; AColorIndex: Byte);
begin
  if ADayOfWeek <= 6 then begin
    FDayColors[ADayOfWeek] := AColorIndex;
    FUseDayColors := True;
  end;
end;

function TCalendarView.GetDayHeaderStr: string;
var
  I, D: Integer;
  S: string;
begin
  S := '';
  for I := 0 to 6 do begin
    D := (FFirstDayOfWeek + I) mod 7;
    if I > 0 then S := S + ' ';
    S := S + DayNamesShort[D];
  end;
  Result := S;
end;

procedure TCalendarView.Draw;
var
  B: TDrawBuffer;
  CTitle, CNormal, CSelected, CArrow: Word;
  FirstDay, Days, Row, Col, D, ActualDOW: Integer;
  S: string;
  TitleStr, MonthStr, YearStr: string;
  Y, MonthX, YearX, ArrowLeftX, ArrowRightX: Integer;
  DayColor: Word;
begin
  CTitle := GetColor(3);     { Title color }
  CNormal := GetColor(1);    { Normal day color }
  CSelected := GetColor(2);  { Selected day color }
  CArrow := GetColor(4);     { Arrow color }

  { Line 0: < Month Year > with navigation arrows }
  MonthStr := MonthNames[FMonth];
  YearStr := IntToStr(FYear);
  TitleStr := MonthStr + ' ' + YearStr;

  DrawChar(B, 0, ' ', Byte(CTitle), Size.X);

  { Left arrow at position 0 }
  ArrowLeftX := 0;
  DrawStr(B, ArrowLeftX, '<', Byte(CArrow));

  { Center the month + year title }
  Col := (Size.X - Length(TitleStr)) div 2;
  if Col < 2 then Col := 2;

  { Remember positions for click detection }
  MonthX := Col;
  DrawStr(B, MonthX, MonthStr, Byte(CTitle));

  YearX := MonthX + Length(MonthStr) + 1;
  DrawStr(B, YearX, YearStr, Byte(CTitle));

  { Right arrow at end }
  ArrowRightX := Size.X - 1;
  DrawStr(B, ArrowRightX, '>', Byte(CArrow));

  WriteLine(0, 0, Size.X, 1, B);

  { Line 1: Day headers (adjusted for FirstDayOfWeek) }
  DrawChar(B, 0, ' ', Byte(CNormal), Size.X);
  DrawStr(B, 0, GetDayHeaderStr, Byte(CNormal));
  WriteLine(0, 1, Size.X, 1, B);

  { Lines 2-7: Calendar days }
  { Calculate which column the 1st of the month falls on }
  FirstDay := DayOfWeek(FYear, FMonth, 1);
  { Adjust for FirstDayOfWeek }
  FirstDay := (FirstDay - FFirstDayOfWeek + 7) mod 7;

  Days := DaysInMonth(FYear, FMonth);
  D := 1;

  for Row := 0 to 5 do begin
    DrawChar(B, 0, ' ', Byte(CNormal), Size.X);
    Y := Row + 2;

    for Col := 0 to 6 do begin
      if (Row = 0) and (Col < FirstDay) then
        Continue
      else if D > Days then
        Break
      else begin
        S := Format('%2d', [D]);

        { Determine color for this day }
        if D = FDay then
          DayColor := CSelected
        else if FUseDayColors then begin
          { Get actual day of week for this date }
          ActualDOW := DayOfWeek(FYear, FMonth, D);
          DayColor := GetColor(FDayColors[ActualDOW]);
        end else
          DayColor := CNormal;

        DrawStr(B, Col * 3, S, Byte(DayColor));
        Inc(D);
      end;
    end;

    WriteLine(0, Y, Size.X, 1, B);
  end;
end;

procedure TCalendarView.ShowMonthMenu;
var
  R: TRect;
  Menu: TCalendarMenu;
  GX, GY: Integer;
  V: TView;
  MonthItems: array[0..11] of string;
  I: Integer;
  Cmd: Word;
begin
  { Build month list }
  for I := 1 to 12 do
    MonthItems[I - 1] := MonthNames[I];

  { Calculate global position for menu }
  GX := Origin.X + 2;
  GY := Origin.Y + 1;
  V := Owner;
  while V <> nil do begin
    Inc(GX, V.Origin.X);
    Inc(GY, V.Origin.Y);
    V := V.Owner;
  end;

  R.Assign(GX, GY, GX + 12, GY + 12);
  Menu := TCalendarMenu.Create(R, MonthItems);
  Menu.Selected := FMonth - 1;

  if Desktop <> nil then begin
    Cmd := Desktop.ExecView(Menu);
    if (Cmd <> cmCancel) and (Menu.Selection >= 0) then begin
      FMonth := Menu.Selection + 1;
      ClampDay;
      DrawView;
      SelectDate;
    end;
    FreeAndNil(Menu);
  end;
end;

procedure TCalendarView.ShowYearMenu;
var
  R: TRect;
  Menu: TCalendarMenu;
  GX, GY: Integer;
  V: TView;
  YearItems: array[0..9] of string;
  I, StartYear, SelectedIdx: Integer;
  Cmd: Word;
begin
  { Show years around current year }
  StartYear := FYear - 5;
  if StartYear < 1 then StartYear := 1;
  SelectedIdx := 5;

  for I := 0 to 9 do
    YearItems[I] := IntToStr(StartYear + I);

  { Calculate global position for menu }
  GX := Origin.X + 10;
  GY := Origin.Y + 1;
  V := Owner;
  while V <> nil do begin
    Inc(GX, V.Origin.X);
    Inc(GY, V.Origin.Y);
    V := V.Owner;
  end;

  R.Assign(GX, GY, GX + 8, GY + 10);
  Menu := TCalendarMenu.Create(R, YearItems);
  Menu.Selected := SelectedIdx;

  if Desktop <> nil then begin
    Cmd := Desktop.ExecView(Menu);
    if (Cmd <> cmCancel) and (Menu.Selection >= 0) then begin
      FYear := StartYear + Menu.Selection;
      ClampDay;
      DrawView;
      SelectDate;
    end;
    FreeAndNil(Menu);
  end;
end;

procedure TCalendarView.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  Row, Col, FirstDay, ClickedDay: Integer;
  MonthStr, YearStr, TitleStr: string;
  MonthX, YearX, MonthEndX, YearEndX: Integer;
begin
  inherited HandleEvent(Event);

  case Event.What of
    evMouseDown: begin
      MakeLocal(Event.Where, Mouse);

      { Check for title row clicks (row 0) }
      if Mouse.Y = 0 then begin
        { Calculate positions }
        MonthStr := MonthNames[FMonth];
        YearStr := IntToStr(FYear);
        TitleStr := MonthStr + ' ' + YearStr;
        Col := (Size.X - Length(TitleStr)) div 2;
        if Col < 2 then Col := 2;
        MonthX := Col;
        MonthEndX := MonthX + Length(MonthStr);
        YearX := MonthEndX + 1;
        YearEndX := YearX + Length(YearStr);

        { Left arrow clicked }
        if Mouse.X = 0 then begin
          PrevMonth;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
          Exit;
        end;

        { Right arrow clicked }
        if Mouse.X = Size.X - 1 then begin
          NextMonth;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
          Exit;
        end;

        { Month name clicked }
        if (Mouse.X >= MonthX) and (Mouse.X < MonthEndX) then begin
          ClearEvent(Event);
          ShowMonthMenu;
          Exit;
        end;

        { Year clicked }
        if (Mouse.X >= YearX) and (Mouse.X < YearEndX) then begin
          ClearEvent(Event);
          ShowYearMenu;
          Exit;
        end;

        ClearEvent(Event);
        Exit;
      end;

      { Check if click is in day area (rows 2-7) }
      if (Mouse.Y >= 2) and (Mouse.Y <= 7) then begin
        Row := Mouse.Y - 2;
        Col := Mouse.X div 3;
        if (Col >= 0) and (Col <= 6) then begin
          FirstDay := DayOfWeek(FYear, FMonth, 1);
          { Adjust for FirstDayOfWeek }
          FirstDay := (FirstDay - FFirstDayOfWeek + 7) mod 7;
          ClickedDay := Row * 7 + Col - FirstDay + 1;
          if (ClickedDay >= 1) and (ClickedDay <= DaysInMonth(FYear, FMonth)) then begin
            FDay := ClickedDay;
            DrawView;
            SelectDate;
          end;
        end;
      end;
      ClearEvent(Event);
    end;

    evKeyDown: begin
      case Event.KeyCode of
        kbLeft: begin
          if FDay > 1 then Dec(FDay)
          else begin
            PrevMonth;
            FDay := DaysInMonth(FYear, FMonth);
          end;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbRight: begin
          if FDay < DaysInMonth(FYear, FMonth) then Inc(FDay)
          else begin
            NextMonth;
            FDay := 1;
          end;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbUp: begin
          if FDay > 7 then Dec(FDay, 7)
          else begin
            PrevMonth;
            FDay := DaysInMonth(FYear, FMonth) - (7 - FDay);
            if FDay < 1 then FDay := 1;
          end;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbDown: begin
          if FDay + 7 <= DaysInMonth(FYear, FMonth) then Inc(FDay, 7)
          else begin
            Col := FDay + 7 - DaysInMonth(FYear, FMonth);
            NextMonth;
            FDay := Col;
            ClampDay;
          end;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbPgUp: begin
          PrevMonth;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbPgDn: begin
          NextMonth;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbCtrlPgUp: begin
          PrevYear;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbCtrlPgDn: begin
          NextYear;
          ClampDay;
          DrawView;
          SelectDate;
          ClearEvent(Event);
        end;
        kbEnter: begin
          SelectDate;
          ClearEvent(Event);
        end;
      end;
    end;
  end;
end;

procedure TCalendarView.SelectDate;
begin
  Message(Owner, evBroadcast, cmCalendarDateSelected, Self);
  if Assigned(FOnDateSelect) then
    FOnDateSelect(Self);
end;

function TCalendarView.GetDate(var AYear, AMonth, ADay: Word): Boolean;
begin
  AYear := FYear;
  AMonth := FMonth;
  ADay := FDay;
  Result := True;
end;

procedure TCalendarView.SetDate(AYear, AMonth, ADay: Word);
begin
  FYear := AYear;
  FMonth := AMonth;
  FDay := ADay;
  ClampDay;
  DrawView;
end;

procedure TCalendarView.NextMonth;
begin
  Inc(FMonth);
  if FMonth > 12 then begin
    FMonth := 1;
    Inc(FYear);
  end;
end;

procedure TCalendarView.PrevMonth;
begin
  Dec(FMonth);
  if FMonth < 1 then begin
    FMonth := 12;
    Dec(FYear);
  end;
end;

procedure TCalendarView.NextYear;
begin
  Inc(FYear);
end;

procedure TCalendarView.PrevYear;
begin
  if FYear > 1 then Dec(FYear);
end;

end.
