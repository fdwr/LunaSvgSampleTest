DEFINT A-Z
DECLARE SUB BarMenu (MenuOps$, Choice, Resp, Mode)
DECLARE SUB StatusShow (Message$)
DECLARE SUB BarHelp ()
DECLARE SUB BarStatus (Mode)
DECLARE SUB PROMPT (Frst$, Last$, KeyIn$, KeyOut$, Lim, Vis, row, Col, Curp, Done)
DECLARE SUB PageDrawLine (Trow, Brow, Lcol, Rcol)
DECLARE SUB PageMoveLine (NewRow, NewCol, RelAbs)
DECLARE SUB LinkClosest (TextPos, CurLink)
DECLARE SUB LinkDraw (CurLink, Mode)
DECLARE SUB GetLineInfo (TextLine, LineStart, LineLen)
DECLARE FUNCTION MarkerSelect (Mode)
DECLARE FUNCTION LinkColor (LinkType$)

SCREEN 0: WIDTH 80, 25: VIEW PRINT: LOCATE , , 0, 13, 15: CLS

TYPE LinkSpecs
LinkType AS STRING * 1 'What type of link..Topic,Sound,Picture,Word def
TextStart AS INTEGER     'Where the link that is embeded over the text starts
TextEnd AS INTEGER     'Where the highlit link ends
FilePointer AS LONG    'Where the link leads to in the file, or points to
PointPos AS INTEGER    'Where in the pointed to page, the ofset from the start
END TYPE
'Up to one thousand lines of text can be held, about 22 pages
'LwinPtrs points to each line in the MainText, after it has been wrapped
'by LineWrap subroutine. LwinTextLen tells where the end of the text is
'LwinLastLine is the last line of LwinTextPoint. LwinCurLink is the current
'link that is lit, or active. Pressing ENTER jumps to the data that the link
'points to. LwinPageOfset is the current base line relative to the beginning
'Only twenty links per total page can be held by LwinLinks

CONST LwinTop = 2, LwinBot = 23, LwinLeft = 2, LwinRite = 78, LwinHite = 23, LwinWdth = 77
CONST MTCback = 0, MTCfore = 7, MTCmenu = 3, MTChelp = 1, MenuLine = 1, StatusLine = 24, HelpLine = 25
DIM SHARED LwinText AS STRING * 10000, LwinPtrs(0 TO 511), LwinLinks(0 TO 19) AS LinkSpecs, LwinMarker(0 TO 1)
DIM SHARED LwinTextLen, LwinPageOfset, LwinLastLine, LwinCurLink, LwinOnLink, LwinTotalLinks, LwinRow, LwinCol, LwinPreCol

LwinText = "HelloHow are you?This is a testof the emergencybroadcast systemSee the control characters? 	": LwinLastLine = 7: LwinTextLen = 93

FOR a = 0 TO 7
 READ LwinPtrs(a)
NEXT a
DATA 5,17,17,31,47,63,63,93
FOR a = 0 TO 3
 READ LwinLinks(a).LinkType, LwinLinks(a).TextStart, LwinLinks(a).TextEnd
NEXT a
DATA T,3,9,W,28,32,S,39,57,P,72,90
LwinTotalLinks = 4

MainMenu$ = "Open/Print/Find/Home/Log/Index/Help"
BarMenu MainMenu$, 0, 0, 2
BarStatus 1
BarHelp
StatusShow ""

COLOR MTCmenu, MTCback
FOR Vrow = LwinTop TO LwinBot
 LOCATE Vrow, 1: PRINT "щ";
 LOCATE , 79: PRINT "ч";
NEXT Vrow

LwinPageOfset = 0: LwinMarker(1) = 2
PageMoveLine 1, 6, 0
PageDrawLine LwinTop, LwinBot, Lcol, Rcol
PageMoveLine 0, 0, 1

ScrollPrompt:
DO
 SELECT CASE INKEY$
 CASE CHR$(27): EXIT DO
 CASE CHR$(0) + "H": IF LwinRow > 0 THEN PageMoveLine -1, 0, 1
 CASE CHR$(0) + "P": IF LwinRow < LwinLastLine THEN PageMoveLine 1, 0, 1
 CASE CHR$(0) + "K": IF LwinMarker(0) > 0 THEN PageMoveLine 0, -1, 1
 CASE CHR$(0) + "M": IF LwinMarker(0) < LwinTextLen THEN PageMoveLine 0, 1, 1
 END SELECT
LOOP

'End program

SUB BarHelp
COLOR 15, MTChelp
LOCATE HelpLine, 1: PRINT SPACE$(80);
END SUB

SUB BarMenu (MenuOps$, Choice, Resp, Mode)

'Mode: 0=All off except lit Choice, 1=All on but unlit, >1=Redraw bar back

