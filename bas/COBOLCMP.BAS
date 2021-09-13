'COBOL Code Compressor
'Dwayne Robinson
'2000.11.16
'
'Simply strips source code of all comments and indentation to compare how much
'size difference there is.
DEFINT A-Z

CONST SourceFile$ = "c:\dw\write\cobol\vidp3d"
CONST DestFile$ = "c:\dw\write\cobol\vidp3d.cpt"

STOP 'be sure to change the source and destination files above

OPEN SourceFile$ FOR INPUT AS 1
OPEN DestFile$ FOR OUTPUT AS 2

DO UNTIL EOF(1)
    LINE INPUT #1, Text$
    LinesRead = LinesRead + 1
    IF MID$(Text$, 7, 1) = "*" THEN
        'ignore
    ELSEIF LEFT$(Text$, 12) = "            " THEN
        PRINT #2, "            " + LTRIM$(Text$)
        LinesWritten = LinesWritten + 1
    ELSE
        PRINT #2, Text$
        LinesWritten = LinesWritten + 1
    END IF
    LOCATE , 1: PRINT LinesRead; LinesWritten;
LOOP

CLOSE 1, 2

