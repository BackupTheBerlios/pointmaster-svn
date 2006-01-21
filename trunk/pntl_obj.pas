Unit PntL_Obj;

INTERFACE

Uses
  Use32,
App,Objects,Views,Dialogs,Drivers,Menus,Memory,HistList,
     {** pm units **}
     Incl,MCommon,Address,StrUnit,Parser,Logger;

Type
    PTemplateBody=^TTemplateBody;
    TTemplateBody=Object(TStringCollection)
        Function Compare(Key1,Key2:Pointer):Integer;Virtual;
End;

Type
   PMessageBody=^TMessageBody;
   TMessageBody=Object(TStringCollection)
        Function Compare(Key1,Key2:Pointer):Integer;Virtual;
End;

Type
   PBossRecSortedCollection=^TBossRecSortedCollection;
   TBossRecSortedCollection=Object(TSortedCollection)
        Function Compare(Key1,Key2:Pointer):Integer;Virtual;
        Function KeyOf(Item:Pointer):Pointer;Virtual;
        Procedure Error(Code, Info: Integer);Virtual;
End;

Type
   PPointsCollection=^TPointsCollection;
   TPointsCollection=Object(TStringCollection)
       Function Compare(Key1,Key2:Pointer):Integer;Virtual;
       Procedure Error(Code, Info: Integer);Virtual;
End;
Type
   PCommentsCollection=^TCommentsCollection;
   TCommentsCollection=Object(TStringCollection)
       Function Compare(Key1,Key2:Pointer):Integer;Virtual;
       Procedure Error(Code, Info: Integer);Virtual;
End;

Type
  PBossRecord=^TBossRecord;
  TBossRecord=Object(TObject)
   PBossString:PString;
   PComments:PCommentsCollection;
   PPoints:PPointsCollection;
  Constructor Init(BossString:String;
                   CommentsCollection:PCommentsCollection;
                   PointsCollection:PPointsCollection);
  Destructor Done;Virtual;
End;

Type
  PBossWithSegmentErrors=^TBossWithSegmentErrors;
  TBossWithSegmentErrors=Object(TObject)
      TBossAddress:TAddress;
      PSegmentName:PString;
      PErrorsMap:PMessageBody;
      Constructor Init(ABossAddress:String;ASegmentName:String;AErrorsMap:PMessageBody);
      Destructor Done;Virtual;
End;

Type
 PBossWithSegmentErrorsArray=^TBossWithSegmentErrorsArray;
 TBossWithSegmentErrorsArray=Object(TSortedCollection)
     Procedure Insert(Item: Pointer); virtual;
     Function KeyOf(Item: Pointer): Pointer; virtual;
     Function Compare(Key1, Key2: Pointer): Integer; virtual;
End;

Var
    BossWithSegmentErrorsArray:PBossWithSegmentErrorsArray;
    DupeBossesStrings:PMessageBody;


IMPLEMENTATION

Function TBossWithSegmentErrorsArray.KeyOf(Item: Pointer): Pointer;
Begin
     KeyOf:=@PBossWithSegmentErrors(Item)^.TBossAddress;
End;

Function TBossWithSegmentErrorsArray.Compare(Key1, Key2: Pointer):Integer;
Var
   FBoss,SBoss: TAddress;
Begin
 FBoss:=TAddress(Key1^);
 SBoss:=TAddress(Key2^);
 If (FBoss.Zone=SBoss.Zone) And (FBoss.Net=SBoss.Net) And
      (FBoss.Node=SBoss.Node) And (FBoss.Point=SBoss.Point) Then
          Compare:=0
 Else
          Compare:=-1;
End;

Procedure  TBossWithSegmentErrorsArray.Insert(Item: Pointer);
Var
    Counter,I:          Integer;
    PBoss,PNewBoss:     PBossWithSegmentErrors;
Begin
  If Not Search(KeyOf(Item), I) {or Duplicates} then AtInsert(I, Item)
  Else
       Begin
           PBoss:=PBossWithSegmentErrors(At(I));
           PNewBoss:=PBossWithSegmentErrors(Item);
           PBoss^.PErrorsMap^.Insert(MCommon.NewStr(' '));
           For Counter:=0 To Pred(PNewBoss^.PErrorsMap^.Count) Do
                 Begin
                        PBoss^.PErrorsMap^.Insert(MCommon.NewStr(
                                                  PString(PNewBoss^.PErrorsMap^.At(Counter))^));
                 End;
           If PNewBoss<> Nil Then
              Dispose(PNewBoss,Done);
       End;
End;


Constructor TBossWithSegmentErrors.Init(ABossAddress:String;ASegmentName:String;AErrorsMap:PMessageBody);
Var
   Counter:     Integer;
