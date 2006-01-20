UNIT Check;

INTERFACE
Uses
{$IFDEF VIRTUALPASCAL}
Use32,
{$ENDIF}
Parser,Incl,Logger,Objects,Dos,StrUnit,MCommon,FileIO;

Var
InvalidFile,
InvalidPath:Boolean;

Function CheckFileNamesAndPath:Boolean;
Procedure RemoveDupeSlash(Var S:String);

IMPLEMENTATION

{function DriveValid(Drive: Char): Boolean; near; assembler;
asm
        MOV     AH,19H
        INT     21H
        MOV     BL,AL
        MOV     DL,Drive
        SUB     DL,'A'
        MOV     AH,0EH
        INT     21H
        MOV     AH,19H
        INT     21H
        MOV     CX,0
        CMP     AL,DL
        JNE     @@1
        MOV     CX,1
        MOV     DL,BL
        MOV     AH,0EH
        INT     21H
@@1:    XCHG    AX,CX
end;


function PathValid(Path: PathStr): Boolean;
var
  ExpPath: PathStr;
  SR: SearchRec;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;

begin
  FSplit(Path,Dir,Name,Ext);
  Path:=Dir;
  ExpPath := FExpand(Path);
  if Length(ExpPath) <= 3 then PathValid := DriveValid(ExpPath[1])
  else
  begin
    if ExpPath[Length(ExpPath)] = '\' then Dec(ExpPath[0]);
    FindFirst(ExpPath, Directory, SR);
    PathValid := (DosError = 0) and (SR.Attr and Directory <> 0);
  end;
end;


function ValidFileName(FileName: PathStr): Boolean;
const
  IllegalChars = ';,=+<>|"[] \';
var
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;

function Contains(S1, S2: String): Boolean; near; assembler;
asm
        PUSH    DS
        CLD
        LDS     SI,S1
        LES     DI,S2
        MOV     DX,DI
        XOR     AH,AH
        LODSB
        MOV     BX,AX
        OR      BX,BX
        JZ      @@2
        MOV     AL,ES:[DI]
        XCHG    AX,CX
@@1:    PUSH    CX
        MOV     DI,DX
        LODSB
        REPNE   SCASB
        POP     CX
        JE      @@3
        DEC     BX
        JNZ     @@1
@@2:    XOR     AL,AL
        JMP     @@4
@@3:    MOV     AL,1
@@4:    POP     DS
end;

{Function FileExist(Name:String):Boolean;
Var
SR:SearchRec;
Begin
FileExist:=True;
FindFirst(Name,AnyFile-Directory,Sr);
FileExist:=DosError=0;
End;}


{
begin
  ValidFileName := True;
  FSplit(FileName, Dir, Name, Ext);
  if not ((Dir = '') or PathValid(Dir)) {or (Not FileExist(FExpand(FileName)))} {or Contains(Name, IllegalChars) or
 {   Contains(Dir, IllegalChars) then ValidFileName := False;
end;}




{Procedure ForEachFile(Point:Pointer);Far;
Var
PStr:PString absolute Point;
Begin
If InvalidFile Then
   Exit;
If Not (ValidFileName(PStr^)) Then
  Begin
   InvalidFile:=True;
   LogWriteLn(GetMakingString(_logInvalidFileName+' '+PStr^));
  End;
End;}

Procedure ReportInvalidDir(Path:String);
  Begin
    LogWriteLn(GetExpandedString(_logInvalidPath+' '+Path));
  End;

Procedure ReportInvalidFile(Path:String);
  Begin
    LogWriteLn(GetExpandedString(_logInvalidFileName+' '+Path));
  End;

Procedure RemoveDupeSlash(Var S:String);
 Var
  SlashPos:Word;
  Begin
   If S='' Then
      Exit;
{$IFDEF LINUX}
   SlashPos:=Pos('//',S);
   While SlashPos>0 Do
     Begin
      Delete(S,SlashPos,1);
      SlashPos:=Pos('//',S);
     End;
   SlashPos:=Pos('\',S);
   While SlashPos>0 Do
     Begin
      Delete(S,SlashPos,1);
      Insert('/',S,SlashPos);
      SlashPos:=Pos('\',S);
     End;
{$ELSE}
   SlashPos:=Pos('\\',S);
   While SlashPos>0 Do
     Begin
      Delete(S,SlashPos,1);
      SlashPos:=Pos('\\',S);
     End;
   SlashPos:=Pos('/',S);
   While SlashPos>0 Do
     Begin
      Delete(S,SlashPos,1);
      Insert('\',S,SlashPos);
      SlashPos:=Pos('/',S);
     End;
{$ENDIF}
  End;

Procedure AddBackSlash(Var S:String);
Begin
{$IFDEF LINUX}
 If S[Length(S)]<>'/' Then
    S:=S+'/';
{$ELSE}
 If S[Length(S)]<>'\' Then
    S:=S+'\';
{$ENDIF}
End;

Procedure ForEachFile(Point:Pointer);Far;
Var
PStr:PString;
Begin
 If InvalidFile Then
    Exit;
   PStr:=PString(Point);
   PStr^:=StrTrim(PStr^);
   RemoveDupeSlash(PStr^);
 If Not (IsFileExist(PStr^)) Then
    Begin
     InvalidFile:=True;
     ReportInvalidFile(PStr^);
     Exit;
    End;
End;

Procedure PreForEachPath(Point:Pointer);Far;
Var
PStr:PString;
Begin
   PStr:=PString(Point);
   PStr^:=StrTrim(PStr^);
   AddBackSlash(PStr^);
End;

Procedure ForEachPath(Point:Pointer);Far;
Var
PStr:PString;
Dir:DirStr;
Name:NameStr;
Ext:ExtStr;
Begin
If InvalidPath Then
   Exit;
   PStr:=PString(Point);
   PStr^:=StrTrim(PStr^);
   RemoveDupeSlash(PStr^);
   If PStr^[Length(PStr^)]='\' Then
      Begin
       If Not (IsDirectoryExist(Copy(PStr^,1,Length(PStr^)-1))) Then
          Begin
           InvalidPath:=True;
           ReportInvalidDir(PStr^);
           Exit;
          End;
       Exit;
      End;
   FSplit(PStr^,Dir,Name,Ext);
   If Not (IsDirectoryExist(Copy(Dir,1,Length(Dir)-1))) Then
      Begin
       InvalidPath:=True;
       ReportInvalidDir(Copy(Dir,1,Length(Dir)-1));
       Exit;
      End;
{   If Not (IsFileExist(Dir+Name+Ext)) Then
      Begin
       InvalidPath:=True;
       ReportInvalidFile(Dir+Name+Ext);
       Exit;
      End;}
{   InvalidPath:=True;
   LogWriteLn(GetExpandedString(_logInvalidPath+' '+PStr^));}
End;

Function CheckFileNamesAndPath:Boolean;
Begin
 CheckFileNamesAndPath:=True;
 {InvalidFile:=False;}
 InvalidPath:=False;
 ForEachVar(MasterLogNameTag.Tag,ForEachPath);
{ ForEachVar(MasterLogNameTag.Tag,ForEachFile);}
 ForEachVar(StatFileNameTag.Tag,ForEachPath);
{ ForEachVar(StatFileNameTag.Tag,ForEachFile);}

 ForEachVar(NetMailPathTag.Tag,PreForEachPath);
 ForEachVar(NetMailPathTag.Tag,ForEachPath);

 ForEachVar(BusyFlagNameTag.Tag,ForEachPath);
{ ForEachVar(BusyFlagNameTag.Tag,ForEachFile);}
 If StrTrim(GetVar(FileAttachPathTag.Tag,_varNONE))<>'' Then
    Begin
     ForEachVar(FileAttachPathTag.Tag,PreForEachPath);
     ForEachVar(FileAttachPathTag.Tag,ForEachPath);
{     ForEachVar(FileAttachPathTag.Tag,ForEachFile);}
    End;
 If StrTrim(GetVar(ProcessedMessagePathTag.Tag,_varNONE))<>'' Then
    Begin
     ForEachVar(ProcessedMessagePathTag.Tag,PreForEachPath);
     ForEachVar(ProcessedMessagePathTag.Tag,ForEachPath);
    End;
{ ForEachVar(ProcessedMessagePathTag.Tag,ForEachPath);}

 ForEachVar(_tplAllDone.Tag,ForEachPath);
 ForEachVar(_tplAllDone.Tag,ForEachFile);

 ForEachVar(_tplNotAllowForPoint.Tag,ForEachPath);
 ForEachVar(_tplNotAllowForPoint.Tag,ForEachFile);

 ForEachVar(_tplCantChangeAnotherBoss.Tag,ForEachPath);
 ForEachVar(_tplCantChangeAnotherBoss.Tag,ForEachFile);

 ForEachVar(_tplDoneSegRequest.Tag,ForEachPath);
 ForEachVar(_tplDoneSegRequest.Tag,ForEachFile);

 ForEachVar(_tplDoneHelpRequest.Tag,ForEachPath);
 ForEachVar(_tplDoneHelpRequest.Tag,ForEachFile);

 ForEachVar(_tplStatisticRequest.Tag,ForEachPath);
 ForEachVar(_tplStatisticRequest.Tag,ForEachFile);

 ForEachVar(_tplErrorsInMessage.Tag,ForEachPath);
 ForEachVar(_tplErrorsInMessage.Tag,ForEachFile);

 ForEachVar(_tplErrorsInPointList.Tag,ForEachPath);
 ForEachVar(_tplErrorsInPointList.Tag,ForEachFile);

 ForEachVar(_tplBadPassword.Tag,ForEachPath);
 ForEachVar(_tplBadPassword.Tag,ForEachFile);

 ForEachVar(_tplInBounceList.Tag,ForEachPath);
 ForEachVar(_tplInBounceList.Tag,ForEachFile);

 ForEachVar(_tplReRoute.Tag,ForEachPath);
 ForEachVar(_tplReRoute.Tag,ForEachFile);

 ForEachVar(_tplInExcludeList.Tag,ForEachPath);
 ForEachVar(_tplInExcludeList.Tag,ForEachFile);

 ForEachVar(_tplErrorsInSegment.Tag,ForEachPath);
 ForEachVar(_tplErrorsInSegment.Tag,ForEachFile);

 If InvalidPath or InvalidFile Then
    CheckFileNamesAndPath:=False;
End;

Begin
End.