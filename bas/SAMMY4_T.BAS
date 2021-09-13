' To run this game, press Shift+F5.
'
' To exit QBasic, press Alt, F, X.

'Sets default data type to integer for faster game play
DEFINT A-Z

'User-defined TYPEs
TYPE snakeBody
 row AS INTEGER
 col AS INTEGER
 dir AS INTEGER
END TYPE

'This type defines the player's snake
TYPE snaketype
 head AS INTEGER
 Length AS INTEGER
 row AS INTEGER
 col AS INTEGER
 dir AS INTEGER
 lives AS INTEGER
 score AS INTEGER
 alive AS INTEGER
END TYPE

'Stores the current color of each point

'Sub Declarations
DECLARE SUB MessagePause (text$)
DECLARE SUB PrintScore (NumPlayers, score1, score2, lives1, lives2)
DECLARE SUB Intro ()
DECLARE SUB GetInputs (NumPlayers, speed, incSpeed)
DECLARE SUB DrawScreen ()
DECLARE SUB PlayNibbles (NumPlayers, speed, incSpeed, GameExit)
DECLARE SUB SetPixel (row, col, acolor)
DECLARE SUB ShowPixel (row, col)
DECLARE SUB Center (row, text$)
DECLARE SUB DoIntro ()
DECLARE SUB Initialize ()
DECLARE SUB SparklePause ()
DECLARE SUB CreateLevel (WhatToDO)
DECLARE SUB SetSnakes (Sammy() AS snaketype)
DECLARE SUB ClearArena ()
DECLARE SUB EraseSnake (snake() AS ANY, snakeBod() AS ANY, snakeNum)
DECLARE SUB SetCharPixel (row, col, Block)
DECLARE SUB SetLandPixel (row, col, Block)
DECLARE SUB ShowWholeArena ()
DECLARE FUNCTION StillWantsToPlay (GameExit)
DECLARE FUNCTION PointIsThere (row, col, backColor)

'Constants
CONST TRUE = -1, FALSE = 0
CONST MAXSNAKELENGTH = 1000
CONST STARTOVER = 1, SAMELEVEL = 2, NEXTLEVEL = 3, LASTLEVEL = 12

'Global Variables
DIM SHARED LandArena(0 TO 60, 0 TO 80) AS INTEGER, CharArena(0 TO 60, 0 TO 80) AS INTEGER, levelPicts(0 TO 3000), LastBlock
DIM SHARED CurLevel, ColorTable(3)

 RANDOMIZE TIMER
 GOSUB ClearKeyLocks
 GOSUB ReadLevelPicts
 ''SCREEN 7: VIEW PRINT
 ''FOR a = 0 TO LastBlock * 2 + 1
 '' LOCATE a MOD 25 + 1, (a \ 25) * 6 + 1: PRINT a;
 '' PUT ((a \ 25) * 48 + 30, (a MOD 25) * 8), levelPicts(a * 18), PSET
 ''NEXT a
 Intro
 DrawScreen
 ClearArena
 GetInputs NumPlayers, speed, incSpeed

 DO
  PlayNibbles NumPlayers, speed, incSpeed, GameExit
 LOOP WHILE StillWantsToPlay(GameExit)

 WIDTH 80, 25
 COLOR 15, 0
 CLS
END

ClearKeyLocks:
 DEF SEG = 0: POKE 1047, &H0
 DEF SEG
 RETURN

ReadLevelPicts:
 RESTORE ReadLevelPicts
 ColorTable(1) = 8  'Dialog border
 ColorTable(2) = 15 'Text, highlit
 ColorTable(3) = 7  'Unused text

 LastBlock = 19
 LandBlockType = 0
 FOR a = 0 TO LastBlock * 36 + 35: READ levelPicts(a): NEXT a
 
'Grass,Crystal,Block
 DATA 8,8,-8960,8704,-256,1024,-256,0,-256,8192,-17664,17408,-256,512,-256,0,-256,16384
 DATA 8,8,244,244,127,2943,151,151,124,26748,219,-31781,239,8431,146,4242,125,28029
 DATA 8,8,-1,-1025,-1,-513,-258,-514,-258,-258,-258,-1282,-258,29694,-515,-25091,-15421,-6205
 DATA 8,8,15420,14396,16962,16450,-20304,-20048,-19790,-19790,-32126,-32126,-32126,898,23644,7260,0,9216
 DATA 8,8,-1,-15361,-15421,-23101,-32383,17025,-32383,129,-32383,129,-32383,17025,-15421,-23101,-258,-15618
 DATA 8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DATA 8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DATA 8,8,-258,-1,722,32511,-16192,15615,-16192,15615,-16192,15615,-16192,15615,-32640,195,0,129
 DATA 8,8,255,-768,255,-8448,255,-256,255,-256,255,-1280,255,-256,255,-16640,255,-256
 DATA 8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DATA 8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DATA 8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
