DECLARE SUB fx.scroll ()
DECLARE SUB fx.explosion (xp AS INTEGER, yp AS INTEGER, vl AS INTEGER, speed AS INTEGER, way AS INTEGER)
DECLARE SUB fx.anim (word AS STRING, speed AS INTEGER)
DECLARE SUB cntr (txt AS STRING)
DECLARE SUB clock.bonus ()
DECLARE SUB clock ()
DECLARE SUB fx.print (word AS STRING)
DECLARE SUB level ()
DECLARE SUB intro (zx AS INTEGER, zy AS INTEGER)
DECLARE SUB object.wall (x AS INTEGER, y AS INTEGER)
DECLARE SUB action.push (x AS INTEGER, y AS INTEGER, sx AS INTEGER, sy AS INTEGER)
DECLARE SUB fx.color (break AS STRING, bl AS INTEGER, gr AS INTEGER, rd AS INTEGER)
DECLARE SUB player.points (bonus AS INTEGER)
DECLARE SUB object (x AS INTEGER, y AS INTEGER)
DECLARE SUB events (x AS INTEGER, y AS INTEGER)
DECLARE SUB action (x AS INTEGER, y AS INTEGER, sx AS INTEGER, sy AS INTEGER)
DECLARE SUB action.move (x AS INTEGER, y AS INTEGER, sx AS INTEGER, sy AS INTEGER)
DECLARE SUB tile ()
DECLARE SUB object.bowl (x AS INTEGER, y AS INTEGER, col AS INTEGER)
DECLARE SUB object.jewel (x AS INTEGER, y AS INTEGER, col AS INTEGER, jsz AS SINGLE)
DECLARE SUB player.keyboard (sx AS INTEGER, sy AS INTEGER)
DECLARE SUB player.enemy (px AS INTEGER, py AS INTEGER)
DECLARE SUB player.over ()
DECLARE SUB fx.sound (vl AS INTEGER)
DECLARE SUB object.dynamite (x AS INTEGER, y AS INTEGER, lt AS INTEGER)
DECLARE SUB level.setpal ()
DECLARE SUB fx.play (song AS STRING)
DECLARE SUB player.handlepill ()
DECLARE FUNCTION tile.buf% (x AS INTEGER, y AS INTEGER, nr AS INTEGER, tp AS INTEGER)

CONST midx = 320 / 2, midy = 200 / 2 + 4
CONST fsz = 10
CONST tlx = 15, tly = 9

TYPE sprite
 x  AS INTEGER
 y  AS INTEGER
 sx AS INTEGER
 sy AS INTEGER
END TYPE

TYPE layer
 bk AS INTEGER
 fr AS INTEGER
END TYPE

TYPE game
 oldgame   AS INTEGER
 dmds      AS INTEGER
 levelnr   AS INTEGER
 lives     AS INTEGER
 cheatmode AS INTEGER
 sndswitch AS INTEGER
 pill      AS INTEGER
 cherry    AS INTEGER
 gtime     AS INTEGER
 ntime     AS SINGLE
 htime     AS INTEGER
END TYPE

DIM SHARED tl(-tlx - 1 TO tlx + 1, -tly - 1 TO tly + 1) AS layer
DIM SHARED status AS game
DIM plr AS sprite, en(1 TO 4) AS sprite

SCREEN 13
RANDOMIZE TIMER
FOR col% = 0 TO 63
 PALETTE 100 + col%, col%
NEXT
status.sndswitch = 1

DO

 status.oldgame = 0
 IF status.lives = 0 THEN
  intro 2, 3
  status.lives = 4
 END IF

 status.htime = 0
 status.cherry = 0
 status.pill = 0
 plr.x = 0
 plr.y = 3
 status.levelnr = status.levelnr + 1
 level
 status.ntime = TIMER

 DO
 
  clock
  player.keyboard plr.sx, plr.sy
  action plr.x, plr.y, plr.sx, plr.sy
  player.handlepill
  player.enemy plr.x, plr.y
  tile
 
 LOOP UNTIL status.dmds <= 0

 IF status.dmds = 0 THEN
  clock.bonus
  fx.scroll
 ELSE
  status.dmds = 0
 END IF

LOOP
END

