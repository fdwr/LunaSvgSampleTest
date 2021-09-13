'2000-05-29
'2001-08-04
'Converts characters from a 256 color bitmap to a 2bit font 32x8
DEFINT A-Z

'CONST CellHeight = 8, CellWidth = 7, CellHeightSep = 9, CellWidthSep = 7
CONST CellHeight = 16, CellWidth = 14, CellHeightSep = 18, CellWidthSep = 14
CONST CellRowBytes = 4, CellBytes = CellHeight * CellRowBytes
CONST CellsPerRow = 16, CellsTotal = 240, PixelCellsSize = CellBytes * CellsPerRow

DIM PixelRow AS STRING, PixelCells AS STRING
DIM CharDataRow AS LONG, BitShift AS LONG
BitmapFile$ = "fnt_larg.bmp"
FontFile$ = "fnt_larg.lbm"

'CLS

IF LEN(COMMAND$) THEN
    BitmapFile$ = COMMAND$ + ".BMP"
    FontFile$ = COMMAND$ + ".LBM"
END IF
OPEN BitmapFile$ FOR INPUT AS 1: CLOSE 1
OPEN BitmapFile$ FOR BINARY AS 1
OPEN FontFile$ FOR OUTPUT AS 2

'SCREEN 13
GET 1, 19, BmpWidth
GET 1, 23, BmpHeight

PixelRow = STRING$(BmpWidth, 0)
PixelCells = STRING$(PixelCellsSize, 0)

FilePos& = CLNG(BmpWidth) * (BmpHeight - 1) + 1079

BmpRows = ((CellsTotal + CellsPerRow - 1) \ CellsPerRow) * CellHeightSep
IF BmpHeight - 1 < BmpRows THEN BmpRows = BmpHeight - 1

CurCell = 0: CellRow = 0
FOR BmpRow = 1 TO BmpRows
    GET 1, FilePos&, PixelRow
    GOSUB ParseCharacterRow
    FilePos& = FilePos& - BmpWidth
NEXT BmpRow

CLOSE 1, 2

PRINT
PRINT "Total of"; CurCell; "characters"

END

ParseCharacterRow:
    IF CellRow >= CellHeight THEN
        CellRow = CellRow + 1
        IF CellRow <= CellHeightSep THEN RETURN
        CellRow = 0
    END IF

    DEF SEG = VARSEG(PixelRow)
    BytePos = SADD(PixelRow)
    Row = BmpRow + 16
    FOR Col = 0 TO BmpWidth - 1
        ByteValue = PEEK(BytePos)
        'PSET (Col, Row), ByteValue
        POKE BytePos, ByteValue
        BytePos = BytePos + 1
    NEXT Col
   
    CharPos = CellRow * CellRowBytes + 1
    BytePos = SADD(PixelRow)
    FOR SubCurCell = 1 TO CellsPerRow
        CharDataRow = 0: BitShift = 1
        FOR SubBytePos = BytePos TO BytePos + CellWidth - 1
            CharDataRow = (PEEK(SubBytePos) * BitShift) OR CharDataRow
            BitShift = BitShift * 4
        NEXT SubBytePos
        MID$(PixelCells, CharPos, 4) = MKL$(CharDataRow)
        BytePos = BytePos + CellWidthSep
        CharPos = CharPos + CellBytes
    NEXT SubCurCell
   
    CellRow = CellRow + 1
    IF CellRow >= CellHeight THEN
        CurCell = CurCell + CellsPerRow
        IF CurCell > CellsTotal THEN
            PRINT #2, MID$(PixelCells, 1, (CellsPerRow - (CurCell - CellsTotal)) * CellBytes);
            CurCell = CellsTotal
        ELSE
            PRINT #2, PixelCells;
        END IF
        PRINT ".";
    END IF
RETURN

