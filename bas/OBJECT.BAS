DECLARE FUNCTION BUTTON% (Lcol%, Rcol%, Ulin%, Dlin%, Fore%, Back%, Bakk%, Titl$, Keys$)
DECLARE FUNCTION STRPROMPT$ (Length%, RecLen%, Result$, Hlin%, Lcol%, Keys$)
DECLARE FUNCTION NUMPROMPT# (Length%, Result$, Hlin%, Lcol%, Keys$)
DECLARE FUNCTION TRUNC% (Nmbr1%, Nmbr2%, Mode%)
DECLARE FUNCTION BIN$ (x&)
DECLARE SUB DRAWBUTTON (Lcol%, Rcol%, Ulin%, Dlin%, Fore%, Back%, Bakk%, Titl$)
DECLARE SUB BOXDRAW5 (Urow%, Lcol%, Drow%, Rcol%, Fore%, Back%, Side%, Titl$)
DECLARE SUB SCROLLBAR (AF1%, AF2%, AT1%, AT2%, Side1%, Side2%, Lin%, Mode%)
DECLARE SUB TEXTWRAP (Hite%, Widt%, Lcol%, Ulin%, Text$)
DECLARE SUB LABEL (Urow!, Lcol!, Text$)

DEFLNG A-Z
FUNCTION BIN$ (x)
b$ = STRING$(16, 48)
IF x AND &H1 THEN MID$(b$, 1) = "1"
IF x AND &H2 THEN MID$(b$, 2) = "1"
IF x AND &H4 THEN MID$(b$, 3) = "1"
IF x AND &H8 THEN MID$(b$, 4) = "1"
IF x AND &H10 THEN MID$(b$, 5) = "1"
IF x AND &H20 THEN MID$(b$, 6) = "1"
IF x AND &H40 THEN MID$(b$, 7) = "1"
IF x AND &H80 THEN MID$(b$, 8) = "1"
IF x AND &H100 THEN MID$(b$, 9) = "1"
IF x AND &H200 THEN MID$(b$, 10) = "1"
IF x AND &H400 THEN MID$(b$, 11) = "1"
IF x AND &H800 THEN MID$(b$, 12) = "1"
IF x AND &H1000 THEN MID$(b$, 13) = "1"
IF x AND &H2000 THEN MID$(b$, 14) = "1"
IF x AND &H4000 THEN MID$(b$, 15) = "1"
IF x AND &H8000 THEN MID$(b$, 16) = "1"
BIN$ = b$
END FUNCTION

DEFINT A-Z
SUB BOXDRAW5 (Urow, Lcol, Drow, Rcol, Fore, Back, Side, Titl$)
COLOR Fore, Back: BoxW = Rcol - Lcol + 1

IF Side AND 256 THEN FOR Vset = Urow + 1 TO Drow - 1: LOCATE Vset, Lcol + 1: PRINT SPACE$(BoxW - 2); : NEXT Vset
IF Side AND 1 THEN LOCATE Urow, Lcol: PRINT "Ú";
IF Side AND 2 THEN LOCATE Urow, Rcol: PRINT "¿";
IF Side AND 4 THEN LOCATE Drow, Lcol: PRINT "À";
IF Side AND 8 THEN LOCATE Drow, Rcol: PRINT "Ù";
IF Side AND 16 THEN LOCATE Urow, Lcol + 1: PRINT STRING$(BoxW - 2, "Ä");
IF Side AND 32 THEN LOCATE Drow, Lcol + 1: PRINT STRING$(BoxW - 2, "Ä");
IF Side AND 64 THEN FOR Vset = Urow + SGN(Drow - Urow) TO Drow - SGN(Drow - Urow) STEP SGN(Drow - Urow) OR 1: LOCATE Vset, Lcol: PRINT "³"; : NEXT Vset
IF Side AND 128 THEN FOR Vset = Urow + SGN(Drow - Urow) TO Drow - SGN(Drow - Urow) STEP SGN(Drow - Urow) OR 1: LOCATE Vset, Rcol: PRINT "³"; : NEXT Vset
'IF Side AND 64 THEN FOR Hset = Lcol + 1 TO Rcol - 1: LOCATE Urow, Hset: PRINT "Ä"; : NEXT Hset
'IF Side AND 128 THEN FOR Hset = Lcol + 1 TO Rcol - 1: LOCATE Drow, Hset: PRINT "Ä"; : NEXT Hset

LOCATE Urow, Lcol + (BoxW - LEN(MID$(Titl$, 1, BoxW))) / 2
PRINT LEFT$(Titl$, BoxW);
END SUB

FUNCTION BUTTON (Lcol, Rcol, Ulin, Dlin, Fore, Back, Bakk, Titl$, Keys$)

