DEFINT A-Z
DECLARE SUB ShowHelp (Help$)
DECLARE SUB Monitor (Mode, Inpt$, Byte)
DECLARE SUB MonitorPort ()
DECLARE SUB MonitorMem ()
DECLARE SUB MonitorMouse ()
DECLARE SUB MonitorKeys ()
DECLARE SUB MonitorPrint ()
DECLARE SUB MonitorStick ()
DECLARE SUB MemViewer ()
DECLARE SUB KeyReader ()
DECLARE SUB PortScan ()
DECLARE SUB BOX (BoxH, BoxL, Ulin, Lcol, Fore, Back, TitC, TexC, Tit$, Tex$)
DECLARE FUNCTION BIN$ (a)
DECLARE FUNCTION Limit& (a&, b&, c)
DECLARE FUNCTION NumPrompt& (Row, Col, Vis, Lim, Radix, Rslt$, Erst$, InKbd$, OutKbd$)
DECLARE FUNCTION Choices (Choice$(), MenuRow(), MenuCol(), Fore, Back, Wone, OutKbd$)
SCREEN 0, , 0, 0: WIDTH , 50: WIDTH 80, 25: COLOR , 1: VIEW PRINT: CLS : LOCATE , , 0

REDIM SHARED MenuCol(9)
REDIM SHARED MenuRow(9)
REDIM SHARED Choice$(9)

BOX 1, 22, 4, 29, 0, 3, 13, 5, "Bit Analyzer", "   Ver 1.0, Dec 1995"

MainScreen:
DATA 9,31,"Ports",9,41,"Memory",12,31,"Mouse",12,41,"Printer",13,31,"Jstick",13,41,"Keyboard",16,31,"Key Buffer Reader",17,31,"Active Port Finder",18,31,"Memory Viewer",19,31,"BitView Options..."
RESTORE MainScreen: FOR Main = 0 TO 9: READ MenuRow(Main), MenuCol(Main), Choice$(Main): NEXT Main
BOX 1, 22, 8, 29, 8, 7, 12, 15, "", ""
BOX 2, 22, 11, 29, 8, 7, 10, 15, "", ""
BOX 4, 22, 15, 29, 8, 7, 9, 15, "", ""

Decision:
Wone = Choices(Choice$(), MenuRow(), MenuCol(), 15, 7, Wone, OutKbd$)
IF OutKbd$ = CHR$(27) THEN GOTO Ending
IF OutKbd$ <> CHR$(13) THEN GOTO Decision

SELECT CASE Wone
CASE 0: MonitorPort
CASE 1: MonitorMem
CASE 2: MonitorMouse
CASE 3: MonitorPrint
CASE 4: MonitorStick
CASE 5: MonitorKeys
CASE 6: KeyReader
CASE 7: PortScan
CASE 8: MemViewer
CASE 9: GOSUB Options
END SELECT
GOTO MainScreen

Options:
SOUND 1024, 1
BOX 1, 30, 11, 25, 8, 5, 12, 15, "", "There are no options to be set"
WHILE INKEY$ = "": WEND
COLOR 0, 1
FOR Show = 11 TO 14
  LOCATE Show, 25: PRINT SPACE$(34)
NEXT Show
RETURN

Ending:
COLOR 7, 0: LOCATE 25, 1: PRINT
SYSTEM

FUNCTION BIN$ (a)
b$ = "00000000"
IF a AND 1 THEN MID$(b$, 8) = "1"
IF a AND 2 THEN MID$(b$, 7) = "1"
IF a AND 4 THEN MID$(b$, 6) = "1"
IF a AND 8 THEN MID$(b$, 5) = "1"
IF a AND 16 THEN MID$(b$, 4) = "1"
IF a AND 32 THEN MID$(b$, 3) = "1"
IF a AND 64 THEN MID$(b$, 2) = "1"
IF a AND 128 THEN MID$(b$, 1) = "1"
BIN$ = b$
END FUNCTION

