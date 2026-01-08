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
  FVConsts, Objects, FVCommon, Drivers, Views, Dialogs, Validate, FVBoxChars;

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

  { TDirEntry }
  PDirEntry = ^TDirEntry;
  TDirEntry = record
    DisplayText: string;
    Directory: string;
  end;

  { TDirCollection - type-safe list of directory entries }
  TDirCollection = class(TList<PDirEntry>)
  public
    destructor Destroy; override;
    procedure FreeDirEntry(Item: PDirEntry);
    procedure ClearAll;
  end;

  { TDirListBox }
  TDirListBox = class(TListBox)
    Dir: DirStr;
    Cur: Word;
    Dirs: TDirCollection;  { Type-safe directory collection }
    constructor Create(var Bounds: TRect; AScrollBar: TScrollBar); reintroduce; virtual;
    destructor Destroy; override;
    function GetText(Item: Integer; MaxLen: Integer): string; override;
    procedure HandleEvent(var Event: TEvent); override;
    function IsSelected(Item: Integer): Boolean; override;
    procedure NewDirectory(var ADir: DirStr);
    procedure SetState(AState: Word; Enable: Boolean); override;
  end;

const
  cdNormal     = $0000;
  cdNoLoadDir  = $0001;
  cdHelpButton = $0002;

type
  { TChDirDialog }
  TChDirDialog = class(TDialog)
    DirInput: TInputLine;
    DirList: TDirListBox;
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

{ TDirCollection }

destructor TDirCollection.Destroy;
begin
  ClearAll;
  inherited Destroy;
end;

procedure TDirCollection.FreeDirEntry(Item: PDirEntry);
begin
  if Item = nil then Exit;
  { DisplayText and Directory are now managed strings - Dispose will finalize them }
  Dispose(Item);
end;

procedure TDirCollection.ClearAll;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    FreeDirEntry(Items[I]);
  Clear;
end;

{ TDirListBox }

var
  DrivesStr: string = '';

constructor TDirListBox.Create(var Bounds: TRect; AScrollBar: TScrollBar);
begin
  DrivesStr := sDrives;
  inherited Create(Bounds, 1, AScrollBar);
  Dir := '';
  Dirs := nil;
end;

destructor TDirListBox.Destroy;
begin
  SetState(sfVisible, False);
  FreeAndNil(Dirs);
  inherited Destroy;
end;

function TDirListBox.GetText(Item: Integer; MaxLen: Integer): string;
begin
  if (Dirs = nil) or (Item >= Dirs.Count) then
    Result := ''
  else
    Result := Dirs[Item]^.DisplayText;
end;

procedure TDirListBox.HandleEvent(var Event: TEvent);
var
  DirEntry: PDirEntry;
  DirName: DirStr;
begin
  case Event.What of
    evMouseDown:
      if Event.Double then
      begin
        Event.What := evCommand;
        Event.Command := cmChangeDir;
        PutEvent(Event);
        ClearEvent(Event);
      end;
    evKeyboard:
      if (Event.CharCode = AnsiChar(' ')) and (Dirs <> nil) and (Focused < Dirs.Count) then
      begin
        DirEntry := Dirs[Focused];
        if (DirEntry <> nil) and (DirEntry^.Directory <> '') then
        begin
          DirName := DirEntry^.Directory;
          if DirName = '..' then
            NewDirectory(DirName);
        end;
      end;
  end;
  inherited HandleEvent(Event);
end;

function TDirListBox.IsSelected(Item: Integer): Boolean;
begin
  Result := inherited IsSelected(Item);
end;

procedure TDirListBox.NewDirectory(var ADir: DirStr);
const
  { Tree drawing characters for directory tree display }
  { Matches Outline style: └── for expanded path, └─+ for collapsed subdirs }
  { PathDir: for current path components - expanded (children shown below) }
  PathDir: string = BoxBottomLeft + BoxHoriz + BoxHoriz;           { └── }
  { FirstDir: for first subdirectory - can be expanded }
  FirstDir: string = ' ' + BoxVertRight + BoxHoriz + '+';          { ├─+ }
  { MiddleDir: for middle subdirectories - can be expanded }
  MiddleDir: string = ' ' + BoxVertRight + BoxHoriz + '+';         { ├─+ }
  { LastDir: for last subdirectory - can be expanded }
  LastDir: string = ' ' + BoxBottomLeft + BoxHoriz + '+';          { └─+ }
  IndentSize = '  ';
