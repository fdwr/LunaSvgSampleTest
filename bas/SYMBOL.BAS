'Peekin 2001.1.1
'
'A vector based character/symbol displayer.
'
DEFINT A-Z
DECLARE SUB MouseFunction (Ax%)
DECLARE FUNCTION MouseInfo% ()
DECLARE SUB DrawShape (Shape AS ANY)
DECLARE SUB DrawSymbol (Symbol%)
DECLARE SUB GetShapeExtents (Shape AS ANY, Xlo%, Xhi%, Ylo%, Yhi%)
DECLARE SUB GetSymbolExtents (Symbol%)
DECLARE FUNCTION AddSymbolShape% (Symbol%)
DECLARE SUB DrawSymbolScaled (Symbol%)
DECLARE SUB DrawShapeScaled (Shape AS ANY)
DECLARE SUB DrawSymbolRegion (Symbol%, Xlo%, Xhi%, Ylo%, Yhi%)
DECLARE SUB DeleteSymbol (Symbol%)
DECLARE SUB DeleteShape (Shape%)
DECLARE SUB StatusLine (Text AS STRING)
DECLARE FUNCTION PointWithinHandle% (HandleX%, HandleY%, X%, Y%)
DECLARE SUB GetSymbolHandle (Symbol%, X%, Y%, Shape%, ShpHnd%)
DECLARE FUNCTION GetShapeHandle% (Shape AS ANY, X%, Y%)

CONST ShpTypePoint = 0, ShpTypLine = 1, ShpTypCircle = 2, ShpTypArc = 3
CONST ShapePreviewSize = 28, ShapePreviewWrap = 16
CONST MenuWidth = 64, MenuHeight = 200
CONST ShapeWindowWidth = 448, PreviewWindowHeight = 448, ShapeWindowLeft = 192
CONST ShpHndPos = 0, ShpHndLine1 = 1, ShpHndLine2 = 2, ShpHndRadius = 3, ShpHndArc1 = 4, ShpHndArc2 = 5
CONST ToolPan = 0, ToolAdjust = 1, ToolPoint = 2, ToolLine = 3, ToolCircle = 4, ToolArc = 5, ToolDelete = 6, ToolInfo = 7
CONST ToolAdjustPos = 0, ToolAdjustLine1 = 1, ToolAdjustLine2 = 2, ToolAdjustRadius = 3

TYPE SymbolShapeType
Sym AS INTEGER 'index of symbol that shape belongs to
Shp AS INTEGER 'type of shape, point, line, circle, arc
X   AS INTEGER 'offset from symbol center
Y   AS INTEGER
A   AS INTEGER 'depending on the shape type, these can be either X2 and Y2
B   AS INTEGER 'or the start and end of an arc
R   AS INTEGER 'radius
END TYPE

TYPE SymbolInfoType
Shp   AS INTEGER 'index of first shape for symbol
Xlo   AS INTEGER 'lowest X coordinate in symbol
Xhi   AS INTEGER 'highest X coordinate
Ylo   AS INTEGER
Yhi   AS INTEGER
Parts AS INTEGER
END TYPE

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
BP AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

CONST MaxShapes = 1000, MaxSymbols = 256
CONST MaxMenuChoices = 20

DIM SHARED Shapes(MaxShapes - 1) AS SymbolShapeType, TotalShapes
DIM SHARED SymbolInfo(MaxSymbols - 1) AS SymbolInfoType, TotalSymbols
DIM SHARED ShapesX, ShapesY, ShapesColor, ShapesMul, ShapesDraw, ShapesDiv, ShapesShowHnd
DIM MenuText(MaxMenuChoices - 1) AS STRING
DIM UndoShape AS SymbolShapeType
DIM ShapeFile AS STRING

DIM SHARED MousePresent, MouseButtons, MousePresses, MouseReleases, MouseY, MouseX, MouseClickTime AS SINGLE
DIM SHARED Regs AS RegisterType



SCREEN 12
MouseFunction &H21
MouseFunction 1

ShapesMul = 1
ShapesDiv = 10
ShapesColor = 9
ShapesDraw = 3
ToolSelected = ToolAdjust
ShapeFile = "symbols.dat"
GOSUB LoadShapes
GOSUB GetAllSymbolExtents

SelectedSymbol = 0
GOSUB SelectSymbol

MouseFunction 2
SCREEN 0 'Regs.Ax = 3: CALL Interruptx(&H10, Regs, Regs)
END


ClearShapes:
    REDIM SymbolInfo(MaxShapes - 1)
    FOR Count = 0 TO MaxSymbols - 1
        SymbolInfo(Count).Shp = MaxShapes
    NEXT Count
    'FOR Count = 0 TO MaxShapes - 1
    '    Shapes(Count).Sym = MaxSymbols
    'NEXT Count
    TotalSymbols = 0
    TotalShapes = 0
RETURN


