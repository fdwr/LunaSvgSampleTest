DEFINT A-Z
DECLARE SUB StrPrompt (Rslt$, KeyIn$, KeyOut$, Lim, Vis, Row, Col, Curp, Ofst, Nsrt, Done)
DECLARE SUB DefScroll (Scroll(), Row1, Row2, Col1, Col2, UpDn, Colr)
DECLARE SUB ScrolScrn (Scroll())
DECLARE SUB DoCommand (Cmnd$, Rspn$)
DECLARE SUB MainHelp (Help$)
DECLARE SUB GetWord (Whole$, Word, Part$)
DECLARE SUB BoardDot (VYpos, HXpos, OnOff)
DECLARE SUB BoardClr ()
DECLARE SUB CursorAdd (CurDir, Length, Rspn$)
DECLARE SUB CursorBak (Length, Rspn$)
DECLARE SUB CursorChg (Place, CurDir, Length, Rspn$)
DECLARE SUB CursorCon (Start, Endng)
DECLARE SUB CursorIns (Place, Rspn$)
DECLARE SUB CursorDel (Place, Rspn$)
DECLARE SUB CursorMov (CurDir AS ANY, VYdir, HXdir)
DECLARE SUB CursorUse ()
TYPE CursorInfo
VYpos AS INTEGER
HXpos AS INTEGER
VYdir AS INTEGER
HXdir AS INTEGER
END TYPE

SCREEN 9: CLS
CONST TRUE = -1, FALSE = 0
DIM SHARED Cursor$, CsrInfo AS CursorInfo, OrigVYpos, OrigHXpos

UserBoxesInitiate:
DIM SHARED FilErr, UserBoxUpdate, EditBoxUpdate
REDIM UserBoxScrollUp(0 TO 6), EditBoxScrollUp(0 TO 6), EditBoxScrollDn(0 TO 6)
DefScroll UserBoxScrollUp(), 0, 23, 0, 23, -1, 0
DefScroll EditBoxScrollUp(), 0, 24, 71, 79, -1, 0
DefScroll EditBoxScrollDn(), 0, 24, 71, 79, 1, 0
GOSUB ShowBoxBorder: OrigVYpos = 42: OrigHXpos = 44: CursorUse
COLOR 14: UserBoxText$ = "Simple Letter Maker 1.0ÿ": GOSUB UserBoxPrint
UserBoxText$ = "Just press F1 for helpÿ": GOSUB UserBoxPrint
GOSUB EditBoxShowAll: GOSUB UserBoxInfo

UserBoxInput:
UserBoxUpdate = 1
DO UNTIL UserIsDone
 IF UserBoxUpdate THEN COLOR 15: StrPrompt CurrCmnd$, kbrd$, "", 128, 24, UserBoxRow + 1, UserBoxCol + 1, UserBoxCurp, Ofst, Nsrt, 1: UserBoxUpdate = 0
 kbrd$ = INKEY$: GOSUB UserKeys
 IF LEN(kbrd$) = 1 THEN kbrd$ = UCASE$(kbrd$)
 SELECT CASE kbrd$
 CASE CHR$(13), CHR$(10)
  CommitLine = TRUE
  RealCmnd$ = CurrCmnd$
  UserBoxText$ = CurrCmnd$
  COLOR 9: GOSUB UserBoxPrint
  LineSkip = 0: GOSUB UserBoxGoDown
  IF kbrd$ = CHR$(13) THEN
   LastCmnd$ = CurrCmnd$
   CurrCmnd$ = ""
   UserBoxCurp = 0
  END IF
  UserBoxCol = 0
  UserBoxUpdate = TRUE
 CASE CHR$(0) + "H"
  CurrCmnd$ = LastCmnd$
  UserBoxCurp = LEN(CurrCmnd$)
  UserBoxUpdate = TRUE
 CASE CHR$(0) + "P"
  CurrCmnd$ = ""
  UserBoxCurp = 0
  Nsrt = FALSE
  UserBoxUpdate = TRUE
 CASE CHR$(0) + "<"
  Help$ = " Keys in prompt mode ÿEnter executes commandÿCtrl+Enter keeps commandÿEscape quits and exitsÿUp recalls last commandÿDown clears prompt textÿF1 for detailed helpÿF3 clears the windowÿTab switches modesÿÿ Commands ÿ"
  Help$ = Help$ + "GO dir [ñlength]ÿCHNG unit dir [ñlength]ÿBACK [+exp|`!`]ÿORIG [yrow|`?` [xcol]]ÿDRAWÿLENÿCON +start +endÿCHECK file$ÿSAVE file$ÿLOAD file$ÿNEWÿ"
  GOSUB UserBoxHelp
 CASE CHR$(9), CHR$(0) + ""
  UserBoxText$ = MID$(CurrCmnd$, 1 + Ofst)
  COLOR 7: GOSUB UserBoxPrint
  IF kbrd$ = CHR$(9) GOTO ShowBoxInput ELSE GOTO EditBoxInput
 CASE CHR$(27): UserIsDone = TRUE
 CASE ""
 CASE ELSE: UserBoxUpdate = 1
 END SELECT

 IF CommitLine THEN
  DoCommand RealCmnd$, Rspn$
  IF Rspn$ > "" THEN GOSUB UserBoxRspn: GOSUB UserBoxGoDown
  CommitLine = FALSE
 END IF
 IF EditBoxUpdate THEN GOSUB EditBoxShowAll: BoardClr: CursorUse: GOSUB UserBoxInfo: EditBoxUpdate = FALSE
