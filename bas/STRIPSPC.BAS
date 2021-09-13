DEFINT A-Z

CONST FileDataSize = 4096

DIM InFile AS STRING, OutFile AS STRING, Char AS STRING * 1
DIM InData AS STRING, OutData AS STRING

InFile = "c:\write\bookrprt.txt"
OutFile = "c:\out.txt"

OPEN InFile FOR INPUT AS 1: CLOSE 1
OPEN InFile FOR BINARY AS 1
OPEN OutFile FOR OUTPUT AS 2

Tab$ = CHR$(9)
DO UNTIL EOF(1)
    InData = INPUT$(FileDataSize, 1)
    OutData = InData
    OutDataSize = 0
    FOR Count = 1 TO LEN(InData)
        Char = MID$(InData, Count, 1)
        IF Char <> " " AND Char <> Tab$ THEN
            OutDataSize = OutDataSize + 1
            MID$(OutData, OutDataSize, 1) = Char
        END IF
    NEXT
    PRINT #2, LEFT$(OutData, OutDataSize);
LOOP

CLOSE 2, 1

