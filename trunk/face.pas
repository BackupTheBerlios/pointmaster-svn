UNIT Face;
{$I VERSION.INC}
INTERFACE
Uses
{$IFDEF VIRTUALPASCAL}
Use32,
{$ENDIF}
Incl,Crt,{Drivers,}StrUnit,Dos,Objects,Parser,Os_Type,Drivers,Register,
     MCommon,Crc_32,FileIO;
{.F+,S-,W-}


Var
CharsCounter:Byte;
SavedInt1C,
SavedInt29:Procedure;
{SavedInt1C,
SavedInt29:Pointer;}
IntCounter:ShortInt;
ScrCounter:Byte;

{IsLogWindowActive,
IsInfoWindowActive:Boolean;}
OldX,OldY,
OldXF,OldYF:Word;
C:Char;
Var
StartHour,StartMinutes,StartSec,StartHnd:Word;

Procedure WriteScreenSkeleton;Far;
Procedure WritePerCent;Far;
{$IFNDEF VIRTUALPASCAL}
Procedure ScreenHandler;Interrupt;
{$ENDIF}
Procedure RefreshScreen;
Procedure DoneScreenForHelpRequest;
Procedure RestoreScreenHandler;Far;
Procedure SetScreenHandler;Far;
{Procedure RedirectOutput;Far;
Procedure RestoreOutput;Far;}
Procedure PreUpdateScreen;Far;
Procedure InitializeScreen;Far;
Procedure DoneScreen;Far;
Procedure SwitchToLogWindow;Far;
{Procedure SwitchToInfoWindow;Far;}
Procedure SwitchToFullWindow;Far;
{$IFNDEF VIRTUALPASCAL}
Procedure CursorOff;Far;
Procedure CursorOn;Far;
{$ENDIF}
Procedure DisplayHelpWindow;Far;
Function  GetMinutesFromStart:Word;
Procedure PrepareScreenToExec;

IMPLEMENTATION

Uses Logger;

{$IFNDEF VIRTUALPASCAL}

{$IFNDEF SPLE}
{$IFDEF STABLE}
{$L PMAST03.OBJ}
Procedure Scr_Skelet_Data;External;

{$L HELP01.OBJ}
Procedure Help1_Skeleton;External;

{$L HELP02.OBJ}
Procedure Help2_Skeleton;External;

{$L HELP03.OBJ}
Procedure Help3_Skeleton;External;
{$ENDIF}
{$ENDIF}
{$ENDIF}


Procedure WriteVersion;Far;
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
(* {$IFNDEF VIRTUALPASCAL}
 CursorOff;
{$IFDEF DPMI}
 Move(Pointer(@Help1_Skeleton)^,Ptr(SegB800,0)^,4000);
{$ELSE}
 Move(Pointer(@Help1_Skeleton)^,Ptr($B800,0)^,4000);
{$ENDIF}
 WriteVersion;
 Repeat
{ While (Not KeyPressed) Do}
    TimeSlice;
 Until KeyPressed;
{$IFDEF DPMI}
 Move(Pointer(@Help2_Skeleton)^,Ptr(SegB800,0)^,4000);
{$ELSE}
 Move(Pointer(@Help2_Skeleton)^,Ptr($B800,0)^,4000);
{$ENDIF}
 WriteVersion;
 While KeyPressed Do
       ReadKey;
 While (Not KeyPressed) Do
    TimeSlice;
{$IFDEF DPMI}
 Move(Pointer(@Help3_Skeleton)^,Ptr(SegB800,0)^,4000);
{$ELSE}
 Move(Pointer(@Help3_Skeleton)^,Ptr($B800,0)^,4000);
{$ENDIF}
 WriteVersion;
 {$ENDIF}*)
End;

Procedure WriteScreenSkeleton;
Const
KeyFile='pm.key';
RegPhrase='Registered to: ';
Var
Ri:RegisterInformation;
OldDosError:System.Integer;
Crc32S:String;
RegName:String;
Begin
 {.IFNDEF VIRTUALPASCAL}
 If MODE_NOCONSOLE Then
    Exit;
 OldDosError:=DosError;
 If IsFileExist(KeyFile) Then
   Begin
    ReadKeyFile(KeyFile,RI);
    Ri.BackGround:=1 Xor Ri.Offset;
    Ri.TextColor:=12 Xor Ri.Offset;
    Ri.Offset:=Ri.Offset Xor Ri.Crc;
    Crc32S:=ShowCrc(Ri.Crc);
    PntMasterVersion:=BaseVersion+
    {$IFDEF DPMI}
    '[DPMI]'
    {$ENDIF}
    {$IFDEF MSDOS}
    '[DOS]'
    {$ENDIF}
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
    RegName:=GetUncryptedString(Ri.Name,Ri.CRC);
    GotoXy(((ScreenWidth-2) div 2) - ((Length(RegPhrase)+Length(RegName)+2) div 2),9);
    TextColor(LightGray);
    TextBackground(1);
    Write('[ ');
    TextColor(LightGreen);
    Write(RegPhrase);
    TextColor(Yellow);
    Write(RegName);
    TExtColor(LightGray);
    Write(' ]');
    DosError:=OldDosError;
   End
 Else
   Begin
    DosError:=OldDosError;
    Crc32S:='UNREG';
    PntMasterVersion:=BaseVersion+
    {$IFDEF DPMI}
    '[DPMI]'
    {$ENDIF}
    {$IFDEF MSDOS}
    '[DOS]'
    {$ENDIF}
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
    {$IFDEF DPMI}
    '[DPMI]'
    {$ENDIF}
    {$IFDEF MSDOS}
    '[DOS]'
    {$ENDIF}
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
    {$IFDEF DPMI}
    '[DPMI]'
    {$ENDIF}
    {$IFDEF MSDOS}
    '[DOS]'
    {$ENDIF}
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

 If Crc32S='UNREG' Then
   Begin
    GotoXy(((ScreenWidth-1) div 2)-10,9);
    TextColor(LightGray);
    Write('[');
    TextColor(LightRed);
    Write('UNREGISTERED COPY');
    TextColor(LightGray);
    Write(']');
  End;
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
 {.ENDIF}
