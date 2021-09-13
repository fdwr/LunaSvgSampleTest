DEFINT A-Z
DECLARE SUB Condense (In$, Out$)
DECLARE SUB Expand (In$, Out$)
DECLARE SUB DrawLetter (Trl$, Clr, Mode, Row, Col)
DECLARE SUB Sketch (Trail$, Clr, Row, Col)
DECLARE SUB MultiFont (Trl$, Entry, Ofst, Last, Lim, Mode)
DECLARE SUB ShowData (Trl$, Mode)
DECLARE SUB HELPLINE (Text$, Row, Col)
DECLARE SUB PIXEL (Row, Col, Clr)
DECLARE SUB PRINTXT (Text$, Row, Col)
DECLARE SUB PROMPT (Frst$, Last$, KeyIn$, KeyOut$, Lim, Vis, Row, Col, Curp, Done)
DIM SHARED EditMode, PixOfset, BackClr
PixOfset = 6
BackClr = 0

SCREEN 0
WIDTH 80, 50
COLOR , 1: CLS
LOCATE , , 0

NewShape:
Trail$ = "": Trl$ = ""
EditMode = 0: LetrChng = 1
COLOR 0, 7
FOR Show = 23 TO 26: LOCATE Show, 33: PRINT SPACE$(16); : NEXT Show
FOR Show = 28 TO 31: LOCATE Show, 33: PRINT SPACE$(16); : NEXT Show
GOSUB Help
GOSUB ShowName
GOSUB ClearBox
DO
 HELPLINE " Choose a starting place and press Enter to lock it", LetrRow, LetrCol
 Trail$ = HEX$(LetrRow) + HEX$(LetrCol)
 ShowData Trail$, 0
 PIXEL LetrRow, LetrCol, 11
 Prr = LetrRow: Prc = LetrCol
 GOSUB KeyReact
 IF Kbrd$ = CHR$(13) THEN Condense Trail$, Trl$: LetrChng = 0: EXIT DO
 IF LetrMove THEN PIXEL Prr, Prc, BackClr: LetrRow = (LetrRow + Rdf) AND 15: LetrCol = (LetrCol + Cdf) AND 15: LetrMove = 0
LOOP
NeedDraw = 2

EditShape:
EditMode = 1: NeedDraw = 3
DO
 IF NeedDraw AND 2 THEN Sketch Trail$, 14, 0, 0: NeedDraw = NeedDraw XOR 2
 IF NeedDraw AND 1 THEN
  HELPLINE " Move the cursor to create a letter and press Enter to QuickDraw it", LetrRow, LetrCol
  ShowData Trail$, 0
  NeedDraw = NeedDraw XOR 1
 END IF

 GOSUB KeyReact

 IF LetrMove = 1 AND LEN(Trail$) < 1018 THEN
  SELECT CASE MoveDir
  CASE 0: Text$ = "U"
  CASE 1: Text$ = "D"
  CASE 2: Text$ = "L"
  CASE 3: Text$ = "R"
  END SELECT
  Trail$ = Trail$ + Text$
  LetrRow = LetrRow + Rdf: LetrCol = LetrCol + Cdf
  PIXEL LetrRow, LetrCol, 14
  LetrMove = 0: NeedDraw = 1: LetrChng = 1
 ELSEIF LetrMove = -1 THEN
  Leng = LEN(Trail$)
  IF Leng > 2 THEN
   PIXEL LetrRow, LetrCol, BackClr
   SELECT CASE MID$(Trail$, Leng, 1)
   CASE "U": LetrRow = LetrRow + 1
   CASE "D": LetrRow = LetrRow - 1
   CASE "L": LetrCol = LetrCol + 1
   CASE "R": LetrCol = LetrCol - 1
   END SELECT
   Trail$ = LEFT$(Trail$, Leng - 1)
   NeedDraw = 1: LetrChng = 1
  END IF
  LetrMove = 0
 ELSEIF LetrMove = 1 THEN LetrMove = 0
 END IF
LOOP

