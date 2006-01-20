Unit Fido_Def;

INTERFACE

{$I VERSION.INC}

Uses
{$IFDEF VIRTUALPASCAL}
 Use32,
{$ENDIF}
 Obj_Cmn,Objects,Strings,Dos,Check,StrUnit,Parser,Incl;

Const
  _attrPrivate   =  1;
  _attrCrash     =  2;
  _attrReceived  =  4;
  _attrSent      =  8;
  _attrAttach    = 16;      { File Attach}
  _attrInTransit = 32;      { in Transit }
  _attrOrphan    = 64;
  _attrKillSent  = 128;
  _attrLocal     = 256;
  _attrHold      = 512;
  _attrFRQ       = 2048;    { File req    }
  _attrRRQ       = 4096;    { Reciept Req }
  _attrCPT       = 8192;    { is Reciept  }
  _attrARQ       = 16384;   { Audit Req   }
  _attrURQ       = 32768;   { Update Req  }

 MonthNames: array[1..12] of string[3] =
                  ('Jan','Feb','Mar','Apr','May',
                   'Jun','Jul','Aug','Sep','Oct',
                   'Nov','Dec');



Type
  Chars40 = Array[1..40] of Char;
  Chars36 = Array[1..36] of Char;
  Chars20 = Array[1..20] of Char;
  Chars72 = Array[1..72] of Char;

  PFidoMsgHeader=^TFidoMsgHeader;
  TFidoMsgHeader = Record
                 FromName:   Chars36;
                 ToName:     Chars36;
                 Subj:       Chars72;
                 Date:       Chars20;
                 Times:      System.Word;
                 DestNode:   System.Integer;
                 OrigNode:   System.Integer;
                 Cost:       System.Integer;
                 OrigNet:    System.Integer;
                 DestNet:    System.Integer;
                 DestZone:   System.Integer;    { FTS0001-15 }
                 OrigZone:   System.Integer;
                 DestPoint:  System.Integer;
                 OrigPoint:  System.Integer;
                 Reply:      System.Word;
                 Attr:       System.Word;
                 Up:         System.Word;
               End;

  DomainStr = String[25];
  PFidoAddress=^TFidoAddress;
  TFidoAddress=Record
    Zone,
    Net,
    Node,
    Point: Word;
    Domain:DomainStr;
  End;

Type
  MsgStatus=(stOpened,stClosed,stBroken);
  OpenMode=(oReadOnly,oReadWrite,oCreate);
Type
   PFidoMessageBody=^TFidoMessageBody;
   TFidoMessageBody=Object(TStringCollectWoutSort)
     Constructor Init(ALimit,ADelta:Integer);
     Destructor Done;Virtual;
     Procedure Insert(Item: Pointer); virtual;
End;

Type
   PFidoMessage=^TFidoMessage;
   TFidoMessage=Object(TObject)
    THandle:File;
    MsgFileName:String;
    NetMailPath:PathStr;
    THeader:TFidoMsgHeader;
    PBody:PFidoMessageBody;
    TCurStr:Integer;
    TStatus:MsgStatus;
    MaxMsgSize,CurMsgSize:LongInt;
    MsgPartNum:Word;
    IsFlushed:Boolean;
    Constructor Init(MaxSize:LongInt);
    Procedure InitHeader(FromName,ToName:String;FromAddress,ToAddress:TFidoAddress;
                     Subject:String;Attrib:Word);
    Destructor Done;Virtual;
    Function OpenMessage(Path:String;ReadOnly:Boolean):Integer;
    Function CloseMessage:Integer;
    Function WriteEndBlock:Integer;
    Function CreateMessage(Path:String):Integer;
    Function WriteHeader(Header:TFidoMsgHeader):Integer;
    Function GetMsgFromFile(FName:String):Integer;
    Function WriteStrToMsg(S:String):Integer;
    Function WriteStrToFile(S:String):Integer;
    Function FlushToDisk:Integer;
    Procedure SetToAddress(Address:TFidoAddress);
    Procedure SetFromAddress(Address:TFidoAddress);
    Procedure SetToName(ToName:String);
    Procedure SetFromName(FromName:String);
    Procedure SetSubject(Subj:String);
    Procedure SetAttribute(Attrib:Word);
    Procedure UnSetAttribute(Attrib:Word);
    Procedure SetNetMailPath(Path:String);
    Function SetINTLkludge:Integer;
    Function SetTOPTkludge:Integer;
    Function SetFMPTkludge:Integer;
    Function SetMSGIDkludge:Integer;
    Private
    Function _OpenMessage(Path:String;Mode:OpenMode):Integer;
