'Dialog Box
'1999.1.8 Peekin
'
'Displays a simple dialog box (non-interactive) with a Yoshi picture in it.
'Includes simple functions to blit transparent bitmaps and scaled bitmaps.

DEFINT A-Z
OPTION BASE 0
DECLARE SUB DrawConvexBorder (TopRow, BtmRow, LftCol, RitCol, Mode)
DECLARE SUB DrawConcaveBorder (TopRow, BtmRow, LftCol, RitCol, Mode)
DECLARE SUB DrawStrechBitmap (Bitmap AS ANY, TopRow, LftCol, PixHeight, PixWidth)
DECLARE SUB DrawTranspBitmap (Bitmap AS ANY, TopRow, LftCol, TranspColor)

TYPE BitmapType
PixHeight AS INTEGER
PixWidth AS INTEGER
SegPtr AS INTEGER
AdrPtr AS INTEGER
END TYPE

CONST ElementColorFace = 7, ElementColorBright = 15, ElementColorDark = 8
CONST ElementColorBack = 9, ElementColorLight = 29, ElementColorShadow = 27
DIM SHARED HighColor
CONST YoshiBmp.Height = 18, YoshiBmp.Width = 20, TitleBmp.Height = 5, TitleBmp.Width = 18
DIM YoshiBitmap AS BitmapType, YoshiBitmapData(YoshiBmp.Height * YoshiBmp.Width \ 2)
DIM TitleBitmap AS BitmapType, TitleBitmapData(TitleBmp.Height * TitleBmp.Width \ 2)

'----------------------------------------
GOSUB LoadTestBitmaps

SCREEN 13

GOSUB DrawTestBackground
GOSUB DrawTestDialogBox

DO
  Key$ = INKEY$
  IF Key$ = " " THEN
    HighColor = HighColor XOR 1: GOSUB DrawTestDialogBox
    DO: LOOP WHILE LEN(INKEY$)
  ELSEIF Key$ = CHR$(13) THEN
    GOSUB DrawLargeTestBitmap
    DO: LOOP WHILE LEN(INKEY$) 'waste any keypresses
    DO: LOOP UNTIL LEN(INKEY$) 'wait for keypress
    GOSUB DrawTestBackground
    GOSUB DrawTestDialogBox
  END IF
LOOP UNTIL Key$ = CHR$(27)

WIDTH 80, 25
END

'----------------------------------------
DrawTestBackground:
  LINE (0, 0)-(319, 199), ElementColorBack, BF
  LINE (7, 175)-(312, 192), 0, BF
  LINE (6, 174)-(313, 193), 1, B
  LOCATE 23, 2: PRINT "Press Space to toggle shading mode,"
  LOCATE 24, 2: PRINT "Or Enter to see a large scaled Yoshi.";
RETURN

DrawTestDialogBox:
  DrawConvexBorder 50, 150, 50, 270, 1
  DrawConvexBorder 132, 145, 55, 100, 1
  DrawConvexBorder 132, 145, 105, 150, 1
  DrawConcaveBorder 61, 71, 60, 139, 1
  DrawConcaveBorder 81, 91, 60, 139, 1
  DrawConcaveBorder 61, 119, 160, 239, 1
  PixColor = 55
  FOR Row = 15 TO 0 STEP -1
    CIRCLE (71, 113), Row, PixColor, , , 1
    PAINT (71, 113), PixColor, PixColor
    PixColor = PixColor + 1
  NEXT Row
  DrawTranspBitmap YoshiBitmap, 104, 61, 1
  DrawTranspBitmap TitleBitmap, 101, 75, 0
  DrawStrechBitmap YoshiBitmap, 61, 160, 59, 80
RETURN

