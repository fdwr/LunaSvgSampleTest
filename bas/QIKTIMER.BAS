LOCATE , , 0
PRINT
PRINT "Quick Timer 1.0 - Created by FDR"
PRINT "Tab pauses, Space holds, Enter resets timer, any other key quits"

TimeStartReal! = TIMER: TimeStart! = TimeStartReal!
PRINT "Start Time:"; : GOSUB ShowStartTime
PRINT "Present time: 12345.12  Elapsed time:";
DO
 k$ = INKEY$
 IF LEN(k$) > 0 THEN
  IF k$ = CHR$(13) THEN
   TimeStartReal! = TIMER: TimeStart! = TimeStartReal!: GOSUB ShowStartTime
  ELSEIF k$ = " " THEN
   TimeDif! = TIMER - TimeStart!: LOCATE , 71: PRINT "Pause";
   WHILE INP(96) = 57: k$ = INKEY$: WEND
   TimeStart! = TIMER - TimeDif!: LOCATE , 71: PRINT "       ";
  ELSEIF k$ = CHR$(9) THEN
   TimeDif! = TIMER - TimeStart!: LOCATE , 71: PRINT "Pause";
   DO: k$ = INKEY$: LOOP UNTIL k$ = CHR$(9) OR k$ = " "
   TimeStart! = TIMER - TimeDif!: LOCATE , 71: PRINT "       ";
  ELSE EXIT DO
  END IF
 END IF
 TimeNow! = TIMER
 LOCATE , 36: PRINT STR$(TimeNow!); TAB(45);
 LOCATE , 60: PRINT STR$(TimeNow! - TimeStart!); TAB(70);
LOOP
PRINT
SYSTEM

ShowStartTime:
LOCATE , 12: PRINT STR$(TimeStartReal!); TAB(23);
RETURN

