UNIT Incl;


INTERFACE
{$I VERSION.INC}
Uses
Use32,
Objects;

{$IFNDEF SPLE}

Const
  _attrPrivate:System.Word   =  1;
  _attrCrash:System.Word     =  2;
  _attrReceived:System.Word  =  4;
  _attrSent:System.Word      =  8;
  _attrAttach:System.Word    = 16;      { File Attach}
  _attrInTransit:System.Word = 32;      { in Transit }
  _attrOrphan:System.Word    = 64;
  _attrKillSent:System.Word  = 128;
  _attrLocal:System.Word     = 256;
  _attrHold:System.Word      = 512;
  _attrFRQ:System.Word       = 2048;    { File req    }
  _attrRRQ:System.Word       = 4096;    { Reciept Req }
  _attrCPT:System.Word       = 8192;    { is Reciept  }
  _attrARQ:System.Word       = 16384;   { Audit Req   }
  _attrURQ:System.Word       = 32768;   { Update Req  }


Type
  Str16 = string[16];
  Str20 = string[20];
  Str36 = string[36];
  Str72 = string[72];


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
{$ENDIF}
Type
  z40 = array[1..40] of char;
  z36 = array[1..36] of char;
  z20 = array[1..20] of char;
  z72 = array[1..72] of char;
{$IFNDEF SPLE}
  PFidoMsgHeader=^TFidoMsgHeader;
  TFidoMsgHeader = Record
                 _From:   z36;
                 _To:     z36;
                 _Subj:      z72;
                 _Date:      z20;
                 _Times:     System.word;
                 _DestNode:      System.integer;
                 _OrigNode:      System.integer;
                 _Cost:      System.integer;
                 _OrigNet:  System.integer;
                 _DestNet:  System.integer;
                 _DestZone:  System.integer;    { FTS0001-15 }
                 _OrigZone:  System.integer;
                 _DestPoint: System.integer;
                 _OrigPoint: System.integer;
                 _Reply:     System.word;
                 _Attr:      System.word;
                 _Up:        System.word;
               End;

{$ENDIF}
Type
 DomainStr = string[25];
Type
 PAddress=^TAddress;
 TAddress=Record
  Zone,
  Net,
  Node,
  Point: System.Word;
  Domain:DomainStr;
 End;

Type
  TExcludeAddress=Record
    Zone,
    Net,
    Node,
    Point: System.Word;
End;


Type
  PVarTagRec=^VarTagRec;
  VarTagRec=Record
    Tag:String[30];
    Flag:Word;
End;
{$IFNDEF SPLE}
Type
 ScreenPoint = Record
        Case Boolean of
             0 : (Chr : Char;
                  Attr: Byte);
             1 : (Pair      : Word);
         End;
    TxtScreen = Array[1..25,1..80] of ScreenPoint;

Const
{ NotAllowedFileNames:Array[0..10] of  String=(
                                      'NUL','CON','LPT1',
                                      'LPT2','LPT3','CLOCK$','AUX',
                                      'COM1','COM2','COM3','COM4');}
RArrow=#61#16#32;
{$ENDIF}
{$IFDEF SPLE}
 Const
{$ENDIF}
CheckWarnings:Boolean=False;
CheckErrors:Boolean=False;

Var

{$IFNDEF SPLE}
ProgrammScreen : TxtScreen;
ErrorReportFile:Text;

BusyFlag:File;

{FileIOResult:Integer;}
{$ENDIF}

PointListBuffer,
DestPointListBuffer:Array[1..2048] of Char;  { 64K buffer }

ModeString:String[50];

TotalBytes:LongInt;
ReadedBytes:LongInt;
CurrentOperation:String;

ExcludeAddr:TAddress;
_IsInExcludeList,
_IsPasswordValid,
_IsInBounceList,
_IsInReRouteList,
_IsInIgnoreList,
_IsInAutoUpdateList:Boolean;
_ExcludeFound,
_PasswordFound,
_BounceFound,
_ReRouteFound,
_AutoUpdateFound:Boolean;
_IsMsgWithMainPassword,
_IgnoreFound:Boolean;

_ExcludeListLoaded:Boolean;

ReRouteAddress:TAddress;
MessageForPntMaster:Boolean;

_IsPointListInMemory:Boolean;
_IsPointListUpdated:Boolean;
_IsWasMessages:Boolean;

DoUpCase:Boolean;
{DupeBossesStrings:PMessageBody;}
TimeSliceTimes:ShortInt;
PntListname:String;
CurrentBossIndex:Integer;
BossFound:Boolean;
PntMasterAddress,BossAddress,SysOpAddress:TAddress;

