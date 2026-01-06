{*******************************************************}
{       Free Vision - Message Box Unit                  }
{       Ported to Modern Delphi                         }
{       Converted to CLASS syntax                       }
{*******************************************************}

unit MsgBox;

interface

uses
  System.SysUtils,
  Objects, FVCommon, FVConsts, Drivers, Views, Dialogs;

const
  { Message Box Classes }
  mfWarning      = $0000;
  mfError        = $0001;
  mfInformation  = $0002;
  mfConfirmation = $0003;

  mfInsertInApp  = $0080;

  { Message Box Button Flags }
  mfYesButton    = $0100;
  mfNoButton     = $0200;
  mfOKButton     = $0400;
  mfCancelButton = $0800;

  mfYesNoCancel  = mfYesButton + mfNoButton + mfCancelButton;
  mfOKCancel     = mfOKButton + mfCancelButton;

var
  MsgBoxTitles: array[0..3] of string;

procedure InitMsgBox;
procedure DoneMsgBox;

function MessageBox(const Msg: string; AOptions: Word): Word;

function MessageBoxRect(var R: TRect; const Msg: string;
  AOptions: Word): Word;

function MessageBoxRectDlg(Dlg: TDialog; var R: TRect; const Msg: string;
  AOptions: Word): Word;

function InputBox(const Title, ALabel: string; var S: string;
  Limit: Byte): Word;

function InputBoxRect(var Bounds: TRect; const Title, ALabel: string;
  var S: string; Limit: Byte): Word;

implementation

uses
  App;

const
  Commands: array[0..3] of Word = (cmYes, cmNo, cmOK, cmCancel);

var
  ButtonName: array[0..3] of string;

resourcestring
  sConfirm = 'Confirm';
  sError = 'Error';
  sInformation = 'Information';
  sWarning = 'Warning';
  slYes = '~Y~es';
  slNo = '~N~o';
  slOk = '~O~k';
  slCancel = 'Cancel';

function MessageBox(const Msg: string; AOptions: Word): Word;
var
  R: TRect;
begin
  R.Assign(0, 0, 40, 9);
  if (AOptions and mfInsertInApp = 0) then
    R.Move((Desktop.Size.X - R.B.X) div 2,
      (Desktop.Size.Y - R.B.Y) div 2)
  else
    R.Move((Application.Size.X - R.B.X) div 2,
      (Application.Size.Y - R.B.Y) div 2);
  Result := MessageBoxRect(R, Msg, AOptions);
end;

function MessageBoxRectDlg(Dlg: TDialog; var R: TRect; const Msg: string;
  AOptions: Word): Word;
var
  I, X, ButtonCount: SmallInt;
  Control: TView;
  ButtonList: array[0..4] of TView;
begin
  with Dlg do
  begin
    Control := TStaticText.Create(R, Msg);
    Insert(Control);
    X := -2;
    ButtonCount := 0;
    for I := 0 to 3 do
      if (AOptions and ($0100 shl I) <> 0) then
      begin
        R.Assign(0, 0, 10, 2);
        Control := TButton.Create(R, ButtonName[I], Commands[I], bfNormal);
        Inc(X, Control.Size.X + 2);
        ButtonList[ButtonCount] := Control;
        Inc(ButtonCount);
      end;
    X := (Size.X - X) shr 1;
    if ButtonCount > 0 then
      for I := 0 to ButtonCount - 1 do
      begin
        Control := ButtonList[I];
        Insert(Control);
        Control.MoveTo(X, Size.Y - 3);
        Inc(X, Control.Size.X + 2);
      end;
    SelectNext(False);
  end;
  if (AOptions and mfInsertInApp = 0) then
    Result := Desktop.ExecView(Dlg)
  else
    Result := Application.ExecView(Dlg);
end;

function MessageBoxRect(var R: TRect; const Msg: string;
  AOptions: Word): Word;
var
  Dialog: TDialog;
begin
  Dialog := TDialog.Create(R, MsgBoxTitles[AOptions and $3]);
  with Dialog do
    R.Assign(3, 2, Size.X - 2, Size.Y - 3);
  Result := MessageBoxRectDlg(Dialog, R, Msg, AOptions);
  FreeAndNil(Dialog);
end;

function InputBox(const Title, ALabel: string; var S: string;
  Limit: Byte): Word;
var
  R: TRect;
begin
  R.Assign(0, 0, 60, 8);
  R.Move((Desktop.Size.X - R.B.X) div 2,
    (Desktop.Size.Y - R.B.Y) div 2);
  Result := InputBoxRect(R, Title, ALabel, S, Limit);
end;

function InputBoxRect(var Bounds: TRect; const Title, ALabel: string;
  var S: string; Limit: Byte): Word;
var
  C: Word;
  R: TRect;
  Control: TView;
  Dialog: TDialog;
  InputLine: TInputLine;
  ShortS: ShortString;
begin
  Dialog := TDialog.Create(Bounds, Title);
  with Dialog do
  begin
    R.Assign(4 + CStrLen(ALabel), 2, Size.X - 3, 3);
    InputLine := TInputLine.Create(R, Limit);
    Control := InputLine;
    Insert(Control);
    R.Assign(2, 2, 3 + CStrLen(ALabel), 3);
    Insert(TLabel.Create(R, ALabel, Control));
    R.Assign(Size.X - 24, Size.Y - 4, Size.X - 14, Size.Y - 2);
    Insert(TButton.Create(R, 'O~K~', cmOk, bfDefault));
    Inc(R.A.X, 12);
    Inc(R.B.X, 12);
    Insert(TButton.Create(R, 'Cancel', cmCancel, bfNormal));
    SelectNext(False);
  end;
  { Convert string to ShortString for SetData }
  ShortS := ShortString(Copy(S, 1, Limit));
  InputLine.SetData(ShortS);
  C := Desktop.ExecView(Dialog);
  if C <> cmCancel then begin
    InputLine.GetData(ShortS);
    S := string(ShortS);
  end;
  FreeAndNil(Dialog);
  Result := C;
end;

procedure InitMsgBox;
begin
  ButtonName[0] := slYes;
  ButtonName[1] := slNo;
  ButtonName[2] := slOk;
  ButtonName[3] := slCancel;
  MsgBoxTitles[0] := sWarning;
  MsgBoxTitles[1] := sError;
  MsgBoxTitles[2] := sInformation;
  MsgBoxTitles[3] := sConfirm;
end;

procedure DoneMsgBox;
begin
end;

initialization
  InitMsgBox;
end.
