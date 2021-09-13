'
'
'
'
'
'
'
'
'
'
'
'
'
'
'
'
'
'
DEFINT A-Z
DECLARE FUNCTION boardclear ()
DECLARE FUNCTION north ()
DECLARE FUNCTION south ()
DECLARE FUNCTION east ()
DECLARE FUNCTION west ()
DECLARE SUB addscore (scor, bal)
DECLARE SUB drawpadle (dir)
DECLARE SUB BOINK ()
DECLARE SUB HIT ()
DECLARE SUB serve ()
DECLARE SUB move ()
DECLARE SUB padle ()
DECLARE SUB drawboard ()
DECLARE SUB pause ()
DIM SHARED k(4) AS INTEGER
DIM SHARED bpos(2) AS INTEGER
DIM SHARED dodemo AS INTEGER
DIM SHARED endgame AS INTEGER
DIM SHARED scor AS LONG
DIM SHARED direct AS INTEGER
DIM SHARED speed AS LONG
DIM SHARED qpos AS INTEGER
DIM SHARED balls AS INTEGER
DIM SHARED nospeed AS INTEGER
DIM SHARED serveagain AS INTEGER
CONST TRUE = -1
CONST FALSE = NOT TRUE
SCREEN 0
WIDTH 80, 25
1
COLOR 15, 0
CLS
LOCATE 5, 31
PRINT "C R A C K  O U T !"
LOCATE 7, 29
PRINT "By :  Thomas W. Watson"
LOCATE 9, 18
PRINT "Adapted from the great arcade game BreakOut"
VIEW PRINT 10 TO 25
LOCATE 11
INPUT "  Enter speed of game ( 1 to 3, 1 is easy, 3 is hard )  :  ", gspeed$
speed = VAL(gspeed$)
nospeed = speed
IF speed < 1 OR speed > 3 THEN VIEW PRINT: GOTO 1
SELECT CASE speed
CASE 1
speed = 10000
CASE 2
speed = 8500
CASE 3
speed = 6200
END SELECT
10
PRINT : PRINT
PRINT "  Enter color of 1-point bricks"
PRINT
INPUT "  (Red, Orange, Yellow, Green, Blue, Purple ) :  ", b1$
SELECT CASE UCASE$(b1$)
CASE "R"
k(1) = 4
CASE "RED"
k(1) = 4
CASE "O"
k(1) = 6
CASE "ORANGE"
k(1) = 6
CASE "Y"
k(1) = 14
CASE "YELLOW"
k(1) = 14
CASE "G"
k(1) = 2
CASE "GREEN"
k(1) = 2
CASE "B"
k(1) = 1
CASE "BLUE"
k(1) = 1
CASE "P"
k(1) = 5
CASE "PURPLE"
k(1) = 5
CASE ELSE
GOTO 10
END SELECT
20
PRINT : PRINT
PRINT "  Enter color of 2-point bricks"
PRINT
INPUT "  (Red, Orange, Yellow, Green, Blue, Purple ) :  ", b2$
SELECT CASE UCASE$(b2$)
CASE "R"
k(2) = 4
CASE "RED"
k(2) = 4
CASE "O"
k(2) = 6
CASE "ORANGE"
k(2) = 6
CASE "Y"
k(2) = 14
CASE "YELLOW"
k(2) = 14
CASE "G"
k(2) = 2
CASE "GREEN"
k(2) = 2
CASE "B"
k(2) = 1
CASE "BLUE"
k(2) = 1
CASE "P"
k(2) = 5
CASE "PURPLE"
k(2) = 5
CASE ELSE
GOTO 20
END SELECT
30
PRINT : PRINT
PRINT "  Enter color of 4-point bricks"
PRINT
INPUT "  (Red, Orange, Yellow, Green, Blue, Purple ) :  ", b3$
SELECT CASE UCASE$(b3$)
CASE "R"
k(3) = 4
CASE "RED"
k(3) = 4
CASE "O"
k(3) = 6
CASE "ORANGE"
k(3) = 6
CASE "Y"
k(3) = 14
CASE "YELLOW"
k(3) = 14
CASE "G"
k(3) = 2
CASE "GREEN"
k(3) = 2
CASE "B"
k(3) = 1
CASE "BLUE"
k(3) = 1
CASE "P"
k(3) = 5
CASE "PURPLE"
k(3) = 5
CASE ELSE
GOTO 30
END SELECT
40
PRINT : PRINT
PRINT "  Enter color of 8-point bricks"
PRINT
INPUT "  (Red, Orange, Yellow, Green, Blue, Purple ) :  ", b4$
SELECT CASE UCASE$(b4$)
CASE "R"
k(4) = 4
CASE "RED"
k(4) = 4
CASE "O"
k(4) = 6
CASE "ORANGE"
k(4) = 6
CASE "Y"
k(4) = 14
CASE "YELLOW"
k(4) = 14
CASE "G"
k(4) = 2
CASE "GREEN"
k(4) = 2
CASE "B"
k(4) = 1
CASE "BLUE"
k(4) = 1
CASE "P"
k(4) = 5
CASE "PURPLE"
k(4) = 5
CASE ELSE
GOTO 40
END SELECT
PRINT : PRINT
IF dodemo <> TRUE THEN PRINT "  Use left and right arrow-keys to move left and right and up arrow to serve."
SLEEP
VIEW PRINT
WIDTH 80, 50

