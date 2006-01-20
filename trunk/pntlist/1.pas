uses strunit;
var
f:text;
i:integer;
begin
assign(f,'aaaaaa');
rewrite(f);
writeln(f,'Boss,777:1998/1');
for i:=1 to 6000 do
 begin
  writeln(f,'Point,',inttostr(i),',HiWOsy,Vladivostok,Andrew_Kornilov,-Unpublished-,9600,MO,V42B,V32B');
 end;
close(f);
end.
