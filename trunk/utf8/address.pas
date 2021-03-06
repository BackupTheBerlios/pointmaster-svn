UNIT Address;

INTERFACE
Uses
Use32,
StrUnit,Incl;

Procedure SetAddressFromString(S:String;Var Address:TAddress);
Procedure SetExcludeAddressFromString(S:String;Var Address:TExcludeAddress);
Procedure SetExcludeAddressFromAddress(Addr:TAddress;Var Address:TExcludeAddress);
Procedure SetStringFromAddress(Var S:String;Address:TAddress);
Procedure SetStringFromExcludeAddress(Var S:String;Address:TExcludeAddress);
Function  GetStringFromAddress(Address:TAddress):String;
Function  GetStringFromExcludeAddress(Address:TExcludeAddress):String;
Function  GetStringWithPointFromAddress(Address:TAddress):String;
Function  GetStringAddressFromString(S:String):String;
Function  IsAddressesEqual(Addr1,Addr2:TAddress):Boolean;
Function  DigitMaskMatch(Mask,Source:String):Boolean;
Function  CharsMaskMatch(Mask,Source:String):Boolean;
Function  IsAddressMatch(Mask:String;Addr:TAddress):Boolean;

IMPLEMENTATION
Uses MCommon;

Procedure SetAddressFromString(S:String;Var Address:TAddress);
Var
BeginPos,EndPos,
BeginPos1:Integer;
Code:Integer;
Begin
S:=StrTrim(S);
FillChar(Address,SizeOf(Address),#0);
BeginPos:=Pos(' ',S);
If BeginPos>0 Then
   Delete(S,BeginPos,Length(S));
BeginPos:=Pos(',',S);
If BeginPos>0 Then
   Delete(S,1,BeginPos);
BeginPos:=Pos(':',S);
If BeginPos<>0 Then
   Val(Copy(S,1,BeginPos-1),Address.Zone,Code);
EndPos:=Pos('/',S);
If (EndPos<>0) And (EndPos>BeginPos) Then
   Val(Copy(S,BeginPos+1,EndPos-BeginPos-1),Address.Net,Code);
BeginPos:=EndPos;
EndPos:=Pos('.',S);
BeginPos1:=Pos('@',S);
If EndPos>0 Then
 Begin
  Val(Copy(S,BeginPos+1,EndPos-BeginPos-1),Address.Node,Code);
  If (BeginPos1>0) Then
    Begin
     If (BeginPos1>EndPos) Then
        Val(Copy(S,EndPos+1,BeginPos1-1-EndPos),Address.Point,Code);
    End
  Else
     Val(Copy(S,EndPos+1,Length(S)),Address.Point,Code);
 End
Else
 Begin
  If (BeginPos1>0) And (BeginPos>0) Then
     Val(Copy(S,BeginPos+1,BeginPos1-1-BeginPos),Address.Node,Code)
  Else
    If (BeginPos>0) Then
     Val(Copy(S,BeginPos+1,Length(S)-BeginPos),Address.Node,Code);
  Address.Point:=0;
 End;
 If BeginPos1>0 Then
    Begin
     EndPos:=Pos(' ',Copy(S,BeginPos1,Length(S)));
     If EndPos>0 Then
        Address.Domain:=StrTrim(Copy(S,BeginPos1+1,EndPos-BeginPos1-1))
     Else
{        Address.Domain:='';}
        Address.Domain:=Copy(S,BeginPos1+1,Length(S));
    End
 Else
   Address.Domain:='';
End;

Procedure SetExcludeAddressFromString(S:String;Var Address:TExcludeAddress);
Var
TmpAddress:TAddress;
Begin
 SetAddressFromString(S,TmpAddress);
 Address.Zone:=TmpAddress.Zone;
 Address.Net:=TmpAddress.Net;
 Address.Node:=TmpAddress.Node;
 Address.Point:=TmpAddress.Point;
End;

Procedure SetExcludeAddressFromAddress(Addr:TAddress;Var Address:TExcludeAddress);
Begin
 Address.Zone:=Addr.Zone;
 Address.Net:=Addr.Net;
 Address.Node:=Addr.Node;
 Address.Point:=Addr.Point;
End;

Procedure SetStringFromAddress(Var S:String;Address:TAddress);
Begin
S:='';
S:=S+IntToStr(Address.Zone)+':'+IntToStr(Address.Net)+'/'+IntToStr(Address.Node);
End;

Procedure SetStringFromExcludeAddress(Var S:String;Address:TExcludeAddress);
Begin
 S:='';
 S:=S+IntToStr(Address.Zone)+':'+IntToStr(Address.Net)+'/'+IntToStr(Address.Node);
End;

Function  IsAddressesEqual(Addr1,Addr2:TAddress):Boolean;
Begin
With Addr1 Do
  Begin
  If (Zone=Addr2.Zone) And (Net=Addr2.Net) And (Node=Addr2.Node) And
     (Point=Addr2.Point) Then
     IsAddressesEqual:=True
  Else
     IsAddressesEqual:=False;
  End;
End;

Function GetStringFromAddress(Address:TAddress):String;
Var
S:String;
Begin
SetStringFromAddress(S,Address);
GetStringFromAddress:=S;
End;

Function  GetStringFromExcludeAddress(Address:TExcludeAddress):String;
Var
S:String;
Begin
 SetStringFromExcludeAddress(S,Address);
 GetStringFromExcludeAddress:=S;
End;

Function  GetStringWithPointFromAddress(Address:TAddress):String;
Var
S:String;
Begin
 SetStringFromAddress(S,Address);
 S:=S+'.'+IntToStr(Address.Point);
 GetStringWithPointFromAddress:=S;
End;

Function  GetStringAddressFromString(S:String):String;
Var
TA:TAddress;
SS:String;
Begin
 SS:='';
 SetAddressFromString(S,TA);
 SetStringFromAddress(SS,TA);
 GetStringAddressFromString:=SS;
End;

Function DigitMaskMatch(Mask,Source:String):Boolean;
Var
Count,Count1:Word;
Begin
DigitMaskMatch:=True;
Count:=1;
Count1:=1;
If Pos('*',Mask)= 0 Then
   Begin
    DigitMaskMatch:=StrUp(Mask)=StrUp(Source);
    Exit;
   End;
While Count<=Length(Mask) Do
 Begin
  If (Count>Length(Source)) or (Count>Length(Mask)) Then
   Begin
     DigitMaskMatch:=False;
     Break;
   End;
  Case Mask[Count] Of
    '0'..'9':
             Begin
              If Count<=Length(Source) Then
                Begin
                  If Source[Count]=Mask[Count] Then
                     Begin
                      Inc(Count);
{                      If (Length(Source)>Length(Mask)) And (Count>Length(Mask)) Then
                         DigitMaskMatch:=False;}
                     End
                 Else
                     Begin
                      DigitMaskMatch:=False;
                      Break;
                     End;
                End
             Else
                Break;
             End;
    '*':
        Begin
         While Count<=Length(Source) Do
           Begin
           If Count<Length(Mask) Then
              Begin
               If Pos('*',Copy(Mask,Count+1,Length(Mask)))>0 Then
                  Begin
                   If Pos(Copy(Mask,Count+1,Pos('*',Copy(Mask,Count+1,Length(Mask)))-1),Source)> 0 Then
                      Begin
                       Count:=Pos('*',Copy(Mask,Count+1,Length(Mask)))+Count;
                       Break;
                      End
                  Else
                      Begin
                       DigitMaskMatch:=False;
                       Exit;
                      End;
                  End
               Else
                  Begin
                   If Pos(Copy(Mask,Count+1,Length(Mask)),Source)> 0 Then
                      Begin
                       Count:=Length(Mask);
                       Break;
                      End
                  Else
                      Begin
                       DigitMaskMatch:=False;
                       Exit;
                      End;
                  End;
              End
            Else
             Begin
              Inc(Count);
              Break;
             End;
           End;
        End;
{    'a'..'z','A'..'Z':
                      Begin
                       MaskMatch:=False;
                       Break;
                      End;}
    #00..#41,#43..#47,
    #58..#255        :
                      Begin
                       DigitMaskMatch:=False;
                       Break;
                      End;

   End;
 End;
End;

Function  CharsMaskMatch(Mask,Source:String):Boolean;
Begin
     CharsMaskMatch:=IsWildCardMatch(Mask,Source);
End;


Function  IsAddressMatch(Mask:String;Addr:TAddress):Boolean;
Var
MaskZone,
MaskNet,
MaskNode,
MaskPoint,
Zone,
Net,
Node,
Point:String;
BeginPos,EndPos:Word;
Begin
 IsAddressMatch:=True;
 Mask:=StrTrim(Mask);
 If Mask='' Then
    Begin
     IsAddressMatch:=False;
     Exit;
    End;
 Zone:=IntToStr(Addr.Zone);
 Net:=IntToStr(Addr.Net);
 Node:=IntToStr(Addr.Node);
 Point:=IntToStr(Addr.Point);
 BeginPos:=Pos(':',Mask);
 If BeginPos>0 Then
    Begin
     MaskZone:=Copy(Mask,1,BeginPos-1);
     Delete(Mask,1,BeginPos);
     If Not(DigitMaskMatch(MaskZone,Zone)) Then
        Begin
         IsAddressMatch:=False;
         Exit;
        End
    End;
 BeginPos:=Pos('/',Mask);
 If BeginPos>0 Then
    Begin
     MaskNet:=Copy(Mask,1,BeginPos-1);
     Delete(Mask,1,BeginPos);
     If Not(DigitMaskMatch(MaskNet,Net)) Then
        Begin
         IsAddressMatch:=False;
         Exit;
        End
    End;
 BeginPos:=Pos('.',Mask);
 If BeginPos>0 Then
    Begin
     MaskNode:=Copy(Mask,1,BeginPos-1);
     Delete(Mask,1,BeginPos);
     If Not(DigitMaskMatch(MaskNode,Node)) Then
        Begin
         IsAddressMatch:=False;
         Exit;
        End;
     MaskPoint:=Mask;
     If Not(DigitMaskMatch(Maskpoint,Point)) Then
        Begin
         IsAddressMatch:=False;
         Exit;
        End;
    End
 Else
    Begin
     MaskNode:=Mask;
     If Not(DigitMaskMatch(MaskNode,Node)) Then
        Begin
         IsAddressMatch:=False;
         Exit;
        End;
     MaskPoint:='0';
     If Not(DigitMaskMatch(MaskPoint,Point)) Then
        Begin
         IsAddressMatch:=False;
         Exit;
        End;
    End;
End;

Begin
End.
