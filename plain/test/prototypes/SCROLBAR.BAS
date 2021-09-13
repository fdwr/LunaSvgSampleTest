'2001-10-19 started
'2001-10-21 still trying to get the ratio right
'2001-10-22 ratio correct!
DEFINT A-Z
DECLARE SUB MouseFunction (Ax%)

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE
DIM SHARED Regs AS RegisterType, MousePresent, MouseRow, MouseCol

DIM SbRange     AS LONG
DIM SbRowInc    AS LONG
DIM SbPageInc   AS LONG
DIM SbValue     AS LONG
DIM SbHeight    AS LONG
DIM SbSpan      AS LONG
DIM SbMaxValue  AS LONG
DIM NewValue    AS LONG
DIM ValueMod    AS LONG

SCREEN 13
MouseFunction &H21
MouseFunction 1

GOSUB ScrollBar.Init
GOSUB ScrollBar.Redraw
DO
    MouseFunction 3
    Regs.Cx = Regs.Cx \ 2
    IF Regs.Dx <> MouseRow OR Regs.Cx <> MouseCol OR MouseButton <> Regs.Bx THEN
        MousePress = Regs.Bx AND NOT MouseButton
        MouseButton = Regs.Bx
        MouseRow = Regs.Dx
        MouseCol = Regs.Cx
        GOSUB ScrollBar.MouseMoved:
        LOCATE 3, 3: PRINT MouseButton; MouseRow; MouseCol; TAB(40);
    END IF
    Key$ = INKEY$
    IF LEN(Key$) THEN GOSUB ScrollBar.KeyPressed
LOOP UNTIL Key$ = CHR$(27)

MouseFunction 2

END

ScrollBar.Init:
    SELECT CASE 5
    CASE 0
        SbRange = 201
        SbRowInc = 1
        SbPageInc = 40
        SbValue = 0
        SbHeight = 100
    CASE 1
        SbRange = 48
        SbRowInc = 1
        SbPageInc = 40
        SbValue = 0
        SbHeight = 100
    CASE 2
        SbRange = 7
        SbRowInc = 1
        SbPageInc = 3
        SbValue = 1
        SbHeight = 100
    CASE 3
        SbRange = 140
        SbRowInc = 1
        SbPageInc = 6
        SbValue = 2
        SbHeight = 200
    CASE 4 'off slightly near bottom
        SbRange = 200
        SbRowInc = 1
        SbPageInc = 60
        SbValue = 2
        SbHeight = 200
    CASE 5
        SbRange = 18
        SbRowInc = 1
        SbPageInc = 5
        SbValue = 7
        SbHeight = 44
    END SELECT
RETURN

ScrollBar.GetSize:
    'round up bar height
    SbBarHeight = (SbPageInc * SbHeight + SbRange - 1) \ SbRange
    IF SbBarHeight < 8 THEN SbBarHeight = 8
    SbSpan = SbHeight - SbBarHeight + 1
    SbMaxValue = SbRange - SbPageInc

    SbBarRow = (SbValue * SbSpan - 1) \ SbMaxValue
    PSET (10, SbBarRow), 15
    PSET (11, SbBarRow + SbBarHeight - 1), 14
    'SbBarRow = (SbValue * SbSpan) \ SbMaxValue
    'r = ((v * h) - 1) / mv     value to row
    'r * mv = (v * h) - 1
    '(r * mv) + 1 = (v * h)
    '((r * mv) + 1) / h = v     row to value
RETURN

ScrollBar.Redraw:
    GOSUB ScrollBar.GetSize
    MouseFunction 2

    LINE (0, 0)-(7, SbHeight - 1), 7, BF
    LINE (0, SbHeight)-(7, 200), 0, BF
    LINE (0, SbBarRow)-(7, SbBarRow + SbBarHeight - 1), 11, BF
    LINE (0, 0)-(7, SbHeight - 1), 14, B, &H1111
    LOCATE 2, 3: PRINT SbValue; SbBarHeight; SbBarRow; TAB(40);
    MouseFunction 1
RETURN

