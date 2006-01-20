{$IFDEF VIRTUALPASCAL}
  {$B-,D+,H-,I+,J+,P-,Q-,R-,T-,V+,W-,X+,Z-}
  {&AlignCode+,AlignData+,AlignRec-,Asm-,Cdecl-,Comments-,Delphi+,Frame+,G3+}
  {&LocInfo+,Open32-,Optimise+,OrgName-,SmartLink+,Speed+,Use32-,ZD-}
  {$M 64000}
{$ELSE}
  {$A+,B-,D+,E-,F+,G+,I+,L+,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y+}
  {$M 64000,1024,655360}
{$ENDIF}

Program Point_Master;
{$IFDEF VIRTUALPASCAL}
  {$PMType VIO}
{$ENDIF}




{$I VERSION.INC}

Uses App,Objects,Views,Dialogs,Drivers,Menus,

{ ********* begin skMHLB *********}
{skMHL, skMHLjam, skMHLmsg, skComnTV, skCommon,skOpen,}
{ ********* end skMHLB *********}

{$IFNDEF VIRTUALPASCAL}
  {$IFDEF DPMI}
    PExtend,
  {$ELSE}
    Extend,
  {$ENDIF}
{$ELSE}
  Use32,
  SysUtils,
{$ENDIF}

{$IFDEF FPC}
  Commands,
{$ENDIF}

PM_Obj,Dos,Face,StrUnit,FidoMsg,Incl,Address,PointLst,Report,Logger,Strings,
     Statist,Parser,Config,Crt,Memory,MCommon,Language,Check,Script,
     Os_Type,FileIO,Dates,Segments,PntL_Obj,
     {** must be latest for correct error detection **}
     Err_Func;

Type
  TPointMaster=Object(TMyApplication)
   MainInfoWindow:PInfoWindow;
   MainLogWindow:PLogWindow;
     Constructor Init;
     Procedure Run;virtual;
     Destructor Done;virtual;
     Procedure HandleEvent(var Event: TEvent); virtual;
     Procedure InitStatusLine;Virtual;
{     Procedure InitMenuBar;Virtual;}
{     Procedure SetInfoWindowRect(Var R:Trect);
     Procedure SetLogWindowRect(Var R:TRect);}
End;

{Var}
{ C_LikeMasterName:Z36;}
{ DirInfo:SearchRec;}
{ CommentsInMessage:PCommentsCollection;}

{ Msg:File;
 MsgRec:TFidoMsgHeader;}


Procedure ForEachMasterName(Pnt,MsgRecord:Pointer);far;
Var
 AsciizMasterName:Z36;
Begin
 If MessageForPntMaster Then
    Exit;
 If StrTrim(PString(Pnt)^)='' Then
    Exit;
 FillStr(StrUp(PString(Pnt)^),AsciizMasterName,36);
 If StrUp(AsciizMasterName)=StrUp(PFidoMsgHeader(MsgRecord)^._To) Then
    MessageForPntMaster:=True;
End;

Function MsgForPntMaster(MsgRecord:TFidoMsgHeader):Boolean;
Begin
 MessageForPntMaster:=False;
 ForEachVarWithData(MasterNameTag.Tag,Addr(MsgRecord),ForEachMasterName);
 MsgForPntMaster:=MessageForPntMaster=True;
 If (MsgRecord._DestNet<>PntMasterAddress.Net) or
    (MsgRecord._DestNode<>PntMasterAddress.Node) Then
    MsgForPntMaster:=False;
End;

Function SecCheckMsgForPntMaster(MsgRecord:TFidoMsgHeader):Boolean;
Begin
 SecCheckMsgForPntMaster:=True;
 If (MsgRecord._DestZone<>PntMasterAddress.Zone) or
    (MsgRecord._DestNet<>PntMasterAddress.Net) or
    (MsgRecord._DestNode<>PntMasterAddress.Node) or
    (MsgRecord._DestPoint<>PntMasterAddress.Point) Then
    SecCheckMsgForPntMaster:=False;
End;

Function MsgFromPoint(MsgRecord:TFidoMsgHeader):Boolean;
Begin
MsgFromPoint:=BossAddress.Point<>0;
If BossAddress.Point<>0 Then
   Begin
     SetVar(FromAddressTag,GetStringWithPointFromAddress(BossAddress));
     LogWriteLn(GetExpandedString(_logMessageFromPoint));
     CreateReport(BossAddress,PntMasterAddress,
                 MsgRecord._From,GetVar(MasterNameTag.Tag,_varNONE),_repNotAllowForPoint,
                 -1,GetVar(_tplNotAllowForPoint.Tag,_varNONE),'',_whoNotAllowedToPoint);
     Exit;
   End;
End;

Procedure ReportPasswordMismatch(MsgRecord:TFidoMsgHeader);
Begin
LogWriteLn(GetExpandedString(_logPasswordMismatch));
CreateReport(BossAddress,PntMasterAddress,
             MsgRecord._From,GetVar(MasterNameTag.Tag,_varNONE),_repPasswordMisMatch,
             -1,GetVar(_tplBadPassword.Tag,_varNONE),'',_whoPasswordMismatch);
End;

Procedure ReportInBounceList(MsgRecord:TFidoMsgHeader);
Begin
LogWriteLn(GetExpandedString(_logInBounceList));
CreateReport(BossAddress,PntMasterAddress,
             MsgRecord._From,GetVar(MasterNameTag.Tag,_varNONE),_repInBounceList,
             -1,GetVar(_tplInBounceList.Tag,_varNONE),'',_whoInBounceList);
End;

Procedure ReportInExcludeList(MsgRecord:TFidoMsgHeader);
Begin
LogWriteLn(GetExpandedString(_logInExcludeList)+GetStringFromAddress(ExcludeAddr));
CreateReport(BossAddress,PntMasterAddress,
             MsgRecord._From,GetVar(MasterNameTag.Tag,_varNONE),_repInExcludeList,
             -1,GetVar(_tplInExcludeList.Tag,_varNONE),'',_whoInExcludeList);
End;

Procedure ForEachAutoUpdateSegment(Pnt:Pointer);
Var
  Mask:        String;
Begin
  Mask:=PString(Pnt)^;
  ExpandString(Mask);
  Mask:=StrTrim(Mask);
  If Mask<>'' Then
          ConditionalAutoCreateSegmentsFromMask(Mask);
 End;

Procedure ForEachAutoCreateSegment(Pnt:Pointer);Far;
Var
   Mask:        String;
Begin
     Mask:=PString(Pnt)^;
     ExpandString(Mask);
     Mask:=StrTrim(Mask);
     If Mask<>'' Then
        ConditionalAutoCreateSegmentsFromMask(Mask);
End;

Procedure ForEachForceAutoCreateSegment(Pnt:Pointer);Far;
Var
   Mask:        String;
Begin
     Mask:=PString(Pnt)^;
     ExpandString(Mask);
     Mask:=StrTrim(Mask);
     If Mask<>'' Then
        ForcedAutoCreateSegmentsFromMask(Mask);
End;

Procedure ForEachAutoUpdate(Pnt:Pointer);Far;
Var
{PStr:PString absolute Pnt;}
PStr:String;
Begin
If _AutoUpdateFound Then
   Exit;
PStr:=PString(Pnt)^;
ExpandString(PStr);
If IsAddressMatch(StrTrim(PStr),BossAddress) Then
   Begin
        _IsInAutoUpdateList:=True;
        _AutoUpdateFound:=True;
   End;
End;




Procedure ForEachPassword(Pnt:Pointer);Far;
Var
{PStr:PString absolute Pnt;}
PStr:String;
Mask,Password:String;
BeginPos:Word;
Begin
If _PasswordFound Then
   Exit;
PStr:=PString(Pnt)^;
ExpandString(PStr);
if PStr='' Then
   Exit;
BeginPos:=Pos(' ',StrTrim(PStr));
If BeginPos>0 Then
   Begin
    Mask:=Copy(PStr,1,Pos(' ',StrTrim(PStr))-1);
    Mask:=StrTrim(Mask);
    Password:=Copy(PStr,Pos(' ',StrTrim(PStr)),Length(StrTrim(PStr)));
    Password:=StrTrim(Password);
    SetVar(MustBePasswordTag,Password);
    If IsAddressMatch(Mask,BossAddress) Then
       Begin
        If StrUp(Password)<>StrUp(GetVar(FromPasswordTag.Tag,_varNONE)) Then
           _IsPasswordValid:=False;
           _PasswordFound:=True;
       End;
   End;
End;

Procedure ForEachIgnore(Pnt,MsgRecordPtr:Pointer);Far;
Var
{PStr:PString absolutes Pnt;}
PStr:String;
Begin
If _IgnoreFound Then
   Exit;
PStr:=PString(Pnt)^;
ExpandString(PStr);
If PStr='' Then
   Exit;
If CharsMaskMatch(StrUp(PStr),StrUp(TruncStr(PFidoMsgHeader(MsgRecordPtr)^._From))) Then
  Begin
   _IgnoreFound:=True;
   _IsInIgnoreList:=True;
   End;
End;

Procedure ForEachReRoute(Pnt:Pointer);Far;
Var
{PStr:PString absolute Pnt;}
PStr:String;
Mask,RouteAddress:String;
BeginPos:Word;
Begin
If _ReRouteFound Then
   Exit;
PStr:=PString(Pnt)^;
ExpandString(PStr);
If PStr='' Then
   Exit;
BeginPos:=Pos(' ',StrTrim(PStr));
If BeginPos>0 Then
   Begin
    Mask:=Copy(PStr,1,Pos(' ',StrTrim(PStr))-1);
    Mask:=StrTrim(Mask);
    RouteAddress:=Copy(PStr,Pos(' ',StrTrim(PStr)),Length(StrTrim(PStr)));
    RouteAddress:=StrTrim(RouteAddress);
    If IsAddressMatch(Mask,BossAddress) Then
       Begin
           _ReRouteFound:=True;
           SetAddressFromString(RouteAddress,ReRouteAddress);
           _IsInReRouteList:=True;
       End;
   End;
