{*******************************************************}
{       Free Vision Sixel View                          }
{       Reusable view for pre-encoded SIXEL data        }
{*******************************************************}

unit SixelView;

{$R-} { Range checking off for performance }

interface

uses
  FVCommon, Drivers, Views, SixelEncoder;

type
  TSixelView = class(TView)
  private
    FSixelData: string;
    FPixelWidth: Integer;
    FPixelHeight: Integer;
    FLoaded: Boolean;
    procedure DrawEmpty;
    function DetectCellPixelSize(out CellW, CellH: Integer): Boolean;
    class function NormalizeSixelData(const RawData: string): string; static;
    class function ParseRasterSize(const SixelData: string;
      out PixelW, PixelH: Integer): Boolean; static;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure Draw; override;
    function GetPalette: PPalette; override;
    function LoadFromFile(const AFileName: string): Boolean;
    procedure SetSixelData(const ASixelData: string; APixelWidth, APixelHeight: Integer);
    procedure Clear;
    property Loaded: Boolean read FLoaded;
    property PixelWidth: Integer read FPixelWidth;
    property PixelHeight: Integer read FPixelHeight;
    property SixelData: string read FSixelData;
  end;

implementation

uses
  System.SysUtils, System.Classes, FVScreen;

constructor TSixelView.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  GrowMode := gfGrowHiX or gfGrowHiY;
  Clear;
end;

procedure TSixelView.Clear;
begin
  FSixelData := '';
  FPixelWidth := 0;
  FPixelHeight := 0;
  FLoaded := False;
end;

procedure TSixelView.SetSixelData(const ASixelData: string; APixelWidth, APixelHeight: Integer);
begin
  FSixelData := NormalizeSixelData(ASixelData);
  FPixelWidth := APixelWidth;
  FPixelHeight := APixelHeight;
  if FSixelData = '' then
  begin
    FLoaded := False;
    Exit;
  end;

  if (FPixelWidth <= 0) or (FPixelHeight <= 0) then
  begin
    if not ParseRasterSize(FSixelData, FPixelWidth, FPixelHeight) then
    begin
      FPixelWidth := 0;
      FPixelHeight := 0;
      FLoaded := False;
      Exit;
    end;
  end;

  FLoaded := (FPixelWidth > 0) and (FPixelHeight > 0);
end;

function TSixelView.LoadFromFile(const AFileName: string): Boolean;
var
  F: TFileStream;
  Bytes: TBytes;
  RawData: string;
  PixelW, PixelH: Integer;
begin
  Result := False;
  Clear;
  if not FileExists(AFileName) then Exit;

  F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    if (F.Size <= 0) or (F.Size > MaxInt) then Exit;
    SetLength(Bytes, Integer(F.Size));
    F.ReadBuffer(Bytes[0], Length(Bytes));
    SetString(RawData, PAnsiChar(@Bytes[0]), Length(Bytes));
  finally
    F.Free;
  end;

  PixelW := 0;
  PixelH := 0;
  SetSixelData(RawData, PixelW, PixelH);
  Result := FLoaded;
end;

function TSixelView.GetPalette: PPalette;
begin
  Result := nil;
end;

procedure TSixelView.DrawEmpty;
var
  B: TDrawBuffer;
  Y: Integer;
begin
  for Y := 0 to Size.Y - 1 do
  begin
    DrawChar(B, 0, ' ', $07, Size.X);
    WriteLine(0, Y, Size.X, 1, B);
  end;
end;

function TSixelView.DetectCellPixelSize(out CellW, CellH: Integer): Boolean;
begin
  Result := False;
  CellW := 8;
  CellH := 16;

  if (Screen <> nil) and Screen.Initialized then
  begin
    CellW := Screen.CellPixelWidth;
    CellH := Screen.CellPixelHeight;
    Result := (CellW > 0) and (CellH > 0);
  end;

  if not Result then
    Result := TSixelEncoder.GetCellPixelSize(CellW, CellH);

  if CellW < 4 then CellW := 8;
  if CellH < 8 then CellH := 16;
end;

class function TSixelView.NormalizeSixelData(const RawData: string): string;
var
  StartPos: Integer;
  EscEndPos, BelEndPos, EndPos: Integer;
