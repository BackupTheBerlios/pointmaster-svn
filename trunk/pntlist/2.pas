uses strunit;
var
f:text;
i:integer;
begin
assign(f,'a');
rewrite(f);
for i:=1 to 6000 do
 begin
  writeln(f,'Point ',inttostr(i),',HiWO');
 end;
close(f);
end.
