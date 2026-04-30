{*********************************************************}
{                                                         }
{       Free Vision - Multi-Task Progress (TTaskProgress) }
{                                                         }
{       Inspired by VSoft.AnsiConsole's Live.Progress     }
{       (https://github.com/VSoftTechnologies/            }
{        VSoft.AnsiConsole) - MIT licensed                }
{       Copyright (c) 2026 Vincent Parrett                }
{                                                         }
{       Adapted for Free Vision under MIT - retained-mode }
{       TView descendant. Does not replace TProgressBar;  }
{       use this when you need multiple concurrent tasks  }
{       with ETA and a spinner column.                    }
{                                                         }
{*********************************************************}

unit TaskProgress;

{$R-}

interface

uses
  System.Generics.Collections,
  Winapi.Windows,
  FVCommon, Objects, Drivers, Views, FVConsts, FVBoxChars;

const
  CTaskProgress = #16#19#17;

type
  TProgressTask = record
    Caption:     string;
    Current:     Int64;
    Max:         Int64;
    StartTickMs: UInt64;
    LastTickMs:  UInt64;
    SpinnerIdx:  Integer;
  end;

  TTaskProgress = class(TView)
  private
    FTasks: TList<TProgressTask>;
    function FormatETA(const Task: TProgressTask): string;
    function ComputePercent(const Task: TProgressTask): Integer;
    procedure DrawTaskRow(Y: Integer; const Task: TProgressTask);
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    destructor Destroy; override;

    function AddTask(const ACaption: string; AMax: Int64): Integer;
    procedure UpdateTask(Index: Integer; ACurrent: Int64);
    procedure IncrementTask(Index: Integer; ADelta: Int64);
    procedure RemoveTask(Index: Integer);
    function TaskCount: Integer;
    function IsFinished(Index: Integer): Boolean;

    function GetPalette: PPalette; override;
    procedure Draw; override;
  end;

implementation

uses
  System.SysUtils;

const
  SpinnerFrames: array[0..9] of string = (
    #$280B, #$2819, #$2839, #$2838, #$283C,
    #$2834, #$2826, #$2827, #$2807, #$280F
  );

constructor TTaskProgress.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FTasks := TList<TProgressTask>.Create;
end;

destructor TTaskProgress.Destroy;
begin
  FTasks.Free;
  inherited Destroy;
end;

function TTaskProgress.AddTask(const ACaption: string; AMax: Int64): Integer;
var
  T: TProgressTask;
begin
  T.Caption     := ACaption;
  T.Current     := 0;
  T.Max         := AMax;
  T.StartTickMs := GetTickCount64;
  T.LastTickMs  := T.StartTickMs;
  T.SpinnerIdx  := 0;
  Result := FTasks.Add(T);
  DrawView;
end;

procedure TTaskProgress.UpdateTask(Index: Integer; ACurrent: Int64);
var
  T: TProgressTask;
  Now: UInt64;
begin
  if (Index < 0) or (Index >= FTasks.Count) then Exit;
  T := FTasks[Index];
  Now := GetTickCount64;
  T.Current := ACurrent;
  if T.Current < 0 then T.Current := 0;
  if T.Current > T.Max then T.Current := T.Max;
  if Now - T.LastTickMs >= 80 then
  begin
    T.LastTickMs := Now;
    Inc(T.SpinnerIdx);
    if T.SpinnerIdx >= Length(SpinnerFrames) then T.SpinnerIdx := 0;
  end;
  FTasks[Index] := T;
  DrawView;
end;

procedure TTaskProgress.IncrementTask(Index: Integer; ADelta: Int64);
begin
  if (Index < 0) or (Index >= FTasks.Count) then Exit;
  UpdateTask(Index, FTasks[Index].Current + ADelta);
end;

procedure TTaskProgress.RemoveTask(Index: Integer);
begin
  if (Index < 0) or (Index >= FTasks.Count) then Exit;
  FTasks.Delete(Index);
  DrawView;
end;

function TTaskProgress.TaskCount: Integer;
begin
  Result := FTasks.Count;
end;

function TTaskProgress.IsFinished(Index: Integer): Boolean;
begin
  if (Index < 0) or (Index >= FTasks.Count) then
    Result := False
  else
    Result := FTasks[Index].Current >= FTasks[Index].Max;
end;

function TTaskProgress.ComputePercent(const Task: TProgressTask): Integer;
begin
  if Task.Max <= 0 then
    Result := 0
  else
  begin
    Result := Integer((Task.Current * 100) div Task.Max);
    if Result < 0 then Result := 0;
    if Result > 100 then Result := 100;
  end;
end;

function TTaskProgress.FormatETA(const Task: TProgressTask): string;
var
  Elapsed, Remaining: UInt64;
  Mins, Secs: Cardinal;
begin
  if (Task.Current <= 0) or (Task.Current >= Task.Max) then
    Exit('--:--');
  Elapsed := GetTickCount64 - Task.StartTickMs;
  if Elapsed < 100 then Exit('--:--');
  { Remaining ms = Elapsed * (Max - Current) / Current }
  Remaining := Elapsed * UInt64(Task.Max - Task.Current) div UInt64(Task.Current);
  Mins := Cardinal(Remaining div 60000);
  Secs := Cardinal((Remaining div 1000) mod 60);
  if Mins > 99 then
    Result := '99:59'
  else
    Result := Format('%.2d:%.2d', [Mins, Secs]);
end;

procedure TTaskProgress.DrawTaskRow(Y: Integer; const Task: TProgressTask);
var
  B:           TDrawBuffer;
  CapColor, BarFilled, BarEmpty, TextColor: Byte;
  CapWidth, BarStart, BarWidth, FilledLen: Integer;
  Percent:     Integer;
  PercentStr:  string;
  ETAStr:      string;
  Spinner:     string;
  X, I:        Integer;
begin
  CapColor  := GetColor(3);
  BarFilled := GetColor(2);
  BarEmpty  := GetColor(1);
  TextColor := GetColor(3);

  DrawChar(B, 0, ' ', CapColor, Size.X);

  { Layout: [spinner] CAPTION ............ [BAR] NN% ETA mm:ss }
  Spinner := SpinnerFrames[Task.SpinnerIdx mod Length(SpinnerFrames)];
  DrawStr(B, 0, Spinner, BarFilled);

  CapWidth := 18;
  if CapWidth > (Size.X div 3) then CapWidth := Size.X div 3;
  if CapWidth < 6 then CapWidth := 6;
  DrawStr(B, 2, Copy(Task.Caption, 1, CapWidth), CapColor);

  Percent := ComputePercent(Task);
  PercentStr := Format('%3d%%', [Percent]);
  ETAStr := 'ETA ' + FormatETA(Task);

  { Reserve right side for percent + eta }
  BarStart := 2 + CapWidth + 1;
  BarWidth := Size.X - BarStart - Length(PercentStr) - 1 - Length(ETAStr) - 1;
  if BarWidth < 4 then BarWidth := 4;

  FilledLen := 0;
  if Task.Max > 0 then
    FilledLen := Integer((Task.Current * BarWidth) div Task.Max);
  if FilledLen < 0 then FilledLen := 0;
  if FilledLen > BarWidth then FilledLen := BarWidth;

  for I := 0 to BarWidth - 1 do
  begin
    X := BarStart + I;
    if X >= Size.X then Break;
    if I < FilledLen then
    begin
      B[X].Ch := BlockFull;
      B[X].Attr := BarFilled;
    end
    else
    begin
      B[X].Ch := BlockLight;
      B[X].Attr := BarEmpty;
    end;
  end;

  DrawStr(B, BarStart + BarWidth + 1, PercentStr, TextColor);
  DrawStr(B, BarStart + BarWidth + 1 + Length(PercentStr) + 1, ETAStr, TextColor);

  WriteLine(0, Y, Size.X, 1, B);
end;

procedure TTaskProgress.Draw;
var
  Y, I: Integer;
  Empty: TDrawBuffer;
begin
  for I := 0 to FTasks.Count - 1 do
  begin
    if I >= Size.Y then Break;
    DrawTaskRow(I, FTasks[I]);
  end;
  { Clear remaining rows }
  for Y := FTasks.Count to Size.Y - 1 do
  begin
    DrawChar(Empty, 0, ' ', GetColor(1), Size.X);
    WriteLine(0, Y, Size.X, 1, Empty);
  end;
end;

function TTaskProgress.GetPalette: PPalette;
const
  P: string[Length(CTaskProgress)] = CTaskProgress;
begin
  GetPalette := PPalette(@P);
end;

end.
