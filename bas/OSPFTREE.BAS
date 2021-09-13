DEFINT A-Z
DECLARE SUB StatusLine (Text AS STRING)

CONST MaxRoutes = 200, MaxRouters = 20, MaxRouterBranches = 10

TYPE RouterType
Top         AS INTEGER
Left        AS INTEGER
Delay       AS INTEGER
Speed       AS INTEGER
Reliable    AS INTEGER
Branches    AS INTEGER
Visited     AS INTEGER
TableBuilt  AS INTEGER
END TYPE

TYPE RouteType
Src         AS INTEGER
Dest        AS INTEGER
Delay       AS INTEGER
Speed       AS INTEGER
Reliable    AS INTEGER
END TYPE

TYPE SavedRouteType
Branch AS INTEGER
Router AS INTEGER
Weight AS INTEGER
END TYPE

DIM Routers(MaxRouters - 1) AS RouterType, Routes(MaxRoutes - 1) AS RouteType
DIM RouteTable(MaxRouters - 1, MaxRouters - 1)
DIM WeightTable(MaxRouters - 1, MaxRouters - 1)
DIM RouterPaths(MaxRouters - 1, MaxRouterBranches - 1)
DIM SaveTable(MaxRouters - 1) AS SavedRouteType


'initialize router and route information

SCREEN 13

GOSUB LoadRoutes
GOSUB DrawRoutingSystem
GOSUB InitializeRouters
'GOSUB BuildRouteTable
GOSUB UserLoopShowBranches

END

UserLoopShowBranches:
    Redraw = -1
    DO
        Key$ = INKEY$
        SELECT CASE Key$
        CASE CHR$(27): EXIT DO
        CASE CHR$(0) + "K": NewRouter = -1
        CASE CHR$(0) + "M": NewRouter = 1
        CASE "b"
            StatusLine "building route table for" + STR$(RootRouter)
            GOSUB DrawRoutingSystem
            ShowBuild = -1
            GOSUB BuildRouteTable
            Redraw = -1
        CASE "r"
            SrcRouter = RootRouter
            StatusLine "source router set to" + STR$(RootRouter)
        CASE "s"
            StatusLine "sending packet from" + STR$(SrcRouter) + " to" + STR$(RootRouter)
            DestRouter = RootRouter
            GOSUB DrawRoutingSystem
            GOSUB TracePacketRoute
            DO: LOOP UNTIL LEN(INKEY$)
            GOSUB DrawRoutingSystem
            RootRouter = DestRouter
            Redraw = -1
        END SELECT
        IF NewRouter THEN
            Highlight = 0
            CurRouter = RootRouter
            GOSUB DrawRouterBranches
            RootRouter = RootRouter + NewRouter
            IF RootRouter < 0 THEN RootRouter = TotalRouters - 1
            IF RootRouter >= TotalRouters THEN RootRouter = 0
            NewRouter = 0
            Redraw = -1
        END IF
        IF Redraw THEN
            StatusLine "current router is" + STR$(RootRouter)
            Highlight = -1
            CurRouter = RootRouter
            GOSUB DrawRouterBranches
            Redraw = 0
        END IF
    LOOP
RETURN

InitializeRouters:
    'mark all router tables as undetermined
    FOR Count = 0 TO TotalRouters - 1
        Routers(Count).Branches = 0
        'set all routes to nonexistant adjacency
        RouteTable(Count, 0) = 32767
    NEXT

    'determine every router's interfaces based on connections
    FOR Count = 0 TO TotalRoutes - 1
        Src = Routes(Count).Src
        Dest = Routes(Count).Dest
        Branches = Routers(Src).Branches
        IF Branches < MaxRouterBranches THEN
            RouterPaths(Src, Branches) = Count
            Routers(Src).Branches = Branches + 1
        END IF
        Branches = Routers(Dest).Branches
        IF Branches < MaxRouterBranches THEN
            RouterPaths(Dest, Branches) = Count
            Routers(Dest).Branches = Branches + 1
        END IF
    NEXT
RETURN


LoadRoutes:
    RESTORE RouteData
    READ TotalRouters
    FOR Count = 0 TO TotalRouters - 1
        READ Routers(Count).Top, Routers(Count).Left, Routers(Count).Delay, Routers(Count).Speed, Routers(Count).Reliable
    NEXT
    READ TotalRoutes
    FOR Count = 0 TO TotalRoutes - 1
        READ Routes(Count).Src, Routes(Count).Dest, Routes(Count).Delay, Routes(Count).Speed, Routes(Count).Reliable
    NEXT
RETURN


BuildRouteTable:
    FOR Count = 0 TO TotalRouters - 1
        Routers(Count).Visited = 0
        'set all routes to maximum (practically infinite) weight
        WeightTable(RootRouter, Count) = 32767
        'set all routes to maximum adjacency
        RouteTable(RootRouter, Count) = 32767
    NEXT
    Routers(RootRouter).Visited = -1

    CurRouter = RootRouter
    Nesting = 0
BuildRouteTableNest:
    Branch = 0
    DO UNTIL Branch >= Routers(CurRouter).Branches
        Route = RouterPaths(CurRouter, Branch)
        NextRouter = Routes(Route).Dest
        IF NextRouter = CurRouter THEN NextRouter = Routes(Route).Src
        IF NOT Routers(NextRouter).Visited THEN
            IF ShowBuild THEN Highlight = 1: GOSUB DrawRoute

            IF Nesting = 0 THEN RootAdjacency = NextRouter

            'save current weight before adding weight of new route
            SaveTable(Nesting).Weight = CurWeight
            CurWeight = CurWeight + Routes(Route).Delay

            'reached router so check if current path < any previous path
            IF CurWeight < WeightTable(RootRouter, NextRouter) THEN
                GOTO BuildRouteTableBranch
            ELSEIF CurWeight = WeightTable(RootRouter, NextRouter) THEN
                IF RootAdjacency < RouteTable(RootRouter, NextRouter) THEN
                    GOTO BuildRouteTableBranch
                END IF
            END IF

