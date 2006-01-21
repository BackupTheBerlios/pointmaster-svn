Unit PM_Obj;

INTERFACE

Uses
  Use32,
App,Objects,Views,Dialogs,Drivers,Menus,Memory,HistList,
     {** pm units **}
     Incl,Parser,Dates;

Type
    PMyProgram=^TMyProgram;
    TMyProgram=Object(TProgram)
      Constructor Init;
      Procedure InitScreen;Virtual;
      procedure InitDesktop; virtual;
      procedure InitMenuBar; virtual;
      procedure InitStatusLine; virtual;
      Destructor Done;Virtual;
End;

Type
    PMyApplication=^TMyApplication;
    TMyApplication=Object(TMyProgram)
      Constructor Init;
      Destructor Done; Virtual;
End;

Type
  PProgressBar=^TProgressBar;
{  TProgressBar=Object(TDialog)
    Bar:PStaticText;
    Constructor Init(var Bounds: TRect; ATitle: TTitleStr);
    Procedure DrawSkeleton;
    Destructor Done;virtual;}
   TProgressBar=Object(TStaticText)
    Constructor Init(var Bounds: TRect; AText: String);
    Procedure Draw;virtual;
    Procedure DrawSkeleton;
    Destructor Done;virtual;
End;

Type
  PLogScroller=^TLogScroller;
  TLogScroller=Object(TScroller)
    Log:PStringCollection;
    Constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar:
                     PScrollBar);
    Procedure Draw;virtual;
    Destructor Done;virtual;
End;

Type
  PBackgroundWindow=^TBackgroundWindow;
  TBackgroundWindow=Object(TWindow)
    Constructor Init(var Bounds: TRect; ATitle: TTitleStr; ANumber:
                     Integer);
    Destructor Done;virtual;
End;


Type
  PInfoWindow=^TInfoWindow;
  TInfoWindow=Object(TWindow)
    Constructor Init(var Bounds: TRect; ATitle: TTitleStr; ANumber:
                     Integer);
    Destructor Done;virtual;
End;

Type
  PLogWindow=^TLogWindow;
  TLogWindow=Object(TWindow)
{    LogScroller:PLogScroller;}
    Constructor Init(var Bounds: TRect; ATitle: TTitleStr; ANumber:
                     Integer);
    Destructor Done;virtual;

End;


IMPLEMENTATION
{*** Begin TMyProgram ***}
procedure TMyProgram.InitScreen;
begin
	{ FIXME}
	{ Temp. disabled}
  Exit;	
(*  if Lo(ScreenMode) <> smMono then
  begin
    if ScreenMode and smFont8x8 <> 0 then
      ShadowSize.X := 1 else
      ShadowSize.X := 2;
    ShadowSize.Y := 1;
    ShowMarkers := False;
    if Lo(ScreenMode) = smBW80 then
      AppPalette := apBlackWhite else
      AppPalette := apColor;
  end else
  begin
    ShadowSize.X := 0;
    ShadowSize.Y := 0;
    ShowMarkers := True;
    AppPalette := apMonochrome;
  end; *)
end;

Constructor TMyProgram.Init;
var
  R: TRect;
begin
  Application := @Self;
  InitScreen;
  R.Assign(0, 0, ScreenWidth, ScreenHeight);
  TGroup.Init(R);
  State := sfVisible + sfSelected + sfFocused + sfModal + sfExposed;
  Options := 0;
  Buffer := ScreenBuffer;
  InitDesktop;
  InitStatusLine;
  InitMenuBar;
  if Desktop <> nil then
     Insert(Desktop);
  if StatusLine <> nil then
     Insert(StatusLine);
  if MenuBar <> nil then
     Insert(MenuBar);
end;

destructor TMyProgram.Done;
begin
  if Desktop <> nil then
     Begin
      Dispose(Desktop, Done);
      Desktop:=Nil;
     End;
  if MenuBar <> nil then
     Begin
      Dispose(MenuBar, Done);
      MenuBar:=Nil;
     End;
  if StatusLine <> nil then
     Begin
      Dispose(StatusLine, Done);
      StatusLine:=Nil;
     End;
  Application := nil;
  inherited Done;
end;


procedure TMyProgram.InitDesktop;
var
  R: TRect;