SavedInt23:Pointer;

PersonalErrors:Pointer;

Const
{FIXME ^ should be removed? SPLE works with removed only}
BossAddressMask='^[#][#][#][#]:^[#][#][#][#];/^[#][#][#][#]';

_whoNone=0;
_whoBOSS=1;
_whoSYSOP=2;
_whoCantChangeAnotherBoss=4;
_whoNotAllowedToPoint=8;
_whoPasswordMismatch=16;
_whoInBounceList=32;
_whoInExcludeList=64;
_whoReRoute=128;

CriticalMemorySize:LongInt=2000;
{_flgNone:Word=0;}
_varNONE:Word=0;
_varUPCASE:Word=2;
_varDOWNCASE:Word=4;
_flgDeletePoint=1;
{$IFNDEF SPLE}
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
_repInReRouteList=13;
_repInExcludeList=14;
_repErrorsInSegment=15;
{$ENDIF}
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
_logErrorPoints,
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
_logCreatingErrorsInSegmentReport,
_logCreatingErrorsInMessageReport,

_logInvalidPath,
_logInvalidFileName,
_logBadStatFileFormat,
_logPasswordMismatch,
_logInBounceList,
_logInExcludeList,
_logCantLoadScript,
_logStartScript,
_logDoneScript,
_logExecuting,
_logExitCode,
_logDosErrorOnExec,
_logWriteToNonOpenedMessage,
_logTryingToCloseNonOpenedMessage,
_logExitByCommand,
_logMessageNotForMaster,
_logReplacingBossComments,
_logInterruptedByUser,
_logMessageWithMainPassword,
_logTryToExecProtectedCommand,
_logMessageWithFileAttach,
_logLoadingListSegmentToMemory,
_logInReRouteList,
_logTryToReRouteToOurSelf,
_logMessageFromPoint,
_logCantOpenMessageForReadWrite,
_logCantWriteToMessage,
_logDosError,
_logBossWithoutPoints,
_logMessageFromIgnoreName,
_logBuildExcludeListIndex,
_logPreviousCopyIsCrashed,
_logAddNewPoint,
_logDeletePoint,
_logFalseDeletePoint,
_logChangeDataOfPoint,
_logFalseChangeDataOfPoint,
_logIndexFileDamaged,
_logNotAnIndexFile,
_logIndexFileWillBeReindexed,
_logCantCreateFile:String;

Const
DosErrorEx:Integer=0;

NULL=0;
NOT_PROCESS_STRING=1;
INCLUDE_FILE=2;
INCLUDE_SEGMENT=4;
INCLUDE_LISTERRORS=8;
INCLUDE_MESSAGEERRORS=16;
INCLUDE_STATISTIC=32;
INCLUDE_MESSAGEBODY=64;
EXECUTE_SCRIPT=128;
INCLUDE_PERSONALLISTERRORS=256;

IncludeTag='#INCLUDE';
DefineTag='#DEFINE';
ScriptTag='#SCRIPT';
SegmentBodyTag='#SEGMENT';
ListErrorsTag='#ERRORSINLIST';
MessageErrorsTag='#ERRORSINMESSAGE';
SegmentErrorsTag='#ERRORSINSEGMENT';
StatisticTag='#STATISTIC';
OriginalMessageBodyTag='#MESSAGEBODY';
LoadListSegmentTag='#LOADLISTSEGMENT';
Crc32Tag='#CRC32';

IgnoreTag='IGNORE';
WarningTag='WARN';
ErrorTag='ERROR';
RedundantFlagTag='REDUNDANTFLAG';
BadSystemFlagTag='BADSYSTEMFLAG';
BadUserFlagTag='BADUSERFLAG';
BadCharacterTag='BADCHAR';
BadPhoneTag='BADPHONE';
BadSpeedTag='BADSPEED';
DuplicateFlagTag='DUPEFLAG';

_evtIgnore=1;
_evtWarning=2;
_evtError=3;

MODE_NOTHING=1;
MODE_MSG=2;
MODE_BUILD=4;
MODE_MSG_BUILD=8;
MODE_CHECKLIST=16;

_flgBossNotFound=1;
_flgDupeBosses=2;
_flgSingle=1;
_flgCollection=2;

Var
MODE_DEBUG:Boolean;
MODE_NOCONSOLE:Boolean;

MsgFromGate:Boolean;
ToEmailName:String;

