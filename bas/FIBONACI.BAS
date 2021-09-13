DEFINT A-Z
DECLARE FUNCTION Fibonacci! (n AS INTEGER)

COLOR 10
CLS

FOR n = 0 TO 20
    PRINT n, Fibonacci(n)
NEXT

DEFSNG A-Z
FUNCTION Fibonacci (n AS INTEGER)

DIM SqrBase AS DOUBLE
SqrBase = 2.23606797749979#'SQR(5)
'Fibonacci = ((((1 + SqrBase) / 2) ^ n) - (((1 - SqrBase) / 2) ^ n)) / SqrBase
'Fibonacci = ((((1 + SqrBase) / 2) ^ n) - (((1 - SqrBase) / 2) ^ n)) / SqrBase
Fibonacci = (8 / 2) ^ n

END FUNCTION

