COLOR 11
CLS

A(0) = 7
A(1) = 11
A(2) = 13
A(3) = 14
A(4) = 19
A(5) = 21
A(6) = 22
A(7) = 25
A(8) = 26
A(9) = 28


B(0) = 15
B(1) = 23
B(2) = 27
B(3) = 29
B(4) = 30

FOR Ac = 0 TO 9
    FOR Bc = 0 TO 4
        C = A(Ac) XOR B(Bc)
        IF C THEN
            Cc = C
            DO UNTIL Cc AND 1
                Cc = Cc \ 2
            LOOP
            IF Cc = 1 THEN
                PRINT A(Ac); B(Bc); C,
                BinStr$ = ""
                Value = A(Ac)
                DO UNTIL Value = 0
                    BinStr$ = RIGHT$(STR$(Value AND 1), 1) + BinStr$
                    Value = Value \ 2
                LOOP
                PRINT BinStr$
            END IF
        END IF
    NEXT
NEXT


'COLOR 11
'CLS
'GOTO Inside
'DO
'    Value = 0
'    FOR CharPos = 1 TO LEN(Num$)
'        Value = Value * 2 + VAL(MID$(Num$, CharPos, 1))
'    NEXT
'    PRINT "Decimal value:"; Value
'Inside:
'    LINE INPUT "Binary number:", Num$
'LOOP WHILE LEN(Num$)

