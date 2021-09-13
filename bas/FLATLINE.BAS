DEFINT A-Z
DECLARE FUNCTION NumPrompt& (limit, radix, Rslt$, Keys$)
radix = 10: StepIt! = .125
SCREEN 12

GetNum:
LOCATE 1, 1: PRINT "Enter a port number 0-65535 to monitor (H-Hex,T-Dec,O-Oct): ";
port& = NumPrompt(5, radix, port$, Keys$): IF port& > 65535 THEN port& = 65535
IF Keys$ = CHR$(13) THEN GOSUB Info ELSE IF Keys$ = CHR$(27) THEN END ELSE GOTO GetNum

DO UNTIL Done
 VIEW (0, 16)-(639, 271), 7
 FOR Hset! = 0 TO 639 STEP StepIt!
  PSET (Hset!, INP(port&)), 15
  Kbrd$ = INKEY$
  IF Kbrd$ > "" THEN
   SELECT CASE Kbrd$
   CASE " ": WHILE INP(96) = 57: Kbrd$ = INKEY$: WEND
   CASE CHR$(0) + "H": port& = (port& + 1) AND 65535: GOSUB Info: EXIT FOR
   CASE CHR$(0) + "P": port& = (port& - 1) AND 65535: GOSUB Info: EXIT FOR
   CASE CHR$(0) + "K": IF StepIt! > .03125 THEN StepIt! = StepIt! / 2: EXIT FOR
   CASE CHR$(0) + "M": IF StepIt! < 8 THEN StepIt! = StepIt! * 2: EXIT FOR
   CASE "": Done = -1: EXIT FOR
   CASE CHR$(13): GOTO GetNum
   END SELECT
   GOSUB Info
  END IF
 NEXT Hset!
LOOP
END
Info: LOCATE 1, 1: PRINT "Port:"; port&; TAB(19); "ENTER=View different port   SPACE=Hold pause   ESC=Quit"; : RETURN

FUNCTION NumPrompt& (limit, radix, Rslt$, Keys$)
IF radix < 0 THEN radix = 0
Row = CSRLIN: Col = POS(0)
Result& = VAL(Rslt$): Chng = -1

DO WHILE NOT Done
IF Chng THEN
 Sign$ = MID$("!       o t     h", radix + 1, 1)
 IF Sign$ = "t" THEN Rslt& = VAL(Rslt$) ELSE Rslt& = VAL("&" + Sign$ + Rslt$)
 IF Rslt$ = "" THEN Rslt$ = "0"
 LOCATE Row, Col, 0: PRINT Sign$ + Rslt$ + CHR$(95); "       ";
 Chng = 0
END IF

Chng = -1
Kbd$ = UCASE$(INKEY$)
SELECT CASE Kbd$
CASE "0" TO "9", "A" TO "F"
 IF INSTR(LEFT$("0123456789ABCDEF", radix), Kbd$) AND LEN(Rslt$) < limit THEN
  IF Rslt$ = "0" THEN Rslt$ = Kbd$ ELSE Rslt$ = Rslt$ + Kbd$
 END IF
CASE "-", "+": IF LEFT$(Rslt$, 1) = "-" THEN Rslt$ = RIGHT$(Rslt$, LEN(Rslt$) - 1) ELSE Rslt$ = "-" + Rslt$
CASE "H": Rslt$ = HEX$(Rslt&): radix = 16
CASE "O": Rslt$ = OCT$(Rslt&): radix = 8
CASE "T": Rslt$ = LTRIM$(STR$(Rslt&)): radix = 10
CASE CHR$(8): IF LEN(Rslt$) > 0 THEN Rslt$ = LEFT$(Rslt$, LEN(Rslt$) - 1)
CASE "": Chng = 0
CASE ELSE: Keys$ = Kbd$: Done = -1
END SELECT
LOOP

LOCATE Row, Col: PRINT Sign$; Rslt$; " ";
IF Sign$ = "t" THEN NumPrompt& = VAL(Rslt$) ELSE NumPrompt& = VAL("&" + Sign$ + Rslt$)
END FUNCTION

