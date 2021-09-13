DEFINT A-Z
DECLARE FUNCTION NUMPROMPT& (limit, Result$)
DECLARE FUNCTION STRPROMPT2$ (Leng, RcLn, PreT$, Keys$, Colr, BClr, CurP, CurS)
DECLARE FUNCTION DELETE$ (Text$, ST, Lg)
DECLARE FUNCTION TRUNC& (Nmbr1&, Nmbr2&, Lrgr)
DECLARE FUNCTION TRUNK% (Nmbr1, Nmbr2, Lrgr)
DECLARE FUNCTION MEMSEARCH& (Text$, Start&, Endig&)
DECLARE SUB WORD (Hlin, Lcol, Text$)
DECLARE SUB PRINTROW (Urow, Lcol, Text$)
DECLARE SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
CONST Max& = 1048575, Wdth = 80

'DIM FastShow(0 TO 19)
'DEF SEG = VARSEG(FastShow(0)): p = VARPTR(FastShow(0)): FOR I = 0 TO 36: READ J: POKE (p + I), J: NEXT I
''FastShow processor code
'DATA &h1E,&h06,&h55,&h89,&hE5,&h8B,&h5E,&h0A,&h8B,&h37,&h8B,&h5E,&h0C,&h8E
'DATA &h1F,&hB8,&h00,&hB8,&h8E,&hC0,&hBF,&h00,&h00,&hB9,&h80,&h07,&hFC,&hA4
'DATA &h47,&hE2,&hFC,&h5D,&h07,&h1F,&hCA,&h04,&h00

DIM SHARED FastShow$

OPEN "fastshow.com" FOR INPUT AS 1: CLOSE 1
OPEN "fastshow.com" FOR BINARY AS 1
FastShow$ = INPUT$(LOF(1), 1)
CLOSE 1

IF LEN(FastShow$) = 0 THEN
  PRINT "What happened to 'fastshow.com'...it is needed for this program to work."
  KILL "fastshow.com"
  END
END IF

SCREEN 0: WIDTH Wdth, 25: LOCATE , , 0
COLOR 15, 0: CLS : LOCATE 1, 1: PRINT SPACE$(1920);
COLOR 0, 3: LOCATE 25, 1: PRINT SPACE$(80); : COLOR , 7
WORD 25, 19, "_Memory Range"
WORD 25, 51, "Hex"
WORD 25, 62, "Segment"

Chng = 1

DO

Pk& = Ofset& \ 16
p2 = Ofset& AND 15

IF Chng THEN
 Chng = 0
 COLOR 0, 3
 LOCATE 25, 31: PRINT STR$(Ofset&) + " -" + STR$(Ofset& + 1023); TAB(50);
 LOCATE , 55: PRINT LEFT$(HEX$(Ofset&) + "    ", 5);
 LOCATE , 69: PRINT LEFT$(STR$(Pk&) + SPACE$(4), 6); TAB(76); LEFT$(HEX$(Pk&) + "   ", 4);
END IF

DEF SEG = VARSEG(FastShow$)
CALL ABSOLUTE(Ofset&, SADD(FastShow$))

Chng = 1
SELECT CASE INP(96)
CASE 72: Ofset& = TRUNC(Ofset& - Wdth, 0, 1)
CASE 80: Ofset& = TRUNC(Ofset& + Wdth, Max&, 0)
CASE 73: Ofset& = TRUNC(Ofset& - 1920, 0, 1)
CASE 81: Ofset& = TRUNC(Ofset& + 1920, Max&, 0)
CASE 71: Ofset& = 0
CASE 79: Ofset& = Max&
CASE 75: Ofset& = TRUNC(Ofset& - 1, 0, 1)
CASE 77: Ofset& = TRUNC(Ofset& + 1, Max&, 0)
CASE 82: Ofset& = INT(Ofset& / Wdth) * Wdth
CASE ELSE: Chng = 0
END SELECT

DO: kbrd$ = INKEY$: LOOP WHILE kbyd$ > ""

