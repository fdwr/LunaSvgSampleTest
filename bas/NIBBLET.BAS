DEFINT A-Z
TYPE snakeBody
row AS INTEGER
col AS INTEGER
END TYPE
TYPE snaketype
head AS INTEGER
length AS INTEGER
row AS INTEGER
col AS INTEGER
direction AS INTEGER
lives AS INTEGER
score AS INTEGER
scolor AS INTEGER
alive AS INTEGER
END TYPE
TYPE arenaType
realRow AS INTEGER
acolor AS INTEGER
sister AS INTEGER
END TYPE
DECLARE SUB SpacePause (text$)
DECLARE SUB PrintScore (NumPlayers%, score1%, score2%, lives1%, lives2%)
DECLARE SUB Intro ()
DECLARE SUB GetInputs (NumPlayers, speed, diff$, monitor$, Names$())
DECLARE SUB DrawScreen ()
DECLARE SUB PlayNibbles (NumPlayers, speed, diff$)
DECLARE SUB Set (row, col, acolor)
DECLARE SUB Center (row, text$)
DECLARE SUB DoIntro ()
DECLARE SUB Initialize ()
DECLARE SUB SparklePause ()
DECLARE SUB Level (WhatToDO, sammy() AS snaketype)
DECLARE SUB InitColors ()
DECLARE SUB EraseSnake (snake() AS ANY, snakeBod() AS ANY, snakeNum%)
DECLARE FUNCTION StillWantsToPlay ()
DECLARE FUNCTION PointIsThere (row, col, backColor)
CONST TRUE = -1
CONST FALSE = NOT TRUE
CONST MAXSNAKELENGTH = 1000
CONST STARTOVER = 1
CONST SAMELEVEL = 2
CONST NEXTLEVEL = 3
DIM SHARED arena(1 TO 50, 1 TO 80) AS arenaType
DIM SHARED curLevel, colorTable(10)
DIM SHARED Names$(1 TO 2)
RANDOMIZE TIMER
GOSUB ClearKeyLocks
Intro
GetInputs NumPlayers, speed, diff$, monitor$, Names$()
GOSUB SetColors
DrawScreen
DO
PlayNibbles NumPlayers, speed, diff$
LOOP WHILE StillWantsToPlay
GOSUB RestoreKeyLocks
COLOR 15, 0
CLS
END
ClearKeyLocks:
DEF SEG = 0
KeyFlags = PEEK(1047)
POKE 1047, &H0
DEF SEG
RETURN
RestoreKeyLocks:
DEF SEG = 0
POKE 1047, KeyFlags
DEF SEG
RETURN
SetColors:
IF monitor$ = "M" THEN
RESTORE mono
ELSE
RESTORE normal
END IF
FOR a = 1 TO 6
READ colorTable(a)
NEXT a
RETURN
mono: DATA 15,7,7,0,15,0
normal: DATA 14,13,12,1,15,4
END

SUB Center (row, text$)
LOCATE row, 41 - LEN(text$) / 2
PRINT text$;
END SUB

SUB DrawScreen
VIEW PRINT
COLOR colorTable(1), colorTable(4)
CLS
Center 1, "Nibbles!"
Center 11, "Initializing Playing Field..."
FOR row = 1 TO 50
FOR col = 1 TO 80
arena(row, col).realRow = INT((row + 1) / 2)
arena(row, col).sister = (row MOD 2) * 2 - 1
NEXT col
NEXT row
END SUB

SUB EraseSnake (snake() AS snaketype, snakeBod() AS snakeBody, snakeNum)
FOR c = 0 TO 9
FOR b = snake(snakeNum).length - c TO 0 STEP -10
tail = (snake(snakeNum).head + MAXSNAKELENGTH - b) MOD MAXSNAKELENGTH
Set snakeBod(tail, snakeNum).row, snakeBod(tail, snakeNum).col, colorTable(4)
NEXT b
NEXT c
END SUB

