{*********************************************************}
{                                                         }
{       Free Vision - Progress Bar Component              }
{                                                         }
{       Single-line visual progress indicator             }
{                                                         }
{*********************************************************}

unit ProgressBar;

{$R-}

interface

uses
  FVCommon, Drivers, Views, FVConsts, FVBoxChars;

const
  CProgressBar = #16#19#17;  { Empty, Filled, Text - maps through dialog palette }

type
  TProgressBar = class(TView)
  private
    FMin: LongInt;
    FMax: LongInt;
    FPosition: LongInt;
    FShowPercent: Boolean;
    FFilledChar: Char;
    FEmptyChar: Char;
  public
    constructor Create(var Bounds: TRect; AMin: LongInt = 0; AMax: LongInt = 100); reintroduce; virtual;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure SetProgress(AValue: LongInt);
    procedure SetRange(AMin, AMax: LongInt);
    procedure Reset;
    property Min: LongInt read FMin;
    property Max: LongInt read FMax;
    property Position: LongInt read FPosition;
    property ShowPercent: Boolean read FShowPercent write FShowPercent;
    property FilledChar: Char read FFilledChar write FFilledChar;
    property EmptyChar: Char read FEmptyChar write FEmptyChar;
  end;

implementation

uses
  System.SysUtils;

constructor TProgressBar.Create(var Bounds: TRect; AMin: LongInt; AMax: LongInt);
begin
  inherited Create(Bounds);
  FMin := AMin;
  FMax := AMax;
  FPosition := AMin;
  FShowPercent := True;
  FFilledChar := BlockFull;
  FEmptyChar := BlockLight;
end;

function TProgressBar.GetPalette: PPalette;
const
  P: string[Length(CProgressBar)] = CProgressBar;
begin
  GetPalette := PPalette(@P);
end;

procedure TProgressBar.Draw;
var
  B: TDrawBuffer;
  EmptyColor, FilledColor, TextColor: Byte;
  Percent: Integer;
  FilledWidth: Integer;
  PercentStr: string;
  TextPos, TextLen: Integer;
  I: Integer;
  TotalRange: LongInt;
begin
  EmptyColor := GetColor(1);
  FilledColor := GetColor(2);
  TextColor := GetColor(3);

  TotalRange := FMax - FMin;
  if TotalRange <= 0 then
    Percent := 0
  else begin
    Percent := ((FPosition - FMin) * 100) div TotalRange;
    if Percent < 0 then Percent := 0;
    if Percent > 100 then Percent := 100;
  end;

  FilledWidth := 0;
  if (TotalRange > 0) and (Size.X > 0) then
    FilledWidth := ((FPosition - FMin) * Size.X) div TotalRange;
  if FilledWidth < 0 then FilledWidth := 0;
  if FilledWidth > Size.X then FilledWidth := Size.X;

  { Draw filled portion }
  DrawChar(B, 0, FFilledChar, FilledColor, FilledWidth);
  { Draw empty portion }
  DrawChar(B, FilledWidth, FEmptyChar, EmptyColor, Size.X - FilledWidth);

  { Overlay percentage text centered }
  if FShowPercent then begin
    PercentStr := IntToStr(Percent) + '%';
    TextLen := Length(PercentStr);
    TextPos := (Size.X - TextLen) div 2;
    if TextPos < 0 then TextPos := 0;
    for I := 1 to TextLen do begin
      if (TextPos + I - 1) < Size.X then begin
        B[TextPos + I - 1].Ch := PercentStr[I];
        B[TextPos + I - 1].Attr := TextColor;
      end;
    end;
  end;

  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TProgressBar.SetProgress(AValue: LongInt);
begin
  if AValue < FMin then AValue := FMin;
  if AValue > FMax then AValue := FMax;
  if AValue <> FPosition then begin
    FPosition := AValue;
    DrawView;
  end;
end;

procedure TProgressBar.SetRange(AMin, AMax: LongInt);
begin
  FMin := AMin;
  FMax := AMax;
  if FPosition < FMin then FPosition := FMin;
  if FPosition > FMax then FPosition := FMax;
  DrawView;
end;

procedure TProgressBar.Reset;
begin
  FPosition := FMin;
  DrawView;
end;

end.
