UNIT Face;
{$I VERSION.INC}
INTERFACE
Uses
Use32,
Incl,Crt,{Drivers,}StrUnit,Dos,Objects,Parser,Os_Type,Drivers,
     MCommon,Crc_32,FileIO;
{.F+,S-,W-}


Var
CharsCounter:Byte;
IntCounter:ShortInt;
ScrCounter:Byte;

OldX,OldY,
OldXF,OldYF:Word;
C:Char;
Var
StartHour,StartMinutes,StartSec,StartHnd:Word;

Procedure WriteScreenSkeleton;
Procedure WritePerCent;
Procedure RefreshScreen;
Procedure DoneScreenForHelpRequest;
Procedure RestoreScreenHandler;
Procedure SetScreenHandler;
Procedure PreUpdateScreen;
Procedure InitializeScreen;
Procedure DoneScreen;
Procedure SwitchToLogWindow;
Procedure SwitchToFullWindow;
Procedure DisplayHelpWindow;
Function  GetMinutesFromStart:Word;
Procedure PrepareScreenToExec;

IMPLEMENTATION

Uses Logger;


Procedure WriteVersion;
Begin
 If MODE_NOCONSOLE Then
    Exit;
 GotoXy(18,1);
 TextColor(15);
 TextBackGround(7);
 Write(PntMasterVersion);
 WriteLn(' by Andrew Kornilov');
End;

Procedure DisplayHelpWindow;
Begin
 Exit;
End;