LOOP
GOTO EndIt
UserBoxGoDown:
FOR GoDown = 0 TO LineSkip
 IF UserBoxRow >= 23 THEN ScrolScrn UserBoxScrollUp() ELSE UserBoxRow = UserBoxRow + 1
NEXT GoDown
RETURN
UserBoxPrint:
LOCATE UserBoxRow + 1, UserBoxCol + 1: PRINT LEFT$(UserBoxText$ + SPACE$(24), 24);
IF INSTR(UserBoxText$, "ÿ") THEN LineSkip = 0: GOSUB UserBoxGoDown
RETURN
UserBoxHelp:
 COLOR 10: LineSkip = 0: LastHelpPos = 0
 DO
  NextHelpPos = INSTR(LastHelpPos + 1, Help$, "ÿ"): IF NextHelpPos = 0 THEN EXIT DO
  UserBoxText$ = MID$(Help$, LastHelpPos + 1, NextHelpPos - LastHelpPos - 1)
  GOSUB UserBoxPrint: GOSUB UserBoxGoDown: LastHelpPos = NextHelpPos
 LOOP
 GOSUB UserBoxGoDown
 UserBoxUpdate = TRUE
 WHILE INKEY$ > "": WEND
RETURN
UserBoxInfo:
Part$ = "y =       x =      ": MID$(Part$, 4, 6) = STR$(CsrInfo.VYpos): MID$(Part$, 14, 6) = STR$(CsrInfo.HXpos)
COLOR 7: LOCATE 25, 1: PRINT Part$;
RETURN
UserBoxRspn:
IF Rspn$ > "" THEN UserBoxText$ = Rspn$ + "ÿ": Rspn$ = "": COLOR 12: GOSUB UserBoxPrint
RETURN

ShowBoxInput:
ShowBoxCursor = TRUE: GOSUB ShowBoxBorder: CursorUse
DO UNTIL UserIsDone
 kbrd$ = INKEY$: GOSUB UserKeys
 SELECT CASE kbrd$
 CASE CHR$(9), CHR$(0) + ""
  ShowBoxCursor = FALSE: GOSUB ShowBoxBorder
  IF kbrd$ = CHR$(9) GOTO EditBoxInput ELSE GOTO UserBoxInput
 CASE CHR$(0) + "H": CursorAdd 0, 1, Rspn$: CursorMov CsrInfo, -1, 0: EditBoxUpdate = TRUE
 CASE CHR$(0) + "M": CursorAdd 1, 1, Rspn$: CursorMov CsrInfo, 0, 1: EditBoxUpdate = TRUE
 CASE CHR$(0) + "P": CursorAdd 2, 1, Rspn$: CursorMov CsrInfo, 1, 0: EditBoxUpdate = TRUE
 CASE CHR$(0) + "K": CursorAdd 3, 1, Rspn$: CursorMov CsrInfo, 0, -1: EditBoxUpdate = TRUE
 CASE CHR$(0) + "<"
  Help$ = " Keys in Manual mode ÿArrow keys move cursorÿBackSpc erases last unitÿEnter redraws the letterÿEscape quits and exitsÿTab switches the modeÿ"
  GOSUB UserBoxHelp
 CASE CHR$(8): CursorBak 1, Rspn$: EditBoxPlc = LEN(Cursor$): GOSUB EditBoxCursor: BoardClr: CursorUse: GOSUB UserBoxInfo
 CASE CHR$(13): BoardClr: CursorUse: WHILE INKEY$ > "": WEND
 END SELECT
 IF EditBoxUpdate THEN EditBoxPlc = LEN(Cursor$) - 1: GOSUB EditBoxCursor: GOSUB UserBoxInfo: EditBoxUpdate = FALSE: IF EditBoxPlc - EditBoxOfs > 24 THEN EditBoxOfs = EditBoxPlc - 24: GOSUB EditBoxShowAll
 GOSUB UserBoxRspn