DRAWBUTTON Lcol, Rcol, Ulin, Dlin, 15, Back, Bakk, Titl$
DO UNTIL Done
 IF INP(96) = 57 THEN
  DRAWBUTTON Lcol, Rcol, Ulin, Dlin, Back, Fore, Bakk, Titl$
  WHILE INP(96) = 57: Kbd$ = INKEY$: WEND
  IF INP(96) = 185 THEN Keys$ = " ": BUTTON = -1: Done = -1 ELSE DRAWBUTTON Lcol, Rcol, Ulin, Dlin, 15, Back, Bakk, Titl$
 END IF
 Kbd$ = INKEY$
 SELECT CASE Kbd$
 CASE ""
 CASE " "
 CASE ELSE: Keys$ = Kbd$: Done = -1
 IF Kbd$ = " " THEN BUTTON = -1 ELSE BUTTON = 0
 END SELECT
LOOP
DRAWBUTTON Lcol, Rcol, Ulin, Dlin, Fore, Back, Bakk, Titl$

END FUNCTION

SUB DRAWBUTTON (Lcol, Rcol, Ulin, Dlin, Fore, Back, Bakk, Titl$)
Ulin2 = TRUNC(TRUNC(Ulin, Dlin, 0), 1, 1)
Dlin2 = TRUNC(TRUNC(Dlin, Ulin, 1), 25, 0)
Lcol2 = TRUNC(TRUNC(Lcol, Rcol, 0), 1, 1)
Rcol2 = TRUNC(TRUNC(Rcol, Lcol, 1), 80, 0)
BLen = Rcol2 - Lcol2 + 1: COLOR Fore, Back

FOR Hset = Ulin2 TO Dlin2: LOCATE Hset, Lcol2: PRINT SPACE$(BLen); : NEXT Hset
LOCATE Ulin, Lcol + (BLen - LEN(LEFT$(Titl$, BLen))) / 2: PRINT LEFT$(Titl$, BLen);

COLOR 8, Bakk
IF TRUNC(Rcol, Lcol, 1) < 80 THEN
 LOCATE Ulin2, Rcol2 + 1: IF TRUNC(Ulin, Dlin, 0) > 0 THEN PRINT "Ü";  ELSE PRINT "Û"
 FOR Hset = Ulin2 + 1 TO Dlin2: LOCATE Hset, Rcol2 + 1: PRINT "Û"; : NEXT Hset
END IF
IF Dlin2 < 25 AND Dlin2 > -1 THEN
 IF TRUNC(Lcol, Rcol, 0) < 1 THEN LOCATE Dlin2 + 1, Lcol2 ELSE LOCATE Dlin2 + 1, Lcol2 + 1
 PRINT STRING$(TRUNC(Rcol2, 79, 0) - Lcol2 + 1, "ß");
END IF

END SUB

DEFSNG A-Z
SUB LABEL (Ulin, Lcol, Text$)
LOCATE Ulin, Lcol
PRINT Text$;
END SUB

DEFINT A-Z
FUNCTION NUMPROMPT# (Length, Result$, Hlin, Lcol, Keys$)
IF Lcol AND Hlin = 0 THEN Hlin = CSRLIN: Lcol = POS(0)
Sign$ = "D"
Change = -1
PreLen = Length

DO
 IF Change THEN
  LOCATE Hlin, Lcol, 0
  PRINT RIGHT$(Result$, Length);
  PreCur = CSRLIN: PrePos = POS(0)
  IF LEN(Result$) < PreLen AND LEN(Result$) < Length THEN
   PRINT SPACE$(PreLen - LEN(Result$));
  END IF
  LOCATE PreCur, PrePos, 1, 5, 6
  Change = 0
  PreLen = LEN(Result$)
 END IF

 Kbd$ = INKEY$
 SELECT CASE Kbd$
 CASE "0" TO "9", "a" TO "f"
  IF LEFT$(Result$, 1) = "0" THEN Result$ = RIGHT$(Result$, LEN(Result$) - 1)
  IF LEN(Result$) < Length THEN Result$ = Result$ + Kbd$
  Change = -1
 CASE CHR$(8)
  IF Result$ > "" THEN
   Result$ = LEFT$(Result$, LEN(Result$) - 1)
   Change = -1
  END IF
 CASE "H", "O", "T", "h", "o", "t"
  Sign$ = UCASE$(Kbd$)
  SOUND 1024, 1
  Change = -1
 CASE ""
   NUMPROMPT# = 0
   Keys$ = ""
   EXIT FUNCTION
 CASE ELSE
   IF Kbd$ > "" THEN Keys$ = Kbd$: Done = -1
 END SELECT
LOOP UNTIL Done

LOCATE , , 0
IF Sign$ = "H" THEN Result$ = "&" + Sign$ + Result$
IF Sign$ = "O" THEN Result$ = "&" + Sign$ + Result$
NUMPROMPT# = VAL(Result$)
END FUNCTION

SUB SCROLLBAR (AF1, AF2, AT1, AT2, Side1, Side2, Lin, Mode)

