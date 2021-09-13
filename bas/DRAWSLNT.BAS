DECLARE SUB DrawSlantColored (ColBase%)
'1999.11.6 Peekin
'Line test
DEFINT A-Z

SCREEN 13

FOR Count = 0 TO 200
    DrawSlantColored (Count)
    'DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)
    'IF Key$ = CHR$(27) THEN EXIT FOR
NEXT Count

SUB DrawSlantColored (ColBase)
    STATIC Clr

    Clr = 9'Clr + 1
    Mask = 31
    Row = (ColBase \ 4) + 100
    Col = ColBase \ 2
    Count = 0
    IF (ColBase AND 3) = 1 THEN Count = Count - 1
    IF (ColBase AND 3) = 3 THEN Col = Col + 1
    IF (ColBase AND 3) = 0 THEN
        'Count = Count + 1
        IF (Count AND Mask) = 0 THEN
            PSET (Col, Row), Clr
            'LINE (Col, Row)-(Col, Row - 20), Clr
        END IF
        Row = Row - 1
        Col = Col + 1
        Count = Count + 1
        Clr = Clr + 1
    END IF
    FOR Row = Row TO 0 STEP -1
        IF (Count AND Mask) = 0 THEN PSET (Col, Row), Clr'LINE (Col, Row)-(Col, Row - 20), Clr
        Count = Count + 1
        Clr = (Clr AND 7) + 9
        IF (Count AND Mask) = 0 THEN PSET (Col + 1, Row), Clr'LINE (Col, Row)-(Col, Row - 20), Clr
        Count = Count + 1
        Clr = (Clr AND 7) + 9
        'Clr = (Clr + 1) AND 7
        Col = Col + 2
    NEXT Row

'0123456789012345
'0000111122223333
'0012223444566678
'--
'  --
'    --
'      --
'
'
END SUB

