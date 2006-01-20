Unit FileIO;

{$I VERSION.INC}

INTERFACE
Uses
{$IFDEF VIRTUALPASCAL}
 Use32,
{$ENDIF}
 Dos,Incl,Parser,StrUnit,Strings,Validate,Objects;

Function TextFileSize(Var F:Text):LongInt;
Function IsFileExist(S:String):Boolean;
Function IsDirectoryExist(S:String):Boolean;
Function IsFileOrDirectoryExist(S:String):Boolean;
Function IsFileOrDirectoryExistEx(S:String):Boolean;
Function FindFile(S:String):String;
Procedure ChangeToCurrentDirectory;
Procedure ChangeToLastDirectory;
Function GetFileTimeStamp(FName:String):LongInt;
Function GetFileSize(FName:String):LongInt;
Function FileCopyBuf(Source,Dest : PathStr;
                       BufPtr : Pointer; BufferSize : Word;IsMove:Boolean;WriteLog:Boolean) : Word;
Function FileCopy(Source,Dest : PathStr; BufferSize : Word;IsMove:Boolean;WriteLog:Boolean) : Word;
Procedure CopyFile(Source,Dest:String;IsMove:Boolean);
Function CreateDir(D:PathStr):Boolean;
Function CreateDirWithSubDirs(Path:PathStr):Boolean;
Procedure FindFirstEx(Path: PathStr; Attr: Word; var F: SearchRec);
Procedure FindNextEx(var F: SearchRec);
Procedure FindCloseEx(var F: SearchRec);
{*** begin fileIO wrapper ***}
Function ResetUnTypedFile(Var F:File;RecSize:Word):Boolean;
Function ResetTypedFile(Var F;RecSize:Word):Boolean;
Function ResetTextFile(Var F:Text):Boolean;

Function RewriteUnTypedFile(Var F:File;RecSize:Word):Boolean;
Function RewriteTypedFile(Var F;RecSize:Word):Boolean;
Function RewriteTextFile(Var F:Text):Boolean;

Function CloseUnTypedFile(Var F:File):Boolean;
Function CloseTypedFile(Var F):Boolean;
Function CloseTextFile(Var F:Text):Boolean;

Function WriteLnToTextFile(Var F:Text;S:String):Boolean;
Function ReadLnFromTextFile(Var F:Text;Var S:String):Boolean;

Function BlockWriteToUnTypedFile(Var F:File;Var Buf;Count:Word):Boolean;
Function BlockReadFromUnTypedFile(Var F:File;Var Buf;Count:Word):Boolean;

Function BlockWriteToUnTypedFileEx(Var F:File;Var Buf;Count:Word;Var _Result:Word):Boolean;
Function BlockReadFromUnTypedFileEx(Var F:File;Var Buf;Count:Word;Var _Result:Word):Boolean;

Function SeekUnTypedFile(Var F:File;N:LongInt):Boolean;

{*** end fileIO wrapper ***}
IMPLEMENTATION

Uses Logger
     {$IFNDEF SPLE}
     ,Script
     {$ENDIF};

Var
LastDirectory:String;

Function CreateDir(D:PathStr):Boolean;
Var
 InOutResult:   Integer;
