SCREEN 12: RANDOMIZE TIMER: DEFINT A-Z

Start:
DO UNTIL INP(96) = 1
user$ = INKEY$: GOSUB Decide
LOOP: END

Decide:
SELECT CASE UCASE$(user$)
CASE "": SYSTEM
CASE "": CLS
CASE " ": SLEEP
CASE "P": RETURN Pancaker
CASE "S": RETURN Scanner
CASE "Z": RETURN ZigZag
CASE "R": RETURN Ripples
CASE ELSE: LOCATE 1, 1: PRINT "S-Scanner, Z-ZigZag, P-Pancakes, R-Ripple, ESC-Quit, BACK-Clear Screen"
END SELECT
RETURN

Pancaker: DO
Hspot = RND * 640
Vspot = RND * 480
FOR rpt = 1 TO RND * 50
Colr = RND * 8 + 8
CIRCLE (Hspot, Vspot), rpt, Colr
NEXT rpt
user$ = INKEY$: IF user$ > "" THEN GOSUB Decide
LOOP
GOTO Start

Ripples: DO
Hspot = RND * 640
Vspot = RND * 480
Lcolr = INT(RND * 8): Colr = Lcolr
FOR rpt = -50 TO 50
LINE (320, 240)-(Hspot + rpt, Vspot + V), Colr
IF Vdir = 1 THEN V = V + 1 ELSE V = V - 1
IF V <= -10 THEN Vdir = 1: Colr = Lcolr
IF V >= 10 THEN Vdir = 0: Colr = Lcolr OR 8
NEXT rpt
user$ = INKEY$: IF user$ > "" THEN GOSUB Decide
LOOP
GOTO Start

Scanner: DO
LINE (320, 240)-(RND * 640, RND * 480), RND * 8 + 8
user$ = INKEY$: IF user$ > "" THEN GOSUB Decide
LOOP
GOTO Start

ZigZag: DO
IF Hdir = 0 THEN Hdir = 1
IF Vdir = 0 THEN Vdir = 1
Colr = Colr MOD 16 + 1: x = x + Hdir: y = y + Vdir
IF x <= 0 THEN Hdir = 1 ELSE IF x >= 480 THEN Hdir = -1
IF y <= 0 THEN Vdir = 1 ELSE IF y >= 639 THEN Vdir = -1
PSET (y, x), Colr
user$ = INKEY$: IF user$ > "" THEN GOSUB Decide
LOOP
GOTO Start

