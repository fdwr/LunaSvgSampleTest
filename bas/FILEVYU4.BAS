DEFINT A-Z
DECLARE SUB FilePrompt (File$, Keys$, InResult, OutResult)
DECLARE SUB DosErrResponse (DosErr)
DECLARE SUB STRPROMPT (Rslt$, RcLn, Vrow, Lcol, Leng, Curp, Curs, Keys$)
DECLARE SUB PRINTROW (Urow, Lcol, text$)
DECLARE SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
DECLARE FUNCTION LIMIT (Nmbr1, Nmbr2, Mode)
DECLARE FUNCTION DELETE$ (text$, Strt, Leng)
DECLARE SUB TEXTWRAP (TexH, Wrap, Ulin, Lcol, Fore, Back, text$)
DECLARE SUB DRAWBUTTON (Lcol, Rcol, Ulin, Dlin, Fore, Back, Sfor)
DECLARE FUNCTION DOSPATH$ ()
DECLARE SUB UpdateFileWin (Urow, Drow, Mode)

CONST TRUE = -1, FALSE = 0
DIM SHARED ScrollUp(1 TO 7), ScrollDown(1 TO 7), Files$(1 TO 10), DosErr, DosRow, DosCol, FileOpen, FileLeng&, CurFile$, CurFile, FilePos&, FileRow&
DIM SHARED FileWinTrow, FileWinBrow, FileWinWidth, FileWinHeight, InfoLine
DATA &HB8,&H01,&H06,&HB9,&H00,&H01,&HBA,&H4F,&H18,&HB7,&H0F,&HCD,&H10,&HCB
DATA &HB8,&H01,&H07,&HB9,&H00,&H01,&HBA,&H4F,&H18,&HB7,&H0F,&HCD,&H10,&HCB

MemAbs = VARPTR(ScrollUp(1)): DEF SEG = VARSEG(ScrollUp(1)): FOR ReadIn = 0 TO 13: READ Byte: POKE (MemAbs + ReadIn), Byte: NEXT ReadIn
MemAbs = VARPTR(ScrollDown(1)): DEF SEG = VARSEG(ScrollDown(1)): FOR ReadIn = 0 TO 13: READ Byte: POKE (MemAbs + ReadIn), Byte: NEXT ReadIn
FileWinTrow = 1: FileWinBrow = 24: FileWinWidth = 80: FileWinHeight = 24: InfoLine = 1
PCOPY 0, 1: WIDTH 80, 25: DosRow = CSRLIN: DosCol = POS(0): VIEW PRINT: COLOR 15, 7: CLS

UpdateFileWin FileWinTrow, FileWinBrow, 3

GetFileName:
FilePrompt "", "", 1, 0
DO
 FilePrompt File$, Keys$, 0, OutResult
 SELECT CASE OutResult
 CASE 1: IF FileOpen THEN FilePrompt "", "", 2, 0: GOTO ScrollPrompt ELSE GOTO EndIt
 CASE 2: GOSUB Opener: IF DosErr THEN DosErrResponse DosErr ELSE IF FileOpen = TRUE THEN UpdateFileWin FileWinTrow, FileWinBrow, 3: GOTO ScrollPrompt ELSE IF FileOpen = FALSE THEN UpdateFileWin FileWinTrow, FileWinBrow, 3: FilePrompt "", "", 1, 0
 CASE 3: GOSUB Doshell: FilePrompt "", "", 1, 0
END SELECT
LOOP

