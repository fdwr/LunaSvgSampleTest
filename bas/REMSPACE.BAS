DEFINT A-Z
DECLARE FUNCTION GetToken$ (Search$, Delim$)
DECLARE FUNCTION StrSpn% (InString$, Separator$)
DECLARE FUNCTION StrBrk% (InString$, Separator$)
DECLARE FUNCTION IsDigit% (Char$)
DECLARE SUB RemoveText (Text$, St%, Lg%)
DECLARE SUB Condense (InLin$)
DECLARE SUB GetFileNames ()
DECLARE SUB BuildTable ()
DECLARE SUB GenOutFile ()
DECLARE SUB InitKeyTable ()

CONST TRUE = -1, FALSE = 0, MaxLines = 400, KeyWordCount = 9
DIM SHARED LineTable!(MaxLines)
DIM SHARED KeyWordTable$(KeyWordCount)
DIM SHARED LineCount
DIM SHARED Seps$, InputFile$, OutputFile$, TmpFile$, SpaceCndns$
SpaceCndns$ = " &`()[],;:=+-<>*/\^" + CHR$(34)

KeyData:
DATA THEN,ELSE,GOSUB,GOTO,RESUME,RETURN,RESTORE,RUN,ERL,""
Seps$ = " ,:=<>()" + CHR$(9)
InitKeyTable
GetFileNames
ON ERROR GOTO FileErr1
OPEN InputFile$ FOR INPUT AS 1
ON ERROR GOTO 0
COLOR 7: PRINT "Working"; : COLOR 23: PRINT " . . .": COLOR 7: PRINT
BuildTable
CLOSE #1
OPEN InputFile$ FOR INPUT AS 1
ON ERROR GOTO FileErr2
OPEN OutputFile$ FOR OUTPUT AS 2
ON ERROR GOTO 0
GenOutFile
CLOSE #1, #2
SYSTEM
FileErr1:
CLS
PRINT "      Invalid file name": PRINT
INPUT "      New input file name (ENTER to terminate): ", InputFile$
IF InputFile$ = "" THEN SYSTEM
FileErr2:
INPUT "      Output file name (ENTER to print to screen) :", OutputFile$
PRINT
IF (OutputFile$ = "") THEN OutputFile$ = "CON"
IF TmpFile$ = "" THEN
RESUME
ELSE
TmpFile$ = ""
RESUME NEXT
END IF

SUB BuildTable STATIC
DO WHILE NOT EOF(1)
DO
LINE INPUT #1, InLin$: Condense InLin$
LOOP WHILE InLin$ = "" AND NOT EOF(1)
Token$ = GetToken$(InLin$, Seps$)
DO WHILE (Token$ <> "")
FOR KeyIndex = 1 TO KeyWordCount
IF (KeyWordTable$(KeyIndex) = UCASE$(Token$)) THEN
Token$ = GetToken$("", Seps$)
DO WHILE (IsDigit(LEFT$(Token$, 1)))
LineCount = LineCount + 1
LineTable!(LineCount) = VAL(Token$)
Token$ = GetToken$("", Seps$)
IF Token$ <> "" THEN KeyIndex = 0
LOOP
END IF
NEXT KeyIndex
Token$ = GetToken$("", Seps$)
LOOP
LOOP
END SUB

SUB Condense (InLin$)
InLin$ = LTRIM$(InLin$): s = 1: InQuote = FALSE
WHILE s <= LEN(InLin$)
 IF MID$(InLin$, s, 1) = CHR$(34) THEN InQuote = InQuote XOR TRUE: IF InQuote = FALSE THEN s = s + 1
 IF NOT InQuote THEN
  SELECT CASE MID$(InLin$, s, 1)
  CASE "'": IF MID$(InLin$, s + 1, 1) <> "$" THEN InLin$ = LEFT$(InLin$, s - 1) ELSE EXIT SUB
  CASE " ": IF INSTR(SpaceCndns$, MID$(InLin$, s + 1, 1)) THEN RemoveText InLin$, s, -1 ELSE s = s + 1
  CASE "=", "+", "-", "<", ">", "*", "/", "\", "^", ",", ":", ";", ")", "]"
   IF MID$(InLin$, s + 1, 1) = " " THEN RemoveText InLin$, s, 1 ELSE s = s + 1
  CASE ELSE: s = s + 1
  END SELECT
 ELSE s = s + 1
 END IF
WEND
END SUB

