DECLARE FUNCTION PickCol% ()
'DECLARE FUNCTION PickCol% ()
DECLARE FUNCTION InputFile$ (Spec$)
DECLARE SUB delay (DelTime%)
 ' Compiled by Jim MacDonalds 'COMPILER.BAS'
    DEFINT A-Z
    DECLARE SUB Mouse (cx, dx, bx)
    DECLARE SUB MousePointer (SW)
    DIM SHARED A(9)                 'Set up array for code
    Max = 1000
    DIM SHARED LSx(Max)
    DIM SHARED LSy(Max)
    DIM SHARED LEx(Max)
    DIM SHARED LEy(Max)
    DIM SHARED BSx(Max)
    DIM SHARED BSy(Max)
    DIM SHARED BEx(Max)
    DIM SHARED BEy(Max)
    DIM SHARED Crx(Max)
    DIM SHARED Cry(Max)
    DIM SHARED Ty(Max)
    DIM SHARED Tx(Max)
    DIM SHARED Text$(Max)
    DIM SHARED Radius(Max)
    DIM SHARED BType(Max)
    DIM SHARED LType(Max)

    UpArr$ = CHR$(0) + "H"
    DownArr$ = CHR$(0) + "P"
    RightArr$ = CHR$(0) + "M"
    LeftArr$ = CHR$(0) + "K"
                                                          



    DEF SEG = VARSEG(A(0))          'Get array segment (nnnn:    )
                                    '    (two 8 bit)
    FOR i = 0 TO 17                 'length of DATA to
       READ r                       'read
       POKE VARPTR(A(0)) + i, r     'into array/2 (nnnn:iiii) (one 8 bit)
    NEXT i                          'until 17
SCREEN 12
'ON 65 GOSUB DrawScreen
DATA &HB8,&H00,&H00   :   ' mov  AX,[n]       [Swap code-(L),(H)] in AX
DATA &H55             :   ' push BP           Save BP
DATA &H8B,&HEC        :   ' mov  BP,SP        Get BP to c Seg
DATA &HCD,&H33        :   ' int  33           Interrupt 33
DATA &H92             :   ' xchg AX,[reg]     [Swap code-reg] in AX
DATA &H8B,&H5E,&H06   :   ' mov  BX,[BP+6]    Point to (variable)
DATA &H89,&H07        :   ' mov  [BX],AX      Put AX in (variable)
DATA &H5D             :   ' pop  BP           Restore BP
DATA &HCA,&H02,&H00   :   ' ret  2            Far return
     CLS
           
                CALL MousePointer(0)      'Reset mouse and
                CALL MousePointer(1)      'turn pointer on
                CALL MousePointer(3)      'Get coordinates
CONST TRUE = -1
Rad = 10
mode = 1
sex = 269
sey = 417
grid = 8
Snap = 8
cross = 1
Style = 381
BGC = 0' Back Ground Color
GridCol = 8
LineCol = 15

Yoffset = 0
Xoffset = 0

'ON ERROR GOTO NotFound

'Ortho = TRUE
SWAP Arg, Style
GOSUB DrawUndos
GOSUB DrawOptions
Start:
GOSUB DrawScreen
'LINE (sex, sey)-(sex + 12, sey + 12), 1, B

