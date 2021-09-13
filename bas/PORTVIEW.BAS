DEFINT A-Z
DECLARE FUNCTION NUMPROMPT& (limit%, Result$)
DECLARE FUNCTION STRPROMPT2$ (Leng%, RcLn%, PreT$, Keys$, Colr%, BClr%, CurP%, CurS%)
DECLARE FUNCTION DELETE$ (Text$, ST%, Lg%)
DECLARE FUNCTION TRUNC& (Nmbr1&, Nmbr2&, Mode%)
DECLARE FUNCTION TRUNK% (Nmbr1%, Nmbr2%, Lrgr%)
DECLARE FUNCTION PRTSEARCH& (Text$, Start&, Endig&)
DECLARE SUB WORD (Hlin%, Lcol%, Text$)
DECLARE SUB PRINTROW (Urow%, Lcol%, Text$)
DECLARE SUB HIGHLIGHT (Lcol%, Rcol%, Hset%, Colr%)
DECLARE SUB SCROLLBAR (AF1&, AF2&, AT1&, AT2&, Side1&, Side2&, Lin&, Mode&)
DECLARE SUB BOXDRAW5 (Urow%, Drow%, Lcol%, Rcol%, Fore%, Back%, Side%, Titl$)
CONST Max& = 65536 - 1024: Change = -1: PreOf& = -1: Prep2 = -1
DIM ScrollUp(1 TO 7): DIM ScrollDown(1 TO 7)
P = VARPTR(ScrollUp(1)): DEF SEG = VARSEG(ScrollUp(1)): FOR I = 0 TO 13: READ J: POKE (P + I), J: NEXT I
P = VARPTR(ScrollDown(1)): DEF SEG = VARSEG(ScrollDown(1)): FOR I = 0 TO 13: READ J: POKE (P + I), J: NEXT I
'                                 ?            ?  color
DATA &HB8,&H01,&H06,&HB9,&H08,&H05,&HBA,&H47,&H14,&HB7,&H0F,&HCD,&H10,&HCB
DATA &HB8,&H01,&H07,&HB9,&H08,&H05,&HBA,&H47,&H14,&HB7,&H0F,&HCD,&H10,&HCB
Start:
SCREEN 0: WIDTH 80, 25: COLOR 0, 3: CLS : LOCATE , , 0
COLOR , 7: LOCATE 2, 10: PRINT SPACE$(20): LOCATE 2, 52: PRINT SPACE$(20): LOCATE 2, 35: PRINT "      "
COLOR 15, 0: FOR Vset = 6 TO 21: LOCATE Vset, 9: PRINT SPACE$(64); : NEXT Vset
BOXDRAW5 1, 3, 8, 31, 10, 3, 255, "_Search String"
BOXDRAW5 1, 3, 33, 48, 10, 3, 255, "_Cursor"
BOXDRAW5 1, 3, 50, 73, 10, 3, 255, "_DOS Command Prompt"
BOXDRAW5 5, 22, 8, 73, 10, 3, 81, ""
WORD 24, 9, "_Refresh Window"
WORD 24, 25, "_Find Again"
WORD 24, 37, "Sh_ow Screen"
WORD 24, 50, "____ PgUp PgDn Home End"
WORD 4, 8, "_Port Range:"
WORD 4, 41, "Hex:"

DO UNTIL Kybd$ = ""
Byte = INP(ofset&): DEF SEG = &HB800: POKE 242, Byte: LOCATE 2, 44: COLOR 0, 3: PRINT RIGHT$(" " + STR$(Byte), 3)

IF Change THEN
 Pk& = INT(ofset& / 16)
 p2 = ofset& MOD 16
 LOCATE 4, 21: PRINT LEFT$(STR$(ofset&) + " -" + STR$(ofset& + 1023) + SPACE$(12), 18);
 LOCATE , 46: PRINT LEFT$(HEX$(ofset&) + "    ", 5);
 COLOR 15, 7
 IF p2 <> Prep2 THEN p3 = (ofset& MOD 64): SCROLLBAR (p3), (p3), 0, 63, 8, 73, 22, 0
 IF INT(ofset& / 4096) <> INT(PreOf& / 4096) THEN SCROLLBAR ofset&, ofset&, 0, 65535, 5, 22, 73, 1
IF ofset& - PreOf& = 64 THEN 'ScrollUp GoDown
 DEF SEG = VARSEG(ScrollUp(1)): CALL Absolute(VARPTR(ScrollUp(1)))
 Move = 960: DEF SEG = &HB8C8
 FOR Hset = 16 TO 142 STEP 2
  POKE Hset, INP(ofset& + Move): Move = Move + 1
 NEXT Hset
