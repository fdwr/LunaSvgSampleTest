DECLARE SUB MAKENOTE (note%, leng!)
DECLARE FUNCTION PITCH# (note%)
'1.059463094359296#
GOTO LeftRightPlay
DO
 LINE INPUT "Enter Pitch, Length: ", x$
 x$ = LTRIM$(x$)
 IF x$ = "" THEN
  SYSTEM
 ELSE
  n% = VAL(x$)
  s% = INSTR(x$, " "): IF s% = 0 THEN s% = INSTR(x$, ",")
  IF s% THEN FOR t% = s% TO LEN(x$): SELECT CASE MID$(x$, t%, 1): CASE "0" TO "9", ".": l! = VAL(MID$(x$, t%)): EXIT FOR: END SELECT: NEXT t% ELSE l! = 4
  MAKENOTE n%, l!
 END IF
LOOP
LeftRightPlay:
DO
 k$ = INKEY$
 IF k$ = "+" AND t% < 90 THEN t% = t% + 1: SoundOn = -1
 IF k$ = "-" AND t% > 0 THEN t% = t% - 1: SoundOn = -1
 k% = INP(96)
 SELECT CASE k%
 CASE 72, 77: IF t% < 90 THEN t% = t% + 1: SoundOn = -1
 CASE 75, 80: IF t% > 0 THEN t% = t% - 1: SoundOn = -1
 CASE ELSE: IF k% AND 128 THEN SoundOn = 0 ELSE SoundOn = -1
 END SELECT
 LOCATE , 1: PRINT RIGHT$(STR$(t%), 2); "   "; LEFT$(STR$(PITCH#(t%)) + "       ", 10);
 IF SoundOn THEN MAKENOTE t%, .5
LOOP UNTIL k$ = ""
SYSTEM

SUB MAKENOTE (note%, leng!)
IF note% < 0 OR note% > 107 THEN EXIT SUB
freq# = (2 ^ INT(note% / 12)) * 64
FOR n% = 1 TO note% MOD 12
freq# = 1.059463 * freq#
NEXT n%
SOUND INT(freq#), leng!
END SUB

FUNCTION PITCH# (note%)
IF note% < 0 OR note% > 107 THEN EXIT FUNCTION
freq# = (2 ^ INT(note% / 12)) * 64
FOR n% = 1 TO note% MOD 12
freq# = 1.059463 * freq#
NEXT n%
PITCH = freq#
END FUNCTION

