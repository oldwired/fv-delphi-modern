{*********************************************************}
{                                                         }
{       Free Vision - Fuzzy Finder Scoring Tests          }
{                                                         }
{       Exercises the TFuzzyFinder.FuzzyScore class       }
{       function (pure: no Screen/Application setup).     }
{                                                         }
{*********************************************************}

unit Test_FuzzyFinder;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TFuzzyFinderTests = class
  public
    [Test] procedure EmptyPattern_ReturnsOne;
    [Test] procedure EmptyText_ReturnsNegative;
    [Test] procedure NoMatch_ReturnsNegative;
    [Test] procedure ExactMatch_BeatsScattered;
    [Test] procedure ConsecutiveMatch_BeatsScattered;
    [Test] procedure CaseInsensitive;
    [Test] procedure CaseExactGetsBonus;
    [Test] procedure WordStart_GetsBonus;
  end;

implementation

uses
  FuzzyFinder;

procedure TFuzzyFinderTests.EmptyPattern_ReturnsOne;
begin
  Assert.AreEqual(1, TFuzzyFinder.FuzzyScore('', 'anything'));
end;

procedure TFuzzyFinderTests.EmptyText_ReturnsNegative;
begin
  Assert.IsTrue(TFuzzyFinder.FuzzyScore('foo', '') < 0);
end;

procedure TFuzzyFinderTests.NoMatch_ReturnsNegative;
begin
  Assert.IsTrue(TFuzzyFinder.FuzzyScore('xyz', 'abcdef') < 0);
end;

procedure TFuzzyFinderTests.ExactMatch_BeatsScattered;
begin
  Assert.IsTrue(
    TFuzzyFinder.FuzzyScore('abc', 'abc') >
    TFuzzyFinder.FuzzyScore('abc', 'a__b__c'),
    'consecutive "abc" should score higher than scattered');
end;

procedure TFuzzyFinderTests.ConsecutiveMatch_BeatsScattered;
begin
  Assert.IsTrue(
    TFuzzyFinder.FuzzyScore('abc', 'xabcx') >
    TFuzzyFinder.FuzzyScore('abc', 'xaxbxc'));
end;

procedure TFuzzyFinderTests.CaseInsensitive;
begin
  Assert.IsTrue(TFuzzyFinder.FuzzyScore('abc', 'ABC') > 0);
  Assert.IsTrue(TFuzzyFinder.FuzzyScore('ABC', 'abc') > 0);
end;

procedure TFuzzyFinderTests.CaseExactGetsBonus;
begin
  { Both match by codepoint, but exact case earns +5 per char. }
  Assert.IsTrue(
    TFuzzyFinder.FuzzyScore('abc', 'abc') >
    TFuzzyFinder.FuzzyScore('abc', 'ABC'));
end;

procedure TFuzzyFinderTests.WordStart_GetsBonus;
begin
  { Word-start match (after '_' or '.') gets +20 per first char. }
  Assert.IsTrue(
    TFuzzyFinder.FuzzyScore('Fo', 'New_Foo') >
    TFuzzyFinder.FuzzyScore('Fo', 'NewFoo'));
end;

initialization
  TDUnitX.RegisterTestFixture(TFuzzyFinderTests);

end.
