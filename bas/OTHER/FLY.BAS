CLS
SCREEN 12
DIM Jet(220)
DIM Bt(220)
DIM Gu(220)
DIM Esp(500)
DIM Las(196)
DIM Fbl(76)
LINE (1, 1)-(12, 1), 11
LINE (1, 24)-(12, 24), 11
GET (1, 1)-(12, 24), Las
PUT (1, 1), Las, XOR
LINE (4, 1)-(6, 9), 5, BF
LINE (1, 4)-(9, 6), 5, BF
LINE (3, 2)-(7, 8), 5, BF
LINE (2, 3)-(8, 7), 5, BF
LINE (4, 3)-(6, 6), 14, BF
GET (1, 1)-(9, 9), Fbl
PUT (1, 1), Fbl, XOR
LINE (3, 4)-(4, 6), 8, BF
PSET (2, 5), 8
LINE (5, 2)-(7, 8), 9, BF
LINE (8, 4)-(13, 5), 8, BF
LINE (8, 6)-(12, 6), 8
LINE (14, 3)-(20, 4), 9, BF
LINE (14, 5)-(24, 5), 9
LINE (13, 6)-(24, 11), 9, BF
LINE (25, 7)-(25, 9), 8
LINE (26, 7)-(27, 9), 12, BF
PSET (28, 8), 12
LINE (11, 11)-(12, 22), 7, BF
LINE (13, 12)-(23, 21), 7, BF
LINE (9, 13)-(10, 20), 4, BF
LINE (5, 15)-(8, 18), 4, BF
LINE (3, 16)-(4, 17), 4, BF
LINE (6, 16)-(8, 17), 7, BF
LINE (24, 13)-(24, 20), 5
LINE (18, 13)-(21, 14), 5, BF
LINE (18, 19)-(21, 20), 5, BF
LINE (14, 16)-(21, 17), 5, BF
LINE (17, 14)-(17, 19), 5, BF
LINE (13, 13)-(14, 13), 5, BF
LINE (13, 20)-(14, 20), 5, BF
LINE (13, 22)-(24, 27), 9, BF
LINE (14, 28)-(24, 28), 9, BF
LINE (14, 29)-(20, 30), 9, BF
LINE (8, 27)-(12, 27), 8
LINE (8, 28)-(13, 29), 8, BF
LINE (5, 25)-(7, 31), 9, BF
LINE (3, 27)-(4, 29), 8, BF
PSET (2, 28), 8
LINE (25, 24)-(25, 26), 8
LINE (26, 24)-(27, 26), 12, BF
PSET (28, 25), 12
GET (1, 1)-(28, 31), Esp
PUT (1, 1), Esp, XOR
LINE (6, 1)-(6, 3), 1
LINE (7, 2)-(7, 3), 1
PSET (8, 3), 1
LINE (6, 5)-(10, 5), 1
LINE (6, 7)-(9, 7), 1
LINE (6, 8)-(7, 8), 1
PSET (6, 9), 1
LINE (6, 4)-(14, 4), 15
LINE (11, 5)-(13, 5), 7
LINE (6, 6)-(14, 6), 7
LINE (15, 4)-(16, 4), 7
LINE (13, 5)-(14, 5), 4
LINE (13, 3)-(14, 3), 4
LINE (13, 7)-(14, 7), 4
PSET (13, 2), 4
PSET (13, 8), 4
LINE (15, 5)-(16, 6), 8, BF
PSET (17, 5), 8
GET (1, 1)-(17, 17), Bt
PUT (1, 1), Bt, XOR
LINE (1, 1)-(1, 2), 8
LINE (2, 1)-(4, 1), 8
PSET (5, 2), 8
LINE (6, 3)-(7, 3), 8
PSET (8, 4), 8
LINE (9, 5)-(10, 5), 8
PSET (11, 6), 8
LINE (9, 7)-(10, 7), 8
PSET (8, 8), 8
LINE (6, 9)-(7, 9), 8
PSET (5, 10), 8
LINE (2, 11)-(4, 11), 8
LINE (1, 11)-(1, 10), 8
LINE (2, 2)-(2, 4), 1
LINE (3, 4)-(7, 4), 1
LINE (2, 10)-(2, 8), 1
LINE (3, 8)-(7, 8), 1
LINE (3, 5)-(3, 7), 4
LINE (3, 2)-(4, 2), 4
LINE (3, 3)-(5, 3), 4
LINE (7, 5)-(8, 5), 4
LINE (8, 6)-(10, 6), 4
LINE (8, 7)-(7, 7), 4
LINE (3, 9)-(5, 9), 4
LINE (3, 10)-(4, 10), 4
LINE (4, 5)-(6, 7), 7, BF
PSET (7, 6), 7
GET (1, 1)-(17, 17), Jet
PUT (1, 1), Jet, XOR
LINE (1, 5)-(5, 5), 8
LINE (1, 12)-(5, 12), 8
LINE (10, 5)-(14, 5), 8
LINE (10, 12)-(14, 12), 8
GET (1, 1)-(17, 17), Gu
PUT (1, 1), Gu, XOR
PSET (1, 6), 8
LINE (2, 5)-(3, 5), 8
PSET (4, 4), 8
LINE (5, 3)-(6, 3), 8
PSET (7, 2), 8
LINE (8, 1)-(11, 1), 8
PSET (11, 2), 8
LINE (2, 7)-(3, 7), 8
PSET (4, 8), 8
LINE (5, 9)-(6, 9), 8
PSET (7, 10), 8
LINE (8, 11)-(11, 11), 8
PSET (11, 10), 8
LINE (5, 4)-(10, 4), 4
LINE (10, 4)-(10, 2), 8
CLS
 PRINT "Electronic Gaming Software"
 PRINT "  Do you wish to Calabrait"
 PRINT "your Control Stick?"
 DO
 yes$ = INKEY$
 IF yes$ = "y" THEN RUN "c:\fant\joytest.bas"
 LOOP UNTIL yes$ <> ""
 CLS
 VIEW SCREEN (1, 1)-(635, 410), , 1
 hp = 40
 ehp = 120
 ss = 1
 tt = 1
 uu = 1
 mis = 10
 RANDOMIZE TIMER
 FOR l = 1 TO 35
 p = INT(RND * 610) + 2
 pp = INT(RND * 400) + 2
 PSET (p, pp), 15
 NEXT l
 LINE (40, 2)-(40, 409), 15, , &HFF00
 LINE (570, 2)-(570, 409), 15, , &HFF00
 x = 100
 y = 190
 x3 = 500
 y3 = 180
 dd = 6
 PUT (x, y), Jet, XOR
 PUT (x3, y3), Esp, XOR
 ON STRIG(0) GOSUB Fire
 STRIG(0) ON
 ON STRIG(4) GOSUB Gun
 STRIG(4) ON
 LINE (50, 385)-(90, 395), 9, BF
 LINE (400, 385)-(520, 395), 12, BF
 PLAY "p2"
 PLAY "p3"
 enm = 1
