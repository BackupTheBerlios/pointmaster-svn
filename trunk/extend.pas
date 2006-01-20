Unit Extend;

Interface

function DosExtendHandles(Handles : Byte) : Word;

Implementation
Uses
  Dos;

{Const
  Handles = 250;}
  { You can reduce the value passed to Handles if fewer Files are required. }

Function DosExtendHandles(Handles : Byte) : Word;

Var
  Reg : Registers;

  begin
  { Check the Dos Version - This technique only works For Dos 3.0 or later }
{  Reg.ah := $30;
  MsDos(Reg);
  if Reg.al<3 then
  begin
    Writeln('Extend Unit Require Dos 3.0 or greater');
    halt(1);
  end;

  {Reset the FreePtr - This reduces the heap space used by Turbo Pascal}
 { if HeapOrg <> HeapPtr then
  {Checks to see if the Heap is empty}
{  begin
    Write('Heap must be empty before Extend Unit initializes');
    Writeln;
    halt(1);
  end;}
  Heapend := ptr(Seg(Heapend^) - (Handles div 8 + 1), Ofs(Heapend^));

  {Determine how much memory is allocated to Program}
  {Reg.Bx will return how many paraGraphs used by Program}
  Reg.ah := $4A;
  Reg.es := PrefixSeg;
  Reg.bx := $FFFF;
  msDos(Reg);

  {Set the Program size to the allow For new handles}
  Reg.ah := $4A;
  Reg.es := PrefixSeg;
  Reg.bx := reg.bx - (Handles div 8 + 1);
  msDos(Reg);

  {Error when a Block Size is not appropriate}
{  if (Reg.flags and 1) = 1 then
  begin
    Writeln('Runtime Error ', Reg.ax, ' in Extend.');
    halt(1);
  end;}

  {Allocate Space For Additional Handles}
  reg.ah := $67;
  reg.bx := Handles;
  MsDos(reg);
end;

Begin
 DosExtendHandles(250);
End.

