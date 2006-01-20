{$O+,F+}
Unit Err_Func;

INTERFACE

Uses
{$IFDEF VIRTUALPASCAL}
Use32,SysUtils,
{$ENDIF}
CRT,DOS,StakDump,Logger,Face,Incl,StrUnit,Config,MCommon,Parser,FileIO;


VAR
    Exit_Msg : String;
    Old_Exit : Pointer;
    InitSP : Word;

IMPLEMENTATION
{Type
    Q_ptr = ^Q_Data;
    Q_Data = record
                      Next : Q_Ptr;
                      Line_to_display : byte;
                      Err_Address : pointer;
                      Err_Seg : String[4];
                      Err_Ofs : String[4];
                      Err_Unit : String[30];
                      Err_Line : Longint;
                end;

VAR
   Stack_q : Q_ptr;
   Current_Line : Q_Ptr;
   Prev_Line : Q_Ptr;}

  {.L STAKDUMP}        {Kim Kokkokonnen's STAKDUMP routine from the Tpro Bonus Disk}
{  procedure DumpStack;}
    {-Dump stack of return addresses}
{  external;}

{FUNCTION Exist(Filename:string):boolean;
VAR File_Rec: SearchRec;
begin
    FindFirst(Filename,AnyFile,File_Rec);
    Exist := (DOSError = 0);
end;  {Func Exist}

{FUNCTION Strip_Blank(S : String) : String;
VAR Lng : byte ABSOLUTE S;
begin
     {Strip Blanks before Source string}
{     While S[1] = ' ' do
           Delete(S,1,1);
     {Strip Blanks After Source string}
{     While S[lng] = ' ' do
           Delete(S,lng,1);
     Strip_Blank := S;
end;

FUNCTION Str2Int(S : String) :Integer;
VAR I,E : integer;
begin
     Val(S,I,E);
     Str2Int := I;
end;

FUNCTION Int2Str(I : Integer) :String;
VAR S : String;
begin
     Str(I,S);
     Int2Str := S;
end;
}
FUNCTION Hex(w : Word) : STRING;
const
  hexChars : array [0..$F] of Char =
    '0123456789ABCDEF';
begin
  hEX :=hexChars[Hi(w) shr 4]+hexChars[Hi(w) and $F]+
        hexChars[Lo(w) shr 4]+hexChars[Lo(w) and $F];
END;

Function Hex_to_int(h : String) : word;
const
  hexChars : String[16] = '0123456789ABCDEF';
var f : word;
begin
     f := 0;
     while length(h) > 0 do
     begin
          if pos(Copy(h,1,1),HexChars) = 0 then
              f := 0
          Else
              f := (f*16)+pos(H[1],Hexchars)-1;
          delete(h,1,1);
     end;
     Hex_to_int := f;
end;

FUNCTION SHOW_PTR(p : POINTER) : STRING;
BEGIN
       IF P = NIL THEN
                sHOW_PTR := 'NIL'
       else
                SHOW_PTR := HEX(SEG(P^))+':'+HEX(OFS(P^));
END;

Procedure Ext_Error(Var ex_code ,Class_ , Action, Locus : byte);
{var
  Regs : Registers;}
begin
{  Regs.AH := $59;
  Regs.BX := 00;
  MsDos(Regs);
  Ex_code := Regs.AX;
  Class_ := Regs.BH;
  Action := Regs.BL;
  Locus := Regs.CH;}
end;  { Ext_Error }

{Function  Ptr_Between(Test,Min,Max : pointer) : Boolean;
var
     Ptr_addr ,
     top_addr,
     bott_addr,
     temp_addr : longint;
begin
     Ptr_addr := seg(Test^);
     Ptr_addr := (ptr_addr*16);
     Ptr_addr := ptr_addr+ofs(Test^);
     top_addr := seg(Max^);
     top_addr := (top_addr*16);
     top_addr := top_addr+ofs(Max^);
     bott_addr := seg(min^);
     bott_addr:=(bott_addr*16);
     bott_addr:=bott_addr+ofs(min^);
     if Bott_addr > top_addr then
     begin
          temp_addr := bott_addr;
          bott_addr := top_addr;
          Top_addr := temp_addr;
     end;
     Ptr_Between := (Ptr_addr >= bott_addr) AND (Ptr_addr < top_addr);
end;

Procedure Insert_to_Queue(_Line : Byte; _Error_seg, _Error_ofs : word);
VAR Temp_Line : Q_Ptr;
    Temp_addr : longint;
begin
     {Insert Line, and err_address to Q, blank Data}
{     New(Temp_Line);
     Fillchar(Temp_Line^,Sizeof(Temp_Line^),0);
     Temp_Line^.Line_to_Display := _Line;
     Temp_Line^.Err_Address := ptr(_Error_seg,_Error_Ofs);
     Temp_Line^.err_seg := Hex(_Error_seg);
     Temp_Line^.err_ofs := Hex(_Error_ofs);
     Current_Line := Stack_Q^.next;
     Prev_Line := Stack_Q;
     While (Current_Line <> Stack_Q)
       AND (seg(Current_Line^.Err_Address^) < _ERROR_seg)
       AND (ofs(Current_Line^.Err_Address^) < _ERROR_ofs) do
     begin
          Prev_Line := Current_Line;
          Current_Line := Current_Line^.next;
     end;
     Prev_Line^.next := temp_Line;
     Temp_Line^.next := Current_Line;
end;


Procedure Pint_Q_Dat;
VAR
  Map_File : TEXT;
  Map_Name : PathStr;
  Map_Dir  : dirStr;
  MAP_FlNm : NameStr;
  MAP_Ext  : ExtStr;
  Map_Line : String;
  Text_Buff : pointer;
  Text_Sze : longint;
  Valid_Map : Boolean;
  Line_Col : Byte;
  old_t,
  T_Line,
  Count_t : Byte;
  Suspect_Unit : NameStr;
  Suspect_Line : Integer;
  Suspect_Seg ,
  Suspect_Ofs : Longint;
  found_Here : boolean;

begin
     {Going through Q fill in Details as you come to them}
     {Open MAP file at Paramstr[0]'s path}

{     Textcolor(lightgreen);}
{     Old_T := wherey;
     fsplit(Fexpand(Paramstr(0)),Map_dir,Map_FlNm,Map_Ext);
     Map_Name := Map_Dir+Map_FLNm+'.MAP';
     IF NOT(EXIST(Map_Name)) then
     begin
          { LogWriteLn(Log,'#No MAP file found at '+Map_Name);}
{           Writeln;}
{           Valid_Map := False;
     end
     ELSE
     begin
           Valid_Map := True;
           {Open Map File}
{           ASSIGN(Map_File,Map_Name);
           Text_Sze := Maxavail - 2048;
           if Text_Sze > 65520 then
              Text_Sze := 65520;
           If Text_Sze > 1024 then
           begin
                getmem(Text_Buff,Text_Sze);
                SetTextBuf(Map_File,Text_Buff^,Text_Sze);
           end;
           Reset(Map_File);
           MAP_Line := '';
           {Read lines until eof or _Start__Stop}
{           TextColor(lightblue);
           While (copy(MAP_Line,1,12) <> ' Start  Stop') and not(eof(Map_File)) do
           begin
                Readln(Map_File,Map_Line);
           end;
           IF EOF(Map_File) then
           begin
{                Writeln;
                LogWriteLn(Log,'#Can''t Find Segments in Map File '+Map_Name);}
{                Valid_Map := False;
           end
     end;
     found_here := false;
     If Valid_Map then
     begin
           {Reset the list}
{           Current_Line := Stack_Q^.next;

           {First go thru Segment info fillin the list}
{           Readln(Map_File,Map_Line);
           Readln(Map_File,Map_Line);
           {Read Lines until EOF or not CODE}
{           Write('Reading '+Map_Name+' for SEGMENT Info :');}
{           While Not(EOF(MAP_File))
             and (Map_Line <> '')
             and (Current_Line <> Stack_Q) do
           begin
               found_here := false;
               if random(2) = 1 then Write('.');
               {Check if 2-4 = Int-hex Error Addr}
{               If copy(Map_Line,2,4) > Current_Line^.err_seg then
               begin
                    {This is it}
{                    Current_Line^.Err_Unit := 'Unknown (No Segment Data)';
                    Current_line := Current_Line^.next;
               end;
               If copy(Map_Line,2,4) = Current_Line^.err_seg then
               begin
                    {This is it}
{                    Current_Line^.Err_Unit := strip_Blank(copy(Map_Line,23,18));
                    Current_line := Current_Line^.next;
                    found_here := true;
               end;
               if not Found_here then
                    Readln(Map_File,Map_Line);
          end;
          While Current_Line <> Stack_q do
          begin
               Current_Line^.Err_Unit := 'Unknown (No Segment Data)';
               Current_Line := Current_Line^.next;
          end;

          {Skip publics info}
{          Writeln;}
          {Loop through until LINE}
{          While (not(EOF(Map_File)) AND
                (copy(Map_Line,1,4) <> 'Line')) do
          begin
               Readln(Map_File,Map_Line);
          end;
          If eof(Map_File) then
          begin
{               Writeln;
               Writeln('Program was not compiled with Line number info');}
{          end;
{          Current_Line := Stack_Q^.next;
          {Go through Line number info}
{          Write('Reading '+Map_Name+' for LINE Info :');}
          {Search for err_seg:_err_Ofs in each of the four possitions}

{          While (not(EOF(Map_File))
            AND (Current_Line <> Stack_Q)) do
          begin
               if random(20) = 1 then {Write('.');
{               For Line_Col := 0 to 3 do
               begin
                     found_here := True;
                     while Found_here do
                     begin
                          found_here := False;
                          if copy(map_line,12,1) <> ':' then
                               Suspect_Seg := -1
                          Else
                          begin
                               Suspect_Seg := Hex_to_int(copy(Map_Line,(Line_Col*16)+8,4));
                               Suspect_Ofs := Hex_to_int(copy(Map_Line,(Line_Col*16)+13,4));
                          end;
                          if Suspect_seg > seg(Current_Line^.Err_Address^) then
                          begin
                               Current_Line^.Err_Line := 0;
                               Current_Line := Current_Line^.next;
                          end;
                          if Suspect_seg = seg(Current_Line^.Err_Address^) then
                          begin
                               IF (copy(Map_Line,(Line_Col*16)+13,4) >= Current_Line^.Err_Ofs) THEN
                               begin
                                    Current_Line^.Err_Line := Str2int(strip_Blank(copy(Map_line,line_col*16+1,6)));
                                    Current_Line := Current_Line^.next;
                                    found_here := true;
                               end;
                          end;
                     end;
               end;
               if Not found_here then
                  Readln(Map_File,Map_Line);
          end;
          While Current_Line <> Stack_Q do
          begin
               Current_Line^.Err_Line := 0;
               Current_line := Current_Line^.next;
          end;
     end;{Valid_Map}
     {Close Map}
{     Close(Map_File);}
{     If Text_Sze > 1024 then
     begin
          freemem(Text_Buff,Text_Sze);
     end;
     t_Line := wherey;
     for count_t := Old_T to t_Line do
     begin
          GotoXY(1,Count_t);
          Clreol;
     end;
     Gotoxy(1,old_t);
     {Then Print out Q data}
{     Current_Line := Stack_Q^.next;
     While Current_Line <> Stack_Q do
     begin
          GotoXY(15,Current_Line^.Line_to_Display);
          with Current_Line^ do
          begin
               if Err_Line = 0 then
                   LogWriteLn('!Location :'+strip_Blank(err_Unit)+'  No Line Data')
               Else
                   LogWriteLn('!Location :'+strip_Blank(err_Unit)+'  On or just before Line:'+int2str(err_Line));
          end;
          Current_Line := current_Line^.next;
     end;
end;}

{$F+}

Procedure Exit_Message;

VAR
  Dos_Err,E,c,a,l : byte;
  blank : integer;
  err_s : string;
  Old_T,
  count_t : Byte;
  T_Line : Byte;
{  TPas_Err : String;}
  Max_Line : word;
  found_max : Boolean;
  T_1,
  T_2 : word;
  Output_File : TEXT;
  FileName:String;
  LineNo:LongInt;
begin
{     textmode(3);}
     Exitproc := old_Exit;
{     TextColor(Yellow);}
     If (ErrorAddr <> nil)
      {$IFNDEF VIRTUALPASCAL}
        and (Mem[PrefixSeg:5] <> $C3)
      {$ENDIF} Then
     begin
          {Error not previously handled, and not in user-interface Turbo}
          {Reset output to CRT, to give some pretty colours}
{          Ext_Error(e ,C , A, L);}
          Dos_Err := DosError;
          AssignCrt(Output);
          Rewrite(Output);

          {STRONGARM SOME HEAP SPACE, If other error functions need heap
          memory make sure they are activated first, ie: Initialised later
          in the program, CONFUSED? Sorry just take my word for it :-}
{$IFNDEF VIRTUALPASCAL}
{$IFNDEF DPMI}
{          RELEASE(HeapOrg);}
{$ENDIF}
{$ENDIF}
          {Firstly find out the Turbo Pascal error name}
          OpenOutput('pm.err');
          DumpExit;
          {DumpStack;}
          DumpScreen;
          CloseOutput;

{          Case ExitCode of
                1: TPas_Err := 'Invalid DOS function code';
                2: TPas_Err := 'File not found';
                3: TPas_Err := 'Path not found';
                4: TPas_Err := 'Too many open files';
                5: TPas_Err := 'File access denied';
                6: TPas_Err := 'Invalid file handle';
                8: TPas_Err := 'Not enough memory';
               12: TPas_Err := 'Invalid file access code';
               15: TPas_Err := 'Invalid drive number';
               16: TPas_Err := 'Cannot remove current directory';
               17: TPas_Err := 'Cannot rename across drives';
              100: TPas_Err := 'Disk read error';
              101: TPas_Err := 'Disk write error';
              102: TPas_Err := 'File not assigned';
              103: TPas_Err := 'File not open';
              104: TPas_Err := 'File not open for input';
              105: TPas_Err := 'File not open for output';
              106: TPas_Err := 'Invalid numeric format';
              150: TPas_Err := 'Disk is write-protected';
              151: TPas_Err := 'Unknown unit';
              152: TPas_Err := 'Drive not ready';
              153: TPas_Err := 'Unknown command';
              154: TPas_Err := 'CRC error in data';
              155: TPas_Err := 'Bad Drive request structure length';
              156: TPas_Err := 'Disk seek error';
              157: TPas_Err := 'Unknown media type';
              158: TPas_Err := 'Sector not found';
              159: TPas_Err := 'Printer out of Paper';
              160: TPas_Err := 'Device write fault';
              161: TPas_Err := 'Device read fault';
              162: TPas_Err := 'Hardware failure';
              200: TPas_Err := 'Division by zero';
              201: TPas_Err := 'Range check error';
              202: TPas_Err := 'Stack overflow error';
              203: TPas_Err := 'Heap overflow error';
              204: TPas_Err := 'Invalid pointer operation';
              205: TPas_Err := 'Floating point overflow';
              206: TPas_Err := 'Floating point underflow';
              207: TPas_Err := 'Invalid floating point operation';
              208: TPas_Err := 'Overlay manager not installed';
              209: TPas_Err := 'Overlay file read error';
              210: TPas_Err := 'Object not initialized';
              211: TPas_Err := 'Call to abstract method';
              212: TPas_Err := 'Stream registration error';
              213: TPas_Err := 'Collection index out of range';
              214: TPas_Err := 'Collection overflow error';
              215: TPas_Err := 'Arithmetic overflow error';
              216: TPas_Err := 'General protection fault';
              ELSE TPas_Err := 'Unknown Error code';
          end;}
          {Put out the standard Turbo Run-Time Error message}
          {$IFDEF VIRTUALPASCAL}
          If GetLocationInfo(ExceptAddr,FileName,LineNo)<>Nil Then
             LogWriteLn('!Get exception in '+FileName+' line: '+IntToStr(LineNo));
          {$ENDIF}
          LogWriteln('!RUN-TIME ERROR ['+IntToStr(exitcode)+'] '+GetErrorString(ExitCode)+' at '+Show_ptr(ErrorAddr));

{          Textcolor(White);}

          {Put out any special application warning}
{          LogWriteln('!Special routine exit message: '+Exit_Msg);
          Flush(Log);}
{          Writeln;}
          {Find the extended error code}
{          Ext_Error(e ,C , A, L);
          Dos_Err := DosError;}
          If Dos_Err <> 0 then
          begin
{               Textcolor(LightCyan);}
{               LogWriteln('!DOS Extended error report shows:');
               Flush(Log);
               Case E of
                 1 : Err_S := 'Invalid function number';
                 2 : Err_S := 'File not found';
                 3 : Err_S := 'Path not found';
                 4 : Err_S := 'Too many open files (no handles left)';
                 5 : Err_S := 'Access denied (file was opened Read Only)';
                 6 : Err_S := 'Invalid handle';
                 7 : Err_S := 'Memory control blocks destroyed';
                 8 : Err_S := 'Insufficient memory';
                 9 : Err_S := 'Invalid memory block address';
                10 : Err_S := 'Invalid environment';
                11 : Err_S := 'Invalid format';
                12 : Err_S := 'Invalid access code';
                13 : Err_S := 'Invalid data';
                15 : Err_S := 'Invalid drive was specified';
                16 : Err_S := 'Attempt to remove current directory';
                17 : Err_S := 'Not same device';
                18 : Err_S := 'No more files';
                19 : Err_S := 'Attempt to write on write-protected diskette';
                20 : Err_S := 'Unknown unit';
                21 : Err_S := 'Drive not ready';
                22 : Err_S := 'Unknown command';
                23 : Err_S := 'Data error (CRC)';
                24 : Err_S := 'Bad request structure length';
                25 : Err_S := 'Seek error';
                26 : Err_S := 'Unknown media type';
                27 : Err_S := 'Sector not found';
                28 : Err_S := 'Printer out of paper';
                29 : Err_S := 'Write fault';
                30 : Err_S := 'Read fault';
                31 : Err_S := 'General failure';
                32 : Err_S := 'Sharing violation';
                33 : Err_S := 'Lock violation';
                34 : Err_S := 'Invalid disk change';
                35 : Err_S := 'FCB unavailable';
                36 : Err_S := 'Sharing buffer overflow';
                50 : Err_S := 'Network request not supported';
                51 : Err_S := 'Remote computer not listening';
                52 : Err_S := 'Duplicate name on network';
                53 : Err_S := 'Network name not found';
                54 : Err_S := 'Network busy';
                55 : Err_S := 'Network device no longer exists';
                56 : Err_S := 'Net BIOS command limit exceeded';
                57 : Err_S := 'Network adapter hardware error';
                58 : Err_S := 'Incorrect response from network';
                59 : Err_S := 'Unexpected network error';
                60 : Err_S := 'Incompatible remote adapter';
                61 : Err_S := 'Print queue full';
                62 : Err_S := 'Not enough space for print file';
                63 : Err_S := 'Print file was deleted';
                65 : Err_S := 'Access denied';
                66 : Err_S := 'Network device type incorrect';
                67 : Err_S := 'Network name not found';
                68 : Err_S := 'Network name limit exceeded';
                69 : Err_S := 'Net BIOS session limit exceeded';
                70 : Err_S := 'Temporarily paused';
                71 : Err_S := 'Network request not accepted';
                72 : Err_S := 'Print or disk redirection is paused';
                80 : Err_S := 'File exists';
                82 : Err_S := 'Cannot make directory entry';
                83 : Err_S := 'Fail on INT 24';
                84 : Err_S := 'Too many redirections';
                85 : Err_S := 'Duplicate redirection';
                86 : Err_S := 'Invalid password';
                87 : Err_S := 'Invalid parameter';
                88 : Err_S := 'Network device fault';
               end;
               LogWriteln('!Extended Error Code:'+err_s);
               Flush(Log);
               Case c of
                 1 : Err_S := 'Out of resource';
                 2 : Err_S := 'Temporary situation';
                 3 : Err_S := 'Permission problem';
                 4 : Err_S := 'Internal error in system software';
                 5 : Err_S := 'Hardware failure';
                 6 : Err_S := 'Serious failure of system software';
                 7 : Err_S := 'Application program error';
                 8 : Err_S := 'File/item not found';
                 9 : Err_S := 'File/item of invalid format or type';
                10 : Err_S := 'File/item interlocked';
                11 : Err_S := 'Media failure: wrong disk, CRC error...';
                12 : Err_S := 'Collision with existing item';
                13 : Err_S := 'Classification doesn''t exist or is inappropriate';
               end;
               LogWriteln('!Error Class        :'+err_s);
               Flush(Log);
               Case a of
                 1 : Err_S := 'Retry';
                 2 : Err_S := 'Retry after pause';
                 3 : Err_S := 'Ask user to re-enter input';
                 4 : Err_S := 'Abort program with cleanup';
                 5 : Err_S := 'Abort immediately, skip cleanup';
                 6 : Err_S := 'Ignore';
                 7 : Err_S := 'Retry after user intervention';
               end;
               LogWriteln('!Recommended Action :'+err_s);
               Flush(Log);
               Case l of
                 1 : Err_S := 'Unknown or inappropriate';
                 2 : Err_S := 'Related to disk storage';
                 3 : Err_S := 'Related to the network';
                 4 : Err_S := 'Serial device';
                 5 : Err_S := 'Memory';
               end;
               LogWriteln('!Error Locus        :'+err_s);
               Flush(Log);
{               Writeln('');}
          end;
{          LogWriteln('!Trace into Procedure Stack Shows:');}
{.IFDEF DPMI}
          LogWriteLn('!Look at PM.ERR');
          LogWriteLn('!Please, report to the author immediately !');
          {Trace from error address to top of stack}
          {Trace;  {With many thanks to Kim Kokonnen for this routine}
{          OpenOutput('PM.ERR');
          DumpExit;
          DumpStack;
          DumpScreen;
          CloseOutput;}
{.ENDIF}
          Flush(Log);
{          Old_T := Wherey;
          T_Line := wherey-2;
          new(Stack_Q);
          Stack_Q^.next := Stack_Q;
          While (T_Line > 1) AND (ProgrammScreen[T_Line,1].Chr<>'T') do
          begin
               {From Cursor Position Grab each Trace pointer and find it's Map}
{               T_1 :=hex_to_int(ProgrammScreen[T_Line,1].Chr+
                                ProgrammScreen[T_Line,2].Chr+
                                ProgrammScreen[T_Line,3].Chr+
                                ProgrammScreen[T_Line,4].Chr);
               T_2:=hex_to_int(ProgrammScreen[T_Line,5].Chr+
                                ProgrammScreen[T_Line,6].Chr+
                                ProgrammScreen[T_Line,7].Chr+
                                ProgrammScreen[T_Line,8].Chr);
               Insert_to_Queue(T_Line, T_1 , T_2);
               {Go up list putting pointer data into insertion sorted Queue}
{               dec(T_Line);
 {         end;
{          Print_Q_Data;    {Now add info to those stack positions}
{          GotoXY(1,Old_t);}
          {Show All Error Data}
          {Stop remaining handlers from reporting error}
          ExitCode:=0;
          ErrorAddr := nil;
          UnSetBusyFlag(BusyFlag);
          DoneLog(Log);
          DoneScreen;
          ChangeToLastDIrectory;
{          Textcolor(lightgray);
          writeln('Press any key to continue');
          while not keypressed do;}
     end
     ELSE
     begin
        {You used HALT(X) to get out}
        if exitcode <> 0 then
        begin
           If ExitCode<>255 Then
             Begin
{              LogWriteln('#Program exitcode :'+IntToStr(Exitcode));}
{              LogWriteln('!Routine exit message:'+Exit_Msg);}
             End
            Else
             Begin
              LogWriteLn('');
              LogWriteLn(GetExpandedString(_logInterruptedByUser));
              Flush(Log);
              UnSetBusyFlag(BusyFlag);
              DoneLog(Log);
              DoneScreen;
             End;
{           SetBusyFlag;}
{           UnSetBusyFlag;}
{           Flush(Log);}
           ExitCode:=0;
           ErrorAddr := nil;
{           DoneLog(Log);
           DoneScreen;}
{           ChangeToLastDirectory;}
           Halt(ExitCode);
        end;
     end;
end;
{$F-}


begin
        {Save initial stack pointer}
        InitSP := SPtr+4;
        {Set up ExitProc}
        Exit_Msg := '';
        Old_Exit := exitProc;
        Exitproc := @Exit_Message;
end.