MoveShape:
EditMode = 2: NeedDraw = 2
DO
 IF NeedDraw AND 2 THEN Sketch Trail$, 10, 0, 0: NeedDraw = NeedDraw XOR 2
 HELPLINE " Use the arrow keys to move the font, or press 'E'", StrtRow, StrtCol
 GOSUB KeyReact
 IF LetrMove = 1 THEN
  StrtRow = ASC(MID$(Trl$, 1, 1)) \ 16: StrtCol = ASC(MID$(Trl$, 1, 1)) AND 15
  StrtRow = (StrtRow + Rdf) AND 15: StrtCol = (StrtCol + Cdf) AND 15
  MID$(Trl$, 1, 1) = CHR$(StrtRow * 16 + StrtCol)
  MID$(Trail$, 1, 2) = HEX$(StrtRow) + HEX$(StrtCol)
  GOSUB ClearBox: Sketch Trail$, 10, LetrRow, LetrCol
  ShowData Trail$, 0: ShowData Trl$, 1
  LetrMove = 0: LetrChng = 0
 END IF
LOOP
RETURN

FlipShape:
EditMode = 3: NeedDraw = 2
DO
 IF NeedDraw AND 2 THEN Sketch Trail$, 12, 0, 0: NeedDraw = NeedDraw XOR 2
 IF LetrMove = 1 THEN
  SELECT CASE MoveDir
  CASE 0, 1
   FOR Show = 2 TO LEN(Trail$)
    Text$ = MID$(Trail$, Show, 1): IF Text$ = "D" THEN MID$(Trail$, Show, 1) = "U" ELSE IF Text$ = "U" THEN MID$(Trail$, Show, 1) = "D"
   NEXT Show
  CASE 2, 3
   FOR Show = 2 TO LEN(Trail$)
    Text$ = MID$(Trail$, Show, 1): IF Text$ = "L" THEN MID$(Trail$, Show, 1) = "R" ELSE IF Text$ = "R" THEN MID$(Trail$, Show, 1) = "L"
   NEXT Show
  END SELECT
  GOSUB ClearBox: Sketch Trail$, 12, LetrRow, LetrCol
  ShowData Trail$, 0
  LetrMove = 0: LetrChng = 1
 END IF
 HELPLINE " Use the arrow keys to flip the font, or press 'E'", LetrRow, LetrCol
 GOSUB KeyReact
LOOP UNTIL Done
Condense Trail$, Trl$
RETURN

KinkShape:
EditMode = 4: LetrMove = 1: MoveDir = -1: NeedDraw = 2
Sketch LEFT$(Trail$, LetrPos + 2), 13, StrtRow, StrtCol
DO
 IF NeedDraw AND 2 THEN Sketch Trail$, 13, 0, 0: NeedDraw = NeedDraw XOR 2
 IF LetrMove = 1 THEN
  IF LetrPos < 0 THEN LetrPos = 0
  Last = LEN(Trail$) - 3: IF LetrPos > Last THEN LetrPos = Last
  SELECT CASE MoveDir
  CASE 0: IF LetrPos < Last THEN LetrPos = LetrPos + 1
  CASE 1: IF LetrPos > 0 THEN LetrPos = LetrPos - 1
  CASE 2: Inv$ = "LRDU"
  CASE 3: Inv$ = "RLUD"
  END SELECT
  IF MoveDir = 2 OR MoveDir = 3 THEN
   FOR Show = LetrPos + 3 TO LEN(Trail$)
    SELECT CASE MID$(Trail$, Show, 1)
    CASE "U": MID$(Trail$, Show, 1) = MID$(Inv$, 1)
    CASE "D": MID$(Trail$, Show, 1) = MID$(Inv$, 2)
    CASE "L": MID$(Trail$, Show, 1) = MID$(Inv$, 3)
    CASE "R": MID$(Trail$, Show, 1) = MID$(Inv$, 4)
    END SELECT
   NEXT Show
   GOSUB ClearBox
   Sketch Trail$, 13, LetrRow, LetrCol
   LetrChng = 1
  END IF
  Prr = StrtRow: Prc = StrtCol: PIXEL Prr, Prc, 13
  Sketch LEFT$(Trail$, LetrPos + 2), 13, StrtRow, StrtCol: PIXEL StrtRow, StrtCol, 15
  ShowData Trail$, 0
  LetrMove = 0
 END IF
 HELPLINE " Use the arrow keys to kink or turn the font, or press 'E'", StrtRow, StrtCol
 GOSUB KeyReact
LOOP UNTIL Done
RETURN

