'For:Written using Qbasic 1.1
'Date:On Dec 26, 1997
'By:Dwayne Robinson
'Purpose:To find picture tiles in ROMs and other game files

DEFINT A-Z
DECLARE SUB GetInputs (File$, FileOfset&, UnitSize)
ON ERROR GOTO FileErrorHandler
'UnitSize PicWidth PicHeight FileOfset& UnitOfset

CONST TRUE = -1, FALSE = 0, TileMaxWidth = 256, TileMaxHeight = 192
CONST TileMinSize = 4, MaxBufferSize = 20000
DIM SHARED Null$, TileBuffer$, TileWidth, TileHeight, TileMask, FilErr
Null$ = CHR$(0): TileBuffer$ = SPACE$(20): TileWidth = 32: TileHeight = 32

SCREEN 13: VIEW PRINT

GetUserInputs:
CLS : PRINT "Simple tile viewer": PRINT
GetInputs File$, FileOfset&, UnitSize
'File$ = "c:\windows\pbrush.exe": FileOfset& = 1: UnitSize = 4

FilErr = 0: OPEN File$ FOR BINARY AS 1
IF FilErr THEN PRINT "Error opening file for viewing!": END
FileLen& = LOF(1): IF FileLen& = 0 THEN PRINT "Zero length file!": END

CLS
GOSUB CalcBitSizeVars

GOSUB OutlineTile
Redraw = TRUE

'TileScrollPrompt
DO
 SELECT CASE INKEY$
 CASE "": FreeToDraw = TRUE
 CASE Null$ + "P": TileScrollVert = TileScrollVert - 1: Redraw = TRUE
 CASE Null$ + "H": TileScrollVert = TileScrollVert + 1: Redraw = TRUE
 CASE Null$ + "K": TileScrollHorz = TileScrollHorz - 1: Redraw = TRUE
 CASE Null$ + "M": TileScrollHorz = TileScrollHorz + 1: Redraw = TRUE
 CASE Null$ + "R": TileWidthChng = TileWidthChng + 1: Redraw = TRUE
 CASE Null$ + "S": TileWidthChng = TileWidthChng - 1: Redraw = TRUE
 CASE Null$ + "I": TileScrollVert = TileHeight: Redraw = TRUE
 CASE Null$ + "Q": TileScrollVert = -TileHeight: Redraw = TRUE
 CASE "+": TileHeightChng = TileHeightChng + 1: Redraw = TRUE
 CASE "-": TileHeightChng = TileHeightChng - 1: Redraw = TRUE
 CASE "1": UnitSize = 1: GOSUB CalcBitSizeVars: Redraw = TRUE
 CASE "2": UnitSize = 2: GOSUB CalcBitSizeVars: Redraw = TRUE
 CASE "3": UnitSize = 4: GOSUB CalcBitSizeVars: Redraw = TRUE
 CASE "4": UnitSize = 8: GOSUB CalcBitSizeVars: Redraw = TRUE
 CASE CHR$(13): CLOSE : GOTO GetUserInputs
 CASE CHR$(27): EXIT DO
 END SELECT

 IF Redraw AND FreeToDraw THEN GOSUB UpdateTile: Redraw = FALSE
 FreeToDraw = FALSE
LOOP

CLOSE
WIDTH 80, 25
END

UpdateTile:
 GOSUB MoveTile
 GOSUB DisplayTile
 LOCATE 24, 1: PRINT "Dim"; TileHeight; "x"; TileWidth; TAB(16); "Units"; (TileWidth * TileHeight); "Bytes"; buffersize; TAB(40);
 LOCATE 25, 1: PRINT "Pos"; FileOfset&; "x"; UnitOfset; TAB(18); "Bits"; UnitSize; TAB(40);
RETURN

MoveTile:
 IF TileWidthChng OR TileHeightChng THEN
  Temp = TileHeight + TileHeightChng: Test = Temp >= TileMinSize AND Temp <= TileMaxHeight: IF Test THEN TileHeight = Temp
  Temp = TileWidth + TileWidthChng: Test2 = Temp >= TileMinSize AND Temp <= TileMaxWidth: IF Test2 THEN TileWidth = Temp
  Temp = MaxBufferSize \ TileWidth: IF TileHeight > Temp THEN TileHeight = Temp
  IF Test OR Test2 THEN GOSUB OutlineTile
  TileWidthChng = 0: TileHeightChng = 0
 END IF
 'LOCATE 20, 1: PRINT "HITE WDTH"; TAB(20); TileHeight; TileWidth; TileHeightChng; TileWidthChng
 'LOCATE 21: PRINT "HITE WDTH HCHG WCHG"; TAB(20); TileHeight; TileWidth; TileHeightChng; TileWidthChng
 'LOCATE 22: PRINT "VERT HORZ FILE UNIT"; TAB(20); TileScrollVert; TileScrollHorz; FileOfset&; UnitOfset
 TileScrollHorz = (TileScrollVert * TileWidth) + TileScrollHorz + UnitOfset
 UnitOfset = TileScrollHorz AND UnitMods: FileOfset& = FileOfset& + ((TileScrollHorz XOR UnitOfset) \ UnitParts)
 IF FileOfset& < 1 THEN FileOfset& = 1 ELSE IF FileOfset& > FileLen& THEN FileOfset& = FileLen&
 'LOCATE 23, 1: PRINT "FILE UNIT"; TAB(20); FileOfset&; UnitOfset;
 TileScrollVert = 0: TileScrollHorz = 0
