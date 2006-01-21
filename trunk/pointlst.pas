UNIT PointLst;

INTERFACE
{$I VERSION.INC}
Uses
Use32,
Objects,StrUnit,Dos,Incl,Address,Logger,Parser,Memory,{TpDos,}Validate,MCommon,
     Crc_32,Face,Os_Type,FileIO,PntL_Obj
     {$IFDEF SPLE}
     ,Ple_Incl,
      PBar,
      MsgBoxA
     {$ELSE}
     ,Script
     {$ENDIF}
     ;


Const
EBossTag='BOSS,';
EPointTag='POINT,';
ZoneTag='ZONE';
RegionTag='REGION';
HostTag='HOST';
DownTag='DOWN';
HoldTag='HOLD';
PvtTag='PVT';
POS_COMMENT=1;
POS_BOSS=2;
POS_POINT=4;
POS_SKIP=8;
POS_ERROR=16;

Var
CurrentPoints:PPointsCollection;
CurrentComments:PCommentsCollection;
{$IFNDEF SPLE}
BossRecArray:PBossRecSortedCollection;
{$ENDIF}
IsBossFoundInSegment:Boolean;
SegmentBossString:String;
MessageBody:PMessageBody;
PSegmentErrorsMap:PMessageBody;
PMessageErrorsMap:PMessageBody;
_flgPointListOpened:Boolean;
{PntListName:String;}
Validat:PPXPictureValidator;

Validator:PPXPictureValidator;


{Const
 _fattrNull=0;
 _fattrSystem=1;
 _fattrModem=2;
 _fattrCompress=4;
 _fattrMailer=8;
 _fattrUser=16;}

Type
 PFlagRecord=^TFlagRecord;
 TFlagRecord=Object(TObject)
   PFlag:PString;
   TStringOffset:Word; {reserved}
{   TAttrib:Word;}
   Constructor Init(AString:String;AOffset:Word);
   Destructor Done;Virtual;
End;

Type
 PPointStringFlags=^TPointStringFlags;
 TPointStringFlags=Object(TCollection)
{  Destructor Done;Virtual;}
End;



Type
 PPointStringRecord=^TPointStringRecord;
 TPointStringRecord=Object(TObject)
   PSignature,
   PNumber,
   PStationName,
   PLocation,
   PSysOpName,
   PPhone,
   PSpeed:PString;
   PFlags:PPointStringFlags;
{   PErrorsMap:PMessageBody;}
{   Function GetStringField(Var AString:String;Var BeginPos:Word):String;}
   Function NewField(S:String):PString;
   Procedure DisposeField(P:PString);
   Constructor Init(AString:String);
   Destructor Done;Virtual;
End;



Function  InitPointList(PointListName:String):Boolean;
Procedure ReadPointListToMemory(Var PointList:Text);
Procedure WritePointListToDisk;
Function  SearchForBoss(BossAddr:TAddress):Integer;
Function  DeleteBossByIndex(Index:Integer):Boolean;
Function  DeleteBossByAddress(Addr:TAddress):Boolean;
Function  GetStringField(Var AString:String;Var BeginPos:Word;Var StringPos:Word):String;
{Function  IsPointStringValid(Var S:String):Boolean;}
Function  IsValidPointString(BossStr:String;S:String;Var PErrorsMap:PMessageBody):Boolean;
{Procedure CollectErrorsInMessage(WrongString:String;Flag:Word);}
{Procedure LogErrorsMap(PErrorsMap:PMessageBody);}
{Procedure CollectErrorsInPointList_(ListName:String;WrongString:String;Flag:Word);}
Function  ProcessPoint(BossIndex:Integer;Point:String;Flag:Integer):Integer;
Function  ReplaceBossComments(BossIndex:Integer;NewComments:PCommentsCollection):Boolean;
Function  GetBossAddressByIndex(Index:Integer):String;
Procedure LoadExcludeList;
Function IsInExcludeList(BossStr:String):Boolean;
Procedure GetLoHiChars(Var LoChar,HiChar:Char);

IMPLEMENTATION

Procedure GetLoHiChars(Var LoChar,HiChar:Char);
Var
Posit:Byte;
_LoChar,_HiChar:String;
Tmp:String;
Begin
Tmp:=GetVar(AllowedCharsTag.Tag,_varNONE);
Tmp:=StrUp(StrTrim(Tmp));
Posit:=Pos('..',Tmp);
LoChar:=#33;
HiChar:=#126;
If Posit=0 Then
   Begin
    Exit;
   End
 Else
   Begin
    _LoChar:=StrTrim(Copy(Tmp,1,Posit-1));
    _HiChar:=StrTrim(Copy(Tmp,Posit+2,Length(Tmp)));
    If _LoChar<>'' Then
{       LoChar:=Char(Byte(StrToInt(_LoChar)));}
       LoChar:=Char(Byte(StrToInt(_LoChar)));
    If _HiChar<>'' Then
{       HiChar:=ByteToChar(Byte(StrToInt(_HiChar)));}
       HiChar:=Chr(Byte(StrToInt(_HiChar)));
   End;
End;

Function IsItTXXFlag(S:String):Boolean;
Begin
IsItTXXFlag:=False;
If (S[1]='U') And (S[2]='T') And ((S[3] in ['a'..'z']) or (S[3] in ['A'..'Z'])) And
   ((S[4] in ['a'..'z']) or (S[4] in ['A'..'Z'])) Then
   IsItTXXFlag:=True;
End;

Procedure UpCaseFlags(Var PFlags:PPointStringFlags;ExcludeTXXFlag:Boolean);
Var
PFlag:PFlagRecord;
Counter:Integer;
Begin
If PFlags<>Nil Then
 Begin
   For Counter:=0 To Pred(PFlags^.Count) Do
     Begin
      PFlag:=PFlags^.At(Counter);
      If ExcludeTXXFlag Then
        Begin
         If Not IsItTXXFlag(PFlag^.PFlag^) Then
            PFlag^.PFlag^:=StrUp(PFlag^.PFlag^);
        End
      Else
         PFlag^.PFlag^:=StrUp(PFlag^.PFlag^);
     End;
 End;
End;

Constructor TFlagRecord.Init(AString:String;AOffset:Word);
Begin
  Inherited Init;
  If StrTrim(AString)<>'' Then
    Begin
     PFlag:=MCommon.NewStr(AString);
     TStringOffset:=AOffset;
{     TAttrib:=_fattrNull;}
{     System.Delete(AString,1,EndPos);}
    End
   Else
    Begin
     PFlag:=Nil;
     TStringOffset:=0;
{     TAttrib:=_fattrNull;}
{     AString:='';}
    End
End;


Destructor TFlagRecord.Done;
Begin
 If PFlag<>Nil Then
   Begin
    DisposeStr(PFlag);
    PFlag:=Nil;
   End;
 Inherited Done;
End;

Function GetStringField(Var AString:String;Var BeginPos:Word;Var StringPos:Word):String;
Var
EndPos:Word;
Begin
 If BeginPos=0 Then
    Begin
     GetStringField:='';
     Exit;
    End;
 EndPos:=Pos(',',Copy(AString,BeginPos,Length(AString)))+BeginPos;
 If (EndPos<>0) And (EndPos<>BeginPos) Then
    Begin
     GetStringField:=Copy(AString,BeginPos,EndPos-BeginPos-1);
     StringPos:=BeginPos;
     BeginPos:=EndPos;
    End
   Else
    Begin
     GetStringField:=Copy(AString,BeginPos,Length(AString));
     StringPos:=StringPos+(EndPos-StringPos);
     BeginPos:=0;
    End;
End;

Function TPointStringRecord.NewField(S:String):PString;
Begin
 If StrTrim(S)<>'' Then
    NewField:=MCommon.NewStr(S)
  Else
    NewField:=Nil;
End;

Procedure TPointStringRecord.DisposeField(P:PString);
Begin
 If P<>Nil Then
   Begin
    DisposeStr(P);
    P:=Nil;
   End;
End;

Constructor TPointStringRecord.Init(AString:String);
Var
BeginPos,EndPos,StringPos:Word;
Begin
  Inherited Init;
  PSignature:=Nil;
  PNumber:=Nil;
  PStationName:=Nil;
  PLocation:=Nil;
  PSysOpName:=Nil;
  PPhone:=Nil;
  PSpeed:=Nil;
  PFlags:=Nil;
{  PErrorsMap:=Nil;}
  If StrTrim(AString)='' Then
     Exit;
  BeginPos:=1;
  StringPos:=1;
  PSignature:=NewField(GetStringField(AString,BeginPos,StringPos));
   If PSignature<>Nil Then
      Begin
       PSignature^:=StrDown(PSignature^);
       PSignature^[1]:=UpCase(PSignature^[1]);
      End;
  PNumber:=NewField(GetStringField(AString,BeginPos,StringPos));
  PStationName:=NewField(GetStringField(AString,BeginPos,StringPos));
  PLocation:=NewField(GetStringField(AString,BeginPos,StringPos));
  PSysOpName:=NewField(GetStringField(AString,BeginPos,StringPos));
  PPhone:=NewField(GetStringField(AString,BeginPos,StringPos));
  PSpeed:=NewField(GetStringField(AString,BeginPos,StringPos));
  If BeginPos<>0 Then
     Begin
      PFlags:=New(PPointStringFlags,Init(5,5));
      While BeginPos>0 Do
        Begin
         PFlags^.Insert(
                  New(PFlagRecord,Init(GetStringField(AString,BeginPos,StringPos),StringPos)));
        End;
     End;
End;

Destructor TPointStringRecord.Done;
Begin
  DisposeField(PSignature);
  DisposeField(PNumber);
  DisposeField(PStationName);
  DisposeField(PLocation);
  DisposeField(PSysOpName);
  DisposeField(PPhone);
  DisposeField(PSpeed);
  If PFlags<>Nil Then
     PFlags^.Done;
  Inherited Done;
{  If PErrorsMap<>Nil Then
     PErrorsMap^.Done;}
End;

Var
IsEventFound:Boolean;
WhatDoOnEvent:Byte;
OnWhatString:String;

Procedure ForEachEvent(Pnt:Pointer);
Var
Event,WhatDo:String;
Begin
 If IsEventFound Then
    Exit;
 If Pnt=Nil Then
    Exit;
 GetTwoTrimmedParamsFromString(PString(Pnt)^,Event,WhatDo);
 Event:=StrUp(StrTrim(Event));
 WhatDo:=StrUp(StrTrim(WhatDo));
 If (Event='') Or (WhatDo='') Then
    Exit;
 If OnWhatString=Event Then
    Begin
     IsEventFound:=True;
     If WhatDo=ErrorTag Then
        WhatDoOnEvent:=_evtError
     Else
     If WhatDo=WarningTag Then
        WhatDoOnEvent:=_evtWarning
     Else
     If WhatDo=IgnoreTag Then
        WhatDoOnEvent:=_evtIgnore;
    End;
End;

Function GetWhatDoOnEvent(OnWhat:String):Byte;
Begin
 IsEventFound:=False;
 GetWhatDoOnEvent:=_evtError;
 WhatDoOnEvent:=_evtError;
 OnWhatString:=OnWhat;
 ForEachVar(EventTag.Tag,ForEachEvent);
 GetWhatDoOnEvent:=WhatDoOnEvent;
End;


Var
IsValidPhone,
IsValidSpeed:Boolean;

Procedure ForEachPhoneMask(Pnt:Pointer;Data:Pointer);Far;
Var
Pict,Phone:String;
Begin
 If IsValidPhone Then
    Exit;
 Pict:=PString(Pnt)^;
 Phone:=PString(Data)^;
 If StrTrim(Pict)='' Then
    Exit;
{ If Validator= Nil Then
    Validator:=New(PPxPictureValidator,Init(' ',False));
 Validator^.Pic:=PString(Pnt);}
 If Validator= Nil Then
    Validator:=New(PPxPictureValidator,Init(Pict,False))
 Else
   Begin
    If Validator^.Pic<>Nil Then
       DisposeStr(Validator^.Pic);
    Validator^.Pic:=MCommon.NewStr(Pict);
   End;
 DoUpCase:=False;
 IsValidPhone:=Validator^.IsValid(Phone)=True;