End;

Var
LastMsgIDSerial: longint;  { Used to prevent duplicate MSGID time stamps
                               when 2 messages created within one second }
IMPLEMENTATION

Type
  Str16 = string[16];
  Str20 = string[20];
  Str36 = string[36];
  Str72 = string[72];

Function IntToStr16(N: System.Integer): Str16;
Var
 S: Str16;
Begin
  Str(N,S);
  IntToStr16:=S;
End;

Procedure MakeAsciizString(S: String; Var Ps; N: Word);
  { Make Ascii String - with \0 at end }
Var
 I: Word;
Begin
  FillChar(Ps,N,0);
  I:=0;
  If S[0]>Chr(N-1) Then S[0]:=Chr(N-1);
  For I:=1 To Length(S) Do String(Ps)[Pred(I)]:=(S[I]);
End;

Function FillString(Num: Word; Len: Word; PadChar: Char): String;
  { Fill a string to "Len" with given character (used by date routines) }
Var
 S: String;
Begin
  If Len>255 Then
     Len:=255;
  S:='';
  Str(Num,S);
  While Length(S)<Len Do
        Insert(PadChar,S,1);
  FillString:=S;
End;

Function GetMsgNumber(S: PathStr): Integer;
Var I,R: Integer;
    D:   DirStr;
    N:   NameStr;
    E:   ExtStr;
Begin
  FSplit(S,D,N,E);
  Val(N,I,R);
  If R > 0 Then
     I := -1;
  GetMsgNumber := I;
End;

Function GetHighestMsgNum(Path: String): Integer;
  { Return the highest msg number used in a directory }
Var SRec: SearchRec;
    I,
    High: Integer;

Begin
  FindFirst(Path+'*.MSG',AnyFile,SRec);
  I:=DosError;
  If I = 3 Then
   Begin
     GetHighestMsgNum:=-1;
     Exit;
   End;
  High:=0;
  If I = 0 Then
  While DosError = 0 Do
   Begin
     I:=GetMsgNumber(SRec.Name);
     If I>High Then
        High:=i;
     FindNext(SRec);
   End;
   GetHighestMsgNum:=High;
End;

Function GetMSGTime: Str20;
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
  Str(Year,s);
  ds:=ds+' '+Copy(s,3,2);
  ts:=FillString(Hour,2,'0')+':'+FillString(Min,2,'0')+':'+FillString(Sec,2,'0');
  GetMsgTime:=Ds + '  '+TS;
End;

Function GetAddressStr(Zone,Net,Node,Point: integer;
                    Domain: DomainStr): String;
Var
 S: String;
Begin
  S:='';
  If Zone > 0 then            { leave zone off if its zero }
   Begin
     S := S + IntToStr16(Zone) + ':';
   End;
  S := S + IntToStr16(Net) + '/' + IntToStr16(Node);
  If (Point > 0) Or (Domain > '') Then
      S:=S+'.' + IntToStr16(Point);
  If Domain <> '' Then
      S := S +'@'+Domain;
  GetAddressStr:=S;
End;

