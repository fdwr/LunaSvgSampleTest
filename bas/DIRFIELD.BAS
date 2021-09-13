'DirField
'2003-05-06

DIM X AS LONG
DIM Y AS LONG
DIM Clr AS LONG

SCREEN 13

OUT &H3C8, 0
FOR Count = 0 TO 255
    OUT &H3C9, Count \ 4 + 128
    OUT &H3C9, Count \ 4 + 128
    OUT &H3C9, Count \ 4 + 128
NEXT

FOR Y = 0 TO 199
    FOR X = 0 TO 319
        Clr = (X * Y \ 2) AND 255
        PSET (X, Y), Clr
    NEXT
NEXT


'FOR Count = 0 TO 255
'    LINE (Count, 0)-(Count, 100), Count
'NEXT

