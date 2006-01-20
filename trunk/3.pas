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
       GetFTime(InF,Time);     { get time/date stamp from source file }
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
                        LogWriteLn(GetMakingString(_logCantOpenFile)+FExpand(Dest));
                        {$IFNDEF SPLE}
                          LogWriteDosError(InOutResult,GetMakingString(_logDosError));
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
{                                             ErrorCode := $FFFF;   { disk probably full }
                                              If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                                                 LogWriteLn('!Error writing to '+FExpand(Dest))
                                              Else
                                                  LogWriteLn('!Ошибка записи в '+FExpand(Dest));
                                              {$IFNDEF SPLE}
                                                LogWriteDosError(InOutResult,GetMakingString(_logDosError));
                                              {$ENDIF}
                                        End;
                                end;
                      end;
          end
       Else
           Begin
                LogWriteLn(GetMakingString(_logCantOpenFile)+FExpand(Source));
                {$IFNDEF SPLE}
                  LogWriteDosError(ErrorCode,GetMakingString(_logDosError));
                {$ENDIF}
                FileMode:=$42;
                Exit;
           End;
   End
  Else
      Begin
           LogWriteLn(GetMakingString(_logCantOpenFile)+FExpand(Source));
           {$IFNDEF SPLE}
             LogWriteDosError(InOutResult,GetMakingString(_logDosError));
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
    {$I+}
    if IOResult <> 0 then ;  { clear IOResult }
    {$I-}
    SetFTime(OutF,Time);     { Set time/date stamp of dest to that of source }
    {$I+}
    {$I-}
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
         FileCopyBuf:=ErrorCode;
         LogWriteLn(GetMakingString(_logCantDeleteFile)+FExpand(Source));
         {$IFNDEF SPLE}
         LogWriteDosError(InOutResult,GetMakingString(_logDosError));
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
