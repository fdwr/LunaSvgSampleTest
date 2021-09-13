DEFINT A-Z
DECLARE SUB DrawParticles (PrtLocs(), TestBitmap AS ANY, PrtRows, PrtsPerRow, PrtCols, TopRow, LeftCol)
DECLARE SUB EraseParticles (PrtLocs(), PrtRows, PrtCols, PrtsPerRow, TopRow, LeftCol)
DECLARE SUB RegenerateParticleField (PrtLocs%(), PrtRange%, PrtDistance%, PrtRows%, PrtCols%, PrtsPerRow, SlideCounter)
DECLARE FUNCTION ShiftParticles (PrtLocs(), PrtRange, PrtDistance, PrtRows, PrtCols, PrtsPerRow, SlideDistance, SlideCounter)

TYPE BitmapType
Segment AS INTEGER
AdrPtr AS INTEGER
Hite AS INTEGER
Wdth AS INTEGER
END TYPE

CONST ScreenHeight = 200, ScreenWidth = 320
CONST TestImgHeight = 30, TestImgWidth = 168

PrtRows = 30: PrtCols = TestImgWidth: PrtsPerRow = 10
PrtLast = PrtRows * PrtsPerRow - 1: PrtDistance = 8: PrtRange = 10
PrtTopRow = (ScreenHeight - PrtRows) \ 2: SlideDistance = 6

DIM ScreenImage((TestImgHeight * TestImgWidth \ 2) + 4)
DIM TestBitmap AS BitmapType
DIM PrtLocs(PrtLast)

TestBitmap.Hite = TestImgHeight
TestBitmap.Wdth = TestImgWidth
InitialBitmapAdr = VARPTR(ScreenImage(2)) + TestImgWidth - PrtsPerRow
TestBitmap.AdrPtr = InitialBitmapAdr
TestBitmap.Segment = VARSEG(ScreenImage(2))

'RANDOMIZE TIMER

SCREEN 13
LINE (0, 0)-(319, 199), 0, BF

DrawTestImage:
  LOCATE 1, 1: PRINT "Particle title ripper"; CHR$(13); "Testing out a theory";
  FOR Row = 0 TO TestImgHeight
    FOR Col = 0 TO TestImgWidth
      IF POINT(Col, Row) = 15 THEN PSET (Col, Row), (Col + Row AND 15) + 40
    NEXT Col
  NEXT Row
  'PrtColor = 1
  'BlockSize = 7
  'FOR a = 0 TO TestImgWidth STEP BlockSize
  '  'LINE (INT(RND * TestImgWidth), INT(RND * TestImgHeight))-(INT(RND * TestImgWidth), INT(RND * TestImgHeight)), INT(RND * 16)
  '  LINE (a, 0)-(a + BlockSize - 1, TestImgHeight), PrtColor, BF
  '  LINE (a + 2, 3)-(a + BlockSize - 3, TestImgHeight - 3), PrtColor XOR 2, BF
  '  PrtColor = PrtColor + 1
  'NEXT a

GET (0, 0)-(TestImgWidth - 1, TestImgHeight - 1), ScreenImage

'GenerateRandomParticles:
'  CurParticle = 0
'  FOR CurPrtRow = 0 TO PrtRows - 1
'    FOR CurPrtCol = 0 TO PrtsPerRow - 1
'      PrtLocs(CurParticle) = INT(RND * PrtRange) + CurPrtCol * PrtDistance
'      CurParticle = CurParticle + 1
'    NEXT CurPrtCol
'  NEXT CurPrtRow

