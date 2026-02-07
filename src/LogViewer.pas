{*******************************************************}
{       Free Vision - Log Viewer Widget                }
{       Scrolling log display with severity colors     }
{*******************************************************}

unit LogViewer;

interface

uses
  System.SysUtils, System.Generics.Collections,
  FVConsts, Objects, Drivers, Views;

type
  TLogSeverity = (lsDebug, lsInfo, lsWarning, lsError);
  TLogFilterSet = set of TLogSeverity;

  TLogEntry = class
  public
    Timestamp: TDateTime;
    Message: string;
    Severity: TLogSeverity;
    constructor Create(const AMessage: string; ASeverity: TLogSeverity);
  end;

  TLogViewer = class(TView)
  private
    FEntries: TObjectList<TLogEntry>;
    FMaxLines: Integer;
    FTopLine: Integer;
    FAutoScroll: Boolean;
    FShowTimestamp: Boolean;
    FFilter: TLogFilterSet;
    FVScrollBar: TScrollBar;
    FFilteredIndices: TList<Integer>;
    procedure RebuildFilteredView;
    function GetVisibleCount: Integer;
    function GetFilteredEntry(Index: Integer): TLogEntry;
    procedure UpdateScrollBar;
  protected
    property TopLine: Integer read FTopLine;
    property FilteredEntry[Index: Integer]: TLogEntry read GetFilteredEntry;
  public
    constructor Create(var Bounds: TRect; AMaxLines: Integer;
      AVScrollBar: TScrollBar); reintroduce; virtual;
    destructor Destroy; override;

    { Main interface }
    procedure Add(const AMessage: string; ASeverity: TLogSeverity = lsInfo); virtual;
    procedure Clear; virtual;

    { Display control }
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetState(AState: Word; Enable: Boolean); override;

    { Scrolling }
    procedure ScrollTo(Line: Integer); virtual;
    procedure ScrollToEnd; virtual;
    procedure PageUp; virtual;
    procedure PageDown; virtual;

    { Filtering }
    procedure SetFilter(AFilter: TLogFilterSet); virtual;
    procedure ShowAll; virtual;
    procedure HideDebug; virtual;

    { Convenience methods }
    procedure Debug(const AMessage: string);
    procedure Info(const AMessage: string);
    procedure Warn(const AMessage: string);
    procedure Error(const AMessage: string);

    { Properties }
    property MaxLines: Integer read FMaxLines write FMaxLines;
    property AutoScroll: Boolean read FAutoScroll write FAutoScroll;
    property ShowTimestamp: Boolean read FShowTimestamp write FShowTimestamp;
    property Filter: TLogFilterSet read FFilter write SetFilter;
    property VScrollBar: TScrollBar read FVScrollBar write FVScrollBar;
    property EntryCount: Integer read GetVisibleCount;
  end;

const
  idLogViewer = 322;

  { Color palette for log viewer - indices into dialog palette }
  { 1=Background, 2=Debug, 3=Info, 4=Warning, 5=Error, 6=Timestamp }
  { Using: 6=StaticText, 7=LabelNormal, 8=LabelHighlight, 9=LabelShortcut }
  CLogViewer = #6#7#6#8#9#5;

implementation

uses
  System.Math;

{ TLogEntry }

constructor TLogEntry.Create(const AMessage: string; ASeverity: TLogSeverity);
begin
  inherited Create;
  Timestamp := Now;
  Message := AMessage;
  Severity := ASeverity;
end;

{ TLogViewer }

constructor TLogViewer.Create(var Bounds: TRect; AMaxLines: Integer;
  AVScrollBar: TScrollBar);
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := EventMask or evBroadcast;

  FEntries := TObjectList<TLogEntry>.Create(True);  { Owns objects }
  FFilteredIndices := TList<Integer>.Create;
  FMaxLines := AMaxLines;
  FTopLine := 0;
  FAutoScroll := True;
  FShowTimestamp := True;
  FFilter := [lsDebug, lsInfo, lsWarning, lsError];  { Show all by default }
  FVScrollBar := AVScrollBar;

  UpdateScrollBar;
end;

destructor TLogViewer.Destroy;
begin
  FreeAndNil(FFilteredIndices);
  FreeAndNil(FEntries);
  inherited Destroy;
end;

function TLogViewer.GetPalette: PPalette;
const
  P: ShortString = CLogViewer;
begin
  Result := PPalette(@P);
end;

procedure TLogViewer.RebuildFilteredView;
var
  I: Integer;
