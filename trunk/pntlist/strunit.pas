UNIT StrUnit;

INTERFACE
Uses Incl;
{Type
  Z36=Array[1..36] of Char;}

Function PadLeft(S:String):String;
Function PadRight(S:String):String;
Function StrUp(S:String):String;
Function TruncStr(A:Z36):String;
Function TruncStr72(A:Z72):String;
Procedure FillStr(S: String; Var Ps; N: Word);
Function LeadZero(W:Word):String;
Function IntToStr(I:LongInt):String;
Function StrTrim(S:String):String;
Function CharPos(S:String):Integer;
Function StrToInt(S:String):LongInt;

IMPLEMENTATION

Function PadLeft(S:String):String;
Begin
While ((S[1] =' ') or (S[1]=#9)) Do
 Begin
   If S='' Then
      Break;
   Delete(S,1,1);
 End;
PadLeft:=S;
End;

Function PadRight(S:String):String;
Begin
 While ((S[Length(S)] =' ') or (S[Length(S)]=#9)) Do
    Begin
     If S='' Then
        Break;
     Delete(S,Length(S),1);
    End;
PadRight:=S;
End;

Function StrUp(S:String):String;
Var
Count:Integer;
Begin
If S='' Then
   Begin
    StrUp:=S;
    Exit;
   End;
For Count:=1 To Length(S) Do
 If S[Count] In ['a'..'z'] Then
    S[Count]:=Chr(Ord('A')+Ord(S[Count])-Ord('a'))
Else
 If S[Count] In [' '..'¯'] Then
    S[Count]:=Chr(Ord('€')+Ord(S[Count])-Ord(' '))
Else
 If S[Count] In ['à'..'ï'] Then
    S[Count]:=Chr(Ord('')+Ord(S[Count])-Ord('à'));
StrUp:=S;
End;


Function TruncStr(A:Z36):String;
Var
CS:String;
Cnt:Byte;
Begin
CS:='';
If Pos(#0,A) >0 Then
  Begin
  For Cnt:=1 To Pos(#0,A)-1 Do
  CS:=Concat(CS,A[Cnt]);
  End
Else
  Begin
  For Cnt:=1 To Length(A) Do
  CS[Cnt]:=A[Cnt];
  End;
TruncStr:=CS;
CS:='';
End;

Function TruncStr72(A:Z72):String;
Var
CS:String;
Cnt:Byte;
Begin
CS:='';
If Pos(#0,A) >0 Then
  Begin
  For Cnt:=1 To Pos(#0,A)-1 Do
  CS:=Concat(CS,A[Cnt]);
  End
Else
  Begin
  For Cnt:=1 To Length(A) Do
  CS[Cnt]:=A[Cnt];
  End;
TruncStr72:=CS;
CS:='';
End;

Procedure FillStr(S: String; Var Ps; N: Word);
Var I: Word;
Begin
  FillChar(Ps,N,0);
  I:=0;
  If S[0]>Chr(N-1) Then S[0]:=Chr(N-1);
  For I:=1 To Length(S) Do Mem[Seg(Ps):Ofs(Ps)+Pred(I)]:=Ord(S[I]);
End;

Function LeadZero(W:Word):String;
Var
S:String;
Begin
Str(W:0,S);
If Length(S)=1 Then
 S:='0'+S;
LeadZero:=S;
End;

Function IntToStr(I:LongInt):String;
Var
S:String;
Begin
Str(I,S);
IntToStr:=S;
End;

Function StrTrim(S:String):String;
Begin
S:=PadLeft(S);
S:=PadRight(S);
StrTrim:=S;
End;

Function CharPos(S:String):Integer;
Begin
End;

Function StrToInt(S:String):LongInt;
Var
I,Code:Integer;
Begin
 I:=0;
 Val(S,I,Code);
 StrToInt:=I;
End;

Begin
 Asm;
  jmp @quit
{    db ' String Manipulation Unit v.0.01 ',0Dh,0Ah
    db ' Copyright (c) by Andrew Kornilov, 1998. ',0Dh,0Ah
    db ' FidoNet: 2:5045/46.24 ',0Dh,0Ah}
  @quit:
 End;
End.
