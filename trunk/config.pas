{$I VERSION.INC}
UNIT Config;

INTERFACE
Uses
{$IFDEF VIRTUALPASCAL}
Use32,
{$ENDIF}
Incl,Parser,Dos,Logger,StrUnit
     {$IFNDEF SPLE}
     ,Script
     {$ENDIF}
     ;


Function ReadConfig(CfgName:String):Boolean;far;
Function IsBusyFlagExist(Var BsyFlag:File):Boolean;
Function SetBusyFlag(Var BsyFlag:File):Boolean;
Function UnSetBusyFlag(Var BsyFlag:File):Boolean;

IMPLEMENTATION

Function ReadConfig(CfgName:String):Boolean;
Var
Cfg:Text;
S:String;
Begin
ReadConfig:=True;
CfgName:=FExpand(CfgName);
Assign(Cfg,CfgName);
{$I-}
Reset(Cfg);
{$I+}
If IOResult<>0 Then
   Begin
    LogWriteLn(GetExpandedString(_logCantOpenFile)+CfgName);
    ReadConfig:=False;
    Exit;
   End;
If MODE_DEBUG Then
  Begin
   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
      DebugLogWriteLn('#Reading config file: '+CfgName)
   Else
      DebugLogWriteLn('#Обpаботка файла конфигypации: '+CfgName)
  End;
While Not Eof(Cfg) Do
 Begin
  Readln(Cfg,S);
  S:=StrTrim(S);
{  ReplaceTabsWithSpaces(S);}
  If S[1]<>';' Then
     Case ExpandString(S) of
                   NULL:ExpandCtlString(S);
           INCLUDE_FILE:Begin
                         If FExpand(S)<>CfgName Then
                            ReadConfig:=ReadConfig(S)
                        Else
                            LogWriteLn(GetExpandedString(_logCircularInclude)+CfgName);
                        End;
       {$IFNDEF SPLE}
         EXECUTE_SCRIPT:
                        Begin
                         If Load_Script(S) Then
                          Begin
                           Exec_Script;
                           Done_Script;
                          End
                        End;
        {$ENDIF}
     NOT_PROCESS_STRING:;
      End;
 End;
Close(Cfg);
End;

Function IsBusyFlagExist(Var BsyFlag:File):Boolean;
Var
{BsyFlag:File;}
DirInfo:SearchRec;
InOutResult:Integer;
Begin
 {$IFNDEF SPLE}
 FindFirst(FExpand(GetVar(BusyFlagNameTag.Tag,_varNONE)),AnyFile-VolumeID-Directory-Hidden-ReadOnly,DirInfo);
 If DosError=0 Then
    Begin
     Assign(BsyFlag,FExpand(GetVar(BusyFlagNameTag.Tag,_varNONE)));
     {$I-}
     FileMode:=$12;
     Reset(BsyFlag);
     {$I+}
     InOutResult:=IOResult;
      Case InOutResult of
        0:Begin
           FileMode:=2;
           IsBusyFlagExist:=False;
           LogWriteLn(GetExpandedString(_logPreviousCopyIsCrashed));
           {$I-}
           Close(BsyFlag);
           Erase(BsyFlag);
           {$I+}
          End;
      Else
          Begin
           IsBusyFlagExist:=True;
           FileMode:=2;
{           Close(BsyFlag);}
           LogWriteLn(GetExpandedString(_logMasterIsBusyInAnotherTask));
          End;
      End;
    End
   Else
    Begin
     IsBusyFlagExist:=False;
    End;
  {$ENDIF}
End;

Function SetBusyFlag(Var BsyFlag:File):Boolean;
Var
InOutResult:Integer;
Begin
 {$IFNDEF SPLE}
 Assign(BsyFlag,FExpand(GetVar(BusyFlagNameTag.Tag,_varNONE)));
 {$I-}
 FileMode:=$12;
 Rewrite(BsyFlag);
 {$I+}
 InOutResult:=IOResult;
 Case InOutResult of
       0:Begin
  {        FileMode:=0;
          Reset(BsyFlag);}
{          FileMode:=$20;
          {$I-}
{          Reset(BsyFlag);
          {$I+}
          FileMode:=2;
          SetBusyFlag:=True;
{          Close(BsyFlag);}
         End;
     Else
        Begin
         FileMode:=2;
         SetBusyFlag:=False;
         LogWriteLn(GetExpandedString(_logCantCreateBusyFlag));
         {$IFNDEF SPLE}
         LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
         {$ENDIF}
        End;
    End;
  {$ENDIF}
End;

Function UnSetBusyFlag(Var BsyFlag:File):Boolean;
{Var
BsyFlag:Text;}
Var
InOutResult:Integer;
Begin
 {$IFNDEF SPLE}
{ Assign(BsyFlag,FExpand(GetVar(BusyFlagNameTag.Tag,_varNONE)));}
 {$I-}
{ FileMode:=2;
 Reset(BsyFlag);}
 Close(BsyFlag);
 Erase(BsyFlag);
 {$I+}
 InOutResult:=IOResult;
 Case InOutResult of
       0:Begin
          UnSetBusyFlag:=True;
         End;
     Else
        Begin
         UnSetBusyFlag:=False;
         LogWriteLn(GetExpandedString(_logCantRemoveBusyFlag));
         {$IFNDEF SPLE}
         LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
         {$ENDIF}
        End;
    End;
 {$ENDIF}
End;


Begin
End.
