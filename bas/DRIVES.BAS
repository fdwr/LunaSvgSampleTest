DEFINT A-Z

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

DIM SHARED InRegs AS RegisterType, OutRegs AS RegisterType

CLS
InRegs.Ax = &H4408 'get removable media
FOR Drive = 0 TO 25
    InRegs.Bx = Drive
    CALL interruptx(&H21, InRegs, OutRegs)
    IF (OutRegs.Flags AND 1) = 0 THEN PRINT CHR$(Drive + 65); " ="; OutRegs.Ax
NEXT

