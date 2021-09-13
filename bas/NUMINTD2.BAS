SCREEN 12

'a = 200
'b = 885
a = 11
b = 50
cs = 22

GetInputs:
LOCATE 1, 1, 0
PRINT SPACE$(80);
PRINT SPACE$(80);
LOCATE 1, 1
LINE INPUT "increment variable  (lower):", char$
IF VAL(char$) THEN a = VAL(LEFT$(char$, 5))
LINE INPUT "limit variable b   (higher):", char$
IF VAL(char$) THEN b = VAL(LEFT$(char$, 5))

SkipInputs:
x = 0  'x coordinate
y = 0  'y coordinate
'c = b \ 2'counter (c=0 or c=b\2 ?)
c = cs
r = 200 'repeat
col = 0'column
LOCATE 20, 1: PRINT "Starting count:"; cs

PRINT
PRINT " (Count)  (X)     (Y)"
WHILE INKEY$ > "": WEND
DO
 row = 0
 f = 1
 FOR y = y TO y + r - 1
  'LOCATE 5 + row, 1: row = row + 1
  'PRINT c; TAB(9); y; TAB(17); x;
  'IF col + 25 > 80 THEN col = 0
  'PRINT TAB(col + 25); "Û";
  'IF col < 55 THEN PRINT TAB(80); " "
  LINE (0, y)-(200, y), f
  IF y = 99 OR y = 100 THEN PSET (201, y), 15
  c = c + a
  IF y = 199 THEN LOCATE 18, 1: PRINT "Final x:"; x
  IF c >= b THEN c = c MOD b: x = x + 1: col = col + 1: f = f + 1: IF f > 15 THEN f = 1
  'activate this line for compression instead of expansion
  x = x + 1: col = col + 1
 NEXT y
 LOCATE 19, 1: PRINT "Final x:"; x
 SLEEP
 char$ = INKEY$
LOOP UNTIL LEN(char$)
IF char$ = CHR$(13) GOTO GetInputs
IF char$ = CHR$(0) + "H" THEN cs = cs + 1: GOTO SkipInputs
IF char$ = CHR$(0) + "P" THEN cs = cs - 1: GOTO SkipInputs

WIDTH 80, 25

