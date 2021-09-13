DECLARE FUNCTION BIN$ (a%)
DECLARE FUNCTION NIB% (a$)

'BIN$ returns a binary string representation of an integer
'   This works much like the OCT$ and HEX$ functions

'NIB% returns a integer of a binary string represenation
'   This is kindred to the VAL function


'Syntax:

'BIN$(numeric-expression%)
'NIB%(stringexpression$) 
  
'   þ {numeric-expression%} is an integer -32768 to 32767

'   þ {stringexpression$} is any string with 1's and 0's. If it contains any
'     other characters, they will be treated as 0's.


PRINT
PRINT 21845; "--> "; BIN(21845)
PRINT " 101010101010101 -->"; NIB("101010101010101")

PRINT 13; "--> "; BIN(13)
PRINT " 1011 -->"; NIB("1011")

DEFINT A-Z
FUNCTION BIN$ (a)
B = LEN(a) * 8: d$ = STRING$(B, "0")

FOR c = 0 TO B - 1
 IF a AND 2 ^ c THEN MID$(d$, c + 1) = "1"
NEXT c

FOR c = LEN(d$) TO 1 STEP -1
 IF MID$(d$, c, 1) = "0" THEN d$ = LEFT$(d$, LEN(d$) - 1) ELSE EXIT FOR
NEXT c

BIN$ = d$
END FUNCTION

FUNCTION NIB (a$)

d = 0

FOR c = 0 TO LEN(a$) - 1
 IF MID$(a$, c + 1, 1) = "1" THEN d = d OR (2 ^ c)
NEXT c

NIB = d
END FUNCTION

