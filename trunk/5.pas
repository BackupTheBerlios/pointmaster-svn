uses dos,fileio,crt;
var
 f:file;
 io:integer;
 i:integer;
begin
clrscr;
assign(f,'awde');
resetuntypedfile(f,1,io);
i:=32000;
blockwrite(f,i,sizeof(i));
closeuntypedfile(f,io);
end.