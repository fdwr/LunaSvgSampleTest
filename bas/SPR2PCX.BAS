DEFINT A-Z

DIM FileBuffer AS STRING, ColorPalette AS STRING

InputFile$ = "c:\dw\src\spc\screen00.spr"
InputPalFile$ = "c:\dw\src\spc\screen00.pal"


OPEN InputFile$ FOR BINARY AS 1
OPEN InputPalFile$ FOR BINARY AS 2
OPEN "snapshot.pcx" FOR OUTPUT AS 3

SCREEN 13


ColorPalette = INPUT$(768, 2)
OUT &H3C8, 0
FOR Index = 0 TO 767
    Byte = ASC(MID$(ColorPalette, Index + 1, 1))
    OUT &H3C9, Byte
    MID$(ColorPalette, Index + 1, 1) = CHR$(Byte * 4)
NEXT
SEEK 1, 9
FOR Row = 0 TO 199
    FileBuffer = INPUT$(320, 1)
    FOR Col = 0 TO 319
        PSET (Col, Row), ASC(MID$(FileBuffer, Col + 1, 1))
NEXT Col, Row


DEF SEG = &HA000: BytePos& = 0
PRINT #3, CHR$(10); CHR$(5); CHR$(1); CHR$(8); MKL$(0); MKI$(319); MKI$(199); MKI$(320); MKI$(200); STRING$(49, 0); CHR$(1); MKI$(320); MKI$(0); STRING$(58, 0);
FOR BytePos& = 0 TO 320& * 200 - 1
    ByteValue = PEEK(BytePos&)
    IF ByteValue < 192 THEN PRINT #3, CHR$(ByteValue);  ELSE PRINT #3, "Á"; CHR$(ByteValue);
NEXT BytePos&
PRINT #3, CHR$(12);
PRINT #3, ColorPalette;


CLOSE 1, 2, 3
END

