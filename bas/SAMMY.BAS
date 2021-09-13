'                         Q B a s i c   N i b b l e s
'                   Copyright (C) Microsoft Corporation 1990
'
' To run this game, press Shift+F5.
' To exit QBasic, press Alt, F, X.

DEFINT A-Z

TYPE SnakeBody: Row AS INTEGER: Col AS INTEGER: clr AS INTEGER: END TYPE
TYPE Snaketype
  head AS INTEGER
  length AS INTEGER
  Row AS INTEGER
  Col AS INTEGER
  direction AS INTEGER
  Speed AS INTEGER
  scolr AS INTEGER
  alive AS INTEGER
END TYPE

TYPE Arena: Layer AS INTEGER: pcolor AS INTEGER: char AS INTEGER: END TYPE
TYPE Player: lives AS INTEGER: score AS INTEGER: alive AS INTEGER: END TYPE

DECLARE SUB MessagePause (text$)
DECLARE SUB PrintScore (NumPlayers, score1, score2, lives1, lives2)
DECLARE SUB Intro ()
DECLARE SUB GetInputs (NumPlayers, PlaySpeed$, Speed)
DECLARE SUB SimPlay (NumPlayers, Speed, Objects$)
DECLARE SUB Set (Row, Col, Layer, acolor)
DECLARE SUB Pixel (Row, Col)
DECLARE SUB ShowGrid ()
DECLARE SUB Center (Row, text$)
DECLARE SUB SparklePause ()
DECLARE SUB Level (WhatToDO, PreLevel, sammy() AS Snaketype)
DECLARE SUB InitColors ()
DECLARE SUB EraseSnake (snake() AS ANY, snakeBod() AS ANY, snakeNum, Mode)
DECLARE SUB SnakeLetter (Letr$, Urow, Lcol, Drow, Rcol)
DECLARE FUNCTION StillWantsToPlay ()
DECLARE FUNCTION PointIsThere (Row, Col, Layer)

CONST TRUE = -1, FALSE = 0
CONST MAXSNAKELENGTH = 1000

CONST FRSTLEVEL = 1, LASTLEVEL = 13, SAMELEVEL = -2, NEXTLEVEL = -3, GOTOLEVEL = -4

DIM SHARED Arena(1 TO 50, 1 TO 80) AS Arena, Objects$, CurLevel, Letter(1 TO 26)
DIM SHARED ColorTable(10), ExitSign, Players(4) AS Player, Player$(4)

Intro
GetInputs NumPlayers, PlaySpeed$, Speed
GOSUB SetComputer
GOSUB SetScreen
CurLevel = FRSTLEVEL

DO
  SimPlay NumPlayers, Speed, Objects$
  IF ExitSign = 2 OR ExitSign = 3 OR ExitSign = -3 THEN
    IF StillWantsToPlay = 0 THEN EXIT DO ELSE CurLevel = FRSTLEVEL
  END IF
  IF ExitSign = -2 THEN GetInputs NumPlayers, PlaySpeed$, Speed: GOSUB SetScreen
LOOP
   
WIDTH 80, 25
COLOR 7, 0: CLS
SYSTEM

SetComputer:
RANDOMIZE TIMER
DEF SEG = 0: POKE 1047, &H20
RESTORE letters: FOR a = 1 TO 1: READ Letter(a): NEXT a
RESTORE normal: FOR a = 1 TO 7: READ ColorTable(a): NEXT a
RETURN

normal: DATA  15,   7,   12,    1,   14,    13,     0
letters:
'Colors - Dialogs-f, b Walls Ground snake1 snake2  Hole

SetScreen:
WIDTH 80, 50
VIEW PRINT
LOCATE , , 0
RETURN

DEFSNG A-Z
SUB Center (Row%, text$)
  LOCATE Row%, 41 - (LEN(text$) \ 2): PRINT text$;
END SUB

DEFINT A-Z
SUB Character (Object$)
SELECT CASE Object$
CASE "SNAKE"
CASE "NUMBER"
CASE "HOLE"
END SELECT
END SUB

