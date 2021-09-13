DECLARE SUB BubbleSort ()
DECLARE SUB RandomizeTest ()
DECLARE SUB Combsort ()
DECLARE SUB DisplayLine (Col AS LONG)
DECLARE SUB DisplayAllLines ()
DECLARE SUB cmdSort ()
DECLARE SUB WaitKey ()
DECLARE FUNCTION SortVerified$ ()

CONST True = -1
CONST TestSize = 500
DIM SHARED Test(TestSize - 1) AS LONG
DIM SHARED Swaps AS LONG, Comps AS LONG
DIM SHARED KeyPress AS STRING

SCREEN 12
PRINT "Press a key to start test"
cmdSort

SUB BubbleSort

DIM X AS LONG, Y AS LONG
DIM Temp AS LONG
FOR X = 0 TO TestSize - 2
    FOR Y = X + 1 TO TestSize - 1
        Comps = Comps + 1
        IF Test(X) > Test(Y) THEN
            Temp = Test(X)
            Test(X) = Test(Y)
            Test(Y) = Temp
            DisplayLine X
            DisplayLine Y
            Swaps = Swaps + 1
        END IF
    NEXT Y
    'WaitKey
    'IF KeyPress = CHR$(27) THEN EXIT SUB
NEXT X

END SUB

SUB cmdSort

DIM TimeStart AS SINGLE, TimeEnd AS SINGLE

'WaitKey
CLS
RandomizeTest

Swaps = 0
Comps = 0
TimeStart = TIMER
'BubbleSort
TimeEnd = TIMER
PRINT "bubble="; Swaps; "swaps,"; Comps; "comparisons"
PRINT "time="; TimeEnd - TimeStart

WaitKey
CLS
RandomizeTest

Swaps = 0
Comps = 0
TimeStart = TIMER
Combsort
TimeEnd = TIMER
PRINT "comb sort="; Swaps; "swaps, "; Comps; "comparisons"
PRINT "time="; TimeEnd - TimeStart
PRINT SortVerified

END SUB

SUB Combsort
   
DIM I AS LONG, J AS LONG, Temp AS LONG
CONST Shrink = 1.333333 '1.3
DIM Gap AS LONG
DIM Swapped AS INTEGER
Gap = TestSize
DO
    Gap = INT(Gap / Shrink)
   
    IF Gap <= 1 THEN Gap = 1
    Swapped = False
    FOR J = 0 TO TestSize - Gap - 1
        I = J + Gap
        Comps = Comps + 1
        IF Test(J) > Test(I) THEN
            Temp = Test(J)
            Test(J) = Test(I)
            Test(I) = Temp
            Swapped = True
            Swaps = Swaps + 1

            DisplayLine J
            DisplayLine I
        END IF
    NEXT J
   
    LOCATE 1, 1: PRINT Gap; Swapped;
    'WaitKey
    'IF KeyPress = CHR$(27) THEN EXIT SUB
LOOP WHILE Swapped OR Gap > 1
'DisplayAllLines

END SUB

SUB DisplayAllLines

DIM Counter AS LONG

FOR Counter = 0 TO TestSize - 1
    LINE (Counter, 0)-(Counter, Test(Counter) - 1), 15'&HEEEEFF
    LINE (Counter, Test(Counter))-(Counter, 200), 0
NEXT

END SUB

SUB DisplayLine (Col AS LONG)

LINE (Col, 0)-(Col, Test(Col) - 1), 15'&HFFFFFF
LINE (Col, Test(Col))-(Col, 200), 0

END SUB

SUB OldCombsort

DIM I AS LONG, J AS LONG, Temp AS LONG
CONST Shrink = 1.3
DIM Gap AS SINGLE
DIM Swapped AS INTEGER
Gap = 500 - 1
DO
    Gap = INT(Gap / Shrink)
    Swapped = True
    FOR J = 0 TO 499 - Gap
        IF Test(J) > Test(J + Gap) THEN
            Temp = Test(J)
            Test(J) = Test(J + Gap)
            Test(J + Gap) = Temp
            Swapped = False
            Swaps = Swaps + 1
               
            DisplayLine J
            DisplayLine J + Gap
        END IF
    NEXT J
LOOP WHILE Swapped OR Gap > 1

END SUB

SUB RandomizeTest

DIM Counter AS LONG

FOR Counter = 0 TO TestSize - 1
    Test(Counter) = INT(RND * 200)
NEXT
DisplayAllLines
Swaps = 0

END SUB

'Verifies that the array is indeed sorted ascending
FUNCTION SortVerified$

DIM Counter AS LONG
DIM Value AS LONG

Value = -32768
FOR Counter = 0 TO TestSize - 1
    IF Test(Counter) < Value THEN
        SortVerified = "unsorted"
        EXIT FUNCTION
    END IF
    Value = Test(Counter)
NEXT
SortVerified = "sorted correctly"

END FUNCTION

SUB WaitKey

DO: KeyPress = INKEY$: LOOP UNTIL LEN(KeyPress)
DO: LOOP WHILE LEN(INKEY$)

END SUB