_logDebugString:String;
{_flgProcessMessages:Boolean;
_flgBuildPointList:Boolean;}
_flgCheckPointList:Boolean;
AddedPoints,
DeletedPoints,
ChangedPoints,
FalseChangedPoints,
FalseDeletedPoints,
ErrorPoints,
AddedBosses,
DeletedBosses,
FalseDeletedBosses,
DuplicateBosses:Integer;
WorkMode:Word;
StringsToSkipAtBegin:Word;

Type
  VerType=(_verAlpha,_verBeta,_verGamma,_verRelease);

Type
  VersionRec=Record
   Major,
   Minor,
   SubMinor:Byte;
   VersionType:VerType;
   Registered:Boolean;
 End;

Var
BinaryMasterVersion:VersionRec;
PntMasterVersion:String;

Const
BaseVersion='PointMaster v1.04a ';
SpleVersion='Simple PointList Editor v.0.02a '+
    {$IFDEF WIN32}
    '[W32]'
    {$ENDIF}
    {$IFDEF OS2}
    '[OS/2]'
    {$ENDIF}
    {$IFDEF LINUX}
    '[LNX]'
    {$ENDIF};
PntMasterName='PointMaster';

{ConfigNameTag='CONFIGNAME';}
LanguageNameTag='pm.lng';
OriginTag='* Origin: ';
TearLineTag='--- ';
BossTag='BOSS';
PointTag='POINT';
_klgFMPT='FMPT';
_klgTOPT='TOPT';
_klgMSGID='MSGID';
_klgINTL='INTL';
_klgREPLYTO='REPLYTO';
_klgREPLYADDR='REPLYADDR';
UUCPTag='UUCP';
Yes='YES';
No='NO';
SysOpTag='SYSOP';
BothTag='BOTH';
KillTag='KILL';
MoveTag='MOVE';
CopyTag='COPY';
EnglishTag='ENG';
RussianTag='RUS';

ExtendedFileMaskTag:VarTagRec=(
                 Tag:'EXTENDEDFILEMASK';
                 Flag:_flgSingle);

EventTag:VarTagRec=(
                 Tag:'EVENT';
                 Flag:_flgCollection);
ConfigNameTag:VarTagRec=(
                 Tag:'CONFIGNAME';
                 Flag:_flgSingle);
MasterVerTag:VarTagRec=(
                 Tag:'VERSION';
                 Flag:_flgSingle);
DeleteListAfterProcessTag:VarTagRec=(
                 Tag:'DELETELISTAFTERPROCESS';
                 Flag:_flgSingle);
DestPointListNameTag:VarTagRec=(
                 Tag:'DESTPOINTLIST';
                 Flag:_flgSingle);
PointListNameTag:VarTagRec=(
                 Tag:'POINTLIST';
                 {$IFNDEF SPLE}
                 Flag:_flgCollection
                 {$ELSE}
                 Flag:_flgSingle
                 {$ENDIF}
                 );
CommentsBeforeBossTag:VarTagRec=(
                 Tag:'COMMENTSBEFOREBOSS';
                 Flag:_flgSingle);
