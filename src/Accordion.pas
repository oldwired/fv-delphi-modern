{*********************************************************}
{                                                         }
{       Free Vision - Accordion Component                 }
{                                                         }
{       Vertical stack of collapsible sections            }
{                                                         }
{*********************************************************}

unit Accordion;

{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections,
  FVCommon, Drivers, Views, FVConsts, FVBoxChars;

const
  CAccordionHeader = #7#8#9#6#8;  { Normal, Focused, Shortcut, Content bg, Arrow }

type
  TAccordionMode = (amMultiple, amExclusive);

  TAccordionHeader = class(TView)
  private
    FTitle: string;
    FExpanded: Boolean;
    FSectionIndex: Integer;
  public
    constructor Create(var Bounds: TRect; const ATitle: string;
      AExpanded: Boolean; ASectionIndex: Integer); reintroduce; virtual;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    property Title: string read FTitle write FTitle;
    property Expanded: Boolean read FExpanded write FExpanded;
    property SectionIndex: Integer read FSectionIndex;
  end;

  TAccordionSection = record
    Header: TAccordionHeader;
    Content: TGroup;
    ContentHeight: Integer;
    Expanded: Boolean;
  end;

  TAccordion = class(TGroup)
  private
    FSections: TList<TAccordionSection>;
    FMode: TAccordionMode;
    FFocusedHeader: Integer;
    procedure RecalcLayout;
  public
    constructor Create(var Bounds: TRect; AMode: TAccordionMode = amMultiple); reintroduce; virtual;
    destructor Destroy; override;
    procedure AddSection(const ATitle: string; AContent: TGroup;
      AContentHeight: Integer; AExpanded: Boolean = False);
    procedure ToggleSection(AIndex: Integer);
    procedure ExpandSection(AIndex: Integer);
    procedure CollapseSection(AIndex: Integer);
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    property Mode: TAccordionMode read FMode write FMode;
    property Sections: TList<TAccordionSection> read FSections;
  end;

implementation

{***************************************************************************}
{                     TAccordionHeader Implementation                       }
{***************************************************************************}

constructor TAccordionHeader.Create(var Bounds: TRect; const ATitle: string;
  AExpanded: Boolean; ASectionIndex: Integer);
begin
  inherited Create(Bounds);
  FTitle := ATitle;
  FExpanded := AExpanded;
  FSectionIndex := ASectionIndex;
  Options := Options or ofSelectable;
  EventMask := EventMask or evBroadcast;
  GrowMode := gfGrowHiX;
end;

function TAccordionHeader.GetPalette: PPalette;
const
  P: string[Length(CAccordionHeader)] = CAccordionHeader;
begin
  GetPalette := PPalette(@P);
end;

procedure TAccordionHeader.Draw;
var
  B: TDrawBuffer;
  Color, ArrowColor: Byte;
  Arrow: Char;
begin
  if State and sfFocused <> 0 then
    Color := GetColor(2)
  else
    Color := GetColor(1);
  ArrowColor := GetColor(5);

  DrawChar(B, 0, ' ', Color, Size.X);

  { Arrow indicator }
  if FExpanded then
    Arrow := ArrowDown
  else
    Arrow := ArrowRight;
  DrawCell(B, 1, Arrow, ArrowColor);

  { Title with hotkey highlighting }
  DrawCStr(B, 3, FTitle, GetColor($0301));

  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TAccordionHeader.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);

  case Event.What of
    evMouseDown: begin
      Message(Owner, evBroadcast, cmAccordionToggle, Pointer(NativeInt(FSectionIndex)));
      ClearEvent(Event);
    end;
    evKeyDown: begin
      if (State and sfFocused <> 0) then begin
        case Event.KeyCode of
          kbEnter, kbSpaceBar: begin
            Message(Owner, evBroadcast, cmAccordionToggle, Pointer(NativeInt(FSectionIndex)));
            ClearEvent(Event);
          end;
        end;
      end;
    end;
  end;
end;

{***************************************************************************}
{                       TAccordion Implementation                           }
{***************************************************************************}

constructor TAccordion.Create(var Bounds: TRect; AMode: TAccordionMode);
begin
  inherited Create(Bounds);
  FSections := TList<TAccordionSection>.Create;
  FMode := AMode;
  FFocusedHeader := -1;
  GrowMode := gfGrowHiX or gfGrowHiY;
end;

destructor TAccordion.Destroy;
begin
  FSections.Free;
  inherited Destroy;
end;

procedure TAccordion.AddSection(const ATitle: string; AContent: TGroup;
  AContentHeight: Integer; AExpanded: Boolean);
