'Aug 1997+
DEFINT A-Z
DECLARE SUB CreateMask (Image$, CurDrawColor%)
DECLARE SUB MouseDriver (ax%, bx%, cx%, dx%)
DECLARE SUB ColorScale (Image$)
DECLARE SUB DrawBorder (Urow, Drow, Lcol, Rcol, Mode)
DECLARE SUB DrawOptionBox (Ulin, Dlin, Llin, Rlin, Mode)
DECLARE SUB ShowKeyOption (Text$, ColorBack, leng)
DECLARE SUB MainCursorDraw (ShowHide)
DECLARE SUB MainCursorMove (CursorRow, CursorCol)
DECLARE SUB ImageSave (FileName$, FileEntry, Image$, PictWdth, PictWdth)
DECLARE SUB ImageLoad (FileName$, FileEntry, Image$, PictHite, PictWdth)
DECLARE SUB ReCalcPictSize (MaxUrow, MaxDrow, MaxLcol, MaxRcol, Hite, Wdth, Urow, Drow, Lcol, Rcol, StretchHite, StretchWdth, StretchMode)
DECLARE SUB DrawPictImage (Image$, Urow, Drow, Lcol, Rcol, PictHite, PictWdth, StretchMode)
DECLARE SUB DrawPictDot (Image$, Urow, Drow, Lcol, Rcol, PictHite, PictWdth, PictRow, PictCol, StretchMode)
DECLARE SUB ShowMenuChoices (MenuChoice)
DECLARE SUB GetUserSize (Image$, PictHite, PictWdth, ColorBack)
DECLARE SUB SetImageSize (Image$, PictHite, PictWdth, StretchHite, StretchWdth, ColorBack)
DECLARE SUB BasicHelp ()
DECLARE SUB SelectColor (ColorFore)
DECLARE SUB LineInsert (Image$, PictRow, PictCol)
DECLARE SUB LineDelete (Image$, PictRow, PictCol)
DECLARE FUNCTION GetFilName (File$, LastEntry, entry, Mode)
DECLARE FUNCTION NoFileExtension (File$)
DECLARE FUNCTION ImageSpecs (LastEntry, PictHite, PictWdth)

CONST MAXcolor = 215, ColorLight = 172, ColorSolid = 129, ColorShadow = 86, ColorText = 165, ColorShades = 6, HighestShade = ColorShades - 1
DIM SHARED FilErr, CurFile$, MainCursorRow, MainCursorCol, PictWinResize, NewFile, mousecode$
DIM SHARED MainCursorAndPict(0 TO 33), MainCursorOrPict(0 TO 33), MainCursorScrn(0 TO 33), ToolPicts(0 TO 253, 0 TO 4)
mousecode$ = SPACE$(57)
FOR ReadPos = 1 TO 57
  READ char$
  MID$(mousecode$, ReadPos, 1) = CHR$(VAL("&H" + char$))
NEXT ReadPos
DATA 55,89,E5,8B,5E,0C,8B,07,50,8B,5E,0A,8B,07,50,8B
DATA 5E,08,8B,0F,8B,5E,06,8B,17,5B,58,1E,07,CD,33,53
DATA 8B,5E,0C,89,07,58,8B,5E,0A,89,07,8B,5E,08,89,0F
DATA 8B,5E,06,89,17,5D,CA,08,00
mousepresent = 0
MouseDriver mousepresent, 0, 0, 0

FOR ReadPos = 0 TO 33: READ MainCursorAndPict(ReadPos): NEXT ReadPos: FOR ReadPos = 0 TO 33: READ MainCursorOrPict(ReadPos): NEXT ReadPos
FOR ActiveTool = 0 TO 2: FOR ReadPos = 0 TO 253 STEP 2: READ ToolPicts(ReadPos, ActiveTool), ToolPicts(ReadPos + 1, ActiveTool): NEXT ReadPos: NEXT ActiveTool

GOSUB SetScreenAndColors

PictHite = 10: PictWdth = 20: PictRow = 4: PictCol = 9
Image$ = STRING$(PictHite * PictWdth, 0)
ActiveTool = 0: StretchMode = 1: PictWinResize = 1: CurDrawColor = MAXcolor
GOSUB WindowsRedraw

PictWinEdit:
 IF PictWinResize THEN ReCalcPictSize 17, 156, 49, 310, PictHite, PictWdth, PictWinUrow, PictWinDrow, PictWinLcol, PictWinRcol, StretchHite, StretchWdth, StretchMode: PictWinResize = 0
 ActiveWindow = 0
 GOSUB PictWinPutCursor
 DO
  kbrd$ = INKEY$
  SELECT CASE kbrd$
  CASE ""
  CASE CHR$(0) + "H": IF PictRow > 0 THEN PictRow = PictRow - 1: GOSUB PictWinCheckDir: GOSUB PictWinPutCursor
  CASE CHR$(0) + "P": IF PictRow < PictHite - 1 THEN PictRow = PictRow + 1: GOSUB PictWinCheckDir: GOSUB PictWinPutCursor
  CASE CHR$(0) + "K": IF PictCol > 0 THEN PictCol = PictCol - 1: GOSUB PictWinCheckDir: GOSUB PictWinPutCursor
  CASE CHR$(0) + "M": IF PictCol < PictWdth - 1 THEN PictCol = PictCol + 1: GOSUB PictWinCheckDir: GOSUB PictWinPutCursor
  CASE CHR$(0) + "S": LineDelete Image$, PictRow, PictCol
  CASE CHR$(0) + "R": LineInsert Image$, PictRow, PictCol
  CASE " ": GOSUB ToolsDo
  CASE CHR$(9): GOTO ColorChoose
  CASE ELSE: GOSUB MenuChoices
  END SELECT
 LOOP
RETURN
PictWinCheckDir:
 IF ActiveTool = 0 THEN DEF SEG = 0: IF PEEK(1047) AND 3 THEN GOSUB ToolsDo
RETURN
PictWinPutCursor:
 IF StretchMode THEN
  row = StretchHite * (PictRow + .5) \ PictHite + PictWinUrow
  col = StretchWdth * (PictCol + .5) \ PictWdth + PictWinLcol
  MainCursorMove row, col
 ELSE
  MainCursorMove PictWinUrow + PictRow, PictWinLcol + PictCol
 END IF
