'Lbm to Char lbm
'2001-03-25
DEFINT A-Z

srcfile$ = "lum.lbm"
destfile$ = "lum.out"
OPEN srcfile$ FOR BINARY AS 1
OPEN destfile$ FOR OUTPUT AS 2

FileLen = LOF(1)
Char$ = " "
FOR Count = 1 TO FileLen
    GET 1, , Char$
    PRINT #2, CHR$(ASC(Char$) + 97);
NEXT

CLOSE 2, 1

