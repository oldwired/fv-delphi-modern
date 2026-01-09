{*******************************************************}
{       Free Vision - VU Meter                         }
{       Audio-style level meter with peak hold         }
{*******************************************************}

unit VUMeter;

interface

uses
  Winapi.Windows,
  FVConsts, Objects, Drivers, Views, FVBoxChars;

type
  TVUMeter = class(TView)
  private
    FValue: Double;       { Current value 0-100 }
    FPeakValue: Double;   { Peak hold value }
    FPeakHoldTime: UInt64;
    FPeakDecay: Double;   { Decay rate per update }
    FLastUpdate: UInt64;
    FShowPeak: Boolean;
    FVertical: Boolean;
    FSegments: Integer;
    FYellowThreshold: Double;  { % where yellow starts }
    FRedThreshold: Double;     { % where red starts }
  public
    constructor Create(var Bounds: TRect; AVertical: Boolean = False); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    procedure SetLevel(AValue: Double);
    procedure Reset;
    property Value: Double read FValue write SetLevel;
    property PeakValue: Double read FPeakValue;
    property ShowPeak: Boolean read FShowPeak write FShowPeak;
    property Vertical: Boolean read FVertical write FVertical;
    property YellowThreshold: Double read FYellowThreshold write FYellowThreshold;
    property RedThreshold: Double read FRedThreshold write FRedThreshold;
    property PeakDecay: Double read FPeakDecay write FPeakDecay;
  end;

const
  idVUMeter = 328;

implementation

uses
  System.SysUtils, System.Math;

{ TVUMeter }

constructor TVUMeter.Create(var Bounds: TRect; AVertical: Boolean);
begin
  inherited Create(Bounds);
  FValue := 0;
  FPeakValue := 0;
  FPeakHoldTime := 0;
  FPeakDecay := 2.0;  { Decay 2% per update }
  FLastUpdate := 0;
  FShowPeak := True;
  FVertical := AVertical;
  FYellowThreshold := 60;
  FRedThreshold := 85;
  if FVertical then
    FSegments := Bounds.B.Y - Bounds.A.Y
  else
    FSegments := Bounds.B.X - Bounds.A.X;
end;

procedure TVUMeter.SetLevel(AValue: Double);
begin
  if AValue < 0 then AValue := 0;
  if AValue > 100 then AValue := 100;

  FValue := AValue;

  { Update peak }
  if AValue >= FPeakValue then begin
    FPeakValue := AValue;
    FPeakHoldTime := GetTickCount64;
  end;

  DrawView;
end;

procedure TVUMeter.Reset;
begin
  FValue := 0;
  FPeakValue := 0;
  DrawView;
end;

procedure TVUMeter.Update;
var
  CurrentTick: UInt64;
begin
  CurrentTick := GetTickCount64;

  { Decay peak after hold time (500ms) }
  if FShowPeak and (FPeakValue > FValue) then begin
    if (CurrentTick - FPeakHoldTime) > 500 then begin
      FPeakValue := FPeakValue - FPeakDecay;
      if FPeakValue < FValue then
        FPeakValue := FValue;
      DrawView;
    end;
  end;

  FLastUpdate := CurrentTick;
end;

procedure TVUMeter.Draw;
var
  B: TDrawBuffer;
  Color, GreenColor, YellowColor, RedColor, PeakColor: Byte;
  I, FilledSegs, PeakSeg, Y: Integer;
  SegColor: Byte;
  Threshold1, Threshold2: Integer;
begin
  Color := GetColor(1);       { Background }
  GreenColor := GetColor(2);  { Green level }
  YellowColor := GetColor(3); { Yellow level }
  RedColor := GetColor(4);    { Red level }
  PeakColor := GetColor(5);   { Peak indicator }

  { Calculate segment thresholds }
  Threshold1 := Trunc((FYellowThreshold / 100) * FSegments);
  Threshold2 := Trunc((FRedThreshold / 100) * FSegments);

  { Calculate filled segments }
  FilledSegs := Trunc((FValue / 100) * FSegments);
  PeakSeg := Trunc((FPeakValue / 100) * FSegments);
  if PeakSeg >= FSegments then PeakSeg := FSegments - 1;

  if FVertical then begin
    { Vertical meter - draw from bottom to top }
    for Y := 0 to Size.Y - 1 do begin
      DrawChar(B, 0, ' ', Color, Size.X);
      I := Size.Y - 1 - Y;  { Segment index from bottom }

      if I < FilledSegs then begin
        { Filled segment - choose color based on level }
        if I >= Threshold2 then
          SegColor := RedColor
        else if I >= Threshold1 then
          SegColor := YellowColor
        else
          SegColor := GreenColor;
        DrawChar(B, 0, BlockFull, SegColor, Size.X);
      end
      else if FShowPeak and (I = PeakSeg) and (PeakSeg > FilledSegs) then begin
        { Peak indicator }
        DrawChar(B, 0, BlockFull, PeakColor, Size.X);
      end
      else begin
        { Empty segment }
        DrawChar(B, 0, BlockLight, Color, Size.X);
      end;

      WriteLine(0, Y, Size.X, 1, B);
    end;
  end
  else begin
    { Horizontal meter }
    DrawChar(B, 0, ' ', Color, Size.X);

    for I := 0 to FSegments - 1 do begin
      if I >= Size.X then Break;

      if I < FilledSegs then begin
        { Filled segment }
        if I >= Threshold2 then
          SegColor := RedColor
        else if I >= Threshold1 then
          SegColor := YellowColor
        else
          SegColor := GreenColor;
        DrawChar(B, I, BlockFull, SegColor, 1);
      end
      else if FShowPeak and (I = PeakSeg) and (PeakSeg > FilledSegs) then begin
        { Peak indicator }
        DrawChar(B, I, BlockFull, PeakColor, 1);
      end
      else begin
        { Empty segment }
        DrawChar(B, I, BlockLight, Color, 1);
      end;
    end;

    WriteLine(0, 0, Size.X, 1, B);
  end;
end;

end.