End;

Procedure ForEachSpeed(Pnt:Pointer;Data:Pointer);Far;
Var
Pict,Speed:String;
Begin
 If IsValidSpeed Then
    Exit;
 Pict:=PString(Pnt)^;
 Speed:=PString(Data)^;
 If StrTrim(Pict)='' Then
    Exit;
{ If Validator= Nil Then
    Validator:=New(PPxPictureValidator,Init(' ',False));
 Validator^.Pic:=PString(Pnt);}
 If Validator= Nil Then
    Validator:=New(PPxPictureValidator,Init(Pict,False))
 Else
   Begin
    If Validator^.Pic<>Nil Then
       DisposeStr(Validator^.Pic);
    Validator^.Pic:=MCommon.NewStr(Pict);
   End;
 DoUpCase:=False;
 IsValidSpeed:=Validator^.IsValid(Speed)=True;
End;

Function GetSystemFlags(AllFlags:PPointStringFlags):PPointStringFlags;
Var
Counter:Integer;
Result_:PPointStringFlags;
PTempFlag:PFlagRecord;
Begin
GetSystemFlags:=Nil;
Result_:=Nil;
If AllFlags<>Nil Then
   Begin
    For Counter:=0 To Pred(AllFlags^.Count) Do
      Begin
       PTempFlag:=AllFlags^.At(Counter);
       If PTempFlag^.PFlag<>Nil Then
        Begin
         If PTempFlag^.PFlag^='U' Then
            Break;
         If Result_=Nil Then
            Result_:=New(PPointStringFlags,Init(3,3));
         Result_^.Insert(New(PFlagRecord,Init(PTempFlag^.PFlag^,PTempFlag^.TStringOffset)));
        End;
      End;
   End;
GetSystemFlags:=Result_;
End;

Function GetUserFlags(AllFlags:PPointStringFlags):PPointStringFlags;
Var
Counter:Integer;
Result_:PPointStringFlags;
PTempFlag:PFlagRecord;
IsUserFlagsPresent:Boolean;
Begin
GetUserFlags:=Nil;
Result_:=Nil;
IsUserFlagsPresent:=False;
If AllFlags<>Nil Then
   Begin
    For Counter:=0 To Pred(AllFlags^.Count) Do
      Begin
       PTempFlag:=AllFlags^.At(Counter);
       If PTempFlag^.PFlag<>Nil Then
        Begin
         If IsUserFlagsPresent Then
           Begin
            If Result_=Nil Then
               Result_:=New(PPointStringFlags,Init(3,3));
            Result_^.Insert(New(PFlagRecord,Init('U'+PTempFlag^.PFlag^,PTempFlag^.TStringOffset)));
           End;
         If PTempFlag^.PFlag^='U' Then
            IsUserFlagsPresent:=True;
        End;
      End;
   End;
GetUserFlags:=Result_;
End;

Function CheckForDupeFlags(SystemFlags,UserFlags:PPointStringFlags):PPointStringFlags;
Var
Result_:PPointStringFlags;
Counter,Counter1:Integer;
PTempFlag:PFlagRecord;
Begin
 CheckForDupeFlags:=Nil;
 Result_:=Nil;
 If SystemFlags<>Nil Then
    Begin
     For Counter:=0 To Pred(SystemFlags^.Count) Do
        Begin
         PTempFlag:=SystemFlags^.At(Counter);
         If PTempFlag^.PFlag<>Nil Then
          Begin
           For Counter1:=0 To Pred(SystemFlags^.Count) Do
             Begin
              If (Counter<>Counter1) And (PFlagRecord(SystemFlags^.At(Counter1))^.PFlag<>Nil) Then
                 Begin
                  If PTempFlag^.PFlag^=PFlagRecord(SystemFlags^.At(Counter1))^.PFlag^ Then
                     Begin
                      If Result_=Nil Then
                         Result_:=New(PPointStringFlags,Init(1,1));
                      Result_^.Insert(New(PFlagRecord,Init(PFlagRecord(SystemFlags^.At(Counter1))^.PFlag^,
                                     PFlagRecord(SystemFlags^.At(Counter1))^.TStringOffset)));
                     End;
                 End;
             End;
         End;
        End;
    End;
 If UserFlags<>Nil Then
    Begin
     For Counter:=0 To Pred(UserFlags^.Count) Do
        Begin
         PTempFlag:=UserFlags^.At(Counter);
         If PTempFlag^.PFlag<>Nil Then
          Begin
           For Counter1:=0 To Pred(UserFlags^.Count) Do
             Begin
              If (Counter<>Counter1) And (PFlagRecord(UserFlags^.At(Counter1))^.PFlag<>Nil) Then
                 Begin
                  If PTempFlag^.PFlag^=PFlagRecord(UserFlags^.At(Counter1))^.PFlag^ Then
                     Begin
                      If Result_=Nil Then
                         Result_:=New(PPointStringFlags,Init(1,1));
                      Result_^.Insert(New(PFlagRecord,Init(PFlagRecord(UserFlags^.At(Counter1))^.PFlag^,
                                     PFlagRecord(UserFlags^.At(Counter1))^.TStringOffset)));
                     End;
                 End;
             End;
          End;
        End;
    End;
CheckForDupeFlags:=Result_;
End;

Var
_IsValidSystemFlag,
_IsValidUserFlag:Boolean;

Procedure ForEachSystemFlags(Point:Pointer;Data:Pointer);Far;
Var
Pict,Flag:String;
Begin
 If _IsValidSystemFlag Then
    Exit;
 If Data=Nil Then
    Exit;
 Pict:=PString(Point)^;
 Flag:=PString(Data)^;
 If StrTrim(Pict)='' Then
    Exit;
 If Validator= Nil Then
    Validator:=New(PPxPictureValidator,Init(Pict,False))
 Else
   Begin
    If Validator^.Pic<>Nil Then
       DisposeStr(Validator^.Pic);
    Validator^.Pic:=MCommon.NewStr(Pict);
   End;
 DoUpCase:=False;
 _IsValidSystemFlag:=Validator^.IsValid(Flag)=True;
End;

Procedure ForEachUserFlags(Point:Pointer;Data:Pointer);Far;
Var
Pict,Flag:String;
Begin
 If _IsValidUserFlag Then
    Exit;
 If Data=Nil Then
    Exit;
 Pict:=PString(Point)^;
 Flag:=PString(Data)^;
 If StrTrim(Pict)='' Then
    Exit;
 If Validator= Nil Then
    Validator:=New(PPxPictureValidator,Init(Pict,False))
 Else
   Begin
    If Validator^.Pic<>Nil Then
       DisposeStr(Validator^.Pic);
    Validator^.Pic:=MCommon.NewStr(Pict);
   End;
 DoUpCase:=False;
 _IsValidUserFlag:=Validator^.IsValid(Flag)=True;
End;


Function CheckSystemFlags(SystemFlags:PPointStringFlags):PPointStringFlags;
Var
Counter:Integer;
Result_:PPointStringFlags;
Begin
 _IsValidSystemFlag:=False;
 Result_:=Nil;
 If SystemFlags<>Nil Then
   Begin
    For Counter:=0 To Pred(SystemFlags^.Count) Do
      Begin
        ForEachVarWithData(SystemFlagsTag.Tag,PFlagRecord(SystemFlags^.At(Counter))^.PFlag,ForEachSystemFlags);
        If Not _IsValidSystemFlag Then
           Begin
            If Result_=Nil Then
               Result_:=New(PPointStringFlags,Init(1,1));
            Result_^.Insert(New(PFlagRecord,Init(
                          PFlagRecord(SystemFlags^.At(Counter))^.PFlag^,
                          PFlagRecord(SystemFlags^.At(Counter))^.TStringOffset
                          )));
            _IsValidSystemFlag:=False;
           End
         Else
           Begin
            _IsValidSystemFlag:=False;
           End;
      End;
   End;
CheckSystemFlags:=Result_;
End;

Function CheckUserFlags(UserFlags:PPointStringFlags):PPointStringFlags;
Var
Counter:Integer;
Result_:PPointStringFlags;
Begin
 _IsValidUserFlag:=False;
 Result_:=Nil;
 If UserFlags<>Nil Then
   Begin
    For Counter:=0 To Pred(UserFlags^.Count) Do
      Begin
        ForEachVarWithData(UserFlagsTag.Tag,PFlagRecord(UserFlags^.At(Counter))^.PFlag,ForEachUserFlags);
        If Not _IsValidUserFlag Then
           Begin
            If Result_=Nil Then
               Result_:=New(PPointStringFlags,Init(1,1));
            Result_^.Insert(New(PFlagRecord,Init(
                          PFlagRecord(UserFlags^.At(Counter))^.PFlag^,
                          PFlagRecord(UserFlags^.At(Counter))^.TStringOffset
                          )));
            _IsValidUserFlag:=False;
           End
         Else
           Begin
            _IsValidUserFlag:=False;
           End;
      End;
   End;
CheckUserFlags:=Result_;
End;

Function IsTXXFlagPresent(Flags:PPointStringFlags;Var FlagPos:Byte;Var Flag:String):Boolean;
Var
Counter:Integer;
Begin
IsTXXFlagPresent:=False;
FlagPos:=0;
Flag:='';
If (Flags=Nil) Then
   Exit;
For Counter:=0 To Pred(Flags^.Count) Do
   Begin
    If (PFlagRecord(Flags^.At(Counter))^.PFlag<>Nil) And
       (Copy(PFlagRecord(Flags^.At(Counter))^.PFlag^,1,2)='UT') And
       (Length(PFlagRecord(Flags^.At(Counter))^.PFlag^)=4) And
       ((PFlagRecord(Flags^.At(Counter))^.PFlag^[3] In ['a'..'z']) Or
        (PFlagRecord(Flags^.At(Counter))^.PFlag^[3] In ['A'..'Z'])) And
       ((PFlagRecord(Flags^.At(Counter))^.PFlag^[4] In ['a'..'z']) Or
        (PFlagRecord(Flags^.At(Counter))^.PFlag^[4] In ['A'..'Z'])) Then
       Begin
        FlagPos:=PFlagRecord(Flags^.At(Counter))^.TStringOffset;
        Flag:=PFlagRecord(Flags^.At(Counter))^.PFlag^;
        IsTXXFlagPresent:=True;
        Break;
       End;
   End;
End;


Function IsFlagsContainsFlag(Flags:PPointStringFlags;Flag:String;Var FlagPos:Byte):Boolean;
Var
Counter:Integer;
Begin
IsFlagsContainsFlag:=False;
FlagPos:=0;
If (Flags=Nil) Or (StrTrim(Flag)='') Then
   Exit;
For Counter:=0 To Pred(Flags^.Count) Do
   Begin
    If (PFlagRecord(Flags^.At(Counter))^.PFlag<>Nil) And
       (PFlagRecord(Flags^.At(Counter))^.PFlag^=Flag) Then
       Begin
        FlagPos:=PFlagRecord(Flags^.At(Counter))^.TStringOffset;
        IsFlagsContainsFlag:=True;
        Break;
       End;
   End;
End;