RETURN
PictWinDraw:
 IF ActiveWindow = 0 THEN MainCursorDraw 0
 IF PictWinResize THEN
  ReCalcPictSize 17, 156, 49, 310, PictHite, PictWdth, PictWinUrow, PictWinDrow, PictWinLcol, PictWinRcol, StretchHite, StretchWdth, StretchMode: PictWinResize = 0
  IF PictRow >= PictHite THEN PictRow = PictHite - 1
  IF PictCol >= PictWdth THEN PictCol = PictWdth - 1
 END IF
 DrawBorder PictWinUrow - 1, PictWinDrow + 1, PictWinLcol - 1, PictWinRcol + 1, 0
 LINE (47, 15)-(312, PictWinUrow - 2), ColorSolid, BF
 LINE (47, PictWinUrow - 1)-(PictWinLcol - 2, PictWinDrow + 1), ColorSolid, BF
 LINE (PictWinRcol + 2, PictWinUrow - 1)-(312, PictWinDrow + 1), ColorSolid, BF
 LINE (47, PictWinDrow + 2)-(312, 158), ColorSolid, BF
 DrawPictImage Image$, PictWinUrow, PictWinDrow, PictWinLcol, PictWinRcol, PictHite, PictWdth, StretchMode
 IF ActiveWindow = 0 THEN GOSUB PictWinPutCursor
RETURN

ToolsChoose:
 ActiveWindow = 1
 GOSUB ToolsPutCursor
 DO
  kbrd$ = INKEY$
  SELECT CASE kbrd$
  CASE ""
  CASE CHR$(0) + "H": IF ActiveTool > 0 THEN ActiveTool = ActiveTool - 1: GOSUB ToolsDraw: GOSUB ToolsPutCursor:
  CASE CHR$(0) + "P": IF ActiveTool < 4 THEN ActiveTool = ActiveTool + 1: GOSUB ToolsDraw: GOSUB ToolsPutCursor:
  CASE CHR$(13), CHR$(9): GOTO PictWinEdit
  CASE ELSE: GOSUB MenuChoices
  END SELECT
 LOOP
RETURN
ToolsPutCursor:
 MainCursorMove ActiveTool * 22 + 45, 35
RETURN
ToolsDraw:
 IF ActiveWindow = 1 THEN MainCursorDraw 0
 IF DrawAll THEN
  DrawBorder 14, 24, 6, 40, 2
  DrawBorder 27, 138, 6, 40, 0
  Urow = 30
  FOR LastActiveTool = 0 TO 2 '30 188
   PUT (10, Urow), ToolPicts(0, LastActiveTool), PSET
   Urow = Urow + 22
  NEXT LastActiveTool
 ELSEIF LastActiveTool <> ActiveTool THEN
  Urow = 28 + LastActiveTool * 22
  LINE (7, Urow)-(39, Urow + 21), ColorSolid, B
 END IF
 LOCATE 3, 2: ShowKeyOption MID$("_Draw_Fill_Cut _Line_Eye ", ActiveTool * 5 + 1, 5), ColorText, 0
 Urow = 28 + ActiveTool * 22
 DrawBorder Urow, Urow + 21, 7, 39, 1
 LastActiveTool = ActiveTool
 IF ActiveWindow = 1 THEN GOSUB ToolsPutCursor
RETURN
ToolsDo:
 SELECT CASE ActiveTool
 CASE 0
  ReadPos = PictRow * PictWdth + PictCol + 1
  IF MID$(Image$, ReadPos, 1) <> CHR$(CurDrawColor) THEN MID$(Image$, ReadPos, 1) = CHR$(CurDrawColor) ELSE RETURN
  MainCursorDraw 0
  DrawPictDot Image$, PictWinUrow, PictWinDrow, PictWinLcol, PictWinRcol, PictHite, PictWdth, PictRow, PictCol, StretchMode
  MainCursorDraw 1
 CASE 4
  CurDrawColor = ASC(MID$(Image$, PictRow * PictWdth + PictCol + 1, 1))
  GOSUB ColorsDraw
 END SELECT
RETURN
     
ColorChoose:
 ActiveWindow = 2
 GOSUB ColorsPutCursor
 DO
  kbrd$ = INKEY$
  SELECT CASE kbrd$
  CASE ""
  CASE CHR$(0) + "H": IF CurDrawColor > 0 THEN CurDrawColor = CurDrawColor - 1: GOSUB ColorsDraw: GOSUB ColorsPutCursor
  CASE CHR$(0) + "P": IF CurDrawColor < MAXcolor THEN CurDrawColor = CurDrawColor + 1: GOSUB ColorsDraw: GOSUB ColorsPutCursor
  CASE CHR$(0) + "K": IF CurDrawColor > HighestShade THEN CurDrawColor = CurDrawColor - 6: GOSUB ColorsDraw: GOSUB ColorsPutCursor
  CASE CHR$(0) + "M": IF CurDrawColor < MAXcolor - HighestShade THEN CurDrawColor = CurDrawColor + 6: GOSUB ColorsDraw: GOSUB ColorsPutCursor
  CASE CHR$(13): GOTO PictWinEdit
  CASE " ": SelectColor CurDrawColor: GOSUB ColorsDraw: GOSUB PictWinDraw
  CASE CHR$(9): GOTO ToolsChoose
  CASE ELSE: GOSUB MenuChoices
  END SELECT
 LOOP
RETURN
ColorsPutCursor:
 Urow = 167 + (LastDrawColor MOD 6) * 3: Lcol = 29 + (LastDrawColor \ 6) * 8
 MainCursorMove Urow, Lcol
RETURN
ColorsDraw:
 IF ActiveWindow = 2 THEN MainCursorDraw 0
 IF DrawAll THEN
  DrawBorder 165, 184, 24, 313, 0
  DrawBorder 165, 184, 6, 21, 0
  'FOR row = 167 TO 183 STEP 9
  ' FOR col = 26 TO 312 STEP 9
  '  LINE (col, row)-(col + 6, row + 6), PixColor, BF
  '  PixColor = PixColor + 1
  ' NEXT col
  'NEXT row
  prerow = 166: row = prerow: rowof = 0: precol = 25: col = precol
  FOR PixColor = 0 TO MAXcolor
   LINE (col, row + rowof)-(col + 7, row + rowof + 2), PixColor, BF
   IF rowcnt >= 5 THEN row = prerow: rowcnt = 0: col = col + 8 ELSE rowcnt = rowcnt + 1: row = row + 3
  NEXT PixColor
 ELSEIF LastDrawColor <= MAXcolor THEN
  Urow = 166 + (LastDrawColor MOD 6) * 3: Lcol = 25 + (LastDrawColor \ 6) * 8
  LINE (Lcol, Urow)-(Lcol + 7, Urow + 2), LastDrawColor, B
 END IF
 LastDrawColor = CurDrawColor
 LINE (7, 166)-(20, 183), CurDrawColor, BF
 IF CurDrawColor > MAXcolor THEN RETURN
 Urow = 166 + (CurDrawColor MOD 6) * 3: Lcol = 25 + (CurDrawColor \ 6) * 8
 DrawBorder Urow, Urow + 2, Lcol, Lcol + 7, 1 '21845
 IF ActiveWindow = 2 THEN GOSUB ColorsPutCursor
