'12-24-97 4231
'04-14-98 4820 Added paging
DEFINT A-Z
DECLARE SUB Prompt (Text$, kbrd$, Row, Col, RecLeng, CurPos)

REDIM ScrollUpAsm(1 TO 7), ScrollDownAsm(1 TO 7)
P = VARPTR(ScrollUpAsm(1)): DEF SEG = VARSEG(ScrollUpAsm(1))
FOR I = 0 TO 13: READ J: POKE (P + I), J: NEXT I
P = VARPTR(ScrollDownAsm(1)): DEF SEG = VARSEG(ScrollDownAsm(1))
FOR I = 0 TO 13: READ J: POKE (P + I), J: NEXT I
'                         Lc   Tr        Rc  Br      Clr     Int
DATA &HB8,&H01,&H06,&HB9,&H00,&H01,&HBA,&H4f,24,&HB7,31,&HCD,&H10,&HCB
DATA &HB8,&H01,&H07,&HB9,&H00,&H01,&HBA,&H4f,24,&HB7,31,&HCD,&H10,&HCB
' Left column, Top row, Right column, Bottom row, Color, VGA Interrupt

SCREEN 0
WIDTH 80, 25
VIEW PRINT
COLOR 15, 1: CLS
LOCATE , , , 12, 14

FileName$ = COMMAND$

FileNamePrompt:
COLOR 0, 7: LOCATE , , 0
Prompt FileName$, kbrd$, 1, 1, 80, CurPos
SELECT CASE kbrd$
CASE CHR$(13): GOSUB OpenFileName
CASE CHR$(27)
 COLOR 7, 0: CLS
 SYSTEM
END SELECT
GOTO FileNamePrompt

OpenFileName:
FileName$ = UCASE$(FileName$)
ON ERROR GOTO DirErrHan
FilErr = 0: CHDIR FileName$
IF FilErr = 0 THEN
 COLOR 0, 2: LOCATE 1, 1: PRINT "Directory changed" + SPACE$(63);
 WHILE INKEY$ = "": WEND
 FileName$ = ""
 RETURN
END IF
ON ERROR GOTO FilErrHan
FilErr = 0: OPEN FileName$ FOR INPUT AS #1: CLOSE #1
IF FilErr THEN
 SELECT CASE FilErr
 CASE 53: ErrMes$ = "File not found, try to spell it again"
 CASE 64: ErrMes$ = "Bad file name, illegal characters are in it   <>*?/|[]+="
 CASE 76: ErrMes$ = "Path not found, a road can not be followed that does not exist"
 CASE ELSE: ErrMes$ = "Unknown file error with name"
 END SELECT
 COLOR 0, 4: LOCATE 1, 1: PRINT ErrMes$ + SPACE$(80 - LEN(ErrMes$));
 WHILE INKEY$ = "": WEND
 RETURN
END IF
OPEN FileName$ FOR BINARY AS #1
FileLeng& = LOF(1): FilePos& = 1

ScrollPrompt:
ScrollTopRow = 1
ScrollBtmRow = 24
ScrollWidth = 80
ScrollHeight = 24
ScrollPage = ScrollHeight * ScrollWidth
ScrollEnd& = FileLeng& - ScrollPage * 2 - 1
COLOR 15, 1: CLS
COLOR 7, 0: LOCATE 1, 1, 0: PRINT FileName$ + SPACE$(80 - LEN(FileName$));
COLOR 15, 1
GOSUB ScrollPage
DO
 kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE "": IF UpdateStat THEN COLOR 7, 0: LOCATE 1, 70: PRINT FilePos&; TAB(80); : UpdateStat = 0
 CASE CHR$(0) + "H": GOSUB ScrollUp
 CASE CHR$(0) + "P": GOSUB ScrollDown
 CASE CHR$(0) + "I": IF FilePos& > ScrollPage THEN FilePos& = FilePos& - ScrollPage: GOSUB ScrollPage
 CASE CHR$(0) + "Q": IF FilePos& < ScrollEnd& THEN FilePos& = FilePos& + ScrollPage: GOSUB ScrollPage
 CASE CHR$(27): EXIT DO
 END SELECT
 IF LEN(kbrd$) THEN WHILE INKEY$ > "": WEND
LOOP
CLOSE #1
RETURN

ScrollUp:
 IF FilePos& <= 1 THEN RETURN ELSE UpdateStat = 1
 IF FilePos& - ScrollWidth < 1 THEN FilePos& = 1 ELSE FilePos& = FilePos& - ScrollWidth
 DEF SEG = VARSEG(ScrollDownAsm(1)): CALL absolute(VARPTR(ScrollDownAsm(1)))
 CurLine = 0: GOSUB ScrollShowLine
RETURN
ScrollDown:
 IF FilePos& + ScrollPage > FileLeng& THEN RETURN ELSE UpdateStat = 1
 FilePos& = FilePos& + ScrollWidth
 DEF SEG = VARSEG(ScrollUpAsm(1)): CALL absolute(VARPTR(ScrollUpAsm(1)))
 CurLine = ScrollHeight - ScrollTopRow: GOSUB ScrollShowLine
RETURN
ScrollPage:
 UpdateStat = 1
 FOR CurLine = 0 TO ScrollHeight - 1
  GOSUB ScrollShowLine
 NEXT CurLine
RETURN
ScrollShowLine:
 FileOfset& = FilePos& + (CurLine * ScrollWidth)
 IF FileOfset& > FileLeng& THEN LOCATE CurLine + ScrollTopRow + 1, 1: PRINT SPACE$(ScrollWidth); : RETURN
 IF FileLeng& - FileOfset& > ScrollWidth THEN DataLength = ScrollWidth ELSE DataLength = FileLeng& - FileOfset& + 1
 SEEK 1, FileOfset&
 FileData$ = INPUT$(DataLength, 1)
 DEF SEG = &HB800
 ScreenOfset = (CurLine + ScrollTopRow) * ScrollWidth * 2
 FOR Col = 1 TO LEN(FileData$)
   POKE ScreenOfset, ASC(MID$(FileData$, Col, 1))
   ScreenOfset = ScreenOfset + 2
 NEXT Col
RETURN

DirErrHan: FilErr = 1: RESUME NEXT
FilErrHan: FilErr = ERR: RESUME NEXT

SUB Prompt (Text$, kbrd$, Row, Col, RecLeng, CurPos)
IF CurPos > LEN(Text$) THEN CurPos = LEN(Text$)
Chng = 1
DO
 kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE ""
 CASE " " TO "ÿ": Chng = 1
  IF LEN(Text$) < RecLeng THEN Text$ = LEFT$(Text$, CurPos) + kbrd$ + RIGHT$(Text$, LEN(Text$) - CurPos): CurPos = CurPos + 1
 CASE CHR$(0) + "K": IF CurPos > 0 THEN CurPos = CurPos - 1: Chng = 1
 CASE CHR$(0) + "M": IF CurPos < LEN(Text$) THEN CurPos = CurPos + 1: Chng = 1
 CASE "": IF CurPos > 0 THEN Text$ = LEFT$(Text$, CurPos - 1) + RIGHT$(Text$, LEN(Text$) - CurPos): CurPos = CurPos - 1: Chng = 1
 CASE ELSE: EXIT SUB
 END SELECT

 IF Chng THEN
  LOCATE , , 0: LOCATE Row, Col
  PRINT LEFT$(Text$ + SPACE$(RecLeng), RecLeng);
  IF CurPos < RecLeng THEN LOCATE Row, Col + CurPos: LOCATE , , 1
  Chng = 0
 END IF
LOOP
kbrd$ = ""

END SUB

