'This simply returns the greatest common facter of two numbers and their
'reduced fraction - as far as I know, this method does not seem to be common
'knowledge. 12-22-97

PRINT "Type in two factors (whole numbers)"
LINE INPUT "Enter factor 1:", num$
IF num$ = "" THEN END ELSE a = VAL(num$)
LINE INPUT "Enter factor 2:", num$
IF num$ = "" THEN END ELSE b = VAL(num$)

c = a: d = b
DO UNTIL d = 0
 e = c MOD d
 c = d
 d = e
LOOP

PRINT "GCF ="; c, a \ c; "\"; b \ c

