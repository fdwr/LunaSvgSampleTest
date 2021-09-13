'Quick Timer
'Dwayne Robinson
'Created 1996-11-08
'Updated 2001-05-02
DEFINT A-Z
DECLARE SUB WhatToDo (Text$)
DECLARE SUB ShowTime (TimeNum#)

CONST PausedMsg$ = "\FSpace\7=\9Start  \FEnter\7=\9Reset elapsed  \FBkSpc\7=\9Reset total  \FEsc\7=\9Quit"
CONST TimingMsg$ = "\FSpace\7=\9Pause  \FEnter\7=\9Reset elapsed  \FBkSpc\7=\9Reset total  \FEsc\7=\9Quit"

SCREEN 0
CLS
COLOR 15: PRINT "   Elapsed    Base   Total"
WhatToDo "\CQ\Eu\Ai\9c\Dk \Ct\Ei\Am\9e\Dr \F(\9Dwayne Robinson\F)\7, press \FSpace\7 to \9start\7..."

TimeStr$ = "###:##.###  ###:##  ###:##"
Begin# = TIMER
Now# = Begin#
PauseTime# = Now#
Paused = -1
GOTO RecalcTime
DO
    IF NOT Paused THEN Now# = TIMER
RecalcTime:
    Total# = Now# - Begin#
    Elapsed# = Total# - BaseTime#

    key$ = INKEY$
    IF LEN(key$) THEN
        SELECT CASE key$
        CASE " "
            Paused = Paused XOR -1
            IF Paused THEN
                PauseTime# = Now#
                WhatToDo PausedMsg$
            ELSE
                Now# = TIMER
                Begin# = Begin# + (Now# - PauseTime#)
                WhatToDo TimingMsg$
            END IF
            GOTO RecalcTime
        CASE CHR$(8)
            Begin# = Now#
            BaseTime# = 0
            GOTO RecalcTime
        CASE CHR$(13)
            BaseTime# = Total#
            GOTO RecalcTime
        CASE CHR$(27): EXIT DO
        END SELECT
    END IF

    MID$(TimeStr$, 1, 3) = RIGHT$("  " + STR$(INT(Elapsed#) \ 60), 3)
    MID$(TimeStr$, 5, 2) = RIGHT$(STR$((INT(Elapsed#) MOD 60) + 100), 2)
    MID$(TimeStr$, 8, 3) = MID$(STR$(Elapsed# - INT(Elapsed#)) + "000", 3, 3)
    MID$(TimeStr$, 13, 3) = RIGHT$("  " + STR$(INT(BaseTime#) \ 60), 3)
    MID$(TimeStr$, 17, 2) = RIGHT$(STR$((INT(BaseTime#) MOD 60) + 100), 2)
    MID$(TimeStr$, 21, 3) = RIGHT$("  " + STR$(INT(Total#) \ 60), 3)
    MID$(TimeStr$, 25, 2) = RIGHT$(STR$((INT(Total#) MOD 60) + 100), 2)

    LOCATE 2, 1: COLOR 11: PRINT TimeStr$;
LOOP

LOCATE 5, 1

DEFSNG A-Z
SUB ShowTime (TimeNum#)
LOCATE 2, 1: PRINT STR$(TimeNum#); TAB(20);
END SUB

DEFINT A-Z
SUB WhatToDo (Text$)

LOCATE 3, 1
CharPos = 1
TextLen = LEN(Text$)
DO UNTIL CharPos > TextLen
    NextPos = INSTR(CharPos, Text$, "\")
    IF NextPos <= 0 THEN NextPos = TextLen + 1
    PRINT MID$(Text$, CharPos, NextPos - CharPos);
    COLOR VAL("&h0" + MID$(Text$, NextPos + 1, 1))
    CharPos = NextPos + 2
LOOP
PRINT TAB(80);

END SUB

