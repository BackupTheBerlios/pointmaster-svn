UNIT Statist;

INTERFACE
Uses
Use32,
Incl,Dos,Parser,Address,MCommon,Objects,StrUnit,Logger,Dates,PntL_Obj;

Type
    PointsRecord=Record
     Added,
     Deleted,
     Changed,
     FalseDeleted,
     FalseChanged,
     Error:System.Integer;
End;

Type
    BossesRecord=Record
     Added,
     Deleted:System.Integer;
End;

Type
   StatisticRecord=Record
     When:System.LongInt;
     WhoName:Z36;
     WhoAddr:TAddress;
     PointsData:PointsRecord;
     BossesData:BossesRecord;
End;

Type
   StatisticHeader=Record
     StartDate:System.LongInt;
     MasterVersion:String;
     BinMasterVersion:VersionRec;
     MasterAddress:TAddress;
     TotalRequests:System.Word;
End;

Var
StatFile:File;
StatRec:StatisticRecord;
StatHeader:StatisticHeader;

Function WriteStatistic(Who:Z36;Addr:TAddress):Boolean;
Function GetBossStatistic(Var TB:PTemplateBody;BossAddr:TAddress):Boolean;

IMPLEMENTATION

Procedure GetPackedDateTime(Var Time:LongInt);
Var
Y,M,D,DoW,H,Mn,S,Hund:Word;
Dt:DateTime;
Begin
GetDate(Y,M,D,DoW);
GetTime(H,Mn,S,Hund);
With Dt Do
 Begin
  Year:=Y;
  Month:=M;
  Day:=D;
  Hour:=H;
  Min:=Mn;
  Sec:=S;
 End;
PackTime(Dt,Time);
End;

Procedure WriteStatHeader;
Begin
{$I-}
Rewrite(StatFile,1);
{$I+}
If IOResult<>0 Then
   Begin
    LogWriteLn('!Stat: error rewriting statfile');
    {$I-}
    Close(StatFile);
    {$I+}
    If IOResult<>0 Then;
    Exit;
   End;
With StatHeader Do
  Begin
  GetPackedDateTime(StartDate);
  MasterVersion:=PntMasterVersion;
  BinMasterVersion:=BinaryMasterVersion;
  SetAddressFromString(GetVar(MasterAddressTag.Tag,_varNONE),MasterAddress);
  TotalRequests:=0;
  End;
{$I-}
Seek(StatFile,0);
{$I+}
If IOResult<>0 Then
   Begin
    LogWriteLn('!Stat: error seeking to begin');
    {$I-}
    Close(StatFile);
    {$I+}
    If IOResult<>0 Then;
    Exit;
   End;
{$I-}
BlockWrite(StatFile,StatHeader,SizeOf(StatHeader));
{$I+}
If IOResult<>0 Then
   Begin
    LogWriteLn('!Stat: error writing header');
    {$I-}
    Close(StatFile);
    {$I+}
    If IOResult<>0 Then;
    Exit;
   End;
End;

Function WriteStatistic(Who:Z36;Addr:TAddress):Boolean;
Var
StatFileName:String;
Begin
StatFileName:=GetVar(StatFileNameTag.Tag,_varNONE);
StatFileName:=FExpand(StatFileName);
Assign(StatFile,StatFileName);
{$I-}
Reset(StatFile,1);
{$I+}
If IOResult<>0 Then
   WriteStatHeader;
With StatRec Do
  Begin
    GetPackedDateTime(When);
    WhoName:=Who;
    WhoAddr:=Addr;
    With PointsData Do
     Begin
      Added:=AddedPoints;
      Deleted:=Deletedpoints;
      Changed:=ChangedPoints;
      FalseDeleted:=FalseDeletedPoints;
      FalseChanged:=FalseChangedPoints;
      Error:=ErrorPoints;
     End;
    With BossesData Do
     Begin
      Added:=AddedBosses;
      Deleted:=DeletedBosses;
     End;
  End;
{$I-}
Seek(StatFile,FileSize(StatFile));
{$I+}
If IOResult<>0 Then
   Begin
    LogWriteLn('!Stat: error seeking to end');
    {$I-}
    Close(StatFile);
    {$I+}
    If IOResult<>0 Then;
    Exit;
   End;
{$I-}
BlockWrite(StatFile,StatRec,SizeOf(StatRec));
{$I+}
If IOResult<>0 Then
   Begin
    LogWriteLn('!Stat: error writing record');
    {$I-}
    Close(StatFile);
    {$I+}
    If IOResult<>0 Then;
    Exit;
   End;
{$I-}
Close(StatFile);
{$I+}
If IOResult<>0 Then
   Begin
    LogWriteLn('!Stat: error closing statfile');
    Exit;
   End;
