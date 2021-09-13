DEFINT A-Z
DECLARE FUNCTION FillIn00$ (Number, Places)
DECLARE SUB DefScroll (Scroll(), Row1, Row2, Col1, Col2, UpDn, Colr)
DECLARE SUB HelpLineMake ()
DECLARE SUB HelpLine (Row, Col, PictCurs(), PictCursAttr)
DECLARE SUB PutTextChar (Row, Col, PictCurs(), PictCursAttr, PictCursMask)
DECLARE SUB PutPictCurs (Row, Col)
DECLARE SUB MovePictCursDown (Row, Col)
DECLARE SUB MovePictCursUp (Row, Col)
DECLARE SUB TextPictRow (Row)
DECLARE SUB TextPictScreen ()

DIM SHARED MainTextPict(0 TO 3999), TextPictTopRow, TextPictLowRow, TextPictLefCol, TextPictRitCol, TextPictHite, TextPictWdth, TextPictOfset, PictCurs(0 TO 3), MovePictDown(1 TO 7), MovePictUp(1 TO 7)
TextPictTopRow = 1: TextPictLowRow = 23: TextPictLefCol = 0: TextPictRitCol = 79
TextPictHite = TextPictLowRow - TextPictTopRow + 1: TextPictWdth = TextPictRitCol - TextPictLefCol + 1
DefScroll MovePictDown(), TextPictTopRow, TextPictLowRow, TextPictLefCol, TextPictRitCol, 1, 0
DefScroll MovePictUp(), TextPictTopRow, TextPictLowRow, TextPictLefCol, TextPictRitCol, -1, 0
DEF SEG = &HB800
FOR ByteOfset = 0 TO 3999 STEP 2
 MainTextPict(ByteOfset) = PEEK(ByteOfset)
 MainTextPict(ByteOfset + 1) = PEEK(ByteOfset + 1)
NEXT ByteOfset

TextPictScreen
PictCursAttr = 8: PictCurs(1) = 11: PictCurs(2) = 2
HelpLineMake
HelpLine CursRow, CursCol, PictCurs(), PictCursAttr
PutPictCurs CursRow, CursCol
LOCATE , , , 12, 14

DO
 kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE ""
 CASE " " TO "џ"
  PictCurs(0) = ASC(kbrd$): PutTextChar CursRow, CursCol, PictCurs(), PictCursAttr, 1: UpdateInfo = 1
 CASE CHR$(0) + "H": MovePictCursUp CursRow, CursCol: GOSUB CursTrails: UpdateInfo = 1
 CASE CHR$(0) + "P": MovePictCursDown CursRow, CursCol: GOSUB CursTrails: UpdateInfo = 1
 CASE CHR$(0) + "K": IF CursCol > 0 THEN CursCol = CursCol - 1: GOSUB CursTrails: UpdateInfo = 1
 CASE CHR$(0) + "M": IF CursCol < 79 THEN CursCol = CursCol + 1: GOSUB CursTrails: UpdateInfo = 1
 CASE CHR$(0) + "R": UpdateInfo = 1: IF PictCursAttr AND 16 THEN PictCursAttr = PictCursAttr XOR 16: LOCATE , , , 12, 14 ELSE PictCursAttr = PictCursAttr OR 16: LOCATE , , , 2, 13
 CASE CHR$(0) + ".": PictCursAttr = PictCursAttr XOR 1: GOSUB CursTrails: UpdateInfo = 1
 CASE CHR$(0) + "!": PictCursAttr = PictCursAttr XOR 2: GOSUB CursTrails: UpdateInfo = 1
 CASE CHR$(0) + "0": PictCursAttr = PictCursAttr XOR 4: GOSUB CursTrails: UpdateInfo = 1
 CASE CHR$(0) + CHR$(31): GOSUB SavePict: HelpLineMake: UpdateInfo = 1
 CASE CHR$(0) + "&": GOSUB LoadPict: HelpLineMake: UpdateInfo = 1
 CASE ELSE
  IF PictCursAttr AND 16 AND kbrd$ < "џ" THEN
   PictCurs(0) = ASC(kbrd$): PutTextChar CursRow, CursCol, PictCurs(), PictCursAttr, 1: PictCursAttr = PictCursAttr XOR 16: LOCATE , , , 12, 14: UpdateInfo = 1
  ELSE
   SELECT CASE kbrd$
   CASE "": EXIT DO
   CASE CHR$(9): GOSUB CursorMenu: UpdateInfo = 1
   CASE CHR$(13): UpdateInfo = 1: IF PictCursAttr AND 8 THEN PictCursAttr = PictCursAttr XOR 8 ELSE PictCursAttr = PictCursAttr OR 8: GOSUB CursTrails
   END SELECT
  END IF
 END SELECT
 IF UpdateInfo THEN HelpLine CursRow, CursCol, PictCurs(), PictCursAttr: PutPictCurs CursRow, CursCol: UpdateInfo = 0