COLOR , MTCmenu
IF Mode > 1 THEN LOCATE MenuLine, 1: PRINT SPACE$(80);
LOCATE MenuLine, 2: ChoiceBeg = 1: ShowChoice = 0
DO
 ChoiceEnd = INSTR(ChoiceBeg, MenuOps$, "/")
 IF ChoiceEnd = 0 THEN ChoiceLen = LEN(MenuOps$) - ChoiceBeg + 1 ELSE ChoiceLen = ChoiceEnd - ChoiceBeg
 IF Mode AND 1 THEN
  IF Choice = ShowChoice THEN COLOR 15 ELSE COLOR 8
  PRINT MID$(MenuOps$, ChoiceBeg, ChoiceLen);
 ELSEIF ChoiceLen THEN
  COLOR 15: PRINT MID$(MenuOps$, ChoiceBeg, 1);
  COLOR 11: PRINT MID$(MenuOps$, ChoiceBeg + 1, ChoiceLen - 1);
 END IF
 IF ChoiceEnd THEN COLOR 0: PRINT "  ";  ELSE EXIT DO
 ShowChoice = ShowChoice + 1
 ChoiceBeg = ChoiceEnd + 1
LOOP

END SUB

SUB BarStatus (Mode)
IF Mode THEN
 COLOR 0, MTCmenu
 LOCATE StatusLine, 1: PRINT SPACE$(80);
END IF
END SUB

SUB GetLineInfo (TextLine, LineStart, LineLen)

IF TextLine > LwinLastLine THEN LineLen = 0: EXIT SUB
IF TextLine THEN TextPos = LwinPtrs(TextLine - 1) + 1 ELSE TextPos = 1
IF INSTR(TextPos, LwinText, CHR$(13)) THEN LineLen = LwinPtrs(TextLine) - TextPos ELSE LineLen = LwinPtrs(TextLine) - TextPos + 1
IF LineLen < 0 THEN LineLen = 0

END SUB

SUB LineWrap
END SUB

SUB LinkClosest (TextPos, CurLink)

IF TextPos >= LwinLinks(CurLink).TextEnd THEN
 FOR CheckLink = CurLink + 1 TO LwinTotalLinks - 1
  IF LwinLinks(CheckLink).TextEnd > TextPos THEN CurLink = CheckLink: EXIT SUB
 NEXT CheckLink
 CurLink = LwinTotalLinks - 1
ELSEIF TextPos < LwinLinks(CurLink).TextStart THEN
 FOR CheckLink = CurLink - 1 TO 0 STEP -1
  IF LwinLinks(CheckLink).TextEnd <= TextPos THEN EXIT FOR ELSE CurLink = CheckLink: EXIT FOR
 NEXT CheckLink
END IF

END SUB

FUNCTION LinkColor (LinkType$)
 SELECT CASE LinkType$
 CASE "S": LinkColor = 14
 CASE "T": LinkColor = 10
 CASE "P": LinkColor = 9
 CASE "W": LinkColor = 12
 END SELECT
END FUNCTION

SUB LinkDraw (CurLink, Mode)
LOCATE 24, 1: IF Mode THEN PRINT "Cursor on link"; CurLink ELSE PRINT SPACE$(20);
END SUB

SUB LoadFilePage
END SUB

FUNCTION MarkerSelect (Mode)
IF (LwinMarker(0) < LwinMarker(1) AND 1) XOR Mode THEN MarkerSelect = LwinMarker(0) ELSE MarkerSelect = LwinMarker(1)
END FUNCTION

SUB PageDrawLine (Trow, Brow, Lcol, Rcol)

IF Trow < LwinTop THEN Trow = LwinTop
IF Brow > LwinBot THEN Brow = LwinBot

TextLine = Trow - LwinTop + LwinPageOfset
IF TextLine < 1 THEN TextPos = 1 ELSE TextPos = LwinPtrs(TextLine - 1) + 1

FOR CheckLink = 0 TO LwinTotalLinks - 1
 IF LwinLinks(CheckLink).TextStart > TextPos THEN EXIT FOR
 IF LwinLinks(CheckLink).TextEnd > TextPos THEN CurLink = CheckLink: LinkSwitch = 1: EXIT FOR
NEXT CheckLink
NextSwitch = TextPos

