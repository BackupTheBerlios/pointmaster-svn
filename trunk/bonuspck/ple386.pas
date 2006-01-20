Uses InitOvr,Crt,Objects,App,Views,Dialogs,StdDlg,Drivers,Menus,PointLst,Dos,PLEUnit,TScript,Incl,MsgBoxA,TVCC,StrUnit,
     PleUnit2,Common;


Type
  PSimplePointListEditor=^TSimplePointListEditor;
  TSimplePointListEditor=Object(TTVCCApplication)
   Constructor Init;
   Procedure Idle;Virtual;
   Procedure InitStatusLine;Virtual;
   Procedure InitMenuBar;Virtual;
   Procedure HandleEvent(Var Event:TEvent);Virtual;
   Procedure OpenPointList;
   Procedure ProcessPointList;
End;


Function IsCommentsBeforeBoss:Word;
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
   Insert(New(PTVCCButton,Init(R,'~Y~es',cmOk,bfDefault)));
   R.Assign(18,5,28,8);
   Insert(New(PTVCCButton,Init(R,'~N~o',cmCancel,bfNormal)));
   SelectNext(False);
  End;
IsCommentsBeforeBoss:=DeskTop^.ExecView(Dlg);
End;


Constructor TSimplePointListEditor.Init;
Var
R:TRect;
Event:TEvent;
Begin
Inherited Init;
R.Assign(19,5,57,16);
MessageBoxRect(R,
           '   BonusPack for PointMaster  '^M+
           'Simple PointList Editor v.0.01  '^M^M+
           'Copyright (c) by Andrew Kornilov'^M+
           '      2:5045/46.24@FidoNet'^M
           ,Nil,mfInformation+mfOkButton);
Event.What:=evCommand;
Event.Command:=cmOpenPointList;
PutEvent(Event);
End;

