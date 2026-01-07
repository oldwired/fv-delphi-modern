{*******************************************************}
{       Free Vision Hex Editor Unit                     }
{       Delphi-compatible version                       }
{       Full hex viewer/editor component                }
{*******************************************************}

unit HexEdit;

{$R-}  { Disable range checking for legacy buffer operations }

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections,
  FVCommon, Objects, Drivers, Views, FVConsts, FVBoxChars;

{***************************************************************************}
{                              PUBLIC CONSTANTS                             }
{***************************************************************************}

const
  { Hex editor layout constants }
  HexBytesPerRow = 16;         { Fixed 16 bytes per row }
  HexAddressWidth = 10;        { 8 hex digits + 2 spaces }
  HexByteWidth = 49;           { 16*2 + 15 spaces + 1 gap after byte 8 }
  HexASCIIWidth = 16;          { 16 characters }
  HexMinWidth = HexAddressWidth + HexByteWidth + HexASCIIWidth; { 75 chars }

  { Direct color attributes (bypass palette for reliable colors) }
  { Format: High nibble = background, Low nibble = foreground }
  HexColorAddressNormal  = $17;  { Blue bg, gray fg }
  HexColorAddressFocus   = $1F;  { Blue bg, bright white fg }
  HexColorNormal         = $1E;  { Blue bg, yellow fg }
  HexColorFocusRow       = $1B;  { Blue bg, cyan fg }
  HexColorCursor         = $4F;  { Red bg, bright white fg }
  HexColorSelection      = $2F;  { Green bg, bright white fg }
  HexColorModified       = $4E;  { Red bg, yellow fg }
  HexColorASCIICursor    = $5F;  { Magenta bg, bright white fg }

{***************************************************************************}
{                            TYPE DEFINITIONS                               }
{***************************************************************************}

type
  { Edit mode: hex nibble or ASCII character }
  THexEditMode = (hemHex, hemASCII);

  { Which nibble of the hex byte is being edited }
  THexNibble = (hnHigh, hnLow);

  { Color indices for THexEditor palette }
  THexColorIndex = (
    hcAddressNormal = 1,
    hcAddressFocus = 2,
    hcHexNormal = 3,
    hcHexFocus = 4,
    hcHexSelected = 5,
    hcHexModified = 6,
    hcASCIINormal = 7,
    hcASCIIFocus = 8,
    hcASCIISelected = 9,
    hcASCIIModified = 10,
    hcSeparator = 11
  );

{***************************************************************************}
{                         DATA SOURCE INTERFACE                             }
{***************************************************************************}

type
  { Data source interface for hex editor }
  IHexDataSource = interface
    ['{E1F2A3B4-5C6D-7E8F-9A0B-1C2D3E4F5A6B}']
    function GetSize: Int64;
    function GetByte(Position: Int64): Byte;
    procedure SetByte(Position: Int64; Value: Byte);
    function Read(Position: Int64; var Buffer; Count: Integer): Integer;
    function CanWrite: Boolean;
    function IsModified: Boolean;
    function IsByteModified(Position: Int64): Boolean;
    procedure ClearModified;
  end;

{***************************************************************************}
{                         MEMORY DATA SOURCE                                }
{***************************************************************************}

type
  TMemoryHexSource = class(TInterfacedObject, IHexDataSource)
  private
    FData: TBytes;
    FModified: Boolean;
    FReadOnly: Boolean;
    FModifiedBytes: TDictionary<Int64, Boolean>;
  public
    constructor Create(ASize: Int64 = 0);
    constructor CreateFromBytes(const AData: TBytes);
    destructor Destroy; override;
    { IHexDataSource }
    function GetSize: Int64;
    function GetByte(Position: Int64): Byte;
    procedure SetByte(Position: Int64; Value: Byte);
    function Read(Position: Int64; var Buffer; Count: Integer): Integer;
    function CanWrite: Boolean;
    function IsModified: Boolean;
    function IsByteModified(Position: Int64): Boolean;
    procedure ClearModified;
    { Memory-specific }
    procedure Resize(NewSize: Int64);
    procedure LoadFromFile(const FileName: string);
    procedure SaveToFile(const FileName: string);
    property Data: TBytes read FData;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
  end;

{***************************************************************************}
{                         FILE DATA SOURCE                                  }
{***************************************************************************}

