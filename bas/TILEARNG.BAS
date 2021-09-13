'Tile Arrange
'Dwayne Robinson
'2001-05-25
'
'Simply rearranges the pixels in a bitmap so that character images, font
'cells, or tile pictures are arranged horizontally instead of vertically.
DEFINT A-Z

TYPE RegType
  Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
  bp AS INTEGER: si AS INTEGER: di AS INTEGER: fl AS INTEGER
  Ds AS INTEGER: es AS INTEGER
END TYPE

CONST BmpChunkSize = 8192

DIM Regs AS RegType, TempRegs AS RegType
DIM SrcPtr AS LONG, DestPtr AS LONG, SrcRowPtr AS LONG
DIM SrcFile AS STRING, DestFile AS STRING

REDIM SrcImg(16383) AS LONG, DestImg(16383) AS LONG
DIM ImgPalette(255) AS LONG

SrcFile = "c:\emu\z64font.bin"
DestFile = "c:\emu\z64font.bmp"
SrcOffset = 128 * 206 + 64
PixelBits = 4
TileWidth = 16
TileHeight = 16
TileCols = 20
TileRows = 12
UsedColors = 16
ImportantColors = UsedColors

SrcSeg = VARSEG(SrcImg(0))
DestSeg = VARSEG(DestImg(0))

SCREEN 13

GOSUB SetGrayPalette
GOSUB ReadSrcFile
GOSUB ChangeVertToHorz

DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)

IF Key$ = "W" THEN GOSUB ExportBitmap

END

ChangeVertToHorz:
    PRINT "Converting vertical to horizontal"
    ImgRows = TileRows * TileHeight
    TileColBytes = (TileWidth * PixelBits + 7) \ 8
    ImgCols = TileCols * TileColBytes
    SrcColInc = (TileHeight - 1) * TileColBytes
    SrcRowInc = TileHeight * ImgCols' - SrcColInc

    SrcPtr = 0
    DestPtr = 0
    SrcRowPtr = VARPTR(SrcImg(0)) + SrcOffset
    RowCount = TileHeight
    FOR Row = 0 TO ImgRows - 1
        ColCount = TileColBytes
        SrcPtr = SrcRowPtr
        FOR Col = 0 TO ImgCols - 1
            DEF SEG = SrcSeg:  Byte = PEEK(SrcPtr)
            'DEF SEG = DestSeg: POKE DestPtr, Byte
            DEF SEG = &HA000: POKE DestPtr, Byte \ 16
            POKE DestPtr + 1, Byte AND 15
            SrcPtr = SrcPtr + 1
            DestPtr = DestPtr + 2
            ColCount = ColCount - 1
            IF ColCount <= 0 THEN SrcPtr = SrcPtr + SrcColInc: ColCount = TileColBytes
        NEXT
        SrcRowPtr = SrcRowPtr + TileColBytes
        RowCount = RowCount - 1
        IF RowCount <= 0 THEN SrcRowPtr = SrcRowPtr + SrcRowInc: RowCount = TileHeight
    NEXT
RETURN

ChangeHorzToVert:
RETURN

SetGrayPalette:
    ImgPalette(0) = 0
    Value& = 2039583
    FOR Count = 1 TO 15
        ImgPalette(Count) = Value&
        Value& = Value& + 1052688
    NEXT
'RETURN

SetPalette:
    DEF SEG = VARSEG(ImgPalette(0))
    SrcPtr = VARPTR(ImgPalette(0))
    OUT &H3C8, 0
    FOR Count = 0 TO UsedColors - 1
        OUT &H3C9, PEEK(SrcPtr + 2) \ 4
        OUT &H3C9, PEEK(SrcPtr + 1) \ 4
        OUT &H3C9, PEEK(SrcPtr) \ 4
        SrcPtr = SrcPtr + 4
    NEXT
RETURN

ReadSrcFile:
    OPEN SrcFile FOR INPUT AS 1: CLOSE 1
    OPEN SrcFile FOR BINARY AS 1
    GOSUB ReadRawData
    CLOSE 1
RETURN

ReadRawData:
    PRINT "Reading source file"
    SEEK 1, 1
    Regs.Ax = &H3F00 'DOS: Read file
    Regs.Bx = FILEATTR(1, 2)
    Regs.Cx = -32768
    Regs.Ds = SrcSeg
    Regs.Dx = VARPTR(SrcImg(0))
    CALL interruptx(&H21, Regs, TempRegs) 'read first 32k VRAM
    Regs.Dx = VARPTR(SrcImg(8192))
    CALL interruptx(&H21, Regs, TempRegs) 'read second 32k
RETURN

ExportBitmap:
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
  
    OPEN DestFile FOR OUTPUT AS 1
   
    PRINT #1, "BM"; MKL$((54 + 1024 + 64000) \ 4); MKL$(0); MKL$(54 + 1024);
    PRINT #1, MKL$(40); MKL$(320); MKL$(200); MKL$(&H80001); MKL$(0);
    PRINT #1, MKL$(320& * 200); MKL$(0); MKL$(0); MKL$(UsedColors); MKL$(ImportantColors);

    FileBuffer$ = STRING$(1024, 0)
    FOR Count = 0 TO 255
        MID$(FileBuffer$, Count * 4 + 1, 4) = MKL$(ImgPalette(Count))
    NEXT
    PRINT #1, FileBuffer$;
    FileBuffer$ = ""

    Regs.Ax = &H4000
    Regs.Bx = FILEATTR(1, 2)
    Regs.Cx = BmpChunkSize
    Regs.Ds = &HA000
    SEEK 1, 1079

    DEF SEG = &HA000
    FOR SrcPtr = 0 TO 63999 STEP BmpChunkSize
        IF SrcPtr < 32768 THEN Regs.Dx = SrcPtr ELSE Regs.Dx = SrcPtr - 65536
        CALL interruptx(&H21, Regs, TempRegs)
    NEXT
 
    'FileBuffer$ = SPACE$(BmpBufferSize)
    'SEEK 1, Filepos&
    'DEF SEG = &HA000
    'FOR SrcPtr = 0 TO 63999 STEP BmpBufferSize
    '    FOR CharPos = 1 TO BmpBufferSize
    '        MID$(FileBuffer$, CharPos, 1) = CHR$(PEEK(SrcPtr + CharPos - 1))
    '    NEXT
    '    PRINT #1, FileBuffer$;
    'NEXT

    CLOSE 1
RETURN

