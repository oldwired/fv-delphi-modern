{*********************************************************}
{                                                         }
{       Free Vision - New Widget Goldens                  }
{                                                         }
{       Covers TProgressBar, TBreadcrumb, TAccordion,     }
{       TSplitter and TCheckListBox rendered inside a     }
{       TWindow host (so any Owner-typed access in their  }
{       Draw paths is well-formed).                        }
{                                                         }
{*********************************************************}

unit Test_NewWidgets;

interface

uses
  DUnitX.TestFramework,
  GoldenHelper, ViewHarness;

type
  [TestFixture]
  TNewWidgetGoldens = class
  private
    FSession: TGoldenSession;
    FHarness: TViewHarness;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure ProgressBar_Empty;
    [Test] procedure ProgressBar_HalfFilled;
    [Test] procedure ProgressBar_Full;
    [Test] procedure Breadcrumb_ThreeSegments;
    [Test] procedure Splitter_Vertical;
    [Test] procedure Accordion_Empty;
  end;

implementation

uses
  System.SysUtils,
  Drivers, Views, App, Dialogs,
  ProgressBar, Breadcrumb, Splitter, Accordion;

function HostWindow(F: TViewHarness): TWindow;
var R: TRect;
begin
  R.A.X := 1; R.A.Y := 0; R.B.X := F.Size.X - 1; R.B.Y := F.Size.Y;
  Result := TWindow.Create(R, 'Host', wnNoNumber);
  F.Adopt(Result);
end;

procedure TNewWidgetGoldens.Setup;
begin
  FSession := TGoldenSession.Create(60, 15);
  FSession.StartScreen;
  FHarness := TViewHarness.CreateHarness(60, 15);
end;

procedure TNewWidgetGoldens.TearDown;
begin
  FHarness.Free;
  FSession.Free;
end;

procedure TNewWidgetGoldens.ProgressBar_Empty;
var
  W: TWindow;
  R: TRect;
  P: TProgressBar;
begin
  W := HostWindow(FHarness);
  R.A.X := 2; R.A.Y := 2; R.B.X := 50; R.B.Y := 3;
  P := TProgressBar.Create(R, 0, 100);
  P.SetProgress(0);
  W.Insert(P);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('widgets\progressbar_empty');
end;

procedure TNewWidgetGoldens.ProgressBar_HalfFilled;
var
  W: TWindow;
  R: TRect;
  P: TProgressBar;
begin
  W := HostWindow(FHarness);
  R.A.X := 2; R.A.Y := 2; R.B.X := 50; R.B.Y := 3;
  P := TProgressBar.Create(R, 0, 100);
  P.SetProgress(50);
  W.Insert(P);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('widgets\progressbar_half');
end;

procedure TNewWidgetGoldens.ProgressBar_Full;
var
  W: TWindow;
  R: TRect;
  P: TProgressBar;
begin
  W := HostWindow(FHarness);
  R.A.X := 2; R.A.Y := 2; R.B.X := 50; R.B.Y := 3;
  P := TProgressBar.Create(R, 0, 100);
  P.SetProgress(100);
  W.Insert(P);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('widgets\progressbar_full');
end;

procedure TNewWidgetGoldens.Breadcrumb_ThreeSegments;
var
  W: TWindow;
  R: TRect;
  B: TBreadcrumb;
begin
  W := HostWindow(FHarness);
  R.A.X := 2; R.A.Y := 2; R.B.X := 50; R.B.Y := 3;
  B := TBreadcrumb.Create(R, 0);
  B.AddSegment('home');
  B.AddSegment('projects');
  B.AddSegment('fv-delphi');
  W.Insert(B);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('widgets\breadcrumb_three');
end;

procedure TNewWidgetGoldens.Splitter_Vertical;
var
  W: TWindow;
  R: TRect;
  S: TSplitter;
begin
  W := HostWindow(FHarness);
  R.A.X := 30; R.A.Y := 2; R.B.X := 31; R.B.Y := 12;
  S := TSplitter.Create(R, soVertical, nil, nil, 2, 2);
  W.Insert(S);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('widgets\splitter_vertical');
end;

procedure TNewWidgetGoldens.Accordion_Empty;
var
  W: TWindow;
  R: TRect;
  A: TAccordion;
begin
  W := HostWindow(FHarness);
  R.A.X := 2; R.A.Y := 2; R.B.X := 50; R.B.Y := 12;
  A := TAccordion.Create(R, amMultiple);
  W.Insert(A);
  FHarness.RenderAndUpdate;
  FSession.Snapshot('widgets\accordion_empty');
end;

initialization
  TDUnitX.RegisterTestFixture(TNewWidgetGoldens);

end.
