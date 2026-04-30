program FVTest;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  FVInterfaces in 'src\FVInterfaces.pas',
  FVSerialization in 'src\FVSerialization.pas',
  Objects in 'src\Objects.pas',
  FVScreen in 'src\FVScreen.pas',
  FVBoxChars in 'src\FVBoxChars.pas',
  FVUnicodeWidth in 'src\FVUnicodeWidth.pas',
  FVProfile in 'src\FVProfile.pas',
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
  Terminal in 'src\Terminal.pas',
  HexEdit in 'src\HexEdit.pas',
  UptimeView in 'src\UptimeView.pas',
  ToggleSwitch in 'src\ToggleSwitch.pas',
  LogViewer in 'src\LogViewer.pas',
  LEDDigits in 'src\LEDDigits.pas',
  BlinkIndicator in 'src\BlinkIndicator.pas',
  Marquee in 'src\Marquee.pas',
  Sparkline in 'src\Sparkline.pas',
  BarChart in 'src\BarChart.pas',
  VUMeter in 'src\VUMeter.pas',
  RAMView in 'src\RAMView.pas',
  DiskUsageView in 'src\DiskUsageView.pas',
  ProcessView in 'src\ProcessView.pas',
  CPUMeter in 'src\CPUMeter.pas',
  BatteryView in 'src\BatteryView.pas',
  NetworkView in 'src\NetworkView.pas',
  CPUCoreView in 'src\CPUCoreView.pas',
  ProgressBar in 'src\ProgressBar.pas',
  Breadcrumb in 'src\Breadcrumb.pas',
  ToolBar in 'src\ToolBar.pas',
  ComboBox in 'src\ComboBox.pas',
  Splitter in 'src\Splitter.pas',
  Accordion in 'src\Accordion.pas',
  EditorGutter in 'src\EditorGutter.pas',
  Notification in 'src\Notification.pas',
  SpinnerView in 'src\SpinnerView.pas',
  TaskProgress in 'src\TaskProgress.pas',
  CheckListBox in 'src\CheckListBox.pas',
  FVClipboard in 'src\FVClipboard.pas',
  SixelEncoder in 'src\SixelEncoder.pas',
  SixelView in 'src\SixelView.pas',
  ImageView in 'src\ImageView.pas',
  TreeView in 'src\TreeView.pas',
  PopupMenu in 'src\PopupMenu.pas',
  FuzzyFinder in 'src\FuzzyFinder.pas',
  Tooltip in 'src\Tooltip.pas',
  SyntaxHighlight in 'src\SyntaxHighlight.pas',
  MarkdownView in 'src\MarkdownView.pas';

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
  cmTestFolderSelect = 1040;
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
  cmTestHexEditor = 1032;
  cmTestStringGridCSV = 1033;
  cmGridLoadCSV = 1034;
  cmGridSaveCSV = 1035;
  cmHexLoadFile = 1036;
  cmHexSaveFile = 1037;
  cmTestModernFileDialog = 1038;
  cmTestNewGadgets = 1039;
  cmAddLogEntry = 1040;
  cmTestGadgetsPhase2 = 1041;
  cmAddSparkValue = 1042;
  cmAddBarValue = 1043;
  cmTestSystemInfo = 1044;
  cmTestEmojiWide = 1045;
  cmTestProgressBar  = 1050;
  cmTestBreadcrumb   = 1051;
  cmTestToolBar      = 1052;
  cmTestComboBox     = 1053;
  cmTestSplitter     = 1054;
  cmTestAccordion    = 1055;
  cmTestEditorGutter = 1056;
  cmTestNotification = 1057;
  cmTestClipboard    = 1058;
  cmTestImageView    = 1059;
  cmTestSixelSpectrometer = 1060;
  cmTestSixelSine         = 1061;
  cmTestCommandSet        = 1062;
  cmTestKeyUpDown         = 1063;
  cmTestConsoleFocus      = 1064;
  cmTestTextAttrs         = 1065;
  cmTestPasteDetect       = 1066;
  cmTestTreeView          = 1067;
  cmTestFuzzyFinder       = 1068;
  cmTestTooltip           = 1069;
  cmTestGridFilter        = 1070;
  cmTestSyntaxHL          = 1072;
  cmTestMarkdownView      = 1073;
  cmTestPopupAutoComplete = 1074;
  cmTestSpinnerGallery    = 1075;
  cmTestMultiProgress     = 1076;
  cmTestCheckList         = 1077;
  cmTestHyperlink         = 1078;
  cmTestProfileDump       = 1079;
  cmTestCapabilityShowcase = 1080;
  cmTestColorModes        = 1081;

  { Local commands inside the Color Modes demo dialog. }
  cmDemoPaletteSwap     = 70;  { Solarized Dark }
  cmDemoPaletteReset    = 71;
  cmDemoPaletteDracula  = 72;
  cmDemoPaletteDork     = 73;

  { Local commands for CommandSet demo - must be 0..255 to work with TCommandSet }
  cmDemoSave    = 60;
  cmDemoPrint   = 61;
  cmDemoExport  = 62;
  cmDemoToggle  = 63;

var
  ExceptionLog: TextFile;
  ExceptionLogOpen: Boolean = False;
  ExceptionLogName: string = '';
  IdleCounter: Integer = 0;
  LastSecond: Word = 65535;
  ClockView: TClockView = nil;
  HeapView: THeapView = nil;
  UptimeViewGadget: TUptimeView = nil;

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

procedure DebugLog(const Msg: string);
const
  LogPath = 'C:\projects\fv-delphi-modern\fvtest_debug.log';
var
  F: TextFile;
begin
  AssignFile(F, LogPath);
  if FileExists(LogPath) then
    Append(F)
  else
    Rewrite(F);
  WriteLn(F, FormatDateTime('hh:nn:ss.zzz', Now), ' ', Msg);
  CloseFile(F);
end;


type
  TMyStatusLine = class;
  TMyApp = class;
  TCalendarWindow = class;
  TGridTestWindow = class;
  TTextScroller = class;
  TMyWindow = class;
  TTabTestDialog = class;
  TSixelSpectrometerWindow = class;
  TSixelSineWindow = class;

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
    procedure TestFolderSelect;
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
    procedure TestStringGridCSV;
    procedure OnCalendarDateSelect(Calendar: TCalendarView);
    procedure OnGridCellFocused(Sender: TObject; Col, Row: Integer);
    procedure TestTerminalCmd;
    procedure TestTerminalPwsh;
    procedure TestTerminalCustom;
    procedure TestHexEditor;
    procedure TestModernFileDialog;
    procedure TestNewGadgets;
    procedure TestGadgetsPhase2;
    procedure TestSystemInfo;
    procedure TestEmojiWide;
    procedure TestProgressBar;
    procedure TestBreadcrumb;
    procedure TestToolBar;
    procedure TestComboBox;
    procedure TestSplitter;
    procedure TestAccordion;
    procedure TestEditorGutter;
    procedure TestNotification;
    procedure TestClipboard;
    procedure TestImageView;
    procedure TestSixelSpectrometer;
    procedure TestSixelSine;
    procedure TestCommandSet;
    procedure TestKeyUpDown;
    procedure TestConsoleFocus;
    procedure TestTextAttrs;
    procedure TestPasteDetect;
    procedure TestTreeView;
    procedure TestFuzzyFinder;
    procedure TestTooltip;
    procedure TestGridFilter;
    procedure TestSyntaxHL;
    procedure TestMarkdownView;
    procedure TestPopupAutoComplete;
    procedure TestSpinnerGallery;
    procedure TestMultiProgress;
    procedure TestCheckList;
    procedure TestHyperlink;
    procedure TestProfileDump;
    procedure TestCapabilityShowcase;
    procedure TestColorModes;
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

  { Custom window for grid CSV load/save testing }
  TGridCSVTestWindow = class(TWindow)
  private
    FStatusLabel: TStaticText;
    FGrid: TStringGrid;
    FFixedHeaderCheck: TCheckBoxes;
    FDelimiterInput: TInputLine;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure HandleEvent(var Event: TEvent); override;
    procedure LoadCSV;
    procedure SaveCSV;
    function GetCSVOptions: TCSVOptions;
    property StatusLabel: TStaticText read FStatusLabel write FStatusLabel;
    property Grid: TStringGrid read FGrid write FGrid;
  end;

  { Custom window for hex editor load/save testing }
  THexTestWindow = class(TWindow)
  private
    FStatusLabel: TStaticText;
    FEditor: THexEditor;
    FDataSource: TMemoryHexSource;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    destructor Destroy; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure LoadFile;
    procedure SaveFile;
    property StatusLabel: TStaticText read FStatusLabel write FStatusLabel;
    property Editor: THexEditor read FEditor;
  end;

  { Custom dialog for new gadgets demo }
  TGadgetsDemoDialog = class(TDialog)
  private
    FLogView: TLogViewer;
    FAutoScrollToggle: TToggleSwitch;
    FTimestampToggle: TToggleSwitch;
    FDebugToggle: TToggleSwitch;
    FLogCounter: Integer;
  public
    constructor Create; reintroduce;
    procedure HandleEvent(var Event: TEvent); override;
    procedure AddRandomLogEntry;
    property LogView: TLogViewer read FLogView;
  end;

  { Phase 2 gadgets demo dialog }
  TPhase2DemoDialog = class(TDialog)
  private
    FLEDDigits: TLEDDigits;
    FBlinker1, FBlinker2, FBlinker3: TBlinkIndicator;
    FMarquee: TMarquee;
    FSparkline: TSparkline;
    FBarChart: TBarChart;
    FVUMeter: TVUMeter;
    FCounter: Integer;
    FVUValue: Double;
    FVUDirection: Integer;
  public
    constructor Create; reintroduce;
    procedure HandleEvent(var Event: TEvent); override;
    procedure UpdateGadgets;
  end;

  { Demo dialog for CommandSetChanged mechanism }
  TCommandSetDemoDialog = class(TDialog)
  private
    FEnabled: Boolean;
    FStatusLabel: TStaticText;
  public
    constructor Create; reintroduce;
    procedure HandleEvent(var Event: TEvent); override;
  end;

  { Interior content view for key-up/key-down demo }
  TKeyUpDownView = class(TView)
  public
    FEventLog: array[0..11] of string;  { Scrolling event log lines }
    FHeldKeys: array[0..7] of string;   { Currently held key names }
    FHeldCount: Integer;
    procedure Draw; override;
    procedure AddLogLine(const S: string);
    procedure KeyPressed(const Name: string);
    procedure KeyReleased(const Name: string);
    function VKeyName(VKey: Word; UChar: Char): string;
  end;

  { Demo dialog for key-up/key-down events }
  TKeyUpDownDemo = class(TDialog)
  private
    FContent: TKeyUpDownView;
  public
    constructor Create; reintroduce;
    procedure HandleEvent(var Event: TEvent); override;
  end;

  { Interior content view for console focus demo }
  TConsoleFocusView = class(TView)
  public
    FEventLog: array[0..13] of string;
    FLogCount: Integer;
    FFocused: Boolean;
    procedure Draw; override;
    procedure AddLogLine(const S: string);
  end;

  { Demo window for console focus in/out events }
  TConsoleFocusDemo = class(TWindow)
  private
    FContent: TConsoleFocusView;
  public
    constructor Create; reintroduce;
    procedure HandleEvent(var Event: TEvent); override;
  end;

  { Interior view for text attributes demo }
  TTextAttrsDemoView = class(TView)
  public
    procedure Draw; override;
  end;

  { Visual capability showcase: lists every FVProfile flag with status
    and an inline example wherever one fits. Designed for a Window large
    enough to hold ~24 rows of content. }
  TCapabilityShowcaseView = class(TView)
  public
    procedure Draw; override;
  end;

  { Live OSC 8 hyperlink demo. TStaticText doesn't populate HyperlinkURL
    on cells, so we draw with DrawHyperlink directly to exercise the
    actual OSC 8 emit path in TScreenBuffer.UpdateScreen. }
  THyperlinkDemoView = class(TView)
  public
    procedure Draw; override;
  end;

  { Cookbook demo: how to drive each colour mode FV supports - 16-colour
    via attribute byte, xterm-256 palette samples via RGB cells, 24-bit RGB
    via FG_RGB / BG_RGB, plus a note that FVProfile downsamples per host. }
  TColorModesView = class(TView)
  public
    procedure Draw; override;
  end;

  { Wraps TColorModesView with two buttons that exercise FVScreen's
    OSC 4 palette-swap helpers. Tracks whether a swap was emitted so we
    can emit OSC 104 on close - leaves the user's themed palette intact. }
  TColorModesDialog = class(TDialog)
  private
    FPaletteSwapped: Boolean;
    procedure ApplyPalette(const Palette: array of Cardinal);
    procedure ApplySolarizedDark;
    procedure ApplyDracula;
    procedure ApplyDork;
  public
    constructor Create; reintroduce;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Close; override;
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

  { System Information demo dialog }
  TSystemInfoDialog = class(TDialog)
  private
    FCPUCores: array of TCPUCoreView;
    FRAMView: TRAMView;
    FDiskView: TDiskUsageView;
    FProcessView: TProcessCountView;
    FNetworkView: TNetworkActivityView;
    FBatteryView: TBatteryStatusView;
  public
    constructor Create; reintroduce;
    procedure UpdateWidgets;
  end;

  TSixelSpectrometerWindow = class(TWindow)
  private
    FCanvas: TSixelCanvasView;
    FLevels: array of Integer;
    FPeaks: array of Integer;
    FTick: Integer;
    procedure EnsureCanvasSize;
    class function SpectrumColor(BarY, BarH: Integer): Cardinal; static;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure UpdateFrame;
  end;

  TSixelSineWindow = class(TWindow)
  private
    FCanvas: TSixelCanvasView;
    FPhase: Double;
    FTick: Integer;
    procedure EnsureCanvasSize;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure UpdateFrame;
  end;

procedure UpdateNotifications; forward;
procedure UpdateSixelDemoWindows; forward;

var
  MyApp: TMyApp;
  WindowCount: Integer;
  Phase2Dialog: TPhase2DemoDialog = nil;
  SystemInfoDialog: TSystemInfoDialog = nil;
  SpinnerGalleryDialog: TDialog = nil;
  SpinnerGalleryViews: array of TSpinnerView;
  MultiProgressDialog: TDialog = nil;
  MultiProgressView: TTaskProgress = nil;
  MultiProgressTaskIds: array[0..2] of Integer;
  MultiProgressLastTickMs: UInt64 = 0;

const
  TwoPi = 6.2831853071795864769;

procedure GetSixelCellPixelSize(out CellW, CellH: Integer);
begin
  CellW := 8;
  CellH := 16;
  if (Screen <> nil) and Screen.Initialized and
     (Screen.CellPixelWidth > 0) and (Screen.CellPixelHeight > 0) then
  begin
    CellW := Screen.CellPixelWidth;
    CellH := Screen.CellPixelHeight;
    Exit;
  end;
  TSixelEncoder.GetCellPixelSize(CellW, CellH);
  if CellW < 4 then CellW := 8;
  if CellH < 8 then CellH := 16;
end;

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

{ TGridCSVTestWindow - demonstrates grid CSV load/save }
constructor TGridCSVTestWindow.Create(var Bounds: TRect);
var
  R: TRect;
  HScrollBar, VScrollBar: TScrollBar;
  LoadBtn, SaveBtn: TButton;
begin
  inherited Create(Bounds, 'StringGrid CSV Test', wnNoNumber);
  Options := Options or ofTileable;
  Flags := Flags and not wfZoom;

  { Create vertical scrollbar }
  GetExtent(R);
  R.A.X := R.B.X - 2;
  R.B.X := R.B.X - 1;
  R.A.Y := 1;
  R.B.Y := R.B.Y - 6;
  VScrollBar := TScrollBar.Create(R);
  VScrollBar.GrowMode := gfGrowLoX + gfGrowHiX + gfGrowHiY;
  Insert(VScrollBar);

  { Create horizontal scrollbar }
  GetExtent(R);
  R.A.X := 1;
  R.B.X := R.B.X - 2;
  R.A.Y := R.B.Y - 6;
  R.B.Y := R.B.Y - 5;
  HScrollBar := TScrollBar.Create(R);
  HScrollBar.GrowMode := gfGrowLoY + gfGrowHiY + gfGrowHiX;
  Insert(HScrollBar);

  { Create the string grid }
  GetExtent(R);
  R.A.X := 1;
  R.A.Y := 1;
  R.B.X := R.B.X - 2;
  R.B.Y := R.B.Y - 6;
  FGrid := TStringGrid.Create(R, 3, HScrollBar, VScrollBar);
  FGrid.GrowMode := gfGrowHiX + gfGrowHiY;

  { Configure default columns }
  FGrid.Columns[0].Title := 'Name';
  FGrid.Columns[0].Width := 15;
  FGrid.Columns[1].Title := 'Value';
  FGrid.Columns[1].Width := 10;
  FGrid.Columns[2].Title := 'Description';
  FGrid.Columns[2].Width := 20;

  { Set grid options }
  FGrid.FixedRows := 0;
  FGrid.ShowGridLines := True;
  FGrid.SelectionMode := smCell;
  FGrid.EditMode := emF2;

  { Add sample data }
  FGrid.RowCount := 3;
  FGrid[0, 0] := 'Alpha';
  FGrid[1, 0] := '100';
  FGrid[2, 0] := 'First item';
  FGrid[0, 1] := 'Beta';
  FGrid[1, 1] := '200';
  FGrid[2, 1] := 'Second item';
  FGrid[0, 2] := 'Gamma';
  FGrid[1, 2] := '300';
  FGrid[2, 2] := 'Third item';

  Insert(FGrid);

  { Options row - Fixed Header checkbox }
  GetExtent(R);
  R.A.X := 1;
  R.A.Y := R.B.Y - 5;
  R.B.X := 24;
  R.B.Y := R.B.Y - 4;
  FFixedHeaderCheck := TCheckBoxes.Create(R, NewSItem('~F~ixed Header Row', nil));
  Insert(FFixedHeaderCheck);

  { Delimiter label }
  GetExtent(R);
  R.A.X := 25;
  R.A.Y := R.B.Y - 5;
  R.B.X := 36;
  R.B.Y := R.B.Y - 4;
  Insert(TStaticText.Create(R, 'Delimiter:'));

  { Delimiter input (single char) }
  GetExtent(R);
  R.A.X := 36;
  R.A.Y := R.B.Y - 5;
  R.B.X := 40;
  R.B.Y := R.B.Y - 4;
  FDelimiterInput := TInputLine.Create(R, 1);
  Insert(FDelimiterInput);

  { Hint for auto-detect }
  GetExtent(R);
  R.A.X := 41;
  R.A.Y := R.B.Y - 5;
  R.B.X := R.B.X - 1;
  R.B.Y := R.B.Y - 4;
  Insert(TStaticText.Create(R, '(empty=auto)'));

  { Add status label }
  GetExtent(R);
  R.A.X := 1;
  R.A.Y := R.B.Y - 3;
  R.B.X := R.B.X - 22;
  R.B.Y := R.B.Y - 2;
  FStatusLabel := TStaticText.Create(R, 'Press Load or Save button');
  Insert(FStatusLabel);

  { Add Load button }
  GetExtent(R);
  R.A.X := R.B.X - 21;
  R.A.Y := R.B.Y - 3;
  R.B.X := R.B.X - 12;
  R.B.Y := R.B.Y - 1;
  LoadBtn := TButton.Create(R, '~L~oad', cmGridLoadCSV, bfNormal);
  Insert(LoadBtn);

  { Add Save button }
  GetExtent(R);
  R.A.X := R.B.X - 11;
  R.A.Y := R.B.Y - 3;
  R.B.X := R.B.X - 2;
  R.B.Y := R.B.Y - 1;
  SaveBtn := TButton.Create(R, '~S~ave', cmGridSaveCSV, bfNormal);
  Insert(SaveBtn);

  FGrid.Select;
end;

procedure TGridCSVTestWindow.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);

  if Event.What = evCommand then begin
    case Event.Command of
      cmGridLoadCSV:
        begin
          LoadCSV;
          ClearEvent(Event);
        end;
      cmGridSaveCSV:
        begin
          SaveCSV;
          ClearEvent(Event);
        end;
    end;
  end;