ELSEIF ofset& - PreOf& = -64 THEN 'ScrollDown GoUp
 DEF SEG = VARSEG(ScrollDown(1)): CALL Absolute(VARPTR(ScrollDown(1)))
 Move = 0: DEF SEG = &HB800
 FOR Hset = 816 TO 942 STEP 2
  POKE Hset, INP(ofset& + Move): Move = Move + 1
 NEXT Hset
ELSE
 IF PreOf& <> ofset& THEN
  Move = 0: DEF SEG = &HB800
  FOR Vset = 800 TO 3200 STEP 160: FOR Hset = 16 TO 142 STEP 2
   POKE Vset + Hset, INP(ofset& + Move): Move = Move + 1
  NEXT Hset, Vset
 END IF
END IF
Prep2 = p2: PreOf& = ofset&: Change = 0
END IF

Kybd$ = UCASE$(LEFT$(INKEY$, 1) + LEFT$(INKEY$, 1) + LEFT$(INKEY$, 1) + LEFT$(INKEY$, 1) + LEFT$(INKEY$, 1) + LEFT$(INKEY$, 1))
Change = -1
SELECT CASE INP(96)
CASE 72: ofset& = TRUNC(ofset& - 64, 0, 1)
CASE 80: ofset& = TRUNC(ofset& + 64, Max&, 0)
CASE 73: ofset& = TRUNC(ofset& - 1024, 0, 1)
CASE 81: ofset& = TRUNC(ofset& + 1024, Max&, 0)
CASE 71: ofset& = 0: CASE 79: ofset& = Max&
CASE 75: ofset& = TRUNC(ofset& - 1, 0, 1)
CASE 77: ofset& = TRUNC(ofset& + 1, Max&, 0)
CASE 82: ofset& = INT(ofset& / 64) * 64
CASE ELSE: Change = 0
END SELECT
IF Kybd$ > "" THEN
 IF Kybd$ = "-" THEN ofset& = TRUNC(ofset& - 64, 0, 1)
 IF Kybd$ = "+" THEN ofset& = TRUNC(ofset& + 64, Max&, 0)
 IF Kybd$ = "" THEN SYSTEM
 IF Kybd$ = "R" THEN PreOf& = -1
 IF Kybd$ = "C" THEN LOCATE 2, 35: Byte$ = STRPROMPT2$(6, 64, Byte$, Keys$, 127, 7, 0, 0): IF Keys$ = CHR$(13) THEN FOR Send = 1 TO LEN(Byte$): OUT ofset&, ASC(MID$(Byte$, Send, 1)): FOR d% = 1 TO 2000: NEXT d%: NEXT Send: PreOf& = -1
 IF Kybd$ = "D" THEN LOCATE 2, 52: CmndText$ = STRPROMPT2$(20, 128, CmndText$, Keys$, 127, 7, 0, 0): IF Keys$ = CHR$(13) THEN PCOPY 0, 1: CLS : SHELL CmndText$: LOCATE 25, 1: PRINT "Press any key to return to Memory Viewer..."; : WHILE INKEY$ = "": WEND: PCOPY 0, 2: PCOPY 1, 0: PreOf& = -1
 IF Kybd$ = "O" THEN SCREEN , , , 2: WHILE INKEY$ = "": WEND: SCREEN , , , 0
 IF Kybd$ = "S" OR Kybd$ = "F" THEN
  IF Kybd$ = "F" THEN DoSearch = 1 ELSE LOCATE 2, 10: SrchText$ = STRPROMPT2$(20, 128, SrchText$, Keys$, 127, 7, 0, 0): IF Keys$ = CHR$(13) THEN DoSearch = 1 ELSE DoSearch = 0
  IF DoSearch THEN PCOPY 0, 1: BOXDRAW5 12, 14, 34, 48, 10, 7, 0, " Searching.. ": TempOf& = PRTSEARCH(SrchText$, ofset&, 65535): PCOPY 1, 0: IF TempOf& > 0 THEN ofset& = TempOf&: PreOf& = -1: Prep2 = -1:  ELSE SOUND 256, 1
 END IF
 IF INSTR("0123456789", Kybd$) OR UCASE$(Kybd$) = "M" THEN
  LOCATE 4, 22: COLOR 15, 3: PRINT SPACE$(18): LOCATE 4, 22: IF UCASE$(Kybd$) = "M" THEN Kybd$ = ""
  Ofset2& = TRUNC(NUMPROMPT(7, Kybd$), Max&, 0): IF Ofset2& > -1 THEN ofset& = Ofset2&
 END IF
 Change = -1
END IF
DEF SEG = 0: IF PEEK(1047) AND 16 AND Change = 0 THEN Change = -1: PreOf& = -1
LOOP

SUB BOXDRAW5 (Urow, Drow, Lcol, Rcol, Fore, Back, Side, Titl$)
IF Urow > Drow THEN SWAP Urow, Drow
IF Lcol > Rcol THEN SWAP Lcol, Rcol

