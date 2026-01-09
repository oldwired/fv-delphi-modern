{*******************************************************}
{       Free Vision - Toggle Switch Control            }
{       Interactive on/off toggle widget               }
{*******************************************************}

unit ToggleSwitch;

interface

uses
  FVConsts, Objects, Drivers, Views, FVBoxChars;

type
  TToggleSwitchStyle = (
    tsSlider,     { [*---] / [---*] }
    tsCheckbox,   { [ ] / [X] }
    tsBrackets    { [OFF] / [ON ] }
  );

  TToggleSwitch = class(TView)
  private
    FValue: Boolean;
    FCommand: Word;
    FStyle: TToggleSwitchStyle;
    FLabel: string;
    FDownFlag: Boolean;
  public
    constructor Create(var Bounds: TRect; const ALabel: string;
      ACommand: Word; AInitialValue: Boolean = False); reintroduce; virtual;
    function DataSize: Word; override;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Toggle; virtual;
    procedure Press; virtual;
    procedure GetData(var Rec); override;
    procedure SetData(var Rec); override;
    property Value: Boolean read FValue write FValue;
    property Command: Word read FCommand write FCommand;
    property Style: TToggleSwitchStyle read FStyle write FStyle;
    property SwitchLabel: string read FLabel write FLabel;
  end;

const
  idToggleSwitch = 321;
  cmToggleChanged = 310;

  { Palette: same as cluster }
  CToggleSwitch = #16#17#18#18#31#6;

implementation

uses
  System.SysUtils;

{ TToggleSwitch }

constructor TToggleSwitch.Create(var Bounds: TRect; const ALabel: string;
  ACommand: Word; AInitialValue: Boolean);
begin
  inherited Create(Bounds);
  Options := Options or ofSelectable or ofFirstClick or ofPreProcess;
  EventMask := EventMask or evBroadcast;
  FValue := AInitialValue;
  FCommand := ACommand;
  FStyle := tsSlider;
  FLabel := ALabel;
  FDownFlag := False;
end;

function TToggleSwitch.GetPalette: PPalette;
const
  P: ShortString = CToggleSwitch;
begin
  Result := PPalette(@P);
end;

function TToggleSwitch.DataSize: Word;
begin
  Result := SizeOf(Boolean);
end;

procedure TToggleSwitch.GetData(var Rec);
begin
  Boolean(Rec) := FValue;
end;

procedure TToggleSwitch.SetData(var Rec);
begin
  FValue := Boolean(Rec);
  DrawView;
end;

procedure TToggleSwitch.Draw;
var
  B: TDrawBuffer;
  Color, SelColor: Word;
  SwitchStr: string;
  X: Integer;
  I: Integer;
  HotPos: Integer;
  C: Byte;
begin
  { Determine colors based on state }
  if State and sfDisabled <> 0 then
    Color := GetColor($0101)
  else if State and sfFocused <> 0 then
    Color := GetColor($0302)
  else
    Color := GetColor($0201);

  SelColor := GetColor($0403);  { For "on" state highlight }

  { Build switch visual based on style }
  case FStyle of
    tsSlider: begin
      if FValue then
        SwitchStr := '[' + BoxHoriz + BoxHoriz + BoxHoriz + Circle + ']'
      else
        SwitchStr := '[' + Circle + BoxHoriz + BoxHoriz + BoxHoriz + ']';
    end;
    tsCheckbox: begin
      if FValue then
        SwitchStr := '[' + CheckMark + ']'
      else
        SwitchStr := '[ ]';
    end;
    tsBrackets: begin
      if FValue then
        SwitchStr := '[ON ]'
      else
        SwitchStr := '[OFF]';
    end;
  end;

  { Clear buffer }
  DrawChar(B, 0, ' ', Lo(Color), Size.X);

  { Draw switch }
  X := 0;
  if FValue then
    C := Lo(SelColor)
  else
    C := Lo(Color);
  DrawStr(B, X, SwitchStr, C);
  X := Length(SwitchStr);

  { Draw label if present }
  if FLabel <> '' then begin
    Inc(X);  { Space between switch and label }
    { Find hotkey position (marked with ~) }
    HotPos := -1;
    for I := 1 to Length(FLabel) do begin
      if FLabel[I] = '~' then begin
        HotPos := I;
        Break;
      end;
    end;

    { Draw label with hotkey highlighting }
    if HotPos > 0 then begin
      { Draw part before hotkey }
      if HotPos > 1 then begin
        DrawStr(B, X, Copy(FLabel, 1, HotPos - 1), Lo(Color));
        Inc(X, HotPos - 1);
      end;
      { Find end of hotkey }
      for I := HotPos + 1 to Length(FLabel) do begin
        if FLabel[I] = '~' then begin
          { Draw hotkey character }
          DrawStr(B, X, Copy(FLabel, HotPos + 1, I - HotPos - 1), Lo(SelColor));
          Inc(X, I - HotPos - 1);
          { Draw rest }
          if I < Length(FLabel) then begin
            DrawStr(B, X, Copy(FLabel, I + 1, Length(FLabel) - I), Lo(Color));
          end;
          Break;
        end;
      end;
    end
    else begin
      { No hotkey, draw plain label }
      DrawStr(B, X, FLabel, Lo(Color));
    end;
  end;

  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TToggleSwitch.Toggle;
begin
  FValue := not FValue;
  DrawView;
end;

procedure TToggleSwitch.Press;
begin
  Toggle;
  { Broadcast the command - use Self directly (it's already a pointer in CLASS syntax) }
  Message(Owner, evBroadcast, FCommand, Self);
end;

procedure TToggleSwitch.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  HotChar: Char;
  Down: Boolean;

  function GetHotKey: Char;
  var
    J: Integer;
  begin
    Result := #0;
    for J := 1 to Length(FLabel) - 1 do begin
      if FLabel[J] = '~' then begin
        Result := UpCase(FLabel[J + 1]);
        Exit;
      end;
    end;
  end;

begin
  inherited HandleEvent(Event);

  if State and sfDisabled <> 0 then
    Exit;

  case Event.What of
    evMouseDown: begin
      if Event.Buttons and mbLeftButton <> 0 then begin
        MakeLocal(Event.Where, Mouse);
        if MouseInView(Event.Where) then begin
          FDownFlag := True;
          DrawView;
          repeat
            MakeLocal(Event.Where, Mouse);
            Down := MouseInView(Event.Where);
            if Down <> FDownFlag then begin
              FDownFlag := Down;
              DrawView;
            end;
          until not MouseEvent(Event, evMouseMove);

          if FDownFlag then
            Press;

          FDownFlag := False;
          DrawView;
          ClearEvent(Event);
        end;
      end;
    end;

    evKeyDown: begin
      { Space or Enter toggles when focused }
      if (State and sfFocused <> 0) then begin
        if (Event.CharCode = ' ') or (Event.KeyCode = kbEnter) then begin
          Press;
          ClearEvent(Event);
          Exit;
        end;
      end;

      { Check for hotkey in label }
      if FLabel <> '' then begin
        HotChar := GetHotKey;
        if (HotChar <> #0) and (UpCase(Char(Event.CharCode)) = HotChar) then begin
          if not (State and sfFocused <> 0) then
            Select;
          Press;
          ClearEvent(Event);
        end;
      end;
    end;

    evBroadcast: begin
      if Event.Command = cmCommandSetChanged then begin
        SetState(sfDisabled, not CommandEnabled(FCommand));
        DrawView;
      end;
    end;
  end;
end;

end.
