DEFINT A-Z
SCREEN 13
GOSUB SetColors

COLOR 23: LOCATE 1, 1: PRINT "Arrow keys       /      /";
LOCATE 13, 27: PRINT "PgUp"; : LOCATE 14, 27: PRINT "PgDn";
LINE (0, 12)-(99, 111), 63, B
GOSUB ShowChoices: GOSUB ColorSpace
ColorArrange = 4: GOSUB RedrawBlocks

DO
 Kbrd$ = INKEY$
 SELECT CASE Kbrd$
 CASE CHR$(0) + "Q": ColorArrange = (ColorArrange + 5) MOD 6: GOSUB RedrawBlocks
 CASE CHR$(0) + "I": ColorArrange = (ColorArrange + 1) MOD 6: GOSUB RedrawBlocks
 CASE CHR$(0) + "H": ColorChoice = (ColorChoice + 3) MOD 4: GOSUB ShowChoices: GOSUB ShowValues
 CASE CHR$(0) + "P": ColorChoice = (ColorChoice + 1) MOD 4: GOSUB ShowChoices: GOSUB ShowValues
 CASE CHR$(0) + "K"
  IF ColorChoice < 3 THEN
   ColorShft = 2 ^ (ColorChoice * 2): ColorVal = ColorNumber \ ColorShft AND 3
   ColorNumber = ColorNumber AND NOT (3 * ColorShft)
   ColorNumber = ColorNumber OR ((ColorVal + 3) MOD 4) * ColorShft
   GOSUB ColorSpace
  ELSE
   ColorNumber = (ColorNumber + 63) MOD 64: GOSUB ColorSpace
  END IF
 CASE CHR$(0) + "M":
  IF ColorChoice < 3 THEN
   ColorShft = 2 ^ (ColorChoice * 2): ColorVal = ColorNumber \ ColorShft AND 3
   ColorNumber = ColorNumber AND NOT (3 * ColorShft)
   ColorNumber = ColorNumber OR ((ColorVal + 1) MOD 4) * ColorShft
   GOSUB ColorSpace
  ELSE
   ColorNumber = (ColorNumber + 1) MOD 64: GOSUB ColorSpace
  END IF
 CASE CHR$(27), CHR$(13): EXIT DO
 END SELECT
LOOP
END

RedrawBlocks:
FOR PalColor = 0 TO 63
 Clr1 = PalColor AND 3
 Clr2 = (PalColor AND 12) \ 4
 Clr3 = (PalColor AND 48) \ 16
 SELECT CASE ColorArrange
 CASE 0: Row = Clr1 * 5: Col = Clr2 * 5: Col = Col + Clr3 * 26
 CASE 1: Row = Clr1 * 5: Col = Clr3 * 5: Col = Col + Clr2 * 26
 CASE 2: Row = Clr2 * 5: Col = Clr1 * 5: Col = Col + Clr3 * 26
 CASE 3: Row = Clr2 * 5: Col = Clr3 * 5: Col = Col + Clr1 * 26
 CASE 4: Row = Clr3 * 5: Col = Clr1 * 5: Col = Col + Clr2 * 26
 CASE 5: Row = Clr3 * 5: Col = Clr2 * 5: Col = Col + Clr1 * 26
 END SELECT
 LINE (Col + 105, Row + 93)-(Col + 108, Row + 96), PalColor, BF
NEXT PalColor
RETURN

SetColors:
FOR PalColor = 0 TO 63
 RedClr = PalColor AND 3
 GrnClr = (PalColor AND 12) \ 4
 BluClr = (PalColor AND 48) \ 16
 OUT &H3C9, RedClr * 21
 OUT &H3C9, GrnClr * 21
 OUT &H3C9, BluClr * 21
NEXT PalColor
RETURN

ColorSpace:
LINE (1, 13)-(98, 110), ColorNumber, BF

ShowValues:
ShowChoice = 0
GOSUB NextHighLight: LOCATE 3, 27: PRINT STR$(ColorNumber AND 3);
GOSUB NextHighLight: LOCATE 5, 27: PRINT STR$((ColorNumber AND 12) \ 4);
GOSUB NextHighLight: LOCATE 7, 27: PRINT STR$((ColorNumber AND 48) \ 16);
GOSUB NextHighLight: LOCATE 9, 27: PRINT STR$(ColorNumber); " ";
RETURN

ShowChoices:
ShowChoice = 0
GOSUB NextHighLight: LOCATE 3, 14: PRINT "Red value   =";
GOSUB NextHighLight: LOCATE 5, 14: PRINT "Green value =";
GOSUB NextHighLight: LOCATE 7, 14: PRINT "Blue value  =";
GOSUB NextHighLight: LOCATE 9, 14: PRINT "Color number:";
RETURN

NextHighLight:
IF ShowChoice = ColorChoice THEN COLOR 57 ELSE COLOR 20
ShowChoice = ShowChoice + 1
RETURN

