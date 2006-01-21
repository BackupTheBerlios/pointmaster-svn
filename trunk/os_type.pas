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
;               ��p�������� �p��� ����᪠.
; Parameters:   none.
; Return:       1 - DOS (�p���p���, v.6.22 & Win'95.OSR2 � p��.��.DOS),
;;              2 - DESQview (�p���p���, v.2.60),
;;              3 - Win 3.x Standart-Mode (�� �p���p���),
;;              4 - Win 3.x Enhansed-Mode (�p���p���, v.3.11 4WG),
;;              5 - Win'95 (�p���p���, v.4.00.1111 [OSR2]),
;;              6 - Win'NT (�p���p��� (avk)),
;;              7 - OS/2 (�p���p��� _��_����_, v.3 & v.4 [Merlin]),
;;              8 - OS/2-Win (�p���p��� _��_����_, v.3 & v.4).
;; Attention:   DESQview ��-��� Win'95 ��p�������� ��� Win'95,
;;              Win'95 � p����� ���樨 DOS ��p�������� ��� DOS,
;;                   � � ���� DOS - ��� Win'95.}
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
