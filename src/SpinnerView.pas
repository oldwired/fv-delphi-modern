{*********************************************************}
{                                                         }
{       Free Vision - Spinner Animator (TSpinnerView)     }
{                                                         }
{       Frame data adapted from VSoft.AnsiConsole         }
{       (https://github.com/VSoftTechnologies/            }
{        VSoft.AnsiConsole) - MIT licensed                }
{       Copyright (c) 2026 Vincent Parrett                }
{                                                         }
{       Spinner frames originate from cli-spinners        }
{       (https://github.com/sindresorhus/cli-spinners)    }
{       MIT - Copyright (c) Sindre Sorhus                 }
{                                                         }
{       Adapted for Free Vision under MIT.                }
{                                                         }
{*********************************************************}

unit SpinnerView;

interface

uses
  Winapi.Windows,
  Objects, Drivers, Views;

type
  TSpinnerKind = (
    skDots,         { Braille dots, classic }
    skDots2,        { Braille dots, alternate }
    skLine,         { ASCII -\|/ - works on legacy terminals }
    skArc,          { Rotating arc }
    skStar,         { Rotating star }
    skBouncingBar,  { ASCII bracketed bar [====] }
    skBoxBounce,    { Unicode box quadrants }
    skPipe,         { Box-drawing pipe rotation }
    skTriangle,     { Rotating triangle }
    skPoint,        { Three-dot point cycle }
    skArrow,        { Eight-direction arrow }
    skAscii         { ASCII-only spinner (legacy) }
  );

  TSpinnerView = class(TView)
  private
    FKind:        TSpinnerKind;
    FCaption:     string;
    FFrameIdx:    Integer;
    FLastTickMs:  UInt64;
    FIntervalMs:  Cardinal;
    FActive:      Boolean;
    function GetFrame(Index: Integer): string;
    function GetFrameCount: Integer;
  public
    constructor Create(var Bounds: TRect; AKind: TSpinnerKind; const ACaption: string); reintroduce; virtual;
    procedure Update; virtual;
    procedure Draw; override;
    property Kind: TSpinnerKind read FKind write FKind;
    property Caption: string read FCaption write FCaption;
    property IntervalMs: Cardinal read FIntervalMs write FIntervalMs;
    property Active: Boolean read FActive write FActive;
  end;

implementation

uses
  System.SysUtils;

{ Per-kind frame defaults: ms-per-frame baseline. }
function DefaultIntervalFor(Kind: TSpinnerKind): Cardinal;
begin
  case Kind of
    skDots, skDots2:    Result := 80;
    skLine, skAscii:    Result := 130;
    skArc:              Result := 100;
    skStar:             Result := 70;
    skBouncingBar:      Result := 80;
    skBoxBounce:        Result := 120;
    skPipe:             Result := 100;
    skTriangle:         Result := 50;
    skPoint:            Result := 125;
    skArrow:            Result := 100;
  else
    Result := 100;
  end;
end;

{ -------- Frame data (curated subset of cli-spinners) -------- }

function Frames_Dots: TArray<string>;
begin
  SetLength(Result, 10);
  Result[0] := #$280B; Result[1] := #$2819; Result[2] := #$2839; Result[3] := #$2838;
  Result[4] := #$283C; Result[5] := #$2834; Result[6] := #$2826; Result[7] := #$2827;
  Result[8] := #$2807; Result[9] := #$280F;
end;

function Frames_Dots2: TArray<string>;
begin
  SetLength(Result, 8);
  Result[0] := #$28FE; Result[1] := #$28FD; Result[2] := #$28FB; Result[3] := #$28BF;
  Result[4] := #$287F; Result[5] := #$28DF; Result[6] := #$28EF; Result[7] := #$28F7;
end;

function Frames_Line: TArray<string>;
begin
  SetLength(Result, 4);
  Result[0] := '-'; Result[1] := '\'; Result[2] := '|'; Result[3] := '/';
end;

function Frames_Arc: TArray<string>;
begin
  SetLength(Result, 6);
  Result[0] := #$25DC; Result[1] := #$25E0; Result[2] := #$25DD;
  Result[3] := #$25DE; Result[4] := #$25E1; Result[5] := #$25DF;
end;

function Frames_Star: TArray<string>;
begin
  SetLength(Result, 6);
  Result[0] := #$2736; Result[1] := #$2738; Result[2] := #$2739;
  Result[3] := #$273A; Result[4] := #$2739; Result[5] := #$2737;
end;

function Frames_BouncingBar: TArray<string>;
begin
  SetLength(Result, 16);
  Result[0]  := '[    ]'; Result[1]  := '[=   ]'; Result[2]  := '[==  ]'; Result[3]  := '[=== ]';
  Result[4]  := '[====]'; Result[5]  := '[ ===]'; Result[6]  := '[  ==]'; Result[7]  := '[   =]';
  Result[8]  := '[    ]'; Result[9]  := '[   =]'; Result[10] := '[  ==]'; Result[11] := '[ ===]';
  Result[12] := '[====]'; Result[13] := '[=== ]'; Result[14] := '[==  ]'; Result[15] := '[=   ]';
end;

function Frames_BoxBounce: TArray<string>;
begin
  SetLength(Result, 4);
  Result[0] := #$2596; Result[1] := #$2598; Result[2] := #$259D; Result[3] := #$2597;
end;

function Frames_Pipe: TArray<string>;
begin
  SetLength(Result, 8);
  Result[0] := #$2524; Result[1] := #$2518; Result[2] := #$2534; Result[3] := #$2514;
  Result[4] := #$251C; Result[5] := #$250C; Result[6] := #$252C; Result[7] := #$2510;
end;

function Frames_Triangle: TArray<string>;
begin
  SetLength(Result, 4);
  Result[0] := #$25E2; Result[1] := #$25E3; Result[2] := #$25E4; Result[3] := #$25E5;
end;

function Frames_Point: TArray<string>;
begin
  SetLength(Result, 5);
  Result[0] := #$2219 + #$2219 + #$2219;
  Result[1] := #$25CF + #$2219 + #$2219;
  Result[2] := #$2219 + #$25CF + #$2219;
  Result[3] := #$2219 + #$2219 + #$25CF;
  Result[4] := #$2219 + #$2219 + #$2219;
end;

function Frames_Arrow: TArray<string>;
begin
  SetLength(Result, 8);
  Result[0] := #$2190; Result[1] := #$2196; Result[2] := #$2191; Result[3] := #$2197;
  Result[4] := #$2192; Result[5] := #$2198; Result[6] := #$2193; Result[7] := #$2199;
end;

function Frames_Ascii: TArray<string>;
begin
  SetLength(Result, 8);
  Result[0] := '-'; Result[1] := '\'; Result[2] := '|'; Result[3] := '/';
  Result[4] := '-'; Result[5] := '\'; Result[6] := '|'; Result[7] := '/';
end;

function FramesFor(Kind: TSpinnerKind): TArray<string>;
begin
  case Kind of
    skDots:        Result := Frames_Dots;
    skDots2:       Result := Frames_Dots2;
    skLine:        Result := Frames_Line;
    skArc:         Result := Frames_Arc;
    skStar:        Result := Frames_Star;
    skBouncingBar: Result := Frames_BouncingBar;
    skBoxBounce:   Result := Frames_BoxBounce;
    skPipe:        Result := Frames_Pipe;
    skTriangle:    Result := Frames_Triangle;
    skPoint:       Result := Frames_Point;
    skArrow:       Result := Frames_Arrow;
    skAscii:       Result := Frames_Ascii;
  else
    Result := Frames_Line;
  end;
end;

{ -------- TSpinnerView -------- }

constructor TSpinnerView.Create(var Bounds: TRect; AKind: TSpinnerKind; const ACaption: string);
begin
  inherited Create(Bounds);
  FKind        := AKind;
  FCaption     := ACaption;
  FFrameIdx    := 0;
  FLastTickMs  := GetTickCount64;
  FIntervalMs  := DefaultIntervalFor(AKind);
  FActive      := True;
end;

function TSpinnerView.GetFrame(Index: Integer): string;
var
  Frames: TArray<string>;
  N: Integer;
begin
  Frames := FramesFor(FKind);
  N := Length(Frames);
  if N = 0 then
    Result := ''
  else
    Result := Frames[((Index mod N) + N) mod N];
end;

function TSpinnerView.GetFrameCount: Integer;
begin
  Result := Length(FramesFor(FKind));
end;

procedure TSpinnerView.Update;
var
  Now: UInt64;
begin
  if not FActive then Exit;
  Now := GetTickCount64;
  if Now - FLastTickMs >= FIntervalMs then
  begin
    FLastTickMs := Now;
    Inc(FFrameIdx);
    if FFrameIdx >= GetFrameCount then
      FFrameIdx := 0;
    DrawView;
  end;
end;

procedure TSpinnerView.Draw;
var
  C: Byte;
  B: TDrawBuffer;
  S: string;
begin
  C := GetColor(2);
  DrawChar(B, 0, ' ', C, Size.X);
  S := GetFrame(FFrameIdx);
  if FCaption <> '' then
    S := S + ' ' + FCaption;
  DrawStr(B, 0, S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

end.
