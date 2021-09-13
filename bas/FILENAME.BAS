'2000.3.10
DEFINT A-Z

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER: Bp AS INTEGER
Si AS INTEGER: Di AS INTEGER: Fl AS INTEGER: Ds AS INTEGER: Es AS INTEGER
END TYPE

DIM SHARED Regs AS RegType
DIM Filename AS STRING, QualifiedFilename AS STRING * 128

DO
    LINE INPUT "Filename:", Filename
    IF LEN(Filename) = 0 THEN EXIT DO
    IF INSTR(Filename, "*") THEN
        SHELL "DIR " + Filename
    ELSE
        Filename = Filename + CHR$(0)
        QualifiedFilename = ""
        GOSUB GetValidFilename
        PRINT Filename; " => "; LEFT$(QualifiedFilename, 64)
        IF Regs.Fl AND 1 THEN PRINT "ERROR:"; Regs.Ax
        PRINT
    END IF
LOOP
CLS
SYSTEM

GetValidFilename:
    Regs.Ax = &H4E00
    Regs.Ds = VARSEG(Filename)
    Regs.Dx = SADD(Filename)
    CALL interruptx(&H21, Regs, Regs)
RETURN

'Get fully qualified name
    Regs.Ds = VARSEG(Filename)
    Regs.Si = SADD(Filename)
    Regs.Es = VARSEG(QualifiedFilename)
    Regs.Di = VARPTR(QualifiedFilename)
    CALL interruptx(&H21, Regs, Regs)

