{*******************************************************}
{       Free Vision Tooltip Widget                      }
{       Focus-based hint display                        }
{*******************************************************}

unit Tooltip;

{$R-}

interface

uses
  Winapi.Windows, System.SysUtils,
  FVCommon, Drivers, Views, FVConsts, FVBoxChars;

type
  TTooltip = class(TView)
  private
    FMessage: string;
    FTargetView: TView;
    FCreatedTick: Cardinal;
    class var FInstance: TTooltip;
    class var FLastCheckedFocus: TView;
    class var FTimeoutMs: Cardinal;
    procedure PositionNear(AView: TView);
  public
    constructor Create(const AMessage: string; ATarget: TView); reintroduce;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    class procedure ShowForView(AView: TView);
    class procedure DismissAll;
    class procedure CheckFocusChange(ANewFocused: TView);
    class procedure PollFocus;
  end;

implementation

uses
  App, FVScreen;

{ TTooltip }

constructor TTooltip.Create(const AMessage: string; ATarget: TView);
var
  R: TRect;
  W, H: Integer;
begin
  FMessage := AMessage;
  FTargetView := ATarget;
  FCreatedTick := GetTickCount;
  if FTimeoutMs = 0 then FTimeoutMs := 3000;

  W := Length(FMessage) + 4;
  if W > 60 then W := 60;
  H := 3;
  R.Assign(0, 0, W, H);
  inherited Create(R);
  Options := Options and not ofSelectable;
  EventMask := 0;  { Don't receive any events }
end;

procedure TTooltip.PositionNear(AView: TView);
var
  ViewOrigin: TPoint;
  R: TRect;
  P: TView;
begin
  { Get screen coordinates of the target view }
  ViewOrigin.X := 0;
  ViewOrigin.Y := 0;
  P := AView;
  while P <> nil do begin
    Inc(ViewOrigin.X, P.Origin.X);
    Inc(ViewOrigin.Y, P.Origin.Y);
    P := P.Owner;
  end;

  { Position below the view }
  R.A.X := ViewOrigin.X;
  R.A.Y := ViewOrigin.Y + AView.Size.Y;
  R.B.X := R.A.X + Size.X;
  R.B.Y := R.A.Y + Size.Y;

  { Clip to screen }
  if R.B.X > ScreenWidth then
    R.Move(ScreenWidth - R.B.X, 0);
  if R.A.X < 0 then R.Move(-R.A.X, 0);

  { If below doesn't fit, try above }
  if R.B.Y > ScreenHeight then begin
    R.A.Y := ViewOrigin.Y - Size.Y;
    R.B.Y := ViewOrigin.Y;
  end;
  if R.A.Y < 0 then begin
    R.A.Y := 0;
    R.B.Y := Size.Y;
  end;

  MoveTo(R.A.X, R.A.Y);
end;

procedure TTooltip.Draw;
var
  B: TDrawBuffer;
  C: Byte;
  S: string;
begin
  C := $70;  { Black on light gray - tooltip colors }

  { Top border }
  DrawChar(B, 0, BoxTopLeft, C, 1);
  DrawChar(B, 1, BoxHoriz, C, Size.X - 2);
  DrawChar(B, Size.X - 1, BoxTopRight, C, 1);
  WriteLine(0, 0, Size.X, 1, B);

  { Content line }
  DrawChar(B, 0, BoxVert, C, 1);
  DrawChar(B, 1, ' ', C, Size.X - 2);
  S := Copy(FMessage, 1, Size.X - 4);
  DrawStr(B, 2, S, C);
  DrawChar(B, Size.X - 1, BoxVert, C, 1);
  WriteLine(0, 1, Size.X, 1, B);

  { Bottom border }
  DrawChar(B, 0, BoxBottomLeft, C, 1);
  DrawChar(B, 1, BoxHoriz, C, Size.X - 2);
  DrawChar(B, Size.X - 1, BoxBottomRight, C, 1);
  WriteLine(0, 2, Size.X, 1, B);
end;

procedure TTooltip.HandleEvent(var Event: TEvent);
begin
  { Never consume any events — pass everything through }
end;

class procedure TTooltip.ShowForView(AView: TView);
var
  Tip: TTooltip;
  OwnerGroup: TGroup;
begin
  DismissAll;
  if (AView = nil) or (AView.HintText = '') then Exit;

  { Find the owning group (dialog/window) to insert the tooltip into }
  OwnerGroup := AView.Owner;
  if OwnerGroup = nil then Exit;

  Tip := TTooltip.Create(AView.HintText, AView);
  { Position relative to the owner group }
  Tip.MoveTo(AView.Origin.X, AView.Origin.Y + AView.Size.Y);
  { Clip to owner bounds }
  if Tip.Origin.X + Tip.Size.X > OwnerGroup.Size.X then
    Tip.MoveTo(OwnerGroup.Size.X - Tip.Size.X, Tip.Origin.Y);
  if Tip.Origin.Y + Tip.Size.Y > OwnerGroup.Size.Y then
    Tip.MoveTo(Tip.Origin.X, AView.Origin.Y - Tip.Size.Y);

  OwnerGroup.Insert(Tip);
  FInstance := Tip;
end;

class procedure TTooltip.DismissAll;
begin
  if FInstance <> nil then begin
    if FInstance.Owner <> nil then
      FInstance.Owner.Delete(FInstance);
    FInstance.Free;
    FInstance := nil;
  end;
end;

class procedure TTooltip.CheckFocusChange(ANewFocused: TView);
begin
  if (ANewFocused <> nil) and (ANewFocused.HintText <> '') then
    ShowForView(ANewFocused)
  else
    DismissAll;
end;

class procedure TTooltip.PollFocus;
var
  V: TView;
begin
  if App.Application = nil then Exit;
  if App.Desktop = nil then Exit;

  { Auto-dismiss after timeout }
  if (FInstance <> nil) and (GetTickCount - FInstance.FCreatedTick > FTimeoutMs) then
    DismissAll;

  { Walk from Desktop.Current down to find deepest focused view }
  V := App.Desktop.Current;
  if V <> nil then begin
    while (V is TGroup) and (TGroup(V).Current <> nil) do
      V := TGroup(V).Current;
  end;

  if V <> FLastCheckedFocus then begin
    FLastCheckedFocus := V;
    CheckFocusChange(V);
  end;
end;

end.
