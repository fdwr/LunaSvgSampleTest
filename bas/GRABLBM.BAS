DEFINT A-Z
DECLARE FUNCTION GetWord (Address&)

CONST BufferSize = 8000

SCREEN 13

DEF SEG = 0
BitmapOffset = GetWord(68 * 4)
BitmapSegment = GetWord(68 * 4 + 2)
PRINT "GrabLbm Bitmap should be at"; STR$(BitmapSegment); ":"; LTRIM$(STR$(BitmapOffset))

PRINT "To screen, file, or both? S/F/B"
SELECT CASE UCASE$(INPUT$(1))
CASE "S": OutputToScreen = 1
CASE "F": OutputToFile = 1
CASE "B": OutputToScreen = 1: OutputToFile = 1
CASE ELSE
    PRINT "Cancel"
    GOTO EndProg
END SELECT

FOR a = 0 TO 199 STEP 2
  LINE (0, a)-(319, a), 7, , &H5555
  LINE (0, a + 1)-(319, a + 1), 7, , &HAAAA
NEXT a

IF OutputToFile THEN
  OPEN "\grablbm.bmp" FOR OUTPUT AS #1
'  0    |   2    | (BM) - Tells us that the picture is in bmp format
'  2    |   4    | Size of the file (without header?)
'  6    |   2    | (0) Reserved1 - Must be zero
'  8    |   2    | (0) Reserved2 - Must be zero
'  10   |   4    | Number of bytes offset of the picture data
'-------+--------+--- Information Header starts here -----------------
'  14   |   4    | (40/12) Size of information header (Win3.1/OS2)
'  18   |   4    | Picture width in pixels
'  22   |   4    | Picture Height in pixels
'  26   |   2    | (1) Number of planes, must be 1
'  28   |   2    | Number of bits per pixel (bpp), must be 1,4,8 or 24
'  30   |   4    | (0) Compression - 0 means no compression, 1,2 are RLEs
'  34   |   4    | Image size in bytes
'  38   |   4    | picture width in pels per metre
'  42   |   4    | picture height in pels per metre
'  46   |   4    | (0) Number of colours used in the picture, 0 means all
'  50   |   4    | (0) Number of important colours, 0 means all
  PRINT #1, "BM"; MKL$((54 + 1024 + 64000) \ 4); MKL$(0); MKL$(54 + 1024);
  PRINT #1, MKL$(40); MKL$(320); MKL$(200); MKL$(&H80001); MKL$(0);
  PRINT #1, MKL$(320& * 200); MKL$(0); MKL$(0); MKL$(0); MKL$(0);
END IF

DEF SEG = BitmapSegment

FileBuffer$ = SPACE$(1024)
Adr& = BitmapOffset + 64000
FOR CharPos = 1 TO 1024 STEP 4
    MID$(FileBuffer$, CharPos, 4) = CHR$(PEEK(Adr& + 2) * 4) + CHR$(PEEK(Adr& + 1) * 4) + MKI$(PEEK(Adr&) * 4)
    Adr& = Adr& + 3
NEXT CharPos
IF OutputToFile THEN PRINT #1, FileBuffer$;
IF OutputToScreen THEN
  OUT &H3C8, 0
  FOR CharPos = 1 TO 1024 STEP 4
    OUT &H3C9, ASC(MID$(FileBuffer$, CharPos + 2, 1)) \ 4
    OUT &H3C9, ASC(MID$(FileBuffer$, CharPos + 1, 1)) \ 4
    OUT &H3C9, ASC(MID$(FileBuffer$, CharPos, 1)) \ 4
  NEXT CharPos
END IF

FileBuffer$ = SPACE$(BufferSize)
ScreenAdr& = -1
FOR Adr& = BitmapOffset - 1 TO BitmapOffset + 63998 STEP BufferSize
  FOR CharPos = 1 TO BufferSize STEP 2
    MID$(FileBuffer$, CharPos, 2) = CHR$(PEEK(Adr& + CharPos)) + CHR$(PEEK(Adr& + CharPos + 1))
  NEXT CharPos
  IF OutputToFile THEN PRINT #1, FileBuffer$;
  IF OutputToScreen THEN
    DEF SEG = &HA000
    FOR CharPos = 1 TO BufferSize STEP 2
      POKE ScreenAdr& + CharPos, ASC(MID$(FileBuffer$, CharPos, 1))
      POKE ScreenAdr& + CharPos + 1, ASC(MID$(FileBuffer$, CharPos + 1, 1))
    NEXT CharPos
    ScreenAdr& = ScreenAdr& + BufferSize
    DEF SEG = BitmapSegment
  END IF
NEXT Adr&

IF OutputToFile THEN CLOSE 1
IF OutputToScreen THEN Key$ = INPUT$(1)

EndProg:
  WIDTH 80, 25
  SCREEN 0

  END

FUNCTION GetWord (Address&)
  TempWord& = PEEK(Address&) OR (PEEK(Address& + 1) * 256&)
  IF TempWord& < 32768 THEN GetWord = TempWord& ELSE GetWord = TempWord& - 65536
END FUNCTION