Begin
 Inherited Init;
 SetAddressFromString(ABossAddress,TBossAddress);

 If StrTrim(ASegmentName)='' Then
    PSegmentName:=MCommon.NewStr(' ')
 Else
    PSegmentName:=MCommon.NewStr(ASegmentName);
 PErrorsMap:=New(PMessageBody,Init(5,5));

 If AErrorsMap<>Nil Then
    Begin
         For Counter:=0 To Pred(AErrorsMap^.Count) Do
             PErrorsMap^.Insert(MCOmmon.NewStr(PString(AErrorsMap^.At(Counter))^));
    End;
End;

Destructor TBossWithSegmentErrors.Done;
Begin
 If PErrorsMap<> Nil Then
    PErrorsMap^.Done;

 If PSegmentName<>Nil Then
    Begin
          DisposeStr(PSegmentName);
          PSegmentName:=Nil;
    End;

 Inherited Done;
End;

Function TTemplateBody.Compare(Key1,Key2:Pointer):Integer;
Begin
      Compare:=-1;
End;

Function TBossRecSortedCollection.KeyOf (Item:Pointer):Pointer;
Begin
      KeyOf:=@PBossRecord(Item)^.PBossString^;
End;

Function TBossRecSortedCollection.Compare(Key1,Key2:Pointer):Integer;
Var
   FStr,SStr:           PString;
   BeginPos,EndPos,
   FBoss,SBoss,Code:    Word;
Begin
     FStr:=PString(Key1);
     SStr:=PString(Key2);
     If (FStr=Nil) or (SStr=Nil) or (FStr^='') or (SStr^='') Then
         Begin
              Compare:=1;
              Exit;
         End;
     BeginPos:=Pos(',',FStr^);
     EndPos:=Pos(':',FStr^);
     Val(Copy(FStr^,BeginPos+1,EndPos-1-BeginPos),FBoss,Code);
     BeginPos:=Pos(',',SStr^);
     EndPos:=Pos(':',FStr^);
     Val(Copy(SStr^,BeginPos+1,EndPos-1-BeginPos),SBoss,Code);
     If FBoss<SBoss Then
        Begin
             Compare:=-1;
             Exit;
        End
     Else
         If FBoss=SBoss Then
            Begin
            End
     Else
         If FBoss>SBoss Then
            Begin
                 Compare:=1;
                 Exit;
            End;
    BeginPos:=Pos('/',FStr^);
    Val(Copy(FStr^,EndPos+1,BeginPos-EndPos-1),FBoss,Code);
    BeginPos:=Pos('/',SStr^);
    Val(Copy(SStr^,EndPos+1,BeginPos-EndPos-1),SBoss,Code);
    If FBoss<SBoss Then
       Begin
            Compare:=-1;
            Exit;
       End
    Else
        If FBoss=SBoss Then
           Begin
           End
    Else
        If FBoss>SBoss Then
           Begin
                Compare:=1;
                Exit;
           End;
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
                Inc(DuplicateBosses);
                If DupeBossesStrings=Nil Then
                   DupeBossesStrings:=New({PStringCollection}PMessageBody,Init(5,5));
                If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
                    DupeBossesStrings^.Insert(NewStr('File ('+GetFNameAndExt(PntListName)+').['+FStr^+']'))
                Else
                    DupeBossesStrings^.Insert(NewStr('Файл ('+GetFNameAndExt(PntListName)+').['+FStr^+']'));
           End
        Else
            If FBoss>SBoss Then
               Compare:=1;
End;

Procedure TBossRecSortedCollection.Error(Code,Info:Integer);
Begin
     If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
        Begin
             Case Code Of
                  -1:  LogWriteLn('!Bosses index out of range. Requested index: '+IntToStr(Info));
                  -2:  LogWriteLn('!Bosses collection overflow. Requested index: '+IntToStr(Info));
             End;
        End
     Else
         Begin
              Case Code Of
                   -1:  LogWriteLn('!Индекс боссов выходит за допyстимые пpеделы. Запpошенный индекс: '+IntToStr(Info));
                   -2:  LogWriteLn('!Пеpеполнение коллекции боссов. Зпpошенный индекс: '+IntToStr(Info));
              End;
         End;
End;

Function TPointsCollection.Compare(Key1,Key2:Pointer):Integer;
Var
FStr: PString {absolute Key1};
SStr: PString {absolute Key2};
BeginPos,EndPos:Word;
FPoint,SPoint,Code:Word;
Begin
FStr:=PString(Key1);
SStr:=PString(Key2);
If (FStr=Nil) or (SStr=Nil) or (FStr^='') or (SStr^='') Then
    Begin
     Compare:=1;
     Exit;
    End;
