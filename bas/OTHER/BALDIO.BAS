
' -----------------------------------------------------------
'             FREEware   Baldio v1.0     FreeWARE
'                            by
'                     Dominick Aguilar
'               E-Mail BCase10582@aol.com
'
' Greetings to: Use & Amuse Software
'               And everyone else who e-mails me
'    VERSION 2 COMING SOON! (Lots more stuff..magic boots...
'                     And LOTS MORE!!!
'
'Note: CapsLock MUST BE ON...and there is no delay to modify
'------------------------------------------------------------

DIM a$(37)
SCREEN 13
CLS
FOR d = 1 TO 31
FOR dd = 1 TO 31
READ a
PSET (d, dd), a
NEXT dd, d
DIM m1(10, 10)
DIM m2(10, 10)
DIM m3(10, 10)
DIM m4(10, 10)
DIM m5(10, 10)
DIM ar1(10, 10)
DIM ar2(10, 10)
DIM ar3(10, 10)

GET (1, 2)-(10, 11), m1
GET (12, 2)-(21, 11), m2
GET (22, 2)-(31, 11), m3
GET (1, 13)-(10, 22), m4
GET (12, 13)-(21, 22), m5
GET (1, 23)-(10, 32), ar1
GET (12, 23)-(21, 32), ar2
GET (22, 23)-(31, 32), ar3
CLS
RESTORE
FOR d = 1 TO 31
FOR dd = 1 TO 31
READ a
PSET (31 - d, dd), a
NEXT dd, d

DIM mm2(10, 10)
DIM mm3(10, 10)
DIM mm6(10, 10)


GET (11, 2)-(20, 11), mm2
GET (22, 2)-(31, 11), mm3
GET (22, 13)-(31, 22), mm6


CLS
FOR d = 1 TO 31
FOR dd = 1 TO 31
READ a
PSET (d, dd), a
NEXT dd, d
DIM brik(10, 10)
DIM grass(10, 10)
DIM fire(10, 10)
DIM pump(10, 10)
DIM slime(10, 10)
DIM ice(10, 10)
GET (1, 1)-(10, 10), grass
GET (12, 1)-(21, 10), brik
GET (1, 12)-(10, 21), fire
GET (12, 12)-(21, 21), pump
GET (1, 22)-(10, 31), slime
GET (12, 22)-(21, 31), ice
CLS
FOR d = 1 TO 31
FOR dd = 1 TO 31
READ a
PSET (d, dd), a
NEXT dd, d


DIM fire2(10, 10)
DIM pump2(10, 10)
DIM slime2(10, 10)
DIM ice2(10, 10)
GET (1, 12)-(10, 21), fire2
GET (12, 12)-(21, 21), pump2
GET (1, 22)-(10, 31), slime2
GET (12, 22)-(21, 31), ice2
CLS
FOR d = 1 TO 31
FOR dd = 1 TO 31
READ a
PSET (d, dd), a
NEXT dd, d
DIM fire3(10, 10)
DIM pump3(10, 10)
DIM slime3(10, 10)
DIM ice3(10, 10)
GET (1, 12)-(10, 21), fire3
GET (12, 12)-(21, 21), pump3
GET (1, 22)-(10, 31), slime3
GET (12, 22)-(21, 31), ice3
CLS
FOR d = 1 TO 31
FOR dd = 1 TO 31
READ a
PSET (d, dd), a
NEXT dd, d
DIM gem(10, 10)
DIM gum(10, 10)
DIM coin(10, 10)
DIM soda(10, 10)
DIM heart(10, 10)
DIM melon(10, 10)
GET (1, 1)-(10, 10), gem
GET (12, 1)-(21, 10), gum
GET (1, 12)-(10, 21), coin
GET (12, 12)-(21, 21), soda
GET (1, 22)-(10, 31), heart
GET (12, 22)-(21, 31), melon
CLS

FOR d = 1 TO 31
FOR dd = 1 TO 31
READ a
PSET (d, dd), a
NEXT dd, d
DIM gem2(10, 10)
DIM gum2(10, 10)
DIM coin2(10, 10)
DIM soda2(10, 10)
DIM heart2(10, 10)
DIM melon2(10, 10)
GET (1, 1)-(10, 10), gem2
GET (12, 1)-(21, 10), gum2
GET (1, 12)-(10, 21), coin2
GET (12, 12)-(21, 21), soda2
GET (1, 22)-(10, 31), heart2
GET (12, 22)-(21, 31), melon2
CLS

FOR d = 1 TO 31
FOR dd = 1 TO 31
READ a
PSET (d, dd), a
NEXT dd, d
DIM gem3(10, 10)
DIM gum3(10, 10)
DIM coin3(10, 10)
DIM soda3(10, 10)
DIM heart3(10, 10)
DIM melon3(10, 10)
GET (1, 1)-(10, 10), gem3
GET (12, 1)-(21, 10), gum3
GET (1, 12)-(10, 21), coin3
GET (12, 12)-(21, 21), soda3
GET (1, 22)-(10, 31), heart3
GET (12, 22)-(21, 31), melon3
CLS
DIM blank(10, 10): GET (1, 1)-(10, 10), blank
GOTO menu
DO: LOOP UNTIL INKEY$ = " "
start:
uplv = 0
LINE (59, 19)-(200, 50), 32, B
ON level GOSUB level1, level2, level3, level4, level5
GOSUB scene1
GOSUB stuff
GOSUB introlv
GOSUB pause
10 m$ = INKEY$
IF m$ = "p" OR m$ = "P" THEN GOSUB pause
IF m$ = "q" OR m$ = "Q" THEN GOTO menu
IF m$ = "4" OR m$ = "6" THEN mi$ = m$
IF m$ = "8" AND j = 0 THEN j = 1
IF m$ = "4" AND dr <> 2 THEN dr = dr + 1: IF dr = 5 THEN dr = 1
IF m$ = "6" AND dr <> 4 THEN dr = dr + 1: IF dr = 5 THEN dr = 1
IF m$ = "^" THEN uplv = 1
IF j = 0 OR j = 7 THEN GOSUB fall:
IF j > 0 AND j < jjj THEN GOSUB jump:

GOSUB move

GOSUB goodies
IF uplv = 1 THEN GOTO uplevel
scene = scene + 1: IF scene = 4 THEN scene = 1
ON scene GOSUB scene1, scene2, scene3
IF MID$(a$(y + 1), x, 1) = "i" THEN GOSUB slide
IF MID$(a$(y + 1), x, 1) = "j" THEN jj = 1: jjj = 6
IF MID$(a$(y + 1), x, 1) <> "j" AND j = 7 THEN jj = 0: jjj = 4
IF MID$(a$(y + 1), x, 1) = "f" THEN energy = energy - 1: SOUND 20000, .1

GOSUB stuff
IF energy = 0 THEN lives = lives - 1: GOTO restart

m$ = ""
GOTO 10
pause:
LOCATE 5, 11: PRINT "Press [SPACE]"
DO: LOOP UNTIL INKEY$ = " "
RETURN
restart:
j = 0: walk = 1: dr = 4: jj = 0: jjj = 4: scene = 0: energy = 100
IF lives <= 0 THEN GOTO dead
GOTO start
dead:
GOSUB melt
CLS
LOCATE 10, 11: COLOR 64: PRINT " You Are Dead!"
LOCATE 12, 11: COLOR 15: PRINT " Press [SPACE]"
DO: LOOP UNTIL INKEY$ = " "
GOTO menu
'---------------------------------------------------------------------
menu:
s = 1: j = 0: walk = 1: dr = 4: jj = 0: jjj = 4: scene = 0: energy = 100: level = 1
lives = 3: score = 0: gems = 0: coins = 0
CLS
LOCATE 1, 1
LINE (60, 30)-(250, 150), 2, B
LINE (100, 50)-(210, 80), 1, B
COLOR 16: PRINT "Baldio"
COLOR 10
LOCATE 14, 13: PRINT "(I)nstructions"
LOCATE 15, 13: PRINT "(E)xit"
LOCATE 16, 13: PRINT "[SPACE] to Play"
PUT (107, 60), m1, PSET: PUT (190, 60), mm3, PSET
c = 0
DO:
FOR d = 0 TO 50
FOR dd = 0 TO 10
c = c + 1: IF c = 5 THEN c = 0
IF POINT(d, dd) = 16 THEN PSET (130 + d, 60 + dd), 23 + c
NEXT dd, d
a$ = INKEY$
LOOP UNTIL a$ <> ""

