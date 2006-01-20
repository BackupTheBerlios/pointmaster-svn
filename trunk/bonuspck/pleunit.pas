unit PLEUnit;

interface

uses Drivers, Objects, Views, Dialogs,PointLst,Incl,Validate,MsgBoxA,App,PLEUnit2,Parser,StrUnit,
     MCommon,Ple_Incl,TVCC,PntL_Obj;

{Const
cmInsert=202;
cmDelete=203;
cmSearch=204;
cmViewPoints=205;
cmEdit=206;}

Type
  PDlgWindow=^TDlgWindow;
  TDlgWindow=Object(TTVCCDialog)
   Procedure HandleEvent(Var Event:TEvent);Virtual;
End;


Type
  PBossValidator=^TBossValidator;
  TBossValidator=Object(TPXPictureValidator)
   Procedure Error;Virtual;
End;



Type
 PBossCollection=^TBossCollection;
 TBossCollection=Object(TStringCollection)
   Function Compare(Key1,Key2:Pointer):Integer;Virtual;
End;



{type
  TListBoxRec = record    {<-- omit if TListBoxRec is defined elsewhere}
 {   List: PBossCollection;
    Selection: Word;
  end;

  BossList = record
    PBossRecord : TListBoxRec;
    end;
  PBossList = ^BossList;}
Type
  PBossList=^TBossList;
  TBossList=Object(TListBox)
  { BossCollection:PBossCollection;}
   {BossCollection:PBossRecSortedCollection;}
   Constructor Init(Var Bounds: TRect; ANumCols: Word; AScrollBar:
                   PScrollBar);
   Destructor Done;Virtual;
   Procedure HandleEvent(Var Event:TEvent);Virtual;
   Procedure NewList(AList: PCollection); virtual;

End;

  { TPointListEditor }

  PPointListEditor = ^TPointListEditor;
  TPointListEditor = object(TTVCCDialog)
    constructor Init;
    constructor Load(var S: TStream);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
    function Valid(Command : word): boolean; virtual;
    destructor Done; virtual;
    Procedure ShowCommentsAndPoints;
  end;


const
  RPointListEditor : TStreamRec = (
    ObjType: 12345;            {<--- Insert a unique number >= 100 here!!}
    VmtLink: Ofs(Typeof(TPointListEditor)^);
    Load : @TPointListEditor.Load;
    Store : @TPointListEditor.Store);

Function IsSaveChanges:Word;

implementation

Procedure TDlgWindow.HandleEvent(Var Event:TEvent);
Begin
 Inherited HandleEvent(Event);
 If Event.What=evCommand Then
    EndModal(Event.Command);
End;

Function IsSaveChanges:Word;
Var
R:TRect;
Dlg:PDlgWindow;
Begin
R.Assign(20,5,57,12);
Dlg:=New(PDlgWindow,Init(R,'Choose'));
With Dlg^ Do
  Begin
   R.Assign(7,1,33,3);
   Insert(New(PStaticText,Init(R,'     Save changes ?    ')));
   R.Assign(7,3,17,6);
   Insert(New(PTVCCButton,Init(R,'~Y~es',cmOk,bfDefault)));
   R.Assign(18,3,28,6);
   Insert(New(PTVCCButton,Init(R,'~N~o',cmCancel,bfNormal)));
   SelectNext(False);
  End;
IsSaveChanges:=DeskTop^.ExecView(Dlg);
If Dlg<>Nil Then
   Dispose(Dlg,Done);
End;



Function TBossCollection.Compare(Key1,Key2:Pointer):Integer;
Var
FStr: PString absolute Key1;
SStr: PString absolute Key2;
BeginPos,EndPos:Word;
FBoss,SBoss,Code:Word;
Begin
BeginPos:=Pos('/',FStr^);
Val(Copy(FStr^,BeginPos+1,Length(FStr^)),FBoss,Code);
BeginPos:=Pos('/',SStr^);
Val(Copy(SStr^,BeginPos+1,Length(SStr^)),SBoss,Code);
If FBoss<SBoss Then
   Compare:=-1
Else
If FBoss=SBoss Then
  Begin
   Compare:=0;
   DuplicateBosses:=DuplicateBosses+1;
  End
Else
If FBoss>SBoss Then
   Compare:=1;
End;

Procedure TBossValidator.Error;
Begin
 MessageBox('    Wrong input',Nil,mfError+mfOkButton);
End;

Constructor TBossList.Init(var Bounds: TRect; ANumCols: Word; AScrollBar:
                         PScrollBar);
Var
Count:Integer;
Begin
Inherited Init(Bounds,ANumCols,AScrollBar);
{If BossCollection=Nil Then
   BossCollection:=New(PBossCollection,Init(20,1));}
{If BossCollection=Nil Then
   BossCollection:=New(PBossRecSortedCollection,Init(20,1));}
{For Count:=0 To Pred(BossRecArray^.Count) Do
    BossCollection^.Insert(NewStr(PBossRecord(BossRecArray^.At(Count))^.PBossString^));}
{NewList(BossCollection);}
NewList(BossRecArray);
End;

Procedure TBossList.NewList(AList: PCollection);
Var
Counter:Integer;
Begin
{  if List <> nil then Dispose(List, Done);
  List := AList;
  if AList <> nil then SetRange(AList^.Count)
  else SetRange(0);
  if Range > 0 then FocusItem(0);
  DrawView;}

   If List<>Nil Then
      List^.DeleteAll
   Else
      List:=New(PCollection,Init(10,5));
   If AList<>Nil Then
    Begin
      For Counter:=0 To Pred(PBossRecSortedCollection(AList)^.Count) Do
         List^.Insert(PBossRecord(PBossRecSortedCollection(AList)^.At(Counter))^.PBossString);
      SetRange(PBossRecSortedCollection(AList)^.Count);
    End
  Else
    SetRange(0);
 If Range>0 Then
    FocusItem(0);
 DrawView;
End;

Destructor TBossList.Done;
Begin
{If BossCollection<>Nil Then
   BossCollection^.Done;
If BossRecArray<>Nil Then
   BossRecArray^.Done;}
If List<>Nil Then
  Begin
   List^.DeleteAll;
   Dispose(List,Done);
  End;
ListNameOverrided:=False;
Inherited Done;
End;

Procedure TBossList.HandleEvent(Var Event:TEvent);

Procedure DeleteBoss;
Var
LastFocus:Integer;
Begin
{ If Focused<BossCollection^.Count Then}
 If Focused<BossRecArray^.Count Then
  Begin
  _flgWasEdited:=True;
{  BossCollection^.AtFree(Focused);
  BossRecArray^.AtFree(Focused);}
  LastFocus:=Focused;
  BossRecArray^.AtFree(Focused);
{  SetRange(BossCollection^.Count);}
{  SetRange(BossRecArray^.Count);}
  NewList(BossRecArray);
  If LastFocus<List^.Count Then
     FocusItem(LastFocus)
  Else
     FocusItem(List^.Count);
{  DrawView;}
 End;
End;

Procedure InsertBoss(IsEdit:Boolean);
Var
BossDialog:PTVCCDialog;
R:TRect;
S:String;
BossString:PInputLine;
Control:Word;
Validator:PBossValidator;
BossTag:String;
LastFocus:Integer;
Begin
 If IsEdit Then
    S:='Edit'
Else
    S:='Insert';
R.Assign(25,4,49,13);
BossDialog:=New(PTVCCDialog,Init(R,S));
Validator:=New(PBossValidator,Init('Boss;,^[#][#][#][#]:^[#][#][#][#];/^[#][#][#][#]',True));
With BossDialog^ Do
 Begin
  R.Assign(2,3,22,4);
  BossString:=New(PInputLine,Init(R,22));
  BossString^.SetValidator(Validator);
  BossString^.Options:=BossString^.Options or ofFramed;
  Insert(BossString);
  R.Assign(2,1,22,2);
  Insert(New(PLabel,Init(R,'  Input address',BossString)));
  R.Assign(1,5,12,8);
  Insert(New(PTVCCButton,Init(R,' ~O~k',cmOk,bfDefault)));
  R.Assign(12,5,23,8);
  Insert(New(PTVCCButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
  SelectNext(False);
 End;
BossTag:='Boss,';
{If (IsEdit) and (BossCollection^.Count<>0) and (Focused<BossCollection^.Count) Then}
If (IsEdit) and (BossRecArray^.Count<>0) and (Focused<BossRecArray^.Count) Then
  Begin
   BossDialog^.SetData(
                      PBossRecord(BossRecArray^.At(Focused))^.PBossString^
                      );
  End
Else
  BossDialog^.SetData(BossTag);
Draw;
Control:=DeskTop^.ExecView(BossDialog);
Draw;
If Control=cmOk Then
   Begin
    If (IsEdit) and (BossString^.Data^<>'') Then
      Begin
       If Focused<BossRecArray^.Count Then
          PBossRecord(BossRecArray^.At(Focused))^.PBossString^:=BossString^.Data^;
       _flgWasEdited:=True;
      End
   Else
    If (BossString^.Data^<>'') Then
      Begin
       BossRecArray^.Insert(New(PBossRecord,Init(BossString^.Data^,Nil,Nil)));
       _flgWasEdited:=True;
      End;
   LastFocus:=Focused;
   NewList(BossRecArray);
    If LastFocus<List^.Count Then
       FocusItem(LastFocus)
    Else
       FocusItem(List^.Count);
   End;
{SetRange(BossCollection^.Count);}
{SetRange(BossRecArray^.Count);}
{Draw;}
If BossDialog<>Nil Then
   Dispose(BossDialog,Done);
{Validator^.Done;}
End;

Procedure SearchBoss;
Var
SearchDialog:PTVCCDialog;
R:TRect;
S:String;
SearchString:PInputLine;
Count:Integer;
BossPos:Integer;
Begin
If BossRecArray^.Count=0 Then
   Exit;
BossPos:=0;
R.Assign(25,4,50,13);
SearchDialog:=New(PTVCCDialog,Init(R,'Search for boss'));
With SearchDialog^ Do
  Begin
   R.Assign(2,3,23,4);
   SearchString:=New(PInputLine,Init(R,20));
   SearchString^.Options:=SearchString^.Options or ofFramed;
   Insert(SearchString);
   R.Assign(1,1,23,2);
   Insert(New(PLabel,Init(R,'Input part of address',SearchString)));
   R.Assign(1,5,12,8);
   Insert(New(PTVCCButton,Init(R,' ~O~k',cmOk,bfDefault)));
   R.Assign(12,5,23,8);
   Insert(New(PTVCCButton,Init(R,'~C~ancel',cmCancel,bfNormal)));
   SelectNext(False);
  End;
If DeskTop^.ExecView(SearchDialog)=cmCancel Then
 Begin
  If SearchDialog<>Nil Then
     Dispose(SearchDialog,Done);
  Exit;
 End;
S:=SearchString^.Data^;
Count:=Focused;
{While (Pos(StrUp(S),StrUp(PString(BossCollection^.At(Count))^))=0) And
      (Count<Pred(BossCollection^.Count)) Do}
{While{ (Pos(StrUp(S),StrUp(PString(BossREcArray^.At(Count))^))=0) And}
For Count:=Focused To Pred(BossRecArray^.Count)
     { (Count<Pred(BossRecArray^.Count))} Do
   Begin
    BossPos:=(Pos(StrUp(S),StrUp(PBossRecord(BossREcArray^.At(Count))^.PBossString^)));
    If BossPos>0 Then
       Break;
 {   Inc(Count);}
   End;
If (Count>Focused) And (BossPos>0) Then
  FocusItem(Count);
Draw;
If SearchDialog<>Nil Then
   Dispose(SearchDialog,Done);
End;


Begin
Inherited HandleEvent(Event);
FocusedBoss:=Focused;
Case Event.What Of
 evCommand:
  case Event.Command of
     cmDelete:Begin
               DisableCommands(EditorCommands);
                DIsableCommands(HelpCommand);
                DIsableCommands(OtherCommands);
               DeleteBoss;
               EnableCommands(EditorCommands);
                EnableCommands(HelpCommand);
                EnableCommands(OtherCommands);
              End;
     cmInsert:Begin
               DisableCommands(EditorCommands);
                DIsableCommands(HelpCommand);
                DIsableCommands(OtherCommands);
               InsertBoss(False);
               EnableCommands(EditorCommands);
                EnableCommands(HelpCommand);
                EnableCommands(OtherCommands);
              End;
     cmEdit:Begin
               DisableCommands(EditorCommands);
                DIsableCommands(HelpCommand);
                DIsableCommands(OtherCommands);
               InsertBoss(True);
               EnableCommands(EditorCommands);
                EnableCommands(HelpCommand);
                EnableCommands(OtherCommands);
              End;
     cmSearch:Begin
               DisableCommands(EditorCommands);
                DIsableCommands(HelpCommand);
                DIsableCommands(OtherCommands);
               SearchBoss;
               EnableCommands(EditorCommands);
                EnableCommands(HelpCommand);
                EnableCommands(OtherCommands);
              End;
     cmHelp:
            Begin
             DisableCommands(EditorCommands);
             DIsableCommands(HelpCommand);
             DIsableCommands(OtherCommands);
              ShowHelpWindow;
             EnableCommands(EditorCommands);
             EnableCommands(HelpCommand);
             EnableCommands(OtherCommands);
             End;
     cmQuit:
            Begin
             If _flgWasEdited Then
              Begin
               Case IsSaveChanges Of
                     cmOk:Begin
{                           If ParamCount=0 Then
                              SetVar(DestPointListNameTag,{CurrentPointListName}{'aa',_flgNone)
{                          Else
                           If GetVar(DestPointListNameTag.Tag,_flgNone) =Copy(
                                DestPointListNameTag.Tag,2,Length(DestPointListNameTag.Tag)) Then
                              SetVar(DestPointListNameTag,{CurrentPointListName}{'aa',_flgNone);}
                           WritePointListToDisk;
                          End;
                    cmCancel:;
                End;
                EndModal(cmCancel);
                Event.What:=evCommand;
                Event.Command:=cmQuit;
                PutEvent(Event);
              End;
            End;
     cmClose:
            Begin
             If _flgWasEdited Then
              Begin
               Case IsSaveChanges Of
                     cmOk:Begin
{                           If ParamCount=0 Then
                              SetVar(DestPointListNameTag,{CurrentPointListName}{'aa',_flgNone)
{                          Else
                           If GetVar(DestPointListNameTag.Tag,_flgNone) =Copy(
                                DestPointListNameTag.Tag,2,Length(DestPointListNameTag.Tag)) Then
                              SetVar(DestPointListNameTag,{CurrentPointListName}{'aa',_flgNone);}
                           WritePointListToDisk;
                          End;
                    cmCancel:;
                End;
                EndModal(cmCancel);
              End;
            End;

    end;
   evKeyDown:
            Case Event.KeyCode Of
               kbEsc:Begin
                   If _flgWasEdited Then
                    Begin
                      Case IsSaveChanges Of
                         cmOk:Begin
{                              If ParamCount=0 Then
                                 SetVar(DestPointListNameTag,{CurrentPointListName}{'aa',_flgNone)
{                             Else
                              If GetVar(DestPointListNameTag.Tag,_flgNone) =Copy(
                                   DestPointListNameTag.Tag,2,Length(DestPointListNameTag.Tag)) Then
                                 SetVar(DestPointListNameTag,{CurrentPointListName}{'aa',_flgNone);}
                                 WritePointListToDisk;
                              End;
                         cmCancel:;
                        End;

                    End;
                     EndModal(cmCancel);
                    End;
               kbF1:
                    Begin
                    DisableCommands(EditorCommands);
                    DisableCommands(HelpCommand);
                    DisableCommands(OtherCommands);

                     ShowHelpWindow;
                    EnableCommands(EditorCommands);
                    EnableCommands(HelpCommand);
                    EnableCommands(OtherCommands);
                    End;
              End;
  End;
End;

constructor TPointListEditor.Init;
Type
 Param=Record
  Number:LongInt;
End;
var
  R: TRect;
  Control : PView;
  Result,Result2,Template:String;
  Par:Param;
begin
R.Assign(0, 0, 80, 23);
inherited Init(R, 'Simple PointList Editor v.0.02');

R.Assign(24, 3, 25, 21);
Control := New(PScrollBar, Init(R));
Insert(Control);

R.Assign(2, 3, 23, 21);
Control := New(PBossList, Init(R, 1, PScrollbar(Control)));
Control^.Options := Control^.Options or ofValidate;
Control^.Options := Control^.Options or ofFramed;
Insert(Control);

  R.Assign(6, 1, 18, 2);
  Insert(New(PLabel, Init(R, 'Bosses List', Control)));

R.Assign(36, 5, 46, 8);
Control := New(PTVCCButton, Init(R, '~I~nsert', cmInsert, bfNormal));
Insert(Control);

R.Assign(48, 5, 58, 8);
Control := New(PTVCCButton, Init(R, '~D~elete', cmDelete, bfNormal));
Insert(Control);

R.Assign(36, 8, 46, 11);
Control := New(PTVCCButton, Init(R, '~S~earch', cmSearch, bfNormal));
Insert(Control);


R.Assign(48, 8, 58, 11);
Control := New(PTVCCButton, Init(R, '~E~dit', cmEdit, bfNormal));
Insert(Control);

R.Assign(38, 11, 56, 14);
Control := New(PTVCCButton, Init(R, ' ~V~iew Points', cmViewPoints, bfDefault));
Insert(Control);

R.Assign(32, 2, 63, 4);

Template:='Duplicate bosses found: %d '#13;
Par.Number:=DuplicateBosses;
FormatStr(Result,Template,Par);
Template:='Wrong point records found: %d ';
Par.Number:=ErrorPoints;
FormatStr(Result2,Template,Par);

Control := New(PStaticText, Init(R, Result+Result2));
Control^.Options := Control^.Options or ofFramed;
Insert(Control);

SelectNext(False);
end;

constructor TPointListEditor.Load(var S: TStream);
begin
inherited Load(S);
end;

Procedure TPointListEditor.ShowCommentsAndPoints;
Var
PointCommentWindow:PPointCommentEditor;
Begin
If BossRecArray^.Count=0 Then
   Exit;
PointCommentWindow:=New(PPointCommentEditor,Init);
DeskTop^.ExecView(PointCommentWindow);
Dispose(PointCommentWindow,Done);
End;


procedure TPointListEditor.HandleEvent(var Event: TEvent);

begin

Inherited HandleEvent(Event);
Case Event.What of
   evCommand:
            Case Event.Command Of
              cmQuit:
                 Begin
                   If _flgWasEdited Then
                    Begin
                      Case IsSaveChanges Of
                         cmOk:Begin
{                               If ParamCount=0 Then
                                  SetVar(DestPointListNameTag,{CurrentPointListName}{'aa',_flgNone)
{                              Else
                               If GetVar(DestPointListNameTag.Tag,_flgNone) =Copy(
                                   DestPointListNameTag.Tag,2,Length(DestPointListNameTag.Tag)) Then
                                   SetVar(DestPointListNameTag,{CurrentPointListName}{'aa',_flgNone);}
                                   WritePointListToDisk;
                              End;
                         cmCancel:;
                        End;

                    End;
                  EndModal(cmCancel);
                  Event.What:=evCommand;
                  Event.Command:=cmQuit;
                  PutEvent(Event);
                 End;
               cmClose:
                 Begin
                   If _flgWasEdited Then
                    Begin
                      Case IsSaveChanges Of
                         cmOk:Begin
(*                               If ParamCount=0 Then
                                  SetVar(DestPointListNameTag,{CurrentPointListName}'aa',_flgNone)
                              Else
                               If GetVar(DestPointListNameTag.Tag,_flgNone) =Copy(
                                   DestPointListNameTag.Tag,2,Length(DestPointListNameTag.Tag)) Then
                                   SetVar(DestPointListNameTag,{CurrentPointListName}'aa',_flgNone);*)
                                   WritePointListToDisk;
                              End;
                         cmCancel:;
                        End;

                    End;
                  EndModal(cmCancel);
                 End;
              cmViewPoints:ShowCommentsAndPoints;
        {     cmClose:Case IsSaveChanges Of
                      cmOk:;
                      cmCancel:;
                      End;}
              cmInsert:;
             End;
   evKeyDown:
            Case Event.KeyCode Of
              kbEsc:
                  Begin
                   If _flgWasEdited Then
                    Begin
                      Case IsSaveChanges Of
                         cmOk:Begin
(*                               If ParamCount=0 Then
                                  SetVar(DestPointListNameTag,{CurrentPointListName}'aa',_flgNone)
                              Else
                               If GetVar(DestPointListNameTag.Tag,_flgNone) =Copy(
                                   DestPointListNameTag.Tag,2,Length(DestPointListNameTag.Tag)) Then
                                   SetVar(DestPointListNameTag,{CurrentPointListName}'aa',_flgNone);*)
                                   WritePointListToDisk;
                              End;
                         cmCancel:;
                        End;

                    End;
                     EndModal(cmCancel);
                   End;
               kbF1:
                    Begin
                    DisableCommands(EditorCommands);
                    DisableCommands(HelpCommand);
                    DisableCommands(OtherCommands);

                     ShowHelpWindow;
                    EnableCommands(EditorCommands);
                    EnableCommands(HelpCommand);
                    EnableCommands(OtherCommands);
                    End;

              End;
         end;

{inherited HandleEvent(Event);}
(*---
if Event.What and evMessage <> 0 then
  case Event.Command of
    end;    --*)

end;

procedure TPointListEditor.Store(var S: TStream);
begin
inherited Store(S);
end;

function TPointListEditor.Valid(Command : word): boolean;
var
  Result : boolean;
begin
Result := inherited Valid(Command);
Valid := Result;
end;

destructor TPointListEditor.Done;
begin
DuplicateBosses:=0;
ErrorPoints:=0;
_flgWasEdited:=False;
DisableCommands(EditorCommands);
If BossRecArray<>Nil Then
  Begin
   Dispose(BossRecArray,Done);
   BossRecArray:=Nil;
  End;
  DisableCommands(HelpCommand);
inherited Done;
end;
Begin
BossRecArray:=Nil;
end.
