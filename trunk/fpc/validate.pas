{*******************************************************}
{ Free Vision Runtime Library                           }
{ Validation Unit                                       }
{ Version: 0.1.0                                        }
{ Release Date: July 23, 1998                           }
{                                                       }
{       Copyright (c) 1996 BitSoft Development, L.L.C.  }
{       Copyright (c) 1992 Borland International        }
{                                                       }
{*******************************************************}
{                                                       }
{ This unit is a port of Borland International's        }
{ Validate.pas unit.  It is for distribution with the   }
{ Free Pascal (FPK) Compiler as part of the 32-bit      }
{ Free Vision library.  The unit is still fully         }
{ functional under BP7 by using the tp compiler         }
{ directive when rebuilding the library.                }
{                                                       }
{*******************************************************}
{ To Do List:                                           }
{   - test all FPK routines                             }
{                                                       }
{*******************************************************}

unit Validate;

{$i platform.inc}

{$ifdef PPC_FPC}
  {$H-}
{$else}
  {$F+,O+,E+,N+}
{$endif}
{$X+,R-,I-,Q-,V-}
{$ifndef OS_LINUX}
  {$S-}
{$endif}

interface

uses
  ObjTypes, Objects{, tlDates};

const

{ TValidator Status constants }

  vsOk     =  0;
  vsSyntax =  1;      { Error in the syntax of either a TPXPictureValidator
                        or a TDBPictureValidator }

  { Validator option flags }
  voFill     =  $0001;
  voTransfer =  $0002;
  voOnAppend =  $0004;
  voReserved =  $00F8;

    { Common Picture Validator Integer Formats }
  PicIntUnsigned = '#[#][#]*{[;,]###}';    { unsigned int, optional commas }
  PicIntUnsignedComma = '#[#][#]*{;,###}'; { unsigned int with commas }
  PicIntSigned  = '[-]#[#][#]*{[;,]###}';  { signed int, optional commas }
  PicIntSignedComma = '[-]#[#][#]*{;,###}';{ signed int with commas }

    { Common Picture Validator Real Formats }
  picReal      = '[-]#[*#][[.]#[*#]][E[-]#[#]]';  { full capabilities }
  PicReal1 = '*#[{;,###}][.*#]';     { real, optional commas and decimal }
  PicReal2 = '#[#][#]*{;,###}[.*#]'; { real with commas, optional decimal }
  PicReal3 = '#[#][#]*{;,###}.[*#]'; { real with commas and at least a
                                       decimal point }
    { Common Picture Validator Stringl Formats }
  PicString1 = '*? ';          { accept only letters }
  PicString2 = '*& ';          { convert all letters to uppercase }
  PicFirstCharUp = '*{&*? }'; { uppercase the first char of every word }

    { Common Picture Validator Money Formats }
  PicMoney  = '$*#.##';
  PicMoney1 = '[$]*#[.[#][#]]'; { dollars, optional dollar sign and decimal }
  PicMoney2 = '[$]*#[.[#][#]]'; { dollars with comma, optional dollar sign }
  PicMoney3 = '$*#{;,###}[.[#][#]]';  { dollars, with comma and dollar sign }
     { dollars, optional dollar sign, commas and 0, 1 or 2 decimal places }
  PicMoney4 = '[$]*#[{;,###}][.[#][#]]';

    { Common Picture Validator Date Formats }
  PicDate1 = '#[#]/#[#]/##';     { date with 2 digit year last }
  PicDate2 = '#[#]/#[#]/##[##]'; { date with 2 or 4 digit year last }
  PicDate3 = '#[#]/#[#]/####';   { date with 4 digit year (mm/dd/yyyy) }
     { a date in the format "JAN 31, 1999" with auto fill-in }
  PicDate4 = '{J{AN ,U{N ,L }},FEB ,MA{R ,Y },A{PR ,UG },SEP ,OCT ,NOV' +
             ',DEC} {1[#],2[#],30,31,#};, 19##';

    { Common Picture Validator Time Formats }
  PicTime1 = '{##}:{##}[:{##}]'; { HH:MM:SS, optional seconds }
  PicTime2 = '{##}:{##}:{##}';   { HH:MM:SS }

    { Common Picture Validator Phone Formats }
  PicPhoneUS1 = '[(*3{#})]*3{#}-*4{#}'; { phone number, optional area code }
  PicPhoneUS2 = '(*3{#})*3{#}-*4{#}';   { phone number with area code }

     { FileName pictures for *.3 file name only; no path information }
  PicFilename1 = '{&*7[&]}.{*3[&]}'; { filename (no path) with extension }
  picFileName2  = '{&[&][&][&][&][&][&][&]}.{[&][&][&]}'; { forces uppercase }

    { Miscellaneous Picture Validator Formats }
  PicSSN = '###-##-####'; { US Social Security Number }
     { colors with autofill }
  PicColor = '{Red,Gr{ay,een},B{l{ack,ue},rown},White,Yellow}';


type
  TVTransfer = (vtDataSize, vtSetData, vtGetData);

{ Abstract TValidator object }

  PValidator = ^TValidator;
  TValidator = object(TObject)
    Status: Word;
    Options: Word;
    constructor Init;
    constructor Load(var S: TStream);
    procedure Error; virtual;
    function IsValidInput(var S: string;
      SuppressFill: Boolean): Boolean; virtual;
    function IsValid(const S: string): Boolean; virtual;
    procedure Store(var S: TStream);
    function Transfer(var S: String; Buffer: Pointer;
      Flag: TVTransfer): Word; virtual;
    function Valid(const S: string): Boolean;
  end;

{ TPXPictureValidator result type }

  TPicResult = (prComplete, prIncomplete, prEmpty, prError, prSyntax,
    prAmbiguous, prIncompNoFill);

{ TPXPictureValidator }

  PPXPictureValidator = ^TPXPictureValidator;
  TPXPictureValidator = object(TValidator)
    Pic: PString;
    constructor Init(const APic: string; AutoFill: Boolean);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Error; virtual;
    function IsValidInput(var S: string;
      SuppressFill: Boolean): Boolean; virtual;
    function IsValid(const S: string): Boolean; virtual;
    function Picture(var Input: string;
      AutoFill: Boolean): TPicResult; virtual;
    procedure Store(var S: TStream);
  end;

{ TFilterValidator }

  PFilterValidator = ^TFilterValidator;
  TFilterValidator = object(TValidator)
    ValidChars: TCharSet;
    constructor Init(AValidChars: TCharSet);
    constructor Load(var S: TStream);
    procedure Error; virtual;
    function IsValid(const S: string): Boolean; virtual;
    function IsValidInput(var S: string;
      SuppressFill: Boolean): Boolean; virtual;
    procedure Store(var S: TStream);
  end;

{ TRangeValidator }

  PRangeValidator = ^TRangeValidator;
  TRangeValidator = object(TFilterValidator)
    Min, Max: LongInt;
    constructor Init(AMin, AMax: LongInt);
    constructor Load(var S: TStream);
    procedure Error; virtual;
    function IsValid(const S: string): Boolean; virtual;
    procedure Store(var S: TStream);
    function Transfer(var S: String; Buffer: Pointer;
      Flag: TVTransfer): Word; virtual;
  end;

{ TLookupValidator }

  PLookupValidator = ^TLookupValidator;
  TLookupValidator = object(TValidator)
    function IsValid(const S: string): Boolean; virtual;
    function Lookup(const S: string): Boolean; virtual;
  end;

{ TStringLookupValidator }

  PStringLookupValidator = ^TStringLookupValidator;
  TStringLookupValidator = object(TLookupValidator)
    Strings: PStringCollection;
    constructor Init(AStrings: PStringCollection);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Error; virtual;
    function Lookup(const S: string): Boolean; virtual;
    procedure NewStringList(AStrings: PStringCollection);
    procedure Store(var S: TStream);
  end;

  {#Z+}
  PByteValidator = ^TByteValidator;
  {#Z-}
  TByteValidator = Object(TRangeValidator)
    { A TByteValidator provides the same functionality of a TRangeValidator,
      but the data is transfered as a byte rather than a LongInt.  This saves
      3 bytes of space in the record used to set/get data from a dialog. }
    constructor Init (AMin, AMax : Byte);
    function Transfer (var S : String; Buffer : Pointer;
                       Flag : TVTransfer) : Word; virtual;
  end;  { of TByteValidator }


  {#Z+}
  PIntegerValidator = ^TIntegerValidator;
  {#Z-}
  TIntegerValidator = Object(TRangeValidator)
    { A TIntegerValidator provides the same functionality of a
      TRangeValidator, but the data is transfered as an Integer rather than a
      LongInt.  This saves 2 bytes of space in the record used to set/get
      data from a dialog. }
    constructor Init (AMin, AMax : Integer);
    function Transfer (var S : String; Buffer : Pointer;
                       Flag : TVTransfer) : Word; virtual;
  end;  { of TIntegerValidator }


  {#Z+}
  PRealValidator = ^TRealValidator;
  {#Z-}
  TRealValidator = object(TPXPictureValidator)
    { A TRealValidator provides the equivalent of a TRangeValidator for real
      numbers.   When the voTransfer bit is set TRealValidator transfers the
      inputline's data as a real. }
    Min : Real;
      { Min is the lowest valid real value for the associated object. }
    Max : Real;
      { Max is the largest valid real value for the associated object. }
    constructor Init (APic: string; AutoFill: Boolean;
                      AMin, AMax : Real);
      { A TRealValidator object by first calling the Init
        constructor inherited from TFilterValidator, passing a set of
        characters containing the digits '0'..'9' and the characters '+', '.',
        and '-'.

        Sets Min to AMin and Max to AMax, establishing the range of
        acceptable long integer values. }
    constructor Load (var S: TStream);
      { Constructs and loads a real validator object from the stream S by
        first calling the Load constructor inherited from TFilterValidator,
        then reading the #Min# and #Max# fields introduced by
        TRealValidator. }
    procedure Error; virtual;
      { Displays a message box indicating that the entered value did not fall
        in the specified range. }
      {#X Min Max }
    function IsValid (const S: String): Boolean; virtual;
      { Converts the string S into an integer number and returns true if the
        result meets all three of these conditions: }
{#F+}
{
 * it is a valid real number
 * its value is greater than or equal to #Min#
 * it value is less than or equal to #Max# }
{#F-}
      { If any of those tests fails, IsValid returns False. }
    function IsValidInput (var S: string; SuppressFill: Boolean): Boolean;
                           virtual;
      { IsValidInput ensures that only acceptable characters are entered for
        a real number - +, -, 0..9, E, and e.  Use the validator's picture to
        validate the total real format. }
    procedure Store (var S: TStream);
      { Stores the real validator object on the stream S by first calling
        the Store method inherited from TFilterValidator, then writing the
        #Min# and #Max# fields introduced by TRangeValidator. }
    function Transfer (var S: String; Buffer: Pointer;
                       Flag: TVTransfer): Word; virtual;
      { Incorporates the three functions DataSize, GetData, and SetData that
        a range validator can handle for its associated input line.

        Instead of setting and reading the value of the numeric input line by
        passing a string representation of the number, Transfer can use a
        Real as its data record, which keeps your application from having
        to handle the conversion.

        S is the input line's string value, and Buffer is the data record
        passed to the input line.

        Depending on the value of Flag, Transfer either sets S from the
        number in Buffer^ or sets the number at Buffer to the value of the
        string S. If Flag is vtSetData, Transfer sets S from Buffer.

        If Flag is vtGetData, Transfer sets Buffer from S. If Flag is
        vtDataSize, Transfer neither sets nor reads data.

        Transfer always returns the size of the data transferred, in this
        case the size of a Real. }
  end;


  {#Z+}
  PSingleValidator = ^TSingleValidator;
  {#Z-}
  TSingleValidator = Object(TRealValidator)
    { A TSingleValidator provides the same functionality as a TRangeValidator,
      but for Singles.  The data is transfered as a Single variable. }
    constructor Init (APic: string; AutoFill: Boolean; AMin, AMax : Single);
      { Constructs ensures than AMin and AMax are valid Single numbers.  AMin
        and AMax are passed to the inherited #TRealValidator.Init#
        constructor. }
    function Transfer (var S : String; Buffer : Pointer;
                       Flag : TVTransfer) : Word; virtual;
      { Transfer overrides the inherited method to handle Single numbers
        rather than Reals. }
  end;  { of TSingleValidator }


  {#Z+}
  PWordValidator = ^TWordValidator;
  {#Z-}
  TWordValidator = Object(TRangeValidator)
    { A TWordValidator provides the same functionality as a TRangeValidator,
      but for Words.  The data is transfered as a Word variable. }
    constructor Init (AMin, AMax : Word);
      { Constructs ensures than AMin and AMax are valid Word numbers.  AMin
        and AMax are passed to the inherited #TRangeValidator.Init#
        constructor. }
    function Transfer (var S : String; Buffer : Pointer;
                       Flag : TVTransfer) : Word; virtual;
      { Transfer overrides the inherited method to handle Word numbers
        rather than LongInts. }
  end;  { of TWordValidator }


  {#Z+}
  PDateRec = ^TDateRec;
  {#Z-}
  TDateRec = record
    { TDateRec is the transfer record structure for a #TDateValidator#. }
    Month: Byte;
    Day: Byte;
    Year: Word;
  end;  { of TDateRec }

  TDateFormat = (dfMonth, dfDay, dfYear, dfMMDDYY, dfYYMMDD, df4DigitYear,
                 dfFill);
  TDateFormats = set of TDateFormat;

const
  WesternDate: TDateFormats = [dfMonth,dfDay,dfYear,dfMMDDYY,dfFill];
  EuropeanDate: TDateFormats = [dfMonth,dfDay,dfYear,dfYYMMDD,dfFill];

type
  PDateValidator = ^TDateValidator;
  TDateValidator = object(TPXPictureValidator)
    { TDateValidator provides an inputline validator for dates.  All date
      formats supported by the #Tools Library# #tlDates# unit are supported. }
    constructor Init (AFormat: TDateFormats; ASeparator: Char;
                      AutoFill: Boolean);
      { Init sets up the validator to use the specified date formatting in
        AFormat using the separator specified in ASeparator.

        If an error occurs, Init fails. }
      {#X Format Separator }
    constructor Load (var S: TStream);
      { Load calls the inherited Load constructor then reads #FFormat# and
        #FSeparator# from the stream.

        If an error occurs Load fails. }
    procedure Error; virtual;
    procedure Format (var AFormat: TDateFormats); virtual;
    function IsValid (const S: String): Boolean; virtual;
    function IsValidInput (var S: string; SuppressFill: Boolean): Boolean;
                           virtual;
      { IsValidInput ensures that only acceptable characters are entered for
        a real number 0..9, and #Separator#.  Use the validator's picture to
        validate the total real format. }
    function LeapYear (AYear: Word): Boolean; virtual;
      { LeapYear returns True if dfYear is not in #Format# or if AYear is a
        leap year. }
    function Separator: Char;
    procedure SetFormat (AFormat: TDateFormats); virtual;
      { SetFormat changes Pic to a picture that matches the specified
        AFormat and updates #Format#. }
    procedure SetSeparator (ASeparator: Char); virtual;
    procedure Store (var S: TStream);
      { Store calls the inherited Store method then writes #FFormat# and
        #FSeparator# to the stream. }
    function Transfer (var S : String; Buffer : Pointer;
                       Flag : TVTransfer) : Word; virtual;
      { Transfer overrides the inherited method to handle #TDateRec#
        variables as the data transfer record structure type.  Transfer uses
        the #Tools Library# #tlDates.DateToStr# and #tlDates.StrToDate#
        routines to perform the conversions. }
    private
      FFormat: TDateFormats;
        { FFormat holds the formatting parameters for string output of the
          date. }
        {#X SetFormat Separator TDateFormats }
      FSeparator: Char;
        { FSeparator is the character used to separate the components of a
          date.  Separator can not be changed without updating Pic. }
        {#X Format }
  end;  { of TDateValidator }


  PTimeRec = ^TTimeRec;
  TTimeRec = record
    { TTimeRec is the transfer record structure for a #TTimeValidator#. }
    Hours: Byte;
    Minutes: Byte;
    Seconds: Byte;
    Hundredths: Byte;
  end;  { of TTimeRec }

  TTimeFormat = (tfHours, tfMinutes, tfSeconds, tfHundredths, tf24Hour,
                 tfFill);
  TTimeFormats = set of TTimeFormat;

  PTimeValidator = ^TTimeValidator;
  TTimeValidator = object(TPXPictureValidator)
    { TTimeValidator provides an inputline validator for Times.  All Time
      formats supported by the #Tools Library# #tlTimes# unit are supported. }
    constructor Init (ATimeFormat: TTimeFormats; AutoFill: Boolean);
      { Init sets up the validator to use the default Time formatting,
        dfMMDDYY with a 2-digit year and all 3 components, day, month and
        year. }
      {#X SetFormat SetSeparator }
    constructor Load (var S: TStream);
      { Load calls the inherited Load constructor then reads #FFormat# and
        #FSeparator# from the stream.

        If an error occurs Load fails. }
    procedure Format (var ATimeFormat: TTimeFormats);
      { Format returns a bitmap of the order and components included in valid
        Times. To interpret the bits, use the #Tools Library#
        #tlTimes.dfXXXX# flags.

        The default format is dfMMDDYY with all components included.  To
        change the formatting, use the #SetFormat# method. }
      {#X Separator tlTimes }
    function Separator: Char;
      { Separator returns the character used to separate the components of a
        Time.

        The default Separator is a forward slash, '/'.  To change the
        Separator call #SetSeparator#. }
      {#X Format tlTimes }
    procedure SetFormat (ATimeFormat: TTimeFormats); virtual;
      { SetFormatsets #FFormat# to AFormat then upTimes the inputline's
        picture.  The next time the associated inputline is redrawn, the
        inputline is upTimed to the new separator. }
      {#X Format SetSeparator Transfer }
    procedure SetSeparator (ASeparator: Char); virtual;
      { SetSeparator sets #FSeparator# to ASeparator then upTimes the
        inputline's picture.  The next time the associated inputline is
        redrawn the inputline is upTimed to the new separator. }
      {#X Separator SetFormat Transfer }
    procedure Store (var S: TStream);
      { Store calls the inherited Store method then writes #FFormat# and
        #FSeparator# to the stream. }
    function Transfer (var S : String; Buffer : Pointer;
                       Flag : TVTransfer) : Word; virtual;
      { Transfer overrides the inherited method to handle #TTimeRec#
        variables as the data transfer record structure type.  Transfer uses
        the #Tools Library# #tlTimes.TimeToStr# and #tlTimes.StrToTime#
        routines to perform the conversions. }
  private
    FFormat: TTimeFormats;
      { FFormat holds the actual formatting parameters for string output of
        the Time. }
    FSeparator: Char;
      { FSeparator holds the character used to separate portions of the
        Time string. }
  end;  { of TTimeValidator }



procedure RegisterValidate;

{#Z+}
const
  RPXPictureValidator: TStreamRec = (
    ObjType: idPXPictureValidator;
    VmtLink: Ofs(TypeOf(TPXPictureValidator)^);
    Load: @TPXPictureValidator.Load;
    Store: @TPXPictureValidator.Store
  );

const
  RFilterValidator: TStreamRec = (
    ObjType: idFilterValidator;
    VmtLink: Ofs(TypeOf(TFilterValidator)^);
    Load: @TFilterValidator.Load;
    Store: @TFilterValidator.Store
  );

const
  RRangeValidator: TStreamRec = (
    ObjType: idRangeValidator;
    VmtLink: Ofs(TypeOf(TRangeValidator)^);
    Load: @TRangeValidator.Load;
    Store: @TRangeValidator.Store
  );

const
  RStringLookupValidator: TStreamRec = (
    ObjType: idStringLookupValidator;
    VmtLink: Ofs(TypeOf(TStringLookupValidator)^);
    Load: @TStringLookupValidator.Load;
    Store: @TStringLookupValidator.Store
  );
{#Z-}


implementation

{$ifdef Windows}
{$ifdef FPC}
{$undef windows}
  {$ifndef cdRebuild}
  uses MsgBox, Strings, Resource,Incl,StrUnit;
  {$else}
  uses Resource;
  {$endif cdRebuild}
{$else FPC}
uses WinTypes, WinProcs, Strings, OWindows;
{$endif FPC}
{$else}
  {$ifndef cdRebuild}
  uses MsgBox, Strings, Resource,Incl,StrUnit;
  {$else}
  uses Resource;
  {$endif cdRebuild}
{$endif Windows}

{****************************************************************************}
{ TByteValidator Object                                                      }
{****************************************************************************}
{****************************************************************************}
{ TByteValidator.Init                                                        }
{****************************************************************************}
constructor TByteValidator.Init (AMin, AMax : Byte);
begin
  if not TRangeValidator.Init(AMin,AMax) then
    Fail;
  Options := Options or voTransfer;
end;

{****************************************************************************}
{ TByteValidator.Transfer                                                    }
{****************************************************************************}
function TByteValidator.Transfer (var S : String; Buffer : Pointer;
                                  Flag : TVTransfer) : Word;
var
  Value : Byte;
  Code : Integer;
begin
  if (Options and voTransfer) = voTransfer then
  begin
    Transfer := SizeOf(Value);
    case Flag of
      vtGetData :
        begin
          Val(S,Value,Code);
          Byte(Buffer^) := Value;
        end;
      vtSetData : Str(Byte(Buffer^),S);
    end;
  end
  else Transfer := 0;
end;

{****************************************************************************}
{ TDateValidator Object                                                      }
{****************************************************************************}
{****************************************************************************}
{ TDateValidator.Init                                                        }
{****************************************************************************}
constructor TDateValidator.Init (AFormat: TDateFormats; ASeparator: Char;
                                 AutoFill: Boolean);
begin
  if (not TPXPictureValidator.Init('',AutoFill)) then
    Fail;
  Options := Options or voTransfer;
  Status := vsOk;
  FSeparator := ASeparator;
  SetFormat(AFormat);
end;

{****************************************************************************}
{ TDateValidator.Load                                                        }
{****************************************************************************}
constructor TDateValidator.Load (var S: TStream);
begin
  if not TPXPictureValidator.Load(S) then
    Fail;
  S.Read(FFormat,SizeOf(FFormat));
  S.Read(FSeparator,SizeOf(FSeparator));
  if (S.Status <> stOk) then
  begin
    TPXPictureValidator.Done;
    Fail;
  end;
end;

{****************************************************************************}
{ TDateValidator.Error                                                       }
{****************************************************************************}
procedure TDateValidator.Error;
type
  Str4 = string[4];
var
  S: string;
  Rec: record
    S: PString;
  end;
  function Year: Str4;
  begin
    if dfYear in FFormat then
      if df4DigitYear in FFormat then
        Year := 'YYYY'
      else Year := 'YY'
    else Year := '';
  end;
begin
  if dfYYMMDD in FFormat then
    S := Year
  else S := '';
  if dfMonth in FFormat then
    S := S + Separator + 'MM';
  if dfDay in FFormat then
    S := S + Separator + 'DD';
  if not (dfYYMMDD in FFormat) then
    S := S + Separator + Year;
  while (Length(S) > 0) and (S[1] = FSeparator) do
    Delete(S,1,SizeOf(FSeparator));
  while (Length(S) > 0) and (S[Length(S)] = FSeparator) do
    Delete(S,Length(S),SizeOf(FSeparator));
  Rec.S := PString(@S);
  MessageBox(^C + 'Invalid date format.  The date must be as follows:'#13#10 +
             #13#10 +
             ^C + S,@Rec,mfError or mfOkButton);
end;

{****************************************************************************}
{ TDateValidator.IsValid                                                     }
{****************************************************************************}
procedure TDateValidator.Format (var AFormat: TDateFormats);
begin
  AFormat := FFormat;
end;

{****************************************************************************}
{ TDateValidator.IsValid                                                     }
{****************************************************************************}
function TDateValidator.IsValid (const S: String): Boolean;
begin
  IsValid := (S <> '') and TPXPictureValidator.IsValid(S);
end;

{****************************************************************************}
{ TDateValidator.IsValidInput                                                }
{****************************************************************************}
function TDateValidator.IsValidInput (var S: string;
                                      SuppressFill: Boolean): Boolean;
const
  Feb = 2;
  Days: array[1..12] of Byte = (
    {Jan} 31, {Feb} 28, {Mar} 31, {Apr} 30, {May} 31, {Jun} 30,
    {Jul} 31, {Aug} 31, {Sep} 30, {Oct} 31, {Nov} 30, {Dec} 31);

{  function ValidMonth: Boolean;
  begin
  end;
  function ValidDay: Boolean;
  begin
    if (dfDay in FFormat) and (Date.Month
  end; }

begin
  IsValidInput := False;
  if TPXPictureValidator.IsValidInput(S,SuppressFill) then
  begin
{    Transfer(S,@Date,vtGetData); }
(*
    if (Length(S) = Length(Pic^)) then  { check total date }
    begin
      if (dfMonth in FFormat) then
      begin
        if (Date.Month < 1) or (Date.Month > 12) then
          Exit;
        if (dfDay in FFormat) then
      end;
    end
    else begin { check what we can of the day number }
    end;
    if (dfMonth in FFormat) then
    begin
      if (Date.Month = 0) or (Date.Month > 12) then
        Exit;  { bad month number }
      if (dfDay in FFormat) then
    end;
*)
    IsValidInput := True;
  end;
end;

{****************************************************************************}
{ TDateValidator.LeapYear                                                    }
{****************************************************************************}
function TDateValidator.LeapYear (AYear: Word): Boolean;
begin
  LeapYear :=  (not (dfYear in FFormat)) or
    ((AYear mod 4 = 0) and ((AYear mod 100 <> 0) or (AYear mod 400 = 0)));
end;

{****************************************************************************}
{ TDateValidator.Separator                                                   }
{****************************************************************************}
function TDateValidator.Separator: Char;
begin
  Separator := FSeparator;
end;


{****************************************************************************}
{ TDateValidator.SetFormat                                                   }
{****************************************************************************}
procedure TDateValidator.SetFormat (AFormat: TDateFormats);
var
  S: string[10];
  i: TDateFormat;
begin
  DisposeStr(Pic);
  FFormat := AFormat;
  S := '';
  for i := dfMonth to dfYear do
    if TDateFormat(i) in FFormat then
      S := S + Separator + '##';
  while (Length(S) > 0) and (S[1] = Separator) do
    Delete(S,1,SizeOf(FSeparator));
  if df4DigitYear in FFormat then
    if dfYYMMDD in FFormat then
      S := '##' + S
    else S := S + '##';
  Pic := NewStr(S);
end;

{****************************************************************************}
{ TDateValidator.SetSeparator                                                }
{****************************************************************************}
procedure TDateValidator.SetSeparator (ASeparator: Char);
var
  i: Byte;
begin
  for i := 1 to Length(Pic^) do
    if Pic^[i] = FSeparator then
      Pic^[i] := ASeparator;
  FSeparator := ASeparator;
end;

{****************************************************************************}
{ TDateValidator.Store                                                       }
{****************************************************************************}
procedure TDateValidator.Store (var S: TStream);
begin
  TPXPictureValidator.Store(S);
  S.Write(FFormat,SizeOf(FFormat));
  S.Write(FSeparator,SizeOf(FSeparator));
end;

{****************************************************************************}
{ TDateValidator.Transfer                                                    }
{****************************************************************************}
function TDateValidator.Transfer (var S : String; Buffer : Pointer;
                                  Flag : TVTransfer) : Word;
  procedure BuildRec;
  var
    S1: string[11];
    function GetPart: Word;
    var
      SepPos: Byte;  { position of first separator in S }
      Part: string[4];
      N: Word;
      Code: Integer;
    begin
      SepPos := Pos(Separator,S1);
      if SepPos > 0 then
      begin
        Part := Copy(S1,1,Pred(SepPos));
        Delete(S1,1,Succ(Length(Part)));  { delete separator too }
      end
      else begin
        Part := S1;
        Delete(S1,1,Length(Part));
      end;
      Val(Part,N,Code);
      GetPart := N;
    end;
  begin
    S1 := S;
    FillChar(Buffer^,SizeOf(TDateRec),#0);
    if (dfYear in FFormat) and (dfYYMMDD in FFormat) then
        TDateRec(Buffer^).Year := GetPart;  { european format string }
    if (dfMonth in FFormat) then
      TDateRec(Buffer^).Month := GetPart;
    if (dfDay in FFormat) then
      TDateRec(Buffer^).Day := GetPart;
    if (dfYear in FFormat) and (not (dfYYMMDD in FFormat)) then
      TDateRec(Buffer^).Year := GetPart;  { english format string }
  end;
  procedure BuildStr;
  type
    Str4 = string[4];
  var
    SubStr: Str4;
    function AddNumber (N: Word): str4;
    begin
      Str(N,SubStr);
      if (dfFill in FFormat) and (Length(SubStr) < 2) then
        AddNumber := '0' + SubStr
      else AddNumber := SubStr;
    end;
    function AddPart (Part: TDateFormat): str4;
    begin
      case Part of
        dfYear:
          begin
            SubStr := AddNumber(TDateRec(Buffer^).Year);
            if not (df4DigitYear in FFormat) then
              Delete(SubStr,1,Length(SubStr)-2);
          end;
        dfMonth: SubStr := AddNumber(TDateRec(Buffer^).Month);
        dfDay: SubStr := AddNumber(TDateRec(Buffer^).Day);
      end;
      AddPart := FSeparator + SubStr;
    end;
  begin
    S := '';
    if (dfYYMMDD in FFormat) and (dfYear in FFormat) then
      S := AddPart(dfYear);  { European format }
    if (dfMonth in FFormat) then
      S := S + AddPart(dfMonth);
    if (dfDay in FFormat) then
      S := S + AddPart(dfDay);
    if (not (dfYYMMDD in FFormat)) and (dfYear in FFormat) then
      S := S + AddPart(dfYear);   { American format }
    while (S[1] = FSeparator) do
      Delete(S,1,SizeOf(FSeparator));
  end;
begin
  if Options and voTransfer <> 0 then
  begin
    Transfer := SizeOf(TDateRec);
    case Flag of
      vtGetData: BuildRec;
      vtSetData: BuildStr;
    end;
  end
  else Transfer := 0;
end;

{****************************************************************************}
{ TFilterValidator Object                                                    }
{****************************************************************************}
{****************************************************************************}
{ TFilterValidator.Init                                                      }
{****************************************************************************}
constructor TFilterValidator.Init(AValidChars: TCharSet);
begin
  inherited Init;
  ValidChars := AValidChars;
end;

constructor TFilterValidator.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(ValidChars, SizeOf(TCharSet));
end;

function TFilterValidator.IsValid(const S: string): Boolean;
var
  I: Integer;
begin
  I := 1;
  while S[I] in ValidChars do
    Inc(I);
  IsValid := (I > Length(S));
end;

function TFilterValidator.IsValidInput(var S: string; SuppressFill: Boolean): Boolean;
var
  I: Integer;
begin
  I := 1;
  while S[I] in ValidChars do
    Inc(I);
  IsValidInput := I > Length(S);
end;

procedure TFilterValidator.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(ValidChars, SizeOf(TCharSet));
end;

{$IFDEF Windows}

procedure TFilterValidator.Error;
begin
  MessageBox(0, 'Invalid character in input', 'Validator', mb_IconExclamation or mb_Ok);
end;

{$ELSE}

procedure TFilterValidator.Error;
begin
{$ifndef cdRebuild}
  MessageBox(Resource.Strings^.Get(sInvalidCharacter), nil,
             mfError + mfOKButton);
{$endif cdRebuild}
end;

{$ENDIF Windows}

{****************************************************************************}
{ TIntegerValidator Object                                                   }
{****************************************************************************}

{****************************************************************************}
{ TIntegerValidator.Init                                                     }
{****************************************************************************}
constructor TIntegerValidator.Init (AMin, AMax : Integer);
begin
  if not TRangeValidator.Init(AMin,AMax) then
    Fail;
  Options := Options or voTransfer;
end;

{****************************************************************************}
{ TIntegerValidator.Transfer                                                 }
{****************************************************************************}
function TIntegerValidator.Transfer (var S : String; Buffer : Pointer;
                                     Flag : TVTransfer) : Word;
var
  Value : Integer;
  Code : Integer;
begin
  if (Options and voTransfer) = voTransfer then
  begin
    Transfer := SizeOf(Value);
    case Flag of
      vtGetData :
        begin
          Val(S,Value,Code);
          Integer(Buffer^) := Value;
        end;
      vtSetData : Str(Integer(Buffer^),S);
    end;
  end
  else Transfer := 0;
end;

{ TLookupValidator }

function TLookupValidator.IsValid(const S: string): Boolean;
begin
  IsValid := Lookup(S);
end;

function TLookupValidator.Lookup(const S: string): Boolean;
begin
  Lookup := True;
end;

{ TPXPictureValidator }

constructor TPXPictureValidator.Init(const APic: string;
  AutoFill: Boolean);
var
  S: String;
begin
  inherited Init;
  Pic := NewStr(APic);
  Options := voOnAppend;
  if AutoFill then Options := Options or voFill;
  S := '';
  if Picture(S, False) <> prEmpty then
    Status := vsSyntax;
end;

constructor TPXPictureValidator.Load(var S: TStream);
begin
  inherited Load(S);
  Pic := S.ReadStr;
end;

destructor TPXPictureValidator.Done;
begin
  DisposeStr(Pic);
  inherited Done;
end;

{$IFDEF Windows}

procedure TPXPictureValidator.Error;
var
  MsgStr: array[0..255] of Char;
begin
  StrPCopy(StrECopy(MsgStr,
    'Input does not conform to picture:'#10'    '), Pic^);
  MessageBox(0, MsgStr, 'Validator', mb_IconExclamation or mb_Ok);
end;

{$ELSE}

procedure TPXPictureValidator.Error;
begin
{$ifndef cdRebuild}
  MessageBox(Resource.Strings^.Get(sInvalidPicture),@Pic,
             mfError + mfOKButton);
{$endif cdRebuild}
end;

{$ENDIF Windows}

function TPXPictureValidator.IsValidInput(var S: string;
  SuppressFill: Boolean): Boolean;
begin
  IsValidInput := (Pic = nil) or
     (Picture(S, (Options and voFill <> 0)  and not SuppressFill) <> prError);
end;

function TPXPictureValidator.IsValid(const S: string): Boolean;
var
  Str: String;
  Rslt: TPicResult;
begin
  Str := S;
  Rslt := Picture(Str, False);
  IsValid := (Pic = nil) or (Rslt = prComplete) or (Rslt = prEmpty);
end;

function IsNumber(Chr: Char): Boolean;
const
  Numbers = ['0'..'9'];
begin
  IsNumber := (Chr in Numbers);
end;


function IsLetter(Chr: Char): Boolean;
const
  Letters = ['A'..'Z','a'..'z'];
begin
  IsLetter := (Chr in Letters);
end;

function IsSpecial(Chr: Char; const Special: string): Boolean;
var
  Len, i: Byte;
begin
  Len := Byte(Special[0]);
  i := 1;
  while (i < Len) and (Chr <> Special[i]) do
    Inc(i);
  IsSpecial := (i <= Len);
end;


function IsComplete(Rslt: TPicResult): Boolean;
begin
  IsComplete := Rslt in [prComplete, prAmbiguous];
end;


function IsIncomplete(Rslt: TPicResult): Boolean;
begin
  IsIncomplete := Rslt in [prIncomplete, prIncompNoFill];
end;


function TPXPictureValidator.Picture(var Input: string;
  AutoFill: Boolean): TPicResult;
var
  I, J: Byte;
  Rslt: TPicResult;
  Reprocess: Boolean;

  function Process(TermCh: Byte): TPicResult;
  var
    Rslt: TPicResult;
    Incomp: Boolean;
    OldI, OldJ, IncompJ, IncompI: Byte;

    { Consume input }

    procedure Consume(Ch: Char);
    begin
      Input[J] := Ch;
      Inc(J);
      Inc(I);
    end;

    { Skip a character or a picture group }

    procedure ToGroupEnd(var I: Byte);
    var
      BrkLevel, BrcLevel: Sw_Integer;
    begin
      BrkLevel := 0;
      BrcLevel := 0;
      repeat
        if I = TermCh then Exit;
        case Pic^[I] of
          '[': Inc(BrkLevel);
          ']': Dec(BrkLevel);
          '{': Inc(BrcLevel);
          '}': Dec(BrcLevel);
          ';': Inc(I);
          '*':
            begin
              Inc(I);
              while IsNumber(Pic^[I]) do Inc(I);
              ToGroupEnd(I);
              Continue;
            end;
        end;
        Inc(I);
      until (BrkLevel = 0) and (BrcLevel = 0);
    end;

    { Find the a comma separator }

    function SkipToComma: Boolean;
    begin
      repeat ToGroupEnd(I) until (I = TermCh) or (Pic^[I] = ',');
      { tvbugs31 patch }
      { if Pic^[I] = ',' then Inc(I); }
       if (I < TermCh) and (Pic^[I] = ',') then Inc(I);
       { end patch }
      SkipToComma := I < TermCh;
    end;

    { Calclate the end of a group }

    function CalcTerm: Byte;
    var
      K: Byte;
    begin
      K := I;
      ToGroupEnd(K);
      CalcTerm := K;
    end;

    { The next group is repeated X times }

    function Iteration: TPicResult;
    var
      Itr, K, L: Byte;
      Rslt: TPicResult;
      NewTermCh: Byte;
    begin
      Itr := 0;
      Iteration := prError;

      Inc(I);  { Skip '*' }

      { Retrieve number }

      while IsNumber(Pic^[I]) do
      begin
        Itr := Itr * 10 + Byte(Pic^[I]) - Byte('0');
        Inc(I);
      end;

      if I > TermCh then
      begin
        Iteration := prSyntax;
        Exit;
      end;

      K := I;
      NewTermCh := CalcTerm;

      { If Itr is 0 allow any number, otherwise enforce the number }
      if Itr <> 0 then
      begin
        for L := 1 to Itr do
        begin
          I := K;
          Rslt := Process(NewTermCh);
          if not IsComplete(Rslt) then
          begin
            { Empty means incomplete since all are required }
            if Rslt = prEmpty then Rslt := prIncomplete;
            Iteration := Rslt;
            Exit;
          end;
        end;
      end
      else
      begin
        repeat
          I := K;
          Rslt := Process(NewTermCh);
        until not IsComplete(Rslt);
        if (Rslt = prEmpty) or (Rslt = prError) then
        begin
          Inc(I);
          Rslt := prAmbiguous;
        end;
      end;
      I := NewTermCh;
      Iteration := Rslt;
    end;

    { Process a picture group }

    function Group: TPicResult;
    var
      Rslt: TPicResult;
      TermCh: Byte;
    begin
      TermCh := CalcTerm;
      Inc(I);
      Rslt := Process(TermCh - 1);
      if not IsIncomplete(Rslt) then I := TermCh;
      Group := Rslt;
    end;

    function CheckComplete(Rslt: TPicResult): TPicResult;
    var
      J: Byte;
    begin
      J := I;
      if IsIncomplete(Rslt) then
      begin
        { Skip optional pieces }
        while True do
          case Pic^[J] of
            '[': ToGroupEnd(J);
            '*':
              if not IsNumber(Pic^[J + 1]) then
              begin
                Inc(J);
                ToGroupEnd(J);
              end
              else
                Break;
          else
            Break;
          end;

        if J = TermCh then Rslt := prAmbiguous;
      end;
      CheckComplete := Rslt;
    end;

    function Scan: TPicResult;
    var
      Ch: Char;
      Rslt: TPicResult;
    begin
      Scan := prError;
      Rslt := prEmpty;
      while (I <> TermCh) and (Pic^[I] <> ',') do
      begin
        if J > Length(Input) then
        begin
          Scan := CheckComplete(Rslt);
          Exit;
        end;

        Ch := Input[J];
        case Pic^[I] of
          '#': if not IsNumber(Ch) then Exit
               else Consume(Ch);
          '^': If Not (Ch In ['1'..'9']) Then
                  Exit
               Else
                  Consume(Ch);
          '?': if not IsLetter(Ch) then Exit
               else Consume(Ch);
          '&': if not IsLetter(Ch) then Exit
               else Consume(TrueUpCase(Ch));
          '!': Consume(TrueUpCase(Ch));
          '@': Consume(Ch);
          '$':If {((IsLetter(Ch)) or (IsNumber(Ch)) or (Ch=' ') or (Ch in [#176..#223])
                  or (IsSpecial(Ch,',.`~!@#$%^&*()_+|-=\/'':;[]"<>?'#0)))
                  and} (Ch<>'"') Then
               Consume(Ch)
              Else
               Exit;
          '%':If {((IsLetter(Ch)) or (IsNumber(Ch)) or (Ch=' ') or (Ch in [#176..#223])
                  or (IsSpecial(Ch,',.`~!@#$%^&*()_+|-=\/'':;[]"<>?'#0)))
                  and} (Ch<>')') and (Ch<>'(') Then
               Consume(Ch)
              Else
               Exit;
          '|':If {((IsLetter(Ch)) or (IsNumber(Ch)) or (IsSpecial(Ch,'.`~!@#$%^&*()_+|-=\/'':;"<>[]'#0)))}
                  (Ch in [#33..#255]) and (Ch<>',') Then
               Consume(Ch)
              Else
               Exit;
          '\':If {((IsLetter(Ch)) or (IsNumber(Ch)) or (IsSpecial(Ch,'.`~!@#$%^&*()_+|-=\/'':;"<>[]'#0)))}
                  (Ch in [#33..#126]) and (Ch<>',') Then
               Consume(Ch)
              Else
               Exit;
          '/':If ( (IsLetter(Ch)) or (IsNumber(Ch)) or (Ch=',') ){ or (IsSpecial(Ch,'.`~!@#$%^&*()_+|-=\/'':;"<>[]'#0)))}
              {    (Ch in [#33..#126]) and (Ch<>',')} Then
               Consume(Ch)
              Else
               Exit;

          '*':
            begin
              Rslt := Iteration;
              if not IsComplete(Rslt) then
              begin
                Scan := Rslt;
                Exit;
              end;
              if Rslt = prError then Rslt := prAmbiguous;
            end;
          '{':
            begin
              Rslt := Group;
              if not IsComplete(Rslt) then
              begin
                Scan := Rslt;
                Exit;
              end;
            end;
          '[':
            begin
              Rslt := Group;
              if IsIncomplete(Rslt) then
              begin
                Scan := Rslt;
                Exit;
              end;
              if Rslt = prError then Rslt := prAmbiguous;
            end;
        else
          if Pic^[I] = ';' then Inc(I);
          if UpCase(Pic^[I]) <> UpCase(Ch) then
            if Ch = ' ' then Ch := Pic^[I]
            else Exit;
          Consume(Pic^[I]);
        end;

        if Rslt = prAmbiguous then
          Rslt := prIncompNoFill
        else
          Rslt := prIncomplete;
      end;

      if Rslt = prIncompNoFill then
        Scan := prAmbiguous
      else
        Scan := prComplete;
    end;

  begin
    Incomp := False;
    IncompJ:=0;
    OldI := I;
    OldJ := J;
    repeat
      Rslt := Scan;

      { Only accept completes if they make it farther in the input
        stream from the last incomplete }
      if (Rslt in [prComplete, prAmbiguous]) and Incomp and (J < IncompJ) then
      begin
        Rslt := prIncomplete;
        J := IncompJ;
      end;

      if (Rslt = prError) or (Rslt = prIncomplete) then
      begin
        Process := Rslt;
        if not Incomp and (Rslt = prIncomplete) then
        begin
          Incomp := True;
          IncompI := I;
          IncompJ := J;
        end;
        I := OldI;
        J := OldJ;
        if not SkipToComma then
        begin
          if Incomp then
          begin
            Process := prIncomplete;
            I := IncompI;
            J := IncompJ;
          end;
          Exit;
        end;
        OldI := I;
      end;
    until (Rslt <> prError) and (Rslt <> prIncomplete);

    if (Rslt = prComplete) and Incomp then
      Process := prAmbiguous
    else
      Process := Rslt;
  end;

  function SyntaxCheck: Boolean;
  var
    I: Integer;
    BrkLevel, BrcLevel: Integer;
  begin
    SyntaxCheck := False;

    if Pic^ = '' then Exit;

    if Pic^[Length(Pic^)] = ';' then Exit;
    if (Pic^[Length(Pic^)] = '*') and (Pic^[Length(Pic^) - 1] <> ';') then
      Exit;

    I := 1;
    BrkLevel := 0;
    BrcLevel := 0;
    while I <= Length(Pic^) do
    begin
      case Pic^[I] of
        '[': Inc(BrkLevel);
        ']': Dec(BrkLevel);
        '{': Inc(BrcLevel);
        '}': Dec(BrcLevel);
        ';': Inc(I);
      end;
      Inc(I);
    end;
    if (BrkLevel <> 0) or (BrcLevel <> 0) then Exit;

    SyntaxCheck := True;
  end;


begin
  Picture := prSyntax;
  if not SyntaxCheck then Exit;

  Picture := prEmpty;
  if Input = '' then Exit;

  J := 1;
  I := 1;

  Rslt := Process(Length(Pic^) + 1);
  if (Rslt <> prError) and (Rslt <> prSyntax) and (J <= Length(Input)) then
    Rslt := prError;

  if (Rslt = prIncomplete) and AutoFill then
  begin
    Reprocess := False;
    while (I <= Length(Pic^)) and
      not IsSpecial(Pic^[I],'#?&!@|*{}[],$%/\^'#0) do
    begin
      if Pic^[I] = ';' then Inc(I);
      Input := Input + Pic^[I];
      Inc(I);
      Reprocess := True;
    end;
    J := 1;
    I := 1;
    if Reprocess then
      Rslt := Process(Length(Pic^) + 1)
  end;

  if Rslt = prAmbiguous then
    Picture := prComplete
  else if Rslt = prIncompNoFill then
    Picture := prIncomplete
  else
    Picture := Rslt;
end;

procedure TPXPictureValidator.Store(var S: TStream);
begin
  inherited Store(S);
  S.WriteStr(Pic);
end;

{ TRangeValidator }

constructor TRangeValidator.Init(AMin, AMax: LongInt);
begin
  inherited Init(['0'..'9','+','-']);
  if AMin >= 0 then ValidChars := ValidChars - ['-'];
  Min := AMin;
  Max := AMax;
end;

constructor TRangeValidator.Load(var S: TStream);
begin
  inherited Load(S);
  S.Read(Min, SizeOf(Max) + SizeOf(Min));
end;

{$IFDEF Windows}

procedure TRangeValidator.Error;
var
  Params: array[0..1] of Longint;
  MsgStr: array[0..80] of Char;
begin
  Params[0] := Min;
  Params[1] := Max;
  wvsprintf(MsgStr, 'Value is not in the range %ld to %ld.', Params);
  MessageBox(0, MsgStr, 'Validator', mb_IconExclamation or mb_Ok);
end;

{$ELSE}

procedure TRangeValidator.Error;
var
  Params: array[0..1] of Longint;
begin
  Params[0] := Min;
  Params[1] := Max;
{$ifndef cdRebuild}
  MessageBox(Resource.Strings^.Get(sInvalidValue), @Params,
             mfError + mfOKButton);
{$endif cdRebuild}
end;

{$ENDIF Windows}

function TRangeValidator.IsValid(const S: string): Boolean;
var
  Value: LongInt;
  Code: Integer;
begin
  IsValid := False;
  if inherited IsValid(S) then
  begin
    Val(S, Value, Code);
    if (Code = 0) and (Value >= Min) and (Value <= Max) then
      IsValid := True;
  end;
end;

procedure TRangeValidator.Store(var S: TStream);
begin
  inherited Store(S);
  S.Write(Min, SizeOf(Max) + SizeOf(Min));
end;

function TRangeValidator.Transfer(var S: String; Buffer: Pointer;
  Flag: TVTransfer): Word;
var
  Value: LongInt;
  Code: Integer;
begin
  if Options and voTransfer <> 0 then
  begin
    Transfer := SizeOf(Value);
    case Flag of
     vtGetData:
       begin
         Val(S, Value, Code);
         LongInt(Buffer^) := Value;
       end;
     vtSetData:
       Str(LongInt(Buffer^), S);
    end;
  end
  else
    Transfer := 0;
end;

{****************************************************************************}
{ TRealValidator Object                                                      }
{****************************************************************************}
{****************************************************************************}
{ TRealValidator.Init                                                        }
{****************************************************************************}
constructor TRealValidator.Init (APic: string; AutoFill: Boolean;
                                 AMin, AMax : Real);
begin
  if not TPXPictureValidator.Init(APic,AutoFill) then
    Fail;
  Min := AMin;
  Max := AMax;
end;


{****************************************************************************}
{ TRealValidator.Load                                                        }
{****************************************************************************}
constructor TRealValidator.Load(var S: TStream);
begin
  if not TPXPictureValidator.Load(S) then
    Fail;
  S.Read(Min,SizeOf(Min));
  S.Read(Max,SizeOf(Max));
  if S.Status <> stOk then
  begin
    TPXPictureValidator.Done;
    Fail;
  end;
end;


{****************************************************************************}
{ TRealValidator.Error                                                       }
{****************************************************************************}
{$IFDEF Windows}

procedure TRealValidator.Error;
var
  Params: array[0..1] of PStringRec;
  MsgStr: array[0..80] of Char;
begin
  Params[0].AString := Min;
  Params[1] := Max;
  wvsprintf(MsgStr, 'Value is not in the range %ld to %ld.', Params);
  MessageBox(0, MsgStr, 'Validator', mb_IconExclamation or mb_Ok);
end;

{$ELSE}

procedure TRealValidator.Error;
type
  PStringRec = record
    AString : PString;
  end;
var
  Params: array[0..1] of PStringRec;
  MinStr, MaxStr : string;
begin
  Transfer(MinStr,@Min,vtSetData);
  Transfer(MaxStr,@Max,vtSetData);
  Params[0].AString := PString(@MinStr);
  Params[1].AString := PString(@MaxStr);
  {$ifndef cdRebuild}
  MessageBox('Value not in the range %s to %s', @Params,
    mfError + mfOKButton);
  {$endif cdRebuild}
end;

{$ENDIF Windows}

{****************************************************************************}
{ TRealValidator.IsValid                                                     }
{****************************************************************************}
function TRealValidator.IsValid (const S: String): Boolean;
var
  MinStr, MaxStr: string;
  Width, Decimals: Integer;
  P, S1: string;
begin
  IsValid := False;
  if Pic = nil then
  begin
    IsValid := TPXPictureValidator.IsValid(S);
    Exit;
  end;
  P := Pic^;
  Width := Pos('.',P);
  Decimals := Length(P) - Width - 1;
  S1 := S;
  if (Pos('.',S1) = 0) then
    S1 := S1 + '.';
  if Pos('.',S1) > Width then
    Exit;  { too many numbers prior to decimal point }
  if ((Length(S1) - Width - 1) > Decimals) then
    Exit;  { too mnay numbers after decimal point }
  while ((Length(S1) - Pos('.',S1) - 1) < Decimals) do
    S1 := S1 + '0';
  Transfer(MinStr,@Min,vtSetData);
  Transfer(MaxStr,@Max,vtSetData);
  IsValid := (S1 >= MinStr) and (S1 <= MaxStr);
end;

{****************************************************************************}
{ TRealValidator.IsValidInput                                                }
{****************************************************************************}
function TRealValidator.IsValidInput (var S: string;
                                      SuppressFill: Boolean): Boolean;
const
  ValidChars: set of Char = ['0'..'9','+','-','.','E','e'];
var
  I: Integer;
begin
  I := 1;
  while S[I] in ValidChars do
    Inc(I);
  if (I > Length(S)) then
    if TPXPictureValidator.IsValidInput(S,SuppressFill) then
    begin
      IsValidInput := True;
      Exit;
    end
    else begin
      { catch simple formatting that doesn't pass picture format }
      IsValidInput := (S[Length(S)] = '.');
    end
  else IsValidInput := False;
end;

{****************************************************************************}
{ TRealValidator.Store                                                       }
{****************************************************************************}
procedure TRealValidator.Store(var S: TStream);
begin
  TPXPictureValidator.Store(S);
  S.Write(Min, SizeOf(Max) + SizeOf(Min));
end;

{****************************************************************************}
{ TRealValidator.Transfer                                                    }
{****************************************************************************}
function TRealValidator.Transfer (var S : String; Buffer : Pointer;
  Flag: TVTransfer): Word;
type
  Preal=^real;
var
  Value: Real;
  Width, Decimals, Code: Integer;
begin
  if Options and voTransfer <> 0 then
  begin
    Transfer := SizeOf(Value);
    case Flag of
     vtGetData:
       begin
         Val(S, Value, Code);
         PReal(Buffer)^:=Value;
       end;
     vtSetData:
       begin
         Width := Pred(Pos('.',Pic^));
         if (Width = 0) then
         begin
           Width := Length(Pic^);
           Decimals := 0;
         end
         else Decimals := Length(Pic^) - Width - 1 { for period };
         Str(PReal(Buffer)^:Width:Decimals, S);
       end;
    end;
  end
  else
    Transfer := 0;
end;

{****************************************************************************}
{ TSingleValidator Object                                                    }
{****************************************************************************}
{****************************************************************************}
{ TSingleValidator.Init                                                      }
{****************************************************************************}
constructor TSingleValidator.Init (APic: string; AutoFill: Boolean;
                                   AMin, AMax: Single);
begin
  if not TRealValidator.Init(APic,AutoFill,AMin,AMax) then
    Fail;
end;

{****************************************************************************}
{ TSingleValidator.Transfer                                                  }
{****************************************************************************}
function TSingleValidator.Transfer (var S : String; Buffer : Pointer;
  Flag: TVTransfer): Word;
type
  PSingle=^single;
var
  Value: Single;
  Code: Integer;
begin
  if Options and voTransfer <> 0 then
  begin
    Transfer := SizeOf(Value);
    case Flag of
     vtGetData:
       begin
         Val(S, Value, Code);
         PSingle(Buffer)^:= Value;
       end;
     vtSetData:
       Str(PSingle(Buffer)^, S);
    end;
  end
  else
    Transfer := 0;
end;

{ TStringLookupValidator }

constructor TStringLookupValidator.Init(AStrings: PStringCollection);
begin
  inherited Init;
  Strings := AStrings;
end;

constructor TStringLookupValidator.Load(var S: TStream);
begin
  inherited Load(S);
  Strings := PStringCollection(S.Get);
end;

destructor TStringLookupValidator.Done;
begin
  NewStringList(nil);
  inherited Done;
end;

{$IFDEF Windows}

procedure TStringLookupValidator.Error;
begin
  MessageBox(0,'Input not in valid-list', 'Validator',
    mb_IconExclamation or mb_Ok);
end;

{$ELSE}

procedure TStringLookupValidator.Error;
begin
{$ifndef cdRebuild}
  MessageBox(Resource.Strings^.Get(sNotInList), nil, mfError + mfOKButton);
{$endif cdRebuild}
end;

{$ENDIF Windows}

function TStringLookupValidator.Lookup(const S: string): Boolean;
var
  Index: Sw_Integer;
  Str: PString;
begin
  Str:=@s;
  Lookup := False;
  if Strings <> nil then
    Lookup := Strings^.Search(Str, Index);
end;

procedure TStringLookupValidator.NewStringList(AStrings: PStringCollection);
begin
  if Strings <> nil then Dispose(Strings, Done);
  Strings := AStrings;
end;

procedure TStringLookupValidator.Store(var S: TStream);
begin
  inherited Store(S);
  S.Put(Strings);
end;

{****************************************************************************}
{ TTimeValidator Object                                                      }
{****************************************************************************}
{****************************************************************************}
{ TTimeValidator.Init                                                        }
{****************************************************************************}
constructor TTimeValidator.Init (ATimeFormat: TTimeFormats;
                                 AutoFill: Boolean);
begin
    { Set FFormat and Pic so they are in sync }
  if (not inherited Init('',AutoFill)) then
    Fail;
  FSeparator := ':';
  SetFormat(ATimeFormat);
  Options := Options or voTransfer;
end;

{****************************************************************************}
{ TTimeValidator.Load                                                        }
{****************************************************************************}
constructor TTimeValidator.Load (var S: TStream);
begin
  if not TPXPictureValidator.Load(S) then
    Fail;
  S.Read(FFormat,SizeOf(FFormat));
  S.Read(FSeparator,SizeOf(FSeparator));
  if (S.Status <> stOk) then
  begin
    TPXPictureValidator.Done;
    Fail;
  end;
end;

{****************************************************************************}
{ TTimeValidator.Format                                                      }
{****************************************************************************}
procedure TTimeValidator.Format (var ATimeFormat: TTimeFormats);
begin
  ATimeFormat := FFormat;
end;

{****************************************************************************}
{ TTimeValidator.Seperator                                                   }
{****************************************************************************}
function TTimeValidator.Separator: Char;
begin
  Separator := FSeparator;
end;

{****************************************************************************}
{ TTimeValidator.SetFormat                                                   }
{****************************************************************************}
procedure TTimeValidator.SetFormat (ATimeFormat: TTimeFormats);
var
  P: string[10];
  Part: TTimeFormat;
begin
    { build new picture }
  P := '';
  for Part := tfHours to tfHundredths do
    if (Part in ATimeFormat) then
      P := P + FSeparator + '##';
  if (Pos(Separator,P) = 1) then
     Delete(P,1,SizeOf(FSeparator));
  DisposeStr(Pic);
  Pic := NewStr(P);
  FFormat := ATimeFormat;
end;

{****************************************************************************}
{ TTimeValidator.Store                                                       }
{****************************************************************************}
procedure TTimeValidator.Store (var S: TStream);
begin
  TPXPictureValidator.Store(S);
  S.Write(FFormat,SizeOf(FFormat));
  S.Write(FSeparator,SizeOf(FSeparator));
end;

{****************************************************************************}
{ TTimeValidator.Transfer                                                    }
{****************************************************************************}
procedure TTimeValidator.SetSeparator (ASeparator: Char);
begin
  FSeparator := ASeparator;
  SetFormat(FFormat);
end;

{****************************************************************************}
{ TTimeValidator.Transfer                                                    }
{****************************************************************************}
function TTimeValidator.Transfer (var S : String; Buffer : Pointer;
                                  Flag : TVTransfer) : Word;
  procedure BuildRec;
  var
    S1: string[11];
    function GetPart: Word;
    var
      SubStr: string[2];
      Width: Byte;
      N: Byte;
      Code: Integer;
    begin
      Width := Pos(FSeparator,S1);
      SubStr := Copy(S1,1,Width);
      Delete(S1,1,Succ(Width));
      Val(SubStr,N,Code);
      GetPart := N;
    end;
  begin
    with TTimeRec(Buffer^) do
    begin
      if (tfHours in FFormat) then
        Hours := GetPart;
      if (tfMinutes in FFormat) then
        Minutes := GetPart;
      if (tfSeconds in FFormat) then
        Seconds := GetPart;
      if (tfHundredths in FFormat) then
        Hundredths := GetPart;
    end;
  end;
  procedure BuildStr;
  type
    str2 = string[2];
    function AddPart (Part: TTimeFormat): str2;
      function AddNumber (N: Word): str2;
      var
        S2: str2;
      begin
        Str(N,S2);
        if (tfFill in FFormat) and (Length(S2) < 2) then
          S2 := '0' + S2;
        AddNumber := S2;
      end;
    var
      SubStr: str2;
    begin
      with TTimeRec(Buffer^) do
        case Part of
          tfHours: SubStr := AddNumber(Hours);
          tfMinutes: SubStr := AddNumber(Minutes);
          tfSeconds: SubStr := AddNumber(Seconds);
          tfHundredths: SubStr := AddNumber(Hundredths);
      end;
      AddPart := FSeparator + SubStr;
    end;
  var
    i: TTimeFormat;
  begin
    for i := tfHours to tfHundredths do
      if (i in FFormat) then
        S := S + AddPart(i);
    while (S[1] = FSeparator) do
      Delete(S,1,SizeOf(FSeparator));
  end;
begin
  if Options and voTransfer <> 0 then
  begin
    Transfer := SizeOf(TTimeRec);
    case Flag of
      vtGetData: BuildRec;
      vtSetData: BuildStr;
    end;
  end
  else Transfer := 0;
end;

{****************************************************************************}
{ TValidator Object                                                          }
{****************************************************************************}
{****************************************************************************}
{ TValidator.Init                                                            }
{****************************************************************************}
constructor TValidator.Init;
begin
  if not TObject.Init then
    Fail;
  Status := 0;
  Options := 0;
end;

{****************************************************************************}
{ TValidator.Load                                                            }
{****************************************************************************}
constructor TValidator.Load (var S : TStream);
begin
  if not TObject.Init then
    Fail;
  Status := 0;
  S.Read(Options, SizeOf(Options));
  if S.Status <> stOk then
  begin
    TObject.Done;
    Fail;
  end;
end;

{****************************************************************************}
{ TValidator.Error                                                           }
{****************************************************************************}
procedure TValidator.Error;
begin
end;

{****************************************************************************}
{ TValidator.IsValidInput                                                    }
{****************************************************************************}
function TValidator.IsValidInput (var S : String;
                                  SuppressFill : Boolean) : Boolean;
begin
  IsValidInput := True;
end;

{****************************************************************************}
{ TValidator.IsValid                                                         }
{****************************************************************************}
function TValidator.IsValid (const S : String) : Boolean;
begin
  IsValid := True;
end;

{****************************************************************************}
{ TValidator.Store                                                           }
{****************************************************************************}
procedure TValidator.Store (var S : TStream);
begin
  S.Write(Options,SizeOf(Options));
end;

{****************************************************************************}
{ TValidator.Transfer                                                        }
{****************************************************************************}
function TValidator.Transfer (var S : String; Buffer : Pointer;
                              Flag : TVTransfer) : Word;
begin
  Transfer := 0;
end;

{****************************************************************************}
{ TValidator.Valid                                                           }
{****************************************************************************}
function TValidator.Valid (const S : String) : Boolean;
begin
  Valid := False;
  if not IsValid(S) then
  begin
    Error;
    Exit;
  end;
  Valid := True;
end;

{****************************************************************************}
{ TWordValidator Object                                                      }
{****************************************************************************}

{****************************************************************************}
{ TWordValidator.Init                                                        }
{****************************************************************************}
constructor TWordValidator.Init (AMin, AMax : Word);
begin
  if not TRangeValidator.Init(AMin,AMax) then
    Fail;
  Options := Options or voTransfer;
end;

{****************************************************************************}
{ TWordValidator.Transfer                                                    }
{****************************************************************************}
function TWordValidator.Transfer (var S : String; Buffer : Pointer;
                                  Flag : TVTransfer) : Word;
var
  Value : Word;
  Code : Integer;
begin
  if (Options and voTransfer) = voTransfer then
  begin
    Transfer := SizeOf(Word);
    case Flag of
      vtGetData :
        begin
          Val(S,Value,Code);
          Word(Buffer^) := Value;
        end;
      vtSetData : Str(Word(Buffer^),S);
    end;
  end
  else Transfer := 0;
end;

{ Validate registration procedure }

procedure RegisterValidate;
begin
  RegisterType(RPXPictureValidator);
  RegisterType(RFilterValidator);
  RegisterType(RRangeValidator);
  RegisterType(RStringLookupValidator);
end;

end.
