
UNIT Script;

INTERFACE
Uses
Use32,SysUtils,
Dos,Logger,Parser,Incl,MCommon,StrUnit,Objects,Crt,Face,Validate,
     Address,FidoMsg,App,Drivers,Memory,FileIO,PntL_Obj;


Type
 PFileObject=^TFileObject;
 TFileObject=Object(TObject)
   PAssignedName:PString;
   PFileName:PString;
   THandle:File;
   TStatus:Word;
{   TFilePos:LongInt;}
   Constructor Init(Assigned,Name:String);
   Destructor Done;virtual;
End;

Type
 PCompiledScript=^TCompiledScript;
 TCompiledScript=Object(TCollection)
  Procedure Insert(Item: Pointer); virtual;
End;

Type
  PFilesRecordCollection=^TFilesRecordCollection;
  TFilesRecordCollection=Object(TSortedCollection)
    Function Compare(Key1,Key2:Pointer):LongInt;Virtual;
    Function KeyOf(Item:Pointer):Pointer;Virtual;
    Procedure Error(Code, Info: Integer);Virtual;
    Function GetFileObjectPointer(Assigned:String):PFileObject;
    Function _OpenFile(PFileRec:PFileObject):Boolean;
    Function _CloseFile(PFileRec:PFileObject):Boolean;
    Function _Seek(PFileRec:PFileObject;Position:LongInt):Boolean;
    Function _WriteToFile(PFileRec:PFileObject;StrToWrite:String):Boolean;
    Function _ReadFromFile(PFileRec:PFileObject;Var StrToRead:String):Boolean;
    Function _EndOfFile(PFileRec:PFileObject):Boolean;
    Function _FPos(PFileRec:PFileObject;Var FilePosition:LongInt):Boolean;
    Function FPos(Assigned:String;Var FilePosition:LongInt):Boolean;
    Function AssignFile(Assigned,Name:String):Boolean;
    Function OpenFile(Assigned:String):Boolean;
    Function WriteToFile(Assigned,StrToWrite:String):Boolean;
    Function Seek(Assigned:String;Position:LongInt):Boolean;
    Function ReadFromFile(Assigned:String;Var StrToRead:String):Boolean;
    Function CloseFile(Assigned:String):Boolean;
    Function EndOfFile(Assigned:String):Boolean;
    Function IsFileAssigned(Assigned:String):Boolean;
    Function IsFileOpened(Assigned:String):Boolean;
End;

Type
 TCommandType=Record
   TCmdPic:String[150];
   TParamCount:Byte;
End;

Const
stOpened=1;
stClosed=2;

_picLogWriteLn:TCommandType=(
               TCmdPic:'LOGWRITELN[* ]([* ]"[*$]"[* ])[* ][;;]';
               TParamCount:1);
_picCopyFile  :TCommandType=(
               TCmdPic:'COPYFILE[* ]([* ]"*$"[* ];,[* ]"*$"[* ])[* ][;;]';
               TParamCount:2);
_picMoveFile  :TCommandType=(
               TCmdPic:'MOVEFILE[* ]([* ]"*$"[* ];,[* ]"*$"[* ])[* ][;;]';
               TParamCount:2);
_picAssignFile:TCommandType=(
               TCmdPic:'ASSIGNFILE[* ]([* ]*|[* ];,[* ]"*$"[* ])[* ][;;]';
               TParamCount:1);
_picWriteToFile:TCommandType=(
               TCmdPic:'WRITETOFILE[* ]([* ]*|[* ];,[* ]"*$"[* ])[* ][;;]';
               TParamCount:1);
_picReadFromFile:TCommandType=(
               TCmdPic:'READFROMFILE[* ]([* ]*|[* ];,[* ]"*$"[* ])[* ][;;]';
               TParamCount:1);
_picSeekToFile:TCommandType=(
               TCmdPic:'SEEKTOFILE[* ]([* ]*|[* ];,[* ]"*$"[* ])[* ][;;]';
               TParamCount:1);
_picFilePos   :TCommandType=(
               TCmdPic:'FILEPOS[* ]([* ]*|[* ];,[* ]"*$"[* ])[* ][;;]';
               TParamCount:1);
_picEndOfFile :TCommandType=(
               TCmdPic:'IF[* ]ENDOFFILE[* ]([* ]*%[* ])[* ][;;]';
               TParamCount:0);
_picCloseFile :TCommandType=(
               TCmdPic:'CLOSEFILE[* ]([* ]*%[* ])[* ][;;]';
               TParamCount:0);
_picDos_Exec  :TCommandType=(
               TCmdPic:'DOS_EXEC[* ]([* ]"*$"[* ];,[* ]"[*$]"[* ])[* ][;;]';
               TParamCount:2);
_picExec      :TCommandType=(
               TCmdPic:'EXEC[* ]([* ]"*$"[* ];,[* ]"[*$]"[* ])[* ][;;]';
               TParamCount:2);
_picCopy      :TCommandType=(
               TCmdPic:'COPY[* ]([* ]"[*$]"[* ];,[* ]"*$"[* ];,[* ]"[* ]*$[* ]"[* ];,'+
                '[* ]"[* ]*$[* ]"[* ])[* ][;;]';
               TParamCount:4);
_picPos       :TCommandType=(
               TCmdPic:'POS[* ]([* ]"[*$]"[* ];,[* ]"*$"[* ];,[* ]"*$"[* ])[* ][;;]';
               TParamCount:3);
_picIf_Then   :TCommandType=(
               TCmdPic:'IF[* ]([* ]"*$"[* ][=][<>][>][<][* ]"*$"[* ])';
               TParamCount:2);
_picIf_Exist  :TCommandType=(
               TCmdPic:'IF[* ]EXIST[* ]([* ]"*$"[* ])';
               TParamCount:1);
_picElse      :TCommandType=(
               TCmdPic:'ELSE';
               TParamCount:0);
_picGoto      :TCommandType=(
               TCmdPic:'GOTO [* ]"*$"[* ][;;]';
               TParamCount:1);
_picAssign     :TCommandType=(
               TCmdPic:'"*$"[* ]:[* ]=[* ]"*$"[* ][;;]';
               TParamCount:2);
_picCreateMsg :TCommandType=(
               TCmdPic:'CREATEMSG[* ]([* ]"*$"[* ];,[* ]"*$"[* ];,[* ]"*$"[* ];,[* ]"*$"[* ];,'+
               '[* ]"*$"[* ];,[* ]"[* ]*$[* ]"[* ])[* ][;;]';
               TParamCount:6);
_picWriteToMsg:TCommandType=(
               TCmdPic:'WRITETOMSG[* ]([* ]"*$"[* ])[* ][;;]';
               TParamCount:1);
_picCloseMsg  :TCommandType=(
               TCmdPic:'CLOSEMSG[* ][;;]';
               TParamCount:0);
_picEndIf     :TCommandType=(
               TCmdPic:'ENDIF[* ][;;]';
               TParamCount:0);
_picExit      :TCommandType=(
               TCmdPic:'EXIT[* ][;;]';
               TParamCount:0);
_picInc       :TCommandType=(
               TCmdPic:'INC[* ]([* ]"*$"[* ];,[* ]"[*$]"[* ])[* ][;;]';
               TParamCount:2);
_picDec       :TCommandType=(
               TCmdPic:'DEC[* ]([* ]"*$"[* ];,[* ]"[*$]"[* ])[* ][;;]';
               TParamCount:2);
{_picDisableScreenHandler:TCommandType=(
               TCmdPic:'DISABLESCREENHANDLER[* ][;;]';
               TParamCount:0);
_picEnableScreenHandler:TCommandType=(
               TCmdPic:'ENABLESCREENHANDLER[* ][;;]';
               TParamCount:0);}
_picStringLength:TCommandType=(
                TCmdPic:'LENGTHSTRING[* ]([* ]"*$"[* ];,[* ]"*$"[* ])[* ][;;]';
                TParamCount:2);
_picStringUp:TCommandType=(
                TCmdPic:'STRINGUP[* ]([* ]"*$"[* ];,[* ]"*$"[* ])[* ][;;]';
                TParamCount:2);
_picStringDown:TCommandType=(
                TCmdPic:'STRINGDOWN[* ]([* ]"*$"[* ];,[* ]"*$"[* ])[* ][;;]';
                TParamCount:2);
_picStringTrim:TCommandType=(
                TCmdPic:'STRINGTRIM[* ]([* ]"*$"[* ];,[* ]"*$"[* ])[* ][;;]';
                TParamCount:2);
_picLeftStringTrim:TCommandType=(
                TCmdPic:'LEFTSTRINGTRIM[* ]([* ]"*$"[* ];,[* ]"*$"[* ])[* ][;;]';
                TParamCount:2);
