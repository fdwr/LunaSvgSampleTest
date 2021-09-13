DEFINT A-Z
DECLARE SUB DrawBox (Urow, Drow, Lcol, Rcol, Fore, Back)
DECLARE SUB NumShow (Urow, Lcol, Leng, Text%)
DECLARE SUB StrShow (Urow, Lcol, Text$)

COLOR 7, 0: CLS : LOCATE , , 0
StrShow 3, 16, "Key Buffer Peeker program, press Escape to exit"
DrawBox 2, 4, 15, 63, 7, 0
StrShow 6, 16, "Counter1Ä     Counter2Ä"'1050,1052
StrShow 8, 16, "ASCIIÄÄÄÄ     ScancodeÄ"
DrawBox 5, 24, 15, 28, 7, 0
DrawBox 5, 24, 29, 42, 7, 0
StrShow 6, 45, "Keylock StatusÄ"'1040
FOR p% = 1 TO 8: READ t$: LOCATE p% + 7, 50: PRINT t$: NEXT p%
DATA "R SHFT","L SHFT","CONTROL","ALTERNATE","SCRL LOCK","NUM LOCK","CAPS LOCK","INSERT"
DrawBox 5, 16, 44, 63, 7, 0
StrShow 18, 45, "Key Input Byte-"
StrShow 20, 45, "Key Scancode  -"
StrShow 22, 45, "Key up or down-"
DrawBox 17, 23, 44, 63, 7, 0
COLOR 15: StrShow 24, 45, "Made by FDR junior"
DEF SEG = 0
DO
k$ = INKEY$: IF k$ > "" THEN GOTO 20
NumShow 6, 25, 2, PEEK(&H41A)
NumShow 6, 39, 3, PEEK(&H41C)
Urow% = 8
FOR p% = 1054 TO 1085 STEP 2
NumShow Urow%, 25, 3, PEEK(p%)
NumShow Urow%, 39, 3, PEEK(p% + 1)
Urow% = Urow% + 1: NEXT p%
s% = PEEK(&H417)
NumShow 6, 60, 3, s%
FOR p% = 0 TO 7
LOCATE p% + 8, 45: IF s% AND 2 ^ p% THEN PRINT "ON ";  ELSE PRINT "OFF";
NEXT p%
s% = INP(&H60)
NumShow 18, 60, 3, s%
NumShow 20, 60, 3, s% AND 127
LOCATE 22, 61: IF s% AND 128 THEN PRINT "";  ELSE PRINT "";
20 LOOP UNTIL k$ = ""
SYSTEM

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