drawboard
balls = 3

50

serve
addscore 0, balls

COLOR 15, 0


DO
padle
IF endgame = TRUE THEN GOTO 60
IF serveagain = TRUE THEN EXIT DO
IF boardclear = TRUE THEN GOTO wonthegame
LOOP UNTIL balls = 0

IF balls = 0 AND serveagain = TRUE THEN GOTO 60
IF serveagain = TRUE THEN serveagain = FALSE: LOCATE bpos(1), bpos(2): PRINT " ": GOTO 50

60
SCREEN 0
COLOR 15, 0
CLS
WIDTH 40, 25
LOCATE 12, 13
PRINT "SORRY, YOU LOSE!"
PLAY "t60mbmlo0l2e-dcl8dl2e-l1c"
COLOR 0, 0
END

wonthegame:
FOR i = 1 TO 5
FOR j = 1 TO 15
COLOR 0, j
CLS
SOUND 50 + i * j, 1
NEXT j
NEXT i
COLOR 15, 0
CLS
WIDTH 40, 25
LOCATE 12, 11
PRINT "YOU WIN!  YOU WIN!"
FOR i = 1 TO 15
PLAY "t1000o1l64mncc+dd+eff+gg+aa+b>c>c>c>c<g<g<g<gc"
NEXT i
COLOR 0, 0
END

SUB addscore (score, bal)
LOCATE 2
COLOR 15, 0
scor = scor + score
PRINT USING "                      SCORE :   ######       BALLS :   #"; scor; bal
END SUB

FUNCTION boardclear

boardclear = FALSE

FOR i = 12 TO 23
FOR j = 4 TO 77
SELECT CASE SCREEN(i, j, 0)
CASE 219
EXIT FUNCTION
CASE ELSE
END SELECT
NEXT j
NEXT i

boardclear = TRUE

END FUNCTION

SUB BOINK

i = 200
SOUND i, 1


END SUB

SUB drawboard
COLOR 15, 0
CLS

LOCATE 5
PRINT STRING$(80, 219)

FOR i = 6 TO 45
LOCATE i, 1
PRINT CHR$(219)
LOCATE i, 80
PRINT CHR$(219)
NEXT i

COLOR k(4), 0
LOCATE 12, 4
PRINT STRING$(74, 219)
LOCATE 13, 4
PRINT STRING$(74, 219)
LOCATE 14, 4
PRINT STRING$(74, 219)

COLOR k(3)
LOCATE 15, 4
PRINT STRING$(74, 219)
LOCATE 16, 4
PRINT STRING$(74, 219)
LOCATE 17, 4
PRINT STRING$(74, 219)

