'Trim Text
'2002-03-01
'Dwayne Robinson
DEFINT A-Z

DIM TotalLines  AS LONG
DIM TextLine    AS STRING
DIM CharPos     AS INTEGER
DIM Char        AS INTEGER

OPEN "\docs\pc\winapico.txt" FOR INPUT AS 1
OPEN "\docs\pc\WINAPIC2.TXT" FOR OUTPUT AS 2

DO UNTIL EOF(1)
    LINE INPUT #1, TextLine
    TextLine = LTRIM$(TextLine)
    'skip all preceding numbers
    FOR CharPos = 1 TO LEN(TextLine)
        Char = ASC(MID$(TextLine, CharPos, 1))
        IF Char < 48 OR Char > 57 THEN EXIT FOR
    NEXT
    TextLine = LTRIM$(RTRIM$(MID$(TextLine, CharPos)))
    PRINT TextLine
    PRINT #2, TextLine
LOOP

CLOSE 2, 1

