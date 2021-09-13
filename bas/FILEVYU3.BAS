DEFINT A-Z
DECLARE SUB FilePrompt (File$, Keys$, InResult%, OutResult%)
DECLARE SUB DosErrResponse (DosErr%)
DECLARE SUB PRINTROW (Urow, Lcol, Text$)
DECLARE SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
DECLARE SUB TEXTWRAP (TexH, Wrap, Ulin, Lcol, Fore, Back, Text$)
DECLARE SUB SCALE (Frct&, Totl&, Lcol, Rcol, Urow)
DECLARE SUB DRAWBUTTON (Lcol, Rcol, Ulin, Dlin, Fore, Back, Sfor)
DECLARE SUB INTRO ()
DECLARE FUNCTION DOSPATH$ ()
DECLARE FUNCTION LIMIT (Nmbr1, Nmbr2, Mode)
DECLARE SUB STRPROMPT (Rslt$, RcLn, Vrow, Lcol, Leng, CurP, CurS, Keys$)
DECLARE FUNCTION DELETE$ (Text$, Strt, Leng)
PRINT "DO NOT RUN THIS PROGRAM, IT IS NOT READY"
'END

CONST TRUE = 1, FALSE = 0

DIM UP(1 TO 7): DIM SHARED Files$(1 TO 10), DosErr
DEF SEG = VARSEG(UP(1)): FOR Rd = 0 TO 13: READ J: POKE (VARPTR(UP(1)) + Rd), J: NEXT Rd: Rd = 0
DATA &HB8,&H01,&H06,&HB9,&H00,&H03,&HBA,&H50,&H17,&HB7,&H30,&HCD,&H10,&HCB
PCOPY 0, 2: WIDTH 80: DosRow = CSRLIN: DosCol = POS(0): VIEW PRINT: COLOR 15, 7: CLS : LOCATE , , 0
ScrollTopRow = 2: ScrollBtmRow = 24: ScrollWidth = 80: ScrollHeight = 23

'INTRO

GetFileName:
FilePrompt File$, Keys$, 1, OutResult
DO
FilePrompt File$, Keys$, 2, OutResult

SELECT CASE OutResult
CASE 0: PCOPY 2, 0: LOCATE DosRow, DosCol: SYSTEM
CASE 1:
'* PCOPY 0, 1: PCOPY 2, 0: LOCATE DosRow, DosCol: WHILE INKEY$ = "": WEND: PCOPY 1, 0
'* CASE CHR$(0) + ";": IF Clrs <> 1 THEN DRAWBUTTON 26, 55, 7, 20, 0, 7, 8: TEXTWRAP 11, 30, 7, 25, 0, 7, "þNormal Prompt Editing Keys:  ùHOME, END, DEL, BKSP, , ,  ùINSúInsert special charactersùSHIFT+( )úHighlight text   " + SPACE$(30) + "þSpecial Function Keys:       ùENTERúView file in prompt or  change path to directory     ùCtrl+ENTERúShell text to DOS  command prompt (DIR, COPY,.) ù{, }úRecall prior entries  ùTABúShow shell subscreen     ùF2úShow File View 2 Credits  ùF3úShow opening screen (CLS)": WHILE INKEY$ > "": WEND: Clrs = 1
'* CASE CHR$(0) + "<": IF Clrs <> 2 THEN DRAWBUTTON 29, 52, 11, 15, 0, 7, 8: TEXTWRAP 5, 24, 11, 28, 15, 7, "     File Viewer 2        Version 2.0, 3-1996     Programmer Credits:    Dwayne Robinson Demmer  No copyright or patent": Clrs = 2
'* CASE CHR$(0) + "=": IF Clrs <> 3 THEN INTRO: WHILE INKEY$ > "": WEND: Clrs = 3
CASE 2: OpenError = FALSE: GOSUB Opener: IF OpenError THEN DosErrResponse DosErr
CASE 3: GOSUB Doshell
END SELECT
LOOP

Opener:
IF File$ = "" THEN CLOSE : FileOpen = FALSE: RETURN
ON ERROR GOTO FilErrHan: NewFile = FREEFILE
DosErr = 0: OPEN File$ FOR INPUT AS NewFile: CLOSE NewFile
IF DosErr THEN OpenError = TRUE: RETURN
DosErr = 0: OPEN File$ FOR BINARY ACCESS READ AS NewFile
CLOSE CurFile: CurFile = NewFile: FileLeng& = LOF(CurFile): FilePos& = 1
IF DosErr THEN OpenError = TRUE: RETURN ELSE File$ = UCASE$(File$): FileOpen = TRUE
RETURN

