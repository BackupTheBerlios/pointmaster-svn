UNIT Incl;


INTERFACE

Const
  _attrPrivate   =  1;
  _attrCrash     =  2;
  _attrReceived  =  4;
  _attrSent      =  8;
  _attrAttach    = 16;      { File Attach}
  _attrInTransit = 32;      { in Transit }
  _attrOrphan    = 64;
  _attrKillSent  = 128;
  _attrLocal     = 256;
  _attrHold      = 512;
  _attrFRQ       = 2048;    { File req    }
  _attrRRQ       = 4096;    { Reciept Req }
  _attrCPT       = 8192;    { is Reciept  }
  _attrARQ       = 16384;   { Audit Req   }
  _attrURQ       = 32768;   { Update Req  }

Type
  Str16 = string[16];
  Str20 = string[20];
  Str36 = string[36];
  Str72 = string[72];

  DomainStr = string[25];
{  TNodeRec = record
    Zone,
    Net,
    Node,
    Point:   integer;
    Domain:  DomainStr;
  end;}

Const
 MonthNames: array[1..12] of string[3] =
                  ('Jan','Feb','Mar','Apr','May',
                   'Jun','Jul','Aug','Sep','Oct',
                   'Nov','Dec');

Type
  z40 = array[1..40] of char;
  z36 = array[1..36] of char;
  z20 = array[1..20] of char;
  z72 = array[1..72] of char;


  FidoMsgHeader = Record   { Structure of a FidoNet message header }
                 _From:   z36;
                 _To:     z36;
                 _Subj:      z72;
                 _Date:      z20;
                 _Times:     word;
                 _DestNode:      integer;
                 _OrigNode:      integer;
                 _Cost:      integer;
                 _OrigNet:  integer;
                 _DestNet:  integer;
                 _DestZone:  integer;    { FTS0001-15 }
                 _OrigZone:  integer;
                 _DestPoint: integer;
                 _OrigPoint: integer;
                 _Reply:     word;
                 _Attr:      word;
                 _Up:        word;
               End;


Type
 TAddress=Record
  Zone,
  Net,
  Node,
  Point: Integer;
  Domain:DomainStr;
 End;


Type
  PVarTagRec=^VarTagRec;
  VarTagRec=Record
    Tag:String[30];
    Flag:Word;
End;


Const
 NotAllowedFileNames:Array[0..10] of  String=(
                                      'NUL','CON','LPT1',
                                      'LPT2','LPT3','CLOCK$','AUX',
                                      'COM1','COM2','COM3','COM4');

Var
TotalBytes:LongInt;
ReadedBytes:LongInt;
CurrentOperation:String;
MsgMaskToSet:Word;
_IsPasswordValid,
_IsInBounceList:Boolean;
_PasswordFound,
_BounceFound:Boolean;

Const
CriticalMemorySize:LongInt=2000;
_flgNone:Word=0;
_flgDeletePoint=1;

_repCantChangeAnotherBoss=3;
_repAllDone=4;
_repNotAllowForPoint=5;
_repSegmentRequest=6;
_repHelpRequest=7;
_repErrorsInMessage=8;
_repErrorsInPointList=9;
_repStatisticRequest=10;
_repPasswordMismatch=11;
_repInBounceList=12;

Var
_logSearchForMsg,
_logFoundMsg,
_logFoundRequest,
_logCantOpenFile,
_logBossAddress,
_logAddedBosses,
_logDeletedBosses,
_logFalseDeletedBosses,
_logAddedPoints,
_logDeletedPoints,
_logChangedPoints,
_logFalseDeletedPoints,
_logFalseChangedPoints,
_logDuplicateBosses,
_logTryChangeAnotherBoss,
_logCantOpenTpl,
_logCantCreateMessage,
_logMasterIsBusyInAnotherTask,
_logCantCreateBusyFlag,
_logCantRemoveBusyFlag,
_logNotEnoughMemory,
_logCantDeleteFile,
_logCircularInclude,
_logBuildingPointList,
_logCreatingAllDoneReport,
_logCreatingFalseReport,
_logCreatingRequestReport,
_logInvalidPath,
_logInvalidFileName,
_logBadStatFileFormat,
_logPasswordMismatch,
_logInBounceList,
_logCantLoadScript:String;