End;


Procedure ForEachBounce(Pnt:Pointer);Far;
Var
{PStr:PString absolute Pnt;}
PStr:String;
IsReverse:Boolean;
Begin
If _BounceFound Then
   Exit;
IsReverse:=False;
PStr:=PString(Pnt)^;
ExpandString(PStr);
If PStr='' Then
   Exit;
If Copy(PadLeft(PStr),1,1)='!' Then
   Begin
    Delete(PStr,Pos('!',PStr),1);
    IsReverse:=True;
   End;
If IsReverse Then
   Begin
    If Not (IsAddressMatch(StrTrim(PStr),BossAddress)) Then
      Begin
       _IsInBounceList:=True;
       _BounceFound:=True;
      End;
   End
Else
   Begin
    If IsAddressMatch(StrTrim(PStr),BossAddress) Then
      Begin
       _IsInBounceList:=True;
       _BounceFound:=True;
      End;
   End;
End;

Function IsPasswordValid(MsgRecord:TFidoMsgHeader):Boolean;
Begin
_IsPasswordValid:=True;
IsPasswordValid:=True;
_PasswordFound:=False;
{If StrUp(GetVar(UsePasswordsTag.Tag,_varNONE))=Yes Then}
   Begin
    ForEachVar(PasswordTag.Tag,ForEachPassword);
    If Not (_IsPasswordValid) Then
       Begin
        IsPasswordValid:=False;
        ReportPasswordMisMatch(MsgRecord);
       End;
   End;
End;

Function IsInReRouteList:Boolean;
Begin
IsInReRouteList:=False;
_IsInReRouteList:=False;
_ReRouteFound:=False;
{If StrUp(GetVar(UseReRouteTag.Tag,_varNONE))=Yes Then}
   Begin
    ForEachVar(ReRouteTag.Tag,ForEachReRoute);
    If _IsInReRouteList Then
       Begin
        IsInReRouteList:=True;
       End;
   End;
End;

Function IsInBounceList(MsgRecord:TFidoMsgHeader):Boolean;
Begin
_IsInBounceList:=False;
IsInBounceList:=False;
_BounceFound:=False;
{If StrUp(GetVar(UseBounceTag.Tag,_varNONE))=Yes Then}
   Begin
    ForEachVar(BounceTag.Tag,ForEachBounce);
    If _IsInBounceList Then
       Begin
        IsInBounceList:=True;
        ReportInBounceList(MsgRecord);
       End;
   End;
End;

Function IsInAutoUpdateList:Boolean;
Begin
 _IsInAutoUpdateList:=False;
 IsInAutoUpdateList:=False;
 _AutoUpdateFound:=False;
 ForEachVar(AutoUpdateSegmentTag.Tag,ForEachAutoUpdate);
 If _IsInAutoUpdateList Then
    Begin
         IsInAutoUpdateList:=True;
    End;
End;

Function IsInIgnoreList(MsgRecord:TFidoMsgHeader):Boolean;
Begin
_IsInIgnoreList:=False;
IsInIgnoreList:=False;
_IgnoreFound:=False;
{If StrUp(GetVar(UseBounceTag.Tag,_varNONE))=Yes Then}
   Begin
    ForEachVarWithData(IgnoreFromNameTag.Tag,Addr(MsgRecord),ForEachIgnore);
    If _IsInIgnoreList Then
       Begin
        IsInIgnoreList:=True;
{        ReportInBounceList;}
        LogWriteLn(GetExpandedString(_logMessageFromIgnoreName));
       End;
   End;
End;


Function BossFoundInPntList(Var BossIndex:Integer;BossString:String):Boolean;
Begin
BossIndex:=SearchForBoss(BossAddress);
BossFoundInPntList:=BossIndex<>-1;
If  (BossIndex=-1) and (BossString<>'')  Then
   Begin
     BossRecArray^.Insert(New(
                         PBossRecord,Init(
                         BossString,Nil,Nil)));
     BossIndex:=SearchForBoss(BossAddress);
     BossFoundInPntList:=BossIndex<>-1;
     If BossIndex<>-1 Then
        Begin
         AddedBosses:=AddedBosses+1;
         SetVar(AddedBossesTag,IntToStr(AddedBosses));
        End;
   End;
End;

Function ReportBossesNotEqual(Boss1,Boss2:TAddress;MsgRecord:TFidoMsgHeader):Boolean;
Begin
{Case (IsAddressesEqual(Boss1,Boss2)) Of
   False:
         Begin}
            ReportBossesNotEqual:=True;
            CreateReport(BossAddress,PntMasterAddress,
                        MsgRecord._From,GetVar(MasterNameTag.Tag,_varNONE),_repCantChangeAnotherBoss,
                        -1,GetVar(_tplCantChangeAnotherBoss.Tag,_varNONE),'',_whoCantChangeAnotherBoss);
            Exit;
{         End;
   True:BossesEqual:=True;
 End;}
End;

Procedure ReportWellDone(MsgRecord:TFidoMsgHeader);
Begin
CreateReport(BossAddress,PntMasterAddress,
             MsgRecord._From,GetVar(MasterNameTag.Tag,_varNONE),_repAllDone,
             -1,GetVar(_tplAllDone.Tag,_varNONE),'',_whoBoss);
End;

Procedure ReportErrorsInMessage(MsgRecord:TFidoMsgHeader);
Begin
If (PMessageErrorsMap<>Nil) And (PMessageErrorsMap^.Count>0) Then
   CreateReport(BossAddress,PntMasterAddress,
               MsgRecord._From,GetVar(MasterNameTag.Tag,_varNONE),_repErrorsInMessage,
               -1,GetVar(_tplErrorsInMessage.Tag,_varNONE),'',_whoBoss);

End;

Procedure ReportErrorsInPointList;
Const
_BOTH=1;
_SYSOP=2;
_BOSS=3;
Var
Counter:Integer;
NotifyMask:Byte;
Begin
If (PSegmentErrorsMap<>Nil) And (PSegmentErrorsMap^.Count>0)  Then
   CreateReport(SysOpAddress,PntMasterAddress,
               GetVar(SysOpNameTag.Tag,_varNONE),GetVar(MasterNameTag.Tag,_varNONE),
               _repErrorsInPointList,-1,GetVar(_tplErrorsInPointList.Tag,_varNONE),'',_whoSysOp);
If (BossWithSegmentErrorsArray<>Nil) And (BossWithSegmentErrorsArray^.Count>0) Then
   Begin
     NotifyMask:=0;
     If StrTrim(GetVar(NotifyOnErrorsTag.Tag,_varNONE))='' Then
         Begin
          Dispose(BossWithSegmentErrorsArray,Done);
          BossWithSegmentErrorsArray:=Nil;
          Exit;
         End
    Else
     If StrUp(GetVar(NotifyOnErrorsTag.Tag,_varNONE))=BothTag Then
         Begin
          NotifyMask:=_BOTH;
         End
    Else
     If StrUp(GetVar(NotifyOnErrorsTag.Tag,_varNONE))=BossTag Then
         Begin
          NotifyMask:=_BOSS;
         End
    Else
     If StrUp(GetVar(NotifyOnErrorsTag.Tag,_varNONE))=SysopTag Then
         Begin
          NotifyMask:=_SYSOP;
         End
    Else
         Begin
          Dispose(BossWithSegmentErrorsArray,Done);
          BossWithSegmentErrorsArray:=Nil;
          Exit;
         End;
     For Counter:=0 To Pred(BossWithSegmentErrorsArray^.Count) Do
         Begin
          PersonalErrors:=BossWithSegmentErrorsArray^.At(Counter);
          Case NotifyMask Of
             _BOTH:
                   Begin
                    CreateReport(SysOpAddress,PntMasterAddress,
                         GetVar(SysOpNameTag.Tag,_varNONE),GetVar(MasterNameTag.Tag,_varNONE),
                        _repErrorsInSegment,-1,GetVar(_tplErrorsInSegment.Tag,_varNONE),'',_whoSysOp);
                    CreateReport(PBossWithSegmentErrors(BossWithSegmentErrorsArray^.At(Counter))^.TBossAddress
                        ,PntMasterAddress,'SysOp',GetVar(MasterNameTag.Tag,_varNONE),
                        _repErrorsInSegment,-1,GetVar(_tplErrorsInSegment.Tag,_varNONE),'',_whoBoss);
                   End;
             _BOSS:
                   Begin
                    CreateReport(PBossWithSegmentErrors(BossWithSegmentErrorsArray^.At(Counter))^.TBossAddress
                        ,PntMasterAddress,'SysOp',GetVar(MasterNameTag.Tag,_varNONE),
                        _repErrorsInSegment,-1,GetVar(_tplErrorsInSegment.Tag,_varNONE),'',_whoBoss);
                   End;
             _SYSOP:
                   Begin
                    CreateReport(SysOpAddress,PntMasterAddress,
                         GetVar(SysOpNameTag.Tag,_varNONE),GetVar(MasterNameTag.Tag,_varNONE),
                        _repErrorsInSegment,-1,GetVar(_tplErrorsInSegment.Tag,_varNONE),'',_whoSysOp);
                   End;
           End;
         End;
     Dispose(BossWithSegmentErrorsArray,Done);
     BossWithSegmentErrorsArray:=Nil;
   End;
End;

Function ProcessSegmentRequest(BossIndex:Integer;MsgRecord:TFidoMsgHeader):Boolean;
Begin
SetVar(RequestTag,SegmentRequestTag.Tag);
LogWriteLn(GetExpandedString(_logFoundRequest));
CreateReport(BossAddress,PntMasterAddress,
             MsgRecord._From,GetVar(MasterNameTag.Tag,_varNONE),_repSegmentRequest,
             BossIndex,GetVar(_tplDoneSegRequest.Tag,_varNONE),'',_whoBoss);