COLOR k(2)
LOCATE 18, 4
PRINT STRING$(74, 219)
LOCATE 19, 4
PRINT STRING$(74, 219)
LOCATE 20, 4
PRINT STRING$(74, 219)

COLOR k(1)
LOCATE 21, 4
PRINT STRING$(74, 219)
LOCATE 22, 4
PRINT STRING$(74, 219)
LOCATE 23, 4
PRINT STRING$(74, 219)

drawpadle 100

END SUB

SUB drawpadle (dir)

IF dodemo = TRUE THEN COLOR 15, 0: LOCATE 46: PRINT STRING$(80, 219): EXIT SUB

IF dir = 100 THEN
qpos = 40
ELSEIF dir = 1 AND qpos = 76 THEN
EXIT SUB
ELSEIF dir = -1 AND qpos = 6 THEN
EXIT SUB
ELSEIF dir = 1 THEN
qpos = qpos + 1
ELSEIF dir = -1 THEN
qpos = qpos - 1
ELSE
END IF

COLOR 0, 0
LOCATE 46
PRINT STRING$(80, 32)
COLOR 15, 0
LOCATE 46, qpos - 5
PRINT STRING$(10, 219)

END SUB

FUNCTION east
east = SCREEN(bpos(1), bpos(2) + 1, 1)
END FUNCTION

SUB HIT
FOR i = 1 TO 1
SOUND 100, 1
SOUND 500, 1
NEXT i

END SUB

SUB move
SELECT CASE direct

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
CASE 1

COLOR 15, 0
LOCATE bpos(1) - 1, bpos(2) - 1, 0
PRINT CHR$(219)
LOCATE bpos(1), bpos(2), 0
COLOR 15, 0
PRINT " "
bpos(1) = bpos(1) - 1: bpos(2) = bpos(2) - 1
IF dodemo <> TRUE THEN pause

IF bpos(1) = 6 AND bpos(2) = 2 THEN direct = 4: HIT: EXIT SUB
IF bpos(1) = 6 THEN
direct = 2
HIT
EXIT SUB
ELSEIF bpos(2) = 2 THEN
direct = 3
HIT
EXIT SUB
END IF

SELECT CASE north

CASE k(1)
COLOR 0, 0: LOCATE bpos(1) - 1, bpos(2) - 1: PRINT "   "
addscore 1, balls
direct = 2
BOINK

CASE k(2)
COLOR 0, 0: LOCATE bpos(1) - 1, bpos(2) - 1: PRINT "   "
addscore 2, balls
direct = 2
BOINK

CASE k(3)
COLOR 0, 0: LOCATE bpos(1) - 1, bpos(2) - 1: PRINT "   "
addscore 4, balls
direct = 2
BOINK

CASE k(4)
COLOR 0, 0: LOCATE bpos(1) - 1, bpos(2) - 1: PRINT "   "
addscore 8, balls
direct = 2
BOINK
END SELECT

SELECT CASE west

CASE k(1)
COLOR 0, 0: LOCATE bpos(1), bpos(2) - 1: PRINT "   "
addscore 1, balls
direct = 3
BOINK

CASE k(2)
COLOR 0, 0: LOCATE bpos(1), bpos(2) - 1: PRINT "   "
addscore 2, balls
direct = 3
BOINK

CASE k(3)
COLOR 0, 0: LOCATE bpos(1), bpos(2) - 1: PRINT "   "
addscore 4, balls
direct = 3
BOINK

CASE k(4)
COLOR 0, 0: LOCATE bpos(1), bpos(2) - 1: PRINT "   "
addscore 8, balls
direct = 3
BOINK
END SELECT

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
CASE 2

COLOR 15, 0
LOCATE bpos(1) + 1, bpos(2) - 1, 0
PRINT CHR$(219)
LOCATE bpos(1), bpos(2), 0
COLOR 15, 0
PRINT " "
bpos(1) = bpos(1) + 1: bpos(2) = bpos(2) - 1
IF dodemo <> TRUE THEN pause
IF dodemo = TRUE THEN GOTO 66

