{*******************************************************}
{       Free Vision - Text Editor Unit                  }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  The main source editor components.
  Based on FPC Free Vision implementation.

  Ported to Delphi: January 2026
}

unit Editors;

{$X+,R-,Q-}

interface

uses
  Objects, Drivers, Views, Dialogs, FVCommon, FVConsts, FVBoxChars, FVUTF8,
  SyntaxHighlight;

const
  { Length constants. }
  Tab_Stop_Length = 74;

  MaxLineLength  = 4096;
  MinBufLength   = $1000;
  MaxBufLength   = $7fffff00;
  NotFoundValue  = $ffffffff;
  LineInfoGrow   = 1024;
  MaxLines       = $7ffffff;

  { Editor constants for dialog boxes. }
  edOutOfMemory   = 0;
  edReadError     = 1;
  edWriteError    = 2;
  edCreateError   = 3;
  edSaveModify    = 4;
  edSaveUntitled  = 5;
  edSaveAs        = 6;
  edFind          = 7;
  edSearchFailed  = 8;
  edReplace       = 9;
  edReplacePrompt = 10;
  edJumpToLine         = 11;
  edPasteNotPossible   = 12;
  edReformatDocument   = 13;
  edReformatNotAllowed = 14;
  edReformNotPossible  = 15;
  edReplaceNotPossible = 16;
  edRightMargin        = 17;
  edSetTabStops        = 18;
  edWrapNotPossible    = 19;

  { Editor flag constants for dialog options. }
  efCaseSensitive   = $0001;
  efWholeWordsOnly  = $0002;
  efPromptOnReplace = $0004;
  efReplaceAll      = $0008;
  efDoReplace       = $0010;
  efBackupFiles     = $0100;

  { Constants for object palettes. }
  CIndicator = #2#3;
  CEditor    = #6#7;
  CMemo      = #26#27;

type
  PPoint = ^TPoint;  { Pointer to TPoint }

  TEditorDialog = function(Dialog: SmallInt; Info: Pointer): Word;

  TIndicator = class(TView)
  private
    FLocation   : TPoint;
    FModified   : Boolean;
    FAutoIndent : Boolean;
    FWordWrap   : Boolean;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure   Draw; override;
    function    GetPalette: PPalette; override;
    procedure   SetState(AState: Word; Enable: Boolean); override;
    procedure   SetValue(ALocation: TPoint; IsAutoIndent: Boolean;
                         IsModified: Boolean; IsWordWrap: Boolean);
    property Location: TPoint read FLocation write FLocation;
    property Modified: Boolean read FModified write FModified;
    property AutoIndent: Boolean read FAutoIndent write FAutoIndent;
    property WordWrap: Boolean read FWordWrap write FWordWrap;
  end;

  TLineInfoRec = record
    Len, Attr: Sw_Word;
  end;
  TLineInfoArr = array[0..MaxLines] of TLineInfoRec;
  PLineInfoArr = ^TLineInfoArr;

  TLineInfo = class(TObject)
  private
    FInfo: PLineInfoArr;
    FMaxPos: Sw_Word;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Grow(Pos: Sw_Word);
    procedure SetLen(Pos, Val: Sw_Word);
    procedure SetAttr(Pos, Val: Sw_Word);
    function  GetLen(Pos: Sw_Word): Sw_Word;
    function  GetAttr(Pos: Sw_Word): Sw_Word;
    property Info: PLineInfoArr read FInfo write FInfo;
    property MaxPos: Sw_Word read FMaxPos write FMaxPos;
  end;

  PEditBuffer = ^TEditBuffer;
  TEditBuffer = array[0..MaxBufLength] of Byte;  { UTF-8 encoded bytes }

  TEditor = class;

  TEditor = class(TView)
  private
    FHScrollBar        : TScrollBar;
    FVScrollBar        : TScrollBar;
    FIndicator         : TIndicator;
    FBuffer            : PEditBuffer;
    FBufSize           : Sw_Word;
    FBufLen            : Sw_Word;
    FGapLen            : Sw_Word;
    FSelStart          : Sw_Word;
    FSelEnd            : Sw_Word;
    FCurPtr            : Sw_Word;
    FCurPos            : TPoint;
    FDelta             : TPoint;
    FLimit             : TPoint;
    FDrawLine          : Sw_Integer;
    FDrawPtr           : Sw_Word;
    FDelCount          : Sw_Word;
    FInsCount          : Sw_Word;
    FFlags             : LongInt;
    FIsReadOnly        : Boolean;
    FIsValid           : Boolean;
    FCanUndo           : Boolean;
    FModified          : Boolean;
    FSelecting         : Boolean;
    FOverwrite         : Boolean;
    FAutoIndent        : Boolean;
    FNoSelect          : Boolean;
    FTabSize           : Sw_Word;
    FBlankLine         : Sw_Word;
    FWord_Wrap         : Boolean;
    FLine_Number       : String[8];
    FRight_Margin      : Sw_Integer;
    FTab_Settings      : String[Tab_Stop_Length];
    FKeyState          : SmallInt;
    FLockCount         : Byte;
    FUpdateFlags       : Byte;
    FPlace_Marker      : array[1..10] of Sw_Word;
    FSearch_Replace    : Boolean;
    FHighlighter       : ISyntaxHighlighter;
    FColorTheme        : TSyntaxColorTheme;
    FUseHighlighter    : Boolean;

    procedure  Center_Text(Select_Mode: Byte);
    function   CharPos(P, Target: Sw_Word): Sw_Integer;
    function   CharPtr(P: Sw_Word; Target: Sw_Integer): Sw_Word;
    procedure  Check_For_Word_Wrap(Select_Mode: Byte; Center_Cursor: Boolean);
    function   ClipCopy: Boolean;
    procedure  ClipCut;
    procedure  ClipPaste;
    procedure  DeleteRange(StartPtr, EndPtr: Sw_Word; DelSelect: Boolean);
    procedure  DoSearchReplace;
    procedure  DoUpdate;
    function   Do_Word_Wrap(Select_Mode: Byte; Center_Cursor: Boolean): Boolean;
    procedure  DrawLines(Y, Count: Sw_Integer; LinePtr: Sw_Word);
    procedure  Find;
    function   GetMousePtr(Mouse: TPoint): Sw_Word;
    function   HasSelection: Boolean;
    procedure  HideSelect;
    procedure  Insert_Line(Select_Mode: Byte);
    function   IsClipboard: Boolean;
    procedure  Jump_FPlace_Marker(Element: Byte; Select_Mode: Byte);
    procedure  Jump_To_Line(Select_Mode: Byte);
    function   LineEnd(P: Sw_Word): Sw_Word;
    function   LineMove(P: Sw_Word; Count: Sw_Integer): Sw_Word;
    function   LineStart(P: Sw_Word): Sw_Word;
    function   LineNr(P: Sw_Word): Sw_Word;
    procedure  Lock;
    function   NewLine(Select_Mode: Byte): Boolean;
    function   NextChar(P: Sw_Word): Sw_Word;
    function   NextLine(P: Sw_Word): Sw_Word;
    function   NextWord(P: Sw_Word): Sw_Word;
    function   PrevChar(P: Sw_Word): Sw_Word;
    function   PrevLine(P: Sw_Word): Sw_Word;
    function   PrevWord(P: Sw_Word): Sw_Word;
    procedure  Reformat_Document(Select_Mode: Byte; Center_Cursor: Boolean);
    function   Reformat_Paragraph(Select_Mode: Byte; Center_Cursor: Boolean): Boolean;
    procedure  Remove_EOL_Spaces(Select_Mode: Byte);
    procedure  Replace;
    procedure  Scroll_Down;
    procedure  Scroll_Up;
    procedure  Select_Word;
    procedure  SetBufLen(Length: Sw_Word);
    procedure  Set_FPlace_Marker(Element: Byte);
    procedure  Set_Right_Margin;
    procedure  Set_Tabs;
    procedure  StartSelect;
    procedure  Tab_Key(Select_Mode: Byte);
    procedure  ToggleInsMode;
    procedure  Unlock;
    procedure  Update(AFlags: Byte);
    procedure  Update_FPlace_Markers(AddCount: Word; KillCount: Word; StartPtr, EndPtr: Sw_Word);
  public
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
                     AIndicator: TIndicator; ABufSize: Sw_Word); reintroduce; virtual;
    destructor Destroy; override;
    function   BufByte(P: Sw_Word): Byte;         { Raw byte at position }
    function   BufChar(P: Sw_Word): Char;         { Decoded UTF-8 character }
    function   BufCharStr(P: Sw_Word): string;    { Decoded UTF-8 as string (supports emoji) }
    function   BufCharWidth(P: Sw_Word): Integer; { Display width: 1 or 2 (wide/emoji) }
    function   BufCharLen(P: Sw_Word): Integer;   { Byte length of UTF-8 char at P }
    function   BufPtr(P: Sw_Word): Sw_Word;
    procedure  ChangeBounds(var Bounds: TRect); override;
    procedure  ConvertEvent(var Event: TEvent); virtual;
    function   CursorVisible: Boolean;
    procedure  DeleteSelect;
    procedure  DoneBuffer; virtual;
    procedure  Draw; override;
    procedure  FormatLine(var DrawBuf; LinePtr: Sw_Word; Width: Sw_Integer; Colors: Word); virtual;
    function   GetPalette: PPalette; override;
    procedure  HandleEvent(var Event: TEvent); override;
    procedure  InitBuffer; virtual;
    function   InsertBuffer(P: PEditBuffer; Offset, Length: Sw_Word;
                            AllowUndo, SelectText: Boolean): Boolean;
    function   InsertFrom(Editor: TEditor): Boolean; virtual;
    function   InsertText(Text: Pointer; Length: Sw_Word; SelectText: Boolean): Boolean;
    procedure  InsertUnicodeChar(C: Char);  { Insert Unicode char as UTF-8 }
    procedure  InsertUnicodeStr(const S: string);  { Insert Unicode string as UTF-8 (supports emoji) }
    procedure  ScrollTo(X, Y: Sw_Integer);
    function   Search(const FindStr: String; Opts: Word): Boolean;
    function   SetBufSize(NewSize: Sw_Word): Boolean; virtual;
    procedure  SetCmdState(Command: Word; Enable: Boolean);
    procedure  SetSelect(NewStart, NewEnd: Sw_Word; CurStart: Boolean);
    procedure  SetCurPtr(P: Sw_Word; SelectMode: Byte);
    procedure  SetState(AState: Word; Enable: Boolean); override;
    procedure  TrackCursor(Center: Boolean);
    procedure  Undo;
    procedure  UpdateCommands; virtual;
    function   Valid(Command: Word): Boolean; override;
    property HScrollBar: TScrollBar read FHScrollBar write FHScrollBar;
    property VScrollBar: TScrollBar read FVScrollBar write FVScrollBar;
    property Indicator: TIndicator read FIndicator write FIndicator;
    property Buffer: PEditBuffer read FBuffer write FBuffer;
    property BufSize: Sw_Word read FBufSize write FBufSize;
    property BufLen: Sw_Word read FBufLen write FBufLen;
    property GapLen: Sw_Word read FGapLen write FGapLen;
    property SelStart: Sw_Word read FSelStart write FSelStart;
    property SelEnd: Sw_Word read FSelEnd write FSelEnd;
    property CurPtr: Sw_Word read FCurPtr write FCurPtr;
    property CurPos: TPoint read FCurPos write FCurPos;
    property Delta: TPoint read FDelta write FDelta;
    property Limit: TPoint read FLimit write FLimit;
    property DrawLine: Sw_Integer read FDrawLine write FDrawLine;
    property DrawPtr: Sw_Word read FDrawPtr write FDrawPtr;
    property DelCount: Sw_Word read FDelCount write FDelCount;
    property InsCount: Sw_Word read FInsCount write FInsCount;
    property Flags: LongInt read FFlags write FFlags;
    property IsReadOnly: Boolean read FIsReadOnly write FIsReadOnly;
    property IsValid: Boolean read FIsValid write FIsValid;
    property CanUndo: Boolean read FCanUndo write FCanUndo;
    property Modified: Boolean read FModified write FModified;
    property Selecting: Boolean read FSelecting write FSelecting;
    property Overwrite: Boolean read FOverwrite write FOverwrite;
    property AutoIndent: Boolean read FAutoIndent write FAutoIndent;
    property NoSelect: Boolean read FNoSelect write FNoSelect;
    property TabSize: Sw_Word read FTabSize write FTabSize;
    property BlankLine: Sw_Word read FBlankLine write FBlankLine;
    property Word_Wrap: Boolean read FWord_Wrap write FWord_Wrap;
    property Right_Margin: Sw_Integer read FRight_Margin write FRight_Margin;
    property Highlighter: ISyntaxHighlighter read FHighlighter write FHighlighter;
    property ColorTheme: TSyntaxColorTheme read FColorTheme write FColorTheme;
    property UseHighlighter: Boolean read FUseHighlighter write FUseHighlighter;
  end;

  TMemoData = record
    Length: Sw_Word;
    Buffer: TEditBuffer;
  end;

  TMemo = class(TEditor)
  public
    function    DataSize: Word; override;
    procedure   GetData(var Rec); override;
    function    GetPalette: PPalette; override;
    procedure   HandleEvent(var Event: TEvent); override;
    procedure   SetData(var Rec); override;
  end;

  TFileEditor = class(TEditor)
  private
    FFileName: FNameStr;
    FHadBOM: Boolean;        { True if original file had UTF-8 BOM }
  public
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
                     AIndicator: TIndicator; AFileName: FNameStr); reintroduce; virtual;
    procedure   DoneBuffer; override;
    procedure   HandleEvent(var Event: TEvent); override;
    procedure   InitBuffer; override;
    function    LoadFile: Boolean;
    function    Save: Boolean;
    function    SaveAs: Boolean;
    function    SaveFile: Boolean;
    function    SetBufSize(NewSize: Sw_Word): Boolean; override;
    procedure   UpdateCommands; override;
    function    Valid(Command: Word): Boolean; override;
    property FileName: FNameStr read FFileName write FFileName;
  end;

  TEditWindow = class(TWindow)
  private
    FEditor: TFileEditor;
    FGutter: TView;  { TEditorGutter - stored as TView to avoid circular ref }
  public
    constructor Create(var Bounds: TRect; AFileName: FNameStr; ANumber: SmallInt); reintroduce; virtual;
    procedure   Close; override;
    function    GetTitle(MaxSize: Sw_Integer): TTitleStr; override;
    procedure   HandleEvent(var Event: TEvent); override;
    procedure   SizeLimits(var Min, Max: TPoint); override;
    property Editor: TFileEditor read FEditor write FEditor;
    property Gutter: TView read FGutter write FGutter;
  end;

