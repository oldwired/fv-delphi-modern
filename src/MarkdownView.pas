{*******************************************************}
{       Free Vision Markdown Viewer                     }
{       Rich text rendering with SGR attributes         }
{*******************************************************}

unit MarkdownView;

{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  FVCommon, Drivers, Views, FVConsts, FVBoxChars, SyntaxHighlight;

type
  TMarkdownLineKind = (
    mlParagraph, mlHeading1, mlHeading2, mlHeading3, mlHeading4,
    mlCodeBlock, mlBlockQuote, mlListItem, mlOrderedListItem,
    mlHRule, mlTableRow, mlTableSep, mlImage, mlBlank
  );

  TMarkdownRenderedLine = record
    Text: string;
    Kind: TMarkdownLineKind;
    IndentLevel: Integer;
    { Per-character formatting (parallel to Text) }
    FG_RGBs: TArray<Cardinal>;
    ExtAttrsArr: TArray<Byte>;
    HyperlinkURLs: TArray<string>;
  end;

  TMarkdownView = class(TScroller)
  private
    FSource: TStringList;
    FRendered: TList<TMarkdownRenderedLine>;
    procedure ParseMarkdown;
    procedure AddRenderedLine(const AText: string; AKind: TMarkdownLineKind;
      AIndent: Integer);
    procedure ParseInlineFormatting(var RL: TMarkdownRenderedLine);
    function HeadingColor(Level: Integer): Cardinal;
  public
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar); reintroduce; virtual;
    destructor Destroy; override;
    procedure Draw; override;
    procedure LoadFromString(const AMarkdown: string);
    procedure LoadFromFile(const AFileName: string);
  end;

  TMarkdownWindow = class(TWindow)
  private
    FView: TMarkdownView;
  public
    constructor Create(const ATitle, AMarkdown: string); reintroduce;
    property View: TMarkdownView read FView;
  end;

implementation

uses
  FVScreen;

{ TMarkdownView }

constructor TMarkdownView.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar);
begin
  inherited Create(Bounds, AHScrollBar, AVScrollBar);
  FSource := TStringList.Create;
  FRendered := TList<TMarkdownRenderedLine>.Create;
  GrowMode := gfGrowHiX or gfGrowHiY;
end;

destructor TMarkdownView.Destroy;
begin
  FRendered.Free;
  FSource.Free;
  inherited;
end;

function TMarkdownView.HeadingColor(Level: Integer): Cardinal;
begin
  case Level of
    1: Result := $FFFFFF;  { Bright white }
    2: Result := $DCDCAA;  { Yellow }
    3: Result := $4EC9B0;  { Cyan }
    4: Result := $569CD6;  { Blue }
  else
    Result := $C0C0C0;
  end;
end;

procedure TMarkdownView.AddRenderedLine(const AText: string; AKind: TMarkdownLineKind;
  AIndent: Integer);
var
  RL: TMarkdownRenderedLine;
  I, L: Integer;
begin
  RL.Text := AText;
  RL.Kind := AKind;
  RL.IndentLevel := AIndent;
  L := Length(AText);
  SetLength(RL.FG_RGBs, L);
  SetLength(RL.ExtAttrsArr, L);
  SetLength(RL.HyperlinkURLs, L);

  { Default formatting based on kind }
  for I := 0 to L - 1 do begin
    RL.HyperlinkURLs[I] := '';
    RL.ExtAttrsArr[I] := 0;
    case AKind of
      mlHeading1..mlHeading4:
        RL.FG_RGBs[I] := HeadingColor(Ord(AKind) - Ord(mlHeading1) + 1);
      mlCodeBlock:
        RL.FG_RGBs[I] := $4EC9B0;
      mlBlockQuote: begin
        RL.FG_RGBs[I] := $808080;
        RL.ExtAttrsArr[I] := eaDim;
      end;
      mlHRule:
        RL.FG_RGBs[I] := $808080;
      mlListItem, mlOrderedListItem: begin
        if I < AIndent then
          RL.FG_RGBs[I] := $D7BA7D  { Marker color }
        else
          RL.FG_RGBs[I] := $C0C0C0;
      end;
      mlTableRow:
        RL.FG_RGBs[I] := $C0C0C0;
      mlTableSep:
        RL.FG_RGBs[I] := $808080;
    else
      RL.FG_RGBs[I] := $C0C0C0;
    end;
  end;

  { Parse inline formatting for paragraphs, list items, blockquotes }
  if AKind in [mlParagraph, mlListItem, mlOrderedListItem, mlBlockQuote,
               mlHeading1, mlHeading2, mlHeading3, mlHeading4] then
    ParseInlineFormatting(RL);

  FRendered.Add(RL);
