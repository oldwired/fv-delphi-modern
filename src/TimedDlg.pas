{*******************************************************}
{       Free Vision - Timed Dialogs Unit               }
{       Ported to Modern Delphi                        }
{*******************************************************}

{
  Timed dialogs that automatically close after a specified
  number of seconds. Useful for splash screens, auto-timeout
  message boxes, etc.
}

unit TimedDlg;

interface

uses
  System.SysUtils,
  Objects, FVConsts, FVCommon, Dialogs, Drivers, Views;

type
  TTimedDialog = class(TDialog)
  private
    FSecs: LongInt;
    FSecs0: LongInt;
    FSecs2: LongInt;
    FDayWrap: Boolean;
  public
    constructor Create(var Bounds: TRect; ATitle: TTitleStr; ASecs: Word); reintroduce; virtual;
    constructor Load(var S: TFVStream); override;
    procedure GetEvent(var Event: TEvent); override;
    procedure Store(var S: TFVStream);
    property Secs: LongInt read FSecs write FSecs;
  end;

  { Must be always included in TTimedDialog! }
  TTimedDialogText = class(TStaticText)
  public
    constructor Create(var Bounds: TRect); reintroduce; virtual;
    procedure GetText(var S: string); override;
  end;

const
  RTimedDialog: TStreamRec = (
    ObjType: idTimedDialog;
    VmtLink: nil;
    Load: @TTimedDialog.Load;
    Store: @TTimedDialog.Store
  );

  RTimedDialogText: TStreamRec = (
    ObjType: idTimedDialogText;
    VmtLink: nil;
    Load: @TTimedDialogText.Load;
    Store: @TTimedDialogText.Store
  );

procedure RegisterTimedDialog;

function TimedMessageBox(const Msg: string;
  AOptions: Word; ASecs: Word): Word;

function TimedMessageBoxRect(var R: TRect; const Msg: string;
  AOptions: Word; ASecs: Word): Word;

implementation

uses
  Time, App, MsgBox;

{ TTimedDialogText }

constructor TTimedDialogText.Create(var Bounds: TRect);
begin
  inherited Create(Bounds, '');
end;

procedure TTimedDialogText.GetText(var S: string);
begin
  if Owner <> nil then
    S := #3 + IntToStr(TTimedDialog(Owner).Secs)  { #3 = center text }
  else
    S := '';
end;

{ TTimedDialog }

constructor TTimedDialog.Create(var Bounds: TRect; ATitle: TTitleStr;
  ASecs: Word);
var
  H, M, Sec, S100: Word;
begin
  inherited Create(Bounds, ATitle);
  GetTime(H, M, Sec, S100);
  FSecs0 := H * 3600 + M * 60 + Sec;
  FSecs2 := FSecs0 + ASecs;
  FSecs := ASecs;
  FDayWrap := FSecs2 > 24 * 3600;
end;

procedure TTimedDialog.GetEvent(var Event: TEvent);
var
  H, M, Sec, S100: Word;
  Secs1: LongInt;
begin
  inherited GetEvent(Event);
  GetTime(H, M, Sec, S100);
  Secs1 := H * 3600 + M * 60 + Sec;
  if FDayWrap then Inc(Secs1, 24 * 3600);
  if FSecs2 - Secs1 <> FSecs then
  begin
    FSecs := FSecs2 - Secs1;
    if FSecs < 0 then
      FSecs := 0;
    { If remaining seconds are displayed in one of included views, update them. }
    Redraw;
  end;
  with Event do
    if (FSecs = 0) and (What = evNothing) then
    begin
      What := evCommand;
      Command := cmCancel;
    end;
end;

constructor TTimedDialog.Load(var S: TFVStream);
begin
  inherited Load(S);
  S.Read(FSecs, SizeOf(FSecs));
  S.Read(FSecs0, SizeOf(FSecs0));
  S.Read(FSecs2, SizeOf(FSecs2));
  S.Read(FDayWrap, SizeOf(FDayWrap));
end;

procedure TTimedDialog.Store(var S: TFVStream);
begin
  inherited Store(S);
  S.Write(FSecs, SizeOf(FSecs));
  S.Write(FSecs0, SizeOf(FSecs0));
  S.Write(FSecs2, SizeOf(FSecs2));
  S.Write(FDayWrap, SizeOf(FDayWrap));
end;

{ Helper functions }

function TimedMessageBox(const Msg: string;
  AOptions: Word; ASecs: Word): Word;
var
  R: TRect;
begin
  R.Assign(0, 0, 40, 10);
  if (AOptions and mfInsertInApp) = 0 then
    R.Move((Desktop.Size.X - R.B.X) div 2,
           (Desktop.Size.Y - R.B.Y) div 2)
  else
    R.Move((Application.Size.X - R.B.X) div 2,
           (Application.Size.Y - R.B.Y) div 2);
  Result := TimedMessageBoxRect(R, Msg, AOptions, ASecs);
end;

function TimedMessageBoxRect(var R: TRect; const Msg: string;
  AOptions: Word; ASecs: Word): Word;
var
  Dlg: TTimedDialog;
  TimedText: TTimedDialogText;
  TextR: TRect;
begin
  Dlg := TTimedDialog.Create(R, MsgBoxTitles[AOptions and $3], ASecs);
  with Dlg do
  begin
    TextR.Assign(3, Size.Y - 5, Size.X - 2, Size.Y - 4);
    TimedText := TTimedDialogText.Create(TextR);
    Insert(TimedText);
    TextR.Assign(3, 2, Size.X - 2, Size.Y - 5);
  end;
  Result := MessageBoxRectDlg(Dlg, TextR, Msg, AOptions);
  FreeAndNil(Dlg);
end;

procedure RegisterTimedDialog;
begin
  RegisterType(RTimedDialog);
  RegisterType(RTimedDialogText);
end;

end.