IF a$ = "i" OR a$ = "I" THEN GOTO instructions
IF a$ = "e" OR a$ = "E" THEN GOSUB melt: CLS : LOCATE 13, 16: PRINT "    BYE!": END
IF a$ = " " THEN CLS : GOTO start
GOTO menu
instructions:
CLS
LOCATE 9, 1
COLOR 14
PRINT "         Use The NumPad Keys to Move"
PRINT
PRINT "           4-LEFT  8-JUMP 6-RIGHT"
PRINT "       Find Arrow    To Advance Level"
PRINT "         (P)ause (Q)uit During Game"
PRINT "Collect Objects        Coin"
PRINT "                       Increase Energy"
PRINT "                       Extra Life"
PUT (139, 85), ar1, PSET
PUT (140, 105), coin, PSET
PUT (125, 110), melon, PSET
PUT (153, 110), soda, PSET
PUT (140, 119), heart, PSET
PRINT
PRINT "         (ANY KEY) to Return to Menu"
DO: LOOP UNTIL INKEY$ <> ""
GOTO menu
melt:
col = 17: x = 1: y = 10
DIM melt%(3000)
  FOR RR = 1 TO 3000
    RANDOMIZE TIMER
    XX = INT(RND * 271)
    RANDOMIZE TIMER
    YX = INT(RND * 150)
    GET (XX, YX)-(XX + 48, YX + 48), melt%
    PUT (XX, YX + 1), melt%, PSET
    IF INKEY$ > "" THEN END
  NEXT RR
RETURN

'-------------------------------------------------------------
GOTO start
goodies:
IF MID$(a$(y), x, 1) = "y" THEN FOR d = 1 TO 100 STEP 10: SOUND 50 * d, .1: NEXT d: coins = coins + 1: score = score + 100
IF MID$(a$(y), x, 1) = "z" THEN FOR d = 1 TO 50 STEP 10: SOUND 100 * d, .1: NEXT d: gems = gems + 1: score = score + 1: IF energy < 90 THEN energy = energy + 1 ELSE energy = 100
IF MID$(a$(y), x, 1) = "u" THEN SOUND 500, .2: score = score + (gems * 100)
IF MID$(a$(y), x, 1) = "x" THEN SOUND 100, .1: SOUND 500, .1: lives = lives + 1
IF MID$(a$(y), x, 1) = "w" THEN FOR d = 1 TO 100 STEP 20: SOUND 50 * d, .1: NEXT d: score = score + 100: energy = energy + 20: IF energy > 100 THEN energy = 100
IF MID$(a$(y), x, 1) = "v" THEN FOR d = 1 TO 50 STEP 10: SOUND 100 * d, .05: NEXT d: score = score + 100: energy = energy + 1: IF energy > 100 THEN energy = 100
IF MID$(a$(y), x, 1) = "{" THEN uplv = 1
RETURN
scene1:
FOR r = 2 TO 4
FOR c = 1 TO 14
IF MID$(a$(r + y - 3), c + x - 7, 1) = "o" THEN PUT (50 + 10 * c, 10 * r), brik, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "g" THEN PUT (50 + 10 * c, 10 * r), grass, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "f" THEN PUT (50 + 10 * c, 10 * r), fire, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "j" THEN PUT (50 + 10 * c, 10 * r), pump, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "i" THEN PUT (50 + 10 * c, 10 * r), ice, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "s" THEN PUT (50 + 10 * c, 10 * r), slime, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = " " THEN PUT (50 + 10 * c, 10 * r), blank, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "z" THEN PUT (50 + 10 * c, 10 * r), gem, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "y" THEN PUT (50 + 10 * c, 10 * r), coin, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "x" THEN PUT (50 + 10 * c, 10 * r), heart, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "w" THEN PUT (50 + 10 * c, 10 * r), soda, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "v" THEN PUT (50 + 10 * c, 10 * r), melon, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "u" THEN PUT (50 + 10 * c, 10 * r), gum, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "{" THEN PUT (50 + 10 * c, 10 * r), ar1, PSET


IF MID$(a$(r + y - 3), c + x - 7, 1) = "b" THEN GOSUB man
NEXT c, r
RETURN

scene2:
FOR r = 2 TO 4
FOR c = 1 TO 14
IF MID$(a$(r + y - 3), c + x - 7, 1) = "o" THEN PUT (50 + 10 * c, 10 * r), brik, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "g" THEN PUT (50 + 10 * c, 10 * r), grass, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "f" THEN PUT (50 + 10 * c, 10 * r), fire2, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "j" THEN PUT (50 + 10 * c, 10 * r), pump2, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "i" THEN PUT (50 + 10 * c, 10 * r), ice2, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "s" THEN PUT (50 + 10 * c, 10 * r), slime2, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = " " THEN PUT (50 + 10 * c, 10 * r), blank, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "z" THEN PUT (50 + 10 * c, 10 * r), gem2, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "y" THEN PUT (50 + 10 * c, 10 * r), coin2, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "x" THEN PUT (50 + 10 * c, 10 * r), heart2, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "w" THEN PUT (50 + 10 * c, 10 * r), soda2, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "v" THEN PUT (50 + 10 * c, 10 * r), melon2, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "u" THEN PUT (50 + 10 * c, 10 * r), gum2, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "{" THEN PUT (50 + 10 * c, 10 * r), ar2, PSET

IF MID$(a$(r + y - 3), c + x - 7, 1) = "b" THEN GOSUB man
NEXT c, r
RETURN

scene3:
FOR r = 2 TO 4
FOR c = 1 TO 14
IF MID$(a$(r + y - 3), c + x - 7, 1) = "o" THEN PUT (50 + 10 * c, 10 * r), brik, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "g" THEN PUT (50 + 10 * c, 10 * r), grass, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "f" THEN PUT (50 + 10 * c, 10 * r), fire3, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "j" THEN PUT (50 + 10 * c, 10 * r), pump3, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "i" THEN PUT (50 + 10 * c, 10 * r), ice3, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "s" THEN PUT (50 + 10 * c, 10 * r), slime3, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = " " THEN PUT (50 + 10 * c, 10 * r), blank, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "z" THEN PUT (50 + 10 * c, 10 * r), gem3, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "y" THEN PUT (50 + 10 * c, 10 * r), coin3, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "x" THEN PUT (50 + 10 * c, 10 * r), heart3, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "w" THEN PUT (50 + 10 * c, 10 * r), soda3, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "v" THEN PUT (50 + 10 * c, 10 * r), melon3, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "u" THEN PUT (50 + 10 * c, 10 * r), gum3, PSET
IF MID$(a$(r + y - 3), c + x - 7, 1) = "{" THEN PUT (50 + 10 * c, 10 * r), ar3, PSET

IF MID$(a$(r + y - 3), c + x - 7, 1) = "b" THEN GOSUB man
NEXT c, r

