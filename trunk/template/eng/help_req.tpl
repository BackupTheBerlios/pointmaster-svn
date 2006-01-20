;
;
#define subj Done %request% request !
#define Origin All clear ?
;#define TearLine %version%
;
                               Hello, %fromfname% !

Your request was successfuly processed:
┌────────────────────────────────────────────────────────────────────────────┐
                             It's simple:

 You can send me your pointlist segment by attaching to message or you can
 send me netmail to %masteraddress% on name %mastername%

 In message body you may write one or more of this (Subj is used for password,
 if you wish to define it, write to %sysopname%):

 %%HELP              - To get this help text
 %%SEGMENT           - To get you pointlist segment
 %%STATISTIC         - To get simple statistic of your messages which was
                      successfuly processed by %mastername%
 Boss,<zone>:<net>/<node>
                    - Not so needed string, it's only define Boss which will
                      be processed (by default, Boss address is taken from me-
                      ssage header). You can't change data of another Boss.
                      If there is no such Boss in pointlist it will be auto-
                      matically added, but if it will not has at least one
                      point it will be automatically deleted.

 %addcommentchars%<new comment>
                    - Your comments in pointlist. If there are no such one they
                      will be added automatically, otherwise they (all) will be
                      deleted from pointlist and new added. There is no limit to
                      amount of strings and they may be in any place of message

 Point,<number>,<station_name>,<location>,<sysop_name>,<phone>,<flags>
                    - If there is no such point in pointlist it'll be automa-
                      tically added, otherwise his data string will be changed
                      to this in condition that it has at least one difference
                      from another one in pointlist. If length of pointstring
                      is more then screen width you may split it by adding to
                      end of string "%splitchar%" (without ") (look at example)
                      Pointstring must not contains bad characters, spaces, du-
                      plicate commas, it must not ends with comma, pointnumber
                      must be in 1..32767.
                                             ! ATTENTION !

                                             ! ВHИМАHИЕ !
                      Проверяется соответствие флагов стандартам, заданным Сис-
                      Опом. Основные правила: не должно быть повторяющихся фла-
                      гов, все флаги, кроме UTxy, должны быть в верхнем регис-
                      тре, не допускаются излишние флаги, уже подразумевающиеся
                      другими флагами (например ZYX и V42B, V32B и V32 etc.)

 %deletepointchars%<number>
                    - Удалить поинта <number> (квадратные скобки не означают,
                      что знак минуса может быть опущен, это просто синтаксис
                      такой :). Если вы хотите удалить больше одного поинта,
                      то нужно указать их номера друг за другом через запятую.
                      Если вы хотите удалить всех поинтов, укажите символ *
                      (это можно использовать для удаления босса из поинтлиста,
                       т.к. боссы без поинтов автоматически выкидываются)


                               Examples:
 ┌───────────────────────────────────────────────────────────────────────────
 │ From: Vasya Pupkin,    777:1998/9999
 │ To:   %mastername%,     %masteraddress%
 │ Subj: PASSWORD
 └───────────────────────────────────────────────────────────────────────────
    Boss,777:1998/9999
    %addcommentchars%New Boss Comment
    Point,123,Vanya,Russia,Ivan_Ivanov,-Unpublished-,9600,MO,V32B,V42B
    %addcommentchars%New Boss Comment
    Point,128,Vanya2,Russia,Ivan_Sidorov,-Unpublished-,9600,MO,V32,V42,V34,%splitchar%
    U,TXX
    %deletepointchars%129,130

 ┌───────────────────────────────────────────────────────────────────────────
 │From: Vasya Pupkin,     777:1998/9999
 │To:   %mastername%,      %masteraddress%
 │Subj:
 └───────────────────────────────────────────────────────────────────────────
    %deletepointchars%128
    %deletepointchars%*
    %%SEGMENT

 ┌───────────────────────────────────────────────────────────────────────────
 │From: Vasya Pupkin,     777:1998/9999
 │To:   %mastername%,      %masteraddress%
 │Subj:
 └───────────────────────────────────────────────────────────────────────────
    %addcommentchars%New Boss Comment
    %addcommentchars%New Boss Comment
    %%STATISTIC

Изменения в поинтлисте производятся сразу, поэтому можно, например,проверить,
что получилось в поинтлисте после ваших строк в письме, указав в конце письма
команду %%SEGMENT (это касается всего, кроме комментариев, они изменяются после
обработки всего письма )

└────────────────────────────────────────────────────────────────────────────┘

With best regards, %mastername%

Processed at [%curtime%] [%curdate%]
