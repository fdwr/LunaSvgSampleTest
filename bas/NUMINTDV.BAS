WIDTH 80, 50

'a = 200
'b = 885
a = 45
b = 200

GetInputs:
LOCATE 1, 1, 0
PRINT SPACE$(80);
PRINT SPACE$(80);
LOCATE 1, 1
LINE INPUT "variable a  (lower):", char$
IF VAL(char$) THEN a = VAL(LEFT$(char$, 5))
LINE INPUT "variable b (higher):", char$
IF VAL(char$) THEN b = VAL(LEFT$(char$, 5))

x = 0  'x coordinate
y = 0  'y coordinate
c = b \ 2'counter (c=0 or c=b\2 ?)
r = 40 'repeat
col = 0'column

PRINT
PRINT " (Count)  (X)     (Y)"
DO
 row = 0
 FOR y = y TO y + r - 1
  LOCATE 5 + row, 1: row = row + 1
  PRINT c; TAB(9); y; TAB(17); x;
  IF col + 25 > 80 THEN col = 0
  PRINT TAB(col + 25); "Û";
  IF col < 55 THEN PRINT TAB(80); " "
  c = c + a
  IF c >= b THEN c = c MOD b: x = x + 1: col = col + 1
  'activate this line for compression instead of expansion
  x = x + 1: col = col + 1
 NEXT y
 SLEEP
 char$ = INKEY$
LOOP UNTIL LEN(char$)
IF char$ = CHR$(13) GOTO GetInputs

WIDTH 80, 25

