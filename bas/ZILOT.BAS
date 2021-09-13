DEFINT A-Z
DECLARE SUB MouseFunction (Ax)
DECLARE SUB DrawShape (ShapePointCount, ShapePoints(), ysa, ysb, xsa, xsb, yra, yrb, xra, xrb)

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

CONST MaxShapePointCount = 20
DIM SHARED Regs AS RegisterType
DIM GrabRow, GrabCol, DragRow, DragCol, MouseRow, MouseCol
DIM ysa, ysb, xsa, xsb, yra, yrb, xra, xrb
DIM ShapePoints(MaxShapePointCount - 1, 1)

GOSUB ReadShape

SCREEN 7, , 1, 0
MouseFunction &H21

GOSUB RestoreShape
DO
    Key$ = LCASE$(INKEY$)
    SELECT CASE Key$
    CASE "s": ShapeMode = 0: GOSUB DeformShape
    CASE "h": ShapeMode = 1: GOSUB DeformShape
    CASE "r": ShapeMode = 2: GOSUB DeformShape
    CASE CHR$(0) + "h": DragRow = DragRow - 1: GOSUB DeformShape
    CASE CHR$(0) + "p": DragRow = DragRow + 1: GOSUB DeformShape
    CASE CHR$(0) + "k": DragCol = DragCol - 1: GOSUB DeformShape
    CASE CHR$(0) + "m": DragCol = DragCol + 1: GOSUB DeformShape
    CASE " ": GOSUB RestoreShape
    CASE CHR$(27): EXIT DO
    END SELECT

    MouseFunction 3
    Regs.Cx = Regs.Cx \ 2
    IF (Regs.Bx AND 1) <> ShapeGrabbed THEN
        ShapeGrabbed = Regs.Bx AND 1
        IF ShapeGrabbed THEN
            GrabRow = Regs.Dx - 100: GrabCol = Regs.Cx - 160
            DragRow = GrabRow: DragCol = GrabCol
            GOSUB RestoreShape
        ELSE
            ShapeChange = -1
        END IF
    ELSE
        IF MouseRow <> Regs.Dx OR MouseCol <> Regs.Cx THEN
            MouseRow = Regs.Dx: MouseCol = Regs.Cx
            DragRow = Regs.Dx - 100: DragCol = Regs.Cx - 160
            GOSUB DeformShape
        END IF
    END IF

    CLS
    DrawShape ShapePointCount, ShapePoints(), ysa, ysb, xsa, xsb, yra, yrb, xra, xrb
    PSET (160, 100), 12
    PSET (DragCol + 160, DragRow + 100), 13
    PSET (MouseCol, MouseRow), 15
    PCOPY 1, 0
LOOP

WIDTH 80, 25
SCREEN 0
END

RestoreShape:
    ysa = 1: ysb = 1: xsa = 1: xsb = 1
    yra = 0: yrb = 1: xra = 0: xrb = 1
    ShapeChange = -1
RETURN

DeformShape:
    IF ShapeGrabbed = 0 THEN RETURN
    SELECT CASE ShapeMode
    CASE 0: ysa = DragRow: ysb = GrabRow
            xsa = DragCol: xsb = GrabCol
    CASE 1: 'yra = DragRow: yrb = GrabRow
            xra = DragCol - GrabCol: xrb = GrabCol
    CASE 2: 'yra = DragRow - 100
            'xra = DragCol - 160
            ysa = DragCol: ysb = GrabCol
            xsa = DragCol: xsb = GrabCol
            yra = DragRow: yrb = GrabRow
            xra = DragRow: xrb = GrabRow
    END SELECT
    ShapeChange = -1
RETURN

ReadShape:
    READ ShapePointCount
    FOR Count = 0 TO ShapePointCount - 1
        READ ShapePoints(Count, 0), ShapePoints(Count, 1)
    NEXT Count
RETURN

'DATA 7, 0,0, 5,0, 10,0, 15,0, 20,0, 20,5, 20,10
DATA 20, -20,0, -12,-3, -12,3, -5,-20, -5,-12, -5,-5, -5,5, -5,12, -5,20
DATA 0,-13, 0,13, 4,-7, 4,7, 8,0, 9,-8, 9,8, 15,-10, 11,-4, 11,4, 15,10

SUB DrawShape (ShapePointCount, ShapePoints(), ysa, ysb, xsa, xsb, yra, yrb, xra, xrb)

IF ysb = 0 THEN ysb = 1: ysa = 0
IF xsb = 0 THEN xsb = 1: xsa = 0
IF yrb = 0 THEN yrb = 1: yra = 0
IF xrb = 0 THEN xrb = 1: xra = 0

FOR Count = 0 TO ShapePointCount - 1
    Row = ShapePoints(Count, 0)
    Col = ShapePoints(Count, 1)
    NewRow = (Row * ysa \ ysb) - (Col * yra \ yrb)
    NewCol = (Col * xsa \ xsb) + (Row * xra \ xrb)
    PSET (NewCol + 160, NewRow + 100), 9
NEXT Count

END SUB

SUB MouseFunction (Ax)
STATIC MousePresent

Regs.Ax = Ax
IF MousePresent THEN
  CALL InterruptX(&H33, Regs, Regs)
ELSEIF Ax = 0 OR Ax = &H21 THEN
  CALL InterruptX(&H33, Regs, Regs)
  IF Regs.Ax = -1 THEN MousePresent = -1
END IF

END SUB

