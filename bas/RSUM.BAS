'Dwayne Robinson (Peekin)
'2003-04-04 / 2003-04-06
'Calculates Reiman sums used for integrals in MTH252 class
'
COLOR 11
CLS

a = 1
b = 10
n = 100
delta = (b - a) / n
'delta = 2

'mode = -1 '-1=left 0=mid 1=right
'GOSUB CalcRsum
'PRINT "Left: "; area

mode = 0 '-1=left 0=mid 1=right
GOSUB CalcRsum
PRINT "Mid:  "; area

'mode = 1 '-1=left 0=mid 1=right
'GOSUB CalcRsum
'PRINT "Right:"; area

END

CalcRsum:
    area = 0
    SELECT CASE mode
    CASE -1 'left
        FOR x = a TO b - delta STEP delta
            GOSUB Formula
        NEXT
    CASE 0 'mid
        FOR x = a + delta / 2 TO b - delta / 2 STEP delta
            GOSUB Formula
        NEXT
    CASE 1 'right
        FOR x = a + delta TO b STEP delta
            GOSUB Formula
        NEXT
    END SELECT
    area = area * delta
RETURN

Formula:
    'area = area + (2 - x ^ 2)
    y = x ^ 2
    area = area + y
    PRINT x; "="; y
RETURN

