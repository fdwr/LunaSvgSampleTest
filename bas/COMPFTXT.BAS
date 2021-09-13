'Quick and dirty file line comparison
'2002-03-14
'Dwayne Robinson
DEFINT A-Z

DIM File1 AS STRING, File2 AS STRING
DIM Line1 AS STRING, Line2 AS STRING

File1 = COMMAND$
CharPos = INSTR(File1, " ")
IF LEN(File1) <= 0 OR CharPos <= 0 THEN
    PRINT "Must give two filenames to compare text lines"
    END
END IF
File2 = LTRIM$(MID$(File1, CharPos))
File1 = LEFT$(File1, CharPos - 1)

ON ERROR GOTO OpenError
OPEN File1 FOR INPUT AS 1
OPEN File2 FOR INPUT AS 2
ON ERROR GOTO 0

GOSUB GetLine1
GOSUB GetLine2

DO UNTIL Eof1 AND Eof2
    IF Line1 = Line2 THEN
        'print nothing
        GOSUB GetLine1
        GOSUB GetLine2
    ELSEIF Line1 > Line2 THEN
        PRINT SPACE$(20); LEFT$(Line2, 79)
        GOSUB GetLine2
    ELSEIF Line1 < Line2 THEN
        PRINT LEFT$(Line1, 79)
        GOSUB GetLine1
    END IF
    'DO UNTIL LEN(INKEY$): LOOP
LOOP

CLOSE 1, 2
END

GetLine1:
    IF NOT EOF(1) THEN
        LINE INPUT #1, Line1
        Line1 = UCASE$(Line1)
    ELSE
        Eof1 = -1
    END IF
RETURN

GetLine2:
    IF NOT EOF(2) THEN
        LINE INPUT #2, Line2
        Line2 = UCASE$(Line2)
    ELSE
        Eof2 = -1
    END IF
RETURN

OpenError:
    PRINT "Error opening files"
    END

