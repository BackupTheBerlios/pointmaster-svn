{$DEFINE SPLE}
{$I VERSION.INC}
Uses {InitOvr,}FvConsts,Crt,Objects,App,Views,Dialogs,StdDlg,Drivers,Menus,
     PntL_Obj,Pm_Obj,PointLst,Dos,PLEUnit,Parser,Incl,MsgBox,StrUnit,
     PleUnit2,MCommon,Ple_Incl,Os_Type,Config,Logger,Dates;

Type
  PSimplePointListEditor=^TSimplePointListEditor;
  TSimplePointListEditor=Object(TApplication)
   Constructor Init;
   Procedure Idle;Virtual;
   Procedure InitStatusLine;Virtual;
   Procedure InitMenuBar;Virtual;
   Procedure HandleEvent(Var Event:TEvent);Virtual;
   Procedure OpenPointList;
   Procedure ProcessPointList;
   Destructor Done;Virtual;
End;


{Function IsCommentsBeforeBoss:Word;
Var
R:TRect;
Dlg:PDlgWindow;
Begin
R.Assign(20,4,57,13);
Dlg:=New(PDlgWindow,Init(R,'Выбеpите нyжное'));
With Dlg^ Do
  Begin
   R.Assign(2,1,33,4);
   Insert(New(PStaticText,Init(R,^M'   Комментаpии в поинтлисте'^M'   пpописаны до стpоки босса ?')));
   R.Assign(7,5,17,8);
   Insert(New(PButton,Init(R,'~Y~es',cmOk,bfDefault)));
   R.Assign(18,5,28,8);
   Insert(New(PButton,Init(R,'~N~o',cmCancel,bfNormal)));
   SelectNext(False);
  End;
IsCommentsBeforeBoss:=DeskTop^.ExecView(Dlg);
End;}


Constructor TSimplePointListEditor.Init;
Var
R:TRect;
Event:TEvent;
Begin
Inherited Init;
If BossRecArray=Nil Then
   BossRecArray:=New(PBossRecSortedCollection,Init(10,10));
R.Assign(19,5,57,16);
MessageBoxRect(R,
           '   BonusPack for PointMaster  '^M+
           'Simple PointList Editor v.0.02  '^M^M+
           'Copyright (c) by Andrew Kornilov'^M+
           '      2:5045/46.24@FidoNet'^M
           ,Nil,mfInformation+mfOkButton);
Event.What:=evCommand;
Event.Command:=cmOpenPointList;
PutEvent(Event);
End;

Destructor TSimplePointListEditor.Done;
Begin
If BossRecArray<>Nil Then
   Dispose(BossRecArray,Done);
Inherited Done;
End;

Procedure TSimplePointListEditor.InitMenubar;
Var
R:TRect;
Begin
GetExtent(R);
R.B.Y:=Succ(R.A.Y);
MenuBar:=New(PMenuBar,Init(R,
 NewMenu(
  NewSubMenu('~F~ile',hcNoContext,
   NewMenu(
    NewItem(
            '~O~pen pointlist','F3',kbF3,cmOpenPointList,hcNoContext,
    NewItem(
            'E~x~it','Alt-X',kbAltX,cmQuit,hcNoContext,
   Nil))),
  Nil))));
End;

Procedure TSimplePointListEditor.InitStatusLine;
Var
R:TRect;
Begin
GetExtent(R);
R.A.Y:=Pred(R.B.Y);
StatusLine:=New(PStatusLine,Init(R,
 NewStatusDef(0,$FFFF,
  NewStatusKey('[~Alt-X~ Exit]',kbAltX,cmQuit,
  NewStatusKey('[~F1~]',kbF1,cmHelp,
  NewStatusKey('[~Alt-F3~ Close window]',kbAltF3,cmClose,
  NewStatusKey('[~I~ns]',kbIns,cmInsert,
  NewStatusKey('[~D~el]',kbDel,cmDelete,
  NewStatusKey('[~F4~]',kbF4,cmEdit,
  NewStatusKey('[~F7~]',kbF7,cmSearch,
  NewStatusKey('[~F10~ Menu]',kbF10,cmMenu,
  Nil)))))))),
 Nil)));
DisableCommands(EditorCommands);
End;