SUB BOX (BoxH, BoxL, Ulin, Lcol, Fore, Back, TitC, TexC, Tit$, Tex$)
COLOR Fore, Back
LOCATE Ulin, Lcol: PRINT "Ú"; STRING$(BoxL, 196); "¿";
FOR Hset = Ulin + 1 TO Ulin + BoxH
LOCATE Hset, Lcol: PRINT "³"; SPACE$(BoxL); "³";
NEXT Hset
LOCATE Hset, Lcol: PRINT "À"; STRING$(BoxL, 196); "Ù";
COLOR 0, 0
FOR Hset = 1 TO BoxH + 1: LOCATE Ulin + Hset, Lcol + BoxL + 2: PRINT "  "; : NEXT Hset
LOCATE Ulin + BoxH + 2, Lcol + 2: PRINT SPACE$(BoxL + 2);
LOCATE Ulin, Lcol + 1 + (BoxL - LEN(MID$(Tit$, 1, BoxL))) \ 2: COLOR TitC, Back: PRINT MID$(Tit$, 1, BoxL);
COLOR TexC
FOR V = 1 TO BoxH
LOCATE Ulin + V, Lcol + 1: PRINT MID$(Tex$, ori + 1, BoxL);
ori = ori + BoxL: IF ori >= LEN(Tex$) THEN EXIT FOR
NEXT V
END SUB

FUNCTION Choices (Choice$(), MenuRow(), MenuCol(), Fore, Back, Wone, OutKbd$)
Done = 0: Lim = UBOUND(Choice$): IF Wone <> 1 THEN Prew = 1 ELSE Prew = 0

COLOR Fore, Back
FOR Show = 0 TO Lim
 IF Show <> Wone THEN LOCATE MenuRow(Show), MenuCol(Show): PRINT " "; Choice$(Show); " "
NEXT Show
ShowHelp "  Use the arrow keys to select your choice, and press Enter to choose"

DO
IF Prew <> Wone THEN
 COLOR Fore, Back: LOCATE MenuRow(Prew), MenuCol(Prew): PRINT " "; Choice$(Prew); " "
 COLOR 13: LOCATE MenuRow(Wone), MenuCol(Wone): PRINT ""; Choice$(Wone); ""
END IF

Kbd$ = INKEY$: Prew = Wone
IF Kbd$ > "" THEN
SELECT CASE Kbd$
CASE CHR$(0) + "H": Wone = (Wone + Lim) MOD (Lim + 1)
CASE CHR$(0) + "P": Wone = (Wone + 1) MOD (Lim + 1)
CASE CHR$(0) + "K": Wone = (Wone + Lim) MOD (Lim + 1)
CASE CHR$(0) + "M": Wone = (Wone + 1) MOD (Lim + 1)
CASE ELSE: OutKbd$ = Kbd$: Done = -1
END SELECT
END IF
LOOP UNTIL Done

Choices = Wone
END FUNCTION

SUB KeyReader
PCOPY 0, 1
SCREEN 0, , 0, 0
FOR grow = 0 TO 72 STEP 4
BOX 5, grow, 12, INT(40 - (grow / 2)), 10, 3, 15, 8, "", ""
NEXT grow
BOX 5, 72, 12, 4, 10, 3, 15, 4, "Key Buffer Reader", ""
ShowHelp "  This shows the present keylock state and the 16-key buffer   Esc Ä Done"
COLOR 0, 3
LOCATE 16, 11: PRINT "Keylock status: Shift, Alt, Ctrl, plus Caps, Scroll, and Num Lock"
LOCATE 17, 11: PRINT "Key Input counter: 16 place range 30 - 60 Memory location 1050"
LOCATE 13, 37: PRINT "- ASCII symbol code": LOCATE , 37: PRINT "- Keyboard Scancode":
COLOR 15, 0
FOR hole = 5 TO 36 STEP 2
LOCATE 13, hole: PRINT " ": LOCATE 14, hole: PRINT " "
NEXT
COLOR 15, 3
DO: DEF SEG = 0
LOCATE 16, 6: PRINT LEFT$(STR$(PEEK(1047)) + "   ", 4)
LOCATE 17, 6: PRINT LEFT$(STR$(PEEK(1050)) + "   ", 4)
FOR rpt = 0 TO 31 STEP 2
DEF SEG = 0: buffer = PEEK(rpt + 1054)
DEF SEG = &HB878: POKE (4 + rpt) * 2, buffer
DEF SEG = 0: buffer = PEEK(rpt + 1055)
DEF SEG = &HB878: POKE (84 + rpt) * 2, buffer
NEXT rpt
LOOP UNTIL INKEY$ = ""
PCOPY 1, 0
END SUB

