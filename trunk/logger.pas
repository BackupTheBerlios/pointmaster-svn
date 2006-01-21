UNIT Logger;
INTERFACE
{$I VERSION.INC}
Uses
Use32,
StrUnit,Incl,Parser,{TpDos,}Crt,Dos,MCommon,Face,Drivers,FileIO,Dates;

Var
Log:Text;
LogName:String;
_flgLogOpened:Boolean;
Function InitLog(Var Log:Text):Boolean;
Function InitDebugLog(Var Log:Text;Name:String):Boolean;
Procedure DoneLog(Var Log:Text);
Procedure LogWrite(S:String);
Procedure LogWriteLn(S:String);
Procedure DebugLogWriteLn(S:String);

IMPLEMENTATION

Function InitDebugLog(Var Log:Text;Name:String):Boolean;
Begin
{$IFNDEF SPLE}
LogName:=FExpand(Name);
If Not _flgLogOpened Then
  Begin
   FileMode:=$42;
   Assign(Log,LogName);
   {$I-}
   Append(Log);
   {$I+}
   If (IOResult<> 0) Then
      Begin
       {$I-}
       Rewrite(Log);
       {$I+}
       If IOResult<>0 Then
         Begin
          If StrUp(GetVar(LanguageTag.Tag,_varNONE))=RussianTag Then
           Begin
            WriteLn('H¥ ¬®£y ®âªpëâì ä ©«: '+LogName);
            WriteLn('‹®£ ¯¥p¥­ ¯p ¢«¥­ ¢ NUL');
           End
          Else
           Begin
            WriteLn('Can''t open file: '+LogName);
            WriteLn('Log redirected to NUL');
           End;
          Assign(Log,'NUL');
          {$I-}
          Rewrite(Log);
          {$I+}
          If IOResult<>0 Then;
         End;
      End;
  _flgLogOpened:=True;
  {$I-}
  WriteLn(Log,'Ú[BEGIN]Ä['+GetDateString+']Ä['+GetTimeString+']Ä['+PntMasterVersion+']');
  {$I+}
  If IOResult<>0 Then;
  If Not MODE_NOCONSOLE Then
    Begin
      {$I-}
      WriteLn('Ú[BEGIN]Ä['+GetDateString+']Ä['+GetTimeString+']Ä['+PntMasterVersion+']');
      {$I+}
      If IOResult<>0 Then;
    End;
  End;
{$ENDIF}
End;

Function InitLog(Var Log:Text):Boolean;
Var
LogSize,Code:Integer;
Begin
{$IFNDEF SPLE}
InitLog:=True;
Logger.LogName:=GetVar(MasterLogNameTag.Tag,_varNONE);
LogName:=FExpand(Logger.LogName);
Val(GetVar(LogSizeTag.Tag,_varNONE),LogSize,Code);
If Not _flgLogOpened Then
  Begin
   FileMode:=$42;
   Assign(Log,LogName);
   {$I-}
   Append(Log);
   {$I+}
{   Val(GetVar(LogSizeTag.Tag,_varNONE),LogSize,Code);}
   If (IOResult<> 0) Then
      Begin
       {$I-}
       Rewrite(Log);
       {$I+}
       If IOResult<>0 Then
         Begin
          If StrUp(GetVar(LanguageTag.Tag,_varNONE))=RussianTag Then
           Begin
            WriteLn('H¥ ¬®£y ®âªpëâì ä ©«: '+Logger.LogName);
            WriteLn('‹®£ ¯¥p¥­ ¯p ¢«¥­ ¢ NUL');
           End
          Else
           Begin
            WriteLn('Can''t open file: '+Logger.LogName);
            WriteLn('Log redirected to NUL');
           End;
          {$IFDEF LINUX}
          Assign(Log,'/dev/null');
          {$ELSE}
          Assign(Log,'NUL');
          {$ENDIF}
          {$I-}
          Rewrite(Log);
          {$I+}
          If IOResult<>0 Then;
         End;
      End
  Else
   If (TextFileSize(Log) div 1024)>=LogSize Then
      {$I-}
      Rewrite(Log);
      {$I+}
   If IOResult<>0 Then;
   _flgLogOpened:=True;
  End;
{$IFDEF SPLE}
{$I-}
WriteLn(Log,'Ú[BEGIN]Ä['+GetDateString+']Ä['+GetTimeString+']Ä['+SpleVersion+']');
{$I+}
If IOResult<>0 Then;
{$ELSE}
{$I-}
WriteLn(Log,'Ú[BEGIN]Ä['+GetDateString+']Ä['+GetTimeString+']Ä['+PntMasterVersion+']');
{$I+}
If IOResult<>0 Then;
{$ENDIF}
{$IFNDEF SPLE}
If Not MODE_NOCONSOLE Then
   Begin
    {$I-}
    WriteLn('Ú[BEGIN]Ä['+GetDateString+']Ä['+GetTimeString+']Ä['+PntMasterVersion+']');
    {$I+}
    If IOResult<>0 Then;
   End;
{$ENDIF}
{$ENDIF}
End;

