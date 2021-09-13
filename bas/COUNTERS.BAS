DECLARE FUNCTION COUNTS% (Text$, Element$)
PRINT
PRINT "This program contains a subprogram that counts the number of occurences of one  string within another. It then returns that value to any variable or calculation"
PRINT "Enter a test string below for it work with. Example: (mý - 3m + 18) ö (m - 6)"
PRINT "It will then count the number of opening and closing parentheses and compare theresults to see if they match. Although you could change it, so that it counted  other characters instead of parentheses, the purpose of this is for testing the";
PRINT "validity of equations. You could tell it to count the number of A's and B's?"
INPUT "Enter the test equation here:", a$

Count1 = COUNTS(a$, "(")
Count2 = COUNTS(a$, ")")
IF Count1 <> Count2 THEN t$ = "not "
PRINT "The number of opening parentheses"; Count1; "does " + t$ + "equal the number of closing."; Count2

DEFINT A-Z
FUNCTION COUNTS (Text$, Element$)
s = 1: e = LEN(Text$)
DO
 IF INSTR(s, Text$, Element$) THEN c = c + 1
 s = s + 1
LOOP UNTIL s >= e
COUNTS = c
END FUNCTION

