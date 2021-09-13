'1999-07-25
'Converts a black&white bitmap into a 1bit linear character set
'Written for TileView
DEFINT A-Z

CONST CellHeight = 8, CellWidth = 8, CellHeightSep = 8, CellWidthSep = 8, CellsPerRow = 16

DIM CharRowPixels AS STRING, CharCellPixels AS STRING
BitmapFile$ = "c:\src\tmv\boldfont.bmp"
FontFile$ = "c:\src\tmv\bold.fnt"

CLS

OPEN BitmapFile$ FOR INPUT AS 1: CLOSE 1
OPEN BitmapFile$ FOR BINARY AS 1
OPEN FontFile$ FOR OUTPUT AS 2

SCREEN 13
GET 1, 19, BmpWidth
GET 1, 23, BmpHeight

CharRowPixels = STRING$(BmpWidth, 0)
CharCellPixels = STRING$(CellHeight * CellsPerRow, 0)

CurChar = 0
CellRow = 1
FilePos& = BmpWidth * (BmpHeight - 1) + 1079
FOR BmpRow = 0 TO BmpHeight - 1
    GET 1, FilePos&, CharRowPixels
    GOSUB ParseCharacterRow
    FilePos& = FilePos& - BmpWidth
NEXT BmpRow

CLOSE 1, 2

PRINT
PRINT "Total of"; CurChar; "characters"

END

ParseCharacterRow:
    DEF SEG = VARSEG(CharRowPixels)
    BytePos = SADD(CharRowPixels)
    CharPos = CellRow
    Row = BmpRow + 16
    FOR Col = 0 TO 127
        PSET (Col, Row), PEEK(BytePos) + 1
        BytePos = BytePos + 1
    NEXT Col
    BytePos = SADD(CharRowPixels)
    FOR CurSubChar = 1 TO CellsPerRow
        ByteValue = 0: BitMask = 1
        FOR CurCharCol = CellWidth - 1 TO 0 STEP -1
            IF PEEK(BytePos + CurCharCol) = 0 THEN ByteValue = ByteValue OR BitMask
            BitMask = BitMask * 2
        NEXT CurCharCol
        MID$(CharCellPixels, CharPos, 1) = CHR$(ByteValue)
        BytePos = BytePos + CellWidthSep
        CharPos = CharPos + CellHeight
    NEXT CurSubChar
    CellRow = CellRow + 1
    IF CellRow > CellHeight THEN
        CellRow = 1
        CurChar = CurChar + CellsPerRow
        PRINT #2, CharCellPixels;
        PRINT ".";
    END IF
RETURN

