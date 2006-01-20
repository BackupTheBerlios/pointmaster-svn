UNIT Os_Type;

INTERFACE
Uses
{$IFDEF VIRTUALPASCAL}
Use32,
{$ENDIF}
Incl,Parser;

Const
OS_DOS   = 1;
OS_DV    = 2;
OS_WIN3S = 3;
OS_WIN3E = 4;
OS_WIN95 = 5;
OS_WINNT = 6;
OS_OS2   = 7;
OS_OS2WIN= 8;

Var
_Os_Type:Word;


Function Detect_Os_Type:Word;
Procedure TimeSlice;
Function SetOS_Type_String:String;

IMPLEMENTATION

{; -------------------------------------------------------------------
; Name:         MultiMode
;               опpеделение сpеды запуска.
; Parameters:   none.
; Return:       1 - DOS (пpовеpено, v.6.22 & Win'95.OSR2 в pеж.эмул.DOS),
;;              2 - DESQview (пpовеpено, v.2.60),
;;              3 - Win 3.x Standart-Mode (не пpовеpено),
;;              4 - Win 3.x Enhansed-Mode (пpовеpено, v.3.11 4WG),
;;              5 - Win'95 (пpовеpено, v.4.00.1111 [OSR2]),
;;              6 - Win'NT (пpовеpено (avk)),
;;              7 - OS/2 (пpовеpено _не_мной_, v.3 & v.4 [Merlin]),
;;              8 - OS/2-Win (пpовеpено _не_мной_, v.3 & v.4).
;; Attention:   DESQview из-под Win'95 опpеделяется как Win'95,
;;              Win'95 в pежиме эмуляции DOS опpеделяется как DOS,
;;                   а в окне DOS - как Win'95.}
Function Detect_Os_Type:Word;
Var
Os:Word;

Begin
 Os:=0;
{$IFNDEF VIRTUALPASCAL}
 Asm
                mov     AX, 3306h
                int     21h
                cmp     BX, 3205h
                jne     @Win3S
                mov     OS, OS_WINNT
                jmp     @quit

@Win3S:         mov     AX, 4680h
                int     2Fh
                or      AX, AX
                jnz     @Win
                mov     OS, OS_WIN3S
                jmp     @quit

@Win:           mov     AX, 1683h
                xor     BX, BX
                int     2Fh
                or      BX, BX
                jz      @DV

                mov     AX, 4A33h
                push    DS
                int     2Fh
                pop     DS
                or      AX, AX
                jz      @Win95
                mov     OS, OS_WIN3E
                jmp     @quit

@Win95:         mov     OS, OS_WIN95
                jmp     @quit

@DV:            mov     AX, 1022h
                xor     BX, BX
                int     15h
                or      BX, BX
                je      @OS2
                mov     OS, OS_DV
                jmp     @quit

@OS2:           mov     AX, 4010h
                int     2Fh
                cmp     AX, 4010h
                je      @DOS

                mov     AX, 3306h
                int     21h
                cmp     BL, 10d
                jb      @OS2Win
                mov     OS, OS_OS2
                jmp     @quit

@OS2Win:        mov     OS, OS_OS2WIN
                jmp     @quit

@DOS:           mov     OS, OS_DOS
@QUIT:
 End;
{$ENDIF}
Detect_Os_Type:=Os;

End;

Procedure TimeSlice;
Begin
{$IFNDEF FPC}
 Asm
   cmp  _OS_Type, 0
   je   @Fin
   cmp  _OS_Type, 1
   je   @Fin
   cmp  _OS_Type, 2
   je   @DV_TV
   jmp  @Win_OS2
 @DV_TV:
   mov  Ax, 1000h
   int  15h
   jmp  @Fin
 @Win_OS2:
   mov  Ax, 1680h
   int  2Fh
 @Fin:
  End;
{$ENDIF}
End;

Function SetOS_Type_String:String;
Begin
 {$IFDEF WIN32}
  SetVar(Os_TypeTag,'Windows');
 {$ENDIF}
 {$IFDEF OS2}
  SetVar(Os_TypeTag,'Os/2');
 {$ENDIF}
 {$IFDEF LINUX}
  SetVar(Os_TypeTag,'Linux');
 {$ENDIF}
 {$IFDEF MSDOS}
 Case _Os_Type Of
   0:SetVar(Os_TypeTag,'Unknown');
   1:SetVar(Os_TypeTag,'Dos');
   2:SetVar(Os_TypeTag,'DesqView');
   3:SetVar(Os_TypeTag,'Windows 3.x Standart');
   4:SetVar(Os_TypeTag,'Windows 3.x Enhanced');
   5:SetVar(Os_TypeTag,'Windows 95');
   6:SetVar(Os_TypeTag,'Windows NT');
   7:SetVar(Os_TypeTag,'OS/2');
   8:SetVar(Os_TypeTag,'OS/2-Win');
  End;
 {$ENDIF}
 {$IFDEF DPMI}
 Case _Os_Type Of
   0:SetVar(Os_TypeTag,'Unknown');
   1:SetVar(Os_TypeTag,'Dos');
   2:SetVar(Os_TypeTag,'DesqView');
   3:SetVar(Os_TypeTag,'Windows 3.x Standart');
   4:SetVar(Os_TypeTag,'Windows 3.x Enhanced');
   5:SetVar(Os_TypeTag,'Windows 95');
   6:SetVar(Os_TypeTag,'Windows NT');
   7:SetVar(Os_TypeTag,'OS/2');
   8:SetVar(Os_TypeTag,'OS/2-Win');
  End;
 {$ENDIF}
End;

Begin
{$IFDEF MSDOS}
_Os_Type:=Detect_Os_Type;
{$ENDIF}
{$IFDEF DPMI}
_Os_Type:=Detect_Os_Type;
{$ENDIF}
End.