DO WHILE k$ <> CHR$(27)
   IF bx = 3 THEN GOSUB DrawScreen
   'GOSUB CrossHair
   GOSUB Coordinates

  oldrad = Rad
  px = dx: py = cx
  k$ = INKEY$
  CALL Mouse(cx, dx, bx)
  IF bx = 1 THEN
    DO
      CALL Mouse(cx, dx, bx)
    LOOP WHILE bx = 1
    bx = 1
  END IF
  SELECT CASE UCASE$(k$)
     CASE CHR$(27): END
     CASE "-": GOSUB Shrink
     CASE "R": GOSUB DrawScreen
     CASE UpArr$: IF Rad < 80 THEN Rad = Rad + 1: GOSUB DrawRad
     CASE DownArr$: IF Rad > 0 THEN Rad = Rad - 1: GOSUB DrawRad
     CASE "F": LOCATE 1, 1: SHELL "dir *.DWG": DO: LOOP WHILE INKEY$ = "": GOSUB DrawScreen
     CASE "A": GOSUB Paste
     'CASE "S": GOSUB SaveData
     'CASE "L": GOSUB LoadData
     CASE "I": GOSUB info
     CASE "C": mode = 3: GOSUB DrawScreen
     CASE "M": Snap = grid: GOSUB DrawScreen
     CASE "H": SWAP Style, Arg
     CASE "P": GOSUB Pointer
     CASE "D": GOSUB Delete
     CASE "Q":
        
         NL = 0: MaxL = 0
         NB = 0: MaxB = 0
         NC = 0: MaxC = 0
         NT = 0
         GOSUB DrawScreen
     CASE "V":
        GOSUB GetVertex
     CASE "T":
        GOSUB Center
     CASE "G":
       IF gridon = 0 THEN gridon = 1: GOTO Start
       IF gridon = 1 THEN gridon = 0: GOSUB DrawScreen
  END SELECT
 
  IF Rad < 80 AND bx = 1 AND cx > 161 AND cx < 173 AND dx > 533 AND dx < 545 THEN Rad = Rad + 1: delay 9999:  GOSUB DrawScreen
  IF Rad > 0 AND bx = 1 AND cx > 161 AND cx < 173 AND dx > 573 AND dx < 585 THEN Rad = Rad - 1: delay 9999: GOSUB DrawScreen
  IF grid > 4 AND bx = 1 AND cx > 289 AND cx < 301 AND dx > 573 AND dx < 585 THEN grid = grid - 1: delay 9999: GOSUB DrawScreen
  IF grid < 80 AND bx = 1 AND cx > 289 AND cx < 301 AND dx > 533 AND dx < 545 THEN grid = grid + 1: delay 9999: GOSUB DrawScreen
  IF Snap > 4 AND bx = 1 AND cx > 337 AND cx < 349 AND dx > 573 AND dx < 585 THEN Snap = Snap - 1: delay 9999: GOSUB DrawScreen
  IF Snap < 80 AND bx = 1 AND cx > 337 AND cx < 349 AND dx > 533 AND dx < 545 THEN Snap = Snap + 1: delay 9999: GOSUB DrawScreen
  IF bx = 1 AND cx < 397 AND dx < 497 AND dx > 3 AND cx > 3 AND mode = 1 THEN GOSUB DoLine
  IF bx = 1 AND cx < 397 AND dx < 497 AND dx > 3 AND cx > 3 AND mode = 2 THEN GOSUB DoBox
  IF bx = 1 AND cx > 32 AND cx < 46 AND dx > 540 AND dx < 584 THEN mode = 1: GOSUB DrawScreen
  IF bx = 1 AND cx > 64 AND cx < 78 AND dx > 540 AND dx < 584 THEN mode = 2: GOSUB DrawScreen
  IF bx = 1 AND cx > 95 AND cx < 109 AND dx > 540 AND dx < 584 THEN mode = 3: GOSUB DrawScreen
  IF bx = 1 AND cx > 128 AND cx < 140 AND dx > 540 AND dx < 584 THEN mode = 4: GOSUB DrawScreen
  IF bx = 1 AND cx < 397 AND dx < 497 AND dx > 3 AND cx > 3 AND mode = 4 THEN GOSUB AddText
  IF bx = 1 AND dx >= 328 AND dx <= 351 AND cx >= 412 AND cx <= 434 THEN GOSUB PickStyle
  IF bx = 1 AND dx >= 368 AND dx <= 391 AND cx >= 412 AND cx <= 434 THEN GOSUB Delete
  IF bx = 1 AND dx >= 408 AND dx <= 431 AND cx >= 412 AND cx <= 434 THEN GOSUB Copy
  IF bx = 1 AND dx >= 448 AND dx <= 471 AND cx >= 412 AND cx <= 434 THEN F$ = "Copy": GOSUB Paste
  IF bx = 1 AND dx >= 510 AND dx <= 533 AND cx >= 360 AND cx <= 382 THEN GOSUB GetVertex
  IF bx = 1 AND dx >= 550 AND dx <= 573 AND cx >= 360 AND cx <= 382 THEN GOSUB Pointer
  IF bx = 1 AND dx >= 590 AND dx <= 613 AND cx >= 360 AND cx <= 382 THEN GOSUB Center
  IF bx = 1 AND dx >= 505 AND dx <= 528 AND cx >= 275 AND cx <= 297 THEN gridon = 1: GOSUB DrawScreen
  IF bx = 1 AND dx >= 592 AND dx <= 615 AND cx >= 275 AND cx <= 297 THEN gridon = 0: GOSUB DrawScreen
  IF bx = 1 AND dx >= 526 AND dx <= 602 AND cx >= 0 AND cx <= 13 THEN GOSUB FileSub
  IF bx = 1 AND dx >= 0 AND dx <= 69 AND cx >= 412 AND cx <= 434 THEN GOSUB Options

 
  IF NL > 0 AND bx = 1 AND cx > 417 AND cx < 429 AND dx > 141 AND dx < 153 THEN NL = NL - 1: GOSUB DrawScreen
  IF NL < MaxL AND bx = 1 AND cx > 417 AND cx < 429 AND dx > 110 AND dx < 122 THEN NL = NL + 1: GOSUB DrawScreen
 
  IF NB < MaxB AND bx = 1 AND cx > 417 AND cx < 429 AND dx > 173 AND dx < 185 THEN NB = NB + 1: GOSUB DrawScreen
  IF NB >= 0 AND bx = 1 AND cx > 417 AND cx < 429 AND dx > 205 AND dx < 217 THEN NB = NB - 1: GOSUB DrawScreen
  IF NC < MaxC AND bx = 1 AND cx > 417 AND cx < 429 AND dx > 237 AND dx < 249 THEN NC = NC + 1: GOSUB DrawScreen
  IF NC >= 0 AND bx = 1 AND cx > 417 AND cx < 429 AND dx > 269 AND dx < 281 THEN NC = NC - 1: GOSUB DrawScreen:

  IF mode = 3 THEN
     IF cx > 397 - Rad THEN cx = 396 - Rad
     IF dx > 497 - Rad THEN dx = 496 - Rad
     IF dx < 4 + Rad THEN dx = 4 + Rad
     IF cx < 4 + Rad THEN cx = 4 + Rad
     IF cx <> py OR dx <> px OR Rad <> oldrad THEN CIRCLE (px, py), Rad, BGC
     CIRCLE (dx, cx), Rad, LineCol
  END IF
 
  IF bx = 2 AND mode = 3 THEN
    IF NC = MaxC THEN MaxC = MaxC + 1
    NC = NC + 1
    Crx(NC) = dx
    Cry(NC) = cx
    Radius(NC) = Rad
    mode = 1
    GOSUB DrawScreen
  END IF
LOOP
END


DoLine:
  IF Snap <= 4 THEN sig = 0 ELSE sig = 4
  p1x = dx: p1y = cx
  p1x = sig + INT(p1x / Snap) * Snap
  p1y = sig + INT(p1y / Snap) * Snap
InterLude:
  bx = 0
  DO
     GOSUB Coordinates
     hx = cx: hy = dx
     CALL Mouse(cx, dx, bx)
        IF bx = 1 THEN
         DO
           CALL Mouse(cx, dx, bx)
         LOOP WHILE bx = 1
         bx = 1
        END IF
     cx = sig + INT(cx / Snap) * Snap
     dx = sig + INT(dx / Snap) * Snap
     IF cx > 397 THEN cx = 396
     IF dx > 497 THEN dx = 496
     IF dx < 4 THEN dx = 4
     IF cx < 4 THEN cx = 4
     IF cx <> hx OR dx <> hy THEN LINE (p1x, p1y)-(hy, hx), BGC
     IF Style = 0 THEN LINE (p1x, p1y)-(dx, cx), LineCol
     IF Style <> 0 THEN LINE (p1x, p1y)-(dx, cx), LineCol, , Style
     IF bx = 2 THEN GOSUB DrawScreen: RETURN
     IF bx = 1 THEN
       IF NL = MaxL THEN MaxL = MaxL + 1
       NL = NL + 1
       LSx(NL) = p1x
       LSy(NL) = p1y
       LEx(NL) = dx
       LEy(NL) = cx
       LType(NL) = Style
       EXIT DO
     END IF
  LOOP UNTIL INKEY$ = CHR$(27)
  GOSUB DrawScreen