LOOP

DEF SEG = &HB800
FOR ByteOfset = 0 TO 3999 STEP 2
 POKE ByteOfset, MainTextPict(ByteOfset)
 POKE ByteOfset + 1, MainTextPict(ByteOfset + 1)
NEXT ByteOfset
SYSTEM

CursTrails:
 IF PictCursAttr AND 8 THEN PutTextChar CursRow, CursCol, PictCurs(), PictCursAttr, 0
RETURN

CursorMenu:
 LOCATE 9, 24, 0: COLOR 15, 3: PRINT "        ASCII Cursor Menu         ";
 LOCATE 17, 24: PRINT SPACE$(34);
 COLOR 3, 7
 FOR Row = 10 TO 16
  LOCATE Row, 24: PRINT "н"; SPACE$(32); "о";
 NEXT Row
 Choice$(0) = "Character"
 Choice$(1) = "Foreground"
 Choice$(2) = "Background"
 FOR CursAttrShow = 0 TO 2
  IF PictCursAttr AND 2 ^ CursAttrShow THEN COLOR 15, 7 ELSE COLOR 0, 7
  LOCATE CursAttrShow * 2 + 11, 27: PRINT Choice$(CursAttrShow);
  GOSUB CursorMenuShow
 NEXT CursAttrShow
 CursAttrShow = CursAttr
 DO
  kbrd$ = INKEY$
  SELECT CASE kbrd$
  CASE CHR$(27), CHR$(13): EXIT DO
  CASE CHR$(0) + "H": CursAttr = (CursAttr + 5) MOD 3: GOSUB CursorMenuShow: CursAttrShow = CursAttr: GOSUB CursorMenuShow
  CASE CHR$(0) + "P": CursAttr = (CursAttr + 1) MOD 3: GOSUB CursorMenuShow: CursAttrShow = CursAttr: GOSUB CursorMenuShow
  CASE CHR$(0) + "K"
   IF PictCurs(CursAttr) > 0 THEN PictCurs(CursAttr) = PictCurs(CursAttr) - 1
   GOSUB CursorMenuShow
  CASE CHR$(0) + "M"
   IF CursAttr THEN IF PictCurs(CursAttr) < 15 THEN PictCurs(CursAttr) = PictCurs(CursAttr) + 1 ELSE  ELSE IF PictCurs(0) < 255 THEN PictCurs(0) = PictCurs(0) + 1
   GOSUB CursorMenuShow
  CASE "0" TO "9"
   IF CursAttr = 0 THEN PictCurs(0) = VAL(STR$(PictCurs(0)) + kbrd$): IF PictCurs(0) > 255 THEN PictCurs(0) = 255
   GOSUB CursorMenuShow
  CASE ""
   IF CursAttr = 0 THEN PictCurs(0) = VAL(LEFT$(STR$(PictCurs(0)), LEN(STR$(PictCurs(0))) - 1)): GOSUB CursorMenuShow
  CASE "A" TO "Z"
   IF CursAttrColr > 0 AND INSTR("dbgsrpywDBGSRPYW", kbrd$) THEN PictCurs(CursAttr) = INSTR("dbgsrpywDBGSRPYW", kbrd$) - 1: GOSUB CursorMenuShow
  CASE " "
   PictCursAttr = PictCursAttr XOR 2 ^ CursAttr
   LOCATE CursAttr * 2 + 11, 27: IF PictCursAttr AND 2 ^ CursAttr THEN COLOR 15, 7 ELSE COLOR 0, 7
   PRINT Choice$(CursAttr);
  END SELECT
 LOOP
 FOR Row = 7 TO 15
  TextPictRow Row + TextPictOfset
 NEXT Row
