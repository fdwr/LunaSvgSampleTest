COLOR 11
CLS
DO UNTIL key$ = CHR$(27)
    key$ = INKEY$
    IF LEN(key$) THEN
        IF ASC(key$) >= 32 THEN
            PRINT key$; ASC(key$); HEX$(ASC(key$)) + "H", " U"; ASC(UCASE$(key$))
        ELSE
            PRINT
        END IF
    END IF
LOOP

