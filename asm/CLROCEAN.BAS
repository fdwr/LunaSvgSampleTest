DEFINT A-Z

CONST PI = 3.141592654#

DIM ColorPalette(0 TO 383)

CLS
PRINT "Press W to write cosine table (sinetabl.txt)"
PRINT "           and color palette  (clrocean.pal)"
DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)
IF Key$ <> "W" THEN END

OPEN "sinetabl.dat" FOR BINARY AS 1
PRINT "Writing cosine table, indexes 0-1023 (2k)"
FOR Count = 0 TO 1023
    Value = INT(COS(Count / 162.9746617048208#) * 16384)
    PUT 1, , Value
NEXT
CLOSE 1

PRINT "Writing color palette, colors 0-255 (768b)"
DEF SEG = VARSEG(ColorPalette(0))
Adr = VARPTR(ColorPalette(0))
FOR Count = 0 TO 255
    ColorCount = (Count + 114) AND 255
    'ColorCount = Count
    POKE Adr, INT(COS(ColorCount / 40.74366542231446#) * 15) + 31
    POKE Adr + 1, INT(COS((ColorCount + 43) / 40.74366542231446#) * 15) + 31
    POKE Adr + 2, INT(COS((ColorCount + 85) / 40.74366542231446#) * 15) + 31
    Adr = Adr + 3
NEXT Count

OPEN "clrocean.pal" FOR BINARY AS 1
FOR Count = 0 TO UBOUND(ColorPalette)
    PUT 1, , ColorPalette(Count)
NEXT
CLOSE 1