RETURN

MenuChoices:
 SELECT CASE UCASE$(kbrd$)
 CASE CHR$(27): WIDTH 80, 25: COLOR 7, 0: CLS : END
 CASE "V": GOSUB ViewPict
 CASE "N": Image$ = STRING$(PictHite * PictWdth, CurDrawColor): PictWinResize = 1: NewFile = 1
 CASE "M": StretchMode = StretchMode XOR 1: PictWinResize = 1
 CASE "G": ShowMenuChoices 1: ImageLoad CurFile$, FileEntry, Image$, PictHite, PictWdth: ShowMenuChoices 0
 CASE "P": ShowMenuChoices 2: ImageSave CurFile$, FileEntry, Image$, PictHite, PictWdth: ShowMenuChoices 0
 CASE "S": ShowMenuChoices 6: GetUserSize Image$, PictHite, PictWdth, CurDrawColor: ShowMenuChoices 0
 CASE "R": ShowMenuChoices 7: SelectColor CurDrawColor: ShowMenuChoices 0: GOSUB ColorsDraw
 CASE "D": ActiveTool = 0: GOSUB ToolsDraw
 CASE "F": ActiveTool = 1: GOSUB ToolsDraw
 CASE "C": ActiveTool = 2: GOSUB ToolsDraw
 CASE "L": ActiveTool = 3: GOSUB ToolsDraw
 CASE "E": ActiveTool = 4: GOSUB ToolsDraw
 CASE "A": CreateMask Image$, CurDrawColor
 CASE CHR$(10): GOSUB ViewData
 CASE "O": ColorScale Image$
 CASE "\": GOSUB DotShow
 END SELECT
 IF INSTR("GPSMNRAO", UCASE$(kbrd$)) THEN GOSUB PictWinDraw
RETURN

ViewPict:
 LINE (0, 0)-(319, 199), CurDrawColor, BF
 ReCalcPictSize 0, 199, 0, 319, PictHite, PictWdth, ScrWinUrow, ScrWinDrow, ScrWinLcol, ScrWinRcol, 0, 0, StretchMode
 DrawPictImage Image$, ScrWinUrow, ScrWinDrow, ScrWinLcol, ScrWinRcol, PictHite, PictWdth, StretchMode
 DO: kbrd$ = UCASE$(INKEY$): LOOP UNTIL kbrd$ > ""
 IF kbrd$ = "M" THEN StretchMode = StretchMode XOR 1: PictWinResize = 1: GOTO ViewPict
 IF kbrd$ = "G" THEN ImageLoad CurFile$, FileEntry, Image$, PictHite, PictWdth: GOTO ViewPict
 GOSUB WindowsRedraw
RETURN

ViewData:
 REDIM SpecImage(0 TO PictWdth * PictHite \ 2 + 1)
 DrawPictImage Image$, 0, 0, 0, 0, PictHite, PictWdth, 0
 GET (0, 0)-(PictWdth - 1, PictHite - 1), SpecImage
 WIDTH 80, 25: SCREEN 0
 FOR ReadPos = 0 TO UBOUND(SpecImage)
  PRINT LTRIM$(STR$(SpecImage(ReadPos))); ",";
 NEXT ReadPos
 ERASE SpecImage
 WHILE INKEY$ = "": WEND
 GOSUB SetScreenAndColors
 GOSUB WindowsRedraw
RETURN

WindowsRedraw:
 DrawBorder 8, 190, 0, 319, 1
 LINE (1, 9)-(318, 189), ColorSolid, BF
 DrawBorder 14, 159, 46, 313, 1
 DrawAll = 1
 ShowMenuChoices 0
 GOSUB PictWinDraw
 GOSUB ToolsDraw
 GOSUB ColorsDraw
 DrawAll = 0
RETURN

FilErrHandler:
FilErr = ERR
RESUME NEXT

DotShow:
 GOSUB DotGet
 DO
  SELECT CASE INKEY$
  CASE CHR$(0) + "H": GOSUB DotRestore: row = row - 1: GOSUB DotGet
  CASE CHR$(0) + "P": GOSUB DotRestore: row = row + 1: GOSUB DotGet
  CASE CHR$(0) + "K": GOSUB DotRestore: col = col - 1: GOSUB DotGet
  CASE CHR$(0) + "M": GOSUB DotRestore: col = col + 1: GOSUB DotGet
  CASE CHR$(27): EXIT DO
  END SELECT
 LOOP
 GOSUB DotRestore
RETURN

DotGet: GET (col, row)-(col + 7, row + 7), MainCursorScrn: PUT (col, row), MainCursorAndPict, AND: PUT (col, row), MainCursorOrPict, OR: RETURN
DotRestore: PUT (col, row), MainCursorScrn, PSET: RETURN

SetScreenAndColors:
SCREEN 13
IF mousepresent THEN
 MouseDriver 1, 0, 0, 0
END IF
FOR PixColor = 0 TO MAXcolor
 'RedClr = PixColor AND 3
 'GrnClr = (PixColor AND 12) \ 4
 'BluClr = (PixColor AND 48) \ 16
 
 OUT &H3C9, RedClr * 12
 OUT &H3C9, GrnClr * 12
 OUT &H3C9, BluClr * 12
 IF RedClr >= HighestShade THEN
  RedClr = 0
  IF GrnClr >= HighestShade THEN
   GrnClr = 0
   IF BluClr >= HighestShade THEN BluClr = 0 ELSE BluClr = BluClr + 1
  ELSE GrnClr = GrnClr + 1
  END IF
 ELSE RedClr = RedClr + 1
 END IF
NEXT PixColor
'row = 0
'FOR PixColor = 0 TO 215
' LINE (row, 0)-(row + 2, 199), PixColor, BF
' row = row + 3
'NEXT PixColor
'SLEEP
RETURN

'Mouse mask and pointer
DATA 64,8,16128,16191,16191,16191,0,16191,16191,16191,0,16128,16191,16191,0,0,16191,16191,0,0,16128,16191,0,0,0,16191,0,0,10752,16191,0,16170,16191,16191
DATA 64,8,63,0,0,0,16149,0,0,0,10773,63,0,0,5376,16170,0,0,5376,10794,63,0,5376,10773,16170,0,0,5397,21,0,0,0,0,0

'Tools: Brush, Roller
 DATA 224,18,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-25983
