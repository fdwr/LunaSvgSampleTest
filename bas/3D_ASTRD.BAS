DEFINT A-Z
SCREEN 12

'--Set Asteroid dimensions--
LastAstr = 4
REDIM Astr(0 TO LastAstr, 0 TO 1)
FOR AstrDot = 0 TO LastAstr
 READ Astr(AstrDot, 0), Astr(AstrDot, 1)
NEXT AstrDot
DATA 0,-20,20,-4,14,16,-10,14,-22,-2
AstrSize! = 1
AstrAngle = 0

'--Define temporary array for resized Asteroid--
REDIM TempAstr(0 TO LastAstr, 0 TO 1)

LOCATE 1, 1: PRINT "Angle:";
LOCATE 2, 1: PRINT "Size:";
GOSUB ConstructAsteroid
GOSUB MakeAsteroid

'--Start main loop--
DO
 SELECT CASE INP(96)
 CASE 77: AstrAngle = (AstrAngle + 4) MOD 360: GOSUB MakeAsteroid
 CASE 75: AstrAngle = (AstrAngle + 356) MOD 360: GOSUB MakeAsteroid
 CASE 72: IF AstrSize! < 6 THEN AstrSize! = AstrSize! + .0625: GOSUB MakeAsteroid
 CASE 80: IF AstrSize! > 1 THEN AstrSize! = AstrSize! - .0625: GOSUB MakeAsteroid
 '--Quit if user presses Esc--
 CASE 1: EXIT DO
 END SELECT
 '--Waste any extra key input--
 WHILE INKEY$ > "": WEND
LOOP
END

MakeAsteroid:
LOCATE 1, 7: PRINT STR$(AstrAngle); "ø"; TAB(13);
LOCATE 2, 7: PRINT AstrSize!; TAB(15);

AstrColor = 0: WAIT &H3DA, 8: GOSUB DrawAsteroid
GOSUB ConstructAsteroid
AstrColor = 12: GOSUB DrawAsteroid
RETURN

ConstructAsteroid:
AstrRad! = AstrAngle * .01745329#
AstrSin! = SIN(AstrRad!)
AstrCos! = COS(AstrRad!)
FOR AstrDot = 0 TO LastAstr
 AstrCol = Astr(AstrDot, 0): AstrRow = Astr(AstrDot, 1)
 TempAstr(AstrDot, 0) = (AstrCol * AstrSin! - AstrRow * AstrCos!) * AstrSize! + 320
 TempAstr(AstrDot, 1) = (AstrRow * AstrSin! + AstrCol * AstrCos!) * AstrSize! + 240
NEXT AstrDot
RETURN

DrawAsteroid:
AstrCol = TempAstr(LastAstr, 0)
AstrRow = TempAstr(LastAstr, 1)
FOR AstrDot = 0 TO LastAstr
 LINE (TempAstr(AstrDot, 0), TempAstr(AstrDot, 1))-(AstrCol, AstrRow), AstrColor
 AstrCol = TempAstr(AstrDot, 0)
 AstrRow = TempAstr(AstrDot, 1)
NEXT AstrDot
RETURN

