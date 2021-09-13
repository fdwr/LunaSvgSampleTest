'Color Balance
'Dwayne Robinson
'2001-04-07
'
'Displays the percentages of a certain color relative to the color sum,
'the brightest color, and the color average.
DIM ColorNames(2) AS STRING
DIM ColorValues(2) 'holds the brightness values for red, green, blue
DIM ColorNumber(2)

ColorNumber(0) = 12
ColorNumber(1) = 10
ColorNumber(2) = 9

ColorNames(0) = "Red"
ColorNames(1) = "Green"
ColorNames(2) = "Blue"

ColorValues(0) = 254 'peach
ColorValues(1) = 248
ColorValues(2) = 204

SCREEN 0
CLS

LOCATE 6, 1
COLOR 3: PRINT " "; STRING$(20, 220)
COLOR 4: PRINT "±"; STRING$(20, 219); "±"
COLOR 5: PRINT " "; STRING$(20, 223)
PRINT
COLOR 7, 0
PRINT "Use the up/down keys to select the chroma (red/green/blue)"
PRINT "Left/right keys to change brightness by one"
PRINT "PgUp/PgDn keys to change brightness by sixteen"
PRINT "Home/End keys to change brightness by sixteen"

Redraw = -1
DO
    IF Redraw THEN
        'set palette
        OUT &H3C8, 3 'start with color 3
        FOR Count = 0 TO 2: OUT &H3C9, ColorValues(Count) \ 8: NEXT
        FOR Count = 0 TO 2: OUT &H3C9, ColorValues(Count) \ 4: NEXT
        FOR Count = 0 TO 2
            Clr = ColorValues(Count) \ 2
            IF Clr > 63 THEN Clr = 63
            OUT &H3C9, Clr
        NEXT

        'calculate percentages
        Sum = ColorValues(0) + ColorValues(1) + ColorValues(2)
        Grt = ColorValues(0)
        IF ColorValues(1) > Grt THEN Grt = ColorValues(1)
        IF ColorValues(2) > Grt THEN Grt = ColorValues(2)
        'Lst = ColorValues(0)
        'IF ColorValues(1) < Lst THEN Lst = ColorValues(1)
        'IF ColorValues(2) < Lst THEN Lst = ColorValues(2)
        Avg = Sum \ 3
        IF Sum < 1 THEN Sum = 32767
        IF Grt < 1 THEN Grt = 32767
        IF Avg < 1 THEN Avg = 32767

        LOCATE 1, 1
        COLOR 7
        PRINT "Color", "Brightness", "Sum", "Greatest", "Average"
        FOR Count = 0 TO 2
            COLOR ColorNumber(Count)
            IF Count = SelectedColor THEN Char$ = "" ELSE Char$ = " "
            PRINT Char$ + ColorNames(Count), ColorValues(Count), STR$(CINT(ColorValues(Count) * 100 / Sum)) + "%", STR$(CINT(ColorValues(Count) * 100 / Grt)) + "%", STR$(CINT(ColorValues(Count) * 100 / Avg)) + "%  "
        NEXT
        PRINT
    END IF

    Redraw = -1
    SELECT CASE INKEY$
    CASE CHR$(0) + "H": SelectedColor = (SelectedColor + 2) MOD 3
    CASE CHR$(0) + "P": SelectedColor = (SelectedColor + 1) MOD 3
    CASE CHR$(0) + "K": ColorValues(SelectedColor) = (ColorValues(SelectedColor) - 1) AND 255
    CASE CHR$(0) + "M": ColorValues(SelectedColor) = (ColorValues(SelectedColor) + 1) AND 255
    CASE CHR$(0) + "Q", CHR$(0) + "s": ColorValues(SelectedColor) = (ColorValues(SelectedColor) - 16) AND 255
    CASE CHR$(0) + "I", CHR$(0) + "t": ColorValues(SelectedColor) = (ColorValues(SelectedColor) + 16) AND 255
    CASE CHR$(0) + "G", CHR$(0) + "s": ColorValues(SelectedColor) = 0
    CASE CHR$(0) + "O", CHR$(0) + "t": ColorValues(SelectedColor) = 255
    CASE CHR$(27): EXIT DO
    CASE ELSE: Redraw = 0
    END SELECT
LOOP

END