type
  TFileHexSource = class(TInterfacedObject, IHexDataSource)
  private
    FStream: TFileStream;
    FFileName: string;
    FFileSize: Int64;
    FReadOnly: Boolean;
    FBuffer: TBytes;              { Cache buffer }
    FBufferStart: Int64;          { Start position of cached data }
    FBufferValid: Integer;        { Valid bytes in buffer }
    FModifiedBytes: TDictionary<Int64, Byte>;  { Pending modifications }
    procedure EnsureBuffered(Position: Int64);
  public
    constructor Create(const AFileName: string; AReadOnly: Boolean = False);
    destructor Destroy; override;
    { IHexDataSource }
    function GetSize: Int64;
    function GetByte(Position: Int64): Byte;
    procedure SetByte(Position: Int64; Value: Byte);
    function Read(Position: Int64; var Buffer; Count: Integer): Integer;
    function CanWrite: Boolean;
    function IsModified: Boolean;
    function IsByteModified(Position: Int64): Boolean;
    procedure ClearModified;
    { File-specific }
    procedure Flush;
    procedure Reload;
    property FileName: string read FFileName;
  end;

{***************************************************************************}
{                           HEX EDITOR VIEW                                 }
{***************************************************************************}

type
  THexEditor = class(TScroller)
  private
    FDataSource: IHexDataSource;
    FCursorPos: Int64;           { Current byte position (0-based) }
    FEditMode: THexEditMode;     { Hex or ASCII editing }
    FNibble: THexNibble;         { Which nibble in hex mode }
    FSelStart: Int64;            { Selection start (-1 if no selection) }
    FSelEnd: Int64;              { Selection end }

    procedure DrawAddressColumn(var B: TDrawBuffer; RowOffset: Int64);
    procedure DrawHexColumn(var B: TDrawBuffer; RowOffset: Int64);
    procedure DrawASCIIColumn(var B: TDrawBuffer; RowOffset: Int64);
    function GetByteColorHex(Position: Int64): Byte;
    function GetByteColorASCII(Position: Int64): Byte;
    function IsByteInSelection(Position: Int64): Boolean;
    procedure EnsureCursorVisible;
    procedure MoveCursor(NewPos: Int64; Selecting: Boolean);
    procedure HandleHexInput(Ch: Char);
    procedure HandleASCIIInput(Ch: Char);
    function IsValidHexChar(Ch: Char): Boolean;
    function HexCharToNibble(Ch: Char): Byte;
    function PositionToScreenX(Position: Int64): Integer;
    function ScreenToPosition(X, Y: Integer; var InASCII: Boolean): Int64;
    procedure UpdateScrollLimits;
  public
    constructor Create(var Bounds: TRect;
                      AHScrollBar, AVScrollBar: TScrollBar); reintroduce; virtual;
    destructor Destroy; override;

    { Overrides }
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    function GetPalette: PPalette; override;
    procedure SetState(AState: Word; Enable: Boolean); override;
    procedure ChangeBounds(var Bounds: TRect); override;

    { Data management }
    procedure SetDataSource(ASource: IHexDataSource);
    procedure RefreshDisplay;

    { Cursor and selection }
    procedure GotoPosition(Position: Int64);
    procedure SelectRange(StartPos, EndPos: Int64);
    procedure ClearSelection;
    function HasSelection: Boolean;
    function GetSelectedData: TBytes;

    { Edit mode }
    procedure SwitchToHexMode;
    procedure SwitchToASCIIMode;
    procedure ToggleEditMode;

    { Properties }
    property DataSource: IHexDataSource read FDataSource;
    property CursorPosition: Int64 read FCursorPos;
    property EditMode: THexEditMode read FEditMode;
    property SelectionStart: Int64 read FSelStart;
    property SelectionEnd: Int64 read FSelEnd;
  end;

{***************************************************************************}
{                          HEX EDITOR WINDOW                                }
{***************************************************************************}

type
  THexWindow = class(TWindow)
  private
    FEditor: THexEditor;
  public
    constructor Create(var Bounds: TRect; const ATitle: TTitleStr;
                      ANumber: Integer); reintroduce; virtual;
    destructor Destroy; override;
    procedure SetDataSource(ASource: IHexDataSource);
    property Editor: THexEditor read FEditor;
  end;

implementation

{***************************************************************************}
{                       TMemoryHexSource Implementation                     }
{***************************************************************************}

