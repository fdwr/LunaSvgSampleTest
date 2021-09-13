'Colormapped Bitmap Displayer
'1999-07-04
'
'Simply displays a true color bitmap (24bit) on a 256 color screen using
'very simple colormapping to a 216 color (6x6x6) palette.
DEFINT A-Z

DIM SHARED ColorPalette(383), Colormap(255), BitmapPixelsRow AS STRING * 320
DIM ColorValue AS LONG
BitmapFile$ = "c:\temp\bg\bgsnap00.bmp"

GOSUB OpenBitmap
IF ErrorHandled GOTO EndProgram

SCREEN 13

GOSUB MakeFlatColormap
'GOSUB MakeColormap
'GOSUB MakeRainbowPalette
GOSUB PaletteSet

FilePos& = 64759
DEF SEG = VARSEG(BitmapPixelsRow)
FOR Row = 0 TO 199
    'GOSUB DrawRow
    GET 1, FilePos&, BitmapPixelsRow
    FilePos& = FilePos& - 320
    BytePos = VARPTR(BitmapPixelsRow)
    FOR Col = 0 TO 319
        PSET (Col, Row), Colormap(PEEK(BytePos))
        BytePos = BytePos + 1
NEXT Col, Row

'GOSUB DrawColorBlocks

CLOSE 1

EndProgram:
END

OpenBitmap:
    OPEN BitmapFile$ FOR INPUT AS 1: CLOSE 1
    OPEN BitmapFile$ FOR BINARY AS 1
   
    SEEK 1, 55: Palette$ = INPUT$(1024, 1)
    DEF SEG = VARSEG(ColorPalette(0))
    BytePos = 0
    FOR Count = 1 TO 1024 STEP 4
      ColorValue = CVL(MID$(Palette$, Count, 4))
      POKE BytePos + 2, (ColorValue AND 255) \ 4
      POKE BytePos + 1, (ColorValue AND 65280) \ 1024
      POKE BytePos, (ColorValue AND 16711680) \ 262144
      BytePos = BytePos + 3
    NEXT Count
    Palette$ = ""
RETURN

PaletteSet:
    DEF SEG = VARSEG(ColorPalette(0))
    OUT &H3C8, 0
    FOR BytePos = 0 TO 767 STEP 3
        OUT &H3C9, PEEK(BytePos)
        OUT &H3C9, PEEK(BytePos + 1)
        OUT &H3C9, PEEK(BytePos + 2)
    NEXT BytePos
RETURN

MakeRainbowPalette:
    DEF SEG = VARSEG(ColorPalette(0))
    FOR BytePos = 0 TO 767 STEP 3
        POKE BytePos, INT(RedValue * 12.6)
        POKE BytePos + 1, INT(GreenValue * 12.6)
        POKE BytePos + 2, INT(BlueValue * 12.6)
        IF RedValue >= 5 THEN
            RedValue = 0
            IF GreenValue >= 5 THEN
                GreenValue = 0
                IF BlueValue >= 5 THEN
                    BlueValue = 0
                ELSE
                    BlueValue = BlueValue + 1
                END IF
            ELSE
                GreenValue = GreenValue + 1
            END IF
        ELSE
            RedValue = RedValue + 1
        END IF
    NEXT BytePos
RETURN

DrawColorBlocks:
    Count = 0
    FOR Row = 0 TO 135 STEP 9
        FOR Col = 0 TO 135 STEP 9
            LINE (Col, Row)-(Col + 8, Row + 8), Count, BF
            Count = Count + 1
        NEXT Col
    NEXT Row
RETURN

'DrawRow:
'    'get 1,,BitmapPixelsRow
'    'def seg = varseg(BitmapPixelsRow)
'    'BytePos=varptr(BitmapPixelsRow)
'    FOR Col = 0 TO 199
'        PSET (Col, Row), Colormap(PEEK(BytePos))
'        BytePos = BytePos + 1
'    NEXT Col
'RETURN

MakeColormap:
    DEF SEG = VARSEG(ColorPalette(0))
    BytePos = 0
    FOR Count = 0 TO 255
        ColorVal = PEEK(BytePos) * 6 \ 64 + (PEEK(BytePos + 1) * 6 \ 64) * 6 + (PEEK(BytePos + 2) * 6 \ 64) * 36
        Colormap(Count) = ColorVal
        BytePos = BytePos + 3
    NEXT Count
RETURN

MakeFlatColormap:
    FOR Count = 0 TO 255
        Colormap(Count) = Count
    NEXT Count
RETURN

