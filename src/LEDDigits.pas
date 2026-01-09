{*******************************************************}
{       Free Vision - LED Digits Display               }
{       7-segment style digit display                  }
{*******************************************************}

unit LEDDigits;

interface

uses
  FVConsts, Objects, Drivers, Views;

type
  TLEDDigits = class(TView)
  private
    FValue: Int64;
    FDigitCount: Integer;
    FLeadingZeros: Boolean;
  public
    constructor Create(var Bounds: TRect; ADigitCount: Integer); reintroduce; virtual;
    procedure Draw; override;
    procedure SetValue(AValue: Int64);
    property Value: Int64 read FValue write SetValue;
    property DigitCount: Integer read FDigitCount write FDigitCount;
    property LeadingZeros: Boolean read FLeadingZeros write FLeadingZeros;
  end;

const
  idLEDDigits = 323;

implementation

uses
  System.SysUtils, System.Math;

const
  { 7-segment bit patterns for digits 0-9 }
  { Bits: 0=top, 1=top-right, 2=bot-right, 3=bottom, 4=bot-left, 5=top-left, 6=middle }
  SegmentPatterns: array[0..9] of Byte = (
    $3F,  { 0: all except middle }
    $06,  { 1: right side only }
    $5B,  { 2: top, top-right, middle, bot-left, bottom }
    $4F,  { 3: top, right side, middle, bottom }
    $66,  { 4: top-left, top-right, middle, bot-right }
    $6D,  { 5: top, top-left, middle, bot-right, bottom }
    $7D,  { 6: top, top-left, middle, bot-left, bot-right, bottom }
    $07,  { 7: top, right side only }
    $7F,  { 8: all segments }
    $6F   { 9: all except bot-left }
  );

{ TLEDDigits }

constructor TLEDDigits.Create(var Bounds: TRect; ADigitCount: Integer);
begin
  inherited Create(Bounds);
  FDigitCount := ADigitCount;
  FValue := 0;
  FLeadingZeros := False;
end;

procedure TLEDDigits.SetValue(AValue: Int64);
begin
  if FValue <> AValue then begin
    FValue := AValue;
    DrawView;
  end;
end;

procedure TLEDDigits.Draw;
var
  B: TDrawBuffer;
  Color: Byte;
  D, X, Row: Integer;
  Digits: array of Integer;
  V: Int64;
  Seg: Byte;
  C1, C2, C3: Char;
  IsBlank: Boolean;
begin
  Color := GetColor(2);

  { Extract digits }
  SetLength(Digits, FDigitCount);
  V := Abs(FValue);
  for D := FDigitCount - 1 downto 0 do begin
    Digits[D] := V mod 10;
    V := V div 10;
  end;

  { Draw 3 rows }
  for Row := 0 to Min(2, Size.Y - 1) do begin
    DrawChar(B, 0, ' ', Color, Size.X);
    X := 0;

    for D := 0 to FDigitCount - 1 do begin
      { Check if this digit should be blank (leading zero suppression) }
      IsBlank := False;
      if not FLeadingZeros and (D < FDigitCount - 1) then begin
        V := Abs(FValue);
        if V < Round(Power(10, FDigitCount - D - 1)) then
          IsBlank := True;
      end;

      if IsBlank then begin
        C1 := ' '; C2 := ' '; C3 := ' ';
      end
      else begin
        Seg := SegmentPatterns[Digits[D]];

        case Row of
          0: begin { Top row: top segment }
            C1 := ' ';
            if (Seg and $01) <> 0 then C2 := '_' else C2 := ' ';
            C3 := ' ';
          end;
          1: begin { Middle row: top-left, middle, top-right }
            if (Seg and $20) <> 0 then C1 := '|' else C1 := ' ';
            if (Seg and $40) <> 0 then C2 := '_' else C2 := ' ';
            if (Seg and $02) <> 0 then C3 := '|' else C3 := ' ';
          end;
          2: begin { Bottom row: bot-left, bottom, bot-right }
            if (Seg and $10) <> 0 then C1 := '|' else C1 := ' ';
            if (Seg and $08) <> 0 then C2 := '_' else C2 := ' ';
            if (Seg and $04) <> 0 then C3 := '|' else C3 := ' ';
          end;
        else
          C1 := ' '; C2 := ' '; C3 := ' ';
        end;
      end;

      DrawChar(B, X, C1, Color, 1);
      DrawChar(B, X + 1, C2, Color, 1);
      DrawChar(B, X + 2, C3, Color, 1);
      Inc(X, 4);  { 3 chars + 1 space between digits }
    end;

    WriteLine(0, Row, Size.X, 1, B);
  end;
end;

end.
