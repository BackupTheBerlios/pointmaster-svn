Uses Script,Objects;
Var
TS:tdosStream;
counter:integer;
psc:pscriptcommand;
Begin
Load_Script('c:\projects\pntmast.dwo\script\notify.pms');
ts.init('comp',stcreate);
registertype(rpscriptcommand);
For Counter:=0 To Pred (compiledscript^.Count) Do
  begin
   psc:=compiledscript^.at(counter);
   psc^.store(ts);
  end;
ts.done;
done_script;
End.