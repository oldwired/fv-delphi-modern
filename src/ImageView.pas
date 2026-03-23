{*******************************************************}
{       Free Vision ImageView - BMP/SIXEL Viewer       }
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
    function LoadSixelFromFile(const AFileName: string): Boolean;
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
    function CellToPixel(CellX, CellY: Integer; out ImgX, ImgY: Integer): Boolean;
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
    FLoaded: Boolean;
  public
    constructor Create(const AFileName: string); reintroduce; virtual;
    procedure ChangeBounds(var Bounds: TRect); override;
    procedure HandleEvent(var Event: TEvent); override;
    property ImageView: TImageView read FImageView;
    property Loaded: Boolean read FLoaded;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.StrUtils, App, FVScreen;

function IsSixelFileName(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.sixel') or (Ext = '.six') or (Ext = '.sxl');
end;

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
  if IsSixelFileName(AFileName) then
  begin
    Result := LoadSixelFromFile(AFileName);
    Exit;
  end;

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

function TImageView.CellToPixel(CellX, CellY: Integer; out ImgX, ImgY: Integer): Boolean;
begin
  if FSixelMode then begin
    ImgX := (CellX + FOffsetX) * FCellPixelW + FCellPixelW div 2;
    ImgY := (CellY + FOffsetY) * FCellPixelH + FCellPixelH div 2;
  end else begin
    { Half-block mode: each cell = 1 pixel wide, 2 pixels tall }
    ImgX := CellX + FOffsetX;
    ImgY := (CellY + FOffsetY) * 2;
  end;
  Result := FImage.Loaded and (ImgX >= 0) and (ImgX < FImage.Width) and
            (ImgY >= 0) and (ImgY < FImage.Height);
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
  FImageView := nil;
  FHScrollBar := nil;
  FVScrollBar := nil;
  FLoaded := False;

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
  FLoaded := FImageView.Image.Loaded;

  { Update title with dimensions and mode }
  if FLoaded then
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

function TBMPImage.LoadSixelFromFile(const AFileName: string): Boolean;
var
  F: TFileStream;
  Bytes: TBytes;
  RawData, Payload: string;
  P, LenPayload: Integer;
  X, Y, MaxX, MaxY: Integer;
  RasterW, RasterH: Integer;
  CurReg, Reg, RepeatCount: Integer;
  Params: array[0..4] of Integer;
  ParamCount: Integer;
  V: Integer;
  Ch: Char;
  OrdCh, Bits, TopBit: Integer;
  PixelX, PixelY, Rep, I: Integer;
  Palette: array of Cardinal;
  CurColor: Cardinal;

  function ParseNumber(const S: string; var Idx: Integer; out N: Integer): Boolean;
  var
    Start, Code: Integer;
    Tmp: string;
  begin
    Start := Idx;
    while (Idx <= LenPayload) and (S[Idx] in ['0'..'9']) do
      Inc(Idx);
    Result := Idx > Start;
    if not Result then
    begin
      N := 0;
      Exit;
    end;
    Tmp := Copy(S, Start, Idx - Start);
    Val(Tmp, N, Code);
    if Code <> 0 then
    begin
      N := 0;
      Result := False;
    end;
  end;

  procedure ReadSemicolonParams(const S: string; var Idx: Integer;
    out Count: Integer);
  var
    K: Integer;
  begin
    for K := Low(Params) to High(Params) do
      Params[K] := -1;
    Count := 0;
    while (Idx <= LenPayload) and (S[Idx] = ';') and (Count <= High(Params)) do
    begin
      Inc(Idx);
      if ParseNumber(S, Idx, V) then
        Params[Count] := V;
      Inc(Count);
    end;
  end;

  function ExtractSixelPayload(const S: string): string;
  var
    DCSPos, QPos: Integer;
    STPosEsc, STPosBel, EndPos: Integer;
  begin
    Result := '';
    DCSPos := Pos(#27'P', S);
    if DCSPos > 0 then
    begin
      QPos := PosEx('q', S, DCSPos + 2);
      if QPos = 0 then Exit;
      STPosEsc := PosEx(#27'\', S, QPos + 1);
      STPosBel := PosEx(#7, S, QPos + 1);
      EndPos := Length(S);
      if (STPosEsc > 0) and ((STPosBel = 0) or (STPosEsc < STPosBel)) then
        EndPos := STPosEsc - 1
      else if STPosBel > 0 then
        EndPos := STPosBel - 1;
      if EndPos >= QPos + 1 then
        Result := Copy(S, QPos + 1, EndPos - QPos)
      else
        Result := '';
    end
    else
    begin
      STPosEsc := Pos(#27'\', S);
      STPosBel := Pos(#7, S);
      EndPos := Length(S);
      if (STPosEsc > 0) and ((STPosBel = 0) or (STPosEsc < STPosBel)) then
        EndPos := STPosEsc - 1
      else if STPosBel > 0 then
        EndPos := STPosBel - 1;
      if EndPos > 0 then
        Result := Copy(S, 1, EndPos);
    end;
  end;

  procedure EnsurePaletteSize(Idx: Integer);
  var
    OldLen, J: Integer;
  begin
    if Idx < 0 then Exit;
    if Idx >= Length(Palette) then
    begin
      OldLen := Length(Palette);
      SetLength(Palette, Idx + 1);
      for J := OldLen to High(Palette) do
        Palette[J] := 0;
    end;
  end;

  function PercentToByte(Pct: Integer): Byte;
  begin
    if Pct < 0 then Pct := 0;
    if Pct > 100 then Pct := 100;
    Result := Byte((Pct * 255 + 50) div 100);
  end;

begin
  Result := False;
  FLoaded := False;
  FWidth := 0;
  FHeight := 0;
  FPixels := nil;

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

  Payload := ExtractSixelPayload(RawData);
  if Payload = '' then Exit;
  LenPayload := Length(Payload);

  { Pass 1: determine raster bounds }
  X := 0;
  Y := 0;
  MaxX := -1;
  MaxY := -1;
  RasterW := 0;
  RasterH := 0;
  CurReg := 0;
  P := 1;
  while P <= LenPayload do
  begin
    Ch := Payload[P];
    case Ch of
      '#':
        begin
          Inc(P);
          if ParseNumber(Payload, P, Reg) then
            CurReg := Reg;
          ReadSemicolonParams(Payload, P, ParamCount);
          Continue;
        end;
      '"':
        begin
          Inc(P);
          for I := 0 to 3 do Params[I] := -1;
          ParamCount := 0;
          if ParseNumber(Payload, P, V) then
          begin
            Params[ParamCount] := V;
            Inc(ParamCount);
          end;
          while (P <= LenPayload) and (Payload[P] = ';') and (ParamCount < 4) do
          begin
            Inc(P);
            if ParseNumber(Payload, P, V) then
              Params[ParamCount] := V;
            Inc(ParamCount);
          end;
          if (ParamCount >= 4) and (Params[2] > 0) and (Params[3] > 0) then
          begin
            RasterW := Params[2];
            RasterH := Params[3];
          end;
          Continue;
        end;
      '!':
        begin
          Inc(P);
          if not ParseNumber(Payload, P, RepeatCount) then
            RepeatCount := 1;
          if RepeatCount < 1 then RepeatCount := 1;
          if P > LenPayload then Break;
          OrdCh := Ord(Payload[P]);
          if (OrdCh >= 63) and (OrdCh <= 126) then
          begin
            Bits := OrdCh - 63;
            if X + RepeatCount - 1 > MaxX then
              MaxX := X + RepeatCount - 1;
            if Bits <> 0 then
            begin
              TopBit := 5;
              while (TopBit > 0) and ((Bits and (1 shl TopBit)) = 0) do
                Dec(TopBit);
              if Y + TopBit > MaxY then
                MaxY := Y + TopBit;
            end;
            Inc(X, RepeatCount);
            Inc(P);
          end;
          Continue;
        end;
      '$':
        begin
          X := 0;
          Inc(P);
          Continue;
        end;
      '-':
        begin
          X := 0;
          Inc(Y, 6);
          Inc(P);
          Continue;
        end;
      #7:
        Break;
      #27:
        begin
          if (P < LenPayload) and (Payload[P + 1] = '\') then Break;
          Inc(P);
          Continue;
        end;
    end;

    OrdCh := Ord(Ch);
    if (OrdCh >= 63) and (OrdCh <= 126) then
    begin
      Bits := OrdCh - 63;
      if X > MaxX then MaxX := X;
      if Bits <> 0 then
      begin
        TopBit := 5;
        while (TopBit > 0) and ((Bits and (1 shl TopBit)) = 0) do
          Dec(TopBit);
        if Y + TopBit > MaxY then
          MaxY := Y + TopBit;
      end;
      Inc(X);
    end;
    Inc(P);
  end;

  if (RasterW > 0) and (RasterH > 0) then
  begin
    FWidth := RasterW;
    FHeight := RasterH;
  end
  else
  begin
    FWidth := MaxX + 1;
    FHeight := MaxY + 1;
  end;

  if (FWidth <= 0) or (FHeight <= 0) then Exit;
  if (FWidth > 8192) or (FHeight > 8192) then Exit;

  SetLength(FPixels, FHeight, FWidth);

  { Pass 2: apply palette definitions and render pixels }
  SetLength(Palette, 16);
  CurReg := 0;
  EnsurePaletteSize(CurReg);
  X := 0;
  Y := 0;
  P := 1;
  while P <= LenPayload do
  begin
    Ch := Payload[P];
    case Ch of
      '#':
        begin
          Inc(P);
          if ParseNumber(Payload, P, Reg) then
            CurReg := Reg;
          if CurReg < 0 then CurReg := 0;
          EnsurePaletteSize(CurReg);
          ReadSemicolonParams(Payload, P, ParamCount);
          if (ParamCount >= 4) and (Params[0] = 2) then
          begin
            Palette[CurReg] := (Cardinal(PercentToByte(Params[1])) shl 16) or
                               (Cardinal(PercentToByte(Params[2])) shl 8) or
                               Cardinal(PercentToByte(Params[3]));
          end;
          Continue;
        end;
      '"':
        begin
          Inc(P);
          if ParseNumber(Payload, P, V) then
          begin
            { Ignore raster params during render pass. }
          end;
          while (P <= LenPayload) and (Payload[P] = ';') do
          begin
            Inc(P);
            ParseNumber(Payload, P, V);
          end;
          Continue;
        end;
      '!':
        begin
          Inc(P);
          if not ParseNumber(Payload, P, RepeatCount) then
            RepeatCount := 1;
          if RepeatCount < 1 then RepeatCount := 1;
          if P > LenPayload then Break;
          OrdCh := Ord(Payload[P]);
          if (OrdCh >= 63) and (OrdCh <= 126) then
          begin
            Bits := OrdCh - 63;
            if (CurReg >= 0) and (CurReg < Length(Palette)) then
              CurColor := Palette[CurReg]
            else
              CurColor := 0;
            for Rep := 0 to RepeatCount - 1 do
            begin
              PixelX := X + Rep;
              if (PixelX < 0) or (PixelX >= FWidth) then Continue;
              for I := 0 to 5 do
              begin
                if (Bits and (1 shl I)) = 0 then Continue;
                PixelY := Y + I;
                if (PixelY >= 0) and (PixelY < FHeight) then
                  FPixels[PixelY][PixelX] := CurColor;
              end;
            end;
            Inc(X, RepeatCount);
            Inc(P);
          end;
          Continue;
        end;
      '$':
        begin
          X := 0;
          Inc(P);
          Continue;
        end;
      '-':
        begin
          X := 0;
          Inc(Y, 6);
          Inc(P);
          Continue;
        end;
      #7:
        Break;
      #27:
        begin
          if (P < LenPayload) and (Payload[P + 1] = '\') then Break;
          Inc(P);
          Continue;
        end;
    end;

    OrdCh := Ord(Ch);
    if (OrdCh >= 63) and (OrdCh <= 126) then
    begin
      Bits := OrdCh - 63;
      if (CurReg >= 0) and (CurReg < Length(Palette)) then
        CurColor := Palette[CurReg]
      else
        CurColor := 0;
      if (X >= 0) and (X < FWidth) then
      begin
        for I := 0 to 5 do
        begin
          if (Bits and (1 shl I)) = 0 then Continue;
          PixelY := Y + I;
          if (PixelY >= 0) and (PixelY < FHeight) then
            FPixels[PixelY][X] := CurColor;
        end;
      end;
      Inc(X);
    end;
    Inc(P);
  end;

  FLoaded := True;
  Result := True;
end;

procedure TImageWindow.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  if FImageView = nil then Exit;
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