DATA -25958,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-21350,-26215,-32389,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,-32383,-32383,-32383,-21350,-26215,-32389,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-21350,-26215,-32389
DATA -32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-21350,-26215,-32389,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,-32383,-21350,-26215,-32389,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-25958,-26196,-26215,31611,-32431,-32383
DATA -32383,-32383,-32383,-32383,-32383,-32383,-32383,-25983,-26215,-26215,-26215,31641,20859,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,11137,22145
DATA 11051,11051,11051,11051,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,22145,-32340,22102,22102,22102,11094,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,11137,11051,20779,11051,11051,11089,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,11137,11089,11051,20779,11051,22059,-32383,-32383
DATA -32383,-32383,-32383,-32383,-32383,-32383,11094,11051,11051,11051,11051,-32469,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,20779,20779,20779,20779
DATA 20779,-32469,-32383,-32383,-32383,-32383,-32383,-32383,-32383,11137,11132,11090,11090,11090,11090,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,31826
DATA 21116,21074,21074,21074,-32431,-32383,-32383,-32383,-32383,-32383,-32383,-32383,21121,-21332,21074,21074,21074,20818,-32383,-32383,-32383,-32383,-32383,-32383
 DATA 224,18,-32383,-32383,-32383,-32383,-32383,-32383,-25187,-32355,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-25215,-23388
DATA 31133,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-25215,-25180,31133,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,-32383,-32383,-25215,-25180,31097,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-25215,-25180,31097,-32383
DATA -32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-25215,-25180,31097,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,-32383,31097,11129,11051,11051,11051,11051,11051,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32469,-32383,-22143,-22103,-22103,-22103,-22103,-22103,-22103,-22103,-22103,-22103,-32343,-32383,-32469,-32383,-22103,-22100,-22100,-22100,-22100
DATA -22100,-22100,-22100,-22100,-22100,22059,-32383,-32469,32641,-23639,-23639,-23639,-23639,-23639,-23639,-23639,-23639,-23639,11177,11094,-32383,-32469,32641
DATA 32675,32675,32675,32675,32675,32675,32675,32675,32675,11171,11051,11051,-32383,32641,22143,22143,22143,22143,22143,22143,22143,22143,22143,11135,11137,-32383
DATA -32383,32641,32597,32597,32597,32597,32597,32597,32597,32597,32597,11051,32555,-32383,-32383,-32383,21887,21803,21803,21803,21803,21803,21803,21803,21803,22059
DATA -32385,-32383,-32383,-32383,32675,32639,32639,32639,32639,32639,32639,32639,32639,-32385,-32383,-32383,-32383,-23679,32639,32639,32639,32639,32639,32639
DATA 32639,32639,32639,-32383,-32383,-32383,-32383,32675,32639,32639,32639,32639,32639,32639,32639,32639,-32385,-32383,-32383,-32383,-32383
 DATA 224,18,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,-32383,-32383,-32383,-32383,-32383,129,11008,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,11008,86,-32469
DATA -32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,129,22059,11051,-32512,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-22143,11094,43,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,19369,-23935,-32512,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,-32383,-32383,-32383,-22143,19282,-32350,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-24876,-14190,-32383
DATA -32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-11135,14404,-32312,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,9174,-22243,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-11135,4101,-32343,-32383,-32383,-32383,-32383
DATA -32383,-32383,-32383,-32383,-32383,-32383,-32383,-22143,-22269,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32343,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383,-32383
DATA -32383,-32383,-32383,-32383,-32383,-32383,-32383,

SUB BasicHelp

DrawOptionBox 5, 16, 8, 32, 1
row = 6
ReadPos = 1
DO
 n = INSTR(ReadPos, Text$, "/"): IF n = 0 THEN n = LEN(Text$) + 2
 LOCATE row, 9: ShowKeyOption MID$(Text$, ReadPos, n - ReadPos), ColorText, 0
 IF n > LEN(Text$) THEN EXIT DO
 ReadPos = n + 1: row = row + 1
LOOP
WHILE INKEY$ = "": WEND

END SUB

SUB ColorScale (Image$)

FOR row = 1 TO LEN(Image$)
 PixColor = ASC(MID$(Image$, row, 1))
 ColorBack = (PixColor MOD 4) + 1
 ColorBack = ColorBack + (((PixColor \ 4) MOD 4) + 1) * 6
 ColorBack = ColorBack + (((PixColor \ 16) MOD 4) + 1) * 36
 LOCATE 25, 1: PRINT PixColor;
 MID$(Image$, row, 1) = CHR$(ColorBack)
NEXT row
LOCATE 25, 1: PRINT "Done";

END SUB

SUB CreateMask (Image$, CurDrawColor)

char$ = CHR$(MAXcolor)
FOR row = 1 TO LEN(Image$)
 IF ASC(MID$(Image$, row, 1)) <> CurDrawColor THEN MID$(Image$, row, 1) = char$
NEXT row
LOCATE 25, 1: PRINT "Done";

END SUB

SUB DrawBorder (Urow, Drow, Lcol, Rcol, Mode)
ColorFore = ColorShadow: ColorBack = ColorLight
IF Mode AND 1 THEN SWAP ColorFore, ColorBack

LINE (Lcol, Urow)-(Lcol, Drow), ColorFore
LINE (Rcol, Urow)-(Rcol, Drow), ColorBack
LINE (Lcol, Urow)-(Rcol, Urow), ColorFore
LINE (Lcol, Drow)-(Rcol, Drow), ColorBack

IF Mode AND 2 THEN LINE (Lcol + 1, Urow + 1)-(Rcol - 1, Drow - 1), 0, BF
END SUB

SUB DrawOptionBox (Ulin, Dlin, Llin, Rlin, Mode)

Urow = (Ulin - 1) * 8 - 1: Drow = Dlin * 8 - 1
Lcol = (Llin - 1) * 8 - 1: Rcol = Rlin * 8 - 1
DrawBorder Urow - 3, Drow + 3, Lcol - 3, Rcol + 3, 1
LINE (Lcol - 2, Urow - 2)-(Rcol + 2, Drow + 2), ColorSolid, B
IF Mode THEN
 DrawBorder Urow - 1, Drow + 1, Lcol - 1, Rcol + 1, 2
ELSE
 LINE (Lcol - 1, Urow - 1)-(Rcol + 1, Drow + 1), ColorSolid, BF
END IF

END SUB

SUB DrawPictDot (Image$, Urow, Drow, Lcol, Rcol, PictHite, PictWdth, PictRow, PictCol, StretchMode)

IF StretchMode THEN
 StretchWdth = Rcol - Lcol + 1: StretchHite = Drow - Urow + 1
 priorRow = (StretchHite * PictRow) \ PictHite + Urow
 priorCol = (StretchWdth * PictCol) \ PictWdth + Lcol
 nextRow = (StretchHite * (PictRow + 1)) \ PictHite + Urow - 1
 nextCol = (StretchWdth * (PictCol + 1)) \ PictWdth + Lcol - 1
 LINE (priorCol, priorRow)-(nextCol, nextRow), ASC(MID$(Image$, PictRow * PictWdth + PictCol + 1, 1)), BF
