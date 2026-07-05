{*********************************************************}
{                                                         }
{       Free Vision - Animation / Time-Based Tests        }
{                                                         }
{       Drives FVClock-aware widgets (Marquee,            }
{       Notification, BlinkIndicator, TaskProgress)       }
{       through fake-time deltas. RTTI is used to read    }
{       private fields where there's no public accessor.  }
{                                                         }
{*********************************************************}

unit Test_Animations;

interface

uses
  DUnitX.TestFramework,
  GoldenHelper;

type
  [TestFixture]
  TAnimationTests = class
  private
    FSession: TGoldenSession;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Marquee_DoesNotMoveBeforeInterval;
    [Test] procedure Marquee_AdvancesAfterInterval;
    [Test] procedure Marquee_PausedStaysPut;

    [Test] procedure Notification_NotDismissedBeforeTimeout;
    [Test] procedure Notification_DismissedAfterTimeout;

    [Test] procedure Blink_TogglesAcrossInterval;
    [Test] procedure Blink_DoesNotToggleEarly;

    [Test] procedure TaskProgress_AddTaskBumpsCount;
    [Test] procedure TaskProgress_UpdateClampsToMax;
    [Test] procedure TaskProgress_IsFinishedReportsCompletion;
  end;

implementation

uses
  System.SysUtils, System.Rtti,
  Drivers, FVClock,
  Marquee, Notification, BlinkIndicator, TaskProgress;

function GetIntField(Inst: TObject; const FieldName: string): Integer;
var
  Ctx: TRttiContext;
  F: TRttiField;
begin
  Ctx := TRttiContext.Create;
  try
    F := Ctx.GetType(Inst.ClassType).GetField(FieldName);
    Result := F.GetValue(Inst).AsInteger;
  finally
    Ctx.Free;
  end;
end;

function GetBoolField(Inst: TObject; const FieldName: string): Boolean;
var
  Ctx: TRttiContext;
  F: TRttiField;
begin
  Ctx := TRttiContext.Create;
  try
    F := Ctx.GetType(Inst.ClassType).GetField(FieldName);
    Result := F.GetValue(Inst).AsBoolean;
  finally
    Ctx.Free;
  end;
end;

procedure TAnimationTests.Setup;
begin
  FSession := TGoldenSession.Create(40, 10);
  FSession.StartScreen;
  FSession.ResetClock(0);
end;

procedure TAnimationTests.TearDown;
begin
  FSession.Free;
end;

{ ---------- Marquee ---------- }

function MakeMarquee: TMarquee;
var R: TRect;
begin
  R.A.X := 0; R.A.Y := 0; R.B.X := 20; R.B.Y := 1;
  Result := TMarquee.Create(R, 'HELLO');
  Result.ScrollSpeed := 100;
end;

procedure TAnimationTests.Marquee_DoesNotMoveBeforeInterval;
var M: TMarquee;
begin
  M := MakeMarquee;
  try
    Assert.AreEqual(0, GetIntField(M, 'FPosition'));
    FSession.AdvanceClock(50);
    M.Update;
    Assert.AreEqual(0, GetIntField(M, 'FPosition'));
  finally
    M.Free;
  end;
end;

procedure TAnimationTests.Marquee_AdvancesAfterInterval;
var M: TMarquee;
begin
  M := MakeMarquee;
  try
    FSession.AdvanceClock(150);
    M.Update;
    Assert.AreNotEqual(0, GetIntField(M, 'FPosition'));
  finally
    M.Free;
  end;
end;

procedure TAnimationTests.Marquee_PausedStaysPut;
var M: TMarquee;
begin
  M := MakeMarquee;
  try
    { Set paused via RTTI since there's no public Pause/Resume helper visible from here }
    { TMarquee exposes Paused read-only; the implementation likely has Pause/Resume — check }
    { Fall back: set FPaused via RTTI }
    var Ctx := TRttiContext.Create;
    try
      var F := Ctx.GetType(M.ClassType).GetField('FPaused');
      F.SetValue(M, True);
    finally
      Ctx.Free;
    end;
    FSession.AdvanceClock(500);
    M.Update;
    Assert.AreEqual(0, GetIntField(M, 'FPosition'));
  finally
    M.Free;
  end;
end;

{ ---------- Notification ---------- }

function MakeNotification(TimeoutMs: Cardinal): TNotification;
begin
  Result := TNotification.Create('hello', ntInfo, TimeoutMs, npTopRight);
end;

procedure TAnimationTests.Notification_NotDismissedBeforeTimeout;
var N: TNotification;
begin
  N := MakeNotification(5000);
  try
    FSession.AdvanceClock(1000);
    N.Update;
    Assert.IsFalse(N.Dismissed);
  finally
    N.Free;
  end;
end;

procedure TAnimationTests.Notification_DismissedAfterTimeout;
var N: TNotification;
begin
  N := MakeNotification(2000);
  try
    FSession.AdvanceClock(2500);
    N.Update;
    Assert.IsTrue(N.Dismissed);
  finally
    N.Free;
  end;
end;

{ ---------- BlinkIndicator ---------- }

function MakeBlink: TBlinkIndicator;
var R: TRect;
begin
  R.A.X := 0; R.A.Y := 0; R.B.X := 5; R.B.Y := 1;
  Result := TBlinkIndicator.Create(R, '');
  Result.BlinkInterval := 200;
  { Force into bsBlinking state by calling StartBlinking if it exists,
    or set FState manually. Simplest: rely on default + Update. }
end;

procedure TAnimationTests.Blink_TogglesAcrossInterval;
var
  B: TBlinkIndicator;
  Before, After: Boolean;
begin
  B := MakeBlink;
  try
    B.Blink;  { enters bsBlinking and stamps FLastToggle from clock }
    FSession.AdvanceClock(50);
    B.Update;
    Before := GetBoolField(B, 'FBlinkOn');
    FSession.AdvanceClock(250);
    B.Update;
    After := GetBoolField(B, 'FBlinkOn');
    Assert.AreNotEqual(Before, After);
  finally
    B.Free;
  end;
end;

procedure TAnimationTests.Blink_DoesNotToggleEarly;
var
  B: TBlinkIndicator;
  Before, After: Boolean;
begin
  B := MakeBlink;
  try
    B.Blink;
    B.Update;
    Before := GetBoolField(B, 'FBlinkOn');
    FSession.AdvanceClock(50);
    B.Update;
    After := GetBoolField(B, 'FBlinkOn');
    Assert.AreEqual(Before, After);
  finally
    B.Free;
  end;
end;

{ ---------- TaskProgress ---------- }

function MakeTaskProgress: TTaskProgress;
var R: TRect;
begin
  R.A.X := 0; R.A.Y := 0; R.B.X := 40; R.B.Y := 5;
  Result := TTaskProgress.Create(R);
end;

procedure TAnimationTests.TaskProgress_AddTaskBumpsCount;
var TP: TTaskProgress;
begin
  TP := MakeTaskProgress;
  try
    Assert.AreEqual(0, TP.TaskCount);
    TP.AddTask('build', 100);
    TP.AddTask('link',  50);
    Assert.AreEqual(2, TP.TaskCount);
  finally
    TP.Free;
  end;
end;

procedure TAnimationTests.TaskProgress_UpdateClampsToMax;
var
  TP: TTaskProgress;
  Idx: Integer;
begin
  TP := MakeTaskProgress;
  try
    Idx := TP.AddTask('x', 100);
    TP.UpdateTask(Idx, 999);   { over max — should clamp }
    Assert.IsTrue(TP.IsFinished(Idx));
  finally
    TP.Free;
  end;
end;

procedure TAnimationTests.TaskProgress_IsFinishedReportsCompletion;
var
  TP: TTaskProgress;
  Idx: Integer;
begin
  TP := MakeTaskProgress;
  try
    Idx := TP.AddTask('x', 10);
    Assert.IsFalse(TP.IsFinished(Idx));
    TP.UpdateTask(Idx, 10);
    Assert.IsTrue(TP.IsFinished(Idx));
  finally
    TP.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAnimationTests);

end.
