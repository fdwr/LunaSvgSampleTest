' 16 color version

' This sprite reader was programmed in QuickBasic so that
' almost any programmer should be able to understand how
' SNES sprites are encoded. Yes its sloppy, yes its slow
' but it also took me two minutes to write. And it gives
' you something to work on. :-)

DEFINT A-Z
COLOR 7, 0
CLS
PRINT "Quick-peice-of-junk SNES Sprite Reader (16 color) v0.01"
PRINT "Programmed by VileWrath 1997 in two minutes."
PRINT
INPUT "FileName: ", f$
OPEN f$ FOR INPUT AS #1: CLOSE #1
OPEN f$ FOR BINARY AS #1
SCREEN 13
'FOR a = 1 TO 14
'PALETTE a - 1, (a * 4) - 4
'NEXT a
OUT &H3C8, 0
FOR a = 0 TO 15
 rgb = a * 4
 OUT &H3C9, rgb
 OUT &H3C9, rgb
 OUT &H3C9, rgb
NEXT a
a& = 1
a$ = " ": x = 0: y = 0
DO WHILE NOT EOF(1)
FOR aa = 1 TO 8
c1 = 0: c2 = 0: c3 = 0: c4 = 0: c5 = 0: c6 = 0: c7 = 0: c8 = 0
GET #1, a&, a$
a = ASC(a$)
IF a AND 128 THEN c1 = c1 + 1
IF a AND 64 THEN c2 = c2 + 1
IF a AND 32 THEN c3 = c3 + 1
IF a AND 16 THEN c4 = c4 + 1
IF a AND 8 THEN c5 = c5 + 1
IF a AND 4 THEN c6 = c6 + 1
IF a AND 2 THEN c7 = c7 + 1
IF a AND 1 THEN c8 = c8 + 1
GET #1, a& + 1, a$
a = ASC(a$)
IF a AND 128 THEN c1 = c1 + 2
IF a AND 64 THEN c2 = c2 + 2
IF a AND 32 THEN c3 = c3 + 2
IF a AND 16 THEN c4 = c4 + 2
IF a AND 8 THEN c5 = c5 + 2
IF a AND 4 THEN c6 = c6 + 2
IF a AND 2 THEN c7 = c7 + 2
IF a AND 1 THEN c8 = c8 + 2
GET #1, a& + 16, a$
a = ASC(a$)
IF a AND 128 THEN c1 = c1 + 4
IF a AND 64 THEN c2 = c2 + 4
IF a AND 32 THEN c3 = c3 + 4
IF a AND 16 THEN c4 = c4 + 4
IF a AND 8 THEN c5 = c5 + 4
IF a AND 4 THEN c6 = c6 + 4
IF a AND 2 THEN c7 = c7 + 4
IF a AND 1 THEN c8 = c8 + 4
GET #1, a& + 17, a$
a = ASC(a$)
IF a AND 128 THEN c1 = c1 + 8
IF a AND 64 THEN c2 = c2 + 8
IF a AND 32 THEN c3 = c3 + 8
IF a AND 16 THEN c4 = c4 + 8
IF a AND 8 THEN c5 = c5 + 8
IF a AND 4 THEN c6 = c6 + 8
IF a AND 2 THEN c7 = c7 + 8
IF a AND 1 THEN c8 = c8 + 8
yaa = y + aa
PSET (x, yaa), c1
PSET (x + 1, yaa), c2
PSET (x + 2, yaa), c3
PSET (x + 3, yaa), c4
PSET (x + 4, yaa), c5
PSET (x + 5, yaa), c6
PSET (x + 6, yaa), c7
PSET (x + 7, yaa), c8
a& = a& + 2
NEXT aa
a& = a& + 16

x = x + 8
IF x >= 128 THEN y = y + 8: x = 0
IF y > 190 THEN
   DO: a$ = INKEY$: LOOP UNTIL a$ <> ""
   IF a$ = CHR$(27) GOTO EndProgram
   WHILE INKEY$ > "": WEND
   x = 0: y = 0
END IF

LOOP

EndProgram:
CLOSE