ELSE
 PSET (Lcol + PictCol, Urow + PictRow), ASC(MID$(Image$, PictRow * PictWdth + PictCol + 1, 1))
END IF

END SUB

SUB DrawPictImage (Image$, Urow, Drow, Lcol, Rcol, PictHite, PictWdth, StretchMode)

IF PictHite * PictWdth > LEN(Image$) THEN SOUND 2000, 1: SOUND 1800, 1: SetImageSize Image$, PictHite, PictWdth, PictHite, PictWdth, 0

ReadPos = 1
IF StretchMode THEN
 StretchWdth = Rcol - Lcol + 1: StretchHite = Drow - Urow + 1
 priorRow = Urow
 FOR row = 1 TO PictHite
  nextRow = (StretchHite * row) \ PictHite + Urow - 1
  priorCol = Lcol
  FOR col = 1 TO PictWdth
   nextCol = (StretchWdth * col) \ PictWdth + Lcol - 1
   LINE (priorCol, priorRow)-(nextCol, nextRow), ASC(MID$(Image$, ReadPos, 1)), BF
   priorCol = nextCol + 1
   ReadPos = ReadPos + 1
  NEXT col
  priorRow = nextRow + 1
 NEXT row
 'draw proprtionally scaled image
ELSE
 'draw non-scaled, 1/1 ratio image
 nextCol = Lcol + PictWdth - 1
 FOR row = Urow TO Urow + PictHite - 1
  FOR col = Lcol TO nextCol
   PSET (col, row), ASC(MID$(Image$, ReadPos, 1))
   ReadPos = ReadPos + 1
  NEXT col
 NEXT row
END IF

END SUB

FUNCTION GetFilName (FileName$, LastEntry, entry, Mode)

DrawOptionBox 12, 14, 8, 33, 0
DrawBorder 102, 112, 54, 216, 2
DrawBorder 102, 112, 222, 264, 2
DrawBorder 86, 96, 54, 88, 2
DrawBorder 86, 96, 94, 264, 2
DrawBorder 98, 100, 54, 264, 1
Chng = 1
IF Mode AND 2 THEN
 LOCATE 14, 8: COLOR ColorText: PRINT "Picture number 0-"; LTRIM$(STR$(LastEntry));
 entry$ = LTRIM$(STR$(entry))
 DO
  kbrd$ = INKEY$
  SELECT CASE kbrd$
  CASE "0" TO "9": IF VAL(entry$ + kbrd$) <= LastEntry OR ((Mode AND 1) AND VAL(entry$ + kbrd$) <= LastEntry + 1) THEN Chng = 1: IF entry$ = "0" THEN entry$ = kbrd$ ELSE entry$ = entry$ + kbrd$
  CASE CHR$(8): IF entry$ > "" THEN entry$ = LEFT$(entry$, LEN(entry$) - 1): Chng = 1
  CASE CHR$(27): EXIT DO
  CASE CHR$(13): entry = VAL(entry$): GetFilName = 1: EXIT DO
  END SELECT
  IF Chng THEN
   LOCATE 14, 29: COLOR ColorText: PRINT LEFT$(entry$, 3);
   COLOR ColorLight: PRINT "Ý"; : IF LEN(entry$) < 3 THEN PRINT SPACE$(3 - LEN(entry$));
   Chng = 0
  END IF
 LOOP
ELSE
 LOCATE 12, 8: COLOR ColorText: IF Mode AND 1 THEN PRINT "Save";  ELSE PRINT "Load";
 DO
  kbrd$ = INKEY$
  SELECT CASE UCASE$(kbrd$)
  CASE "!" TO "ÿ"
   IF INSTR("?*+=<>|" + CHR$(34), kbrd$) = 0 THEN
    IF LEN(FileName$) < 128 THEN FileName$ = FileName$ + kbrd$: Chng = 1
   END IF
  CASE CHR$(8): IF LEN(FileName$) THEN FileName$ = LEFT$(FileName$, LEN(FileName$) - 1): Chng = 1
  CASE CHR$(27): EXIT DO
  CASE CHR$(13): GetFilName = 1: EXIT DO
  END SELECT
  IF Chng THEN
   LOCATE 12, 13: COLOR ColorText: PRINT RIGHT$(FileName$, 20);
   COLOR ColorLight: PRINT ""; : IF LEN(FileName$) < 20 THEN PRINT SPACE$(20 - LEN(FileName$));
   Chng = 0
  END IF
 LOOP
END IF

END FUNCTION

SUB GetUserSize (Image$, PictHite, PictWdth, ColorBack)

DrawOptionBox 12, 14, 16, 25, 0
DrawBorder 86, 96, 118, 168, 2
DrawBorder 102, 112, 118, 168, 2
DrawBorder 86, 96, 174, 200, 2
DrawBorder 102, 112, 174, 200, 2

DIM num$(0 TO 1)
num$(0) = LTRIM$(STR$(PictHite)): num$(1) = LTRIM$(STR$(PictWdth))
FOR item = 0 TO 3: GOSUB GetUserSizeShow: NEXT

DO
 kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE CHR$(0) + "H", CHR$(0) + "P": MenuChoice = MenuChoice XOR 1: FOR item = 0 TO 3: GOSUB GetUserSizeShow: NEXT
 CASE "0" TO "9": IF VAL(num$(MenuChoice) + kbrd$) < 65 THEN num$(MenuChoice) = num$(MenuChoice) + kbrd$: item = MenuChoice: GOSUB GetUserSizeShow
 CASE CHR$(8): IF num$(MenuChoice) > "" THEN num$(MenuChoice) = LEFT$(num$(MenuChoice), LEN(num$(MenuChoice)) - 1): item = MenuChoice: GOSUB GetUserSizeShow
 CASE CHR$(27): EXIT DO
 CASE CHR$(13)
  StretchHite = VAL(num$(0)): IF StretchHite < 1 THEN StretchHite = 16
  StretchWdth = VAL(num$(1)): IF StretchWdth < 1 THEN StretchWdth = 16
  SetImageSize Image$, PictHite, PictWdth, StretchHite, StretchWdth, ColorBack
  PictHite = StretchHite: PictWdth = StretchWdth: PictWinResize = 1
  EXIT DO
 END SELECT
LOOP
EXIT SUB
 
GetUserSizeShow:
 IF (item AND 1) = MenuChoice THEN COLOR ColorLight: Bar$ = "Ý " ELSE COLOR ColorText: Bar$ = "  "
 LOCATE 12 + (item AND 1) * 2: IF item < 2 THEN LOCATE , 23 ELSE LOCATE , 16
 SELECT CASE item
 CASE 0: PRINT LEFT$(num$(item) + Bar$, 3);
 CASE 1: PRINT LEFT$(num$(item) + Bar$, 3);
 CASE 2: PRINT "Height";
 CASE 3: PRINT "Width";
 END SELECT