1 :
DATA  1,0,0
DATA  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
DATA  3,11, 2, 2, 2, 2, 2, 2, 2, 2, 3,11, 3, 2, 2, 3
DATA  3, 2, 3, 3,33,33,33, 3, 3, 2, 3, 2, 3, 3, 2, 3
DATA  3, 2, 3,19, 0, 2, 2, 2, 3, 2, 3, 2, 2, 2, 2, 3
DATA  3, 2, 3, 0, 0, 3, 3, 2, 3, 2, 3, 3, 3, 3, 2, 3
DATA  3, 2, 3, 2, 2, 2, 3,11, 3, 2, 2, 2, 2, 2, 2, 2
DATA  3, 2, 3, 2, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0
DATA  3, 2, 3, 2, 3, 2, 2, 2, 2, 3, 0, 2, 3, 3, 3, 0
DATA  3, 2, 3, 2, 3, 3, 3, 3, 2, 3, 0, 2, 3, 6, 0, 0
DATA  3, 2, 3, 2, 2, 2, 2, 2, 2, 2, 0, 2, 3, 0, 0, 0
2 :
DATA  1,1,0
DATA  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
DATA  3, 2, 2, 2, 2, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
DATA  3, 2, 2, 2, 0, 3, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0
DATA  3, 2, 2, 0, 0, 5, 0, 3, 3, 3, 3, 3, 3, 3, 3, 0
DATA  3, 2, 2, 2, 2, 3, 0, 3, 2, 2, 2, 2, 2, 2, 2, 2
DATA  3, 3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3
DATA  3,11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
DATA  3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 3, 4, 3, 3
DATA  3, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 3, 0, 6, 2
DATA  3, 0, 0, 0, 0, 0, 3, 3, 3, 4, 3, 3, 3, 0, 0, 0
3 :
DATA  1,0,1
DATA  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
DATA  3,11, 2, 2, 2, 3, 0, 3, 0, 0, 0, 3, 2, 2, 3, 5
DATA  3, 3, 2, 3, 2, 3, 0, 3, 0, 0, 0, 3, 3, 3, 3, 2
DATA  3, 2, 2, 2, 2, 3, 0, 3, 0, 0, 0, 2, 2, 2, 2, 2
DATA  3, 3, 2, 3, 2, 3, 0, 3, 0, 0, 0, 2, 2, 2, 2, 2
DATA  3, 5, 5, 5, 5, 5, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0
DATA  3, 3, 3, 3, 3, 3, 2, 3, 0, 0,11, 0, 3, 0, 3, 0
DATA  3, 2, 3, 6, 3, 0, 0, 0, 0, 0, 2, 0, 3, 0, 3, 3
DATA  3, 2, 3, 3, 3, 0, 0, 0, 0, 0, 2, 0, 3, 0, 0, 0
DATA  3, 2, 2, 2, 2, 0, 0, 0, 0, 0,11, 0, 3, 0, 0, 0
4 :
DATA  0,1,1
DATA  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
DATA  3,11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
DATA  3, 0, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0
DATA  3, 0, 3, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 2, 2, 0
DATA  3, 0, 3, 0, 3, 3, 3, 3, 0, 3, 0, 6, 0, 2, 0, 0
DATA  3, 0, 3, 0, 3, 0,11, 3, 0, 3, 0, 0, 0, 2, 3, 4
DATA  3, 0, 3, 0, 3, 0, 3, 3, 0, 3, 0, 3, 3, 2, 3, 0
DATA  3, 0, 3, 0, 3, 0, 0, 0, 2, 3, 0, 3, 2, 2, 3, 0
DATA  3, 0, 3, 0, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 2
DATA  3, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 3,11, 0, 0, 0
5 :
DATA  1,1,1
DATA  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
DATA  3, 0, 0, 0, 0,17, 0,05, 0, 0, 0, 0, 0, 0, 0, 0
DATA  3, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0
DATA  3, 0,17, 0, 0, 0, 3, 2, 3,11, 0, 0, 0, 3, 0, 0
DATA  3, 0, 0,17, 0, 0, 3, 3, 3, 3, 3, 3, 0, 3, 0, 0
DATA  3, 0, 0, 0,17, 0, 0,20, 0, 0, 0, 0, 0, 3, 0, 0
DATA  3, 2, 2, 2, 2,17, 0,20, 0, 6, 0, 0, 0, 3, 5, 2
DATA  3, 2, 2, 2, 2, 0,17,20, 0, 0, 0, 0, 3, 3, 3, 3
DATA  3, 2, 2, 2, 2, 0, 0,20, 0, 0, 0, 0, 3, 0, 0, 0
DATA  3, 2, 2, 2, 2, 0, 0,20, 0, 0, 0, 0, 0, 0, 0, 0
6 :
DATA  0,1,0
DATA  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
DATA  3, 2, 2, 2, 0, 3, 0, 0, 3, 0, 0, 0, 0, 0, 0,11
DATA  3, 2, 2, 2, 0,20, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0
DATA  3, 2, 2, 2, 0,20, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0
DATA  3, 2, 2, 2, 0,03, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0
DATA  3, 0, 0, 0, 0, 3, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0
DATA  3, 0, 0, 0, 0,31, 0, 0,31, 0, 0, 0, 0, 0, 0, 0
DATA  3, 0, 0, 0, 0, 3, 0, 0, 3, 0, 0, 0, 3, 3, 3, 3
DATA  3, 6, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0
DATA  3, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

