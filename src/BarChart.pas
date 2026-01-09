{*******************************************************}
{       Free Vision - Bar Chart                        }
{       Simple horizontal/vertical bar chart           }
{*******************************************************}

unit BarChart;

interface

uses
  System.Generics.Collections,
  FVConsts, Objects, Drivers, Views, FVBoxChars;

type
  TBarOrientation = (boHorizontal, boVertical);

  TBarData = record
    Value: Double;
    Label_: string;
  end;

  TBarChart = class(TView)
  private
    FBars: TList<TBarData>;
    FOrientation: TBarOrientation;
    FMaxValue: Double;
    FAutoScale: Boolean;
    FShowValues: Boolean;
    FShowLabels: Boolean;
    FBarChar: Char;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    destructor Destroy; override;
    procedure Draw; override;
    procedure AddBar(const ALabel: string; AValue: Double);
    procedure SetBar(Index: Integer; AValue: Double);
    procedure Clear;
    property Orientation: TBarOrientation read FOrientation write FOrientation;
    property MaxValue: Double read FMaxValue write FMaxValue;
    property AutoScale: Boolean read FAutoScale write FAutoScale;
    property ShowValues: Boolean read FShowValues write FShowValues;
    property ShowLabels: Boolean read FShowLabels write FShowLabels;
    property BarChar: Char read FBarChar write FBarChar;
  end;

const
  idBarChart = 327;

implementation

uses
  System.SysUtils, System.Math;

{ TBarChart }

constructor TBarChart.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FBars := TList<TBarData>.Create;
  FOrientation := boHorizontal;
  FMaxValue := 100;
  FAutoScale := True;
  FShowValues := True;
  FShowLabels := True;
  FBarChar := BlockFull;  { █ }
end;

destructor TBarChart.Destroy;
begin
  FreeAndNil(FBars);
  inherited Destroy;
end;

procedure TBarChart.AddBar(const ALabel: string; AValue: Double);
var
  Bar: TBarData;
begin
  Bar.Label_ := ALabel;
  Bar.Value := AValue;
  FBars.Add(Bar);

  if FAutoScale and (AValue > FMaxValue) then
    FMaxValue := AValue;

  DrawView;
end;

procedure TBarChart.SetBar(Index: Integer; AValue: Double);
var
  Bar: TBarData;
begin
  if (Index >= 0) and (Index < FBars.Count) then begin
    Bar := FBars[Index];
    Bar.Value := AValue;
    FBars[Index] := Bar;

    if FAutoScale then begin
      FMaxValue := 0;
      for var B in FBars do
        if B.Value > FMaxValue then FMaxValue := B.Value;
      if FMaxValue = 0 then FMaxValue := 100;
    end;

    DrawView;
  end;
end;

procedure TBarChart.Clear;
begin
  FBars.Clear;
  FMaxValue := 100;
  DrawView;
end;

procedure TBarChart.Draw;
var
  B: TDrawBuffer;
  Color, BarColor: Byte;
  I, Y, BarLen, LabelWidth, MaxBarWidth: Integer;
  Bar: TBarData;
  S: string;
  Ratio: Double;
begin
  Color := GetColor(1);
  BarColor := GetColor(2);

  if FOrientation = boHorizontal then begin
    { Horizontal bars - each bar is one row }
    LabelWidth := 0;
    if FShowLabels then begin
      for var BD in FBars do
        if Length(BD.Label_) > LabelWidth then
          LabelWidth := Length(BD.Label_);
      Inc(LabelWidth, 1);  { Space after label }
    end;

    MaxBarWidth := Size.X - LabelWidth;
    if FShowValues then
      Dec(MaxBarWidth, 6);  { Space for value display }
    if MaxBarWidth < 1 then MaxBarWidth := 1;

    for I := 0 to Min(FBars.Count - 1, Size.Y - 1) do begin
      DrawChar(B, 0, ' ', Color, Size.X);
      Bar := FBars[I];

      { Draw label }
      if FShowLabels then begin
        S := Bar.Label_;
        while Length(S) < LabelWidth do S := S + ' ';
        DrawStr(B, 0, S, Color);
      end;

      { Calculate bar length }
      if FMaxValue > 0 then
        Ratio := Bar.Value / FMaxValue
      else
        Ratio := 0;
      BarLen := Trunc(Ratio * MaxBarWidth);
      if BarLen < 0 then BarLen := 0;
      if BarLen > MaxBarWidth then BarLen := MaxBarWidth;

      { Draw bar }
      if BarLen > 0 then
        DrawChar(B, LabelWidth, FBarChar, BarColor, BarLen);

      { Draw value }
      if FShowValues then begin
        S := Format('%5.0f', [Bar.Value]);
        DrawStr(B, Size.X - 5, S, Color);
      end;

      WriteLine(0, I, Size.X, 1, B);
    end;

    { Clear remaining rows }
    for I := FBars.Count to Size.Y - 1 do begin
      DrawChar(B, 0, ' ', Color, Size.X);
      WriteLine(0, I, Size.X, 1, B);
    end;
  end
  else begin
    { Vertical bars - each bar is one column }
    { For simplicity, use block characters at different heights }
    for Y := 0 to Size.Y - 1 do begin
      DrawChar(B, 0, ' ', Color, Size.X);

      for I := 0 to Min(FBars.Count - 1, Size.X - 1) do begin
        Bar := FBars[I];

        if FMaxValue > 0 then
          Ratio := Bar.Value / FMaxValue
        else
          Ratio := 0;
        BarLen := Trunc(Ratio * Size.Y);

        { Check if this row should have a bar segment }
        if (Size.Y - 1 - Y) < BarLen then
          DrawChar(B, I, FBarChar, BarColor, 1);
      end;

      WriteLine(0, Y, Size.X, 1, B);
    end;
  end;
end;

end.
