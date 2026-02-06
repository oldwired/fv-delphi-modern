{*******************************************************}
{       Free Vision - ASCII Table Unit                  }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  ASCII Table dialog window - displays a 32x8 grid of characters
  and shows character details (decimal, hex values).
}

unit AsciiTab;

interface

uses
  System.SysUtils, FVConsts, Objects, Drivers, Views, App;

{***************************************************************************}
{                        PUBLIC OBJECT DEFINITIONS                          }
{***************************************************************************}


{---------------------------------------------------------------------------}
{                  TTABLE OBJECT - 32x32 matrix of all chars                }
{---------------------------------------------------------------------------}

type
  TTable = class(TView)
  private
    procedure DrawCurPos(enable: boolean);
  public
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
  end;

{---------------------------------------------------------------------------}
{                  TREPORT OBJECT - View with details of current AnsiChar       }
{---------------------------------------------------------------------------}
  TReport = class(TView)
  private
    FASCIIChar: LongInt;
  public
    constructor Load(var S: TFVStream);
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Store(var S: TFVStream);
    property ASCIIChar: LongInt read FASCIIChar write FASCIIChar;
  end;

{---------------------------------------------------------------------------}
{                  TASCIIChart OBJECT - the complete AsciiChar window       }
{---------------------------------------------------------------------------}

  TASCIIChart = class(TWindow)
  private
    FReport: TReport;
    FTable: TTable;
  public
    constructor Create; reintroduce; virtual;
    constructor Load(var S: TFVStream);
    procedure Store(var S: TFVStream);
    procedure HandleEvent(var Event: TEvent); override;
    property Report: TReport read FReport;
    property Table: TTable read FTable;
  end;

{---------------------------------------------------------------------------}
{ AsciiTableCommandBase                                                     }
{---------------------------------------------------------------------------}

const
  AsciiTableCommandBase: Word = 910;

{---------------------------------------------------------------------------}
{ Registrations records                                                     }
{---------------------------------------------------------------------------}

  RTable: TStreamRec = (
    ObjType: idTable;
    VmtLink: nil;
    Load: @TTable.Load;
    Store: @TTable.Store
  );
  RReport: TStreamRec = (
    ObjType: idReport;
    VmtLink: nil;
    Load: @TReport.Load;
    Store: @TReport.Store
  );
  RASCIIChart: TStreamRec = (
    ObjType: idASCIIChart;
    VmtLink: nil;
    Load: @TASCIIChart.Load;
    Store: @TASCIIChart.Store
  );

{---------------------------------------------------------------------------}
{ Registration procedure                                                    }
{---------------------------------------------------------------------------}
procedure RegisterASCIITab;



{<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>}
                             IMPLEMENTATION
{<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>}

{***************************************************************************}
{                           HELPER FUNCTIONS                                }
{***************************************************************************}

{ Returns a displayable character for the ASCII chart.
  Control characters (0-31, 127) are replaced with a middle dot placeholder
  since they either have zero width, have special effects (like TAB), or
  are invisible/unrenderable. }
function GetDisplayChar(CharCode: Integer): Char;
const
  MiddleDot = #$00B7;  { · - Middle dot as placeholder for control chars }
begin
  CharCode := CharCode and $FF;
  { C0 control chars (0-31), DEL (127), and C1 control chars (128-159)
    are not renderable in Unicode - replace with placeholder }
  if (CharCode < 32) or ((CharCode >= 127) and (CharCode <= 159)) then
    Result := MiddleDot
  else
    Result := Char(CharCode);
end;

{ Returns the actual character for the report display.
  For control characters, returns a safe representation. }
function GetReportDisplayChar(CharCode: Integer): Char;
const
  MiddleDot = #$00B7;  { · - Middle dot as placeholder for control chars }
begin
  CharCode := CharCode and $FF;
  { C0 control chars (0-31), DEL (127), and C1 control chars (128-159)
    are not renderable in Unicode - replace with placeholder }
  if (CharCode < 32) or ((CharCode >= 127) and (CharCode <= 159)) then
    Result := MiddleDot
  else
    Result := Char(CharCode);
end;

{***************************************************************************}
{                              OBJECT METHODS                               }
{***************************************************************************}

