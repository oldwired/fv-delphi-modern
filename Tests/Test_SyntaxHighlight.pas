{*********************************************************}
{                                                         }
{       Free Vision - Syntax Highlighter Tests            }
{                                                         }
{       Drives TJSONHighlighter and TMarkdownHighlighter  }
{       through canned input lines, walking the token     }
{       stream via the ISyntaxHighlighter interface.      }
{                                                         }
{*********************************************************}

unit Test_SyntaxHighlight;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TSyntaxHighlightTests = class
  public
    [Test] procedure JSON_TokenizesString;
    [Test] procedure JSON_TokenizesNumber;
    [Test] procedure JSON_TokenizesKeywordTrue;
    [Test] procedure JSON_TokenizesObjectStructure;
    [Test] procedure Markdown_TokenizesHeading;
    [Test] procedure Markdown_TokenizesListMarker;
    [Test] procedure Markdown_TokenizesCodeBlock;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  SyntaxHighlight;

function CollectKinds(H: ISyntaxHighlighter; const Line: string;
  LineIndex: Integer): TArray<TSyntaxTokenKind>;
var
  Tok: TSyntaxToken;
  L: TList<TSyntaxTokenKind>;
begin
  L := TList<TSyntaxTokenKind>.Create;
  try
    H.SetLine(Line, LineIndex);
    while H.NextToken(Tok) do
      L.Add(Tok.Kind);
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function ContainsKind(const Kinds: TArray<TSyntaxTokenKind>;
  Wanted: TSyntaxTokenKind): Boolean;
var K: TSyntaxTokenKind;
begin
  for K in Kinds do
    if K = Wanted then Exit(True);
  Result := False;
end;

procedure TSyntaxHighlightTests.JSON_TokenizesString;
var
  H: ISyntaxHighlighter;
  Tok: TSyntaxToken;
begin
  H := TJSONHighlighter.Create;
  H.SetLine('"hello"', 0);
  Assert.IsTrue(H.NextToken(Tok));
  Assert.IsTrue(Tok.Kind = tkString);
  Assert.AreEqual(1, Tok.StartPos);
  Assert.AreEqual(7, Tok.Length);
end;

procedure TSyntaxHighlightTests.JSON_TokenizesNumber;
var
  H: ISyntaxHighlighter;
  Tok: TSyntaxToken;
begin
  H := TJSONHighlighter.Create;
  H.SetLine('-12.5e3', 0);
  Assert.IsTrue(H.NextToken(Tok));
  Assert.IsTrue(Tok.Kind = tkNumber);
  Assert.AreEqual(7, Tok.Length, 'whole literal in one token');
end;

procedure TSyntaxHighlightTests.JSON_TokenizesKeywordTrue;
var
  H: ISyntaxHighlighter;
  Tok: TSyntaxToken;
begin
  H := TJSONHighlighter.Create;
  H.SetLine('true', 0);
  Assert.IsTrue(H.NextToken(Tok));
  Assert.IsTrue(Tok.Kind = tkKeyword);
  Assert.AreEqual(4, Tok.Length);
end;

procedure TSyntaxHighlightTests.JSON_TokenizesObjectStructure;
var
  H: ISyntaxHighlighter;
  Kinds: TArray<TSyntaxTokenKind>;
begin
  H := TJSONHighlighter.Create;
  Kinds := CollectKinds(H, '{"x":42}', 0);
  (* Expect at minimum: tkOperator (open brace), tkString "x", tkOperator colon,
     tkNumber 42, tkOperator (close brace). *)
  Assert.IsTrue(ContainsKind(Kinds, tkOperator));
  Assert.IsTrue(ContainsKind(Kinds, tkString));
  Assert.IsTrue(ContainsKind(Kinds, tkNumber));
end;

procedure TSyntaxHighlightTests.Markdown_TokenizesHeading;
var
  H: ISyntaxHighlighter;
  Kinds: TArray<TSyntaxTokenKind>;
begin
  H := TMarkdownHighlighter.Create;
  Kinds := CollectKinds(H, '# Title', 0);
  Assert.IsTrue(ContainsKind(Kinds, tkHeading));
end;

procedure TSyntaxHighlightTests.Markdown_TokenizesListMarker;
var
  H: ISyntaxHighlighter;
  Kinds: TArray<TSyntaxTokenKind>;
begin
  H := TMarkdownHighlighter.Create;
  Kinds := CollectKinds(H, '- item', 0);
  Assert.IsTrue(ContainsKind(Kinds, tkListMarker));
end;

procedure TSyntaxHighlightTests.Markdown_TokenizesCodeBlock;
var
  H: ISyntaxHighlighter;
  Kinds: TArray<TSyntaxTokenKind>;
begin
  H := TMarkdownHighlighter.Create;
  Kinds := CollectKinds(H, '```pascal', 0);
  { After this line, the highlighter is in a code block — content lines
    should be tokenized as tkCode. Just verify SetLine/NextToken survive. }
  Assert.IsTrue(Length(Kinds) > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TSyntaxHighlightTests);

end.
