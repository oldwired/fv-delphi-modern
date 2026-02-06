{*******************************************************}
{       Free Vision ImageView - BMP Image Viewer       }
{       Sixel graphics (primary) with half-block        }
{       character fallback for 24-bit RGB rendering     }
{*******************************************************}

unit ImageView;

{$R-} { Range checking off for performance }

interface

uses
  FVCommon, Drivers, Views, FVConsts, SixelEncoder;

const
  BlockUpper = #$2580;  { Upper half block character }

type
  { BMP file parser - supports 24-bit and 32-bit uncompressed BMPs }
  TBMPImage = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FLoaded: Boolean;
  public
    FPixels: TPixelGrid;  { [Y][X] = $00RRGGBB }
    constructor Create;
    destructor Destroy; override;
    function LoadFromFile(const AFileName: string): Boolean;
    function GetPixel(X, Y: Integer): Cardinal;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Loaded: Boolean read FLoaded;
  end;

  { Image view with Sixel graphics (primary) and half-block fallback }
  TImageView = class(TView)
  private
    FImage: TBMPImage;
    FOffsetX: Integer;
    FOffsetY: Integer;
    FFileName: string;
    FSixelMode: Boolean;       { True if Sixel rendering is active }
    FCellPixelW: Integer;      { Cell width in pixels }
    FCellPixelH: Integer;      { Cell height in pixels }
    FSixelData: string;        { Cached encoded Sixel DCS string }
    FSixelDirty: Boolean;      { True when Sixel re-encoding is needed }
    FLastEncPixW: Integer;     { Pixel width of last encode (for resize detection) }
    FLastEncPixH: Integer;     { Pixel height of last encode }
    FHScrollBar: TScrollBar;   { Linked horizontal scrollbar (set by owner) }
    FVScrollBar: TScrollBar;   { Linked vertical scrollbar (set by owner) }
    procedure DrawSixel;
    procedure DrawHalfBlock;
    procedure UpdateScrollBars;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    destructor Destroy; override;
    procedure LoadFromFile(const AFileName: string);
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    function GetPalette: PPalette; override;
    property Image: TBMPImage read FImage;
    property OffsetX: Integer read FOffsetX write FOffsetX;
    property OffsetY: Integer read FOffsetY write FOffsetY;
    property SixelMode: Boolean read FSixelMode;
  end;

  { Image window with scrollbars }
  TImageWindow = class(TWindow)
  private
    FImageView: TImageView;
    FHScrollBar: TScrollBar;
    FVScrollBar: TScrollBar;
  public
    constructor Create(const AFileName: string); reintroduce; virtual;
    procedure ChangeBounds(var Bounds: TRect); override;
    procedure HandleEvent(var Event: TEvent); override;
    property ImageView: TImageView read FImageView;
  end;

implementation

uses
  System.SysUtils, System.Classes, App, FVScreen;

{***************************************************************************}
{                        TBMPImage IMPLEMENTATION                          }
{***************************************************************************}

constructor TBMPImage.Create;
begin
  inherited Create;
  FWidth := 0;
  FHeight := 0;
  FLoaded := False;
end;

destructor TBMPImage.Destroy;
begin
  FPixels := nil;
  inherited Destroy;
end;

function TBMPImage.LoadFromFile(const AFileName: string): Boolean;
var
  F: TFileStream;
  FileHeader: packed record
    bfType: Word;
    bfSize: Cardinal;
    bfReserved1: Word;
    bfReserved2: Word;
    bfOffBits: Cardinal;
  end;
  InfoHeader: packed record
    biSize: Cardinal;
    biWidth: Integer;
    biHeight: Integer;
    biPlanes: Word;
    biBitCount: Word;
    biCompression: Cardinal;
    biSizeImage: Cardinal;
    biXPelsPerMeter: Integer;
    biYPelsPerMeter: Integer;
    biClrUsed: Cardinal;
    biClrImportant: Cardinal;
  end;
  RowSize: Integer;
  Row: TBytes;
  X, Y, SrcY: Integer;
  B, G, R: Byte;
  BottomUp: Boolean;
  ColorTable: array of Cardinal;  { BGRA entries from BMP color table }
  NumColors: Integer;
  ColorEntry: packed record B, G, R, A: Byte; end;
  BitPos: Integer;
  PixelIdx: Byte;
