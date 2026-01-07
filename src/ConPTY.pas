{*******************************************************}
{       ConPTY - Windows Pseudo Console Wrapper         }
{       For Free Vision Terminal Component              }
{       Requires Windows 10 1809+                       }
{*******************************************************}

unit ConPTY;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  Drivers;  { For evTerminal, cmTerminalData, cmTerminalExit }

{***************************************************************************}
{                              PUBLIC CONSTANTS                             }
{***************************************************************************}

const
  { ConPTY flags }
  PSEUDOCONSOLE_INHERIT_CURSOR = $00000001;

{***************************************************************************}
{                           WINDOWS API TYPES                               }
{***************************************************************************}

type
  { Pseudo console handle type }
  HPCON = THandle;
  PHCON = ^HPCON;

  { Coordinate for console size }
  COORD = record
    X: SHORT;
    Y: SHORT;
  end;

  { Extended startup info for CreateProcess with ConPTY }
  PPROC_THREAD_ATTRIBUTE_LIST = Pointer;

  STARTUPINFOEXW = record
    StartupInfo: TStartupInfoW;
    lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST;
  end;
  PSTARTUPINFOEXW = ^STARTUPINFOEXW;

{***************************************************************************}
{                           WINDOWS API IMPORTS                             }
{***************************************************************************}

const
  PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE = $00020016;
  EXTENDED_STARTUPINFO_PRESENT = $00080000;

{ ConPTY API functions - Windows 10 1809+ }
function CreatePseudoConsole(size: COORD; hInput, hOutput: THandle;
  dwFlags: DWORD; out phPC: HPCON): HRESULT; stdcall;
  external kernel32 name 'CreatePseudoConsole';

function ResizePseudoConsole(hPC: HPCON; size: COORD): HRESULT; stdcall;
  external kernel32 name 'ResizePseudoConsole';

procedure ClosePseudoConsole(hPC: HPCON); stdcall;
  external kernel32 name 'ClosePseudoConsole';

{ Thread attribute list functions }
function InitializeProcThreadAttributeList(
  lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST;
  dwAttributeCount: DWORD;
  dwFlags: DWORD;
  var lpSize: SIZE_T): BOOL; stdcall;
  external kernel32 name 'InitializeProcThreadAttributeList';

function UpdateProcThreadAttribute(
  lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST;
  dwFlags: DWORD;
  Attribute: DWORD_PTR;
  lpValue: Pointer;
  cbSize: SIZE_T;
  lpPreviousValue: Pointer;
  lpReturnSize: PSIZE_T): BOOL; stdcall;
  external kernel32 name 'UpdateProcThreadAttribute';

procedure DeleteProcThreadAttributeList(
  lpAttributeList: PPROC_THREAD_ATTRIBUTE_LIST); stdcall;
  external kernel32 name 'DeleteProcThreadAttributeList';

{***************************************************************************}
{                            FORWARD DECLARATIONS                           }
{***************************************************************************}

type
  TConPTY = class;
  TConPTYReader = class;

  { Event callback types }
  TConPTYDataEvent = procedure(Sender: TConPTY; const Data: TBytes) of object;
  TConPTYExitEvent = procedure(Sender: TConPTY; ExitCode: DWORD) of object;

  { Event posting callback - allows decoupling from FV }
  TConPTYPostEvent = procedure(What: Word; Command: Word; InfoPtr: Pointer) of object;

{***************************************************************************}
{                           TConPTYReader CLASS                             }
{***************************************************************************}

  TConPTYReader = class(TThread)
  private
    FOwner: TConPTY;
    FPipeRead: THandle;
    FBuffer: TBytes;
    FBufferLock: TCriticalSection;
    FDataAvailable: Boolean;
    FStopEvent: System.SyncObjs.TEvent;
    FReadBuffer: array[0..4095] of Byte;  // 4KB read buffer

  protected
    procedure Execute; override;

  public
    constructor Create(AOwner: TConPTY; APipeRead: THandle);
    destructor Destroy; override;

    { Thread-safe data retrieval }
    function GetPendingData: TBytes;
    function HasPendingData: Boolean;
    procedure ClearBuffer;

    { Signal thread to stop }
    procedure SignalStop;
  end;