LOOP
GOTO EndIt
ShowBoxBorder:
IF ShowBoxCursor THEN ShowBoxColor = 15 ELSE ShowBoxColor = 7
LINE (192, 0)-(199, 349), ShowBoxColor, BF
LINE (552, 0)-(559, 349), ShowBoxColor, BF
LINE (200, 0)-(551, 6), ShowBoxColor, BF
LINE (200, 343)-(551, 349), ShowBoxColor, BF
RETURN

EditBoxInput:
IF EditBoxPlc > LEN(Cursor$) THEN EditBoxPlc = LEN(Cursor$)
IF EditBoxPlc >= 0 AND EditBoxOfs > EditBoxPlc THEN EditBoxOfs = EditBoxPlc: GOSUB EditBoxShowAll
EditBoxOn = TRUE: GOSUB EditBoxCursor
DO UNTIL UserIsDone
 kbrd$ = INKEY$: GOSUB UserKeys
 SELECT CASE kbrd$
 CASE CHR$(0) + "H"
  IF EditBoxPlc > 0 THEN
   EditBoxOn = FALSE: GOSUB EditBoxCursor
   IF EditBoxPlc <= EditBoxOfs THEN EditBoxOfs = EditBoxOfs - 1: ScrolScrn EditBoxScrollDn(): EditBoxRow = 1: GOSUB EditBoxPrint
   EditBoxPlc = EditBoxPlc - 1
  END IF
  EditBoxOn = TRUE: GOSUB EditBoxCursor
 CASE CHR$(0) + "P"
  IF EditBoxPlc < LEN(Cursor$) THEN
   EditBoxOn = FALSE: GOSUB EditBoxCursor
   IF EditBoxPlc - EditBoxOfs >= 24 THEN EditBoxOfs = EditBoxOfs + 1: ScrolScrn EditBoxScrollUp(): EditBoxRow = 25: GOSUB EditBoxPrint
   EditBoxPlc = EditBoxPlc + 1
  END IF
  EditBoxOn = TRUE: GOSUB EditBoxCursor
 CASE CHR$(0) + "I"
  IF EditBoxOfs > 0 THEN
   EditBoxOfs = EditBoxOfs - 25
   EditBoxPlc = EditBoxPlc - 25
   IF EditBoxOfs < 0 THEN EditBoxOfs = 0
   IF EditBoxPlc < 0 THEN EditBoxPlc = 0
   GOSUB EditBoxShowAll
  END IF
  EditBoxOn = TRUE: GOSUB EditBoxCursor
 CASE CHR$(0) + "Q"
  Part = LEN(Cursor$)
  IF EditBoxOfs + 25 < Part THEN
   EditBoxOfs = EditBoxOfs + 25
   EditBoxPlc = EditBoxPlc + 25
   IF EditBoxOfs > Part THEN EditBoxOfs = Part
   IF EditBoxPlc > Part THEN EditBoxPlc = Part
   GOSUB EditBoxShowAll
  END IF
  EditBoxOn = TRUE: GOSUB EditBoxCursor
 CASE CHR$(0) + "<"
  Help$ = " Keys in Edit mode ÿArrow keys move aroundÿPgUp and PgDn scrollÿEnter to edit the entryÿDel deletes that entryÿIns inserts an entryÿEscape quits and exitsÿTab switches the modeÿ"
  GOSUB UserBoxHelp
 CASE CHR$(0) + "R": CursorIns EditBoxPlc, Rspn$: GOSUB UserBoxRspn: EditBoxUpdate = TRUE
 CASE CHR$(0) + "S": CursorDel EditBoxPlc, Rspn$: GOSUB UserBoxRspn: EditBoxUpdate = TRUE
 CASE CHR$(9), CHR$(0) + ""
  EditBoxOn = FALSE: GOSUB EditBoxCursor
  IF kbrd$ = CHR$(9) GOTO UserBoxInput ELSE GOTO ShowBoxInput
 CASE CHR$(13)
  GOSUB EditBoxCursor: EditBoxPrompt = TRUE
  DO
   IF EditBoxPrompt THEN COLOR 15: StrPrompt Cmnd$, kbrd$, "", 8, 9, EditBoxRow, 72, EditBoxCurp, EditBoxOfst, Nsrt, 1: EditBoxPrompt = 0
   kbrd$ = UCASE$(INKEY$)
   SELECT CASE kbrd$
   CASE CHR$(27): EXIT DO
   CASE CHR$(13)
    DoCommand "CHNG " + STR$(EditBoxPlc + 1) + " " + Cmnd$, Rspn$
    IF Rspn$ > "" THEN GOSUB UserBoxRspn ELSE BoardClr: CursorUse: GOSUB UserBoxInfo: EXIT DO
   CASE ""
   CASE ELSE: EditBoxPrompt = TRUE
   END SELECT
  LOOP
  COLOR 15: GOSUB EditBoxPrint
 END SELECT
 IF EditBoxUpdate THEN GOSUB EditBoxShowAll: GOSUB EditBoxCursor: BoardClr: CursorUse: GOSUB UserBoxInfo: EditBoxUpdate = FALSE
