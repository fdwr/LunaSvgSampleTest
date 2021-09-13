'                         Q B a s i c   N i b b l e s
'                   Copyright (C) Microsoft Corporation 1990
'
' To run this game, press Shift+F5.
' To exit QBasic, press Alt, F, X.

DEFINT A-Z

TYPE SnakeBody: Row AS INTEGER: Col AS INTEGER: Lay AS INTEGER: END TYPE
TYPE Snaketype
  head AS INTEGER
  length AS INTEGER
  Row AS INTEGER
  Col AS INTEGER
  Lay AS INTEGER
  direction AS INTEGER
  Speed AS INTEGER
  scolr AS INTEGER
  alive AS INTEGER
END TYPE

TYPE Player: lives AS INTEGER: score AS INTEGER: alive AS INTEGER: END TYPE

DECLARE SUB MessagePause (text$)
DECLARE SUB PrintScore (NumPlayers, score1, score2, lives1, lives2)
DECLARE SUB Intro ()
DECLARE SUB GetInputs (NumPlayers, PlaySpeed$, Speed)
DECLARE SUB SimPlay (NumPlayers, Speed, Objects$)
DECLARE SUB SetOn (Row, Col, Lay, Ncolor, Char, Thik)
DECLARE SUB Pixel (Row, Col)
DECLARE SUB ShowGrid ()
DECLARE SUB Center (Row, text$)
DECLARE SUB SparklePause ()
DECLARE SUB Level (WhatToDO, PreLevel, Sammy() AS Snaketype)
DECLARE SUB InitColors ()
DECLARE SUB EraseSnake (snake() AS ANY, snakeBod() AS ANY, snakeNum, Mode)
DECLARE SUB SnakeLetter (Letr$, Urow, Lcol, Drow, Rcol)
DECLARE SUB SetOff (Row, Col, Lay)
DECLARE FUNCTION StillWantsToPlay ()
DECLARE FUNCTION PointIsThere (Row, Col, Layer)

CONST TRUE = -1, FALSE = 0
CONST MAXSNAKELENGTH = 1000

CONST FRSTLEVEL = 1, LASTLEVEL = 13, SAMELEVEL = -2, NEXTLEVEL = -3, GOTOLEVEL = -4

DIM SHARED Arena(1 TO 50, 1 TO 80, 0 TO 4) AS INTEGER, Objects$, CurLevel, Letter(1 TO 26)
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
   
WIDTH 80, 25: COLOR 7, 0: CLS
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
WIDTH 80, 50: VIEW PRINT: LOCATE , , 0
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
        IF snakeBod(tail, snakeNum).Row THEN SetOff snakeBod(tail, snakeNum).Row, snakeBod(tail, snakeNum).Col, snakeBod(tail, snakeNum).Lay
      NEXT b
    NEXT c
  ELSE
    FOR b = snake(snakeNum).length TO 0 STEP -1
      tail = (snake(snakeNum).head + MAXSNAKELENGTH - b) MOD MAXSNAKELENGTH
      IF snakeBod(tail, snakeNum).Row THEN SetOff snakeBod(tail, snakeNum).Row, snakeBod(tail, snakeNum).Col, snakeBod(tail, snakeNum).Lay
    NEXT b
  END IF
END SUB

SUB GetInputs (NumPlayers, PreSpeed$, RealSpeed)

  WIDTH 80, 25: COLOR 7, 0: CLS : LOCATE , , 1

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
    
  colr = &HDB OR ColorTable(4) * 1024
  FOR Row = 1 TO 50
  FOR Col = 1 TO 80
    Arena(Row, Col, 0) = 0
    Arena(Row, Col, 1) = colr
    Arena(Row, Col, 2) = colr
    Arena(Row, Col, 3) = colr
    Arena(Row, Col, 4) = colr
  NEXT Col, Row

  COLOR , ColorTable(4): CLS
    
  FOR Col = 1 TO 80
    SetOn 3, Col, 1, ColorTable(3), 219, 3
    SetOn 50, Col, 1, ColorTable(3), 219, 3
  NEXT Col

  FOR Row = 4 TO 49
    SetOn Row, 1, 1, ColorTable(3), 219, 3
    SetOn Row, 80, 1, ColorTable(3), 219, 3
  NEXT Row