ScrollPrompt:
FOR CurLine = 0 TO ScrollHeight - 1
 'GOSUB ScrollShowLine
NEXT CurLine
DO
 kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE ""
 CASE CHR$(0) + "H": 'GOSUB ScrollUp
 CASE CHR$(0) + "P": 'GOSUB ScrollDown
 CASE CHR$(27): EXIT DO
 END SELECT
LOOP
RETURN

RETURN

Doshell:
PCOPY 0, 1: PCOPY 2, 0: LOCATE DosRow, DosCol
IF File$ = "" THEN COLOR 7, 0: PRINT CHR$(13); "When done, you can return to FV2 by typing 'EXIT' at the prompt"
SHELL File$
IF File$ > "" THEN COLOR 7, 0: PRINT "Press any key to return to FV2..": WHILE INKEY$ = "": WEND
PCOPY 0, 2: PCOPY 1, 0: DosRow = CSRLIN: DosCol = POS(0)
RETURN

ErrTrap: Exist = 0: RESUME NEXT

DirErrHan: DosErr = ERR: RESUME NEXT
FilErrHan: DosErr = ERR: RESUME NEXT

FUNCTION DELETE$ (Text$, St, Lg)
IF SGN(Lg) = -1 THEN Lt = St + Lg: Rt = LEN(Text$) - St ELSE Lt = St: Rt = LEN(Text$) - (St + Lg)
IF Lt > LEN(Text$) THEN Lt = LEN(Text$) ELSE IF Lt < 0 THEN Lt = 0
IF Rt > LEN(Text$) THEN Rt = LEN(Text$) ELSE IF Rt < 0 THEN Rt = 0
DELETE$ = LEFT$(Text$, Lt) + RIGHT$(Text$, Rt)
END FUNCTION

SUB DosErrResponse (DosErr)
PCOPY 0, 1
SELECT CASE DosErr
CASE 6: ErrTxt$ = "      Avalanche, Too Much to load       This file has more byte postions than this program can access."
CASE 53: ErrTxt$ = "        Sorry can not find it          You might have spelled the filename   wrong or typed in a file that does    not exist. If it does exist, shell    'DIR /S'+ filename to search for it."
CASE 64: ErrTxt$ = "   Get out your instruction manual!    Now this is different than just spel- ling a name wrong. You totally goofed it up. These are reserved characters: / \ < > [ ] . , : ; ? * + | = " + CHR$(34) + "  "
CASE 68: ErrTxt$ = "  Sorry, that device is unavailable"
CASE 71, 75: ErrTxt$ = "  Can not access that device or path"
CASE 76: ErrTxt$ = "If you were my guide, I would be lost! This path does not exist or maybe you are mixed up with another road. Type  'DIR /AD' and press Ctrl+ENTER for a  listing of real directories."
CASE ELSE: ErrTxt$ = "          Unknown Error !             Error" + STR$(ERR) + " is unknown"
END SELECT
DRAWBUTTON 22, 59, 6, 10, 0, 7, 8
TEXTWRAP 10, 38, 6, 21, 0, 7, ErrTxt$
WHILE INKEY$ = "": WEND: PCOPY 1, 0
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
SUB DRAWBUTTON (Lcol, Rcol, Ulin, Dlin, Fore, Back, Sfor)
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
IF InResult = 0 THEN
 PCOPY 1, 0
 OutResult = 1
 EXIT SUB
END IF

IF InResult AND 1 THEN
 PCOPY 0, 1
 DRAWBUTTON 4, 77, 11, 14, 0, 11, 8
 DRAWBUTTON 6, 73, 13, 13, 0, 7, 8
 COLOR , 3
END IF

IF InResult < 2 THEN EXIT SUB

