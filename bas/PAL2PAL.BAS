DEFINT A-Z

InputFile$ = "sv\rainbow.old"
OutputFile$ = "sv\rainbow.pal"

OPEN InputFile$ FOR BINARY AS 1
OPEN OutputFile$ FOR BINARY AS 2

Char$ = " "
FOR Count = 1 TO LOF(1)
    GET 1, , Char$
    Char$ = CHR$((ASC(Char$) * 4) AND 255)
    PUT 2, , Char$
NEXT Count

CLOSE 1, 2