Function CheckRedundantFlags(SystemFlags,UserFlags:PPointStringFlags):PMessageBody;
Var
Result_:PMessageBody;
ImpliesCollection:PValueCollection;
Counter,Counter1:Integer;
OneFlag,RedundantFlags,OneOfRedundant:String;
BeginPos,StringPos:Word;
FlagPos:Byte;
Begin
 Result_:=Nil;
 ImpliesCollection:=Nil;
 BeginPos:=1;
 ImpliesCollection:=GetValueCollectionPointer(ImpliesFlagsTag);
 If ImpliesCollection<>Nil Then
    Begin
     For Counter:=0 To Pred(ImpliesCollection^.Count) Do
        Begin
         GetTwoTrimmedParamsFromString(PString(ImpliesCollection^.At(Counter))^,OneFlag,RedundantFlags);
         If IsFlagsContainsFlag(SystemFlags,OneFlag,FlagPos) Then
            Begin
             While BeginPos>0 Do
               Begin
                OneOfRedundant:=GetStringField(RedundantFlags,BeginPos,StringPos);
                If (IsFlagsContainsFlag(SystemFlags,OneOfRedundant,FlagPos) or
                   IsFlagsContainsFlag(UserFlags,OneOfRedundant,FlagPos)) Then
                   Begin
                     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                        Begin
                         If Result_=Nil Then
                            Result_:=New(PMessageBody,Init(2,2));
                         Result_^.Insert(NewStr('  · Redundant flag ['+OneOfRedundant+'] at position ['+IntToStr(FlagPos)+
                                               '] implies into flag ['+OneFlag+']'));
                        End
                     Else
                        Begin
                         If Result_=Nil Then
                            Result_:=New(PMessageBody,Init(2,2));
                         Result_^.Insert(NewStr('  · Излишний флаг ['+OneOfRedundant+'] по смещению ['+IntToStr(FlagPos)+
                                               '] уже подразумевается флагом ['+OneFlag+']'));
                        End;
                   End
                  Else
                   Begin
                    If (Copy(OneOfRedundant,1,2)='UT') And
                       (Length(OneOfRedundant)=4) Then
                       Begin
                        If IsTXXFlagPresent(UserFlags,FlagPos,OneOfRedundant) Then
                           Begin
                             If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                               Begin
                                If Result_=Nil Then
                                   Result_:=New(PMessageBody,Init(2,2));
                              Result_^.Insert(NewStr('  · Redundant flag ['+OneOfRedundant+'] at position ['+IntToStr(FlagPos)+
                                                      '] implies into flag ['+OneFlag+']'));
                               End
                             Else
                               Begin
                                If Result_=Nil Then
                                   Result_:=New(PMessageBody,Init(2,2));
                               Result_^.Insert(NewStr('  · Излишний флаг ['+OneOfRedundant+'] по смещению ['+IntToStr(FlagPos)+
                                                      '] уже подразумевается флагом ['+OneFlag+']'));
                               End;
                           End;
                       End;
                   End;

               End;
              BeginPos:=1;
            End
         Else
         If IsFlagsContainsFlag(UserFlags,OneFlag,FlagPos) Then
            Begin
             BeginPos:=1;
             While BeginPos>0 Do
               Begin
                OneOfRedundant:=GetStringField(RedundantFlags,BeginPos,StringPos);
                If (IsFlagsContainsFlag(UserFlags,OneOfRedundant,FlagPos) or
                   IsFlagsContainsFlag(SystemFlags,OneOfRedundant,FlagPos)) Then
                   Begin
                     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                        Begin
                         If Result_=Nil Then
                            Result_:=New(PMessageBody,Init(2,2));
                         Result_^.Insert(NewStr('  · Redundant flag ['+OneOfRedundant+'] at position ['+IntToStr(FlagPos)+
                                               '] implies into flag ['+OneFlag+']'));
                        End
                     Else
                        Begin
                         If Result_=Nil Then
                            Result_:=New(PMessageBody,Init(2,2));
                         Result_^.Insert(NewStr('  · Излишний флаг ['+OneOfRedundant+'] по смещению ['+IntToStr(FlagPos)+
                                               '] уже подразумевается флагом ['+OneFlag+']'));
                        End;
                   End
                 Else
                   Begin
                    If (Copy(OneOfRedundant,1,2)='UT') And
                       (Length(OneOfRedundant)=4) Then
                       Begin
                        If IsTXXFlagPresent(UserFlags,FlagPos,OneOfRedundant) Then
                           Begin
                             If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                               Begin
                                If Result_=Nil Then
                                   Result_:=New(PMessageBody,Init(2,2));
                              Result_^.Insert(NewStr('  · Redundant flag ['+OneOfRedundant+'] at position ['+IntToStr(FlagPos)+
                                                      '] implies into flag ['+OneFlag+']'));
                               End
                             Else
                               Begin
                                If Result_=Nil Then
                                   Result_:=New(PMessageBody,Init(2,2));
                               Result_^.Insert(NewStr('  · Излишний флаг ['+OneOfRedundant+'] по смещению ['+IntToStr(FlagPos)+
                                                      '] уже подразумевается флагом ['+OneFlag+']'));
                               End;
                           End;
                       End;
                   End;
               End;
            End;


        End;
    End;
 CheckRedundantFlags:=Result_;
End;

Function IsValidPointString(BossStr:String;S:String;Var PErrorsMap:PMessageBody):Boolean;
Var
PPointString:PPointStringRecord;
LoChar,HiChar:Char;

PntStringInMap:Boolean;
BeginPos,EndPos:Word;
Counter:Word;
{ErrorsCounter:Word;}
SystemFlags,
UserFlags,DupeFlags,
NotValidSystemFlags,
NotValidUserFlags:PPointStringFlags;
RedundantFlags:PMessageBody;
GarbagePos,LastGarbagePos:Byte;
WhatDoOnError:Byte;
     Procedure PutPntStringAtMap;
       Begin
        {$IFNDEF SPLE}
            If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
               PErrorsMap^.Insert(NewStr('File: '+GetFNameAndExt(PntListName)))
            Else
               PErrorsMap^.Insert(NewStr('Файл: '+GetFNameAndExt(PntListName)));
            If (PPointString<>Nil) And (PPointString^.PNumber<>Nil) Then
             Begin
              If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                 PErrorsMap^.Insert(NewStr('Pointstring ('+
                          GetStringAddressFromString(BossStr)+'.'+PPointString^.PNumber^+') contains errors: '))
              Else
                 PErrorsMap^.Insert(NewStr('Поинтстрока ('+
                          GetStringAddressFromString(BossStr)+'.'+PPointString^.PNumber^+') содержит ошибки: '))
             End
            Else
             Begin
              If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                 PErrorsMap^.Insert(NewStr('Pointstring ('+GetStringAddressFromString(BossStr)+'.?) contains errors: '))
              Else
                 PErrorsMap^.Insert(NewStr('Поинтстрока ('+GetStringAddressFromString(BossStr)+'.?) содержит ошибки: '));
             End;
            PErrorsMap^.Insert(NewStr(RArrow+S));
            If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
               PErrorsMap^.Insert(NewStr('Errors:'))
            Else
               PErrorsMap^.Insert(NewStr('Ошибки:'));
            If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
              Begin
               If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                  LogWriteLn('!File: '++GetFNameAndExt(PntListName))
               Else
                  LogWriteLn('!Файл: '++GetFNameAndExt(PntListName));
               If (PPointString<>Nil) And (PPointString^.PNumber<>Nil) Then
                 Begin
                  If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                     LogWriteLn('!Pointstring ('+
                             GetStringAddressFromString(BossStr)+'.'+PPointString^.PNumber^+') contains errors: ')
                  Else
                     LogWriteLn('!Поинтстрока ('+
                             GetStringAddressFromString(BossStr)+'.'+PPointString^.PNumber^+') содержит ошибки: ')
                 End
               Else
                 Begin
                  If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                     LogWriteLn('!Pointstring ('+GetStringAddressFromString(BossStr)+'.?) contains errors: ')
                  Else
                     LogWriteLn('!Поинтстрока ('+GetStringAddressFromString(BossStr)+'.?) содержит ошибки: ')
                 End;
               LogWriteLn('!'+RArrow+S);
               If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                  LogWriteLn('!Errors:')
               Else
                  LogWriteLn('!Ошибки:')
              End;
         PntStringInMap:=True;
         {$ENDIF}
       End;
