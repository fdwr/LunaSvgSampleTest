' To run this game, press Shift+F5.
'
' To exit QBasic, press Alt, F, X.

'Sets default data type to integer for faster game play
DEFINT A-Z

'User-defined TYPEs
TYPE snakeBody
 Row AS INTEGER
 Col AS INTEGER
END TYPE

'This type defines the player's snake
TYPE snaketype
 head      AS INTEGER
 length    AS INTEGER
 Row       AS INTEGER
 Col       AS INTEGER
 direction AS INTEGER
 lives     AS INTEGER
 score     AS INTEGER
 scolor    AS INTEGER
 alive     AS INTEGER
END TYPE

'Stores the current color of each point
TYPE arenaType
 acolor      AS INTEGER
END TYPE

'Sub Declarations
DECLARE SUB MessagePause (text$)
DECLARE SUB PrintScore (NumPlayers%, score1%, score2%, lives1%, lives2%)
DECLARE SUB Intro ()
DECLARE SUB GetInputs (NumPlayers, speed, diff$)
DECLARE SUB DrawScreen ()
DECLARE SUB PlayNibbles (NumPlayers, speed, diff$)
DECLARE SUB SetPixel (Row, Col, acolor)
DECLARE SUB ShowPixel (Row, Col)
DECLARE SUB Center (Row, text$)
DECLARE SUB DoIntro ()
DECLARE SUB Initialize ()
DECLARE SUB SparklePause ()
DECLARE SUB Level (WhatToDO, sammy() AS snaketype)
DECLARE SUB InitColors ()
DECLARE SUB EraseSnake (snake() AS ANY, snakeBod() AS ANY, snakeNum%)
DECLARE FUNCTION StillWantsToPlay ()
DECLARE FUNCTION PointIsThere (Row, Col, backColor)

'Constants
CONST TRUE = -1
CONST FALSE = NOT TRUE
CONST MAXSNAKELENGTH = 1000
CONST STARTOVER = 1             ' Parameters to 'Level' SUB
CONST SAMELEVEL = 2
CONST NEXTLEVEL = 3

'Global Variables
DIM SHARED arena(1 TO 50, 1 TO 80) AS arenaType
DIM SHARED curLevel, ColorTable(10)

 RANDOMIZE TIMER
 GOSUB ClearKeyLocks
 GOSUB SetColors
 DrawScreen
 Intro
 GetInputs NumPlayers, speed, diff$

 DO
  PlayNibbles NumPlayers, speed, diff$
 LOOP WHILE StillWantsToPlay

 WIDTH 80, 25
 COLOR 15, 0
 CLS
END

ClearKeyLocks:         ' Turn off CapLock, NumLock and ScrollLock
 DEF SEG = 0
 POKE 1047, &H0
 DEF SEG
 RETURN

SetColors:
 RESTORE SetColors
 FOR a = 1 TO 7
  READ ColorTable(a)
 NEXT a
     'snake1  snake2   Walls  Background  Dialogs Fore  Back  Number
 DATA 14,     13,      12,     1,          15,           7,   15
 RETURN

END

'  Centers text on given row
SUB Center (Row, text$)
    LOCATE Row, 41 - LEN(text$) \ 2
    PRINT text$;
END SUB

'  Sets screen mode for playing field
SUB DrawScreen

 'initialize screen
 SCREEN 0
 VIEW PRINT
 WIDTH 80, 50

END SUB

'  Erases snake to facilitate moving through playing field
SUB EraseSnake (snake() AS snaketype, snakeBod() AS snakeBody, snakeNum)

 FOR c = 0 TO 9
  FOR b = snake(snakeNum).length - c TO 0 STEP -10
   tail = (snake(snakeNum).head + MAXSNAKELENGTH - b) MOD MAXSNAKELENGTH
   SetPixel snakeBod(tail, snakeNum).Row, snakeBod(tail, snakeNum).Col, ColorTable(4)
  NEXT b
 NEXT c
    
END SUB

