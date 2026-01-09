{*******************************************************}
{       Free Vision - Disk Usage View                  }
{       Disk space usage display widget                }
{*******************************************************}

unit DiskUsageView;

interface

uses
  Winapi.Windows,
  FVConsts, Objects, Drivers, Views;

type
  TDiskUsageView = class(TView)
  private
    FDrive: Char;
    FLastUpdate: UInt64;
    FRefreshInterval: Word;
    FUsedPercent: Integer;
    FFreeBytes: UInt64;
    FTotalBytes: UInt64;
    FShowFreeSpace: Boolean;
    FWarningThreshold: Byte;
    FCriticalThreshold: Byte;
    FDriveValid: Boolean;
  public
    constructor Create(var Bounds: TRect; ADrive: Char = 'C'); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    procedure SetDrive(ADrive: Char);
    property Drive: Char read FDrive write SetDrive;
    property RefreshInterval: Word read FRefreshInterval write FRefreshInterval;
    property ShowFreeSpace: Boolean read FShowFreeSpace write FShowFreeSpace;
    property WarningThreshold: Byte read FWarningThreshold write FWarningThreshold;
    property CriticalThreshold: Byte read FCriticalThreshold write FCriticalThreshold;
    property UsedPercent: Integer read FUsedPercent;
    property FreeBytes: UInt64 read FFreeBytes;
    property TotalBytes: UInt64 read FTotalBytes;
  end;

const
  idDiskUsageView = 331;

implementation

uses
  System.SysUtils;

{ TDiskUsageView }

constructor TDiskUsageView.Create(var Bounds: TRect; ADrive: Char);
begin
  inherited Create(Bounds);
  FDrive := UpCase(ADrive);
  FRefreshInterval := 10;  { Disk changes slowly }
  FLastUpdate := 0;
  FUsedPercent := 0;
  FFreeBytes := 0;
  FTotalBytes := 0;
  FShowFreeSpace := True;
  FWarningThreshold := 80;
  FCriticalThreshold := 95;
  FDriveValid := False;
  { Get initial data }
  Update;
end;

procedure TDiskUsageView.SetDrive(ADrive: Char);
begin
  FDrive := UpCase(ADrive);
  FLastUpdate := 0;  { Force refresh }
  Update;
end;

procedure TDiskUsageView.Update;
var
  CurrentTick: UInt64;
  FreeBytesAvailable, TotalNumberOfBytes, TotalNumberOfFreeBytes: Int64;
  DrivePath: string;
begin
  CurrentTick := GetTickCount64;
  if (CurrentTick - FLastUpdate) >= (UInt64(FRefreshInterval) * 1000) then begin
    FLastUpdate := CurrentTick;

    DrivePath := FDrive + ':\';
    if GetDiskFreeSpaceEx(PChar(DrivePath), FreeBytesAvailable, TotalNumberOfBytes, @TotalNumberOfFreeBytes) then begin
      FDriveValid := True;
      FTotalBytes := TotalNumberOfBytes;
      FFreeBytes := TotalNumberOfFreeBytes;
      if FTotalBytes > 0 then
        FUsedPercent := 100 - Integer((FFreeBytes * 100) div FTotalBytes)
      else
        FUsedPercent := 0;
    end
    else begin
      FDriveValid := False;
      FTotalBytes := 0;
      FFreeBytes := 0;
      FUsedPercent := 0;
    end;

    DrawView;
  end;
end;

function FormatBytes(Bytes: UInt64): string;
begin
  if Bytes >= 1099511627776 then  { >= 1 TB }
    Result := Format('%.1f TB', [Bytes / 1099511627776])
  else if Bytes >= 1073741824 then  { >= 1 GB }
    Result := Format('%.0f GB', [Bytes / 1073741824])
  else if Bytes >= 1048576 then  { >= 1 MB }
    Result := Format('%.0f MB', [Bytes / 1048576])
  else
    Result := Format('%.0f KB', [Bytes / 1024]);
end;

procedure TDiskUsageView.Draw;
var
  B: TDrawBuffer;
  Color, BarColor: Byte;
  S, Info: string;
  BarWidth, FilledWidth, I, InfoLen: Integer;
begin
  Color := GetColor(1);

  DrawChar(B, 0, ' ', Color, Size.X);

  if not FDriveValid then begin
    S := Format('%s: N/A', [FDrive]);
    DrawStr(B, 0, S, Color);
    WriteLine(0, 0, Size.X, 1, B);
    Exit;
  end;

  { Determine bar color based on usage }
  if FUsedPercent >= FCriticalThreshold then
    BarColor := GetColor(4)  { Red/Critical }
  else if FUsedPercent >= FWarningThreshold then
    BarColor := GetColor(3)  { Yellow/Warning }
  else
    BarColor := GetColor(2); { Green/Normal }

  { Format: C: [████░░░░] 245 GB free }
  DrawStr(B, 0, FDrive + ': ', Color);

  { Build info string }
  if FShowFreeSpace then
    Info := Format(' %s free', [FormatBytes(FFreeBytes)])
  else
    Info := Format(' %d%%', [FUsedPercent]);

  InfoLen := Length(Info);

  { Calculate bar dimensions }
  BarWidth := Size.X - 5 - InfoLen;  { "C: " (3) + "[]" (2) + info }
  if BarWidth < 5 then BarWidth := 5;

  FilledWidth := (FUsedPercent * BarWidth) div 100;

  DrawChar(B, 3, '[', Color, 1);
  for I := 0 to BarWidth - 1 do begin
    if I < FilledWidth then
      DrawChar(B, 4 + I, #$2588, BarColor, 1)  { █ Full block }
    else
      DrawChar(B, 4 + I, #$2591, Color, 1);    { ░ Light shade }
  end;
  DrawChar(B, 4 + BarWidth, ']', Color, 1);

  DrawStr(B, 5 + BarWidth, Info, Color);

  WriteLine(0, 0, Size.X, 1, B);
end;

end.