IF kbrd$ > "" AND LEN(kbrd$) < 2 THEN
 SELECT CASE UCASE$(kbrd$)
 CASE "": SYSTEM
 CASE "-": Ofset& = TRUNC(Ofset& - Wdth, 0, 1)
 CASE "+": Ofset& = TRUNC(Ofset& + Wdth, Max&, 0)
 CASE "*": IF Ofset& < 983040 THEN Ofset& = Ofset& - (Ofset& MOD 65536) + 65536
 CASE "/": IF Ofset& > 0 THEN Ofset& = (Ofset& - 1) - ((Ofset& - 1) MOD 65536)
 CASE "C": DEF SEG = Pk&: LOCATE 1, 1: Byte$ = STRPROMPT2$(1, 1, CHR$(PEEK(p2)), Keys$, 127, 7, 0, 0): IF Keys$ = CHR$(13) AND Byte$ > "" THEN DEF SEG = Pk&: POKE p2, ASC(Byte$): Chng = 1
 CASE "D":    _
'LOCATE 2, 48: CmndText$ = STRPROMPT2$(24, 128, CmndText$, Keys$, 127, 7, 0, 0): IF Keys$ = CHR$(13) THEN PCOPY 0, 1: CLS : SHELL CmndText$: LOCATE 25, 1: PRINT "Press any key to return to Memory Viewer..."; : WHILE INKEY$ = "": WEND: PCOPY 0, 2: PCOPY 1,
 CASE "O": SCREEN , , , 2: WHILE INKEY$ = "": WEND: SCREEN , , , 0
 CASE "": DEF SEG = Pk&: CALL ABSOLUTE(p2)
 CASE "S", "F":
  IF kbrd$ = "F" THEN DoSearch = 1 ELSE LOCATE 1, 1: SrchText$ = STRPROMPT2$(24, 128, SrchText$, Keys$, 127, 7, 0, 0): Chng = 1: IF Keys$ = CHR$(13) THEN DoSearch = 1 ELSE DoSearch = 0
  IF DoSearch THEN DEF SEG = Pk&: TempOf& = MEMSEARCH(SrchText$, 0, 65535): IF TempOf& > 0 THEN Ofset& = (Pk& * 16) + TempOf&: Chng = 1 ELSE SOUND 256, 1
 CASE "0" TO "9", "M"
  LOCATE 25, 32: COLOR 15, 3: PRINT SPACE$(18); : IF UCASE$(kbrd$) = "M" THEN kbrd$ = ""
  LOCATE 25, 32: Ofset2& = TRUNC(NUMPROMPT(7, kbrd$), 1048575, 0): IF Ofset2& > -1 THEN Ofset& = Ofset2&
 END SELECT
 Chng = 1
END IF
LOOP

DEFSNG A-Z
FUNCTION DELETE$ (Text$, ST%, Lg%) : DELETE$ = LEFT$(Text$, TRUNK(ST% - 1 + TRUNK(Lg%, 0, 0), 0, 1)) + RIGHT$(Text$, TRUNK(LEN(Text$) - (ST% + TRUNK(Lg%, 0, 1)) + 1, 0, 1)): END FUNCTION

DEFINT A-Z
SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
DEF SEG = &HB800: Urow = Hset - 1
FOR Show = Lcol - 1 TO Rcol - 1 STEP SGN(Rcol - Lcol) OR 1
 POKE (Urow * 80 + Show) * 2 + 1, Colr
NEXT Show
END SUB

DEFLNG A-Z
FUNCTION MEMSEARCH (Text$, Start, Endig)
IF Text$ = "" THEN MEMSEARCH = -1: EXIT FUNCTION
FirstChar% = ASC(LEFT$(Text$, 1)): Mtch% = -1
FOR SG& = Start& TO Endig& - LEN(Text$)
 IF PEEK(SG&) = FirstChar% THEN
  FOR SG2 = 1 TO LEN(Text$) - 1
   IF PEEK(SG& + SG2) <> ASC(MID$(Text$, SG2 + 1, 1)) THEN Mtch = 0: EXIT FOR
  NEXT SG2
  IF Mtch THEN MEMSEARCH = SG&: EXIT FUNCTION ELSE Mtch = -1
 END IF