begin
  Result := RawData;
  StartPos := Pos(#27'P', Result);
  if StartPos > 0 then
    Result := Copy(Result, StartPos, MaxInt);

  if Result = '' then Exit;

  if Pos(#27'P', Result) = 0 then
    Result := #27'P0;1q' + Result;

  EscEndPos := Pos(#27'\', Result);
  BelEndPos := Pos(#7, Result);
  EndPos := 0;
  if (EscEndPos > 0) and ((BelEndPos = 0) or (EscEndPos < BelEndPos)) then
    EndPos := EscEndPos + 1
  else if BelEndPos > 0 then
    EndPos := BelEndPos;

  if EndPos > 0 then
    Result := Copy(Result, 1, EndPos)
  else
    Result := Result + #27'\';
end;

class function TSixelView.ParseRasterSize(const SixelData: string;
  out PixelW, PixelH: Integer): Boolean;
var
  I, Count, V, Code: Integer;
  ParamText: string;
  Params: array[0..3] of Integer;
begin
  Result := False;
  PixelW := 0;
  PixelH := 0;

  I := Pos('"', SixelData);
  if I = 0 then Exit;
  Inc(I);

  Count := 0;
  ParamText := '';
  while (I <= Length(SixelData)) and (Count < 4) do
  begin
    if SixelData[I] in ['0'..'9'] then
      ParamText := ParamText + SixelData[I]
    else if SixelData[I] = ';' then
    begin
      if ParamText = '' then Break;
      Val(ParamText, V, Code);
      if Code <> 0 then Exit;
      Params[Count] := V;
      Inc(Count);
      ParamText := '';
    end
    else
      Break;
    Inc(I);
  end;

  if (ParamText <> '') and (Count < 4) then
  begin
    Val(ParamText, V, Code);
    if Code <> 0 then Exit;
    Params[Count] := V;
    Inc(Count);
  end;

  if Count >= 4 then
  begin
    PixelW := Params[2];
    PixelH := Params[3];
  end
  else if Count >= 2 then
  begin
    PixelW := Params[0];
    PixelH := Params[1];
  end
  else
    Exit;

  Result := (PixelW > 0) and (PixelH > 0);
end;

procedure TSixelView.Draw;
var
  B: TDrawBuffer;
  Y: Integer;
  GlobalPt: TPoint;
  CellW, CellH: Integer;
  CoveredW, CoveredH: Integer;
  ScreenX, ScreenY: Integer;
begin
  if not FLoaded then begin DrawEmpty; Exit; end;
  if (Screen = nil) or not Screen.Initialized or not Screen.SixelSupported then
  begin
    DrawEmpty;
    Exit;
  end;
  if FSixelData = '' then begin DrawEmpty; Exit; end;

  GlobalPt.X := 0;
  GlobalPt.Y := 0;
  MakeGlobal(GlobalPt, GlobalPt);
  ScreenX := GlobalPt.X;
  ScreenY := GlobalPt.Y;

  DetectCellPixelSize(CellW, CellH);
  CoveredW := (FPixelWidth + CellW - 1) div CellW;
  CoveredH := (FPixelHeight + CellH - 1) div CellH;

  { Raw SIXEL cannot be source-clipped safely. Emit only when the complete
    raster fits inside view and visible screen area. }
  if (CoveredW <= 0) or (CoveredH <= 0) then begin DrawEmpty; Exit; end;
  if (CoveredW > Size.X) or (CoveredH > Size.Y) then begin DrawEmpty; Exit; end;
  if (ScreenX < 0) or (ScreenY < 0) then begin DrawEmpty; Exit; end;
  if (ScreenX >= Screen.Width) or (ScreenY >= Screen.Height) then begin DrawEmpty; Exit; end;
  if ScreenX + CoveredW > Screen.Width then begin DrawEmpty; Exit; end;
  if ScreenY + CoveredH >= Screen.Height then begin DrawEmpty; Exit; end;

  for Y := 0 to Size.Y - 1 do
  begin
    if (Y < CoveredH) and (CoveredW > 0) then
    begin
      DrawChar(B, 0, SixelPlaceholder, $00, CoveredW);
      if CoveredW < Size.X then
        DrawChar(B, CoveredW, ' ', $07, Size.X - CoveredW);
    end
    else
      DrawChar(B, 0, ' ', $07, Size.X);
    WriteLine(0, Y, Size.X, 1, B);
  end;

  Screen.RegisterSixelRegion(ScreenX, ScreenY, CoveredW, CoveredH, FSixelData);
end;

end.