SUB GenOutFile STATIC
Sep$ = " " + CHR$(9)
DO WHILE NOT EOF(1)
DO
LINE INPUT #1, InLin$: Condense InLin$
LOOP WHILE InLin$ = "" AND NOT EOF(1)
IF (InLin$ <> "") THEN
Token$ = GetToken$(InLin$, Sep$)
IF IsDigit(LEFT$(Token$, 1)) THEN
LineNumber! = VAL(Token$)
FoundNumber = FALSE
FOR index = 1 TO LineCount
IF (LineNumber! = LineTable!(index)) THEN
FoundNumber = TRUE
END IF
NEXT index
IF (NOT FoundNumber) THEN
Token$ = SPACE$(LEN(Token$))
MID$(InLin$, StrSpn(InLin$, Sep$), LEN(Token$)) = Token$
END IF
END IF
END IF
IF OutputFile$ = "CON" THEN
PRINT InLin$
ELSE
PRINT #2, InLin$
END IF
LOOP
END SUB

SUB GetFileNames STATIC
PRINT
PRINT " Microsoft RemSpace: line number removal and space condenser utility"
PRINT "       (.BAS assumed if no extension given)"
PRINT
LINE INPUT "      Input file name (ENTER to terminate): ", InputFile$
IF InputFile$ = "" THEN SYSTEM
LINE INPUT "      Output file name (ENTER to print to screen): ", OutputFile$
PRINT
IF (OutputFile$ = "") THEN OutputFile$ = "CON"
IF INSTR(InputFile$, ".") = 0 THEN
InputFile$ = InputFile$ + ".BAS"
END IF
IF INSTR(OutputFile$, ".") = 0 THEN
SELECT CASE OutputFile$
CASE "CON", "SCRN", "PRN", "COM1", "COM2", "LPT1", "LPT2", "LPT3"
EXIT SUB
CASE ELSE
OutputFile$ = OutputFile$ + ".BAS"
END SELECT
END IF
DO WHILE InputFile$ = OutputFile$
TmpFile$ = LEFT$(InputFile$, INSTR(InputFile$, ".")) + "BAK"
ON ERROR GOTO FileErr1
NAME InputFile$ AS TmpFile$
ON ERROR GOTO 0
IF TmpFile$ <> "" THEN InputFile$ = TmpFile$
LOOP
END SUB

FUNCTION GetToken$ (Search$, Delim$) STATIC
IF (Search$ <> "") THEN
BegPos = 1
SaveStr$ = Search$
END IF
NewPos = StrSpn(MID$(SaveStr$, BegPos, LEN(SaveStr$)), Delim$)
IF NewPos THEN
BegPos = NewPos + BegPos - 1
ELSE
GetToken$ = ""
EXIT FUNCTION
END IF
NewPos = StrBrk(MID$(SaveStr$, BegPos, LEN(SaveStr$)), Delim$)
IF NewPos THEN
NewPos = BegPos + NewPos - 1
ELSE
NewPos = LEN(SaveStr$) + 1
END IF
GetToken$ = MID$(SaveStr$, BegPos, NewPos - BegPos)
BegPos = NewPos
END FUNCTION

SUB InitKeyTable STATIC
RESTORE KeyData
FOR Count = 1 TO KeyWordCount
READ KeyWord$
KeyWordTable$(Count) = KeyWord$
NEXT
END SUB

FUNCTION IsDigit (Char$) STATIC
IF (Char$ = "") THEN
IsDigit = FALSE
ELSE
CharAsc = ASC(Char$)
IsDigit = (CharAsc >= ASC("0")) AND (CharAsc <= ASC("9"))
END IF
END FUNCTION

SUB RemoveText (Text$, St, Lg)
IF SGN(Lg) = -1 THEN Lt = St + Lg: Rt = LEN(Text$) - St ELSE Lt = St: Rt = LEN(Text$) - (St + Lg)
IF Lt > LEN(Text$) THEN Lt = LEN(Text$) ELSE IF Lt < 0 THEN Lt = 0
IF Rt > LEN(Text$) THEN Rt = LEN(Text$) ELSE IF Rt < 0 THEN Rt = 0
Text$ = LEFT$(Text$, Lt) + RIGHT$(Text$, Rt)
END SUB

FUNCTION StrBrk (InString$, Separator$) STATIC
Ln = LEN(InString$)
BegPos = 1
DO WHILE INSTR(Separator$, MID$(InString$, BegPos, 1)) = 0
IF BegPos > Ln THEN
StrBrk = 0
EXIT FUNCTION
ELSE
BegPos = BegPos + 1
END IF
LOOP
StrBrk = BegPos
END FUNCTION

FUNCTION StrSpn% (InString$, Separator$) STATIC
Ln = LEN(InString$)
BegPos = 1
DO WHILE INSTR(Separator$, MID$(InString$, BegPos, 1))
IF BegPos > Ln THEN
StrSpn = 0
EXIT FUNCTION
ELSE
BegPos = BegPos + 1
END IF
LOOP
StrSpn = BegPos
END FUNCTION

