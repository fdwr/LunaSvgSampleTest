DIM ox(100)
DIM oy(100)
DIM oz(100)

DIM nx(100)
DIM ny(100)
DIM nz(100)


'I'm trying to make it so that the objects just rotate instead of orbit
'and rotate.  If you have any suggestions, they'd be appreciated.

CLS
PRINT "******** 3d vector graphics engine ver 1.91 by Jake Billings ********"
PRINT
PRINT "- Use numeric pad to orbit around origin horizontally or vertically."
PRINT "- You can be orbiting both horizontally and vertically simultaneously."
PRINT "- keep pressing the direction to speed up orbitation up to 30 times that"
PRINT "of the slowest speed."
PRINT "- Press s to change settings."
PRINT "- Press r to make a new object with same settings."
PRINT "- Press 5 to stop the object from orbiting."
PRINT "- Press ESC to exit."
PRINT "- Press any key to begin."
PRINT
PRINT "NOTE: the more the object is blinking when it first appears, "
PRINT "the slower it will animate."
FOR c = 1 TO 2 STEP 0
        goon$ = INKEY$
        IF goon$ > "" THEN EXIT FOR
NEXT c

10 CLS
PRINT "1 - Randomly generated object"
PRINT "2 - User defined point coordinates"
INPUT choose

IF choose = 1 THEN
        CLS
        PRINT "Enter max. possible points(minimum of 3)"
        PRINT
        PRINT "NOTE: more points cause animation to slow."
        PRINT "Past 10, major slowdown can occur."
        INPUT maxpoints
END IF
5 IF choose = 2 THEN
        CLS
        PRINT "Enter number of points(minimum of 3)"
        PRINT
        PRINT "NOTE: more points cause animation to slow."
        PRINT "Past 10, major slowdown can occur."
        INPUT maxpoints
        points = maxpoints
        FOR s = 1 TO maxpoints
                PRINT "Enter x coordinate number "; s; "."
                INPUT ox(s)
                PRINT "Enter y coordinate number "; s; "."
                INPUT oy(s)
                PRINT "Enter z coordinate number "; s; "."
                INPUT oz(s)
        NEXT s
END IF

CLS
PRINT
PRINT "0 - Black"
PRINT "1 - Blue"
PRINT "2 - Green"
PRINT "3 - Turquoise"
PRINT "4 - Red"
PRINT "5 - Purple"
PRINT "6 - Brown"
PRINT "7 - Off-White"
PRINT "8 - Gray"
PRINT "9 - Cyan"
PRINT "10 - Light Green"
PRINT "11 - Light Turquoise"
PRINT "12 - Pink"
PRINT "13 - Light Purple"
PRINT "14 - Yellow"
PRINT "15 - White"
PRINT
INPUT "Background color"; bclor
INPUT "Object color"; clor
PRINT
PRINT "NOTE: darker colors tend to blink less"


CLS
SCREEN 12

20 CLS
IF choose = 1 THEN
        RANDOMIZE TIMER
        rndpoints = INT(RND * maxpoints) + 3
        points = rndpoints
        FOR t = 1 TO points
                ox(t) = INT(RND * 200) + 1
                oy(t) = INT(RND * 200) + 1
                oz(t) = INT(RND * 200) + 1
        NEXT t
END IF

rotatex = 1
rotatey = 1
anglex = 0
angley = 0
angchange = .01
originx = 320
originy = 240

PAINT (1, 1), bclor

FOR i = 1 TO 2 STEP 0
        move$ = INKEY$
       
        IF rotatey = 1 OR rotatex = 1 THEN
        FOR d = 1 TO points
                FOR e = 1 TO points
                        LINE (ox(d) + originx, oy(d) + originy)-(ox(e) + originx, oy(e) + originy), bclor
                NEXT e
        NEXT d
        END IF
       
        IF rotatey = 1 THEN
       
                FOR b = 1 TO points
                        nz(b) = oz(b) * COS(angley) - ox(b) * SIN(angley)
                        nx(b) = oz(b) * SIN(angley) + ox(b) * COS(angley)
                        ny(b) = oy(b)
                        ox(b) = nx(b)
                        oy(b) = ny(b)
                        oz(b) = nz(b)
                NEXT b
        END IF
       
       
       
       
 IF rotatex = 1 THEN
      
        FOR b = 1 TO points
                ny(b) = oy(b) * COS(anglex) - oz(b) * SIN(anglex)
                nz(b) = oy(b) * SIN(anglex) + oz(b) * COS(anglex)
                nx(b) = ox(b)
                ox(b) = nx(b)
                oy(b) = ny(b)
                oz(b) = nz(b)
        NEXT b
 END IF
       
       
        FOR f = 1 TO points
                FOR g = 1 TO points
                        LINE (nx(f) + originx, ny(f) + originy)-(nx(g) + originx, ny(g) + originy), clor
                NEXT g
        NEXT f
   
IF move$ = "8" THEN
        anglex = anglex - angchange
        rotatex = 1
END IF
IF move$ = "2" THEN
        anglex = anglex + angchange
        rotatex = 1
END IF
IF move$ = "4" THEN
        angley = angley - angchange
        rotatey = 1
END IF
IF move$ = "6" THEN
        angley = angley + angchange
        rotatey = 1
END IF
IF move$ = "5" THEN
        anglex = 0
        angley = 0
        rotatex = 0
        rotatey = 0
END IF
IF anglex > .3 THEN anglex = .3
IF angley > .3 THEN angley = .3
IF move$ = CHR$(27) THEN END
IF move$ = "s" THEN GOTO 10
IF move$ = "r" THEN
        IF choose = 1 THEN GOTO 20
        IF choose = 2 THEN GOTO 5
END IF
NEXT i