ScrollPrompt:
DO
 SELECT CASE INKEY$
 CASE ""
 CASE CHR$(0) + "I": IF FilePos& >= FileWinHeight * FileWinWidth THEN FilePos& = FilePos& - FileWinHeight * FileWinWidth: UpdateFileWin FileWinTrow, FileWinBrow, 3: WHILE INKEY$ > "": WEND ELSE IF FilePos& > 0 THEN FilePos& = 0: UpdateFileWin FileWinTrow, FileWinBrow, 3
 CASE CHR$(0) + "Q": IF FilePos& + (FileWinHeight * FileWinWidth) < FileLeng& THEN FilePos& = FilePos& + FileWinHeight * FileWinWidth: UpdateFileWin FileWinTrow, FileWinBrow, 3: WHILE INKEY$ > "": WEND ELSE IF FilePos& < FileLeng& - 1 THEN FilePos& = FileLeng& - 1: UpdateFileWin FileWinTrow, FileWinBrow, 3
 CASE CHR$(9): SCREEN , , 1, 1: LOCATE DosRow, DosCol: WHILE INKEY$ = "": WEND: SCREEN , , 0, 0
 CASE CHR$(0) + "H": IF FilePos& - FileWinWidth >= 0 THEN FilePos& = FilePos& - FileWinWidth: UpdateFileWin 1, 1, 1
 CASE CHR$(0) + "P": IF FilePos& < FileLeng& - FileWinWidth THEN FilePos& = FilePos& + FileWinWidth: UpdateFileWin 1, 1, 2
 CASE CHR$(0) + "K": IF FilePos& > 0 THEN FilePos& = FilePos& - 1: IF FilePos& MOD FileWinWidth = FileWinWidth - 1 THEN UpdateFileWin 1, 1, 1 ELSE UpdateFileWin 1, 1, 0
 CASE CHR$(0) + "M": IF FilePos& < FileLeng& - 1 THEN FilePos& = FilePos& + 1: IF FilePos& MOD FileWinWidth = 0 THEN UpdateFileWin 1, 1, 2 ELSE UpdateFileWin 1, 1, 0
 CASE CHR$(13): GOTO GetFileName
 CASE CHR$(27): CLOSE : EXIT DO
 CASE CHR$(27): EXIT DO
 END SELECT
LOOP

EndIt: PCOPY 1, 0: LOCATE DosRow, DosCol: COLOR 7, 0: SYSTEM

Opener:
IF File$ = "" THEN CLOSE : DosErr = FALSE: FileOpen = FALSE: CurFile$ = "": RETURN
ON ERROR GOTO FilErrHan: NewFile = FREEFILE
DosErr = 0: OPEN File$ FOR INPUT AS NewFile: CLOSE NewFile
IF DosErr THEN RETURN
DosErr = 0: OPEN File$ FOR BINARY ACCESS READ AS NewFile
CLOSE CurFile: CurFile = NewFile: FileLeng& = LOF(CurFile): FilePos& = 0
IF DosErr THEN RETURN ELSE File$ = UCASE$(File$): CurFile$ = File$: FileOpen = TRUE
RETURN

Doshell:
PCOPY 1, 0: LOCATE DosRow, DosCol: COLOR 7, 0
IF File$ = "" THEN PRINT CHR$(13); "When done, you can return to FV2 by typing 'EXIT' at the prompt"
SHELL File$
IF File$ > "" THEN WHILE INKEY$ = "": WEND
DosRow = CSRLIN: DosCol = POS(0): PCOPY 0, 1
UpdateFileWin FileWinTrow, FileWinBrow, 3
RETURN

ErrTrap: Exist = 0: RESUME NEXT

DirErrHan: DosErr = ERR: RESUME NEXT
FilErrHan: DosErr = ERR: RESUME NEXT

FUNCTION DELETE$ (text$, St, Lg)
IF SGN(Lg) = -1 THEN Lt = St + Lg: Rt = LEN(text$) - St ELSE Lt = St: Rt = LEN(text$) - (St + Lg)
IF Lt > LEN(text$) THEN Lt = LEN(text$) ELSE IF Lt < 0 THEN Lt = 0
IF Rt > LEN(text$) THEN Rt = LEN(text$) ELSE IF Rt < 0 THEN Rt = 0
DELETE$ = LEFT$(text$, Lt) + RIGHT$(text$, Rt)
END FUNCTION

