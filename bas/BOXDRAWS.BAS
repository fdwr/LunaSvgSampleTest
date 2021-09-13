DEFINT A-Z
DECLARE SUB BOXDRAW2 (Urow, Lcol, Drow, Rcol, Fore, Back, Shadow, BoxChr)
DECLARE SUB BOXDRAW3 (Hite, Wdth, Urow, Lcol, Fore, Back, Titl, Colr, Titl$, Text$)
DECLARE SUB BOXDRAW4 (Urow, Lcol, Drow, Rcol, Fore, Back, Titl, Titl$)
DECLARE SUB BOXDRAW5 (Urow, Lcol, Drow, Rcol, Fore, Back, Side, Titl$)
COLOR 7, 7: CLS
LOCATE , , 0

a# = TIMER ' Before time
FOR this = 2 TO 79
BOXDRAW2 1, 1, 24, this, 10, 3, 1, 32
NEXT this
b# = TIMER ' After time
LOCATE 2, 4: PRINT "Before"; a#; "  After"; b#; "  Difference"; b# - a#
a# = TIMER
FOR this = 2 TO 76
BOXDRAW3 22, this, 1, 1, 10, 3, 6, 10, "BOXDRAW3", ""
NEXT this
b# = TIMER
LOCATE 2, 4: PRINT "Before"; a#, "After"; b#, "Difference"; b# - a#
a# = TIMER
FOR this = 2 TO 80
BOXDRAW4 1, 1, 25, this, 10, 3, 15, "BOXDRAW4"
NEXT this
b# = TIMER
LOCATE 2, 4: PRINT "Before"; a#, "After"; b#, "Difference"; b# - a#
a# = TIMER
FOR this = 2 TO 80
BOXDRAW5 1, 1, 25, this, 10, 3, 511, "BOXDRAW5"
NEXT this
b# = TIMER
LOCATE 2, 4: PRINT "Before"; a#, "After"; b#, "Difference"; b# - a#

SUB BOXDRAW2 (Urow, Lcol, Drow, Rcol, Fore, Back, Shadow, BoxChr)
BoxDrawer:
 boxL = Rcol - Lcol + 1
 BoxH = Drow - Urow + 1
 COLOR Fore, Back
 FOR Hset = 0 TO BoxH - 1: LOCATE Urow + Hset, Lcol: PRINT STRING$(boxL, BoxChr); : NEXT Hset
Shadow:
IF Shadow THEN
 COLOR 0
 FOR Hset = 1 TO BoxH - 1: LOCATE Urow + Hset, Rcol + 1: PRINT "Û"; : NEXT Hset
 LOCATE Urow + BoxH, Lcol + 1: PRINT STRING$(boxL, 219);
END IF
END SUB

SUB BOXDRAW3 (a, b, c, d, e, f, g, h, i$, j$)

COLOR e, f
LOCATE c, d: PRINT "Ú"; STRING$(b, 196); "¿"
FOR Hset% = 1 TO a
LOCATE c + Hset%, d: PRINT "³"; SPACE$(b); "³"
NEXT Hset%
LOCATE c + Hset%, d: PRINT "À"; STRING$(b, 196); "Ù";

COLOR 0, 0
FOR Hset% = 1 TO a + 1
LOCATE c + Hset%, d + b + 2: PRINT "  ";
NEXT Hset%
LOCATE c + Hset%, d + 2: PRINT SPACE$(b + 2);

LOCATE c, d + 1 + (b - LEN(MID$(i$, 1, b))) / 2: COLOR g, f: PRINT LEFT$(i$, b)
COLOR h: LOCATE c + 1, d + 1: ori = 1
FOR rpt = 1 TO INT(LEN(j$) / (b + 1))
LOCATE , d + 1: PRINT MID$(j$, ori, b)
ori = ori + b: NEXT rpt%
END SUB

SUB BOXDRAW4 (Urow, Lcol, Drow, Rcol, Fore, Back, Titl, Titl$)
IF Urow - Drow AND Lcol - Rcol THEN
IF Urow > Drow THEN SWAP Urow, Drow
IF Lcol > Rcol THEN SWAP Lcol, Rcol
COLOR Fore, Back: BoxWidth = Rcol - Lcol + 1

LOCATE Urow, Lcol: PRINT "Ú"; STRING$(BoxWidth - 2, "Ä"); "¿";
FOR Hset = Urow + 1 TO Drow - 1
LOCATE Hset, Lcol: PRINT "³"; STRING$(BoxWidth - 2, " "); "³";
NEXT Hset
LOCATE Drow, Lcol: PRINT "À"; STRING$(BoxWidth - 2, "Ä"); "Ù";

LOCATE Urow, Lcol + (BoxWidth - LEN(MID$(Titl$, 1, BoxWidth - 2))) / 2
COLOR Titl, Back: PRINT MID$(Titl$, 1, BoxWidth - 2);
END IF
END SUB

SUB BOXDRAW5 (Urow, Lcol, Drow, Rcol, Fore, Back, Side, Titl$)

COLOR Fore, Back: BoxWidth = Rcol - Lcol + 1
IF Side AND 256 THEN FOR Vset = Urow + 1 TO Drow - 1: LOCATE Vset, Lcol + 1: PRINT SPACE$(BoxWidth - 2); : NEXT Vset
IF Side AND 1 THEN LOCATE Urow, Lcol: PRINT "Ú";
IF Side AND 2 THEN LOCATE Urow, Rcol: PRINT "¿";
IF Side AND 4 THEN LOCATE Drow, Lcol: PRINT "À";
IF Side AND 8 THEN LOCATE Drow, Rcol: PRINT "Ù";
IF Side AND 16 THEN LOCATE Urow, Lcol + 1: PRINT STRING$(BoxWidth - 2, "Ä");
IF Side AND 32 THEN LOCATE Drow, Lcol + 1: PRINT STRING$(BoxWidth - 2, "Ä");
IF Side AND 64 THEN FOR Vset = Urow + 1 TO Drow - 1: LOCATE Vset, Lcol: PRINT "³"; : NEXT Vset
IF Side AND 128 THEN FOR Vset = Urow + 1 TO Drow - 1: LOCATE Vset, Rcol: PRINT "³"; : NEXT Vset
'IF Side AND 64 THEN FOR Hset = Lcol + 1 TO Rcol - 1: LOCATE Urow, Hset: PRINT "Ä"; : NEXT Hset
'IF Side AND 128 THEN FOR Hset = Lcol + 1 TO Rcol - 1: LOCATE Drow, Hset: PRINT "Ä"; : NEXT Hset

LOCATE Urow, Lcol + (BoxWidth - LEN(MID$(Titl$, 1, BoxWidth))) / 2
PRINT LEFT$(Titl$, BoxWidth);
END SUB

