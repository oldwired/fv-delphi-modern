{*********************************************************}
{                                                         }
{       Free Vision - UTF-8 Encoding Utilities            }
{                                                         }
{       Encoding detection and conversion for             }
{       Unicode file support in the editor                }
{                                                         }
{*********************************************************}

unit FVUTF8;

interface

uses
  System.SysUtils;

type
  TFileEncoding = (
    feUnknown,    // Could not determine encoding
    feUTF8,       // UTF-8 without BOM
    feUTF8BOM,    // UTF-8 with BOM (EF BB BF)
    feUTF16LE,    // UTF-16 Little Endian (FF FE)
    feUTF16BE,    // UTF-16 Big Endian (FE FF)
    feANSI        // Windows-1252 / CP1252
  );

{ Encoding detection }
function DetectEncoding(const Data: TBytes; Size: Integer): TFileEncoding;
function GetBOMLength(Encoding: TFileEncoding): Integer;

{ UTF-8 character handling }
function UTF8CharLen(LeadByte: Byte): Integer;
function IsUTF8TrailByte(B: Byte): Boolean;
function DecodeUTF8Char(const Buf: PByte; BufLen: Integer; out CharLen: Integer): Char;

{ Full Unicode string decoding (supports emoji / code points > $FFFF) }
function DecodeUTF8ToString(const Buf: PByte; BufLen: Integer; out CharLen: Integer): string;
function DecodeUTF8CodePoint(const Buf: PByte; BufLen: Integer; out CharLen: Integer): Cardinal;

{ Unicode display width (wcwidth equivalent) }
function IsWideCodePoint(CodePoint: Cardinal): Boolean;
function CodePointCharWidth(CodePoint: Cardinal): Integer;

{ String-level width helpers }
function IsWideString(const S: string): Boolean;
function StringDisplayWidth(const S: string): Integer;
function CStrDisplayWidth(const S: string): Integer;

{ Conversion to UTF-8 }
function ANSIBytesToUTF8(const Data: TBytes): TBytes;
function UTF16LEBytesToUTF8(const Data: TBytes; SkipBOM: Boolean = True): TBytes;
function UTF16BEBytesToUTF8(const Data: TBytes; SkipBOM: Boolean = True): TBytes;
function ConvertToUTF8(const Data: TBytes; Encoding: TFileEncoding): TBytes;

implementation

{ Encoding detection }

function DetectEncoding(const Data: TBytes; Size: Integer): TFileEncoding;
var
  I: Integer;
  HasHighBytes: Boolean;
  ValidUTF8: Boolean;
  ExpectedTrail: Integer;
begin
  Result := feUnknown;
  if Size = 0 then Exit;

  // Check for BOM first
  if Size >= 3 then
  begin
    if (Data[0] = $EF) and (Data[1] = $BB) and (Data[2] = $BF) then
    begin
      Result := feUTF8BOM;
      Exit;
    end;
  end;

  if Size >= 2 then
  begin
    if (Data[0] = $FF) and (Data[1] = $FE) then
    begin
      Result := feUTF16LE;
      Exit;
    end;
    if (Data[0] = $FE) and (Data[1] = $FF) then
    begin
      Result := feUTF16BE;
      Exit;
    end;
  end;

  // No BOM - analyze content
  // Check if it's valid UTF-8
  HasHighBytes := False;
  ValidUTF8 := True;
  ExpectedTrail := 0;
  I := 0;

  while I < Size do
  begin
    if Data[I] >= $80 then
      HasHighBytes := True;

    if ExpectedTrail > 0 then
    begin
      // Expecting a trail byte (10xxxxxx)
      if (Data[I] and $C0) = $80 then
        Dec(ExpectedTrail)
      else
      begin
        ValidUTF8 := False;
        Break;
      end;
    end
    else if Data[I] >= $80 then
    begin
      // Start of multi-byte sequence
      if (Data[I] and $E0) = $C0 then
        ExpectedTrail := 1  // 2-byte sequence (110xxxxx)
      else if (Data[I] and $F0) = $E0 then
        ExpectedTrail := 2  // 3-byte sequence (1110xxxx)
      else if (Data[I] and $F8) = $F0 then
        ExpectedTrail := 3  // 4-byte sequence (11110xxx)
      else
      begin
        ValidUTF8 := False;
        Break;
      end;
    end;
    Inc(I);
  end;

  // If we ended expecting more trail bytes, it's invalid
  if ExpectedTrail > 0 then
    ValidUTF8 := False;

  if ValidUTF8 then
  begin
    if HasHighBytes then
      Result := feUTF8
    else
      Result := feUTF8;  // Pure ASCII is valid UTF-8
  end
  else
  begin
    // Not valid UTF-8, assume ANSI (Windows-1252)
    Result := feANSI;
  end;