_picRightStringTrim:TCommandType=(
                TCmdPic:'RIGHTSTRINGTRIM[* ]([* ]"*$"[* ];,[* ]"*$"[* ])[* ][;;]';
                TParamCount:2);

Const
 _cmdUnknown=0;
 _cmdLogWriteLn=1;
 _cmdCopyFile=2;
 _cmdMoveFile=3;
 _cmdAssignFile=4;
 _cmdWriteToFile=5;
 _cmdReadFromFile=6;
 _cmdSeekToFile=7;
 _cmdFilePos=8;
 _cmdIf_EndOfFIle=9;
 _cmdCloseFile=10;
 _cmdDos_Exec=11;
 _cmdExec=12;
 _cmdCopy=13;
 _cmdPos=14;
 _cmdIf_Then=15;
 _cmdIf_Exist=16;
 _cmdElse=17;
 _cmdGoto=18;
 _cmdAssign=19;
 _cmdCreateMsg=20;
 _cmdWriteToMsg=21;
 _cmdCloseMsg=22;
 _cmdEndIf=23;
 _cmdExit=24;
 _cmdInc=25;
 _cmdDec=26;
 _cmdLabel=27;
 _cmdNotProcess=28;
{ _cmdDisableScreenHandler=29;
 _cmdEnableScreenHandler=30;}
 _cmdStringLength=29;
 _cmdStringUp=30;
 _cmdStringDown=31;
 _cmdStringTrim=32;
 _cmdLeftStringTrim=33;
 _cmdRightStringTrim=34;
 _cmdReserved=35;{inc when add new command, must be after last used}

Type
   PScriptCommand=^TScriptCommand;
   TScriptCommand=Object(TObject)
    TCommandType:Word;
    PCommandParameters:PMessageBody;
    Constructor Init(ACommandType:Word;ACommandParameters:PMessageBody);
    Destructor  Done;Virtual;
    Procedure Store(Var S:TStream);
    Procedure Load(Var S:TStream);
End;

Const
 RPScriptCommand:TStreamRec=(
   ObjType:200;
   VMTLink:Ofs(TypeOf(TScriptCommand)^);
   Load:@TScriptCommand.Load;
   Store:@TScriptCommand.Store);

Var
PCmdValidator:PPXPictureValidator;
PFilesCollection:PFilesRecordCollection;
BodyCount:LongInt;
_MsgWasCreated:Boolean;
_MsgWasClosed:Boolean;
CompiledScript:PCompiledScript;

Procedure LogWriteDosError(ErrorCode:Integer;LogString:String);
Function Load_Script(Name:String):Boolean;
Function IsToken_Valid(Token:String;Source:String):Boolean;
Function Exec_Script:Boolean;
Procedure CreateFilesCollection;
Procedure ScrollToEndIf;
Function Do_AssignFile(Cmd:PScriptCommand):Boolean;
Function Do_WriteToFile(Cmd:PScriptCommand):Boolean;
Function Do_ReadFromFile(Cmd:PScriptCommand):Boolean;
Function Do_SeekToFile(Cmd:PScriptCommand):Boolean;
Function Do_FilePos(Cmd:PScriptCommand):Boolean;
Function Do_IfEndOfFile(Cmd:PScriptCommand):Boolean;
Function Do_CloseFile(Cmd:PScriptCommand):Boolean;
Function Do_Inc(Cmd:PScriptCommand):Boolean;
Function Do_Dec(Cmd:PScriptCommand):Boolean;
Function Do_LogWriteLn(Cmd:PScriptCommand):Boolean;
Function Do_CopyFile(Cmd:PScriptCommand):Boolean;
Function Do_Dos_Exec(Cmd:PScriptCommand):Boolean;
Function Do_Exec(Cmd:PScriptCommand):Boolean;
Function Do_If_Then(Cmd:PScriptCommand):Boolean;
Function Do_If_Exist(Cmd:PScriptCommand):Boolean;
Function Do_Exit(Cmd:PScriptCommand):Boolean;
Function Do_Assigment(Cmd:PScriptCommand):Boolean;
Function Do_CreateMsg(Cmd:PScriptCommand):Boolean;
Function Do_WriteToMsg(Cmd:PScriptCommand):Boolean;
Function Do_CloseMsg(Cmd:PScriptCommand):Boolean;
Function Do_Goto(Cmd:PScriptCommand):Boolean;
Function Do_Copy(Cmd:PScriptCommand):Boolean;
Function Do_Pos(Cmd:PScriptCommand):Boolean;
Procedure Do_NotProcess(Cmd:PScriptCommand);
Procedure Do_EnableScreenHandler(Cmd:PScriptCommand);
Procedure Do_DisableScreenHandler(Cmd:PScriptCommand);
Procedure Done_Script;
{Procedure CopyFile(Source,Dest:String;IsMove:Boolean);}
Procedure Do_StringTrim(Cmd:PScriptCommand);
Procedure Do_LeftStringTrim(Cmd:PScriptCommand);
Procedure Do_RightStringTrim(Cmd:PScriptCommand);

IMPLEMENTATION

Procedure TCompiledScript.Insert(Item: Pointer);
Var
Counter:LongInt;
Params:String;
Begin
 If MODE_DEBUG Then
   Begin
    Params:='';
    With PScriptCommand(Item)^ Do
     Begin
      For Counter:=0 To Pred(PCommandParameters^.Count) Do
        Begin
         If PCommandParameters^.At(Counter)<>Nil Then
            Params:=Params+PString(PCommandParameters^.At(Counter))^+','
           Else
            Params:=Params+'Nil,';
        End;
      System.Delete(Params,Length(Params),1);
      DebugLogWriteLn('#Script.InsertCmd.CmdType('+IntToStr(PScriptCommand(Item)^.TCommandType)
                      +').CmdParams('+Params+')');
     End;
   End;
 Inherited Insert(Item);
End;

Procedure TScriptCommand.Store(Var S:TStream);
Var Counter:LongInt;
Begin
 S.Write(TCommandType,SizeOf(TCommandType));
{ For Counter:=0 To Pred(PCommandParameters^.Count) Do
     S.Write(PString(PCommandParameters^.At(Counter))^,Length(PString(PCommandParameters^.At(Counter))^));}
 PCommandParameters^.Store(s);
End;

Procedure TScriptCommand.Load(Var S:TStream);
Begin
End;

Procedure GetCmdParameters(Cmd:String;CmdType:Byte;ParamsCount:Byte;Var Params:PMessageBody);
Var
Counter:Word;
BeginPos,EndPos:Byte;
Begin
If Params<>Nil Then
   Begin
    Params^.FreeAll;
    Case CmdType Of
         _cmdAssignFile,
         _cmdWriteToFile,
         _cmdReadFromFile,
         _cmdSeekToFile,
         _cmdIf_EndOfFile,
         _cmdFilePos,
         _cmdCloseFile:
                       Begin
                        BeginPos:=Pos('(',Cmd);
                        Delete(Cmd,BeginPos,1);
                        If (CmdType=_cmdIf_EndOfFile)
                           or (CmdType=_cmdCloseFile) Then
                           EndPos:=Pos(')',Cmd)
                        Else
                           EndPos:=Pos(',',Cmd);
                        Delete(Cmd,EndPos,1);
                        Params^.Insert(MCommon.NewStr(StrTrim(Copy(Cmd,BeginPos,EndPos-BeginPos))));
                       End;
         _cmdLabel:
                       Begin
                        Cmd:=StrTrim(Cmd);
                  {      Delete(Cmd,Length(Cmd),1);}
                        Params^.Insert(MCommon.NewStr(Cmd));
                       End;
         _cmdNotProcess:
                       Begin
                        Params^.Insert(MCommon.NewStr(StrTrim(Cmd)));
                       End;
    End;
    For Counter:=1 To ParamsCount Do
        Begin
          BeginPos:=Pos('"',Cmd);
          Delete(Cmd,BeginPos,1);
          EndPos:=Pos('"',Cmd);
          Delete(Cmd,EndPos,1);
          Params^.Insert(MCommon.NewStr(StrTrim(Copy(Cmd,BeginPos,EndPos-BeginPos))));
          Delete(Cmd,BeginPos,EndPos-BeginPos);
        End;
    If CmdType=_cmdIf_Then Then
        Begin
         If Pos('=',Cmd)<>0 Then
            Params^.Insert(Objects.NewStr('='))
        Else
         If Pos('<>',Cmd)<>0 Then
            Params^.Insert(Objects.NewStr('<>'))
        Else
         If Pos('>',Cmd)<>0 Then
            Params^.Insert(Objects.NewStr('>'))
        Else
         If Pos('<',Cmd)<>0 Then
            Params^.Insert(Objects.NewStr('<'));
        End;
   End;
End;

