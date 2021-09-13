'Simple Encryptor
DEFINT A-Z

CONST FileBufferSize = 8192
DIM FileBuffer AS STRING * FileBufferSize

r1 = 135: r2 = 127: r3 = 49: r4 = 13

FilePos = 0
FileLen = LOF(1)
DO UNTIL FilePos >= FileLen
    'get next chunk from file
    'xor bytes with random byte
    'output encrypted chunk
   
    GET 1, , FileBuffer
    FOR Count = 1 TO FileBufferSize
        GOSUB GetRnd
        MID$(FileBuffer, Count, 1) = ASC(MID$(FileBuffer, Count, 1)) XOR r1
    NEXT
    FilePos = FilePos + FileBufferSize
LOOP UNTIL LEN(INKEY$)
END

GetRnd:
    r4 = r3: r3 = r2: r2 = r1
    IF r2 < r3 THEN
        r1 = (r2 + r4) AND 255
    ELSE
        r1 = (r3 + r4) AND 255
    END IF
RETURN

RandomDisplay:
    DIM Plots(199)

    PSET (Plots(Row), Row), 0
    PSET (r1, Row), 15
    Plots(Row) = r1
    Row = Row + 1
    IF Row >= 200 THEN Row = 0
RETURN

