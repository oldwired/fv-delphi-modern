{*********************************************************}
{                                                         }
{       Free Vision - Notification Component              }
{                                                         }
{       Non-modal auto-dismissing toast popup             }
{                                                         }
{*********************************************************}

unit Notification;

{$R-}

interface

uses
  Winapi.Windows,
  System.SysUtils,
  FVCommon, Drivers, Views, Dialogs, FVConsts, FVBoxChars, App;

const
  CNotification = #64#65#66#67#68#69#70#71;  { Blue dialog palette }

type
  TNotificationType = (ntInfo, ntSuccess, ntWarning, ntError);
  TNotificationPosition = (npTopRight, npBottomRight, npTopLeft, npBottomLeft);

  TNotification = class(TWindow)
  private
    FMessage: string;
    FNotifType: TNotificationType;
    FTimeoutMs: Cardinal;
    FCreatedAt: UInt64;
    FPosition: TNotificationPosition;
    FDismissed: Boolean;
    procedure PositionSelf;
    function TypeIcon: string;
  public
    constructor Create(const AMessage: string;
      AType: TNotificationType = ntInfo;
      ATimeoutMs: Cardinal = 3000;
      APosition: TNotificationPosition = npTopRight); reintroduce; virtual;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Update;
    procedure Dismiss;
    class procedure Show(const AMessage: string;
      AType: TNotificationType = ntInfo;
      ATimeoutMs: Cardinal = 3000;
      APosition: TNotificationPosition = npTopRight);
    property NotifType: TNotificationType read FNotifType;
    property Position: TNotificationPosition read FPosition;
    property Dismissed: Boolean read FDismissed;
  end;

implementation

constructor TNotification.Create(const AMessage: string;
  AType: TNotificationType; ATimeoutMs: Cardinal;
  APosition: TNotificationPosition);
var
  R: TRect;
  MsgWidth: Integer;
begin
  MsgWidth := Length(AMessage) + 6;  { icon + padding + frame }
  if MsgWidth < 20 then MsgWidth := 20;
  if MsgWidth > 50 then MsgWidth := 50;

  R.Assign(0, 0, MsgWidth, 3);
  inherited Create(R, '', wnNoNumber);

  FMessage := AMessage;
  FNotifType := AType;
  FTimeoutMs := ATimeoutMs;
  FPosition := APosition;
  FCreatedAt := GetTickCount64;
  FDismissed := False;

  Flags := 0;  { No close/zoom/move buttons - frameless toast }
  Options := Options and not ofSelectable;  { Non-selectable }
  State := State or sfVisible;
  Palette := dpBlueDialog;

  PositionSelf;
end;

function TNotification.TypeIcon: string;
begin
  case FNotifType of
    ntInfo:    Result := 'i';
    ntSuccess: Result := CheckMark;
    ntWarning: Result := '!';
    ntError:   Result := CrossMark;
  else
    Result := ' ';
  end;
end;

procedure TNotification.Draw;
var
  B: TDrawBuffer;
  Color: Byte;
  DisplayMsg: string;
begin
  inherited Draw;

  Color := GetColor(6);  { Text color from window palette }

  { Draw icon + message on line 1 (inside frame) }
  DrawChar(B, 0, ' ', Color, Size.X - 2);
  DrawStr(B, 1, TypeIcon + ' ' + FMessage, Color);

  { Truncate to fit }
  DisplayMsg := TypeIcon + ' ' + FMessage;
  if Length(DisplayMsg) > Size.X - 4 then
    DisplayMsg := Copy(DisplayMsg, 1, Size.X - 5) + Ellipsis;

  DrawChar(B, 0, ' ', Color, Size.X - 2);
  DrawStr(B, 0, DisplayMsg, Color);
  WriteLine(1, 1, Size.X - 2, 1, B);
end;

procedure TNotification.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
begin
  { Intercept mouse clicks before inherited to dismiss on click anywhere }
  if Event.What = evMouseDown then begin
    MakeLocal(Event.Where, Mouse);
    if MouseInView(Event.Where) then begin
      ClearEvent(Event);
      Dismiss;
      Exit;
    end;
  end;
  inherited HandleEvent(Event);
end;

procedure TNotification.Update;
begin
  if FDismissed then Exit;
  if GetTickCount64 - FCreatedAt >= FTimeoutMs then
    Dismiss;
end;

procedure TNotification.Dismiss;
begin
  if FDismissed then Exit;
  FDismissed := True;
  Message(Owner, evBroadcast, cmNotificationDismiss, @Self);
  if Owner <> nil then begin
    Owner.Delete(Self);
    Free;
  end;
end;

procedure TNotification.PositionSelf;
var
  DeskR: TRect;
  X, Y: Integer;
  StackOffset: Integer;
  P: TView;
begin
  if Desktop = nil then Exit;
  Desktop.GetExtent(DeskR);

  { Count existing notifications for stacking }
  StackOffset := 0;
  P := Desktop.First;
  if P <> nil then begin
    repeat
      if (P <> Self) and (P is TNotification) and
         (TNotification(P).Position = FPosition) and
         not TNotification(P).Dismissed then
        Inc(StackOffset, P.Size.Y);
      P := P.Next;
    until P = Desktop.First;
  end;

  case FPosition of
    npTopRight: begin
      X := DeskR.B.X - Size.X;
      Y := DeskR.A.Y + StackOffset;
    end;
    npBottomRight: begin
      X := DeskR.B.X - Size.X;
      Y := DeskR.B.Y - Size.Y - StackOffset;
    end;
    npTopLeft: begin
      X := DeskR.A.X;
      Y := DeskR.A.Y + StackOffset;
    end;
    npBottomLeft: begin
      X := DeskR.A.X;
      Y := DeskR.B.Y - Size.Y - StackOffset;
    end;
  else begin
    X := DeskR.B.X - Size.X;
    Y := DeskR.A.Y + StackOffset;
  end;
  end;

  MoveTo(X, Y);
end;

class procedure TNotification.Show(const AMessage: string;
  AType: TNotificationType; ATimeoutMs: Cardinal;
  APosition: TNotificationPosition);
var
  N: TNotification;
begin
  if Desktop = nil then Exit;
  N := TNotification.Create(AMessage, AType, ATimeoutMs, APosition);
  Desktop.Insert(N);
end;

end.
