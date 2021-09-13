'Little Timer Demo - 1999.12.15
DEFINT A-Z

CLS
PRINT "Original speed  - 18.2 ticks per second"
DO
    LOCATE , 1: PRINT TIMER;
LOOP UNTIL LEN(INKEY$)

PRINT
PRINT "Faster speed    - 30 ticks per second"
OUT &H43, &H34
Dummy = INP(&H43)
OUT &H40, 92    '39772
Dummy = INP(&H43)
OUT &H40, 155
DO
    LOCATE , 1: PRINT TIMER;
LOOP UNTIL LEN(INKEY$)

PRINT
PRINT "Restored speed"
OUT &H43, &H36
Dummy = INP(&H43)
OUT &H40, 0     '65536
Dummy = INP(&H43)
OUT &H40, 0
DO
    LOCATE , 1: PRINT TIMER;
LOOP UNTIL LEN(INKEY$)

END