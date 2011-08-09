UNIT Language;

INTERFACE
Uses
Use32,
Parser,Logger,Incl,Dos,StrUnit;

Function LoadLanguageFile:Boolean;

IMPLEMENTATION

Function LoadLanguageFile:Boolean;
Var
LangFile:Text;
Begin
 LoadLanguageFile:=True;
 Assign(LangFile,FExpand(LanguageNameTag));
 {$I-}
 Reset(LangFile);
 {$I+}
 If IOResult<>0 Then
   Begin
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('!Can''t open language file: '+LanguageNameTag)
    Else
       LogWriteLn('!Hе могy откpыть языковой файл: '+LanguageNameTag);
    LoadLanguageFile:=False;
    Exit;
   End;
{ While Not Eof(LangFile) Do}
   Begin
     ReadLn(LangFile,_logSearchForMsg);
     ReadLn(LangFile,_logFoundMsg);
     ReadLn(LangFile,_logFoundRequest);
     ReadLn(LangFile,_logMessageWithMainPassword);
     ReadLn(LangFile,_logMessageWithFileAttach);
     ReadLn(LangFile,_logLoadingListSegmentToMemory);
     ReadLn(LangFile,_logBuildExcludeListIndex);
     ReadLn(LangFile,_logIndexFileWillBeReIndexed);
     ReadLn(LangFile,_logBossAddress);

     ReadLn(LangFile,_logAddNewPoint);
     ReadLn(LangFile,_logDeletePoint);
     ReadLn(LangFile,_logFalseDeletePoint);
     ReadLn(LangFile,_logChangeDataOfPoint);
     ReadLn(LangFile,_logFalseChangeDataOfPoint);

     ReadLn(LangFile,_logAddedBosses);
     ReadLn(LangFile,_logDeletedBosses);
     ReadLn(LangFile,_logFalseDeletedBosses);
     ReadLn(LangFile,_logAddedPoints);
     ReadLn(LangFile,_logDeletedPoints);
     ReadLn(LangFile,_logChangedPoints);
     ReadLn(LangFile,_logFalseDeletedPoints);
     ReadLn(LangFile,_logFalseChangedPoints);
     ReadLn(LangFile,_logErrorPoints);
     ReadLn(LangFile,_logDuplicateBosses);
     ReadLn(LangFile,_logBuildingPointList);
     ReadLn(LangFile,_logCreatingAllDoneReport);
     ReadLn(LangFile,_logCreatingFalseReport);
     ReadLn(LangFile,_logCreatingErrorsInSegmentReport);
     ReadLn(LangFile,_logCreatingErrorsInMessageReport);
     ReadLn(LangFile,_logCreatingRequestReport);
     ReadLn(LangFile,_logReplacingBossComments);
     ReadLn(LangFile,_logBossWithoutPoints);
     ReadLn(LangFile,_logStartScript);
     ReadLn(LangFile,_logDoneScript);
     ReadLn(LangFile,_logExecuting);
     ReadLn(LangFile,_logExitCode);
     ReadLn(LangFile,_logExitByCommand);
     ReadLn(LangFile,_logInterruptedByUser);
     ReadLn(LangFile,_logDosErrorOnExec);
     ReadLn(LangFile,_logDosError);
     ReadLn(LangFile,_logTryChangeAnotherBoss);
     ReadLn(LangFile,_logMessageFromPoint);
     ReadLn(LangFile,_logTryToExecProtectedCommand);
     ReadLn(LangFile,_logCantCreateMessage);
     ReadLn(LangFile,_logCantOpenMessageForReadWrite);
     ReadLn(LangFile,_logCantWriteToMessage);
     ReadLn(LangFile,_logCantOpenTpl);
     ReadLn(LangFile,_logMasterIsBusyInAnotherTask);
     ReadLn(LangFile,_logCantCreateBusyFlag);
     ReadLn(LangFile,_logCantRemoveBusyFlag);
     ReadLn(LangFile,_logNotEnoughMemory);
     ReadLn(LangFile,_logCantDeleteFile);
     ReadLn(LangFile,_logCircularInclude);
     ReadLn(LangFile,_logInvalidPath);
     ReadLn(LangFile,_logInvalidFileName);
     ReadLn(LangFile,_logIndexFileDamaged);
     ReadLn(LangFile,_logNotAnIndexFile);
     ReadLn(LangFile,_logBadStatFileFormat);
     ReadLn(LangFile,_logPasswordMismatch);
     ReadLn(LangFile,_logInBounceList);
     ReadLn(LangFile,_logMessageFromIgnoreName);
     ReadLn(LangFile,_logInReRouteList);
     ReadLn(LangFile,_logInExcludeList);
     ReadLn(LangFile,_logCantOpenFile);
     ReadLn(LangFile,_logCantCreateFile);
     ReadLn(LangFile,_logCantLoadScript);
     ReadLn(LangFile,_logWriteToNonOpenedMessage);
     ReadLn(LangFile,_logTryingToCloseNonOpenedMessage);
     ReadLn(LangFile,_logMessageNotForMaster);
     ReadLn(LangFile,_logTryToReRouteToOurSelf);
     ReadLn(LangFile,_logPreviousCopyIsCrashed);
   End;
  Close(LangFile);
End;

Begin
End.
