UNIT therm;
INTERFACE
USES Views;

procedure Thermometer (Title            : VIEWS.TTitleStr;
                       Current, Total   : LongInt;
                       Abort            : boolean);

{*******************************************************}
{*******************************************************}
{*******************************************************}
IMPLEMENTATION
USES APP, DIALOGS, Objects;





{**************************************************************}
{* returns a string filled with the character specified       *}
{**************************************************************}
function Fill_String(Len : Byte; Ch : Char) : String;
var
  S : String;
begin
  IF (Len > 0) THEN
    BEGIN
      S[0] := Chr(Len);
      FillChar(S[1], Len, Ch);
      Fill_String := S;
    END
  ELSE Fill_String := '';
end; { FillString }


procedure Thermometer (Title            : VIEWS.TTitleStr;
                       Current, Total   : LongInt;
                       Abort            : boolean);
const
  Therm_Ptr  : PDialog = nil;
  Therm_Line : PStaticText = nil;
VAR
  Num_Blocks : integer;   {0,1..20}
  Temp_Str   : string;
  R          : TRect;
begin
  IF (Abort) THEN
    BEGIN
      IF (Therm_Ptr <> NIL) THEN
        BEGIN
          Desktop^.Delete (Therm_Ptr);
          Dispose (Therm_Ptr, DONE);
          Therm_Ptr := NIL;
        END;
    END

  ELSE
    BEGIN
      {*-------------------------------------------------------------*}
      {* determine how many of the 20 blocks to fill in              *}
      {*-------------------------------------------------------------*}
      IF (Total = 0)
        THEN Exit;
      IF (Current > Total)
        THEN Current := Total;
      Num_Blocks := (((Current*100) DIV Total) DIV 5);
      Temp_Str := Fill_String (Num_Blocks, chr(219)) +
                  Fill_String (20-Num_Blocks, chr(176));

      IF (Therm_Ptr = NIL) THEN
        BEGIN
          R.Assign (25,12,54,18);
          Therm_Ptr := New (PDialog,Init (R,Title));
          Therm_Ptr^.Flags := 0;
          R.Assign (5,1,28,2);
          Therm_Ptr^.Insert(New (PStaticText,
                                 Init (R,'5        50       100%')));

          R.Assign (5,3,28,4);
          Therm_Line := New (PStaticText, Init (R,Temp_Str));
          Therm_Ptr^.Insert (Therm_Line);
          DeskTop^.Insert (Therm_Ptr);
       END

      ELSE
        BEGIN
           Therm_Line^.Text^ := Temp_Str;
           Therm_Line^.DrawView;
        END;
    END; {if}

end; {thermometer}

end. {unit therm}