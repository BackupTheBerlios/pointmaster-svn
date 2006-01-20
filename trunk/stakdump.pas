{$IFDEF Windows}
  !! Error: not compatible with TPW
{$ENDIF}

{$S-,R-,V-,I-,B-,F-,A-,X+}
{$IFDEF DPMI}
  {$G+}
  {$C DEMANDLOAD,DISCARDABLE}
{$ENDIF}

unit StakDump;
  {-Stack dump for real or protected mode}

Interface

Uses
{$IFDEF VIRTUALPASCAL}
SysUtils,
{$ENDIF}
Go32,Incl,Dos,Dates;

{procedure DumpStack;
  {-Dump the current stack chain, starting at this routine's return address}
Procedure DumpExit;far;
Procedure DumpScreen;

procedure OpenOutput(FName : String);
  {-Create and open an alternate file for output reporting}

procedure CloseOutput;
  {-Close alternate output file}

procedure WriteOutput(S : String);
  {-Write a string to the output file}

{========================================================================}

implementation

{type
  OS = record
         O, S : Word;
       end;}
var
 { ExitSave : Pointer;{Exit procedure chain}
{  OutHandle : Word;  {Handle of file to write to. 1 = StdOut}
  {$IFDEF DPMI}
  ProgSele : Word;   {Selector of main program's code segment}
  {$ENDIF}
  CharBuf : Byte;    {Buffer for convenient writing}


Procedure OpenOutput(FName : String);
Begin
Assign(ErrorReportFile,FExpand(FName));
{$I-}
Append(ErrorReportFile);
{$I+}
If IOResult<>0 Then
  Begin
   {$I-}
   Rewrite(ErrorReportFile);
   {$I+}
   {$IFDEF VIRTUALPASCAL}
   If IOResult<>0 Then
      TextRec(ErrorReportFile).Handle:=1;
   {$ELSE}
   If IOResult<>0 Then
      TTextRec(ErrorReportFile).Handle:=1;
   {$ENDIF}
  End;
End;

{.IFDEF VIRTUALPASCAL}
procedure CloseOutput;
Begin
 {$I-}
  Close(ErrorReportFile);
 {$I+}
end;

procedure WriteOutput(S : String);
Begin
 {$I-}
  Write(ErrorReportFile,S);
 {$I+}

end;

(*
{.ELSE}

procedure CloseOutput; assembler;
asm
    mov  bx,TTextRec(ErrorReportFile).Handle
    mov  ah,$3E
    int  $21
    jc   @1
    xor  ax,ax
@1: mov  InOutRes,ax
end;

procedure WriteOutput(S : String); assembler;
asm
    mov  ah,$40
    mov  bx,TTextRec(ErrorReportFile).Handle
    push ds
    lds  si,S
    xor  cx,cx
    mov  cl,[si]
    mov  dx,si
    inc  dx
    int  $21
    pop  ds
    jc   @1
    xor  ax,ax
@1: mov  InOutRes,ax
end;

{.ENDIF}*)

{procedure WriteAlAscii; assembler;
asm
    mov  CharBuf,al
    mov  ah,$40
    mov  bx,TTextRec(ErrorReportFile).Handle
    mov  cx,1
    mov  dx,offset CharBuf
    int  $21
end;

procedure WriteAxHex; assembler;
asm
    push ax
    mov  al,ah
    call @1
    pop  ax
@1: push ax
    mov  cl,4
    shr  al,cl
    call @2
    pop  ax
    and  al,$0F
@2: add  al,'0'
    cmp  al,'9'
    jbe  @3
    add  al,07
@3: call WriteAlAscii
end;}

(*const
  {Used to compute length of each instruction}
  InstrTable : array[0..255] of byte = (
    {0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F}
    09, 09, 09, 09, 02, 03, 01, 01, 09, 09, 09, 09, 02, 03, 01, 32,  {0}
    09, 09, 09, 09, 02, 03, 01, 01, 09, 09, 09, 09, 02, 03, 01, 01,  {1}
    09, 09, 09, 09, 02, 03, 01, 01, 09, 09, 09, 09, 02, 03, 01, 01,  {2}
    09, 09, 09, 09, 02, 03, 01, 01, 09, 09, 09, 09, 02, 03, 01, 01,  {3}
    01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01,  {4}
    01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 01,  {5}
    01, 01, 32, 32, 01, 01, 01, 01, 03, 11, 02, 10, 32, 32, 01, 01,  {6}
    02, 02, 02, 02, 02, 02, 02, 02, 02, 02, 02, 02, 02, 02, 02, 02,  {7}
    10, 11, 10, 10, 09, 09, 09, 09, 09, 09, 09, 09, 09, 09, 09, 09,  {8}
    01, 01, 01, 01, 01, 01, 01, 01, 01, 01, 05, 01, 01, 01, 01, 01,  {9}
    03, 03, 03, 03, 01, 01, 01, 01, 02, 03, 01, 01, 01, 01, 01, 01,  {A}
    02, 02, 02, 02, 02, 02, 02, 02, 03, 03, 03, 03, 03, 03, 03, 03,  {B}
    10, 10, 03, 01, 09, 09, 10, 11, 04, 01, 03, 01, 01, 02, 01, 01,  {C}
    09, 09, 09, 09, 01, 01, 32, 01, 09, 09, 09, 09, 09, 09, 09, 09,  {D}
    02, 02, 02, 02, 02, 02, 02, 02, 03, 03, 05, 02, 01, 01, 01, 01,  {E}
    01, 32, 01, 01, 01, 01, 18, 19, 01, 01, 01, 01, 01, 01, 09, 09   {F}
    );

    {Notes: 32 in table means an invalid or unsupported opcode.
            Instructions not supported:
              $0F    286/386/486 extended opcode prefix
              $62    BOUND
              $63    ARPL
            Generally, instructions with 32-bit addresses or operands
              are not supported.
    }

procedure RmLength; assembler;
  {Entry: AH = mod reg r/m byte to decode
          BX = instruction length so far
   Exit:  BX = total instruction length
          AX destroyed}
asm
    mov  al,ah                  {AL = next byte}
    and  al,$C0                 {AL = mod field}
    or   al,al                  {Direct addressing mode?}
    jnz  @4                     {No, check again}
    and  ah,7                   {AH = r/m field}
    cmp  ah,6                   {No base register mode?}
    jne  @1                     {No, just one byte of instruction}
    jmp  @3
@4: cmp  al,$40                 {One byte displacement mode?}
    je   @2                     {Yes, two bytes of instruction}
    cmp  al,$80                 {Two byte displacement mode?}
    jne  @1                     {No, just one byte of instruction}
@3: inc  bx
@2: inc  bx
@1: inc  bx
end;

procedure NextIP; assembler;
  {Entry: ES:DI points to current instruction
   Exit:  ES:DI points to next instruction
          AX,BX destroyed
          CF set if disassembly error}
asm
    mov  ax,es:[di]             {get next word of code}
    mov  bx,offset InstrTable   {point to instruction table}
    xlat                        {AL = instruction code delta}
    mov  bl,al                  {Save delta}
    xor  bh,bh
    and  bl,7                   {BX = instruction length}
    and  al,$F8                 {Separate instruction type}
    or   al,al                  {Itype = 0?}
    jz   @4                     {Jump if so}
    cmp  al,08                  {Itype = 8?}
    jne  @2                     {Jump if not}
@1: call RmLength               {Get addressing length}
    jmp  @4
@2: cmp  al,$10                 {Itype = $10?}
    jne  @3                     {No, error}
    mov  al,ah                  {AL = next byte of code}
    and  al,$38
    or   al,al
    jz   @1                     {Add RM and we're done}
    mov  bx,1                   {Base length is one}
    jmp  @1
@3: stc
    ret
@4: add  di,bx                  {Point DI to next}
end;

procedure IsFarProc; assembler;
  {Entry: ES:DI points to current instruction
   Exit:  ES:DI still points to current instruction
          ZF set if current procedure is NEAR
          CF set if disassembly error
          AX,BX destroyed}
asm
    push di                     {save IP value}
    clc                         {clear error flag}
@1: mov  al,es:[di]             {get next instruction}
    cmp  al,0C2h                {see if any RET instruction}
    je   @2
    cmp  al,0C3h                {see if any RET instruction}
    je   @2
    cmp  al,0CAh                {see if any RET instruction}
    je   @2
    cmp  al,0CBh                {see if any RET instruction}
    je   @2
    call NextIP                 {advance to next instruction}
    jnc  @1                     {loop if no error}
@2: test al,$08                 {is FAR bit set?}
    pop  di
end;

{.IFDEF DPMI}
procedure TraceStack(StartAddr : Pointer); assembler;
  {-Trace and dump stack, starting at code address StartAddr. PMode version}
asm
    les  di,StartAddr           {es:di -> physical start address of code}
    mov  si,[bp]
    mov  si,ss:[si]             {skip stack frame of this routine}
@1: mov  ax,es:[0]              {ax = logical code segment}
    call WriteAxHex
    mov  al,':'
    call WriteAlAscii
    mov  ax,di                  {ax = code offset}
    call WriteAxHex
    mov  al,13
    call WriteAlAscii           {write CR/LF}
    mov  al,10
    call WriteAlAscii
    cmp  word ptr ss:[si],0     {end of chain?}
    je   @3
    call IsFarProc
    jc   @3                     {exit if disassembly error}
    jz   @2
    mov  ax,ss:[si+4]           {ax = possible new code segment}
    verr ax                     {verify valid segment for reading}
    jnz  @3                     {jump if invalid segment}
    mov  es,ax
@2: mov  di,ss:[si+2]           {di = new code offset}
    mov  si,ss:[si]             {si = new BP}
    jmp  @1                     {loop to next scope}
@3:
end;

{$ELSE}

procedure FindOverlay; assembler;
  {Entry: ES:DI is current return address
          CX is segment load fixup
   Exit:  DX is physical segment, 0 if not available
          AX,BX destroyed}
asm
    mov  bx,es                  {Save segment in BX}
    mov  dx,bx                  {Default return value in DX, if not in overlay}
    mov  ax,OvrCodeList         {Walk through overlays, if any}
@1: or   ax,ax                  {More overlays?}
    jz   @4                     {Jump if not}
    add  ax,cx                  {Fixup for load base}
    mov  es,ax
    cmp  bx,es:[16]             {Physical overlaid segment?}
    je   @2
    cmp  bx,ax                  {Static overlaid segment?}
    je   @3
    mov  ax,es:[14]             {Next overlay segment}
    jmp  @1
@2: mov  bx,es                  {Convert physical to static}
@3: mov  dx,es:[16]             {Load physical from overlay control block}
    or   di,di
    jnz  @4
    mov  di,es:[2]              {Restore offset from overlay control block}
@4: mov  es,bx                  {Restore segment from ES}
end;

procedure TraceStack(StartAddr : Pointer); assembler;
  {-Trace and dump stack, starting at code address StartAddr. RMode version}
asm
    les  di,StartAddr           {es:di -> physical start address of code}
    mov  si,[bp]
    mov  si,ss:[si]             {skip stack frame of this routine}
    mov  cx,PrefixSeg
    add  cx,$10                 {CX = segment load fixup}
@1: call FindOverlay            {returns physical segment in DX}
    push dx                     {save segment}
    push cx                     {save fixup}
    mov  ax,es
    sub  ax,cx                  {AX = relative segment}
    call WriteAxHex
    mov  al,':'
    call WriteAlAscii
    mov  ax,di                  {ax = code offset}
    call WriteAxHex
    mov  al,13
    call WriteAlAscii           {write CR/LF}
    mov  al,10
    call WriteAlAscii
    pop  cx                     {restore fixup}
    pop  dx                     {restore physical segment}
    cmp  word ptr ss:[si],0     {end of chain?}
    je   @3
    or   dx,dx                  {is code available?}
    jz   @4                     {assume far if not}
    push es
    mov  es,dx
    call IsFarProc
    pop  es
    jc   @3                     {exit if disassembly error}
    jz   @2
@4: mov  es,ss:[si+4]           {ES = new code segment}
@2: mov  di,ss:[si+2]           {di = new code offset}
    mov  si,ss:[si]             {si = new BP}
    jmp  @1                     {loop to next scope}
@3:
end;
{.ENDIF}

procedure DumpStack; assembler;
asm
  push bp
  mov  bp,sp
  {Push the return address of this procedure}
  push word ptr [bp+4]
  push word ptr [bp+2]
  call TraceStack
  pop  bp
end;

{.IFDEF DPMI}
function ValidSele(Sele : Word) : Boolean; assembler;
  {-Return True if Sele is valid for reading}
asm
  verr Sele
  mov  al,0
  jnz  @1
  inc  al
@1:
end;

{.$DEFINE FastAndDirty}
{.IFDEF FastAndDirty}
{This routine uses information in the instance's module table. Given
 the dependence on hard coded offsets, it appears to be subject to
 change.}
function FindPhysAddr(LogAddr : Pointer) : Pointer;
  {-Return the selector:offset address for given logical segment:offset}
begin
  FindPhysAddr := Ptr(MemW[HInstance:$00F2+32*(OS(LogAddr).S-1)],
                      OS(LogAddr).O);
end;
{.ELSE}
function FindPhysAddr(LogAddr : Pointer) : Pointer;
  {-Return the selector:offset address for given logical segment:offset}
var
  LogExp : Word;
  LogTgt : Word;
  Sele : Word;
begin
  FindPhysAddr := nil;
  LogTgt := OS(LogAddr).S;
  if LogTgt <> $FFFF then begin
    {The logical address represents a valid code selector}
    LogExp := 1;
    Sele := ProgSele;
    repeat
      if not ValidSele(Sele) then
        {Invalid selector. Avoid a GPF}
        Exit;
      if MemW[Sele:0] <> LogExp then
        {Logical segment trace is off the track}
        Exit;
      if LogExp = LogTgt then begin
        {Found target selector}
        FindPhysAddr := Ptr(Sele, OS(LogAddr).O);
        Exit;
      end;
      {Next logical segment}
      inc(LogExp);
      {Next code selector (note 2 selectors per code segment)}
      inc(Sele, 2*SelectorInc);
    until LogExp > 1024; {Terminate eventually just in case}
  end;
end;
{.ENDIF}
{.ENDIF}
*)

Procedure DumpScreen;
Var
Count,Count1:Byte;
Begin
{.IFNDEF VIRTUALPASCAL}

{$IFDEF DPMI}
Move(Ptr(SegB800,0)^,ProgrammScreen,4000);
{$ENDIF}

For Count:=1 To 25 Do
 Begin
  For Count1:=1 To 80 Do
    Begin
     Write(ErrorReportFile,ProgrammScreen[Count,Count1].Chr);
    End;
  WriteLn(ErrorReportFile,'');
 End;
WriteLn(ErrorReportFile,' ');
{.ENDIF}
End;


procedure DumpExit;
var
  {PhysAddr : Pointer;}
  ExitStr : String[9];
{$IFDEF VIRTUALPASCAL}
  FileName:String;
  LineNo:LongInt;
{$ENDIF}
begin
{  ExitProc := ExitSave;}
  if ErrorAddr <> nil then begin
    {An error occurred, not a normal halt}
     begin
      {Able to translate logical address into physical}
      WriteOutput(PntMasterVersion+' '+GetDateString+' '+GetTimeString+#13#10);
      WriteOutput('Please, report to the author immediately !');
      WriteOutput(' ');
      WriteOutput(^M^J'Run-time error ');
      Str(ExitCode, ExitStr);
      WriteOutput(ExitStr+^M^J);
{$IFDEF VIRTUALPASCAL}
      If GetLocationInfo(ExceptAddr,FileName,LineNo)<>Nil Then
         WriteOutput('Get exception in '+FileName+' line: '+IntToStr(LineNo)+^M^J);
{$ENDIF}
    end;
  end;
end;

begin
  {Write to standard output by default}
{  OutHandle := 1;
  {Install stack dump exit handler}
{  ExitSave := ExitProc;
  ExitProc := @DumpExit;}
end.
