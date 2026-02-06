{*********************************************************}
{                                                         }
{       Free Vision - ComboBox Component                  }
{                                                         }
{       Dropdown select control following the             }
{       THistory/THistoryViewer/THistoryWindow pattern    }
{                                                         }
{*********************************************************}

unit ComboBox;

{$R-}

interface

uses
  System.SysUtils, System.Classes,
  FVCommon, Drivers, Views, Dialogs, FVConsts, FVBoxChars;

const
  CComboViewer = #6#6#7#6#6;    { Same as CHistoryViewer }
  CComboWindow = #19#19#21#24#25#19#20;  { Same as CHistoryWindow }
  CComboBox    = #22#23;         { Same as CHistory }

type
  TComboViewer = class(TListViewer)
  private
    FStrings: TStringList;
  public
    constructor Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
      AStrings: TStringList); reintroduce; virtual;
    function GetPalette: PPalette; override;
    function GetText(Item: Integer; MaxLen: Integer): string; override;
    procedure HandleEvent(var Event: TEvent); override;
  end;

  TComboWindow = class(TWindow)
  private
    FViewer: TComboViewer;
  public
    constructor Create(var Bounds: TRect; AStrings: TStringList); reintroduce; virtual;
    function GetSelection: string;
    function GetPalette: PPalette; override;
    property Viewer: TComboViewer read FViewer;
  end;

  TComboBox = class(TView)
  private
    FLink: TInputLine;
    FStrings: TStringList;
    FDropDownRows: Integer;
  public
    constructor Create(var Bounds: TRect; ALink: TInputLine;
      AStrings: TStringList; ADropDownRows: Integer = 7); reintroduce; virtual;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure NewList(AStrings: TStringList);
    property Link: TInputLine read FLink;
    property Strings: TStringList read FStrings;
  end;

implementation

{***************************************************************************}
{                        TComboViewer Implementation                        }
{***************************************************************************}

constructor TComboViewer.Create(var Bounds: TRect; AHScrollBar, AVScrollBar: TScrollBar;
  AStrings: TStringList);
begin
  inherited Create(Bounds, 1, AHScrollBar, AVScrollBar);
  FStrings := AStrings;
  if FStrings <> nil then
    SetRange(FStrings.Count);
end;

function TComboViewer.GetPalette: PPalette;
const
  P: string[Length(CComboViewer)] = CComboViewer;
begin
  GetPalette := PPalette(@P);
end;

function TComboViewer.GetText(Item: Integer; MaxLen: Integer): string;
begin
  if (FStrings <> nil) and (Item >= 0) and (Item < FStrings.Count) then
    Result := Copy(FStrings[Item], 1, MaxLen)
  else
    Result := '';
end;

procedure TComboViewer.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) then begin
    EndModal(cmOk);
    ClearEvent(Event);
  end else if ((Event.What = evKeyDown) and (Event.KeyCode = kbEsc)) or
              ((Event.What = evCommand) and (Event.Command = cmCancel)) then begin
    EndModal(cmCancel);
    ClearEvent(Event);
  end else
    inherited HandleEvent(Event);
end;

{***************************************************************************}
{                        TComboWindow Implementation                        }
{***************************************************************************}

constructor TComboWindow.Create(var Bounds: TRect; AStrings: TStringList);
var
  R: TRect;
begin
  inherited Create(Bounds, '', wnNoNumber);
  Flags := wfClose;

  GetExtent(R);
  R.Grow(-1, -1);
  FViewer := TComboViewer.Create(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    AStrings);
  if FViewer <> nil then Insert(FViewer);
end;

function TComboWindow.GetSelection: string;
begin
  if FViewer <> nil then
    Result := FViewer.GetText(FViewer.Focused, 255)
  else
    Result := '';
end;

function TComboWindow.GetPalette: PPalette;
const
  P: string[Length(CComboWindow)] = CComboWindow;
begin
  GetPalette := PPalette(@P);
end;

{***************************************************************************}
{                         TComboBox Implementation                          }
{***************************************************************************}

constructor TComboBox.Create(var Bounds: TRect; ALink: TInputLine;
  AStrings: TStringList; ADropDownRows: Integer);
begin
  inherited Create(Bounds);
  Options := Options or ofPostProcess;
  EventMask := EventMask or evBroadcast;
  FLink := ALink;
  FStrings := AStrings;
  FDropDownRows := ADropDownRows;
end;

function TComboBox.GetPalette: PPalette;
const
  P: string[Length(CComboBox)] = CComboBox;
begin
  GetPalette := PPalette(@P);
end;

procedure TComboBox.Draw;
var
  B: TDrawBuffer;
begin
  DrawCStr(B, 0, '[~' + ArrowDown + '~]', GetColor($0102));
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TComboBox.HandleEvent(var Event: TEvent);
var
  C: Word;
  Idx: Integer;
  Rslt: string;
  R, P: TRect;
  ComboWindow: TComboWindow;
begin
  inherited HandleEvent(Event);
  if FLink = nil then Exit;

  if (Event.What = evMouseDown) or
     ((Event.What = evKeyDown) and
      (CtrlToArrow(Event.KeyCode) = kbDown) and
      (FLink.State and sfFocused <> 0)) then begin
    if not FLink.Focus then begin
      ClearEvent(Event);
      Exit;
    end;

    { Calculate popup bounds below the input line }
    FLink.GetBounds(R);
    Dec(R.A.X);
    Inc(R.B.X);
    Inc(R.B.Y, FDropDownRows);
    Dec(R.A.Y, 1);
    Owner.GetExtent(P);
    R.Intersect(P);
    Dec(R.B.Y, 1);

    ComboWindow := TComboWindow.Create(R, FStrings);
    if ComboWindow <> nil then begin
      { Try to pre-select current input value }
      if (FStrings <> nil) and (ComboWindow.Viewer <> nil) then begin
        Idx := FStrings.IndexOf(FLink.Data);
        if Idx >= 0 then
          ComboWindow.Viewer.FocusItem(Idx);
      end;

      C := Owner.ExecView(ComboWindow);
      if C = cmOk then begin
        Rslt := ComboWindow.GetSelection;
        if Length(Rslt) > FLink.MaxLen then
          SetLength(Rslt, FLink.MaxLen);
        FLink.Data := Rslt;
        FLink.SelectAll(True);
        FLink.DrawView;
      end;
      FreeAndNil(ComboWindow);
    end;
    ClearEvent(Event);
  end;
end;

procedure TComboBox.NewList(AStrings: TStringList);
begin
  FStrings := AStrings;
end;

end.
