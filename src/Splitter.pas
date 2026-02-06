{*********************************************************}
{                                                         }
{       Free Vision - Splitter Component                  }
{                                                         }
{       Draggable divider between two panels with         }
{       TSplitGroup convenience container                 }
{                                                         }
{*********************************************************}

unit Splitter;

{$R-}

interface

uses
  System.SysUtils,
  FVCommon, Drivers, Views, FVConsts, FVBoxChars;

const
  CSplitter = #6#7;  { Normal bar, Handle/highlight }

type
  TSplitOrientation = (soHorizontal, soVertical);

  TSplitter = class(TView)
  private
    FOrientation: TSplitOrientation;
    FPanel1: TView;
    FPanel2: TView;
    FMinPanel1: Integer;
    FMinPanel2: Integer;
    procedure AdjustPanels(Delta: Integer);
  public
    constructor Create(var Bounds: TRect; AOrientation: TSplitOrientation;
      APanel1, APanel2: TView; AMinPanel1: Integer = 2;
      AMinPanel2: Integer = 2); reintroduce; virtual;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    property Orientation: TSplitOrientation read FOrientation;
    property Panel1: TView read FPanel1 write FPanel1;
    property Panel2: TView read FPanel2 write FPanel2;
    property MinPanel1: Integer read FMinPanel1 write FMinPanel1;
    property MinPanel2: Integer read FMinPanel2 write FMinPanel2;
  end;

  TSplitGroup = class(TGroup)
  private
    FOrientation: TSplitOrientation;
    FSplitPos: Integer;
    FPanel1: TView;
    FPanel2: TView;
    FSplitter: TSplitter;
    procedure RecalcLayout;
  public
    constructor Create(var Bounds: TRect; AOrientation: TSplitOrientation;
      ASplitPos: Integer); reintroduce; virtual;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure SetPanel1(AView: TView);
    procedure SetPanel2(AView: TView);
    procedure ChangeBounds(var Bounds: TRect); override;
    property Orientation: TSplitOrientation read FOrientation;
    property SplitPos: Integer read FSplitPos write FSplitPos;
    property Splitter: TSplitter read FSplitter;
  end;

implementation

{***************************************************************************}
{                         TSplitter Implementation                          }
{***************************************************************************}

constructor TSplitter.Create(var Bounds: TRect; AOrientation: TSplitOrientation;
  APanel1, APanel2: TView; AMinPanel1, AMinPanel2: Integer);
begin
  inherited Create(Bounds);
  FOrientation := AOrientation;
  FPanel1 := APanel1;
  FPanel2 := APanel2;
  FMinPanel1 := AMinPanel1;
  FMinPanel2 := AMinPanel2;
  Options := Options or ofSelectable;
  EventMask := EventMask or evBroadcast;
end;

function TSplitter.GetPalette: PPalette;
const
  P: string[Length(CSplitter)] = CSplitter;
begin
  GetPalette := PPalette(@P);
end;

procedure TSplitter.Draw;
var
  B: TDrawBuffer;
  Color, HandleColor: Byte;
  I, Mid: Integer;
begin
  Color := GetColor(1);
  HandleColor := GetColor(2);

  if FOrientation = soHorizontal then begin
    { Horizontal splitter = full-width row }
    DrawChar(B, 0, BoxHoriz, Color, Size.X);
    { Diamond handle in center }
    Mid := Size.X div 2;
    if Mid < Size.X then
      DrawCell(B, Mid, Diamond, HandleColor);
    WriteLine(0, 0, Size.X, 1, B);
  end else begin
    { Vertical splitter = column of vertical bars }
    Mid := Size.Y div 2;
    for I := 0 to Size.Y - 1 do begin
      if I = Mid then
        DrawCell(B, 0, Diamond, HandleColor)
      else
        DrawCell(B, 0, BoxVert, Color);
      WriteLine(0, I, 1, 1, B);
    end;
  end;
end;

procedure TSplitter.AdjustPanels(Delta: Integer);
var
  R: TRect;
  P1Size, P2Size, TotalSpace: Integer;