LoadTestBitmaps:
  YoshiBitmap.PixWidth = YoshiBmp.Width
  YoshiBitmap.PixHeight = YoshiBmp.Height
  FOR Readin = 0 TO (YoshiBmp.Width * YoshiBmp.Height) \ 2 - 1
    READ LowPix, HighPix
    YoshiBitmapData(Readin) = LowPix OR HighPix * 256
  NEXT Readin
  YoshiBitmap.SegPtr = VARSEG(YoshiBitmapData(0))
  YoshiBitmap.AdrPtr = VARPTR(YoshiBitmapData(0))
 
  TitleBitmap.PixWidth = TitleBmp.Width
  TitleBitmap.PixHeight = TitleBmp.Height
  FOR Readin = 0 TO (TitleBmp.Width * TitleBmp.Height) \ 2 - 1
    READ LowPix, HighPix
    TitleBitmapData(Readin) = LowPix OR HighPix * 256
  NEXT Readin
  TitleBitmap.SegPtr = VARSEG(TitleBitmapData(0))
  TitleBitmap.AdrPtr = VARPTR(TitleBitmapData(0))
RETURN

DrawLargeTestBitmap:
  PixColor = 64
  FOR Row = 0 TO 9
    LINE (Row, Row)-(319 - Row, 199 - Row), PixColor, B
    PixColor = PixColor + 1
  NEXT Row
  DrawStrechBitmap YoshiBitmap, 10, 10, 180, 300
RETURN

'----------
LINE (0, 0)-(319, 199), 11, BF

FOR Row = 60 TO 160 STEP 2
    LINE (110, Row)-(210, Row), 3, , &HAAAA
    LINE (110, Row + 1)-(210, Row + 1), 3, , &H5555
NEXT Row
LINE (100, 50)-(200, 150), 7, BF

LINE (100, 50)-(200, 50), 15
LINE (100, 150)-(200, 150), 8
LINE (100, 50)-(100, 150), 15
LINE (200, 50)-(200, 150), 8

LINE (104, 54)-(196, 54), 8
LINE (104, 70)-(196, 70), 15
LINE (104, 54)-(104, 70), 8
LINE (196, 54)-(196, 70), 15
LINE (105, 55)-(195, 69), 1, BF

FOR Row = 100 TO 115 STEP 2
    LINE (190, Row)-(240, Row), 3, , &HAAAA
    LINE (190, Row + 1)-(240, Row + 1), 3, , &H5555
NEXT Row

LINE (180, 90)-(230, 105), 0, B
LINE (181, 91)-(229, 104), 14, BF

'----------
DEF SEG = &HA000
FOR BytePos = 32767 TO 0 STEP -1
    POKE (BytePos), INP(10)
NEXT BytePos
FOR BytePos = -32768 TO -1
    POKE (BytePos), INP(10)
NEXT BytePos

'----------------------------------------
TestBitmapYoshi:
DATA  1, 1, 1, 1, 1, 1, 1, 1, 1,02,00, 1, 1, 1, 1, 1, 1, 1, 1, 1
DATA  1, 1, 1, 1, 1, 1, 1, 1,00,10,00,00, 1, 1, 1, 1, 1, 1, 1, 1
DATA  1, 1, 1, 1, 1, 1, 1,00,02,00,15,15, 1, 1, 1, 1, 1, 1, 1, 1
DATA  1, 1, 1, 1, 1, 1, 1,00,00,15,15,00, 1, 1, 1, 1, 1, 1, 1, 1
DATA  1, 1, 1, 1, 1, 1,00,00,15,15,15,00, 1,00,00,00, 1, 1, 1, 1
DATA  1, 1, 1, 1, 1,00,14,00,15,15,15,15,00,10,10,10,00,00, 1, 1
DATA  1, 1, 1, 1,00,14,04,00,00,15,15,00,10,10,10,15,15,10,00, 1
DATA  1, 1, 1, 1,00,04,14,00,02,00,00,10,10,10,10,10,00,15,00, 1
DATA  1, 1, 1, 1, 1,00,04,00,02,02,10,10,10,10,10,10,10,10,10,00
DATA  1, 1, 1, 1, 1, 1,00,00,02,10,10,10,10,02,10,10,10,10,10,00
DATA  1, 1, 1, 1, 1,00,14,00,02,10,10,10,15,00,02,10,10,10,10,00
DATA  1, 1, 1, 1,00,14,04,00,02,10,10,10,15,00,02,10,10,10,10,00
DATA  1, 1, 1, 1,00,04,14,00,02,10,10,15,00,00,00,02,10,10,02,0
DATA  1, 1, 1, 1, 1,00,04,00,02,15,15,15,15,15,00,00,02,02,00, 1
DATA  1, 1, 1, 1,00,00,00,00,02,15,15,00,15,15,15,00,00,00, 1, 1
DATA  1, 1, 1,00,14,04,00,02,10,15,00, 1,00,00,00, 1, 1, 1, 1, 1
DATA  1, 1,00,14,04,00,00,10,15,00, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
DATA  1, 1,00,04,14,00,02,10,15,00, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

