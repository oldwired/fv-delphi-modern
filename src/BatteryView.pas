{*******************************************************}
{       Free Vision - Battery Status View              }
{       Battery level and AC power display             }
{*******************************************************}

unit BatteryView;

interface

uses
  Winapi.Windows,
  FVConsts, Objects, Drivers, Views;

type
  TBatteryStatusView = class(TView)
  private
    FLastUpdate: UInt64;
    FRefreshInterval: Word;
    FBatteryPercent: Integer;
    FACPower: Boolean;
    FCharging: Boolean;
    FHasBattery: Boolean;
    FShowACStatus: Boolean;
    FWarningThreshold: Byte;
    FCriticalThreshold: Byte;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    property RefreshInterval: Word read FRefreshInterval write FRefreshInterval;
    property ShowACStatus: Boolean read FShowACStatus write FShowACStatus;
    property WarningThreshold: Byte read FWarningThreshold write FWarningThreshold;
    property CriticalThreshold: Byte read FCriticalThreshold write FCriticalThreshold;
    property BatteryPercent: Integer read FBatteryPercent;
    property ACPower: Boolean read FACPower;
    property HasBattery: Boolean read FHasBattery;
  end;

const
  idBatteryStatusView = 334;

implementation

uses
  System.SysUtils;

{ TBatteryStatusView }

constructor TBatteryStatusView.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FRefreshInterval := 30;  { Battery changes slowly }
  FLastUpdate := 0;
  FBatteryPercent := 0;
  FACPower := False;
  FCharging := False;
  FHasBattery := False;
  FShowACStatus := True;
  FWarningThreshold := 30;
  FCriticalThreshold := 15;
  { Get initial data }
  Update;
end;

procedure TBatteryStatusView.Update;
var
  CurrentTick: UInt64;
  PowerStatus: TSystemPowerStatus;
begin
  CurrentTick := GetTickCount64;
  if (CurrentTick - FLastUpdate) >= (UInt64(FRefreshInterval) * 1000) then begin
    FLastUpdate := CurrentTick;

    if GetSystemPowerStatus(PowerStatus) then begin
      { Check if battery is present }
      { BatteryLifePercent = 255 means unknown/no battery }
      FHasBattery := (PowerStatus.BatteryLifePercent <> 255) and
                     (PowerStatus.BatteryFlag <> 128);  { 128 = No battery }

      if FHasBattery then
        FBatteryPercent := PowerStatus.BatteryLifePercent
      else
        FBatteryPercent := 0;

      { AC power status: 1 = AC, 0 = Battery, 255 = Unknown }
      FACPower := (PowerStatus.ACLineStatus = 1);

      { Charging: BatteryFlag bit 3 = Charging }
      FCharging := (PowerStatus.BatteryFlag and 8) <> 0;
    end
    else begin
      FHasBattery := False;
      FBatteryPercent := 0;
      FACPower := True;  { Assume desktop }
      FCharging := False;
    end;

    DrawView;
  end;
end;

procedure TBatteryStatusView.Draw;
var
  B: TDrawBuffer;
  Color, BarColor: Byte;
  S, StatusStr: string;
  BarWidth, FilledWidth, I, X: Integer;
begin
  Color := GetColor(1);
  DrawChar(B, 0, ' ', Color, Size.X);

  if not FHasBattery then begin
    { No battery - probably desktop }
    S := 'No Battery';
    if FShowACStatus and FACPower then
      S := S + ' (AC)';
    DrawStr(B, 0, S, Color);
    WriteLine(0, 0, Size.X, 1, B);
    Exit;
  end;

  { Determine bar color based on level }
  if FBatteryPercent <= FCriticalThreshold then
    BarColor := GetColor(4)  { Red/Critical }
  else if FBatteryPercent <= FWarningThreshold then
    BarColor := GetColor(3)  { Yellow/Warning }
  else
    BarColor := GetColor(2); { Green/Normal }

  { Build status string }
  StatusStr := '';
  if FShowACStatus then begin
    if FCharging then
      StatusStr := ' Charging'
    else if FACPower then
      StatusStr := ' AC'
    else
      StatusStr := ' Batt';
  end;

  { Format: Batt: 85% [████████░░] AC }
  DrawStr(B, 0, 'Batt: ', Color);
  X := 6;

  S := Format('%3d%% ', [FBatteryPercent]);
  DrawStr(B, X, S, BarColor);
  X := X + Length(S);

  { Calculate bar dimensions }
  BarWidth := Size.X - X - 2 - Length(StatusStr);  { "[]" (2) + status }
  if BarWidth < 5 then BarWidth := 5;

  FilledWidth := (FBatteryPercent * BarWidth) div 100;

  DrawChar(B, X, '[', Color, 1);
  Inc(X);
  for I := 0 to BarWidth - 1 do begin
    if I < FilledWidth then
      DrawChar(B, X + I, #$2588, BarColor, 1)  { █ Full block }
    else
      DrawChar(B, X + I, #$2591, Color, 1);    { ░ Light shade }
  end;
  DrawChar(B, X + BarWidth, ']', Color, 1);

  if StatusStr <> '' then
    DrawStr(B, X + BarWidth + 1, StatusStr, Color);

  WriteLine(0, 0, Size.X, 1, B);
end;

end.
