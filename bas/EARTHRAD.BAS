'Earth's Radius
'2003-04-14
'At 4.4km out from shore, the boat should be 1.5m below the horizon.
'
a = 30 'distance to core
b = 40 'boat's distance from shore
c = 0 'unknown quantity, hypotenuse
h = 20'16.56854

CLS
COLOR 11
c = SQR(a * a + b * b)
PRINT "a:", a
PRINT "b:", b
PRINT "c:", c

PRINT (b * b - h * h) / (2 * h)