Begin
 IsValidPointString:=True;
 {ErrorsCounter:=0;}
 GarbagePos:=0;
 LastGarbagePos:=0;
 IsValidPhone:=False;
 IsValidSpeed:=False;
 PntStringInMap:=False;
 WhatDoOnError:=_evtError;
 PPointString:=Nil;
 UserFlags:=Nil;
 SystemFlags:=Nil;
 DupeFlags:=Nil;
 NotValidSystemFlags:=Nil;
 NotValidUserFlags:=Nil;
 RedundantFlags:=Nil;
 If StrTrim(S)='' Then
    Begin
     IsValidPointString:=False;
     Exit;
    End;
 If PErrorsMap=Nil Then
    PErrorsMap:=New(PMessageBody,Init(5,5));
 {************ Поиск пpобелов и недопyстимых символов***********}
 If StrTrim(PntListName)='' Then
    PntListName:='MESSAGE';
 GetLoHiChars(LoChar,HiChar);
 For Counter:=1 To Length(S) Do
     Begin
      If Not (S[Counter] In [LoChar..HiChar]) Then
         Begin
          WhatDoOnError:=GetWhatDoOnEvent(BadCharacterTag);
          If WhatDoOnError=_evtError Then
             IsValidPointString:=False;
{          Inc(ErrorsCounter);}
          {$IFNDEF SPLE}
         If WhatDoOnError<>_evtIgnore Then
           Begin
            If Not PntStringInMap Then
              Begin
               PutPntStringAtMap;
              End;
            If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
               PErrorsMap^.Insert(NewStr(' ■ Bad character at position ['+
                        IntToStr(Counter)+']:'+S[Counter]))
            Else
               PErrorsMap^.Insert(NewStr(' ■ Недопустимый символ по смещению ['+
                        IntToStr(Counter)+']:'+S[Counter]));
            If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                Begin
                 If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                    LogWriteLn('! ■ Bad character at position ['+
                            IntToStr(Counter)+']:'+S[Counter])
                 Else
                    LogWriteLn('! ■ Недопустимый символ по смещению ['+
                            IntToStr(Counter)+']:'+S[Counter])
                End;
            End;
          {$ENDIF}
         End;
     End;
 GarbagePos:=Pos(',,',S);
 While GarbagePos>0 Do
   Begin
      WhatDoOnError:=GetWhatDoOnEvent(BadCharacterTag);
      If WhatDoOnError=_evtError Then
         IsValidPointString:=False;
      {$IFNDEF SPLE}
      If WhatDoOnError<>_evtIgnore Then
       Begin
        If Not PntStringInMap Then
          Begin
            PutPntStringAtMap;
          End;
        If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
           PErrorsMap^.Insert(NewStr(' ■ Duplicate commas at position ['+
                    IntToStr(GarbagePos+LastGarbagePos)+']'))
        Else
           PErrorsMap^.Insert(NewStr(' ■ Повторяющиеся запятые по смещению ['+
                    IntToStr(GarbagePos+LastGarbagePos)+']'));
        If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
            Begin
             If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                LogWriteLn('! ■ Duplicate commas at position ['+
                       IntToStr(GarbagePos+LastGarbagePos)+']')
             Else
                LogWriteLn('! ■ Повторяющиеся запятые по смещению ['+
                       IntToStr(GarbagePos+LastGarbagePos)+']')
            End;
       End;
    {$ENDIF}
    LastGarbagePos:=GarbagePos+LastGarbagePos;
    GarbagePos:=Pos(',,',Copy(S,LastGarbagePos+2,Length(S)));
    Inc(LastGarbagePos);
   End;
 If (S[Length(S)]=',')
     {$IFNDEF SPLE}
     And (GetVar(SplitCharTag.Tag,_varNONE)<>',')
     {$ENDIF}
    Then
   Begin
    WhatDoOnError:=GetWhatDoOnEvent(BadCharacterTag);
    If WhatDoOnError=_evtError Then
       IsValidPointString:=False;
      {$IFNDEF SPLE}
    If WhatDoOnError<>_evtIgnore Then
     Begin
      If Not PntStringInMap Then
        Begin
          PutPntStringAtMap;
        End;
      If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
         PErrorsMap^.Insert(NewStr(' ■ String must not ends with comma'))
      Else
         PErrorsMap^.Insert(NewStr(' ■ Строка не должна оканчиваться запятой'));
      If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
          Begin
           If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
              LogWriteLn('! ■ String must not ends with comma')
           Else
              LogWriteLn('! ■ Строка не должна оканчиваться запятой');
          End;
      End;
      {$ENDIF}
   End;
 {************ Загpyзка полей стpоки в коллекцию ***************}
 PPointString:=New(PPointStringRecord,Init(S));
 {************ Пошла пpовеpка на пpавильность ***************}
 With PPointString^ Do
  Begin
   If (PSignature=Nil) or (PNumber=Nil) or (PStationName=Nil) or
      (PLocation=Nil) or (PSysOpName=Nil) or (PPhone=Nil) or
      (PSpeed=Nil) Then
      Begin
       {$IFNDEF SPLE}
       If Not PntStringInMap Then
          Begin
           PutPntStringAtMap;
          End;
       If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
          PErrorsMap^.Insert(NewStr(' ■ Not enough fields in pointstring'))
       Else
          PErrorsMap^.Insert(NewStr(' ■ Неполная поинтстрока'));
       If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
          Begin
           If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
              LogWriteLn('! ■ Not enough fields in pointstring')
           Else
              LogWriteLn('! ■ Неполная поинтстрока')
          End;
       {$ENDIF}
{       LogWriteLn('Not enough fields in pointstring');}
       IsValidPointString:=False;
       PPointString^.Done;
       PPointString:=Nil;
       Exit;
      End;
  End;
 With PPointString^ Do
  Begin
   If Not ((StrToInt(PNumber^)>=1) and (StrToInt(PNumber^)<=32767)) Then
     Begin
      {$IFNDEF SPLE}
      If Not PntStringInMap Then
         Begin
          PutPntStringAtMap;
         End;
      If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
         PErrorsMap^.Insert(NewStr(' ■ Point number is out of range, must be in [1..32767]'))
      Else
         PErrorsMap^.Insert(NewStr(' ■ Номер поинта выходит за допустимые границы, должен быть от 1 до 32767'));
      IsValidPointString:=False;
      If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
         Begin
          If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
             LogWriteLn('! ■ Point number is out of range, must be in [1..32767]')
          Else
             LogWriteLn('! ■ Номер поинта выходит за допустимые границы, должен быть от 1 до 32767');
         End;
      {$ENDIF}
     End;
  End;
 With PPointString^ Do
  Begin
   If GetValueCount(PhoneMaskTag)>1 Then
      Begin
       ForEachVarWithData(PhoneMaskTag.Tag,PPhone,ForEachPhoneMask);
       If Not IsValidPhone Then
          Begin
           WhatDoOnError:=GetWhatDoOnEvent(BadPhoneTag);
           If WhatDoOnError=_evtError Then
              IsValidPointString:=False;
           {$IFNDEF SPLE}
           If WhatDoOnError<>_evtIgnore Then
            Begin
             If Not PntStringInMap Then
               Begin
                PutPntStringAtMap;
               End;
             If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                PErrorsMap^.Insert(NewStr(' ■ Phone is not valid'))
             Else
                PErrorsMap^.Insert(NewStr(' ■ Неверный формат номера телефона'));
             If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
               Begin
                 If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                    LogWriteLn('! ■ Phone is not valid')
                 Else
                    LogWriteLn('! ■ Неверный формат номера телефона');
               End;
           End;
          {$ENDIF}
          End;
      End;
   If GetValueCount(SpeedFlagsTag)>1 Then
      Begin
       ForEachVarWithData(SpeedFlagsTag.Tag,PSpeed,ForEachSpeed);
       If Not IsValidSpeed Then
          Begin
           WhatDoOnError:=GetWhatDoOnEvent(BadSpeedTag);
           If WhatDoOnError=_evtError Then
              IsValidPointString:=False;
           {$IFNDEF SPLE}
           If WhatDoOnError<>_evtIgnore Then
            Begin
             If Not PntStringInMap Then
               Begin
                PutPntStringAtMap;
               End;
             If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                PErrorsMap^.Insert(NewStr(' ■ Speed is not valid'))
             Else
                PErrorsMap^.Insert(NewStr(' ■ Недопустимая скорость'));
             If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
               Begin
                If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                   LogWriteLn('! ■ Speed is not valid')
                Else
                   LogWriteLn('! ■ Недопустимая скорость')
               End;
            End;
           {$ENDIF}
          End;
      End;
{check system, user, redundant, dupes}
 With PPointString^ Do
   Begin
    If PFlags<> Nil Then
       Begin
        SystemFlags:=GetSystemFlags(PFlags);
        UserFlags:=GetUserFlags(PFlags);
        If StrUp(GetVar(AutoFlagsUpCaseTag.Tag,_varNONE))=Yes Then
          Begin
           UpCaseFlags(SystemFlags,False);
           UpCaseFlags(UserFlags,True);
          End;
        DupeFlags:=CheckForDupeFlags(SystemFlags,UserFlags);
        If DupeFlags<>Nil Then
           Begin
             WhatDoOnError:=GetWhatDoOnEvent(DuplicateFlagTag);
             If WhatDoOnError=_evtError Then
                IsValidPointString:=False;
             {$IFNDEF SPLE}
             If WhatDoOnError<>_evtIgnore Then
              Begin
               If Not PntStringInMap Then
                 Begin
                  PutPntStringAtMap;
                 End;
                  If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                    PErrorsMap^.Insert(NewStr(' ■ Duplicate flags:'))
                  Else
                    PErrorsMap^.Insert(NewStr(' ■ Повторяющиеся флаги:'));
                  If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                    Begin
                     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                        LogWriteLn('! ■ Duplicate flags:')
                     Else
                        LogWriteLn('! ■ Повторяющиеся флаги:')
                    End;
               For Counter:=0 To Pred(DupeFlags^.Count) Do
                  Begin
                   If DupeFlags^.At(Counter)<>Nil Then
                    Begin
                    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                       PErrorsMap^.Insert(NewStr('  · Flag ['+PFlagRecord(DupeFlags^.At(Counter))^.PFlag^+
                                          '] at position ['+IntToStr(PFlagRecord(DupeFlags^.At(Counter))^.TStringOffset)+']'
                                         ))
                    Else
                       PErrorsMap^.Insert(NewStr('  · Флаг ['+PFlagRecord(DupeFlags^.At(Counter))^.PFlag^+
                                          '] по смещению ['+IntToStr(PFlagRecord(DupeFlags^.At(Counter))^.TStringOffset)+']'
                                         ));
                    If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                       LogWriteLn('!  · Flag ['+PFlagRecord(DupeFlags^.At(Counter))^.PFlag^+
                                          '] at position ['+IntToStr(PFlagRecord(DupeFlags^.At(Counter))^.TStringOffset)+']'
                                  )
                    Else
                       LogWriteLn('!  · Флаг ['+PFlagRecord(DupeFlags^.At(Counter))^.PFlag^+
                                          '] по смещению ['+IntToStr(PFlagRecord(DupeFlags^.At(Counter))^.TStringOffset)+']'
                                  );
                    End;
                  End;
              End;
            {$ENDIF}
           End;
        If GetValueCount(SystemFlagsTag)>1 Then
           Begin
            NotValidSystemFlags:=CheckSystemFlags(SystemFlags);
            If NotValidSystemFlags<>Nil Then
               Begin
                WhatDoOnError:=GetWhatDoOnEvent(BadSystemFlagTag);
                If WhatDoOnError=_evtError Then
                   IsValidPointString:=False;
                {$IFNDEF SPLE}
                If WhatDoOnError<>_evtIgnore Then
                Begin
                If Not PntStringInMap Then
                  Begin
                   PutPntStringAtMap;
                  End;
                   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                     PErrorsMap^.Insert(NewStr(' ■ Unknown system flag:'))
                   Else
                     PErrorsMap^.Insert(NewStr(' ■ Неизвестный системный флаг:'));
                   If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                     Begin
                      If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                         LogWriteLn('! ■ Unknown system flag:')
                      Else
                         LogWriteLn('! ■ Неизвестный системный флаг:')
                     End;
                 For Counter:=0 To Pred(NotValidSystemFlags^.Count) Do
                   Begin
                    If NotValidSystemFlags^.At(Counter)<>Nil Then
                     Begin
                     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                        PErrorsMap^.Insert(NewStr('  · Flag ['+PFlagRecord(NotValidSystemFlags^.At(Counter))^.PFlag^+
                                   '] at position ['+IntToStr(PFlagRecord(NotValidSystemFlags^.At(Counter))^.TStringOffset)+']'
                                          ))
                     Else
                        PErrorsMap^.Insert(NewStr('  · Флаг ['+PFlagRecord(NotValidSystemFlags^.At(Counter))^.PFlag^+
                                   '] по смещению ['+IntToStr(PFlagRecord(NotValidSystemFlags^.At(Counter))^.TStringOffset)+']'
                                          ));
                     If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                        LogWriteLn('!  · Flag ['+PFlagRecord(NotValidSystemFlags^.At(Counter))^.PFlag^+
                                   '] at position ['+IntToStr(PFlagRecord(NotValidSystemFlags^.At(Counter))^.TStringOffset)+']'
                                   )
                     Else
                        LogWriteLn('!  · Флаг ['+PFlagRecord(NotValidSystemFlags^.At(Counter))^.PFlag^+
                                   '] по смещению ['+IntToStr(PFlagRecord(NotValidSystemFlags^.At(Counter))^.TStringOffset)+']'
                                   );
                    End;
                   End;
                 End;
                {$ENDIF}
               End;
           End;
        If GetValueCount(UserFlagsTag)>1 Then
           Begin
            NotValidUserFlags:=CheckUserFlags(UserFlags);
            If NotValidUserFlags<>Nil Then
               Begin
                WhatDoOnError:=GetWhatDoOnEvent(BadUserFlagTag);
                If WhatDoOnError=_evtError Then
                   IsValidPointString:=False;
                {$IFNDEF SPLE}
                If WhatDoOnError<>_evtIgnore Then
                Begin
                If Not PntStringInMap Then
                  Begin
                   PutPntStringAtMap;
                  End;
                   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                     PErrorsMap^.Insert(NewStr(' ■ Unknown user flag:'))
                   Else
                     PErrorsMap^.Insert(NewStr(' ■ Неизвестный пользовательский флаг:'));
                   If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                     Begin
                      If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                         LogWriteLn('! ■ Unknown user flag:')
                      Else
                         LogWriteLn('! ■ Неизвестный пользовательский флаг:')
                     End;
                 For Counter:=0 To Pred(NotValidUserFlags^.Count) Do
                   Begin
                    If NotValidUserFlags^.At(Counter)<>Nil Then
                     Begin
                     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                        PErrorsMap^.Insert(NewStr('  · Flag ['+PFlagRecord(NotValidUserFlags^.At(Counter))^.PFlag^+
                                   '] at position ['+IntToStr(PFlagRecord(NotValidUserFlags^.At(Counter))^.TStringOffset)+']'
                                          ))
                     Else
                        PErrorsMap^.Insert(NewStr('  · Флаг ['+PFlagRecord(NotValidUserFlags^.At(Counter))^.PFlag^+
                                   '] по смещению ['+IntToStr(PFlagRecord(NotValidUserFlags^.At(Counter))^.TStringOffset)+']'
                                          ));
                     If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                        LogWriteLn('!  · Flag ['+PFlagRecord(NotValidUserFlags^.At(Counter))^.PFlag^+
                                   '] at position ['+IntToStr(PFlagRecord(NotValidUserFlags^.At(Counter))^.TStringOffset)+']'
                                   )
                     Else
                        LogWriteLn('!  · Флаг ['+PFlagRecord(NotValidUserFlags^.At(Counter))^.PFlag^+
                                   '] по смещению ['+IntToStr(PFlagRecord(NotValidUserFlags^.At(Counter))^.TStringOffset)+']'
                                   );
                     End;
                   End;
                 End;
                {$ENDIF}
               End;
           End;
        If GetValueCount(ImpliesFlagsTag)>1 Then
           Begin
            RedundantFlags:=CheckRedundantFlags(SystemFlags,UserFlags);
            If RedundantFlags<>Nil Then
               Begin
                WhatDoOnError:=GetWhatDoOnEvent(RedundantFlagTag);
                If WhatDoOnError=_evtError Then
                   IsValidPointString:=False;
                {$IFNDEF SPLE}
                If WhatDoOnError<>_evtIgnore Then
                Begin
                If Not PntStringInMap Then
                   PutPntStringAtMap;
                If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                  Begin
                   PErrorsMap^.Insert(NewStr(' ■ Redundant flags:'));
                   LogWriteLn('! ■ Redundant flags:');
                  End
                Else
                  Begin
                   PErrorsMap^.Insert(NewStr(' ■ Излишние флаги:'));
                   LogWriteLn('! ■ Излишние флаги:');
                  End;
                For Counter:=0 To Pred(RedundantFlags^.Count) Do
                  Begin
                    If RedundantFlags^.At(Counter)<>Nil Then
                      Begin
                       PErrorsMap^.Insert(MCommon.NewStr(PString(RedundantFlags^.At(Counter))^));
                       If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                          LogWriteLn('!'+PString(RedundantFlags^.At(Counter))^);
                      End;
                  End;
                 End;
                {$ENDIF}
               End;
           End;
       End;
   End;


  End;
 If PErrorsMap^.Count=0 Then
   Begin
    PErrorsMap^.Done;
    PErrorsMap:=Nil;
   End;
 If SystemFlags<>Nil Then
    Dispose(SystemFlags,Done);
 If UserFlags<>Nil Then
    Dispose(UserFlags,Done);
 If DupeFlags<>Nil Then
    Dispose(DupeFlags,Done);
 If NotValidSystemFlags<> Nil Then
    Dispose(NotValidSystemFlags,Done);
 If NotValidUserFlags<> Nil Then
    Dispose(NotValidUserFlags,Done);
 If RedundantFlags<>Nil Then
    Dispose(RedundantFlags,Done);
 Dispose(PPointString,Done);