RETURN

DisplayTile:
 'buffersize = (TileWidth * TileHeight * UnitSize + 7) \ 8
 buffersize = ((TileWidth * TileHeight) + UnitOfset + UnitMods) \ UnitParts
 'LOCATE 17, 1: PRINT "BUFFER"; (TileWidth * TileHeight); "units"; buffersize; "bytes"; TAB(40);
 TileBuffer$ = SPACE$(buffersize)
 GET 1, FileOfset&, TileBuffer$
 'curbyte = 1: bitShift = 2 ^ (UnitOfset * UnitSize)
 curbyte = 1: bitShift = 2 ^ ((UnitMods - UnitOfset) * UnitSize)
 FOR row = TileHeight TO 1 STEP -1
  FOR col = 1 TO TileWidth
   PSET (col, row), ASC(MID$(TileBuffer$, curbyte, 1)) \ bitShift AND TileMask
   'IF bitShift >= ShiftMax THEN bitShift = 1: curbyte = curbyte + 1 ELSE bitShift = bitShift * ShiftInc
   IF bitShift <= 1 THEN bitShift = ShiftMax: curbyte = curbyte + 1 ELSE bitShift = bitShift \ ShiftInc
 NEXT col, row
 'Alternate line for reversed bit arrangement
RETURN

GetNextPixel:
 'PixColor = INT(RND * 256)
 PixColor = ASC(MID$(TileBuffer$, curbyte, 1)) \ bitShift AND TileMask
 IF bitShift >= ShiftMax THEN bitShift = 1: curbyte = curbyte + 1 ELSE bitShift = bitShift * ShiftInc
RETURN

OutlineTile:
 LINE (0, 0)-(1 + TileWidth, 1 + TileHeight), 15, B
 IF TileWidthChng < 0 THEN LINE (2 + TileWidth - TileWidthChng, 0)-(2 + TileWidth, 2 + TileHeight), 0, BF
 IF TileHeightChng < 0 THEN LINE (0, 2 + TileHeight)-(2 + TileWidth, 1 + TileHeight - TileHeightChng), 0, BF
RETURN

CalcBitSizeVars:
 IF UnitSize < 1 OR UnitSize > 8 THEN UnitSize = 8
 ShiftInc = 2 ^ UnitSize: ShiftMax = 256 \ ShiftInc
 TileMask = ShiftInc - 1: UnitParts = 8 \ UnitSize
 UnitMods = UnitParts - 1
 'LOCATE 16, 1: PRINT "FILE LENGTH "; RIGHT$(File$, 19); FileLen&
 'LOCATE 18: PRINT "SIZE PARTS MODS"; TAB(20); UnitSize; UnitParts; UnitMods
 'LOCATE 19: PRINT "SHINC SHMAX MASK"; TAB(20); ShiftInc; ShiftMax; TileMask
RETURN

FileErrorHandler:
FilErr = TRUE
RESUME NEXT

SUB GetInputs (File$, FileOfset&, UnitSize)

PRINT "Any type of file you want"
DO
 LINE INPUT "Filename: ", File$
 IF File$ = "" THEN END
 IF INSTR(File$, "*") THEN
  SHELL "dir " + File$
 ELSE
  FilErr = 0: CHDIR File$
  IF FilErr THEN
   FilErr = 0: OPEN File$ FOR INPUT AS 1
   IF NOT FilErr THEN FileLen& = LOF(1)
   CLOSE 1
   IF FilErr THEN PRINT "Could not find that file, please retype" ELSE EXIT DO
  ELSE PRINT "Directory changed"
  END IF
 END IF
LOOP
PRINT
PRINT "File size is"; FileLen&; "bytes"
DO
 LINE INPUT ; "Starting position: ", Temp$
 IF LEN(Temp$) THEN FileOfset& = VAL(Temp$): PRINT  ELSE FileOfset& = 1: PRINT LTRIM$(STR$(FileOfset&))
 IF FileOfset& < 1 OR FileOfset& > FileLen& THEN PRINT "Value must be within file" ELSE EXIT DO
LOOP
PRINT
PRINT "Valid bit sizes are 1,2,4,8": PRINT "(binary,couple,nibble,byte)"
DO
 LINE INPUT "Unit size (bits): ", Temp$
 IF Temp$ = "" THEN END
 IF LEN(Temp$) = 1 AND INSTR("1248", Temp$) THEN UnitSize = VAL(Temp$): EXIT DO
 PRINT "Not an available bit size"
LOOP

END SUB

