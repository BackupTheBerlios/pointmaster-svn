UNIT Report;

INTERFACE
Uses
Use32,
StrUnit,Incl,FidoMsg,Address,PointLst,Objects,Parser,Logger,
     Dos,MCommon,Statist,Script,PntL_Obj;


Procedure CreateReport(ToAddr,FromAddr:TAddress;
                       ToName,FromName:String;Flag:Word;BossIndex:Integer;_tplName,DefaultSubj:String;ForWho:Word);


IMPLEMENTATION


Procedure CreateReport(ToAddr,FromAddr:TAddress;
                       ToName,FromName:String;Flag:Word;BossIndex:Integer;_tplName,DefaultSubj:String;ForWho:Word);
Var
Subj,Origin,TearLine:String;
BossRec:PBossRecord;
PStr:PString;
Counter,SubCounter:Integer;
TemplateBody:PTemplateBody;
ReadedStr:String;
Tpl:Text;
ForWhoString:String;
InOutResult:Integer;
Begin
If DefaultSubj='' Then
   SetVar(SubjTag,'Answer for you')
 Else
   SetVar(SubjTag,DefaultSubj);
SetVar(TearLineStrTag,'PointMaster');
SetVar(OriginStrTag,'Default origin');
ForWhoString:='';
_tplName:=FExpand(_tplName);
Assign(Tpl,_tplName);
{$I-}
Reset(Tpl);
{$I+}
InOutResult:=IOResult;
If InOutResult<>0 Then
   Begin
    LogWriteLn(GetExpandedString(_logCantOpenTpl)+_tplName);
    LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('!Aborting creating report')
    Else
       LogWriteLn('!Отмена создания pепоpта');
    Exit;
   End;
TemplateBody:=New(PTemplateBody,Init(15,5));
TemplateBody^.Duplicates:=True;
If MODE_DEBUG Then
  Begin
   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
     DebugLogWriteLn('#Loading template file: '+_tplName)
   Else
     DebugLogWriteLn('#Обpаботка темплейта: '+_tplName)
  End;
If MsgFromGate Then
  Begin
   TemplateBody^.AtInsert(TemplateBody^.Count,MCommon.NewStr('To: '+ToEmailName));
  End;
While Not Eof(Tpl) Do
  Begin
   ReadLn(Tpl,ReadedStr);
   If Copy(PadLeft(ReadedStr),1,1)<>';' Then
     Begin
      Case ExpandString(ReadedStr) of
            NULL:
                Begin
                  If ReadedStr='' Then
                     ReadedStr:=' ';
                  TemplateBody^.AtInsert(TemplateBody^.Count,MCommon.NewStr(ReadedStr));
                End;
INCLUDE_LISTERRORS:
                Begin
                 If PSegmentErrorsMap<>Nil Then
                  Begin
                   For Counter:=0 To Pred({ErrorsInPointList^}PSegmentErrorsMap^.Count) Do
                      Begin
                       TemplateBody^.AtInsert(TemplateBody^.Count,MCommon.NewStr(PString(PSegmentErrorsMap^.At(Counter))^));
                      End;
                  End;
                End;
INCLUDE_PERSONALLISTERRORS:
                Begin
                 If (PersonalErrors<>Nil) And (PBossWithSegmentErrors(PersonalErrors)^.PErrorsMap^.Count>0) Then
                     Begin
                      For Counter:=0 To Pred(PBossWithSegmentErrors(PersonalErrors)^.PErrorsMap^.Count) Do
                         Begin
                          TemplateBody^.AtInsert(TemplateBody^.Count,MCommon.NewStr(
                                               PString(PBossWithSegmentErrors(PersonalErrors)^.PErrorsMap^.At(Counter))^));
                         End;
                     End;
                End;
