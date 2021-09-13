'Continuous Line Path, Point Crosser
'
'I'm not sure what to call this program, but I can tell you what it does. This
'was written to solve a brain teaser given to me by a friend. Instead of
'trying to solve it manually by drawing out the several possibilities, I gave
'it to the computer.
'
'The rules are simple:
'Given a 5x5 grid of points,
'You must draw one continuous path (no lifting the pencil up),
'Through every one of the 25 points,
'Making no more than six turns (seven lines total),
'The line may cross itself,
'But can not turn around or follow the same path twice.

DEFINT A-Z

CONST GridHeight = 5, GridWidth = 5, GridSize = 5
CONST GridHeightHalf = (GridHeight + 1) \ 2, GridWidthHalf = (GridWidth + 1) \ 2
CONST MaxSegments = 9
CONST PointsNeeded = 25
CONST GridPointVisited = 256, GridPointNeeded = 512

TYPE SegmentInfoType
Row AS INTEGER
Col AS INTEGER
Dir AS INTEGER
Visits AS INTEGER
Crosses AS INTEGER
END TYPE

DIM GridPoints(GridHeight - 1, GridWidth - 1)
DIM GridVisitRecord(MaxSegments * GridSize * 2, 2)
DIM SegmentInfo(MaxSegments - 1) AS SegmentInfoType
DIM DirMasks(15)
DIM RowInc(7), ColInc(7)
DIM Iterations AS LONG

RESTORE PointIncData
FOR Dir = 0 TO 7
    READ RowInc(Dir), ColInc(Dir)
NEXT
DirMask = 1
FOR Dir = 0 TO 15
    DirMasks(Dir) = DirMask
    DirMask = DirMask * 2
    IF DirMask > 128 THEN DirMask = 1
NEXT
GOSUB ReadGridPoints


SCREEN 13

LINE (0, 0)-(GridWidth * 8 - 6, GridHeight * 8 - 6), 15, B
FOR Row = 0 TO GridHeight - 1
    FOR Col = 0 TO GridWidth - 1
        IF GridPoints(Row, Col) AND GridPointNeeded THEN
            PtRow = Row: PtCol = Col
            GOSUB ShowImportantPoint
        END IF
    NEXT
NEXT
LOCATE 12, 1
PRINT TAB(20); "Segment"
PRINT TAB(20); "Visits/ParVisits"
PRINT TAB(20); "Crosses/ParCrosses"
PRINT TAB(20); "Row/Col"
PRINT TAB(20); "ParRow/ParCol"
PRINT TAB(20); "Dir/ParDir"

DO: LOOP UNTIL LEN(INKEY$)
StartTime! = TIMER

NextLineBase:
GOSUB InitPath
DO
    GOSUB NextPath
    Iterations = Iterations + 1
    IF Crosses >= PointsNeeded THEN
        Msg$ = "Solution found!! :)"
        GOSUB DisplayMsg
        GOTO CheckKeyPress
    ELSEIF Segment <= 0 THEN
        BaseCol = BaseCol + 1
        IF BaseCol >= GridWidthHalf THEN
            BaseRow = BaseRow + 1
            IF BaseRow >= GridHeightHalf THEN
                Msg$ = "No solution found... :("
                GOSUB DisplayMsg
                EXIT DO
            END IF
            BaseCol = 0
        END IF
        GOTO NextLineBase
    ELSEIF KeyChkCount >= 1000 THEN
        Key$ = INKEY$
CheckKeyPress:
        IF Key$ = CHR$(27) THEN
            Msg$ = "Aborted by keypress... :/"
            GOSUB DisplayMsg
            EXIT DO
        END IF
        LOCATE 20, 1: PRINT Iterations;
        KeyChkCount = 0
    END IF
    KeyChkCount = KeyChkCount + 1

    'LOCATE 12, 1
    'PRINT Segment
    'PRINT Visits; ParVisits
    'PRINT Crosses; ParCrosses
    'PRINT Row; Col
    'PRINT ParRow; ParCol
    'PRINT Dir; ParDir
    'DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)
    'IF Key$ = CHR$(27) THEN EXIT DO