KeyReact:
Rdf = 0: Cdf = 0
DO: Kbrd$ = INKEY$: LOOP UNTIL Kbrd$ > ""
IF LEN(Kbrd$) = 1 THEN Kbrd$ = UCASE$(Kbrd$)
SELECT CASE Kbrd$
CASE CHR$(0) + "H", "U": Rdf = -1: MoveDir = 0: LetrMove = 1
CASE CHR$(0) + "P", "D": Rdf = 1: MoveDir = 1: LetrMove = 1
CASE CHR$(0) + "K", "L": Cdf = -1: MoveDir = 2: LetrMove = 1
CASE CHR$(0) + "M", "R": Cdf = 1: MoveDir = 3: LetrMove = 1
CASE CHR$(8): LetrMove = -1
CASE CHR$(0) + "R" 'Condense
 HELPLINE " Condensing letter into shape", LetrRow, LetrCol: NeedDraw = 1: Condense Trail$, Trl$: ShowData Trl$, 1: LetrChng = 0
CASE CHR$(0) + "S": IF EditMode THEN RETURN NewShape
CASE CHR$(13) 'QuickDraw letter
 IF LetrChng THEN Condense Trail$, Trl$: ShowData Trl$, 1: LetrChng = 0
 DrawLetter Trl$, 9, 1, 0, 0: DrawLetter Trl$, 11, 1, 0, 0: NeedDraw = 3
CASE "E": IF EditMode THEN RETURN EditShape
CASE "M": IF EditMode THEN RETURN MoveShape
CASE "F": IF EditMode THEN RETURN FlipShape
CASE "K": IF EditMode THEN RETURN KinkShape
CASE "O"
 GOSUB LoadFont: LOCATE , , 0
 IF LetrChng = -1 THEN ShowData Trail$, 0: ShowData Trl$, 1: NeedDraw = 3: GOSUB ClearBox: Sketch Trail$, BackClr, LetrRow, LetrCol ELSE NeedDraw = 1
 IF EditMode = 0 AND LetrChng = -1 THEN RETURN EditShape
 IF LetrChng = -1 THEN LetrChng = 0
CASE "S"
 IF EditMode THEN
  IF LetrChng THEN Condense Trail$, Trl$: ShowData Trl$, 1: LetrChng = 0
  GOSUB SaveFont: LOCATE , , 0
  NeedDraw = 1
 END IF
CASE CHR$(27): RETURN Endit
END SELECT
IF Kbrd$ > "" THEN WHILE INKEY$ > "": WEND
RETURN

Endit:
WIDTH 80, 25
COLOR 7, 0: CLS
END

ClearBox:
COLOR 7, BackClr: FOR Show = PixOfset TO 15 + PixOfset: LOCATE Show, 33, 0: PRINT SPACE$(16); : NEXT Show
RETURN

ShowName:
COLOR 15, 7
LOCATE 2, 33
IF file$ = "" THEN PRINT "   (Untitled)   ";  ELSE PRINT LEFT$(RIGHT$(file$, 15) + SPACE$(16), 16);
RETURN

SaveFont:
HELPLINE " Enter a filename to save this single font in, or press Esc to cancel", LetrRow, LetrCol
GOSUB GetFileName
IF Key$ = CHR$(27) OR file$ = "" THEN RETURN
ON ERROR GOTO FileErr: FilErr = 0
OPEN file$ FOR INPUT AS #1: CLOSE #1
COLOR 15, 1
IF FilErr > 0 AND FilErr <> 53 THEN LOCATE 4, 19: PRINT "There was an error trying to open this file!"; : SOUND 860, 1: WHILE INKEY$ = "": WEND: LOCATE 4, 19: PRINT SPACE$(61); : GOTO SaveFont
IF FilErr = 0 THEN
 LOCATE 4, 19: PRINT "This file already exists, write over it? (Y,N)";
 DO
  PROMPT "", Ans$, "", Key$, 1, 2, 4, 0, 0, 0: Ans$ = UCASE$(Ans$)
 LOOP UNTIL (Key$ = CHR$(13) AND (Ans$ = "Y" OR Ans$ = "N")) OR Key$ = ""
 LOCATE 4, 19: PRINT SPACE$(61);
 IF Key$ = "" THEN RETURN ELSE IF Ans$ = "N" THEN GOTO SaveFont
END IF
OPEN file$ FOR OUTPUT AS #1
PRINT #1, Trl$;
CLOSE #1
RETURN

LoadFont:
HELPLINE " Enter the filename of the font to load, or press Esc to cancel", LetrRow, LetrCol
GOSUB GetFileName
IF Key$ = CHR$(27) OR file$ = "" THEN RETURN
ON ERROR GOTO FileErr: FilErr = 0
OPEN file$ FOR INPUT AS #1: CLOSE #1
COLOR , 1
IF FilErr > 0 THEN
 SOUND 860, 1
 COLOR 15, 1
 IF FilErr = 53 THEN LOCATE 4, 19: PRINT "Cannot find this file, try a different name";  ELSE LOCATE 4, 19: PRINT "There was an error trying to open this file";
 WHILE INKEY$ = "": WEND: LOCATE 4, 19: PRINT SPACE$(61); : GOTO LoadFont