'0 :
'DATA  0,0,0
'DATA  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
'DATA  3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
'DATA  3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
'DATA  3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
'DATA  3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
'DATA  3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
'DATA  3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
'DATA  3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
'DATA  3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
'DATA  3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

' empty            '  0
' player           '  1
' silver pill      '  2
' wall             '  3
' movable door     '  4
' unlit dynamite   '  5
' enemy            '  6 -> 10
' gold pill        ' 11
' lit dynamite     ' 12 -> 14
' explosion        ' 15
' bonus pill       ' 16
' box              ' 17 -> 18
' warp             ' 19
' laser            ' 20 -> 30
' door closed      ' 31
' door open        ' 32
' animated wall    ' 33 -> 38

SUB action (x AS INTEGER, y AS INTEGER, sx AS INTEGER, sy AS INTEGER)

SELECT CASE tl(x + sx, y + sy).fr

 CASE 0
  action.move x, y, sx, sy

 CASE 2
  status.dmds = status.dmds - 1
  fx.sound 6
  tl(x + sx, y + sy).fr = 0
  action.move x, y, sx, sy
  player.points 10

 CASE 4
  action.push x, y, sx, sy

 CASE 5
  tl(x + sx, y + sy).fr = 12

 CASE 11
  fx.sound 2
  fx.print "energy"
  tl(x + sx, y + sy).fr = 0
  status.pill = 150
  action.move x, y, sx, sy
  player.points 20

 CASE 16
  fx.sound 5
  tl(x + sx, y + sy).fr = 0
  action.move x, y, sx, sy
  player.points 50
  status.cherry = status.cherry + 1

  IF status.cherry = 4 THEN
   status.cherry = 0
   IF status.lives < 4 THEN
    fx.anim "1 up!", 2
    status.lives = status.lives + 1
    FOR n% = 1 TO status.lives - 1
     object.bowl n% - 8, -tly - 1, 41
    NEXT
   ELSEIF status.gtime < 50 AND status.htime = 0 THEN
    fx.anim "time up!", 2
    status.ntime = TIMER
    status.htime = 1
   ELSE
    fx.anim "bonus!", 2
    player.points 250
   END IF
  END IF

  LOCATE 1, 24: PRINT SPACE$(4)
  FOR nn% = 1 TO status.cherry
   nx% = 2 + nn%: ny% = -tly - 1
   object.bowl nx%, ny%, 140
   LINE (midx + nx% * fsz, midy + ny% * fsz - fsz / 6)-STEP(fsz / 6, -fsz / 7), 10
   LINE (midx + nx% * fsz, midy + ny% * fsz - fsz / 6)-STEP(-fsz / 6, -fsz / 7), 10
  NEXT

 CASE 17
  action.push x, y, sx, sy

 CASE 19
  fx.sound 15
  tl(x, y).fr = 0
  x = x * -1
  y = y * -1
  tl(x, y).fr = 1

 CASE 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30
  player.over

 CASE 31
  fx.sound 5
  tl(x + sx, y + sy).fr = 32

 CASE 32
  fx.sound 6
  tl(x + sx, y + sy).fr = 31

 CASE 33, 34, 35, 36, 37
  fx.sound 9
  player.over

END SELECT

END SUB

SUB action.move (x AS INTEGER, y AS INTEGER, sx AS INTEGER, sy AS INTEGER)

tl(x, y).fr = 0
x = x + sx
y = y + sy
tl(x, y).fr = 1

END SUB

SUB action.push (x AS INTEGER, y AS INTEGER, sx AS INTEGER, sy AS INTEGER)

fx.sound 1
IF tl(x + sx * 2, y + sy * 2).fr = 0 THEN
 SWAP tl(x + sx, y + sy).fr, tl(x + sx * 2, y + sy * 2).fr
END IF

END SUB

SUB clock

STATIC otime AS INTEGER

status.gtime = 100 - (TIMER - status.ntime)

IF status.gtime <> otime THEN
 COLOR 7
 LOCATE 1, 20
 PRINT status.gtime
 otime = status.gtime
 IF status.gtime = 10 THEN
  fx.anim "hurry up", 2
 ELSEIF status.gtime <= 0 THEN
  fx.anim "time out", 2
  player.over
 END IF
END IF

END SUB

SUB clock.bonus

COLOR 7
FOR gt% = status.gtime TO 0 STEP -1
 status.gtime = gt%
 fx.sound 1
 LOCATE 1, 16
 PRINT "TIME"; status.gtime
 player.points 10
NEXT

END SUB

SUB cntr (txt AS STRING)

LOCATE , 20 - LEN(txt) / 2
PRINT txt

END SUB

SUB events (x AS INTEGER, y AS INTEGER)

