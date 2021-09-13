COLOR 11
CLS
GOTO Inside
DO
    Value = 0
    FOR CharPos = 1 TO LEN(Num$)
        Value = Value * 2 + VAL(MID$(Num$, CharPos, 1))
    NEXT
    PRINT "Decimal value:"; Value
Inside:
    LINE INPUT "Binary number:", Num$
LOOP WHILE LEN(Num$)

