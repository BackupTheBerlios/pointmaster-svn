UNIT Parser;

INTERFACE

Uses
{$IFDEF VIRTUALPASCAL}
Use32,
SysUtils,
{$ENDIF}
Objects,StrUnit,Dos,Incl,MCommon,CRC_32,Dates;

Type
  PVarRecCollection=^TVarRecCollection;
  TVarRecCollection=Object(TCollection)
    Procedure Error(Code, Info: Integer); virtual;
End;

Type
  ForEachProcedure= Procedure (Point:Pointer);
  ForEachProcedureWithData= Procedure (Point,Data:Pointer);

Type
  PValueCollection=^TValueCollection;
  TValueCollection=Object(TStringCollection)
{$IFDEF VIRTUALPASCAL}
   Function Compare(Key1, Key2: Pointer): LongInt; virtual;
{$ELSE}
   Function Compare(Key1, Key2: Pointer): Integer; virtual;
{$ENDIF}
End;

Type
 TVarRec=Object(TObject)
    PName :PVarTagRec;
    PValue:PValueCollection;
{    PFlag :Word;}
  Constructor Init(Name:VarTagRec;Value:String);
  Destructor Done;Virtual;
  Constructor Load(Var S:TDosStream);
  Procedure Store(Var S:TDosStream);Virtual;
End;
 PVarRec=^TVarRec;
