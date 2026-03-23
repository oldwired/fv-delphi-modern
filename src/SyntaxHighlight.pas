{*******************************************************}
{       Free Vision Syntax Highlighting                 }
{       Extensible lexer interface + JSON/MD lexers     }
{*******************************************************}

unit SyntaxHighlight;

interface

uses
  System.SysUtils, System.Classes,
  FVCommon;

type
  TSyntaxTokenKind = (
    tkDefault,
    tkKeyword,
    tkString,
    tkComment,
    tkNumber,
    tkOperator,
    tkDirective,
    tkError,
    tkIdentifier,
    tkWhitespace,
    { Markdown-specific }
    tkHeading,
    tkEmphasis,
    tkStrong,
    tkCode,
    tkLink,
    tkListMarker,
    tkBlockQuote
  );

  TSyntaxToken = record
    StartPos: Integer;   { 1-based char offset in line }
    Length: Integer;      { Char count }
    Kind: TSyntaxTokenKind;
  end;

  TSyntaxTokenColor = record
    Attr: Byte;
    FG_RGB: Cardinal;
    BG_RGB: Cardinal;
    UL_RGB: Cardinal;
    ExtAttrs: Byte;
  end;

  TSyntaxColorTheme = record
    Colors: array[TSyntaxTokenKind] of TSyntaxTokenColor;
  end;

  ISyntaxHighlighter = interface
    ['{E1F2A3B4-5C6D-7E8F-9A0B-1C2D3E4F5060}']
    procedure SetLine(const ALine: string; ALineIndex: Integer);
    function NextToken(out Token: TSyntaxToken): Boolean;
    procedure ResetState;
  end;

  { JSON Highlighter }
  TJSONHighlighter = class(TInterfacedObject, ISyntaxHighlighter)
  private
    FLine: string;
    FPos: Integer;
    FLen: Integer;
  public
    procedure SetLine(const ALine: string; ALineIndex: Integer);
    function NextToken(out Token: TSyntaxToken): Boolean;
    procedure ResetState;
  end;

  { Markdown Highlighter }
  TMarkdownHighlighter = class(TInterfacedObject, ISyntaxHighlighter)
  private
    FLine: string;
    FPos: Integer;
    FLen: Integer;
    FInCodeBlock: Boolean;
  public
    procedure SetLine(const ALine: string; ALineIndex: Integer);
    function NextToken(out Token: TSyntaxToken): Boolean;
    procedure ResetState;
  end;

function CreateDefaultDarkTheme: TSyntaxColorTheme;

implementation

{ Theme }

function CreateDefaultDarkTheme: TSyntaxColorTheme;
begin
  FillChar(Result, SizeOf(Result), 0);
  { Default: light gray }
  Result.Colors[tkDefault].FG_RGB := $C0C0C0;
  { Keywords: blue }
  Result.Colors[tkKeyword].FG_RGB := $569CD6;
  { Strings: orange }
  Result.Colors[tkString].FG_RGB := $CE9178;
  { Comments: green italic }
  Result.Colors[tkComment].FG_RGB := $6A9955;
  Result.Colors[tkComment].ExtAttrs := eaItalic;
  { Numbers: light green }
  Result.Colors[tkNumber].FG_RGB := $B5CEA8;
  { Operators: light gray }
  Result.Colors[tkOperator].FG_RGB := $D4D4D4;
  { Errors: red wavy underline }
  Result.Colors[tkError].FG_RGB := $FF0000;
  Result.Colors[tkError].UL_RGB := $FF0000;
  Result.Colors[tkError].ExtAttrs := 3 shl eaUnderShift; { curly underline }
  { Identifiers: light blue }
  Result.Colors[tkIdentifier].FG_RGB := $9CDCFE;
  { Whitespace: inherit }
  Result.Colors[tkWhitespace].FG_RGB := 0;
  { Markdown heading: bright yellow bold }
  Result.Colors[tkHeading].FG_RGB := $DCDCAA;
  { Emphasis: italic }
  Result.Colors[tkEmphasis].FG_RGB := $C0C0C0;
  Result.Colors[tkEmphasis].ExtAttrs := eaItalic;
  { Strong: bright white }
  Result.Colors[tkStrong].FG_RGB := $FFFFFF;
  { Code: cyan on dark }
  Result.Colors[tkCode].FG_RGB := $4EC9B0;
  Result.Colors[tkCode].BG_RGB := $1E1E1E;
  { Link: blue underline }
  Result.Colors[tkLink].FG_RGB := $569CD6;
  Result.Colors[tkLink].ExtAttrs := 1 shl eaUnderShift; { single underline }
  { List marker: yellow }
  Result.Colors[tkListMarker].FG_RGB := $D7BA7D;
  { Block quote: dim }
  Result.Colors[tkBlockQuote].FG_RGB := $808080;
  Result.Colors[tkBlockQuote].ExtAttrs := eaDim;
