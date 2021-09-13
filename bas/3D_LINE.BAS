DECLARE SUB FlipScreen (CurrScreen%)
DECLARE SUB DrawLine (TopRow%, LowRow%, Dist%)
DEFINT A-Z

SCREEN 7
Dist = 0: TopRow = 90: LowRow = 110
Renew = 1
DO
 SELECT CASE INP(96)
 CASE 54: IF Dist < 20 THEN Dist = Dist + 1
 CASE 42: IF Dist > -20 THEN Dist = Dist - 1
 END SELECT
 Key$ = INKEY$: IF Key$ = " " THEN Renew = Renew XOR 1: SCREEN , , CurrScreen XOR 1 ELSE IF Key$ = CHR$(27) THEN EXIT DO

 IF Renew THEN FlipScreen CurrScreen ELSE WAIT &H3DA, 8, 8: WAIT &H3DA, 8

 LOCATE 1, 1: PRINT Dist; TAB(3); "ø";
 DrawLine TopRow, LowRow, Dist

LOOP

SCREEN 0, , 0, 0
WIDTH 80, 25
END

SUB DrawLine (TopRow, LowRow, Dist)

LeftCol = 159 - Dist: RiteCol = 160 + Dist

LINE (LeftCol, TopRow)-(LeftCol, LowRow), 12
LINE (RiteCol, TopRow)-(RiteCol, LowRow), 9
END SUB

SUB FlipScreen (CurrScreen)
SCREEN , , CurrScreen, CurrScreen XOR 1
WAIT &H3DA, 8, 8: WAIT &H3DA, 8
CLS 0
CurrScreen = CurrScreen XOR 1
END SUB

