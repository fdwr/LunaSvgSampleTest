DEFINT A-Z
DECLARE FUNCTION NL$ ()
DECLARE SUB FILEWRIT (Cmnd$)
DECLARE SUB FILESHOW (Cmnd$)
DECLARE FUNCTION FILEFIND& (Cmnd$)
DECLARE SUB PRINT2 (vset%, Hset%, text$)
DECLARE FUNCTION SelectPart$ (text$, Part%, Ofst)
DECLARE SUB PROMPT (Frst$, Last$, KeyIn$, KeyOut$, Lim, Vis, Row, Col, Curp, Done)
Cmnds$ = ":OPEN:MAKE:HELP:CLOSE:READ:BYTE:FIND:WRITE:SEARCH:DIRLIST:CANDO:CPROMPT:CD:LENG:"

'ON ERROR GOTO FilErrHan
SCREEN 13: VIEW PRINT 1 TO 25: CLS
GOSUB Help
Newl = 1

Main:
WHILE INKEY$ > "": WEND
LOCATE , 1: PRINT "("; file$; "):>";
IF Newl AND 1 THEN Row = CSRLIN: Col = POS(0): Pre$ = Cmnd$: Newl = Newl XOR 1
IF Newl AND 2 THEN Pre$ = Cmnd$: Cmnd$ = "": Newl = Newl XOR 2
IF Newl AND 4 THEN Curp = LEN(Cmnd$)
CmndLen = 36 - LEN(file$)
PROMPT Cmnd$, Cmnd$, "", Key$, 255, CmndLen, Row, Col, Curp, 0
SELECT CASE Key$
CASE CHR$(27): CLOSE : SYSTEM
CASE CHR$(13): IF Cmnd$ > "" THEN PRINT : Newl = 1: HelpPage = 0: GOSUB Decide
CASE CHR$(0) + "H": Cmnd$ = Pre$: Curp = LEN(Cmnd$)
CASE CHR$(0) + "P": IF Cmnd$ > "" THEN Newl = 3
CASE CHR$(0) + ";": GOSUB Help: Newl = 1
CASE CHR$(0) + "<": GOSUB EditHelp: Newl = 1
CASE CHR$(0) + "=": GOSUB Credits: Newl = 1
CASE ELSE: GOTO Main
END SELECT
GOTO Main

Decide:
Cmnd$ = LTRIM$(Cmnd$)
CmndPart$ = UCASE$(SelectPart(Cmnd$, 1, 0))
CmndValid = INSTR(Cmnds$, ":" + CmndPart$)
IF CmndValid = 0 THEN PRINT "Not an available command or dufus spelling error: "; Cmnd$; NL$: RETURN
IF CmndValid AND (INSTR(CmndValid + 1, Cmnds$, ":" + CmndPart$) OR (INSTR(Cmnds$, ":" + CmndPart$) <> CmndValid)) THEN PRINT "More than one command starts with: "; CmndPart$; NL$: RETURN
CmndLen = LEN(CmndPart$): CmndPart$ = MID$(Cmnds$, CmndValid + 1, INSTR(CmndValid + 1, Cmnds$, ":") - CmndValid - 1)

