'1999.6.10 Peekin
DEFINT A-Z

CONST BlockHeight = 12, BlockWidth = 20
DIM ColorPalette(0 TO 255) AS LONG

SCREEN 13

PALETTE

DEF SEG = VARSEG(ColorPalette(0))
BytePos = 0'VARPTR(ColorPalette(0))
OUT &H3C7, 0                            'start with black (color index 0)
FOR Count = 0 TO 15
    POKE BytePos, INP(&H3C9)
    POKE BytePos + 1, INP(&H3C9)
    POKE BytePos + 2, INP(&H3C9)
    BytePos = BytePos + 4
NEXT Count

'FOR Count = 0 TO 16
'    RgbTuple$ = "000000"
'    MID$(RgbTuple$, 1, 6) = HEX$(ColorPalette(Count))
'    COLOR Count
'    PRINT RgbTuple$; " ";
'NEXT Count

FOR Row = 0 TO 15 * BlockHeight STEP BlockHeight
    FOR Col = 0 TO 15 * BlockWidth STEP BlockWidth
        LINE (Col, Row)-(Col + BlockWidth - 1, Row + BlockHeight - 1), PaletteColor, BF
        PaletteColor = PaletteColor + 1
    NEXT Col
NEXT Row

Index = 16: ColorCount = 16
FOR ColorRow = 0 TO 14
    READ RedValue, GreenValue, BlueValue, RedInc, GreenInc, BlueInc
    GOSUB AddColors
NEXT ColorRow

GOSUB SetPalette
DO
    SELECT CASE INKEY$
    CASE CHR$(0) + "K": NewColor = CurColor - 1: GOSUB ChangeCurColor
    CASE CHR$(0) + "M": NewColor = CurColor + 1: GOSUB ChangeCurColor
    CASE CHR$(0) + "H": NewColor = CurColor - 16: GOSUB ChangeCurColor
    CASE CHR$(0) + "P": NewColor = CurColor + 16: GOSUB ChangeCurColor
    CASE " ": GOSUB SetPalette
    CASE CHR$(13)
        OPEN "rainbow.pal" FOR OUTPUT AS #1
        RgbTuple$ = "RGB"
        FOR Count = 0 TO 255
            MID$(RgbTuple$, 1, 3) = MKL$(ColorPalette(Count))
            PRINT #1, RgbTuple$;
        NEXT Count
        CLOSE #1
    CASE CHR$(27): EXIT DO
    END SELECT
LOOP

END

ChangeCurColor:
    DrawColorCursor = 0
    GOSUB DrawColorBlock
    CurColor = NewColor AND 255
    DrawColorCursor = 1
    GOSUB DrawColorBlock
    LOCATE 25, 1: PRINT CurColor; TAB(10); RIGHT$("00000" + HEX$(ColorPalette(CurColor)), 6);
RETURN

'(CurColor)
DrawColorBlock:
    LeftCol = (CurColor AND 15) * BlockWidth
    TopRow = (CurColor \ 16) * BlockHeight
    IF DrawColorCursor THEN
        LINE (LeftCol, TopRow)-(LeftCol + BlockWidth - 1, TopRow + BlockHeight - 1), CurColor XOR 128, B
    ELSE
        LINE (LeftCol, TopRow)-(LeftCol + BlockWidth - 1, TopRow + BlockHeight - 1), CurColor, BF
    END IF
RETURN

'(Index,Count,RedValue,GreenValue,BlueValue,RedInc,GreenInc,BlueInc)
AddColors:
    IF Count < 0 THEN RETURN
    LastCount = Index + ColorCount - 1
    IF LastCount > 255 THEN LastCount = 255
    BytePos = Index * 4'+VARPTR(ColorPalette(0))
    FOR Count = Index TO LastCount
        POKE BytePos, RedValue' \ 10
        POKE BytePos + 1, GreenValue' \ 10
        POKE BytePos + 2, BlueValue' \ 10
        RedValue = RedValue + RedInc
        GreenValue = GreenValue + GreenInc
        BlueValue = BlueValue + BlueInc
        BytePos = BytePos + 4
    NEXT Count
    Index = LastCount + 1
RETURN

SetPalette:
    OUT &H3C8, 0
    BytePos = 0'VARPTR(ColorPalette(0))
    FOR Count = 0 TO 255
        OUT &H3C9, PEEK(BytePos)
        OUT &H3C9, PEEK(BytePos + 1)
        OUT &H3C9, PEEK(BytePos + 2)
        BytePos = BytePos + 4
    NEXT Count
RETURN

DATA 0,0,32,0,0,2
DATA 24,0,32,2,0,2
DATA 32,0,32,2,0,2
DATA 32,0,24,2,0,2
DATA 32,0,18,2,0,2
DATA 32,0,0,2,0,0
DATA 32,18,0,2,2,0
DATA 32,24,0,2,2,0
DATA 32,32,0,2,2,0
DATA 24,32,0,2,2,0
DATA 0,32,0,0,2,0
DATA 0,32,24,0,2,2
DATA 0,32,32,0,2,2
DATA 0,24,32,0,2,2
DATA 0,18,32,0,2,2

DATA 0,0,63,0,0,-1
DATA 56,0,63,-1,0,-1
DATA 63,0,63,-1,0,-1
DATA 63,0,47,-1,0,-1
DATA 63,0,32,-1,0,-1
DATA 63,0,0,-1,0,0
DATA 63,50,0,-1,-1,0
DATA 63,56,0,-1,-1,0
DATA 63,63,0,-1,-1,0
DATA 56,63,0,-1,-1,0
DATA 0,63,0,0,-1,0
DATA 0,63,47,0,-1,-1
DATA 0,63,63,0,-1,-1
DATA 0,56,63,0,-1,-1
DATA 0,47,63,0,-1,-1

'263600 light aqua green
'373000 soft blue

