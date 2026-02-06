{*********************************************************}
{                                                         }
{       Free Vision - ToolBar Component                   }
{                                                         }
{       Horizontal button bar placed between menu bar     }
{       and desktop area                                  }
{                                                         }
{*********************************************************}

unit ToolBar;

{$R-}

interface

uses
  FVCommon, Drivers, Views, FVConsts, FVBoxChars;

const
  { Reuse status line palette - same visual style }
  CToolBar = #2#3#4#5#6#7;

type
  PToolBarItem = ^TToolBarItem;
  TToolBarItem = record
    Next: PToolBarItem;
    Text: string;
    Command: Word;
    HelpCtx: Word;
  end;

  TToolBar = class(TView)
  private
    FItems: PToolBarItem;
    procedure DrawSelect(Selected: PToolBarItem);
    function ItemAtPos(X: Integer): PToolBarItem;
  public
    constructor Create(var Bounds: TRect; AItems: PToolBarItem); reintroduce; virtual;
    destructor Destroy; override;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    property Items: PToolBarItem read FItems;
  end;

function NewToolBarItem(const AText: string; ACommand: Word; AHelpCtx: Word;
  ANext: PToolBarItem): PToolBarItem;
function NewToolBarSeparator(ANext: PToolBarItem): PToolBarItem;

implementation

function NewToolBarItem(const AText: string; ACommand: Word; AHelpCtx: Word;
  ANext: PToolBarItem): PToolBarItem;
var
  T: PToolBarItem;
begin
  New(T);
  T^.Text := AText;
  T^.Command := ACommand;
  T^.HelpCtx := AHelpCtx;
  T^.Next := ANext;
  Result := T;
end;

function NewToolBarSeparator(ANext: PToolBarItem): PToolBarItem;
var
  T: PToolBarItem;
begin
  New(T);
  T^.Text := '';
  T^.Command := 0;
  T^.HelpCtx := hcNoContext;
  T^.Next := ANext;
  Result := T;
end;

{ TToolBar }

constructor TToolBar.Create(var Bounds: TRect; AItems: PToolBarItem);
begin
  inherited Create(Bounds);
  FItems := AItems;
  GrowMode := gfGrowHiX;
  Options := Options or ofPreProcess;
  EventMask := EventMask or evBroadcast;
end;

destructor TToolBar.Destroy;
var
  P, Q: PToolBarItem;
begin
  P := FItems;
  while P <> nil do begin
    Q := P;
    P := P^.Next;
    Dispose(Q);
  end;
  inherited Destroy;
end;

function TToolBar.GetPalette: PPalette;
const
  P: string[Length(CToolBar)] = CToolBar;
begin
  GetPalette := PPalette(@P);
end;

procedure TToolBar.Draw;
begin
  DrawSelect(nil);
end;

procedure TToolBar.DrawSelect(Selected: PToolBarItem);
var
  B: TDrawBuffer;
  T: PToolBarItem;
  I, L: Integer;
  Color, CNormal, CSelect, CNormDisabled, CSelDisabled: Word;
begin
  CNormal := GetColor($0301);
  CSelect := GetColor($0604);
  CNormDisabled := GetColor($0202);
  CSelDisabled := GetColor($0505);

  DrawChar(B, 0, ' ', Byte(CNormal), Size.X);

  T := FItems;
  I := 0;
  while T <> nil do begin
    if T^.Text <> '' then begin
      L := CStrLen(' ' + T^.Text + ' ');
      if I + L >= MaxViewWidth then Break;

      if CommandEnabled(T^.Command) then begin
        if T = Selected then Color := CSelect
        else Color := CNormal;
      end else begin
        if T = Selected then Color := CSelDisabled
        else Color := CNormDisabled;
      end;

      DrawCStr(B, I, ' ' + T^.Text + ' ', Color);
      Inc(I, L);
    end else begin
      { Separator }
      if I < MaxViewWidth then begin
        DrawCell(B, I, BoxVert, Byte(CNormal));
        Inc(I, 1);
      end;
    end;
    T := T^.Next;
  end;

  WriteLine(0, 0, Size.X, 1, B);
end;

function TToolBar.ItemAtPos(X: Integer): PToolBarItem;
var
  T: PToolBarItem;
  Xi, Xn: Integer;
begin
  Result := nil;
  T := FItems;
  Xi := 0;
  while T <> nil do begin
    if T^.Text <> '' then begin
      Xn := Xi + CStrLen(' ' + T^.Text + ' ');
      if (X >= Xi) and (X < Xn) then begin
        Result := T;
        Exit;
      end;
      Xi := Xn;
    end else begin
      Inc(Xi, 1); { Separator width }
    end;
    T := T^.Next;
  end;
end;

procedure TToolBar.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  T, Tt: PToolBarItem;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evMouseDown: begin
      T := nil;
      repeat
        Mouse.X := Event.Where.X - Origin.X;
        Mouse.Y := Event.Where.Y - Origin.Y;
        Tt := ItemAtPos(Mouse.X);
        if T <> Tt then begin
          DrawSelect(Tt);
          T := Tt;
        end;
      until not MouseEvent(Event, evMouseMove);
      if (T <> nil) and (T^.Command <> 0) and CommandEnabled(T^.Command) then begin
        Event.What := evCommand;
        Event.Command := T^.Command;
        Event.InfoPtr := nil;
        PutEvent(Event);
      end;
      ClearEvent(Event);
      DrawSelect(nil);
    end;
    evKeyDown: begin
      { Check for Alt+hotkey }
      T := FItems;
      while T <> nil do begin
        if (T^.Text <> '') and (T^.Command <> 0) and CommandEnabled(T^.Command) then begin
          { Alt+hotkey matching is done by checking the tilde-marked char }
          { For simplicity, toolbar responds to events routed by owner }
        end;
        T := T^.Next;
      end;
    end;
    evBroadcast: begin
      if Event.Command = cmCommandSetChanged then
        DrawView;
    end;
  end;
end;

end.
