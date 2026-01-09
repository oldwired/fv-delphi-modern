{*******************************************************}
{       Free Vision - Process Count View               }
{       Running processes and threads display          }
{*******************************************************}

unit ProcessView;

interface

uses
  Winapi.Windows, Winapi.TlHelp32,
  FVConsts, Objects, Drivers, Views;

type
  TProcessCountView = class(TView)
  private
    FLastUpdate: UInt64;
    FRefreshInterval: Word;
    FProcessCount: Integer;
    FThreadCount: Integer;
    FShowThreads: Boolean;
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure Draw; override;
    procedure Update; virtual;
    property RefreshInterval: Word read FRefreshInterval write FRefreshInterval;
    property ShowThreads: Boolean read FShowThreads write FShowThreads;
    property ProcessCount: Integer read FProcessCount;
    property ThreadCount: Integer read FThreadCount;
  end;

const
  idProcessCountView = 332;

implementation

uses
  System.SysUtils;

{ TProcessCountView }

constructor TProcessCountView.Create(var Bounds: TRect);
begin
  inherited Create(Bounds);
  FRefreshInterval := 3;
  FLastUpdate := 0;
  FProcessCount := 0;
  FThreadCount := 0;
  FShowThreads := True;
  { Get initial data }
  Update;
end;

procedure TProcessCountView.Update;
var
  CurrentTick: UInt64;
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  ProcCount, ThrCount: Integer;
begin
  CurrentTick := GetTickCount64;
  if (CurrentTick - FLastUpdate) >= (UInt64(FRefreshInterval) * 1000) then begin
    FLastUpdate := CurrentTick;

    ProcCount := 0;
    ThrCount := 0;

    Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if Snapshot <> INVALID_HANDLE_VALUE then begin
      try
        ProcessEntry.dwSize := SizeOf(TProcessEntry32);
        if Process32First(Snapshot, ProcessEntry) then begin
          repeat
            Inc(ProcCount);
            Inc(ThrCount, ProcessEntry.cntThreads);
          until not Process32Next(Snapshot, ProcessEntry);
        end;
      finally
        CloseHandle(Snapshot);
      end;
    end;

    FProcessCount := ProcCount;
    FThreadCount := ThrCount;

    DrawView;
  end;
end;

procedure TProcessCountView.Draw;
var
  B: TDrawBuffer;
  Color: Byte;
  S: string;
begin
  Color := GetColor(2);
  DrawChar(B, 0, ' ', Color, Size.X);

  if FShowThreads then
    S := Format('Procs: %d  Threads: %d', [FProcessCount, FThreadCount])
  else
    S := Format('Processes: %d', [FProcessCount]);

  DrawStr(B, 0, S, Color);
  WriteLine(0, 0, Size.X, 1, B);
end;

end.