end;

{ TJSONHighlighter }

procedure TJSONHighlighter.SetLine(const ALine: string; ALineIndex: Integer);
begin
  FLine := ALine;
  FPos := 1;
  FLen := Length(FLine);
end;

function TJSONHighlighter.NextToken(out Token: TSyntaxToken): Boolean;
var
  Start: Integer;
begin
  if FPos > FLen then begin
    Result := False;
    Exit;
  end;

  Start := FPos;
  Result := True;

  case FLine[FPos] of
    ' ', #9:
      begin
        while (FPos <= FLen) and CharInSet(FLine[FPos], [' ', #9]) do
          Inc(FPos);
        Token.Kind := tkWhitespace;
      end;
    '"':
      begin
        Inc(FPos);
        while FPos <= FLen do begin
          if FLine[FPos] = '\' then
            Inc(FPos, 2)
          else if FLine[FPos] = '"' then begin
            Inc(FPos);
            Break;
          end else
            Inc(FPos);
        end;
        Token.Kind := tkString;
      end;
    '-', '0'..'9':
      begin
        if FLine[FPos] = '-' then Inc(FPos);
        while (FPos <= FLen) and CharInSet(FLine[FPos], ['0'..'9']) do Inc(FPos);
        if (FPos <= FLen) and (FLine[FPos] = '.') then begin
          Inc(FPos);
          while (FPos <= FLen) and CharInSet(FLine[FPos], ['0'..'9']) do Inc(FPos);
        end;
        if (FPos <= FLen) and CharInSet(FLine[FPos], ['e', 'E']) then begin
          Inc(FPos);
          if (FPos <= FLen) and CharInSet(FLine[FPos], ['+', '-']) then Inc(FPos);
          while (FPos <= FLen) and CharInSet(FLine[FPos], ['0'..'9']) do Inc(FPos);
        end;
        Token.Kind := tkNumber;
      end;
    '{', '}', '[', ']', ':', ',':
      begin
        Inc(FPos);
        Token.Kind := tkOperator;
      end;
    't':
      begin
        if Copy(FLine, FPos, 4) = 'true' then begin
          Inc(FPos, 4);
          Token.Kind := tkKeyword;
        end else begin
          Inc(FPos);
          Token.Kind := tkError;
        end;
      end;
    'f':
      begin
        if Copy(FLine, FPos, 5) = 'false' then begin
          Inc(FPos, 5);
          Token.Kind := tkKeyword;
        end else begin
          Inc(FPos);
          Token.Kind := tkError;
        end;
      end;
    'n':
      begin
        if Copy(FLine, FPos, 4) = 'null' then begin
          Inc(FPos, 4);
          Token.Kind := tkKeyword;
        end else begin
          Inc(FPos);
          Token.Kind := tkError;
        end;
      end;
  else
    begin
      Inc(FPos);
      Token.Kind := tkError;
    end;
  end;

  Token.StartPos := Start;
  Token.Length := FPos - Start;
end;

procedure TJSONHighlighter.ResetState;
begin
  { JSON has no multi-line state }
end;

{ TMarkdownHighlighter }

procedure TMarkdownHighlighter.SetLine(const ALine: string; ALineIndex: Integer);
begin
  FLine := ALine;
  FPos := 1;
  FLen := Length(FLine);
end;

function TMarkdownHighlighter.NextToken(out Token: TSyntaxToken): Boolean;
var
  Start: Integer;
  Trimmed: string;
begin
  if FPos > FLen then begin
    Result := False;
    Exit;
  end;

  Start := FPos;
  Result := True;
  Trimmed := TrimLeft(FLine);

  { Code block toggle }
  if (FPos = 1) and (Copy(Trimmed, 1, 3) = '```') then begin
    FInCodeBlock := not FInCodeBlock;
    Token.StartPos := 1;
    Token.Length := FLen;
    Token.Kind := tkCode;
    FPos := FLen + 1;
    Exit;
  end;

  { Inside code block }
  if FInCodeBlock then begin
    Token.StartPos := 1;
    Token.Length := FLen;
    Token.Kind := tkCode;
    FPos := FLen + 1;
    Exit;
  end;

  { Line-level tokens (only at start of line) }
  if FPos = 1 then begin
    { Headings }
    if (FLen > 0) and (FLine[1] = '#') then begin
      Token.StartPos := 1;
      Token.Length := FLen;
      Token.Kind := tkHeading;
      FPos := FLen + 1;
      Exit;
    end;
    { Blockquote }
    if (FLen > 0) and (FLine[1] = '>') then begin
      Token.StartPos := 1;
      Token.Length := FLen;
      Token.Kind := tkBlockQuote;
      FPos := FLen + 1;
      Exit;
    end;
    { List markers }
    if (FLen >= 2) and CharInSet(FLine[1], ['-', '*', '+']) and (FLine[2] = ' ') then begin
      Token.StartPos := 1;
      Token.Length := 2;
      Token.Kind := tkListMarker;
      FPos := 3;
      Exit;
    end;
    { Ordered list }
    if (FLen >= 3) and CharInSet(FLine[1], ['0'..'9']) then begin
      var I := 1;
      while (I <= FLen) and CharInSet(FLine[I], ['0'..'9']) do Inc(I);
      if (I <= FLen) and (FLine[I] = '.') and (I + 1 <= FLen) and (FLine[I + 1] = ' ') then begin
        Token.StartPos := 1;
        Token.Length := I + 1;
        Token.Kind := tkListMarker;
        FPos := I + 2;
        Exit;
      end;
    end;
  end;

  { Inline tokens }
  case FLine[FPos] of
    '`':
      begin
        Inc(FPos);
        while (FPos <= FLen) and (FLine[FPos] <> '`') do Inc(FPos);
        if FPos <= FLen then Inc(FPos);
        Token.Kind := tkCode;
      end;
    '*', '_':
      begin
        var Marker := FLine[FPos];
        if (FPos + 1 <= FLen) and (FLine[FPos + 1] = Marker) then begin
          { Bold }
          Inc(FPos, 2);
          while (FPos + 1 <= FLen) and not ((FLine[FPos] = Marker) and (FLine[FPos + 1] = Marker)) do
            Inc(FPos);
          if FPos + 1 <= FLen then Inc(FPos, 2);
          Token.Kind := tkStrong;
        end else begin
          { Italic }
          Inc(FPos);
          while (FPos <= FLen) and (FLine[FPos] <> Marker) do Inc(FPos);
          if FPos <= FLen then Inc(FPos);
          Token.Kind := tkEmphasis;
        end;
      end;
    '~':
      begin
        if (FPos + 1 <= FLen) and (FLine[FPos + 1] = '~') then begin
          Inc(FPos, 2);
          while (FPos + 1 <= FLen) and not ((FLine[FPos] = '~') and (FLine[FPos + 1] = '~')) do
            Inc(FPos);
          if FPos + 1 <= FLen then Inc(FPos, 2);
          Token.Kind := tkStrong; { Use strong style for strikethrough in syntax coloring }
        end else begin
          Inc(FPos);
          Token.Kind := tkDefault;
        end;
      end;
    '[':
      begin
        { Link: [text](url) }
        Inc(FPos);
        while (FPos <= FLen) and (FLine[FPos] <> ']') do Inc(FPos);
        if FPos <= FLen then Inc(FPos);
        if (FPos <= FLen) and (FLine[FPos] = '(') then begin
          Inc(FPos);
          while (FPos <= FLen) and (FLine[FPos] <> ')') do Inc(FPos);
          if FPos <= FLen then Inc(FPos);
        end;
        Token.Kind := tkLink;
      end;
  else
    begin
      { Default text - consume until next special char }
      while (FPos <= FLen) and not CharInSet(FLine[FPos], ['`', '*', '_', '~', '[']) do
        Inc(FPos);
      Token.Kind := tkDefault;
    end;
  end;

  Token.StartPos := Start;
  Token.Length := FPos - Start;
end;

procedure TMarkdownHighlighter.ResetState;
begin
  FInCodeBlock := False;
end;

end.
