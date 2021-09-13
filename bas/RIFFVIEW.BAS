DECLARE SUB FlipLong (Num AS LONG)
'RIFF VIEW
'2000.12.10

DEFINT A-Z

TYPE RiffHeaderType
Id     AS STRING * 4
Length AS LONG
END TYPE

DIM RiffHeader AS RiffHeaderType
DIM RiffPosHistory(99) AS LONG, RiffPosIdx, RiffPosTotal

RiffFile$ = COMMAND$
OPEN RiffFile$ FOR INPUT AS 1: CLOSE 1
OPEN RiffFile$ FOR BINARY AS 1
FileLen& = LOF(1)

PRINT "RIFF View (Peekin 2000.12.10)"
PRINT "Viewing "; RiffFile$; FileLen&; "bytes"

FlipHeaderLength = 1
RiffPos& = 1
GetRiffInfo = 1
DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE CHR$(13)
        RiffPos& = RiffPos& + RiffHeader.Length + 8
        RiffPosIdx = RiffPosIdx + 1
        GetRiffInfo = 1
    CASE " "
        RiffPos& = RiffPos& + 8
        RiffPosIdx = RiffPosIdx + 1
        GetRiffInfo = 1
    CASE "*"
        RiffPos& = RiffPos& + 4
        RiffPosIdx = RiffPosIdx + 1
        GetRiffInfo = 1
    CASE CHR$(0) + "K", CHR$(8)
        RiffPosDif = -1
        GOSUB GetNextPrevRiffPos
    CASE CHR$(0) + "M"
        RiffPosDif = 1
        GOSUB GetNextPrevRiffPos
    CASE CHR$(27)
        EXIT DO
    END SELECT
    IF GetRiffInfo THEN
        GET 1, RiffPos&, RiffHeader
        IF FlipHeaderLength THEN FlipLong RiffHeader.Length
        IF RiffPos& > FileLen& THEN COLOR 12 ELSE COLOR 7
        PRINT RiffPos&; TAB(10);
        COLOR 7
        PRINT RiffPosIdx; TAB(15); "("; RiffHeader.Id; ") ="; RiffHeader.Length
        GetRiffInfo = 0
        IF RiffPosIdx > UBOUND(RiffPosHistory) THEN
            RiffPosIdx = UBOUND(RiffPosHistory)
        END IF
        RiffPosHistory(RiffPosIdx) = RiffPos&
        IF RiffPosIdx > RiffPosTotal THEN RiffPosTotal = RiffPosIdx
    END IF
LOOP

CLOSE 1
PRINT
END

StoreRiffPos:
RETURN

GetNextPrevRiffPos:
    RiffPosDif = RiffPosIdx + RiffPosDif
    IF RiffPosDif >= 0 AND RiffPosDif <= UBOUND(RiffPosHistory) AND RiffPosDif <= RiffPosTotal THEN
        RiffPosIdx = RiffPosDif
        RiffPos& = RiffPosHistory(RiffPosIdx)
        GetRiffInfo = 1
    END IF
RETURN

SUB FlipLong (Num AS LONG)

DEF SEG = VARSEG(Num)
Adr = VARPTR(Num)
Byte = PEEK(Adr)
POKE Adr, PEEK(Adr + 3)
POKE Adr + 3, Byte
Byte = PEEK(Adr + 1)
POKE Adr + 1, PEEK(Adr + 2)
POKE Adr + 2, Byte

END SUB

