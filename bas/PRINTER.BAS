PRINT : LINE INPUT "FileName - ", f$
IF f$ = "" THEN PRINT "Operation aborted": END
ON ERROR GOTO ferr: OPEN f$ FOR INPUT AS #1: CLOSE #1
OPEN f$ FOR BINARY AS #1
OPEN "LPT1" FOR OUTPUT AS #2

FOR r& = 1 TO LOF(1)
 p$ = INPUT$(1, #1): PRINT #2, p$;
NEXT r&
PRINT #2, CHR$(13);

quit:
CLOSE
END

ferr: ferr = ERR
IF ferr = 24 OR ferr = 25 OR ferr = 27 THEN PRINT "Printer error ?.." ELSE PRINT "File not found - "; f$
RESUME quit

