'Written for Qbasic by FDwR on 4-8-98
'Load a linear bitmap (LBM) using a palette (PAL)
'Show image in buffer to screen
DEFINT A-Z

DIM ImageBuffer(0 TO 16382) AS LONG, ImagePalette(0 TO 255) AS LONG, BlitBmpCode AS STRING * 68

PictFile$ = "FAIRY.LBM": PalFile$ = "FAIRY.PAL"

PRINT "Loading " + PictFile$ + " picture"
OPEN PictFile$ FOR BINARY AS 1
PRINT "File size:"; LOF(1)
GET 1, 1, ImageHeight: PRINT "Height: "; ImageHeight
GET 1, 3, ImageWidth: PRINT "Width: "; ImageWidth
Index = 0
FileLen& = LOF(1): IF FileLen& > 65532 THEN FileLen& = 65532
IF FileLen& = 0 THEN CLOSE 1: PRINT "Null size image, stopping PICTSHOW.BAS": KILL "FAIRY.LBM": END
PRINT "Bytes loaded:";
FOR BytePos& = 5 TO (FileLen& + 3) AND -4& STEP 4
  GET 1, BytePos&, ImageBuffer(Index)
  Index = Index + 1
  IF Index AND 16 THEN LOCATE , 14: PRINT BytePos&;
NEXT BytePos&
LOCATE , 14: PRINT LOF(1)
CLOSE 1

PRINT "Loading " + PalFile$ + " palette"
OPEN PalFile$ FOR BINARY AS 1
Index = 0
FOR BytePos& = 1 TO 768 STEP 4
  GET 1, BytePos&, ImagePalette(Index)
  Index = Index + 1
NEXT BytePos&
CLOSE 1

PRINT "Setting up Bitmap Blitting code"
FOR Index = 1 TO LEN(BlitBmpCode$)
  READ byte
  MID$(BlitBmpCode$, Index) = CHR$(byte)
NEXT

PRINT "Ready to set color palette and show picture, press any key..."
DO: LOOP UNTIL LEN(INKEY$)

SCREEN 13

DEF SEG = VARSEG(ImagePalette(0)) 'Set segment to ImagePalette's
OUT &H3C8, 0 'Tell VGA register to start at zero
FOR BytePos = VARPTR(ImagePalette(0)) TO VARPTR(ImagePalette(0)) + 767 STEP 3
  OUT &H3C9, PEEK(BytePos)
  OUT &H3C9, PEEK(BytePos + 1)
  OUT &H3C9, PEEK(BytePos + 2)
NEXT BytePos

'PUT (0, 0), ImageBuffer, PSET 'Scrap the old PUT command
LINE (0, 0)-(319, 199), 7, BF

TopRow = (200 - ImageHeight) \ 2
LeftCol = (320 - ImageWidth) \ 2
NeedsRedrawing = 1

DO
  IF NeedsRedrawing THEN
    DEF SEG = VARSEG(BlitBmpCode$)
    CALL ABSOLUTE(BYVAL LeftCol, BYVAL TopRow, BYVAL ImageWidth, BYVAL ImageHeight, BYVAL VARPTR(ImageBuffer(1)), BYVAL VARSEG(ImageBuffer(1)), VARPTR(BlitBmpCode$))
  END IF
  EatKeys = 1
  SELECT CASE INKEY$
  CASE CHR$(0) + "H": IF TopRow > 0 THEN TopRow = TopRow - 1: NeedsRedrawing = 1
  CASE CHR$(0) + "P": IF TopRow < 200 - ImageHeight THEN TopRow = TopRow + 1: NeedsRedrawing = 1
  CASE CHR$(0) + "K": IF LeftCol > 0 THEN LeftCol = LeftCol - 1: NeedsRedrawing = 1
  CASE CHR$(0) + "M": IF LeftCol < 320 - ImageWidth THEN LeftCol = LeftCol + 1: NeedsRedrawing = 1
  CASE CHR$(27): EXIT DO
  CASE "": EatKeys = 0
  END SELECT
  IF EatKeys THEN Null$ = INKEY$
LOOP

WIDTH 80, 25
SCREEN 0 'Restore screen back to normal text mode
COLOR 7, 0: CLS

SYSTEM

'BLITBMP.ASC using ApndData.Bas
DATA 30,6,85,137,229,184,0,160,142,192,139,70,10,142,216,139,118,12,139,94,14
DATA 139,86,16,139,126,18,137,248,193,231,8,193,224,6,1,199,3,126,20,189,64,1
DATA 41,213,137,209,138,4,70,38,136,5,71,73,117,246,1,239,75,117,239,93,7,31
DATA 202,12,0