End;

Procedure ForEachExclude(Pnt:Pointer);far;
Var
{PStr:PString absolute Pnt;}
PStr:String;
Addr:TAddress;
IsReverse:Boolean;
Begin
If _ExcludeFound Then
   Exit;
IsReverse:=False;
PStr:=PString(Pnt)^;
ExpandString(PStr);
If StrTrim(PStr)='' Then
   Exit;
If Copy(PadLeft(PStr),1,1)='!' Then
   Begin
    Delete(PStr,Pos('!',PStr),1);
    IsReverse:=True;
   End;
If IsReverse Then
   Begin
    If Not (IsAddressMatch(StrTrim(PStr),ExcludeAddr)) Then
      Begin
       _ExcludeFound:=True;
       _IsInExcludeList:=True;
      End;
   End
  Else
   Begin
    If IsAddressMatch(StrTrim(PStr),ExcludeAddr) Then
      Begin
       _ExcludeFound:=True;
       _IsInExcludeList:=True;
      End;
   End;
End;

Type
  TExcludeFileHeader=Record
{       FileName:String[11];
       FileCRC32:LongInt;}
       Version:VersionRec;
       TotalFileRecords:Word;
{       TotalRecords:Word;}
End;
Type
  TExcludeFileRecord=Record
       FileName:String[79];
{       FileCRC32:LongInt;}
        FileTimeStamp:LongInt;
        FileSize:LongInt;
{       Offset:LongInt;}
End;


Procedure LoadExcludeList;
{.IFNDEF SPLE}
Label IndexProc;

Const
 ExcludeIndexFileName='exclude.idx';

Var
ExcludeIndexFile:File;
ExcludeFileHeader:TExcludeFileHeader;
ExcludeFileRecord:TExcludeFileRecord;
ExcludeAddress:TExcludeAddress;
ExcludeAddressString:String;
_ExcludeHold,_ExcludeDown,
_ExcludePvt:Boolean;
ExcludeStatus:String;
Counter:Word;
_MustBeReIndexed:Boolean;
ValueCollection:PValueCollection;
NodeList:Text;
ReadedStr:String;
{BeginPos,EndPos:Word;}
{ListCRC:LongInt;}

 Procedure ForEachNodeListCheckTimeAndSize(Point:Pointer);
  Begin
    If _MustBeReIndexed Then
       Exit;
    If StrTrim(PString(Point)^)='' Then
       Exit;
    BlockRead(ExcludeIndexFile,ExcludeFileRecord,SizeOf(ExcludeFileRecord));
    If IOResult<>0 Then
       Begin
        LogWriteLn(GetExpandedString(_logIndexFileDamaged));
        Rewrite(ExcludeIndexFile,1);
        _MustBeReIndexed:=True;
        Exit;
       End;
    If (ExcludeFileRecord.FileTimeStamp<>GetFileTimeStamp(PString(Point)^)) Or
       (ExcludeFileRecord.FileSize<>GetFileSize(PString(Point)^)) Then
       Begin
        _MustBeReIndexed:=True;
       End;
  End;

 Procedure ForEachNodeListWriteListData(Pnt:Pointer);
  Var
  DirInfo:SearchRec;
  Dir:DirStr;
  Name:NameStr;
  Ext:ExtStr;
  Begin
    If StrTrim(PString(Pnt)^)='' Then
       Exit;
    FSplit(PString(Pnt)^,Dir,Name,Ext);
    FindFirstEx(PString(Pnt)^,AnyFile-Directory-VolumeID-Hidden-ReadOnly,DirInfo);
    While DosError=0 Do
      Begin
       If DosErrorEx=0 Then
          Begin
                 FillChar(ExcludeFileRecord.FileName,SizeOf(ExcludeFileRecord.FileName),' ');
                 ExcludeFileRecord.FileName:=FExpand(Dir+DirInfo.Name);
                 ExcludeFileRecord.FileTimeStamp:=GetFileTimeStamp(Dir+DirInfo.Name);
                 ExcludeFileRecord.FileSize:=GetFileSize(Dir+DirInfo.Name);
                 BlockWrite(ExcludeIndexFile,ExcludeFileRecord,SizeOf(ExcludeFileRecord));
                 Inc(ExcludeFileHeader.TotalFileRecords);
                 FindNextEx(DirInfo);
          End;
      End;
    FindCloseEx(DirInfo);
  End;
{.ENDIF}
Begin
{.IFNDEF SPLE}
If _ExcludeListLoaded Then
    Exit;
If GetValueCount(GetExcludeFromNodeListTag)<=1 Then
   Begin
    _ExcludeListLoaded:=True;
    Exit;
   End;
_ExcludeHold:=False;
_ExcludeDown:=False;
_ExcludePvt:=False;
_MustBeReIndexed:=False;
ExcludeStatus:=StrUp(StrTrim(GetVar(ExcludeStatusTag.Tag,_varNONE)));
_ExcludeDown:=(Pos(DownTag,ExcludeStatus)<>0);
_ExcludeHold:=(Pos(HoldTag,ExcludeStatus)<>0);
_ExcludePvt:=(Pos(PvtTag,ExcludeStatus)<>0);
Assign(ExcludeIndexFile,ExcludeIndexFileName);
While (True) Do
  Begin
   {$I-}
   Reset(ExcludeIndexFile,1);
   {.I+}
   If IOResult<>0 Then
      Begin
       Rewrite(ExcludeIndexFile,1);
       If IOResult<>0 Then
          LogWriteLn(GetExpandedString(_logCantOpenFile)+ExcludeIndexFileName)
         Else
          Break;
      End;

   BlockRead(ExcludeIndexFile,ExcludeFileHeader,SizeOf(ExcludeFileHeader));
   If IOResult<>0 Then
      Begin
       LogWriteLn(GetExpandedString(_logNotAnIndexFile)+ExcludeIndexFileName);
       Rewrite(ExcludeIndexFile,1);
       Break;
      End;
   If (GetValueCount(GetExcludeFromNodelistTag)-1)<>ExcludeFileHeader.TotalFileRecords Then
      Begin
       Rewrite(ExcludeIndexFile,1);
       If IOResult=0 Then;
       Break;
      End;
   ValueCollection:=GetValueCollectionPointer(GetExcludeFromNodeListTag);
   If ValueCollection<>Nil Then
      Begin
       For Counter:=0 To Pred(ValueCollection^.Count) Do
           ForEachNodeListCheckTimeAndSize(ValueCollection^.At(Counter));
      End;
   If _MustBeReIndexed Then
      Begin
       LogWriteLn(GetExpandedString(_logIndexFileWillBeReindexed));
       Rewrite(ExcludeIndexFile,1);
       If IOResult=0 Then;
       Break;
      End;
   While (Not Eof(ExcludeIndexFile)) And (FilePos(ExcludeIndexFile)<=FileSize(ExcludeIndexFile)) Do
      Begin
       BlockRead(ExcludeIndexFile,ExcludeAddress,SizeOf(TExcludeAddress));
       If IOResult<>0 Then
          Begin
           LogWriteLn(GetExpandedString(_logIndexFileDamaged));
           Rewrite(ExcludeIndexFile,1);
           Goto IndexProc;
          End;
       SetStringFromExcludeAddress(ExcludeAddressString,ExcludeAddress);
       SetVar(ExcludeTag,ExcludeAddressString);
      End;
   Exit;
  End;
IndexProc:
SetExcludeAddressFromAddress(PntMasterAddress,ExcludeAddress);
{FillChar(ExcludeFileHeader.Version,SizeOf(ExcludeFileHeader.Version),0);}
ExcludeFileHeader.Version:=BinaryMasterVersion;
ExcludeFileHeader.TotalFileRecords:=0;
Seek(ExcludeIndexFile,0);
If IOResult=0 Then;
BlockWrite(ExcludeIndexFile,ExcludeFileHeader,SizeOf(ExcludeFileHeader));
If IOResult=0 Then;
ValueCollection:=GetValueCollectionPointer(GetExcludeFromNodeListTag);
If ValueCollection<>Nil Then
   Begin
    For Counter:=0 To Pred(ValueCollection^.Count) Do
        ForEachNodeListWriteListData(ValueCollection^.At(Counter));
   End;

Seek(ExcludeIndexFile,0);
If IOResult=0 Then;
BlockWrite(ExcludeIndexFile,ExcludeFileHeader,SizeOf(ExcludeFileHeader));
If IOResult=0 Then;

 {      SetStringFromExcludeAddress(ExcludeAddressString,ExcludeAddress);
       SetVar(ExcludeTag,ExcludeAddressString,_varNONE);}
