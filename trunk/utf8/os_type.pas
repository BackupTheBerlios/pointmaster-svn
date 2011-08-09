UNIT Os_Type;

INTERFACE
Uses
Use32,
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
Detect_Os_Type:=Os;

End;

Procedure TimeSlice;
Begin
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
End;

Begin
End.