function DefEditorDialog(Dialog: SmallInt; Info: Pointer): Word;
function CreateFindDialog: TDialog;
function CreateReplaceDialog: TDialog;
function JumpLineDialog: TDialog;
function ReformDocDialog: TDialog;
function RightMarginDialog: TDialog;
function TabStopDialog: TDialog;
function StdEditorDialog(Dialog: SmallInt; Info: Pointer): Word;

{ Unicode-aware word character detection }
function IsWordChar(C: Char): Boolean; inline;

const
  LineBreak: String[2] = #13#10;

  Allow_Reformat: Boolean = True;

  EditorDialog: TEditorDialog = DefEditorDialog;
  EditorFlags: Word = efBackupFiles + efPromptOnReplace;
  FindStr: String[80] = '';
  ReplaceStr: String[80] = '';
  Clipboard: TEditor = nil;

var
  ToClipCmds: TCommandSet = ([cmCut, cmCopy, cmClear]);
  FromClipCmds: TCommandSet = ([cmPaste]);
  UndoCmds: TCommandSet = ([cmUndo, cmRedo]);

type
  TFindDialogRec = packed record
    Find: String[80];
    Options: Word;
  end;

  TReplaceDialogRec = packed record
    Find: String[80];
    Replace: String[80];
    Options: Word;
  end;

  TRightMarginRec = packed record
    Margin_Position: String[3];
  end;

  TTabStopRec = packed record
    Tab_String: String[Tab_Stop_Length];
  end;

{ String constants (replacing FPC resourcestrings) }
const
  sClipboard = 'Clipboard';
  sFileCreateError = 'Error creating file %s';
  sFileReadError = 'Error reading file %s';
  sFileUntitled = 'Save untitled file?';
  sFileWriteError = 'Error writing to file %s';
  sFind = 'Find';
  sJumpTo = 'Jump To';
  sModified = #3'%s'#13#10#13#3'has been modified.  Save?';
  sOutOfMemory = 'Not enough memory for this operation.';
  sPasteNotPossible = 'Wordwrap on:  Paste not possible in current margins when at end of line.';
  sReformatDocument = 'Reformat Document';
  sReformatNotPossible = 'Paragraph reformat not possible while trying to wrap current line with current margins.';
  sReformattingTheDocument = 'Reformatting the document:';
  sReplaceNotPossible = 'Wordwrap on:  Replace not possible in current margins when at end of line.';
  sReplaceThisOccurence = 'Replace this occurrence?';
  sRightMargin = 'Right Margin';
  sSearchStringNotFound = 'Search string not found.';
  sSelectWhereToBegin = 'Please select where to begin.';
  sSetting = 'Setting:';
  sTabSettings = 'Tab Settings';
  sUnknownDialog = 'Unknown dialog requested!';
  sUntitled = 'Untitled';
  sWordWrapNotPossible = 'Wordwrap on:  Wordwrap not possible in current margins with continuous line.';
  sWordWrapOff = 'You must turn on wordwrap before you can reformat.';

  slCaseSensitive = '~C~ase sensitive';
  slCurrentLine = '~C~urrent line';
  slEntireDocument = '~E~ntire document';
  slLineNumber = '~L~ine number';
  slName = '~N~ame';
  slNewText = '~N~ew text';
  slOK = 'O~K~';
  slCancel = 'Cancel';
  slPromptOnReplace = '~P~rompt on replace';
  slReplace = '~R~eplace';
  slReplaceAll = '~R~eplace all';
  slSaveFileAs = 'Save File As';
  slTextToFind = '~T~ext to find';
  slWholeWordsOnly = '~W~hole words only';

implementation

uses
  SysUtils, System.Character, App, StdDlg, MsgBox, FVClipboard;

{ Unicode-aware word character detection }
function IsWordChar(C: Char): Boolean;
begin
  Result := C.IsLetterOrDigit or (C = '_');
end;

const
  { Update flag constants. }
  ufUpdate = $01;
  ufLine   = $02;
  ufView   = $04;
  ufStats  = $05;

  { SelectMode constants. }
  smExtend = $01;
  smDouble = $02;

  sfSearchFailed = NotFoundValue;

  { Arrays that hold all the command keys and options. }
  FirstKeys: array[0..46 * 2] of Word = (46,
    Ord(^A), cmWordLeft,
    Ord(^B), cmReformPara,
    Ord(^C), cmPageDown,
    Ord(^D), cmCharRight,
    Ord(^E), cmLineUp,
    Ord(^F), cmWordRight,
    Ord(^G), cmDelChar,
    Ord(^H), cmBackSpace,
    Ord(^J), $FF04,
    Ord(^K), $FF02,
    Ord(^L), cmSearchAgain,
    Ord(^M), cmNewLine,
    Ord(^N), cmInsertLine,
    Ord(^O), $FF03,
    Ord(^Q), $FF01,
    Ord(^R), cmPageUp,
    Ord(^S), cmCharLeft,
    Ord(^T), cmDelWord,
    Ord(^U), cmUndo,
    Ord(^V), cmInsMode,
    Ord(^X), cmLineDown,
    Ord(^Y), cmDelLine,
    kbLeft, cmCharLeft,
    kbRight, cmCharRight,
    kbCtrlLeft, cmWordLeft,
    kbCtrlRight, cmWordRight,
    kbHome, cmLineStart,
    kbEnd, cmLineEnd,
    kbUp, cmLineUp,
    kbDown, cmLineDown,
    kbPgUp, cmPageUp,
    kbPgDn, cmPageDown,
    kbCtrlPgUp, cmTextStart,
    kbCtrlPgDn, cmTextEnd,
    kbIns, cmInsMode,
    kbDel, cmDelChar,
    kbShiftIns, cmPaste,
    kbShiftDel, cmCut,
    kbCtrlIns, cmCopy,
    kbCtrlDel, cmClear,
    kbCtrlBack, cmDelStart,
    kbCtrlEnter, cmNewLine,
    kbCtrlEnd, cmDelEnd,
    kbCtrlHome, cmDelStart,
    kbBack, cmBackSpace,
    kbTab, cmTabKey);

  QuickKeys: array[0..9 * 2] of Word = (9,
    Ord('A'), cmReplace,
    Ord('C'), cmTextEnd,
    Ord('D'), cmLineEnd,
    Ord('F'), cmFind,
    Ord('H'), cmDelStart,
    Ord('R'), cmTextStart,
    Ord('S'), cmLineStart,
    Ord('Y'), cmDelEnd,
    Ord('G'), cmJumpMark0);

  BlockKeys: array[0..20 * 2] of Word = (20,
    Ord('B'), cmStartSelect,
    Ord('C'), cmPaste,
    Ord('D'), cmSaveDone,
    Ord('F'), cmSaveAs,
    Ord('H'), cmHideSelect,
    Ord('K'), cmEndSelect,
    Ord('S'), cmSave,
    Ord('T'), cmSelectWord,
    Ord('X'), cmSave,
    Ord('Y'), cmCut,
    Ord('0'), cmSetMark0,
    Ord('1'), cmSetMark1,
    Ord('2'), cmSetMark2,
    Ord('3'), cmSetMark3,
    Ord('4'), cmSetMark4,
    Ord('5'), cmSetMark5,
    Ord('6'), cmSetMark6,
    Ord('7'), cmSetMark7,
    Ord('8'), cmSetMark8,
    Ord('9'), cmSetMark9);

  FormatKeys: array[0..5 * 2] of Word = (5,
    Ord('C'), cmCenterText,
    Ord('T'), cmCenterText,
    Ord('I'), cmSetTabs,
    Ord('R'), cmRightMargin,
    Ord('W'), cmWordWrap);

  JumpKeys: array[0..1 * 2] of Word = (1,
    Ord('L'), cmJumpLine);

  KeyMap: array[0..4] of Pointer = (@FirstKeys, @QuickKeys, @BlockKeys, @FormatKeys, @JumpKeys);

{****************************************************************************
                                 Dialogs
****************************************************************************}

function DefEditorDialog(Dialog: SmallInt; Info: Pointer): Word;
begin
  Result := cmCancel;
end;

function CreateFindDialog: TDialog;
var
  D: TDialog;
  Control: TView;
  R: TRect;
begin
  R.Assign(0, 0, 38, 12);
  D := TDialog.Create(R, sFind);
  D.Options := D.Options or ofCentered;

  R.Assign(3, 3, 32, 4);
  Control := TInputLine.Create(R, 80);
  Control.HelpCtx := hcDFindText;
  D.Insert(Control);
  R.Assign(2, 2, 15, 3);
  D.Insert(TLabel.Create(R, slTextToFind, Control));
  R.Assign(32, 3, 35, 4);
  D.Insert(THistory.Create(R, TInputLine(Control), 10));

  R.Assign(3, 5, 35, 7);
  Control := TCheckBoxes.Create(R,
    NewSItem(slCaseSensitive,
    NewSItem(slWholeWordsOnly, nil)));
  Control.HelpCtx := hcCCaseSensitive;
  D.Insert(Control);

  R.Assign(14, 9, 24, 11);
  Control := TButton.Create(R, slOK, cmOk, bfDefault);
  Control.HelpCtx := hcDOk;
  D.Insert(Control);

  Inc(R.A.X, 12);
  Inc(R.B.X, 12);
  Control := TButton.Create(R, slCancel, cmCancel, bfNormal);
  Control.HelpCtx := hcDCancel;
  D.Insert(Control);

  D.SelectNext(False);
  Result := D;
end;

function CreateReplaceDialog: TDialog;
var
  D: TDialog;
  Control: TView;
  R: TRect;
begin
  R.Assign(0, 0, 40, 16);
  D := TDialog.Create(R, slReplace);
  D.Options := D.Options or ofCentered;

  R.Assign(3, 3, 34, 4);
  Control := TInputLine.Create(R, 80);
  Control.HelpCtx := hcDFindText;
  D.Insert(Control);
  R.Assign(2, 2, 15, 3);
  D.Insert(TLabel.Create(R, slTextToFind, Control));
  R.Assign(34, 3, 37, 4);
  D.Insert(THistory.Create(R, TInputLine(Control), 10));

  R.Assign(3, 6, 34, 7);
  Control := TInputLine.Create(R, 80);
  Control.HelpCtx := hcDReplaceText;
  D.Insert(Control);
  R.Assign(2, 5, 12, 6);
  D.Insert(TLabel.Create(R, slNewText, Control));
  R.Assign(34, 6, 37, 7);
  D.Insert(THistory.Create(R, TInputLine(Control), 11));

  R.Assign(3, 8, 37, 12);
  Control := TCheckBoxes.Create(R,
    NewSItem(slCaseSensitive,
    NewSItem(slWholeWordsOnly,
    NewSItem(slPromptOnReplace,
    NewSItem(slReplaceAll, nil)))));
  Control.HelpCtx := hcCCaseSensitive;
  D.Insert(Control);

  R.Assign(8, 13, 18, 15);
  Control := TButton.Create(R, slOK, cmOk, bfDefault);
  Control.HelpCtx := hcDOk;
  D.Insert(Control);

  R.Assign(22, 13, 32, 15);
  Control := TButton.Create(R, slCancel, cmCancel, bfNormal);
  Control.HelpCtx := hcDCancel;
  D.Insert(Control);

  D.SelectNext(False);
  Result := D;
end;

function JumpLineDialog: TDialog;
var
  D: TDialog;
  R: TRect;
  Control: TView;
begin
  R.Assign(0, 0, 26, 8);
  D := TDialog.Create(R, sJumpTo);
  D.Options := D.Options or ofCentered;

  R.Assign(3, 2, 15, 3);
  Control := TStaticText.Create(R, slLineNumber);
  D.Insert(Control);

  R.Assign(15, 2, 21, 3);
  Control := TInputLine.Create(R, 4);
  Control.HelpCtx := hcDLineNumber;
  D.Insert(Control);

  R.Assign(21, 2, 24, 3);
  D.Insert(THistory.Create(R, TInputLine(Control), 12));

  R.Assign(2, 5, 12, 7);
  Control := TButton.Create(R, slOK, cmOK, bfDefault);
  Control.HelpCtx := hcDOk;
  D.Insert(Control);

  R.Assign(14, 5, 24, 7);
  Control := TButton.Create(R, slCancel, cmCancel, bfNormal);
  Control.HelpCtx := hcDCancel;
  D.Insert(Control);

  D.SelectNext(False);
  Result := D;
