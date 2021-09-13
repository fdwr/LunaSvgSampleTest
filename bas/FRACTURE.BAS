DEFINT A-Z
OPTION BASE 0

CONST LastWarpPoint = 99
CONST ScreenWidth = 320
CONST ScreenHeight = 200

DIM WarpPoints(0 TO LastWarpPoint, 1)

SCREEN 13
COLOR 7
PRINT "Fracture by FDwR, 4-19-99"

GOSUB PickRandomWarpPoints
DO: LOOP UNTIL LEN(INKEY$)
GOSUB PlotsPoints
GOSUB TracePoints.Octagon
GOSUB TracePoints.Polygon
GOSUB PlotsPoints

DO: LOOP UNTIL LEN(INKEY$)
END

BlackenPalette:
    OUT &H3C8, 0
    FOR CurColor = 0 TO 255
        OUT &H3C9, 0: OUT &H3C9, 0: OUT &H3C9, 0
    NEXT CurColor
RETURN

PickRandomWarpPoints:
    FOR CurPoint = 0 TO LastWarpPoint
        WarpPoints(CurPoint, 0) = INT(RND * ScreenHeight)
        WarpPoints(CurPoint, 1) = INT(RND * ScreenWidth)
    NEXT CurPoint
    PRINT LastWarpPoint + 1; "points randomly selected"
RETURN

PlotsPoints:
    FOR CurPoint = 0 TO LastWarpPoint
        Row = WarpPoints(CurPoint, 0)
        Col = WarpPoints(CurPoint, 1)
        'LINE (Col, Row - 3)-(Col, Row + 3), 15
        'LINE (Col - 3, Row)-(Col + 3, Row), 15
        PSET (Col, Row), 0
    NEXT CurPoint
RETURN

FindNearestPoint.Octagon:
    Distance = 1000
    FOR CurPoint = 0 TO LastWarpPoint
        RowDist = ABS(WarpPoints(CurPoint, 0) - Row)
        ColDist = ABS(WarpPoints(CurPoint, 1) - Col)
        IF RowDist < Distance AND ColDist < Distance THEN
            NewDistance = RowDist + ColDist
            IF NewDistance < Distance THEN NearestPoint = CurPoint: Distance = NewDistance
        END IF
    NEXT CurPoint
RETURN

FindNearestPoint.Polygon:
    Distance = 1000
    FOR CurPoint = 0 TO LastWarpPoint
        RowDist = ABS(WarpPoints(CurPoint, 0) - Row)
        ColDist = ABS(WarpPoints(CurPoint, 1) - Col)
        IF RowDist < Distance AND ColDist < Distance THEN
            NewDistance& = ABS(WarpPoints(CurPoint, 0) - Row) * CLNG(ABS(WarpPoints(CurPoint, 1) - Col))
            IF NewDistance& < Distance THEN NearestPoint = CurPoint: Distance = NewDistance&
            'NewDistance = INT(SQR(RowDist * CLNG(RowDist) + ColDist * CLNG(ColDist)))
            'IF NewDistance < Distance THEN NearestPoint = CurPoint: Distance = NewDistance
        END IF
    NEXT CurPoint
            'NearestPoint = INT(RND * (LastWarpPoint + 1))
            'IF NewDistance < Distance THEN NearestPoint = CurPoint: Distance = NewDistance
            'NewDistance = SQR(RowDist * CLNG(RowDist) + ColDist * CLNG(ColDist))
            'NewDistance = ABS(WarpPoints(CurPoint, 0) - Row) + ABS(WarpPoints(CurPoint, 1) - Col)
            'NewDistance& = ABS(WarpPoints(CurPoint, 0) - Row) * CLNG(ABS(WarpPoints(CurPoint, 1) - Col))
            'IF NewDistance& < Distance THEN NearestPoint = CurPoint: Distance = NewDistance&
            'NewDistance& = ABS(WarpPoints(CurPoint, 0) - Row) * CLNG(ABS(WarpPoints(CurPoint, 1) - Col))
            'IF NewDistance& < Distance THEN NearestPoint = CurPoint: Distance = NewDistance&
RETURN

TracePoints.Octagon:
    FOR Row = 0 TO ScreenHeight - 1
        FOR Col = 0 TO ScreenWidth - 1
            GOSUB FindNearestPoint.Octagon
            PSET (Col, Row), NearestPoint + 32
        NEXT Col
    NEXT Row
RETURN

TracePoints.Polygon:
    FOR Row = 0 TO ScreenHeight - 1
        FOR Col = 0 TO ScreenWidth - 1
            GOSUB FindNearestPoint.Polygon
            PSET (Col, Row), NearestPoint + 32
        NEXT Col
    NEXT Row
RETURN