END IF
LOCATE 4, 15: PRINT "Read as a multifont file or a single font file (M,S)";
DO
 Ans$ = "": PROMPT "", Ans$, "", Key$, 1, 2, 4, 0, 0, 0: Ans$ = UCASE$(Ans$)
LOOP UNTIL (Key$ = CHR$(13) AND (Ans$ = "M" OR Ans$ = "S")) OR Key$ = ""
LOCATE 4, 15: PRINT SPACE$(61);
IF Key$ = "" THEN RETURN
OPEN file$ FOR BINARY AS #1
LetrChng = -1
IF Ans$ = "M" THEN
 MultiFont "", 0, 0, Last, 0, 0
 LOCATE 4, 28: PRINT "Entry number     out of" + STR$(Last); : Ans$ = ""
 HELPLINE " Press Enter when you the shape what you want, or Esc to cancel", 0, 0
 DO
  IF Key$ > "" THEN GOSUB ClearBox: IF Ans$ > "" THEN MultiFont Tst$, Entry, 1, 0, 0, Lim: DrawLetter Tst$, 9, 0, 0, 0
  Key$ = INKEY$: COLOR 15, 1: PROMPT Ans$, Ans$, Key$, "", 3, 4, 4, 41, Curp, 1: Entry = VAL(Ans$)
 LOOP UNTIL (Key$ = CHR$(13) AND (Entry >= 0 AND Entry <= Last)) OR Key$ = ""
 LOCATE 4, 19: PRINT SPACE$(61);
 GOSUB ClearBox
 Tst$ = ""
 IF Key$ = "" THEN CLOSE #1: RETURN
 MultiFont Trl$, Entry, 1, 0, 0, 0
 IF Trl$ = "" THEN COLOR 15, 1: LOCATE 4, 19: PRINT "That entry is empty and will not be loaded"; : WHILE INKEY$ = "": WEND: LOCATE 4, 19: PRINT SPACE$(61);
ELSEIF Ans$ = "S" THEN
 SEEK #1, Ofst: Trl$ = INPUT$(64, #1)
END IF
CLOSE #1: Expand Trl$, Trail$
RETURN

FileErr: FilErr = ERR: RESUME NEXT
GetFileName:
DO
 COLOR 15, 7: PROMPT file$, file$, "", Key$, 127, 16, 2, 33, -1, 0
LOOP UNTIL Key$ = CHR$(13) OR Key$ = CHR$(27)
IF file$ > "" AND INSTR(file$, ".") = 0 AND RIGHT$(file$, 1) <> "\" THEN file$ = file$ + ".FNT"
file$ = UCASE$(file$): GOSUB ShowName
RETURN

Help:
DATA"U, - Move cusor up,","D, - Down,","L, - Left,","R, - and Right","BckSpc - Retrace or go back","","E - Edit font (default) yellow","M - Move font around    green","F - Flip font ver/hor   red"
DATA"K - Kink or turn font   purple","","Enter - Quick Redraw font","Ins - Condense font","Del - Remove font and restart","","S - Save font to file","O - Open font from file"
RESTORE Help
COLOR 15, 1
FOR Show = 6 TO 22
 READ Text$
 LOCATE Show, 2: PRINT Text$
NEXT Show
RETURN

SUB Condense (In$, Out$)
 IF LEN(In$) < 1 THEN EXIT SUB
 Leng = LEN(In$) - 2
 Out$ = STRING$(Leng \ 4 + 1 + SGN(Leng MOD 4), 0)

 MID$(Out$, 1) = CHR$(VAL("&H" + LEFT$(In$, 1)) * 16 + VAL("&H" + MID$(In$, 2, 1)))
 FOR Chng = 3 TO LEN(In$) STEP 4
  Char = 0
  FOR Chng2 = 0 TO 3
   IF Chng + Chng2 > LEN(In$) THEN
    Dir = Dir XOR 1
   ELSE
    NxtDir = INSTR("UDLR", MID$(In$, Chng + Chng2, 1))
    IF NxtDir THEN Dir = NxtDir - 1
   END IF
   Char = Char OR (Dir * (2 ^ (Chng2 * 2)))
  NEXT Chng2
  MID$(Out$, (Chng + 1) \ 4 + 1) = CHR$(Char)
 NEXT Chng
