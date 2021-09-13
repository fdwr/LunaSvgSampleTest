DEFINT A-Z

SCREEN 13

GOSUB SetGradientPalette
FOR Count = 0 TO 255
    PSET (Count, 190), Count
NEXT Count

ColorStripWrap = 13
Change = 1
DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE "+": ColorStripWrap = ColorStripWrap + 1: Change = 1
    CASE "-": IF ColorStripWrap > 1 THEN ColorStripWrap = ColorStripWrap - 1: Change = 1
    CASE "*": ColorStripWrap = ColorStripWrap + 16: Change = 1
    CASE "/": IF ColorStripWrap > 16 THEN ColorStripWrap = ColorStripWrap - 16: Change = 1
    CASE CHR$(0) + "H": ColorStripWrap = ColorStripWrap * 2: Change = 1
    CASE CHR$(0) + "P": IF ColorStripWrap >= 2 THEN ColorStripWrap = ColorStripWrap \ 2: Change = 1
    CASE CHR$(27): EXIT DO
    END SELECT
    IF Change THEN
        GOSUB ColorStripAnimate
        LOCATE 25, 1: PRINT ColorStripWrap;
        Change = 0
    END IF
LOOP

END

SetGradientPalette:
    OUT &H3C8, 1
    FOR Count = 1 TO 63
        OUT &H3C9, Count
        OUT &H3C9, 0
        OUT &H3C9, 0'(255 - Count) \ 2
    NEXT Count
    FOR Count = 0 TO 63
        OUT &H3C9, 63 - Count
        OUT &H3C9, 0
        OUT &H3C9, Count
    NEXT Count
    FOR Count = 0 TO 63
        OUT &H3C9, 0
        OUT &H3C9, Count
        OUT &H3C9, 63 - Count
    NEXT Count
    FOR Count = 0 TO 63
        OUT &H3C9, Count
        OUT &H3C9, 63 - Count
        OUT &H3C9, 0
    NEXT Count
RETURN

DrawColorStrips:
    HalfColor = INT(ColorStripWrap * .8)
    Count = ColorStripOffset MOD ColorStripWrap
    FOR Row = 0 TO 179
        IF Count > HalfColor THEN PSET (ColorStripOffset, Row), 100 ELSE PSET (ColorStripOffset, Row), 0
        'IF Count AND 8 THEN PSET (ColorStripOffset, Row), 100 ELSE PSET (ColorStripOffset, Row), 0
        'PSET (ColorStripOffset, Row), Count
        'Count = (Count + Row) MOD ColorStripWrap
        'Count = (Count + 2) MOD ColorStripWrap
        Count = (Count + ColorStripOffset) MOD ColorStripWrap
    NEXT Row
RETURN

ColorStripAnimate:
    FOR ColorStripOffset = 255 TO 2 STEP -1
        GOSUB DrawColorStrips
    NEXT ColorStripOffset
RETURN

