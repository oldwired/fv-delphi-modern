{*********************************************************}
{                                                         }
{       Free Vision - UTF-8 / Width Tests                 }
{                                                         }
{       Covers FVUTF8 encoding detection, codepoint       }
{       decoding (including surrogate pairs for emoji),   }
{       and display-width calculation.                     }
{                                                         }
{*********************************************************}

unit Test_UTF8;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TUTF8Tests = class
  public
    [Test] procedure DetectEncoding_UTF8BOM;
    [Test] procedure DetectEncoding_UTF16LE;
    [Test] procedure DetectEncoding_PlainASCII;
    [Test] procedure UTF8CharLen_KnownLeadBytes;
    [Test] procedure IsUTF8TrailByte_Boundaries;
    [Test] procedure DecodeUTF8ToString_ASCII;
    [Test] procedure DecodeUTF8ToString_BMP_Latin;
    [Test] procedure DecodeUTF8ToString_Emoji_SurrogatePair;
    [Test] procedure DecodeUTF8CodePoint_Emoji;
    [Test] procedure CodePointCharWidth_ASCII_IsOne;
    [Test] procedure CodePointCharWidth_CJK_IsTwo;
    [Test] procedure CodePointCharWidth_Combining_IsZero;
    [Test] procedure CodePointCharWidth_Emoji_IsTwo;
    [Test] procedure IsWideString_DetectsCJK;
    [Test] procedure StringDisplayWidth_Mixed;
  end;

implementation

uses
  System.SysUtils,
  FVUTF8;

procedure TUTF8Tests.DetectEncoding_UTF8BOM;
var B: TBytes;
begin
  B := TBytes.Create($EF, $BB, $BF, Ord('h'), Ord('i'));
  Assert.IsTrue(DetectEncoding(B, Length(B)) = feUTF8BOM);
end;

procedure TUTF8Tests.DetectEncoding_UTF16LE;
var B: TBytes;
begin
  B := TBytes.Create($FF, $FE, Ord('h'), 0, Ord('i'), 0);
  Assert.IsTrue(DetectEncoding(B, Length(B)) = feUTF16LE);
end;

procedure TUTF8Tests.DetectEncoding_PlainASCII;
var B: TBytes;
begin
  B := TBytes.Create(Ord('h'), Ord('e'), Ord('l'), Ord('l'), Ord('o'));
  { Plain ASCII content with no BOM is reported as either feUTF8 or feANSI
    depending on heuristics; we just require it's not declared UTF-16. }
  Assert.IsTrue(DetectEncoding(B, Length(B)) <> feUTF16LE);
  Assert.IsTrue(DetectEncoding(B, Length(B)) <> feUTF16BE);
end;

procedure TUTF8Tests.UTF8CharLen_KnownLeadBytes;
begin
  Assert.AreEqual(1, UTF8CharLen($41));    // 'A'  — single byte
  Assert.AreEqual(2, UTF8CharLen($C3));    // 0xC3 0xA4 = ä
  Assert.AreEqual(3, UTF8CharLen($E4));    // 0xE4 0xB8 0xAD = 中
  Assert.AreEqual(4, UTF8CharLen($F0));    // 0xF0 0x9F 0x98 0x80 = 😀
end;

procedure TUTF8Tests.IsUTF8TrailByte_Boundaries;
begin
  Assert.IsTrue(IsUTF8TrailByte($80));
  Assert.IsTrue(IsUTF8TrailByte($BF));
  Assert.IsFalse(IsUTF8TrailByte($7F));
  Assert.IsFalse(IsUTF8TrailByte($C0));
end;

procedure TUTF8Tests.DecodeUTF8ToString_ASCII;
var
  B: TBytes;
  L: Integer;
  S: string;
begin
  B := TBytes.Create(Ord('A'));
  S := DecodeUTF8ToString(@B[0], 1, L);
  Assert.AreEqual('A', S);
  Assert.AreEqual(1, L);
end;

procedure TUTF8Tests.DecodeUTF8ToString_BMP_Latin;
var
  B: TBytes;
  L: Integer;
  S: string;
begin
  B := TBytes.Create($C3, $A4);    // ä (U+00E4)
  S := DecodeUTF8ToString(@B[0], 2, L);
  Assert.AreEqual(#$00E4, S);
  Assert.AreEqual(2, L);
end;

procedure TUTF8Tests.DecodeUTF8ToString_Emoji_SurrogatePair;
var
  B: TBytes;
  L: Integer;
  S: string;
begin
  { U+1F600 GRINNING FACE — emoji, encoded as 4 UTF-8 bytes,
    which Delphi represents in a UTF-16 string as a surrogate pair. }
  B := TBytes.Create($F0, $9F, $98, $80);
  S := DecodeUTF8ToString(@B[0], 4, L);
  Assert.AreEqual(2, Length(S), 'emoji should be a surrogate pair (2 UTF-16 code units)');
  Assert.AreEqual(4, L, 'consumed all four UTF-8 bytes');
  Assert.AreEqual(Word($D83D), Word(S[1]), 'high surrogate');
  Assert.AreEqual(Word($DE00), Word(S[2]), 'low surrogate');
end;

procedure TUTF8Tests.DecodeUTF8CodePoint_Emoji;
var
  B: TBytes;
  L: Integer;
  CP: Cardinal;
begin
  B := TBytes.Create($F0, $9F, $98, $80);    // U+1F600
  CP := DecodeUTF8CodePoint(@B[0], 4, L);
  Assert.AreEqual(Cardinal($1F600), CP);
  Assert.AreEqual(4, L);
end;

procedure TUTF8Tests.CodePointCharWidth_ASCII_IsOne;
begin
  Assert.AreEqual(1, CodePointCharWidth(Ord('A')));
  Assert.AreEqual(1, CodePointCharWidth(Ord(' ')));
  Assert.AreEqual(1, CodePointCharWidth($00E4));     // ä
end;

procedure TUTF8Tests.CodePointCharWidth_CJK_IsTwo;
begin
  Assert.AreEqual(2, CodePointCharWidth($4E2D));     // 中
  Assert.AreEqual(2, CodePointCharWidth($65E5));     // 日
end;

procedure TUTF8Tests.CodePointCharWidth_Combining_IsZero;
begin
  Assert.AreEqual(0, CodePointCharWidth($0301));     // combining acute accent
  Assert.AreEqual(0, CodePointCharWidth($200B));     // zero-width space
end;

procedure TUTF8Tests.CodePointCharWidth_Emoji_IsTwo;
begin
  Assert.AreEqual(2, CodePointCharWidth($1F600));    // 😀
end;

procedure TUTF8Tests.IsWideString_DetectsCJK;
begin
  (* IsWideString is implemented as "StringDisplayWidth(S) > 1" — it reports
     True for any string with display width > 1, not just strings containing
     wide chars. So pure ASCII of length > 1 is "wide" by this definition.
     We test the boundary cases that match the actual contract. *)
  Assert.IsFalse(IsWideString(''));
  Assert.IsTrue(IsWideString('中'));        // single wide char, width 2
  Assert.IsTrue(IsWideString('中文'));      // width 4
end;

procedure TUTF8Tests.StringDisplayWidth_Mixed;
begin
  Assert.AreEqual(5, StringDisplayWidth('hello'));
  Assert.AreEqual(7, StringDisplayWidth('A中B日C'));   // 1 + 2 + 1 + 2 + 1
end;

initialization
  TDUnitX.RegisterTestFixture(TUTF8Tests);

end.