begin
  FFilteredIndices.Clear;
  for I := 0 to FEntries.Count - 1 do begin
    if FEntries[I].Severity in FFilter then
      FFilteredIndices.Add(I);
  end;
end;

function TLogViewer.GetVisibleCount: Integer;
begin
  Result := FFilteredIndices.Count;
end;

function TLogViewer.GetFilteredEntry(Index: Integer): TLogEntry;
begin
  if (Index >= 0) and (Index < FFilteredIndices.Count) then
    Result := FEntries[FFilteredIndices[Index]]
  else
    Result := nil;
end;

procedure TLogViewer.UpdateScrollBar;
var
  MaxTop: Integer;
begin
  if FVScrollBar <> nil then begin
    MaxTop := Max(0, GetVisibleCount - Size.Y);
    FVScrollBar.SetParams(FTopLine, 0, MaxTop, Size.Y, 1);
  end;
end;

procedure TLogViewer.Add(const AMessage: string; ASeverity: TLogSeverity);
var
  Entry: TLogEntry;
  MaxTop: Integer;
  DeletedFromTop: Boolean;
begin
  { Check if we need to remove oldest entry (ring buffer) }
  DeletedFromTop := FEntries.Count >= FMaxLines;
  if DeletedFromTop then
    FEntries.Delete(0);

  { Add new entry }
  Entry := TLogEntry.Create(AMessage, ASeverity);
  FEntries.Add(Entry);

  { Rebuild filtered view }
  RebuildFilteredView;

  { If we deleted from top and not auto-scrolling, adjust position to stay in place }
  if DeletedFromTop and not FAutoScroll and (FTopLine > 0) then
    Dec(FTopLine);

  { Clamp to valid range }
  MaxTop := Max(0, GetVisibleCount - Size.Y);
  if FTopLine > MaxTop then
    FTopLine := MaxTop;
  if FTopLine < 0 then
    FTopLine := 0;

  { Update scrollbar }
  UpdateScrollBar;

  { Only auto-scroll if the toggle is ON }
  if FAutoScroll then
    ScrollToEnd
  else
    DrawView;
end;

procedure TLogViewer.Clear;
begin
  FEntries.Clear;
  FFilteredIndices.Clear;
  FTopLine := 0;
  UpdateScrollBar;
  DrawView;
end;

procedure TLogViewer.Draw;
var
  B: TDrawBuffer;
  I, Line: Integer;
  Entry: TLogEntry;
  Color, TimeColor, BgColor: Byte;
  Text, TimeStr, SevStr: string;
  X: Integer;
begin
  BgColor := GetColor(1);
  TimeColor := GetColor(6);

  for I := 0 to Size.Y - 1 do begin
    Line := FTopLine + I;

    { Clear line with background color }
    DrawChar(B, 0, ' ', BgColor, Size.X);

    Entry := GetFilteredEntry(Line);
    if Entry <> nil then begin
      { Determine color based on severity }
      case Entry.Severity of
        lsDebug:   Color := GetColor(2);
        lsInfo:    Color := GetColor(3);
        lsWarning: Color := GetColor(4);
        lsError:   Color := GetColor(5);
      else
        Color := BgColor;
      end;

      X := 0;

      { Draw timestamp if enabled }
      if FShowTimestamp then begin
        TimeStr := FormatDateTime('hh:nn:ss ', Entry.Timestamp);
        DrawStr(B, X, TimeStr, TimeColor);
        Inc(X, Length(TimeStr));
      end;

      { Draw severity indicator }
      case Entry.Severity of
        lsDebug:   SevStr := '[D] ';
        lsInfo:    SevStr := '[I] ';
        lsWarning: SevStr := '[W] ';
        lsError:   SevStr := '[E] ';
      else
        SevStr := '    ';
      end;
      DrawStr(B, X, SevStr, Color);
      Inc(X, Length(SevStr));

      { Draw message (truncate to fit) }
      Text := Copy(Entry.Message, 1, Size.X - X);
      DrawStr(B, X, Text, Color);
    end;

    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TLogViewer.HandleEvent(var Event: TEvent);
var
  NewTop: Integer;