{***************************************************************************}
{                              TConPTY CLASS                                }
{***************************************************************************}

  TConPTY = class
  private
    FhPC: HPCON;                      // Pseudo console handle
    FhPipeIn: THandle;                // Pipe for reading PTY output (our read end)
    FhPipeOut: THandle;               // Pipe for writing to PTY (our write end)
    FhPipePTYIn: THandle;             // PTY's input pipe (connected to our write)
    FhPipePTYOut: THandle;            // PTY's output pipe (connected to our read)
    FhProcess: THandle;               // Child process handle
    FhThread: THandle;                // Child main thread handle
    FProcessId: DWORD;                // Child process ID
    FReaderThread: TConPTYReader;     // Background reader thread
    FWidth: Integer;                  // Current width in characters
    FHeight: Integer;                 // Current height in characters
    FExitCode: DWORD;                 // Process exit code
    FRunning: Boolean;                // Is process running?
    FLastError: string;               // Last error message

    { Event callbacks }
    FOnData: TConPTYDataEvent;
    FOnExit: TConPTYExitEvent;
    FOnPostEvent: TConPTYPostEvent;

    { Internal methods }
    function CreatePipes: Boolean;
    function CreatePseudoConsoleInternal: Boolean;
    function LaunchProcess(const CommandLine: string): Boolean;
    procedure Cleanup;
    procedure CheckProcessStatus;

  public
    constructor Create(AWidth, AHeight: Integer);
    destructor Destroy; override;

    { Launch methods }
    function Execute(const CommandLine: string): Boolean; overload;
    function Execute(const Executable: string;
      const Args: array of string): Boolean; overload;

    { I/O operations }
    procedure Write(const Data: TBytes);
    procedure WriteChar(Ch: Char);
    procedure WriteString(const S: string);

    { Read pending data (called from main thread) }
    function ReadPendingData: TBytes;
    function HasPendingData: Boolean;

    { Control operations }
    procedure Resize(NewWidth, NewHeight: Integer);
    procedure Terminate;
    function WaitForExit(Timeout: DWORD = INFINITE): Boolean;

    { Status }
    function IsRunning: Boolean;
    function GetExitCode: DWORD;

    { Properties }
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property ExitCode: DWORD read FExitCode;
    property ProcessId: DWORD read FProcessId;
    property ProcessHandle: THandle read FhProcess;
    property LastError: string read FLastError;

    { Event properties }
    property OnData: TConPTYDataEvent read FOnData write FOnData;
    property OnExit: TConPTYExitEvent read FOnExit write FOnExit;
    property OnPostEvent: TConPTYPostEvent read FOnPostEvent write FOnPostEvent;
  end;

{***************************************************************************}
{                           UTILITY FUNCTIONS                               }
{***************************************************************************}

{ Check if ConPTY is available (Windows 10 1809+) }
function IsConPTYAvailable: Boolean;

{ Build command line from executable and arguments }
function BuildCommandLine(const Executable: string;
  const Args: array of string): string;

implementation

{***************************************************************************}
{                           UTILITY FUNCTIONS                               }
{***************************************************************************}

function IsConPTYAvailable: Boolean;
var
  Module: HMODULE;
  ProcAddr: Pointer;
begin
  Result := False;
  Module := GetModuleHandle(kernel32);
  if Module <> 0 then
  begin
    ProcAddr := GetProcAddress(Module, 'CreatePseudoConsole');
    Result := ProcAddr <> nil;
  end;
end;

function BuildCommandLine(const Executable: string;
  const Args: array of string): string;
