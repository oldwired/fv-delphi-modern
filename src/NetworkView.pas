{*******************************************************}
{       Free Vision - Network Activity View            }
{       Network upload/download speed display          }
{*******************************************************}

unit NetworkView;

interface

uses
  Winapi.Windows,
  FVConsts, Objects, Drivers, Views;

type
  TNetworkActivityView = class(TView)
  private
    FLastUpdate: UInt64;
    FRefreshInterval: Word;
    FBytesIn: UInt64;
    FBytesOut: UInt64;
    FSpeedIn: UInt64;   { Bytes per second }
    FSpeedOut: UInt64;  { Bytes per second }
    FPrevBytesIn: UInt64;
    FPrevBytesOut: UInt64;
    FPrevTime: UInt64;
    FFirstSample: Boolean;
    FAvailable: Boolean;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    property RefreshInterval: Word read FRefreshInterval write FRefreshInterval;
    property SpeedIn: UInt64 read FSpeedIn;
    property SpeedOut: UInt64 read FSpeedOut;
    property Available: Boolean read FAvailable;
  end;

const
  idNetworkActivityView = 335;

implementation

uses
  System.SysUtils;

type
  { MIB_IF_ROW2 structure - simplified for our needs }
  PMIB_IF_ROW2 = ^MIB_IF_ROW2;
  MIB_IF_ROW2 = record
    InterfaceLuid: UInt64;
    InterfaceIndex: ULONG;
    InterfaceGuid: TGUID;
    Alias: array[0..256] of WideChar;
    Description: array[0..256] of WideChar;
    PhysicalAddressLength: ULONG;
    PhysicalAddress: array[0..31] of Byte;
    PermanentPhysicalAddress: array[0..31] of Byte;
    Mtu: ULONG;
    Type_: ULONG;
    TunnelType: ULONG;
    MediaType: ULONG;
    PhysicalMediumType: ULONG;
    AccessType: ULONG;
    DirectionType: ULONG;
    InterfaceAndOperStatusFlags: Byte;
    OperStatus: ULONG;
    AdminStatus: ULONG;
    MediaConnectState: ULONG;
    NetworkGuid: TGUID;
    ConnectionType: ULONG;
    TransmitLinkSpeed: UInt64;
    ReceiveLinkSpeed: UInt64;
    InOctets: UInt64;
    InUcastPkts: UInt64;
    InNUcastPkts: UInt64;
    InDiscards: UInt64;
    InErrors: UInt64;
    InUnknownProtos: UInt64;
    InUcastOctets: UInt64;
    InMulticastOctets: UInt64;
    InBroadcastOctets: UInt64;
    OutOctets: UInt64;
    OutUcastPkts: UInt64;
    OutNUcastPkts: UInt64;
    OutDiscards: UInt64;
    OutErrors: UInt64;
    OutUcastOctets: UInt64;
    OutMulticastOctets: UInt64;
    OutBroadcastOctets: UInt64;
    OutQLen: UInt64;
  end;

  { MIB_IF_TABLE2 structure }
  PMIB_IF_TABLE2 = ^MIB_IF_TABLE2;
  MIB_IF_TABLE2 = record
    NumEntries: ULONG;
    Table: array[0..0] of MIB_IF_ROW2;  { Variable size array }
  end;

var
  IpHlpApiHandle: THandle = 0;
  GetIfTable2: function(var Table: PMIB_IF_TABLE2): DWORD; stdcall = nil;
  FreeMibTable: procedure(Memory: Pointer); stdcall = nil;

function LoadIpHlpApi: Boolean;
begin
  if IpHlpApiHandle <> 0 then begin
    Result := Assigned(GetIfTable2);
    Exit;
  end;

  IpHlpApiHandle := LoadLibrary('iphlpapi.dll');
  if IpHlpApiHandle <> 0 then begin
    @GetIfTable2 := GetProcAddress(IpHlpApiHandle, 'GetIfTable2');
    @FreeMibTable := GetProcAddress(IpHlpApiHandle, 'FreeMibTable');
  end;

  Result := Assigned(GetIfTable2) and Assigned(FreeMibTable);
end;

{ TNetworkActivityView }