begin
  inherited HandleEvent(Event);

  case Event.What of
    evKeyDown: begin
      NewTop := FTopLine;
      case CtrlToArrow(Event.KeyCode) of
        kbUp:       NewTop := FTopLine - 1;
        kbDown:     NewTop := FTopLine + 1;
        kbPgUp:     NewTop := FTopLine - Size.Y;
        kbPgDn:     NewTop := FTopLine + Size.Y;
        kbHome:     NewTop := 0;
        kbEnd:      NewTop := GetVisibleCount - Size.Y;
        kbCtrlHome: NewTop := 0;
        kbCtrlEnd:  NewTop := GetVisibleCount - Size.Y;
      else
        Exit;  { Don't clear event for unhandled keys }
      end;

      if NewTop <> FTopLine then begin
        { Disable auto-scroll when user scrolls manually (except End key) }
        if (Event.KeyCode <> kbEnd) and (Event.KeyCode <> kbCtrlEnd) then
          FAutoScroll := False
        else
          FAutoScroll := True;
        ScrollTo(NewTop);
      end;
      ClearEvent(Event);
    end;

    evMouseDown: begin
      { Handle mouse wheel scrolling }
      if Event.Buttons and (mbScrollWheelUp or mbScrollWheelDown) <> 0 then begin
        if Event.Buttons and mbScrollWheelUp <> 0 then begin
          FAutoScroll := False;
          ScrollTo(FTopLine - 3);
        end else begin
          ScrollTo(FTopLine + 3);
          if FTopLine >= Max(0, GetVisibleCount - Size.Y) then
            FAutoScroll := True;
        end;
        ClearEvent(Event);
      end
      { Handle click to focus }
      else if Event.Buttons and mbLeftButton <> 0 then begin
        Select;
        ClearEvent(Event);
      end;
    end;

    evBroadcast: begin
      if (Event.Command = cmScrollBarChanged) and
         (Event.InfoPtr = Pointer(FVScrollBar)) then begin
        { Only update position, don't change auto-scroll here }
        { (auto-scroll is disabled on user click, not on every change) }
        if FVScrollBar.Value <> FTopLine then begin
          FTopLine := FVScrollBar.Value;
          DrawView;
        end;
      end
      else if (Event.Command = cmScrollBarClicked) and
              (Event.InfoPtr = Pointer(FVScrollBar)) then begin
        { User clicked scrollbar - disable auto-scroll }
        FAutoScroll := False;
        Select;
      end;
    end;
  end;
end;

procedure TLogViewer.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState and sfActive <> 0 then
    UpdateScrollBar;
end;

procedure TLogViewer.ScrollTo(Line: Integer);
var
  MaxTop: Integer;
begin
  MaxTop := Max(0, GetVisibleCount - Size.Y);
  if Line < 0 then Line := 0;
  if Line > MaxTop then Line := MaxTop;

  FTopLine := Line;
  if FVScrollBar <> nil then
    FVScrollBar.SetValue(FTopLine);
  DrawView;
end;

procedure TLogViewer.ScrollToEnd;
var
  NewTop: Integer;
begin
  FAutoScroll := True;
  NewTop := GetVisibleCount - Size.Y;
  if NewTop < 0 then NewTop := 0;
  FTopLine := NewTop;
  UpdateScrollBar;
  DrawView;
end;

procedure TLogViewer.PageUp;
begin
  FAutoScroll := False;
  ScrollTo(FTopLine - Size.Y);
end;

procedure TLogViewer.PageDown;
var
  MaxTop: Integer;
begin
  ScrollTo(FTopLine + Size.Y);
  MaxTop := Max(0, GetVisibleCount - Size.Y);
  if FTopLine >= MaxTop then
    FAutoScroll := True;
end;

procedure TLogViewer.SetFilter(AFilter: TLogFilterSet);
var
  MaxTop: Integer;
begin
  if FFilter <> AFilter then begin
    FFilter := AFilter;
    RebuildFilteredView;

    { Clamp TopLine to valid range after filter change }
    MaxTop := Max(0, GetVisibleCount - Size.Y);
    if FTopLine > MaxTop then
      FTopLine := MaxTop;

    UpdateScrollBar;

    if FAutoScroll then
      ScrollToEnd
    else
      DrawView;
  end;
end;

procedure TLogViewer.ShowAll;
begin
  SetFilter([lsDebug, lsInfo, lsWarning, lsError]);
end;

procedure TLogViewer.HideDebug;
begin
  SetFilter([lsInfo, lsWarning, lsError]);
end;

{ Convenience methods }

procedure TLogViewer.Debug(const AMessage: string);
begin
  Add(AMessage, lsDebug);
end;

procedure TLogViewer.Info(const AMessage: string);
begin
  Add(AMessage, lsInfo);
end;

procedure TLogViewer.Warn(const AMessage: string);
begin
  Add(AMessage, lsWarning);
end;

procedure TLogViewer.Error(const AMessage: string);
begin
  Add(AMessage, lsError);
end;

end.