SELECT CASE tl(x, y).fr

 CASE 0
  SELECT CASE RND * 30000
   CASE IS < 2
    tl(x, y).fr = 16
  END SELECT

 CASE 12, 13
  IF RND * 30 < 2 THEN
   tl(x, y).fr = tl(x, y).fr + 1
  END IF

 CASE 14
  IF RND * 30 < 2 THEN
   fx.sound 1
   FOR nx% = -1 TO 1
    FOR ny% = -1 TO 1
     IF x + nx% > -tlx AND x + nx% < tlx AND y + ny% > -tly AND y + ny% < tly THEN
    
      IF tl(x + nx%, y + ny%).fr = 1 THEN
       player.over
      ELSEIF tl(x + nx%, y + ny%).fr = 5 THEN
       tl(x + nx%, y + ny%).fr = 14
      ELSEIF tl(x + nx%, y + ny%).fr <> 2 THEN
       tl(x + nx%, y + ny%).fr = 15
      END IF
   
     END IF
    NEXT
   NEXT
  END IF

 CASE 15
  IF RND * 20 < 2 THEN
   tl(x, y).fr = 0
  END IF

 CASE 16
  IF RND * 200 < 2 THEN
   tl(x, y).fr = 0
  END IF

 CASE 17
  IF tl(x - 1, y).fr = 17 AND tl(x + 1, y).fr = 17 THEN
   FOR nx% = -1 TO 1
    tl(x + nx%, y).fr = 18
   NEXT
  END IF

 CASE 18
  IF RND * 30 < 2 THEN
   tl(x + nx%, y).fr = 0
  END IF

 CASE 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
  tl(x, y).fr = tl(x, y).fr + 1

 CASE 30
  tl(x, y).fr = 20

 CASE 31
  IF tl(x, y + 1).fr = 0 THEN
   tl(x, y + 1).fr = 3
  ELSEIF tl(x, y + 1).fr = 1 THEN
   player.over
  END IF

 CASE 32
  IF tl(x, y + 1).fr = 3 THEN tl(x, y + 1).fr = 0
 
 CASE 33, 34, 35, 36
  tl(x, y).fr = tl(x, y).fr + 1

 CASE 37
  tl(x, y).fr = 33

END SELECT

END SUB

SUB fx.anim (word AS STRING, speed AS INTEGER)

lnx% = LEN(word) * 8 - 1

DIM pic(lnx%, 6) AS layer
DIM x AS INTEGER, y AS INTEGER, gx AS INTEGER

PALETTE 1, 0
COLOR 1
LOCATE 1, 1
PRINT USING "\       \"; UCASE$(word)

FOR x = 0 TO lnx%
 FOR y = 0 TO 6
  pic(x, y).fr = POINT(x, y)
 NEXT
NEXT

LOCATE 1, 1
PRINT SPACE$(LEN(word))

FOR gx = 320 + lnx% + speed TO 0 - lnx% - speed STEP -speed

 FOR x = 0 TO lnx%
  FOR y = 0 TO 6

   PSET (gx + x + speed, 100 + y), pic(x, y).bk
   pic(x, y).bk = POINT(gx + x, 100 + y)
   IF pic(x, y).fr THEN PSET (gx + x, 100 + y), 15
  
  NEXT
 NEXT

 IF INKEY$ = CHR$(13) THEN
  FOR x = 0 TO lnx%
   FOR y = 0 TO 6
    PSET (gx + x + speed * 0, 100 + y), pic(x, y).bk
   NEXT
  NEXT
  EXIT SUB
 END IF

NEXT

END SUB

SUB fx.color (break AS STRING, bl AS INTEGER, gr AS INTEGER, rd AS INTEGER)

DO

 IF col% < 63 THEN
  col% = col% + 3
 ELSE
  col% = -63
 END IF
 PALETTE 1, (65536 * ABS(col%) * bl) + (256 * ABS(col%) * gr) + ABS(col%) * rd

 keyb$ = INKEY$
 IF keyb$ = CHR$(27) THEN
  END
 ELSEIF keyb$ <> "" THEN
  word$ = word$ + keyb$
  IF LCASE$(RIGHT$(word$, 4)) = "warp" THEN
   status.cheatmode = 1
   COLOR 7
   LOCATE 7
   cntr "CHEATMODE ACTIVATED"
  END IF
 END IF

LOOP UNTIL keyb$ = break$
PALETTE 1, 0

END SUB

SUB fx.explosion (xp AS INTEGER, yp AS INTEGER, vl AS INTEGER, speed AS INTEGER, way AS INTEGER)

DIM back(-vl TO vl, -vl TO vl) AS INTEGER

IF way THEN
 n1% = 2: n2% = 50: n3% = speed
ELSE
 n1% = 50: n2% = 2: n3% = -speed
END IF

n% = n1%
FOR x% = -vl TO vl
 FOR y% = -vl TO vl
  back(x%, y%) = POINT(xp + x% * n%, yp + y% * n%)
 NEXT
NEXT

