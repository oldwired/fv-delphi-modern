{*********************************************************}
{                                                         }
{       Free Vision - List Navigation Event-Flow Tests    }
{                                                         }
{       Drives TStringListBox by directly calling its     }
{       HandleEvent with synthetic key events, then       }
{       asserting on the Focused / TopItem fields.        }
{                                                         }
{*********************************************************}

unit Test_ListNav;

interface

uses
  DUnitX.TestFramework,
  GoldenHelper, ViewHarness;

type
  [TestFixture]
  TListNavTests = class
  private
    FSession: TGoldenSession;
    FHarness: TViewHarness;
    function MakeList(ItemCount: Integer): TObject;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure ArrowDown_AdvancesFocused;
    [Test] procedure ArrowUp_AtTopClamps;
    [Test] procedure ArrowDown_PastEnd_Clamps;
    [Test] procedure PageDown_JumpsByPage;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  Drivers, Views, Dialogs;

procedure TListNavTests.Setup;
begin
  FSession := TGoldenSession.Create(40, 10);
  FSession.StartScreen;
  FHarness := TViewHarness.CreateHarness(40, 10);
end;

procedure TListNavTests.TearDown;
begin
  FHarness.Free;
  FSession.Free;
end;

function TListNavTests.MakeList(ItemCount: Integer): TObject;
var
  R: TRect;
  LB: TStringListBox;
  S: TStringList;
  I: Integer;
begin
  R.A.X := 0; R.A.Y := 0; R.B.X := 30; R.B.Y := 5;   { 5 visible rows }
  LB := TStringListBox.Create(R, 1, nil);
  S := TStringList.Create;
  for I := 0 to ItemCount - 1 do
    S.Add(Format('item %d', [I]));
  LB.NewList(S);
  FHarness.Adopt(LB);
  Result := LB;
end;

procedure TListNavTests.ArrowDown_AdvancesFocused;
var
  LB: TStringListBox;
  E: TEvent;
begin
  LB := TStringListBox(MakeList(20));
  Assert.AreEqual(0, LB.Focused);
  E.What := evKeyDown; E.KeyCode := kbDown; E.KeyShift := 0;
  LB.HandleEvent(E);
  Assert.AreEqual(1, LB.Focused);
  E.What := evKeyDown; E.KeyCode := kbDown;
  LB.HandleEvent(E);
  Assert.AreEqual(2, LB.Focused);
end;

procedure TListNavTests.ArrowUp_AtTopClamps;
var
  LB: TStringListBox;
  E: TEvent;
begin
  LB := TStringListBox(MakeList(20));
  E.What := evKeyDown; E.KeyCode := kbUp;
  LB.HandleEvent(E);
  Assert.AreEqual(0, LB.Focused, 'arrow up at top should not go negative');
end;

procedure TListNavTests.ArrowDown_PastEnd_Clamps;
var
  LB: TStringListBox;
  E: TEvent;
  I: Integer;
begin
  LB := TStringListBox(MakeList(5));
  for I := 1 to 10 do begin
    E.What := evKeyDown; E.KeyCode := kbDown;
    LB.HandleEvent(E);
  end;
  Assert.AreEqual(4, LB.Focused, 'last item index is Range-1');
end;

procedure TListNavTests.PageDown_JumpsByPage;
var
  LB: TStringListBox;
  E: TEvent;
begin
  LB := TStringListBox(MakeList(30));
  E.What := evKeyDown; E.KeyCode := kbPgDn;
  LB.HandleEvent(E);
  Assert.IsTrue(LB.Focused >= 5, 'PageDown should move focused by visible page');
end;

initialization
  TDUnitX.RegisterTestFixture(TListNavTests);

end.
