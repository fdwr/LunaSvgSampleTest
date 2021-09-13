'Gamma Curve Adjuster
'2000-09-20 Peekin
'
'Tests for uneven "gamma" curves on monitors, a problem which mine definitely
'suffers. A midtone gray should, technically, be equal the same brightness
'as a hash pattern of the pure black and the brightest white. Instead of being
'linear though, mine has a very distorted curve.
'
'.10.5 Added interpolation, clearing, saving palette, reloading,
'      palette setting, better hash patterns, increased MaxColors
'
DEFINT A-Z
DECLARE FUNCTION GetBinNum& (Num AS STRING)

CONST MaxColors = 64
DIM ColorPalette(MaxColors - 1) AS LONG

SCREEN 13

ValueInc& = &H40404
ColorAtr = 3
SelectedColor = 10
GOSUB CreateGradient
GOSUB ChangeColorAtr
GOSUB DisplayHash

Change = 11
DO
    Key$ = INKEY$
    IF LEN(Key$) THEN
        SELECT CASE Key$
        CASE CHR$(0) + "H": ColorValue = 1: GOSUB ChangeColorValue
        CASE CHR$(0) + "P": ColorValue = -1: GOSUB ChangeColorValue
        CASE CHR$(0) + "I": ColorValue = 8: GOSUB ChangeColorValue
        CASE CHR$(0) + "Q": ColorValue = -8: GOSUB ChangeColorValue
        CASE CHR$(0) + "K": NewSelectedColor = (SelectedColor + MaxColors - 1) MOD MaxColors: GOSUB ChangeSelectedColor
        CASE CHR$(0) + "M": NewSelectedColor = (SelectedColor + 1) MOD MaxColors: GOSUB ChangeSelectedColor
        CASE CHR$(0) + "s": ColorAtr = (ColorAtr + 3) MOD 4: GOSUB ChangeColorAtr
        CASE CHR$(0) + "t": ColorAtr = (ColorAtr + 1) MOD 4: GOSUB ChangeColorAtr
        CASE CHR$(0) + "G"
            IF ColorAtr >= 3 THEN ColorPalette(SelectedColor) = 0 ELSE ColorPalette(SelectedColor) = ColorPalette(SelectedColor) AND NOT (63 * ColorAtrMultiple&)
            Change = Change OR 4
        CASE CHR$(0) + "O"
            IF ColorAtr >= 3 THEN ColorPalette(SelectedColor) = 63 ELSE ColorPalette(SelectedColor) = ColorPalette(SelectedColor) OR (63 * ColorAtrMultiple&)
            Change = Change OR 4
        CASE "g": GOSUB CreateGradient: GOSUB SetPalette: Change = Change OR 1
        CASE "i": GOSUB InterpolateColors: Change = Change OR 1
        CASE "c": GOSUB ClearColors: Change = Change OR 1
        CASE "S": GOSUB OutputGammaTable
        CASE "L": GOSUB InputGammaTable
        CASE "r"
            IF Mask2 AND 1 THEN Mask2 = (Mask2 AND 65534) \ 2 OR -32768 ELSE Mask2 = (Mask2 AND 65534) \ 2
            GOSUB ReDisplayHash
        CASE "0" TO "9"
            IF ColorAtr < 3 THEN
                'ColorPalette(SelectedColor) OR (63 * ColorAtrMultiple&)

            END IF
        CASE CHR$(27): EXIT DO
        END SELECT
    ELSEIF Change THEN
        IF Change AND 8 THEN
            Col = 0
            FOR Count = 0 TO MaxColors - 1
                LINE (Col, 0)-(Col + 3, 11), Count + 16, BF
                Col = Col + 4
            NEXT
            FOR Count = 0 TO MaxColors - 1
                LINE (260, Count)-(319, Count), Count + 16
            NEXT
            FOR Count = 0 TO MaxColors - 1
                ColorValue = Count + 16
                ColorValue2 = 79 - Count
                PSET (Count + 256, 65), ColorValue
                PSET (Count + 256, 66), ColorValue2
                PSET (Count + 256, 67), ColorValue
                PSET (Count + 256, 68), ColorValue2
                PSET (Count + 256, 69), ColorValue
                PSET (Count + 256, 70), ColorValue2
                PSET (Count + 256, 71), ColorValue
                PSET (Count + 256, 72), ColorValue2
                PSET (Count + 256, 73), ColorValue
                PSET (Count + 256, 74), ColorValue2
                PSET (Count + 256, 75), ColorValue
                PSET (Count + 256, 76), ColorValue2
                PSET (Count + 256, 77), ColorValue
                PSET (Count + 256, 78), ColorValue2
                PSET (Count + 256, 79), ColorValue
                PSET (Count + 256, 80), ColorValue2
            NEXT
        END IF
        IF Change AND 2 THEN
            Col = OldSelectedColor * 4
            LINE (Col, 0)-(Col + 3, 0), OldSelectedColor + 16, B
            Col = SelectedColor * 4
            LINE (Col, 0)-(Col + 3, 0), 15, B
            OldSelectedColor = SelectedColor
            GOSUB DisplayHash
        END IF
        IF Change AND 4 THEN
            PALETTE SelectedColor + 16, ColorPalette(SelectedColor) AND NOT ColorMask&
            'OUT &H3C8, SelectedColor + 16
            'DEF SEG = VARSEG(ColorPalette(0))
            'BytePos = VARPTR(ColorPalette(0)) + SelectedColor * 4
            'OUT &H3C9, PEEK(BytePos)
            'OUT &H3C9, PEEK(BytePos + 1)
            'OUT &H3C9, PEEK(BytePos + 1)
        END IF
        IF Change AND 7 THEN
            Value& = ColorPalette(SelectedColor)
            COLOR 15
            LOCATE 3, 1: PRINT MID$("Red  GreenBlue All  ", ColorAtr * 5 + 1, 5);
            LOCATE 4, 1: PRINT SelectedColor; "="; TAB(6);
            COLOR 12: PRINT STR$(Value& AND 255);
            COLOR 10: PRINT STR$((Value& AND 65280) \ 256);
            COLOR 9: PRINT STR$((Value& AND 16711680) \ 65536); SPC(5);
        END IF
        Change = 0
    END IF