LOOP

WIDTH 80, 25
END

DisplayMsg:
    LOCATE 20, 1: PRINT Msg$; TAB(40);
    PRINT "Total time:"; TIMER - StartTime!
    DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)
    LOCATE 20, 1: PRINT TAB(40);
RETURN

ReadGridPoints:
    'read which points are important
    RESTORE GridPointData
    FOR Row = 0 TO GridHeight - 1
        FOR Col = 0 TO GridWidth - 1
            READ GridPoint
            IF GridPoint THEN GridPoints(Row, Col) = GridPointNeeded
        NEXT
    NEXT

    'create an impassible border around grid
    '    6         64
    '  5\|/7    32\|/128
    ' 4--*--0  16--*--1
    '  3/|\1     8/|\2
    '    2         4
    FOR Col = 0 TO GridWidth - 1
        GridPoints(0, Col) = GridPoints(0, Col) OR 224
        GridPoints(GridHeight - 1, Col) = GridPoints(GridHeight - 1, Col) OR 14
    NEXT
    FOR Row = 0 TO GridHeight - 1
        GridPoints(Row, 0) = GridPoints(Row, 0) OR 56
        GridPoints(Row, GridWidth - 1) = GridPoints(Row, GridWidth - 1) OR 131
    NEXT
RETURN

InitPath:
    Segment = 0
    Row = BaseRow
    Col = BaseCol
    Dir = -1
    ParDir = -1

    GridPoint = GridPoints(BaseRow, BaseCol)
    GridVisitRecord(0, 0) = BaseRow
    GridVisitRecord(0, 1) = BaseCol
    GridVisitRecord(0, 2) = GridPoint
   
    ParVisits = 1
    IF GridPoint AND GridPointNeeded THEN ParCrosses = 1 ELSE ParCrosses = 0
    Crosses = ParCrosses

    PtRow = Row
    PtCol = Col
RETURN

NextPath:
'draws a complete path of seven lines, or until a end is reached.
'responsible for determining all the possible paths,
'drawing a new path every call.
'note that this routine breaks every branching 'rule' by using goto's and
'more than one deep return. this was done because of the recursive nature,
'attempting to avoid actual recursion.
'
'Segment = current line segment (0-6)
'Row/Col = position of current line segment
'ParRow/ParCol = starting position of child line (end of parent line)
'Dir = direction of current line segment (0-7)
'ParDir = direction of parent line
'Visits = total recorded point visits by all segments
'ParVisits = recorded point visits of parent
'Crosses = important points crossed through by all segments
'ParCrosses = important points already crossed through by parent
'GridPoint = value of point at current row/col
'
NextPathRetreat:
    DO UNTIL Visits <= ParVisits
        Visits = Visits - 1
        PtRow = Row: PtCol = Col
        Row = GridVisitRecord(Visits, 0)
        Col = GridVisitRecord(Visits, 1)
        GridPoints(Row, Col) = GridVisitRecord(Visits, 2)
        LINE (PtCol * 8 + 1, PtRow * 8 + 1)-(Col * 8 + 1, Row * 8 + 1), 0
        'GOSUB ShowImportantPoint
        'PtRow = Row: PtCol = Col
        'GOSUB ShowImportantPoint
    LOOP
    Crosses = ParCrosses

    'search through all directions
    'if valid dir is found, move forward
    'if all directions tested, destroy child and resume from parent
    'DirMask = DirMasks(Dir)
    'GridPoint = GridPoints(Row, Col)
