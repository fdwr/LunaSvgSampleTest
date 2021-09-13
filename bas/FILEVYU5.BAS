DEFINT A-Z
DECLARE SUB ScrollFile (WinRow, ScrollDif)

SCREEN 0: WIDTH 80, 25: VIEW PRINT: LOCATE , , 0, 14, 15

WinWdth = 80: WinHite = 22: WinRow = 0: WinVof = 2: WinHof = 0: WinOpn = 0
DIM SHARED ScrollUp(1 TO 7), ScrollDown(1 TO 7)
DATA &HB8,&H01,&H06,&HB9,&H00,&H03,&HBA,&H4F,&H18,&HB7,&H0F,&HCD,&H10,&HCB
DATA &HB8,&H01,&H07,&HB9,&H00,&H03,&HBA,&H4F,&H18,&HB7,&H0F,&HCD,&H10,&HCB
MemAbs = VARPTR(ScrollUp(1)): DEF SEG = VARSEG(ScrollUp(1)): FOR ReadIn = 0 TO 13: READ Byte: POKE (MemAbs + ReadIn), Byte: NEXT ReadIn
MemAbs = VARPTR(ScrollDown(1)): DEF SEG = VARSEG(ScrollDown(1)): FOR ReadIn = 0 TO 13: READ Byte: POKE (MemAbs + ReadIn), Byte: NEXT ReadIn

ON ERROR GOTO FilErrHan
GOSUB HeadInfo: GOSUB PosStat: GOSUB ShowFileName: ScrollFile WinRow, ScrollDif
GOSUB NamePromptVerify: GOSUB NamePromptShow
DO
 Key$ = INKEY$
 SELECT CASE Key$
 CASE " " TO "ÿ": IF LEN(File$) < 64 THEN File$ = LEFT$(File$, NameCurp) + Key$ + RIGHT$(File$, LEN(File$) - NameCurp): NameCurp = NameCurp + 1: GOSUB NamePromptShow
 CASE CHR$(0) + "K": IF NameCurp > 0 THEN NameCurp = NameCurp - 1: GOSUB NamePromptShow
 CASE CHR$(0) + "M": IF NameCurp < LEN(File$) THEN NameCurp = NameCurp + 1: GOSUB NamePromptShow
 CASE "": IF File$ > "" AND NameCurp > 0 THEN File$ = LEFT$(File$, NameCurp - 1) + RIGHT$(File$, LEN(File$) - NameCurp): NameCurp = NameCurp - 1: GOSUB NamePromptShow
 CASE CHR$(0) + "<"
  COLOR 7, 0: CLS 0: SHELL "DIR/A/P " + File$
  LOCATE 24, 1: PRINT : PRINT "Press any key to return to FileView";
  WHILE INKEY$ = "": WEND
  GOSUB HeadInfo: GOSUB PosStat: GOSUB ShowFileName: ScrollFile WinRow, 0: GOSUB NamePromptShow
 CASE CHR$(27): UserDone = 1
 CASE CHR$(13)
  IF File$ = "" THEN
   CLOSE #1: IF WinOpn THEN ScrollFile 0, 0
   WinOpn = 0: CurrFile$ = "": GOSUB ShowFileName: GOSUB PosStat
   GOSUB NamePromptShow
  ELSE
   FilErr = 0: CLOSE #2: OPEN File$ FOR INPUT AS #2: CLOSE #2
   IF FilErr = 0 THEN
    CLOSE #1: OPEN File$ FOR BINARY AS #1
    WinOpn = 1: WinRow = 0: CurrFile$ = UCASE$(File$): GOSUB ShowFileName
    GOSUB PosStat: ScrollFile WinRow, 0: GOSUB NamePromptShow
   ELSE
    Text$ = "Error opening the specified file"
    IF WinOpn THEN Text$ = Text$ + "...Last file will remain open"
    COLOR 0, 4: GOSUB Notice
   END IF
  END IF
 END SELECT
 IF WinOpn THEN
  SELECT CASE Key$
  CASE CHR$(0) + "H"
   IF WinRow > 0 THEN ScrollDif = WinRow: WinRow = WinRow - 1': ScrollFile WinRow, -1: GOSUB Update
  CASE CHR$(0) + "P"
   IF (CLNG(WinRow) + WinHite) * WinWdth < LOF(1) THEN ScrollDif = WinRow: WinRow = WinRow + 1': ScrollFile WinRow, 1: GOSUB Update
  CASE CHR$(0) + "G"
   IF WinRow <> 0 THEN ScrollDif = WinRow: WinRow = 0': ScrollFile WinRow, 0: GOSUB Update
  CASE CHR$(0) + "O"
   IF (CLNG(WinRow) + WinHite) * WinWdth < LOF(1) AND WinWdth > 0 THEN ScrollDif = WinRow: WinRow = LOF(1) \ WinWdth - WinHite + 1': ScrollFile WinRow, 0: GOSUB Update
  CASE CHR$(0) + "Q"
   IF (CLNG(WinRow) + WinHite) * WinWdth < LOF(1) THEN ScrollDif = WinRow: WinRow = WinRow + WinHite': ScrollFile WinRow, 0: GOSUB Update
  CASE CHR$(0) + "I"
   IF WinRow > 0 THEN
    WinRow = WinRow - WinHite: IF WinRow < 0 THEN WinRow = 0
    'ScrollFile WinRow, 0: GOSUB Update
   END IF
  CASE "": Ready = -1
  END SELECT
  IF ScrollDif <> WinRow AND Ready THEN ScrollFile WinRow, WinRow - ScrollDif: GOSUB Update: ScrollDif = WinRow: Ready = 0
 END IF
