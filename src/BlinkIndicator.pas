{*******************************************************}
{       Free Vision - Blink Indicator                  }
{       Blinking activity indicator dot                }
{*******************************************************}

unit BlinkIndicator;

interface

uses
  Winapi.Windows,
  FVConsts, Objects, Drivers, Views, FVBoxChars;

type
  TBlinkState = (bsOff, bsOn, bsBlinking);

  TBlinkIndicator = class(TView)
  private
    FState: TBlinkState;
    FBlinkOn: Boolean;
    FLastToggle: UInt64;
    FBlinkInterval: Word;  { milliseconds }
    FOnChar: Char;
    FOffChar: Char;
    FLabel: string;
  public
    constructor Create(var Bounds: TRect; const ALabel: string = ''); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    procedure TurnOn;
    procedure TurnOff;
    procedure Blink;
    procedure Pulse;  { Brief on then off }
    property State: TBlinkState read FState write FState;
    property BlinkInterval: Word read FBlinkInterval write FBlinkInterval;
    property OnChar: Char read FOnChar write FOnChar;
    property OffChar: Char read FOffChar write FOffChar;
    property IndicatorLabel: string read FLabel write FLabel;
  end;

const
  idBlinkIndicator = 324;

implementation

{ TBlinkIndicator }

constructor TBlinkIndicator.Create(var Bounds: TRect; const ALabel: string);
begin
  inherited Create(Bounds);
  FState := bsOff;
  FBlinkOn := False;
  FLastToggle := 0;
  FBlinkInterval := 500;  { 500ms default }
  FOnChar := Circle;      { ● solid circle }
  FOffChar := CircleOpen; { ○ open circle }
  FLabel := ALabel;
end;

procedure TBlinkIndicator.Update;
var
  CurrentTick: UInt64;
begin
  if FState = bsBlinking then begin
    CurrentTick := GetTickCount64;
    if (CurrentTick - FLastToggle) >= FBlinkInterval then begin
      FBlinkOn := not FBlinkOn;
      FLastToggle := CurrentTick;
      DrawView;
    end;
  end;
end;

procedure TBlinkIndicator.TurnOn;
begin
  FState := bsOn;
  FBlinkOn := True;
  DrawView;
end;

procedure TBlinkIndicator.TurnOff;
begin
  FState := bsOff;
  FBlinkOn := False;
  DrawView;
end;

procedure TBlinkIndicator.Blink;
begin
  FState := bsBlinking;
  FBlinkOn := True;
  FLastToggle := GetTickCount64;
  DrawView;
end;

procedure TBlinkIndicator.Pulse;
begin
  { Show on briefly - caller should call TurnOff after a delay }
  FState := bsOn;
  FBlinkOn := True;
  DrawView;
end;

procedure TBlinkIndicator.Draw;
var
  B: TDrawBuffer;
  Color, OnColor: Byte;
  DispChar: Char;
  X: Integer;
begin
  Color := GetColor(1);
  OnColor := GetColor(2);

  DrawChar(B, 0, ' ', Color, Size.X);

  { Determine which character to show }
  case FState of
    bsOff: DispChar := FOffChar;
    bsOn: DispChar := FOnChar;
    bsBlinking: begin
      if FBlinkOn then
        DispChar := FOnChar
      else
        DispChar := FOffChar;
    end;
  else
    DispChar := FOffChar;
  end;

  { Draw indicator }
  if (FState = bsOn) or ((FState = bsBlinking) and FBlinkOn) then
    DrawChar(B, 0, DispChar, OnColor, 1)
  else
    DrawChar(B, 0, DispChar, Color, 1);

  { Draw label if present }
  if FLabel <> '' then begin
    X := 2;
    DrawStr(B, X, FLabel, Color);
  end;

  WriteLine(0, 0, Size.X, 1, B);
end;

end.