SUB DosErrResponse (DosErr)
SELECT CASE DosErr
CASE 6: ErrTxt$ = "      Avalanche, Too Much to load       This file has more byte postions than this program can access."
CASE 53: ErrTxt$ = "        Sorry can not find it~You might have spelled the filename   wrong or typed in a file that does    not exist. If it does exist, shell    'DIR /S'+ filename to search for it."
CASE 64: ErrTxt$ = "        Very very bad filename~This is different than spelling a name~wrong. None of these special reserved~symbols are allowed in a filename:~ / \ < > [ ] . , : ; ? * + | = " + CHR$(34) + "  "
CASE 68: ErrTxt$ = "  Sorry, that device is unavailable"
CASE 71, 75: ErrTxt$ = "  Can not access that device or path"
CASE 76: ErrTxt$ = "If you were my guide, I would be lost!~This path does not exist or maybe you~are mixed up with another road. Type~'DIR /AD' and press Ctrl+ENTER for a~listing of real directories."
CASE ELSE: ErrTxt$ = "          Unknown Error !             Error" + STR$(ERR) + " is unknown"
END SELECT
DRAWBUTTON 4, 8, 22, 59, 0, 3, 8
TEXTWRAP 4, 8, 22, 59, 15, 3, ErrTxt$
WHILE INKEY$ = "": WEND
UpdateFileWin 3, 8, 3
END SUB

DEFSNG A-Z
FUNCTION DOSPATH$
DEF SEG = 0: Path$ = "": CHDIR "."
FOR Show% = 5406 TO 5470
 IF PEEK(Show%) = 0 THEN EXIT FOR ELSE Path$ = Path$ + CHR$(PEEK(Show%))
NEXT Show%
DOSPATH$ = Path$
END FUNCTION

DEFINT A-Z
SUB DRAWBUTTON (Ulin, Dlin, Lcol, Rcol, Fore, Back, Sfor)
IF Dlin > 25 THEN Dlin = 25
IF Rcol > 80 THEN Rcol = 80
Bwidth = LIMIT(Rcol, 80, 0) - LIMIT(Lcol, 1, 1) + 1

LOCATE , , 0: COLOR Fore, Back
FOR Hset = LIMIT(Ulin, 1, 1) TO Dlin
 LOCATE Hset, LIMIT(Lcol, 1, 1)
 PRINT SPACE$(LIMIT(Bwidth, 0, 1));
NEXT Hset

COLOR Sfor
IF Rcol < 80 AND Bwidth > 0 THEN
 IF Ulin > 0 THEN PRINTROW Ulin, Rcol + 1, "Ü": Prow = ((Ulin - 1) * 80 + Rcol) * 2 + 1: POKE Prow, (PEEK(Prow) AND 240) OR Sfor
 FOR Hset = LIMIT(Ulin, 0, 1) + 1 TO Dlin
  LOCATE Hset, Rcol + 1: PRINT "Û";
 NEXT Hset
END IF
IF Bwidth > 0 THEN
 Prow = Dlin * 80
 FOR Show = (Prow + Lcol) * 2 TO (Prow + Rcol) * 2 STEP 2
  POKE Show + 1, (PEEK(Show + 1) AND 240) OR Sfor
 NEXT Show
 PRINTROW Dlin + 1, LIMIT(Lcol + 1, 1, 1), STRING$(LIMIT(Rcol, 79, 0) - LIMIT(Lcol, 0, 1) + 1, "ß")
END IF
END SUB

SUB FilePrompt (File$, Keys$, InResult, OutResult) STATIC

Rcl = 0
IF InResult = 2 THEN
 UpdateFileWin 10, 14, 3
 EXIT SUB
END IF

IF InResult THEN
 DRAWBUTTON 11, 14, 4, 77, 0, 11, 8
 DRAWBUTTON 13, 13, 6, 73, 0, 7, 8
 COLOR , 3
 EXIT SUB
END IF

