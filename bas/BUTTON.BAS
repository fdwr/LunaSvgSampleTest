DECLARE FUNCTION BUTTON% (Lcol%, Rcol%, Ulin%, Dlin%, Fore%, Back%, Sfor%, Sbak%, Titl$, Keys$)
DECLARE SUB DRAWBUTTON (Lcol%, Rcol%, Ulin%, Dlin%, Fore%, Back%, Sfor%, Sbak%, Titl$)
DECLARE FUNCTION TRUNC% (Nmbr%, Nmbr2%, Mode%)
COLOR 0, 7: CLS
DRAWBUTTON 20, 61, 3, 3, 0, 4, 7, 8, "Press Me if you want to exit"
DRAWBUTTON 20, 61, 5, 5, 0, 2, 7, 8, "I don't do anything"
DRAWBUTTON 20, 39, 9, 15, 0, 3, 7, 8, "Press Me"
DRAWBUTTON 42, 61, 7, 13, 0, 3, 7, 8, "Use the SPACE BAR."
DRAWBUTTON 20, 39, 7, 7, 0, 5, 7, 8, "I make a high beep"
DRAWBUTTON 42, 61, 15, 15, 0, 1, 7, 8, "I make a low beep"
object = 3

DO UNTIL Done: Keys$ = ""

IF object = 0 THEN Done = BUTTON(20, 61, 3, 3, 0, 4, 7, 8, "Press Me if you want to exit", Keys$)

IF object = 1 THEN d = BUTTON(20, 61, 5, 5, 0, 2, 7, 8, "I don't do anything", Keys$)

IF pmt THEN pmt2 = pmt2 XOR 1
IF pmt2 THEN PressMe$ = "Press Me Again" ELSE PressMe$ = "Press Me"
IF object = 3 THEN pmt = BUTTON(20, 39, 9, 15, 0, 3, 7, 8, PressMe$, Keys$)

presor$ = MID$("Press Me, or else    Or else what      Or else I'll   Beep like this", presor + 1, 18)
IF object = 4 THEN DidPress = BUTTON(42, 61, 7, 13, 0, 3, 7, 8, presor$, Keys$)
IF DidPress THEN presor = presor + 18: IF presor = 54 THEN SOUND 1024, 1 ELSE IF presor > 54 THEN presor = 0

IF object = 2 THEN DoSoundHih = BUTTON(20, 39, 7, 7, 0, 5, 7, 8, "I make a high beep", Keys$)
IF DoSoundHih THEN SOUND 2048, 3

IF object = 5 THEN DoSoundLow = BUTTON(42, 61, 15, 15, 0, 1, 7, 8, "I make a low beep", Keys$)
IF DoSoundLow THEN SOUND 64, 3

NextItem = -1: Data$ = ""
IF Keys$ = "" THEN Keys$ = INKEY$
SELECT CASE Keys$
CASE CHR$(0) + "K": Data$ = ",4,5=3"
CASE CHR$(0) + "M": Data$ = ",2,3=4"
CASE CHR$(0) + "H": Data$ = ",1=0,2=1,3=2,5=4,4=1"
CASE CHR$(0) + "P": Data$ = ",0=1,1=2,2=3,4=5"
CASE CHR$(9): Data$ = ",0=1,1=2,2=3,3=4,4=5,5=0"
CASE CHR$(0) + CHR$(15): Data$ = ",5=4,4=3,3=2,2=1,1=0,0=5"
CASE "": Done = -1
CASE "": NextItem = 0
END SELECT
IF NextItem AND INSTR(Data$, "," + LTRIM$(STR$(object))) THEN object = VAL(MID$(Data$, INSTR(INSTR(Data$, "," + LTRIM$(STR$(object))), Data$, "=") + 1))
LOOP

END

DEFINT A-Z
FUNCTION BUTTON (Lcol, Rcol, Ulin, Dlin, Fore, Back, Sfor, Sbak, Titl$, Keys$)

DRAWBUTTON Lcol, Rcol, Ulin, Dlin, 15, Back, Sfor, Sbak, Titl$
DO UNTIL Done
 IF INP(96) = 57 THEN
  DRAWBUTTON Lcol, Rcol, Ulin, Dlin, Back, Fore, Sfor, Sfor, Titl$
  WHILE INP(96) = 57: Kbd$ = INKEY$: WEND
  IF INP(96) = 185 THEN Keys$ = " ": BUTTON = -1: Done = -1 ELSE DRAWBUTTON Lcol, Rcol, Ulin, Dlin, 15, Back, Sfor, Sbak, Titl$
 END IF
 Kbd$ = INKEY$
 SELECT CASE Kbd$
 CASE "": CASE " ": BUTTON = -1
 CASE ELSE: BUTTON = 0: Keys$ = Kbd$: Done = -1
 END SELECT
LOOP
DRAWBUTTON Lcol, Rcol, Ulin, Dlin, Fore, Back, Sfor, Sbak, Titl$

END FUNCTION

SUB DRAWBUTTON (Lcol, Rcol, Ulin, Dlin, Fore, Back, Sfor, Sbak, Titl$)
Ulin2 = TRUNC(TRUNC(Ulin, Dlin, 0), 1, 1)
Dlin2 = TRUNC(TRUNC(Dlin, Ulin, 1), 25, 0)
Lcol2 = TRUNC(TRUNC(Lcol, Rcol, 0), 1, 1)
Rcol2 = TRUNC(TRUNC(Rcol, Lcol, 1), 80, 0)
BLen = Rcol2 - Lcol2 + 1: COLOR Fore, Back

FOR Hset = Ulin2 TO Dlin2: LOCATE Hset, Lcol2: PRINT SPACE$(BLen); : NEXT Hset
LOCATE Ulin2 + INT((Dlin2 - Ulin2) / 2), Lcol + (BLen - LEN(LEFT$(Titl$, BLen))) / 2
PRINT LEFT$(Titl$, BLen);

COLOR Sfor, Sbak
IF TRUNC(Rcol, Lcol, 1) < 80 THEN
 LOCATE Ulin2, Rcol2 + 1: IF TRUNC(Ulin, Dlin, 0) > 0 THEN PRINT "ß";  ELSE PRINT "Û"
 FOR Hset = Ulin2 + 1 TO Dlin2: LOCATE Hset, Rcol2 + 1: PRINT " "; : NEXT Hset
END IF
IF Dlin2 < 25 AND Dlin2 > -1 THEN
 IF TRUNC(Lcol, Rcol, 0) < 1 THEN LOCATE Dlin2 + 1, Lcol2 ELSE LOCATE Dlin2 + 1, Lcol2 + 1
 PRINT STRING$(TRUNC(Rcol2, 79, 0) - Lcol2 + 1, "Ü");
END IF

END SUB

FUNCTION TRUNC (Nmbr1, Nmbr2, Mode)
IF Mode THEN
 IF Nmbr1 > Nmbr2 THEN TRUNC = Nmbr1 ELSE TRUNC = Nmbr2
 'Choose the Greater
ELSE
 IF Nmbr1 < Nmbr2 THEN TRUNC = Nmbr1 ELSE TRUNC = Nmbr2
 'Choose the Lesser
END IF
END FUNCTION

