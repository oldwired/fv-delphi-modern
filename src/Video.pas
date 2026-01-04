{*******************************************************}
{       Video Unit - Console output for Delphi          }
{       Replacement for FPC Video unit                  }
{*******************************************************}

unit Video;

interface

uses
  Winapi.Windows;

const
  vioOk = 0;
  vioError = 1;

type
  TVideoCell = Word;
  PVideoCell = ^TVideoCell;
  TVideoBuf = array[0..32767] of TVideoCell;
  PVideoBuf = ^TVideoBuf;

  TVideoMode = record
    Col: Word;
    Row: Word;
    Color: Boolean;
  end;

var
  ScreenWidth: Word;
  ScreenHeight: Word;
  VideoBuf: PVideoBuf;
  OldVideoBuf: PVideoBuf;
  VideoBufSize: LongInt;
  CursorX: Word;
  CursorY: Word;
  ErrorCode: Integer;

procedure InitVideo;
procedure DoneVideo;
procedure UpdateScreen(Force: Boolean);
procedure ClearScreen;
procedure SetCursorPos(X, Y: Word);
procedure GetCursorPos(var X, Y: Word);
procedure SetCursorType(Shape: Word);
procedure ShowCursor;
procedure HideCursor;
procedure SetVideoMode(const Mode: TVideoMode);
procedure GetVideoMode(var Mode: TVideoMode);
function GetCapabilities: Word;
procedure ResizeVideo(NewWidth, NewHeight: Word);

implementation

uses
  System.SysUtils, System.Math;

var
  ConsoleOutput: THandle;
  OrigMode: DWORD;
  OrigInfo: TConsoleScreenBufferInfo;
  VideoInitialized: Boolean = False;
  InternalBuf: array[0..32767] of TVideoCell;
  InternalOldBuf: array[0..32767] of TVideoCell;

procedure InitVideo;
var
  Info: TConsoleScreenBufferInfo;
begin
  if VideoInitialized then Exit;
  ConsoleOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  if ConsoleOutput = INVALID_HANDLE_VALUE then begin
    ErrorCode := vioError;
    Exit;
  end;
  GetConsoleMode(ConsoleOutput, OrigMode);
  GetConsoleScreenBufferInfo(ConsoleOutput, OrigInfo);
  GetConsoleScreenBufferInfo(ConsoleOutput, Info);
  ScreenWidth := Info.dwSize.X;
  ScreenHeight := Info.srWindow.Bottom - Info.srWindow.Top + 1;
  if ScreenWidth > 255 then ScreenWidth := 255;
  if ScreenHeight > 255 then ScreenHeight := 255;
  VideoBufSize := ScreenWidth * ScreenHeight * SizeOf(TVideoCell);
  VideoBuf := @InternalBuf;
  OldVideoBuf := @InternalOldBuf;
  FillChar(InternalBuf, SizeOf(InternalBuf), 0);
  FillChar(InternalOldBuf, SizeOf(InternalOldBuf), 0);
  CursorX := 0;
  CursorY := 0;
  VideoInitialized := True;
  ErrorCode := vioOk;
  HideCursor;  { Start with cursor hidden until a view requests it }
end;

procedure DoneVideo;
begin
  if not VideoInitialized then Exit;
  SetConsoleMode(ConsoleOutput, OrigMode);
  VideoInitialized := False;
end;

procedure UpdateScreen(Force: Boolean);
var
  I: Integer;
  WriteRegion: TSmallRect;
  BufSize: TCoord;
  BufCoord: TCoord;
  CharBuf: array of TCharInfo;
begin
  if not VideoInitialized then Exit;
  SetLength(CharBuf, ScreenWidth * ScreenHeight);
  for I := 0 to ScreenWidth * ScreenHeight - 1 do begin
    CharBuf[I].AsciiChar := AnsiChar(Lo(VideoBuf^[I]));
    CharBuf[I].Attributes := Hi(VideoBuf^[I]);
  end;
  BufSize.X := ScreenWidth;
  BufSize.Y := ScreenHeight;
  BufCoord.X := 0;
  BufCoord.Y := 0;
  WriteRegion.Left := 0;
  WriteRegion.Top := 0;
  WriteRegion.Right := ScreenWidth - 1;
  WriteRegion.Bottom := ScreenHeight - 1;
  WriteConsoleOutputA(ConsoleOutput, @CharBuf[0], BufSize, BufCoord, WriteRegion);
  Move(VideoBuf^, OldVideoBuf^, VideoBufSize);
end;

procedure ClearScreen;
var
  I: Integer;
begin
  for I := 0 to ScreenWidth * ScreenHeight - 1 do
    VideoBuf^[I] := $0720;
  UpdateScreen(True);
end;

procedure SetCursorPos(X, Y: Word);
var
  Coord: TCoord;
begin
  CursorX := X;
  CursorY := Y;
  if (X < ScreenWidth) and (Y < ScreenHeight) then begin
    Coord.X := X;
    Coord.Y := Y;
    SetConsoleCursorPosition(ConsoleOutput, Coord);
    ShowCursor;
  end else begin
    HideCursor;
  end;
end;

procedure GetCursorPos(var X, Y: Word);
begin
  X := CursorX;
  Y := CursorY;
end;

procedure SetCursorType(Shape: Word);
var
  CursorInfo: TConsoleCursorInfo;
begin
  if not VideoInitialized then Exit;
  CursorInfo.dwSize := Shape;
  CursorInfo.bVisible := Shape > 0;
  SetConsoleCursorInfo(ConsoleOutput, CursorInfo);
end;

procedure ShowCursor;
var
  CursorInfo: TConsoleCursorInfo;
begin
  if not VideoInitialized then Exit;
  CursorInfo.dwSize := 25;  { 25% block }
  CursorInfo.bVisible := True;
  SetConsoleCursorInfo(ConsoleOutput, CursorInfo);
end;

procedure HideCursor;
var
  CursorInfo: TConsoleCursorInfo;
begin
  if not VideoInitialized then Exit;
  CursorInfo.dwSize := 1;
  CursorInfo.bVisible := False;
  SetConsoleCursorInfo(ConsoleOutput, CursorInfo);
end;

procedure SetVideoMode(const Mode: TVideoMode);
begin
  ScreenWidth := Mode.Col;
  ScreenHeight := Mode.Row;
  VideoBufSize := ScreenWidth * ScreenHeight * SizeOf(TVideoCell);
end;

procedure GetVideoMode(var Mode: TVideoMode);
begin
  Mode.Col := ScreenWidth;
  Mode.Row := ScreenHeight;
  Mode.Color := True;
end;

function GetCapabilities: Word;
begin
  Result := 0;
end;

procedure ResizeVideo(NewWidth, NewHeight: Word);
begin
  if not VideoInitialized then Exit;

  { Clamp to maximum size supported by internal buffer }
  if NewWidth > 255 then NewWidth := 255;
  if NewHeight > 255 then NewHeight := 255;

  { Update dimensions }
  ScreenWidth := NewWidth;
  ScreenHeight := NewHeight;
  VideoBufSize := ScreenWidth * ScreenHeight * SizeOf(TVideoCell);

  { Clear both buffers to force full redraw }
  FillChar(InternalBuf, SizeOf(InternalBuf), 0);
  FillChar(InternalOldBuf, SizeOf(InternalOldBuf), 0);

  { Fill with default blank character (space with normal attribute) }
  ClearScreen;
end;

end.
