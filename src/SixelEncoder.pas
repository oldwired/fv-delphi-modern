{*******************************************************}
{       Free Vision - Sixel Graphics Encoder            }
{       Encodes pixel data to Sixel DCS strings          }
{       for terminals supporting Sixel graphics          }
{*******************************************************}

unit SixelEncoder;

{$R-} { Range checking off for performance }

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Math,
  System.Generics.Collections;

type
  { Pixel row type for encoder input }
  TPixelRow = array of Cardinal;  { $00RRGGBB per pixel }
  TPixelGrid = array of TPixelRow;

  TSixelEncoder = class
  private
    class var FCachedSupported: Integer;  { -1 = unknown, 0 = no, 1 = yes }
    class var FCachedCellW: Integer;
    class var FCachedCellH: Integer;
    class var FCachedCellDetected: Boolean;
    { Quantize a pixel to a hash encoding its palette percentages.
      Step is the quantization step in percentage points (e.g. 4 = round to
      nearest 4%). Hash = RQ*10201 + GQ*101 + BQ where RQ/GQ/BQ are 0..100. }
    class function QuantPixelHash(RGB: Cardinal; Step: Integer): Integer;
  public
    class function IsSixelSupported: Boolean;
    class function GetCellPixelSize(out CellW, CellH: Integer): Boolean;
    class function Encode(const Pixels: TPixelGrid;
      SrcX, SrcY, SrcW, SrcH: Integer): string;
  end;

implementation

const
  MaxRegisters = 256;

class function TSixelEncoder.QuantPixelHash(RGB: Cardinal; Step: Integer): Integer;
var
  R, G, B: Integer;
  RQ, GQ, BQ: Integer;
  Divisor, HalfDiv: Integer;
begin
  R := (RGB shr 16) and $FF;
  G := (RGB shr 8) and $FF;
  B := RGB and $FF;
  { Round each channel to the nearest percentage multiple of Step.
    Single-step formula avoids double-rounding errors. }
  Divisor := 255 * Step;
  HalfDiv := Divisor div 2;
  RQ := (R * 100 + HalfDiv) div Divisor * Step;
  GQ := (G * 100 + HalfDiv) div Divisor * Step;
  BQ := (B * 100 + HalfDiv) div Divisor * Step;
  if RQ > 100 then RQ := 100;
  if GQ > 100 then GQ := 100;
  if BQ > 100 then BQ := 100;
  Result := RQ * 10201 + GQ * 101 + BQ;
end;

class function TSixelEncoder.IsSixelSupported: Boolean;
begin
  if FCachedSupported < 0 then
  begin
    if GetEnvironmentVariable('WT_SESSION') <> '' then
      FCachedSupported := 1
    else
      FCachedSupported := 0;
  end;
  Result := FCachedSupported = 1;
end;

class function TSixelEncoder.GetCellPixelSize(out CellW, CellH: Integer): Boolean;
var
  hConsole: THandle;
  FontInfo: CONSOLE_FONT_INFOEX;
  EnvW, EnvH: string;
  ValW, ValH, Code: Integer;
