UNIT InitOvr;

INTERFACE
Uses TVCC,Overlay;

IMPLEMENTATION

Begin
{RegisterTVCC;}
OvrInit('PLE.OVR');
if OvrResult <> ovrOk then
begin
  Writeln('Overlay manager initialization failed.');
  Halt(1);
end;
OvrInitEMS;
End.