LoadShapes:
    'GOSUB ClearShapes
    'RESTORE DefaultShapeData
    'DO
    '    READ Symbol
    '    IF Symbol < 0 THEN
    '        RETURN
    '    ELSEIF Symbol >= TotalSymbols THEN
    '        SymbolInfo(Symbol).Shp = TotalShapes
    '        TotalSymbols = Symbol + 1
    '    END IF
    '    READ Shapes(TotalShapes).Shp, Shapes(TotalShapes).X, Shapes(TotalShapes).Y, Shapes(TotalShapes).A, Shapes(TotalShapes).B, Shapes(TotalShapes).R
    '    Shapes(TotalShapes).Sym = Symbol
    '    TotalShapes = TotalShapes + 1
    'LOOP
    'RETURN

    GOSUB CatchErr: OPEN ShapeFile FOR INPUT AS 1
    ON ERROR GOTO 0: IF ErrHandled THEN RETURN
    GOSUB ClearShapes
    CLOSE 1: OPEN ShapeFile FOR BINARY AS 1
    StatusLine "Loading shapes"
  
    GET 1, , Version
    TotalShapes = 0
    TotalSymbols = 0
    Symbol = -1
    DO UNTIL TotalShapes >= MaxShapes
        GET 1, , Shapes(TotalShapes)
        IF EOF(1) THEN EXIT DO
        IF Shapes(TotalShapes).Sym <> Symbol THEN
            Symbol = Shapes(TotalShapes).Sym
            IF SymbolInfo(Symbol).Shp >= MaxShapes THEN
                IF Symbol < MaxSymbols THEN
                    SymbolInfo(Symbol).Shp = TotalShapes
                    TotalSymbols = TotalSymbols + 1
                END IF
            END IF
        END IF
        TotalShapes = TotalShapes + 1
    LOOP

    CLOSE 1
    StatusLine "Loaded" + STR$(TotalShapes) + " shapes"
RETURN


GetAllSymbolExtents:
    FOR Count = 0 TO MaxSymbols - 1
        GetSymbolExtents Count
    NEXT
RETURN


StoreShapes:
    OPEN ShapeFile FOR OUTPUT AS 1: CLOSE 1
    OPEN ShapeFile FOR BINARY AS 1
    StatusLine "Storing shapes"

    Version = 0
    PUT 1, , Version
    FOR Count = 0 TO TotalShapes - 1
        IF Shapes(Count).Sym < MaxSymbols THEN
            PUT 1, , Shapes(Count)
        END IF
    NEXT
    StatusLine "Stored" + STR$(TotalShapes) + " shapes"

    CLOSE 1
RETURN


ReadMenuChoices:
    DO
        READ Text$
        IF LEN(Text$) <= 0 THEN EXIT DO
        MenuText(TotalMenuChoices) = Text$
        TotalMenuChoices = TotalMenuChoices + 1
    LOOP
RETURN


DisplayMenu:
    FOR Count = 0 TO TotalMenuChoices - 1
        LOCATE Count + 1, 1
        PRINT MenuText(Count);
    NEXT
RETURN


GetMenuChoice:
    MenuChoice = MouseY \ 16
    IF MenuChoice >= MaxMenuChoices THEN MenuChoice = -1: RETURN
    IF MouseX \ 8 >= LEN(MenuText(MenuChoice)) THEN MenuChoice = -1: RETURN
RETURN


SelectSymbol:
    TotalMenuChoices = 0
    RESTORE SelSymMenuChoices
    GOSUB ReadMenuChoices

    PageRedraw = 15
    DO
        Key$ = INKEY$
        IF LEN(Key$) THEN
            SELECT CASE Key$
            CASE CHR$(0) + "H": SelectedSymbol = SelectedSymbol - 16: GOSUB SelectNewSymbol
            CASE CHR$(0) + "P": SelectedSymbol = SelectedSymbol + 16: GOSUB SelectNewSymbol
            CASE CHR$(0) + "K": SelectedSymbol = SelectedSymbol - 1:  GOSUB SelectNewSymbol
            CASE CHR$(0) + "M": SelectedSymbol = SelectedSymbol + 1:  GOSUB SelectNewSymbol
            CASE CHR$(0) + "S": GOSUB DeleteSelectedSymbol
            CASE "P"
                PRINT
                FOR Count = 0 TO TotalShapes - 1
                    PRINT Shapes(Count).Sym; Shapes(Count).Shp; Shapes(Count).X; Shapes(Count).Y
                NEXT
            CASE "S"
                PRINT
                FOR Count = 0 TO TotalSymbols - 1
                    PRINT SymbolInfo(Count).Shp
                NEXT
            CASE CHR$(13): GOSUB EditSymbol: GOTO SelectSymbol
            CASE CHR$(19): GOSUB StoreShapes
            CASE CHR$(12)
                GOSUB LoadShapes
                GOSUB GetAllSymbolExtents
                PageRedraw = 7
            CASE CHR$(27): EXIT DO
            END SELECT
        ELSEIF MouseInfo > 1 THEN
            IF MouseX >= ShapeWindowLeft THEN
                SelectedSymbol = ((MouseX - ShapeWindowLeft) \ ShapePreviewSize) + ((MouseY \ ShapePreviewSize) * ShapePreviewWrap)
                IF MousePresses THEN
                    IF MouseClickTime < .3 THEN
                        GOSUB EditSymbol
                        GOTO SelectSymbol
                    ELSE
                        GOSUB SelectNewSymbol
                    END IF
                END IF
            ELSEIF MousePresses THEN
                GOSUB GetMenuChoice
                SELECT CASE MenuChoice
                CASE 0: EXIT DO
                CASE 1, 2
                    GOSUB LoadShapes
                    GOSUB GetAllSymbolExtents
                    PageRedraw = 7
                CASE 3, 4: GOSUB StoreShapes
                CASE 5: GOSUB EditSymbol: GOTO SelectSymbol
                CASE 9: GOSUB DeleteSelectedSymbol
                END SELECT
            END IF
        ELSE
            'Delay& = Delay& + 1
            'IF Delay& > 20000 THEN Delay& = 0
            GOSUB SelectSymbolRedraw
        END IF
    LOOP