begin
  if FCachedCellDetected then
  begin
    CellW := FCachedCellW;
    CellH := FCachedCellH;
    Result := True;
    Exit;
  end;

  Result := False;
  CellW := 8;
  CellH := 16;

  { Priority 1: Environment variable override (FV_CELL_W, FV_CELL_H) }
  EnvW := GetEnvironmentVariable('FV_CELL_W');
  EnvH := GetEnvironmentVariable('FV_CELL_H');
  if (EnvW <> '') and (EnvH <> '') then
  begin
    Val(EnvW, ValW, Code);
    if Code = 0 then
    begin
      Val(EnvH, ValH, Code);
      if (Code = 0) and (ValW >= 4) and (ValH >= 4) then
      begin
        CellW := ValW;
        CellH := ValH;
        Result := True;
        FCachedCellW := CellW;
        FCachedCellH := CellH;
        FCachedCellDetected := True;
        Exit;
      end;
    end;
  end;

  { Priority 2: Console font API (may be inaccurate under ConPTY) }
  hConsole := GetStdHandle(STD_OUTPUT_HANDLE);
  if hConsole <> INVALID_HANDLE_VALUE then
  begin
    FillChar(FontInfo, SizeOf(FontInfo), 0);
    FontInfo.cbSize := SizeOf(FontInfo);
    if GetCurrentConsoleFontEx(hConsole, False, FontInfo) then
    begin
      if (FontInfo.dwFontSize.X > 0) and (FontInfo.dwFontSize.Y > 0) then
      begin
        CellW := FontInfo.dwFontSize.X;
        CellH := FontInfo.dwFontSize.Y;
        Result := True;
      end;
    end;
  end;

  { Fallback: ensure reasonable values }
  if CellW < 4 then CellW := 8;
  if CellH < 8 then CellH := 16;

  FCachedCellW := CellW;
  FCachedCellH := CellH;
  FCachedCellDetected := True;
end;

{ Adaptive palette Sixel encoder.
  Tries progressively coarser quantization steps until unique colors fit
  within 256 registers. Uses a single global palette for all bands. }

class function TSixelEncoder.Encode(const Pixels: TPixelGrid;
  SrcX, SrcY, SrcW, SrcH: Integer): string;
const
  Steps: array[0..5] of Integer = (4, 5, 7, 10, 14, 20);
var
  SB: TStringBuilder;
  PixelH, PixelW: Integer;
  X, Y, I, J: Integer;
  BandY, RowInBand: Integer;
  NumBands: Integer;
  ImgH, ImgW: Integer;
  ClampedW, ClampedH: Integer;
  { Adaptive palette }
  ColorMap: TDictionary<Integer, Integer>;
  RegMap: array of array of Integer;
  NumRegs: Integer;
  QuantStep: Integer;
  Hash: Integer;
  StepIdx: Integer;
  PaletteR, PaletteG, PaletteB: array of Integer;
  PaletteR8, PaletteG8, PaletteB8: array of Byte;
  Pair: TPair<Integer, Integer>;
  UseDither: Boolean;
  DitherEnv: string;
  ErrCurR, ErrCurG, ErrCurB: TArray<Integer>;
  ErrNextR, ErrNextG, ErrNextB: TArray<Integer>;
  ErrTmp: TArray<Integer>;
  R0, G0, B0: Integer;
  AdjR, AdjG, AdjB: Integer;
  BestReg: Integer;
  BestDist, Dist: Integer;
  DR, DG, DB: Integer;
  ErrR, ErrG, ErrB: Integer;
  ErrIdx: Integer;
  { Band encoding }
  BandColors: array[0..MaxRegisters - 1] of Boolean;
  RegIdx: Integer;
  SixelBit: Integer;
  SixelVal: Byte;
  LastVal: Byte;
  RunLen: Integer;
  Overflow: Boolean;
  BandHasColor: Boolean;