FOR n% = n1% TO n2% STEP n3%

 FOR dummy% = 1 TO 25000
 NEXT

 FOR x% = -vl TO vl
  FOR y% = -vl TO vl
 
   IF x% <> 0 OR y% <> 0 THEN
    IF back(x%, y%) <> 43 THEN PSET (xp + x% * (n% - speed), yp + y% * (n% - speed)), back(x%, y%)
    back(x%, y%) = POINT(xp + x% * n%, yp + y% * n%)
    IF ABS(n%) < 50 THEN PSET (xp + x% * n%, yp + y% * n%), 43
   END IF
 
  NEXT
 NEXT

NEXT

END SUB

SUB fx.play (song AS STRING)

IF status.sndswitch THEN PLAY "o1l30" + song

END SUB

SUB fx.print (word AS STRING)

COLOR 1
PALETTE 1, 0
LOCATE 1, 2
PRINT USING "\       \"; UCASE$(word)

END SUB

SUB fx.scroll

LINE (0, 190)-(319, 199), 0, BF
FOR i% = 1 TO 30
 LOCATE 25, 40: PRINT
NEXT

END SUB

SUB fx.sound (vl AS INTEGER)

IF status.sndswitch THEN
 FOR freq% = -1000 TO 1000 STEP 200
  SOUND 1000 - ABS(freq%) + vl * 100 + 100, .03
 NEXT
END IF

END SUB

SUB intro (zx AS INTEGER, zy AS INTEGER)

CLS

PALETTE 1, 0
COLOR 1
title$ = "PEARL III"

LOCATE 1, 1
PRINT title$

FOR x% = 0 TO LEN(title$) * 8
 FOR y% = 0 TO 6
  LINE (LEN(title$) * 8 + 5 + x% * zx + 1, 8 + y% * zy + 1)-STEP(zx, zy), POINT(x%, y%) * 7, BF
 NEXT
NEXT

LOCATE 1, 1
PRINT SPACE$(LEN(title$))

COLOR 7
LOCATE 5
cntr "FREEWARE BY JESTER 97"
LOCATE 15
cntr "USE DIRECTIONAL KEYS TO MOVE."
cntr "P PAUSES, S TOGGLES SOUND ON/OFF,"
cntr "RETURN CONTINUES AND ESC QUITS."
cntr ""
cntr "FOR PEARL II VISIT"
cntr "MY HOMEPAGE!"
cntr ""
cntr "http://www.geocities.com/"
cntr "SiliconValley/Lakes/7784"

FOR coins% = 2 TO 1 STEP -1
 COLOR 1
 LOCATE 11
 cntr "PLEASE INSERT" + STR$(coins%) + " COIN(S)"
 fx.color CHR$(13), 1, 1, 1
 fx.sound 5
NEXT

END SUB

SUB level

SHARED en() AS sprite

fx.play "abacegee"

SELECT CASE status.levelnr
 CASE 1: RESTORE 1
 CASE 2: RESTORE 2
 CASE 3: RESTORE 3
 CASE 4: RESTORE 4
 CASE 5: RESTORE 5
 CASE 6: RESTORE 6
 CASE ELSE
  fx.play "egbaageabeecdceggc"
  fx.anim "well done", 1
  END
END SELECT

level.setpal

FOR y% = -tly TO tly
 FOR x% = -tlx TO tlx
  
  IF x% <= 0 AND y% <= 0 THEN
   READ tl(x%, y%).fr
  ELSEIF x% > 0 THEN
   tl(x%, y%).fr = tl(x% * -1, y%).fr
  ELSEIF y% > 0 THEN
   tl(x%, y%).fr = tl(x%, y% * -1).fr
  END IF
 
  IF x% = 0 AND y% = 0 THEN
   tl(x%, y%).bk = 1
  ELSE
   tl(x%, y%).bk = ABS(x%) + ABS(y%)
  END IF

  FOR nrt% = 1 TO 2
   dummy% = tile.buf%(x%, y%, 100, nrt%)
  NEXT

 NEXT
NEXT

FOR y% = -tly TO tly
 FOR x% = -tlx TO tlx
 
  IF tl(x%, y%).fr = 6 THEN
   nr% = nr% + 1
   en(nr%).x = x%
   en(nr%).y = y%
   en(nr%).sx = 0
   en(nr%).sy = 0
  ELSEIF tl(x%, y%).fr = 2 THEN
   status.dmds = status.dmds + 1
  END IF

 NEXT
NEXT

LINE (0, 0)-(319, 8), 0, BF

FOR n% = 1 TO status.lives - 1
 object.bowl n% - 8, -tly - 1, 41
NEXT

COLOR 7
LOCATE 1, 16
PRINT "TIME 100"
LOCATE 1, 28
PRINT "SCORE"
player.points 0

END SUB

SUB level.setpal

READ bl%, gr%, rd%

