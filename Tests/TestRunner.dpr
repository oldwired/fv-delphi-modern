program FVTests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  {$ENDIF }
  DUnitX.TestFramework,

  { FV core (subset needed by tests) }
  FVInterfaces in '..\src\FVInterfaces.pas',
  FVSerialization in '..\src\FVSerialization.pas',
  Objects in '..\src\Objects.pas',
  FVCommon in '..\src\FVCommon.pas',
  FVBoxChars in '..\src\FVBoxChars.pas',
  FVUnicodeWidth in '..\src\FVUnicodeWidth.pas',
  FVProfile in '..\src\FVProfile.pas',
  FVClock in '..\src\FVClock.pas',
  FVHeadless in '..\src\FVHeadless.pas',
  FVUTF8 in '..\src\FVUTF8.pas',
  FVScreen in '..\src\FVScreen.pas',
  Drivers in '..\src\Drivers.pas',

  { Test infrastructure }
  GridSerializer in 'GridSerializer.pas',
  GoldenHelper in 'GoldenHelper.pas',
  ViewHarness in 'ViewHarness.pas',

  { FV widgets exercised by tests }
  fvconsts in '..\src\fvconsts.pas',
  HistList in '..\src\histlist.pas',
  Views in '..\src\Views.pas',
  Menus in '..\src\Menus.pas',
  Validate in '..\src\Validate.pas',
  App in '..\src\app.pas',
  Dialogs in '..\src\Dialogs.pas',
  SpinnerView in '..\src\SpinnerView.pas',
  FuzzyFinder in '..\src\FuzzyFinder.pas',
  SyntaxHighlight in '..\src\SyntaxHighlight.pas',
  Marquee in '..\src\Marquee.pas',
  Notification in '..\src\Notification.pas',
  BlinkIndicator in '..\src\BlinkIndicator.pas',
  TaskProgress in '..\src\TaskProgress.pas',

  { Test fixtures }
  Test_Smoke in 'Test_Smoke.pas',
  Test_Spinners in 'Test_Spinners.pas',
  Test_UTF8 in 'Test_UTF8.pas',
  Test_UnicodeWidth in 'Test_UnicodeWidth.pas',
  Test_Serialization in 'Test_Serialization.pas',
  Test_Profile in 'Test_Profile.pas',
  Test_Validators in 'Test_Validators.pas',
  Test_FuzzyFinder in 'Test_FuzzyFinder.pas',
  Test_SyntaxHighlight in 'Test_SyntaxHighlight.pas',
  Test_GridSerializer in 'Test_GridSerializer.pas',
  Test_Animations in 'Test_Animations.pas',
  Test_Views in 'Test_Views.pas',
  Test_Dialogs in 'Test_Dialogs.pas',
  ProgressBar in '..\src\ProgressBar.pas',
  Breadcrumb in '..\src\Breadcrumb.pas',
  Splitter in '..\src\Splitter.pas',
  Accordion in '..\src\Accordion.pas',
  Test_NewWidgets in 'Test_NewWidgets.pas',
  Test_Regressions in 'Test_Regressions.pas',
  Test_ListNav in 'Test_ListNav.pas';

{$IFNDEF TESTINSIGHT}
var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnitLogger: ITestLogger;
  ExitCodeVal: Integer;
{$ENDIF}

begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;

    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then begin
      Logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      Runner.AddLogger(Logger);
    end;
    NUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NUnitLogger);

    Results := Runner.Execute;
    if not Results.AllPassed then
      ExitCodeVal := 1
    else
      ExitCodeVal := 0;

    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;

    ExitCode := ExitCodeVal;
  except
    on E: Exception do begin
      System.Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 2;
    end;
  end;
{$ENDIF}
end.
