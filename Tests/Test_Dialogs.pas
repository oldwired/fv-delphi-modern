{*********************************************************}
{                                                         }
{       Free Vision - Dialog Widget Goldens               }
{                                                         }
{       Snapshots for TInputLine + buttons + cluster      }
{       widgets, hosted in a TWindow so their parent      }
{       Owner is the correct type.                         }
{                                                         }
{*********************************************************}

unit Test_Dialogs;

interface

uses
  DUnitX.TestFramework,
  GoldenHelper, ViewHarness;

type
  [TestFixture]
  TDialogGoldens = class
  private
    FSession: TGoldenSession;
    FHarness: TViewHarness;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure DialogWithButton;
    [Test] procedure DialogWithInputLine;
  end;

implementation

uses
  System.SysUtils,
  Drivers, Views, App, Dialogs;

procedure TDialogGoldens.Setup;
begin
  FSession := TGoldenSession.Create(60, 15);
  FSession.StartScreen;
  FHarness := TViewHarness.CreateHarness(60, 15);
end;

procedure TDialogGoldens.TearDown;
begin
  FHarness.Free;
  FSession.Free;
end;

procedure TDialogGoldens.DialogWithButton;
var
  R: TRect;
  Dlg: TDialog;
  Btn: TButton;
begin
  R.A.X := 5; R.A.Y := 2; R.B.X := 50; R.B.Y := 12;
  Dlg := TDialog.Create(R, 'Confirm');
  R.A.X := 5; R.A.Y := 7; R.B.X := 15; R.B.Y := 9;
  Btn := TButton.Create(R, '~O~K', 10, bfDefault);
  Dlg.Insert(Btn);
  FHarness.Adopt(Dlg);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('dialogs\dialog_button');
end;

procedure TDialogGoldens.DialogWithInputLine;
var
  R: TRect;
  Dlg: TDialog;
  Line: TInputLine;
begin
  R.A.X := 2; R.A.Y := 1; R.B.X := 50; R.B.Y := 11;
  Dlg := TDialog.Create(R, 'Name');
  R.A.X := 2; R.A.Y := 3; R.B.X := 32; R.B.Y := 4;
  Line := TInputLine.Create(R, 30);
  Dlg.Insert(Line);
  FHarness.Adopt(Dlg);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('dialogs\dialog_inputline');
end;

initialization
  TDUnitX.RegisterTestFixture(TDialogGoldens);

end.