AddSemicolonAfterEachBossTag:VarTagRec=(
                 Tag:'ADDSEMICOLONAFTEREACH';
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
CrcTag:VarTagRec=(
                 Tag:'CRC';
                 Flag:_flgSingle);
DayOfYearTag:VarTagRec=(
                 Tag:'DOY';
                 Flag:_flgSingle);
DomainTag:VarTagRec=(
                 Tag:'DOMAIN';
                 Flag:_flgSingle);
YearTag:VarTagRec=(
                 Tag:'YEAR';
                 Flag:_flgSingle);
MonthTag:VarTagRec=(
                 Tag:'MONTH';
                 Flag:_flgSingle);
DayTag:VarTagRec=(
                 Tag:'DAY';
                 Flag:_flgSingle);
MonthNameTag:VarTagRec=(
                 Tag:'MONTH_NAME';
                 Flag:_flgSingle);
PhoneMaskTag:VarTagRec=(
                 Tag:'PHONEMASK';
                 Flag:_flgCollection);
SpeedFlagsTag:VarTagRec=(
                 Tag:'SPEEDFLAGS';
                 Flag:_flgCollection);
SystemFlagsTag:VarTagRec=(
                 Tag:'SYSTEMFLAGS';
                 Flag:_flgCollection);
UserFlagsTag:VarTagRec=(
                 Tag:'USERFLAGS';
                 Flag:_flgCollection);
ImpliesFlagstag:VarTagRec=(
                 Tag:'IMPLIESFLAGS';
                 Flag:_flgCollection);
Os_TypeTag:VarTagRec=(
                 Tag:'OS_TYPE';
                 Flag:_flgSingle);
LanguageTag:VarTagRec=(
                 Tag:'LANGUAGE';
                 Flag:_flgSingle);

AllowedCharsTag:VarTagRec=(
                 Tag:'ALLOWEDCHARS';
                 Flag:_flgSingle);
GetExcludeFromNodelistTag:VarTagRec=(
                 Tag:'GETEXCLUDEFROMNODELIST';
                 Flag:_flgCollection);
ExcludeStatusTag:VarTagRec=(
                 Tag:'EXCLUDESTATUS';
                 Flag:_flgSingle);
ExcludeTag:VarTagRec=(
                 Tag:'EXCLUDE';
                 Flag:_flgCollection);
AutoFlagsUpCaseTag:VarTagRec=(
                 Tag:'AUTOFLAGSUPCASE';
                 Flag:_flgSingle);


{$IFNDEF SPLE}
BuildPointListTag:VarTagRec=(
                 Tag:'BUILDPOINTLIST';
                 Flag:_flgSingle);
ProcessMessagesTag:VarTagRec=(
                 Tag:'PROCESSMSG';
                 Flag:_flgSingle);

TaskNumberTag:VarTagRec=(
                 Tag:'TASK';
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

{UsePasswordsTag:VarTagRec=(
                 Tag:'USEPASSWORDS';
                 Flag:_flgSingle);}
{UseBounceTag:VarTagRec=(
                 Tag:'USEBOUNCE';
                 Flag:_flgSingle);}
{UseExcludeTag:VarTagRec=(
                 Tag:'USEEXCLUDE';
                 Flag:_flgSingle);}
AutoCreateSegmentTag:VarTagRec=(
                 Tag:'AUTOCREATESEGMENT';
                 Flag:_flgSingle);
ForceAutoCreateSegmentTag:VarTagRec=(
                 Tag:'FORCEAUTOCREATESEGMENT';
                 Flag:_flgSingle);
AutoUpdateSegmentTag:VarTagRec=(
                 Tag:'AUTOUPDATESEGMENT';
                 Flag:_flgSingle);
AutoCreateSegmentMaskTag:VarTagRec=(
                 Tag:'AUTOCREATESEGMENTMASK';
                 Flag:_flgSingle);
SegZoneTag:VarTagRec=(
                 Tag:'ZONE';
                 Flag:_flgSingle);
SegNetTag:VarTagRec=(
                 Tag:'NET';
                 Flag:_flgSingle);
SegNodeTag:VarTagRec=(
                 Tag:'NODE';
                 FLag:_flgSingle);

MasterAddressTag:VarTagRec=(
                 Tag:'MASTERADDRESS';
                 Flag:_flgSingle);
MasterLogNameTag:VarTagRec=(
                 Tag:'LOG';
                 Flag:_flgSingle);


LogPntStringErrorsTag:VarTagRec=(
                 Tag:'LOGPNTSTRINGERRORS';
                 Flag:_flgSingle);
{LogStringErrorsInSegmentTag:VarTagRec=(
                 Tag:'LOGSTRINGERRORSINSEGMENT';
                 Flag:_flgSingle);}

LogSizeTag:VarTagRec=(
                 Tag:'LOGSIZE';
                 Flag:_flgSingle);
StatFileNameTag:VarTagRec=(
                 Tag:'BINARYSTATFILE';
                 Flag:_flgSingle);
PointSegmentNameTag:VarTagRec=(
                 Tag:'LISTSEGMENT';
                 Flag:_flgCollection);
NetMailPathTag:VarTagRec=(
                 Tag:'NETMAILPATH';
                 Flag:_flgSingle);
CurrentMessageNameTag:VarTagRec=(
                 Tag:'CURMSG';
                 Flag:_flgSingle);
{KillSentTag:VarTagRec=(
                 Tag:'KILLSENT';
                 Flag:_flgSingle);}
SafeMsgModeTag:VarTagRec=(
                 Tag:'SAFEMSGMODE';
                 Flag:_flgSingle);
SplitCharTag:VarTagRec=(
                 Tag:'SPLITCHAR';
                 Flag:_flgSingle);
DeleteCharsTag:VarTagRec=(
                 Tag:'DELETEPOINTCHARS';
                 Flag:_flgSingle);
{StringsToSkipAtBeginOfListTag:VarTagRec=(
                 Tag:'SKIPATBEGINOFLIST';
                 Flag:_flgSingle);}
BusyFlagNameTag:VarTagRec=(
                 Tag:'BUSYFLAG';
                 Flag:_flgSingle);
FileAttachPathTag:VarTagRec=(
                 Tag:'FILEATTACHPATH';
                 Flag:_flgSingle);
ProcessFileAttachTag:VarTagRec=(
                 Tag:'PROCESSFILEATTACH';
                 Flag:_flgSingle);
{ValidateStringTag:VarTagRec=(
                 Tag:'VALIDATESTRING';
                 Flag:_flgSingle);}

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
ErrorPointsTag:VarTagRec=(
                 Tag:'ERRPOINTS';
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
OnListUpdateScriptTag:VarTagRec=(
                 Tag:'ONLISTUPDATESCRIPT';
                 Flag:_flgCollection);
OnMessagesScriptTag:VarTagRec=(
                 Tag:'ONMESSAGESSCRIPT';
                 Flag:_flgCollection);
OnEachMessageBeforeScriptTag:VarTagRec=(
                 Tag:'ONEACHMSGBEFORESCRIPT';
                 Flag:_flgCollection);
OnEachMessageAfterScriptTag:VarTagRec=(
                 Tag:'ONEACHMSGAFTERSCRIPT';
                 Flag:_flgCollection);

MessageSizeTag:VarTagRec=(
                 Tag:'MSGSIZE';
                 Flag:_flgSingle);
LogLevelTag:VarTagRec=(
                 Tag:'LOGLEVEL';
                 Flag:_flgSingle);
AddCommentCharsTag:VarTagRec=(
                 Tag:'ADDCOMMENTCHARS';
                 Flag:_flgSingle);
ErrorLevelTag:VarTagRec=(
                 Tag:'ERRORLEVEL';
                 Flag:_flgSingle);
ProcessedMessageActionTag:VarTagRec=(
                 Tag:'PROCESSEDMSGACTION';
                 Flag:_flgSingle);
ProcessedMessagePathTag:VarTagRec=(
                 Tag:'PROCESSEDMSGPATH';
                 Flag:_flgSingle);
MainPasswordTag:VarTagRec=(
                 Tag:'MAINPASSWORD';
                 Flag:_flgSingle);
ReRouteTag:VarTagRec=(
                 Tag:'RE-ROUTE';
                 Flag:_flgSingle);
{UseReRouteTag:VarTagRec=(
                 Tag:'USEREROUTE';
                 Flag:_flgSingle);}
IgnoreFromNameTag:VarTagRec=(
                 Tag:'IGNOREFROM';
                 Flag:_flgCollection);

{ProtocolFlagsTag:VarTagRec=(
                 Tag:'PROTOCOLFLAGS';
                 Flag:_flgCollection);}

NotifyOnErrorsTag:VarTagRec=(
                 Tag:'NOTIFYONERRORS';
                 Flag:_flgSingle);

MsgAttributesTag:VarTagRec=(
                 Tag:'MSGATTRIB';
                 Flag:_flgSingle);
TimeSliceTag:VarTagRec=(
                 Tag:'TIMESLICE';
                 Flag:_flgSingle);

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
{$ENDIF}
_tplPntListHeader:VarTagRec=(
                      Tag:'LISTHEADER';
                      Flag:_flgSingle);
_tplPntListFooter:VarTagRec=(
                      Tag:'LISTFOOTER';
                      Flag:_flgSingle);

{$IFNDEF SPLE}
_tplBadPassword:VarTagRec=(
                      Tag:'BADPASSWORDTPL';
                      Flag:_flgSingle);
_tplInBounceList:VarTagRec=(
                      Tag:'BOUNCETPL';
                      Flag:_flgSingle);
_tplReRoute:VarTagRec=(
                      Tag:'RE-ROUTETPL';
                      Flag:_flgSingle);
_tplInExcludeList:VarTagRec=(
                      Tag:'EXCLUDETPL';
                      Flag:_flgSingle);
_tplErrorsInSegment:VarTagRec=(
                      Tag:'SEGMENTERRORSTPL';
                      Flag:_flgSingle);
{$ENDIF}
IMPLEMENTATION

Begin
 PntMasterVersion:=BaseVersion+
    {$IFDEF WIN32}
    '[W32]'
    {$ENDIF}
    {$IFDEF OS2}
    '[OS/2]'
    {$ENDIF}
    {$IFDEF LINUX}
    '[LNX]'
    {$ENDIF};

With BinaryMasterVersion Do
  Begin
   Major:=1;
   Minor:=0;
   SubMinor:=4;
   VersionType:=_verAlpha;
   Registered:=True;
  End;
MODE_NOCONSOLE:=False;
DoUpCase:=True;
End.