FOR col% = 0 TO 63
 PALETTE 180 + col%, ((2 ^ 16) * bl%) * col% + ((2 ^ 8) * gr%) * col% + rd% * col%
NEXT

END SUB

SUB object (x AS INTEGER, y AS INTEGER)

SELECT CASE tl(x, y).fr
  
 CASE 1
  object.bowl x, y, 41

 CASE 2
  object.jewel x, y, 283, 2

 CASE 3
  object.wall x, y

 CASE 4
  FOR ny% = 3 TO fsz - 3
   LINE (midx + x * fsz - fsz / 2, midy + y * fsz - fsz / 2 + ny%)-STEP(fsz - 1, 0), 240 - ny% * 2
  NEXT
  
 CASE 5
  object.dynamite x, y, 0
  
 CASE 6, 7, 8, 9, 10
  object.bowl x, y, 70 + tl(x, y).fr
  PSET (midx + x * fsz - fsz / 4, midy + y * fsz - fsz / 4), 163
  PSET (midx + x * fsz + fsz / 4, midy + y * fsz - fsz / 4), 163
  LINE (midx + x * fsz - fsz / 4, midy + y * fsz + fsz / 8)-STEP(fsz / 3, 0), 8

 CASE 11
  object.jewel x, y, 43, 2
  
 CASE 12, 13, 14
  object.dynamite x, y, tl(x, y).fr - 11

 CASE 15
  LINE (midx + x * fsz - fsz / 2, midy + y * fsz - fsz / 2)-STEP(fsz - 2, fsz - 2), 148
  LINE (midx + x * fsz - fsz / 2, midy + y * fsz + fsz / 2 - 1)-STEP(fsz - 2, -fsz + 3), 148
  CIRCLE (midx + x * fsz, midy + y * fsz), fsz / 3, 145
  PAINT STEP(0, 0), 160, 145

 CASE 16
  object.bowl x, y, 140
  LINE (midx + x * fsz, midy + y * fsz - fsz / 6)-STEP(fsz / 6, -fsz / 7), 10
  LINE (midx + x * fsz, midy + y * fsz - fsz / 6)-STEP(-fsz / 6, -fsz / 7), 10

 CASE 17
  FOR nn% = 0 TO fsz / 2 - 1
   LINE (midx + x * fsz - nn%, midy + y * fsz - nn%)-(midx + x * fsz + nn%, midy + y * fsz + nn%), 160 - nn% * 6, B
  NEXT

 CASE 18
  FOR nn% = 0 TO fsz / 4 - 1
   LINE (midx + x * fsz - nn%, midy + y * fsz - nn%)-(midx + x * fsz + nn%, midy + y * fsz + nn%), 130 + nn% * 6, B
  NEXT

 CASE 19
  LINE (midx + x * fsz - fsz / 2 + 2, midy + y * fsz - fsz / 2 + 2)-STEP(fsz - 4, fsz - 4), 7, B
  PAINT STEP(-2, -2), 15, 7
  PSET (midx + x * fsz, midy + y * fsz), 0
  PSET (midx + x * fsz - fsz / 4, midy + y * fsz - fsz / 4), 0
  PSET (midx + x * fsz - fsz / 4, midy + y * fsz + fsz / 4), 0
  PSET (midx + x * fsz + fsz / 4, midy + y * fsz - fsz / 4), 0
  PSET (midx + x * fsz + fsz / 4, midy + y * fsz + fsz / 4), 0

 CASE 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30
  LINE (midx + x * fsz + ABS(tl(x, y).fr - 25) / 2 - 2, midy + y * fsz - fsz / 2)-STEP(fsz / 9, fsz - 1), 150 - ABS(y) * 3, BF

 CASE 31
  object.wall x, y
  LINE (midx + x * fsz + fsz / 3, midy + y * fsz + fsz / 3)-STEP(-fsz / 2, 0), 140
  LINE -STEP(fsz / 3, -fsz / 2), 140
  LINE -STEP(fsz / 3, fsz / 2), 140
  PAINT STEP(-2, -2), 150, 140
 
 CASE 32
  object.wall x, y
  LINE (midx + x * fsz - fsz / 2 + 1, midy + y * fsz - fsz / 3)-STEP(fsz - 3, 0), 140
  LINE -STEP(-fsz / 3, fsz / 2), 140
  LINE -STEP(-fsz / 3, -fsz / 2), 140
  PAINT STEP(2, 2), 150, 140

 CASE 33, 34, 35, 36, 37
  LINE (midx + x * fsz - fsz / 2, midy + y * fsz - fsz / 4 + 1)-STEP(fsz - 1, fsz / 2 - 2), 140, BF
  LINE (midx + x * fsz + tl(x, y).fr - 38, midy + y * fsz - fsz / 2)-STEP(0, fsz - 1), 150
  LINE (midx + x * fsz + tl(x, y).fr - 38 + fsz / 2, midy + y * fsz - fsz / 2)-STEP(0, fsz - 1), 150
 