RETURN


SelectSymbolRedraw:
    IF PageRedraw = 0 THEN RETURN
    MouseFunction 2
    IF PageRedraw AND 12 THEN
        IF PageRedraw AND 8 THEN
            LINE (0, 0)-(639, PreviewWindowHeight - 1), 0, BF
            GOSUB DisplayMenu
        ELSE
            LINE (ShapeWindowLeft, 0)-(639, PreviewWindowHeight - 1), 0, BF
        END IF
        Symbol = 0
    END IF
    IF PageRedraw AND 2 THEN
        X = (OldSelectedSymbol AND 15) * ShapePreviewSize + ShapeWindowLeft
        Y = (OldSelectedSymbol \ ShapePreviewWrap) * ShapePreviewSize
        LINE (X, Y)-(X + ShapePreviewSize - 1, Y + ShapePreviewSize - 1), 0, B
        X = (SelectedSymbol AND 15) * ShapePreviewSize + ShapeWindowLeft
        Y = (SelectedSymbol \ ShapePreviewWrap) * ShapePreviewSize
        LINE (X, Y)-(X + ShapePreviewSize - 1, Y + ShapePreviewSize - 1), 15, B
        OldSelectedSymbol = SelectedSymbol

        LOCATE 30, 1
        PRINT "Symbol:"; SelectedSymbol; TAB(15);
        PRINT "Height:"; SymbolInfo(SelectedSymbol).Yhi - SymbolInfo(SelectedSymbol).Ylo; TAB(30);
        PRINT "Width:"; SymbolInfo(SelectedSymbol).Xhi - SymbolInfo(SelectedSymbol).Xlo; TAB(45);
        PRINT "Parts:"; SymbolInfo(SelectedSymbol).Parts; TAB(60);
        PRINT "Shapes:"; SymbolInfo(SelectedSymbol).Shp; "-"; SymbolInfo(SelectedSymbol).Shp + SymbolInfo(SelectedSymbol).Parts - 1; TAB(80);
    END IF
    IF PageRedraw AND 1 THEN
        IF Symbol < MaxSymbols THEN
            ShapesX = (Symbol AND 15) * ShapePreviewSize + ShapeWindowLeft + ShapePreviewSize \ 2
            ShapesY = (Symbol \ 16) * ShapePreviewSize + ShapePreviewSize \ 2
            PSET (ShapesX, ShapesY), 12
           
            X = ABS(SymbolInfo(Symbol).Xlo)
            IF X < SymbolInfo(Symbol).Xhi THEN X = SymbolInfo(Symbol).Xhi
            Y = ABS(SymbolInfo(Symbol).Ylo)
            IF Y < SymbolInfo(Symbol).Yhi THEN Y = SymbolInfo(Symbol).Yhi
            IF X > Y THEN ShapesDiv = X + X ELSE ShapesDiv = Y + Y
            IF ShapesDiv <= ShapePreviewSize - 4 THEN
                DrawSymbol Symbol
            ELSE
                ShapesMul = ShapePreviewSize - 4
                DrawSymbolScaled Symbol
            END IF
            'LINE (ShapesX + SymbolInfo(Symbol).Xlo, ShapesY + SymbolInfo(Symbol).Ylo)-(ShapesX + SymbolInfo(Symbol).Xhi, ShapesY + SymbolInfo(Symbol).Yhi), 13, B, &H1111
            Symbol = Symbol + 1
        ELSE
            PageRedraw = 0
            'PageRedraw = PageRedraw XOR 1
        END IF
    END IF
    PageRedraw = PageRedraw AND 1
    MouseFunction 1
RETURN


SelectNewSymbol:
    SelectedSymbol = (SelectedSymbol + MaxSymbols) MOD MaxSymbols
    PageRedraw = PageRedraw OR 2
RETURN


DeleteSelectedSymbol:
    DeleteSymbol SelectedSymbol
    X = (SelectedSymbol AND 15) * ShapePreviewSize + ShapeWindowLeft
    Y = (SelectedSymbol \ ShapePreviewWrap) * ShapePreviewSize
    LINE (X, Y)-(X + ShapePreviewSize - 1, Y + ShapePreviewSize - 1), 0, BF
    StatusLine "Deleted symbol" + STR$(SelectedSymbol)
    SelectedSymbol = SelectedSymbol + 1
    GOTO SelectNewSymbol