NEXT SG&
MEMSEARCH = -1
END FUNCTION

DEFINT A-Z
FUNCTION NUMPROMPT& (limit, Preslt$)
Rslt$ = Preslt$
Urow = CSRLIN
Lcol = POS(0)
Chng = -1

DO UNTIL Done
IF Chng THEN
LOCATE Urow, Lcol, 0
PRINT Rslt$; CHR$(95); " ";
Chng = 0
END IF

kbrd$ = INKEY$
SELECT CASE kbrd$
CASE "0" TO "9"
 IF LEN(Rslt$) < limit THEN Rslt$ = Rslt$ + kbrd$
 Chng = -1
CASE CHR$(13)
 Done = -1
CASE CHR$(8)
 IF Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, LEN(Rslt$) - 1)
 Chng = -1
CASE CHR$(27)
 NUMPROMPT = -1
 EXIT FUNCTION
CASE ELSE
 IF LEN(kbrd$) = 2 THEN NUMPROMPT = -1: EXIT FUNCTION
END SELECT
LOOP

LOCATE Urow, Lcol
PRINT Rslt$; " ";
NUMPROMPT = VAL(Rslt$)
END FUNCTION

SUB PRINTROW (Urow, Lcol, Text$)
Vset = (Urow - 1) * 80 + (Lcol - 2)
DEF SEG = &HB800
FOR Show = 1 TO LEN(Text$)
 POKE (Vset + Show) * 2, ASC(MID$(Text$, Show, 1))
NEXT Show
END SUB

FUNCTION STRPROMPT2$ (Leng, RcLn, PreT$, Keys$, Colr, BClr, CurP, CurS)
DEF SEG = 0: POKE (1047), 128
Vlin = CSRLIN: Lcol = POS(0): Rslt$ = PreT$
IF CurP = 0 THEN CurP = LEN(Rslt$) + 1
IF CurS = 0 THEN CurS = 1
IF RsCr = 0 THEN RsCr = 1
IF CurP - CurS THEN Shft = -1
GOSUB RedrawPrompt

DO
DEF SEG = 0: Nsrt = PEEK(1047) AND 128 XOR 128: Shft = PEEK(1047) AND 3
IF Nsrt THEN LOCATE , , , 3, 6 ELSE LOCATE , , , 5, 6
Chng = -1: IF Done THEN kbrd$ = Keys$ ELSE kbrd$ = INKEY$
SELECT CASE kbrd$
CASE "": Chng = 0
CASE " " TO "ÿ": GOSUB Insert: IF Done THEN CurS = CurP: Keys$ = ""
CASE CHR$(0) + "K": IF CurP > 1 THEN CurP = CurP - 1
CASE CHR$(0) + "M": IF CurP < LEN(Rslt$) + 1 THEN CurP = CurP + 1
CASE CHR$(0) + "O": CurP = LEN(Rslt$) + 1
CASE CHR$(0) + "G": CurP = 1
CASE CHR$(0) + "S": IF Shft THEN Keys$ = MID$(Rslt$, TRUNK(CurP, CurS, 0), TRUNK(CurP, CurS, 1) - TRUNK(CurP, CurS, 0)): Done = -1
 IF CurP - CurS THEN Rslt$ = DELETE(Rslt$, TRUNK(CurP, CurS, 0), TRUNK(CurP, CurS, 1) - TRUNK(CurP, CurS, 0)): CurP = TRUNK(CurP, CurS, 0): CurS = CurP ELSE Rslt$ = DELETE$(Rslt$, CurP, 1)
CASE CHR$(0) + "R": IF Shft THEN Keys$ = kbrd$: POKE 1047, PEEK(1047) XOR 128: Done = -1 ELSE Shft = -1
CASE ELSE
 IF (Nsrt OR Done) AND LEN(kbrd$) < 2 THEN
  GOSUB Insert
 ELSE
  SELECT CASE kbrd$
  CASE CHR$(8): Rslt$ = DELETE$(Rslt$, CurP - 1, 1): CurP = CurP - 1
  CASE CHR$(27): IF CurP - CurS THEN CurS = CurP ELSE Rslt$ = PreT$: Keys$ = kbrd$: Done = -1
  CASE ELSE: Done = -1: Shft = -1: Keys$ = kbrd$
  END SELECT
 END IF