END SELECT

END SUB

SUB object.bowl (x AS INTEGER, y AS INTEGER, col AS INTEGER)

CIRCLE (midx + x * fsz, midy + y * fsz), fsz / 3, col
PAINT STEP(0, 0), col + 1, col
PSET STEP(fsz / 7, -fsz / 7), col + 2

END SUB

SUB object.dynamite (x AS INTEGER, y AS INTEGER, lt AS INTEGER)

FOR nx% = 3 TO fsz - 3
 LINE (midx + x * fsz - fsz / 2 + nx%, midy + y * fsz - fsz / 2 + 4)-STEP(0, fsz - 5), 120 + nx% * 4
NEXT
LINE (midx + x * fsz, midy + y * fsz - fsz / 2 + lt)-(midx + x * fsz, midy + y * fsz - fsz / 3 + 1), 7

IF lt > 0 THEN PSET (midx + x * fsz, midy + y * fsz - fsz / 2 + lt), 15

END SUB

SUB object.jewel (x AS INTEGER, y AS INTEGER, col AS INTEGER, jsz AS SINGLE)

rx% = x * fsz
ry% = y * fsz

LINE (midx + rx% - fsz / jsz, midy + ry%)-STEP(fsz / jsz, -fsz / jsz), col
LINE -STEP(fsz / jsz, fsz / jsz), col
LINE -STEP(-fsz / jsz, fsz / jsz), col
LINE -STEP(-fsz / jsz, -fsz / jsz), col
LINE -STEP(fsz / jsz, 0), col
LINE -STEP(fsz / jsz, 0), col
LINE (midx + rx%, midy + ry% - fsz / jsz)-STEP(0, fsz / jsz), col
LINE -STEP(0, fsz / jsz), col

PAINT (midx + rx% - fsz / (jsz * 2), midy + ry% - fsz / (jsz * 2)), col, col
PAINT (midx + rx% + fsz / (jsz * 2), midy + ry% - fsz / (jsz * 2)), col + 1, col
PAINT (midx + rx% + fsz / (jsz * 2), midy + ry% + fsz / (jsz * 2)), col, col
PAINT (midx + rx% - fsz / (jsz * 2), midy + ry% + fsz / (jsz * 2)), col - 1, col

END SUB

SUB object.wall (x AS INTEGER, y AS INTEGER)

IF tl(x - 1, y).fr = 3 OR tl(x + 1, y).fr = 3 THEN
 FOR ny% = 0 TO fsz
  LINE (midx + x * fsz - fsz / 2, midy + y * fsz - fsz / 2 + ny%)-STEP(fsz - 1, 0), 240 - ny% * 2
 NEXT
ELSE 'IF tl(x, y - 1).fr = 3 OR tl(x, y + 1).fr = 3 THEN
 FOR nx% = 1 TO fsz - 1
  LINE (midx + x * fsz - fsz / 2 + nx%, midy + y * fsz - fsz / 2)-STEP(0, fsz - 1), 220 + nx% * 2
 NEXT
END IF

END SUB

SUB player.enemy (px AS INTEGER, py AS INTEGER) STATIC

SHARED en() AS sprite
DIM n AS INTEGER
DIM hunt AS INTEGER

IF n < UBOUND(en, 1) THEN
 n = n + 1
ELSE
 n = 1
END IF

IF status.pill = 0 THEN
 hunt = 1
ELSE
 hunt = -1
END IF

IF px < en(n).x AND tl(en(n).x - 1 * hunt, en(n).y).fr <= 1 THEN
 en(n).sx = -1 * hunt: en(n).sy = 0
ELSEIF px > en(n).x AND tl(en(n).x + 1 * hunt, en(n).y).fr <= 1 THEN
 en(n).sx = 1 * hunt: en(n).sy = 0
ELSEIF py < en(n).y AND tl(en(n).x, en(n).y - 1 * hunt).fr <= 1 THEN
 en(n).sx = 0: en(n).sy = -1 * hunt
ELSEIF py > en(n).y AND tl(en(n).x, en(n).y + 1 * hunt).fr <= 1 THEN
 en(n).sx = 0: en(n).sy = 1 * hunt
ELSEIF en(n).sx = 1 AND tl(en(n).x + en(n).sx, en(n).y + en(n).sy).fr > 0 THEN
 en(n).sx = 0: en(n).sy = 1
ELSEIF en(n).sy = 1 AND tl(en(n).x + en(n).sx, en(n).y + en(n).sy).fr > 0 THEN
 en(n).sx = -1: en(n).sy = 0
ELSEIF en(n).sx = -1 AND tl(en(n).x + en(n).sx, en(n).y + en(n).sy).fr > 0 THEN
 en(n).sx = 0: en(n).sy = -1