RETURN

DoBox:
  IF Snap <= 4 THEN sig = 0 ELSE sig = 4
  p1x = dx: p1y = cx
  p1x = sig + INT(p1x / Snap) * Snap
  p1y = sig + INT(p1y / Snap) * Snap
  bx = 0
  DO
     GOSUB Coordinates
     hx = cx: hy = dx
     CALL Mouse(cx, dx, bx)
        IF bx = 1 THEN
         DO
           CALL Mouse(cx, dx, bx)
         LOOP WHILE bx = 1
         bx = 1
        END IF

     cx = sig + INT(cx / Snap) * Snap
     dx = sig + INT(dx / Snap) * Snap
     IF cx > 397 THEN cx = 396
     IF dx > 497 THEN dx = 496
     IF dx < 4 THEN dx = 4
     IF cx < 4 THEN cx = 4
     IF cx <> hx OR dx <> hy THEN LINE (p1x, p1y)-(hy, hx), BGC, B
     IF Style = 0 THEN LINE (p1x, p1y)-(dx, cx), LineCol, B
     IF Style <> 0 THEN LINE (p1x, p1y)-(dx, cx), LineCol, B, Style
     IF bx = 2 THEN GOSUB DrawScreen: RETURN
     IF bx = 1 THEN
       IF NB = MaxB THEN MaxB = MaxB + 1
       NB = NB + 1
       BSx(NB) = p1x
       BSy(NB) = p1y
       BEx(NB) = dx
       BEy(NB) = cx
       BType(NB) = Style
       EXIT DO
     END IF
  LOOP WHILE INKEY$ = ""
   GOSUB DrawScreen
RETURN



DrawScreen:
  LINE (4, 4)-(497, 397), BGC, BF
  'LOCATE 22, 64: PRINT "D"
  IF gridon = 1 THEN
       FOR py = 4 TO 397 STEP grid
          FOR px = 4 TO 497 STEP grid
            PSET (px, py), GridCol
          NEXT
       NEXT
  COLOR 15
  END IF
  FOR n = 1 TO NT
    LOCATE Tx(n), Ty(n): PRINT Text$(n)
  NEXT
  FOR n = 1 TO NL
    IF LType(n) <> 0 THEN LINE (LSx(n), LSy(n))-(LEx(n), LEy(n)), LineCol, , LType(n)
    IF LType(n) = 0 THEN LINE (LSx(n), LSy(n))-(LEx(n), LEy(n)), LineCol
  NEXT
  FOR n = 1 TO NB
     IF BType(n) <> 0 THEN LINE (BSx(n), BSy(n))-(BEx(n), BEy(n)), LineCol, B, BType(n)
     IF BType(n) = 0 THEN LINE (BSx(n), BSy(n))-(BEx(n), BEy(n)), LineCol, B
  NEXT
  FOR n = 1 TO NC
    CIRCLE (Crx(n), Cry(n)), Radius(n), LineCol
  NEXT
  FOR n = 1 TO 3
    LINE (n, n)-(500 - n, 400 - n), 25 - (n * 2), B
  NEXT
  IF mode = 1 THEN COLOR 15 ELSE COLOR 7
  LOCATE 3, 69: PRINT "Lines"
  LINE (540, 32)-(540 + 44, 32 + 14), , B
  IF mode = 2 THEN COLOR 15 ELSE COLOR 7
  LOCATE 5, 70: PRINT "Box"
  LINE (540, 64)-(540 + 44, 64 + 14), , B
  IF mode = 3 THEN COLOR 15 ELSE COLOR 7
  LOCATE 7, 69: PRINT "Circ"
  LINE (540, 95)-(540 + 44, 95 + 14), , B
  IF mode = 4 THEN COLOR 15 ELSE COLOR 7
  LOCATE 9, 69: PRINT "Text"
  LINE (540, 128)-(540 + 44, 128 + 14), , B
 
  COLOR 15
  LOCATE 15, 66: PRINT "X: "
  LOCATE 16, 66: PRINT "Y: "
  LINE (518, 222)-(588, 257), , B

  GOSUB DrawRad
RETURN

DrawRad:
  LOCATE 10, 69: PRINT "Rad "
  LOCATE 11, 68: PRINT "+    -"
  LOCATE 11, 69: PRINT Rad
  LOCATE 18, 69: PRINT "Grid "
  LOCATE 19, 68: PRINT "+    -"
  LOCATE 19, 69: PRINT grid
  LOCATE 21, 69: PRINT "Snap "
  LOCATE 22, 68: PRINT "+    -"
  LOCATE 22, 69: PRINT Snap
RETURN


DrawOptions:
  ' add 23 on x amd 22 on y  and 40 apart
  LINE (368, 412)-(391, 434), , B
  LOCATE 27, 48: PRINT "D"
 
  LINE (408, 412)-(431, 434), , B
  LOCATE 27, 53: PRINT "C"
 
  LINE (448, 412)-(471, 434), , B
  LOCATE 27, 58: PRINT "P"
 
  LINE (328, 412)-(351, 434), , B
  IF Style <> 0 THEN LINE (328, 423)-(351, 423), 7, , Style
  IF Style = 0 THEN LINE (328, 423)-(351, 423), 7

  LINE (510, 360)-(533, 382), , B
  LINE (521, 361)-(521, 371), 7
  LINE (521, 371)-(532, 371), 7
  LINE (520, 370)-(522, 372), 2, B

  LINE (550, 360)-(573, 382), , B
  LINE (551, 363)-(572, 379), 7
  LINE (561, 372)-(563, 372), 2
  LINE (562, 371)-(562, 373), 2

  LINE (590, 360)-(613, 382), , B
  CIRCLE (602, 371), 8, 7
  LINE (601, 370)-(603, 372), 2, B

  LINE (505, 275)-(528, 297), , B
  LINE (592, 275)-(615, 297), , B
  FOR py = 1 TO 21 STEP 3
    FOR px = 1 TO 23 STEP 3
      PSET (505 + px, 275 + py), GridCol
    NEXT
  NEXT

  'LINE (488, 412)-(511, 434), , B
  'FOR n = 1 TO 20
  '   LINE (489, 412 + n)-(510, 412 + n), INT(RND * 15) + 1
  'NEXT



