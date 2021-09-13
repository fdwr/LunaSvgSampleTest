DEFLNG A-Z
SCREEN 0: WIDTH 80, 25
LOCATE 1, 1: PRINT "Simple Port Input Viewer, Ver 1.0, 3-1996, Programmer: Dwayne Robinson Demmer"
LOCATE 25, 1: PRINT "Use [ ][ ][+ -] to change port number:";
VIEW PRINT 2 TO 24: LOCATE 24, 1: Done% = 0: Pinp = -1: Mode% = 0: Paws% = -1

DO UNTIL Done%
IF Paws% THEN IF Mode% THEN SOUND INP(Inpt) + 256, .125 ELSE PRINT INP(Inpt),

Kbrd% = INP(96): Kbrd$ = INKEY$
IF Kbrd$ > "" OR (Kbrd% XOR 128) THEN
 GOSUB Respond
 IF Inpt > 65535 THEN Inpt = 65535
 IF Inpt < 0 THEN Inpt = 0
 IF Inpt <> Pinp THEN GOSUB Info: Pinp = Inpt
END IF
LOOP
VIEW PRINT: LOCATE 25: PRINT : SYSTEM

Respond:
IF Kbrd$ = CHR$(27) THEN Done% = -1
IF Kbrd$ = "	" THEN Mode% = Mode% XOR -1: GOSUB Info
IF Kbrd$ = " " THEN Paws% = Paws% XOR -1: GOSUB Info
IF Kbrd$ = "+" THEN Inpt = Inpt + 1
IF Kbrd$ = "-" THEN Inpt = Inpt - 1
IF Kbrd% = 77 THEN Inpt = Inpt + 1
IF Kbrd% = 75 THEN Inpt = Inpt - 1
IF Kbrd% = 72 THEN Inpt = Inpt + 100
IF Kbrd% = 80 THEN Inpt = Inpt - 100
RETURN

Info:
PreV% = CSRLIN: PreH% = POS(0): VIEW PRINT
LOCATE 25, 43: PRINT MID$(STR$(Inpt) + "     ", 2, 6); : PRINT " [Tab]: ";
IF Mode% THEN PRINT "þ))";  ELSE PRINT ")-=ð";
IF Paws% THEN PRINT "  [Space]: pauses  ";  ELSE PRINT "  [Space]: unpauses";
VIEW PRINT 2 TO 24: LOCATE PreV%, PreH%
RETURN