var
  I: Integer;
  Arg: string;
begin
  // Quote executable if it contains spaces
  if Pos(' ', Executable) > 0 then
    Result := '"' + Executable + '"'
  else
    Result := Executable;

  // Add arguments
  for I := 0 to High(Args) do
  begin
    Arg := Args[I];
    // Quote argument if it contains spaces
    if Pos(' ', Arg) > 0 then
      Arg := '"' + Arg + '"';
    Result := Result + ' ' + Arg;
  end;
end;

{***************************************************************************}
{                        TConPTYReader IMPLEMENTATION                       }
{***************************************************************************}

constructor TConPTYReader.Create(AOwner: TConPTY; APipeRead: THandle);
begin
  inherited Create(True);  // Create suspended
  FOwner := AOwner;
  FPipeRead := APipeRead;
  FBufferLock := TCriticalSection.Create;
  FStopEvent := System.SyncObjs.TEvent.Create(nil, True, False, '');
  FDataAvailable := False;
  SetLength(FBuffer, 0);
  FreeOnTerminate := False;
end;

destructor TConPTYReader.Destroy;
begin
  SignalStop;
  if not Terminated then
  begin
    Terminate;
    WaitFor;
  end;
  FreeAndNil(FBufferLock);
  FreeAndNil(FStopEvent);
  inherited;
end;

procedure TConPTYReader.SignalStop;
begin
  if FStopEvent <> nil then
    FStopEvent.SetEvent;
end;

procedure TConPTYReader.Execute;
var
  BytesRead: DWORD;
  BytesAvail: DWORD;
  OldLen: Integer;
  WaitResult: DWORD;
  Overlapped: TOverlapped;
  ReadEvent: THandle;
begin
  ReadEvent := CreateEvent(nil, True, False, nil);
  try
    while not Terminated do
    begin
      // Check if we should stop
      if FStopEvent.WaitFor(0) = wrSignaled then
        Break;

      // Check if pipe is valid
      if FPipeRead = INVALID_HANDLE_VALUE then
        Break;

      // Check if data is available (non-blocking peek)
      BytesAvail := 0;
      if not PeekNamedPipe(FPipeRead, nil, 0, nil, @BytesAvail, nil) then
      begin
        // Pipe error - probably closed
        Break;
      end;

      if BytesAvail > 0 then
      begin
        // Read available data
        if ReadFile(FPipeRead, FReadBuffer[0], SizeOf(FReadBuffer),
          BytesRead, nil) then
        begin
          if BytesRead > 0 then
          begin
            // Append to buffer with lock
            FBufferLock.Enter;
            try
              OldLen := Length(FBuffer);
              SetLength(FBuffer, OldLen + Integer(BytesRead));
              Move(FReadBuffer[0], FBuffer[OldLen], BytesRead);
              FDataAvailable := True;
            finally
              FBufferLock.Leave;
            end;

            // Notify owner via event posting callback
            if Assigned(FOwner.FOnPostEvent) then
              FOwner.FOnPostEvent(evTerminal, cmTerminalData, FOwner);
          end;
        end
        else
        begin
          // Read error
          Break;
        end;
      end
      else
      begin
        // No data available - sleep briefly to avoid busy wait
        Sleep(10);
      end;

      // Check process status periodically
      FOwner.CheckProcessStatus;
    end;
  finally
    CloseHandle(ReadEvent);
  end;
end;

function TConPTYReader.GetPendingData: TBytes;
begin
  FBufferLock.Enter;
  try
    Result := Copy(FBuffer);
    SetLength(FBuffer, 0);
    FDataAvailable := False;
  finally
    FBufferLock.Leave;
  end;
end;

function TConPTYReader.HasPendingData: Boolean;
begin
  FBufferLock.Enter;
  try
    Result := FDataAvailable and (Length(FBuffer) > 0);
  finally
    FBufferLock.Leave;
  end;
