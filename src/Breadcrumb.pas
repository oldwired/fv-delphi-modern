{*********************************************************}
{                                                         }
{       Free Vision - Breadcrumb Navigation Component     }
{                                                         }
{       Horizontal path navigation with clickable         }
{       segments                                          }
{                                                         }
{*********************************************************}

unit Breadcrumb;

{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections,
  FVCommon, Drivers, Views, FVConsts, FVBoxChars;

const
  CBreadcrumb = #6#7#8;  { Normal, Focused/Last, Separator }

type
  TBreadcrumb = class(TView)
  private
    FSegments: TList<string>;
    FFocused: Integer;
    FSeparator: string;
    FCommand: Word;
    function SegmentAtPos(X: Integer): Integer;
  public
    constructor Create(var Bounds: TRect; ACommand: Word = cmBreadcrumbSelect); reintroduce; virtual;
    destructor Destroy; override;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure SetPath(const ASegments: array of string); overload;
    procedure SetPath(const APath: string; ADelimiter: Char = '\'); overload;
    procedure AddSegment(const ASegment: string);
    procedure TruncateTo(AIndex: Integer);
    property Segments: TList<string> read FSegments;
    property Focused: Integer read FFocused write FFocused;
    property Separator: string read FSeparator write FSeparator;
    property Command: Word read FCommand write FCommand;
  end;

implementation

constructor TBreadcrumb.Create(var Bounds: TRect; ACommand: Word);
begin
  inherited Create(Bounds);
  FSegments := TList<string>.Create;
  FFocused := -1;
  FSeparator := ' ' + SmallArrowRight + ' ';
  FCommand := ACommand;
  Options := Options or ofSelectable;
  EventMask := EventMask or evBroadcast;
  GrowMode := gfGrowHiX;
end;

destructor TBreadcrumb.Destroy;
begin
  FSegments.Free;
  inherited Destroy;
end;

function TBreadcrumb.GetPalette: PPalette;
const
  P: string[Length(CBreadcrumb)] = CBreadcrumb;
begin
  GetPalette := PPalette(@P);
end;

procedure TBreadcrumb.Draw;
var
  B: TDrawBuffer;
  NormalColor, FocusedColor, SepColor: Byte;
  I, X: Integer;
  S: string;
begin
  NormalColor := GetColor(1);
  FocusedColor := GetColor(2);
  SepColor := GetColor(3);

  DrawChar(B, 0, ' ', NormalColor, Size.X);

  X := 0;
  for I := 0 to FSegments.Count - 1 do begin
    { Draw separator before each segment except the first }
    if I > 0 then begin
      DrawStr(B, X, FSeparator, SepColor);
      Inc(X, Length(FSeparator));
    end;
    { Draw segment text - highlight if focused or last }
    S := FSegments[I];
    if (I = FFocused) or (I = FSegments.Count - 1) then
      DrawStr(B, X, S, FocusedColor)
    else
      DrawStr(B, X, S, NormalColor);
    Inc(X, Length(S));
    if X >= Size.X then Break;
  end;

  WriteLine(0, 0, Size.X, Size.Y, B);
end;

function TBreadcrumb.SegmentAtPos(X: Integer): Integer;
var
  I, CurX, SegEnd: Integer;
begin
  Result := -1;
  CurX := 0;
  for I := 0 to FSegments.Count - 1 do begin
    if I > 0 then
      Inc(CurX, Length(FSeparator));
    SegEnd := CurX + Length(FSegments[I]);
    if (X >= CurX) and (X < SegEnd) then begin
      Result := I;
      Exit;
    end;
    CurX := SegEnd;
  end;
end;

procedure TBreadcrumb.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  Idx: Integer;
begin
  inherited HandleEvent(Event);

  case Event.What of
    evMouseDown: begin
      MakeLocal(Event.Where, Mouse);
      Idx := SegmentAtPos(Mouse.X);
      if Idx >= 0 then begin
        FFocused := Idx;
        DrawView;
        Message(Owner, evBroadcast, FCommand, Pointer(NativeInt(Idx)));
        ClearEvent(Event);
      end;
    end;
    evKeyDown: begin
      if State and sfFocused <> 0 then begin
        case CtrlToArrow(Event.KeyCode) of
          kbLeft: begin
            if FFocused > 0 then Dec(FFocused)
            else FFocused := FSegments.Count - 1;
            DrawView;
            ClearEvent(Event);
          end;
          kbRight: begin
            if FFocused < FSegments.Count - 1 then Inc(FFocused)
            else FFocused := 0;
            DrawView;
            ClearEvent(Event);
          end;
          kbEnter: begin
            if FFocused >= 0 then
              Message(Owner, evBroadcast, FCommand, Pointer(NativeInt(FFocused)));
            ClearEvent(Event);
          end;
        end;
      end;
    end;
  end;
end;

procedure TBreadcrumb.SetPath(const ASegments: array of string);
var
  I: Integer;
begin
  FSegments.Clear;
  for I := Low(ASegments) to High(ASegments) do
    FSegments.Add(ASegments[I]);
  if FSegments.Count > 0 then
    FFocused := FSegments.Count - 1
  else
    FFocused := -1;
  DrawView;
end;

procedure TBreadcrumb.SetPath(const APath: string; ADelimiter: Char);
var
  Parts: TArray<string>;
  I: Integer;
begin
  FSegments.Clear;
  Parts := APath.Split([ADelimiter], TStringSplitOptions.ExcludeEmpty);
  for I := 0 to High(Parts) do
    FSegments.Add(Parts[I]);
  if FSegments.Count > 0 then
    FFocused := FSegments.Count - 1
  else
    FFocused := -1;
  DrawView;
end;

procedure TBreadcrumb.AddSegment(const ASegment: string);
begin
  FSegments.Add(ASegment);
  FFocused := FSegments.Count - 1;
  DrawView;
end;

procedure TBreadcrumb.TruncateTo(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FSegments.Count) then begin
    while FSegments.Count > AIndex + 1 do
      FSegments.Delete(FSegments.Count - 1);
    FFocused := FSegments.Count - 1;
    DrawView;
  end;
end;

end.