LOCATE 1, 68: PRINT "F I L E"
LINE (526, 0)-(602, 13), , B

LOCATE 27, 2: PRINT "Options"
LINE (0, 412)-(69, 434), , B
RETURN



DrawUndos:
  LOCATE 27, 15: PRINT "+"
  LOCATE 27, 17: PRINT "L"
  LOCATE 27, 19: PRINT "-"
 
  LOCATE 27, 23: PRINT "+"
  LOCATE 27, 25: PRINT "B"
  LOCATE 27, 27: PRINT "-"

  LOCATE 27, 31: PRINT "+"
  LOCATE 27, 33: PRINT "C"
  LOCATE 27, 35: PRINT "-"

RETURN


done:
                 CALL MousePointer(2)              'Turn mouse off
   
    DEF SEG
   
END

SaveData:
  OPEN F$ + ".DWG" FOR OUTPUT AS #1
  PRINT #1, NL
  PRINT #1, NB
  PRINT #1, NC
  PRINT #1, NT
  FOR n = 1 TO NL
    PRINT #1, LSx(n)
    PRINT #1, LSy(n)
    PRINT #1, LEx(n)
    PRINT #1, LEy(n)
    PRINT #1, LType(n)
  NEXT
  FOR n = 1 TO NB
    PRINT #1, BSx(n)
    PRINT #1, BSy(n)
    PRINT #1, BEx(n)
    PRINT #1, BEy(n)
    PRINT #1, BType(n)
  NEXT
  FOR n = 1 TO NC
    PRINT #1, Crx(n)
    PRINT #1, Cry(n)
    PRINT #1, Radius(n)
  NEXT
  FOR n = 1 TO NT
    PRINT #1, Tx(n)
    PRINT #1, Ty(n)
    PRINT #1, Text$(n)
  NEXT

  CLOSE #1
RETURN

LoadData:
OPEN F$ + ".DWG" FOR INPUT AS #1
  INPUT #1, NL
  INPUT #1, NB
  INPUT #1, NC
  INPUT #1, NT
  FOR n = 1 TO NL
    INPUT #1, LSx(n)
    INPUT #1, LSy(n)
    INPUT #1, LEx(n)
    INPUT #1, LEy(n)
    INPUT #1, LType(n)
  NEXT
  FOR n = 1 TO NB
    INPUT #1, BSx(n)
    INPUT #1, BSy(n)
    INPUT #1, BEx(n)
    INPUT #1, BEy(n)
    INPUT #1, BType(n)
  NEXT
  FOR n = 1 TO NC
    INPUT #1, Crx(n)
    INPUT #1, Cry(n)
    INPUT #1, Radius(n)
  NEXT
  FOR n = 1 TO NT
    INPUT #1, Tx(n)
    INPUT #1, Ty(n)
    INPUT #1, Text$(n)
  NEXT

  CLOSE #1
  MaxL = NL
  MaxC = NC
  MaxB = NB
  MaxT = NT
  GOSUB DrawScreen
RETURN

Shrink:
  FOR n = 1 TO NL
     LSx(n) = INT(LSx(n) / 2)
     LSy(n) = INT(LSy(n) / 2)
     LEx(n) = INT(LEx(n) / 2)
     LEy(n) = INT(LEy(n) / 2)
  NEXT
  FOR n = 1 TO NB
     BSx(n) = INT(BSx(n) / 2)
     BSy(n) = INT(BSy(n) / 2)
     BEx(n) = INT(BEx(n) / 2)
     BEy(n) = INT(BEy(n) / 2)
  NEXT
  FOR n = 1 TO NC
     Crx(n) = INT(Crx(n) / 2)
     Cry(n) = INT(Cry(n) / 2)
     Radius(n) = INT(Radius(n) / 2)
  NEXT
  GOSUB DrawScreen
RETURN
AddText:
  x = cx / 15
  y = dx / 8
  IF x > 1 AND x < 25 AND y > 1 AND y < 64 THEN
    LOCATE x, y: LINE INPUT txt$
    IF txt$ <> "" THEN
      NT = NT + 1
      Tx(NT) = x
      Ty(NT) = y
      Text$(NT) = txt$
    END IF
  END IF
RETURN

CrossHair:
     px = INT(Showx / Snap) * Snap
     py = INT(Showy / Snap) * Snap
     Showx = INT(dx / Snap) * Snap
     Showy = INT(cx / Snap) * Snap
    IF dx <> px AND px < 497 AND py < 397 OR cx <> py AND px < 497 AND py < 397 THEN
      LINE (4, py + 4)-(496, py + 4), BGC
      LINE (px + 4, 4)-(px + 4, 396), BGC
      'GOSUB DrawScreen
    END IF
     IF Showx < 497 AND Showy < 397 THEN
      LINE (4, Showy + 4)-(496, Showy + 4), 8
      LINE (Showx + 4, 4)-(Showx + 4, 396), 8
     END IF
RETURN

Center:
  FOR n = 1 TO NC
    LINE (Crx(n) - 1, Cry(n) - 1)-(Crx(n) + 1, Cry(n) + 1), 2, B
  NEXT

  DO
    CALL Mouse(cx, dx, bx)
    IF bx = 1 THEN
      'IF cx > 400 THEN EXIT DO
      'IF dx > 500 THEN EXIT DO
      FOR n = 1 TO NC
         IF dx > Crx(n) - 2 AND dx < Crx(n) + 2 AND cx > Cry(n) - 2 AND cx < Cry(n) + 2 THEN
            p1x = Crx(n)
            p1y = Cry(n)
            GOSUB InterLude
            EXIT DO
         END IF
      NEXT
    END IF
  LOOP UNTIL INKEY$ = CHR$(27)
  GOSUB DrawScreen
RETURN





        