END SUB

SUB Intro
  SCREEN 0: WIDTH 80, 25: COLOR 15, 0: CLS : LOCATE , , 0

  Center 3, "S  a  m  m  y ! "
  COLOR 7: Center 5, "Original (Nibbles) Copyright Microsoft Corporation 1990"
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

SUB Level (WhatToDO, PreLevel, Sammy() AS Snaketype)
    
SELECT CASE (WhatToDO)
CASE STARTOVER: CurLevel = FRSTLEVEL
CASE NEXTLEVEL: CurLevel = PreLevel + 1
CASE GOTOLEVEL: CurLevel = PreLevel
END SELECT

Sammy(1).head = 1: Sammy(1).length = 2: Sammy(1).Lay = 1: Sammy(1).alive = TRUE
Sammy(2).head = 1: Sammy(2).length = 2: Sammy(2).Lay = 1: Sammy(2).alive = TRUE
Players(1).alive = TRUE: Players(2).alive = TRUE

InitColors

SELECT CASE CurLevel
CASE 1
 Sammy(1).Row = 25: Sammy(2).Row = 25
 Sammy(1).Col = 50: Sammy(2).Col = 30
 Sammy(1).direction = 4: Sammy(2).direction = 3
CASE 2
 FOR i = 20 TO 60
  SetOn 25, i, 1, ColorTable(3), 254, 3
 NEXT i
 Sammy(1).Row = 7: Sammy(2).Row = 43
 Sammy(1).Col = 60: Sammy(2).Col = 20
 Sammy(1).direction = 3: Sammy(2).direction = 4
CASE 3
 FOR i = 10 TO 40
  SetOn i, 20, 1, ColorTable(3), 219, 3
  SetOn i, 60, 1, ColorTable(3), 219, 3
 NEXT i
 Sammy(1).Row = 25: Sammy(2).Row = 25
 Sammy(1).Col = 50: Sammy(2).Col = 30
 Sammy(1).direction = 1: Sammy(2).direction = 2
CASE 4
 FOR i = 4 TO 30
  SetOn i, 20, 1, ColorTable(3), 219, 3
  SetOn 53 - i, 60, 1, ColorTable(3), 219, 3
 NEXT i
 FOR i = 2 TO 40
  SetOn 38, i, 1, ColorTable(3), 219, 3
  SetOn 15, 81 - i, 1, ColorTable(3), 219, 3
 NEXT i
 Sammy(1).Row = 7: Sammy(2).Row = 43
 Sammy(1).Col = 60: Sammy(2).Col = 20
 Sammy(1).direction = 3: Sammy(2).direction = 4
CASE 5
 FOR i = 4 TO 49 STEP 2
  SetOn i, 40, 1, ColorTable(3), 219, 3
 NEXT i
 Sammy(1).Row = 7: Sammy(2).Row = 43
 Sammy(1).Col = 65: Sammy(2).Col = 15
 Sammy(1).direction = 2: Sammy(2).direction = 1
CASE 6
 FOR i = 13 TO 39
  SetOn i, 21, 1, ColorTable(3), 219, 3
  SetOn i, 59, 1, ColorTable(3), 219, 3
 NEXT i
 FOR i = 23 TO 57
  SetOn 11, i, 1, ColorTable(3), 219, 3
  SetOn 41, i, 1, ColorTable(3), 219, 3
 NEXT i
 Sammy(1).Row = 25: Sammy(2).Row = 25
 Sammy(1).Col = 50: Sammy(2).Col = 30
 Sammy(1).direction = 1: Sammy(2).direction = 2
