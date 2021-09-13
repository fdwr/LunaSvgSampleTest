DECLARE FUNCTION prompt% ()
'n# - Note Multiple Constant
't% - Pitch Multiple base
'l% - Note Sound Limit
CONST n# = 1.059463094359296#, t% = 64, l% = 107

DO
 PRINT "Enter Pitch: ";
 WHILE INKEY$ > "": WEND
 x% = prompt: tone# = t%
 IF x% = -1 THEN EXIT DO
 IF x% > l% THEN x% = l%
 PRINT : PRINT 0, tone#
 FOR note% = 1 TO x%
  tone# = n# * tone#
  PRINT note%, tone#
 NEXT note%
 SOUND INT(tone#), 2
LOOP

PRINT : END

FUNCTION prompt%
v = CSRLIN
h = POS(0)
LOCATE , , 1

WHILE NOT done
a$ = INKEY$
IF a$ >= "0" AND a$ <= "9" AND LEN(b$) < 4 THEN
 b$ = b$ + a$
 LOCATE v, h, 1: PRINT b$;
END IF
IF a$ = "" AND b$ > "" THEN
 b$ = LEFT$(b$, LEN(b$) - 1)
 LOCATE v, h: PRINT b$; " "; : LOCATE v, h: PRINT b$;
END IF
IF a$ = "" THEN prompt = -1: done = -1
IF a$ = CHR$(13) THEN WHILE INP(96) = 28: e$ = INKEY$: WEND: IF INP(96) = 156 THEN prompt = VAL(b$): done = -1
WEND

LOCATE , , 0
END FUNCTION