TBL = ABS(Side2 - Side1 + SGN(Side2 - Side1)) - 2
ABL = ABS(AT1 - AT2 + SGN(AT1 - AT2))
 IF TBL < 1 OR ABL = 0 THEN EXIT SUB
TPL = TRUNC(TRUNC(ABS(AF1 - AF2 + SGN(AF1 - AF2)), 1, 1) * TBL / ABL, 1, 1)
TPO = (TRUNC((AF1), (AF2), 0) - AT1) * TBL / TRUNC((AT1), (AT2), 1)

RPL = TRUNC(TPL - TRUNC(TPO + TPL - TBL, 0, 1), 0, 1): RPO = TPO
IF TPO < 0 THEN RPL = TRUNC(TPL + TPO, 0, 1): RPO = 0 ELSE IF TPO >= TBL THEN RPO = 0
Bar$ = STRING$(TBL, 176): MID$(Bar$, 1 + RPO, RPL) = STRING$(RPL, "Û")

IF Mode THEN
 LOCATE Side1, Lin: IF TPO < 0 THEN PRINT "";  ELSE PRINT "";
 LOCATE Side2, Lin: IF TPO + TPL > TBL THEN PRINT "";  ELSE PRINT "";
 FOR Vset = 1 TO TBL
  LOCATE Side1 + Vset, Lin
  PRINT MID$(Bar$, Vset, 1);
 NEXT Vset
ELSE
 LOCATE Lin, Side1: IF TPO < 0 THEN PRINT "®";  ELSE PRINT "";
 LOCATE Lin, Side2: IF TPO + TPL > TBL THEN PRINT "¯";  ELSE PRINT "";
 LOCATE Lin, TRUNC((Side1), (Side2), 0) + 1: PRINT Bar$;
END IF
END SUB

FUNCTION STRPROMPT$ (Length, RecLen, Result$, Hlin, Lcol, Keys$)
IF Lcol AND Hlin = 0 THEN Hlin = CSRLIN: Lcol = POS(0)
Change = -1
Done = 0
PreLen = Length

DO
 IF Change THEN
  LOCATE Hlin, Lcol, 0: PRINT RIGHT$(Result$, Length);
  PreCur = CSRLIN: PrePos = POS(0)
  IF LEN(Result$) < PreLen AND LEN(Result$) < Length THEN
   PRINT SPACE$(PreLen - LEN(Result$));
  END IF
  LOCATE PreCur, PrePos
  IF PrintAll THEN LOCATE , , 1, 3, 6 ELSE LOCATE , , 1, 5, 6
  PreLen = LEN(Result$)
  Change = 0
 END IF

Kbd$ = INKEY$
SELECT CASE Kbd$
 CASE " " TO "~", "€" TO "ÿ"
  IF LEN(Result$) < RecLen THEN
   Result$ = Result$ + Kbd$: Change = -1
  ELSE SOUND 860, .1
  END IF
  PrintAll = 0
CASE ""
 IF PrintAll THEN
  IF LEN(Result$) < RecLen THEN Result$ = Result$ + Kbd$: Change = -1: PrintAll = 0 ELSE SOUND 860, .1
 ELSE
  PrintAll = -1: Change = -1
 END IF
CASE ELSE
 IF PrintAll AND Kbd$ > "" THEN
  IF LEN(Result$) < RecLen THEN Result$ = Result$ + LEFT$(Kbd$, 1): Change = -1: PrintAll = 0 ELSE SOUND 860, .1
 ELSEIF Kbd$ > "" THEN
  IF Kbd$ = CHR$(8) THEN
   IF Result$ > "" THEN Result$ = LEFT$(Result$, LEN(Result$) - 1)
  ELSEIF Kbd$ = CHR$(27) THEN Result$ = "": Keys$ = "": EXIT DO
  ELSE IF Kbd$ > "" THEN Keys$ = Kbd$: Done = -1
  END IF
  Change = -1
 END IF
END SELECT
LOOP UNTIL Done

LOCATE , , 0
STRPROMPT$ = Result$
END FUNCTION

SUB TEXTWRAP (Hite, Widt, Lcol, Urow, Text$)
IF (Widt OR Hite) = 0 THEN EXIT SUB
FOR Vset = 0 TO Hite - 1
LOCATE Urow + Vset, 1 + Lcol: PRINT MID$(Text$, Vset * Widt + 1, Widt)
NEXT Vset
END SUB

FUNCTION TRUNC (Nmbr1, Nmbr2, Mode)
IF Mode THEN
 IF Nmbr1 > Nmbr2 THEN TRUNC = Nmbr1 ELSE TRUNC = Nmbr2
ELSE
 IF Nmbr1 < Nmbr2 THEN TRUNC = Nmbr1 ELSE TRUNC = Nmbr2
END IF
END FUNCTION

