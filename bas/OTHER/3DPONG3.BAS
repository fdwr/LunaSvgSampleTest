'------------------3D Pong---------------
'----------------BY KYLE MAHAN-----------
'Use the mouse to hit the ball...
'YOU CAN CHANGE THE GRAVITY, PADDLE HEIGHT AND WIDTH WITH THE OPTIONS SCREEN.
'THERE ARE ALSO SOME CODES THAT CAN BE TYPED AT THE OPTIONS SCREEN.
'The codes can only be typed one at a time.  The first is THINK PAD.  It will
'give you 100 points for every paddle hit.  The second is CROSSHAIRS.  This
'gives you a cross on the ball.  The third is slope[n].  n can be from 1 to 9
'This changes the paddle's slope depending on the n.
'Declarations
DECLARE SUB OPTIONSMENU ()
DECLARE SUB MouseDriver (Ax%, Bx%, Cx%, Dx%)
DECLARE FUNCTION MouseInit% ()
DECLARE SUB MOUSEPUT (PUTX%, PUTY%)
DECLARE SUB MOUSESTATUS (lb%, rb%, XMOUSE%, YMOUSE%)
DECLARE SUB DRAWTABLE ()
DECLARE SUB DRAWBALL (X!, Y!, Z!, c!)
DECLARE SUB DRAWPADDLE (X!, Y!, c!)
DECLARE SUB LINE3D (X1!, Y1!, Z1!, X2!, Y2!, Z2!)
DIM SHARED MOUSE$, Ax%, Bx%, Cx%, Dx%, lb%, rb%, XMOUSE%, YMOUSE%, PADDLEWIDTH, PADDLEHEIGHT, GRAVITY, BALLSLEFT, SECRET$, CROSSHAIRS, PADDLESLOPE
'--Read Mouse Data
RESTORE
MOUSE$ = SPACE$(57)
FOR i% = 1 TO 57
  READ a$
H$ = CHR$(VAL("&H" + a$))
  MID$(MOUSE$, i%, 1) = H$
NEXT i%
DATA 55,89,E5,8B,5E,0C,8B,07,50,8B,5E,0A,8B,07,50,8B
DATA 5E,08,8B,0F,8B,5E,06,8B,17,5B,58,1E,07,CD,33,53
DATA 8B,5E,0C,89,07,58,8B,5E,0A,89,07,8B,5E,08,89,0F
DATA 8B,5E,06,89,17,5D,CA,08,00

ms% = MouseInit
CLS
SCREEN 12
'-------------Opening Screen
LOCATE 1, 1: PRINT "3D Virtual Pong"
PRINT " by Kyle Mahan"
msglen = LEN("3D Virtual Pong")
DIM a(msglen * 8, 32)
FOR titlex = 0 TO msglen * 8
    FOR titley = 0 TO 32
    a(titlex, titley) = POINT(titlex, titley)
    NEXT titley
NEXT titlex
CLS
FOR titlex = 0 TO msglen * 8
    FOR titley = 0 TO 32
    IF a(titlex, titley) > 0 THEN CIRCLE (titlex * 5, titley * 5), 3, 7: CIRCLE (titlex * 5 + 2, titley * 5 + 2), 3, 15
    a(tilex, tiley) = 0
    NEXT titley
NEXT titlex
PLAY "MBT250cccfg"
'-------------------------------------INITIAL OPTIONS
'CHANGE THESE TO VARY THE GAMES CHALLENGE.  9.5 IS THE DEFAULT VALUE FOR
'NORMAL GRAVITY.  IF YOU CHANGE IT TO 0 THERE IS NO GRAVITY (WHICH IS
'PRETTY COOL).  PADDLE SLOPE IS THE DEGREE OF ANGLE WITH WHICH THE BALL
'BOUNCES OF THE PADDLE.  THIS ALSO VARIES THE WAY THE PADDLE IS DRAWN.
PADDLEHEIGHT = 80
PADDLEWIDTH = 120
GRAVITY = 0
BALLSLEFT = 5    'NUMBER OF LIVES         
PADDLESLOPE = 9  '1 TO 9

'DIMENSIONS OF THE WORLD ARE 640x480x5
WINDOW (320, 240)-(-320, -240)

'--------------------SELECTION SCREEN
'PRINT INITIAL WORDS
COLOR 2
LOCATE 20, 1: PRINT SPC((81 - LEN(" START ")) / 2); " START "
LOCATE 21, 1: PRINT SPC((80 - LEN(" OPTIONS ")) / 2); " OPTIONS "
DO 'CHOOSE START OR OPTIONS
SELECT CASE UCASE$(INKEY$)
    CASE CHR$(0) + "P"
    SELECTION = SELECTION + 1
    IF SELECTION = 2 THEN SELECTION = 0
    CASE CHR$(0) + "H"
    SELECTION = SELECTION - 1
    IF SELECTION = -1 THEN SELECTION = 1
    CASE CHR$(13)
    EXIT DO