End;

Function GetBossStatistic(Var TB:PTemplateBody;BossAddr:TAddress):Boolean;
Var
StatFileName:String;
Dt:DateTime;

Begin
StatFileName:=GetVar(StatFileNameTag.Tag,_varNONE);
StatFileName:=FExpand(StatFileName);
Assign(StatFile,StatFileName);
{$I-}
Reset(StatFile,1);
{$I+}
If IOResult<>0 Then
   Begin
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       TB^.Insert(NewStr('Have not information'))
    Else
       TB^.Insert(NewStr('Hет инфоpмации'));
    Exit;
   End;
{$I-}
BlockRead(StatFile,StatHeader,SizeOf(StatHeader));
{$I+}
If IOResult<>0 Then
   Begin
{    LogWriteLn(GetExpandedString(StatFileNameTag.Tag));}
    LogWriteLn(GetExpandedString(_logBadStatFileFormat));
{    SetVar(StatFileNameTag,'NEW.PBS',_varNONE);}
    {$I-}
    Close(StatFile);
    Erase(StatFile);
    {$I+}
    If IOResult<>0 Then;
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       TB^.Insert(NewStr('Have not information'))
    Else
       TB^.Insert(NewStr('Hет инфоpмации'));
    Exit;
   End;
While Not Eof(StatFile) Do
  Begin
  {$I-}
   BlockRead(StatFile,StatRec,SizeOf(StatRec));
  {$I+}
  If IOResult<>0 Then
     Begin
      LogWriteLn(GetExpandedString(_logBadStatFileFormat));
      {$I-}
      Close(StatFile);
      Erase(StatFile);
      {$I+}
      If IOResult<>0 Then;
      If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
         TB^.Insert(NewStr('Have not information'))
      Else
         TB^.Insert(NewStr('Hет инфоpмации'));
      Exit;
     End;
   With StatRec Do
     Begin
      If (WhoAddr.Zone=BossAddr.Zone) and  (WhoAddr.Net=BossAddr.Net) and
         (WhoAddr.Node=BossAddr.Node) and (WhoAddr.Point=BossAddr.Point)
          and ((PointsData.Added<>0) or (PointsData.Deleted<>0) or
               (PointsData.Changed<>0) or (PointsData.FalseChanged<>0) or
               (PointsData.FalseDeleted<>0) or (PointsData.Error<>0) or
                (BossesData.Added<>0)) Then
          Begin
           UnPackTime(When,Dt);
           SetVarFromString(StatisticDateTag.Tag,GetDateStringFromDt(Dt));
           SetVarFromString(AddedPointsTag.Tag,IntToStr(PointsData.Added));
           SetVarFromString(DeletedPointsTag.Tag,IntToStr(PointsData.Deleted));
           SetVarFromString(ChangedPointsTag.Tag,IntToStr(PointsData.Changed));
           SetVarFromString(FalseDeletedPointsTag.Tag,IntToStr(PointsData.FalseDeleted));
           SetVarFromString(FalseChangedPointsTag.Tag,IntToStr(PointsData.FalseChanged));
           SetVarFromString(ErrorPointsTag.Tag,IntToStr(PointsData.Error));
           SetVarFromString(AddedBossesTag.Tag,IntToStr(BossesData.Added));
           SetVarFromString(DeletedBossesTag.Tag,IntToStr(BossesData.Deleted));
           TB^.Insert(MCommon.NewStr(GetExpandedString(GetVar(StatisticStringTag.Tag,_varNONE))));
          End;
     End;
  End;
 {$I-}
 Close(StatFile);
 {$I+}
 If IOResult<>0 Then
    LogWriteLn('!Stat: error closing file');
 SetVarFromString(AddedPointsTag.Tag,IntToStr(AddedPoints));
 SetVarFromString(DeletedPointsTag.Tag,IntToStr(DeletedPoints));
 SetVarFromString(ChangedPointsTag.Tag,IntToStr(ChangedPoints));
 SetVarFromString(FalseDeletedPointsTag.Tag,IntToStr(FalseDeletedPoints));
 SetVarFromString(FalseChangedPointsTag.Tag,IntToStr(FalseChangedPoints));
 SetVarFromString(ErrorPointsTag.Tag,IntToStr(ErrorPoints));
 SetVarFromString(AddedBossesTag.Tag,IntToStr(AddedBosses));
 SetVarFromString(DeletedBossesTag.Tag,IntToStr(DeletedBosses));
End;



Begin
End.
