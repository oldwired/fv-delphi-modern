program FVTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  FVInterfaces in 'src\FVInterfaces.pas',
  FVSerialization in 'src\FVSerialization.pas',
  Objects in 'src\Objects.pas',
  FVScreen in 'src\FVScreen.pas',
  FVBoxChars in 'src\FVBoxChars.pas',
  FVUTF8 in 'src\FVUTF8.pas',
  Drivers in 'src\Drivers.pas',
  Views in 'src\Views.pas',
  Menus in 'src\Menus.pas',
  HistList in 'src\histlist.pas',
  fvconsts in 'src\fvconsts.pas',
  App in 'src\app.pas',
  FVCommon in 'src\FVCommon.pas',
  Validate in 'src\Validate.pas',
  Dialogs in 'src\Dialogs.pas',
  MsgBox in 'src\MsgBox.pas',
  StdDlg in 'src\StdDlg.pas',
  ColorTxt in 'src\ColorTxt.pas',
  Time in 'src\Time.pas',
  Gadgets in 'src\Gadgets.pas',
  InpLong in 'src\InpLong.pas',
  AsciiTab in 'src\AsciiTab.pas',
  TimedDlg in 'src\TimedDlg.pas',
  Tabs in 'src\Tabs.pas',
  Statuses in 'src\Statuses.pas',
  ColorSel in 'src\ColorSel.pas',
  Outline in 'src\Outline.pas',
  Editors in 'src\Editors.pas',
  Calendar in 'src\Calendar.pas',
  Grid in 'src\Grid.pas',
  ConPTY in 'src\ConPTY.pas',
  Terminal in 'src\Terminal.pas';

const
  cmNewWindow = 100;
  cmTestWindow1 = 1001;
  cmTestWindow2 = 1002;
  cmTestDialog = 1003;
  cmTestScroller = 1004;
  cmTestMsgBox = 1005;
  cmTestInputBox = 1006;
  cmTestFileOpen = 1007;
  cmTestChDir = 1008;
  cmTestColoredText = 1009;
  cmTestInputLong = 1010;
  cmTestAsciiChart = 1011;
  cmTestTimedDlg = 1012;
  cmTestTabs = 1013;
  cmAddTab = 1014;
  cmRemoveTab = 1015;
  cmTestStatuses = 1016;
  cmUpdateGauge = 1017;
  cmTestColors = 1018;
  cmTestOutline = 1019;
  cmTestEditor = 1020;
  cmTestEditorFind = 1021;
  cmTestEditorFile = 1022;
  cmTestEditorClipboard = 1023;
  cmTestCalendar = 1024;
  cmTestCalendarBroadcast = 1025;
  cmTestStringGrid = 1026;
  cmTestStringGrid2 = 1027;
  cmTestStringGrid3 = 1028;
  cmTestTerminalCmd = 1029;
  cmTestTerminalPwsh = 1030;
  cmTestTerminalCustom = 1031;

var
  ExceptionLog: TextFile;
  ExceptionLogOpen: Boolean = False;
  ExceptionLogName: string = '';
  IdleCounter: Integer = 0;
  LastSecond: Word = 65535;
  ClockView: TClockView = nil;
  HeapView: THeapView = nil;

procedure LogException(const Context: string; E: Exception);
begin
  if not ExceptionLogOpen then begin
    { Use timestamp-based filename to avoid conflicts with nested instances }
    ExceptionLogName := FormatDateTime('"fvtest_"yyyymmdd_hhnnsszzz".log"', Now);
    AssignFile(ExceptionLog, ExceptionLogName);
    Rewrite(ExceptionLog);
    ExceptionLogOpen := True;
  end;
  WriteLn(ExceptionLog, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
          ' EXCEPTION in ', Context, ': ', E.ClassName, ' - ', E.Message);
  Flush(ExceptionLog);
end;


type
  TMyStatusLine = class;
  TMyApp = class;
  TCalendarWindow = class;
  TGridTestWindow = class;
  TTextScroller = class;
  TMyWindow = class;
  TTabTestDialog = class;

  TMyStatusLine = class(TStatusLine)
    function Hint(AHelpCtx: Word): string; override;
  end;

  TMyApp = class(TApplication)
  private
    FCalendarDateLabel: TStaticText;  { Reference for calendar demo }
    FGridCellLabel: TStaticText;      { Reference for grid callback demo }
    FCallbackGrid: TStringGrid;       { Reference to callback grid }
  public
    constructor Create; reintroduce; virtual;
    procedure InitMenuBar; override;
    procedure InitStatusLine; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Idle; override;
    procedure NewWindow;
    procedure TestWindow1;
    procedure TestWindow2;
    procedure TestDialog;
    procedure TestScroller;
    procedure TestMsgBox;
    procedure TestInputBox;
    procedure TestFileOpen;
    procedure TestChDir;
    procedure TestColoredText;
    procedure TestInputLong;
    procedure TestAsciiChart;
    procedure TestTimedDlg;
    procedure TestTabs;
    procedure TestStatuses;
    procedure TestColors;
    procedure TestOutline;
    procedure TestEditor;
    procedure TestEditorFind;
    procedure TestEditorFile;
    procedure TestEditorClipboard;
    procedure TestCalendar;
    procedure TestCalendarBroadcast;
    procedure TestStringGrid;
    procedure TestStringGrid2;
    procedure TestStringGrid3;
    procedure OnCalendarDateSelect(Calendar: TCalendarView);
    procedure OnGridCellFocused(Sender: TObject; Col, Row: Integer);
    procedure TestTerminalCmd;
    procedure TestTerminalPwsh;
    procedure TestTerminalCustom;
    property CalendarDateLabel: TStaticText read FCalendarDateLabel write FCalendarDateLabel;
  end;

  { Custom window for calendar that handles broadcast }
  TCalendarWindow = class(TWindow)
  private
    FDateLabel: TStaticText;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure HandleEvent(var Event: TEvent); override;
    property DateLabel: TStaticText read FDateLabel write FDateLabel;
  end;

  { Custom window for grid that handles cell focus broadcast }
  TGridTestWindow = class(TWindow)
  private
    FCellLabel: TStaticText;
    FGrid: TStringGrid;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure HandleEvent(var Event: TEvent); override;
    property CellLabel: TStaticText read FCellLabel write FCellLabel;
    property Grid: TStringGrid read FGrid write FGrid;
  end;

  { Custom scroller that displays numbered lines }
  TTextScroller = class(TScroller)
  public
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar); reintroduce; virtual;
    procedure Draw; override;
  end;

  TMyWindow = class(TWindow)
  public
    constructor Create(var Bounds: TRect; const ATitle: string; ANumber: Integer); reintroduce; virtual;
  end;

  { Custom dialog for testing dynamic tab add/remove }
  TTabTestDialog = class(TDialog)
  private
    FTabCtrl: TTab;
    FTabCounter: Integer;
  public
    constructor Create(var Bounds: TRect; const ATitle: string); reintroduce; virtual;
    procedure HandleEvent(var Event: TEvent); override;
    procedure AddNewTab;
    procedure RemoveCurrentTab;
    property TabCtrl: TTab read FTabCtrl write FTabCtrl;
    property TabCounter: Integer read FTabCounter write FTabCounter;
  end;

var
  MyApp: TMyApp;
  WindowCount: Integer;

function TMyStatusLine.Hint(AHelpCtx: Word): string;
begin
  Result := FormatDateTime('hh:nn:ss', Now);
end;

constructor TMyWindow.Create(var Bounds: TRect; const ATitle: string; ANumber: Integer);
begin
  inherited Create(Bounds, ATitle, ANumber);
  Options := Options or ofTileable;
end;

{ TCalendarWindow - demonstrates broadcast handling }
constructor TCalendarWindow.Create(var Bounds: TRect);
var
  R: TRect;
  CalView: TCalendarView;
  Y, M, D: Word;
  S: string;
begin
  inherited Create(Bounds, 'Calendar (Broadcast)', wnNoNumber);
  Options := Options or ofTileable;
  Flags := Flags and not (wfGrow or wfZoom);

  { Add the calendar view }
  R.Assign(2, 1, 24, 9);
  CalView := TCalendarView.Create(R);
  CalView.SetFirstDayOfWeek(1);
  CalView.SetDayColor(0, 5);
  CalView.SetDayColor(6, 5);
  Insert(CalView);

  { Add label to show selected date }
  CalView.GetDate(Y, M, D);
  S := Format('Selected: %d/%d/%d', [M, D, Y]);
  R.Assign(2, 10, 26, 11);
  FDateLabel := TStaticText.Create(R, S);
  Insert(FDateLabel);

  { Instructions }
  R.Assign(2, 9, 26, 10);
  Insert(TStaticText.Create(R, 'Using broadcast message'));

  CalView.Select;
end;

procedure TCalendarWindow.HandleEvent(var Event: TEvent);
var
  Cal: TCalendarView;
  Y, M, D: Word;
  S: string;
begin
  inherited HandleEvent(Event);

  { Handle calendar date selection broadcast }
  if (Event.What = evBroadcast) and (Event.Command = cmCalendarDateSelected) then begin
    Cal := TCalendarView(Event.InfoPtr);
    if (Cal <> nil) and (FDateLabel <> nil) then begin
      Cal.GetDate(Y, M, D);
      S := Format('Selected: %d/%d/%d', [M, D, Y]);
      FDateLabel.Text := S;
      FDateLabel.DrawView;
    end;
    ClearEvent(Event);
  end;