end;

function TGridCSVTestWindow.GetCSVOptions: TCSVOptions;
var
  DelimStr: string;
begin
  Result := TCSVOptions.Create;

  { Check if Fixed Header Row is selected }
  if (FFixedHeaderCheck.Value and 1) <> 0 then
    Result.UseFixedHeaderRow := True;

  { Get custom delimiter if specified }
  DelimStr := FDelimiterInput.Data;
  if Length(DelimStr) > 0 then
    Result.CustomDelimiter := DelimStr[1];
end;

procedure TGridCSVTestWindow.LoadCSV;
var
  Dlg: TFileDialog;
  FileName: PathStr;
  C: Word;
  Opts: TCSVOptions;
begin
  FileName := '*.csv';
  Dlg := TFileDialog.Create('*.csv', 'Load CSV File', '~N~ame', fdOpenButton, 1);
  if Dlg <> nil then begin
    C := Desktop.ExecView(Dlg);
    if C = cmFileOpen then begin
      Dlg.GetData(FileName);
      Opts := GetCSVOptions;
      try
        try
          FGrid.LoadFromCSV(FileName, Opts);
          if Opts.UseFixedHeaderRow then
            FStatusLabel.Text := 'Loaded (fixed hdr): ' + ExtractFileName(FileName)
          else
            FStatusLabel.Text := 'Loaded: ' + ExtractFileName(FileName);
          FStatusLabel.DrawView;
        except
          on E: Exception do begin
            MessageBox('Error loading CSV: ' + E.Message, mfError + mfOKButton);
            FStatusLabel.Text := 'Load failed';
            FStatusLabel.DrawView;
          end;
        end;
      finally
        Opts.Free;
      end;
    end;
    Dlg.Free;
  end;
end;

procedure TGridCSVTestWindow.SaveCSV;
var
  Dlg: TFileDialog;
  FileName: PathStr;
  C: Word;
  Opts: TCSVOptions;
begin
  FileName := 'grid_data.csv';
  Dlg := TFileDialog.Create('*.csv', 'Save CSV File', '~N~ame', fdOKButton, 1);
  if Dlg <> nil then begin
    Dlg.SetData(FileName);
    C := Desktop.ExecView(Dlg);
    if C = cmFileOpen then begin
      Dlg.GetData(FileName);
      Opts := GetCSVOptions;
      try
        try
          FGrid.SaveToCSV(FileName, Opts);
          FStatusLabel.Text := 'Saved: ' + ExtractFileName(FileName);
          FStatusLabel.DrawView;
          MessageBox('CSV file saved successfully!', mfInformation + mfOKButton);
        except
          on E: Exception do begin
            MessageBox('Error saving CSV: ' + E.Message, mfError + mfOKButton);
            FStatusLabel.Text := 'Save failed';
            FStatusLabel.DrawView;
          end;
        end;
      finally
        Opts.Free;
      end;
    end;
    Dlg.Free;
  end;
end;

{ THexTestWindow }
constructor THexTestWindow.Create(var Bounds: TRect);
var
  R: TRect;
  LoadBtn, SaveBtn: TButton;
  HScrollBar, VScrollBar: TScrollBar;
  I: Integer;
begin
  inherited Create(Bounds, 'Hex Editor Test', wnNoNumber);
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

  { Create the hex editor }
  GetExtent(R);
  R.A.X := 1;
  R.A.Y := 1;
  R.B.X := R.B.X - 2;
  R.B.Y := R.B.Y - 4;
  FEditor := THexEditor.Create(R, HScrollBar, VScrollBar);
  FEditor.GrowMode := gfGrowHiX + gfGrowHiY;
  Insert(FEditor);

  { Create sample data (256 bytes) }
  FDataSource := TMemoryHexSource.Create(256);
  for I := 0 to 255 do
    FDataSource.SetByte(I, Byte(I));
  FDataSource.ClearModified;
  FEditor.SetDataSource(FDataSource);

  { Create status label }
  GetExtent(R);
  R.A.X := 1;
  R.A.Y := R.B.Y - 2;
  R.B.X := R.B.X - 16;
  R.B.Y := R.A.Y + 1;
  FStatusLabel := TStaticText.Create(R, 'Sample data (256 bytes)');
  FStatusLabel.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(FStatusLabel);

  { Create Load button }
  GetExtent(R);
  R.A.X := R.B.X - 15;
  R.A.Y := R.B.Y - 2;
  R.B.X := R.B.X - 8;
  R.B.Y := R.B.Y;
  LoadBtn := TButton.Create(R, '~L~oad', cmHexLoadFile, bfNormal);
  LoadBtn.GrowMode := gfGrowLoX + gfGrowLoY + gfGrowHiX + gfGrowHiY;
  Insert(LoadBtn);

  { Create Save button }
  GetExtent(R);
  R.A.X := R.B.X - 8;
  R.A.Y := R.B.Y - 2;
  R.B.X := R.B.X - 1;
  R.B.Y := R.B.Y;
  SaveBtn := TButton.Create(R, '~S~ave', cmHexSaveFile, bfNormal);
  SaveBtn.GrowMode := gfGrowLoX + gfGrowLoY + gfGrowHiX + gfGrowHiY;
  Insert(SaveBtn);
end;

