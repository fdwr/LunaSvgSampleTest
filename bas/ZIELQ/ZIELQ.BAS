'Ziel 11-2-97, Jay Cook (C)1997. READ ZIEL.TXT and RUN setup.bas:Added keyboard fix
'$DYNAMIC
DEFINT A-Z
DECLARE SUB Putimg (x111%, y111%, s11%())
DECLARE SUB putimt (x111%, y111%, s11%())
DECLARE SUB Put2 (x111%, y111%, s11%())
DECLARE FUNCTION GETS (x111%, y111%, x211%, y211%, s11%())
DECLARE FUNCTION GETT (x111%, y111%, x211%, y211%, s11%())
DECLARE FUNCTION GET2 (x111%, y111%, x211%, y211%, s11%())
DECLARE SUB cycle (st2%, st1%)
DECLARE SUB pic ()
DECLARE SUB zmap ()
DECLARE SUB zinit ()
DECLARE SUB upt ()
DECLARE SUB mov ()
DECLARE SUB wll ()
DECLARE SUB endscrn ()
DECLARE SUB zinfo ()
DECLARE SUB go1 ()
DECLARE SUB hit ()
DECLARE SUB warp ()
DECLARE SUB hom ()
DECLARE SUB playfx (FXnum)
DECLARE FUNCTION LoadFX (Filename$)
DECLARE SUB paus ()
DECLARE SUB owll ()
DECLARE SUB oa ()
DECLARE SUB ObjR ()
DECLARE SUB Oar ()
DECLARE SUB tile123 ()
DECLARE SUB hdis ()
DECLARE SUB pause1 ()
DECLARE SUB set1 ()
DECLARE SUB sign1 ()
DECLARE SUB zhit ()
DECLARE SUB zstrk ()
DECLARE SUB qberr ()
DECLARE SUB zmld ()
DECLARE SUB zdie ()
DECLARE SUB hit2 ()
DECLARE SUB zflyba ()
DECLARE SUB zinfos ()
DECLARE SUB getobj ()
DECLARE SUB ldlist ()
COMMON SHARED n$, S$, w$, E$, sx%, SY%, b, wlmx, wl$(), ln$, b2, wlm2, ln2$, wl2$(), dr, Yn
COMMON SHARED x, y, xa, ya, xx, yy, sx2%, SY2%, mx, my, mmx, mmy, pict$, map$, htt, ht3
COMMON SHARED devm, mxht, uptd, gamnam$, ht, dat1$, map2$, wl$, wl2$, del, ht2
COMMON SHARED mnx, mny, mmmx, mmmy, tx, ty, mv, d, mn2, ms, nmp22, mp$, gfx2, ht1
COMMON SHARED hom1, pp3, bbp, mvp, mv22, mvp5, ttt, dly1, xx2, yy2, mvn2, r$
COMMON SHARED mn, sy1%, sx1%, xa2, ya2, T3, px, sd, xz3, Ox, Oy, ox2, oy2, ox3, oy3
COMMON SHARED oamv, oad, oed, oax, oay, oax2, oay2, ht4, hx, hy, time1, tim1
COMMON SHARED obtp, Xax, yax, Dob, Mvob, obn, onx, ony, oxx, oyy, Xaa, Yaa, mv2
COMMON SHARED Xn2, Yn2, htm, xx3, yy3, n2$, mp2$, set$, set2$, pic1$, gold%
COMMON SHARED ott, flsh, flash1, sprtg, sprtt, zhp, mzhp, flash2, otxt7$, otxt8$
COMMON SHARED o16, o26, o36, o46, o56, o66, otxt1$, otxt2$, otxt3$, otxt4$, otxt5$, otxt6$
COMMON SHARED o12, o22, o32, o42, o52, o62, o13, o23, o33, o43, o53, o63
COMMON SHARED o14, o24, o34, o44, o54, o64, o15, o25, o35, o45, o55, o65
COMMON SHARED o17, o27, o37, o47, o57, o67, o18, o28, o38, o48, o58, o68
COMMON SHARED o71, o72, o73, o74, o75, o76, o11, o21, o31, o41, o51, o61
COMMON SHARED o77, o78, qbasic1, ox2nn, oy2nn, y222, x222, mvb, oxx2, oyy2, on2
COMMON SHARED zfb, zfbn, zfb2, x2, y2, zdd, txt$, sword1, rmnb, room2, room3
COMMON SHARED map3$, r, n, zcp, mxobjn, roomnum, keys, room11, mapend$
RANDOMIZE TIMER
SCREEN 13
mxobjn = 3: 'how many objects
DIM SHARED rm$(mxobjn): 'room
DIM SHARED objnum(mxobjn) AS INTEGER: 'graphics number
DIM SHARED zgf1(mxobjn) AS INTEGER: 'which frame ziel uses when hold up obj
ldlist
rmnb = 4:
DIM SHARED room1$(rmnb)
DIM SHARED zbgp(1)
DIM SHARED objfu(1)
DIM SHARED robj1(rmnb) AS INTEGER
DIM SHARED robj2(rmnb) AS INTEGER
DIM SHARED robj3(rmnb) AS INTEGER
DIM SHARED robj4(rmnb) AS INTEGER
DIM SHARED robj5(rmnb) AS INTEGER
DIM SHARED robj6(rmnb) AS INTEGER
DIM SHARED robj7(rmnb) AS INTEGER
DIM SHARED robj8(rmnb) AS INTEGER
DEF SEG = &HA000
REDIM SHARED snd(1 TO 500) AS STRING * 30
RESULT = LoadFX("Ziel.SND")
DIM SHARED wl3(240) AS INTEGER
DIM SHARED wl4(240) AS INTEGER
OPEN "ziel.cfg" FOR INPUT AS #1
INPUT #1, sprtg
INPUT #1, sprtt
INPUT #1, sd
INPUT #1, qbasic1
CLOSE
IF sprtg = 0 THEN sprtg = 1
IF sprtt = 0 THEN sprtt = 1
TYPE obj1
  obtp AS INTEGER: 'Object number(max 8)
  Xax AS INTEGER: 'X-coord
  yax AS INTEGER: 'Y-coord
  Dob AS INTEGER: 'Direction
  Mvob AS INTEGER: 'cycle number
  Xaa AS INTEGER: 'Old X Pos
  Yaa AS INTEGER: 'Old Y Pos
  Mvob2 AS INTEGER:
  Obna AS INTEGER
  Omv AS INTEGER
  Ohp AS INTEGER: ' Object hit points
  Oht1 AS INTEGER: ' Object can only be hit once, a register
  ht2 AS INTEGER: 'When hit fly back direction
  ht3 AS INTEGER: 'Can you hit object?
  ht4 AS INTEGER: 'object flying back number of times
END TYPE
TYPE ObjCFG: 'Object configuration
  Ornd AS INTEGER: 'Random movement?(Only kind of movement setup)
  Omvl AS INTEGER: 'Object moves or stationary
  OSpd AS INTEGER: 'Object Speed
  Obmhp AS INTEGER: ' Object max hp
  Obhrm AS INTEGER: ' Amount of harm object will do(0 if none)
  Obwall AS INTEGER: ' Obay walls(can or can't go threw them)
  Obmny AS INTEGER: 'Money-how much
  obtalk AS INTEGER: 'Does object say anything when you hit it?
