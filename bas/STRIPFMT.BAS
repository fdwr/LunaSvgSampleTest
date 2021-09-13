'2001-09-24 Dwayne Robinson
'Strips formatting from documents using "\{...}" control codes for easier
'reading in a normal text editor.
DEFINT A-Z

CONST FileBufferSize = 4096
DIM FinName AS STRING, FoutName AS STRING
DIM FinBuffer AS STRING * FileBufferSize, FoutBuffer AS STRING * FileBufferSize
DIM Char AS STRING * 1
DIM FinPos AS LONG, FinLen AS LONG, BufferSize AS LONG

FinName = COMMAND$ '"c:\src\nasm\nasm.txt"
IF LEN(FinName) <= 0 THEN
    PRINT "StripFmt NameOfFile.doc"
    PRINT "Exports to temp.txt in current path"
    END
END IF
FoutName = "temp.txt"

OPEN FinName FOR INPUT AS 1: CLOSE 1
OPEN FinName FOR BINARY AS 1
OPEN FoutName FOR OUTPUT AS 2

FinLen = LOF(1)
'FinPos = 0
'Expecting = 0
DO UNTIL FinPos >= FinLen
    BufferSize = FinLen - FinPos
    IF BufferSize > FileBufferSize THEN BufferSize = FileBufferSize
    GET 1, , FinBuffer
    FoutBfrPos = 0
    FOR FinBfrPos = 1 TO BufferSize
        Char = MID$(FinBuffer, FinBfrPos, 1)
        AscChar = ASC(Char)
        IF Expecting = 1 THEN
            'IF Char = "\" OR Char = "{" OR Char = "}" OR Char = "-" THEN
            IF AscChar = 92 OR AscChar = 123 OR AscChar = 125 OR AscChar = 45 THEN
                FoutBfrPos = FoutBfrPos + 1
                MID$(FoutBuffer, FoutBfrPos, 1) = Char
                Expecting = 0
            ELSE
                Expecting = 2
            END IF
        ELSEIF Expecting = 2 THEN
            'IF Char = "{" OR Char = "}" OR Char = " " THEN
            IF AscChar = 123 OR AscChar = 125 OR AscChar = 32 THEN Expecting = 0
        ELSE
            'IF Char = "\" THEN
            IF AscChar = 92 THEN
                Expecting = 1
            'ELSEIF Char = "{" OR Char = "}" THEN
            ELSEIF AscChar <> 123 AND AscChar <> 125 THEN
                FoutBfrPos = FoutBfrPos + 1
                MID$(FoutBuffer, FoutBfrPos, 1) = Char
            END IF
        END IF
    NEXT
    PRINT #2, MID$(FoutBuffer, 1, FoutBfrPos);
    FinPos = FinPos + BufferSize

    LOCATE , 1: PRINT FinPos; "/"; FinLen;
    IF INKEY$ = CHR$(27) THEN EXIT DO
LOOP
CLOSE 2, 1

