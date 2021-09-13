DEFINT A-Z
OPTION BASE 0

SCREEN 12
CONST ScreenPixelWidth = 640, ScreenPixelHeight = 480
CONST ScreenRightPixel = ScreenPixelWidth - 1, ScreenBtmPixel = ScreenPixelHeight - 1

CONST FillBorderTotalTypes = 3
CONST FillCursorSize = 10, FillCursorHalfSize = FillCursorSize \ 2
DIM FillCursorBackground(FillCursorSize * FillCursorSize \ 2 + 2)
FillCursorRow = ScreenPixelHeight \ 2: FillCursorCol = ScreenPixelWidth \ 2

FillBorderType = 0
GOSUB DrawFillBorders

GOSUB MoveFillCursorGetImage
GOSUB MoveFillCursorRefresh

DO
  key$ = INKEY$
  SELECT CASE key$
  CASE CHR$(0) + "H": PixelStep = -10: GOSUB MoveFillCursorRow
  CASE CHR$(0) + "P": PixelStep = 10: GOSUB MoveFillCursorRow
  CASE CHR$(0) + "K": PixelStep = -10: GOSUB MoveFillCursorCol
  CASE CHR$(0) + "M": PixelStep = 10: GOSUB MoveFillCursorCol
  CASE "-": PixelStep = -1: GOSUB MoveFillCursorRow
  CASE "+": PixelStep = 1: GOSUB MoveFillCursorRow
  CASE "/": PixelStep = -1: GOSUB MoveFillCursorCol
  CASE "*": PixelStep = 1: GOSUB MoveFillCursorCol
  CASE " "
    IF SceneJustRedrawn THEN
      GOSUB MoveFillCursorPutImage
      PAINT (FillCursorCol, FillCursorRow), 3, 15
      SceneJustRedrawn = 0
    ELSE
      GOSUB DrawFillBorders
    END IF
    GOSUB MoveFillCursorRefresh
  CASE CHR$(13)
    FillBorderType = FillBorderType + 1
    IF FillBorderType >= FillBorderTotalTypes THEN FillBorderType = 0
    GOSUB DrawFillBorders
    GOSUB MoveFillCursorRefresh
  CASE CHR$(27): EXIT DO
  END SELECT

  IF FillCursorChange THEN
    FillCursorChange = 0
    GOSUB MoveFillCursor
  END IF
LOOP

END

MoveFillCursorRow:
  Temp = FillCursorRow + PixelStep
  IF Temp < 0 THEN
    IF FillCursorRow = 0 THEN RETURN
    FillCursorRowNew = 0
  ELSEIF Temp > ScreenBtmPixel THEN
    IF FillCursorRow = ScreenBtmPixel THEN RETURN
    FillCursorRowNew = ScreenBtmPixel
  ELSE
    FillCursorRowNew = Temp
  END IF
  FillCursorColNew = FillCursorCol
  FillCursorChange = -1
RETURN

MoveFillCursorCol:
  Temp = FillCursorCol + PixelStep
  IF Temp < 0 THEN
    IF FillCursorCol = 0 THEN RETURN
    FillCursorColNew = 0
  ELSEIF Temp > ScreenRightPixel THEN
    IF FillCursorCol = ScreenRightPixel THEN RETURN
    FillCursorColNew = ScreenRightPixel
  ELSE
    FillCursorColNew = Temp
  END IF
  FillCursorRowNew = FillCursorRow
  FillCursorChange = -1
RETURN

MoveFillCursor:
  GOSUB MoveFillCursorPutImage
  FillCursorRow = FillCursorRowNew: FillCursorCol = FillCursorColNew
MoveFillCursorRefresh:
  GOSUB MoveFillCursorGetImage
  LINE (FillCursorCol - FillCursorHalfSize, FillCursorRow)-(FillCursorCol + FillCursorHalfSize, FillCursorRow), 12
  LINE (FillCursorCol, FillCursorRow - FillCursorHalfSize)-(FillCursorCol, FillCursorRow + FillCursorHalfSize), 12
RETURN

MoveFillCursorGetImage:
  GOSUB MoveFillCursorGetDims
  GET (FillCursorLeftCol, FillCursorTopRow)-(FillCursorRightCol, FillCursorBtmRow), FillCursorBackground
RETURN

MoveFillCursorPutImage:
  GOSUB MoveFillCursorGetDims
  PUT (FillCursorLeftCol, FillCursorTopRow), FillCursorBackground, PSET
RETURN

MoveFillCursorGetDims:
  IF FillCursorRow < FillCursorHalfSize THEN
    Temp = FillCursorHalfSize
  ELSEIF FillCursorRow > ScreenBtmPixel - FillCursorHalfSize THEN
    Temp = ScreenBtmPixel - FillCursorHalfSize
  ELSE
    Temp = FillCursorRow
  END IF
  FillCursorTopRow = Temp - FillCursorHalfSize
  FillCursorBtmRow = Temp + FillCursorHalfSize
 
  IF FillCursorCol < FillCursorHalfSize THEN
    Temp = FillCursorHalfSize
  ELSEIF FillCursorCol > ScreenRightPixel - FillCursorHalfSize THEN
    Temp = ScreenRightPixel - FillCursorHalfSize
  ELSE
    Temp = FillCursorCol
  END IF
  FillCursorLeftCol = Temp - FillCursorHalfSize
  FillCursorRightCol = Temp + FillCursorHalfSize
RETURN

DrawFillBorders:
  LINE (0, 0)-(ScreenPixelWidth, ScreenPixelHeight), 1, BF
  SELECT CASE FillBorderType
  CASE 0
    FOR Temp = 10 TO 630 STEP 10
      LINE (Temp, 0)-(Temp, 470), 15
      LINE (Temp + 5, 10)-(Temp + 5, 479), 15
    NEXT Temp
  CASE 1
    LINE (100, 20)-(100, 460), 15
    LINE (540, 20)-(540, 460), 15
  CASE 2
    TopRow = 100
    FOR Temp = 10 TO 630 STEP 10
      LINE (Temp, TopRow)-(Temp, TopRow + 100), 15
      TopRow = TopRow + 3
    NEXT Temp
    TopRow = 640 - 120
    FOR Temp = 10 TO 100 STEP 5
      CIRCLE (TopRow, 120), Temp, 15
    NEXT Temp
    LINE (TopRow, 120)-(640, 120), 1
    TopRow = 480 - 120
    FOR Temp = 10 TO 100 STEP 5
      CIRCLE (120, TopRow), Temp, 15
    NEXT Temp
    LINE (0, TopRow)-(120, TopRow), 1
  END SELECT
  SceneJustRedrawn = 1
RETURN

