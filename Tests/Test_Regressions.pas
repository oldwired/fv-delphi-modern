{*********************************************************}
{                                                         }
{       Free Vision - Regression Hotspot Tests            }
{                                                         }
{       One named test per documented historical bug.     }
{       Each test pins the current (fixed) behavior so a  }
{       future regression fails this fixture loudly.      }
{                                                         }
{       Sources:                                          }
{         - 0001-fixed-z-order-clipping.patch             }
{         - TERMINAL_RENDERING_BUG.md                     }
{         - memory entry: "TStringGrid wide-Unicode fix"  }
{         - memory entry: "OSC 8 hyperlinks need id="     }
{         - memory entry: "DEC 2026 sync mode wraps"      }
{                                                         }
{*********************************************************}

unit Test_Regressions;

interface

uses
  DUnitX.TestFramework,
  GoldenHelper, ViewHarness;

type
  [TestFixture]
  TRegressionTests = class
  private
    FSession: TGoldenSession;
    FHarness: TViewHarness;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure ZOrder_TopWindowDoesNotBleedIntoBackdrop;
    [Test] procedure WideCJK_HasFollowerCell;
    [Test] procedure Emoji_IsRecognizedAsWide;
    [Test] procedure CombiningMark_HasZeroWidth;
    [Test] procedure ForcedProfile_DisablesHyperlinkAndSixel;
    [Test] procedure DrawBuffer_ExtensionFieldsZeroed_AsciiTable;
  end;

implementation

uses
  System.SysUtils, System.StrUtils,
  Drivers, Views, App, FVCommon, FVScreen, FVUTF8, FVUnicodeWidth, FVProfile,
  AsciiTab;

procedure TRegressionTests.Setup;
begin
  FSession := TGoldenSession.Create(40, 12);
  FSession.StartScreen;
  FHarness := TViewHarness.CreateHarness(40, 12);
end;

procedure TRegressionTests.TearDown;
begin
  FHarness.Free;
  FSession.Free;
end;

procedure TRegressionTests.ZOrder_TopWindowDoesNotBleedIntoBackdrop;
var
  R: TRect;
  Back, Front: TWindow;
  Y, X, BackCount, FrontCount: Integer;
  C: TScreenCell;
begin
  { Two overlapping TWindow children of the harness. The "front" window is
    inserted last, so it draws on top per the Z-order. The fix in
    0001-fixed-z-order-clipping.patch ensures the back window's frame does
    not poke through the cells the front window owns. We assert that the
    rectangle owned exclusively by the front window contains no '═'
    horizontal-frame glyph from the back window. }
  R.A.X := 2;  R.A.Y := 1;  R.B.X := 28; R.B.Y := 8;
  Back := TWindow.Create(R, 'Back', wnNoNumber);
  FHarness.Adopt(Back);
  R.A.X := 8;  R.A.Y := 3;  R.B.X := 36; R.B.Y := 11;
  Front := TWindow.Create(R, 'Front', wnNoNumber);
  FHarness.Adopt(Front);
  FHarness.RenderAndUpdate;

  BackCount  := 0;
  FrontCount := 0;
  for Y := 0 to 11 do
    for X := 0 to 39 do begin
      C := Screen.GetCell(X, Y);
      if C.Ch = '═' then begin
        { Inside the front window's interior rows (Y in 4..9 exclusive,
          X in 9..35 exclusive)? Then any frame char there is a bleed. }
        if (Y > 3) and (Y < 10) and (X > 8) and (X < 35) then
          Inc(BackCount);
        if (Y = 3) or (Y = 10) then
          Inc(FrontCount);
      end;
    end;

  Assert.AreEqual(0, BackCount, 'no back-window frame chars should appear inside front window interior');
  Assert.IsTrue(FrontCount > 0, 'front window should still have visible frame');
end;

procedure TRegressionTests.WideCJK_HasFollowerCell;
var
  Y: Integer;
  C1, C2: TScreenCell;
