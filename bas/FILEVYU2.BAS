DEFINT A-Z
DECLARE SUB PRINTROW (Urow, Lcol, Text$)
DECLARE SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
DECLARE SUB TEXTWRAP (TexH, Wrap, Ulin, Lcol, Fore, Back, Text$)
DECLARE SUB SCALE (Frct&, Totl&, Lcol, Rcol, Urow)
DECLARE SUB DRAWBUTTON (Lcol, Rcol, Ulin, Dlin, Fore, Back, Sfor)
DECLARE SUB INTRO ()
DECLARE FUNCTION DOSPATH$ ()
DECLARE FUNCTION LIMIT (Nmbr1, Nmbr2, Mode)
DECLARE FUNCTION STRPROMPT$ (Leng, RcLn, Rslt$, Kbrd$, Colr, BClr, CurP, CurS)
DECLARE FUNCTION DELETE$ (Text$, Strt, Leng)
DIM UP(1 TO 7): DIM files$(16)
DEF SEG = VARSEG(UP(1)): FOR Rd = 0 TO 13: READ J: POKE (VARPTR(UP(1)) + Rd), J: NEXT Rd: Rd = 0
DATA &HB8,&H01,&H06,&HB9,&H00,&H03,&HBA,&H50,&H17,&HB7,&H30,&HCD,&H10,&HCB
PCOPY 0, 2: WIDTH 80: DosR = CSRLIN: DosC = POS(0): VIEW PRINT: COLOR 15, 3: CLS : LOCATE , , 0
DRAWBUTTON 3, 66, 2, 2, 0, 7, 8: DRAWBUTTON 69, 78, 2, 2, 0, 7, 8: INTRO: Clrs = 0

Prompt:
DO: Done = 0
 DEF SEG = 0: LOCATE 1, 3: COLOR 15, 3: PRINT LEFT$(DOSPATH + SPACE$(64), 64)
 Keys$ = "": LOCATE 2, 3: file$ = STRPROMPT$(64, 128, file$, Keys$, 112, 7, CurP, CurS)
 WHILE INKEY$ > "": WEND
 SELECT CASE Keys$
 CASE "":
 CASE "": PCOPY 0, 1: PCOPY 2, 0: LOCATE DosR, DosC: SYSTEM
 CASE CHR$(13): Done = 1
 CASE CHR$(10): Done = 2
 CASE CHR$(9): PCOPY 0, 1: PCOPY 2, 0: LOCATE DosR, DosC: WHILE INKEY$ = "": WEND: PCOPY 1, 0
 CASE CHR$(0) + ";": IF Clrs <> 1 THEN DRAWBUTTON 26, 55, 7, 20, 0, 7, 8: TEXTWRAP 11, 30, 7, 25, 0, 7, "þNormal Prompt Editing Keys:  ùHOME, END, DEL, BKSP, , ,  ùINSúInsert special charactersùSHIFT+( )úHighlight text   " + SPACE$(30) + "þSpecial Function Keys:       ùENTERúView file in prompt or  change path to directory     ùCtrl+ENTERúShell text to DOS  command prompt (DIR, COPY,.) ù{, }úRecall prior entries  ùTABúShow shell subscreen     ùF2úShow File View 2 Credits  ùF3úShow opening screen (CLS)": WHILE INKEY$ > "": WEND: Clrs = 1
 CASE CHR$(0) + "<": IF Clrs <> 2 THEN DRAWBUTTON 29, 52, 11, 15, 0, 7, 8: TEXTWRAP 5, 24, 11, 28, 15, 7, "     File Viewer 2        Version 2.0, 3-1996     Programmer Credits:    Dwayne Robinson Demmer  No copyright or patent": Clrs = 2
 CASE CHR$(0) + "=": IF Clrs <> 3 THEN INTRO: WHILE INKEY$ > "": WEND: Clrs = 3
 CASE CHR$(0) + "H": Rcl = LIMIT(16, Rcl + 1, 0): GOSUB Recall
 CASE CHR$(0) + "P": Rcl = LIMIT(0, Rcl - 1, 1): GOSUB Recall
 CASE ELSE
 END SELECT