RETURN

END SUB

SUB ImageLoad (CurFile$, FileEntry, Image$, PictHite, PictWdth)

FileName$ = CurFile$
ON ERROR GOTO FilErrHandler
DO
 IF GetFilName(FileName$, 0, 0, 0) = 0 THEN EXIT DO
 FilErr = 0: CHDIR FileName$
 IF FilErr THEN
  IF NoFileExtension(FileName$) THEN File$ = FileName$ + ".pix" ELSE File$ = FileName$
  FilErr = 0: OPEN File$ FOR INPUT AS #1: CLOSE #1
  IF FilErr THEN
   Text$ = "Error finding file": GOSUB LoadShowUserInfo
  ELSE
   DEF SEG = 0
   IF PEEK(1047) AND 3 THEN
    FilErr = 0: OPEN File$ FOR BINARY AS #1
    IF FilErr THEN
     Text$ = "Error reading from file": GOSUB LoadShowUserInfo
    ELSE
     LastEntry = LOF(1) \ (PictHite * PictWdth) - 1
     IF LastEntry < 0 THEN Text$ = "File is empty": GOSUB LoadShowUserInfo: EXIT DO
     entry = FileEntry
     IF GetFilName("", LastEntry, entry, 3) THEN
      GET #1, entry * CLNG(PictHite * PictWdth) + 1, Image$
      CurFile$ = File$: FileEntry = entry: NewFile = 0
     END IF
    END IF
    CLOSE #1
    EXIT DO
   END IF
   OPEN File$ FOR BINARY AS #1
   IF ImageSpecs(LastEntry, NewPictHite, NewPictWdth) = 0 THEN
    CLOSE #1: Text$ = "Can only load pix files ": GOSUB LoadShowUserInfo
   ELSEIF FilErr THEN
    CLOSE #1: Text$ = "Error reading file": GOSUB LoadShowUserInfo
   ELSE
    CLOSE #1: IF FileEntry <= LastEntry THEN entry = FileEntry ELSE entry = 0
    IF GetFilName("", LastEntry, entry, 2) THEN
     GOSUB LoadFile
     IF FilErr = 0 THEN PictWinResize = 1: CurFile$ = File$: FileEntry = entry: NewFile = 0: EXIT DO
    END IF
   END IF
  END IF
 ELSE Text$ = "Directory changed": GOSUB LoadShowUserInfo: FileName$ = ""
 END IF
LOOP

ON ERROR GOTO 0
EXIT SUB

LoadFile:
 FilErr = 0: OPEN File$ FOR BINARY AS #1
 IF FilErr THEN
  Text$ = "Error reading from file": GOSUB LoadShowUserInfo
 ELSE
  PictHite = NewPictHite: PictWdth = NewPictWdth
  SEEK 1, entry * CLNG(PictHite * PictWdth) + 8
  Image$ = INPUT$(PictHite * PictWdth, 1)
 END IF
 CLOSE #1
RETURN

RETURN

LoadShowUserInfo:
DrawOptionBox 13, 13, 8, 33, 1
LOCATE 13, 21 - (LEN(Text$) \ 2): PRINT Text$;
WHILE INKEY$ = "": WEND
RETURN

LoadMultiFile:
 SEEK ImageFile, 1
 Header$ = INPUT$(11, ImageFile) 'should be #18;"LIBRARY:QBASIC_PIX"
 'Pointer to the description table (just in case we want to skip this part)
 'File type table starts here
 '  Each type is just a few words or characters, sometimes just the extension
 '  or sometimes a little more descriptive few words
 '  Theoretically, a pix library can contain anything, but usually it consists
 '  of linear bitmaps and palettes. It would not be impossible though to even
 '  include something as unrelated as a sound wave. Something like a text file
 '  might be good for something..like if you wanted to add a description too
 '  one of your drawings?? Each filetype is assigned a number so that is
 '  quicker to identify each entry by comparing its number to the equivalent
 '  of its type, instead of a much slower string comparison.
 'Pointer to the beginning of the data pieces
 'Next comes the description table
 '  This tells what type of file each entry is and includes a string name
 '  (up to two-hundred fifty charcaters) in normal ASCII text. The types are
 '  identified here rather than at each of the pieces so that you can browse
 '  through the list and select only certain types without needing to find and
 '  jump to each data piece, which would be a lot slower and inneficient. Of
 '  course that means that this table must always accurately represent what
 '  type of data each piece truly is, but the benefits are worth it. Unlike
 '  the data pieces which can rearranged any way with each pointing to another
 '  this table must always be in order; the entries can even be empty, but
 '  they must at least be there.
 'Pointer to the first piece of data (in no particular order)
 'Pointer to the first entry (not necessarily the first piece of data)
 'The first piece of data
 '  This may be the first entry, or depending on how much things have shifted
 '  around, it may be the seventy-third. All of the entries are dynamic and
 '  can be moved around to part in the file, since they are always linked
 '  together by pointers (yes, it's a big linked list). There are four
 '  three byte pointers on each entry plus another two byte integer that tells
 '  the length of that piece (that's only a total of fourteen bytes compared
 '  to the data piece itself which is usually a few kilobytes). The pointers
 '  are forward and backwards and to the next and prior entries. From any data
 '  piece you can find your way to any other one. That is very important in a
 '  big file when you are rearranging large chunks of data, but don't have the
 '  memory to keep a gigantic pointer table. To speed things up a little, the
 '  libraries are intentionally left a little loose so that later saves (ones
 '  that change the size of the piece) will have some space to squeeze in. On
 '  the other hand, it does try to waste space either. You can tell PIXDRAW
 '  to compact a library when you are done with it. It has no function for
 '  rearranging the pieces into sequential once they have been jumbled around,
 '  but you can tell it the priority it should set on trying to save them in
 '  order whenever you save one. Even then, it might not be able to.

 '  Whenever you save a picture to an existing entry, PIXDRAW will try to put
 '  it in the same spot it was loaded from. If there is the same amount of or
 '  more room, it will simply put it in there. If the new piece of data is
 '  larger than the space the original had to fit in, PIXDRAW checks if it
 '  would be too much of a hassle to move the next one over (if it has any
 '  empty space). Otherwise, it just puts the data at the end of all the
 '  pieces, readjusting the pointers accordingly.
 SEEK 1, entry * CLNG(PictHite * PictWdth) + 8
  Image$ = INPUT$(PictHite * PictWdth, 1)
 END IF
 CLOSE #1
RETURN

END SUB

SUB ImageSave (FileName$, FileEntry, Image$, PictHite, PictWdth)