begin
  Result := False;
  FLoaded := False;
  FWidth := 0;
  FHeight := 0;
  FPixels := nil;

  if not FileExists(AFileName) then Exit;

  F := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    { Read file header }
    if F.Size < 54 then Exit;  { Minimum BMP size }
    F.ReadBuffer(FileHeader, SizeOf(FileHeader));
    if FileHeader.bfType <> $4D42 then Exit;  { 'BM' signature }

    { Read info header }
    F.ReadBuffer(InfoHeader, SizeOf(InfoHeader));
    if InfoHeader.biCompression <> 0 then Exit;  { Only BI_RGB supported }
    if not (InfoHeader.biBitCount in [1, 4, 8, 24, 32]) then Exit;
    if (InfoHeader.biWidth <= 0) or (InfoHeader.biWidth > 8192) then Exit;

    FWidth := InfoHeader.biWidth;
    FHeight := Abs(InfoHeader.biHeight);
    BottomUp := InfoHeader.biHeight > 0;  { Standard BMP is bottom-up }

    if (FHeight <= 0) or (FHeight > 8192) then Exit;

    { Read color table for indexed formats }
    if InfoHeader.biBitCount <= 8 then
    begin
      NumColors := InfoHeader.biClrUsed;
      if NumColors = 0 then
        NumColors := 1 shl InfoHeader.biBitCount;
      SetLength(ColorTable, NumColors);
      { Seek to color table (right after info header) }
      F.Position := 14 + InfoHeader.biSize;
      for X := 0 to NumColors - 1 do
      begin
        F.ReadBuffer(ColorEntry, 4);
        ColorTable[X] := (Cardinal(ColorEntry.R) shl 16) or
                          (Cardinal(ColorEntry.G) shl 8) or
                          Cardinal(ColorEntry.B);
      end;
    end;

    { Calculate row size with padding to 4-byte boundary }
    RowSize := ((FWidth * InfoHeader.biBitCount + 31) div 32) * 4;

    { Allocate pixel array }
    SetLength(FPixels, FHeight, FWidth);

    { Seek to pixel data }
    F.Position := FileHeader.bfOffBits;

    { Read pixel rows }
    SetLength(Row, RowSize);
    for Y := 0 to FHeight - 1 do
    begin
      if F.Read(Row[0], RowSize) < RowSize then Exit;

      if BottomUp then
        SrcY := FHeight - 1 - Y
      else
        SrcY := Y;

      case InfoHeader.biBitCount of
        1: begin
          for X := 0 to FWidth - 1 do
          begin
            BitPos := 7 - (X and 7);
            PixelIdx := (Row[X shr 3] shr BitPos) and 1;
            if PixelIdx < Length(ColorTable) then
              FPixels[SrcY][X] := ColorTable[PixelIdx]
            else
              FPixels[SrcY][X] := 0;
          end;
        end;
        4: begin
          for X := 0 to FWidth - 1 do
          begin
            if (X and 1) = 0 then
              PixelIdx := (Row[X shr 1] shr 4) and $0F
            else
              PixelIdx := Row[X shr 1] and $0F;
            if PixelIdx < Length(ColorTable) then
              FPixels[SrcY][X] := ColorTable[PixelIdx]
            else
              FPixels[SrcY][X] := 0;
          end;
        end;
        8: begin
          for X := 0 to FWidth - 1 do
          begin
            PixelIdx := Row[X];
            if PixelIdx < Length(ColorTable) then
              FPixels[SrcY][X] := ColorTable[PixelIdx]
            else
              FPixels[SrcY][X] := 0;
          end;
        end;
        24: begin
          for X := 0 to FWidth - 1 do
          begin
            B := Row[X * 3];
            G := Row[X * 3 + 1];
            R := Row[X * 3 + 2];
            FPixels[SrcY][X] := (Cardinal(R) shl 16) or (Cardinal(G) shl 8) or Cardinal(B);
          end;
        end;
        32: begin
          for X := 0 to FWidth - 1 do
          begin
            B := Row[X * 4];
            G := Row[X * 4 + 1];
            R := Row[X * 4 + 2];
            FPixels[SrcY][X] := (Cardinal(R) shl 16) or (Cardinal(G) shl 8) or Cardinal(B);
          end;
        end;
      end;
    end;

    FLoaded := True;
    Result := True;
  finally
    F.Free;
  end;
end;

function TBMPImage.GetPixel(X, Y: Integer): Cardinal;
begin
  if (X >= 0) and (X < FWidth) and (Y >= 0) and (Y < FHeight) then
    Result := FPixels[Y][X]
  else
    Result := 0;