begin
  if (FPanel1 = nil) or (FPanel2 = nil) or (Owner = nil) then Exit;

  if FOrientation = soHorizontal then begin
    P1Size := FPanel1.Size.Y + Delta;
    TotalSpace := FPanel1.Size.Y + FPanel2.Size.Y;
    P2Size := TotalSpace - P1Size;

    if P1Size < FMinPanel1 then begin P1Size := FMinPanel1; P2Size := TotalSpace - P1Size; end;
    if P2Size < FMinPanel2 then begin P2Size := FMinPanel2; P1Size := TotalSpace - P2Size; end;
    if (P1Size < FMinPanel1) or (P2Size < FMinPanel2) then Exit;

    { Resize Panel1 }
    FPanel1.GetBounds(R);
    R.B.Y := R.A.Y + P1Size;
    FPanel1.ChangeBounds(R);

    { Move/resize splitter }
    GetBounds(R);
    R.A.Y := FPanel1.Origin.Y + P1Size;
    R.B.Y := R.A.Y + 1;
    ChangeBounds(R);

    { Move/resize Panel2 }
    FPanel2.GetBounds(R);
    R.A.Y := Origin.Y + 1;
    R.B.Y := R.A.Y + P2Size;
    FPanel2.ChangeBounds(R);
  end else begin
    P1Size := FPanel1.Size.X + Delta;
    TotalSpace := FPanel1.Size.X + FPanel2.Size.X;
    P2Size := TotalSpace - P1Size;

    if P1Size < FMinPanel1 then begin P1Size := FMinPanel1; P2Size := TotalSpace - P1Size; end;
    if P2Size < FMinPanel2 then begin P2Size := FMinPanel2; P1Size := TotalSpace - P2Size; end;
    if (P1Size < FMinPanel1) or (P2Size < FMinPanel2) then Exit;

    { Resize Panel1 }
    FPanel1.GetBounds(R);
    R.B.X := R.A.X + P1Size;
    FPanel1.ChangeBounds(R);

    { Move/resize splitter }
    GetBounds(R);
    R.A.X := FPanel1.Origin.X + P1Size;
    R.B.X := R.A.X + 1;
    ChangeBounds(R);

    { Move/resize Panel2 }
    FPanel2.GetBounds(R);
    R.A.X := Origin.X + 1;
    R.B.X := R.A.X + P2Size;
    FPanel2.ChangeBounds(R);
  end;

  { Redraw entire owner to clear artefacts from old positions }
  if Owner <> nil then begin
    Owner.DrawView;
    Message(Owner, evBroadcast, cmSplitterMoved, @Self);
  end;
end;

procedure TSplitter.HandleEvent(var Event: TEvent);
var
  Mouse, Last: TPoint;
  Delta: Integer;
begin
  inherited HandleEvent(Event);

  case Event.What of
    evMouseDown: begin
      MakeLocal(Event.Where, Last);
      repeat
        MakeLocal(Event.Where, Mouse);
        if FOrientation = soHorizontal then
          Delta := Mouse.Y - Last.Y
        else
          Delta := Mouse.X - Last.X;
        if Delta <> 0 then begin
          AdjustPanels(Delta);
          Last := Mouse;
        end;
      until not MouseEvent(Event, evMouseMove);
      ClearEvent(Event);
    end;
    evKeyDown: begin
      if State and sfFocused <> 0 then begin
        case CtrlToArrow(Event.KeyCode) of
          kbUp: if FOrientation = soHorizontal then begin AdjustPanels(-1); ClearEvent(Event); end;
          kbDown: if FOrientation = soHorizontal then begin AdjustPanels(1); ClearEvent(Event); end;
          kbLeft: if FOrientation = soVertical then begin AdjustPanels(-1); ClearEvent(Event); end;
          kbRight: if FOrientation = soVertical then begin AdjustPanels(1); ClearEvent(Event); end;
        end;
      end;
    end;
  end;
end;

