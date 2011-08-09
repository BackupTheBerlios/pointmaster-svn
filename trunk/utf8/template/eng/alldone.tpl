;
;
#define subj Done request !
#define Origin Use %%HELP for more information
;#define TearLine %version%

                              Hello, %fromfname% !

Your request was successefuly processed:
┌───────┐
│Points │
├───────┴─────────────────────────────────────┬────┐
│ Added:                                      │ %addpoints%  │
│ Deleted:                                    │ %delpoints%  │
│ Changed information:                        │ %chgpoints%  │
│ Points you wish to change information but   │    │
│ it hasn't differences from old:             │ %fchgpoints%  │
│ Points you wish to delete but they wasn't   │    │
│ found:                                      │ %fdelpoints%  │
│ Points with wrong datastring:               │ %errpoints%  │
└─────────────────────────────────────────────┴────┘
┌───────┐
│Bosses │
├───────┴─────────────────────────────────────┬────┐
│ Added:                                      │ %addbosses%  │
│ Deleted:                                    │ %delbosses%  │
│ Bosses you wish to delete but they wasn't   │    │
│ found:                                      │ %fdelbosses%  │
└─────────────────────────────────────────────┴────┘

With best regards, %mastername%

Processed at [%curtime%] [%curdate%]