end;

procedure TConPTYReader.ClearBuffer;
begin
  FBufferLock.Enter;
  try
    SetLength(FBuffer, 0);
    FDataAvailable := False;
  finally
    FBufferLock.Leave;
  end;
end;

{***************************************************************************}
{                          TConPTY IMPLEMENTATION                           }
{***************************************************************************}

constructor TConPTY.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
  FhPC := 0;
  FhPipeIn := INVALID_HANDLE_VALUE;
  FhPipeOut := INVALID_HANDLE_VALUE;
  FhPipePTYIn := INVALID_HANDLE_VALUE;
  FhPipePTYOut := INVALID_HANDLE_VALUE;
  FhProcess := INVALID_HANDLE_VALUE;
  FhThread := INVALID_HANDLE_VALUE;
  FProcessId := 0;
  FReaderThread := nil;
  FExitCode := 0;
  FRunning := False;
  FLastError := '';
end;

destructor TConPTY.Destroy;
begin
  Cleanup;
  inherited;
end;

procedure TConPTY.Cleanup;
begin
  // Stop reader thread first
  if FReaderThread <> nil then
  begin
    FReaderThread.SignalStop;
    FReaderThread.Terminate;
    FReaderThread.WaitFor;
    FreeAndNil(FReaderThread);
  end;

  // Terminate process if still running
  if FhProcess <> INVALID_HANDLE_VALUE then
  begin
    if IsRunning then
      TerminateProcess(FhProcess, 1);
    CloseHandle(FhProcess);
    FhProcess := INVALID_HANDLE_VALUE;
  end;

  if FhThread <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FhThread);
    FhThread := INVALID_HANDLE_VALUE;
  end;

  // Close pseudo console (must be before closing pipes)
  if FhPC <> 0 then
  begin
    ClosePseudoConsole(FhPC);
    FhPC := 0;
  end;

  // Close pipes
  if FhPipeIn <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FhPipeIn);
    FhPipeIn := INVALID_HANDLE_VALUE;
  end;

  if FhPipeOut <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FhPipeOut);
    FhPipeOut := INVALID_HANDLE_VALUE;
  end;

  if FhPipePTYIn <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FhPipePTYIn);
    FhPipePTYIn := INVALID_HANDLE_VALUE;
  end;

  if FhPipePTYOut <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FhPipePTYOut);
    FhPipePTYOut := INVALID_HANDLE_VALUE;
  end;

  FRunning := False;
end;

function TConPTY.CreatePipes: Boolean;
var
  SecurityAttr: TSecurityAttributes;
begin
  Result := False;

  SecurityAttr.nLength := SizeOf(TSecurityAttributes);
  SecurityAttr.bInheritHandle := True;
  SecurityAttr.lpSecurityDescriptor := nil;

  // Create pipe for PTY output (we read from FhPipeIn, PTY writes to FhPipePTYOut)
  if not CreatePipe(FhPipeIn, FhPipePTYOut, @SecurityAttr, 0) then
  begin
    FLastError := 'Failed to create output pipe: ' + SysErrorMessage(GetLastError);
    Exit;
  end;

  // Create pipe for PTY input (we write to FhPipeOut, PTY reads from FhPipePTYIn)
  if not CreatePipe(FhPipePTYIn, FhPipeOut, @SecurityAttr, 0) then
  begin
    FLastError := 'Failed to create input pipe: ' + SysErrorMessage(GetLastError);
    CloseHandle(FhPipeIn);
    CloseHandle(FhPipePTYOut);
    FhPipeIn := INVALID_HANDLE_VALUE;
    FhPipePTYOut := INVALID_HANDLE_VALUE;
    Exit;
  end;

  Result := True;
end;

function TConPTY.CreatePseudoConsoleInternal: Boolean;
var
  ConSize: COORD;
  HR: HRESULT;
