Unit Dates;

INTERFACE

Uses
{$IFDEF VIRTUALPASCAL}
 Use32,
{$ENDIF}
 Dos,StrUnit;

Function GetDateString:String;
Function GetTimeString:String;
Function GetDateStringFromDt(Var Dt:DateTime):String;
Function GetDoWString:String;
Function GetDoYString:String;
Function GetYearString:String;
Function GetMonthString:String;
Function GetDayString:String;
Function GetMonthNameString:String;
Function GetUnixTime(Day,Month,Year,Hour,Min,Sec: Word): Longint;
Function IsLeapYear(Y:Word):Boolean;


IMPLEMENTATION


Function IsLeapYear(Y:Word):Boolean;
Begin
 IsLeapYear:=( (Y mod 100<>0) And (Y Mod 4=0) ) or
 ( (Y mod 100=0) And (Y mod 400=0) );
End;

Function GetDateString:String;
Var
Y,M,D,DoW:Word;
S:String;
Begin
 S:='';
 GetDate(Y,M,D,DoW);
 S:=S+LeadZero(D)+'/'+LeadZero(M)+'/'+LeadZero(Y);
 GetDateString:=S;
End;

Function GetTimeString:String;
Var
Hour,Min,Sec,Hund:Word;
S:String;
Begin
 S:='';
 GetTime(Hour,Min,Sec,Hund);
 S:=S+LeadZero(Hour)+':'+LeadZero(Min)+':'+LeadZero(Sec);
 GetTimeString:=S;
End;

Function GetDateStringFromDt(Var Dt:DateTime):String;
Var
S:String;
Begin
 S:='';
 S:=S+LeadZero(Dt.Day)+'/'+LeadZero(Dt.Month)+'/'+LeadZero(Dt.Year);
 Delete(S,Length(S)-3,2);
 GetDateStringFromDt:=S;
End;

Function GetDoWString:String;
Const
Days : array [0..6] of String[9] =
  ('Sunday','Monday','Tuesday',
   'Wednesday','Thursday','Friday',
   'Saturday');
Var
  Y, M, D, DoW : Word;

Begin
 GetDate(Y,M,D,DoW);
 GetDoWString:=Days[DoW];
End;

Function GetDoYString:String;
Const
Monthes:Array[1..12] of Word=(
        31,28,31,30,31,30,31,31,30,31,30,31);
LeapMonthes:Array[1..12] of Word=(
        31,29,31,30,31,30,31,31,30,31,30,31);
Var
Y,M,D,DoW:Word;
Count:Word;
DayOfYear:Word;
S:String;
Begin
 GetDate(Y,M,D,DoW);
 DayOfYear:=0;
 If IsLeapYear(Y) Then
    For Count:=1 To M-1 Do
       DayOfYear:=DayOfYear+Monthes[Count]
 Else
    For Count:=1 To M-1 Do
       DayOfYear:=DayOfYear+LeapMonthes[Count];

 DayOfYear:=DayOfYear+D;
 S:=IntToStr(DayOfYear);
 If Length(S)=1 Then
    S:='00'+S
Else
 If Length(S)=2 Then
    S:='0'+S;
 GetDoYString:=S;
End;

Function GetYearString:String;
Var
S:String;
Y,M,D,DoW:Word;
Begin
 S:='';
 GetDate(Y,M,D,DoW);
 S:=S+LeadZero(Y);
 GetYearString:=S;
End;

Function GetMonthString:String;
Var
S:String;
Y,M,D,DoW:Word;
Begin
 S:='';
 GetDate(Y,M,D,DoW);
 S:=S+LeadZero(M);
 GetMonthString:=S;
End;

Function GetMonthNameString:String;
Const
Monthes : array [1..12] of String[9] =
  ('January','February','March',
   'April','May','June',
   'July','August','September',
   'October','November','December');
Var
Y,M,D,DoW:Word;
Begin
 GetMonthNameString:='';
 GetDate(Y,M,D,DoW);
 GetMonthNameString:=Monthes[M];
End;

Function GetDayString:String;
Var
S:String;
Y,M,D,DoW:Word;
Begin
 S:='';
 GetDate(Y,M,D,DoW);
 S:=S+LeadZero(D);
 GetDayString:=S;
End;

Function GetUnixTime(Day,Month,Year,Hour,Min,Sec: word): longint;
  { Return unix time (secs since 1/1/1970). On UNIX system this would#
    always be GMT so here we try to get to GMT using a GMT env var. If
    that's not set then we are stuck with whatever the system clock says.

   *** In case of future concern note that this routine has been checked
       against Turbo C's TIME function and returns an exactly correct
       value for all tests (including in/after leap years).

       This routine is *CORRECT*
  }
var Mf,l,r: longint;
    DayOfWeek,Sec100: word;

begin
  if Day = 0 then
   begin
     getdate(Year,Month,Day,DayOfWeek);
     gettime(Hour,Min,Sec,Sec100);
   end;
  Mf:=0;
  IF Month<3 then Mf:=1;
  if (Year < 1900) then if Year<70 then Year:=Year+2000
    else Year:=Year+1900;
  R:=Longint((36525*(Year-Mf)) div 100) +
    Longint((3060*(Month+1+Mf*12)) div 100)+longint(Day)-longint(719606);
  GetUnixTime := (r * 86400) + (longint(Hour) * 3600) + (Min * 60) + Sec;
end;

Begin
End.