end;

procedure TMarkdownView.ParseInlineFormatting(var RL: TMarkdownRenderedLine);
var
  I, L, Start: Integer;
  NewText: string;
  NewFG: TList<Cardinal>;
  NewExt: TList<Byte>;
  NewURL: TList<string>;
  BaseFG: Cardinal;
  BaseExt: Byte;

  procedure AddChar(C: Char; FG: Cardinal; Ext: Byte; const URL: string);
  begin
    NewText := NewText + C;
    NewFG.Add(FG);
    NewExt.Add(Ext);
    NewURL.Add(URL);
  end;

  procedure AddStr(const S: string; FG: Cardinal; Ext: Byte; const URL: string);
  var
    J: Integer;
  begin
    for J := 1 to Length(S) do
      AddChar(S[J], FG, Ext, URL);
  end;

begin
  L := Length(RL.Text);
  if L = 0 then Exit;

  NewText := '';
  NewFG := TList<Cardinal>.Create;
  NewExt := TList<Byte>.Create;
  NewURL := TList<string>.Create;
  try
    { Preserve base formatting from kind }
    if Length(RL.FG_RGBs) > 0 then
      BaseFG := RL.FG_RGBs[0]
    else
      BaseFG := $C0C0C0;
    if Length(RL.ExtAttrsArr) > 0 then
      BaseExt := RL.ExtAttrsArr[0]
    else
      BaseExt := 0;

    I := 1;
    while I <= L do begin
      if (I + 1 <= L) and (RL.Text[I] = '*') and (RL.Text[I + 1] = '*') then begin
        { Bold: **text** }
        Inc(I, 2);
        Start := I;
        while (I + 1 <= L) and not ((RL.Text[I] = '*') and (RL.Text[I + 1] = '*')) do
          Inc(I);
        AddStr(Copy(RL.Text, Start, I - Start), $FFFFFF, BaseExt, '');
        if (I + 1 <= L) then Inc(I, 2);
      end
      else if (RL.Text[I] = '*') or (RL.Text[I] = '_') then begin
        { Italic: *text* or _text_ }
        var Marker := RL.Text[I];
        Inc(I);
        Start := I;
        while (I <= L) and (RL.Text[I] <> Marker) do Inc(I);
        AddStr(Copy(RL.Text, Start, I - Start), BaseFG, BaseExt or eaItalic, '');
        if I <= L then Inc(I);
      end
      else if (I + 1 <= L) and (RL.Text[I] = '~') and (RL.Text[I + 1] = '~') then begin
        { Strikethrough: ~~text~~ }
        Inc(I, 2);
        Start := I;
        while (I + 1 <= L) and not ((RL.Text[I] = '~') and (RL.Text[I + 1] = '~')) do
          Inc(I);
        AddStr(Copy(RL.Text, Start, I - Start), BaseFG, BaseExt or eaStrikethrough, '');
        if (I + 1 <= L) then Inc(I, 2);
      end
      else if RL.Text[I] = '`' then begin
        { Code: `text` }
        Inc(I);
        Start := I;
        while (I <= L) and (RL.Text[I] <> '`') do Inc(I);
        AddStr(Copy(RL.Text, Start, I - Start), $4EC9B0, 0, '');
        if I <= L then Inc(I);
      end
      else if RL.Text[I] = '[' then begin
        { Link: [text](url) }
        Inc(I);
        Start := I;
        while (I <= L) and (RL.Text[I] <> ']') do Inc(I);
        var LinkText := Copy(RL.Text, Start, I - Start);
        var LinkURL := '';
        if I <= L then Inc(I); { skip ] }
        if (I <= L) and (RL.Text[I] = '(') then begin
          Inc(I);
          Start := I;
          while (I <= L) and (RL.Text[I] <> ')') do Inc(I);
          LinkURL := Copy(RL.Text, Start, I - Start);
          if I <= L then Inc(I); { skip ) }
        end;
        AddStr(LinkText, $569CD6, 1 shl eaUnderShift, LinkURL);
      end
      else begin
        AddChar(RL.Text[I], BaseFG, BaseExt, '');
        Inc(I);
      end;
    end;

    { Update the rendered line }
    RL.Text := NewText;
    SetLength(RL.FG_RGBs, NewFG.Count);
    SetLength(RL.ExtAttrsArr, NewExt.Count);
    SetLength(RL.HyperlinkURLs, NewURL.Count);
    for I := 0 to NewFG.Count - 1 do begin
      RL.FG_RGBs[I] := NewFG[I];
      RL.ExtAttrsArr[I] := NewExt[I];
      RL.HyperlinkURLs[I] := NewURL[I];
    end;
  finally
    NewURL.Free;
    NewExt.Free;
    NewFG.Free;
  end;