'RETURN


EditSymbol:
    TotalMenuChoices = 0
    RESTORE EditSymMenuChoices
    GOSUB ReadMenuChoices
   
    MouseFunction 2
    CLS
    GOSUB DisplayMenu
    PageRedraw = 1
    'LINE (0, 0)-(255, 383), 11, B
    ShapesX = 320
    ShapesY = 240
    ShapesColor = 7
    ShapesDraw = 1
    DrawSymbol 0
    ShapesColor = 9
    ShapesDraw = 3
    DrawSymbol SelectedSymbol
    MouseFunction 1
    SelectedShape = -1
   
    DO
        Key$ = INKEY$
        IF LEN(Key$) THEN
            SELECT CASE Key$
            CASE CHR$(27): EXIT DO
            END SELECT
        ELSEIF MouseInfo THEN
            IF MouseX >= MenuWidth THEN
                ShapePtX = MouseX - ShapesX
                ShapePtY = MouseY - ShapesY
                ShapeGrabX = ShapePtX
                ShapeGrabY = ShapePtY
                GOSUB EditSymbolGridAlign
                PageRedraw = 1
                IF MousePresses THEN
                    SELECT CASE ToolSelected
                    CASE ToolPan
                        ShapesDraw = 2
                        MouseFunction 2
                        DrawSymbol SelectedSymbol
                        ShapesX = 320 - ShapePtX
                        ShapesY = 240 - ShapePtY
                        ShapesDraw = 3
                        DrawSymbol SelectedSymbol
                        MouseFunction 1
                    CASE ToolAdjust
                        GetSymbolHandle SelectedSymbol, ShapeGrabX, ShapeGrabY, SelectedShape, ShapeHnd
                        IF SelectedShape >= 0 THEN
                            IF ShapeHnd = ShpHndLine1 THEN
                                ShapeGrabX = Shapes(SelectedShape).X - ShapeGrabX
                                ShapeGrabY = Shapes(SelectedShape).Y - ShapeGrabY
                            ELSE
                                ShapeGrabX = 0
                                ShapeGrabY = 0
                            END IF
                        END IF
                    CASE ToolPoint, ToolLine, ToolCircle, ToolArc
                        SelectedShape = AddSymbolShape(SelectedSymbol)
                        SelectedShapeType = ToolSelected - 2
                        Shapes(SelectedShape).X = ShapePtX
                        Shapes(SelectedShape).Y = ShapePtY
                        Shapes(SelectedShape).Shp = SelectedShapeType
                        SELECT CASE ToolSelected
                        CASE ToolLine
                            Shapes(SelectedShape).A = 0
                            Shapes(SelectedShape).B = 0
                            ShapeHnd = ShpHndLine2
                        CASE ToolCircle, ToolArc
                            Shapes(SelectedShape).R = 10
                            ShapeHnd = ShpHndRadius
                        END SELECT
                        MouseFunction 2
                        DrawShape Shapes(SelectedShape)
                        MouseFunction 1
                    CASE ToolDelete
                        GetSymbolHandle SelectedSymbol, ShapePtX, ShapePtY, SelectedShape, ShapeHnd
                        IF SelectedShape >= 0 THEN
                            ShapesDraw = 2
                            MouseFunction 2
                            DrawShape Shapes(SelectedShape)
                            MouseFunction 1
                            ShapesDraw = 3
                            DeleteShape SelectedShape
                        END IF
                    CASE ToolInfo
                        GetSymbolHandle SelectedSymbol, ShapePtX, ShapePtY, SelectedShape, ShapeHnd
                        IF SelectedShape >= 0 THEN
                            'IF SelectedShape >= 0 THEN DrawShape Shapes(SelectedShape)
                            GetShapeExtents Shapes(SelectedShape), Xlo, Xhi, Ylo, Yhi
                            LOCATE 23, 1: PRINT Xlo; Xhi; ":"; Ylo; Yhi; "="; Xhi - Xlo; "x"; Yhi - Ylo;
                        END IF
                    END SELECT
                ELSEIF MouseReleases THEN
                    SelectedShape = -1
                    SELECT CASE ToolSelected
                    CASE ToolAdjust
                        ShapesDraw = 3
                        DrawSymbol SelectedSymbol
                    END SELECT
                ELSE
                    SELECT CASE ToolSelected
                    CASE ToolAdjust, ToolCircle, ToolLine, ToolArc
                        IF SelectedShape >= 0 THEN
                            'get active shape extents for redrawing other shapes
                            GetShapeExtents Shapes(SelectedShape), Xlo, Xhi, Ylo, Yhi
                            PageRedraw = PageRedraw OR 2

                            MouseFunction 2
                            ShapesDraw = 2
                            DrawShape Shapes(SelectedShape)
                            SELECT CASE ShapeHnd
                            CASE ShpHndPos
                                Shapes(SelectedShape).X = ShapePtX + ShapeGrabX
                                Shapes(SelectedShape).Y = ShapePtY + ShapeGrabY
                            CASE ShpHndLine1
                                X = ShapePtX - Shapes(SelectedShape).X
                                Y = ShapePtY - Shapes(SelectedShape).Y
                                Shapes(SelectedShape).X = ShapePtX
                                Shapes(SelectedShape).Y = ShapePtY
                                Shapes(SelectedShape).A = Shapes(SelectedShape).A - X
                                Shapes(SelectedShape).B = Shapes(SelectedShape).B - Y
                            CASE ShpHndLine2
                                Shapes(SelectedShape).A = ShapePtX - Shapes(SelectedShape).X
                                Shapes(SelectedShape).B = ShapePtY - Shapes(SelectedShape).Y
                            CASE ShpHndRadius
                                Shapes(SelectedShape).R = ABS(ShapePtY - Shapes(SelectedShape).Y)
                            CASE ShpHndArc1, ShpHndArc2
                                ShapeGrabX = ShapePtX - Shapes(SelectedShape).X
                                ShapeGrabY = ShapePtY - Shapes(SelectedShape).Y
                                IF ShapeGrabY > 0 THEN
                                    Angle = ATN(ShapeGrabX / ShapeGrabY) * 2607.597 + 12288
                                ELSEIF ShapeGrabY < 0 THEN
                                    Angle = ATN(ShapeGrabX / ShapeGrabY) * 2607.597 + 4096
                                ELSEIF ShapeGrabX >= 0 THEN
                                    IF ShapeHnd = ShpHndArc2 THEN Angle = 16384 ELSE Angle = 0
                                ELSE 'ShapeGrabX < 0
                                    Angle = 8192
                                END IF
                                IF ShapeHnd = ShpHndArc1 THEN
                                    Shapes(SelectedShape).A = Angle
                                ELSE
                                    Shapes(SelectedShape).B = Angle
                                END IF
                            END SELECT
                            ShapesDraw = 3
                            DrawShape Shapes(SelectedShape)
                            MouseFunction 1
                            'redraw all affected shapes
                        END IF
                    END SELECT
                END IF
            ELSEIF MousePresses THEN
                GOSUB GetMenuChoice
                SELECT CASE MenuChoice
                CASE 0: EXIT DO
                CASE 1 TO 8
                    ToolSelected = MenuChoice - 1
                END SELECT
            END IF
        ELSE
            GOSUB EditSymbolRedraw
        END IF
    LOOP
    GetSymbolExtents SelectedSymbol
