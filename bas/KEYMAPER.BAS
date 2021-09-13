DEFINT A-Z
COLOR 10, 3: CLS : LOCATE , , 0: DEF SEG = &HB800

DO UNTIL INKEY$ = ""
t2 = t: t = INP(96): S = t AND 128: d = (t AND 127) * 2
IF S = 128 THEN POKE d, 177: sign$ = "-" ELSE POKE d, 219: sign$ = "+"
IF t2 = t AND count < 32767 THEN count = count + 1 ELSE count = 0
LOCATE 3, 1: PRINT sign$; d, t, count; "   "
LOOP