end;

function ReformDocDialog: TDialog;
var
  R: TRect;
  D: TDialog;
  Control: TView;
begin
  R.Assign(0, 0, 32, 11);
  D := TDialog.Create(R, sReformatDocument);
  D.Options := D.Options or ofCentered;

  R.Assign(2, 2, 30, 3);
  Control := TStaticText.Create(R, sSelectWhereToBegin);
  D.Insert(Control);

  R.Assign(3, 3, 29, 6);
  Control := TRadioButtons.Create(R,
    NewSItem(slCurrentLine,
    NewSItem(slEntireDocument, nil)));
  D.Insert(Control);

  R.Assign(4, 8, 14, 10);
  Control := TButton.Create(R, slOK, cmOK, bfDefault);
  Control.HelpCtx := hcDOk;
  D.Insert(Control);

  R.Assign(18, 8, 28, 10);
  Control := TButton.Create(R, slCancel, cmCancel, bfNormal);
  Control.HelpCtx := hcDCancel;
  D.Insert(Control);

  D.SelectNext(False);
  Result := D;
end;

function RightMarginDialog: TDialog;
var
  R: TRect;
  D: TDialog;
  Control: TView;
begin
  R.Assign(0, 0, 30, 8);
  D := TDialog.Create(R, sRightMargin);
  D.Options := D.Options or ofCentered;

  R.Assign(3, 2, 12, 3);
  Control := TStaticText.Create(R, sSetting);
  D.Insert(Control);

  R.Assign(14, 2, 20, 3);
  Control := TInputLine.Create(R, 3);
  Control.HelpCtx := hcDRightMargin;
  D.Insert(Control);

  R.Assign(20, 2, 23, 3);
  D.Insert(THistory.Create(R, TInputLine(Control), 13));

  R.Assign(4, 5, 14, 7);
  Control := TButton.Create(R, slOK, cmOK, bfDefault);
  Control.HelpCtx := hcDOk;
  D.Insert(Control);

  R.Assign(16, 5, 26, 7);
  Control := TButton.Create(R, slCancel, cmCancel, bfNormal);
  Control.HelpCtx := hcDCancel;
  D.Insert(Control);

  D.SelectNext(False);
  Result := D;
end;

function TabStopDialog: TDialog;
var
  R: TRect;
  D: TDialog;
  Control: TView;
begin
  R.Assign(0, 0, 80, 8);
  D := TDialog.Create(R, sTabSettings);
  D.Options := D.Options or ofCentered;

  R.Assign(2, 2, 78, 3);
  Control := TStaticText.Create(R,
    '....+....1....+....2....+....3....+....4....+....5....+....6....+....7....');
  D.Insert(Control);

  R.Assign(2, 3, 78, 4);
  Control := TInputLine.Create(R, 74);
  Control.HelpCtx := hcDTabStops;
  D.Insert(Control);

  R.Assign(38, 5, 41, 6);
  D.Insert(THistory.Create(R, TInputLine(Control), 14));

  R.Assign(27, 5, 37, 7);
  Control := TButton.Create(R, slOK, cmOK, bfDefault);
  Control.HelpCtx := hcDOk;
  D.Insert(Control);

  R.Assign(42, 5, 52, 7);
  Control := TButton.Create(R, slCancel, cmCancel, bfNormal);
  Control.HelpCtx := hcDCancel;
  D.Insert(Control);

  D.SelectNext(False);
  Result := D;
end;

function GetFileNameFromInfo(Info: Pointer): string;
type
  PFNameStr = ^FNameStr;  { Pointer to string (UnicodeString), not ShortString }
begin
  Result := '(unknown)';
  if Info = nil then
    Exit;
  try
    Result := PFNameStr(Info)^;
  except
    Result := '(error reading filename)';
  end;
end;

function StdEditorDialog(Dialog: SmallInt; Info: Pointer): Word;
var
  R: TRect;
  T: TPoint;
  FormattedMsg: string;
begin
  case Dialog of
    edOutOfMemory:
      Result := MessageBox(sOutOfMemory, mfError + mfOkButton);
    edReadError:
      begin
        FormattedMsg := Format('Error reading file: %s', [GetFileNameFromInfo(Info)]);
        Result := MessageBox(FormattedMsg, mfError + mfOkButton);
      end;
    edWriteError:
      begin
        FormattedMsg := Format('Error writing file: %s', [GetFileNameFromInfo(Info)]);
        Result := MessageBox(FormattedMsg, mfError + mfOkButton);
      end;
    edCreateError:
      begin
        FormattedMsg := Format('Error creating file: %s', [GetFileNameFromInfo(Info)]);
        Result := MessageBox(FormattedMsg, mfError + mfOkButton);
      end;
    edSaveModify:
      begin
        FormattedMsg := Format('%s has been modified. Save?', [GetFileNameFromInfo(Info)]);
        Result := MessageBox(FormattedMsg, mfInformation + mfYesNoCancel);
      end;
    edSaveUntitled:
      Result := MessageBox(sFileUntitled, mfInformation + mfYesNoCancel);
    edSaveAs:
      Result := Application.ExecuteDialog(TFileDialog.Create('*.*',
        slSaveFileAs, slName, fdOkButton, 101), Info);
    edFind:
      Result := Application.ExecuteDialog(CreateFindDialog, Info);
    edSearchFailed:
      Result := MessageBox(sSearchStringNotFound, mfError + mfOkButton);
    edReplace:
      Result := Application.ExecuteDialog(CreateReplaceDialog, Info);
    edReplacePrompt:
      begin
        R.Assign(0, 1, 40, 8);
        R.Move((Desktop.Size.X - R.B.X) div 2, 0);
        Desktop.MakeGlobal(R.B, T);
        Inc(T.Y);
        if PPoint(Info)^.Y <= T.Y then
          R.Move(0, Desktop.Size.Y - R.B.Y - 2);
        Result := MessageBoxRect(R, sReplaceThisOccurence,
          mfYesNoCancel + mfInformation);
      end;
    edJumpToLine:
      Result := Application.ExecuteDialog(JumpLineDialog, Info);
    edSetTabStops:
      Result := Application.ExecuteDialog(TabStopDialog, Info);
    edPasteNotPossible:
      Result := MessageBox(sPasteNotPossible, mfError + mfOkButton);
    edReformatDocument:
      Result := Application.ExecuteDialog(ReformDocDialog, Info);
    edReformatNotAllowed:
      Result := MessageBox(sWordWrapOff, mfError + mfOkButton);
    edReformNotPossible:
      Result := MessageBox(sReformatNotPossible, mfError + mfOkButton);
    edReplaceNotPossible:
      Result := MessageBox(sReplaceNotPossible, mfError + mfOkButton);
    edRightMargin:
      Result := Application.ExecuteDialog(RightMarginDialog, Info);
    edWrapNotPossible:
      Result := MessageBox(sWordWrapNotPossible, mfError + mfOKButton);
  else
    Result := MessageBox(sUnknownDialog, mfError + mfOkButton);
  end;
end;

{****************************************************************************
                                 Helpers
****************************************************************************}

function CountLines(var Buf; Count: Sw_Word): Sw_Integer;
var
  P: PByte;
  Lines: Sw_Word;
begin
  P := PByte(@Buf);
  Lines := 0;
  while Count > 0 do
  begin
    if P^ in [10, 13] then  { LF, CR }
    begin
      Inc(Lines);
      if (P + 1)^ + P^ = 23 then  { CR+LF or LF+CR pair }
      begin
        Inc(P);
        Dec(Count);
        if Count = 0 then
          Break;
      end;
    end;
    Inc(P);
    Dec(Count);
  end;
  Result := Lines;
end;

procedure GetLimits(var Buf; Count: Sw_Word; var Lim: TPoint);
var
  P: PByte;
  Len: Sw_Word;
begin
  Lim.X := 0;
  Lim.Y := 0;
  Len := 0;
  P := PByte(@Buf);
  while Count > 0 do
  begin
    if P^ in [10, 13] then  { LF, CR }
    begin
      if Sw_Integer(Len) > Lim.X then
        Lim.X := Len;
      Inc(Lim.Y);
      if (P + 1)^ + P^ = 23 then  { CR+LF or LF+CR pair }
      begin
        Inc(P);
        Dec(Count);
      end;
      Len := 0;
    end
    else
      Inc(Len);
    Inc(P);
    Dec(Count);
  end;
end;

function ScanKeyMap(KeyMap: Pointer; KeyCode: Word): Word;
var
  P: PWord;
  Count: Sw_Word;
begin
  P := KeyMap;
  Count := P^;
  Inc(P);
  while Count > 0 do
  begin
    if (Lo(P^) = Lo(KeyCode)) and ((Hi(P^) = 0) or (Hi(P^) = Hi(KeyCode))) then
    begin
      Inc(P);
      Result := P^;
      Exit;
    end;
    Inc(P, 2);
    Dec(Count);
  end;
  Result := 0;
end;

type
  BTable = array[0..255] of Byte;

{ Boyer-Moore skip table for UTF-8 byte search }
procedure BMMakeTableUTF8(const S: TBytes; var T: BTable);
var
  X, Len: Integer;
begin
  Len := Length(S);
  FillChar(T, SizeOf(T), Len);
  for X := Len - 1 downto 0 do
    if T[S[X]] = Len then
      T[S[X]] := Len - 1 - X;
end;

{ Case-sensitive search - searches for UTF-8 encoded string in buffer }
function Scan(var Block; Size: Sw_Word; const Str: String): Sw_Word;
var
  Buffer: array[0..MaxBufLength - 1] of Byte absolute Block;
  SearchBytes: TBytes;
  Len, Numb: Integer;
  Found: Boolean;
  BT: BTable;
  I: Integer;
begin
  { Convert search string to UTF-8 bytes }
  SearchBytes := TEncoding.UTF8.GetBytes(Str);
  Len := Length(SearchBytes);
  if (Len = 0) or (Sw_Word(Len) > Size) then
  begin
    Result := NotFoundValue;
    Exit;
  end;

  BMMakeTableUTF8(SearchBytes, BT);
  Found := False;
  Numb := Len - 1;

  while (not Found) and (Numb < Integer(Size)) do
  begin
    { Check last byte first }
    if Buffer[Numb] = SearchBytes[Len - 1] then
    begin
      { Potential match - verify all bytes }
      Found := True;
      for I := 0 to Len - 1 do
      begin
        if Buffer[Numb - (Len - 1) + I] <> SearchBytes[I] then
        begin
          Found := False;
          Break;
        end;
      end;
      if not Found then
        Inc(Numb);
    end
    else
      Inc(Numb, BT[Buffer[Numb]]);
  end;

  if not Found then
    Result := NotFoundValue
  else
    Result := Numb - (Len - 1);
end;

{ Case-insensitive search - decodes UTF-8 and compares using Unicode case folding }
function IScan(var Block; Size: Sw_Word; const Str: String): Sw_Word;
var
  Buffer: array[0..MaxBufLength - 1] of Byte absolute Block;
  SearchUpper: String;
  BufPos, SearchLen: Integer;
  BufChar, SearchChar: Char;
  CharLen, SearchIdx: Integer;
  Found: Boolean;
  MatchStart: Integer;
begin
  SearchUpper := UpperCase(Str);
  SearchLen := Length(SearchUpper);

  if (SearchLen = 0) or (Sw_Word(SearchLen) > Size) then
  begin
    Result := NotFoundValue;
    Exit;
  end;

  BufPos := 0;
  Found := False;

  while (BufPos < Integer(Size)) and not Found do
  begin
    { Decode UTF-8 character from buffer }
    BufChar := DecodeUTF8Char(@Buffer[BufPos], Integer(Size) - BufPos, CharLen);
    if CharLen = 0 then
    begin
      Inc(BufPos);
      Continue;
    end;

    { Check if first character matches (case-insensitive) }
    if UpCase(BufChar) = SearchUpper[1] then
    begin
      { Potential match - verify remaining characters }
      MatchStart := BufPos;
      Found := True;
      SearchIdx := 1;

      while (SearchIdx <= SearchLen) and Found and (BufPos < Integer(Size)) do
      begin
        BufChar := DecodeUTF8Char(@Buffer[BufPos], Integer(Size) - BufPos, CharLen);
        if CharLen = 0 then
        begin
          Found := False;
          Break;
        end;

        SearchChar := SearchUpper[SearchIdx];
        if UpCase(BufChar) <> SearchChar then
          Found := False
        else
        begin
          Inc(BufPos, CharLen);
          Inc(SearchIdx);
        end;
      end;

      { Check if we matched all search characters }
      if Found and (SearchIdx <= SearchLen) then
        Found := False;

      if Found then
      begin
        Result := MatchStart;
        Exit;
      end;

      { Reset to continue searching from next character after match start }
      BufPos := MatchStart;
      BufChar := DecodeUTF8Char(@Buffer[BufPos], Integer(Size) - BufPos, CharLen);
      if CharLen > 0 then
        Inc(BufPos, CharLen)
      else
        Inc(BufPos);
    end
    else
      Inc(BufPos, CharLen);
  end;

  Result := NotFoundValue;
end;

{****************************************************************************
                                 TIndicator
****************************************************************************}

constructor TIndicator.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  GrowMode := gfGrowLoY + gfGrowHiY;
end;

procedure TIndicator.Draw;
var
  Color: Byte;
  Frame: Char;
  S: string;
  B: TDrawBuffer;
