{*********************************************************}
{                                                         }
{       Free Vision - Headless Mode Switches              }
{                                                         }
{       Lets the application run without a real Windows   }
{       console (no STD_OUTPUT/INPUT, no VT mode, no      }
{       alternate-buffer escape sequences). Used by the   }
{       DUnitX test rig to drive golden-file snapshots.   }
{                                                         }
{       Activation order:                                  }
{         FVHeadless.RequestHeadless(W, H);                }
{         (then) Screen.Init / Application.Init           }
{                                                         }
{       RequestHeadless also forces a deterministic       }
{       FVProfile so VT emission is identical across      }
{       hosts (NoColors, no Sixel, no hyperlink).          }
{                                                         }
{*********************************************************}

unit FVHeadless;

interface

{ Mark the process as headless and remember the requested screen size.
  Must be called before Screen.Init / TApplication.Create. Idempotent. }
procedure RequestHeadless(W: Integer = 80; H: Integer = 25);

{ Leave headless mode (test teardown). Does not touch the live screen. }
procedure LeaveHeadless;

function IsHeadless: Boolean;
procedure GetRequestedSize(out W, H: Integer);

{ VT capture is OFF by default: in headless mode FlushVT discards the VT byte
  stream so nothing leaks to whatever the test runner's stdout happens to be.
  Enable capture to accumulate those bytes for inspection via TakeCapture.
  (TGoldenSession.StartScreen enables it so SnapshotVTCapture has data.) }
procedure EnableVTCapture;
procedure DisableVTCapture;
function  CaptureVTEnabled: Boolean;

procedure AppendCapture(const S: string);
function  TakeCapture: string;
procedure ClearCapture;

implementation

uses
  System.SysUtils, FVProfile;

var
  GHeadless    : Boolean = False;
  GWidth       : Integer = 80;
  GHeight      : Integer = 25;
  GCapture     : Boolean = False;
  GCaptureBuf  : TStringBuilder = nil;  { created in initialization }

procedure RequestHeadless(W: Integer = 80; H: Integer = 25);
begin
  if W < 10 then W := 10;
  if H < 5  then H := 5;
  GHeadless := True;
  GWidth    := W;
  GHeight   := H;
  GCaptureBuf.Clear;
  FVProfile.ForceDeterministicProfile;
end;

procedure LeaveHeadless;
begin
  GHeadless := False;
  GCapture  := False;
  GCaptureBuf.Clear;
  { Symmetric with RequestHeadless's ForceDeterministicProfile: release the
    pin so a later non-headless run re-detects the real terminal instead of
    staying stuck on NoColors/AnsiSupported=False. }
  FVProfile.UnpinFVProfile;
end;

function IsHeadless: Boolean;
begin
  Result := GHeadless;
end;

procedure GetRequestedSize(out W, H: Integer);
begin
  W := GWidth;
  H := GHeight;
end;

procedure EnableVTCapture;
begin
  GCapture := True;
end;

procedure DisableVTCapture;
begin
  GCapture := False;
end;

function CaptureVTEnabled: Boolean;
begin
  Result := GCapture;
end;

procedure AppendCapture(const S: string);
begin
  if GCapture and (S <> '') then
    GCaptureBuf.Append(S);
end;

function TakeCapture: string;
begin
  Result := GCaptureBuf.ToString;
  GCaptureBuf.Clear;
end;

procedure ClearCapture;
begin
  GCaptureBuf.Clear;
end;

initialization
  GCaptureBuf := TStringBuilder.Create;

finalization
  GCaptureBuf.Free;

end.
