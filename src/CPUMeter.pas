{*******************************************************}
{       Free Vision - CPU Meter View                   }
{       CPU usage percentage display widget            }
{*******************************************************}

unit CPUMeter;

interface

uses
  Winapi.Windows,
  FVConsts, Objects, Drivers, Views;

type
  TCPUMeterView = class(TView)
  private
    FLastUpdate: UInt64;
    FRefreshInterval: Word;
    FCPUPercent: Integer;
    FWarningThreshold: Byte;
    FCriticalThreshold: Byte;
    { Previous system times for delta calculation }
    FPrevIdleTime: UInt64;
    FPrevKernelTime: UInt64;
    FPrevUserTime: UInt64;
    FFirstSample: Boolean;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    property RefreshInterval: Word read FRefreshInterval write FRefreshInterval;
    property WarningThreshold: Byte read FWarningThreshold write FWarningThreshold;
    property CriticalThreshold: Byte read FCriticalThreshold write FCriticalThreshold;
    property CPUPercent: Integer read FCPUPercent;
  end;

const
  idCPUMeterView = 333;

implementation

uses
  System.SysUtils;

{ Helper to convert FILETIME to UInt64 }
function FileTimeToUInt64(const FT: TFileTime): UInt64;
begin
  Result := (UInt64(FT.dwHighDateTime) shl 32) or FT.dwLowDateTime;
end;

{ TCPUMeterView }

constructor TCPUMeterView.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FRefreshInterval := 1;
  FLastUpdate := 0;
  FCPUPercent := 0;
  FWarningThreshold := 50;
  FCriticalThreshold := 80;
  FPrevIdleTime := 0;
  FPrevKernelTime := 0;
  FPrevUserTime := 0;
  FFirstSample := True;
  { Get initial sample }
  Update;
end;

procedure TCPUMeterView.Update;
var
  CurrentTick: UInt64;
  IdleTime, KernelTime, UserTime: TFileTime;
  CurrIdle, CurrKernel, CurrUser: UInt64;
  IdleDelta, KernelDelta, UserDelta, TotalDelta: UInt64;
begin
  CurrentTick := GetTickCount64;
  if (CurrentTick - FLastUpdate) >= (UInt64(FRefreshInterval) * 1000) then begin
    FLastUpdate := CurrentTick;

    if GetSystemTimes(IdleTime, KernelTime, UserTime) then begin
      CurrIdle := FileTimeToUInt64(IdleTime);
      CurrKernel := FileTimeToUInt64(KernelTime);
      CurrUser := FileTimeToUInt64(UserTime);

      if FFirstSample then begin
        { First sample - just store values }
        FFirstSample := False;
        FPrevIdleTime := CurrIdle;
        FPrevKernelTime := CurrKernel;
        FPrevUserTime := CurrUser;
        FCPUPercent := 0;
      end
      else begin
        { Calculate deltas }
        IdleDelta := CurrIdle - FPrevIdleTime;
        KernelDelta := CurrKernel - FPrevKernelTime;
        UserDelta := CurrUser - FPrevUserTime;

        { Total = Kernel + User (Kernel includes Idle) }
        TotalDelta := KernelDelta + UserDelta;

        if TotalDelta > 0 then
          FCPUPercent := 100 - Integer((IdleDelta * 100) div TotalDelta)
        else
          FCPUPercent := 0;

        { Clamp to valid range }
        if FCPUPercent < 0 then FCPUPercent := 0;
        if FCPUPercent > 100 then FCPUPercent := 100;

        { Store current values for next delta }
        FPrevIdleTime := CurrIdle;
        FPrevKernelTime := CurrKernel;
        FPrevUserTime := CurrUser;
      end;
    end;

    DrawView;
  end;
end;

procedure TCPUMeterView.Draw;
var
  B: TDrawBuffer;
  Color, BarColor: Byte;
  S: string;
  BarWidth, FilledWidth, I: Integer;
begin
  Color := GetColor(1);

  { Determine bar color based on usage }
  if FCPUPercent >= FCriticalThreshold then
    BarColor := GetColor(4)  { Red/Critical }
  else if FCPUPercent >= FWarningThreshold then
    BarColor := GetColor(3)  { Yellow/Warning }
  else
    BarColor := GetColor(2); { Green/Normal }

  { Format: CPU [████████░░] 42% }
  DrawChar(B, 0, ' ', Color, Size.X);
  DrawStr(B, 0, 'CPU ', Color);

  { Calculate bar dimensions - leave room for " 100%" at end }
  BarWidth := Size.X - 11;  { "CPU " (4) + "[]" (2) + " 100%" (5) }
  if BarWidth < 5 then BarWidth := 5;

  FilledWidth := (FCPUPercent * BarWidth) div 100;

  DrawChar(B, 4, '[', Color, 1);
  for I := 0 to BarWidth - 1 do begin
    if I < FilledWidth then
      DrawChar(B, 5 + I, #$2588, BarColor, 1)  { █ Full block }
    else
      DrawChar(B, 5 + I, #$2591, Color, 1);    { ░ Light shade }
  end;
  DrawChar(B, 5 + BarWidth, ']', Color, 1);

  S := Format(' %d%%', [FCPUPercent]);
  DrawStr(B, 6 + BarWidth, S, Color);

  WriteLine(0, 0, Size.X, 1, B);
end;

end.