var
  AList: TDirCollection;
  NewDir, Dirct: DirStr;
  C, OldC: Char;
  S, Indent: string;
  TempStr: string;
  NewCur: Word;
  IsFirst: Boolean;
  SR: TSearchRec;
  I: Integer;

  function NewDirEntry(const DisplayText, ADirectory: String): PDirEntry;
  var
    DirEntry: PDirEntry;
  begin
    New(DirEntry);
    DirEntry^.DisplayText := DisplayText;
    if ADirectory = '' then
      DirEntry^.Directory := DirSeparator
    else
      DirEntry^.Directory := ADirectory;
    Result := DirEntry;
  end;

begin
  Dir := ADir;
  AList := TDirCollection.Create;
  AList.Add(NewDirEntry(DrivesStr, DrivesStr));

  if Dir = DrivesStr then
  begin
    IsFirst := True;
    OldC := ' ';
    for C := 'A' to 'Z' do
    begin
      if DriveValid(C) then
      begin
        if OldC <> ' ' then
        begin
          if IsFirst then
          begin
            S := FirstDir + OldC;
            IsFirst := False;
          end
          else
            S := MiddleDir + OldC;
          AList.Add(NewDirEntry(S, OldC + ':' + DirSeparator));
        end;
        if C = GetCurDrive then
          NewCur := AList.Count;
        OldC := C;
      end;
    end;
    if OldC <> ' ' then
      AList.Add(NewDirEntry(LastDir + OldC, OldC + ':' + DirSeparator));
  end
  else
  begin
    Indent := IndentSize;
    NewDir := Dir;
    Dirct := Copy(NewDir, 1, 3);
    AList.Add(NewDirEntry(PathDir + string(Dirct), string(Dirct)));
    NewDir := Copy(NewDir, 4, 255);

    while NewDir <> '' do
    begin
      I := Pos(DirSeparator, string(NewDir));
      if I <> 0 then
      begin
        S := Copy(string(NewDir), 1, I - 1);
        Dirct := Dirct + DirStr(S);
        AList.Add(NewDirEntry(Indent + PathDir + S, string(Dirct)));
        NewDir := Copy(NewDir, I + 1, 255);
      end
      else
      begin
        Dirct := Dirct + NewDir;
        AList.Add(NewDirEntry(Indent + PathDir + string(NewDir), string(Dirct)));
        NewDir := '';
      end;
      Indent := Indent + IndentSize;
      Dirct := Dirct + DirSeparator;
    end;

    NewCur := AList.Count - 1;
    IsFirst := True;
    NewDir := Dirct + AllFiles;
    DosFindFirst(string(NewDir), Directory, SR);
    while DosError = 0 do
    begin
      if (SR.Attr and Directory <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        if IsFirst then
        begin
          S := FirstDir;
          IsFirst := False;
        end
        else
          S := MiddleDir;
        AList.Add(NewDirEntry(Indent + S + SR.Name, string(Dirct) + SR.Name));
      end;
      DosFindNext(SR);
    end;
    DosFindClose;

    { Fix last directory entry's tree drawing characters }
    { The last subdirectory should use LastDir (└─) instead of MiddleDir (├─) }
    if (AList.Count > 0) and not IsFirst then
    begin
      TempStr := AList[AList.Count - 1]^.DisplayText;
      { Find and replace the middle connector (├) with bottom corner (└) }
      I := Pos(BoxVertRight, TempStr);
      if I > 0 then
      begin
        TempStr[I] := BoxBottomLeft;
        AList[AList.Count - 1]^.DisplayText := TempStr;
      end;
    end;
  end;

  { Replace old Dirs with new list }
  FreeAndNil(Dirs);
  Dirs := AList;
  SetRange(Dirs.Count);
  FocusItem(NewCur);
  Cur := NewCur;
end;

procedure TDirListBox.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState and sfFocused <> 0 then
    TChDirDialog(Owner).ChDirButton.MakeDefault(Enable);
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
  DirList := TDirListBox.Create(R, TScrollBar(Control));
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
  DirList := TDirListBox(GetSubViewPtr(S, Self));
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
  P: PDirEntry;
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
              P := DirList.Dirs[DirList.Focused];
              if (P^.Directory = DrivesStr) or DriveValid(Char(P^.Directory[1])) then
                CurDir := P^.Directory
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