var
  Section: TAccordionSection;
  R: TRect;
begin
  { Create header }
  R.Assign(0, 0, Size.X, 1);
  Section.Header := TAccordionHeader.Create(R, ATitle, AExpanded, FSections.Count);
  Section.Content := AContent;
  Section.ContentHeight := AContentHeight;
  Section.Expanded := AExpanded;

  Insert(Section.Header);
  if AContent <> nil then begin
    Insert(AContent);
    if not AExpanded then
      AContent.Hide;
  end;

  FSections.Add(Section);
  RecalcLayout;
end;

procedure TAccordion.ToggleSection(AIndex: Integer);
var
  Section: TAccordionSection;
  I: Integer;
begin
  if (AIndex < 0) or (AIndex >= FSections.Count) then Exit;

  Section := FSections[AIndex];
  Section.Expanded := not Section.Expanded;
  Section.Header.Expanded := Section.Expanded;
  FSections[AIndex] := Section;

  if Section.Expanded and (Section.Content <> nil) then
    Section.Content.Show
  else if Section.Content <> nil then
    Section.Content.Hide;

  { In exclusive mode, collapse all others when expanding }
  if (FMode = amExclusive) and Section.Expanded then begin
    for I := 0 to FSections.Count - 1 do begin
      if I <> AIndex then begin
        Section := FSections[I];
        if Section.Expanded then begin
          Section.Expanded := False;
          Section.Header.Expanded := False;
          if Section.Content <> nil then
            Section.Content.Hide;
          FSections[I] := Section;
        end;
      end;
    end;
  end;

  RecalcLayout;
  DrawView;
end;

procedure TAccordion.ExpandSection(AIndex: Integer);
var
  Section: TAccordionSection;
begin
  if (AIndex < 0) or (AIndex >= FSections.Count) then Exit;
  Section := FSections[AIndex];
  if not Section.Expanded then
    ToggleSection(AIndex);
end;

procedure TAccordion.CollapseSection(AIndex: Integer);
var
  Section: TAccordionSection;
begin
  if (AIndex < 0) or (AIndex >= FSections.Count) then Exit;
  Section := FSections[AIndex];
  if Section.Expanded then
    ToggleSection(AIndex);
end;

procedure TAccordion.RecalcLayout;
var
  I, Y: Integer;
  Section: TAccordionSection;
  R: TRect;
begin
  Y := 0;
  for I := 0 to FSections.Count - 1 do begin
    Section := FSections[I];

    { Position header }
    R.Assign(0, Y, Size.X, Y + 1);
    Section.Header.ChangeBounds(R);
    Inc(Y);

    { Position content if expanded }
    if Section.Expanded and (Section.Content <> nil) then begin
      R.Assign(0, Y, Size.X, Y + Section.ContentHeight);
      Section.Content.ChangeBounds(R);
      Inc(Y, Section.ContentHeight);
    end;
  end;
end;

procedure TAccordion.Draw;
var
  B: TDrawBuffer;
  Y: Integer;
  BgColor: Byte;
begin
  { Clear the entire background first to prevent artefacts
    when sections are collapsed and content area shrinks }
  BgColor := GetColor(1);
  if BgColor = 0 then BgColor := $07;  { Fallback }
  for Y := 0 to Size.Y - 1 do begin
    DrawChar(B, 0, ' ', BgColor, Size.X);
    WriteLine(0, Y, Size.X, 1, B);
  end;
  { Now draw all child views (headers + visible content) }
  inherited Draw;
end;

procedure TAccordion.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);

  if (Event.What = evBroadcast) and (Event.Command = cmAccordionToggle) then begin
    ToggleSection(NativeInt(Event.InfoPtr));
    ClearEvent(Event);
  end;

  if Event.What = evKeyDown then begin
    case CtrlToArrow(Event.KeyCode) of
      kbUp: begin
        if FFocusedHeader > 0 then begin
          Dec(FFocusedHeader);
          if (FFocusedHeader >= 0) and (FFocusedHeader < FSections.Count) then
            FSections[FFocusedHeader].Header.Focus;
          ClearEvent(Event);
        end;
      end;
      kbDown: begin
        if FFocusedHeader < FSections.Count - 1 then begin
          Inc(FFocusedHeader);
          if (FFocusedHeader >= 0) and (FFocusedHeader < FSections.Count) then
            FSections[FFocusedHeader].Header.Focus;
          ClearEvent(Event);
        end;
      end;
    end;
  end;
end;

end.
