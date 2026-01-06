{*******************************************************}
{       Free Vision - Colored Text Unit                 }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  TColoredText is a descendant of TStaticText designed to allow the writing
  of colored text when color monitors are used.  With a monochrome or BW
  monitor, TColoredText acts the same as TStaticText.

  TColoredText is used in exactly the same way as TStaticText except that
  the constructor has an extra Byte parameter specifying the attribute
  desired.  (Do not use a 0 attribute, black on black).
}

unit ColorTxt;

interface

uses
  Objects, Drivers, Views, Dialogs, App, FVConsts;

const
  { Application palette constants }
  apColor      = 0;
  apBlackWhite = 1;
  apMonochrome = 2;

type
  TColoredText = class(TStaticText)
  private
    FAttr: Byte;
  public
    constructor Create(var Bounds: TRect; const AText: string; Attribute: Byte); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    function GetTheColor: Byte; virtual;
    procedure Draw; override;
    procedure Store(var S: TFVStream);
    property Attr: Byte read FAttr write FAttr;
  end;

const
  RColoredText: TStreamRec = (
    ObjType: idColoredText;
    VmtLink: nil;
    Load: @TColoredText.Load;
    Store: @TColoredText.Store
  );

implementation

constructor TColoredText.Create(var Bounds: TRect; const AText: String;
                                  Attribute: Byte);
begin
  inherited Create(Bounds, AText);
  FAttr := Attribute;
end;

constructor TColoredText.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(FAttr, Sizeof(FAttr));
end;

procedure TColoredText.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(FAttr, Sizeof(FAttr));
end;

function TColoredText.GetTheColor: Byte;
begin
  if AppPalette = apColor then
    Result := FAttr
  else
    Result := GetColor(1);
end;

procedure TColoredText.Draw;
var
  Color: Byte;
  Center: Boolean;
  I, J, L, P, Y: Integer;
  B: TDrawBuffer;
  S: string;
begin
  Color := GetTheColor;
  GetText(S);
  L := Length(S);
  P := 1;
  Y := 0;
  Center := False;
  while Y < Size.Y do
  begin
    DrawChar(B, 0, ' ', Color, Size.X);
    if P <= L then
    begin
      if S[P] = #3 then
      begin
        Center := True;
        Inc(P);
      end;
      I := P;
      repeat
        J := P;
        while (P <= L) and (S[P] = ' ') do Inc(P);
        while (P <= L) and (S[P] <> ' ') and (S[P] <> #13) do Inc(P);
      until (P > L) or (P >= I + Size.X) or (S[P] = #13);
      if P > I + Size.X then
        if J > I then P := J else P := I + Size.X;
      if Center then J := (Size.X - P + I) div 2 else J := 0;
      DrawStr(B, J, Copy(S, I, P - I), Color);
      while (P <= L) and (S[P] = ' ') do Inc(P);
      if (P <= L) and (S[P] = #13) then
      begin
        Center := False;
        Inc(P);
        if (P <= L) and (S[P] = #10) then Inc(P);
      end;
    end;
    WriteLine(0, Y, Size.X, 1, B);
    Inc(Y);
  end;
end;

procedure RegisterColorTxt;
begin
  RegisterType(RColoredText);
end;

end.