END TYPE
DIM SHARED obje(8) AS obj1
DIM SHARED objCFG1(8) AS ObjCFG
DIM SHARED zget1(256) AS INTEGER
DIM SHARED zget2(256) AS INTEGER
DIM SHARED d1(256) AS INTEGER
DIM SHARED d2(256) AS INTEGER
DIM SHARED d3(256) AS INTEGER
DIM SHARED u1(256) AS INTEGER
DIM SHARED u2(256) AS INTEGER
DIM SHARED u3(256) AS INTEGER
DIM SHARED r1(256) AS INTEGER
DIM SHARED r2(256) AS INTEGER
DIM SHARED R3(256) AS INTEGER
DIM SHARED l1(256) AS INTEGER
DIM SHARED l2(256) AS INTEGER
DIM SHARED l3(256) AS INTEGER
DIM SHARED dh(256) AS INTEGER
DIM SHARED uh(256) AS INTEGER
DIM SHARED rh(256) AS INTEGER
DIM SHARED lh(256) AS INTEGER
DIM SHARED obj1(256) AS INTEGER
DIM SHARED obj2(256) AS INTEGER
DIM SHARED obj3(256) AS INTEGER
DIM SHARED obj4(256) AS INTEGER
DIM SHARED obj5(256) AS INTEGER
DIM SHARED mny1(256) AS INTEGER
DIM SHARED mny2(256) AS INTEGER
DIM SHARED lf1(256) AS INTEGER
DIM SHARED bg1(256) AS INTEGER
DIM SHARED BG1S(256) AS INTEGER
DIM SHARED sw1(256) AS INTEGER
DIM SHARED sw2(256) AS INTEGER
DIM SHARED sw3(256) AS INTEGER
DIM SHARED sw4(256) AS INTEGER
DIM SHARED BGA(256) AS INTEGER
DIM SHARED BGB(256) AS INTEGER
DIM SHARED BGC(256) AS INTEGER
DIM SHARED BGD(256) AS INTEGER
DIM SHARED BGE(256) AS INTEGER
DIM SHARED BGF(256) AS INTEGER
DIM SHARED BGG(256) AS INTEGER
DIM SHARED BGH(256) AS INTEGER
DIM SHARED a1(256) AS INTEGER
DIM SHARED a2(256) AS INTEGER
DIM SHARED a3(256) AS INTEGER
DIM SHARED a4(256) AS INTEGER
DIM SHARED a5(256) AS INTEGER
DIM SHARED a6(256) AS INTEGER
DIM SHARED a7(256) AS INTEGER
DIM SHARED a8(256) AS INTEGER
DIM SHARED b1(256) AS INTEGER
DIM SHARED b22(256) AS INTEGER
DIM SHARED b3(256) AS INTEGER
DIM SHARED b4(256) AS INTEGER
DIM SHARED b5(256) AS INTEGER
DIM SHARED b6(256) AS INTEGER
DIM SHARED b7(256) AS INTEGER
DIM SHARED b8(256) AS INTEGER
DIM SHARED c1(256) AS INTEGER
DIM SHARED c2(256) AS INTEGER
DIM SHARED c3(256) AS INTEGER
DIM SHARED c4(256) AS INTEGER
DIM SHARED c5(256) AS INTEGER
DIM SHARED c6(256) AS INTEGER
DIM SHARED c7(256) AS INTEGER
DIM SHARED c8(256) AS INTEGER
DIM SHARED d11(256) AS INTEGER
DIM SHARED d21(256) AS INTEGER
DIM SHARED d31(256) AS INTEGER
DIM SHARED d4(256) AS INTEGER
DIM SHARED d5(256) AS INTEGER
DIM SHARED d6(256) AS INTEGER
DIM SHARED d7(256) AS INTEGER
DIM SHARED d8(256) AS INTEGER
DIM SHARED e1(256) AS INTEGER
DIM SHARED e2(256) AS INTEGER
DIM SHARED e3(256) AS INTEGER
DIM SHARED e4(256) AS INTEGER
DIM SHARED e5(256) AS INTEGER
DIM SHARED e6(256) AS INTEGER
DIM SHARED e7(256) AS INTEGER
DIM SHARED e8(256) AS INTEGER
DIM SHARED f1(256) AS INTEGER
DIM SHARED f2(256) AS INTEGER
DIM SHARED f3(256) AS INTEGER
DIM SHARED f4(256) AS INTEGER
DIM SHARED f5(256) AS INTEGER
DIM SHARED f6(256) AS INTEGER
DIM SHARED f7(256) AS INTEGER
DIM SHARED f8(256) AS INTEGER
DIM SHARED g1(256) AS INTEGER
DIM SHARED g2(256) AS INTEGER
DIM SHARED g3(256) AS INTEGER
DIM SHARED g4(256) AS INTEGER
DIM SHARED g5(256) AS INTEGER
DIM SHARED g6(256) AS INTEGER
DIM SHARED g7(256) AS INTEGER
DIM SHARED g8(256) AS INTEGER
DIM SHARED h1(256) AS INTEGER
DIM SHARED h2(256) AS INTEGER
DIM SHARED h3(256) AS INTEGER
DIM SHARED h4(256) AS INTEGER
DIM SHARED h5(256) AS INTEGER
DIM SHARED h6(256) AS INTEGER
DIM SHARED h7(256) AS INTEGER
DIM SHARED h8(256) AS INTEGER
DIM SHARED T1(256) AS INTEGER
DIM SHARED t2(256) AS INTEGER
DIM SHARED T3a(256) AS INTEGER
DIM SHARED t4(256) AS INTEGER
DIM SHARED t5(256) AS INTEGER
DIM SHARED t6(256) AS INTEGER
DIM SHARED t7(256) AS INTEGER
DIM SHARED t8(256) AS INTEGER
DIM SHARED t9(256) AS INTEGER
DIM SHARED t10(256) AS INTEGER
DIM SHARED t11(256) AS INTEGER
DIM SHARED t12(256) AS INTEGER
DIM SHARED t13(256) AS INTEGER
DIM SHARED t14(256) AS INTEGER
DIM SHARED t15(256) AS INTEGER
DIM SHARED t16(256) AS INTEGER
DIM SHARED t17(256) AS INTEGER
DIM SHARED t18(256) AS INTEGER
DIM SHARED t19(256) AS INTEGER
DIM SHARED t20(256) AS INTEGER
DIM SHARED t21(256) AS INTEGER
DIM SHARED t22(256) AS INTEGER
DIM SHARED t23(256) AS INTEGER
DIM SHARED t24(256) AS INTEGER
DIM SHARED t25(256) AS INTEGER
DIM SHARED t26(256) AS INTEGER
DIM SHARED t27(256) AS INTEGER
DIM SHARED t28(256) AS INTEGER
DIM SHARED t29(256) AS INTEGER
DIM SHARED t30(256) AS INTEGER
DIM SHARED t31(256) AS INTEGER
DIM SHARED t32(256) AS INTEGER
DIM SHARED t33(256) AS INTEGER
DIM SHARED t34(256) AS INTEGER
DIM SHARED t35(256) AS INTEGER
DIM SHARED t36(256) AS INTEGER
DIM SHARED t37(256) AS INTEGER
DIM SHARED t38(256) AS INTEGER
DIM SHARED t39(256) AS INTEGER
DIM SHARED t40(256) AS INTEGER
DIM SHARED t41(256) AS INTEGER
DIM SHARED t42(256) AS INTEGER
DIM SHARED t43(256) AS INTEGER
DIM SHARED t44(256) AS INTEGER
DIM SHARED t45(256) AS INTEGER
DIM SHARED t46(256) AS INTEGER
DIM SHARED t47(256) AS INTEGER
DIM SHARED t48(256) AS INTEGER
DIM SHARED t49(256) AS INTEGER
DIM SHARED t50(256) AS INTEGER
DIM SHARED ho1(256) AS INTEGER
DIM SHARED ho2(256) AS INTEGER
OUT &H3C4, 1:   CMR% = INP(&H3C5): OUT &H3C5, CMR% OR &H20
pict$ = "sprt.gfx": pic
RESULT = GETS(1, 18, 16, 33, sw1())
RESULT = GETS(18, 18, 33, 33, sw2())
RESULT = GETS(35, 18, 50, 33, sw3())
RESULT = GETS(52, 18, 67, 33, sw4())
RESULT = GETS(205, 18, 220, 33, ho1())
RESULT = GETS(222, 18, 237, 33, ho2())
RESULT = GETS(188, 18, 203, 33, mny2())
RESULT = GETS(239, 18, 254, 33, mny1())
RESULT = GETS(256, 18, 271, 33, lf1())
RESULT = GETS(1, 1, 16, 16, zget1())
RESULT = GETS(18, 1, 16, 33, zget2())
RESULT = GETS(35, 1, 50, 16, d1())
RESULT = GETS(52, 1, 67, 16, d2())
RESULT = GETS(69, 1, 84, 16, d3())
RESULT = GETS(86, 1, 101, 16, u1())
RESULT = GETS(103, 1, 118, 16, u2())
RESULT = GETS(120, 1, 135, 16, u3())
RESULT = GETS(137, 1, 152, 16, r1())
RESULT = GETS(154, 1, 169, 16, r2())
RESULT = GETS(171, 1, 186, 16, R3())
RESULT = GETS(188, 1, 203, 16, l1())
RESULT = GETS(205, 1, 220, 16, l2())
RESULT = GETS(222, 1, 237, 16, l3())
RESULT = GETS(239, 1, 254, 16, dh())
RESULT = GETS(256, 1, 271, 16, uh())
RESULT = GETS(273, 1, 288, 16, lh())
RESULT = GETS(290, 1, 305, 16, rh())
CLS
OUT &H3C4, 1: CMR% = INP(&H3C5): OUT &H3C5, CMR% AND &HDF
zinit
OPEN "start.txt" FOR INPUT AS #1
INPUT #1, txt$
CLOSE
sword1 = 0
sign1
DO:
'LOCATE 2, 1: PRINT FRE(-1): 'show free memory
   a$ = INKEY$
    IF a$ = CHR$(27) THEN endscrn
    IF LCASE$(a$) = "s" THEN IF sd = 1 THEN sd = 0:  ELSE sd = 1
    IF LCASE$(a$) = "j" THEN IF js = 0 THEN js = 1:  ELSE js = 0
    mv2 = mv: WHILE LEN(INKEY$): WEND
   SELECT CASE INP(96)
      CASE 23: zinfo
      CASE 25: pause1
      CASE 56: IF zfbn = 0 THEN ht1 = 1: ht4 = 1: IF ht2 = 0 THEN ht2 = 1
      CASE 57: IF zfbn = 0 THEN ht1 = 1: ht4 = 1: IF ht2 = 0 THEN ht2 = 1
      CASE 72: IF ht1 = 0 AND zfbn = 0 THEN d = 1: y = y - ms: mv = mv + 1: wll
      CASE 75: IF ht1 = 0 AND zfbn = 0 THEN d = 3: x = x - ms: mv = mv + 1: wll
      CASE 77: IF ht1 = 0 AND zfbn = 0 THEN d = 4: x = x + ms: mv = mv + 1: wll
      CASE 80: IF ht1 = 0 AND zfbn = 0 THEN d = 2: y = y + ms: mv = mv + 1: wll
  END SELECT
 paus
 cycle 242, 255
 upt
LOOP UNTIL zdd = 1
zdead:
zdie
a$ = INKEY$
endscrn

REM $STATIC
SUB cycle (st2%, st1%)
OUT &H3C7, st1%
BC1 = INP(&H3C9)
BC2 = INP(&H3C9)
BC3 = INP(&H3C9)
FOR E = st1% TO st2% STEP -1
OUT &H3C7, E - 1
c1 = INP(&H3C9)
c2 = INP(&H3C9)
c3 = INP(&H3C9)
OUT &H3C8, E: OUT &H3C9, c1: OUT &H3C9, c2: OUT &H3C9, c3
NEXT E
OUT &H3C8, st2: OUT &H3C9, BC1: OUT &H3C9, BC2: OUT &H3C9, BC3
END SUB

SUB endscrn
OPEN "ziel.cfg" FOR OUTPUT AS #1
PRINT #1, sprtg
PRINT #1, sprtt
PRINT #1, sd
PRINT #1, qbasic1
CLOSE
CLS
SCREEN 0: WIDTH 80
COLOR 9, 0
PRINT "                                 --- Ziel ---"
COLOR 15, 0
PRINT
PRINT "                  An action adventure game with rich graphics"
PRINT "                         and Sound Blaster FM sound FX"
PRINT "                            This is a demo version."
PRINT
PRINT
COLOR 13, 0
PRINT "http://members.tripod.com/~ziel/ziel.htm    -=-  Ziel developement page"
PRINT
COLOR 9, 0
PRINT "Developer: "
COLOR 15
LOCATE 10, 33
PRINT "Jay Cook               jaycook1@juno.com"
PRINT
COLOR 12
PRINT "Sound routines and Sound FX:"
LOCATE 12, 33
COLOR 15
PRINT "Angelo Mottola         angelillo@geocities.com"
IF INKEY$ = "" THEN t = 1
SYSTEM
END SUB

FUNCTION GET2 (x111%, y111%, x211%, y211%, s11%())
GET (x111%, y111%)-(x211%, y211%), s11%: GOTO gtnd2
gtnd2:
END FUNCTION

SUB getobj
room11 = 0
IF objnum(roomnum) = 5 AND keys < 1 THEN room11 = 1: GOTO rm1
playfx 9
SELECT CASE obn
CASE 1: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGA, PSET
CASE 2: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGB, PSET
CASE 3: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGC, PSET
CASE 4: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGD, PSET
CASE 5: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGE, PSET
CASE 6: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGF, PSET
CASE 7: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGG, PSET
CASE 8: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGH, PSET
END SELECT
IF zgf1(roomnum) = 0 THEN GOTO rm2
PUT (xa, ya + 8), bg1, PSET:
REDIM zbgp(256): REDIM objfu(256): d = 2
IF zgf1(roomnum) = 1 THEN GET (x, y + 8)-(x + 16, y + 16 + 8), zbgp: GET (x, y - 15 + 8)-(x + 16, y + 1 + 8), objfu: Putimg x, y, zget1()
IF zgf1(roomnum) = 2 THEN GET (x, y + 8)-(x + 16, y + 16 + 8), zbgp: GET (x - 6, y - 15 + 8)-(x - 6 + 16, y + 1 + 8), objfu: Putimg x, y, zget2()
SELECT CASE objnum(roomnum)
CASE 1: sword1 = 1: Putimg x - 5, y - 15, sw1()
CASE 2: keys = keys + 1: Putimg x - 5, y - 15, obj2()
CASE 5: keys = keys - 1
END SELECT
FOR n = 1 TO 15
paus
NEXT
rm2:
sign1
IF zgf1(roomnum) = 1 THEN PUT (x, y + 8), zbgp, PSET: PUT (x, y - 15 + 8), objfu, PSET
IF zgf1(roomnum) = 2 THEN PUT (x, y + 8), zbgp, PSET: PUT (x - 6, y - 15 + 8), objfu, PSET
REDIM zbgp(1): REDIM objfu(1)
rm$(roomnum) = "NONE"
rm1:
END SUB

FUNCTION GETS (x111%, y111%, x211%, y211%, s11%())
SELECT CASE sprtg
CASE 1: GET (x111%, y111%)-(x111% + 15, y111% + 15), s11%:
CASE 2: GOSUB gt2
CASE 3: GOSUB gt2
END SELECT
GOTO gtnd:
gt2:
xz3 = 15
xz = x111%: yz = y111%
xz2 = xz: yz1 = yz
 FOR b5 = 1 TO 256
  IF xz > xz2 + xz3 THEN xz = xz2: yz = yz + 1
    s11%(b5) = POINT(xz, yz)
  xz = xz + 1
NEXT
RETURN
gtnd:
END FUNCTION

