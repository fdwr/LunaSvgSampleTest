DEFINT A-Z
DECLARE FUNCTION FILEMATCH% (text$, fltr$, wild$)
CONST IDs = 5' The number of filetypes that IDFILE can identify
PRINT "File Identification Program, Ver 1.0"
PRINT "This program identifies files by their actual file content, not their extensions"; " "

pr:
PRINT "ID a file, get directory list, show known filetypes, or exit? (I-G-S-E)";
DO: k$ = UCASE$(INKEY$)
LOOP UNTIL k$ = "I" OR k$ = "S" OR k$ = "E" OR k$ = "" OR k$ = CHR$(13) OR k$ = "G"
PRINT k$;
SELECT CASE k$
CASE "I", CHR$(13): GOSUB IDfiles
CASE "G": SHELL "DIR/P"
CASE "S": GOSUB ShowTypes
CASE "E", "": SYSTEM
END SELECT
GOTO pr

IDfiles:
DO: CLOSE #1
PRINT : LINE INPUT "Filename:", file$
 IF file$ = "" THEN EXIT DO ELSE file$ = UCASE$(file$)
 DirErr = 0: ON ERROR GOTO DrEr: CHDIR file$: IF NOT DirErr THEN PRINT "Directory changed to "; UCASE$(file$): GOTO IDfiles
 ON ERROR GOTO FlEr: OPEN file$ FOR INPUT AS #1: CLOSE #1
 OPEN file$ FOR BINARY ACCESS READ AS #1
 FOR s = LEN(file$) TO 1 STEP -1
  IF MID$(file$, s, 1) = "." THEN ext$ = RIGHT$(file$, LEN(file$) - s): EXIT FOR ELSE ext$ = ""
 NEXT
 IF INSTR(file$, "\") THEN
  FOR s = LEN(file$) TO 1 STEP -1
   IF MID$(file$, s, 1) = "\" THEN filn$ = RIGHT$(file$, LEN(file$) - s): EXIT FOR
  NEXT
 ELSE filn$ = file$
 END IF
 RESTORE: mtch = 0
 FOR t = 1 TO IDs
  READ type$: READ extn$: READ fltr$: comp$ = fltr$: GET #1, 1, comp$
  IF FILEMATCH(comp$, fltr$, "?") THEN mtch = -1: EXIT FOR
 NEXT t
 IF mtch THEN
  PRINT filn$ + " = " + type$: IF ext$ <> extn$ THEN PRINT "extension name [" + ext$ + "] does not match formal name [" + extn$ + "]"
 ELSE
  PRINT "Type of file not determined"
 END IF
LOOP
RETURN

ShowTypes:
RESTORE: IF POS(0) <> 1 THEN PRINT CHR$(13)
FOR s = 1 TO IDs
READ type$: READ extn$: READ comp$: PRINT LEFT$("." + extn$ + "   ", 4); "  "; type$
NEXT s
RETURN

DrEr: DirErr = -1: RESUME NEXT
FlEr:
SELECT CASE ERR
CASE 53: PRINT "file not found"
CASE 64: PRINT "bad file name"
CASE 75, 76: PRINT "path not found"
CASE ELSE: PRINT "unknown error"; STR$(ERR)
END SELECT
RESUME IDfiles
DATA "16-Color Bitmap picture","BMP","BM????????v???(","MIDI song","MID","MThd","Sound wave","WAV","RIFF????WAVE","Creative Music File","CMF","CTMF","Windows WRITE document","WRI","?¾???«"

FUNCTION FILEMATCH (text$, fltr$, wild$)
IF LEN(text$) <> LEN(fltr$) THEN FILEMATCH = 0: EXIT FUNCTION ELSE mtch = -1
FOR s = 1 TO LEN(text$)
 IF MID$(text$, s, 1) <> MID$(fltr$, s, 1) AND MID$(text$, s, 1) <> wild$ THEN mtch = 0: EXIT FOR
NEXT s
FILEMATCH = mtch
END FUNCTION

