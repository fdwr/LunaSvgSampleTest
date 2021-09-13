'Palette Editor
'2001-01-17
DEFINT A-Z
DECLARE FUNCTION ConfirmKeypress% (Text AS STRING, DesiredKey AS STRING)

DIM ColorPalette(383)

DEF SEG = VARSEG(ColorPalette(0))
ColorPaletteAdr& = VARPTR(ColorPalette(0))

SCREEN 13
COLOR 255
PalFile$ = COMMAND$
GOSUB LoadPalette
IF ErrHandled THEN
    PalFile$ = "palset.pal"
    GOSUB GetPalette
    GOSUB SetPaletteHighClr
ELSE
    GOSUB SetPalette
END IF

FOR Count = 0 TO 255
    LINE (Count, 16)-(Count, 32), Count
NEXT
LOCATE 6, 1
PRINT "Left/right to select color"
PRINT "Ctrl+Left/right to select color by 16"
PRINT "Up/Down to adjust color"
PRINT
PRINT "PgUp/PgDown to adjust color by 16"
PRINT "Home/End for full or no color"
PRINT
PRINT "1 adjust red only"
PRINT "2 adjust green"
PRINT "3 adjust blue"
PRINT "4 adjust all"
PRINT
PRINT "L Reload palette"
PRINT "S Save palette"

SelectedColor = 1
OldSelectedColor = SelectedColor
SelectedColorMask = 7
Redraw = -1
DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE CHR$(0) + "K": NewValue = -1: GOSUB ChangeSelectedColor
    CASE CHR$(0) + "M": NewValue = 1: GOSUB ChangeSelectedColor
    CASE CHR$(0) + "s": NewValue = -16: GOSUB ChangeSelectedColor
    CASE CHR$(0) + "t": NewValue = 16: GOSUB ChangeSelectedColor
    CASE CHR$(0) + "H": NewValue = 1: GOSUB AdjustColorEntry
    CASE CHR$(0) + "P": NewValue = -1: GOSUB AdjustColorEntry
    CASE CHR$(0) + "G": NewValue = 0: GOSUB SetColorEntry
    CASE CHR$(0) + "O": NewValue = 63: GOSUB SetColorEntry
    CASE CHR$(0) + "Q": NewValue = -16: GOSUB AdjustColorEntry
    CASE CHR$(0) + "I": NewValue = 16: GOSUB AdjustColorEntry
    CASE "1": SelectedColorMask = 1: Redraw = Redraw OR 2
    CASE "2": SelectedColorMask = 2: Redraw = Redraw OR 2
    CASE "3": SelectedColorMask = 4: Redraw = Redraw OR 2
    CASE "4": SelectedColorMask = 7: Redraw = Redraw OR 2
    CASE "l"
        IF ConfirmKeypress("Press 'l' again to reload", "l") THEN
            GOSUB LoadPalette
            IF ErrHandled = 0 THEN GOSUB SetPalette
        END IF
    CASE "s"
        IF ConfirmKeypress("Press 's' again to save", "s") THEN GOSUB SavePalette
    CASE "w"
        IF ConfirmKeypress("Press 'w' again to write bitmap", "w") THEN GOSUB WriteBitmap
    CASE CHR$(27): EXIT DO
    CASE ELSE
        IF Redraw THEN
            IF Redraw AND 1 THEN
                'top, bottom, and middle
                LINE (0, 13)-(255, 15), SelectedColor, BF
                LINE (0, 33)-(255, 35), SelectedColor, BF
                LINE (OldSelectedColor, 16)-(OldSelectedColor, 32), OldSelectedColor
                'erasure
                LINE (0, 12)-(255, 12), 0
                LINE (0, 36)-(255, 36), 0
                'inidicator
                LINE (SelectedColor, 12)-(SelectedColor, 16), 255
                LINE (SelectedColor, 32)-(SelectedColor, 36), 255
                OldSelectedColor = SelectedColor
            END IF
            IF Redraw AND 2 THEN
                Adr& = ColorPaletteAdr& + SelectedColor * 3
                LOCATE 1, 1
                PRINT "Color:"; SelectedColor; TAB(12);
                ColorMask = 1
                FOR Count = 1 TO 3
                    IF SelectedColorMask AND ColorMask THEN PRINT MID$("RGB", Count, 1);
                    ColorMask = ColorMask * 2
                NEXT
                PRINT STR$(PEEK(Adr&)); STR$(PEEK(Adr& + 1)); STR$(PEEK(Adr& + 2)); TAB(27);
            END IF
            Redraw = 0
        END IF
    END SELECT
LOOP

END

LoadPalette:
    GOSUB CatchErr
    OPEN PalFile$ FOR INPUT AS 1: CLOSE 1
    ON ERROR GOTO 0
    IF ErrHandled THEN RETURN
    OPEN PalFile$ FOR BINARY AS 1
    FOR Count = 0 TO UBOUND(ColorPalette)
        GET 1, , ColorPalette(Count)
    NEXT
    CLOSE 1
RETURN