FUNCTION GETT (x111%, y111%, x211%, y211%, s11%())
SELECT CASE sprtt
CASE 1: GET (x111%, y111%)-(x111% + 15, y111% + 15), s11%:
CASE 2: GOSUB gt1
CASE 3: GOSUB gt1
END SELECT
GOTO gtnd3
gt1:
xz3 = 15
xz = x111%: yz = y111%
xz2 = xz: yz1 = yz
FOR b5 = 1 TO 256
  IF xz > xz2 + xz3 THEN xz = xz2: yz = yz + 1
    s11%(b5) = POINT(xz, yz)
  xz = xz + 1
NEXT
RETURN
gtnd3:
END FUNCTION

SUB go1
go1:
map2$ = map$
xxx = xa: yyy = ya
GOSUB room
IF rm2 = 1 THEN x = xa: y = ya: GOTO go1nd
GOTO go1nd
room:
rm2 = 0
IF dr = 1 AND n$ = "NONE" THEN rm2 = 1: RETURN
IF dr = 2 AND S$ = "NONE" THEN rm2 = 1: bbp = 1: RETURN
IF dr = 3 AND w$ = "NONE" THEN rm2 = 1: RETURN
IF dr = 4 AND E$ = "NONE" THEN rm2 = 1: RETURN
GOSUB load
rm2 = 1
RETURN
load:
GOSUB rch:
IF dr = 1 THEN map$ = n$
IF dr = 2 THEN map$ = S$
IF dr = 3 THEN map$ = w$
IF dr = 4 THEN map$ = E$
IF dr = 5 THEN map$ = r$
GOSUB go2
zmap
upt
RETURN
go2:
IF dr = 1 THEN x = x: y = 192 - 19
IF dr = 2 THEN x = x: y = 0:
IF dr = 3 THEN y = y: x = 320 - 16
IF dr = 4 THEN y = y: x = 1
IF dr = 5 THEN y = SY%: x = sx%
xa = x: ya = y:
RETURN
rch:
r = 0:
FOR n = 1 TO rmnb - 1
IF room1$(rmnb - n) = map3$ THEN r = n:
NEXT
tr5:
FOR n = 1 TO rmnb - 1
t = rmnb
 IF r >= n THEN GOTO ak1
 room1$(rmnb - n + 1) = room1$(rmnb - n)
 robj1(rmnb - n + 1) = robj1(rmnb - n)
 robj2(rmnb - n + 1) = robj2(rmnb - n)
 robj3(rmnb - n + 1) = robj3(rmnb - n)
 robj4(rmnb - n + 1) = robj4(rmnb - n)
 robj5(rmnb - n + 1) = robj5(rmnb - n)
 robj6(rmnb - n + 1) = robj6(rmnb - n)
 robj7(rmnb - n + 1) = robj7(rmnb - n)
 robj8(rmnb - n + 1) = robj8(rmnb - n)
ak1:
NEXT
room1$(1) = map3$
IF obje(1).obtp >= 1 AND obje(1).obtp <= 8 THEN robj1(1) = 1:   ELSE robj1(1) = 0
IF obje(2).obtp >= 1 AND obje(2).obtp <= 8 THEN robj2(1) = 1:   ELSE robj2(1) = 0
IF obje(3).obtp >= 1 AND obje(3).obtp <= 8 THEN robj3(1) = 1:   ELSE robj3(1) = 0
IF obje(4).obtp >= 1 AND obje(4).obtp <= 8 THEN robj4(1) = 1:   ELSE robj4(1) = 0
IF obje(5).obtp >= 1 AND obje(5).obtp <= 8 THEN robj5(1) = 1:   ELSE robj5(1) = 0
IF obje(6).obtp >= 1 AND obje(6).obtp <= 8 THEN robj6(1) = 1:   ELSE robj6(1) = 0
IF obje(7).obtp >= 1 AND obje(7).obtp <= 8 THEN robj7(1) = 1:   ELSE robj7(1) = 0
IF obje(8).obtp >= 1 AND obje(8).obtp <= 8 THEN robj8(1) = 1:   ELSE robj8(1) = 0
RETURN
go1nd:
END SUB

SUB hdis
WAIT &H3DA, 8: WAIT &H3DA, 8, 8
LINE (0, 0)-(319, 7), 0, BF
IF zhp > mzhp THEN zhp = mzhp
IF zhp < 1 THEN zhp = 0
LOCATE 1, 1: COLOR 12: PRINT "Life"; zhp; "/"; mzhp
IF zhp < 1 THEN LOCATE 1, 1: PRINT "DEAD": zdd = 1:
IF gold > 990 THEN gold = 990
LOCATE 1, 31: COLOR 14: PRINT "Gold:"; gold
LOCATE 1, 19: COLOR 9: PRINT "Ziel"
END SUB

SUB hit :
mxht = 4:
IF ht2 = 1 THEN hit2
ht2 = ht2 + 1
IF ht2 > mxht THEN ht2 = 0: ht1 = 0: ht3 = 0: mv = 2: htt = 1: GOTO hitnd
IF ht4 = 1 THEN GET (hx, hy)-(hx + 15, hy + 15), BG1S:
IF sword1 = 0 THEN GOTO hitnd
SELECT CASE d
CASE 1: Putimg x, y, uh(): Putimg xx2, yy2, sw1()
CASE 2: Putimg x, y, dh(): Putimg xx2, yy2, sw2()
CASE 3: Putimg x, y, rh(): Putimg xx2, yy2, sw3()
CASE 4: Putimg x, y, lh(): Putimg xx2, yy2, sw4()
END SELECT
ht3 = 1
IF ht4 = 1 THEN : playfx (3): ht4 = 0:
GOTO hitnd

hor: 'Resets object hit register(so can only be hit once per slash)
FOR obn = 1 TO 8
obje(obn).Oht1 = 0
NEXT
RETURN
hitnd:
IF ht1 = 0 THEN GOSUB hor: xx2 = 0: yy2 = 0: mov
END SUB

SUB hit2
SELECT CASE d
CASE 1: xx2 = x: yy2 = y - 16:
CASE 2: xx2 = x: yy2 = y + 15:
CASE 3: xx2 = x - 16: yy2 = y:
CASE 4: xx2 = x + 16: yy2 = y:
END SELECT
hx = xx2: hy = yy2 + 8
IF hx < 0 THEN hx = 0
IF hx > 319 - 15 THEN hx = 319 - 15
IF hy < 0 THEN hy = 0
IF hy > 199 - 15 THEN hy = 199 - 15
IF ht4 = 1 THEN GET (hx, hy)-(hx + 15, hy + 15), BG1S:
END SUB

SUB ldlist
OPEN "object.lst" FOR INPUT AS #1
FOR n = 1 TO mxobjn
INPUT #1, rm$(n), objnum(n), zgf1(n)
NEXT
CLOSE
END SUB

FUNCTION LoadFX (Filename$)
OPEN Filename$ FOR BINARY AS #1
IF LOF(1) = 0 THEN LoadFX = 0: CLOSE #1: EXIT FUNCTION
DIM id AS STRING * 4
GET #1, , id
IF MID$(id, 1, 2) <> "SL" THEN LoadFX = 1: CLOSE #1: EXIT FUNCTION
IF MID$(id, 3, 2) <> "10" THEN LoadFX = 2: CLOSE #1: EXIT FUNCTION
GET #1, , NumSound
REDIM snd(1 TO NumSound) AS STRING * 30
FOR i = 1 TO NumSound
  GET #1, , snd(i)
  temp$ = SPACE$(20)
  GET #1, , temp$
NEXT i
CLOSE #1
LoadFX = -1
END FUNCTION

SUB mov
IF zfbn > 0 THEN GOTO zifly
IF ht1 = 1 THEN hit: IF sword1 > 0 THEN GOTO movnd
IF mv > 4 THEN mv = 1:
IF mv2 <> mv THEN mvp = mvp + 1: IF mvp = 2 THEN mv = mv22: mvp = 0: ' playfx 8
IF flash2 = 1 THEN GOSUB fl1:
IF flash1 = 0 THEN GOSUB tr1: GOTO movnd
SELECT CASE d
  CASE 1: GOSUB up
  CASE 2: GOSUB dn
  CASE 3: GOSUB lf
  CASE 4: GOSUB rt
END SELECT
GOSUB tr1
GOTO movnd
tr1:
mv22 = mv:
RETURN
zifly:
IF flash2 = 1 THEN GOSUB fl1:
IF flash1 = 0 THEN GOSUB tr1: GOTO tt2
SELECT CASE zfb
CASE 1: Putimg x, y, d2()
CASE 2: Putimg x, y, u2()
CASE 3: Putimg x, y, l2()
CASE 4: Putimg x, y, r2()
END SELECT
tt2:
GOTO movnd
up:
SELECT CASE mv
  CASE 1: Putimg x, y, u1()
  CASE 2: Putimg x, y, u2()
  CASE 3: Putimg x, y, u3()
  CASE 4: Putimg x, y, u2()
END SELECT
RETURN
dn:
SELECT CASE mv
  CASE 1: Putimg x, y, d1()
  CASE 2: Putimg x, y, d2()
  CASE 3: Putimg x, y, d3()
  CASE 4: Putimg x, y, d2()
END SELECT
RETURN
lf:
SELECT CASE mv
  CASE 1: Putimg x, y, l1()
  CASE 2: Putimg x, y, l2()
  CASE 3: Putimg x, y, l3()
  CASE 4: Putimg x, y, l2()
END SELECT
RETURN
rt:
SELECT CASE mv
CASE 1: Putimg x, y, r1()
CASE 2: Putimg x, y, r2()
CASE 3: Putimg x, y, R3()
CASE 4: Putimg x, y, r2()
END SELECT
RETURN
fl1:
flsh = flsh - 1:
IF flsh < 1 THEN flash1 = 1: flash2 = 0: RETURN
IF flash1 = 1 THEN flash1 = 0: RETURN
IF flash1 = 0 THEN flash1 = 1: RETURN
RETURN
movnd:
END SUB

SUB oa
'### Object Handler
Obt: '## sets up objects
FOR obn = 1 TO 8
oamv = obje(obn).Mvob
oax = obje(obn).Xax
oay = obje(obn).yax
oad = obje(obn).Dob
ox2 = oax: oy2 = oay
obje(obn).Xaa = obje(obn).Xax: obje(obn).Yaa = obje(obn).yax

SELECT CASE obje(obn).obtp: '## selects objects
CASE 0: GOTO oa1
CASE 9: GOSUB htob1
CASE 0: GOTO oa1
CASE 99: obje(obn).obtp = 0:
CASE ELSE: GOSUB ob2
END SELECT
GOTO oa1
' ###### Object handler
ob2:
''Sword hit
 IF ht1 = 1 THEN GOSUB swht: IF obje(obn).obtp = 0 THEN RETURN:
''Colision
 IF x + 13 > oax AND x + 2 < oax + 15 AND y + 13 > oay AND y + 2 < oay + 15 THEN GOSUB col
''If object is movable
' IF objCFG1(obn).Omvl = 0 THEN GOTO oa1:
''Object flys back when hit
 IF obje(obn).ht2 > 0 THEN GOSUB mhto: GOTO oa1:
''if object is "slow" then delay it
 IF objCFG1(obn).OSpd = 1 THEN GOSUB spd
''delays animation
 obje(obn).Omv = obje(obn).Omv + 1
  IF obje(obn).Omv = 2 THEN obje(obn).Omv = 0: IF obje(obn).Mvob2 = 1 THEN obje(obn).Mvob2 = 2:  ELSE obje(obn).Mvob2 = 1
''setup object movement
 IF oamv = 0 THEN oamv = INT(RND * 15) + 6: oad = INT(RND * 4) + 1:
