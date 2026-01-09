{*******************************************************}
{       Free Vision - Sparkline Chart                  }
{       Inline mini chart using Unicode block chars    }
{*******************************************************}

unit Sparkline;

interface

uses
  System.Generics.Collections,
  FVConsts, Objects, Drivers, Views;

type
  TSparkline = class(TView)
  private
    FValues: TList<Double>;
    FMinValue: Double;
    FMaxValue: Double;
    FAutoScale: Boolean;
    FMaxPoints: Integer;
  public
    constructor Create(var Bounds: TRect; AMaxPoints: Integer = 0); reintroduce; virtual;
    destructor Destroy; override;
    procedure Draw; override;
    procedure AddValue(AValue: Double);
    procedure SetValues(const AValues: array of Double);
    procedure Clear;
    procedure SetRange(AMin, AMax: Double);
    property MinValue: Double read FMinValue write FMinValue;
    property MaxValue: Double read FMaxValue write FMaxValue;
    property AutoScale: Boolean read FAutoScale write FAutoScale;
    property MaxPoints: Integer read FMaxPoints write FMaxPoints;
  end;

const
  idSparkline = 326;

  { Unicode block elements for 8-level sparkline }
  SparkChars: array[0..7] of Char = (
    #$2581,  { ▁ lower one eighth }
    #$2582,  { ▂ lower one quarter }
    #$2583,  { ▃ lower three eighths }
    #$2584,  { ▄ lower half }
    #$2585,  { ▅ lower five eighths }
    #$2586,  { ▆ lower three quarters }
    #$2587,  { ▇ lower seven eighths }
    #$2588   { █ full block }
  );

implementation

uses
  System.SysUtils, System.Math;

{ TSparkline }

constructor TSparkline.Create(var Bounds: TRect; AMaxPoints: Integer);
begin
  inherited Create(Bounds);
  FValues := TList<Double>.Create;
  FMinValue := 0;
  FMaxValue := 100;
  FAutoScale := True;
  if AMaxPoints = 0 then
    FMaxPoints := Bounds.B.X - Bounds.A.X
  else
    FMaxPoints := AMaxPoints;
end;

destructor TSparkline.Destroy;
begin
  FreeAndNil(FValues);
  inherited Destroy;
end;

procedure TSparkline.AddValue(AValue: Double);
begin
  FValues.Add(AValue);

  { Limit to max points }
  while FValues.Count > FMaxPoints do
    FValues.Delete(0);

  { Update auto-scale if enabled }
  if FAutoScale and (FValues.Count > 0) then begin
    FMinValue := FValues[0];
    FMaxValue := FValues[0];
    for var V in FValues do begin
      if V < FMinValue then FMinValue := V;
      if V > FMaxValue then FMaxValue := V;
    end;
    { Ensure some range }
    if FMaxValue = FMinValue then begin
      FMinValue := FMinValue - 1;
      FMaxValue := FMaxValue + 1;
    end;
  end;

  DrawView;
end;

procedure TSparkline.SetValues(const AValues: array of Double);
var
  I: Integer;
begin
  FValues.Clear;
  for I := 0 to High(AValues) do
    FValues.Add(AValues[I]);

  { Limit to max points }
  while FValues.Count > FMaxPoints do
    FValues.Delete(0);

  { Update auto-scale }
  if FAutoScale and (FValues.Count > 0) then begin
    FMinValue := FValues[0];
    FMaxValue := FValues[0];
    for var V in FValues do begin
      if V < FMinValue then FMinValue := V;
      if V > FMaxValue then FMaxValue := V;
    end;
    if FMaxValue = FMinValue then begin
      FMinValue := FMinValue - 1;
      FMaxValue := FMaxValue + 1;
    end;
  end;

  DrawView;
end;

procedure TSparkline.Clear;
begin
  FValues.Clear;
  DrawView;
end;

procedure TSparkline.SetRange(AMin, AMax: Double);
begin
  FAutoScale := False;
  FMinValue := AMin;
  FMaxValue := AMax;
  DrawView;
end;

procedure TSparkline.Draw;
var
  B: TDrawBuffer;
  Color: Byte;
  I, Level, StartX: Integer;
  V, Range, Normalized: Double;
begin
  Color := GetColor(2);
  DrawChar(B, 0, ' ', Color, Size.X);

  if FValues.Count > 0 then begin
    Range := FMaxValue - FMinValue;
    if Range = 0 then Range := 1;

    { Right-align the sparkline }
    StartX := Size.X - FValues.Count;
    if StartX < 0 then StartX := 0;

    for I := 0 to FValues.Count - 1 do begin
      if StartX + I >= Size.X then Break;

      V := FValues[I];
      Normalized := (V - FMinValue) / Range;
      Level := Trunc(Normalized * 7);
      if Level < 0 then Level := 0;
      if Level > 7 then Level := 7;

      DrawChar(B, StartX + I, SparkChars[Level], Color, 1);
    end;
  end;

  WriteLine(0, 0, Size.X, 1, B);
end;

end.
