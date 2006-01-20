Uses Parser,Incl,crt;
var
s:string;
Begin
clrscr;
setvar(SegZoneTag,'777');
setvar(SegNetTag,'1998');
setvar(SegNodeTag,'911');
s:='%%zone%%%%net%%%%node%%';
makestring(s);
writeln(s);
makestring(s);
writeln(s);
End.