''select object movement type
SELECT CASE objCFG1(obn).Omvl
 CASE 0: GOTO oa1
 CASE 1: GOSUB mvobj
 CASE 2: GOSUB mvobj2
END SELECT
 owll
''if object hits a wall, change direction
  SELECT CASE oad
   CASE 1: IF oed = 1 THEN oad = 3: GOTO oa1
   CASE 2: IF oed = 1 THEN oad = 4: GOTO oa1
   CASE 3: IF oed = 1 THEN oad = 2: GOTO oa1
   CASE 4: IF oed = 1 THEN oad = 1: GOTO oa1
  END SELECT
RETURN
'#############
mvobj:
''move object
 SELECT CASE oad
  CASE 1: oamv = oamv - 1: oay = oay - ms:
  CASE 2: oamv = oamv - 1: oay = oay + ms:
  CASE 3: oamv = oamv - 1: oax = oax - ms:
  CASE 4: oamv = oamv - 1: oax = oax + ms:
 END SELECT
RETURN
mvobj2:
''move object diagnal
 SELECT CASE oad
  CASE 1: oamv = oamv - 1: oay = oay - ms: oax = oax - ms
  CASE 2: oamv = oamv - 1: oay = oay + ms: oax = oax - ms
  CASE 3: oamv = oamv - 1: oax = oax + ms: oay = oay + ms
  CASE 4: oamv = oamv - 1: oax = oax + ms: oay = oay - ms
 END SELECT
RETURN

spd: '' slow or fast, delay in movement
 IF obje(obn).Obna = 1 THEN obje(obn).Obna = 0: GOTO oa1:
 IF obje(obn).Obna = 0 THEN obje(obn).Obna = 1:
RETURN

col: '' colision routines
''if the object can do harm then do it, else do nothing
 IF objCFG1(obn).Omvl = 0 THEN x = xa: y = ya
 IF objCFG1(obn).Obhrm > 0 THEN zhit
''if it is money & life
SELECT CASE obje(obn).obtp
 CASE 10: GOSUB mny1
 CASE 11: GOSUB mny22
 CASE 12: GOSUB life1
 CASE 13: GOSUB getob
END SELECT
RETURN

''What happens when you get the below objects
getob:
 getobj
 IF room11 = 0 THEN obje(obn).obtp = 99
 RETURN
mny1:  'Money, 5 gold
  playfx 7
  gold = gold + 5
  playfx 6
  obje(obn).obtp = 99
  hdis
 RETURN
mny22: '1 Money, 1 gold
  playfx 6
  gold = gold + 1
  obje(obn).obtp = 99
  hdis
 RETURN
life1: 'life, add 1 hit point
  playfx 5
  zhp = zhp + 1
  obje(obn).obtp = 99
  hdis
 RETURN

swht: 'Sword fighting colision
  IF obje(obn).Oht1 = 1 THEN RETURN
  IF ht2 = 1 THEN hit2:
  IF (xx2 + 15 > oax - 1 AND xx2 < oax + 15) AND (yy2 + 15 > oay - 1 AND yy2 < oay + 16) THEN GOSUB sht2
  RETURN
sht2:
     IF objCFG1(obn).obtalk = 1 THEN sign1: obje(obn).Oht1 = 1:
     IF sword1 = 0 THEN ht1 = 0: ht2 = 0: RETURN
     IF obje(obn).ht3 = 1 THEN RETURN
     zstrk
    obje(obn).Oht1 = 1
   'which direction object should fly back
     IF obje(obn).Ohp > 0 AND d = 1 THEN obje(obn).ht2 = 1:
     IF obje(obn).Ohp > 0 AND d = 2 THEN obje(obn).ht2 = 2:
     IF obje(obn).Ohp > 0 AND d = 3 THEN obje(obn).ht2 = 3:
     IF obje(obn).Ohp > 0 AND d = 4 THEN obje(obn).ht2 = 4:
     IF obje(obn).Ohp < 1 THEN obje(obn).obtp = 9: htm = 0: obje(obn).Oht1 = 1: objCFG1(obn).Obhrm = 0
   RETURN
mhto: 'Object flys back when hit
 SELECT CASE obje(obn).ht2
  CASE 1: oay = oay - 10: obje(obn).ht4 = obje(obn).ht4 + 1
  CASE 2: oay = oay + 10: obje(obn).ht4 = obje(obn).ht4 + 1
  CASE 3: oax = oax - 10: obje(obn).ht4 = obje(obn).ht4 + 1
  CASE 4: oax = oax + 10: obje(obn).ht4 = obje(obn).ht4 + 1
 END SELECT
owll
 IF oed = 1 THEN obje(obn).ht2 = 0
 IF obje(obn).ht4 > 5 THEN obje(obn).ht2 = 0: obje(obn).ht4 = 0
RETURN
'#############
htob1: '## Flash when object is hit and killed
 oad = 5
  htm = htm + 1
   IF htm = 1 THEN obje(obn).Mvob2 = 1:  playfx 1
   IF htm = 2 THEN obje(obn).Mvob2 = 2
   IF htm = 3 THEN obje(obn).Mvob2 = 1
   IF htm > 3 THEN htm = 0: GOSUB rop:
 RETURN
'#############
rop: 'Ya get random object when you kill a guy
 ott = INT(RND * 6) + 1
  SELECT CASE ott
   CASE 4: GOSUB mncf
   CASE 5: GOSUB mncf1
   CASE 6: GOSUB lff
   CASE ELSE: obje(obn).obtp = 99
  END SELECT
RETURN
lff: 'get life
 obje(obn).Mvob = 0
 obje(obn).obtp = 12
 objCFG1(obn).Omvl = 0
 obje(obn).ht3 = 1
RETURN
mncf: 'get Money
'set up variables as money
 obje(obn).Mvob = 0
 obje(obn).obtp = 10
 objCFG1(obn).Omvl = 0
 obje(obn).ht3 = 1
RETURN
mncf1: 'get Money
'set up variables as money
 obje(obn).Mvob = 0
 obje(obn).obtp = 11
 objCFG1(obn).Omvl = 0
 obje(obn).ht3 = 1
RETURN
''Sets object stats
oa1:
obje(obn).Mvob = oamv
obje(obn).Xax = oax
obje(obn).yax = oay
obje(obn).Dob = oad
NEXT
END SUB

SUB Oar : 'Object drawer
Obt2:
FOR obn = 1 TO 8
SELECT CASE obje(obn).obtp
CASE 0: GOTO t2:
CASE 1: GOSUB a1o: 'Object 1
CASE 2: GOSUB b1o: 'Object 2
CASE 3: GOSUB c1o: 'Object 3
CASE 4: GOSUB d1o: 'Object 4
CASE 5: GOSUB e1o: 'Object 5
CASE 6: GOSUB f1o: 'Object 6
CASE 7: GOSUB g1o: 'Object 7
CASE 8: GOSUB h1o: 'Object 8
CASE 9: GOSUB fls: 'Flash
CASE 10: GOSUB mny: 'Money
CASE 11: GOSUB mn2: 'other money
CASE 12: GOSUB lf11: 'life
CASE 13: GOSUB objp: 'object
END SELECT
t2:
NEXT obn
GOTO oan
mny:
Putimg obje(obn).Xax, obje(obn).yax, mny1():
RETURN
mn2:
Putimg obje(obn).Xax, obje(obn).yax, mny2():
RETURN
lf11:
Putimg obje(obn).Xax, obje(obn).yax, lf1():
RETURN
objp:
SELECT CASE objnum(roomnum)
CASE 1: Putimg obje(obn).Xax, obje(obn).yax, obj1():
CASE 2: Putimg obje(obn).Xax, obje(obn).yax, obj2():
CASE 3: Putimg obje(obn).Xax, obje(obn).yax, obj3():
CASE 4: Putimg obje(obn).Xax, obje(obn).yax, obj4():
CASE 5: Putimg obje(obn).Xax, obje(obn).yax, obj5():
END SELECT
RETURN
fls: '###  Flash
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, ho1():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, ho2():
RETURN


a1o: '##### Object 1
SELECT CASE obje(obn).Dob
CASE 1: GOSUB a1ou
CASE 2: GOSUB a1od
CASE 3: GOSUB a1or
CASE 4: GOSUB a1ol
END SELECT
RETURN
a1od:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, a1():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, a2():
RETURN
a1ou:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, a3():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, a4():
RETURN
a1ol:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, a5():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, a6():
RETURN
a1or:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, a7():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, a8():
RETURN

b1o: '##### Object 2
SELECT CASE obje(obn).Dob
CASE 1: GOSUB b1ou
CASE 2: GOSUB b1od
CASE 3: GOSUB b1or
CASE 4: GOSUB b1ol
END SELECT
RETURN
b1od:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, b1():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, b22():
RETURN
b1ou:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, b3():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, b4():
RETURN
b1ol:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, b5():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, b6():
RETURN
b1or:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, b7():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, b8():
RETURN
c1o: '##### Object 3
SELECT CASE obje(obn).Dob
CASE 1: GOSUB c1ou
CASE 2: GOSUB c1od
CASE 3: GOSUB c1or
CASE 4: GOSUB c1ol
END SELECT
RETURN
c1od:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, c1():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, c2():
RETURN
c1ou:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, c3():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, c4():
RETURN
c1ol:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, c5():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, c6():
RETURN
c1or:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, c7():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, c8():
RETURN
d1o: '##### Object 4
SELECT CASE obje(obn).Dob
CASE 1: GOSUB d1ou
CASE 2: GOSUB d1od
CASE 3: GOSUB d1or
CASE 4: GOSUB d1ol
END SELECT
RETURN
d1od:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, d11():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, d21():
RETURN
d1ou:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, d31():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, d4():
RETURN
d1ol:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, d5():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, d6():
RETURN
d1or:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, d7():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, d8():
RETURN
e1o: '##### Object 5
SELECT CASE obje(obn).Dob
CASE 1: GOSUB e1ou
CASE 2: GOSUB e1od
CASE 3: GOSUB e1or
CASE 4: GOSUB e1ol
END SELECT
RETURN
e1od:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, e1():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, e2():
RETURN
e1ou:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, e3():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, e4():
RETURN
e1ol:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, e5():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, e6():
RETURN
e1or:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, e7():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, e8():
RETURN
f1o: '##### Object 6
SELECT CASE obje(obn).Dob
CASE 1: GOSUB f1ou
CASE 2: GOSUB f1od
CASE 3: GOSUB f1or
CASE 4: GOSUB f1ol
END SELECT
RETURN
f1od:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, f1():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, f2():
RETURN
f1ou:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, f3():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, f4():
RETURN
f1ol:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, f5():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, f6():
RETURN
f1or:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, f7():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, f8():
RETURN
g1o: '##### Object 7
SELECT CASE obje(obn).Dob
CASE 1: GOSUB g1ou
CASE 2: GOSUB g1od
CASE 3: GOSUB g1or
CASE 4: GOSUB g1ol
END SELECT
RETURN
g1od:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, g1():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, g2():
RETURN
g1ou:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, g3():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, g4():
RETURN
g1ol:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, g5():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, g6():
RETURN
g1or:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, g7():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, g8():
RETURN
h1o: '##### Object 8
SELECT CASE obje(obn).Dob
CASE 1: GOSUB h1ou
CASE 2: GOSUB h1od
CASE 3: GOSUB h1or
CASE 4: GOSUB h1ol
END SELECT
RETURN
h1od:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, h1():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, h2():
RETURN
h1ou:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, h3():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, h4():
RETURN
h1ol:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, h5():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, h6():
RETURN
h1or:
IF obje(obn).Mvob2 = 1 THEN Putimg obje(obn).Xax, obje(obn).yax, h7():
IF obje(obn).Mvob2 = 2 THEN Putimg obje(obn).Xax, obje(obn).yax, h8():
RETURN


