Uses Dos,crt,mcommon,segments,validate,parser,incl,fileio;
var
p:pathstr;
d:dirstr;
n:namestr;
e:extstr;
s:string;
f:searchrec;
Begin
{p:='c:\name\name\name.ext';
fsplit(p,d,n,e);
clrscr;
{writeln('*',d,'*');
writeln('*',n,'*');
writeln('*',e,'*');}
{while d<>'' do
 begin
  writeln(d);
  mkdir(d);
  fsplit(d,d,n,e);
 end;}
{writeln(isdirectoryexist('c:\'));}
{mkdir('tst');}
{mkdir('\tst\tt');}
{{{{writeln(createdirwithsubdirs('.\tttss\tt\ss\'));}
clrscr;
MODE_noconsole:=true;
setvar(extendedfilemasktag,yes);
findfirstex('c:\windows\*#.*@',anyfile,f);
while (doserror=0) do
 begin
   if doserrorex=0 then
      write(f.name+': ');
   findnextex(f);
 end;

findcloseex(f);
writeln(isfileordirectoryexistex('c:\windows\*#.*@'));
End.