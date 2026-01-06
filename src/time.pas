{*******************************************************}
{       Free Vision - Time Unit                         }
{       Ported to Modern Delphi                         }
{*******************************************************}

{
  Time utility functions for getting and setting system time.
  Based on original FPC Free Vision TIME.PAS by Leon de Boer.
}

unit Time;

interface

{ Returns the number of minutes since midnight of current system time.
  Range: 0 - 1439 }
function CurrentMinuteOfDay: Word;

{ Returns the number of seconds since midnight of current system time.
  Range: 0 - 86399 }
function CurrentSecondOfDay: LongInt;

{ Returns the 1/100ths of a second since midnight of current system time.
  Range: 0 - 8639999 }
function CurrentSec100OfDay: LongInt;

{ Returns the number of minutes since midnight of a valid given time.
  Range: 0 - 1439 }
function MinuteOfDay(Hour24, Minute: Word): Word;

{ Returns the number of seconds since midnight of a valid given time.
  Range: 0 - 86399 }
function SecondOfDay(Hour24, Minute, Second: Word): LongInt;

{ Set the operating systems time clock to the given values. If values
  are invalid this function will fail without notification. }
procedure SetTime(Hour, Minute, Second, Sec100: Word);

{ Returns the current time settings of the operating system. }
procedure GetTime(var Hour, Minute, Second, Sec100: Word);

{ Returns the time in hours and minutes of a given number of minutes. }
procedure MinutesToTime(Md: LongInt; var Hour24, Minute: Word);

{ Returns the time in hours, mins and secs of a given number of seconds. }
procedure SecondsToTime(Sd: LongInt; var Hour24, Minute, Second: Word);

implementation

uses
  Winapi.Windows;

function CurrentMinuteOfDay: Word;
var
  Hour, Minute, Second, Sec100: Word;
begin
  GetTime(Hour, Minute, Second, Sec100);
  Result := (Hour * 60) + Minute;
end;

function CurrentSecondOfDay: LongInt;
var
  Hour, Minute, Second, Sec100: Word;
begin
  GetTime(Hour, Minute, Second, Sec100);
  Result := (LongInt(Hour) * 3600) + (Minute * 60) + Second;
end;

function CurrentSec100OfDay: LongInt;
var
  Hour, Minute, Second, Sec100: Word;
begin
  GetTime(Hour, Minute, Second, Sec100);
  Result := (LongInt(Hour) * 360000) + (LongInt(Minute) * 6000) +
            (Second * 100) + Sec100;
end;

function MinuteOfDay(Hour24, Minute: Word): Word;
begin
  Result := (Hour24 * 60) + Minute;
end;

function SecondOfDay(Hour24, Minute, Second: Word): LongInt;
begin
  Result := (LongInt(Hour24) * 3600) + (Minute * 60) + Second;
end;

procedure SetTime(Hour, Minute, Second, Sec100: Word);
var
  DT: TSystemTime;
begin
  GetLocalTime(DT);
  DT.wHour := Hour;
  DT.wMinute := Minute;
  DT.wSecond := Second;
  DT.wMilliseconds := Sec100 * 10;
  SetLocalTime(DT);
end;

procedure GetTime(var Hour, Minute, Second, Sec100: Word);
var
  DT: TSystemTime;
begin
  GetLocalTime(DT);
  Hour := DT.wHour;
  Minute := DT.wMinute;
  Second := DT.wSecond;
  Sec100 := DT.wMilliseconds div 10;
end;

procedure MinutesToTime(Md: LongInt; var Hour24, Minute: Word);
begin
  Hour24 := Md div 60;
  Minute := Md mod 60;
end;

procedure SecondsToTime(Sd: LongInt; var Hour24, Minute, Second: Word);
begin
  Hour24 := Sd div 3600;
  Minute := Sd mod 3600 div 60;
  Second := Sd mod 60;
end;

end.