SELECT CASE CmndPart$
CASE "QUIT": CLOSE : SYSTEM
CASE "HELP": PRINT : GOSUB Help: Newl = 3
CASE "OPEN": tfile$ = SelectPart(Cmnd$, 2, 0): IF tfile$ = "" THEN ERROR 80
 OPEN tfile$ FOR INPUT AS #2: CLOSE 2: CLOSE 1: OPEN tfile$ FOR BINARY AS #1
 WHILE INSTR(tfile$, "\"): tfile$ = RIGHT$(tfile$, LEN(tfile$) - INSTR(tfile$, "\")): WEND
 file$ = UCASE$(tfile$): tfile$ = "": PRINT "Link is active with "; file$; NL$: Newl = 3
CASE "MAKE"
 tfile$ = SelectPart(Cmnd$, 2, 0): IF tfile$ = "" THEN ERROR 80 ELSE CLOSE 1
 FilErr = 0: ON ERROR GOTO FilErrDetect: OPEN tfile$ FOR INPUT AS #1: CLOSE 1
 IF FilErr THEN
  PRINT "Can not create it, that file already exists"; NL$
 ELSE
  OPEN tfile$ FOR BINARY AS #1
  WHILE INSTR(tfile$, "\"): tfile$ = RIGHT$(tfile$, LEN(tfile$) - INSTR(tfile$, "\")): WEND
  file$ = UCASE$(tfile$): tfile$ = "": PRINT "Link is active with "; file$; NL$: Newl = 3
 END IF
 ON ERROR GOTO FilErrHan
CASE "CLOSE": IF NOT FREEFILE > 1 THEN PRINT "Link already closed. Use OPEN to make one"; NL$: Cmnd$ = "OPEN ": Newl = 4 ELSE CLOSE #1: PRINT "Link is closed with "; file$; NL$: file$ = "": Newl = 3
CASE "READ": FILESHOW LTRIM$(RIGHT$(Cmnd$, LEN(Cmnd$) - CmndLen))
CASE "BYTE"
 IF NOT FREEFILE > 1 THEN ERROR 77 ELSE Rcrd$ = SelectPart(Cmnd$, 2, 0)
 IF Rcrd$ = "" THEN ERROR 79 ELSE s& = VAL(Rcrd$)
 IF s& < 1 OR s& > LOF(1) THEN ERROR 85 ELSE Subr$ = " ": GET 1, s&, Subr$: PRINT ASC(Subr$)
CASE "FIND"
 IF FREEFILE > 1 AND INSTR(Cmnd$, "=") OR INSTR(Cmnd$, "#") THEN PRINT "Searching"; : COLOR 23: PRINT "..."; : COLOR 7: LOCATE , 1
 Srch& = FILEFIND(LTRIM$(RIGHT$(Cmnd$, LEN(Cmnd$) - CmndLen)))
 IF Srch& THEN PRINT "Match found at -"; STR$(Srch&); NL$: FILESHOW STR$(Srch& - 80) + STR$(Srch& + 158): Newl = 3 ELSE PRINT "No match found": PRINT
CASE "WRITE"
 FILEWRIT LTRIM$(RIGHT$(Cmnd$, LEN(Cmnd$) - 5))
 FILESHOW SelectPart(Cmnd$, 2, 0) + " 40": PRINT
CASE "SEARCH"
 text$ = SelectPart(Cmnd$, 2, Ofst): text$ = MID$(Cmnd$, Ofst + 1)
 IF text$ = "" THEN ERROR 78
 PRINT "Replace with:"; : PROMPT text$, Txt2$, "", Key$, LEN(text$), 64, CSRLIN, 14, -1, 0
 IF Key$ <> CHR$(13) OR Txt2$ = "" THEN RETURN
 IF LEN(Txt2$) <> LEN(text$) THEN PRINT "Original text and replace text should be the same length: Procede, Cancel (P\C)": SLEEP: Key$ = UCASE$(INKEY$): IF Key$ = "P" THEN  ELSE GOTO Main
 Srch& = 0
 DO
  Srch& = FILEFIND(STR$(Srch& + 1) + " =" + text$)
  IF Srch& = 0 THEN EXIT DO ELSE PRINT NL$; NL$; "Match found at -"; STR$(Srch&): FILESHOW STR$(Srch&) + STR$(Srch& + 158)
  DO
   PRINT "Replace, Skip, or Cancel? (R/S/C)";
   Key$ = "": WHILE Key$ = "": Key$ = UCASE$(INKEY$): WEND
  LOOP UNTIL Key$ = "R" OR Key$ = "S" OR Key$ = "C" OR Key$ = ""
  SELECT CASE Key$
  CASE "C", "": GOTO Main
  CASE "R": FILEWRIT STR$(Srch&) + " =" + Txt2$
  END SELECT
 LOOP
 PRINT NL$; "Search process complete"; NL$
CASE "DIRLIST"
 LOCATE , , 0
 IF SelectPart(Cmnd$, 2, 0) = "" THEN SHELL "DIR /P" ELSE SHELL "DIR " + SelectPart(Cmnd$, 2, 0)
 Newl = 3: PRINT
CASE "CPROMPT": SHELL: Cmnd$ = "": PRINT
CASE "CHD"
 tfile$ = UCASE$(SelectPart(Cmnd$, 2, Ofst)): FilErr = 0
 IF tfile$ > "" THEN ON ERROR GOTO FilErrDetect: CHDIR tfile$: ON ERROR GOTO FilErrHan
 IF FilErr THEN
  PRINT "Could not change to the specified directory": Newl = 1
 ELSE
  SHELL "CD": Newl = 3
 END IF
 PRINT
CASE "LENG": IF NOT FREEFILE > 1 THEN ERROR 77 ELSE PRINT file$; " is"; LOF(1); "Byte(s) long": PRINT : Newl = 3
CASE "CANDO":
 IF NOT FREEFILE > 1 THEN
  PRINT "Can not quick close and reopen if no file is open to begin with"; NL$: Cmnd$ = "OPEN ": Newl = 4
 ELSE
  CLOSE #1: PRINT "Closing and reopening "; file$
  ON ERROR GOTO FilErrDetect: FilErr = 0
  OPEN file$ FOR INPUT AS #1: CLOSE #1
  IF FilErr = 0 THEN OPEN file$ FOR BINARY AS #1
  IF FilErr THEN
   PRINT "Could not reopen file. You may have changed directories or deleted it?"; NL$: Newl = 1
  ELSE
   PRINT "Link is reactive with "; file$; NL$: Newl = 3
  END IF
  ON ERROR GOTO FilErrHan
 END IF
END SELECT
RETURN

FilErrHan:
SELECT CASE ERR
CASE 5: IF ERL = 30 THEN er$ = "READ command error, make sure your screen is set to a width of 80"
CASE 53: er$ = "I can not find that file, or at least not in this directory, use LIST for files"
CASE 64: er$ = "Bad filename. You put some really weird, illegal stuff in the name! @#*?<>"
CASE 75, 76: er$ = "I'm lost. That path is not found. Get out your map or type LIST to get a list"

CASE 77: er$ = "This is no current link to any file or device, You need to use the OPEN command": Cmnd$ = "OPEN ": Newl = 4
CASE 78: er$ = "There are some essential parameters missing. Press F1 to get the right format"
CASE 79: er$ = "I need a starting record number for this command, 1 -" + STR$(LOF(1))
CASE 80: er$ = "I need a filename for this command. It can be any MS-DOS format filename"
CASE 85: er$ = "Record number is out of range, enter a value of 1 -" + STR$(LOF(1))
CASE ELSE: er$ = "Unknown error:" + STR$(ERR)
END SELECT
PRINT er$; NL$
RESUME Main
FilErrDetect:
FilErr = ERR
RESUME NEXT

Help: RETURN
IF HelpPage = 1 THEN RETURN
CLS : LOCATE , , 0
PRINT "Type one of the following commands (At any time):"
PRINT "úTo choose what file or device to work with- OPEN Filename (plus drive and path)"
PRINT "úTo create a completely new file on disk   - MAKE Filename"
PRINT "úTo close the link with the current file   - CLOSE"
PRINT "úTo change the current directory to another- CD [dir name]"
PRINT "úFor a listing of files in the current dir - DIRLIST [parameters]"
PRINT "úFor a refresher on the format of commands - HELP or press F1  (F2=Editing help)"
PRINT "úTo temporarily shell to the MS-DOS prompt - CPROMPT (Type EXIT to get back)"
PRINT NL$; "Use these commands to work with files (When a file is open):"
PRINT "ùTo read a section of the file  - READ [First byte [Last byte]]"
PRINT "ùOr to see the entire contents  - READ (with no parameters)"
PRINT "ùTo get the length of the file  - LENG (returns it in bytes)"
PRINT "ùTo get a single filebyte value - BYTE Byte number (returns the ASCII code)"
PRINT "ùTo search for a string of data - FIND [Starting byte [Ending byte]] {=|#}Data"
PRINT "ùTo search for and replace text - SEARCH Searchtext (Ù ENTER) Replacetext"
PRINT "ùTo write over a part of a file - WRITE Recordnumber {=|#}Data (be careful using this command with binary files since it may cause them to become inoperable!)"; NL$
PRINT "You can abbreviate these commands to letters rather than typing the whole word"
PRINT "For CD, COMMAND, and CLOSE though, you would have at least to type the first two"
PRINT "letters (CD,CO,CL) since they all start with the same first letter"; NL$
PRINT "Press F2 for help on using the prompt, F3 for background info about FilEditr"
HelpPage = 1
RETURN

EditHelp: RETURN
IF HelpPage = 2 THEN RETURN
CLS : LOCATE , , 0
PRINT "Using the editing prompt:"
PRINT "ùThe left and right arrow keys move the cursor within the text"
PRINT " The up and down keys recall the last command or clear text for next command"
PRINT " HOME and END move the cursor to the front or beginning"
PRINT " BKSPC and DELETE remove characters before or after cursor position"
PRINT "ùAlthough only seventy or so characters in the prompt can be seen, up to two-"
PRINT " hundred fifty-six characters can be held, even though they are off the screen"
PRINT "ùIf there is more text in the prompt than can be seen on the screen, the prompt"
PRINT " will scroll left and right when the cursor 'pushes' past either way"
PRINT "ùOnce the cursor is positioned, you can insert any text you want"
PRINT "ùAll characters can be typed in at least some way. Extended characters can"
PRINT " be input by pressing ALT and the ASCII number for the symbol"
PRINT "úControl characters (ESC, ENTER, LINEFEED, FORMFEED, TAB, BELL, BKSPC...) can"
PRINT " be inserted by using INSERT so that the cursor size changes, and then pressing"
PRINT " whatever control code you want. You can also see the actual characters as"
PRINT " they really are. As soon as you press the control key, the cursor will resume"
PRINT " its prior size, which means the prompt is also back in normal editing. To"
PRINT " not insert a control code and cancel special insert mode, just press INSERT"
PRINT " once again. Insert mode is handy for the FIND and WRITE commands"
PRINT NL$; "When entering data to be used by the FIND or WRITE command, you must type:"
PRINT " 1. An equal sign, followed by the ASCII character string, =ABC123$@#!"
PRINT " 2. Or the pound sign, before the ASCII code of a character, #127"; NL$
HelpPage = 2
RETURN

Credits: RETURN
IF HelpPage = 3 THEN RETURN
CLS
LOCATE 2, 26: PRINT "Simple File Editer, Ver 1.3"
LOCATE 4, 21: PRINT "Created and written by Dwayne Robinson"
LOCATE 8, 29: PRINT "Made using Qbasic 1.1"
LOCATE 10, 27: PRINT "Start date: many moons ago"
LOCATE 12, 23: PRINT "Completion date: still working on"
LOCATE 15
HelpPage = 3
RETURN

DEFSNG A-Z
FUNCTION FILEFIND& (Cmnd$)
IF NOT FREEFILE > 1 THEN ERROR 77
a$ = SelectPart(Cmnd$, 1, 0): b$ = SelectPart(Cmnd$, 2, 0): c$ = SelectPart(Cmnd$, 3, 0)
IF MID$(a$, 1, 1) = "=" OR MID$(a$, 1, 1) = "#" THEN
 s& = 1: e& = LOF(1): Data$ = MID$(Cmnd$, INSTR(Cmnd$, a$), LEN(Cmnd$) - INSTR(Cmnd$, a$) + 1)
ELSEIF MID$(b$, 1, 1) = "=" OR MID$(b$, 1, 1) = "#" THEN s& = VAL(a$): e& = LOF(1): Data$ = MID$(Cmnd$, INSTR(Cmnd$, b$), LEN(Cmnd$) - INSTR(Cmnd$, b$) + 1)
ELSEIF c$ > "" THEN s& = VAL(a$): e& = VAL(b$): Data$ = MID$(Cmnd$, INSTR(Cmnd$, c$), LEN(Cmnd$) - INSTR(Cmnd$, c$) + 1)
ELSE ERROR 78
END IF
IF MID$(Data$, 1, 1) = "=" THEN Data$ = RIGHT$(Data$, LEN(Data$) - 1) ELSE Data$ = CHR$(VAL(RIGHT$(Data$, LEN(Data$) - 1)))
IF s& < 1 THEN s& = 1 ELSE IF s& > LOF(1) THEN s& = LOF(1)
IF e& < 1 THEN e& = 1 ELSE IF e& > LOF(1) THEN e& = LOF(1)
Buffer$ = SPACE$(1024)
FOR Srch& = s& TO e& STEP 1024 - LEN(Data$)
 GET 1, Srch&, Buffer$
 IF INSTR(Buffer$, Data$) THEN FILEFIND = Srch& + INSTR(Buffer$, Data$) - 1: EXIT FUNCTION
NEXT Srch&
FILEFIND = 0
END FUNCTION

DEFINT A-Z
SUB FILESHOW (Cmnd$)
IF NOT FREEFILE > 1 THEN ERROR 77 ELSE Leng& = LOF(1)
30 s& = VAL(SelectPart(Cmnd$, 1, 0)): e& = VAL(SelectPart(Cmnd$, 2, 0))
IF s& - 1 > Leng& THEN EXIT SUB ELSE IF s& < 1 THEN s& = 1
IF e& > Leng& THEN e& = Leng& ELSE IF e& = 0 THEN e& = Leng& ELSE IF e& < s& THEN EXIT SUB
SEEK 1, s&: LOCATE , 1, 0: l& = e& - s& + 1: Cont = 1
vrow = (CSRLIN - 1) * 8: vcol = 0: vcount = 0
FOR Look& = 1 TO l& \ 16384
 Rslt$ = "": Rslt$ = INPUT$(16384, #1)
 FOR Show = 1 TO 16384
  PSET (vcol, vrow), ASC(MID$(Rslt$, Show, 1))
  IF vcol >= 255 THEN
   vcol = 0
   IF vrow >= 199 THEN PRINT : vrow = vrow - 8 ELSE vrow = vrow + 1
  ELSE vcol = vcol + 1
  END IF
  IF INP(96) = 1 GOTO ExitShowLoop
 NEXT Show
NEXT Look&
IF Cont THEN
 Rslt$ = "": Rslt$ = INPUT$(l& MOD 16384, #1)
 FOR Show = 1 TO LEN(Rslt$)
  PSET (vcol, vrow), ASC(MID$(Rslt$, Show, 1))
  IF vcol >= 255 THEN
   vcol = 0
   IF vrow >= 199 THEN PRINT : vrow = vrow - 8 ELSE vrow = vrow + 1
  ELSE vcol = vcol + 1
  END IF
  IF INP(96) = 1 GOTO ExitShowLoop
 NEXT Show
END IF
ExitShowLoop:
COLOR 15: IF e& = Leng& AND Cont THEN PRINT "þ" ELSE PRINT ""
COLOR 7: PRINT NL$;
END SUB

DEFSNG A-Z
SUB FILEWRIT (Cmnd$)
IF NOT FREEFILE > 1 THEN ERROR 77
a$ = SelectPart(Cmnd$, 1, 0): IF a$ = "" THEN ERROR 78
s& = VAL(a$): IF s& = 0 THEN s& = LOF(1) + 1 ELSE IF s& > LOF(1) THEN ERROR 85

IF INSTR(Cmnd$, "=") THEN
 Data$ = RIGHT$(Cmnd$, LEN(Cmnd$) - INSTR(Cmnd$, "="))
ELSEIF INSTR(Cmnd$, "#") THEN
 Data$ = CHR$(VAL(MID$(Cmnd$, INSTR(Cmnd$, "#") + 1)))
ELSE
 ERROR 78
END IF

PUT 1, s&, Data$
END SUB

FUNCTION NL$
NL$ = CHR$(13)
END FUNCTION

DEFINT A-Z
SUB PRINT2 (vset, Hset, text$)
DEF SEG = &HB800: POKE (vset - 1) * 160 + (Hset - 1) * 2, ASC(text$)
END SUB

SUB PROMPT (Frst$, Last$, KeyIn$, KeyOut$, Lim, Vis, Row, Col, Curp, Done)
Chng = 1
Kbrd$ = KeyIn$
Rslt$ = Frst$
'Vset = (Row - 1) * 80 + (Col - 2)
IF Curp = -1 THEN Curp = LEN(Rslt$)

DO
 Leng = LEN(Rslt$)
 SELECT CASE Kbrd$
 CASE ""
 CASE " " TO "ÿ": GOSUB PromptInsert: Nsrt = 0
 CASE CHR$(8): IF Nsrt THEN GOSUB PromptInsert: Nsrt = 0 ELSE IF Curp > 0 AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp - 1) + RIGHT$(Rslt$, Leng - Curp): Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "S": IF Curp < Leng AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp) + RIGHT$(Rslt$, Leng - Curp - 1): Chng = 1
 CASE CHR$(0) + "R": Nsrt = Nsrt XOR 1: Chng = 1
 CASE CHR$(0) + "K": IF Curp > 0 THEN Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "M": IF Curp < Leng THEN Curp = Curp + 1: Chng = 1
 CASE CHR$(0) + "G": Curp = 0: Chng = 1
 CASE CHR$(0) + "O": Curp = Leng: Chng = 1
 CASE ELSE: IF LEN(Kbrd$) <> 1 OR Nsrt = 0 THEN KeyOut$ = Kbrd$: Done = 1 ELSE GOSUB PromptInsert: Nsrt = 0
 END SELECT

 IF Chng THEN
  Leng = LEN(Rslt$)
  IF Curp > Leng THEN Curp = Leng ELSE IF Curp < 0 THEN Curp = 0
  IF Curp < Ofst THEN Ofst = Curp ELSE IF Curp >= Ofst + Vis THEN Ofst = Curp - Vis + 1
  text$ = MID$(Rslt$ + SPACE$(Vis), Ofst + 1, Vis)
  DEF SEG = &HB800
  LOCATE Row, Col, 0: PRINT text$;
  'FOR Show = 1 TO LEN(text$)
  ' POKE (Vset + Show) * 2, ASC(MID$(text$, Show, 1))
  'NEXT Show
  LOCATE Row + ((Curp - Ofst) \ 80), Col + ((Curp - Ofst) MOD 80), 1
  IF Nsrt THEN LOCATE , , , 1, 13 ELSE LOCATE , , , 14, 15
  Chng = 0
 END IF

 Kbrd$ = INKEY$
LOOP UNTIL Done

DEF SEG
Last$ = Rslt$
EXIT SUB

PromptInsert:
 IF LEN(Kbrd$) + LEN(Rslt$) > Lim THEN SOUND 1024, .1: RETURN
 Rslt$ = LEFT$(Rslt$, Curp) + Kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - Curp)
 Curp = Curp + LEN(Kbrd$)
 Chng = 1
RETURN
END SUB

FUNCTION SelectPart$ (text$, Part, Ofst)

FOR Search = 1 TO LEN(text$)
 IF MID$(text$, Search, 1) = " " THEN Son = 0 ELSE IF Son = 0 THEN Son = -1: Ofst = Search: Count = Count + 1: IF Count >= Part THEN EXIT FOR
NEXT Search

IF Count < Part THEN
 Ofst = LEN(text$)
 SelectPart$ = ""
ELSE
 IF INSTR(Ofst, text$, " ") THEN Dlmt = INSTR(Ofst, text$, " ") - 1 ELSE Dlmt = LEN(text$)
 SelectPart$ = MID$(text$, Ofst, Dlmt - Ofst + 1)
END IF
END FUNCTION

