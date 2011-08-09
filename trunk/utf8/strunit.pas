UNIT StrUnit;

{$I VERSION.INC}

INTERFACE
Uses
Use32,
Incl,Dos,Drivers;
{Type
  Z36=Array[1..36] of Char;}

Procedure SplitFileName(S:String;Var D:DirStr;Var N:NameStr;Var E:ExtStr);
Function DownCase(Ch:Char):Char;
Function PadLeft(S:String):String;
Function PadRight(S:String):String;
Function StrUp(S:String):String;
Function StrDown(S:String):String;
Function TruncStr(A:Z36):String;
Function TruncStr72(A:Z72):String;
Procedure FillStr(S: String; Var Ps; N: Word);
Function LeadZero(W:LongInt):String;
Function LeadTwoZero(W:Longint):String;
Function IntToStr(I:LongInt):String;
Function StrTrim(S:String):String;
Function LeftStrTrimByChar(S:String;Ch:Char):String;
Function RightStrTrimByChar(S:String;Ch:Char):String;
Function CharPos(S:String):Integer;
Function StrToInt(S:String):LongInt;
Function ByteToChar(B:Byte):Char;
Function TrueUpCase (C: Char): Char;
Function LeftCharPad(S:String;Ch:Char;Count:Word):String;
Function RightCharPad(S:String;Ch:Char;Count:Word):String;
Function LeftSpacePad(S:String;Count:Word):String;
Function RightSpacePad(S:String;Count:Word):String;
Function GetFNameAndExt(S:String):String;
Function GetFName(S:String):String;
Function CharsToString(A:Array Of Char):String;
Function GetFormattedString(Format: String; var Params):String;
Procedure GetTwoTrimmedParamsFromString(Source:String;Var Param1:String;Var Param2:String);
Procedure ExtractTwoParamsFromCommentedString(Source:String;Var Param1:String;Var Param2:String);
Procedure ReplaceTabsWithSpaces(Var S:String);
Procedure DeleteSpacesInString(Var S:String);
Procedure DeleteCharInString(Var S:String;Ch:Char);

function Byte2Hex(B : Byte) : string;
  {-Return hex string for byte}

function Word2Hex(W : Word) : string;
  {-Return hex string for word}

function Long2Hex(L : LongInt) : string;

IMPLEMENTATION

type
  Long =
    record
      LowWord, HighWord : Word;
    end;

const
  Digits : array[0..$F] of Char = '0123456789ABCDEF';


Function DownCase(Ch:Char):Char;
Begin
 Case Ch Of
    'A'..'Z',
    'А'..'П':Inc(Ch,32);
    'Р'..'Я':Inc(Ch,80);
  End;
 DownCase:=Ch;
End;

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

Function LeftStrTrimByChar(S:String;Ch:Char):String;
Begin
While ((S[1] =Ch)) Do
 Begin
   If S='' Then
      Break;
   Delete(S,1,1);
 End;
LeftStrtrimByChar:=S;
End;

Function RightStrTrimByChar(S:String;Ch:Char):String;
Begin
 While (S[Length(S)] =Ch) Do
    Begin
     If S='' Then
        Break;
     Delete(S,Length(S),1);
    End;
RightStrTrimByChar:=S;
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
{ If S[Count] In ['a'..'z'] Then
    S[Count]:=Chr(Ord('A')+Ord(S[Count])-Ord('a'))
Else
 If S[Count] In ['а'..'п'] Then
    S[Count]:=Chr(Ord('А')+Ord(S[Count])-Ord('а'))
Else
 If S[Count] In ['р'..'я'] Then
    S[Count]:=Chr(Ord('Р')+Ord(S[Count])-Ord('р'));}
 Begin
  Case S[Count] Of
    'a'..'z',
    'а'..'п':Dec(S[Count],32);
    'р'..'я':Dec(S[Count],80);
  End;
 End;
StrUp:=S;
End;

Function TrueUpCase(C:Char):Char;
Begin
  Case C Of
    'a'..'z',
    'а'..'п':Dec(C,32);
    'р'..'я':Dec(C,80);
  End;
TrueUpCase:=C;
End;

Function StrDown(S:String):String;
Var
Count:Integer;
Begin
If S='' Then
   Begin
    StrDown:=S;
    Exit;
   End;
