DEFINT A-Z
ON ERROR GOTO ScrErr
Start:
LOCATE 1, 1: PRINT "What screen mode"; TAB(80);
LOCATE 1, 18: LINE INPUT Mode$
IF LEN(Mode$) THEN Mode = VAL(Mode$) ELSE END
SCREEN Mode
'FOR c = 0 TO Mode
' READ l: DATA 15,
'NEXT
IF Mode THEN
 FOR h = 0 TO 255
  LINE (h, 0)-(h, 99), h
 NEXT h
ELSE
 FOR c = 0 TO 15
  COLOR c
  PRINT "лллллллл"
 NEXT c
END IF
c = 1
DO
 OUT &H3C8, c
 OUT &H3C9, INT(RND * 64)
 OUT &H3C9, INT(RND * 64)
 OUT &H3C9, INT(RND * 64)
 K$ = INKEY$
 IF c >= 255 THEN c = 1 ELSE c = c + 1
LOOP UNTIL K$ > ""
IF K$ = CHR$(13) THEN GOTO Start
ON ERROR GOTO 0
END
ScrErr:
PRINT "Quick BASIC does not support that one"
RESUME Start