Begin
 If MODE_NOCONSOLE Then
    Desktop:=Nil
 Else
   Begin
    GetExtent(R);
    Inc(R.A.Y);
    Dec(R.B.Y);
    New(Desktop, Init(R));
   End;
End;
procedure TMyProgram.InitMenuBar;
var
  R: TRect;
Begin
 If MODE_NOCONSOLE Then
    MenuBar:=Nil
 Else
   Begin
    GetExtent(R);
    R.B.Y := R.A.Y + 1;
    MenuBar := New(PMenuBar, Init(R, nil));
   End;
End;

procedure TMyProgram.InitStatusLine;
var
  R: TRect;
Begin
 If MODE_NOCONSOLE Then
    StatusLine:=Nil
 Else
   Begin
     GetExtent(R);
     R.A.Y := R.B.Y - 1;
     New(StatusLine, Init(R,
       NewStatusDef(0, $FFFF,
         NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
         StdStatusKeys(nil)), nil)));
   End;
End;
{*** End TMyProgram ***}

{*** Begin TMyApplication ***}
Constructor TMyApplication.Init;
Begin
  InitMemory;
  InitVideo;
  InitEvents;
{***** Отключаем нафиг дурацкий хандлер ошибок из TV *****}
{  InitSysError;}
  InitHistory;
  TMyProgram.Init;
End;

Destructor TMyApplication.Done;
Begin
  TMyProgram.Done;
  DoneHistory;
  DoneSysError;
  DoneEvents;
  DoneVideo;
  DoneMemory;
End;
{*** End TMyApplication ***}

{*** Begin TProgressBar ***}
Constructor TProgressBar.Init;
Begin
      Inherited Init(Bounds,AText);
      DrawSkeleton;
End;

Procedure TProgressBar.DrawSkeleton;
Var
   R:   Trect;
Begin
End;

Procedure TProgressBar.Draw;
Var
   R:   Trect;
Begin
End;

Destructor TProgressBar.Done;
Begin
      Inherited Done;
End;
{*** End TProgressBar ***}

{*** Begin TLogScroller ***}
Constructor TLogScroller.Init(var Bounds: TRect; AHScrollBar, AVScrollBar:
                     PScrollBar);
Begin
 Inherited Init(Bounds,AHScrollBar,AVScrollBar);
 Log:=New(PStringCollection,Init(5,5));
 Log^.Duplicates:=True;
 Log^.Insert(NewStr('┌[BEGIN]─['+GetDateString+']─['+GetTimeString+']─['+PntMasterVersion+']'));
 GrowMode:=gfGrowHiX+gfGrowHiY+gfGrowRel;
 SetLimit(SizeOf(String),Log^.Count);
End;

Procedure TLogScroller.Draw;
var
  color: byte;
  Y, I: Integer;
  B: TDrawBuffer;
begin                            { draw only what's visible }
  Color:= GetColor(1);
  for y:= 0 to Size.Y-1 do
  begin
    MoveChar(B,' ',Color,Size.X);
    I:= Delta.Y+Y;
    if (I < Log^.Count) and (Log^.At(I) <> nil) then
      MoveStr(B, Copy(PString(Log^.At(I))^,Delta.X+1, Size.X), Color);
    WriteLine(0,Y,Size.X,1,B);
  end;
End;

Destructor TLogScroller.Done;
Begin
 Dispose(Log);
 Inherited Done;
End;
{*** End TLogScroller ***}

{*** Begin TBackgroundWindow ***}
Constructor TBackgroundWindow.Init;
Begin
 Inherited Init(Bounds,ATitle,ANumber);
End;

Destructor TBackgroundWindow.Done;
Begin
 Inherited Done;
End;
{*** End TBackgroundWindow ***}

{*** Begin TInfoWindow ***}
Constructor TInfoWindow.Init;
Begin
 Inherited Init(Bounds,ATitle,ANumber);
{ ProgressBar:=New(PProgressBar,Init(ProgressBarRect,'Progress bar'));
 Insert(ProgressBar);}
End;

Destructor TInfoWindow.Done;
Begin
 Inherited Done;
End;
{*** End TInfoWindow ***}

{*** Begin TLogWindow ***}
Constructor TLogWindow.Init;
Begin
 Inherited Init(Bounds,ATitle,ANumber);
End;

Destructor TLogWindow.Done;
Begin
{ Dispose(LogScroller,Done);}
 Inherited Done;
End;
{*** End TLogWindow ***}

Begin
End.
