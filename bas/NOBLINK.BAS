'Calls video BIOS to disable that stupid, annoying blinking for high colors,
'when what I really want is high intensity background colors.
DEFINT A-Z

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

DIM SHARED Regs AS RegisterType

COLOR 7, 0: CLS

COLOR 1: PRINT "Color 1 (dark blue)"
COLOR 9: PRINT "Color 9 (bright blue)"
COLOR 31, 1: PRINT "Color 31"
COLOR 15: PRINT "Press a key to disable blinking..."

DO: LOOP UNTIL LEN(INKEY$)
Regs.Ax = &H1003
Regs.Bx = 0      'set intensity
CALL interruptx(&H10, Regs, Regs)

COLOR 9: PRINT "Press a key to enable blinking..."
DO: LOOP UNTIL LEN(INKEY$)
Regs.Ax = &H1003
Regs.Bx = 1      'set intensity
CALL interruptx(&H10, Regs, Regs)

COLOR 9: PRINT "Blinking reenabled."
DO: LOOP UNTIL LEN(INKEY$)
Regs.Ax = &H1003
Regs.Bx = 0      'set intensity
CALL interruptx(&H10, Regs, Regs)