LOOP UNTIL Done
LOCATE , , 0: Rcl = 0: CurP = LEN(file$): CurS = 0: Clrs = 0
IF file$ <> files$(1) AND file$ > "" THEN FOR Move = 16 TO 1 STEP -1: files$(Move) = files$(Move - 1): NEXT Move: files$(1) = file$
IF Done = 1 THEN GOSUB Opener ELSE IF Done = 2 THEN GOSUB Doshell
GOTO Prompt

Recall:
 IF files$(Rcl) > "" THEN file$ = files$(Rcl) ELSE IF Rcl > 0 THEN Rcl = Rcl - 1: IF Rcl <> 0 THEN file$ = files$(Rcl)
 IF Rcl = 0 THEN file$ = ""
 CurP = LEN(file$): CurS = CurP
RETURN

Opener:
file$ = LTRIM$(file$): IF file$ = "" THEN RETURN ELSE CLOSE #1
ON ERROR GOTO DirErrHan: DrEr = 0: CHDIR file$: IF NOT DrEr THEN RETURN
ON ERROR GOTO FilErrHan: OPEN file$ FOR INPUT AS #1: CLOSE #1: OPEN file$ FOR BINARY ACCESS READ AS 1: Flen& = LOF(1)
COLOR 0, 3: LOCATE 25, 1: PRINT STR$(Flen&) + " Bytes"; TAB(17); : VIEW PRINT 4 TO 24: CLS 2
Byte$ = SPACE$(80): COLOR 10, 7
FOR ShowFile& = 1 TO Flen& STEP 80
 GET 1, ShowFile&, Byte$
 DEF SEG = &HB8E6
 IF Flen& - ShowFile& < 80 THEN
  FOR Show = 0 TO Flen& - ShowFile&
   POKE Show * 2, ASC(MID$(Byte$, Show + 1, 1)): POKE Show * 2 + 1, 15
  NEXT Show
 ELSE
  FOR Show = 0 TO LEN(Byte$) - 1
   POKE Show * 2, ASC(MID$(Byte$, Show + 1, 1)): POKE Show * 2 + 1, 15
  NEXT Show
  DEF SEG = VARSEG(UP(1)): CALL ABSOLUTE(VARPTR(UP(1))): SCALE ShowFile&, Flen&, 17, 80, 25
 END IF
 IF INKEY$ = "" THEN EXIT FOR
NEXT ShowFile&
SCALE 0, 0, 17, 80, 25
VIEW PRINT 1 TO 25: CLOSE #1
RETURN

Doshell:
PCOPY 0, 1: PCOPY 2, 0: LOCATE DosR, DosC
IF file$ = "" THEN COLOR 7, 0: PRINT CHR$(13); "When done, you can return to FV2 by typing 'EXIT' at the prompt"
SHELL file$
IF file$ > "" THEN COLOR 7, 0: PRINT "Press any key to return to FV2..": WHILE INKEY$ = "": WEND
PCOPY 0, 2: PCOPY 1, 0: DosR = CSRLIN: DosC = POS(0)
RETURN