'6 Snakehead u,l,d,r
 DATA 8,8,-1,-1,-1,-1,-1,-1,-1,-1,-15421,-15421,-32383,-32383,0,0,0,0
 DATA 8,8,0,0,0,0,0,0,0,0,0,0,0,15420,0,20566,0,20566
 DATA 8,8,-772,-772,-1800,-1800,-3856,-3856,-3856,-3856,-3856,-3856,-3856,-3856,-1800,-1800,-772,-772
 DATA 8,8,0,0,0,772,0,1028,0,1799,0,1028,0,7,0,3,0,0
 DATA 8,8,0,0,0,0,-32383,-32383,-15421,-15421,-1,-1,-1,-1,-1,-1,-1,-1
 DATA 8,8,0,20566,0,20566,0,60,0,0,0,0,0,0,0,0,0,0
 DATA 8,8,16191,16191,7967,7967,3855,3855,3855,3855,3855,3855,3855,3855,7967,7967,16191,16191
 DATA 8,8,0,0,0,-32576,0,32,0,-16160,0,32,0,224,0,192,0,0
'10 Snaketail u,l,d,r
 DATA 8,8,0,0,0,0,-32383,-32383,-15421,-15421,-1,-1,-1,-1,-1,-1,-1,-1
 DATA 8,8,0,30846,0,12414,0,60,0,0,0,0,0,0,0,0,0,0
 DATA 8,8,16191,16191,7967,7967,3855,3855,3855,3855,3855,3855,3855,3855,7967,7967,16191,16191
 DATA 8,8,0,0,0,-32576,0,-16160,0,-16160,0,-32544,0,224,0,192,0,0
 DATA 8,8,-1,-1,-1,-1,-1,-1,-1,-1,-15421,-15421,-32383,-32383,0,0,0,0
 DATA 8,8,0,0,0,0,0,0,0,0,0,0,0,12348,0,30846,0,30846
 DATA 8,8,-772,-772,-1800,-1800,-3856,-3856,-3856,-3856,-3856,-3856,-3856,-3856,-1800,-1800,-772,-772
 DATA 8,8,0,0,0,771,0,1799,0,1799,0,775,0,7,0,3,0,0
'14 snakebody ud,lr
 DATA 8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DATA 8,8,0,30846,0,30846,0,30846,0,30846,0,30846,0,30846,0,30846,0,30846
 DATA 8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DATA 8,8,0,0,0,-1,0,-1,0,-1,0,-1,0,255,0,255,0,0
'16 Snakecorner dl,dr,ur,ul
 DATA 8,8,0,0,0,0,0,0,-32640,-32640,-32640,-32640,-16192,-16192,-7968,-7968,-1800,-1800
 DATA 8,8,0,31870,0,32639,0,16255,0,16191,0,3903,0,31,0,7,0,0
 DATA 8,8,0,0,0,0,0,0,257,257,257,257,771,771,1799,1799,7967,7967
 DATA 8,8,0,30846,0,-1794,0,-3842,0,-3844,0,-16132,0,248,0,224,0,0
 DATA 8,8,7967,7967,1799,1799,771,771,257,257,257,257,0,0,0,0,0,0
 DATA 8,8,0,0,0,-16160,0,-3848,0,-3844,0,-1796,0,-1794,0,30974,0,30846
 DATA 8,8,-1800,-1800,-7968,-7968,-16192,-16192,-32640,-32640,-32640,-32640,0,0,0,0,0,0
 DATA 8,8,0,0,0,1799,0,7967,0,16191,0,16191,0,31871,0,30847,0,30846
RETURN

END

'  Centers text on given row
SUB Center (row, text$)
    LOCATE row, 41 - LEN(text$) \ 2
    PRINT text$;
END SUB

'  Initializes playing field colors
SUB ClearArena
    
 FOR row = 5 TO 59
  FOR col = 0 TO 79
   IF CharArena(row, col) THEN CharArena(row, col) = 0: ShowPixel row, col
  NEXT col
 NEXT row

END SUB