oan:
END SUB

SUB ObjR
'Object reader(Start of map plots objects)
'Reads map for objects, gives them variables from set file, places them on
'the map to roam free
obn = 0
roomnum = 0
oxx = 0: oyy = 1
room2 = 0: room3 = 0
FOR n = 1 TO rmnb: 'checks to see if screen is in cache
IF room1$(n) = map3$ THEN room2 = 1: r = n
NEXT'checks to see if screen is in cache
FOR b3 = 1 TO wlm2
ln2$ = wl2$(b3)
oxx = oxx + 1: IF oxx > mmmx THEN oyy = oyy + 1: oxx = 1
onx = oxx * 16 - 16: ony = oyy * 16 - 16
'So badguys can't start beyond the "borders"(adjust)
IF ony < 24 THEN ony = 24
IF ony > 165 THEN ony = 165
IF onx < 8 THEN onx = 8
IF onx > 300 THEN onx = 300
SELECT CASE ln2$
'-----------------------
CASE "a":  GOSUB rn:
obje(obn).obtp = 1:
GOSUB obcf: IF room3 = 1 THEN GOTO rn1
obje(obn).Xax = onx: obje(obn).yax = ony: obje(obn).Dob = 2: obje(obn).Mvob = 0: obje(obn).Mvob2 = 1:
'Object moves or stationary
objCFG1(obn).Omvl = o11
'Obay wall
objCFG1(obn).Obwall = o21
'Object hitpoints
objCFG1(obn).Obmhp = o31
'Have object start hit points = max hp
obje(obn).Ohp = objCFG1(obn).Obmhp
'Hitable with sword
obje(obn).ht3 = o41
'speed
objCFG1(obn).OSpd = o51
'amount of harm object can do
objCFG1(obn).Obhrm = o61
'if object talks or not
objCFG1(obn).obtalk = o71
rn1:
'-----------------------
CASE "b":  GOSUB rn:
obje(obn).obtp = 2:
GOSUB obcf: IF room3 = 1 THEN GOTO rn1
obje(obn).Xax = onx: obje(obn).yax = ony: obje(obn).Dob = 2: obje(obn).Mvob = 0: obje(obn).Mvob2 = 1:
objCFG1(obn).Omvl = o12
objCFG1(obn).Obwall = o22
objCFG1(obn).Obmhp = o32
obje(obn).Ohp = objCFG1(obn).Obmhp
obje(obn).ht3 = o42
objCFG1(obn).OSpd = o52
objCFG1(obn).Obhrm = o62
objCFG1(obn).obtalk = o72
rn12:
'-----------------------
CASE "c": GOSUB rn:
IF room3 = 1 THEN GOTO rn3
GOSUB obcf: IF room3 = 1 THEN GOTO rn1
obje(obn).obtp = 3:
obje(obn).Xax = onx: obje(obn).yax = ony: obje(obn).Dob = 2: obje(obn).Mvob = 0: obje(obn).Mvob2 = 1:
objCFG1(obn).Omvl = o13
objCFG1(obn).Obwall = o23
objCFG1(obn).Obmhp = o33
obje(obn).Ohp = objCFG1(obn).Obmhp
obje(obn).ht3 = o43
objCFG1(obn).OSpd = o53
objCFG1(obn).Obhrm = o63
objCFG1(obn).obtalk = o73
rn3:
'-----------------------
CASE "d": GOSUB rn:
obje(obn).obtp = 4:
GOSUB obcf: IF room3 = 1 THEN GOTO rn1
obje(obn).Xax = onx: obje(obn).yax = ony: obje(obn).Dob = 2: obje(obn).Mvob = 0: obje(obn).Mvob2 = 1:
objCFG1(obn).Omvl = o14
objCFG1(obn).Obwall = o24
objCFG1(obn).Obmhp = o34
obje(obn).Ohp = objCFG1(obn).Obmhp
obje(obn).ht3 = o44
objCFG1(obn).OSpd = o54
objCFG1(obn).Obhrm = o64
objCFG1(obn).obtalk = o74
rn4:
'-----------------------
CASE "e": GOSUB rn:
obje(obn).obtp = 5:
GOSUB obcf: IF room3 = 1 THEN GOTO rn1
obje(obn).Xax = onx: obje(obn).yax = ony: obje(obn).Dob = 2: obje(obn).Mvob = 0: obje(obn).Mvob2 = 1:
objCFG1(obn).Omvl = o15
objCFG1(obn).Obwall = o25
objCFG1(obn).Obmhp = o35
obje(obn).Ohp = objCFG1(obn).Obmhp
obje(obn).ht3 = o45
objCFG1(obn).OSpd = o55
objCFG1(obn).Obhrm = o65
objCFG1(obn).obtalk = o75
rn5:
'-----------------------
CASE "f": GOSUB rn:
obje(obn).obtp = 6:
GOSUB obcf: IF room3 = 1 THEN GOTO rn1
obje(obn).Xax = onx: obje(obn).yax = ony: obje(obn).Dob = 2: obje(obn).Mvob = 0: obje(obn).Mvob2 = 1:
objCFG1(obn).Omvl = o16
objCFG1(obn).Obwall = o26
objCFG1(obn).Obmhp = o36
obje(obn).Ohp = objCFG1(obn).Obmhp
obje(obn).ht3 = o46
objCFG1(obn).OSpd = o56
objCFG1(obn).Obhrm = o66
objCFG1(obn).obtalk = o76
rn6:
'-----------------------
CASE "g": GOSUB rn:
obje(obn).obtp = 7:
GOSUB obcf: IF room3 = 1 THEN GOTO rn1
obje(obn).Xax = onx: obje(obn).yax = ony: obje(obn).Dob = 2: obje(obn).Mvob = 0: obje(obn).Mvob2 = 1:
objCFG1(obn).Omvl = o17
objCFG1(obn).Obwall = o27
objCFG1(obn).Obmhp = o37
obje(obn).Ohp = objCFG1(obn).Obmhp
obje(obn).ht3 = o47
objCFG1(obn).OSpd = o57
objCFG1(obn).Obhrm = o67
objCFG1(obn).obtalk = o77
rn7:
'-----------------------
CASE "h": GOSUB rn:
obje(obn).obtp = 8:
GOSUB obcf: IF room3 = 1 THEN GOTO rn1
obje(obn).Xax = onx: obje(obn).yax = ony: obje(obn).Dob = 2: obje(obn).Mvob = 0: obje(obn).Mvob2 = 1:
objCFG1(obn).Omvl = o18
objCFG1(obn).Obwall = o28
objCFG1(obn).Obmhp = o38
obje(obn).Ohp = objCFG1(obn).Obmhp
obje(obn).ht3 = o48
objCFG1(obn).OSpd = o58
objCFG1(obn).Obhrm = o68
objCFG1(obn).obtalk = o78
rn8:
'-----------------------
CASE "o": 'gettable objects
'checks object list for object
FOR n = 1 TO mxobjn
IF map3$ = rm$(n) THEN roomnum = n
NEXT
IF roomnum = 0 THEN GOTO noob
GOSUB rn
obje(obn).Xax = onx: obje(obn).yax = ony: obje(obn).Dob = 2: obje(obn).Mvob = 0: obje(obn).Mvob2 = 1:
obje(obn).obtp = 13:
objCFG1(obn).Omvl = 0
obje(obn).ht3 = 1
objCFG1(obn).Obhrm = 0
objCFG1(obn).obtalk = 0
noob:
'-----------------------
END SELECT
tr2:
NEXT
GOTO rn2
rn:
obn = obn + 1
IF obn > 8 THEN GOTO rn2
SELECT CASE obn
CASE 1: GET (onx, ony + 8)-(onx + 15, ony + 23), BGA: RETURN
CASE 2: GET (onx, ony + 8)-(onx + 15, ony + 23), BGB: RETURN
CASE 3: GET (onx, ony + 8)-(onx + 15, ony + 23), BGC: RETURN
CASE 4: GET (onx, ony + 8)-(onx + 15, ony + 23), BGD: RETURN
CASE 5: GET (onx, ony + 8)-(onx + 15, ony + 23), BGE: RETURN
CASE 6: GET (onx, ony + 8)-(onx + 15, ony + 23), BGF: RETURN
CASE 7: GET (onx, ony + 8)-(onx + 15, ony + 23), BGG: RETURN
CASE 8: GET (onx, ony + 8)-(onx + 15, ony + 23), BGH: RETURN
END SELECT
RETURN
obcf: 'Checks to see what bad guys are dead and which are alive
IF room2 = 0 THEN RETURN
room3 = 0:
IF obn = 1 AND robj1(r) = 0 THEN obje(obn).obtp = 0: room3 = 1:
IF obn = 2 AND robj2(r) = 0 THEN obje(obn).obtp = 0: room3 = 1:
IF obn = 3 AND robj3(r) = 0 THEN obje(obn).obtp = 0: room3 = 1:
IF obn = 4 AND robj4(r) = 0 THEN obje(obn).obtp = 0: room3 = 1:
IF obn = 5 AND robj5(r) = 0 THEN obje(obn).obtp = 0: room3 = 1:
IF obn = 6 AND robj6(r) = 0 THEN obje(obn).obtp = 0: room3 = 1:
IF obn = 7 AND robj7(r) = 0 THEN obje(obn).obtp = 0: room3 = 1:
IF obn = 8 AND robj8(r) = 0 THEN obje(obn).obtp = 0: room3 = 1:
RETURN
rn2:
END SUB

SUB owll
'### Object colision
oed = 0: 'Object error direction = 0(Meaning no wall hit)
'### Screen limits(So objects don't wonder off screen)
IF oay < 8 THEN oay = oy2: oed = 1: GOTO wd
IF oay > 170 THEN oay = oy2: oed = 1: GOTO wd
IF oax < 8 THEN oax = ox2: oed = 1: GOTO wd
IF oax > 300 THEN oax = ox2: oed = 1: GOTO wd
'If flag is set so object doesn't obay wall(but still has to obay borders)
IF objCFG1(obn).Obwall = 0 THEN GOTO wd
'### Colision tiles
'selects direction, so it will look infront of the object
SELECT CASE objCFG1(obn).Omvl
 CASE 1: 'regular movement
   SELECT CASE oad
    CASE 1: oxx = (oax - 6) / 16 + 1: oyy = (oay - 4) / 16 + 1: oxx2 = (oax + 6) / 16 + 1: oyy2 = oyy
    CASE 2: oxx = (oax - 6) / 16 + 1: oyy = (oay + 10) / 16 + 1: oxx2 = (oax + 6) / 16 + 1: oyy2 = oyy
    CASE 3: oxx = (oax - 6) / 16 + 1: oyy = (oay + 4) / 16 + 1: oxx2 = oxx: oyy2 = (oay + 7) / 16 + 1
    CASE 4: oxx = (oax + 6) / 16 + 1: oyy = (oay + 4) / 16 + 1: oxx2 = oxx: oyy2 = (oay + 7) / 16 + 1
   END SELECT
 CASE 2: 'diagnal movement
   SELECT CASE oad
    'upper left
    CASE 1: oxx = (oax - 6) / 16 + 1: oyy = (oay - 4) / 16 + 1: oxx2 = oxx: oyy2 = (oay + 7) / 16 + 1
    'lower left
    CASE 2: oxx = (oax - 6) / 16 + 1: oyy = (oay + 10) / 16 + 1: oxx2 = oxx: oyy2 = (oay + 7) / 16 + 1
    'lower right
    CASE 3: oxx = (oax - 6) / 16 + 1: oyy = (oay + 10) / 16 + 1: oxx2 = oxx: oyy2 = (oay + 7) / 16 + 1
    'upper right
    CASE 4: oxx = (oax - 6) / 16 + 1: oyy = (oay - 4) / 16 + 1: oxx2 = (oax + 6) / 16 + 1: oyy2 = oyy
   END SELECT