end;

{ TGridTestWindow - demonstrates grid with cell info label }
constructor TGridTestWindow.Create(var Bounds: TRect);
var
  R: TRect;
  HScrollBar, VScrollBar: TScrollBar;
  I: Integer;
begin
  inherited Create(Bounds, 'StringGrid (With Label)', wnNoNumber);
  Options := Options or ofTileable;
  Flags := Flags and not wfZoom;

  { Create vertical scrollbar }
  GetExtent(R);
  R.A.X := R.B.X - 2;
  R.B.X := R.B.X - 1;
  R.A.Y := 1;
  R.B.Y := R.B.Y - 4;
  VScrollBar := TScrollBar.Create(R);
  VScrollBar.GrowMode := gfGrowLoX + gfGrowHiX + gfGrowHiY;
  Insert(VScrollBar);

  { Create horizontal scrollbar }
  GetExtent(R);
  R.A.X := 1;
  R.B.X := R.B.X - 2;
  R.A.Y := R.B.Y - 4;
  R.B.Y := R.B.Y - 3;
  HScrollBar := TScrollBar.Create(R);
  HScrollBar.GrowMode := gfGrowLoY + gfGrowHiY + gfGrowHiX;
  Insert(HScrollBar);

  { Create the string grid }
  GetExtent(R);
  R.A.X := 1;
  R.A.Y := 1;
  R.B.X := R.B.X - 2;
  R.B.Y := R.B.Y - 4;
  FGrid := TStringGrid.Create(R, 4, HScrollBar, VScrollBar);
  FGrid.GrowMode := gfGrowHiX + gfGrowHiY;

  { Configure columns }
  FGrid.Columns[0].Title := 'ID';
  FGrid.Columns[0].Width := 6;
  FGrid.Columns[0].Alignment := gaRight;

  FGrid.Columns[1].Title := 'Name';
  FGrid.Columns[1].Width := 15;

  FGrid.Columns[2].Title := 'Value';
  FGrid.Columns[2].Width := 10;
  FGrid.Columns[2].Alignment := gaRight;

  FGrid.Columns[3].Title := 'Status';
  FGrid.Columns[3].Width := 12;
  FGrid.Columns[3].Alignment := gaCenter;

  { Set grid options }
  FGrid.FixedRows := 1;
  FGrid.ShowGridLines := True;
  FGrid.SelectionMode := smCell;

  { Add test data - start at row 1 (row 0 is header) }
  FGrid.RowCount := 16;  { 1 header + 15 data rows }
  for I := 1 to 15 do begin
    FGrid[0, I] := IntToStr(I);
    FGrid[1, I] := 'Item ' + IntToStr(I);
    FGrid[2, I] := Format('%.2f', [Random * 100]);
    case I mod 3 of
      0: FGrid[3, I] := 'Active';
      1: FGrid[3, I] := 'Pending';
      2: FGrid[3, I] := 'Done';
    end;
  end;

  Insert(FGrid);

  { Add label to show cell info }
  GetExtent(R);
  R.A.X := 1;
  R.A.Y := R.B.Y - 3;
  R.B.X := R.B.X - 1;
  R.B.Y := R.B.Y - 2;
  FCellLabel := TStaticText.Create(R, 'Click a cell to see info');
  Insert(FCellLabel);

  { Instructions }
  GetExtent(R);
  R.A.X := 1;
  R.A.Y := R.B.Y - 2;
  R.B.X := R.B.X - 1;
  R.B.Y := R.B.Y - 1;
  Insert(TStaticText.Create(R, 'Using broadcast cmGridCellFocused'));

  FGrid.Select;
end;

procedure TGridTestWindow.HandleEvent(var Event: TEvent);
var
  G: TStringGrid;
  S: string;
  Col, Row: Integer;
  CellText: string;
begin
  inherited HandleEvent(Event);

  { Handle grid cell focused broadcast }
  if (Event.What = evBroadcast) and (Event.Command = cmGridCellFocused) then begin
    G := TStringGrid(Event.InfoPtr);
    if (G = FGrid) and (FCellLabel <> nil) then begin
      Col := G.FocusedCol;
      Row := G.FocusedRow;
      CellText := G[Col, Row];
      S := Format('%d,%d: %s', [Col, Row, CellText]);
      FCellLabel.Text := S;
      FCellLabel.DrawView;
    end;
    ClearEvent(Event);
  end;
end;

{ TTabTestDialog }
constructor TTabTestDialog.Create(var Bounds: TRect; const ATitle: string);
begin
  inherited Create(Bounds, ATitle);
  FTabCtrl := nil;
  FTabCounter := 3;  { We start with 3 tabs }
end;

procedure TTabTestDialog.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then begin
    case Event.Command of
      cmAddTab: begin
        AddNewTab;
        ClearEvent(Event);
      end;
      cmRemoveTab: begin
        RemoveCurrentTab;
        ClearEvent(Event);
      end;
    end;
  end;
end;

procedure TTabTestDialog.AddNewTab;
var
  R: TRect;
  NewInput: TInputLine;
  TabDef: PTabDef;
begin
  if FTabCtrl = nil then Exit;

  Inc(FTabCounter);

  { Create a new input line for the new tab }
  R.Assign(2, 4, 50, 5);
  NewInput := TInputLine.Create(R, 40);

  { Create the tab definition using Tabs.NewTabDef function }
  TabDef := Tabs.NewTabDef('Tab ~' + ShortString(IntToStr(FTabCounter)) + '~', NewInput,
    Tabs.NewTabItem(NewInput, nil), nil);

  { Add it to the tab control }
  FTabCtrl.AddTab(TabDef);
end;

procedure TTabTestDialog.RemoveCurrentTab;
begin
  if FTabCtrl = nil then Exit;
  if FTabCtrl.TabCount > 1 then begin
    FTabCtrl.RemoveTab(FTabCtrl.ActiveDef);
    Dec(FTabCounter);
  end;
end;

{ TTextScroller - displays 100 lines of text for scrolling test }
constructor TTextScroller.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar);
begin
  inherited Create(Bounds, AHScrollBar, AVScrollBar);
  Options := Options or ofFirstClick;
  SetLimit(80, 100);  { 80 columns, 100 lines }
  GrowMode := gfGrowHiX + gfGrowHiY;
end;

procedure TTextScroller.Draw;
var
  B: TDrawBuffer;
  C: Byte;
  I, J: Integer;
  S: string;
begin
  C := GetColor(1);  { Normal color }
  for I := 0 to Size.Y - 1 do begin
    DrawChar(B, 0, ' ', C, Size.X);
    J := Delta.Y + I;
    if J < Limit.Y then begin
      S := Format('Line %3d: ', [J + 1]);
      { Add some content to show horizontal scrolling }
      S := S + 'The quick brown fox jumps over the lazy dog. ABCDEFGHIJKLMNOP';
      if Delta.X < Length(S) then begin
        DrawStr(B, 0, Copy(S, Delta.X + 1, Size.X), C);
      end;
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

constructor TMyApp.Create;
var
  R: TRect;
begin
  inherited Create;
  FCalendarDateLabel := nil;

  { Add Clock view at top right of desktop }
  if Desktop <> nil then begin
    Desktop.GetExtent(R);
    R.A.X := R.B.X - 10;
    R.A.Y := 0;
    R.B.Y := 1;
    ClockView := TClockView.Create(R);
    Desktop.Insert(ClockView);

    { Add Heap view below clock }
    Desktop.GetExtent(R);
    R.A.X := R.B.X - 12;
    R.B.X := R.B.X - 1;
    R.A.Y := 1;
    R.B.Y := 2;
    HeapView := THeapView.CreateKb(R);
    Desktop.Insert(HeapView);
  end;
end;