END SUB

SUB DrawLetter (Trl$, Clr, Mode, Row, Col)

Leng = LEN(Trl$)
IF Leng < 1 THEN EXIT SUB
Row = (ASC(Trl$) AND 240) \ 16: Col = ASC(Trl$) AND 15

PIXEL Row, Col, Clr
FOR Show = 2 TO Leng
 Letr = ASC(MID$(Trl$, Show, 1))
 Dir = Letr AND 3: PreDir = Dir: GOSUB DrawDir
 Dir = (Letr AND 12) \ 4: GOSUB DrawDir
 Dir = (Letr AND 48) \ 16: GOSUB DrawDir
 Dir = (Letr AND 192) \ 64: GOSUB DrawDir
NEXT Show
EXIT SUB

DrawDir:
 ' You may remove the above statement
 IF Show = Leng AND (PreDir XOR 1) = Dir THEN EXIT SUB
 SELECT CASE Dir
 CASE 0: Row = Row - 1
 CASE 1: Row = Row + 1
 CASE 2: Col = Col - 1
 CASE 3: Col = Col + 1
 END SELECT
 PreDir = Dir
 IF Mode THEN HELPLINE " Drawing your letter", Row, Col
 PIXEL Row, Col, Clr
RETURN
END SUB

SUB Expand (In$, Out$)

Leng = LEN(In$)
IF Leng < 1 THEN EXIT SUB
Out$ = STRING$(Leng * 4 + 2, 0)

MID$(Out$, 1) = HEX$(ASC(LEFT$(In$, 1)) \ 16)
MID$(Out$, 2) = HEX$(ASC(LEFT$(In$, 1)) AND 15)
Chng2 = 2
FOR Chng = 2 TO Leng
 Letr = ASC(MID$(In$, Chng, 1))
 Dir = Letr AND 3: PreDir = Dir: GOSUB ExpandDir
 Dir = (Letr AND 12) \ 4: GOSUB ExpandDir
 Dir = (Letr AND 48) \ 16: GOSUB ExpandDir
 Dir = (Letr AND 192) \ 64: GOSUB ExpandDir
NEXT Chng
EXIT SUB

ExpandDir:
 IF Chng = Leng AND (Dir XOR 1) = PreDir THEN Out$ = LEFT$(Out$, Chng2): EXIT SUB
 Dir$ = MID$("UDLR", Dir + 1, 1)
 Chng2 = Chng2 + 1
 MID$(Out$, Chng2, 1) = Dir$
 PreDir = Dir
RETURN
END SUB

SUB HELPLINE (Text$, Row, Col)
 LOCATE 50, 1: COLOR 15, 3
 PRINT LEFT$(Text$, 72); TAB(73);
 COLOR 0, 3
 PRINT "³"; LEFT$(STR$(Row) + ":" + LTRIM$(STR$(Col)) + SPACE$(7), 7);
END SUB

SUB MultiFont (Trl$, Entry, Mode, Last, Ofst, Lim)
IF FREEFILE <= 1 THEN EXIT SUB
Leng = LOF(1)

SELECT CASE Mode
CASE 0
 SEEK 1, 1: a$ = INPUT$(1, 1)
 IF a$ = "" THEN Last = 0: Lim = 0: EXIT SUB ELSE Last = ASC(MID$(a$, 1, 1))
 IF Entry > Last OR Entry + 2 > LOF(1) THEN Lim = 0: EXIT SUB
 Ptof = 0: SEEK 1, 2
 FOR a = 1 TO Entry: Ptof = Ptof + ASC(INPUT$(1, 1)): NEXT a
 IF Ptof + Last + 1 > LOF(1) THEN Lim = 0: EXIT SUB
 IF Entry = Last THEN Lim = Leng - Last - 1 ELSE SEEK 1, Entry + 2: Lim = ASC(INPUT$(1, 1))
CASE 1
 SEEK 1, 1: a$ = INPUT$(1, 1)
 IF a$ > "" THEN
  Last = ASC(a$)
  a$ = INPUT$(Last, 1)
  Ptln = LEN(a$)
  IF Entry > Last OR Entry > Ptln GOTO MultiError
  Ptof = 0
  FOR a = 1 TO Entry
   Ptof = Ptof + ASC(MID$(a$, a + 2, 1))
  NEXT a
  IF Entry = Last THEN Lim = Leng - Ptln - 1 ELSE Lim = ASC(MID$(a$, Entry + 1, 1))
  Ofst = Ptof + 1 + Ptln
  IF Ofst > Leng GOTO MultiError
  SEEK 1, Ofst: Trl$ = "": Trl$ = INPUT$(Lim, 1)
 ELSE
  Last = 0: GOTO MultiError
 END IF