RETURN


EditSymbolRedraw:
    IF PageRedraw = 0 THEN RETURN
    MouseFunction 2
    IF PageRedraw AND 1 THEN
        LOCATE 30, 1: PRINT "X:"; ShapePtX; "Y:"; ShapePtY; TAB(20);
    END IF
    IF PageRedraw AND 2 THEN
        ShapesDraw = 1
        ShapesColor = 7
        DrawSymbolRegion 0, Xlo, Xhi, Ylo, Yhi
        ShapesDraw = 3
        ShapesColor = 9
        DrawSymbolRegion SelectedSymbol, Xlo, Xhi, Ylo, Yhi
    END IF
    PageRedraw = 0
    MouseFunction 1
RETURN


EditSymbolGridAlign:
    ShapePtX = ShapePtX - (ShapePtX MOD 5)
    ShapePtY = ShapePtY - (ShapePtY MOD 5)
RETURN


CatchErr:
    ON ERROR GOTO ErrHandler
    ErrHandled = 0
RETURN


ErrHandler:
    ErrHandled = ERR
RESUME NEXT


DefaultShapeData:
'Box
DATA 0,1,-100,-100,200,0,0
DATA 0,1,-100,-100,0,200,0
DATA 0,1,100,100,-200,0,0
DATA 0,1,100,100,0,-200,0
DATA 0,1,-100,0,200,0,0
DATA 0,1,0,-100,0,200,0
'A
DATA 1,1,0,-100,-100,200,0
DATA 1,1,0,-100,100,200,0
DATA 1,1,-50,0,100,0,0
'E
DATA 2,1,-100,-100,0,200,0
DATA 2,1,-100,-100,200,0,0
DATA 2,1,-100,0,200,0,0
DATA 2,1,-100,100,200,0,0
'O
DATA 3,2,0,0,0,0,100
'Z
DATA 4,1,-100,-100,200,0,0
DATA 4,1,100,-100,-200,200,0
DATA 4,1,-100,100,200,0,0
'C
DATA 5,3,0,0,2048,14336,100
'H
DATA 6,1,-100,-100,0,200,0
DATA 6,1,100,-100,0,200,0
DATA 6,1,-100,0,200,0,0
'End of symbol shapes
DATA -1

SelSymMenuChoices:
DATA "Quit"
DATA "Load"
DATA "Revert"
DATA "Update"
DATA "Store"
DATA "Edit"
DATA "Get"
DATA "Put"
DATA "Merge"
DATA "Delete"
DATA ""

EditSymMenuChoices:
DATA "Exit"
DATA "Pan"
DATA "Adjust"
DATA "Point"
DATA "Line"
DATA "Circle"
DATA "Arc"
DATA "Delete"
'DATA "FlipH"
DATA "Info"
DATA "FlipV"
DATA "Grid"
DATA "Clear"
DATA ""

