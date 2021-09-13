DEFINT A-Z

DIM Count AS LONG
DIM SineTbl(1023) AS LONG

OPEN "sinewave.dat" FOR BINARY AS 1


CLS
FOR Count = 0 TO 1023
    SineTbl(Count) = INT(SIN(3.14159 * 2 * Count / 1024) * 65536)
    PRINT SineTbl(Count);
    PUT 1, , SineTbl(Count)
NEXT

CLOSE 1