END SELECT
'-----------------------WRITE YOUR SELECTION IN WHITE AND SURROUNDED BY > <
IF SELECTION = 0 THEN
COLOR 15
LOCATE 20, 1: PRINT SPC((81 - LEN(" START ")) / 2); ">START<"
COLOR 2
LOCATE 21, 1: PRINT SPC((80 - LEN(" OPTIONS ")) / 2); " OPTIONS "
ELSE
COLOR 2
LOCATE 20, 1: PRINT SPC((81 - LEN(" START ")) / 2); " START "
COLOR 15
LOCATE 21, 1: PRINT SPC((80 - LEN(" OPTIONS ")) / 2); ">OPTIONS<"
END IF
LOOP

SELECT CASE SELECTION
    CASE 1
    CALL OPTIONSMENU
END SELECT
SCOREINCREMENT = 10

IF UCASE$(SECRET$) = "THINK PAD" THEN SCOREINCREMENT = 100
IF UCASE$(SECRET$) = "CROSSHAIRS" THEN CROSSHAIRS = 1
IF LEFT$(UCASE$(SECRET$), 5) = "SLOPE" AND VAL(RIGHT$(UCASE$(SECRET$), 1)) > 0 AND VAL(RIGHT$(UCASE$(SECRET$), 1)) > 0 THEN PADDLESLOPE = VAL(RIGHT$(UCASE$(SECRET$), 1))
COLOR 15
'--------------The Game
SCORE = 0
'Startup values and positions
5 CLS
SCREEN 12
IF BALLSLEFT = 0 THEN GOTO fin
MOUSEPUT 320, 240

DIM BALL(2)
DIM BALLV(2)
'BALL(0) = X, BALL(1) = Y, BALL(2) = Z
DIM P(1)
'P(0) = PADDLE X, P(1) = PADDLE Y
BALL(0) = 0
BALL(1) = 0
BALL(2) = 2.5
BALLV(0) = 0
BALLV(1) = 0
BALLV(2) = .2


'DRAW THE GAME TABLE
DRAWTABLE
'Draw the ball
CALL DRAWBALL(BALL(0), BALL(1), BALL(2), 15)
'Tell Score and lives
LOCATE 1, 1
PRINT "Score: "; SCORE
PRINT "Lives: "; BALLSLEFT
LINE (-321, 241)-(-220, 205), , B
'------The actual game loop
DO
DRAWTABLE
CALL DRAWBALL(BALL(0), BALL(1), BALL(2), 0)
CALL DRAWPADDLE(P(0), P(1), 0)
'Tell Score and lives
LOCATE 1, 1
PRINT "Score: "; SCORE
PRINT "Lives: "; BALLSLEFT
LINE (-321, 241)-(-220, 205), , B
'------Check mouse and move the paddle as needed
MOUSESTATUS lb%, rb%, XMOUSE%, YMOUSE%
P(0) = XMOUSE% - 320
P(1) = 480 - YMOUSE% - 240

'----Update ball position and bounce if needed
BALL(0) = BALL(0) + BALLV(0)
BALL(1) = BALL(1) + BALLV(1)
BALL(2) = BALL(2) + BALLV(2)
BALLV(1) = BALLV(1) - (GRAVITY / 10)
IF BALL(0) > 320 THEN BALLV(0) = -ABS(BALLV(0)): BEEP
IF BALL(0) < -320 THEN BALLV(0) = ABS(BALLV(0)): BEEP
IF BALL(1) > 240 THEN BALLV(1) = -ABS(BALLV(1)): BEEP
IF BALL(1) < -240 THEN BALLV(1) = ABS(BALLV(1)): BEEP
IF BALL(2) > 5 THEN BALLV(2) = -ABS(BALLV(2)): BEEP

'Check the ball to see if it hit the paddle
IF BALL(2) < 1 THEN
SELECT CASE BALL(0)
    CASE P(0) - PADDLEWIDTH / 2 TO P(0) + PADDLEWIDTH / 2
    SELECT CASE BALL(1)
        CASE P(1) - PADDLEHEIGHT / 2 TO P(1) + PADDLEHEIGHT / 2
        BEEP
        BALLV(2) = ABS(BALLV(2))
        BALLV(1) = (BALL(1) - P(1)) / (11 - PADDLESLOPE)
        BALLV(0) = (BALL(0) - P(0)) / (11 - PADDLESLOPE)
        SCORE = SCORE + SCOREINCREMENT
    CASE ELSE
    BALLSLEFT = BALLSLEFT - 1: GOTO 5
    END SELECT
    CASE ELSE
    BALLSLEFT = BALLSLEFT - 1: GOTO 5