Procedure PutCommandIntoCompiledScript(Cmd:String);
Var
Params:PMessageBody;
CmdTest:String;
{ CmdParams:Array[0..}
Begin
CmdTest:=Cmd;
{If ExpandString(CmdTest)<>NULL Then
   Exit;}
Params:=New(PMessageBody,Init(2,1));
    If Copy(PadLeft(Cmd),1,1)='#' Then
       Begin
         GetCmdParameters(Cmd,_cmdNotProcess,0,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdNotProcess,Params)));
       End
   Else
    If (Cmd='{') or (Cmd='}') {or (StrUp(Copy(Cmd,1,5))='ENDIF')}
        {or (Cmd[Length(Cmd)]=':')} Then
       Begin
{        Inc(BodyCount);}
       End
   Else
    If (Cmd[Length(Cmd)]=':') Then
       Begin
         GetCmdParameters(Cmd,_cmdLabel,0,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdLabel,Params)));
       End
   Else
    If (StrUp(Copy(Cmd,1,5))='ENDIF'){IsToken_Valid(_picEndIf.TCmdPic,Cmd)} Then
       Begin
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdEndIf,Nil)));
       End
   Else
    If IsToken_Valid(_picIf_Then.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdIf_Then,_picIf_Then.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdIf_Then,Params)));
       End
   Else
    If IsToken_Valid(_picIf_Exist.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdIf_Exist,_picIf_Exist.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdIf_Exist,Params)));
       End
   Else
    If IsToken_Valid(_picElse.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdElse,_picElse.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdElse,Params)));
       End
   Else
    If IsToken_Valid(_picLogWriteLn.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdLogWriteLn,_picLogWriteLn.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdLogWriteLn,Params)));
       End
   Else
    If IsToken_Valid(_picAssign.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdAssign,_picAssign.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdAssign,Params)));
       End
   Else
    If IsToken_Valid(_picCopy.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdCopy,_picCopy.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdCopy,Params)));
       End
   Else
    If IsToken_Valid(_picPos.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdPos,_picPos.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdPos,Params)));
       End
   Else
    If IsToken_Valid(_picCopyFile.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdCopyFile,_picCopyFile.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdCopyFile,Params)));
        End
   Else
    If IsToken_Valid(_picMoveFile.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdMoveFile,_picMoveFile.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdMoveFile,Params)));
       End
   Else
    If IsToken_Valid(_picAssignFile.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdAssignFile,_picAssignFile.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdAssignFile,Params)));
       End
   Else
    If IsToken_Valid(_picWriteToFile.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdWriteToFile,_picWriteToFile.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdWriteToFile,Params)));
       End
   Else
    If IsToken_Valid(_picReadFromFile.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdReadFromFile,_picReadFromFile.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdReadFromFile,Params)));
       End
   Else
    If IsToken_Valid(_picSeekToFile.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdSeekToFile,_picSeekToFile.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdSeekToFile,Params)));
       End
   Else
    If IsToken_Valid(_picFilePos.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdFilePos,_picFilePos.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdFilePos,Params)));
       End
   Else
    If IsToken_Valid(_picEndOfFile.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdIf_EndOfFile,_picEndOfFile.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdIf_EndOfFile,Params)));
       End
   Else
    If IsToken_Valid(_picCloseFile.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdCloseFile,_picCloseFile.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdCloseFile,Params)));
       End
   Else
    If IsToken_Valid(_picInc.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdInc,_picInc.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdInc,Params)));
       End
   Else
    If IsToken_Valid(_picDec.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdDec,_picDec.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdDec,Params)));
       End
   Else
    If IsToken_Valid(_picDos_Exec.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdDos_Exec,_picDos_Exec.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdDos_Exec,Params)));
       End
   Else
    If IsToken_Valid(_picExec.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdExec,_picExec.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdExec,Params)));
       End
   Else
    If IsToken_Valid(_picCreateMsg.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdCreateMsg,_picCreateMsg.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdCreateMsg,Params)));
       End
   Else
    If IsToken_Valid(_picWriteToMsg.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdWriteToMsg,_picWriteToMsg.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdWriteToMsg,Params)));
       End
   Else
    If IsToken_Valid(_picCloseMsg.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdCloseMsg,_picCloseMsg.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdCloseMsg,Params)));
       End
   Else
    If IsToken_Valid(_picGoto.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdGoTo,_picGoTo.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdGoTo,Params)));
       End
   Else
    If IsToken_Valid(_picExit.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdExit,_picExit.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdExit,Params)));
       End
{   Else
    If IsToken_Valid(_picEnableScreenHandler.TCmdPic,Cmd) Then
       Begin
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdEnableScreenHandler,Nil)));
       End
   Else
    If IsToken_Valid(_picDisableScreenHandler.TCmdPic,Cmd) Then
       Begin
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdDisableScreenHandler,Nil)));
       End}
   Else
    If IsToken_Valid(_picStringLength.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdStringLength,_picStringLength.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdStringLength,Params)));
       End
   Else
    If IsToken_Valid(_picStringUp.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdStringUp,_picStringUp.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdStringUp,Params)));
       End
   Else
    If IsToken_Valid(_picStringDown.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdStringDown,_picStringDown.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdStringDown,Params)));
       End

   Else
    If IsToken_Valid(_picStringTrim.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdStringTrim,_picStringTrim.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdStringTrim,Params)));
       End
   Else
    If IsToken_Valid(_picLeftStringTrim.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdLeftStringTrim,_picLeftStringTrim.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdLeftStringTrim,Params)));
       End
   Else
    If IsToken_Valid(_picRightStringTrim.TCmdPic,Cmd) Then
       Begin
         GetCmdParameters(Cmd,_cmdRIghtStringTrim,_picRightStringTrim.TParamCount,Params);
         CompiledScript^.Insert(New(PScriptCommand,Init(_cmdRightStringTrim,Params)));
       End

   Else
    Begin
        If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
           LogWriteLn('!Unknown command: '+Cmd)
        Else
           LogWriteLn('!Hеизвестная команда: '+Cmd);
    End;
If Params<>Nil Then
   Dispose(Params,Done);
End;

Constructor TScriptCommand.Init(ACommandType:Word;ACommandParameters:PMessageBody);
Var
 Counter:LongInt;
Begin
 Inherited Init;
 TCommandType:=ACommandType;
 PCommandParameters:=New(PMessageBody,Init(2,1));
 If ACommandParameters<>Nil Then
  Begin
    For Counter:=0 To Pred(ACommandParameters^.Count) Do
     Begin
      PCommandParameters^.Insert(MCommon.NewStr(StrTrim(PString(ACommandParameters^.At(Counter))^)));
     End;
  ENd;
End;

Destructor TScriptCommand.Done;
Begin
 If PCommandParameters<>Nil Then
    Dispose(PCommandParameters,Done);
 Inherited Done;
End;

Constructor TFileObject.Init(Assigned,Name:String);
Begin
 Inherited Init;
 PAssignedName:=MCommon.NewStr(Assigned);
 PFileName:=MCommon.NewStr(Name);
 TStatus:=stClosed;
 TFileRec(THandle).Handle:=0;
End;

Destructor TFileObject.Done;
Begin
 If TStatus=stOpened Then
    If PFilesCollection<> Nil Then
       PFilesCollection^._CloseFile(@Self);
 Objects.DisposeStr(PFileName);
 Objects.DisposeStr(PAssignedName);
 Inherited Done;
End;

Function TFilesRecordCollection.Compare(Key1,Key2:Pointer):LongInt;
Var
FStr: PString;{ absolute Key1;}
SStr: PString; {absolute Key2;}
Begin
FStr:=PString(Key1);
SStr:=PString(Key2);
If StrUp(FStr^)=StrUp(SStr^) Then
  Begin
   Compare:=0;
  End
 Else
   Compare:=-1;
End;

Function TFilesRecordCollection.KeyOf(Item:Pointer):Pointer;
Begin
 KeyOf:=@PFileObject(Item)^.PAssignedName^;
End;

Procedure TFilesRecordCollection.Error(Code, Info: Integer);
Begin
If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
Begin
Case Code Of
   -1:LogWriteLn('!Files index out of range. Requested index: '+IntToStr(Info));
   -2:LogWriteLn('!Files collection overflow. Requested index: '+IntToStr(Info));
 End;
End
Else
 Begin
 Case Code Of
    -1:LogWriteLn('!Индекс файлов пpевышает допyстимый пpедел. Запpошенный индекс: '+IntToStr(Info));
    -2:LogWriteLn('!Пеpеполнение коллекции файлов. Запpошенный индекс: '+IntToStr(Info));
  End;
 End;
End;

Function TFilesRecordCollection.IsFileAssigned(Assigned:String):Boolean;
Begin
 IsFileAssigned:=GetFileObjectPointer(Assigned)<>Nil;
End;

Function TFilesRecordCollection.IsFileOpened(Assigned:String):Boolean;
Var
Result_:PFileObject;
Begin
 Result_:=GetFileObjectPointer(Assigned);
 If Result_<>Nil Then
   IsFileOpened:=Result_^.TStatus=stOpened
 Else
   IsFileOpened:=False;
{ IsFileOpened:=GetFileObjectPointer(Assigned)^.TStatus=stOpened;}
End;