begin
  if State and sfDragging = 0 then
  begin
    Color := GetColor(1);
    Frame := BoxDblHoriz;
  end
  else
  begin
    Color := GetColor(2);
    Frame := BoxHoriz;
  end;
  DrawChar(B, 0, Frame, Color, Size.X);
  { If the text has been modified, put an 'M' in the TIndicator display. }
  if Modified then
    DrawChar(B, 1, 'M', Color, 1);
  { If WordWrap is active put a 'W' in the TIndicator display. }
  if WordWrap then
    DrawChar(B, 2, 'W', Color, 1)
  else
    DrawChar(B, 2, Frame, Color, 1);
  { If AutoIndent is active put an 'I' in TIndicator display. }
  if AutoIndent then
    DrawChar(B, 0, 'I', Color, 1)
  else
    DrawChar(B, 0, Frame, Color, 1);
  S := Format(' %d:%d ', [Location.Y + 1, Location.X + 1]);
  DrawStr(B, 9 - Pos(':', S), S, Color);
  WriteBuf(0, 0, Size.X, 1, B);
end;

function TIndicator.GetPalette: PPalette;
const
  P: String[Length(CIndicator)] = CIndicator;
begin
  Result := PPalette(@P);
end;

procedure TIndicator.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState = sfDragging then
    DrawView;
end;

procedure TIndicator.SetValue(ALocation: TPoint; IsAutoIndent: Boolean;
                              IsModified: Boolean; IsWordWrap: Boolean);
begin
  if (Location.X <> ALocation.X) or
     (Location.Y <> ALocation.Y) or
     (AutoIndent <> IsAutoIndent) or
     (Modified <> IsModified) or
     (WordWrap <> IsWordWrap) then
  begin
    Location := ALocation;
    AutoIndent := IsAutoIndent;
    Modified := IsModified;
    WordWrap := IsWordWrap;
    DrawView;
  end;
end;

{****************************************************************************
                                 TLineInfo
****************************************************************************}

constructor TLineInfo.Create;
begin
  inherited Create;
  FMaxPos := 0;
  Grow(1);
end;

destructor TLineInfo.Destroy;
begin
  FreeMem(FInfo, FMaxPos * SizeOf(TLineInfoRec));
  FInfo := nil;
  inherited Destroy;
end;

procedure TLineInfo.Grow(Pos: Sw_Word);
var
  NewSize: Sw_Word;
  P: Pointer;
begin
  NewSize := (Pos + LineInfoGrow - (Pos mod LineInfoGrow));
  GetMem(P, NewSize * SizeOf(TLineInfoRec));
  FillChar(P^, NewSize * SizeOf(TLineInfoRec), 0);
  if FMaxPos > 0 then
    Move(FInfo^, P^, FMaxPos * SizeOf(TLineInfoRec));
  if FMaxPos > 0 then
    FreeMem(FInfo, FMaxPos * SizeOf(TLineInfoRec));
  FInfo := P;
  FMaxPos := NewSize;
end;

procedure TLineInfo.SetLen(Pos, Val: Sw_Word);
begin
  if Pos >= FMaxPos then
    Grow(Pos);
  FInfo^[Pos].Len := Val;
end;

procedure TLineInfo.SetAttr(Pos, Val: Sw_Word);
begin
  if Pos >= FMaxPos then
    Grow(Pos);
  FInfo^[Pos].Attr := Val;
end;

function TLineInfo.GetLen(Pos: Sw_Word): Sw_Word;
begin
  Result := FInfo^[Pos].Len;
end;

function TLineInfo.GetAttr(Pos: Sw_Word): Sw_Word;
begin
  Result := FInfo^[Pos].Attr;
end;

{****************************************************************************
                                 TEditor
****************************************************************************}

constructor TEditor.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
                         AIndicator: TIndicator; ABufSize: Sw_Word);
var
  Element: Byte;
