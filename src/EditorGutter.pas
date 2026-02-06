{*********************************************************}
{                                                         }
{       Free Vision - Editor Gutter Component             }
{                                                         }
{       Extensible multi-column gutter with pluggable     }
{       providers: line numbers, bookmarks, breakpoints,  }
{       diff markers                                      }
{                                                         }
{*********************************************************}

unit EditorGutter;

{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections,
  FVCommon, Drivers, Views, Editors, FVConsts, FVBoxChars;

const
  CGutter = #6#2#3;  { Normal, Active line, Separator }

type
  TDiffStatus = (dsNone, dsAdded, dsModified, dsDeleted);

  TGutterProvider = class
  private
    FEnabled: Boolean;
  public
    constructor Create; virtual;
    function GetWidth: Integer; virtual; abstract;
    procedure DrawCell(var B: TDrawBuffer; X: Integer; LineIndex: Integer;
      IsCurrent: Boolean; Attr: Byte); virtual; abstract;
    procedure HandleClick(LineIndex: Integer); virtual;
    function GetHint(LineIndex: Integer): string; virtual;
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

  TLineNumberProvider = class(TGutterProvider)
  private
    FTotalLines: Integer;
    FWidth: Integer;
    procedure RecalcWidth;
  public
    constructor Create; override;
    function GetWidth: Integer; override;
    procedure DrawCell(var B: TDrawBuffer; X: Integer; LineIndex: Integer;
      IsCurrent: Boolean; Attr: Byte); override;
    procedure SetTotalLines(ATotal: Integer);
    property TotalLines: Integer read FTotalLines;
  end;

  TBookmarkProvider = class(TGutterProvider)
  private
    FBookmarks: TList<Integer>;
  public
    constructor Create; override;
    destructor Destroy; override;
    function GetWidth: Integer; override;
    procedure DrawCell(var B: TDrawBuffer; X: Integer; LineIndex: Integer;
      IsCurrent: Boolean; Attr: Byte); override;
    procedure HandleClick(LineIndex: Integer); override;
    procedure ToggleBookmark(ALine: Integer);
    function IsBookmarked(ALine: Integer): Boolean;
    function NextBookmark(FromLine: Integer): Integer;
    function PrevBookmark(FromLine: Integer): Integer;
    property Bookmarks: TList<Integer> read FBookmarks;
  end;

  TBreakpointProvider = class(TGutterProvider)
  private
    FBreakpoints: TList<Integer>;
  public
    constructor Create; override;
    destructor Destroy; override;
    function GetWidth: Integer; override;
    procedure DrawCell(var B: TDrawBuffer; X: Integer; LineIndex: Integer;
      IsCurrent: Boolean; Attr: Byte); override;
    procedure HandleClick(LineIndex: Integer); override;
    procedure ToggleBreakpoint(ALine: Integer);
    function IsBreakpoint(ALine: Integer): Boolean;
    procedure ClearAll;
    property Breakpoints: TList<Integer> read FBreakpoints;
  end;

  TDiffProvider = class(TGutterProvider)
  private
    FLineStatus: TDictionary<Integer, TDiffStatus>;
  public
    constructor Create; override;
    destructor Destroy; override;
    function GetWidth: Integer; override;
    procedure DrawCell(var B: TDrawBuffer; X: Integer; LineIndex: Integer;
      IsCurrent: Boolean; Attr: Byte); override;
    procedure SetLineStatus(ALine: Integer; AStatus: TDiffStatus);
    procedure ClearAll;
    procedure MarkRange(FromLine, ToLine: Integer; AStatus: TDiffStatus);
    property LineStatus: TDictionary<Integer, TDiffStatus> read FLineStatus;
  end;

  TEditorGutter = class(TView)
  private
    FProviders: TObjectList<TGutterProvider>;
    FEditor: TView;
    FSeparatorChar: Char;
    FTopLine: Integer;
    FTotalLines: Integer;
    FCurLine: Integer;
    function GetProviderAtX(X: Integer): TGutterProvider;
  public
    constructor Create(var Bounds: TRect; AEditor: TView); reintroduce; virtual;
    class function CreateDefault(var Bounds: TRect; AEditor: TView): TEditorGutter;
    destructor Destroy; override;
    function GetPalette: PPalette; override;
    procedure Draw; override;
    procedure HandleEvent(var Event: TEvent); override;
    procedure Update;
    procedure AddProvider(AProvider: TGutterProvider);
    procedure RemoveProvider(AProvider: TGutterProvider);
    procedure InsertProvider(AIndex: Integer; AProvider: TGutterProvider);
    procedure RecalcWidth;
    property Providers: TObjectList<TGutterProvider> read FProviders;
    property Editor: TView read FEditor;
    property SeparatorChar: Char read FSeparatorChar write FSeparatorChar;
  end;

implementation

{***************************************************************************}
{                      TGutterProvider Implementation                       }
{***************************************************************************}

constructor TGutterProvider.Create;
begin
  inherited Create;
  FEnabled := True;
end;

procedure TGutterProvider.HandleClick(LineIndex: Integer);
begin
  { Default: do nothing }
end;

function TGutterProvider.GetHint(LineIndex: Integer): string;
begin
  Result := '';
end;

{***************************************************************************}
{                    TLineNumberProvider Implementation                     }
{***************************************************************************}

constructor TLineNumberProvider.Create;
begin
  inherited Create;
  FTotalLines := 1;
  FWidth := 4;
end;

procedure TLineNumberProvider.RecalcWidth;
begin
  if FTotalLines < 100 then
    FWidth := 3
  else if FTotalLines < 1000 then
    FWidth := 4
  else if FTotalLines < 10000 then
    FWidth := 5
  else
    FWidth := 6;
end;

function TLineNumberProvider.GetWidth: Integer;
begin
  Result := FWidth;
end;

procedure TLineNumberProvider.DrawCell(var B: TDrawBuffer; X: Integer;
  LineIndex: Integer; IsCurrent: Boolean; Attr: Byte);
var
  S: string;
  I: Integer;
begin
  if LineIndex < FTotalLines then begin
    S := IntToStr(LineIndex + 1);
    { Right-align }
    while Length(S) < FWidth do
      S := ' ' + S;
  end else begin
    { Past EOF - show tilde }
    S := '';
    for I := 1 to FWidth - 1 do
      S := S + ' ';
    S := S + '~';
  end;

  for I := 1 to Length(S) do begin
    if X + I - 1 < MaxViewWidth then
      Drivers.DrawCell(B, X + I - 1, S[I], Attr);
  end;
end;

procedure TLineNumberProvider.SetTotalLines(ATotal: Integer);
begin
  FTotalLines := ATotal;
  RecalcWidth;
end;

{***************************************************************************}
{                    TBookmarkProvider Implementation                       }
{***************************************************************************}

constructor TBookmarkProvider.Create;
begin
  inherited Create;
  FBookmarks := TList<Integer>.Create;
end;

destructor TBookmarkProvider.Destroy;
begin
  FBookmarks.Free;
  inherited Destroy;
end;

function TBookmarkProvider.GetWidth: Integer;
begin
  Result := 1;
end;

procedure TBookmarkProvider.DrawCell(var B: TDrawBuffer; X: Integer;
  LineIndex: Integer; IsCurrent: Boolean; Attr: Byte);
begin
  if X < MaxViewWidth then begin
    if FBookmarks.Contains(LineIndex) then
      Drivers.DrawCell(B, X, Diamond, Attr)
    else
      Drivers.DrawCell(B, X, ' ', Attr);
  end;
end;

procedure TBookmarkProvider.HandleClick(LineIndex: Integer);
begin
  ToggleBookmark(LineIndex);
end;

procedure TBookmarkProvider.ToggleBookmark(ALine: Integer);
var
  Idx: Integer;
begin
  Idx := FBookmarks.IndexOf(ALine);
  if Idx >= 0 then
    FBookmarks.Delete(Idx)
  else
    FBookmarks.Add(ALine);
end;

function TBookmarkProvider.IsBookmarked(ALine: Integer): Boolean;
begin
  Result := FBookmarks.Contains(ALine);
end;

function TBookmarkProvider.NextBookmark(FromLine: Integer): Integer;
var
  I, Best: Integer;
begin
  Best := -1;
  for I := 0 to FBookmarks.Count - 1 do begin
    if FBookmarks[I] > FromLine then begin
      if (Best < 0) or (FBookmarks[I] < Best) then
        Best := FBookmarks[I];
    end;
  end;
  Result := Best;
end;

function TBookmarkProvider.PrevBookmark(FromLine: Integer): Integer;
var
  I, Best: Integer;
begin
  Best := -1;
  for I := 0 to FBookmarks.Count - 1 do begin
    if FBookmarks[I] < FromLine then begin
      if FBookmarks[I] > Best then
        Best := FBookmarks[I];
    end;
  end;
  Result := Best;
end;

{***************************************************************************}
{                   TBreakpointProvider Implementation                      }
{***************************************************************************}

constructor TBreakpointProvider.Create;
begin
  inherited Create;
  FBreakpoints := TList<Integer>.Create;
end;

destructor TBreakpointProvider.Destroy;
begin
  FBreakpoints.Free;
  inherited Destroy;
end;

function TBreakpointProvider.GetWidth: Integer;
begin
  Result := 1;
end;

procedure TBreakpointProvider.DrawCell(var B: TDrawBuffer; X: Integer;
  LineIndex: Integer; IsCurrent: Boolean; Attr: Byte);
begin
  if X < MaxViewWidth then begin
    if FBreakpoints.Contains(LineIndex) then
      Drivers.DrawCell(B, X, Circle, Attr or $40) { Red-tinted }
    else
      Drivers.DrawCell(B, X, ' ', Attr);
  end;
end;

procedure TBreakpointProvider.HandleClick(LineIndex: Integer);
begin
  ToggleBreakpoint(LineIndex);
end;

procedure TBreakpointProvider.ToggleBreakpoint(ALine: Integer);
var
  Idx: Integer;
begin
  Idx := FBreakpoints.IndexOf(ALine);
  if Idx >= 0 then
    FBreakpoints.Delete(Idx)
  else
    FBreakpoints.Add(ALine);
end;

function TBreakpointProvider.IsBreakpoint(ALine: Integer): Boolean;
begin
  Result := FBreakpoints.Contains(ALine);
end;

procedure TBreakpointProvider.ClearAll;
begin
  FBreakpoints.Clear;
end;

{***************************************************************************}
{                      TDiffProvider Implementation                         }
{***************************************************************************}

constructor TDiffProvider.Create;
begin
  inherited Create;
  FLineStatus := TDictionary<Integer, TDiffStatus>.Create;
end;

destructor TDiffProvider.Destroy;
begin
  FLineStatus.Free;
  inherited Destroy;
end;

function TDiffProvider.GetWidth: Integer;
begin
  Result := 1;
end;

procedure TDiffProvider.DrawCell(var B: TDrawBuffer; X: Integer;
  LineIndex: Integer; IsCurrent: Boolean; Attr: Byte);
var
  Status: TDiffStatus;
  C: Char;
  A: Byte;
begin
  if X >= MaxViewWidth then Exit;
  if FLineStatus.TryGetValue(LineIndex, Status) then begin
    case Status of
      dsAdded:    begin C := BlockFull; A := $20; end;  { Green }
      dsModified: begin C := BlockFull; A := $E0; end;  { Yellow }
      dsDeleted:  begin C := BoxHoriz;  A := $40; end;  { Red }
    else
      begin C := ' '; A := Attr; end;
    end;
    Drivers.DrawCell(B, X, C, A);
  end else
    Drivers.DrawCell(B, X, ' ', Attr);
end;

procedure TDiffProvider.SetLineStatus(ALine: Integer; AStatus: TDiffStatus);
begin
  if AStatus = dsNone then
    FLineStatus.Remove(ALine)
  else
    FLineStatus.AddOrSetValue(ALine, AStatus);
end;

procedure TDiffProvider.ClearAll;
begin
  FLineStatus.Clear;
end;

procedure TDiffProvider.MarkRange(FromLine, ToLine: Integer; AStatus: TDiffStatus);
var
  I: Integer;
begin
  for I := FromLine to ToLine do
    SetLineStatus(I, AStatus);
end;

{***************************************************************************}
{                      TEditorGutter Implementation                         }
{***************************************************************************}

constructor TEditorGutter.Create(var Bounds: TRect; AEditor: TView);
begin
  inherited Create(Bounds);
  FProviders := TObjectList<TGutterProvider>.Create(True);
  FEditor := AEditor;
  FSeparatorChar := BoxVert;
  FTopLine := 0;
  FTotalLines := 1;
  FCurLine := 0;
  EventMask := EventMask or evBroadcast;
  GrowMode := gfGrowHiY;
end;

class function TEditorGutter.CreateDefault(var Bounds: TRect; AEditor: TView): TEditorGutter;
begin
  Result := TEditorGutter.Create(Bounds, AEditor);
  Result.AddProvider(TLineNumberProvider.Create);
end;

destructor TEditorGutter.Destroy;
begin
  FProviders.Free;
  inherited Destroy;
end;

function TEditorGutter.GetPalette: PPalette;
const
  P: string[Length(CGutter)] = CGutter;
begin
  GetPalette := PPalette(@P);
end;

procedure TEditorGutter.Draw;
var
  B: TDrawBuffer;
  NormalAttr, ActiveAttr, SepAttr: Byte;
  Y, LineIdx, X, PW: Integer;
  Provider: TGutterProvider;
  IsCurrent: Boolean;
  CurAttr: Byte;
begin
  NormalAttr := GetColor(1);
  ActiveAttr := GetColor(2);
  SepAttr := GetColor(3);

  for Y := 0 to Size.Y - 1 do begin
    LineIdx := FTopLine + Y;
    IsCurrent := (LineIdx = FCurLine);
    if IsCurrent then
      CurAttr := ActiveAttr
    else
      CurAttr := NormalAttr;

    DrawChar(B, 0, ' ', CurAttr, Size.X);

    X := 0;
    for Provider in FProviders do begin
      if Provider.Enabled then begin
        PW := Provider.GetWidth;
        Provider.DrawCell(B, X, LineIdx, IsCurrent, CurAttr);
        Inc(X, PW);
      end;
    end;

    { Draw separator at right edge }
    if X < Size.X then
      Drivers.DrawCell(B, X, FSeparatorChar, SepAttr);

    WriteLine(0, Y, Size.X, 1, B);
  end;
end;

procedure TEditorGutter.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  LineIdx: Integer;
  Provider: TGutterProvider;
begin
  inherited HandleEvent(Event);

  case Event.What of
    evMouseDown: begin
      MakeLocal(Event.Where, Mouse);
      LineIdx := FTopLine + Mouse.Y;
      Provider := GetProviderAtX(Mouse.X);
      if Provider <> nil then begin
        Provider.HandleClick(LineIdx);
        DrawView;
        Message(Owner, evBroadcast, cmGutterClick, Pointer(NativeInt(LineIdx)));
        ClearEvent(Event);
      end;
    end;
    evBroadcast: begin
      if Event.Command = cmCursorChanged then begin
        Update;
      end else if Event.Command = cmScrollBarChanged then begin
        Update;
      end;
    end;
  end;
end;

procedure TEditorGutter.Update;
var
  Ed: TEditor;
  Changed: Boolean;
  Provider: TGutterProvider;
begin
  if (FEditor = nil) or not (FEditor is TEditor) then Exit;
  Ed := TEditor(FEditor);

  Changed := False;
  if FTopLine <> Ed.Delta.Y then begin
    FTopLine := Ed.Delta.Y;
    Changed := True;
  end;
  if FCurLine <> Ed.CurPos.Y then begin
    FCurLine := Ed.CurPos.Y;
    Changed := True;
  end;
  { Ed.Limit.Y is line count + 1 (for scrolling), so subtract 1 for display }
  if FTotalLines <> Ed.Limit.Y - 1 then begin
    FTotalLines := Ed.Limit.Y - 1;
    if FTotalLines < 1 then FTotalLines := 1;
    Changed := True;
    { Update line number provider width }
    for Provider in FProviders do begin
      if Provider is TLineNumberProvider then
        TLineNumberProvider(Provider).SetTotalLines(FTotalLines);
    end;
  end;

  if Changed then
    DrawView;
end;

procedure TEditorGutter.AddProvider(AProvider: TGutterProvider);
begin
  FProviders.Add(AProvider);
  RecalcWidth;
end;

procedure TEditorGutter.RemoveProvider(AProvider: TGutterProvider);
begin
  FProviders.Extract(AProvider);
  AProvider.Free;
  RecalcWidth;
end;

procedure TEditorGutter.InsertProvider(AIndex: Integer; AProvider: TGutterProvider);
begin
  FProviders.Insert(AIndex, AProvider);
  RecalcWidth;
end;

procedure TEditorGutter.RecalcWidth;
var
  W: Integer;
  Provider: TGutterProvider;
begin
  W := 1;  { 1 for separator }
  for Provider in FProviders do begin
    if Provider.Enabled then
      Inc(W, Provider.GetWidth);
  end;
  if W <> Size.X then begin
    GrowTo(W, Size.Y);
    DrawView;
  end;
end;

function TEditorGutter.GetProviderAtX(X: Integer): TGutterProvider;
var
  CurX, PW: Integer;
  Provider: TGutterProvider;
begin
  Result := nil;
  CurX := 0;
  for Provider in FProviders do begin
    if Provider.Enabled then begin
      PW := Provider.GetWidth;
      if (X >= CurX) and (X < CurX + PW) then begin
        Result := Provider;
        Exit;
      end;
      Inc(CurX, PW);
    end;
  end;
end;

end.
