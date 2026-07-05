{*********************************************************}
{                                                         }
{       Free Vision - Core View Rendering Goldens         }
{                                                         }
{       Snapshots covering TBackground, TFrame, TWindow,  }
{       TStaticText, TLabel, TButton, TInputLine,         }
{       TScrollBar. Each test inserts a single widget     }
{       into a TViewHarness, renders, and snapshots.       }
{                                                         }
{*********************************************************}

unit Test_Views;

interface

uses
  DUnitX.TestFramework,
  GoldenHelper, ViewHarness;

type
  [TestFixture]
  TViewGoldens = class
  private
    FSession: TGoldenSession;
    FHarness: TViewHarness;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Background_PatternFillsRect;
    [Test] procedure Window_TitleAndFrame;
    [Test] procedure StaticText_RendersText;
    [Test] procedure Button_RendersTitle;
    [Test] procedure InputLine_RendersEmpty;
    [Test] procedure ScrollBar_Vertical;
  end;

implementation

uses
  System.SysUtils,
  Drivers, Views, App, Dialogs;

procedure TViewGoldens.Setup;
begin
  FSession := TGoldenSession.Create(40, 12);
  FSession.StartScreen;
  FHarness := TViewHarness.CreateHarness(40, 12);
end;

procedure TViewGoldens.TearDown;
begin
  FHarness.Free;
  FSession.Free;
end;

procedure TViewGoldens.Background_PatternFillsRect;
var
  R: TRect;
  B: TBackground;
begin
  R.A.X := 0; R.A.Y := 0; R.B.X := 40; R.B.Y := 12;
  B := TBackground.Create(R, '.');
  FHarness.Adopt(B);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('views\background_dot');
end;

procedure TViewGoldens.Window_TitleAndFrame;
var
  R: TRect;
  W: TWindow;
begin
  R.A.X := 2; R.A.Y := 1; R.B.X := 36; R.B.Y := 10;
  W := TWindow.Create(R, 'Hello', wnNoNumber);
  FHarness.Adopt(W);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('views\window_basic');
end;

procedure TViewGoldens.StaticText_RendersText;
var
  R: TRect;
  T: TStaticText;
begin
  R.A.X := 1; R.A.Y := 1; R.B.X := 20; R.B.Y := 2;
  T := TStaticText.Create(R, 'Hello, world!');
  FHarness.Adopt(T);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('views\statictext_hello');
end;

procedure TViewGoldens.Button_RendersTitle;
var
  R: TRect;
  B: TButton;
begin
  R.A.X := 2; R.A.Y := 3; R.B.X := 12; R.B.Y := 5;
  B := TButton.Create(R, '~O~K', 10, bfDefault);
  FHarness.Adopt(B);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('views\button_ok');
end;

procedure TViewGoldens.InputLine_RendersEmpty;
var
  R: TRect;
  L: TInputLine;
begin
  R.A.X := 2; R.A.Y := 5; R.B.X := 22; R.B.Y := 6;
  L := TInputLine.Create(R, 20);
  FHarness.Adopt(L);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('views\inputline_empty');
end;

procedure TViewGoldens.ScrollBar_Vertical;
var
  R: TRect;
  SB: TScrollBar;
begin
  R.A.X := 38; R.A.Y := 1; R.B.X := 39; R.B.Y := 11;
  SB := TScrollBar.Create(R);
  SB.SetParams(50, 0, 100, 1, 1);   { mid-range scroll position }
  FHarness.Adopt(SB);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('views\scrollbar_vmid');
end;

initialization
  TDUnitX.RegisterTestFixture(TViewGoldens);

end.