FUNCTION AddSymbolShape (Symbol)
'adds another shape to a symbol, inserting it between between any others,
'returning the index of the new shape

AddSymbolShape = MaxShapes - 1
Count = SymbolInfo(Symbol).Shp + 1
DO UNTIL Count >= TotalShapes
    IF Shapes(Count).Sym <> Symbol THEN
        AddSymbolShape = Count
        IF Shapes(Count).Sym >= MaxSymbols THEN
            Shapes(Count).Sym = Symbol
            EXIT FUNCTION
        END IF
        IF TotalShapes >= MaxShapes THEN EXIT FUNCTION
        PrevSymbol = -1
        FOR Count = TotalShapes TO Count + 1 STEP -1
            Shapes(Count) = Shapes(Count - 1)
            IF Shapes(Count).Sym <> PrevSymbol THEN
                PrevSymbol = Shapes(Count).Sym
                SymbolInfo(PrevSymbol).Shp = SymbolInfo(PrevSymbol).Shp + 1
            END IF
        NEXT
        Shapes(Count).Sym = Symbol
        TotalShapes = TotalShapes + 1
        EXIT FUNCTION
    END IF
    Count = Count + 1
LOOP
IF Count >= TotalShapes THEN
    IF SymbolInfo(Symbol).Shp >= TotalShapes THEN
        SymbolInfo(Symbol).Shp = TotalShapes
    END IF
    Shapes(TotalShapes).Sym = Symbol
    AddSymbolShape = TotalShapes
    TotalShapes = TotalShapes + 1
END IF

END FUNCTION

SUB DeleteShape (Shape)

Count = SymbolInfo(Symbol).Shp
Symbol = Shapes(Shape).Sym
IF Symbol >= MaxSymbols THEN EXIT SUB
FOR Count = Shape TO TotalShapes - 2
    IF Shapes(Count + 1).Sym <> Symbol THEN EXIT FOR
    Shapes(Count) = Shapes(Count + 1)
NEXT
Shapes(Count).Sym = MaxSymbols
IF Count = SymbolInfo(Symbol).Shp THEN
    SymbolInfo(Symbol).Shp = MaxShapes
    TotalSymbols = TotalSymbols - 1
END IF

END SUB

SUB DeleteSymbol (Symbol)

DIM EmptySymbol AS SymbolInfoType
EmptySymbol.Shp = MaxShapes
Count = SymbolInfo(Symbol).Shp
DO UNTIL Count >= TotalShapes
    IF Shapes(Count).Sym = Symbol THEN
        Shapes(Count).Sym = MaxSymbols
    'ELSE
    '    EXIT DO
    END IF
    Count = Count + 1
LOOP
SymbolInfo(Symbol) = EmptySymbol
TotalSymbols = TotalSymbols - 1

END SUB

SUB DrawShape (Shape AS SymbolShapeType)

IF ShapesDraw AND 1 THEN
    ShpColor = ShapesColor
    HndColor = 15
ELSE
    ShpColor = 0
    HndColor = 0
END IF

X = ShapesX + Shape.X
Y = ShapesY + Shape.Y

SELECT CASE Shape.Shp
CASE ShpTypPoint
    PSET (X, Y), ShpColor
    IF ShapesDraw AND 2 THEN
        CIRCLE (X, Y), 3, HndColor
    END IF
CASE ShpTypLine
    LINE (X, Y)-(X + Shape.A, Y + Shape.B), ShpColor
    IF ShapesDraw AND 2 THEN
        CIRCLE (X, Y), 3, HndColor
        CIRCLE (X + Shape.A \ 2, Y + Shape.B \ 2), 3, HndColor
        CIRCLE (X + Shape.A, Y + Shape.B), 3, HndColor
    END IF
CASE ShpTypCircle
    CIRCLE (X, Y), Shape.R, ShpColor
    IF ShapesDraw AND 2 THEN
        CIRCLE (X, Y), 3, HndColor
        CIRCLE (X, Y + Shape.R), 3, HndColor
        CIRCLE (X, Y - Shape.R), 3, HndColor
    END IF
CASE ShpTypArc
    '0=start 16384=end
    'Qbasic draw only a single pixel if the start and end are too close
    IF ABS(Shape.A - Shape.B) < 40 THEN
        CIRCLE (X, Y), Shape.R, ShpColor
    ELSE
        CIRCLE (X, Y), Shape.R, ShpColor, Shape.A / 2607.597, Shape.B / 2607.597
    END IF
    IF ShapesDraw AND 2 THEN
        CIRCLE (X, Y), 3, HndColor
        CIRCLE (X, Y + Shape.R), 3, HndColor
        CIRCLE (X + COS(Shape.A / 2607.597) * Shape.R, Y - SIN(Shape.A / 2607.597) * Shape.R), 3, HndColor
        CIRCLE (X + COS(Shape.B / 2607.597) * Shape.R, Y - SIN(Shape.B / 2607.597) * Shape.R), 3, HndColor
    END IF
END SELECT