'Sets game level
SUB CreateLevel (WhatToDO)
    
 SELECT CASE (WhatToDO)
  CASE STARTOVER: CurLevel = 1
  CASE NEXTLEVEL: CurLevel = CurLevel + 1
 END SELECT

 Center 1, " << Drawing >> "

 FOR row = 5 TO 59
  FOR col = 0 TO 79
   LandArena(row, col) = 0
  NEXT col
 NEXT row

 'Set (turn on) pixels for screen border
 FOR col = 0 TO 79
  LandArena(4, col) = 1
  LandArena(59, col) = 1
 NEXT col

 FOR row = 5 TO 58
  LandArena(row, 0) = 1
  LandArena(row, 79) = 1
 NEXT row

 SELECT CASE CurLevel
 CASE 1 'Do nothing
 CASE 2
  FOR i = 20 TO 60
   SetLandPixel 30, i, 1
  NEXT i
 CASE 3
  FOR i = 11 TO 52
   SetLandPixel i, 20, 1
   SetLandPixel i, 60, 1
  NEXT i
 CASE 4
  FOR i = 5 TO 34
   SetLandPixel i, 19, 1
   SetLandPixel 63 - i, 59, 1
  NEXT i
  FOR i = 1 TO 39
   SetLandPixel 44, i, 1
   SetLandPixel 17, 79 - i, 1
  NEXT i
 CASE 5
  FOR i = 15 TO 48
   SetLandPixel i, 21, 1
   SetLandPixel i, 59, 1
  NEXT i
  FOR i = 23 TO 57
   SetLandPixel 13, i, 1
   SetLandPixel 50, i, 1
  NEXT i
 CASE 6
  FOR i = 5 TO 59
   IF i > 36 OR i < 28 THEN
    SetLandPixel i, 6, 1
    SetLandPixel i, 14, 1
    SetLandPixel i, 25, 1
    SetLandPixel i, 40, 1
    SetLandPixel i, 54, 1
    SetLandPixel i, 65, 1
    SetLandPixel i, 73, 1
   END IF
  NEXT i
 CASE 7
  FOR i = 6 TO 58 STEP 2
   SetLandPixel i, 40, 1
  NEXT i
 CASE 8
  FOR i = 4 TO 50
   SetLandPixel i, 10, 1
   SetLandPixel 62 - i, 20, 1
   SetLandPixel i, 30, 1
   SetLandPixel 62 - i, 40, 1
   SetLandPixel i, 50, 1
   SetLandPixel 62 - i, 60, 1
   SetLandPixel i, 70, 1
  NEXT i
 CASE 9
  FOR i = 5 TO 46
   SetLandPixel i + 6, i, 1
   SetLandPixel i + 6, i + 28, 1
  NEXT i
 CASE 10
  FOR i = 1 TO 38
   SetLandPixel 32, i, 1
   SetLandPixel 32, 80 - i, 1
  NEXT i
  FOR i = 5 TO 30
   SetLandPixel i, 40, 1
   SetLandPixel 64 - i, 40, 1
  NEXT i
 CASE 11
  FOR i = 4 TO 58 STEP 2
   SetLandPixel i, 10, 1
   SetLandPixel i + 1, 20, 1
   SetLandPixel i, 30, 1
   SetLandPixel i + 1, 40, 1
   SetLandPixel i, 50, 1
   SetLandPixel i + 1, 60, 1
   SetLandPixel i, 70, 1
  NEXT i
 CASE ELSE
  FOR i = 9 TO 54: SetLandPixel i, 40, 1: NEXT i
   FOR i = 1 TO 38
    SetLandPixel 32, i, 1
    SetLandPixel 32, i + 41, 1
   NEXT i
  FOR i = 0 TO 23
   SetLandPixel 7 + i, 38 - i, 1
   SetLandPixel 7 + i, 42 + i, 1
   SetLandPixel 34 + i, 65 - i, 1
   SetLandPixel 34 + i, 15 + i, 1
  NEXT i
  FOR i = 38 TO 42
   FOR b = 5 TO 6
    SetLandPixel b, i, 1
    SetLandPixel b + 53, i, 1
   NEXT b
  NEXT i
 END SELECT

ShowWholeArena
Center 1, " << Level" + STR$(CurLevel) + " >> "

END SUB

'  Sets screen mode for playing field
SUB DrawScreen

 'initialize screen
 SCREEN 12
 VIEW PRINT

END SUB