IF bpos(1) = 45 AND bpos(2) = 2 AND south = 15 THEN direct = 3: HIT: EXIT SUB

IF bpos(1) = 45 AND south = 15 THEN
direct = 1
HIT
GOTO 70
ELSEIF bpos(1) = 45 AND south = 0 THEN
balls = balls - 1: serveagain = TRUE: EXIT SUB
ELSEIF bpos(2) = 2 THEN
direct = 4
HIT
END IF

66
SELECT CASE south

CASE k(1)
COLOR 0, 0: LOCATE bpos(1) + 1, bpos(2): PRINT "   "
addscore 1, balls
direct = 1
BOINK

CASE k(2)
COLOR 0, 0: LOCATE bpos(1) + 1, bpos(2): PRINT "   "
addscore 2, balls
direct = 1
BOINK

CASE k(3)
COLOR 0, 0: LOCATE bpos(1) + 1, bpos(2): PRINT "   "
addscore 4, balls
direct = 1
BOINK

CASE k(4)
COLOR 0, 0: LOCATE bpos(1) + 1, bpos(2): PRINT "   "
addscore 8, balls
direct = 1
BOINK

CASE ELSE
END SELECT

SELECT CASE west

CASE k(1)
COLOR 0, 0: LOCATE bpos(1), bpos(2) - 3: PRINT "   "
addscore 1, balls
direct = 4
BOINK

CASE k(2)
COLOR 0, 0: LOCATE bpos(1), bpos(2) - 3: PRINT "   "
addscore 2, balls
direct = 4
BOINK

CASE k(3)
COLOR 0, 0: LOCATE bpos(1), bpos(2) - 3: PRINT "   "
addscore 4, balls
direct = 4
BOINK

CASE k(4)
COLOR 0, 0: LOCATE bpos(1), bpos(2) - 3: PRINT "   "
addscore 8, balls
direct = 4
BOINK
END SELECT

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
CASE 3

COLOR 15, 0
LOCATE bpos(1) - 1, bpos(2) + 1, 0
PRINT CHR$(219)
LOCATE bpos(1), bpos(2), 0
COLOR 15, 0
PRINT " "
bpos(1) = bpos(1) - 1: bpos(2) = bpos(2) + 1
IF dodemo <> TRUE THEN pause

IF bpos(1) = 6 AND bpos(2) = 79 THEN direct = 2: HIT: EXIT SUB
IF bpos(1) = 6 THEN
direct = 4
HIT
EXIT SUB
ELSEIF bpos(2) = 79 THEN
direct = 1
HIT
EXIT SUB
END IF

SELECT CASE north

CASE k(1)
COLOR 0, 0: LOCATE bpos(1) - 1, bpos(2) - 1: PRINT "   "
addscore 1, balls
direct = 4
BOINK

CASE k(2)
COLOR 0, 0: LOCATE bpos(1) - 1, bpos(2) - 1: PRINT "   "
addscore 2, balls
direct = 4
BOINK

CASE k(3)
COLOR 0, 0: LOCATE bpos(1) - 1, bpos(2) - 1: PRINT "   "
addscore 4, balls
direct = 4
BOINK

CASE k(4)
COLOR 0, 0: LOCATE bpos(1) - 1, bpos(2) - 1: PRINT "   "
addscore 8, balls
direct = 4
BOINK

CASE ELSE
END SELECT

SELECT CASE east

CASE k(1)
COLOR 0, 0: LOCATE bpos(1), bpos(2) + 1: PRINT "   "
addscore 1, balls
direct = 1
BOINK

CASE k(2)
COLOR 0, 0: LOCATE bpos(1), bpos(2) + 1: PRINT "   "
addscore 2, balls
direct = 1
BOINK

CASE k(3)
COLOR 0, 0: LOCATE bpos(1), bpos(2) + 1: PRINT "   "
addscore 4, balls
direct = 1
BOINK

