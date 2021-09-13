'Remove duplicate lines
'REMDUPLN
DEFINT A-Z

DIM SrcFile AS STRING
DIM DestFile AS STRING
DIM TextLine AS STRING
DIM NextLine AS STRING
DIM LineCount AS LONG

SrcFile = COMMAND$
IF LEN(SrcFile) <= 0 THEN
    PRINT "Remove Duplicate Lines"
    PRINT "Removes duplicate lines in a sorted text file."
    PRINT
    PRINT "Usage: REMDUPLN srcfile"
    END
END IF
DestFile = LEFT$(SrcFile, LEN(SrcFile) - 1) + "2"

OPEN SrcFile FOR INPUT AS 1
OPEN DestFile FOR OUTPUT AS 2

DO UNTIL EOF(1)
    LINE INPUT #1, NextLine
    IF UCASE$(NextLine) <> UCASE$(TextLine) THEN
        TextLine = NextLine
        PRINT #2, NextLine
        IF (LineCount AND 1023) = 0 THEN
            LOCATE , 1
            PRINT "Line"; LineCount;
        END IF
        LineCount = LineCount + 1
    END IF
LOOP

CLOSE 2, 1

