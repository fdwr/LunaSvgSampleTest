'Opens any 256 color pcx and exports it to a linear bitmap
'Useful for Qbasic screen mode 13

DEFINT A-Z
DECLARE SUB Prompt (Text$, Key$, Csr%, Lim%, Row%, Col%)
DECLARE FUNCTION FileExists% (FileName$)
DIM SHARED ErrorNum

CLS
PRINT "Bitmap exporter 0.0"
PRINT "By FDwR on 9-7-98"
PRINT

'if len(FileName$) then open file
GetSourceFilename:
  PromptText$ = "Source image:": FileName$ = SourceFile$
  GOSUB GetFileName
  PRINT
  IF LEN(FileName$) = 0 THEN GOTO ProgramEnd ELSE SourceFile$ = FileName$
'attempt open
'if not found, go back

GetDestFilename:
  PromptText$ = "Destination:": FileName$ = DestFile$
  GOSUB GetFileName
  PRINT
  IF LEN(FileName$) = 0 THEN GOTO GetSourceFilename ELSE DestFile$ = FileName$
 
OpenFiles:
  IF NOT FileExists(SourceFile$) THEN
    PRINT "Source could not be opened"
    GOTO GetSourceFilename
  END IF
  IF FileExists(DestFile$) THEN
    PRINT "Destination already exists, do you want write over it? Y/N"
    DO: Key$ = UCASE$(INKEY$): LOOP UNTIL LEN(Key$)
    IF Key$ <> CHR$(13) AND Key$ <> "Y" THEN GOTO GetDestFilename
  END IF
  ON ERROR GOTO ErrorHandler
  SourceFileNum = FREEFILE
  OPEN SourceFile$ FOR BINARY AS SourceFileNum
  DestFileNum = FREEFILE
  'OPEN DestFile$ FOR OUTPUT AS 1
  PRINT SourceFileNum; DestFileNum
  ON ERROR GOTO 0
  'IF ErrorNum THEN
  '  PRINT "Could not write to destination"
  '  CLOSE SourceFileNum, DestFileNum
  '  GOTO GetSourceFilename
  'END IF

StartConversion:
  SEEK SourceFileNum, 19
  PicWidth = CVI(INPUT$(2, SourceFileNum))
  SEEK SourceFileNum, 23
  PicHeight = CVI(INPUT$(2, SourceFileNum))

  CLOSE SourceFileNum, DestFileNum

ProgramEnd:
END

GetFileName:
  PRINT PromptText$;
  Row = CSRLIN: Col = POS(0): Csr = LEN(FileName$)
  Prompt FileName$, "", Csr, 64, Row, Col
  DO
    Key$ = INKEY$
    IF LEN(Key$) THEN
      IF Key$ = CHR$(27) THEN FileName$ = "": RETURN ELSE IF Key$ = CHR$(13) THEN EXIT DO
      Prompt FileName$, Key$, Csr, 64, Row, Col
    END IF
  LOOP
  PRINT
  IF INSTR(FileName$, "*") THEN SHELL "dir " + FileName$: GOTO GetFileName
  ON ERROR GOTO ErrorHandler: ErrorNum = 0
  CHDIR FileName$
  ON ERROR GOTO 0
  IF ErrorNum = 0 OR FileName$ = ".." THEN
    IF ErrorNum = 0 THEN PRINT "Directory changed" ELSE PRINT "Already in root directory"
    FileName$ = ""
    GOTO GetFileName
  END IF
RETURN

ErrorHandler:
  ErrorNum = ERR
RESUME NEXT

FUNCTION FileExists (FileName$)
  ON ERROR GOTO ErrorHandler: ErrorNum = 0
  FileNum = FREEFILE
  OPEN FileName$ FOR INPUT AS FileNum: CLOSE FileNum
  ON ERROR GOTO 0
  IF ErrorNum = 0 THEN FileExists = -1
END FUNCTION

SUB Prompt (Text$, Key$, Csr, Lim, Row, Col)

Length = LEN(Text$)
SELECT CASE Key$
CASE CHR$(0) + "K": IF Csr > 0 THEN Csr = Csr - 1
CASE CHR$(0) + "M": IF Csr < Length THEN Csr = Csr + 1
CASE CHR$(0) + "G": Csr = 0
CASE CHR$(0) + "O": Csr = Length
CASE CHR$(8): IF Csr > 0 THEN Text$ = LEFT$(Text$, Csr - 1) + MID$(Text$, Csr + 1): Csr = Csr - 1
CASE " " TO "ÿ": IF Length < Lim THEN Text$ = LEFT$(Text$, Csr) + Key$ + MID$(Text$, Csr + 1): Csr = Csr + 1
END SELECT

LOCATE Row, Col, 0
IF Length > Lim THEN
  PRINT RIGHT$(Text$, Lim);
ELSE
  PRINT Text$; SPACE$(Lim - Length);
END IF
LOCATE Row, Col + Csr, 1

END SUB

