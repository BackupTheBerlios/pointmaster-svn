UNIT MCommon;
 {$I VERSION.INC}

INTERFACE
Uses

{$IFDEF VIRTUALPASCAL}
  Use32,
{$ENDIF}
Crt,Dos,StrUnit,Objects,Incl,Address,Strings{,App,Menus,Drivers,Views,Memory,HistList};


{.IFDEF VIRTUALPASCAL}
Function NewStr (S: String): PString;
{.ENDIF}
Function GetAttributesFromString(S:String):Word;
Function GetErrorString(Err_Num:Integer):String;
Procedure ReadLnFromFile(Var F:File;Var S:String);
Procedure ReadLnFromMsg(Var F:File;Var S:String);
Function IsWildcardMatch(Mask,Source:String):Boolean;

{ *** begin getopt functions *** }
Function IsGetOptionValue(Name:String;Var Value:String):Boolean;
Function IsGetOption(Name:String):Boolean;
Function IsGetOptionNext(Name:String;CStart:Word;Var PCount:Word;Var Value:String):Boolean;
{Function GetOptionInt(Name:String;Var Value:Integer):Boolean;}

IMPLEMENTATION

Uses Logger,Parser,Face;

Procedure ReadLnFromMsg(Var F:File;Var S:String);
Begin
 ReadLnFromFile(F,S);
End;

Procedure ReadLnFromFile(Var F:File;Var S:String);
Var
{   S:                 String;}
   Buf:               Array[1..512] Of Char;
   NumRead,
   Counter,
   BufPos:            Integer;
   EoLnFound:         Boolean;