Procedure DoneLog(Var Log:Text);
Begin
{$IFNDEF SPLE}
If Not _flgLogOpened Then
   InitLog(Log);
 {$IFDEF SPLE}
 {$I-}
 WriteLn(Log,'À[END]Ä['+GetDateString+']Ä['+GetTimeString+']Ä['+SpleVersion+']');
 {$I+}
 If IOResult<>0 Then;
 {$ELSE}
 {$I-}
 WriteLn(Log,'À[END]Ä['+GetDateString+']Ä['+GetTimeString+']Ä['+PntMasterVersion+']');
 {$I+}
 If IOResult<>0 Then;
 {$ENDIF}
 {$IFNDEF SPLE}
 If Not MODE_NOCONSOLE Then
    Begin
     {$I-}
     WriteLn('À[END]Ä['+GetDateString+']Ä['+GetTimeString+']Ä['+PntMasterVersion+']');
     {$I+}
     If IOResult<>0 Then;
    End;
 {$ENDIF}
 {$I-}
 WriteLn(Log,'');
 If IOResult<>0 Then;
 Close(Log);
 {$I+}
 If IOResult<>0 Then;
 _flgLogOpened:=False;
{$ENDIF}
End;

Procedure LogWrite(S:String);
Begin
 {$I-}
 Write(Log,S);
 {$I+}
 If IOResult<>0 Then;
End;


Procedure LogWriteLn(S:String);
Var
LogLevel:Byte;
Color:Byte;
Begin
{$IFNDEF SPLE}
If Not _flgLogOpened Then
   InitLog(Log);
LogLevel:=StrToInt(GetVar(LogLevelTag.Tag,_varNONE));
Case LogLevel Of
    0:Case S[1] Of
       '!':;
       Else
        Exit;
       End;
    1:Case S[1] Of
       '!','+','?':;
       Else
        Exit;
       End;
    2..255:;
   Else;
 End;
Case S[1] Of
      '!':Color:=LightRed;
      '#':Color:=Yellow;
      '?':Color:=LightGreen;
     Else
          Color:=Yellow;
End;
LogWrite('Ã['+S[1]+']Ä['+GetTimeString+'] ');
{$IFNDEF SPLE}
If Not MODE_NOCONSOLE Then
  Begin
   TextColor(White);
   Write('Ã[');
   TextColor(Color);
   Write(S[1]);
   TextColor(White);
   Write('] ');
  End;
{$ENDIF}
Delete(S,1,1);
{$I-}
WriteLn(Log,S);
{$I+}
If IOResult<>0 Then;
If Length(S)>(ScreenWidth-9) Then
   Begin
    Insert(#13'³    ',S,ScreenWidth-8);
   End;
{$IFNDEF SPLE}
If Not MODE_NOCONSOLE Then
   WriteLn(S);
{$ENDIF}
{$ENDIF}
End;

Procedure DebugLogWriteLn(S:String);
Var
Color:Byte;
Begin
{$IFNDEF SPLE}
 If Not _flgLogOpened Then
    InitDebugLog(Log,'debug.log');
 LogWrite('Ã['+S[1]+']Ä['+GetTimeString+'] ');
 Case S[1] Of
       '!':Color:=LightRed;
       '#':Color:=Yellow;
       '?':Color:=LightGreen;
      Else
           Color:=Yellow;
 End;

 If Not MODE_NOCONSOLE Then
   Begin
    TextColor(White);
    Write('Ã[');
    TextColor(Color);
    Write(S[1]);
    TextColor(White);
    Write('] ');
   End;
 Delete(S,1,1);
 {$i-}
 WriteLn(Log,S);
 If IOResult<>0 Then;
 Flush(Log);
 {$I+}
 If IOResult<>0 Then;
 If Length(S)>ScreenWidth-9 Then
    Begin
     Insert(#13'³    ',S,ScreenWidth-8);
    End;
 If Not MODE_NOCONSOLE Then
    WriteLn(S);
{$ENDIF}
End;

Begin
End.