END SELECT
FOR tt11 = 1 TO 2
  SELECT CASE tt11
    CASE 1: on1 = (oyy * mmmx - mmmx) + oxx: ln2$ = wl2$(on1):
    CASE 2: on2 = (oyy2 * mmmx - mmmx) + oxx2: ln2$ = wl2$(on2):
  END SELECT
'## Wall tiles
 IF ln2$ = "2" THEN tt11 = 3: oax = ox2: oay = oy2: oed = 1: 'Wall hit so it tells it to change direction
 IF ln2$ = "3" THEN tt11 = 3: oax = ox2: oay = oy2: oed = 1: 'Wall hit so it tells it to change direction
NEXT
wd:
END SUB

SUB paus
'System sync(so it runs the same speed on all CPUs)
DEF SEG = 0: POKE (1132), 0 'reset timer again
t: IF PEEK(1132) < 1 THEN GOTO t 'If not enough time was passed goto T
DEF SEG = &HA000
END SUB

SUB pause1
'Guess =)
LOCATE 1, 1: COLOR 12: PRINT "                P A U S E               "
DO: LOOP UNTIL INKEY$ <> ""
hdis
END SUB

SUB pic
'Loads a graphics w/ palette(BSAVE)
DEF SEG = &HA000: '#### Loads gfx
  BLOAD pict$
  OUT &H3C8, 0
  FOR a = 0 TO 767
  OUT &H3C9, PEEK(a + 64000)'64775
 NEXT
END SUB

SUB playfx (Num)
IF sd = 0 GOTO fxnd
'
' Plays specified FX num.
'
FOR i = 1 TO 15
  OUT &H388, ASC(MID$(snd(Num), (i * 2) - 1, 1))
  FOR ii = 1 TO 6: temp = INP(&H388): NEXT ii
  OUT &H389, ASC(MID$(snd(Num), (i * 2)))
  FOR ii = 1 TO 35: temp = INP(&H388): NEXT ii
NEXT i
fxnd:
END SUB

SUB Put2 (x111%, y111%, s11%())
'Graphics routines
PUT (x111%, y111%), s11%, PSET: GOTO ptnd2
ptnd2:
END SUB

SUB Putimg (x111%, y111%, s11%())
'Sprite routines
xz = x111%: yz = y111% + 8
xz2 = xz: yz2 = yz
SELECT CASE sprtg
CASE 1:
 IF x111% < 0 OR x111% > 304 OR y111% < 0 OR y111% > 177 THEN GOTO ptnd:
 PUT (x111%, y111% + 8), s11%, PSET:
CASE 2:
FOR b5 = 1 TO 256
   sc = 0
   IF xz > xz2 + xz3 THEN xz = xz2: yz = yz + 1
   IF s11%(b5) = 0 THEN sc = 1
   IF yz > 199 OR yz < 8 OR xz > 319 OR xz < 0 THEN sc = 1
   IF sc = 0 THEN : PSET (xz, yz), s11%(b5)
   xz = xz + 1:
NEXT
CASE 3:
FOR b5 = 1 TO 256
   sc = 0
   IF xz > xz2 + xz3 THEN xz = xz2: yz = yz + 1
   IF s11%(b5) = 0 THEN sc = 1
   IF yz > 199 OR yz < 8 OR xz > 319 OR xz < 0 THEN sc = 1
   IF sc = 0 THEN : px = yz * 320 + xz: POKE (px), s11%(b5)
   xz = xz + 1:
NEXT
END SELECT
ptnd:
END SUB

SUB putimt (x111%, y111%, s11%())
'tile graphics routines
xz = x111%: yz = y111% + 8
xz2 = xz: yz2 = yz
SELECT CASE sprtt
CASE 1: PUT (x111%, y111% + 8), s11%, PSET:
CASE 2:
FOR b5 = 1 TO 256
 sc = 0
  IF xz > xz2 + xz3 THEN xz = xz2: yz = yz + 1
   IF s11%(b5) = 0 THEN sc = 1
   IF yz > 199 OR yz < 8 OR xz > 319 OR xz < 0 THEN sc = 1
 IF sc = 0 THEN : PSET (xz, yz), s11%(b5)
 xz = xz + 1:
NEXT
CASE 3:
FOR b5 = 1 TO 256
 sc = 0
  IF xz > xz2 + xz3 THEN xz = xz2: yz = yz + 1
   IF s11%(b5) = 0 THEN sc = 1
   IF yz > 199 OR yz < 8 OR xz > 319 OR xz < 0 THEN sc = 1
 IF sc = 0 THEN : px = yz * 320 + xz: POKE (px), s11%(b5)
 xz = xz + 1:
NEXT
END SELECT
'GOTO ptn2
'pt2:
'RETURN
ptn2:
END SUB

SUB qberr
'error message for Qbasic users
COLOR 12
LINE (0, 0)-(319, 7), 0, BF
BEEP
LOCATE 1, 1: PRINT "Can't use this function is Qbasic!!!"
DO: LOOP UNTIL INKEY$ <> ""
hdis
END SUB

SUB set1
'loads set file
OPEN set$ FOR INPUT AS #1
INPUT #1, pic1$

INPUT #1, o11
INPUT #1, o21
INPUT #1, o31
INPUT #1, o41
INPUT #1, o51
INPUT #1, o61

INPUT #1, o12
INPUT #1, o22
INPUT #1, o32
INPUT #1, o42
INPUT #1, o52
INPUT #1, o62

INPUT #1, o13
INPUT #1, o23
INPUT #1, o33
INPUT #1, o43
INPUT #1, o53
INPUT #1, o63

INPUT #1, o14
INPUT #1, o24
INPUT #1, o34
INPUT #1, o44
INPUT #1, o54
INPUT #1, o64

INPUT #1, o15
INPUT #1, o25
INPUT #1, o35
INPUT #1, o45
INPUT #1, o55
INPUT #1, o65

INPUT #1, o16
INPUT #1, o26
INPUT #1, o36
INPUT #1, o46
INPUT #1, o56
INPUT #1, o66

INPUT #1, o17
INPUT #1, o27
INPUT #1, o37
INPUT #1, o47
INPUT #1, o57
INPUT #1, o67

INPUT #1, o18
INPUT #1, o28
INPUT #1, o38
INPUT #1, o48
INPUT #1, o58
INPUT #1, o68

INPUT #1, o71
INPUT #1, o72
INPUT #1, o73
INPUT #1, o74
INPUT #1, o75
INPUT #1, o76
INPUT #1, o77
INPUT #1, o78
CLOSE

END SUB

SUB sign1
FOR a = 1 TO 10
IF INKEY$ <> " " THEN a = a
NEXT
'displays sign or when talking to a person what they say
SELECT CASE obn
CASE 1: txt$ = otxt1$
CASE 2: txt$ = otxt2$
CASE 3: txt$ = otxt3$
CASE 4: txt$ = otxt4$
CASE 5: txt$ = otxt5$
CASE 6: txt$ = otxt6$
CASE 7: txt$ = otxt7$
CASE 8: txt$ = otxt8$
END SELECT
'Note: if you are using Qbasic and it crashes run setup and pick qbasic mode
IF qbasic1 = 1 THEN qberr:  GOTO sind2:
'LOCATE 1, 1: PRINT "Free memory:"; FRE(-1):
DIM txtbg1(8500)
GET (64, 56)-(256, 143), txtbg1
tx2 = 0
tx1 = 0
txt1 = 0
prt:
'Text box
  COLOR 15
  '22 characters wide   1234567890123456789012
  LOCATE 8, 9:  PRINT "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿"
  LOCATE 9, 9:  PRINT "³                      ³"
  LOCATE 10, 9: PRINT "³                      ³"
  LOCATE 11, 9: PRINT "³                      ³"
  LOCATE 12, 9: PRINT "³                      ³"
  LOCATE 13, 9: PRINT "³                      ³"
  LOCATE 14, 9: PRINT "³                      ³"
  LOCATE 15, 9: PRINT "³                      ³"
  LOCATE 16, 9: PRINT "³                      ³"
  LOCATE 17, 9: PRINT "³Hit any key.......... ³"
  LOCATE 18, 9: PRINT "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ"
'first character in the sign string is void
IF tx2 > 0 THEN LOCATE 9, 10: PRINT MID$(txt$, 1 + tx1, 22)
IF tx2 = 0 THEN LOCATE 9, 11: PRINT MID$(txt$, 2, 21): txt1 = 1:
LOCATE 10, 10: PRINT MID$(txt$, 23 + tx1, 22)
LOCATE 11, 10: PRINT MID$(txt$, 45 + tx1, 22)
LOCATE 12, 10: PRINT MID$(txt$, 67 + tx1, 22)
LOCATE 13, 10: PRINT MID$(txt$, 89 + tx1, 22)
LOCATE 14, 10: PRINT MID$(txt$, 111 + tx1, 22)
LOCATE 15, 10: PRINT MID$(txt$, 133 + tx1, 22)
LOCATE 16, 10: PRINT MID$(txt$, 155 + tx1, 22)
tx2 = tx2 + 1
IF tx2 = 1 AND LEN(txt$) > 175 THEN GOSUB sinmr
IF tx2 = 2 AND LEN(txt$) > 320 THEN GOSUB sinmr
IF tx2 = 3 AND LEN(txt$) > 465 THEN GOSUB sinmr
IF tx2 = 4 AND LEN(txt$) > 610 THEN GOSUB sinmr
IF tx2 = 5 AND LEN(txt$) > 755 THEN GOSUB sinmr
DO: LOOP UNTIL INKEY$ <> ""
IF tx2 = 1 AND LEN(txt$) > 175 THEN tx1 = 176: GOTO prt
IF tx2 = 2 AND LEN(txt$) > 320 THEN tx1 = 322: GOTO prt
IF tx2 = 3 AND LEN(txt$) > 465 THEN tx1 = 468: GOTO prt
IF tx2 = 4 AND LEN(txt$) > 610 THEN tx1 = 614: GOTO prt
IF tx2 = 5 AND LEN(txt$) > 755 THEN tx1 = 760: GOTO prt
GOTO sind
sinmr:
COLOR 9: LOCATE 17, 10: PRINT "       More .......  "
RETURN
sind:
PUT (64, 56), txtbg1, PSET
REDIM txtbg1(256)
sind2:
END SUB

