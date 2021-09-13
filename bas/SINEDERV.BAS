DECLARE SUB GraphVals (Vals() AS DOUBLE, Scale%)
'prove derivative of sine is indeed shifted sine
DEFINT A-Z

SCREEN 13

CONST ScreenHeight = 200
CONST ScreenWidth = 320

DIM SineVals(320) AS DOUBLE
DIM DerivVals(320) AS DOUBLE

FOR Count = 0 TO 319
    SineVals(Count) = SIN(Count / 32)
NEXT
FOR Count = 1 TO 319
    DerivVals(Count) = SineVals(Count) - SineVals(Count - 1)
NEXT
DerivVals(0) = DerivVals(1)

COLOR 12: GraphVals SineVals(), 50
COLOR 9: GraphVals DerivVals(), 1600

SUB GraphVals (Vals() AS DOUBLE, Scale)

FOR Count = 0 TO ScreenWidth - 1
    PSET (Count, Vals(Count) * Scale + ScreenHeight \ 2)
NEXT

END SUB

