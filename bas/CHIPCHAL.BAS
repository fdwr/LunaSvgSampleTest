DEFINT A-Z
DECLARE SUB DisplayBlock (Row, Col)
DECLARE SUB DisplayWindow ()
DECLARE SUB LoadBlockPicts ()
DECLARE SUB LoadGameFile (Level, LoadErr)
DECLARE SUB DrawBorder (Urow, Drow, Lcol, Rcol, Mode)
DECLARE SUB StartupMessage (text$)

CONST LevelFile$ = "CHIPCHAL.LVL", BlocksFile$ = "CHIPCHAL.PIX"
CONST GameFileNotFound = 1, NullLevel = 2, LvlWinToprow = 4, LvlWinLeftcol = 59
CONST ColorShadow = 21, ColorLight = 63, BlockPictsSize = 1024, BlocksSize = 257
DIM SHARED ErrCode, LevelWidth, LevelHeight, LevelRowOfset, LevelColOfset, MaxBlockPicts
REDIM SHARED LevelArray(0 TO 0, 0 TO 0), BlockPicts(0 TO 0) AS LONG

SCREEN 13
 StartupMessage "Screen mode set to mode 13h (320x200)"
StartupMessage "Setting color palette"
 GOSUB SetScreenColors
 FOR PixColor = 0 TO 63: LINE (PixColor + 168, 8)-(PixColor + 168, 15), PixColor: NEXT PixColor
StartupMessage "Loading level grid"
 ON ERROR GOTO ErrHandler
 LoadGameFile Level, LoadErr
 IF LoadErr THEN StartupMessage "Can not find level file: " + LevelFile$: END
 StartupMessage "Dimensions are" + STR$(LevelWidth) + " x" + STR$(LevelHeight)
StartupMessage "Loading picture tiles"
 LoadBlockPicts
 IF MaxBlockPicts THEN StartupMessage "Loaded" + STR$(MaxBlockPicts) + " tiles " ELSE StartupMessage "No tiles found in file: " + BlocksFile$
 ON ERROR GOTO 0
StartupMessage ""
StartupMessage "Press a key to display level"
 DO UNTIL INKEY$ > "": LOOP

LINE (0, 0)-(319, 199), 42, BF
DrawBorder LvlWinToprow - 1, LvlWinToprow + 192, LvlWinLeftcol - 1, LvlWinLeftcol + 256, 0
DisplayWindow

DO
 WHILE INKEY$ > "": WEND
 SELECT CASE INP(96)
 CASE 72: LevelRowOfset = LevelRowOfset - 1: ViewChanged = 1
 CASE 80: LevelRowOfset = LevelRowOfset + 1: ViewChanged = 1
 CASE 75: LevelColOfset = LevelColOfset - 1: ViewChanged = 1
 CASE 77: LevelColOfset = LevelColOfset + 1: ViewChanged = 1
 CASE 1: EXIT DO
 END SELECT

 IF ViewChanged THEN DisplayWindow: ViewChanged = 0
LOOP
ON ERROR GOTO 0

'FOR Row = 0 TO LevelHeight
' LOCATE Row + 1, 1
' FOR Col = 0 TO LevelWidth
'  PRINT STR$(LevelArray(Row, Col));
' NEXT Col
'NEXT Row

END

ErrHandler:
ErrCode = ERR
RESUME NEXT

SetScreenColors:
OUT &H3C8, 0
FOR PixColor = 0 TO 63
 RedClr = PixColor AND 3
 GrnClr = (PixColor AND 12) \ 4
 BluClr = (PixColor AND 48) \ 16
 OUT &H3C9, RedClr * 21
 OUT &H3C9, GrnClr * 21
 OUT &H3C9, BluClr * 21
NEXT PixColor
RETURN

SUB DisplayBlock (Row, Col)

IF Row < 0 OR Row > LevelHeight THEN BlockColor = -1: GOTO DrawBlock
IF Col < 0 OR Col > LevelWidth THEN BlockColor = -1: GOTO DrawBlock
BlockColor = LevelArray(Row, Col)

DrawBlock:
ScrnRow = Row - LevelRowOfset: IF ScrnRow < 0 OR ScrnRow > 8 THEN EXIT SUB
ScrnCol = Col - LevelColOfset: IF ScrnCol < 0 OR ScrnCol > 8 THEN EXIT SUB
ScrnRow = ScrnRow * 32 + LvlWinToprow
ScrnCol = ScrnCol * 32 + LvlWinLeftcol

IF BlockColor < 0 THEN
 LINE (ScrnCol, ScrnRow)-(ScrnCol + 31, ScrnRow + 31), 0, BF
ELSEIF BlockColor < MaxBlockPicts THEN
 PUT (ScrnCol, ScrnRow), BlockPicts(BlockColor * BlocksSize), PSET
ELSE
 LINE (ScrnCol, ScrnRow)-(ScrnCol + 31, ScrnRow + 31), BlockColor, BF
END IF

END SUB

SUB DisplayWindow

FOR Row = 0 TO 5
 FOR Col = 0 TO 7
  DisplayBlock Row + LevelRowOfset, Col + LevelColOfset
 NEXT Col
NEXT Row
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

SUB LoadBlockPicts

ErrCode = 0: OPEN BlocksFile$ FOR INPUT AS #1
IF ErrCode THEN MaxBlockPicts = 0: EXIT SUB ELSE CLOSE #1
OPEN BlocksFile$ FOR BINARY AS #1

FilePtr& = 1
MaxBlockPicts = LOF(1) \ BlockPictsSize
IF MaxBlockPicts = 0 THEN EXIT SUB
REDIM BlockPicts(0 TO MaxBlockPicts * BlocksSize - 1)

CurWord = 0
FileWord = 1
FOR CurBlock = 1 TO MaxBlockPicts
 BlockPicts(CurWord) = 2097408
 CurWord = CurWord + 1
 FOR CurWord = CurWord TO CurWord + BlocksSize - 2
  GET 1, FileWord, BlockPicts(CurWord)
  FileWord = FileWord + 4
 NEXT CurWord
NEXT CurBlock

CLOSE #1
END SUB

SUB LoadGameFile (Level, LoadErr)

ErrCode = 0: OPEN LevelFile$ FOR INPUT AS #1: CLOSE #1
IF ErrCode THEN LoadErr = GameFileNotFound: EXIT SUB
OPEN LevelFile$ FOR BINARY AS #1

FilePtr& = 1
FileLen& = LOF(1)
GOTO GetArrayLen
WHILE FindLevel < Level
 FilePtr& = FilePtr& + NextPtr + 2
 FindLevel = FindLevel + 1
GetArrayLen:
 IF NextPtr < 0 OR FilePtr& > FileLen& THEN LoadErr = NullLevel: EXIT SUB
 GET 1, FilePtr&, NextPtr
WEND

LevelHeight = ASC(INPUT$(1, 1))
LevelWidth = ASC(INPUT$(1, 1))
REDIM LevelArray(0 TO LevelHeight, 0 TO LevelWidth)
FOR Row = 0 TO LevelHeight
 FOR Col = 0 TO LevelWidth
  LevelArray(Row, Col) = ASC(INPUT$(1, 1))
 NEXT Col
NEXT Row

CLOSE #1
LoadErr = 0
END SUB

SUB StartupMessage (text$)

COLOR 58
LOCATE , 1: PRINT LEFT$(text$, 80);
PRINT

END SUB