'  Gets player inputs
SUB GetInputs (NumPlayers, speed, diff$)

 COLOR 15, 0: CLS
 COLOR 0, 15
 Center 35, "ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ"
 Center 36, "    General    €  Sammy   Jamie  "
 Center 37, "ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ€ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ"
 Center 38, " Space - Pause €           W    "
 Center 39, "               €         A S   "
 Center 40, "   Esc - Menu  €           D    "
 Center 41, "‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹"
 COLOR 15, 0

 LOCATE 15, 27, 1
 PRINT "How many players (1 or 2) 1";
 DO
  num$ = INKEY$
 LOOP UNTIL VAL(num$) = 1 OR VAL(num$) = 2 OR num$ = CHR$(13)
 IF num$ = CHR$(13) THEN NumPlayers = 1 ELSE NumPlayers = VAL(num$)
 LOCATE , 52, 0: PRINT NumPlayers;

 LOCATE 17, 28: PRINT "Skill level (1 to 100)"
 Center 18, "1   = Just Hatched "
 Center 19, "50  = Pretty Good  "
 Center 20, "80  = Natural Snake"
 Center 21, "100 = Mad Serpent  "
 DO
  LOCATE 17, 51: PRINT SPACE$(28);
  LOCATE 17, 51
  INPUT "", gamespeed$
 LOOP UNTIL VAL(gamespeed$) >= 1 AND VAL(gamespeed$) <= 100 OR gamespeed$ = ""
 IF gamespeed$ = "" THEN speed = 20 ELSE speed = VAL(gamespeed$)
 LOCATE 17, 50: PRINT STR$(speed);

 speed = (100 - speed) * 2 + 1

 LOCATE 23, 18, 1
 PRINT "Increase game speed during play (Y or N) N";
 DO
  diff$ = UCASE$(INKEY$)
 LOOP UNTIL diff$ = "Y" OR diff$ = "N" OR diff$ = CHR$(13)
 IF diff$ = CHR$(13) THEN diff$ = "N"
 LOCATE , 59, 0: PRINT diff$;

 startTime# = TIMER                          ' Calculate speed of system
 FOR i# = 1 TO 1000: NEXT i#                 ' and do some compensation
 stopTime# = TIMER
 speed = speed * .5 / (stopTime# - startTime#)

END SUB

'  Initializes playing field colors
SUB InitColors
    
    FOR Row = 1 TO 50
        FOR Col = 1 TO 80
            arena(Row, Col).acolor = ColorTable(4)
        NEXT Col
    NEXT Row

    COLOR , ColorTable(4): CLS
   
    'Set (turn on) pixels for screen border
    FOR Col = 1 TO 80
        SetPixel 3, Col, ColorTable(3)
        SetPixel 50, Col, ColorTable(3)
    NEXT Col

    FOR Row = 4 TO 49
        SetPixel Row, 1, ColorTable(3)
        SetPixel Row, 80, ColorTable(3)
    NEXT Row

END SUB

'  Displays game introduction
SUB Intro
 
 WIDTH 80, 25
 COLOR 15, 0
 CLS

 COLOR 14
 Center 4, "‹ﬂﬂﬂﬂ ‹ﬂﬂﬂ‹ ‹ﬂ‹ﬂ‹ ‹ﬂ‹ﬂ‹ € € "
 Center 5, " ﬂﬂﬂ‹ €ﬂﬂﬂ€ € € € € € € ﬂ‹ﬂ  "
 Center 6, "ﬂﬂﬂﬂ  ﬂ   ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ ﬂ  ﬂ   "
 COLOR 15
 Center 7, "AND "
 COLOR 13
 Center 8, "‹‹‹‹‹  ‹‹‹   ‹ ‹  ‹‹‹ ‹‹‹‹‹ "
 Center 9, "    € €‹‹‹€ € € €  €  €‹‹‹‹ "
 Center 10, "‹‹‹‹ﬂ €   € € € € ‹€‹ €‹‹‹‹ "

 COLOR 7
 Center 12, "Based on Microsoft Nibbles (C) 1990"
 Center 15, "Sammy is a game for one or two players. Navigate your snakes around the"
 Center 16, "obstacle course trying to eat up all the numbers while avoiding running"
 Center 17, "into walls, other snakes, or yourself. With each number your snake eats,"
 Center 18, "it gets gets longer, making it harder to control. When you get all nine,"
 Center 19, "a hole will appear that you must go down to get to the next level..."

 Center 24, "Press any key to continue"

 PLAY "MBT160O1L8CDEDCDL4ECC"
 SparklePause
 DrawScreen

END SUB

'Sets game level
SUB Level (WhatToDO, sammy() AS snaketype) STATIC
    
 SELECT CASE (WhatToDO)
  CASE STARTOVER: curLevel = 1
  CASE NEXTLEVEL: curLevel = curLevel + 1
 END SELECT

 sammy(1).head = 1                       'Initialize Snakes
 sammy(1).length = 2
 sammy(1).alive = TRUE
 sammy(2).head = 1
 sammy(2).length = 2
 sammy(2).alive = TRUE

 InitColors
    
 SELECT CASE curLevel
 CASE 1
  sammy(1).Row = 25: sammy(2).Row = 25
  sammy(1).Col = 50: sammy(2).Col = 30
  sammy(1).direction = 4: sammy(2).direction = 3

 CASE 2
  FOR i = 20 TO 60
   SetPixel 25, i, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 60: sammy(2).Col = 20
  sammy(1).direction = 3: sammy(2).direction = 4

 CASE 3
  FOR i = 10 TO 40
   SetPixel i, 20, ColorTable(3)
   SetPixel i, 60, ColorTable(3)
  NEXT i
  sammy(1).Row = 25: sammy(2).Row = 25
  sammy(1).Col = 50: sammy(2).Col = 30
  sammy(1).direction = 1: sammy(2).direction = 2

 CASE 4
  FOR i = 4 TO 30
   SetPixel i, 20, ColorTable(3)
   SetPixel 53 - i, 60, ColorTable(3)
  NEXT i
  FOR i = 2 TO 40
   SetPixel 38, i, ColorTable(3)
   SetPixel 15, 81 - i, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 60: sammy(2).Col = 20
  sammy(1).direction = 3: sammy(2).direction = 4
   
 CASE 5
  FOR i = 13 TO 39
   SetPixel i, 21, ColorTable(3)
   SetPixel i, 59, ColorTable(3)
  NEXT i
  FOR i = 23 TO 57
   SetPixel 11, i, ColorTable(3)
   SetPixel 41, i, ColorTable(3)
  NEXT i
  sammy(1).Row = 25: sammy(2).Row = 25
  sammy(1).Col = 50: sammy(2).Col = 30
  sammy(1).direction = 1: sammy(2).direction = 2

 CASE 6
  FOR i = 4 TO 49
   IF i > 30 OR i < 23 THEN
    SetPixel i, 10, ColorTable(3)
    SetPixel i, 20, ColorTable(3)
    SetPixel i, 30, ColorTable(3)
    SetPixel i, 40, ColorTable(3)
    SetPixel i, 50, ColorTable(3)
    SetPixel i, 60, ColorTable(3)
    SetPixel i, 70, ColorTable(3)
   END IF
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 65: sammy(2).Col = 15
  sammy(1).direction = 2: sammy(2).direction = 1

 CASE 7
  FOR i = 4 TO 49 STEP 2
   SetPixel i, 40, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 65: sammy(2).Col = 15
  sammy(1).direction = 2: sammy(2).direction = 1

 CASE 8
  FOR i = 4 TO 40
   SetPixel i, 10, ColorTable(3)
   SetPixel 53 - i, 20, ColorTable(3)
   SetPixel i, 30, ColorTable(3)
   SetPixel 53 - i, 40, ColorTable(3)
   SetPixel i, 50, ColorTable(3)
   SetPixel 53 - i, 60, ColorTable(3)
   SetPixel i, 70, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 65: sammy(2).Col = 15
  sammy(1).direction = 2: sammy(2).direction = 1

 CASE 9
  FOR i = 6 TO 47
   SetPixel i, i, ColorTable(3)
   SetPixel i, i + 28, ColorTable(3)
  NEXT i
  sammy(1).Row = 40: sammy(2).Row = 15
  sammy(1).Col = 75: sammy(2).Col = 5
  sammy(1).direction = 1: sammy(2).direction = 2
   
 CASE 10
  FOR i = 1 TO 38
   SetPixel 26, i, ColorTable(3)
   SetPixel 26, 80 - i, ColorTable(3)
  NEXT i
  FOR i = 3 TO 24
   SetPixel i, 40, ColorTable(3)
   SetPixel 52 - i, 40, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 60: sammy(2).Col = 20
  sammy(1).direction = 3: sammy(2).direction = 4
   
 CASE 11
  FOR i = 7 TO 45: SetPixel i, 41, ColorTable(3): NEXT i
   FOR i = 2 TO 39
    SetPixel 26, i, ColorTable(3)
    SetPixel 26, i + 41, ColorTable(3)
   NEXT i
  FOR i = 1 TO 22
   SetPixel 2 + i, 42 - i, ColorTable(3)
   SetPixel 27 + i, 63 - i, ColorTable(3)
   SetPixel 2 + i, 40 + i, ColorTable(3)
   SetPixel 27 + i, 19 + i, ColorTable(3)
  NEXT i
  sammy(1).Row = 5: sammy(2).Row = 48
  sammy(1).Col = 46: sammy(2).Col = 37
  sammy(1).direction = 4: sammy(2).direction = 3

 CASE ELSE
  FOR i = 4 TO 49 STEP 2
   SetPixel i, 10, ColorTable(3)
   SetPixel i + 1, 20, ColorTable(3)
   SetPixel i, 30, ColorTable(3)
   SetPixel i + 1, 40, ColorTable(3)
   SetPixel i, 50, ColorTable(3)
   SetPixel i + 1, 60, ColorTable(3)
   SetPixel i, 70, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 65: sammy(2).Col = 15
  sammy(1).direction = 2: sammy(2).direction = 1

 END SELECT
END SUB

'  Pauses game play and waits for space bar to be pressed before continuing
SUB MessagePause (text$)

 COLOR ColorTable(5), ColorTable(6)
 Center 23, STRING$(24, 219)
 Center 24, "€" + SPACE$(22) + "€"
 Center 25, "€ " + LEFT$(text$ + SPACE$(20), 20) + " €"
 Center 26, "€" + SPACE$(22) + "€"
 Center 27, STRING$(24, 219)
 WHILE INKEY$ <> "": WEND
 DO: kbd$ = INKEY$: LOOP UNTIL kbd$ = " " OR kbd$ = CHR$(13)
 COLOR 15, ColorTable(4)

 FOR Row = 23 TO 27      ' Restore the screen background
  FOR Col = 29 TO 52
   ShowPixel Row, Col
  NEXT Col
 NEXT Row

END SUB

'  Main routine that controls game play
SUB PlayNibbles (NumPlayers, speed, diff$)

 'Initialize Snakes
 DIM sammyBody(MAXSNAKELENGTH - 1, 1 TO 2) AS snakeBody
 DIM sammy(1 TO 2) AS snaketype
 sammy(1).lives = 5
 sammy(1).score = 0
 sammy(1).scolor = ColorTable(1)
 sammy(2).lives = 5
 sammy(2).score = 0
 sammy(2).scolor = ColorTable(2)
                 
 Level STARTOVER, sammy()
 startRow1 = sammy(1).Row: startCol1 = sammy(1).Col
 startRow2 = sammy(2).Row: startCol2 = sammy(2).Col

 CurSpeed = speed

 'play Nibbles until finished

 MessagePause "      Level" + STR$(curLevel)
 GameOver = FALSE
 DO
  IF NumPlayers = 1 THEN
   sammy(2).Row = 0
  END IF

  number = 1      'Current number that snakes are trying to run into
  nonum = TRUE    'nonum = TRUE if a number is not on the screen
  count = FALSE   'sets animation frame of number

  playerDied = FALSE
  PrintScore NumPlayers, sammy(1).score, sammy(2).score, sammy(1).lives, sammy(2).lives
  PLAY "T160O1>L20CDEDCDL10ECC"

        DO
            'Print number if no number exists
            IF nonum = TRUE THEN
             IF count = FALSE THEN
              DO
               numberRow = INT(RND(1) * 47 + 3)
               NumberCol = INT(RND(1) * 78 + 2)
              LOOP UNTIL NOT PointIsThere(numberRow, NumberCol, ColorTable(4))
              count = 1
             ELSEIF count < 4 THEN
              COLOR ColorTable(7), ColorTable(4): LOCATE numberRow, NumberCol: PRINT MID$("∞±≤", count, 1);
              count = count + 1
             ELSE
              nonum = FALSE
              count = FALSE
              LOCATE numberRow, NumberCol
              IF number > 9 THEN
               COLOR 0, 0: PRINT "€";
              ELSE
               COLOR ColorTable(7), ColorTable(4): PRINT RIGHT$(STR$(number), 1);
              END IF
             END IF
            END IF

            'Delay game
            FOR a# = 1 TO CurSpeed:  NEXT a#

            'Get keyboard input & Change direction accordingly
            kbd$ = UCASE$(INKEY$)
            SELECT CASE kbd$
             CASE "W": IF sammy(2).direction <> 2 THEN sammy(2).direction = 1
             CASE "S": IF sammy(2).direction <> 1 THEN sammy(2).direction = 2
             CASE "A": IF sammy(2).direction <> 4 THEN sammy(2).direction = 3
             CASE "D": IF sammy(2).direction <> 3 THEN sammy(2).direction = 4
             CASE CHR$(0) + "H": IF sammy(1).direction <> 2 THEN sammy(1).direction = 1
             CASE CHR$(0) + "P": IF sammy(1).direction <> 1 THEN sammy(1).direction = 2
             CASE CHR$(0) + "K": IF sammy(1).direction <> 4 THEN sammy(1).direction = 3
             CASE CHR$(0) + "M": IF sammy(1).direction <> 3 THEN sammy(1).direction = 4
             CASE " ": MessagePause "    Game Paused"
             CASE CHR$(27): EXIT SUB
             CASE ELSE
            END SELECT

            FOR a = 1 TO NumPlayers
                'Move Snake
                SELECT CASE sammy(a).direction
                 CASE 1: sammy(a).Row = sammy(a).Row - 1
                 CASE 2: sammy(a).Row = sammy(a).Row + 1
                 CASE 3: sammy(a).Col = sammy(a).Col - 1
                 CASE 4: sammy(a).Col = sammy(a).Col + 1
                END SELECT

                'If snake hits number, respond accordingly
                IF numberRow = INT(sammy(a).Row) AND NumberCol = sammy(a).Col THEN
                    PLAY "MBO0L16>CCCE"
                    IF sammy(a).length < (MAXSNAKELENGTH - 30) THEN
                        sammy(a).length = sammy(a).length + number * 4
                    END IF
                    sammy(a).score = sammy(a).score + number
                    PrintScore NumPlayers, sammy(1).score, sammy(2).score, sammy(1).lives, sammy(2).lives
                    IF diff$ = "Y" THEN CurSpeed = CurSpeed - 10
                    IF number > 9 THEN
                     EraseSnake sammy(), sammyBody(), 1
                     EraseSnake sammy(), sammyBody(), 2
                     Level NEXTLEVEL, sammy()
                     PrintScore NumPlayers, sammy(1).score, sammy(2).score, sammy(1).lives, sammy(2).lives
                     MessagePause "      Level" + STR$(curLevel)
                     IF NumPlayers = 1 THEN sammy(2).Row = 0
                     number = 1
                    ELSE number = number + 1
                    END IF
                    nonum = TRUE
                    IF CurSpeed < 1 THEN CurSpeed = 1
                END IF
            NEXT a

            FOR a = 1 TO NumPlayers
                'If player runs into any point, or the head of the other snake, it dies.
                IF PointIsThere(sammy(a).Row, sammy(a).Col, ColorTable(4)) OR (sammy(1).Row = sammy(2).Row AND sammy(1).Col = sammy(2).Col) THEN
                 PLAY "MBO0L32EFGEFDC"
                
                 playerDied = TRUE
                 sammy(a).alive = FALSE
                   
                'Otherwise, move the snake, and erase the tail
                ELSE
                    sammy(a).head = (sammy(a).head + 1) MOD MAXSNAKELENGTH
                    sammyBody(sammy(a).head, a).Row = sammy(a).Row
                    sammyBody(sammy(a).head, a).Col = sammy(a).Col
                    tail = (sammy(a).head + MAXSNAKELENGTH - sammy(a).length) MOD MAXSNAKELENGTH
                    SetPixel sammyBody(tail, a).Row, sammyBody(tail, a).Col, ColorTable(4)
                    sammyBody(tail, a).Row = 0
                    SetPixel sammy(a).Row, sammy(a).Col, sammy(a).scolor
                END IF
            NEXT a

   LOOP UNTIL playerDied

   CurSpeed = speed                ' reset speed to initial value
       
   FOR a = 1 TO NumPlayers
    EraseSnake sammy(), sammyBody(), a

    'If dead, then erase snake in really cool way
    IF sammy(a).alive = FALSE THEN
     'Update both score and lives
     IF sammy(a).lives < 1 THEN GameOver = TRUE ELSE sammy(a).lives = sammy(a).lives - 1
     sammy(a).score = sammy(a).score - 10
     PrintScore NumPlayers, sammy(1).score, sammy(2).score, sammy(1).lives, sammy(2).lives
                
     IF a = 1 THEN
      MessagePause " !!! Sammy Died !!!"
     ELSE
      MessagePause " !!! Jamie Died !!!"
     END IF
    END IF
   NEXT a

  IF NOT GameOver THEN Level SAMELEVEL, sammy()
  PrintScore NumPlayers, sammy(1).score, sammy(2).score, sammy(1).lives, sammy(2).lives
     
 'Play next round, until either of snake's lives have run out.
 LOOP UNTIL GameOver

END SUB

'  Checks the global  arena array to see if the boolean flag is set
FUNCTION PointIsThere (Row, Col, acolor)
 IF Row <> 0 THEN
  IF arena(Row, Col).acolor <> acolor THEN
   PointIsThere = TRUE
  ELSE
   PointIsThere = FALSE
  END IF
 END IF
END FUNCTION

'  Prints players scores and number of lives remaining
SUB PrintScore (NumPlayers, score1, score2, lives1, lives2)
 COLOR 15, ColorTable(4)

 Center 1, "<< Level" + STR$(curLevel) + " >>"
 IF NumPlayers = 2 THEN
  LOCATE 1, 76: PRINT "Jamie";
  LOCATE 2, 61: PRINT USING "##### Score  # Lives"; score2; lives2
 END IF

 LOCATE 1, 1: PRINT "Sammy";
 LOCATE 2, 1: PRINT USING "Score #####  Lives #"; score1; lives1
END SUB

'  Sets row and column on playing field to given color to facilitate moving
'  of snakes around the field.
SUB SetPixel (Row, Col, acolor)
 IF Row <> 0 THEN
  arena(Row, Col).acolor = acolor             'assign color to arena

  LOCATE Row, Col
  COLOR acolor
  PRINT CHR$(219);
 END IF
END SUB

SUB ShowPixel (Row, Col)

 COLOR arena(Row, Col).acolor
 LOCATE Row, Col
 PRINT CHR$(219);

END SUB

'  Creates flashing border for intro screen
SUB SparklePause
 
  COLOR 9, 0: LOCATE , , 0
  a$ = "ﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ    ﬂﬂ"
  WHILE INKEY$ <> "": WEND

  WHILE INKEY$ = ""
    FOR a = 1 TO 6
      WAIT &H3DA, 8: WAIT &H3DA, 8, 8
      LOCATE 1, 2: PRINT MID$(a$, a, 79);
      LOCATE 22, 1: PRINT MID$(a$, 8 - a, 80);
     
      IF a AND 1 THEN
       FOR b = 1 TO 21
        c = ((a \ 2) + b) MOD 3
        IF c = 0 THEN
         LOCATE b, 80: PRINT "‹";
         LOCATE 22 - b, 1: PRINT "ﬂ";
        ELSEIF c = 1 THEN
         LOCATE b, 80: PRINT "ﬂ";
         LOCATE 22 - b, 1: PRINT "‹";
        ELSE
         LOCATE b, 80: PRINT " ";
         LOCATE 22 - b, 1: PRINT " ";
        END IF
       NEXT b
      ELSE
       FOR b = 1 TO 21
        c = ((a \ 2) + b) MOD 3
        IF c = 1 THEN
         LOCATE b, 80: PRINT "€";
         LOCATE 22 - b, 1: PRINT "€";
        ELSE
         LOCATE b, 80: PRINT " ";
         LOCATE 22 - b, 1: PRINT " ";
        END IF
       NEXT b
      END IF

    NEXT a
  WEND
  
END SUB

'  Determines if users want to play game again.
FUNCTION StillWantsToPlay

 PLAY "MBO1L7CCCL14D#DDCC<B>C"

 COLOR ColorTable(5), ColorTable(6)
 Center 22, "€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€"
 Center 23, "€                             €"
 Center 24, "€      G A M E   O V E R      €"
 Center 25, "€                             €"
 Center 26, "€     Play Again?   (Y/N)     €"
 Center 27, "€                             €"
 Center 28, "€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€"

 WHILE INKEY$ <> "": WEND
 DO
  kbd$ = UCASE$(INKEY$)
 LOOP UNTIL kbd$ = "Y" OR kbd$ = "N"

 COLOR 15, ColorTable(4)
 FOR Row = 22 TO 28
  Center Row, "                               "
 NEXT Row

 IF kbd$ = "Y" THEN
  StillWantsToPlay = TRUE
 ELSE
  StillWantsToPlay = FALSE
  COLOR 7, 0
  CLS
 END IF

END FUNCTION