Function TFilesRecordCollection.GetFileObjectPointer(Assigned:String):PFileObject;
Var
Counter:LongInt;
Begin
 GetFileObjectPointer:=Nil;
 For Counter:=0 To Pred(Count) Do
    Begin
     If StrUp(PFileObject(At(Counter))^.PAssignedName^)=StrUp(Assigned) Then
       Begin
        GetFileObjectPointer:=PFileObject(At(Counter));
        Break;
       End;
    End;
End;

Function TFilesRecordCollection._OpenFile(PFileRec:PFileObject):Boolean;
Begin
 _OpenFile:=True;
 If PFileRec=Nil Then
   Begin
    _OpenFile:=False;
    LogWriteLn('!Null pointer assignment: OpenFile');
{    RunError(204);}
    Exit;
   End;
 With PFileRec^ Do
  Begin
    FileMode:=$42;
    Assign(THandle,PFileName^);
    {$I-}
    Reset(THandle,1);
    {$I+}
    If IOResult<>0 Then
       Begin
        FileMode:=$40;
        {$I-}
        Reset(THandle,1);
        {$I+}
        FileMode:=$42;
        If IOResult<>0 Then
          Begin
           {$I-}
           Rewrite(THandle,1);
           {$I+}
           If IOResult<>0 Then
             Begin
              _OpenFile:=False;
              LogWriteLn(GetExpandedString(_logCantOpenFile)+PFileName^);
              Exit;
             End;
          End;
       End;
{    TFilePos:=0;}
    TStatus:=stOpened;
    {$I-}
    System.Seek(THandle,0);
    {$I+}
    If IOResult=0 Then;
  End;
End;

Function TFilesRecordCollection.OpenFile(Assigned:String):Boolean;
Begin
 OpenFile:=_OpenFile(GetFileObjectPointer(Assigned));
End;

Function TFilesRecordCollection._CloseFile(PFileRec:PFileObject):Boolean;
Begin
 _CloseFile:=True;
 If PFileRec=Nil Then
   Begin
    _CloseFile:=False;
    LogWriteLn('!Null pointer assignment: CloseFile');
{    RunError(204);}
    Exit;
   End;
 With PFileRec^ Do
  Begin
   {$I-}
   Close(THandle);
   {$I+}
   If IOResult<>0 Then
      Begin
       _CloseFile:=False;
      If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
         LogWriteLn('!Can''t close file: '+PFileName^)
      Else
         LogWriteLn('!Hе могy закpыть файл: '+PFileName^);
      End;
   TStatus:=stClosed;
{   TFilePos:=0;}
  End;
End;

Function TFilesRecordCollection.CloseFile(Assigned:String):Boolean;
Begin
CloseFile:=True;
If Not (IsFileAssigned(Assigned)) Then
   Begin
    CloseFile:=False;
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('!File not assigned: '+Assigned)
    Else
       LogWriteLn('!Hе найден хэндл файла: '+Assigned);
    Exit;
   End;
If Not (IsFileOpened(Assigned)) Then
   Begin
    CloseFile:=False;
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('!File not opened: '+GetFileObjectPointer(Assigned)^.PFileName^)
    Else
       LogWriteLn('!Файл не откpыт: '+GetFileObjectPointer(Assigned)^.PFileName^);
    Exit;
   End;
CloseFile:=_CloseFile(GetFileObjectPointer(Assigned));
{Free(GetFileObjectPointer(Assigned));}
{GetFileObjectPointer(Assigned)^.Done;}
End;

Function TFilesRecordCollection._Seek(PFileRec:PFileObject;Position:LongInt):Boolean;
Begin
 _Seek:=True;
 If PFileRec=Nil Then
   Begin
    _Seek:=False;
    LogWriteLn('!Null pointer assignment: SeekToFile');
{    RunError(204);}
    Exit;
   End;
 With PFileRec^ Do
  Begin
   If (Position>FileSize(THandle)) or (Position<0) Then
      Position:=FileSize(THandle);
   {$I-}
   System.Seek(THandle,Position);
   {$I+}
   If IOResult<>0 Then
      Begin
       _Seek:=False;
       If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
          LogWriteLn('!Can''t seek in file: '+PFileName^+', pos: '+IntToStr(Position))
       Else
          LogWriteLn('!Hе могy пеpеместить позицию в файле: '+PFileName^+', pos: '+IntToStr(Position));
       Exit;
      End;
  End;
End;

Function TFilesRecordCollection.Seek(Assigned:String;Position:LongInt):Boolean;
Begin
 Seek:=True;
 If Not (IsFileAssigned(Assigned)) Then
    Begin
     Seek:=False;
     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('!File not assigned: '+Assigned)
     Else
       LogWriteLn('!Hе найден хэндл файла: '+Assigned);
     Exit;
    End;
If Not (IsFileOpened(Assigned)) Then
   If Not (OpenFile(Assigned)) Then
      Begin
       Seek:=False;
       Exit;
      End;
Seek:=_Seek(GetFileObjectPointer(Assigned),Position);
End;

Function TFilesRecordCollection._FPos(PFileRec:PFileObject;Var FilePosition:LongInt):Boolean;
Begin
 _FPos:=True;
 FilePosition:=0;
 If PFileRec=Nil Then
   Begin
    _FPos:=False;
    LogWriteLn('!Null pointer assignment: FilePos');
{    RunError(204);}
    Exit;
   End;
With PFileRec^ Do
  Begin
   {$I-}
   FilePosition:=FilePos(THandle);
   {$I+}
   If FilePosition<0 Then
      FilePosition:=FileSize(THandle);
   If IOResult<>0 Then
    Begin
     _FPos:=False;
     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
        LogWriteLn('!Can''t get file position: '+PFileName^)
     Else
        LogWriteLn('!Hе могy полyчить позицию в файле: '+PFileName^);
     Exit;
    End;
  End;
End;

Function TFilesRecordCollection.FPos(Assigned:String;Var FilePosition:LongInt):Boolean;
Begin
 FPos:=True;
 If Not (IsFileAssigned(Assigned)) Then
    Begin
     FPos:=False;
     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
        LogWriteLn('!File not assigned: '+Assigned)
     Else
        LogWriteLn('!Hе найден хэндл файла: '+Assigned);
     Exit;
    End;
If Not (IsFileOpened(Assigned)) Then
   If Not (OpenFile(Assigned)) Then
      Begin
       FPos:=False;
       Exit;
      End;
FPos:=_FPos(GetFileObjectPointer(Assigned),FilePosition);
End;