END SELECT
IF Chng THEN GOSUB RedrawPrompt
LOOP UNTIL Done
STRPROMPT2$ = Rslt$
LOCATE , , 0
EXIT FUNCTION
RedrawPrompt:
 IF CurP < 1 THEN CurP = 1 ELSE IF CurP > LEN(Rslt$) + 1 THEN CurP = LEN(Rslt$) + 1
 IF CurP < RsCr THEN RsCr = CurP ELSE IF CurP > RsCr + Leng THEN RsCr = CurP - Leng
 IF Leng - (LEN(Rslt$) - RsCr) > 0 THEN Tail$ = SPACE$(Leng - (LEN(Rslt$) - RsCr) - 1)
 PRINTROW Vlin, Lcol, MID$(Rslt$, RsCr, Leng) + Tail$
 IF CurP >= RsCr AND CurP < RsCr + Leng + 1 THEN LOCATE Vlin, Lcol + (CurP - RsCr), 1 ELSE LOCATE Vlin, , 0
 IF Shft = 0 THEN CurS = CurP
 IF TRUNK(TRUNK(CurP, CurS, 0) - RsCr, 0, 1) THEN HIGHLIGHT Lcol, Lcol + TRUNK(TRUNK(CurP, CurS, 0) - RsCr, 0, 1) - 1, Vlin, Colr
 IF CurP - CurS THEN HIGHLIGHT Lcol + TRUNK(TRUNK(CurP, CurS, 0) - RsCr, 0, 1), Lcol + TRUNK((TRUNK(CurP, CurS, 1) - RsCr), Leng, 0) - 1, Vlin, BClr
 IF Leng - 1 <> TRUNK((TRUNK(CurP, CurS, 1) - RsCr), Leng, 0) - 1 THEN HIGHLIGHT Lcol + TRUNK((TRUNK(CurP, CurS, 1) - RsCr), Leng, 0), Lcol + Leng - 1, Vlin, Colr
 Chng = 0
RETURN
Insert:
 IF CurP - CurS THEN Rslt$ = DELETE(Rslt$, TRUNK(CurP, CurS, 0), TRUNK(CurP, CurS, 1) - TRUNK(CurP, CurS, 0)): CurP = TRUNK(CurP, CurS, 0)
 IF LEN(Rslt$) + LEN(kbrd$) > RcLn THEN SOUND 860, .1: RETURN
 IF CurP < 0 OR CurP > LEN(Rslt$) + 1 THEN  ELSE Rslt$ = LEFT$(Rslt$, CurP - 1) + kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - CurP + 1): Shft = 0
 CurP = CurP + LEN(kbrd$)
RETURN
END FUNCTION

DEFLNG A-Z
FUNCTION TRUNC (Nmbr1, Nmbr2, Lrgr%)
IF Lrgr% THEN
 IF Nmbr1 > Nmbr2 THEN TRUNC = Nmbr1 ELSE TRUNC = Nmbr2
ELSE
 IF Nmbr1 < Nmbr2 THEN TRUNC = Nmbr1 ELSE TRUNC = Nmbr2
END IF
END FUNCTION

DEFINT A-Z
FUNCTION TRUNK (Nmbr1, Nmbr2, Lrgr%)
IF Lrgr% THEN
 IF Nmbr1 > Nmbr2 THEN TRUNK = Nmbr1 ELSE TRUNK = Nmbr2
ELSE
 IF Nmbr1 < Nmbr2 THEN TRUNK = Nmbr1 ELSE TRUNK = Nmbr2
END IF
END FUNCTION

DEFSNG A-Z
SUB WORD (Hlin%, Lcol%, Text$)
LOCATE Hlin%, Lcol%
FOR Show% = 1 TO LEN(Text$)
 IF MID$(Text$, Show%, 1) = "_" THEN COLOR 15: Show% = Show% + 1 ELSE COLOR 0
 PRINT MID$(Text$, Show%, 1);
NEXT Show%
END SUB