For Count:=1 To Length(S) Do
{ If S[Count] In ['A'..'Z'] Then
    S[Count]:=Chr(Ord('a')+Ord(S[Count])-Ord('A'))
Else
 If S[Count] In ['А'..'П'] Then
    S[Count]:=Chr(Ord('а')+Ord(S[Count])-Ord('А'))
Else
 If S[Count] In ['Р'..'Я'] Then
    S[Count]:=Chr(Ord('р')+Ord(S[Count])-Ord('Р'));}
 Begin
 Case S[Count] Of
    'A'..'Z',
    'А'..'П':Inc(S[Count],32);
    'Р'..'Я':Inc(S[Count],80);
  End;
 End;
StrDown:=S;
End;

Function TruncStr(A:Z36):String;
Var
CS:String;
Cnt:Byte;
NullPos:Byte;
Begin
CS:='';
NullPos:=Pos(#0,A);
If NullPos >0 Then
  Begin
  For Cnt:=1 To NullPos-1 Do
  CS:=Concat(CS,A[Cnt]);
  End
Else
  Begin
  For Cnt:=1 To SizeOf(A) Do
  CS[Cnt]:=A[Cnt];
  End;
TruncStr:=CS;
CS:='';
End;

Function TruncStr72(A:Z72):String;
Var
CS:String;
Cnt:Byte;
NullPos:Byte;
Begin
CS:='';
NullPos:=Pos(#0,A);
If NullPos >0 Then
  Begin
  For Cnt:=1 To NullPos-1 Do
  CS:=Concat(CS,A[Cnt]);
  End
Else
  Begin
  For Cnt:=1 To SizeOf(A) Do
  CS[Cnt]:=A[Cnt];
  End;
TruncStr72:=CS;
{CS:='';}
End;

Procedure FillStr(S: String; Var Ps; N: Word);
Var I: Word;
Begin
  FillChar(Ps,N,0);
  I:=0;
  If S[0]>Chr(N-1) Then S[0]:=Chr(N-1);
 { For I:=1 To Length(S) Do Mem[Seg(Ps):Ofs(Ps)+Pred(I)]:=Ord(S[I]);}
 { For I:=1 To Length(S) Do Ps[Pred(I)]:=Ord(S[I]);}
  For I:=1 To Length(S) Do String(Ps)[Pred(I)]:=(S[I]);
End;

Function LeadZero(W:LongInt):String;
Var
S:String;
Begin
Str(W:0,S);
If Length(S)=1 Then
 S:='0'+S;
LeadZero:=S;
End;

Function LeadTwoZero(W:Longint):String;
Var
S:String;
Begin
Str(W:0,S);
Case Length(S) Of
     1: S:='00'+S;
     2: S:='0'+S;
    End;
LeadTwoZero:=S;
End;


Function IntToStr(I:LongInt):String;
Var
S:String;
Begin
Str(I,S);
IntToStr:=S;
End;

Function ByteToChar(B:Byte):Char;
Var
S:String;
Begin
 Str(B,S);
 ByteToChar:=S[1];
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
I:LongInt;
Code:Integer;
Begin
 I:=0;
 Code:=0;
 Val(S,I,Code);
 StrToInt:=I;
End;

{  procedure UpperCase; near; assembler;
   asm
        CMP     AL, 'a'
        JB      @@1
        CMP     AL, 'z'
        JBE     @@2
        CMP     AL, 'а'
        JB      @@1
        CMP     AL, 'п'
        JBE     @@2
        CMP     AL, 'р'
        JB      @@1
        CMP     AL, 'я'
        JBE     @@3
        CMP     AL, 'ё'
        JNE     @@1
        DEC     AL
        JMP     @@1
@@3:    SUB     AL, 30H
@@2:    SUB     AL, 20H
@@1:
   end;
  function TrueUpCase; assembler;
   asm
        MOV     AL, C
        CALL    UpperCase
   end;}


Function LeftCharPad(S:String;Ch:Char;Count:Word):String;
Var
Counter:Word;
Begin
For Counter:=1 To Count Do
    S:=Ch+S;
LeftCharPad:=S;
End;
Function RightCharPad(S:String;Ch:Char;Count:Word):String;
Var
Counter:Word;
Begin
End;
Function LeftSpacePad(S:String;Count:Word):String;
Var
Counter:Word;
Begin
For Counter:=1 To Count Do
    S:=' '+S;
LeftSpacePad:=S;
End;
Function RightSpacePad(S:String;Count:Word):String;
Var
Counter:Word;
Begin
If Count>Length(S) Then
   For Counter:=1 To Count-Length(S) Do
       S:=S+' ';
RightSpacePad:=S;
End;

Procedure SplitFileName(S:String;Var D:DirStr;Var N:NameStr;Var E:ExtStr);
Begin
 FSplit(S,D,N,E);
End;

Function GetFNameAndExt(S:String):String;
Var
D: DirStr;
N: NameStr;
E: ExtStr;
Begin
 SplitFileName(S,D,N,E);
 GetFNameAndExt:=N+E;
End;

Function GetFName(S:String):String;
Var
D: DirStr;
N: NameStr;
E: ExtStr;
Begin
 SplitFileName(S,D,N,E);
 GetFName:=N;
End;


Function CharsToString(A:Array Of Char):String;
Var
Count:Word;
S:String;
Begin
 CharsToString:='';
 S:='';
 For Count:=0 To Pred(SizeOf(A)) Do
  S:=S+A[Count];
 CharsToString:=S;
End;

Function GetFormattedString(Format: String; var Params):String;
Var
S:String;
Begin
 S:='';
 FormatStr(S,Format,Params);
 GetFormattedString:=S;
End;

Procedure GetTwoTrimmedParamsFromString(
                                        Source:String;
                                        Var Param1:String;
                                        Var Param2:String);
Var
SpacePos:Byte;
Begin
Param1:='';
Param2:='';
Source:=StrTrim(Source);
If Source='' Then
   Exit;
SpacePos:=Pos(' ',Source);
If SpacePos<>0 Then
   Begin
    Param1:=Copy(Source,1,SpacePos-1);
    Param2:=PadLeft(Copy(Source,SpacePos+1,Length(Source)-SpacePos));
   End;
End;

Procedure ExtractTwoParamsFromCommentedString(Source:String;Var Param1:String;Var Param2:String);
Var
EqualPos:Byte;
Begin
Param1:='';
Param2:='';
Source:=StrTrim(Source);
If Source='' Then
   Exit;
{If Source[1]='"' Then
   Delete(Source,1,1);
If Source[Length(Source)]='"' Then
   Delete(Source,Length(Source),1);}
EqualPos:=Pos('=',Source);
If EqualPos<>0 Then
   Begin
    Param1:=Copy(Source,1,EqualPos-1);
    Param2:=PadLeft(Copy(Source,EqualPos+1,Length(Source)-EqualPos));
   End;
End;

Procedure ReplaceTabsWithSpaces(Var S:String);
Var
TabPos:Byte;
Begin
 TabPos:=Pos(#9,S);
 While TabPos>0 Do
   Begin
    Delete(S,TabPos,1);
    TabPos:=Pos(#9,S);
   End;
End;

Procedure DeleteSpacesInString(Var S:String);
Var
SpaceP:Byte;
Begin
 SpaceP:=Pos(' ',S);
 While SpaceP>0 Do
  Begin
   Delete(S,SpaceP,1);
   SpaceP:=Pos(' ',S);
  End;

 SpaceP:=Pos(#9,S);
 While SpaceP>0 Do
  Begin
   Delete(S,SpaceP,1);
   SpaceP:=Pos(#9,S);
  End;
End;

Procedure DeleteCharInString(Var S:String;Ch:Char);
Var
SpaceP:Byte;
Begin
 SpaceP:=Pos(Ch,S);
 While SpaceP>0 Do
  Begin
   Delete(S,SpaceP,1);
   SpaceP:=Pos(Ch,S);
  End;
End;


function Byte2Hex(B : Byte) : string;
    {-Return hex string for byte}
  begin
    Byte2Hex[0] := #2;
    Byte2Hex[1] := Digits[B shr 4];
    Byte2Hex[2] := Digits[B and $F];
  end;

function Word2Hex(W : Word) : string;
    {-Return hex string for word}
  begin
    Word2Hex[0] := #4;
    Word2Hex[1] := Digits[hi(W) shr 4];
    Word2Hex[2] := Digits[hi(W) and $F];
    Word2Hex[3] := Digits[lo(W) shr 4];
    Word2Hex[4] := Digits[lo(W) and $F];
  end;

function Long2Hex(L : LongInt) : string;
    {-Return hex string for LongInt}
  begin
    with Long(L) do
      Long2Hex := Word2Hex(HighWord)+Word2Hex(LowWord);
  end;


Begin
End.