procedure TMyApp.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := TMenuBar.Create(R, NewMenu(
    NewSubMenu('~F~ile', hcNoContext, NewMenu(
      NewItem('~N~ew', 'F4', kbF4, cmNewWindow, hcNoContext,
      NewItem('~O~pen...', 'F3', kbF3, cmTestFileOpen, hcNoContext,
      NewItem('Change ~D~ir...', '', kbNoKey, cmTestChDir, hcNoContext,
      NewLine(
      NewItem('E~x~it', 'Alt-X', kbAltX, cmQuit, hcNoContext, nil)))))),
    NewSubMenu('~T~est', hcNoContext, NewMenu(
      NewItem('Window ~1~ (Input+Radio)', '', kbNoKey, cmTestWindow1, hcNoContext,
      NewItem('Window ~2~ (Checkboxes)', '', kbNoKey, cmTestWindow2, hcNoContext,
      NewItem('Test ~D~ialog (Full)', '', kbNoKey, cmTestDialog, hcNoContext,
      NewItem('~S~croller Test', '', kbNoKey, cmTestScroller, hcNoContext,
      NewLine(
      NewItem('~M~essageBox Test', '', kbNoKey, cmTestMsgBox, hcNoContext,
      NewItem('~I~nputBox Test', '', kbNoKey, cmTestInputBox, hcNoContext,
      NewLine(
      NewItem('~C~olored Text', '', kbNoKey, cmTestColoredText, hcNoContext,
      NewItem('Input~L~ong', '', kbNoKey, cmTestInputLong, hcNoContext,
      NewItem('~A~SCII Chart', '', kbNoKey, cmTestAsciiChart, hcNoContext,
      NewItem('~T~imed Dialog', '', kbNoKey, cmTestTimedDlg, hcNoContext,
      NewItem('Ta~b~s', '', kbNoKey, cmTestTabs, hcNoContext,
      NewItem('~S~tatuses', '', kbNoKey, cmTestStatuses, hcNoContext,
      NewItem('~C~olors', '', kbNoKey, cmTestColors, hcNoContext,
      NewItem('~O~utline', '', kbNoKey, cmTestOutline, hcNoContext,
      NewSubMenu('String~G~rid', hcNoContext, NewMenu(
        NewItem('~B~asic Test', '', kbNoKey, cmTestStringGrid, hcNoContext,
        NewItem('~B~roadcast Label', '', kbNoKey, cmTestStringGrid2, hcNoContext,
        NewItem('~C~allback Label', '', kbNoKey, cmTestStringGrid3, hcNoContext,
        nil)))),
      NewSubMenu('Ca~l~endar', hcNoContext, NewMenu(
        NewItem('~C~allback', '', kbNoKey, cmTestCalendar, hcNoContext,
        NewItem('~B~roadcast', '', kbNoKey, cmTestCalendarBroadcast, hcNoContext,
        nil))),
      NewSubMenu('~E~ditor', hcNoContext, NewMenu(
        NewItem('~N~ew Editor', '', kbNoKey, cmTestEditor, hcNoContext,
        NewItem('~F~ind/Replace', '', kbNoKey, cmTestEditorFind, hcNoContext,
        NewItem('File ~L~oad/Save', '', kbNoKey, cmTestEditorFile, hcNoContext,
        NewItem('~C~lipboard', '', kbNoKey, cmTestEditorClipboard, hcNoContext,
        nil))))),
      NewSubMenu('Ter~m~inal', hcNoContext, NewMenu(
        NewItem('~C~md.exe', '', kbNoKey, cmTestTerminalCmd, hcNoContext,
        NewItem('~P~owerShell', '', kbNoKey, cmTestTerminalPwsh, hcNoContext,
        NewItem('C~u~stom...', '', kbNoKey, cmTestTerminalCustom, hcNoContext,
        nil)))),
      nil))))))))))))))))))))),
    NewSubMenu('~W~indow', hcNoContext, NewMenu(
      NewItem('~T~ile', '', kbNoKey, cmTile, hcNoContext,
      NewItem('Tile ~H~orizontal', '', kbNoKey, cmTileHorizontal, hcNoContext,
      NewItem('Tile ~V~ertical', '', kbNoKey, cmTileVertical, hcNoContext,
      NewItem('C~a~scade', '', kbNoKey, cmCascade, hcNoContext,
      NewItem('Cascade (~K~eep Size)', '', kbNoKey, cmCascadeNoResize, hcNoContext,
      NewLine(
      NewItem('~N~ext', 'F6', kbF6, cmNext, hcNoContext,
      NewItem('~P~revious', 'Shift-F6', kbShiftF6, cmPrev, hcNoContext,
      NewLine(
      NewItem('~C~lose', 'Alt-F3', kbAltF3, cmClose, hcNoContext,
      NewItem('Close ~A~ll', '', kbNoKey, cmCloseAll, hcNoContext, nil)))))))))))),
    nil)))));
end;

procedure TMyApp.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := TMyStatusLine.Create(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      NewStatusKey('~F4~ New', kbF4, cmNewWindow,
      NewStatusKey('~F10~ Menu', kbF10, cmMenu,
      NewStatusKey('~Alt-F3~ Close', kbAltF3, cmClose, nil)))), nil));
end;

procedure TMyApp.HandleEvent(var Event: TEvent);
var
  TermWin: TTerminalWindow;
begin
  try
    { Intercept keyboard events for terminal windows in capture mode
      BEFORE inherited processing, so F10 etc. go to terminal instead
      of being converted to cmMenu by TApplication }
    if (Event.What = evKeyDown) and (Desktop <> nil) and
       (Desktop.Current <> nil) and (Desktop.Current is TTerminalWindow) then
    begin
      TermWin := TTerminalWindow(Desktop.Current);
      if TermWin.Terminal.Mode = tmCapture then
      begin
        TermWin.Terminal.HandleEvent(Event);
        if Event.What = evNothing then
          Exit;  { Event was handled by terminal }
      end;
    end;

    inherited HandleEvent(Event);

    if Event.What = evCommand then begin
      case Event.Command of
        cmNewWindow: NewWindow;
        cmTestWindow1: TestWindow1;
        cmTestWindow2: TestWindow2;
        cmTestDialog: TestDialog;
        cmTestScroller: TestScroller;
        cmTestMsgBox: TestMsgBox;
        cmTestInputBox: TestInputBox;
        cmTestFileOpen: TestFileOpen;
        cmTestChDir: TestChDir;
        cmTestColoredText: TestColoredText;
        cmTestInputLong: TestInputLong;
        cmTestAsciiChart: TestAsciiChart;
        cmTestTimedDlg: TestTimedDlg;
        cmTestTabs: TestTabs;
        cmTestStatuses: TestStatuses;
        cmTestColors: TestColors;
        cmTestOutline: TestOutline;
        cmTestEditor: TestEditor;
        cmTestEditorFind: TestEditorFind;
        cmTestEditorFile: TestEditorFile;
        cmTestEditorClipboard: TestEditorClipboard;
        cmTestCalendar: TestCalendar;
        cmTestCalendarBroadcast: TestCalendarBroadcast;
        cmTestStringGrid: TestStringGrid;
        cmTestStringGrid2: TestStringGrid2;
        cmTestStringGrid3: TestStringGrid3;
        cmTestTerminalCmd: TestTerminalCmd;
        cmTestTerminalPwsh: TestTerminalPwsh;
        cmTestTerminalCustom: TestTerminalCustom;
      else
        Exit;
      end;
      ClearEvent(Event);
    end;
  except
    on E: Exception do LogException('TMyApp.HandleEvent', E);
  end;
end;

procedure TMyApp.Idle;
var
  Hour, Min, Sec, MSec: Word;
begin
  try
    Inc(IdleCounter);
    DecodeTime(Now, Hour, Min, Sec, MSec);
    if Sec <> LastSecond then begin
      LastSecond := Sec;
      if StatusLine <> nil then begin
        StatusLine.DrawView;
      end;
    end;

    { Update gadgets }
    if ClockView <> nil then ClockView.Update;
    if HeapView <> nil then HeapView.Update;

    inherited Idle;
  except
    on E: Exception do LogException('TMyApp.Idle', E);
  end;
end;

procedure TMyApp.NewWindow;
var
  R: TRect;
  Win: TMyWindow;
begin
  Inc(WindowCount);
  R.Assign(0, 0, 40, 12);
  R.Move((WindowCount mod 5) * 2, (WindowCount mod 5));
  Win := TMyWindow.Create(R, 'Window ' + IntToStr(WindowCount), WindowCount);
  if Desktop <> nil then Desktop.Insert(Win);
end;

procedure TMyApp.TestWindow1;
{ Window with input line, radio buttons, static text }
var
  R: TRect;
  Win: TWindow;
begin
  R.Assign(5, 2, 40, 16);
  Win := TWindow.Create(R, 'Test Window 1', wnNoNumber);
  if Win <> nil then begin
    Win.Options := Win.Options or ofTileable;

    { Input line }
    R.Assign(3, 2, 30, 3);
    Win.Insert(TStaticText.Create(R, 'Enter your name:'));
    R.Assign(3, 3, 30, 4);
    Win.Insert(TInputLine.Create(R, 50));

    { Radio buttons }
    R.Assign(3, 5, 20, 6);
    Win.Insert(TStaticText.Create(R, 'Select option:'));
    R.Assign(3, 6, 25, 9);
    Win.Insert(TRadioButtons.Create(R,
      NewSItem('Option ~A~',
      NewSItem('Option ~B~',
      NewSItem('Option ~C~', nil)))));

    { Static text }
    R.Assign(3, 10, 32, 12);
    Win.Insert(TStaticText.Create(R,
      'This is a test window with input line and radio buttons.'));

    Desktop.Insert(Win);
  end;
end;

procedure TMyApp.TestWindow2;
{ Window with checkboxes }
var
  R: TRect;
  Win: TWindow;
begin
  R.Assign(10, 2, 45, 18);  { Made window taller: 16 rows }
  Win := TWindow.Create(R, 'Test Window 2', wnNoNumber);
  if Win <> nil then begin
    Win.Options := Win.Options or ofTileable;

    { Checkboxes }
    R.Assign(2, 1, 25, 2);
    Win.Insert(TStaticText.Create(R, 'Select features:'));
    R.Assign(2, 2, 32, 7);  { 5 items need 5 rows }
    Win.Insert(TCheckBoxes.Create(R,
      NewSItem('~E~nable logging',
      NewSItem('~S~how warnings',
      NewSItem('~A~uto-save',
      NewSItem('~D~ebug mode',
      NewSItem('~V~erbose output', nil)))))));

    { Another group of checkboxes }
    R.Assign(2, 8, 25, 9);
    Win.Insert(TStaticText.Create(R, 'Display options:'));
    R.Assign(2, 9, 32, 12);  { 3 items need 3 rows }
    Win.Insert(TCheckBoxes.Create(R,
      NewSItem('Show ~t~oolbar',
      NewSItem('Show status~b~ar',
      NewSItem('~F~ull screen', nil)))));

    Desktop.Insert(Win);
  end;
