DECLARE FUNCTION REVERSE$ (Old$)
RANDOMIZE TIMER

FOR Test% = 1 TO 500
Test$ = Test$ + CHR$(RND * 200 + 50)
NEXT Test%

COLOR 15: PRINT "Before it is flipped": COLOR 7: PRINT Test$
COLOR 15: PRINT "After it is flipped": COLOR 7: PRINT REVERSE(Test$)

DEFINT A-Z
FUNCTION REVERSE$ (Old$)

Ver = LEN(Old$)
New$ = SPACE$(Ver)
FOR Rev = 1 TO Ver
 MID$(New$, Ver, 1) = MID$(Old$, Rev, 1)
 Ver = Ver - 1
NEXT Rev

REVERSE$ = New$
END FUNCTION

