DEFINT A-Z
DECLARE SUB MouseDrvCall (DriverFunction%)
DECLARE FUNCTION MouseExists% ()
DECLARE FUNCTION MousePos% (Row%, Col%, Buttons%)
DECLARE SUB MouseShow ()
DECLARE SUB MouseHide ()
DECLARE FUNCTION NewGuiObject% (Trow%, Lcol%)
DECLARE FUNCTION FindGuiObjectAt% (Row%, Col%)
DECLARE SUB AlignToGrid (Row%, Col%)
DECLARE SUB DeleteGuiObject (GuiObject%)
DECLARE SUB ResizeGuiObject (GuiObject AS ANY, Trow%, Lcol%)
DECLARE SUB RedrawGuiObject (GuiObject AS ANY, ColorTop, ColorBottom, ColorLeft, ColorRight)
DECLARE SUB RedrawAllGuiObjects ()

CONST True = -1, False = 0

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Fl AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

TYPE GuiObjectType
Trow AS INTEGER
Lcol AS INTEGER
Hite AS INTEGER
Wdth AS INTEGER
END TYPE

DIM SHARED Regs AS RegType
DIM SHARED GuiObjects(49) AS GuiObjectType, GuiObjectsTotal, GridSize, GridOffset

SCREEN 13

IF MouseExists = False THEN
    PRINT "This program requires a mouse driver. Ending..."
    END
END IF

RedrawAllGuiObjects
MouseShow

UseGrid = True
GridSize = 8
GridOffset = 4
CurrentGuiObject = 0
GuiObjectsTotal = 0
DO
    Key$ = INKEY$
    SELECT CASE UCASE$(Key$)
    CASE "G": UseGrid = UseGrid XOR True
    CASE CHR$(13): RedrawAllGuiObjects
    CASE CHR$(27): EXIT DO
    END SELECT
    MouseChange = MousePos(Row, Col, Buttons)
    IF MouseChange THEN
        LOCATE 1, 1
        IF MouseChange AND 1 THEN
            IF Buttons AND 1 THEN
                IF UseGrid THEN AlignToGrid Row, Col
                CurrentGuiObject = NewGuiObject(Row, Col)
            ELSE
                RedrawAllGuiObjects
            END IF
        ELSEIF MouseChange AND 2 THEN
            IF Buttons AND 2 THEN
                Index = FindGuiObjectAt(Row, Col)
                IF Index < GuiObjectsTotal THEN
                    DeleteGuiObject Index
                    RedrawAllGuiObjects
                END IF
            END IF
        ELSEIF Buttons AND 1 THEN
            IF UseGrid THEN AlignToGrid Row, Col
            ResizeGuiObject GuiObjects(CurrentGuiObject), Row, Col
            PRINT GuiObjects(CurrentGuiObject).Hite; GuiObjects(CurrentGuiObject).Wdth; TAB(10);
        ELSE
            PRINT Row; Col; TAB(10);
        END IF
    END IF
LOOP

WIDTH 80, 25
END

SUB AlignToGrid (Row, Col)
    Row = ((Row + GridOffset) \ GridSize) * GridSize
    Col = ((Col + GridOffset) \ GridSize) * GridSize
END SUB

SUB DeleteGuiObject (GuiObject)
    IF GuiObject < GuiObjectsTotal THEN
        GuiObjectsTotal = GuiObjectsTotal - 1
        GuiObjects(GuiObject).Trow = GuiObjects(GuiObjectsTotal).Trow
        GuiObjects(GuiObject).Lcol = GuiObjects(GuiObjectsTotal).Lcol
        GuiObjects(GuiObject).Hite = GuiObjects(GuiObjectsTotal).Hite
        GuiObjects(GuiObject).Wdth = GuiObjects(GuiObjectsTotal).Wdth
    END IF
END SUB

FUNCTION FindGuiObjectAt (Row, Col)
    FOR Count = 0 TO GuiObjectsTotal - 1
        IF GuiObjects(Count).Trow = Row OR GuiObjects(Count).Lcol = Col THEN
            EXIT FOR
        END IF
    NEXT Count
    FindGuiObjectAt = Count
END FUNCTION

SUB MouseDrvCall (DriverFunction)
    Regs.Ax = DriverFunction
    CALL interruptx(&H33, Regs, Regs)
END SUB

FUNCTION MouseExists
    MouseDrvCall 0
    MouseExists = Regs.Ax
END FUNCTION

SUB MouseHide
    MouseDrvCall 2
END SUB

FUNCTION MousePos (Row, Col, Buttons)
    STATIC LastRow, LastCol, LastButtons

    MouseDrvCall 3
    Row = Regs.Dx
    Col = Regs.Cx \ 2
    Buttons = Regs.Bx
   
    IF Buttons <> LastButtons THEN
        MouseChange = Buttons XOR LastButtons
        LastButtons = LastButtons XOR MouseChange
    END IF
    IF Row <> LastRow OR Col <> LastCol THEN
        LastRow = Row
        LastCol = Col
        MouseChange = MouseChange OR 128
    END IF
    MousePos = MouseChange
END FUNCTION

SUB MouseShow
    MouseDrvCall 1
END SUB

FUNCTION NewGuiObject (Trow, Lcol)
    IF GuiObjectsTotal < UBOUND(GuiObjects) THEN
        GuiObjects(GuiObjectsTotal).Trow = Trow
        GuiObjects(GuiObjectsTotal).Lcol = Lcol
        GuiObjects(GuiObjectsTotal).Hite = 1
        GuiObjects(GuiObjectsTotal).Wdth = 1
        NewGuiObject = GuiObjectsTotal
        GuiObjectsTotal = GuiObjectsTotal + 1
    END IF
END FUNCTION

SUB RedrawAllGuiObjects
    MouseHide
    LINE (0, 0)-(319, 199), 0, BF
    LOCATE 25, 1: PRINT "Total Objects:"; GuiObjectsTotal;
    FOR Count = 0 TO GuiObjectsTotal - 1
        RedrawGuiObject GuiObjects(Count), 31, 26, 29, 28
    NEXT Count
    MouseShow
END SUB

SUB RedrawGuiObject (GuiObject AS GuiObjectType, ColorTop, ColorBottom, ColorLeft, ColorRight)
    Brow = GuiObject.Trow + GuiObject.Hite - 1
    Rcol = GuiObject.Lcol + GuiObject.Wdth - 1
    LINE (GuiObject.Lcol, GuiObject.Trow)-(GuiObject.Lcol, Brow), ColorLeft
    LINE (GuiObject.Lcol, GuiObject.Trow)-(Rcol, GuiObject.Trow), ColorTop
    LINE (Rcol, GuiObject.Trow)-(Rcol, Brow), ColorRight
    LINE (GuiObject.Lcol + 1, Brow)-(Rcol, Brow), ColorBottom
END SUB

SUB ResizeGuiObject (GuiObject AS GuiObjectType, Trow, Lcol)
    MouseHide
    RedrawGuiObject GuiObject, 0, 0, 0, 0
    GuiObject.Hite = Trow - GuiObject.Trow + 1
    GuiObject.Wdth = Lcol - GuiObject.Lcol + 1
    RedrawGuiObject GuiObject, 32, 36, 40, 46
    MouseShow
END SUB

