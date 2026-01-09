{*******************************************************}
{       Free Vision - CPU Core View                    }
{       Per-core CPU usage display widget              }
{*******************************************************}

unit CPUCoreView;

interface

uses
  Winapi.Windows,
  FVConsts, Objects, Drivers, Views;

type
  TCPUCoreView = class(TView)
  private
    FCoreIndex: Integer;       { Which core to display (-1 = total) }
    FLastUpdate: UInt64;
    FRefreshInterval: Word;
    FCPUPercent: Integer;
    FWarningThreshold: Byte;
    FCriticalThreshold: Byte;
    FShowLabel: Boolean;
    FLabelWidth: Integer;
    { Previous times for delta calculation }
    FPrevIdleTime: UInt64;
    FPrevKernelTime: UInt64;
    FPrevUserTime: UInt64;
    FFirstSample: Boolean;
    FCoreCount: Integer;
  public
    constructor Create(var Bounds: TRect; ACoreIndex: Integer = -1); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    class function GetCoreCount: Integer;
    property CoreIndex: Integer read FCoreIndex write FCoreIndex;
    property RefreshInterval: Word read FRefreshInterval write FRefreshInterval;
    property WarningThreshold: Byte read FWarningThreshold write FWarningThreshold;
    property CriticalThreshold: Byte read FCriticalThreshold write FCriticalThreshold;
    property ShowLabel: Boolean read FShowLabel write FShowLabel;
    property LabelWidth: Integer read FLabelWidth write FLabelWidth;
    property CPUPercent: Integer read FCPUPercent;
    property CoreCount: Integer read FCoreCount;
  end;

const
  idCPUCoreView = 336;

implementation

uses
  System.SysUtils;

type
  { SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION structure }
  TSYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = record
    IdleTime: Int64;
    KernelTime: Int64;
    UserTime: Int64;
    Reserved1: array[0..1] of Int64;
    Reserved2: ULONG;
  end;
  PSYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = ^TSYSTEM_PROCESSOR_PERFORMANCE_INFORMATION;

const
  SystemProcessorPerformanceInformation = 8;

var
  NtQuerySystemInformation: function(
    SystemInformationClass: ULONG;
    SystemInformation: Pointer;
    SystemInformationLength: ULONG;
    ReturnLength: PULONG
  ): LONG; stdcall = nil;
  NtDllHandle: THandle = 0;
  CachedCoreCount: Integer = 0;

function LoadNtDll: Boolean;
begin
  if NtDllHandle <> 0 then begin
    Result := Assigned(NtQuerySystemInformation);
    Exit;
  end;

  NtDllHandle := GetModuleHandle('ntdll.dll');
  if NtDllHandle <> 0 then
    @NtQuerySystemInformation := GetProcAddress(NtDllHandle, 'NtQuerySystemInformation');

  Result := Assigned(NtQuerySystemInformation);
end;

function GetProcessorCount: Integer;
var
  SysInfo: TSystemInfo;
begin
  if CachedCoreCount > 0 then begin
    Result := CachedCoreCount;
    Exit;
  end;
  GetSystemInfo(SysInfo);
  CachedCoreCount := SysInfo.dwNumberOfProcessors;
  Result := CachedCoreCount;
end;

{ TCPUCoreView }

constructor TCPUCoreView.Create(var Bounds: TRect; ACoreIndex: Integer);
begin
  inherited Create(Bounds);
  FCoreIndex := ACoreIndex;
  FRefreshInterval := 1;
  FLastUpdate := 0;
  FCPUPercent := 0;
  FWarningThreshold := 50;
  FCriticalThreshold := 80;
  FShowLabel := True;
  FLabelWidth := 6;  { "CPU 0 " or "Total " }
  FPrevIdleTime := 0;
  FPrevKernelTime := 0;
  FPrevUserTime := 0;
  FFirstSample := True;
  FCoreCount := GetProcessorCount;
  LoadNtDll;
  Update;
end;

class function TCPUCoreView.GetCoreCount: Integer;
begin
  Result := GetProcessorCount;
end;

procedure TCPUCoreView.Update;
var
  CurrentTick: UInt64;
  PerfInfo: array of TSYSTEM_PROCESSOR_PERFORMANCE_INFORMATION;
  ReturnLength: ULONG;
  Status: LONG;
  CurrIdle, CurrKernel, CurrUser: UInt64;
  IdleDelta, KernelDelta, UserDelta, TotalDelta: UInt64;
  I: Integer;