Begin
 S:='';
 EoLnFound:=False;
 If (Not EoF(F)) Then
    Begin
         BlockRead(F,Buf,SizeOf(Buf),NumRead);
         For Counter:=1 To NumRead Do
             Begin
                  If Buf[Counter] in [#13{,#10}] Then
                     Begin
                          EoLnFound:=True;
                          BufPos:=Counter+1;
                          If ((Counter+1)<=NumRead) And
                             (Buf[Counter+1] in [{#13,}#10]) Then
                             Inc(BufPos);
                          Buf[BufPos]:=#0;
                          S:=StrPas(@Buf);
                          Seek(F,FilePos(F)-((NumRead-BufPos+1)));
                          Break;
                     End;

             End;
         If (Not EoLnFound) Then
            Begin
                 If NumRead>255 Then
                    Buf[256]:=#0
                 Else
                     Buf[NumRead+1]:=#0;
                 S:=StrPas(@Buf);
            End;
    End;
 If S[Length(S)]=#10 Then
    Delete(S,Length(S),1);
 If S[Length(S)]=#13 Then
    Delete(S,Length(S),1);
End;

{.IFDEF VIRTUALPASCAL}
Function NewStr (S: String): PString;
Var
 P:      PString;
 Counter:Word;
Begin
   If S='' Then
      Begin
{            LogWriteLn('!Function ''NewStr(String)'' called with empty string. Make '' ''');}
            S:=' ';
      End;
   Counter:=0;
   Begin                                              { Empty returns nil }
     While (MaxAvail< (Length(S)+1)) And (Counter<20) Do
        Begin
             LogWriteLn('!Not enough memory to allocate string '''+S+'''. Pause for 2 seconds.');
             Delay(2000);
             Inc(Counter);
        End;
     GetMem(P, Length(S) + 1);                        { Allocate memory }
     If (P <> Nil) Then
         P^ := S;                                     { Transfer string }
   End;
   NewStr := P;                                       { Return result }
End;
{.ENDIF}

Function GetErrorString(Err_Num:Integer):String;
Var
TPas_Err:String;
Begin
 TPas_Err:='';
 Case Err_Num Of
                1: TPas_Err := 'Invalid DOS function code';
                2: TPas_Err := 'File not found';
                3: TPas_Err := 'Path not found';
                4: TPas_Err := 'Too many open files';
                5: TPas_Err := 'File access denied';
                6: TPas_Err := 'Invalid file handle';
                8: TPas_Err := 'Not enough memory';
               10: TPas_Err := 'Invalid environment';
               11: TPas_Err := 'Invalid format';
               12: TPas_Err := 'Invalid file access code';
               15: TPas_Err := 'Invalid drive number';
               16: TPas_Err := 'Cannot remove current directory';
               17: TPas_Err := 'Cannot rename across drives';
               18: TPas_Err := 'No more files';
              100: TPas_Err := 'Disk read error';
              101: TPas_Err := 'Disk write error';
              102: TPas_Err := 'File not assigned';
              103: TPas_Err := 'File not open';
              104: TPas_Err := 'File not open for input';
              105: TPas_Err := 'File not open for output';
              106: TPas_Err := 'Invalid numeric format';
              150: TPas_Err := 'Disk is write-protected';
              151: TPas_Err := 'Unknown unit';
              152: TPas_Err := 'Drive not ready';
              153: TPas_Err := 'Unknown command';
              154: TPas_Err := 'CRC error in data';
              155: TPas_Err := 'Bad Drive request structure length';
              156: TPas_Err := 'Disk seek error';
              157: TPas_Err := 'Unknown media type';
              158: TPas_Err := 'Sector not found';
              159: TPas_Err := 'Printer out of Paper';
              160: TPas_Err := 'Device write fault';
              161: TPas_Err := 'Device read fault';
              162: TPas_Err := 'Hardware failure';
              200: TPas_Err := 'Division by zero';
              201: TPas_Err := 'Range check error';
              202: TPas_Err := 'Stack overflow error';
              203: TPas_Err := 'Heap overflow error';
              204: TPas_Err := 'Invalid pointer operation';
              205: TPas_Err := 'Floating point overflow';
              206: TPas_Err := 'Floating point underflow';
              207: TPas_Err := 'Invalid floating point operation';
              208: TPas_Err := 'Overlay manager not installed';
              209: TPas_Err := 'Overlay file read error';
              210: TPas_Err := 'Object not initialized';
              211: TPas_Err := 'Call to abstract method';
              212: TPas_Err := 'Stream registration error';
              213: TPas_Err := 'Collection index out of range';
              214: TPas_Err := 'Collection overflow error';
              215: TPas_Err := 'Arithmetic overflow error';
              216: TPas_Err := 'General protection fault';
              Else TPas_Err := 'Unknown Error code';
     End;
  GetErrorString:=TPas_Err;
End;


Function GetAttributesFromString(S:String):Word;
Var
   Attr:        Word;
   Count:       Byte;
Begin
{$IFNDEF SPLE}
  Attr:=0;
  S:=StrUp(StrTrim(S));
  If (S)<>'' Then
     Begin
          For Count:=1 To Length(S) Do
              Begin
                     Case (S[Count]) Of
                          'P':       Attr:=Attr or _attrPrivate;
                          'C':       Attr:=Attr or _attrCrash;
                          'R':       Attr:=Attr or _attrReceived;
                          'S':       Attr:=Attr or _attrSent;
                          'A':       Attr:=Attr or _attrAttach;
                          'T':       Attr:=Attr or _attrInTransit;
                          'O':       Attr:=Attr or _attrOrphan;
                          'K':       Attr:=Attr or _attrKillSent;
                          'L':       Attr:=Attr or _attrLocal;
                          'H':       Attr:=Attr or _attrHold;
                          'F':       Attr:=Attr or _attrFRQ;
                     End;
              End;
     End;
  GetAttributesFromString:=Attr;
{$ENDIF}
End;

Function IsGetOptionNext(Name:String;CStart:Word;Var PCount:Word;Var Value:String):Boolean;
Var
   Counter:     Word;
   PName:       String;
Begin
     IsGetOptionNext:=False;
     PCount:=0;
     Name:=StrTrim(Name);
     Value:='';
     If (ParamCount=0) or (Name='') Or (CStart>ParamCount) Then
        Exit;
     For Counter:=(CStart+1) To ParamCount Do
         Begin
              PName:=ParamStr(Counter);
              If (PName[1]='-') Or (PName[1]='/') Then
                 Delete(PName,1,1);
{              PName:=StrUp(PName);}
              If (IsWildCardMatch(StrUp(Name),StrUp(PName))) Then
                 Begin
                      IsGetOptionNext:=True;
                      PCount:=Counter;
                      Value:=PName;
                      Exit;
                 End;
         End;
End;

Function IsGetOptionValue(Name:String;Var Value:String):Boolean;
Const
     PCount:Word=0;
Begin
     IsGetOptionValue:=IsGetOptionNext(Name,PCount,PCount,Value);
End;

Function IsGetOption(Name:String):Boolean;
Const
     PCount:Word=0;
     Value:String='';
Begin
     IsGetOption:=IsGetOptionNext(Name,PCount,PCount,Value);
End;

{Function GetOptionInt(Name:String;Var Value:Integer):Boolean;
Begin
End;}

Function  IsWildCardMatch(Mask,Source:String):Boolean;
Var
Count,Count1:Word;
Begin
IsWildcardMatch:=True;
Count:=1;
Count1:=1;
If Pos('*',Mask)= 0 Then
   Begin
    IsWildcardMatch:=StrUp(Mask)=StrUp(Source);
    Exit;
   End;
While Count<=Length(Mask) Do
 Begin
  If (Count>Length(Source)) or (Count>Length(Mask)) Then
   Begin
     IsWildcardMatch:=False;
     Break;
   End;
  Case Mask[Count] Of
    #00..#41,#43..#255:
             Begin
              If Count<=Length(Source) Then
                Begin
                  If Source[Count]=Mask[Count] Then
                     Begin
                      Inc(Count);
                     End
                 Else
                     Begin
                      IsWildcardMatch:=False;
                      Break;
                     End;
                End
             Else
                Break;
             End;
    '*':
        Begin
         While Count<=Length(Source) Do
           Begin
           If Count<Length(Mask) Then
              Begin
               If Pos('*',Copy(Mask,Count+1,Length(Mask)))>0 Then
                  Begin
                   If Pos(Copy(Mask,Count+1,Pos('*',Copy(Mask,Count+1,Length(Mask)))-1),Source)> 0 Then
                      Begin
                       Count:=Pos('*',Copy(Mask,Count+1,Length(Mask)))+Count;
                       Break;
                      End
                  Else
                      Begin
                       IsWildcardMatch:=False;
                       Exit;
                      End;
                  End
               Else
                  Begin
                   If Pos(Copy(Mask,Count+1,Length(Mask)),Source)> 0 Then
                      Begin
                       Count:=Length(Mask);
                       Break;
                      End
                  Else
                      Begin
                       IsWildcardMatch:=False;
                       Exit;
                      End;
                  End;
              End
            Else
             Begin
              Inc(Count);
              Break;
             End;
           End;
        End;
{    'a'..'z','A'..'Z':
                      Begin
                       MaskMatch:=False;
                       Break;
                      End;}
{    #00..#41,#43..#47,
    #58..#255        :
                      Begin
                       IsWildcardMatch:=False;
                       Break;
                      End;}

   End;
 End;
End;



Begin
End.
