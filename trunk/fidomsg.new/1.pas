Uses Fido_Def,Incl;
Var
 P:PFidoMessage;
 Tf,tt:TfidoAddress;
Begin
 With tf Do
  begin
   zone:=1;
   net:=2;
   node:=3;
   point:=4;
  end;
 With tt Do
  begin
   zone:=1;
   net:=2;
   node:=3;
   point:=4;
  end;
 P:=new(PFidoMessage,Init(200));
 P^.InitHeader('andrew kornilov','vasya pupkin',tf,tt,'test subj',_attrPrivate);
 if P^.CreateMessage('c:\projects\pntmast.dwo\fidomsg.new')=0 then
   begin
    P^.WriteStrToMsg('   test string');
    p^.flushtodisk;
    p^.writeendblock;
    p^.closemessage;
   end;
 dispose(p,done);
End.