end;

function GetBOMLength(Encoding: TFileEncoding): Integer;
begin
  case Encoding of
    feUTF8BOM: Result := 3;
    feUTF16LE, feUTF16BE: Result := 2;
  else
    Result := 0;
  end;
end;

{ UTF-8 character handling }

function UTF8CharLen(LeadByte: Byte): Integer;
begin
  if LeadByte < $80 then
    Result := 1           // ASCII (0xxxxxxx)
  else if (LeadByte and $E0) = $C0 then
    Result := 2           // 2-byte (110xxxxx)
  else if (LeadByte and $F0) = $E0 then
    Result := 3           // 3-byte (1110xxxx)
  else if (LeadByte and $F8) = $F0 then
    Result := 4           // 4-byte (11110xxx)
  else
    Result := 1;          // Invalid lead byte, treat as single byte
end;

function IsUTF8TrailByte(B: Byte): Boolean;
begin
  // Trail bytes are 10xxxxxx (range $80-$BF)
  Result := (B and $C0) = $80;
end;

function DecodeUTF8Char(const Buf: PByte; BufLen: Integer; out CharLen: Integer): Char;
var
  CodePoint: Cardinal;
  B0, B1, B2, B3: Byte;
begin
  Result := #0;
  CharLen := 0;
  if (Buf = nil) or (BufLen <= 0) then Exit;

  B0 := Buf[0];
  CharLen := UTF8CharLen(B0);

  // Make sure we have enough bytes
  if CharLen > BufLen then
  begin
    CharLen := 1;
    Result := Char(B0);  // Return as-is if incomplete
    Exit;
  end;

  case CharLen of
    1:
      CodePoint := B0;
    2:
      begin
        B1 := Buf[1];
        if not IsUTF8TrailByte(B1) then
        begin
          CharLen := 1;
          Result := Char(B0);
          Exit;
        end;
        CodePoint := ((B0 and $1F) shl 6) or (B1 and $3F);
      end;
    3:
      begin
        B1 := Buf[1];
        B2 := Buf[2];
        if not (IsUTF8TrailByte(B1) and IsUTF8TrailByte(B2)) then
        begin
          CharLen := 1;
          Result := Char(B0);
          Exit;
        end;
        CodePoint := ((B0 and $0F) shl 12) or ((B1 and $3F) shl 6) or (B2 and $3F);
      end;
    4:
      begin
        B1 := Buf[1];
        B2 := Buf[2];
        B3 := Buf[3];
        if not (IsUTF8TrailByte(B1) and IsUTF8TrailByte(B2) and IsUTF8TrailByte(B3)) then
        begin
          CharLen := 1;
          Result := Char(B0);
          Exit;
        end;
        CodePoint := ((B0 and $07) shl 18) or ((B1 and $3F) shl 12) or
                     ((B2 and $3F) shl 6) or (B3 and $3F);
      end;
  else
    CodePoint := B0;
    CharLen := 1;
  end;

  // Convert code point to Char
  // Delphi Char is UTF-16, so code points > $FFFF need surrogate pairs
  // For simplicity, we'll use the replacement character for these
  if CodePoint <= $FFFF then
    Result := Char(CodePoint)
  else
    Result := #$FFFD;  // Replacement character for code points > BMP