SavePalette:
    GOSUB CatchErr
    OPEN PalFile$ FOR OUTPUT AS 1: CLOSE 1
    ON ERROR GOTO 0
    IF ErrHandled THEN RETURN
    OPEN PalFile$ FOR BINARY AS 1
    FOR Count = 0 TO UBOUND(ColorPalette)
        PUT 1, , ColorPalette(Count)
    NEXT
    CLOSE 1
RETURN

WriteBitmap:
    CONST ImportantColors = 256

    GOSUB CatchErr
    OPEN "paledit.bmp" FOR OUTPUT AS #1
    ON ERROR GOTO 0

    PRINT #1, "BM"; MKL$((54 + 1024 + (ImportantColors * 4)) \ 4); MKL$(0); MKL$(54 + (ImportantColors * 4));
    PRINT #1, MKL$(40); MKL$(ImportantColors); MKL$(4); MKL$(&H80001); MKL$(0);
    PRINT #1, MKL$(ImportantColors * 4); MKL$(0); MKL$(0); MKL$(ImportantColors); MKL$(ImportantColors);

    FileBuffer$ = STRING$(ImportantColors * 4, 0)
    Adr& = ColorPaletteAdr&
    FOR Count = 1 TO ImportantColors * 4 STEP 4
        MID$(FileBuffer$, Count, 4) = MKL$(PEEK(Adr& + 2) * 4 OR PEEK(Adr& + 1) * 1024& OR PEEK(Adr&) * 262144)
        Adr& = Adr& + 3
    NEXT
    PRINT #1, FileBuffer$;

    'SEEK 1, 1079
    'print four rows of ascending color strips
    FileBuffer$ = STRING$(ImportantColors, 0)
    FOR Count = 0 TO ImportantColors - 1
        MID$(FileBuffer$, Count + 1, 1) = CHR$(Count)
    NEXT
    FOR Count = 1 TO 4
        PRINT #1, FileBuffer$;
    NEXT

    CLOSE 1
RETURN

GetPalette:
    OUT &H3C7, 0
    FOR Adr& = ColorPaletteAdr& TO Adr& + 765 STEP 3
        POKE Adr&, INP(&H3C9)
        POKE Adr& + 1, INP(&H3C9)
        POKE Adr& + 2, INP(&H3C9)
    NEXT
RETURN

SetPalette:
    OUT &H3C8, 0
    OUT &H3C9, 0: OUT &H3C9, 0: OUT &H3C9, 0
    FOR Adr& = ColorPaletteAdr& + 3 TO ColorPaletteAdr& + 762 STEP 3
        OUT &H3C9, PEEK(Adr&)
        OUT &H3C9, PEEK(Adr& + 1)
        OUT &H3C9, PEEK(Adr& + 2)
    NEXT
SetPaletteHighClr:
    OUT &H3C8, 255
    OUT &H3C9, 255: OUT &H3C9, 255: OUT &H3C9, 255
RETURN

SetPaletteEntry:
    Adr& = ColorPaletteAdr& + SelectedColor * 3
    OUT &H3C8, SelectedColor
    OUT &H3C9, PEEK(Adr&)
    OUT &H3C9, PEEK(Adr& + 1)
    OUT &H3C9, PEEK(Adr& + 2)
RETURN

AdjustColorEntry:
    Adr& = ColorPaletteAdr& + SelectedColor * 3
    ColorMask = 1
    DO
        IF SelectedColorMask AND ColorMask THEN
            Value = PEEK(Adr&) + NewValue
            IF Value > 63 THEN Value = 63 ELSE IF Value < 0 THEN Value = 0
            POKE Adr&, Value
        END IF
        Adr& = Adr& + 1
        ColorMask = ColorMask * 2
    LOOP WHILE ColorMask <= 4
    Redraw = Redraw OR 2
GOTO SetPaletteEntry
'RETURN

SetColorEntry:
    IF NewValue > 63 THEN NewValue = 63 ELSE IF NewValue < 0 THEN NewValue = 0
    Adr& = ColorPaletteAdr& + SelectedColor * 3
    ColorMask = 1
    DO
        IF SelectedColorMask AND ColorMask THEN POKE Adr&, NewValue
        Adr& = Adr& + 1
        ColorMask = ColorMask * 2
    LOOP WHILE ColorMask <= 4
    Redraw = Redraw OR 2
GOTO SetPaletteEntry
'RETURN

ChangeSelectedColor:
    SelectedColor = (SelectedColor + NewValue) AND 255
    Redraw = Redraw OR 3
RETURN

CatchErr:
    ErrHandled = 0
    ON ERROR GOTO ErrHandler
RETURN

ErrHandler:
    ErrHandled = ERR
RESUME NEXT

FUNCTION ConfirmKeypress (Text AS STRING, DesiredKey AS STRING)

DO: LOOP WHILE LEN(INKEY$)
LOCATE 25, 1: PRINT Text; TAB(40);
DO: KeyPress$ = INKEY$: LOOP UNTIL LEN(KeyPress$)
LOCATE 25, 1: PRINT SPACE$(40);
ConfirmKeypress = (KeyPress$ = DesiredKey)

END FUNCTION