LOOP UNTIL UserDone
CLOSE
COLOR 7, 0: CLS
SYSTEM

NamePromptVerify:
 IF NameCurp > LEN(File$) THEN NameCurp = LEN(File$) ELSE IF NameCurp < 0 THEN NameCurp = 0
 RETURN
NamePromptShow:
 LOCATE , , 0: LOCATE 3, 7: COLOR 15, 7: PRINT LEFT$(File$, 64); TAB(71); : IF NameCurp < 65 THEN LOCATE 3, 7 + NameCurp, 1
 RETURN
HeadInfo:
 LOCATE 3, 1: COLOR 0, 7: PRINT "Name:"; TAB(80); " "; : LOCATE 2, 1: COLOR 0, 3: PRINT "Byte:"; TAB(30); "Row:"; TAB(80); " ";
 RETURN
PosStat:
 WinOfs& = CLNG(WinRow) * WinWdth
 LOCATE 2, 6: COLOR 15, 3: IF WinOpn THEN PRINT STR$(WinOfs&); " -"; STR$(WinOfs& + (WinWdth * WinHite) - 1); TAB(30);  ELSE PRINT TAB(30);
 LOCATE 2, 34: IF WinOpn THEN PRINT STR$(WinRow); TAB(45);  ELSE PRINT TAB(45);
 RETURN
ShowFileName:
 LOCATE 1, 1: COLOR 0, 3: PRINT "File: "; : COLOR 15
 IF LEN(CurrFile$) > 72 THEN PRINT RIGHT$(CurrFile$, 72); "  ";  ELSE IF CurrFile$ = "" THEN PRINT "None"; TAB(79);  ELSE PRINT CurrFile$; SPACE$(72 - LEN(CurrFile$));
 LOCATE 1, 79: IF WinOpn THEN PRINT " û";  ELSE PRINT " X";
RETURN
Update: GOSUB PosStat: GOSUB NamePromptShow: RETURN
Notice:
 LOCATE 2, 1: PRINT LEFT$(Text$, 78); TAB(80); " ";
 WHILE INKEY$ = "": WEND: GOSUB HeadInfo: GOSUB PosStat: GOSUB NamePromptShow
RETURN
FilErrHan: FilErr = 1: RESUME NEXT

SUB ScrollFile (WinRow, ScrollDif)
: WinWdth = 80: WinHite = 22: WinVof = 3: WinHof = 0
IF FREEFILE = 1 THEN
 COLOR 0, 3
 FOR Show = WinVof + 1 TO WinHite + WinVof
  LOCATE Show, WinHof + 1: PRINT STRING$(WinWdth, 176);
 NEXT Show
 EXIT SUB
ELSE COLOR 15, 1: FileLeng& = LOF(1)
END IF

SELECT CASE ScrollDif
CASE -1
 SEEK 1, CLNG(WinRow) * WinWdth + 1: VerLine = WinVof * 80
 DEF SEG = VARSEG(ScrollDown(1)): CALL ABSOLUTE(VARPTR(ScrollDown(1)))
 DEF SEG = &HB800: GOSUB ShowFileRow
 IF LEN(Byte$) < WinWdth THEN GOSUB PadTheRest
CASE 1
 SEEK 1, CLNG(WinRow + WinHite - 1) * WinWdth: VerLine = (WinVof + WinHite - 1) * 80
 DEF SEG = VARSEG(ScrollUp(1)): CALL ABSOLUTE(VARPTR(ScrollUp(1)))
 DEF SEG = &HB800: GOSUB ShowFileRow
 IF LEN(Byte$) < WinWdth THEN ReadIn = WinHite - 1: GOSUB PadTheRest
CASE ELSE
 SEEK 1, CLNG(WinRow) * WinWdth + 1
 DEF SEG = &HB800
 FOR ReadIn = 0 TO WinHite - 1
  VerLine = (ReadIn + WinVof) * 80
  GOSUB ShowFileRow
  IF LEN(Byte$) < WinWdth THEN GOSUB PadTheRest: EXIT FOR
 NEXT ReadIn
END SELECT
EXIT SUB
ShowFileRow:
IF SEEK(1) > FileLeng& THEN Byte$ = "" ELSE IF FileLeng& - SEEK(1) < WinWdth THEN Byte$ = INPUT$(FileLeng& - SEEK(1), 1) ELSE Byte$ = INPUT$(WinWdth, 1)
MemAbs = VerLine * 2
FOR Show = 1 TO LEN(Byte$)
 POKE MemAbs, ASC(MID$(Byte$, Show, 1))
 POKE MemAbs + 1, 31
 MemAbs = MemAbs + 2
NEXT Show
RETURN
PadTheRest:
LOCATE ReadIn + WinVof + 1, LEN(Byte$) + WinHof + 1
COLOR 0, 3: PRINT STRING$(WinWdth - LEN(Byte$), 176);
FOR Show = ReadIn + 2 TO WinHite
 LOCATE Show + WinVof, WinHof + 1
 PRINT STRING$(WinWdth, 176);
NEXT Show
RETURN
END SUB

