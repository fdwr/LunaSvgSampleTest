'2000.9.2 Peekin
'A hundred worms of varying colors emerge from the center of the screen,
'spiraling out in octal shapes towards the screen's sides.
DEFINT A-Z

CONST MaxWorms = 100, MaxTurnRange = 2, MinWormDistance = 3, MaxWormDistance = 18
CONST ScreenHeight = 200, ScreenWidth = 320

DIM CountDgr AS DOUBLE, WormColor AS INTEGER
DIM WormPaths(MaxWorms - 1, 3), WormDirLut(7, 1)
'0 = direction
'1 = distance
'2 = row
'3 = column

GOSUB InitScreen
SCREEN 13

FOR Count = 0 TO 7
    SELECT CASE Count
    CASE 0, 1, 7: WormDirLut(Count, 0) = -1
    CASE 3, 4, 5: WormDirLut(Count, 0) = 1
    CASE ELSE: WormDirLut(Count, 0) = 0
    END SELECT
    SELECT CASE Count
    CASE 1, 2, 3: WormDirLut(Count, 1) = -1
    CASE 5, 6, 7: WormDirLut(Count, 1) = 1
    CASE ELSE: WormDirLut(Count, 1) = 0
    END SELECT
NEXT Count

FOR Count = 0 TO MaxWorms - 1
    WormPaths(Count, 2) = ScreenHeight \ 2
    WormPaths(Count, 3) = ScreenWidth \ 2
NEXT Count

DO
    WormColorCount = WormColorCount - 1
    IF WormColorCount <= 0 THEN
        WormColor = ((WormColor + 1) AND 255) OR 128
        WormColorCount = 24
    END IF
    FOR Count = 0 TO MaxWorms - 1
        WormDistance = WormPaths(Count, 1)
        WormTurn = WormPaths(Count, 0)
        IF WormDistance <= 0 THEN
            WormTurn = (WormTurn + 1) AND 7'(WormTurn + RND * MaxTurnRange) AND 7
            WormPaths(Count, 0) = WormTurn
            WormPaths(Count, 1) = MinWormDistance + RND * (MaxWormDistance - MinWormDistance)
        ELSE
            WormPaths(Count, 1) = WormDistance - 1
        END IF
        'IF WormPaths(Count, 2) < 0 THEN
        '    WormPaths(Count, 2) = WormPaths(Count, 2) + 1
        'ELSEIF WormPaths(Count, 2) >= ScreenHeight THEN
        '    WormPaths(Count, 2) = WormPaths(Count, 2) - 1
        'END IF
        'IF WormPaths(Count, 3) < 0 THEN
        '    WormPaths(Count, 3) = WormPaths(Count, 3) + 1
        'ELSEIF WormPaths(Count, 3) >= ScreenWidth THEN
        '    WormPaths(Count, 3) = WormPaths(Count, 3) - 1
        'END IF
        IF WormPaths(Count, 2) < 0 OR WormPaths(Count, 2) >= ScreenHeight OR WormPaths(Count, 3) < 0 OR WormPaths(Count, 3) >= ScreenWidth THEN
            WormPaths(Count, 2) = ScreenHeight \ 2
            WormPaths(Count, 3) = ScreenWidth \ 2
        END IF
        WormPaths(Count, 2) = WormPaths(Count, 2) + WormDirLut(WormTurn, 0)
        WormPaths(Count, 3) = WormPaths(Count, 3) + WormDirLut(WormTurn, 1)
        PSET (WormPaths(Count, 3), WormPaths(Count, 2)), WormColor
    NEXT Count
LOOP UNTIL LEN(INKEY$)

END


InitScreen:
    SCREEN 13
    OUT &H3C8, 128
    FOR Count = 0 TO 127
        CountDgr = Count / 20.37185
        'OUT &H3C9, 0
        'OUT &H3C9, 0
        'OUT &H3C9, COS(CountDgr) * 20 + 31
        OUT &H3C9, COS(CountDgr + 4.188787) * 31 + 32
        OUT &H3C9, COS(CountDgr + 2.0943) * 31 + 32
        OUT &H3C9, COS(CountDgr) * 31 + 32
    NEXT Count
RETURN