LOOP
GOTO EndIt
EditBoxShowAll:
IF EditBoxPlc > LEN(Cursor$) THEN EditBoxPlc = LEN(Cursor$)
IF EditBoxPlc >= 0 AND EditBoxOfs > EditBoxPlc THEN EditBoxOfs = EditBoxPlc
COLOR 7: FOR EditBoxRow = 1 TO 25: GOSUB EditBoxPrint: NEXT EditBoxRow
RETURN
EditBoxCursor:
EditBoxRow = EditBoxPlc - EditBoxOfs + 1
IF EditBoxRow >= 0 AND EditBoxRow < 26 THEN  ELSE EditBoxRow = 0
IF EditBoxRow THEN IF EditBoxOn THEN COLOR 15: GOSUB EditBoxPrint ELSE COLOR 7: GOSUB EditBoxPrint
RETURN
EditBoxPrint:
 RealPlace = EditBoxRow + EditBoxOfs: Part$ = MID$(Cursor$, RealPlace, 1)
 IF Part$ = "" THEN LOCATE EditBoxRow, 72: PRINT STRING$(9, "-"); : RETURN
 Part = ASC(Part$): Part$ = SPACE$(9)
 MID$(Part$, 1, 3) = STR$((Part AND 63) + 1): MID$(Part$, 1, 1) = MID$("", (Part \ 64) + 1, 1)
 IF INSTR("	" + CHR$(10) + CHR$(13), CHR$(Part)) = 0 THEN MID$(Part$, 5, 1) = CHR$(Part) ELSE MID$(Part$, 5, 1) = "ù"
 MID$(Part$, 6, 4) = STR$(Part)
 LOCATE EditBoxRow, 72: PRINT Part$;
RETURN
UserKeys:
 IF kbrd$ = CHR$(27) THEN
  UserIsDone = TRUE
 ELSEIF kbrd$ = CHR$(0) + ";" THEN
  Help$ = " This is a simple letter maker that can create RLE string letters. There areÿthree modes and two windows to help you make them: Prompt, Manual, and List.ÿEach mode has special benefits over another. In Prompt mode, you type in textÿ"
  Help$ = Help$ + "commands, allowing exactness. You can make a letter freehand in Manual mode.ÿThen, in List mode, you can easily edit any mistakes. The Viewing window letsÿyou see the letter. The Movement List shows the movement data of the cursor.ÿ"
  Help$ = Help$ + "				     ** General Keys **ÿEscape quits the programÿEnter does different things in each modeÿCtrl+Enter executes and keeps the command in Prompt modeÿF2 brings up syntax ref. and help for each modeÿF3 clears the command window "
  Help$ = Help$ + "of all textÿTab cycles through all of the modesÿThese keys will work for text prompt editing (Home End Left Right Back Del)ÿOther keys vary from mode to mode, press F2 while in any one of them for infoÿ				       ** "
  Help$ = Help$ + "Commands **ÿDRAW erases the board and quickly redraws all or part of the spider letterÿGO adds a direction to the move list   BACK deletes your last move(s)ÿLEN gives the length of the move list  CON condenses the list if possibleÿ"
  Help$ = Help$ + "CHECK checks the existance of a file   SAVE & LOAD do just that, save & loadÿORIG repositions the cursor origin     NEW clears all the board and letterÿ (ñexp = ñ1 to ñ64) (+exp = 1 to ?) (file$ = any correct DOS format filename)"
  MainHelp Help$
 ELSEIF kbrd$ = CHR$(0) + "=" THEN
  FOR GoDown = 1 TO 24
   LOCATE GoDown, 1: PRINT SPACE$(24);
  NEXT GoDown
  UserBoxRow = 0
  UserBoxUpdate = TRUE
  WHILE INKEY$ > "": WEND
 ELSEIF kbrd$ = CHR$(0) + ">" THEN
  Help$ = "ÿÿÿÿÿÿÿÿ				  Programmer and Designerÿ				    Frank Dwayne Robinsonÿÿ					Inspirationÿ					 Ryan Foster"
  MainHelp Help$
 END IF
RETURN
FilErrHan: FilErr = ERR: RESUME NEXT
EndIt:
SCREEN 0: COLOR 7, 0: CLS
SYSTEM

SUB BoardClr
LINE (200, 7)-(551, 342), 0, BF
END SUB