DirErrHan: DrEr = -1: RESUME NEXT
FilErrHan:
PCOPY 0, 1
SELECT CASE ERR
CASE 6: ErTx$ = "      Avalanche, Too Much to load       This file has more byte postions than this program can access."
CASE 53: ErTx$ = "        Sorry can not find it          You might have spelled the filename   wrong or typed in a file that does    not exist. If it does exist, shell    'DIR /S'+ filename to search for it."
CASE 64: ErTx$ = "   Get out your instruction manual!    Now this is different than just spel- ling a name wrong. You totally goofed it up. These are reserved characters: / \ < > [ ] . , : ; ? * + | = " + CHR$(34) + "  "
CASE 68: ErTx$ = "  Sorry, that device is unavailable"
CASE 71, 75: ErTx$ = "  Can not access that device or path"
CASE 76: ErTx$ = "If you were my guide, I would be lost! This path does not exist or maybe you are mixed up with another road. Type  'DIR /AD' and press Ctrl+ENTER for a  listing of real directories."
CASE ELSE: ErTx$ = "          Unknown Error !             For your computer's sake this program will self-terminate. Refer this bleep to the programmer, error number:" + STR$(ERR): UnEr = -1
END SELECT
DRAWBUTTON 22, 59, 6, 10, 0, 7, 8
TEXTWRAP 10, 38, 6, 21, 0, 7, ErTx$
WHILE INKEY$ = "": WEND: PCOPY 1, 0
IF UnEr THEN LOCATE 25, 1: SYSTEM
RESUME Prompt

FUNCTION DELETE$ (Text$, St, Lg)
IF SGN(Lg) = -1 THEN Lt = St + Lg: Rt = LEN(Text$) - St ELSE Lt = St: Rt = LEN(Text$) - (St + Lg)
IF Lt > LEN(Text$) THEN Lt = LEN(Text$) ELSE IF Lt < 0 THEN Lt = 0
IF Rt > LEN(Text$) THEN Rt = LEN(Text$) ELSE IF Rt < 0 THEN Rt = 0
DELETE$ = LEFT$(Text$, Lt) + RIGHT$(Text$, Rt)
END FUNCTION

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

SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
DEF SEG = &HB800: Urow = Hset - 1: Prow = Urow * 160 + 1
FOR Show = Lcol - 1 TO Rcol - 1 STEP SGN(Rcol - Lcol) OR 1
 POKE Prow + (Show * 2), Colr
NEXT Show
END SUB

DEFSNG A-Z
SUB INTRO
LOCATE , , 0
VIEW PRINT 4 TO 24: COLOR 0, 3: CLS : VIEW PRINT
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

FUNCTION STRPROMPT$ (Leng, RcLn, Prst$, Keys$, Colr, BClr, CurP, CurS)
Vlin = CSRLIN: Lcol = POS(0): Rslt$ = Prst$
Shft = -1: GOSUB StrPromptShow

DO
DEF SEG = 0: Nsrt = PEEK(1047) AND 128 XOR 128: Shft = PEEK(1047) AND 3
IF Nsrt THEN LOCATE , , , 3, 6 ELSE LOCATE , , , 5, 6
Chng = -1: Kbrd$ = INKEY$
SELECT CASE Kbrd$
CASE "": Chng = 0
CASE " " TO "ÿ": GOSUB StrPromptInsert: IF Done THEN CurS = CurP: Keys$ = ""
CASE CHR$(0) + "K": IF CurP > 0 THEN CurP = CurP - 1
CASE CHR$(0) + "M": IF CurP < LEN(Rslt$) THEN CurP = CurP + 1
CASE CHR$(0) + "G": CurP = 0
CASE CHR$(0) + "O": CurP = LEN(Rslt$)
CASE CHR$(0) + "S": IF CurP - CurS THEN Rslt$ = DELETE(Rslt$, CurS, CurP - CurS): IF CurS < CurP THEN CurP = CurS ELSE  ELSE Rslt$ = DELETE$(Rslt$, CurP, 1)
CASE CHR$(0) + "R": IF Shft THEN Keys$ = Kbrd$: POKE 1047, PEEK(1047) XOR 128: Done = -1 ELSE Shft = -1
CASE CHR$(0) + "s": Lttr = 0
 FOR Srch = CurP TO 1 STEP -1
  IF INSTR(" ÿ()/\.	", MID$(Rslt$, Srch, 1)) = 0 THEN Lttr = -1 ELSE IF Lttr THEN CurP = Srch: EXIT FOR
 NEXT Srch: IF Srch = 0 THEN CurP = 0