END SELECT
END IF

CALL DRAWBALL(BALL(0), BALL(1), BALL(2), 15)
CALL DRAWPADDLE(P(0), P(1), 4)

'delay
FOR i = 1 TO 500: NEXT i

'loop until ESC is pressed
LOOP UNTIL INKEY$ = CHR$(27)

'THIS RANKS YOU!!!  IF YOU QUIT EARLY, IT MULTIPLIES YOUR SCORE BY THE #
'OF LIVES YOU HAD LEFT
fin:
CLS
PRINT "Your final score was: "; SCORE
IF BALLSLEFT > 0 THEN SCORE = SCORE * BALLSLEFT   'IN CASE YOU PRESS ESCAPE BEFORE YOU DIE.
IF SCOREINCREMENT = 10 THEN
SELECT CASE SCORE
    CASE IS < 100
    PRINT "Have you never used a mouse before???"
    CASE 101 TO 200
    PRINT "Needs some work"
    CASE 201 TO 300
    PRINT "Getting there..."
    CASE 301 TO 400
    PRINT "Extreme!!!"
    CASE 401 TO 500
    PRINT "I dub thee a paddle man"
    CASE 501 TO 600
    PRINT "Don't you have anything better to do?"
    CASE IS > 601
    PRINT "Alright!!!  You hacked my code didn't you?!"
END SELECT
ELSE
PRINT "CHEATER!!!"
END IF

SUB DRAWBALL (X, Y, Z, c)
FOR i = 1 TO (6 - Z) * 2
CIRCLE (X / Z, Y / Z), i, c
NEXT i
'---------------------------points
PSET (X / Z, 240 / Z), c
PSET (320 / Z, Y / Z), c
PSET (-320 / Z, Y / Z), c
'Shadow
IF c = 15 THEN
FOR i = 1 TO (6 - Z) * 2
CIRCLE (X / Z, -240 / Z), i, 7, , , .5
NEXT i
ELSE
FOR i = 1 TO (6 - Z) * 2
CIRCLE (X / Z, -240 / Z), i, 0, , , .5
NEXT i
END IF
'PSET (x / Z, -240 / Z), c

'--------------------------crosshairs
IF CROSSHAIRS = 1 THEN
LINE (X / Z, 240 / Z)-(X / Z, -240 / Z), c
LINE (320 / Z, Y / Z)-(-320 / Z, Y / Z), c
END IF
END SUB

SUB DRAWPADDLE (X, Y, c)
LINE (X - PADDLEWIDTH / 2, Y - PADDLEHEIGHT / 2)-(X + PADDLEWIDTH / 2, Y + PADDLEHEIGHT / 2), c, B
drawslope = 1 + PADDLESLOPE / 40
LINE (X - PADDLEWIDTH / 2, Y - PADDLEHEIGHT / 2)-(X / drawslope, Y / drawslope), c
LINE (X + PADDLEWIDTH / 2, Y + PADDLEHEIGHT / 2)-(X / drawslope, Y / drawslope), c
LINE (X - PADDLEWIDTH / 2, Y + PADDLEHEIGHT / 2)-(X / drawslope, Y / drawslope), c
LINE (X + PADDLEWIDTH / 2, Y - PADDLEHEIGHT / 2)-(X / drawslope, Y / drawslope), c

END SUB

SUB DRAWTABLE
'DRAW THE GAME TABLE
LINE3D -320, -240, 1, 320, -240, 1
LINE3D -320, -240, 5, 320, -240, 5
LINE3D -320, -240, 1, -320, -240, 5
LINE3D 320, -240, 1, 320, -240, 5
'PAINT (0, -70), 2, 15
LINE3D -320, -240, 5, -320, 240, 5
LINE3D -320, 240, 5, 320, 240, 5
LINE3D 320, 240, 5, 320, -240, 5
LINE3D -285, 205, 1, -320, 240, 5   'top left
LINE3D 320, 240, 1, 320, 240, 5
'DRAW A GRID
FOR X1 = -320 TO 320 STEP 50
X2 = X1
CALL LINE3D(X1, -240, 1, X2, -240, 5)
NEXT X1
FOR Z1 = 1 TO 5 STEP .5
Z2 = Z1
CALL LINE3D(-320, -240, Z1, 320, -240, Z2)
NEXT Z1

END SUB

SUB LINE3D (X1, Y1, Z1, X2, Y2, Z2)
X1 = X1 / Z1
Y1 = Y1 / Z1
X2 = X2 / Z2
Y2 = Y2 / Z2
LINE (X1, Y1)-(X2, Y2)
END SUB

