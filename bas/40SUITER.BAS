'To find which suitor of the 40 would be left after counting every
'third one off. Looks the suitor 27 is the lucky one to marry the
'princess.

DEFINT A-Z
CONST Nums = 40
DIM Num(Nums), Gone(Nums)

FOR Count = 0 TO Nums
    Num(Count) = Count + 1
NEXT Count
GOSUB DisplayNums

DO UNTIL INPUT$(1) = CHR$(27)
    SkipCount = 10
    FOR Count = 0 TO Nums
        IF Gone(Count) = 0 THEN
            IF SkipCount >= 2 THEN
                Gone(Count) = -1
                SkipCount = 0
            ELSE
                SkipCount = SkipCount + 1
            END IF
        END IF
    NEXT
    GOSUB DisplayNums
LOOP

END

DisplayNums:
    CLS
    FOR Count = 0 TO 39
        IF Gone(Count) THEN COLOR 12 ELSE COLOR 15
        PRINT Num(Count),
    NEXT Count
RETURN