OutResult = 0: Curp = LEN(File$): Curs = 0
DO
 LOCATE 12, 6: COLOR 15, 3: PRINT LEFT$(DOSPATH + SPACE$(68), 68);
 LOCATE 12, 76: IF Files$(Rcl + 1) > "" THEN PRINT "";  ELSE PRINT " ";
 LOCATE 13, 76: IF Rcl > 0 THEN PRINT "";  ELSE PRINT " ";
 STRPROMPT File$, 128, 13, 6, 68, Curp, Curs, Keys$
 SELECT CASE Keys$
 CASE "":
 CASE CHR$(0) + "H": IF Rcl < UBOUND(Files$, 0) THEN IF Files$(Rcl + 1) > "" THEN Rcl = Rcl + 1: GOSUB FilePromptRecall
 CASE CHR$(0) + "P": IF Rcl > 0 THEN Rcl = Rcl - 1: GOSUB FilePromptRecall
 CASE "": OutResult = 1: EXIT DO
 CASE CHR$(9): SCREEN , , 1, 1: LOCATE DosRow, DosCol: WHILE INKEY$ = "": WEND: SCREEN , , 0, 0
 CASE CHR$(13): IF File$ > "" THEN ON ERROR GOTO DirErrHan: DosErr = 0: CHDIR File$: IF DosErr THEN OutResult = 2 ELSE GOSUB FilePromptEntry: Curp = LEN(File$): Curs = 0
 CASE CHR$(10): OutResult = 3
 CASE ELSE: OutResult = 0: EXIT DO
 END SELECT
 WHILE INKEY$ > "": WEND
LOOP UNTIL OutResult
IF OutResult THEN GOSUB FilePromptEntry
EXIT SUB

FilePromptRecall: IF Rcl THEN File$ = Files$(Rcl) ELSE File$ = ""
 Curp = LEN(File$): Curs = Curp: RETURN
FilePromptEntry: File$ = LTRIM$(File$): IF UCASE$(File$) <> UCASE$(Files$(1)) AND File$ > "" THEN FOR Move = 10 TO 2 STEP -1: Files$(Move) = Files$(Move - 1): NEXT Move: Files$(1) = File$: RETURN
END SUB

SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
DEF SEG = &HB800: Urow = Hset - 1: Prow = Urow * 160 + 1
FOR Show = Lcol - 1 TO Rcol - 1 STEP SGN(Rcol - Lcol) OR 1
 POKE Prow + (Show * 2), Colr
NEXT Show
END SUB

FUNCTION LIMIT (Nmbr1, Nmbr2, Mode)
IF Mode THEN
 IF Nmbr1 > Nmbr2 THEN LIMIT = Nmbr1 ELSE LIMIT = Nmbr2
ELSE
 IF Nmbr1 < Nmbr2 THEN LIMIT = Nmbr1 ELSE LIMIT = Nmbr2
END IF
END FUNCTION

SUB PRINTROW (Urow, Lcol, text$)
DEF SEG = &HB800: Vset = (Urow - 1) * 80 + (Lcol - 2)
FOR Show = 1 TO LEN(text$)
 POKE (Vset + Show) * 2, ASC(MID$(text$, Show, 1))
NEXT Show
END SUB

SUB STRPROMPT (Rslt$, RcLn, Vrow, Lcol, Leng, Curp, Curs, Keys$)

Colr = 112: BClr = 7: Chng = 1: Visible = TRUE: Keys$ = "": nCurp = LEN(Rslt$): LOCATE , , 1, 5, 6
IF Vrow < 1 OR Vrow > 25 THEN Visible = FALSE ELSE IF Lcol < 1 OR Lcol > 80 THEN Visible = FALSE

