COLOR 11
CLS
FOR Count = 0 TO 7
    c = Count AND 1
    b = (Count AND 2) \ 2
    a = (Count AND 4) \ 4

    PRINT a; b; c,


    PRINT (NOT a AND b AND NOT c) OR (a AND NOT b) OR (b AND c),
    PRINT (NOT a AND b AND NOT c) OR (a AND NOT b AND NOT c) OR (a AND NOT b AND c) OR (NOT a AND b AND c) OR (a AND b AND c),
    PRINT (NOT a AND b) OR (a AND NOT b) OR (b AND c)




NEXT

