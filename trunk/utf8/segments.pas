{%node %net %zone %hexnode %nexnet %hexzone}
{mojno ukazivat dirs, like
{delat auto create from attach, from msg, from /build}
{mojet sdelat chtobi store crc dlya each segment i esli takoy je, to ne trogat ?}
Unit Segments;

INTERFACE
Uses Incl,Parser,StrUnit,MCommon,Dos,Logger,Script,Objects,Address,PointLst,
     FileIO,PntL_Obj;

Type
  CreateType=(tCreate,tUpdate);

Function GetAutoCreateSegNameFromMask:String;
Procedure SetMaskPartsFromAddress(Address:TAddress);
Function  AutoCreateBossSegment(BossRecord:PBossRecord;CType:CreateType):Boolean;
Procedure ForcedAutoCreateSegmentsFromMask(Mask:String);
Procedure ConditionalAutoCreateSegmentsFromMask(Mask:String);
Procedure ForcedAutoUpdateSegmentFromAddress(Address:TAddress);

IMPLEMENTATION


Function GetAutoCreateSegNameFromMask:String;
Var
 S:String;
Begin
 S:=GetVar(AutoCreateSegmentMaskTag.Tag,_varNone);
 ExpandString(S);
 GetAutoCreateSegNameFromMask:=S;
End;

Procedure SetMaskPartsFromAddress(Address:TAddress);
Begin
 SetVarFromString(SegZoneTag.Tag,IntToStr(Address.Zone));
 SetVarFromString(SegNetTag.Tag,IntToStr(Address.Net));
 SetVarFromString(SegNodeTag.Tag,IntToStr(Address.Node));
End;

Function  AutoCreateBossSegment(BossRecord:PBossRecord;CType:CreateType):Boolean;
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;
 SegName:PathStr;
 InOutResult:System.Integer;
 SegHandle:Text;
 Counter:Integer;
 Address:TAddress;
Begin
 AutoCreateBossSegment:=True;
 If BossRecord=Nil Then
    Begin
     AutoCreateBossSegment:=False;
     Exit;
    End;
 SetAddressFromString(BossRecord^.PBossString^,Address);
 SetMaskPartsFromAddress(Address);
 SegName:=GetAutoCreateSegNameFromMask;
 If Not (CreateDirWithSubDirs(SegName)) Then
    Begin
     AutoCreateBossSegment:=False;
     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
        LogWriteLn('!Can''t auto create segment for: '+Copy(BossRecord^.PBossString^,6,255))
     Else
        LogWriteLn('!Не могу создать сегмент для: '+Copy(BossRecord^.PBossString^,6,255));
     Exit;
    End;
 Assign(SegHandle,SegName);
(* {$I-}
 Rewrite(SegHandle);
 {$I+}
 InOutResult:=IOResult;
 If InOutResult<>0 Then*)
 If Not RewriteTextFile(SegHandle) Then
    Begin
        LogWriteLn(GetExpandedString(_logCantCreateFile)+SegName);
{        LogWriteDosError(InOutResult,GetExpandedString(_logDosError));}
        If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
           LogWriteLn('!Can''t auto create segment for: '+Copy(BossRecord^.PBossString^,6,255))
        Else
           LogWriteLn('!Не могу создать сегмент для: '+Copy(BossRecord^.PBossString^,6,255));
        AutoCreateBossSegment:=False;
        Exit;
    End;
  If CType=tCreate Then
     Begin
          If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
             LogWriteLn('#Auto create segment for: '+Copy(BossRecord^.PBossString^,6,255))
          Else
              LogWriteLn('#Авто создание сегмента для: '+Copy(BossRecord^.PBossString^,6,255));
     End
  Else
      Begin
          If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
             LogWriteLn('#Auto update segment for: '+Copy(BossRecord^.PBossString^,6,255))
          Else
              LogWriteLn('#Авто обновление сегмента для: '+Copy(BossRecord^.PBossString^,6,255));
      End;
  For Counter:=0 To Pred(BossRecord^.PComments^.Count) Do
   Begin
     WriteLn(SegHandle,PString(BossRecord^.PComments^.At(Counter))^);
   End;
  WriteLn(SegHandle,BossRecord^.PBossString^);
  For Counter:=0 To Pred(BossRecord^.PPoints^.Count) Do
   Begin
     WriteLn(SegHandle,PString(BossRecord^.PPoints^.At(Counter))^);
   End;
(* {$I-}
 Close(SegHandle);
 {$I+}
 If IOResult<>0 Then;*)
 CloseTextFile(SegHandle);
End;

Procedure ForcedAutoCreateSegmentsFromMask(Mask:String);
Var
 Counter:Integer;
 Address:TAddress;
Begin
 If Mask='' Then
    Exit;
 If BossRecArray<>Nil Then
    Begin
         For Counter:=0 To Pred(BossRecArray^.Count) Do
             Begin
                  SetAddressFromString(PBossRecord(BossRecArray^.At(Counter))^.PBossString^,Address);
                  If IsAddressMatch(Mask,Address) Then
                     AutoCreateBossSegment(PBossRecord(BossRecArray^.At(Counter)),tCreate);
             End;
    End;
End;


Procedure SoftAutoCreateBossSegment(BossRecord:PBossRecord);
Var
 Address:       TAddress;
 SegName:       String;
Begin
 SetAddressFromString(BossRecord^.PBossString^,Address);
 SetMaskPartsFromAddress(Address);
 SegName:=GetAutoCreateSegNameFromMask;
 If Not (IsFileExist(SegName)) Then
    AutoCreateBossSegment(BossRecord,tCreate);
End;

Procedure ConditionalAutoCreateSegmentsFromMask(Mask:String);
Var
 Counter:Integer;
 Address:TAddress;
Begin
 If Mask='' Then
    Exit;
 If BossRecArray<>Nil Then
    Begin
         For Counter:=0 To Pred(BossRecArray^.Count) Do
             Begin
                  SetAddressFromString(PBossRecord(BossRecArray^.At(Counter))^.PBossString^,Address);
                  If IsAddressMatch(Mask,Address) Then
                     SoftAutoCreateBossSegment(PBossRecord(BossRecArray^.At(Counter)));
             End;
    End;
End;

Procedure ForcedAutoUpdateSegmentFromAddress(Address:TAddress);
Var
 Counter:Integer;
 Address2:TAddress;
Begin
 If BossRecArray<>Nil Then
    Begin
         For Counter:=0 To Pred(BossRecArray^.Count) Do
             Begin
                  SetAddressFromString(PBossRecord(BossRecArray^.At(Counter))^.PBossString^,Address2);
                  If IsAddressesEqual(Address,Address2) Then
                     AutoCreateBossSegment(PBossRecord(BossRecArray^.At(Counter)),tUpdate);
                  Break;
             End;
    End;
End;

Begin
End.