LOOP

WIDTH 80, 25
END

ChangeSelectedColor:
    IF (Change AND 1) = 0 THEN Change = Change OR 2
    SelectedColor = NewSelectedColor
RETURN

ChangeColorValue:
    ColorValue = ColorValue AND 63
    IF ColorAtr >= 3 THEN
        ColorPalette(SelectedColor) = (ColorPalette(SelectedColor) + ColorValue + ColorValue * 256 + ColorValue * 65536) AND 4144959
    ELSE
        ColorPalette(SelectedColor) = (ColorPalette(SelectedColor) + ColorValue * ColorAtrMultiple&) AND 4144959
    END IF
    Change = Change OR 4
RETURN

ChangeColorAtr:
    IF ColorAtr < 3 THEN ColorAtrMultiple& = 2 ^ (ColorAtr * 8)
    SELECT CASE ColorAtr
    CASE 0: ColorMask& = &HFFFF00
    CASE 1: ColorMask& = &HFF00FF
    CASE 2: ColorMask& = &HFFFF&
    CASE ELSE: ColorMask& = 0
    END SELECT
    Change = Change OR 1
GOTO SetPalette
'RETURN

DisplayHash:
    LINE (0, 34)-(255, 116), SelectedColor + 16, BF
    SELECT CASE SelectedColor \ 4
    CASE 0: Mask1 = &H0: Mask2 = &H0
    CASE 1: Mask1 = &H8000: Mask2 = &H80
    CASE 2: Mask1 = &H8080: Mask2 = &H808
    CASE 3: Mask1 = &H8420: Mask2 = &H2084
    CASE 4: Mask1 = &H1111: Mask2 = &H4444
    CASE 5: Mask1 = &H1249: Mask2 = &H4912
    CASE 6: Mask1 = &H9494: Mask2 = &H4949
    CASE 7: Mask1 = &HA54A: Mask2 = &H4AA5
    CASE 8: Mask1 = &H5555: Mask2 = &HAAAA
    CASE 9: Mask1 = &HAB56: Mask2 = &H56AB
    CASE 10: Mask1 = &HB6B6: Mask2 = &H6B6B
    CASE 11: Mask1 = &HB76D: Mask2 = &H6DB7
    CASE 12: Mask1 = &HEEEE: Mask2 = &HBBBB
    CASE 13: Mask1 = &HBDF7: Mask2 = &HF7BD
    CASE 14: Mask1 = &HFEFE: Mask2 = &HEFEF
    CASE 15: Mask1 = &HFFFF: Mask2 = &HFFFF
    END SELECT

