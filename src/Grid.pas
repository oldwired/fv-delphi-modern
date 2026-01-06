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

  { Enumerations }
  TGridAlignment = (gaLeft, gaCenter, gaRight);
  TSelectionMode = (smRow, smCell);
  TEditMode = (emNone, emF2, emEnter, emTyping);
  TSortDirection = (sdNone, sdAscending, sdDescending);

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

  { Event callback types }
  TGridCellEvent = procedure(Sender: TObject; Col, Row: Integer) of object;
  TGridEditEvent = procedure(Sender: TObject; Col, Row: Integer; var AllowEdit: Boolean) of object;
  TGridValidateEvent = procedure(Sender: TObject; Col, Row: Integer;
    const Value: string; var Accept: Boolean) of object;
  TGridCompareEvent = procedure(Sender: TObject; Col: Integer;
    const S1, S2: string; var Result: Integer) of object;

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
  FVSerialization;

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
{                            TGridColumn                                    }
{***************************************************************************}

constructor TGridColumn.Create(const ATitle: string; AWidth: Integer);
begin
  inherited Create;
  FTitle := string(ATitle);
  FWidth := AWidth;
  FMinWidth := 3;
  FMaxWidth := 255;
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
end;

destructor TStringGrid.Destroy;
begin
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
  Result := GetCell(Col, Row);
  { If empty, show default value }
  if (Result = '') and (Col < FColumns.Count) then
    Result := FColumns[Col].DefaultValue;
end;

function TStringGrid.FormatCellText(const Text: string; Width: Integer;
  Alignment: TGridAlignment): string;
var
  Len, Pad: Integer;
begin
  Len := Length(Text);
  if Len >= Width then
  begin
    Result := Copy(Text, 1, Width);
    Exit;
  end;

  Pad := Width - Len;
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
  ShowLeftArrow, ShowRightArrow: Boolean;
  I, OutPos: Integer;
  C: Char;
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

  { Check for overflow }
  ShowLeftArrow := False;
  ShowRightArrow := Length(Text) > CellWidth;

  { Format text to fit cell width }
  if Length(Text) > CellWidth then
    DisplayText := Copy(Text, 1, CellWidth - 1)
  else
    DisplayText := FormatCellText(Text, CellWidth, Alignment);

  { Draw to buffer using new TDrawCell format }
  if ScreenX + CellWidth <= MaxViewWidth then
  begin
    OutPos := ScreenX;
    for I := 1 to Length(DisplayText) do
    begin
      if OutPos >= MaxViewWidth then Break;
      C := DisplayText[I];
      B[OutPos].Ch := C;
      B[OutPos].Attr := Color;
      Inc(OutPos);
    end;

    { Draw overflow arrows - use grid line color for visibility }
    if ShowRightArrow then
    begin
      OutPos := ScreenX + CellWidth - 1;
      if OutPos < MaxViewWidth then
      begin
        B[OutPos].Ch := RightArrow;
        B[OutPos].Attr := GetColor(5);
      end;
    end;
  end;
end;

procedure TStringGrid.Draw;
var
  B: TDrawBuffer;
  I, J, K, Row, ScreenY, ScreenX, ColWidth: Integer;
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
    for J := FLeftCol + FFixedCols to FColumns.Count - 1 do
    begin
      if ScreenX >= Size.X then Break;
      if FColumns[J].Visible then
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

  { Draw data rows (starting after fixed rows) }
  for I := 0 to Size.Y - ScreenY - 1 do
  begin
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
      for J := FLeftCol + FFixedCols to FColumns.Count - 1 do
      begin
        if ScreenX >= Size.X then Break;
        if FColumns[J].Visible then
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
  I, X: Integer;
begin
  X := 0;
  for I := 0 to FColumns.Count - 1 do
  begin
    if I = Col then
    begin
      Result := X;
      Exit;
    end;
    if FColumns[I].Visible then
    begin
      Inc(X, FColumns[I].Width);
      if FShowGridLines then
        Inc(X);
    end;
  end;
  Result := -1;
end;

function TStringGrid.ScreenToCol(X: Integer): Integer;
var
  ColStart: Integer;
begin
  Result := FColumns.ColumnAtX(X, ColStart);
end;

procedure TStringGrid.EnsureCellVisible(Col, Row: Integer);
var
  VisibleRows: Integer;
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
    if Col < FLeftCol + FFixedCols then
      FLeftCol := Col - FFixedCols
    else
    begin
      { TODO: Calculate visible column range and scroll if needed }
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
      Col := ScreenToCol(Mouse.X);
      Row := ScreenToRow(Mouse.Y);

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
end;

procedure TStringGrid.PasteFromClipboard;
var
  Lines: TStringList;
  Cols: TStringList;
  R, C, DestRow, DestCol: Integer;
begin
  if GridClipboard = '' then Exit;
  if FEditMode = emNone then Exit;

  Lines := TStringList.Create;
  Cols := TStringList.Create;
  try
    Lines.Text := GridClipboard;
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

initialization
  TFVSerializerRegistry.RegisterType('TStringGrid', CreateStringGrid);

end.
