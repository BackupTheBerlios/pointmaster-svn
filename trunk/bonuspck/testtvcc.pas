{$X+}
program TestTVCC;

uses Dos, Memory, Objects, Drivers, Views, Menus, Dialogs, App,
     TVCC;

Const
  cmTryTV = 150;
  cmTryTVCC = 151;

type
  TMyApp = object(TTVCCApplication)
    procedure InitStatusLine; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

var
  MyApp: TMyApp;

procedure TMyApp.InitStatusLine;
var R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~ Exit', kbAltX, cmQuit,
      NewStatusKey('~F8~ Try TV Style', kbF8, cmTryTV,
      NewStatusKey('~F9~ Try TVCC Style', kbF9, cmTryTVCC,
      nil))),
    nil)
  ));
end;

FUNCTION MakeTVCCDialog : PTVCCDialog;
var
  Dlg : PTVCCDialog;
  R : TRect;
  Control, HScroll : PView;
  NewButton : PTVCCButton;
  TVCCButton : PTVCCButton;
Begin
  R.Assign(2,1,76,21);
  New(Dlg, Init(R, 'A TVCC Dialog'));

  R.Assign(15,5,27,6);
  Control := New(PInputLine, Init(R, 20));
  Control^.Options := Control^.Options OR ofFramed;
  Dlg^.Insert(Control);

    R.Assign(28,5,31,6);
    Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), 100)));

    R.Assign(3,5,13,6);
    Dlg^.Insert(New(PLabel, Init(R, '~I~nput Box', Control)));

  R.Assign(33,4,44,7);
  Control := New(PCheckboxes, Init(R,
    NewSItem('Box 1',
    NewSItem('Box 2',
    NewSItem('Box 3',Nil)))));
  PCluster(Control)^.SetButtonState($00000001, False);
  Control^.Options := Control^.Options OR ofFramed;
  Dlg^.Insert(Control);

    R.Assign(32,2,43,3);
    Dlg^.Insert(New(PLabel, Init(R, '~T~est Check', Control)));

  R.Assign(49,4,62,6);
  Control := New(PRadiobuttons, Init(R,
    NewSItem('Radio 1',
    NewSItem('Radio 2',Nil))));
  Control^.Options := Control^.Options OR ofFramed;
  Dlg^.Insert(Control);

    R.Assign(48,2,59,3);
    Dlg^.Insert(New(PLabel, Init(R, '~T~est Radio', Control)));

  R.Assign(24,10,25,16);
  Control := New(PScrollbar, Init(R));
  Dlg^.Insert(Control);

  R.Assign(3,10,23,16);
  Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
  Control^.Options := Control^.Options OR ofFramed;
  Dlg^.Insert(Control);

    R.Assign(2,8,12,9);
    Dlg^.Insert(New(PLabel, Init(R, '~T~est List', Control)));

  R.Assign(50,10,61,13);
  Control := New(PMultiCheckboxes, Init(R,
    NewSItem('Box 1',
    NewSItem('Box 2',
    NewSItem('Box 3',Nil))), 2, cfOneBit, ' X'));
  Control^.Options := Control^.Options OR ofFramed;
  Dlg^.Insert(Control);

    R.Assign(49,8,60,9);
    Dlg^.Insert(New(PLabel, Init(R, '~M~ulticheck', Control)));

  { For TVCC style buttons the TTVCCButton object must be used }

  R.Assign(29,15,47,18);
  NewButton := New(PTVCCButton, Init(R, '~D~efault Button', cmOk, bfDefault));
  Dlg^.Insert(NewButton);

  R.Assign(51,15,70,18);
  TVCCButton := New(PTVCCButton, Init(R, '~N~ormal Button', cmCancel, bfNormal));
  Dlg^.Insert(TVCCButton);

  R.Assign(3,2,24,3);
  Control := New(PStaticText, Init(R, ^C'This is a test dialog'));
  Dlg^.Insert(Control);

  Dlg^.SelectNext(False);
  MakeTVCCDialog := Dlg;
end;

FUNCTION MakeTVDialog : PDialog;
var
  Dlg : PDialog;
  R : TRect;
  Control, HScroll : PView;
Begin
  R.Assign(2,1,76,21);
  New(Dlg, Init(R, 'Normal Turbo Vision Gray Dialog'));

  R.Assign(15,5,27,6);
  Control := New(PInputLine, Init(R, 20));
  Control^.Options := Control^.Options OR ofFramed;
  Dlg^.Insert(Control);

    R.Assign(28,5,31,6);
    Dlg^.Insert(New(PHistory, Init(R, PInputline(Control), 100)));

    R.Assign(3,5,13,6);
    Dlg^.Insert(New(PLabel, Init(R, '~I~nput Box', Control)));

  R.Assign(33,4,44,7);
  Control := New(PCheckboxes, Init(R,
    NewSItem('Box 1',
    NewSItem('Box 2',
    NewSItem('Box 3',Nil)))));
  PCluster(Control)^.SetButtonState($00000001, False);
  Control^.Options := Control^.Options OR ofFramed;
  Dlg^.Insert(Control);

    R.Assign(32,2,43,3);
    Dlg^.Insert(New(PLabel, Init(R, '~T~est Check', Control)));

  R.Assign(49,4,62,6);
  Control := New(PRadiobuttons, Init(R,
    NewSItem('Radio 1',
    NewSItem('Radio 2',Nil))));
  Control^.Options := Control^.Options OR ofFramed;
  Dlg^.Insert(Control);

    R.Assign(48,2,59,3);
    Dlg^.Insert(New(PLabel, Init(R, '~T~est Radio', Control)));

  R.Assign(24,10,25,16);
  Control := New(PScrollbar, Init(R));
  Dlg^.Insert(Control);

  R.Assign(3,10,23,16);
  Control := New(PListBox, Init(R, 1, PScrollbar(Control)));
  Control^.Options := Control^.Options OR ofFramed;
  Dlg^.Insert(Control);

    R.Assign(2,8,12,9);
    Dlg^.Insert(New(PLabel, Init(R, '~T~est List', Control)));

  R.Assign(50,10,61,13);
  Control := New(PMultiCheckboxes, Init(R,
    NewSItem('Box 1',
    NewSItem('Box 2',
    NewSItem('Box 3',Nil))), 2, cfOneBit, ' X'));
  Control^.Options := Control^.Options OR ofFramed;
  Dlg^.Insert(Control);

    R.Assign(49,8,60,9);
    Dlg^.Insert(New(PLabel, Init(R, '~M~ulticheck', Control)));

  R.Assign(29,15,47,17);
  Control := New(PButton, Init(R, '~D~efault Button', cmOk, bfDefault));
  Dlg^.Insert(Control);

  R.Assign(51,15,70,17);
  Control := New(PButton, Init(R, '~N~ormal Button', cmCancel, bfNormal));
  Dlg^.Insert(Control);

  R.Assign(3,2,24,3);
  Control := New(PStaticText, Init(R, ^C'This is a test dialog'));
  Dlg^.Insert(Control);

  Dlg^.SelectNext(False);
  MakeTVDialog := Dlg;
end;

procedure TMyApp.HandleEvent(var Event: TEvent);
begin
  inherited HandleEvent(Event);
  Case Event.What of
    evCommand : Case Event.Command of
      cmTryTV : Application^.ExecuteDialog(MakeTVDialog, NIL);
      cmTryTVCC : Application^.ExecuteDialog(MakeTVCCDialog, NIL);
    end;
  end;
end;

begin
  MyApp.Init;
  MyApp.Run;
  MyApp.Done;
end.