constructor TMemoryHexSource.Create(ASize: Int64);
begin
  inherited Create;
  SetLength(FData, ASize);
  FModified := False;
  FReadOnly := False;
  FModifiedBytes := TDictionary<Int64, Boolean>.Create;
end;

constructor TMemoryHexSource.CreateFromBytes(const AData: TBytes);
begin
  inherited Create;
  FData := Copy(AData);
  FModified := False;
  FReadOnly := False;
  FModifiedBytes := TDictionary<Int64, Boolean>.Create;
end;

destructor TMemoryHexSource.Destroy;
begin
  FModifiedBytes.Free;
  inherited Destroy;
end;

function TMemoryHexSource.GetSize: Int64;
begin
  Result := Length(FData);
end;

function TMemoryHexSource.GetByte(Position: Int64): Byte;
begin
  if (Position >= 0) and (Position < Length(FData)) then
    Result := FData[Position]
  else
    Result := 0;
end;

procedure TMemoryHexSource.SetByte(Position: Int64; Value: Byte);
begin
  if FReadOnly then Exit;
  if (Position >= 0) and (Position < Length(FData)) then
  begin
    FData[Position] := Value;
    FModified := True;
    FModifiedBytes.AddOrSetValue(Position, True);
  end;
end;

function TMemoryHexSource.Read(Position: Int64; var Buffer; Count: Integer): Integer;
var
  Available: Int64;
begin
  if Position >= Length(FData) then
  begin
    Result := 0;
    Exit;
  end;
  Available := Length(FData) - Position;
  if Count > Available then
    Count := Available;
  if Count > 0 then
    Move(FData[Position], Buffer, Count);
  Result := Count;
end;

function TMemoryHexSource.CanWrite: Boolean;
begin
  Result := not FReadOnly;
end;

function TMemoryHexSource.IsModified: Boolean;
begin
  Result := FModified;
end;

function TMemoryHexSource.IsByteModified(Position: Int64): Boolean;
begin
  Result := FModifiedBytes.ContainsKey(Position);
end;

procedure TMemoryHexSource.ClearModified;
begin
  FModified := False;
  FModifiedBytes.Clear;
end;

procedure TMemoryHexSource.Resize(NewSize: Int64);
begin
  SetLength(FData, NewSize);
end;