RETURN
move:
IF m$ = "4" THEN IF ASC(MID$(a$(y), x - 1, 1)) > 116 OR ASC(MID$(a$(y), x - 1, 1)) = 32 THEN x = x - 1: GOSUB goodies: a$(y) = MID$(a$(y), 1, x - 1) + "b " + MID$(a$(y), x + 2, LEN(a$(y)))
IF m$ = "6" THEN IF ASC(MID$(a$(y), x + 1, 1)) > 116 OR ASC(MID$(a$(y), x + 1, 1)) = 32 THEN x = x + 1: GOSUB goodies: a$(y) = MID$(a$(y), 1, x - 2) + " b" + MID$(a$(y), x + 1, LEN(a$(y)))

RETURN
slide:
ON scene GOSUB scene1, scene2, scene3
IF mi$ = "4" THEN IF ASC(MID$(a$(y), x - 1, 1)) > 116 OR ASC(MID$(a$(y), x - 1, 1)) = 32 THEN x = x - 1: GOSUB goodies: a$(y) = MID$(a$(y), 1, x - 1) + "b " + MID$(a$(y), x + 2, LEN(a$(y)))
IF mi$ = "6" THEN IF ASC(MID$(a$(y), x + 1, 1)) > 116 OR ASC(MID$(a$(y), x + 1, 1)) = 32 THEN x = x + 1: GOSUB goodies: a$(y) = MID$(a$(y), 1, x - 2) + " b" + MID$(a$(y), x + 1, LEN(a$(y)))

RETURN

jump:
j = j + 1: IF j = jjj THEN j = 7: RETURN
SOUND 200 * (10 * j), .1
IF ASC(MID$(a$(y - 1), x, 1)) < 117 AND ASC(MID$(a$(y - 1), x, 1)) > 32 THEN j = 7: SOUND 1000, .1: SOUND 100, .1: SOUND 400, .2: RETURN
y = y - 1
GOSUB goodies
a$(y + 1) = MID$(a$(y + 1), 1, x - 1) + " " + MID$(a$(y + 1), x + 1, LEN(a$(y + 1)))
a$(y) = MID$(a$(y), 1, x - 1) + "b" + MID$(a$(y), x + 1, LEN(a$(y)))

RETURN
fall:


IF ASC(MID$(a$(y + 1), x, 1)) < 117 AND ASC(MID$(a$(y + 1), x, 1)) > 32 THEN j = 0: IF jj = 0 THEN RETURN ELSE j = 1: RETURN
y = y + 1
GOSUB goodies
a$(y - 1) = MID$(a$(y - 1), 1, x - 1) + " " + MID$(a$(y - 1), x + 1, LEN(a$(y - 1)))
a$(y) = MID$(a$(y), 1, x - 1) + "b" + MID$(a$(y), x + 1, LEN(a$(y)))

IF MID$(a$(y + 1), x, 1) <> " " THEN SOUND 2000, .1: SOUND 500, .1: SOUND 200, .1

RETURN

man:
IF m$ <> "" THEN walk = walk + 1: IF walk = 4 THEN walk = 1
IF walk = 1 AND dr = 4 THEN PUT (50 + 10 * c, 10 * r), m1, PSET
IF walk = 2 AND dr = 4 THEN PUT (50 + 10 * c, 10 * r), m2, PSET
IF walk = 3 AND dr = 4 THEN PUT (50 + 10 * c, 10 * r), m4, PSET
IF dr = 3 THEN PUT (50 + 10 * c, 10 * r), m3, PSET
IF dr = 1 THEN PUT (50 + 10 * c, 10 * r), m5, PSET
IF walk = 1 AND dr = 2 THEN PUT (50 + 10 * c, 10 * r), mm6, PSET
IF walk = 2 AND dr = 2 THEN PUT (50 + 10 * c, 10 * r), mm3, PSET
IF walk = 3 AND dr = 2 THEN PUT (50 + 10 * c, 10 * r), mm2, PSET
IF m$ = "4" OR m$ = "6" THEN SOUND 100, .05: SOUND 1000, .2

RETURN
stuff:
LINE (57, 104)-(57 + energy, 109), 2, BF: LINE (157, 104)-(57 + energy, 109), 8, BF
COLOR 32: LOCATE 14, 1: PRINT "Energy:"
COLOR 4: LOCATE 15, 1: PRINT "Lives :"; lives
COLOR 14: LOCATE 16, 1: PRINT "Coins :"; coins
COLOR 1: LOCATE 17, 1: PRINT "Gems  :"; gems
PRINT
COLOR 15: LOCATE 18, 1: PRINT "Score :"; score
RETURN
introlv:
LOCATE 4, 11: PRINT lv$

RETURN

uplevel:
FOR d = 1 TO 1000 STEP 10
SOUND 10 * d + 100, s * (.3)
NEXT d
level = level + 1: IF level = 6 THEN level = 1
GOTO start

' b=baldio o=brick g=grass f=fire s=slime i=ice
' u=gum v=melon w=soda x=heart y=coin

level1:
lv$ = " Level 1"
x = 21: y = 3
 a$(1) = "         oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo         "
 a$(2) = "         o            oy               o                     w   w            x         o         "
 a$(3) = "         o          b o    yyy         o            v                  ggggggggggggggg  o         "
 a$(4) = "         o    ffiiioooooo              ox   w   w      ooo o o o o o                 o  o         "
 a$(5) = "         oo       ooooooooo                           o    y y y y y                 o  o         "
 a$(6) = "         o            oooooooooo       o  iiiiiii oooo                               o  o         "
 a$(7) = "         o     ooo        z            o                   ooooooooo          o      o  o         "
 a$(8) = "         o     ov                      oj yyyyyyy              v v v          o    f o  o         "
 a$(9) = "         o  j  o           iiiifffj    oo                                   j offfff    o         "
a$(10) = "         oooooooooooooooooooooooooooooooggggggggggggg          gggggggggggggggggggggggg o         "
a$(11) = "         o                                           g   vw   g                         o         "
a$(12) = "         oyzyzyzy                        yyyyyyy      g      g                        y o         "
a$(13) = "         o{                  yy          yyyyyyy       ssssss                         y o         "
a$(14) = "         oggg g ggggggggggg              vvvvvvv                   yyyy               y o         "
a$(15) = "         o                             j                           yyyy               y o         "
a$(16) = "         o                 iiiiiiii ii            j   sssssss                         y o         "
a$(17) = "         ox   v  v        iiiiiiiii iii               sxxxxxs    jjoooooo             y o         "
a$(18) = "         o               iiiiiiiiii  iii              s     s    x                    y o         "
a$(19) = "         offfffffffffffffffiiiiiiiij  xiiiiii        js             iifffjiiffiiiii     o         "
a$(20) = "         oggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg         "
a$(21) = "                                                                                                  "
RETURN
level2:
lv$ = " Ice Slides"
x = 21: y = 3
 a$(1) = "         oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo         "
 a$(2) = "         o                            w       o  u ooo                                  o         "
 a$(3) = "         o          b                          o    o                                   o         "
 a$(4) = "         o          o                           o                                       o         "
 a$(5) = "         o         i i             iij i         ooooooooooooooo oooooooooooooooooooooooo         "
 a$(6) = "         o        i   i           iiii ii                                               o         "
 a$(7) = "         o       iyyyyyi         iiiiiziii                                              o         "
 a$(8) = "         o      iyyyyyyyi   iiiiiiiiii iiiiiiiiiiiiiiiiiiiiiiiiijiiiiiiiiiiiiiiiiiiiiii o         "
 a$(9) = "         o     iyyyyyyyyyi              v yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy v             o         "
