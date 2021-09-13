'tester program for full name qualification

DEFINT A-Z
TYPE RegType
  ax AS INTEGER: bx AS INTEGER: cx AS INTEGER: dx AS INTEGER: bp AS INTEGER
  si AS INTEGER: di AS INTEGER: fl AS INTEGER: ds AS INTEGER: es AS INTEGER
END TYPE
DIM Regs AS RegType, FilenameUnqaulified AS STRING * 128, FilenameQaulified AS STRING * 128

FilenameUnqaulified = "C:FILETEst.Bas"

Regs.ax = &H
'Regs.bx = &H1
'Regs.ds = VARSEG(FilenameUnqaulified)
'Regs.si = VARPTR(FilenameUnqaulified)
'Regs.es = VARSEG(FilenameQaulified)
'Regs.di = VARPTR(FilenameQaulified)

PRINT FilenameUnqaulified

CALL interrupt(&H10, Regs, Regs)

DEF SEG = &HA000
FOR a& = 0 TO 6000
  POKE a&, INT(RND * 256)
NEXT a&
'DO: COLOR INT(RND * 16): PRINT "Hello": LOOP UNTIL INKEY$ = CHR$(27)
'PRINT FilenameQaulified