SUB tile123
pict$ = pic1$: pic
'Gets tile and object graphics
'row 1
RESULT = GETT(1, 1, 16, 16, T1())
RESULT = GETT(18, 1, 33, 16, t2())
RESULT = GETT(35, 1, 50, 16, T3a())
RESULT = GETT(52, 1, 67, 16, t4())
RESULT = GETT(69, 1, 84, 16, t5())
RESULT = GETT(86, 1, 101, 16, t6())
RESULT = GETT(103, 1, 118, 16, t7())
RESULT = GETT(120, 1, 135, 16, t8())
RESULT = GETT(137, 1, 152, 16, t9())
RESULT = GETT(154, 1, 169, 16, t10())
RESULT = GETT(171, 1, 186, 16, t11())
RESULT = GETT(188, 1, 203, 16, t12())
RESULT = GETT(205, 1, 220, 16, t13())
RESULT = GETT(222, 1, 237, 16, t14())
RESULT = GETT(239, 1, 254, 16, t15())
RESULT = GETT(256, 1, 271, 16, t16())
RESULT = GETS(273, 1, 288, 16, obj1())
'row 2
RESULT = GETT(1, 18, 16, 33, t17())
RESULT = GETT(18, 18, 33, 33, t18())
RESULT = GETT(35, 18, 50, 33, t19())
RESULT = GETT(52, 18, 67, 33, t20())
RESULT = GETT(69, 18, 84, 33, t21())
RESULT = GETT(86, 18, 101, 33, t22())
RESULT = GETT(103, 18, 118, 33, t23())
RESULT = GETT(120, 18, 135, 33, t24())
RESULT = GETT(137, 18, 152, 33, t25())
RESULT = GETT(154, 18, 169, 33, t26())
RESULT = GETT(171, 18, 186, 33, t27())
RESULT = GETT(188, 18, 203, 33, t28())
RESULT = GETT(205, 18, 220, 33, t29())
RESULT = GETT(222, 18, 237, 33, t30())
RESULT = GETT(239, 18, 254, 33, t31())
RESULT = GETT(256, 18, 271, 33, t32())
RESULT = GETS(273, 18, 288, 33, obj2())
'row 3
RESULT = GETT(1, 35, 16, 50, t33())
RESULT = GETT(18, 35, 33, 50, t34())
RESULT = GETT(35, 35, 50, 50, t35())
RESULT = GETT(52, 35, 67, 50, t36())
RESULT = GETT(69, 35, 84, 50, t37())
RESULT = GETT(86, 35, 101, 50, t38())
RESULT = GETT(103, 35, 118, 50, t39())
RESULT = GETT(120, 35, 135, 50, t40())
RESULT = GETT(137, 35, 152, 50, t41())
RESULT = GETT(154, 35, 169, 50, t42())
RESULT = GETT(171, 35, 186, 50, t43())
RESULT = GETT(188, 35, 203, 50, t44())
RESULT = GETT(205, 35, 220, 50, t45())
RESULT = GETT(222, 35, 237, 50, t46())
RESULT = GETT(239, 35, 254, 50, t47())
RESULT = GETT(256, 35, 271, 50, t48())
RESULT = GETS(273, 35, 288, 50, obj3())
'row 4
RESULT = GETT(1, 52, 16, 67, t49())
RESULT = GETT(18, 52, 33, 67, t50())
RESULT = GETS(273, 52, 288, 67, obj4())
'object 1
RESULT = GETS(1, 69, 16, 83, a1())
RESULT = GETS(18, 69, 33, 83, a2())
RESULT = GETS(35, 69, 50, 83, a3())
RESULT = GETS(52, 69, 67, 83, a4())
RESULT = GETS(69, 69, 84, 83, a5())
RESULT = GETS(86, 69, 101, 83, a6())
RESULT = GETS(103, 69, 118, 83, a7())
RESULT = GETS(120, 69, 135, 83, a8())
RESULT = GETS(273, 69, 288, 83, obj5())
'object 2
RESULT = GETS(137, 69, 152, 83, b1())
RESULT = GETS(154, 69, 169, 83, b22())
RESULT = GETS(171, 69, 186, 83, b3())
RESULT = GETS(188, 69, 203, 83, b4())
RESULT = GETS(205, 69, 220, 83, b5())
RESULT = GETS(222, 69, 237, 83, b6())
RESULT = GETS(239, 69, 254, 83, b7())
RESULT = GETS(256, 69, 271, 83, b8())
'object 3
RESULT = GETS(1, 86, 16, 100, c1())
RESULT = GETS(18, 86, 33, 100, c2())
RESULT = GETS(35, 86, 50, 100, c3())
RESULT = GETS(52, 86, 67, 100, c4())
RESULT = GETS(69, 86, 84, 100, c5())
RESULT = GETS(86, 86, 101, 100, c6())
RESULT = GETS(103, 86, 118, 100, c7())
RESULT = GETS(120, 86, 135, 100, c8())
'object 4
RESULT = GETS(137, 86, 152, 100, d11())
RESULT = GETS(154, 86, 169, 100, d21())
RESULT = GETS(171, 86, 186, 100, d31())
RESULT = GETS(188, 86, 203, 100, d4())
RESULT = GETS(205, 86, 220, 100, d5())
RESULT = GETS(222, 86, 237, 100, d6())
RESULT = GETS(239, 86, 254, 100, d7())
RESULT = GETS(256, 86, 271, 100, d8())
'object 5
RESULT = GETS(1, 103, 16, 117, e1())
RESULT = GETS(18, 103, 33, 117, e2())
RESULT = GETS(35, 103, 50, 117, e3())
RESULT = GETS(52, 103, 67, 117, e4())
RESULT = GETS(69, 103, 84, 117, e5())
RESULT = GETS(86, 103, 101, 117, e6())
RESULT = GETS(103, 103, 118, 117, e7())
RESULT = GETS(120, 103, 135, 117, e8())
'object 6
RESULT = GETS(137, 103, 152, 117, f1())
RESULT = GETS(154, 103, 169, 117, f2())
RESULT = GETS(171, 103, 186, 117, f3())
RESULT = GETS(188, 103, 203, 117, f4())
RESULT = GETS(205, 103, 220, 117, f5())
RESULT = GETS(222, 103, 237, 117, f6())
RESULT = GETS(239, 103, 254, 117, f7())
RESULT = GETS(256, 103, 271, 117, f8())
'object 7
RESULT = GETS(1, 120, 16, 134, g1())
RESULT = GETS(18, 120, 33, 134, g2())
RESULT = GETS(35, 120, 50, 134, g3())
RESULT = GETS(52, 120, 67, 134, g4())
RESULT = GETS(69, 120, 84, 134, g5())
RESULT = GETS(86, 120, 101, 134, g6())
RESULT = GETS(103, 120, 118, 134, g7())
RESULT = GETS(120, 120, 135, 134, g8())
'object 8
RESULT = GETS(137, 120, 152, 134, h1())
RESULT = GETS(154, 120, 169, 134, h2())
RESULT = GETS(171, 120, 186, 134, h3())
RESULT = GETS(188, 120, 203, 134, h4())
RESULT = GETS(205, 120, 220, 134, h5())
RESULT = GETS(222, 120, 237, 134, h6())
RESULT = GETS(239, 120, 254, 134, h7())
RESULT = GETS(256, 120, 271, 134, h8())

END SUB

SUB upt
'#### Screen updates
'## Object Handler
oa
IF zfbn > 0 THEN zflyba
'Background Update
WAIT &H3DA, 8
WAIT &H3DA, 8, 8
IF ht1 = 1 THEN PUT (hx, hy), BG1S, PSET:
PUT (xa, ya + 8), bg1, PSET:
FOR obn = 1 TO 8
IF obje(obn).obtp = 0 THEN GOTO tr3
SELECT CASE obn
CASE 1: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGA, PSET
CASE 2: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGB, PSET
CASE 3: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGC, PSET
CASE 4: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGD, PSET
CASE 5: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGE, PSET
CASE 6: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGF, PSET
CASE 7: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGG, PSET
CASE 8: PUT (obje(obn).Xaa, obje(obn).Yaa + 8), BGH, PSET
END SELECT
tr3:

NEXT
GET (x, y + 8)-(x + 15, y + 23), bg1
FOR obn = 1 TO 8
IF obje(obn).obtp = 0 THEN GOTO tr4
Xn2 = obje(obn).Xax
Yn2 = obje(obn).yax
SELECT CASE obn
CASE 1: GET (Xn2, Yn2 + 8)-(Xn2 + 15, Yn2 + 23), BGA
CASE 2: GET (Xn2, Yn2 + 8)-(Xn2 + 15, Yn2 + 23), BGB
CASE 3: GET (Xn2, Yn2 + 8)-(Xn2 + 15, Yn2 + 23), BGC
CASE 4: GET (Xn2, Yn2 + 8)-(Xn2 + 15, Yn2 + 23), BGD
CASE 5: GET (Xn2, Yn2 + 8)-(Xn2 + 15, Yn2 + 23), BGE
CASE 6: GET (Xn2, Yn2 + 8)-(Xn2 + 15, Yn2 + 23), BGF
CASE 7: GET (Xn2, Yn2 + 8)-(Xn2 + 15, Yn2 + 23), BGG
CASE 8: GET (Xn2, Yn2 + 8)-(Xn2 + 15, Yn2 + 23), BGH
END SELECT
tr4:
NEXT
ut1:
'## player update
mov
'## Object gfx update
Oar
xa = x: ya = y: mvb = mv
END SUB

SUB warp
IF r$ = "NONE" THEN T3 = 1: GOTO warpnd
dr = 5
go1
warpnd:
END SUB

SUB wll
zfb2 = 0
'Colision- Checks two tiles infront of ziel(one on left and one on right side
' of him)
'### colision
  'Checks to see if it hits the borders of the screen
  IF zfbn > 0 THEN GOTO htwll
  IF y < 0 THEN dr = 1: go1: GOTO wllnd
  IF y > 192 - 17 THEN dr = 2: go1: GOTO wllnd
  IF x < 1 THEN dr = 3:  go1: GOTO wllnd
  IF x > 320 - 16 THEN dr = 4:  go1: GOTO wllnd
  GOTO wll:
htwll:
  IF y < 0 THEN y = 0: zfb2 = 1: GOTO wllnd
  IF y > 192 - 17 THEN y = 192 - 17: zfb2 = 1: GOTO wllnd
  IF x < 1 THEN x = 1: go1: zfb2 = 1: GOTO wllnd
  IF x > 320 - 16 THEN x = 320 - 16: zfb2 = 1: go1: GOTO wllnd
wll: '############# What to do with what tiles
ya5 = y: xa5 = x
SELECT CASE d
  CASE 1: x111 = (x - 6) / 16 + 1: y111 = (y + 4) / 16 + 1: y222 = y111: x222 = (x + 6) / 16 + 1
  CASE 2: x111 = (x - 6) / 16 + 1: y111 = (ya + 10) / 16 + 1: y222 = y111: x222 = (x + 6) / 16 + 1
  CASE 3: x111 = (x - 6) / 16 + 1: y111 = (y + 4) / 16 + 1:  y222 = (y + 7) / 16 + 1: x222 = x111
  CASE 4: x111 = (x + 6) / 16 + 1: y111 = (y + 4) / 16 + 1:  y222 = (y + 7) / 16 + 1: x222 = x111
END SELECT
  nn1 = (y111 * mmmx - mmmx) + x111
  nn2 = (y222 * mmmx - mmmx) + x222
FOR tt11 = 1 TO 2
'### Checks the tile being ocupied
  SELECT CASE tt11
  CASE 1: ln2$ = wl2$(nn1):
  CASE 2: ln2$ = wl2$(nn2):
  END SELECT
'### These tiles represent walls
SELECT CASE ln2$
CASE IS = "2": tt11 = 3: x = xa2: y = ya2: zfb2 = 1
'(tt11= 3) if it hits a wall, it doesn't need to scan 2nd tile
CASE IS = "3":
T3 = 0: warp: IF T3 = 1 THEN x = xa2: y = ya2:
nd = 1
IF nd = 1 THEN GOTO wllnd
CASE ELSE: y = ya5: x = xa5
END SELECT
NEXT
GOTO wllnd

wllnd:
xa2 = x: ya2 = y
END SUB

