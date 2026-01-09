{*******************************************************}
{       Free Vision - Uptime View Gadget               }
{       Displays system uptime                          }
{*******************************************************}

unit UptimeView;

interface

uses
  Winapi.Windows,
  FVConsts, Objects, Drivers, Views;

type
  TUptimeDisplayMode = (udCompact, udFull);

  TUptimeView = class(TView)
  private
    FMode: TUptimeDisplayMode;
    FLastTicks: UInt64;
    FRefreshInterval: Word;  { Refresh interval in seconds }
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    constructor CreateCompact(var Bounds: TRect); virtual;
    function FormatUptime: string; virtual;
    procedure Update; virtual;
    procedure Draw; override;
    property Mode: TUptimeDisplayMode read FMode write FMode;
    property RefreshInterval: Word read FRefreshInterval write FRefreshInterval;
  end;

const
  idUptimeView = 320;

implementation

uses
  System.SysUtils;

{ TUptimeView }

constructor TUptimeView.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FMode := udFull;
  FRefreshInterval := 1;
  FLastTicks := 0;
end;

constructor TUptimeView.CreateCompact(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FMode := udCompact;
  FRefreshInterval := 1;
  FLastTicks := 0;
end;

function TUptimeView.FormatUptime: string;
var
  Ticks: UInt64;
  TotalSecs, Days, Hours, Mins, Secs: UInt64;
begin
  Ticks := GetTickCount64;
  TotalSecs := Ticks div 1000;

  Days := TotalSecs div 86400;
  Hours := (TotalSecs mod 86400) div 3600;
  Mins := (TotalSecs mod 3600) div 60;
  Secs := TotalSecs mod 60;

  if FMode = udCompact then begin
    { Compact: "5d 12:34:56" or just "12:34:56" if < 1 day }
    if Days > 0 then
      Result := Format('%dd %.2d:%.2d:%.2d', [Days, Hours, Mins, Secs])
    else
      Result := Format('%.2d:%.2d:%.2d', [Hours, Mins, Secs]);
  end
  else begin
    { Full: "5 days 12:34:56" or "12:34:56" }
    if Days > 0 then begin
      if Days = 1 then
        Result := Format('1 day %.2d:%.2d:%.2d', [Hours, Mins, Secs])
      else
        Result := Format('%d days %.2d:%.2d:%.2d', [Days, Hours, Mins, Secs]);
    end
    else
      Result := Format('%.2d:%.2d:%.2d', [Hours, Mins, Secs]);
  end;
end;

procedure TUptimeView.Update;
var
  CurrentTicks: UInt64;
begin
  CurrentTicks := GetTickCount64;
  { Check if refresh interval has passed (convert to ms) }
  if (CurrentTicks - FLastTicks) >= (UInt64(FRefreshInterval) * 1000) then begin
    FLastTicks := CurrentTicks;
    DrawView;
  end;
end;

procedure TUptimeView.Draw;
var
  B: TDrawBuffer;
  S: string;
  C: Byte;
begin
  C := GetColor(2);
  S := FormatUptime;
  { Right-align within available width }
  while Length(S) < Size.X do
    S := ' ' + S;
  DrawChar(B, 0, ' ', C, Size.X);
  DrawStr(B, 0, S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

end.