{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
{                          TTable OBJECT METHODS                            }
{+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

procedure TTable.Draw;
var
  NormColor: Byte;
  B: TDrawBuffer;
  X, Y: Integer;
  CharCode: Integer;
begin
  NormColor := GetColor(1);
  for Y := 0 to Size.Y - 1 do
  begin
    { Set each cell using new TDrawCell format }
    for X := 0 to Size.X - 1 do
    begin
      CharCode := (Y * Size.X + X) and $FF;
      { Use helper function to get safe displayable character }
      B[X].Ch := GetDisplayChar(CharCode);
      B[X].Attr := NormColor;
    end;
    WriteLine(0, Y, Size.X, 1, B);
  end;
  DrawCurPos(True);
end;

procedure TTable.DrawCurPos(Enable: Boolean);
var
  Color: Byte;
  B: TDrawBuffer;
  CharCode: Integer;
begin
  Color := GetColor(1);
  { Add highlight if enable (swap foreground and background) }
  if Enable then
    Color := ((Color and $F) shl 4) or (Color shr 4);
  CharCode := (Cursor.Y * Size.X + Cursor.X) and $FF;
  { Use helper function to get safe displayable character }
  B[0].Ch := GetDisplayChar(CharCode);
  B[0].Attr := Color;
  WriteLine(Cursor.X, Cursor.Y, 1, 1, B);
end;

procedure TTable.HandleEvent(var Event: TEvent);
var
  CurrentPos: TPoint;
  Handled: Boolean;

  procedure SetTo(XPos, YPos: Integer; Press: SmallInt);
  var
    NewChar: NativeInt;
  begin
    NewChar := (YPos * Size.X + XPos) and $FF;
    DrawCurPos(False);
    SetCursor(XPos, YPos);
    Message(Owner, evCommand, AsciiTableCommandBase, Pointer(NewChar));
    if Press > 0 then
      Message(Owner, evCommand, AsciiTableCommandBase + Press, Pointer(NewChar));
    DrawCurPos(True);
    ClearEvent(Event);
  end;

begin
  case Event.What of
    evMouseDown:
      if MouseInView(Event.Where) then
      begin
        MakeLocal(Event.Where, CurrentPos);
        SetTo(CurrentPos.X, CurrentPos.Y, 1);
        Exit;
      end;
    evKeyDown:
      begin
        Handled := True;
        case Event.KeyCode of
          kbUp:    if Cursor.Y > 0 then SetTo(Cursor.X, Cursor.Y - 1, 0);
          kbDown:  if Cursor.Y < Size.Y - 1 then SetTo(Cursor.X, Cursor.Y + 1, 0);
          kbLeft:  if Cursor.X > 0 then SetTo(Cursor.X - 1, Cursor.Y, 0);
          kbRight: if Cursor.X < Size.X - 1 then SetTo(Cursor.X + 1, Cursor.Y, 0);
          kbHome:  SetTo(0, 0, 0);
          kbEnd:   SetTo(Size.X - 1, Size.Y - 1, 0);
          kbEnter: SetTo(Cursor.X, Cursor.Y, 1);
        else
          Handled := False;
        end;
        if Handled then Exit;
      end;
  end;
  inherited HandleEvent(Event);
end;

{ TReport }

constructor TReport.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(FASCIIChar, SizeOf(FASCIIChar));
end;

procedure TReport.Draw;
var
  StHex, StDec, S: string;
begin
  Str(FASCIIChar, StDec);
  while Length(StDec) < 3 do
    StDec := ' ' + StDec;
  StHex := IntToHex(FASCIIChar, 2);
  { Use helper function for safe character display }
  S := 'Char "' + GetReportDisplayChar(FASCIIChar) + '" Decimal: ' + StDec + ' Hex: $' + StHex + '  ';
  WriteStr(0, 0, S, 1);
end;

procedure TReport.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evCommand) and
     (Event.Command = AsciiTableCommandBase) then
  begin
    FASCIIChar := NativeInt(Event.InfoPtr);
    Draw;
    ClearEvent(Event);
  end
  else
    inherited HandleEvent(Event);
end;

procedure TReport.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(FASCIIChar, SizeOf(FASCIIChar));
end;

{ TASCIIChart }

constructor TASCIIChart.Create;
var
  R: TRect;
begin
  R.Assign(0, 0, 34, 12);
  inherited Create(R, 'ASCII Table', wnNoNumber);
  Flags := Flags and not (wfGrow or wfZoom);
  Palette := wpGrayWindow;
  R.Assign(1, 10, 33, 11);
  FReport := TReport.Create(R);
  FReport.Options := FReport.Options or ofFramed;
  Insert(FReport);
  R.Assign(1, 1, 33, 9);
  FTable := TTable.Create(R);
  FTable.Options := FTable.Options or (ofSelectable + ofTopSelect);
  Insert(FTable);
  FTable.Select;
end;

constructor TASCIIChart.Load(var S: TFVStream);
begin
  inherited Load(S);
  FTable := TTable(GetSubViewPtr(S, Self));
  FReport := TReport(GetSubViewPtr(S, Self));
end;

procedure TASCIIChart.Store(var S: TFVStream);
begin
  inherited Store(S);
  PutSubViewPtr(S, FTable);
  PutSubViewPtr(S, FReport);
end;

procedure TASCIIChart.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evCommand) and
     (Event.Command = AsciiTableCommandBase) then
    FReport.HandleEvent(Event)
  else
    inherited HandleEvent(Event);
end;

procedure RegisterASCIITab;
begin
  RegisterType(RTable);
  RegisterType(RReport);
  RegisterType(RAsciiChart);
end;

end.
