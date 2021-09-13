' 16 color version

' This sprite reader was programmed in QuickBasic so that
' almost any programmer should be able to understand how
' SNES sprites are encoded. Yes its sloppy, yes its slow
' but it also took me two minutes to write. And it gives
' you something to work on. :-)

DEFINT A-Z
COLOR 7, 0
CLS
version$ = "0.01"
PRINT "Quick-peice-of-shit SNES Sprite Reader (16 color) v" + version$
PRINT "Programmed by VileWrath 1997 in two minutes."
PRINT
'INPUT "FileName: ", f$
OPEN "allstars.smc" FOR BINARY AS #1
SCREEN 13
'FOR a% = 1 TO 14
'PALETTE a% - 1, (a% * 4) - 4
'NEXT a%
a& = 33'201743
a$ = SPACE$(64): x% = 0: y% = 0
DO WHILE NOT EOF(1)
GET #1, a&, a$
ta = 1
FOR aa = 0 TO 7
c1 = 0: c2 = 0: c3 = 0: c4 = 0: c5 = 0: c6 = 0: c7 = 0: c8 = 0
a% = ASC(MID$(a$, ta, 1))
IF a% AND 128 THEN c1% = c1% OR 1
IF a% AND 64 THEN c2% = c2% OR 1
IF a% AND 32 THEN c3% = c3% OR 1
IF a% AND 16 THEN c4% = c4% OR 1
IF a% AND 8 THEN c5% = c5% OR 1
IF a% AND 4 THEN c6% = c6% OR 1
IF a% AND 2 THEN c7% = c7% OR 1
IF a% AND 1 THEN c8% = c8% OR 1
a% = ASC(MID$(a$, ta + 1, 1))
IF a% AND 128 THEN c1% = c1% OR 2
IF a% AND 64 THEN c2% = c2% OR 2
IF a% AND 32 THEN c3% = c3% OR 2
IF a% AND 16 THEN c4% = c4% OR 2
IF a% AND 8 THEN c5% = c5% OR 2
IF a% AND 4 THEN c6% = c6% OR 2
IF a% AND 2 THEN c7% = c7% OR 2
IF a% AND 1 THEN c8% = c8% OR 2
a% = ASC(MID$(a$, ta + 16, 1))
IF a% AND 128 THEN c1% = c1% OR 4
IF a% AND 64 THEN c2% = c2% OR 4
IF a% AND 32 THEN c3% = c3% OR 4
IF a% AND 16 THEN c4% = c4% OR 4
IF a% AND 8 THEN c5% = c5% OR 4
IF a% AND 4 THEN c6% = c6% OR 4
IF a% AND 2 THEN c7% = c7% OR 4
IF a% AND 1 THEN c8% = c8% OR 4
a% = ASC(MID$(a$, ta + 17, 1))
IF a% AND 128 THEN c1% = c1% OR 8
IF a% AND 64 THEN c2% = c2% OR 8
IF a% AND 32 THEN c3% = c3% OR 8
IF a% AND 16 THEN c4% = c4% OR 8
IF a% AND 8 THEN c5% = c5% OR 8
IF a% AND 4 THEN c6% = c6% OR 8
IF a% AND 2 THEN c7% = c7% OR 8
IF a% AND 1 THEN c8% = c8% OR 8
yaa = y + aa
PSET (x + 0, yaa), c1
PSET (x + 1, yaa), c2
PSET (x + 2, yaa), c3
PSET (x + 3, yaa), c4
PSET (x + 4, yaa), c5
PSET (x + 5, yaa), c6
PSET (x + 6, yaa), c7
PSET (x + 7, yaa), c8
ta = ta + 2
NEXT aa
a& = a& + 32

x = x + 8
IF x > 127 THEN
 y = y + 8: x = 0 '127
 IF y > 190 THEN
  LOCATE 25, 1: PRINT a&;
  DO: c$ = INKEY$: LOOP UNTIL LEN(c$)
  IF c$ = CHR$(27) THEN EXIT DO
  y = 0
 END IF
END IF

LOOP
CLOSE