CASE 7
 FOR i = 6 TO 47
  SetOn i, i, 1, ColorTable(3), 219, 3
  SetOn i, i + 28, 1, ColorTable(3), 219, 3
 NEXT i
 Sammy(1).Row = 40: Sammy(2).Row = 15
 Sammy(1).Col = 75: Sammy(2).Col = 5
 Sammy(1).direction = 1: Sammy(2).direction = 2
CASE 8
 FOR i = 4 TO 49
  IF i > 30 OR i < 23 THEN
   SetOn i, 10, 1, ColorTable(3), 219, 3
   SetOn i, 20, 1, ColorTable(3), 219, 3
   SetOn i, 30, 1, ColorTable(3), 219, 3
   SetOn i, 40, 1, ColorTable(3), 219, 3
   SetOn i, 50, 1, ColorTable(3), 219, 3
   SetOn i, 60, 1, ColorTable(3), 219, 3
  END IF
 NEXT i
 Sammy(1).Row = 7: Sammy(2).Row = 43
 Sammy(1).Col = 65: Sammy(2).Col = 15
 Sammy(1).direction = 2: Sammy(2).direction = 1
CASE 9
 FOR i = 4 TO 40
  SetOn i, 10, 1, ColorTable(3), 219, 3
  SetOn 53 - i, 20, 1, ColorTable(3), 219, 3
  SetOn i, 30, 1, ColorTable(3), 219, 3
  SetOn 53 - i, 40, 1, ColorTable(3), 219, 3
  SetOn i, 50, 1, ColorTable(3), 219, 3
  SetOn 53 - i, 60, 1, ColorTable(3), 219, 3
  SetOn i, 70, 2, ColorTable(3), 219, 3
 NEXT i
 Sammy(1).Row = 7: Sammy(2).Row = 43
 Sammy(1).Col = 65: Sammy(2).Col = 15
 Sammy(1).direction = 2: Sammy(2).direction = 1
CASE 10
CASE 11
 FOR i = 4 TO 49 STEP 2
  SetOn i, 10, 1, ColorTable(3), 219, 3
  SetOn i + 1, 20, 1, ColorTable(3), 219, 3
  SetOn i, 30, 1, ColorTable(3), 219, 3
  SetOn i + 1, 40, 1, ColorTable(3), 219, 3
  SetOn i, 50, 1, ColorTable(3), 219, 3
  SetOn i + 1, 60, 1, ColorTable(3), 219, 3
  SetOn i, 70, 1, ColorTable(3), 219, 3
 NEXT i
 Sammy(1).Row = 7: Sammy(2).Row = 43
 Sammy(1).Col = 65: Sammy(2).Col = 15
 Sammy(1).direction = 2: Sammy(2).direction = 1
CASE 12
 FOR i = 1 TO 38
  SetOn 26, i, 1, ColorTable(3), 219, 3
  SetOn 26, 80 - i, 1, ColorTable(3), 219, 3
 NEXT i
 FOR i = 3 TO 24
  SetOn i, 40, 1, ColorTable(3), 219, 3
  SetOn 52 - i, 40, 1, ColorTable(3), 219, 3
 NEXT i
 Sammy(1).Row = 7: Sammy(2).Row = 43
 Sammy(1).Col = 60: Sammy(2).Col = 20
 Sammy(1).direction = 3: Sammy(2).direction = 4