Const
NULL=0;
NOT_PROCESS_STRING=1;
INCLUDE_FILE=2;
INCLUDE_SEGMENT=4;
INCLUDE_LISTERRORS=8;
INCLUDE_MESSAGEERRORS=16;
INCLUDE_STATISTIC=32;
INCLUDE_MESSAGEBODY=64;

MODE_NOTHING=1;
MODE_MSG=2;
MODE_BUILD=4;
MODE_MSG_BUILD=8;

_flgBossNotFound=1;
_flgDupeBosses=2;
_flgSingle=1;
_flgCollection=2;

Var
_flgDebug:Boolean;
_flgProcessMessages:Boolean;
_flgBuildPointList:Boolean;
AddedPoints,
DeletedPoints,
ChangedPoints,
FalseChangedPoints,
FalseDeletedPoints,
AddedBosses,
DeletedBosses,
FalseDeletedBosses,
DuplicateBosses:Integer;
WorkMode:Word;

Const
ConfigNameTag='CONFIGNAME';
LanguageNameTag='PM.LNG';
IncludeTag='#INCLUDE';
DefineTag='#DEFINE';
SegmentBodyTag='#SEGMENT';
ListErrorsTag='#ERRORSINLIST';
MessageErrorsTag='#ERRORSINMESSAGE';
StatisticTag='#STATISTIC';
OriginalMessageBodyTag='#MESSAGEBODY';
OriginTag='* Origin: ';
TearLineTag='--- ';
BossTag='BOSS';
PointTag='POINT';
_klgFMPT='FMPT';
_klgTOPT='TOPT';
_klgMSGID='MSGID';
Yes='YES';
No='NO';
PntMasterVersion='PointMaster v.0.05a '+
{$IFDEF DPMI}
'[PM]'
{$ELSE}
'[DOS]'
{$ENDIF};
PntMasterName='PointMaster';

TaskNumberTag:VarTagRec=(
                 Tag:'TASK';
                 Flag:_flgSingle);
MasterVerTag:VarTagRec=(
                 Tag:'VERSION';
                 Flag:_flgSingle);
MasterNameTag:VarTagRec=(
                 Tag:'MASTERNAME';
                 Flag:_flgCollection);
SysOpNameTag:VarTagRec=(
                 Tag:'SYSOPNAME';
                 Flag:_flgSingle);
SysOpAddressTag:VarTagRec=(
                 Tag:'SYSOPADDRESS';
                 Flag:_flgSingle);
FromFNameTag:VarTagRec=(
                 Tag:'FROMFNAME';
                 Flag:_flgSingle);
FromLNameTag:VarTagRec=(
                 Tag:'FROMLNAME';
                 Flag:_flgSingle);
FromFLNameTag:VarTagRec=(
                 Tag:'FROMFULLNAME';
                 Flag:_flgSingle);
FromAddressTag:VarTagRec=(
                 Tag:'FROMADDRESS';
                 Flag:_flgSingle);
FromPasswordTag:VarTagRec=(
                 Tag:'FROMPWD';
                 Flag:_flgSingle);
MustBePasswordTag:VarTagRec=(
                 Tag:'MUSTPWD';
                 Flag:_flgSingle);
PasswordTag:VarTagRec=(
                 Tag:'PWD';
                 Flag:_flgCollection);
BounceTag:VarTagRec=(
                 Tag:'BOUNCE';
                 Flag:_flgCollection);
UsePasswordsTag:VarTagRec=(
                 Tag:'USEPASSWORDS';
                 Flag:_flgSingle);
