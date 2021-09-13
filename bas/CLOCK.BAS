'1322 10-30-96 FDR
'revised slightly 5-7-98
DEFINT A-Z
DIM Number$(0 TO 9), Digits(0 TO 5), Chrs$(1 TO 3, 1 TO 5)
FOR GetN = 0 TO 9
  _
DATA "ÜßßßÜ Û   Û Û   Û  ßßß  "," ÜÛ     Û     Û    ßßß  ","ÜßßßÜ    Üß  Üß   ßßßßß ","ÜßßßÜ  ÜÜÜß Ü   Û  ßßß  ","Û   Û ÛÜÜÜÛ     Û     ß ","Ûßßßß ÛÜÜÜ  Ü   Û  ßßß  ","ÜßßßÜ ÛÜÜÜ  Û   Û  ßßß  ","ßßßßÛ    Û    Û    ß    ","ÜßßßÜ ßÜÜÜß Û   Û  ßßß  ","ÜßßßÜ ßÜÜÜÛ     Û     ß "
 READ Number$(GetN)
NEXT GetN

COLOR 7, 0: CLS
COLOR 0, 4

LOCATE 10, 19, 0: PRINT STRING$(41, "ß")
FOR Show = 11 TO 14: LOCATE Show, 19: PRINT " ": NEXT Show: COLOR 12
FOR PutH = 32 TO 46 STEP 14
 FOR Show = 0 TO 3
  LOCATE 11 + Show, PutH: PRINT MID$("  ß ß   ", Show * 2 + 1, 2)
 NEXT Show
NEXT PutH
COLOR 12, 4

DO' UNTIL Done
 'IF INKEY$ > "" THEN Done = -1

 Temp$ = TIME$
 IF Temp$ = "12:00:00" THEN SOUND 860, 1

 'FOR PutT = 1 TO 3
 ' Temp$(PutT) = MID$(Temp$, PutT * 3 - 2, 2)
 'NEXT PutT

 'FOR Clr1 = 1 TO 3: FOR Clr2 = 1 TO 5: Chrs$(Clr1, Clr2) = "": NEXT Clr2, Clr1

 'FOR Put1 = 1 TO 3
 ' FOR Put2 = 1 TO LEN(Temp$(Put1))
 '  Digit = VAL(MID$(Temp$(Put1), Put2, 1))
 '  FOR Put3 = 1 TO 4
 '   Chrs$(Put1, Put3) = Chrs$(Put1, Put3) + MID$(Number$(Digit), (Put3% - 1) * 6 + 1, 6)
 'NEXT Put3, Put2, Put1

 'FOR Put1 = 1 TO 3
 ' FOR Put2 = 1 TO 5
 '  LOCATE Put2 + 10, Put1 * 14 + 6: PRINT Chrs$(Put1, Put2);
 'NEXT Put2, Put1

 FOR Col = 0 TO 2
  Digit1 = VAL(MID$(Temp$, Col * 3 + 1, 1))
  Digit2 = VAL(MID$(Temp$, Col * 3 + 2, 1))
  FOR Row = 0 TO 3
   LOCATE Row + 11, Col * 14 + 20
   PRINT MID$(Number$(Digit1), Row * 6 + 1, 6); MID$(Number$(Digit2), Row * 6 + 1, 6);
 NEXT Row, Col

LOOP UNTIL LEN(INKEY$)

SYSTEM