end;

{***************************************************************************}
{                        TImageView IMPLEMENTATION                         }
{***************************************************************************}

constructor TImageView.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FImage := TBMPImage.Create;
  FOffsetX := 0;
  FOffsetY := 0;
  GrowMode := gfGrowHiX or gfGrowHiY;
  EventMask := EventMask or evKeyDown;
  FSixelMode := TSixelEncoder.IsSixelSupported;
  if FSixelMode then
  begin
    { Prefer Screen's detected values - includes VT-based auto-detection
      which is accurate under ConPTY/Windows Terminal with custom font sizes }
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
  FSixelDirty := True;
end;

destructor TImageView.Destroy;
begin
  FImage.Free;
  inherited Destroy;
end;

procedure TImageView.LoadFromFile(const AFileName: string);
begin
  FFileName := AFileName;
  FImage.LoadFromFile(AFileName);
  FOffsetX := 0;
  FOffsetY := 0;
  FSixelDirty := True;
  DrawView;
end;

procedure TImageView.Draw;
begin
  if FSixelMode then
    DrawSixel
  else
    DrawHalfBlock;
end;

procedure TImageView.DrawHalfBlock;
var
  B: TDrawBuffer;
  X, Y: Integer;
  ImgRow0, ImgRow1: Integer;
  ImgCol: Integer;
  TopRGB, BotRGB: Cardinal;
  ViewW, ViewH: Integer;
begin
  ViewW := Size.X;
  ViewH := Size.Y;

  for Y := 0 to ViewH - 1 do
  begin
    { Each view row maps to 2 image rows (top and bottom half of block) }
    ImgRow0 := (FOffsetY + Y) * 2;
    ImgRow1 := ImgRow0 + 1;

    { Fill the draw buffer }
    DrawChar(B, 0, ' ', $07, ViewW);

    if FImage.Loaded then
    begin
      for X := 0 to ViewW - 1 do
      begin
        ImgCol := FOffsetX + X;
        if (ImgCol >= 0) and (ImgCol < FImage.Width) then
        begin
          { Get top pixel (foreground of upper half block) }
          if (ImgRow0 >= 0) and (ImgRow0 < FImage.Height) then
            TopRGB := FImage.GetPixel(ImgCol, ImgRow0)
          else
            TopRGB := 0;

          { Get bottom pixel (background) }
          if (ImgRow1 >= 0) and (ImgRow1 < FImage.Height) then
            BotRGB := FImage.GetPixel(ImgCol, ImgRow1)
          else
            BotRGB := 0;

          { Use upper half block: FG = top pixel, BG = bottom pixel }
          { Special case: if both are black ($000000), use $000001 to
            distinguish from "no RGB" (which is 0) }
          if TopRGB = 0 then TopRGB := 1;
          if BotRGB = 0 then BotRGB := 1;
          DrawRGBCell(B, X, BlockUpper, TopRGB, BotRGB);
        end;
      end;
    end;

    WriteLine(0, Y, ViewW, 1, B);
  end;
end;

procedure TImageView.DrawSixel;
var
  B: TDrawBuffer;
  Y: Integer;
  GlobalPt: TPoint;
  PixW, PixH: Integer;
  SrcX, SrcY: Integer;
  ImgPixW, ImgPixH: Integer;
  CoveredW, CoveredH: Integer;
  EncCellW, EncCellH: Integer;
  EncPixW, EncPixH: Integer;
  EncSrcX, EncSrcY: Integer;
  EncScreenX, EncScreenY: Integer;