procedure TMemoryHexSource.LoadFromFile(const FileName: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(FData, Stream.Size);
    if Stream.Size > 0 then
      Stream.ReadBuffer(FData[0], Stream.Size);
    FModified := False;
    FModifiedBytes.Clear;
  finally
    Stream.Free;
  end;
end;

procedure TMemoryHexSource.SaveToFile(const FileName: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    if Length(FData) > 0 then
      Stream.WriteBuffer(FData[0], Length(FData));
    FModified := False;
    FModifiedBytes.Clear;
  finally
    Stream.Free;
  end;
end;

{***************************************************************************}
{                       TFileHexSource Implementation                       }
{***************************************************************************}

const
  FileBufferSize = 4096;

constructor TFileHexSource.Create(const AFileName: string; AReadOnly: Boolean);
var
  Mode: Word;
begin
  inherited Create;
  FFileName := AFileName;
  FReadOnly := AReadOnly;
  if AReadOnly then
    Mode := fmOpenRead or fmShareDenyWrite
  else
    Mode := fmOpenReadWrite or fmShareDenyWrite;
  FStream := TFileStream.Create(AFileName, Mode);
  FFileSize := FStream.Size;
  SetLength(FBuffer, FileBufferSize);
  FBufferStart := -1;
  FBufferValid := 0;
  FModifiedBytes := TDictionary<Int64, Byte>.Create;
end;

destructor TFileHexSource.Destroy;
begin
  Flush;
  FModifiedBytes.Free;
  FStream.Free;
  inherited Destroy;
end;

procedure TFileHexSource.EnsureBuffered(Position: Int64);
begin
  if (Position < FBufferStart) or (Position >= FBufferStart + FBufferValid) then
  begin
    { Need to read new buffer }
    FBufferStart := (Position div FileBufferSize) * FileBufferSize;
    FStream.Position := FBufferStart;
    FBufferValid := FStream.Read(FBuffer[0], FileBufferSize);
  end;
end;

function TFileHexSource.GetSize: Int64;
begin
  Result := FFileSize;
end;

function TFileHexSource.GetByte(Position: Int64): Byte;
begin
  { Check modifications first }
  if FModifiedBytes.TryGetValue(Position, Result) then
    Exit;

  if (Position < 0) or (Position >= FFileSize) then
  begin
    Result := 0;
    Exit;
  end;

  EnsureBuffered(Position);
  if Position - FBufferStart < FBufferValid then
    Result := FBuffer[Position - FBufferStart]
  else
    Result := 0;
end;

procedure TFileHexSource.SetByte(Position: Int64; Value: Byte);
begin
  if FReadOnly then Exit;
  if (Position >= 0) and (Position < FFileSize) then
    FModifiedBytes.AddOrSetValue(Position, Value);
end;

function TFileHexSource.Read(Position: Int64; var Buffer; Count: Integer): Integer;
var
  I: Integer;
  P: PByte;
begin
  P := @Buffer;
  Result := 0;
  for I := 0 to Count - 1 do
  begin
    if Position + I >= FFileSize then
      Break;
    P^ := GetByte(Position + I);
    Inc(P);
    Inc(Result);
  end;
end;

function TFileHexSource.CanWrite: Boolean;
begin
  Result := not FReadOnly;
end;

function TFileHexSource.IsModified: Boolean;
begin
  Result := FModifiedBytes.Count > 0;
end;

function TFileHexSource.IsByteModified(Position: Int64): Boolean;
begin
  Result := FModifiedBytes.ContainsKey(Position);
end;

procedure TFileHexSource.ClearModified;
begin
  FModifiedBytes.Clear;
end;

procedure TFileHexSource.Flush;
var
  Pair: TPair<Int64, Byte>;
begin
  if FReadOnly or (FModifiedBytes.Count = 0) then Exit;

  for Pair in FModifiedBytes do
  begin
    FStream.Position := Pair.Key;
    FStream.WriteBuffer(Pair.Value, 1);
  end;
  FModifiedBytes.Clear;
  { Invalidate buffer }
  FBufferStart := -1;
  FBufferValid := 0;
end;

procedure TFileHexSource.Reload;
begin
  FModifiedBytes.Clear;
  FBufferStart := -1;
  FBufferValid := 0;
  FStream.Position := 0;
  FFileSize := FStream.Size;
end;

{***************************************************************************}
{                        THexEditor Implementation                          }
{***************************************************************************}

constructor THexEditor.Create(var Bounds: TRect;
                              AHScrollBar, AVScrollBar: TScrollBar);
begin
  inherited Create(Bounds, AHScrollBar, AVScrollBar);
  Options := Options or ofSelectable;
  EventMask := EventMask or evBroadcast;
  FDataSource := nil;
  FCursorPos := 0;
  FEditMode := hemHex;
  FNibble := hnHigh;
  FSelStart := -1;
  FSelEnd := -1;
  GrowMode := gfGrowHiX or gfGrowHiY;
end;

destructor THexEditor.Destroy;
begin
  FDataSource := nil;
  inherited Destroy;
end;

function THexEditor.GetPalette: PPalette;
begin
  { We use direct color constants, so just inherit parent palette }
  Result := inherited GetPalette;
end;

procedure THexEditor.UpdateScrollLimits;
var
  TotalRows: Int64;
begin
  if FDataSource <> nil then
  begin
    TotalRows := (FDataSource.GetSize + HexBytesPerRow - 1) div HexBytesPerRow;
    SetLimit(0, TotalRows);
  end
  else
    SetLimit(0, 0);
end;

procedure THexEditor.SetDataSource(ASource: IHexDataSource);
begin
  FDataSource := ASource;
  FCursorPos := 0;
  FSelStart := -1;
  FSelEnd := -1;
  FNibble := hnHigh;
  UpdateScrollLimits;
  DrawView;
end;

procedure THexEditor.RefreshDisplay;
begin
  UpdateScrollLimits;
  DrawView;
end;

procedure THexEditor.Draw;
var
  B: TDrawBuffer;
  Y: Integer;
  RowOffset: Int64;
  DataSize: Int64;
begin
  DataSize := 0;
  if FDataSource <> nil then
    DataSize := FDataSource.GetSize;

  for Y := 0 to Size.Y - 1 do
  begin
    RowOffset := Int64(Delta.Y + Y) * HexBytesPerRow;

    { Clear the line with normal color }
    DrawChar(B, 0, ' ', HexColorNormal, Size.X);

    if RowOffset < DataSize then
    begin
      { Draw address column }
      DrawAddressColumn(B, RowOffset);

      { Draw hex bytes }
      DrawHexColumn(B, RowOffset);

      { Draw ASCII representation }
      DrawASCIIColumn(B, RowOffset);
    end;

    WriteLine(0, Y, Size.X, 1, B);
  end;

  { Position cursor }
  if (State and sfFocused <> 0) and (FDataSource <> nil) then
  begin
    Y := Integer(FCursorPos div HexBytesPerRow) - Delta.Y;
    if (Y >= 0) and (Y < Size.Y) then
    begin
      if FEditMode = hemHex then
      begin
        SetCursor(PositionToScreenX(FCursorPos), Y);
        if FNibble = hnLow then
          SetCursor(Cursor.X + 1, Cursor.Y);
      end
      else
      begin
        { ASCII mode cursor }
        SetCursor(HexAddressWidth + HexByteWidth + Integer(FCursorPos mod HexBytesPerRow), Y);
      end;
    end;
  end;
end;

procedure THexEditor.DrawAddressColumn(var B: TDrawBuffer; RowOffset: Int64);
var
  AddrStr: string;
  Color: Byte;
begin
  if State and sfFocused <> 0 then
    Color := HexColorAddressFocus
  else
    Color := HexColorAddressNormal;

  AddrStr := Format('%.8X  ', [RowOffset]);
  DrawStr(B, 0, AddrStr, Color);
end;

procedure THexEditor.DrawHexColumn(var B: TDrawBuffer; RowOffset: Int64);
var
  I: Integer;
  BytePos: Int64;
  ByteVal: Byte;
  HexStr: string;
  Color: Byte;
  X: Integer;
  DataSize: Int64;
begin
  DataSize := FDataSource.GetSize;
  X := HexAddressWidth;

  for I := 0 to HexBytesPerRow - 1 do
  begin
    BytePos := RowOffset + I;

    if BytePos < DataSize then
    begin
      ByteVal := FDataSource.GetByte(BytePos);
      HexStr := Format('%.2X', [ByteVal]);
      Color := GetByteColorHex(BytePos);
      DrawStr(B, X, HexStr, Color);
    end
    else
    begin
      { Past end of data }
      DrawStr(B, X, '  ', HexColorNormal);
    end;

    Inc(X, 2);

    { Add space after each byte, extra space after byte 7 }
    if I = 7 then
      Inc(X, 2)
    else
      Inc(X, 1);
  end;
end;

procedure THexEditor.DrawASCIIColumn(var B: TDrawBuffer; RowOffset: Int64);
var
  I: Integer;
  BytePos: Int64;
  ByteVal: Byte;
  Ch: Char;
  Color: Byte;
  X: Integer;
  DataSize: Int64;
begin
  DataSize := FDataSource.GetSize;
  X := HexAddressWidth + HexByteWidth;

  for I := 0 to HexBytesPerRow - 1 do
  begin
    BytePos := RowOffset + I;

    if BytePos < DataSize then
    begin
      ByteVal := FDataSource.GetByte(BytePos);
      { Show printable ASCII, dot for non-printable }
      if (ByteVal >= 32) and (ByteVal < 127) then
        Ch := Char(ByteVal)
      else
        Ch := '.';
      Color := GetByteColorASCII(BytePos);
      DrawCell(B, X + I, Ch, Color);
    end
    else
    begin
      DrawCell(B, X + I, ' ', HexColorNormal);
    end;
  end;
end;

function THexEditor.GetByteColorHex(Position: Int64): Byte;
var
  IsCursorPos, IsInSelection, IsFocusedRow, IsModified: Boolean;
begin
  IsModified := (FDataSource <> nil) and FDataSource.IsByteModified(Position);
  IsCursorPos := (Position = FCursorPos);
  IsInSelection := IsByteInSelection(Position);
  IsFocusedRow := (Position div HexBytesPerRow) = (FCursorPos div HexBytesPerRow);

  { Priority: Modified > Cursor > Selection > FocusedRow > Normal }
  if IsModified then
    Result := HexColorModified
  else if IsCursorPos then
  begin
    if FEditMode = hemHex then
      Result := HexColorCursor      { Red bg - active cursor in hex mode }
    else
      Result := HexColorSelection;  { Green bg - inactive side }
  end
  else if IsInSelection then
    Result := HexColorSelection
  else if IsFocusedRow then
    Result := HexColorFocusRow
  else
    Result := HexColorNormal;
end;

function THexEditor.GetByteColorASCII(Position: Int64): Byte;
var
  IsCursorPos, IsInSelection, IsFocusedRow, IsModified: Boolean;
begin
  IsModified := (FDataSource <> nil) and FDataSource.IsByteModified(Position);
  IsCursorPos := (Position = FCursorPos);
  IsInSelection := IsByteInSelection(Position);
  IsFocusedRow := (Position div HexBytesPerRow) = (FCursorPos div HexBytesPerRow);

  { Priority: Modified > Cursor > Selection > FocusedRow > Normal }
  if IsModified then
    Result := HexColorModified
  else if IsCursorPos then
  begin
    if FEditMode = hemASCII then
      Result := HexColorASCIICursor  { Magenta bg - active cursor in ASCII mode }
    else
      Result := HexColorSelection;   { Green bg - inactive side }
  end
  else if IsInSelection then
    Result := HexColorSelection
  else if IsFocusedRow then
    Result := HexColorFocusRow
  else
    Result := HexColorNormal;
end;

function THexEditor.IsByteInSelection(Position: Int64): Boolean;
var
  SelMin, SelMax: Int64;
begin
  if FSelStart < 0 then
  begin
    Result := False;
    Exit;
  end;

  if FSelStart <= FSelEnd then
  begin
    SelMin := FSelStart;
    SelMax := FSelEnd;
  end
  else
  begin
    SelMin := FSelEnd;
    SelMax := FSelStart;
  end;

  Result := (Position >= SelMin) and (Position <= SelMax);
end;

function THexEditor.PositionToScreenX(Position: Int64): Integer;
var
  ByteInRow: Integer;
begin
  ByteInRow := Position mod HexBytesPerRow;
  { Each byte takes 2 chars + 1 space, extra space after byte 7 }
  Result := HexAddressWidth + (ByteInRow * 3);
  if ByteInRow > 7 then
    Inc(Result);
end;

function THexEditor.ScreenToPosition(X, Y: Integer; var InASCII: Boolean): Int64;
var
  RowOffset: Int64;
  ByteInRow: Integer;
begin
  RowOffset := Int64(Delta.Y + Y) * HexBytesPerRow;

  if X >= HexAddressWidth + HexByteWidth then
  begin
    { In ASCII column }
    InASCII := True;
    ByteInRow := X - (HexAddressWidth + HexByteWidth);
    if ByteInRow >= HexBytesPerRow then
      ByteInRow := HexBytesPerRow - 1;
    if ByteInRow < 0 then
      ByteInRow := 0;
  end
  else if X >= HexAddressWidth then
  begin
    { In hex column }
    InASCII := False;
    X := X - HexAddressWidth;
    { Account for extra space after byte 7 }
    if X >= 25 then { Past the gap }
      ByteInRow := (X - 1) div 3
    else
      ByteInRow := X div 3;
    if ByteInRow >= HexBytesPerRow then
      ByteInRow := HexBytesPerRow - 1;
    if ByteInRow < 0 then
      ByteInRow := 0;
  end
  else
  begin
    { In address column - treat as hex column byte 0 }
    InASCII := False;
    ByteInRow := 0;
  end;

  Result := RowOffset + ByteInRow;
end;

procedure THexEditor.EnsureCursorVisible;
var
  CursorRow: Integer;
begin
  CursorRow := FCursorPos div HexBytesPerRow;

  if CursorRow < Delta.Y then
    ScrollTo(0, CursorRow)
  else if CursorRow >= Delta.Y + Size.Y then
    ScrollTo(0, CursorRow - Size.Y + 1);
end;

procedure THexEditor.MoveCursor(NewPos: Int64; Selecting: Boolean);
var
  DataSize: Int64;
begin
  if FDataSource = nil then Exit;

  DataSize := FDataSource.GetSize;
  if DataSize = 0 then Exit;

  { Clamp position }
  if NewPos < 0 then NewPos := 0;
  if NewPos >= DataSize then NewPos := DataSize - 1;

  { Handle selection }
  if Selecting then
  begin
    if FSelStart < 0 then
      FSelStart := FCursorPos;
    FSelEnd := NewPos;
  end
  else
  begin
    FSelStart := -1;
    FSelEnd := -1;
  end;

  FCursorPos := NewPos;
  FNibble := hnHigh;
  EnsureCursorVisible;
  DrawView;
end;

procedure THexEditor.GotoPosition(Position: Int64);
begin
  MoveCursor(Position, False);
end;

procedure THexEditor.SelectRange(StartPos, EndPos: Int64);
begin
  FSelStart := StartPos;
  FSelEnd := EndPos;
  FCursorPos := EndPos;
  EnsureCursorVisible;
  DrawView;
end;

procedure THexEditor.ClearSelection;
begin
  FSelStart := -1;
  FSelEnd := -1;
  DrawView;
end;

function THexEditor.HasSelection: Boolean;
begin
  Result := FSelStart >= 0;
end;

function THexEditor.GetSelectedData: TBytes;
var
  SelMin, SelMax: Int64;
  Len: Int64;
begin
  if (FSelStart < 0) or (FDataSource = nil) then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  if FSelStart <= FSelEnd then
  begin
    SelMin := FSelStart;
    SelMax := FSelEnd;
  end
  else
  begin
    SelMin := FSelEnd;
    SelMax := FSelStart;
  end;

  Len := SelMax - SelMin + 1;
  SetLength(Result, Len);
  FDataSource.Read(SelMin, Result[0], Len);
end;

procedure THexEditor.SwitchToHexMode;
begin
  FEditMode := hemHex;
  FNibble := hnHigh;
  DrawView;
end;

procedure THexEditor.SwitchToASCIIMode;
begin
  FEditMode := hemASCII;
  DrawView;
end;

procedure THexEditor.ToggleEditMode;
begin
  if FEditMode = hemHex then
    SwitchToASCIIMode
  else
    SwitchToHexMode;
end;

function THexEditor.IsValidHexChar(Ch: Char): Boolean;
begin
  Result := CharInSet(Ch, ['0'..'9', 'A'..'F', 'a'..'f']);
end;

function THexEditor.HexCharToNibble(Ch: Char): Byte;
begin
  case Ch of
    '0'..'9': Result := Ord(Ch) - Ord('0');
    'A'..'F': Result := Ord(Ch) - Ord('A') + 10;
    'a'..'f': Result := Ord(Ch) - Ord('a') + 10;
  else
    Result := 0;
  end;
end;

procedure THexEditor.HandleHexInput(Ch: Char);
var
  OldByte, NewByte, NibbleVal: Byte;
begin
  if (FDataSource = nil) or not FDataSource.CanWrite then Exit;
  if not IsValidHexChar(Ch) then Exit;

  NibbleVal := HexCharToNibble(Ch);
  OldByte := FDataSource.GetByte(FCursorPos);

  if FNibble = hnHigh then
  begin
    NewByte := (NibbleVal shl 4) or (OldByte and $0F);
    FDataSource.SetByte(FCursorPos, NewByte);
    FNibble := hnLow;
  end
  else
  begin
    NewByte := (OldByte and $F0) or NibbleVal;
    FDataSource.SetByte(FCursorPos, NewByte);
    { Move to next byte }
    FNibble := hnHigh;
    if FCursorPos < FDataSource.GetSize - 1 then
      Inc(FCursorPos);
    EnsureCursorVisible;
  end;

  DrawView;
end;

procedure THexEditor.HandleASCIIInput(Ch: Char);
begin
  if (FDataSource = nil) or not FDataSource.CanWrite then Exit;
  if (Ord(Ch) < 32) or (Ord(Ch) > 126) then Exit;

  FDataSource.SetByte(FCursorPos, Ord(Ch));

  { Move to next byte }
  if FCursorPos < FDataSource.GetSize - 1 then
    Inc(FCursorPos);
  EnsureCursorVisible;
  DrawView;
end;

procedure THexEditor.HandleEvent(var Event: TEvent);
var
  ShiftPressed: Boolean;
  Mouse: TPoint;
  InASCII: Boolean;
  NewPos: Int64;
begin
  inherited HandleEvent(Event);

  if FDataSource = nil then Exit;

  case Event.What of
    evKeyDown:
    begin
      ShiftPressed := (Event.KeyShift and kbBothShifts) <> 0;

      case CtrlToArrow(Event.KeyCode) of
        kbUp:
        begin
          MoveCursor(FCursorPos - HexBytesPerRow, ShiftPressed);
          ClearEvent(Event);
        end;
        kbDown:
        begin
          MoveCursor(FCursorPos + HexBytesPerRow, ShiftPressed);
          ClearEvent(Event);
        end;
        kbLeft:
        begin
          if (FEditMode = hemHex) and (FNibble = hnLow) then
          begin
            FNibble := hnHigh;
            DrawView;
          end
          else
            MoveCursor(FCursorPos - 1, ShiftPressed);
          ClearEvent(Event);
        end;
        kbRight:
        begin
          if (FEditMode = hemHex) and (FNibble = hnHigh) then
          begin
            FNibble := hnLow;
            DrawView;
          end
          else
          begin
            FNibble := hnHigh;
            MoveCursor(FCursorPos + 1, ShiftPressed);
          end;
          ClearEvent(Event);
        end;
        kbPgUp:
        begin
          MoveCursor(FCursorPos - HexBytesPerRow * Size.Y, ShiftPressed);
          ClearEvent(Event);
        end;
        kbPgDn:
        begin
          MoveCursor(FCursorPos + HexBytesPerRow * Size.Y, ShiftPressed);
          ClearEvent(Event);
        end;
        kbHome:
        begin
          if (Event.KeyShift and kbCtrlShift) <> 0 then
            MoveCursor(0, ShiftPressed)
          else
            MoveCursor((FCursorPos div HexBytesPerRow) * HexBytesPerRow, ShiftPressed);
          ClearEvent(Event);
        end;
        kbEnd:
        begin
          if (Event.KeyShift and kbCtrlShift) <> 0 then
            MoveCursor(FDataSource.GetSize - 1, ShiftPressed)
          else
            MoveCursor((FCursorPos div HexBytesPerRow) * HexBytesPerRow + HexBytesPerRow - 1, ShiftPressed);
          ClearEvent(Event);
        end;
        kbTab:
        begin
          ToggleEditMode;
          ClearEvent(Event);
        end;
      else
        { Handle character input }
        if Event.UnicodeChar >= ' ' then
        begin
          if FEditMode = hemHex then
            HandleHexInput(Event.UnicodeChar)
          else
            HandleASCIIInput(Event.UnicodeChar);
          ClearEvent(Event);
        end;
      end;
    end;

    evMouseDown:
    begin
      { Handle mouse wheel in inherited }
      if Event.Buttons and (mbScrollWheelUp or mbScrollWheelDown) <> 0 then
        Exit;

      MakeLocal(Event.Where, Mouse);
      if MouseInView(Event.Where) then
      begin
        NewPos := ScreenToPosition(Mouse.X, Mouse.Y, InASCII);
        if NewPos < FDataSource.GetSize then
        begin
          if InASCII then
            SwitchToASCIIMode
          else
            SwitchToHexMode;
          MoveCursor(NewPos, False);
        end;
        ClearEvent(Event);
      end;
    end;
  end;
end;

procedure THexEditor.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if (AState and sfFocused) <> 0 then
    DrawView;
end;

procedure THexEditor.ChangeBounds(var Bounds: TRect);
begin
  inherited ChangeBounds(Bounds);
  UpdateScrollLimits;
end;

{***************************************************************************}
{                        THexWindow Implementation                          }
{***************************************************************************}

constructor THexWindow.Create(var Bounds: TRect; const ATitle: TTitleStr;
                              ANumber: Integer);
var
  R: TRect;
  HSB, VSB: TScrollBar;
begin
  inherited Create(Bounds, ATitle, ANumber);
  Options := Options or ofTileable;
  Palette := wpGrayWindow;

  { Create scrollbars }
  VSB := StandardScrollBar(sbVertical or sbHandleKeyboard);
  HSB := nil;  { No horizontal scroll needed for fixed 16-byte width }

  { Create hex editor }
  GetExtent(R);
  R.Grow(-1, -1);
  FEditor := THexEditor.Create(R, HSB, VSB);
  FEditor.GrowMode := gfGrowHiX or gfGrowHiY;
  Insert(FEditor);
end;

destructor THexWindow.Destroy;
begin
  { FEditor is freed by TGroup.Destroy }
  inherited Destroy;
end;

procedure THexWindow.SetDataSource(ASource: IHexDataSource);
begin
  FEditor.SetDataSource(ASource);
end;

end.