Procedure TSimplePointListEditor.Idle;
Var
S:String;
Count:Byte;
Begin
Inherited Idle;
{Inline($b4/$01/$b5/$20/$b1/$20/$cd/$10);}
{TextColor(0);
TextBackGround(7);
GotoXy(66,1);
WriteLn('Memory: ',(MemAvail div 1024):3, ' kb');}
{Inline($b4/$01/$b5/$05/$b1/$06/$cd/$10);}
{S:='Memory: '+IntToStr(MemAvail div 1024)+' kb';}
{FIXME MemAvail}
S:='Memory: FIXME kb';
{MoveStr(Mem[SegB800:(80*0)+(65*2)],'Memory: '+IntToStr(MemAvail div 1024)+' kb',0);}
{FIXME 
For Count:=1 To Length(S) Do
    Mem[SegB800:(63*2)+(Count*2)]:=Ord(S[Count]);
}
TimeSlice;
End;

Procedure TSimplePointListEditor.OpenPointList;
Var
PFD:PFileDialog;
Control:Word;
Path:PathStr;
FNameVar,FName,Skip:String;
SpacePos:Byte;
Begin
If ListNameOverrided Then
  Begin
   { CurrentPointListName:=FExpand(ParamStr(1));}
{{{    SetVar(CommentsBeforeBossTag,Yes,_flgNone);
{    Case IsCommentsBeforeBoss Of
         cmOk:SetVar(CommentsBeforeBossTag,Yes,_flgNone);
         cmCancel:SetVar(CommentsBeforeBossTag,No,_flgNone);
     End;}
    LoadExcludeList;
    InitPointList(GetVar(PointListNameTag.Tag,_varNONE));
    EnableCommands(EditorCommands);
    ProcessPointList;
    Exit;
  End
Else
FNameVar:=StrTrim(GetVar(PointListNameTag.Tag,_varNONE));
SpacePos:=Pos(' ',FNameVar);
If SpacePos>0 Then
   Begin
    FName:=Copy(FNameVar,1,SpacePos-1);
    Skip:=StrTrim(Copy(FNameVar,SpacePos,Length(FNameVar)));
   End
  Else
   Begin
    FName:=FNameVar;
    Skip:='';
   End;
New(PFD,Init({'*.PVT'}FName,'Open pointlist:','File name',fdOpenButton,0));
Control:=Desktop^.ExecView(PFD);
Case Control Of
  cmFileOpen,cmOk:
                        Begin
                         PFD^.GetFileName(Path);
                         {CurrentPointListName:=Path;}
{{{                         SetVar(CommentsBeforeBossTag,Yes);
                         {Case IsCommentsBeforeBoss Of
                           cmOk:SetVar(CommentsBeforeBossTag,Yes);
                           cmCancel:SetVar(CommentsBeforeBossTag,No);
                          End;}
                         LoadExcludeList;
                         InitPointList(Path+' '+Skip);
                         EnableCommands(EditorCommands);
                         ProcessPointList;
                        End;
  End;
If PFD<>Nil Then
   Dispose(PFD,Done);
End;


Procedure TSimplePointListEditor.ProcessPointList;
Var
BossWindow:PPointListEditor;
Control:Word;
Begin
BossWindow:=New(PPointListEditor,Init);
Control:=DeskTop^.ExecView(BossWindow);
If BossWindow<>Nil Then
   Dispose(BossWindow,Done);
End;


Procedure TSimplePointListEditor.HandleEvent(Var Event:TEvent);
Begin
TApplication.HandleEvent(Event);
If Event.What=evCommand Then
   Case Event.Command of
     cmOpenPointList:OpenPointList;
     cmQuit:;
    End
Else
 Exit;
ClearEvent(Event);
End;

Procedure DisplayHelpScreen;
Begin
ClrScr;
TextColor(15);
Write('SPLE v.0.02');
TextColor(11);
WriteLn('   Simple pointlist editor');
TextColor(14);
WriteLn('          Copyright (c) 1999 by Andrew Kornilov. 2:5045/46.24@FidoNet');
TextColor(15);
WriteLn(#13#10'Usage:'#13#10);
TextColor(7);
Write('SPLE.EXE  ');
TextColor(14);
WriteLn(' [/C<config>] [/L<infile>] [/O<outfile>] [/D] [/A] [/B]');
WriteLn(#13#10);
TextColor(15);
Write('  <config>');
TextColor(7);
WriteLn('  - Override name of config file. Default is SPLE.CTL');
TextColor(15);
Write('  <infile>');
TextColor(7);
WriteLn('  - Override name of poinlist(-s) to edit.Wildcards (*,?) are allowed');
TextColor(15);
Write('  <outfile>');
TextColor(7);
WriteLn(' - Override output filename to save pointlist');
TextColor(15);
Write('  /D');
TextColor(7);
WriteLn('        - Delete pointlist(-s) after loading');
TextColor(15);
Write('  /A');
TextColor(7);
WriteLn('        - Comments after boss');
TextColor(15);
Write('  /B');
TextColor(7);
WriteLn('        - Comments before boss');

TextColor(7);
WriteLn('        You may run it also without any parameters');
TextColor(14);
Write(#13#10'EXAMPLE: ');
TextColor(7);
WriteLn(' SPLE.EXE pnt50*.pvt /olist50.pvt /d');
WriteLn('          SPLE.EXE pnt*.pvt /a');
TextColor(15);
WriteLn(#10'               See documentation for more information !');
End;


Procedure CheckIsUseAnotherConfig;
Var
Count:Integer;
ParamString:String;
Begin
If ParamCount>0 Then
   Begin
    For Count:=1 To ParamCount Do
       Begin
        ParamString:=StrUp(ParamStr(Count));
        If (ParamString[1]='-') or (ParamString[1]='/') Then
           Delete(ParamString,1,1);
        If (ParamString[1])='C' Then
           Begin
            Delete(ParamString,1,1);
            SetVar(ConfigNameTag,ParamString);
           End
       End;
   End;
End;

Procedure ProcessCmdString;
Var
Count:Integer;
ParamString:String;
Begin
If ParamCount>0 Then
   Begin
    For Count:=1 To ParamCount Do
       Begin
        ParamString:=StrUp(ParamStr(Count));
        If (ParamString[1]='-') or (ParamString[1]='/') Then
           Delete(ParamString,1,1);
{{{        If (ParamString[1])='S' Then
           Begin
            Delete(ParamString,1,1);
            {SetVar(StringsToSkipAtBeginOfListTag,ParamString);}
 {          End
       Else}
        If (ParamString[1])='L' Then
           Begin
            Delete(ParamString,1,1);
            SetVar(PointListNameTag,ParamString);
            ListNameOverrided:=True;
           End
       Else
        If (ParamString)='D' Then
           Begin
            SetVar(DeleteListAfterProcessTag,Yes);
           End
       Else
        If (ParamString)='B' Then
           Begin
            SetVar(CommentsBeforeBossTag,Yes);
           End
       Else
        If (ParamString)='A' Then
           Begin
            SetVar(CommentsBeforeBossTag,No);
           End
       Else
        If (ParamString='?') or (ParamString='H') or (ParamString='HELP') Then
           Begin
            DisplayHelpScreen;
            Halt(0);
           End
       Else
        If (ParamString[1])='O' Then
           Begin
            Delete(ParamString,1,1);
            SetVar(DestPointListNameTag,ParamString);
           End
       End;
   End;
End;

Var
PLE:TSimplePointListEditor;

Begin
 DuplicateBosses:=0;
 ErrorPoints:=0;
 ListNameOverrided:=False;
 MODE_NOCONSOLE:=True;
 SetVar(ConfigNameTag,'sple.ctl');
{ SetVar(CurDateStrTag,GetDateString);
 SetVar(CurTimeStrTag,GetTimeString);}

 SetVar(CurDateStrTag,GetDateString);
 SetVar(CurTimeStrTag,GetTimeString);
 SetVar(DayOfWeekTag,GetDoWString);
 SetVar(DayOfYearTag,GetDoYString);
 SetVar(YearTag,GetYearString);
 SetVar(MonthTag,GetMonthString);
 SetVar(DayTag,GetDayString);
 SetVar(MonthNameTag,GetMonthNameString);

 SetVar(CommentsBeforeBossTag,Yes);
 SetVar(AddSemicolonAfterEachBossTag,Yes);


 SetVar(UseValidateTag,Yes);
 SetVar(AllowedCharsTag,'33..126');
 SetVar(ExcludeTag,'');
 SetVar(GetExcludeFromNodelistTag,'');
 SetVar(ExcludeStatusTag,'DOWN');
 SetVar(PhoneMaskTag,'');
 SetVar(SpeedFlagsTag,'');
 SetVar(SystemFlagsTag,'');
 SetVar(UserFlagsTag,'');

 SetVar(DeleteListAfterProcessTag,No);
 SetVar(_tplPntListHeader,'header.txt');
 SetVar(_tplPntListFooter,'footer.txt');

 SetVar(MasterVerTag,SpleVersion);

 CheckIsUseAnotherConfig;
{ InitLog(Log);}
 ReadConfig(GetVar(ConfigNameTag.Tag,_varNONE));
 ProcessCmdString;
 PLE.Init;
 PLE.Run;
 PLE.Done;
{ DoneLog(Log);}
End.
