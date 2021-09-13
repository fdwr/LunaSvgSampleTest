DEFINT A-Z
'09-06-97 Ziel setup
CLS
SCREEN 0
OPEN "ziel.cfg" FOR INPUT AS #1
INPUT #1, sprts
INPUT #1, sprtt
INPUT #1, sd
INPUT #1, qbasic1
CLOSE
IF sprts = 0 THEN sprts = 1
IF sprtt = 0 THEN sprtt = 1
LOCATE 1, 1: COLOR 12, 0: PRINT "LOADING!"
COLOR 0, 1
LOCATE 1, 1
PRINT "                                    Ziel  Setup                                 "
COLOR 12, 0
LOCATE 23, 7: PRINT "Use arrow keys to move cursor and space to chance setup of cursor."
COLOR 15, 0
LOCATE 19, 1: PRINT "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿"
LOCATE 20, 1: PRINT "³                                                                              ³"
LOCATE 21, 1: PRINT "³                                                                              ³"
LOCATE 22, 1: PRINT "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ"
n = 0
GOSUB sd:
GOSUB ts:
GOSUB cs:
GOSUB qb1
GOSUB qt:
GOSUB er
t = 1
n = 1: GOSUB bar
DO
a$ = INKEY$
IF a$ = "8" THEN GOSUB up:
IF a$ = "2" THEN GOSUB down:
IF a$ = CHR$(0) + CHR$(72) THEN GOSUB up:
IF a$ = CHR$(0) + CHR$(80) THEN GOSUB down:
IF a$ = " " THEN GOSUB button
COLOR 7, 0
LOOP

button:
GOSUB er
SELECT CASE t
CASE 1: IF sd = 1 THEN sd = 0:  ELSE sd = 1
GOSUB sd
CASE 2:
  SELECT CASE sprtt
  CASE 1: sprtt = 2
  CASE 2: sprtt = 3
  CASE 3: sprtt = 1
  END SELECT
  GOSUB ts
CASE 3:
  SELECT CASE sprts
  CASE 1: sprts = 2
  CASE 2: sprts = 3
  CASE 3: sprts = 1
  END SELECT
  GOSUB cs
CASE 4:
  SELECT CASE qbasic1
  CASE 1: qbasic1 = 0
  CASE 0: qbasic1 = 1
  END SELECT
  GOSUB qb1
CASE 5: GOTO qt2
END SELECT
RETURN
qt2:
OPEN "ziel.cfg" FOR OUTPUT AS #1
PRINT #1, sprts
PRINT #1, sprtt
PRINT #1, sd
PRINT #1, qbasic1
CLOSE
COLOR 7, 0
CLS
SYSTEM
RETURN
er:
COLOR 0, 0
LOCATE 20, 3: PRINT "                                                                            "
LOCATE 21, 3: PRINT "                                                                            "
RETURN
bar:
IF t = 1 THEN GOSUB sd:
IF t = 2 THEN GOSUB ts:
IF t = 3 THEN GOSUB cs:
IF t = 4 THEN GOSUB qb1:
IF t = 5 THEN GOSUB qt:
RETURN
up:
n = 0: GOSUB bar
GOSUB er
t = t - 1
IF t = 0 THEN t = 5
n = 1: GOSUB bar
RETURN
down:
n = 0: GOSUB bar
GOSUB er
t = t + 1
IF t = 6 THEN t = 1
n = 1: GOSUB bar
RETURN
sd:
COLOR 9, n
LOCATE 7, 40
PRINT "Sound"
COLOR 9, 0
IF sd = 0 THEN LOCATE 8, 41: PRINT "OFF": LOCATE 20, 3: PRINT "No Sound Blaster sound effects"
IF sd = 1 THEN LOCATE 8, 41: PRINT "ON!": LOCATE 20, 3: PRINT "Sound Blaster sound effects"
RETURN
ts:
COLOR 9, n
LOCATE 10, 36
PRINT "Tile  Sprites"
LOCATE 11, 40: COLOR 9, 0
SELECT CASE sprtt
CASE 1: PRINT "Mode 1"
LOCATE 20, 3: PRINT "Uses PSET to place bitmaps on screen. Disadvantage is it has a black"
LOCATE 21, 3: PRINT "box around the sprite. If you have a slow PC, pick this one."
CASE 2: PRINT "Mode 2"
LOCATE 20, 3: PRINT "Uses PSET place pixels on screen, slower than mode 1 but looks cleaner."
LOCATE 21, 3: PRINT "Disadvantage slowest."
CASE 3: PRINT "Mode 3"
LOCATE 20, 3: PRINT "Like Mode 2, but faster. Disadvantage is you can't run this mode in QB"
LOCATE 21, 3: PRINT "Uses POKE instead of PSET for plotting pixels"
END SELECT
RETURN
cs:
COLOR 9, n
LOCATE 13, 34
PRINT "Character Sprites"
LOCATE 14, 40: COLOR 9, 0
SELECT CASE sprts
CASE 1: PRINT "Mode 1"
LOCATE 20, 3: PRINT "Uses PSET to place bitmaps on screen. Disadvantage is it has a black"
LOCATE 21, 3: PRINT "box around the sprite. If you have a slow PC, pick this one."
CASE 2: PRINT "Mode 2"
LOCATE 20, 3: PRINT "Uses PSET place pixels on screen, slower than mode 1 but looks cleaner."
LOCATE 21, 3: PRINT "Disadvantage slowest."
CASE 3: PRINT "Mode 3"
LOCATE 20, 3: PRINT "Like Mode 2, but faster. Disadvantage is you can't run this mode in QB"
LOCATE 21, 3: PRINT "Uses POKE instead of PSET for plotting pixels"
END SELECT
RETURN
qb1:
COLOR 9, n
LOCATE 16, 34
PRINT "   QB  or QBasic "
LOCATE 17, 40: COLOR 9, 0
SELECT CASE qbasic1
CASE 0: PRINT "  QB  "
LOCATE 20, 3: PRINT "Everything is available. If you are running Quick Basic and not Qbasic "
LOCATE 21, 3: PRINT "then run this, since Quick Basic gives you more memory."
CASE 1: PRINT "Qbasic"
LOCATE 20, 3: PRINT "Due to lack to mem in Qbasic, you can't read signs or talk to people.  "
LOCATE 21, 3: PRINT "But besides that, it will still run."
END SELECT
RETURN
qt:
COLOR 12, n
LOCATE 18, 40
PRINT "Quit"
COLOR 9, 0
LOCATE 20, 3: PRINT "Quits and saves setup"
RETURN

