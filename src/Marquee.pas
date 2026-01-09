{*******************************************************}
{       Free Vision - Marquee / Scrolling Ticker       }
{       Scrolling text display                         }
{*******************************************************}

unit Marquee;

interface

uses
  Winapi.Windows,
  FVConsts, Objects, Drivers, Views;

type
  TScrollDirection = (sdLeft, sdRight);

  TMarquee = class(TView)
  private
    FText: string;
    FPosition: Integer;
    FDirection: TScrollDirection;
    FScrollSpeed: Word;  { milliseconds between scrolls }
    FLastScroll: UInt64;
    FPaused: Boolean;
    FGap: Integer;  { spaces between repeating text }
  public
    constructor Create(var Bounds: TRect; const AText: string); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    procedure SetText(const AText: string);
    procedure Pause;
    procedure Resume;
    procedure Reset;
    property Text: string read FText write SetText;
    property Direction: TScrollDirection read FDirection write FDirection;
    property ScrollSpeed: Word read FScrollSpeed write FScrollSpeed;
    property Paused: Boolean read FPaused;
    property Gap: Integer read FGap write FGap;
  end;

const
  idMarquee = 325;

implementation

uses
  System.SysUtils, System.Math;

{ TMarquee }

constructor TMarquee.Create(var Bounds: TRect; const AText: string);
begin
  inherited Create(Bounds);
  FText := AText;
  FPosition := 0;
  FDirection := sdLeft;
  FScrollSpeed := 150;  { 150ms default }
  FLastScroll := 0;
  FPaused := False;
  FGap := 5;
end;

procedure TMarquee.SetText(const AText: string);
begin
  FText := AText;
  FPosition := 0;
  DrawView;
end;

procedure TMarquee.Pause;
begin
  FPaused := True;
end;

procedure TMarquee.Resume;
begin
  FPaused := False;
  FLastScroll := GetTickCount64;
end;

procedure TMarquee.Reset;
begin
  FPosition := 0;
  DrawView;
end;

procedure TMarquee.Update;
var
  CurrentTick: UInt64;
  TextLen: Integer;
begin
  if FPaused or (FText = '') then Exit;

  CurrentTick := GetTickCount64;
  if (CurrentTick - FLastScroll) >= FScrollSpeed then begin
    FLastScroll := CurrentTick;

    TextLen := Length(FText) + FGap;

    case FDirection of
      sdLeft: begin
        Inc(FPosition);
        if FPosition >= TextLen then
          FPosition := 0;
      end;
      sdRight: begin
        Dec(FPosition);
        if FPosition < 0 then
          FPosition := TextLen - 1;
      end;
    end;

    DrawView;
  end;
end;

procedure TMarquee.Draw;
var
  B: TDrawBuffer;
  Color: Byte;
  DisplayText: string;
  I, Pos, TextLen: Integer;
  FullText: string;
begin
  Color := GetColor(2);
  DrawChar(B, 0, ' ', Color, Size.X);

  if FText <> '' then begin
    { Create text with gap for seamless scrolling }
    FullText := FText + StringOfChar(' ', FGap);
    TextLen := Length(FullText);

    { Build display string by wrapping around }
    DisplayText := '';
    for I := 0 to Size.X - 1 do begin
      Pos := (FPosition + I) mod TextLen;
      if Pos < Length(FullText) then
        DisplayText := DisplayText + FullText[Pos + 1]
      else
        DisplayText := DisplayText + ' ';
    end;

    DrawStr(B, 0, DisplayText, Color);
  end;

  WriteLine(0, 0, Size.X, 1, B);
end;

end.
