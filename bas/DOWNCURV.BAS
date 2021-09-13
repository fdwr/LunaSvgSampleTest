'DEF A-Z
SCREEN 12

PRINT "Just a little curve test, 4-1-98 ver 0.1"
PRINT "Press Shift or enter in your own curve"
SLEEP
IF LEN(INKEY$) = 0 THEN
  LeftValue = -60
  RightValue = 0
  LeftIncrement = 1
  RightIncrement = 1
  GOTO PlotCurve
END IF

INPUT "Start of left:", LeftValue
INPUT "Start of right:", RightValue
INPUT "Left increment:", LeftIncrement
INPUT "Right increment:", RightIncrement

PlotCurve:
FOR PixelRow = 0 TO 479
  'IF ABS(LeftValue) > 160 OR ABS(RightValue) > 160 THEN PixelCol = 160 ELSE PixelCol = LeftValue * RightValue
  PixelCol = (LeftValue * RightValue) \ 10
  PSET (PixelCol + 320, PixelRow), 15
  LeftValue = LeftValue + LeftIncrement
  RightValue = RightValue + RightIncrement
  IF LeftValue = 0 THEN RightIncrement = -RightIncrement
  IF RightValue = 0 THEN LeftIncrement = -LeftIncrement
NEXT PixelRow
END

'ver 0.0
GOSUB ClearScreen
DO
 SELECT CASE INKEY$
 CASE CHR$(0) + "H": startvalue = startvalue - 1: redrawdots = 1
 CASE CHR$(0) + "P": startvalue = startvalue + 1: redrawdots = 1
 CASE " ": GOSUB ClearScreen
 CASE CHR$(27): END
 END SELECT
 IF redrawdots THEN redrawdots = 0: GOSUB DrawDots
LOOP

ClearScreen:
CLS
LINE (160, 0)-(160, 20), 4
redrawdots = 1
RETURN

DrawDots:
upvalue = startvalue
downvalue = startvalue
FOR row = 0 TO 100
 'Plot dot
 pixcol = upvalue * downvalue
 PSET (pixcol + 160, row + 8), 12

 'Modify dots
 upvalue = upvalue + 1
 downvalue = downvalue - 1
NEXT row
RETURN