RETURN
CursorMenuShow:
 SELECT CASE CursAttrShow
 CASE 0
  LOCATE 11, 38: COLOR 15, 7: PRINT STR$(PictCurs(0)); TAB(43); "( )";
  DEF SEG = &HB800: POKE 1686, PictCurs(0)
 CASE 1, 2
  Row = CursAttrShow * 2 + 11
  FOR Col = 0 TO 15
   LOCATE Row + 1, Col + 39: COLOR 15, 7: IF PictCurs(CursAttrShow) = Col THEN PRINT "^";  ELSE PRINT " ";
   LOCATE Row, Col + 39: COLOR Col: PRINT "л";
  NEXT Col
 END SELECT
 LOCATE CursAttrShow * 2 + 11, 26: COLOR 15, 7: IF CursAttrShow = CursAttr THEN PRINT "";  ELSE PRINT " ";
RETURN

SavePict:
LOCATE 25, 1: COLOR 15, 3: PRINT SPACE$(80);
LOCATE 25, 1: LINE INPUT ; "Save to file:"; File$
IF File$ = "" THEN RETURN
FilErr = 0: ON ERROR GOTO FilErrHan
OPEN File$ FOR OUTPUT AS #1
IF FilErr THEN
 LOCATE 25, 1: PRINT "Error saving file"; TAB(80); " ";
 WHILE INKEY$ = "": WEND
ELSE
 FOR ByteOfset = 0 TO 3999 STEP 2
  PRINT #1, CHR$(MainTextPict(ByteOfset)); CHR$(MainTextPict(ByteOfset + 1));
 NEXT ByteOfset
END IF
ON ERROR GOTO 0
CLOSE #1
RETURN

LoadPict:
LOCATE 25, 1: COLOR 15, 3: PRINT SPACE$(80);
LOCATE 25, 1: LINE INPUT ; "Load from file:"; File$
IF File$ = "" THEN RETURN
FilErr = 0: ON ERROR GOTO FilErrHan
OPEN File$ FOR INPUT AS #1: CLOSE #1
IF FilErr = 0 THEN OPEN File$ FOR BINARY AS #1
IF LOF(1) < 4000 THEN FilErr = 180
IF FilErr THEN
 LOCATE 25, 1: PRINT "Error loading specified file"; TAB(80); " ";
 WHILE INKEY$ = "": WEND
ELSE
 File$ = INPUT$(4000, 1)
 FOR ByteOfset = 0 TO 3999 STEP 2
  MainTextPict(ByteOfset) = ASC(MID$(File$, ByteOfset + 1, 1))
  MainTextPict(ByteOfset + 1) = ASC(MID$(File$, ByteOfset + 2, 1))
 NEXT ByteOfset
 TextPictScreen
END IF
ON ERROR GOTO 0
CLOSE #1
RETURN

FilErrHan:
FilErr = ERR
RESUME NEXT

SUB DefScroll (Scroll(), Row1, Row2, Col1, Col2, UpDn, Colr)
P = VARPTR(Scroll(1)): DEF SEG = VARSEG(Scroll(1))
POKE P, &HB8: POKE P + 1, ABS(UpDn)
IF SGN(UpDn) = -1 THEN POKE P + 2, &H6 ELSE POKE P + 2, &H7
POKE P + 3, &HB9: POKE P + 4, Col1: POKE P + 5, Row1: POKE P + 6, &HBA
POKE P + 7, Col2: POKE P + 8, Row2: POKE P + 9, &HB7: POKE P + 10, Colr
POKE P + 11, &HCD: POKE P + 12, &H10: POKE P + 13, &HCB
END SUB

FUNCTION FillIn00$ (Number, Places)
FillIn00$ = RIGHT$(STRING$(Places, "0") + LTRIM$(STR$(Number)), Places)
END FUNCTION

SUB HelpLine (Row, Col, PictCurs(), PictCursAttr)