End;

Function ProcessStatisticRequest(BossIndex:Integer;MsgRecord:TFidoMsgHeader):Boolean;
Begin
SetVar(RequestTag,StatisticRequestTag.Tag);
LogWriteLn(GetExpandedString(_logFoundRequest));
CreateReport(BossAddress,PntMasterAddress,
             MsgRecord._From,GetVar(MasterNameTag.Tag,_varNONE),_repStatisticRequest,
             BossIndex,GetVar(_tplStatisticRequest.Tag,_varNONE),'',_whoBoss);

End;



Function ProcessHelpRequest(BossIndex:Integer;MsgRecord:TFidoMsgHeader):Boolean;
Begin
SetVar(RequestTag,HelpRequestTag.Tag);
LogWriteLn(GetExpandedString(_logFoundRequest));
CreateReport(BossAddress,PntMasterAddress,
             MsgRecord._From,GetVar(MasterNameTag.Tag,_varNONE),_repHelpRequest,
             BossIndex,GetVar(_tplDoneHelpRequest.Tag,_varNONE),'',_whoBoss);
End;

Function ProcessFileAttach(MsgRecord:TFidoMsgHeader):Boolean;
Var
FileAttachPath:String;
Old:Byte;
Begin
 Old:=StringsToSkipAtBegin;
 StringsToSkipAtBegin:=0;
 If StrTrim(GetVar(FileAttachPathTag.Tag,_varNONE))<>'' Then
    Begin
     FileAttachPath:=GetVar(FileAttachPathTag.Tag,_varNONE);
     If FileAttachPath[Length(FileAttachPath)]<>'\' Then
        FileAttachPath:=FileAttachPath+'\';
     If Not IsFileExist(FileAttachPath+MsgRecord._Subj) Then
        LogWriteLn(GetExpandedString(_logCantOpenFile)+StrTrim(FileAttachPath+MsgRecord._Subj));
     InitPointList(FileAttachPath+MsgRecord._Subj);
    End
Else
    Begin
     If Not IsFileExist(MsgRecord._Subj) Then
        LogWriteLn(GetExpandedString(_logCantOpenFile)+StrTrim(MsgRecord._Subj));
     InitPointList(FExpand(MsgRecord._Subj));
    End;
 StringsToSkipAtBegin:=Old;
End;

Function ReRouteMessage(MsgRecord:TFidoMsgHeader):Boolean;
Begin
ReRouteMessage:=True;
If IsAddressesEqual(PntMasterAddress,ReRouteAddress) Then
   Begin
    LogWriteLn(GetExpandedString(_logTryToReRouteToOurSelf));
    ReRouteMessage:=False;
    Exit;
   End;
CurrentOperation:=GetOperationString(_logInReRouteList)+GetStringFromAddress(ReRouteAddress);
LogWriteLn(GetExpandedString(_logInReRouteList)+GetStringFromAddress(ReRouteAddress));
{MsgMaskToSet:=MsgRecord._Attr;}
CreateReport(ReRouteAddress,BossAddress,
             MsgRecord._To,MsgRecord._From,_repInReRouteList,
             -1,GetVar(_tplReRoute.Tag,_varNONE),MsgRecord._Subj,_whoNone);
WriteToMessage(#1'Re-routed by '+PntMasterVersion+' ('+
               GetStringFromAddress(PntMasterAddress)+') to '+
               GetStringFromAddress(ReRouteAddress));
CloseMessage;
End;


Function GetMsgBody(Var Msg:File;MsgRecord:TFidoMsgHeader):Boolean;
Var
S,S2:String;
Begin
While Not Eof(Msg) Do
  Begin
{   ReadMsgLn(Msg,S);}
   ReadLnFromMsg(Msg,S);
   ReadedBytes:=ReadedBytes+Length(S);
   {WritePerCent;}
{   ScreenHandler;}
   RefreshScreen;
   If S[1]=#01 Then
      Begin
{       FindKludge(S);}
        ExtractKludge(S,MsgRecord);
      End;
   If S[Length(S)]=GetVar(SplitCharTag.Tag,_varNONE) Then
      Begin
{       ReadMsgLn(Msg,S2);}
       ReadLnFromMsg(Msg,S2);
       StrTrim(S2);
       Delete(S,Length(S),1);
       S:=S+S2;
       If S[Length(S)]=GetVar(SplitCharTag.Tag,_varNONE) Then
         Begin
{           ReadMsgLn(Msg,S2);}
           ReadLnFromMsg(Msg,S2);
           StrTrim(S2);
           Delete(S,Length(S),1);
           S:=S+S2;
         End;
      End;
   If S='' Then
      S:=' ';
   MessageBody^.Insert(MCommon.NewStr(S));
  End;
End;

Procedure ForEachOnListUpdateScript(Pnt:Pointer);Far;
{Var
 ScriptName:PString Absolute Pnt;}
Begin
If StrTrim(PString(Pnt)^)<>'' Then
   If Load_Script(PString(Pnt)^) Then
     Begin
      Exec_Script;
      Done_Script;
     End;
End;

Procedure ForEachOnMessagesScript(Pnt:Pointer);Far;
{Var
 ScriptName:PString Absolute Pnt;}
Begin
If StrTrim(PString(Pnt)^)<>'' Then
   If Load_Script(PString(Pnt)^) Then
     Begin
      Exec_Script;
      Done_Script;
     End;
End;

Procedure ForEachPntList(Point:Pointer);Far;
Begin
 InitPointList(PString(Point)^);
End;


Function CheckMessage(Var Msg:File;MsgRecord:TFidoMsgHeader):Boolean;
Var
S,SS:String;
BossAddrInMsg:TAddress;
Count:Integer;
CommaPos:Byte;
CommentsInMessage:PCommentsCollection;
Begin
 CheckMessage:=True;
 CommentsInMessage:=Nil;
 BossFound:=False;
 GetMsgBody(Msg,MsgRecord);
 SetVar(FromAddressTag,GetStringFromAddress(BossAddress));
 If (Not SecCheckMsgForPntMaster(MsgRecord)) Then
     Begin
      CheckMessage:=False;
      LogWriteLn(GetExpandedString(_logMessageNotForMaster)+
                                 IntToStr(MsgRecord._DestZone)+':'+
                                 IntToStr(MsgRecord._DestNet)+'/'+
                                 IntToStr(MsgRecord._DestNode)+'.'+
                                 IntToStr(MsgRecord._DestPoint));
      Exit;
     End;
 If MsgFromPoint(MsgRecord) Then
    Begin
     CheckMessage:=False;
     Exit;
    End;
 If IsInBounceList(MsgRecord) Then
    Begin
     CheckMessage:=False;
     Exit;
    End;
 If IsInIgnoreList(MsgRecord) Then
    Begin
     CheckMessage:=False;
     Exit;
    End;
 If IsInReRouteList Then
    Begin
     ReRouteMessage(MsgRecord);
     CheckMessage:=False;
     Exit;
    End;
 If (Not IsPasswordValid(MsgRecord)) Then
    Begin
     CheckMessage:=False;
     Exit;
    End;
 If IsInExcludeList(GetStringFromAddress(BossAddress)) Then
  {потом это пеpенести ниже, после нахождения boostag -для той веpсии,
   где можно бyдет изменять дpyгих боссов}
    Begin
     CheckMessage:=False;
     ReportInExcludeList(MsgRecord);
     Exit;
    End;
 ForEachVar(OnEachMessageBeforeScriptTag.Tag,ForEachOnMessagesScript);
 If (Not _IsPointListInMemory) Then
    Begin
     ForEachVar(PointListNameTag.Tag,ForEachPntList);
     _IsPointListInMemory:=True;
    End;