Function GetUnixTime(Day,Month,Year,Hour,Min,Sec: System.Word): Longint;
  { Return unix time (secs since 1/1/1970). On UNIX system this would#
    always be GMT so here we try to get to GMT using a GMT env var. If
    that's not set then we are stuck with whatever the system clock says.

   *** In case of future concern note that this routine has been checked
       against Turbo C's TIME function and returns an exactly correct
       value for all tests (including in/after leap years).

       This routine is *CORRECT*
  }
Var Mf,l,r: Longint;
    DayOfWeek,Sec100: System.Word;

Begin
  If Day = 0 Then
   Begin
     GetDate(Year,Month,Day,DayOfWeek);
     GetTime(Hour,Min,Sec,Sec100);
   End;
  Mf:=0;
  If Month<3 Then
     Mf:=1;
  If (Year < 1900) Then
     If Year<70 Then
        Year:=Year+2000
     Else
        Year:=Year+1900;
  R:=Longint((36525*(Year-Mf)) Div 100) +
    Longint((3060*(Month+1+Mf*12)) Div 100)+Longint(Day)-Longint(719606);
  GetUnixTime := (r * 86400) + (Longint(Hour) * 3600) + (Min * 60) + Sec;
End;

Function GetMSGIDStr(Zone,Net,Node,Point: System.Integer;
                  Domain: DomainStr): String;
 { Return ^AMSGID: zone:net/node.point@domain<cr/lf> }

Var L: longint;
    S: string[60];
    S1: string[10];
    I: System.Integer;

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
  While l <= LastMsgIDSerial Do
     Inc(l);
  LastMsgIDSerial := L;
  s1 := HexL(l);
  {DownCaseStr(s1);}
   { Note (Rev 1.3) We add domain ourselves because we want to be able
     to add a zero point which addressstr leaves off
   }
  s := #1'MSGID: '+GetAddressStr(Zone,Net,Node,Point,Domain);

   { AddressStr leaves off point if zero and no domain }
  if (Point = 0) and (Domain = '') then s:=s+'.0';
  GetMSGIDStr := s+' '+s1;
end;


Constructor TFidoMessageBody.Init(ALimit,ADelta:Integer);
Begin
 Inherited Init(ALimit,ADelta);
End;

Destructor TFidoMessageBody.Done;
Begin
 Inherited Done;
End;
Procedure TFidoMessageBody.Insert(Item: Pointer);
Begin
 If PString(Item)^='' Then
    PString(Item)^:=#13;
 Inherited Insert(Item);
End;

Constructor TFidoMessage.Init(MaxSize:LongInt);
Begin
 Inherited Init;
{ PHeader:=New(PFidoMsgHeader);}
 FillChar(THeader,SizeOf(THeader),0);
 PBody:=New(PFidoMessageBody,Init(10,5));
 TCurStr:=0;
 TStatus:=stClosed;
 THeader.Attr:=0;
 CurMsgSize:=0;
 If MaxSize<=0 Then
    MaxMsgSize:=16000
   Else
    MaxMsgSize:=MaxSize;
 MsgPartNum:=1;
 IsFlushed:=False;
 MsgFileName:='';
 NetMailPath:='';
End;

Destructor TFidoMessage.Done;
Begin
 Dispose(PBody,Done);
{ Dispose(THeader);}
 If TStatus=stOpened Then
   CloseMessage;
 Inherited Done;
End;

Procedure TFidoMessage.InitHeader(FromName,ToName:String;FromAddress,ToAddress:TFidoAddress;
                     Subject:String;Attrib:Word);
Begin
 SetToName(ToName);
 SetFromName(FromName);
 SetToAddress(ToAddress);
 SetFromAddress(FromAddress);
 SetAttribute(Attrib);
End;

Function TFidoMessage.WriteHeader(Header:TFidoMsgHeader):Integer;
Var
 InOutResult:Integer;
 FPos:LongInt;
