DEFINT A-Z

SCREEN 13
VIEW PRINT

maxsnakeindex = 1000: snakelength = 120
REDIM snakestring(0 TO maxsnakeindex - 1, 0 TO 2)

'Intro
COLOR 9
LOCATE 8, 15
PRINT "ÚÄÄÄÄÄÄÄÄÄÄ¿"
PRINT TAB(15); "³          ³"
PRINT TAB(15); "ÀÄÄÄÄÄÄÄÄÄÄÙ"
COLOR 15
LOCATE 9, 16: PRINT "MINI-SNAKE"
PRINT
PRINT
COLOR 7
PRINT TAB(7); "Arrow keys change direction"
PRINT TAB(7); "Plus and minus change length"
PRINT
COLOR 3
PRINT TAB(10); " up           right"
PRINT TAB(10); " down         left"
PRINT TAB(10); "+ longer      - shorter"
COLOR 7
LOCATE 23, 1: PRINT TAB(6); "Press any key to have freedom";
PRINT TAB(6); "and control the snake yourself";

snakey = 55: snakex = 130
DO
 SELECT CASE snakedir
 CASE 0: snakex = snakex + 1: IF snakex >= 208 THEN snakedir = 1
 CASE 1: snakey = snakey + 1: IF snakey >= 80 THEN snakedir = 2
 CASE 2: snakex = snakex - 1: IF snakex <= 111 THEN snakedir = 3
 CASE 3: snakey = snakey - 1: IF snakey <= 55 THEN snakedir = 0
 END SELECT

 GOSUB SnakeDraw

 FOR temp = 1 TO 500: NEXT temp
LOOP UNTIL INKEY$ > ""

'REDIM TitleBitmap(0 TO 766) '90x17
'GET (115, 60)-(204, 76), TitleBitmap(0)

FOR row = 8 TO 10: LOCATE row, 15: PRINT SPACE$(12); : NEXT row
FOR row = 23 TO 24: LOCATE row, 5: PRINT SPACE$(31); : NEXT row

DO
 SELECT CASE INKEY$
 CASE CHR$(0) + "P": IF snakedir <> 3 THEN snakedir = 1
 CASE CHR$(0) + "H": IF snakedir <> 1 THEN snakedir = 3
 CASE CHR$(0) + "K": IF snakedir <> 0 THEN snakedir = 2
 CASE CHR$(0) + "M": IF snakedir <> 2 THEN snakedir = 0
 CASE "+": IF snakelength < 999 THEN snakelength = snakelength + 1
 CASE "-": IF snakelength > 1 THEN snakelength = snakelength - 1: tailshorten = tailshorten + 1
 CASE CHR$(27): EXIT DO
 END SELECT

 GOSUB SnakeMove
 GOSUB SnakeDraw

 'LOCATE 1, 1: PRINT snakedir; TAB(10); snakey; TAB(20); snakex; TAB(30); snakelength; tailshorten;
 'PUT (115, 0), TitleBitmap(0), OR

 FOR temp = 1 TO 500: NEXT temp

LOOP

SCREEN 0
SYSTEM

SnakeMove:
 SELECT CASE snakedir
 CASE 0: snakex = snakex + 1: IF snakex >= 319 THEN GOSUB SnakeDirDecideHorizontal
 CASE 1: snakey = snakey + 1: IF snakey >= 199 THEN GOSUB SnakeDirDecideVertical
 CASE 2: snakex = snakex - 1: IF snakex <= 0 THEN GOSUB SnakeDirDecideHorizontal
 CASE 3: snakey = snakey - 1: IF snakey <= 0 THEN GOSUB SnakeDirDecideVertical
 END SELECT
RETURN

SnakeDirDecideHorizontal:
 IF snakey > 99 THEN snakedir = 3 ELSE snakedir = 1
RETURN

SnakeDirDecideVertical:
 IF snakex > 159 THEN snakedir = 2 ELSE snakedir = 0
RETURN

SnakeDraw:
 snakestring(snakeindex, 0) = snakey
 snakestring(snakeindex, 1) = snakex
 temp = POINT(snakex, snakey)
 IF temp <> 13 THEN snakestring(snakeindex, 2) = temp
 PSET (snakex, snakey), 13
 snakeindextail = (maxsnakeindex + snakeindex - snakelength - tailshorten) MOD maxsnakeindex
 FOR erasetail = 0 TO tailshorten
  PSET (snakestring(snakeindextail, 1), snakestring(snakeindextail, 0)), snakestring(snakeindextail, 2)
  snakeindextail = (snakeindextail + 1) MOD maxsnakeindex
 NEXT erasetail
 IF tailshorten THEN tailshorten = 0
 snakeindex = (snakeindex + 1) MOD maxsnakeindex
RETURN