SUB BoardDot (VYpos, HXpos, OnOff)
IF VYpos >= 0 AND VYpos < 84 THEN
 IF HXpos >= 0 AND HXpos < 88 THEN
  VYtmp = (VYpos * 4) + 7
  HXtmp = (HXpos * 4) + 200
  LINE (HXtmp, VYtmp)-(HXtmp + 3, VYtmp + 3), OnOff, BF
 END IF
END IF
END SUB

SUB CursorAdd (CurDir, Length, Rspn$)
Rspn$ = ""
IF SGN(Length) = -1 THEN RelDir = CurDir XOR 2 ELSE RelDir = CurDir
RelDir = RelDir AND 3
DirLen = ABS(Length)
IF DirLen = 0 OR DirLen > 64 THEN Rspn$ = "Length out of range": EXIT SUB
IF Cursor$ > "" THEN Part$ = MID$(Cursor$, LEN(Cursor$), 1): IF (ASC(Part$) AND 192) = RelDir * 64 THEN LstLen = ASC(Part$) AND 63: IF LstLen + DirLen + 1 <= 64 THEN MID$(Cursor$, LEN(Cursor$), 1) = CHR$((RelDir * 64) OR (LstLen + DirLen)): EXIT SUB
IF LEN(Cursor$) >= 100 THEN Rspn$ = "String too long": EXIT SUB
Cursor$ = Cursor$ + CHR$((RelDir * 64) OR (DirLen - 1))
END SUB

SUB CursorBak (Length, Rspn$)
Rspn$ = ""
IF Length < 0 THEN Rspn$ = "Negative number!": EXIT SUB
IF LEN(Cursor$) = 0 THEN Rspn$ = "Already cleared": EXIT SUB
IF Length > LEN(Cursor$) THEN
 Cursor$ = ""
ELSE
 Cursor$ = LEFT$(Cursor$, LEN(Cursor$) - Length)
END IF
IF LEN(Cursor$) = 0 THEN Rspn$ = "All empty now"
END SUB

SUB CursorChg (Place, CurDir, Length, Rspn$)
Rspn$ = "": IF Place < 1 THEN Rspn$ = "Illegal unit pointer": EXIT SUB ELSE Part$ = MID$(Cursor$, Place, 1)
IF CurDir = -1 THEN IF Part$ = "" THEN Rspn$ = "No direction": EXIT SUB ELSE RelDir = ASC(Part$) \ 64 ELSE RelDir = CurDir AND 3
IF Length = 0 THEN
 IF Part$ = "" THEN DirLen = 0 ELSE DirLen = ASC(Part$) AND 63
ELSE
 IF SGN(Length) = -1 THEN RelDir = RelDir XOR 2
 DirLen = ABS(Length) - 1: IF DirLen > 63 THEN Rspn$ = "Length out of range": EXIT SUB
END IF
Part$ = CHR$((RelDir * 64) OR DirLen): IF Place > LEN(Cursor$) THEN Cursor$ = Cursor$ + Part$ ELSE MID$(Cursor$, Place, 1) = Part$
END SUB

SUB CursorCon (Start, Endng)
IF Start = 0 THEN Place = 1 ELSE Place = Start
Look = Place
IF Endng = 0 THEN Endng = LEN(Cursor$)
DO
 Part$ = MID$(Cursor$, Place, 1)
 IF Look >= Endng OR Part$ = "" THEN EXIT DO
 Length = ASC(Part$) AND 63: CurDir = ASC(Part$) \ 64
 Part$ = MID$(Cursor$, Place + 1, 1)
 IF Part$ = "" THEN EXIT DO
 DirLen = ASC(Part$) AND 63: NxtDir = ASC(Part$) \ 64
 IF NxtDir = CurDir THEN
  IF Length + DirLen + 1 < 64 THEN
   MID$(Cursor$, Place, 1) = CHR$((CurDir * 64) OR (Length + DirLen + 1))
   Cursor$ = LEFT$(Cursor$, Place) + MID$(Cursor$, Place + 2)
  ELSEIF Length < 64 THEN
   DirLen = (DirLen + Length + 2) MOD 64
   MID$(Cursor$, Place, 1) = CHR$((CurDir * 64) OR 63)
   MID$(Cursor$, Place + 1, 1) = CHR$((CurDir * 64) OR (DirLen - 1))
   Place = Place + 1
  ELSE Place = Place + 1
  END IF
 ELSE Place = Place + 1
 END IF
 Look = Look + 1
LOOP
END SUB

SUB CursorDel (Place, Rspn$)
IF Place < 0 OR Place > LEN(Cursor$) THEN Rspn$ = "Illegal unit pointer": EXIT SUB
Cursor$ = LEFT$(Cursor$, Place) + MID$(Cursor$, Place + 2)
END SUB

