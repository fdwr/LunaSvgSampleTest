SCREEN 13
CLS

CONST PI = 3.14159

FOR col = 0 TO 319
    x = col / 320

    'linear
    y = x
    PSET (col, 200 - y * 200), 7
   
    'smooth interpolate
    y = (3 - 2 * x) * x * x
    PSET (col, 200 - y * 200), 12

    'sin
    y = SIN(x * PI)
    PSET (col, 200 - y * 200), 9
   
    'quadrance
    y = SIN(x * PI) * SIN(x * PI)
    PSET (col, 200 - y * 200), 10
NEXT

COLOR 7:  PRINT "Linear"
COLOR 12: PRINT "Interpolate"
COLOR 9:  PRINT "Sin"
COLOR 10: PRINT "Quadrance"

DO: LOOP UNTIL LEN(INKEY$)