CASE k(4)
COLOR 0, 0: LOCATE bpos(1), bpos(2) + 1: PRINT "   "
addscore 8, balls
direct = 1
BOINK
END SELECT

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
CASE 4

COLOR 15, 0
LOCATE bpos(1) + 1, bpos(2) + 1, 0
PRINT CHR$(219)
LOCATE bpos(1), bpos(2), 0
COLOR 15, 0
PRINT " "
bpos(1) = bpos(1) + 1: bpos(2) = bpos(2) + 1
IF dodemo <> TRUE THEN pause
IF dodemo = TRUE THEN GOTO 70

IF bpos(1) = 45 AND bpos(2) = 79 AND south = 15 THEN direct = 1: HIT: EXIT SUB

IF bpos(1) = 45 AND south = 15 THEN
direct = 3
HIT
GOTO 70
ELSEIF bpos(1) = 45 AND south = 0 THEN
balls = balls - 1: serveagain = TRUE: EXIT SUB
ELSEIF bpos(2) = 79 THEN
direct = 2
HIT
END IF

70

SELECT CASE south

CASE k(1)
COLOR 0, 0: LOCATE bpos(1) + 1, bpos(2) - 1: PRINT "   "
addscore 1, balls
direct = 3
BOINK

CASE k(2)
COLOR 0, 0: LOCATE bpos(1) + 1, bpos(2) - 1: PRINT "   "
addscore 2, balls
direct = 3
BOINK

CASE k(3)
COLOR 0, 0: LOCATE bpos(1) + 1, bpos(2) - 1: PRINT "   "
addscore 4, balls
direct = 3
BOINK

CASE k(4)
COLOR 0, 0: LOCATE bpos(1) + 1, bpos(2) - 1: PRINT "   "
addscore 8, balls
direct = 3
BOINK

CASE ELSE
END SELECT

SELECT CASE east

CASE k(1)
COLOR 0, 0: LOCATE bpos(1), bpos(2) + 1: PRINT "   "
addscore 1, balls
direct = 4
BOINK

CASE k(2)
COLOR 0, 0: LOCATE bpos(1), bpos(2) + 1: PRINT "   "
addscore 2, balls
direct = 4
BOINK

CASE k(3)
COLOR 0, 0: LOCATE bpos(1), bpos(2) + 1: PRINT "   "
addscore 4, balls
direct = 4
BOINK

CASE k(4)
COLOR 0, 0: LOCATE bpos(1), bpos(2) + 1: PRINT "   "
addscore 8, balls
direct = 4
BOINK
END SELECT

END SELECT
END SUB

FUNCTION north
north = SCREEN(bpos(1) - 1, bpos(2), 1)
END FUNCTION

SUB padle

IF dodemo = TRUE THEN GOTO 65

j$ = INKEY$
IF j$ = CHR$(27) THEN endgame = TRUE: EXIT SUB
IF j$ = CHR$(0) + "M" THEN drawpadle 1: EXIT SUB
IF j$ = CHR$(0) + "K" THEN drawpadle -1: EXIT SUB

65
COLOR 15, 0
move
END SUB

SUB pause
FOR a& = 1 TO speed: NEXT a&
END SUB

SUB serve
IF dodemo = TRUE THEN
bpos(1) = 42
bpos(2) = 40
direct = 1
END IF

IF dodemo = TRUE THEN GOTO 67

DO: j$ = INKEY$: LOOP UNTIL j$ = CHR$(0) + "H"
bpos(1) = 42
bpos(2) = 40
IF qpos <= 40 THEN
direct = 1
ELSEIF qpos >= 41 THEN direct = 3
END IF

67
LOCATE bpos(1), bpos(2), 0
COLOR 15, 0
PRINT CHR$(219)
END SUB

FUNCTION south
south = SCREEN(bpos(1) + 1, bpos(2), 1)
END FUNCTION

FUNCTION west
west = SCREEN(bpos(1), bpos(2) - 1, 1)
END FUNCTION