TestBitmapTitle:
DATA 12, 0,12, 0, 0,14, 0, 0, 0,10,10, 0,09, 0,09, 0,13, 0
DATA 12, 0,12, 0,14, 0,14, 0,10, 0, 0, 0,09, 0,09, 0,13, 0
DATA  0,12, 0, 0,14, 0,14, 0, 0,10, 0, 0,09,09,09, 0,13, 0
DATA  0,12, 0, 0,14, 0,14, 0, 0, 0,10, 0,09, 0,09, 0,13, 0
DATA  0,12, 0, 0, 0,14, 0, 0,10,10, 0, 0,09, 0,09, 0,13, 0

SUB DrawConcaveBorder (TopRow, BtmRow, LftCol, RitCol, Mode)

IF Mode AND 1 THEN
  LINE (LftCol, TopRow)-(RitCol, BtmRow), ElementColorBack, BF
END IF

LINE (RitCol + 1, TopRow - 1)-(RitCol + 1, BtmRow + 1), ElementColorBright
LINE (LftCol - 1, TopRow - 1)-(RitCol + 1, TopRow - 1), ElementColorDark
LINE (LftCol - 1, BtmRow + 1)-(RitCol + 1, BtmRow + 1), ElementColorBright
LINE (LftCol - 1, TopRow)-(LftCol - 1, BtmRow + 1), ElementColorDark

IF HighColor THEN
  LINE (LftCol - 2, TopRow - 2)-(LftCol - 2, BtmRow + 2), ElementColorShadow
  LINE (RitCol + 2, TopRow - 1)-(RitCol + 2, BtmRow + 2), ElementColorLight
  LINE (LftCol - 2, TopRow - 2)-(RitCol + 2, TopRow - 2), ElementColorShadow
  LINE (LftCol - 1, BtmRow + 2)-(RitCol + 2, BtmRow + 2), ElementColorLight
ELSE
  LINE (LftCol - 2, TopRow - 2)-(LftCol - 2, BtmRow + 2), ElementColorDark, , 21845
  LINE (RitCol + 2, TopRow - 1)-(RitCol + 2, BtmRow + 2), ElementColorBright, , 21845
  LINE (LftCol - 2, TopRow - 2)-(RitCol + 2, TopRow - 2), ElementColorDark, , 21845
  LINE (LftCol - 1, BtmRow + 2)-(RitCol + 2, BtmRow + 2), ElementColorBright, , 21845
END IF

END SUB

SUB DrawConvexBorder (TopRow, BtmRow, LftCol, RitCol, Mode)

IF Mode AND 1 THEN
  LINE (LftCol, TopRow)-(RitCol, BtmRow), ElementColorFace, BF
END IF

LINE (LftCol, TopRow)-(LftCol, BtmRow), ElementColorBright
LINE (RitCol, TopRow)-(RitCol, BtmRow), ElementColorDark
LINE (LftCol, TopRow)-(RitCol, TopRow), ElementColorBright
LINE (LftCol, BtmRow)-(RitCol, BtmRow), ElementColorDark

