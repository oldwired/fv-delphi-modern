{*********************************************************}
{                                                         }
{       Free Vision - Injectable Monotonic Clock          }
{                                                         }
{       Wraps Windows.GetTickCount64 so animated widgets  }
{       (spinners, marquees, gadgets, etc.) can be driven }
{       deterministically from unit tests via a fake      }
{       clock source.                                     }
{                                                         }
{*********************************************************}

unit FVClock;

interface

type
  TFVClockSource = reference to function: UInt64;

function  GetMonotonicMs: UInt64;

procedure SetClockOverride(const Source: TFVClockSource);
procedure ClearClockOverride;

{ Convenience helpers for tests: install (if needed) an internal fake clock
  source backed by a unit-private UInt64 counter, then bump it. }
procedure AdvanceFakeClock(DeltaMs: UInt64);
function  CurrentFakeMs: UInt64;
procedure ResetFakeClock(InitialMs: UInt64 = 0);

implementation

uses
  Winapi.Windows;

var
  GSource     : TFVClockSource = nil;
  GFakeMs     : UInt64 = 0;
  GFakeSource : TFVClockSource = nil;  { the internal fake, built once }

function GetMonotonicMs: UInt64;
begin
  if Assigned(GSource) then
    Result := GSource()
  else
    Result := Winapi.Windows.GetTickCount64;
end;

procedure SetClockOverride(const Source: TFVClockSource);
begin
  GSource := Source;
end;

procedure ClearClockOverride;
begin
  GSource := nil;
end;

procedure ArmFakeSource;
begin
  { Build the internal fake closure once, then point GSource at it. Assigning
    unconditionally (rather than tracking an "armed" flag) keeps the helpers
    self-consistent even when a custom SetClockOverride source was installed
    in between: calling a fake-clock helper is an explicit request to use the
    fake, so it always (re)installs the fake as the active source. }
  if not Assigned(GFakeSource) then
    GFakeSource :=
      function: UInt64
      begin
        Result := GFakeMs;
      end;
  GSource := GFakeSource;
end;

procedure AdvanceFakeClock(DeltaMs: UInt64);
begin
  ArmFakeSource;
  Inc(GFakeMs, DeltaMs);
end;

function CurrentFakeMs: UInt64;
begin
  Result := GFakeMs;
end;

procedure ResetFakeClock(InitialMs: UInt64 = 0);
begin
  ArmFakeSource;
  GFakeMs := InitialMs;
end;

end.