SUB GetInputs (NumPlayers, speed, diff$, monitor$, Names$())
COLOR 7, 0
CLS
DO
LOCATE 5, 47: PRINT SPACE$(34);
LOCATE 5, 20
INPUT "How many players (1 or 2)"; num$
LOOP UNTIL VAL(num$) = 1 OR VAL(num$) = 2
NumPlayers = VAL(num$)
FOR GetNames = 1 TO NumPlayers
DO
LOCATE 5 + GetNames, 47: PRINT SPACE$(34);
LOCATE 5 + GetNames, 21: PRINT "Name of player" + STR$(GetNames);
INPUT ""; Names$(GetNames)
LOOP UNTIL VAL(num$) = 1 OR VAL(num$) = 2
NEXT GetNames
LOCATE 9, 21: PRINT "Skill level (1 to 100)"
LOCATE 10, 22: PRINT "1   = Novice"
LOCATE 11, 22: PRINT "90  = Expert"
LOCATE 12, 22: PRINT "100 = Twiddle Fingers"
LOCATE 13, 15: PRINT "(Computer speed may affect your skill level)"
DO
LOCATE 9, 44: PRINT SPACE$(35);
LOCATE 9, 43
INPUT gamespeed$
LOOP UNTIL VAL(gamespeed$) >= 1 AND VAL(gamespeed$) <= 100
speed = VAL(gamespeed$)
speed = (100 - speed) * 2 + 1
DO
LOCATE 15, 56: PRINT SPACE$(25);
LOCATE 15, 15
INPUT "Increase game speed during play (Y or N)"; diff$
diff$ = UCASE$(diff$)
LOOP UNTIL diff$ = "Y" OR diff$ = "N"
DO
LOCATE 17, 46: PRINT SPACE$(34);
LOCATE 17, 17
INPUT "Monochrome or color monitor (M or C)"; monitor$
monitor$ = UCASE$(monitor$)
LOOP UNTIL monitor$ = "M" OR monitor$ = "C"
startTime# = TIMER             ' Calculate speed of system
FOR i# = 1 TO 1000: NEXT i#    ' and do some compensation
stopTime# = TIMER
speed = speed * .5 / (stopTime# - startTime#)
END SUB

SUB InitColors
FOR row = 1 TO 50
FOR col = 1 TO 80
arena(row, col).acolor = colorTable(4)
NEXT col
NEXT row
CLS
FOR col = 1 TO 80
Set 3, col, colorTable(3)
Set 50, col, colorTable(3)
NEXT col
FOR row = 4 TO 49
Set row, 1, colorTable(3)
Set row, 80, colorTable(3)
NEXT row
END SUB

SUB Intro
SCREEN 0
WIDTH 80, 25
COLOR 15, 0
LOCATE , , 0
CLS
Center 4, "Q B a s i c   N i b b l e s"
COLOR 7
Center 6, "Copyright (C) Microsoft Corporation 1990"
Center 8, "Nibbles is a game for one or two players.  Navigate your snakes"
Center 9, "around the game board trying to eat up numbers while avoiding"
Center 10, "running into walls or other snakes.  The more numbers you eat up,"
Center 11, "the more points you gain and the longer your snake becomes."
Center 13, " Game Controls "
Center 15, "  General             Player 1               Player 2    "
Center 16, "                        (Up)                   (Up)      "
Center 17, "Space - Pause              " + CHR$(24) + "                      W         "
Center 18, "                     (Left) " + CHR$(27) + "   " + CHR$(26) + " (Right)   (Left) A   D (Right)  "
Center 19, "                         " + CHR$(25) + "                      S       "
Center 20, "                       (Down)                 (Down)     "
Center 24, "Press any key to continue"
PLAY "MBT160O1L8CDEDCDL4ECC"
SparklePause
END SUB

SUB Level (WhatToDO, sammy() AS snaketype) STATIC
SELECT CASE (WhatToDO)
CASE STARTOVER
curLevel = 1
CASE NEXTLEVEL
curLevel = curLevel + 1
END SELECT
sammy(1).head = 1
sammy(1).length = 2
sammy(1).alive = TRUE
sammy(2).head = 1
sammy(2).length = 2
sammy(2).alive = TRUE
InitColors
SELECT CASE curLevel
CASE 1
sammy(1).row = 25: sammy(2).row = 25
sammy(1).col = 50: sammy(2).col = 30
sammy(1).direction = 4: sammy(2).direction = 3
CASE 2
FOR i = 20 TO 60
Set 25, i, colorTable(3)
NEXT i
sammy(1).row = 7: sammy(2).row = 43
sammy(1).col = 60: sammy(2).col = 20
sammy(1).direction = 3: sammy(2).direction = 4
CASE 3
FOR i = 10 TO 40
Set i, 20, colorTable(3)
Set i, 60, colorTable(3)
NEXT i
sammy(1).row = 25: sammy(2).row = 25
sammy(1).col = 50: sammy(2).col = 30
sammy(1).direction = 1: sammy(2).direction = 2
CASE 4
FOR i = 4 TO 30
Set i, 20, colorTable(3)
Set 53 - i, 60, colorTable(3)
NEXT i
FOR i = 2 TO 40
Set 38, i, colorTable(3)
Set 15, 81 - i, colorTable(3)
NEXT i
sammy(1).row = 7: sammy(2).row = 43
sammy(1).col = 60: sammy(2).col = 20
sammy(1).direction = 3: sammy(2).direction = 4
CASE 5
FOR i = 13 TO 39
Set i, 21, colorTable(3)
Set i, 59, colorTable(3)
NEXT i
FOR i = 23 TO 57
Set 11, i, colorTable(3)
Set 41, i, colorTable(3)
NEXT i
sammy(1).row = 25: sammy(2).row = 25
sammy(1).col = 50: sammy(2).col = 30
sammy(1).direction = 1: sammy(2).direction = 2
CASE 6
FOR i = 4 TO 49
IF i > 30 OR i < 23 THEN
Set i, 10, colorTable(3)
Set i, 20, colorTable(3)
Set i, 30, colorTable(3)
Set i, 40, colorTable(3)
Set i, 50, colorTable(3)
Set i, 60, colorTable(3)
Set i, 70, colorTable(3)
END IF
NEXT i
sammy(1).row = 7: sammy(2).row = 43
sammy(1).col = 65: sammy(2).col = 15
sammy(1).direction = 2: sammy(2).direction = 1
CASE 7
FOR i = 4 TO 49 STEP 2
Set i, 40, colorTable(3)
NEXT i
sammy(1).row = 7: sammy(2).row = 43
sammy(1).col = 65: sammy(2).col = 15
sammy(1).direction = 2: sammy(2).direction = 1
CASE 8
FOR i = 4 TO 40
Set i, 10, colorTable(3)
Set 53 - i, 20, colorTable(3)
Set i, 30, colorTable(3)
Set 53 - i, 40, colorTable(3)
Set i, 50, colorTable(3)
Set 53 - i, 60, colorTable(3)
Set i, 70, colorTable(3)
NEXT i
sammy(1).row = 7: sammy(2).row = 43
sammy(1).col = 65: sammy(2).col = 15
sammy(1).direction = 2: sammy(2).direction = 1
CASE 9
FOR i = 6 TO 47
Set i, i, colorTable(3)
Set i, i + 28, colorTable(3)
NEXT i
sammy(1).row = 40: sammy(2).row = 15
sammy(1).col = 75: sammy(2).col = 5
sammy(1).direction = 1: sammy(2).direction = 2
CASE ELSE
FOR i = 4 TO 49 STEP 2
Set i, 10, colorTable(3)
Set i + 1, 20, colorTable(3)
Set i, 30, colorTable(3)
Set i + 1, 40, colorTable(3)
Set i, 50, colorTable(3)
Set i + 1, 60, colorTable(3)
Set i, 70, colorTable(3)
NEXT i
sammy(1).row = 7: sammy(2).row = 43
sammy(1).col = 65: sammy(2).col = 15
sammy(1).direction = 2: sammy(2).direction = 1
END SELECT
END SUB

SUB PlayNibbles (NumPlayers, speed, diff$)
DIM sammyBody(MAXSNAKELENGTH - 1, 1 TO 2) AS snakeBody
DIM sammy(1 TO 2) AS snaketype
sammy(1).lives = 5
sammy(1).score = 0
sammy(1).scolor = colorTable(1)
sammy(2).lives = 5
sammy(2).score = 0
sammy(2).scolor = colorTable(2)
Level STARTOVER, sammy()
startRow1 = sammy(1).row: startCol1 = sammy(1).col
startRow2 = sammy(2).row: startCol2 = sammy(2).col
curSpeed = speed
SpacePause "     Level" + STR$(curLevel) + ",  Push Space"
GameOver = FALSE
DO
IF NumPlayers = 1 THEN sammy(2).row = 0
number = 1
nonum = TRUE
PlayerDied = FALSE
PrintScore NumPlayers, sammy(1).score, sammy(2).score, sammy(1).lives, sammy(2).lives
PLAY "T160O1>L20CDEDCDL10ECC"
DO
IF nonum = TRUE THEN
DO
NumberRow = INT(RND(1) * 47 + 3)
NumberCol = INT(RND(1) * 78 + 2)
sisterRow = NumberRow + arena(NumberRow, NumberCol).sister
LOOP UNTIL NOT PointIsThere(NumberRow, NumberCol, colorTable(4)) AND NOT PointIsThere(sisterRow, NumberCol, colorTable(4))
NumberRow = arena(NumberRow, NumberCol).realRow
nonum = FALSE
COLOR colorTable(1), colorTable(4)
LOCATE NumberRow, NumberCol
PRINT RIGHT$(STR$(number), 1);
count = 0
END IF
FOR a# = 1 TO curSpeed:  NEXT a#
kbd$ = INKEY$
SELECT CASE kbd$
CASE "w", "W": IF sammy(2).direction <> 2 THEN sammy(2).direction = 1
CASE "s", "S": IF sammy(2).direction <> 1 THEN sammy(2).direction = 2
CASE "a", "A": IF sammy(2).direction <> 4 THEN sammy(2).direction = 3
CASE "d", "D": IF sammy(2).direction <> 3 THEN sammy(2).direction = 4
CASE CHR$(0) + "H": IF sammy(1).direction <> 2 THEN sammy(1).direction = 1
CASE CHR$(0) + "P": IF sammy(1).direction <> 1 THEN sammy(1).direction = 2
CASE CHR$(0) + "K": IF sammy(1).direction <> 4 THEN sammy(1).direction = 3
CASE CHR$(0) + "M": IF sammy(1).direction <> 3 THEN sammy(1).direction = 4
CASE " ": SpacePause " Game Paused ... Push Space  "
CASE "": EXIT SUB
CASE ELSE
END SELECT
FOR a = 1 TO NumPlayers
SELECT CASE sammy(a).direction
CASE 1: sammy(a).row = sammy(a).row - 1
CASE 2: sammy(a).row = sammy(a).row + 1
CASE 3: sammy(a).col = sammy(a).col - 1
CASE 4: sammy(a).col = sammy(a).col + 1
END SELECT
IF NumberRow = INT((sammy(a).row + 1) / 2) AND NumberCol = sammy(a).col THEN
PLAY "MBO0L16>CCCE"
IF sammy(a).length < (MAXSNAKELENGTH - 30) THEN
sammy(a).length = sammy(a).length + number * 4
END IF
sammy(a).score = sammy(a).score + number
PrintScore NumPlayers, sammy(1).score, sammy(2).score, sammy(1).lives, sammy(2).lives
number = number + 1
IF number = 10 THEN
EraseSnake sammy(), sammyBody(), 1
EraseSnake sammy(), sammyBody(), 2
LOCATE NumberRow, NumberCol: PRINT " "
Level NEXTLEVEL, sammy()
PrintScore NumPlayers, sammy(1).score, sammy(2).score, sammy(1).lives, sammy(2).lives
SpacePause "     Level" + STR$(curLevel) + ",  Push Space"
IF NumPlayers = 1 THEN sammy(2).row = 0
number = 1
IF diff$ = "P" THEN speed = speed - 10: curSpeed = speed
END IF
nonum = TRUE
IF curSpeed < 1 THEN curSpeed = 1
END IF
NEXT a
FOR a = 1 TO NumPlayers
IF PointIsThere(sammy(a).row, sammy(a).col, colorTable(4)) OR (sammy(1).row = sammy(2).row AND sammy(1).col = sammy(2).col) THEN
PLAY "MBO0L32EFGEFDC"
COLOR , colorTable(4)
LOCATE NumberRow, NumberCol
PRINT " "
PlayerDied = TRUE
sammy(a).alive = FALSE
sammy(a).lives = sammy(a).lives - 1
ELSE
sammy(a).head = (sammy(a).head + 1) MOD MAXSNAKELENGTH
sammyBody(sammy(a).head, a).row = sammy(a).row
sammyBody(sammy(a).head, a).col = sammy(a).col
tail = (sammy(a).head + MAXSNAKELENGTH - sammy(a).length) MOD MAXSNAKELENGTH
Set sammyBody(tail, a).row, sammyBody(tail, a).col, colorTable(4)
sammyBody(tail, a).row = 0
Set sammy(a).row, sammy(a).col, sammy(a).scolor
END IF
NEXT a
LOOP UNTIL PlayerDied
curSpeed = speed    ' reset speed to initial value
FOR a = 1 TO NumPlayers
EraseSnake sammy(), sammyBody(), a
IF sammy(a).alive = FALSE THEN
sammy(a).score = sammy(a).score - 10
PrintScore NumPlayers, sammy(1).score, sammy(2).score, sammy(1).lives, sammy(2).lives
IF a = 1 THEN
SpacePause " Dwayne Dies! Push Space! --->"
ELSE
SpacePause " <---- Scott Dies! Push Space "
END IF
END IF
NEXT a
Level SAMELEVEL, sammy()
PrintScore NumPlayers, sammy(1).score, sammy(2).score, sammy(1).lives, sammy(2).lives
LOOP UNTIL sammy(1).lives = 0 AND sammy(2).lives = 0
END SUB

FUNCTION PointIsThere (row, col, acolor)
IF row <> 0 THEN
IF arena(row, col).acolor <> acolor THEN
PointIsThere = TRUE
ELSE
PointIsThere = FALSE
END IF
END IF
END FUNCTION

SUB PrintScore (NumPlayers, score1, score2, lives1, lives2)
COLOR 15, colorTable(4)
IF NumPlayers = 2 THEN
LOCATE 1, 1: PRINT LEFT$(Names$(2) + "ƒƒƒƒƒƒ", 7) + "> "; "Lives:" + STR$(lives2) + "  " + RIGHT$(STR$(score2) + "     ", 8);
END IF
LOCATE 1, 48: PRINT LEFT$(Names$(1) + "ƒƒƒƒƒƒ", 7) + "> "; "Lives:" + STR$(lives1) + "  " + RIGHT$(STR$(score1) + "     ", 8);
END SUB

SUB Set (row, col, acolor)
IF row <> 0 THEN
arena(row, col).acolor = acolor
realRow = arena(row, col).realRow
topFlag = arena(row, col).sister + 1 / 2
sisterRow = row + arena(row, col).sister
sisterColor = arena(sisterRow, col).acolor
LOCATE realRow, col
IF acolor = sisterColor THEN
COLOR acolor, acolor
PRINT CHR$(219);
ELSE
IF topFlag THEN
IF acolor > 7 THEN
COLOR acolor, sisterColor
PRINT CHR$(223);
ELSE
COLOR sisterColor, acolor
PRINT CHR$(220);
END IF
ELSE
IF acolor > 7 THEN
COLOR acolor, sisterColor
PRINT CHR$(220);
ELSE
COLOR sisterColor, acolor
PRINT CHR$(223);
END IF
END IF
END IF
END IF
END SUB

SUB SpacePause (text$)
COLOR colorTable(5), colorTable(6)
Center 11, "€ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€"
Center 12, "€ " + LEFT$(text$ + SPACE$(29), 29) + " €"
Center 13, "€‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€"
WHILE INKEY$ <> "": WEND
WHILE INKEY$ <> " ": WEND
COLOR 15, colorTable(4)
FOR i = 21 TO 26    ' Restore the screen background
FOR j = 24 TO 56
Set i, j, arena(i, j).acolor
NEXT j
NEXT i
END SUB

SUB SparklePause
COLOR 13, 0
a$ = "*    *    *    *    *    *    *    *    *    *    *    *    *    *    *    *    *    "
WHILE INKEY$ <> "": WEND
WHILE INKEY$ = ""
FOR a = 1 TO 5
LOCATE 1, 1
PRINT MID$(a$, a, 80);
LOCATE 22, 1
PRINT MID$(a$, 6 - a, 80);
FOR b = 2 TO 21
c = (a + b) MOD 5
IF c = 1 THEN
LOCATE b, 80
PRINT "*";
LOCATE 23 - b, 1
PRINT "*";
ELSE
LOCATE b, 80
PRINT " ";
LOCATE 23 - b, 1
PRINT " ";
END IF
NEXT b
NEXT a
WEND
END SUB

FUNCTION StillWantsToPlay
COLOR colorTable(5), colorTable(6)
Center 10, "€ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ€"
Center 11, "€       G A M E   O V E R       €"
Center 12, "€                               €"
Center 13, "€      Play Again?   (Y/N)      €"
Center 14, "€‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹€"
WHILE INKEY$ <> "": WEND
DO
kbd$ = UCASE$(INKEY$)
LOOP UNTIL kbd$ = "Y" OR kbd$ = "N"
COLOR 15, colorTable(4)
Center 10, SPACE$(33)
Center 11, SPACE$(33)
Center 12, SPACE$(33)
Center 13, SPACE$(33)
Center 14, SPACE$(33)
IF kbd$ = "Y" THEN
StillWantsToPlay = TRUE
ELSE
StillWantsToPlay = FALSE
COLOR 7, 0
CLS
END IF
END FUNCTION