Fly:
 DO
 IF INKEY$ = CHR$(27) THEN END
 a = STICK(0)
 b = STICK(1)
 IF a < 35 OR a > 75 OR b < 40 OR b > 85 THEN GOTO Move
 IF r = 1 THEN GOSUB Fire
 IF k = 1 THEN GOSUB Gun
 IF enm = 1 THEN GOTO Espmove
 LOOP
Move:
 IF x < 40 THEN a = 90
 IF x > 570 THEN a = 20
 IF y < 15 THEN b = 90
 IF y > 350 THEN b = 30
 IF a < 35 THEN
 x = x - 5
 PUT (x + 5, y), Jet, XOR
 PUT (x, y), Jet, XOR
 END IF
 IF a > 75 THEN
 x = x + 5
 PUT (x - 5, y), Jet, XOR
 PUT (x, y), Jet, XOR
 END IF
 IF b < 40 THEN
 y = y - 5
 PUT (x, y + 5), Jet, XOR
 PUT (x, y), Jet, XOR
 END IF
 IF b > 80 THEN
 y = y + 5
 PUT (x, y - 5), Jet, XOR
 PUT (x, y), Jet, XOR
 END IF
Emny:
 IF k = 1 THEN GOSUB Gun
 IF r = 1 THEN GOSUB Fire
 IF r <> 1 THEN
 x1 = x + 17
 y1 = y
 END IF
 IF k <> 1 THEN
 x2 = x + 17
 y2 = y
 END IF
 IF enm = 1 THEN GOTO Espmove
