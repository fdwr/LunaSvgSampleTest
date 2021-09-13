DECLARE FUNCTION PROMPT# (result$)
CONST TRUE = -1
CONST FALSE = 0

CLS
a# = PROMPT("")
PRINT
PRINT "This was the number entered:"; a#

FUNCTION PROMPT# (result$)

 Change = TRUE
 DO WHILE NOT Done

  IF Change THEN
   LOCATE Row + 1, Col + 1, 0
   PRINT result$; CHR$(95); " ";
   Change = FALSE
  END IF

  Kbd$ = INKEY$
  SELECT CASE Kbd$
   CASE "0" TO "9"
    result$ = result$ + Kbd$
    Change = TRUE
   CASE "."
    IF INSTR(result$, ".") = 0 THEN
     result$ = result$ + Kbd$
     Change = TRUE
    END IF
   CASE CHR$(13)
    Done = TRUE
   CASE CHR$(8), CHR$(0) + "S"
    IF LEN(result$) > 0 THEN
     IF Kbd$ = CHR$(8) THEN
      result$ = LEFT$(result$, LEN(result$) - 1)
     ELSE
      result$ = RIGHT$(result$, LEN(result$) - 1)
     END IF
     Change = TRUE
    END IF
   CASE CHR$(27)
    EXIT FUNCTION
   CASE ELSE
    IF LEN(Kbd$) > 0 THEN
     SOUND 1024, .2
    END IF
  END SELECT
 LOOP

 LOCATE Row + 1, Col + 1
 PRINT result$; " ";

 PROMPT# = VAL(result$)
END FUNCTION

