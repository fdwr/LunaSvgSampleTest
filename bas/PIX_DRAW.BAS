DEFINT A-Z
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
DECLARE FUNCTION GetFilName (File$, LastEntry, Entry, Mode)
DECLARE FUNCTION NoFileExtension (File$)
DECLARE FUNCTION ImageSpecs (LastEntry, PictHite, PictWdth)

CONST MAXcolor = 63, ColorLight = MAXcolor, ColorSolid = 42, ColorShadow = 21, ColorText = 58
DIM SHARED FilErr, CurFile$, MainCursorRow, MainCursorCol, PictWinResize, NewFile
REDIM SHARED MainCursorAndPict(0 TO 33), MainCursorOrPict(0 TO 33), MainCursorScrn(0 TO 33)
DIM ToolPicts(0 TO 253, 0 TO 4)
FOR ReadPos = 0 TO 33: READ MainCursorAndPict(ReadPos): NEXT ReadPos: FOR ReadPos = 0 TO 33: READ MainCursorOrPict(ReadPos): NEXT ReadPos
DATA 64,8,16128,16191,16191,16191,0,16191,16191,16191,0,16128,16191,16191,0,0,16191,16191,0,0,16128,16191,0,0,0,16191,0,0,10752,16191,0,16170,16191,16191
DATA 64,8,63,0,0,0,16149,0,0,0,10773,63,0,0,5376,16170,0,0,5376,10794,63,0,5376,10773,16170,0,0,5397,21,0,0,0,0,0
FOR ActiveTool = 0 TO 1: FOR ReadPos = 0 TO 253: READ ToolPicts(ReadPos, ActiveTool): NEXT ReadPos: NEXT ActiveTool
 DATA 224,18,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,13098,13107,10794,10794,10794
DATA 10794,10794,10794,10794,10794,10794,10794,10794,10794,16179,12850,10790,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,16179,12850,10790
DATA 10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,16179,12850,10790,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,16179
DATA 12850,10790,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,16179,12850,10790,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794
DATA 13107,12863,12850,9766,10770,10794,10794,10794,10794,10794,10794,10794,10794,13098,12850,12850,12850,9778,4646,10794,10794,10794,10794,10794,10794,10794
DATA 10794,42,5418,0,0,0,0,10794,10794,10794,10794,10794,10794,10794,10794,5418,10815,5397,5397,5397,21,10794,10794,10794,10794,10794,10794,10794,10794,42,0,4608,0,0
DATA 18,10794,10794,10794,10794,10794,10794,10794,10794,42,18,0,4608,0,5376,10794,10794,10794,10794,10794,10794,10794,10794,21,0,0,0,0,10752,10794,10794,10794
DATA 10794,10794,10794,10794,10794,4608,4608,4608,4608,4608,10752,10794,10794,10794,10794,10794,10794,10794,42,39,19,19,19,19,10794,10794,10794,10794,10794,10794
DATA 10794,10794,10003,4903,4883,4883,4883,10770,10794,10794,10794,10794,10794,10794,10794,4906,16191,4883,4883,4883,4627,10794,10794,10794,10794,10794,10794
 DATA 224,18,10794,10794,10794,10794,10794,10794,13364,10804,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,13354,14649,9268,10794,10794,10794
DATA 10794,10794,10794,10794,10794,10794,10794,10794,13354,13369,9268,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,13354,13369,9252,10794
DATA 10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,13354,13369,9252,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,13354,13369
DATA 9252,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794,9252,36,0,0,0,0,0,10794,10794,10794,10794,10794,10794,10794,10794,10794,10794
DATA 10794,10794,10794,10794,10752,10794,15402,15420,15420,15420,15420,15420,15420,15420,15420,15420,10812,10794,10752,10794,15420,15423,15423,15423,15423,15423
DATA 15423,15423,15423,15423,5376,10794,10752,10282,14396,14396,14396,14396,14396,14396,14396,14396,14396,60,21,10794,10752,10282,10296,10296,10296,10296,10296
DATA 10296,10296,10296,10296,56,0,0,10794,10282,5416,5416,5416,5416,5416,5416,5416,5416,5416,40,42,10794,10794,10282,10260,10260,10260,10260,10260,10260,10260
DATA 10260,10260,0,10240,10794,10794,10794,5160,5120,5120,5120,5120,5120,5120,5120,5120,5376,10792,10794,10794,10794,10296,10280,10280,10280,10280,10280,10280
DATA 10280,10280,10792,10794,10794,10794,14378,10280,10280,10280,10280,10280,10280,10280,10280,10280,10794,10794,10794,10794,10296,10280,10280,10280,10280,10280
DATA 10280,10280,10280,10792,10794,10794,10794,10794

GOSUB SetScreenColors

