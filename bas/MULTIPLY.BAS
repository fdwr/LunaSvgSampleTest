DECLARE FUNCTION MULTIPLY! (a#, b#)
INPUT "First operand:", a#
INPUT "Last  operand:", b#
PRINT MULTIPLY(a#, b#)

FUNCTION MULTIPLY (a#, b#)
IF a# > b# THEN SWAP a#, b#: swapped = 1
FOR count# = 1 TO ABS(a#)
r# = r# + b#
NEXT count#
MULTIPLY = r#
IF swapped THEN SWAP a#, b#: swapped = 0
END FUNCTION