CASE ELSE
 FOR i = 7 TO 45: SetOn i, 41, 1, ColorTable(3), 219, 3: NEXT i
 FOR i = 2 TO 39
  SetOn 26, i, 1, ColorTable(3), 219, 3
  SetOn 26, i + 41, 1, ColorTable(3), 219, 3
 NEXT i
 FOR i = 1 TO 22
  SetOn 2 + i, 42 - i, 1, ColorTable(3), 219, 3
  SetOn 27 + i, 63 - i, 1, ColorTable(3), 219, 3
  SetOn 2 + i, 40 + i, 1, ColorTable(3), 219, 3
  SetOn 27 + i, 19 + i, 1, ColorTable(3), 219, 3
 NEXT i
 Sammy(1).Row = 5: Sammy(2).Row = 48
 Sammy(1).Col = 46: Sammy(2).Col = 37
 Sammy(1).direction = 4: Sammy(2).direction = 3
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
  WHILE INKEY$ <> "": WEND: WHILE INP(96) = 57: Kbd$ = INKEY$: WEND
  DO: Kbd$ = INKEY$: LOOP UNTIL Kbd$ = CHR$(13) OR Kbd$ = " "
   
  FOR v = 23 TO 27: FOR h = 29 TO 52: Pixel v, h: NEXT h, v

END SUB

SUB Pixel (Row, Col)
 Lay = Arena(Row, Col, 0): LOCATE Row, Col
 IF Lay THEN COLOR Arena(Row, Col, Lay) \ 1024, 1: PRINT CHR$(Arena(Row, Col, Lay) AND 255);  ELSE COLOR 1: PRINT "Û";
END SUB

FUNCTION PointIsThere (Row, Col, Lay)
  IF Row > 0 AND Row < 51 AND Col > 0 AND Col < 81 THEN
    IF (Arena(Row, Col, Lay) AND 768) = 768 THEN PointIsThere = TRUE
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

SUB SetOff (Row, Col, Lay)
  IF Lay = 0 THEN EXIT SUB
  Arena(Row, Col, Lay) = Arena(Row, Col, Lay) OR 768 XOR 768
  Layer = 0
  FOR Find = 4 TO 1 STEP -1
   IF Arena(Row, Col, Find) AND 768 THEN Layer = Find: EXIT FOR
  NEXT Find
  Arena(Row, Col, 0) = Layer
  Pixel Row, Col
END SUB

SUB SetOn (Row, Col, Lay, colr, Char, Thik)
 IF Lay >= Arena(Row, Col, 0) THEN Arena(Row, Col, 0) = Lay: COLOR colr, 1: LOCATE Row, Col: PRINT CHR$(Char);
 Arena(Row, Col, Lay) = (colr * 1024 OR ((Thik AND 3) * 256)) OR Char
END SUB

SUB ShowGrid
  FOR v = 1 TO 50
   FOR h = 1 TO 80
    Lay = Arena(v, h, 0)
    IF Lay THEN COLOR Arena(v, h, Lay) \ 1024: LOCATE v, h: PRINT CHR$(Arena(v, h, Lay) AND 255);  ELSE COLOR 1: PRINT "Û";
  NEXT h, v
END SUB