END SUB

SUB DrawShapeScaled (Shape AS SymbolShapeType)

X = Shape.X * ShapesMul \ ShapesDiv
Y = Shape.Y * ShapesMul \ ShapesDiv

SELECT CASE Shape.Shp
CASE ShpTypPoint
    PSET (ShapesX + X, ShapesY + Y), ShapesColor
CASE ShpTypLine
    LINE (ShapesX + X, ShapesY + Y)-(ShapesX + (Shape.X + Shape.A) * ShapesMul \ ShapesDiv, ShapesY + (Shape.Y + Shape.B) * ShapesMul \ ShapesDiv), ShapesColor
CASE ShpTypCircle
    CIRCLE (ShapesX + X, ShapesY + Y), Shape.R * ShapesMul \ ShapesDiv, ShapesColor
CASE ShpTypArc
    '0=start 16384=end
    'Qbasic draw only a single pixel if the start and end are too close
    IF ABS(Shape.A - Shape.B) < 40 THEN
        CIRCLE (ShapesX + X, ShapesY + Y), Shape.R * ShapesMul \ ShapesDiv, ShapesColor
    ELSE
        CIRCLE (ShapesX + X, ShapesY + Y), Shape.R * ShapesMul \ ShapesDiv, ShapesColor, Shape.A / 2607.597, Shape.B / 2607.597
    END IF
END SELECT

END SUB

SUB DrawSymbol (Symbol)

Count = SymbolInfo(Symbol).Shp
DO UNTIL Count >= TotalShapes
    IF Shapes(Count).Sym <> Symbol THEN EXIT DO
    DrawShape Shapes(Count)
    Count = Count + 1
LOOP

END SUB

SUB DrawSymbolRegion (Symbol, Xlft, Xrit, Ytop, Ybtm)

Count = SymbolInfo(Symbol).Shp
'LINE (ShapesX + Xlft, ShapesY + Ytop)-(ShapesX + Xrit, ShapesY + Ybtm), INT(RND * 16), BF
DO UNTIL Count >= TotalShapes
    IF Shapes(Count).Sym <> Symbol THEN EXIT DO
    GetShapeExtents Shapes(Count), Xlo, Xhi, Ylo, Yhi
    'LINE (ShapesX + Xlo, ShapesY + Ylo)-(ShapesX + Xhi, ShapesY + Yhi), INT(RND * 16), BF
    IF Xlo <= Xrit AND Xhi >= Xlft AND Ylo <= Ybtm AND Yhi >= Ytop THEN
        DrawShape Shapes(Count)
    END IF
    Count = Count + 1
LOOP

END SUB

SUB DrawSymbolScaled (Symbol)

Count = SymbolInfo(Symbol).Shp
DO UNTIL Count >= TotalShapes
    IF Shapes(Count).Sym <> Symbol THEN EXIT DO
    DrawShapeScaled Shapes(Count)
    Count = Count + 1
LOOP

END SUB

SUB GetShapeExtents (Shape AS SymbolShapeType, Xlo, Xhi, Ylo, Yhi)

SELECT CASE Shape.Shp
CASE ShpTypPoint
    Xlo = Shape.X
    Ylo = Shape.Y
    Xhi = Xlo
    Yhi = Ylo
CASE ShpTypLine
    Xlo = Shape.X
    Ylo = Shape.Y
    Xhi = Shape.X + Shape.A
    Yhi = Shape.Y + Shape.B
    IF Xlo > Xhi THEN SWAP Xlo, Xhi
    IF Ylo > Yhi THEN SWAP Ylo, Yhi
CASE ShpTypCircle, ShpTypArc
    Xlo = Shape.X - Shape.R
    Ylo = Shape.Y - Shape.R
    Xhi = Shape.X + Shape.R
    Yhi = Shape.Y + Shape.R
CASE ELSE
    Xlo = 0: Xhi = 0
    Ylo = 0: Xlo = 0
END SELECT


END SUB

FUNCTION GetShapeHandle (Shape AS SymbolShapeType, X, Y)

GetShapeHandle = -1

SELECT CASE Shape.Shp
CASE ShpTypPoint
    IF PointWithinHandle(Shape.X, Shape.Y, X, Y) THEN
        GetShapeHandle = ShpHndPos
    END IF
CASE ShpTypLine
    IF PointWithinHandle(Shape.X, Shape.Y, X, Y) THEN
        GetShapeHandle = ShpHndLine1
    ELSEIF PointWithinHandle(Shape.X + Shape.A, Shape.Y + Shape.B, X, Y) THEN
        GetShapeHandle = ShpHndLine2
    ELSEIF PointWithinHandle(Shape.X + Shape.A \ 2, Shape.Y + Shape.B \ 2, X, Y) THEN
        GetShapeHandle = ShpHndPos
    END IF