COLOR Fore, Back: BoxWidth = Rcol - Lcol + 1
IF Side AND 256 THEN FOR Vset = Urow + 1 TO Drow - 1: LOCATE Vset, Lcol + 1: PRINT SPACE$(BoxWidth - 2); : NEXT Vset
IF Side AND 1 THEN LOCATE Urow, Lcol: PRINT "Ú";
IF Side AND 2 THEN LOCATE Urow, Rcol: PRINT "¿";
IF Side AND 4 THEN LOCATE Drow, Lcol: PRINT "À";
IF Side AND 8 THEN LOCATE Drow, Rcol: PRINT "Ù";
IF Side AND 16 THEN FOR Vset = Urow + 1 TO Drow - 1: LOCATE Vset, Lcol: PRINT "³"; : NEXT Vset
IF Side AND 32 THEN FOR Vset = Urow + 1 TO Drow - 1: LOCATE Vset, Rcol: PRINT "³"; : NEXT Vset
IF Side AND 64 THEN LOCATE Urow, Lcol + 1: PRINT STRING$(BoxWidth - 2, "Ä");
IF Side AND 128 THEN LOCATE Drow, Lcol + 1: PRINT STRING$(BoxWidth - 2, "Ä");
'IF Side AND 64 THEN FOR Hset = Lcol + 1 TO Rcol - 1: LOCATE Urow, Hset: PRINT "Ä"; : NEXT Hset
'IF Side AND 128 THEN FOR Hset = Lcol + 1 TO Rcol - 1: LOCATE Drow, Hset: PRINT "Ä"; : NEXT Hset

FOR Srch% = 1 TO LEN(Titl$)
 IF MID$(Titl$, Srch%, 1) = "_" THEN Cnt% = Cnt% + 1
NEXT Srch%
COLOR , Back: WORD Urow, Lcol + (BoxWidth - LEN(MID$(Titl$, 1, BoxWidth)) + Cnt%) / 2, LEFT$(Titl$, BoxWidth)
END SUB

DEFSNG A-Z
FUNCTION DELETE$ (Text$, ST%, Lg%) : DELETE$ = LEFT$(Text$, TRUNK(ST% - 1 + TRUNK(Lg%, 0, 0), 0, 1)) + RIGHT$(Text$, TRUNK(LEN(Text$) - (ST% + TRUNK(Lg%, 0, 1)) + 1, 0, 1)): END FUNCTION

DEFINT A-Z
SUB HIGHLIGHT (Lcol, Rcol, Hset, Colr)
DEF SEG = &HB800: Urow = Hset - 1
FOR Show = Lcol - 1 TO Rcol - 1 STEP SGN(Rcol - Lcol) OR 1
 POKE (Urow * 80 + Show) * 2 + 1, Colr
NEXT Show
END SUB

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

Kbrd$ = INKEY$
SELECT CASE Kbrd$
CASE "0" TO "9"
 IF LEN(Rslt$) < limit THEN Rslt$ = Rslt$ + Kbrd$
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
 IF LEN(Kbrd$) = 2 THEN NUMPROMPT = -1: EXIT FUNCTION
END SELECT
LOOP

LOCATE Urow, Lcol
PRINT Rslt$; " ";
NUMPROMPT = VAL(Rslt$)
END FUNCTION

SUB PRINTROW (Urow, Lcol, Text$)
DEF SEG = &HB800: Vset = (Urow - 1) * 80 + (Lcol - 2)
FOR Show = 1 TO LEN(Text$)
 POKE (Vset + Show) * 2, ASC(MID$(Text$, Show, 1))
NEXT Show
END SUB

DEFLNG A-Z
FUNCTION PRTSEARCH (Text$, Start, Endig)
IF Text$ = "" THEN PRTSEARCH = -1: EXIT FUNCTION
StartChar% = ASC(LEFT$(Text$, 1))
FOR SG = Start TO Endig - LEN(Text$)
 IF INP(SG) = StartChar% THEN
  FOR SG2 = 0 TO LEN(Text$) - 1
   Text2$ = Text2$ + CHR$(INP(SG + SG2))
  NEXT SG2
  IF Text2$ = Text$ THEN PRTSEARCH = SG: EXIT FUNCTION ELSE Text2$ = ""
 END IF
NEXT SG
PRTSEARCH = -1
END FUNCTION

SUB SCROLLBAR (AF1, AF2, AT1, AT2, Side1, Side2, Lin, Mode)

TBL = ABS(Side2 - Side1 + SGN(Side2 - Side1)) - 2
ABL = ABS(AT1 - AT2 + SGN(AT1 - AT2))
 IF TBL < 1 OR ABL = 0 THEN EXIT SUB
