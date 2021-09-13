'98/5/15 3334
DEFINT A-Z
DECLARE FUNCTION VALCHECK% (Num$, Number%)
DECLARE FUNCTION BIN$ (Number%)

LOCATE , , 0: CLS

NumColors(0) = 7: NumColors(1) = 11: NumColors(2) = 9: NumColors(3) = 13

MenuChoices = 2
MenuText$(0) = "The number to shift:"
MenuText$(1) = "Value to shift by:"
MenuRow = 1: MenuCol = 20: NumCol = 41

Num$(0) = "1456"
Num$(1) = "7"
GOSUB RefreshValues

GOSUB ShowMenuChoices

DO
 Key$ = INKEY$
 SELECT CASE Key$
 CASE "0" TO "9": GOSUB AddKeyToNum
 CASE CHR$(0) + "H": MenuChoice = (MenuChoice + MenuChoices - 1) MOD MenuChoices: GOSUB ShowMenuChoices
 CASE CHR$(0) + "P": MenuChoice = (MenuChoice + 1) MOD MenuChoices: GOSUB ShowMenuChoices
 CASE CHR$(0) + "K": IF VALCHECK(Num$, Number) THEN Num$ = ""
 CASE CHR$(0) + "M":
 CASE CHR$(8): IF LEN(Num$(MenuChoice)) THEN Num$(MenuChoice) = LEFT$(Num$(MenuChoice), LEN(Num$(MenuChoice)) - 1): GOSUB ShowCurNum
 CASE CHR$(13): GOSUB RefreshValues
 CASE CHR$(27): EXIT DO
 END SELECT
LOOP

CLS
END

AddKeyToNum:
 IF LEN(Num$(MenuChoice)) >= 10 THEN RETURN
 Num$(MenuChoice) = Num$(MenuChoice) + Key$
 ShowChoice = MenuChoice: GOSUB ShowNum
RETURN

ShowCurNum:
 ShowChoice = MenuChoice
ShowNum:
 IF ShowChoice THEN COLOR 9 ELSE COLOR 11
 LOCATE MenuRow + ShowChoice, NumCol
 PRINT Num$(ShowChoice); : IF ShowChoice = MenuChoice THEN PRINT "_";
 PRINT TAB(NumCol + 10);
RETURN

ShowMenuChoices:
 FOR ShowChoice = 0 TO MenuChoices - 1
  IF ShowChoice = MenuChoice THEN COLOR 15 ELSE COLOR 7
  LOCATE MenuRow + ShowChoice, MenuCol
  PRINT MenuText$(ShowChoice);
  GOSUB ShowNum
 NEXT ShowChoice
RETURN

RefreshValues:
 IF NOT VALCHECK(Num$(0), Num) OR NOT VALCHECK(Num$(1), Shift) THEN
  LOCATE 25, 1
  COLOR 12: PRINT "That value is larger than an integer, it must be no greater than 32768";
  DO: LOOP UNTIL LEN(INKEY$)
  LOCATE 25, 1: PRINT TAB(80);
  RETURN
 END IF
 GOSUB ShiftNum
RETURN

ShiftNum:
 LOCATE 4, 1
 COLOR 7: PRINT Num; Shift; TAB(21); HEX$(Num); "  "; HEX$(Shift); TAB(41); BIN$(Num); "  "; BIN$(Shift)
 IF Shift THEN Number = Num \ Shift ELSE Number = 0
 PRINT Number; TAB(21); HEX$(Number); TAB(41); BIN$(Number)

 PRINT
 NumSum = 0: ShiftSum = 0: BitMask = 16384
 FOR Count = 1 TO 15
  NumColor = 0
  IF Num AND BitMask THEN NumSum = NumSum + Num \ BitMask: NumColor = NumColor OR 1
  IF Shift AND BitMask THEN ShiftSum = ShiftSum + Num \ BitMask: NumColor = NumColor OR 2
  COLOR NumColors(NumColor)
  Number = Num \ BitMask
  PRINT BitMask; TAB(11); Number; TAB(21); HEX$(Number); TAB(41); BIN$(Number)
  BitMask = BitMask \ 2
 NEXT Count

 PRINT
 COLOR 7: PRINT NumSum; TAB(21); HEX$(NumSum); TAB(41); BIN$(NumSum)
 PRINT ShiftSum; TAB(21); HEX$(ShiftSum); TAB(41); BIN$(ShiftSum);
RETURN

GetNum:
 PRINT Text$;
 LINE INPUT Num$
 IF LEN(Num$) > 4 THEN IF Num$ > "32767" THEN PRINT "That value is larger than a integer": GOTO GetNum
RETURN

FUNCTION BIN$ (Number)
  Text$ = STRING$(15, 48)
  BitMask = 16384
  FOR Count = 1 TO 15 STEP 1
    IF Number AND BitMask THEN MID$(Text$, Count) = "1"
    BitMask = BitMask \ 2
  NEXT Count
  BIN$ = Text$
END FUNCTION

FUNCTION VALCHECK (Num$, Number)
  IF LEN(Num$) > 5 THEN EXIT FUNCTION
  IF LEN(Num$) = 5 THEN IF Num$ > "32767" THEN EXIT FUNCTION
  Number = VAL(Num$): VALCHECK = -1
END FUNCTION