'  Erases snake to facilitate moving through playing field
SUB EraseSnake (snake() AS snaketype, snakeBod() AS snakeBody, snakeNum)

 IF snake(snakeNum).alive THEN
  SetCharPixel snake(snakeNum).row, snake(snakeNum).col, (snake(snakeNum).dir XOR 2) + 10
  FOR b = snake(snakeNum).Length TO 0 STEP -1
   tail = (snake(snakeNum).head + MAXSNAKELENGTH - b) MOD MAXSNAKELENGTH
   SetCharPixel snakeBod(tail, snakeNum).row, snakeBod(tail, snakeNum).col, 0
   tail = (tail + 1) MOD MAXSNAKELENGTH
   SetCharPixel snakeBod(tail, snakeNum).row, snakeBod(tail, snakeNum).col, snakeBod((tail + 1) MOD MAXSNAKELENGTH, snakeNum).dir MOD 4 + 10
   WAIT &H3DA, 8, 8: WAIT &H3DA, 8
  NEXT b
 ELSE
  FOR c = 0 TO 9
   FOR b = snake(snakeNum).Length - c TO 0 STEP -10
    tail = (snake(snakeNum).head + MAXSNAKELENGTH - b) MOD MAXSNAKELENGTH
    SetCharPixel snakeBod(tail, snakeNum).row, snakeBod(tail, snakeNum).col, 3
   NEXT b
   WAIT &H3DA, 8, 8: WAIT &H3DA, 8
  NEXT c
 END IF

END SUB