ELSEIF en(n).sy = -1 AND tl(en(n).x + en(n).sx, en(n).y + en(n).sy).fr > 0 THEN
 en(n).sx = 1: en(n).sy = 0
END IF

SELECT CASE tl(en(n).x + en(n).sx, en(n).y + en(n).sy).fr
 CASE 0
  tl(en(n).x, en(n).y).fr = 0
  en(n).x = en(n).x + en(n).sx
  en(n).y = en(n).y + en(n).sy
  tl(en(n).x, en(n).y).fr = 6 + n
 CASE 1
  fx.sound 11
  IF hunt = 1 THEN
   player.over
  ELSE
   tl(en(n).x, en(n).y).fr = 0
   en(n).x = 0
   en(n).y = 0
  END IF
END SELECT

END SUB

SUB player.handlepill

STATIC col AS INTEGER

IF status.pill > 0 THEN
 status.pill = status.pill - 1
 IF status.pill = 0 THEN
  PALETTE 1, 0
 ELSE
  IF col < 33 THEN
   col = col + 3
  ELSE
   col = -33
  END IF
  PALETTE 1, 65536 * ABS(col) + 256 * ABS(col) + ABS(col)
 END IF
END IF

END SUB

SUB player.keyboard (sx AS INTEGER, sy AS INTEGER)

STATIC lkey AS STRING
DIM nkey AS STRING

nkey = INKEY$
IF nkey <> "" AND nkey = lkey THEN
 dummy$ = INKEY$
END IF
lkey = nkey

SELECT CASE nkey
 CASE CHR$(0) + "M": sx = 1:  sy = 0
 CASE CHR$(0) + "K": sx = -1: sy = 0
 CASE CHR$(0) + "P": sx = 0:  sy = 1
 CASE CHR$(0) + "H": sx = 0:  sy = -1
 CASE " "
  IF status.cheatmode = 1 THEN
   COLOR 7
   LOCATE 1, 1
   INPUT "WARP TO ", status.levelnr
   status.levelnr = status.levelnr - 1
   status.dmds = 0
  END IF
 CASE "p"
  fx.anim "paused", 1
  DO: LOOP UNTIL INKEY$ = CHR$(13)
 CASE "s"
  IF status.sndswitch = 0 THEN
   status.sndswitch = 1
  ELSE
   status.sndswitch = 0
  END IF
 CASE CHR$(27): END
 CASE ELSE: sx = 0: sy = 0
END SELECT

END SUB

SUB player.over

SHARED plr AS sprite

LINE (midx + plr.x * fsz - fsz / 2, midy + plr.y * fsz - fsz / 2)-STEP(fsz - 1, fsz - 1), 200 + tl(plr.x, plr.y).bk, BF
fx.explosion midx + plr.x * fsz, midy + plr.y * fsz, 2, 1, 1

status.lives = status.lives - 1
IF status.lives > 0 THEN
 fx.anim "try again", 2
 fx.play "ababecebae"
ELSE
 player.points -1
 fx.anim "game over", 1
 fx.play "ceggebacegabe"
 status.levelnr = 1
END IF

status.levelnr = status.levelnr - 1
status.dmds = -1

END SUB

SUB player.points (bonus AS INTEGER)

STATIC value AS INTEGER

IF bonus >= 0 THEN
 value = value + bonus
 COLOR 7
 LOCATE 1, 33
 PRINT value
ELSEIF bonus = -1 THEN
 value = 0
END IF

END SUB

SUB tile

STATIC x AS INTEGER, y AS INTEGER

FOR x = -tlx TO tlx
 FOR y = -tly TO tly
 
  IF tile.buf(x, y, tl(x, y).bk, 1) OR tile.buf(x, y, tl(x, y).fr, 2) THEN
  
   'IF tl(x, y).bk > 0 THEN
    LINE (midx + x * fsz - fsz / 2, midy + y * fsz - fsz / 2)-STEP(fsz - 1, fsz - 1), 200 + tl(x, y).bk, BF
   'END IF

   object x, y
    
  END IF

  events x, y

 NEXT
NEXT

IF status.oldgame = 0 THEN
 status.oldgame = 1
 fx.anim "level" + STR$(status.levelnr), 2
END IF

END SUB

FUNCTION tile.buf% (x AS INTEGER, y AS INTEGER, nr AS INTEGER, tp AS INTEGER) STATIC

DIM pic(-tlx TO tlx, -tly TO tly) AS layer

IF tp = 1 THEN

 IF pic(x, y).bk = nr THEN
  tile.buf% = 0
 ELSE
  pic(x, y).bk = nr
  tile.buf% = 1
 END IF

ELSE

 IF pic(x, y).fr = nr THEN
  tile.buf% = 0
 ELSE
  pic(x, y).fr = nr
  tile.buf% = 1
 END IF

END IF

END FUNCTION

