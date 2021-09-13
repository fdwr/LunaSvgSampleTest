SCREEN 12

REDIM AxisPoint(0 TO 1), MovePoint(0 TO 1)
AxisPoint(0) = 240: AxisPoint(1) = 320

GOSUB MakeLine
DO
 SELECT CASE INP(96)
 CASE 72: MovePoint(0) = MovePoint(0) - 1: GOSUB MakeLine
 CASE 80: MovePoint(0) = MovePoint(0) + 1: GOSUB MakeLine
 CASE 75: MovePoint(1) = MovePoint(1) - 1: GOSUB MakeLine
 CASE 77: MovePoint(1) = MovePoint(1) + 1: GOSUB MakeLine
 CASE 1: EXIT DO
 END SELECT
 Null$ = INKEY$
LOOP
END

MakeLine:
 'WAIT &H3DA, 8, 8: WAIT &H3DA, 8
 LINE (MovePoint(1), MovePoint(0))-(AxisPoint(1), AxisPoint(0)), LineColor
 LineColor = (LineColor + 1) MOD 16
RETURN

