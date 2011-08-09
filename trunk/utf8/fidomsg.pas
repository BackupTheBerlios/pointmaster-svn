UNIT FidoMsg;

INTERFACE
{.I-}
{$DEFINE MSGX}   { To use zone/point extensions in header (FTS 0001-15}
Uses
Use32,
Dos,Incl,StrUnit,Parser,Address,Objects,Dates,MCommon,PntL_Obj,FileIO,Logger;

Var
LastMsgIDSerial: longint;  { Used to prevent duplicate MSGID time stamps
                               when 2 messages created within one second }
MsgFile: File;   { The file we write to }
MSG_PID: String;
BytesInMsg:LongInt;
MsgParts:Word;
_Dir:DirStr;
_Dest,_Orig:TAddress;
_To,_From:Str36;
_Subj:Str72;
_Flags:Word;

Type
  PFidoMessage=^TFidoMessage;
  TFidoMessage=Object(TObject)
    PToName,
    PFromName:PChar;
    PMsgBody:PMessageBody;
End;


Function IsCreateMessage(Dir:                DirStr;
                         Destination,Origin: TAddress;
                         ToName,FromName:    Str36;
                         Subject:            str72;
                         Flags:              word
                         ): Boolean;
Function WriteToMessage(Str: String): Boolean;
Function CloseMessage: boolean;
Function MSGIDStr(Zone,Net,Node,Point: integer;
                  Domain: DomainStr): string;

Function ExtractKludge(S:String;MsgRecord:TFidoMsgHeader):Boolean;
Function MsgAlreadyRead(MsgRecord:TFidoMsgHeader):Boolean;
Function MsgAlreadySent(MsgRecord:TFidoMsgHeader):Boolean;
Function MsgWithAttach(MsgRecord:TFidoMsgHeader):Boolean;
Procedure SetMsgIsReaded(Var Msg:File;MsgRecord:TFidoMsgHeader);

IMPLEMENTATION



Function MsgAlreadyRead(MsgRecord:TFidoMsgHeader):Boolean;
Begin
 MsgAlreadyRead:=(MsgRecord._Attr and _attrReceived)<>0;
End;

Function MsgAlreadySent(MsgRecord:TFidoMsgHeader):Boolean;
Begin
 MsgAlreadySent:=(MsgRecord._Attr and _attrSent)<>0;
End;

Function MsgWithAttach(MsgRecord:TFidoMsgHeader):Boolean;
Begin
 MsgWithAttach:=(MsgRecord._Attr and _attrAttach)<>0;
End;

Procedure SetMsgIsReaded(Var Msg:File;MsgRecord:TFidoMsgHeader);
Var
IORes:Integer;
Begin
 MsgRecord._Attr:=MsgRecord._Attr or _attrReceived;
{  Reset(Msg,1);}
   If (Not ResetUnTypedFile(Msg,1) ) Then
      Exit;
{ Seek(Msg,0);}
 If (Not SeekUnTypedFile(Msg,0)) Then
      Exit;
(* {.I-}
 BlockWrite(Msg,MsgRecord,SizeOf(MsgRecord));
 {.I+}*)
 If (Not BlockWriteToUnTypedFile(Msg, MsgRecord, SizeOf(MsgRecord))) Then
   Begin
    LogWriteLn(GetExpandedString(_logCantWriteToMessage));
{    LogWriteDosError(IORes,GetExpandedString(_logDosError));}
   End;
End;


Function ExtractKludge(S:String;MsgRecord:TFidoMsgHeader):Boolean;
Var
BeginPos,EndPos,BeginPos1,EndPos1:Integer;
TmpAddr:TAddress;
Begin
 ExtractKludge:=False;
 If S='' Then
    Exit;
 Delete(S,1,1);
 BeginPos:=Pos(' ',S);
 If BeginPos>0 Then
  Begin
   If StrUp(Copy(S,1,Length(_klgMSGID)))=_klgMSGID Then
     Begin
      Delete(S,1,Length(_klgMSGID)+1);
      S:=StrTrim(S);
      BeginPos1:=Pos('@',S);
      EndPos1:=Pos(' ',S);
      If (BeginPos1<>0) And (EndPos1<>0) Then
         Begin
          BossAddress.Domain:=Copy(S,BeginPos1+1,EndPos1-BeginPos1-1);
          Delete(S,BeginPos1,Length(S));
         End
      Else
         Begin
          BossAddress.Domain:='';
          If EndPos1<>0 Then
             Delete(S,EndPos1,Length(S));
         End;
      SetAddressFromString(S,BossAddress);
     End
  Else
   If StrUp(Copy(S,1,Length(_klgINTL)))=_klgINTL Then
     Begin
      Delete(S,1,Length(_klgINTL)+1);
      S:=StrTrim(S);
      BeginPos1:=Pos(' ',S);
      SetAddressFromString(Copy(S,1,BeginPos1-1),TmpAddr);
      With MsgRecord Do
        Begin
         _DestZone:=TmpAddr.Zone;
         _DestNet:=TmpAddr.Net;
         _DestNode:=TmpAddr.Node;
        End;
     End
  Else
   If Copy(S,1,Length(_klgFMPT))=_klgFMPT Then
     Begin
      Delete(S,1,Length(_klgFMPT)+1);
      S:=StrTrim(S);
      Val(S,BossAddress.Point,EndPos);
      MsgRecord._OrigPoint:=BossAddress.Point;
     End
  Else
   If Copy(S,1,Length(_klgTOPT))=_klgTOPT Then
     Begin
      Delete(S,1,Length(_klgTOPT)+1);
      S:=StrTrim(S);
      Val(S,MsgRecord._DestPoint,EndPos);
     End
  Else
   If StrUp(Copy(S,1,Length(_klgREPLYADDR)))=_klgREPLYADDR Then
     Begin
      Delete(S,1,Length(_klgREPLYADDR)+1);
      S:=StrTrim(S);
      ToEmailName:=S;
      MsgFromGate:=True;
      If Length(S)>36 Then
         Begin
          FillStr(UUCPTag,MsgRecord._From,36);
         End
      Else
         Begin
          FillStr(S,MsgRecord._From,36);
         End;
     End
  Else
   If StrUp(Copy(S,1,Length(_klgREPLYTO)))=_klgREPLYTO Then
     Begin
      Delete(S,1,Length(_klgREPLYTO)+1);
      S:=StrTrim(S);
      MsgFromGate:=True;
      If ToEmailName='' Then
         ToEmailName:=TruncStr(MsgRecord._From);
      BeginPos1:=Pos('@',S);
      EndPos1:=Pos(' ',S);
      If EndPos1=0 Then
         EndPos1:=Length(S)
       Else
         Dec(EndPos1);
      If BeginPos1<>0 Then
         Begin
          BossAddress.Domain:=Copy(S,BeginPos1+1,EndPos1-BeginPos1);
          Delete(S,BeginPos1,Length(S));
         End
      Else
         Begin
          BossAddress.Domain:='';
          If EndPos1<>0 Then
             Delete(S,EndPos1,Length(S));
         End;
      SetAddressFromString(S,BossAddress);
     End;
  End;
End;

Function StrInt(N: Integer): Str16;
Var S: Str16;
Begin
  Str(N,S);
  StrInt:=S;
End;

Procedure CStr(S: String; Var Ps; N: Word);
Var I: Word;
Begin
  FillChar(Ps,N,0);
  I:=0;
  If S[0]>Chr(N-1) Then S[0]:=Chr(N-1);
  For I:=1 To Length(S) Do String(Ps)[Pred(I)]:=(S[I]);
End;

Function StrFill(Num: Word; Len: Word; PadChar: Char): String;
  { Fill a string to "Len" with given character (used by date routines) }
Var S: String;

Begin
  If Len>255 Then
     Len:=255;
  S:='';
  Str(Num,S);
  While Length(S)<Len Do
        Insert(PadChar,S,1);
  StrFill:=S;
End;

Function MsgNumber(S: PathStr): Integer;
Var I,R: Integer;
    D:   DirStr;
    N:   NameStr;
    E:   ExtStr;
Begin
  FSplit(S,D,N,E);
  Val(N,I,R);
  If R > 0 Then
     I := -1;
  MsgNumber := I;
End;


Function HighMsg(Path: String): Integer;
  { Return the highest msg number used in a directory }
Var SRec: SearchRec;
    I,
    High: Integer;
{    S: String[12];}


Begin
  FindFirst(Path+'*.MSG',AnyFile,SRec);
  I:=DosError;
  If I = 3 Then
   Begin
     HighMsg:=-1;
     Exit;
   End;
  High:=0;
  If I = 0 Then
  While DosError = 0 Do
   Begin
     I:=MsgNumber(SRec.Name);
     If I>High Then
        High:=i;
     FindNext(SRec);
   End;
   HighMsg:=High;
End;


Function MSG_Time: Str20;
Var DS:  String[10];
    S:   String[4];
    TS:  String[8];
    Hour,Min,Sec,S100: Word;
    Year,Month,Day,DayOfWeek:Word;

Begin
  GetTime(Hour,Min,Sec,S100);
  GetDate(Year,Month,Day,DayOfWeek);
  Str(Day,Ds);
  If Day<10 Then
     Ds:='0'+Ds;
  ds:=ds+' '+MonthNames[Month];
  str(Year,s);
  ds:=ds+' '+copy(s,3,2);
  ts:=StrFill(Hour,2,'0')+':'+StrFill(Min,2,'0')+':'+StrFill(Sec,2,'0');
  Msg_Time:=Ds + '  '+TS;
end;

Function AddressStr(Zone,Net,Node,Point: integer;
                    Domain: DomainStr): string;
var s: string;


begin
  s:='';
  if Zone > 0 then            { leave zone off if its zero }
   begin
     s := s + StrInt(Zone) + ':';
   end;
  s := s + StrInt(Net) + '/' + StrInt(Node);
  if (Point > 0) or (Domain > '') then s:=s+'.' + StrInt(Point);
  if Domain <> '' then s := s +'@'+Domain;
  AddressStr:=s;
end;


Function MSGIDStr(Zone,Net,Node,Point: integer;
                  Domain: DomainStr): String;
 { Return ^AMSGID: zone:net/node.point@domain<cr/lf> }

Var L: longint;
    S: string[60];
    S1: string[10];
    I: Integer;

Type Long = record
         LowWord, HighWord : Word;
        end;

Const Digits : Array[0..$F] of Char = '0123456789abcdef';

  function HexW(W : Word) : string;
  {-Return hex string for word}
  Begin
    HexW[0] := #4;
    HexW[1] := Digits[hi(W) shr 4];
    HexW[2] := Digits[hi(W) and $F];
    HexW[3] := Digits[lo(W) shr 4];
    HexW[4] := Digits[lo(W) and $F];
  End;

  function HexL(L : LongInt) : string;
  {-Return hex string for LongInt}
  begin
    with Long(L) do
     HexL := HexW(HighWord)+HexW(LowWord);
  end;

begin
  L := GetUnixTime(0,0,0,0,0,0);  { Rev 1.10, use Unix time and avoid dupes }
  While L <= LastMsgIDSerial Do
     Inc(l);
  LastMsgIDSerial := L;
  s1 := HexL(l);
  {DownCaseStr(s1);}
   { Note (Rev 1.3) We add domain ourselves because we want to be able
     to add a zero point which addressstr leaves off
   }
  s := #1'MSGID: '+AddressStr(Zone,Net,Node,Point,Domain);

   { AddressStr leaves off point if zero and no domain }
  if (Point = 0) and (Domain = '') then s:=s+'.0';
  MSGIDStr := s+' '+s1;
end;


{ *********************** }
{ *    The main bits    * }
{ *********************** }

Function WriteToMessage(Str: string): boolean;
Var
MsgHeader:TFidoMsgHeader;
TearLine,Origin:String;
OurAddrInString:String;
OldSubj:String;
NewSubj:Z72;
Count:Word;
begin
  If Length(Str)>79 Then
     Begin
      Insert(#13#10,Str,79);
     End;
  If (BytesInMsg div 1024)>=StrToInt(GetVar(MessageSizeTag.Tag,_varNONE)) Then
     Begin
      TearLine:=TearLineTag+GetVar(TearLineStrTag.Tag,_varNONE);
      SetStringFromAddress(OurAddrInString,_Orig);
      Origin:=OriginTag+GetVar(OriginStrTag.Tag,_varNONE)+' ('+OurAddrInString+')';
      TearLine:=TearLine+#13;
      Origin:=' '+Origin+#13;
      If Length(TearLine)>79 Then
        Begin
{         Insert(#13#10,TearLine,79);}
          Delete(TearLine,80,Length(TearLine)-79);
        End;
      If Length(Origin)>79 Then
        Begin
{         Insert(#13#10,Origin,78);}
          Delete(Origin,80,Length(TearLine)-79);
        End;
      {$I-}
      Blockwrite(MsgFile,TearLine[1],length(TearLine));
      Blockwrite(MsgFile,Origin[1],length(Origin));
      Reset(MsgFile,1);
      Seek(MsgFile,0);
      BlockRead(MsgFile,MsgHeader,SizeOf(MsgHeader));
      {$I+}
      If IOResult<>0 Then;
      OldSubj:=StrTrim(_Subj);
      If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
         OldSubj:=OldSubj+' [Part '+IntToStr(MsgParts)+']'
      Else
         OldSubj:=OldSubj+' [Часть '+IntToStr(MsgParts)+']';
      FillStr(OldSubj,NewSubj,72);
      MsgHeader._Subj:=NewSubj;
      {$I-}
      Seek(MsgFile,0);
      BlockWrite(MsgFile,MsgHeader,SizeOf(MsgHeader));
{      Seek(MsgFile,SizeOf(MsgFile));}
      Seek(MsgFile,FileSize(MsgFile));
      {$I+}
      If IOResult<>0 Then;
      CloseMessage;
      Inc(MsgParts);
      IsCreateMessage(_Dir,_Dest,_Orig,_To,_From,
                      _Subj,_Flags);
     End;
  Str:=Str+#13;
  BytesInMsg:=BytesInMsg+Length(Str);
  {$I-}
  Blockwrite(MsgFile,Str[1],length(Str));
  {$I+}
  WriteToMessage := IOResult = 0;
end;

Function IsCreateMessage(Dir:               DirStr;
                    Destination,Origin: TAddress;
                    ToName,FromName:    Str36;
                    Subject:            str72;
                    Flags:              word
                   ): Boolean;
Var
  Err: Boolean;
  S:   string;
  i:   integer;
  High: integer;
  FidoMessageHeader: TFidoMsgHeader;
  MsgFileName:       String[12];



begin
  IsCreateMessage := False;  { Let's assume we fail! }
  if Dir[length(Dir)] <> '\' then Dir := Dir + '\';
  High:=HighMsg(Dir);
  if High < 0 then exit;  { Bad path }
  inc(High);
  MSGFileName := StrInt(High)+'.MSG';

  fillchar(FidoMessageHeader,sizeof(FidoMessageHeader),0);
   with FidoMessageHeader do
    begin
      cStr(ToName,FidoMessageHeader._To,36);
      cStr(FromName,FidoMessageHeader._From,36);
      cStr(Subject,FidoMessageHeader._Subj,72);
      cStr(MSG_Time,FidoMessageHeader._Date,20);
      FidoMessageHeader._Attr := Flags;
      with Origin do begin
        FidoMessageHeader._OrigNode := Node;
        FidoMessageHeader._OrigNet := Net;
        {.IFDEF MSGX}
        FidoMessageHeader._OrigZone := Zone;
        FidoMessageHeader._OrigPoint := Point;
        {.ENDIF}
      end;
      with Destination do begin
        FidoMessageHeader._DestNode := Node;
        FidoMessageHeader._DestNet := Net;
        {.IFDEF MSGX}
        FidoMessageHeader._DestZone := Zone;
        FidoMessageHeader._DestPoint := Point;
        {.ENDIF}
      end;
    end;
  assign(MSGFile,Dir+MsgFileName);
  {$I-}
  rewrite(MSGFile,1);
  {$I+}
  if ioresult <> 0 then exit;
  {$I-}
  blockwrite(MSGFile,FidoMessageHeader,sizeof(FidoMessageHeader));
  {$I+}
  if ioresult <> 0 then
   begin
     {$I-}
     close(MsgFile);
     {$I+}
     exit;
   end;
{******************************}
  BytesInMsg:=190;
  _Dir:=Dir;
  _Dest:=Destination;
  _Orig:=Origin;
  _To:=ToName;
  _From:=FromName;
  _Subj:=Subject;
  _Flags:=Flags;
{******************************}
  with Destination do S := #1'INTL '+AddressStr(Zone,Net,Node,0,'');
  with Origin do S := S +' '+AddressStr(Zone,Net,Node,0,'');
  Err := Not WriteToMessage(s);
  with Destination do
    if Point <> 0 then Err := not WriteToMessage(#1'TOPT '+StrInt(Point));
  with Origin do
    if Point <> 0 then Err := not WriteToMessage(#1'FMPT '+StrInt(Point));
  with Origin do
    Err := not WriteToMessage(MSGIDStr(Zone,Net,Node,Point,Domain));
  Err := Not WriteToMessage(#1'PID: '+Msg_PID);
  IsCreateMessage := not Err;
End;



Function CloseMessage: boolean;
Var
  Err: boolean;
  MSGHead:TFidoMsgHeader;
  OLdSubj:String;
Const
  EndB: byte = 0;
begin
  {$I-}
  blockwrite(MsgFile,EndB,1);
  Err := ioresult <> 0;
      Reset(MsgFile,1);
  Seek(MsgFile,0);
  Err := ioresult <> 0;
  BlockRead(MsgFile,MSGHead,SizeOf(MSGHead));
  {$I+}
  If (MsgParts>1) And (Pos('[Part',MSGHead._Subj)=0) And (Pos('[Часть',MSGHEad._Subj)=0) Then
     Begin
      OldSubj:=TruncStr72(MSGHead._Subj);
      If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
         OldSubj:=OldSubj+' [Part '+IntToStr(MSgParts)+']'
      Else
         OldSubj:=OldSubj+' [Часть '+IntToStr(MSgParts)+']';
      FillStr(OldSubj,MSGHead._Subj,72);
      {$I-}
      Seek(MsgFile,0);
      BlockWrite(MsgFile,MSGHead,SizeOf(MSGHead));
      Seek(MsgFile,FileSize(MsgFile));
      {$I+}
      MsgParts:=1;
     End;
  {$I-}
  close(MsgFile);
  {$I+}
  Err := ioresult <> 0;
  CloseMessage := NOT Err;
end;

Begin
  LastMsgIDSerial := 0;
  MsgParts:=1;
End.