TPL = TRUNC(ABS(AF2 - AF1 + SGN(AF2 - AF1)) * TBL / ABL, 1, 1)
TPO = INT((TRUNC((AF1), (AF2), 0) - AT1) * TBL / ABL)

RPO = TPO: RPL = TRUNC(TPL - TRUNC(TPO + TPL - TBL, 0, 1), 0, 1)
IF TPO < 0 THEN RPL = TRUNC(TPL + TPO, 0, 1): RPO = 0 ELSE IF TPO >= TBL THEN RPO = 0
Bar$ = STRING$(TBL, 176): MID$(Bar$, 1 + RPO, RPL) = STRING$(RPL, "Û")

IF Mode THEN
 LOCATE Side1, Lin: IF TPO < 0 THEN PRINT "";  ELSE PRINT "";
 LOCATE Side2, Lin: IF TPO + TPL > TBL THEN PRINT "";  ELSE PRINT "";
 FOR Vset = 1 TO TBL
  LOCATE Side1 + Vset, Lin
  PRINT MID$(Bar$, Vset, 1);
 NEXT Vset
ELSE
 LOCATE Lin, Side1: IF TPO < 0 THEN PRINT "®";  ELSE PRINT "";
 LOCATE Lin, Side2: IF TPO + TPL > TBL THEN PRINT "¯";  ELSE PRINT "";
 LOCATE Lin, TRUNC((Side1), (Side2), 0) + 1: PRINT Bar$;
END IF
END SUB

DEFINT A-Z
FUNCTION STRPROMPT2$ (Leng, RcLn, PreT$, Keys$, Colr, BClr, CurP, CurS)
DEF SEG = 0: POKE 1047, PEEK(1047) OR 128
'IF Keys$ > "" THEN Done = -1 ELSE Done = 0
Vlin = CSRLIN: Lcol = POS(0): Rslt$ = PreT$
IF CurP = 0 THEN CurP = LEN(Rslt$) + 1
IF CurS = 0 THEN CurS = 1
IF RsCr = 0 THEN RsCr = 1
IF CurP - CurS THEN Shft = -1
GOSUB RedrawPrompt

DO
DEF SEG = 0: Nsrt = PEEK(1047) AND 128 XOR 128: Shft = PEEK(1047) AND 3
IF Nsrt THEN LOCATE , , , 3, 6 ELSE LOCATE , , , 5, 6
Chng = -1: IF Done THEN Kbrd$ = Keys$ ELSE Kbrd$ = INKEY$
SELECT CASE Kbrd$
CASE "": Chng = 0
CASE " " TO "ÿ": GOSUB Insert: IF Done THEN CurS = CurP: Keys$ = ""
CASE CHR$(0) + "": Kbrd$ = CHR$(0): GOSUB Insert
CASE CHR$(0) + "K": IF CurP > 1 THEN CurP = CurP - 1
CASE CHR$(0) + "M": IF CurP < LEN(Rslt$) + 1 THEN CurP = CurP + 1
CASE CHR$(0) + "O": CurP = LEN(Rslt$) + 1
CASE CHR$(0) + "G": CurP = 1
CASE CHR$(0) + "S": IF Shft THEN Keys$ = MID$(Rslt$, TRUNK(CurP, CurS, 0), TRUNK(CurP, CurS, 1) - TRUNK(CurP, CurS, 0)): Done = -1
 IF CurP - CurS THEN Rslt$ = DELETE(Rslt$, TRUNK(CurP, CurS, 0), TRUNK(CurP, CurS, 1) - TRUNK(CurP, CurS, 0)): CurP = TRUNK(CurP, CurS, 0): CurS = CurP ELSE Rslt$ = DELETE$(Rslt$, CurP, 1)
CASE CHR$(0) + "R": IF Shft THEN Keys$ = Kbrd$: POKE 1047, PEEK(1047) XOR 128: Done = -1 ELSE Shft = -1
CASE ELSE
 IF (Nsrt OR Done) AND LEN(Kbrd$) < 2 THEN
  GOSUB Insert
 ELSE
  SELECT CASE Kbrd$
  CASE CHR$(8): Rslt$ = DELETE$(Rslt$, CurP - 1, 1): CurP = CurP - 1
  CASE CHR$(27): IF CurP - CurS THEN CurS = CurP ELSE Rslt$ = PreT$: Keys$ = Kbrd$: Done = -1
  CASE ELSE: Done = -1: Shft = -1: Keys$ = Kbrd$
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
 IF LEN(Rslt$) + LEN(Kbrd$) > RcLn THEN SOUND 860, .1: RETURN
 IF CurP < 0 OR CurP > LEN(Rslt$) + 1 THEN  ELSE Rslt$ = LEFT$(Rslt$, CurP - 1) + Kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - CurP + 1): Shft = 0
 CurP = CurP + LEN(Kbrd$)
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

