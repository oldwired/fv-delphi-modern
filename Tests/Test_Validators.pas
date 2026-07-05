{*********************************************************}
{                                                         }
{       Free Vision - Validator Tests                     }
{                                                         }
{       Covers TFilterValidator (char-set membership),    }
{       TRangeValidator (numeric bounds), and             }
{       TStringLookupValidator (list membership).         }
{                                                         }
{       Note: TPXPictureValidator.Picture in this port    }
{       has only stub behavior — its mask handling is     }
{       intentionally not exercised here.                  }
{                                                         }
{*********************************************************}

unit Test_Validators;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TValidatorTests = class
  public
    [Test] procedure Filter_AcceptsDigitsOnly;
    [Test] procedure Filter_RejectsLetter;
    [Test] procedure Filter_AcceptsEmpty;
    [Test] procedure Range_AcceptsWithinBounds;
    [Test] procedure Range_RejectsBelowMin;
    [Test] procedure Range_RejectsAboveMax;
    [Test] procedure Range_RejectsNonNumeric;
    [Test] procedure StringLookup_AcceptsKnown;
    [Test] procedure StringLookup_RejectsUnknown;
    [Test] procedure StringLookup_EmptyListRejectsAll;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  Validate;

procedure TValidatorTests.Filter_AcceptsDigitsOnly;
var V: TFilterValidator;
begin
  V := TFilterValidator.Create(['0'..'9']);
  try
    Assert.IsTrue(V.IsValid('12345'));
  finally
    V.Free;
  end;
end;

procedure TValidatorTests.Filter_RejectsLetter;
var V: TFilterValidator;
begin
  V := TFilterValidator.Create(['0'..'9']);
  try
    Assert.IsFalse(V.IsValid('12a45'));
  finally
    V.Free;
  end;
end;

procedure TValidatorTests.Filter_AcceptsEmpty;
var V: TFilterValidator;
begin
  V := TFilterValidator.Create(['0'..'9']);
  try
    Assert.IsTrue(V.IsValid(''));
  finally
    V.Free;
  end;
end;

procedure TValidatorTests.Range_AcceptsWithinBounds;
var V: TRangeValidator;
begin
  V := TRangeValidator.Create(10, 20);
  try
    Assert.IsTrue(V.IsValid('10'));
    Assert.IsTrue(V.IsValid('15'));
    Assert.IsTrue(V.IsValid('20'));
  finally
    V.Free;
  end;
end;

procedure TValidatorTests.Range_RejectsBelowMin;
var V: TRangeValidator;
begin
  V := TRangeValidator.Create(10, 20);
  try
    Assert.IsFalse(V.IsValid('9'));
    Assert.IsFalse(V.IsValid('-5'));
  finally
    V.Free;
  end;
end;

procedure TValidatorTests.Range_RejectsAboveMax;
var V: TRangeValidator;
begin
  V := TRangeValidator.Create(10, 20);
  try
    Assert.IsFalse(V.IsValid('21'));
    Assert.IsFalse(V.IsValid('100'));
  finally
    V.Free;
  end;
end;

procedure TValidatorTests.Range_RejectsNonNumeric;
var V: TRangeValidator;
begin
  V := TRangeValidator.Create(0, 100);
  try
    Assert.IsFalse(V.IsValid('1a'));   // 'a' isn't in the accepted char set
  finally
    V.Free;
  end;
end;

procedure TValidatorTests.StringLookup_AcceptsKnown;
var
  V: TStringLookupValidator;
  L: TStringList;
begin
  L := TStringList.Create;
  L.Add('alpha');
  L.Add('beta');
  V := TStringLookupValidator.Create(L);   // takes ownership of L
  try
    Assert.IsTrue(V.IsValid('alpha'));
    Assert.IsTrue(V.IsValid('beta'));
  finally
    V.Free;
  end;
end;

procedure TValidatorTests.StringLookup_RejectsUnknown;
var
  V: TStringLookupValidator;
  L: TStringList;
begin
  L := TStringList.Create;
  L.Add('alpha');
  V := TStringLookupValidator.Create(L);
  try
    Assert.IsFalse(V.IsValid('gamma'));
    Assert.IsFalse(V.IsValid(''));
  finally
    V.Free;
  end;
end;

procedure TValidatorTests.StringLookup_EmptyListRejectsAll;
var
  V: TStringLookupValidator;
  L: TStringList;
begin
  L := TStringList.Create;
  V := TStringLookupValidator.Create(L);
  try
    Assert.IsFalse(V.IsValid('anything'));
  finally
    V.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TValidatorTests);

end.