NextPathChkDir:
    DO
        IF Dir >= 6 THEN
            Segment = Segment - 1
            IF Segment < 0 THEN RETURN

            'restore parent information
            Row = ParRow
            Col = ParCol
            'Visits = ParVisits
            Dir = ParDir

            'retrieve saved line segment information
            ParRow = SegmentInfo(Segment).Row
            ParCol = SegmentInfo(Segment).Col
            ParDir = SegmentInfo(Segment).Dir
            ParVisits = SegmentInfo(Segment).Visits
            ParCrosses = SegmentInfo(Segment).Crosses
            GridPoint = GridPoints(Row, Col)
            DirMask = DirMasks(Dir)
            IF GridPoint AND DirMask THEN GOTO NextPathRetreat
            EXIT DO
        ELSE
            Dir = Dir + 1
            'DirMask = DirMask * 2
        END IF
        DirMask = DirMasks(Dir)
        GridPoint = GridPoints(Row, Col)
    LOOP WHILE Dir = ParDir OR (GridPoint AND DirMask)

    'move forward:
    '  save point
    '  mark old point coming from as visited
    '  adjust row/col
    '  check points visited
    '  save point
    '  mark new point going to as visited

NextPathForward:
    'save old row/col grid point
    GridPoint = GridPoints(Row, Col)
    GridVisitRecord(Visits, 0) = Row
    GridVisitRecord(Visits, 1) = Col
    GridVisitRecord(Visits, 2) = GridPoint
    GridPoints(Row, Col) = GridPoint OR GridPointVisited OR DirMask
    Visits = Visits + 1

    'mark direction going to in old point as used
    'move forward in direction to new row/col
    PtRow = Row: PtCol = Col
    Row = Row + RowInc(Dir)
    Col = Col + ColInc(Dir)
    LINE (PtCol * 8 + 1, PtRow * 8 + 1)-(Col * 8 + 1, Row * 8 + 1), 12
    'GOSUB ShowImportantPoint
    'PtRow = Row
    'PtCol = Col
    'GOSUB ShowImportantPoint

    GridPoint = GridPoints(Row, Col)
    'check new point
    IF (GridPoint AND GridPointVisited) = 0 THEN
        IF GridPoint AND GridPointNeeded THEN
            Crosses = Crosses + 1
            IF Crosses >= PointsNeeded THEN RETURN
        END IF
    END IF

    'save new row/col grid point
    GridVisitRecord(Visits, 0) = Row
    GridVisitRecord(Visits, 1) = Col
    GridVisitRecord(Visits, 2) = GridPoint
    'mark direction coming from in new point as used
    GridPoints(Row, Col) = GridPoint OR GridPointVisited OR DirMasks(Dir + 4)
    Visits = Visits + 1

    'create child if not last segment
    IF Segment < MaxSegments - 1 THEN
        'first save current segment info
        SegmentInfo(Segment).Row = ParRow
        SegmentInfo(Segment).Col = ParCol
        SegmentInfo(Segment).Dir = ParDir
        SegmentInfo(Segment).Visits = ParVisits
        SegmentInfo(Segment).Crosses = ParCrosses
        Segment = Segment + 1
    
        'set info for connected child segment
        ParRow = Row
        ParCol = Col
        ParVisits = Visits
        ParCrosses = Crosses
        ParDir = Dir
        Dir = -1
        GOTO NextPathChkDir
    ELSEIF GridPoints(Row, Col) AND DirMask THEN
        RETURN
    END IF
    GOTO NextPathForward

RETURN


ShowImportantPoint:
    IF GridPoints(PtRow, PtCol) AND GridPointNeeded THEN
        PSET (PtCol * 8 + 1, PtRow * 8 + 1), 15
    END IF
RETURN

PointIncData:
DATA 0,1, 1,1, 1,0, 1,-1, 0,-1, -1,-1, -1,0, -1,1

GridPointData:
DATA 1,1,1,1,1
DATA 1,1,1,1,1
DATA 1,1,1,1,1
DATA 1,1,1,1,1
DATA 1,1,1,1,1

DATA 0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,1,1,1,1,1,0,0,0
DATA 0,0,0,1,1,1,1,1,0,0,0
DATA 0,0,0,1,1,1,1,1,0,0,0
DATA 0,0,0,1,1,1,1,1,0,0,0
DATA 0,0,0,1,1,1,1,1,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0
DATA 0,0,0,0,0,0,0,0,0,0,0