end;

{ Full Unicode string decoding - returns a Delphi string that can hold
  surrogate pairs for code points > $FFFF (emoji, etc.) }

function DecodeUTF8ToString(const Buf: PByte; BufLen: Integer; out CharLen: Integer): string;
var
  CodePoint: Cardinal;
  B0, B1, B2, B3: Byte;
begin
  Result := '';
  CharLen := 0;
  if (Buf = nil) or (BufLen <= 0) then Exit;

  B0 := Buf[0];
  CharLen := UTF8CharLen(B0);

  if CharLen > BufLen then
  begin
    CharLen := 1;
    Result := Char(B0);
    Exit;
  end;

  case CharLen of
    1:
      CodePoint := B0;
    2:
      begin
        B1 := Buf[1];
        if not IsUTF8TrailByte(B1) then
        begin
          CharLen := 1;
          Result := Char(B0);
          Exit;
        end;
        CodePoint := ((B0 and $1F) shl 6) or (B1 and $3F);
      end;
    3:
      begin
        B1 := Buf[1];
        B2 := Buf[2];
        if not (IsUTF8TrailByte(B1) and IsUTF8TrailByte(B2)) then
        begin
          CharLen := 1;
          Result := Char(B0);
          Exit;
        end;
        CodePoint := ((B0 and $0F) shl 12) or ((B1 and $3F) shl 6) or (B2 and $3F);
      end;
    4:
      begin
        B1 := Buf[1];
        B2 := Buf[2];
        B3 := Buf[3];
        if not (IsUTF8TrailByte(B1) and IsUTF8TrailByte(B2) and IsUTF8TrailByte(B3)) then
        begin
          CharLen := 1;
          Result := Char(B0);
          Exit;
        end;
        CodePoint := ((B0 and $07) shl 18) or ((B1 and $3F) shl 12) or
                     ((B2 and $3F) shl 6) or (B3 and $3F);
      end;
  else
    CodePoint := B0;
    CharLen := 1;
  end;

  // Convert code point to Delphi string
  // Code points > $FFFF need UTF-16 surrogate pairs
  if CodePoint <= $FFFF then
    Result := Char(CodePoint)
  else if CodePoint <= $10FFFF then
  begin
    // Encode as surrogate pair
    Dec(CodePoint, $10000);
    Result := Char($D800 + (CodePoint shr 10)) + Char($DC00 + (CodePoint and $3FF));
  end
  else
    Result := #$FFFD;  // Invalid code point
end;

{ Decode UTF-8 to raw code point (Cardinal) - avoids string allocation }

function DecodeUTF8CodePoint(const Buf: PByte; BufLen: Integer; out CharLen: Integer): Cardinal;
var
  B0, B1, B2, B3: Byte;
begin
  Result := 0;
  CharLen := 0;
  if (Buf = nil) or (BufLen <= 0) then Exit;

  B0 := Buf[0];
  CharLen := UTF8CharLen(B0);

  if CharLen > BufLen then
  begin
    CharLen := 1;
    Result := B0;
    Exit;
  end;

  case CharLen of
    1: Result := B0;
    2: begin
         B1 := Buf[1];
         if not IsUTF8TrailByte(B1) then begin CharLen := 1; Result := B0; Exit; end;
         Result := ((B0 and $1F) shl 6) or (B1 and $3F);
       end;
    3: begin
         B1 := Buf[1]; B2 := Buf[2];
         if not (IsUTF8TrailByte(B1) and IsUTF8TrailByte(B2)) then begin CharLen := 1; Result := B0; Exit; end;
         Result := ((B0 and $0F) shl 12) or ((B1 and $3F) shl 6) or (B2 and $3F);
       end;
    4: begin
         B1 := Buf[1]; B2 := Buf[2]; B3 := Buf[3];
         if not (IsUTF8TrailByte(B1) and IsUTF8TrailByte(B2) and IsUTF8TrailByte(B3)) then begin CharLen := 1; Result := B0; Exit; end;
         Result := ((B0 and $07) shl 18) or ((B1 and $3F) shl 12) or ((B2 and $3F) shl 6) or (B3 and $3F);
       end;
  else
    Result := B0;
    CharLen := 1;
  end;
