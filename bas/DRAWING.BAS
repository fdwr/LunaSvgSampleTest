DEFINT A-Z
DECLARE SUB ShowDrawing ()
DECLARE SUB ShowDrawingCells ()
DECLARE SUB ShowDrawingCell (TopRow, LeftCol)
DECLARE FUNCTION FindMouseItem% (ScreenItems() AS ANY)
DECLARE SUB ShowColorPalette ()
DECLARE SUB SetColorPalette ()
DECLARE SUB GetMousePos ()
DECLARE SUB MouseFunction (Ax%)

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

TYPE ScreenItemType
TopRow  AS INTEGER
LeftCol AS INTEGER
Hite    AS INTEGER
Wdth    AS INTEGER
END TYPE

CONST DrawingHeight = 64, DrawingWidth = 60
CONST DrawingScreenHeight = 49, DrawingScreenWidth = 60
CONST DrawingPixelSize = 4, DrawingPixelHeight = DrawingScreenHeight * DrawingPixelSize, DrawingPixelWidth = DrawingScreenWidth * DrawingPixelSize
DIM SHARED Drawing(0 TO 4095), ColorPalette(255) AS LONG, RedValue, GrnValue, BluValue
DIM SHARED DrawingTop, DrawingLeft, DrawingColor, DrawingRow, DrawingCol, DrawingChanges
DIM SHARED MouseExists, MouseRow, MouseCol, MouseButtons, MouseChange, Regs AS RegisterType
DIM ScreenItems(2) AS ScreenItemType

SCREEN 13
MouseFunction &H21

IF LEN(COMMAND$) THEN
    GOSUB LoadFile
END IF
GOSUB InitDefaultPalette

FOR Index = 0 TO 3839
    Value = (Value + (Index AND 255) * 13) AND 16383
    Drawing(Index) = Value
NEXT Index

SetColorPalette
CALL ShowDrawingCells
CALL ShowDrawing
CALL ShowColorPalette
MouseFunction 1
DO
    SELECT CASE INKEY$
    CASE ""
        'check for mouse input
        CALL GetMousePos
        IF MouseChange THEN
            IF MouseButtons AND 1 THEN
                TopRow = MouseRow \ 4
                LeftCol = MouseCol \ 4
                Drawing(TopRow * DrawingWidth + LeftCol) = DrawingColor
                MouseFunction 2
                ShowDrawingCell TopRow, LeftCol
                MouseFunction 1
            END IF
            IF MouseGrabbed THEN
                'pass to item
                IF (MouseButtons AND 3) = 0 THEN MouseGrabbed = 0
            ELSEIF MouseButtons AND 3 THEN
                MouseItem = FindMouseItem(ScreenItems())
                MouseGrabbed = -1
                'pass to item
            END IF
        END IF
    CASE CHR$(27): EXIT DO
    CASE CHR$(0) + "I"
    CASE CHR$(0) + "Q"
    CASE CHR$(0) + "G"
    CASE CHR$(0) + "O"
    END SELECT
LOOP

IF DrawingChanges THEN
    IF DrawingChanges AND 1 THEN
    ELSEIF DrawingChanges AND 2 THEN
    ELSEIF DrawingChanges AND 4 THEN
    END IF
END IF
WIDTH 80, 25
SCREEN 0
END

LoadFile:
RETURN

LoadPalette:
RETURN

InitDefaultPalette:
    DEF SEG = VARSEG(ColorPalette(0))
    BytePos = VARPTR(ColorPalette(0))
    FOR Count = 0 TO 255
        RedValue = RedValue + 51
        IF RedValue > 255 THEN
            RedValue = 0
            GrnValue = GrnValue + 51
            IF GrnValue > 255 THEN
                GrnValue = 0
                BluValue = BluValue + 51
                IF BluValue > 255 THEN BluValue = 0
            END IF
        END IF
        POKE BytePos, RedValue
        POKE BytePos + 1, GrnValue
        POKE BytePos + 2, BluValue
        BytePos = BytePos + 4
    NEXT Count
