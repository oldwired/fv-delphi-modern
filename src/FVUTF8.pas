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
  System.SysUtils,
  FVUnicodeWidth;

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
function CopyDisplayCells(const S: string; StartCol, MaxWidth: Integer): string;

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

{ Unicode display width - delegates to FVUnicodeWidth (Unicode 15.1 tables
  ported from spectreconsole/wcwidth via VSoft.AnsiConsole). }

function IsWideCodePoint(CodePoint: Cardinal): Boolean;
begin
  Result := FVIsWideCodePoint(CodePoint);
end;

function CodePointCharWidth(CodePoint: Cardinal): Integer;
begin
  Result := FVCellWidth(CodePoint);
end;

{ String-level width helpers }

function IsWideString(const S: string): Boolean;
begin
  Result := StringDisplayWidth(S) > 1;
end;

{ StringDisplayWidth - returns display column count for a Delphi UTF-16 string,
  correctly handling surrogate pairs (emoji, CJK extensions) }

function StringDisplayWidth(const S: string): Integer;
var
  I, Len, W, ClusterWidth: Integer;
  CP: Cardinal;
  HaveCluster, JoinNext: Boolean;

  procedure FlushCluster;
  begin
    if HaveCluster then
    begin
      Inc(Result, ClusterWidth);
      HaveCluster := False;
      ClusterWidth := 0;
    end;
  end;

begin
  Result := 0;
  Len := Length(S);
  I := 1;
  ClusterWidth := 0;
  HaveCluster := False;
  JoinNext := False;
  while I <= Len do
  begin
    if (I < Len) and
       (Ord(S[I]) >= $D800) and (Ord(S[I]) <= $DBFF) and
       (Ord(S[I+1]) >= $DC00) and (Ord(S[I+1]) <= $DFFF) then
    begin
      CP := $10000 + Cardinal((Ord(S[I]) - $D800) shl 10) + Cardinal(Ord(S[I+1]) - $DC00);
      Inc(I, 2);
    end
    else
    begin
      CP := Ord(S[I]);
      Inc(I);
    end;
    W := CodePointCharWidth(CP);

    if W = 0 then
    begin
      if HaveCluster then
      begin
        { VS16 (U+FE0F) promotes a width-1 base character to width 2
          (emoji presentation), matching what DrawStr will lay out. }
        if (CP = $FE0F) and (ClusterWidth = 1) then
          ClusterWidth := 2;
        if CP = $200D then
          JoinNext := True;
      end;
      Continue;
    end;

    if HaveCluster and JoinNext then
    begin
      if W > ClusterWidth then
        ClusterWidth := W;
      JoinNext := False;
    end
    else
    begin
      FlushCluster;
      HaveCluster := True;
      ClusterWidth := W;
      JoinNext := False;
    end;
  end;
  FlushCluster;
end;

{ CStrDisplayWidth - same as StringDisplayWidth but skips ~ hotkey markers }

function CStrDisplayWidth(const S: string): Integer;
var
  I, Len, W, ClusterWidth: Integer;
  CP: Cardinal;
  HaveCluster, JoinNext: Boolean;

  procedure FlushCluster;
  begin
    if HaveCluster then
    begin
      Inc(Result, ClusterWidth);
      HaveCluster := False;
      ClusterWidth := 0;
    end;
  end;

begin
  Result := 0;
  Len := Length(S);
  I := 1;
  ClusterWidth := 0;
  HaveCluster := False;
  JoinNext := False;
  while I <= Len do
  begin
    if S[I] = '~' then
    begin
      Inc(I); { Skip tilde marker }
      Continue;
    end
    else if (I < Len) and
            (Ord(S[I]) >= $D800) and (Ord(S[I]) <= $DBFF) and
            (Ord(S[I+1]) >= $DC00) and (Ord(S[I+1]) <= $DFFF) then
    begin
      CP := $10000 + Cardinal((Ord(S[I]) - $D800) shl 10) + Cardinal(Ord(S[I+1]) - $DC00);
      Inc(I, 2);
    end
    else
    begin
      CP := Ord(S[I]);
      Inc(I);
    end;
    W := CodePointCharWidth(CP);

    if W = 0 then
    begin
      if HaveCluster then
      begin
        if (CP = $FE0F) and (ClusterWidth = 1) then
          ClusterWidth := 2;
        if CP = $200D then
          JoinNext := True;
      end;
      Continue;
    end;

    if HaveCluster and JoinNext then
    begin
      if W > ClusterWidth then
        ClusterWidth := W;
      JoinNext := False;
    end
    else
    begin
      FlushCluster;
      HaveCluster := True;
      ClusterWidth := W;
      JoinNext := False;
    end;
  end;
  FlushCluster;
end;

{ CopyDisplayCells - returns whole grapheme clusters that fit within a
  display-cell slice. StartCol is zero-based and MaxWidth is in terminal
  cells; wide/emoji clusters are either included whole or omitted. }

function CopyDisplayCells(const S: string; StartCol, MaxWidth: Integer): string;
var
  I, Len, W, Col, EndCol, ClusterWidth: Integer;
  CP: Cardinal;
  CellStr, ClusterText: string;
  HaveCluster, JoinNext: Boolean;

  procedure FlushCluster;
  begin
    if not HaveCluster then Exit;
    if (Col >= StartCol) and (Col + ClusterWidth <= EndCol) then
      Result := Result + ClusterText;
    Inc(Col, ClusterWidth);
    HaveCluster := False;
    ClusterText := '';
    ClusterWidth := 0;
  end;

begin
  Result := '';
  if StartCol < 0 then StartCol := 0;
  if MaxWidth <= 0 then Exit;

  EndCol := StartCol + MaxWidth;
  Len := Length(S);
  I := 1;
  Col := 0;
  ClusterWidth := 0;
  ClusterText := '';
  HaveCluster := False;
  JoinNext := False;
  while I <= Len do
  begin
    if (I < Len) and
       (Ord(S[I]) >= $D800) and (Ord(S[I]) <= $DBFF) and
       (Ord(S[I+1]) >= $DC00) and (Ord(S[I+1]) <= $DFFF) then
    begin
      CP := $10000 + Cardinal((Ord(S[I]) - $D800) shl 10) + Cardinal(Ord(S[I+1]) - $DC00);
      CellStr := S[I] + S[I+1];
      Inc(I, 2);
    end
    else
    begin
      CP := Ord(S[I]);
      CellStr := S[I];
      Inc(I);
    end;

    W := CodePointCharWidth(CP);
    if W = 0 then
    begin
      if HaveCluster then
      begin
        ClusterText := ClusterText + CellStr;
        if (CP = $FE0F) and (ClusterWidth = 1) then
          ClusterWidth := 2;
        if CP = $200D then
          JoinNext := True;
      end;
      Continue;
    end;

    if HaveCluster and JoinNext then
    begin
      ClusterText := ClusterText + CellStr;
      if W > ClusterWidth then
        ClusterWidth := W;
      JoinNext := False;
    end
    else
    begin
      FlushCluster;
      if Col >= EndCol then
        Break;
      HaveCluster := True;
      ClusterText := CellStr;
      ClusterWidth := W;
      JoinNext := False;
    end;
  end;
  FlushCluster;
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