UseBounceTag:VarTagRec=(
                 Tag:'USEBOUNCE';
                 Flag:_flgSingle);
MasterAddressTag:VarTagRec=(
                 Tag:'MASTERADDRESS';
                 Flag:_flgSingle);
MasterLogNameTag:VarTagRec=(
                 Tag:'LOG';
                 Flag:_flgSingle);
LogSizeTag:VarTagRec=(
                 Tag:'LOGSIZE';
                 Flag:_flgSingle);
StatFileNameTag:VarTagRec=(
                 Tag:'BINARYSTATFILE';
                 Flag:_flgSingle);
PointSegmentNameTag:VarTagRec=(
                 Tag:'LISTSEGMENT';
                 Flag:_flgCollection);
DeleteListAfterProcessTag:VarTagRec=(
                 Tag:'DELETELISTAFTERPROCESS';
                 Flag:_flgSingle);
DestPointListNameTag:VarTagRec=(
                 Tag:'DESTPOINTLIST';
                 Flag:_flgSingle);
PointListNameTag:VarTagRec=(
                 Tag:'POINTLIST';
                 Flag:_flgCollection);
NetMailPathTag:VarTagRec=(
                 Tag:'NETMAILPATH';
                 Flag:_flgSingle);
CurrentMessageNameTag:VarTagRec=(
                 Tag:'CURMSG';
                 Flag:_flgSingle);
KillSentTag:VarTagRec=(
                 Tag:'KILLSENT';
                 Flag:_flgSingle);
SafeMsgModeTag:VarTagRec=(
                 Tag:'SAFEMSGMODE';
                 Flag:_flgSingle);
SplitCharTag:VarTagRec=(
                 Tag:'SPLITCHAR';
                 Flag:_flgSingle);
DeleteCharsTag:VarTagRec=(
                 Tag:'DELETEPOINTCHARS';
                 Flag:_flgSingle);
CommentsBeforeBossTag:VarTagRec=(
                 Tag:'COMMENTSBEFOREBOSS';
                 Flag:_flgSingle);
StringsToSkipAtBeginOfListTag:VarTagRec=(
                 Tag:'SKIPATBEGINOFLIST';
                 Flag:_flgSingle);
AddSemicolonAfterEachBossTag:VarTagRec=(
                 Tag:'ADDSEMICOLONAFTEREACH';
                 Flag:_flgSingle);
BusyFlagNameTag:VarTagRec=(
                 Tag:'BUSYFLAG';
                 Flag:_flgSingle);
FileAttachPathTag:VarTagRec=(
                 Tag:'FILEATTACHPATH';
                 Flag:_flgSingle);
ProcessFileAttachTag:VarTagRec=(
                 Tag:'PROCESSFILEATTACH';
                 Flag:_flgSingle);
UseFileAttachPathTag:VarTagRec=(
                 Tag:'USEFILEATTACHPATH';
                 Flag:_flgSingle);
ValidateStringTag:VarTagRec=(
                 Tag:'VALIDATESTRING';
                 Flag:_flgSingle);
UseValidateTag:VartagRec=(
                 Tag:'USEVALIDATE';
                 Flag:_flgSingle);
CurDateStrTag:VarTagRec=(
                 Tag:'CURDATE';
                 Flag:_flgSingle);
CurTimeStrTag:VarTagRec=(
                 Tag:'CURTIME';
                 Flag:_flgSingle);
DayOfWeekTag:VarTagRec=(
                 Tag:'DOW';
                 Flag:_flgSingle);
SubjTag:VarTagRec=(
                 Tag:'SUBJ';
                 Flag:_flgSingle);
FromTag:VarTagRec=(
                 Tag:'FROM';
                 Flag:_flgSingle);
ToTag:VarTagRec=(
                 Tag:'TO';
                 Flag:_flgSingle);
TearLineStrTag:VarTagRec=(
                 Tag:'TEARLINE';
                 Flag:_flgSingle);
