{*********************************************************}
{                                                         }
{       Free Vision - Spinner Animation Tests             }
{                                                         }
{       Demonstrates the fake-clock pattern: with         }
{       FVClock.AdvanceFakeClock we drive a TSpinnerView  }
{       through its frame cycle deterministically, with   }
{       no real time passing.                              }
{                                                         }
{*********************************************************}

unit Test_Spinners;

interface

uses
  DUnitX.TestFramework,
  GoldenHelper;

type
  [TestFixture]
  TSpinnerAnimationTests = class
  private
    FSession: TGoldenSession;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Spinner_DoesNotAdvanceBeforeInterval;
    [Test] procedure Spinner_AdvancesOnIntervalBoundary;
    [Test] procedure Spinner_WrapsAtFrameCount;
    [Test] procedure Spinner_InactiveDoesNotAdvance;
  end;

implementation

uses
  System.SysUtils, System.Rtti,
  Drivers, FVClock, SpinnerView;

procedure TSpinnerAnimationTests.Setup;
begin
  FSession := TGoldenSession.Create(40, 10);
  FSession.StartScreen;
  FSession.ResetClock(0);
end;

procedure TSpinnerAnimationTests.TearDown;
begin
  FSession.Free;
end;

function FrameIndexOf(Sp: TSpinnerView): Integer;
var
  Ctx: TRttiContext;
  Fld: TRttiField;
begin
  Ctx := TRttiContext.Create;
  try
    Fld := Ctx.GetType(Sp.ClassType).GetField('FFrameIdx');
    Result := Fld.GetValue(Sp).AsInteger;
  finally
    Ctx.Free;
  end;
end;

function MakeSpinner: TSpinnerView;
var
  R: TRect;
begin
  R.A.X := 0; R.A.Y := 0; R.B.X := 20; R.B.Y := 1;
  Result := TSpinnerView.Create(R, skLine, '');
  Result.IntervalMs := 100;
end;

procedure TSpinnerAnimationTests.Spinner_DoesNotAdvanceBeforeInterval;
var Sp: TSpinnerView;
begin
  Sp := MakeSpinner;
  try
    Assert.AreEqual(0, FrameIndexOf(Sp));
    FSession.AdvanceClock(50);
    Sp.Update;
    Assert.AreEqual(0, FrameIndexOf(Sp), 'should not advance before interval');
  finally
    Sp.Free;
  end;
end;

procedure TSpinnerAnimationTests.Spinner_AdvancesOnIntervalBoundary;
var Sp: TSpinnerView;
begin
  Sp := MakeSpinner;
  try
    FSession.AdvanceClock(100);
    Sp.Update;
    Assert.AreEqual(1, FrameIndexOf(Sp));
    FSession.AdvanceClock(100);
    Sp.Update;
    Assert.AreEqual(2, FrameIndexOf(Sp));
  finally
    Sp.Free;
  end;
end;

procedure TSpinnerAnimationTests.Spinner_WrapsAtFrameCount;
var
  Sp: TSpinnerView;
  I: Integer;
begin
  Sp := MakeSpinner;
  try
    { skLine has 4 frames; after 4 ticks the index wraps to 0. }
    for I := 1 to 4 do begin
      FSession.AdvanceClock(100);
      Sp.Update;
    end;
    Assert.AreEqual(0, FrameIndexOf(Sp), 'should wrap to 0 after a full cycle');
  finally
    Sp.Free;
  end;
end;

procedure TSpinnerAnimationTests.Spinner_InactiveDoesNotAdvance;
var Sp: TSpinnerView;
begin
  Sp := MakeSpinner;
  try
    Sp.Active := False;
    FSession.AdvanceClock(500);
    Sp.Update;
    Assert.AreEqual(0, FrameIndexOf(Sp));
  finally
    Sp.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TSpinnerAnimationTests);

end.