end;

{ Unicode display width - equivalent to wcwidth().
  Returns True for characters that occupy 2 terminal columns. }

function IsWideCodePoint(CodePoint: Cardinal): Boolean;
begin
  Result :=
    { East Asian Wide and Fullwidth characters (BMP) }
    ((CodePoint >= $1100) and (CodePoint <= $115F)) or   { Hangul Jamo }
    ((CodePoint >= $231A) and (CodePoint <= $231B)) or   { Watch, Hourglass }
    ((CodePoint >= $2329) and (CodePoint <= $232A)) or   { Angle brackets }
    ((CodePoint >= $23E9) and (CodePoint <= $23F3)) or   { Various symbols }
    ((CodePoint >= $23F8) and (CodePoint <= $23FA)) or   { Play/pause buttons }
    ((CodePoint >= $25FD) and (CodePoint <= $25FE)) or   { Medium squares }
    ((CodePoint >= $2614) and (CodePoint <= $2615)) or   { Umbrella, hot beverage }
    ((CodePoint >= $2648) and (CodePoint <= $2653)) or   { Zodiac signs }
    (CodePoint = $267F) or                                { Wheelchair }
    (CodePoint = $2693) or                                { Anchor }
    (CodePoint = $26A1) or                                { High voltage }
    ((CodePoint >= $26AA) and (CodePoint <= $26AB)) or   { Circles }
    ((CodePoint >= $26BD) and (CodePoint <= $26BE)) or   { Sports }
    ((CodePoint >= $26C4) and (CodePoint <= $26C5)) or   { Snowman, sun }
    (CodePoint = $26CE) or                                { Ophiuchus }
    (CodePoint = $26D4) or                                { No entry }
    (CodePoint = $26EA) or                                { Church }
    ((CodePoint >= $26F2) and (CodePoint <= $26F3)) or   { Fountain, golf }
    (CodePoint = $26F5) or                                { Sailboat }
    (CodePoint = $26FA) or                                { Tent }
    (CodePoint = $26FD) or                                { Fuel pump }
    (CodePoint = $2702) or                                { Scissors }
    (CodePoint = $2705) or                                { Check mark }
    ((CodePoint >= $2708) and (CodePoint <= $270D)) or   { Airplane..writing hand }
    (CodePoint = $270F) or                                { Pencil }
    ((CodePoint >= $2753) and (CodePoint <= $2755)) or   { Question marks }
    (CodePoint = $2757) or                                { Exclamation mark }
    ((CodePoint >= $2795) and (CodePoint <= $2797)) or   { Math symbols }
    (CodePoint = $27B0) or                                { Curly loop }
    (CodePoint = $27BF) or                                { Double curly loop }
    ((CodePoint >= $2934) and (CodePoint <= $2935)) or   { Arrows }
    ((CodePoint >= $2B05) and (CodePoint <= $2B07)) or   { Arrows }
    ((CodePoint >= $2B1B) and (CodePoint <= $2B1C)) or   { Squares }
    (CodePoint = $2B50) or                                { Star }
    (CodePoint = $2B55) or                                { Circle }
    ((CodePoint >= $2E80) and (CodePoint <= $9FFF)) or   { CJK and related blocks }
    ((CodePoint >= $AC00) and (CodePoint <= $D7AF)) or   { Hangul Syllables }
    ((CodePoint >= $F900) and (CodePoint <= $FAFF)) or   { CJK Compatibility Ideographs }
    ((CodePoint >= $FE10) and (CodePoint <= $FE1F)) or   { Vertical Forms }
    ((CodePoint >= $FE30) and (CodePoint <= $FE6F)) or   { CJK Compatibility Forms }
    ((CodePoint >= $FF00) and (CodePoint <= $FF60)) or   { Fullwidth Forms }
    ((CodePoint >= $FFE0) and (CodePoint <= $FFE6)) or   { Fullwidth currency }
    { Supplementary planes - emoji and other wide chars }
    ((CodePoint >= $1F000) and (CodePoint <= $1F02F)) or { Mahjong, Domino }
    ((CodePoint >= $1F0A0) and (CodePoint <= $1F0FF)) or { Playing cards }
    ((CodePoint >= $1F100) and (CodePoint <= $1F1FF)) or { Enclosed alphanumerics, flags }
    ((CodePoint >= $1F200) and (CodePoint <= $1F2FF)) or { Enclosed ideographic }
    ((CodePoint >= $1F300) and (CodePoint <= $1F9FF)) or { Misc symbols, emoticons, transport, etc. }
    ((CodePoint >= $1FA00) and (CodePoint <= $1FAFF)) or { Chess, extended symbols }
    ((CodePoint >= $20000) and (CodePoint <= $2FFFF)) or { CJK Unified Ideographs Extension B+ }
    ((CodePoint >= $30000) and (CodePoint <= $3FFFF));   { CJK Extension G+ }
