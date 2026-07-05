{*********************************************************}
{                                                         }
{       Free Vision - Unicode Width Range Tests           }
{                                                         }
{       Boundary tests around the binary-searched wide /  }
{       zero-width range tables in FVUnicodeWidth.        }
{                                                         }
{*********************************************************}

unit Test_UnicodeWidth;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TUnicodeWidthTests = class
  public
    [Test] procedure Wide_CJK_Block_IsWide;
    [Test] procedure Wide_BeforeCJK_IsNotWide;
    [Test] procedure Wide_AfterCJK_IsNotWide;
    [Test] procedure Wide_EmojiPlane_IsWide;
    [Test] procedure Zero_Combining_IsZero;
    [Test] procedure Zero_NonCombining_IsNotZero;
    [Test] procedure CellWidth_Default_IsOne;
    [Test] procedure CellWidth_Wide_IsTwo;
    [Test] procedure CellWidth_Zero_IsZero;
  end;

implementation

uses
  FVUnicodeWidth;

procedure TUnicodeWidthTests.Wide_CJK_Block_IsWide;
begin
  { CJK Unified Ideographs U+4E00..U+9FFF — all wide. }
  Assert.IsTrue(FVIsWideCodePoint($4E00), 'first CJK ideograph');
  Assert.IsTrue(FVIsWideCodePoint($4E2D), 'CJK 中');
  Assert.IsTrue(FVIsWideCodePoint($9FFF), 'last CJK ideograph (block end)');
end;

procedure TUnicodeWidthTests.Wide_BeforeCJK_IsNotWide;
begin
  { Latin / common-script range is narrow. }
  Assert.IsFalse(FVIsWideCodePoint(Ord('A')));
  Assert.IsFalse(FVIsWideCodePoint($00E4));     // ä
  Assert.IsFalse(FVIsWideCodePoint($0301));     // combining acute (zero, not wide)
end;

procedure TUnicodeWidthTests.Wide_AfterCJK_IsNotWide;
begin
  { Spot-check codepoints that are NOT wide so the range isn't reporting
    "everything is wide above some threshold". $00B0 (degree sign) and
    $0394 (Greek capital delta) are both ambiguous/narrow in cell terms. }
  Assert.IsFalse(FVIsWideCodePoint($00B0));
  Assert.IsFalse(FVIsWideCodePoint($0394));
end;

procedure TUnicodeWidthTests.Wide_EmojiPlane_IsWide;
begin
  Assert.IsTrue(FVIsWideCodePoint($1F600), 'grinning face');
  Assert.IsTrue(FVIsWideCodePoint($1F4A9), 'pile of poo');
end;

procedure TUnicodeWidthTests.Zero_Combining_IsZero;
begin
  Assert.IsTrue(FVIsZeroCodePoint($0301), 'combining acute');
  Assert.IsTrue(FVIsZeroCodePoint($0300), 'combining grave');
  Assert.IsTrue(FVIsZeroCodePoint($200B), 'zero-width space');
end;

procedure TUnicodeWidthTests.Zero_NonCombining_IsNotZero;
begin
  Assert.IsFalse(FVIsZeroCodePoint(Ord('A')));
  Assert.IsFalse(FVIsZeroCodePoint($00E4));     // ä
  Assert.IsFalse(FVIsZeroCodePoint($4E2D));     // CJK 中 — wide, not zero
end;

procedure TUnicodeWidthTests.CellWidth_Default_IsOne;
begin
  Assert.AreEqual(1, FVCellWidth(Ord('A')));
  Assert.AreEqual(1, FVCellWidth($00E4));
end;

procedure TUnicodeWidthTests.CellWidth_Wide_IsTwo;
begin
  Assert.AreEqual(2, FVCellWidth($4E2D));
  Assert.AreEqual(2, FVCellWidth($1F600));
end;

procedure TUnicodeWidthTests.CellWidth_Zero_IsZero;
begin
  Assert.AreEqual(0, FVCellWidth($0301));
  Assert.AreEqual(0, FVCellWidth($200B));
end;

initialization
  TDUnitX.RegisterTestFixture(TUnicodeWidthTests);

end.
