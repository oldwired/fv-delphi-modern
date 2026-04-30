{*********************************************************}
{                                                         }
{       Free Vision - Terminal Capability Profile         }
{                                                         }
{       Adapted from VSoft.AnsiConsole                    }
{       (https://github.com/VSoftTechnologies/            }
{        VSoft.AnsiConsole) - MIT licensed                }
{       Copyright (c) 2026 Vincent Parrett                }
{                                                         }
{       Detection rules mirror Spectre.Console            }
{       (MIT - (c) 2020 Patrik Svensson, Phil Scott,      }
{        Nils Andresen).                                  }
{                                                         }
{       Probes the host terminal once at startup and      }
{       publishes a singleton FVProfile record that the   }
{       rest of Free Vision (FVScreen, SixelEncoder, ...) }
{       consults to decide what to emit.                  }
{                                                         }
{*********************************************************}

unit FVProfile;

interface

uses
  Winapi.Windows;

type
  { Coarse color capability classes, ordered from least to most capable.
    Drives RGB-to-palette downsampling in FVScreen.UpdateScreen. }
  TFVColorSystem = (
    fvcsNoColors,    { NO_COLOR / not a tty / probe failed }
    fvcsLegacy,      { 16-color SGR (30-37/40-47, 90-97/100-107) }
    fvcsEightBit,    { 256-color SGR (38;5;N / 48;5;N) }
    fvcsTrueColor    { 24-bit SGR (38;2;R;G;B / 48;2;R;G;B) }
  );

  TFVProfile = record
    AnsiSupported    : Boolean;     { VT escapes safe to emit at all }
    Interactive      : Boolean;     { console attached, not redirected, not CI }
    LegacyConsole    : Boolean;     { conhost without VT support }
    Unicode          : Boolean;     { output codepage handles wide chars }
    HyperlinkSupport : Boolean;     { OSC 8 supported by terminal }
    SixelSupport     : Boolean;     { Sixel DCS supported }
    IsCI             : Boolean;     { running under known CI environment }
    ColorSystem      : TFVColorSystem;
  end;

{ Probe + populate the singleton. Safe to call multiple times; later calls
  are idempotent unless the host changes. }
procedure InitFVProfile;

{ Singleton, populated by InitFVProfile. Reads as if all flags are False /
  fvcsNoColors before InitFVProfile runs - safe for early callers. }
function GetFVProfile: TFVProfile;

{ Active probe: try to enable VT on stdout, then read back the mode bit.
  Returns True only if the bit actually stuck. }
function ProbeVirtualTerminal(Handle: THandle): Boolean;

implementation

uses
  System.SysUtils;

const
  ENABLE_VIRTUAL_TERMINAL_PROCESSING_LOCAL = $0004;

var
  GProfile: TFVProfile;
  GInitialized: Boolean = False;

function EnvDefined(const Name: string): Boolean;
begin
  Result := GetEnvironmentVariable(Name) <> '';
end;

function EnvEquals(const Name, Value: string): Boolean;
begin
  Result := SameText(GetEnvironmentVariable(Name), Value);
end;

function EnvContains(const Name, Needle: string): Boolean;
var
  V: string;
begin
  V := LowerCase(GetEnvironmentVariable(Name));
  Result := (V <> '') and (Pos(LowerCase(Needle), V) > 0);
end;

function StdOutIsConsole: Boolean;
var
  H: THandle;
  Mode: DWORD;
begin
  H := GetStdHandle(STD_OUTPUT_HANDLE);
  if H = INVALID_HANDLE_VALUE then
    Exit(False);
  Result := GetConsoleMode(H, Mode);
end;

function ProbeVirtualTerminal(Handle: THandle): Boolean;
var
  Mode, Readback: DWORD;
begin
  if (Handle = 0) or (Handle = INVALID_HANDLE_VALUE) then
    Exit(False);
  if not GetConsoleMode(Handle, Mode) then
    Exit(False);
  if (Mode and ENABLE_VIRTUAL_TERMINAL_PROCESSING_LOCAL) <> 0 then
    Exit(True);
  if not SetConsoleMode(Handle, Mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING_LOCAL) then
    Exit(False);
  if not GetConsoleMode(Handle, Readback) then
    Exit(False);
  Result := (Readback and ENABLE_VIRTUAL_TERMINAL_PROCESSING_LOCAL) <> 0;
end;

function DetectIsCI: Boolean;
begin
  Result :=
    EnvEquals('GITHUB_ACTIONS', 'true') or
    EnvDefined('APPVEYOR') or
    EnvEquals('TRAVIS', 'true') or
    EnvEquals('GITLAB_CI', 'true') or
    EnvDefined('JENKINS_URL') or
    EnvDefined('TEAMCITY_VERSION') or
    EnvDefined('BITBUCKET_BUILD_NUMBER') or
    EnvDefined('ContinuaCI.Version') or
    EnvDefined('CI');
end;

function DetectInteractive(IsCI: Boolean): Boolean;
begin
  if IsCI then
    Exit(False);
  Result := StdOutIsConsole;
end;

function DetectAnsiSupport(VTProbeOk: Boolean): Boolean;
begin
  if EnvEquals('CLICOLOR_FORCE', '1') then
    Exit(True);
  if not StdOutIsConsole then
    Exit(False);
  Result := VTProbeOk;
end;

function DetectColorSystem(VTProbeOk: Boolean): TFVColorSystem;
begin
  if EnvDefined('NO_COLOR') then
    Exit(fvcsNoColors);
  if EnvContains('COLORTERM', 'truecolor') or EnvContains('COLORTERM', '24bit') then
    Exit(fvcsTrueColor);
  if EnvContains('TERM', '256color') then
    Exit(fvcsEightBit);
  if VTProbeOk then
    Result := fvcsTrueColor   { Win10+ conhost, WT, ConEmu all do truecolor }
  else
    Result := fvcsLegacy;
end;

function DetectUnicode: Boolean;
begin
  if not StdOutIsConsole then
    Result := GetConsoleOutputCP = 65001
  else
    Result := True;
end;

function DetectHyperlinks(AnsiOk: Boolean): Boolean;
var
  TermProgram, Term: string;
begin
  if not AnsiOk then
    Exit(False);
  if EnvDefined('WT_SESSION') then
    Exit(True);
  TermProgram := LowerCase(GetEnvironmentVariable('TERM_PROGRAM'));
  if (TermProgram = 'iterm.app') or (TermProgram = 'wezterm') or
     (TermProgram = 'vscode') or (TermProgram = 'hyper') or
     (TermProgram = 'tabby') or (TermProgram = 'apple_terminal') then
    Exit(True);
  Term := LowerCase(GetEnvironmentVariable('TERM'));
  if (Pos('xterm-direct', Term) > 0) or
     (Pos('xterm-kitty', Term) > 0) or
     (Pos('truecolor', Term) > 0) then
    Exit(True);
  if EnvDefined('KITTY_WINDOW_ID') then
    Exit(True);
  Result := False;
end;

function DetectSixel(AnsiOk: Boolean): Boolean;
var
  TermProgram, Term: string;
begin
  { Sixel support is rarer than hyperlinks; we widen beyond the
    bare WT_SESSION check FV used previously. }
  if not AnsiOk then
    Exit(False);
  if EnvDefined('WT_SESSION') then
    Exit(True);
  TermProgram := LowerCase(GetEnvironmentVariable('TERM_PROGRAM'));
  if (TermProgram = 'wezterm') or (TermProgram = 'mintty') then
    Exit(True);
  Term := LowerCase(GetEnvironmentVariable('TERM'));
  if (Pos('xterm-kitty', Term) > 0) or (Pos('mlterm', Term) > 0) then
    Exit(True);
  Result := False;
end;

procedure InitFVProfile;
var
  H: THandle;
  VTOk: Boolean;
begin
  H := GetStdHandle(STD_OUTPUT_HANDLE);
  VTOk := ProbeVirtualTerminal(H);

  GProfile.IsCI            := DetectIsCI;
  GProfile.LegacyConsole   := StdOutIsConsole and (not VTOk);
  GProfile.AnsiSupported   := DetectAnsiSupport(VTOk);
  GProfile.Interactive     := DetectInteractive(GProfile.IsCI);
  GProfile.Unicode         := DetectUnicode;
  GProfile.HyperlinkSupport:= DetectHyperlinks(GProfile.AnsiSupported);
  GProfile.SixelSupport    := DetectSixel(GProfile.AnsiSupported);
  GProfile.ColorSystem     := DetectColorSystem(VTOk);

  GInitialized := True;
end;

function GetFVProfile: TFVProfile;
begin
  if not GInitialized then
    InitFVProfile;
  Result := GProfile;
end;

initialization
  FillChar(GProfile, SizeOf(GProfile), 0);
  GProfile.ColorSystem := fvcsNoColors;

end.
