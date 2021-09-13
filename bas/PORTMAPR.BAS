'1996.4.15
DEFINT A-Z: DIM p$, p&, t, l, c
VIEW PRINT 1 TO 6: COLOR 10, 3: CLS : VIEW PRINT: DEF SEG = &HB800: l = -1

p& = 64
LOCATE 6, 1: PRINT TAB(29); "Press Space to change port number";
DO UNTIL INKEY$ = ""
    IF INP(96) = 57 THEN
        LOCATE 5, 36: PRINT SPACE$(3)
        LOCATE 5, 36: LINE INPUT p$
        VIEW PRINT 1 TO 5: CLS : VIEW PRINT
        IF LEN(p$) AND LEN(p$) < 5 THEN
            IF VAL(p$) > 65535 THEN p& = 65535 ELSE p& = VAL(p$)
            l = -1
        END IF
    END IF
    t = INP(p&)
    IF t <> l THEN POKE t * 2, 219
    IF l >= 0 THEN
        IF l <> t THEN POKE l * 2, 177
        IF l = t AND c < 32767 THEN c = c + 1 ELSE c = 0
    END IF
    l = t
    LOCATE 5, 1: PRINT t, c; "   ", "PORT ="; STR$(p&)
LOOP
END