DEF SEG = &HB800: COLOR MTCfore, MTCback: LOCATE , , 0
ColorBack = 0: ColorLit = 7
FOR Vrow = Trow TO Brow
 IF TextLine <= LwinLastLine THEN
  IF TextLine THEN TextPos = LwinPtrs(TextLine - 1) + 1 ELSE TextPos = 1
  IF INSTR(TextPos, LwinText, CHR$(13)) THEN LineLen = LwinPtrs(TextLine) - TextPos ELSE LineLen = LwinPtrs(TextLine) - TextPos + 1
  IF LineLen < 0 THEN LineLen = 0 ELSE IF LineLen > LwinWdth THEN LineLen = LwinWdth
  ScreenPos = (Vrow - 1) * 160 + LwinLeft
  FOR Hcol = 1 TO LineLen
   IF TextPos = NextSwitch THEN GOSUB LDLSetNextBreak
   POKE ScreenPos, ASC(MID$(LwinText, TextPos, 1))
   POKE ScreenPos + 1, ColorByte
   TextPos = TextPos + 1
   ScreenPos = ScreenPos + 2
  NEXT Hcol
  TextLine = TextLine + 1
 ELSE LineLen = 0
 END IF
 LOCATE Vrow, LwinLeft + LineLen: PRINT STRING$(LwinWdth - LineLen, 32);
NEXT Vrow
EXIT SUB

LDLSetNextBreak:
 'IF TextPos = MarkBreak THEN
 ' IF BreakAttr AND 1 THEN
 '  MarkBreak = MarkerSelect(1) + 1: BreakAttr = BreakAttr XOR 1
 '  ColorBack = 7: ColorLit = 15: IF ColorFore = 7 THEN ColorFore = 15
 ' ELSE
 '  ColorBack = 0: ColorLit = 7: IF ColorFore = 15 THEN ColorFore = 7
 '  IF TextPos < MarkerSelect(0) THEN MarkBreak = MarkerSelect(0): BreakAttr = BreakAttr OR 1 ELSE MarkBreak = LwinTextLen + 1
 ' END IF
 'END IF
 'yes=link text, no=normal text
 IF LinkSwitch THEN
  ColorFore = LinkColor(LwinLinks(CurLink).LinkType)
  NextSwitch = LwinLinks(CurLink).TextEnd
  LinkSwitch = 0
 ELSE
  NextSwitch = LwinTextLen + 1
  IF CurLink < LwinTotalLinks THEN
   FOR CheckLink = CurLink TO LwinTotalLinks - 1
    IF LwinLinks(CheckLink).TextStart > TextPos THEN CurLink = CheckLink: NextSwitch = LwinLinks(CheckLink).TextStart: LinkSwitch = 1: EXIT FOR
   NEXT CheckLink
  END IF
  ColorFore = ColorLit
 END IF
 ColorByte = ColorFore OR ColorBack * 16
RETURN

END SUB

SUB PageMoveLine (NewRow, NewCol, RelAbs)
'PageLine can either be a relative move or an absolute move, which is
'determined by RelAbs.
'If cursor position can not be moved, then exit sub
'However, if absolute, then relocate cursor
'If on relative then check shift key, if down then strech highlight marker
'else if up and highlight is streched then dehighlight marker
'If link found at cursor, then set LwinOnLink to TRUE and LwinCurLink to it
'If moved while on link, check to see if still on it, delight if off
'If moved while off link, check to see if on one, light if on
'Call StatusShow so that the new position and link type can be shown

IF RelAbs THEN
 IF SGN(NewCol) = 1 AND LwinMarker(0) < LwinTextLen THEN
  GetLineInfo LwinRow, 0, LineLen
  LwinCol = LwinCol + NewCol
  IF LwinCol > LineLen THEN LwinCol = 0: NewRow = NewRow + 1
 ELSEIF SGN(NewCol) = -1 AND LwinMarker(0) > 0 THEN
  LwinCol = LwinCol + NewCol
  IF LwinCol < 0 THEN GetLineInfo LwinRow - 1, 0, LineLen: LwinCol = LineLen: NewRow = NewRow - 1
 END IF
 IF NewCol THEN LwinPreCol = LwinCol
 IF SGN(NewRow) = 1 AND LwinRow < LwinLastLine THEN
  LwinRow = LwinRow + NewRow
  IF LwinRow > LwinLastLine THEN LwinRow = LwinLastLine
 ELSEIF SGN(NewRow) = -1 AND LwinRow > 0 THEN
  LwinRow = LwinRow + NewRow
  IF LwinRow < 0 THEN LwinRow = 0
 END IF
 IF NewRow THEN
  GetLineInfo LwinRow, 0, LineLen
  IF LwinCol = LwinPreCol AND LwinCol > LineLen THEN LwinPreCol = LwinCol
  LwinCol = LwinPreCol: IF LwinCol > LineLen THEN LwinCol = LineLen
 END IF
ELSE
 LwinCol = NewCol: LwinPreCol = LwinCol: LwinRow = NewRow
END IF
'If the cursor is off screen, adjust LwinPageOfset so that it is on screen
'If vertical difference is less than page height then call ScrollScrBlock and
'scroll the screen the desired amount. Then draw bottom or top line by calling
'PageDrawLine