Const
(* NotAllowChars:Set of Char=['[',']','{','}','.',',','~','!','@','#','$','%','^','*','(',')','-',
                             '+','\','=','|','/','<','>',' ',#9,#00..#31,#176..#223,#242..#255];*)
 RPVarRec:TStreamRec=(
   ObjType:200;
   VMTLink:Ofs(TypeOf(TVarRec)^);
   Load:@TVarRec.Load;
   Store:@TVarRec.Store);

Var
VarRecArray:PVarRecCollection;
NotAllowChars:Set Of Char;
{VarRec:PVarRec;}


Function  CreateVarArray:Boolean;
Function  SetVar(Name:VarTagRec;Value:String):Integer;
Function  SetVarFromString(Name:String;Value:String):Integer;
Function  GetVar(Name:String;Var Flag:Word):String;
{$IFDEF VIRTUALPASCAL}
Function  GetVarByIndex(Name:String;Index:LongInt;Var Flag:Word):String;
{$ELSE}
Function  GetVarByIndex(Name:String;Index:Integer;Var Flag:Word):String;
{$ENDIF}
{Function  MakeString(Var StrToMake:String):Integer;}
Function  ExpandString(Var StrToMake:String):Integer;
Function  GetExpandedString(S:String):String;
Function  GetOperationString(S:String):String;
Procedure ExpandCtlString(Var StrToMake:String);
Procedure WriteAllDataToDisk(S:String);
Procedure ForEachVar(Name:String;ProcPtr:ForEachProcedure);
Procedure ForEachVarWithData(Name:String;Data:Pointer;ProcPtr:ForEachProcedureWithData);
Function  GetValueCount(Name:VarTagRec):Word;
Function  GetValueCollectionPointer(Name:VarTagRec):Pointer;
Procedure DisposeAllVarRecCollection;
Procedure RestoreAllDataFromDisk(S:String);

IMPLEMENTATION
Uses Logger,Os_Type,Face,PointLst;

Procedure TVarRecCollection.Error(Code, Info: Integer);
Begin
 Case Code Of
    -1:LogWriteLn('!Variables index out of range. Requested index: '+IntToStr(Info));
    -2:LogWriteLn('!Variables collection overflow. Requested index: '+IntToStr(Info));
   Else
      LogWriteLn('!Unknown variables collection error.Code: '+IntToStr(Code)+' Info: '+IntToStr(Info));
  End;
End;

{$IFDEF VIRTUALPASCAL}
Function TValueCollection.Compare(Key1, Key2: Pointer): LongInt;
{$ELSE}
Function TValueCollection.Compare(Key1, Key2: Pointer): Integer;
{$ENDIF}
Begin
Compare:=-1;
End;



Constructor TVarRec.Init(Name:VarTagRec;Value:String);
Begin
 Inherited Init;
 PName :=New(PVarTagRec);
 PName^.Tag:=Name.Tag;
 PName^.Flag:=Name.Flag;
 PValue:=New(PValueCollection,Init(1,1));
 If Value='' Then Value:=' ';
 PValue^.Insert(MCommon.NewStr(Value));
 {PFlag :=Flag;}
End;


Destructor TVarRec.Done;
Begin
 Dispose(PName);
 Dispose(PValue,Done);
 Inherited Done;
End;

Procedure  TVarRec.Store(Var S:TDosStream);
Begin
 S.Write(PName^,SizeOf(PName^));
 PValue^.Store(S);
End;

Constructor TVarRec.Load(Var S:TDosStream);
Begin
 New(PName);
 PValue:=New(PValueCollection,Init(1,1));
 S.Read(PName^,SizeOf(PName^));
 PValue^.Load(S);
End;

Function CreateVarArray:Boolean;
Begin
     VarRecArray:=New(PVarRecCollection,Init(50,10));
     { RegisterType(RStringCollection);
      RegisterType(RPVarRec);}
End;

Function SetVar(Name:VarTagRec;Value:String):Integer;
Var
{$IFDEF VIRTUALPASCAL}
        Counter:      LongInt;
{$ELSE}
        Counter:      Integer;
{$ENDIF}
        PPVarRec:     PVarRec;
Begin
{TimeSlice;}
{WritePerCent;}
{ScreenHandler;}
RefreshScreen;
If VarRecArray=Nil Then
 CreateVarArray;
Name.Tag:=StrUp(Name.Tag);
If Value='' Then
   Value:=' ';
If MODE_DEBUG Then
   _logDebugString:='#SetVar[Int].';
If (VarRecArray<>Nil) Then
 Begin
 For Counter:=0 To Pred(VarRecArray^.Count) Do
    Begin
    PPVarRec:=VarRecArray^.At(Counter);
    If PPVarRec^.PName^.Tag=Name.Tag Then
       Begin
         If MODE_DEBUG Then
            _logDebugString:=_logDebugString+'Exist.';
         Case Name.Flag Of
             _flgSingle: Begin
 {                         PVarRec(VarRecArray^.At(Counter))^.PValue^.Done;}
                          PPVarRec^.PValue^.FreeAll;
                          PPVarRec^.PValue^.Insert(MCommon.NewStr(Value));
                          If MODE_DEBUG Then
                             _logDebugString:=_logDebugString+'Replace.';
                         End;
             _flgCollection:
                         Begin
                          PPVarRec^.PValue^.Insert(MCommon.NewStr(Value));
                          If MODE_DEBUG Then
                             _logDebugString:=_logDebugString+'Add['+
                              IntToStr(
                                PPVarRec^.PValue^.Count+1)+
                                      '].';
                         End;
         End;
         If MODE_DEBUG Then
           Begin
            _logDebugString:=_logDebugString+'Name:"'+Name.Tag+'".Value:"'+Value+'"';
            DebugLogWriteLn(_logDebugString);
           End;
         Exit;
       End;
    End;

  If MODE_DEBUG Then
    Begin
     _logDebugString:=_logDebugString+'Not-Exist.New.Name:"'+Name.Tag+'".Value:"'+Value+'"';
     DebugLogWriteLn(_logDebugString);
    End;
  End;
  With VarRecArray^ Do
   Begin
    Insert(New(PVarRec,Init(
      Name,Value)));
   End;

End;

Function SetVarFromString(Name:String;Value:String):Integer;
Var
{$IFDEF VIRTUALPASCAL}
Counter:LongInt;
{$ELSE}
Counter:Integer;
{$ENDIF}
TmpVarTagRec:VarTagRec;
PPVarRec:PVarRec;
Begin
{TimeSlice;}
{WritePerCent;}
{ScreenHandler;}
RefreshScreen;
If VarRecArray=Nil Then
 CreateVarArray;
Name:=StrUp(Name);
If Value='' Then
   Value:=' ';
If MODE_DEBUG Then
   _logDebugString:='#SetVar[Ext].';
If (VarRecArray<>Nil) Then
 Begin
 For Counter:=0 To Pred(VarRecArray^.Count) Do
    Begin
     PPVarRec:=VarRecArray^.At(Counter);
     If PPVarRec^.PName^.Tag=Name Then
        Begin
        If MODE_DEBUG Then
           _logDebugString:=_logDebugString+'Exist.';
         If PPVarRec^.PName^.Flag=_flgSingle Then
           Begin
            PPVarRec^.PValue^.FreeAll;
            If MODE_DEBUG Then
               _logDebugString:=_logDebugString+'Replace.';
           End
          Else
           Begin
            If MODE_DEBUG Then
              _logDebugString:=_logDebugString+'Add['+
                  IntToStr(PPVarRec^.PValue^.Count+1)+'].';
           End;
         PPVarRec^.PValue^.Insert(MCommon.NewStr(Value));
         If MODE_DEBUG Then
          Begin
           _logDebugString:=_logDebugString+'Name:"'+Name+'".Value:"'+Value+'"';
           DebugLogWriteLn(_logDebugString);
          End;
         Exit;
        End;
    End;
 End;
 If MODE_DEBUG Then
  Begin
   _logDebugString:=_logDebugString+'Not-Exist.New.Name:"'+Name+'".Value:"'+Value+'"';
   DebugLogWriteLn(_logDebugString);
  End;
  With VarRecArray^ Do
   Begin
    TmpVarTagRec.Tag:=Name;
    TmpVarTagRec.Flag:=_flgSingle;
    Insert(New(PVarRec,Init(
      TmpVarTagRec,Value)));
   End;

End;



Function GetVar(Name:String;Var Flag:Word):String;
Var
{$IFDEF VIRTUALPASCAL}
Count:LongInt;
{$ELSE}
Count:Integer;
{$ENDIF}
IsVarFound:Boolean;
Result_:String;
PPVarRec:PVarRec;
Begin
{TimeSlice;}
{WritePerCent;}
{ScreenHandler;}
REfreshScreen;
GetVar:=Name;
Result_:=Name;
Name:=StrUp(Name);
Name:=StrTrim(Name);
IsVarFound:=False;
If MODE_DEBUG Then
  _logDebugString:='#GetVar.';
If (VarRecArray<>Nil) and (Name<>'') Then
 Begin
 For Count:=0 To Pred(VarRecArray^.Count) Do
  Begin
  PPVarRec:=VarRecArray^.At(Count);
  If {PVarRec(VarRecArray^.At(Count))}PPVarRec^.PName^.Tag=Name Then
     Begin
      Result_:=PString({PVarRec(VarRecArray^.At(Count))}PPVarRec^.PValue^.At(0))^;
      If MODE_DEBUG Then
        _logDebugString:=_logDebugString+'Found.';
      IsVarFound:=True;
      If Name=CurDateStrTag.Tag Then
         Begin
          Result_:=GetDateString;
         End
     Else
      If Name=CurTimeStrTag.Tag Then
         Begin
          Result_:=GetTimeString;
         End
     Else
      If Name=DayOfYearTag.Tag Then
         Begin
          Result_:=GetDoYString;
         End
     Else
      If Name=DayOfWeekTag.Tag Then
         Begin
          Result_:=GetDoWString;
         End
     Else
      If Name=YearTag.Tag Then
         Begin
          Result_:=GetYearString;
         End
     Else
      If Name=MonthTag.Tag Then
         Begin
          Result_:=GetMonthString;
         End
     Else
      If Name=MonthNameTag.Tag Then
         Begin
          Result_:=GetMonthNameString;
         End
     Else
      If Name=DayTag.Tag Then
         Begin
          Result_:=GetDayString;
         End;
      GetVar:=Result_;
      If MODE_DEBUG Then
       Begin
        _logDebugString:=_logDebugString+'Name:"'+Name+'".Value:"'+Result_+'"';
        DebugLogWriteLn(_logDebugString);
       End;
      Break;
     End;
 End;
 End;
If (Not IsVarFound) Then
  Begin
   Result_:=GetEnv(Name);
   If Result_='' Then
      Begin
       Result_:=Name;
       If MODE_DEBUG Then
        Begin
        _logDebugString:=_logDebugString+'Not-found.';
        _logDebugString:=_logDebugString+'Name:"'+Name+'".Value:"'+Name+'"';
         DebugLogWriteLn(_logDebugString);
        End;
      End
   Else
      Begin
       If MODE_DEBUG Then
        Begin
        _logDebugString:=_logDebugString+'Found-DOS.';
        _logDebugString:=_logDebugString+'Name:"'+Name+'".Value:"'+Result_+'"';
         DebugLogWriteLn(_logDebugString);
        End;
      End;
  GetVar:=Result_;
  End;
End;

{$IFDEF VIRTUALPASCAL}
Function  GetVarByIndex(Name:String;Index:LongInt;Var Flag:Word):String;
{$ELSE}
Function  GetVarByIndex(Name:String;Index:Integer;Var Flag:Word):String;
{$ENDIF}
Var
{$IFDEF VIRTUALPASCAL}
Count:LongInt;
{$ELSE}
Count:Integer;
{$ENDIF}
IsVarFound:Boolean;
Result_:String;
PPVarRec:PVarRec;
Begin
{TimeSlice;}
{WritePerCent;}
{ScreenHandler;}
RefreshScreen;
GetVarByIndex:=Name;
Result_:=Name;
Name:=StrUp(Name);
Name:=StrTrim(Name);
IsVarFound:=False;
If MODE_DEBUG Then
  _logDebugString:='#GetVar['+IntToStr(Index)+'].';
If (VarRecArray<>Nil) and (Name<>'') Then
 Begin
 For Count:=0 To Pred(VarRecArray^.Count) Do
  Begin
  PPVarRec:=VarRecArray^.At(Count);
  If {PVarRec(VarRecArray^.At(Count))}PPVarRec^.PName^.Tag=Name Then
     Begin
      If Index>PPVarRec^.PValue^.COunt Then
          Result_:=PString(PPVarRec^.PValue^.At(0))^
      Else
          Result_:=PString(PPVarRec^.PValue^.At(Index))^;
      If MODE_DEBUG Then
        _logDebugString:=_logDebugString+'Found.';
      IsVarFound:=True;
      If Name=CurDateStrTag.Tag Then
         Begin
          Result_:=GetDateString;
         End
     Else
      If Name=CurTimeStrTag.Tag Then
         Begin
          Result_:=GetTimeString;
         End
     Else
      If Name=DayOfYearTag.Tag Then
         Begin
          Result_:=GetDoYString;
         End
     Else
      If Name=DayOfWeekTag.Tag Then
         Begin
          Result_:=GetDoWString;
         End
     Else
      If Name=YearTag.Tag Then
         Begin
          Result_:=GetYearString;
         End
     Else
      If Name=MonthTag.Tag Then
         Begin
          Result_:=GetMonthString;
         End
     Else
      If Name=MonthNameTag.Tag Then
         Begin
          Result_:=GetMonthNameString;
         End
     Else
      If Name=DayTag.Tag Then
         Begin
          Result_:=GetDayString;
         End;
      GetVarByIndex:=Result_;
      If MODE_DEBUG Then
       Begin
        _logDebugString:=_logDebugString+'Name:"'+Name+'".Value:"'+Result_+'"';
        DebugLogWriteLn(_logDebugString);
       End;
      Break;
     End;
 End;
 End;
If (Not IsVarFound) Then
  Begin
   Result_:=GetEnv(Name);
   If Result_='' Then
      Begin
       Result_:=Name;
       If MODE_DEBUG Then
        Begin
        _logDebugString:=_logDebugString+'Not-found.';
        _logDebugString:=_logDebugString+'Name:"'+Name+'".Value:"'+Name+'"';
         DebugLogWriteLn(_logDebugString);
        End;
      End
   Else
      Begin
       If MODE_DEBUG Then
        Begin
        _logDebugString:=_logDebugString+'Found-DOS.';
        _logDebugString:=_logDebugString+'Name:"'+Name+'".Value:"'+Result_+'"';
         DebugLogWriteLn(_logDebugString);
        End;
      End;
  GetVarByIndex:=Result_;
  End;
End;


Procedure ForEachVar(Name:String;ProcPtr:ForEachProcedure);
Var
{$IFDEF VIRTUALPASCAL}
Count,Count1:LongInt;
{$ELSE}
Count,Count1:Integer;
{$ENDIF}
Pnt:Pointer;
VarRec:PVarRec;
{PStr:PString Absolute Pnt;}
Begin
{WritePerCent;}
{ScreenHandler;}
RefreshScreen;
For Count:=0 To Pred(VarRecArray^.Count) Do
   Begin
    VarRec:=VarRecArray^.At(Count);
    If VarRec^.PName^.Tag=Name Then
       Begin
        If MODE_DEBUG Then
           _logDebugString:='#ForEach.';
        For Count1:=0 To Pred(VarRec^.PValue^.Count) Do
            Begin
             Pnt:=VarRec^.PValue^.At(Count1);
             If MODE_DEBUG Then
                Begin
                 _logDebugString:=_logDebugString+'Name:"'+Name+'".Value:"'+PString(Pnt)^+'"';
                 DebugLogWriteLn(_logDebugString);
                End;
             ProcPtr(Pnt);
            End;
        Break;
       End;
   End;
End;

Procedure ForEachVarWithData(Name:String;Data:Pointer;ProcPtr:ForEachProcedureWithData);
Var
{$IFDEF VIRTUALPASCAL}
Count,Count1:LongInt;
{$ELSE}
Count,Count1:Integer;
{$ENDIF}
Pnt:Pointer;
VarRec:PVarRec;
{PStr:PString Absolute Pnt;}
Begin
{WritePerCent;}
{ScreenHandler;}
RefreshScreen;
For Count:=0 To Pred(VarRecArray^.Count) Do
   Begin
    VarRec:=VarRecArray^.At(Count);
    If VarRec^.PName^.Tag=Name Then
       Begin
        If MODE_DEBUG Then
           _logDebugString:='#ForEach.';
        For Count1:=0 To Pred(VarRec^.PValue^.Count) Do
            Begin
             Pnt:=VarRec^.PValue^.At(Count1);
             If MODE_DEBUG Then
                Begin
                 _logDebugString:=_logDebugString+'Name:"'+Name+'".Value:"'+PString(Pnt)^+'"';
                 DebugLogWriteLn(_logDebugString);
                End;
             ProcPtr(Pnt,Data);
            End;
        Break;
       End;
   End;
End;

Function  GetValueCount(Name:VarTagRec):Word;
Var
{$IFDEF VIRTUALPASCAL}
Count:LongInt;
{$ELSE}
Count:Integer;
{$ENDIF}
VarRec:PVarRec;
Begin
GetValueCount:=0;
For Count:=0 To Pred(VarRecArray^.Count) Do
   Begin
    VarRec:=VarRecArray^.At(Count);
    If VarRec^.PName^.Tag=Name.Tag Then
       Begin
        GetValueCount:=VarRec^.PValue^.Count;
        Break;
       End;
   End;
End;

Function  GetValueCollectionPointer(Name:VarTagRec):Pointer;
Var
{$IFDEF VIRTUALPASCAL}
Count:LongInt;
{$ELSE}
Count:Integer;
{$ENDIF}
VarRec:PVarRec;
Begin
GetValueCollectionPointer:=Nil;
For Count:=0 To Pred(VarRecArray^.Count) Do
   Begin
    VarRec:=VarRecArray^.At(Count);
    If VarRec^.PName^.Tag=Name.Tag Then
       Begin
        GetValueCollectionPointer:=VarRec^.PValue;
        Break;
       End;
   End;
End;

Function ExpandString(Var StrToMake:String):Integer;
Var
 BeginPos,EndPos:Word;
 PerCentPos:Word;
 VarResult:String;
 Count:Integer;
 Result_:Word;
 EndOfString:Word;
 NeedToReMake:Boolean;
Begin
 {WritePerCent;}
{ ScreenHandler;}
RefreshScreen;
 BeginPos:=0;
 EndPos:=0;
 PerCentPos:=0;
 Count:=0;
 Result_:=NULL;
 EndOfString:=0;
 NeedToReMake:=False;
{********************** Обpаботка макpосов **********************************}
 ReplaceTabsWithSpaces(StrToMake);
 PerCentPos:=Pos('%',StrToMake);
If (PerCentPos>0) Then
Begin
  EndOfString:=Length(StrToMake);
  Count:=PerCentPos;
   While (True) Do
   Begin
    If Count>=EndOfString Then
      Break;
    If (StrToMake[Count]='%') and (Count<=EndOfString) and (StrToMake[Count+1]<>'%')  Then
     Begin
       BeginPos:=Count;
       Inc(Count);
        While ((Count <=EndOfString) And (Not (StrToMake[Count] In NotAllowChars))) Do
         Begin
          Inc(Count);
         End;
       If StrToMake[Count]='%' Then
         Begin
          Delete(StrToMake,Count,1);
          Dec(Count);
          EndOfString:=Length(StrToMake);
         End
       Else
         Dec(Count);
       If (Count+1<=EndOfString) And (StrToMake[Count+1]='@') Then
         Begin
          If (Count+1=EndOfString) Then
            Begin
             Delete(StrToMake,Count+1,1);
             EndOfString:=Length(StrToMake);
             NeedToReMake:=True;
            End
         Else
          If (StrToMake[Count+2]<>'@') Then
            Begin
             Delete(StrToMake,Count+1,1);
             EndOfString:=Length(StrToMake);
             NeedToReMake:=True;
            End
         Else
          If (StrToMake[Count+2]='@') Then
            Begin
             Delete(StrToMake,Count+1,1);
             EndOfString:=Length(StrToMake);
            End;
         End
       Else
            Begin
            End;
       EndPos:=Count;
       If EndPos=BeginPos Then
          EndPos:=EndPos+1;
       If (BeginPos=EndOfString) Then
          VarResult:=''
       Else
         Begin
           VarResult:=GetVar(Copy(StrToMake,BeginPos+1,EndPos-BeginPos),_varNONE);
         End;
       Delete(StrToMake,BeginPos,EndPos-BeginPos+1);
       Insert(VarResult,StrToMake,BeginPos);
       EndOfString:=Length(StrToMake);
       If NeedToReMake Then
          Begin
            NeedToReMake:=False;
            Count:=PerCentPos-1;
          End
         Else
          If Pos('%',Copy(StrToMake,(BeginPos+Length(VarResult){-1}),(Length(StrToMake))))>0 Then
             Begin
              PerCentPos:=Pos('%',Copy(StrToMake,(BeginPos+Length(VarResult)-1),(Length(StrToMake))))+
              BeginPos+Length(VarResult)-2;
              Count:=PerCentPos-1;
              EndOfString:=Length(StrToMake);
             End
            Else
              Break;
     End
    Else
     If (Count<EndOfString) And (StrToMake[Count]='%') and (StrToMake[Count+1]='%') Then
        Begin
         Delete(StrToMake,Count,1);
         EndOfString:=Length(StrToMake);
{         Inc(Count);}
        End;
     Inc(Count);
   End;
End;
{*********************** Обpаботка макpосов *********************************}
If (Pos('#',StrToMake)>0) Then
 Begin
  BeginPos:=Pos('#',StrToMake);
  EndPos:=Pos(' ',Copy(StrToMake,BeginPos,Length(StrToMake)-BeginPos));
  If EndPos>0 Then
    Begin
     If StrUp(Copy(StrToMake,BeginPos,EndPos-BeginPos))=DefineTag Then
       Begin
          Delete(StrToMake,BeginPos,EndPos-BeginPos);
          StrToMake:=StrTrim(StrToMake);
          BeginPos:=1;
          EndPos:=Pos(' ',StrToMake);
          If EndPos>0 Then
            Begin
             SetVarFromString(
               StrUp(
                Copy(StrToMake,BeginPos,EndPos-BeginPos)),PadLeft(Copy(StrToMake,EndPos,Length(StrToMake))));
                StrToMake:='';
                Result_:=NOT_PROCESS_STRING;
            End;
       End
    Else
     If StrUp(Copy(StrToMake,BeginPos,EndPos-BeginPos))=IncludeTag Then
       Begin
         Delete(StrToMake,BeginPos,EndPos-BeginPos);
         StrToMake:=StrTrim(StrToMake);
         Result_:=INCLUDE_FILE;
       End
    Else
     If StrUp(Copy(StrToMake,BeginPos,EndPos-BeginPos))=ScriptTag Then
       Begin
         Delete(StrToMake,BeginPos,EndPos-BeginPos);
         StrToMake:=StrTrim(StrToMake);
         Result_:=EXECUTE_SCRIPT;
       End
    Else
     If StrUp(Copy(StrToMake,BeginPos,EndPos-BeginPos))=CRC32Tag Then
       Begin
         Delete(StrToMake,BeginPos,EndPos-BeginPos);
         StrToMake:=StrTrim(StrToMake);
         Result_:=NOT_PROCESS_STRING;
         SetVar(CrcTag,StrUp(GetCRC32String(StrToMake)));
       End
    Else
     If StrUp(Copy(StrToMake,BeginPos,EndPos-BeginPos))=LoadListSegmentTag Then
       Begin
         Delete(StrToMake,BeginPos,EndPos-BeginPos);
         StrToMake:=StrTrim(StrToMake);
         Result_:=NOT_PROCESS_STRING;
         InitPointList(StrToMake);
       End
    End
   Else
    Begin
    If StrUp(StrTrim(Copy(StrToMake,BeginPos,Length(StrToMake))))=SegmentBodyTag Then
       Begin
         Delete(StrToMake,BeginPos,Length(StrToMake));
         Result_:=INCLUDE_SEGMENT;
       End
   Else
    If StrUp(StrTrim(Copy(StrToMake,BeginPos,Length(StrToMake))))=ListErrorsTag Then
       Begin
         Delete(StrToMake,BeginPos,Length(StrToMake));
         Result_:=INCLUDE_LISTERRORS;
       End
   Else
    If StrUp(StrTrim(Copy(StrToMake,BeginPos,Length(StrToMake))))=SegmentErrorsTag Then
       Begin
         Delete(StrToMake,BeginPos,Length(StrToMake));
         Result_:=INCLUDE_PERSONALLISTERRORS;
       End
   Else
    If StrUp(StrTrim(Copy(StrToMake,BeginPos,Length(StrToMake))))=StatisticTag Then
       Begin
         Delete(StrToMake,BeginPos,Length(StrToMake));
         Result_:=INCLUDE_STATISTIC;
       End
   Else
    If StrUp(StrTrim(Copy(StrToMake,BeginPos,Length(StrToMake))))=OriginalMessageBodyTag Then
       Begin
         Delete(StrToMake,BeginPos,Length(StrToMake));
         Result_:=INCLUDE_MESSAGEBODY;
       End
   Else
    If StrUp(StrTrim(Copy(StrToMake,BeginPos,Length(StrToMake))))=MessageErrorsTag Then
       Begin
         Delete(StrToMake,BeginPos,Length(StrToMake));
         Result_:=INCLUDE_MESSAGEERRORS;
       End;
    End;
 End;
ExpandString:=Result_;
End;

Procedure ExpandCtlString(Var StrToMake:String);
Var
Position:Word;
Begin
StrToMake:=StrTrim(StrToMake);
If ((Pos(';',StrToMake)>1) or (Pos(';',StrToMake)=0)) and (Pos(' ',StrToMake)<>0) Then
 Begin
  Position:=Pos(' ',StrToMake);
  SetVarFromString(StrUp(Copy(StrToMake,1,Position-1)),PadLeft(Copy(StrToMake,Position,Length(StrToMake))));
 End;
End;

Function GetExpandedString(S:String):String;
Var
SubStr:String;
Begin
 SubStr:=Copy(S,2,Length(S));
 ExpandString(SubStr);
 GetExpandedString:=Copy(S,1,1)+SubStr;
End;

Function  GetOperationString(S:String):String;
Var
SubStr:String;
Begin
 SubStr:=Copy(S,2,Length(S));
 ExpandString(SubStr);
 GetOperationString:=SubStr;
End;

Procedure WriteAllDataToDisk(S:String);
Var
F:TDosStream;
{$IFDEF VIRTUALPASCAL}
Count:LongInt;
{$ELSE}
Count:Integer;
{$ENDIF}
VR:PVarRec;
Begin
F.Init(FExpand(S),stCreate);
For Count:=0 To Pred(VarRecArray^.Count) Do
 Begin
  VR:=VarRecArray^.At(Count);
  With VR^ Do
    Begin
     Store(F);
    End;
 End;
F.Done;
End;


Procedure DisposeAllVarRecCollection;
Begin
VarRecArray^.FreeAll;
End;

Procedure RestoreAllDataFromDisk(S:String);
Var
F:TDosStream;
{$IFDEF VIRTUALPASCAL}
Count:LongInt;
{$ELSE}
Count:Integer;
{$ENDIF}
VR:PVarRec;
Begin
F.Init(FExpand(S),stOpenRead);
F.Seek(0);
While ((F.Status=stOk) and (F.GetPos<=SizeOf(F)))  Do
 Begin
  VarRecArray^.Insert(New(PVarRec,Load(F)));
 End;
F.Done;
End;

Begin
{.$IFDEF VIRTUALPASCAL}
(* NotAllowChars:=['[',']','{','}','.',',','~','!','@','#','$','%','^','*','(',')','-','+','\','=','|','/','<','>',' ',
 #00..#31,#176..#223,#242..#255];*)

{.$ELSE}
 NotAllowChars:=['[',']','{','}','.',',','~','!','@','#','$','%','^','*','(',')','-','+','\','=','|','/','<','>',' ',
                 #9,#00..#31,#176..#223,#242..#255];
{.$ENDIF}
End.