destructor THexTestWindow.Destroy;
begin
  { TMemoryHexSource inherits from TInterfacedObject with reference counting.
    Don't call Free - let the editor's interface reference handle cleanup.
    When inherited Destroy frees FEditor, it releases the interface reference,
    which decrements refcount to 0 and auto-frees the data source. }
  FDataSource := nil;  { Clear our object reference (doesn't affect refcount) }
  inherited Destroy;
end;

procedure THexTestWindow.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);

  if Event.What = evCommand then begin
    case Event.Command of
      cmHexLoadFile:
        begin
          LoadFile;
          ClearEvent(Event);
        end;
      cmHexSaveFile:
        begin
          SaveFile;
          ClearEvent(Event);
        end;
    end;
  end;
end;

procedure THexTestWindow.LoadFile;
var
  Dlg: TFileDialog;
  FileName: PathStr;
  C: Word;
begin
  FileName := '*.*';
  Dlg := TFileDialog.Create('*.*', 'Load Binary File', '~N~ame', fdOpenButton, 1);
  if Dlg <> nil then begin
    C := Desktop.ExecView(Dlg);
    if C = cmFileOpen then begin
      Dlg.GetData(FileName);
      try
        FDataSource.LoadFromFile(FileName);
        FEditor.SetDataSource(FDataSource);  { Refresh the editor }
        FStatusLabel.Text := 'Loaded: ' + ExtractFileName(FileName) +
          ' (' + IntToStr(FDataSource.GetSize) + ' bytes)';
        FStatusLabel.DrawView;
        FEditor.DrawView;
      except
        on E: Exception do begin
          MessageBox('Error loading file: ' + E.Message, mfError + mfOKButton);
          FStatusLabel.Text := 'Load failed';
          FStatusLabel.DrawView;
        end;
      end;
    end;
    Dlg.Free;
  end;
end;

procedure THexTestWindow.SaveFile;
var
  Dlg: TFileDialog;
  FileName: PathStr;
  C: Word;
begin
  FileName := 'output.bin';
  Dlg := TFileDialog.Create('*.*', 'Save Binary File', '~N~ame', fdOKButton, 1);
  if Dlg <> nil then begin
    Dlg.SetData(FileName);
    C := Desktop.ExecView(Dlg);
    if C = cmFileOpen then begin
      Dlg.GetData(FileName);
      try
        FDataSource.SaveToFile(FileName);
        FDataSource.ClearModified;
        FStatusLabel.Text := 'Saved: ' + ExtractFileName(FileName);
        FStatusLabel.DrawView;
        FEditor.DrawView;  { Refresh to clear modified markers }
        MessageBox('Binary file saved successfully!', mfInformation + mfOKButton);
      except
        on E: Exception do begin
          MessageBox('Error saving file: ' + E.Message, mfError + mfOKButton);
          FStatusLabel.Text := 'Save failed';
          FStatusLabel.DrawView;
        end;
      end;
    end;
    Dlg.Free;
  end;
end;

{ TGadgetsDemoDialog }
constructor TGadgetsDemoDialog.Create;
var
  R: TRect;
  ScrollBar: TScrollBar;
  Uptime: TUptimeView;
  Btn: TButton;
begin
  R.Assign(5, 2, 75, 22);
  inherited Create(R, 'New Gadgets Demo');
  FLogCounter := 0;

  { Add uptime view at the top }
  R.Assign(2, 1, 22, 2);
  Uptime := TUptimeView.CreateCompact(R);
  Insert(Uptime);
  UptimeViewGadget := Uptime;

  R.Assign(23, 1, 43, 2);
  Insert(TStaticText.Create(R, 'System Uptime'));

  { Add toggle switches with distinct commands }
  R.Assign(2, 3, 35, 4);
  FAutoScrollToggle := TToggleSwitch.Create(R, '~A~uto-scroll log', cmToggleChanged, True);
  FAutoScrollToggle.Style := tsSlider;
  Insert(FAutoScrollToggle);

  R.Assign(2, 4, 35, 5);
  FTimestampToggle := TToggleSwitch.Create(R, '~T~imestamps', cmToggleChanged, True);
  FTimestampToggle.Style := tsCheckbox;
  Insert(FTimestampToggle);

  R.Assign(2, 5, 35, 6);
  FDebugToggle := TToggleSwitch.Create(R, 'Show ~D~ebug', cmToggleChanged, True);
  FDebugToggle.Style := tsBrackets;
  Insert(FDebugToggle);

  { Add button to add log entries }
  R.Assign(40, 3, 58, 5);
  Btn := TButton.Create(R, 'Add ~L~og', cmAddLogEntry, bfNormal);
  Insert(Btn);

  { Add scrollbar for log viewer }
  R.Assign(67, 7, 68, 17);
  ScrollBar := TScrollBar.Create(R);
  Insert(ScrollBar);

  { Add log viewer }
  R.Assign(2, 7, 67, 17);
  FLogView := TLogViewer.Create(R, 500, ScrollBar);
  Insert(FLogView);

  { Add sample log entries }
  FLogView.Debug('Application started');
  FLogView.Info('Loading configuration...');
  FLogView.Info('Configuration loaded successfully');
  FLogView.Warn('Deprecated setting detected: use_legacy_mode');
  FLogView.Info('Initializing subsystems...');
  FLogView.Debug('Subsystem A initialized');
  FLogView.Debug('Subsystem B initialized');
  FLogView.Info('All subsystems ready');
  FLogView.Error('Connection to server failed: timeout');
  FLogView.Info('Retrying connection...');
  FLogView.Info('Connection established');
  FLogView.Debug('Handshake complete');
  FLogView.Info('Ready for user input');

  { Add close button }
  R.Assign(28, 18, 42, 20);
  Btn := TButton.Create(R, '~C~lose', cmCancel, bfDefault);
  Insert(Btn);
end;

procedure TGadgetsDemoDialog.HandleEvent(var Event: TEvent);
begin
  { Handle toggle broadcasts BEFORE inherited, so they don't get consumed }
  if (Event.What = evBroadcast) and (Event.Command = cmToggleChanged) then begin
    { Update log viewer based on toggle states }
    if Event.InfoPtr = Pointer(FAutoScrollToggle) then begin
      FLogView.AutoScroll := FAutoScrollToggle.Value;
      if FAutoScrollToggle.Value then
        FLogView.ScrollToEnd;
    end
    else if Event.InfoPtr = Pointer(FTimestampToggle) then begin
      FLogView.ShowTimestamp := FTimestampToggle.Value;
      FLogView.DrawView;
    end
    else if Event.InfoPtr = Pointer(FDebugToggle) then begin
      if FDebugToggle.Value then
        FLogView.ShowAll
      else
        FLogView.HideDebug;
    end;
    ClearEvent(Event);
    Exit;
  end;

  inherited HandleEvent(Event);

  if Event.What = evCommand then begin
    case Event.Command of
      cmAddLogEntry: begin
        AddRandomLogEntry;
        ClearEvent(Event);
      end;
    end;
  end;
end;

procedure TGadgetsDemoDialog.AddRandomLogEntry;
const
  InfoMessages: array[0..4] of string = (
    'Processing user request',
    'Data synchronized successfully',
    'Cache refreshed',
    'Background task completed',
    'New connection accepted'
  );
  DebugMessages: array[0..4] of string = (
    'Memory allocation: 1024 bytes',
    'Thread pool size: 4',
    'Buffer flushed',
    'Checkpoint created',
    'GC cycle completed'
  );
  WarnMessages: array[0..2] of string = (
    'High memory usage detected',
    'Slow query detected (>100ms)',
    'Rate limit approaching'
  );
  ErrorMessages: array[0..2] of string = (
    'Database connection lost',
    'File not found: config.ini',
    'Permission denied'
  );
var
  SeverityRoll: Integer;
begin
  Inc(FLogCounter);
  SeverityRoll := FLogCounter mod 10;

  case SeverityRoll of
    0: FLogView.Error(ErrorMessages[FLogCounter mod Length(ErrorMessages)]);
    1, 2: FLogView.Warn(WarnMessages[FLogCounter mod Length(WarnMessages)]);
    3, 4, 5: FLogView.Debug(DebugMessages[FLogCounter mod Length(DebugMessages)]);
  else
    FLogView.Info(InfoMessages[FLogCounter mod Length(InfoMessages)]);
  end;
end;

{ TPhase2DemoDialog }
constructor TPhase2DemoDialog.Create;
var
  R: TRect;
  Btn: TButton;
begin
  R.Assign(2, 1, 78, 24);
  inherited Create(R, 'Phase 2 Gadgets Demo');
  FCounter := 0;
  FVUValue := 0;
  FVUDirection := 1;

  { Row 1: LED Digits (left) and Blink Indicators (right) }
  R.Assign(2, 1, 18, 4);
  FLEDDigits := TLEDDigits.Create(R, 4);
  FLEDDigits.LeadingZeros := True;
  Insert(FLEDDigits);

  R.Assign(20, 1, 21, 2);
  Insert(TStaticText.Create(R, 'Counter'));

  { Blink indicators }
  R.Assign(35, 1, 50, 2);
  FBlinker1 := TBlinkIndicator.Create(R, 'Network');
  FBlinker1.Blink;
  FBlinker1.BlinkInterval := 300;
  Insert(FBlinker1);

  R.Assign(35, 2, 50, 3);
  FBlinker2 := TBlinkIndicator.Create(R, 'Disk');
  FBlinker2.TurnOn;
  Insert(FBlinker2);

  R.Assign(35, 3, 50, 4);
  FBlinker3 := TBlinkIndicator.Create(R, 'CPU');
  FBlinker3.TurnOff;
  Insert(FBlinker3);

  { Row 2: Marquee (full width) }
  R.Assign(2, 5, 73, 6);
  FMarquee := TMarquee.Create(R, 'Welcome to Free Vision Modern!  This is a scrolling marquee demo.  Enjoy the new TUI gadgets!  ');
  FMarquee.ScrollSpeed := 100;
  Insert(FMarquee);

  R.Assign(2, 4, 10, 5);
  Insert(TStaticText.Create(R, 'Ticker:'));

  { Row 3: Sparkline }
  R.Assign(2, 7, 50, 8);
  FSparkline := TSparkline.Create(R, 48);
  { Add some initial data }
  FSparkline.SetValues([10, 25, 40, 35, 50, 45, 60, 55, 70, 65, 80, 75, 90, 85, 95, 80, 70, 60, 50, 40]);
  Insert(FSparkline);

  R.Assign(2, 6, 15, 7);
  Insert(TStaticText.Create(R, 'Sparkline:'));

  R.Assign(52, 6, 73, 8);
  Btn := TButton.Create(R, 'Add ~V~alue', cmAddSparkValue, bfNormal);
  Insert(Btn);

  { Row 4: Bar Chart }
  R.Assign(2, 9, 45, 14);
  FBarChart := TBarChart.Create(R);
  FBarChart.AddBar('Alpha', 75);
  FBarChart.AddBar('Beta', 45);
  FBarChart.AddBar('Gamma', 90);
  FBarChart.AddBar('Delta', 30);
  FBarChart.AddBar('Epsilon', 60);
  Insert(FBarChart);

  R.Assign(2, 8, 15, 9);
  Insert(TStaticText.Create(R, 'Bar Chart:'));

  R.Assign(47, 9, 73, 11);
  Btn := TButton.Create(R, 'Randomize ~B~ars', cmAddBarValue, bfNormal);
  Insert(Btn);

  { Row 5: VU Meter }
  R.Assign(2, 15, 52, 16);
  FVUMeter := TVUMeter.Create(R, False);
  FVUMeter.SetLevel(50);
  Insert(FVUMeter);

  R.Assign(2, 14, 15, 15);
  Insert(TStaticText.Create(R, 'VU Meter:'));

  R.Assign(54, 15, 73, 16);
  Insert(TStaticText.Create(R, '(auto-animating)'));

  { Close button }
  R.Assign(30, 18, 46, 20);
  Btn := TButton.Create(R, '~C~lose', cmCancel, bfDefault);
  Insert(Btn);
end;

procedure TPhase2DemoDialog.HandleEvent(var Event: TEvent);
var
  I: Integer;
begin
  { Handle our commands BEFORE inherited to prevent them being consumed }
  if Event.What = evCommand then begin
    case Event.Command of
      cmAddSparkValue: begin
        FSparkline.AddValue(Random(100));
        ClearEvent(Event);
        Exit;
      end;
      cmAddBarValue: begin
        for I := 0 to 4 do
          FBarChart.SetBar(I, Random(100));
        ClearEvent(Event);
        Exit;
      end;
    end;
  end;

  inherited HandleEvent(Event);
end;

procedure TPhase2DemoDialog.UpdateGadgets;
begin
  { Update LED counter }
  Inc(FCounter);
  FLEDDigits.SetValue(FCounter mod 10000);

  { Update blinkers }
  FBlinker1.Update;
  FBlinker2.Update;
  FBlinker3.Update;

  { Toggle disk blinker occasionally }
  if (FCounter mod 30) = 0 then begin
    if FBlinker2.State = bsOn then
      FBlinker2.TurnOff
    else
      FBlinker2.TurnOn;
  end;

  { Toggle CPU blinker more frequently }
  if (FCounter mod 10) = 0 then begin
    if FBlinker3.State = bsOn then
      FBlinker3.TurnOff
    else
      FBlinker3.TurnOn;
  end;

  { Update marquee }
  FMarquee.Update;

  { Animate VU meter - only update every 3rd call }
  if (FCounter mod 3) = 0 then begin
    FVUValue := FVUValue + (FVUDirection * (1 + Random(2)));
    if FVUValue >= 85 then begin
      FVUValue := 85;
      FVUDirection := -1;
    end
    else if FVUValue <= 5 then begin
      FVUValue := 5;
      FVUDirection := 1;
    end;
    FVUMeter.SetLevel(FVUValue);
    FVUMeter.Update;
  end;
end;

{ TSystemInfoDialog }
constructor TSystemInfoDialog.Create;
var
  R: TRect;
  Btn: TButton;
  CoreCount, I, Y, MaxCores: Integer;
begin
  CoreCount := TCPUCoreView.GetCoreCount;
  MaxCores := 8;  { Limit display to 8 cores max }
  if CoreCount > MaxCores then CoreCount := MaxCores;

  { Calculate dialog height based on core count }
  { Cores + Total + RAM + Disk + separator + Procs + separator + Net + Batt + button }
  R.Assign(5, 1, 70, 12 + CoreCount + 2);
  inherited Create(R, 'System Information');

  Y := 1;

  { CPU Total first }
  SetLength(FCPUCores, CoreCount + 1);
  R.Assign(2, Y, 62, Y + 1);
  FCPUCores[0] := TCPUCoreView.Create(R, -1);  { -1 = Total }
  FCPUCores[0].LabelWidth := 7;
  Insert(FCPUCores[0]);
  Inc(Y);

  { Per-core CPU }
  for I := 0 to CoreCount - 1 do begin
    R.Assign(2, Y, 62, Y + 1);
    FCPUCores[I + 1] := TCPUCoreView.Create(R, I);
    FCPUCores[I + 1].LabelWidth := 7;
    Insert(FCPUCores[I + 1]);
    Inc(Y);
  end;

  { RAM View }
  R.Assign(2, Y, 62, Y + 1);
  FRAMView := TRAMView.Create(R, rdBar);
  Insert(FRAMView);
  Inc(Y);

  { Disk Usage }
  R.Assign(2, Y, 62, Y + 1);
  FDiskView := TDiskUsageView.Create(R, 'C');
  Insert(FDiskView);
  Inc(Y);

  { Separator }
  Inc(Y);

  { Process Count }
  R.Assign(2, Y, 62, Y + 1);
  FProcessView := TProcessCountView.Create(R);
  Insert(FProcessView);
  Inc(Y);

  { Network Activity }
  R.Assign(2, Y, 62, Y + 1);
  FNetworkView := TNetworkActivityView.Create(R);
  Insert(FNetworkView);
  Inc(Y);

  { Battery Status }
  R.Assign(2, Y, 62, Y + 1);
  FBatteryView := TBatteryStatusView.Create(R);
  Insert(FBatteryView);
  Inc(Y, 2);

  { Close button }
  R.Assign(25, Y, 41, Y + 2);
  Btn := TButton.Create(R, '~C~lose', cmCancel, bfDefault);
  Insert(Btn);
end;

procedure TSystemInfoDialog.UpdateWidgets;
var
  I: Integer;
begin
  for I := 0 to High(FCPUCores) do
    FCPUCores[I].Update;
  FRAMView.Update;
  FDiskView.Update;
  FProcessView.Update;
  FNetworkView.Update;
  FBatteryView.Update;
end;

constructor TSixelSpectrometerWindow.Create(var Bounds: TRect);
var
  R: TRect;
  CellW, CellH: Integer;
begin
  inherited Create(Bounds, 'SIXEL Spectrometer', wnNoNumber);
  Options := Options or ofTileable;

  R.Assign(2, 1, Size.X - 2, 2);
  Insert(TStaticText.Create(R,
    'Direct SIXEL canvas: animated pixel bars with per-row color gradient'));

  R.Assign(1, 2, Size.X - 1, Size.Y - 1);
  GetSixelCellPixelSize(CellW, CellH);
  FCanvas := TSixelCanvasView.Create(R,
    (R.B.X - R.A.X) * CellW,
    (R.B.Y - R.A.Y) * CellH);
  FCanvas.GrowMode := gfGrowHiX or gfGrowHiY;
  Insert(FCanvas);

  FTick := 0;
  SetLength(FLevels, 0);
  SetLength(FPeaks, 0);
end;

procedure TSixelSpectrometerWindow.EnsureCanvasSize;
var
  CellW, CellH: Integer;
  NeedW, NeedH: Integer;
begin
  if FCanvas = nil then Exit;
  GetSixelCellPixelSize(CellW, CellH);
  NeedW := FCanvas.Size.X * CellW;
  NeedH := FCanvas.Size.Y * CellH;
  if NeedW < 1 then NeedW := 1;
  if NeedH < 1 then NeedH := 1;
  if (NeedW <> FCanvas.PixelWidth) or (NeedH <> FCanvas.PixelHeight) then
    FCanvas.ResizePixels(NeedW, NeedH);
end;

class function TSixelSpectrometerWindow.SpectrumColor(BarY, BarH: Integer): Cardinal;
var
  Pct: Integer;
  R, G, B: Integer;
begin
  if BarH <= 1 then
    Pct := 0
  else
    Pct := (BarY * 100) div (BarH - 1);

  if Pct < 65 then
  begin
    R := (Pct * 96) div 65;
    G := 72 + (Pct * 183) div 65;
    B := 8;
  end
  else if Pct < 85 then
  begin
    R := 96 + ((Pct - 65) * 159) div 20;
    G := 255;
    B := 0;
  end
  else
  begin
    R := 255;
    G := 255 - ((Pct - 85) * 220) div 15;
    if G < 30 then G := 30;
    B := 0;
  end;

  Result := (Cardinal(R) shl 16) or (Cardinal(G) shl 8) or Cardinal(B);
end;

procedure TSixelSpectrometerWindow.UpdateFrame;
var
  W, H: Integer;
  BarW, Gap, Bars: Integer;
  I, X, Y: Integer;
  LevelPx, PeakPx, DrawY: Integer;
  Envelope, Target: Integer;
begin
  if FCanvas = nil then Exit;
  Inc(FTick);
  if (FTick mod 3) <> 0 then Exit;

  EnsureCanvasSize;
  W := FCanvas.PixelWidth;
  H := FCanvas.PixelHeight;
  if (W < 8) or (H < 8) then Exit;

  BarW := 3;
  Gap := 1;
  Bars := W div (BarW + Gap);
  if Bars < 16 then
  begin
    BarW := 2;
    Gap := 1;
    Bars := W div (BarW + Gap);
  end;
  if Bars < 8 then Exit;

  if Length(FLevels) <> Bars then
  begin
    SetLength(FLevels, Bars);
    SetLength(FPeaks, Bars);
    for I := 0 to Bars - 1 do
    begin
      FLevels[I] := 0;
      FPeaks[I] := 0;
    end;
  end;

  for I := 0 to Bars - 1 do
  begin
    Envelope := 20 + (35 * I) div Bars +
      Round(45 * (0.5 + 0.5 * Sin((I * TwoPi / Bars) + (FTick * 0.08))));
    Target := Random(Envelope + 1);
    if Target > 100 then Target := 100;
    FLevels[I] := (FLevels[I] * 7 + Target * 3) div 10;
    if FLevels[I] > FPeaks[I] then
      FPeaks[I] := FLevels[I]
    else if FPeaks[I] > 0 then
      Dec(FPeaks[I], 1);
  end;

  FCanvas.Clear($000000);
  H := H - 2;
  if H < 1 then Exit;
  for I := 0 to Bars - 1 do
  begin
    X := I * (BarW + Gap);
    if X >= FCanvas.PixelWidth then Break;
    LevelPx := (FLevels[I] * H) div 100;
    PeakPx := (FPeaks[I] * H) div 100;

    for Y := 0 to LevelPx - 1 do
    begin
      DrawY := FCanvas.PixelHeight - 2 - Y;
      if DrawY < 0 then Break;
      FCanvas.FillRect(X, DrawY, BarW, 1, SpectrumColor(Y, H + 1));
    end;

    DrawY := FCanvas.PixelHeight - 2 - PeakPx;
    if DrawY < 0 then DrawY := 0;
    FCanvas.FillRect(X, DrawY, BarW, 1, $00FFFFFF);
  end;

  FCanvas.InvalidateSixel;
  FCanvas.DrawView;
end;

constructor TSixelSineWindow.Create(var Bounds: TRect);
var
  R: TRect;
  CellW, CellH: Integer;
begin
  inherited Create(Bounds, 'SIXEL Animated Sine', wnNoNumber);
  Options := Options or ofTileable;

  R.Assign(2, 1, Size.X - 2, 2);
  Insert(TStaticText.Create(R,
    'Direct SIXEL canvas: continuously redrawn sine wave with sub-cell detail'));

  R.Assign(1, 2, Size.X - 1, Size.Y - 1);
  GetSixelCellPixelSize(CellW, CellH);
  FCanvas := TSixelCanvasView.Create(R,
    (R.B.X - R.A.X) * CellW,
    (R.B.Y - R.A.Y) * CellH);
  FCanvas.GrowMode := gfGrowHiX or gfGrowHiY;
  Insert(FCanvas);

  FPhase := 0.0;
  FTick := 0;
end;

procedure TSixelSineWindow.EnsureCanvasSize;
var
  CellW, CellH: Integer;
  NeedW, NeedH: Integer;
begin
  if FCanvas = nil then Exit;
  GetSixelCellPixelSize(CellW, CellH);
  NeedW := FCanvas.Size.X * CellW;
  NeedH := FCanvas.Size.Y * CellH;
  if NeedW < 1 then NeedW := 1;
  if NeedH < 1 then NeedH := 1;
  if (NeedW <> FCanvas.PixelWidth) or (NeedH <> FCanvas.PixelHeight) then
    FCanvas.ResizePixels(NeedW, NeedH);
end;

procedure TSixelSineWindow.UpdateFrame;
var
  W, H: Integer;
  X, PrevX, PrevY, CurY: Integer;
  MidY, Amp: Integer;
  GridStepX, GridStepY: Integer;
  T: Double;
begin
  if FCanvas = nil then Exit;
  Inc(FTick);
  if (FTick and 1) <> 0 then Exit;

  EnsureCanvasSize;
  W := FCanvas.PixelWidth;
  H := FCanvas.PixelHeight;
  if (W < 8) or (H < 8) then Exit;

  FCanvas.Clear($00030A);

  GridStepX := 32;
  GridStepY := 18;
  X := 0;
  while X < W do
  begin
    FCanvas.DrawLine(X, 0, X, H - 1, $00101828);
    Inc(X, GridStepX);
  end;
  X := 0;
  while X < H do
  begin
    FCanvas.DrawLine(0, X, W - 1, X, $00101828);
    Inc(X, GridStepY);
  end;

  MidY := H div 2;
  FCanvas.DrawLine(0, MidY, W - 1, MidY, $00204060);

  Amp := MidY - 4;
  if Amp < 2 then Amp := 2;

  PrevX := 0;
  PrevY := MidY - Round(Sin(FPhase) * Amp);
  for X := 1 to W - 1 do
  begin
    if W > 1 then
      T := X / (W - 1)
    else
      T := 0.0;
    CurY := MidY - Round(Sin(FPhase + (T * TwoPi * 2.0)) * Amp);
    FCanvas.DrawLine(PrevX, PrevY, X, CurY, $0020D4FF);
    FCanvas.DrawLine(PrevX, PrevY + 1, X, CurY + 1, $00007CC8);
    PrevX := X;
    PrevY := CurY;
  end;

  FCanvas.InvalidateSixel;
  FCanvas.DrawView;
  FPhase := FPhase + 0.13;
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
      NewItem('Select ~F~older...', '', kbNoKey, cmTestFolderSelect, hcNoContext,
      NewLine(
      NewItem('E~x~it', 'Alt-X', kbAltX, cmQuit, hcNoContext, nil))))))),
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
        NewItem('C~S~V Load/Save', '', kbNoKey, cmTestStringGridCSV, hcNoContext,
        nil))))),
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
      NewItem('~H~ex Editor', '', kbNoKey, cmTestHexEditor, hcNoContext,
      NewItem('~M~odern File Dialog', '', kbNoKey, cmTestModernFileDialog, hcNoContext,
      NewItem('New ~G~adgets Demo', '', kbNoKey, cmTestNewGadgets, hcNoContext,
      NewItem('Gadgets ~P~hase 2', '', kbNoKey, cmTestGadgetsPhase2, hcNoContext,
      NewItem('~S~ystem Info', '', kbNoKey, cmTestSystemInfo, hcNoContext,
      NewItem(#$D83E#$DD9A + ' Emoji/~W~ide Chars', '', kbNoKey, cmTestEmojiWide, hcNoContext,
      NewSubMenu('New Co~m~ponents', hcNoContext, NewMenu(
        NewItem('~P~rogress Bar', '', kbNoKey, cmTestProgressBar, hcNoContext,
        NewItem('~B~readcrumb', '', kbNoKey, cmTestBreadcrumb, hcNoContext,
        NewItem('~T~ool Bar', '', kbNoKey, cmTestToolBar, hcNoContext,
        NewItem('~C~ombo Box', '', kbNoKey, cmTestComboBox, hcNoContext,
        NewItem('~S~plitter', '', kbNoKey, cmTestSplitter, hcNoContext,
        NewItem('~A~ccordion', '', kbNoKey, cmTestAccordion, hcNoContext,
        NewItem('Editor ~G~utter', '', kbNoKey, cmTestEditorGutter, hcNoContext,
        NewItem('~N~otification', '', kbNoKey, cmTestNotification, hcNoContext,
        NewItem('Clip~b~oard', '', kbNoKey, cmTestClipboard, hcNoContext,
        NewItem('~I~mage Viewer', '', kbNoKey, cmTestImageView, hcNoContext,
        NewItem('SIXEL ~S~pectrometer', '', kbNoKey, cmTestSixelSpectrometer, hcNoContext,
        NewItem('SIXEL ~A~nimated Sine', '', kbNoKey, cmTestSixelSine, hcNoContext,
        NewItem('Command~S~et Demo', '', kbNoKey, cmTestCommandSet, hcNoContext,
        NewItem('Spinner ~G~allery', '', kbNoKey, cmTestSpinnerGallery, hcNoContext,
        NewItem('Multi-Task Pro~g~ress', '', kbNoKey, cmTestMultiProgress, hcNoContext,
        NewItem('Check-~L~ist Selection', '', kbNoKey, cmTestCheckList, hcNoContext,
        NewItem('~H~yperlink Test', '', kbNoKey, cmTestHyperlink, hcNoContext,
        NewItem('Capa~b~ility Dump', '', kbNoKey, cmTestProfileDump, hcNoContext,
        NewItem('Capability ~S~howcase', '', kbNoKey, cmTestCapabilityShowcase, hcNoContext,
        NewItem('Color ~M~odes', '', kbNoKey, cmTestColorModes, hcNoContext,
        nil))))))))))))))))))))),
      NewSubMenu('~A~dvanced', hcNoContext, NewMenu(
        NewItem('~K~ey Up/Down', '', kbNoKey, cmTestKeyUpDown, hcNoContext,
        NewItem('Console ~F~ocus', '', kbNoKey, cmTestConsoleFocus, hcNoContext,
        NewItem('Text ~A~ttributes', '', kbNoKey, cmTestTextAttrs, hcNoContext,
        NewItem('~P~aste Detection', '', kbNoKey, cmTestPasteDetect, hcNoContext,
        NewItem('~T~ree View', '', kbNoKey, cmTestTreeView, hcNoContext,
        NewItem('Fu~z~zy Finder', '', kbNoKey, cmTestFuzzyFinder, hcNoContext,
        NewItem('Too~l~tips', '', kbNoKey, cmTestTooltip, hcNoContext,
        NewItem('~G~rid Filter', '', kbNoKey, cmTestGridFilter, hcNoContext,
        NewItem('~S~yntax Highlight', '', kbNoKey, cmTestSyntaxHL, hcNoContext,
        NewItem('~M~arkdown Viewer', '', kbNoKey, cmTestMarkdownView, hcNoContext,
        NewItem('A~u~tocomplete Popup', '', kbNoKey, cmTestPopupAutoComplete, hcNoContext,
        nil)))))))))))),
    nil))))))))))))))))))))))))))))),
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
      NewItem('Close ~A~ll', '', kbNoKey, cmCloseAll, hcNoContext,
      NewLine(
      NewItem('Window ~L~ist...', 'Alt-0', kbAlt0, cmWindowList, hcNoContext, nil)))))))))))))),
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
        cmTestFolderSelect: TestFolderSelect;
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
        cmTestStringGridCSV: TestStringGridCSV;
        cmTestTerminalCmd: TestTerminalCmd;
        cmTestTerminalPwsh: TestTerminalPwsh;
        cmTestTerminalCustom: TestTerminalCustom;
        cmTestHexEditor: TestHexEditor;
        cmTestModernFileDialog: TestModernFileDialog;
        cmTestNewGadgets: TestNewGadgets;
        cmTestGadgetsPhase2: TestGadgetsPhase2;
        cmTestSystemInfo: TestSystemInfo;
        cmTestEmojiWide: TestEmojiWide;
        cmTestProgressBar: TestProgressBar;
        cmTestBreadcrumb: TestBreadcrumb;
        cmTestToolBar: TestToolBar;
        cmTestComboBox: TestComboBox;
        cmTestSplitter: TestSplitter;
        cmTestAccordion: TestAccordion;
        cmTestEditorGutter: TestEditorGutter;
        cmTestNotification: TestNotification;
        cmTestClipboard: TestClipboard;
        cmTestImageView: TestImageView;
        cmTestSixelSpectrometer: TestSixelSpectrometer;
        cmTestSixelSine: TestSixelSine;
        cmTestCommandSet: TestCommandSet;
        cmTestKeyUpDown: TestKeyUpDown;
        cmTestConsoleFocus: TestConsoleFocus;
        cmTestTextAttrs: TestTextAttrs;
        cmTestPasteDetect: TestPasteDetect;
        cmTestTreeView: TestTreeView;
        cmTestFuzzyFinder: TestFuzzyFinder;
        cmTestTooltip: TestTooltip;
        cmTestGridFilter: TestGridFilter;
        cmTestSyntaxHL: TestSyntaxHL;
        cmTestMarkdownView: TestMarkdownView;
        cmTestPopupAutoComplete: TestPopupAutoComplete;
        cmTestSpinnerGallery: TestSpinnerGallery;
        cmTestMultiProgress: TestMultiProgress;
        cmTestCheckList: TestCheckList;
        cmTestHyperlink: TestHyperlink;
        cmTestProfileDump: TestProfileDump;
        cmTestCapabilityShowcase: TestCapabilityShowcase;
        cmTestColorModes: TestColorModes;
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
    if UptimeViewGadget <> nil then UptimeViewGadget.Update;
    if Phase2Dialog <> nil then Phase2Dialog.UpdateGadgets;
    if SystemInfoDialog <> nil then SystemInfoDialog.UpdateWidgets;
    UpdateSixelDemoWindows;

    { Drive spinner gallery animation. TSpinnerView.Update is self-paced
      via elapsed-time check, so calling on every Idle is safe. }
    if SpinnerGalleryDialog <> nil then
    begin
      var SpI: Integer;
      for SpI := 0 to High(SpinnerGalleryViews) do
        if SpinnerGalleryViews[SpI] <> nil then
          SpinnerGalleryViews[SpI].Update;
    end;

    { Multi-task progress demo: drive 3 simulated tasks at different rates. }
    if (MultiProgressView <> nil) and (MultiProgressDialog <> nil) then
    begin
      var Now64: UInt64;
      Now64 := GetTickCount64;
      if Now64 - MultiProgressLastTickMs >= 60 then
      begin
        MultiProgressLastTickMs := Now64;
        MultiProgressView.IncrementTask(MultiProgressTaskIds[0], 2);
        if Random(2) = 0 then
          MultiProgressView.IncrementTask(MultiProgressTaskIds[1], 1);
        if MultiProgressView.IsFinished(MultiProgressTaskIds[1]) then
          MultiProgressView.IncrementTask(MultiProgressTaskIds[2], 3);
      end;
    end;

    { Update tooltips based on focus changes }
    TTooltip.PollFocus;

    { Update notifications for auto-dismiss }
    if Desktop <> nil then begin
      try
        UpdateNotifications;
      except
        on E: Exception do LogException('Idle.UpdateNotifications', E);
      end;
    end;

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