IF LwinRow THEN LwinMarker(0) = LwinPtrs(LwinRow - 1) + LwinCol ELSE LwinMarker(0) = LwinCol
TextPos = LwinMarker(0) + 1
: LOCATE 24, 21: PRINT LwinRow; ":"; LwinCol; "="; LwinMarker(0); "("; MID$(LwinText, TextPos, 1); ")"; "   ";
IF LwinOnLink THEN
 IF TextPos < LwinLinks(LwinCurLink).TextStart OR TextPos >= LwinLinks(LwinCurLink).TextEnd THEN LinkDraw LwinCurLink, 0: StatusShow " ": LwinOnLink = 0
END IF
IF LwinOnLink = 0 THEN
 LinkClosest TextPos, LwinCurLink
 IF TextPos >= LwinLinks(LwinCurLink).TextStart AND TextPos < LwinLinks(LwinCurLink).TextEnd THEN LinkDraw LwinCurLink, 1: StatusShow "": LwinOnLink = 1
END IF
Vrow = LwinRow - LwinPageOfset + LwinTop
LOCATE Vrow, LwinCol + LwinLeft, 1

END SUB

SUB PROMPT (Frst$, Last$, KeyIn$, KeyOut$, Lim, Vis, row, Col, Curp, Done)
IF row = 0 THEN row = CSRLIN
IF Col = 0 THEN Col = POS(0)
IF Curp = -1 THEN Curp = LEN(Frst$)
Rslt$ = Frst$
Chng = 1
kbrd$ = KeyIn$

DO
 leng = LEN(Rslt$)
 SELECT CASE kbrd$
 CASE ""
 CASE " " TO "Ъ": GOSUB PromptInsert: Chng = 1
 CASE CHR$(0) + "S": IF Curp < leng AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp) + RIGHT$(Rslt$, leng - Curp - 1): Chng = 1
 CASE CHR$(8): IF Curp > 0 AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp - 1) + RIGHT$(Rslt$, leng - Curp): Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "K": IF Curp > 0 THEN Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "M": IF Curp < leng THEN Curp = Curp + 1: Chng = 1
 CASE CHR$(0) + "G": Curp = 0: Chng = 1
 CASE CHR$(0) + "O": Curp = leng: Chng = 1
 CASE ELSE: KeyOut$ = kbrd$: Done = 1
 END SELECT

 IF Chng THEN
  leng = LEN(Rslt$)
  IF Curp > leng THEN Curp = leng ELSE IF Curp < 0 THEN Curp = 0
  IF Curp < Ofst THEN Ofst = Curp ELSE IF Curp >= Ofst + Vis THEN Ofst = Curp - Vis + 1
  LOCATE , , 0: LOCATE row, Col: PRINT MID$(Rslt$ + SPACE$(Vis), Ofst + 1, Vis);
  LOCATE , , 1: LOCATE row, Col + (Curp - Ofst)
  Chng = 0
 END IF

 kbrd$ = INKEY$
LOOP UNTIL Done

Last$ = Rslt$
EXIT SUB

PromptInsert:
 IF LEN(kbrd$) + LEN(Rslt$) > Lim THEN SOUND 860, .1: RETURN
 Rslt$ = LEFT$(Rslt$, Curp) + kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - Curp)
 Curp = Curp + 1
RETURN
END SUB

SUB ScrollScrBlock (Trow, Brow, Lcol, Rcol, ScrollDif)

END SUB

SUB StatusShow (Message$)
'If a message is included, then print the message
'else print the type of current link spot and approximate page number
'example: "Loading" or "Formatting" or "Playing"
'example: "Line 10    Ч))) Short Song" or "Line 203   AB=CD Word def"
'S=Song T=Text P=Picture W=Word def

IF Message$ = "" THEN
 SELECT CASE LwinLinks(LwinCurLink).LinkType
 CASE "S": Message$ = "Ч))) Short Song"
 CASE "T": Message$ = "ABC.. Text Topic"
 CASE "P": Message$ = "зад©Ё Picture"
 CASE "W": Message$ = "AB=CD Word Definition"
 END SELECT
 COLOR LinkColor(LwinLinks(LwinCurLink).LinkType)
ELSE COLOR 15
END IF

LOCATE MenuLine, 55: COLOR , MTCmenu
IF LEN(Message$) > 25 THEN PRINT LEFT$(Message$, 25);  ELSE PRINT SPACE$(25 - LEN(Message$)); Message$;
'The pointer always says what type of data the link takes the user to, however
'it is theoretically possible for the data to show a type that the data is
'actually not. The type that the link claims the data to be, does not
'determine the actual type. The actual type is determined from the location
'in file that is pointed to, and the link is usually concurrent; however,
'if some 'mutation' were to occur, the link could say that it pointed to a
'picture when it would really play a song!

'Last but not least, draw a scrollbar so that the user will know where he is
'at in the document

END SUB

