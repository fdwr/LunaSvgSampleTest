'2000-01-30
'2003-05-05
'Converts bitmap into raw pixel data, converting 8bit to 16bit
DEFINT A-Z
DECLARE FUNCTION NumberStr$ (Number%)

DIM SourceFile AS STRING, DestFile AS STRING, PixelStrip AS STRING
DIM BitmapHeight, BitmapWidth, BitmapBytesPerRow
DIM ImgPalette(255) AS LONG, Pixel AS INTEGER, PixelL AS LONG

BitmapFile$ = COMMAND$
IF RIGHT$(BitmapFile$, 4) = ".BMP" THEN
    SourceFile$ = BitmapFile$
    BitmapFile$ = LEFT$(BitmapFile$, LEN(BitmapFile$) - 4)
ELSE
    SourceFile$ = BitmapFile$ + ".BMP"
END IF
DestFile$ = BitmapFile$ + ".LBM"
DestPal$ = BitmapFile$ + ".PAL"
BitmapHeight = 128
BitmapWidth = 16

COLOR 11
PRINT "-------------------------------"
PRINT "Windows bitmap to linear bitmap"
PRINT "-------------------------------"
PRINT "Source file: "; SourceFile$
PRINT "Dest file:   "; DestFile$
'PRINT "Dest palette:"; DestPal$
IF LEN(BitmapFile$) <= 0 THEN
    COLOR 12
    PRINT "No source bitmap given."
    END
END IF

ON ERROR GOTO ErrorHandler
ErrorHandled = 0

OPEN SourceFile$ FOR INPUT AS 1: CLOSE
IF ErrorHandled THEN
    COLOR 12
    PRINT "Error opening source"
    GOTO ErrorEnd
END IF
OPEN SourceFile$ FOR BINARY AS 1
GET 1, 11, FilePos&
GET 1, 19, BitmapWidth
GET 1, 23, BitmapHeight
GET 1, 29, BitmapBpp
PRINT "Bitmap size: "; NumberStr$(BitmapWidth); "x"; NumberStr$(BitmapHeight)
PRINT "Data starts: "; NumberStr$(INT(FilePos&))
PRINT "Colors     : "; NumberStr$(2 ^ BitmapBpp)
IF (BitmapBpp <> 8) AND (BitmapBpp <> 16) AND (BitmapBpp <> 24) THEN
    COLOR 12
    PRINT "Source must be an 8/16/24bit bitmap image."
    GOTO ErrorEnd
END IF

IF BitmapBpp <= 8 THEN
    SEEK 1, 55
    FOR Count = 0 TO (2 ^ BitmapBpp) - 1
        GET 1, , ImgPalette(Count)
    NEXT
END IF

ErrorHandled = 0
OPEN DestFile$ FOR OUTPUT AS 2: CLOSE 2
OPEN DestFile$ FOR BINARY AS 2
IF ErrorHandled THEN
    COLOR 12
    PRINT "Error opening destination:"; ErrorHandled
    GOTO ErrorEnd
END IF
ON ERROR GOTO 0


BitmapBytesPerRow = (BitmapWidth * BitmapBpp \ 8 + 3) AND -4
FilePos& = FilePos& + (BitmapHeight - 1) * CLNG(BitmapBytesPerRow) + 1

PixelStrip = STRING$(BitmapBytesPerRow + 1, 0)
IF BitmapBpp = 8 THEN
    'map 8bit to 16bit

    TransColor = 255'for now
    FOR Count = 1 TO BitmapHeight
        GET 1, FilePos&, PixelStrip
        FOR Col = 1 TO BitmapWidth
            Pixel = ASC(MID$(PixelStrip, Col, 1))
            IF Pixel = TransColor THEN
                Pixel = &HFFFF
            ELSE
                'Red = (ImgPalette(Pixel) \ 8) AND &H1F
                'Green = (ImgPalette(Pixel) \ 2048&) AND &H1F&
                'Blue = (ImgPalette(Pixel) \ 524288) AND &H1F&
                PixelL = ImgPalette(Pixel)
                Red = (PixelL AND &HF8) \ 8
                Green = (PixelL AND &HF800&) \ 2048&
                Blue = (PixelL AND &HF80000) \ 524288
                Pixel = Red OR Green * 32 OR Blue * 1024
            END IF
            PUT 2, , Pixel
        NEXT
        
        FilePos& = FilePos& - BitmapBytesPerRow
        LOCATE , 1: PRINT "Writing...   "; NumberStr$(Count * 100& \ BitmapHeight); "%";
    NEXT
ELSEIF BitmapBpp = 16 THEN
    'copy 16bit directly

    FOR Count = 1 TO BitmapHeight
        GET 1, FilePos&, PixelStrip
        PRINT #2, PixelStrip;
        FilePos& = FilePos& - BitmapBytesPerRow
        LOCATE , 1: PRINT "Writing...   "; NumberStr$(Count * 100& \ BitmapHeight); "%";
    NEXT
ELSEIF BitmapBpp = 24 THEN
    'reduce 24bit down to 16bit

    TransColor = 0'for now
    FOR Count = 1 TO BitmapHeight
        GET 1, FilePos&, PixelStrip
        FOR Col = 1 TO BitmapWidth
            PixelL = CVL(MID$(PixelStrip, Col * 3 - 2, 4))
            IF (PixelL AND &HFFFFFF) = TransColor THEN
                Pixel = &HFFFF
            ELSE
                Red = (PixelL AND &HF8) \ 8
                Green = (PixelL AND &HF800&) \ 2048&
                Blue = (PixelL AND &HF80000) \ 524288
                Pixel = Red OR Green * 32 OR Blue * 1024
            END IF
            PUT 2, , Pixel
        NEXT
        FilePos& = FilePos& - BitmapBytesPerRow
        LOCATE , 1: PRINT "Writing...   "; NumberStr$(Count * 100& \ BitmapHeight); "%";
    NEXT
END IF
PRINT
PRINT

ErrorEnd:
CLOSE
END

ErrorHandler:
    ErrorHandled = ERR
RESUME NEXT

FUNCTION NumberStr$ (Number)
    NumberStr$ = LTRIM$(STR$(Number))
END FUNCTION