{***************************************************************************}
{                        TSplitGroup Implementation                         }
{***************************************************************************}

constructor TSplitGroup.Create(var Bounds: TRect; AOrientation: TSplitOrientation;
  ASplitPos: Integer);
begin
  inherited Create(Bounds);
  FOrientation := AOrientation;
  FSplitPos := ASplitPos;
  FPanel1 := nil;
  FPanel2 := nil;
  FSplitter := nil;
end;

function TSplitGroup.GetPalette: PPalette;
begin
  Result := nil;  { Use owner's palette }
end;

procedure TSplitGroup.Draw;
var
  B: TDrawBuffer;
  Y: Integer;
  Color: Byte;
begin
  { Clear background to prevent artefacts when panels resize }
  Color := GetColor(1);
  if Color = 0 then Color := $07;  { Fallback: white on black }
  for Y := 0 to Size.Y - 1 do begin
    DrawChar(B, 0, ' ', Color, Size.X);
    WriteLine(0, Y, Size.X, 1, B);
  end;
  { Now draw all child views on top }
  inherited Draw;
end;

procedure TSplitGroup.SetPanel1(AView: TView);
begin
  if FPanel1 <> nil then Delete(FPanel1);
  FPanel1 := AView;
  if FPanel1 <> nil then Insert(FPanel1);
  RecalcLayout;
end;

procedure TSplitGroup.SetPanel2(AView: TView);
begin
  if FPanel2 <> nil then Delete(FPanel2);
  FPanel2 := AView;
  if FPanel2 <> nil then Insert(FPanel2);
  RecalcLayout;
end;

procedure TSplitGroup.RecalcLayout;
var
  R: TRect;
begin
  if (FPanel1 = nil) or (FPanel2 = nil) then Exit;

  { Remove old splitter }
  if FSplitter <> nil then begin
    Delete(FSplitter);
    FreeAndNil(FSplitter);
  end;

  if FOrientation = soHorizontal then begin
    { Panel1 at top }
    R.Assign(0, 0, Size.X, FSplitPos);
    FPanel1.ChangeBounds(R);

    { Splitter row }
    R.Assign(0, FSplitPos, Size.X, FSplitPos + 1);
    FSplitter := TSplitter.Create(R, soHorizontal, FPanel1, FPanel2);
    Insert(FSplitter);

    { Panel2 at bottom }
    R.Assign(0, FSplitPos + 1, Size.X, Size.Y);
    FPanel2.ChangeBounds(R);
  end else begin
    { Panel1 at left }
    R.Assign(0, 0, FSplitPos, Size.Y);
    FPanel1.ChangeBounds(R);

    { Splitter column }
    R.Assign(FSplitPos, 0, FSplitPos + 1, Size.Y);
    FSplitter := TSplitter.Create(R, soVertical, FPanel1, FPanel2);
    Insert(FSplitter);

    { Panel2 at right }
    R.Assign(FSplitPos + 1, 0, Size.X, Size.Y);
    FPanel2.ChangeBounds(R);
  end;
end;

procedure TSplitGroup.ChangeBounds(var Bounds: TRect);
var
  OldW, OldH, NewW, NewH: Integer;
begin
  OldW := Size.X;
  OldH := Size.Y;
  inherited ChangeBounds(Bounds);
  NewW := Size.X;
  NewH := Size.Y;

  { Adjust split position proportionally }
  if (FPanel1 <> nil) and (FPanel2 <> nil) then begin
    if FOrientation = soHorizontal then begin
      if OldH > 0 then
        FSplitPos := (FSplitPos * NewH) div OldH;
      if FSplitPos < 2 then FSplitPos := 2;
      if FSplitPos >= NewH - 2 then FSplitPos := NewH - 3;
    end else begin
      if OldW > 0 then
        FSplitPos := (FSplitPos * NewW) div OldW;
      if FSplitPos < 2 then FSplitPos := 2;
      if FSplitPos >= NewW - 2 then FSplitPos := NewW - 3;
    end;
    RecalcLayout;
  end;
end;

end.