CASE CHR$(0) + "t": Lttr = 0
 FOR Srch = CurP + 1 TO LEN(Rslt$)
  IF INSTR(" ÿ()/\.	", MID$(Rslt$, Srch, 1)) THEN Lttr = -1 ELSE IF Lttr THEN CurP = Srch - 1: EXIT FOR
 NEXT Srch: IF Srch = LEN(Rslt$) + 1 THEN CurP = LEN(Rslt$)
CASE ELSE
 IF (Nsrt OR Done) AND LEN(Kbrd$) < 2 THEN
  GOSUB StrPromptInsert
 ELSE
  SELECT CASE Kbrd$
  CASE CHR$(8): Rslt$ = DELETE$(Rslt$, CurP, -1): CurP = CurP - 1
  CASE ELSE: Chng = -1: Done = -1: Keys$ = Kbrd$
  END SELECT
 END IF
END SELECT
IF Chng THEN GOSUB StrPromptShow: Chng = 0
LOOP UNTIL Done

LOCATE , , 0
STRPROMPT$ = Rslt$
EXIT FUNCTION
StrPromptShow:
 IF CurP < 0 THEN CurP = 0 ELSE IF CurP > LEN(Rslt$) THEN CurP = LEN(Rslt$)
 IF CurP < RsCr THEN RsCr = CurP ELSE IF CurP > RsCr + Leng THEN RsCr = CurP - Leng
 IF Leng - (LEN(Rslt$) - RsCr) >= 0 THEN Tail$ = SPACE$(Leng - (LEN(Rslt$) - RsCr)) ELSE Tail$ = ""
 PRINTROW Vlin, Lcol, MID$(Rslt$, RsCr + 1, Leng) + Tail$
 IF CurP >= RsCr AND CurP < RsCr + Leng THEN LOCATE Vlin, Lcol + (CurP - RsCr), 1 ELSE LOCATE Vlin, , 0
 IF Shft = 0 THEN CurS = CurP
 IF LIMIT(LIMIT(CurP, CurS, 0) - RsCr, 0, 1) THEN HIGHLIGHT Lcol, Lcol + LIMIT(LIMIT(CurP, CurS, 0) - RsCr, 0, 1) - 1, Vlin, Colr
 IF CurP - CurS THEN HIGHLIGHT Lcol + LIMIT(LIMIT(CurP, CurS, 0) - RsCr, 0, 1), Lcol + LIMIT((LIMIT(CurP, CurS, 1) - RsCr), Leng, 0) - 1, Vlin, BClr
 IF Leng - 1 <> LIMIT((LIMIT(CurP, CurS, 1) - RsCr), Leng, 0) - 1 THEN HIGHLIGHT Lcol + LIMIT((LIMIT(CurP, CurS, 1) - RsCr), Leng, 0), Lcol + Leng - 1, Vlin, Colr
RETURN
StrPromptInsert:
 Rslt$ = DELETE(Rslt$, CurS, CurP - CurS): IF CurS < CurP THEN CurP = CurS
 IF LEN(Rslt$) + LEN(Kbrd$) > RcLn THEN SOUND 860, .1: RETURN
 IF CurP >= 0 AND CurP <= LEN(Rslt$) THEN Rslt$ = LEFT$(Rslt$, CurP) + Kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - CurP): Shft = 0
 CurP = CurP + LEN(Kbrd$)
RETURN
END FUNCTION

SUB TEXTWRAP (Hite, Wdth, Urow, Lcol, Fore, Back, Text$)
COLOR Fore, Back
FOR Vset = 0 TO INT((LEN(Text$) - 1) / Wdth)
 LOCATE Urow + Vset, 1 + Lcol: PRINT MID$(Text$, Vset * Wdth + 1, Wdth)
NEXT Vset
END SUB