GetVertex:
        FOR n = 1 TO NL
          LINE (LSx(n) - 1, LSy(n) - 1)-(LSx(n) + 1, LSy(n) + 1), 2, B
          LINE (LEx(n) - 1, LEy(n) - 1)-(LEx(n) + 1, LEy(n) + 1), 2, B
        NEXT

  DO
    CALL Mouse(cx, dx, bx)
    IF bx = 1 THEN
      'IF cx > 400 THEN EXIT DO
      'IF dx > 500 THEN EXIT DO

      FOR n = 1 TO NL
         IF dx > LSx(n) - 2 AND dx < LSx(n) + 2 AND cx > LSy(n) - 2 AND cx < LSy(n) + 2 THEN
            p1x = LSx(n)
            p1y = LSy(n)
            GOSUB InterLude
            EXIT DO
         END IF
         IF dx > LEx(n) - 2 AND dx < LEx(n) + 2 AND cx > LEy(n) - 2 AND cx < LEy(n) + 2 THEN
            p1x = LEx(n)
            p1y = LEy(n)
            GOSUB InterLude
            EXIT DO
         END IF
      NEXT
    END IF
  LOOP UNTIL INKEY$ = CHR$(27)
  GOSUB DrawScreen
RETURN

info:
  Bubs = 0
  LINE (226, 176)-(400, 300), 0, BF
  FOR n = 1 TO NT: Bubs = Bubs + LEN(Text$(n)): NEXT
  LOCATE 12, 30: PRINT "Num. of Lines:  "; NL
  LOCATE 13, 30: PRINT "Num. of Boxes:  "; NB
  LOCATE 14, 30: PRINT "Num. of Circs:  "; NC
  LOCATE 15, 30: PRINT "Num. of Texts:  "; NT
  LOCATE 16, 30: PRINT "Bubs:           "; Bubs
  LOCATE 18, 39: PRINT "O K"
  LINE (226, 176)-(400, 300), , B
  LINE (286, 270)-(344, 288), , B

  DO
    CALL Mouse(cx, dx, bx)
    IF bx <> 0 AND dx >= 286 AND dx <= 344 AND cx >= 270 AND cx <= 288 THEN EXIT DO
  LOOP UNTIL INKEY$ <> ""
  mode = 0
  GOSUB DrawScreen
RETURN

Delete:
  'LOCATE 26: PRINT "Choose point 1"
  DO
     CALL Mouse(cx, dx, bx)
     IF bx = 1 AND cx <= 397 AND cx > 3 AND dx > 3 AND dx <= 497 THEN
          p1x = dx
          p1y = cx
          EXIT DO
     END IF
  LOOP
  'LOCATE 26: PRINT "              "
  DO
     hx = cx: hy = dx
     CALL Mouse(cx, dx, bx)
     'cx = sig + INT(cx / Snap) * Snap
     'dx = sig + INT(dx / Snap) * Snap
     IF cx > 397 THEN cx = 396
     IF dx > 497 THEN dx = 496
     IF dx < 4 THEN dx = 4
     IF cx < 4 THEN cx = 4
     IF cx <> hx OR dx <> hy THEN LINE (p1x, p1y)-(hy, hx), BGC, B
      LINE (p1x, p1y)-(dx, cx), , B, 381
     IF bx = 2 THEN
       IF dx < p1x THEN SWAP dx, p1x
       IF cx < p1y THEN SWAP cx, p1y

       FOR n = 1 TO NL
         IF LSx(n) >= p1x AND LSx(n) <= dx AND LSy(n) >= p1y AND LSy(n) <= cx OR LEx(n) >= p1x AND LEx(n) <= dx AND LEy(n) >= p1y AND LEy(n) <= cx THEN
            IF n <> NL THEN
              FOR i = n + 1 TO NL
                LSx(i - 1) = LSx(i)
                LSy(i - 1) = LSy(i)
                LEx(i - 1) = LEx(i)
                LEy(i - 1) = LEy(i)
                LType(i - 1) = LType(i)
              NEXT
              'n = n - 1
            END IF
            NL = NL - 1
         END IF
       NEXT
       FOR n = 1 TO NB
         IF BSx(n) >= p1x AND BSx(n) <= dx AND BSy(n) >= p1y AND BSy(n) <= cx OR BEx(n) >= p1x AND BEx(n) <= dx AND BEy(n) >= p1y AND BEy(n) <= cx THEN
            'OR BSx(n) + (BEx(n) - BSx(n)) >= p1x AND BSx(n) + (BEx(n) - BSx(n)) <= dx
            IF n <> NB THEN
              FOR i = n + 1 TO NB
                BSx(i - 1) = BSx(i)
                BSy(i - 1) = BSy(i)
                BEx(i - 1) = BEx(i)
                BEy(i - 1) = BEy(i)
                BType(i - 1) = BType(i)
              NEXT
            END IF
            NB = NB - 1
         END IF
       NEXT
       FOR n = 1 TO NC
         IF Crx(n) >= p1x AND Crx(n) <= dx AND Cry(n) >= p1y AND Cry(n) <= cx THEN
            IF n <> NC THEN
              FOR i = n + 1 TO NC
                Crx(i - 1) = Crx(i)
                Cry(i - 1) = Cry(i)
                Radius(i - 1) = Radius(i)
              NEXT
            END IF
            NC = NC - 1
         END IF
       NEXT

       EXIT DO
     END IF
  LOOP WHILE INKEY$ = ""
  GOSUB DrawScreen


RETURN

Pointer:
  DO
    CALL Mouse(cx, dx, bx)
    IF bx = 1 THEN
      'IF cx > 400 THEN EXIT DO
      'IF dx > 500 THEN EXIT DO
      IF POINT(dx - 1, cx - 1) = LineCol AND cx > 4 AND dx > 4 AND cx < 397 AND dx < 497 THEN
        p1x = dx - 1
        p1y = cx - 1
        GOSUB InterLude
        EXIT DO
      END IF
    END IF
  LOOP UNTIL INKEY$ = CHR$(27)
  GOSUB DrawScreen
RETURN

