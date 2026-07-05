{*********************************************************}
{                                                         }
{       Free Vision - Terminal Capability Profile Tests   }
{                                                         }
{       Covers ForceDeterministicProfile: that it pins    }
{       the documented fixed values (NoColors, not        }
{       interactive, IsCI, no Sixel, no hyperlink) and is }
{       idempotent. NOTE: the host env-detection paths    }
{       (NO_COLOR, CLICOLOR_FORCE, CI sniffing, the VT     }
{       probe) are NOT exercised here — those would need   }
{       env mutation + a profile reset and remain a gap.  }
{                                                         }
{*********************************************************}

unit Test_Profile;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TProfileTests = class
  public
    [Test] procedure ForceDeterministicProfile_NoColors;
    [Test] procedure ForceDeterministicProfile_NotInteractive;
    [Test] procedure ForceDeterministicProfile_Idempotent;
    [Test] procedure ForceDeterministicProfile_DisablesSixel;
    [Test] procedure ForceDeterministicProfile_DisablesHyperlink;
  end;

implementation

uses
  FVProfile;

procedure TProfileTests.ForceDeterministicProfile_NoColors;
var P: TFVProfile;
begin
  ForceDeterministicProfile;
  P := GetFVProfile;
  Assert.IsTrue(P.ColorSystem = fvcsNoColors);
end;

procedure TProfileTests.ForceDeterministicProfile_NotInteractive;
var P: TFVProfile;
begin
  ForceDeterministicProfile;
  P := GetFVProfile;
  Assert.IsFalse(P.Interactive);
  Assert.IsTrue(P.IsCI);
end;

procedure TProfileTests.ForceDeterministicProfile_Idempotent;
var A, B: TFVProfile;
begin
  ForceDeterministicProfile;
  A := GetFVProfile;
  ForceDeterministicProfile;
  B := GetFVProfile;
  Assert.AreEqual(Ord(A.ColorSystem), Ord(B.ColorSystem));
  Assert.AreEqual(A.AnsiSupported, B.AnsiSupported);
  Assert.AreEqual(A.IsCI, B.IsCI);
end;

procedure TProfileTests.ForceDeterministicProfile_DisablesSixel;
var P: TFVProfile;
begin
  ForceDeterministicProfile;
  P := GetFVProfile;
  Assert.IsFalse(P.SixelSupport);
end;

procedure TProfileTests.ForceDeterministicProfile_DisablesHyperlink;
var P: TFVProfile;
begin
  ForceDeterministicProfile;
  P := GetFVProfile;
  Assert.IsFalse(P.HyperlinkSupport);
end;

initialization
  TDUnitX.RegisterTestFixture(TProfileTests);

end.
