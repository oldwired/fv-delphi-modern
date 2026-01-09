{*******************************************************}
{       Free Vision - RAM Usage View                   }
{       System memory usage display widget             }
{*******************************************************}

unit RAMView;

interface

uses
  Winapi.Windows,
  FVConsts, Objects, Drivers, Views;

type
  TRAMDisplayMode = (rdBar, rdText, rdCompact);

  TRAMView = class(TView)
  private
    FDisplayMode: TRAMDisplayMode;
    FLastUpdate: UInt64;
    FRefreshInterval: Word;
    FUsedPercent: Integer;
    FUsedBytes: UInt64;
    FTotalBytes: UInt64;
    FWarningThreshold: Byte;
    FCriticalThreshold: Byte;
  public
    constructor Create(var Bounds: TRect; AMode: TRAMDisplayMode = rdBar); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    property DisplayMode: TRAMDisplayMode read FDisplayMode write FDisplayMode;
    property RefreshInterval: Word read FRefreshInterval write FRefreshInterval;
    property WarningThreshold: Byte read FWarningThreshold write FWarningThreshold;
    property CriticalThreshold: Byte read FCriticalThreshold write FCriticalThreshold;
    property UsedPercent: Integer read FUsedPercent;
    property UsedBytes: UInt64 read FUsedBytes;
    property TotalBytes: UInt64 read FTotalBytes;
  end;

const
  idRAMView = 330;

implementation

uses
  System.SysUtils;

{ TRAMView }

constructor TRAMView.Create(var Bounds: TRect; AMode: TRAMDisplayMode);
begin
  inherited Create(Bounds);
  FDisplayMode := AMode;
  FRefreshInterval := 2;
  FLastUpdate := 0;
  FUsedPercent := 0;
  FUsedBytes := 0;
  FTotalBytes := 0;
  FWarningThreshold := 70;
  FCriticalThreshold := 90;
  { Get initial data }
  Update;
end;

procedure TRAMView.Update;
var
  MemStatus: TMemoryStatusEx;
  CurrentTick: UInt64;
begin
  CurrentTick := GetTickCount64;
  if (CurrentTick - FLastUpdate) >= (UInt64(FRefreshInterval) * 1000) then begin
    FLastUpdate := CurrentTick;

    MemStatus.dwLength := SizeOf(MemStatus);
    if GlobalMemoryStatusEx(MemStatus) then begin
      FTotalBytes := MemStatus.ullTotalPhys;
      FUsedBytes := FTotalBytes - MemStatus.ullAvailPhys;
      FUsedPercent := MemStatus.dwMemoryLoad;
    end;

    DrawView;
  end;
end;

function FormatBytes(Bytes: UInt64): string;
begin
  if Bytes >= 1099511627776 then  { >= 1 TB }
    Result := Format('%.1f TB', [Bytes / 1099511627776])
  else if Bytes >= 1073741824 then  { >= 1 GB }
    Result := Format('%.1f GB', [Bytes / 1073741824])
  else if Bytes >= 1048576 then  { >= 1 MB }
    Result := Format('%.1f MB', [Bytes / 1048576])
  else
    Result := Format('%.1f KB', [Bytes / 1024]);
end;

procedure TRAMView.Draw;
var
  B: TDrawBuffer;
  Color, BarColor: Byte;
  S: string;
  BarWidth, FilledWidth, I: Integer;
begin
  Color := GetColor(1);

  { Determine bar color based on usage }
  if FUsedPercent >= FCriticalThreshold then
    BarColor := GetColor(4)  { Red/Critical }
  else if FUsedPercent >= FWarningThreshold then
    BarColor := GetColor(3)  { Yellow/Warning }
  else
    BarColor := GetColor(2); { Green/Normal }

  case FDisplayMode of
    rdBar: begin
      { Format: RAM [████████░░] 62% }
      DrawChar(B, 0, ' ', Color, Size.X);
      DrawStr(B, 0, 'RAM ', Color);

      { Calculate bar dimensions - leave room for " 100%" at end }
      BarWidth := Size.X - 11;  { "RAM " (4) + "[]" (2) + " 100%" (5) }
      if BarWidth < 5 then BarWidth := 5;

      FilledWidth := (FUsedPercent * BarWidth) div 100;

      DrawChar(B, 4, '[', Color, 1);
      for I := 0 to BarWidth - 1 do begin
        if I < FilledWidth then
          DrawChar(B, 5 + I, #$2588, BarColor, 1)  { █ Full block }
        else
          DrawChar(B, 5 + I, #$2591, Color, 1);    { ░ Light shade }
      end;
      DrawChar(B, 5 + BarWidth, ']', Color, 1);

      S := Format(' %d%%', [FUsedPercent]);
      DrawStr(B, 6 + BarWidth, S, Color);

      WriteLine(0, 0, Size.X, 1, B);
    end;

    rdText: begin
      { Format: 4.2 GB / 8.0 GB }
      DrawChar(B, 0, ' ', Color, Size.X);
      S := Format('%s / %s', [FormatBytes(FUsedBytes), FormatBytes(FTotalBytes)]);
      DrawStr(B, 0, S, BarColor);
      WriteLine(0, 0, Size.X, 1, B);
    end;

    rdCompact: begin
      { Format: RAM: 78% }
      DrawChar(B, 0, ' ', Color, Size.X);
      S := Format('RAM: %d%%', [FUsedPercent]);
      DrawStr(B, 0, S, BarColor);
      WriteLine(0, 0, Size.X, 1, B);
    end;
  end;
end;

end.
