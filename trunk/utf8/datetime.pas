Unit DateTime;

INTERFACE

Function GetDateString:String;
Function GetTimeString:String;
Function GetDateStringFromDt(Var Dt:DateTime):String;
Function GetDoWString:String;
Function GetDoYString:String;
Function GetYearString:String;
Function GetMonthString:String;
Function GetDayString:String;
Function GetMonthNameString:String;

IMPLEMENTATION


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
Var
Y,M,D,DoW:Word;
Count:Word;
DayOfYear:Word;
S:String;
Begin
 GetDate(Y,M,D,DoW);
 DayOfYear:=0;
 For Count:=1 To M-1 Do
     DayOfYear:=DayOfYear+Monthes[Count];
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

Begin
End.