SUB CursorIns (Place, Rspn$)
IF Place < 0 OR Place > LEN(Cursor$) THEN Rspn$ = "Illegal unit pointer": EXIT SUB
IF Place THEN Part$ = MID$(Cursor$, Place, 1) ELSE Part$ = "@"
Cursor$ = LEFT$(Cursor$, Place) + Part$ + MID$(Cursor$, Place + 1)
END SUB

SUB CursorMov (CurDir AS CursorInfo, VYdir, HXdir)
CurDir.VYdir = 0: CurDir.HXdir = 0
IF VYdir < 0 AND NOT (CurDir.VYdir > 0) THEN CurDir.VYdir = -1 ELSE IF VYdir > 0 AND NOT (CurDir.VYdir < 0) THEN CurDir.VYdir = 1
IF HXdir < 0 AND NOT (CurDir.HXdir > 0) THEN CurDir.HXdir = -1 ELSE IF HXdir > 0 AND NOT (CurDir.HXdir < 0) THEN CurDir.HXdir = 1

BoardDot CurDir.VYpos, CurDir.HXpos, 11
CurDir.VYpos = CurDir.VYpos + CurDir.VYdir
CurDir.HXpos = CurDir.HXpos + CurDir.HXdir
BoardDot CurDir.VYpos, CurDir.HXpos, 15
END SUB

SUB CursorUse
 CsrInfo.VYpos = OrigVYpos: CsrInfo.HXpos = OrigHXpos
 CursorMov CsrInfo, 0, 0
 GoDown = 0
 DO
  IF Count <= 0 THEN
   IF GoDown >= LEN(Cursor$) THEN EXIT DO ELSE GoDown = GoDown + 1
   DirInput = ASC(MID$(Cursor$, GoDown, 1))
   SELECT CASE DirInput \ 64
   CASE 0: VYdir = -1: HXdir = 0
   CASE 1: VYdir = 0: HXdir = 1
   CASE 2: VYdir = 1: HXdir = 0
   CASE 3: VYdir = 0: HXdir = -1
   END SELECT
   Count = DirInput AND 63
  ELSE Count = Count - 1
  END IF
  CursorMov CsrInfo, VYdir, HXdir
 LOOP
END SUB

SUB DefScroll (Scroll(), Row1, Row2, Col1, Col2, UpDn, Colr)
REDIM Scroll(0 TO 6)
p = VARPTR(Scroll(0)): DEF SEG = VARSEG(Scroll(0))
POKE p, &HB8
POKE p + 1, ABS(UpDn)
IF SGN(UpDn) = -1 THEN POKE p + 2, &H6 ELSE POKE p + 2, &H7
POKE p + 3, &HB9 '?
POKE p + 4, Col1 ' Left side
POKE p + 5, Row1 ' Top Line
POKE p + 6, &HBA '?
POKE p + 7, Col2 ' Right Side
POKE p + 8, Row2 ' Bottom Line
POKE p + 9, &HB7 '?
POKE p + 10, Colr'þ Back Color
POKE p + 11, &HCD'?
POKE p + 12, &H10'?
POKE p + 13, &HCB'?
'  0    1    2    3    4    5    6    7    8    9   10   11   12   13
'  ?    ?    ?    ?            ?            ?  color  ?    ?    ?
'&HB8,&H01,&H06,&HB9,&H08,&H05,&HBA,&H0?,&H0?,&HB7,&H09,&HCD,&H10,&HCB
DEF SEG
END SUB

SUB DoCommand (CmndLine$, Rspn$)
Rspn$ = ""
CmndLine$ = UCASE$(CmndLine$)
GetWord CmndLine$, 0, Cmnd$
Cmnd$ = UCASE$(Cmnd$)
SELECT CASE Cmnd$
CASE "GO"
 GetWord CmndLine$, 1, Part$
 SELECT CASE Part$
 CASE "": Rspn$ = "Missing direction": GOTO DCErr
 CASE "UP", "1": CurDir = 0
 CASE "RIGHT", "2": CurDir = 1
 CASE "DOWN", "3": CurDir = 2
 CASE "LEFT", "4": CurDir = 3
 CASE ELSE: Rspn$ = "Unknown direction": GOTO DCErr
 END SELECT
 GetWord CmndLine$, 2, Part$
 IF Part$ = "" THEN Length = 1 ELSE Length = VAL(LEFT$(Part$, 3))
 CursorAdd CurDir, Length, Rspn$
 EditBoxUpdate = TRUE
CASE "BACK"
 GetWord CmndLine$, 1, Part$
 IF Part$ = "" THEN Length = 1 ELSE IF Part$ = "!" THEN Length = LEN(Cursor$) ELSE Length = VAL(LEFT$(Part$, 3))
 CursorBak Length, Rspn$
 EditBoxUpdate = TRUE