OutResult = 0: CurP = LEN(File$): CurS = 0
DO
 LOCATE 12, 6: COLOR 15, 3: PRINT LEFT$(DOSPATH + SPACE$(68), 68);
 LOCATE 12, 76: IF Files$(Rcl + 1) > "" THEN PRINT "";  ELSE PRINT " ";
 LOCATE 13, 76: IF Rcl > 0 THEN PRINT "";  ELSE PRINT " ";
 STRPROMPT File$, 128, 13, 6, 68, CurP, CurS, Keys$
 SELECT CASE Keys$
 CASE "":
 CASE CHR$(0) + "H": IF Rcl < UBOUND(Files$, 0) THEN IF Files$(Rcl + 1) > "" THEN Rcl = Rcl + 1: GOSUB FilePromptRecall
 CASE CHR$(0) + "P": IF Rcl > 0 THEN Rcl = Rcl - 1: GOSUB FilePromptRecall
 CASE "": PCOPY 1, 0: EXIT DO
 CASE CHR$(13): ON ERROR GOTO DirErrHan: DosErr = 0: CHDIR File$: IF DosErr THEN OutResult = 2 ELSE GOSUB FilePromptEntry: CurP = LEN(File$): CurS = 0
 CASE CHR$(10): OutResult = 3
 CASE ELSE: OutResult = 1
 END SELECT
 WHILE INKEY$ > "": WEND
LOOP UNTIL OutResult
GOSUB FilePromptEntry
EXIT SUB

FilePromptRecall: IF Rcl THEN File$ = Files$(Rcl) ELSE File$ = ""
 CurP = LEN(File$): CurS = CurP: RETURN
FilePromptEntry: File$ = LTRIM$(File$): IF File$ <> Files$(1) AND File$ > "" THEN FOR Move = 10 TO 2 STEP -1: Files$(Move) = Files$(Move - 1): NEXT Move: Files$(1) = File$: RETURN
END SUB

SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
DEF SEG = &HB800: Urow = Hset - 1: Prow = Urow * 160 + 1
FOR Show = Lcol - 1 TO Rcol - 1 STEP SGN(Rcol - Lcol) OR 1
 POKE Prow + (Show * 2), Colr
NEXT Show
END SUB

DEFSNG A-Z
SUB INTRO
LOCATE , , 0
VIEW PRINT 5 TO 24: COLOR 0, 3: CLS : VIEW PRINT
TEXTWRAP 11, 60, 5, 10, 11, 3, " This is the second version of Dwayne's file viewer utility with which you can view any file. Unlike most programs, you can see all characters, even control characters. To open thefile that you want to be displayed, type in the entire name (including the path if it is on another directory or drive) then press ENTER. The file's contents will scroll across thescreen. If you want to pause it, use the PAUSE key or press the ESCAPE key to stop it. You can also execute DOS commandsfrom this program. Just type in the DOS command and then hitCtrl+ENTER (not ENTER). This can be used for things such as showing a directory listing. If you press Ctrl+ENTER withoutanything typed in the prompt, you will shell to the Command Prompt. Then type EXIT at the Command Prompt to exit it and return to File View 2. You can Change directories by typing its name. Use the UP and DOWN arrow keys to recall files or commands you have already entered. This prompt works like a Windows prompt as far as editing. Press ESCAPE while at the prompt to exit File View 2. (like you would really do that!)"
END SUB

DEFINT A-Z
FUNCTION LIMIT (Nmbr1, Nmbr2, Mode)
IF Mode THEN
 IF Nmbr1 > Nmbr2 THEN LIMIT = Nmbr1 ELSE LIMIT = Nmbr2
ELSE
 IF Nmbr1 < Nmbr2 THEN LIMIT = Nmbr1 ELSE LIMIT = Nmbr2
END IF
END FUNCTION

SUB PRINTROW (Urow, Lcol, Text$)
DEF SEG = &HB800: Vset = (Urow - 1) * 80 + (Lcol - 2)
FOR Show = 1 TO LEN(Text$)
 POKE (Vset + Show) * 2, ASC(MID$(Text$, Show, 1))
NEXT Show
END SUB

SUB SCALE (FRACT&, Total&, Lcol, Rcol, Urow)
LENGT = Rcol - Lcol + 1
IF Total& = 0 THEN Part = LENGT ELSE Part = INT((FRACT& * LENGT) / Total&)

LOCATE Urow, Lcol: PRINT STRING$(Part, 219) + STRING$(LENGT - Part, 176);
END SUB

SUB STRPROMPT (Rslt$, RcLn, Vrow, Lcol, Leng, CurP, CurS, Keys$)

Colr = 112: BClr = 7: Chng = 2: Keys$ = "": LOCATE , , 1, 5, 6
IF Vrow < 1 OR Vrow > 25 THEN Chng = 0 ELSE IF Lcol < 1 OR Lcol > 80 THEN Chng = 0

Shft = -1: IF Chng THEN GOSUB StrPromptShow

