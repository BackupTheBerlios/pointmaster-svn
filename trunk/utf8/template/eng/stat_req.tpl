;
;
#define subj Done %request% request !
#define Origin Use %%HELP for more information
#define statstring │%%statdate%%│    %%addpoints%%    │   %%delpoints%%   │    %%chgpoints%%   │     %%fchgpoints%%     │     %%fdelpoints%%     │    %%errpoints%%       │
;#define TearLine %version%

                            Hello, %fromfname% !

Table of successfuly processed messages:

┌────────┬───────────────────────────────────────────────────────────────┐
│Message │                            Points                             │
│  date  ├─────────┬───────┬────────┬───────────┬───────────┬────────────┤
│        │  Added  │Deleted│Changed │Not changed│Not deleted│ Wrong data │
├────────┼─────────┼───────┼────────┼───────────┼───────────┼────────────┤
#statistic
└────────┴─────────┴───────┴────────┴───────────┴───────────┴────────────┘

With best regards, %mastername%

Processed at [%curtime%] [%curdate%]