CASE "CHNG"
 GetWord CmndLine$, 1, Word$: IF Word$ = "" THEN Rspn$ = "Missing Unit": GOTO DCErr ELSE EditBoxPlc = VAL(LEFT$(Word$, 3))
 GetWord CmndLine$, 2, Word$
 IF Word$ > "" THEN
  SELECT CASE Word$
  CASE "?", "0": CurDir = -1
  CASE "UP", "1": CurDir = 0
  CASE "RIGHT", "4": CurDir = 1
  CASE "DOWN", "2": CurDir = 2
  CASE "LEFT", "3": CurDir = 3
  CASE ELSE: Rspn$ = "Unknown direction": GOTO DCErr
  END SELECT
  GetWord CmndLine$, 3, Word$
  IF Word$ = "" OR Word$ = "0" THEN Length = 0 ELSE Length = VAL(LEFT$(Word$, 3)): IF Length = 0 THEN Rspn$ = "Unknown length": GOTO DCErr
  CursorChg EditBoxPlc, CurDir, Length, Rspn$
  EditBoxUpdate = TRUE
 ELSE Rspn$ = "Missing direction"
 END IF
CASE "DRAW": BoardClr: CursorUse
CASE "LEN": Rspn$ = "Length is" + STR$(LEN(Cursor$))
CASE "CON"
 GetWord CmndLine$, 1, Part$: Start = VAL(LEFT$(Part$, 4))
 GetWord CmndLine$, 1, Part$: Endng = VAL(LEFT$(Part$, 4))
 CursorCon Start, Endng: EditBoxUpdate = TRUE
CASE "ORIG"
 GetWord CmndLine$, 1, Part$
 IF Part$ > "" THEN
  IF Part$ <> "?" THEN OrigVYpos = VAL(LEFT$(Part$, 3))
  GetWord CmndLine$, 2, Part$: IF Part$ > "" AND Part$ <> "?" THEN OrigHXpos = VAL(LEFT$(Part$, 3))
  EditBoxUpdate = TRUE
 END IF
 Rspn$ = "Origins are" + STR$(OrigVYpos) + "y" + STR$(OrigHXpos) + "x"
CASE "NEW"
 Cursor$ = "": BoardClr
 OrigVYpos = 42: OrigHXpos = 44
 EditBoxUpdate = TRUE
CASE "LOAD", "SAVE", "CHECK"
 ON ERROR GOTO FilErrHan
 GetWord CmndLine$, 1, Part$
 IF Part$ = "" THEN Rspn$ = "No file name": GOTO DCErr
 IF Cmnd$ = "CHECK" THEN
  FilErr = 0: OPEN Part$ FOR INPUT AS #1: CLOSE #1: IF FilErr THEN Rspn$ = "Do not see that file": GOTO DCErr ELSE Rspn$ = "File already exists": GOTO DCErr
 ELSEIF Cmnd$ = "LOAD" THEN
  FilErr = 0: OPEN Part$ FOR INPUT AS #1: CLOSE #1:
  IF FilErr THEN IF FilErr = 53 THEN Rspn$ = "Can not find file": GOTO DCErr ELSE Rspn$ = "Baaad file name": GOTO DCErr
  OPEN Part$ FOR BINARY AS #1: IF LOF(1) < 2 THEN Rspn$ = "Too short of a file": GOTO DCErr: CLOSE #1
  OrigVYpos = ASC(INPUT$(1, 1)): OrigHXpos = ASC(INPUT$(1, 1)): IF LOF(1) > 102 THEN Cursor$ = INPUT$(100, 1) ELSE Cursor$ = INPUT$(LOF(1) - 2, 1)
  CLOSE #1: EditBoxUpdate = TRUE: IF FilErr THEN Rspn$ = "Load error recieved?": GOTO DCErr
 ELSE
  OPEN Part$ FOR OUTPUT AS #1: PRINT #1, CHR$(OrigVYpos AND 255); CHR$(OrigHXpos AND 255); Cursor$; : CLOSE #1
  IF FilErr THEN Rspn$ = "Save error recieved?": GOTO DCErr
 END IF
 ON ERROR GOTO 0
CASE ELSE: IF CmndLine$ > "" THEN Rspn$ = "Unknown command"
END SELECT

DCErr:
END SUB

SUB GetWord (Whole$, Word, Part$)
InWord = FALSE
Start = 0
FOR Look = 1 TO LEN(Whole$)
 IF InWord = FALSE THEN
  IF MID$(Whole$, Look, 1) <> " " THEN InWord = TRUE: WordCount = WordCount + 1: IF WordCount > Word THEN Start = Look: EXIT FOR
 ELSE IF InWord THEN IF MID$(Whole$, Look, 1) = " " THEN InWord = FALSE
 END IF