ParticleShift = 0
RegenerateParticleField PrtLocs(), PrtRange, PrtDistance, PrtRows, PrtCols, PrtsPerRow, SlideCounter
SlideCounter = 200
DO
  DrawParticles PrtLocs(), TestBitmap, PrtRows, PrtCols, PrtsPerRow, PrtTopRow, LeftCol
  IF PrtCols <= 0 THEN
    RegenerateParticleField PrtLocs(), PrtRange, PrtDistance, PrtRows, PrtCols, PrtsPerRow, SlideCounter
    PrtCols = TestImgWidth
    TestBitmap.AdrPtr = InitialBitmapAdr
  END IF
  'FOR a = 0 TO 5000: NEXT a
  WindowSlid = ShiftParticles(PrtLocs(), PrtRange, PrtDistance, PrtRows, PrtCols, PrtsPerRow, SlideDistance, SlideCounter)
  IF WindowSlid THEN PrtCols = PrtCols - 1
  LINE (0, PrtTopRow)-(PrtCols - 1, PrtTopRow + PrtRows), 0, BF
  IF WindowSlid THEN
    TestBitmap.AdrPtr = TestBitmap.AdrPtr - 1
    LOCATE 10, 1: PRINT SlideCounter; "   ";
  END IF
LOOP UNTIL LEN(INKEY$)

SUB DrawParticles (PrtLocs(), Bitmap AS BitmapType, PrtRows, PrtCols, PrtsPerRow, TopRow, LeftCol)
'given source bitmap
'particle locations
DEF SEG = Bitmap.Segment
BitmapAdr& = Bitmap.AdrPtr
BitmapWrap = Bitmap.Wdth - PrtsPerRow
FOR CurPrtRow = 0 TO PrtRows - 1
  TempRange = PrtCols - PrtsPerRow
  FOR CurPrtCol = 0 TO PrtsPerRow - 1
    IF PrtLocs(CurParticle) >= 0 THEN
      PrtColor = PEEK(BitmapAdr&)
      IF PrtLocs(CurParticle) <= TempRange THEN
        PSET (PrtLocs(CurParticle), TopRow + CurPrtRow), PrtColor
      ELSE
        PSET (TempRange, TopRow + CurPrtRow), PrtColor
      END IF
    END IF
    TempRange = TempRange + 1
    CurParticle = CurParticle + 1
    BitmapAdr& = BitmapAdr& + 1
  NEXT CurPrtCol
  BitmapAdr& = BitmapAdr& + BitmapWrap
NEXT CurPrtRow

END SUB

SUB FillRandomParticleColumn (PrtLocs(), PrtRange, PrtDistance, PrtRows, PrtCols, PrtsPerRow, SlideDistance, SlideCounter)
END SUB

SUB RegenerateParticleField (PrtLocs(), PrtRange, PrtDistance, PrtRows, PrtCols, PrtsPerRow, SlideCounter)

  SlideCounter = PrtsPerRow * PrtDistance
  PrtBaseOffset = -SlideCounter
  CurParticle = 0
  FOR CurPrtRow = 0 TO PrtRows - 1
    FOR CurPrtCol = 0 TO PrtsPerRow - 1
      PrtLocs(CurParticle) = INT(RND * PrtRange) + CurPrtCol * PrtDistance + PrtBaseOffset
      CurParticle = CurParticle + 1
    NEXT CurPrtCol
  NEXT CurPrtRow

END SUB

FUNCTION ShiftParticles (PrtLocs(), PrtRange, PrtDistance, PrtRows, PrtCols, PrtsPerRow, SlideDistance, SlideCounter)
STATIC Slides

PrtLast = PrtRows * PrtsPerRow - 1
SlideCounter = SlideCounter - SlideDistance
IF SlideCounter <= 0 THEN
  FOR CurParticle = PrtLast TO 1 STEP -1
    PrtLocs(CurParticle) = PrtLocs(CurParticle - 1) + SlideDistance
  NEXT CurParticle
  FOR CurParticle = 0 TO PrtLast STEP PrtsPerRow
    PrtLocs(CurParticle) = -INT(RND * PrtRange)
  NEXT CurParticle
  SlideCounter = SlideCounter + PrtDistance
  ShiftParticles = -1
  LOCATE 9, 1: PRINT Slides;
  Slides = Slides + 1
ELSE
  FOR CurParticle = 0 TO PrtLast
    PrtLocs(CurParticle) = PrtLocs(CurParticle) + SlideDistance
  NEXT CurParticle
END IF

END FUNCTION