procedure TMyApp.TestFolderSelect;
var
  SelectedPath: DirStr;
begin
  SelectedPath := GetCurDir;
  if ExecuteDialog(TFolderSelectDialog.Create(0, 3), @SelectedPath) = cmOK then
    MessageBox('Selected folder: ' + SelectedPath, mfInformation + mfOKButton)
  else
    MessageBox('Folder selection cancelled.', mfInformation + mfOKButton);
end;

procedure TMyApp.TestModernFileDialog;
var
  Dlg: TModernFileDialog;
  FileName: PathStr;
begin
  Dlg := TModernFileDialog.Create('*.*', 'Open File', 0, 0);
  if Dlg <> nil then begin
    if Desktop.ExecView(Dlg) = cmFileOpen then begin
      Dlg.GetFileName(FileName);
      MessageBox('Selected: ' + FileName, mfInformation + mfOKButton);
    end;
    Dlg.Free;
  end;
end;

procedure TMyApp.TestNewGadgets;
{ Window demonstrating TUptimeView, TToggleSwitch, and TLogViewer }
var
  Dlg: TGadgetsDemoDialog;
begin
  Dlg := TGadgetsDemoDialog.Create;
  Desktop.ExecView(Dlg);
  UptimeViewGadget := nil;
  Dlg.Free;
end;

procedure TMyApp.TestGadgetsPhase2;
{ Window demonstrating Phase 2 gadgets: LEDDigits, BlinkIndicator, Marquee, Sparkline, BarChart, VUMeter }
var
  Dlg: TPhase2DemoDialog;
begin
  Dlg := TPhase2DemoDialog.Create;
  Phase2Dialog := Dlg;
  Desktop.ExecView(Dlg);
  Phase2Dialog := nil;
  Dlg.Free;
end;

procedure TMyApp.TestSystemInfo;
{ Window demonstrating System Information widgets }
var
  Dlg: TSystemInfoDialog;
begin
  Dlg := TSystemInfoDialog.Create;
  SystemInfoDialog := Dlg;
  Desktop.ExecView(Dlg);
  SystemInfoDialog := nil;
  Dlg.Free;
end;

procedure TMyApp.TestEmojiWide;
{ Dialog testing emoji and wide character rendering across all widget types }
var
  R: TRect;
  Dlg: TDialog;
  ScrollBar: TScrollBar;
  ListBox: TStringListBox;
  List: TStringList;