NEXT Look
IF Start = 0 THEN Part$ = "": Endng = 0: EXIT SUB
FOR Look = Start TO LEN(Whole$)
 IF MID$(Whole$, Look, 1) = " " THEN Endng = Look - 1: EXIT FOR ELSE IF Look >= LEN(Whole$) THEN Endng = Look
NEXT Look
Part$ = MID$(Whole$, Start, Endng - Start + 1)
END SUB

SUB MainHelp (Help$)
PCOPY 0, 1
CLS
LOCATE 1, 33: COLOR 14: PRINT "Letter Maker Help"
LOCATE 2, 1: COLOR 7: PRINT STRING$(80, 220);
LOCATE 25, 1: PRINT STRING$(80, 223);
FOR GoDown = 3 TO 24
 LOCATE GoDown, 1: PRINT "Û";
 LOCATE , 80: PRINT "Û";
NEXT GoDown
COLOR 15
ColCount = 0
RowCount = 0
FOR GoDown = 1 TO LEN(Help$)
 WHILE MID$(Help$, GoDown, 1) = "	": ColCount = ColCount + 8: GoDown = GoDown + 1: WEND
 IF ColCount >= 78 THEN
  NextHelpPos = INSTR(GoDown, Help$, "ÿ")
  IF NextHelpPos = 0 THEN EXIT FOR ELSE GoDown = NextHelpPos
 END IF
 WHILE MID$(Help$, GoDown, 1) = "ÿ"
  IF RowCount >= 21 THEN EXIT FOR
  GoDown = GoDown + 1
  RowCount = RowCount + 1
  ColCount = 0
 WEND
 IF MID$(Help$, GoDown, 1) > "" THEN LOCATE RowCount + 3, ColCount + 2: PRINT MID$(Help$, GoDown, 1); : ColCount = ColCount + 1
NEXT GoDown
WHILE INKEY$ = "": WEND
PCOPY 1, 0
END SUB

DEFSNG A-Z
SUB ScrolScrn (Scroll%())
DEF SEG = VARSEG(Scroll%(0))
CALL Absolute(VARPTR(Scroll%(0)))
END SUB

DEFINT A-Z
SUB StrPrompt (Rslt$, KeyIn$, KeyOut$, Lim, Vis, Row, Col, Curp, Ofst, Nsrt, Done)
Chng = 1
kbrd$ = KeyIn$
IF Row = 0 THEN Row = CSRLIN
IF Col = 0 THEN Col = POS(0)
IF Curp = -1 THEN Curp = LEN(Rslt$)

DO
 Leng = LEN(Rslt$)
 SELECT CASE kbrd$
 CASE ""
 CASE " " TO "ÿ": GOSUB PromptInsert: Chng = 1
 CASE CHR$(8): IF Curp > 0 AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp - 1) + RIGHT$(Rslt$, Leng - Curp): Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "S": IF Curp < Leng AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp) + RIGHT$(Rslt$, Leng - Curp - 1): Chng = 1
'CASE CHR$(0) + "R": Nsrt = Nsrt XOR 1: Chng = 1
 CASE CHR$(0) + "K": IF Curp > 0 THEN Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "M": IF Curp < Leng THEN Curp = Curp + 1: Chng = 1
 CASE CHR$(0) + "G": Curp = 0: Chng = 1
 CASE CHR$(0) + "O": Curp = Leng: Chng = 1
 CASE ELSE: IF LEN(kbrd$) <> 1 OR Nsrt = 0 THEN KeyOut$ = kbrd$: Done = 1 ELSE GOSUB PromptInsert: Nsrt = 0: Chng = 1
 END SELECT

 IF Chng THEN
  Leng = LEN(Rslt$)
  IF Curp > Leng THEN Curp = Leng ELSE IF Curp < 0 THEN Curp = 0
  IF Curp < Ofst THEN Ofst = Curp ELSE IF Curp >= Ofst + Vis THEN Ofst = Curp - Vis + 1
  text$ = MID$(Rslt$ + SPACE$(Vis), Ofst + 1, Vis)
  LOCATE , , 0: LOCATE Row, Col: PRINT text$;
  LOCATE Row, Col + ((Curp - Ofst) MOD 80)
  IF Nsrt THEN PRINT "Û";  ELSE PRINT "Ý";
  Chng = 0
 END IF

 IF Done THEN EXIT DO
 kbrd$ = INKEY$
LOOP
EXIT SUB

PromptInsert:
 IF LEN(kbrd$) + LEN(Rslt$) > Lim THEN SOUND 1024, .1: RETURN
 Rslt$ = LEFT$(Rslt$, Curp) + kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - Curp)
 Curp = Curp + LEN(kbrd$)
RETURN
END SUB