IF HighColor THEN
  LINE (LftCol + 1, TopRow + 1)-(LftCol + 1, BtmRow - 1), ElementColorLight
  LINE (RitCol - 1, TopRow + 1)-(RitCol - 1, BtmRow - 1), ElementColorShadow
  LINE (LftCol + 1, TopRow + 1)-(RitCol - 1, TopRow + 1), ElementColorLight
  LINE (LftCol + 1, BtmRow - 1)-(RitCol - 1, BtmRow - 1), ElementColorShadow
ELSE
  LINE (LftCol + 1, TopRow + 1)-(LftCol + 1, BtmRow - 1), ElementColorBright, , 21845
  LINE (RitCol - 1, TopRow + 1)-(RitCol - 1, BtmRow - 1), ElementColorDark, , 21845
  LINE (LftCol + 1, TopRow + 1)-(RitCol - 1, TopRow + 1), ElementColorBright, , 21845
  LINE (LftCol + 1, BtmRow - 1)-(RitCol - 1, BtmRow - 1), ElementColorDark, , 21845
END IF

END SUB

SUB DrawStrechBitmap (Bitmap AS BitmapType, TopRow, LftCol, PixHeight, PixWidth)

'line used for debugging only
'LINE (LftCol - 1, TopRow - 1)-(LftCol + PixWidth, TopRow + PixHeight), 12, B, 21845

DIM RowSrcPtr AS LONG   'should defined as integer when compiling, but it has
DIM SrcPtr AS LONG      'to be long in Qb to prevent overflows

DEF SEG = Bitmap.SegPtr
RowSrcPtr = Bitmap.AdrPtr

ColSrcInc = 0'Bitmap.PixWidth \ PixWidth
ColCountFull = PixWidth
ColCountDec = Bitmap.PixWidth

RowSrcInc = 0'Bitmap.PixWidth \ PixWidth
RowCountFull = PixHeight
RowCountDec = Bitmap.PixHeight

RowCounter = RowCountFull
FOR Row = TopRow TO TopRow + PixHeight - 1
  SrcPtr = RowSrcPtr
  ColCounter = ColCountFull
  FOR Col = LftCol TO LftCol + PixWidth - 1
    PSET (Col, Row), PEEK(SrcPtr)
    ColCounter = ColCounter - ColCountDec
    IF ColCounter <= 0 THEN
      ColCounter = ColCounter + ColCountFull
      SrcPtr = SrcPtr + ColSrcInc + 1
    'ELSE
      'SrcPtr = SrcPtr + ColSrcInc
    END IF
  NEXT Col
  RowCounter = RowCounter - RowCountDec
  IF RowCounter <= 0 THEN
    RowCounter = RowCounter + RowCountFull
    RowSrcPtr = RowSrcPtr + Bitmap.PixWidth
  'ELSE
    'RowSrcPtr = RowSrcPtr + RowSrcInc
  END IF
NEXT Row

END SUB

SUB DrawTranspBitmap (Bitmap AS BitmapType, TopRow, LftCol, TranspColor)

'line used for debugging only
'LINE (LftCol - 1, TopRow - 1)-(LftCol + Bitmap.PixWidth, TopRow + Bitmap.PixHeight), 12, B, 21845

DIM RowSrcPtr AS LONG   'should defined as integer when compiling, but it has
DIM SrcPtr AS LONG      'to be long in Qb to prevent overflows

DEF SEG = Bitmap.SegPtr
RowSrcPtr = Bitmap.AdrPtr

FOR Row = TopRow TO TopRow + Bitmap.PixHeight - 1
  SrcPtr = RowSrcPtr
  FOR Col = LftCol TO LftCol + Bitmap.PixWidth - 1
    PixColor = PEEK(SrcPtr)
    IF PixColor <> TranspColor THEN PSET (Col, Row), PixColor
    SrcPtr = SrcPtr + 1
  NEXT Col
  RowSrcPtr = RowSrcPtr + Bitmap.PixWidth
NEXT Row

END SUB

