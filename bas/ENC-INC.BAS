'20030510
'Dwayne Robinson
'Incremental Encoder/Decoder
DEFINT A-Z

COLOR 11
CLS

CountDir = 1
Counter = 0
DO
    Key$ = INKEY$
    IF LEN(Key$) THEN
        IF Key$ = CHR$(27) THEN EXIT DO
        AscVal = ASC(Key$)
        'IF AscVal = 100 THEN STOP
        IF AscVal <= 32 THEN
            SELECT CASE AscVal
            CASE 0: 'do nothing
            CASE 8: CLS
            CASE 13: PRINT
            CASE ELSE: PRINT Key$;
            END SELECT
        ELSEIF AscVal >= 65 AND AscVal <= 90 THEN
            Counter = (Counter + CountDir + 26) MOD 26
            PRINT CHR$((AscVal - 65 + Counter) MOD 26 + 65);
        ELSEIF AscVal >= 97 AND AscVal <= 122 THEN
            Counter = (Counter + CountDir + 26) MOD 26
            PRINT CHR$((AscVal - 97 + Counter) MOD 26 + 97);
        ELSE
            PRINT Key$;
        END IF
    END IF
LOOP

