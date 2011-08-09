unit PLEUNIT2;

interface

uses Drivers, Objects, Views, Dialogs,PointLst,Incl,Validate,MsgBox,App,StrUnit,
     MCommon,Ple_Incl,Parser,PntL_Obj;


Const

EditorCommands:TCommandSet=[cmInsert,cmDelete,cmSearch,cmEdit];
OtherCommands:TCommandSet=[cmQuit];
HelpCommand:TCommandSet=[cmHelp];

Type
  PPointValidator=^TPointValidator;
  TPointValidator=Object(TPXPictureValidator)
   Procedure Error;Virtual;
End;



Type
  PPointList=^TPointList;
  TPointList=Object(TListBox)
{   PointsCollection:PPointsCollection;}
   Constructor Init(Var Bounds: TRect; ANumCols: Word; AScrollBar:
                   PScrollBar);
   Destructor Done;Virtual;
   Procedure HandleEvent(Var Event:TEvent);Virtual;
   procedure NewList(AList: PCollection); virtual;
End;

Type
  PCommentList=^TCommentList;
  TCommentList=Object(TListBox)
{   CommentsCollection:PCommentsCollection;}
   Constructor Init(Var Bounds: TRect; ANumCols: Word; AScrollBar:
                   PScrollBar);
   Destructor Done;Virtual;
   Procedure HandleEvent(Var Event:TEvent);Virtual;
   procedure NewList(AList: PCollection); virtual;
End;



  { TPointListEditor }

  PPointCommentEditor = ^TPointCommentEditor;
  TPointCommentEditor = object(TDialog)
    constructor Init;
    constructor Load(var S: TStream);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
    function Valid(Command : word): boolean; virtual;
    destructor Done; virtual;
  end;

const
  RPointListEditor : TStreamRec = (
    ObjType: 12345;            {<--- Insert a unique number >= 100 here!!}
    VmtLink: Ofs(Typeof(TPointCommentEditor)^);
    Load : @TPointCommentEditor.Load;
    Store : @TPointCommentEditor.Store);

Function ShowHelpWindow:Word;

implementation
{ TPointListEditor }

Procedure ReplaceTralingChars(Var S:String);
Var
Count:LongInt;
Begin
S:=StrTrim(S);
Count:=Pos(' ',S);
While Count>0 Do
 Begin
  System.Delete(S,Count,1);
  System.Insert('_',S,Count);
  Count:=Pos(' ',S);
 End;
