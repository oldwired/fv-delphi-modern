{*******************************************************}
{       Free Vision - Gadgets Unit                      }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  THeapView - displays current heap memory usage
  TClockView - displays current time

  Based on original FPC Free Vision GADGETS.PAS by Leon de Boer.
}

unit Gadgets;

interface

uses
  FVConsts, Time, Objects, Drivers, Views, App;

{***************************************************************************}
{                        PUBLIC OBJECT DEFINITIONS                          }
{***************************************************************************}

{---------------------------------------------------------------------------}
{                  THeapView OBJECT - ANCESTOR VIEW OBJECT                  }
{---------------------------------------------------------------------------}
TYPE
   TTimeString = String[10];
   THeapViewMode=(HVNormal,HVComma,HVKb,HVMb);

   THeapView = class(TView)
   private
      FMode: THeapViewMode;
      FOldMem: LongInt;                              { Last memory count }
   public
      constructor Create(var Bounds: TRect); reintroduce; virtual;
      constructor CreateComma(var Bounds: TRect); virtual;
      constructor CreateKb(var Bounds: TRect); virtual;
      constructor CreateMb(var Bounds: TRect); virtual;
      procedure Update;
      procedure Draw; override;
      function Comma(N: LongInt): String;
      property Mode: THeapViewMode read FMode write FMode;
      property OldMem: LongInt read FOldMem write FOldMem;
   end;

{---------------------------------------------------------------------------}
{                 TClockView OBJECT - ANCESTOR VIEW OBJECT                  }
{---------------------------------------------------------------------------}
TYPE
   TClockView = class(TView)
   private
      Fam: AnsiChar;
      FRefresh: Byte;                                { Refresh rate }
      FLastTime: Longint;                            { Last time displayed }
      FTimeStr: TTimeString;                          { Time string }
   public
      constructor Create(var Bounds: TRect); reintroduce; virtual;
      function FormatTimeStr(H, M, S: Word): String; virtual;
      procedure Update; virtual;
      procedure Draw; override;
      property am: AnsiChar read Fam write Fam;
      property Refresh: Byte read FRefresh write FRefresh;
      property LastTime: LongInt read FLastTime write FLastTime;
      property TimeStr: TTimeString read FTimeStr write FTimeStr;
   end;

{<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>}
                             IMPLEMENTATION
{<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>}

{***************************************************************************}
{                              OBJECT METHODS                               }
{***************************************************************************}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
{                          THeapView OBJECT METHODS                         }
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

constructor THeapView.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FMode := HVNormal;
  FOldMem := 0;
end;

constructor THeapView.CreateComma(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FMode := HVComma;
  FOldMem := 0;
end;

constructor THeapView.CreateKb(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FMode := HVKb;
  FOldMem := 0;
end;

constructor THeapView.CreateMb(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FMode := HVMb;
  FOldMem := 0;
end;

procedure THeapView.Update;
var
  NewMem: LongInt;
begin
  { In Delphi, use GetHeapStatus or memory manager info }
  {$IFDEF MSWINDOWS}
  NewMem := GetHeapStatus.TotalAllocated;
  {$ELSE}
  NewMem := 0;
  {$ENDIF}
  if FOldMem <> NewMem then
  begin
    FOldMem := NewMem;
    DrawView;
  end;
end;

procedure THeapView.Draw;
var
  C: Byte;
  S: string;
  B: TDrawBuffer;
begin
  case FMode of
    HVNormal:
      Str(FOldMem:Size.X, S);
    HVComma:
      S := Comma(FOldMem);
    HVKb:
      begin
        Str(FOldMem shr 10:Size.X-1, S);
        S := S + 'K';
      end;
    HVMb:
      begin
        Str(FOldMem shr 20:Size.X-1, S);
        S := S + 'M';
      end;
  end;
  C := GetColor(2);
  DrawChar(B, 0, ' ', C, Size.X);
  DrawStr(B, 0, S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

function THeapView.Comma(N: LongInt): string;
var
  Num, Loc: Byte;
  S, T: string;
begin
  Str(N, S);
  Str(N:Size.X, T);

  Num := Length(S) div 3;
  if (Length(S) mod 3) = 0 then Dec(Num);

  Delete(T, 1, Num);
  Loc := Length(T) - 2;

  while Num > 0 do
  begin
    Insert(',', T, Loc);
    Dec(Num);
    Dec(Loc, 3);
  end;

  Result := T;
end;

{ TClockView }

constructor TClockView.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FillChar(FLastTime, SizeOf(FLastTime), $FF);
  FTimeStr := '';
  FRefresh := 1;
end;

function TClockView.FormatTimeStr(H, M, S: Word): string;
var
  Hs, Ms, Ss: string;
begin
  Str(H, Hs);
  while Length(Hs) < 2 do Hs := '0' + Hs;
  Str(M, Ms);
  while Length(Ms) < 2 do Ms := '0' + Ms;
  Str(S, Ss);
  while Length(Ss) < 2 do Ss := '0' + Ss;
  Result := Hs + ':' + Ms + ':' + Ss;
end;

procedure TClockView.Update;
var
  Hour, Min, Sec, Sec100: Word;
begin
  GetTime(Hour, Min, Sec, Sec100);
  if Abs(Sec - FLastTime) >= FRefresh then
  begin
    FLastTime := Sec;
    FTimeStr := FormatTimeStr(Hour, Min, Sec);
    DrawView;
  end;
end;

procedure TClockView.Draw;
var
  C: Byte;
  B: TDrawBuffer;
begin
  C := GetColor(2);
  DrawChar(B, 0, ' ', C, Size.X);
  DrawStr(B, 0, FTimeStr, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

end.