SUB EraseSnake (snake() AS Snaketype, snakeBod() AS SnakeBody, snakeNum, Mode)

  IF Mode THEN
    FOR c = 0 TO 9
      FOR b = snake(snakeNum).length - c TO 0 STEP -10
        tail = (snake(snakeNum).head + MAXSNAKELENGTH - b) MOD MAXSNAKELENGTH
        Set snakeBod(tail, snakeNum).Row, snakeBod(tail, snakeNum).Col, 0, ColorTable(4)
      NEXT b
    NEXT c
  ELSE
    FOR b = snake(snakeNum).length TO 0 STEP -1
      FOR d = 1 TO 500: NEXT d
      tail = (snake(snakeNum).head + MAXSNAKELENGTH - b) MOD MAXSNAKELENGTH
      Set snakeBod(tail, snakeNum).Row, snakeBod(tail, snakeNum).Col, 0, ColorTable(4)
    NEXT b
  END IF
END SUB

SUB GetInputs (NumPlayers, PreSpeed$, RealSpeed)

  WIDTH 80, 25
  COLOR 7, 0: CLS
  LOCATE , , 1

  LOCATE 5, 25: PRINT "How many players (1 or 2)? ";
  DO
    num$ = INKEY$
    IF num$ = CHR$(27) THEN LOCATE 25, 1: SYSTEM
  LOOP UNTIL num$ = "1" OR num$ = "2" OR num$ = "*"
  PRINT num$
  Player$(1) = "Sammy": Player$(2) = "Jamie"
  NumPlayers = VAL(num$)
 
  Center 9, "1   = Just Hatched    "
  Center 10, "50  = Pretty Good     "
  Center 11, "80  = Natural Snake   "
  Center 12, "100 = Mad Serpent     "
  IF PreSpeed$ = "" THEN PreSpeed$ = "20"
  LOCATE 8, 26: PRINT "Skill level (1 to 100)? " + PreSpeed$; : SLEEP
  DO
    LOCATE 8, 50: PRINT SPACE$(30);
    LOCATE 8, 50: INPUT "", PlaySpeed$
  LOOP UNTIL VAL(PlaySpeed$) <= 100
  IF PlaySpeed$ = "" THEN PlaySpeed$ = PreSpeed$ ELSE PreSpeed$ = PlaySpeed$
  PlaySpeed = VAL(PlaySpeed$): RealSpeed = PlaySpeed
  RealSpeed = (100 - RealSpeed) * 2 + 1

  startTime# = TIMER
  FOR i# = 1 TO 1000: NEXT i#
  stopTime# = TIMER
  RealSpeed = RealSpeed * .5 / (stopTime# - startTime#)

END SUB

SUB InitColors
    
  colr = ColorTable(4)
  FOR Row = 1 TO 50
  FOR Col = 1 TO 80
    Arena(Row, Col).pcolor = colr
    Arena(Row, Col).Layer = 0
    Arena(Row, Col).char = &HDB
  NEXT Col, Row

  COLOR , colr: CLS
    
  FOR Col = 1 TO 80
    Set 3, Col, 1, ColorTable(3)
    Set 50, Col, 1, ColorTable(3)
  NEXT Col

  FOR Row = 4 TO 49
    Set Row, 1, 1, ColorTable(3)
    Set Row, 80, 1, ColorTable(3)
  NEXT Row

END SUB

SUB Intro
  SCREEN 0: WIDTH 80, 25
  COLOR 15, 0: CLS
  LOCATE , , 0

  Center 3, "S  a  m  m  y ! "
  COLOR 7
  Center 5, "Original (Nibbles) Copyright Microsoft Corporation 1990"
  Center 7, "Sammy is a game for one or two players. Navigate your snakes around the"
  Center 8, "obstacle course trying to eat up all the numbers while avoiding running"
  Center 9, "into walls, other snakes, or yourself. With each number your snake eats,"
  Center 10, "it gets gets longer, making it harder to control. When you get all nine,"
  Center 11, "a hole will appear that you must go down to get to the next level..."
  Center 14, "ÚÄÄÄ General ÄÄÄ¿ÚÄÄÄÄÄ Player 1 ÄÄÄÄÄÄÄÂÄÄÄÄÄ Player 2 ÄÄÄÄÄÄÄ¿"
  Center 15, "³               ³³        (Up)          ³        (Up)          ³"
  Center 16, "³ Space - Pause ³³          " + CHR$(24) + "           ³          W           ³"
  Center 17, "³  Home - Menu  ³³ (Left) " + CHR$(27) + "   " + CHR$(26) + " (Right) ³ (Left) A   D (Right) ³"
  Center 18, "³   Esc - Quit  ³³          " + CHR$(25) + "           ³          S           ³"
  Center 19, "³               ³³       (Down)         ³       (Down)         ³"
  Center 20, "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ"
  Center 24, "Press any key to continue"
  PLAY "MBT160O1L8CDEDCDL4ECC"
  SparklePause
    
END SUB

SUB Level (WhatToDO, PreLevel, sammy() AS Snaketype)
    
SELECT CASE (WhatToDO)
CASE STARTOVER: CurLevel = FRSTLEVEL
CASE NEXTLEVEL: CurLevel = PreLevel + 1
CASE GOTOLEVEL: CurLevel = PreLevel
END SELECT

sammy(1).head = 1
sammy(1).length = 2
sammy(1).alive = TRUE
sammy(2).head = 1
sammy(2).length = 2
sammy(2).alive = TRUE
Players(1).alive = TRUE
Players(2).alive = TRUE

InitColors
    
SELECT CASE CurLevel
CASE 1
  sammy(1).Row = 25: sammy(2).Row = 25
  sammy(1).Col = 50: sammy(2).Col = 30
  sammy(1).direction = 4: sammy(2).direction = 3
CASE 2
  FOR i = 20 TO 60
    Set 25, i, 1, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 60: sammy(2).Col = 20
  sammy(1).direction = 3: sammy(2).direction = 4
CASE 3
  FOR i = 10 TO 40
    Set i, 20, 1, ColorTable(3)
    Set i, 60, 1, ColorTable(3)
  NEXT i
  sammy(1).Row = 25: sammy(2).Row = 25
  sammy(1).Col = 50: sammy(2).Col = 30
  sammy(1).direction = 1: sammy(2).direction = 2
CASE 4
  FOR i = 4 TO 30
    Set i, 20, 1, ColorTable(3)
    Set 53 - i, 60, 1, ColorTable(3)
  NEXT i
  FOR i = 2 TO 40
    Set 38, i, 1, ColorTable(3)
    Set 15, 81 - i, 1, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 60: sammy(2).Col = 20
  sammy(1).direction = 3: sammy(2).direction = 4
CASE 5
  FOR i = 4 TO 49 STEP 2
    Set i, 40, 1, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 65: sammy(2).Col = 15
  sammy(1).direction = 2: sammy(2).direction = 1
CASE 6
  FOR i = 13 TO 39
    Set i, 21, 1, ColorTable(3)
    Set i, 59, 1, ColorTable(3)
  NEXT i
  FOR i = 23 TO 57
    Set 11, i, 1, ColorTable(3)
    Set 41, i, 1, ColorTable(3)
  NEXT i
  sammy(1).Row = 25: sammy(2).Row = 25
  sammy(1).Col = 50: sammy(2).Col = 30
  sammy(1).direction = 1: sammy(2).direction = 2
CASE 7
  FOR i = 6 TO 47
    Set i, i, 1, ColorTable(3)
    Set i, i + 28, 1, ColorTable(3)
  NEXT i
  sammy(1).Row = 40: sammy(2).Row = 15
  sammy(1).Col = 75: sammy(2).Col = 5
  sammy(1).direction = 1: sammy(2).direction = 2
CASE 8
  FOR i = 4 TO 49
    IF i > 30 OR i < 23 THEN
      Set i, 10, 1, ColorTable(3)
      Set i, 20, 1, ColorTable(3)
      Set i, 30, 1, ColorTable(3)
      Set i, 40, 1, ColorTable(3)
      Set i, 50, 1, ColorTable(3)
      Set i, 60, 1, ColorTable(3)
      Set i, 70, 1, ColorTable(3)
    END IF
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 65: sammy(2).Col = 15
  sammy(1).direction = 2: sammy(2).direction = 1
CASE 9
  FOR i = 4 TO 40
    Set i, 10, 1, ColorTable(3)
    Set 53 - i, 20, 1, ColorTable(3)
    Set i, 30, 1, ColorTable(3)
    Set 53 - i, 40, 1, ColorTable(3)
    Set i, 50, 1, ColorTable(3)
    Set 53 - i, 60, 1, ColorTable(3)
    Set i, 70, 1, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 65: sammy(2).Col = 15
  sammy(1).direction = 2: sammy(2).direction = 1
CASE 10
CASE 11
  FOR i = 4 TO 49 STEP 2
    Set i, 10, 1, ColorTable(3)
    Set i + 1, 20, 1, ColorTable(3)
    Set i, 30, 1, ColorTable(3)
    Set i + 1, 40, 1, ColorTable(3)
    Set i, 50, 1, ColorTable(3)
    Set i + 1, 60, 1, ColorTable(3)
    Set i, 70, 1, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 65: sammy(2).Col = 15
  sammy(1).direction = 2: sammy(2).direction = 1
CASE 12
  FOR i = 1 TO 38
    Set 26, i, 1, ColorTable(3)
    Set 26, 80 - i, 1, ColorTable(3)
  NEXT i
  FOR i = 3 TO 24
    Set i, 40, 1, ColorTable(3)
    Set 52 - i, 40, 1, ColorTable(3)
  NEXT i
  sammy(1).Row = 7: sammy(2).Row = 43
  sammy(1).Col = 60: sammy(2).Col = 20
  sammy(1).direction = 3: sammy(2).direction = 4
CASE ELSE
  FOR i = 7 TO 45: Set i, 41, 1, ColorTable(3): NEXT i
  FOR i = 2 TO 39
    Set 26, i, 1, ColorTable(3)
    Set 26, i + 41, 1, ColorTable(3)
  NEXT i
  FOR i = 1 TO 22
    Set 2 + i, 42 - i, 1, ColorTable(3)
    Set 27 + i, 63 - i, 1, ColorTable(3)
    Set 2 + i, 40 + i, 1, ColorTable(3)
    Set 27 + i, 19 + i, 1, ColorTable(3)
  NEXT i
  sammy(1).Row = 5: sammy(2).Row = 48
  sammy(1).Col = 46: sammy(2).Col = 37
  sammy(1).direction = 4: sammy(2).direction = 3
END SELECT
END SUB

SUB MessagePause (text$)

  IF LEN(text$) >= 20 THEN Show$ = LEFT$(text$, 20) ELSE Show$ = LEFT$(SPACE$((20 - LEN(text$)) \ 2) + text$ + SPACE$(16), 20)
  COLOR ColorTable(1), ColorTable(2)
  Center 23, STRING$(24, 219)
  Center 24, "Û" + SPACE$(22) + "Û"
  Center 25, "Û " + Show$ + " Û"
  Center 26, "Û" + SPACE$(22) + "Û"
  Center 27, STRING$(24, 219)
  WHILE INKEY$ <> "": WEND
  WHILE INP(96) = 57: Kbd$ = INKEY$: WEND
  DO: Kbd$ = INKEY$: LOOP UNTIL Kbd$ = CHR$(13) OR Kbd$ = " "
   
  FOR v = 23 TO 27
    FOR h = 29 TO 52
      Pixel v, h
    NEXT h
  NEXT v

END SUB

SUB Pixel (Row, Col)
 COLOR Arena(Row, Col).pcolor: LOCATE Row, Col: PRINT CHR$(Arena(Row, Col).char);
END SUB

FUNCTION PointIsThere (Row, Col, Layer)
  IF Row > 0 AND Row < 51 AND Col > 0 AND Col < 81 THEN
    IF Arena(Row, Col).Layer > Layer THEN PointIsThere = TRUE
  END IF
END FUNCTION

SUB PrintScore (NumPlayers, score1, score2, lives1, lives2)
 COLOR 15, ColorTable(4)

 IF NumPlayers = 2 THEN
  LOCATE 1, 57 - LEN(Player$(2))
  PRINT USING "##### Score ## Lives Ä "; score2; lives2;
  PRINT Player$(2);
  Players(2).lives = lives2
  Players(2).score = score2
 END IF

 Center 1, "<< Level Ä" + STR$(CurLevel) + " >>"
 LOCATE 1, 1
 PRINT Player$(1);
 PRINT USING " Ä Lives ## Score" + LEFT$(STR$(score1) + "    ", 5); lives1
 Players(1).lives = lives1
 Players(1).score = score1
END SUB

SUB Set (Row, Col, Layer, ncolor)
  IF Row > 0 THEN
    Arena(Row, Col).pcolor = ncolor
    Arena(Row, Col).Layer = Layer
    LOCATE Row, Col: COLOR ncolor: PRINT CHR$(Arena(Row, Col).char);
  END IF
END SUB

SUB ShowGrid
  FOR v = 1 TO 50: FOR h = 1 TO 80: COLOR Arena(v, h).pcolor: LOCATE v, h: PRINT CHR$(Arena(v, h).char); : NEXT h, v
END SUB

SUB SimPlay (NumPlayers, Speed, Objects$)

  ExitSign = 0
  DIM sammyBody(MAXSNAKELENGTH - 1, 1 TO 2) AS SnakeBody
  DIM sammy(1 TO 2) AS Snaketype
  Players(1).lives = 4: Players(1).score = 0
  Players(2).lives = 4: Players(2).score = 0
  sammy(1).Speed = 1: sammy(1).scolr = ColorTable(5)
  sammy(2).Speed = 1: sammy(2).scolr = ColorTable(6)

  Level SAMELEVEL, CurLevel, sammy()
  startRow1 = sammy(1).Row: startCol1 = sammy(1).Col
  startRow2 = sammy(2).Row: startCol2 = sammy(2).Col

  MessagePause "Level" + STR$(CurLevel)
  curSpeed = Speed
  gameOver = FALSE
  DO
    IF NumPlayers = 1 THEN sammy(2).Row = 0
       
    number = 1
    nonum = TRUE
    count = 0

    playerDied = FALSE
    PrintScore NumPlayers, Players(1).score, Players(2).score, Players(1).lives, Players(2).lives
    PLAY "T160O1>L20CDEDCDL10ECC"

    DO
      IF count AND count < 5 THEN
        COLOR , ColorTable(4)
        SELECT CASE count
        CASE 1: char = 176
        CASE 2: char = 177
        CASE 3: char = 178
        CASE 4: char = ASC(RIGHT$(STR$(number), 1))
        END SELECT
        Arena(NumberRow, NumberCol).char = char
        Set NumberRow, NumberCol, 0, ColorTable(1)
        count = count + 1
      END IF
      IF nonum = TRUE THEN
        DO
          NumberRow = INT(RND(1) * 46) + 4
          NumberCol = INT(RND(1) * 80) + 1
        LOOP UNTIL NOT PointIsThere(NumberRow, NumberCol, 0)
        nonum = FALSE
        count = 1
      END IF
           
      FOR a# = 1 TO curSpeed:  NEXT a#

      DEF SEG = 0: Kbrd = PEEK(1047)
      IF Kbrd AND 16 THEN FOR t = 1 TO NumPlayers: sammy(t).Speed = 0: NEXT t
      IF (Kbrd AND 15) = 15 THEN ShowGrid
      Kbd$ = INKEY$
      SELECT CASE UCASE$(Kbd$)
      CASE "W": IF sammy(2).direction <> 2 THEN sammy(2).direction = 1: sammy(2).Speed = 1
      CASE "S": IF sammy(2).direction <> 1 THEN sammy(2).direction = 2: sammy(2).Speed = 1
      CASE "A": IF sammy(2).direction <> 4 THEN sammy(2).direction = 3: sammy(2).Speed = 1
      CASE "D": IF sammy(2).direction <> 3 THEN sammy(2).direction = 4: sammy(2).Speed = 1
      CASE CHR$(0) + "H": IF sammy(1).direction <> 2 THEN sammy(1).direction = 1: sammy(1).Speed = 1
      CASE CHR$(0) + "P": IF sammy(1).direction <> 1 THEN sammy(1).direction = 2: sammy(1).Speed = 1
      CASE CHR$(0) + "K": IF sammy(1).direction <> 4 THEN sammy(1).direction = 3: sammy(1).Speed = 1
      CASE CHR$(0) + "M": IF sammy(1).direction <> 3 THEN sammy(1).direction = 4: sammy(1).Speed = 1
      CASE " ": MessagePause "Game Paused"
      CASE CHR$(0) + "G": ExitSign = -2: EXIT SUB
      CASE CHR$(27): ExitSign = -3: EXIT SUB
      CASE ELSE
      END SELECT
           
      FOR a = 1 TO NumPlayers
        IF sammy(a).Speed THEN
          SELECT CASE sammy(a).direction
          CASE 1: sammy(a).Row = sammy(a).Row - 1
          CASE 2: sammy(a).Row = sammy(a).Row + 1
          CASE 3: sammy(a).Col = sammy(a).Col - 1
          CASE 4: sammy(a).Col = sammy(a).Col + 1
          END SELECT
        END IF
        IF sammy(a).Row = NumberRow AND sammy(a).Col = NumberCol THEN
          IF sammy(a).length < (MAXSNAKELENGTH - 30) THEN sammy(a).length = sammy(a).length + number * 4
          Players(a).score = Players(a).score + number
          PrintScore NumPlayers, Players(1).score, Players(2).score, Players(1).lives, Players(2).lives
          Arena(NumberRow, NumberCol).char = 219
          Set NumberRow, NumberCol, 0, 4
          IF number = 9 THEN
            PLAY "MBO3L64>C<GEC<GEC<GEC"
            Set NumberRow, NumberCol, 1, sammy(a).scolr
            FOR b = 1 TO NumPlayers
              IF b = a THEN EraseSnake sammy(), sammyBody(), a, 0 ELSE EraseSnake sammy(), sammyBody(), b, 1
            NEXT b
            Set NumberRow, NumberCol, 0, ColorTable(7)
            IF CurLevel = LASTLEVEL THEN ExitSign = 3: EXIT SUB ELSE Level NEXTLEVEL, CurLevel, sammy()
            PrintScore NumPlayers, Players(1).score, Players(2).score, Players(1).lives, Players(2).lives
            MessagePause "Level" + STR$(CurLevel)
            IF NumPlayers = 1 THEN sammy(2).Row = 0
            number = 1
          ELSE PLAY "MBO0L20>EEC": number = number + 1
          END IF
          nonum = TRUE
        END IF
      NEXT a

      FOR a = 1 TO NumPlayers
        IF (PointIsThere(sammy(a).Row, sammy(a).Col, 0) OR (sammy(1).Row = sammy(2).Row AND sammy(1).Col = sammy(2).Col)) AND sammy(a).Speed > 0 THEN
          playerDied = TRUE
          sammy(a).alive = FALSE
          Players(a).alive = FALSE
        ELSEIF sammy(a).Speed THEN
          sammy(a).head = (sammy(a).head + 1) MOD MAXSNAKELENGTH
          sammyBody(sammy(a).head, a).Row = sammy(a).Row
          sammyBody(sammy(a).head, a).Col = sammy(a).Col
          sammyBody(sammy(a).head, a).clr = Arena(sammy(a).Row, sammy(a).Col).pcolor
          tail = (sammy(a).head + MAXSNAKELENGTH - sammy(a).length) MOD MAXSNAKELENGTH
          Set sammyBody(tail, a).Row, sammyBody(tail, a).Col, 0, sammyBody(tail, a).clr
          sammyBody(tail, a).Row = 0
          Set sammy(a).Row, sammy(a).Col, 1, sammy(a).scolr
        END IF
      NEXT a
           
    LOOP UNTIL playerDied

    PLAY "MBO0L32EFGEFDC"
       
   FOR a = 1 TO NumPlayers
    EraseSnake sammy(), sammyBody(), a, 1
    IF Players(a).alive = FALSE THEN
     Players(a).score = Players(a).score - 10
     IF Players(a).lives = 0 THEN ExitSign = 2 ELSE Players(a).lives = Players(a).lives - 1
     PrintScore NumPlayers, Players(1).score, Players(2).score, Players(1).lives, Players(2).lives
     MessagePause Player$(a) + " Died!"
    END IF
   NEXT a
   
   IF ExitSign = 2 THEN PLAY "MBO1L7CCCL14D#DDCC<B>C": EXIT DO
   Level SAMELEVEL, 0, sammy()
  LOOP
 
' 1 = Get Level  2 = Game Over  3 = BeatGame
'-1 = Pause     -2 = Menu      -3 = Exit
END SUB

SUB SnakeLetter (Letr$, Urow, Lcol, Drow, Rcol)
Drow = 0: Rcol = 0
SELECT CASE Letr$
CASE "A": Trl$ = "`" + CHR$(0) + "Ã×U‚î"
CASE "B": Trl$ = "##jUýŒè"
CASE "C": Trl$ = "¢YuÏ"
CASE "D": Trl$ = "`" + CHR$(0) + "ðw•é"
CASE "E": Trl$ = "jý©Õï"
CASE "F": Trl$ = "jõ§"
CASE "G": Trl$ = "¢YÝ3º"
CASE "H": Trl$ = CHR$(0) + "U5ðÕ" + CHR$(0) + ""
CASE "M": Trl$ = "`" + CHR$(0) + "ÌUÜU"
CASE " ":
CASE ELSE: EXIT SUB
END SELECT

IF LEN(Trl$) < 2 THEN EXIT SUB
Row = Urow + (ASC(Trl$) AND 240) \ 16: Col = (ASC(Trl$) AND 15) + Lcol
IF Urow <> -1 THEN Set Row, Col, 1, 14
FOR Show = 2 TO LEN(Trl$)
 Letr = ASC(MID$(Trl$, Show, 1))
 Dir = Letr AND 3: GOSUB ChngDir
 Dir = (Letr AND 12) \ 4: GOSUB ChngDir
 Dir = (Letr AND 48) \ 16: GOSUB ChngDir
 Dir = (Letr AND 192) \ 64: GOSUB ChngDir
NEXT Show
EXIT SUB

ChngDir:
 SELECT CASE Dir
 CASE 0: Row = Row - 1
 CASE 1: Row = Row + 1: IF Row > Urow THEN Urow = Row
 CASE 2: Col = Col - 1
 CASE 3: Col = Col + 1: IF Col > Rcol THEN Rcol = Col
 END SELECT
 IF Urow <> -1 THEN Set Row, Col, 1, 14
RETURN
END SUB

SUB SparklePause

  COLOR 5, 0
  a$ = "ß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßßß  ßß"
  WHILE INKEY$ <> "": WEND

  WHILE INKEY$ = ""
    FOR a = 1 TO 5
      LOCATE 1, 1: PRINT MID$(a$, a, 80);
      LOCATE 22, 1: PRINT MID$(a$, 6 - a, 80);

      FOR b = 1 TO 21
        c = (a + b) MOD 5
        IF c = 1 THEN
          LOCATE b, 80
          PRINT "Û";
          LOCATE 22 - b, 1
          PRINT "Û";
        ELSE
          LOCATE b, 80
          PRINT " ";
          LOCATE 22 - b, 1
          PRINT " ";
        END IF
      NEXT b
    NEXT a
  WEND

END SUB

FUNCTION StillWantsToPlay

  COLOR ColorTable(1), ColorTable(2)
  WHILE INKEY$ > "": WEND
  IF ExitSign = -3 THEN
    Center 23, STRING$(32, 219)
    Center 24, "Û" + SPACE$(30) + "Û"
    Center 25, "Û    Restart or Quit? (R/Q)    Û"
    Center 26, "Û" + SPACE$(30) + "Û"
    Center 27, STRING$(32, 219)
    DO: Kbd$ = UCASE$(INKEY$): LOOP UNTIL Kbd$ > "" AND INSTR("RQ" + CHR$(27) + CHR$(13), Kbd$)
    IF Kbd$ = "R" OR Kbd$ = CHR$(13) THEN StillWantsToPlay = TRUE ELSE StillWantsToPlay = FALSE
    EXIT FUNCTION
  END IF
   
  Center 21, STRING$(33, 219)
  Center 22, "Û" + SPACE$(31) + "Û"
  Center 24, "Û" + SPACE$(31) + "Û"
  IF ExitSign = 3 THEN
    PLAY "MBT160O1L10CDEDCDL5ECGP2T160O1>L10CDEDCDL5ECC"
    Center 23, "Û  Congrats! You beat the game. Û"
    Center 25, "Û  You must be a natural Sammy! Û"
    ExitSign = -2
  ELSE
    Center 23, "Û       G A M E   O V E R       Û"
    Center 25, "Û     Game ended on level" + LEFT$(STR$(CurLevel) + "  ", 3) + "    Û"
  END IF
  Center 26, "Û" + SPACE$(31) + "Û"
  Center 27, "Û      Play Again?   (Y/N)      Û"
  Center 28, "Û" + SPACE$(31) + "Û"
  Center 29, STRING$(33, 219)

  DO: Kbd$ = UCASE$(INKEY$): LOOP UNTIL Kbd$ > "" AND INSTR("YN" + CHR$(27) + CHR$(13), Kbd$)
  IF Kbd$ = "Y" OR Kbd$ = CHR$(13) THEN StillWantsToPlay = TRUE ELSE StillWantsToPlay = FALSE

END FUNCTION

