'1999.11.6 Peekin
'Graphical Port Mapper
DEFINT A-Z
DECLARE SUB DrawSlantColored (ColBase%, Port%)

SCREEN 13

ON ERROR GOTO IgnoreStupidOverflow

Port = 40: GOSUB PrintCurPort
DO
    FOR Count = 0 TO 199
        DrawSlantColored Count, Port
GetKeyPress:
        Key$ = INKEY$
        IF LEN(Key$) THEN
            SELECT CASE Key$
            CASE CHR$(0) + "H": Port = Port + 20: GOSUB PrintCurPort
            CASE CHR$(0) + "P": Port = Port - 20: GOSUB PrintCurPort
            CASE CHR$(0) + "M": Port = Port + 1: GOSUB PrintCurPort
            CASE CHR$(0) + "K": Port = Port - 1: GOSUB PrintCurPort
            CASE "0" TO "9"
                Port = VAL(STR$(Port) + Key$) AND 32767: GOSUB PrintCurPort
            CASE CHR$(8)
                Port = VAL(LEFT$(STR$(Port), LEN(STR$(Port)) - 1)): GOSUB PrintCurPort
            CASE CHR$(13)
                GOSUB ViewSinglePort
                CLS
                GOSUB PrintCurPort
            CASE CHR$(27): EXIT DO
            END SELECT
            GOTO GetKeyPress
        END IF
        'Port = Port + 1
    NEXT Count
    GOSUB PrintCurPort
    'IF Key$ = CHR$(27) THEN EXIT FOR
LOOP

END

PrintCurPort:
    LOCATE 1, 33: PRINT STR$(Port); TAB(40);
RETURN

ViewSinglePort:
    CLS
    GOSUB PrintCurPort
    Row = 0
    DO
        LINE (0, Row)-(255, Row), 0
        PSET (INP(Port), Row), 9
        IF Row >= 199 THEN
            Row = 0
            IF LEN(INKEY$) THEN EXIT DO
        ELSE
            Row = Row + 1
        END IF
    LOOP
RETURN

IgnoreStupidOverflow:
RESUME NEXT

SUB DrawSlantColored (ColBase, Port)
    Clr = 41
    Row = (ColBase \ 2) + 100
    Col = ColBase
    IF ColBase AND 1 THEN
        LINE (Col - 1, Row + 1)-(Col + 199, Row - 99), 0
    ELSE
        LINE (Col, Row)-(Col + 200, Row - 100), 0
    END IF
    CurPort = Port
    FOR Row = Row TO Row - 60 STEP -1
        PortInp = INP(CurPort)
        IF PortInp <> 255 THEN
            LINE (Col, Row)-(Col, Row - (PortInp \ 8)), Clr
        ELSE
            PSET (Col, Row), Clr
            'PSET (Col, Row - 1), Clr
        END IF
        Clr = Clr + 1
        Col = Col + 2
        CurPort = CurPort + 1
    NEXT Row

'0123456789012345
'0000111122223333
'012223444566678
'--
'  --
'    --
'      --
'
'
END SUB

