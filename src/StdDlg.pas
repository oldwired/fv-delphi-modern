{*******************************************************}
{       Free Vision - Standard Dialogs Unit             }
{       Ported to Modern Delphi                         }
{       Converted to CLASS syntax                       }
{*******************************************************}

unit StdDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults,
  FVConsts, Objects, FVCommon, Drivers, Views, Dialogs, Validate, FVBoxChars, Outline;

const
  MaxDir   = 255;
  MaxFName = 255;

  DirSeparator: Char = '\';
  AllFiles = '*.*';

type
  { TSearchRec - Our own record for file information }
  TSearchRec = record
    Attr: LongInt;
    Time: LongInt;
    Size: LongInt;
    Name: string;
  end;
  PSearchRec = ^TSearchRec;

  { TFileInputLine }
  TFileInputLine = class(TInputLine)
    constructor Create(var Bounds: TRect; AMaxLen: Integer); override;
    procedure HandleEvent(var Event: TEvent); override;
  end;

  { TFileCollection - type-safe sorted list of file records }
  TFileCollection = class(TList<PSearchRec>)
  public
    destructor Destroy; override;
    procedure ClearAll;
    function Compare(Key1, Key2: PSearchRec): Integer;
    procedure InsertSorted(Item: PSearchRec);
    function Search(Key: PSearchRec; var Index: Integer): Boolean;
  end;

  { TFileValidator }
  TFileValidator = class(TValidator)
  end;

  { TSortedListBox }
  TSortedListBox = class(TListBox)
    SearchPos: Byte;
    HandleDir: Boolean;
    constructor Create(var Bounds: TRect; ANumCols: Word; AScrollBar: TScrollBar); override;
    procedure HandleEvent(var Event: TEvent); override;
    function GetKey(var S: string): Pointer; virtual;
    procedure NewList(AList: TObjectList<TObject>); override;
  end;

  { Forward declarations for TFileDialog }
  TFileDialog = class;
  TFileHistory = class;
  TFileList = class;

  { TFileList }
  TFileList = class(TSortedListBox)
    Files: TFileCollection;  { Type-safe file collection }
    constructor Create(var Bounds: TRect; AScrollBar: TScrollBar); reintroduce; virtual;
    destructor Destroy; override;
    function DataSize: Word; override;
    procedure FocusItem(Item: Integer); override;
    procedure GetData(var Rec); override;
    function GetText(Item: Integer; MaxLen: Integer): string; override;
    function GetKey(var S: string): Pointer; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure ReadDirectory(AWildCard: PathStr);
    procedure SetData(var Rec); override;
  end;

  { TFileInfoPane }
  TFileInfoPane = class(TView)
    S: TSearchRec;
    constructor Create(var Bounds: TRect); override;
    destructor Destroy; override;
    procedure Draw; override;
    function GetPalette: PPalette; override;
    procedure HandleEvent(var Event: TEvent); override;
  end;

  { TFileDialog constants }
  TWildStr = PathStr;

  { TFileHistory }
  TFileHistory = class(THistory)
    CurDir: string;
    constructor Create(var Bounds: TRect; ALink: TInputLine; AHistoryId: Word); override;
    procedure HandleEvent(var Event: TEvent); override;
    destructor Destroy; override;
    procedure AdaptHistoryToDir(Dir: string);
  end;

  { TFileDialog }
  TFileDialog = class(TDialog)
    FileName: TFileInputLine;
    FileList: TFileList;
    FileHistory: TFileHistory;
    WildCard: TWildStr;
    Directory: string;
    constructor Create(AWildCard: TWildStr; const ATitle, InputName: String;
      AOptions: Word; HistoryId: Byte); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    destructor Destroy; override;
    procedure GetData(var Rec); override;
    procedure GetFileName(var S: PathStr);
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetData(var Rec); override;
    procedure Store(var S: TFVStream);
    function Valid(Command: Word): Boolean; override;
  private
    procedure ReadDirectory;
  end;

  { TDirNode - Tree node for directory outline }
  PDirNode = ^TDirNode;
  TDirNode = record
    Next: PDirNode;           { Next sibling }
    Text: string;             { Display name (directory name or drive letter) }
    ChildList: PDirNode;      { First child }
    Expanded: Boolean;        { Is node expanded }
    FullPath: string;         { Full path to this directory }
    ChildrenLoaded: Boolean;  { Have children been loaded from filesystem }
    IsDrive: Boolean;         { Is this a drive node }
  end;

  { TDirOutline - Directory tree using TOutlineViewer with lazy loading }
  TDirOutline = class(TOutlineViewer)
  private
    FRoot: PDirNode;
    FDir: DirStr;
    FDrivesNode: PDirNode;    { Special "Drives" root node }
    FActivePath: string;      { Currently active/highlighted path }
    procedure LoadChildren(Node: PDirNode);
    procedure ExpandToPath(const APath: string);
    function FindNodeByPath(const APath: string): PDirNode;
    function FindNodePosition(TargetNode: PDirNode): Sw_Integer;
    procedure FreeNode(Node: PDirNode);
    procedure BuildDriveNodes;
  public
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar); reintroduce; virtual;
    destructor Destroy; override;
    procedure Adjust(Node: Pointer; Expand: Boolean); override;
    function GetChild(Node: Pointer; I: Sw_Integer): Pointer; override;
    function GetNumChildren(Node: Pointer): Sw_Integer; override;
    function GetRoot: Pointer; override;
    function GetText(Node: Pointer): string; override;
    function GetPalette: PPalette; override;
    function HasChildren(Node: Pointer): Boolean; override;
    function IsExpanded(Node: Pointer): Boolean; override;
    function IsSelected(I: Sw_Integer): Boolean; override;
    procedure Focused(I: Sw_Integer); override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure NewDirectory(var ADir: DirStr);
    function GetSelectedPath: string;
    procedure SetActivePath(const APath: string);
    property Dir: DirStr read FDir;
    property ActivePath: string read FActivePath write SetActivePath;
  end;

const
  cdNormal     = $0000;
  cdNoLoadDir  = $0001;
  cdHelpButton = $0002;

type
  { TChDirDialog }
  TChDirDialog = class(TDialog)
    DirInput: TInputLine;
    DirList: TDirOutline;
    OkButton: TButton;
    ChDirButton: TButton;
    constructor Create(AOptions: Word; HistoryId: Word); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    function DataSize: Word; override;
    procedure GetData(var Rec); override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetData(var Rec); override;
    procedure Store(var S: TFVStream);
    function Valid(Command: Word): Boolean; override;
  private
    procedure SetUpDialog;
  end;

  { TEditChDirDialog }
  TEditChDirDialog = class(TChDirDialog)
    function DataSize: Word; override;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
  end;

  { TFolderSelectDialog - Dialog for selecting a folder to use elsewhere
    Similar to TChDirDialog but does not change current directory.
    Returns the selected folder path via GetData. }
  TFolderSelectDialog = class(TDialog)
    DirInput: TInputLine;
    DirList: TDirOutline;
    SelectButton: TButton;
    constructor Create(AOptions: Word; HistoryId: Word); reintroduce; virtual;
    function DataSize: Word; override;
    procedure GetData(var Rec); override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetData(var Rec); override;
    function Valid(Command: Word): Boolean; override;
  private
    procedure SetUpDialog;
  end;

  { TModernFileDialog - Split-pane file dialog with directory tree }
  TModernFileDialog = class(TDialog)
    DirTree: TDirOutline;       { Left pane - directory tree }
    FileList: TFileList;        { Right pane - file list }
    FileName: TFileInputLine;   { Filename input }
    InfoPane: TFileInfoPane;    { File info display }
    WildCard: TWildStr;         { File filter pattern }
    Directory: string;          { Current directory }
    FOptions: Word;             { fdOkButton / fdOpenButton / fdReplaceButton }
    constructor Create(AWildCard: TWildStr; const ATitle: string;
      AOptions: Word; AHistoryId: Byte); reintroduce; virtual;
    destructor Destroy; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure GetFileName(var S: PathStr);
    function Valid(Command: Word): Boolean; override;
  private
    procedure ReadDirectory;
    procedure SyncTreeToList;
  end;

  { TDirValidator }
  TDirValidator = class(TFilterValidator)
    constructor Create; reintroduce; virtual;
    function IsValid(const S: string): Boolean; override;
    function IsValidInput(var S: string; SuppressFill: Boolean): Boolean; override;
  end;

  FileConfirmFunc = function(AFile: FNameStr): Boolean;

var
  ReplaceFile: FileConfirmFunc;
  DeleteFile: FileConfirmFunc;

const
  { TFileDialog options }
  fdOkButton      = $0001;
  fdOpenButton    = $0002;
  fdReplaceButton = $0004;
  fdClearButton   = $0008;
  fdHelpButton    = $0010;
  fdNoLoadDir     = $0100;

  CInfoPane = #30;
  CheckOnReplace: Boolean = True;
  CheckOnDelete: Boolean = True;

{ Helper functions }
function Contains(S1, S2: String): Boolean;
function DriveValid(Drive: Char): Boolean;
function ExtractDir(AFile: FNameStr): DirStr;
function ExtractFileName(AFile: FNameStr): NameStr;
function Equal(const S1, S2: String; Count: Sw_Word): Boolean;
function FileExists(AFile: FNameStr): Boolean;
function GetCurDir: DirStr;
function GetCurDrive: Char;
function IsWild(const S: String): Boolean;
function IsList(const S: String): Boolean;
function IsDir(const S: String): Boolean;
function NoWildChars(S: String): String;
function OpenFile(var AFile: FNameStr; HistoryID: Byte): Boolean;
function OpenNewFile(var AFile: FNameStr; HistoryID: Byte): Boolean;
function PathValid(var Path: PathStr): Boolean;
procedure RegisterStdDlg;
function SaveAs(var AFile: FNameStr; HistoryID: Word): Boolean;
function SelectDir(var ADir: DirStr; HistoryID: Byte): Boolean;
function SelectFolder(var ADir: DirStr; HistoryID: Byte): Boolean;
function ShrinkPath(AFile: FNameStr; MaxLen: Byte): FNameStr;
function StdDeleteFile(AFile: FNameStr): Boolean;
function StdReplaceFile(AFile: FNameStr): Boolean;
function ValidFileName(var FileName: PathStr): Boolean;

{ DOS-compatible file functions }
function FExpand(const Path: PathStr): PathStr;
procedure FSplit(const Path: PathStr; var Dir: DirStr; var Name: NameStr; var Ext: ExtStr);

const
  RFileInputLine: TStreamRec = (
    ObjType: idFileInputLine;
    VmtLink: 0;
    Load: nil;
    Store: nil
  );

  RFileCollection: TStreamRec = (
    ObjType: idFileCollection;
    VmtLink: 0;
    Load: nil;
    Store: nil
  );

  RFileList: TStreamRec = (
    ObjType: idFileList;
    VmtLink: 0;
    Load: nil;
    Store: nil
  );

  RFileInfoPane: TStreamRec = (
    ObjType: idFileInfoPane;
    VmtLink: 0;
    Load: nil;
    Store: nil
  );

  RFileDialog: TStreamRec = (
    ObjType: idFileDialog;
    VmtLink: 0;
    Load: nil;
    Store: nil
  );

  RDirCollection: TStreamRec = (
    ObjType: idDirCollection;
    VmtLink: 0;
    Load: nil;
    Store: nil
  );

  RDirListBox: TStreamRec = (
    ObjType: idDirListBox;
    VmtLink: 0;
    Load: nil;
    Store: nil
  );

  RChDirDialog: TStreamRec = (
    ObjType: idChDirDialog;
    VmtLink: 0;
    Load: nil;
    Store: nil
  );

  RSortedListBox: TStreamRec = (
    ObjType: idSortedListBox;
    VmtLink: 0;
    Load: nil;
    Store: nil
  );

  REditChDirDialog: TStreamRec = (
    ObjType: idEditChDirDialog;
    VmtLink: 0;
    Load: nil;
    Store: nil
  );