constructor TNetworkActivityView.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FRefreshInterval := 1;
  FLastUpdate := 0;
  FBytesIn := 0;
  FBytesOut := 0;
  FSpeedIn := 0;
  FSpeedOut := 0;
  FPrevBytesIn := 0;
  FPrevBytesOut := 0;
  FPrevTime := 0;
  FFirstSample := True;
  FAvailable := LoadIpHlpApi;
  { Get initial sample }
  if FAvailable then
    Update;
end;

procedure TNetworkActivityView.Update;
var
  CurrentTick: UInt64;
  Table: PMIB_IF_TABLE2;
  I: Integer;
  TotalIn, TotalOut: UInt64;
  TimeDelta: UInt64;
begin
  if not FAvailable then Exit;

  CurrentTick := GetTickCount64;
  if (CurrentTick - FLastUpdate) >= (UInt64(FRefreshInterval) * 1000) then begin
    FLastUpdate := CurrentTick;

    Table := nil;
    if GetIfTable2(Table) = 0 then begin
      try
        TotalIn := 0;
        TotalOut := 0;

        { Sum bytes from all interfaces }
        for I := 0 to Table.NumEntries - 1 do begin
          { Skip loopback (type 24) and tunnel interfaces }
          if (Table.Table[I].Type_ <> 24) and (Table.Table[I].OperStatus = 1) then begin
            TotalIn := TotalIn + Table.Table[I].InOctets;
            TotalOut := TotalOut + Table.Table[I].OutOctets;
          end;
        end;

        FBytesIn := TotalIn;
        FBytesOut := TotalOut;

        if FFirstSample then begin
          FFirstSample := False;
          FPrevBytesIn := TotalIn;
          FPrevBytesOut := TotalOut;
          FPrevTime := CurrentTick;
          FSpeedIn := 0;
          FSpeedOut := 0;
        end
        else begin
          { Calculate speed (bytes per second) }
          TimeDelta := CurrentTick - FPrevTime;
          if TimeDelta > 0 then begin
            FSpeedIn := ((TotalIn - FPrevBytesIn) * 1000) div TimeDelta;
            FSpeedOut := ((TotalOut - FPrevBytesOut) * 1000) div TimeDelta;
          end;

          FPrevBytesIn := TotalIn;
          FPrevBytesOut := TotalOut;
          FPrevTime := CurrentTick;
        end;
      finally
        if Assigned(FreeMibTable) then
          FreeMibTable(Table);
      end;
    end;

    DrawView;
  end;
end;

function FormatSpeed(BytesPerSec: UInt64): string;
begin
  if BytesPerSec >= 1073741824 then  { >= 1 GB/s }
    Result := Format('%.1f GB/s', [BytesPerSec / 1073741824])
  else if BytesPerSec >= 1048576 then  { >= 1 MB/s }
    Result := Format('%.1f MB/s', [BytesPerSec / 1048576])
  else if BytesPerSec >= 1024 then  { >= 1 KB/s }
    Result := Format('%.0f KB/s', [BytesPerSec / 1024])
  else
    Result := Format('%d B/s', [BytesPerSec]);
end;

procedure TNetworkActivityView.Draw;
var
  B: TDrawBuffer;
  Color, UpColor, DownColor: Byte;
  S: string;
begin
  Color := GetColor(1);
  UpColor := GetColor(3);    { Yellow for upload }
  DownColor := GetColor(2);  { Green for download }

  DrawChar(B, 0, ' ', Color, Size.X);

  if not FAvailable then begin
    DrawStr(B, 0, 'Net: N/A', Color);
    WriteLine(0, 0, Size.X, 1, B);
    Exit;
  end;

  { Format: Net: ↑ 125 KB/s ↓ 1.2 MB/s }
  DrawStr(B, 0, 'Net: ', Color);

  { Upload arrow and speed }
  DrawChar(B, 5, #$2191, UpColor, 1);  { ↑ }
  S := ' ' + FormatSpeed(FSpeedOut);
  DrawStr(B, 6, S, UpColor);

  { Download arrow and speed }
  DrawChar(B, 6 + Length(S) + 1, #$2193, DownColor, 1);  { ↓ }
  S := ' ' + FormatSpeed(FSpeedIn);
  DrawStr(B, 8 + Length(FormatSpeed(FSpeedOut)), S, DownColor);

  WriteLine(0, 0, Size.X, 1, B);
end;

initialization

finalization
  if IpHlpApiHandle <> 0 then
    FreeLibrary(IpHlpApiHandle);

end.