ScrollBar.MouseMoved:
    GOSUB ScrollBar.GetSize

    MouseFunction 2
    SbButtonGrabbed = 0
    IF MouseRow < SbBarRow THEN
        'p = (v * s - 1) \ r

        IF MouseRow <= 0 THEN
            NewValue = 0
        ELSEIF SbMaxValue < SbSpan THEN
            'use this formula when the range is smaller than height
            NewValue = CINT((MouseRow * SbMaxValue + SbMaxValue) / SbSpan + .0000001)
            'NewValue = (MouseRow * SbMaxValue + SbMaxValue) \ SbSpan 'mostly accurate, except row 0 might be 1
        ELSE 'SbMaxValue >= SbSpan THEN
            'use this when the range is larger than height
            NewValue = (MouseRow * SbMaxValue + SbSpan) \ SbSpan
            'NewValue = (MouseRow * SbMaxValue + SbSpan) \ SbSpan 'mostly accurate, except row 0 might be 1
        END IF

        SbBarRow = (NewValue * SbSpan - 1) \ SbMaxValue
        PSET (9, SbBarRow), 12
    ELSEIF MouseRow < SbBarRow + SbBarHeight THEN
        NewValue = SbValue 'no change
        SbButtonGrabbed = 1
    ELSE
        'v = (p * r + s) \ s

        IF MouseRow + 1 >= SbHeight THEN
            NewValue = SbMaxValue
        ELSEIF SbMaxValue < SbSpan THEN
            'use this formula when the range is smaller than height
            
            ' (works best)
            NewValue = CINT(((MouseRow - SbBarHeight + 1) * SbMaxValue) / SbSpan + .0000001)
            ' (also works)
            'NewValue = SbMaxValue - ((SbHeight - MouseRow) * SbMaxValue - 1) \ SbSpan
            ' (old signed formula)
            'NewValue = ((MouseRow - SbHeight + 1) * SbMaxValue - SbMaxValue) \ SbSpan + SbMaxValue
        ELSE 'SbMaxValue >= SbSpan THEN
            'use this when the range is larger than height

            NewValue = ((MouseRow - SbBarHeight + 1) * SbMaxValue) \ SbSpan + 1
            ' (old signed formula off by one)
            'NewValue = ((MouseRow - SbHeight + 1) * SbMaxValue) \ SbSpan + SbMaxValue
        END IF
       
        SbBarRow = (NewValue * SbSpan - 1) \ SbMaxValue + SbBarHeight - 1
        PSET (8, SbBarRow), 13
    END IF
    LOCATE 1, 3: PRINT NewValue; SbBarHeight; SbBarRow; SbButtonGrabbed; TAB(40);
    MouseFunction 1

    IF MouseButton AND 1 THEN
        IF NewValue > SbRange - SbPageInc THEN NewValue = SbRange - SbPageInc
        IF NewValue <> SbValue THEN
            SbValue = NewValue
            GOTO ScrollBar.Redraw
        END IF
    END IF

RETURN

ScrollBar.KeyPressed:
    NewValue = SbValue
    SELECT CASE Key$
    CASE CHR$(0) + "H": IF SbValue > 0 THEN NewValue = SbValue - 1
    CASE CHR$(0) + "P": IF SbValue < SbRange - SbPageInc THEN NewValue = SbValue + 1
    CASE CHR$(0) + "G": NewValue = 0
    CASE CHR$(0) + "O": NewValue = SbRange - SbPageInc
    CASE ELSE: RETURN
    END SELECT
    IF NewValue <> SbValue THEN SbValue = NewValue: GOTO ScrollBar.Redraw
RETURN

ScrollBar.SyncTest:
    CLS
    WIDTH 80, 50
    PRINT "p = (v * s - 1) \ r    v = (p * r + s) \ s"
    PreValue = -1
    FOR Value = 0 TO 1000'Range
        Row = ((Value * Span) - 1) \ Range
        Value2 = ((INT(Row) * Range) + Span) \ Span
        PRINT Value; INT(Row); Row; Value2; ((Value * Span) - 1) MOD Range
        IF PreValue <> Value2 THEN
            PreValue = Value2
            IF Value <> Value2 THEN DO: LOOP UNTIL LEN(INKEY$)
        END IF
    NEXT
RETURN

'With these values, mouse row 1 does not match the drawn row
'NewValue = (MouseRow * SbMaxValue + SbMaxValue) \ SbSpan
'SbRange = 201
'SbRowInc = 1
'SbPageInc = 40
'SbValue = 0
'SbHeight = 100

SUB MouseFunction (Ax)

Regs.Ax = Ax
IF MousePresent THEN
  CALL interruptx(&H33, Regs, Regs)
ELSEIF Ax = 0 OR Ax = &H21 THEN
  CALL interruptx(&H33, Regs, Regs)
  IF Regs.Ax = -1 THEN MousePresent = -1
END IF

END SUB

