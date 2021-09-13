SCREEN 12

REDIM AxisPoint(0 TO 1), MovePoint(0 TO 1)
AxisPoint(0) = 240: AxisPoint(1) = 320: UpDown = 0: UpDownJump = 10

DO
 GOSUB MakeLine
 GOSUB MoveLine
 IF (INP(96) AND 128) XOR 128 THEN EXIT DO
LOOP
END

MoveLine:
 IF MovePoint(1) > 0 THEN
  MovePoint(1) = MovePoint(1) - 1
 ELSE
  MovePoint(1) = 639
  IF UpDown THEN
   IF MovePoint(0) > AxisPoint(0) THEN UpDown = 0: MovePoint(0) = 479 ELSE MovePoint(0) = MovePoint(0) + UpDownJump
  ELSE
   IF MovePoint(0) < AxisPoint(0) THEN UpDown = 1: MovePoint(0) = 0 ELSE MovePoint(0) = MovePoint(0) - UpDownJump
  END IF
 END IF
RETURN

MakeLine:
 'WAIT &H3DA, 8, 8: WAIT &H3DA, 8
 LINE (MovePoint(1), MovePoint(0))-(AxisPoint(1), AxisPoint(0)), LineColor
 LineColor = (LineColor + 1) MOD 16
RETURN

