{*******************************************************}
{       Free Vision - Long Integer Input Unit           }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  TInputLong is a derivative of TInputLine designed to accept LongInt
  numeric input. Since both the upper and lower limit of acceptable numeric
  input can be set, TInputLong may be used for SmallInt, Word, or Byte input
  as well. Option flag bits allow optional hex input and display. A blank
  field may optionally be rejected or interpreted as zero.
}

unit InpLong;

interface

uses
  System.SysUtils, Objects, Drivers, Views, Dialogs, MsgBox, FVCommon, FVConsts;

const
  { Flags for TInputLong constructor }
  ilHex = 1;          { Will enable hex input with leading '$' }
  ilBlankEqZero = 2;  { No input (blank) will be interpreted as '0' }
  ilDisplayHex = 4;   { Number displayed as hex when possible }

type
  TInputLong = class(TInputLine)
  private
    FILOptions: Word;
    FLLim, FULim: LongInt;
  public
    constructor Create(var R: TRect; AMaxLen: Integer;
      LowerLim, UpperLim: LongInt; Flgs: Word); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    procedure Store(var S: TFVStream);
    function DataSize: Word; override;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
    function RangeCheck: Boolean; virtual;
    procedure Error; virtual;
    procedure HandleEvent(var Event: TEvent); override;
    function Valid(Cmd: Word): Boolean; override;
    property ILOptions: Word read FILOptions write FILOptions;
    property LLim: LongInt read FLLim write FLLim;
    property ULim: LongInt read FULim write FULim;
  end;

const
  RInputLong: TStreamRec = (
    ObjType: idInputLong;
    VmtLink: nil;
    Load: @TInputLong.Load;
    Store: @TInputLong.Store
  );

procedure RegisterInpLong;

implementation

function Hex2(B: Byte): string;
const
  HexArray: array[0..15] of Char = '0123456789ABCDEF';
begin
  Result := HexArray[B shr 4] + HexArray[B and $F];
end;

function Hex4(W: Word): string;
begin
  Result := Hex2(Hi(W)) + Hex2(Lo(W));
end;

function Hex8(L: LongInt): string;
begin
  Result := Hex4(LongRec(L).Hi) + Hex4(LongRec(L).Lo);
end;

function FormHexStr(L: LongInt): string;
var
  Minus: Boolean;
  S: string;
begin
  Minus := L < 0;
  if Minus then L := -L;
  S := Hex8(L);
  while (Length(S) > 1) and (S[1] = '0') do Delete(S, 1, 1);
  S := '$' + S;
  if Minus then System.Insert('-', S, 2);
  Result := S;
end;

constructor TInputLong.Create(var R: TRect; AMaxLen: Integer;
  LowerLim, UpperLim: LongInt; Flgs: Word);
begin
  inherited Create(R, AMaxLen);
  FULim := UpperLim;
  FLLim := LowerLim;
  if (Flgs and ilDisplayHex) <> 0 then Flgs := Flgs or ilHex;
  FILOptions := Flgs;
  if (FILOptions and ilBlankEqZero) <> 0 then Data := '0';
end;

constructor TInputLong.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(FILOptions, SizeOf(FILOptions));
  S.Read(FLLim, SizeOf(FLLim));
  S.Read(FULim, SizeOf(FULim));
end;

procedure TInputLong.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(FILOptions, SizeOf(FILOptions));
  S.Write(FLLim, SizeOf(FLLim));
  S.Write(FULim, SizeOf(FULim));
end;

function TInputLong.DataSize: Word;
begin
  Result := SizeOf(LongInt);
end;

procedure TInputLong.GetData(var Rec);
var
  Code: Integer;
begin
  Val(Data, LongInt(Rec), Code);
end;

procedure TInputLong.SetData(var Rec);
var
  L: LongInt;
  S: string;
begin
  L := LongInt(Rec);
  if L > FULim then L := FULim
  else if L < FLLim then L := FLLim;
  if (FILOptions and ilDisplayHex) <> 0 then
    S := FormHexStr(L)
  else
    Str(L, S);
  if Length(S) > MaxLen then SetLength(S, MaxLen);
  Data := S;
end;

function TInputLong.RangeCheck: Boolean;
var
  L: LongInt;
  Code: Integer;
begin
  if (Data = '') and ((FILOptions and ilBlankEqZero) <> 0) then
    Data := '0';
  Val(Data, L, Code);
  Result := (Code = 0) and (L >= FLLim) and (L <= FULim);
end;

procedure TInputLong.Error;
var
  SU, SL: string;
begin
  Str(FLLim, SL);
  Str(FULim, SU);
  if (FILOptions and ilHex) <> 0 then
  begin
    SL := SL + '(' + FormHexStr(FLLim) + ')';
    SU := SU + '(' + FormHexStr(FULim) + ')';
  end;
  MessageBox('Value not within range ' + SL + ' to ' + SU,
    mfError + mfOKButton);
end;

procedure TInputLong.HandleEvent(var Event: TEvent);
var
  L: LongInt;
  Code: Integer;
begin
  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbTab, kbShiftTab:
        begin
          { Enforce limits and formatting when leaving field }
          if (Data = '') and ((FILOptions and ilBlankEqZero) <> 0) then
            Data := '0';
          Val(Data, L, Code);
          if Code = 0 then
          begin
            { Clamp to range }
            if L < FLLim then L := FLLim
            else if L > FULim then L := FULim;
            { Update display with proper formatting }
            SetData(L);
          end
          else if not RangeCheck then
          begin
            Error;
            SelectAll(True);
            ClearEvent(Event);
          end;
        end;
    end;
    if Event.CharCode <> #0 then
    begin
      Event.CharCode := UpCase(Event.CharCode);
      case Event.CharCode of
        '0'..'9', #1..#$1B: ; { acceptable }
        '-':
          if (FLLim >= 0) or (CurPos <> 0) then
            ClearEvent(Event);
        '$':
          if (FILOptions and ilHex) = 0 then ClearEvent(Event);
        'A'..'F':
          if Pos('$', Data) = 0 then ClearEvent(Event);
      else
        ClearEvent(Event);
      end;
    end;
  end;
  inherited HandleEvent(Event);
end;

function TInputLong.Valid(Cmd: Word): Boolean;
var
  Rslt: Boolean;
  L: LongInt;
  Code: Integer;
begin
  Rslt := inherited Valid(Cmd);
  if Rslt and (Cmd <> 0) and (Cmd <> cmCancel) then
  begin
    { Auto-clamp values to range and reformat }
    if (Data = '') and ((FILOptions and ilBlankEqZero) <> 0) then
      Data := '0';
    Val(Data, L, Code);
    if Code = 0 then
    begin
      { Clamp to range }
      if L < FLLim then L := FLLim
      else if L > FULim then L := FULim;
      { Update display with proper formatting }
      SetData(L);
      Rslt := True;
    end
    else
    begin
      { Invalid format - show error }
      Error;
      Select;
      SelectAll(True);
      Rslt := False;
    end;
  end;
  Result := Rslt;
end;

procedure RegisterInpLong;
begin
  RegisterType(RInputLong);
end;

end.