Begin
 WriteHeader:=0;
 {$I-}
 FPos:=FilePos(THandle);
 {$I+}
 {$I-}
 Seek(THandle,0);
 {$I+}
 InOutResult:=IOResult;
 If InOutResult<>0 Then
    Begin
     WriteHeader:=InOutResult;
     Exit;
    End;
 {$I-}
 BlockWrite(THandle,Header,SizeOf(Header));
 {$I+}
 InOutResult:=IOResult;
 If InOutResult<>0 Then
    Begin
     WriteHeader:=InOutResult;
     Exit;
    End;
 {$I-}
 Seek(THandle,FPos);
 {$I+}
 InOutResult:=IOResult;
 If InOutResult<>0 Then
    Begin
     WriteHeader:=InOutResult;
     Exit;
    End;
 THeader:=Header;
End;

Function TFidoMessage.FlushToDisk:Integer;
Var
InOutResult:Integer;
Counter:Integer;
Begin
 FlushToDisk:=0;
 {$I-}
 Seek(THandle,190);
 {$I+}
 InOutResult:=IOResult;
 If InOutResult<>0 Then
    Begin
     IsFlushed:=False;
     FlushToDisk:=InOutResult;
     Exit;
    End;
 For Counter:=0 To Pred(PBody^.Count) Do
     Begin
       InOutResult:=WriteStrToFile(PString(PBody^.At(Counter))^);
       If InOutResult<>0 Then
         Begin
          FlushToDisk:=InOutResult;
          Exit;
         End;
     End;
End;

Function TFidoMessage.WriteStrToFile(S:String):Integer;
Const
 NewLine:Char=#13;
Var
 InOutResult:Integer;
 Begin
 WriteStrToFile:=0;
 {$I-}
 BlockWrite(THandle,S[1],Length(S));
 If IOResult<>0 Then;
 BlockWrite(THandle,NewLine,SizeOf(NewLine));
 {$I+}
 WriteStrToFile:=IOResult;
End;

Function TFidoMessage.WriteStrToMsg(S:String):Integer;
Var
 InOutResult:Integer;
 OldHeader:TFidoMsgHeader;
 SubjStr:String;
Begin
 WriteStrToMsg:=0;
 If CurMsgSize+Length(S)>=MaxMsgSize Then
    Begin
     InOutResult:=FlushToDisk;
     If InOutResult<>0 Then
        Begin
         WriteStrToMsg:=InOutResult;
         Exit;
        End;
     OldHeader:=THeader;
     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
        MakeAsciizString(StrPas(@THeader.Subj)+' [Part '+IntToStr(MsgPartNum)+']',THeader,72)
       Else
        MakeAsciizString(StrPas(@THeader.Subj)+' [Часть '+IntToStr(MsgPartNum)+']',THeader,72);
      InOutResult:=WriteHeader(THeader);
      If InOutResult<>0 Then
         Begin
          WriteStrToMsg:=InOutResult;
          Exit;
         End;
      InOutResult:=WriteEndBlock;
      If InOutResult<>0 Then
         Begin
          WriteStrToMsg:=InOutResult;
          Exit;
         End;
      InOutResult:=CloseMessage;
      If InOutResult<>0 Then
         Begin
          WriteStrToMsg:=InOutResult;
          Exit;
         End;
      Inc(MsgPartNum);
      THeader:=OldHeader;
      CreateMessage(NetMailPath);
    End;
 PBody^.Insert(MCommon.NewStr(S));
 Inc(CurMsgSize,Length(S));
End;

Function TFidoMessage.CreateMessage(Path:String):Integer;
Var
 HighMsgNum:Integer;
 InOutResult:Integer;
