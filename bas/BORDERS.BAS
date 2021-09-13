DECLARE SUB BOXDRAWR (Urow%, Lcol%, Drow%, Rcol%, Fore%, Back%, Titl%, Titl$)
DIM SHARED BoxS(0 TO 7) AS STRING
LOCATE , , 0
FOR Border% = 1 TO 8
 FOR Side% = 0 TO 7
  READ BoxS(Side%)
 NEXT Side%
 BOXDRAWR 1, 1, 25, 80, 15, 7, 0, "Various Border Tests - Test Border" + STR$(Border%)
 WHILE INKEY$ = "": WEND
NEXT Border%
END

DATA "1","2","3","4","5","6","7","8"
DATA "A","B","C","D","E","F","G","H"
DATA "#","+","#","*","ö","#","-","#"
DATA "Ú","Ä","¿","³","³","À","Ä","Ù"
DATA "Õ","Í","¸","³","³","Ô","Í","¾"
DATA "Ö","Ä","·","º","º","Ó","Ä","½"
DATA "É","Í","»","º","º","È","Í","¼"
DATA "Û","ß","Û","Û","Û","Û","Ü","Û"

DEFINT A-Z
SUB BOXDRAWR (Urow, Lcol, Drow, Rcol, Fore, Back, Titl, Titl$) STATIC
IF Urow - Drow AND Lcol - Rcol THEN
IF Urow > Drow THEN SWAP Urow, Drow
IF Lcol > Rcol THEN SWAP Lcol, Rcol
COLOR Fore, Back: BoxWidth = Rcol - Lcol + 1

LOCATE Urow, Lcol: PRINT BoxS(0); STRING$(BoxWidth - 2, BoxS(1)); BoxS(2);
FOR Hset = Urow + 1 TO Drow - 1
LOCATE Hset, Lcol: PRINT BoxS(3); STRING$(BoxWidth - 2, 0); BoxS(4);
NEXT Hset
LOCATE Drow, Lcol: PRINT BoxS(5); STRING$(BoxWidth - 2, BoxS(6)); BoxS(7);

LOCATE Urow, Lcol + (BoxWidth - LEN(MID$(Titl$, 1, BoxWidth - 2))) / 2
COLOR Titl, Back: PRINT MID$(Titl$, 1, BoxWidth - 2);

END IF
END SUB