end;

procedure TMyApp.TestDialog;
{ Full dialog with buttons, listbox, input, checkboxes }
var
  R: TRect;
  Dlg: TDialog;
  ScrollBar: TScrollBar;
  ListBox: TStringListBox;
  List: TStringList;
begin
  R.Assign(5, 2, 70, 22);
  Dlg := TDialog.Create(R, 'Test Dialog');
  if Dlg <> nil then begin

    { Input line with label }
    R.Assign(3, 2, 30, 3);
    Dlg.Insert(TStaticText.Create(R, 'Name:'));
    R.Assign(10, 2, 35, 3);
    Dlg.Insert(TInputLine.Create(R, 80));

    { Another input line }
    R.Assign(3, 4, 30, 5);
    Dlg.Insert(TStaticText.Create(R, 'Value:'));
    R.Assign(10, 4, 35, 5);
    Dlg.Insert(TInputLine.Create(R, 80));

    { Checkboxes }
    R.Assign(3, 6, 30, 10);
    Dlg.Insert(TCheckBoxes.Create(R,
      NewSItem('Check ~1~',
      NewSItem('Check ~2~',
      NewSItem('Check ~3~', nil)))));

    { Radio buttons }
    R.Assign(3, 11, 30, 15);
    Dlg.Insert(TRadioButtons.Create(R,
      NewSItem('Radio ~A~',
      NewSItem('Radio ~B~',
      NewSItem('Radio ~C~', nil)))));

    { Scrollbar for listbox }
    R.Assign(58, 6, 59, 15);
    ScrollBar := TScrollBar.Create(R);
    Dlg.Insert(ScrollBar);

    { Listbox with strings }
    R.Assign(38, 6, 58, 15);
    ListBox := TStringListBox.Create(R, 1, ScrollBar);
    Dlg.Insert(ListBox);

    { Create string list for listbox }
    List := TStringList.Create;
    List.Add('Apple');
    List.Add('Banana');
    List.Add('Cherry');
    List.Add('Date');
    List.Add('Elderberry');
    List.Add('Fig');
    List.Add('Grape');
    List.Add('Honeydew');
    List.Add('Kiwi');
    List.Add('Lemon');
    List.Add('Mango');
    List.Add('Nectarine');
    List.Add('Orange');
    List.Add('Papaya');
    List.Add('Quince');
    ListBox.NewList(List);

    { Buttons }
    R.Assign(10, 16, 22, 18);
    Dlg.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));
    R.Assign(26, 16, 38, 18);
    Dlg.Insert(TButton.Create(R, '~C~ancel', cmCancel, bfNormal));
    R.Assign(42, 16, 54, 18);
    Dlg.Insert(TButton.Create(R, '~H~elp', cmHelp, bfNormal));

    { Execute as modal dialog }
    Desktop.ExecView(Dlg);
    Dlg.Free;
  end;
end;

procedure TMyApp.TestScroller;
{ Window with scrollable content to test TScroller and scrollbars }
var
  R: TRect;
  Win: TWindow;
  Scroller: TTextScroller;
  HScrollBar, VScrollBar: TScrollBar;
begin
  R.Assign(5, 2, 55, 20);
  Win := TWindow.Create(R, 'Scroller Test', wnNoNumber);
  if Win <> nil then begin
    Win.Options := Win.Options or ofTileable;

    { Create vertical scrollbar - inside the frame }
    Win.GetExtent(R);
    R.A.X := R.B.X - 2;       { One column inside right border }
    R.B.X := R.B.X - 1;       { Width = 1 }
    R.A.Y := 1;               { Below title bar }
    R.B.Y := R.B.Y - 2;       { Above bottom border and horizontal scrollbar }
    VScrollBar := TScrollBar.Create(R);
    VScrollBar.GrowMode := gfGrowLoX + gfGrowHiX + gfGrowHiY;
    Win.Insert(VScrollBar);

    { Create horizontal scrollbar - inside the frame }
    Win.GetExtent(R);
    R.A.X := 1;               { Inside left border }
    R.B.X := R.B.X - 2;       { Inside right border, before vertical scrollbar }
    R.A.Y := R.B.Y - 2;       { One row above bottom border }
    R.B.Y := R.B.Y - 1;       { Height = 1 }
    HScrollBar := TScrollBar.Create(R);
    HScrollBar.GrowMode := gfGrowLoY + gfGrowHiY + gfGrowHiX;
    Win.Insert(HScrollBar);

    { Create the scroller interior }
    Win.GetExtent(R);
    R.A.X := 1;               { Inside left border }
    R.A.Y := 1;               { Below title bar }
    R.B.X := R.B.X - 2;       { Before vertical scrollbar }
    R.B.Y := R.B.Y - 2;       { Above horizontal scrollbar }
    Scroller := TTextScroller.Create(R, HScrollBar, VScrollBar);
    Win.Insert(Scroller);

    Desktop.Insert(Win);
  end;
end;

procedure TMyApp.TestMsgBox;
begin
  { Test Warning message }
  MessageBox('This is a warning message.', mfWarning + mfOKButton);

  { Test Error message with OK/Cancel }
  MessageBox('An error has occurred!'#13#10'Do you want to continue?',
    mfError + mfOKCancel);

  { Test Information message }
  MessageBox('This is an information message.'#13#10 +
    'It can have multiple lines.', mfInformation + mfOKButton);

  { Test Confirmation with Yes/No/Cancel }
  MessageBox('Do you want to save changes before exiting?',
    mfConfirmation + mfYesNoCancel);
end;

procedure TMyApp.TestInputBox;
var
  Result: Word;
  UserInput: string;
begin
  UserInput := 'Default Value';
  Result := InputBox('Enter Value', '~V~alue:', UserInput, 50);
  if Result = cmOK then
    MessageBox('You entered: ' + UserInput, mfInformation + mfOKButton)
  else
    MessageBox('Input was cancelled.', mfInformation + mfOKButton);
end;

procedure TMyApp.TestFileOpen;
var
  Dlg: TFileDialog;
  FileName: PathStr;
  C: Word;
begin
  FileName := '';
  try
    Dlg := TFileDialog.Create('*.*', 'Open File', '~N~ame', fdOpenButton + fdHelpButton, 1);
  except
    on E: Exception do begin
      LogException('TestFileOpen.Init', E);
      Exit;
    end;
  end;
  if Dlg <> nil then begin
    try
      C := Desktop.ExecView(Dlg);
    except
      on E: Exception do begin
        LogException('TestFileOpen.ExecView', E);
        Dlg.Free;
        Exit;
      end;
    end;
    if C <> cmCancel then begin
      try
        Dlg.GetData(FileName);
      except
        on E: Exception do begin
          LogException('TestFileOpen.GetData', E);
          Dlg.Free;
          Exit;
        end;
      end;
    end;
    try
      Dlg.Free;
    except
      on E: Exception do begin
        LogException('TestFileOpen.Dispose', E);
        Exit;
      end;
    end;
    if C = cmFileOpen then
      MessageBox('Selected file: ' + FileName, mfInformation + mfOKButton);
  end;
end;

procedure TMyApp.TestChDir;
var
  Dlg: TChDirDialog;
begin
  Dlg := TChDirDialog.Create(cdNormal, 2);
  if Dlg <> nil then begin
    if ExecuteDialog(Dlg, nil) = cmOK then
      MessageBox('Directory changed successfully.', mfInformation + mfOKButton);
  end;
end;

procedure TMyApp.TestColoredText;
{ Window with colored static text examples }
var
  R: TRect;
  Win: TWindow;
begin
  R.Assign(5, 2, 50, 16);
  Win := TWindow.Create(R, 'Colored Text Test', wnNoNumber);
  if Win <> nil then begin
    Win.Options := Win.Options or ofTileable;

    { Normal static text for comparison }
    R.Assign(2, 1, 40, 2);
    Win.Insert(TStaticText.Create(R, 'Normal static text (palette color)'));

    { Red text on black: $04 = red foreground, black background }
    R.Assign(2, 3, 40, 4);
    Win.Insert(TColoredText.Create(R, 'Red text on black background', $04));

    { Yellow text on blue: $1E = blue bg (1), yellow fg (E) }
    R.Assign(2, 5, 40, 6);
    Win.Insert(TColoredText.Create(R, 'Yellow text on blue background', $1E));

    { White text on red: $4F = red bg (4), bright white fg (F) }
    R.Assign(2, 7, 40, 8);
    Win.Insert(TColoredText.Create(R, 'White text on red background', $4F));

    { Green text on black: $0A = green foreground }
    R.Assign(2, 9, 40, 10);
    Win.Insert(TColoredText.Create(R, 'Bright green text', $0A));

    { Cyan on black: $0B }
    R.Assign(2, 11, 40, 12);
    Win.Insert(TColoredText.Create(R, 'Cyan colored text', $0B));

    Desktop.Insert(Win);
  end;
end;

procedure TMyApp.TestInputLong;
{ Dialog with TInputLong for numeric input }
var
  R: TRect;
  Dlg: TDialog;
  InputLine: TInputLong;
  Value: LongInt;
