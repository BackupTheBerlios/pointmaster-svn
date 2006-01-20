Uses Use32,Register;
Var
S:String;
Begin
 Write('Enter username and address: ');
 ReadLn(S);
 WriteKeyFile('PM.KEY',S);
End.