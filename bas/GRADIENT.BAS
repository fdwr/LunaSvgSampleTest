DEFINT A-Z
CONST Bits = 7, BitValues = 128
DIM BitFlip(0 TO Bits - 1), ValueFlip(0 TO BitValues - 1)

'RANDOMIZE TIMER
GOSUB FlipBits

SCREEN 13

DO
    TotalRows = 200
    FOR Row = 0 TO TotalRows - 1
        'RowAcc = 0
        'RowAcc = (Row * 13) AND 127
        'RowAcc = INT(RND * TotalRows)
        RowAcc = ValueFlip(Row AND 127)
        FOR Col = 0 TO 319
            RowAcc = RowAcc + Row
            IF RowAcc > TotalRows THEN
                RowAcc = RowAcc MOD TotalRows
                PSET (Col, Row), 9
            ELSE
                PSET (Col, Row), 0
            END IF
        NEXT Col
    NEXT Row
LOOP UNTIL LEN(INKEY$)

WIDTH 80, 25
END


FlipBits:
    Value = BitValues
    FOR Count = 0 TO Bits - 1
        Value = Value \ 2
        BitFlip(Count) = Value
    NEXT Count
    FOR Count = 0 TO BitValues - 1
        Value = 0
        Mask = 1
        FOR Bit = 0 TO Bits - 1
            IF Count AND Mask THEN Value = Value OR BitFlip(Bit)
            Mask = Mask * 2
        NEXT Bit
        ValueFlip(Count) = Value
    NEXT Count
RETURN

ShowBitFlips:
    FOR Count = 0 TO BitValues - 1
        LINE (Count, -1)-(Count, ValueFlip(Count) + 1), 9
    NEXT Count
RETURN

