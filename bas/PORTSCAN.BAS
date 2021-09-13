DEFINT A-Z: CLS
LOCATE 3, 9: PRINT ":Current port being checked for activity";
LOCATE 4, 9: PRINT ":Last port detected to have activity";
LOCATE 5, 9: PRINT ":Number of ports detected as active";

GetPorts:
text$ = "": GOSUB Menu
LOCATE 1, 1: LINE INPUT "Enter Starting Port:", StrPort$: StrPort& = VAL(LEFT$(StrPort$, 5))
LOCATE 1, 29: LINE INPUT "Enter Ending Port:", EndPort$: EndPort& = VAL(LEFT$(EndPort$, 5))
LOCATE 1, 55: LINE INPUT "Number of checks:", ChkPort$: ChkPort = VAL(LEFT$(ChkPort$, 5))
IF StrPort& < 0 THEN StrPort& = 0 ELSE IF StrPort& > 65535 THEN StrPort& = 65535
IF EndPort& < 0 THEN EndPort& = 0 ELSE IF EndPort& > 65535 THEN EndPort& = 65535
IF ChkPort < 2 THEN ChkPort = 20 ELSE IF ChkPort > 255 THEN ChkPort = 255
LOCATE 7, 1: PRINT "Active Port List: Range ="; StrPort&; "thru"; EndPort&; "at"; ChkPort; "checks          "

Startscan:
text$ = "Searching, Press ESC to cancel": GOSUB Menu
LOCATE 3, 1: PRINT "       "
FOR Port& = StrPort& TO EndPort&
 LOCATE 3, 1: PRINT Port&; " ";
 preCheck = INP(Port&)
 FOR checknumber = 1 TO ChkPort
  check = INP(Port&)
  IF check% <> preCheck% THEN GOSUB Active: EXIT FOR
 NEXT checknumber%
 IF INKEY$ = "" THEN GOSUB Pause
NEXT Port&

Ending:
text$ = "This scan is done: S-Scan again, P-Print active port list, or ESC-Exit ?": GOSUB Menu
LOCATE 3, 1: PRINT " (None)";
DO: user$ = UCASE$(INKEY$): LOOP UNTIL user$ > ""
IF user$ = "S" THEN GOTO GetPorts
IF user$ = "P" THEN LPRINT portlist$
IF user$ = "" THEN LOCATE 25, 1: SYSTEM ELSE GOTO Ending

Active:
LOCATE 4, 1: PRINT Port&;
IF INSTR(1, portlist$, STR$(Port&)) = 0 THEN
 Actv = Actv + 1: LOCATE 5, 1: PRINT Actv
 portlist$ = portlist$ + STR$(Port&): LOCATE 8, 1: PRINT portlist$
END IF
RETURN

Pause:
pret$ = text$: text$ = "Do you want to quit the scan? Y/N": GOSUB Menu
DO: user$ = UCASE$(INKEY$): LOOP UNTIL user$ > ""
text$ = pret$: pret$ = ""
IF user$ = "Y" THEN GOTO Ending
IF user$ = "N" THEN GOSUB Menu: RETURN ELSE GOTO Pause

Menu:
LOCATE 1, 1: PRINT SPACE$(80);
LOCATE 1, 1: PRINT text$
RETURN

