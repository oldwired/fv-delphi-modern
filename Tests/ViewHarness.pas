{*********************************************************}
{                                                         }
{       Free Vision - View Test Harness                   }
{                                                         }
{       Wraps a single TView (or a small tree) inside a   }
{       parent TGroup that has sfExposed pre-set so the   }
{       child's WriteBuf calls reach the VideoBuf.        }
{                                                         }
{       Use from Tier 2 fixtures: CreateHarness ->        }
{       Adopt(...) -> RenderAndUpdate -> Snapshot.        }
{                                                         }
{*********************************************************}

unit ViewHarness;

interface

uses
  Drivers, Views;

type
  TViewHarness = class(TGroup)
  public
    constructor CreateHarness(W, H: Integer); reintroduce;
    function  Adopt(Child: TView): TView;
    procedure RenderAndUpdate;
  end;

implementation

uses
  FVScreen;

constructor TViewHarness.CreateHarness(W, H: Integer);
var
  R: TRect;
begin
  R.A.X := 0; R.A.Y := 0; R.B.X := W; R.B.Y := H;
  inherited Create(R);
  { Mark the harness exposed and active. With no Owner, sfExposed
    won't propagate via Show alone — we set it manually here, then
    Insert/Show in Adopt propagates it to children. }
  SetState(sfExposed, True);
  SetState(sfActive,  True);
end;

function TViewHarness.Adopt(Child: TView): TView;
begin
  { TGroup.Insert hides + re-shows the child; Show propagates sfExposed
    because the harness is already exposed. }
  Insert(Child);
  Result := Child;
end;

procedure TViewHarness.RenderAndUpdate;
begin
  Draw;
  { Use the global FVScreen.UpdateScreen which runs SyncVideoBufToScreen
    first to copy the legacy VideoBuf into TScreenBuffer.FCells. The
    TScreenBuffer.UpdateScreen method alone doesn't perform that copy. }
  FVScreen.UpdateScreen(True);
end;

end.
