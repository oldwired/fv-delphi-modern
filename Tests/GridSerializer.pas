{*********************************************************}
{                                                         }
{       Free Vision - Golden File Cell Serializer         }
{                                                         }
{       Pure functions that turn the live screen cell     }
{       buffer into two diff-friendly representations:    }
{                                                         }
{         CellsToGrid  -> 1 char per cell, CRLF rows      }
{         CellsToJSONL -> 1 JSON object per non-default   }
{                         cell, sorted by (Y, X)          }
{                                                         }
{       No dependency on the global Screen — every caller }
{       passes their own snapshot in.                     }
{                                                         }
{*********************************************************}

unit GridSerializer;

interface

uses
  System.SysUtils,
  FVCommon;

type
  TCellMatrix = array of array of TScreenCell;

function SnapshotScreen: TCellMatrix;

function CellsToGrid(const Cells: TCellMatrix): string;
function CellsToJSONL(const Cells: TCellMatrix): string;

implementation

uses
  FVScreen;

function SnapshotScreen: TCellMatrix;
var
  X, Y, W, H: Integer;
begin
  if (Screen = nil) or (not Screen.Initialized) then begin
    SetLength(Result, 0, 0);
    Exit;
  end;
  W := Screen.Width;
  H := Screen.Height;
  SetLength(Result, H, W);
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
      Result[Y, X] := Screen.GetCell(X, Y);
end;

function CellChar(const C: TScreenCell): string;
var
  W: Word;
begin
  if Length(C.Ch) = 0 then
    Exit(' ');
  { Single-unit cells: collapse C0 controls / fill sentinels to a space. }
  if Length(C.Ch) = 1 then begin
    W := Ord(C.Ch[1]);
    if W < 32 then
      Exit(' ');
    { A lone surrogate half is not valid UTF-16. TEncoding.UTF8.GetBytes
      writes it as U+FFFD on disk while the live string keeps the raw half,
      so the golden could never round-trip (regen == compare fails forever).
      The terminal stores supplementary-plane glyphs as two single-Char
      cells, so this is the common path for emoji. Normalize any unpaired
      surrogate to U+FFFD now so disk and memory always agree. }
    if (W >= $D800) and (W <= $DFFF) then
      Exit(#$FFFD);
    Exit(C.Ch[1]);
  end;
  { Multi-unit cell (a complete grapheme — valid surrogate pair, or base +
    combining marks). Emit it verbatim; UTF-8 round-trips it cleanly. }
  Result := C.Ch;
end;

function CellsToGrid(const Cells: TCellMatrix): string;
var
  SB: TStringBuilder;
  Y, X, H, W: Integer;
begin
  H := Length(Cells);
  if H = 0 then Exit('');
  W := Length(Cells[0]);
  SB := TStringBuilder.Create((W + 2) * H);
  try
    for Y := 0 to H - 1 do begin
      for X := 0 to W - 1 do
        SB.Append(CellChar(Cells[Y, X]));
      SB.Append(#13#10);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function JSONEscape(const S: string): string;
var
  I: Integer;
  C: Char;
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create(Length(S) + 2);
  try
    for I := 1 to Length(S) do begin
      C := S[I];
      case C of
        '"' : SB.Append('\"');
        '\' : SB.Append('\\');
        #8  : SB.Append('\b');
        #9  : SB.Append('\t');
        #10 : SB.Append('\n');
        #12 : SB.Append('\f');
        #13 : SB.Append('\r');
      else
        if Ord(C) < 32 then
          SB.Append('\u' + IntToHex(Ord(C), 4))
        else
          SB.Append(C);
      end;
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function IsDefault(const C: TScreenCell): Boolean;
begin
  Result :=
    (C.Ch = ' ') and (C.FG = 7) and (C.BG = 0) and
    (not C.Bold) and (not C.Underline) and (not C.Inverse) and
    (not C.Italic) and (not C.Strikethrough) and
    (C.UnderlineStyle = 0) and (not C.Dim) and (not C.Overline) and
    (C.FG_RGB = 0) and (C.BG_RGB = 0) and (C.UL_RGB = 0) and
    (C.HyperlinkURL = '');
end;

procedure AppendField(SB: TStringBuilder; var First: Boolean; const Key, Value: string);
begin
  if not First then SB.Append(',');
  SB.Append('"').Append(Key).Append('":').Append(Value);
  First := False;
end;

function CellsToJSONL(const Cells: TCellMatrix): string;
var
  SB: TStringBuilder;
  Y, X, H, W: Integer;
  C: TScreenCell;
  First: Boolean;
begin
  H := Length(Cells);
  if H = 0 then Exit('');
  W := Length(Cells[0]);
  SB := TStringBuilder.Create(1024);
  try
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do begin
        C := Cells[Y, X];
        if IsDefault(C) then Continue;
        SB.Append('{');
        First := True;
        AppendField(SB, First, 'x', IntToStr(X));
        AppendField(SB, First, 'y', IntToStr(Y));
        AppendField(SB, First, 'ch', '"' + JSONEscape(C.Ch) + '"');
        if C.FG <> 7 then AppendField(SB, First, 'fg', IntToStr(C.FG));
        if C.BG <> 0 then AppendField(SB, First, 'bg', IntToStr(C.BG));
        if C.FG_RGB <> 0 then AppendField(SB, First, 'fg_rgb', IntToStr(C.FG_RGB));
        if C.BG_RGB <> 0 then AppendField(SB, First, 'bg_rgb', IntToStr(C.BG_RGB));
        if C.Bold          then AppendField(SB, First, 'bold', 'true');
        if C.Underline     then AppendField(SB, First, 'underline', 'true');
        if C.Inverse       then AppendField(SB, First, 'inverse', 'true');
        if C.Italic        then AppendField(SB, First, 'italic', 'true');
        if C.Strikethrough then AppendField(SB, First, 'strikethrough', 'true');
        if C.Dim           then AppendField(SB, First, 'dim', 'true');
        if C.Overline      then AppendField(SB, First, 'overline', 'true');
        if C.UnderlineStyle <> 0 then AppendField(SB, First, 'underline_style', IntToStr(C.UnderlineStyle));
        if C.UL_RGB <> 0 then AppendField(SB, First, 'ul_rgb', IntToStr(C.UL_RGB));
        if C.HyperlinkURL <> '' then AppendField(SB, First, 'hyperlink_url', '"' + JSONEscape(C.HyperlinkURL) + '"');
        SB.Append('}').Append(#13#10);
      end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.