BeginPos:=Pos(',',FStr^);
EndPos:=Pos(',',Copy(FStr^,BeginPos+1,Length(FStr^)));
Val(Copy(FStr^,BeginPos+1,EndPos-1),FPoint,Code);
BeginPos:=Pos(',',SStr^);
EndPos:=Pos(',',Copy(SStr^,BeginPos+1,Length(SStr^)));
Val(Copy(SStr^,BeginPos+1,EndPos-1),SPoint,Code);
If FPoint<SPoint Then
   Compare:=-1
Else
If FPoint=Spoint Then
   Compare:=0
Else
If FPoint>SPoint Then
   Compare:=1;
End;

Procedure TPointsCollection.Error(Code,Info:Integer);
Begin
If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
Begin
Case Code Of
   -1:LogWriteLn('!Points index out of range. Requested index: '+IntToStr(Info));
   -2:LogWriteLn('!Points collection overflow. Requested index: '+IntToStr(Info));
 End;
End
Else
 Begin
 Case Code Of
    -1:LogWriteLn('!Индекс поинтов выходит за допyстимые пpеделы. Запpошенный индекс: '+IntToStr(Info));
    -2:LogWriteLn('!Пеpеполнение коллекции поинтов. Запpошенный индекс: '+IntToStr(Info));
  End;
 End;
End;

Function TCommentsCollection.Compare(Key1,Key2:Pointer):Integer;
Begin
 Compare:=-1;
End;

Procedure TCommentsCollection.Error(Code,Info:Integer);
Begin
If StrUp(GetVar(LanguageTag.Tag,_varNONE))=EnglishTag Then
Begin
Case Code Of
   -1:LogWriteLn('!Comments index out of range. Requested index: '+IntToStr(Info));
   -2:LogWriteLn('!Comments collection overflow. Requested index: '+IntToStr(Info));
 End;
End
Else
 Begin
 Case Code Of
    -1:LogWriteLn('!Индекс комментаpиев выходит за допyстимы пpеделы. Запpошенный индекс: '+IntToStr(Info));
    -2:LogWriteLn('!Пеpеполнение коллекции комментаpиев. Запpошенный индекс: '+IntToStr(Info));
  End;
 End;
End;

Function TMessageBody.Compare(Key1,Key2:Pointer):Integer;
Begin
 Compare:=-1;
End;

Constructor TBossRecord.Init(BossString:String;
                             CommentsCollection:PCommentsCollection;
                             PointsCollection:PPointsCollection);
Var
Counter:Integer;
Begin
Inherited Init;
BossString:=StrDown(BossString);
BossString[1]:=UpCase(BossString[1]);
PBossString:=MCommon.NewStr(BossString);
If CommentsCollection<>Nil Then
 Begin
   PComments:=New(PCommentsCollection,Init(CommentsCollection^.Count+1,1));
 If CommentsCollection^.Count<>0 Then
   Begin
   For Counter:=0 To Pred(CommentsCollection^.Count) Do
      Begin
       PComments^.Insert(MCommon.NewStr(PString(CommentsCollection^.At(Counter))^))
      End;
   End;
 End
Else
 Begin
  PComments:=New(PCommentsCollection,Init(1,1));
 End;
If PointsCollection<>Nil Then
  Begin
    PPoints:=New(PPointsCollection,Init(PointsCollection^.Count+1,1));
  If PointsCollection^.Count<>0 Then
    Begin
    For Counter:=0 To Pred(PointsCollection^.Count) Do
       Begin
       PString(PointsCollection^.At(Counter))^[1]:=UpCase(PString(PointsCollection^.At(Counter))^[1]);
       PString(PointsCollection^.At(Counter))^[2]:=DownCase(PString(PointsCollection^.At(Counter))^[2]);
       PString(PointsCollection^.At(Counter))^[3]:=DownCase(PString(PointsCollection^.At(Counter))^[3]);
       PString(PointsCollection^.At(Counter))^[4]:=DownCase(PString(PointsCollection^.At(Counter))^[4]);
       PString(PointsCollection^.At(Counter))^[5]:=DownCase(PString(PointsCollection^.At(Counter))^[5]);
       PPoints^.Insert(MCommon.NewStr(PString(PointsCollection^.At(Counter))^));
       End;
    End;
  End
 Else
  Begin
    PPoints:=New(PPointsCollection,Init(1,1));
  End;
End;

Destructor TBossRecord.Done;
Begin
 DisposeStr(PBossString);
 PBossString:=Nil;
 Dispose(PComments,Done);
 PComments:=Nil;
 Dispose(PPoints,Done);
 PPoints:=Nil;
 Inherited Done;
End;

Begin
End.