PickStyle:
  LINE (4, 4)-(100, 100), 0, BF
  LINE (4, 4)-(100, 100), , B
  FOR n = 1 TO 4
    LINE (30, n * 15)-(99, (n * 15) + 15), , B
  NEXT
  LOCATE 6, 5: PRINT "Cancel"
  LINE (29, 78)-(80, 95), , B
 
  LINE (31, 22)-(98, 22), 7
  LINE (31, 37)-(98, 37), 7, , 511
  LINE (31, 52)-(98, 52), 7, , 341
  LINE (31, 67)-(98, 67), 7, , 381
  SELECT CASE Style
     CASE 0: x = 22
     CASE 511: x = 37
     CASE 341: x = 52
     CASE 381: x = 67
  END SELECT
  LINE (25, x)-(20, x + 5)
  LINE (25, x)-(20, x - 5)
  LINE (20, x - 5)-(20, x + 5)
  DO
     CALL Mouse(cx, dx, bx)
     IF bx = 1 THEN
        LINE (29, 78)-(80, 95), , B
        IF dx > 29 AND dx < 80 AND cx > 78 AND cx < 95 THEN GOTO Picked
       FOR n = 1 TO 4
         LINE (30, n * 15)-(99, (n * 15) + 15), , B
         IF dx >= 30 AND dx <= 99 AND cx > n * 15 AND cx < (n * 15) + 15 THEN
            SELECT CASE n
              CASE 1: Style = 0
              CASE 2: Style = 511
              CASE 3: Style = 341
              CASE 4: Style = 381
            END SELECT
            GOTO Picked
         END IF
       NEXT
     END IF
  LOOP UNTIL INKEY$ = CHR$(27)
Picked:
  mode = 0
  LINE (328, 423)-(351, 423), 0
  GOSUB DrawScreen
  GOSUB DrawOptions

RETURN

Copy:
  DO
     CALL Mouse(cx, dx, bx)
     IF bx = 1 AND cx <= 397 AND cx > 3 AND dx > 3 AND dx <= 497 THEN
          p1x = dx
          p1y = cx
          EXIT DO
     END IF
  LOOP
  'LOCATE 26: PRINT "              "
  OPEN "Copy.DWG" FOR OUTPUT AS #1
  DO
     hx = cx: hy = dx
     CALL Mouse(cx, dx, bx)
     'cx = sig + INT(cx / Snap) * Snap
     'dx = sig + INT(dx / Snap) * Snap
     IF cx > 397 THEN cx = 396
     IF dx > 497 THEN dx = 496
     IF dx < 4 THEN dx = 4
     IF cx < 4 THEN cx = 4
     IF cx <> hx OR dx <> hy THEN LINE (p1x, p1y)-(hy, hx), BGC, B
      LINE (p1x, p1y)-(dx, cx), , B, 381
     IF bx = 2 THEN
       IF dx < p1x THEN SWAP dx, p1x
       IF cx < p1y THEN SWAP cx, p1y

       LC = 0
       FOR n = 1 TO NL
         IF LSx(n) >= p1x AND LSx(n) <= dx AND LSy(n) >= p1y AND LSy(n) <= cx OR LEx(n) >= p1x AND LEx(n) <= dx AND LEy(n) >= p1y AND LEy(n) <= cx THEN LC = LC + 1
       NEXT
       PRINT #1, LC
       BC = 0
       FOR n = 1 TO NB
         IF BSx(n) >= p1x AND BSx(n) <= dx AND BSy(n) >= p1y AND BSy(n) <= cx OR BEx(n) >= p1x AND BEx(n) <= dx AND BEy(n) >= p1y AND BEy(n) <= cx THEN BC = BC + 1
       NEXT
       PRINT #1, BC
       CrC = 0
       FOR n = 1 TO NC
         IF Crx(n) >= p1x AND Crx(n) <= dx AND Cry(n) >= p1y AND Cry(n) <= cx THEN CrC = CrC + 1
       NEXT
       PRINT #1, CrC
       PRINT #1, 0
       FOR n = 1 TO NL
         IF LSx(n) >= p1x AND LSx(n) <= dx AND LSy(n) >= p1y AND LSy(n) <= cx OR LEx(n) >= p1x AND LEx(n) <= dx AND LEy(n) >= p1y AND LEy(n) <= cx THEN
                PRINT #1, LSx(n)
                PRINT #1, LSy(n)
                PRINT #1, LEx(n)
                PRINT #1, LEy(n)
                PRINT #1, LType(n)
         END IF
       NEXT
       FOR n = 1 TO NB
         IF BSx(n) >= p1x AND BSx(n) <= dx AND BSy(n) >= p1y AND BSy(n) <= cx OR BEx(n) >= p1x AND BEx(n) <= dx AND BEy(n) >= p1y AND BEy(n) <= cx THEN
                PRINT #1, BSx(n)
                PRINT #1, BSy(n)
                PRINT #1, BEx(n)
                PRINT #1, BEy(n)
                PRINT #1, BType(n)
         END IF
       NEXT
       FOR n = 1 TO NC
         IF Crx(n) >= p1x AND Crx(n) <= dx AND Cry(n) >= p1y AND Cry(n) <= cx THEN
                PRINT #1, Crx(n)
                PRINT #1, Cry(n)
                PRINT #1, Radius(n)
         END IF
       NEXT
     EXIT DO
     END IF
       

      
  LOOP WHILE INKEY$ = ""
  CLOSE #1
  GOSUB DrawScreen
RETURN

Paste:
  OPEN F$ + ".DWG" FOR INPUT AS #1
    INPUT #1, AddNL
    INPUT #1, AddNB
    INPUT #1, AddNC
    INPUT #1, NofT
    FOR n = 1 TO AddNL
      INPUT #1, LSx(NL + n)
      INPUT #1, LSy(NL + n)
      INPUT #1, LEx(NL + n)
      INPUT #1, LEy(NL + n)
      INPUT #1, LType(NL + n)
       LSx(NL + n) = LSx(NL + n) + Xoffset
       LSy(NL + n) = LSy(NL + n) + Yoffset
       LEx(NL + n) = LEx(NL + n) + Xoffset
       LEy(NL + n) = LEy(NL + n) + Yoffset
    NEXT
  FOR n = 1 TO AddNB
    INPUT #1, BSx(NB + n)
    INPUT #1, BSy(NB + n)
    INPUT #1, BEx(NB + n)
    INPUT #1, BEy(NB + n)
    INPUT #1, BType(NB + n)
       BSx(NB + n) = BSx(NB + n) + Xoffset
       BSy(NB + n) = BSy(NB + n) + Yoffset
       BEx(NB + n) = BEx(NB + n) + Xoffset
       BEy(NB + n) = BEy(NB + n) + Yoffset
  NEXT
  FOR n = 1 TO AddNC
    INPUT #1, Crx(NC + n)
    INPUT #1, Cry(NC + n)
    INPUT #1, Radius(NC + n)
    Cry(NC + n) = Cry(NC + n) + Yoffset
    Crx(NC + n) = Crx(NC + n) + Xoffset
  NEXT
  FOR n = 1 TO NofT
    INPUT #1, Tx(n)
    INPUT #1, Ty(n)
    INPUT #1, Text$(n)
  NEXT

  NL = NL + AddNL
  NB = NB + AddNB
  NC = NC + AddNC
  CLOSE #1
  GOSUB DrawScreen
  LINE (180, 200)-(320, 280), 0, BF
  LINE (180, 200)-(320, 280), , B
  LOCATE 14, 25: PRINT "Paste complete!"
  LOCATE 17, 31: PRINT "O K"
  LINE (226, 254)-(276, 271), , B

  DO
     CALL Mouse(cx, dx, bx)
     IF bx <> 0 AND dx >= 226 AND dx <= 276 AND cx >= 254 AND cx <= 271 THEN EXIT DO
  LOOP WHILE INKEY$ = ""
  mode = 0
  GOSUB DrawScreen