begin
  if not FImage.Loaded then
  begin
    { No image loaded: fill everything with spaces }
    for Y := 0 to Size.Y - 1 do
    begin
      DrawChar(B, 0, ' ', $07, Size.X);
      WriteLine(0, Y, Size.X, 1, B);
    end;
    Exit;
  end;

  if (Screen = nil) or not Screen.Initialized then Exit;

  { Source offset in image pixels }
  SrcX := FOffsetX * FCellPixelW;
  SrcY := FOffsetY * FCellPixelH;

  { Compute how many image pixels are actually visible }
  PixW := Size.X * FCellPixelW;
  PixH := Size.Y * FCellPixelH;
  ImgPixW := FImage.Width - SrcX;
  if ImgPixW > PixW then ImgPixW := PixW;
  if ImgPixW < 0 then ImgPixW := 0;
  ImgPixH := FImage.Height - SrcY;
  if ImgPixH > PixH then ImgPixH := PixH;
  if ImgPixH < 0 then ImgPixH := 0;

  { How many cells are covered by actual image content }
  CoveredW := (ImgPixW + FCellPixelW - 1) div FCellPixelW;
  CoveredH := (ImgPixH + FCellPixelH - 1) div FCellPixelH;
  if CoveredW > Size.X then CoveredW := Size.X;
  if CoveredH > Size.Y then CoveredH := Size.Y;

  { Fill cells: placeholder for image area, spaces for uncovered area.
    Only placeholder cells get skipped by Phase 2 rendering; spaces
    render normally so stale content gets cleared. }
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

  { Compute global screen position of this view }
  GlobalPt.X := 0;
  GlobalPt.Y := 0;
  MakeGlobal(GlobalPt, GlobalPt);

  { Clip Sixel region to screen bounds on all 4 edges.
    - Left/top: adjust source offset so we encode only the visible portion
    - Right: terminal clips naturally but we clamp for consistency
    - Bottom: Sixel touching the last row causes cursor-advance scrolling,
      so we leave a 1-row margin }
  EncCellW := CoveredW;
  EncCellH := CoveredH;
  EncSrcX := SrcX;
  EncSrcY := SrcY;
  EncScreenX := GlobalPt.X;
  EncScreenY := GlobalPt.Y;

  { Clamp left edge: advance source, start at screen column 0 }
  if EncScreenX < 0 then
  begin
    EncCellW := EncCellW + EncScreenX;
    EncSrcX := EncSrcX - EncScreenX * FCellPixelW;
    EncScreenX := 0;
  end;

  { Clamp top edge: advance source, start at screen row 0 }
  if EncScreenY < 0 then
  begin
    EncCellH := EncCellH + EncScreenY;
    EncSrcY := EncSrcY - EncScreenY * FCellPixelH;
    EncScreenY := 0;
  end;

  { Clamp right edge }
  if EncScreenX + EncCellW > Screen.Width then
    EncCellW := Screen.Width - EncScreenX;

  { Clamp bottom edge with 1-row margin to prevent scroll }
  if EncScreenY + EncCellH >= Screen.Height then
    EncCellH := Screen.Height - 1 - EncScreenY;

  { Skip if nothing visible after clipping }
  if (EncCellW <= 0) or (EncCellH <= 0) then Exit;

  { Encode only the screen-visible portion of the image }
  EncPixW := EncCellW * FCellPixelW;
  EncPixH := EncCellH * FCellPixelH;

  if FSixelDirty or (EncPixW <> FLastEncPixW) or (EncPixH <> FLastEncPixH) then
  begin
    FSixelData := TSixelEncoder.Encode(
      FImage.FPixels, EncSrcX, EncSrcY, EncPixW, EncPixH);
    FSixelDirty := False;
    FLastEncPixW := EncPixW;
    FLastEncPixH := EncPixH;
  end;

  { Register Sixel region with clamped screen position and dimensions }
  if FSixelData <> '' then
    Screen.RegisterSixelRegion(
      EncScreenX, EncScreenY, EncCellW, EncCellH, FSixelData);
end;

procedure TImageView.HandleEvent(var Event: TEvent);
var
  MaxOffX, MaxOffY: Integer;
begin
  inherited HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    if FSixelMode then
    begin
      { Sixel mode: offsets are in cell units, each cell = CellPixel pixels }
      MaxOffX := (FImage.Width - Size.X * FCellPixelW + FCellPixelW - 1) div FCellPixelW;
      MaxOffY := (FImage.Height - Size.Y * FCellPixelH + FCellPixelH - 1) div FCellPixelH;
    end
    else
    begin
      { Half-block mode: 1 cell = 1 column, 2 rows }
      MaxOffX := FImage.Width - Size.X;
      MaxOffY := (FImage.Height + 1) div 2 - Size.Y;
    end;
    if MaxOffX < 0 then MaxOffX := 0;
    if MaxOffY < 0 then MaxOffY := 0;

    case Event.KeyCode of
      kbLeft:
        if FOffsetX > 0 then Dec(FOffsetX);
      kbRight:
        if FOffsetX < MaxOffX then Inc(FOffsetX);
      kbUp:
        if FOffsetY > 0 then Dec(FOffsetY);
      kbDown:
        if FOffsetY < MaxOffY then Inc(FOffsetY);
      kbHome:
        begin
          FOffsetX := 0;
          FOffsetY := 0;
        end;
      kbEnd:
        begin
          FOffsetX := MaxOffX;
          FOffsetY := MaxOffY;
        end;
      kbPgUp:
        begin
          Dec(FOffsetY, Size.Y);
          if FOffsetY < 0 then FOffsetY := 0;
        end;
      kbPgDn:
        begin
          Inc(FOffsetY, Size.Y);
          if FOffsetY > MaxOffY then FOffsetY := MaxOffY;
        end;
    else
      Exit;
    end;
    FSixelDirty := True;
    DrawView;
    UpdateScrollBars;
    ClearEvent(Event);
  end;
