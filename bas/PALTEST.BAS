DEFINT A-Z
DECLARE SUB LIMIT (var%, dif%, lim%, dir%)

'ChngPalette
SCREEN 13: VIEW PRINT: CLS
REDIM Clr(0 TO 2), Lok(0 TO 2)
'0 = Red, 1 = Green, 2 = Blue

GOSUB ChngPaltMakeStuff
GOSUB ChngPaltShowColorMode
GOSUB ChngPaltShowColorData
DO UNTIL Done

 SELECT CASE UCASE$(INKEY$)
 CASE "R": ColrMode = 0
 CASE "G": ColrMode = 1
 CASE "B": ColrMode = 2
 CASE "A": IF Lok(ColrMode) <> 1 THEN Lok(ColrMode) = 1
 CASE "N": IF Lok(ColrMode) <> 0 THEN Lok(ColrMode) = 0
 CASE "S": IF Lok(ColrMode) <> -1 THEN Lok(ColrMode) = -1
 CASE CHR$(0) + "H": LIMIT ColrMode, -1, 0, 0
 CASE CHR$(0) + "P": LIMIT ColrMode, 1, 2, 1
 CASE "+", CHR$(0) + "M"
  FOR ChngMode = 0 TO 2
   IF ChngMode = ColrMode THEN LIMIT Clr(ColrMode), 1, 63, 1 ELSE IF (Lok(ChngMode) AND Lok(ColrMode)) THEN IF Lok(ChngMode) > 0 THEN LIMIT Clr(ChngMode), 1, 63, 1 ELSE LIMIT Clr(ChngMode), -1, 0, 0
  NEXT ChngMode: ColrChng = 1
 CASE "-", CHR$(0) + "K"
  FOR ChngMode = 0 TO 2
   IF ChngMode = ColrMode THEN LIMIT Clr(ColrMode), -1, 0, 0 ELSE IF (Lok(ChngMode) AND Lok(ColrMode)) THEN IF Lok(ChngMode) > 0 THEN LIMIT Clr(ChngMode), -1, 0, 0 ELSE LIMIT Clr(ChngMode), 1, 63, 1
  NEXT ChngMode: ColrChng = 1
 CASE CHR$(27): Done = 1
 END SELECT

 IF ColrChng THEN GOSUB ChngPaltShowColorData: ColrChng = 0
 IF TIMER - LastCrsr! > .0625 THEN GOSUB ChngPaltShowColorMode: LastCrsr! = TIMER
LOOP
END

ChngPaltMakeStuff:
OUT &H3C8, 12: OUT &H3C9, 63: OUT &H3C9, 0: OUT &H3C9, 0
OUT &H3C8, 10: OUT &H3C9, 0: OUT &H3C9, 63: OUT &H3C9, 0
OUT &H3C8, 9: OUT &H3C9, 0: OUT &H3C9, 0: OUT &H3C9, 63
LINE (96, 40)-(223, 175), 15, B
LINE (97, 41)-(222, 174), 255, BF
LOCATE 2, 17: COLOR 12: PRINT "Red": COLOR 10: LOCATE , 17: PRINT "Green": COLOR 9: LOCATE , 17: PRINT "Blue"
LOCATE 24, 1: PRINT "Use the Up, Down, Left, and Right arrows";
LOCATE 25, 1: PRINT "To edit (or use R,G,B,+,-)    A,S,N=lock";
RETURN

ChngPaltShowColorMode:
FOR ShowMode = 0 TO 2
 LOCATE 2 + ShowMode, 15: IF ShowMode = ColrMode THEN COLOR CrsrColr + 9: PRINT "";  ELSE PRINT " ";
 'COLOR 15: LOCATE , 30: PRINT MID$("÷ =", Lok(ShowMode) + 2, 1);
NEXT ShowMode
CrsrColr = (CrsrColr + 1) MOD 6
RETURN

ChngPaltShowColorData:
COLOR 15
FOR ShowMode = 0 TO 2
LOCATE ShowMode + 2, 23: PRINT LEFT$(STR$(Clr(ShowMode)) + "  ", 4);
NEXT ShowMode
LINE (146, 174)-(153, 174 - Clr(0)), 12, BF: LINE (146, 110)-(153, 173 - Clr(0)), 255, BF
LINE (156, 174)-(163, 174 - Clr(1)), 10, BF: LINE (156, 110)-(163, 173 - Clr(1)), 255, BF
LINE (166, 174)-(173, 174 - Clr(2)), 9, BF: LINE (166, 110)-(173, 173 - Clr(2)), 255, BF
'The following sets the palette by sending a byte to the VGA ports
OUT &H3C8, 255
OUT &H3C9, Clr(0) 'Red
OUT &H3C9, Clr(1) 'Green
OUT &H3C9, Clr(2) 'Blue
RETURN

SUB LIMIT (var, dif, lim, dir)
IF dir THEN
 IF var + dif > lim THEN var = lim ELSE var = var + dif
ELSE
 IF var + dif < lim THEN var = lim ELSE var = var + dif
END IF
END SUB

