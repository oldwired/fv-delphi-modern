{*******************************************************}
{       Free Vision Sixel View                          }
{       Reusable view for pre-encoded SIXEL data        }
{*******************************************************}

unit SixelView;

{$R-} { Range checking off for performance }

interface

uses
  Winapi.Windows,
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

  { Animated view base class with dual rendering: Sixel (primary) + half-block.
    Subclasses override UpdatePixels to fill the pixel buffer each frame.
    Call Update() from the application's Idle loop. }
  TSixelAnimView = class(TView)
  private
    FSixelMode: Boolean;
    FRealtimeMode: Boolean;
    FCellPixelW: Integer;
    FCellPixelH: Integer;
    FSixelData: string;
    FLastEncPixW: Integer;
    FLastEncPixH: Integer;
    FLastUpdate: UInt64;
    FSixelScale: Integer;
    procedure DrawSixel;
    procedure DrawHalfBlock;
  protected
    FSixelDirty: Boolean;
    FPixels: TPixelGrid;
    FPixelW: Integer;
    FPixelH: Integer;
    FUpdateInterval: Integer;
    FTick: Integer;
    procedure EnsurePixelBuffer;
    procedure UpdatePixels; virtual; abstract;
  public
    constructor Create(var Bounds: TRect; AUpdateInterval: Integer); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    procedure SetSixelMode(AValue: Boolean);
    function GetPalette: PPalette; override;
    property SixelMode: Boolean read FSixelMode write SetSixelMode;
    { When True, uses the fast 6x6x6 cube encoder instead of the adaptive
      quality encoder. Best for game engines and animations. }
    property RealtimeMode: Boolean read FRealtimeMode write FRealtimeMode;
    { Sixel render scale divisor: 1=full, 2=half, 4=quarter resolution }
    property SixelScale: Integer read FSixelScale write FSixelScale;
  end;

  { Window wrapper that fixes the TWindow.Close crash (Hide before Close)
    and auto-nils the owner's view field reference on destroy }
  TSixelAnimWindow = class(TWindow)
  private
    FViewRef: Pointer;  { Points to owner's TSixelAnimView field }
  public
    constructor Create(var Bounds: TRect; const ATitle: string;
      AViewRef: Pointer); reintroduce;
    procedure Close; override;
    destructor Destroy; override;
  end;

  { Mutable pixel canvas that renders through SIXEL. Draw into the pixel
    buffer with primitive methods, then call DrawView to present it. }
  TSixelCanvasView = class(TView)
  private
    FPixels: TPixelGrid;
    FPixelWidth: Integer;
    FPixelHeight: Integer;
    FBackgroundColor: Cardinal;
    FSixelData: string;
    FSixelDirty: Boolean;
    FLastSrcX: Integer;
    FLastSrcY: Integer;
    FLastPixW: Integer;
    FLastPixH: Integer;
    procedure DrawEmpty;
    function DetectCellPixelSize(out CellW, CellH: Integer): Boolean;
    procedure MarkDirty;
  public
    constructor Create(var Bounds: TRect; APixelWidth, APixelHeight: Integer); reintroduce; virtual;
    procedure Draw; override;
    function GetPalette: PPalette; override;
    procedure ResizePixels(APixelWidth, APixelHeight: Integer);
    procedure Clear(AColor: Cardinal = $000000);
    procedure SetPixel(X, Y: Integer; AColor: Cardinal);
    procedure FillRect(X, Y, W, H: Integer; AColor: Cardinal);
    procedure DrawLine(X1, Y1, X2, Y2: Integer; AColor: Cardinal);
    procedure InvalidateSixel;
    property PixelWidth: Integer read FPixelWidth;
    property PixelHeight: Integer read FPixelHeight;
    property BackgroundColor: Cardinal read FBackgroundColor write FBackgroundColor;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Math, FVScreen;

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

{ TSixelAnimView }

constructor TSixelAnimView.Create(var Bounds: TRect; AUpdateInterval: Integer);
begin
  inherited Create(Bounds);
  GrowMode := gfGrowHiX or gfGrowHiY;
  FUpdateInterval := AUpdateInterval;
  FTick := 0;
  FLastUpdate := 0;
  FSixelDirty := True;
  FPixelW := 0;
  FPixelH := 0;
  FSixelScale := 1;

  FSixelMode := TSixelEncoder.IsSixelSupported;
  if FSixelMode then
  begin
    if (Screen <> nil) and Screen.Initialized then
    begin
      FCellPixelW := Screen.CellPixelWidth;
      FCellPixelH := Screen.CellPixelHeight;
    end
    else if not TSixelEncoder.GetCellPixelSize(FCellPixelW, FCellPixelH) then
    begin
      FCellPixelW := 8;
      FCellPixelH := 16;
    end;
  end;
end;

procedure TSixelAnimView.EnsurePixelBuffer;
var
  NeedW, NeedH: Integer;
  Scale: Integer;
begin
  if FSixelMode then
  begin
    Scale := FSixelScale;
    if Scale < 1 then Scale := 1;
    NeedW := (Size.X * FCellPixelW) div Scale;
    NeedH := (Size.Y * FCellPixelH) div Scale;
  end
  else
  begin
    NeedW := Size.X;
    NeedH := Size.Y * 2;
  end;
  if NeedW < 1 then NeedW := 1;
  if NeedH < 1 then NeedH := 1;

  if (NeedW <> FPixelW) or (NeedH <> FPixelH) then
  begin
    FPixelW := NeedW;
    FPixelH := NeedH;
    SetLength(FPixels, FPixelH, FPixelW);
    FSixelDirty := True;
  end;
end;

procedure TSixelAnimView.Draw;
begin
  if FSixelMode then
    DrawSixel
  else
    DrawHalfBlock;
end;

procedure TSixelAnimView.DrawHalfBlock;
var
  B: TDrawBuffer;
  X, Y: Integer;
  TopRGB, BotRGB: Cardinal;
begin
  EnsurePixelBuffer;

  for Y := 0 to Size.Y - 1 do
  begin
    DrawChar(B, 0, ' ', $07, Size.X);

    for X := 0 to Size.X - 1 do
    begin
      if (X < FPixelW) and (Y * 2 < FPixelH) then
      begin
        TopRGB := FPixels[Y * 2][X];
        if TopRGB = 0 then TopRGB := 1;

        if Y * 2 + 1 < FPixelH then
          BotRGB := FPixels[Y * 2 + 1][X]
        else
          BotRGB := 1;
        if BotRGB = 0 then BotRGB := 1;

        DrawRGBCell(B, X, #$2580, TopRGB, BotRGB);
      end;
    end;

    WriteLine(0, Y, Size.X, 1, B);
  end;
end;

procedure TSixelAnimView.DrawSixel;
var
  B: TDrawBuffer;
  Y: Integer;
  GlobalPt: TPoint;
  EncCellW, EncCellH: Integer;
  EncSrcX, EncSrcY: Integer;
  EncScreenX, EncScreenY: Integer;
  EncPixW, EncPixH: Integer;
  Scale: Integer;
begin
  if (Screen = nil) or not Screen.Initialized then Exit;

  EnsurePixelBuffer;
  Scale := FSixelScale;
  if Scale < 1 then Scale := 1;

  { Fill all cells with sixel placeholder }
  for Y := 0 to Size.Y - 1 do
  begin
    DrawChar(B, 0, SixelPlaceholder, $00, Size.X);
    WriteLine(0, Y, Size.X, 1, B);
  end;

  { Compute global screen position }
  GlobalPt.X := 0;
  GlobalPt.Y := 0;
  MakeGlobal(GlobalPt, GlobalPt);

  { Start with full view dimensions }
  EncCellW := Size.X;
  EncCellH := Size.Y;
  EncSrcX := 0;
  EncSrcY := 0;
  EncScreenX := GlobalPt.X;
  EncScreenY := GlobalPt.Y;

  { Clamp left edge }
  if EncScreenX < 0 then
  begin
    EncCellW := EncCellW + EncScreenX;
    EncSrcX := (-EncScreenX * FCellPixelW) div Scale;
    EncScreenX := 0;
  end;

  { Clamp top edge }
  if EncScreenY < 0 then
  begin
    EncCellH := EncCellH + EncScreenY;
    EncSrcY := (-EncScreenY * FCellPixelH) div Scale;
    EncScreenY := 0;
  end;

  { Clamp right edge }
  if EncScreenX + EncCellW > Screen.Width then
    EncCellW := Screen.Width - EncScreenX;

  { Clamp bottom edge with 1-row margin }
  if EncScreenY + EncCellH >= Screen.Height then
    EncCellH := Screen.Height - 1 - EncScreenY;

  if (EncCellW <= 0) or (EncCellH <= 0) then Exit;

  { Encode visible portion — pixel buffer is already at scaled resolution }
  EncPixW := (EncCellW * FCellPixelW) div Scale;
  EncPixH := (EncCellH * FCellPixelH) div Scale;

  if FSixelDirty or (EncPixW <> FLastEncPixW) or (EncPixH <> FLastEncPixH) then
  begin
    if FRealtimeMode then
      FSixelData := TSixelEncoder.EncodeRealtime(FPixels, EncSrcX, EncSrcY, EncPixW, EncPixH, Scale)
    else
      FSixelData := TSixelEncoder.Encode(FPixels, EncSrcX, EncSrcY, EncPixW, EncPixH);
    FSixelDirty := False;
    FLastEncPixW := EncPixW;
    FLastEncPixH := EncPixH;
  end;

  if FSixelData <> '' then
    Screen.RegisterSixelRegion(EncScreenX, EncScreenY, EncCellW, EncCellH, FSixelData);
end;

procedure TSixelAnimView.Update;
var
  Now64: UInt64;
begin
  Now64 := GetTickCount64;
  if (Now64 - FLastUpdate) < Cardinal(FUpdateInterval) then Exit;
  FLastUpdate := Now64;

  EnsurePixelBuffer;
  UpdatePixels;
  Inc(FTick);
  FSixelDirty := True;
  DrawView;
end;

function TSixelAnimView.GetPalette: PPalette;
begin
  Result := nil;
end;

procedure TSixelAnimView.SetSixelMode(AValue: Boolean);
begin
  if AValue = FSixelMode then Exit;
  FSixelMode := AValue;
  { Force pixel buffer reallocation for new resolution }
  FPixelW := 0;
  FPixelH := 0;
  FSixelDirty := True;
end;

{ TSixelAnimWindow }

constructor TSixelAnimWindow.Create(var Bounds: TRect; const ATitle: string;
  AViewRef: Pointer);
begin
  inherited Create(Bounds, ATitle, wnNoNumber);
  Options := Options or ofTileable;
  FViewRef := AViewRef;
end;

procedure TSixelAnimWindow.Close;
begin
  { Hide while subviews are still alive to prevent nil access
    during cascading focus changes in SetState/ResetCurrent }
  Hide;
  inherited Close;
end;

destructor TSixelAnimWindow.Destroy;
begin
  { Nil the owner's field reference so Idle doesn't call Update
    on a freed view }
  if FViewRef <> nil then
    TSixelAnimView(FViewRef^) := nil;
  inherited Destroy;
end;

{ TSixelCanvasView }

constructor TSixelCanvasView.Create(var Bounds: TRect; APixelWidth,
  APixelHeight: Integer);
begin
  inherited Create(Bounds);
  GrowMode := gfGrowHiX or gfGrowHiY;
  FBackgroundColor := $000000;
  FSixelData := '';
  FSixelDirty := True;
  FLastSrcX := -1;
  FLastSrcY := -1;
  FLastPixW := -1;
  FLastPixH := -1;
  ResizePixels(APixelWidth, APixelHeight);
end;

procedure TSixelCanvasView.MarkDirty;
begin
  FSixelDirty := True;
end;

procedure TSixelCanvasView.ResizePixels(APixelWidth, APixelHeight: Integer);
var
  Y: Integer;
begin
  if APixelWidth < 1 then APixelWidth := 1;
  if APixelHeight < 1 then APixelHeight := 1;
  if (APixelWidth = FPixelWidth) and (APixelHeight = FPixelHeight) then Exit;

  FPixelWidth := APixelWidth;
  FPixelHeight := APixelHeight;
  SetLength(FPixels, FPixelHeight);
  for Y := 0 to FPixelHeight - 1 do
    SetLength(FPixels[Y], FPixelWidth);

  Clear(FBackgroundColor);
  FSixelData := '';
  FLastSrcX := -1;
  FLastSrcY := -1;
  FLastPixW := -1;
  FLastPixH := -1;
  FSixelDirty := True;
end;

procedure TSixelCanvasView.Clear(AColor: Cardinal);
var
  X, Y: Integer;
begin
  FBackgroundColor := AColor and $00FFFFFF;
  if (FPixelWidth <= 0) or (FPixelHeight <= 0) then Exit;
  for Y := 0 to FPixelHeight - 1 do
    for X := 0 to FPixelWidth - 1 do
      FPixels[Y][X] := FBackgroundColor;
  MarkDirty;
end;

procedure TSixelCanvasView.SetPixel(X, Y: Integer; AColor: Cardinal);
begin
  if (X < 0) or (Y < 0) or (X >= FPixelWidth) or (Y >= FPixelHeight) then Exit;
  FPixels[Y][X] := AColor and $00FFFFFF;
  MarkDirty;
end;

procedure TSixelCanvasView.FillRect(X, Y, W, H: Integer; AColor: Cardinal);
var
  X1, Y1, X2, Y2: Integer;
  I, J: Integer;
  C: Cardinal;
begin
  if (W <= 0) or (H <= 0) then Exit;
  X1 := X;
  Y1 := Y;
  X2 := X + W;
  Y2 := Y + H;
  if X1 < 0 then X1 := 0;
  if Y1 < 0 then Y1 := 0;
  if X2 > FPixelWidth then X2 := FPixelWidth;
  if Y2 > FPixelHeight then Y2 := FPixelHeight;
  if (X1 >= X2) or (Y1 >= Y2) then Exit;

  C := AColor and $00FFFFFF;
  for J := Y1 to Y2 - 1 do
    for I := X1 to X2 - 1 do
      FPixels[J][I] := C;
  MarkDirty;
end;

procedure TSixelCanvasView.DrawLine(X1, Y1, X2, Y2: Integer; AColor: Cardinal);
var
  Dx, Dy, SX, SY: Integer;
  Err, E2: Integer;
  C: Cardinal;
begin
  C := AColor and $00FFFFFF;

  if X1 < X2 then SX := 1 else SX := -1;
  if Y1 < Y2 then SY := 1 else SY := -1;
  Dx := Abs(X2 - X1);
  Dy := -Abs(Y2 - Y1);
  Err := Dx + Dy;

  while True do
  begin
    if (X1 >= 0) and (Y1 >= 0) and (X1 < FPixelWidth) and (Y1 < FPixelHeight) then
      FPixels[Y1][X1] := C;
    if (X1 = X2) and (Y1 = Y2) then Break;
    E2 := Err shl 1;
    if E2 >= Dy then
    begin
      Err := Err + Dy;
      Inc(X1, SX);
    end;
    if E2 <= Dx then
    begin
      Err := Err + Dx;
      Inc(Y1, SY);
    end;
  end;

  MarkDirty;
end;

procedure TSixelCanvasView.InvalidateSixel;
begin
  MarkDirty;
end;

procedure TSixelCanvasView.DrawEmpty;
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

function TSixelCanvasView.DetectCellPixelSize(out CellW, CellH: Integer): Boolean;
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

function TSixelCanvasView.GetPalette: PPalette;
begin
  Result := nil;
end;

procedure TSixelCanvasView.Draw;
var
  B: TDrawBuffer;
  Y: Integer;
  GlobalPt: TPoint;
  CellW, CellH: Integer;
  VisiblePixW, VisiblePixH: Integer;
  CoveredW, CoveredH: Integer;
  EncCellW, EncCellH: Integer;
  EncPixW, EncPixH: Integer;
  EncSrcX, EncSrcY: Integer;
  EncScreenX, EncScreenY: Integer;
begin
  if (FPixelWidth <= 0) or (FPixelHeight <= 0) or (Length(FPixels) = 0) then
  begin
    DrawEmpty;
    Exit;
  end;

  if (Screen = nil) or not Screen.Initialized or not Screen.SixelSupported then
  begin
    DrawEmpty;
    Exit;
  end;

  DetectCellPixelSize(CellW, CellH);

  VisiblePixW := Size.X * CellW;
  VisiblePixH := Size.Y * CellH;
  if VisiblePixW > FPixelWidth then VisiblePixW := FPixelWidth;
  if VisiblePixH > FPixelHeight then VisiblePixH := FPixelHeight;
  if (VisiblePixW <= 0) or (VisiblePixH <= 0) then
  begin
    DrawEmpty;
    Exit;
  end;

  CoveredW := (VisiblePixW + CellW - 1) div CellW;
  CoveredH := (VisiblePixH + CellH - 1) div CellH;
  if CoveredW > Size.X then CoveredW := Size.X;
  if CoveredH > Size.Y then CoveredH := Size.Y;

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

  GlobalPt.X := 0;
  GlobalPt.Y := 0;
  MakeGlobal(GlobalPt, GlobalPt);

  EncScreenX := GlobalPt.X;
  EncScreenY := GlobalPt.Y;
  EncCellW := CoveredW;
  EncCellH := CoveredH;
  EncSrcX := 0;
  EncSrcY := 0;

  if EncScreenX < 0 then
  begin
    EncCellW := EncCellW + EncScreenX;
    EncSrcX := EncSrcX - EncScreenX * CellW;
    EncScreenX := 0;
  end;
  if EncScreenY < 0 then
  begin
    EncCellH := EncCellH + EncScreenY;
    EncSrcY := EncSrcY - EncScreenY * CellH;
    EncScreenY := 0;
  end;
  if EncScreenX + EncCellW > Screen.Width then
    EncCellW := Screen.Width - EncScreenX;
  if EncScreenY + EncCellH >= Screen.Height then
    EncCellH := Screen.Height - 1 - EncScreenY;
  if (EncCellW <= 0) or (EncCellH <= 0) then Exit;

  EncPixW := EncCellW * CellW;
  EncPixH := EncCellH * CellH;
  if EncSrcX + EncPixW > FPixelWidth then
    EncPixW := FPixelWidth - EncSrcX;
  if EncSrcY + EncPixH > FPixelHeight then
    EncPixH := FPixelHeight - EncSrcY;
  if (EncPixW <= 0) or (EncPixH <= 0) then Exit;

  EncCellW := (EncPixW + CellW - 1) div CellW;
  EncCellH := (EncPixH + CellH - 1) div CellH;
  if (EncCellW <= 0) or (EncCellH <= 0) then Exit;

  if FSixelDirty or
     (EncSrcX <> FLastSrcX) or (EncSrcY <> FLastSrcY) or
     (EncPixW <> FLastPixW) or (EncPixH <> FLastPixH) then
  begin
    FSixelData := TSixelEncoder.Encode(FPixels, EncSrcX, EncSrcY, EncPixW, EncPixH);
    FSixelDirty := False;
    FLastSrcX := EncSrcX;
    FLastSrcY := EncSrcY;
    FLastPixW := EncPixW;
    FLastPixH := EncPixH;
  end;

  if FSixelData <> '' then
    Screen.RegisterSixelRegion(EncScreenX, EncScreenY, EncCellW, EncCellH, FSixelData);
end;

end.