begin
  Result := False;

  ConSize.X := SHORT(FWidth);
  ConSize.Y := SHORT(FHeight);

  HR := CreatePseudoConsole(ConSize, FhPipePTYIn, FhPipePTYOut, 0, FhPC);
  if FAILED(HR) then
  begin
    FLastError := Format('CreatePseudoConsole failed: 0x%.8X', [HR]);
    Exit;
  end;

  Result := True;
end;

function TConPTY.LaunchProcess(const CommandLine: string): Boolean;
var
  StartupInfoEx: STARTUPINFOEXW;
  ProcessInfo: TProcessInformation;
  AttrListSize: SIZE_T;
  AttrList: PPROC_THREAD_ATTRIBUTE_LIST;
  CmdLine: string;
begin
  Result := False;
  AttrList := nil;

  try
    // Initialize startup info
    FillChar(StartupInfoEx, SizeOf(StartupInfoEx), 0);
    StartupInfoEx.StartupInfo.cb := SizeOf(STARTUPINFOEXW);

    // Get required size for attribute list
    AttrListSize := 0;
    InitializeProcThreadAttributeList(nil, 1, 0, AttrListSize);

    // Allocate attribute list
    GetMem(AttrList, AttrListSize);
    if AttrList = nil then
    begin
      FLastError := 'Failed to allocate attribute list';
      Exit;
    end;

    // Initialize attribute list
    if not InitializeProcThreadAttributeList(AttrList, 1, 0, AttrListSize) then
    begin
      FLastError := 'InitializeProcThreadAttributeList failed: ' +
        SysErrorMessage(GetLastError);
      Exit;
    end;

    // Add pseudo console attribute
    if not UpdateProcThreadAttribute(AttrList, 0,
      PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE, Pointer(FhPC), SizeOf(HPCON),
      nil, nil) then
    begin
      FLastError := 'UpdateProcThreadAttribute failed: ' +
        SysErrorMessage(GetLastError);
      DeleteProcThreadAttributeList(AttrList);
      Exit;
    end;

    StartupInfoEx.lpAttributeList := AttrList;

    // Make command line mutable (CreateProcessW requires it)
    CmdLine := CommandLine;
    UniqueString(CmdLine);

    // Create the process
    FillChar(ProcessInfo, SizeOf(ProcessInfo), 0);
    if not CreateProcessW(nil, PWideChar(CmdLine), nil, nil, False,
      EXTENDED_STARTUPINFO_PRESENT, nil, nil,
      StartupInfoEx.StartupInfo, ProcessInfo) then
    begin
      FLastError := 'CreateProcess failed: ' + SysErrorMessage(GetLastError);
      DeleteProcThreadAttributeList(AttrList);
      Exit;
    end;

    // Store process info
    FhProcess := ProcessInfo.hProcess;
    FhThread := ProcessInfo.hThread;
    FProcessId := ProcessInfo.dwProcessId;
    FRunning := True;

    // Clean up attribute list
    DeleteProcThreadAttributeList(AttrList);
    FreeMem(AttrList);
    AttrList := nil;

    // Close the PTY-side pipe handles (we don't need them anymore)
    CloseHandle(FhPipePTYIn);
    FhPipePTYIn := INVALID_HANDLE_VALUE;
    CloseHandle(FhPipePTYOut);
    FhPipePTYOut := INVALID_HANDLE_VALUE;

    // Start the reader thread
    FReaderThread := TConPTYReader.Create(Self, FhPipeIn);
    FReaderThread.Start;

    Result := True;

  finally
    if AttrList <> nil then
      FreeMem(AttrList);
  end;
end;