end;

procedure TImageView.UpdateScrollBars;
var
  MaxH, MaxV: Integer;
begin
  if not FImage.Loaded then Exit;

  if FSixelMode then
  begin
    MaxH := (FImage.Width - Size.X * FCellPixelW + FCellPixelW - 1) div FCellPixelW;
    MaxV := (FImage.Height - Size.Y * FCellPixelH + FCellPixelH - 1) div FCellPixelH;
  end
  else
  begin
    MaxH := FImage.Width - Size.X;
    MaxV := (FImage.Height + 1) div 2 - Size.Y;
  end;

  if MaxH < 0 then MaxH := 0;
  if MaxV < 0 then MaxV := 0;

  if FHScrollBar <> nil then
    FHScrollBar.SetParams(FOffsetX, 0, MaxH, Size.X, 1);
  if FVScrollBar <> nil then
    FVScrollBar.SetParams(FOffsetY, 0, MaxV, Size.Y, 1);
end;

function TImageView.GetPalette: PPalette;
begin
  Result := nil;  { Uses RGB directly, no palette needed }
end;

{***************************************************************************}
{                       TImageWindow IMPLEMENTATION                        }
{***************************************************************************}

constructor TImageWindow.Create(const AFileName: string);
var
  R: TRect;
  Title: string;
  DW, DH: Integer;
begin
  Desktop.GetExtent(R);
  { Size the window to ~50% of the desktop, centered }
  DW := R.B.X - R.A.X;
  DH := R.B.Y - R.A.Y;
  R.Assign(R.A.X + DW div 4, R.A.Y + DH div 4,
           R.B.X - DW div 4, R.B.Y - DH div 4);

  Title := ExtractFileName(AFileName);
  inherited Create(R, Title, wnNoNumber);

  Options := Options or ofTileable;

  FHScrollBar := StandardScrollBar(sbHorizontal or sbHandleKeyboard);
  FVScrollBar := StandardScrollBar(sbVertical or sbHandleKeyboard);

  GetExtent(R);
  R.Grow(-1, -1);
  FImageView := TImageView.Create(R);
  FImageView.GrowMode := gfGrowHiX or gfGrowHiY;
  Insert(FImageView);

  { Wire scrollbar references so TImageView can update them directly }
  FImageView.FHScrollBar := FHScrollBar;
  FImageView.FVScrollBar := FVScrollBar;

  FImageView.LoadFromFile(AFileName);

  { Update title with dimensions and mode }
  if FImageView.Image.Loaded then
  begin
    Title := Title + ' (' + IntToStr(FImageView.Image.Width) + 'x' +
      IntToStr(FImageView.Image.Height) + ')';
    if FImageView.SixelMode then
      Title := Title + ' [Sixel]'
    else
      Title := Title + ' [HalfBlock]';
  end;
  Self.Title := Title;

  FImageView.UpdateScrollBars;
end;

procedure TImageWindow.ChangeBounds(var Bounds: TRect);
begin
  inherited ChangeBounds(Bounds);
  if FImageView <> nil then
  begin
    FImageView.FSixelDirty := True;
    FImageView.UpdateScrollBars;
  end;
end;

procedure TImageWindow.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmScrollBarChanged) then
  begin
    if (Event.InfoPtr = FHScrollBar) and (FHScrollBar <> nil) then
    begin
      FImageView.OffsetX := FHScrollBar.Value;
      FImageView.FSixelDirty := True;
      FImageView.DrawView;
      ClearEvent(Event);
    end
    else if (Event.InfoPtr = FVScrollBar) and (FVScrollBar <> nil) then
    begin
      FImageView.OffsetY := FVScrollBar.Value;
      FImageView.FSixelDirty := True;
      FImageView.DrawView;
      ClearEvent(Event);
    end;
  end;
end;

end.