end;

{ Returns display width of a code point: 0 for controls, 2 for wide, 1 otherwise }

function CodePointCharWidth(CodePoint: Cardinal): Integer;
begin
  if CodePoint < 32 then
    Result := 0
  else if IsWideCodePoint(CodePoint) then
    Result := 2
  else
    Result := 1;
end;

{ String-level width helpers }

function IsWideString(const S: string): Boolean;
var
  CP: Cardinal;
begin
  Result := False;
  if Length(S) = 0 then Exit;
  if (Length(S) >= 2) and
     (Ord(S[1]) >= $D800) and (Ord(S[1]) <= $DBFF) and
     (Ord(S[2]) >= $DC00) and (Ord(S[2]) <= $DFFF) then
  begin
    { Surrogate pair - decode to code point }
    CP := $10000 + Cardinal((Ord(S[1]) - $D800) shl 10) + Cardinal(Ord(S[2]) - $DC00);
    Result := IsWideCodePoint(CP);
  end
  else
    Result := IsWideCodePoint(Ord(S[1]));
end;

{ StringDisplayWidth - returns display column count for a Delphi UTF-16 string,
  correctly handling surrogate pairs (emoji, CJK extensions) }

function StringDisplayWidth(const S: string): Integer;
var
  I, Len: Integer;
  CP: Cardinal;
begin
  Result := 0;
  Len := Length(S);
  I := 1;
  while I <= Len do
  begin
    if (I < Len) and
       (Ord(S[I]) >= $D800) and (Ord(S[I]) <= $DBFF) and
       (Ord(S[I+1]) >= $DC00) and (Ord(S[I+1]) <= $DFFF) then
    begin
      { Surrogate pair - decode to code point }
      CP := $10000 + Cardinal((Ord(S[I]) - $D800) shl 10) + Cardinal(Ord(S[I+1]) - $DC00);
      Inc(Result, CodePointCharWidth(CP));
      Inc(I, 2);
    end
    else
    begin
      Inc(Result, CodePointCharWidth(Ord(S[I])));
      Inc(I);
    end;
  end;
end;

{ CStrDisplayWidth - same as StringDisplayWidth but skips ~ hotkey markers }

function CStrDisplayWidth(const S: string): Integer;
var
  I, Len: Integer;
  CP: Cardinal;
