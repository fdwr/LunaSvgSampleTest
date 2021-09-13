DEFINT A-Z
SCREEN 7

row = 85: col = 110

GOSUB drawScreen

DO
 SELECT CASE INKEY$
 CASE CHR$(27): EXIT DO
 CASE CHR$(0) + "P": IF row < 199 THEN row = row + 1: chng = 1
 CASE CHR$(0) + "H": IF row > 0 THEN row = row - 1: chng = 1
 CASE CHR$(0) + "K": IF col > 0 THEN col = col - 1: chng = 1
 CASE CHR$(0) + "M": IF col < 319 THEN col = col + 1: chng = 1
 CASE CHR$(13): s$ = s$ + "BM" + LTRIM$(STR$(col)) + "," + LTRIM$(STR$(row))
  GOSUB ShowS: lastrow = row: lastcol = col
 CASE " ": s$ = s$ + "M+" + LTRIM$(STR$(col - lastcol)) + ",+" + LTRIM$(STR$(row - lastrow))
  GOSUB ShowS: GOSUB NewSegment: lastrow = row: lastcol = col
 CASE "": s$ = "": GOSUB drawScreen
 CASE CHR$(0) + "S": s$ = "": GOSUB ShowS
 CASE "s", "S"
  OPEN "qmakeltr.dat" FOR APPEND AS #1
  PRINT #1, s$
  CLOSE #1
 CASE CHR$(9)
  SCREEN 0: LOCATE 1, 1: PRINT s$
  WHILE INKEY$ = "": WEND
  GOSUB drawScreen
 END SELECT
 IF chng THEN GOSUB ShowPos: GOSUB PutDot
LOOP
END

ShowPos:
LOCATE 25, 1: PRINT "Row:"; row; "Col:"; col; TAB(40);
RETURN

PutDot:
PSET (oldcol, oldrow), oldcolor
oldcolor = POINT(col, row)
oldrow = row: oldcol = col
PSET (col, row), 15
RETURN

ShowS: LOCATE 1, 1: PRINT LEFT$(RIGHT$(s$, 40) + SPACE$(40), 40); : RETURN

NewSegment: LINE (lastcol, lastrow)-(col, row), 15: RETURN

drawScreen:
SCREEN 7: CLS : FOR a = 110 TO 200 STEP 20: LINE (a, 85)-(a + 19, 114), 7, B: NEXT a
GOSUB ShowS
GOSUB ShowPos
DRAW s$
RETURN

