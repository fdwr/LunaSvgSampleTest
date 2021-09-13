DEFINT A-Z

REDIM b(0 TO 3)
DEF SEG = 0
FOR a = 0 TO 3
 b(a) = PEEK(&H40 + a)
NEXT a
FOR a = 0 TO 1
 b(a) = b(a * 2) + b(a * 2 + 1) * 256
NEXT a

PRINT
PRINT "Interrupt vector to video BIOS"
PRINT "Segment:"; b(0), HEX$(b(0))
PRINT "Offset:"; b(1), HEX$(b(1))