Begin
  CreateDir:=True;
  If D[Length(D)]='\' Then
     Delete(D,Length(D),1);
  If ((D<>'') And (D<>'\') And (D<>'.\')) And (Not IsFileOrDirectoryExist(D)) Then
       Begin
        {$I-}
        MkDir(D);
        {$I+}
        InOutResult:=IOResult;
        If InOutResult<>0 Then
           Begin
            If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
               LogWriteLn(GetExpandedString(_logCantCreateFile)+D+' (directory)')
            Else
               LogWriteLn(GetExpandedString(_logCantCreateFile)+D+' (диpектоpия)');
               {$IFNDEF SPLE}
               LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
               {$ENDIF}
               CreateDir:=False;
               Exit;
            End;
       End;
End;


Function CreateDirWithSubDirs(Path:PathStr):Boolean;
{.\dgdg\dgf\dfhf\fs.ext}
Var
 Dir:           DirStr;
 N:             NameStr;
 E:             ExtStr;
 InOutResult:   Integer;
 BeginPos,
 EndPos:        Byte;
Begin
 CreateDirWithSubDirs:=True;
 SplitFileName(Path,Dir,N,E);
 If (Dir<>'') And (Dir<>'\') And (Dir<>'.\') Then
  Begin
    BeginPos:=Pos('\',Dir);
    While BeginPos>0 Do
          Begin
               If (Not CreateDir(Copy(Dir,1,BeginPos-1))) Then
                  Begin
                   BeginPos:=0;
                   CreateDirWithSubDirs:=True;
                   Break;
                  End;
               EndPos:=Pos('\',Copy(Dir,BeginPos+1,Length(Dir)-BeginPos));
               If EndPos>0 Then
                  BeginPos:=BeginPos+EndPos
               Else
                  BeginPos:=0;
          End;
  End;
End;



{$IFDEF VIRTUALPASCAL}
Function TextFileSize(Var F:Text):LongInt;
Var
DirInfo:SearchRec;
Counter:Byte;
TTR:TextRec;
Begin
 TextFileSize:=0;
 FileMode:=0;
 FindFirst(StrPas(TextRec(F).Name),AnyFile,DirInfo);
 If DosError=0 Then
    TextFileSize:=DirInfo.Size;
 FileMode:=2;
End;

{$ELSE}

Function TextFileSize(var F : Text) : LongInt;
Type
  TextBuffer = array[0..65520] of Byte;
  FIB =
    record
      Handle : Word;
      Mode : Word;
      BufSize : Word;
      Private : Word;
      BufPos : Word;
      BufEnd : Word;
      BufPtr : ^TextBuffer;
      OpenProc : Pointer;
      InOutProc : Pointer;
      FlushProc : Pointer;
      CloseProc : Pointer;
      UserData : array[1..16] of Byte;
      Name : array[0..79] of Char;
      Buffer : array[0..127] of Char;
    end;

Const
  FMClosed = $D7B0;

Var
 Regs : Registers;
 OldHi, OldLow : Integer;
Begin
 With Regs, FIB(F) Do
    Begin
      {check for open file}
      If Mode = FMClosed Then
       Begin
         TextFileSize := -1;
         Exit;
       End;
      {get current position of the file pointer}
      AX := $4201;           {move file pointer function}
      BX := Handle;          {file handle}
      CX := 0;               {if CX and DX are both 0, call returns the..}
      DX := 0;               {current file pointer in DX:AX}
      MsDos(Regs);

      {check for I/O error}
      if Odd(Flags) Then
       Begin
        TextFileSize := -1;
        Exit;
       End;

      {save current position of the file pointer}
      OldHi := DX;
      OldLow := AX;

      {have DOS move to end-of-file}
      AX := $4202;           {move file pointer function}
      BX := Handle;          {file handle}
      CX := 0;               {if CX and DX are both 0, call returns the...}
      DX := 0;               {current file pointer in DX:AX}
      MsDos(Regs);           {call DOS}

      {check for I/O error}
      If Odd(Flags) Then
       Begin
        TextFileSize := -1;
        Exit;
       End;

      {calculate the size}
      TextFileSize := LongInt(DX) shl 16+AX;

      {reset the old position of the file pointer}
      AX := $4200;           {move file pointer function}
      BX := Handle;          {file handle}
      CX := OldHi;           {high word of old position}
      DX := OldLow;          {low word of old position}
      MsDos(Regs);           {call DOS}

      {check for I/O error}
      If Odd(Flags) Then
        TextFileSize := -1;
    End;
End;
{$ENDIF}

Function IsFileExist(S:String):Boolean;
Var
DirInfo:SearchRec;
Begin
 FindFirst(FExpand(S),AnyFile-VolumeID-Hidden-Directory,DirInfo);
 IsFileExist:=DosError=0;
End;

Function IsDirectoryExist(S:String):Boolean;
Var
DirInfo:SearchRec;
Begin
 FindFirst(FExpand(S),Directory+VolumeID,DirInfo);
 IsDirectoryExist:=DosError=0;
End;

Function IsFileOrDirectoryExist(S:String):Boolean;
Var
DirInfo:SearchRec;
Begin
 FindFirst(FExpand(S),AnyFile-VolumeId,DirInfo);
 IsFileOrDirectoryExist:=DosError=0;
End;

Function IsFileOrDirectoryExistEx(S:String):Boolean;
Var
D:DirStr;
N:NameStr;
E:ExtStr;
DirInfo:SearchRec;
DErrorEx:Integer;
FValidator:PPxPictureValidator;
Begin
 DErrorEx:=0;
 IsFileOrDirectoryExistEx:=False;
 If StrUp(GetVar(ExtendedFileMaskTag.Tag,_varNONE))=Yes Then
    Begin
         S:=FExpand(S);
         FSplit(S,D,N,E);
         FValidator:=New(PPxPictureValidator,Init(N+E,False));
         If N+E<>'' Then
            FindFirst(D+'*.*',AnyFile-VolumeId,DirInfo)
         Else
             FindFirst(D,AnyFile-VolumeId,DirInfo);
         If DosError=0 Then
            Begin
                 If N+E<>'' Then
                    If FValidator^.IsValid(DirInfo.Name) Then
                       IsFileOrDIrectoryExistEx:=True
                 Else
                     IsFileOrDIrectoryExistEx:=True
            End;
         Dispose(FValidator,Done);
    End
 Else
     Begin
          FindFirst(FExpand(S),AnyFile-VolumeId,DirInfo);
          IsFileOrDirectoryExistEx:=DosError=0;
     End;
End;

Function FindFile(S:String):String;
{ld FileSearch}
Var
Path:PathStr;
D:DirStr;
N:NameStr;
E:ExtStr;
Begin
FSplit(S,D,N,E);
Path := FSearch(N+E,GetEnv('PATH'));
If Path='' Then
   FindFile:=FExpand(S)
Else
   FindFile:=Path;
End;

Procedure ChangeToCurrentDirectory;
Var
Dir:DirStr;
Name:NameStr;
Ext:ExtStr;
Begin
 GetDir(0,LastDirectory);
 FSplit(FExpand(ParamStr(0)),Dir,Name,Ext);
 If Dir[Length(Dir)]='\'  Then
    Delete(Dir,Length(Dir),1);
 ChDir(Dir);
End;

Procedure ChangeToLastDirectory;
Begin
 If LastDirectory[Length(LastDirectory)]='\' Then
    Delete(LastDirectory,Length(LastDirectory),1);
 ChDir(LastDirectory);
End;

Function GetFileTimeStamp(FName:String):LongInt;
Var
DirInfo:SearchRec;
Begin
 FindFirst(FName,AnyFile-Directory-VolumeID-Hidden,DirInfo);
 If DosError=0 Then
    GetFileTimeStamp:=DirInfo.Time
   Else
    GetFileTimeStamp:=0;
End;

Function GetFileSize(FName:String):LongInt;
Var
DirInfo:SearchRec;
Begin
 FindFirst(FName,AnyFile-Directory-VolumeID-Hidden,DirInfo);
 If DosError=0 Then
    GetFileSize:=DirInfo.Size
   Else
    GetFileSize:=0;
End;

{$I-,V-,S-,R-}
Function FileCopyBuf(Source,Dest : PathStr;
                     BufPtr : Pointer; BufferSize : Word;IsMove:Boolean;WriteLog:Boolean) : Word;

Var
  InF,OutF         : File;    { the input and output files }
  InOutResult,Num,N  : Word;    { a few words }
  Time             : LongInt; { to hold time/date stamp }

Begin
  If StrUp(FExpand(Source))=StrUp(FExpand(Dest)) Then
     Begin
          If IsMove Then
             Begin
                   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                      LogWriteLn('!Can''t move to itself: '+FExpand(Source))
                   Else
                       LogWriteLn('!Hе могy пеpеместить файл на самого себя: '+FExpand(Source))
             End
          Else
              Begin
                   If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                      LogWriteLn('!Can''t copy to itself: '+FExpand(Source))
                   Else
                       LogWriteLn('!Hе могy скопиpовать файл на самого себя: '+FExpand(Source))
              End;
          DosError:=18;
          FileCopyBuf:=18;
          Exit;
     End;
  FileMode:=($40);
  Assign(InF,Source);
  {$I-}
  Reset(InF,1);           { open the source file }
  {$I+}
  InOutResult := IOResult;
  If InOutResult=0 Then
   Begin
       {$I-}
       GetFTime(InF,Time);     { get time/date stamp from source file }
       {$I+}
       if IOResult = 0 then
          Begin
               FileMode:=$42;
               Assign(OutF,Dest);
               {$I-}
               Rewrite(OutF,1);      { Create destination file }
               {$I+}
               InOutResult:= IOResult;
               If InOutResult<>0 Then
                  Begin
                        LogWriteLn(GetExpandedString(_logCantOpenFile)+FExpand(Dest));
                        {$IFNDEF SPLE}
                          LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
                        {$ENDIF}
                        {$I-}
                        Close(InF);
                        {$I+}
                        If IOResult<>0 Then;
                        FileMode:=$42;
                        Exit;
                  End;
               { copy loop }
                While (Not EOF(InF)) And (InOutResult = 0) do
                      Begin
                            {$I-}
                            BlockRead(InF,BufPtr^,BufferSize,Num); { read a buffer full from source }
                            {$I+}
                            InOutResult := IOResult;
                            if InOutResult = 0 then
                               Begin
                                     {$I-}
                                     BlockWrite(OutF,BufPtr^,Num);      { write it to destintion }
                                     {$I+}
                                     InOutResult := IOResult;
{                                     If N < Num then}
                                     If InOutResult<>0 Then
                                        Begin
{                                             ErrorCode := $FFFF;    disk probably full }
                                              If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                                                 LogWriteLn('!Error writing to '+FExpand(Dest))
                                              Else
                                                  LogWriteLn('!Ошибка записи в '+FExpand(Dest));
                                              {$IFNDEF SPLE}
                                                LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
                                              {$ENDIF}
                                        End;
                                end;
                      end;
          end
       Else
           Begin
                LogWriteLn(GetExpandedString(_logCantOpenFile)+FExpand(Source));
                {$IFNDEF SPLE}
                  LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
                {$ENDIF}
                FileMode:=$42;
                Exit;
           End;
   End
  Else
      Begin
           LogWriteLn(GetExpandedString(_logCantOpenFile)+FExpand(Source));
           {$IFNDEF SPLE}
             LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
           {$ENDIF}
            FileMode:=$42;
            Exit;
      End;
  {$I-}
  Close(OutF);      { Close destination file }
  {$I+}
  if IOresult <> 0 then ;
  {$I-}
  Close(InF);       { close source file }
  {$I+}
  FileMode:=$42;
  if IOResult = 0 then begin
    Assign(OutF,Dest);
    {$I-}
    Reset(OutF);
    if IOResult <> 0 then ;  { clear IOResult }
    SetFTime(OutF,Time);     { Set time/date stamp of dest to that of source }
    If IOResult<>0 Then;
    Close(OutF);
    {$I+}
    if IOresult <> 0 then ;
  end;
  FileCopyBuf := InOutResult;
  If IsMove Then
     Begin
      {$I-}
      Erase(InF);
      {$I+}
      InOutResult:=IOresult;
      If InOutResult<>0 Then
        Begin
         FileCopyBuf:=InOutResult;
         LogWriteLn(GetExpandedString(_logCantDeleteFile)+FExpand(Source));
         {$IFNDEF SPLE}
         LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
         {$ENDIF}
        End;
     End;
If WriteLog Then
 Begin
  If IsMove Then
    Begin
     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
        LogWriteLn('#Done move '+FExpand(Source)+' to '+FExpand(Dest))
     Else
        LogWriteLn('#Пеpемещен '+FExpand(Source)+' в '+FExpand(Dest))
    End
  Else
    Begin
     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
        LogWriteLn('#Done copy '+FExpand(Source)+' to '+FExpand(Dest))
     Else
        LogWriteLn('#Скопиpован '+FExpand(Source)+' в '+FExpand(Dest))
    End;
 End;
end;

Function FileCopy(Source,Dest : PathStr; BufferSize : Word;IsMove:Boolean;WriteLog:Boolean) : Word;
{ shell around File_Copy_Buf to automatically allocate a buffer of }
{ BufferSize on the heap }
Var
  Buf              : Pointer;

Begin
  if BufferSize > 65521 then
    BufferSize := 65521;  { user specified buffer bigger than possible }
                          { so scale it down }
  GetMem(Buf,BufferSize); { allocate memory for the buffer }
  FileCopy := FileCopyBuf(Source,Dest,Buf,BufferSize,IsMove,WriteLog);
  FreeMem(Buf,BufferSize); { deallocate heap space for buffer }
end;
{$I+,V+,S+,R+}

Procedure CopyFile(Source,Dest:String;IsMove:Boolean);
Var
Dir,Dir1:DirStr;
Name,Name1:NameStr;
Ext,Ext1:ExtStr;
DirInfo:SearchRec;
InOutResult:Integer;
Begin
 FSplit(Source,Dir,Name,Ext);
 FSplit(Dest,Dir1,Name1,Ext1);
 If Dir1[length(Dir1)]='\' Then
    Delete(Dir1,Length(Dir1),1);
 If Length(Dir1)=2 Then
   Dos.FindFirst(Dir1+'*.*',Directory,DirInfo)
Else
   Dos.FindFirst(Dir1,Directory,DirInfo);
 InOutResult:=IOResult;
 If DosError=0 Then
   Begin
    If (Name1='') Then
      Begin
       Name1:=Name;
       Ext1:=Ext;
      End;
    Dest:=Dir1+'\'+Name1+Ext1;
    FileCopy(Source,Dest,$FFFF,IsMove,True);
   End
  Else
   Begin
    If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
       LogWriteLn(GetExpandedString(_logCantOpenFile)+Dir1+'\ (directory)')
    Else
       LogWriteLn(GetExpandedString(_logCantOpenFile)+Dir1+'\ (диpектоpия)');
    {$IFNDEF SPLE}
    LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
    {$ENDIF}
   End;
End;

Var
 SearchRecValidator:PPxPictureValidator;

Procedure InitValidator;
Begin
 If SearchRecValidator=Nil Then
   Begin
    SearchRecValidator:=New(PPxPictureValidator,Init('*@',False));
   End;
End;

Procedure SetValidatorPicture(Var P:PPxPictureValidator;S:String);
Begin
 If P<>Nil Then
    Begin
         DisposeStr(P^.Pic);
         P^.Pic:=MCommon.NewStr(S);
    End;
End;

Procedure DoneValidator;
Begin
 If SearchRecValidator<>Nil Then
    Begin
     Dispose(SearchRecValidator,Done);
     SearchRecValidator:=Nil;
    End;
End;

Procedure FindFirstEx(Path: PathStr; Attr: Word; var F: SearchRec);
{пока только для имени файла}
Var
 D:DirStr;
 N:NameStr;
 E:ExtStr;

Begin
     DosErrorEx:=0;
     If StrUp(GetVar(ExtendedFileMaskTag.Tag,_varNONE))=Yes Then
        Begin
          InitValidator;
          FSplit(Path,D,N,E);
          SetValidatorPicture(SearchRecValidator,N+E);
          FindFirst(D+'*.*',Attr,F);
          If DosError=0 Then
             Begin
              If SearchRecValidator^.IsValid(F.Name) Then
                 Begin
                 End
              Else
                 DosErrorEx:=2;
             End;
        End
     Else
        Begin
         FindFirst(Path,Attr,F);
        End;
End;

Procedure FindNextEx(var F: SearchRec);
Begin
     DosErrorEx:=0;
     If StrUp(GetVar(ExtendedFileMaskTag.Tag,_varNONE))=Yes Then
        Begin
          InitValidator;
          FindNext(F);
          If DosError=0 Then
             Begin
              If SearchRecValidator^.IsValid(F.Name) Then
                 Begin
                 End
              Else
                 DosErrorEx:=2;
             End;
        End
     Else
        Begin
         FindNext(F);
        End;
End;
Procedure FindCloseEx(var F: SearchRec);
Begin
 DoneValidator;
 DosErrorEx:=0;
End;

{*** begin fileIO wrapper ***}
Function ResetUnTypedFile(Var F:File;RecSize:Word):Boolean;
Var
   InOutResult:Integer;
Begin
     ResetUnTypedFile:=True;
     {$I-}
     Reset(F,RecSize);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              ResetUnTypedFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t reset untyped file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t reset untyped file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;
End;
Function ResetTypedFile(Var F;RecSize:Word):Boolean;
Var
   InOutResult:Integer;
Begin
     ResetTypedFile:=True;
     {$I-}
     Reset(File(F),RecSize);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              ResetTypedFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t reset typed file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t reset typed file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;
End;
Function ResetTextFile(Var F:Text):Boolean;
Var
   InOutResult:Integer;
Begin
     ResetTextFile:=True;
     {$I-}
     Reset(F);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              ResetTextFile:=False;
              {$IFDEF VIRTUALPASCAL}
                     LogWriteLn('!Can''t reset text file '+StrPas(TextRec(F).Name));
              {$ELSE}
                     LogWriteLn('!Can''t reset text file '+TextRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;
End;


Function RewriteUnTypedFile(Var F:File;RecSize:Word):Boolean;
Var
   InOutResult:Integer;
Begin
     RewriteUnTypedFile:=True;
     {$I-}
     Rewrite(F,RecSize);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              RewriteUnTypedFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t rewrite untyped file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t rewrite untyped file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;
End;
Function RewriteTypedFile(Var F;RecSize:Word):Boolean;
Var
   InOutResult:Integer;
Begin
     RewriteTypedFile:=True;
     {$I-}
     Rewrite(File(F),RecSize);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              RewriteTypedFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t rewrite typed file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t rewrite typed file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;
End;
Function RewriteTextFile(Var F:Text):Boolean;
Var
   InOutResult:Integer;
Begin
     RewriteTextFile:=True;
     {$I-}
     Rewrite(F);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              RewriteTextFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t rewrite text file '+StrPas(TextRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t rewrite text file '+TextRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;
End;


Function CloseUnTypedFile(Var F:File):Boolean;
Var
   InOutResult:Integer;
Begin
     CloseUnTypedFile:=True;
     {$I-}
     Close(F);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              CloseUnTypedFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t close untyped file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t close untyped file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;
End;

Function CloseTypedFile(Var F):Boolean;
Var
   InOutResult:Integer;
Begin
     CloseTypedFile:=True;
     {$I-}
     Close(File(F));
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              CloseTypedFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t close typed file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t close typed file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;
End;

Function CloseTextFile(Var F:Text):Boolean;
Var
   InOutResult:Integer;
Begin
     CloseTextFile:=True;
     {$I-}
     Close(F);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              CloseTextFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t close text file '+StrPas(TextRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t close text file '+TextRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;
End;

Function WriteLnToTextFile(Var F:Text;S:String):Boolean;
Var
   InOutResult:Integer;
Begin
     WriteLnToTextFile:=True;
     {$I-}
     WriteLn(F,S);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              WriteLnToTextFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t write line to text file '+StrPas(TextRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t write line to text file '+TextRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;

End;

Function ReadLnFromTextFile(Var F:Text;Var S:String):Boolean;
Var
   InOutResult:Integer;
Begin
     ReadLnFromTextFile:=True;
     {$I-}
     ReadLn(F,S);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              ReadLnFromTextFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t read line to text file '+StrPas(TextRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t read line to text file '+TextRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;

End;


Function BlockWriteToUnTypedFile(Var F:File;Var Buf;Count:Word):Boolean;
Var
   InOutResult:Integer;
Begin
     BlockWriteToUnTypedFile:=True;
     {$I-}
     BlockWrite(F,Buf,Count);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              BlockWriteToUnTypedFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t write block to untyped file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t write block to untyped file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;

End;


Function BlockReadFromUnTypedFile(Var F:File;Var Buf;Count:Word):Boolean;
Var
   InOutResult:Integer;
Begin
     BlockReadFromUnTypedFile:=True;
     {$I-}
     BlockRead(F,Buf,Count);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              BlockReadFromUnTypedFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t read block from untyped file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t read block from untyped file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;

End;


Function BlockWriteToUnTypedFileEx(Var F:File;Var Buf;Count:Word;Var _Result:Word):Boolean;
Var
   InOutResult:Integer;
Begin
     BlockWriteToUnTypedFileEx:=True;
     {$I-}
     BlockWrite(F,Buf,Count,_Result);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              BlockWriteToUnTypedFileEx:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t write block to untyped file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t write block to untyped file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;

End;

Function BlockReadFromUnTypedFileEx(Var F:File;Var Buf;Count:Word;Var _Result:Word):Boolean;
Var
   InOutResult:Integer;
Begin
     BlockReadFromUnTypedFileEx:=True;
     {$I-}
     BlockRead(F,Buf,Count,_Result);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              BlockReadFromUnTypedFileEx:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t read block from untyped file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t read block from untyped file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;

End;


Function SeekUnTypedFile(Var F:File;N:LongInt):Boolean;
Var
   InOutResult:Integer;
Begin
     SeekUnTypedFile:=True;
     {$I-}
     Seek(F,N);
     {$I+}
     InOutResult:=IOResult;
     If InOutResult<>0 Then
        Begin
              SeekunTypedFile:=False;
              {$IFDEF VIRTUALPASCAL}
                      LogWriteLn('!Can''t seek to untyped file '+StrPas(FileRec(F).Name));
              {$ELSE}
                      LogWriteLn('!Can''t seek to untyped file '+FileRec(F).Name);
              {$ENDIF}
              LogWriteDosError(InOutResult,GetExpandedString(_logDosError));
        End;

End;

{*** end fileIO wrapper ***}

Begin
 SearchRecValidator:=Nil;
End.