CASE ShpTypCircle
    IF PointWithinHandle(Shape.X, Shape.Y, X, Y) THEN
        GetShapeHandle = ShpHndPos
    ELSEIF PointWithinHandle(Shape.X, Shape.Y + Shape.R, X, Y) THEN
        GetShapeHandle = ShpHndRadius
    ELSEIF PointWithinHandle(Shape.X, Shape.Y - Shape.R, X, Y) THEN
        GetShapeHandle = ShpHndRadius
    'ELSEIF Shape.R > 0 THEN
    '    R = SQR(CLNG(X) * X + CLNG(Y) * Y)
    '    IF R >= Shape.R - 5 AND R <= Shape.R + 5 THEN
    '        GetShapeHandle = ShpHndPos
    '    END IF
    END IF
CASE ShpTypArc
    '0=start 16384=end
    IF PointWithinHandle(Shape.X + COS(Shape.A / 2607.597) * Shape.R, Shape.Y - SIN(Shape.A / 2607.597) * Shape.R, X, Y) THEN
        GetShapeHandle = ShpHndArc1
    ELSEIF PointWithinHandle(Shape.X + COS(Shape.B / 2607.597) * Shape.R, Shape.Y - SIN(Shape.B / 2607.597) * Shape.R, X, Y) THEN
        GetShapeHandle = ShpHndArc2
    ELSEIF PointWithinHandle(Shape.X, Shape.Y, X, Y) THEN
        GetShapeHandle = ShpHndPos
    ELSEIF PointWithinHandle(Shape.X, Shape.Y + Shape.R, X, Y) THEN
        GetShapeHandle = ShpHndRadius
    END IF
END SELECT

END FUNCTION

SUB GetSymbolExtents (Symbol)

Count = SymbolInfo(Symbol).Shp
IF Count >= TotalShapes THEN EXIT SUB
GetShapeExtents Shapes(Count), Xlo, Xhi, Ylo, Yhi
SymbolInfo(Symbol).Xlo = Xlo
SymbolInfo(Symbol).Xhi = Xhi
SymbolInfo(Symbol).Ylo = Ylo
SymbolInfo(Symbol).Yhi = Yhi
Parts = 1
Count = Count + 1
DO UNTIL Count >= TotalShapes
    IF Shapes(Count).Sym <> Symbol THEN EXIT DO
    GetShapeExtents Shapes(Count), Xlo, Xhi, Ylo, Yhi
    IF SymbolInfo(Symbol).Xlo > Xlo THEN SymbolInfo(Symbol).Xlo = Xlo
    IF SymbolInfo(Symbol).Xhi < Xhi THEN SymbolInfo(Symbol).Xhi = Xhi
    IF SymbolInfo(Symbol).Ylo > Ylo THEN SymbolInfo(Symbol).Ylo = Ylo
    IF SymbolInfo(Symbol).Yhi < Yhi THEN SymbolInfo(Symbol).Yhi = Yhi
    Parts = Parts + 1
    Count = Count + 1
LOOP
SymbolInfo(Symbol).Parts = Parts

END SUB

SUB GetSymbolHandle (Symbol, X, Y, Shape, ShpHnd)

Count = SymbolInfo(Symbol).Shp
Shape = -1
DO UNTIL Count >= TotalShapes
    IF Shapes(Count).Sym <> Symbol THEN EXIT DO
    ShpHnd = GetShapeHandle(Shapes(Count), X, Y)
    IF ShpHnd >= 0 THEN
        Shape = Count
        EXIT DO
    END IF
    Count = Count + 1
LOOP

END SUB

SUB MouseFunction (Ax)

Regs.Ax = Ax
IF MousePresent THEN
  CALL Interruptx(&H33, Regs, Regs)
ELSEIF Ax = &H21 THEN
  CALL Interruptx(&H33, Regs, Regs)
  IF Regs.Ax <> 0 THEN MousePresent = -1
END IF

END SUB

FUNCTION MouseInfo
STATIC OldY, OldX, OldButtons, LastPress AS SINGLE

IF MousePresent = 0 THEN EXIT FUNCTION

Regs.Ax = 3
CALL Interruptx(&H33, Regs, Regs)
MouseY = Regs.Dx
MouseX = Regs.Cx' \ 2
MouseButtons = Regs.Bx

IF OldY <> MouseY OR OldX <> MouseX THEN
    OldY = MouseY: OldX = MouseX
    MouseInfo = 1
END IF
IF MouseButtons <> OldButtons THEN
    MousePresses = MouseButtons XOR OldButtons
    MouseReleases = NOT MouseButtons AND OldButtons
    MousePresses = MousePresses AND MouseButtons
    IF MousePresses THEN MouseClickTime = TIMER - LastPress: LastPress = TIMER
    MouseInfo = 2
ELSE
    MousePresses = 0
    MouseReleases = 0
END IF
OldButtons = MouseButtons

END FUNCTION

FUNCTION PointWithinHandle (HandleX, HandleY, X, Y)

IF X < HandleX - 3 THEN EXIT FUNCTION
IF X > HandleX + 3 THEN EXIT FUNCTION
IF Y < HandleY - 3 THEN EXIT FUNCTION
IF Y > HandleY + 3 THEN EXIT FUNCTION
PointWithinHandle = -1

END FUNCTION

SUB StatusLine (Text AS STRING)

LOCATE 29, 1: PRINT Text; TAB(80);

END SUB