Begin
 CreateMessage:=0;
 RemoveDupeSlash(Path);
 If Path[Length(Path)] <> '\' Then
    Path:=Path + '\';
 HighMsgNum:=GetHighestMsgNum(Path);
 If HighMsgNum<0 Then
    Begin
     CreateMessage:=3;
     Exit;
    End;
 Inc(HighMsgNum);
 MsgFileName:=IntToStr(HighMsgNum)+'.msg';
 SetNetMailPath(Path);
 InOutResult:=_OpenMessage(Path+MsgFileName,oCreate);
 If InOutResult<>0 Then
    Begin
     CreateMessage:=InOutResult;
     Exit;
    End;
 InOutResult:=WriteHeader(THeader);
 If InOutResult<>0 Then
    Begin
     CreateMessage:=InOutResult;
     Exit;
    End;
 CurMsgSize:=190;
 InOutResult:=SetINTLkludge;
 If InOutResult<>0 Then
    Begin
     CreateMessage:=InOutResult;
     Exit;
    End;
 InOutResult:=SetTOPTkludge;
 If InOutResult<>0 Then
    Begin
     CreateMessage:=InOutResult;
     Exit;
    End;
 InOutResult:=SetFMPTkludge;
 If InOutResult<>0 Then
    Begin
     CreateMessage:=InOutResult;
     Exit;
    End;
 InOutResult:=SetMSGIDkludge;
 If InOutResult<>0 Then
    Begin
     CreateMessage:=InOutResult;
     Exit;
    End;
End;

Function TFidoMessage.OpenMessage(Path:String;ReadOnly:Boolean):Integer;
Begin
 OpenMessage:=0;
 RemoveDupeSlash(Path);
 If Path[Length(Path)] <> '\' Then
    Path:=Path + '\';
 If ReadOnly Then
    OpenMessage:=_OpenMessage(Path,oReadOnly)
   Else
    OpenMessage:=_OpenMessage(Path,oReadWrite);
End;


Function TFidoMessage._OpenMessage(Path:String;Mode:OpenMode):Integer;
Var
 InOutResult:Byte;
Begin
 _OpenMessage:=0;
 If TStatus=stOpened Then
    Begin
     _OpenMessage:=-1;
     Exit;
    End;
 Assign(THandle,Path);
 If Mode=oReadOnly Then
    FileMode:=$40
   Else
    FileMode:=$42;
 {$I-}
 Reset(THandle,1);
 {$I+}
 InOutResult:=IOResult;
 FileMode:=$42;
 If InOutResult<>0 Then
   Begin
    If Mode=oCreate Then
       Begin
        {$I-}
        Rewrite(THandle,1);
        {$I+}
        InOutResult:=IOResult;
        If InOutResult<>0 Then
           Begin
            _OpenMessage:=InOutResult;
            TStatus:=stClosed;
            Exit;
           End;
       End
      Else
       Begin
        _OpenMessage:=InOutResult;
        TStatus:=stClosed;
        Exit;
       End;
   End;
 TStatus:=stOpened;
 MsgFileName:=Path;
End;

Function TFidoMessage.WriteEndBlock:Integer;
Var
 InOutResult:Integer;
Const
 EndBlock:Byte=0;
Begin
 WriteEndBlock:=0;
 {$I-}
 BlockWrite(THandle,EndBlock,SizeOf(EndBlock));
 {$I+}
 InOutResult:=IOResult;
 If InOutResult<>0 Then
    Begin
     WriteEndBlock:=InOutResult;
     Exit;
    End;
End;

Function TFidoMessage.CloseMessage:Integer;
Var
 InOutResult:Integer;
Begin
 CloseMessage:=0;
 If (Not IsFlushed) Then
    Begin
     InOutResult:=FlushToDisk;
     If InOutResult<>0 Then
        Begin
         CloseMessage:=InOutResult;
         Exit;
        End;
    End;
{$IFDEF VIRTUALPASCAL}
 {Reset(THandle,1);}
{$ENDIF}
 {$I-}
 Close(THandle);
 {$I+}
 If InOutResult<>0 Then
    Begin
     CloseMessage:=InOutResult;
     TStatus:=stClosed;
     Exit;
    End;
 TStatus:=stClosed;