{ If (Not MsgFromPoint) And (Not IsInBounceList) And (IsPasswordValid) Then}
    For Count:=0 To Pred(MessageBody^.Count) Do
     Begin
       S:=PString(MessageBody^.At(Count))^;
       S:=StrTrim(S);
       If Pos(BossTag,StrUp(Copy(S,1,7)))=1 Then
          Begin
           SS:=S;
           Delete(SS,1,Length(BossTag)+1);
           SetAddressFromString(SS,BossAddrInMsg);
           If Not (IsAddressesEqual(BossAddress,BossAddrInMsg)) Then
             Begin
              LogWriteLn(GetExpandedString(_logTryChangeAnotherBoss)+GetStringFromAddress(BossAddrInMsg));
              ReportBossesNotEqual(BossAddress,BossAddrInMsg,MsgRecord);
{              Exit;}
             End
           Else
             Begin
              BossFound:=BossFoundInPntList(CurrentBossIndex,S);
              LogWriteLn(GetExpandedString(_logBossAddress));
             End;
          End
      Else
       If (Pos(PointTag,StrUp(Copy(S,1,7)))=1) Then
          Begin
           DeleteSpacesInString(S);
           If (Not BossFound) Then
              Begin
                BossFound:=BossFoundInPntList(CurrentBossIndex,'');
                If CurrentBossIndex=-1 Then
                   Begin
                    BossFound:=BossFoundInPntList(CurrentBossIndex,
                               'Boss,'+GetStringFromAddress(BossAddress));
                   End;
              End;
           If CurrentBossIndex<>-1 Then
              Begin
               If StrUp(GetVar(UseValidatetag.Tag,_varNONE))=Yes Then
                  Begin
                   If IsValidPointString(GetStringFromAddress(BossAddress),S,PMessageErrorsMap) Then
                      ProcessPoint(CurrentBossIndex,S,_varNONE)
                   Else
                    Begin
                     Inc(ErrorPoints);
                     SetVar(ErrorPointsTag,IntToStr(ErrorPoints));
                    End;
                  End
              Else
                  ProcessPoint(CurrentBossIndex,S,_varNONE);
              End;
          End
      Else
       If Pos((GetVar(DeleteCharsTag.Tag,_varNONE)),S)=1 Then
          Begin
           If (Not BossFound) Then
             Begin
               BossFound:=BossFoundInPntList(CurrentBossIndex,'');
             End;
          If CurrentBossIndex<>-1 Then
             Begin
              Delete(S,1,Length(GetVar(DeleteCharsTag.Tag,_varNONE)));
              CommaPos:=Pos(',',S);
              If CommaPos>0 Then
                 Begin
                  While CommaPos>0 Do
                    Begin
                     ProcessPoint(CurrentBossIndex,
                          StrTrim(Copy(S,1,CommaPos-1)),_flgDeletePoint);
                     Delete(S,1,CommaPos);
                     CommaPos:=Pos(',',S);
                    End;
                  ProcessPoint(CurrentBossIndex,
                         StrTrim(S),_flgDeletePoint);
                 End
              Else
                 Begin
                   ProcessPoint(CurrentBossIndex,
                          StrTrim(S),_flgDeletePoint);
                 End;
             End
          End
      Else
       If Pos(SegmentRequestTag.Tag,StrUp(S))=1 Then
          Begin
           If (Not BossFound) Then
              Begin
                BossFound:=BossFoundInPntList(CurrentBossIndex,'');
              End;
           If CurrentBossIndex<>-1 Then
              ProcessSegmentRequest(CurrentBossIndex,MsgRecord);
          End
      Else
       If Pos(StatisticRequestTag.Tag,StrUp(S))=1 Then
          Begin
           If (Not BossFound) Then
              Begin
                BossFound:=BossFoundInPntList(CurrentBossIndex,'');
              End;
              ProcessStatisticRequest(CurrentBossIndex,MsgRecord);
          End
       Else
       If Pos(HelpRequestTag.Tag,StrUp(S))=1 Then
          Begin
           If (Not BossFound) Then
              Begin
                BossFound:=BossFoundInPntList(CurrentBossIndex,'');
              End;
              ProcessHelpRequest(CurrentBossIndex,MsgRecord);
          End
       Else
       If Pos(GetVar(AddCommentCharsTag.Tag,_varNONE),StrUp(S))=1 Then
          Begin
           If (Not BossFound) Then
              Begin
                BossFound:=BossFoundInPntList(CurrentBossIndex,'');
              End;
              If CurrentBossIndex<>-1 Then
                 Begin
                  If CommentsInMessage=Nil Then
                     CommentsInMessage:=New(PCommentsCollection,Init(5,1));
                  Delete(S,1,1);
                  CommentsInMessage^.Insert(MCommon.NewStr(S));
                 End;
          End
       Else
       If Pos(ScriptTag,StrUp(S))=1 Then
          Begin
           If _IsMsgWithMainPassword Then
              Begin
               ExpandString(S);
               If Load_Script(S) Then
                 Begin
                  Exec_Script;
                  Done_Script;
                 End;
              End
           Else
              LogWriteLn(GetExpandedString(
                        _logTryToExecProtectedCommand)+S);
          End
       Else
       If Pos(DefineTag,StrUp(S))=1 Then
          Begin
           If _IsMsgWithMainPassword Then
              Begin
               ExpandString(S);
              End
           Else
              LogWriteLn(GetExpandedString(
                        _logTryToExecProtectedCommand)+S);
          End
       Else
       If Pos(IncludeTag,StrUp(S))=1 Then
          Begin
           If _IsMsgWithMainPassword Then
              Begin
               ExpandString(S);
               ReadConfig(S);
              End
           Else
              LogWriteLn(GetExpandedString(
                        _logTryToExecProtectedCommand)+S);

          End;
     End;
   {Else
     Begin
      Exit;
     End;}
 If CommentsInMessage<>Nil Then
    Begin
     LogWriteLn(GetExpandedString(_logReplacingBossComments)+
                                GetBossAddressByIndex(CurrentBossIndex));
     ReplaceBossComments(CurrentBossIndex,CommentsInMessage);
     Dispose(CommentsInMessage);
     CommentsInMessage:=Nil;
    End;
 ReportErrorsInMessage(MsgRecord);
 ReportWellDone(MsgRecord);
 WriteStatistic(MsgRecord._From,BossAddress);
 LogWriteLn(GetExpandedString(_logAddedBosses));
 LogWriteLn(GetExpandedString(_logDeletedBosses));
 LogWriteLn(GetExpandedString(_logDuplicateBosses));
 LogWriteLn(GetExpandedString(_logFalseDeletedPoints));
 LogWriteLn(GetExpandedString(_logAddedPoints));
 LogWriteLn(GetExpandedString(_logDeletedPoints));
 LogWriteLn(GetExpandedString(_logChangedPoints));
 LogWriteLn(GetExpandedString(_logFalseDeletedPoints));
 LogWriteLn(GetExpandedString(_logFalseChangedPoints));
 LogWriteLn(GetExpandedString(_logErrorPoints));
 _IsPointListUpdated:=
                    (AddedPoints<>0) or
                    (DeletedPoints<>0) or
                    (ChangedPoints<>0) or
                    (AddedBosses<>0) or
                    (DeletedBosses<>0);
 If _IsPointListUpdated Then
    Begin
         If IsInAutoUpdateList Then
            ForcedAutoUpdateSegmentFromAddress(BossAddress);
    End;
End;

Procedure SetToDefaultVariables;
Begin
 SetVar(DeletedPointsTag,'0');
 SetVar(FalseDeletedPointsTag,'0');
 SetVar(AddedPointsTag,'0');
 SetVar(ChangedPointsTag,'0');
 SetVar(FalseChangedPointsTag,'0');
 SetVar(ErrorPointsTag,'0');
 SetVar(DeletedBossesTag,'0');
 SetVar(FalseDeletedBossesTag,'0');
 SetVar(AddedBossesTag,'0');
 SetVar(DuplicateBossesTag,'0');
 DeletedPoints:=0;
 AddedPoints:=0;
 ChangedPoints:=0;
 FalseChangedPoints:=0;
 FalseDeletedPoints:=0;
 ErrorPoints:=0;
 AddedBosses:=0;
 DeletedBosses:=0;
 FalseDeletedBosses:=0;
 DuplicateBosses:=0;
{ MsgMaskToSet:=_attrPrivate+_attrLocal;}
{ MsgMaskToSet:=GetAttributesFromString(GetVar(MsgAttributesTag.Tag,_varNONE));}
 _IsMsgWithMainPassword:=False;
 _IsInReRouteList:=False;
 _IsInAutoUpdateList:=False;
 MsgFromGate:=False;
 ToEmailName:='';
 If MessageBody<> Nil Then
    MessageBody^.FreeAll;
 If PSegmentErrorsMap<>Nil Then
   Begin
    PSegmentErrorsMap^.Done;
    PSegmentErrorsMap:=Nil;
   End;
 If PMessageErrorsMap<>Nil Then
   Begin
    PMessageErrorsMap^.Done;
    PMessageErrorsMap:=Nil;
   End;
{ If CommentsInMessage<>Nil Then
   Begin
    CommentsInMessage^.Done;
    CommentsInMessage:=Nil;
   End;}

End;