begin
  R.Assign(3, 1, 75, 23);
  Dlg := TDialog.Create(R, #$D83D#$DE80 + ' Emoji & Wide Char Test ' + #$D83C#$DF0D);
  if Dlg <> nil then begin

    { --- Column 1: Static text and labels --- }

    { Section: Static text with emoji }
    R.Assign(2, 1, 34, 2);
    Dlg.Insert(TStaticText.Create(R,
      #$D83D#$DE00 + ' Grinning Face'));
    R.Assign(2, 2, 34, 3);
    Dlg.Insert(TStaticText.Create(R,
      #$2615 + ' Hot Beverage (BMP wide)'));
    R.Assign(2, 3, 34, 4);
    Dlg.Insert(TStaticText.Create(R,
      #$D83C#$DF55 + ' Pizza ' + #$D83C#$DF54 + ' Burger'));

    { Section: CJK wide characters }
    R.Assign(2, 4, 34, 5);
    Dlg.Insert(TStaticText.Create(R,
      #$4F60#$597D + ' = Hello (CJK)'));
    R.Assign(2, 5, 34, 6);
    Dlg.Insert(TStaticText.Create(R,
      #$D83C#$DDE9#$D83C#$DDEA + ' Flag: DE'));

    { Section: Centered text with emoji }
    R.Assign(2, 7, 34, 9);
    Dlg.Insert(TStaticText.Create(R,
      #3 + #$D83C#$DF1F + ' Centered Star ' + #$D83C#$DF1F));

    { Section: Buttons with emoji labels }
    R.Assign(2, 10, 16, 12);
    Dlg.Insert(TButton.Create(R,
      #$D83D#$DCC1 + ' ~S~ave', cmCancel, bfNormal));
    R.Assign(17, 10, 34, 12);
    Dlg.Insert(TButton.Create(R,
      #$274C + ' ~C~ancel', cmCancel, bfNormal));

    { Section: Radio buttons with emoji }
    R.Assign(2, 13, 34, 14);
    Dlg.Insert(TStaticText.Create(R, 'Mood:'));
    R.Assign(2, 14, 34, 17);
    Dlg.Insert(TRadioButtons.Create(R,
      NewSItem(#$D83D#$DE00 + ' ~H~appy',
      NewSItem(#$D83D#$DE22 + ' ~S~ad',
      NewSItem(#$D83D#$DE0E + ' ~C~ool', nil)))));

    { Section: Checkboxes with CJK/emoji }
    R.Assign(2, 17, 34, 20);
    Dlg.Insert(TCheckBoxes.Create(R,
      NewSItem(#$D83C#$DF55 + ' Pi~z~za',
      NewSItem(#$D83C#$DF54 + ' ~B~urger',
      NewSItem(#$4E2D#$6587 + ' Chinese', nil)))));

    { --- Column 2: ListBox, Input --- }

    { Listbox with emoji entries }
    R.Assign(63, 1, 64, 10);
    ScrollBar := TScrollBar.Create(R);
    Dlg.Insert(ScrollBar);

    R.Assign(36, 1, 63, 10);
    ListBox := TStringListBox.Create(R, 1, ScrollBar);
    Dlg.Insert(ListBox);

    List := TStringList.Create;
    List.Add(#$D83D#$DE80 + ' Rocket Launch');
    List.Add(#$D83C#$DF0D + ' Earth Globe');
    List.Add(#$2B50 + ' Star (BMP wide)');
    List.Add(#$D83C#$DF89 + ' Party Popper');
    List.Add(#$D83D#$DC4D + ' Thumbs Up');
    List.Add(#$4F60#$597D + ' CJK Hello');
    List.Add(#$D83C#$DDF9#$D83C#$DDFC + ' Flag: TW');
    List.Add(#$D83C#$DF1F + ' Glowing Star');
    List.Add('ABC Normal text');
    List.Add(#$D83D#$DE00 + ' Mixed ' + #$4E16#$754C);
    ListBox.NewList(List);

    { Input line with emoji label }
    R.Assign(36, 11, 64, 12);
    Dlg.Insert(TStaticText.Create(R, #$D83D#$DD0D + ' Search:'));
    R.Assign(36, 12, 64, 13);
    Dlg.Insert(TInputLine.Create(R, 128));

    { Label using ~ hotkey with emoji }
    Dlg.NewLabel(36, 14, #$D83D#$DCC4 + ' ~F~ilename:', nil);

    { More static text showing alignment }
    R.Assign(36, 16, 64, 17);
    Dlg.Insert(TStaticText.Create(R,
      'Width: ' + #$2588#$2588#$2588 + ' blocks'));
    R.Assign(36, 17, 64, 18);
    Dlg.Insert(TStaticText.Create(R,
      #$FF21#$FF22#$FF23 + ' Fullwidth ABC'));

    { OK button }
    R.Assign(40, 19, 56, 21);
    Dlg.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));

    Dlg.SelectNext(False);
    Desktop.ExecView(Dlg);
    Dlg.Free;
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
  InputLine1, InputLine2, InputLine3: TInputLong;
  Value1, Value2, Value3: LongInt;
begin
  R.Assign(10, 4, 60, 18);
  Dlg := TDialog.Create(R, 'InputLong Test');
  if Dlg <> nil then begin
    { Label and input for positive number }
    R.Assign(3, 2, 30, 3);
    Dlg.Insert(TStaticText.Create(R, 'Enter a number (0-1000):'));
    R.Assign(3, 3, 20, 4);
    InputLine1 := TInputLong.Create(R, 10, 0, 1000, 0);
    Dlg.Insert(InputLine1);

    { Label and input for signed number }
    R.Assign(3, 5, 35, 6);
    Dlg.Insert(TStaticText.Create(R, 'Enter signed (-100 to 100):'));
    R.Assign(3, 6, 20, 7);
    InputLine2 := TInputLong.Create(R, 10, -100, 100, 0);
    Dlg.Insert(InputLine2);

    { Label and input for hex number }
    R.Assign(3, 8, 35, 9);
    Dlg.Insert(TStaticText.Create(R, 'Enter hex ($0-$FF, use $):'));
    R.Assign(3, 9, 20, 10);
    InputLine3 := TInputLong.Create(R, 10, 0, 255, ilHex or ilDisplayHex);
    Dlg.Insert(InputLine3);

    { Buttons }
    R.Assign(10, 11, 22, 13);
    Dlg.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));
    R.Assign(26, 11, 38, 13);
    Dlg.Insert(TButton.Create(R, 'Cancel', cmCancel, bfNormal));

    Dlg.SelectNext(False);

    { Set initial values }
    Value1 := 42;
    Value2 := 0;
    Value3 := 128;  { $80 in hex }
    InputLine1.SetData(Value1);
    InputLine2.SetData(Value2);
    InputLine3.SetData(Value3);

    if Desktop.ExecView(Dlg) = cmOK then begin
      { Show message boxes for all three values entered }
      InputLine1.GetData(Value1);
      MessageBox('Positive value: ' + IntToStr(Value1), mfInformation + mfOKButton);

      InputLine2.GetData(Value2);
      MessageBox('Signed value: ' + IntToStr(Value2), mfInformation + mfOKButton);

      InputLine3.GetData(Value3);
      MessageBox('Hex value: $' + IntToHex(Value3, 2) + ' (' + IntToStr(Value3) + ')', mfInformation + mfOKButton);
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

procedure TMyApp.TestStringGridCSV;
{ Test the TStringGrid CSV import/export with options }
var
  R: TRect;
  Win: TGridCSVTestWindow;
begin
  R.Assign(3, 1, 72, 22);  { Larger window to fit options row }
  Win := TGridCSVTestWindow.Create(R);
  if Win <> nil then
    Desktop.Insert(Win);
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

procedure TMyApp.TestHexEditor;
{ Test hex editor component with load/save }
var
  R: TRect;
  Win: THexTestWindow;
begin
  R.Assign(2, 1, 82, 24);
  Win := THexTestWindow.Create(R);
  if Win <> nil then begin
    Desktop.Insert(Win);

    MessageBox('Hex Editor Controls:'#13#10 +
               #13#10 +
               'Arrow keys - Navigate'#13#10 +
               'Tab - Toggle hex/ASCII mode'#13#10 +
               '0-9, A-F - Edit hex values'#13#10 +
               'Printable chars - Edit ASCII'#13#10 +
               'PgUp/PgDn - Scroll by page'#13#10 +
               'Ctrl+Home/End - Go to start/end'#13#10 +
               #13#10 +
               'Use Load/Save buttons for files',
               mfInformation or mfOKButton);
  end;
end;

{ ====================== UpdateNotifications ====================== }
procedure UpdateNotifications;
var
  P, Next: TView;
  Notifs: TList;
  I: Integer;
begin
  if Desktop = nil then Exit;
  Notifs := TList.Create;
  try
    { Collect notification views first to avoid modifying list while iterating }
    P := Desktop.First;
    if P <> nil then begin
      repeat
        Next := P.Next;
        if (P is TNotification) and not TNotification(P).Dismissed then
          Notifs.Add(P);
        P := Next;
      until P = Desktop.First;
    end;
    { Update each notification }
    for I := 0 to Notifs.Count - 1 do
      TNotification(Notifs[I]).Update;
  finally
    Notifs.Free;
  end;
end;

procedure UpdateSixelDemoWindows;
var
  P, Next: TView;
begin
  if Desktop = nil then Exit;
  P := Desktop.First;
  if P = nil then Exit;

  repeat
    Next := P.Next;
    if P is TSixelSpectrometerWindow then
      TSixelSpectrometerWindow(P).UpdateFrame
    else if P is TSixelSineWindow then
      TSixelSineWindow(P).UpdateFrame;
    P := Next;
  until P = Desktop.First;
end;

{ ====================== Test Procedures ====================== }
procedure TMyApp.TestProgressBar;
var
  D: TDialog;
  R: TRect;
  PB1, PB2, PB3: TProgressBar;
begin
  R.Assign(10, 3, 60, 16);
  D := TDialog.Create(R, 'Progress Bar Demo');

  { Standard progress bar }
  R.Assign(3, 2, 47, 3);
  PB1 := TProgressBar.Create(R, 0, 100);
  PB1.SetProgress(75);
  D.Insert(PB1);

  R.Assign(3, 1, 47, 2);
  D.Insert(TStaticText.Create(R, '75% complete:'));

  { Half-way progress bar }
  R.Assign(3, 5, 47, 6);
  PB2 := TProgressBar.Create(R, 0, 200);
  PB2.SetProgress(100);
  D.Insert(PB2);

  R.Assign(3, 4, 47, 5);
  D.Insert(TStaticText.Create(R, '50% complete:'));

  { Empty progress bar }
  R.Assign(3, 8, 47, 9);
  PB3 := TProgressBar.Create(R, 0, 100);
  PB3.ShowPercent := True;
  D.Insert(PB3);

  R.Assign(3, 7, 47, 8);
  D.Insert(TStaticText.Create(R, '0% (empty):'));

  { OK button }
  R.Assign(18, 10, 32, 12);
  D.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));

  Desktop.ExecView(D);
  FreeAndNil(D);
end;

procedure TMyApp.TestBreadcrumb;
var
  D: TDialog;
  R: TRect;
  BC: TBreadcrumb;
begin
  R.Assign(5, 3, 65, 12);
  D := TDialog.Create(R, 'Breadcrumb Demo');

  R.Assign(2, 1, 58, 2);
  D.Insert(TStaticText.Create(R, 'File path breadcrumb:'));

  R.Assign(2, 2, 58, 3);
  BC := TBreadcrumb.Create(R);
  BC.SetPath('C:\Projects\FV-Delphi\src\Views.pas', '\');
  D.Insert(BC);

  R.Assign(2, 4, 58, 5);
  D.Insert(TStaticText.Create(R, 'Navigation breadcrumb:'));

  R.Assign(2, 5, 58, 6);
  BC := TBreadcrumb.Create(R);
  BC.SetPath(['Home', 'Settings', 'Display', 'Colors']);
  D.Insert(BC);

  R.Assign(22, 7, 36, 9);
  D.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));

  Desktop.ExecView(D);
  FreeAndNil(D);
end;

procedure TMyApp.TestToolBar;
var
  R: TRect;
  Win: TWindow;
  TB: ToolBar.TToolBar;
begin
  Inc(WindowCount);
  R.Assign(2, 1, 70, 18);

  Win := TWindow.Create(R, 'ToolBar Demo', WindowCount);
  Win.Options := Win.Options or ofTileable;

  { Create toolbar at top of window }
  R.Assign(1, 1, Win.Size.X - 1, 2);
  TB := ToolBar.TToolBar.Create(R,
    NewToolBarItem('~N~ew', cmNewWindow, hcNoContext,
    NewToolBarItem('~O~pen', cmTestFileOpen, hcNoContext,
    NewToolBarSeparator(
    NewToolBarItem('~C~ut', cmCut, hcNoContext,
    NewToolBarItem('Co~p~y', cmCopy, hcNoContext,
    NewToolBarItem('~P~aste', cmPaste, hcNoContext,
    NewToolBarSeparator(
    NewToolBarItem('~H~elp', cmHelp, hcNoContext,
    nil)))))))));
  Win.Insert(TB);

  { Static text below toolbar }
  R.Assign(2, 3, Win.Size.X - 2, 5);
  Win.Insert(TStaticText.Create(R,
    'The toolbar above shows clickable buttons with ' +
    'hotkey highlighting. Disabled commands appear dimmed.'));

  Desktop.Insert(Win);
end;

procedure TMyApp.TestComboBox;
var
  D: TDialog;
  R: TRect;
  IL: TInputLine;
  CB: TComboBox;
  Items: TStringList;
begin
  R.Assign(10, 3, 55, 14);
  D := TDialog.Create(R, 'ComboBox Demo');

  R.Assign(3, 2, 35, 3);
  D.Insert(TLabel.Create(R, '~C~olor:', nil));

  R.Assign(3, 3, 35, 4);
  IL := TInputLine.Create(R, 30);
  IL.Data := 'Red';
  D.Insert(IL);

  Items := TStringList.Create;
  Items.Add('Red');
  Items.Add('Green');
  Items.Add('Blue');
  Items.Add('Yellow');
  Items.Add('Cyan');
  Items.Add('Magenta');
  Items.Add('White');
  Items.Add('Black');

  R.Assign(35, 3, 38, 4);
  CB := TComboBox.Create(R, IL, Items, 6);
  D.Insert(CB);

  R.Assign(3, 5, 35, 6);
  D.Insert(TLabel.Create(R, '~S~ize:', nil));

  R.Assign(3, 6, 35, 7);
  IL := TInputLine.Create(R, 30);
  IL.Data := 'Medium';
  D.Insert(IL);

  Items := TStringList.Create;
  Items.Add('Tiny');
  Items.Add('Small');
  Items.Add('Medium');
  Items.Add('Large');
  Items.Add('Extra Large');

  R.Assign(35, 6, 38, 7);
  CB := TComboBox.Create(R, IL, Items, 5);
  D.Insert(CB);

  R.Assign(14, 9, 28, 11);
  D.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));

  Desktop.ExecView(D);
  FreeAndNil(D);
end;

procedure TMyApp.TestSplitter;
var
  R: TRect;
  SG: TSplitGroup;
  Win: TWindow;
  LeftPanel, RightPanel: TGroup;
begin
  Inc(WindowCount);
  R.Assign(2, 1, 72, 22);
  Win := TWindow.Create(R, 'Splitter Demo', WindowCount);
  Win.Options := Win.Options or ofTileable;

  R.Assign(1, 1, Win.Size.X - 1, Win.Size.Y - 1);
  SG := TSplitGroup.Create(R, soVertical, 25);

  { Left panel with static text }
  R.Assign(0, 0, 25, R.B.Y - R.A.Y);
  LeftPanel := TGroup.Create(R);
  R.Assign(1, 0, 24, 2);
  LeftPanel.Insert(TStaticText.Create(R, 'Left Panel - drag the splitter bar to resize'));

  { Right panel with static text }
  R.Assign(26, 0, SG.Size.X, SG.Size.Y);
  RightPanel := TGroup.Create(R);
  R.Assign(1, 0, RightPanel.Size.X - 1, 2);
  RightPanel.Insert(TStaticText.Create(R, 'Right Panel - use arrow keys when splitter is focused'));

  SG.SetPanel1(LeftPanel);
  SG.SetPanel2(RightPanel);

  Win.Insert(SG);
  Desktop.Insert(Win);
end;

procedure TMyApp.TestAccordion;
var
  D: TDialog;
  R, CR: TRect;
  Acc: TAccordion;
  Content1, Content2, Content3: TGroup;
begin
  R.Assign(8, 2, 62, 22);
  D := TDialog.Create(R, 'Accordion Demo');

  R.Assign(2, 1, D.Size.X - 2, D.Size.Y - 3);
  Acc := TAccordion.Create(R, amMultiple);

  { Section 1 - General }
  CR.Assign(0, 0, Acc.Size.X, 3);
  Content1 := TGroup.Create(CR);
  CR.Assign(1, 0, Acc.Size.X - 1, 1);
  Content1.Insert(TStaticText.Create(CR, 'Application: FV Test'));
  CR.Assign(1, 1, Acc.Size.X - 1, 2);
  Content1.Insert(TStaticText.Create(CR, 'Version: 1.0'));
  CR.Assign(1, 2, Acc.Size.X - 1, 3);
  Content1.Insert(TStaticText.Create(CR, 'Author: FV Team'));
  Acc.AddSection('~G~eneral Info', Content1, 3, True);

  { Section 2 - Display }
  CR.Assign(0, 0, Acc.Size.X, 2);
  Content2 := TGroup.Create(CR);
  CR.Assign(1, 0, Acc.Size.X - 1, 1);
  Content2.Insert(TStaticText.Create(CR, 'Screen: 80x25'));
  CR.Assign(1, 1, Acc.Size.X - 1, 2);
  Content2.Insert(TStaticText.Create(CR, 'Colors: 16'));
  Acc.AddSection('~D~isplay Settings', Content2, 2, False);

  { Section 3 - About }
  CR.Assign(0, 0, Acc.Size.X, 2);
  Content3 := TGroup.Create(CR);
  CR.Assign(1, 0, Acc.Size.X - 1, 1);
  Content3.Insert(TStaticText.Create(CR, 'Free Vision for Delphi'));
  CR.Assign(1, 1, Acc.Size.X - 1, 2);
  Content3.Insert(TStaticText.Create(CR, 'Text-mode UI framework'));
  Acc.AddSection('~A~bout', Content3, 2, False);

  D.Insert(Acc);

  R.Assign(20, D.Size.Y - 3, 34, D.Size.Y - 1);
  D.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));

  Desktop.ExecView(D);
  FreeAndNil(D);
end;

procedure TMyApp.TestEditorGutter;
var
  R: TRect;
  Win: TEditWindow;
  Gutter: TEditorGutter;
  GutterR: TRect;
  EditorR: TRect;
  BmProvider: TBookmarkProvider;
  BpProvider: TBreakpointProvider;
  DfProvider: TDiffProvider;
begin
  Inc(WindowCount);
  R.Assign(2, 1, 78, 24);
  Win := TEditWindow.Create(R, '', SmallInt(WindowCount));
  if Win <> nil then begin
    { Create gutter with all 4 provider columns }
    GutterR.Assign(1, 1, 10, Win.Size.Y - 1);
    Gutter := TEditorGutter.CreateDefault(GutterR, Win.Editor);

    { Add bookmark column }
    BmProvider := TBookmarkProvider.Create;
    BmProvider.ToggleBookmark(2);   { Mark line 3 }
    BmProvider.ToggleBookmark(7);   { Mark line 8 }
    Gutter.AddProvider(BmProvider);

    { Add breakpoint column }
    BpProvider := TBreakpointProvider.Create;
    BpProvider.ToggleBreakpoint(4);  { Mark line 5 }
    Gutter.AddProvider(BpProvider);

    { Add diff/change marker column }
    DfProvider := TDiffProvider.Create;
    DfProvider.MarkRange(1, 3, dsAdded);     { Lines 2-4: added (green) }
    DfProvider.SetLineStatus(6, dsModified);  { Line 7: modified (yellow) }
    Gutter.AddProvider(DfProvider);

    Win.Insert(Gutter);
    Win.Gutter := Gutter;

    { Adjust editor bounds to make room for gutter }
    Gutter.RecalcWidth;
    Win.Editor.GetBounds(EditorR);
    EditorR.A.X := Gutter.Size.X + 1;
    Win.Editor.ChangeBounds(EditorR);

    Desktop.Insert(Win);

    MessageBox('Editor Gutter Demo:'#13#10 +
               #13#10 +
               'Columns (left to right):'#13#10 +
               '  Line numbers - right-aligned'#13#10 +
               '  Bookmarks - click to toggle (' + Diamond + ')'#13#10 +
               '  Breakpoints - click to toggle (' + Circle + ')'#13#10 +
               '  Diff markers - green=added, yellow=modified'#13#10 +
               #13#10 +
               'Type some text to see line numbers update.',
               mfInformation or mfOKButton);
  end;
end;

procedure TMyApp.TestNotification;
begin
  TNotification.Show('Information: Operation completed successfully.',
    ntInfo, 4000, npTopRight);
  TNotification.Show('Success! File saved.', ntSuccess, 3000, npBottomRight);
  TNotification.Show('Warning: Low disk space.', ntWarning, 5000, npTopLeft);
end;

procedure TMyApp.TestClipboard;
var
  R: TRect;
  W: TEditWindow;
begin
  { Open an editor window - user can copy/paste with system clipboard }
  R.Assign(5, 3, 75, 20);
  W := TEditWindow.Create(R, '', wnNoNumber);
  if W <> nil then begin
    W.Title := 'Clipboard Test (Ctrl+Ins=Copy, Shift+Ins=Paste)';
    W.Editor.InsertUnicodeStr(
      'System clipboard integration test.' + #13#10 +
      'Select text and press Ctrl+Ins to copy to Windows clipboard.' + #13#10 +
      'Press Shift+Ins to paste from Windows clipboard.' + #13#10 +
      'Try copying text from Notepad and pasting here!' + #13#10);
    Desktop.Insert(W);
  end;
end;

procedure TMyApp.TestImageView;
var
  Dlg: TFileDialog;
  FileName: PathStr;
  W: TImageWindow;
begin
  FileName := '*.bmp;*.sixel;*.six;*.sxl';
  Dlg := TFileDialog.Create(FileName, 'Open Image/SIXEL', '~N~ame', fdOpenButton, 1);
  if Dlg = nil then Exit;
  try
    if Desktop.ExecView(Dlg) <> cmCancel then begin
      Dlg.GetData(FileName);
      FileName := Trim(FileName);
      if FileName = '' then Exit;
      W := TImageWindow.Create(FileName);
      if W <> nil then begin
        if not W.Loaded then begin
          MsgBox.MessageBox('Failed to load image/SIXEL: unsupported format or file error.',
            mfError or mfOKButton);
          W.Free;
        end else
          Desktop.Insert(W);
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TMyApp.TestSixelSpectrometer;
var
  R: TRect;
begin
  Inc(WindowCount);
  R.Assign(2, 1, 78, 23);
  Desktop.Insert(TSixelSpectrometerWindow.Create(R));
end;

procedure TMyApp.TestSixelSine;
var
  R: TRect;
begin
  Inc(WindowCount);
  R.Assign(5, 2, 75, 20);
  Desktop.Insert(TSixelSineWindow.Create(R));
end;

{ TCommandSetDemoDialog }

constructor TCommandSetDemoDialog.Create;
var
  R: TRect;
begin
  R.Assign(10, 3, 60, 18);
  inherited Create(R, 'CommandSet Demo');

  FEnabled := True;

  R.Assign(3, 2, 47, 4);
  Insert(TStaticText.Create(R,
    'Click "Toggle" to enable/disable the three'#13 +
    'action buttons via EnableCommands/DisableCommands.'));

  { Three action buttons that will be toggled }
  R.Assign(3, 5, 17, 7);
  Insert(TButton.Create(R, '~S~ave', cmDemoSave, bfNormal));

  R.Assign(18, 5, 32, 7);
  Insert(TButton.Create(R, '~P~rint', cmDemoPrint, bfNormal));

  R.Assign(33, 5, 47, 7);
  Insert(TButton.Create(R, '~E~xport', cmDemoExport, bfNormal));

  { Status label }
  R.Assign(3, 8, 47, 9);
  FStatusLabel := TStaticText.Create(R, 'Status: Commands are ENABLED');
  Insert(FStatusLabel);

  { Toggle button and Close button }
  R.Assign(10, 10, 26, 12);
  Insert(TButton.Create(R, '~T~oggle', cmDemoToggle, bfNormal));

  R.Assign(28, 10, 42, 12);
  Insert(TButton.Create(R, '~C~lose', cmCancel, bfDefault));
end;

procedure TCommandSetDemoDialog.HandleEvent(var Event: TEvent);
var
  DemoCmds: TCommandSet;
begin
  inherited HandleEvent(Event);
  if (Event.What = evCommand) and (Event.Command = cmDemoToggle) then begin
    FEnabled := not FEnabled;
    DemoCmds := [cmDemoSave, cmDemoPrint, cmDemoExport];
    if FEnabled then begin
      EnableCommands(DemoCmds);
      FStatusLabel.Text := 'Status: Commands are ENABLED';
    end else begin
      DisableCommands(DemoCmds);
      FStatusLabel.Text := 'Status: Commands are DISABLED';
    end;
    FStatusLabel.DrawView;
    ClearEvent(Event);
  end
  else if (Event.What = evCommand) then begin
    case Event.Command of
      cmDemoSave:   begin MessageBox('Save clicked!', mfInformation or mfOKButton); ClearEvent(Event); end;
      cmDemoPrint:  begin MessageBox('Print clicked!', mfInformation or mfOKButton); ClearEvent(Event); end;
      cmDemoExport: begin MessageBox('Export clicked!', mfInformation or mfOKButton); ClearEvent(Event); end;
    end;
  end;
end;

procedure TMyApp.TestCommandSet;
var
  D: TCommandSetDemoDialog;
begin
  D := TCommandSetDemoDialog.Create;
  Desktop.ExecView(D);
  { Re-enable commands in case dialog was closed while disabled }
  EnableCommands([cmDemoSave, cmDemoPrint, cmDemoExport]);
  D.Free;
end;

{ TKeyUpDownView }

function TKeyUpDownView.VKeyName(VKey: Word; UChar: Char): string;
begin
  case VKey of
    VK_BACK:    Result := 'Backspace';
    VK_TAB:     Result := 'Tab';
    VK_RETURN:  Result := 'Enter';
    VK_ESCAPE:  Result := 'Esc';
    VK_SPACE:   Result := 'Space';
    VK_PRIOR:   Result := 'PgUp';
    VK_NEXT:    Result := 'PgDn';
    VK_END:     Result := 'End';
    VK_HOME:    Result := 'Home';
    VK_LEFT:    Result := 'Left';
    VK_UP:      Result := 'Up';
    VK_RIGHT:   Result := 'Right';
    VK_DOWN:    Result := 'Down';
    VK_INSERT:  Result := 'Ins';
    VK_DELETE:  Result := 'Del';
    VK_F1..VK_F12: Result := 'F' + IntToStr(VKey - VK_F1 + 1);
  else
    if (UChar >= ' ') and (UChar <= '~') then
      Result := UpperCase(UChar)
    else if UChar <> #0 then
      Result := 'U+' + IntToHex(Ord(UChar), 4)
    else
      Result := 'VK_' + IntToHex(VKey, 2);
  end;
end;

procedure TKeyUpDownView.AddLogLine(const S: string);
var
  I: Integer;
begin
  for I := 0 to High(FEventLog) - 1 do
    FEventLog[I] := FEventLog[I + 1];
  FEventLog[High(FEventLog)] := S;
end;

procedure TKeyUpDownView.KeyPressed(const Name: string);
var
  I: Integer;
begin
  for I := 0 to FHeldCount - 1 do
    if FHeldKeys[I] = Name then Exit;
  if FHeldCount <= High(FHeldKeys) then begin
    FHeldKeys[FHeldCount] := Name;
    Inc(FHeldCount);
  end;
end;

procedure TKeyUpDownView.KeyReleased(const Name: string);
var
  I, J: Integer;
begin
  for I := 0 to FHeldCount - 1 do begin
    if FHeldKeys[I] = Name then begin
      for J := I to FHeldCount - 2 do
        FHeldKeys[J] := FHeldKeys[J + 1];
      Dec(FHeldCount);
      FHeldKeys[FHeldCount] := '';
      Exit;
    end;
  end;
end;

procedure TKeyUpDownView.Draw;
var
  B: TDrawBuffer;
  I, W: Integer;
  S, HeldStr: string;
  C: Byte;
begin
  W := Size.X;
  C := $1E; { yellow on blue }

  { Held keys line }
  DrawChar(B, 0, ' ', C, W);
  HeldStr := 'Held: ';
  if FHeldCount = 0 then
    HeldStr := HeldStr + '(none)'
  else begin
    for I := 0 to FHeldCount - 1 do begin
      if I > 0 then HeldStr := HeldStr + ', ';
      HeldStr := HeldStr + '[' + FHeldKeys[I] + ']';
    end;
  end;
  DrawStr(B, 1, HeldStr, C);
  WriteLine(0, 0, W, 1, B);

  { Separator }
  DrawChar(B, 0, #$2500, $17, W);
  WriteLine(0, 1, W, 1, B);

  { Header }
  DrawChar(B, 0, ' ', $17, W);
  DrawStr(B, 1, 'Event Log (press and release keys):', $17);
  WriteLine(0, 2, W, 1, B);

  { Event log lines }
  for I := 0 to High(FEventLog) do begin
    DrawChar(B, 0, ' ', $17, W);
    S := FEventLog[I];
    if S <> '' then begin
      if Copy(S, 1, 4) = 'DOWN' then
        DrawStr(B, 1, S, $2E)  { yellow on green }
      else
        DrawStr(B, 1, S, $1F); { white on blue }
    end;
    WriteLine(0, 3 + I, W, 1, B);
  end;

  { Footer }
  DrawChar(B, 0, #$2500, $17, W);
  WriteLine(0, Size.Y - 2, W, 1, B);
  DrawChar(B, 0, ' ', $17, W);
  DrawStr(B, 1, 'Press Esc to close. Modifier-only releases filtered.', $17);
  WriteLine(0, Size.Y - 1, W, 1, B);
end;

{ TKeyUpDownDemo }

constructor TKeyUpDownDemo.Create;
var
  R: TRect;
begin
  R.Assign(5, 2, 65, 22);
  inherited Create(R, 'Key Up/Down Events');

  GetExtent(R);
  R.Grow(-1, -1);  { Inset by frame }
  FContent := TKeyUpDownView.Create(R);
  FContent.GrowMode := gfGrowHiX or gfGrowHiY;
  FContent.FHeldCount := 0;
  Insert(FContent);
end;

procedure TKeyUpDownDemo.HandleEvent(var Event: TEvent);
var
  Name, Line, Shift: string;
  VKey: Word;
begin
  if ((Event.What = evKeyDown) or (Event.What = evKeyUp)) and
     (Event.KeyCode <> kbEsc) then begin
    VKey := Event.ScanCode;
    case VKey of
      $01: VKey := VK_ESCAPE;
      $0E: VKey := VK_BACK;
      $0F: VKey := VK_TAB;
      $1C: VKey := VK_RETURN;
      $39: VKey := VK_SPACE;
      $3B..$44: VKey := VK_F1 + (VKey - $3B);
      $47: VKey := VK_HOME;
      $48: VKey := VK_UP;
      $49: VKey := VK_PRIOR;
      $4B: VKey := VK_LEFT;
      $4D: VKey := VK_RIGHT;
      $4F: VKey := VK_END;
      $50: VKey := VK_DOWN;
      $51: VKey := VK_NEXT;
      $52: VKey := VK_INSERT;
      $53: VKey := VK_DELETE;
      $57: VKey := VK_F11;
      $58: VKey := VK_F12;
    else
      if Event.UnicodeChar >= ' ' then
        VKey := Ord(UpCase(Event.UnicodeChar));
    end;

    Name := FContent.VKeyName(VKey, Event.UnicodeChar);

    Shift := '';
    if Event.KeyShift and kbCtrlShift <> 0 then Shift := Shift + 'Ctrl+';
    if Event.KeyShift and kbAltShift <> 0 then Shift := Shift + 'Alt+';
    if Event.KeyShift and (kbLeftShift or kbRightShift) <> 0 then Shift := Shift + 'Shift+';

    if Event.What = evKeyDown then begin
      Line := 'DOWN  ' + Shift + Name;
      FContent.KeyPressed(Name);
    end else begin
      Line := '  UP  ' + Shift + Name;
      FContent.KeyReleased(Name);
    end;
    Line := Line + '  (code=$' + IntToHex(Event.KeyCode, 4) + ')';

    FContent.AddLogLine(Line);
    FContent.DrawView;
    ClearEvent(Event);
    Exit;
  end;

  inherited HandleEvent(Event);
end;

procedure TMyApp.TestKeyUpDown;
var
  D: TKeyUpDownDemo;
begin
  D := TKeyUpDownDemo.Create;
  Desktop.ExecView(D);
  D.Free;
end;

{ TConsoleFocusView }

procedure TConsoleFocusView.AddLogLine(const S: string);
var
  I: Integer;
  TimeStr: string;
begin
  for I := 0 to High(FEventLog) - 1 do
    FEventLog[I] := FEventLog[I + 1];
  DateTimeToString(TimeStr, 'hh:nn:ss', Now);
  Inc(FLogCount);
  FEventLog[High(FEventLog)] := Format('%3d  %s  %s', [FLogCount, TimeStr, S]);
end;

procedure TConsoleFocusView.Draw;
var
  B: TDrawBuffer;
  I, W: Integer;
  C, CStatus: Byte;
  S: string;
begin
  W := Size.X;
  C := $17; { white on blue }

  { Status indicator }
  DrawChar(B, 0, ' ', C, W);
  if FFocused then begin
    CStatus := $2A; { green on green }
    S := 'Console Status:  FOCUSED';
  end else begin
    CStatus := $4F; { white on red }
    S := 'Console Status:  NOT FOCUSED';
  end;
  DrawStr(B, 1, S, CStatus);
  WriteLine(0, 0, W, 1, B);

  { Separator }
  DrawChar(B, 0, #$2500, C, W);
  WriteLine(0, 1, W, 1, B);

  { Header }
  DrawChar(B, 0, ' ', C, W);
  DrawStr(B, 1, 'Event Log:', C);
  WriteLine(0, 2, W, 1, B);

  { Event log lines }
  for I := 0 to High(FEventLog) do begin
    DrawChar(B, 0, ' ', C, W);
    S := FEventLog[I];
    if S <> '' then begin
      if Pos('FOCUS IN', S) > 0 then
        DrawStr(B, 1, S, $2E)   { yellow on green }
      else if Pos('FOCUS OUT', S) > 0 then
        DrawStr(B, 1, S, $4F)   { white on red }
      else
        DrawStr(B, 1, S, C);
    end;
    WriteLine(0, 3 + I, W, 1, B);
  end;
end;

{ TConsoleFocusDemo }

constructor TConsoleFocusDemo.Create;
var
  R: TRect;
begin
  R.Assign(8, 3, 62, 21);
  inherited Create(R, 'Console Focus Events', wnNoNumber);

  GetExtent(R);
  R.Grow(-1, -1);  { Inset by frame }
  FContent := TConsoleFocusView.Create(R);
  FContent.GrowMode := gfGrowHiX or gfGrowHiY;
  FContent.FFocused := True;
  FContent.FLogCount := 0;
  FContent.AddLogLine('Switch to another window and back to see events.');
  Insert(FContent);
end;

procedure TConsoleFocusDemo.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if (Event.What = evBroadcast) then begin
    case Event.Command of
      cmConsoleFocusIn: begin
        FContent.FFocused := True;
        FContent.AddLogLine('FOCUS IN  - console window activated');
        FContent.DrawView;
      end;
      cmConsoleFocusOut: begin
        FContent.FFocused := False;
        FContent.AddLogLine('FOCUS OUT - console window deactivated');
        FContent.DrawView;
      end;
    end;
  end;
end;

procedure TMyApp.TestConsoleFocus;
var
  W: TConsoleFocusDemo;
begin
  W := TConsoleFocusDemo.Create;
  Inc(WindowCount);
  Desktop.Insert(W);
end;

{ TTextAttrsDemoView }

procedure TTextAttrsDemoView.Draw;
var
  B: TDrawBuffer;
  W: Integer;
  C: Byte;
begin
  W := Size.X;
  C := $1E; { yellow on blue }

  { Line 0: Normal }
  DrawChar(B, 0, ' ', $17, W);
  DrawStr(B, 1, 'Normal text', $17);
  WriteLine(0, 0, W, 1, B);

  { Line 1: Italic }
  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Italic text (SGR 3)', $17, eaItalic);
  WriteLine(0, 1, W, 1, B);

  { Line 2: Strikethrough }
  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Strikethrough text (SGR 9)', $17, eaStrikethrough);
  WriteLine(0, 2, W, 1, B);

  { Line 3: Italic + Strikethrough }
  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Italic + Strikethrough', $17, eaItalic or eaStrikethrough);
  WriteLine(0, 3, W, 1, B);

  { Line 4: separator }
  DrawChar(B, 0, #$2500, $17, W);
  WriteLine(0, 4, W, 1, B);

  { Lines 5-9: Underline styles }
  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Single underline (SGR 4)', $17, 1 shl eaUnderShift);
  WriteLine(0, 5, W, 1, B);

  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Double underline (SGR 21)', $17, 2 shl eaUnderShift);
  WriteLine(0, 6, W, 1, B);

  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Curly underline (SGR 4:3)', $1C, 3 shl eaUnderShift);
  WriteLine(0, 7, W, 1, B);

  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Dotted underline (SGR 4:4)', $17, 4 shl eaUnderShift);
  WriteLine(0, 8, W, 1, B);

  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Dashed underline (SGR 4:5)', $17, 5 shl eaUnderShift);
  WriteLine(0, 9, W, 1, B);

  { Line 10: separator }
  DrawChar(B, 0, #$2500, $17, W);
  WriteLine(0, 10, W, 1, B);

  { Line 11: Combined }
  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Italic + Curly + Strikethrough', $1E,
    eaItalic or eaStrikethrough or (3 shl eaUnderShift));
  WriteLine(0, 11, W, 1, B);

  { Line 12: Dim/Faint }
  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Dim/Faint text (SGR 2)', $17, eaDim);
  WriteLine(0, 12, W, 1, B);

  { Line 13: Overline }
  DrawChar(B, 0, ' ', $17, W);
  DrawStrEx(B, 1, 'Overline text (SGR 53)', $17, eaOverline);
  WriteLine(0, 13, W, 1, B);

  { Line 14: Colored underline - red curly }
  DrawChar(B, 0, ' ', $17, W);
  DrawStrRGBEx(B, 1, 'Red curly underline (SGR 58)', $C0C0C0, $000080, $FF0000,
    3 shl eaUnderShift);
  WriteLine(0, 14, W, 1, B);

  { Line 15: separator }
  DrawChar(B, 0, #$2500, $17, W);
  WriteLine(0, 15, W, 1, B);

  { Line 16: Hyperlink }
  DrawChar(B, 0, ' ', $17, W);
  DrawStr(B, 1, 'Hyperlink: ', $17);
  DrawHyperlink(B, 12, 'https://github.com', $1F, 'https://github.com');
  WriteLine(0, 16, W, 1, B);

  { Line 17: Note }
  DrawChar(B, 0, ' ', $17, W);
  DrawStr(B, 1, '(Requires Windows Terminal for full support)', $18);
  WriteLine(0, 17, W, 1, B);
end;

procedure TMyApp.TestTextAttrs;
var
  R: TRect;
  W: TWindow;
  V: TTextAttrsDemoView;
begin
  R.Assign(5, 1, 65, 23);
  W := TWindow.Create(R, 'Text Attributes Demo', wnNoNumber);
  W.GetExtent(R);
  R.Grow(-1, -1);
  V := TTextAttrsDemoView.Create(R);
  V.GrowMode := gfGrowHiX or gfGrowHiY;
  W.Insert(V);
  Inc(WindowCount);
  Desktop.Insert(W);
end;

procedure TMyApp.TestPasteDetect;
var
  R: TRect;
  W: TEditWindow;
  TestText: string;
begin
  R.Assign(5, 3, 75, 20);
  Inc(WindowCount);
  W := TEditWindow.Create(R, '', SmallInt(WindowCount));
  W.Title := 'Paste Detection Demo';
  TestText :=
    'Paste Detection Demo' + #13#10 +
    '====================' + #13#10 +
    '' + #13#10 +
    'Copy some text from another application and' + #13#10 +
    'paste it below this line. When 3+ characters' + #13#10 +
    'arrive in rapid succession, FV detects it as' + #13#10 +
    'a paste and inserts as a single operation via' + #13#10 +
    'the cmPaste command.' + #13#10 +
    '' + #13#10 +
    'Paste here:' + #13#10;
  W.Editor.InsertUnicodeStr(TestText);
  Desktop.Insert(W);
end;

procedure TMyApp.TestTreeView;
var
  R: TRect;
  W: TWindow;
  TV: TTreeView;
  HSB, VSB: TScrollBar;
  Folder, Sub: TTreeNode;
begin
  R.Assign(5, 2, 55, 22);
  W := TWindow.Create(R, 'Tree View Demo', wnNoNumber);

  { Create scrollbar }
  W.GetExtent(R);
  R.Assign(R.B.X - 1, R.A.Y + 1, R.B.X, R.B.Y - 1);
  VSB := TScrollBar.Create(R);
  W.Insert(VSB);

  { Create tree view }
  W.GetExtent(R);
  R.Grow(-1, -1);
  Dec(R.B.X); { room for scrollbar }
  TV := TTreeView.Create(R, nil, VSB);
  TV.Checkboxes := True;

  { Build sample tree }
  Folder := TV.AddNode(nil, 'Documents');
  Folder.Icon := #$D83D#$DCC1;  { folder emoji }
  Folder.Expanded := True;
    Sub := TV.AddNode(Folder, 'Report.pdf');
    Sub.Icon := #$D83D#$DCC4;  { file emoji }
    Sub.Checkable := True;
    Sub := TV.AddNode(Folder, 'Notes.txt');
    Sub.Icon := #$D83D#$DCC4;
    Sub.Checkable := True;
    Sub.Checked := True;

  Folder := TV.AddNode(nil, 'Source');
  Folder.Icon := #$D83D#$DCC1;
  Folder.Expanded := True;
    Sub := TV.AddNode(Folder, 'App.pas');
    Sub.Icon := #$D83D#$DCC4;
    Sub.Checkable := True;
    Sub := TV.AddNode(Folder, 'Views.pas');
    Sub.Icon := #$D83D#$DCC4;
    Sub.Checkable := True;
    Sub := TV.AddNode(Folder, 'Drivers.pas');
    Sub.Icon := #$D83D#$DCC4;
    Sub.Checkable := True;

  Folder := TV.AddNode(nil, 'Projects');
  Folder.Icon := #$D83D#$DCC1;
  Folder.HasChildrenHint := True;  { Lazy loading indicator }
  TV.OnGetChildren := procedure(Sender: TObject; Node: TTreeNode)
    var Child: TTreeNode;
    begin
      Child := Node.AddChild('SubProject-A');
      Child.Icon := #$D83D#$DCC1;
      Child := Node.AddChild('SubProject-B');
      Child.Icon := #$D83D#$DCC1;
      Child := Node.AddChild('readme.md');
      Child.Icon := #$D83D#$DCC4;
      Child.Checkable := True;
    end;

  Folder := TV.AddNode(nil, 'Empty Folder');
  Folder.Icon := #$D83D#$DCC1;

  TV.InvalidateFlat;
  W.Insert(TV);
  Inc(WindowCount);
  Desktop.Insert(W);
end;

procedure TMyApp.TestFuzzyFinder;
var
  Items: TStringList;
  Finder: TFuzzyFinder;
  C: Word;
  Selected: string;
begin
  Items := TStringList.Create;
  try
    { Populate with .pas file names }
    Items.Add('App.pas');
    Items.Add('Views.pas');
    Items.Add('Drivers.pas');
    Items.Add('Dialogs.pas');
    Items.Add('Editors.pas');
    Items.Add('FVCommon.pas');
    Items.Add('FVScreen.pas');
    Items.Add('FVConsts.pas');
    Items.Add('FVBoxChars.pas');
    Items.Add('FVUTF8.pas');
    Items.Add('Objects.pas');
    Items.Add('Menus.pas');
    Items.Add('Grid.pas');
    Items.Add('Calendar.pas');
    Items.Add('ComboBox.pas');
    Items.Add('Splitter.pas');
    Items.Add('Accordion.pas');
    Items.Add('ProgressBar.pas');
    Items.Add('Breadcrumb.pas');
    Items.Add('ToolBar.pas');
    Items.Add('EditorGutter.pas');
    Items.Add('Notification.pas');
    Items.Add('TreeView.pas');
    Items.Add('PopupMenu.pas');
    Items.Add('FuzzyFinder.pas');
    Items.Add('ImageView.pas');
    Items.Add('SixelEncoder.pas');
    Items.Add('HexEdit.pas');
    Items.Add('Terminal.pas');
    Items.Add('Validate.pas');
    Items.Add('ToggleSwitch.pas');

    Finder := TFuzzyFinder.Create('Quick Open (type to filter)', Items);
    C := Desktop.ExecView(Finder);
    if C = cmOk then begin
      Selected := Finder.GetSelectedItem;
      if Selected <> '' then
        MessageBox('Selected: ' + Selected, mfInformation or mfOKButton);
    end;
    Finder.Free;
  finally
    Items.Free;
  end;
end;

procedure TMyApp.TestTooltip;
var
  R: TRect;
  Dlg: TDialog;
  IL: TInputLine;
  Btn: TButton;
  CB: TCheckBoxes;
begin
  R.Assign(10, 4, 60, 16);
  Dlg := TDialog.Create(R, 'Tooltip Demo');

  { Input line with tooltip }
  R.Assign(3, 2, 30, 3);
  Dlg.Insert(TStaticText.Create(R, 'Name:'));
  R.Assign(3, 3, 45, 4);
  IL := TInputLine.Create(R, 80);
  IL.HintText := 'Enter your full name here';
  Dlg.Insert(IL);

  { Checkboxes with tooltip }
  R.Assign(3, 5, 35, 8);
  CB := TCheckBoxes.Create(R,
    NewSItem('~B~old',
    NewSItem('~I~talic',
    NewSItem('~U~nderline', nil))));
  CB.HintText := 'Select text formatting options';
  Dlg.Insert(CB);

  { Buttons with tooltips }
  R.Assign(5, 9, 19, 11);
  Btn := TButton.Create(R, '~O~K', cmOk, bfDefault);
  Btn.HintText := 'Apply and close the dialog';
  Dlg.Insert(Btn);

  R.Assign(21, 9, 37, 11);
  Btn := TButton.Create(R, '~C~ancel', cmCancel, bfNormal);
  Btn.HintText := 'Discard changes and close';
  Dlg.Insert(Btn);

  Desktop.ExecView(Dlg);
  Dlg.Free;
end;

procedure TMyApp.TestGridFilter;
var
  R: TRect;
  W: TWindow;
  G: TStringGrid;
  HSB, VSB: TScrollBar;
  I, J: Integer;
begin
  R.Assign(3, 2, 77, 22);
  W := TWindow.Create(R, 'Grid Filter Demo (Ctrl+F to filter)', wnNoNumber);

  W.GetExtent(R);
  R.Assign(R.B.X - 1, R.A.Y + 1, R.B.X, R.B.Y - 1);
  VSB := TScrollBar.Create(R);
  W.Insert(VSB);

  W.GetExtent(R);
  R.Assign(R.A.X + 1, R.B.Y - 1, R.B.X - 1, R.B.Y);
  HSB := TScrollBar.Create(R);
  W.Insert(HSB);

  W.GetExtent(R);
  R.Assign(R.A.X + 1, R.A.Y + 1, R.B.X - 1, R.B.Y - 1);
  G := TStringGrid.Create(R, 4, HSB, VSB);
  G.GrowMode := gfGrowHiX or gfGrowHiY;
  G.Columns[0].Title := 'Name';
  G.Columns[0].Width := 15;
  G.Columns[1].Title := 'City';
  G.Columns[1].Width := 12;
  G.Columns[2].Title := 'Age';
  G.Columns[2].Width := 6;
  G.Columns[3].Title := 'Status';
  G.Columns[3].Width := 10;

  { Populate with sample data }
  G.RowCount := 20;
  for I := 0 to 19 do begin
    case I mod 5 of
      0: begin G[0, I] := 'Alice'; G[1, I] := 'Berlin'; end;
      1: begin G[0, I] := 'Bob'; G[1, I] := 'Paris'; end;
      2: begin G[0, I] := 'Charlie'; G[1, I] := 'London'; end;
      3: begin G[0, I] := 'Diana'; G[1, I] := 'Rome'; end;
      4: begin G[0, I] := 'Eve'; G[1, I] := 'Madrid'; end;
    end;
    G[2, I] := IntToStr(25 + (I * 3) mod 40);
    if I mod 3 = 0 then G[3, I] := 'Active'
    else if I mod 3 = 1 then G[3, I] := 'Inactive'
    else G[3, I] := 'Pending';
  end;

  G.Columns[0].Sortable := True;
  G.Columns[1].Sortable := True;
  G.Columns[2].Sortable := True;
  G.Columns[3].Sortable := True;
  G.ShowFilterRow := True;
  W.Insert(G);
  Inc(WindowCount);
  Desktop.Insert(W);
end;

procedure TMyApp.TestSyntaxHL;
var
  R: TRect;
  W: TEditWindow;
  SampleJSON: string;
  HL: ISyntaxHighlighter;
begin
  R.Assign(3, 2, 72, 22);
  Inc(WindowCount);
  W := TEditWindow.Create(R, '', SmallInt(WindowCount));
  W.Title := 'JSON Syntax Highlighting';
  SampleJSON :=
    '{' + #13#10 +
    '  "name": "Free Vision",' + #13#10 +
    '  "version": 2.0,' + #13#10 +
    '  "modern": true,' + #13#10 +
    '  "features": [' + #13#10 +
    '    "unicode",' + #13#10 +
    '    "sixel",' + #13#10 +
    '    "syntax-highlighting",' + #13#10 +
    '    null' + #13#10 +
    '  ],' + #13#10 +
    '  "widgets": 42,' + #13#10 +
    '  "nested": {' + #13#10 +
    '    "key": "value",' + #13#10 +
    '    "enabled": false' + #13#10 +
    '  }' + #13#10 +
    '}' + #13#10;
  W.Editor.InsertUnicodeStr(SampleJSON);
  HL := TJSONHighlighter.Create;
  W.Editor.Highlighter := HL;
  W.Editor.ColorTheme := CreateDefaultDarkTheme;
  W.Editor.UseHighlighter := True;
  Desktop.Insert(W);
end;

procedure TMyApp.TestMarkdownView;
var
  W: TMarkdownWindow;
  MD: string;
begin
  MD :=
    '# Markdown Viewer Demo' + #13#10 +
    '' + #13#10 +
    '## Features' + #13#10 +
    '' + #13#10 +
    'This viewer supports **bold**, *italic*, ~~strikethrough~~, and `inline code`.' + #13#10 +
    '' + #13#10 +
    '### Links' + #13#10 +
    '' + #13#10 +
    'Click here: [GitHub](https://github.com) or [Delphi](https://www.embarcadero.com)' + #13#10 +
    '' + #13#10 +
    '### Lists' + #13#10 +
    '' + #13#10 +
    '- First item with **bold** text' + #13#10 +
    '- Second item with *italic* text' + #13#10 +
    '- Third item with `code`' + #13#10 +
    '' + #13#10 +
    '1. Ordered item one' + #13#10 +
    '2. Ordered item two' + #13#10 +
    '3. Ordered item three' + #13#10 +
    '' + #13#10 +
    '### Code Block' + #13#10 +
    '' + #13#10 +
    '```' + #13#10 +
    'procedure Hello;' + #13#10 +
    'begin' + #13#10 +
    '  WriteLn(''Hello, World!'');' + #13#10 +
    'end;' + #13#10 +
    '```' + #13#10 +
    '' + #13#10 +
    '### Blockquote' + #13#10 +
    '' + #13#10 +
    '> This is a blockquote.' + #13#10 +
    '> It can span multiple lines.' + #13#10 +
    '' + #13#10 +
    '---' + #13#10 +
    '' + #13#10 +
    '### Table' + #13#10 +
    '' + #13#10 +
    '| Feature       | Status    |' + #13#10 +
    '|---------------|-----------|' + #13#10 +
    '| Italic        | Done      |' + #13#10 +
    '| Strikethrough | Done      |' + #13#10 +
    '| Underline     | Done      |' + #13#10 +
    '| Hyperlinks    | Done      |' + #13#10 +
    '' + #13#10 +
    '#### Small Heading' + #13#10 +
    '' + #13#10 +
    'End of demo. All rendering uses the new SGR attributes.' + #13#10;

  W := TMarkdownWindow.Create('Markdown Viewer', MD);
  Inc(WindowCount);
  Desktop.Insert(W);
end;

procedure TMyApp.TestPopupAutoComplete;
var
  R: TRect;
  Dlg: TDialog;
  IL: TInputLine;
  ResultLabel: TStaticText;
  Items: TStringList;
  PM: TPopupMenu;
  C: Word;
  Selected: string;
  AnchorX, AnchorY: Integer;
begin
  Items := TStringList.Create;
  try
    Items.Add('TView');
    Items.Add('TWindow');
    Items.Add('TDialog');
    Items.Add('TButton');
    Items.Add('TInputLine');
    Items.Add('TListBox');
    Items.Add('TScrollBar');
    Items.Add('TCheckBoxes');
    Items.Add('TRadioButtons');
    Items.Add('TStaticText');
    Items.Add('TStringGrid');
    Items.Add('TTreeView');
    Items.Add('TEditor');
    Items.Add('TProgressBar');
    Items.Add('TComboBox');
    Items.Add('TSplitter');
    Items.Add('TAccordion');
    Items.Add('TFuzzyFinder');
    Items.Add('TTooltip');
    Items.Add('TPopupMenu');

    R.Assign(8, 3, 58, 13);
    Dlg := TDialog.Create(R, 'Autocomplete Demo');

    R.Assign(3, 2, 46, 3);
    Dlg.Insert(TStaticText.Create(R, 'Type part of a class name, then press Down:'));
    R.Assign(3, 3, 40, 4);
    IL := TInputLine.Create(R, 80);
    Dlg.Insert(IL);

    R.Assign(3, 5, 46, 6);
    ResultLabel := TStaticText.Create(R, 'Selected: (none yet)');
    Dlg.Insert(ResultLabel);

    R.Assign(3, 7, 22, 9);
    Dlg.Insert(TButton.Create(R, '~S~how Popup', cmOk, bfNormal));
    R.Assign(24, 7, 40, 9);
    Dlg.Insert(TButton.Create(R, '~C~lose', cmCancel, bfDefault));

    { Run dialog in a loop - OK opens popup, Cancel closes }
    repeat
      C := Desktop.ExecView(Dlg);
      if C = cmOk then begin
        { Calculate popup position below the input line }
        AnchorX := Dlg.Origin.X + IL.Origin.X;
        AnchorY := Dlg.Origin.Y + IL.Origin.Y + 1;
        PM := TPopupMenu.Create(Items, AnchorX, AnchorY, 8);
        PM.Title := 'Suggestions';
        PM.Filter(IL.Data);
        if Desktop.ExecView(PM) = cmOk then begin
          Selected := PM.GetSelection;
          IL.Data := Selected;
          IL.SelectAll(True);
          ResultLabel.Text := 'Selected: ' + Selected;
        end;
        PM.Free;
      end;
    until C = cmCancel;

    Dlg.Free;
  finally
    Items.Free;
  end;
end;

{ TCapabilityShowcaseView }

procedure TCapabilityShowcaseView.Draw;
const
  Bg = $17;     { white on blue }
  Hdr = $1F;    { bright white on blue }
  Lbl = $1E;    { yellow on blue }
  ValYes = $1A; { bright green on blue }
  ValNo = $1C;  { bright red on blue }

  function YN(B: Boolean): string;
  begin
    if B then Result := 'Yes' else Result := 'No';
  end;

  function YNAttr(B: Boolean): Byte;
  begin
    if B then Result := ValYes else Result := ValNo;
  end;

  function CSName(C: TFVColorSystem): string;
  begin
    case C of
      fvcsNoColors:  Result := 'NoColors (suppressed)';
      fvcsLegacy:    Result := 'Legacy (16 colors)';
      fvcsEightBit:  Result := '8-bit (256 colors)';
      fvcsTrueColor: Result := 'TrueColor (24-bit RGB)';
    else
      Result := '?';
    end;
  end;

var
  B: TDrawBuffer;
  W, Y, I, X: Integer;
  P: TFVProfile;
  S: string;
  R, G, BCol: Byte;
  Hue: Integer;
begin
  W := Size.X;
  P := GetFVProfile;

  { Header }
  Y := 0;
  DrawChar(B, 0, ' ', Hdr, W);
  DrawStr(B, 1, 'FV terminal capability showcase', Hdr);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Each row: detected status + (when sensible) live example.', Bg);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);
  DrawChar(B, 0, #$2500, Bg, W);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { ANSI Support }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'ANSI VT support  : ', Lbl);
  DrawStr(B, 20, YN(P.AnsiSupported), YNAttr(P.AnsiSupported));
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Interactive }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Interactive (TTY): ', Lbl);
  DrawStr(B, 20, YN(P.Interactive), YNAttr(P.Interactive));
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Legacy console }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Legacy console   : ', Lbl);
  DrawStr(B, 20, YN(P.LegacyConsole), YNAttr(not P.LegacyConsole));
  DrawStr(B, 26, '(no VT - colour/sequences off)', Bg);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Is CI }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Running under CI : ', Lbl);
  DrawStr(B, 20, YN(P.IsCI), YNAttr(not P.IsCI));
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Unicode }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Unicode output   : ', Lbl);
  DrawStr(B, 20, YN(P.Unicode), YNAttr(P.Unicode));
  S := 'Box ' + #$2554 + #$2550 + #$2557 + '  CJK ' + #$65E5 + #$672C + #$8A9E +
       '  Emoji ' + #$D83C + #$DF89;
  DrawStr(B, 26, S, Bg);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Hyperlinks (OSC 8) }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'OSC 8 hyperlinks : ', Lbl);
  DrawStr(B, 20, YN(P.HyperlinkSupport), YNAttr(P.HyperlinkSupport));
  DrawHyperlink(B, 26, 'example.com', $1B, 'https://example.com');
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Sixel }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Sixel graphics   : ', Lbl);
  DrawStr(B, 20, YN(P.SixelSupport), YNAttr(P.SixelSupport));
  DrawStr(B, 26, '(see Test -> SIXEL Spectrometer for live demo)', Bg);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Colour system + samples }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Colour system    : ', Lbl);
  DrawStr(B, 20, CSName(P.ColorSystem), Hdr);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { 16-colour swatches: paint 16 cells with each Attr value (FG=index on dark BG) }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, '16-colour    :', Bg);
  for I := 0 to 15 do
  begin
    X := 18 + I * 2;
    if X + 1 < W then
    begin
      B[X].Ch := #$2588;        { full block }
      B[X].Attr := Byte(I) or $00;
      B[X].FG_RGB := 0;
      B[X].BG_RGB := 0;
      B[X].ExtAttrs := 0;
      B[X + 1] := B[X];
    end;
  end;
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { 256-colour cube row: pick 32 indices spanning the 16-231 cube }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, '256-colour   :', Bg);
  for I := 0 to 31 do
  begin
    X := 18 + I;
    if X >= W then Break;
    B[X].Ch := #$2588;
    B[X].Attr := Byte(16 + (I * (231 - 16)) div 31);
    B[X].FG_RGB := 0;
    B[X].BG_RGB := 0;
    B[X].ExtAttrs := 0;
  end;
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { 24-bit RGB gradient: HSV-style hue sweep }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, '24-bit RGB   :', Bg);
  for I := 0 to 39 do
  begin
    X := 18 + I;
    if X >= W then Break;
    Hue := (I * 360) div 40;
    case (Hue div 60) mod 6 of
      0: begin R := 255; G := Byte((Hue mod 60) * 255 div 60); BCol := 0; end;
      1: begin R := Byte(255 - (Hue mod 60) * 255 div 60); G := 255; BCol := 0; end;
      2: begin R := 0; G := 255; BCol := Byte((Hue mod 60) * 255 div 60); end;
      3: begin R := 0; G := Byte(255 - (Hue mod 60) * 255 div 60); BCol := 255; end;
      4: begin R := Byte((Hue mod 60) * 255 div 60); G := 0; BCol := 255; end;
    else
      begin R := 255; G := 0; BCol := Byte(255 - (Hue mod 60) * 255 div 60); end;
    end;
    B[X].Ch := #$2588;
    B[X].Attr := $07;
    B[X].FG_RGB := (Cardinal(R) shl 16) or (Cardinal(G) shl 8) or Cardinal(BCol);
    B[X].BG_RGB := 0;
    B[X].ExtAttrs := 0;
  end;
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Console size (from screen buffer dimensions) }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Console size     : ', Lbl);
  DrawStr(B, 20, IntToStr(ScreenWidth) + ' x ' + IntToStr(ScreenHeight) + ' cells', Hdr);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Separator + text attribute samples }
  DrawChar(B, 0, #$2500, Bg, W);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Text attributes :', Lbl);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'Bold         : ', Bg);
  DrawStr(B, 18, 'sample (bright FG = bold)', $1F);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'Dim          : ', Bg);
  DrawStrEx(B, 18, 'sample (faint)', Bg, eaDim);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'Italic       : ', Bg);
  DrawStrEx(B, 18, 'sample (slant)', Bg, eaItalic);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'Underline    : ', Bg);
  DrawStrEx(B, 18, 'sample (single)', Bg, 1 shl eaUnderShift);
  DrawStrEx(B, 36, 'curly', Bg, 3 shl eaUnderShift);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'Strikethrough: ', Bg);
  DrawStrEx(B, 18, 'sample (strike)', Bg, eaStrikethrough);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'Inverse      : ', Bg);
  { Inverse via swapped FG/BG palette: BG=white, FG=blue }
  DrawStr(B, 18, 'sample (swap)', $71);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'Overline     : ', Bg);
  DrawStrEx(B, 18, 'sample (line above)', Bg, eaOverline);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Fill remaining rows with background so we don't show garbage. }
  while Y < Size.Y do
  begin
    DrawChar(B, 0, ' ', Bg, W);
    WriteLine(0, Y, W, 1, B);
    Inc(Y);
  end;
end;

procedure TMyApp.TestCapabilityShowcase;
var
  R: TRect;
  W: TWindow;
  V: TCapabilityShowcaseView;
begin
  R.Assign(2, 1, 78, 27);
  W := TWindow.Create(R, 'Capability Showcase', wnNoNumber);
  W.GetExtent(R);
  R.Grow(-1, -1);
  V := TCapabilityShowcaseView.Create(R);
  V.GrowMode := gfGrowHiX or gfGrowHiY;
  W.Insert(V);
  Inc(WindowCount);
  Desktop.Insert(W);
end;

{ TColorModesView }

procedure TColorModesView.Draw;
const
  Bg = $17;     { white on blue - dialog body }
  Hdr = $1F;    { bright white on blue }
  Lbl = $1E;    { yellow on blue - section labels }
  Code = $1B;   { bright cyan on blue - code lines }
  Note = $18;   { dim grey on blue - notes }

  function CSName(C: TFVColorSystem): string;
  begin
    case C of
      fvcsNoColors:  Result := 'NoColors';
      fvcsLegacy:    Result := 'Legacy (16)';
      fvcsEightBit:  Result := '8-bit (256)';
      fvcsTrueColor: Result := 'TrueColor (24-bit)';
    else
      Result := '?';
    end;
  end;

var
  B: TDrawBuffer;
  W, Y, I, X: Integer;
  R, G, BCol: Byte;
  Hue: Integer;

  function XTerm256RGB(Index: Byte): Cardinal;
  const
    Axis: array[0..5] of Byte = (0, 95, 135, 175, 215, 255);
  var
    N, RLevel, GLevel, BLevel, Gray: Integer;
  begin
    if Index < 16 then
      Exit(0);
    if Index <= 231 then
    begin
      N := Index - 16;
      RLevel := N div 36;
      GLevel := (N div 6) mod 6;
      BLevel := N mod 6;
      Result := (Cardinal(Axis[RLevel]) shl 16) or
                (Cardinal(Axis[GLevel]) shl 8) or
                 Cardinal(Axis[BLevel]);
    end
    else
    begin
      Gray := 8 + (Index - 232) * 10;
      Result := (Cardinal(Gray) shl 16) or
                (Cardinal(Gray) shl 8) or
                 Cardinal(Gray);
    end;
  end;

  procedure BlankRow;
  begin
    DrawChar(B, 0, ' ', Bg, W);
    WriteLine(0, Y, W, 1, B);
    Inc(Y);
  end;
begin
  W := Size.X;
  Y := 0;

  { Header }
  DrawChar(B, 0, ' ', Hdr, W);
  DrawStr(B, 1, 'Colour Modes - cookbook for FV drawing code', Hdr);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Active profile: ' + CSName(GetFVProfile.ColorSystem) +
    '  (RGB cells get downsampled per profile)', Bg);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, #$2500, Bg, W);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { ===== Section 1: 16-colour attribute byte ===== }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, '1. Legacy 16 colours - attribute byte (hi nibble = BG, lo = FG):', Lbl);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'DrawChar(B, X, '' '', $1F, n);  // White on Blue', Code);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { 16 swatches - white text on each of the 16 BG colours }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, '16 BG swatches:', Bg);
  for I := 0 to 15 do
  begin
    X := 21 + I * 3;
    if X + 2 < W then
    begin
      { Build attr byte: BG nibble in high, FG=white(15) in low. The
        renderer maps both halves through ColorMap. }
      DrawChar(B, X, ' ',     Byte((I shl 4) or $0F), 1);
      DrawChar(B, X + 1, ' ', Byte((I shl 4) or $0F), 1);
      DrawChar(B, X + 2, ' ', Bg, 1);
    end;
  end;
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { 16 FG samples - each shows a glyph in that FG colour on default BG }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, '16 FG glyphs:  ', Bg);
  for I := 0 to 15 do
  begin
    X := 21 + I * 3;
    if X < W then
      DrawChar(B, X, #$2588, Byte((Hi(Bg) shl 4) or I), 1);
  end;
  WriteLine(0, Y, W, 1, B);
  Inc(Y);
  BlankRow;

  { ===== Section 2: 256-colour ===== }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, '2. 256-colour palette - xterm indices 16..255 as RGB samples:', Lbl);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'DrawRGBCell(B, X, #$2588, XTerm256RGB(N), 0);  // 8-bit emits 38;5', Code);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { 6x6x6 cube row - sample 36 indices spanning 16..231 }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, '6x6x6 cube  : ', Bg);
  for I := 0 to 35 do
  begin
    X := 18 + I;
    if X >= W then Break;
    DrawRGBCell(B, X, #$2588, XTerm256RGB(Byte(16 + (I * (231 - 16)) div 35)), 0);
  end;
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Greyscale 232..255 (24 cells) }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'Greyscale   : ', Bg);
  for I := 0 to 23 do
  begin
    X := 18 + I;
    if X >= W then Break;
    DrawRGBCell(B, X, #$2588, XTerm256RGB(Byte(232 + I)), 0);
  end;
  WriteLine(0, Y, W, 1, B);
  Inc(Y);
  BlankRow;

  { ===== Section 3: 24-bit RGB ===== }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, '3. 24-bit RGB - set FG_RGB / BG_RGB to $00RRGGBB:', Lbl);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'DrawRGBCell(B, X, ''#'', $FF8800, $202020);  // orange on dark grey', Code);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { HSV gradient row (40 cells) }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'HSV gradient: ', Bg);
  for I := 0 to 39 do
  begin
    X := 18 + I;
    if X >= W then Break;
    Hue := (I * 360) div 40;
    case (Hue div 60) mod 6 of
      0: begin R := 255; G := Byte((Hue mod 60) * 255 div 60); BCol := 0; end;
      1: begin R := Byte(255 - (Hue mod 60) * 255 div 60); G := 255; BCol := 0; end;
      2: begin R := 0; G := 255; BCol := Byte((Hue mod 60) * 255 div 60); end;
      3: begin R := 0; G := Byte(255 - (Hue mod 60) * 255 div 60); BCol := 255; end;
      4: begin R := Byte((Hue mod 60) * 255 div 60); G := 0; BCol := 255; end;
    else
      begin R := 255; G := 0; BCol := Byte(255 - (Hue mod 60) * 255 div 60); end;
    end;
    DrawRGBCell(B, X, #$2588,
      (Cardinal(R) shl 16) or (Cardinal(G) shl 8) or Cardinal(BCol), 0);
  end;
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Named hex colours - text rendered with brand-style backgrounds }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'Brand demo  : ', Bg);
  DrawStrRGBEx(B, 18, ' Anthropic ', $FFFFFF, $D97757, 0, 0);
  DrawStrRGBEx(B, 30, ' Embarcadero ', $FFFFFF, $E62D2D, 0, 0);
  DrawStrRGBEx(B, 44, ' Spectre ', $FFFFFF, $005FB8, 0, 0);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);
  BlankRow;

  { ===== Section 4: Profile downsampling + runtime palette ===== }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, '4. UpdateScreen downsamples per profile; buttons swap palette via OSC 4:', Lbl);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'TrueColor 38;2;R;G;B  ', Note);
  DrawStr(B, 26, '|  EightBit 38;5;N   ', Note);
  DrawStr(B, 47, '|  Legacy 30-37/90-97 ', Note);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'Screen.EmitPaletteEntry(N,$RRGGBB) / Screen.ResetPalette  (OSC 4 / 104)', Code);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 3, 'NO_COLOR=1, CLICOLOR_FORCE=1, COLORTERM=truecolor, TERM=*-256color', Note);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { Fill remaining rows. }
  while Y < Size.Y do
  begin
    DrawChar(B, 0, ' ', Bg, W);
    WriteLine(0, Y, W, 1, B);
    Inc(Y);
  end;
end;

{ TColorModesDialog }

constructor TColorModesDialog.Create;
var
  R: TRect;
  V: TColorModesView;
begin
  R.Assign(2, 1, 78, 27);
  inherited Create(R, 'Color Modes Cookbook');
  Options := Options or ofTileable;
  GrowMode := gfGrowHiX or gfGrowHiY;
  FPaletteSwapped := False;

  GetExtent(R);
  R.Grow(-1, -1);
  R.B.Y := R.B.Y - 4;  { Reserve 4 rows at the bottom: 1 gap + 2 button + 1 margin }
  V := TColorModesView.Create(R);
  V.GrowMode := gfGrowHiX or gfGrowHiY;
  Insert(V);

  { Five buttons across the bottom. Y=22..24 → button height 2 rows
    (sits on rows 22 and 23 inside the dialog frame). }
  R.Assign(2, 22, 16, 24);
  Insert(TButton.Create(R, '~S~olarized', cmDemoPaletteSwap, bfNormal));

  R.Assign(17, 22, 30, 24);
  Insert(TButton.Create(R, '~D~racula', cmDemoPaletteDracula, bfNormal));

  R.Assign(31, 22, 46, 24);
  Insert(TButton.Create(R, 'Dor~k~ Mode', cmDemoPaletteDork, bfNormal));

  R.Assign(47, 22, 58, 24);
  Insert(TButton.Create(R, '~R~eset', cmDemoPaletteReset, bfNormal));

  R.Assign(62, 22, 73, 24);
  Insert(TButton.Create(R, '~C~lose', cmCancel, bfDefault));
end;

procedure TColorModesDialog.ApplyPalette(const Palette: array of Cardinal);
var
  I: Integer;
begin
  for I := 0 to 15 do
    Screen.EmitPaletteEntry(I, Palette[I]);
  FPaletteSwapped := True;
end;

procedure TColorModesDialog.ApplySolarizedDark;
const
  { Solarized Dark base16 palette - https://ethanschoonover.com/solarized/.
    Mapped onto the standard ANSI 16-slot order so SGR 30-37 / 90-97 hit
    the recoloured slots. }
  Solarized: array[0..15] of Cardinal = (
    $002B36, $DC322F, $859900, $B58900, $268BD2, $D33682, $2AA198, $EEE8D5,
    $073642, $CB4B16, $586E75, $657B83, $839496, $6C71C4, $93A1A1, $FDF6E3
  );
begin
  ApplyPalette(Solarized);
end;

procedure TColorModesDialog.ApplyDracula;
const
  { Dracula - https://draculatheme.com/. Higher contrast dark theme,
    visibly different from Solarized so the swap demo reads at a glance. }
  Dracula: array[0..15] of Cardinal = (
    $21222C, $FF5555, $50FA7B, $F1FA8C, $BD93F9, $FF79C6, $8BE9FD, $F8F8F2,
    $6272A4, $FF6E6E, $69FF94, $FFFFA5, $D6ACFF, $FF92DF, $A4FFFF, $FFFFFF
  );
begin
  ApplyPalette(Dracula);
end;

procedure TColorModesDialog.ApplyDork;
const
  { Dork mode: every slot recoloured to something that absolutely does
    not match its name. Black is hot pink, Red is cyan, Green is orange.
    The point is to demonstrate just how much the SGR codes lie - they
    are slot names, the terminal decides the colour. Hit Reset when your
    eyes start bleeding. }
  Dork: array[0..15] of Cardinal = (
    $FF1493,  { 0  "black"      - hot pink     }
    $00E5FF,  { 1  "red"        - cyan         }
    $FF8C00,  { 2  "green"      - dark orange  }
    $4169E1,  { 3  "yellow"     - royal blue   }
    $7CFC00,  { 4  "blue"       - lawn green   }
    $FFD700,  { 5  "magenta"    - gold         }
    $C71585,  { 6  "cyan"       - violet       }
    $32CD32,  { 7  "white"      - lime green   }
    $FF69B4,  { 8  "br black"   - pink         }
    $00FA9A,  { 9  "br red"     - mint         }
    $FF4500,  { 10 "br green"   - red-orange   }
    $1E90FF,  { 11 "br yellow"  - dodger blue  }
    $ADFF2F,  { 12 "br blue"    - greenyellow  }
    $FF00FF,  { 13 "br magenta" - magenta      }
    $9400D3,  { 14 "br cyan"    - dark violet  }
    $FF6347   { 15 "br white"   - tomato       }
  );
begin
  ApplyPalette(Dork);
end;

procedure TColorModesDialog.HandleEvent(var Event: TEvent);
begin
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmDemoPaletteSwap:
        begin
          ApplySolarizedDark;
          if Owner <> nil then Owner.DrawView;
          ClearEvent(Event);
          Exit;
        end;
      cmDemoPaletteDracula:
        begin
          ApplyDracula;
          if Owner <> nil then Owner.DrawView;
          ClearEvent(Event);
          Exit;
        end;
      cmDemoPaletteDork:
        begin
          ApplyDork;
          if Owner <> nil then Owner.DrawView;
          ClearEvent(Event);
          Exit;
        end;
      cmDemoPaletteReset:
        begin
          Screen.ResetPalette;
          FPaletteSwapped := False;
          if Owner <> nil then Owner.DrawView;
          ClearEvent(Event);
          Exit;
        end;
    end;
  end;
  inherited HandleEvent(Event);
end;

procedure TColorModesDialog.Close;
begin
  { Don't leave the user's terminal recoloured after the demo closes. }
  if FPaletteSwapped then
  begin
    Screen.ResetPalette;
    FPaletteSwapped := False;
  end;
  inherited Close;
end;

procedure TMyApp.TestColorModes;
var
  Dlg: TColorModesDialog;
begin
  Dlg := TColorModesDialog.Create;
  Desktop.ExecView(Dlg);
  Dlg.Free;
end;

procedure TMyApp.TestSpinnerGallery;
const
  Kinds: array[0..7] of TSpinnerKind = (
    skDots, skDots2, skLine, skArc, skBouncingBar, skBoxBounce, skPipe, skTriangle);
  Captions: array[0..7] of string = (
    'Dots', 'Dots2', 'Line', 'Arc', 'BouncingBar', 'BoxBounce', 'Pipe', 'Triangle');
var
  Dlg: TDialog;
  R: TRect;
  I: Integer;
  SV: TSpinnerView;
begin
  R.Assign(8, 3, 60, 17);
  Dlg := TDialog.Create(R, 'Spinner Gallery');

  R.Assign(3, 1, 50, 2);
  Dlg.Insert(TStaticText.Create(R, 'Curated subset of cli-spinners frame sets:'));

  SetLength(SpinnerGalleryViews, Length(Kinds));
  for I := 0 to High(Kinds) do
  begin
    R.Assign(3, 3 + I, 50, 4 + I);
    SV := TSpinnerView.Create(R, Kinds[I], Captions[I]);
    Dlg.Insert(SV);
    SpinnerGalleryViews[I] := SV;
  end;

  R.Assign(20, 12, 32, 14);
  Dlg.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));

  SpinnerGalleryDialog := Dlg;
  try
    Desktop.ExecView(Dlg);
  finally
    SpinnerGalleryDialog := nil;
    SetLength(SpinnerGalleryViews, 0);
  end;
  Dlg.Free;
end;

procedure TMyApp.TestMultiProgress;
var
  Dlg: TDialog;
  R: TRect;
  TP: TTaskProgress;
begin
  R.Assign(6, 4, 74, 14);
  Dlg := TDialog.Create(R, 'Multi-Task Progress');

  R.Assign(2, 1, 66, 2);
  Dlg.Insert(TStaticText.Create(R, 'Three concurrent tasks driven from the Idle loop:'));

  R.Assign(2, 2, 66, 6);
  TP := TTaskProgress.Create(R);
  Dlg.Insert(TP);

  MultiProgressTaskIds[0] := TP.AddTask('Downloading', 100);
  MultiProgressTaskIds[1] := TP.AddTask('Verifying',   100);
  MultiProgressTaskIds[2] := TP.AddTask('Installing',  100);

  R.Assign(28, 7, 40, 9);
  Dlg.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));

  MultiProgressView       := TP;
  MultiProgressDialog     := Dlg;
  MultiProgressLastTickMs := GetTickCount64;
  try
    Desktop.ExecView(Dlg);
  finally
    MultiProgressView   := nil;
    MultiProgressDialog := nil;
  end;
  Dlg.Free;
end;

procedure TMyApp.TestCheckList;
var
  Dlg: TDialog;
  R: TRect;
  CL: TCheckListBox;
  Lst: TStringList;
  I: Integer;
  Picked: TStringList;
  Msg: string;
begin
  R.Assign(15, 3, 65, 18);
  Dlg := TDialog.Create(R, 'Check-List Selection');

  R.Assign(2, 1, 48, 2);
  Dlg.Insert(TStaticText.Create(R, 'Space toggles, Enter accepts:'));

  R.Assign(2, 2, 48, 11);
  CL := TCheckListBox.Create(R, 1, nil);
  Dlg.Insert(CL);

  Lst := TStringList.Create;
  for I := 1 to 15 do
    Lst.Add('Sample item #' + IntToStr(I));
  CL.NewList(Lst);

  R.Assign(8, 12, 20, 14);
  Dlg.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));
  R.Assign(28, 12, 40, 14);
  Dlg.Insert(TButton.Create(R, '~C~ancel', cmCancel, bfNormal));

  if Desktop.ExecView(Dlg) = cmOK then
  begin
    Picked := CL.CheckedItems;
    try
      if Picked.Count = 0 then
        Msg := 'Nothing selected.'
      else
        Msg := 'Selected: ' + IntToStr(Picked.Count) + #13#10 + Picked.Text;
      MessageBox(Msg, mfInformation + mfOKButton);
    finally
      Picked.Free;
    end;
  end;
  Dlg.Free;
end;

{ THyperlinkDemoView }

procedure THyperlinkDemoView.Draw;
const
  Bg = $17;
  Lbl = $1F;
  Linky = $1B;  { bright cyan on blue }
var
  B: TDrawBuffer;
  W, Y: Integer;
begin
  W := Size.X;
  Y := 0;

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'OSC 8 hyperlink test - hover or Ctrl+click below:', Lbl);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  { A long, multi-cell link. After the A1 fix the whole string should
    light up as one continuous link region on hover; before, each cell
    fragmented into its own micro-link. }
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Visit: ', Bg);
  DrawHyperlink(B, 8, 'https://example.com (long underlined link)', Linky,
    'https://example.com');
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'Two more, side by side - each should hover as a single', Bg);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, 'region (id= keeps cells in the same logical link):', Bg);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawHyperlink(B, 3, 'one.example.com', Linky, 'https://one.example.com');
  DrawHyperlink(B, 22, 'two.example.com', Linky, 'https://two.example.com');
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, '(Requires a terminal with OSC 8 support - Windows Terminal,', Bg);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);
  DrawChar(B, 0, ' ', Bg, W);
  DrawStr(B, 1, ' iTerm2, WezTerm, etc. See "Capability Showcase" for status.)', Bg);
  WriteLine(0, Y, W, 1, B);
  Inc(Y);

  while Y < Size.Y do
  begin
    DrawChar(B, 0, ' ', Bg, W);
    WriteLine(0, Y, W, 1, B);
    Inc(Y);
  end;