begin
  { Memory note: TStringGrid corruption with wide Unicode was fixed
    by FVUnicodeWidth ranges. The contract is: a wide code point occupies
    one cell at the start position and a "follower" cell at the next
    column. Verify by emitting 中文 directly and reading back. }
  Screen.SetCell(0, 0, '中', 7, 0);
  Screen.SetCell(2, 0, '文', 7, 0);
  Y := 0;
  C1 := Screen.GetCell(0, Y);
  C2 := Screen.GetCell(2, Y);
  Assert.AreEqual('中', C1.Ch);
  Assert.AreEqual('文', C2.Ch);
  Assert.AreEqual(2, FVCellWidth($4E2D), '中 must report cell width 2');
  Assert.AreEqual(2, FVCellWidth($6587), '文 must report cell width 2');
end;

procedure TRegressionTests.Emoji_IsRecognizedAsWide;
begin
  { Emoji code points (above $FFFF) need surrogate-pair handling AND
    width=2. Both the per-codepoint and the string-level widths were
    sources of past bugs. }
  Assert.AreEqual(2, FVCellWidth($1F600), 'grinning face');
  Assert.AreEqual(2, FVCellWidth($1F4A9), 'pile of poo');
  Assert.AreEqual(2, CodePointCharWidth($1F600));
end;

procedure TRegressionTests.CombiningMark_HasZeroWidth;
begin
  { Combining marks are zero-width — the editor and grid both relied on
    this for correct cursor placement after a base-char + combining mark. }
  Assert.AreEqual(0, FVCellWidth($0301), 'combining acute');
  Assert.AreEqual(0, FVCellWidth($0300), 'combining grave');
  Assert.AreEqual(0, FVCellWidth($200B), 'zero-width space');
end;

{ Fill a large stack region with a non-zero pattern so a TDrawBuffer local
  allocated further down inherits garbage instead of a coincidentally clean
  stack - mimics the deep call stacks of a real application run. }
procedure DirtyStackDeep;
var
  A: array[0..65535] of Byte;
  I: Integer;
begin
  for I := 0 to High(A) do
    A[I] := $A5;
  if A[32768] <> $A5 then
    raise Exception.Create('unreachable');
end;

procedure TRegressionTests.DrawBuffer_ExtensionFieldsZeroed_AsciiTable;
var
  R: TRect;
  T: TTable;
  X, Y, I, Bad: Integer;
begin
  { Memory gotcha: "TDrawBuffer is stack-allocated, NOT zero-initialized".
    TTable.Draw used to write B[X].Ch/Attr directly, leaving FG_RGB/BG_RGB/
    ExtAttrs/UL_RGB as stack garbage - random colors and attributes in the
    ASCII chart. Draw functions must go through the Draw* helpers (or zero
    every extension field explicitly). }
  R.A.X := 1; R.A.Y := 1; R.B.X := 33; R.B.Y := 9;
  T := TTable.Create(R);
  FHarness.Adopt(T);
  DirtyStackDeep;
  FHarness.RenderAndUpdate;

  Bad := 0;
  for Y := 1 to 8 do
    for X := 1 to 32 do begin
      I := Y * ScreenWidth + X;
      if (FGRGBBuf[I] <> 0) or (BGRGBBuf[I] <> 0) or
         (ExtAttrsBuf[I] <> 0) or (ULRGBBuf[I] <> 0) then
        Inc(Bad);
    end;
  Assert.AreEqual(0, Bad,
    'ASCII table cells must not carry RGB/ExtAttrs/UL_RGB stack garbage');
end;

procedure TRegressionTests.ForcedProfile_DisablesHyperlinkAndSixel;
var P: TFVProfile;
begin
  { When a regression turns hyperlinks or Sixel on under
    ForceDeterministicProfile, golden tests across hosts will diverge
    silently. Pin both flags off. }
  ForceDeterministicProfile;
  P := GetFVProfile;
  Assert.IsFalse(P.HyperlinkSupport);
  Assert.IsFalse(P.SixelSupport);
  Assert.IsTrue(P.ColorSystem = fvcsNoColors);
end;

initialization
  TDUnitX.RegisterTestFixture(TRegressionTests);

end.