FileName$ = CurFile$
ON ERROR GOTO FilErrHandler
DO
 IF GetFilName(FileName$, 0, 0, 1) = 0 THEN EXIT DO
 IF NoFileExtension(FileName$) THEN File$ = FileName$ + ".PIX" ELSE File$ = FileName$
 FilErr = 0: OPEN File$ FOR INPUT AS #1: CLOSE #1
 IF FilErr AND FilErr <> 53 THEN
  Text$ = " Error reading file": GOSUB SaveShowUserInfo
 ELSE
  IF FilErr = 53 THEN
   'Need to create new pix file
   entry = 0: GOSUB CreateFile
   IF FilErr = 0 THEN CurFile$ = File$: FileEntry = 0: NewFile = 0: EXIT DO
  ELSE
   DEF SEG = 0
   IF PEEK(1047) AND 3 THEN
    FilErr = 0: OPEN File$ FOR BINARY AS #1
    IF FilErr THEN
     Text$ = "Error writing to file": GOSUB SaveShowUserInfo
    ELSE
     LastEntry = LOF(1) \ (PictHite * PictWdth) - 1
     entry = FileEntry
     IF GetFilName("", LastEntry, entry, 3) THEN
      PUT #1, entry * CLNG(PictHite * PictWdth) + 1, Image$
     END IF
    END IF
    CLOSE #1
    EXIT DO
   END IF
   OPEN File$ FOR BINARY AS #1
   IF ImageSpecs(LastEntry, NewPictHite, NewPictWdth) = 0 THEN
    CLOSE #1: Text$ = "Can only save to pix files": GOSUB SaveShowUserInfo
   ELSEIF NewPictHite <> PictHite OR NewPictWdth <> PictWdth THEN
    CLOSE #1: Text$ = "Size must be" + STR$(NewPictHite) + "x" + LTRIM$(STR$(NewPictWdth)): GOSUB SaveShowUserInfo
   ELSE
    CLOSE #1
    IF File$ <> CurFile$ OR NewFile THEN IF LastEntry < 255 THEN entry = LastEntry + 1 ELSE entry = 255 ELSE entry = FileEntry
    IF GetFilName("", LastEntry, entry, 3) THEN
     GOSUB SaveFile
     IF FilErr = 0 THEN CurFile$ = File$: FileEntry = entry: NewFile = 0: EXIT DO
    END IF
   END IF
  END IF
 END IF
LOOP

ON ERROR GOTO 0
EXIT SUB

CreateFile:
 FilErr = 0: OPEN File$ FOR OUTPUT AS #1
 IF FilErr THEN
  Text$ = "Error creating to file": GOSUB SaveShowUserInfo
 ELSE
  PRINT #1, CHR$(3); "PIX"; CHR$(LastEntry); CHR$(PictHite); CHR$(PictWdth); Image$;
 END IF
 CLOSE #1
RETURN

SaveFile:
 FilErr = 0: OPEN File$ FOR BINARY AS #1
 IF FilErr THEN
  Text$ = "Error writing to file": GOSUB SaveShowUserInfo
 ELSE
  PictHite = NewPictHite: PictWdth = NewPictWdth
  PUT #1, entry * CLNG(PictHite * PictWdth) + 8, Image$
  IF entry > LastEntry THEN entry$ = CHR$(entry): PUT #1, 5, entry$
 END IF
 CLOSE #1
RETURN

SaveShowUserInfo:
DrawOptionBox 13, 13, 8, 33, 1
LOCATE 13, 21 - (LEN(Text$) \ 2): PRINT Text$;
WHILE INKEY$ = "": WEND
RETURN
      
END SUB

FUNCTION ImageSpecs (LastEntry, PictHite, PictWdth)

IF LOF(1) < 8 THEN EXIT FUNCTION
SEEK 1, 1: IF INPUT$(4, 1) = CHR$(3) + "PIX" THEN ImageSpecs = 1 ELSE EXIT FUNCTION

LastEntry = ASC(INPUT$(1, 1))
PictHite = ASC(INPUT$(1, 1))
PictWdth = ASC(INPUT$(1, 1))

END FUNCTION

SUB LineDelete (Image$, PictRow, PictCol)
DrawOptionBox 13, 13, 8, 33, 0
END SUB

SUB LineInsert (Image$, PictRow, PictCol)
DrawOptionBox 11, 15, 8, 33, 0
LOCATE 11, 13: PRINT "Above";
LOCATE 13, 13: PRINT "Copy";
LOCATE 15, 13: PRINT "Vert";
END SUB

SUB MainCursorDraw (ShowCursor) STATIC
IF ShowCursor AND ShowHide = 0 THEN
 GET (MainCursorCol, MainCursorRow)-(MainCursorCol + 7, MainCursorRow + 7), MainCursorScrn
 PUT (MainCursorCol, MainCursorRow), MainCursorAndPict, AND
 PUT (MainCursorCol, MainCursorRow), MainCursorOrPict, OR
 ShowHide = 1
ELSEIF ShowCursor = 0 AND ShowHide = 1 THEN
 PUT (MainCursorCol, MainCursorRow), MainCursorScrn, PSET
 ShowHide = 0
END IF
END SUB

SUB MainCursorMove (CursorRow, CursorCol)
 MainCursorDraw 0
 MainCursorRow = CursorRow
 MainCursorCol = CursorCol
 MainCursorDraw 1
END SUB

SUB MouseDriver (ax, bx, cx, dx)
  DEF SEG = VARSEG(mousecode$)
  mouse = SADD(mousecode$)
  CALL Absolute(ax, bx, cx, dx, mouse)
END SUB

FUNCTION NoFileExtension (File$)
NoFileExtension = 1
FOR ReadPos = LEN(File$) TO 1 STEP -1
 IF MID$(File$, ReadPos, 1) = "\" THEN EXIT FOR ELSE IF MID$(File$, ReadPos, 1) = "." THEN NoFileExtension = 0: EXIT FOR
NEXT ReadPos
END FUNCTION

SUB PictLineDelete
 DrawOptionBox 8, 14, 11, 30, 0
 LOCATE 9, 12: PRINT "Height";
 LOCATE 11, 12: PRINT "Width";
 LOCATE 13, 12: PRINT "Accept";
END SUB

SUB PictLineInsert
 DrawOptionBox 8, 14, 11, 30, 0
 LOCATE 9, 12: PRINT "Height";
 LOCATE 11, 12: PRINT "Width";
 LOCATE 13, 12: PRINT "Accept";
END SUB

SUB ReCalcPictSize (MaxUrow, MaxDrow, MaxLcol, MaxRcol, PictHite, PictWdth, Urow, Drow, Lcol, Rcol, StretchHite, StretchWdth, StretchMode)

