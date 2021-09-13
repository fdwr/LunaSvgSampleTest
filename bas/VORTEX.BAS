DEFINT A-Z
SCREEN 13

CONST MaxPoints = 100

angle! = 0
DIM Angles(MaxPoints), distances(MaxPoints), PrePos(MaxPoints) AS LONG
DIM SineTable(359) AS SINGLE

FOR count = 0 TO MaxPoints - 1
    distances(count) = INT(RND * 50) + 50
    Angles(count) = INT(RND * 1024)
NEXT

FOR count = 0 TO 359
    SineTable(count) = SIN(count / 57.29583)
NEXT

rotation = 1
DEF SEG = &HA000
DO
    FOR count = 0 TO MaxPoints - 1
        distance = distances(count)
        angle = Angles(count)
        'PSET (PreX(count), PreY(count)), 0
        'POKE PrePos(count), 0
        'Y = SIN(angle MOD 360) * distance + 100
        'X = COS((angle + 90) MOD 360) * distance + 160
        Y = SineTable(angle MOD 360) * distance + 100
        X = SineTable((angle + 90) MOD 360) * distance + 160
        NewPos& = Y * 320& + X
        POKE NewPos&, count + 48
        'PSET (X, Y), 12
        PrePos(count) = NewPos&
        Angles(count) = (angle + rotation) AND 1023
        IF direction = 0 THEN
            IF distance <= 0 THEN
                distances(count) = INT(RND * 50) + 50
            ELSE
                distances(count) = distance - 1
            END IF
        ELSE
            IF distance >= 100 THEN
                distances(count) = 0
            ELSE
                distances(count) = distance + 1
            END IF
        END IF
    NEXT
    key$ = INKEY$
    IF LEN(key$) THEN
        IF key$ = CHR$(13) THEN
            direction = direction XOR 1
        ELSE
            EXIT DO
        END IF
    END IF
LOOP

SYSTEM

