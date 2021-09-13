'1999.9.30
'Converts spaces in text files into tabs.
DEFINT A-Z

CONST TabLength = 8

DIM InputFile, OutputFile
DIM InputFileName AS STRING, OutputFileName AS STRING
DIM TextLine AS STRING, OutLine AS STRING
DIM CrLf AS STRING: CrLf = CHR$(13) + CHR$(10)
DIM SpaceStr AS STRING: SpaceStr = "        "

LINE INPUT "File to tab :", InputFileName
IF LEN(InputFileName) THEN
    LINE INPUT "Output to   :", OutputFileName
    IF LEN(OutputFileName) THEN
        OPEN InputFileName FOR INPUT AS 1': CLOSE 1
        'OPEN InputFileName FOR BINARY AS 1
        OPEN OutputFileName FOR OUTPUT AS 2
        InputFile = 1
        OutputFile = 2
        GOSUB Detab
        CLOSE InputFile, OutputFile
    END IF
END IF

END

Detab:
    DO UNTIL EOF(1)
        LINE INPUT #InputFile, TextLine
        TextLine = RTRIM$(TextLine)
        OutLine = ""
        DO WHILE LEFT$(TextLine, TabLength) = SpaceStr
            OutLine = OutLine + CHR$(9)
            TextLine = MID$(TextLine, TabLength + 1)
        LOOP
        OutLine = OutLine + TextLine
        PRINT #OutputFile, OutLine
        LineCount = LineCount + 1
        IF (LineCount AND 31) = 0 THEN LOCATE , 1: PRINT LineCount;
    LOOP
RETURN