begin
  Result := 0;
  Len := Length(S);
  I := 1;
  while I <= Len do
  begin
    if S[I] = '~' then
    begin
      Inc(I); { Skip tilde marker }
    end
    else if (I < Len) and
            (Ord(S[I]) >= $D800) and (Ord(S[I]) <= $DBFF) and
            (Ord(S[I+1]) >= $DC00) and (Ord(S[I+1]) <= $DFFF) then
    begin
      { Surrogate pair - decode to code point }
      CP := $10000 + Cardinal((Ord(S[I]) - $D800) shl 10) + Cardinal(Ord(S[I+1]) - $DC00);
      Inc(Result, CodePointCharWidth(CP));
      Inc(I, 2);
    end
    else
    begin
      Inc(Result, CodePointCharWidth(Ord(S[I])));
      Inc(I);
    end;
  end;
end;

{ Conversion to UTF-8 }

function ANSIBytesToUTF8(const Data: TBytes): TBytes;
var
  AnsiStr: AnsiString;
  UnicodeStr: string;
begin
  if Length(Data) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  // Convert ANSI (Windows-1252) to Unicode string, then to UTF-8
  SetLength(AnsiStr, Length(Data));
  Move(Data[0], AnsiStr[1], Length(Data));

  // Use Windows-1252 code page
  UnicodeStr := string(AnsiStr);  // Delphi converts using default ANSI code page

  Result := TEncoding.UTF8.GetBytes(UnicodeStr);
end;

function UTF16LEBytesToUTF8(const Data: TBytes; SkipBOM: Boolean): TBytes;
var
  StartIdx: Integer;
  CharCount: Integer;
  UnicodeStr: string;
begin
  if Length(Data) < 2 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  StartIdx := 0;
  if SkipBOM and (Length(Data) >= 2) and (Data[0] = $FF) and (Data[1] = $FE) then
    StartIdx := 2;

  CharCount := (Length(Data) - StartIdx) div 2;
  if CharCount = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(UnicodeStr, CharCount);
  Move(Data[StartIdx], UnicodeStr[1], CharCount * 2);

  Result := TEncoding.UTF8.GetBytes(UnicodeStr);
end;

function UTF16BEBytesToUTF8(const Data: TBytes; SkipBOM: Boolean): TBytes;
var
  StartIdx: Integer;
  CharCount: Integer;
  I: Integer;
  UnicodeStr: string;
  SwappedData: TBytes;
begin
  if Length(Data) < 2 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  StartIdx := 0;
  if SkipBOM and (Length(Data) >= 2) and (Data[0] = $FE) and (Data[1] = $FF) then
    StartIdx := 2;

  CharCount := (Length(Data) - StartIdx) div 2;
  if CharCount = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  // Swap bytes from big-endian to little-endian
  SetLength(SwappedData, CharCount * 2);
  for I := 0 to CharCount - 1 do
  begin
    SwappedData[I * 2] := Data[StartIdx + I * 2 + 1];
    SwappedData[I * 2 + 1] := Data[StartIdx + I * 2];
  end;

  SetLength(UnicodeStr, CharCount);
  Move(SwappedData[0], UnicodeStr[1], CharCount * 2);

  Result := TEncoding.UTF8.GetBytes(UnicodeStr);
end;

function ConvertToUTF8(const Data: TBytes; Encoding: TFileEncoding): TBytes;
var
  BOMLen: Integer;
begin
  case Encoding of
    feUTF8:
      Result := Copy(Data);

    feUTF8BOM:
      begin
        // Strip BOM and return the rest
        if Length(Data) > 3 then
        begin
          SetLength(Result, Length(Data) - 3);
          Move(Data[3], Result[0], Length(Result));
        end
        else
          SetLength(Result, 0);
      end;

    feUTF16LE:
      Result := UTF16LEBytesToUTF8(Data, True);

    feUTF16BE:
      Result := UTF16BEBytesToUTF8(Data, True);

    feANSI:
      Result := ANSIBytesToUTF8(Data);

  else
    // Unknown - treat as UTF-8
    Result := Copy(Data);
  end;
end;

end.
