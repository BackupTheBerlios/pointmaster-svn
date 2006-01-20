Unit Register;

INTERFACE
Uses
{$IFDEF VIRTUALPASCAL}
Use32,
{$ENDIF}
Crc_32,Drivers;

Type
 RegisterInformation=Record
   Name:String[70];
   CRC:System.LongInt;
   Offset:System.Word;
   BackGround:System.Byte;
   TextColor:System.Byte;
End;
{
[Registered to: '
}
Function GetUnCryptedString(S:String;CRC:LongInt):String;
Procedure ReadKeyFile(FName:String;Var Ri:RegisterInformation);
Procedure WriteKeyFile(FName:String;RegName:String);

IMPLEMENTATION

Function GetCryptedString(S:String;CRC:System.LongInt):String;
Var
Counter:System.Byte;
Begin
GetCryptedString:='';
If S='' Then
   Exit;
Crc:=(Crc mod Crc)+Crc;
For Counter:=1 To Length(S) Do
   Begin
    If Counter<=1 Then
       S[Counter]:=Chr((Ord(S[Counter]) Xor Byte(Crc)))
    Else
       S[Counter]:=Chr((Ord(S[Counter]) Xor Byte(Crc)) Xor (Ord(S[Counter-1])))
   End;
GetCryptedString:=S;
End;

Function GetUnCryptedString(S:String;CRC:System.LongInt):String;
Var
Counter:System.Byte;
Begin
GetUnCryptedString:='';
If S='' Then
   Exit;
Crc:=(Crc mod Crc)+Crc;
For Counter:=Length(S) DownTo 1 Do
   Begin
    If Counter<=1 Then
       S[Counter]:=Chr((Ord(S[Counter]) Xor Byte(Crc)))
    Else
       S[Counter]:=Chr((Ord(S[Counter]) Xor Byte(Crc)) Xor (Ord(S[Counter-1])))
   End;
GetUnCryptedString:=S;
End;

Function GetStringOffset(S:String):System.Word;
Begin
 GetStringOffset:=0;
 If S='' Then
    Exit;
 GetStringOffset:=(80*2*8)+( (37-( Round((Length(S)+18)/2)))*2);
End;

Procedure WriteKeyFile(FName:String;RegName:String);
Var
F:File;
Ri:RegisterInformation;
Offset:System.Byte;
Crc:System.Longint;
Begin
Assign(F,FName);
Rewrite(F);
FillChar(Ri,SizeOf(Ri),#0);
Ri.Crc:=GetBadCrc32OfString(RegName);
Ri.OffSet:=GetStringOffset(RegName) Xor Ri.Crc;
Ri.Name:=GetCryptedString(RegName,Ri.Crc);
Ri.BackGround:=1 Xor Ri.Offset;
Ri.TextColor:=12 Xor Ri.Offset;
BlockWrite(F,Ri,SizeOf(Ri));
Close(F);
End;

Procedure ReadKeyFile(FName:String;Var Ri:RegisterInformation);
Var
F:File;
Begin
FillChar(Ri,SizeOf(Ri),#0);
Assign(F,FName);
{$I-}
Reset(F,1);
{$I+}
If IOResult=0 Then
  Begin
    {$I-}
    BlockRead(F,Ri,SizeOf(Ri));
    If IOResult<>0 Then
        FillChar(Ri,SizeOf(Ri),#0);
    Close(F);
    {$I+}
    If IOResult<>0 Then;
  End;
End;


Begin
End.