a$(10) = "         o    i           i  iiiiiiiiiiiiifffffffffffffffffffffffffffffffiiiiiiiiiiiiii o         "
a$(11) = "         o   ioooooojo     i                                                            o         "
a$(12) = "         o  i               i              i              i                f            o         "
a$(13) = "         o i     z z z       i            i i            i i              f f           o         "
a$(14) = "         o             j      i          i   i          i   i            f   f          o         "
a$(15) = "         oooooo o o o oo       iiii ii  i w   i        iyyyyyi          f  w  f         o         "
a$(16) = "         o     x   y y          i      i       i      iyyyyyyyi        f  vwv  f        o         "
a$(17) = "         o         y y           i    i         i    i         i      f  v w v  f       o         "
a$(18) = "         o                           i     w     iiii     w     i    f{ v  w  v  f      o         "
a$(19) = "         ou                         iu     j              j         f      j            o         "
a$(20) = "         ooooooooooooooooooooooooooooifffffffffffffffffffffffffffoooooooooooooooooooooooo         "
a$(21) = "                                                                                                  "
RETURN
level3:
lv$ = " 3rd Level"
x = 21: y = 3
 a$(1) = "         oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo         "
 a$(2) = "         o                                                xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo         "
 a$(3) = "         o          b                                                                   o         "
 a$(4) = "         o          ooooooooiiiii o o o oooiiiiiiiiiiiiiii oooooooooooooooooooooooooooo o         "
 a$(5) = "         o        y     o                                                     {       o o         "
 a$(6) = "         o        y     f                  w w  w w w w w w w                 o       o o         "
 a$(7) = "         o        y     f                                                    oo       o o         "
 a$(8) = "         o        y     f      oooooooiiiiiiiiffffffffffffffiiiiii          owo       o o         "
 a$(9) = "         o      y o     f                                                  owwo       o o         "
a$(10) = "         o      y                                                         owwwo         o         "
a$(11) = "         o      y     fff                                                owwwwo      yo o         "
a$(12) = "         o      y       f fiiiiiiii iiiiiiiiiiii                        owwwwwo      yo o         "
a$(13) = "         o      y  o    f f                                            oowwwwwo      yo o         "
a$(14) = "         o      y   o   fjf          ooooooooo                        oooowwwwo      yo o         "
a$(15) = "         o      y    o  fff          o yyyyyyy                     jooooo    wo      yo o         "
a$(16) = "         o      o     o            j o oooooooooooo              o          joo      yo o         "
a$(17) = "         o            voo            o yyyyyyyyyyzo        j               oooo  oooooo o         "
a$(18) = "         o                           o oooooooooooo                       ooooo         o         "
a$(19) = "         offfffffffffffffffff                                     j               ffffffo         "
a$(20) = "         oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo         "
a$(21) = "                                                                                                  "
RETURN
level4:
lv$ = " BIG LEVEL!"
x = 11: y = 35

 a$(1) = "         ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo         "
 a$(2) = "         ovvvvvvvvvvvvvvvv                                                               o         "
 a$(3) = "         oovvvvvvvvvvvvvvvg                oooooooooooooooooooo oooooooooooooooooooooooooo         "
 a$(4) = "         ooovvvvvvvvvvvvvv g              o                   o o                        o         "
 a$(5) = "         oooovvvvvvvvvvvvv  g            o                    o o                     f  o         "
 a$(6) = "         oggggggggggggggg               o                     o o               oj ffff  o         "
 a$(7) = "         o                             o                      o o            o        o  o         "
 a$(8) = "         o                   j                                o o                 j   o  o         "
 a$(9) = "         ox                          o                        o o          o   j      o  o         "
a$(10) = "         o              j           oojooooooooooooo  ooooooo o o o                 j o  o         "
a$(11) = "         o     j                   ooooooooooooooo  ooooooooooo o   o    o   j        o  o         "
a$(12) = "         og                       oy  oooooooooo  ooooooooooooo o     o               o  o         "
a$(13) = "         oojg          j         ooyo  ooooooo  ooooooooooooooo o       o       j     o  o         "
a$(14) = "         oooogg                 oooyoo  oooo  oooooooooyyyyyyyy o   j     o        j  o  o         "
a$(15) = "         oooooogg              oooo ooo  o   oooooooooo         o        ooo          o  o         "
a$(16) = "         oooooooog            oooox oooo   oooooooooooooooooooo o     ooooooo o       o  o         "
a$(17) = "         ooooooooog          ooooooyooooooooooooooooooooooooooo ooooooooooooo oooooo  o  o         "
a$(18) = "         ooooooooo          o     o                             o                    oo  o         "
a$(19) = "         ooooooo    j      o      ooooooooooooooooooooooooooooo o                   ooo  o         "
a$(20) = "         ooooo      gggg  o                                   o o                  oooo  o         "
a$(21) = "         ooo             o                                    o o         iiiii ooooooo  o         "
a$(22) = "         oo             o                          ooooooooo  o o        i    y y     o  o         "
a$(23) = "         o             o                           o          o o       i     y y     o  o         "
a$(24) = "         ogggggggggg  o                            o        j o o      i      y y     o  o         "
a$(25) = "         o           o                             o       oo o o     i       y yyyyyyo  o         "
a$(26) = "         o          o        ooooooooooooooooooo   o      ooo o o    i                o  o         "
a$(27) = "         o    y    o                             j o     oooo o o   i    oooooooooooooo  o         "
a$(28) = "         o        o  o                              o  oo     o o  i     o            o  o         "
a$(29) = "         o  y    o  ooo                              o        o oj                    o  o         "
a$(30) = "         o      o  ooooo                              o       o ooooo    oooooooooooooo  o         "
a$(31) = "         o     o  ooooooo                             oo      o o                     o  o         "
a$(32) = "         o    oo ooooooooo ooooooooooooo  ooooooooo ooo o     o o        o            o  o         "
a$(33) = "         o   ooovoyyyyyyyy y      oooooo              o  o    o   iiiij  o            o  o         "
a$(34) = "         o  oooojovvvvvvvv   vvvv ooooooooooooooooojooo   o   ooooooooooooooooooooooooo  o         "
a$(35) = "         obooooooo    j                                   {o                             o         "
a$(36) = "         ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo         "
a$(37) = "                                                                                                  "

RETURN
level5:
lv$ = "All or NONE"
x = 21: y = 3
 a$(1) = "         oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo         "
 a$(2) = "         o                                                                              o         "
 a$(3) = "         o          b                 zwzwzwzwzwzwzwzwzwzwzwzw                          o         "
 a$(4) = "         oooo     ooooooooo                                   yyyyyyyyyyyyyyyyyyyyyyyyyyo         "
 a$(5) = "         o          oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooyo         "
 a$(6) = "         o          oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo         "
 a$(7) = "         o          oyooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo         "
 a$(8) = "         o          oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo         "
 a$(9) = "         o          oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooyo         "
a$(10) = "         o          oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo         "
a$(11) = "         o          oooooooooooooooooo oooooooooooooooooooooooooooooooooooooooooooooooooo         "
a$(12) = "         o                          {oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo         "
a$(13) = "         o         oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooovo         "
a$(14) = "         o        o o vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvo         "
a$(15) = "         o       o  o ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo         "
a$(16) = "         o      o   o yyyyyyyyyyyzyyyyyyyyxyyyyyyyyyyywyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy{o         "
a$(17) = "         oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo         "
a$(18) = "                                                                                                  "

RETURN

DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 66 , 66 , 2 , 2 , 2 , 0 , 0 , 0 , 0 , 0 , 0 , 66 , 66 , 2 , 2 , 2 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 112 , 0 , 0 , 0 , 0
DATA  0 , 0 , 66 , 66 , 66 , 48 , 48 , 2 , 2 , 1 , 6 , 0 , 0 , 66 , 66 , 66 , 48 , 48 , 48 , 2 , 0 , 0 , 0 , 0 , 0 , 4 , 112 , 0 , 0 , 0 , 0
DATA  0 , 66 , 66 , 90 , 66 , 48 , 2 , 66 , 66 , 32 , 6 , 0 , 66 , 66 , 90 , 66 , 48 , 48 , 2 , 2 , 1 , 6 , 0 , 0 , 4 , 4 , 112 , 112 , 112 , 112 , 0
DATA  0 , 90 , 6 , 90 , 90 , 48 , 65 , 90 , 90 , 66 , 6 , 0 , 90 , 6 , 90 , 90 , 48 , 65 , 66 , 66 , 32 , 0 , 0 , 4 , 4 , 4 , 4 , 4 , 4 , 112 , 0
DATA  0 , 6 , 30 , 15 , 90 , 48 , 90 , 90 , 2 , 32 , 0 , 0 , 6 , 30 , 15 , 90 , 48 , 90 , 90 , 90 , 66 , 6 , 4 , 4 , 4 , 4 , 4 , 39 , 4 , 112 , 0
DATA  0 , 90 , 15 , 16 , 90 , 48 , 48 , 48 , 48 , 105 , 0 , 0 , 90 , 15 , 0 , 90 , 48 , 48 , 48 , 48 , 32 , 6 , 0 , 4 , 4 , 4 , 4 , 4 , 4 , 0 , 0
DATA  0 , 0 , 90 , 90 , 90 , 70 , 48 , 48 , 48 , 105 , 105 , 0 , 0 , 90 , 90 , 90 , 70 , 48 , 48 , 48 , 32 , 6 , 0 , 0 , 4 , 4 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 90 , 90 , 0 , 70 , 70 , 32 , 105 , 6 , 0 , 0 , 0 , 90 , 90 , 0 , 70 , 70 , 70 , 0 , 0 , 0 , 0 , 0 , 4 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 6 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 66 , 66 , 0 , 0 , 65 , 66 , 66 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 66 , 66 , 2 , 2 , 2 , 0 , 6 , 0 , 0 , 66 , 66 , 66 , 66 , 2 , 2 , 2 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 112 , 0 , 0 , 0 , 0
DATA  0 , 0 , 66 , 66 , 66 , 48 , 48 , 48 , 2 , 1 , 6 , 0 , 66 , 90 , 90 , 66 , 48 , 48 , 48 , 2 , 1 , 6 , 0 , 0 , 0 , 4 , 112 , 0 , 0 , 0 , 0
DATA  0 , 66 , 66 , 90 , 66 , 48 , 2 , 2 , 48 , 105 , 1 , 0 , 90 , 90 , 90 , 66 , 48 , 48 , 48 , 48 , 32 , 6 , 0 , 0 , 4 , 4 , 112 , 112 , 112 , 112 , 0
DATA  0 , 90 , 6 , 90 , 90 , 48 , 65 , 66 , 2 , 1 , 105 , 0 , 90 , 90 , 90 , 90 , 48 , 48 , 48 , 48 , 32 , 0 , 0 , 4 , 4 , 4 , 4 , 4 , 4 , 112 , 0
DATA  0 , 6 , 30 , 15 , 90 , 48 , 90 , 90 , 66 , 32 , 0 , 0 , 90 , 90 , 90 , 90 , 48 , 48 , 48 , 48 , 32 , 0 , 4 , 4 , 4 , 39 , 4 , 4 , 4 , 112 , 0
DATA  0 , 90 , 15 , 16 , 90 , 48 , 48 , 90 , 90 , 32 , 6 , 0 , 90 , 90 , 90 , 90 , 48 , 48 , 48 , 48 , 32 , 6 , 0 , 4 , 4 , 4 , 4 , 4 , 4 , 0 , 0
DATA  0 , 0 , 90 , 90 , 90 , 70 , 48 , 48 , 90 , 32 , 6 , 0 , 90 , 90 , 90 , 90 , 48 , 48 , 48 , 70 , 32 , 6 , 0 , 0 , 4 , 4 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 90 , 90 , 0 , 70 , 70 , 0 , 0 , 6 , 0 , 90 , 90 , 90 , 90 , 70 , 70 , 70 , 32 , 0 , 0 , 0 , 0 , 0 , 4 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 90 , 90 , 0 , 0 , 90 , 90 , 90 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 66 , 66 , 0 , 0 , 65 , 66 , 66 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 66 , 6 , 90 , 66 , 2 , 2 , 2 , 1 , 0 , 0 , 0 , 0 , 0 , 66 , 66 , 2 , 2 , 2 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 112 , 0 , 0 , 0 , 0
DATA  0 , 6 , 30 , 15 , 90 , 48 , 48 , 48 , 2 , 1 , 6 , 0 , 0 , 66 , 66 , 66 , 48 , 48 , 48 , 2 , 0 , 0 , 0 , 0 , 0 , 4 , 112 , 0 , 0 , 0 , 0
DATA  0 , 90 , 15 , 16 , 66 , 2 , 48 , 48 , 48 , 32 , 6 , 0 , 66 , 66 , 90 , 66 , 48 , 48 , 48 , 48 , 1 , 6 , 0 , 0 , 4 , 4 , 112 , 112 , 112 , 112 , 0
DATA  0 , 90 , 66 , 66 , 66 , 66 , 48 , 48 , 48 , 32 , 0 , 0 , 90 , 6 , 90 , 90 , 48 , 65 , 66 , 66 , 32 , 0 , 0 , 4 , 4 , 4 , 4 , 4 , 4 , 112 , 0
DATA  0 , 90 , 90 , 90 , 90 , 90 , 48 , 48 , 48 , 32 , 0 , 0 , 90 , 6 , 65 , 90 , 48 , 90 , 90 , 90 , 90 , 6 , 4 , 39 , 4 , 4 , 4 , 4 , 4 , 112 , 0
DATA  0 , 90 , 30 , 15 , 90 , 48 , 48 , 48 , 48 , 32 , 6 , 0 , 90 , 6 , 66 , 90 , 48 , 48 , 48 , 48 , 32 , 6 , 0 , 4 , 4 , 4 , 4 , 4 , 4 , 0 , 0
DATA  0 , 6 , 15 , 0 , 90 , 48 , 48 , 48 , 70 , 32 , 6 , 0 , 0 , 90 , 90 , 90 , 70 , 48 , 48 , 48 , 32 , 6 , 0 , 0 , 4 , 4 , 0 , 0 , 0 , 0 , 0
DATA  0 , 90 , 6 , 90 , 90 , 70 , 70 , 70 , 32 , 0 , 0 , 0 , 0 , 0 , 90 , 90 , 0 , 70 , 70 , 70 , 0 , 0 , 0 , 0 , 0 , 4 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 90 , 90 , 0 , 0 , 90 , 90 , 90 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 10 , 10 , 2 , 6 , 6 , 6 , 18 , 18 , 18 , 0 , 4 , 40 , 40 , 4 , 4 , 40 , 4 , 4 , 4 , 112 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 2 , 10 , 6 , 6 , 6 , 18 , 18 , 0 , 4 , 40 , 40 , 40 , 4 , 40 , 4 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 10 , 6 , 10 , 6 , 6 , 42 , 18 , 0 , 18 , 4 , 4 , 40 , 40 , 4 , 112 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 2 , 6 , 6 , 6 , 42 , 18 , 18 , 0 , 4 , 4 , 40 , 40 , 40 , 4 , 112 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1
DATA  0 , 10 , 10 , 10 , 6 , 42 , 42 , 18 , 18 , 18 , 0 , 18 , 40 , 40 , 40 , 40 , 40 , 4 , 40 , 112 , 112 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 105 , 1 , 1
DATA  0 , 10 , 2 , 10 , 10 , 6 , 10 , 6 , 18 , 18 , 0 , 40 , 18 , 18 , 40 , 4 , 40 , 40 , 40 , 112 , 112 , 2 , 2 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1
DATA  0 , 10 , 10 , 10 , 10 , 10 , 6 , 6 , 18 , 18 , 0 , 18 , 18 , 18 , 18 , 40 , 4 , 40 , 40 , 112 , 112 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 2 , 10 , 6 , 6 , 6 , 6 , 18 , 0 , 18 , 18 , 4 , 18 , 40 , 40 , 4 , 4 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 2 , 2 , 6 , 6 , 6 , 6 , 42 , 18 , 0 , 18 , 40 , 4 , 40 , 4 , 40 , 4 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 2 , 2 , 2 , 105 , 1 , 1
DATA  0 , 10 , 10 , 2 , 2 , 6 , 42 , 42 , 18 , 18 , 0 , 4 , 4 , 40 , 4 , 4 , 40 , 4 , 112 , 112 , 112 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1 , 1 , 1
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 22 , 22 , 22 , 18 , 22 , 22 , 20 , 22 , 22 , 0 , 5 , 5 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 5 , 30 , 15 , 77 , 80 , 102 , 102 , 77 , 102 , 102 , 102
DATA  0 , 18 , 18 , 20 , 20 , 22 , 20 , 20 , 22 , 22 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 0 , 0 , 5 , 5 , 30 , 15 , 77 , 77 , 102 , 102 , 77 , 77 , 102 , 102
DATA  0 , 22 , 22 , 22 , 20 , 22 , 20 , 22 , 20 , 20 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 0 , 0 , 36 , 5 , 30 , 15 , 15 , 80 , 102 , 102 , 102 , 77 , 77 , 102
DATA  0 , 22 , 22 , 22 , 20 , 18 , 22 , 22 , 22 , 22 , 0 , 35 , 35 , 180 , 108 , 108 , 108 , 108 , 108 , 36 , 36 , 30 , 15 , 15 , 80 , 80 , 102 , 77 , 77 , 77 , 102
DATA  0 , 22 , 20 , 20 , 22 , 18 , 16 , 20 , 20 , 20 , 0 , 35 , 35 , 108 , 5 , 5 , 5 , 5 , 5 , 36 , 36 , 30 , 15 , 15 , 15 , 102 , 102 , 102 , 77 , 77 , 102
DATA  0 , 20 , 20 , 22 , 22 , 20 , 18 , 18 , 18 , 20 , 0 , 35 , 35 , 108 , 5 , 5 , 5 , 5 , 5 , 36 , 36 , 30 , 15 , 15 , 80 , 102 , 102 , 77 , 77 , 77 , 102
DATA  0 , 20 , 22 , 22 , 20 , 18 , 22 , 22 , 22 , 18 , 0 , 35 , 35 , 5 , 35 , 35 , 35 , 35 , 35 , 36 , 36 , 30 , 15 , 80 , 80 , 102 , 77 , 77 , 77 , 77 , 102
DATA  0 , 20 , 20 , 22 , 18 , 22 , 20 , 20 , 22 , 22 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 0 , 0 , 36 , 36 , 30 , 15 , 15 , 15 , 15 , 102 , 77 , 77 , 77 , 102
DATA  0 , 22 , 22 , 20 , 18 , 22 , 22 , 20 , 20 , 22 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 0 , 0 , 36 , 36 , 30 , 15 , 15 , 15 , 102 , 102 , 102 , 77 , 102 , 102
DATA  0 , 22 , 22 , 22 , 20 , 22 , 22 , 20 , 20 , 22 , 0 , 36 , 36 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 36 , 30 , 15 , 80 , 80 , 102 , 102 , 102 , 102 , 102 , 102
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 10 , 10 , 2 , 6 , 6 , 6 , 18 , 18 , 18 , 0 , 4 , 18 , 18 , 4 , 4 , 40 , 4 , 4 , 4 , 112 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 2 , 10 , 6 , 6 , 6 , 18 , 18 , 0 , 18 , 18 , 40 , 18 , 4 , 40 , 4 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1
DATA  0 , 10 , 10 , 10 , 6 , 10 , 6 , 6 , 42 , 18 , 0 , 18 , 4 , 4 , 18 , 18 , 4 , 112 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 2 , 6 , 6 , 6 , 42 , 18 , 18 , 0 , 4 , 4 , 40 , 18 , 40 , 4 , 18 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1
DATA  0 , 10 , 10 , 10 , 6 , 42 , 42 , 18 , 18 , 18 , 0 , 18 , 18 , 18 , 18 , 40 , 18 , 4 , 40 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 2 , 10 , 10 , 6 , 10 , 6 , 18 , 18 , 0 , 18 , 40 , 40 , 40 , 4 , 112 , 112 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 10 , 10 , 10 , 6 , 6 , 18 , 18 , 0 , 4 , 4 , 18 , 40 , 40 , 4 , 112 , 112 , 112 , 112 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 2 , 10 , 6 , 6 , 6 , 6 , 18 , 0 , 18 , 4 , 4 , 18 , 40 , 40 , 4 , 4 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 2 , 2 , 6 , 6 , 6 , 6 , 42 , 18 , 0 , 18 , 40 , 4 , 40 , 4 , 40 , 4 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 2 , 2 , 2 , 105 , 1
DATA  0 , 10 , 10 , 2 , 2 , 6 , 42 , 42 , 18 , 18 , 0 , 4 , 4 , 40 , 4 , 4 , 40 , 4 , 112 , 112 , 112 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1 , 1 , 1
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 22 , 22 , 22 , 18 , 22 , 22 , 20 , 22 , 22 , 0 , 0 , 5 , 5 , 0 , 0 , 0 , 0 , 0 , 0 , 5 , 30 , 15 , 77 , 80 , 102 , 102 , 77 , 102 , 102 , 102
DATA  0 , 18 , 18 , 20 , 20 , 22 , 20 , 20 , 22 , 22 , 0 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 0 , 5 , 5 , 30 , 15 , 77 , 77 , 102 , 102 , 77 , 77 , 102 , 102
DATA  0 , 22 , 22 , 22 , 20 , 22 , 20 , 22 , 20 , 20 , 0 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 0 , 36 , 5 , 30 , 15 , 15 , 80 , 77 , 102 , 102 , 102 , 102 , 102
DATA  0 , 22 , 22 , 22 , 20 , 18 , 22 , 22 , 22 , 22 , 0 , 0 , 35 , 35 , 180 , 108 , 108 , 108 , 108 , 36 , 36 , 30 , 15 , 15 , 80 , 77 , 77 , 102 , 77 , 77 , 102
DATA  0 , 22 , 20 , 20 , 22 , 18 , 16 , 20 , 20 , 20 , 0 , 0 , 35 , 35 , 108 , 5 , 5 , 5 , 5 , 36 , 36 , 30 , 15 , 15 , 15 , 102 , 77 , 77 , 77 , 77 , 102
DATA  0 , 20 , 20 , 22 , 22 , 20 , 18 , 18 , 18 , 20 , 0 , 0 , 35 , 35 , 108 , 5 , 5 , 5 , 5 , 36 , 36 , 30 , 15 , 15 , 80 , 102 , 77 , 102 , 102 , 77 , 102
DATA  0 , 20 , 22 , 22 , 20 , 18 , 22 , 22 , 22 , 18 , 0 , 0 , 35 , 35 , 5 , 35 , 35 , 35 , 35 , 36 , 36 , 30 , 15 , 80 , 80 , 102 , 77 , 102 , 102 , 77 , 102
DATA  0 , 20 , 20 , 22 , 18 , 22 , 20 , 20 , 22 , 22 , 0 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 0 , 36 , 36 , 30 , 15 , 15 , 15 , 15 , 102 , 77 , 77 , 77 , 102
DATA  0 , 22 , 22 , 20 , 18 , 22 , 22 , 20 , 20 , 22 , 0 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 0 , 36 , 36 , 30 , 15 , 15 , 15 , 102 , 77 , 77 , 77 , 102 , 102
DATA  0 , 22 , 22 , 22 , 20 , 22 , 22 , 20 , 20 , 22 , 0 , 0 , 36 , 36 , 0 , 0 , 0 , 0 , 0 , 0 , 36 , 30 , 15 , 80 , 80 , 102 , 102 , 102 , 102 , 102 , 102
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0