begin
  R.Assign(10, 4, 60, 18);
  Dlg := TDialog.Create(R, 'InputLong Test');
  if Dlg <> nil then begin
    { Label and input for positive number }
    R.Assign(3, 2, 30, 3);
    Dlg.Insert(TStaticText.Create(R, 'Enter a number (0-1000):'));
    R.Assign(3, 3, 20, 4);
    InputLine := TInputLong.Create(R, 10, 0, 1000, 0);
    Dlg.Insert(InputLine);

    { Label and input for signed number }
    R.Assign(3, 5, 35, 6);
    Dlg.Insert(TStaticText.Create(R, 'Enter signed (-100 to 100):'));
    R.Assign(3, 6, 20, 7);
    Dlg.Insert(TInputLong.Create(R, 10, -100, 100, 0));

    { Label and input for hex number }
    R.Assign(3, 8, 35, 9);
    Dlg.Insert(TStaticText.Create(R, 'Enter hex ($0-$FF, use $):'));
    R.Assign(3, 9, 20, 10);
    Dlg.Insert(TInputLong.Create(R, 10, 0, 255, ilHex or ilDisplayHex));

    { Buttons }
    R.Assign(10, 11, 22, 13);
    Dlg.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));
    R.Assign(26, 11, 38, 13);
    Dlg.Insert(TButton.Create(R, 'Cancel', cmCancel, bfNormal));

    Dlg.SelectNext(False);

    { Set initial value }
    Value := 42;
    InputLine.SetData(Value);

    if Desktop.ExecView(Dlg) = cmOK then begin
      InputLine.GetData(Value);
      MessageBox('First value entered: ' + IntToStr(Value), mfInformation + mfOKButton);
    end;
    Dlg.Free;
  end;
end;

procedure TMyApp.TestAsciiChart;
{ Open ASCII Chart window }
var
  Chart: TASCIIChart;
begin
  Chart := TASCIIChart.Create;
  if Chart <> nil then begin
    { Center the window }
    Chart.MoveTo(
      (Desktop.Size.X - Chart.Size.X) div 2,
      (Desktop.Size.Y - Chart.Size.Y) div 2);
    Desktop.Insert(Chart);
  end;
end;

procedure TMyApp.TestTimedDlg;
{ Test timed message box that auto-closes after countdown }
begin
  { Show a timed message box that closes after 5 seconds }
  TimedMessageBox(
    'This message will close automatically in 5 seconds.'#13#10 +
    'Or click a button to close it now.',
    mfInformation + mfOKCancel,
    5);
end;

procedure TMyApp.TestTabs;
{ Test tabbed dialog with multiple tabs and dynamic add/remove }
var
  R: TRect;
  Dlg: TTabTestDialog;
  Tab: TTab;
  Input1, Input2, Input3: TInputLine;
  Check1: TCheckBoxes;
  Radio1: TRadioButtons;