End;

Function TFidoMessage.SetINTLkludge:Integer;
Begin
 SetINTLkludge:=0;
 With THeader Do
  Begin
   SetINTLkludge:=WriteStrToMsg(#1+_klgINTL+' '+
                                GetAddressStr(OrigZone,OrigNet,OrigNode,OrigPoint,''));

  End;
End;

Function TFidoMessage.SetTOPTkludge:Integer;
Begin
 SetTOPTkludge:=0;
 If THeader.DestPoint<>0 Then
    SetTOPTkludge:=WriteStrToMsg(#1+_klgTOPT+' '+IntToStr(THeader.DestPoint));
End;

Function TFidoMessage.SetFMPTkludge:Integer;
Begin
 SetFMPTkludge:=0;
 If THeader.OrigPoint<>0 Then
    SetFMPTkludge:=WriteStrToMsg(#1+_klgFMPT+' '+IntToStr(THeader.OrigPoint));
End;

Function TFidoMessage.SetMSGIDkludge:Integer;
Begin
 SetMSGIDkludge:=0;
 With THeader Do
   SetMSGIDkludge:=WriteStrToMsg(GetMSGIDstr(OrigZone,OrigNet,OrigNode,OrigPoint,''));
End;


Procedure TFidoMessage.SetNetMailPath(Path:String);
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
Begin
 FSplit(Path,D,N,E);
 netMailPath:=D;
End;
Procedure TFidoMessage.SetToAddress(Address:TFidoAddress);
Begin
 With THeader Do
  Begin
   DestZone:=Address.Zone;
   DestNet:=Address.Net;
   DestNode:=Address.Node;
   DestPoint:=Address.Point;
  End;
End;
Procedure TFidoMessage.SetFromAddress(Address:TFidoAddress);
Begin
 With THeader Do
  Begin
   OrigZone:=Address.Zone;
   OrigNet:=Address.Net;
   OrigNode:=Address.Node;
   OrigPoint:=Address.Point;
  End;
End;

Procedure TFidoMessage.SetToName(ToName:String);
Begin
 MakeAsciizString(ToName,THeader.ToName,36);
End;
Procedure TFidoMessage.SetFromName(FromName:String);
Begin
 MakeAsciizString(FromName,THeader.FromName,36);
End;

Procedure TFidoMessage.SetSubject(Subj:String);
Begin
 MakeAsciizString(Subj,THeader.Subj,72);
End;

Procedure TFidoMessage.SetAttribute(Attrib:Word);
Begin
  THeader.Attr:=THeader.Attr or Attrib;
End;

Procedure TFidoMessage.UnSetAttribute(Attrib:Word);
Begin
  THeader.Attr:=THeader.Attr and not Attrib;
End;

Function TFidoMessage.GetMsgFromFile(FName:String):Integer;
Var
 Result:Byte;
 Ch:Char;
Begin
 Assign(THandle,FName);
 FileMode:=0;
 {$I-}
 Reset(THandle,1);
 {$I+}
 Result:=IOResult;
 FileMode:=2;
 If Result<>0 Then
   Begin
    GetMsgFromFile:=Result;
    TStatus:=stClosed;
    Exit;
   End;
 TStatus:=stOpened;
 {$I-}
 BlockRead(THandle,THeader,SizeOf(TFidoMsgHeader));
 {$I+}
 Result:=IOResult;
 If Result<>0 Then
   Begin
    TStatus:=stBroken;
    GetMsgFromFile:=Result;
    {$I-}
    Close(THandle);
    {$I+}
    Exit;
   End;
 While Not Eof(THandle) Do
   Begin
    {$I-}
    BlockRead(THandle,Ch,SizeOf(Ch));
    {$I+}
   End;
 {$I-}
 Close(THandle);
 {$I+}
 GetMsgFromFile:=0;
End;

Begin
  LastMsgIDSerial := 0;
End.