DEFSNG A-Z
FUNCTION Limit& (a&, b&, c%)
IF c% THEN 'Greater
 IF a& >= b& THEN Limit = a& ELSE Limit = b&
ELSE 'Lesser
 IF a& <= b& THEN Limit = a& ELSE Limit = b&
END IF
END FUNCTION

DEFINT A-Z
SUB MemViewer
PCOPY 0, 1
BOX 17, 64, 2, 7, 10, 3, 15, 15, "Memory Viewer", ""
COLOR 15, 7
FOR Vset = 3 TO 18
LOCATE Vset, 8: PRINT SPACE$(64)
NEXT Vset
ShowHelp "  Use the cursor keys to scroll or type in an address. ESC-Go Back"
COLOR 15, 3: Change = -1
DO UNTIL Kybd$ = ""

IF Change THEN
segm& = INT(ofset& / 16)
pk = Start& MOD 16
Move = 0
FOR Vset = 320 TO 2720 STEP 160
FOR Hset = 14 TO 140 STEP 2
DEF SEG = segm&: Memory% = PEEK(pk + Move)
DEF SEG = &HB800: POKE Vset + Hset, Memory%
Move = Move + 1
NEXT Hset, Vset
 LOCATE 19, 8
 PRINT "Absolute address range:"; STR$(ofset&); " -"; STR$(ofset& + 1023);
 LOCATE , 50: PRINT "Segment:"; STR$(segm&); " "; HEX$(segm&); "  "
 Change = 0
END IF

WHILE INKEY$ > "": WEND
DO: Kybd$ = INKEY$: LOOP UNTIL Kybd$ > ""
IF Kybd$ > "" THEN Change = -1
SELECT CASE Kybd$
CASE CHR$(0) + "H": ofset& = Limit(ofset& - 64, 0, 1)
CASE CHR$(0) + "P": ofset& = Limit(ofset& + 64, 1048575, 0)
CASE CHR$(0) + "I": ofset& = Limit(ofset& - 1024, 0, 1)
CASE CHR$(0) + "Q": ofset& = Limit(ofset& + 1024, 1048575, 0)
CASE CHR$(0) + "s": ofset& = Limit(ofset& - 4096, 0, 1)
CASE CHR$(0) + "t": ofset& = Limit(ofset& + 4096, 1048575, 0)
CASE CHR$(0) + "G": ofset& = 0
CASE CHR$(0) + "O": ofset& = 1048575
CASE "0" TO "9": LOCATE 19, 8: PRINT "Enter another address?:"; SPACE$(18)
ofset2& = NumPrompt(19, 32, 8, 7, 10, Kybd$, "", "", Keys$)
IF Keys$ = CHR$(13) THEN ofset& = Limit(ofset2&, 1048575, 0)
END SELECT
LOOP
PCOPY 1, 0
END SUB

SUB Monitor (Mode, Inpt$, Byte)
IF Mode AND 1 THEN
 BOX 2, 20, 11, 6, 0, 3, 14, 0, "", ""
 BOX 2, 46, 11, 28, 0, 3, 14, 0, "", " DECIMAL HEXADECIMAL BINARY-CODE ASCII SYMBOL": DEF SEG = &HB800: POKE 2053, 63
END IF
IF Mode AND 2 THEN
 COLOR 15, 3
 FOR V = 12 TO 13
  Back$ = SPACE$(20): MID$(Back$, 1) = MID$(Inpt$, ori + 1, 20)
  LOCATE V, 7: PRINT Back$
  ori = ori + 20
 NEXT V