SUB MouseDriver (Ax%, Bx%, Cx%, Dx%)
  DEF SEG = VARSEG(MOUSE$)
  MOUSE% = SADD(MOUSE$)
  CALL Absolute(Ax%, Bx%, Cx%, Dx%, MOUSE%)
END SUB

FUNCTION MouseInit%
 
  Ax% = 0
  MouseDriver Ax%, 0, 0, 0
 MouseInit% = Ax%

END FUNCTION

SUB MOUSEPUT (PUTX%, PUTY%)
  Ax% = 4
  Cx% = PUTX%
  Dx% = PUTY%
  MouseDriver Ax%, 0, Cx%, Dx%
END SUB

SUB MOUSESTATUS (lb%, rb%, XMOUSE%, YMOUSE%)
  Ax% = 3
  MouseDriver Ax%, Bx%, Cx%, Dx%
  lb% = ((Bx% AND 1) <> 0)
  rb% = ((Bx% AND 2) <> 0)
  XMOUSE% = Cx%
  YMOUSE% = Dx%
END SUB

SUB OPTIONSMENU
CLS
MSELECTION = 1

DO
DRAWING = 1
X = 320
FOR Y = -240 TO 120 STEP 120

'-------------------------PRINT VALUES
LOCATE 4, (80 - LEN("PADDLE HEIGHT = ") + LEN(PADDLEHEIGHT)) / 2
PRINT "PADDLE HEIGHT ="; PADDLEHEIGHT
LOCATE 12, (80 - LEN("PADDLE WIDTH = ") + LEN(PADDLEWIDTH)) / 2
PRINT "PADDLE WIDTH ="; PADDLEWIDTH
LOCATE 20, (80 - LEN("GRAVITY = ") + LEN(GRAVITY)) / 2
PRINT "GRAVITY ="; GRAVITY; "  "
LOCATE 27, (80 - LEN("LIVES = ") + LEN(BALLSLEFT)) / 2
PRINT "LIVES ="; BALLSLEFT


IF MSELECTION = DRAWING THEN c = 15
IF MSELECTION <> DRAWING THEN c = 1
'--------------------------DRAW THE BOXES
IF DRAWING <> 2 THEN
LINE (-X, Y)-(X, Y), c
LINE (-X + 30, Y + 119)-(X - 30, Y + 119), c
LINE (-X + 30, Y + 119)-(-X, Y), c
LINE (X - 30, Y + 119)-(X, Y), c
ELSE   'FOR SOME REASON THE 2ND DRAWING IS MESSED UP IF I DON'T DO THIS
LINE (-X, Y)-(X, Y), c
LINE (-X + 30, Y + 118)-(X - 30, Y + 118), c
LINE (-X + 30, Y + 118)-(-X, Y), c
LINE (X - 30, Y + 118)-(X, Y), c
END IF
'-INCREMENTS
X = X - 30
DRAWING = DRAWING + 1
NEXT Y
'-------------------------KEY INPUT
K$ = INKEY$
SELECT CASE K$
    CASE CHR$(0) + "H"
    MSELECTION = MSELECTION + 1
    IF MSELECTION = 5 THEN MSELECTION = 1
    CASE CHR$(0) + "P"
    MSELECTION = MSELECTION - 1
    IF MSELECTION = 0 THEN MSELECTION = 4
    CASE CHR$(0) + "K"
        SELECT CASE MSELECTION
            CASE 4
            IF PADDLEHEIGHT > 10 THEN PADDLEHEIGHT = PADDLEHEIGHT - 1
            CASE 3
            IF PADDLEWIDTH > 10 THEN PADDLEWIDTH = PADDLEWIDTH - 1
            CASE 2
            IF GRAVITY > 0 THEN GRAVITY = GRAVITY - .5
            CASE 1
            IF BALLSLEFT > 1 THEN BALLSLEFT = BALLSLEFT - 1
        END SELECT
    CASE CHR$(0) + "M"
        SELECT CASE MSELECTION
            CASE 4
            IF PADDLEHEIGHT < 480 THEN PADDLEHEIGHT = PADDLEHEIGHT + 1
            CASE 3
            IF PADDLEWIDTH < 640 THEN PADDLEWIDTH = PADDLEWIDTH + 1
            CASE 2
            GRAVITY = GRAVITY + .5
            CASE 1
            IF BALLSLEFT < 50 THEN BALLSLEFT = BALLSLEFT + 1
        END SELECT
    CASE CHR$(13)
    EXIT DO
    CASE IS <> ""
    SECRET$ = SECRET$ + K$
    END SELECT
LOOP

END SUB

