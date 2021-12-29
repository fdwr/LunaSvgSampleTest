'Spc2Midi Gui Colors
'1999-06-10 Peekin
'
'Generates, displays, and writes the rainbow GUI palette for Spc2Midi.
DEFINT A-Z

CONST BlockHeight = 12, BlockWidth = 20
DIM ColorPalette(0 TO 255) AS LONG
DIM RgbTuple AS STRING * 4'3

DEF SEG = 0
ShiftKey = PEEK(1047) AND 3
IF ShiftKey = 0 THEN
    SCREEN 13
    PALETTE
END IF

DEF SEG = VARSEG(ColorPalette(0))
BytePos = VARPTR(ColorPalette(0))
'OUT &H3C7, 0                            'start with black (color index 0)
'FOR Count = 0 TO 15
'    POKE BytePos, INP(&H3C9)
'    POKE BytePos + 1, INP(&H3C9)
'    POKE BytePos + 2, INP(&H3C9)
'    BytePos = BytePos + 4
'NEXT Count
'
'FOR Count = 0 TO 16
'    RgbTuple$ = "000000"
'    MID$(RgbTuple$, 1, 6) = HEX$(ColorPalette(Count))
'    COLOR Count
'    PRINT RgbTuple$; " ";
'NEXT Count

'DEF SEG = VARSEG(ColorPalette(0))
BytePos = VARPTR(ColorPalette(0))
FOR Index = 0 TO 15
    READ RedValue, GreenValue, BlueValue
    POKE BytePos, RedValue
    POKE BytePos + 1, GreenValue
    POKE BytePos + 2, BlueValue
    BytePos = BytePos + 4
NEXT Index
'Index is 16
ColorCount = 15
FOR ColorRow = 0 TO 15
    'READ RedValue, GreenValue, BlueValue, RedInc, GreenInc, BlueInc
    READ RedStart, GreenStart, BlueStart, RedEnd, GreenEnd, BlueEnd
    GOSUB AddColors
NEXT ColorRow

IF ShiftKey THEN
    GOSUB ExportPalette
    END
END IF

FOR Row = 0 TO 15 * BlockHeight STEP BlockHeight
    FOR Col = 0 TO 15 * BlockWidth STEP BlockWidth
        LINE (Col, Row)-(Col + BlockWidth - 1, Row + BlockHeight - 1), PaletteColor, BF
        PaletteColor = PaletteColor + 1
    NEXT Col
NEXT Row
DrawColorCursor = 1
GOSUB DrawColorBlock


GOSUB SetPalette
DO
    SELECT CASE INKEY$
    CASE CHR$(0) + "K": NewColor = CurColor - 1: GOSUB ChangeCurColor
    CASE CHR$(0) + "M": NewColor = CurColor + 1: GOSUB ChangeCurColor
    CASE CHR$(0) + "H": NewColor = CurColor - 16: GOSUB ChangeCurColor
    CASE CHR$(0) + "P": NewColor = CurColor + 16: GOSUB ChangeCurColor
    CASE " ": GOSUB SetPalette
    CASE "W": GOSUB ExportPalette
    CASE CHR$(27): EXIT DO
    END SELECT
LOOP

END

ExportPalette:
    OPEN "RAINBOW.PAL" FOR OUTPUT AS #1
    FOR Count = 0 TO 255
        RgbTuple = MKL$(ColorPalette(Count) * 4 AND &HFCFCFC)
        PRINT #1, RgbTuple;
    NEXT Count
    PRINT "Colors exported"
    CLOSE #1
RETURN

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
        LINE (LeftCol, TopRow)-(LeftCol + BlockWidth - 1, TopRow + BlockHeight - 1), 15, B
    ELSE
        LINE (LeftCol, TopRow)-(LeftCol + BlockWidth - 1, TopRow + BlockHeight - 1), CurColor, BF
    END IF
RETURN

'(Index,ColorCount,RedStart,GreenStart,BlueStart,RedEnd,GreenEnd,BlueEnd)
AddColors:
    'DEF SEG = VARSEG(ColorPalette(0))
    LastCount = Index + ColorCount - 1
    IF LastCount > 255 THEN LastCount = 255
    BytePos = Index * 4 + VARPTR(ColorPalette(0))
    RedValue = 0: GreenValue = 0: BlueValue = 0
    IF ColorCount > 1 THEN
        RedInc = ((RedEnd - RedStart) * 256) \ (ColorCount - 1)
        GreenInc = ((GreenEnd - GreenStart) * 256) \ (ColorCount - 1)
        BlueInc = ((BlueEnd - BlueStart) * 256) \ (ColorCount - 1)
    END IF
    FOR Index = Index TO LastCount
        POKE BytePos, RedStart + RedValue \ 256
        POKE BytePos + 1, GreenStart + GreenValue \ 256
        POKE BytePos + 2, BlueStart + BlueValue \ 256
        RedValue = RedValue + RedInc
        GreenValue = GreenValue + GreenInc
        BlueValue = BlueValue + BlueInc
        BytePos = BytePos + 4
    NEXT
RETURN

SetPalette:
    'DEF SEG = VARSEG(ColorPalette(0))
    OUT &H3C8, 0
    BytePos = 0'VARPTR(ColorPalette(0))
    FOR Count = 0 TO 255
        OUT &H3C9, PEEK(BytePos)
        OUT &H3C9, PEEK(BytePos + 1)
        OUT &H3C9, PEEK(BytePos + 2)
        BytePos = BytePos + 4
    NEXT Count
RETURN

'Gui Colors
DATA 0,0,0,   24,20,26, 30,26,32, 41,38,44, 50,45,53, 63,63,63
DATA 40,0,40, 60,0,60,  0,0,40,   0,0,58,   0,40,0,   0,60,0
DATA 40,40,0, 63,60,0,  40,0,0,   63,0,64

'Rainbow colors
 DATA 0,0,24, 0,0,63
DATA  0,20,24,0,46,63
DATA  0,24,24,0,63,63
DATA  0,24,20,0,63,46
 DATA 0,24,0, 0,63,0
DATA  20,24,0,52,63,0
DATA  24,24,0,63,63,0
DATA  24,22,0,63,56,0
DATA  24,20,0,63,46,0
DATA  24,18,0,63,34,0
 DATA 24,0,0, 63,0,0
DATA  24,0,10,63,0,34
DATA  24,0,20,63,0,52
DATA  24,0,24,63,0,63
DATA  20,0,24,52,0,63
DATA  18,0,24,46,0,63

'Old Brigher Colors
 DATA 0,0,32,0,0,60
DATA  0,22,32,0,50,60
DATA  0,32,32,0,60,60
DATA  0,32,24,0,60,52
 DATA 0,32,0,0,60,0
DATA  24,32,0,52,60,0
DATA  32,32,0,60,60,0
DATA  32,28,0,60,56,0
DATA  32,24,0,60,52,0
DATA  32,18,0,60,46,0
 DATA 32,0,0,60,0,0
DATA  32,0,10,60,0,38
DATA  32,0,24,60,0,52
DATA  32,0,32,60,0,60
DATA  24,0,32,52,0,60
DATA  18,0,32,46,0,60

'263600 light aqua green
'373000 soft blue

