{*********************************************************}
{                                                         }
{       Free Vision - Golden-File Smoke Tests             }
{                                                         }
{       Verifies the headless rig itself: the screen      }
{       boots without a real console, SetCell writes go   }
{       into the cell buffer, snapshots round-trip        }
{       through grid + JSONL serialization, the fake      }
{       clock is wired up, and the golden compare /       }
{       update path works.                                 }
{                                                         }
{*********************************************************}

unit Test_Smoke;

interface

uses
  DUnitX.TestFramework,
  GoldenHelper;

type
  [TestFixture]
  TSmokeTests = class
  private
    FSession: TGoldenSession;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Headless_BootsWithoutConsole;
    [Test] procedure SetCell_WritesIntoBuffer;
    [Test] procedure HelloGolden;
    [Test] procedure FakeClock_IsMonotonic;
  end;

implementation

uses
  System.SysUtils,
  FVCommon, FVScreen, FVClock;

procedure TSmokeTests.Setup;
begin
  FSession := TGoldenSession.Create(40, 10);
  FSession.StartScreen;
end;

procedure TSmokeTests.TearDown;
begin
  FSession.Free;
end;

procedure TSmokeTests.Headless_BootsWithoutConsole;
begin
  Assert.IsTrue(Screen <> nil, 'Screen should be allocated');
  Assert.IsTrue(Screen.Initialized, 'Screen should be initialized');
  Assert.AreEqual(40, Screen.Width,  'Width should match requested');
  Assert.AreEqual(10, Screen.Height, 'Height should match requested');
end;

procedure TSmokeTests.SetCell_WritesIntoBuffer;
var
  C: TScreenCell;
begin
  Screen.SetCell(3, 2, 'X', 14, 1, True);
  Screen.UpdateScreen(True);
  C := Screen.GetCell(3, 2);
  Assert.AreEqual('X', C.Ch);
  Assert.AreEqual(Byte(14), C.FG);
  Assert.AreEqual(Byte(1),  C.BG);
  Assert.IsTrue(C.Bold);
end;

procedure TSmokeTests.HelloGolden;
const
  Msg = 'HELLO';
var
  I: Integer;
begin
  FSession.Draw(
    procedure
    var
      K: Integer;
    begin
      for K := 1 to Length(Msg) do
        Screen.SetCell(K - 1, 0, Msg[K], 7, 0);
    end);
  FSession.Snapshot('smoke\hello');
  I := I; { suppress unused }
end;

procedure TSmokeTests.FakeClock_IsMonotonic;
var
  T0, T1: UInt64;
begin
  FSession.ResetClock(1000);
  T0 := FVClock.GetMonotonicMs;
  FSession.AdvanceClock(250);
  T1 := FVClock.GetMonotonicMs;
  Assert.AreEqual(UInt64(1000), T0);
  Assert.AreEqual(UInt64(1250), T1);
end;

initialization
  TDUnitX.RegisterTestFixture(TSmokeTests);

end.