OriginStrTag:VarTagRec=(
                 Tag:'ORIGIN';
                 Flag:_flgSingle);
RequestTag:VarTagRec=(
                 Tag:'REQUEST';
                 Flag:_flgSingle);
DeletedBossesTag:VarTagRec=(
                 Tag:'DELBOSSES';
                 Flag:_flgSingle);
AddedBossesTag:VartagRec=(
                 Tag:'ADDBOSSES';
                 Flag:_flgSingle);
FalseDeletedBossesTag:VarTagRec=(
                 Tag:'FDELBOSSES';
                 Flag:_flgSingle);
DeletedPointsTag:VarTagRec=(
                 Tag:'DELPOINTS';
                 Flag:_flgSingle);
AddedPointsTag:VarTagRec=(
                 Tag:'ADDPOINTS';
                 Flag:_flgSingle);
ChangedPointsTag:VarTagRec=(
                 Tag:'CHGPOINTS';
                 Flag:_flgSingle);
FalseDeletedPointsTag:VarTagRec=(
                 Tag:'FDELPOINTS';
                 Flag:_flgSingle);
FalseChangedPointsTag:VarTagRec=(
                 Tag:'FCHGPOINTS';
                 Flag:_flgSingle);
DuplicateBossesTag:VarTagRec=(
                 Tag:'DUPEBOSSES';
                 Flag:_flgSingle);

StatisticStringTag:VarTagRec=(
                 Tag:'STATSTRING';
                 Flag:_flgSingle);
StatisticDateTag:VarTagRec=(
                 Tag:'STATDATE';
                 Flag:_flgSingle);

OnStartScriptTag:VarTagRec=(
                 Tag:'ONSTARTSCRIPT';
                 Flag:_flgCollection);
OnExitScriptTag:VarTagRec=(
                 Tag:'ONEXITSCRIPT';
                 Flag:_flgCollection);

{Requests}
SegmentRequestTag:VarTagRec=(
                   Tag:'%SEGMENT';
                   Flag:_flgSingle);
HelpRequestTag:VarTagRec=(
                   Tag:'%HELP';
                   Flag:_flgSingle);
StatisticRequestTag:VarTagRec=(
                   Tag:'%STATISTIC';
                   Flag:_flgSingle);
_tplAllDone:VarTagRec=(
                      Tag:'ALLDONETPL';
                      Flag:_flgSingle);
_tplNotAllowForPoint:VarTagRec=(
                      Tag:'NOTFORPOINTTPL';
                      Flag:_flgSingle);
_tplCantChangeAnotherBoss:VarTagRec=(
                      Tag:'NOTANOTHERBOSSTPL';
                      Flag:_flgSingle);
_tplDoneSegRequest:VarTagRec=(
                      Tag:'SEGMENTREQUESTTPL';
                      Flag:_flgSingle);
_tplDoneHelpRequest:VarTagRec=(
                      Tag:'HELPREQUESTTPL';
                      Flag:_flgSingle);
_tplStatisticRequest:VarTagRec=(
                      Tag:'STATISTICREQUESTTPL';
                      Flag:_flgSingle);
_tplErrorsInMessage:VarTagRec=(
                      Tag:'ERRORSINMESSAGETPL';
                      Flag:_flgSingle);
_tplErrorsInPointList:VarTagRec=(
                      Tag:'ERRORSINPOINTLISTTPL';
                      Flag:_flgSingle);
_tplPntListHeader:VarTagRec=(
                      Tag:'LISTHEADER';
                      Flag:_flgSingle);
_tplPntListFooter:VarTagRec=(
                      Tag:'LISTFOOTER';
                      Flag:_flgSingle);
_tplBadPassword:VarTagRec=(
                      Tag:'BADPASSWORDTPL';
                      Flag:_flgSingle);
_tplInBounceList:VarTagRec=(
                      Tag:'BOUNCETPL';
                      Flag:_flgSingle);

IMPLEMENTATION

Begin
End.