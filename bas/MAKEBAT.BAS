DEFINT A-Z
DECLARE SUB PROMPT (Frst$, Last$, KeyIn$, KeyOut$, Lim%, Vis%, Row%, Col%, Curp%, Done%)
Row = CSRLIN: Col = POS(0): VIEW PRINT: LOCATE Row, Col
PRINT : PRINT "ÄÄÄ Batch Maker 1.0 ÄÄÄ";

GetName:
PRINT
PRINT "Path or Filename:";
Entry = CSRLIN
DO
 PROMPT file$, file$, "", key$, 127, 60, Entry, 19, Curp, 0
LOOP UNTIL key$ = CHR$(13) OR key$ = CHR$(27) OR key$ = CHR$(10) OR key$ = CHR$(0) + ";"
PRINT
IF key$ = CHR$(27) THEN SYSTEM
IF key$ = CHR$(10) THEN PRINT : SHELL "DIR/B/P/ON/A-D " + file$: GOTO GetName
IF key$ = CHR$(0) + ";" OR file$ = "" THEN GOSUB Help: GOTO GetName
Curp = -1

OpenFile:
ON ERROR GOTO DirErr
DirErr = 0: CHDIR file$: IF DirErr = 0 THEN GOTO GetName
ON ERROR GOTO FilErr
FilErr = 0: OPEN file$ FOR INPUT AS #1: CLOSE #1
IF FilErr = 0 THEN
 PRINT "File already exists, write over it? [Yes/No] ";
 DO
  kbrd$ = UCASE$(INKEY$): IF kbrd$ = CHR$(13) THEN kbrd$ = "Y" ELSE IF kbrd$ = CHR$(27) THEN kbrd$ = "N"
 LOOP UNTIL kbrd$ = "Y" OR kbrd$ = "N"
 PRINT kbrd$
 IF kbrd$ = "N" THEN GOTO GetName
END IF
FilErr = 0: OPEN file$ FOR OUTPUT AS #1
IF FilErr THEN PRINT "Error opening file, press any key to continue": WHILE INKEY$ = "": WEND: GOTO GetName
PRINT "File is opened þ"
PRINT
Entry = 1
AllDone = 0: DO UNTIL AllDone OR Entry > 999
 Row = CSRLIN
 Text$ = ""
 EntryDone = 0: DO UNTIL EntryDone
  LOCATE Row, 1: PRINT "Line" + LEFT$(STR$(Entry) + ":", 5);
  PROMPT Text$, Text$, "", key$, 256, 70, Row, 10, -1, 0
  SELECT CASE key$
  CASE CHR$(0) + "H": Text$ = Ptxt$
  CASE CHR$(13): PRINT #1, Text$: PRINT : EntryDone = 1: Entry = Entry + 1
  CASE CHR$(27): EntryDone = 1: AllDone = 1
  CASE CHR$(10): PRINT #1, Text$; : EntryDone = 1: PRINT
  CASE CHR$(0) + ";": GOSUB Help: PRINT
  END SELECT
 LOOP
 Ptxt$ = Text$
LOOP
DO: key$ = INKEY$: LOOP UNTIL INP(96) AND 128: key$ = INKEY$
PRINT
PRINT "File is closed þ"
CLOSE #1
GOTO GetName

DirErr: DirErr = -1: RESUME NEXT
FilErr: FilErr = ERR: RESUME NEXT

Help:
PRINT
PRINT "At any time:"
PRINT TAB(10); "F1 - Bring up help"
PRINT
PRINT "While entering a path and filename:"
PRINT TAB(10); "ENTER - Choose as output file"; TAB(50); "ESC - Cancel and quit"
PRINT TAB(10); "Ctrl+ENTER (with any parameters) - Gets a list of files"
PRINT
PRINT "When outputting to a file:"
PRINT TAB(10); "ENTER      - Commit line to file and goto next line"
PRINT TAB(10); "Ctrl+ENTER - Send line to file without a CR"
PRINT TAB(10); "UP arrow   - Retrieve last line"
PRINT TAB(10); "ESC        - Quit editing and close the file"
RETURN

SUB PROMPT (Frst$, Last$, KeyIn$, KeyOut$, Lim, Vis, Row, Col, Curp, Done)
IF Row = 0 THEN Row = CSRLIN
IF Col = 0 THEN Col = POS(0)
IF Curp = -1 THEN Curp = LEN(Frst$)
Rslt$ = Frst$
Chng = 1
kbrd$ = KeyIn$

DO
 Leng = LEN(Rslt$)
 SELECT CASE kbrd$
 CASE ""
 CASE " " TO "ÿ": GOSUB PromptInsert: Chng = 1
 CASE CHR$(0) + "S": IF Curp < Leng AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp) + RIGHT$(Rslt$, Leng - Curp - 1): Chng = 1
 CASE CHR$(8): IF Curp > 0 AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp - 1) + RIGHT$(Rslt$, Leng - Curp): Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "K": IF Curp > 0 THEN Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "M": IF Curp < Leng THEN Curp = Curp + 1: Chng = 1
 CASE CHR$(0) + "G": Curp = 0: Chng = 1
 CASE CHR$(0) + "O": Curp = Leng: Chng = 1
 CASE ELSE: KeyOut$ = kbrd$: Done = 1
 END SELECT

 IF Chng THEN
  Leng = LEN(Rslt$)
  IF Curp > Leng THEN Curp = Leng ELSE IF Curp < 0 THEN Curp = 0
  IF Curp < Ofst THEN Ofst = Curp ELSE IF Curp >= Ofst + Vis THEN Ofst = Curp - Vis + 1
  LOCATE , , 0: LOCATE Row, Col: PRINT MID$(Rslt$ + SPACE$(Vis), Ofst + 1, Vis);
  LOCATE , , 1: LOCATE Row, Col + (Curp - Ofst)
  Chng = 0
 END IF

 kbrd$ = INKEY$
LOOP UNTIL Done

Last$ = Rslt$
EXIT SUB

PromptInsert:
 IF LEN(kbrd$) + LEN(Rslt$) > Lim THEN SOUND 860, .1: RETURN
 Rslt$ = LEFT$(Rslt$, Curp) + kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - Curp)
 Curp = Curp + 1
RETURN
END SUB