end;

procedure TMarkdownView.ParseMarkdown;
var
  I: Integer;
  Line, Trimmed: string;
  InCodeBlock: Boolean;
  HeadingLevel: Integer;
begin
  FRendered.Clear;
  InCodeBlock := False;

  for I := 0 to FSource.Count - 1 do begin
    Line := FSource[I];
    Trimmed := TrimLeft(Line);

    { Code block toggle }
    if Copy(Trimmed, 1, 3) = '```' then begin
      InCodeBlock := not InCodeBlock;
      if InCodeBlock then
        AddRenderedLine('  ' + Copy(Trimmed, 4, MaxInt), mlCodeBlock, 0)
      else
        AddRenderedLine('', mlBlank, 0);
      Continue;
    end;

    if InCodeBlock then begin
      AddRenderedLine('  ' + Line, mlCodeBlock, 0);
      Continue;
    end;

    { Blank lines }
    if Trimmed = '' then begin
      AddRenderedLine('', mlBlank, 0);
      Continue;
    end;

    { Horizontal rule }
    if (Length(Trimmed) >= 3) and
       ((Copy(Trimmed, 1, 3) = '---') or (Copy(Trimmed, 1, 3) = '***') or
        (Copy(Trimmed, 1, 3) = '___')) then begin
      var HRLine := '';
      for var J := 1 to Size.X - 2 do HRLine := HRLine + BoxHoriz;
      AddRenderedLine(HRLine, mlHRule, 0);
      Continue;
    end;

    { Headings }
    if Trimmed[1] = '#' then begin
      HeadingLevel := 0;
      var P := 1;
      while (P <= Length(Trimmed)) and (Trimmed[P] = '#') do begin
        Inc(HeadingLevel);
        Inc(P);
      end;
      if (P <= Length(Trimmed)) and (Trimmed[P] = ' ') then Inc(P);
      var HeadText := Copy(Trimmed, P, MaxInt);
      case HeadingLevel of
        1: AddRenderedLine(HeadText, mlHeading1, 0);
        2: AddRenderedLine('  ' + HeadText, mlHeading2, 0);
        3: AddRenderedLine('    ' + HeadText, mlHeading3, 0);
      else
        AddRenderedLine('      ' + HeadText, mlHeading4, 0);
      end;
      Continue;
    end;

    { Blockquote }
    if Trimmed[1] = '>' then begin
      var QuoteText := Copy(Trimmed, 2, MaxInt);
      if (Length(QuoteText) > 0) and (QuoteText[1] = ' ') then
        QuoteText := Copy(QuoteText, 2, MaxInt);
      AddRenderedLine(BoxVert + ' ' + QuoteText, mlBlockQuote, 2);
      Continue;
    end;

    { Unordered list }
    if (Length(Trimmed) >= 2) and CharInSet(Trimmed[1], ['-', '*', '+']) and (Trimmed[2] = ' ') then begin
      AddRenderedLine('  ' + #$2022 + ' ' + Copy(Trimmed, 3, MaxInt), mlListItem, 4);
      Continue;
    end;

    { Ordered list }
    if CharInSet(Trimmed[1], ['0'..'9']) then begin
      var P := 1;
      while (P <= Length(Trimmed)) and CharInSet(Trimmed[P], ['0'..'9']) do Inc(P);
      if (P <= Length(Trimmed)) and (Trimmed[P] = '.') and (P + 1 <= Length(Trimmed)) and (Trimmed[P + 1] = ' ') then begin
        var NumStr := Copy(Trimmed, 1, P);
        AddRenderedLine('  ' + NumStr + ' ' + Copy(Trimmed, P + 2, MaxInt), mlOrderedListItem, Length(NumStr) + 3);
        Continue;
      end;
    end;

    { Table row }
    if (Length(Trimmed) > 0) and (Trimmed[1] = '|') then begin
      { Check if separator row }
      var IsSep := True;
      for var J := 1 to Length(Trimmed) do
        if not CharInSet(Trimmed[J], ['|', '-', ':', ' ']) then begin
          IsSep := False;
          Break;
        end;
      if IsSep then
        AddRenderedLine(Trimmed, mlTableSep, 0)
      else
        AddRenderedLine(Trimmed, mlTableRow, 0);
      Continue;
    end;

    { Image }
    if Copy(Trimmed, 1, 2) = '![' then begin
      var P := 3;
      while (P <= Length(Trimmed)) and (Trimmed[P] <> ']') do Inc(P);
      var AltText := Copy(Trimmed, 3, P - 3);
      AddRenderedLine('[Image: ' + AltText + ']', mlImage, 0);
      Continue;
    end;

    { Default: paragraph }
    AddRenderedLine(Line, mlParagraph, 0);
  end;

  SetLimit(Size.X, FRendered.Count);
end;

procedure TMarkdownView.Draw;
var
  B: TDrawBuffer;
  Y, I, J, W: Integer;
  RL: TMarkdownRenderedLine;
  C: Byte;
begin
  W := Size.X;
  C := $17; { white on blue default }

  for Y := 0 to Size.Y - 1 do begin
    I := Delta.Y + Y;
    DrawChar(B, 0, ' ', C, W);

    if (I >= 0) and (I < FRendered.Count) then begin
      RL := FRendered[I];

      { Code block gets dark background }
      if RL.Kind = mlCodeBlock then
        DrawChar(B, 0, ' ', $08, W);

      { Write text with per-character formatting }
      for J := 0 to Length(RL.Text) - 1 do begin
        if J >= W then Break;
        if J < Length(RL.Text) then begin
          B[J].Ch := RL.Text[J + 1];
          { Keep Attr from DrawChar pre-fill ($17 = white on blue) so
            BG_RGB=0 falls through to the blue window background }
          if J < Length(RL.FG_RGBs) then
            B[J].FG_RGB := RL.FG_RGBs[J]
          else
            B[J].FG_RGB := $C0C0C0;
          if RL.Kind = mlCodeBlock then
            B[J].BG_RGB := $1E1E1E
          else
            B[J].BG_RGB := 0;
          if J < Length(RL.ExtAttrsArr) then
            B[J].ExtAttrs := RL.ExtAttrsArr[J]
          else
            B[J].ExtAttrs := 0;
          B[J].UL_RGB := 0;
          if J < Length(RL.HyperlinkURLs) then
            B[J].HyperlinkURL := RL.HyperlinkURLs[J]
          else
            B[J].HyperlinkURL := '';
        end;
      end;
    end;

    WriteLine(0, Y, W, 1, B);
  end;
end;

procedure TMarkdownView.LoadFromString(const AMarkdown: string);
begin
  FSource.Text := AMarkdown;
  ParseMarkdown;
  ScrollTo(0, 0);
  DrawView;
end;

procedure TMarkdownView.LoadFromFile(const AFileName: string);
begin
  FSource.LoadFromFile(AFileName, TEncoding.UTF8);
  ParseMarkdown;
  ScrollTo(0, 0);
  DrawView;
end;

{ TMarkdownWindow }

constructor TMarkdownWindow.Create(const ATitle, AMarkdown: string);
var
  R: TRect;
  VSB: TScrollBar;
begin
  R.Assign(2, 1, ScreenWidth - 2, ScreenHeight - 2);
  inherited Create(R, ATitle, wnNoNumber);
  Options := Options or ofTileable;

  { Scrollbar }
  GetExtent(R);
  R.Assign(R.B.X - 1, R.A.Y + 1, R.B.X, R.B.Y - 1);
  VSB := TScrollBar.Create(R);
  Insert(VSB);

  { Markdown view }
  GetExtent(R);
  R.Grow(-1, -1);
  Dec(R.B.X);
  FView := TMarkdownView.Create(R, nil, VSB);
  FView.GrowMode := gfGrowHiX or gfGrowHiY;
  Insert(FView);

  FView.LoadFromString(AMarkdown);
end;

end.