IF StretchMode THEN
 StretchHite = MaxDrow - MaxUrow + 1: StretchWdth = MaxRcol - MaxLcol + 1
 IF StretchHite / PictHite < StretchWdth / PictWdth THEN
  Urow = MaxUrow: Drow = MaxDrow
  StretchWdth = (StretchHite * PictWdth) \ PictHite
  Lcol = (MaxRcol - MaxLcol + 1 - StretchWdth) \ 2 + MaxLcol
  Rcol = Lcol + StretchWdth - 1
 ELSE
  Lcol = MaxLcol: Rcol = MaxRcol
  StretchHite = (StretchWdth * PictHite) \ PictWdth
  Urow = (MaxDrow - MaxUrow + 1 - StretchHite) \ 2 + MaxUrow
  Drow = Urow + StretchHite - 1
 END IF
ELSE
 Urow = (MaxDrow - MaxUrow + 1 - PictHite) \ 2 + MaxUrow
 Lcol = (MaxRcol - MaxLcol + 1 - PictWdth) \ 2 + MaxLcol
 Drow = Urow + PictHite - 1
 Rcol = Lcol + PictWdth - 1
END IF

END SUB

SUB SelectColor (ColorFore)

DrawOptionBox 11, 15, 14, 27, 0
DrawBorder 78, 88, 142, 184, 2
DrawBorder 94, 104, 142, 184, 2
DrawBorder 110, 120, 142, 184, 2
DrawBorder 78, 120, 102, 136, 0

DIM RGBs(0 TO 2)
RGBs(0) = ColorFore MOD 6
RGBs(1) = (ColorFore \ 6) MOD 6
RGBs(2) = (ColorFore \ 36) MOD 6
GOSUB SelectColorShowItems: GOSUB SelectColorOrColors
FOR item = 0 TO 2: GOSUB SelectColorShowBar: NEXT

DO
 kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE CHR$(0) + "H": MenuChoice = (MenuChoice + 2) MOD 3: GOSUB SelectColorShowItems
 CASE CHR$(0) + "P": MenuChoice = (MenuChoice + 1) MOD 3: GOSUB SelectColorShowItems
 CASE CHR$(0) + "K": IF RGBs(MenuChoice) > 0 THEN RGBs(MenuChoice) = RGBs(MenuChoice) - 1: item = MenuChoice: GOSUB SelectColorOrColors: GOSUB SelectColorShowBar
 CASE CHR$(0) + "M": IF RGBs(MenuChoice) < HighestShade THEN RGBs(MenuChoice) = RGBs(MenuChoice) + 1: item = MenuChoice: GOSUB SelectColorOrColors: GOSUB SelectColorShowBar
 CASE CHR$(13): GOSUB SelectColorOrColors: ColorFore = ColorBack: EXIT DO
 CASE CHR$(27): EXIT DO
 END SELECT
LOOP
EXIT SUB

SelectColorOrColors:
ColorBack = RGBs(0)
ColorBack = ColorBack + RGBs(1) * 6
ColorBack = ColorBack + RGBs(2) * 36
LINE (103, 79)-(135, 119), ColorBack, BF
RETURN

SelectColorShowBar:
 Urow = item * 16 + 80: Lcol = 190
 LINE (Lcol, Urow)-(Lcol + 25, Urow + 2), ColorSolid, BF
 LINE (Lcol, Urow + 5)-(Lcol + 25, Urow + 7), ColorSolid, BF
 DrawBorder Urow + 3, Urow + 4, Lcol, Lcol + 25, 0
 Lcol = RGBs(item) * 4 + Lcol
 DrawBorder Urow, Urow + 7, Lcol, Lcol + 5, 3
RETURN

SelectColorShowItems:
 FOR item = 0 TO 2
  IF item = MenuChoice THEN COLOR ColorLight ELSE COLOR ColorText
  LOCATE 11 + item * 2, 19
  PRINT MID$("Red  GreenBlue", item * 5 + 1, 5);
 NEXT item
RETURN
END SUB

SUB SetImageSize (Image$, PictHite, PictWdth, StretchHite, StretchWdth, ColorBack)

StretchLength = StretchHite * StretchWdth
IF StretchLength > LEN(Image$) THEN Image$ = Image$ + STRING$(StretchLength - LEN(Image$), ColorBack)
IF StretchHite < PictHite THEN nextRow = StretchHite ELSE nextRow = PictHite

IF StretchWdth < PictWdth THEN
 nextCol = 1
 FOR row = 1 TO nextRow * PictWdth STEP PictWdth
  MID$(Image$, nextCol) = MID$(Image$, row, StretchWdth)
  nextCol = nextCol + StretchWdth
 NEXT row
ELSEIF StretchWdth > PictWdth THEN
 nextCol = (nextRow - 1) * StretchWdth + 1
 excessFill = StretchWdth - PictWdth
 FOR row = (nextRow - 1) * PictWdth + 1 TO 1 STEP -PictWdth
  MID$(Image$, nextCol) = MID$(Image$, row, PictWdth)
  MID$(Image$, nextCol + PictWdth) = STRING$(excessFill, ColorBack)
  nextCol = nextCol - StretchWdth
 NEXT row
END IF

IF StretchLength < LEN(Image$) THEN Image$ = LEFT$(Image$, StretchLength)

END SUB

SUB ShowKeyOption (Text$, ColorBack, leng)

ReadPos = 1
leng = 0
DO
 n = INSTR(ReadPos, Text$, "_")
 IF n THEN
  COLOR ColorBack: PRINT MID$(Text$, ReadPos, n - ReadPos);
  COLOR ColorLight: PRINT MID$(Text$, n + 1, 1);
  leng = leng + n - ReadPos + 1: ReadPos = n + 2
  IF ReadPos > LEN(Text$) THEN EXIT DO
 ELSE
  COLOR ColorBack: PRINT MID$(Text$, ReadPos);
  leng = leng + LEN(Text$) - ReadPos + 1
  EXIT DO
 END IF
LOOP

END SUB

SUB ShowMenuChoices (MenuChoice)

Text$ = "_Get/_Put/_New/_Mode/_View/_Size/_Range"
col = 1: ReadPos = 1: ShowChoice = 1
DO
 n = INSTR(ReadPos, Text$, "/"): IF n = 0 THEN n = LEN(Text$) + 2
 LOCATE 1, col
 IF MenuChoice THEN
  IF ShowChoice = MenuChoice THEN COLOR ColorLight ELSE COLOR ColorShadow
  leng = n - ReadPos - 1: PRINT MID$(Text$, ReadPos + 1, leng);
 ELSE
  ShowKeyOption MID$(Text$, ReadPos, n - ReadPos), ColorText, leng
 END IF
 IF n > LEN(Text$) THEN EXIT DO
 ReadPos = n + 1: col = col + leng + 2
 ShowChoice = ShowChoice + 1: PRINT "  ";
LOOP
PRINT SPACE$(41 - col - 5);

END SUB

