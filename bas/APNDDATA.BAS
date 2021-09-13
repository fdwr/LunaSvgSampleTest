'Data appender 4-8-98, by FDwR (FDwR@Juno.com)

'This program (not very advanced) can be used for getting file data into a
'Qbasic program as DATA statements. Just tell it the source file, whether
'linear bitmap, assembly code, or anything else, and the Qbasic program to
'recieve the string of numbers (16bit integers). It works fine for me, tell
'me if you find any bugs in it.

DEFINT A-Z
CONST MaxLineLength = 78
row = CSRLIN: col = POS(0): VIEW PRINT 1 TO 25: LOCATE row, col

'In case your using Qbasic 1.1 and not 4.5
ON ERROR GOTO FilErrHan: FilErr = 0
IF LEN(COMMAND$) THEN GOSUB ParseCommandLine
ON ERROR GOTO 0

StartProgram:
PRINT
PRINT "Qbasic DATA Appender version nada.zip (0.0)"
COLOR 7, 0

IF source$ = "" THEN
GetSource:
 PRINT "Enter the source filename to read data from"
 GOSUB GetFileName
 IF NewFile$ = "" THEN END ELSE source$ = NewFile$
END IF

IF dest$ = "" THEN
GetDest:
 PRINT "Enter the destination filename to append to 'DATA' to"
 GOSUB GetFileName
 IF NewFile$ = "" THEN END ELSE dest$ = NewFile$
END IF

IF comment$ = "" THEN
 PRINT "Would you like to add a comment before the DATA statements, so you will know"
 PRINT "what they are later when you open your program? Press Enter for filename."
 LINE INPUT "Description:", comment$
 IF comment$ = "" THEN comment$ = source$
END IF

OpenFiles:
ON ERROR GOTO FilErrHan: FilErr = 0: OPEN dest$ FOR INPUT AS 1: CLOSE 1: ON ERROR GOTO 0
IF FilErr AND FilErr <> 53 THEN PRINT "Error opening append file"; FilErr: GOTO GetDest
ON ERROR GOTO FilErrHan: FilErr = 0: OPEN source$ FOR INPUT AS 1: CLOSE 1: ON ERROR GOTO 0
IF FilErr THEN PRINT "Could not open source, please respell or include full path": GOTO GetSource
IF RIGHT$(UCASE$(dest$), 4) <> ".BAS" AND RIGHT$(UCASE$(source$), 4) <> ".BI" THEN
 PRINT "Destination is not a BASIC program or include file,"
 PRINT "Just checking you are sure you want to write to it [y/n]"
 DO: byte$ = INKEY$: LOOP UNTIL LEN(byte$)
 IF UCASE$(byte$) <> "Y" GOTO GetSource
END IF
OPEN source$ FOR BINARY AS 1
PRINT "Source file opened: "; source$; " is"; LOF(1); "bytes"
OPEN dest$ FOR APPEND AS 2
destfileleng& = LOF(2)
PRINT "Destination for append opened: "; dest$; " is"; destfileleng&; "bytes"
row = CSRLIN: col = POS(0)

PRINT #2, "'" + comment$

fileleng& = LOF(1): byte$ = "  "
index& = 1
GET 1, , byte$
number$ = LTRIM$(STR$(CVI(byte$)))
numlength = LEN(number$) + 1
GOTO BreakIntoLoop

DO WHILE index& < fileleng&
 IF count <= 0 THEN count = 1000: GOSUB UpdateAndCheck: IF Done THEN EXIT DO ELSE  ELSE count = count - 1

 index& = index& + 2
 GET 1, index&, byte$
 number$ = LTRIM$(STR$(CVI(byte$)))
 numlength = LEN(number$) + 1

 IF filecol + numlength > MaxLineLength THEN
  PRINT #2,
BreakIntoLoop:
  PRINT #2, "DATA ";
  PRINT #2, number$;
  filecol = 4 + numlength
 ELSE
  PRINT #2, "," + number$;
  filecol = filecol + numlength
 END IF
LOOP

PRINT #2,

LOCATE row, col: PRINT "Number of bytes translated:"; index&
PRINT "Destination increased by:"; LOF(2) - destfileleng&; ", now"; LOF(2); "bytes"

CLOSE 1, 2

SYSTEM

UpdateAndCheck:
 LOCATE row, col: PRINT "Position in source:"; index&;
 IF LEN(INKEY$) THEN
  PRINT "Do you want to quit? Press Esc to end or any other key to continue..."
  IF INPUT$(1) = CHR$(27) THEN Done = 1
 END IF
RETURN

FilErrHan:
 FilErr = ERR
RESUME NEXT

GetFileName:
  LINE INPUT "Filename:", NewFile$
  IF UserEscape THEN NewFile$ = ""
  IF NewFile$ = "" THEN RETURN ELSE NewFile$ = UCASE$(LTRIM$(NewFile$))
  IF INSTR(NewFile$, "*") THEN SHELL "dir " + NewFile$: GOTO GetFileName
  ON ERROR GOTO FilErrHan
  FilErr = 0: CHDIR NewFile$
  IF FilErr = 0 THEN PRINT "Directory changed": GOTO GetFileName
  ON ERROR GOTO 0
RETURN

ParseCommandLine:
 NewFile$ = COMMAND$
 IF LEFT$(NewFile$, 2) = "/H" THEN
  PRINT "Qbasic DATA Appender by FDwR, version nada.zero (0.0), 4-8-98"
  PRINT "Used to translate binary data from any type of file and append it to"
  PRINT "a Qbasic program as DATA statements followed by numbers sequences."
  PRINT
  PRINT "Syntax: APNDDATA [source [destination]] [+text string]"
  PRINT "        you obviously already know about the '/h'elp switch"
  PRINT "Examples: APNDDATA blitfont.asc +This is assembly code for font blitting"
  PRINT "          APNDDATA fairy.lbm drawpict.bas +Fairy picture"
  PRINT "          APNDDATA"
  PRINT "Notes: Anything you do not include will be asked for at the text prompts."
  PRINT "       Sorry about the comment changing to all caps when supplied from the"
  PRINT "       command line...it's not a bug, just an annoying quirk about Qbasic."
  SYSTEM
 END IF
 'I admit this part is sort of stupid below, but it is the first time I've
 'ever written any code to parse command line variables.
 IF LEFT$(NewFile$, 1) = "+" THEN comment$ = RIGHT$(NewFile$, LEN(NewFile$) - 1): RETURN
 endparam = INSTR(NewFile$, " ")
 IF endparam < 1 THEN source$ = LEFT$(NewFile$, LEN(NewFile$)): RETURN ELSE source$ = LEFT$(NewFile$, endparam - 1)
 NewFile$ = LTRIM$(MID$(NewFile$, endparam))
 IF LEN(NewFile$) = 0 THEN RETURN
 IF LEFT$(NewFile$, 1) = "+" THEN comment$ = RIGHT$(NewFile$, LEN(NewFile$) - 1): RETURN
 endparam = INSTR(NewFile$, " ")
 IF endparam < 1 THEN dest$ = LEFT$(NewFile$, LEN(NewFile$)): RETURN ELSE dest$ = LEFT$(NewFile$, endparam - 1)
 NewFile$ = LTRIM$(MID$(NewFile$, endparam))
 IF LEN(NewFile$) = 0 THEN RETURN
 IF LEFT$(NewFile$, 1) = "+" THEN comment$ = RIGHT$(NewFile$, LEN(NewFile$) - 1) ELSE comment$ = NewFile$
RETURN