Count:=Pos(#9,S);
While Count>0 Do
 Begin
  System.Delete(S,Count,1);
  System.Insert('_',S,Count);
  Count:=Pos(#9,S);
 End;

End;


Function ShowHelpWindow:Word;
Var
R:TRect;
HelpScroller:PScroller;
Begin
R.Assign(25,5,58,16);
MessageBoxRect(R,{'         Клавиши yпpавления   '^M+
                ''^M+}
                'Alt-F3,Esc - Close window'^M+
                'Ins        - Insert'^M+
                'Del        - Delete'^M+
                'F4         - Edit'^M+
                'F7         - Search'^M^M,
                Nil,mfInformation+mfOkButton);
End;

Procedure TPointValidator.Error;
Begin
 MessageBox('    Wrong input',Nil,mfError+mfOkButton);
End;


Constructor TPointList.Init(Var Bounds: TRect; ANumCols: Word; AScrollBar:
                   PScrollBar);
Var
Count:Integer;
Begin
Inherited Init(Bounds,ANumCols,AScrollBar);
{If PointsCollection=Nil Then
   PointsCollection:=New(PpointsCollection,Init(10,5));}
If FocusedBoss<BossRecArray^.Count Then
   Begin
{    For Count:=0 To Pred(PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.Count) Do
        PointsCollection^.Insert(NewStr(PString(PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.At(Count))^));}
     NewList(PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints);
   End
{NewList(PointsCollection);}
End;

Procedure TPointList.NewList(AList: PCollection);
Begin
{  if List <> nil then List^.DeleteAll;}
  List := AList;
  if AList <> nil then SetRange(AList^.Count)
  else SetRange(0);
  if Range > 0 then FocusItem(0);
  DrawView;
End;

Constructor TCommentList.Init(Var Bounds: TRect; ANumCols: Word; AScrollBar:
                   PScrollBar);
Var
Count:Integer;
Begin
Inherited Init(Bounds,ANumCols,AScrollBar);
{If CommentsCollection=Nil Then
   CommentsCollection:=New(PCommentsCollection,Init(10,5));}
If FocusedBoss<BossRecArray^.Count Then
   Begin
{    For Count:=0 To Pred(PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments^.Count) Do
        CommentsCollection^.Insert(NewStr(PString(PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments^.At(Count))^));}
     NewList(PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments);
   End;
{NewList(CommentsCollection);}
End;

Procedure TCommentList.NewList(AList: PCollection);
Begin
{  if List <> nil then List^.DeleteAll;}
  List := AList;
  if AList <> nil then SetRange(AList^.Count)
  else SetRange(0);
  if Range > 0 then FocusItem(0);
  DrawView;
End;

Destructor TPointList.Done;
Begin
{If PointsCollection<>Nil Then
   PointsCollection^.Done;}
Inherited Done;
End;

Destructor TCommentList.Done;
Begin
{If CommentsCollection<> Nil Then
   CommentsCollection^.Done;}
Inherited Done;
End;

Procedure TPointList.HandleEvent(Var Event:TEvent);

Procedure DeletePoint;
Var
LastFocus:Integer;
Begin
 If Focused<PBossRecord(BossrecArray^.At(FocusedBoss))^.PPoints^.Count Then
  Begin
   _flgWasEdited:=True;
{   PointsCollection^.AtFree(Focused);}
   PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.AtFree(Focused);
{   SetRange(PointsCollection^.Count);
   DrawView;}
    LastFocus:=Focused;
    NewList(PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints);
   If LastFocus<List^.Count Then
      FocusItem(LastFocus)
   Else
      FocusItem(List^.Count);
 End;
End;

Procedure InsertPoint(IsEdit:Boolean);
Var
PointDialog:PDialog;
R:TRect;
LastFocus:Integer;
S:String;
PointString,
PointSysNameString,
PointLocationString,
PointNameString,
PointPhoneString,
PointSpeedString,
PointFlagsString:PInputLine;
DestPointString:String;
Control:Word;
NumberValidator,
SysNameValidator,
LocationValidator,
NameValidator,
PhoneValidator,
SpeedValidator,
FlagsValidator:PPointValidator;
FillData:String;
TempData:String;
Begin
 If IsEdit Then
    S:='Edit'
Else
    S:='Insert';
R.Assign(8,0,66,23);
PointDialog:=New(PDialog,Init(R,S));
NumberValidator:=New(PPointValidator,Init('#[#][#][#][#]',True));
SysNameValidator:=New(PPointValidator,Init('*\',True));
LocationValidator:=New(PPointValidator,Init('*\',True));
NameValidator:=New(PPointValidator,Init('*\',True));
PhoneValidator:=New(PPointValidator,Init(GetVarByIndex(PhoneMaskTag.Tag,1,_varNONE),True));
SpeedValidator:=New(PPointValidator,Init(GetVarByIndex(SpeedFlagsTag.Tag,1,_varNONE),True));
FlagsValidator:=New(PPointValidator,Init('*/',True));
FillData:='';
TempData:='';
If (IsEdit) and (PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.Count<>0)
            and (Focused<PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.Count) Then
  Begin
{   FillData:=PString(PointsCollection^.At(Focused))^;}
   FillData:=PString(PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.At(Focused))^;
  End;
With PointDialog^ Do
 Begin

  R.Assign(14,2,21,3);
  PointString:=New(PInputLine,Init(R,5));
  PointString^.SetValidator(NumberValidator);
  PointString^.Options:=PointString^.Options or ofFramed;
  If FillData<>'' Then
     Begin
      System.Delete(FillData,1,6);
      TempData:=Copy(FillData,1,Pos(',',FillData)-1);
      PointString^.SetData(TempData);
      System.Delete(FillData,1,Pos(',',FillData));
     End;
  Insert(PointString);
  R.Assign(2,2,9,3);
  Insert(New(PLabel,Init(R,'Number',PointString)));

  R.Assign(14,5,44,6);
  PointSysNameString:=New(PInputLine,Init(R,50));
  PointSysNameString^.SetValidator(SysNameValidator);
  PointSysNameString^.Options:=PointSysNameString^.Options or ofFramed;
  If FillData<>'' Then
     Begin
      TempData:=Copy(FillData,1,Pos(',',FillData)-1);
      PointSysNameString^.SetData(TempData);
      System.Delete(FillData,1,Pos(',',FillData));
     End;
  Insert(PointSysNameString);
  R.Assign(2,5,10,6);
  Insert(New(PLabel,Init(R,'System',PointSysNameString)));

  R.Assign(14,8,44,9);
  PointLocationString:=New(PInputLine,Init(R,50));
  PointLocationString^.SetValidator(LocationValidator);
  PointLocationString^.Options:=PointLocationString^.Options or ofFramed;
  If FillData<>'' Then
     Begin
      TempData:=Copy(FillData,1,Pos(',',FillData)-1);
      PointLocationString^.SetData(TempData);
      System.Delete(FillData,1,Pos(',',FillData));
     End;
  Insert(PointLocationString);
  R.Assign(2,8,11,9);
  Insert(New(PLabel,Init(R,'Location',PointLocationString)));

  R.Assign(14,11,44,12);
  PointNameString:=New(PInputLine,Init(R,50));
  PointNameString^.SetValidator(NameValidator);
  PointNameString^.Options:=PointNameString^.Options or ofFramed;
  If FillData<>'' Then
     Begin
      TempData:=Copy(FillData,1,Pos(',',FillData)-1);
      PointNameString^.SetData(TempData);
      System.Delete(FillData,1,Pos(',',FillData));
     End;
  Insert(PointNameString);
  R.Assign(2,11,10,12);
  Insert(New(PLabel,Init(R,'Name',PointNameString)));

  R.Assign(14,14,44,15);
  PointPhoneString:=New(PInputLine,Init(R,50));
  PointPhoneString^.SetValidator(PhoneValidator);
  PointPhoneString^.Options:=PointPhoneString^.Options or ofFramed;
  If FillData<>'' Then
     Begin
      TempData:=Copy(FillData,1,Pos(',',FillData)-1);
      PointPhoneString^.SetData(TempData);
      System.Delete(FillData,1,Pos(',',FillData));
     End;
  Insert(PointPhoneString);
  R.Assign(2,14,10,15);
  Insert(New(PLabel,Init(R,'Phone',PointPhoneString)));

  R.Assign(14,17,44,18);
  PointSpeedString:=New(PInputLine,Init(R,50));
  PointSpeedString^.SetValidator(SpeedValidator);
  PointSpeedString^.Options:=PointSpeedString^.Options or ofFramed;
  If FillData<>'' Then
     Begin
      TempData:=Copy(FillData,1,Pos(',',FillData)-1);
      PointSpeedString^.SetData(TempData);
      System.Delete(FillData,1,Pos(',',FillData));
     End;
  Insert(PointSpeedString);
  R.Assign(2,17,10,18);
  Insert(New(PLabel,Init(R,'Speed',PointSpeedString)));

  R.Assign(14,20,44,21);
  PointFlagsString:=New(PInputLine,Init(R,70));
  PointFlagsString^.SetValidator(FlagsValidator);
  PointFlagsString^.Options:=PointFlagsString^.Options or ofFramed;
  If FillData<>'' Then
     Begin
      TempData:=FillData;
      PointFlagsString^.SetData(TempData);
      FillData:='';
     End;
  Insert(PointFlagsString);
  R.Assign(2,20,10,21);
  Insert(New(PLabel,Init(R,'Flags',PointFlagsString)));


  R.Assign(46,6,56,9);
  Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
  R.Assign(46,10,56,13);
  Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
  SelectNext(False);
 End;
{If (IsEdit) and (PointsCollection^.Count<>0) and (Focused<PointsCollection^.Count) Then
  Begin
   PointDialog^.SetData(PString(PointsCollection^.At(Focused))^);
  End;}
Draw;
Control:=DeskTop^.ExecView(PointDialog);
Draw;
If Control=cmOk Then
   Begin
    If (IsEdit) and (PointString^.Data^<>'') and (PointSysNameString^.Data^<>'') and (PointLocationString^.Data^<>'')
       and (PointNameString^.Data^<>'') and (PointPhoneString^.Data^<>'') and (PointSpeedString^.Data^<>'')
       and (PointFlagsString^.Data^<>'') Then
      Begin
       ReplaceTralingChars(PointString^.Data^);
       ReplaceTralingChars(PointSysNameString^.Data^);
       ReplaceTralingChars(PointLocationString^.Data^);
       ReplaceTralingChars(PointNameString^.Data^);
       ReplaceTralingChars(PointPhoneString^.Data^);
       ReplaceTralingChars(PointSpeedString^.Data^);
       ReplaceTralingChars(PointFlagsString^.Data^);
       PointFlagsString^.Data^:=LeftStrTrimByChar(PointFlagsString^.Data^,',');
       PointFlagsString^.Data^:=RightStrTrimByChar(PointFlagsString^.Data^,',');
       If Focused<PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.Count Then
          PString(PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.At(Focused))^:=
            'Point,'+PointString^.Data^+','+PointSysNameString^.Data^
           +','+PointLocationString^.Data^+','+PointNameString^.Data^
           +','+PointPhoneString^.Data^+','+PointSpeedString^.Data^
           +','+PointFlagsString^.Data^;

          PString(PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.At(Focused))^:=
           'Point,'+PointString^.Data^+','+PointSysNameString^.Data^
           +','+PointLocationString^.Data^+','+PointNameString^.Data^
           +','+PointPhoneString^.Data^+','+PointSpeedString^.Data^
           +','+PointFlagsString^.Data^;
          _flgWasEdited:=True;
      End
   Else
    If (PointString^.Data^<>'') and (PointSysNameString^.Data^<>'') and (PointLocationString^.Data^<>'')
       and (PointNameString^.Data^<>'') and (PointPhoneString^.Data^<>'') and (PointSpeedString^.Data^<>'')
       and (PointFlagsString^.Data^<>'') Then
      Begin
       ReplaceTralingChars(PointString^.Data^);
       ReplaceTralingChars(PointSysNameString^.Data^);
       ReplaceTralingChars(PointLocationString^.Data^);
       ReplaceTralingChars(PointNameString^.Data^);
       ReplaceTralingChars(PointPhoneString^.Data^);
       ReplaceTralingChars(PointSpeedString^.Data^);
       ReplaceTralingChars(PointFlagsString^.Data^);
       PointFlagsString^.Data^:=LeftStrTrimByChar(PointFlagsString^.Data^,',');
       PointFlagsString^.Data^:=RightStrTrimByChar(PointFlagsString^.Data^,',');
{       PointsCollection^.Insert(NewStr(
           'Point,'+PointString^.Data^+','+PointSysNameString^.Data^
           +','+PointLocationString^.Data^+','+PointNameString^.Data^
           +','+PointPhoneString^.Data^+','+PointSpeedString^.Data^
           +','+PointFlagsString^.Data^));}
       PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.Insert(NewStr(
           'Point,'+PointString^.Data^+','+PointSysNameString^.Data^
           +','+PointLocationString^.Data^+','+PointNameString^.Data^
           +','+PointPhoneString^.Data^+','+PointSpeedString^.Data^
           +','+PointFlagsString^.Data^));
       _flgWasEdited:=True;
      End;
  LastFocus:=Focused;
  {SetRange(PointsCollection^.Count);
  Draw;}
  NewList(PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints);
  If LastFocus<List^.Count Then
     FocusItem(LastFocus)
  Else
     FocusItem(List^.Count);
   End;
{
   NumberValidator^.Done;

   SysNameValidator^.Done;

   LocationValidator^.Done;

   NameValidator^.Done;

   PhoneValidator^.Done;
SpeedValidator^.Done;}
If PointDialog<>Nil Then
   Dispose(PointDialog,Done);
{FlagsValidator^.Done;}
End;

Procedure SearchPoint;
Var
SearchDialog:PDialog;
R:TRect;
S:String;
SearchString:PInputLine;
Count:Integer;
PointPos:Integer;
Begin
If (BossRecArray^.Count=0) or (PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.Count=0) Then
   Exit;
R.Assign(2,0,79,9);
SearchDialog:=New(PDialog,Init(R,'Search for point'));
With SearchDialog^ Do
  Begin
   R.Assign(2,3,75,4);
   SearchString:=New(PInputLine,Init(R,20));
   SearchString^.Options:=SearchString^.Options or ofFramed;
   Insert(SearchString);
   R.Assign(2,1,40,2);
   Insert(New(PLabel,Init(R,' Input part of string',SearchString)));
   R.Assign(24,5,34,8);
   Insert(New(PButton,Init(R,' ~O~k',cmOk,bfDefault)));
   R.Assign(37,5,47,8);
   Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
   SelectNext(False);
  End;
If DeskTop^.ExecView(SearchDialog)=cmCancel Then
 Begin
  If SearchDialog<>Nil Then
     Dispose(SearchDIalog,Done);
  Exit;
 End;
S:=SearchString^.Data^;
Count:=Focused;
For Count:=Focused To Pred(PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.Count)
{While (Pos(StrUp(S),StrUp(PString(PointsCollection^.At(Count))^))=0) And
      (Count<Pred(PointsCollection^.Count))} Do
     Begin
      PointPos:=Pos(StrUp(S),StrUp(PString(PBossRecord(BossRecArray^.At(FocusedBoss))^.PPoints^.At(Count))^));
      If PointPos>0 Then
         Break;
 { Inc(Count);}
     End;
If SearchDialog<>Nil Then
   Dispose(SearchDIalog,Done);
If (Count>Focused) And (PointPos>0) Then
  FocusItem(Count);
Draw;
End;


Begin
Inherited HandleEvent(Event);
if Event.What and evMessage <> 0 then
  case Event.Command of
     cmDelete: Begin
                DeletePoint;
               End;
     cmInsert:Begin
                DisableCommands(EditorCommands);
                DisableCommands(HelpCommand);
                DisableCommands(OtherCommands);
                InsertPoint(False);
                EnableCommands(EditorCommands);
                EnableCommands(HelpCommand);
                EnableCommands(OtherCommands);
              End;
     cmEdit:Begin
                DisableCommands(EditorCommands);
                DisableCommands(HelpCommand);
                DisableCommands(OtherCommands);
                InsertPoint(True);
                EnableCommands(EditorCommands);
                EnableCommands(HelpCommand);
                EnableCommands(OtherCommands);
            End;
     cmSearch:Begin
                DisableCommands(EditorCommands);
                DisableCommands(HelpCommand);
                DisableCommands(OtherCommands);
                SearchPoint;
                EnableCommands(EditorCommands);
                EnableCommands(HelpCommand);
                EnableCommands(OtherCommands);
              End;
     cmHelp:Begin
             DisableCommands(EditorCommands);
             DisableCommands(HelpCommand);
             DisableCommands(OtherCommands);
             ShowHelpWindow;
             EnableCommands(EditorCommands);
             EnableCommands(HelpCommand);
             EnableCommands(OtherCommands);
            End;
     cmViewBosses:EndModal(cmCancel);
     cmQuit:Begin
             EndModal(cmCancel);
             Event.What:=evCommand;
             Event.Command:=cmQuit;
             PutEvent(Event);
            End;
    end;
End;

Procedure TCommentList.HandleEvent(Var Event:TEvent);

Procedure DeleteComment;
Var
LastFocus:Integer;
Begin
 If Focused<PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments^.Count Then
  Begin
  _flgWasEdited:=True;
{  CommentsCollection^.AtFree(Focused);}
  PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments^.AtFree(Focused);
  LastFocus:=Focused;
{  SetRange(CommentsCollection^.Count);
  DrawView;}
  NewList(PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments);
  If LastFocus<List^.Count Then
     FocusItem(LastFocus)
  Else
     FocusItem(List^.Count);
 End;
End;

Procedure InsertComment(IsEdit:Boolean);
Var
CommentDialog:PDialog;
R:TRect;
S:String;
CommentString:PInputLine;
Control:Word;
Validator:PPointValidator;
CommTag:String;
LastFocus:Integer;
Begin
 If IsEdit Then
    S:='Edit'
Else
    S:='Insert';
R.Assign(2,4,79,13);
CommentDialog:=New(PDialog,Init(R,S));
Validator:=New(PPointValidator,Init(';;*@',True));
With CommentDialog^ Do
 Begin
  R.Assign(2,3,75,4);
  CommentString:=New(PInputLine,Init(R,250));
  CommentString^.SetValidator(Validator);
  CommentString^.Options:=CommentString^.Options or ofFramed;
  Insert(CommentString);
  R.Assign(2,1,27,2);
  Insert(New(PLabel,Init(R,'  Input comment',CommentString)));
  R.Assign(21,5,31,8);
  Insert(New(PButton,Init(R,'~O~k',cmOk,bfDefault)));
  R.Assign(34,5,44,8);
  Insert(New(PButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
  SelectNext(False);
 End;
CommTag:=';';
If (IsEdit) and (PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments^.Count<>0)
            and (Focused<PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments^.Count) Then
  Begin
   CommentDialog^.SetData(PString(PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments^.At(Focused))^);
  End
Else
  CommentDialog^.SetData(CommTag);
Draw;
Control:=DeskTop^.ExecView(CommentDialog);
Draw;
If Control=cmOk Then
   Begin
    If (IsEdit) and (CommentString^.Data^<>'')  Then
      Begin
       If Focused<PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments^.Count Then
         { PString(CommentsCollection^.At(Focused))^:=CommentString^.Data^;}
          PString(PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments^.At(Focused))^:=CommentString^.Data^;
       _flgWasEdited:=True;
      End
   Else
    If (CommentString^.Data^<>'') Then
      Begin
{       CommentsCollection^.Insert(NewStr(CommentString^.Data^));}
       PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments^.Insert(NewStr(CommentString^.Data^));
       _flgWasEdited:=True;
      End;
   End;
LastFocus:=Focused;
NewList(PBossRecord(BossRecArray^.At(FocusedBoss))^.PComments);
If LastFocus<List^.Count Then
   FocusItem(LastFocus)
Else
   FocusItem(List^.Count);
{SetRange(CommentsCollection^.Count);
Draw;}
{Validator^.Done;}
If CommentDialog<>Nil Then
   Dispose(CommentDialog,Done);
End;


Begin
Inherited HandleEvent(Event);
if Event.What and evMessage <> 0 then
  case Event.Command of
     cmDelete:DeleteComment;
     cmInsert:Begin
                DisableCommands(EditorCommands);
                DIsableCommands(HelpCommand);
                DIsableCommands(OtherCommands);
                InsertComment(False);
                EnableCommands(EditorCommands);
                EnableCommands(HelpCommand);
                EnableCommands(OtherCommands);
              End;
     cmEdit:Begin
                DisableCommands(EditorCommands);
                DIsableCommands(HelpCommand);
                DIsableCommands(OtherCommands);
                InsertComment(True);
                EnableCommands(EditorCommands);
                EnableCommands(HelpCommand);
                EnableCommands(OtherCommands);
            End;
     cmViewBosses:EndModal(cmCancel);
     cmHelp:Begin
             DisableCommands(EditorCommands);
             DisableCommands(HelpCommand);
             DisableCommands(OtherCommands);
             ShowHelpWindow;
             EnableCommands(EditorCommands);
             EnableCommands(HelpCommand);
             EnableCommands(OtherCommands);
            End;
     cmQuit:Begin
             EndModal(cmCancel);
             Event.What:=evCommand;
             Event.Command:=cmQuit;
             PutEvent(Event);
            End;
    end;
End;



constructor TPointCommentEditor.Init;
var
  R: TRect;
  Control : PView;
begin
R.Assign(0, 0, 80, 23);
inherited Init(R, PBossRecord(BossRecArray^.At(FocusedBoss))^.PBossString^);

R.Assign(79, 10, 80, 18);
Control := New(PScrollBar, Init(R));
Insert(Control);

R.Assign(2, 10, 78, 18);
Control := New(PPointList, Init(R, 1, PScrollbar(Control)));
Control^.Options := Control^.Options or ofValidate;
Control^.Options := Control^.Options or ofFramed;
Insert(Control);

R.Assign(33, 8, 42, 9);
Insert(New(PLabel, Init(R, 'Points', Control)));

R.Assign(79, 3, 80, 7);
Control := New(PScrollBar, Init(R));
Insert(Control);

R.Assign(2, 3, 78, 7);
Control := New(PCommentList, Init(R, 1, PScrollbar(Control)));
Control^.Options := Control^.Options or ofFramed;
Insert(Control);

R.Assign(32, 1, 41, 2);
Insert(New(PLabel, Init(R, 'Comments', Control)));


R.Assign(25, 19, 35, 22);
Control := New(PButton, Init(R, '~I~nsert', cmInsert, bfNormal));
Insert(Control);

R.Assign(35, 19, 45, 22);
Control := New(PButton, Init(R, '~D~elete', cmDelete, bfNormal));
Insert(Control);

R.Assign(45, 19, 55, 22);
Control := New(PButton, Init(R, '~E~dit', cmEdit, bfDefault));
Insert(Control);


R.Assign(55, 19, 65, 22);
Control := New(PButton, Init(R, '~S~earch', cmSearch, bfNormal));
Insert(Control);


R.Assign(4, 19, 22, 22);
Control := New(PButton, Init(R, ' ~V~iew Bosses', cmViewBosses, bfNormal));
Insert(Control);


SelectNext(False);
end;

constructor TPointCommentEditor.Load(var S: TStream);
begin
inherited Load(S);
end;

procedure TPointCommentEditor.HandleEvent(var Event: TEvent);
begin
(*---
if Event.What and evMessage <> 0 then
  case Event.Command of
    end;    --*)

Inherited HandleEvent(Event);
if Event.What and evMessage <> 0 then
  case Event.Command of
     cmClose:EndModal(cmCancel);
     cmInsert:;
    end;
(*---
if Event.What and evMessage <> 0 then
  case Event.Command of
    end;    --*)

end;

procedure TPointCommentEditor.Store(var S: TStream);
begin
inherited Store(S);
end;

function TPointCommentEditor.Valid(Command : word): boolean;
var
  Result : boolean;
begin
Result := inherited Valid(Command);
Valid := Result;
end;

destructor TPointCommentEditor.Done;
begin
inherited Done;
end;

end.