Procedure TSimplePointListEditor.InitMenubar;
Var
R:TRect;
Begin
GetExtent(R);
R.B.Y:=Succ(R.A.Y);
MenuBar:=New(PMenuBar,Init(R,
 NewMenu(
  NewSubMenu('~Ф~айл',hcNoContext,
   NewMenu(
    NewItem(
            '~О~ткpыть поинтлист','F3',kbF3,cmOpenPointList,hcNoContext,
    NewItem(
            '~В~ыход','Alt-X',kbAltX,cmQuit,hcNoContext,
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
  NewStatusKey('[~Alt-X~ Выход]',kbAltX,cmQuit,
  NewStatusKey('[~F1~]',kbF1,cmHelp,
  NewStatusKey('[~Alt-F3~ Закpыть окно]',kbAltF3,cmClose,
  NewStatusKey('[~I~ns]',kbIns,cmInsert,
  NewStatusKey('[~D~el]',kbDel,cmDelete,
  NewStatusKey('[~F4~]',kbF4,cmEdit,
  NewStatusKey('[~F7~]',kbF7,cmSearch,
  NewStatusKey('[~F10~ Меню]',kbF10,cmMenu,
  Nil)))))))),
 Nil)));
DisableCommands(EditorCommands);
End;

Procedure TSimplePointListEditor.Idle;
Begin
Inherited Idle;
{Inline($b4/$01/$b5/$20/$b1/$20/$cd/$10);}
{TextColor(0);
TextBackGround(7);
GotoXy(66,1);
WriteLn('Memory: ',(MemAvail div 1024):3, ' kb');}
{Inline($b4/$01/$b5/$05/$b1/$06/$cd/$10);}
End;

Procedure TSimplePointListEditor.OpenPointList;
Var
PFD:PFileDialog;
Control:Word;
Path:PathStr;
Begin
If ParamCount<>0 Then
  Begin
    CurrentPointListName:=FExpand(ParamStr(1));
    SetVar(CommentsBeforeBossTag,Yes,_flgNone);
    Case IsCommentsBeforeBoss Of
         cmOk:SetVar(CommentsBeforeBossTag,Yes,_flgNone);
         cmCancel:SetVar(CommentsBeforeBossTag,No,_flgNone);
     End;
    InitPointList(FExpand(ParamStr(1)));
    EnableCommands(EditorCommands);
    ProcessPointList;
    Exit;
  End
Else
New(PFD,Init('*.PVT','Откpыть поинтлист:','Имя файла',fdOpenButton,0));
Control:=Desktop^.ExecView(PFD);
Case Control Of
  StdDlg.cmFileOpen,cmOk:
                        Begin
                         PFD^.GetFileName(Path);
                         CurrentPointListName:=Path;
                         SetVar(CommentsBeforeBossTag,Yes,_flgNone);
                         Case IsCommentsBeforeBoss Of
                           cmOk:SetVar(CommentsBeforeBossTag,Yes,_flgNone);
                           cmCancel:SetVar(CommentsBeforeBossTag,No,_flgNone);
                          End;
                         InitPointList(Path);
                         EnableCommands(EditorCommands);
                         ProcessPointList;
                        End;
  End;
Dispose(PFD,Done);
End;


Procedure TSimplePointListEditor.ProcessPointList;
Var
BossWindow:PPointListEditor;
Control:Word;
Begin
BossWindow:=New(PPointListEditor,Init);
Control:=DeskTop^.ExecView(BossWindow);
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
Write('SPLE v.0.01');
TextColor(11);
WriteLn('   Simple pointlist editor');
TextColor(14);
WriteLn('          Copyright (c) 1998 by Andrew Kornilov. 2:5045/46.24@FidoNet');
TextColor(15);
WriteLn(#13#10'Usage:'#13#10);
TextColor(7);
Write('SPLE.EXE  ');
TextColor(14);
WriteLn(' infile [/O<outfile>] [/D] [/S<n>]');
WriteLn(#13#10);
TextColor(15);
Write('  infile');
TextColor(7);
WriteLn('       - Name of poinlist(-s) to edit. Wildcards (*,?) are allowed');
TextColor(15);
Write('  /O<outfile>');
TextColor(7);
WriteLn('  - Output filename to save pointlist');
TextColor(15);
Write('  /D');
TextColor(7);
WriteLn('           - Delete pointlist(-s) ');
TextColor(15);
Write('  /S<n>');
TextColor(7);
WriteLn('        - Skip <n> strings at begin of poinlist(-s)'#13#10+
        '                  (i.e. for skip pointlist header)');
TextColor(7);
WriteLn('        You may run it also without any parameters');
TextColor(14);
Write(#13#10'EXAMPLE: ');
TextColor(7);
WriteLn(' SPLE.EXE pnt50*.pvt /olist50.pvt /d /s5');
WriteLn('          SPLE.EXE pnt*.pvt /s3');
TextColor(15);
WriteLn(#10'               See documentation for more information !');
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
        If (ParamString[1])='S' Then
           Begin
            Delete(ParamString,1,1);
            SetVar(StringsToSkipAtBeginOfListTag,ParamString,_flgNone);
           End
       Else
        If (ParamString)='D' Then
           Begin
            SetVar(DeleteListAfterProcessTag,Yes,_flgNone);
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
            SetVar(DestPointListNameTag,ParamString,_flgNone);
           End
       End;
   End;
End;

Var
PLE:TSimplePointListEditor;

Begin
 DuplicateBosses:=0;
 WrongPoints:=0;
 SetVar(CurDateStrTag,GetDateString,_flgNone);
 SetVar(CurTimeStrTag,GetTimeString,_flgNone);
 SetVar(CommentsBeforeBossTag,Yes,_flgNone);
 SetVar(StringsToSkipAtBeginOfListTag,'0',_flgNone);
 SetVar(AddSemicolonAfterEachBossTag,Yes,_flgNone);
 SetVar(ValidateStringTag,'Point;,*#;,*|;,*|;,*|;,{-Unpublished-,*#[-]*#[-]*#[-]*#};,*#;,*@',_flgNone);
 SetVar(UseValidateTag,Yes,_flgNone);
 SetVar(DeleteListAfterProcessTag,No,_flgNone);
 SetVar(_tplPntListHeader,'HEADER.TXT',_flgNone);
 SetVar(_tplPntListFooter,'FOOTER.TXT',_flgNone);
 SetVar(EditorNameTag,'Simple Pointlist Editor v.0.01',_flgNone);
 If ParamCount<>0 Then
    SetVar(DestPointListNameTag,ParamStr(1),_flgNone);
 ProcessCmdString;
PLE.Init;
PLE.Run;
PLE.Done;
End.