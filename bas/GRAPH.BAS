DEFINT A-Z
DECLARE FUNCTION GetPlotX# (y#)
DECLARE FUNCTION GetPlotSin# (y#)

SCREEN 12

COLOR 12: LOCATE 4, 40: PRINT "Red = square formula"
COLOR 9: LOCATE 5, 40: PRINT "Blue = true sine"

FOR PixelRow = 0 TO 479
  y# = PixelRow * 100! / 480
  PixelCol = INT(GetPlotX(y#) * 15)
  PSET (PixelCol, PixelRow), 12
NEXT PixelRow

FOR PixelRow = 0 TO 479
  y# = PixelRow / 154
  PixelCol = INT(GetPlotSin(y#) * 330)
  PSET (PixelCol, PixelRow), 9
NEXT PixelRow

LINE (320, 238)-(320, 242), 15
LINE (318, 240)-(322, 240), 15

COLOR 15
Ylong = 50
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE CHR$(27): EXIT DO
  CASE CHR$(0) + "H": Ylong = Ylong + 1
  CASE CHR$(0) + "P": Ylong = Ylong - 1
  END SELECT
  LOCATE 1, 1: PRINT Ylong, INT(GetPlotX(Ylong / 100) * 1000); TAB(60);
  y# = Ylong / 31.830989#
  LOCATE 2, 1: PRINT INT(y# * 1000), INT(SIN(y#) * 1000); TAB(60);
LOOP

FOR Ylong = 0 TO 100
  PSET (GetPlotX(Ylong / 100) * 1000, GetPlotX((Ylong + 50) / 100) * 1000), 15
NEXT Ylong

FUNCTION GetPlotSin# (y#)
  GetPlotSin = SIN(y#)
END FUNCTION

FUNCTION GetPlotX# (y#)
  GetPlotX = y# * (100 - y#) / 120.71069#
  'GetPlotX# = (100 - y#) / 120.71069# * y#
  'y# + y# * ((100 - y#) / 120.71069#)
END FUNCTION