PictHite = 10: PictWdth = 20: PictRow = 4: PictCol = 9
Image$ = STRING$(PictHite * PictWdth, 0)
FOR ReadPos = 1 TO LEN(Image$): MID$(Image$, ReadPos, 1) = CHR$(INT(RND * 40)): NEXT ReadPos
ActiveTool = 0: StretchMode = 1: PictWinResize = 1
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
  FOR LastActiveTool = 0 TO 1 '30 188
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
  CASE CHR$(0) + "H": IF CurDrawColor > 31 THEN CurDrawColor = CurDrawColor - 32: GOSUB ColorsDraw: GOSUB ColorsPutCursor
  CASE CHR$(0) + "P": IF CurDrawColor < MAXcolor - 31 THEN CurDrawColor = CurDrawColor + 32: GOSUB ColorsDraw: GOSUB ColorsPutCursor
  CASE CHR$(0) + "K": IF CurDrawColor > 0 THEN CurDrawColor = CurDrawColor - 1: GOSUB ColorsDraw: GOSUB ColorsPutCursor
  CASE CHR$(0) + "M": IF CurDrawColor < MAXcolor THEN CurDrawColor = CurDrawColor + 1: GOSUB ColorsDraw: GOSUB ColorsPutCursor
  CASE CHR$(13): GOTO PictWinEdit
  CASE " ": SelectColor CurDrawColor: GOSUB ColorsDraw: GOSUB PictWinDraw
  CASE CHR$(9): GOTO ToolsChoose
  CASE ELSE: GOSUB MenuChoices
  END SELECT
 LOOP
RETURN
ColorsPutCursor:
 Urow = 170 + (LastDrawColor \ 32) * 9: Lcol = 29 + (LastDrawColor MOD 32) * 9
 MainCursorMove Urow, Lcol
RETURN
ColorsDraw:
 IF ActiveWindow = 2 THEN MainCursorDraw 0
 IF DrawAll THEN
  DrawBorder 165, 184, 24, 313, 0
  DrawBorder 165, 184, 6, 21, 0
  PixColor = 0
  FOR row = 167 TO 183 STEP 9
   FOR col = 26 TO 312 STEP 9
    LINE (col, row)-(col + 6, row + 6), PixColor, BF
    PixColor = PixColor + 1
   NEXT col
  NEXT row
 ELSEIF LastDrawColor <= MAXcolor THEN
  Urow = 166 + (LastDrawColor \ 32) * 9: Lcol = 25 + (LastDrawColor MOD 32) * 9
  LINE (Lcol, Urow)-(Lcol + 8, Urow + 8), ColorSolid, B
 END IF
 LastDrawColor = CurDrawColor
 LINE (7, 166)-(20, 183), CurDrawColor, BF
 IF CurDrawColor > MAXcolor THEN RETURN
 Urow = 166 + (CurDrawColor \ 32) * 9: Lcol = 25 + (CurDrawColor MOD 32) * 9
 DrawBorder Urow, Urow + 8, Lcol, Lcol + 8, 1 '21845
 IF ActiveWindow = 2 THEN GOSUB ColorsPutCursor
RETURN

MenuChoices:
 SELECT CASE UCASE$(kbrd$)
 CASE CHR$(27): SCREEN 2: END
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
 CASE CHR$(10): GOSUB ViewData
 CASE "\": GOSUB DotShow
 END SELECT
 IF INSTR("GPSMNR", UCASE$(kbrd$)) THEN GOSUB PictWinDraw
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
 SCREEN 0: WIDTH 80, 25
 FOR ReadPos = 0 TO UBOUND(SpecImage)
  PRINT LTRIM$(STR$(SpecImage(ReadPos))); ",";
 NEXT ReadPos
 ERASE SpecImage
 WHILE INKEY$ = "": WEND
 GOSUB SetScreenColors
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

SetScreenColors:
SCREEN 13
FOR PixColor = 0 TO MAXcolor
 RedClr = PixColor AND 3
 GrnClr = (PixColor AND 12) \ 4
 BluClr = (PixColor AND 48) \ 16
 OUT &H3C9, RedClr * 21
 OUT &H3C9, GrnClr * 21
 OUT &H3C9, BluClr * 21
NEXT PixColor
RETURN

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
LINE (Lcol - 2, Urow - 2)-(Rcol + 2, Drow + 2), 42, B
IF Mode THEN
 DrawBorder Urow - 1, Drow + 1, Lcol - 1, Rcol + 1, 2
ELSE
 LINE (Lcol - 1, Urow - 1)-(Rcol + 1, Drow + 1), 42, BF
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

FUNCTION GetFilName (FileName$, LastEntry, Entry, Mode)