DO
 IF Visible THEN IF Chng THEN GOSUB StrPromptMvCsr: IF Chng > FALSE THEN GOSUB StrPromptShow: Chng = FALSE ELSE Chng = FALSE
 DEF SEG = 0: Shft = PEEK(1047) AND 3: kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE ""
 CASE " " TO "ÿ": GOSUB StrPromptInsert: Chng = 1
 CASE CHR$(0) + "K": Chng = TRUE: IF Curp > 0 THEN nCurp = Curp - 1
 CASE CHR$(0) + "M": Chng = TRUE: IF Curp < LEN(Rslt$) THEN nCurp = Curp + 1
 CASE CHR$(0) + "G": Chng = TRUE: IF Curp THEN nCurp = 0
 CASE CHR$(0) + "O": Chng = TRUE: IF Curp < LEN(Rslt$) THEN nCurp = LEN(Rslt$)
 CASE CHR$(0) + "s": Lttr = 0
  FOR Srch = Curp TO 1 STEP -1
   IF INSTR(" ÿ()/\.	", MID$(Rslt$, Srch, 1)) = 0 THEN Lttr = -1 ELSE IF Lttr THEN nCurp = Srch: EXIT FOR
  NEXT Srch: Chng = TRUE: IF Srch = 0 THEN nCurp = 0
 CASE CHR$(0) + "t": Lttr = 0
  FOR Srch = Curp + 1 TO LEN(Rslt$)
   IF INSTR(" ÿ()/\.	", MID$(Rslt$, Srch, 1)) THEN Lttr = -1 ELSE IF Lttr THEN nCurp = Srch - 1: EXIT FOR
  NEXT Srch: Chng = TRUE: IF Srch = LEN(Rslt$) + 1 THEN nCurp = LEN(Rslt$)
 CASE CHR$(0) + "S": IF Curp - Curs THEN Rslt$ = DELETE(Rslt$, Curs, Curp - Curs): Chng = 1: IF Curs < Curp THEN nCurp = Curs ELSE  ELSE Rslt$ = DELETE$(Rslt$, Curp, 1): Chng = FALSE: GOSUB StrPromptShow
 CASE "": IF Curp THEN Rslt$ = LEFT$(Rslt$, Curp - 1) + MID$(Rslt$, Curp + 1): nCurp = Curp - 1: Shft = 0: Chng = 1
 CASE ELSE: Keys$ = kbrd$: EXIT DO
 END SELECT
LOOP

EXIT SUB

StrPromptMvCsr:
 IF Shft THEN Chng = 1 ELSE IF Curp <> Curs THEN Curs = nCurp: Chng = 1 ELSE Curs = nCurp
 Curp = nCurp
 IF Curp < RsCr THEN RsCr = Curp: Chng = 1 ELSE IF Curp > RsCr + Leng THEN RsCr = Curp - Leng: Chng = 1
 IF Curp - RsCr < Leng THEN LOCATE Vrow, Lcol + (Curp - RsCr), 1 ELSE LOCATE Vrow, , 0
RETURN
StrPromptShow:
 IF Curp < RsCr THEN RsCr = Curp ELSE IF Curp > RsCr + Leng THEN RsCr = Curp - Leng
 IF Leng - (LEN(Rslt$) - RsCr) >= 0 THEN Tail$ = SPACE$(Leng - (LEN(Rslt$) - RsCr)) ELSE Tail$ = ""
 PRINTROW Vrow, Lcol, MID$(Rslt$, RsCr + 1, Leng) + Tail$
 
 IF LIMIT(LIMIT(Curp, Curs, 0) - RsCr, 0, 1) THEN HIGHLIGHT Lcol, Lcol + LIMIT(LIMIT(Curp, Curs, 0) - RsCr, 0, 1) - 1, Vrow, Colr
 IF Curp - Curs THEN HIGHLIGHT Lcol + LIMIT(LIMIT(Curp, Curs, 0) - RsCr, 0, 1), Lcol + LIMIT((LIMIT(Curp, Curs, 1) - RsCr), Leng, 0) - 1, Vrow, BClr
 IF Leng - 1 <> LIMIT((LIMIT(Curp, Curs, 1) - RsCr), Leng, 0) - 1 THEN HIGHLIGHT Lcol + LIMIT((LIMIT(Curp, Curs, 1) - RsCr), Leng, 0), Lcol + Leng - 1, Vrow, Colr
RETURN
StrPromptInsert:
 Rslt$ = DELETE(Rslt$, Curs, Curp - Curs): IF Curs < Curp THEN Curp = Curs
 IF LEN(Rslt$) + LEN(kbrd$) > RcLn THEN SOUND 860, .1: RETURN
 Rslt$ = LEFT$(Rslt$, Curp) + kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - Curp): Shft = 0
 nCurp = Curp + LEN(kbrd$): Curs = nCurp
RETURN
END SUB