function TConPTY.Execute(const CommandLine: string): Boolean;
begin
  Result := False;

  // Clean up any existing session
  Cleanup;

  // Check ConPTY availability
  if not IsConPTYAvailable then
  begin
    FLastError := 'ConPTY not available (requires Windows 10 1809+)';
    Exit;
  end;

  // Create pipes
  if not CreatePipes then
    Exit;

  // Create pseudo console
  if not CreatePseudoConsoleInternal then
  begin
    Cleanup;
    Exit;
  end;

  // Launch the process
  if not LaunchProcess(CommandLine) then
  begin
    Cleanup;
    Exit;
  end;

  Result := True;
end;

function TConPTY.Execute(const Executable: string;
  const Args: array of string): Boolean;
begin
  Result := Execute(BuildCommandLine(Executable, Args));
end;

procedure TConPTY.Write(const Data: TBytes);
var
  BytesWritten: DWORD;
begin
  if (FhPipeOut <> INVALID_HANDLE_VALUE) and (Length(Data) > 0) then
    WriteFile(FhPipeOut, Data[0], Length(Data), BytesWritten, nil);
end;

procedure TConPTY.WriteChar(Ch: Char);
var
  UTF8Bytes: TBytes;
begin
  if FhPipeOut <> INVALID_HANDLE_VALUE then
  begin
    { Encode Char as UTF-8 }
    UTF8Bytes := TEncoding.UTF8.GetBytes(string(Ch));
    Write(UTF8Bytes);
  end;
end;

procedure TConPTY.WriteString(const S: string);
var
  UTF8Bytes: TBytes;
begin
  if (FhPipeOut <> INVALID_HANDLE_VALUE) and (Length(S) > 0) then
  begin
    { Encode string as UTF-8 }
    UTF8Bytes := TEncoding.UTF8.GetBytes(S);
    Write(UTF8Bytes);
  end;
end;

function TConPTY.ReadPendingData: TBytes;
begin
  if FReaderThread <> nil then
    Result := FReaderThread.GetPendingData
  else
    SetLength(Result, 0);
end;

function TConPTY.HasPendingData: Boolean;
begin
  Result := (FReaderThread <> nil) and FReaderThread.HasPendingData;
end;

procedure TConPTY.Resize(NewWidth, NewHeight: Integer);
var
  ConSize: COORD;
begin
  if FhPC <> 0 then
  begin
    ConSize.X := SHORT(NewWidth);
    ConSize.Y := SHORT(NewHeight);
    if SUCCEEDED(ResizePseudoConsole(FhPC, ConSize)) then
    begin
      FWidth := NewWidth;
      FHeight := NewHeight;
    end;
  end
  else
  begin
    FWidth := NewWidth;
    FHeight := NewHeight;
  end;
end;

procedure TConPTY.Terminate;
begin
  if (FhProcess <> INVALID_HANDLE_VALUE) and IsRunning then
    TerminateProcess(FhProcess, 1);
end;

function TConPTY.WaitForExit(Timeout: DWORD): Boolean;
begin
  Result := False;
  if FhProcess <> INVALID_HANDLE_VALUE then
  begin
    Result := WaitForSingleObject(FhProcess, Timeout) = WAIT_OBJECT_0;
    if Result then
      CheckProcessStatus;
  end;
end;

procedure TConPTY.CheckProcessStatus;
var
  EC: DWORD;
begin
  if FRunning and (FhProcess <> INVALID_HANDLE_VALUE) then
  begin
    if GetExitCodeProcess(FhProcess, EC) then
    begin
      if EC <> STILL_ACTIVE then
      begin
        FExitCode := EC;
        FRunning := False;

        // Notify via callback
        if Assigned(FOnExit) then
          FOnExit(Self, FExitCode);

        // Notify via event posting
        if Assigned(FOnPostEvent) then
          FOnPostEvent(evTerminal, cmTerminalExit, Self);
      end;
    end;
  end;
end;

function TConPTY.IsRunning: Boolean;
begin
  CheckProcessStatus;
  Result := FRunning;
end;

function TConPTY.GetExitCode: DWORD;
begin
  CheckProcessStatus;
  Result := FExitCode;
end;

end.