Procedure InitAllVariables;
Begin
 VarRecArray:=Nil;
 PMessageErrorsMap:=Nil;
 PSegmentErrorsMap:=Nil;
{ CommentsInMessage:=Nil;}
 PersonalErrors:=Nil;
 ModeString:='';
 SetToDefaultVariables;
 _IsPointListUpdated:=False;
 _IsWasMessages:=False;
 SetVar(ProcessMessagesTag,Yes);
 SetVar(BuildPointListTag,No);
 _flgCheckPointList:=False;
 SetVar(ConfigNameTag,'pm.ctl');
 SetVar(LanguageTag,'ENG');
 SetVar(MasterLogNameTag,'pm.log');
 SetVar(CurDateStrTag,GetDateString);
 SetVar(CurTimeStrTag,GetTimeString);
 SetVar(DayOfWeekTag,GetDoWString);
 SetVar(DayOfYearTag,GetDoYString);
 SetVar(YearTag,GetYearString);
 SetVar(MonthTag,GetMonthString);
 SetVar(DayTag,GetDayString);
 SetVar(MonthNameTag,GetMonthNameString);
 SetVar(MasterVerTag,PntMasterVersion);
 SetVar(MasterNameTag,PntMasterName);
 MSG_PID:=PntMasterVersion;
 SetVar(NetMailPathTag,'C:\');
 SetVar(MasterAddressTag,'-1:-1/-1.-1@net');
 SetVar(DomainTag,'net');
 SetVar(LogSizeTag,'100');
 SetVar(StatFileNameTag,'pm.pbs');
 SetVar(SafeMsgModeTag,No);
 SetVar(PointSegmentNameTag,'');
 SetVar(PointListNameTag,'');
 SetVar(SplitCharTag,'&');
 SetVar(AddCommentCharsTag,';;');
 SetVar(CommentsBeforeBossTag,Yes);
 SetVar(AddSemicolonAfterEachBossTag,Yes);
 SetVar(TaskNumberTag,'1');
 SetVar(ProcessFileAttachTag,Yes);
 SetVar(FileAttachPathTag,'');
 SetVar(BusyFlagNameTag,'pm.bsy');
 SetVar(AllowedCharsTag,'33..126');
 SetVar(UseValidateTag,Yes);
 SetVar(DeleteListAfterProcessTag,No);
 SetVar(StatisticDateTag,'');
 SetVar(PasswordTag,'');
 SetVar(BounceTag,'');
 SetVar(IgnoreFromNameTag,'');
 SetVar(ExcludeTag,'');
 SetVar(OnStartScriptTag,'');
 SetVar(OnExitScriptTag,'');
 SetVar(OnMessagesScriptTag,'');
 SetVar(OnEachMessageBeforeScriptTag,'');
 SetVar(OnEachMessageAfterScriptTag,'');
 SetVar(CrcTag,'0');
 SetVar(MessageSizeTag,'16');
 SetVar(LogLevelTag,'2');
 SetVar(ErrorLevelTag,'0');
 SetVar(ProcessedMessageActionTag,'');
 SetVar(ProcessedMessagePathTag,'');
 SetVar(MainPasswordTag,'');
 SetVar(FromFLNameTag,'SysOp');
 SetVar(FromFNameTag,'SysOp');
 SetVar(FromLNameTag,'SysOp');
 SetVar(GetExcludeFromNodelistTag,'');
 SetVar(ExcludeStatusTag,'DOWN');
 SetVar(PhoneMaskTag,'');
 SetVar(SpeedFlagsTag,'');
 SetVar(SystemFlagsTag,'');
 SetVar(LogPntStringErrorsTag,Yes);
 SetVar(MsgAttributesTag,'PL');
 SetVar(NotifyOnErrorsTag,'');
 SetVar(UserFlagsTag,'');
 SetVar(ImpliesFlagsTag,'');
 SetVar(TimeSliceTag,'-1');
 SetVar(EventTag,'');
 SetVar(AutoFlagsUpCaseTag,No);

 SetVar(AutoCreateSegmentTag,'');
 SetVar(AutoUpdateSegmentTag,'');
 SetVar(ForceAutoCreateSegmentTag,'');
 SetVar(AutoCreateSegmentMaskTag,'.\pntlist\segments\%zone%\%net%\%node%');
 SetVar(SegZoneTag,'0');
 SetVar(SegNetTag,'0');
 SetVar(SegNodeTag,'0');

 SetVar(TearLineStrTag,PntMasterVersion);
 SetVar(OriginStrTag,'Default origin');

 SetVar(ExtendedFileMaskTag,No);
 _ExcludeListLoaded:=False;
 MessageBody:=New(PMessageBody,Init(20,10));
 TotalBytes:=1;
 _IsPointListInMemory:=False;
 StringsToSkipAtBegin:=0;
End;

{Procedure ForEachPntList(Point:Pointer);Far;
Begin
 InitPointList(PString(Point)^);
End;}

Procedure ForEachOnStartScript(Pnt:Pointer);Far;
Begin
If Pnt=Nil Then
   Exit;
If StrTrim(PString(Pnt)^)<>'' Then
   If Load_Script(PString(Pnt)^) Then
     Begin
      Exec_Script;
      Done_Script;
     End;
End;

Procedure ForEachOnExitScript(Pnt:Pointer);Far;
{Var
 ScriptName:PString Absolute Pnt;}
Begin
If Pnt=Nil Then
   Exit;
If StrTrim(PString(Pnt)^)<>'' Then
   If Load_Script(PString(Pnt)^) Then
     Begin
      Exec_Script;
      Done_Script;
     End;
End;



Procedure ProcessedMessageAction(Var Msg:File);
Var
Action:String;
InOutResult:Integer;
DirInfo:SearchRec;
Begin
Action:=StrUp(StrTrim(GetVar(ProcessedMessageActionTag.Tag,_varNONE)));
 If Action=KillTag Then
    Begin
     {$I-}
     Erase(Msg);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
       Begin
        LogWriteLn(GetExpandedString(_logCantDeleteFile)+
                   GetVar(NetMailPathTag.Tag,_varNONE)+DirInfo.Name);
        LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
       End;
    End
Else
 If Action=CopyTag Then
    Begin
     CopyFile(GetVar(NetMailPathTag.Tag,_varNONE)+DirInfo.Name,
               GetVar(ProcessedMessagePathTag.Tag,_varNONE),False);
    End
Else
 If Action=MoveTag Then
    Begin
     CopyFile(GetVar(NetMailPathTag.Tag,_varNONE)+DirInfo.Name,
               GetVar(ProcessedMessagePathTag.Tag,_varNONE),True);
    End;
End;

Function StartMessageSubSystem:Integer;
Var
 NetMailPath:     String;
 Counter:         Integer;
 InOutResult:     Integer;
Begin
 NetMailPath:=GetVar(NetMailPathTag.Tag,_varNONE);
 If NetMailPath[Length(NetMailPath)]<>'\' Then
    NetMailPath:=NetMailPath+'\';

 StartMessageSubSystem:=0;
End;


Procedure ReadAllMessages;
Label ReadLoop;
Var
NetMailPath:String;
Counter:Integer;
InOutResult:Integer;
Msg:File;
MsgRec:TFidoMsgHeader;
DirInfo:SearchRec;

Begin
NetMailPath:=GetVar(NetMailPathTag.Tag,_varNONE);
If NetMailPath[Length(NetMailPath)]<>'\' Then
   NetMailPath:=NetMailPath+'\';
FindFirst(NetMailPath+'*.MSG',{(AnyFile-Directory-ReadOnly-Hidden-VolumeId)}(SysFile or Archive),DirInfo);
While (DosError=0) And ((DirInfo.Attr And ReadOnly)=0)
      And ((DirInfo.Attr And Hidden=0)) Do
 Begin {dos error=0}
  FillChar(MsgRec,SizeOf(MsgRec),0);
  If StrUp(GetVar(SafeMsgModeTag.Tag,_varNONE))=Yes Then
     FileMode:=$40
  Else
     FileMode:=$42;
  Assign(Msg,NetMailPath+DirInfo.Name);
(*  {$I-}
  Reset(Msg,1);
  {$I+}
  InOutResult:=IOResult;
  If InOutResult=0 Then*)
  If ResetUnTypedFile(Msg,1) Then
    Begin {reset ioresult =0}
     TotalBytes:=FileSize(Msg);
     SetVar(CurrentMessageNameTag,DirInfo.Name);
(*     {$I-}
     BlockRead(Msg,MsgRecord,SizeOf(MsgRecord));
     {$I+}
     InOutResult:=IOResult;
     If InOutResult=0 Then*)
     If BlockReadFromUnTypedFile(Msg,MsgRec,SizeOf(MsgRec)) Then
      Begin {read header ioresult=0}
       ReadedBytes:=190;
       With BossAddress Do
        Begin
         MsgRec._DestZone:=PntMasterAddress.Zone;
         MsgRec._OrigZone:=PntMasterAddress.Zone;
         MsgRec._OrigPoint:=0;
         MsgRec._DestPoint:=0;
         Zone:=PntMasterAddress.Zone;
         Net:=MsgRec._OrigNet;
         Node:=MsgRec._OrigNode;
         Point:=0;
         Domain:=PntMasterAddress.Domain;
        End;
       If (Not MsgAlreadyRead(MsgRec)) and (Not MsgAlreadySent(MsgRec)) and
          (MsgForPntMaster(MsgRec)) Then
          Begin {msg for us and not readed/sent}
            _IsWasMessages:=True;
            LoadExcludeList;
            If StrUp(GetVar(SafeMsgModeTag.Tag,_varNONE))=Yes Then
               Begin {safemode=yes}
                FileMode:=$42;
                (*{$I-}
                Reset(Msg,1);
                {$I+}
                InOutResult:=IOResult;
                If InOutResult<>0 Then*)
                If Not ResetUnTypedFile(Msg,1) Then
                   Begin {reset to fmode 2 ioresult}
                    LogWriteLn(GetExpandedString(_logCantOpenMessageForReadWrite));
{                    LogWriteDosError(InOutResult,GetExpandedString(_logDosError));}
                    SetToDefaultVariables;
                    (*{$I-}
                    Close(Msg);
                    {$I+}
                    If IOResult=0 Then;*)
                    CloseUnTypedFile(Msg);
                     Goto ReadLoop;
                   End; {reset to fmode 2 ioresult}
                (*{$I-}
                Seek(Msg,190);
                {$I+}
                If IOResult=0 Then;*)
                SeekUnTypedFile(Msg,190);
               End;{safemode=yes}
          SetVar(FromFLNameTag,TruncStr(MsgRec._From));
          If Pos(' ',StrTrim(TruncStr(MsgRec._From)))=0 Then
             Begin
              SetVar(FromFNameTag,TruncStr(MsgRec._From));
              SetVar(FromLNameTag,TruncStr(MsgRec._From));
            End
          Else
             Begin
              SetVar(FromFNameTag,Copy(StrTrim(TruncStr(MsgRec._From)),1,
                     Pos(' ',StrTrim(TruncStr(MsgRec._From)))-1));
              SetVar(FromLNameTag,Copy(StrTrim(TruncStr(MsgRec._From)),
                     Pos(' ',StrTrim(TruncStr(MsgRec._From)))+1,36));
             End;
          If MsgRec._Subj<>'' Then
             Begin
               SetVar(FromPasswordTag,TruncStr72(MsgRec._Subj));
             End
           Else
             Begin
               SetVar(FromPasswordTag,'');
             End;
            LogWriteLn(GetExpandedString(_logFoundMsg));
           If StrUp(GetVar(MainPasswordTag.Tag,_varNONE))=
                    StrUp(StrTrim(GetVar(FromPasswordTag.Tag,_varNONE))) Then
              Begin
                LogWriteLn(_logMessageWithMainPassword);
               _IsMsgWithMainPassword:=True;
              End;
            If CheckMessage(Msg,MsgRec) Then
               Begin {msg checked}
                If MsgWithAttach(MsgRec) Then
                  Begin {msg with attach}
                   If (StrUp(GetVar(ProcessFileAttachTag.Tag,_varNONE))=Yes) And
                       (Not _IsInReRouteList) Then
                     Begin
                      If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                      LogWriteLn(_logMessageWithFileAttach+
                                 TruncStr72(MsgRec._Subj)+'.Processed')
                      Else
                      LogWriteLn(_logMessageWithFileAttach+
                                 TruncStr72(MsgRec._Subj)+'.Обpаботан');
                      ProcessFileAttach(MsgRec);
                     End
                    Else
                     Begin
                      If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                       LogWriteLn(_logMessageWithFileAttach+
                                 TruncStr72(MsgRec._Subj)+'.Ignored')
                       Else
                       LogWriteLn(_logMessageWithFileAttach+
                                 TruncStr72(MsgRec._Subj)+'.Игноpиpован')
                     End;
                  End; {msg with attach}
                SetMsgIsReaded(Msg,MsgRec);
                If DuplicateBosses<>0 Then
                  Begin {dupebosses<>0}
                   If PSegmentErrorsMap=Nil Then
                      PSegmentErrorsMap:=New(PMessageBody,Init(5,5));
                   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                     Begin
                      PSegmentErrorsMap^.Insert(NewStr('Duplicate bosses: ['+IntToStr(DuplicateBosses)+'] -'));
                      If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                         LogWriteLn('!Duplicate bosses: ['+IntToStr(DuplicateBosses)+'] :');
                     End
                   Else
                     Begin
                      PSegmentErrorsMap^.Insert(NewStr('Повтоpяющихся боссов: ['+IntToStr(DuplicateBosses)+'] -'));
                      If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                         LogWriteLn('!Повтоpяющихся боссов: ['+IntToStr(DuplicateBosses)+'] :');
                     End;
                   For Counter:=0 To Pred(DupeBossesStrings^.Count) Do
                     Begin
                       PSegmentErrorsMap^.Insert(MCommon.NewStr(PString(
                                          DupeBossesStrings^.At(Counter))^));
                       If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                          LogWriteLn('!'+PString(DupeBossesStrings^.At(Counter))^);
                     End;
                   DupeBossesStrings^.FreeAll;
                  End; {dupebosses<>0}
                ReportErrorsInPointList;
                ProcessedMessageAction(Msg);
                SetToDefaultVariables;
               End {msg checked}
              Else
               Begin {msg not checked}
                SetMsgIsReaded(Msg,MsgRec);
                If DuplicateBosses<>0 Then
                  Begin {dupebosses<>0}
                   If PSegmentErrorsMap=Nil Then
                      PSegmentErrorsMap:=New(PMessageBody,Init(5,5));
                   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                     Begin
                      PSegmentErrorsMap^.Insert(NewStr('Duplicate bosses: ['+IntToStr(DuplicateBosses)+'] -'));
                      If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                         LogWriteLn('!Duplicate bosses: ['+IntToStr(DuplicateBosses)+'] :');
                     End
                   Else
                     Begin
                      PSegmentErrorsMap^.Insert(NewStr('Повтоpяющихся боссов: ['+IntToStr(DuplicateBosses)+'] -'));
                      If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                         LogWriteLn('!Повтоpяющихся боссов: ['+IntToStr(DuplicateBosses)+'] :');
                     End;
                   For Counter:=0 To Pred(DupeBossesStrings^.Count) Do
                     Begin
                       PSegmentErrorsMap^.Insert(MCommon.NewStr(PString(
                                          DupeBossesStrings^.At(Counter))^));
                       If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                          LogWriteLn('!'+PString(DupeBossesStrings^.At(Counter))^);
                     End;
                   DupeBossesStrings^.FreeAll;
                  End; {dupebosses<>0}

                ReportErrorsInPointList;
                ProcessedMessageAction(Msg);
                SetToDefaultVariables;
               End; {msg not checked}
          End; {msg for us and not readed/sent}
      End; {read header ioresult=0}
    End
     Else
      Begin {reset ioresult <>0}
        SetVar(CurrentMessageNameTag,DirInfo.Name);
        LogWriteLn(GetExpandedString(_logCantOpenMessageForReadWrite));
    {    LogWriteDosError(InOutResult,GetExpandedString(_logDosError));}
      End;  {reset ioresult <>0}
(*  {$I-}
  Close(Msg);
  {$I+}
  If IOResult=0 Then;*)
  CloseUnTypedFile(Msg);
  ForEachVar(OnEachMessageAfterScriptTag.Tag,ForEachOnMessagesScript);
ReadLoop:
  FindNext(DirInfo);
 End;
{$IFDEF VIRTUALPASCAL}
FindClose(DirInfo);
{$ENDIF}
If _IsPointListInMemory Then
  Begin
    CurrentOperation:=GetOperationString(_logBuildingPointList);
    LogWriteLn(GetExpandedString(_logBuildingPointList));
    WritePointListToDisk;
{    If DuplicateBosses<>0 Then
       CollectErrorsInPointList('','',_flgDupeBosses);
    ReportErrorsInPointList;}
    BossRecArray^.Done;
    BossRecArray:=Nil;
  End;
End;


Procedure DoneAll;
Begin
{DoneLog(Log);
DoneScreen;}
 If VarRecArray<> Nil Then
    Dispose(VarRecArray,Done);
 If CurrentPoints<>Nil Then
    Dispose(CurrentPoints,Done);
 If CurrentComments<>Nil Then
    Dispose(CurrentComments,Done);
 If BossRecArray<>Nil Then
    Dispose(BossRecArray,Done);
 If MessageBody<>Nil Then
    Dispose(MessageBody,Done);
 If PMessageErrorsMap<>Nil Then
    Dispose(PMessageErrorsMap,Done);
 If PSegmentErrorsMap<>Nil Then
    Dispose(PSegmentErrorsMap,Done);
 If DupeBossesStrings<>Nil Then
   Begin
    Dispose(DupeBossesStrings,Done);
    DupeBossesStrings:=Nil;
   End;
{ If CommentsInMessage<>Nil Then
   Begin
    Dispose(CommentsInMessage,Done);
    CommentsInMessage:=Nil;
   End;}
 If Validator<>Nil Then
    Validator^.Done;
DoneLog(Log);
{DoneScreen;}
End;


Procedure ProcessDefineCmdString;
Var
{Count:Integer;}
ParamString:String;
{PCount:Word;}
Param1,Param2:String;
Begin
{If ParamCount>0 Then
   Begin
    For Count:=1 To ParamCount Do
       Begin
        ParamString:=ParamStr(Count);
        If (ParamString[1]='-') or (ParamString[1]='/') Then
           Delete(ParamString,1,1);
        If (StrUp(ParamString[1])='D') And (ParamString[2]=':') Then
           Begin
            Delete(ParamString,1,2);
            ExtractTwoParamsFromCommentedString(ParamString,Param1,Param2);
            SetVarFromString(Param1,Param2);
           End;
      End;
   End;}
        If (IsGetOptionValue('D:*',ParamString)) Then
           Begin
{                ParamString:=ParamStr(PCount);}
                Delete(ParamString,1,2);
                ExtractTwoParamsFromCommentedString(ParamString,Param1,Param2);
                SetVarFromString(Param1,Param2);
                While (IsGetOptionValue('D:*',ParamString)) Do
                      Begin
{                            ParamString:=ParamStr(PCount);
                            Delete(ParamString,1,2);}
                            ExtractTwoParamsFromCommentedString(ParamString,Param1,Param2);
                            SetVarFromString(Param1,Param2);
                      End;
           End;
End;

Procedure ProcessCmdString;
Var
{Count:Integer;}
ParamString:String;
Param1,Param2:String;
Begin
{If ParamCount>0 Then
   Begin
    For Count:=1 To ParamCount Do
       Begin
        ParamString:=ParamStr(Count);
        If (ParamString[1]='-') or (ParamString[1]='/') Then
           Delete(ParamString,1,1);}
        If (IsGetOption('NOMSG')) Then
          Begin
{           _flgProcessMessages:=False}
            SetVar(ProcessMessagestag,No);
          End;
   {    Else}
        If (StrUp(ParamString[1])='N') and (ParamString[2] in ['0'..'9']) Then
           Begin
            SetVarFromString(TaskNumberTag.Tag,Copy(ParamString,2,Length(ParamString)));
           End
       Else
        If StrUp(ParamString)='BUILD' Then
           Begin
{           _flgBuildPointList:=True}
            SetVar(BuildPointListTag,Yes);
           End
       Else
        If StrUp(Copy(ParamString,1,6))='CHECK:' Then
          Begin
           {_flgBuildPointList:=False;
           _flgProcessMessages:=False;}
            SetVar(BuildPointListTag,No);
            SetVar(ProcessMessagesTag,No);
           _flgCheckPointList:=True;
          End
       Else
        If (StrUp(ParamString)=RussianTag) Then
           Begin
            SetVarFromString(LanguageTag.Tag,RussianTag);
           End
       Else
        If (StrUp(ParamString)=EnglishTag) Then
           Begin
            SetVarFromString(LanguageTag.Tag,EnglishTag);
           End
       Else
        If (StrUp(ParamString[1])='C') And (StrUp(Copy(ParamString,1,6))<>'CHECK:') Then
           Begin
            SetVar(ConfigNameTag,Copy(ParamString,2,Length(ParamString)));
           End;
{       End;
   End;}
End;

Procedure CheckIsDebugMode;
Var
Count:Integer;
ParamString:String;
Begin
MODE_DEBUG:=False;
 If ParamCount>0 Then
   Begin
    For Count:=1 To ParamCount Do
       Begin
        ParamString:=ParamStr(Count);
        If (ParamString[1]='-') or (ParamString[1]='/') Then
           Delete(ParamString,1,1);
        If StrUp(ParamString)='DEBUG' Then
           MODE_DEBUG:=True;
       End;
   End;
If MODE_DEBUG Then
   Begin
    InitDebugLog(Log,'DEBUG.LOG');
   End;
End;

Procedure CheckIsNoConsoleMode;
Var
Count:Integer;
ParamString:String;
Begin
MODE_NOCONSOLE:=False;
 If ParamCount>0 Then
   Begin
    For Count:=1 To ParamCount Do
       Begin
        ParamString:=ParamStr(Count);
        If (ParamString[1]='-') or (ParamString[1]='/') Then
           Delete(ParamString,1,1);
        If StrUp(ParamString)='NOCON' Then
           MODE_NOCONSOLE:=True;
       End;
   End;
End;



Function CheckForHelpRequest:Boolean;
Var
Count:Integer;
ParamString:String;
Begin
CheckForHelpRequest:=False;
 If ParamCount>0 Then
   Begin
    For Count:=1 To ParamCount Do
       Begin
        ParamString:=ParamStr(Count);
        If (ParamString[1]='-') or (ParamString[1]='/') Then
           Delete(ParamString,1,1);
        ParamString:=StrUp(ParamString);
        If (ParamString='?') or (ParamString='H') or (ParamString='HELP') Then
           CheckForHelpRequest:=True;
       End;
   End;
End;

Function IsCheckPointList:Boolean;
Var
Count,Counter:Integer;
ParamString:String;
Begin
 IsCheckPointList:=False;
 If ParamCount>0 Then
   Begin
    For Count:=1 To ParamCount Do
       Begin
        ParamString:=ParamStr(Count);
        If (ParamString[1]='-') or (ParamString[1]='/') Then
           Delete(ParamString,1,1);
        ParamString:=StrUp(ParamString);
        If Copy(ParamString,1,6)='CHECK:' Then
          Begin
           Delete(ParamString,1,6);
           SetVar(DeleteListAfterProcessTag,No);
           SetVar(NotifyOnErrorsTag,'');
           SetVar(LogPntStringErrorsTag,Yes);
           SetVar(UseValidateTag,Yes);
           InitPointList(ParamString);
           IsCheckPointList:=True;
{**}
        If DuplicateBosses<>0 Then
           Begin
             CheckErrors:=True;
             If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
               Begin
                 LogWriteLn('!Duplicate bosses: ['+IntToStr(DuplicateBosses)+'] :');
               End
             Else
               Begin
                 LogWriteLn('!Повтоpяющихся боссов: ['+IntToStr(DuplicateBosses)+'] :');
               End;
             For Counter:=0 To Pred(DupeBossesStrings^.Count) Do
               Begin
                    LogWriteLn('!'+PString(DupeBossesStrings^.At(Counter))^);
               End;
             DupeBossesStrings^.FreeAll;
           End;
         DuplicateBosses:=0;
{**}
          End;
       End;
   End;
End;

Procedure CheckForTplRequest;
Var
Count:Integer;
ParamString:String;
Tpl,TplOut:Text;
TplName,TplOutName:String;
Dir:DirStr;
Name:NameStr;
Ext:ExtStr;
BeginPos:Byte;
ReadedStr:String;
Begin
 If ParamCount>0 Then
   Begin
    For Count:=1 To ParamCount Do
       Begin
        ParamString:=ParamStr(Count);
        If (ParamString[1]='-') or (ParamString[1]='/') Then
           Delete(ParamString,1,1);
        If StrUp(Copy(ParamString,1,4))='TPL:' Then
           Begin
             Delete(ParamString,1,4);
             BeginPos:=Pos(':',ParamString);
             If BeginPos>0 Then
                Begin
                 TplName:=GetVar(Copy(ParamString,1,BeginPos-1),_varNONE);
                 TplOutName:=Copy(ParamString,BeginPos+1,Length(ParamString))
                End
            Else
                Begin
                  TplName:=GetVar(ParamString,_varNONE);
                  FSplit(TplName,Dir,Name,Ext);
                  TplOutName:=Dir+Name+'.OUT';
                End;
             Assign(Tpl,FExpand(TplName));
             (*{$I-}
             Reset(Tpl);
             {$I+}
             If IOResult<>0 Then*)
             If Not ResetTextFile(Tpl) Then
                Begin
                 LogWriteLn(GetExpandedString(_logCantOpenTpl)+FExpand(TplName));
                 Exit;
                End;
             Assign(TplOut,FExpand(TplOutName));
             (*{$I-}
             Rewrite(TplOut);
             {$I+}
             If IOResult<>0 Then*)
             if Not RewriteTextFile(TplOut) Then
                Begin
                 LogWriteLn(GetExpandedString(_logCantOpenFile)+FExpand(TplOutName));
                 Exit;
                End;
             While Not Eof(Tpl) Do
                Begin
{                 ReadLn(Tpl,ReadedStr);}
                 If ReadLnFromTextFile(Tpl,ReadedStr) Then
                    Begin
                         If Copy(PadLeft(ReadedStr),1,1)<>';' Then
                            If ExpandString(ReadedStr) = NULL Then
                               Begin
                                    If ReadedStr='' Then
                                       ReadedStr:=' ';
                                    WriteLn(TplOut,ReadedStr);
                               End;
                    End;
                End;
             CloseTextFile(Tpl);
             CloseTextFile(TplOut);
           End;
       End;
   End;
End;

{Procedure UnInstallCtrlBreakHandler;
Begin
 SetIntVec($23,SavedInt23);
End;}

{Procedure CtrlBreakHandler;Interrupt;
Begin
 LogWriteLn(GetExpandedString(_logInterruptedByUser));
 UnSetBusyFlag;
 DoneAll;
 UnInstallCtrlBreakHandler;
 ExitCode:=0;
 ErrorAddr:=Nil;
 ExitProc:=Old_Exit;
 ChangeToLastDirectory;
 Halt(255);
End;}

{Procedure InstallCtrlBreakHandler;
Begin
 GetIntVec($23,SavedInt23);
 SetIntVec($23,Addr(CtrlBreakHandler));
End;}


Procedure SetWorkModeString;
Var
_mMSG,_mList:String;
Begin
 If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
    ModeString:='#Mode: '
 Else
    ModeString:='#Режим: ';
 _mMSG:=StrUp(Copy(GetVar(ProcessMessagesTag.Tag,_varNONE),1,1));
 _mList:=StrUp(Copy(GetVar(BuildPointListTag.Tag,_varNONE),1,1));
 Case {_flgProcessMessages}_mMSG[1] Of
        'N':
           Begin
            Case {_flgBuildPointList}_mList[1] Of
                 'N'{False}:
                       Begin
                        WorkMode:=MODE_NOTHING;
                        ModeString:=ModeString+'NOTHING';
                       End;
                 'Y'{True}:
                      Begin
                        WorkMode:=MODE_BUILD;
                        ModeString:=ModeString+'BUILD';
                      End;
                End;
           End;
     'Y'{True}:
          Begin
            Case {_flgBuildPointList}_mList[1] Of
                 'N'{False}:
                       Begin
                        WorkMode:=MODE_MSG;
                        ModeString:=ModeString+'MSG';
                       End;
                 'Y'{True}:
                      Begin
                        WorkMode:=MODE_MSG_BUILD;
                        ModeString:=ModeString+'BUILD/MSG';
                      End;
                End;

          End;
    End;
If _flgCheckPointList Then
  Begin
   ModeString:=ModeString+'/CHECK';
   WorkMode:=MODE_CHECKLIST;
  End;
If MODE_DEBUG Then
   ModeString:=ModeString+'/DEBUG';
If MODE_NOCONSOLE Then
   ModeString:=ModeString+'/NOCON';
 LogWriteLn(ModeString);
End;

Procedure DoBuildPointList;
Var
Counter:Integer;
Begin
      LoadExcludeList;
      ForEachVar(PointSegmentNameTag.Tag,ForEachPntList);
      ForEachVar(AutoCreateSegmentTag.Tag,ForEachAutoCreateSegment);
      ForEachVar(ForceAutoCreateSegmentTag.Tag,ForEachForceAutoCreateSegment);
      CurrentOperation:=GetOperationString(_logBuildingPointList);
      LogWriteLn(GetExpandedString(_logBuildingPointList));
      WritePointListToDisk;
      If DuplicateBosses<>0 Then
         Begin
          If PSegmentErrorsMap=Nil Then
             PSegmentErrorsMap:=New(PMessageBody,Init(5,5));
          If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
            Begin
              PSegmentErrorsMap^.Insert(NewStr('Duplicate bosses: ['+IntToStr(DuplicateBosses)+'] -'));
              If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
              LogWriteLn('!Duplicate bosses: ['+IntToStr(DuplicateBosses)+'] :');
            End
          Else
            Begin
              PSegmentErrorsMap^.Insert(NewStr('Повтоpяющихся боссов: ['+IntToStr(DuplicateBosses)+'] -'));
              If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
              LogWriteLn('!Повтоpяющихся боссов: ['+IntToStr(DuplicateBosses)+'] :');
            End;
          For Counter:=0 To Pred(DupeBossesStrings^.Count) Do
            Begin
              PSegmentErrorsMap^.Insert(MCommon.NewStr(PString(
                                 DupeBossesStrings^.At(Counter))^));
              If StrUp(GetVar(LogPntStringErrorsTag.Tag,_varNONE))=Yes Then
                 LogWriteLn('!'+PString(DupeBossesStrings^.At(Counter))^);
            End;
          DupeBossesStrings^.FreeAll;
         End;
      ReportErrorsInPointList;
      DuplicateBosses:=0;
     If PSegmentErrorsMap<>Nil Then
        Begin
         PSegmentErrorsMap^.Done;
         PSegmentErrorsMap:=Nil;
        End;
     If BossRecArray<>Nil Then
        Begin
         BossRecArray^.Done;
         BossRecArray:=Nil;
        End;
End;

Procedure DoProcessMessages;
Begin
     CurrentOperation:=GetOperationString(_logSearchForMsg);
     LogWriteLn(GetExpandedString(_logSearchForMsg));
     ReadAllMessages;
     If _IsWasMessages Then
         ForEachVar(OnMessagesScriptTag.Tag,ForEachOnMessagesScript);
     If _IsPointListUpdated Then
         ForEachVar(OnListUpdateScriptTag.Tag,ForEachOnlistUpdateScript);

End;


{Var Counter:Integer;}
{ff:text;}
{FreeMemoryBefore, FreeMemoryAfter:LongInt;}



Constructor TPointMaster.Init;
Var
R:TRect;
W:PWindow;
{сделать здесь проверку screenwidth/height, если меньше допустимого
 то не рисовать экран, вернее, просто включить MODE_NOCONSOLE}
Begin
 CheckIsNoConsoleMode;
 Inherited Init;
 CheckBreak:=True;
 If MODE_NOCONSOLE Then
    Begin
     If Desktop <> Nil Then
        Dispose(Desktop, Done);
     If MenuBar <> Nil Then
        Dispose(MenuBar, Done);
     If StatusLine <> Nil Then
        Dispose(StatusLine, Done);
     Desktop:=Nil;
     MenuBar:=Nil;
     StatusLine:=Nil;

    End;
 If Not MODE_NOCONSOLE Then
   Begin
    R.A.X:=0;
    R.A.Y:=0;
    R.B.X:=ScreenWidth-1;
    R.B.Y:=8;
    MainInfoWindow:=New(PInfoWindow,Init(R,'',1));
    MainInfoWindow^.SetState(sfDragging,False);
    InsertWindow(MainInfoWindow);

    R.A.X:=0;
    R.A.Y:=9;
    R.B.X:=ScreenWidth-1;
    R.B.Y:=ScreenHeight-3;
    MainLogWindow:=New(PLogWindow,Init(R,'',1));
    MainLogWindow^.SetState(sfDragging,False);
    InsertWindow(MainLogWindow);
    R.A.X:=0;
    R.A.Y:=0;
    R.B.X:=0;
    R.B.Y:=0;
    W:=New(PWindow,Init(R,'',1));
    InsertWindow(W);

{ SetInfoWindowRect(R);
 MainInfoWindow:=New(PInfoWindow,Init(R,'[Info Window]',1));
 InsertWindow(MainInfoWindow);

 SetLogWindowRect(R);
 MainLogWindow:=New(PLogWindow,Init(R,'[Log Window]',2));
 With MainLogWindow^ Do
  Begin
   GetClipRect(R);
   R.Grow(-1,-1);
   LogScroller:=New(PLogScroller,Init(R,StandardScrollBar(sbHorizontal+sbHandleKeyboard),
                     StandardScrollBar(sbVertical+sbHandleKeyboard)));
   Insert(LogScroller);
  End;
 InsertWindow(MainLogWindow);}
 End;
End;

Procedure TPointMaster.InitStatusLine;
Var
R:TRect;
Begin
  If Not MODE_NOCONSOLE Then
   Begin
    GetExtent(R);
    R.A.Y := R.B.Y - 1;
    New(StatusLine, Init(R,
      NewStatusDef(0, $FFFF,
        NewStatusKey('~Control-C~ Safe exit', kbAltX, cmQuit,
        StdStatusKeys(nil)), nil)));
   End;

End;

Procedure TPointMaster.HandleEvent(var Event: TEvent);
Begin
 Inherited HandleEvent(Event);
 Case Event.What of
    evCommand:
      Begin
{        Case Event.Command of
        End}
      End;
    evKeyDown:
      Begin
{        Case Event.KeyCode of
             kbF1:
                  Begin
                    MainLogWindow^.LogScroller^.WriteStr(0,1,'TEST',
                                   GetColor(14));
                  End;
        End;}
      End;
 End;
End;


Procedure TPointMaster.Run;
Var
Event:TEvent;
FileName:String;
LineNo:LongInt;
Begin
 {InstallCtrlBreakHandler;}
 If CheckForHelpRequest Then
    Begin
     DisplayHelpWindow;
{     DoneScreenForHelpRequest;}
     Event.What:=evCommand;
     Event.Command:=cmQuit;
     PutEvent(Event);
     Inherited Run;
     Exit;
    End;


 InitializeScreen;

 CheckIsDebugMode;
 ChangeToCurrentDirectory;
 InitAllVariables;
 ProcessCmdString;
 SetOs_Type_String;
 If (Not LoadLanguageFile) Then
     Begin
      DoneAll;
      ChangeToLastDirectory;
      Event.What:=evCommand;
      Event.Command:=cmQuit;
      PutEvent(Event);
      Inherited Run;
      Exit;
     End;
 If (Not ReadConfig(GetVar(ConfigNameTag.Tag,_varNONE))) Then
     Begin
      DoneAll;
      ChangeToLastDirectory;
      Event.What:=evCommand;
      Event.Command:=cmQuit;
      PutEvent(Event);
      Inherited Run;
      Exit;
     End;
 ProcessDefineCmdString;
 TimeSliceTimes:=StrToInt(GetVar(TimeSliceTag.Tag,_varNONE));
 SetWorkModeString;
 PreUpdateScreen;
 If (Not CheckFileNamesAndPath) Then
     Begin
      DoneAll;
      ChangeToLastDirectory;
      Event.What:=evCommand;
      Event.Command:=cmQuit;
      PutEvent(Event);
      Inherited Run;
      Exit;
     End;
 SetAddressFromString(GetVar(MasterAddressTag.Tag,_varNONE),PntMasterAddress);
 SetVar(DomainTag,Copy(GetVar(MasterAddressTag.Tag,_varNONE),
                       Pos('@',GetVar(MasterAddressTag.Tag,_varNONE))+1,
                       Length(GetVar(MasterAddressTag.Tag,_varNONE))));
 SetAddressFromString(GetVar(SysOpAddressTag.Tag,_varNONE),SysOpAddress);
 CheckForTplRequest;
 If IsCheckPointList Then
    Begin
     DoneAll;
     ChangeToLastDirectory;
     Event.What:=evCommand;
     Event.Command:=cmQuit;
     PutEvent(Event);
     Inherited Run;
     Exit;
    End;
 If IsBusyFlagExist(BusyFlag) Then
     Begin
      DoneAll;
      ChangeToLastDirectory;
      Event.What:=evCommand;
      Event.Command:=cmQuit;
      PutEvent(Event);
      Inherited Run;
      Exit;
     End;
 If Not SetBusyFlag(BusyFlag) Then
     Begin
      DoneAll;
      ChangeToLastDirectory;
      Event.What:=evCommand;
      Event.Command:=cmQuit;
      PutEvent(Event);
      Inherited Run;
      Exit;
     End;
 ForEachVar(OnStartScriptTag.Tag,ForEachOnStartScript);
 If StrUp(GetVar(BuildPointListTag.Tag,_varNONE))=Yes Then
    Begin
          DoBuildPointList;
    End;
 If StrUp(GetVar(ProcessMessagesTag.Tag,_varNONE))=Yes Then
    Begin
          DoProcessMessages;
    End;
 ForEachVar(OnExitScriptTag.Tag,ForEachOnExitScript);
 UnSetBusyFlag(BusyFlag);
 DoneAll;
 ChangeToLastDirectory;
 Event.What:=evCommand;
 Event.Command:=cmQuit;
 PutEvent(Event);
 Inherited Run;
End;


Destructor TPointMaster.Done;
Begin
 Inherited Done;
 If WorkMode=MODE_CHECKLIST Then
    Begin
     If CheckErrors Then
        Halt(1);
    End;
End;

Function GetExceptString:String;
Var
FileName:String;
LineNo:LongInt;
Begin
{$IFDEF VIRTUALPASCAL}
 If GetLocationInfo(ExceptAddr,FileName,LineNo)<> Nil Then
    GetExceptString:='!Get exception in '+FileName+' line: '+IntToStr(LineNo)
 Else
    GetExceptString:='!Get exception in ???? line: ????';
{$ENDIF}
End;






Const
 RepExceptStr:String='!Exception class: ';
Var
 PointMaster:TPointMaster;

{$IFDEF VIRTUALPASCAL}
  EC:ExceptClass;
{$ENDIF}

(*{$IFDEF DEBUGVERSION}
  MemAvailBefore,
  MemAvailAfter:LongInt;
  LeakF:Text;
{$ENDIF}*)

Begin
{$IFDEF VIRTUALPASCAL}
  Try
{$ENDIF}

(*{$IFDEF DEBUGVERSION}
  MemAvailBefore:=MemAvail;
{$ENDIF}*)

 PointMaster.Init;
 PointMaster.Run;
 PointMaster.Done;

(*{$IFDEF DEBUGVERSION}
  MemAvailAfter:=MemAvail;
  If MemAvailAfter<MemAvailBefore Then
     Begin
      Assign(LeakF,'MEMLEAK.!');
      Rewrite(LeakF);
      Writeln(LeakF,'Memory leak detected !');
      WriteLn(LeakF,'Memory before: ',MemAvailBefore);
      WriteLn(LeakF,'Memory after: ',MemAvailAfter);
      Close(LeakF);
     End;
{$END}*)

{$IFDEF VIRTUALPASCAL} {*** Virtual Pascal Compiler ***}
  Except
    on EC:EAbort Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Abort');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EOutOfMemory Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Out of memory');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EInOutError Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'I/O error');
        LogWriteLn('!Error code: '+IntToStr(EC.ErrorCode));
        LogWriteLn('!Error description: '+GetErrorString(EC.ErrorCode));
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EIntError Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Non-specific integer error');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EDivByZero Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Intreger divizion by zero');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:ERangeError Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Range check error');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EIntOverFlow Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Integer overflow');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EMathError Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Non-specific floating point math error');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EInvalidOp Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Invalid operand');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EZeroDivide Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Floating point divizion by zero');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EOverflow Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Floating point overflow');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EUnderFlow Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Floating point underflow');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EInvalidPointer Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Invalid pointer is being dereferenced');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EInvalidCast Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Invalid typecast');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EConvertError Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Conversion error');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EAccessViolation Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Access violation');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EPrivilege Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Privilege error');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EStackOverFlow Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Stack overflow');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EControlC Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Ctrl-C or Ctrl-Brk was pressed');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EPropReadOnly Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Read-only property is assigned a value');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EPropWriteOnly Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'Write-only property is read');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
    on EC:EExternalException Do
       Begin
        LogWriteLn(GetExceptString);
        LogWriteLn(RepExceptStr+'External exception');
        UnSetBusyFlag(BusyFlag);
        DoneAll;
       End;
  {DoneAll;}
 End;
{$ENDIF}  {*** Virtual Pascal Compiler ***}
End.
