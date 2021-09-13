DEFINT A-Z

DIM SHARED ColorPalette(767)

SCREEN 13

GOSUB RainbowColorSet
FOR Col = 0 TO 255
    LINE (Col, 0)-(Col, 199), Col
NEXT Col
GOSUB PaletteSet

DO: LOOP UNTIL LEN(INKEY$)

WIDTH 80, 25
END

PaletteSet:
    OUT &H3C8, 0
    FOR Index = 0 TO 767 STEP 3
        OUT &H3C9, ColorPalette(Index) \ 4
        OUT &H3C9, ColorPalette(Index + 1) \ 4
        OUT &H3C9, ColorPalette(Index + 2) \ 4
    NEXT Index
RETURN

RainbowColorSet:
    Rcolor = 0: Gcolor = 0: Bcolor = 0
    FOR Index = 0 TO 767 STEP 3
        ColorPalette(Index) = Rcolor * 43'30 + 105
        ColorPalette(Index + 1) = Gcolor * 43'30 + 105
        ColorPalette(Index + 2) = Bcolor * 43'30 + 105
        Bcolor = Bcolor + 1
        IF Bcolor > 5 THEN
            Bcolor = 0: Gcolor = Gcolor + 1
            IF Gcolor > 5 THEN
                Gcolor = 0: Rcolor = Rcolor + 1
                IF Rcolor > 5 THEN Rcolor = 0
            END IF
        END IF
    NEXT Index
RETURN

GrayColorSet:
    Rcolor = 0
    FOR Index = 0 TO 767 STEP 3
        ColorPalette(Index) = Rcolor
        ColorPalette(Index + 1) = Rcolor
        ColorPalette(Index + 2) = Rcolor
        Rcolor = Rcolor + 1
    NEXT Index
RETURN

SaveSnapshot:
    OPEN "snapshot.pcx" FOR OUTPUT AS #3

    DEF SEG = &HA000
    PRINT #3, CHR$(10); CHR$(5); CHR$(1); CHR$(8); MKL$(0); MKI$(319); MKI$(199); MKI$(320); MKI$(200); STRING$(49, 0); CHR$(1); MKI$(320); MKI$(0); STRING$(58, 0);
    BytePos& = 0
    Row = 200
    'DO
    '    Col = 320
    '    FOR Count = 1 TO Col
    '        ByteValue = PEEK(BytePos&)
    '        PRINT #3, "Á"; CHR$(ByteValue);
    '        BytePos& = BytePos& + 1
    '    NEXT Count
    '    Row = Row - 1
    'LOOP WHILE Row
    'GOTO PcxPalette
    DO
        Col = 320
        ByteValue = PEEK(BytePos&)
PcxNewValue:
        RleCount = 1
        LastValue = ByteValue
        BytePos& = BytePos& + 1
        Col = Col - 1
        IF Col <= 0 GOTO PcxRowEnd
PcxSameValue:
        ByteValue = PEEK(BytePos&)
        IF ByteValue = LastValue THEN
            RleCount = RleCount + 1
            BytePos& = BytePos& + 1
            Col = Col - 1
            IF Col > 0 GOTO PcxSameValue
        ELSE
            GOSUB PcxOutputRun
            GOTO PcxNewValue
        END IF
PcxRowEnd:
        GOSUB PcxOutputRun
        Row = Row - 1
    LOOP WHILE Row

PcxPalette: 
    PRINT #3, CHR$(12);
    FOR Index = 0 TO 767
        PRINT #3, CHR$(ColorPalette(Index));
    NEXT

    CLOSE #3
RETURN

PcxOutputRun:
    IF RleCount = 1 THEN
        IF LastValue >= 192 THEN
            PRINT #3, "Á"; CHR$(LastValue);
        ELSE
            PRINT #3, CHR$(LastValue);
        END IF
    ELSE
        DO
            IF RleCount >= 63 THEN
                PRINT #3, "ÿ"; CHR$(LastValue);
            ELSE
                PRINT #3, CHR$(RleCount + 192); CHR$(LastValue);
            END IF
            RleCount = RleCount - 63
        LOOP UNTIL RleCount <= 0
    END IF
RETURN