begin
  R.Assign(5, 2, 65, 22);  { Made taller for extra buttons }
  Dlg := TTabTestDialog.Create(R, 'Tabbed Dialog Test');
  if Dlg <> nil then begin
    { Note: Inside TTab, content area starts at row 3 (after tab header) }
    { and column 1 (inside left border), ending at Size.X-2, Size.Y-2 }

    { Tab 1: General settings - views positioned relative to TTab origin }
    { Content area: rows 3-11, columns 1-52 }
    R.Assign(2, 4, 50, 5);  { Row 4 inside tab = visible in content area }
    Input1 := TInputLine.Create(R, 40);

    { Tab 2: Advanced options }
    R.Assign(2, 4, 50, 5);
    Input2 := TInputLine.Create(R, 40);
    R.Assign(2, 6, 40, 10);
    Check1 := TCheckBoxes.Create(R,
      NewSItem('~E~nable feature A',
      NewSItem('~D~ebug mode',
      NewSItem('~V~erbose logging', nil))));

    { Tab 3: Display settings }
    R.Assign(2, 4, 50, 5);
    Input3 := TInputLine.Create(R, 40);
    R.Assign(2, 6, 35, 10);
    Radio1 := TRadioButtons.Create(R,
      NewSItem('~S~mall',
      NewSItem('~M~edium',
      NewSItem('~L~arge', nil))));

    { Create tab control with 3 tabs }
    R.Assign(2, 1, 56, 14);
    Tab := TTab.Create(R,
      NewTabDef('~G~eneral', Input1,
        NewTabItem(Input1, nil),
      NewTabDef('~A~dvanced', Input2,
        NewTabItem(Input2,
        NewTabItem(Check1, nil)),
      NewTabDef('~D~isplay', Input3,
        NewTabItem(Input3,
        NewTabItem(Radio1, nil)),
      nil))));
    Dlg.Insert(Tab);
    Dlg.TabCtrl := Tab;  { Store reference for Add/Remove handlers }

    { Add Tab / Remove Tab buttons }
    R.Assign(2, 15, 16, 17);
    Dlg.Insert(TButton.Create(R, '~+~ Add Tab', cmAddTab, bfNormal));
    R.Assign(18, 15, 36, 17);
    Dlg.Insert(TButton.Create(R, '~-~ Remove Tab', cmRemoveTab, bfNormal));

    { OK / Cancel buttons }
    R.Assign(38, 15, 48, 17);
    Dlg.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));
    R.Assign(50, 15, 58, 17);
    Dlg.Insert(TButton.Create(R, 'Cancel', cmCancel, bfNormal));

    { Don't call SelectNext - Tab is already Current and should have focus }
    { Dlg.SelectNext(False); }

    Desktop.ExecView(Dlg);
    Dlg.Free;
  end;
end;

procedure TMyApp.TestStatuses;
{ Comprehensive test for Status/Gauge views from Statuses.pas }
var
  R: TRect;
  Dlg: TDialog;
  BarGauge: TBarGauge;
  PercentGauge: TPercentGauge;
  ArrowGaugeR, ArrowGaugeL: TArrowGauge;
  SpinnerGauge: TSpinnerGauge;
  UpdateBtn, ResetBtn: TButton;
  Event: TEvent;
  Finished: Boolean;
begin

  { Create a dialog to hold all the gauge types }
  R.Assign(10, 3, 70, 22);
  Dlg := TDialog.Create(R, 'Status/Gauge Demo');
  if Dlg = nil then Exit;

  { Label and Bar Gauge (progress bar with percentage) }
  R.Assign(2, 2, 20, 3);
  Dlg.Insert(TStaticText.Create(R, 'Bar Gauge:'));
  R.Assign(2, 3, 56, 4);
  BarGauge := TBarGauge.Create(R, cmUpdateGauge, 0, 100);
  BarGauge.Current := 35;
  Dlg.Insert(BarGauge);

  { Label and Percent Gauge }
  R.Assign(2, 5, 20, 6);
  Dlg.Insert(TStaticText.Create(R, 'Percent Gauge:'));
  R.Assign(22, 5, 36, 6);
  PercentGauge := TPercentGauge.Create(R, cmUpdateGauge, 0, 100);
  PercentGauge.Current := 35;
  Dlg.Insert(PercentGauge);

  { Label and Arrow Gauge (right-facing) }
  R.Assign(2, 7, 25, 8);
  Dlg.Insert(TStaticText.Create(R, 'Arrow Gauge (Right):'));
  R.Assign(2, 8, 56, 9);
  ArrowGaugeR := TArrowGauge.Create(R, cmUpdateGauge, 0, 100, True);
  ArrowGaugeR.Current := 35;
  Dlg.Insert(ArrowGaugeR);

  { Label and Arrow Gauge (left-facing) }
  R.Assign(2, 10, 25, 11);
  Dlg.Insert(TStaticText.Create(R, 'Arrow Gauge (Left):'));
  R.Assign(2, 11, 56, 12);
  ArrowGaugeL := TArrowGauge.Create(R, cmUpdateGauge, 0, 100, False);
  ArrowGaugeL.Current := 35;
  Dlg.Insert(ArrowGaugeL);

  { Label and Spinner Gauge }
  R.Assign(2, 13, 20, 14);
  Dlg.Insert(TStaticText.Create(R, 'Spinner Gauge:'));
  SpinnerGauge := TSpinnerGauge.Create(22, 13, cmUpdateGauge);
  Dlg.Insert(SpinnerGauge);

  { Buttons }
  R.Assign(2, 16, 18, 18);
  UpdateBtn := TButton.Create(R, '~U~pdate +10', cmUpdateGauge, bfNormal);
  Dlg.Insert(UpdateBtn);

  R.Assign(20, 16, 32, 18);
  ResetBtn := TButton.Create(R, '~R~eset', cmNo, bfNormal);
  Dlg.Insert(ResetBtn);

  R.Assign(44, 16, 56, 18);
  Dlg.Insert(TButton.Create(R, 'Close', cmOK, bfDefault));

  { Run the dialog with manual event loop for updates }
  Dlg.SetState(sfModal, True);
  Desktop.Insert(Dlg);
  Dlg.SetState(sfVisible, True);
  Dlg.DrawView;

  Finished := False;
  repeat
    GetEvent(Event);

    if Event.What = evCommand then begin
      case Event.Command of
        cmOK, cmCancel, cmClose: begin
          Finished := True;
          ClearEvent(Event);
        end;
        cmUpdateGauge: begin
          { Increment all gauges by 10 }
          if BarGauge.Current + 10 <= BarGauge.Max then
            BarGauge.Current := BarGauge.Current + 10
          else
            BarGauge.Current := BarGauge.Max;
          BarGauge.DrawView;

          if PercentGauge.Current + 10 <= PercentGauge.Max then
            PercentGauge.Current := PercentGauge.Current + 10
          else
            PercentGauge.Current := PercentGauge.Max;
          PercentGauge.DrawView;

          if ArrowGaugeR.Current + 10 <= ArrowGaugeR.Max then
            ArrowGaugeR.Current := ArrowGaugeR.Current + 10
          else
            ArrowGaugeR.Current := ArrowGaugeR.Max;
          ArrowGaugeR.DrawView;

          if ArrowGaugeL.Current + 10 <= ArrowGaugeL.Max then
            ArrowGaugeL.Current := ArrowGaugeL.Current + 10
          else
            ArrowGaugeL.Current := ArrowGaugeL.Max;
          ArrowGaugeL.DrawView;

          { Spinner cycles }
          SpinnerGauge.Update(nil);

          ClearEvent(Event);
        end;
        cmNo: begin
          { Reset all gauges }
          BarGauge.Current := 0;
          BarGauge.DrawView;
          PercentGauge.Current := 0;
          PercentGauge.DrawView;
          ArrowGaugeR.Current := 0;
          ArrowGaugeR.DrawView;
          ArrowGaugeL.Current := 0;
          ArrowGaugeL.DrawView;
          ClearEvent(Event);
        end;
      end;
    end;

    if Event.What <> evNothing then
      Dlg.HandleEvent(Event);

  until Finished;

  Desktop.Delete(Dlg);
  Dlg.Free;
end;

procedure TMyApp.TestColors;
{ Test color selection dialog }
var
  Dlg: TColorDialog;
  Groups: PColorGroup;
  Pal: TPalette;
  Result: Word;
begin
  { Build standard color groups }
  Groups :=
    ColorGroup('Desktop',
      DesktopColorItems(nil),
    ColorGroup('Menus',
      MenuColorItems(nil),
    ColorGroup('Dialogs/Windows',
      DialogColorItems(dpGrayDialog, nil),
    ColorGroup('Editor',
      WindowColorItems(wpBlueWindow, nil),
    nil))));

  { Create the color dialog with empty palette }
  Pal := '';
  Dlg := TColorDialog.Create(Pal, Groups);

  if Dlg <> nil then begin
    { Execute the dialog }
    Result := Desktop.ExecView(Dlg);
    if Result = cmOK then begin
      { Get the modified palette }
      Dlg.GetData(Pal);
      MessageBox('Colors dialog completed (OK)', mfInformation + mfOKButton);
    end;
    Dlg.Free;
  end;
end;

procedure TMyApp.TestOutline;
{ Test outline/tree view }
var
  R: TRect;
  Win: TWindow;
  OutlineView: TOutline;
  Root: PNode;
  HScrollBar, VScrollBar: TScrollBar;
begin
  {
    Build a sample tree structure:
    Nature
    +- Animals
    |  +- Mammals
    |  |  +- Dogs
    |  |  |  +- German Shepherd
    |  |  |  +- Labrador
    |  |  |  +- Poodle
    |  |  +- Cats
    |  |     +- Siamese
    |  |     +- Persian
    |  |     +- Maine Coon
    |  +- Birds
    |     +- Eagle
    |     +- Sparrow
    |     +- Penguin
    +- Plants
       +- Trees
       |  +- Oak
       |  +- Pine
       |  +- Maple
       +- Flowers
          +- Rose
          +- Tulip
          +- Daisy
  }

  { Build from leaves up, using NewNode(Text, Children, Next) }
  Root := NewNode('Nature',
    { First child: Animals }
    NewNode('Animals',
      { Children of Animals: Mammals (with its children) }
      NewNode('Mammals',
        { Children of Mammals: Dogs group }
        NewNode('Dogs',
          { Children of Dogs }
          NewNode('German Shepherd', nil,
          NewNode('Labrador', nil,
          NewNode('Poodle', nil, nil))),
          { Next sibling of Dogs: Cats }
          NewNode('Cats',
            { Children of Cats }
            NewNode('Siamese', nil,
            NewNode('Persian', nil,
            NewNode('Maine Coon', nil, nil))),
            nil)),  { No more siblings for Cats }
        { Next sibling of Mammals: Birds }
        NewNode('Birds',
          { Children of Birds }
          NewNode('Eagle', nil,
          NewNode('Sparrow', nil,
          NewNode('Penguin', nil, nil))),
          nil)),  { No more siblings for Birds }
      { Next sibling of Animals: Plants }
      NewNode('Plants',
        { Children of Plants: Trees }
        NewNode('Trees',
          { Children of Trees }
          NewNode('Oak', nil,
          NewNode('Pine', nil,
          NewNode('Maple', nil, nil))),
          { Next sibling of Trees: Flowers }
          NewNode('Flowers',
            { Children of Flowers }
            NewNode('Rose', nil,
            NewNode('Tulip', nil,
            NewNode('Daisy', nil, nil))),
            nil)),  { No more siblings for Flowers }
        nil)),  { No more siblings for Plants }
    nil);  { No siblings for Nature (root) }

  { Create window with outline view }
  R.Assign(5, 2, 50, 20);
  Win := TWindow.Create(R, 'Outline Test', wnNoNumber);
  if Win <> nil then begin
    Win.Options := Win.Options or ofTileable;

    { Create vertical scrollbar }
    Win.GetExtent(R);
    R.A.X := R.B.X - 2;
    R.B.X := R.B.X - 1;
    R.A.Y := 1;
    R.B.Y := R.B.Y - 1;
    VScrollBar := TScrollBar.Create(R);
    VScrollBar.GrowMode := gfGrowLoX + gfGrowHiX + gfGrowHiY;
    Win.Insert(VScrollBar);

    { Create horizontal scrollbar }
    Win.GetExtent(R);
    R.A.X := 1;
    R.B.X := R.B.X - 2;
    R.A.Y := R.B.Y - 2;
    R.B.Y := R.B.Y - 1;
    HScrollBar := TScrollBar.Create(R);
    HScrollBar.GrowMode := gfGrowLoY + gfGrowHiY + gfGrowHiX;
    Win.Insert(HScrollBar);

    { Create the outline view }
    Win.GetExtent(R);
    R.A.X := 1;
    R.A.Y := 1;
    R.B.X := R.B.X - 2;
    R.B.Y := R.B.Y - 2;
    OutlineView := TOutline.Create(R, HScrollBar, VScrollBar, Root);
    OutlineView.GrowMode := gfGrowHiX + gfGrowHiY;
    Win.Insert(OutlineView);

    Desktop.Insert(Win);

    { Select the outline so it has keyboard focus - must be after window is inserted }
    OutlineView.Select;
  end else begin
    { Clean up if window creation failed }
    DisposeNode(Root);
  end;
end;

procedure TMyApp.TestCalendar;
{ Test calendar view - opens in a window so events can be handled }
var
  R: TRect;
  Win: TWindow;
  CalView: TCalendarView;
  Y, M, D: Word;
  S: string;
begin
  R.Assign(0, 0, 28, 14);
  R.Move((Desktop.Size.X - R.B.X) div 2, (Desktop.Size.Y - R.B.Y) div 2);
  Win := TWindow.Create(R, 'Calendar', wnNoNumber);
  if Win <> nil then begin
    Win.Options := Win.Options or ofTileable;
    Win.Flags := Win.Flags and not (wfGrow or wfZoom);

    { Add the calendar view }
    R.Assign(2, 1, 24, 9);
    CalView := TCalendarView.Create(R);

    { Configure calendar: Monday as first day }
    CalView.SetFirstDayOfWeek(1);  { 0=Sunday, 1=Monday }

    { Make Sunday (0) use color 5 (typically highlight) }
    CalView.SetDayColor(0, 5);  { Sunday }
    { Saturday can also be colored }
    CalView.SetDayColor(6, 5);  { Saturday }

    { Set up callback for date changes }
    CalView.OnDateSelect := OnCalendarDateSelect;

    Win.Insert(CalView);

    { Add label to show selected date }
    CalView.GetDate(Y, M, D);
    S := Format('Selected: %d/%d/%d', [M, D, Y]);
    R.Assign(2, 10, 26, 11);
    FCalendarDateLabel := TStaticText.Create(R, S);
    Win.Insert(FCalendarDateLabel);

    { Instructions }
    R.Assign(2, 9, 26, 10);
    Win.Insert(TStaticText.Create(R, 'Click < > month year'));

    Desktop.Insert(Win);
    CalView.Select;
  end;
end;

procedure TMyApp.OnCalendarDateSelect(Calendar: TCalendarView);
var
  Y, M, D: Word;
  S: ShortString;
begin
  if (Calendar <> nil) and (FCalendarDateLabel <> nil) then begin
    Calendar.GetDate(Y, M, D);
    S := ShortString(Format('Selected: %d/%d/%d', [M, D, Y]));
    { Update the label text }
    FCalendarDateLabel.Text := string(S);
    FCalendarDateLabel.DrawView;
  end;
end;

procedure TMyApp.TestCalendarBroadcast;
{ Test calendar using broadcast message approach }
var
  R: TRect;
  Win: TCalendarWindow;
begin
  R.Assign(0, 0, 28, 14);
  R.Move((Desktop.Size.X - R.B.X) div 2 + 5, (Desktop.Size.Y - R.B.Y) div 2 + 2);
  Win := TCalendarWindow.Create(R);
  if Win <> nil then
    Desktop.Insert(Win);
end;

procedure TMyApp.TestStringGrid;
{ Test the TStringGrid component }
var
  R: TRect;
  Win: TWindow;
  Grid: TStringGrid;
  HScrollBar, VScrollBar: TScrollBar;
  I: Integer;
begin
  R.Assign(3, 1, 75, 22);
  Win := TWindow.Create(R, 'StringGrid Test', wnNoNumber);
  if Win <> nil then begin
    Win.Options := Win.Options or ofTileable;

    { Create vertical scrollbar }
    Win.GetExtent(R);
    R.A.X := R.B.X - 2;
    R.B.X := R.B.X - 1;
    R.A.Y := 1;
    R.B.Y := R.B.Y - 2;
    VScrollBar := TScrollBar.Create(R);
    VScrollBar.GrowMode := gfGrowLoX + gfGrowHiX + gfGrowHiY;
    Win.Insert(VScrollBar);

    { Create horizontal scrollbar }
    Win.GetExtent(R);
    R.A.X := 1;
    R.B.X := R.B.X - 2;
    R.A.Y := R.B.Y - 2;
    R.B.Y := R.B.Y - 1;
    HScrollBar := TScrollBar.Create(R);
    HScrollBar.GrowMode := gfGrowLoY + gfGrowHiY + gfGrowHiX;
    Win.Insert(HScrollBar);

    { Create the string grid }
    Win.GetExtent(R);
    R.A.X := 1;
    R.A.Y := 1;
    R.B.X := R.B.X - 2;
    R.B.Y := R.B.Y - 2;
    Grid := TStringGrid.Create(R, 6, HScrollBar, VScrollBar);
    Grid.GrowMode := gfGrowHiX + gfGrowHiY;

    { Configure columns }
    Grid.Columns[0].Title := 'ID';
    Grid.Columns[0].Width := 5;
    Grid.Columns[0].Alignment := gaRight;

    Grid.Columns[1].Title := 'Name';
    Grid.Columns[1].Width := 15;
    Grid.Columns[1].Alignment := gaLeft;

    Grid.Columns[2].Title := 'Value';
    Grid.Columns[2].Width := 10;
    Grid.Columns[2].Alignment := gaRight;

    Grid.Columns[3].Title := 'Status';
    Grid.Columns[3].Width := 12;
    Grid.Columns[3].Alignment := gaCenter;

    Grid.Columns[4].Title := 'Unicode';
    Grid.Columns[4].Width := 16;
    Grid.Columns[4].Alignment := gaLeft;

    Grid.Columns[5].Title := 'Notes';
    Grid.Columns[5].Width := 20;
    Grid.Columns[5].Alignment := gaLeft;

    { Set grid options }
    Grid.FixedRows := 1;
    Grid.ShowGridLines := True;
    Grid.SelectionMode := smRow;

    { Add some test data - start at row 1 (row 0 is header) }
    Grid.RowCount := 21;  { 1 header + 20 data rows }
    for I := 1 to 20 do begin
      Grid[0, I] := IntToStr(I);
      Grid[1, I] := 'Item ' + IntToStr(I);
      Grid[2, I] := Format('%.2f', [Random * 1000]);
      case I mod 4 of
        0: Grid[3, I] := 'Active';
        1: Grid[3, I] := 'Pending';
        2: Grid[3, I] := 'Completed';
        3: Grid[3, I] := 'Cancelled';
      end;
      { Unicode test data - various scripts and symbols }
      case I mod 10 of
        1: Grid[4, I] := 'Grüß Gott 🦚';        { German }
        2: Grid[4, I] := 'Café français';    { French }
        3: Grid[4, I] := 'Señor España';     { Spanish }
        4: Grid[4, I] := 'Привет мир';       { Russian }
        5: Grid[4, I] := 'Ελληνικά';         { Greek }
        6: Grid[4, I] := '日本語テスト';      { Japanese }
        7: Grid[4, I] := '中文测试';          { Chinese }
        8: Grid[4, I] := '한국어';            { Korean }
        9: Grid[4, I] := '★♠♥♦♣';            { Symbols }
        0: Grid[4, I] := 'αβγδεζηθ';         { Greek letters }
      end;
      Grid[5, I] := 'Note for item ' + IntToStr(I);
    end;

    Win.Insert(Grid);
    Desktop.Insert(Win);
    Grid.Select;
  end;
end;

procedure TMyApp.TestStringGrid2;
{ Test the TStringGrid component with broadcast label }
var
  R: TRect;
  Win: TGridTestWindow;
begin
  R.Assign(5, 2, 60, 20);
  Win := TGridTestWindow.Create(R);
  if Win <> nil then
    Desktop.Insert(Win);
end;

procedure TMyApp.TestStringGrid3;
{ Test the TStringGrid component with callback label }
var
  R: TRect;
  Win: TWindow;
  Grid: TStringGrid;
  HScrollBar, VScrollBar: TScrollBar;
  I: Integer;
begin
  R.Assign(8, 3, 65, 21);
  Win := TWindow.Create(R, 'StringGrid (Callback)', wnNoNumber);
  if Win <> nil then begin
    Win.Options := Win.Options or ofTileable;
    Win.Flags := Win.Flags and not wfZoom;

    { Create vertical scrollbar }
    Win.GetExtent(R);
    R.A.X := R.B.X - 2;
    R.B.X := R.B.X - 1;
    R.A.Y := 1;
    R.B.Y := R.B.Y - 4;
    VScrollBar := TScrollBar.Create(R);
    VScrollBar.GrowMode := gfGrowLoX + gfGrowHiX + gfGrowHiY;
    Win.Insert(VScrollBar);

    { Create horizontal scrollbar }
    Win.GetExtent(R);
    R.A.X := 1;
    R.B.X := R.B.X - 2;
    R.A.Y := R.B.Y - 4;
    R.B.Y := R.B.Y - 3;
    HScrollBar := TScrollBar.Create(R);
    HScrollBar.GrowMode := gfGrowLoY + gfGrowHiY + gfGrowHiX;
    Win.Insert(HScrollBar);

    { Create the string grid }
    Win.GetExtent(R);
    R.A.X := 1;
    R.A.Y := 1;
    R.B.X := R.B.X - 2;
    R.B.Y := R.B.Y - 4;
    Grid := TStringGrid.Create(R, 3, HScrollBar, VScrollBar);
    Grid.GrowMode := gfGrowHiX + gfGrowHiY;

    { Configure columns }
    Grid.Columns[0].Title := 'Col 0';
    Grid.Columns[0].Width := 8;
    Grid.Columns[1].Title := 'Col 1';
    Grid.Columns[1].Width := 15;
    Grid.Columns[2].Title := 'Col 2';
    Grid.Columns[2].Width := 12;

    { Set grid options }
    Grid.FixedRows := 1;
    Grid.ShowGridLines := True;
    Grid.SelectionMode := smCell;

    { Set up callback }
    Grid.OnCellFocused := OnGridCellFocused;
    FCallbackGrid := Grid;

    { Add test data }
    Grid.RowCount := 11;
    for I := 1 to 10 do begin
      Grid[0, I] := Format('R%d C0', [I]);
      Grid[1, I] := Format('Row %d Col 1', [I]);
      Grid[2, I] := Format('Data %d', [I]);
    end;

    Win.Insert(Grid);

    { Add label to show cell info }
    Win.GetExtent(R);
    R.A.X := 1;
    R.A.Y := R.B.Y - 3;
    R.B.X := R.B.X - 1;
    R.B.Y := R.B.Y - 2;
    FGridCellLabel := TStaticText.Create(R, 'Click a cell (callback mode)');
    Win.Insert(FGridCellLabel);

    { Instructions }
    Win.GetExtent(R);
    R.A.X := 1;
    R.A.Y := R.B.Y - 2;
    R.B.X := R.B.X - 1;
    R.B.Y := R.B.Y - 1;
    Win.Insert(TStaticText.Create(R, 'Using OnCellFocused callback'));

    Desktop.Insert(Win);
    Grid.Select;
  end;
end;

procedure TMyApp.OnGridCellFocused(Sender: TObject; Col, Row: Integer);
var
  Grid: TStringGrid;
  S: string;
  CellText: string;
begin
  if (Sender = FCallbackGrid) and (FGridCellLabel <> nil) then begin
    Grid := TStringGrid(Sender);
    CellText := Grid[Col, Row];
    S := Format('CB: %d,%d: %s', [Col, Row, CellText]);
    FGridCellLabel.Text := S;
    FGridCellLabel.DrawView;
  end;
end;

{ Editor test cases }
procedure TMyApp.TestEditor;
{ Test editor window - opens a new editor or edits a file }
var
  R: TRect;
  Win: TEditWindow;
begin
  { Set up standard editor dialogs }
  EditorDialog := StdEditorDialog;

  Inc(WindowCount);
  R.Assign(3, 2, 72, 22);
  R.Move((WindowCount mod 4) * 2, (WindowCount mod 4));
  Win := TEditWindow.Create(R, '', WindowCount);
  if Win <> nil then
    Desktop.Insert(Win);
end;

procedure TMyApp.TestEditorFind;
{ Test editor Find/Replace dialogs }
var
  R: TRect;
  Win: TEditWindow;
  Editor: TEditor;
  TestText: AnsiString;
begin
  { Set up standard editor dialogs }
  EditorDialog := StdEditorDialog;

  Inc(WindowCount);
  R.Assign(3, 2, 72, 22);
  R.Move((WindowCount mod 4) * 2, (WindowCount mod 4));
  Win := TEditWindow.Create(R, '', WindowCount);
  if Win <> nil then begin
    Desktop.Insert(Win);

    { Get the editor and insert test text }
    Editor := Win.Editor;
    if Editor <> nil then begin
      TestText := 'This is a test line.' + #13#10 +
                  'Find this word: apple' + #13#10 +
                  'Another line with apple here.' + #13#10 +
                  'And more text follows.' + #13#10 +
                  'Replace apple with orange.' + #13#10;
      Editor.InsertText(@TestText[1], Length(TestText), False);

      { Now trigger Find dialog - user can test interactively }
      { Press Ctrl+Q F to find, Ctrl+Q A to replace }
      MessageBox('Editor opened with test text.'#13#10 +
                 'Press Ctrl+Q F to Find'#13#10 +
                 'Press Ctrl+Q A to Replace'#13#10 +
                 'Try searching for "apple"',
                 mfInformation or mfOKButton);
    end;
  end;
end;

procedure TMyApp.TestEditorFile;
{ Test editor File Load/Save operations }
var
  R: TRect;
  Win: TEditWindow;
  TestFileName: string;
  TestText: AnsiString;
begin
  { Set up standard editor dialogs }
  EditorDialog := StdEditorDialog;

  TestFileName := 'editor_test.txt';

  { First, create an editor with a file }
  Inc(WindowCount);
  R.Assign(3, 2, 72, 22);
  R.Move((WindowCount mod 4) * 2, (WindowCount mod 4));
  Win := TEditWindow.Create(R, TestFileName, WindowCount);
  if Win <> nil then begin
    Desktop.Insert(Win);

    if Win.Editor <> nil then begin
      { Insert some test content }
      if Win.Editor.BufLen = 0 then begin
        { New file - add content }
        TestText := 'This is a test file.'#13#10 +
                    'Line 2 of the test.'#13#10 +
                    'Line 3 - save and reload to test.'#13#10;
        Win.Editor.InsertText(@TestText[1], Length(TestText), False);
      end;

      MessageBox('Editor opened with file: ' + TestFileName + #13#10 +
                 'Press Ctrl+K S to Save'#13#10 +
                 'Press Ctrl+K F to Save As'#13#10 +
                 'Press Ctrl+K D to Save and Close'#13#10 +
                 'Edit the text and save to test file operations.',
                 mfInformation or mfOKButton);
    end;
  end;
end;

procedure TMyApp.TestEditorClipboard;
{ Test editor Clipboard operations (Cut/Copy/Paste) }
var
  R: TRect;
  Win1, Win2: TEditWindow;
  ClipWin: TEditWindow;
  Editor: TEditor;
  TestText: AnsiString;
  ClipR: TRect;
begin
  { Set up standard editor dialogs }
  EditorDialog := StdEditorDialog;

  { Create a clipboard editor (hidden or visible for testing) }
  ClipR.Assign(0, 0, 40, 10);
  ClipWin := TEditWindow.Create(ClipR, 'Clipboard', 0);
  if ClipWin <> nil then begin
    { Set the global clipboard }
    Clipboard := ClipWin.Editor;

    { Create first editor with source text }
    Inc(WindowCount);
    R.Assign(2, 1, 40, 15);
    Win1 := TEditWindow.Create(R, 'Source', WindowCount);
    if Win1 <> nil then begin
      Desktop.Insert(Win1);
      Editor := Win1.Editor;
      if Editor <> nil then begin
        TestText := 'Source text for clipboard test.' + #13#10 +
                    'Select this line and copy it.' + #13#10 +
                    'Or cut this text to move it.' + #13#10 +
                    'Then paste into the other window.' + #13#10;
        Editor.InsertText(@TestText[1], Length(TestText), False);
      end;
    end;

    { Create second editor as destination }
    Inc(WindowCount);
    R.Assign(42, 1, 78, 15);
    Win2 := TEditWindow.Create(R, 'Destination', WindowCount);
    if Win2 <> nil then begin
      Desktop.Insert(Win2);
      Editor := Win2.Editor;
      if Editor <> nil then begin
        TestText := 'Paste text here:' + #13#10 + #13#10;
        Editor.InsertText(@TestText[1], Length(TestText), False);
      end;
    end;

    R.Assign(0, 0, 50, 14);
    R.Move((Desktop.Size.X - R.B.X) div 2, (Desktop.Size.Y - R.B.Y) div 2);
    MessageBoxRect(R,
               'Clipboard Test Instructions:'#13#10 +
               #13#10 +
               'In Source window:'#13#10 +
               '  Select text: Shift+arrows'#13#10 +
               '  Copy: Ctrl+Ins'#13#10 +
               '  Cut: Shift+Del or Ctrl+K Y'#13#10 +
               #13#10 +
               'In Destination window:'#13#10 +
               '  Paste: Shift+Ins or Ctrl+K C',
               mfInformation or mfOKButton);
  end;
end;

procedure TMyApp.TestTerminalCmd;
{ Open a terminal window running cmd.exe }
const
  TerminalHelp =
    'Terminal Keyboard Controls:'#13#10 +
    #13#10 +
    'Ctrl+A, <key>  - Exit capture, send <key> to app'#13#10 +
    'Ctrl+A, Ctrl+A - Send literal Ctrl+A to terminal'#13#10 +
    'Shift+PgUp/Dn  - Scroll through history'#13#10 +
    #13#10 +
    'Click or press Enter/Esc to re-enter capture mode.';
var
  R: TRect;
  Win: TTerminalWindow;
begin
  MessageBox(TerminalHelp, mfInformation or mfOKButton);

  Inc(WindowCount);
  R.Assign(2, 1, 82, 26);
  R.Move((WindowCount mod 4) * 2, (WindowCount mod 4));
  Win := TTerminalWindow.Create(R, 'Terminal - cmd.exe');
  if Win <> nil then begin
    Desktop.Insert(Win);
    if not Win.Execute('cmd.exe') then
      MessageBox('Failed to start cmd.exe: ' + Win.Terminal.ConPTY.LastError,
                 mfError or mfOKButton)
    else
      Win.Terminal.Select;  { Ensure terminal has focus for capture mode }
  end;
end;

procedure TMyApp.TestTerminalPwsh;
{ Open a terminal window running PowerShell }
const
  TerminalHelp =
    'Terminal Keyboard Controls:'#13#10 +
    #13#10 +
    'Ctrl+A, <key>  - Exit capture, send <key> to app'#13#10 +
    'Ctrl+A, Ctrl+A - Send literal Ctrl+A to terminal'#13#10 +
    'Shift+PgUp/Dn  - Scroll through history'#13#10 +
    #13#10 +
    'Click or press Enter/Esc to re-enter capture mode.';
var
  R: TRect;
  Win: TTerminalWindow;
  Started: Boolean;
begin
  MessageBox(TerminalHelp, mfInformation or mfOKButton);

  Inc(WindowCount);
  R.Assign(2, 1, 82, 26);
  R.Move((WindowCount mod 4) * 2, (WindowCount mod 4));
  Win := TTerminalWindow.Create(R, 'Terminal - PowerShell');
  if Win <> nil then begin
    Desktop.Insert(Win);
    Started := Win.Execute('pwsh.exe');
    if not Started then
      { Try Windows PowerShell if PowerShell Core not available }
      Started := Win.Execute('powershell.exe');
    if Started then
      Win.Terminal.Select  { Ensure terminal has focus for capture mode }
    else
      MessageBox('Failed to start PowerShell',
                 mfError or mfOKButton);
  end;
end;

procedure TMyApp.TestTerminalCustom;
{ Open a terminal window with user-specified command }
const
  TerminalHelp =
    'Terminal Keyboard Controls:'#13#10 +
    #13#10 +
    'Ctrl+A, <key>  - Exit capture, send <key> to app'#13#10 +
    'Ctrl+A, Ctrl+A - Send literal Ctrl+A to terminal'#13#10 +
    'Shift+PgUp/Dn  - Scroll through history'#13#10 +
    #13#10 +
    'Click or press Enter/Esc to re-enter capture mode.';
var
  R: TRect;
  Win: TTerminalWindow;
  CommandLine: string;
  InputResult: Word;
begin
  MessageBox(TerminalHelp, mfInformation or mfOKButton);

  CommandLine := 'cmd.exe';
  InputResult := InputBox('Run Command', 'Command ~L~ine:', CommandLine, 255);
  if InputResult = cmOK then begin
    Inc(WindowCount);
    R.Assign(2, 1, 82, 26);
    R.Move((WindowCount mod 4) * 2, (WindowCount mod 4));
    Win := TTerminalWindow.Create(R, 'Terminal - ' + CommandLine);
    if Win <> nil then begin
      Desktop.Insert(Win);
      if not Win.Execute(CommandLine) then
        MessageBox('Failed to execute: ' + CommandLine + #13#10 +
                   Win.Terminal.ConPTY.LastError,
                   mfError or mfOKButton)
      else
        Win.Terminal.Select;  { Ensure terminal has focus for capture mode }
    end;
  end;
end;

begin
  WindowCount := 0;
  try
    MyApp := TMyApp.Create;
    MyApp.Run;
    MyApp.Free;
  except
    on E: Exception do begin
      LogException('Main', E);
      WriteLn('Exception: ', E.Message);
    end;
  end;

  { Close exception log if it was opened }
  if ExceptionLogOpen then
    CloseFile(ExceptionLog);
end.