end;

procedure TMyApp.TestHyperlink;
var
  R: TRect;
  W: TWindow;
  V: THyperlinkDemoView;
begin
  R.Assign(5, 3, 75, 16);
  W := TWindow.Create(R, 'OSC 8 Hyperlink Test', wnNoNumber);
  W.GetExtent(R);
  R.Grow(-1, -1);
  V := THyperlinkDemoView.Create(R);
  V.GrowMode := gfGrowHiX or gfGrowHiY;
  W.Insert(V);
  Inc(WindowCount);
  Desktop.Insert(W);
end;

procedure TMyApp.TestProfileDump;
var
  Dlg: TDialog;
  R: TRect;
  P: TFVProfile;
  Lines: TStringList;
  ST: TStaticText;
  Y: Integer;

  function CSName(C: TFVColorSystem): string;
  begin
    case C of
      fvcsNoColors:  Result := 'NoColors';
      fvcsLegacy:    Result := 'Legacy (16)';
      fvcsEightBit:  Result := '8-bit (256)';
      fvcsTrueColor: Result := 'TrueColor (24-bit)';
    else
      Result := '?';
    end;
  end;

  function YN(B: Boolean): string;
  begin
    if B then Result := 'yes' else Result := 'no';
  end;

begin
  P := GetFVProfile;
  Lines := TStringList.Create;
  try
    Lines.Add('AnsiSupported    : ' + YN(P.AnsiSupported));
    Lines.Add('Interactive      : ' + YN(P.Interactive));
    Lines.Add('LegacyConsole    : ' + YN(P.LegacyConsole));
    Lines.Add('Unicode          : ' + YN(P.Unicode));
    Lines.Add('HyperlinkSupport : ' + YN(P.HyperlinkSupport));
    Lines.Add('SixelSupport     : ' + YN(P.SixelSupport));
    Lines.Add('IsCI             : ' + YN(P.IsCI));
    Lines.Add('ColorSystem      : ' + CSName(P.ColorSystem));

    R.Assign(10, 4, 64, 6 + Lines.Count + 4);
    Dlg := TDialog.Create(R, 'Capability Dump (FVProfile)');

    R.Assign(2, 1, 50, 2);
    Dlg.Insert(TStaticText.Create(R, 'Detected at startup; consult before drawing.'));

    for Y := 0 to Lines.Count - 1 do
    begin
      R.Assign(3, 3 + Y, 50, 4 + Y);
      ST := TStaticText.Create(R, Lines[Y]);
      Dlg.Insert(ST);
    end;

    R.Assign(20, Lines.Count + 4, 32, Lines.Count + 6);
    Dlg.Insert(TButton.Create(R, '~O~K', cmOK, bfDefault));
    Desktop.ExecView(Dlg);
    Dlg.Free;
  finally
    Lines.Free;
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