RETURN

FileSub:
  LINE (400, 20)-(497, 150), 0, BF
  LINE (400, 20)-(497, 150), , B
  LOCATE 3, 52: PRINT "NEW"
  LOCATE 4, 52: PRINT "OPEN"
  LOCATE 5, 52: PRINT "SAVE"
  LOCATE 6, 52: PRINT "MERGE"
  LOCATE 7, 52: PRINT "DELETE"
  LOCATE 8, 52: PRINT "INFO"

DO WHILE k$ <> CHR$(27)
   IF Ortho = TRUE THEN
     Showx = INT(dx / Snap) * Snap
     Showy = INT(cx / Snap) * Snap
   ELSE
     Showx = dx
     Showy = cx
   END IF
   LOCATE 15, 69: PRINT Showx
   LOCATE 16, 69: PRINT Showy

  oldrad = Rad
  px = dx: py = cx
  k$ = INKEY$
  CALL Mouse(cx, dx, bx)
  IF bx = 1 AND dx >= 408 AND dx <= 460 AND cx >= 32 AND cx <= 44 THEN
     NL = 0: MaxL = 0
     NB = 0: MaxB = 0
     NC = 0: MaxC = 0
     NT = 0
     Style = 0
     EXIT DO
  END IF
  IF bx = 1 AND dx >= 408 AND dx <= 460 AND cx >= 50 AND cx <= 62 THEN
     F$ = InputFile$("Open")
     IF F$ = "" THEN EXIT DO
     GOSUB LoadData
     EXIT DO
  END IF


  IF bx = 1 AND dx >= 408 AND dx <= 460 AND cx >= 66 AND cx <= 74 THEN
     F$ = InputFile$("Save")
     IF F$ = "" THEN EXIT DO
     GOSUB SaveData
     EXIT DO
  END IF

  IF bx = 1 AND dx >= 408 AND dx <= 460 AND cx >= 82 AND cx <= 94 THEN
     F$ = InputFile$("Merge")
     IF F$ = "" THEN EXIT DO
     GOSUB Paste
     EXIT DO
  END IF

  IF bx = 1 AND dx >= 408 AND dx <= 460 AND cx >= 98 AND cx <= 110 THEN
     F$ = InputFile$("Kill")
     IF F$ = "" THEN EXIT DO
     cert = 1
     KILL F$ + ".DWG"
     cert = 0
     EXIT DO
  END IF
 
  IF bx = 1 AND dx >= 408 AND dx <= 460 AND cx >= 114 AND cx <= 126 THEN : GOSUB info: EXIT DO
  IF bx = 2 THEN EXIT DO

LOOP
mode = 0
GOSUB DrawScreen
RETURN
NotFound:
  'PRINT "Error "; ERR; " on line "; ERL
  'BEEP
  SELECT CASE ERR
     CASE 53
        LOCATE 10, 30: PRINT "File not Found !"
        DO: LOOP WHILE INKEY$ = ""
        F$ = "Draft"
     CASE ELSE: PRINT "Miscalanious error .. endding ..": END
  END SELECT
IF cert = 1 THEN END
RESUME

Options:
    'Xoffset = -100
    LINE (4, 397)-(180, 200), 0, BF
    LINE (4, 397)-(180, 200), , B
    LOCATE 24, 2: PRINT "Grid"
    LOCATE 22, 2: PRINT "Line"
    LOCATE 20, 2: PRINT "Board"
    LOCATE 18, 2: PRINT "Y offset    <     >"
    LOCATE 16, 2: PRINT "X offset    <     >"
    LOCATE 14, 2: PRINT "Cord snap   < ";
    IF Ortho = TRUE THEN PRINT "ON  >" ELSE PRINT "OFF >"
    LOCATE 16, 15: PRINT Xoffset
    LOCATE 18, 15: PRINT Yoffset
    LINE (106, 302)-(158, 316), , B
    LINE (106, 334)-(158, 348), , B
    LINE (106, 366)-(158, 380), , B
   
    LINE (107, 303)-(157, 315), BGC, BF
    LINE (107, 335)-(157, 347), LineCol, BF
    LINE (107, 367)-(157, 379), GridCol, BF
    GOSUB DrawOffset
   
 