DO
DEF SEG = 0: Shft = PEEK(1047) AND 3
Chng = Chng OR 1: kbrd$ = INKEY$
SELECT CASE kbrd$
CASE "": Chng = Chng AND 2
CASE " " TO "ÿ": GOSUB StrPromptInsert
CASE CHR$(0) + "K": IF CurP > 0 THEN CurP = CurP - 1
CASE CHR$(0) + "M": IF CurP < LEN(Rslt$) THEN CurP = CurP + 1
CASE CHR$(0) + "G": CurP = 0
CASE CHR$(0) + "O": CurP = LEN(Rslt$)
CASE CHR$(0) + "S": IF CurP - CurS THEN Rslt$ = DELETE(Rslt$, CurS, CurP - CurS): IF CurS < CurP THEN CurP = CurS ELSE  ELSE Rslt$ = DELETE$(Rslt$, CurP, 1)
CASE CHR$(0) + "s": Lttr = 0
 FOR Srch = CurP TO 1 STEP -1
  IF INSTR(" ÿ()/\.	", MID$(Rslt$, Srch, 1)) = 0 THEN Lttr = -1 ELSE IF Lttr THEN CurP = Srch: EXIT FOR
 NEXT Srch: IF Srch = 0 THEN CurP = 0
CASE CHR$(0) + "t": Lttr = 0
 FOR Srch = CurP + 1 TO LEN(Rslt$)
  IF INSTR(" ÿ()/\.	", MID$(Rslt$, Srch, 1)) THEN Lttr = -1 ELSE IF Lttr THEN CurP = Srch - 1: EXIT FOR
 NEXT Srch: IF Srch = LEN(Rslt$) + 1 THEN CurP = LEN(Rslt$)
CASE "": Rslt$ = DELETE$(Rslt$, CurP, -1): CurP = CurP - 1
CASE ELSE: Keys$ = kbrd$: EXIT DO
END SELECT
IF Chng > 2 THEN GOSUB StrPromptShow: Chng = Chng AND 2
LOOP

LOCATE , , 0
EXIT SUB

StrPromptShow:
 IF CurP < 0 THEN CurP = 0 ELSE IF CurP > LEN(Rslt$) THEN CurP = LEN(Rslt$)
 IF CurP < RsCr THEN RsCr = CurP ELSE IF CurP > RsCr + Leng THEN RsCr = CurP - Leng
 IF Leng - (LEN(Rslt$) - RsCr) >= 0 THEN Tail$ = SPACE$(Leng - (LEN(Rslt$) - RsCr)) ELSE Tail$ = ""
 PRINTROW Vrow, Lcol, MID$(Rslt$, RsCr + 1, Leng) + Tail$
 IF CurP >= RsCr AND CurP < RsCr + Leng THEN LOCATE Vrow, Lcol + (CurP - RsCr), 1 ELSE LOCATE Vrow, , 0
 IF Shft = 0 THEN CurS = CurP
 IF LIMIT(LIMIT(CurP, CurS, 0) - RsCr, 0, 1) THEN HIGHLIGHT Lcol, Lcol + LIMIT(LIMIT(CurP, CurS, 0) - RsCr, 0, 1) - 1, Vrow, Colr
 IF CurP - CurS THEN HIGHLIGHT Lcol + LIMIT(LIMIT(CurP, CurS, 0) - RsCr, 0, 1), Lcol + LIMIT((LIMIT(CurP, CurS, 1) - RsCr), Leng, 0) - 1, Vrow, BClr
 IF Leng - 1 <> LIMIT((LIMIT(CurP, CurS, 1) - RsCr), Leng, 0) - 1 THEN HIGHLIGHT Lcol + LIMIT((LIMIT(CurP, CurS, 1) - RsCr), Leng, 0), Lcol + Leng - 1, Vrow, Colr
RETURN
StrPromptInsert:
 Rslt$ = DELETE(Rslt$, CurS, CurP - CurS): IF CurS < CurP THEN CurP = CurS
 IF LEN(Rslt$) + LEN(kbrd$) > RcLn THEN SOUND 860, .1: RETURN
 IF CurP >= 0 AND CurP <= LEN(Rslt$) THEN Rslt$ = LEFT$(Rslt$, CurP) + kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - CurP): Shft = 0
 CurP = CurP + LEN(kbrd$)
RETURN
END SUB

SUB TEXTWRAP (Hite, Wdth, Urow, Lcol, Fore, Back, Text$)
COLOR Fore, Back
FOR Vset = 0 TO INT((LEN(Text$) - 1) / Wdth)
 LOCATE Urow + Vset, 1 + Lcol: PRINT MID$(Text$, Vset * Wdth + 1, Wdth)
NEXT Vset
END SUB