ReDisplayHash:
    FOR Count = 117 TO 199 STEP 2
        LINE (0, Count)-(255, Count + 1), 0, BF
        LINE (0, Count)-(255, Count), 79, , Mask1
        LINE (0, Count + 1)-(255, Count + 1), 79, , Mask2
    NEXT
    'LOCATE 6, 1: COLOR 15: PRINT HEX$(Mask1); ","; HEX$(Mask2);
RETURN

ClearColors:
    FOR Count = 0 TO MaxColors - 1
        ColorPalette(Count) = 0
    NEXT
    GOSUB SetPalette
RETURN

CreateGradient:
    SELECT CASE ColorAtr
    CASE 0: ValueInc& = 1
    CASE 1: ValueInc& = &H100
    CASE 2: ValueInc& = &H10000
    CASE ELSE: ValueInc& = &H10101
    END SELECT
    Value& = 0
CreateGradientSpecial:
    FOR Count = 0 TO MaxColors - 1
        ColorPalette(Count) = (ColorPalette(Count) AND ColorMask&) OR Value&
        Value& = Value& + ValueInc&
    NEXT
RETURN

InterpolateColors:
    DEF SEG = VARSEG(ColorPalette(0))
    BytePos = VARPTR(ColorPalette(0))
    Red = 0: Grn = 0: Blu = 0: ColorDistance = 1
    RedDif = 0: GrnDif = 0: BluDif = 0

    FOR Count = 0 TO MaxColors - 1
        Value& = ColorPalette(Count)
        IF Value& > 0 OR Count = 0 THEN
            Red = PEEK(BytePos)
            Grn = PEEK(BytePos + 1)
            Blu = PEEK(BytePos + 2)
            FOR SubCount = Count + 1 TO MaxColors - 1
                IF ColorPalette(SubCount) THEN EXIT FOR
            NEXT
            IF SubCount < MaxColors THEN
                ColorDistance = SubCount - Count 'get relative distance
                BytePos = BytePos + ColorDistance * 4
                RedDif = PEEK(BytePos) - Red
                GrnDif = PEEK(BytePos + 1) - Grn
                BluDif = PEEK(BytePos + 2) - Blu
                BytePos = VARPTR(ColorPalette(0)) + Count * 4
                SubCount = 1
            ELSE
                RedDif = 0: GrnDif = 0: BluDif = 0
            END IF
        ELSE
            POKE BytePos, (RedDif * SubCount) \ ColorDistance + Red
            POKE BytePos + 1, (GrnDif * SubCount) \ ColorDistance + Grn
            POKE BytePos + 2, (BluDif * SubCount) \ ColorDistance + Blu
            SubCount = SubCount + 1
        END IF
        BytePos = BytePos + 4
    NEXT
    GOSUB SetPalette
RETURN

SetPalette:
    OUT &H3C8, 16
    DEF SEG = VARSEG(Value&)
    BytePos = VARPTR(Value&)

    FOR Count = 0 TO MaxColors - 1
        Value& = ColorPalette(Count) AND NOT ColorMask&
        OUT &H3C9, PEEK(BytePos)
        OUT &H3C9, PEEK(BytePos + 1)
        OUT &H3C9, PEEK(BytePos + 2)
    NEXT
RETURN

OutputGammaTable:
    OPEN "gamma.dat" FOR OUTPUT AS 1
    DEF SEG = VARSEG(ColorPalette(0))
    FOR ColorValue = 0 TO 2
        BytePos = VARPTR(ColorPalette(0)) + ColorValue
        FOR Count = 0 TO MaxColors - 1
            PRINT #1, CHR$(PEEK(BytePos));
            BytePos = BytePos + 4
        NEXT
    NEXT
    CLOSE 1
RETURN

InputGammaTable:
    OPEN "gamma.dat" FOR BINARY AS 1
    DEF SEG = VARSEG(ColorPalette(0))
    CharValue$ = " "
    FOR ColorValue = 0 TO 2
        BytePos = VARPTR(ColorPalette(0)) + ColorValue
        FOR Count = 0 TO MaxColors - 1
            GET 1, , CharValue$
            POKE BytePos, ASC(CharValue$)
            BytePos = BytePos + 4
        NEXT
    NEXT
    CLOSE 1
    GOSUB SetPalette
RETURN

FUNCTION GetBinNum& (Num AS STRING)
DIM Result AS LONG

FOR Count = 1 TO LEN(Num)
    Result = Result * 2
    IF MID$(Num, Count, 1) = "1" THEN Result = Result + 1
NEXT

GetBinNum = Result

END FUNCTION

