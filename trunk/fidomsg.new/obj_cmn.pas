Unit Obj_Cmn;

INTERFACE

Uses
{$IFDEF VIRTUALPASCAL}
Use32,
{$ENDIF}
Objects;

Type

   PStringCollectWoutSort=^TStringCollectWoutSort;
   TStringCollectWoutSort=Object(TStringCollection)
     Constructor Init(ALimit,ADelta:Integer);
     Function Compare(Key1,Key2:Pointer):Integer;Virtual;   
End;


IMPLEMENTATION

Constructor TStringCollectWoutSort.Init(ALimit,ADelta:Integer);
Begin
 Inherited Init(ALimit,ADelta);
 Duplicates:=True;
End;

Function TStringCollectWoutSort.Compare(Key1,Key2:Pointer):Integer;
Begin
 Compare:=-1;
End;

End.


