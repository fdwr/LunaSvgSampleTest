'This turns any unwrapped text file into text with carriage returns and line
'feeds so Word Processors that can not properly handle unwrapped text will
'then be able to edit it

DEFINT A-Z
DECLARE SUB GetInfo (InFile$, OutFile$, ColWrap)
DECLARE SUB GetNewFile (File$, Mode)
DECLARE SUB WordWrap (ColWrap, TextIn$, TextOut$, LeftOver$)
CONST TRUE = -1, FALSE = 0

VIEW PRINT

GetInfo InFile$, OutFile$, ColWrap

CheckFilErr:
ON ERROR GOTO ErrHan
DO
 IF InFile$ = OutFile$ THEN
  PRINT "You can not have the same output file as your input file"
  GetNewFile OutFile$, 1
 ELSE EXIT DO
 END IF
LOOP
DO
 FilErr = 0: OPEN InFile$ FOR INPUT AS 1
 IF FilErr = 0 THEN
  IF LOF(1) = 0 THEN PRINT "Your input file is null and empty" ELSE CLOSE 1: EXIT DO
 ELSEIF FilErr = 53 THEN
  PRINT "Your input filename was not found, try another one"
 ELSE
  PRINT "Bad input filename, try another one"
 END IF
 CLOSE 1
 GetNewFile InFile$, 0
LOOP
FilErr = 0: OPEN OutFile$ FOR INPUT AS 1: CLOSE 1
IF FilErr = 0 THEN
 PRINT "Your output file already exists, do you want to replace it? [Y\N] ";
 DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N": PRINT k$
 IF k$ = "N" THEN GetNewFile OutFile$, 1: GOTO CheckFilErr ELSE PRINT
ELSEIF FilErr > 0 AND FilErr <> 53 THEN
 PRINT "Bad output filename, try another one"
 GetNewFile OutFile$, 1
 GOTO CheckFilErr
END IF

PRINT "Opening input and output files...": PRINT
FilErr = 0: OPEN InFile$ FOR BINARY AS 1
IF FilErr THEN CLOSE 1: PRINT "There was an unexpected error in trying to open your input file": GetNewFile InFile$, 0: GOTO CheckFilErr
FilErr = 0: OPEN OutFile$ FOR OUTPUT AS 2
IF FilErr THEN CLOSE 1, 2: PRINT "Could not open output file, permission was denied": GetNewFile OutFile$, 1: GOTO CheckFilErr

PRINT "Wrapping text..."
LineBytes = ColWrap + 4
LastByte = LOF(1)
Feed$ = CHR$(13) + CHR$(10)
DO
 IF INKEY$ = "" THEN
  PRINT CHR$(13): PRINT "You have suspended Text Wrapper, do you wish to cancel the operation? [Y\N] ";
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N": PRINT k$
  IF k$ = "Y" THEN EXIT DO
 END IF
 InputBytes = LineBytes - LEN(LeftOver$)
 IF InputBytes > 0 THEN TextIn$ = LeftOver$ + INPUT$(InputBytes, 1) ELSE TextIn$ = LeftOver$
 WordWrap ColWrap, TextIn$, TextOut$, LeftOver$
 IF INSTR(TextOut$, Feed$) THEN PRINT #2, TextOut$;  ELSE PRINT #2, TextOut$
 CurInputLine& = CurInputLine& + 1: LOCATE , 1: PRINT CurInputLine&; "Lines";
 IF LeftOver$ = "" THEN EXIT DO
LOOP
PRINT CHR$(13)

PRINT "Closing input and output files..."
PRINT
SYSTEM

ErrHan: FilErr = ERR: RESUME NEXT

SUB GetInfo (InFile$, OutFile$, ColWrap)
COLOR 7, 0: CLS
PRINT "Text wrapper 1.0, Created by DWR"
PRINT : PRINT "Please enter the filename with the text to be wrapped"
LINE INPUT "  Input file name (ENTER to cancel): ", InFile$
IF InFile$ = "" THEN SYSTEM
PRINT : PRINT "Enter the file to recieve the wrapped text"
LINE INPUT "  Output file name (ENTER to cancel): ", OutFile$
IF OutFile$ = "" THEN SYSTEM
PRINT : PRINT "Enter the number of columns for the the text"
DO
 LOCATE , 1: LINE INPUT ; "  Text colums 1-255 (ENTER for 80): ", ColWrap$
 IF ColWrap$ = "" THEN
  PRINT "80"; : ColWrap = 80: EXIT DO
 ELSE
  ErrText$ = ""
  IF LEN(ColWrap$) > 3 THEN
   ErrText$ = "Number out of range"
  ELSE ColWrap = VAL(ColWrap$): IF ColWrap > 255 THEN ErrText$ = "Columns greater than 255" ELSE IF ColWrap < 1 THEN ErrText$ = "Columns less than one" ELSE EXIT DO
  END IF
  IF ErrText$ > "" THEN LOCATE , 1: PRINT "  "; LEFT$(ErrText$ + SPACE$(62), 64); : WHILE INKEY$ = "": WEND
 END IF
LOOP
PRINT : PRINT
END SUB

SUB GetNewFile (File$, Mode)

IF Mode THEN PRINT "  Output";  ELSE PRINT "  Input";
LINE INPUT " file name (ENTER to cancel): ", File$
IF File$ = "" THEN SYSTEM ELSE PRINT

END SUB

SUB WordWrap (ColWrap, TextIn$, TextOut$, LeftOver$)
TextOut$ = "": LeftOver$ = "": CurOfs = 0
IF TextIn$ = "" THEN EXIT SUB
NxtPos = INSTR(TextIn$, CHR$(13) + CHR$(10)): IF NxtPos AND NxtPos <= ColWrap + 1 THEN CurOfs = NxtPos + 1: TextOut$ = LEFT$(TextIn$, CurOfs): GOTO WordWrapCut
IF LEN(TextIn$) < ColWrap THEN TextOut$ = TextIn$: LeftOver$ = "": EXIT SUB
NxtPos = INSTR(TextIn$, " "): IF NxtPos = 0 OR NxtPos > ColWrap THEN CurOfs = ColWrap: TextOut$ = LEFT$(TextIn$, ColWrap): GOTO WordWrapCut
DO
 IF MID$(TextIn$, CurOfs + 1, 1) = " " THEN
  TextOut$ = TextOut$ + " "
  IF CurOfs >= ColWrap THEN EXIT DO ELSE CurOfs = CurOfs + 1: IF CurOfs = ColWrap THEN EXIT DO
 ELSE
  NxtPos = INSTR(CurOfs + 1, TextIn$, " ")
  IF NxtPos = 0 OR NxtPos > ColWrap THEN EXIT DO
  TextOut$ = TextOut$ + MID$(TextIn$, CurOfs + 1, NxtPos - CurOfs - 1)
  CurOfs = NxtPos - 1
 END IF
LOOP
WordWrapCut:
LeftOver$ = RIGHT$(TextIn$, LEN(TextIn$) - CurOfs)
END SUB

