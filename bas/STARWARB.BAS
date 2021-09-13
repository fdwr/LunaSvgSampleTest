DEFINT A-Z
DECLARE SUB Scale (sx%, sy%, srx%, sry%, ScaleX%, ScaleY%, LocX%, LocY%)
SCREEN 13

COLOR 15
PRINT "Star"
PRINT "Wars"
REDIM StarWarsWords(0 TO 2163)
'Scale 0, 0, 80, 16, 3, 3, 0, 0
'GET (0, 0)-(92, 44), StarWarsWords(0)
GET (0, 0)-(30, 15), StarWarsWords(0)
CLS
'PALETTE 15, 63


'curscreen = 0
'PCOPY 0, 1
'SCREEN , , curscreen, curscreen XOR 1

'PUT (0, 0), StarWarsWords(0)
'SLEEP
SCREEN 13
DO
p = 2
upper = UBOUND(StarWarsWords)
DEF SEG = VARSEG(StarWarsWords(0))
p = VARPTR(StarWarsWords(0)) + 4
FOR a = 0 TO 15
 p2 = p
 linelength = 0
 xrow = a + 92
 FOR row = a TO 15
  FOR col = 0 + 144 TO 30 + 144
   LINE (col, xrow)-(col, xrow + linelength), PEEK(p2), B
   p2 = p2 + 1
  NEXT col
  'FOR g = 0 TO 9000: NEXT g
  linelength = linelength + 1
  xrow = xrow + linelength
  IF xrow > 199 THEN EXIT FOR
  'LOCATE 1, 1: PRINT linelength; xrow; row - 92
  'SOUND 1024, .024
 NEXT row
 p = p + 31
NEXT a
'FOR a = 0 TO 1000
' PSET (RND * 320, RND * 200), RND * 15 + 1
'NEXT a
LOOP
END
FOR a = 0 + 92 TO 15 + 92
 FOR B = 0 + 144 TO 30 + 144
  IF shift >= 1 THEN pc = StarWarsWords(p) \ 256: shift = 0: p = p + 1 ELSE pc = StarWarsWords(p) AND 255: shift = 1
  LINE (B, a)-(B, 199), pc, B
  FOR c = 0 TO 100: NEXT c
 NEXT B
NEXT a
LINE (0, 45)-(30, 199), 0, BF

DO
 IF a < 1 THEN a = 150 ELSE a = a - 1
 GOSUB drawwords
 olda(curscreen) = a
 'curscreen = curscreen XOR 1
 'SCREEN , , curscreen, curscreen XOR 1
 'FOR b = 0 TO 2000: NEXT b
 'IF eraseit THEN GOSUB erasewords: eraseit = 1
 GOSUB erasewords
LOOP UNTIL INKEY$ > ""

END

erasewords:
 PUT (100, olda(curscreen)), StarWarsWords(0), XOR
RETURN

drawwords:
 PUT (100, a), StarWarsWords(0), XOR
RETURN

SUB Scale (sx, sy, srx, sry, ScaleX, ScaleY, LocX, LocY)
REDIM array(sx TO sx + srx, sy TO sy + sry)

FOR y3 = sy TO sy + sry
FOR x3 = sx TO sx + srx
  array(x3, y3) = POINT(x3, y3)
NEXT: NEXT

FOR y3 = sy TO sy + sry
FOR x3 = sx TO sx + srx
    x1 = (x3 * ScaleX) + LocX
    y1 = (y3 * ScaleY) + LocY
    x2 = (x3 * ScaleX) + ScaleX + LocX
    y2 = (y3 * ScaleY) + ScaleY + LocY
      LINE (x1, y1)-(x2, y2), array(x3, y3), BF
NEXT: NEXT
ERASE array
END SUB

