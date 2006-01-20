Uses dos,dates,crt,strings,mcommon;
var
f:file;
ff:text;
s:string;
h,m,ss,hun,
hh,mm,sss,hhun:word;
begin
assign(f,'c:\vp20\doc\aa');
reset(f,1);
assign(ff,'c:\vp20\doc\licence.my');
rewrite(ff);
clrscr;
s:='';
gettime(h,m,ss,hun);
{writeln(h,':',m,':',ss,':',hun);}
while not eof(f) do
 begin
  write(ff,readlnfromfile(f));
 end;
close(f);
close(ff);
gettime(hh,mm,sss,hhun);
writeln(h,':',m,':',ss,':',hun);
writeln(hh,':',mm,':',sss,':',hhun);
end.