SUB GetInputs (NumPlayers, speed, incSpeed) STATIC

 NumPlayers = 1

 COLOR ColorTable(1)
 Center 4, "€" + STRING$(34, 223) + "€"
 FOR row = 5 TO 27
  Center row, "€" + SPACE$(34) + "€"
 NEXT row
 Center 15, STRING$(34, 220)
 Center 21, "ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ"
 Center 22, "     General    €  Sammy   Jamie  "
 Center 23, "ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ€ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ"
 Center 24, "  Space - Pause €           W    "
 Center 25, "                €         A S   "
 Center 26, "    Esc - Menu  €           D    "
 Center 27, "‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹"
 FOR ShowChoice = 0 TO 4
  GOSUB GetInputsMenu
 NEXT ShowChoice
 ShowChoice = 0

 DO
  kbrd$ = INKEY$
  IF kbrd$ > "" THEN
   SELECT CASE kbrd$
   CASE CHR$(13): IF CurChoice = 1 AND gameSpeed$ = "" THEN gameSpeed$ = "20"
    IF CurChoice < 3 THEN CurChoice = CurChoice + 1: DrawMenuChoice = 1 ELSE IF CurChoice = 3 THEN EXIT DO ELSE END
   CASE CHR$(27): END
   CASE CHR$(0) + "H": CurChoice = (CurChoice + 4) MOD 5: DrawMenuChoice = 1
   CASE CHR$(0) + "P": CurChoice = (CurChoice + 1) MOD 5: DrawMenuChoice = 1
   CASE ELSE
    SELECT CASE CurChoice
    CASE 0: value = VAL(kbrd$): IF value = 1 OR value = 2 THEN NumPlayers = value: CurChoice = CurChoice + 1: DrawMenuChoice = 1
    CASE 1: IF kbrd$ >= "0" AND kbrd$ <= "9" THEN IF VAL(gameSpeed$ + kbrd$) <= 100 THEN gameSpeed$ = gameSpeed$ + kbrd$: DrawMenuChoice = 1
     IF kbrd$ = "" THEN DrawMenuChoice = 1: IF gameSpeed$ > "" THEN gameSpeed$ = LEFT$(gameSpeed$, LEN(gameSpeed$) - 1)
    CASE 2: IF kbrd$ = CHR$(0) + "K" OR kbrd$ = CHR$(0) + "M" OR kbrd$ = " " THEN incSpeed = incSpeed XOR TRUE: DrawMenuChoice = 1
    END SELECT
   END SELECT
   IF DrawMenuChoice THEN DrawMenuChoice = 0: GOSUB GetInputsMenu: IF ShowChoice <> CurChoice THEN ShowChoice = CurChoice: GOSUB GetInputsMenu
  END IF
 LOOP

 IF gameSpeed$ = "" THEN speed = 20 ELSE speed = VAL(gameSpeed$)
 startTime# = TIMER: FOR i# = 1 TO 2000: NEXT i#: stopTime# = TIMER
 speed = (100 - speed) * 2 + 1: speed = speed * .5 / (stopTime# - startTime#)
 
EXIT SUB

GetInputsMenu:
 IF ShowChoice = CurChoice THEN COLOR ColorTable(2) ELSE COLOR ColorTable(3)
 SELECT CASE ShowChoice
 CASE 0: LOCATE 5, 27: PRINT "How many players (1 or 2):"; STR$(NumPlayers);
 CASE 1: Center 8, "1   = Just Hatched ": Center 9, "40  = Pretty Good  "
  Center 10, "70  = Natural Snake": Center 11, "100 = Mad Serpent  "
  LOCATE 7, 28: PRINT "Skill level (1 to 100):    "; : LOCATE , 52: PRINT gameSpeed$;
 CASE 2: Center 13, "Increase game speed during play:"
  LOCATE 14, 30: PRINT "Stay same";
  LOCATE , 43: PRINT "Go faster";
  IF incSpeed THEN LOCATE , 42 ELSE LOCATE , 29
  PRINT "";
  IF incSpeed THEN LOCATE , 29 ELSE LOCATE , 42
  PRINT " ";
 CASE 3: Center 17, "Start Game"
 CASE 4: Center 19, "Exit Sammy"
 END SELECT
RETURN

END SUB

'  Displays game introduction
SUB Intro
 
 SCREEN 0
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

END SUB

'  Pauses game play and waits for space bar to be pressed before continuing
SUB MessagePause (text$)

 COLOR ColorTable(1)
 Center 13, STRING$(24, 219)
 Center 14, "€" + SPACE$(22) + "€"
 Center 15, "€" + SPACE$(22) + "€"
 Center 16, "€" + SPACE$(22) + "€"
 Center 17, STRING$(24, 219)
 COLOR ColorTable(2): Center 15, LEFT$(text$, 20)
 WHILE INKEY$ <> "": WEND
 DO: kbd$ = INKEY$: LOOP UNTIL kbd$ = " " OR kbd$ = CHR$(13) OR kbd$ = CHR$(27)

 FOR row = 24 TO 33      ' Restore the screen background
  FOR col = 28 TO 51
   ShowPixel row, col
  NEXT col
 NEXT row

END SUB

'  Main routine that controls game play
SUB PlayNibbles (NumPlayers, speed, incSpeed, GameExit)

 'Initialize Snakes
 DIM sammyBody(MAXSNAKELENGTH - 1, 1 TO 2) AS snakeBody
 DIM Sammy(1 TO 2) AS snaketype
 Sammy(1).lives = 4
 Sammy(1).score = 0
 Sammy(2).lives = 4
 Sammy(2).score = 0
 GameExit = 1

 CreateLevel STARTOVER
 SetSnakes Sammy()

 CurSpeed = speed

 'play Nibbles until finished

 MessagePause "Ready for Level" + STR$(CurLevel)
 GameOver = FALSE
 DO
  IF NumPlayers = 1 THEN Sammy(2).row = 0
 
  number = 1      'Current number that snakes are trying to run into
  nonum = TRUE   '= TRUE if there is no number on the screen

  playerDied = FALSE
  PrintScore NumPlayers, Sammy(1).score, Sammy(2).score, Sammy(1).lives, Sammy(2).lives
  PLAY "T160O1>L20CDEDCDL10ECC"

  DO
   'Delay game
   FOR a# = 1 TO CurSpeed: NEXT a#
   'WAIT &H3DA, 8, 8: WAIT &H3DA, 8

   'Get keyboard input & Change direction accordingly
   kbd$ = UCASE$(INKEY$)
   SELECT CASE kbd$
   CASE "W": IF Sammy(2).dir <> 2 THEN Sammy(2).dir = 0
   CASE "A": IF Sammy(2).dir <> 3 THEN Sammy(2).dir = 1
   CASE "S": IF Sammy(2).dir <> 0 THEN Sammy(2).dir = 2
   CASE "D": IF Sammy(2).dir <> 1 THEN Sammy(2).dir = 3
   CASE CHR$(0) + "H": IF Sammy(1).dir <> 2 THEN Sammy(1).dir = 0
   CASE CHR$(0) + "K": IF Sammy(1).dir <> 3 THEN Sammy(1).dir = 1
   CASE CHR$(0) + "P": IF Sammy(1).dir <> 0 THEN Sammy(1).dir = 2
   CASE CHR$(0) + "M": IF Sammy(1).dir <> 1 THEN Sammy(1).dir = 3
   CASE " ": MessagePause "Game Paused "
   CASE CHR$(27): IF NOT StillWantsToPlay(0) THEN ClearArena: EXIT SUB
   CASE ELSE
   END SELECT

   IF nonum THEN
    numberRow = INT(RND(1) * 54) + 5
    numberCol = INT(RND(1) * 78) + 1
    IF (PointIsThere(numberRow, numberCol, 0) OR CharArena(numberRow, numberCol)) = FALSE THEN
     IF number > 9 THEN SetCharPixel numberRow, numberCol, 2 ELSE SetCharPixel numberRow, numberCol, 1
     nonum = FALSE
    END IF
   END IF
         
   FOR a = 1 TO NumPlayers
    'Move Snake
    SELECT CASE Sammy(a).dir
    CASE 0: Sammy(a).row = Sammy(a).row - 1
    CASE 1: Sammy(a).col = Sammy(a).col - 1
    CASE 2: Sammy(a).row = Sammy(a).row + 1
    CASE 3: Sammy(a).col = Sammy(a).col + 1
    END SELECT
   NEXT a

   FOR a = 1 TO NumPlayers
    'If player runs into any point, or the head of the other snake, it dies.
    IF PointIsThere(Sammy(a).row, Sammy(a).col, 0) OR (Sammy(1).row = Sammy(2).row AND Sammy(1).col = Sammy(2).col) THEN
     PLAY "O0L32EFGEFDC"
                
     playerDied = TRUE
     Sammy(a).alive = FALSE
                   
     'Otherwise, move the snake
    ELSE
     Sammy(a).head = (Sammy(a).head + 1) MOD MAXSNAKELENGTH
     sammyBody(Sammy(a).head, a).row = Sammy(a).row
     sammyBody(Sammy(a).head, a).col = Sammy(a).col
     sammyBody(Sammy(a).head, a).dir = Sammy(a).dir
     SetCharPixel Sammy(a).row, Sammy(a).col, Sammy(a).dir + 6
     tail = (Sammy(a).head - 1 + MAXSNAKELENGTH) MOD MAXSNAKELENGTH
     IF sammyBody(tail, a).dir = Sammy(a).dir THEN
      SetCharPixel sammyBody(tail, a).row, sammyBody(tail, a).col, (Sammy(a).dir AND 1) + 14
     ELSE
      corner = Sammy(a).dir: IF (Sammy(a).dir - sammyBody(tail, a).dir + 4) MOD 4 = 1 THEN corner = (corner + 1) MOD 4
      SetCharPixel sammyBody(tail, a).row, sammyBody(tail, a).col, corner + 16
     END IF
     tail = (Sammy(a).head + MAXSNAKELENGTH - Sammy(a).Length) MOD MAXSNAKELENGTH
     SetCharPixel sammyBody(tail, a).row, sammyBody(tail, a).col, 0
     sammyBody(tail, a).row = 0
     tail = (tail + 1) MOD MAXSNAKELENGTH
     SetCharPixel sammyBody(tail, a).row, sammyBody(tail, a).col, sammyBody((tail + 1) MOD MAXSNAKELENGTH, a).dir MOD 4 + 10
    END IF
   
    'If snake hits number, respond accordingly
    IF numberRow = INT(Sammy(a).row) AND numberCol = Sammy(a).col AND NOT nonum THEN
     IF Sammy(a).Length < (MAXSNAKELENGTH - 30) THEN
      Sammy(a).Length = Sammy(a).Length + number * 4
     END IF
     Sammy(a).score = Sammy(a).score + number
     PrintScore NumPlayers, Sammy(1).score, Sammy(2).score, Sammy(1).lives, Sammy(2).lives
     IF incSpeed THEN CurSpeed = CurSpeed - 10
     IF number > 9 THEN
      FOR a = 1 TO NumPlayers
       EraseSnake Sammy(), sammyBody(), a
      NEXT a
      IF CurLevel = LASTLEVEL THEN GameExit = 2: EXIT SUB
      CreateLevel NEXTLEVEL
      ClearArena
      SetSnakes Sammy()
      PrintScore NumPlayers, Sammy(1).score, Sammy(2).score, Sammy(1).lives, Sammy(2).lives
      MessagePause " Ready for Level" + STR$(CurLevel)
      IF NumPlayers = 1 THEN Sammy(2).row = 0
      number = 1
     ELSE
      PLAY "O0L16>CCCE"
      number = number + 1
     END IF
     nonum = TRUE
     IF CurSpeed < 1 THEN CurSpeed = 1
    END IF
   NEXT a

  LOOP UNTIL playerDied

  CurSpeed = speed                ' reset speed to initial value
       
  FOR a = 1 TO NumPlayers
   EraseSnake Sammy(), sammyBody(), a
   'If dead, then erase snake in really cool way
  
   IF Sammy(a).alive = FALSE THEN
    'Update both score and lives
    IF Sammy(a).lives < 1 THEN GameOver = TRUE ELSE Sammy(a).lives = Sammy(a).lives - 1
    Sammy(a).score = Sammy(a).score - 10
    PrintScore NumPlayers, Sammy(1).score, Sammy(2).score, Sammy(1).lives, Sammy(2).lives
                
    IF a = 1 THEN
     MessagePause "!!! Sammy Died !!!"
    ELSE
     MessagePause "!!! Jamie Died !!!"
    END IF
   END IF
  NEXT a

  PrintScore NumPlayers, Sammy(1).score, Sammy(2).score, Sammy(1).lives, Sammy(2).lives
  ClearArena
  IF NOT GameOver THEN SetSnakes Sammy()

 'Play next round, until either of snake's lives have run out.
 LOOP UNTIL GameOver

END SUB

'  Checks the global  arena array to see if the boolean flag is set
FUNCTION PointIsThere (row, col, Block)
 IF row <> 0 THEN
  IF LandArena(row, col) <> Block THEN
   PointIsThere = TRUE
  ELSE
   PointIsThere = FALSE
  END IF
 END IF
END FUNCTION

'  Prints players scores and number of lives remaining
SUB PrintScore (NumPlayers, score1, score2, lives1, lives2)
 COLOR 15

 IF NumPlayers = 2 THEN
  LOCATE 1, 76: PRINT "Jamie";
  LOCATE 2, 61: PRINT USING "##### Score  # Lives"; score2; lives2
 END IF

 LOCATE 1, 1: PRINT "Sammy";
 LOCATE 2, 1: PRINT USING "Score #####  Lives #"; score1; lives1
END SUB

'  Sets row and column on playing field to given color to facilitate moving
'  of snakes around the field.
SUB SetCharPixel (row, col, Block)
 IF row THEN
  CharArena(row, col) = Block'assign color to arena

  IF Block > LastBlock THEN PUT (col * 8, row * 8), levelPicts(36), PSET: EXIT SUB
  PUT (col * 8, row * 8), levelPicts(LandArena(row, col) * 18), PSET
  IF Block THEN
   PUT (col * 8, row * 8), levelPicts(Block * 36), AND
   PUT (col * 8, row * 8), levelPicts(Block * 36 + 18), OR
  END IF
 END IF
END SUB

SUB SetLandPixel (row, col, Block)
 LandArena(row, col) = Block'assign color to arena

 'IF Block > LastBlock THEN PUT ((Col - 1) * 8, (Row - 1) * 8), levelPicts(36), PSET: EXIT SUB
 'PUT (Col * 8, Row * 8), levelPicts(Block * 18), PSET
 'IF CharArena(Row, Col) THEN
 ' PUT (Col * 8, Row * 8), levelPicts(CharArena(Row, Col) * 36), AND
 ' PUT (Col * 8, Row * 8), levelPicts(CharArena(Row, Col) * 36 + 18), OR
 'END IF

END SUB

SUB SetSnakes (Sammy() AS snaketype)

 Sammy(1).head = 1     'Initialize Snakes
 Sammy(1).Length = 3
 Sammy(1).alive = TRUE
 Sammy(2).head = 1
 Sammy(2).Length = 3
 Sammy(2).alive = TRUE

 SELECT CASE CurLevel
 CASE 1
  Sammy(1).row = 25: Sammy(2).row = 25
  Sammy(1).col = 50: Sammy(2).col = 30
  Sammy(1).dir = 3: Sammy(2).dir = 2
 CASE 2
  Sammy(1).row = 7: Sammy(2).row = 43
  Sammy(1).col = 60: Sammy(2).col = 20
  Sammy(1).dir = 1: Sammy(2).dir = 3
 CASE 3
  Sammy(1).row = 25: Sammy(2).row = 25
  Sammy(1).col = 50: Sammy(2).col = 30
  Sammy(1).dir = 0: Sammy(2).dir = 1
 CASE 4
  Sammy(1).row = 7: Sammy(2).row = 43
  Sammy(1).col = 60: Sammy(2).col = 20
  Sammy(1).dir = 1: Sammy(2).dir = 3
 CASE 5
  Sammy(1).row = 35: Sammy(2).row = 25
  Sammy(1).col = 50: Sammy(2).col = 30
  Sammy(1).dir = 0: Sammy(2).dir = 1
 CASE 6
  Sammy(1).row = 31: Sammy(2).row = 32
  Sammy(1).col = 49: Sammy(2).col = 32
  Sammy(1).dir = 1: Sammy(2).dir = 3
 CASE 7
  Sammy(1).row = 7: Sammy(2).row = 33
  Sammy(1).col = 65: Sammy(2).col = 15
  Sammy(1).dir = 2: Sammy(2).dir = 1
 CASE 8
  Sammy(1).row = 7: Sammy(2).row = 43
  Sammy(1).col = 75: Sammy(2).col = 15
  Sammy(1).dir = 2: Sammy(2).dir = 0
 CASE 9
  Sammy(1).row = 40: Sammy(2).row = 15
  Sammy(1).col = 75: Sammy(2).col = 5
  Sammy(1).dir = 0: Sammy(2).dir = 1
 CASE 10
  Sammy(1).row = 7: Sammy(2).row = 43
  Sammy(1).col = 60: Sammy(2).col = 20
  Sammy(1).dir = 2: Sammy(2).dir = 3
 CASE 11
  Sammy(1).row = 5: Sammy(2).row = 48
  Sammy(1).col = 46: Sammy(2).col = 37
  Sammy(1).dir = 2: Sammy(2).dir = 2
 CASE ELSE
  Sammy(1).row = 7: Sammy(2).row = 43
  Sammy(1).col = 50: Sammy(2).col = 15
  Sammy(1).dir = 3: Sammy(2).dir = 0
 END SELECT



END SUB

SUB ShowPixel (row, col)

 Block = CharArena(row, col)
 IF Block > LastBlock THEN PUT (col * 8, row * 8), levelPicts(18), PSET: EXIT SUB
 IF Block = 0 THEN
  PUT (col * 8, row * 8), levelPicts(LandArena(row, col) * 18), PSET
 ELSE
  PUT (col * 8, row * 8), levelPicts(LandArena(row, col) * 18), PSET
  PUT (col * 8, row * 8), levelPicts(Block * 36), AND
  PUT (col * 8, row * 8), levelPicts(Block * 36 + 18), OR
 END IF

END SUB

SUB ShowWholeArena

 FOR row = 4 TO 59
  FOR col = 0 TO 79
   PUT (col * 8, row * 8), levelPicts(LandArena(row, col) * 18), PSET
  NEXT col
 NEXT row
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
FUNCTION StillWantsToPlay (GameExit)

 COLOR ColorTable(2)
 IF GameExit > 1 THEN
  PLAY "O3L4CL12CCCL2C L12C#CC#C#CC# O3L4CL12CCCL6C<L6AB->MLL2CL18CP2P4MNL12FFFF"
 
  Center 10, STRING$(31, 219)
  Center 11, "€   I am sorry that I do not  €"
  Center 12, "€ have a really fancy ending  €"
  Center 13, "€                             €"
  Center 14, "€  Being able to get through  €"
  Center 15, "€ twelve levels on only five  €"
  Center 16, "€   lives is pretty awesome   €"
  Center 17, "€                             €"
  Center 18, "€ All I can say is that, if   €"
  Center 19, "€ you can beat this game, you €"
  Center 20, "€ must be an excellent sammy! €"
  Center 21, STRING$(31, 219)

  WHILE INKEY$ = "": WEND
  EXIT FUNCTION
 ELSEIF GameExit THEN
  PLAY "O1L7CCCL14D#DDCC<B>C"

  Center 12, STRING$(31, 219)
  Center 13, "€                             €"
  Center 14, "€      G A M E   O V E R      €"
  Center 15, "€                             €"
  Center 16, "€      Play again? (Y/N)      €"
  Center 17, "€                             €"
  Center 18, STRING$(31, 219)
 ELSE
  Center 13, STRING$(29, 219)
  Center 14, "€                           €"
  Center 15, "€  Continue playing? (Y/N)  €"
  Center 16, "€                           €"
  Center 17, STRING$(29, 219)
 END IF

 WHILE INKEY$ <> "": WEND
 DO
  kbd$ = UCASE$(INKEY$)
 LOOP UNTIL kbd$ = "Y" OR kbd$ = "N" OR kbd$ = CHR$(27)

 IF kbd$ = "Y" THEN
  StillWantsToPlay = TRUE
  IF GameExit = 0 THEN
   FOR row = 24 TO 33
    FOR col = 26 TO 54
     ShowPixel row, col
    NEXT col
   NEXT row
  END IF
 ELSE
  StillWantsToPlay = FALSE
 END IF

END FUNCTION

