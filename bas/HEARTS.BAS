DEFINT A-Z
SCREEN 0: CLS
CONST HeartLimit = 10
DIM hearts(0 TO HeartLimit - 1, 0 TO 1) AS INTEGER

LOCATE 13, 31: COLOR 15: PRINT "L ve Your Neighbor";
LOCATE 13, 32: COLOR 12: PRINT "";

RANDOMIZE TIMER
DO
 row = INT(RND * 25) + 1
 col = INT(RND * 80) + 1

 IF row <> 13 OR col > 49 OR col < 30 THEN
  IF hearts(heart, 0) THEN LOCATE hearts(heart, 0), hearts(heart, 1): PRINT " ";

  hearts(heart, 0) = row
  hearts(heart, 1) = col
  COLOR INT(RND * 15) + 1: LOCATE row, col: PRINT "";

  heart = (heart + 1) MOD HeartLimit
 END IF

 user = INP(96)
 IF user = 1 THEN EXIT DO
 IF user = 57 THEN WHILE INP(96) = 57: user$ = INKEY$: WEND
LOOP