begin
  Result := '';
  if (Pixels = nil) or (Length(Pixels) = 0) then Exit;
  ImgH := Length(Pixels);
  ImgW := Length(Pixels[0]);
  if ImgW = 0 then Exit;
  if (SrcW <= 0) or (SrcH <= 0) then Exit;

  { Clamp source rect to image bounds }
  ClampedW := SrcW;
  ClampedH := SrcH;
  if SrcX + ClampedW > ImgW then
    ClampedW := ImgW - SrcX;
  if SrcY + ClampedH > ImgH then
    ClampedH := ImgH - SrcY;
  if SrcX < 0 then begin ClampedW := ClampedW + SrcX; SrcX := 0; end;
  if SrcY < 0 then begin ClampedH := ClampedH + SrcY; SrcY := 0; end;
  if (ClampedW <= 0) or (ClampedH <= 0) then Exit;

  PixelW := ClampedW;
  PixelH := ClampedH;
  NumBands := (PixelH + 5) div 6;

  { Build adaptive color palette: try finest quantization step that fits
    within MaxRegisters color registers }
  ColorMap := TDictionary<Integer, Integer>.Create(512);
  try
    QuantStep := Steps[High(Steps)];
    for StepIdx := Low(Steps) to High(Steps) do
    begin
      ColorMap.Clear;
      NumRegs := 0;
      Overflow := False;

      for Y := 0 to PixelH - 1 do
      begin
        if SrcY + Y >= ImgH then Break;
        for X := 0 to PixelW - 1 do
        begin
          if SrcX + X >= ImgW then Break;
          Hash := QuantPixelHash(Pixels[SrcY + Y][SrcX + X], Steps[StepIdx]);
          if not ColorMap.ContainsKey(Hash) then
          begin
            if NumRegs >= MaxRegisters then
            begin
              Overflow := True;
              Break;
            end;
            ColorMap.Add(Hash, NumRegs);
            Inc(NumRegs);
          end;
        end;
        if Overflow then Break;
      end;

      if not Overflow then
      begin
        QuantStep := Steps[StepIdx];
        Break;
      end;
    end;

    { Safety: if even the coarsest step overflowed, rebuild with step=20 }
    if Overflow then
    begin
      QuantStep := 20;
      ColorMap.Clear;
      NumRegs := 0;
      for Y := 0 to PixelH - 1 do
      begin
        if SrcY + Y >= ImgH then Break;
        for X := 0 to PixelW - 1 do
        begin
          if SrcX + X >= ImgW then Break;
          Hash := QuantPixelHash(Pixels[SrcY + Y][SrcX + X], QuantStep);
          if not ColorMap.ContainsKey(Hash) then
          begin
            ColorMap.Add(Hash, NumRegs);
            Inc(NumRegs);
          end;
        end;
      end;
    end;

    { Extract palette RGB percentages from color hashes }
    SetLength(PaletteR, NumRegs);
    SetLength(PaletteG, NumRegs);
    SetLength(PaletteB, NumRegs);
    SetLength(PaletteR8, NumRegs);
    SetLength(PaletteG8, NumRegs);
    SetLength(PaletteB8, NumRegs);
    for Pair in ColorMap do
    begin
      PaletteR[Pair.Value] := Pair.Key div 10201;
      PaletteG[Pair.Value] := (Pair.Key div 101) mod 101;
      PaletteB[Pair.Value] := Pair.Key mod 101;
    end;
    for I := 0 to NumRegs - 1 do
    begin
      PaletteR8[I] := Byte((PaletteR[I] * 255 + 50) div 100);
      PaletteG8[I] := Byte((PaletteG[I] * 255 + 50) div 100);
      PaletteB8[I] := Byte((PaletteB[I] * 255 + 50) div 100);
    end;

    { Build per-pixel register map for fast encoding.
      Use optional error-diffusion dithering when quantization is coarse
      (or forced via FV_SIXEL_DITHER=1). }
    SetLength(RegMap, PixelH, PixelW);
    DitherEnv := LowerCase(Trim(GetEnvironmentVariable('FV_SIXEL_DITHER')));
    UseDither := QuantStep >= 5;
    if (DitherEnv = '1') or (DitherEnv = 'on') or (DitherEnv = 'true') then
      UseDither := True
    else if (DitherEnv = '0') or (DitherEnv = 'off') or (DitherEnv = 'false') then
      UseDither := False;

    if UseDither and (NumRegs > 0) then
    begin
      SetLength(ErrCurR, PixelW + 2);
      SetLength(ErrCurG, PixelW + 2);
      SetLength(ErrCurB, PixelW + 2);
      SetLength(ErrNextR, PixelW + 2);
      SetLength(ErrNextG, PixelW + 2);
      SetLength(ErrNextB, PixelW + 2);
      FillChar(ErrCurR[0], (PixelW + 2) * SizeOf(Integer), 0);
      FillChar(ErrCurG[0], (PixelW + 2) * SizeOf(Integer), 0);
      FillChar(ErrCurB[0], (PixelW + 2) * SizeOf(Integer), 0);

      for Y := 0 to PixelH - 1 do
      begin
        FillChar(ErrNextR[0], (PixelW + 2) * SizeOf(Integer), 0);
        FillChar(ErrNextG[0], (PixelW + 2) * SizeOf(Integer), 0);
        FillChar(ErrNextB[0], (PixelW + 2) * SizeOf(Integer), 0);

        if SrcY + Y >= ImgH then
        begin
          for X := 0 to PixelW - 1 do
            RegMap[Y][X] := -1;
        end
        else
        for X := 0 to PixelW - 1 do
        begin
          if SrcX + X >= ImgW then
          begin
            RegMap[Y][X] := -1;
            Continue;
          end;

          Hash := Pixels[SrcY + Y][SrcX + X];
          R0 := (Hash shr 16) and $FF;
          G0 := (Hash shr 8) and $FF;
          B0 := Hash and $FF;

          ErrIdx := X + 1;
          AdjR := R0 + ErrCurR[ErrIdx];
          AdjG := G0 + ErrCurG[ErrIdx];
          AdjB := B0 + ErrCurB[ErrIdx];
          if AdjR < 0 then AdjR := 0 else if AdjR > 255 then AdjR := 255;
          if AdjG < 0 then AdjG := 0 else if AdjG > 255 then AdjG := 255;
          if AdjB < 0 then AdjB := 0 else if AdjB > 255 then AdjB := 255;

          BestReg := 0;
          BestDist := MaxInt;
          for I := 0 to NumRegs - 1 do
          begin
            DR := AdjR - PaletteR8[I];
            DG := AdjG - PaletteG8[I];
            DB := AdjB - PaletteB8[I];
            Dist := 30 * DR * DR + 59 * DG * DG + 11 * DB * DB;
            if Dist < BestDist then
            begin
              BestDist := Dist;
              BestReg := I;
            end;
          end;
          RegMap[Y][X] := BestReg;

          ErrR := AdjR - PaletteR8[BestReg];
          ErrG := AdjG - PaletteG8[BestReg];
          ErrB := AdjB - PaletteB8[BestReg];

          { Floyd-Steinberg diffusion }
          Inc(ErrCurR[ErrIdx + 1], (ErrR * 7) div 16);
          Inc(ErrCurG[ErrIdx + 1], (ErrG * 7) div 16);
          Inc(ErrCurB[ErrIdx + 1], (ErrB * 7) div 16);

          Inc(ErrNextR[ErrIdx - 1], (ErrR * 3) div 16);
          Inc(ErrNextG[ErrIdx - 1], (ErrG * 3) div 16);
          Inc(ErrNextB[ErrIdx - 1], (ErrB * 3) div 16);

          Inc(ErrNextR[ErrIdx], (ErrR * 5) div 16);
          Inc(ErrNextG[ErrIdx], (ErrG * 5) div 16);
          Inc(ErrNextB[ErrIdx], (ErrB * 5) div 16);

          Inc(ErrNextR[ErrIdx + 1], ErrR div 16);
          Inc(ErrNextG[ErrIdx + 1], ErrG div 16);
          Inc(ErrNextB[ErrIdx + 1], ErrB div 16);
        end;

        ErrTmp := ErrCurR; ErrCurR := ErrNextR; ErrNextR := ErrTmp;
        ErrTmp := ErrCurG; ErrCurG := ErrNextG; ErrNextG := ErrTmp;
        ErrTmp := ErrCurB; ErrCurB := ErrNextB; ErrNextB := ErrTmp;
      end;
    end
    else
    begin
      for Y := 0 to PixelH - 1 do
      begin
        if SrcY + Y >= ImgH then
        begin
          for X := 0 to PixelW - 1 do
            RegMap[Y][X] := -1;
          Continue;
        end;
        for X := 0 to PixelW - 1 do
        begin
          if SrcX + X >= ImgW then
            RegMap[Y][X] := -1
          else
            RegMap[Y][X] := ColorMap[QuantPixelHash(
              Pixels[SrcY + Y][SrcX + X], QuantStep)];
        end;
      end;
    end;

    { Encode Sixel DCS string }
    SB := TStringBuilder.Create(PixelW * PixelH div 2);
    try
      { DCS introducer: P1=0 normal aspect ratio, P2=1 transparent background }
      SB.Append(#27'P0;1q');

      { Raster attributes }
      SB.Append('"1;1;');
      SB.Append(IntToStr(PixelW));
      SB.Append(';');
      SB.Append(IntToStr(PixelH));

      { Color register definitions }
      for I := 0 to NumRegs - 1 do
      begin
        SB.Append('#');
        SB.Append(IntToStr(I));
        SB.Append(';2;');
        SB.Append(IntToStr(PaletteR[I]));
        SB.Append(';');
        SB.Append(IntToStr(PaletteG[I]));
        SB.Append(';');
        SB.Append(IntToStr(PaletteB[I]));
      end;

      { Encode bands of 6 pixel rows }
      for BandY := 0 to NumBands - 1 do
      begin
        { Determine which registers appear in this band }
        FillChar(BandColors, SizeOf(BandColors), 0);
        for RowInBand := 0 to 5 do
        begin
          Y := BandY * 6 + RowInBand;
          if Y >= PixelH then Break;
          for X := 0 to PixelW - 1 do
          begin
            RegIdx := RegMap[Y][X];
            if RegIdx >= 0 then
              BandColors[RegIdx] := True;
          end;
        end;

        { Encode each register present in this band }
        for RegIdx := 0 to NumRegs - 1 do
        begin
          if not BandColors[RegIdx] then Continue;

          { Select color register }
          SB.Append('#');
          SB.Append(IntToStr(RegIdx));

          { Build sixel data for this register with RLE compression }
          RunLen := 0;
          LastVal := 255;  { Invalid sentinel }

          for X := 0 to PixelW - 1 do
          begin
            SixelBit := 0;
            for RowInBand := 0 to 5 do
            begin
              Y := BandY * 6 + RowInBand;
              if (Y < PixelH) and (RegMap[Y][X] = RegIdx) then
                SixelBit := SixelBit or (1 shl RowInBand);
            end;

            SixelVal := SixelBit + 63;

            if SixelVal = LastVal then
              Inc(RunLen)
            else
            begin
              { Flush previous run }
              if RunLen > 0 then
              begin
                if RunLen >= 4 then
                begin
                  SB.Append('!');
                  SB.Append(IntToStr(RunLen));
                  SB.Append(Char(LastVal));
                end
                else
                begin
                  for J := 0 to RunLen - 1 do
                    SB.Append(Char(LastVal));
                end;
              end;
              LastVal := SixelVal;
              RunLen := 1;
            end;
          end;

          { Flush final run }
          if RunLen > 0 then
          begin
            if RunLen >= 4 then
            begin
              SB.Append('!');
              SB.Append(IntToStr(RunLen));
              SB.Append(Char(LastVal));
            end
            else
            begin
              for J := 0 to RunLen - 1 do
                SB.Append(Char(LastVal));
            end;
          end;

          { Carriage return within band }
          SB.Append('$');
        end;

        { Line feed - advance to next band (except after last) }
        if BandY < NumBands - 1 then
          SB.Append('-');
      end;

      { String Terminator }
      SB.Append(#27'\');

      Result := SB.ToString;
    finally
      SB.Free;
    end;
  finally
    ColorMap.Free;
  end;
end;

initialization
  TSixelEncoder.FCachedSupported := -1;
  TSixelEncoder.FCachedCellDetected := False;

end.