RETURN

FUNCTION FindMouseItem (ScreenItems() AS ScreenItemType)

END FUNCTION

'Gets mouse cursor position (row/col) plus button states
SUB GetMousePos
    IF MouseExists THEN
        Regs.Ax = 3
        CALL InterruptX(&H33, Regs, Regs)
        MouseChange = (Regs.Bx XOR MouseButtons) AND 3
        IF Regs.Bx <> MouseButtons THEN IF MouseButtons = 0 THEN MouseChange = MouseChange OR 32
        MouseButtons = Regs.Bx
        Regs.Cx = Regs.Cx \ 2
        IF Regs.Cx <> MouseCol THEN MouseChange = MouseChange OR 128: MouseCol = Regs.Cx
        IF Regs.Dx <> MouseRow THEN MouseChange = MouseChange OR 64: MouseRow = Regs.Dx
    END IF
END SUB

SUB MouseFunction (Ax)
    Regs.Ax = Ax
    IF MouseExists THEN
      CALL InterruptX(&H33, Regs, Regs)
    ELSEIF Ax = 0 OR Ax = &H21 THEN
      CALL InterruptX(&H33, Regs, Regs)
      IF Regs.Ax = -1 THEN MouseExists = -1
    END IF
END SUB

SUB SetColorPalette
    DEF SEG = VARSEG(ColorPalette(0))
    BytePos = VARPTR(ColorPalette(0))
    FOR Count = 0 TO 255
        OUT &H3C9, PEEK(BytePos) \ 4
        OUT &H3C9, PEEK(BytePos + 1) \ 4
        OUT &H3C9, PEEK(BytePos + 2) \ 4
        BytePos = BytePos + 4
    NEXT Count
END SUB

SUB ShowColorPalette
    Count = 0
    FOR Row = 72 TO 199 STEP 4
        FOR Col = 256 TO 319 STEP 8
            LINE (Col, Row)-(Col + 7, Row + 7), Count, BF
            Count = Count + 1
        NEXT Col
    NEXT Row
    'Row = DrawingColor * 8
    'LINE (Col, Row)-(Col + 7, Row + 7), Count, BF
END SUB

SUB ShowDrawing
    Index = 0
    FOR Row = 0 TO DrawingHeight - 1
        FOR Col = 320 - DrawingWidth TO 319
            PSET (Col, Row), Drawing(Index)
            Index = Index + 1
        NEXT Col
    NEXT Row
END SUB

SUB ShowDrawingCell (TopRow, LeftCol)
    Index = TopRow * DrawingWidth + LeftCol
    Row = TopRow * DrawingPixelSize + 1
    Col = LeftCol * DrawingPixelSize + 1
    LINE (Col, Row)-(Col + 2, Row + 2), Drawing(Index), BF
END SUB

SUB ShowDrawingCells
    Index = DrawingTop * DrawingWidth + DrawingLeft
    FOR Col = 0 TO DrawingPixelWidth STEP DrawingPixelSize
        LINE (Col, 0)-(Col, DrawingPixelHeight), 1
    NEXT Col
   
    FOR Row = 1 TO DrawingPixelHeight STEP DrawingPixelSize
        LINE (0, Row - 1)-(DrawingPixelWidth, Row - 1), 1
        FOR Col = 1 TO DrawingPixelWidth STEP DrawingPixelSize
            LINE (Col, Row)-(Col + DrawingPixelSize - 2, Row + DrawingPixelSize - 2), Drawing(Index), BF
            Index = Index + 1
        NEXT Col
        Index = Index + (DrawingWidth - DrawingScreenWidth)
    NEXT Row
    LINE (0, DrawingPixelHeight)-(DrawingPixelWidth, DrawingPixelHeight), 1
END SUB