begin
  inherited Create(Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
  Options := Options or ofSelectable;
  FFlags := EditorFlags;
  EventMask := evMouseDown + evKeyDown + evCommand + evBroadcast;
  ShowCursor;

  FHScrollBar := AHScrollBar;
  FVScrollBar := AVScrollBar;

  FIndicator := AIndicator;
  FBufSize := ABufSize;
  FCanUndo := True;
  InitBuffer;

  if Assigned(FBuffer) then
    FIsValid := True
  else
  begin
    EditorDialog(edOutOfMemory, nil);
    FBufSize := 0;
  end;

  SetBufLen(0);

  for Element := 1 to 10 do
    FPlace_Marker[Element] := 0;

  Element := 1;
  FTab_Settings := '';
  while Element <= 70 do
  begin
    if Element mod 5 = 0 then
      FTab_Settings := FTab_Settings + 'x'
    else
      FTab_Settings := FTab_Settings + ' ';
    Inc(Element);
  end;
  { Default Right_Margin value. }
  FRight_Margin := 76;
  FTabSize := 8;
end;

destructor TEditor.Destroy;
begin
  DoneBuffer;
  inherited Destroy;
end;

function TEditor.BufByte(P: Sw_Word): Byte;
begin
  if P >= CurPtr then
    Inc(P, GapLen);
  Result := Buffer^[P];
end;

function TEditor.BufChar(P: Sw_Word): Char;
var
  PhysP: Sw_Word;
  Remaining: Integer;
  CharLen: Integer;
begin
  if P >= BufLen then
  begin
    Result := #0;
    Exit;
  end;

  PhysP := P;
  if PhysP >= CurPtr then
    Inc(PhysP, GapLen);

  { Calculate remaining bytes in buffer }
  Remaining := BufSize - PhysP;
  if Remaining <= 0 then
  begin
    Result := #0;
    Exit;
  end;

  { Decode UTF-8 character }
  Result := DecodeUTF8Char(@Buffer^[PhysP], Remaining, CharLen);
end;

function TEditor.BufCharStr(P: Sw_Word): string;
var
  PhysP: Sw_Word;
  Remaining: Integer;
  CharLen: Integer;
begin
  if P >= BufLen then
  begin
    Result := '';
    Exit;
  end;

  PhysP := P;
  if PhysP >= CurPtr then
    Inc(PhysP, GapLen);

  { Calculate remaining bytes in buffer }
  Remaining := BufSize - PhysP;
  if Remaining <= 0 then
  begin
    Result := '';
    Exit;
  end;

  { Decode UTF-8 character to full string (supports surrogate pairs for emoji) }
  Result := DecodeUTF8ToString(@Buffer^[PhysP], Remaining, CharLen);
end;

function TEditor.BufCharWidth(P: Sw_Word): Integer;
var
  PhysP: Sw_Word;
  Remaining: Integer;
  CharLen: Integer;
  CP: Cardinal;
begin
  Result := 1;
  if P >= BufLen then Exit;

  PhysP := P;
  if PhysP >= CurPtr then
    Inc(PhysP, GapLen);

  Remaining := BufSize - PhysP;
  if Remaining <= 0 then Exit;

  CP := DecodeUTF8CodePoint(@Buffer^[PhysP], Remaining, CharLen);
  Result := CodePointCharWidth(CP);
  if Result < 1 then Result := 1;  { Minimum 1 column for editor purposes }
end;

function TEditor.BufCharLen(P: Sw_Word): Integer;
var
  PhysP: Sw_Word;
  B: Byte;
begin
  if P >= BufLen then
  begin
    Result := 1;  { Return 1 to prevent infinite loops in callers }
    Exit;
  end;

  PhysP := P;
  if PhysP >= CurPtr then
    Inc(PhysP, GapLen);

  B := Buffer^[PhysP];
  Result := UTF8CharLen(B);

  { Make sure we return at least 1 to prevent infinite loops }
  if Result < 1 then
    Result := 1;

  { Make sure we don't exceed buffer length }
  if P + Result > BufLen then
    Result := BufLen - P;
  if Result < 1 then
    Result := 1;
end;

function TEditor.BufPtr(P: Sw_Word): Sw_Word;
begin
  if P >= CurPtr then
    Result := P + GapLen
  else
    Result := P;
end;

procedure TEditor.Center_Text(Select_Mode: Byte);
var
  Spaces: array[1..80] of Byte;
  Index: Byte;
  Line_Length: Sw_Integer;
  E, S: Sw_Word;
begin
  E := LineEnd(CurPtr);
  S := LineStart(CurPtr);
  if E = S then
    Exit;
  SetCurPtr(S, Select_Mode);
  Remove_EOL_Spaces(Select_Mode);
  if Buffer^[BufPtr(CurPtr)] = 32 then  { ASCII space }
  begin
    E := LineEnd(CurPtr);
    if NextWord(CurPtr) > E then
      Exit;
    if E - NextWord(CurPtr) > Sw_Word(Right_Margin) then
      Exit;
    DeleteRange(CurPtr, NextWord(CurPtr), True);
    E := LineEnd(CurPtr);
    SetCurPtr(LineStart(CurPtr), Select_Mode);
  end
  else
    if E - CurPtr > Sw_Word(Right_Margin) then
      Exit;
  Line_Length := E - CurPtr;
  for Index := 1 to ((Right_Margin - Line_Length) shr 1) do
    Spaces[Index] := 32;  { ASCII space }
  InsertText(@Spaces, Index, False);
  SetCurPtr(LineEnd(CurPtr), Select_Mode);
end;

procedure TEditor.ChangeBounds(var Bounds: TRect);
begin
  SetBounds(Bounds);
  FDelta.X := Max(0, Min(FDelta.X, FLimit.X - Size.X));
  FDelta.Y := Max(0, Min(FDelta.Y, FLimit.Y - Size.Y));
  Update(ufView);
end;

function TEditor.CharPos(P, Target: Sw_Word): Sw_Integer;
var
  Pos: Sw_Integer;
begin
  Pos := 0;
  while P < Target do
  begin
    if BufChar(P) = #9 then
      Pos := Pos or (TabSize - 1);
    Inc(Pos, BufCharWidth(P));
    Inc(P, BufCharLen(P));
  end;
  Result := Pos;
end;

function TEditor.CharPtr(P: Sw_Word; Target: Sw_Integer): Sw_Word;
var
  Pos: Sw_Integer;
  CharLen: Integer;
begin
  Pos := 0;
  while (Pos < Target) and (P < BufLen) and not ((BufChar(P) = #10) or (BufChar(P) = #13)) do
  begin
    if BufChar(P) = #9 then
      Pos := Pos or (TabSize - 1);
    Inc(Pos, BufCharWidth(P));
    CharLen := BufCharLen(P);
    Inc(P, CharLen);
  end;
  if Pos > Target then
    P := PrevChar(P);
  Result := P;
end;

procedure TEditor.Check_For_Word_Wrap(Select_Mode: Byte; Center_Cursor: Boolean);
begin
  if FCurPos.X > Right_Margin then
    Do_Word_Wrap(Select_Mode, Center_Cursor);
end;

function TEditor.ClipCopy: Boolean;
var
  UTF8Bytes: TBytes;
  SelLen, PhysStart, PhysEnd, BeforeGap, AfterGap: Sw_Word;
begin
  Result := False;
  if not HasSelection then
    Exit;

  { Extract selected UTF-8 bytes from gap buffer and set system clipboard }
  SelLen := SelEnd - SelStart;
  if SelLen > 0 then begin
    SetLength(UTF8Bytes, SelLen);
    PhysStart := BufPtr(SelStart);
    PhysEnd := BufPtr(SelEnd);
    if (SelStart < CurPtr) and (SelEnd > CurPtr) then begin
      { Selection spans the gap }
      BeforeGap := CurPtr - SelStart;
      AfterGap := SelEnd - CurPtr;
      Move(Buffer^[PhysStart], UTF8Bytes[0], BeforeGap);
      Move(Buffer^[CurPtr + GapLen], UTF8Bytes[BeforeGap], AfterGap);
    end else begin
      { Selection is entirely on one side of the gap }
      Move(Buffer^[PhysStart], UTF8Bytes[0], SelLen);
    end;
    FVClipboard.ClipboardSetText(TEncoding.UTF8.GetString(UTF8Bytes));
  end;

  { Internal clipboard copy }
  if Assigned(Clipboard) and (Clipboard <> Self) then begin
    Clipboard.SetSelect(0, Clipboard.BufLen, True);
    Clipboard.DeleteSelect;
    Result := Clipboard.InsertFrom(Self);
    Clipboard.SetSelect(0, Clipboard.BufLen, False);
  end else
    Result := True;  { System clipboard succeeded even without internal clipboard }
  Selecting := False;
  Update(ufUpdate);
end;

procedure TEditor.ClipCut;
begin
  if ClipCopy then
  begin
    Update_FPlace_Markers(0, SelEnd - SelStart, SelStart, SelEnd);
    DeleteSelect;
  end;
end;

procedure TEditor.ClipPaste;
var
  SysText: string;
begin
  if Word_Wrap and (FCurPos.X > Right_Margin) then
  begin
    EditorDialog(edPasteNotPossible, nil);
    Exit;
  end;
  { Check for bulk paste from burst detection first }
  if Drivers.PasteText <> '' then begin
    InsertUnicodeStr(Drivers.PasteText);
    Drivers.PasteText := '';
    Exit;
  end;
  { Try system clipboard first }
  if FVClipboard.ClipboardHasText then begin
    SysText := FVClipboard.ClipboardGetText;
    if SysText <> '' then begin
      InsertUnicodeStr(SysText);
      Exit;
    end;
  end;
  { Fall back to internal clipboard }
  if not Assigned(Clipboard) then
    Exit;
  if Clipboard = Self then
    Exit;
  if not Clipboard.HasSelection then
    Exit;
  if CurPtr = SelStart then
    Update_FPlace_Markers(Clipboard.SelEnd - Clipboard.SelStart, 0,
                         Clipboard.SelStart, Clipboard.SelEnd);
  InsertFrom(Clipboard);
end;

procedure TEditor.ConvertEvent(var Event: TEvent);
var
  ShiftState: Byte;
  Key: Word;
begin
  ShiftState := GetShiftState;
  if Event.What = evKeyDown then
  begin
    if (ShiftState and $03 <> 0) and (Event.ScanCode >= $47) and (Event.ScanCode <= $51) then
      Event.CharCode := #0;
    Key := Event.KeyCode;
    if FKeyState <> 0 then
    begin
      if (Lo(Key) >= $01) and (Lo(Key) <= $1A) then
        Inc(Key, $40);
      if (Lo(Key) >= $61) and (Lo(Key) <= $7A) then
        Dec(Key, $20);
    end;
    Key := ScanKeyMap(KeyMap[FKeyState], Key);
    FKeyState := 0;
    if Key <> 0 then
      if Hi(Key) = $FF then
      begin
        FKeyState := Lo(Key);
        ClearEvent(Event);
      end
      else
      begin
        Event.What := evCommand;
        Event.Command := Key;
      end;
  end;
end;

function TEditor.CursorVisible: Boolean;
begin
  Result := (FCurPos.Y >= FDelta.Y) and (FCurPos.Y < FDelta.Y + Size.Y);
end;

procedure TEditor.DeleteRange(StartPtr, EndPtr: Sw_Word; DelSelect: Boolean);
begin
  Update_FPlace_Markers(0, EndPtr - StartPtr, StartPtr, EndPtr);
  if HasSelection and DelSelect then
    DeleteSelect
  else
  begin
    SetSelect(CurPtr, EndPtr, True);
    DeleteSelect;
    SetSelect(StartPtr, CurPtr, False);
    DeleteSelect;
  end;
end;

procedure TEditor.DeleteSelect;
begin
  InsertText(nil, 0, False);
end;

procedure TEditor.DoneBuffer;
begin
  ReallocMem(FBuffer, 0);
end;

procedure TEditor.DoSearchReplace;
var
  I: Word;
  C: TPoint;
begin
  repeat
    I := cmCancel;
    if not Search(FindStr, Flags) then
    begin
      if Flags and (efReplaceAll + efDoReplace) <> (efReplaceAll + efDoReplace) then
        EditorDialog(edSearchFailed, nil);
    end
    else if Flags and efDoReplace <> 0 then
    begin
      I := cmYes;
      if Flags and efPromptOnReplace <> 0 then
      begin
        MakeGlobal(Cursor, C);
        I := EditorDialog(edReplacePrompt, Pointer(@C));
      end;
      if I = cmYes then
      begin
        if Word_Wrap and ((FCurPos.X + Sw_Integer(Length(ReplaceStr)) - Sw_Integer(Length(FindStr))) > Right_Margin) then
          EditorDialog(edReplaceNotPossible, nil)
        else
        begin
          Lock;
          FSearch_Replace := True;
          if Length(ReplaceStr) < Length(FindStr) then
            Update_FPlace_Markers(0, Length(FindStr) - Length(ReplaceStr),
                                 CurPtr - Sw_Word(Length(FindStr)) + Sw_Word(Length(ReplaceStr)), CurPtr)
          else if Length(ReplaceStr) > Length(FindStr) then
            Update_FPlace_Markers(Length(ReplaceStr) - Length(FindStr), 0,
                                 CurPtr, CurPtr + Sw_Word(Length(ReplaceStr)) - Sw_Word(Length(FindStr)));
          InsertText(@ReplaceStr[1], Length(ReplaceStr), False);
          FSearch_Replace := False;
          TrackCursor(False);
          Unlock;
        end;
      end;
    end;
  until (I = cmCancel) or (Flags and efReplaceAll = 0);
end;

procedure TEditor.DoUpdate;
begin
  if FUpdateFlags <> 0 then
  begin
    SetCursor(FCurPos.X - FDelta.X, FCurPos.Y - FDelta.Y);
    if FUpdateFlags and ufView <> 0 then
      DrawView
    else if FUpdateFlags and ufLine <> 0 then
      DrawLines(FCurPos.Y - FDelta.Y, 1, LineStart(CurPtr));
    if Assigned(HScrollBar) then
      HScrollBar.SetParams(FDelta.X, 0, FLimit.X - Size.X, Size.X div 2, 1);
    if Assigned(VScrollBar) then
      VScrollBar.SetParams(FDelta.Y, 0, FLimit.Y - Size.Y, Size.Y - 1, 1);
    if Assigned(Indicator) then
      Indicator.SetValue(CurPos, AutoIndent, Modified, Word_Wrap);
    if State and sfActive <> 0 then
      UpdateCommands;
    FUpdateFlags := 0;
    { Notify gutter and other listeners of cursor/scroll changes }
    Message(Owner, evBroadcast, cmCursorChanged, @Self);
  end;
end;

function TEditor.Do_Word_Wrap(Select_Mode: Byte; Center_Cursor: Boolean): Boolean;
var
  A, C, L, P, S: Sw_Word;
begin
  Result := False;
  Select_Mode := 0;
  if BufLen >= (BufSize - 1) then
    Exit;
  C := CurPtr;
  L := BufLen;
  S := LineStart(CurPtr);

  if AutoIndent and (Buffer^[BufPtr(S)] = 32) then  { space }
  begin
    if NextWord(S) > CurPtr then
      A := CurPtr
    else
      A := NextWord(S);
  end
  else
    A := NextWord(S);

  Remove_EOL_Spaces(Select_Mode);
  if FCurPos.X = 0 then
  begin
    NewLine(Select_Mode);
    Result := True;
    Exit;
  end;

  { Check for special conditions }
  if Buffer^[BufPtr(CurPtr)] = 32 then  { space }
  begin
    SetCurPtr(PrevChar(CurPtr), Select_Mode);
    if Buffer^[BufPtr(CurPtr)] = 32 then  { space }
    begin
      SetCurPtr(NextChar(CurPtr), Select_Mode);
      EditorDialog(edWrapNotPossible, nil);
      Exit;
    end;
  end
  else
  begin
    P := PrevWord(CurPtr);
    if P = LineStart(CurPtr) then
    begin
      EditorDialog(edWrapNotPossible, nil);
      Exit;
    end;
    SetCurPtr(P, Select_Mode);
    if Buffer^[BufPtr(CurPtr)] = 32 then  { space }
      SetCurPtr(NextChar(CurPtr), Select_Mode);
  end;

  if not NewLine(Select_Mode) then
    Exit;

  if AutoIndent and (A > S) and (A < C) then
  begin
    P := A - S;
    while P > 0 do
    begin
      InsertText(@Buffer^[BufPtr(S)], 1, False);
      Dec(P);
    end;
  end;

  SetCurPtr(LineEnd(CurPtr), Select_Mode);
  Result := True;
end;

procedure TEditor.Draw;
begin
  DrawLines(0, Size.Y, LineMove(DrawPtr, FDelta.Y - DrawLine));
end;

procedure TEditor.DrawLines(Y, Count: Sw_Integer; LinePtr: Sw_Word);
var
  B: TDrawBuffer;
  Color: Word;
begin
  Color := GetColor($0201);
  while Count > 0 do
  begin
    DrawChar(B, 0, ' ', Byte(Color), Size.X);
    FormatLine(B, LinePtr, Size.X, Color);
    WriteLine(0, Y, Size.X, 1, B);
    LinePtr := NextLine(LinePtr);
    Inc(Y);
    Dec(Count);
  end;
end;

procedure TEditor.Find;
var
  FindRec: TFindDialogRec;
begin
  FindRec.Find := FindStr;
  FindRec.Options := Flags;
  if EditorDialog(edFind, @FindRec) <> cmCancel then
  begin
    FindStr := FindRec.Find;
    Flags := FindRec.Options and not efDoReplace;
    DoSearchReplace;
  end;
end;

procedure TEditor.FormatLine(var DrawBuf; LinePtr: Sw_Word; Width: Sw_Integer; Colors: Word);
var
  Buf: PDrawBuffer;
  X: Sw_Integer;
  OutPos: Sw_Integer;  { Position in output buffer }
  C: Char;
  CStr: string;
  CharLen: Integer;
  Color, SelColor: Byte;
  SelS, SelE: Sw_Integer;
  CurColor: Byte;
begin
  Buf := @DrawBuf;
  var OrigLinePtr: Sw_Word := LinePtr;
  X := 0;
  OutPos := 0;
  Color := Lo(Colors);
  SelColor := Hi(Colors);

  { Calculate selection range }
  if (SelStart <> SelEnd) and (LinePtr < SelEnd) then
  begin
    SelS := 0;
    if LinePtr < SelStart then
      SelS := CharPos(LinePtr, SelStart);
    SelE := CharPos(LinePtr, Min(LineEnd(LinePtr), SelEnd));
  end
  else
  begin
    SelS := MaxLineLength;
    SelE := MaxLineLength;
  end;

  while (X < Width + FDelta.X) and (LinePtr < BufLen) do
  begin
    C := BufChar(LinePtr);
    CharLen := BufCharLen(LinePtr);

    if (C = #10) or (C = #13) then
      Break;
    if C = #9 then
    begin
      repeat
        if X >= FDelta.X then
        begin
          if (X >= SelS) and (X < SelE) then
            CurColor := SelColor
          else
            CurColor := Color;
          if OutPos < MaxViewWidth then
          begin
            Buf^[OutPos].Ch := ' ';
            Buf^[OutPos].Attr := CurColor;
          end;
          Inc(OutPos);
        end;
        Inc(X);
      until (X mod TabSize = 0) or (X >= Width + FDelta.X);
    end
    else
    begin
      { Use full string decoding to support emoji (surrogate pairs) }
      CStr := BufCharStr(LinePtr);
      if CStr = '' then CStr := C;
      if X >= FDelta.X then
      begin
        if (X >= SelS) and (X < SelE) then
          CurColor := SelColor
        else
          CurColor := Color;
        if OutPos < MaxViewWidth then
        begin
          Buf^[OutPos].Ch := CStr;
          Buf^[OutPos].Attr := CurColor;
        end;
        Inc(OutPos);
        { Wide characters take 2 columns - fill second column with space }
        if BufCharWidth(LinePtr) > 1 then
        begin
          if OutPos < MaxViewWidth then
          begin
            Buf^[OutPos].Ch := ' ';
            Buf^[OutPos].Attr := CurColor;
          end;
          Inc(OutPos);
        end;
      end;
      Inc(X, BufCharWidth(LinePtr));
    end;
    Inc(LinePtr, CharLen);  { Advance by UTF-8 character length }
  end;

  { Fill rest with spaces }
  while X < Width + FDelta.X do
  begin
    if X >= FDelta.X then
    begin
      if OutPos < MaxViewWidth then
      begin
        Buf^[OutPos].Ch := ' ';
        Buf^[OutPos].Attr := Color;
      end;
      Inc(OutPos);
    end;
    Inc(X);
  end;

  { Syntax highlighting pass: apply token colors to the rendered buffer }
  if FUseHighlighter and (FHighlighter <> nil) then begin
    var LineText: string := '';
    var TempPtr: Sw_Word;
    TempPtr := OrigLinePtr;
    while TempPtr < BufLen do begin
      var TC := BufChar(TempPtr);
      if (TC = #10) or (TC = #13) then Break;
      LineText := LineText + BufCharStr(TempPtr);
      Inc(TempPtr, BufCharLen(TempPtr));
    end;

    FHighlighter.SetLine(LineText, -1);
    var Token: TSyntaxToken;
    while FHighlighter.NextToken(Token) do begin
      var ThemeColor := FColorTheme.Colors[Token.Kind];
      if ThemeColor.FG_RGB = 0 then Continue; { Skip unthemed tokens }
      { Map token char positions to buffer positions }
      { Token.StartPos is 1-based in LineText; need to subtract FDelta.X }
      var BufStart := Token.StartPos - 1 - FDelta.X;
      var BufEnd := BufStart + Token.Length;
      if BufStart < 0 then BufStart := 0;
      if BufEnd > OutPos then BufEnd := OutPos;
      for var J := BufStart to BufEnd - 1 do begin
        if (J >= 0) and (J < MaxViewWidth) then begin
          { Don't override selection colors }
          var SrcX := J + FDelta.X;
          if (SrcX >= SelS) and (SrcX < SelE) then Continue;
          if ThemeColor.FG_RGB <> 0 then
            Buf^[J].FG_RGB := ThemeColor.FG_RGB;
          if ThemeColor.BG_RGB <> 0 then
            Buf^[J].BG_RGB := ThemeColor.BG_RGB;
          Buf^[J].ExtAttrs := ThemeColor.ExtAttrs;
          Buf^[J].UL_RGB := ThemeColor.UL_RGB;
        end;
      end;
    end;
  end;
end;

function TEditor.GetMousePtr(Mouse: TPoint): Sw_Word;
begin
  MakeLocal(Mouse, Mouse);
  Mouse.X := Max(0, Min(Mouse.X, Size.X - 1));
  Mouse.Y := Max(0, Min(Mouse.Y, Size.Y - 1));
  Result := CharPtr(LineMove(DrawPtr, Mouse.Y + FDelta.Y - DrawLine), Mouse.X + FDelta.X);
end;

function TEditor.GetPalette: PPalette;
const
  P: String[Length(CEditor)] = CEditor;
begin
  Result := PPalette(@P);
end;

procedure TEditor.HandleEvent(var Event: TEvent);
var
  CenterCursor: Boolean;
  SelectMode: Byte;
  NewPtr: Sw_Word;
  D, Mouse: TPoint;
  ShiftState: Byte;

  function CheckScrollBar(P: TScrollBar; var D: Sw_Integer): Boolean;
  begin
    Result := False;
    if (Event.InfoPtr = P) and (P.Value <> D) then
    begin
      D := P.Value;
      Update(ufView);
      Result := True;
    end;
  end;

begin
  inherited HandleEvent(Event);
  CenterCursor := not CursorVisible;
  SelectMode := 0;
  ShiftState := GetShiftState;
  { Check shift state BEFORE ConvertEvent changes evKeyDown to evCommand }
  if (ShiftState and $03 <> 0) and (Event.What = evKeyDown) then
    SelectMode := smExtend;
  ConvertEvent(Event);
  { Also check for commands - shift may still be held for cursor movement commands }
  if (ShiftState and $03 <> 0) and (Event.What = evCommand) then
    SelectMode := smExtend;

  case Event.What of
    evMouseDown:
      begin
        { Handle mouse wheel scrolling }
        if Event.Buttons and (mbScrollWheelUp or mbScrollWheelDown) <> 0 then begin
          if Event.Buttons and mbScrollWheelUp <> 0 then
            ScrollTo(FDelta.X, FDelta.Y - 3)
          else
            ScrollTo(FDelta.X, FDelta.Y + 3);
          ClearEvent(Event);
          Exit;
        end;

        if Event.Double then
          SelectMode := smDouble;

        repeat
          Lock;
          if Event.What = evMouseAuto then
          begin
            MakeLocal(Event.Where, Mouse);
            D.X := 0;
            D.Y := 0;
            if Mouse.X < 0 then
              D.X := -1
            else if Mouse.X >= Size.X then
              D.X := 1;
            if Mouse.Y < 0 then
              D.Y := -1
            else if Mouse.Y >= Size.Y then
              D.Y := 1;
            if (D.X <> 0) or (D.Y <> 0) then
              ScrollTo(FDelta.X + D.X, FDelta.Y + D.Y);
          end;
          SetCurPtr(GetMousePtr(Event.Where), SelectMode);
          SelectMode := smExtend;
          Unlock;
        until not MouseEvent(Event, evMouseMove + evMouseAuto);
        ClearEvent(Event);
      end;

    evKeyDown:
      begin
        { Handle printable Unicode characters }
        { Check LastUnicodeStr first for surrogate pair support (emoji) }
        if (LastUnicodeStr <> '') and (Length(LastUnicodeStr) > 1) and
           (Ord(LastUnicodeStr[1]) >= $D800) and (Ord(LastUnicodeStr[1]) <= $DBFF) then
        begin
          { Surrogate pair (emoji) - insert the full string as UTF-8 }
          Lock;
          if Overwrite and not HasSelection then
            if BufChar(CurPtr) <> #13 then
              SetSelect(CurPtr, NextChar(CurPtr), True);
          InsertUnicodeStr(LastUnicodeStr);
          LastUnicodeStr := '';
          if Word_Wrap then
            Check_For_Word_Wrap(SelectMode, CenterCursor);
          TrackCursor(CenterCursor);
          Unlock;
          ClearEvent(Event);
        end
        else if Event.UnicodeChar >= ' ' then
        begin
          Lock;
          if Overwrite and not HasSelection then
            if BufChar(CurPtr) <> #13 then
              SetSelect(CurPtr, NextChar(CurPtr), True);
          { Convert Unicode char to UTF-8 and insert }
          InsertUnicodeChar(Event.UnicodeChar);
          if Word_Wrap then
            Check_For_Word_Wrap(SelectMode, CenterCursor);
          TrackCursor(CenterCursor);
          Unlock;
          ClearEvent(Event);
        end
        else
          Exit;
      end;

    evCommand:
      begin
        Lock;
        case Event.Command of
          cmFind: Find;
          cmReplace: Replace;
          cmSearchAgain: DoSearchReplace;
          cmCut: ClipCut;
          cmCopy: ClipCopy;
          cmPaste: ClipPaste;
          cmUndo: Undo;
          cmClear: DeleteSelect;
          cmCharLeft: SetCurPtr(PrevChar(CurPtr), SelectMode);
          cmCharRight: SetCurPtr(NextChar(CurPtr), SelectMode);
          cmWordLeft: SetCurPtr(PrevWord(CurPtr), SelectMode);
          cmWordRight: SetCurPtr(NextWord(CurPtr), SelectMode);
          cmLineStart: SetCurPtr(LineStart(CurPtr), SelectMode);
          cmLineEnd: SetCurPtr(LineEnd(CurPtr), SelectMode);
          cmLineUp: SetCurPtr(LineMove(CurPtr, -1), SelectMode);
          cmLineDown: SetCurPtr(LineMove(CurPtr, 1), SelectMode);
          cmPageUp: SetCurPtr(LineMove(CurPtr, -(Size.Y - 1)), SelectMode);
          cmPageDown: SetCurPtr(LineMove(CurPtr, Size.Y - 1), SelectMode);
          cmTextStart: SetCurPtr(0, SelectMode);
          cmTextEnd: SetCurPtr(BufLen, SelectMode);
          cmNewLine: NewLine(SelectMode);
          cmBackSpace:
            if not HasSelection then
            begin
              if CurPtr > 0 then
              begin
                SetSelect(PrevChar(CurPtr), CurPtr, True);
                DeleteSelect;
              end;
            end
            else
              DeleteSelect;
          cmDelChar:
            if not HasSelection then
            begin
              if CurPtr < BufLen then
              begin
                SetSelect(CurPtr, NextChar(CurPtr), True);
                DeleteSelect;
              end;
            end
            else
              DeleteSelect;
          cmDelWord:
            if not HasSelection then
            begin
              SetSelect(CurPtr, NextWord(CurPtr), True);
              DeleteSelect;
            end
            else
              DeleteSelect;
          cmDelStart:
            if not HasSelection then
            begin
              SetSelect(LineStart(CurPtr), CurPtr, True);
              DeleteSelect;
            end
            else
              DeleteSelect;
          cmDelEnd:
            if not HasSelection then
            begin
              SetSelect(CurPtr, LineEnd(CurPtr), True);
              DeleteSelect;
            end
            else
              DeleteSelect;
          cmDelLine:
            begin
              SetSelect(LineStart(CurPtr), NextLine(CurPtr), True);
              DeleteSelect;
            end;
          cmInsMode: ToggleInsMode;
          cmStartSelect: StartSelect;
          cmEndSelect: Selecting := False;
          cmHideSelect: HideSelect;
          cmInsertLine: Insert_Line(SelectMode);
          cmIndentMode: AutoIndent := not AutoIndent;
          cmTabKey: Tab_Key(SelectMode);
          cmScrollUp: Scroll_Up;
          cmScrollDown: Scroll_Down;
          cmSelectWord: Select_Word;
          cmWordWrap: Word_Wrap := not Word_Wrap;
          cmReformPara: Reformat_Paragraph(SelectMode, CenterCursor);
          cmReformDoc: Reformat_Document(SelectMode, CenterCursor);
          cmRightMargin: Set_Right_Margin;
          cmSetTabs: Set_Tabs;
          cmCenterText: Center_Text(SelectMode);
          cmJumpLine: Jump_To_Line(SelectMode);
          cmSetMark0..cmSetMark9: Set_FPlace_Marker(Event.Command - cmSetMark0);
          cmJumpMark0..cmJumpMark9: Jump_FPlace_Marker(Event.Command - cmJumpMark0, SelectMode);
        else
          Unlock;
          Exit;
        end;
        TrackCursor(CenterCursor);
        Unlock;
        ClearEvent(Event);
      end;

    evBroadcast:
      case Event.Command of
        cmScrollBarChanged:
          if (Event.InfoPtr = HScrollBar) or (Event.InfoPtr = VScrollBar) then
          begin
            CheckScrollBar(HScrollBar, FDelta.X);
            CheckScrollBar(VScrollBar, FDelta.Y);
          end
          else
            Exit;
      else
        Exit;
      end;
  end;
  ClearEvent(Event);
end;

function TEditor.HasSelection: Boolean;
begin
  Result := SelStart <> SelEnd;
end;

procedure TEditor.HideSelect;
begin
  Selecting := False;
  SetSelect(CurPtr, CurPtr, False);
end;

procedure TEditor.InitBuffer;
begin
  Buffer := nil;
end;

procedure TEditor.Insert_Line(Select_Mode: Byte);
var
  P: Sw_Word;
begin
  P := CurPtr;
  NewLine(Select_Mode);
  SetCurPtr(P, Select_Mode);
end;

function TEditor.InsertBuffer(P: PEditBuffer; Offset, Length: Sw_Word;
                              AllowUndo, SelectText: Boolean): Boolean;
var
  SelLen, DelLen: Sw_Word;
  SelLines, Lines: Sw_Word;
  NewSize: LongInt;
begin
  Result := True;
  Selecting := False;
  SelLen := SelEnd - SelStart;

  if (SelLen = 0) and (Length = 0) then
    Exit;

  DelLen := 0;
  if AllowUndo then
  begin
    if CurPtr = SelStart then
      DelLen := SelLen
    else if SelLen > InsCount then
      DelLen := SelLen - InsCount;
  end;

  NewSize := LongInt(BufLen + DelCount - SelLen + DelLen) + Length;
  if NewSize > BufLen + DelCount then
    if (NewSize > MaxBufLength) or not SetBufSize(NewSize) then
    begin
      EditorDialog(edOutOfMemory, nil);
      Result := False;
      SelEnd := SelStart;
      Exit;
    end;

  { Count lines in selection being deleted }
  SelLines := CountLines(Buffer^[BufPtr(SelStart)], SelLen);

  { Handle deletion when cursor is at end of selection }
  if CurPtr = SelEnd then
  begin
    if AllowUndo then
    begin
      if DelLen > 0 then
        Move(Buffer^[SelStart], Buffer^[CurPtr + GapLen - DelCount - DelLen], DelLen);
      Dec(FInsCount, SelLen - DelLen);
    end;
    CurPtr := SelStart;
    Dec(FCurPos.Y, SelLines);
  end;

  { Adjust FDelta.Y if needed }
  if FDelta.Y > FCurPos.Y then
  begin
    Dec(FDelta.Y, SelLines);
    if FDelta.Y < FCurPos.Y then
      FDelta.Y := FCurPos.Y;
  end;

  { Insert new text }
  if Length > 0 then
    Move(P^[Offset], Buffer^[CurPtr], Length);

  { Count lines in new text }
  Lines := CountLines(Buffer^[CurPtr], Length);
  Inc(FCurPtr, Length);

  { Update buffer length BEFORE position calculations (BufCharLen needs correct BufLen) }
  if Length > SelLen then
  begin
    Inc(FBufLen, Length - SelLen);
    Dec(FGapLen, Length - SelLen);
  end
  else
  begin
    Dec(FBufLen, SelLen - Length);
    Inc(FGapLen, SelLen - Length);
  end;

  { Update cursor position (now BufLen is correct for BufCharLen) }
  Inc(FCurPos.Y, Lines);
  DrawLine := FCurPos.Y;
  DrawPtr := LineStart(CurPtr);
  FCurPos.X := CharPos(DrawPtr, CurPtr);

  { Update selection }
  if not SelectText then
    SelStart := CurPtr;
  SelEnd := CurPtr;

  { Update undo info }
  if AllowUndo then
  begin
    Inc(FDelCount, DelLen);
    Inc(FInsCount, Length);
  end;

  { Update limits }
  Inc(FLimit.Y, Sw_Integer(Lines) - Sw_Integer(SelLines));
  if Sw_Integer(FCurPos.X) > FLimit.X then
    FLimit.X := FCurPos.X;

  Modified := True;
  Update(ufView);
end;

function TEditor.InsertFrom(Editor: TEditor): Boolean;
begin
  Result := InsertBuffer(Editor.Buffer, Editor.BufPtr(Editor.SelStart),
                         Editor.SelEnd - Editor.SelStart, CanUndo, IsClipboard);
end;

function TEditor.InsertText(Text: Pointer; Length: Sw_Word; SelectText: Boolean): Boolean;
begin
  Result := InsertBuffer(PEditBuffer(Text), 0, Length, CanUndo, SelectText);
end;

procedure TEditor.InsertUnicodeChar(C: Char);
var
  UTF8Bytes: TBytes;
begin
  UTF8Bytes := TEncoding.UTF8.GetBytes(C);
  InsertText(@UTF8Bytes[0], System.Length(UTF8Bytes), False);
end;

procedure TEditor.InsertUnicodeStr(const S: string);
var
  UTF8Bytes: TBytes;
begin
  if S = '' then Exit;
  UTF8Bytes := TEncoding.UTF8.GetBytes(S);
  InsertText(@UTF8Bytes[0], System.Length(UTF8Bytes), False);
end;

function TEditor.IsClipboard: Boolean;
begin
  Result := Clipboard = Self;
end;

procedure TEditor.Jump_FPlace_Marker(Element: Byte; Select_Mode: Byte);
begin
  if (Element >= 0) and (Element <= 9) then
    if FPlace_Marker[Element + 1] <= BufLen then
      SetCurPtr(FPlace_Marker[Element + 1], Select_Mode);
end;

procedure TEditor.Jump_To_Line(Select_Mode: Byte);
var
  P: Sw_Word;
  LineNum: LongInt;
  Code: Integer;
begin
  if EditorDialog(edJumpToLine, @FLine_Number) <> cmCancel then
  begin
    Val(FLine_Number, LineNum, Code);
    if Code = 0 then
    begin
      Dec(LineNum);
      P := 0;
      while (LineNum > 0) and (P < BufLen) do
      begin
        P := NextLine(P);
        Dec(LineNum);
      end;
      SetCurPtr(P, Select_Mode);
    end;
  end;
end;

function TEditor.LineEnd(P: Sw_Word): Sw_Word;
begin
  while (P < BufLen) and not ((BufChar(P) = #10) or (BufChar(P) = #13)) do
    Inc(P, BufCharLen(P));
  Result := P;
end;

function TEditor.LineMove(P: Sw_Word; Count: Sw_Integer): Sw_Word;
var
  Pos: Sw_Integer;
  I: Sw_Word;
begin
  Pos := CharPos(LineStart(P), P);
  while Count <> 0 do
  begin
    I := P;
    if Count < 0 then
    begin
      P := PrevLine(P);
      Inc(Count);
    end
    else
    begin
      P := NextLine(P);
      Dec(Count);
    end;
    if P = I then
      Break;
  end;
  Result := CharPtr(P, Pos);
end;

function TEditor.LineNr(P: Sw_Word): Sw_Word;
var
  Count: Sw_Word;
begin
  Count := 0;
  while P > 0 do
  begin
    P := PrevLine(P);
    Inc(Count);
  end;
  Result := Count;
end;

function TEditor.LineStart(P: Sw_Word): Sw_Word;
begin
  while (P > 0) and not ((BufChar(P - 1) = #10) or (BufChar(P - 1) = #13)) do
    Dec(P);
  Result := P;
end;

procedure TEditor.Lock;
begin
  Inc(FLockCount);
end;

function TEditor.NewLine(Select_Mode: Byte): Boolean;
begin
  Remove_EOL_Spaces(Select_Mode);
  Result := InsertText(@LineBreak[1], Length(LineBreak), False);
end;

function TEditor.NextChar(P: Sw_Word): Sw_Word;
var
  CharLen: Integer;
begin
  if P < BufLen then
  begin
    { Get UTF-8 character length and advance by that many bytes }
    CharLen := BufCharLen(P);
    if CharLen < 1 then
      CharLen := 1;  { Safety: always advance at least 1 byte }
    Inc(P, CharLen);
    { Handle CRLF as single line ending }
    if (P < BufLen) and (BufByte(P - 1) = 13) and (BufByte(P) = 10) then
      Inc(P);
  end;
  Result := P;
end;

function TEditor.NextLine(P: Sw_Word): Sw_Word;
begin
  Result := NextChar(LineEnd(P));
end;

function TEditor.NextWord(P: Sw_Word): Sw_Word;
var
  CharLen: Integer;
begin
  { Skip word characters }
  while (P < BufLen) and IsWordChar(BufChar(P)) do
  begin
    CharLen := BufCharLen(P);
    if CharLen < 1 then CharLen := 1;
    Inc(P, CharLen);
  end;
  { Skip non-word characters }
  while (P < BufLen) and not IsWordChar(BufChar(P)) do
  begin
    CharLen := BufCharLen(P);
    if CharLen < 1 then CharLen := 1;
    Inc(P, CharLen);
  end;
  Result := P;
end;

function TEditor.PrevChar(P: Sw_Word): Sw_Word;
begin
  if P > 0 then
  begin
    Dec(P);
    { Handle CRLF as single line ending }
    if (P > 0) and (BufByte(P) = 10) and (BufByte(P - 1) = 13) then
      Dec(P);
    { Scan backwards past UTF-8 trail bytes to find lead byte }
    while (P > 0) and IsUTF8TrailByte(BufByte(P)) do
      Dec(P);
  end;
  Result := P;
end;

function TEditor.PrevLine(P: Sw_Word): Sw_Word;
begin
  Result := LineStart(PrevChar(LineStart(P)));
end;

function TEditor.PrevWord(P: Sw_Word): Sw_Word;
var
  PrevP: Sw_Word;
begin
  { Skip non-word characters going backwards }
  while P > 0 do
  begin
    PrevP := PrevChar(P);
    if IsWordChar(BufChar(PrevP)) then
      Break;
    P := PrevP;
  end;
  { Skip word characters going backwards }
  while P > 0 do
  begin
    PrevP := PrevChar(P);
    if not IsWordChar(BufChar(PrevP)) then
      Break;
    P := PrevP;
  end;
  Result := P;
end;

procedure TEditor.Reformat_Document(Select_Mode: Byte; Center_Cursor: Boolean);
var
  Choice: Word;
  OldPtr: Sw_Word;
begin
  if not Word_Wrap then
  begin
    if not Allow_Reformat then
    begin
      EditorDialog(edReformatNotAllowed, nil);
      Exit;
    end;
  end;
  Choice := 0;
  if EditorDialog(edReformatDocument, @Choice) = cmCancel then
    Exit;
  OldPtr := CurPtr;
  if Choice = 1 then
    SetCurPtr(0, Select_Mode);

  while CurPtr < BufLen do
  begin
    if not Reformat_Paragraph(Select_Mode, Center_Cursor) then
      Break;
    SetCurPtr(NextLine(CurPtr), Select_Mode);
  end;

  SetCurPtr(OldPtr, Select_Mode);
end;

function TEditor.Reformat_Paragraph(Select_Mode: Byte; Center_Cursor: Boolean): Boolean;
begin
  Result := True;
  if FCurPos.X > Right_Margin then
    Result := Do_Word_Wrap(Select_Mode, Center_Cursor);
end;

procedure TEditor.Remove_EOL_Spaces(Select_Mode: Byte);
var
  E: Sw_Word;
begin
  E := LineEnd(CurPtr);
  while (E > LineStart(CurPtr)) and (BufChar(E - 1) = ' ') do
    Dec(E);
  if CurPtr > E then
    SetCurPtr(E, Select_Mode);
  if E < LineEnd(E) then
    DeleteRange(E, LineEnd(E), False);
end;

procedure TEditor.Replace;
var
  ReplaceRec: TReplaceDialogRec;
begin
  ReplaceRec.Find := FindStr;
  ReplaceRec.Replace := ReplaceStr;
  ReplaceRec.Options := Flags;
  if EditorDialog(edReplace, @ReplaceRec) <> cmCancel then
  begin
    FindStr := ReplaceRec.Find;
    ReplaceStr := ReplaceRec.Replace;
    Flags := ReplaceRec.Options or efDoReplace;
    DoSearchReplace;
  end;
end;

procedure TEditor.Scroll_Down;
begin
  ScrollTo(FDelta.X, FDelta.Y + 1);
end;

procedure TEditor.Scroll_Up;
begin
  ScrollTo(FDelta.X, FDelta.Y - 1);
end;

procedure TEditor.ScrollTo(X, Y: Sw_Integer);
begin
  X := Max(0, Min(X, FLimit.X - Size.X));
  Y := Max(0, Min(Y, FLimit.Y - Size.Y));
  if (X <> FDelta.X) or (Y <> FDelta.Y) then
  begin
    FDelta.X := X;
    FDelta.Y := Y;
    Update(ufView);
  end;
end;

function TEditor.Search(const FindStr: String; Opts: Word): Boolean;
var
  I: Sw_Word;
  Pos: Sw_Word;
begin
  Result := False;
  if Length(FindStr) = 0 then
    Exit;

  Pos := CurPtr;
  repeat
    if Opts and efCaseSensitive <> 0 then
    begin
      if Pos < BufLen then
        I := Scan(Buffer^[BufPtr(Pos)], BufLen - Pos, FindStr)
      else
        I := NotFoundValue;
    end
    else
    begin
      if Pos < BufLen then
        I := IScan(Buffer^[BufPtr(Pos)], BufLen - Pos, FindStr)
      else
        I := NotFoundValue;
    end;

    if I <> NotFoundValue then
    begin
      Inc(I, Pos);
      { Check for whole words only if option is set }
      if (Opts and efWholeWordsOnly = 0) or
         not (((I <> 0) and IsWordChar(BufChar(I - 1))) or
              ((I + Sw_Word(Length(FindStr)) <> BufLen) and
               IsWordChar(BufChar(I + Sw_Word(Length(FindStr)))))) then
      begin
        Lock;
        SetSelect(I, I + Sw_Word(Length(FindStr)), False);
        TrackCursor(not CursorVisible);
        Unlock;
        Result := True;
        Exit;
      end
      else
        Pos := I + 1;
    end;
  until I = NotFoundValue;
end;

procedure TEditor.Select_Word;
var
  S, E: Sw_Word;
begin
  S := CurPtr;
  while (S > 0) and IsWordChar(BufChar(S - 1)) do
    Dec(S);
  E := CurPtr;
  while (E < BufLen) and IsWordChar(BufChar(E)) do
    Inc(E, BufCharLen(E));
  SetSelect(S, E, False);
end;

function TEditor.SetBufSize(NewSize: Sw_Word): Boolean;
begin
  Result := True;
end;

procedure TEditor.SetBufLen(Length: Sw_Word);
begin
  BufLen := Length;
  GapLen := BufSize - BufLen;
  SelStart := 0;
  SelEnd := 0;
  CurPtr := 0;
  FCurPos.X := 0;
  FCurPos.Y := 0;
  FDelta.X := 0;
  FDelta.Y := 0;
  FLimit.X := MaxLineLength;
  FLimit.Y := 1;
  if Assigned(Buffer) and (BufLen > 0) then
    GetLimits(Buffer^[GapLen], BufLen, FLimit);
  Inc(FLimit.Y);
  DrawLine := 0;
  DrawPtr := 0;
  DelCount := 0;
  InsCount := 0;
  Modified := False;
  Update(ufView);
end;

procedure TEditor.SetCmdState(Command: Word; Enable: Boolean);
begin
  if State and sfActive <> 0 then
  begin
    if Enable then
      EnableCommands([Command])
    else
      DisableCommands([Command]);
  end;
end;

procedure TEditor.SetCurPtr(P: Sw_Word; SelectMode: Byte);
var
  Anchor: Sw_Word;
begin
  if SelectMode and smExtend = 0 then
    Anchor := P
  else if CurPtr = SelStart then
    Anchor := SelEnd
  else
    Anchor := SelStart;

  if P < Anchor then
  begin
    if SelectMode and smDouble <> 0 then
    begin
      P := PrevLine(NextLine(P));
      Anchor := NextLine(PrevLine(Anchor));
    end;
    SetSelect(P, Anchor, True);
  end
  else
  begin
    if SelectMode and smDouble <> 0 then
    begin
      P := NextLine(P);
      Anchor := PrevLine(NextLine(Anchor));
    end;
    SetSelect(Anchor, P, False);
  end;
end;

procedure TEditor.SetSelect(NewStart, NewEnd: Sw_Word; CurStart: Boolean);
var
  P: Sw_Word;
  L: Sw_Word;
  UFlags: Byte;
begin
  if CurStart then
    P := NewStart
  else
    P := NewEnd;

  UFlags := ufUpdate;
  if (NewStart <> SelStart) or (NewEnd <> SelEnd) then
    if (NewStart <> NewEnd) or (SelStart <> SelEnd) then
      UFlags := ufView;

  if P <> CurPtr then
  begin
    if P > CurPtr then
    begin
      { Moving forward: Move first, then count lines in destination }
      L := P - CurPtr;
      Move(Buffer^[CurPtr + GapLen], Buffer^[CurPtr], L);
      Inc(FCurPos.Y, CountLines(Buffer^[CurPtr], L));
      CurPtr := P;
    end
    else
    begin
      { Moving backward: Set CurPtr first, count lines, then Move }
      { This order is critical - count lines BEFORE the Move corrupts the source }
      L := CurPtr - P;
      CurPtr := P;
      Dec(FCurPos.Y, CountLines(Buffer^[CurPtr], L));
      Move(Buffer^[CurPtr], Buffer^[CurPtr + GapLen], L);
    end;
    DrawLine := FCurPos.Y;
    DrawPtr := LineStart(CurPtr);
    FCurPos.X := CharPos(DrawPtr, CurPtr);
    { Reset undo state when cursor moves }
    DelCount := 0;
    InsCount := 0;
    SetBufSize(BufLen);
  end;
  SelStart := NewStart;
  SelEnd := NewEnd;
  Update(UFlags);
end;

procedure TEditor.Set_FPlace_Marker(Element: Byte);
begin
  if (Element >= 0) and (Element <= 9) then
    FPlace_Marker[Element + 1] := CurPtr;
end;

procedure TEditor.Set_Right_Margin;
var
  MarginRec: TRightMarginRec;
  Code: Integer;
  NewMargin: Integer;
begin
  Str(Right_Margin, MarginRec.Margin_Position);
  if EditorDialog(edRightMargin, @MarginRec) <> cmCancel then
  begin
    Val(MarginRec.Margin_Position, NewMargin, Code);
    if Code = 0 then
      Right_Margin := NewMargin;
  end;
end;

procedure TEditor.Set_Tabs;
var
  TabRec: TTabStopRec;
begin
  TabRec.Tab_String := FTab_Settings;
  if EditorDialog(edSetTabStops, @TabRec) <> cmCancel then
    FTab_Settings := TabRec.Tab_String;
end;

procedure TEditor.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  case AState of
    sfActive:
      begin
        if Assigned(HScrollBar) then
          HScrollBar.SetState(sfVisible, Enable);
        if Assigned(VScrollBar) then
          VScrollBar.SetState(sfVisible, Enable);
        if Assigned(Indicator) then
          Indicator.SetState(sfVisible, Enable);
        UpdateCommands;
      end;
    sfExposed:
      if Enable then
        Unlock;
  end;
end;

procedure TEditor.StartSelect;
begin
  HideSelect;
  Selecting := True;
end;

procedure TEditor.Tab_Key(Select_Mode: Byte);
var
  I: Integer;
begin
  if Overwrite then
    SetCurPtr(NextChar(CurPtr), Select_Mode)
  else
  begin
    I := TabSize - (FCurPos.X mod TabSize);
    if I = 0 then
      I := TabSize;
    InsertText(@'        '[1], I, False);
  end;
end;

procedure TEditor.ToggleInsMode;
begin
  Overwrite := not Overwrite;
  SetState(sfCursorIns, Overwrite);
end;

procedure TEditor.TrackCursor(Center: Boolean);
begin
  if Center then
    ScrollTo(FCurPos.X - Size.X div 2, FCurPos.Y - Size.Y div 2)
  else
    ScrollTo(Max(FCurPos.X - Size.X + 1, Min(FDelta.X, FCurPos.X)),
             Max(FCurPos.Y - Size.Y + 1, Min(FDelta.Y, FCurPos.Y)));
end;

procedure TEditor.Undo;
begin
  if (DelCount > 0) or (InsCount > 0) then
  begin
    SetSelect(CurPtr - InsCount, CurPtr, True);
    InsertBuffer(Buffer, CurPtr + GapLen - DelCount, DelCount, False, True);
    DelCount := 0;
    InsCount := 0;
  end;
end;

procedure TEditor.Unlock;
begin
  if FLockCount > 0 then
  begin
    Dec(FLockCount);
    if FLockCount = 0 then
      DoUpdate;
  end;
end;

procedure TEditor.Update(AFlags: Byte);
begin
  FUpdateFlags := FUpdateFlags or AFlags;
  if FLockCount = 0 then
    DoUpdate;
end;

procedure TEditor.UpdateCommands;
begin
  SetCmdState(cmUndo, (DelCount > 0) or (InsCount > 0));
  if not IsClipboard then
  begin
    SetCmdState(cmCut, HasSelection);
    SetCmdState(cmCopy, HasSelection);
    SetCmdState(cmPaste, Assigned(Clipboard) and (Clipboard.HasSelection));
  end;
  SetCmdState(cmClear, HasSelection);
  SetCmdState(cmFind, True);
  SetCmdState(cmReplace, True);
  SetCmdState(cmSearchAgain, True);
end;

procedure TEditor.Update_FPlace_Markers(AddCount: Word; KillCount: Word;
                                       StartPtr, EndPtr: Sw_Word);
var
  Element: Byte;
begin
  for Element := 1 to 10 do
  begin
    if FPlace_Marker[Element] >= StartPtr then
    begin
      if FPlace_Marker[Element] <= EndPtr then
        FPlace_Marker[Element] := StartPtr
      else
        FPlace_Marker[Element] := FPlace_Marker[Element] + AddCount - KillCount;
    end;
  end;
end;

function TEditor.Valid(Command: Word): Boolean;
begin
  Result := IsValid;
end;

{****************************************************************************
                                   TMemo
****************************************************************************}

function TMemo.DataSize: Word;
begin
  Result := BufSize + SizeOf(Sw_Word);
end;

procedure TMemo.GetData(var Rec);
var
  Data: TMemoData absolute Rec;
begin
  Data.Length := BufLen;
  Move(Buffer^, Data.Buffer, CurPtr);
  Move(Buffer^[CurPtr + GapLen], Data.Buffer[CurPtr], BufLen - CurPtr);
  FillChar(Data.Buffer[BufLen], BufSize - BufLen, 0);
end;

function TMemo.GetPalette: PPalette;
const
  P: String[Length(CMemo)] = CMemo;
begin
  Result := PPalette(@P);
end;

procedure TMemo.HandleEvent(var Event: TEvent);
begin
  if (Event.What <> evKeyDown) or (Event.KeyCode <> kbTab) then
    inherited HandleEvent(Event);
end;

procedure TMemo.SetData(var Rec);
var
  Data: TMemoData absolute Rec;
begin
  Move(Data.Buffer, Buffer^[BufSize - Data.Length], Data.Length);
  SetBufLen(Data.Length);
end;

{****************************************************************************
                               TFileEditor
****************************************************************************}

constructor TFileEditor.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
                             AIndicator: TIndicator; AFileName: FNameStr);
begin
  inherited Create(Bounds, AHScrollBar, AVScrollBar, AIndicator, 0);
  if AFileName <> '' then
  begin
    FFileName := FExpand(AFileName);
    if IsValid then
      FIsValid := LoadFile;
  end;
end;

procedure TFileEditor.DoneBuffer;
begin
  ReallocMem(FBuffer, 0);
end;

procedure TFileEditor.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  case Event.What of
    evCommand:
      case Event.Command of
        cmSave: Save;
        cmSaveAs: SaveAs;
        cmSaveDone:
          if Save then
            Message(Owner, evCommand, cmClose, nil);
      else
        Exit;
      end;
  else
    Exit;
  end;
  ClearEvent(Event);
end;

procedure TFileEditor.InitBuffer;
begin
  Assert(Buffer = nil, 'TFileEditor.InitBuffer: Buffer is not nil');
  ReallocMem(FBuffer, MinBufLength);
  BufSize := MinBufLength;
end;

function TFileEditor.LoadFile: Boolean;
var
  FLength: Sw_Word;
  FSize: LongInt;
  FRead: Integer;
  F: File;
  RawData: TBytes;
  UTF8Data: TBytes;
  Encoding: TFileEncoding;
  BOMLen: Integer;
begin
  Result := False;
  FLength := 0;
  FHadBOM := False;

  AssignFile(F, FileName);
  {$I-}
  Reset(F, 1);
  {$I+}
  if IOResult <> 0 then
    EditorDialog(edReadError, @FileName)
  else
  begin
    FSize := FileSize(F);
    if FSize > MaxBufLength then
      EditorDialog(edOutOfMemory, nil)
    else if FSize = 0 then
    begin
      { Empty file - nothing to load }
      Result := True;
      CloseFile(F);
      SetBufLen(0);
      Exit;
    end
    else
    begin
      { Read raw file data }
      SetLength(RawData, FSize);
      {$I-}
      BlockRead(F, RawData[0], FSize, FRead);
      {$I+}
      if (IOResult <> 0) or (FRead <> FSize) then
        EditorDialog(edReadError, @FileName)
      else
      begin
        { Detect encoding and convert to UTF-8 }
        Encoding := DetectEncoding(RawData, FSize);
        FHadBOM := Encoding in [feUTF8BOM, feUTF16LE, feUTF16BE];

        if Encoding in [feUTF8, feUTF8BOM] then
        begin
          { Already UTF-8, just strip BOM if present }
          BOMLen := GetBOMLength(Encoding);
          if BOMLen > 0 then
          begin
            SetLength(UTF8Data, FSize - BOMLen);
            if Length(UTF8Data) > 0 then
              Move(RawData[BOMLen], UTF8Data[0], Length(UTF8Data));
          end
          else
            UTF8Data := RawData;
        end
        else
          { Convert from other encoding to UTF-8 }
          UTF8Data := ConvertToUTF8(RawData, Encoding);

        { Allocate buffer and copy data }
        FLength := Length(UTF8Data);
        if (FLength > MaxBufLength) or not SetBufSize(FLength) then
          EditorDialog(edOutOfMemory, nil)
        else
        begin
          if FLength > 0 then
            Move(UTF8Data[0], Buffer^[BufSize - FLength], FLength);
          Result := True;
        end;
      end;
    end;
    CloseFile(F);
  end;
  SetBufLen(FLength);
end;

function TFileEditor.Save: Boolean;
begin
  if FileName = '' then
    Result := SaveAs
  else
    Result := SaveFile;
end;

function TFileEditor.SaveAs: Boolean;
begin
  Result := False;
  if EditorDialog(edSaveAs, @FileName) <> cmCancel then
  begin
    FileName := FExpand(FileName);
    Message(Owner, evBroadcast, cmUpdateTitle, nil);
    Result := SaveFile;
    if IsClipboard then
      FileName := '';
  end;
end;

function TFileEditor.SaveFile: Boolean;
const
  UTF8BOM: array[0..2] of Byte = ($EF, $BB, $BF);
var
  F: File;
  BackupName: FNameStr;
  D: DirStr;
  N: NameStr;
  E: ExtStr;
  WriteError: Boolean;
begin
  Result := False;
  if Flags and efBackupFiles <> 0 then
  begin
    FSplit(FileName, D, N, E);
    BackupName := D + N + '.bak';
    {$I-}
    AssignFile(F, BackupName);
    Erase(F);
    AssignFile(F, FileName);
    Rename(F, BackupName);
    {$I+}
    IOResult;  { Clear any errors }
  end;
  AssignFile(F, FileName);
  {$I-}
  Rewrite(F, 1);
  {$I+}
  if IOResult <> 0 then
    EditorDialog(edCreateError, @FileName)
  else
  begin
    WriteError := False;
    {$I-}
    { Write UTF-8 BOM if original file had one }
    if FHadBOM then
    begin
      BlockWrite(F, UTF8BOM, 3);
      if IOResult <> 0 then
        WriteError := True;
    end;
    { Write buffer contents (already UTF-8) }
    if not WriteError then
    begin
      BlockWrite(F, Buffer^, CurPtr);
      if IOResult <> 0 then
        WriteError := True;
    end;
    if not WriteError then
    begin
      BlockWrite(F, Buffer^[CurPtr + GapLen], BufLen - CurPtr);
      if IOResult <> 0 then
        WriteError := True;
    end;
    {$I+}
    if WriteError then
      EditorDialog(edWriteError, @FileName)
    else
    begin
      Modified := False;
      Update(ufUpdate);
      Result := True;
    end;
    CloseFile(F);
  end;
end;

function TFileEditor.SetBufSize(NewSize: Sw_Word): Boolean;
var
  N: Sw_Word;
begin
  Result := False;
  if NewSize = 0 then
    NewSize := MinBufLength
  else if NewSize > (MaxBufLength - MinBufLength) then
    NewSize := MaxBufLength
  else
    NewSize := (NewSize + (MinBufLength - 1)) and (MaxBufLength and (not (MinBufLength - 1)));

  if NewSize <> BufSize then
  begin
    if NewSize > BufSize then
      ReallocMem(FBuffer, NewSize);
    N := BufLen - CurPtr + DelCount;
    Move(Buffer^[BufSize - N], Buffer^[NewSize - N], N);
    if NewSize < BufSize then
      ReallocMem(FBuffer, NewSize);
    BufSize := NewSize;
    GapLen := BufSize - BufLen;
  end;
  Result := True;
end;

procedure TFileEditor.UpdateCommands;
begin
  inherited UpdateCommands;
  SetCmdState(cmSave, True);
  SetCmdState(cmSaveAs, True);
  SetCmdState(cmSaveDone, True);
end;

function TFileEditor.Valid(Command: Word): Boolean;
var
  D: SmallInt;
begin
  if Command = cmValid then
    Result := IsValid
  else
  begin
    Result := True;
    if Modified then
    begin
      if FileName = '' then
        D := edSaveUntitled
      else
        D := edSaveModify;
      case EditorDialog(D, @FileName) of
        cmYes: Result := Save;
        cmNo: Modified := False;
        cmCancel: Result := False;
      end;
    end;
  end;
end;

{****************************************************************************
                             TEditWindow
****************************************************************************}

constructor TEditWindow.Create(var Bounds: TRect; AFileName: FNameStr; ANumber: SmallInt);
var
  AHScrollBar: TScrollBar;
  AVScrollBar: TScrollBar;
  AIndicator: TIndicator;
  R: TRect;
begin
  inherited Create(Bounds, '', ANumber);
  Options := Options or ofTileable;

  R.Assign(18, Size.Y - 1, Size.X - 2, Size.Y);
  AHScrollBar := TScrollBar.Create(R);
  AHScrollBar.Hide;
  Insert(AHScrollBar);

  R.Assign(Size.X - 1, 1, Size.X, Size.Y - 1);
  AVScrollBar := TScrollBar.Create(R);
  AVScrollBar.Hide;
  Insert(AVScrollBar);

  R.Assign(2, Size.Y - 1, 16, Size.Y);
  AIndicator := TIndicator.Create(R);
  AIndicator.Hide;
  Insert(AIndicator);

  GetExtent(R);
  R.Grow(-1, -1);
  FEditor := TFileEditor.Create(R, AHScrollBar, AVScrollBar, AIndicator, AFileName);
  Insert(FEditor);
end;

procedure TEditWindow.Close;
begin
  if FEditor.IsClipboard then
    Hide
  else
    inherited Close;
end;

function TEditWindow.GetTitle(MaxSize: Sw_Integer): TTitleStr;
begin
  if FEditor.IsClipboard then
    Result := sClipboard
  else if FEditor.FileName = '' then
    Result := sUntitled
  else
    Result := FEditor.FileName;
end;

procedure TEditWindow.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if Event.What = evBroadcast then
    case Event.Command of
      cmUpdateTitle:
        begin
          Frame.DrawView;
          ClearEvent(Event);
        end;
      cmBludgeonStats:
        begin
          FEditor.Update(ufStats);
          ClearEvent(Event);
        end;
    end;
end;

procedure TEditWindow.SizeLimits(var Min, Max: TPoint);
begin
  inherited SizeLimits(Min, Max);
  Min.X := 23;
end;

end.