Fire:
 STRIG(0) OFF
 IF mis = 0 THEN RETURN
 IF r <> 1 THEN
 PUT (x1, y1), Bt, XOR
 END IF
 r = 1
 x1 = x1 + 15
 PUT (x1 - 15, y1), Bt, XOR
 PUT (x1, y1), Bt, XOR
 IF x1 > 570 THEN
  mis = mis - 1
  PUT (x1, y1), Bt, XOR
  STRIG(0) ON
  r = 2
 END IF
 RETURN
Gun:
 STRIG(4) OFF
 IF k <> 1 THEN
 PUT (x2, y2), Gu, XOR
 END IF
 k = 1
 x2 = x2 + 30
 PUT (x2 - 30, y2), Gu, XOR
 PUT (x2, y2), Gu, XOR
 IF x2 > 540 THEN
  PUT (x2, y2), Gu, XOR
  STRIG(4) ON
  k = 2
 END IF
 RETURN
Espmove:
 IF y3 < 20 THEN
 y3 = y3 + 6
 PUT (x3, y3 - 6), Esp, XOR
 PUT (x3, y3), Esp, XOR
 dd = 6
 END IF
 IF y3 > 370 THEN
 y3 = y3 - 6
 PUT (x3, y3 + 6), Esp, XOR
 PUT (x3, y3), Esp, XOR
 dd = -6
 END IF
 IF y3 > 20 AND y3 < 370 THEN
 y3 = y3 + dd
 PUT (x3, y3 - dd), Esp, XOR
 PUT (x3, y3), Esp, XOR
 END IF
 IF tt = 1 THEN
 y4 = y3 + 4
 x4 = x3
 END IF
 IF uu = 1 THEN
 y5 = y3 + 13
 x5 = x3
 END IF
 GOSUB Laser
 GOSUB Fireball
 GOTO Checkit
Laser:
 IF tt = 1 THEN
 PUT (x4, y4), Las, XOR
 tt = 0
 END IF
 x4 = x4 - 50
 PUT (x4 + 50, y4), Las, XOR
 PUT (x4, y4), Las, XOR
 IF x4 < 45 THEN
 tt = 1
 PUT (x4, y4), Las, XOR
 END IF
 RETURN
Fireball:
 IF uu = 1 THEN
 PUT (x5, y5), Fbl, XOR
 uu = 0
 END IF
 x5 = x5 - 25
 PUT (x5 + 25, y5), Fbl, XOR
 PUT (x5, y5), Fbl, XOR
 IF x5 < 40 THEN
 uu = 1
 PUT (x5, y5), Fbl, XOR
 END IF
 RETURN
Checkit:
 IF x > x3 - 20 AND x < x3 + 31 AND y + 10 > y3 AND y < y3 + 28 THEN hp = hp - 10
 IF r = 1 AND y1 > y3 AND y1 < y3 + 28 AND x1 < x3 + 10 AND x1 > x3 - 12 THEN
  ehp = ehp - 10
  PUT (x1, y1), Bt, XOR
  STRIG(0) ON
  r = 2
 END IF
 IF k = 1 AND y2 - 6 > y3 AND y2 < y3 + 28 AND x2 < x3 + 10 AND x2 > x3 - 15 THEN
  ehp = ehp - 5
  PUT (x2, y2), Gu, XOR
  STRIG(4) ON
  k = 2
 END IF
 IF y4 < y + 10 AND y4 > y - 24 AND x4 < x + 22 AND x4 > x - 12 THEN
  hp = hp - 5
  PUT (x4, y4), Las, XOR
  tt = 1
 END IF
 IF y5 < y + 10 AND y5 > y - 9 AND x5 < x + 19 AND x5 > x - 9 THEN
  hp = hp - 10
  PUT (x5, y5), Fbl, XOR
  uu = 1
 END IF
 LINE (91, 385)-(91 + (hp - 40), 395), 0, BF
 LINE (521, 385)-(521 + (ehp - 120), 395), 0, BF
 LOCATE 28, 1, 0
 PRINT "Missles: "; mis
 IF hp < 0 OR hp = 0 THEN LOCATE 15, 35, 0: PRINT "You Lose": LINE (50, 385)-(50, 395), 0, BF: END
 IF ehp < 0 OR ehp = 0 THEN LOCATE 15, 35, 0: PRINT "You Win!": LINE (400, 385)-(400, 395), 0, BF: END
 GOTO Fly
 
 