SUB SimPlay (NumPlayers, Speed, Objects$)

  ExitSign = 0
  REDIM sammyBody(MAXSNAKELENGTH - 1, 1 TO 2) AS SnakeBody
  DIM Sammy(1 TO 2) AS Snaketype
  Players(1).lives = 4: Players(1).score = 0
  Players(2).lives = 4: Players(2).score = 0
  Sammy(1).Speed = 1: Sammy(1).scolr = ColorTable(5)
  Sammy(2).Speed = 1: Sammy(2).scolr = ColorTable(6)

  Level SAMELEVEL, CurLevel, Sammy()
  startRow1 = Sammy(1).Row: startCol1 = Sammy(1).Col
  startRow2 = Sammy(2).Row: startCol2 = Sammy(2).Col

  MessagePause "Level" + STR$(CurLevel)
  curSpeed = Speed
  gameOver = FALSE
  DO
    IF NumPlayers = 1 THEN Sammy(2).Row = 0
       
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
        CASE 1: Char = 176
        CASE 2: Char = 177
        CASE 3: Char = 178
        CASE 4: Char = ASC(RIGHT$(STR$(number), 1))
        END SELECT
        SetOn NumberRow, NumberCol, 1, ColorTable(1), Char, 1
        count = count + 1
      END IF
      IF nonum = TRUE THEN
        NumberRow = INT(RND(1) * 46) + 4
        NumberCol = INT(RND(1) * 80) + 1
        IF NOT PointIsThere(NumberRow, NumberCol, 1) THEN nonum = FALSE: count = 1
      END IF
           
      FOR a# = 1 TO curSpeed:  NEXT a#

      DEF SEG = 0: Kbrd = PEEK(1047)
      IF Kbrd AND 16 THEN FOR t = 1 TO NumPlayers: Sammy(t).Speed = 0: NEXT t
      IF (Kbrd AND 15) = 15 THEN ShowGrid
      FOR t = 1 TO NumPlayers
       Kbd$ = INKEY$
       SELECT CASE UCASE$(Kbd$)
       CASE "W": IF Sammy(2).direction <> 2 THEN Sammy(2).direction = 1: Sammy(2).Speed = 1
       CASE "S": IF Sammy(2).direction <> 1 THEN Sammy(2).direction = 2: Sammy(2).Speed = 1
       CASE "A": IF Sammy(2).direction <> 4 THEN Sammy(2).direction = 3: Sammy(2).Speed = 1
       CASE "D": IF Sammy(2).direction <> 3 THEN Sammy(2).direction = 4: Sammy(2).Speed = 1
       CASE CHR$(0) + "H": IF Sammy(1).direction <> 2 THEN Sammy(1).direction = 1: Sammy(1).Speed = 1
       CASE CHR$(0) + "P": IF Sammy(1).direction <> 1 THEN Sammy(1).direction = 2: Sammy(1).Speed = 1
       CASE CHR$(0) + "K": IF Sammy(1).direction <> 4 THEN Sammy(1).direction = 3: Sammy(1).Speed = 1
       CASE CHR$(0) + "M": IF Sammy(1).direction <> 3 THEN Sammy(1).direction = 4: Sammy(1).Speed = 1
       CASE " ": ExitSign = -1: MessagePause "Game Paused"
       CASE CHR$(0) + "G": ExitSign = -2: EXIT SUB
       CASE CHR$(27): ExitSign = -3: EXIT SUB
       END SELECT
       IF ExitSign THEN EXIT FOR
      NEXT t
           
      FOR a = 1 TO NumPlayers
        IF Sammy(a).Speed THEN
          SELECT CASE Sammy(a).direction
          CASE 1: Sammy(a).Row = Sammy(a).Row - 1
          CASE 2: Sammy(a).Row = Sammy(a).Row + 1
          CASE 3: Sammy(a).Col = Sammy(a).Col - 1
          CASE 4: Sammy(a).Col = Sammy(a).Col + 1
          END SELECT
        END IF
        IF Sammy(a).Row = NumberRow AND Sammy(a).Col = NumberCol THEN
          IF Sammy(a).length < (MAXSNAKELENGTH - 30) THEN Sammy(a).length = Sammy(a).length + number * 4
          Players(a).score = Players(a).score + number
          PrintScore NumPlayers, Players(1).score, Players(2).score, Players(1).lives, Players(2).lives
          SetOn NumberRow, NumberCol, 1, 4, 219, 1
          IF number = 9 THEN
            PLAY "MBO3L64>C<GEC<GEC<GEC"
            SetOn NumberRow, NumberCol, 1, Sammy(a).scolr, 219, 1
            FOR b = 1 TO NumPlayers
              IF b = a THEN EraseSnake Sammy(), sammyBody(), a, 0 ELSE EraseSnake Sammy(), sammyBody(), b, 1
            NEXT b
            SetOn NumberRow, NumberCol, 0, ColorTable(7), 219, 1
            IF CurLevel = LASTLEVEL THEN ExitSign = 3: EXIT SUB ELSE Level NEXTLEVEL, CurLevel, Sammy()
            PrintScore NumPlayers, Players(1).score, Players(2).score, Players(1).lives, Players(2).lives
            MessagePause "Level" + STR$(CurLevel)
            IF NumPlayers = 1 THEN Sammy(2).Row = 0
            number = 1
          ELSE PLAY "MBO0L20>EEC": number = number + 1
          END IF
          nonum = TRUE
        END IF
      NEXT a

      FOR a = 1 TO NumPlayers
        IF (PointIsThere(Sammy(a).Row, Sammy(a).Col, Sammy(a).Lay) OR (Sammy(1).Row = Sammy(2).Row AND Sammy(1).Col = Sammy(2).Col)) AND Sammy(a).Speed > 0 THEN
          playerDied = TRUE
          Sammy(a).alive = FALSE
          Players(a).alive = FALSE
        ELSEIF Sammy(a).Speed THEN
          Sammy(a).head = (Sammy(a).head + 1) MOD MAXSNAKELENGTH
          sammyBody(Sammy(a).head, a).Row = Sammy(a).Row
          sammyBody(Sammy(a).head, a).Col = Sammy(a).Col
          sammyBody(Sammy(a).head, a).Lay = Sammy(a).Lay
          tail = (Sammy(a).head + MAXSNAKELENGTH - Sammy(a).length) MOD MAXSNAKELENGTH
          IF sammyBody(tail, a).Row THEN SetOff sammyBody(tail, a).Row, sammyBody(tail, a).Col, sammyBody(tail, a).Lay
          sammyBody(tail, a).Row = 0
          SetOn Sammy(a).Row, Sammy(a).Col, Sammy(a).Lay, Sammy(a).scolr, 219, 2
        END IF
      NEXT a
           
    LOOP UNTIL playerDied

    PLAY "MBO0L32EFGEFDC"
       
   FOR a = 1 TO NumPlayers
    EraseSnake Sammy(), sammyBody(), a, 1
    IF Players(a).alive = FALSE THEN
     Players(a).score = Players(a).score - 10
     IF Players(a).lives = 0 THEN ExitSign = 2 ELSE Players(a).lives = Players(a).lives - 1
     PrintScore NumPlayers, Players(1).score, Players(2).score, Players(1).lives, Players(2).lives
     MessagePause Player$(a) + " Died!"
    END IF
   NEXT a
   
   IF ExitSign = 2 THEN PLAY "MBO1L7CCCL14D#DDCC<B>C": EXIT DO
   Level SAMELEVEL, 0, Sammy()
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
IF Urow <> -1 THEN SetOn Row, Col, 1, 14, 219, 3
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
 IF Urow <> -1 THEN SetOn Row, Col, 1, 14, 219, 3
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
   
  Center 19, STRING$(33, 219)
  Center 20, "Û" + SPACE$(31) + "Û"
  Center 22, "Û" + SPACE$(31) + "Û"
  Center 23, STRING$(33, 219)
  Center 24, "Û" + SPACE$(31) + "Û"
  IF ExitSign = 3 THEN
    PLAY "MBT160O1L10CDEDCDL5ECGP2T160O1>L10CDEDCDL5ECC"
    Center 21, "Û  Congrats! You beat the game. Û"
    Center 25, "Û  You must be a natural Sammy! Û"
    ExitSign = -2
  ELSE
    Center 21, "Û       G A M E   O V E R       Û"
    Center 25, "Û     Game ended on level" + LEFT$(STR$(CurLevel) + "  ", 3) + "    Û"
  END IF
  Center 26, "Û" + SPACE$(31) + "Û"
  Center 27, "Û      Play Again?   (Y/N)      Û"
  Center 28, "Û" + SPACE$(31) + "Û"
  Center 29, STRING$(33, 219)

  DO: Kbd$ = UCASE$(INKEY$): LOOP UNTIL Kbd$ > "" AND INSTR("YN" + CHR$(27) + CHR$(13), Kbd$)
  IF Kbd$ = "Y" OR Kbd$ = CHR$(13) THEN StillWantsToPlay = TRUE ELSE StillWantsToPlay = FALSE

END FUNCTION

