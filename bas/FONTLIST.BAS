'Dwayne Robinson
'2004-06-29
'Quick and dirty, lists all ASCII characters to text file


    'good old messed up ASCII
    OPEN "FONTANSI.TXT" FOR OUTPUT AS 1
    Chars$ = ""
    FOR count = 32 TO 255
        Chars$ = Chars$ + "| " + CHR$(count) + " "
        IF (count AND 15) = 15 THEN Chars$ = Chars$ + "| " + CHR$(10) + CHR$(13)
    NEXT
    PRINT #1, Chars$;
    CLOSE 1

    'Unicode little endian
    OPEN "FONTUNIL.TXT" FOR OUTPUT AS 1
    Chars$ = CHR$(255) + CHR$(254)
    FOR count = 32 TO 1023
        Chars$ = Chars$ + "|" + CHR$(0) + " " + CHR$(0) + MKI$(count) + " " + CHR$(0)
        IF (count AND 15) = 15 THEN Chars$ = Chars$ + " " + CHR$(0) + " " + CHR$(0) + CHR$(13) + CHR$(0) + CHR$(10) + CHR$(0)
    NEXT
    PRINT #1, Chars$;
    CLOSE 1

    'Unicode backwards endian
    OPEN "FONTUNIB.TXT" FOR OUTPUT AS 1
    Chars$ = CHR$(254) + CHR$(255)
    FOR count = 32 TO 1023
        Chars$ = Chars$ + CHR$(0) + "|" + CHR$(0) + " " + CHR$(count \ 256) + CHR$(count AND 255) + CHR$(0) + " "
        IF (count AND 15) = 15 THEN Chars$ = Chars$ + CHR$(0) + "|" + CHR$(0) + " " + CHR$(0) + CHR$(13) + CHR$(0) + CHR$(10)
    NEXT
    PRINT #1, Chars$;
    CLOSE 1