DATA  0 , 10 , 10 , 2 , 6 , 6 , 6 , 18 , 18 , 18 , 0 , 18 , 4 , 18 , 4 , 4 , 40 , 4 , 4 , 4 , 112 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 2 , 10 , 6 , 6 , 6 , 18 , 18 , 0 , 4 , 18 , 40 , 4 , 18 , 40 , 4 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 2 , 2 , 105 , 1 , 1
DATA  0 , 10 , 10 , 10 , 6 , 10 , 6 , 6 , 42 , 18 , 0 , 18 , 40 , 40 , 4 , 40 , 4 , 112 , 18 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 2 , 6 , 6 , 6 , 42 , 18 , 18 , 0 , 18 , 40 , 40 , 40 , 18 , 18 , 18 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1
DATA  0 , 10 , 10 , 10 , 6 , 42 , 42 , 18 , 18 , 18 , 0 , 18 , 18 , 4 , 4 , 40 , 40 , 40 , 40 , 112 , 112 , 2 , 2 , 2 , 1 , 1 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 2 , 10 , 10 , 6 , 10 , 6 , 18 , 18 , 0 , 40 , 18 , 40 , 40 , 40 , 40 , 18 , 18 , 112 , 112 , 2 , 2 , 2 , 105 , 2 , 105 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 10 , 10 , 10 , 6 , 6 , 18 , 18 , 0 , 18 , 4 , 4 , 4 , 40 , 18 , 112 , 40 , 18 , 112 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 10 , 2 , 10 , 6 , 6 , 6 , 6 , 18 , 0 , 18 , 18 , 18 , 4 , 4 , 40 , 4 , 4 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1
DATA  0 , 10 , 2 , 2 , 6 , 6 , 6 , 6 , 42 , 18 , 0 , 18 , 40 , 40 , 40 , 18 , 4 , 4 , 112 , 112 , 112 , 2 , 2 , 2 , 2 , 105 , 1 , 2 , 2 , 2 , 105
DATA  0 , 10 , 10 , 2 , 2 , 6 , 42 , 42 , 18 , 18 , 0 , 18 , 18 , 18 , 4 , 4 , 40 , 4 , 112 , 112 , 112 , 2 , 2 , 105 , 1 , 1 , 1 , 1 , 1 , 1 , 1
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 22 , 22 , 22 , 18 , 22 , 22 , 20 , 22 , 22 , 0 , 0 , 0 , 5 , 5 , 0 , 0 , 0 , 0 , 0 , 5 , 30 , 15 , 77 , 80 , 77 , 102 , 77 , 102 , 102 , 102
DATA  0 , 18 , 18 , 20 , 20 , 22 , 20 , 20 , 22 , 22 , 0 , 0 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 5 , 5 , 30 , 15 , 77 , 77 , 77 , 77 , 77 , 77 , 77 , 102
DATA  0 , 22 , 22 , 22 , 20 , 22 , 20 , 22 , 20 , 20 , 0 , 0 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 36 , 5 , 30 , 15 , 15 , 80 , 80 , 102 , 77 , 102 , 102 , 102
DATA  0 , 22 , 22 , 22 , 20 , 18 , 22 , 22 , 22 , 22 , 0 , 0 , 0 , 35 , 35 , 180 , 108 , 108 , 108 , 36 , 36 , 30 , 15 , 15 , 80 , 77 , 80 , 77 , 77 , 77 , 102
DATA  0 , 22 , 20 , 20 , 22 , 18 , 16 , 20 , 20 , 20 , 0 , 0 , 0 , 35 , 35 , 108 , 5 , 5 , 5 , 36 , 36 , 30 , 15 , 15 , 15 , 102 , 80 , 77 , 77 , 77 , 102
DATA  0 , 20 , 20 , 22 , 22 , 20 , 18 , 18 , 18 , 20 , 0 , 0 , 0 , 35 , 35 , 108 , 5 , 5 , 5 , 36 , 36 , 30 , 15 , 15 , 80 , 80 , 102 , 77 , 102 , 77 , 102
DATA  0 , 20 , 22 , 22 , 20 , 18 , 22 , 22 , 22 , 18 , 0 , 0 , 0 , 35 , 35 , 5 , 35 , 35 , 35 , 36 , 36 , 30 , 15 , 80 , 80 , 80 , 102 , 102 , 102 , 77 , 102
DATA  0 , 20 , 20 , 22 , 18 , 22 , 20 , 20 , 22 , 22 , 0 , 0 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 36 , 36 , 30 , 15 , 15 , 15 , 15 , 102 , 77 , 77 , 77 , 102
DATA  0 , 22 , 22 , 20 , 18 , 22 , 22 , 20 , 20 , 22 , 0 , 0 , 0 , 35 , 35 , 0 , 0 , 0 , 0 , 36 , 36 , 30 , 15 , 15 , 15 , 102 , 77 , 77 , 77 , 102 , 102
DATA  0 , 22 , 22 , 22 , 20 , 22 , 22 , 20 , 20 , 22 , 0 , 0 , 0 , 36 , 36 , 0 , 0 , 0 , 0 , 0 , 36 , 30 , 15 , 80 , 80 , 102 , 102 , 102 , 102 , 102 , 102
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0

DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 112 , 112 , 112 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 14 , 14 , 14 , 14 , 0 , 0 , 0 , 0 , 112 , 4 , 4 , 4 , 112 , 0 , 0 , 0 , 0
DATA  0 , 0 , 1 , 1 , 105 , 105 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 14 , 42 , 42 , 42 , 42 , 14 , 0 , 0 , 0 , 4 , 4 , 4 , 4 , 4 , 112 , 0 , 0 , 0
DATA  0 , 0 , 1 , 1 , 1 , 1 , 105 , 1 , 0 , 0 , 0 , 0 , 14 , 42 , 14 , 14 , 14 , 14 , 42 , 14 , 0 , 0 , 40 , 4 , 4 , 4 , 4 , 4 , 112 , 0 , 0
DATA  0 , 0 , 1 , 9 , 1 , 1 , 105 , 1 , 0 , 0 , 0 , 0 , 14 , 14 , 14 , 14 , 14 , 14 , 14 , 14 , 0 , 0 , 0 , 40 , 40 , 4 , 4 , 4 , 4 , 40 , 0
DATA  0 , 0 , 1 , 9 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 0 , 14 , 14 , 14 , 14 , 14 , 14 , 14 , 14 , 0 , 0 , 112 , 4 , 4 , 4 , 4 , 4 , 40 , 0 , 0
DATA  0 , 0 , 1 , 9 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 0 , 42 , 14 , 14 , 14 , 14 , 14 , 14 , 42 , 0 , 0 , 4 , 4 , 4 , 4 , 4 , 40 , 0 , 0 , 0
DATA  0 , 0 , 1 , 1 , 9 , 9 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 42 , 14 , 14 , 14 , 14 , 42 , 0 , 0 , 0 , 40 , 4 , 4 , 4 , 40 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 0 , 18 , 0 , 0 , 42 , 42 , 42 , 42 , 0 , 0 , 0 , 0 , 0 , 40 , 40 , 40 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 3 , 3 , 0 , 3 , 3 , 3 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 3 , 0 , 0 , 3 , 6 , 6 , 3 , 6 , 6 , 6 , 3 , 0 , 0 , 0 , 2 , 2 , 2 , 2 , 0 , 0 , 0
DATA  0 , 0 , 35 , 35 , 5 , 5 , 36 , 36 , 0 , 0 , 198 , 3 , 3 , 6 , 6 , 6 , 6 , 6 , 20 , 6 , 3 , 0 , 0 , 2 , 10 , 10 , 10 , 10 , 2 , 0 , 0
DATA  0 , 0 , 35 , 35 , 5 , 5 , 36 , 36 , 0 , 0 , 198 , 198 , 198 , 6 , 20 , 6 , 6 , 6 , 6 , 6 , 3 , 0 , 2 , 10 , 40 , 40 , 0 , 40 , 10 , 2 , 0
DATA  0 , 0 , 35 , 35 , 5 , 5 , 36 , 36 , 0 , 0 , 198 , 198 , 198 , 6 , 6 , 6 , 6 , 20 , 6 , 6 , 3 , 2 , 10 , 40 , 0 , 40 , 40 , 40 , 40 , 10 , 2
DATA  0 , 0 , 35 , 35 , 5 , 5 , 36 , 36 , 0 , 0 , 198 , 52 , 52 , 6 , 6 , 20 , 6 , 6 , 6 , 20 , 3 , 48 , 70 , 12 , 12 , 12 , 12 , 12 , 0 , 70 , 48
DATA  0 , 0 , 35 , 35 , 5 , 5 , 36 , 36 , 0 , 0 , 52 , 0 , 0 , 52 , 6 , 6 , 52 , 6 , 6 , 6 , 52 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 52 , 52 , 0 , 52 , 3 , 52 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0

DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 112 , 112 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 1 , 1 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 14 , 14 , 14 , 14 , 0 , 0 , 0 , 0 , 0 , 112 , 4 , 4 , 112 , 0 , 0 , 0 , 0
DATA  0 , 1 , 1 , 1 , 105 , 105 , 105 , 1 , 1 , 0 , 0 , 0 , 0 , 14 , 42 , 42 , 42 , 42 , 14 , 0 , 0 , 0 , 0 , 40 , 4 , 4 , 4 , 112 , 0 , 0 , 0
DATA  0 , 1 , 9 , 1 , 1 , 1 , 1 , 105 , 1 , 0 , 0 , 0 , 14 , 42 , 14 , 14 , 14 , 14 , 42 , 14 , 0 , 0 , 0 , 0 , 40 , 4 , 4 , 4 , 40 , 0 , 0
DATA  0 , 1 , 9 , 1 , 1 , 1 , 1 , 105 , 1 , 0 , 0 , 0 , 42 , 14 , 14 , 14 , 14 , 14 , 14 , 42 , 0 , 0 , 0 , 112 , 4 , 4 , 4 , 40 , 0 , 0 , 0
DATA  0 , 1 , 1 , 9 , 9 , 9 , 1 , 1 , 1 , 0 , 0 , 0 , 0 , 42 , 14 , 14 , 14 , 14 , 42 , 0 , 0 , 0 , 0 , 40 , 4 , 4 , 40 , 0 , 0 , 0 , 0
DATA  0 , 0 , 1 , 1 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 42 , 42 , 42 , 42 , 0 , 0 , 0 , 0 , 0 , 0 , 40 , 40 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 18 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 3 , 3 , 0 , 3 , 3 , 3 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 3 , 0 , 0 , 3 , 6 , 6 , 3 , 6 , 6 , 6 , 3 , 0 , 0 , 0 , 2 , 2 , 2 , 2 , 0 , 0 , 0
DATA  0 , 0 , 5 , 5 , 36 , 36 , 35 , 35 , 0 , 0 , 198 , 3 , 3 , 6 , 6 , 6 , 6 , 20 , 6 , 6 , 3 , 0 , 0 , 2 , 2 , 2 , 2 , 2 , 2 , 0 , 0
DATA  0 , 0 , 5 , 5 , 36 , 36 , 35 , 35 , 0 , 0 , 198 , 198 , 198 , 20 , 6 , 6 , 6 , 6 , 6 , 6 , 3 , 0 , 2 , 2 , 10 , 10 , 10 , 10 , 2 , 2 , 0
DATA  0 , 0 , 5 , 5 , 36 , 36 , 35 , 35 , 0 , 0 , 198 , 198 , 198 , 6 , 6 , 6 , 20 , 6 , 6 , 6 , 3 , 2 , 2 , 10 , 40 , 40 , 0 , 40 , 10 , 2 , 2
DATA  0 , 0 , 5 , 5 , 36 , 36 , 35 , 35 , 0 , 0 , 198 , 52 , 52 , 6 , 20 , 6 , 6 , 6 , 20 , 6 , 3 , 2 , 70 , 40 , 0 , 40 , 40 , 40 , 40 , 70 , 2
DATA  0 , 0 , 5 , 5 , 36 , 36 , 35 , 35 , 0 , 0 , 52 , 0 , 0 , 52 , 6 , 6 , 52 , 6 , 6 , 6 , 52 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 52 , 52 , 0 , 52 , 3 , 52 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0

DATA  0 , 0 , 0 , 0 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 1 , 105 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 1 , 1 , 105 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 112 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 1 , 1 , 105 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 112 , 4 , 112 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 42 , 42 , 42 , 42 , 42 , 42 , 42 , 42 , 0 , 0 , 0 , 0 , 0 , 4 , 4 , 40 , 0 , 0 , 0
DATA  0 , 0 , 0 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 14 , 14 , 14 , 14 , 14 , 14 , 14 , 14 , 0 , 0 , 0 , 0 , 40 , 4 , 40 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 1 , 9 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 40 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 1 , 9 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 1 , 1 , 9 , 1 , 0 , 0 , 0 , 0 , 18 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 3 , 3 , 0 , 3 , 3 , 3 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 3 , 0 , 0 , 3 , 6 , 6 , 3 , 6 , 6 , 6 , 3 , 0 , 0 , 0 , 48 , 48 , 48 , 48 , 0 , 0 , 0
DATA  0 , 0 , 36 , 36 , 35 , 35 , 5 , 5 , 0 , 0 , 198 , 3 , 3 , 6 , 6 , 6 , 20 , 6 , 6 , 6 , 3 , 0 , 0 , 48 , 40 , 40 , 0 , 40 , 48 , 0 , 0
DATA  0 , 0 , 36 , 36 , 35 , 35 , 5 , 5 , 0 , 0 , 198 , 198 , 198 , 6 , 6 , 6 , 6 , 6 , 6 , 6 , 3 , 0 , 48 , 40 , 0 , 40 , 40 , 40 , 40 , 48 , 0
DATA  0 , 0 , 36 , 36 , 35 , 35 , 5 , 5 , 0 , 0 , 198 , 198 , 198 , 6 , 6 , 20 , 6 , 6 , 6 , 6 , 3 , 48 , 12 , 12 , 12 , 12 , 12 , 12 , 0 , 12 , 48
DATA  0 , 0 , 36 , 36 , 35 , 35 , 5 , 5 , 0 , 0 , 198 , 52 , 52 , 20 , 6 , 6 , 6 , 20 , 6 , 6 , 3 , 12 , 0 , 12 , 12 , 12 , 12 , 12 , 12 , 12 , 12
DATA  0 , 0 , 36 , 36 , 35 , 35 , 5 , 5 , 0 , 0 , 52 , 0 , 0 , 52 , 6 , 6 , 52 , 6 , 6 , 6 , 52 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 52 , 52 , 0 , 52 , 3 , 52 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
DATA  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0

