' 4 color version

' This sprite reader was programmed in QuickBasic so that
' almost any programmer should be able to understand how
' SNES sprites are encoded. Yes its sloppy, yes its slow
' but it also took me two minutes to write. And it gives
' you something to work on. :-)

DEFINT A-Z
COLOR 7, 0
CLS
version$ = "0.01"
PRINT "Quick-peice-of-shit SNES Sprite Reader v" + version$
PRINT "Programmed by VileWrath 1997 in two minutes."
PRINT
INPUT "FileName: ", f$
OPEN f$ FOR BINARY AS #1
SCREEN 13
FOR a% = 1 TO 4
PALETTE a% - 1, a% * 15
NEXT a%
a# = 1
a$ = " ": x% = 1: y% = 1
DO WHILE NOT EOF(1)
FOR aa% = 1 TO 8
c1 = 0: c2 = 0: c3 = 0: c4 = 0: c5 = 0: c6 = 0: c7 = 0: c8 = 0
GET #1, a#, a$
a% = ASC(a$)
IF a% > 128 THEN a% = a% - 128: c1% = c1% + 1
IF a% > 64 THEN a% = a% - 64: c2% = c2% + 1
IF a% > 32 THEN a% = a% - 32: c3% = c3% + 1
IF a% > 16 THEN a% = a% - 16: c4% = c4% + 1
IF a% > 8 THEN a% = a% - 8: c5% = c5% + 1
IF a% > 4 THEN a% = a% - 4: c6% = c6% + 1
IF a% > 2 THEN a% = a% - 2: c7% = c7% + 1
IF a% > 1 THEN a% = a% - 1: c8% = c8% + 1
GET #1, a# + 1, a$
a% = ASC(a$)
IF a% > 128 THEN a% = a% - 128: c1% = c1% + 2
IF a% > 64 THEN a% = a% - 64: c2% = c2% + 2
IF a% > 32 THEN a% = a% - 32: c3% = c3% + 2
IF a% > 16 THEN a% = a% - 16: c4% = c4% + 2
IF a% > 8 THEN a% = a% - 8: c5% = c5% + 2
IF a% > 4 THEN a% = a% - 4: c6% = c6% + 2
IF a% > 2 THEN a% = a% - 2: c7% = c7% + 2
IF a% > 1 THEN a% = a% - 1: c8% = c8% + 2
PSET (x%, y% + aa%), c1%
PSET (x% + 1, y% + aa%), c2%
PSET (x% + 2, y% + aa%), c3%
PSET (x% + 3, y% + aa%), c4%
PSET (x% + 4, y% + aa%), c5%
PSET (x% + 5, y% + aa%), c6%
PSET (x% + 6, y% + aa%), c7%
PSET (x% + 7, y% + aa%), c8%
a# = a# + 2
NEXT aa%

x% = x% + 9
IF x% > 300 THEN y% = y% + 9: x% = 1
IF y% > 190 THEN
        DO
        a$ = INKEY$
        LOOP UNTIL a$ <> ""
        x% = 1: y% = 1
        END IF

LOOP
CLOSE