COLOR 15, 3
IF Row > -1 THEN LOCATE 25, 2: PRINT FillIn00(Row, 2);
IF Col > -1 THEN LOCATE , 5: PRINT FillIn00(Col, 2);

GOSUB InfoLineColor: LOCATE 25, 10: PRINT "Character ( )";
GOSUB InfoLineColor: LOCATE , 26: PRINT "Foreground";
GOSUB InfoLineColor: LOCATE , 40: PRINT "Background";
GOSUB InfoLineColor: LOCATE , 54: PRINT "Draw On";
GOSUB InfoLineColor: LOCATE , 64: PRINT "Insert";

DEF SEG = &HB800: POKE 3880, PictCurs(0)
LOCATE , 37: COLOR PictCurs(1), 0: PRINT "он";
LOCATE , 51: COLOR PictCurs(2): PRINT "он";

EXIT SUB
InfoLineColor:
 IF PictCursAttr AND 2 ^ SwitchCounter THEN COLOR 15 ELSE COLOR 0
 SwitchCounter = SwitchCounter + 1
RETURN
END SUB

SUB HelpLineMake
LOCATE 25, 1: COLOR 0, 3: PRINT "   :   Г               Г            но            но         Г"; SPACE$(18);
END SUB

SUB MovePictCursDown (Row, Col)

IF Row < 24 THEN Row = Row + 1
IF Row >= TextPictOfset + TextPictHite THEN
 DEF SEG = VARSEG(MovePictUp(1)): CALL absolute(VARPTR(MovePictUp(1)))
 TextPictOfset = Row - TextPictHite + 1
 TextPictRow Row
END IF
PutPictCurs Row, Col
END SUB

SUB MovePictCursUp (Row, Col)

IF Row > 0 THEN Row = Row - 1
IF Row < TextPictOfset THEN
 DEF SEG = VARSEG(MovePictDown(1)): CALL absolute(VARPTR(MovePictDown(1)))
 TextPictOfset = Row
 TextPictRow Row
END IF
PutPictCurs Row, Col
END SUB

SUB PutPictCurs (Row, Col)
IF Row < TextPictOfset THEN LOCATE , , 0: EXIT SUB
IF Row - TextPictOfset > TextPictHite THEN LOCATE , , 0: EXIT SUB
LOCATE Row - TextPictOfset + TextPictTopRow + 1, Col + 1, 1
END SUB

SUB PutTextChar (Row, Col, PictCurs(), PictCursAttr, PictCursMask)

Curs = Row * 160 + (Col * 2)
IF (PictCursAttr OR PictCursMask) AND 1 THEN MainTextPict(Curs) = PictCurs(0)
IF (PictCursAttr OR PictCursMask) AND 2 THEN MainTextPict(Curs + 1) = (MainTextPict(Curs + 1) AND 240) OR PictCurs(1)
IF (PictCursAttr OR PictCursMask) AND 4 THEN MainTextPict(Curs + 1) = (MainTextPict(Curs + 1) AND 15) OR (PictCurs(2) * 16)

IF Row < TextPictOfset OR Row - TextPictOfset >= TextPictHite THEN EXIT SUB
DEF SEG = &HB800
CharOfset = Row * 160 + (Col * 2)
ByteOfset = (Row - TextPictOfset + TextPictTopRow) * 160 + (Col * 2)
POKE ByteOfset, MainTextPict(CharOfset)
POKE ByteOfset + 1, MainTextPict(CharOfset + 1)

END SUB

SUB TextPictRow (Row)
IF Row < TextPictOfset OR Row - TextPictOfset >= TextPictHite THEN EXIT SUB
DEF SEG = &HB800
CharOfset = Row * 160
ByteOfset = (Row - TextPictOfset + TextPictTopRow) * 160
FOR Char = CharOfset TO CharOfset + 159 STEP 2
 POKE ByteOfset, MainTextPict(Char)
 POKE ByteOfset + 1, MainTextPict(Char + 1)
 ByteOfset = ByteOfset + 2
NEXT Char
END SUB

SUB TextPictScreen
FOR Row = TextPictOfset TO TextPictOfset + TextPictHite
 TextPictRow Row
NEXT
END SUB

