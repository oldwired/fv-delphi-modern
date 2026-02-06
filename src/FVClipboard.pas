{*******************************************************}
{       Free Vision Clipboard - Windows Integration    }
{       Shared clipboard access for all components     }
{*******************************************************}

unit FVClipboard;

interface

function ClipboardSetText(const Text: string): Boolean;
function ClipboardGetText: string;
function ClipboardHasText: Boolean;

implementation

uses
  Winapi.Windows;

function ClipboardSetText(const Text: string): Boolean;
var
  hMem: HGLOBAL;
  pMem: PChar;
begin
  Result := False;
  if not OpenClipboard(0) then Exit;
  try
    EmptyClipboard;
    hMem := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE,
      (Length(Text) + 1) * SizeOf(Char));
    if hMem = 0 then Exit;
    try
      pMem := GlobalLock(hMem);
      if pMem = nil then Exit;
      try
        Move(PChar(Text)^, pMem^, (Length(Text) + 1) * SizeOf(Char));
      finally
        GlobalUnlock(hMem);
      end;
      {$IFDEF UNICODE}
      Result := SetClipboardData(CF_UNICODETEXT, hMem) <> 0;
      {$ELSE}
      Result := SetClipboardData(CF_TEXT, hMem) <> 0;
      {$ENDIF}
    except
      GlobalFree(hMem);
      raise;
    end;
  finally
    CloseClipboard;
  end;
end;

function ClipboardGetText: string;
var
  hMem: HGLOBAL;
  pMem: PChar;
begin
  Result := '';
  if not OpenClipboard(0) then Exit;
  try
    {$IFDEF UNICODE}
    hMem := GetClipboardData(CF_UNICODETEXT);
    {$ELSE}
    hMem := GetClipboardData(CF_TEXT);
    {$ENDIF}
    if hMem = 0 then Exit;
    pMem := GlobalLock(hMem);
    if pMem = nil then Exit;
    try
      Result := pMem;
    finally
      GlobalUnlock(hMem);
    end;
  finally
    CloseClipboard;
  end;
end;

function ClipboardHasText: Boolean;
begin
  {$IFDEF UNICODE}
  Result := IsClipboardFormatAvailable(CF_UNICODETEXT);
  {$ELSE}
  Result := IsClipboardFormatAvailable(CF_TEXT);
  {$ENDIF}
end;

end.
