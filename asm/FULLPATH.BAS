DEFINT A-Z

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: fl AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

DIM Regs AS RegType
DIM FullPath AS STRING * 128

Regs.Ax = &H1900
CALL INTERRUPTX(&H21, Regs, Regs)
MID$(FullPath, 1, 3) = CHR$((Regs.Ax AND 31) + 65) + ":\"

Regs.Ds = VARSEG(FullPath)
Regs.Si = VARPTR(FullPath) + 3
Regs.Dx = 3

Regs.Ax = &H4700
CALL INTERRUPTX(&H21, Regs, Regs)

PRINT FullPath