ELSEIF Mode AND 4 THEN
 COLOR 15, 3
 LOCATE 13, 31: PRINT Byte%; "  ";
 LOCATE , 42: PRINT HEX$(Byte%); "  ";
 LOCATE , 51: PRINT BIN$(Byte%);
 DEF SEG = &HB800: POKE 2052, Byte%
ELSEIF Mode = 0 THEN
 COLOR 0, 1
 FOR Show = 11 TO 15
  LOCATE Show, 6: PRINT SPACE$(72)
 NEXT Show
END IF
END SUB

SUB MonitorKeys
Monitor 3, " Keyboard Ä CON      Port 96, 60h", 0
ShowHelp "  Press any key to see its scancode on the monitor ù Esc when done"
DO
Monitor 4, "", INP(96)
LOOP UNTIL INKEY$ = ""
Monitor 0, "", 0
END SUB

SUB MonitorMem
Monitor 1, "", 0
ShowHelp "  ( ), ( ), (0-9) Ä Change address   Space Ä Pause   Enter Ä Done": Chng = 1
DO
IF NewN THEN Addr$ = LTRIM$(STR$(address&)): NewN = 0
IF Chng THEN segment& = address& \ 16: ofset& = address& MOD 16: Monitor 2, " PC Mem 0-1048575    Address:" + STR$(address&), 0: Chng = 0
DEF SEG = segment&: Monitor 4, "", PEEK(ofset&)

Kbd$ = INKEY$
IF Kbd$ > "" THEN
SELECT CASE Kbd$
CASE " ": WHILE INKEY$ = "": WEND
CASE "", CHR$(13): EXIT DO
CASE CHR$(0) + "M": address& = Limit(address& + 1, 1048575, 0): NewN = 1
CASE CHR$(0) + "K": address& = Limit(address& - 1, 0, 1): NewN = 1
CASE CHR$(0) + "H": address& = Limit(address& + 10, 1048575, 0): NewN = 1
CASE CHR$(0) + "P": address& = Limit(address& - 10, 0, 1): NewN = 1
CASE "0" TO "9", "": COLOR 15, 1: address& = Limit(Limit(NumPrompt(15, 14, 0, 7, 10, Addr$, Addr$, Kbd$, ""), 1048575, 0), 0, 1)
END SELECT
Chng = -1
END IF
LOOP

Monitor 0, "", 0
END SUB

SUB MonitorMouse
Monitor 3, " Mouse Ä COM1        Port 1016, 3F8h", 0
ShowHelp "  Move your mouse around or press the buttons and watch it on the monitor"
DO
Monitor 4, "", INP(&H3F8)
Kbd$ = INKEY$
IF Kbd$ = " " THEN SLEEP
LOOP UNTIL Kbd$ = "" OR Kbd$ = CHR$(13)
Monitor 0, "", 0
END SUB

SUB MonitorPort
Monitor 1, "", 0
ShowHelp "  ( ), ( ), (0-9) Ä Change address   Space Ä Pause   Enter Ä Done": Chng = 1
DO
IF NewN THEN Port$ = LTRIM$(STR$(address&)): NewN = 0
IF Chng THEN Monitor 2, " PC Ports 0-65535    Address:" + LEFT$(STR$(address&) + ",    ", 7) + HEX$(address&), 0: Chng = 0
Monitor 4, "", INP(address&)

Kbd$ = INKEY$
IF Kbd$ > "" THEN
SELECT CASE Kbd$
CASE " ": WHILE INKEY$ = "": WEND
CASE "", CHR$(13): EXIT DO
CASE CHR$(0) + "M": address& = Limit(address& + 1, 65535, 0): NewN = 1
CASE CHR$(0) + "K": address& = Limit(address& - 1, 0, 1): NewN = 1
CASE CHR$(0) + "H": address& = Limit(address& + 10, 65535, 0): NewN = 1
CASE CHR$(0) + "P": address& = Limit(address& - 10, 0, 1): NewN = 1
CASE "0" TO "9", "": address& = Limit(Limit(NumPrompt(15, 14, 0, 5, 10, Port$, Port$, Kbd$, ""), 65535, 0), 0, 1)
END SELECT
Chng = -1
END IF
LOOP
Monitor 0, "", 0
END SUB