BuildRouteTableUnnest:
            IF ShowBuild THEN Route = RouterPaths(CurRouter, Branch): Highlight = 0: GOSUB DrawRoute

            'restore variables
            CurWeight = SaveTable(Nesting).Weight
        END IF
        IF ShowBuild THEN PreTime! = TIMER: DO: LOOP UNTIL TIMER <> PreTime!
        Branch = Branch + 1
    LOOP
    IF Nesting > 0 THEN
        Nesting = Nesting - 1
        Routers(CurRouter).Visited = 0
        Branch = SaveTable(Nesting).Branch
        IF ShowBuild THEN Highlight = 0: GOSUB DrawRouter
        CurRouter = SaveTable(Nesting).Router
        GOTO BuildRouteTableUnnest
    END IF
    Routers(RootRouter).TableBuilt = -1
RETURN

BuildRouteTableBranch:
    WeightTable(RootRouter, NextRouter) = CurWeight
    RouteTable(RootRouter, NextRouter) = RootAdjacency

    'add weights of router itself
    CurWeight = CurWeight + Routers(NextRouter).Delay
    Routers(NextRouter).Visited = -1
    SaveTable(Nesting).Branch = Branch
    SaveTable(Nesting).Router = CurRouter

    CurRouter = NextRouter
    Nesting = Nesting + 1

    IF ShowBuild THEN Highlight = 1: GOSUB DrawRouter
GOTO BuildRouteTableNest


TracePacketRoute:
    PktRouter = SrcRouter
    ShowBuild = 0
    DO UNTIL PktRouter = DestRouter OR PktRouter = 32767 OR LEN(INKEY$)
        IF NOT Routers(PktRouter).TableBuilt THEN
            RootRouter = PktRouter
            GOSUB BuildRouteTable
        END IF
        Src = PktRouter
        PktRouter = RouteTable(PktRouter, DestRouter)
        LINE (Routers(Src).Left, Routers(Src).Top)-(Routers(PktRouter).Left, Routers(PktRouter).Top), 11
    LOOP
RETURN


DrawRoutingSystem:
    FOR Count = 0 TO TotalRouters - 1
        CIRCLE (Routers(Count).Left, Routers(Count).Top), 4, 9, , , 1
        'LOCATE Routers(Count).Top \ 8 + 1, Routers(Count).Left \ 8 + 1
        'PRINT LTRIM$(STR$(Count));
    NEXT
    FOR Count = 0 TO TotalRoutes - 1
        Src = Routes(Count).Src
        Dest = Routes(Count).Dest
        LINE (Routers(Src).Left, Routers(Src).Top)-(Routers(Dest).Left, Routers(Dest).Top), 1
    NEXT
RETURN


DrawRouterBranches:
    IF RootRouter >= TotalRouters THEN RETURN
    IF Highlight THEN
        BranchColor = 11
        RouterColor = 15
    ELSE
        BranchColor = 1
        RouterColor = 9
    END IF
    CIRCLE (Routers(CurRouter).Left, Routers(CurRouter).Top), 4, RouterColor, , , 1
    FOR Count = 0 TO Routers(CurRouter).Branches - 1
        Route = RouterPaths(CurRouter, Count)
        Src = Routes(Route).Src
        Dest = Routes(Route).Dest
        LINE (Routers(Src).Left, Routers(Src).Top)-(Routers(Dest).Left, Routers(Dest).Top), BranchColor
    NEXT
RETURN


DrawRouter:
    IF Highlight THEN
        RouterColor = 15
    ELSE
        RouterColor = 9
    END IF
    CIRCLE (Routers(CurRouter).Left, Routers(CurRouter).Top), 4, RouterColor, , , 1
    'LOCATE Routers(CurRouter).Top \ 8 + 1, Routers(CurRouter).Left \ 8 + 1
    'PRINT LTRIM$(STR$(CurRouter));
RETURN


DrawRoute:
    IF Highlight THEN
        BranchColor = 12
    ELSE
        BranchColor = 1
    END IF
    Src = Routes(Route).Src
    Dest = Routes(Route).Dest
    LINE (Routers(Src).Left, Routers(Src).Top)-(Routers(Dest).Left, Routers(Dest).Top), BranchColor
RETURN


RouteData:
DATA 15
DATA 88,152,0,0,1
DATA 44,116,0,0,1
DATA 44,24,0,0,1
DATA 12,72,0,0,1
DATA 12,168,0,0,1
DATA 88,228,0,0,1
DATA 56,272,0,0,1
DATA 12,232,0,0,1
DATA 136,256,0,0,1
DATA 136,152,0,0,1
DATA 136,76,0,0,1
DATA 88,20,0,0,1
DATA 172,20,0,0,1
DATA 172,108,0,0,1
DATA 172,192,0,0,1

DATA 17
DATA 0,1,1,0,1
DATA 1,3,1,0,1
DATA 1,2,1,0,1
DATA 1,4,1,0,1
DATA 0,5,1,0,1
DATA 5,6,1,0,1
DATA 4,7,1,0,1
DATA 6,7,1,0,1
DATA 5,8,1,0,1
DATA 0,9,1,0,1
DATA 9,10,1,0,1
DATA 13,14,1,0,1
DATA 14,8,1,0,1
DATA 9,13,1,0,1
DATA 10,12,1,0,1
DATA 10,11,1,0,1
DATA 2,11,1,0,1

SUB StatusLine (Text AS STRING)

LOCATE 25, 1: PRINT Text; TAB(40);

END SUB