SUB TEXTWRAP (Urow, Drow, Lcol, Rcol, Fore, Back, text$)
COLOR Fore, Back
Spos = 1: Hwid = Rcol - Lcol + 1: IF Hwid < 1 THEN Hwid = 0
FOR Vrow = Urow TO Drow
 Npos = INSTR(Spos, text$, "~")
 IF Npos = 0 THEN Wdth = LEN(text$) + 1 - Spos ELSE Wdth = Npos - Spos
 IF Wdth > Hwid THEN Wdth = Hwid
 LOCATE Vrow, Lcol: PRINT MID$(text$, Spos, Wdth); SPACE$(Hwid - Wdth);
 IF Npos THEN Spos = Npos + 1 ELSE Spos = Spos + Hwid
NEXT Vrow
END SUB

SUB UpdateFileWin (Urow, Drow, Mode)

IF Urow < FileWinTrow THEN Urow = FileWinTrow
IF Drow > FileWinBrow THEN Drow = FileWinBrow

IF FileOpen = 0 THEN
 GOSUB ShowInfoBar: GOSUB ShowInfo
 COLOR , 7
 FOR Show = Urow + 1 TO Drow + 1
  LOCATE Show, 1: PRINT SPACE$(FileWinWidth);
 NEXT Show
 EXIT SUB
END IF
COLOR , 7

FileRow& = FilePos& - (FilePos& MOD FileWinWidth)

SELECT CASE Mode
CASE 1
 DEF SEG = VARSEG(ScrollDown(1)): CALL ABSOLUTE(VARPTR(ScrollDown(1)))
 ReadPos& = FileRow& + 1
 DEF SEG = &HB800: ShowLine = 0: GOSUB DisplayFileRow
CASE 2
 DEF SEG = VARSEG(ScrollUp(1)): CALL ABSOLUTE(VARPTR(ScrollUp(1)))
 ReadPos& = FileRow& + (FileWinHeight - 1) * FileWinWidth + 1
 DEF SEG = &HB800: ShowLine = FileWinHeight - 1: GOSUB DisplayFileRow
CASE 3
 ReadPos& = FileRow& + (Urow - FileWinTrow) * FileWinWidth + 1
 DEF SEG = &HB800
 FOR ShowLine = Urow - 1 TO Drow - 1
  GOSUB DisplayFileRow
  ReadPos& = ReadPos& + FileWinWidth
 NEXT ShowLine
 GOSUB ShowInfoBar
END SELECT

GOSUB ShowInfo
LOCATE FileWinTrow + 1, FilePos& MOD FileWinWidth + 1, 1, 1, 14

EXIT SUB

DisplayFileRow:
IF ReadPos& > FileLeng& THEN
 LOCATE ShowLine + FileWinTrow + 1, 1: PRINT SPACE$(FileWinWidth);
ELSE
 SEEK CurFile, ReadPos&
 IF FileLeng& - ReadPos& + 1 < FileWinWidth THEN Byte$ = INPUT$(FileLeng& - ReadPos& + 1, CurFile) ELSE Byte$ = INPUT$(FileWinWidth, CurFile)
 VerLine = (ShowLine + FileWinTrow) * 80 - 1
 FOR Show = 1 TO LEN(Byte$)
  MemAbs = (VerLine + Show) * 2
  POKE MemAbs, ASC(MID$(Byte$, Show, 1))
  POKE MemAbs + 1, 31
 NEXT Show
 IF LEN(Byte$) < FileWinWidth THEN LOCATE ShowLine + FileWinTrow + 1, LEN(Byte$) + 1: PRINT SPACE$(FileWinWidth - LEN(Byte$));
END IF
RETURN

ShowInfoBar:
 COLOR 0, 5: LOCATE InfoLine, 1: PRINT "File:";
 IF CurFile$ = "" THEN PRINT "(None)";  ELSE PRINT RIGHT$(CurFile$, 62);
 PRINT TAB(68); "Pos:         ";
RETURN
ShowInfo:
COLOR 0, 5: LOCATE InfoLine, 72: PRINT LTRIM$(STR$(FilePos&)); TAB(80);
RETURN

END SUB

