'12-29-95, 862 bytes

'Intro
SCREEN 12
PRINT
PRINT "This programs finds the factors of any given ratio to each other that equal the "; "given product. You may enter the numbers in decimal but you can also enter octalor hexadecimal by preceding them with an &O for octal and &H for hex. (&H78)"
PRINT
'Inputs
INPUT "The ratio of the first factor (multiplicand):", ratio1#
INPUT "The ratio of the second factor (multiplier) :", ratio2#
INPUT "The end result of the two factors (product) :", product#
'Math
dimensions# = ratio1# * ratio2#
IF dimensions# THEN
 factor1# = SQR(product# / dimensions#) * ratio1#
 factor2# = SQR(product# / dimensions#) * ratio2#
END IF
'Result
PRINT
PRINT "Multiplying"; ratio1#; "by"; ratio2#; "equals"; dimensions#
PRINT "The factors with a"; ratio1#; "to"; ratio2#; "ratio that equal this product are:"
PRINT factor1#; "times"; factor2#; "equals"; product#
LINE (0, 196)-(INT(factor1#), INT(factor2#) + 196), 11, B