SUB zdie
d = 2
n = 0
DO
WAIT &H3DA, 8
WAIT &H3DA, 8, 8
paus
n = n + 16
LINE (0 - n, 0)-(0 + n, 199), 0, BF
LINE (319 + n, 0)-(319 - n, 199), 0, BF
x = xa: y = ya: mv = mvb:
flash2 = 0: flash1 = 1
mov
LOOP UNTIL n >= 160
FOR nnn = 1 TO 2
FOR n = 1 TO 2
LINE (x, y + 8)-(x + 15, y + 15 + 8), 0, BF
Putimg x, y, r2()
paus
NEXT
FOR n = 1 TO 2
LINE (x, y + 8)-(x + 15, y + 15 + 8), 0, BF
mov
Putimg x, y, u2()
paus
NEXT
FOR n = 1 TO 2
LINE (x, y + 8)-(x + 15, y + 15 + 8), 0, BF
Putimg x, y, l2()
paus
NEXT
FOR n = 1 TO 2
LINE (x, y + 8)-(x + 15, y + 15 + 8), 0, BF
Putimg x, y, d2()
paus
NEXT
NEXT
LINE (x, y + 8)-(x + 15, y + 16 + 8), 0, BF
COLOR 12
LOCATE 12, 12
PRINT "G A M E    O V E R"
DO: LOOP UNTIL INKEY$ <> ""
SLEEP
END SUB

SUB zflyba
zfb3 = 6
mv = 2
SELECT CASE zfb
CASE 1: y = y - zfb3:
CASE 2: y = y + zfb3:
CASE 3: x = x + zfb3:
CASE 4: x = x - zfb3:
END SELECT
wll
zfbn = zfbn - 1
IF zfb2 = 1 THEN zfb2 = 0: ' GOSUB zset1
IF zfbn = 0 THEN GOSUB zset1
GOTO zflnd
zset1:
SELECT CASE zfb
CASE 1: d = 2
CASE 2: d = 1
CASE 3: d = 3
CASE 4: d = 4
END SELECT
RETURN
zflnd:
END SUB

SUB zhit
'
IF flash2 = 0 THEN GOSUB zn1
GOTO zhtnd
zn1:
'note: if armor is added, then change the below so
' it can calculate how much armor absorbs
zhp = zhp - objCFG1(obn).Obhrm:
playfx 4
flsh = 20: flash2 = 1: hdis
zfbn = 6:
IF oad = 1 THEN zfb = 1:  d = 1
IF oad = 2 THEN zfb = 2:  d = 2
IF oad = 3 THEN zfb = 4:  d = 3
IF oad = 4 THEN zfb = 3:  d = 4
'IF y < oay AND x + 5 > oax AND x < oax + 5 THEN zfb = 1: GOTO zhtnd
'IF y > oay AND x + 5 > oax AND x < oax + 5 THEN zfb = 2: GOTO zhtnd
'IF x > oax AND y + 5 > oay AND y < oay + 5 THEN zfb = 3: GOTO zhtnd
'IF x < oax AND y + 5 > oay AND y < oay + 5 THEN zfb = 4: GOTO zhtnd
zhtnd:
END SUB

SUB zinfo
IF qbasic1 = 1 THEN qberr: GOTO znd
'Note: if you are using Qbasic and it crashes run setup and pick qbasic mode
DIM txtbg1(8500)
GET (64, 56)-(256, 143), txtbg1
'When you hit I
  COLOR 15
  LOCATE 8, 9:  PRINT "ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ"
  LOCATE 9, 9:  PRINT "Û                      Û"
  LOCATE 10, 9: PRINT "Û         Ziel         Û"
  LOCATE 11, 9: PRINT "Û                      Û"
  LOCATE 12, 9: PRINT "Û      Jay  Cook       Û"
  LOCATE 13, 9: PRINT "Û                      Û"
  LOCATE 14, 9: PRINT "Û                      Û"
  LOCATE 16, 9: PRINT "Û                      Û"
  IF sd = 0 THEN LOCATE 15, 9: PRINT "Û     Sound is OFF     Û"
  IF sd = 1 THEN LOCATE 15, 9: PRINT "Û     Sound is ON!     Û"
  LOCATE 16, 11: PRINT "Free memory:"; FRE(-1)
  LOCATE 17, 9: PRINT "ÛLast updated: "; dat1$; "Û"
  LOCATE 18, 9: PRINT "ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ"
 DO: LOOP UNTIL INKEY$ <> ""
PUT (64, 56), txtbg1, PSET
REDIM txtbg1(100)
znd:
END SUB

SUB zinit
'######## Init info
'fill cache at begining to NONE for rooms
FOR n = 1 TO rmnb
room1$(n) = "NONE"
NEXT
' \/ Starting sword values
ht1 = 0: ht2 = 0: ht3 = 0: htt = 0
'for when ziel flashes when he gets hit
flash1 = 1: mapend$ = "u20"
dat1$ = "11-02-97": 'last updated date
map$ = "h1": 'start room
wlmx = 240: 'max tiles in a room
wlm2 = 240: 'Max colision units
xx = 16: yy = 16: 'X/Y Size of tiles
mmmx = 20: 'Map tiles x width
mmmy = 12: 'Map tiles y width
mmx = mmmx - 1
mmy = mmmy - 1
tx = 16: 'Pixels X-width of tiles
ty = 16: 'Pixels Y-width of tiles
mv = 2: d = 2: 'Start in direction 2,animation frame 2
ms = 3: 'how many spaces Ziel moves
gold = 0
mzhp = 10: 'starting hitpoints
zhp = mzhp
'mp2$ = COMMAND$
IF mp2$ <> "" THEN map$ = mp2$
set2$ = ""
zmap
x = sx% * 16 - 16: y = SY% * 16 - 16
xa = x: ya = y:
start:
map$ = map2$
mx = 0: my = 0
RESULT = GET2(x, y + 8, x + 15, y + 23, bg1())
upt
END SUB

SUB zmap
'##### mapper #####
'### loads map and puts into array
REDIM wl2$(wlmx)
REDIM wl3(wlmx) AS INTEGER
REDIM wl4(wlmx) AS INTEGER
IF map$ = "" THEN GOTO mapnd:
map3$ = map$
OPEN map$ FOR INPUT AS #1
INPUT #1, n$
INPUT #1, S$
INPUT #1, w$
INPUT #1, E$
INPUT #1, r$
INPUT #1, sx%
INPUT #1, SY%
FOR b = 1 TO wlmx
INPUT #1, ln%, ln2%
wl3(b) = ln%
wl4(b) = ln2%
NEXT
FOR b2 = 1 TO wlm2
INPUT #1, ln2$:
wl2$(b2) = ln2$
NEXT
INPUT #1, set$:
INPUT #1, otxt1$
INPUT #1, otxt2$
INPUT #1, otxt3$
INPUT #1, otxt4$
INPUT #1, otxt5$
INPUT #1, otxt6$
INPUT #1, otxt7$
INPUT #1, otxt8$
CLOSE

GOTO mp2
ldst:
set1
set2$ = set$
tile123
RETURN
mp2:
IF dr = 5 THEN SY2% = SY% * yy - yy: y = SY2%: ya = y:
IF dr = 5 THEN sx2% = sx% * xx - xx: x = sx2%: xa = x:
IF dr = 5 THEN dr = 2:
IF Yn = 1 THEN GOTO mapnd:
'OUT &H3C4, 1:   CMR% = INP(&H3C5): OUT &H3C5, CMR% OR &H20
IF set$ = set2$ GOTO mp1 ELSE GOSUB ldst
mp1:
hdis
mp: '#### map drawer/maker
'#### Goes through array and use numbers from file and convert to tiles
GOSUB lnd
'OUT &H3C4, 1: CMR% = INP(&H3C5): OUT &H3C5, CMR% AND &HDF
GOTO mapnd:
'############ Clean up !!! ############

lnd: '###### matches tile with number(from map file)
mx = -1: my = 0
FOR b = 1 TO 240
mx = mx + 1
IF mx > 19 THEN my = my + 1: mx = 0
nm3% = wl3(b)
GOSUB til1:
nm3% = wl4(b)
GOSUB til1:
NEXT
RETURN

til1:
SELECT CASE nm3%
CASE 1
putimt mx * xx, my * yy, T1()
CASE 2
putimt mx * xx, my * yy, t2()
CASE 3
putimt mx * xx, my * yy, T3a()
CASE 4
putimt mx * xx, my * yy, t4()
CASE 5
putimt mx * xx, my * yy, t5()
CASE 6
putimt mx * xx, my * yy, t6()
CASE 7
putimt mx * xx, my * yy, t7()
CASE 8
putimt mx * xx, my * yy, t8()
CASE 9
putimt mx * xx, my * yy, t9()
CASE 10
putimt mx * xx, my * yy, t10()
CASE 11
putimt mx * xx, my * yy, t11()
CASE 12
putimt mx * xx, my * yy, t12()
CASE 13
putimt mx * xx, my * yy, t13()
CASE 14
putimt mx * xx, my * yy, t14()
CASE 15
putimt mx * xx, my * yy, t15()
CASE 16
putimt mx * xx, my * yy, t16()
CASE 17
putimt mx * xx, my * yy, t17()
CASE 18
putimt mx * xx, my * yy, t18()
CASE 19
putimt mx * xx, my * yy, t19()
CASE 20
putimt mx * xx, my * yy, t20()
CASE 21
putimt mx * xx, my * yy, t21()
CASE 22
putimt mx * xx, my * yy, t22()
CASE 23
putimt mx * xx, my * yy, t23()
CASE 24
putimt mx * xx, my * yy, t24()
CASE 25
putimt mx * xx, my * yy, t25()
CASE 26
putimt mx * xx, my * yy, t26()
CASE 27
putimt mx * xx, my * yy, t27()
CASE 28
putimt mx * xx, my * yy, t28()
CASE 29
putimt mx * xx, my * yy, t29()
CASE 30
putimt mx * xx, my * yy, t30()
CASE 31
putimt mx * xx, my * yy, t31()
CASE 32
putimt mx * xx, my * yy, t32()
CASE 33
putimt mx * xx, my * yy, t33()
CASE 34
putimt mx * xx, my * yy, t34()
CASE 35
putimt mx * xx, my * yy, t35()
CASE 36
putimt mx * xx, my * yy, t36()
CASE 37
putimt mx * xx, my * yy, t37()
CASE 38
putimt mx * xx, my * yy, t38()
CASE 39
putimt mx * xx, my * yy, t39()
CASE 40
putimt mx * xx, my * yy, t40()
CASE 41
putimt mx * xx, my * yy, t41()
CASE 42
putimt mx * xx, my * yy, t42()
CASE 43
putimt mx * xx, my * yy, t43()
CASE 44
putimt mx * xx, my * yy, t44()
CASE 45
putimt mx * xx, my * yy, t45()
CASE 46
putimt mx * xx, my * yy, t46()
CASE 47
putimt mx * xx, my * yy, t47()
CASE 48
putimt mx * xx, my * yy, t48()
CASE 49
putimt mx * xx, my * yy, t49()
CASE 50
putimt mx * xx, my * yy, t50()
END SELECT
RETURN
mapnd:

RESULT = GET2(x, y + 8, x + 15, y + 23, bg1())
FOR obn = 1 TO 8: 'Clears object array
obje(obn).obtp = 0: obje(obn).Xax = 0: obje(obn).yax = 0: obje(obn).Dob = 0: obje(obn).Mvob = 0
NEXT
hx = 1: hy = 1
RESULT = GET2(hx, hy, hx + 15, hy + 15, BG1S())
ht1 = 0
ObjR
REDIM wl3(1) AS INTEGER
REDIM wl4(1) AS INTEGER
zfb2 = 1
zfbn = 0
IF map3$ = mapend$ THEN mapend$ = mapend$:  ELSE GOTO nd1
upt
OPEN "finish.txt" FOR INPUT AS #1
INPUT #1, txt$
CLOSE
FOR n = 1 TO 60
paus
NEXT
sign1
endscrn
nd1:
END SUB

SUB zstrk
'note: change this if ziel has diferent swords
obje(obn).Ohp = obje(obn).Ohp - 1
playfx 2
END SUB