INCLUDE_MESSAGEERRORS:
                Begin
                 If PMessageErrorsMap<>Nil Then
                  Begin
                   For Counter:=0 To Pred({ErrorsInMessage^}PMessageErrorsMap^.Count) Do
                      Begin
                       TemplateBody^.AtInsert(TemplateBody^.Count,MCommon.NewStr(PString(PMessageErrorsMap^.At(Counter))^));
                      End;
                  End;
                End;
INCLUDE_STATISTIC:
                Begin
                 GetBossStatistic(TemplateBody,ToAddr);
                End;
   EXECUTE_SCRIPT:
                Begin
                 If Load_Script(ReadedStr) Then
                   Begin
                    Exec_Script;
                    Done_Script;
                   End
                End;
INCLUDE_MESSAGEBODY:
                Begin
                 For Counter:=0 To Pred(MessageBody^.Count) Do
                  Begin
                   PStr:=MessageBody^.At(Counter);
                   SubCounter:=Pos(#01,PStr^);
                   While (SubCounter>0) Do
                    Begin
                     Delete(PStr^,SubCounter,1);
                     Insert('@',PStr^,SubCounter);
                     SubCounter:=Pos(#01,PStr^);
                    End;

                   SubCounter:=Pos(#00,PStr^);
                   While (SubCounter>0) Do
                    Begin
                     Delete(PStr^,SubCounter,1);
                     Insert(' ',PStr^,SubCounter);
                     SubCounter:=Pos(#00,PStr^);
                    End;

                   SubCounter:=Pos(TearLineTag,PStr^);
                   While (SubCounter>0) Do
                    Begin
                     Delete(PStr^,SubCounter+1,1);
                     Insert('+',PStr^,SubCounter+1);
                     SubCounter:=Pos(TearLineTag,PStr^);
                    End;

                   SubCounter:=Pos(OriginTag,PStr^);
                   While (SubCounter>0) Do
                    Begin
                     Delete(PStr^,SubCounter,1);
                     Insert('#',PStr^,SubCounter);
                     SubCounter:=Pos(OriginTag,PStr^);
                    End;

                   TemplateBody^.AtInsert(TemplateBody^.Count,MCommon.NewStr(PStr^));
                  End;
                End;
 INCLUDE_SEGMENT:
                Begin
                 BossRec:=BossRecArray^.At(BossIndex);
                 For Counter:=0 To Pred(BossRec^.PComments^.Count) Do
                  Begin
                   TemplateBody^.AtInsert(TemplateBody^.Count,MCommon.NewStr(
                                       PString(BossRec^.PComments^.At(Counter))^));
                  End;
                 TemplateBody^.AtInsert(TemplateBody^.Count,MCommon.NewStr(BossRec^.PBossString^));
                 For Counter:=0 To Pred(BossRec^.PPoints^.Count) Do
                  Begin
                   TemplateBody^.AtInsert(TemplateBody^.Count,MCommon.NewStr(
                                       PString(BossRec^.PPoints^.At(Counter))^));
                  End;
                End;
           End;
     End;
  End;
Close(Tpl);

Subj:=GetVar(SubjTag.Tag,_varNONE);
TearLine:=TearLineTag+GetVar(TearLineStrTag.Tag,_varNONE);
Origin:=OriginTag+GetVar(OriginStrTag.Tag,_varNONE)+' ('+
        GetStringFromAddress(FromAddr)+')';
If IsCreateMessage(GetVar(NetMailPathTag.Tag,_varNONE),ToAddr,FromAddr,ToName,FromName,
             Subj,GetAttributesFromString(GetVar(MsgAttributesTag.Tag,_varNONE))) Then
   Begin
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
     Begin
      Case ForWho Of
       _whoBOSS:ForWhoString:=' (Boss)';
       _whoSYSOP:ForWhoString:=' (SysOp)';
       _whoCantChangeAnotherBoss:ForWhoString:=' (Not allowed to change data of another Boss)';
       _whoNotAllowedToPoint:ForWhoString:=' (Not allowed for points)';
       _whoPasswordMismatch:ForWhoString:=' (Password mismatch)';
       _whoInBounceList:ForWhoString:=' (In bounce-list)';
       _whoInExcludeList:ForWhoString:=' (In exclude-list)';
      End;
     End
    Else
     Begin
      Case ForWho Of
       _whoBOSS:ForWhoString:=' (Босс)';
       _whoSYSOP:ForWhoString:=' (СисОп)';
       _whoCantChangeAnotherBoss:ForWhoString:=' (Не разрешено изменять данные другого Босса)';
       _whoNotAllowedToPoint:ForWhoString:=' (Не разрешено поинтам)';
       _whoPasswordMismatch:ForWhoString:=' (Несовпадение пароля)';
       _whoInBounceList:ForWhoString:=' (В bounce-списке)';
       _whoInExcludeList:ForWhoString:=' (В exclude-списке)';
       End;
     End;
   Case Flag Of
   _repAllDone:
              Begin
               CurrentOperation:=GetOperationString(_logCreatingAllDoneReport)+
                                 ' '+GetStringWithPointFromAddress(ToAddr)+ForWhoString;
               LogWriteLn(GetExpandedString(_logCreatingAllDoneReport)+' '+GetStringWithPointFromAddress(ToAddr)+ForWhoString);
              End;
   _repCantChangeAnotherBoss,
   _repNotAllowForPoint,
   _repPasswordMismatch,
   _repInBounceList,
   _repInExcludeList:
                       Begin
                        CurrentOperation:=GetOperationString(_logCreatingFalseReport)+
                                          ' '+GetStringWithPointFromAddress(ToAddr)+ForWhoString;
                        LogWriteLn(GetExpandedString(_logCreatingFalseReport)+' '+
                                   GetStringWithPointFromAddress(ToAddr)+ForWhoString);
                       End;
   _repSegmentRequest,
   _repHelpRequest,
   _repStatisticRequest:
                        Begin
                          CurrentOperation:=GetOperationString(_logCreatingRequestReport)+
                                                            ' '+GetStringWithPointFromAddress(ToAddr)+ForWhoString;
                          LogWriteLn(GetExpandedString(_logCreatingRequestReport)+' '+
                                     GetStringWithPointFromAddress(ToAddr)+ForWhoString);
                        End;
   _repErrorsInMessage:
                       Begin
                          CurrentOperation:=GetOperationString(_logCreatingErrorsInMessageReport)+
                                                            ' '+GetStringWithPointFromAddress(ToAddr)+ForWhoString;
                          LogWriteLn(GetExpandedString(_logCreatingErrorsInMessageReport)+' '+
                                     GetStringWithPointFromAddress(ToAddr)+ForWhoString);
                       End;
   _repErrorsInPointList,
   _repErrorsInSegment:
                       Begin
                          CurrentOperation:=GetOperationString(_logCreatingErrorsInSegmentReport)+
                                                            ' '+GetStringWithPointFromAddress(ToAddr)+ForWhoString;
                          LogWriteLn(GetExpandedString(_logCreatingErrorsInSegmentReport)+' '+
                                     GetStringWithPointFromAddress(ToAddr)+ForWhoString);
                       End;
     End;
    For SubCounter:=0 To Pred(TemplateBody^.Count) Do
      Begin
       WriteToMessage(PString(TemplateBody^.At(SubCounter))^);
      End;
    WriteToMessage(#10);
    WriteToMessage(TearLine);
    WriteToMessage(' '+Origin);
    If Flag<>_repInReRouteList Then
      Begin
       CloseMessage;
      End;
    {.I+}
    If TemplateBody<>Nil Then
       Dispose(TemplateBody,Done);
   End
 Else
   Begin
    LogWriteLn(GetExpandedString(_logCantCreateMessage));
   End;
End;



Begin
{MSG_PID:=PntMasterVersion;
SetVar(NetMailPathTag,'C:\FIDO\MAIL\MAILBOX\PNTMAST\',_varNONE);}
End.
