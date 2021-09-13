PRINT : COLOR 7
PRINT "Type a number for a tone or just press Enter to end."
CONST t = .0594631
DO
COLOR 7: INPUT "Enter Tone: ", x$
IF x$ = "" THEN END ELSE x = VAL(x$)
IF x > 95 THEN x = 95
p = 128
COLOR 15
FOR r% = 1 TO x
IF INKEY$ = CHR$(27) THEN END
p = (t * p) + p
PRINT "Tone ="; p
NEXT r%
SOUND INT(p), 5
LOOP