End;

{$IFNDEF VIRTUALPASCAL}
Procedure CursorOff;assembler;
Asm
   mov ah,01h
   mov ch,$20
   mov cl,$20
   int 10h
End;

Procedure CursorOn;assembler;
Asm
   mov ah,01h
   mov ch,$5
   mov cl,$6
   int 10h
End;
{$ENDIF}

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
 {.IFNDEF VIRTUALPASCAL}
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

Procedure WriteMemory;Far;
Var
S:String;
Begin
 {.IFNDEF VIRTUALPASCAL}
 S:=IntToStr(MemAvail div 1024)+' kb';
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
 {.ENDIF}
End;

Procedure WriteOperation;Far;
Var
Count:Word;
Begin
{.IFNDEF VIRTUALPASCAL}
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

Procedure WriteRunTimeChars;Far;
Const
Chars:Array[1..4] of Char=('-','\','|','/');
Begin
 {.IFNDEF VIRTUALPASCAL}
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

{$IFNDEF VIRTUALPASCAL}
Procedure ScreenHandler;
Begin
 If @SavedInt1C<>Nil Then
   Begin
    Asm
      pushf;
    End;
    SavedInt1C;
   End;
If TimeSliceTimes In [1..18] Then
 Begin
    If IntCounter>=(Round(18.2/TimeSliceTimes)) Then
      Begin
       TimeSlice;
       IntCounter:=0;
      End;
  Inc(IntCounter);
 End;
 Port[$20]:=$20;
End;
{$ENDIF}

{
Procedure RedirectOutput;
Begin
 OldX:=1;
 OldY:=1;
 TextColor(7);
 TextBackGround(0);
 GetIntVec($29,@SavedInt29);
 SetIntVec($29,@Int29Handler);
 Window(1,1,1,1);
End;

Procedure RestoreOutput;
Begin
 If @SavedInt29<>Nil Then
    SetIntVec($29,@SavedInt29);
End;}

Procedure PreUpdateScreen;
Var
TaskStr:String;
OsStr:String;
Addr:String;
Begin
 {$IFNDEF SPLE}
 {.IFNDEF VIRTUALPASCAL}
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
    {$IFDEF DPMI}
    '[DPMI]'
    {$ENDIF}
    {$IFDEF MSDOS}
    '[DOS]'
    {$ENDIF}
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
 If MODE_NOCONSOLE Then
    Exit;
 {$IFNDEF VIRTUALPASCAL}
 If @SavedInt1C<> Nil Then
    SetIntVec($1C,@SavedInt1C);
 {$ENDIF}
 SavedInt1C:=Nil;
End;

Procedure SetScreenHandler;
Begin
 If MODE_NOCONSOLE Then
    Exit;
 {$IFNDEF VIRTUALPASCAL}
 If @SavedInt1C=Nil Then
    Begin
     GetIntVec($1C,@SavedInt1C);
     SetIntVec($1C,@ScreenHandler);
    End;
 {$ENDIF}
End;

Procedure InitializeScreen;
Begin
{ CursorOff;}
 WriteScreenSkeleton;
 CharsCounter:=1;
 SwitchToLogWindow;
 TextColor(15);
 TextBackGround(1);
{ SetScreenHandler;}
End;

Procedure DoneScreen;
Begin
 ScrCounter:=20;
 RefreshScreen;
{ CursorOn;}
{ RestoreScreenHandler;}
 SwitchToFullWindow;
 TextColor(7);
 TextBackGround(0);
End;

Procedure DoneScreenForHelpRequest;
Begin
{ CursorOn;}
{ RestoreScreenHandler;}
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
 {$IFNDEF VIRTUALPASCAL}
 @SavedInt1C:=Nil;
 @SavedInt29:=Nil;
 {$ENDIF}
 IntCounter:=0;
 ScrCounter:=0;
 TimeSliceTimes:=-1;
End.
