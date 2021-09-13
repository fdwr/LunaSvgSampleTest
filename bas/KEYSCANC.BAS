DEFINT A-Z

CLS
DO
    KeyInp = INP(96)
    IF KeyInp <> PreInp THEN
        PreInp = KeyInp
        IF KeyInp < 128 THEN
            COLOR 10: PRINT KeyInp,
        ELSE
            COLOR 9: PRINT KeyInp
        END IF
    END IF
LOOP UNTIL INKEY$ = CHR$(27)

SUB DrawBox (Urow, Drow, Lcol, Rcol, Fore, Back)

COLOR Fore, Back: BoxWidth = Rcol - Lcol + 1
'FOR Vset = Urow + 1 TO Drow - 1: LOCATE Vset, Lcol + 1: PRINT SPACE$(BoxWidth - 2); : NEXT Vset
LOCATE Urow, Lcol: PRINT "Ú";
LOCATE Urow, Rcol: PRINT "¿";
LOCATE Drow, Lcol: PRINT "À";
LOCATE Drow, Rcol: PRINT "Ù";
LOCATE Urow, Lcol + 1: IF Lcol = Rcol THEN PRINT "Â";  ELSE PRINT STRING$(BoxWidth - 2, "Ä");
LOCATE Drow, Lcol + 1: IF Lcol = Rcol THEN PRINT "Á";  ELSE PRINT STRING$(BoxWidth - 2, "Ä");
FOR Vset = Urow + 1 TO Drow - 1: LOCATE Vset, Lcol: PRINT "³"; : NEXT Vset
FOR Vset = Urow + 1 TO Drow - 1: LOCATE Vset, Rcol: PRINT "³"; : NEXT Vset
'IF Side AND 64 THEN FOR Hset = Lcol + 1 TO Rcol - 1: LOCATE Urow, Hset: PRINT "Ä"; : NEXT Hset
'IF Side AND 128 THEN FOR Hset = Lcol + 1 TO Rcol - 1: LOCATE Drow, Hset: PRINT "Ä"; : NEXT Hset

LOCATE Urow, Lcol + (BoxWidth - LEN(MID$(Titl$, 1, BoxWidth))) / 2: PRINT LEFT$(Titl$, BoxWidth);
END SUB

SUB NumShow (Urow, Lcol, Leng, Text%)
LOCATE Urow, Lcol: PRINT LEFT$(LTRIM$(STR$(Text%)) + SPACE$(Leng), Leng);
END SUB

SUB StrShow (Urow, Lcol, Text$)
LOCATE Urow, Lcol: PRINT Text$;
END SUB