DO WHILE k$ <> CHR$(27)
   IF bx = 1 AND dx >= 114 AND cx >= 210 AND cx < 220 AND dx <= 148 THEN
      IF Ortho = FALSE THEN Ortho = TRUE: EXIT DO
      IF Ortho = TRUE THEN Ortho = FALSE: EXIT DO
   END IF
   '104 242
   IF bx = 1 AND dx >= 104 AND dx <= 116 AND cx >= 242 AND cx <= 252 THEN
     GOSUB XorOff
     Xoffset = Xoffset - 1
     LOCATE 16, 15: PRINT Xoffset
     GOSUB DrawOffset
     PLAY "l50n0"
   END IF
   IF bx = 1 AND dx >= 150 AND dx <= 162 AND cx >= 242 AND cx <= 252 THEN
     GOSUB XorOff
     Xoffset = Xoffset + 1
     LOCATE 16, 15: PRINT Xoffset
     GOSUB DrawOffset
     PLAY "l50n0"
   END IF
   IF bx = 1 AND dx >= 104 AND dx <= 116 AND cx >= 274 AND cx <= 284 THEN
     GOSUB XorOff
     Yoffset = Yoffset - 1
     LOCATE 18, 15: PRINT Yoffset
     GOSUB DrawOffset
     PLAY "l50n0"
   END IF
   IF bx = 1 AND dx >= 150 AND dx <= 162 AND cx >= 274 AND cx <= 284 THEN
     GOSUB XorOff
     Yoffset = Yoffset + 1
     LOCATE 18, 15: PRINT Yoffset
     GOSUB DrawOffset
     PLAY "l50n0"
   END IF
    IF bx = 1 AND dx >= 107 AND dx <= 157 AND cx >= 303 AND cx <= 315 THEN BGC = PickCol: LINE (107, 303)-(157, 315), BGC, BF
    IF bx = 1 AND dx >= 107 AND dx <= 157 AND cx >= 335 AND cx <= 347 THEN LineCol = PickCol: LINE (107, 335)-(157, 347), LineCol, BF
    IF bx = 1 AND dx >= 107 AND dx <= 157 AND cx >= 367 AND cx <= 379 THEN GridCol = PickCol: LINE (107, 367)-(157, 379), GridCol, BF
    IF bx = 2 THEN EXIT DO
   LOCATE 15, 69: PRINT dx
   LOCATE 16, 69: PRINT cx
   k$ = INKEY$
   CALL Mouse(cx, dx, bx)
LOOP
'c = PickCol
mode = 0
GOSUB DrawScreen

RETURN

DrawOffset:
    LINE (248, 200)-(252, 200)
    LINE (250, 198)-(250, 202)
    LINE (248 + Xoffset, 200 + Yoffset)-(252 + Xoffset, 200 + Yoffset), 2
    LINE (250 + Xoffset, 198 + Yoffset)-(250 + Xoffset, 202 + Yoffset), 2
RETURN

XorOff:
    LINE (248, 200)-(252, 200), BGC
    LINE (250, 198)-(250, 202), BGC
    LINE (248 + Xoffset, 200 + Yoffset)-(252 + Xoffset, 200 + Yoffset), BGC
    LINE (250 + Xoffset, 198 + Yoffset)-(250 + Xoffset, 202 + Yoffset), BGC
RETURN
Coordinates:
   IF Ortho = TRUE THEN
     Showx = INT(dx / Snap) * Snap
     Showy = INT(cx / Snap) * Snap
   ELSE
     Showx = dx
     Showy = cx
   END IF
   LOCATE 15, 69: PRINT Showx
   LOCATE 16, 69: PRINT Showy
RETURN

SUB delay (DelTime)
FOR n = 1 TO DelTime: NEXT
END SUB

FUNCTION InputFile$ (Spec$)
LINE (170, 170)-(360, 260), 0, BF

LOCATE 12, 24: PRINT "File name to "; Spec$; " as:"
LINE (170, 170)-(360, 260), , B
LINE (227, 205)-(298, 224), , B

LOCATE 16, 26: PRINT "O K"
LOCATE 16, 37: PRINT "Cancel"

'186 240
LINE (186, 238)-(236, 256), , B
LINE (278 + 8, 238)-(328 + 8, 256), , B
DO
  LOCATE 15, 69: PRINT dx
  LOCATE 16, 69: PRINT cx
  CALL Mouse(cx, dx, bx)
  A$ = INKEY$
  SELECT CASE UCASE$(A$)
      CASE CHR$(27): END
      CASE "A" TO "Z", "0" TO "9", ":", "\":
        IF LEN(D$) < 8 THEN
          D$ = D$ + UCASE$(A$)
          LOCATE 14, 30: PRINT D$
        END IF
      CASE CHR$(8):
        IF LEN(D$) > 0 THEN
          LOCATE 14, 29 + LEN(D$): PRINT " "
          D$ = LEFT$(D$, LEN(D$) - 1)
        END IF
      CASE CHR$(13): InputFile$ = D$: EXIT FUNCTION
  END SELECT
  IF bx = 1 AND dx >= 186 AND dx <= 236 AND cx >= 238 AND cx <= 256 THEN InputFile$ = D$: EXIT FUNCTION
  IF bx = 1 AND dx >= 286 AND dx <= 336 AND cx >= 238 AND cx <= 256 THEN InputFile$ = "": EXIT FUNCTION

LOOP

InputFile$ = D$

END FUNCTION

SUB Mouse (cx, dx, bx)
         
           POKE VARPTR(A(4)), &H92           'Swap code,Get CX setup
          CALL absolute(cx, VARPTR(A(0)))     'Run Code
              cx = cx                    'Adjust 25x80
           POKE VARPTR(A(4)), &H91           'Swap code,Get DX setup
          CALL absolute(dx, VARPTR(A(0)))     'Run Code
              dx = dx                    'Adjust 25x80
           POKE VARPTR(A(4)), &H93           'Swap code,Get BX setup
          CALL absolute(bx, VARPTR(A(0)))     'Run Code
                                   'Note :
                                   'Remove the /8
                                   'for graphics modes.
END SUB

SUB MousePointer (SW)
         
           POKE VARPTR(A(0)) + 1, SW         'Swap code,Set AX = (SW)
          CALL absolute(c, VARPTR(A(0)))     'Run Code
                                          'Note:
                                             'SW = 0-reset
                                             'SW = 1-on
                                             'SW = 2-off
                                             'SW = 3-coordinates
END SUB

FUNCTION PickCol

FOR n = 0 TO 15
  LINE (100 + (n * 16), 120)-(100 + (n * 16) + 16, 136), , B
NEXT
FOR n = 0 TO 15
  LINE (100 + (n * 16) + 1, 121)-(100 + (n * 16) + 15, 135), n, BF
NEXT
DO WHILE k$ <> CHR$(27)
   LOCATE 15, 69: PRINT dx
   LOCATE 16, 69: PRINT cx
   k$ = INKEY$
   CALL Mouse(cx, dx, bx)
   IF bx = 1 AND dx >= 101 AND dx <= 100 + (n * 16) + 15 AND cx > 120 AND cx < 136 THEN PickCol = POINT(dx - 1, cx - 1): LINE (100, 120)-(100 + (n * 16) + 16, 136), 0, BF: EXIT FUNCTION
   IF bx = 2 THEN PickCol = INT(RND * 16): EXIT FUNCTION
LOOP



END FUNCTION