implementation

uses
  App, HistList, MsgBox;

{ File attribute constants }
const
  faReadOnly  = $01;
  faHidden    = $02;
  faSysFile   = $04;
  faVolumeID  = $08;
  faDirectory = $10;
  faArchive   = $20;
  faAnyFile   = $3F;

  Directory = faDirectory;
  ReadOnly  = faReadOnly;
  Archive   = faArchive;
  Hidden    = faHidden;

  ListSeparator = ';';

resourcestring
  sChangeDirectory = 'Change Directory';
  sSelectFolder = 'Select Folder';
  sDeleteFile = 'Delete file?'#13#10#13#3'%s';
  sDirectory = 'Directory';
  sDrives = 'Drives';
  sInvalidDirectory = 'Invalid directory.';
  sInvalidDriveOrDir = 'Invalid drive or directory.';
  sInvalidFileName = 'Invalid file name.';
  sOpen = 'Open';
  sReplaceFile = 'Replace file?'#13#10#13#3'%s';
  sSaveAs = 'Save As';
  sTooManyFiles = 'Too many files.';

  smApr = 'Apr';
  smAug = 'Aug';
  smDec = 'Dec';
  smFeb = 'Feb';
  smJan = 'Jan';
  smJul = 'Jul';
  smJun = 'Jun';
  smMar = 'Mar';
  smMay = 'May';
  smNov = 'Nov';
  smOct = 'Oct';
  smSep = 'Sep';

  slCancel = 'Cancel';
  slChDir = '~C~hdir';
  slClear = 'C~l~ear';
  slDirectoryName = 'Directory ~n~ame';
  slDirectoryTree = 'Directory ~t~ree';
  slFiles = '~F~iles';
  slName = '~N~ame';
  slOk = '~O~K';
  slOpen = '~O~pen';
  slSelect = '~S~elect';
  slReplace = '~R~eplace';
  slRevert = '~R~evert';
  slSaveAs = 'Save ~a~s';

var
  DosError: Integer;
  SysSearchRec: System.SysUtils.TSearchRec;

{ DOS-compatible helper functions }

function FExpand(const Path: PathStr): PathStr;
begin
  Result := System.SysUtils.ExpandFileName(string(Path));
end;

procedure FSplit(const Path: PathStr; var Dir: DirStr; var Name: NameStr; var Ext: ExtStr);
var
  I: Integer;
  S: string;
begin
  S := string(Path);
  Dir := System.SysUtils.ExtractFilePath(S);
  Name := System.SysUtils.ExtractFileName(S);
  Ext := System.SysUtils.ExtractFileExt(S);
  { Remove extension from name }
  if Ext <> '' then
  begin
    I := Pos(Ext, Name);
    if I > 0 then
      Name := Copy(Name, 1, I - 1);
  end;
end;

procedure DosFindFirst(const Path: string; Attr: Integer; var SR: TSearchRec);
begin
  DosError := System.SysUtils.FindFirst(Path, Attr, SysSearchRec);
  if DosError = 0 then
  begin
    SR.Attr := SysSearchRec.Attr;
    SR.Time := DateTimeToFileDate(SysSearchRec.TimeStamp);
    SR.Size := SysSearchRec.Size;
    SR.Name := SysSearchRec.Name;
  end;
end;

procedure DosFindNext(var SR: TSearchRec);
begin
  DosError := System.SysUtils.FindNext(SysSearchRec);
  if DosError = 0 then
  begin
    SR.Attr := SysSearchRec.Attr;
    SR.Time := DateTimeToFileDate(SysSearchRec.TimeStamp);
    SR.Size := SysSearchRec.Size;
    SR.Name := SysSearchRec.Name;
  end;
end;

procedure DosFindClose;
begin
  System.SysUtils.FindClose(SysSearchRec);
end;

procedure RemoveDoubleDirSep(var ExpPath: PathStr);
var
  P: Integer;
  OneDirSepRemoved: Boolean;
begin
  P := Pos(DirSeparator + DirSeparator, ExpPath);
  if P = 1 then
  begin
    System.Delete(ExpPath, 1, 1);
    OneDirSepRemoved := True;
    P := Pos(DirSeparator + DirSeparator, ExpPath);
  end
  else
    OneDirSepRemoved := False;
  while P > 0 do
  begin
    System.Delete(ExpPath, P + 1, 1);
    P := Pos(DirSeparator + DirSeparator, ExpPath);
  end;
  if OneDirSepRemoved then
    ExpPath := DirSeparator + ExpPath;
end;

function PathValid(var Path: PathStr): Boolean;
var
  ExpPath: PathStr;
  SR: TSearchRec;
begin
  RemoveDoubleDirSep(Path);
  ExpPath := FExpand(Path);
  if Length(ExpPath) <= 3 then
    Result := DriveValid(ExpPath[1])
  else
  begin
    if (Length(ExpPath) > 1) and (ExpPath[Length(ExpPath)] = DirSeparator) then
      SetLength(ExpPath, Length(ExpPath) - 1);
    DosFindFirst(ExpPath, Directory + Hidden, SR);
    Result := (DosError = 0) and (SR.Attr and Directory <> 0);
    if (DosError <> 0) and (Length(ExpPath) > 2) and
       (ExpPath[1] = '\') and (ExpPath[2] = '\') then
    begin
      DosFindClose;
      DosFindFirst(ExpPath + '\*', faAnyFile, SR);
      Result := (DosError = 0);
    end;
    DosFindClose;
  end;
end;

{ TDirValidator }

constructor TDirValidator.Create;
const
  Chars: TCharSet = ['A'..'Z', 'a'..'z', '.', '~', ':', '_', '-', '\'];
begin
  inherited Create(Chars);
end;

function TDirValidator.IsValid(const S: string): Boolean;
begin
  Result := True;
end;

function TDirValidator.IsValidInput(var S: string; SuppressFill: Boolean): Boolean;
begin
  Result := True;
end;

{ TFileInputLine }

constructor TFileInputLine.Create(var Bounds: TRect; AMaxLen: Integer);
begin
  inherited Create(Bounds, AMaxLen);
  EventMask := EventMask or evBroadcast;
end;

procedure TFileInputLine.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmFileFocused) and
     (State and sfSelected = 0) then
  begin
    if PSearchRec(Event.InfoPtr)^.Attr and Directory <> 0 then
      Data := PSearchRec(Event.InfoPtr)^.Name + DirSeparator +
        TFileDialog(Owner).WildCard
    else
      Data := PSearchRec(Event.InfoPtr)^.Name;
    DrawView;
  end;
end;

{ TFileCollection }

function UpperName(const S: string): string;
var
  I: Integer;
  InName: Boolean;
begin
  SetLength(Result, Length(S));
  InName := True;
  for I := Length(S) downto 1 do
    if InName and (S[I] in ['a'..'z']) then
      Result[I] := Chr(Ord(S[I]) - 32)
    else
    begin
      Result[I] := S[I];
      if S[I] = DirSeparator then
        InName := False;
    end;
end;

destructor TFileCollection.Destroy;
begin
  ClearAll;
  inherited Destroy;
end;

procedure TFileCollection.ClearAll;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I] <> nil then
      Dispose(Items[I]);
  Clear;
end;

function TFileCollection.Compare(Key1, Key2: PSearchRec): Integer;
begin
  if Key1^.Name = Key2^.Name then
    Result := 0
  else if Key1^.Name = '..' then
    Result := 1
  else if Key2^.Name = '..' then
    Result := -1
  else if (Key1^.Attr and Directory <> 0) and
          (Key2^.Attr and Directory = 0) then
    Result := 1
  else if (Key2^.Attr and Directory <> 0) and
          (Key1^.Attr and Directory = 0) then
    Result := -1
  else if UpperName(Key1^.Name) > UpperName(Key2^.Name) then
    Result := 1
  else
    Result := -1;
end;

procedure TFileCollection.InsertSorted(Item: PSearchRec);
begin
  Add(Item);
  Sort(TComparer<PSearchRec>.Construct(
    function(const Left, Right: PSearchRec): Integer
    begin
      Result := Compare(Left, Right);
    end));
end;