Function TFilesRecordCollection._WriteToFile(PFileRec:PFileObject;StrToWrite:String):Boolean;
Begin
 _WriteToFile:=True;
 If PFileRec=Nil Then
   Begin
    _WriteToFile:=False;
    LogWriteLn('!Null pointer assignment: WriteToFile');
{    RunError(204);}
    Exit;
   End;
 If (StrToWrite[Length(StrToWrite)-1]<>#13) And
    (StrToWrite[Length(StrToWrite)]<>#10) Then
    StrToWrite:=StrToWrite+#13#10;
 With PFileRec^ Do
  Begin
   {$I-}
   BlockWrite(THandle,StrToWrite[1],Length(StrToWrite));
   {$I+}
   If IOResult<>0 Then
      Begin
       _WriteToFile:=False;
       If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
          LogWriteLn('!Can''t write to file: '+PFileName^)
       Else
          LogWriteLn('!Hе могy записать в файл: '+PFileName^);
       Exit;
      End;
  End;
End;

Function TFilesRecordCollection.WriteToFile(Assigned,StrToWrite:String):Boolean;
Begin
WriteToFile:=True;
If Not (IsFileAssigned(Assigned)) Then
   Begin
    WriteToFile:=False;
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
      LogWriteLn('!File not assigned: '+Assigned)
    Else
      LogWriteLn('!Hе найден хэндл файла: '+Assigned);
    Exit;
   End;
If Not (IsFileOpened(Assigned)) Then
   If Not (OpenFile(Assigned)) Then
      Begin
       WriteToFile:=False;
       Exit;
      End;
 WriteToFile:=_WriteToFile(GetFileObjectPointer(Assigned),StrToWrite);
End;

Function TFilesRecordCollection._ReadFromFile(PFileRec:PFileObject;Var StrToRead:String):Boolean;
Var
Ch:Char;
Begin
_ReadFromFile:=True;
StrToRead:='';
 If PFileRec=Nil Then
   Begin
    _ReadFromFile:=False;
    LogWriteLn('!Null pointer assignment: ReadFromFile');
{    RunError(204);}
    Exit;
   End;
With PFileRec^ Do
  Begin
{   While Not Eof(THandle) Do}
   If Not Eof(THandle) Then
    Begin
(*     {$I-}
     BlockRead(THandle,Ch,SizeOf(Ch));
     {$I+}
     If IOResult<>0 Then
        Begin
         _ReadFromFile:=False;
         If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
            LogWriteLn('!Can''t read from file: '+PFileName^)
         Else
            LogWriteLn('!Hе могy пpочитать из файла: '+PFileName^);
         Exit;
        End;
     If Ch<>#13 Then
       Begin
        If Length(StrToRead)<>255 Then
           StrToRead:=StrToRead+Ch
       End
     Else
       Begin
        {$I-}
        {new}
        BlockRead(THandle,Ch,SizeOf(Ch));
        If IOResult=0 Then;
        If Ch<>#10 Then
           System.Seek(THandle,System.FilePos(Thandle)-1);
        If IOResult=0 Then;
        {end of new}
        {$I+}
        Exit;
       End;*)
     ReadLnFromFile(THandle,StrToRead);
    End;
  End;
End;

Function TFilesRecordCollection.ReadFromFile(Assigned:String;Var StrToRead:String):Boolean;
Begin
ReadFromFile:=True;
If Not (IsFileAssigned(Assigned)) Then
   Begin
    ReadFromFile:=False;
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('!File not assigned: '+Assigned)
    Else
       LogWriteLn('!Hе найден хэндл файла: '+Assigned);
    Exit;
   End;
If Not (IsFileOpened(Assigned)) Then
   If Not (OpenFile(Assigned)) Then
      Begin
       ReadFromFile:=False;
       Exit;
      End;
ReadFromFile:=_ReadFromFile(GetFileObjectPointer(Assigned),StrToRead);
End;

Function TFilesRecordCollection._EndOfFile(PFileRec:PFileObject):Boolean;
Begin
 If PFileRec=Nil Then
   Begin
    _EndOfFile:=False;
    LogWriteLn('!Null pointer assignment: EndOfFile');
{    RunError(204);}
    Exit;
   End;
With PFileRec^ Do
 Begin
   {$I-}
  _EndOfFile:=(FilePos(THandle)>=FileSize(THandle)) or
               (FilePos(THandle)<0);
   {$I+}
   If IOResult=0 Then;
 End;
End;


Function TFilesRecordCollection.EndOfFile(Assigned:String):Boolean;
Begin
EndOfFile:=False;
If Not (IsFileAssigned(Assigned)) Then
   Begin
    EndOfFile:=True;
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('!File not assigned: '+Assigned)
    Else
       LogWriteLn('!Hе найден хэндл файла: '+Assigned);
    Exit;
   End;
If Not (IsFileOpened(Assigned)) Then
   If Not (OpenFile(Assigned)) Then
      Begin
       EndOfFile:=True;
       Exit;
      End;
EndOfFile:=_EndOfFile(GetFileObjectPointer(Assigned));
End;

Function TFilesRecordCollection.AssignFile(Assigned,Name:String):Boolean;
Begin
AssignFile:=True;
If IsFileAssigned(Assigned) Then
   Begin
    AssignFile:=False;
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('!Assignment already in use: '+Assigned)
    Else
       LogWriteLn('!Хэндл yже использyется: '+Assigned)
   End
Else
Insert(New(PFileObject,Init(
       Assigned,Name)));
End;

{Function File_Exist(S:String):Boolean;
Var
DirInfo:SearchRec;
Begin
 Dos.FindFirst(FExpand(S),AnyFile-VolumeID-Hidden,DirInfo);
 File_Exist:=DosError=0;
End;}


Function Load_Script(Name:String):Boolean;
Var
S:String;
Scr:Text;
InOutResult:Integer;
Begin
Load_Script:=True;
BodyCount:=0;
Assign(Scr,FExpand(Name));
FileMode:=$40;
{$I-}
Reset(Scr);
{$I+}
FileMode:=$42;
InOutResult:=IOResult;
If InOutResult<>0 Then
   Begin
    Load_Script:=False;
    LogWriteLn(GetExpandedString(_logCantLoadScript)+FExpand(Name));
    LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
    Exit;
   End;
If CompiledScript<>Nil Then
   Dispose(CompiledScript,Done);
{PScriptBody:=New(PTemplateBody,Init(10,5));
PScriptBody^.Duplicates:=True;}
CompiledScript:=New(PCompiledScript,Init(5,5));
While Not Eof(Scr) Do
 Begin
  ReadLn(Scr,S);
  S:=StrTrim(S);
  If (S<>'') and (S[1]<>';') Then
     Begin
{      S:=StrTrim(S);}
{       ReplaceTabsWithSpaces(S);}
{      PScriptBody^.Insert(NewStr(S));}
      PutCommandIntoCompiledScript(S);
     End;
 End;
Close(Scr);
LogWriteLn(GetExpandedString(_logStartScript)+FExpand(Name));
CurrentOperation:=GetOperationString(_logStartScript)+FExpand(Name);
End;

Function IsToken_Valid(Token:String;Source:String):Boolean;
{Var
P:PString;}
Begin
IsToken_Valid:=True;
{P:=NewStr(Token);}
If  BodyCount>CompiledScript^.Count Then
    Begin
     IsToken_Valid:=False;
     Exit;
    End;
If PCmdValidator=Nil Then
   PCmdValidator:=New(PPXPictureValidator,Init(Token,True))
  Else
   Begin
    If PCmdValidator^.Pic<>Nil Then
       Objects.DisposeStr(PCmdValidator^.Pic);
    PCmdValidator^.Pic:=MCommon.NewStr(Token);
   End;
DoUpCase:=True;
IsToken_Valid:=PCmdValidator^.IsValid(Source)=True;
{DisposeStr(P);}
{PCmdValidator^.Done;}
End;

Procedure CreateFilesCollection;
Begin
 PFilesCollection:=New(PFilesRecordCollection,Init(5,5));
End;

Function Do_AssignFile(Cmd:PScriptCommand):Boolean;
Var
 Handle,FName:String;
Begin
If PFilesCollection=Nil Then
   CreateFilesCollection;
 Handle:=PString(Cmd^.PCommandParameters^.At(0))^;
 FName:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(Handle);
 ExpandString(FName);
 PFilesCollection^.AssignFile(Handle,FName);
 Inc(BodyCount);
End;

Function Do_WriteToFile(Cmd:PScriptCommand):Boolean;
Var
Handle,Str:String;
Begin
If PFilesCollection=Nil Then
   CreateFilesCollection;
 Handle:=PString(Cmd^.PCommandParameters^.At(0))^;
 Str:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(Handle);
 ExpandString(Str);
 PFilesCollection^.WriteToFile(Handle,Str+#13#10);
 Inc(BodyCount);
End;

Function Do_ReadFromFile(Cmd:PScriptCommand):Boolean;
Var
Handle,
Variable,
StrToRead:String;
Begin
If PFilesCollection=Nil Then
   CreateFilesCollection;
 Handle:=PString(Cmd^.PCommandParameters^.At(0))^;
 Variable:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(Handle);
 ExpandString(Variable);
 PFilesCollection^.ReadFromFile(Handle,StrToRead);
 SetVarFromString(Variable,StrToRead);
 Inc(BodyCount);
End;

Function Do_SeekToFile(Cmd:PScriptCommand):Boolean;
Var
Position:LongInt;
Handle,PosStr:String;
Begin
If PFilesCollection=Nil Then
   CreateFilesCollection;
 Handle:=PString(Cmd^.PCommandParameters^.At(0))^;
 PosStr:=StrUp(PString(Cmd^.PCommandParameters^.At(1))^);
 ExpandString(Handle);
 ExpandString(PosStr);
 PosStr:=StrUp(PosStr);
 If PosStr='END' Then
    Position:=2147483647
Else
 If PosStr='BEGIN' Then
    Position:=0
Else
    Position:=StrToInt(PosStr);
 PFilesCollection^.Seek(Handle,Position);
 Inc(BodyCount);
End;

Function Do_FilePos(Cmd:PScriptCommand):Boolean;
Var
Handle,
Variable:String;
FilePosInt:LongInt;
Begin
If PFilesCollection=Nil Then
   CreateFilesCollection;
 Handle:=PString(Cmd^.PCommandParameters^.At(0))^;
 Variable:=StrUp(PString(Cmd^.PCommandParameters^.At(1))^);
 ExpandString(Handle);
 ExpandString(Variable);
 PFilesCollection^.FPos(Handle,FilePosInt);
 SetVarFromString(Variable,IntToStr(FilePosInt));
 Inc(BodyCount);
End;

Function Do_IfEndOfFile(Cmd:PScriptCommand):Boolean;
Var
Handle:String;
Begin
If PFilesCollection=Nil Then
   CreateFilesCollection;
 Handle:=PString(Cmd^.PCommandParameters^.At(0))^;
 ExpandString(Handle);
 If PFilesCollection^.EndOfFile(Handle) Then
    Begin
     Inc(BodyCount);
     Exit;
    End
  Else
    Begin
     ScrollToEndIf;
     Exit;
    End;
 Inc(BodyCount);
End;

Function Do_CloseFile(Cmd:PScriptCommand):Boolean;
Var
Handle:String;
Begin
If PFilesCollection=Nil Then
   CreateFilesCollection;
 Handle:=PString(Cmd^.PCommandParameters^.At(0))^;
 ExpandString(Handle);
 PFilesCollection^.CloseFile(Handle);
 Inc(BodyCount);
End;

Function Do_Inc(Cmd:PScriptCommand):Boolean;
Var
VarToIncStr:String;
VarValueStr:String;
NumToIncStr:String;
NumToInc:LongInt;
VarValue:LongInt;
Begin
 VarToIncStr:=PString(Cmd^.PCommandParameters^.At(0))^;
 NumToIncStr:=StrTrim(PString(Cmd^.PCommandParameters^.At(1))^);
 ExpandString(VarToIncStr);
 ExpandString(NumToIncStr);
 If NumToIncStr='' Then
    NumToInc:=1
Else
    NumToInc:=StrToInt(NumToIncStr);
 VarValueStr:=GetVar(VarToIncStr,_varNONE);
 If StrUp(VarValueStr)=StrUp(VarToIncStr) Then
    VarValue:=0
Else
    VarValue:=StrToInt(VarValueStr);
 Inc(VarValue,NumToInc);
 SetVarFromString(VarToIncStr,IntToStr(VarValue));
 Inc(BodyCount);
End;

Function Do_Dec(Cmd:PScriptCommand):Boolean;
Var
VarToDecStr:String;
VarValueStr:String;
NumToDecStr:String;
NumToDec:LongInt;
VarValue:LongInt;
Begin
 VarToDecStr:=PString(Cmd^.PCommandParameters^.At(0))^;
 NumToDecStr:=StrTrim(PString(Cmd^.PCommandParameters^.At(1))^);
 ExpandString(VarToDecStr);
 ExpandString(NumToDecStr);
 If NumToDecStr='' Then
    NumToDec:=1
Else
    NumToDec:=StrToInt(NumToDecStr);
 VarValueStr:=GetVar(VarToDecStr,_varNONE);
 If StrUp(VarValueStr)=StrUp(VarToDecStr) Then
    VarValue:=0
Else
    VarValue:=StrToInt(VarValueStr);
 Dec(VarValue,NumToDec);
 SetVarFromString(VarToDecStr,IntToStr(VarValue));
 Inc(BodyCount);
End;

Function Do_Pos(Cmd:PScriptCommand):Boolean;
Var
Source,Dest,PosChar:String;
Begin
 PosChar:=PString(Cmd^.PCommandParameters^.At(0))^;
 Source:=(PString(Cmd^.PCommandParameters^.At(1))^);
 Dest:=(PString(Cmd^.PCommandParameters^.At(2))^);
 ExpandString(PosChar);
 ExpandString(Source);
 ExpandString(Dest);
 PosChar:=StrUp(PosChar);
 Source:=StrUp(Source);
 If Dest<>'' Then
   Begin
    SetVarFromString(Dest,IntToStr(Pos(PosChar,Source)));
   End;
 Inc(BodyCount);
End;

Function Do_Copy(Cmd:PScriptCommand):Boolean;
{'COPY("[*$]","*$","*#","*#")}
Var
Source,Dest,StrPos,StrLen:String;
Begin
 Source:=PString(Cmd^.PCommandParameters^.At(0))^;
 Dest:=PString(Cmd^.PCommandParameters^.At(1))^;
 StrPos:=StrTrim(PString(Cmd^.PCommandParameters^.At(2))^);
 StrLen:=StrTrim(PString(Cmd^.PCommandParameters^.At(3))^);
 ExpandString(Source);
 ExpandString(Dest);
 ExpandString(StrPos);
 ExpandString(StrLen);
 If Dest<>'' Then
    Begin
     SetVarFromString(Dest,Copy(Source,StrToInt(StrPos),StrToInt(StrLen)));
    End;
 Inc(BodyCount);
End;

Function Do_Assigment(Cmd:PScriptCommand):Boolean;
Var
Param,Value:String;
Begin
 Param:=(StrTrim(PString(Cmd^.PCommandParameters^.At(0))^));
 Value:=(StrTrim(PString(Cmd^.PCommandParameters^.At(1))^));
 ExpandString(Param);
 ExpandString(Value);
 Param:=StrUp(Param);
 SetVarFromString(Param,Value);
 Inc(BodyCount);
End;

Function Do_LogWriteLn(Cmd:PScriptCommand):Boolean;
Var
LStr:String;
Begin
 LStr:=PString(Cmd^.PCommandParameters^.At(0))^;
 ExpandString(LStr);
 LogWriteLn(LStr);
 Inc(BodyCount);
End;


Function Do_CopyFile(Cmd:PScriptCommand):Boolean;
Var
DirInfo:SearchRec;
Source,Dest:String;
Dir:DirStr;
Name:NameStr;
Ext:ExtStr;
Begin
 Source:=(StrUp(PString(Cmd^.PCommandParameters^.At(0))^));
 Dest:=(StrUp(PString(Cmd^.PCommandParameters^.At(1))^));
 ExpandString(Source);
 ExpandString(Dest);
 Source:=FExpand(Source);
 Dest:=FExpand(Dest);
 FSplit(Source,Dir,Name,Ext);
 FindFirstEx(Source,AnyFile-Directory-VolumeID-ReadOnly-Hidden,DirInfo);
 While (DosError=0) Do
   Begin
    If DosErrorEx=0 Then
       Begin
            CopyFile(Dir+DirInfo.Name,Dest,(Cmd^.TCommandType=_cmdMoveFile));
       End;
    FindNextEx(DirInfo);
   End;
 FindCloseEx(DirInfo);
 Inc(BodyCount);
End;

Procedure LogWriteDosError(ErrorCode:Integer;LogString:String);
Begin
  {$IFNDEF SPLE}
  LogWriteLn(GetExpandedString(LogString)+GetErrorString(ErrorCode));
  {$ENDIF}
End;


Procedure BeforeExec;
Begin
{  DoneSysError;}
  DoneEvents;
  DoneVideo;
  DoneDosMem;
End;

Procedure AfterExec;
Begin
  InitDosMem;
  InitVideo;
  InitEvents;
{  InitSysError;}
  {Redraw;}
End;

Function Do_Dos_Exec(Cmd:PScriptCommand):Boolean;
Var
Old1CInt:Pointer;
FName:String;
Params:String;
ExecResult:Integer;
{$IFNDEF DPMI}
SwapFileName:String;
{$ENDIF}
Begin
 FName:=PString(Cmd^.PCommandParameters^.At(0))^;
 Params:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(FName);
 ExpandString(Params);
 LogWriteLn(GetExpandedString(_logExecuting)+GetEnv('COMSPEC')+' /C '+FName+' '+Params);
 SwapVectors;
{$IFNDEF MSDOS}
  DoneScreen;
  BeforeExec;
  ClrScr;
  Exec(GetEnv('COMSPEC'),' /C '+FName+' '+Params);
  ExecResult:=DosError;
{$ELSE}
 SwapFileName:='$PM'+GetVar(TaskNumberTag.Tag,_varNONE)+'$.SWP';
 If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
    LogWriteLn('#Swapping to EMS/DISK')
 Else
    LogWriteLn('#Своп в EMS/DISK');
 If PrepareExecWithSwap(Ptr($ffff,0),SwapFileName) Then
   Begin
    DoneScreen;
    BeforeExec;
    ClrScr;
    ExecWithSwap(GetEnv('COMSPEC'),' /C '+FName+' '+Params);
    ExecResult:=DosError;
    RemoveExecWithSwap;
   End
 Else
   Begin
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('!Error while swapping')
    Else
       LogWriteLn('!Ошибка пpи свопе');
    SetVar(ErrorLevelTag,'255');
    Inc(BodyCount);
    Exit;
   End;
{$ENDIF}
 SwapVectors;
 AfterExec;
 InitializeScreen;
 PreUpdateScreen;
 SetVar(ErrorLevelTag,IntToStr(DosExitCode));
 Case ExecResult Of
      0:LogWriteLn(GetExpandedString(_logExitCode));
      1:LogWriteLn(GetExpandedString(_logDosErrorOnExec)+'error mapping EMS device/accessign swap file');
      2..32767:LogWriteDosError(ExecResult,GetExpandedString(_logDosErrorOnExec));
 End;
{ If DosError<>0 Then
    LogWriteDosError(DosError,GetExpandedString(_logDosErrorOnExec))
 Else
    LogWriteLn(GetExpandedString(_logExitCode));}
 Inc(BodyCount);
End;

Function Do_Exec(Cmd:PScriptCommand):Boolean;
Var
Old1CInt:Pointer;
FName,Params:String;
ExecResult:Integer;
{$IFNDEF DPMI}
SwapFileName:String;
{$ENDIF}
Begin
 FName:=PString(Cmd^.PCommandParameters^.At(0))^;
 Params:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(FName);
 ExpandString(Params);
 If Not IsFileExist(FName) Then
     FName:=FindFile(FName);
 LogWriteLn(GetExpandedString(_logExecuting)+FName+' '+ Params);
 SwapVectors;
{$IFNDEF MSDOS}
  DoneScreen;
  BeforeExec;
  ClrScr;
  Exec(FName,' '+ Params);
  ExecResult:=DosError;
{$ELSE}
 SwapFileName:='$PM'+GetVar(TaskNumberTag.Tag,_varNONE)+'$.SWP';
 If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
    LogWriteLn('#Swapping to EMS/DISK')
 Else
    LogWriteLn('#Своп в EMS/DISK');
 If PrepareExecWithSwap(Ptr($ffff,0),SwapFileName) Then
   Begin
    DoneScreen;
    BeforeExec;
    ClrScr;
    ExecWithSwap(FName,+' '+ Params);
    ExecResult:=DosError;
    RemoveExecWithSwap;
   End
 Else
   Begin
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('!Error while swapping')
    Else
       LogWriteLn('!Ошибка пpи свопе');
    SetVar(ErrorLevelTag,'255');
    Inc(BodyCount);
    Exit;
   End;
{$ENDIF}
 SwapVectors;
 AfterExec;
 InitializeScreen;
 PreUpdateScreen;
 SetVar(ErrorLevelTag,IntToStr(DosExitCode));
 Case ExecResult Of
      0:LogWriteLn(GetExpandedString(_logExitCode));
      1:LogWriteLn(GetExpandedString(_logDosErrorOnExec)+'error mapping EMS device/accessign swap file');
      2..32767:LogWriteDosError(ExecResult,GetExpandedString(_logDosErrorOnExec));
 End;

{ If DosError<>0 Then
     LogWriteDosError(DosError,GetExpandedString(_logDosErrorOnExec))
 Else
    LogWriteLn(GetExpandedString(_logExitCode));}

 Inc(BodyCount);
End;

Function Do_CreateMsg(Cmd:PScriptCommand):Boolean;
{
P:private;
C:crash;
S:Sent;
R:received
A:attach
T:intransit;
O:orphan
K:killsent
L:local;
H:hold;
F:freq

}
Var
Attr:Word;
AttrStr:String;
ToName,FromName:String;
ToAddrStr,FromAddrStr:String;
ToAddr,FromAddr:TAddress;
Subj:String;
Count:Word;
Begin
 Attr:=0;
 _MsgWasCreated:=False;
 ToAddrStr:=StrTrim(PString(Cmd^.PCommandParameters^.At(0))^);
 FromAddrStr:=StrTrim(PString(Cmd^.PCommandParameters^.At(1))^);
 ToName:=Strtrim(PString(Cmd^.PCommandParameters^.At(2))^);
 FromName:=StrTrim(PString(Cmd^.PCommandParameters^.At(3))^);
 Subj:=StrTrim(PString(Cmd^.PCommandParameters^.At(4))^);
 AttrStr:=StrTrim(PString(Cmd^.PCommandParameters^.At(5))^);
 ExpandString(ToAddrStr);
 ExpandString(FromAddrStr);
 ExpandString(ToName);
 ExpandString(FromName);
 ExpandString(Subj);
 ExpandString(AttrStr);
 For Count:=1 To Length(AttrStr) Do
  Begin
   Case UpCase(AttrStr[Count]) Of
      'P':Attr:=Attr or _attrPrivate;
      'C':Attr:=Attr or _attrCrash;
      'R':Attr:=Attr or _attrReceived;
      'S':Attr:=Attr or _attrSent;
      'A':Attr:=Attr or _attrAttach;
      'T':Attr:=Attr or _attrInTransit;
      'O':Attr:=Attr or _attrOrphan;
      'K':Attr:=Attr or _attrKillSent;
      'L':Attr:=Attr or _attrLocal;
      'H':Attr:=Attr or _attrHold;
      'F':Attr:=Attr or _attrFRQ;
    End;
  End;
 SetAddressFromString(ToAddrStr,ToAddr);
 SetAddressFromString(FromAddrStr,FromAddr);
 If IsCreateMessage(GetVar(NetMailPathtag.Tag,_varNONE),ToAddr,FromAddr,
                   ToName,FromName,Subj,Attr) Then
    Begin
    _MsgWasCreated:=True;
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn('#Created message for '+ToName+' ['+ToAddrStr+'] from '+FromName+
                     ' ['+FromAddrStr+']')
    Else
       LogWriteLn('#Создано письмо для '+ToName+' ['+ToAddrStr+'] от '+FromName+
                     ' ['+FromAddrStr+']')
    End
 Else
    Begin
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
      LogWriteLn('!Can''t create message for '+ToName+' ['+ToAddrStr+'] from '+FromName+
                     ' ['+FromAddrStr+']')
    Else
      LogWriteLn('!Hе могy создать письмо от '+ToName+' ['+ToAddrStr+'] к '+FromName+
                     ' ['+FromAddrStr+']');
    End;
 Inc(BodyCount);
End;

Function Do_WriteToMsg(Cmd:PScriptCommand):Boolean;
Var
MsgStr:String;
Begin
 MsgStr:=PString(Cmd^.PCommandParameters^.At(0))^;
 ExpandString(MsgStr);
 If MsgStr[Length(MsgStr)]=#10 Then
    Delete(MsgStr,Length(MsgStr),1);
 If MsgStr[Length(MsgStr)]=#13 Then
    Delete(MsgStr,Length(MsgStr),1);
 If _MsgWasCreated Then
    Begin
     WriteToMessage(MsgStr);
    End
 Else
    Begin
     LogWriteLn(GetExpandedString(_logWriteToNonOpenedMessage));
    End;
 Inc(BodyCount);
End;

Function Do_CloseMsg(Cmd:PScriptCommand):Boolean;
Begin
If _MsgWasCreated Then
   Begin
    CloseMessage;
   End
Else
   Begin
     LogWriteLn(GetExpandedString(_logTryingToCloseNonOpenedMessage));
   End;
 Inc(BodyCount);
End;


Procedure ScrollToEndIf;
Var
PCmd:PScriptCommand;
NumCircle:Word;
{NumElse:Word;}
Begin
NumCircle:=0;
Inc(BodyCount);
While ((BodyCount<CompiledScript^.Count)) Do
  Begin
   PCmd:=(CompiledScript^.At(BodyCount));
   Case PCmd^.TCommandType Of
      _cmdIf_Then,
      _cmdIf_Exist,
      _cmdIf_EndOfFile:Inc(NumCircle);
      _cmdElse:
               Begin
                If NumCircle>0 Then
                   Begin
                   End
               Else
                   Begin
                    Inc(BodyCount);
                    Break;
                   End;
               End;
      _cmdEndIf:
               Begin
                If NumCircle>0 Then
                   Dec(NumCircle)
               Else
                  Begin
                   Inc(BodyCount);
                   Break;
                  End;
               End;

   End;{case}
   Inc(BodyCount);
  End;
End;

Function Do_Goto(Cmd:PScriptCommand):Boolean;
Var
Lbl:String;
Count:Word;
_IsLabelFound:Boolean;
BeginPos,EndPos:Byte;
Cmd2:PScriptCommand;
Begin
Do_Goto:=True;
_IsLabelFound:=False;
 Lbl:=StrUp(StrTrim(PString(Cmd^.PCommandParameters^.At(0))^))+':';
 ExpandString(Lbl);
For Count:=0 To Pred(CompiledScript^.Count) Do
   Begin
    Cmd2:=CompiledScript^.At(Count);
    If Cmd2^.TCommandType=_cmdLabel Then
     Begin
      If StrUp(StrTrim(PString(Cmd2^.PCommandParameters^.At(0))^))=Lbl Then
         Begin
          _IsLabelFound:=True;
          BodyCount:=Count;
          Break;
         End;
     End;
   End;
If Not _IsLabelFound Then
  Begin
   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
      LogWriteLn('!Label not found: '+Lbl)
   Else
      LogWriteLn('!Метка не найдена: '+Lbl);
  End;
 Inc(BodyCount);
End;

Function Do_If_Then(Cmd:PScriptCommand):Boolean;
Var
Operation:String;
LeftVar,RightVar:String;
Begin
 LeftVar:=(StrTrim(PString(Cmd^.PCommandParameters^.At(0))^));
 RightVar:=(StrTrim(PString(Cmd^.PCommandParameters^.At(1))^));
 Operation:=StrTrim(PString(Cmd^.PCommandParameters^.At(2))^);
 ExpandString(LeftVar);
 ExpandString(RightVar);
 ExpandString(Operation);
 While (LeftVar[1]='0') And (LeftVar[2]<>'.') And (Length(LeftVar)<>1) Do
   Delete(LeftVar,1,1);
 While (RightVar[1]='0') And (RightVar[2]<>'.')  And (Length(RightVar)<>1) Do
   Delete(RightVar,1,1);
 LeftVar:=StrUp(LeftVar);
 RightVar:=StrUp(RightVar);
 If Operation='=' Then
    Begin
       Begin
         If LeftVar=RightVar Then
            Begin
             Inc(BodyCount);
             Exit;
            End
         Else
            Begin
             ScrollToEndIf;
             Exit;
            End;
       End;
    End
Else
 If Operation='>' Then
    Begin
       Begin
         If LeftVar>RightVar Then
            Begin
             Inc(BodyCount);Exit;
            End
         Else
            Begin
             ScrollToEndIf;
             Exit;
            End;
       End;
    End
Else
 If Operation='<' Then
    Begin
       Begin
         If LeftVar<RightVar Then
            Begin
             Inc(BodyCount);Exit;
            End
         Else
            Begin
             ScrollToEndIf;
             Exit;
            End;
       End;
    End
Else
 If Operation='<>' Then
    Begin
       Begin
         If LeftVar<>RightVar Then
            Begin
             Inc(BodyCount);Exit;
            End
         Else
            Begin
             ScrollToEndIf;
             Exit;
            End;
       End;
    End
Else
 Inc(BodyCount);
End;

Function Do_If_Exist(Cmd:PScriptCommand):Boolean;
Var
FileName:String;
Begin
 Do_If_Exist:=True;
 FileName:=StrUp(Strtrim(PString(Cmd^.PCommandParameters^.At(0))^));
 ExpandString(FileName);
 If IsFileOrDirectoryExist(FileName) Then
    Begin
     Inc(BodyCount);
     Exit;
    End
Else
 Begin
  ScrollToEndIf;
 End;
End;

Function Do_Exit(Cmd:PScriptCommand):Boolean;
Begin
 LogWriteLn(GetExpandedString(_logExitByCommand));
 BodyCount:=CompiledScript^.Count;
End;

Procedure Do_EnableScreenHandler(Cmd:PScriptCommand);
Begin
 {SetScreenHandler;}
 Inc(BodyCount);
End;

Procedure Do_DisableScreenHandler(Cmd:PScriptCommand);
Begin
 {RestoreScreenHandler;}
 Inc(BodyCount);
End;

Procedure Do_NotProcess(Cmd:PScriptCommand);
Var
SStr:String;
Begin
 SStr:=PString(Cmd^.PCommandParameters^.At(0))^;
 ExpandString(SStr);
 Inc(BodyCount);
End;

Procedure Do_StringLength(Cmd:PScriptCommand);
Var
StrToGetLen,
Variable:String;
Begin
 StrToGetLen:=PString(Cmd^.PCommandParameters^.At(0))^;
 Variable:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(StrToGetLen);
 ExpandString(Variable);
 SetVarFromString(Variable,IntToStr(Length(StrToGetLen)));
 Inc(BodyCount);
End;

Procedure Do_StringUp(Cmd:PScriptCommand);
Var
StrToUp,
Variable:String;
Begin
 StrToUp:=PString(Cmd^.PCommandParameters^.At(0))^;
 Variable:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(StrToUp);
 ExpandString(Variable);
 SetVarFromString(Variable,StrUp(StrToUp));
 Inc(BodyCount);
End;

Procedure Do_StringDown(Cmd:PScriptCommand);
Var
StrToDown,
Variable:String;
Begin
 StrToDown:=PString(Cmd^.PCommandParameters^.At(0))^;
 Variable:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(StrToDown);
 ExpandString(Variable);
 SetVarFromString(Variable,StrDown(StrToDown));
 Inc(BodyCount);
End;

Procedure Do_StringTrim(Cmd:PScriptCommand);
Var
Source,Dest:String;
Begin
 Source:=PString(Cmd^.PCommandParameters^.At(0))^;
 Dest:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(Source);
 ExpandString(Dest);
 SetVarFromString(Dest,StrTrim(Source));
 Inc(BodyCount);
End;

Procedure Do_LeftStringTrim(Cmd:PScriptCommand);
Var
Source,Dest:String;
Begin
 Source:=PString(Cmd^.PCommandParameters^.At(0))^;
 Dest:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(Source);
 ExpandString(Dest);
 SetVarFromString(Dest,PadLeft(Source));
 Inc(BodyCount);
End;

Procedure Do_RightStringTrim(Cmd:PScriptCommand);
Var
Source,Dest:String;
Begin
 Source:=PString(Cmd^.PCommandParameters^.At(0))^;
 Dest:=PString(Cmd^.PCommandParameters^.At(1))^;
 ExpandString(Source);
 ExpandString(Dest);
 SetVarFromString(Dest,PadRight(Source));
 Inc(BodyCount);
End;

Function Exec_Script:Boolean;
Var
Cmd:PScriptCommand;
Begin
Exec_Script:=True;
BodyCount:=0;
While (True) Do
 Begin
  If BodyCount>=CompiledScript^.Count Then
     Exit;
  Cmd:=(CompiledScript^.At(BodyCount));
    Case Cmd^.TCommandType Of
       _cmdEndIf,
       _cmdUnknown,
       _cmdLabel,
       _cmdReserved..65534: Inc(BodyCount);
       _cmdIf_Then:      Do_If_Then(Cmd);
       _cmdIf_Exist:     Do_If_Exist(Cmd);
       _cmdElse:         ScrollToEndIf;
       _cmdLogWriteLn:   Do_LogWriteLn(Cmd);
       _cmdAssign:       Do_Assigment(Cmd);
       _cmdCopy:         Do_Copy(Cmd);
       _cmdPos:          Do_Pos(Cmd);
       _cmdCopyFile:     Do_CopyFile(Cmd{,False});
       _cmdMoveFile:     Do_CopyFile(Cmd{,True});
       _cmdAssignFile:   Do_AssignFile(Cmd);
       _cmdWriteToFile:  Do_WriteToFile(Cmd);
       _cmdReadFromFile: Do_ReadFromFile(Cmd);
       _cmdSeekToFile:   Do_SeekToFile(Cmd);
       _cmdFilePos:      Do_FilePos(Cmd);
       _cmdIf_EndOfFile: Do_IfEndOfFile(Cmd);
       _cmdCloseFile:    Do_CloseFile(Cmd);
       _cmdInc:          Do_Inc(Cmd);
       _cmdDec:          Do_Dec(Cmd);
       _cmdDos_Exec:     Do_Dos_Exec(Cmd);
       _cmdExec:         Do_Exec(Cmd);
       _cmdCreateMsg:    Do_CreateMsg(Cmd);
       _cmdWriteToMsg:   Do_WriteToMsg(Cmd);
       _cmdCloseMsg:     Do_CloseMsg(Cmd);
       _cmdGoto:         Do_Goto(Cmd);
       _cmdExit:         Do_Exit(Cmd);
       _cmdNotProcess:   Do_NotProcess(Cmd);
{       _cmdEnableScreenHandler: Do_EnableScreenHandler(Cmd);
       _cmdDisableScreenHandler: Do_DisableScreenHandler(Cmd);}
       _cmdStringLength: Do_StringLength(Cmd);
       _cmdStringUp:     Do_StringUp(Cmd);
       _cmdStringDown:   Do_StringDown(Cmd);
       _cmdStringTrim:       Do_StringTrim(Cmd);
       _cmdLeftStringTrim:   Do_LeftStringTrim(Cmd);
       _cmdRightStringTrim:  Do_RightStringTrim(Cmd);
    End;{case}
  {Inc(BodyCount);}
 End;
End;

Procedure Done_Script;
Begin
{SetScreenHandler;}
LogWriteLn(GetExpandedString(_logDoneScript));
{If PScriptBody<>Nil Then
  Begin
   Dispose(PScriptBody,Done);
   PScriptBody:=Nil;
  End;}
If PFilesCollection<>Nil Then
   Begin
    Dispose(PFilesCollection,Done);
    PFilesCollection:=Nil
   End;
If PCmdValidator<>Nil Then
  Begin
   Dispose(PCmdValidator,Done);
   PCmdValidator:=Nil;
  End;
If CompiledScript<>Nil Then
  Begin
   Dispose(CompiledScript,Done);
   CompiledScript:=Nil;
  End;
End;

Begin
_MsgWasCreated:=False;
 PFilesCollection:=Nil;
 PCmdValidator:=Nil;
{ PScriptBody:=Nil;}
 CompiledScript:=Nil;
End.