For Counter:= 1 To ExcludeFileHeader.TotalFileRecords Do
  Begin
   BlockRead(ExcludeIndexFile,ExcludeFileRecord,SizeOf(ExcludeFIleRecord));
   If IOResult=0 Then;
   Assign(NodeList,ExcludeFileRecord.FileName);
   {$I-}
   Reset(NodeList);
   If IOResult=0 Then
      Begin
       LogWriteLn(GetExpandedString(_logBuildExcludeListIndex)+ExcludeFileRecord.FileName);
       Seek(ExcludeIndexFile,FileSize(ExcludeIndexFile));
       If IOResult=0 Then;
       While Not Eof(NodeList) Do
        Begin
         ReadLn(NodeList,ReadedStr);
         ReadedStr:=PadLeft(ReadedStr);
         If (ReadedStr<>'') And (ReadedStr[1]<>';') Then
            Begin
             If Pos(ZoneTag,StrUp(Copy(ReadedStr,1,6)))=1 Then
                Begin
                 ExcludeAddress.Zone:=StrToInt(
                                      Copy(ReadedStr,Length(ZoneTag)+2,Pos(',',Copy(ReadedStr,Length(ZoneTag)+2,
                                      Length(ReadedStr)))-1));
                End
               Else
             If Pos(RegionTag,StrUp(Copy(ReadedStr,1,6)))=1 Then
                Begin
                 ExcludeAddress.Net:=StrToInt(
                                      Copy(ReadedStr,Length(RegionTag)+2,Pos(',',Copy(ReadedStr,Length(RegionTag)+2,
                                      Length(ReadedStr)))-1));
                End
               Else
             If Pos(HostTag,StrUp(Copy(ReadedStr,1,6)))=1 Then
                Begin
                 ExcludeAddress.Net:=StrToInt(
                                      Copy(ReadedStr,Length(HostTag)+2,Pos(',',Copy(ReadedStr,Length(HostTag)+2,
                                      Length(ReadedStr)))-1));
                End
               Else
             If Pos(DownTag,StrUp(Copy(ReadedStr,1,6)))=1 Then
                Begin
                 ExcludeAddress.Node:=StrToInt(
                                      Copy(ReadedStr,Length(DownTag)+2,Pos(',',Copy(ReadedStr,Length(DownTag)+2,
                                      Length(ReadedStr)))-1));
                 If _ExcludeDown Then
                    Begin
                     BlockWrite(ExcludeIndexFile,ExcludeAddress,SizeOf(ExcludeAddress));
                     If IOResult=0 Then;
                     SetVar(ExcludeTag,GetStringFromExcludeAddress(ExcludeAddress));
                    End;
                End
               Else
             If Pos(HoldTag,StrUp(Copy(ReadedStr,1,6)))=1 Then
                Begin
                 ExcludeAddress.Node:=StrToInt(
                                      Copy(ReadedStr,Length(HoldTag)+2,Pos(',',Copy(ReadedStr,Length(HoldTag)+2,
                                      Length(ReadedStr)))-1));
                 If _ExcludeHold Then
                    Begin
                     BlockWrite(ExcludeIndexFile,ExcludeAddress,SizeOf(ExcludeAddress));
                     If IOResult=0 Then;
                     SetVar(ExcludeTag,GetStringFromExcludeAddress(ExcludeAddress));
                    End;
                End
               Else
             If Pos(PvtTag,StrUp(Copy(ReadedStr,1,6)))=1 Then
                Begin
                 ExcludeAddress.Node:=StrToInt(
                                      Copy(ReadedStr,Length(PvtTag)+2,Pos(',',Copy(ReadedStr,Length(PvtTag)+2,
                                      Length(ReadedStr)))-1));
                 If _ExcludePvt Then
                    Begin
                     BlockWrite(ExcludeIndexFile,ExcludeAddress,SizeOf(ExcludeAddress));
                     If IOResult=0 Then;
                     SetVar(ExcludeTag,GetStringFromExcludeAddress(ExcludeAddress));
                    End;
                End;
            End;
        End;
       Close(NodeList);
       If IOResult=0 Then;
       Seek(ExcludeIndexFile,SizeOf(ExcludeFileHeader)+(Counter*SizeOf(ExcludeFileRecord)));
       If IOResult=0 Then;
      End
     Else
      LogWriteLn(GetExpandedString(_logCantOpenFile)+ExcludeFileRecord.FileName);
  End;

Close(ExcludeIndexFile);
If IOResult=0 Then;
{$I+}
_ExcludeListLoaded:=True;
{.ENDIF}

End;

Function IsInExcludeList(BossStr:String):Boolean;
Begin
 IsInExcludeList:=False;
 _IsInExcludeList:=False;
 {$IFNDEF SPLE}
 _ExcludeFound:=False;
{ If StrUp(GetVar(UseExcludeTag.Tag,_varNONE))=Yes Then}
    Begin
     SetAddressFromString(BossStr,ExcludeAddr);
     ForEachVar(ExcludeTag.Tag,ForEachExclude);
     If _IsInExcludeList Then
       Begin
        IsInExcludeList:=True;
{        LogWriteLn(GetExpandedString(_logInExcludeList)+GetStringFromAddress(ExcludeAddr));}
       End;
    End;
  {$ENDIF}
End;


Function PosString(S:String):Integer;
Begin
PosString:=0;
 If (S=';') or (S='') Then
    Begin
     PosString:=POS_SKIP;
     Exit;
    End
Else
 If Pos(EBossTag,S)=1 Then
    Begin
     PosString:=POS_BOSS;
     Exit;
    End
Else
 If Pos(EPointTag,S)=1 Then
    Begin
     PosString:=POS_POINT;
     Exit;
    End
Else
 If S[1]=';' Then
    Begin
     PosString:=POS_COMMENT;
     Exit;
    End
Else
   Begin
    PosString:=POS_ERROR;
   End;
End;


