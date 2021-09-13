DEFINT A-Z
WIDTH 80, 25

COLOR 7: LOCATE 1, 1, 0: PRINT STRING$(80, 196)
PRINT "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ This is a color reverser that uses the XOR operator to"
PRINT "³" + SPACE$(21) + "³ reverse brightness and hue by switching individual bits,"
PRINT "³" + SPACE$(21) + "³ creating a four-way interchangeable color loop."
PRINT "³" + SPACE$(21) + "³ Use the Up and Down Arrows to change the color hue"
PRINT "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ Use the Left and Right Arrows to change the brightness"
PRINT "Use the '+' and '-' or the PgUp and PgDn keys to choose a different color set"
PRINT STRING$(80, 196)

LOCATE 3: COLOR 15
LOCATE , 12: PRINT ""
LOCATE , 7: PRINT "        "
LOCATE , 12: PRINT "";

Colors$ = "Black  Blue   Green  Cyan   Red    Purple Brown  White  Gray   BrBlue BrGreenBrCyan BrRed  Pink   Yellow BrWhite"
Colr = 2

DO
 GOSUB ShowColors
 DO: GOSUB GetKey: LOOP UNTIL Change
LOOP

GetKey:
 Change = -1
 SELECT CASE INKEY$
 CASE CHR$(27): END
 CASE "+", CHR$(0) + "I": Colr = Colr AND 248 OR ((Colr AND 7) + 1 AND 7)
 CASE "-", CHR$(0) + "Q": Colr = Colr AND 248 OR ((Colr AND 7) - 1 AND 7)
 CASE CHR$(0) + "H", CHR$(0) + "P": Colr = Colr XOR 8
 CASE CHR$(0) + "K", CHR$(0) + "M": Colr = Colr XOR 7
 CASE ELSE: Change = 0
 END SELECT
RETURN

ShowColors:
 COLOR Colr: LOCATE 3, 4: PRINT MID$(Colors$, Colr * 7 + 1, 7);
 COLOR Colr XOR 7: LOCATE , 15: PRINT MID$(Colors$, (Colr XOR 7) * 7 + 1, 7);
 COLOR Colr XOR 8: LOCATE 5, 4: PRINT MID$(Colors$, (Colr XOR 8) * 7 + 1, 7);
 COLOR Colr XOR 15: LOCATE , 15: PRINT MID$(Colors$, (Colr XOR 15) * 7 + 1, 7);
RETURN

