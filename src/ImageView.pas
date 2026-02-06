{*******************************************************}
{       Free Vision ImageView - BMP Image Viewer       }
{       Uses half-block characters with 24-bit RGB     }
{*******************************************************}

unit ImageView;

{$R-} { Range checking off for performance }

interface

uses
  FVCommon, Drivers, Views, FVConsts;

const
  BlockUpper = #$2580;  { Upper half block character }

type
  { BMP file parser - supports 24-bit and 32-bit uncompressed BMPs }
  TBMPImage = class
  private
    FPixels: array of array of Cardinal;  { [Y][X] = $00RRGGBB }
    FWidth: Integer;
    FHeight: Integer;
    FLoaded: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromFile(const AFileName: string): Boolean;
    function GetPixel(X, Y: Integer): Cardinal;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Loaded: Boolean read FLoaded;
  end;

  { Image view using half-block character rendering }
  TImageView = class(TView)
  private
    FImage: TBMPImage;
    FOffsetX: Integer;
    FOffsetY: Integer;
    FFileName: string;
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
  end;

  { Image window with scrollbars }
  TImageWindow = class(TWindow)
  private
    FImageView: TImageView;
    FHScrollBar: TScrollBar;
    FVScrollBar: TScrollBar;
    procedure UpdateScrollBars;
  public
    constructor Create(const AFileName: string); reintroduce; virtual;
    procedure HandleEvent(var Event: TEvent); override;
    property ImageView: TImageView read FImageView;
  end;

implementation

uses
  System.SysUtils, System.Classes, App;

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
  DrawView;
end;

procedure TImageView.Draw;
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

procedure TImageView.HandleEvent(var Event: TEvent);
var
  MaxOffX, MaxOffY: Integer;
begin
  inherited HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbLeft:
        if FOffsetX > 0 then Dec(FOffsetX);
      kbRight:
        begin
          MaxOffX := FImage.Width - Size.X;
          if MaxOffX < 0 then MaxOffX := 0;
          if FOffsetX < MaxOffX then Inc(FOffsetX);
        end;
      kbUp:
        if FOffsetY > 0 then Dec(FOffsetY);
      kbDown:
        begin
          MaxOffY := (FImage.Height + 1) div 2 - Size.Y;
          if MaxOffY < 0 then MaxOffY := 0;
          if FOffsetY < MaxOffY then Inc(FOffsetY);
        end;
      kbHome:
        begin
          FOffsetX := 0;
          FOffsetY := 0;
        end;
      kbEnd:
        begin
          MaxOffX := FImage.Width - Size.X;
          if MaxOffX < 0 then MaxOffX := 0;
          FOffsetX := MaxOffX;
          MaxOffY := (FImage.Height + 1) div 2 - Size.Y;
          if MaxOffY < 0 then MaxOffY := 0;
          FOffsetY := MaxOffY;
        end;
      kbPgUp:
        begin
          Dec(FOffsetY, Size.Y);
          if FOffsetY < 0 then FOffsetY := 0;
        end;
      kbPgDn:
        begin
          MaxOffY := (FImage.Height + 1) div 2 - Size.Y;
          if MaxOffY < 0 then MaxOffY := 0;
          Inc(FOffsetY, Size.Y);
          if FOffsetY > MaxOffY then FOffsetY := MaxOffY;
        end;
    else
      Exit;
    end;
    DrawView;
    ClearEvent(Event);
  end;
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
begin
  Desktop.GetExtent(R);
  { Size the window to a reasonable portion of the desktop }
  R.Assign(R.A.X + 2, R.A.Y + 1, R.B.X - 2, R.B.Y - 1);

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

  FImageView.LoadFromFile(AFileName);

  { Update title with dimensions }
  if FImageView.Image.Loaded then
    Title := Title + ' (' + IntToStr(FImageView.Image.Width) + 'x' +
      IntToStr(FImageView.Image.Height) + ')';
  Self.Title := Title;

  UpdateScrollBars;
end;

procedure TImageWindow.UpdateScrollBars;
var
  MaxH, MaxV: Integer;
begin
  if not FImageView.Image.Loaded then Exit;

  MaxH := FImageView.Image.Width - FImageView.Size.X;
  if MaxH < 0 then MaxH := 0;
  MaxV := (FImageView.Image.Height + 1) div 2 - FImageView.Size.Y;
  if MaxV < 0 then MaxV := 0;

  if FHScrollBar <> nil then
  begin
    FHScrollBar.SetParams(FImageView.OffsetX, 0, MaxH, FImageView.Size.X, 1);
  end;
  if FVScrollBar <> nil then
  begin
    FVScrollBar.SetParams(FImageView.OffsetY, 0, MaxV, FImageView.Size.Y, 1);
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
      FImageView.DrawView;
      ClearEvent(Event);
    end
    else if (Event.InfoPtr = FVScrollBar) and (FVScrollBar <> nil) then
    begin
      FImageView.OffsetY := FVScrollBar.Value;
      FImageView.DrawView;
      ClearEvent(Event);
    end;
  end;
end;

end.