Procedure ReadPointListToMemory(Var PointList:Text);
Var
ReadedStr:String;
BeginPos,EndPos,DotPos:Word;
StringsCount:Word;
OldTotalBytes,OldReadedBytes:LongInt;
TempErrorsMap:PMessageBody;
BossValidator:PPXPictureValidator;
Begin
StringsCount:=0;
OldTotalBytes:=TotalBytes;
OldReadedBytes:=ReadedBytes;
TotalBytes:=TextFileSize(PointList);
ReadedBytes:=0;
BossValidator:=Nil;
{$IFDEF SPLE}
ProgressBar('Please wait...', 0, TotalBytes, FALSE);
{$ENDIF}
TempErrorsMap:=Nil;
While (Not Eof(PointList)) Do
  Begin
   ReadLn(PointList,ReadedStr);
   Inc(ReadedBytes,Length(ReadedStr));
   {$IFDEF SPLE}
    ProgressBar ('Loading pointlist...', ReadedBytes, TotalBytes, FALSE);
{    TimeSlice;}
   {$ENDIF}
   ReadedStr:=StrTrim(ReadedStr);
   Inc(StringsCount);
   If StringsCount>StringsToSkipAtBegin Then
   Begin
   Case PosString(StrUp(PadLeft(Copy(ReadedStr,1,7)))) Of
        POS_SKIP:;
        POS_ERROR:
                  Begin
                   {$IFNDEF SPLE}
                    CheckErrors:=True;
                    If PSegmentErrorsMap=Nil Then
                       PSegmentErrorsMap:=New(PMessageBody,Init(10,5));

                    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                      Begin
                       PSegmentErrorsMap^.Insert(NewStr('File: '+ GetFNameAndExt(PntListName)));

                       PSegmentErrorsMap^.Insert(NewStr('Invalid line ['+
                            IntToStr(StringsCount+StringsToSkipAtBegin)+']:'));
                       PSegmentErrorsMap^.Insert(NewStr(Copy(RArrow+ReadedStr,1,253)+#13#10));
                       If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                          Begin
                            LogWriteLn('!File: '+ GetFNameAndExt(PntListName));
                            LogWriteLn('!Invalid line ['+
                                IntToStr(StringsCount+StringsToSkipAtBegin)+']:');
                            LogWriteLn('!'+(Copy(RArrow+ReadedStr,1,253)));
                          End;
                      End
                    Else
                      Begin
                       PSegmentErrorsMap^.Insert(NewStr('Файл: '+ GetFNameAndExt(PntListName)));
                       PSegmentErrorsMap^.Insert(NewStr('Неверная стpока ['+
                            IntToStr(StringsCount+StringsToSkipAtBegin)+']:'));
                       PSegmentErrorsMap^.Insert(NewStr(Copy(RArrow+ReadedStr,1,253)+#13#10));
                       If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                          Begin
                            LogWriteLn('!Файл: '+ GetFNameAndExt(PntListName));
                            LogWriteLn('!Неверная строка ['+
                                IntToStr(StringsCount+StringsToSkipAtBegin)+']:');
                            LogWriteLn('!'+(Copy(RArrow+ReadedStr,1,253)));
                          End;
                      End;
                    {$ENDIF}
                   End;

        POS_COMMENT:
                    Begin
                     If (Not IsBossFoundInSegment) Then
                        Begin
                          If StrUp(GetVar(CommentsBeforeBossTag.Tag,_varNONE))=Yes Then
                             Begin
                              CurrentComments^.Insert(MCommon.NewStr(ReadedStr));
                             End;
                        End
                    Else
                     If IsBossFoundInSegment Then
                        Begin
                          If StrUp(GetVar(CommentsBeforeBossTag.Tag,_varNONE))=Yes Then
                             Begin
                               If Not(IsInExcludeList(SegmentBossString)) Then
                                   Begin
                                     BossRecArray^.Insert(New(
                                                          PBossRecord,Init(
                                                          SegmentBossString,CurrentComments,CurrentPoints)));
                                   End
                                Else
                                   Begin
                                     LogWriteLn(GetExpandedString(_logInExcludeList)+GetStringFromAddress(ExcludeAddr));
                                   End;
                               CurrentPoints^.FreeAll;
                               CurrentComments^.FreeAll;
                               IsBossFoundInSegment:=False;
                               SegmentBossString:='';
                               CurrentComments^.Insert(MCommon.NewStr(ReadedStr));
                             End
                         Else
                             Begin
                              CurrentComments^.Insert(MCommon.NewStr(ReadedStr));
                             End;
                        End;
                    End;
        POS_POINT:
                  Begin
                   If IsBossFoundInSegment Then
                      Begin
                       If StrUp(GetVar(UseValidateTag.Tag,_varNONE))=Yes Then
                          Begin
                           If IsValidPointString(SegmentBossString,ReadedStr,TempErrorsMap) Then
                             Begin
                              {$IFNDEF SPLE}
                              If (TempErrorsMap<>Nil) And (TempErrorsMap^.Count<>0) Then
                               Begin
                                CheckErrors:=True;
                                If WorkMode<>MODE_CHECKLIST Then
                                  Begin
                                   If BossWithSegmentErrorsArray=Nil Then
                                     Begin
                                      BossWithSegmentErrorsArray:=New(PBossWithSegmentErrorsArray,Init(10,2));
                                      BossWithSegmentErrorsArray^.Duplicates:=True;
                                     End;
                                   BossWithSegmentErrorsArray^.Insert(New(
                                           PBossWithSegmentErrors,Init(
                                                                       SegmentBossString,
                                                                       GetFNameAndExt(PntListname),
                                                                       TempErrorsMap)));
                                  End;
                                 If TempErrorsMap<>Nil Then
                                   Begin
                                    TempErrorsMap^.Done;
                                    TempErrorsMap:=Nil;
                                   End;
{                                 Inc(ErrorPoints);}
                               End;
                              {$ELSE}
                               If TempErrorsMap<>Nil Then
                                 Begin
                                  TempErrorsMap^.Done;
                                  TempErrorsMap:=Nil;
                                 End;
{                               Inc(ErrorPoints);}
                              {$ENDIF}
                              CurrentPoints^.Insert(MCommon.NewStr(ReadedStr));
                             End
                          Else
                           Begin
                            {$IFNDEF SPLE}
                            CheckErrors:=True;
                            If WorkMode<>MODE_CHECKLIST Then
                              Begin
                               If BossWithSegmentErrorsArray=Nil Then
                                 Begin
                                  BossWithSegmentErrorsArray:=New(PBossWithSegmentErrorsArray,Init(10,2));
                                  BossWithSegmentErrorsArray^.Duplicates:=True;
                                 End;
                               BossWithSegmentErrorsArray^.Insert(New(
                                       PBossWithSegmentErrors,Init(
                                                                   SegmentBossString,
                                                                   GetFNameAndExt(PntListname),
                                                                   TempErrorsMap)));
                              End;
                             If TempErrorsMap<>Nil Then
                               Begin
                                TempErrorsMap^.Done;
                                TempErrorsMap:=Nil;
                               End;
                             Inc(ErrorPoints);
                            {$ELSE}
                             If TempErrorsMap<>Nil Then
                               Begin
                                TempErrorsMap^.Done;
                                TempErrorsMap:=Nil;
                               End;
                             Inc(ErrorPoints);
                            {$ENDIF}
                           End;
                          End
                      Else
                        CurrentPoints^.Insert(MCommon.NewStr(ReadedStr));
                      End
                  Else
                      Begin
                       CheckErrors:=True;
                       {$IFNDEF SPLE}
                       If PSegmentErrorsMap=Nil Then
                          PSegmentErrorsMap:=New(PMessageBody,Init(10,5));

                       If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                         Begin
                          PSegmentErrorsMap^.Insert(NewStr('File: '+ GetFNameAndExt(PntListName)));
                          PSegmentErrorsMap^.Insert(NewStr('Boss not defined, but point is present. Line ['+
                              IntToStr(StringsCount+StringsToSkipAtBegin)+']'+#13#10));
                          If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                            Begin
                             LogWriteLn('!File: '+ GetFNameAndExt(PntListName));
                             LogWriteLn('!Boss not defined, but point is present. Line ['+
                                  IntToStr(StringsCount+StringsToSkipAtBegin)+']');
                            End;
                         End
                       Else
                         Begin
                          PSegmentErrorsMap^.Insert(NewStr('Файл: '+ GetFNameAndExt(PntListName)));
                          PSegmentErrorsMap^.Insert(NewStr('Босс не задан, но обнаpyжена поинтстpока. Стpока ['+
                              IntToStr(StringsCount+StringsToSkipAtBegin)+']'+#13#10));
                          If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                            Begin
                             LogWriteLn('!Файл: '+ GetFNameAndExt(PntListName));
                             LogWriteLn('!Босс не задан, но обнаружена поинтстрока. Строка ['+
                                  IntToStr(StringsCount+StringsToSkipAtBegin)+']');
                            End;
                         End;
                       {$ENDIF}
                      End;
                  End;
        POS_BOSS:
                 Begin
                  RefreshScreen;
                  If IsBossFoundInSegment Then
                     Begin
                       If Not(IsInExcludeList(SegmentBossString)) Then
                           Begin
                            BossRecArray^.Insert(New(
                                                 PBossRecord,Init(
                                                 SegmentBossString,CurrentComments,CurrentPoints)));
                           End
                       Else
                           Begin
                            LogWriteLn(GetExpandedString(_logInExcludeList)+GetStringFromAddress(ExcludeAddr));
                           End;
                      CurrentPoints^.FreeAll;
                      CurrentComments^.FreeAll;
                      IsBossFoundInSegment:=False;
                      SegmentBossString:=ReadedStr;
                      IsBossFoundInSegment:=True;
                     End
                 Else
                     Begin
                      SegmentBossString:=ReadedStr;
                      DeleteSpacesInString(SegmentBossString);
                      IsBossFoundInSegment:=True;
                      DotPos:=Pos('.',SegmentBossString);
                      If DotPos>0 Then
                         Begin
                          CheckErrors:=True;
                          {$IFNDEF SPLE}
                          If PSegmentErrorsMap=Nil Then
                             PSegmentErrorsMap:=New(PMessageBody,Init(10,5));
                          If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                             Begin
                              PSegmentErrorsMap^.Insert(NewStr('File: '+ GetFNameAndExt(PntListName)));
                              PSegmentErrorsMap^.Insert(NewStr('Boss address ('+SegmentBossString+') may be contains point '+
                                                 'number at position ['+IntToStr(DotPos+1)+']. Fixed'));
                              If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                                Begin
                                  LogWriteLn('!File: '+ GetFNameAndExt(PntListName));
                                  LogWriteLn('!Boss address ('+SegmentBossString+') may be contains point '+
                                                    'number at position ['+IntToStr(DotPos+1)+']. Fixed');
                                End;
                             End
                          Else
                             Begin
                              PSegmentErrorsMap^.Insert(NewStr('Файл: '+ GetFNameAndExt(PntListName)));
                              PSegmentErrorsMap^.Insert(NewStr('Адрес босса ('+SegmentBossString+') возможно содержит номер '+
                                                 'поинта по смещению ['+IntToStr(DotPos+1)+']. Исправлено'));
                              If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                                Begin
                                  LogWriteLn('!Файл: '+ GetFNameAndExt(PntListName));
                                  LogWriteLn('!Адрес босса ('+SegmentBossString+') возможно содержит номер '+
                                                     'поинта по смещению ['+IntToStr(DotPos+1)+']. Исправлено');
                                End;

                             End;
                          {$ENDIF}
                          Delete(SegmentBossString,DotPos,Length(SegmentBossString)-DotPos+1);
                         End;

                      If BossValidator=Nil Then
                         BossValidator:=New(PPXPictureValidator,Init(BossAddressMask,False));
{                      Else
                         Begin
                          If BossValidator^.Pic<>Nil Then
                             DisposeStr(BossValidator^.Pic);
                          BossValidator^.Pic:=BossAddressMask;
                         End;}
                      If (Not BossValidator^.IsValid(Copy(SegmentBossString,Pos(',',SegmentBossString)+1,255))) Then
                          Begin
                            IsBossFoundInSegment:=False;
                            CheckErrors:=True;
                            {$IFNDEF SPLE}
                              If PSegmentErrorsMap=Nil Then
                                 PSegmentErrorsMap:=New(PMessageBody,Init(10,5));
                              If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                                 Begin
                                  PSegmentErrorsMap^.Insert(NewStr('File: '+ GetFNameAndExt(PntListName)));
                                  PSegmentErrorsMap^.Insert(NewStr('Boss address ('+SegmentBossString+
                                                                   ') is not valid. Skipped'));
                                  If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                                     Begin
                                      LogWriteLn('!File: '+ GetFNameAndExt(PntListName));
                                      LogWriteLn('!Boss address ('+SegmentBossString+') is not valid. Skipped');
                                     End;
                                 End
                              Else
                                 Begin
                                  PSegmentErrorsMap^.Insert(NewStr('Файл: '+ GetFNameAndExt(PntListName)));
                                  PSegmentErrorsMap^.Insert(NewStr('Адрес босса ('+SegmentBossString+
                                        ') неверный. Пропущен'));
                                  If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                                    Begin
                                      LogWriteLn('!Файл: '+ GetFNameAndExt(PntListName));
                                      LogWriteLn('!Адрес босса ('+SegmentBossString+') не верен. Пропущен');
                                    End;

                                 End;
                            {$ENDIF}
                            SegmentBossString:='';
                          End;
                     End;
                 End;
     End;
     End;
  End;
   If SegmentBossString<>'' Then
      Begin
        If Not (IsInExcludeList(SegmentBossString)) Then
          Begin
            BossRecArray^.Insert(New(
                                 PBossRecord,Init(
                                 SegmentBossString,CurrentComments,CurrentPoints)));
          End
        Else
          Begin
            LogWriteLn(GetExpandedString(_logInExcludeList)+GetStringFromAddress(ExcludeAddr));
          End;
      End;
   IsBossFoundInSegment:=False;
   CurrentPoints^.FreeAll;
   CurrentComments^.FreeAll;
   IsBossFoundInSegment:=False;
   SegmentBossString:='';
   StringsCount:=0;
   If BossValidator<>Nil Then
      Dispose(BossValidator,Done);
   {$IFDEF SPLE}
    ProgressBar ('', 0, 0, TRUE);
   {$ENDIF}
   TotalBytes:=OldTotalBytes;
   ReadedBytes:=OldReadedBytes;
End;

Function InitPointList(PointListName:String):Boolean;
Var
DirInfo:SearchRec;
PointList:Text;
D:DirStr;
N:NameStr;
E:ExtStr;
BeginPos:Byte;
R:TRect;
InOutResult:Integer;
Begin
{BossFound:=False;}
IsBossFoundInSegment:=False;
If BossRecArray=Nil Then
   BossRecArray:=New(PBossRecSortedCollection,Init(10,10));
If CurrentPoints=Nil Then
   CurrentPoints:=New(PPointsCollection,Init(10,10));
If CurrentComments=Nil Then
   CurrentComments:=New(PCommentsCollection,Init(10,10));
PointListName:=StrTrim(PointListName);
If PointListName='' Then
   Exit;
BeginPos:=Pos(' ',PointListName);
If BeginPos<>0 Then
   Begin
    StringsToSkipAtBegin:=StrToInt(StrTrim(Copy(PointListName,BeginPos,255)));
   End
  Else
   Begin
    StringsToSkipAtBegin:=0;
   End;
FindFirstEx(PointListName,{AnyFile-Directory}(SysFile or Archive),DirInfo);
While DosError= 0 Do
Begin
 If DosErrorEx=0 Then
 Begin
 FSplit(PointListName,D,N,E);
 PointListName:=D+DirInfo.Name;
 PntListName:=PointListName;
 Assign(PointList,PointListName);
 SetTextBuf(PointList,PointListBuffer);
 {$I-}
 Reset(PointList);
 {$I+}
 InOutResult:=IOResult;
 If InOutResult=0 Then
    Begin
     InitPointList:=True;
     _flgPointListOpened:=True;
     If (1=1) Then
       Begin
         LogWriteLn(GetExpandedString(_logLoadingListSegmentToMemory)+PointListName);
         CurrentOperation:=GetOperationString(_logLoadingListSegmentToMemory)+PointListName;
         ReadPointListToMemory(PointList)
       End
    Else
       Begin
         LogWriteLn(GetExpandedString(_logNotEnoughMemory+' load pointlist: '+PointListName));
         {$IFDEF SPLE}
           R.Assign(20,7,61,15);
           MessageBoxREct(R,'Not enough memory to load '+
                        'pointlist.'^M+
                        #3'Need at least '+IntToStr(TextFileSize(PointList) div 1024)+'kb',Nil,mfError+mfOkButton);
         {$ENDIF}
       End;
     Close(PointList);
     PntListName:='';
     If StrUp(GetVar(DeleteListAfterProcessTag.Tag,_varNONE))=Yes Then
        Begin
         {$I-}
         Erase(PointList);
         {$I+}
         InOutResult:=IOResult;
        If InOutResult<> 0 Then
           Begin
            LogWriteLn(GetExpandedString(_logCantDeleteFile+PointListName));
            {$IFNDEF SPLE}
            LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
            {$ENDIF}
           End;
        End;
    End
 Else
    Begin
     InitPointList:=False;
    _flgPointListOpened:=False;
    LogWriteLn(GetExpandedString(_logCantOpenFile)+PointListName);
    {$IFNDEF SPLE}
    LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
    {$ENDIF}
    End;
 End;
 FindNextEx(DirInfo);
End;
 FindCloseEx(DirInfo);
End;


Procedure WritePointListHeader(Var F:Text);
Var
Header:Text;
HeaderName:String;
S:String;
InOutResult:Integer;
Begin
HeaderName:=FExpand(GetVar(_tplPntListHeader.Tag,_varNONE));
Assign(Header,HeaderName);
{$I-}
Reset(Header);
{$I+}
InOutResult:=IOResult;
If InOutResult<>0 Then
   Begin
    LogWriteLn(GetExpandedString(_logCantOpenFile)+HeaderName);
    {$IFNDEF SPLE}
    LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
    {$ENDIF}
    Exit;
   End;
If MODE_DEBUG Then
  Begin
   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
      DebugLogWriteLn('#Loading template file: '+HeaderName)
   Else
      DebugLogWriteLn('#Обpаботка темплейта: '+HeaderName);
  End;
While Not Eof(Header) Do
  Begin
   Readln(Header,S);
   Case ExpandString(S) of
        NULL:WriteLn(F,S);
        {$IFNDEF SPLE}
        EXECUTE_SCRIPT:
                 If Load_Script(S) Then
                   Begin
                    Exec_Script;
                    Done_Script;
                   End;
        {$ENDIF}
       End;
  End;
Close(Header);
End;

Procedure WritePointListFooter(Var F:Text);
Var
Footer:Text;
FooterName:String;
S:String;
InOutResult:Integer;
Begin
FooterName:=FExpand(GetVar(_tplPntListFooter.Tag,_varNONE));
Assign(Footer,FooterName);
{$I-}
Reset(Footer);
{$I+}
InOutResult:=IOResult;
If InOutResult<>0 Then
   Begin
    LogWriteLn(GetExpandedString(_logCantOpenFile)+FooterName);
    {$IFNDEF SPLE}
    LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
    {$ENDIF}
    Exit;
   End;
If MODE_DEBUG Then
  Begin
   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
      DebugLogWriteLn('#Loading template file: '+FooterName)
   Else
      DebugLogWriteLn('#Обpаботка темплейта: '+FooterName);
  End;

While Not Eof(Footer) Do
  Begin
   Readln(Footer,S);
   Case ExpandString(S) of
        NULL:WriteLn(F,S);
        INCLUDE_FILE:;
        {$IFNDEF SPLE}
        EXECUTE_SCRIPT:
                 If Load_Script(S) Then
                   Begin
                    Exec_Script;
                    Done_Script;
                   End;
        {$ENDIF}
       End;
  End;
Close(Footer);
End;





Procedure WritePointListToDisk;
Const
TmpPointListName:String='$tmplst$.$$$';

Var
TmpPointList:Text;
DestPointList:Text;
DestPointListName:String;
Count1,Count2:Integer;
BossRec:PBossRecord;
Begin
{If BossRecArray^.Count<>0 Then}
   Begin
   TmpPointListName:=FExpand(TmpPointListName);
   Assign(TmpPointList,TmpPointListName);
   {$I-}
   SetTextBuf(TmpPointList,DestPointListBuffer);
   Rewrite(TmpPointList);
   {$I+}
   If IOResult<>0 Then
      Begin
       LogWriteLn(GetExpandedString(_logCantOpenFile)+TmpPointListName);
       Exit;
      End;
   WritePointListHeader(TmpPointList);
    For Count1:=0 To Pred(BossRecArray^.Count) Do
        Begin
        BossRec:=BossRecArray^.At(Count1);
        If BossRec^.PPoints^.Count>0 Then
           Begin
            If StrUp(GetVar(CommentsBeforeBossTag.Tag,_varNONE))=Yes Then
               Begin
                For Count2:=0 To Pred(BossRec^.PComments^.Count) Do
                  Begin
                   WriteLn(TmpPointList,PString(BossRec^.PComments^.At(Count2))^);
                  End;
                WriteLn(TmpPointList,BossRec^.PBossString^);
               End
            Else
               Begin
                WriteLn(TmpPointList,BossRec^.PBossString^);
                For Count2:=0 To Pred(BossRec^.PComments^.Count) Do
                  Begin
                   WriteLn(TmpPointList,PString(BossRec^.PComments^.At(Count2))^);
                  End;
               End;
            For Count2:=0 To Pred(BossRec^.PPoints^.Count) Do
              Begin
               WriteLn(TmpPointList,PString(BossRec^.PPoints^.At(Count2))^);
              End;
            If StrUp(GetVar(AddSemicolonAfterEachBossTag.Tag,_varNONE))=Yes Then
               WriteLn(TmpPointList,';');
           End
          Else
           Begin
              LogWriteLn(GetExpandedString(_logBossWithoutPoints)+
                         Copy(BossRec^.PBossString^,Pos(',',BossRec^.PBossString^)+1,255));
           End;
        End;
   WritePointListFooter(TmpPointList);
   DestPointListName:=GetVar(DestPointListNameTag.Tag,_varNONE);
   If DestPointListName<>'' Then
      Begin
       DestPointListName:=FExpand(DestPointListName);
       Assign(DestPointList,DestPointListName);
       {$I-}
       Reset(DestPointList);
       {$I+}
       If IOResult=0 Then
          Begin
            {$I-}
            Close(DestPointList);
            Erase(DestPointList);
            {$I+}
            If IOResult<>0 Then;
          End;
{       Rename(TmpPointList,DestPointListName);}
       {$I-}
        Close(TmpPointList);
       {$I+}
       If IOResult<>0 Then;
       If FileCopy(TmpPointListName,DestPointListName,$FFFF,True,False)<> 0{IOResult<>0} Then
          Begin
{           LogWriteLn(GetExpandedString(_logCantOpenFile)+DestPointListName);}
           {$IFNDEF SPLE}
{           LogWriteDosError(DosError,GetExpandedString(_logDosError));}
           {$ENDIF}
{           Close(TmpPointList);}
           Exit;
          End;
{       Close(TmpPointList);}
      End;
   End;
End;

Function SearchForBoss(BossAddr:TAddress):Integer;
Var
Counter:Integer;
BossRec:PBossRecord;
BossForSearch:String;
Begin
SearchForBoss:=-1;
If BossRecArray^.Count<>0 Then
  Begin
  SetStringFromAddress(BossForSearch,BossAddr);
  For Counter:=0 To BossRecArray^.Count-1 do
     Begin
     BossRec:=BossRecArray^.At(Counter);
     If ((EBossTag+BossForSearch)=StrUp(BossRec^.PBossString^)) Then
        Begin
         SearchForBoss:=Counter;
         Exit;
        End;
     End;
  End
Else
  SearchForBoss:=-1;
End;

Function  DeleteBossByIndex(Index:Integer):Boolean;
Var
SearchResult:Integer;
Begin
DeleteBossByIndex:=True;
If Index=-1 Then
  Begin
   DeleteBossByIndex:=False;
   Exit;
  End;
 BossRecArray^.AtFree(Index);
 SearchResult:=SearchForBoss(BossAddress);
 BossFound:=SearchResult<>-1;
End;

Function  DeleteBossByAddress(Addr:TAddress):Boolean;
Var
Count:Word;
BossStr:String;
AddrInArray:TAddress;
SearchResult:Integer;
Begin
Count:=0;
DeleteBossByAddress:=False;
While (True) Do
 Begin
  If Count>=BossRecArray^.Count Then
     Break;
  BossStr:=(PBossRecord(BossRecArray^.At(Count))^.PBossString)^;
  SetAddressFromString(BossStr,AddrInArray);
  If IsAddressesEqual(Addr,AddrInArray) Then
     Begin
      BossRecArray^.AtFree(Count);
      DeleteBossByAddress:=True;
      SearchResult:=SearchForBoss(BossAddress);
      BossFound:=SearchResult<>-1;
      Break;
     End;
  Inc(Count);
 End;
End;






Function ProcessPoint(BossIndex:Integer;Point:String;Flag:Integer):Integer;
Var
BossRec:PBossRecord;
FPoint,SPoint:Word;
BeginPos,EndPos,Code:Word;
Counter:Integer;
TmpPoint:PString;
Begin
If Flag=_flgDeletePoint Then
   Begin
    If (BossRecArray^.Count) > BossIndex Then
        Begin
         BossRec:=BossRecArray^.At(BossIndex);
         If StrTrim(Point)='*' Then
            Begin
             If BossRec^.PPoints^.Count>0 Then
                Begin
                  If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                      LogWriteLn(GetExpandedString(_logDeletePoint)+' All')
                  Else
                      LogWriteLn(GetExpandedString(_logDeletePoint)+' Все');
                  Inc(DeletedPoints,BossRec^.PPoints^.Count);
                  Inc(DeletedBosses);
                  {$IFNDEF SPLE}
                  SetVar(DeletedPointsTag,IntToStr(DeletedPoints));
                  SetVar(DeletedBossesTag,IntToStr(DeletedBosses));
                  {$ENDIF}
                  BossRec^.PPoints^.FreeAll;
                  BossRecArray^.AtPut(BossIndex,BossRec);
                End;
             Exit;
            End;
         Val(Point,FPoint,Code);
         For Counter:=0 To Pred(BossRec^.PPoints^.Count) Do
           Begin
            TmpPoint:=BossRec^.PPoints^.At(Counter);
            BeginPos:=Pos(',',TmpPoint^);
            EndPos:=Pos(',',Copy(TmpPoint^,BeginPos+1,Length(TmpPoint^)));
            Val(Copy(TmpPoint^,BeginPos+1,EndPos-1),SPoint,Code);
            If FPoint=SPoint Then
               Begin
                LogWriteLn(GetExpandedString(_logDeletePoint)+' '+GetBossAddressByIndex(BossIndex)+'.'+IntToStr(FPoint));
                BossRec^.PPoints^.AtFree(Counter);
                Inc(DeletedPoints);
                {$IFNDEF SPLE}
                SetVar(DeletedPointsTag,IntToStr(DeletedPoints));
                {$ENDIF}
                BossRecArray^.AtPut(BossIndex,BossRec);
                Exit;
              End
           End;
         LogWriteLn(GetExpandedString(_logFalseDeletePoint)+' '+GetBossAddressByIndex(BossIndex)+'.'+IntToStr(FPoint));
         Inc(FalseDeletedPoints);
         {$IFNDEF SPLE}
         SetVar(FalseDeletedpointsTag,IntToStr(FalseDeletedPoints));
         {$ENDIF}
         Exit;
        End;
   End
Else
 Begin
  If (BossRecArray^.Count) > BossIndex Then
     Begin
      BossRec:=BossRecArray^.At(BossIndex);
      Point[1]:=UpCase(Point[1]);
      Point[2]:=DownCase(Point[2]);
      Point[3]:=DownCase(Point[3]);
      Point[4]:=DownCase(Point[4]);
      Point[5]:=DownCase(Point[5]);
{      Delete(Point,1,Pos(',',Point));
      Insert('Point,',Point,1);}
      BeginPos:=Pos(',',Point);
      EndPos:=Pos(',',Copy(Point,BeginPos+1,Length(Point)));
      Val(Copy(Point,BeginPos+1,EndPos-1),FPoint,Code);
     For Counter:=0 To BossRec^.PPoints^.Count-1 Do
        Begin
         TmpPoint:=BossRec^.PPoints^.At(Counter);
         BeginPos:=Pos(',',TmpPoint^);
         EndPos:=Pos(',',Copy(TmpPoint^,BeginPos+1,Length(TmpPoint^)));
         Val(Copy(TmpPoint^,BeginPos+1,EndPos-1),SPoint,Code);
        If FPoint=SPoint Then
           Begin
            If (StrUp(Point)<>StrUp(TmpPoint^)) Then
               Begin
                BossRec^.PPoints^.AtPut(Counter,MCommon.NewStr(Point));
                LogWriteLn(GetExpandedString(_logChangeDataOfPoint)+' '+GetBossAddressByIndex(BossIndex)+'.'+IntToStr(FPoint));
                Inc(ChangedPoints);
                {$IFNDEF SPLE}
                SetVar(ChangedPointsTag,IntToStr(ChangedPoints));
                {$ENDIF}
                BossRecArray^.AtPut(BossIndex,BossRec);
                Exit;
               End
           Else
            If (StrUp(Point)=StrUp(TmpPoint^)) Then
               Begin
                LogWriteLn(GetExpandedString(_logFalseChangeDataOfPoint)+' '+
                           GetBossAddressByIndex(BossIndex)+'.'+IntToStr(FPoint));
                Inc(FalseChangedPoints);
                {$IFNDEF SPLE}
                SetVar(FalseChangedPointsTag,IntToStr(FalseChangedPoints));
                {$ENDIF}
                Exit;
               End;
           End;
        End;
        BossRec^.PPoints^.Insert(MCommon.NewStr(Point));
        LogWriteLn(GetExpandedString(_logAddNewPoint)+' '+GetBossAddressByIndex(BossIndex)+'.'+IntToStr(FPoint));
        Inc(AddedPoints);
        {$IFNDEF SPLE}
        SetVar(AddedPointsTag,IntToStr(AddedPoints));
        {$ENDIF}
        BossRecArray^.AtPut(BossIndex,BossRec);
     End
  Else
    ProcessPoint:=-1;
 End;
End;

Function  ReplaceBossComments(BossIndex:Integer;NewComments:PCommentsCollection):Boolean;
Var
Count:Integer;
Begin
If (BossIndex>=0) and (BossIndex<BossRecArray^.Count) Then
   Begin
    With PBossRecord(BossRecArray^.At(BossIndex))^ Do
      Begin
       PComments^.FreeAll;
       For Count:=0 To Pred(NewComments^.Count) Do
            PComments^.Insert(MCommon.NewStr(PString(NewComments^.At(Count))^));
      End;
   End;
End;

Function GetBossAddressByIndex(Index:Integer):String;
Var
S:String;
Begin
S:='';
If (Index>=0) and (Index<BossRecArray^.Count) Then
   Begin
    S:=PBossRecord(BossRecArray^.At(Index))^.PBossString^;
    Delete(S,1,5);
   End;
GetBossAddressByIndex:=S;
End;


Begin
 Validat:=Nil;
 Validator:=Nil;
 BossWithSegmentErrorsArray:=Nil;
 PntListName:='';
End.
