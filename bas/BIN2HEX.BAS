DEFINT A-Z

CONST InFile$ = "midpak.dat", OutFile$ = "out.txt"
CONST LineWrap = 16

DIM HexNumTable(15)

OPEN InFile$ FOR INPUT AS 1: CLOSE 1
OPEN InFile$ FOR BINARY AS 1
OPEN OutFile$ FOR OUTPUT AS 2

FOR Count = 0 TO 9
    HexNumTable(Count) = Count + 48
NEXT
FOR Count = 10 TO 15
    HexNumTable(Count) = Count + 55
NEXT

HexText$ = SPACE$(LineWrap * 3)
DO UNTIL EOF(1)
    FileBuffer$ = INPUT$(2048, 1)
    DEF SEG = VARSEG(HexText$)
    LineWrapCount = 0
    Adr& = SADD(HexText$)
    FOR Count = 1 TO LEN(FileBuffer$)
        Value = ASC(MID$(FileBuffer$, Count, 1))
        POKE Adr&, HexNumTable(Value \ 16)
        POKE Adr& + 1, HexNumTable(Value AND 15)
        Adr& = Adr& + 3
        LineWrapCount = LineWrapCount + 1
        IF LineWrapCount >= LineWrap THEN
            PRINT #2, HexText$
            LineWrapCount = 0
            Adr& = SADD(HexText$)
        END IF
    NEXT
LOOP
IF LineWrapCount > 0 THEN PRINT #2, HexText$

CLOSE 2, 1