DrawOptionBox 12, 14, 8, 33, 0
DrawBorder 102, 112, 54, 216, 2
DrawBorder 102, 112, 222, 264, 2
DrawBorder 86, 96, 54, 88, 2
DrawBorder 86, 96, 94, 264, 2
DrawBorder 98, 100, 54, 264, 1
Chng = 1
IF Mode AND 2 THEN
 LOCATE 14, 8: COLOR ColorText: PRINT "Picture number 0-"; LTRIM$(STR$(LastEntry));
 Entry$ = LTRIM$(STR$(Entry))
 DO
  kbrd$ = INKEY$
  SELECT CASE kbrd$
  CASE "0" TO "9": IF VAL(Entry$ + kbrd$) <= LastEntry OR ((Mode AND 1) AND VAL(Entry$ + kbrd$) <= LastEntry + 1) THEN Chng = 1: IF Entry$ = "0" THEN Entry$ = kbrd$ ELSE Entry$ = Entry$ + kbrd$
  CASE CHR$(8): IF Entry$ > "" THEN Entry$ = LEFT$(Entry$, LEN(Entry$) - 1): Chng = 1
  CASE CHR$(27): EXIT DO
  CASE CHR$(13): Entry = VAL(Entry$): GetFilName = 1: EXIT DO
  END SELECT
  IF Chng THEN
   LOCATE 14, 29: COLOR ColorText: PRINT LEFT$(Entry$, 3);
   COLOR ColorLight: PRINT "Ý"; : IF LEN(Entry$) < 3 THEN PRINT SPACE$(3 - LEN(Entry$));
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
     Entry = FileEntry
     IF GetFilName("", LastEntry, Entry, 3) THEN
      GET #1, Entry * CLNG(PictHite * PictWdth) + 1, Image$
      CurFile$ = File$: FileEntry = Entry: NewFile = 0
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
    CLOSE #1: IF FileEntry <= LastEntry THEN Entry = FileEntry ELSE Entry = 0
    IF GetFilName("", LastEntry, Entry, 2) THEN
     GOSUB LoadFile
     IF FilErr = 0 THEN PictWinResize = 1: CurFile$ = File$: FileEntry = Entry: NewFile = 0: EXIT DO
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
  SEEK 1, Entry * CLNG(PictHite * PictWdth) + 8
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
   Entry = 0: GOSUB CreateFile
   IF FilErr = 0 THEN CurFile$ = File$: FileEntry = 0: NewFile = 0: EXIT DO
  ELSE
   DEF SEG = 0
   IF PEEK(1047) AND 3 THEN
    FilErr = 0: OPEN File$ FOR BINARY AS #1
    IF FilErr THEN
     Text$ = "Error writing to file": GOSUB SaveShowUserInfo
    ELSE
     LastEntry = LOF(1) \ (PictHite * PictWdth) - 1
     Entry = FileEntry
     IF GetFilName("", LastEntry, Entry, 3) THEN
      PUT #1, Entry * CLNG(PictHite * PictWdth) + 1, Image$
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
    IF File$ <> CurFile$ OR NewFile THEN IF LastEntry < 255 THEN Entry = LastEntry + 1 ELSE Entry = 255 ELSE Entry = FileEntry
    IF GetFilName("", LastEntry, Entry, 3) THEN
     GOSUB SaveFile
     IF FilErr = 0 THEN CurFile$ = File$: FileEntry = Entry: NewFile = 0: EXIT DO
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
  PUT #1, Entry * CLNG(PictHite * PictWdth) + 8, Image$
  IF Entry > LastEntry THEN Entry$ = CHR$(Entry): PUT #1, 5, Entry$
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
RGBs(0) = ColorFore AND 3
RGBs(1) = (ColorFore AND 12) \ 4
RGBs(2) = (ColorFore AND 48) \ 16
GOSUB SelectColorShowItems: GOSUB SelectColorOrColors
FOR item = 0 TO 2: GOSUB SelectColorShowBar: NEXT

DO
 kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE CHR$(0) + "H": MenuChoice = (MenuChoice + 2) MOD 3: GOSUB SelectColorShowItems
 CASE CHR$(0) + "P": MenuChoice = (MenuChoice + 1) MOD 3: GOSUB SelectColorShowItems
 CASE CHR$(0) + "K": IF RGBs(MenuChoice) > 0 THEN RGBs(MenuChoice) = RGBs(MenuChoice) - 1: item = MenuChoice: GOSUB SelectColorOrColors: GOSUB SelectColorShowBar
 CASE CHR$(0) + "M": IF RGBs(MenuChoice) < 3 THEN RGBs(MenuChoice) = RGBs(MenuChoice) + 1: item = MenuChoice: GOSUB SelectColorOrColors: GOSUB SelectColorShowBar
 CASE CHR$(13): GOSUB SelectColorOrColors: ColorFore = ColorBack: EXIT DO
 CASE CHR$(27): EXIT DO
 END SELECT
LOOP
EXIT SUB

SelectColorOrColors:
ColorBack = 0
ColorBack = ColorBack OR RGBs(0)
ColorBack = ColorBack OR RGBs(1) * 4
ColorBack = ColorBack OR RGBs(2) * 16
LINE (103, 79)-(135, 119), ColorBack, BF
RETURN

SelectColorShowBar:
 Urow = item * 16 + 80: Lcol = 190
 LINE (Lcol, Urow)-(Lcol + 23, Urow + 2), ColorSolid, BF
 LINE (Lcol, Urow + 5)-(Lcol + 23, Urow + 7), ColorSolid, BF
 DrawBorder Urow + 3, Urow + 4, Lcol, Lcol + 23, 0
 Lcol = RGBs(item) * 6 + Lcol
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

