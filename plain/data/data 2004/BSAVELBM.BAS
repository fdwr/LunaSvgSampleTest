DEFINT A-Z
DIM FontChars(3583)

OPEN "FNT_LARG.LBM" FOR BINARY AS 1
FOR Count = 0 TO UBOUND(FontChars)
    GET 1, , FontChars(Count)
NEXT
CLOSE 1

DEF SEG = VARSEG(FontChars(0))
BSAVE "lettersl.lbm", VARPTR(FontChars(0)), 7168

