{*******************************************************}
{       Free Vision Grid Unit                          }
{       TStringGrid - Terminal-based string grid       }
{       Modern Delphi 12+ version                      }
{*******************************************************}

unit Grid;

{$R-}  { Disable range checking for legacy buffer operations }

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  System.StrUtils, System.JSON,
  FVCommon, Objects, Drivers, Views, FVConsts, FVInterfaces, Validate, FVBoxChars;

{***************************************************************************}
{                              PUBLIC CONSTANTS                             }
{***************************************************************************}

const
  { Grid command constants (150-169 range) }
  cmGridCellFocused      = 150;  { Broadcast when cell focus changes }
  cmGridSelectionChanged = 151;  { Broadcast when selection changes }
  cmGridBeginEdit        = 152;  { Internal: start editing }
  cmGridEndEdit          = 153;  { Internal: end editing }
  cmGridCancelEdit       = 154;  { Internal: cancel editing }
  cmGridSortColumn       = 155;  { Command to sort by column }
  cmGridCellChanged      = 156;  { Broadcast when cell content changes }

  { Grid type ID for serialization }
  idStringGrid = 120;

  { TStringGrid palette - 6 colors mapped to dialog palette indices }
  { Based on TListViewer pattern - each entry is a complete color attribute }
  { 1: Normal/Active cell     -> dialog #26 (list viewer active)
    2: Normal/Inactive cell   -> dialog #26 (list viewer inactive)
    3: Focused cell           -> dialog #27 (list viewer focused)
    4: Selected cell          -> dialog #28 (list viewer selected)
    5: Grid lines/divider     -> dialog #29 (list viewer divider)
    6: Header cell            -> dialog #7 (label normal - distinct) }
  CStringGrid = #26#26#27#28#29#7;

  { Arrow characters for overflow indicators }
  LeftArrow  = SmallArrowLeft;
  RightArrow = SmallArrowRight;

  { Box drawing characters - Unicode }
  GridHLine  = BoxHoriz;      { ─ }
  GridVLine  = BoxVert;       { │ }
  GridCross  = BoxCross;      { ┼ }
  GridTTop   = BoxHorizDown;  { ┬ }
  GridTBot   = BoxHorizUp;    { ┴ }
  GridTLeft  = BoxVertRight;  { ├ }
  GridTRight = BoxVertLeft;   { ┤ }

  { Sort direction indicators }
  SortAscChar  = SmallArrowUp;    { ▲ }
  SortDescChar = SmallArrowDown;  { ▼ }

{***************************************************************************}
{                            TYPE DEFINITIONS                               }
{***************************************************************************}

type
  { Forward declarations }
  TStringGrid = class;
  TGridColumn = class;
  TGridColumns = class;
  TCSVOptions = class;

  { Enumerations }
  TGridAlignment = (gaLeft, gaCenter, gaRight);
  TSelectionMode = (smRow, smCell);
  TEditMode = (emNone, emF2, emEnter, emTyping);
  TSortDirection = (sdNone, sdAscending, sdDescending);

  { CSV support types }
  TCSVDelimiter = (cdComma, cdSemicolon, cdTab, cdPipe, cdAuto);
  TCSVEncoding = (ceUTF8BOM, ceUTF8, ceANSI);

  { TGridCell - cell coordinate record }
  TGridCell = record
    Col: Integer;
    Row: Integer;
    class function Create(ACol, ARow: Integer): TGridCell; static;
    function Equals(const Other: TGridCell): Boolean;
  end;

  { TGridChangeEntry - change log entry for tracking edits }
  TGridChangeEntry = record
    Cell: TGridCell;
    OldValue: string;
    NewValue: string;
  end;
  PGridChangeEntry = ^TGridChangeEntry;

  { TCSVOptions - CSV import/export configuration }
  TCSVOptions = class(TObject)
  private
    FDelimiter: TCSVDelimiter;
    FCustomDelimiter: Char;
    FEncoding: TCSVEncoding;
    FHasHeaders: Boolean;
    FUseFixedHeaderRow: Boolean;
    FTrimWhitespace: Boolean;
    FAutoCreateColumns: Boolean;
  public
    constructor Create;
    property Delimiter: TCSVDelimiter read FDelimiter write FDelimiter;
    property CustomDelimiter: Char read FCustomDelimiter write FCustomDelimiter;
    property Encoding: TCSVEncoding read FEncoding write FEncoding;
    property HasHeaders: Boolean read FHasHeaders write FHasHeaders;
    property UseFixedHeaderRow: Boolean read FUseFixedHeaderRow write FUseFixedHeaderRow;
    property TrimWhitespace: Boolean read FTrimWhitespace write FTrimWhitespace;
    property AutoCreateColumns: Boolean read FAutoCreateColumns write FAutoCreateColumns;
  end;

  { Event callback types }
  TGridCellEvent = procedure(Sender: TObject; Col, Row: Integer) of object;
  TGridEditEvent = procedure(Sender: TObject; Col, Row: Integer; var AllowEdit: Boolean) of object;
  TGridValidateEvent = procedure(Sender: TObject; Col, Row: Integer;
    const Value: string; var Accept: Boolean) of object;
  TGridCompareEvent = procedure(Sender: TObject; Col: Integer;
    const S1, S2: string; var Result: Integer) of object;
  TGridGetCellEvent = procedure(Sender: TObject; Col, Row: Integer;
    var CellText: string) of object;

  { TGridColumn - column definition }
  TGridColumn = class(TObject)
  private
    FTitle: string;
    FWidth: Integer;
    FMinWidth: Integer;
    FMaxWidth: Integer;
    FAlignment: TGridAlignment;
    FColor: Byte;
    FSortable: Boolean;
    FVisible: Boolean;
    FValidator: TValidator;
    FDefaultValue: string;
    function GetTitle: string;
    procedure SetTitle(const Value: string);
    function GetDefaultValue: string;
    procedure SetDefaultValue(const Value: string);
    procedure SetWidth(Value: Integer);
    procedure SetValidator(Value: TValidator);
  public
    constructor Create(const ATitle: string; AWidth: Integer);
    destructor Destroy; override;

    property Title: string read GetTitle write SetTitle;
    property Width: Integer read FWidth write SetWidth;
    property MinWidth: Integer read FMinWidth write FMinWidth;
    property MaxWidth: Integer read FMaxWidth write FMaxWidth;
    property Alignment: TGridAlignment read FAlignment write FAlignment;
    property Color: Byte read FColor write FColor;
    property Sortable: Boolean read FSortable write FSortable;
    property Visible: Boolean read FVisible write FVisible;
    property Validator: TValidator read FValidator write SetValidator;
    property DefaultValue: string read GetDefaultValue write SetDefaultValue;
  end;

  { TGridColumns - column collection }
  TGridColumns = class(TObjectList<TGridColumn>)
  private
    FOwner: TStringGrid;
  public
    constructor Create(AOwner: TStringGrid);
    function Add(const ATitle: string; AWidth: Integer): TGridColumn;
    function Insert(Index: Integer; const ATitle: string; AWidth: Integer): TGridColumn;
    procedure MoveColumn(FromIndex, ToIndex: Integer);
    function TotalWidth: Integer;
    function ColumnAtX(X: Integer; var ColStart: Integer): Integer;
    function VisibleCount: Integer;
  end;

  { TStringGrid - main grid component }
  TStringGrid = class(TView, ISerializable)
  private
    { Data storage - using TDictionary for sparse storage }
    FData: TDictionary<string, string>;
    FRowCount: Integer;
    FRowIDs: TList<Integer>;
    FNextRowID: Integer;

    { Column management }
    FColumns: TGridColumns;

    { Selection state }
    FFocusedCell: TGridCell;
    FSelectionMode: TSelectionMode;
    FSelectedCells: TList<TGridCell>;
    FAnchorCell: TGridCell;

    { Scrolling }
    FTopRow: Integer;
    FLeftCol: Integer;
    FHScrollBar: TScrollBar;
    FVScrollBar: TScrollBar;

    { Fixed rows/cols }
    FFixedRows: Integer;
    FFixedCols: Integer;

    { Display options }
    FShowGridLines: Boolean;

    { Editing }
    FEditMode: TEditMode;
    FEditing: Boolean;
    FEditCell: TGridCell;
    FOldEditValue: string;

    { Change tracking }
    FModified: Boolean;
    FChangeLog: TList<TGridChangeEntry>;
    FUndoEntry: TGridChangeEntry;
    FHasUndo: Boolean;

    { Sorting }
    FSortColumn: Integer;
    FSortDirection: TSortDirection;

    { Virtual mode }
    FVirtualMode: Boolean;
    FVirtualRowCount: Integer;
    FOnGetCell: TGridGetCellEvent;

    { Column filter }
    FShowFilterRow: Boolean;
    FColumnFilters: TArray<string>;
    FFilteredRows: TList<Integer>;
    FFilterDirty: Boolean;

    { Column resize }
    FResizingCol: Integer;
    FResizeStartX: Integer;
    FResizeOrigWidth: Integer;

    { Filter row editing }
    FFilterFocusedCol: Integer;
    FFilterCursorPos: Integer;
    FFilterActive: Boolean;  { True when filter row has focus }

    { Event callbacks }
    FOnCellFocused: TGridCellEvent;
    FOnSelectionChanged: TNotifyEvent;
    FOnBeforeEdit: TGridEditEvent;
    FOnAfterEdit: TGridCellEvent;
    FOnValidateCell: TGridValidateEvent;
    FOnCompare: TGridCompareEvent;

    { Property getters/setters }
    function GetColCount: Integer;
    function GetCell(Col, Row: Integer): string;
    procedure SetCell(Col, Row: Integer; const Value: string);
    procedure SetRowCount(Value: Integer);
    procedure SetFixedRows(Value: Integer);
    procedure SetFixedCols(Value: Integer);
    procedure SetShowGridLines(Value: Boolean);
    function GetFocusedCol: Integer;
    function GetFocusedRow: Integer;

    { Internal helpers }
    function CellKey(Col, Row: Integer): string;
    procedure EnsureRowID(Row: Integer);

  protected
    { Drawing helpers }
    procedure DrawCell(Col, Row, ScreenX, ScreenY, CellWidth: Integer;
      var B: TDrawBuffer; IsFocused, IsSelected: Boolean);
    function GetCellColor(Col, Row: Integer; IsFocused, IsSelected: Boolean): Word;
    function GetCellText(Col, Row: Integer): string;
    function FormatCellText(const Text: string; Width: Integer;
      Alignment: TGridAlignment): string;

    { Navigation helpers }
    function RowToScreen(Row: Integer): Integer;
    function ScreenToRow(Y: Integer): Integer;
    function ColToScreen(Col: Integer): Integer;
    function ScreenToCol(X: Integer): Integer;
    procedure EnsureCellVisible(Col, Row: Integer);
    procedure UpdateScrollBars;

    { Selection helpers }
    procedure ClearSelection;
    procedure SelectCell(Col, Row: Integer);
    procedure SelectRange(FromCell, ToCell: TGridCell);
    procedure ToggleSelection(Col, Row: Integer);
    function IsCellSelected(Col, Row: Integer): Boolean;
    function IsRowSelected(Row: Integer): Boolean;

    { Focus management }
    procedure FocusCell(Col, Row: Integer; Extend: Boolean);

    { Validation }
    function ValidateCell(Col, Row: Integer; const Value: string): Boolean;

    { Sorting helpers }
    procedure DoSort;
    function CompareRows(Row1, Row2: Integer): Integer;

  public
    constructor Create(var Bounds: TRect; AColCount: Integer;
      AHScrollBar, AVScrollBar: TScrollBar); reintroduce; virtual;
    destructor Destroy; override;

    { TView overrides }
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    function GetPalette: PPalette; override;
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure ChangeBounds(var Bounds: TRect); override;

    { IFVDataAware implementation }
    function DataSize: Word; override;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
    function Valid(Command: Word): Boolean; override;

    { Cell access }
    property Cells[Col, Row: Integer]: string read GetCell write SetCell; default;

    { Row management }
    procedure AddRow;
    procedure InsertRow(AtRow: Integer);
    procedure DeleteRow(AtRow: Integer);
    procedure ClearRows;
    procedure ClearAll;
    function GetRowID(Row: Integer): Integer;
    function RowFromID(ID: Integer): Integer;

    { Selection access }
    function GetSelectedRows: TArray<Integer>;
    function GetSelectedCells: TArray<TGridCell>;

    { Clipboard }
    procedure CopyToClipboard;
    procedure PasteFromClipboard;

    { CSV Import/Export }
    procedure LoadFromCSV(const FileName: string; Options: TCSVOptions = nil);
    procedure SaveToCSV(const FileName: string; Options: TCSVOptions = nil);
    procedure LoadFromCSVStream(Stream: TStream; Options: TCSVOptions = nil);
    procedure SaveToCSVStream(Stream: TStream; Options: TCSVOptions = nil);
    procedure LoadFromCSVString(const CSVData: string; Options: TCSVOptions = nil);
    function SaveToCSVString(Options: TCSVOptions = nil): string;

    { Undo }
    procedure Undo;
    function CanUndo: Boolean;

    { Change tracking }
    procedure ResetModified;
    function GetChangeLog: TArray<TGridChangeEntry>;

    { Column auto-fit }
    procedure AutoFitColumn(Col: Integer);
    procedure AutoFitAllColumns;

    { Sorting }
    procedure Sort(Col: Integer; Direction: TSortDirection);

    { Properties - Data }
    property RowCount: Integer read FRowCount write SetRowCount;
    property ColCount: Integer read GetColCount;
    property Columns: TGridColumns read FColumns;

    { Properties - Display }
    property FixedRows: Integer read FFixedRows write SetFixedRows;
    property FixedCols: Integer read FFixedCols write SetFixedCols;
    property ShowGridLines: Boolean read FShowGridLines write SetShowGridLines;

    { Properties - Selection }
    property FocusedCol: Integer read GetFocusedCol;
    property FocusedRow: Integer read GetFocusedRow;
    property SelectionMode: TSelectionMode read FSelectionMode write FSelectionMode;

    { Properties - Editing }
    property EditMode: TEditMode read FEditMode write FEditMode;

    { Properties - State }
    property Modified: Boolean read FModified;

    { Properties - Sorting }
    property SortColumn: Integer read FSortColumn;
    property SortDirection: TSortDirection read FSortDirection;

    { Properties - Scrollbars }
    property HScrollBar: TScrollBar read FHScrollBar;
    property VScrollBar: TScrollBar read FVScrollBar;

    { Events }
    property OnCellFocused: TGridCellEvent read FOnCellFocused write FOnCellFocused;
    property OnSelectionChanged: TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
    property OnBeforeEdit: TGridEditEvent read FOnBeforeEdit write FOnBeforeEdit;
    property OnAfterEdit: TGridCellEvent read FOnAfterEdit write FOnAfterEdit;
    property OnValidateCell: TGridValidateEvent read FOnValidateCell write FOnValidateCell;
    property OnCompare: TGridCompareEvent read FOnCompare write FOnCompare;
    property OnGetCell: TGridGetCellEvent read FOnGetCell write FOnGetCell;

    { Virtual mode }
    property VirtualMode: Boolean read FVirtualMode write FVirtualMode;
    property VirtualRowCount: Integer read FVirtualRowCount write FVirtualRowCount;

    { Column filtering }
    property ShowFilterRow: Boolean read FShowFilterRow write FShowFilterRow;
    procedure SetColumnFilter(Col: Integer; const AFilter: string);
    function GetColumnFilter(Col: Integer): string;
    procedure ClearFilters;
    procedure ApplyFilters;
    function GetVisibleRowCount: Integer;
    function VisibleToDataRow(VisibleRow: Integer): Integer;

    { ISerializable - persists layout (columns, settings), not cell data }
    function ToJSON: TJSONObject; override;
    procedure FromJSON(const AJson: TJSONObject); override;
    function GetTypeId: string; override;
  end;

var
  { Module-level clipboard for grid copy/paste }
  GridClipboard: string = '';

implementation

uses
  FVSerialization, FVUTF8, FVClipboard;

{***************************************************************************}
{                            TGridCell                                      }
{***************************************************************************}

class function TGridCell.Create(ACol, ARow: Integer): TGridCell;
begin
  Result.Col := ACol;
  Result.Row := ARow;
end;

function TGridCell.Equals(const Other: TGridCell): Boolean;
begin
  Result := (Col = Other.Col) and (Row = Other.Row);
end;

{***************************************************************************}
{                            TCSVOptions                                    }
{***************************************************************************}

constructor TCSVOptions.Create;
begin
  inherited Create;
  FDelimiter := cdComma;
  FCustomDelimiter := #0;  { #0 means use Delimiter enum }
  FEncoding := ceUTF8BOM;
  FHasHeaders := True;
  FUseFixedHeaderRow := False;
  FTrimWhitespace := False;
  FAutoCreateColumns := True;
end;

{***************************************************************************}
{                          CSV Helper Functions                             }
{***************************************************************************}

function GetDelimiterChar(Delim: TCSVDelimiter): Char;
begin
  case Delim of
    cdComma:     Result := ',';
    cdSemicolon: Result := ';';
    cdTab:       Result := #9;
    cdPipe:      Result := '|';
  else
    Result := ',';  { Default for cdAuto }
  end;
end;

function QuoteCSVField(const Value: string; Delimiter: Char): string;
var
  NeedsQuoting: Boolean;
  I: Integer;
begin
  { Check if quoting is needed per RFC 4180 }
  NeedsQuoting := False;
  for I := 1 to Length(Value) do
  begin
    if (Value[I] = Delimiter) or (Value[I] = '"') or
       (Value[I] = #13) or (Value[I] = #10) then
    begin
      NeedsQuoting := True;
      Break;
    end;
  end;

  if not NeedsQuoting then
    Result := Value
  else
    { Quote the field and escape embedded quotes by doubling them }
    Result := '"' + StringReplace(Value, '"', '""', [rfReplaceAll]) + '"';
end;

function CountDelimitersOutsideQuotes(const Line: string; Delim: Char): Integer;
var
  I: Integer;
  InQuotes: Boolean;
begin
  Result := 0;
  InQuotes := False;
  for I := 1 to Length(Line) do
  begin
    if Line[I] = '"' then
      InQuotes := not InQuotes
    else if (Line[I] = Delim) and (not InQuotes) then
      Inc(Result);
  end;
end;

function DetectDelimiter(const Data: string): TCSVDelimiter;
const
  Candidates: array[0..3] of TCSVDelimiter = (cdComma, cdSemicolon, cdTab, cdPipe);
  CandidateChars: array[0..3] of Char = (',', ';', #9, '|');
var
  Lines: TStringList;
  I, J, LineCount: Integer;
  Counts: array[0..3] of Integer;
  FirstLineCounts: array[0..3] of Integer;
  Consistent: array[0..3] of Boolean;
  BestIdx: Integer;
  BestCount: Integer;
begin
  Result := cdComma;  { Default }

  Lines := TStringList.Create;
  try
    Lines.Text := Data;
    LineCount := Min(Lines.Count, 5);  { Analyze first 5 lines }
    if LineCount = 0 then Exit;

    { Initialize }
    for I := 0 to 3 do
    begin
      FirstLineCounts[I] := 0;
      Consistent[I] := True;
    end;

    { Count delimiters in each line }
    for J := 0 to LineCount - 1 do
    begin
      for I := 0 to 3 do
      begin
        Counts[I] := CountDelimitersOutsideQuotes(Lines[J], CandidateChars[I]);
        if J = 0 then
          FirstLineCounts[I] := Counts[I]
        else if Counts[I] <> FirstLineCounts[I] then
          Consistent[I] := False;
      end;
    end;

    { Find best delimiter: highest consistent count }
    BestIdx := 0;
    BestCount := 0;
    for I := 0 to 3 do
    begin
      if Consistent[I] and (FirstLineCounts[I] > BestCount) then
      begin
        BestCount := FirstLineCounts[I];
        BestIdx := I;
      end;
    end;

    if BestCount > 0 then
      Result := Candidates[BestIdx];
  finally
    Lines.Free;
  end;
end;

type
  TCSVParserState = (psFieldStart, psUnquotedField, psQuotedField, psQuoteInQuoted);

procedure ParseCSVLine(const Line: string; Delimiter: Char; var Fields: TArray<string>);
var
  State: TCSVParserState;
  Field: TStringBuilder;
  I: Integer;
  C: Char;
  FieldList: TList<string>;
begin
  FieldList := TList<string>.Create;
  Field := TStringBuilder.Create;
  try
    State := psFieldStart;

    for I := 1 to Length(Line) do
    begin
      C := Line[I];

      case State of
        psFieldStart:
          begin
            if C = '"' then
              State := psQuotedField
            else if C = Delimiter then
            begin
              FieldList.Add(Field.ToString);
              Field.Clear;
            end
            else if (C = #13) or (C = #10) then
            begin
              { End of line - emit field }
              FieldList.Add(Field.ToString);
              Field.Clear;
            end
            else
            begin
              Field.Append(C);
              State := psUnquotedField;
            end;
          end;

        psUnquotedField:
          begin
            if C = Delimiter then
            begin
              FieldList.Add(Field.ToString);
              Field.Clear;
              State := psFieldStart;
            end
            else if (C = #13) or (C = #10) then
            begin
              FieldList.Add(Field.ToString);
              Field.Clear;
              State := psFieldStart;
            end
            else
              Field.Append(C);
          end;

        psQuotedField:
          begin
            if C = '"' then
              State := psQuoteInQuoted
            else
              Field.Append(C);
          end;

        psQuoteInQuoted:
          begin
            if C = '"' then
            begin
              { Escaped quote - add single quote and continue }
              Field.Append('"');
              State := psQuotedField;
            end
            else if C = Delimiter then
            begin
              FieldList.Add(Field.ToString);
              Field.Clear;
              State := psFieldStart;
            end
            else if (C = #13) or (C = #10) then
            begin
              FieldList.Add(Field.ToString);
              Field.Clear;
              State := psFieldStart;
            end
            else
            begin
              { Recovery: treat quote as end of field, start new unquoted }
              FieldList.Add(Field.ToString);
              Field.Clear;
              Field.Append(C);
              State := psUnquotedField;
            end;
          end;
      end;
    end;

    { Handle final field }
    if (State <> psFieldStart) or (FieldList.Count > 0) or (Field.Length > 0) then
      FieldList.Add(Field.ToString);

    Fields := FieldList.ToArray;
  finally
    Field.Free;
    FieldList.Free;
  end;
end;

procedure ParseCSV(const Data: string; Delimiter: Char;
  var Rows: TArray<TArray<string>>);
var
  State: TCSVParserState;
  Field: TStringBuilder;
  Row: TList<string>;
  RowList: TList<TArray<string>>;
  I: Integer;
  C: Char;
begin
  RowList := TList<TArray<string>>.Create;
  Row := TList<string>.Create;
  Field := TStringBuilder.Create;
  try
    State := psFieldStart;
    I := 1;
    while I <= Length(Data) do
    begin
      C := Data[I];

      case State of
        psFieldStart:
          begin
            if C = '"' then
              State := psQuotedField
            else if C = Delimiter then
            begin
              Row.Add(Field.ToString);
              Field.Clear;
            end
            else if (C = #13) or (C = #10) then
            begin
              if (Row.Count > 0) or (Field.Length > 0) then
              begin
                Row.Add(Field.ToString);
                Field.Clear;
                RowList.Add(Row.ToArray);
                Row.Clear;
              end;
              if (C = #13) and (I < Length(Data)) and (Data[I + 1] = #10) then
                Inc(I);
            end
            else
            begin
              Field.Append(C);
              State := psUnquotedField;
            end;
          end;

        psUnquotedField:
          begin
            if C = Delimiter then
            begin
              Row.Add(Field.ToString);
              Field.Clear;
              State := psFieldStart;
            end
            else if (C = #13) or (C = #10) then
            begin
              Row.Add(Field.ToString);
              Field.Clear;
              RowList.Add(Row.ToArray);
              Row.Clear;
              State := psFieldStart;
              if (C = #13) and (I < Length(Data)) and (Data[I + 1] = #10) then
                Inc(I);
            end
            else
              Field.Append(C);
          end;

        psQuotedField:
          begin
            if C = '"' then
              State := psQuoteInQuoted
            else
              Field.Append(C);
          end;

        psQuoteInQuoted:
          begin
            if C = '"' then
            begin
              { Escaped quote }
              Field.Append('"');
              State := psQuotedField;
            end
            else if C = Delimiter then
            begin
              Row.Add(Field.ToString);
              Field.Clear;
              State := psFieldStart;
            end
            else if (C = #13) or (C = #10) then
            begin
              Row.Add(Field.ToString);
              Field.Clear;
              RowList.Add(Row.ToArray);
              Row.Clear;
              State := psFieldStart;
              if (C = #13) and (I < Length(Data)) and (Data[I + 1] = #10) then
                Inc(I);
            end
            else
            begin
              { Recovery for malformed CSV }
              Field.Append(C);
              State := psUnquotedField;
            end;
          end;
      end;

      Inc(I);
    end;

    { Emit trailing field/row at EOF }
    if (State <> psFieldStart) or (Row.Count > 0) or (Field.Length > 0) then
    begin
      Row.Add(Field.ToString);
      RowList.Add(Row.ToArray);
    end;

    Rows := RowList.ToArray;
  finally
    Field.Free;
    Row.Free;
    RowList.Free;
  end;
end;

{***************************************************************************}
{                            TGridColumn                                    }
{***************************************************************************}

constructor TGridColumn.Create(const ATitle: string; AWidth: Integer);
begin
  inherited Create;
  FTitle := string(ATitle);
  FWidth := AWidth;
  FMinWidth := 3;
  FMaxWidth := MaxViewWidth;
  FAlignment := gaLeft;
  FColor := 0;  { Use default palette }
  FSortable := True;
  FVisible := True;
  FValidator := nil;
  FDefaultValue := '';
end;

destructor TGridColumn.Destroy;
begin
  { FTitle and FDefaultValue are managed strings - no need to dispose }
  FreeAndNil(FValidator);
  inherited Destroy;
end;

function TGridColumn.GetTitle: string;
begin
  Result := FTitle;
end;

procedure TGridColumn.SetTitle(const Value: string);
begin
  FTitle := Value;
end;

function TGridColumn.GetDefaultValue: string;
begin
  Result := FDefaultValue;
end;

procedure TGridColumn.SetDefaultValue(const Value: string);
begin
  FDefaultValue := string(Value);
end;

procedure TGridColumn.SetWidth(Value: Integer);
begin
  if Value < FMinWidth then
    Value := FMinWidth;
  if Value > FMaxWidth then
    Value := FMaxWidth;
  FWidth := Value;
end;

procedure TGridColumn.SetValidator(Value: TValidator);
begin
  FreeAndNil(FValidator);
  FValidator := Value;
end;

{***************************************************************************}
{                            TGridColumns                                   }
{***************************************************************************}

constructor TGridColumns.Create(AOwner: TStringGrid);
begin
  inherited Create(True);  { OwnsObjects = True }
  FOwner := AOwner;
end;

function TGridColumns.Add(const ATitle: string; AWidth: Integer): TGridColumn;
begin
  Result := TGridColumn.Create(ATitle, AWidth);
  inherited Add(Result);
end;

function TGridColumns.Insert(Index: Integer; const ATitle: string;
  AWidth: Integer): TGridColumn;
begin
  Result := TGridColumn.Create(ATitle, AWidth);
  inherited Insert(Index, Result);
end;

procedure TGridColumns.MoveColumn(FromIndex, ToIndex: Integer);
var
  Col: TGridColumn;
begin
  if (FromIndex >= 0) and (FromIndex < Count) and
     (ToIndex >= 0) and (ToIndex < Count) and
     (FromIndex <> ToIndex) then
  begin
    Col := Items[FromIndex];
    Extract(Col);  { Remove without freeing }
    inherited Insert(ToIndex, Col);
  end;
end;

function TGridColumns.TotalWidth: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
    if Items[I].Visible then
      Inc(Result, Items[I].Width);
end;

function TGridColumns.ColumnAtX(X: Integer; var ColStart: Integer): Integer;
var
  I, CurrentX: Integer;
begin
  Result := -1;
  ColStart := 0;
  CurrentX := 0;

  for I := 0 to Count - 1 do
  begin
    if Items[I].Visible then
    begin
      if (X >= CurrentX) and (X < CurrentX + Items[I].Width) then
      begin
        Result := I;
        ColStart := CurrentX;
        Exit;
      end;
      Inc(CurrentX, Items[I].Width);
      if FOwner.ShowGridLines then
        Inc(CurrentX);  { Account for grid line }
    end;
  end;
end;

function TGridColumns.VisibleCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
    if Items[I].Visible then
      Inc(Result);
end;

{***************************************************************************}
{                            TStringGrid                                    }
{***************************************************************************}

constructor TStringGrid.Create(var Bounds: TRect; AColCount: Integer;
  AHScrollBar, AVScrollBar: TScrollBar);
var
  I: Integer;
begin
  inherited Create(Bounds);

  { Set options }
  Options := Options or ofSelectable or ofFirstClick;
  EventMask := EventMask or evMouseDown or evKeyDown or evBroadcast;
  GrowMode := gfGrowHiX or gfGrowHiY;

  { Initialize data structures }
  FData := TDictionary<string, string>.Create;
  FRowIDs := TList<Integer>.Create;
  FNextRowID := 1;
  FRowCount := 0;

  { Create columns }
  FColumns := TGridColumns.Create(Self);
  for I := 0 to AColCount - 1 do
    FColumns.Add('Column ' + IntToStr(I + 1), 10);

  { Selection }
  FFocusedCell := TGridCell.Create(0, 0);
  FAnchorCell := TGridCell.Create(0, 0);
  FSelectionMode := smRow;
  FSelectedCells := TList<TGridCell>.Create;

  { Scrolling }
  FTopRow := 0;
  FLeftCol := 0;
  FHScrollBar := AHScrollBar;
  FVScrollBar := AVScrollBar;

  { Fixed rows/cols }
  FFixedRows := 1;  { Default: 1 header row }
  FFixedCols := 0;

  { Display }
  FShowGridLines := True;

  { Editing }
  FEditMode := emF2;
  FEditing := False;

  { Change tracking }
  FModified := False;
  FChangeLog := TList<TGridChangeEntry>.Create;
  FHasUndo := False;

  { Sorting }
  FSortColumn := -1;
  FSortDirection := sdNone;

  { Virtual mode }
  FVirtualMode := False;
  FVirtualRowCount := 0;

  { Filtering }
  FShowFilterRow := False;
  SetLength(FColumnFilters, AColCount);
  FFilteredRows := TList<Integer>.Create;
  FFilterDirty := True;

  { Column resize }
  FResizingCol := -1;

  { Filter row }
  FFilterFocusedCol := 0;
  FFilterCursorPos := 0;
  FFilterActive := False;
end;

destructor TStringGrid.Destroy;
begin
  FreeAndNil(FFilteredRows);
  FreeAndNil(FChangeLog);
  FreeAndNil(FSelectedCells);
  FreeAndNil(FRowIDs);
  FreeAndNil(FColumns);
  FreeAndNil(FData);
  inherited Destroy;
end;

{--- Property getters/setters ---}

function TStringGrid.GetColCount: Integer;
begin
  Result := FColumns.Count;
end;

function TStringGrid.CellKey(Col, Row: Integer): string;
begin
  Result := IntToStr(Col) + ',' + IntToStr(Row);
end;

function TStringGrid.GetCell(Col, Row: Integer): string;
begin
  if not FData.TryGetValue(CellKey(Col, Row), Result) then
    Result := '';
end;

procedure TStringGrid.SetCell(Col, Row: Integer; const Value: string);
begin
  if Value = '' then
    FData.Remove(CellKey(Col, Row))
  else
    FData.AddOrSetValue(CellKey(Col, Row), Value);
end;

procedure TStringGrid.SetRowCount(Value: Integer);
var
  I: Integer;
begin
  if Value < 0 then Value := 0;

  { If reducing row count, remove data for deleted rows }
  if Value < FRowCount then
  begin
    for I := Value to FRowCount - 1 do
    begin
      { Remove row data }
      for var C := 0 to ColCount - 1 do
        FData.Remove(CellKey(C, I));
    end;
  end;

  FRowCount := Value;

  { Ensure row IDs exist }
  while FRowIDs.Count < FRowCount do
  begin
    FRowIDs.Add(FNextRowID);
    Inc(FNextRowID);
  end;

  { Trim excess row IDs }
  while FRowIDs.Count > FRowCount do
    FRowIDs.Delete(FRowIDs.Count - 1);

  { Adjust focused cell if needed }
  if FFocusedCell.Row >= FRowCount then
    FFocusedCell.Row := Max(0, FRowCount - 1);

  UpdateScrollBars;
  DrawView;
end;

procedure TStringGrid.SetFixedRows(Value: Integer);
begin
  if Value < 0 then Value := 0;
  FFixedRows := Value;
  DrawView;
end;

procedure TStringGrid.SetFixedCols(Value: Integer);
begin
  if Value < 0 then Value := 0;
  FFixedCols := Value;
  DrawView;
end;

procedure TStringGrid.SetShowGridLines(Value: Boolean);
begin
  if FShowGridLines <> Value then
  begin
    FShowGridLines := Value;
    DrawView;
  end;
end;

function TStringGrid.GetFocusedCol: Integer;
begin
  Result := FFocusedCell.Col;
end;

function TStringGrid.GetFocusedRow: Integer;
begin
  Result := FFocusedCell.Row;
end;

procedure TStringGrid.EnsureRowID(Row: Integer);
begin
  while FRowIDs.Count <= Row do
  begin
    FRowIDs.Add(FNextRowID);
    Inc(FNextRowID);
  end;
end;

{--- Drawing ---}

function TStringGrid.GetPalette: PPalette;
const
  P: TPalette = CStringGrid;
begin
  Result := @P;
end;

function TStringGrid.GetCellText(Col, Row: Integer): string;
begin
  if FVirtualMode and Assigned(FOnGetCell) then begin
    Result := '';
    FOnGetCell(Self, Col, Row, Result);
    Exit;
  end;
  Result := GetCell(Col, Row);
  { If empty, show default value }
  if (Result = '') and (Col < FColumns.Count) then
    Result := FColumns[Col].DefaultValue;
end;

{ Returns True if the character is a wide (East Asian Wide) character
  that takes 2 columns on the terminal }
function IsWideChar(C: Char): Boolean;
begin
  Result := IsWideCodePoint(Ord(C));
end;

{ Calculates the display width of a string in terminal columns.
  Wide characters (CJK, emoji) count as 2 columns, others as 1.
  Handles surrogate pairs correctly. }
function DisplayWidth(const S: string): Integer;
begin
  Result := StringDisplayWidth(S);
end;

{ Returns a substring of S that fits in MaxWidth display columns.
  Handles surrogate pairs correctly. }
function TruncateToWidth(const S: string; MaxWidth: Integer): string;
var
  I, Len, Width, W: Integer;
  CP: Cardinal;
begin
  Width := 0;
  Len := Length(S);
  I := 1;
  while I <= Len do
  begin
    { Check for surrogate pair }
    if (I < Len) and
       (Ord(S[I]) >= $D800) and (Ord(S[I]) <= $DBFF) and
       (Ord(S[I+1]) >= $DC00) and (Ord(S[I+1]) <= $DFFF) then
    begin
      CP := $10000 + Cardinal((Ord(S[I]) - $D800) shl 10) + Cardinal(Ord(S[I+1]) - $DC00);
      W := CodePointCharWidth(CP);
      if Width + W > MaxWidth then
      begin
        Result := Copy(S, 1, I - 1);
        Exit;
      end;
      Inc(Width, W);
      Inc(I, 2);
    end
    else
    begin
      W := CodePointCharWidth(Ord(S[I]));
      if Width + W > MaxWidth then
      begin
        Result := Copy(S, 1, I - 1);
        Exit;
      end;
      Inc(Width, W);
      Inc(I);
    end;
  end;
  Result := S;
end;

function TStringGrid.FormatCellText(const Text: string; Width: Integer;
  Alignment: TGridAlignment): string;
var
  TextWidth, Pad: Integer;
begin
  TextWidth := DisplayWidth(Text);
  if TextWidth >= Width then
  begin
    { Truncate text to fit, accounting for wide characters }
    Result := TruncateToWidth(Text, Width);
    Exit;
  end;

  Pad := Width - TextWidth;
  case Alignment of
    gaLeft:
      Result := Text + StringOfChar(' ', Pad);
    gaCenter:
      Result := StringOfChar(' ', Pad div 2) + Text +
                StringOfChar(' ', Pad - (Pad div 2));
    gaRight:
      Result := StringOfChar(' ', Pad) + Text;
  else
    Result := Text;
  end;
end;

function TStringGrid.GetCellColor(Col, Row: Integer;
  IsFocused, IsSelected: Boolean): Word;
begin
  if Row < FFixedRows then
    { Header row - use distinct header color }
    Result := GetColor(6)
  else if IsFocused then
    { Focused cell }
    Result := GetColor(3)
  else if IsSelected then
    { Selected cell }
    Result := GetColor(4)
  else if (State and (sfSelected + sfActive)) = (sfSelected + sfActive) then
    { Normal cell in active view }
    Result := GetColor(1)
  else
    { Normal cell in inactive view }
    Result := GetColor(2);
end;

procedure TStringGrid.DrawCell(Col, Row, ScreenX, ScreenY, CellWidth: Integer;
  var B: TDrawBuffer; IsFocused, IsSelected: Boolean);
var
  Text, DisplayText: string;
  Color: Word;
  Alignment: TGridAlignment;
  ShowRightArrow: Boolean;
  I, FillPos, TextWidth: Integer;
begin
  { Get color }
  Color := GetCellColor(Col, Row, IsFocused, IsSelected);

  { Get text and alignment }
  if Row < FFixedRows then
  begin
    { Header row - show column title with sort indicator }
    if Col < FColumns.Count then
    begin
      Text := FColumns[Col].Title;
      if (Col = FSortColumn) and (FSortDirection <> sdNone) then
      begin
        if FSortDirection = sdAscending then
          Text := Text + ' ' + SortAscChar
        else
          Text := Text + ' ' + SortDescChar;
      end;
    end
    else
      Text := '';
    Alignment := gaCenter;
  end
  else
  begin
    Text := GetCellText(Col, Row);
    if Col < FColumns.Count then
      Alignment := FColumns[Col].Alignment
    else
      Alignment := gaLeft;
  end;

  { Check for overflow using display width }
  TextWidth := DisplayWidth(Text);
  ShowRightArrow := TextWidth > CellWidth;

  { Format text to fit cell width }
  if ShowRightArrow and (CellWidth > 0) then
    DisplayText := TruncateToWidth(Text, CellWidth - 1)
  else
    DisplayText := FormatCellText(Text, CellWidth, Alignment);

  if CellWidth <= 0 then Exit;

  { Fill cell area first so stale content never leaks into short strings }
  for I := 0 to CellWidth - 1 do
  begin
    FillPos := ScreenX + I;
    if FillPos >= MaxViewWidth then Break;
    if FillPos >= 0 then
    begin
      B[FillPos].Ch := ' ';
      B[FillPos].Attr := Color;
    end;
  end;

  { Draw text with Unicode-aware routine (handles surrogate pairs/wide glyphs) }
  if (ScreenX >= 0) and (ScreenX < MaxViewWidth) then
    DrawStr(B, ScreenX, DisplayText, Color);

  { Draw overflow arrows - use grid line color for visibility }
  if ShowRightArrow then
  begin
    FillPos := ScreenX + CellWidth - 1;
    if (FillPos >= 0) and (FillPos < MaxViewWidth) then
    begin
      B[FillPos].Ch := RightArrow;
      B[FillPos].Attr := GetColor(5);
    end;
  end;
end;

procedure TStringGrid.Draw;
var
  B: TDrawBuffer;
  I, J, K, Row, ScreenY, ScreenX, ColWidth, ScrollVisibleIndex: Integer;
  IsFocused, IsSelected: Boolean;
  NormalColor, GridLineColor: Word;
begin
  NormalColor := GetColor(1);       { Normal cell color }
  GridLineColor := GetColor(5);     { Grid lines/divider color }

  ScreenY := 0;

  { Draw fixed header rows first }
  for I := 0 to FFixedRows - 1 do
  begin
    if ScreenY >= Size.Y then Break;

    { Clear buffer using new TDrawCell format }
    for K := 0 to Size.X - 1 do
    begin
      B[K].Ch := ' ';
      B[K].Attr := NormalColor;
    end;
    ScreenX := 0;

    { Draw fixed columns }
    for J := 0 to FFixedCols - 1 do
    begin
      if (J < FColumns.Count) and FColumns[J].Visible then
      begin
        ColWidth := FColumns[J].Width;
        if ScreenX + ColWidth > Size.X then
          ColWidth := Size.X - ScreenX;
        if ColWidth > 0 then
        begin
          DrawCell(J, I, ScreenX, ScreenY, ColWidth, B, False, False);
          Inc(ScreenX, ColWidth);
          { Grid line }
          if FShowGridLines and (ScreenX < Size.X) then
          begin
            B[ScreenX].Ch := GridVLine;
            B[ScreenX].Attr := GridLineColor;
            Inc(ScreenX);
          end;
        end;
      end;
    end;

    { Draw scrollable columns }
    ScrollVisibleIndex := 0;
    for J := FFixedCols to FColumns.Count - 1 do
    begin
      if ScreenX >= Size.X then Break;
      if FColumns[J].Visible then
      begin
        if ScrollVisibleIndex < FLeftCol then
        begin
          Inc(ScrollVisibleIndex);
          Continue;
        end;
        ColWidth := FColumns[J].Width;
        if ScreenX + ColWidth > Size.X then
          ColWidth := Size.X - ScreenX;
        if ColWidth > 0 then
        begin
          DrawCell(J, I, ScreenX, ScreenY, ColWidth, B, False, False);
          Inc(ScreenX, ColWidth);
          { Grid line }
          if FShowGridLines and (ScreenX < Size.X) then
          begin
            B[ScreenX].Ch := GridVLine;
            B[ScreenX].Attr := GridLineColor;
            Inc(ScreenX);
          end;
        end;
        Inc(ScrollVisibleIndex);
      end;
    end;

    WriteLine(0, ScreenY, Size.X, 1, B);
    Inc(ScreenY);

    { Draw horizontal grid line below header }
    if FShowGridLines and (I = FFixedRows - 1) and (ScreenY < Size.Y) then
    begin
      for K := 0 to Size.X - 1 do
      begin
        B[K].Ch := GridHLine;
        B[K].Attr := GridLineColor;
      end;
      { Draw intersections at column boundaries }
      ScreenX := 0;
      for J := 0 to FColumns.Count - 1 do
      begin
        if FColumns[J].Visible then
        begin
          Inc(ScreenX, FColumns[J].Width);
          if ScreenX < Size.X then
          begin
            B[ScreenX].Ch := GridTTop;
            B[ScreenX].Attr := GridLineColor;
            Inc(ScreenX);
          end;
        end;
      end;
      WriteLine(0, ScreenY, Size.X, 1, B);
      Inc(ScreenY);
    end;
  end;

  { Draw filter row if enabled }
  if FShowFilterRow and (ScreenY < Size.Y) then begin
    for K := 0 to Size.X - 1 do begin
      B[K].Ch := ' ';
      B[K].Attr := $1F; { white on blue - filter input style }
    end;
    ScreenX := 0;
    ScrollVisibleIndex := 0;
    for J := 0 to FColumns.Count - 1 do begin
      if ScreenX >= Size.X then Break;
      if not FColumns[J].Visible then Continue;
      if (J >= FFixedCols) and (ScrollVisibleIndex < FLeftCol) then begin
        Inc(ScrollVisibleIndex);
        Continue;
      end;
      ColWidth := FColumns[J].Width;
      if ScreenX + ColWidth > Size.X then
        ColWidth := Size.X - ScreenX;
      if ColWidth > 0 then begin
        { Draw filter text }
        var FilterText: string;
        if J < Length(FColumnFilters) then
          FilterText := FColumnFilters[J]
        else
          FilterText := '';
        var FilterColor: Byte;
        if FFilterActive and (J = FFilterFocusedCol) then
          FilterColor := $3F  { white on cyan - active filter }
        else
          FilterColor := $1F; { white on blue }
        for K := 0 to ColWidth - 1 do begin
          if ScreenX + K < Size.X then begin
            if K < Length(FilterText) then
              B[ScreenX + K].Ch := FilterText[K + 1]
            else
              B[ScreenX + K].Ch := ' ';
            B[ScreenX + K].Attr := FilterColor;
          end;
        end;
        Inc(ScreenX, ColWidth);
        { Grid line }
        if FShowGridLines and (ScreenX < Size.X) then begin
          B[ScreenX].Ch := GridVLine;
          B[ScreenX].Attr := GridLineColor;
          Inc(ScreenX);
        end;
      end;
      if J >= FFixedCols then
        Inc(ScrollVisibleIndex);
    end;
    WriteLine(0, ScreenY, Size.X, 1, B);
    Inc(ScreenY);
  end;

  { Apply pending filters before drawing data }
  if FShowFilterRow and FFilterDirty then
    ApplyFilters;

  { Draw data rows (starting after fixed rows) }
  for I := 0 to Size.Y - ScreenY - 1 do
  begin
    if FShowFilterRow then begin
      var VisIdx := FTopRow + I;
      if VisIdx < FFilteredRows.Count then
        Row := FFilteredRows[VisIdx]
      else
        Row := FRowCount; { Past end — will draw empty }
    end else
      Row := FFixedRows + FTopRow + I;  { Data rows start at FFixedRows }

    { Clear buffer using new TDrawCell format }
    for K := 0 to Size.X - 1 do
    begin
      B[K].Ch := ' ';
      B[K].Attr := NormalColor;
    end;

    if Row < FRowCount then
    begin
      ScreenX := 0;

      { Draw fixed columns }
      for J := 0 to FFixedCols - 1 do
      begin
        if (J < FColumns.Count) and FColumns[J].Visible then
        begin
          ColWidth := FColumns[J].Width;
          if ScreenX + ColWidth > Size.X then
            ColWidth := Size.X - ScreenX;
          if ColWidth > 0 then
          begin
            IsFocused := (State and sfFocused <> 0) and
                         FFocusedCell.Equals(TGridCell.Create(J, Row));
            IsSelected := IsCellSelected(J, Row) or IsRowSelected(Row);
            DrawCell(J, Row, ScreenX, ScreenY + I, ColWidth, B, IsFocused, IsSelected);
            Inc(ScreenX, ColWidth);
            { Grid line }
            if FShowGridLines and (ScreenX < Size.X) then
            begin
              B[ScreenX].Ch := GridVLine;
              B[ScreenX].Attr := GridLineColor;
              Inc(ScreenX);
            end;
          end;
        end;
      end;

      { Draw scrollable columns }
      ScrollVisibleIndex := 0;
      for J := FFixedCols to FColumns.Count - 1 do
      begin
        if ScreenX >= Size.X then Break;
        if FColumns[J].Visible then
        begin
          if ScrollVisibleIndex < FLeftCol then
          begin
            Inc(ScrollVisibleIndex);
            Continue;
          end;
          ColWidth := FColumns[J].Width;
          if ScreenX + ColWidth > Size.X then
            ColWidth := Size.X - ScreenX;
          if ColWidth > 0 then
          begin
            IsFocused := (State and sfFocused <> 0) and
                         FFocusedCell.Equals(TGridCell.Create(J, Row));
            IsSelected := IsCellSelected(J, Row) or IsRowSelected(Row);
            DrawCell(J, Row, ScreenX, ScreenY + I, ColWidth, B, IsFocused, IsSelected);
            Inc(ScreenX, ColWidth);
            { Grid line }
            if FShowGridLines and (ScreenX < Size.X) then
            begin
              B[ScreenX].Ch := GridVLine;
              B[ScreenX].Attr := GridLineColor;
              Inc(ScreenX);
            end;
          end;
          Inc(ScrollVisibleIndex);
        end;
      end;
    end;

    WriteLine(0, ScreenY + I, Size.X, 1, B);
  end;
end;

{--- Navigation helpers ---}

function TStringGrid.RowToScreen(Row: Integer): Integer;
var
  HeaderHeight: Integer;
begin
  HeaderHeight := FFixedRows;
  if FShowGridLines and (FFixedRows > 0) then
    Inc(HeaderHeight);  { Grid line below header }

  if Row < FFixedRows then
    Result := Row
  else
    Result := HeaderHeight + (Row - FTopRow);
end;

function TStringGrid.ScreenToRow(Y: Integer): Integer;
var
  HeaderHeight: Integer;
begin
  HeaderHeight := FFixedRows;
  if FShowGridLines and (FFixedRows > 0) then
    Inc(HeaderHeight);

  if Y < FFixedRows then
    Result := Y  { Fixed row index (0..FFixedRows-1) }
  else if Y < HeaderHeight then
    Result := -1  { On grid line }
  else
    { Data rows: add FFixedRows offset to get actual row index }
    Result := FFixedRows + FTopRow + (Y - HeaderHeight);
end;

function TStringGrid.ColToScreen(Col: Integer): Integer;
var
  I, X, ScrollVisibleIndex: Integer;
begin
  Result := -1;
  if (Col < 0) or (Col >= FColumns.Count) then Exit;

  X := 0;
  ScrollVisibleIndex := 0;
  for I := 0 to FColumns.Count - 1 do
  begin
    if not FColumns[I].Visible then
      Continue;

    if I >= FFixedCols then
    begin
      if ScrollVisibleIndex < FLeftCol then
      begin
        Inc(ScrollVisibleIndex);
        Continue;
      end;
    end;

    if I = Col then
    begin
      Result := X;
      Exit;
    end;

    Inc(X, FColumns[I].Width);
    if FShowGridLines then
      Inc(X);
    if X >= Size.X then
      Exit;

    if I >= FFixedCols then
      Inc(ScrollVisibleIndex);
  end;
end;

function TStringGrid.ScreenToCol(X: Integer): Integer;
var
  I, CurrentX, ColWidth, ScrollVisibleIndex: Integer;
begin
  Result := -1;
  if (X < 0) or (X >= Size.X) then Exit;

  CurrentX := 0;
  ScrollVisibleIndex := 0;
  for I := 0 to FColumns.Count - 1 do
  begin
    if not FColumns[I].Visible then
      Continue;

    if I >= FFixedCols then
    begin
      if ScrollVisibleIndex < FLeftCol then
      begin
        Inc(ScrollVisibleIndex);
        Continue;
      end;
    end;

    ColWidth := FColumns[I].Width;
    if CurrentX + ColWidth > Size.X then
      ColWidth := Size.X - CurrentX;
    if ColWidth <= 0 then Break;

    if (X >= CurrentX) and (X < CurrentX + ColWidth) then
    begin
      Result := I;
      Exit;
    end;

    Inc(CurrentX, ColWidth);
    if FShowGridLines and (CurrentX < Size.X) then
    begin
      if X = CurrentX then
        Exit;  { On grid line }
      Inc(CurrentX);
    end;

    if I >= FFixedCols then
      Inc(ScrollVisibleIndex);

    if CurrentX >= Size.X then Break;
  end;
end;

procedure TStringGrid.EnsureCellVisible(Col, Row: Integer);
var
  VisibleRows: Integer;
  ScrollableCols: TList<Integer>;
  I, TargetIndex, StartIndex, FixedWidth: Integer;
  function GetFixedAreaWidth: Integer;
  var
    C, W: Integer;
  begin
    Result := 0;
    for C := 0 to FFixedCols - 1 do
    begin
      if (C >= FColumns.Count) or (not FColumns[C].Visible) then
        Continue;
      W := FColumns[C].Width;
      if Result + W > Size.X then
        W := Size.X - Result;
      if W <= 0 then Break;
      Inc(Result, W);
      if FShowGridLines and (Result < Size.X) then
        Inc(Result);
    end;
  end;
  function IsTargetVisible(AStartIndex: Integer): Boolean;
  var
    K, ColIndex, X, W: Integer;
  begin
    Result := False;
    X := FixedWidth;
    for K := AStartIndex to ScrollableCols.Count - 1 do
    begin
      if X >= Size.X then Break;
      ColIndex := ScrollableCols[K];
      W := FColumns[ColIndex].Width;
      if X + W > Size.X then
        W := Size.X - X;
      if W <= 0 then Break;
      if ColIndex = Col then
      begin
        Result := True;
        Exit;
      end;
      Inc(X, W);
      if FShowGridLines and (X < Size.X) then
        Inc(X);
    end;
  end;
begin
  { Vertical scrolling }
  VisibleRows := Size.Y - FFixedRows;
  if FShowGridLines and (FFixedRows > 0) then
    Dec(VisibleRows);

  if Row < FTopRow then
    FTopRow := Row
  else if Row >= FTopRow + VisibleRows then
    FTopRow := Row - VisibleRows + 1;

  { Horizontal scrolling - handle frozen columns }
  if Col >= FFixedCols then
  begin
    ScrollableCols := TList<Integer>.Create;
    try
      for I := FFixedCols to FColumns.Count - 1 do
        if FColumns[I].Visible then
          ScrollableCols.Add(I);

      if ScrollableCols.Count = 0 then
        FLeftCol := 0
      else
      begin
        TargetIndex := ScrollableCols.IndexOf(Col);
        if TargetIndex >= 0 then
        begin
          if FLeftCol < 0 then
            FLeftCol := 0;
          if FLeftCol > ScrollableCols.Count - 1 then
            FLeftCol := ScrollableCols.Count - 1;

          FixedWidth := GetFixedAreaWidth;
          StartIndex := FLeftCol;
          if not IsTargetVisible(StartIndex) then
          begin
            if TargetIndex < StartIndex then
              StartIndex := TargetIndex
            else
              while (StartIndex < TargetIndex) and (not IsTargetVisible(StartIndex)) do
                Inc(StartIndex);

            { Keep the target visible while showing as much leading context as possible }
            while (StartIndex > 0) and IsTargetVisible(StartIndex - 1) do
              Dec(StartIndex);

            FLeftCol := StartIndex;
          end;
        end;
      end;
    finally
      ScrollableCols.Free;
    end;
  end;

  UpdateScrollBars;
end;

procedure TStringGrid.UpdateScrollBars;
var
  MaxRow, MaxCol, VisibleRows, DataRows: Integer;
begin
  VisibleRows := Size.Y - FFixedRows;
  if FShowGridLines and (FFixedRows > 0) then
    Dec(VisibleRows);

  { DataRows = total rows minus fixed header rows }
  DataRows := FRowCount - FFixedRows;
  MaxRow := DataRows - VisibleRows;
  if MaxRow < 0 then MaxRow := 0;

  MaxCol := FColumns.VisibleCount - FFixedCols - 1;
  if MaxCol < 0 then MaxCol := 0;

  if FVScrollBar <> nil then
    FVScrollBar.SetParams(FTopRow, 0, MaxRow, Max(1, VisibleRows - 1), 1);

  if FHScrollBar <> nil then
    FHScrollBar.SetParams(FLeftCol, 0, MaxCol, 1, 1);
end;

{--- Selection helpers ---}

procedure TStringGrid.ClearSelection;
begin
  FSelectedCells.Clear;
end;

procedure TStringGrid.SelectCell(Col, Row: Integer);
var
  Cell: TGridCell;
begin
  ClearSelection;
  Cell := TGridCell.Create(Col, Row);
  FSelectedCells.Add(Cell);

  { Broadcast selection change }
  Message(Owner, evBroadcast, cmGridSelectionChanged, Self);
  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

procedure TStringGrid.SelectRange(FromCell, ToCell: TGridCell);
var
  MinCol, MaxCol, MinRow, MaxRow, C, R: Integer;
  Cell: TGridCell;
begin
  ClearSelection;
  MinCol := Min(FromCell.Col, ToCell.Col);
  MaxCol := Max(FromCell.Col, ToCell.Col);
  MinRow := Min(FromCell.Row, ToCell.Row);
  MaxRow := Max(FromCell.Row, ToCell.Row);

  if FSelectionMode = smRow then
  begin
    { Select entire rows }
    for R := MinRow to MaxRow do
      for C := 0 to ColCount - 1 do
      begin
        Cell := TGridCell.Create(C, R);
        FSelectedCells.Add(Cell);
      end;
  end
  else
  begin
    { Select cell range }
    for R := MinRow to MaxRow do
      for C := MinCol to MaxCol do
      begin
        Cell := TGridCell.Create(C, R);
        FSelectedCells.Add(Cell);
      end;
  end;

  { Broadcast selection change }
  Message(Owner, evBroadcast, cmGridSelectionChanged, Self);
  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

procedure TStringGrid.ToggleSelection(Col, Row: Integer);
var
  Cell: TGridCell;
  I: Integer;
begin
  Cell := TGridCell.Create(Col, Row);

  { Check if already selected }
  for I := FSelectedCells.Count - 1 downto 0 do
  begin
    if FSelectedCells[I].Equals(Cell) then
    begin
      FSelectedCells.Delete(I);
      Exit;
    end;
  end;

  { Add to selection }
  FSelectedCells.Add(Cell);
end;

function TStringGrid.IsCellSelected(Col, Row: Integer): Boolean;
var
  Cell: TGridCell;
  I: Integer;
begin
  Result := False;
  Cell := TGridCell.Create(Col, Row);
  for I := 0 to FSelectedCells.Count - 1 do
  begin
    if FSelectedCells[I].Equals(Cell) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TStringGrid.IsRowSelected(Row: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  if FSelectionMode <> smRow then Exit;

  for I := 0 to FSelectedCells.Count - 1 do
  begin
    if FSelectedCells[I].Row = Row then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure TStringGrid.FocusCell(Col, Row: Integer; Extend: Boolean);
var
  OldCell: TGridCell;
begin
  { Clamp to valid range }
  if Col < 0 then Col := 0;
  if Col >= ColCount then Col := ColCount - 1;
  if Row < FFixedRows then Row := FFixedRows;
  if Row >= FRowCount then Row := FRowCount - 1;

  OldCell := FFocusedCell;
  FFocusedCell := TGridCell.Create(Col, Row);

  if Extend then
    { Extend selection from anchor }
    SelectRange(FAnchorCell, FFocusedCell)
  else
  begin
    { Set new anchor and single selection }
    FAnchorCell := FFocusedCell;
    SelectCell(Col, Row);
  end;

  EnsureCellVisible(Col, Row);

  { Broadcast focus change }
  if not OldCell.Equals(FFocusedCell) then
  begin
    Message(Owner, evBroadcast, cmGridCellFocused, Self);
    if Assigned(FOnCellFocused) then
      FOnCellFocused(Self, Col, Row);
  end;

  DrawView;
end;

{--- Validation ---}

function TStringGrid.ValidateCell(Col, Row: Integer;
  const Value: string): Boolean;
var
  Accept: Boolean;
begin
  Result := True;

  { Check column validator }
  if (Col < FColumns.Count) and (FColumns[Col].Validator <> nil) then
  begin
    Result := FColumns[Col].Validator.IsValid(Value);
    if not Result then Exit;
  end;

  { Check OnValidateCell callback }
  if Assigned(FOnValidateCell) then
  begin
    Accept := True;
    FOnValidateCell(Self, Col, Row, Value, Accept);
    Result := Accept;
  end;
end;

{--- Event handling ---}

procedure TStringGrid.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  Col, Row: Integer;
  ShiftState: Byte;
  Extend: Boolean;
begin
  inherited HandleEvent(Event);

  case Event.What of
    evKeyDown:
    begin
      { Filter row input handling }
      if FShowFilterRow and FFilterActive then begin
        case Event.KeyCode of
          kbEsc: begin
            FFilterActive := False;
            DrawView;
            ClearEvent(Event);
          end;
          kbTab: begin
            if FFilterFocusedCol < FColumns.Count - 1 then
              Inc(FFilterFocusedCol)
            else begin
              FFilterFocusedCol := 0;
              FFilterActive := False;  { Leave filter row }
            end;
            FFilterCursorPos := Length(GetColumnFilter(FFilterFocusedCol));
            DrawView;
            ClearEvent(Event);
          end;
          kbEnter: begin
            FFilterActive := False;
            ApplyFilters;
            DrawView;
            ClearEvent(Event);
          end;
          kbBack: begin
            var F := GetColumnFilter(FFilterFocusedCol);
            if Length(F) > 0 then begin
              SetColumnFilter(FFilterFocusedCol, Copy(F, 1, Length(F) - 1));
              ApplyFilters;
              DrawView;
            end;
            ClearEvent(Event);
          end;
        else
          if (Event.UnicodeChar >= ' ') then begin
            var F := GetColumnFilter(FFilterFocusedCol);
            SetColumnFilter(FFilterFocusedCol, F + Event.UnicodeChar);
            ApplyFilters;
            DrawView;
            ClearEvent(Event);
          end;
        end;
        if Event.What = evNothing then Exit;
      end;

      { Ctrl+F activates filter row }
      if FShowFilterRow and (Event.KeyCode = kbCtrlF) then begin
        FFilterActive := True;
        FFilterFocusedCol := FFocusedCell.Col;
        if FFilterFocusedCol < 0 then FFilterFocusedCol := 0;
        FFilterCursorPos := Length(GetColumnFilter(FFilterFocusedCol));
        DrawView;
        ClearEvent(Event);
        Exit;
      end;

      ShiftState := Event.KeyCode shr 8;
      Extend := (ShiftState and $03) <> 0;  { Shift pressed }

      case CtrlToArrow(Event.KeyCode) of
        kbUp:
        begin
          if FFocusedCell.Row > FFixedRows then
            FocusCell(FFocusedCell.Col, FFocusedCell.Row - 1, Extend);
          ClearEvent(Event);
        end;
        kbDown:
        begin
          if FFocusedCell.Row < FRowCount - 1 then
            FocusCell(FFocusedCell.Col, FFocusedCell.Row + 1, Extend);
          ClearEvent(Event);
        end;
        kbLeft:
        begin
          if FFocusedCell.Col > 0 then
            FocusCell(FFocusedCell.Col - 1, FFocusedCell.Row, Extend);
          ClearEvent(Event);
        end;
        kbRight:
        begin
          if FFocusedCell.Col < ColCount - 1 then
            FocusCell(FFocusedCell.Col + 1, FFocusedCell.Row, Extend);
          ClearEvent(Event);
        end;
        kbHome:
        begin
          if (ShiftState and $04) <> 0 then  { Ctrl+Home }
            FocusCell(0, FFixedRows, Extend)
          else
            FocusCell(0, FFocusedCell.Row, Extend);
          ClearEvent(Event);
        end;
        kbEnd:
        begin
          if (ShiftState and $04) <> 0 then  { Ctrl+End }
            FocusCell(ColCount - 1, FRowCount - 1, Extend)
          else
            FocusCell(ColCount - 1, FFocusedCell.Row, Extend);
          ClearEvent(Event);
        end;
        kbPgUp:
        begin
          FocusCell(FFocusedCell.Col,
            Max(FFixedRows, FFocusedCell.Row - (Size.Y - FFixedRows)), Extend);
          ClearEvent(Event);
        end;
        kbPgDn:
        begin
          FocusCell(FFocusedCell.Col,
            Min(FRowCount - 1, FFocusedCell.Row + (Size.Y - FFixedRows)), Extend);
          ClearEvent(Event);
        end;
        kbCtrlIns:  { Copy }
        begin
          CopyToClipboard;
          ClearEvent(Event);
        end;
        kbShiftIns:  { Paste }
        begin
          PasteFromClipboard;
          ClearEvent(Event);
        end;
      end;
    end;

    evMouseDown:
    begin
      { Handle mouse wheel scrolling first - scroll viewport, not focus }
      if Event.Buttons and mbScrollWheelUp <> 0 then
      begin
        if FTopRow > 0 then
        begin
          FTopRow := Max(0, FTopRow - 3);
          UpdateScrollBars;
          DrawView;
        end;
        ClearEvent(Event);
        Exit;
      end;
      if Event.Buttons and mbScrollWheelDown <> 0 then
      begin
        if FTopRow < FRowCount - FFixedRows - 1 then
        begin
          FTopRow := Min(FRowCount - FFixedRows - 1, FTopRow + 3);
          UpdateScrollBars;
          DrawView;
        end;
        ClearEvent(Event);
        Exit;
      end;

      MakeLocal(Event.Where, Mouse);

      { Check if click is on filter row }
      if FShowFilterRow then begin
        var FilterRowY := FFixedRows;
        if FShowGridLines then Inc(FilterRowY);
        if Mouse.Y = FilterRowY then begin
          Col := ScreenToCol(Mouse.X);
          if (Col >= 0) and (Col < FColumns.Count) then begin
            FFilterActive := True;
            FFilterFocusedCol := Col;
            FFilterCursorPos := Length(GetColumnFilter(Col));
            DrawView;
          end;
          ClearEvent(Event);
          Exit;
        end;
      end;

      Col := ScreenToCol(Mouse.X);
      Row := ScreenToRow(Mouse.Y);

      { Deactivate filter when clicking on data/header }
      if FFilterActive then begin
        FFilterActive := False;
        DrawView;
      end;

      if (Col >= 0) and (Row >= 0) then
      begin
        ShiftState := GetShiftState;
        Extend := (ShiftState and kbLeftShift) <> 0;

        if Row < FFixedRows then
        begin
          { Header click - sort }
          if (Col < FColumns.Count) and FColumns[Col].Sortable then
          begin
            if FSortColumn = Col then
            begin
              if FSortDirection = sdAscending then
                Sort(Col, sdDescending)
              else
                Sort(Col, sdNone);
            end
            else
              Sort(Col, sdAscending);
          end;
          ClearEvent(Event);
        end
        else if Row < FRowCount then
        begin
          { Data cell click }
          if (ShiftState and kbCtrlShift) <> 0 then
            { Ctrl+Click - toggle selection }
            ToggleSelection(Col, Row)
          else
            FocusCell(Col, Row, Extend);
          ClearEvent(Event);
        end;
        { Don't clear event if click wasn't handled - let parent handle it }
      end;
    end;

    evBroadcast:
    begin
      if Event.Command = cmScrollBarChanged then
      begin
        if Event.InfoPtr = FVScrollBar then
        begin
          FTopRow := FVScrollBar.Value;
          DrawView;
        end
        else if Event.InfoPtr = FHScrollBar then
        begin
          FLeftCol := FHScrollBar.Value;
          DrawView;
        end;
      end;
    end;
  end;
end;

procedure TStringGrid.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if AState = sfFocused then
    DrawView;
end;

procedure TStringGrid.ChangeBounds(var Bounds: TRect);
begin
  inherited ChangeBounds(Bounds);
  UpdateScrollBars;
end;

{--- IFVDataAware implementation ---}

function TStringGrid.DataSize: Word;
begin
  Result := 0;  { Grid uses Cells property, not data transfer }
end;

procedure TStringGrid.GetData(var Rec);
begin
  { Not used - grid uses Cells property }
end;

procedure TStringGrid.SetData(var Rec);
begin
  { Not used - grid uses Cells property }
end;

function TStringGrid.Valid(Command: Word): Boolean;
begin
  Result := True;
end;

{--- Row management ---}

procedure TStringGrid.AddRow;
begin
  SetRowCount(FRowCount + 1);
end;

procedure TStringGrid.InsertRow(AtRow: Integer);
var
  I, C: Integer;
  TempData: TDictionary<string, string>;
  Pair: TPair<string, string>;
  Col, Row: Integer;
begin
  if AtRow < 0 then AtRow := 0;
  if AtRow > FRowCount then AtRow := FRowCount;

  { Shift existing data down }
  TempData := TDictionary<string, string>.Create;
  try
    for Pair in FData do
    begin
      { Parse key to get col,row }
      I := Pos(',', Pair.Key);
      if I > 0 then
      begin
        Col := StrToIntDef(Copy(Pair.Key, 1, I - 1), -1);
        Row := StrToIntDef(Copy(Pair.Key, I + 1, Length(Pair.Key)), -1);
        if (Col >= 0) and (Row >= AtRow) then
          TempData.AddOrSetValue(CellKey(Col, Row + 1), Pair.Value)
        else
          TempData.AddOrSetValue(Pair.Key, Pair.Value);
      end;
    end;

    FData.Clear;
    for Pair in TempData do
      FData.AddOrSetValue(Pair.Key, Pair.Value);
  finally
    TempData.Free;
  end;

  { Insert new row ID }
  FRowIDs.Insert(AtRow, FNextRowID);
  Inc(FNextRowID);
  Inc(FRowCount);

  UpdateScrollBars;
  DrawView;
end;

procedure TStringGrid.DeleteRow(AtRow: Integer);
var
  I, C: Integer;
  TempData: TDictionary<string, string>;
  Pair: TPair<string, string>;
  Col, Row: Integer;
begin
  if (AtRow < 0) or (AtRow >= FRowCount) then Exit;

  { Remove row data and shift remaining data up }
  TempData := TDictionary<string, string>.Create;
  try
    for Pair in FData do
    begin
      I := Pos(',', Pair.Key);
      if I > 0 then
      begin
        Col := StrToIntDef(Copy(Pair.Key, 1, I - 1), -1);
        Row := StrToIntDef(Copy(Pair.Key, I + 1, Length(Pair.Key)), -1);
        if Row < AtRow then
          TempData.AddOrSetValue(Pair.Key, Pair.Value)
        else if Row > AtRow then
          TempData.AddOrSetValue(CellKey(Col, Row - 1), Pair.Value);
        { Row = AtRow is deleted }
      end;
    end;

    FData.Clear;
    for Pair in TempData do
      FData.AddOrSetValue(Pair.Key, Pair.Value);
  finally
    TempData.Free;
  end;

  { Remove row ID }
  FRowIDs.Delete(AtRow);
  Dec(FRowCount);

  { Adjust focused cell }
  if FFocusedCell.Row >= FRowCount then
    FFocusedCell.Row := Max(0, FRowCount - 1);

  UpdateScrollBars;
  DrawView;
end;

procedure TStringGrid.ClearRows;
begin
  FData.Clear;
  FRowIDs.Clear;
  FRowCount := 0;
  FFocusedCell := TGridCell.Create(0, 0);
  FTopRow := 0;
  UpdateScrollBars;
  DrawView;
end;

procedure TStringGrid.ClearAll;
begin
  ClearRows;
  FColumns.Clear;
  FModified := False;
  FChangeLog.Clear;
  FHasUndo := False;
end;

function TStringGrid.GetRowID(Row: Integer): Integer;
begin
  if (Row >= 0) and (Row < FRowIDs.Count) then
    Result := FRowIDs[Row]
  else
    Result := -1;
end;

function TStringGrid.RowFromID(ID: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to FRowIDs.Count - 1 do
  begin
    if FRowIDs[I] = ID then
    begin
      Result := I;
      Exit;
    end;
  end;
  Result := -1;
end;

{--- Selection access ---}

function TStringGrid.GetSelectedRows: TArray<Integer>;
var
  Rows: TList<Integer>;
  I, Row: Integer;
begin
  Rows := TList<Integer>.Create;
  try
    for I := 0 to FSelectedCells.Count - 1 do
    begin
      Row := FSelectedCells[I].Row;
      if Rows.IndexOf(Row) < 0 then
        Rows.Add(Row);
    end;
    Result := Rows.ToArray;
  finally
    Rows.Free;
  end;
end;

function TStringGrid.GetSelectedCells: TArray<TGridCell>;
begin
  Result := FSelectedCells.ToArray;
end;

{--- Clipboard ---}

procedure TStringGrid.CopyToClipboard;
var
  S: string;
  Rows: TArray<Integer>;
  R, C: Integer;
begin
  Rows := GetSelectedRows;
  if Length(Rows) = 0 then Exit;

  { Sort rows }
  TArray.Sort<Integer>(Rows);

  S := '';
  for R := 0 to High(Rows) do
  begin
    if R > 0 then
      S := S + #13#10;
    for C := 0 to ColCount - 1 do
    begin
      if C > 0 then
        S := S + #9;
      S := S + string(GetCell(C, Rows[R]));
    end;
  end;

  GridClipboard := S;
  FVClipboard.ClipboardSetText(S);
end;

procedure TStringGrid.PasteFromClipboard;
var
  Lines: TStringList;
  Cols: TStringList;
  R, C, DestRow, DestCol: Integer;
  S: string;
begin
  { Try system clipboard first, fall back to internal }
  S := '';
  if FVClipboard.ClipboardHasText then
    S := FVClipboard.ClipboardGetText;
  if S = '' then
    S := GridClipboard;
  if S = '' then Exit;
  if FEditMode = emNone then Exit;

  Lines := TStringList.Create;
  Cols := TStringList.Create;
  try
    Lines.Text := S;
    DestRow := FFocusedCell.Row;

    for R := 0 to Lines.Count - 1 do
    begin
      if DestRow >= FRowCount then Break;

      Cols.Clear;
      Cols.Delimiter := #9;
      Cols.StrictDelimiter := True;
      Cols.DelimitedText := Lines[R];

      DestCol := FFocusedCell.Col;
      for C := 0 to Cols.Count - 1 do
      begin
        if DestCol >= ColCount then Break;
        SetCell(DestCol, DestRow, Cols[C]);
        Inc(DestCol);
      end;
      Inc(DestRow);
    end;

    FModified := True;
    DrawView;
  finally
    Cols.Free;
    Lines.Free;
  end;
end;

{--- CSV Import/Export ---}

function TStringGrid.SaveToCSVString(Options: TCSVOptions): string;
var
  SB: TStringBuilder;
  Row, Col, StartRow: Integer;
  DelimChar: Char;
  Value: string;
  OwnOptions: Boolean;
begin
  OwnOptions := (Options = nil);
  if OwnOptions then
    Options := TCSVOptions.Create;
  try
    { Determine delimiter character - CustomDelimiter overrides enum }
    if Options.CustomDelimiter <> #0 then
      DelimChar := Options.CustomDelimiter
    else
      DelimChar := GetDelimiterChar(Options.Delimiter);

    SB := TStringBuilder.Create;
    try
      { Determine starting row for data }
      if Options.UseFixedHeaderRow and (FFixedRows > 0) then
        StartRow := FFixedRows  { Skip fixed header rows }
      else
        StartRow := 0;

      { Write header row if enabled }
      if Options.HasHeaders then
      begin
        if Options.UseFixedHeaderRow and (FFixedRows > 0) and (FRowCount > 0) then
        begin
          { Use row 0 (fixed header row) as the header source }
          for Col := 0 to FColumns.Count - 1 do
          begin
            if Col > 0 then
              SB.Append(DelimChar);
            Value := GetCell(Col, 0);
            SB.Append(QuoteCSVField(Value, DelimChar));
          end;
        end
        else
        begin
          { Use column titles as headers }
          for Col := 0 to FColumns.Count - 1 do
          begin
            if Col > 0 then
              SB.Append(DelimChar);
            SB.Append(QuoteCSVField(FColumns[Col].Title, DelimChar));
          end;
        end;
        SB.AppendLine;
      end;

      { Write data rows }
      for Row := StartRow to FRowCount - 1 do
      begin
        for Col := 0 to FColumns.Count - 1 do
        begin
          if Col > 0 then
            SB.Append(DelimChar);
          Value := GetCell(Col, Row);
          SB.Append(QuoteCSVField(Value, DelimChar));
        end;
        SB.AppendLine;
      end;

      Result := SB.ToString;
    finally
      SB.Free;
    end;
  finally
    if OwnOptions then
      Options.Free;
  end;
end;

procedure TStringGrid.SaveToCSVStream(Stream: TStream; Options: TCSVOptions);
var
  Data: string;
  Bytes: TBytes;
  BOM: array[0..2] of Byte;
  OwnOptions: Boolean;
  Enc: TCSVEncoding;
begin
  OwnOptions := (Options = nil);
  if OwnOptions then
    Options := TCSVOptions.Create;
  try
    { Generate CSV string }
    Data := SaveToCSVString(Options);
    Enc := Options.Encoding;

    { Convert to bytes based on encoding }
    case Enc of
      ceUTF8BOM:
      begin
        { Write UTF-8 BOM }
        BOM[0] := $EF; BOM[1] := $BB; BOM[2] := $BF;
        Stream.WriteBuffer(BOM, 3);
        Bytes := TEncoding.UTF8.GetBytes(Data);
        if Length(Bytes) > 0 then
          Stream.WriteBuffer(Bytes[0], Length(Bytes));
      end;
      ceUTF8:
      begin
        Bytes := TEncoding.UTF8.GetBytes(Data);
        if Length(Bytes) > 0 then
          Stream.WriteBuffer(Bytes[0], Length(Bytes));
      end;
      ceANSI:
      begin
        Bytes := TEncoding.ANSI.GetBytes(Data);
        if Length(Bytes) > 0 then
          Stream.WriteBuffer(Bytes[0], Length(Bytes));
      end;
    end;
  finally
    if OwnOptions then
      Options.Free;
  end;
end;

procedure TStringGrid.SaveToCSV(const FileName: string; Options: TCSVOptions);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToCSVStream(Stream, Options);
  finally
    Stream.Free;
  end;
end;

procedure TStringGrid.LoadFromCSVString(const CSVData: string; Options: TCSVOptions);
var
  Rows: TArray<TArray<string>>;
  Fields: TArray<string>;
  RowIdx, Col, DataRow: Integer;
  EffectiveDelim: TCSVDelimiter;
  DelimChar: Char;
  OwnOptions: Boolean;
  Value: string;
  HeaderHandled: Boolean;
begin
  OwnOptions := (Options = nil);
  if OwnOptions then
    Options := TCSVOptions.Create;
  try
    { Determine delimiter - CustomDelimiter overrides enum }
    if Options.CustomDelimiter <> #0 then
      DelimChar := Options.CustomDelimiter
    else if Options.Delimiter = cdAuto then
    begin
      EffectiveDelim := DetectDelimiter(CSVData);
      DelimChar := GetDelimiterChar(EffectiveDelim);
    end
    else
      DelimChar := GetDelimiterChar(Options.Delimiter);

    { Clear existing data }
    ClearRows;

    ParseCSV(CSVData, DelimChar, Rows);
    DataRow := 0;
    HeaderHandled := not Options.HasHeaders;

    for RowIdx := 0 to High(Rows) do
    begin
      Fields := Rows[RowIdx];
      if (Length(Fields) = 0) or
         ((Length(Fields) = 1) and (Fields[0] = '')) then
        Continue;  { Skip empty rows }

      if not HeaderHandled then
      begin
        { Process header row }
        if Options.AutoCreateColumns then
        begin
          FColumns.Clear;
          for Col := 0 to High(Fields) do
          begin
            Value := Fields[Col];
            if Options.TrimWhitespace then
              Value := Trim(Value);
            FColumns.Add(Value, 10);
          end;
        end
        else
        begin
          { Update existing column titles }
          for Col := 0 to Min(High(Fields), FColumns.Count - 1) do
          begin
            Value := Fields[Col];
            if Options.TrimWhitespace then
              Value := Trim(Value);
            FColumns[Col].Title := Value;
          end;
        end;

        { If UseFixedHeaderRow, also add headers as row 0 data }
        if Options.UseFixedHeaderRow then
        begin
          AddRow;
          for Col := 0 to High(Fields) do
          begin
            if Col < FColumns.Count then
            begin
              Value := Fields[Col];
              if Options.TrimWhitespace then
                Value := Trim(Value);
              SetCell(Col, 0, Value);
            end;
          end;
          DataRow := 1;
          FFixedRows := 1;
        end;

        HeaderHandled := True;
        Continue;
      end;

      { Process data row }
      if Options.AutoCreateColumns and (FColumns.Count = 0) then
      begin
        { No headers - create generic columns }
        for Col := 0 to High(Fields) do
          FColumns.Add('Column ' + IntToStr(Col + 1), 10);
      end;

      { Add new row }
      AddRow;
      for Col := 0 to High(Fields) do
      begin
        if Col < FColumns.Count then
        begin
          Value := Fields[Col];
          if Options.TrimWhitespace then
            Value := Trim(Value);
          SetCell(Col, DataRow, Value);
        end;
      end;
      Inc(DataRow);
    end;

    { Auto-fit columns to content }
    AutoFitAllColumns;

    { Reset state }
    FModified := False;
    if Options.UseFixedHeaderRow and (FRowCount > FFixedRows) then
      FFocusedCell := TGridCell.Create(0, FFixedRows)
    else
      FFocusedCell := TGridCell.Create(0, 0);
    FTopRow := 0;
    FLeftCol := 0;
    UpdateScrollBars;
    DrawView;
  finally
    if OwnOptions then
      Options.Free;
  end;
end;

procedure TStringGrid.LoadFromCSVStream(Stream: TStream; Options: TCSVOptions);
var
  Bytes: TBytes;
  Data: string;
  StartPos: Integer;
  OwnOptions: Boolean;
  Enc: TCSVEncoding;
begin
  OwnOptions := (Options = nil);
  if OwnOptions then
    Options := TCSVOptions.Create;
  try
    { Read all bytes from stream }
    SetLength(Bytes, Stream.Size - Stream.Position);
    if Length(Bytes) > 0 then
      Stream.ReadBuffer(Bytes[0], Length(Bytes));

    { Detect and skip UTF-8 BOM if present }
    StartPos := 0;
    if (Length(Bytes) >= 3) and
       (Bytes[0] = $EF) and (Bytes[1] = $BB) and (Bytes[2] = $BF) then
    begin
      StartPos := 3;
      Enc := ceUTF8;  { BOM takes precedence over option }
    end
    else
      Enc := Options.Encoding;

    { Convert to string using requested/detected encoding }
    case Enc of
      ceANSI:
        begin
          if StartPos > 0 then
            Data := TEncoding.ANSI.GetString(Bytes, StartPos, Length(Bytes) - StartPos)
          else
            Data := TEncoding.ANSI.GetString(Bytes);
        end;
    else
      begin
        if StartPos > 0 then
          Data := TEncoding.UTF8.GetString(Bytes, StartPos, Length(Bytes) - StartPos)
        else
          Data := TEncoding.UTF8.GetString(Bytes);
      end;
    end;

    LoadFromCSVString(Data, Options);
  finally
    if OwnOptions then
      Options.Free;
  end;
end;

procedure TStringGrid.LoadFromCSV(const FileName: string; Options: TCSVOptions);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromCSVStream(Stream, Options);
  finally
    Stream.Free;
  end;
end;

{--- Undo ---}

procedure TStringGrid.Undo;
begin
  if not FHasUndo then Exit;

  SetCell(FUndoEntry.Cell.Col, FUndoEntry.Cell.Row, FUndoEntry.OldValue);
  FHasUndo := False;
  DrawView;
end;

function TStringGrid.CanUndo: Boolean;
begin
  Result := FHasUndo;
end;

{--- Change tracking ---}

procedure TStringGrid.ResetModified;
begin
  FModified := False;
  FChangeLog.Clear;
end;

function TStringGrid.GetChangeLog: TArray<TGridChangeEntry>;
begin
  Result := FChangeLog.ToArray;
end;

{--- Column auto-fit ---}

procedure TStringGrid.AutoFitColumn(Col: Integer);
var
  MaxWidth, R: Integer;
  Text: string;
begin
  if (Col < 0) or (Col >= FColumns.Count) then Exit;

  MaxWidth := Length(FColumns[Col].Title) + 2;

  for R := 0 to FRowCount - 1 do
  begin
    Text := GetCell(Col, R);
    if Length(Text) + 1 > MaxWidth then
      MaxWidth := Length(Text) + 1;
  end;

  FColumns[Col].Width := Min(MaxWidth, FColumns[Col].MaxWidth);
  DrawView;
end;

procedure TStringGrid.AutoFitAllColumns;
var
  C: Integer;
begin
  for C := 0 to FColumns.Count - 1 do
    AutoFitColumn(C);
end;

{--- Sorting ---}

function TStringGrid.CompareRows(Row1, Row2: Integer): Integer;
var
  S1, S2: string;
begin
  if FSortColumn < 0 then
  begin
    Result := 0;
    Exit;
  end;

  S1 := GetCell(FSortColumn, Row1);
  S2 := GetCell(FSortColumn, Row2);

  if Assigned(FOnCompare) then
    FOnCompare(Self, FSortColumn, S1, S2, Result)
  else
    Result := CompareStr(string(S1), string(S2));

  if FSortDirection = sdDescending then
    Result := -Result;
end;

procedure TStringGrid.DoSort;
var
  I, J, MinIdx: Integer;
  TempID: Integer;
  TempData: TDictionary<string, string>;
  OldRowOrder: TList<Integer>;
  Pair: TPair<string, string>;
  Col, Row, NewRow: Integer;
  K: Integer;
begin
  if (FSortColumn < 0) or (FSortDirection = sdNone) or (FRowCount <= 1) then
    Exit;

  { Simple selection sort - can be optimized later }
  OldRowOrder := TList<Integer>.Create;
  try
    for I := 0 to FRowCount - 1 do
      OldRowOrder.Add(I);

    { Sort the row order }
    for I := 0 to FRowCount - 2 do
    begin
      MinIdx := I;
      for J := I + 1 to FRowCount - 1 do
      begin
        if CompareRows(OldRowOrder[J], OldRowOrder[MinIdx]) < 0 then
          MinIdx := J;
      end;
      if MinIdx <> I then
      begin
        { Swap in order list }
        TempID := OldRowOrder[I];
        OldRowOrder[I] := OldRowOrder[MinIdx];
        OldRowOrder[MinIdx] := TempID;
      end;
    end;

    { Remap data according to new order }
    TempData := TDictionary<string, string>.Create;
    try
      for I := 0 to FRowCount - 1 do
      begin
        NewRow := I;
        Row := OldRowOrder[I];
        for Col := 0 to ColCount - 1 do
        begin
          if FData.TryGetValue(CellKey(Col, Row), Pair.Value) then
            TempData.AddOrSetValue(CellKey(Col, NewRow), Pair.Value);
        end;
      end;

      { Clear and repopulate }
      FData.Clear;
      for Pair in TempData do
        FData.AddOrSetValue(Pair.Key, Pair.Value);
    finally
      TempData.Free;
    end;

    { Update row IDs }
    for I := 0 to FRowCount - 1 do
      FRowIDs[I] := OldRowOrder[I] + 1;  { Simplified - just renumber }
  finally
    OldRowOrder.Free;
  end;

  DrawView;
end;

procedure TStringGrid.Sort(Col: Integer; Direction: TSortDirection);
begin
  FSortColumn := Col;
  FSortDirection := Direction;
  if Direction <> sdNone then
    DoSort
  else
    DrawView;  { Just redraw to remove sort indicator }
end;

{--- ISerializable implementation ---}

function TStringGrid.GetTypeId: string;
begin
  Result := 'TStringGrid';
end;

function TStringGrid.ToJSON: TJSONObject;
var
  ColsArray: TJSONArray;
  ColObj: TJSONObject;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('_type', GetTypeId);

  { Layout settings }
  Result.AddPair('fixedRows', TJSONNumber.Create(FFixedRows));
  Result.AddPair('fixedCols', TJSONNumber.Create(FFixedCols));
  Result.AddPair('showGridLines', TJSONBool.Create(FShowGridLines));
  Result.AddPair('selectionMode', TJSONNumber.Create(Ord(FSelectionMode)));
  Result.AddPair('editMode', TJSONNumber.Create(Ord(FEditMode)));

  { Sort state }
  Result.AddPair('sortColumn', TJSONNumber.Create(FSortColumn));
  Result.AddPair('sortDirection', TJSONNumber.Create(Ord(FSortDirection)));

  { Column definitions }
  ColsArray := TJSONArray.Create;
  for I := 0 to FColumns.Count - 1 do
  begin
    ColObj := TJSONObject.Create;
    ColObj.AddPair('title', string(FColumns[I].Title));
    ColObj.AddPair('width', TJSONNumber.Create(FColumns[I].Width));
    ColObj.AddPair('minWidth', TJSONNumber.Create(FColumns[I].MinWidth));
    ColObj.AddPair('maxWidth', TJSONNumber.Create(FColumns[I].MaxWidth));
    ColObj.AddPair('alignment', TJSONNumber.Create(Ord(FColumns[I].Alignment)));
    ColObj.AddPair('color', TJSONNumber.Create(FColumns[I].Color));
    ColObj.AddPair('sortable', TJSONBool.Create(FColumns[I].Sortable));
    ColObj.AddPair('visible', TJSONBool.Create(FColumns[I].Visible));
    ColObj.AddPair('defaultValue', string(FColumns[I].DefaultValue));
    ColsArray.Add(ColObj);
  end;
  Result.AddPair('columns', ColsArray);
end;

procedure TStringGrid.FromJSON(const AJson: TJSONObject);
var
  ColsArray: TJSONArray;
  ColObj: TJSONObject;
  I: Integer;
  Col: TGridColumn;
begin
  if AJson = nil then Exit;

  { Layout settings }
  FFixedRows := AJson.GetValue<Integer>('fixedRows', FFixedRows);
  FFixedCols := AJson.GetValue<Integer>('fixedCols', FFixedCols);
  FShowGridLines := AJson.GetValue<Boolean>('showGridLines', FShowGridLines);
  FSelectionMode := TSelectionMode(AJson.GetValue<Integer>('selectionMode', Ord(FSelectionMode)));
  FEditMode := TEditMode(AJson.GetValue<Integer>('editMode', Ord(FEditMode)));

  { Sort state }
  FSortColumn := AJson.GetValue<Integer>('sortColumn', FSortColumn);
  FSortDirection := TSortDirection(AJson.GetValue<Integer>('sortDirection', Ord(FSortDirection)));

  { Column definitions }
  ColsArray := AJson.GetValue<TJSONArray>('columns');
  if ColsArray <> nil then
  begin
    { Update existing columns or add new ones }
    for I := 0 to ColsArray.Count - 1 do
    begin
      ColObj := ColsArray.Items[I] as TJSONObject;
      if ColObj = nil then Continue;

      if I < FColumns.Count then
        Col := FColumns[I]
      else
        Col := FColumns.Add('', 10);

      Col.Title := ColObj.GetValue<string>('title', '');
      Col.Width := ColObj.GetValue<Integer>('width', 10);
      Col.MinWidth := ColObj.GetValue<Integer>('minWidth', 3);
      Col.MaxWidth := ColObj.GetValue<Integer>('maxWidth', 255);
      Col.Alignment := TGridAlignment(ColObj.GetValue<Integer>('alignment', 0));
      Col.Color := ColObj.GetValue<Integer>('color', 0);
      Col.Sortable := ColObj.GetValue<Boolean>('sortable', True);
      Col.Visible := ColObj.GetValue<Boolean>('visible', True);
      Col.DefaultValue := ColObj.GetValue<string>('defaultValue', '');
    end;

    { Remove extra columns if JSON has fewer }
    while FColumns.Count > ColsArray.Count do
      FColumns.Delete(FColumns.Count - 1);
  end;

  UpdateScrollBars;
  DrawView;
end;

{ Factory function for serialization registry }
function CreateStringGrid: TObject;
var
  R: TRect;
begin
  R.Assign(0, 0, 40, 10);
  Result := TStringGrid.Create(R, 3, nil, nil);
end;

{ Filter methods }

procedure TStringGrid.SetColumnFilter(Col: Integer; const AFilter: string);
begin
  if Col < Length(FColumnFilters) then begin
    FColumnFilters[Col] := AFilter;
    FFilterDirty := True;
  end;
end;

function TStringGrid.GetColumnFilter(Col: Integer): string;
begin
  if Col < Length(FColumnFilters) then
    Result := FColumnFilters[Col]
  else
    Result := '';
end;

procedure TStringGrid.ClearFilters;
var
  I: Integer;
begin
  for I := 0 to High(FColumnFilters) do
    FColumnFilters[I] := '';
  FFilterDirty := True;
end;

procedure TStringGrid.ApplyFilters;
var
  R, C: Integer;
  PassesFilter: Boolean;
  CellText, FilterText: string;
begin
  FFilteredRows.Clear;
  for R := 0 to FRowCount - 1 do begin
    PassesFilter := True;
    for C := 0 to FColumns.Count - 1 do begin
      if (C < Length(FColumnFilters)) and (FColumnFilters[C] <> '') then begin
        CellText := LowerCase(GetCellText(C, R));
        FilterText := LowerCase(FColumnFilters[C]);
        if Pos(FilterText, CellText) = 0 then begin
          PassesFilter := False;
          Break;
        end;
      end;
    end;
    if PassesFilter then
      FFilteredRows.Add(R);
  end;
  FFilterDirty := False;
end;

function TStringGrid.GetVisibleRowCount: Integer;
begin
  if FShowFilterRow then begin
    if FFilterDirty then ApplyFilters;
    Result := FFilteredRows.Count;
  end else
    Result := FRowCount;
end;

function TStringGrid.VisibleToDataRow(VisibleRow: Integer): Integer;
begin
  if FShowFilterRow then begin
    if FFilterDirty then ApplyFilters;
    if (VisibleRow >= 0) and (VisibleRow < FFilteredRows.Count) then
      Result := FFilteredRows[VisibleRow]
    else
      Result := -1;
  end else
    Result := VisibleRow;
end;

initialization
  TFVSerializerRegistry.RegisterType('TStringGrid', CreateStringGrid);

end.