SUB MonitorPrint
Monitor 3, " Printer Ä LPT1      Port 888, 378h", 0
ShowHelp "  This shows the current status from the printer such as on/off, paper out,.."
DO
Monitor 4, "", INP(&H378)
Kbd$ = INKEY$
IF Kbd$ = " " THEN SLEEP
LOOP UNTIL Kbd$ = "" OR Kbd$ = CHR$(13)
Monitor 0, "", 0
END SUB

SUB MonitorStick
Monitor 3, " JoyStick Ä SOUND    Port 512, 200h", 0
ShowHelp "  Move your joystick or press the buttons and watch on the monitor"
DO
Monitor 4, "", INP(&H200)
Kbd$ = INKEY$
IF Kbd$ = " " THEN SLEEP
IF Kbd$ = CHR$(13) THEN EXIT DO
LOOP UNTIL Kbd$ = ""
Monitor 0, "", 0
END SUB

FUNCTION NumPrompt& (Row, Col, Vis, Lim, Radix, Prst$, Erst$, InKbd$, OutKbd$)
IF Radix = 0 THEN EXIT FUNCTION
Rslt$ = Prst$: Result& = VAL(Rslt$): Chng = 1
IF InKbd$ > "" THEN Done = 1

DO
IF Chng THEN
 Sign$ = MID$("       o t     h", Radix, 1)
 IF Sign$ = "t" THEN Rslt& = VAL(Rslt$) ELSE Rslt& = VAL("&" + Sign$ + Rslt$)
 IF Rslt$ = "" THEN Rslt$ = "0"
 LOCATE Row, Col, 0: PRINT LEFT$(Rslt$ + SPACE$(Vis), Vis);
 IF LEN(Rslt$) < Vis THEN LOCATE , Col + LEN(Rslt$), 1 ELSE LOCATE , Row + Vis
 Chng = 0
END IF

Chng = -1
IF Done THEN Kbd$ = InKbd$ ELSE Kbd$ = INKEY$
SELECT CASE UCASE$(Kbd$)
CASE "0" TO "9", "A" TO "F"
IF INSTR(LEFT$("0123456789ABCDEF", Radix), Kbd$) AND LEN(Rslt$) < Lim THEN
 IF Rslt$ = "0" THEN Rslt$ = Kbd$ ELSE Rslt$ = Rslt$ + Kbd$
END IF
CASE "-", "+": IF LEFT$(Rslt$, 1) = "-" THEN Rslt$ = RIGHT$(Rslt$, LEN(Rslt$) - 1) ELSE Rslt$ = "-" + Rslt$
CASE "H": Rslt$ = HEX$(Rslt&): Radix = 16
CASE "O": Rslt$ = OCT$(Rslt&): Radix = 8
CASE "T": Rslt$ = LTRIM$(STR$(Rslt&)): Radix = 10
CASE CHR$(8): IF Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, LEN(Rslt$) - 1)
CASE "": Chng = 0
CASE ELSE: IF LEN(Kbd$) = 2 OR ASC(Kbd$) < 32 THEN OutKbd$ = Kbd$: Done = -1
END SELECT
LOOP UNTIL Done

LOCATE Row, Col, 0
Erst$ = Rslt$
IF Sign$ = "t" THEN NumPrompt& = VAL(Rslt$) ELSE NumPrompt& = VAL("&" + Sign$ + Rslt$)
END FUNCTION

SUB PortScan
WHILE INKEY$ > "": WEND
PCOPY 0, 1
FOR grow = 0 TO 15
BOX grow, grow * 4.8, 4, 39 - (grow * 2.4), 10, 3, 15, 8, "", ""
NEXT grow
BOX 15, 72, 4, 3, 10, 3, 15, 8, "Port Searcher", ""
WHILE INKEY$ > "": WEND
WHILE INKEY$ = "": WEND
PCOPY 1, 0
END SUB

DEFSNG A-Z
SUB ShowHelp (Help$)
COLOR 15, 3: LOCATE 25, 1: PRINT LEFT$(Help$, 80);
IF LEN(Help$) < 80 THEN PRINT SPACE$(80 - LEN(Help$));
END SUB

