{*******************************************************}
{       Free Vision FuzzyFinder Widget                  }
{       VS Code Ctrl+P style overlay dialog             }
{*******************************************************}

unit FuzzyFinder;

{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.Generics.Defaults,
  FVCommon, Drivers, Views, Dialogs, FVConsts, FVScreen;

const
  cmFuzzySelect = 723;

type
  TFuzzyMatch = record
    Index: Integer;
    Score: Integer;
  end;

  TFuzzyFinder = class;

  TFuzzyListViewer = class(TListViewer)
  private
    FFinder: TFuzzyFinder;
  public
    constructor Create(var Bounds: TRect; AVScrollBar: TScrollBar;
      AFinder: TFuzzyFinder); reintroduce; virtual;
    function GetText(Item: Integer; MaxLen: Integer): string; override;
    procedure HandleEvent(var Event: TEvent); override;
  end;

  TFuzzyFinder = class(TDialog)
  private
    FInputLine: TInputLine;
    FListViewer: TFuzzyListViewer;
    FItems: TStringList;
    FMatches: TList<TFuzzyMatch>;
    FLastFilter: string;
    FSelectedIndex: Integer;
    procedure UpdateMatches;
  public
    constructor Create(const ATitle: string; AItems: TStringList;
      AMaxVisible: Integer = 12); reintroduce;
    destructor Destroy; override;
    procedure HandleEvent(var Event: TEvent); override;
    function GetSelectedItem: string;
    class function FuzzyScore(const Pattern, Text: string): Integer; static;
    property SelectedIndex: Integer read FSelectedIndex;
  end;

implementation

{ Fuzzy scoring algorithm }

class function TFuzzyFinder.FuzzyScore(const Pattern, Text: string): Integer;
var
  PI, TI: Integer;
  PLen, TLen: Integer;
  LPattern, LText: string;
  Consecutive: Integer;
  PrevMatch: Boolean;
begin
  Result := 0;
  PLen := Length(Pattern);
  TLen := Length(Text);
  if PLen = 0 then begin
    Result := 1;
    Exit;
  end;
  if TLen = 0 then begin
    Result := -1;
    Exit;
  end;

  LPattern := LowerCase(Pattern);
  LText := LowerCase(Text);

  PI := 1;
  Consecutive := 0;
  PrevMatch := False;
  for TI := 1 to TLen do begin
    if PI > PLen then Break;
    if LText[TI] = LPattern[PI] then begin
      Inc(Result, 10);
      { Consecutive match bonus }
      if PrevMatch then begin
        Inc(Consecutive);
        Inc(Result, Consecutive * 5);
      end else
        Consecutive := 0;
      { Word start bonus (after space, separator, or at position 1) }
      if (TI = 1) or CharInSet(Text[TI - 1], [' ', '.', '_', '-', '/', '\']) then
        Inc(Result, 20);
      { Exact case match bonus }
      if Text[TI] = Pattern[PI] then
        Inc(Result, 5);
      PrevMatch := True;
      Inc(PI);
    end else begin
      PrevMatch := False;
      Consecutive := 0;
    end;
  end;

  { All pattern chars must be found }
  if PI <= PLen then
    Result := -1
  else begin
    { Bonus for shorter matches (closer to pattern length) }
    if TLen > 0 then
      Inc(Result, (PLen * 100) div TLen);
  end;
end;

{ TFuzzyListViewer }

constructor TFuzzyListViewer.Create(var Bounds: TRect; AVScrollBar: TScrollBar;
  AFinder: TFuzzyFinder);
begin
  inherited Create(Bounds, 1, nil, AVScrollBar);
  FFinder := AFinder;
end;

function TFuzzyListViewer.GetText(Item: Integer; MaxLen: Integer): string;
var
  Idx: Integer;
begin
  if (FFinder <> nil) and (Item >= 0) and (Item < FFinder.FMatches.Count) then begin
    Idx := FFinder.FMatches[Item].Index;
    if (Idx >= 0) and (Idx < FFinder.FItems.Count) then begin
      Result := Copy(FFinder.FItems[Idx], 1, MaxLen);
      Exit;
    end;
  end;
  Result := '';
end;

procedure TFuzzyListViewer.HandleEvent(var Event: TEvent);
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

{ TFuzzyFinder }

constructor TFuzzyFinder.Create(const ATitle: string; AItems: TStringList;
  AMaxVisible: Integer);
var
  R: TRect;
  W, H: Integer;
  VSB: TScrollBar;
begin
  W := (ScreenWidth * 3) div 5;
  if W < 30 then W := 30;
  if W > ScreenWidth - 4 then W := ScreenWidth - 4;
  H := AMaxVisible + 4;  { input line + frame + list }
  if H > ScreenHeight - 4 then H := ScreenHeight - 4;

  R.Assign(
    (ScreenWidth - W) div 2,
    2,
    (ScreenWidth + W) div 2,
    2 + H);

  inherited Create(R, ATitle);

  FItems := AItems;
  FMatches := TList<TFuzzyMatch>.Create;
  FLastFilter := '';
  FSelectedIndex := -1;

  { Input line at top }
  GetExtent(R);
  R.Assign(R.A.X + 2, R.A.Y + 1, R.B.X - 2, R.A.Y + 2);
  FInputLine := TInputLine.Create(R, 255);
  Insert(FInputLine);

  { Scrollbar }
  GetExtent(R);
  R.Assign(R.B.X - 2, R.A.Y + 2, R.B.X - 1, R.B.Y - 1);
  VSB := TScrollBar.Create(R);
  Insert(VSB);

  { List viewer }
  GetExtent(R);
  R.Assign(R.A.X + 1, R.A.Y + 2, R.B.X - 2, R.B.Y - 1);
  FListViewer := TFuzzyListViewer.Create(R, VSB, Self);
  Insert(FListViewer);

  { Initial match: show all }
  UpdateMatches;

  FInputLine.Select;
end;

destructor TFuzzyFinder.Destroy;
begin
  FMatches.Free;
  inherited;
end;

procedure TFuzzyFinder.UpdateMatches;
var
  I, Score: Integer;
  Match: TFuzzyMatch;
  Pattern: string;
begin
  Pattern := FInputLine.Data;
  FMatches.Clear;

  if FItems <> nil then begin
    for I := 0 to FItems.Count - 1 do begin
      Score := FuzzyScore(Pattern, FItems[I]);
      if Score >= 0 then begin
        Match.Index := I;
        Match.Score := Score;
        FMatches.Add(Match);
      end;
    end;
  end;

  { Sort by score descending }
  FMatches.Sort(TComparer<TFuzzyMatch>.Construct(
    function(const A, B: TFuzzyMatch): Integer
    begin
      Result := B.Score - A.Score;
    end));

  FListViewer.SetRange(FMatches.Count);
  if FListViewer.Focused >= FMatches.Count then
    FListViewer.FocusItem(0);
  FListViewer.DrawView;
end;

procedure TFuzzyFinder.HandleEvent(var Event: TEvent);
begin
  { Intercept Up/Down in input line to move list focus }
  if (Event.What = evKeyDown) then begin
    case Event.KeyCode of
      kbUp:
        if FInputLine.State and sfFocused <> 0 then begin
          if FListViewer.Focused > 0 then
            FListViewer.FocusItem(FListViewer.Focused - 1);
          FListViewer.DrawView;
          ClearEvent(Event);
          Exit;
        end;
      kbDown:
        if FInputLine.State and sfFocused <> 0 then begin
          if FListViewer.Focused < FMatches.Count - 1 then
            FListViewer.FocusItem(FListViewer.Focused + 1);
          FListViewer.DrawView;
          ClearEvent(Event);
          Exit;
        end;
      kbEnter:
        begin
          if FMatches.Count > 0 then
            FSelectedIndex := FMatches[FListViewer.Focused].Index
          else
            FSelectedIndex := -1;
          EndModal(cmOk);
          ClearEvent(Event);
          Exit;
        end;
      kbEsc:
        begin
          FSelectedIndex := -1;
          EndModal(cmCancel);
          ClearEvent(Event);
          Exit;
        end;
    end;
  end;

  inherited HandleEvent(Event);

  { After inherited processing, check if input changed }
  if FInputLine.Data <> FLastFilter then begin
    FLastFilter := FInputLine.Data;
    UpdateMatches;
  end;
end;

function TFuzzyFinder.GetSelectedItem: string;
begin
  if (FSelectedIndex >= 0) and (FItems <> nil) and (FSelectedIndex < FItems.Count) then
    Result := FItems[FSelectedIndex]
  else
    Result := '';
end;

end.