function TFileCollection.Search(Key: PSearchRec; var Index: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Count - 1 do
    if Compare(Items[I], Key) = 0 then
    begin
      Index := I;
      Result := True;
      Exit;
    end;
  Index := Count;
end;

{ Pattern matching }

function MatchesMask(What, Mask: string): Boolean;
var
  D1, D2: DirStr;
  N1, N2: NameStr;
  E1, E2: ExtStr;

  function CmpStr(const Hstr1, Hstr2: string): Boolean;
  var
    Found: Boolean;
    I1, I2: Integer;
  begin
    I1 := 0;
    I2 := 0;
    if Hstr1 = '' then
    begin
      Result := (Hstr2 = '');
      Exit;
    end;
    Found := True;
    repeat
      Inc(I1);
      if I1 > Length(Hstr1) then
        Break;
      Inc(I2);
      if I2 > Length(Hstr2) then
        Break;
      case Hstr1[I1] of
        '?':
          Found := True;
        '*':
          begin
            Found := True;
            if I1 = Length(Hstr1) then
              I2 := Length(Hstr2)
            else if (I1 < Length(Hstr1)) and (Hstr1[I1 + 1] <> Hstr2[I2]) then
            begin
              if I2 < Length(Hstr2) then
                Dec(I1);
            end
            else if I2 > 1 then
              Dec(I2);
          end;
      else
        Found := (Hstr1[I1] = Hstr2[I2]) or (Hstr2[I2] = '?');
      end;
    until not Found;
    if Found then
      Found := (I2 >= Length(Hstr2)) and
               ((I1 > Length(Hstr1)) or
                ((I1 = Length(Hstr1)) and (Hstr1[I1] = '*')));
    Result := Found;
  end;

begin
  FSplit(UpperCase(What), D1, N1, E1);
  FSplit(UpperCase(Mask), D2, N2, E2);
  Result := CmpStr(N2, N1) and CmpStr(E2, E1);
end;

function MatchesMaskList(What, MaskList: string): Boolean;
var
  P: Integer;
  Match: Boolean;
begin
  Match := False;
  if What <> '' then
    repeat
      P := Pos(ListSeparator, MaskList);
      if P = 0 then
        P := Length(MaskList) + 1;
      Match := MatchesMask(What, Copy(MaskList, 1, P - 1));
      System.Delete(MaskList, 1, P);
    until Match or (MaskList = '');
  Result := Match;
end;

{ TFileList }

constructor TFileList.Create(var Bounds: TRect; AScrollBar: TScrollBar);
begin
  inherited Create(Bounds, 2, AScrollBar);
  Files := nil;
end;

destructor TFileList.Destroy;
begin
  SetState(sfVisible, False);
  FreeAndNil(Files);
  inherited Destroy;
end;

function TFileList.DataSize: Word;
begin
  Result := 0;
end;

procedure TFileList.FocusItem(Item: Integer);
begin
  inherited FocusItem(Item);
  if (Files <> nil) and (Files.Count > 0) and (Item < Files.Count) then
    Message(Owner, evBroadcast, cmFileFocused, Files[Item]);
end;

procedure TFileList.GetData(var Rec);
begin
end;

var
  FileListKeyBuffer: TSearchRec;
  FileListKeyBufferInitialized: Boolean = False;

function TFileList.GetKey(var S: string): Pointer;
begin
  if not FileListKeyBufferInitialized then
  begin
    Initialize(FileListKeyBuffer);
    FileListKeyBufferInitialized := True;
  end;
  if HandleDir or ((S <> '') and (S[1] = '.')) then
    FileListKeyBuffer.Attr := Directory
  else
    FileListKeyBuffer.Attr := 0;
  FileListKeyBuffer.Name := S;
  Result := @FileListKeyBuffer;
end;

function TFileList.GetText(Item: Integer; MaxLen: Integer): string;
var
  S: string;
  SR: PSearchRec;
begin
  if (Files = nil) or (Item >= Files.Count) then
  begin
    Result := '';
    Exit;
  end;
  SR := Files[Item];
  S := SR^.Name;
  if SR^.Attr and Directory <> 0 then
    S := S + DirSeparator;
  Result := S;
end;

procedure TFileList.HandleEvent(var Event: TEvent);
var
  S: String;
  K: PSearchRec;
  Value: Integer;
begin
  if (Event.What = evMouseDown) and Event.Double then
  begin
    Event.What := evCommand;
    Event.Command := cmOK;
    PutEvent(Event);
    ClearEvent(Event);
  end
  else if (Event.What = evKeyDown) and (Event.CharCode = AnsiChar('<')) then
  begin
    S := '..';
    K := PSearchRec(GetKey(S));
    if (Files <> nil) and Files.Search(K, Value) then
      FocusItem(Value);
  end
  else
    inherited HandleEvent(Event);
end;

procedure TFileList.ReadDirectory(AWildCard: PathStr);
const
  FindAttr = ReadOnly + Archive;
  PrevDir = '..';
var
  SR: TSearchRec;
  P: PSearchRec;
  AFileList: TFileCollection;
  FindStr, WildName: string;
  Dir: DirStr;
  Ext: ExtStr;
  Name: NameStr;
  Event: TEvent;
  Tmp: PathStr;
begin
  AFileList := TFileCollection.Create;
  AWildCard := FExpand(AWildCard);
  FSplit(AWildCard, Dir, Name, Ext);
  if Pos(ListSeparator, string(AWildCard)) > 0 then
  begin
    WildName := Copy(string(AWildCard), Length(Dir) + 1, 255);
    FindStr := Dir + AllFiles;
  end
  else
  begin
    WildName := Name + Ext;
    FindStr := AWildCard;
  end;

  { Find files }
  DosFindFirst(FindStr, FindAttr, SR);
  while DosError = 0 do
  begin
    if (SR.Attr and Directory = 0) and MatchesMaskList(SR.Name, WildName) then
    begin
      New(P);
      Initialize(P^);
      P^ := SR;
      AFileList.InsertSorted(P);
    end;
    DosFindNext(SR);
  end;
  DosFindClose;

  { Find directories }
  Tmp := Dir + AllFiles;
  DosFindFirst(string(Tmp), Directory, SR);
  while DosError = 0 do
  begin
    if (SR.Attr and Directory <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
    begin
      New(P);
      Initialize(P^);
      P^ := SR;
      AFileList.InsertSorted(P);
    end;
    DosFindNext(SR);
  end;
  DosFindClose;

  { Add parent directory }
  if Length(Dir) > 4 then
  begin
    New(P);
    Initialize(P^);
    DosFindFirst(string(Tmp), Directory, SR);
    DosFindNext(SR);
    if (DosError = 0) and (SR.Name = PrevDir) then
      P^ := SR
    else
    begin
      P^.Name := PrevDir;
      P^.Size := 0;
      P^.Time := $210000;
      P^.Attr := Directory;
    end;
    AFileList.InsertSorted(P);
    DosFindClose;
  end;

  { Replace old Files with new list }
  FreeAndNil(Files);
  Files := AFileList;
  SetRange(Files.Count);
  if Files.Count > 0 then
  begin
    Event.What := evBroadcast;
    Event.Command := cmFileFocused;
    Event.InfoPtr := Files[0];
    Owner.HandleEvent(Event);
  end;
end;

procedure TFileList.SetData(var Rec);
begin
  with TFileDialog(Owner) do
    Self.ReadDirectory(Directory + WildCard);
end;

{ TFileInfoPane }

constructor TFileInfoPane.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  Initialize(S);
  S.Attr := 0;
  S.Time := 0;
  S.Size := 0;
  S.Name := '';
  EventMask := EventMask or evBroadcast;
end;

destructor TFileInfoPane.Destroy;
begin
  Finalize(S);
  inherited Destroy;
end;

procedure TFileInfoPane.Draw;
var
  B: TDrawBuffer;
  IsPM: Boolean;
  Color: Word;
  Time: TDateTime;
  Year, Mon, Day, Hour, Min, Sec, MSec: Word;
  Path: PathStr;
  Str, FileName, MonthStr: string;
  AMPMStr: string;
const
  MonthNames: array[1..12] of string = (
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
  sDirectoryLine = ' %-12s %-9s %3s %2d, %4d  %2d:%02d%s';
  sFileLine = ' %-12s %-9d %3s %2d, %4d  %2d:%02d%s';
begin
  if TFileDialog(Owner).Directory <> '' then
    Path := TFileDialog(Owner).Directory
  else
    Path := '';
  Path := FExpand(Path + TFileDialog(Owner).WildCard);
  Path := ShrinkPath(Path, Size.X - 1);
  Color := GetColor($01);
  DrawChar(B, 0, ' ', Color, Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
  DrawStr(B, 1, Path, Color);
  WriteLine(0, 0, Size.X, 1, B);

  if (S.Name = '') or (S.Name = '.') or (S.Name = '..') then
    Exit;

  FileName := Copy(S.Name, 1, 12);

  try
    Time := FileDateToDateTime(S.Time);
    DecodeDate(Time, Year, Mon, Day);
    DecodeTime(Time, Hour, Min, Sec, MSec);
  except
    Year := 1980;
    Mon := 1;
    Day := 1;
    Hour := 0;
    Min := 0;
  end;

  MonthStr := MonthNames[Mon];
  IsPM := Hour >= 12;
  Hour := Hour mod 12;
  if Hour = 0 then
    Hour := 12;
  if IsPM then
    AMPMStr := 'pm'
  else
    AMPMStr := 'am';

  if S.Attr and Directory <> 0 then
    Str := Format(sDirectoryLine, [FileName, sDirectory, MonthStr, Day, Year, Hour, Min, AMPMStr])
  else
    Str := Format(sFileLine, [FileName, S.Size, MonthStr, Day, Year, Hour, Min, AMPMStr]);

  DrawStr(B, 0, Str, Color);
  WriteLine(0, 1, Size.X, 1, B);

  DrawChar(B, 0, ' ', Color, Size.X);
  WriteLine(0, 2, Size.X, Size.Y - 2, B);
end;

function TFileInfoPane.GetPalette: PPalette;
const
  P: String[Length(CInfoPane)] = CInfoPane;
begin
  Result := PPalette(@P);
end;

procedure TFileInfoPane.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmFileFocused) then
  begin
    S := PSearchRec(Event.InfoPtr)^;
    DrawView;
  end;
end;

{ TFileHistory helper functions }

function LTrim(const S: String): String;
var
  I: Integer;
begin
  I := 1;
  while (I < Length(S)) and (S[I] = ' ') do
    Inc(I);
  Result := Copy(S, I, 255);
end;

function RTrim(const S: String): String;
var
  I: Integer;
begin
  I := Length(S);
  while (I > 0) and (S[I] = ' ') do
    Dec(I);
  Result := Copy(S, 1, I);
end;

function RelativePath(S: PathStr): Boolean;
begin
  S := LTrim(RTrim(S));
  Result := not ((S <> '') and ((S[1] = DirSeparator) or ((Length(S) > 1) and (S[2] = ':'))));
end;

function Simplify(var S: string; const Dir: string): string;
var
  I: Integer;
begin
  if RelativePath(Dir) then
  begin
    if (S <> '') and (Copy(Dir, 1, 3) = '..' + DirSeparator) then
    begin
      for I := Length(S) - 1 downto 1 do
        if S[I] = DirSeparator then
          Break;
      if S[I] = DirSeparator then
        Result := Copy(S, 1, I) + Copy(Dir, 4, 255)
      else
        Result := S + Dir;
    end
    else
      Result := S + Dir;
  end
  else
    Result := Dir;
end;

{ TFileHistory }

constructor TFileHistory.Create(var Bounds: TRect; ALink: TInputLine; AHistoryId: Word);
begin
  inherited Create(Bounds, ALink, AHistoryId);
  CurDir := '';
end;

procedure TFileHistory.HandleEvent(var Event: TEvent);
var
  HistoryWindow: THistoryWindow;
  R, P: TRect;
  C: Word;
  Rslt: String;
begin
  inherited HandleEvent(Event);
  if (Event.What = evMouseDown) or
     ((Event.What = evKeyDown) and (CtrlToArrow(Event.KeyCode) = kbDown) and
      (Link.State and sfFocused <> 0)) then
  begin
    if not Link.Focus then
    begin
      ClearEvent(Event);
      Exit;
    end;
    if CurDir <> '' then
      Rslt := CurDir
    else
      Rslt := '';
    Rslt := Simplify(Rslt, string(Link.Data));
    RemoveDoubleDirSep(Rslt);
    if IsWild(Rslt) then
      RecordHistory(Rslt);
    Link.GetBounds(R);
    Dec(R.A.X);
    Inc(R.B.X);
    Inc(R.B.Y, 7);
    Dec(R.A.Y, 1);
    Owner.GetExtent(P);
    R.Intersect(P);
    Dec(R.B.Y, 1);
    HistoryWindow := InitHistoryWindow(R);
    if HistoryWindow <> nil then
    begin
      C := Owner.ExecView(HistoryWindow);
      if C = cmOk then
      begin
        Rslt := string(HistoryWindow.GetSelection);
        if Length(Rslt) > Link.MaxLen then
          SetLength(Rslt, Link.MaxLen);
        Link.Data := Rslt;
        Link.SelectAll(True);
        Link.DrawView;
      end;
      FreeAndNil(HistoryWindow);
    end;
    ClearEvent(Event);
  end
  else if Event.What = evBroadcast then
    if ((Event.Command = cmReleasedFocus) and (Event.InfoPtr = Pointer(Link))) or
       (Event.Command = cmRecordHistory) then
    begin
      if CurDir <> '' then
        Rslt := CurDir
      else
        Rslt := '';
      Rslt := Simplify(Rslt, string(Link.Data));
      RemoveDoubleDirSep(Rslt);
      if IsWild(Rslt) then
        RecordHistory(Rslt);
    end;
end;

procedure TFileHistory.AdaptHistoryToDir(Dir: string);
var
  S, S2: String;
  I, Count: Integer;
  Items: array of string;
begin
  if CurDir <> '' then
  begin
    S := CurDir;
    if S = Dir then
      Exit;
  end
  else
    S := '';
  CurDir := Simplify(S, Dir);

  { Collect all items first }
  Count := HistoryCount(HistoryId);
  if Count = 0 then
    Exit;

  SetLength(Items, Count);
  for I := 0 to Count - 1 do
    Items[I] := HistoryStr(HistoryId, I);

  { Remove all items }
  for I := Count - 1 downto 0 do
    HistoryRemove(HistoryId, I);

  { Transform and re-add in reverse order (so first item ends up at front) }
  for I := Count - 1 downto 0 do
  begin
    S2 := Items[I];
    if RelativePath(S2) then
      if S <> '' then
        S2 := S + S2
      else
        S2 := FExpand(S2);
    HistoryAdd(HistoryId, S2);
  end;
end;

destructor TFileHistory.Destroy;
begin
  { CurDir is now a managed string - no need to free }
  inherited Destroy;
end;

{ TFileDialog }

constructor TFileDialog.Create(AWildCard: TWildStr; const ATitle, InputName: String;
  AOptions: Word; HistoryId: Byte);
var
  Control: TView;
  R: TRect;
  Opt: Word;
begin
  R.Assign(15, 1, 64, 20);
  inherited Create(R, ATitle);
  Options := Options or ofCentered;
  WildCard := AWildCard;
  Directory := '';

  R.Assign(3, 3, 31, 4);
  FileName := TFileInputLine.Create(R, 79);
  FileName.Data := WildCard;
  Insert(FileName);
  R.Assign(2, 2, 3 + CStrLen(InputName), 3);
  Control := TLabel.Create(R, InputName, FileName);
  Insert(Control);
  R.Assign(31, 3, 34, 4);
  FileHistory := TFileHistory.Create(R, FileName, HistoryId);
  Insert(FileHistory);

  R.Assign(3, 14, 34, 15);
  Control := TScrollBar.Create(R);
  Insert(Control);
  R.Assign(3, 6, 34, 14);
  FileList := TFileList.Create(R, TScrollBar(Control));
  Insert(FileList);
  R.Assign(2, 5, 8, 6);
  Control := TLabel.Create(R, slFiles, FileList);
  Insert(Control);

  R.Assign(35, 3, 46, 5);
  Opt := bfDefault;
  if AOptions and fdOpenButton <> 0 then
  begin
    Insert(TButton.Create(R, slOpen, cmFileOpen, Opt));
    Opt := bfNormal;
    Inc(R.A.Y, 3);
    Inc(R.B.Y, 3);
  end;
  if AOptions and fdOkButton <> 0 then
  begin
    Insert(TButton.Create(R, slOk, cmFileOpen, Opt));
    Opt := bfNormal;
    Inc(R.A.Y, 3);
    Inc(R.B.Y, 3);
  end;
  if AOptions and fdReplaceButton <> 0 then
  begin
    Insert(TButton.Create(R, slReplace, cmFileReplace, Opt));
    Opt := bfNormal;
    Inc(R.A.Y, 3);
    Inc(R.B.Y, 3);
  end;
  if AOptions and fdClearButton <> 0 then
  begin
    Insert(TButton.Create(R, slClear, cmFileClear, Opt));
    Opt := bfNormal;
    Inc(R.A.Y, 3);
    Inc(R.B.Y, 3);
  end;
  Insert(TButton.Create(R, slCancel, cmCancel, bfNormal));

  R.Assign(1, 16, 48, 18);
  Control := TFileInfoPane.Create(R);
  Insert(Control);

  SelectNext(False);

  if AOptions and fdNoLoadDir = 0 then
    ReadDirectory;
end;

constructor TFileDialog.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(WildCard, SizeOf(WildCard));
  FileName := TFileInputLine(GetSubViewPtr(S, Self));
  FileList := TFileList(GetSubViewPtr(S, Self));
  FileHistory := TFileHistory(GetSubViewPtr(S, Self));
  ReadDirectory;
end;

destructor TFileDialog.Destroy;
begin
  { Directory is now a managed string - no need to free }
  inherited Destroy;
end;

procedure TFileDialog.GetData(var Rec);
var
  S: PathStr;
  PStr: ^PathStr;
begin
  GetFileName(S);
  PStr := @Rec;
  PStr^ := S;
end;

procedure TFileDialog.GetFileName(var S: PathStr);
var
  Path: PathStr;
  Name: NameStr;
  Ext: ExtStr;
  TWild: string;
  TPath: PathStr;
  TName: NameStr;
  TExt: NameStr;
  I: Integer;
begin
  S := FileName.Data;
  if RelativePath(S) then
  begin
    if Directory <> '' then
      S := FExpand(Directory + S);
  end
  else
    S := FExpand(S);

  if Pos(ListSeparator, S) = 0 then
  begin
    if FileExists(S) then
      Exit;
    FSplit(S, Path, Name, Ext);
    if ((Name = '') or (Ext = '')) and not IsDir(S) then
    begin
      TWild := WildCard;
      repeat
        I := Pos(ListSeparator, TWild);
        if I = 0 then
          I := Length(TWild) + 1;
        FSplit(Copy(TWild, 1, I - 1), TPath, TName, TExt);
        if (Name = '') and (Ext = '') then
          S := Path + TName + TExt
        else if Name = '' then
          S := Path + TName + Ext
        else if Ext = '' then
        begin
          if IsWild(Name) then
            S := Path + Name + TExt
          else
            S := Path + Name + NoWildChars(TExt);
        end;
        if FileExists(S) then
          Break;
        System.Delete(TWild, 1, I);
      until TWild = '';
      if TWild = '' then
        S := Path + Name + Ext;
    end;
  end;
end;

procedure TFileDialog.HandleEvent(var Event: TEvent);
begin
  if (Event.What and evBroadcast <> 0) and
     (Event.Command = cmListItemSelected) then
  begin
    EndModal(cmFileOpen);
    ClearEvent(Event);
  end;
  inherited HandleEvent(Event);
  if Event.What = evCommand then
    case Event.Command of
      cmFileOpen, cmFileReplace, cmFileClear:
        begin
          EndModal(Event.Command);
          ClearEvent(Event);
        end;
    end;
end;

procedure TFileDialog.SetData(var Rec);
var
  PStr: ^PathStr;
begin
  inherited SetData(Rec);
  PStr := @Rec;
  if (PStr^ <> '') and IsWild(PStr^) then
  begin
    Valid(cmFileInit);
    FileName.Select;
  end;
end;

procedure TFileDialog.ReadDirectory;
begin
  FileList.ReadDirectory(WildCard);
  FileHistory.AdaptHistoryToDir(GetCurDir);
  Directory := GetCurDir;
end;

procedure TFileDialog.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(WildCard, SizeOf(WildCard));
  PutSubViewPtr(S, FileName);
  PutSubViewPtr(S, FileList);
  PutSubViewPtr(S, FileHistory);
end;

function TFileDialog.Valid(Command: Word): Boolean;
var
  FName: PathStr;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;

  function CheckDirectory(var S: PathStr): Boolean;
  begin
    if not PathValid(S) then
    begin
      MessageBox(sInvalidDriveOrDir, mfError + mfOkButton);
      FileName.Select;
      Result := False;
    end
    else
      Result := True;
  end;

  function CompleteDir(const Path: string): string;
  begin
    if (Path <> '') and (Path[Length(Path)] <> DirSeparator) and
       (Path[Length(Path)] <> ':') then
      Result := Path + DirSeparator
    else
      Result := Path;
  end;

  function NormalizeDir(const Path: string): string;
  var
    Root: Boolean;
  begin
    Root := False;
    if (Length(Path) = 3) and (UpCase(Path[1]) in ['A'..'Z']) and
       (Path[2] = ':') and (Path[3] = DirSeparator) then
      Root := True;
    if (not Root) and (Copy(Path, Length(Path), 1) = DirSeparator) then
      Result := Copy(Path, 1, Length(Path) - 1)
    else
      Result := Path;
  end;

begin
  if Command = 0 then
  begin
    Result := True;
    Exit;
  end
  else
    Result := False;

  if inherited Valid(Command) then
  begin
    GetFileName(FName);
    if (Command <> cmCancel) and (Command <> cmFileClear) then
    begin
      if IsWild(FName) or IsList(FName) then
      begin
        FSplit(FName, Dir, Name, Ext);
        if CheckDirectory(Dir) then
        begin
          FileHistory.AdaptHistoryToDir(Dir);
          Directory := Dir;
          if Pos(ListSeparator, FName) > 0 then
            WildCard := Copy(FName, Length(Dir) + 1, 255)
          else
            WildCard := Name + Ext;
          if Command <> cmFileInit then
            FileList.Select;
          FileList.ReadDirectory(Directory + WildCard);
        end;
      end
      else
      begin
        FName := NormalizeDir(FName);
        if IsDir(FName) then
        begin
          if CheckDirectory(FName) then
          begin
            FileHistory.AdaptHistoryToDir(CompleteDir(FName));
            Directory := CompleteDir(FName);
            if Command <> cmFileInit then
              FileList.Select;
            FileList.ReadDirectory(Directory + WildCard);
          end;
        end
        else if ValidFileName(FName) then
          Result := True
        else
        begin
          MessageBox(^C + sInvalidFileName, mfError + mfOkButton);
          Result := False;
        end;
      end;
    end
    else
      Result := True;
  end;
end;

{ TDirOutline - Directory tree with lazy loading }

var
  DrivesStr: string = '';

function NewDirNode(const AText, AFullPath: string; AIsDrive: Boolean): PDirNode;
begin
  New(Result);
  Result^.Next := nil;
  Result^.Text := AText;
  Result^.ChildList := nil;
  Result^.Expanded := False;
  Result^.FullPath := AFullPath;
  Result^.ChildrenLoaded := False;
  Result^.IsDrive := AIsDrive;
end;

constructor TDirOutline.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar);
begin
  DrivesStr := sDrives;
  inherited Create(Bounds, AHScrollBar, AVScrollBar);
  FRoot := nil;
  FDrivesNode := nil;
  FDir := '';
  BuildDriveNodes;
end;

destructor TDirOutline.Destroy;
begin
  FreeNode(FRoot);
  inherited Destroy;
end;

procedure TDirOutline.FreeNode(Node: PDirNode);
var
  Next: PDirNode;
begin
  while Node <> nil do
  begin
    { Free children first (recursively handles their siblings) }
    if Node^.ChildList <> nil then
      FreeNode(Node^.ChildList);
    { Move to next sibling before disposing current node }
    Next := Node^.Next;
    Dispose(Node);
    Node := Next;
  end;
end;

procedure TDirOutline.BuildDriveNodes;
var
  C: Char;
  DriveNode, LastDrive: PDirNode;
begin
  { Create root "Drives" node }
  FRoot := NewDirNode(DrivesStr, DrivesStr, False);
  FRoot^.Expanded := True;
  FRoot^.ChildrenLoaded := True;
  FDrivesNode := FRoot;

  { Add drive nodes as children }
  LastDrive := nil;
  for C := 'A' to 'Z' do
  begin
    if DriveValid(C) then
    begin
      DriveNode := NewDirNode(C + ':', C + ':' + DirSeparator, True);
      if LastDrive = nil then
        FRoot^.ChildList := DriveNode
      else
        LastDrive^.Next := DriveNode;
      LastDrive := DriveNode;
    end;
  end;
end;

procedure TDirOutline.LoadChildren(Node: PDirNode);
var
  SR: TSearchRec;
  ChildNode, LastChild: PDirNode;
  SearchPath: string;
begin
  if (Node = nil) or Node^.ChildrenLoaded then Exit;

  Node^.ChildrenLoaded := True;
  LastChild := nil;

  { Build search path }
  SearchPath := Node^.FullPath;
  if (SearchPath <> '') and (SearchPath[Length(SearchPath)] <> DirSeparator) then
    SearchPath := SearchPath + DirSeparator;
  SearchPath := SearchPath + AllFiles;

  { Enumerate subdirectories }
  DosFindFirst(SearchPath, Directory, SR);
  while DosError = 0 do
  begin
    if (SR.Attr and Directory <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
    begin
      { Build child path - avoid double backslash if parent ends with separator }
      if (Node^.FullPath <> '') and (Node^.FullPath[Length(Node^.FullPath)] = DirSeparator) then
        ChildNode := NewDirNode(SR.Name, Node^.FullPath + SR.Name, False)
      else
        ChildNode := NewDirNode(SR.Name, Node^.FullPath + DirSeparator + SR.Name, False);
      if LastChild = nil then
        Node^.ChildList := ChildNode
      else
        LastChild^.Next := ChildNode;
      LastChild := ChildNode;
    end;
    DosFindNext(SR);
  end;
  DosFindClose;
end;

function TDirOutline.FindNodeByPath(const APath: string): PDirNode;
var
  Path, Part: string;
  Node, Child: PDirNode;
  I: Integer;
begin
  Result := nil;
  if APath = '' then Exit;
  if APath = DrivesStr then
  begin
    Result := FRoot;
    Exit;
  end;

  Path := APath;

  { Start from drives node }
  Node := FRoot;
  if Node = nil then Exit;

  { Find the drive }
  if Length(Path) >= 2 then
  begin
    Part := UpperCase(Copy(Path, 1, 2));  { e.g., "C:" }
    Child := Node^.ChildList;
    while Child <> nil do
    begin
      if UpperCase(Child^.Text) = Part then
      begin
        Node := Child;
        Break;
      end;
      Child := Child^.Next;
    end;
    if Child = nil then Exit;  { Drive not found }

    { Remove drive part from path }
    Path := Copy(Path, 3, MaxInt);
    if (Path <> '') and (Path[1] = DirSeparator) then
      Delete(Path, 1, 1);
  end;

  { Navigate through path components }
  while Path <> '' do
  begin
    I := Pos(DirSeparator, Path);
    if I > 0 then
    begin
      Part := Copy(Path, 1, I - 1);
      Delete(Path, 1, I);
    end
    else
    begin
      Part := Path;
      Path := '';
    end;

    if Part = '' then Continue;

    { Load children if needed }
    if not Node^.ChildrenLoaded then
      LoadChildren(Node);

    { Find child with matching name }
    Child := Node^.ChildList;
    while Child <> nil do
    begin
      if SameText(Child^.Text, Part) then
      begin
        Node := Child;
        Break;
      end;
      Child := Child^.Next;
    end;
    if Child = nil then Exit;  { Path component not found }
  end;

  Result := Node;
end;

function TDirOutline.FindNodePosition(TargetNode: PDirNode): Sw_Integer;
{ Find the position of a node in the flattened tree view }
var
  Position: Sw_Integer;
  Found: Boolean;

  procedure CountNodes(Node: PDirNode);
  var
    Child: PDirNode;
  begin
    if (Node = nil) or Found then Exit;

    Inc(Position);
    if Node = TargetNode then
    begin
      Found := True;
      Exit;
    end;

    if Node^.Expanded then
    begin
      Child := Node^.ChildList;
      while (Child <> nil) and not Found do
      begin
        CountNodes(Child);
        Child := Child^.Next;
      end;
    end;
  end;

begin
  Position := -1;
  Found := False;
  if FRoot <> nil then
    CountNodes(FRoot);
  if Found then
    Result := Position
  else
    Result := -1;
end;

procedure TDirOutline.ExpandToPath(const APath: string);
var
  Path, Part: string;
  Node, Child, TargetNode: PDirNode;
  I: Integer;
begin
  if APath = '' then Exit;
  if APath = DrivesStr then
  begin
    FRoot^.Expanded := True;
    Update;
    Exit;
  end;

  Path := APath;
  Node := FRoot;
  Node^.Expanded := True;

  { Find and expand the drive }
  if Length(Path) >= 2 then
  begin
    Part := UpperCase(Copy(Path, 1, 2));
    Child := Node^.ChildList;
    while Child <> nil do
    begin
      if UpperCase(Child^.Text) = Part then
      begin
        Node := Child;
        Node^.Expanded := True;
        if not Node^.ChildrenLoaded then
          LoadChildren(Node);
        Break;
      end;
      Child := Child^.Next;
    end;
    if Child = nil then Exit;

    Path := Copy(Path, 3, MaxInt);
    if (Path <> '') and (Path[1] = DirSeparator) then
      Delete(Path, 1, 1);
  end;

  TargetNode := Node;

  { Expand along the path }
  while Path <> '' do
  begin
    I := Pos(DirSeparator, Path);
    if I > 0 then
    begin
      Part := Copy(Path, 1, I - 1);
      Delete(Path, 1, I);
    end
    else
    begin
      Part := Path;
      Path := '';
    end;

    if Part = '' then Continue;

    if not Node^.ChildrenLoaded then
      LoadChildren(Node);

    Child := Node^.ChildList;
    while Child <> nil do
    begin
      if SameText(Child^.Text, Part) then
      begin
        Node := Child;
        Node^.Expanded := True;
        TargetNode := Node;
        if not Node^.ChildrenLoaded then
          LoadChildren(Node);
        Break;
      end;
      Child := Child^.Next;
    end;
    if Child = nil then Break;
  end;

  Update;

  { Focus on target node }
  if TargetNode <> nil then
  begin
    I := FindNodePosition(TargetNode);
    if (I >= 0) and (I < Limit.Y) then
    begin
      { Set focus directly - SetFocus may not work during initialization }
      Foc := I;
      { Ensure node is visible by scrolling if needed }
      if I < Delta.Y then
        ScrollTo(Delta.X, I)
      else if I - Size.Y >= Delta.Y then
        ScrollTo(Delta.X, I - Size.Y + 1);
    end;
    { Also set as active path for highlighting }
    FActivePath := TargetNode^.FullPath;
  end;
end;

procedure TDirOutline.Adjust(Node: Pointer; Expand: Boolean);
var
  DirNode: PDirNode;
begin
  DirNode := PDirNode(Node);
  if DirNode = nil then Exit;

  { Load children on first expand }
  if Expand and not DirNode^.ChildrenLoaded then
    LoadChildren(DirNode);

  DirNode^.Expanded := Expand;
end;

function TDirOutline.GetChild(Node: Pointer; I: Sw_Integer): Pointer;
var
  DirNode, Child: PDirNode;
begin
  Result := nil;
  DirNode := PDirNode(Node);
  if DirNode = nil then Exit;

  { Load children on demand }
  if not DirNode^.ChildrenLoaded then
    LoadChildren(DirNode);

  Child := DirNode^.ChildList;
  while (I > 0) and (Child <> nil) do
  begin
    Dec(I);
    Child := Child^.Next;
  end;
  Result := Child;
end;

function TDirOutline.GetNumChildren(Node: Pointer): Sw_Integer;
var
  DirNode, Child: PDirNode;
begin
  Result := 0;
  DirNode := PDirNode(Node);
  if DirNode = nil then Exit;

  { Load children on demand }
  if not DirNode^.ChildrenLoaded then
    LoadChildren(DirNode);

  Child := DirNode^.ChildList;
  while Child <> nil do
  begin
    Inc(Result);
    Child := Child^.Next;
  end;
end;

function TDirOutline.GetRoot: Pointer;
begin
  Result := FRoot;
end;

function TDirOutline.GetText(Node: Pointer): string;
var
  DirNode: PDirNode;
begin
  Result := '';
  DirNode := PDirNode(Node);
  if DirNode <> nil then
    Result := DirNode^.Text;
end;

function TDirOutline.HasChildren(Node: Pointer): Boolean;
var
  DirNode: PDirNode;
  SR: TSearchRec;
  SearchPath: string;
begin
  Result := False;
  DirNode := PDirNode(Node);
  if DirNode = nil then Exit;

  { If already loaded, just check the list }
  if DirNode^.ChildrenLoaded then
  begin
    Result := DirNode^.ChildList <> nil;
    Exit;
  end;

  { For drives node (root), we know it has children }
  if DirNode = FDrivesNode then
  begin
    Result := True;
    Exit;
  end;

  { Quick check: scan for ANY subdirectory, return immediately when found }
  SearchPath := DirNode^.FullPath;
  if (SearchPath <> '') and (SearchPath[Length(SearchPath)] <> DirSeparator) then
    SearchPath := SearchPath + DirSeparator;
  SearchPath := SearchPath + AllFiles;

  DosFindFirst(SearchPath, Directory, SR);
  while DosError = 0 do
  begin
    if (SR.Attr and Directory <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
    begin
      Result := True;
      DosFindClose;
      Exit;
    end;
    DosFindNext(SR);
  end;
  DosFindClose;
end;

function TDirOutline.IsExpanded(Node: Pointer): Boolean;
var
  DirNode: PDirNode;
begin
  Result := False;
  DirNode := PDirNode(Node);
  if DirNode <> nil then
    Result := DirNode^.Expanded;
end;

function TDirOutline.GetPalette: PPalette;
const
  { Custom palette: Normal=#6, Focus=#8 (same as Select), Select=#8 }
  { This ensures the active folder is always highlighted the same way }
  { whether the tree has focus or not }
  CDirOutline: ShortString = #6#8#8#8;
begin
  Result := PPalette(@CDirOutline);
end;

function TDirOutline.IsSelected(I: Sw_Integer): Boolean;
var
  Node: PDirNode;
begin
  { Item is selected if it's the focused item OR if its path matches ActivePath }
  Result := (Foc = I);
  if not Result and (FActivePath <> '') then
  begin
    Node := PDirNode(GetNode(I));
    if Node <> nil then
      Result := SameText(Node^.FullPath, FActivePath);
  end;
end;

procedure TDirOutline.SetActivePath(const APath: string);
begin
  FActivePath := APath;
  DrawView;  { Always redraw to ensure highlighting is visible }
end;

procedure TDirOutline.Focused(I: Sw_Integer);
var
  Node: PDirNode;
  NewPath: string;
begin
  inherited Focused(I);

  { Update ActivePath to match focused node and redraw }
  Node := PDirNode(GetNode(I));
  if Node <> nil then
  begin
    NewPath := Node^.FullPath;
    if FActivePath <> NewPath then
    begin
      FActivePath := NewPath;
      DrawView;
    end;
  end;

  { Broadcast directory selection change to owner when visible }
  if (Owner <> nil) and (State and sfVisible <> 0) then
    Message(Owner, evCommand, cmDirSelected, @Self);
end;

procedure TDirOutline.HandleEvent(var Event: TEvent);
var
  SelectedNode: PDirNode;
  Mouse: TPoint;
  ClickedItem: Sw_Integer;
  WasAlreadyFocused: Boolean;
begin
  case Event.What of
    evMouseDown:
      begin
        { Calculate which item was clicked }
        MakeLocal(Event.Where, Mouse);
        if MouseInView(Event.Where) then
        begin
          ClickedItem := Delta.Y + Mouse.Y;
          WasAlreadyFocused := (ClickedItem = Foc);
        end
        else
          WasAlreadyFocused := False;

        if Event.Double then
        begin
          { Double-click navigates into directory }
          SelectedNode := PDirNode(GetNode(Foc));
          if SelectedNode <> nil then
          begin
            Event.What := evCommand;
            Event.Command := cmChangeDir;
            PutEvent(Event);
            ClearEvent(Event);
          end;
        end
        else
        begin
          { Let inherited handle the click first }
          inherited HandleEvent(Event);
          { If clicked on already-focused item, manually trigger update }
          if WasAlreadyFocused and (Owner <> nil) and (State and sfVisible <> 0) then
            Message(Owner, evCommand, cmDirSelected, @Self);
          Exit; { Already called inherited }
        end;
      end;
  end;
  inherited HandleEvent(Event);
end;

procedure TDirOutline.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState and sfFocused <> 0) and (Owner <> nil) and (Owner is TChDirDialog) then
    TChDirDialog(Owner).ChDirButton.MakeDefault(Enable);
end;

procedure TDirOutline.NewDirectory(var ADir: DirStr);
begin
  FDir := ADir;
  ExpandToPath(ADir);
  DrawView;
end;

function TDirOutline.GetSelectedPath: string;
var
  SelectedNode: PDirNode;
begin
  Result := '';
  SelectedNode := PDirNode(GetNode(Foc));
  if SelectedNode <> nil then
    Result := SelectedNode^.FullPath;
end;

{ TChDirDialog }

constructor TChDirDialog.Create(AOptions: Word; HistoryId: Word);
var
  R: TRect;
  Control: TView;
begin
  R.Assign(16, 2, 64, 20);
  inherited Create(R, sChangeDirectory);
  Options := Options or ofCentered;

  R.Assign(3, 3, 30, 4);
  DirInput := TInputLine.Create(R, FileNameLen + 4);
  Insert(DirInput);
  R.Assign(2, 2, 17, 3);
  Control := TLabel.Create(R, slDirectoryName, DirInput);
  Insert(Control);
  R.Assign(30, 3, 33, 4);
  Control := THistory.Create(R, DirInput, HistoryId);
  Insert(Control);

  R.Assign(32, 6, 33, 16);
  Control := TScrollBar.Create(R);
  Insert(Control);
  R.Assign(3, 6, 32, 16);
  DirList := TDirOutline.Create(R, nil, TScrollBar(Control));
  Insert(DirList);
  R.Assign(2, 5, 17, 6);
  Control := TLabel.Create(R, slDirectoryTree, DirList);
  Insert(Control);

  R.Assign(35, 6, 45, 8);
  OkButton := TButton.Create(R, slOk, cmOK, bfDefault);
  Insert(OkButton);
  Inc(R.A.Y, 3);
  Inc(R.B.Y, 3);
  ChDirButton := TButton.Create(R, slChDir, cmChangeDir, bfNormal);
  Insert(ChDirButton);
  Inc(R.A.Y, 3);
  Inc(R.B.Y, 3);
  Insert(TButton.Create(R, slRevert, cmRevert, bfNormal));

  if AOptions and cdNoLoadDir = 0 then
    SetUpDialog;

  SelectNext(False);
end;

constructor TChDirDialog.Load(var S: TFVStream);
begin
  inherited Load(S);
  DirList := TDirOutline(GetSubViewPtr(S, Self));
  DirInput := TInputLine(GetSubViewPtr(S, Self));
  OkButton := TButton(GetSubViewPtr(S, Self));
  ChDirButton := TButton(GetSubViewPtr(S, Self));
  SetUpDialog;
end;

function TChDirDialog.DataSize: Word;
begin
  Result := 0;
end;

procedure TChDirDialog.GetData(var Rec);
begin
end;

procedure TChDirDialog.HandleEvent(var Event: TEvent);
var
  CurDir: DirStr;
  SelectedPath: string;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evCommand:
      begin
        case Event.Command of
          cmRevert:
            System.GetDir(0, CurDir);
          cmChangeDir:
            begin
              SelectedPath := DirList.GetSelectedPath;
              if (SelectedPath = DrivesStr) or
                 ((Length(SelectedPath) >= 1) and DriveValid(Char(SelectedPath[1]))) then
                CurDir := SelectedPath
              else
                Exit;
            end;
        else
          Exit;
        end;
        if (Length(CurDir) > 3) and (CurDir[Length(CurDir)] = DirSeparator) then
          CurDir := Copy(CurDir, 1, Length(CurDir) - 1);
        DirList.NewDirectory(CurDir);
        DirInput.Data := CurDir;
        DirInput.DrawView;
        DirList.Select;
        ClearEvent(Event);
      end;
  end;
end;

procedure TChDirDialog.SetData(var Rec);
begin
end;

procedure TChDirDialog.SetUpDialog;
var
  CurDir: DirStr;
begin
  if DirList <> nil then
  begin
    CurDir := GetCurDir;
    DirList.NewDirectory(CurDir);
    if (Length(CurDir) > 3) and (CurDir[Length(CurDir)] = DirSeparator) then
      CurDir := Copy(CurDir, 1, Length(CurDir) - 1);
    if DirInput <> nil then
    begin
      DirInput.Data := CurDir;
      DirInput.DrawView;
    end;
  end;
end;

procedure TChDirDialog.Store(var S: TFVStream);
begin
  inherited Store(S);
  PutSubViewPtr(S, DirList);
  PutSubViewPtr(S, DirInput);
  PutSubViewPtr(S, OkButton);
  PutSubViewPtr(S, ChDirButton);
end;

function TChDirDialog.Valid(Command: Word): Boolean;
var
  P: PathStr;
begin
  Result := True;
  if Command = cmOk then
  begin
    P := FExpand(DirInput.Data);
    if (Length(P) > 3) and (P[Length(P)] = DirSeparator) then
      SetLength(P, Length(P) - 1);
    {$I-}
    System.ChDir(P);
    if IOResult <> 0 then
    begin
      MessageBox(sInvalidDirectory, mfError + mfOkButton);
      Result := False;
    end;
    {$I+}
  end;
end;

{ TEditChDirDialog }

function TEditChDirDialog.DataSize: Word;
begin
  Result := SizeOf(DirStr);
end;

procedure TEditChDirDialog.GetData(var Rec);
var
  CurDir: DirStr absolute Rec;
begin
  if DirInput = nil then
    CurDir := ''
  else
  begin
    CurDir := DirInput.Data;
    if CurDir[Length(CurDir)] <> DirSeparator then
      CurDir := CurDir + DirSeparator;
  end;
end;

procedure TEditChDirDialog.SetData(var Rec);
var
  CurDir: DirStr absolute Rec;
begin
  if DirList <> nil then
  begin
    DirList.NewDirectory(CurDir);
    if DirInput <> nil then
    begin
      if (Length(CurDir) > 3) and (CurDir[Length(CurDir)] = DirSeparator) then
        DirInput.Data := Copy(CurDir, 1, Length(CurDir) - 1)
      else
        DirInput.Data := CurDir;
      DirInput.DrawView;
    end;
  end;
end;

{ TFolderSelectDialog - Dialog for selecting a folder without changing current directory }

constructor TFolderSelectDialog.Create(AOptions: Word; HistoryId: Word);
var
  R: TRect;
  Control: TView;
begin
  R.Assign(16, 2, 64, 18);
  inherited Create(R, sSelectFolder);
  Options := Options or ofCentered;

  R.Assign(3, 3, 30, 4);
  DirInput := TInputLine.Create(R, FileNameLen + 4);
  Insert(DirInput);
  R.Assign(2, 2, 17, 3);
  Control := TLabel.Create(R, slDirectoryName, DirInput);
  Insert(Control);
  R.Assign(30, 3, 33, 4);
  Control := THistory.Create(R, DirInput, HistoryId);
  Insert(Control);

  R.Assign(32, 6, 33, 14);
  Control := TScrollBar.Create(R);
  Insert(Control);
  R.Assign(3, 6, 32, 14);
  DirList := TDirOutline.Create(R, nil, TScrollBar(Control));
  Insert(DirList);
  R.Assign(2, 5, 17, 6);
  Control := TLabel.Create(R, slDirectoryTree, DirList);
  Insert(Control);

  R.Assign(35, 6, 45, 8);
  SelectButton := TButton.Create(R, slSelect, cmOK, bfDefault);
  Insert(SelectButton);
  Inc(R.A.Y, 3);
  Inc(R.B.Y, 3);
  Insert(TButton.Create(R, slCancel, cmCancel, bfNormal));

  if AOptions and cdNoLoadDir = 0 then
    SetUpDialog;

  SelectNext(False);
end;

function TFolderSelectDialog.DataSize: Word;
begin
  Result := SizeOf(DirStr);
end;

procedure TFolderSelectDialog.GetData(var Rec);
var
  SelectedDir: DirStr absolute Rec;
begin
  if DirInput = nil then
    SelectedDir := ''
  else
  begin
    SelectedDir := DirInput.Data;
    if (SelectedDir <> '') and (SelectedDir[Length(SelectedDir)] <> DirSeparator) then
      SelectedDir := SelectedDir + DirSeparator;
  end;
end;

procedure TFolderSelectDialog.HandleEvent(var Event: TEvent);
var
  SelectedPath: string;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evCommand:
      begin
        case Event.Command of
          cmDirSelected:
            begin
              { Single-click on folder - update the input line }
              SelectedPath := DirList.GetSelectedPath;
              if (SelectedPath <> '') and (SelectedPath <> DrivesStr) then
              begin
                if (Length(SelectedPath) > 3) and (SelectedPath[Length(SelectedPath)] = DirSeparator) then
                  SelectedPath := Copy(SelectedPath, 1, Length(SelectedPath) - 1);
                DirInput.Data := SelectedPath;
                DirInput.DrawView;
              end;
              ClearEvent(Event);
            end;
          cmChangeDir:
            begin
              { Double-click on folder - select it and close dialog }
              SelectedPath := DirList.GetSelectedPath;
              if (SelectedPath <> '') and (SelectedPath <> DrivesStr) then
              begin
                if (Length(SelectedPath) > 3) and (SelectedPath[Length(SelectedPath)] = DirSeparator) then
                  SelectedPath := Copy(SelectedPath, 1, Length(SelectedPath) - 1);
                DirInput.Data := SelectedPath;
                DirInput.DrawView;
                { Close the dialog with OK result }
                EndModal(cmOK);
              end;
              ClearEvent(Event);
            end;
        end;
      end;
  end;
end;

procedure TFolderSelectDialog.SetData(var Rec);
var
  InitDir: DirStr absolute Rec;
begin
  if DirList <> nil then
  begin
    DirList.NewDirectory(InitDir);
    if DirInput <> nil then
    begin
      if (Length(InitDir) > 3) and (InitDir[Length(InitDir)] = DirSeparator) then
        DirInput.Data := Copy(InitDir, 1, Length(InitDir) - 1)
      else
        DirInput.Data := InitDir;
      DirInput.DrawView;
    end;
  end;
end;

procedure TFolderSelectDialog.SetUpDialog;
var
  CurDir: DirStr;
begin
  if DirList <> nil then
  begin
    CurDir := GetCurDir;
    DirList.NewDirectory(CurDir);
    if (Length(CurDir) > 3) and (CurDir[Length(CurDir)] = DirSeparator) then
      CurDir := Copy(CurDir, 1, Length(CurDir) - 1);
    if DirInput <> nil then
    begin
      DirInput.Data := CurDir;
      DirInput.DrawView;
    end;
  end;
end;

function TFolderSelectDialog.Valid(Command: Word): Boolean;
var
  P: PathStr;
begin
  Result := True;
  if Command = cmOK then
  begin
    P := FExpand(DirInput.Data);
    if (Length(P) > 3) and (P[Length(P)] = DirSeparator) then
      SetLength(P, Length(P) - 1);
    if not DirectoryExists(P) then
    begin
      MessageBox(sInvalidDirectory, mfError + mfOkButton);
      Result := False;
    end;
  end;
end;

{ TModernFileDialog - Split-pane file dialog with directory tree and file list }

constructor TModernFileDialog.Create(AWildCard: TWildStr; const ATitle: string;
  AOptions: Word; AHistoryId: Byte);
var
  R: TRect;
  TreeScroll, ListScroll: TScrollBar;
begin
  { Dialog: 76 wide x 20 tall, centered }
  R.Assign(0, 0, 76, 20);
  inherited Create(R, ATitle);
  Options := Options or ofCentered;

  FOptions := AOptions;
  WildCard := AWildCard;
  Directory := GetCurDir;
  if (Directory <> '') and (Directory[Length(Directory)] <> DirSeparator) then
    Directory := Directory + DirSeparator;

  { === Top row: Label + Filename input + Buttons === }

  { Label "Name" }
  R.Assign(3, 2, 8, 3);
  Insert(TLabel.Create(R, 'Name', nil));

  { Filename input field }
  R.Assign(9, 2, 48, 3);
  FileName := TFileInputLine.Create(R, 128);
  { For save dialogs, start with empty name so user can just type;
    for open dialogs, start with the wildcard to show current filter }
  if AOptions and (fdOkButton or fdReplaceButton) <> 0 then
    FileName.Data := ''
  else
    FileName.Data := WildCard;
  Insert(FileName);

  { Action button - text and command depend on options }
  R.Assign(55, 2, 65, 4);
  if AOptions and fdReplaceButton <> 0 then
    Insert(TButton.Create(R, slReplace, cmFileReplace, bfDefault))
  else if AOptions and fdOkButton <> 0 then
    Insert(TButton.Create(R, slOk, cmFileOpen, bfDefault))
  else
    Insert(TButton.Create(R, slOpen, cmFileOpen, bfDefault));

  { Cancel button }
  R.Assign(66, 2, 75, 4);
  Insert(TButton.Create(R, 'Cancel', cmCancel, bfNormal));

  { === Left pane: Directory tree === }

  { Tree label }
  R.Assign(2, 4, 15, 5);
  Insert(TLabel.Create(R, '~D~irectory', nil));

  { Tree scrollbar }
  R.Assign(35, 5, 36, 17);
  TreeScroll := TScrollBar.Create(R);
  Insert(TreeScroll);

  { Directory tree }
  R.Assign(2, 5, 35, 17);
  DirTree := TDirOutline.Create(R, nil, TreeScroll);
  Insert(DirTree);

  { === Right pane: File list === }

  { Files label }
  R.Assign(38, 4, 48, 5);
  Insert(TLabel.Create(R, '~F~iles', nil));

  { File list scrollbar }
  R.Assign(73, 5, 74, 17);
  ListScroll := TScrollBar.Create(R);
  Insert(ListScroll);

  { File list }
  R.Assign(38, 5, 73, 17);
  FileList := TFileList.Create(R, ListScroll);
  Insert(FileList);

  { No InfoPane - it requires TFileDialog as owner }
  InfoPane := nil;

  { Initialize tree to current directory and set active path }
  if DirTree <> nil then
  begin
    DirTree.NewDirectory(DirStr(Directory));
    DirTree.ActivePath := ExcludeTrailingPathDelimiter(Directory);
  end;

  { Load initial file list }
  if FileList <> nil then
    FileList.ReadDirectory(Directory + WildCard);

  SelectNext(False);
end;

destructor TModernFileDialog.Destroy;
begin
  inherited Destroy;
end;

procedure TModernFileDialog.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  { When dialog becomes visible, ensure tree highlighting is shown }
  if (AState and sfVisible <> 0) and Enable then
  begin
    if DirTree <> nil then
      DirTree.DrawView;
  end;
end;

procedure TModernFileDialog.ReadDirectory;
begin
  if FileList <> nil then
  begin
    FileList.ReadDirectory(Directory + WildCard);
    { Reset scroll to top and focus first item }
    FileList.FocusItem(0);
    FileList.DrawView;
  end;
  { Update active path highlighting in tree }
  if DirTree <> nil then
  begin
    DirTree.ActivePath := ExcludeTrailingPathDelimiter(Directory);
  end;
end;

procedure TModernFileDialog.SyncTreeToList;
var
  TreePath: string;
begin
  if DirTree <> nil then
  begin
    TreePath := DirTree.GetSelectedPath;
    if (TreePath <> '') and (TreePath <> DrivesStr) then
    begin
      Directory := TreePath;
      if (Directory <> '') and (Directory[Length(Directory)] <> DirSeparator) then
        Directory := Directory + DirSeparator;
    end;
  end;
  ReadDirectory;
end;

procedure TModernFileDialog.HandleEvent(var Event: TEvent);
var
  FocusedFile: PSearchRec;
  NewDir: string;

  function NavigateToDirectory: Boolean;
  { If focused item is a directory, navigate into it and return True }
  begin
    Result := False;
    if (FileList <> nil) and (FileList.Files <> nil) and
       (FileList.Focused < FileList.Files.Count) then
    begin
      FocusedFile := FileList.Files[FileList.Focused];
      if (FocusedFile <> nil) and ((FocusedFile^.Attr and faDirectory) <> 0) then
      begin
        { Navigate into directory }
        if FocusedFile^.Name = '..' then
        begin
          { Go up one level }
          NewDir := ExtractFileDir(ExcludeTrailingPathDelimiter(Directory));
          if NewDir = '' then
            NewDir := ExtractFileDrive(Directory);
        end
        else
        begin
          { Go into subdirectory }
          NewDir := Directory + FocusedFile^.Name;
        end;

        if NewDir <> '' then
        begin
          if NewDir[Length(NewDir)] <> DirSeparator then
            NewDir := NewDir + DirSeparator;
          Directory := NewDir;

          { Update tree to match }
          if DirTree <> nil then
          begin
            DirTree.NewDirectory(DirStr(Directory));
            DirTree.DrawView;
          end;

          { Update file list }
          ReadDirectory;

          { Update filename field with wildcard }
          if FileName <> nil then
          begin
            FileName.Data := WildCard;
            FileName.DrawView;
          end;
        end;
        Result := True;
      end;
    end;
  end;

begin
  case Event.What of
    evCommand:
      begin
        case Event.Command of
          cmDirSelected:
            begin
              { Directory tree selection changed - update file list }
              SyncTreeToList;
              ClearEvent(Event);
            end;

          cmOK:
            begin
              { Double-click in file list sends cmOK }
              { If it's a directory, navigate; if file, close with cmFileOpen }
              if NavigateToDirectory then
                ClearEvent(Event)
              else
              begin
                { It's a file - close dialog with cmFileOpen result }
                ClearEvent(Event);
                EndModal(cmFileOpen);
              end;
            end;

          cmFileOpen:
            begin
              { Open/OK button clicked - check if directory selected }
              if NavigateToDirectory then
                ClearEvent(Event)
              else
              begin
                { It's a file - close dialog }
                ClearEvent(Event);
                EndModal(cmFileOpen);
              end;
            end;

          cmFileReplace:
            begin
              { Replace/Save button clicked }
              if NavigateToDirectory then
                ClearEvent(Event)
              else
              begin
                ClearEvent(Event);
                EndModal(cmFileReplace);
              end;
            end;
        end;
      end;
  end;

  if Event.What <> evNothing then
    inherited HandleEvent(Event);

  { Handle broadcasts after inherited }
  if Event.What = evBroadcast then
  begin
    if Event.Command = cmFileFocused then
    begin
      { Update filename field when file is focused }
      if (FileList <> nil) and (FileList.Files <> nil) and
         (FileList.Focused < FileList.Files.Count) then
      begin
        FocusedFile := FileList.Files[FileList.Focused];
        if (FocusedFile <> nil) and ((FocusedFile^.Attr and faDirectory) = 0) then
        begin
          { It's a file - show in filename field }
          if FileName <> nil then
          begin
            FileName.Data := FocusedFile^.Name;
            FileName.DrawView;
          end;
        end;
      end;
    end;
  end;
end;

procedure TModernFileDialog.GetFileName(var S: PathStr);
begin
  if FileName <> nil then
    S := FExpand(Directory + FileName.Data)
  else
    S := '';
end;

function TModernFileDialog.Valid(Command: Word): Boolean;
var
  T: PathStr;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
begin
  Result := inherited Valid(Command);
  if not Result then Exit;

  if (Command = cmFileOpen) or (Command = cmFileReplace) then
  begin
    GetFileName(T);
    if T = '' then
    begin
      Result := False;
      Exit;
    end;

    { Parse the path }
    FSplit(T, Dir, Name, Ext);

    { Check if it's a wildcard or directory }
    if (Pos('*', Name) > 0) or (Pos('?', Name) > 0) then
    begin
      { It's a wildcard - update filter and directory }
      WildCard := Name + Ext;
      if Dir <> '' then
        Directory := Dir;
      ReadDirectory;
      if FileName <> nil then
      begin
        FileName.Data := WildCard;
        FileName.DrawView;
      end;
      Result := False;  { Don't close dialog }
    end
    else if DirectoryExists(T) then
    begin
      { It's a directory - navigate into it }
      Directory := T;
      if Directory[Length(Directory)] <> DirSeparator then
        Directory := Directory + DirSeparator;

      if DirTree <> nil then
      begin
        DirTree.NewDirectory(DirStr(Directory));
        DirTree.DrawView;
      end;

      ReadDirectory;
      if FileName <> nil then
      begin
        FileName.Data := WildCard;
        FileName.DrawView;
      end;
      Result := False;  { Don't close dialog }
    end
    else if not FileExists(T) then
    begin
      { In save/replace mode (fdOkButton or fdReplaceButton), allow new files.
        In open mode (fdOpenButton), reject non-existing files. }
      if FOptions and (fdOkButton or fdReplaceButton) <> 0 then
        Result := True   { Allow saving to a new file }
      else
      begin
        MessageBox(^C'File not found:'^M + T, mfError + mfOkButton);
        Result := False;
      end;
    end;
  end;
end;

{ TSortedListBox }

constructor TSortedListBox.Create(var Bounds: TRect; ANumCols: Word;
  AScrollBar: TScrollBar);
begin
  inherited Create(Bounds, ANumCols, AScrollBar);
  SearchPos := 0;
  ShowCursor;
  SetCursor(1, 0);
end;

procedure TSortedListBox.HandleEvent(var Event: TEvent);

  function IsSpecialChar(C: Char): Boolean;
  begin
    Result := (C = #0) or (C = #9) or (C = #27);
  end;

  function GetFileList: TFileCollection;
  begin
    if Self is TFileList then
      Result := TFileList(Self).Files
    else
      Result := nil;
  end;

var
  CurString, NewString: String;
  K: PSearchRec;
  Value: Sw_Integer;
  OldPos, OldValue: Sw_Integer;
  T: Boolean;
  FileList: TFileCollection;
begin
  OldValue := Focused;
  inherited HandleEvent(Event);
  if (OldValue <> Focused) or
     ((Event.What = evBroadcast) and (Event.InfoPtr = Pointer(Self)) and
      (Event.Command = cmReleasedFocus)) then
    SearchPos := 0;
  if Event.What = evKeyDown then
  begin
    FileList := GetFileList;
    if not IsSpecialChar(Char(Event.CharCode)) and
       (FileList <> nil) and (FileList.Count > 0) then
    begin
      Value := Focused;
      if Value < Range then
        CurString := GetText(Value, 255)
      else
        CurString := '';
      OldPos := SearchPos;
      if Event.KeyCode = kbBack then
      begin
        if SearchPos = 0 then
          Exit;
        Dec(SearchPos);
        if SearchPos = 0 then
          HandleDir := ((GetShiftState and $3) <> 0) or CharInSet(Event.CharCode, ['A'..'Z']);
        SetLength(CurString, SearchPos);
      end
      else if Event.CharCode = AnsiChar('.') then
        SearchPos := System.Pos('.', CurString)
      else
      begin
        Inc(SearchPos);
        if SearchPos = 1 then
          HandleDir := ((GetShiftState and 3) <> 0) or CharInSet(Event.CharCode, ['A'..'Z']);
        SetLength(CurString, SearchPos);
        CurString[SearchPos] := Char(Event.CharCode);
      end;
      K := PSearchRec(GetKey(CurString));
      if FileList <> nil then
        T := FileList.Search(K, Value)
      else
      begin
        T := False;
        Value := 0;
      end;
      if Value < Range then
      begin
        if Value < Range then
          NewString := GetText(Value, 255)
        else
          NewString := '';
        if Equal(NewString, CurString, SearchPos) then
        begin
          if Value <> OldValue then
          begin
            FocusItem(Value);
            SetCursor(Cursor.X + SearchPos, Cursor.Y);
          end
          else
            SetCursor(Cursor.X + (SearchPos - OldPos), Cursor.Y);
        end
        else
          SearchPos := OldPos;
      end
      else
        SearchPos := OldPos;
      if (SearchPos <> OldPos) or CharInSet(Event.CharCode, ['A'..'Z', 'a'..'z']) then
        ClearEvent(Event);
    end;
  end;
end;

function TSortedListBox.GetKey(var S: string): Pointer;
begin
  Result := @S;
end;

procedure TSortedListBox.NewList(AList: TObjectList<TObject>);
begin
  inherited NewList(AList);
  SearchPos := 0;
end;

{ Global Functions }

function Contains(S1, S2: String): Boolean;
var
  I: Byte;
begin
  Result := True;
  I := 1;
  while (I < Length(S2)) and (I < Length(S1)) do
    if UpCase(S1[I]) = UpCase(S2[I]) then
      Exit
    else
      Inc(I);
  Result := False;
end;

function StdDeleteFile(AFile: FNameStr): Boolean;
var
  Msg: string;
begin
  Result := False;
  if CheckOnDelete then
  begin
    AFile := ShrinkPath(AFile, 33);
    Msg := ^C + Format(sDeleteFile, [AFile]);
    Result := MessageBox(Msg, mfConfirmation or mfOkCancel) = cmOk;
  end;
end;

function DriveValid(Drive: Char): Boolean;
var
  OldMode: Cardinal;
begin
  OldMode := SetErrorMode(SEM_FAILCRITICALERRORS);
  try
    Result := GetDriveTypeW(PChar(Drive + ':\')) > DRIVE_NO_ROOT_DIR;
  finally
    SetErrorMode(OldMode);
  end;
end;

function Equal(const S1, S2: String; Count: Sw_Word): Boolean;
var
  I: Sw_Word;
begin
  Result := False;
  if (Length(S1) < Count) or (Length(S2) < Count) then
    Exit;
  for I := 1 to Count do
    if UpCase(S1[I]) <> UpCase(S2[I]) then
      Exit;
  Result := True;
end;

function ExtractDir(AFile: FNameStr): DirStr;
var
  D: DirStr;
  N: NameStr;
  E: ExtStr;
begin
  FSplit(AFile, D, N, E);
  if D = '' then
  begin
    Result := '';
    Exit;
  end;
  if D[Length(D)] <> DirSeparator then
    D := D + DirSeparator;
  Result := D;
end;

function ExtractFileName(AFile: FNameStr): NameStr;
var
  D: DirStr;
  N: NameStr;
  E: ExtStr;
begin
  FSplit(AFile, D, N, E);
  Result := N;
end;

function FileExists(AFile: FNameStr): Boolean;
begin
  Result := System.SysUtils.FileExists(AFile);
end;

function GetCurDir: DirStr;
var
  CurDir: DirStr;
begin
  System.GetDir(0, CurDir);
  if Length(CurDir) > 3 then
    CurDir := CurDir + DirSeparator;
  Result := CurDir;
end;

function GetCurDrive: Char;
var
  D: DirStr;
begin
  D := GetCurDir;
  if (Length(D) > 1) and (D[2] = ':') then
    Result := UpCase(D[1])
  else
    Result := 'C';
end;

function IsDir(const S: String): Boolean;
var
  SR: TSearchRec;
begin
  Result := (Length(S) = 3) and CharInSet(UpCase(S[1]), ['A'..'Z']) and (S[2] = ':') and (S[3] = DirSeparator);
  if not Result then
  begin
    DosFindFirst(S, Directory, SR);
    if DosError = 0 then
      Result := (SR.Attr and Directory) <> 0
    else
      Result := False;
    DosFindClose;
  end;
end;

function IsWild(const S: String): Boolean;
begin
  Result := (Pos('?', S) > 0) or (Pos('*', S) > 0);
end;

function IsList(const S: String): Boolean;
begin
  Result := Pos(ListSeparator, S) > 0;
end;

function NoWildChars(S: String): String;
var
  I: Integer;
begin
  repeat
    I := Pos('?', S);
    if I > 0 then
      System.Delete(S, I, 1);
  until I = 0;
  repeat
    I := Pos('*', S);
    if I > 0 then
      System.Delete(S, I, 1);
  until I = 0;
  Result := S;
end;

function OpenFile(var AFile: FNameStr; HistoryID: Byte): Boolean;
var
  Dlg: TFileDialog;
begin
  Dlg := TFileDialog.Create('*.*', sOpen, slName, fdOkButton or fdHelpButton, 0);
  THistory(Dlg.FileName.Next.Next).HistoryID := HistoryID;
  Result := Application.ExecuteDialog(Dlg, @AFile) = cmFileOpen;
end;

function OpenNewFile(var AFile: FNameStr; HistoryID: Byte): Boolean;
begin
  Result := False;
  if OpenFile(AFile, HistoryID) then
  begin
    if not ValidFileName(AFile) then
      Exit;
    if FileExists(AFile) then
      if (not CheckOnReplace) or (not ReplaceFile(AFile)) then
        Exit;
    Result := True;
  end;
end;

procedure RegisterStdDlg;
begin
  RegisterType(RFileInputLine);
  RegisterType(RFileCollection);
  RegisterType(RFileList);
  RegisterType(RFileInfoPane);
  RegisterType(RFileDialog);
  RegisterType(RDirCollection);
  RegisterType(RDirListBox);
  RegisterType(RSortedListBox);
  RegisterType(RChDirDialog);
end;

function StdReplaceFile(AFile: FNameStr): Boolean;
var
  Msg: string;
begin
  if CheckOnReplace then
  begin
    AFile := ShrinkPath(AFile, 33);
    Msg := ^C + Format(sReplaceFile, [AFile]);
    Result := MessageBox(Msg, mfConfirmation or mfOkCancel) = cmOk;
  end
  else
    Result := True;
end;

function SaveAs(var AFile: FNameStr; HistoryID: Word): Boolean;
var
  Dlg: TFileDialog;
begin
  Result := False;
  Dlg := TFileDialog.Create('*.*', sSaveAs, slSaveAs, fdOkButton or fdHelpButton, 0);
  THistory(Dlg.FileName.Next.Next).HistoryID := HistoryID;
  Dlg.HelpCtx := hcSaveAs;
  if (Application.ExecuteDialog(Dlg, @AFile) = cmFileOpen) and
     ((not FileExists(AFile)) or ReplaceFile(AFile)) then
    Result := True;
end;

function SelectDir(var ADir: DirStr; HistoryID: Byte): Boolean;
var
  Dir: DirStr;
  Dlg: TEditChDirDialog;
  Rec: DirStr;
begin
  {$I-}
  System.GetDir(0, Dir);
  {$I+}
  Rec := FExpand(ADir);
  Dlg := TEditChDirDialog.Create(cdHelpButton, HistoryID);
  if Application.ExecuteDialog(Dlg, @Rec) = cmOk then
  begin
    Result := True;
    ADir := Rec;
  end
  else
    Result := False;
  {$I-}
  System.ChDir(Dir);
  {$I+}
end;

function SelectFolder(var ADir: DirStr; HistoryID: Byte): Boolean;
var
  Dlg: TFolderSelectDialog;
  Rec: DirStr;
begin
  Rec := FExpand(ADir);
  Dlg := TFolderSelectDialog.Create(0, HistoryID);
  if Application.ExecuteDialog(Dlg, @Rec) = cmOk then
  begin
    Result := True;
    ADir := Rec;
  end
  else
    Result := False;
end;

function ShrinkPath(AFile: FNameStr; MaxLen: Byte): FNameStr;
var
  Filler: string;
  D1: DirStr;
  N1: NameStr;
  E1: ExtStr;
  I: Integer;
begin
  if Length(AFile) > MaxLen then
  begin
    FSplit(FExpand(AFile), D1, N1, E1);
    AFile := Copy(D1, 1, 3) + '..' + DirSeparator;
    I := Length(D1) - 1;
    while (I > 0) and (D1[I] <> DirSeparator) do
      Dec(I);
    if I = 0 then
      AFile := AFile + D1
    else
      AFile := AFile + Copy(D1, I + 1, Length(D1) - I);
    if AFile[Length(AFile)] <> DirSeparator then
      AFile := AFile + DirSeparator;
    if Length(AFile) + Length(N1) + Length(E1) <= MaxLen then
      AFile := AFile + N1 + E1
    else
    begin
      Filler := '...' + DirSeparator;
      AFile := Copy(AFile, 1, MaxLen - Length(Filler) - Length(N1) - Length(E1)) +
               Filler + N1 + E1;
    end;
  end;
  Result := AFile;
end;

function ValidFileName(var FileName: PathStr): Boolean;
const
  IllegalChars = ';,=+<>|"[]' + '\';
var
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
begin
  Result := True;
  FSplit(FileName, Dir, Name, Ext);
  if not ((Dir = '') or PathValid(Dir)) or
     Contains(Name, IllegalChars) or
     Contains(Dir, IllegalChars) then
    Result := False;
end;

initialization
  ReplaceFile := @StdReplaceFile;
  DeleteFile := @StdDeleteFile;

finalization
  if FileListKeyBufferInitialized then
    Finalize(FileListKeyBuffer);
end.