Procedure WriteScreenSkeleton;
Var
OldDosError:System.Integer;
Crc32S:String;
Begin
 If MODE_NOCONSOLE Then
    Exit;
 OldDosError:=DosError;
   Begin
    DosError:=OldDosError;
    Crc32S:='OPEN';
    PntMasterVersion:=BaseVersion+
    {$IFDEF WIN32}
    '[W32]'
    {$ENDIF}
    {$IFDEF OS2}
    '[OS/2]'
    {$ENDIF}
    {$IFDEF LINUX}
    '[LNX]'
    {$ENDIF}+
    '.'+Crc32S;
   End;
 SwitchToFullWindow;
 GotoXy((ScreenWidth div 2)-(Length(BaseVersion+
    {$IFDEF WIN32}
    '[W32]'
    {$ENDIF}
    {$IFDEF OS2}
    '[OS/2]'
    {$ENDIF}
    {$IFDEF LINUX}
    '[LNX]'
    {$ENDIF}+
     '.'+Crc32S) div 2),1);
 TextColor(Black);
 TextBackground(LightGray);
 WriteLn(BaseVersion+
    {$IFDEF WIN32}
    '[W32]'
    {$ENDIF}
    {$IFDEF OS2}
    '[OS/2]'
    {$ENDIF}
    {$IFDEF LINUX}
    '[LNX]'
    {$ENDIF}+
     '.'+Crc32S);
 GotoXy(((ScreenWidth-1) div 2) - 7,2);
 TextColor(LightGray);
 TextBackground(Blue);
 Write('[');
 TextColor(Yellow);
 Write('Info Window');
 TextColor(LightGray);
 Write(']');
 GotoXy(((ScreenWidth-1) div 2) - 6,11);
 TextColor(LightGray);
 Write('[');
 TextColor(Yellow);
 Write('Log Window');
 TextColor(LightGray);
 Write(']');

    GotoXy(((ScreenWidth-1) div 2)-10,9);
    TextColor(LightGray);
    Write('[');
    TextColor(LightRed);
    Write('FREE OPEN VERSION');
    TextColor(LightGray);
    Write(']');
 GotoXy(3,3);
 TextColor(White);
 Write(#254);
 TextColor(LightGreen);
 Write(' Operation:');
 GotoXy(3,4);
 TExtColor(White);
 Write(#254);
 TExtColor(LightGreen);
 Write(' Operation progress:');
 GotoXy(3,5);
 TExtColor(White);
 Write(#254);
 TextColor(LightGreen);
 Write(' Total memory free:');
 GotoXy(3,6);
 TextColor(White);
 Write(#254);
 TextColor(LightGreen);
 Write(' Task number:');
 GotoXy(3,7);
 TextCOlor(White);
 Write(#254);
 TExtColor(LightGreen);
 Write(' Mode:');
 GotoXy(3,8);
 TextColor(White);
 Write(#254);
 TextColor(LightGreen);
 Write(' Address:');
 GotoXy(25,4);
 TextColor(White);
 Write('[');
 GotoXy(46,4);
 Write(']');

 SwitchToLogWindow;
End;


Function GetMinutesFromStart:Word;
Var
CurHour,CurMin,CurSec,CurHnd:Word;
Begin
 GetTime(CurHour,CurMin,CurSec,CurHnd);
 If StartHour<CurHour Then
    Begin
     GetMinutesFromStart:=(60-StartMinutes+Abs(CurMin));
    End
 Else
  If StartHour>=CurHour Then
    Begin
     GetMinutesFromStart:=(CurMin-StartMinutes);
    End;
End;

Procedure PrepareScreenToExec;
Begin
 Window(1,1,80,25);
 TextColor(7);
 TextBackGround(0);
 OldX:=1;
 OldY:=1;
 ClrScr;
End;

Procedure SwitchToLogWindow;
Var
X,Y:Word;
Begin
 {$IFNDEF SPLE}
 If MODE_NOCONSOLE Then
    Exit;
 OldXF:=WhereX;
 OldYF:=WhereY;
 Window(2,12,ScreenWidth-3,ScreenHeight-3);
 GotoXy(OldX,OldY);
 OldX:=1;
 OldY:=1;
 TextColor(15);
 {$ENDIF}
End;

Procedure SwitchToFullWindow;
Var
X,Y:Word;
Begin
 {$IFNDEF SPLE}
 If MODE_NOCONSOLE Then
    Exit;
 OldX:=WhereX;
 OldY:=WhereY;
 Window(1,1,ScreenWidth,ScreenHeight);
 GotoXy(OldXF,OldYF);
 {$ENDIF}
End;

Procedure WritePerCent;
Var
PerCents:LongInt;
S,S2:String;
Begin
 {$IFNDEF SPLE}
 If MODE_NOCONSOLE Then
    Exit;
 S:='■■■■■■■■■■■■■■■■■■■■';
 S2:='····················';
 If TotalBytes<> 0 Then
   Begin
    PerCents:=((Trunc((Abs(ReadedBytes)/Abs(TotalBytes))*10{0})){ div 10});
    S:=Copy(S,1,PerCents*2);
   End
Else
   Begin
    PerCents:=0;
    S:='';
   End;

 SwitchToFullWindow;
 TextColor(Red);
 GotoXy(3,4);
 Write(#254);
 TextColor(White);
 GotoXy(26,4);
 Write(S2);
 GotoXy(26,4);
 Write(S);
 TextColor(LightRed);
 GotoXy(48,4);
 Write(IntToStr(PerCents*10)+'% Done');
 TextColor(White);
 GotoXy(3,4);
 Write(#254);
 SwitchToLogWindow;
 {.ENDIF}
 {$ENDIF}
End;

Procedure WriteMemory;
Var
S:String;
Begin
	{S:=IntToStr(MemAvail div 1024)+' kb';}
 S:='FIXME kb';
 SwitchToFullWindow;
 TextColor(Red);
 GotoXy(3,5);
 Write(#254);
 TextColor(LightRed);
 GotoXy(24,5);
 Write(S);
 TextColor(White);
 GotoXy(3,5);
 Write(#254);
 SwitchToLogWindow;
End;

Procedure WriteOperation;
Var
Count:Word;
Begin
If Length(CurrentOperation)>ScreenWidth-21 Then
  Begin
   CurrentOperation[0]:=Chr(ScreenWidth-21);
   CurrentOperation[ScreenWidth-21]:='.';
   CurrentOperation[ScreenWidth-20]:='.';
   CurrentOperation[ScreenWidth-19]:='.';
  End;
If Length(CurrentOperation)<ScreenWidth-21 Then
   Begin
    For Count:=(Length(CurrentOperation)+1) to ScreenWidth-21 Do
      Begin
       CurrentOperation:=CurrentOperation+' ';
      End;
   End;
SwitchToFullWindow;
TextColor(Red);
GotoXy(3,3);
Write(#254);
TextColor(LightRed);
GotoXy(16,3);
Write(CurrentOperation);
TextColor(White);
GotoXy(3,3);
Write(#254);
SwitchToLogWindow;
{.ENDIF}
End;

Procedure WriteRunTimeChars;
Const
Chars:Array[1..4] of Char=('-','\','|','/');
Begin
 If CharsCounter>4 Then CharsCounter:=1;
 SwitchToFullWindow;
 TextColor(Red);
 GotoXy(3,4);
 Write(#254);
 TextColor(LightGray);
 GotoXy(57,4);
 Write(Chars[CharsCounter]);
 Inc(CharsCounter);
 TextColor(White);
 GotoXy(3,4);
 Write(#254);

 SwitchToLogWindow;
 {.ENDIF}
End;


Procedure RefreshScreen;
Begin
{$IFNDEF SPLE}
 If  (Not MODE_NOCONSOLE)  Then
  Begin
   If ScrCounter>=15 Then
     Begin
     WritePerCent;
     WriteMemory;
     WriteOperation;
     WriteRunTimeChars;
     ScrCounter:=0;
   End;
 End;
Inc(ScrCounter);
{$ENDIF}
End;

Procedure PreUpdateScreen;
Var
TaskStr:String;
OsStr:String;
Addr:String;
Begin
 {$IFNDEF SPLE}
 If MODE_NOCONSOLE Then
    Exit;
{ MoveStr(Mem[SegB800:(13*2)],PntMasterVersion+' by Andrew Kornilov',127);}
 SwitchToFullWindow;
 GotoXy(18,6);
 If MODE_DEBUG Then
    SwitchToLogWindow;
 OsStr:=GetVar(TaskNumberTag.Tag,_varNONE);
 If MODE_DEBUG Then
    SwitchToFullWindow;
 TextColor(LightRed);
 Write(OsStr+' '+
    {$IFDEF WIN32}
    '[W32]'
    {$ENDIF}
    {$IFDEF OS2}
    '[OS/2]'
    {$ENDIF}
    {$IFDEF LINUX}
    '[LNX]'
    {$ENDIF});
 Case WorkMode Of
      MODE_MSG:
              Begin
              If MODE_DEBUG Then
                 SwitchToLogWindow;
              If StrUp(GetVar(LanguageTag.Tag,_varNONE))=RussianTag Then
                Begin
{                 WriteLn('Обpаботка писем');}
                 If MODE_DEBUG Then
                   Begin
                    SwitchToFullWindow;
                    TextColor(LightRed);
                   End;
                 GotoXy(11,7);
                 Write('Обpаботка писем');
                End
              Else
                Begin
{                 GotoXy(12,7);
                 WriteLn('Process netmail requests only');}
                 If MODE_DEBUG Then
                   Begin
                    SwitchToFullWindow;
                    TextColor(LightRed);
                   End;
                 GotoXy(11,7);
                 Write('Process netmail requests only');
                End;
              End;
      MODE_BUILD:
              Begin
              If MODE_DEBUG Then
                 SwitchToLogWindow;
              If StrUp(GetVar(LanguageTag.Tag,_varNONE))=RussianTag Then
                Begin
                 If MODE_DEBUG Then
                    Begin
                     SwitchToFullWindow;
                     TextColor(LightRed);
                    End;
                 GotoXy(11,7);
                 WriteLn('Компилиpование поинтлиста');
                End
              Else
                Begin
                 If MODE_DEBUG Then
                   Begin
                    SwitchToFullWindow;
                    TextColor(LightRed);
                   End;
                 GotoXy(11,7);
                 WriteLn('Compile pointlist only');
                End;
              End;
      MODE_MSG_BUILD:
              Begin
              If MODE_DEBUG Then
                 SwitchToLogWindow;
              If StrUp(GetVar(LanguageTag.Tag,_varNONE))=RussianTag Then
                Begin
                 If MODE_DEBUG Then
                   Begin
                    SwitchToFullWindow;
                    TextColor(LightRed);
                   End;
                 GotoXy(11,7);
                 WriteLn('Обpаботка писем и компилиpование поинтлиста');
                End
              Else
                Begin
                 If MODE_DEBUG Then
                   Begin
                    SwitchToFullWindow;
                    TextColor(LightRed);
                   End;
                 GotoXy(11,7);
                 WriteLn('Process netmail requests & compile pointlist');
                End
              End;
      MODE_NOTHING:
              Begin
              If MODE_DEBUG Then
                 SwitchToLogWindow;
              If StrUp(GetVar(LanguageTag.Tag,_varNONE))=RussianTag Then
                Begin
                 If MODE_DEBUG Then
                   Begin
                    SwitchToFullWindow;
                    TextColor(LightRed);
                   End;
                 GotoXy(11,7);
                 WriteLn('Hичего');
                End
              Else
                Begin
                 If MODE_DEBUG Then
                   Begin
                    SwitchToFullWindow;
                    TextColor(LightRed);
                   End;
                 GotoXy(11,7);
                 WriteLn('Nothing to do');
                End;
              End;
      MODE_CHECKLIST:
              Begin
              If MODE_DEBUG Then
                 SwitchToLogWindow;
              If StrUp(GetVar(LanguageTag.Tag,_varNONE))=RussianTag Then
                Begin
                 If MODE_DEBUG Then
                   Begin
                    SwitchToFullWindow;
                    TextColor(LightRed);
                   End;
                 GotoXy(11,7);
                 WriteLn('Проверка сегмента');
                End
              Else
                Begin
                 If MODE_DEBUG Then
                   Begin
                    SwitchToFullWindow;
                    TextColor(LightRed);
                   End;
                 GotoXy(11,7);
                 WriteLn('Check listsegment');
                End;
              End;
   End;
{ Addr:=GetVar(MasterAddressTag.Tag,_varNONE);}
 GotoXy(14,8);
{ If MODE_DEBUG Then}
    SwitchToLogWindow;
 Addr:=GetVar(MasterAddressTag.Tag,_varNONE);
{ If MODE_DEBUG Then}
   Begin
    SwitchToFullWindow;
    TextColor(LightRed);
   End;
 GotoXy(14,8);
 WriteLn(Addr);
 {GotoXy(1,3);
 TextColor(15);}
 {.ENDIF}
 SwitchToLogWindow;
 {$ENDIF}
End;

Procedure RestoreScreenHandler;
Begin
End;

Procedure SetScreenHandler;
Begin
End;

Procedure InitializeScreen;
Begin
 WriteScreenSkeleton;
 CharsCounter:=1;
 SwitchToLogWindow;
 TextColor(15);
 TextBackGround(1);
End;

Procedure DoneScreen;
Begin
 ScrCounter:=20;
 RefreshScreen;
 SwitchToFullWindow;
 TextColor(7);
 TextBackGround(0);
End;

Procedure DoneScreenForHelpRequest;
Begin
 SwitchToFullWindow;
 TextColor(7);
 TextBackGround(0);
End;


Begin
 SwitchToFullWindow;
 GotoXY(1,1);
 OldX:=1;
 OldY:=1;
 OldXF:=1;
 OldYF:=1;
 IntCounter:=0;
 ScrCounter:=0;
 TimeSliceTimes:=-1;
End.