END SELECT
EXIT SUB
MultiError:
 Ofst = 2: Lim = 0: Trl$ = ""
END SUB

SUB PIXEL (Row, Col, Clr)
IF Row >= 0 AND Row < 16 AND Col >= 0 AND Col < 16 THEN
 COLOR Clr: LOCATE Row + PixOfset, Col + 33: PRINT "Û";
END IF
END SUB

SUB PRINTXT (Text$, Urow, Lcol)
DEF SEG = &HB800: Vset = (Urow - 1) * 80 + (Lcol - 1)
FOR Show = 0 TO LEN(Text$) - 1
 POKE (Vset + Show) * 2, ASC(MID$(Text$, Show + 1, 1))
NEXT Show
END SUB

SUB PROMPT (Frst$, Last$, KeyIn$, KeyOut$, Lim, Vis, Row, Col, Curp, Done)
Chng = 1
Kbrd$ = KeyIn$
Rslt$ = Frst$
IF Row = 0 THEN Row = CSRLIN
IF Col = 0 THEN Col = POS(0)
IF Curp = -1 THEN Curp = LEN(Rslt$)

DO
 Leng = LEN(Rslt$)
 SELECT CASE Kbrd$
 CASE ""
 CASE " " TO "ÿ": GOSUB PromptInsert: Chng = 1
 CASE CHR$(0) + "S": IF Curp < Leng AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp) + RIGHT$(Rslt$, Leng - Curp - 1): Chng = 1
 CASE CHR$(8): IF Curp > 0 AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp - 1) + RIGHT$(Rslt$, Leng - Curp): Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "K": IF Curp > 0 THEN Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "M": IF Curp < Leng THEN Curp = Curp + 1: Chng = 1
 CASE CHR$(0) + "G": Curp = 0: Chng = 1
 CASE CHR$(0) + "O": Curp = Leng: Chng = 1
 CASE ELSE: KeyOut$ = Kbrd$: Done = 1
 END SELECT

 IF Chng THEN
  Leng = LEN(Rslt$)
  IF Curp > Leng THEN Curp = Leng ELSE IF Curp < 0 THEN Curp = 0
  IF Curp < Ofst THEN Ofst = Curp ELSE IF Curp >= Ofst + Vis THEN Ofst = Curp - Vis + 1
  LOCATE , , 0: LOCATE Row, Col: PRINT MID$(Rslt$ + SPACE$(Vis), Ofst + 1, Vis);
  LOCATE , , 1: LOCATE Row, Col + (Curp - Ofst)
  Chng = 0
 END IF

 IF Done = 0 THEN Kbrd$ = INKEY$
LOOP UNTIL Done

Last$ = Rslt$
EXIT SUB

PromptInsert:
 IF LEN(Kbrd$) + LEN(Rslt$) > Lim THEN SOUND 1024, .1: RETURN
 Rslt$ = LEFT$(Rslt$, Curp) + Kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - Curp)
 Curp = Curp + 1
RETURN
END SUB

SUB ShowData (Trl$, Mode)
IF LEN(Trl$) < 64 THEN Txt$ = Trl$ + SPACE$(64 - LEN(Trl$)) ELSE Txt$ = LEFT$(Trl$, 64)
IF Mode THEN Lin = 28 ELSE Lin = 23
FOR Show = 0 TO 3
 PRINTXT MID$(Txt$, Show * 16 + 1, 16), Show + Lin, 33
NEXT Show
COLOR 15, 1: LOCATE Lin, 49: PRINT LEN(Trl$); "bytes   ";
END SUB

SUB Sketch (Trl$, Clr, Row, Col)

Leng = LEN(Trl$)
IF Leng < 2 THEN EXIT SUB
Row = VAL("&h" + LEFT$(Trl$, 1)): Col = VAL("&h" + MID$(Trl$, 2, 1))

PIXEL Row, Col, Clr
FOR Show = 3 TO Leng
 Dir$ = MID$(Trl$, Show, 1)
 SELECT CASE Dir$
 CASE "U": Row = Row - 1
 CASE "D": Row = Row + 1
 CASE "L": Col = Col - 1
 CASE "R": Col = Col + 1
 END SELECT
 PIXEL Row, Col, Clr
NEXT Show
END SUB