begin
  if not Assigned(NtQuerySystemInformation) then Exit;

  CurrentTick := GetTickCount64;
  if (CurrentTick - FLastUpdate) >= (UInt64(FRefreshInterval) * 1000) then begin
    FLastUpdate := CurrentTick;

    SetLength(PerfInfo, FCoreCount);
    Status := NtQuerySystemInformation(
      SystemProcessorPerformanceInformation,
      @PerfInfo[0],
      FCoreCount * SizeOf(TSYSTEM_PROCESSOR_PERFORMANCE_INFORMATION),
      @ReturnLength
    );

    if Status = 0 then begin
      if (FCoreIndex >= 0) and (FCoreIndex < FCoreCount) then begin
        { Single core }
        CurrIdle := PerfInfo[FCoreIndex].IdleTime;
        CurrKernel := PerfInfo[FCoreIndex].KernelTime;
        CurrUser := PerfInfo[FCoreIndex].UserTime;
      end
      else begin
        { Total (all cores summed) }
        CurrIdle := 0;
        CurrKernel := 0;
        CurrUser := 0;
        for I := 0 to FCoreCount - 1 do begin
          CurrIdle := CurrIdle + UInt64(PerfInfo[I].IdleTime);
          CurrKernel := CurrKernel + UInt64(PerfInfo[I].KernelTime);
          CurrUser := CurrUser + UInt64(PerfInfo[I].UserTime);
        end;
      end;

      if FFirstSample then begin
        FFirstSample := False;
        FPrevIdleTime := CurrIdle;
        FPrevKernelTime := CurrKernel;
        FPrevUserTime := CurrUser;
        FCPUPercent := 0;
      end
      else begin
        IdleDelta := CurrIdle - FPrevIdleTime;
        KernelDelta := CurrKernel - FPrevKernelTime;
        UserDelta := CurrUser - FPrevUserTime;
        TotalDelta := KernelDelta + UserDelta;

        if TotalDelta > 0 then
          FCPUPercent := 100 - Integer((IdleDelta * 100) div TotalDelta)
        else
          FCPUPercent := 0;

        if FCPUPercent < 0 then FCPUPercent := 0;
        if FCPUPercent > 100 then FCPUPercent := 100;

        FPrevIdleTime := CurrIdle;
        FPrevKernelTime := CurrKernel;
        FPrevUserTime := CurrUser;
      end;
    end;

    DrawView;
  end;
end;

procedure TCPUCoreView.Draw;
var
  B: TDrawBuffer;
  Color, BarColor: Byte;
  S, LabelStr: string;
  BarWidth, FilledWidth, I, X: Integer;
begin
  Color := GetColor(1);

  { Determine bar color based on usage }
  if FCPUPercent >= FCriticalThreshold then
    BarColor := GetColor(4)  { Red/Critical }
  else if FCPUPercent >= FWarningThreshold then
    BarColor := GetColor(3)  { Yellow/Warning }
  else
    BarColor := GetColor(2); { Green/Normal }

  DrawChar(B, 0, ' ', Color, Size.X);
  X := 0;

  { Draw label if enabled }
  if FShowLabel then begin
    if FCoreIndex < 0 then
      LabelStr := 'Total'
    else
      LabelStr := Format('CPU%d', [FCoreIndex]);
    while Length(LabelStr) < FLabelWidth - 1 do
      LabelStr := LabelStr + ' ';
    LabelStr := LabelStr + ' ';
    DrawStr(B, X, LabelStr, Color);
    X := FLabelWidth;
  end;

  { Calculate bar dimensions }
  BarWidth := Size.X - X - 7;  { "[]" (2) + " 100%" (5) }
  if BarWidth < 3 then BarWidth := 3;

  FilledWidth := (FCPUPercent * BarWidth) div 100;

  DrawChar(B, X, '[', Color, 1);
  Inc(X);
  for I := 0 to BarWidth - 1 do begin
    if I < FilledWidth then
      DrawChar(B, X + I, #$2588, BarColor, 1)  { █ Full block }
    else
      DrawChar(B, X + I, #$2591, Color, 1);    { ░ Light shade }
  end;
  DrawChar(B, X + BarWidth, ']', Color, 1);

  S := Format(' %d%%', [FCPUPercent]);
  DrawStr(B, X + BarWidth + 1, S, Color);

  WriteLine(0, 0, Size.X, 1, B);
end;

end.
