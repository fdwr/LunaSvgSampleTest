DEFINT A-Z
REDIM Test(0 TO 1)

DEF SEG = VARSEG(Test(0))
FOR a = 0 TO 2
 READ Value
 POKE VARPTR(Test(0)) + a, Value
NEXT
DATA &hCD,&h00,&hCB

CALL ABSOLUTE(VARPTR(Test(0)))

