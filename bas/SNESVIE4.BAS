' Example SNES/Gameboy sprite viewer for simple Qbasic
' Programmed by FDwR, version 0.4
' Thanks to Corsair, Kari, Dax, and Yoshi for revealing how the SNES stores
' its graphics in their docs, VileWrath for the example, and Magnus Runesson
' for letting me see his source code.

' "This sprite reader was programmed in QuickBasic so that
'  almost any programmer should be able to understand how
'  SNES sprites are encoded. Yes its sloppy, yes its slow
'  but it also took me two minutes to write. And it gives
'  you something to work on. :-) Vilewrath"

' Well I worked on it, adding more bitmodes, faster bit blitting, user
'   palettes, and the ability to scroll! ;-)
' You might notice this is ver 0.4, that is because the previous three stunk
'   too much to release. There are plenty of possible optimizations in this
'   version, but they would just make it more difficult to understand. Tried
'   to remove all the bugs, tell if me if I didn't.
' This is also not meant to be the ultimate editor by any means; there are
'   plenty of better viewers/editors out there. It is just an example written
'   in a universal language. Unlike VileWrath's though, this took a little
'   more than two minutes!

DEFINT A-Z
' These are allocated for the assembly code
CONST TileTranCodeSize = (514 + 1) \ 2
DIM TileTransCode(0 TO TileTranCodeSize - 1), CodeEntryTable(0 TO 3)
' These are for the slower Qb routine
DIM PlaneBase(0 TO 7), PlaneInc(0 TO 10), PlanePattern(0 TO 8), TransCode(0 TO 20)
' These are for your game palette
DIM ScrnPalette(0 TO 383), UserPalette(0 TO 383), PaletteLoaded

' Read in the assembly
FOR Index = 0 TO TileTranCodeSize - 1
  READ TileTransCode(Index)
NEXT Index

' Set all the variables used the Qb tile translating ruotine
' Planebase tells what byte the first row of each plane starts on
PlaneBase(0) = 0:  PlaneBase(1) = 1
PlaneBase(2) = 16: PlaneBase(3) = 17
PlaneBase(4) = 32: PlaneBase(5) = 33
PlaneBase(6) = 48: PlaneBase(7) = 49
' Planeinc tells how many bytes it is to each plane's next row...
'#In bitmode one, each row is immediately after the prior so the spacing is one.
'#In bitmodes two, four, and eight, each row comes two bytes after the prior.
'#In bitmode three, the two spacing patterns are combined into <2,2,1>.
' The first two planes are interleaved so each row is two bytes apart,
' (like bitmode two) while in the third bitplane, each row comes immediately
' after the prior row so the spacing is one (like bitmode one)
FOR plane = 0 TO 9
 PlaneInc(plane) = 2
NEXT plane
PlaneInc(10) = 1
' Plane pattern is an pointer array that determines which increment pattern
' to use for each bitmode, in other words where to point into planeinc(?)
' We actually only need to assign bitmodes 1 and 3 though since all the others
' are already set to index zero.
PlanePattern(1) = 10
PlanePattern(3) = 8

TilesWide = 16: TilesHeigh = 24: BitPlanes = 4: CurPalette = 3: AllPlanes = 0
'BitPlanes (bits: colors)
'  1:2   SNES/GameBoy
'  2:4   SNES/GameBoy
'  3:8   SNES compressed
'  4:16  SNES sprite mode
'  8:256 SNES only
'CurPalette
'  0:User palette
'  1:Normal gray
'  2:Inverse gray
'  3:Default VGA palette
'  4,5:Dumb rainbow palettes (don't ask me why I made them)
'  The reason why CurPalette is set to VGA default is because when you first
'  start, the user palette is completely blank and would only show blackness.
'AllPlanes
'  0:All planes on and showing
'  1:Filter out all but one plane
'  2:Filter out a single plane

' If you have Qb 4.5, you can enable this line to be able to pass filenames
' from the command line. Not available with normal Qbasic 1.1 for MS-DOS.
'IF LEN(COMMAND$) THEN file$ = COMMAND$: GOTO CheckRomName

StartingScreen:
GOSUB ResetTextScreen
PRINT "SNES/GameBoy Sprite Reader (any color) v0.4"
PRINT "Programmed by FDwR, starting on 2-98"
PRINT "Thanks to VileWrath for the example translation code"
PRINT
PRINT "Type in the path and filename of the ROM you want to view"
PRINT "Or type *.* to get a full directory list, *.s?c for ROMs only"
DO
 GOSUB GetFileName 'Get name of the ROM from user
CheckRomName:
 'IF INSTR(file$, "MARIO") THEN
 ' FileBase& = 286249
 'ELSEIF INSTR(file$, "ZELDA") THEN
 ' 'filebase& = 549825
 ' 'filebase& = 541185
 ' FileBase& = 529953
 'ELSEIF INSTR(file$, "TEST.SMC") THEN
 ' FileBase& = 978
 'ELSEIF file$ = "=" THEN
 ' IF LEN(ROMfileName$) THEN
 '  file$ = ROMfileName$
 ' ELSE
 '  filelen& = 0
 '  NewFileNum = 0
 '  EXIT DO
 ' END IF
 'filebase& = 459265 for super metroid
 IF file$ > "" THEN
   FileBase& = 1
 ELSEIF LEN(ROMfileName$) THEN
   file$ = ROMfileName$
 ELSE
   FileLen& = 0
   ErrorNum = -1
   EXIT DO
 END IF
 GOSUB OpenBinaryFile 'Try to open ROM, if can't then print an error message
LOOP WHILE ErrorNum     'If open is successful, exit loop

IF ErrorNum = 0 THEN
 ROMfileNum = NewFileNum
 ROMfileName$ = file$
 FileLen& = LOF(1)
 FilePos& = FileBase&
END IF

GOSUB ResetViewingScreen
GOSUB SetViewValues

LOCATE 25, 1: PRINT "Size:"; FileLen&; "bytes,"; INT((FileLen& - 512) / 131072); "Mbits";
'Actually, the formula for calculating the megabits only works for ROM
'images stored with a 512 byte header, by subtracting the file header from
'the file length and then dividing it. Any other format or pure binaries
'will not show the right size. Not that big of a deal though.
TilesRemain = TilesSquare
'Below is the main loop where key input and tile drawing are coordinated
DO
 Key$ = INKEY$: IF LEN(Key$) THEN GOSUB DecideKeyInput

 IF TilesRemain THEN
  GOSUB DrawTile
  ViewX = ViewX + 8: FilePos& = FilePos& + NextTile
  IF ViewX >= LastCol THEN ViewY = ViewY + 8: ViewX = 0: FilePos& = FilePos& + RowAlignment
  IF ViewY >= LastRow THEN ViewY = 0: FilePos& = FileBase&
  TilesRemain = TilesRemain - 1
  IF TilesRemain = 0 THEN ViewX = 0: ViewY = 0: FilePos& = FileBase&: JustUpdated = 0
 END IF

 IF UpdateStatus AND NOT JustUpdated THEN
  LOCATE 25, 1: PRINT "Filepos:"; FileBase&; "Bits:"; BitPlanes; "Jump:"; RowAlignment; TAB(40);
  LOCATE 6, 20: PRINT "Pal:"; MID$("User   Gray   InvGrayDefaultRainbowSmooth ", CurPalette * 7 + 1, 7);
  LOCATE 7, 20: PRINT "Palette base:"; PalBase; TAB(40);
  LOCATE 8, 20: PRINT "Planes:"; MID$("all    single exclude", AllPlanes * 7 + 1, 7);
  LOCATE 9, 20: PRINT "Current plane:"; CurPlane;
  
  UpdateStatus = 0: IF TilesRemain THEN JustUpdated = -1
 END IF
LOOP

DecideKeyInput:
 SELECT CASE UCASE$(Key$)
 CASE CHR$(0) + "P": FileBase& = FileBase& + NextRow: FilePos& = FilePos& + NextRow: TilesRemain = TilesSquare
 CASE CHR$(0) + "H": IF FileBase& - NextRow > 0 THEN FileBase& = FileBase& - NextRow: FilePos& = FilePos& - NextRow: TilesRemain = TilesSquare
 CASE CHR$(0) + "M": FileBase& = FileBase& + NextTile: FilePos& = FilePos& + NextTile: TilesRemain = TilesSquare
 CASE CHR$(0) + "K": IF FileBase& - NextTile > 0 THEN FileBase& = FileBase& - NextTile: FilePos& = FilePos& - NextTile: TilesRemain = TilesSquare
 CASE CHR$(0) + "Q": FileBase& = FileBase& + NextPage&: FilePos& = FilePos& + NextPage&: TilesRemain = TilesSquare
 CASE CHR$(0) + "I": IF FileBase& - NextPage& > 0 THEN FileBase& = FileBase& - NextPage&: FilePos& = FilePos& - NextPage&: TilesRemain = TilesSquare
 CASE "+": FileBase& = FileBase& + 1: FilePos& = FilePos& + 1: TilesRemain = TilesSquare
 CASE "-": IF FileBase& > 1 THEN FileBase& = FileBase& - 1: FilePos& = FilePos& - 1: TilesRemain = TilesSquare
 CASE "*": IF TilesWide < 32 THEN NewTilesWide = TilesWide + 1: GOSUB ResizeViewingWindow
 CASE "/": IF TilesWide > 0 THEN NewTilesWide = TilesWide - 1: GOSUB ResizeViewingWindow
 CASE "1", "2", "3", "4", "7", "8"
  BitPlanes = VAL(Key$): FilePos& = FileBase&: ViewX = 0: ViewY = 0: JustUpdated = 0: TilesRemain = TilesSquare: IF BitPlanes = 7 THEN BitPlanes = 8: ViewMode = 1 ELSE ViewMode = 0
  GOSUB SetViewValues
 CASE CHR$(0) + "R": PalBase = PalBase + Colors AND 255: GOSUB SetPalette
 CASE CHR$(0) + "S": PalBase = PalBase - Colors AND 255: GOSUB SetPalette
 CASE "L": GOSUB LoadPalette
 CASE "P": GOSUB SavePalette
 CASE "V": GOSUB EditPaletteColors
 CASE "Q": TileDrawSlow = TileDrawSlow XOR 1
 CASE "W": GOSUB SaveToPcx
 CASE "G": LOCATE 1, 20: INPUT "Goto:", newbase&: LOCATE 1, 20: PRINT SPACE$(20);
  IF newbase& > 0 AND newbase& < FileLen& THEN FileBase& = newbase&: FilePos& = FileBase&: ViewX = 0: ViewY = 0: JustUpdated = 0: TilesRemain = TilesSquare
 CASE CHR$(0) + ";": GOSUB ShowHelp
 CASE CHR$(0) + "<", CHR$(0) + "=", CHR$(0) + ">", CHR$(0) + "?", CHR$(0) + "@", CHR$(0) + "A", CHR$(0) + "B"
  CurPalette = INSTR("<=>?@AB", UCASE$(RIGHT$(Key$, 1))) - 1: GOSUB SetPalette: JustUpdated = 0
 CASE CHR$(0) + "C": GOSUB ScreenPalToUserPalette
 CASE CHR$(13): CLOSE ROMfileNum: GOTO StartingScreen
 CASE "U": LOCATE 1, 20: LINE INPUT "Shift palette:", Key$: LOCATE 1, 20: PRINT SPACE$(20);
  IF LEN(Key$) THEN PalShift = VAL(Key$): PalBase = 0: GOSUB TransposePaletteBlock
 CASE "A", "S", "E": AllPlanes = INSTR("ASE", UCASE$(Key$)) - 1: JustUpdated = 0: TilesRemain = TilesSquare
 CASE "B": LOCATE 1, 20: PRINT "Plane:Û"; : DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$): LOCATE 1, 20: PRINT SPACE$(20);
  IF Key$ >= "0" AND Key$ <= "7" THEN CurPlane = VAL(Key$): JustUpdated = 0: TilesRemain = TilesSquare
 CASE "R": LOCATE 1, 20: LINE INPUT "Row spacing:", Key$: LOCATE 1, 20: PRINT SPACE$(20);
  IF Key$ >= "0" THEN RowAlignment = VAL(Key$): JustUpdated = 0: TilesRemain = TilesSquare
 CASE "T": LOCATE 1, 20: LINE INPUT "Tile size:", Key$: LOCATE 1, 20: PRINT SPACE$(20);
  IF Key$ >= "0" THEN NextTile = VAL(Key$): JustUpdated = 0: TilesRemain = TilesSquare
 CASE CHR$(27): GOTO EndProgram
 END SELECT
 UpdateStatus = 1
RETURN

DrawTile:
'Read in a whole tile, exact number of bytes depends on bitmode
 IF ROMfileNum <= 0 THEN RETURN
 GET ROMfileNum, FilePos&, tile$
 IF TileDrawSlow GOTO DrawSlowTile

'!! Do not mess with the code immediately below !!
'Changing the number of parameters will cause the routine to adjust the stack
'wrong, which will cause the program to freeze. Note that they are passed in
'reverse format from the Qb point of view. If you are not familiar with how
'to interface with assembly, that's fine (actually, that is probably most of
'you out there). Just look below to DrawSlowTile instead.

'Parameters passed: (all are 16bit words, or short integers)
'raw data source offset  (the tile read in from the file)
'         source segment
'linear bitmap destination offset  (in this case, the screen is the bitmap)
'              destination segment
'bitplanes (only 1,2,3,4,8, other values will display junk)
'linear bitmap width (the screen width in mode 13 is 320 pixels)

 Index = (ViewY * 320& + ViewX - 32768) XOR -32768
 DEF SEG = VARSEG(TileTransCode(0))
 CALL Absolute(BYVAL 320, BYVAL BitPlanes, BYVAL &HA000, BYVAL Index, BYVAL VARSEG(tile$), BYVAL SADD(tile$), VARPTR(TileTransCode(0)))
RETURN

DrawSlowTile: 'Here is what actually does it ;-)
'This routine is used for the mode 7 and bitplane separated graphics.
'As of yet, only this one and not the assembly can display mode 7 and support
'bitplane filtering and exclusion (used for my early bitmode 3 debugging).
'Even though the assembly actually has a routine in it to display mode 7
'graphics, it has simply not implemented yet.

'This part is used for mode 7
 IF ViewMode THEN
  DEF SEG = VARSEG(tile$)
  BytePos = SADD(tile$)
  FOR RowCount = 0 TO 7
   ViewYrow = ViewY + RowCount
   PSET (ViewX, ViewYrow), PEEK(BytePos)
   PSET (ViewX + 1, ViewYrow), PEEK(BytePos + 2)
   PSET (ViewX + 2, ViewYrow), PEEK(BytePos + 4)
   PSET (ViewX + 3, ViewYrow), PEEK(BytePos + 6)
   PSET (ViewX + 4, ViewYrow), PEEK(BytePos + 8)
   PSET (ViewX + 5, ViewYrow), PEEK(BytePos + 10)
   PSET (ViewX + 6, ViewYrow), PEEK(BytePos + 12)
   PSET (ViewX + 7, ViewYrow), PEEK(BytePos + 14)
   BytePos = BytePos + 16
  NEXT RowCount
  RETURN
 END IF

'The rest of the sub is used for normal SNES/Gameboy bitplane separated modes
 IF AllPlanes THEN FilterPlane = CurPlane ELSE FilterPlane = -1
 IF AllPlanes AND 1 THEN InversePlanes = -1 ELSE InversePlanes = 0
'Reset plane pointers
 PlaneStepOfset = PlanePattern(BitPlanes)
 FOR plane = 0 TO LastPlane
  PlanePointer(plane) = PlaneBase(plane)
  planeStep(plane) = PlaneInc(plane + PlaneStepOfset)
 NEXT plane
 FOR RowCount = 0 TO 7
  p1 = 0: p2 = 0: p3 = 0: p4 = 0: p5 = 0: p6 = 0: p7 = 0: p8 = 0

'Separate each bit from the raw data left to right (pixels are reversed);
'Then if is set, OR BitShift to the pixel until we get full pixel depth.
  BitShift = 1
  FOR plane = 0 TO LastPlane
   IF plane <> FilterPlane XOR InversePlanes THEN
    Byte = ASC(MID$(tile$, PlanePointer(plane) + 1, 1))
    IF Byte AND 128 THEN p1 = p1 OR BitShift
    IF Byte AND 64 THEN p2 = p2 OR BitShift
    IF Byte AND 32 THEN p3 = p3 OR BitShift
    IF Byte AND 16 THEN p4 = p4 OR BitShift
    IF Byte AND 8 THEN p5 = p5 OR BitShift
    IF Byte AND 4 THEN p6 = p6 OR BitShift
    IF Byte AND 2 THEN p7 = p7 OR BitShift
    IF Byte AND 1 THEN p8 = p8 OR BitShift
   END IF
   PlanePointer(plane) = PlanePointer(plane) + planeStep(plane)
   BitShift = BitShift * 2
  NEXT plane

'Draw all eight pixels to the screen
  ViewYrow = ViewY + RowCount
  PSET (ViewX, ViewYrow), p1
  PSET (ViewX + 1, ViewYrow), p2
  PSET (ViewX + 2, ViewYrow), p3
  PSET (ViewX + 3, ViewYrow), p4
  PSET (ViewX + 4, ViewYrow), p5
  PSET (ViewX + 5, ViewYrow), p6
  PSET (ViewX + 6, ViewYrow), p7
  PSET (ViewX + 7, ViewYrow), p8
 NEXT RowCount
RETURN

SetViewValues:
 Colors = 2 ^ BitPlanes
 LastPlane = BitPlanes - 1
 NextTile = 8 * BitPlanes
 IF ViewMode THEN NextTile = NextTile * 2
'The plane depth (bits per pixel) can change but tiles are always 8x8,
'So use the formula (8 * 8 * bitplanes) \ 8 to figure the size. Actually,
'since the two 8's simply cancel each other, just use 8 * bitplanes.
 LastCol = TilesWide * 8: LastRow = TilesHeigh * 8
 NextRow = TilesWide * NextTile + RowAlignment
 NextPage& = TilesHeigh * CLNG(NextRow)
 TilesSquare = TilesWide * TilesHeigh
 tile$ = SPACE$(NextTile)

 LOCATE 2, 20: PRINT "Tile size:"; NextTile;
 LOCATE 3, 20: PRINT "Page size:"; NextPage&;
 LOCATE 4, 20: PRINT "Window size:"; TilesHeigh; TilesWide;
RETURN

SetPalette:
'This routine uses the VGA palette registers for extra speed (actually much
'more speed ;-) They are auto incrementing, so once you reset it to color
'index 0 by using port &H3C8 (968d), simply outputting all your color values
'(range 0-63) to port &h3C9 (969d) does it all.
 Colors = 2 ^ BitPlanes
'If no palette has been loaded into the user palette, then set to default VGA
'palette so that screen is not all black.
 IF CurPalette + PaletteLoaded = 0 THEN CurPalette = 3
 IF CurPalette THEN DEF SEG = VARSEG(ScrnPalette(0)): BytePos = VARPTR(ScrnPalette(0))
 SELECT CASE CurPalette
 CASE 0 'Your palette, loaded from a game snapshot
  DEF SEG = VARSEG(UserPalette(0))
  BytePos = VARPTR(UserPalette(0)) + PalBase * 3
  Index = 256 - PalBase
  FOR CurColor = 0 TO 255
   OUT &H3C9, PEEK(BytePos) \ 4
   OUT &H3C9, PEEK(BytePos + 1) \ 4
   OUT &H3C9, PEEK(BytePos + 2) \ 4
   IF CurColor = Index THEN BytePos = VARPTR(UserPalette(0)) ELSE BytePos = BytePos + 3
  NEXT CurColor
  RETURN
 CASE 1 'Grey palette
  ColorFactor! = 256 / Colors
  FOR CurColor = 0 TO Colors - 1
   RGBvalue = INT(CurColor * ColorFactor!)
   POKE BytePos, RGBvalue
   POKE BytePos + 1, RGBvalue
   POKE BytePos + 2, RGBvalue
   BytePos = BytePos + 3
  NEXT CurColor
 CASE 2 'Inverse grey palette
  ColorFactor! = 256 / Colors
  FOR CurColor = 0 TO Colors - 1
   RGBvalue = 255 - INT(CurColor * ColorFactor!)
   POKE BytePos, RGBvalue
   POKE BytePos + 1, RGBvalue
   POKE BytePos + 2, RGBvalue
   BytePos = BytePos + 3
  NEXT CurColor
 CASE 3 'Default VGA palette
  PALETTE
  OUT &H3C8, 1 'Don't ask me why it starts on a one ??
  FOR BytePos = BytePos TO 767 + BytePos STEP 3
   POKE BytePos, INP(&H3C9) * 4
   POKE BytePos + 1, INP(&H3C9) * 4
   POKE BytePos + 2, INP(&H3C9) * 4
  NEXT BytePos
  RETURN
 CASE 4 'A simple rainbow
  POKE BytePos, 0  'Set background to black
  POKE BytePos + 1, 0
  POKE BytePos + 2, 0
  BytePos = 3
  RedValue = 0: RedInc = 1
  GreenValue = 0: GreenInc = 0
  BlueValue = 63: BlueInc = -1
  FOR CurColor = 1 TO 255
   POKE BytePos, RedValue * 4: RedValue = RedValue + RedInc
   POKE BytePos + 1, GreenValue * 4: GreenValue = GreenValue + GreenInc
   POKE BytePos + 2, BlueValue * 4: BlueValue = BlueValue + BlueInc
   BytePos = BytePos + 3
   IF RedValue < 0 THEN RedInc = 0: RedValue = 0: BlueInc = 1 ELSE IF RedValue > 63 THEN RedInc = -1: RedValue = 63
   IF GreenValue > 63 THEN GreenInc = -1: GreenValue = 63 ELSE IF GreenValue < 0 THEN GreenInc = 0: GreenValue = 0: RedInc = 1
   IF BlueValue > 63 THEN BlueInc = -1: BlueValue = 63 ELSE IF BlueValue < 0 THEN BlueInc = 0: BlueValue = 0: GreenInc = 1
  NEXT CurColor
 CASE 5 'A slower but smoother rainbow using SIN
  POKE BytePos, 0  'Set background to black
  POKE BytePos + 1, 0
  POKE BytePos + 2, 0
  BytePos = 3
  ColorFactor# = 6.283186# / Colors
  FOR CurColor = 1 TO Colors - 1
   RGBvalue# = CurColor * ColorFactor#'CurColor * .0245436953125#
   POKE BytePos, SIN(RGBvalue#) * 127 + 128 'Red
   POKE BytePos + 1, SIN(RGBvalue# + 2.09439519620768#) * 127 + 128 'Green
   POKE BytePos + 2, SIN(RGBvalue# + 4.188790639241536#) * 127 + 128'Blue
   BytePos = BytePos + 3
  NEXT CurColor
 END SELECT
 OUT &H3C8, 0
 BytePos = VARPTR(ScrnPalette(0))
 FOR BytePos = BytePos TO 767 + BytePos STEP 3
  OUT &H3C9, PEEK(BytePos) \ 4
  OUT &H3C9, PEEK(BytePos + 1) \ 4
  OUT &H3C9, PEEK(BytePos + 2) \ 4
 NEXT BytePos
RETURN

ResizeViewingWindow:
 IF NewTilesWide < TilesWide THEN
  LINE (LastCol, 0)-(NewTilesWide * 8, LastRow - 1), 0, BF
 END IF
 TilesWide = NewTilesWide
 FilePos& = FileBase&: ViewX = 0: ViewY = 0
 GOSUB SetViewValues
 TilesRemain = TilesSquare
RETURN

LoadPalette:
 GOSUB ResetTextScreen
 PRINT "Type in the filename of the picture or palette you want to grab colors from"
 PRINT "It can be any one of these file types: GIF, BMP, PCX, PAL"
 PRINT "You can also use *.* for a directory listing."
 DO
  GOSUB GetFileName
  IF file$ = "" GOTO ResetViewingScreen
  IF INSTR(".BMP.GIF.PCX.PAL", RIGHT$(file$, 4)) AND LEN(file$) > 4 THEN
   GOSUB OpenBinaryFile
  ELSE
   PRINT "Unsupported picture format, please stick to one of the more common ones": ErrorNum = -1
  END IF
 LOOP WHILE ErrorNum

 IF RIGHT$(file$, 4) = ".BMP" THEN
  FilePalette$ = SPACE$(1024)
  GET NewFileNum, 55, FilePalette$ 'assuming a standard 256-color Windows bitmap
  DEF SEG = VARSEG(UserPalette(0))
  Index = VARPTR(UserPalette(0))
  FOR BytePos = 1 TO 1024 STEP 4
   POKE Index, ASC(MID$(FilePalette$, BytePos, 1))
   POKE Index + 1, ASC(MID$(FilePalette$, BytePos + 1, 1))
   POKE Index + 2, ASC(MID$(FilePalette$, BytePos + 2, 1))
   Index = Index + 3
  NEXT BytePos
 ELSEIF RIGHT$(file$, 4) = ".PAL" THEN
  IF LOF(NewFileNum) < 768 THEN FilePalette$ = SPACE$(LOF(NewFileNum)) ELSE FilePalette$ = SPACE$(768)
  GET NewFileNum, 1, FilePalette$
  Index = 0
  FOR BytePos = 1 TO LEN(FilePalette$) STEP 2
   UserPalette(Index) = CVI(MID$(FilePalette$, BytePos, 2))
   Index = Index + 1
  NEXT BytePos
 ELSE
  FilePalette$ = SPACE$(768)
  IF RIGHT$(file$, 4) = ".PCX" THEN 'standard 256-color pcx palette
   GET NewFileNum, LOF(NewFileNum) - 767, FilePalette$
  ELSE 'standard 256-color gif palette
   GET NewFileNum, 13, FilePalette$
  END IF
  Index = 0
  FOR BytePos = 1 TO 768 STEP 2
   UserPalette(Index) = CVI(MID$(FilePalette$, BytePos, 2))
   Index = Index + 1
  NEXT BytePos
 END IF
 CLOSE NewFileNum

 FilePalette$ = ""
 PaletteLoaded = 1
 PalBase = 0
 CurPalette = 0 'Set to the current palette to the one just loaded in
GOTO ResetViewingScreen

SavePalette:
 GOSUB ResetTextScreen
 PRINT "Type in the filename to save this palette as, or nothing to cancel"
 DO
  GOSUB GetFileName
  GOSUB QuestionFileOverwrite
  IF ErrorNum = 0 THEN GOSUB OpenOutputFile
 LOOP WHILE ErrorNum
 GOSUB WritePaletteToFile
 CLOSE NewFileNum
GOTO ResetViewingScreen

WritePaletteToFile: 'assumes a file is already open
 IF CurPalette THEN
  DEF SEG = VARSEG(ScrnPalette(0))
  BytePos = VARPTR(ScrnPalette(0))
  FOR BytePos = BytePos TO 767 + BytePos STEP 3
   PRINT #NewFileNum, CHR$(PEEK(BytePos));
   PRINT #NewFileNum, CHR$(PEEK(BytePos + 1));
   PRINT #NewFileNum, CHR$(PEEK(BytePos + 2));
  NEXT BytePos
 ELSE
  IF PalBase THEN PalShift = PalBase: GOSUB TransposePaletteBlock: PalBase = (256 - PalBase) AND 255
  FOR Index = 0 TO 383
   PRINT #NewFileNum, MKI$(UserPalette(Index));
  NEXT Index
 END IF
RETURN

TransposePaletteBlock: 'shift palette forwards or backwards
'Most games have their total 256 color palette split into smaller palettes,
'or as I will call pages. The average game (not StarFox or mode 7 games),
'has sixteen palettes with sixteen colors each. Although I read somewhere
'that only eight of those are used for sprites, and the other eight are used
'for playfield tiles or something. When you load a palette from a snapshot,
'the first page of colors is visible. To access other pages, you simply shift
'the color base higher or lower. For normal sprites, just leave the number of
'colors per page at 16. For other bitmodes, you might try their color number
'instead to access more pages. If you want a certain page of your palette to
'always be first when loaded, you must actually shift the colors rather than
'simply their base...that is what this is for.
 PalShift = PalShift AND 255
 REDIM DummyPalette(0 TO 383)
 DummyPalSeg = VARSEG(DummyPalette(0))
 UserPalSeg = VARSEG(UserPalette(0))
 Index = VARPTR(UserPalette(0))
 BytePos = VARPTR(DummyPalette(0)) + (256 - PalShift) * 3
 FOR RowCount = 0 TO PalShift - 1
  DEF SEG = UserPalSeg: RedValue = PEEK(Index): GreenValue = PEEK(Index + 1): BlueValue = PEEK(Index + 2)
  Index = Index + 3
  DEF SEG = DummyPalSeg: POKE BytePos, RedValue: POKE BytePos + 1, GreenValue: POKE BytePos + 2, BlueValue
  BytePos = BytePos + 3
 NEXT RowCount
 Index = VARPTR(UserPalette(0)) + PalShift * 3
 BytePos = VARPTR(DummyPalette(0))
 FOR RowCount = PalShift TO 255
  DEF SEG = UserPalSeg: RedValue = PEEK(Index): GreenValue = PEEK(Index + 1): BlueValue = PEEK(Index + 2)
  Index = Index + 3
  DEF SEG = DummyPalSeg: POKE BytePos, RedValue: POKE BytePos + 1, GreenValue: POKE BytePos + 2, BlueValue
  BytePos = BytePos + 3
 NEXT RowCount
 FOR Index = 0 TO 383
  UserPalette(Index) = DummyPalette(Index)
 NEXT Index
 ERASE DummyPalette
 IF CurPalette = 0 THEN GOSUB SetPalette
RETURN

ScreenPalToUserPalette:
 FOR Index = 0 TO 383
  UserPalette(Index) = ScrnPalette(Index)
 NEXT Index
 CurPalette = 0
 PaletteLoaded = 1
RETURN

EditPaletteColors:
 CLS
 IF PalBase THEN PalShift = PalBase: GOSUB SetPalette: PalBase = PalShift
 CurColor = 0
 FOR RowCount = 0 TO 180 STEP 12
  FOR ColCount = 0 TO 240 STEP 16
   LINE (ColCount, RowCount)-(ColCount + 15, RowCount + 11), CurColor, BF
   CurColor = CurColor + 1
  NEXT ColCount
 NEXT RowCount
 IF CurPalette <> 0 OR PaletteLoaded = 0 THEN
  LOCATE 25, 1
  PRINT "Only the user palette can be edited..."; TAB(40);
  SLEEP: WHILE LEN(INKEY$): WEND
  GOTO ReturnFromPaletteEditor
 END IF
 CurColor = 0
 CursorLocked = 0
 RedrawCell = 1
 DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE CHR$(0) + "H": OldCursorIndex = CursorColorIndex: CursorColorIndex = CursorColorIndex - 16 AND 255
  CASE CHR$(0) + "P": OldCursorIndex = CursorColorIndex: CursorColorIndex = CursorColorIndex + 16 AND 255
  CASE CHR$(0) + "K": OldCursorIndex = CursorColorIndex: CursorColorIndex = CursorColorIndex - 1 AND 255
  CASE CHR$(0) + "M": OldCursorIndex = CursorColorIndex: CursorColorIndex = CursorColorIndex + 1 AND 255
  CASE "": CursorLocked = 0: RedrawCell = 1
  CASE CHR$(0) + "R": PalShift = 16: GOSUB TransposePaletteBlock
  CASE CHR$(0) + "S": PalShift = -16: GOSUB TransposePaletteBlock
  CASE CHR$(0) + "t": PalShift = 1: GOSUB TransposePaletteBlock
  CASE CHR$(0) + "s": PalShift = -1: GOSUB TransposePaletteBlock
  CASE CHR$(9): OverWriteColor = OverWriteColor XOR 1: RedrawCell = 1
  CASE " ": RedrawCell = 1: IF CursorLocked THEN GOSUB MoveColors: CursorLocked = 0 ELSE CursorLocked = 1: LockedColorIndex = CursorColorIndex
  CASE CHR$(13): LOCATE 25, 1: PRINT TAB(40); : GOSUB EditPaletteValue: RedrawCell = 1
  CASE CHR$(27): EXIT DO
  END SELECT
  IF OldCursorIndex <> CursorColorIndex OR RedrawCell THEN
   RowCount = (OldCursorIndex \ 16) * 12
   ColCount = (OldCursorIndex AND 15) * 16
   LINE (ColCount, RowCount)-(ColCount + 15, RowCount + 11), OldCursorIndex, BF
   OldCursorIndex = CursorColorIndex
   RedrawCell = 0
   DEF SEG = VARSEG(UserPalette(0))
   Index = VARPTR(UserPalette(0)) + (CursorColorIndex * 3)
   LOCATE 25, 1: PRINT PEEK(Index); PEEK(Index + 1); PEEK(Index + 2); TAB(20); "Overwrite is "; MID$("offon ", OverWriteColor * 3 + 1, 3);
  END IF
  IF TIMER <> LastTime% THEN
   RowCount = (CursorColorIndex \ 16) * 12
   ColCount = (CursorColorIndex AND 15) * 16
   IF CursorLocked THEN
    LINE (ColCount + 4, RowCount + 4)-(ColCount + 11, RowCount + 7), LockedColorIndex, BF
    LINE (ColCount + 3, RowCount + 3)-(ColCount + 12, RowCount + 8), CurColor, B
   ELSE
    LINE (ColCount, RowCount)-(ColCount + 15, RowCount + 11), CurColor, B
   END IF
   CurColor = CurColor + 1 AND 255
  END IF
 LOOP
ReturnFromPaletteEditor:
 CLS
 TilesRemain = TilesSquare
RETURN

EditPaletteValue:
 LOCATE 25, 1: LINE INPUT ; "New RGB value:", Key$
 IF Key$ = "" THEN RETURN
 DEF SEG = VARSEG(UserPalette(0))
 BytePos = VARPTR(UserPalette(0)) + (CursorColorIndex * 3)
 OUT &H3C8, CursorColorIndex
 ON ERROR GOTO ErrorHandler: ErrorNum = 0
 FOR Index = 1 TO 3
  Key$ = LTRIM$(Key$): IF Key$ = "" THEN EXIT FOR
  NextPos = INSTR(Key$, " "): IF NextPos = 0 THEN NextPos = LEN(Key$) + 1
  RGBvalue = VAL(MID$(Key$, 1, NextPos)): IF ErrorNum THEN EXIT FOR
  POKE BytePos, RGBvalue: OUT &H3C9, RGBvalue \ 4
  BytePos = BytePos + 1
  Key$ = MID$(Key$, NextPos)
 NEXT Index
 ON ERROR GOTO 0
 LOCATE 25, 1: PRINT TAB(40);
RETURN

MoveColors:
 DEF SEG = VARSEG(UserPalette(0))
 BytePos = VARPTR(UserPalette(0)) + (LockedColorIndex * 3)
 Index = VARPTR(UserPalette(0)) + (CursorColorIndex * 3)
 IF OverWriteColor THEN
  POKE Index, PEEK(BytePos)
  POKE Index + 1, PEEK(BytePos + 1)
  POKE Index + 2, PEEK(BytePos + 2)
 ELSE
  Byte = PEEK(BytePos): POKE BytePos, PEEK(Index): POKE Index, Byte
  Byte = PEEK(BytePos + 1): POKE BytePos + 1, PEEK(Index + 1): POKE Index + 1, Byte
  Byte = PEEK(BytePos + 2): POKE BytePos + 2, PEEK(Index + 2): POKE Index + 2, Byte
 END IF
 GOSUB SetPalette
RETURN

SaveToPcx:
 GOSUB ResetTextScreen
 IF ROMfileNum < 1 THEN
  PRINT "Viewing window is empty, only palette should be saved? Y/N"
  SLEEP: IF UCASE$(INKEY$) <> "Y" GOTO ResetViewingScreen
 END IF
 PRINT "Type in the pcx filename to save the screen window to, or nothing to cancel"
 DO
  GOSUB GetFileName
  GOSUB QuestionFileOverwrite
  IF ErrorNum = 0 THEN GOSUB OpenOutputFile
 LOOP WHILE ErrorNum

 RowBytes = TilesWide * 8
 REDIM ImageBuffer(0 TO 8191) AS DOUBLE
 DEF SEG = VARSEG(ImageBuffer(0))
 Index& = VARPTR(ImageBuffer(0))

 IF ROMfileNum < 1 GOTO StartCompressing
 PRINT "Loading and translating tiles"
 FilePos& = FileBase&: tiles = 0

'I know the code below is a little redundant, but for now it works.
'Eventually it will be replaced by one simple assembly call, since there is
'already a near exact copy of this code above (when it draws to the screen).

 IF AllPlanes THEN FilterPlane = CurPlane ELSE FilterPlane = -1
 IF AllPlanes AND 1 THEN InversePlanes = -1 ELSE InversePlanes = 0
 FOR row = 0 TO 23
  FOR col = 1 TO TilesWide
   GET ROMfileNum, FilePos&, tile$
   IF ViewMode THEN
    BytePos = SADD(tile$)
   ELSE
    'Reset plane pointers
    PlaneStepOfset = PlanePattern(BitPlanes)
    FOR plane = 0 TO LastPlane
     PlanePointer(plane) = PlaneBase(plane)
     planeStep(plane) = PlaneInc(plane + PlaneStepOfset)
    NEXT plane
   END IF
   FOR RowCount = 0 TO 7
    IF ViewMode THEN
     DEF SEG = VARSEG(tile$)
     p1 = PEEK(BytePos)
     p2 = PEEK(BytePos + 2)
     p3 = PEEK(BytePos + 4)
     p4 = PEEK(BytePos + 6)
     p5 = PEEK(BytePos + 8)
     p6 = PEEK(BytePos + 10)
     p7 = PEEK(BytePos + 12)
     p8 = PEEK(BytePos + 14)
     BytePos = BytePos + 16
     DEF SEG = VARSEG(ImageBuffer(0))
     GOTO PixelsToPcxBuffer
    END IF
  
    p1 = 0: p2 = 0: p3 = 0: p4 = 0: p5 = 0: p6 = 0: p7 = 0: p8 = 0
    BitShift = 1
    FOR plane = 0 TO LastPlane
     IF plane <> FilterPlane XOR InversePlanes THEN
      Byte = ASC(MID$(tile$, PlanePointer(plane) + 1, 1))
      IF Byte AND 128 THEN p1 = p1 OR BitShift
      IF Byte AND 64 THEN p2 = p2 OR BitShift
      IF Byte AND 32 THEN p3 = p3 OR BitShift
      IF Byte AND 16 THEN p4 = p4 OR BitShift
      IF Byte AND 8 THEN p5 = p5 OR BitShift
      IF Byte AND 4 THEN p6 = p6 OR BitShift
      IF Byte AND 2 THEN p7 = p7 OR BitShift
      IF Byte AND 1 THEN p8 = p8 OR BitShift
     END IF
     PlanePointer(plane) = PlanePointer(plane) + planeStep(plane)
     BitShift = BitShift * 2
    NEXT plane

PixelsToPcxBuffer:
    POKE Index&, p1
    POKE Index& + 1, p2
    POKE Index& + 2, p3
    POKE Index& + 3, p4
    POKE Index& + 4, p5
    POKE Index& + 5, p6
    POKE Index& + 6, p7
    POKE Index& + 7, p8
   
    Index& = Index& + RowBytes
   NEXT RowCount
   Index& = Index& - RowBytes * 8 + 8
   FilePos& = FilePos& + NextTile
  NEXT col
  Index& = Index& + RowBytes * 7
  tiles = tiles + 100
  LOCATE , 1: PRINT "%"; LTRIM$(STR$(tiles \ TilesHeigh));
 NEXT row

'If you do not understand the code below, that's fine. First all of all, it
'is not even the focus of this program; and second, it confused me more than
'anything (even the graphics modes) and sometimes still does a little. (:-)
StartCompressing:
 PRINT
 PRINT "Compressing and saving to "; file$
 PRINT #NewFileNum, CHR$(10); CHR$(5); CHR$(1); CHR$(8); MKL$(0); MKI$(RowBytes - 1); MKI$(191); MKI$(320); MKI$(200); STRING$(49, 0); CHR$(1); MKI$(RowBytes); MKI$(0); STRING$(58, 0);

 Index& = VARPTR(ImageBuffer(0))
 TotalBytes& = RowBytes * 192&
 WHILE Index& < TotalBytes&
  rowlong& = Index& + RowBytes
  rowrle = 0
  lastchar = PEEK(Index&)
  rlecount = 1
  DO
ContinueCompression:
   Index& = Index& + 1
   IF Index& < rowlong& THEN
     char = PEEK(Index&)
     IF char = lastchar AND rlecount < 63 THEN
       rlecount = rlecount + 1
       GOTO ContinueCompression
     END IF
   END IF
   IF lastchar > 192 THEN
     PRINT #NewFileNum, CHR$(192 + rlecount); CHR$(lastchar);
   ELSE
     IF rlecount > 2 THEN PRINT #NewFileNum, CHR$(192 + rlecount); CHR$(lastchar);  ELSE PRINT #NewFileNum, STRING$(rlecount, lastchar);
   END IF
   rowrle = rowrle + rlecount
   rlecount = 1
   IF char <> lastchar THEN lastchar = char
  LOOP WHILE Index& < rowlong&
 WEND

 PRINT "Writing 256 color palette"
 PRINT #NewFileNum, CHR$(12); 'Don't ask me what the 12 is for, but pcx readers won't work without it
 GOSUB WritePaletteToFile

 PRINT "Done..."

 CLOSE NewFileNum
 ERASE ImageBuffer
 FilePos& = FileBase&

 SLEEP 2: WHILE LEN(INKEY$): WEND
GOTO ResetViewingScreen

ResetTextScreen:
 WIDTH 80, 25 'Set screen text width before mode
 SCREEN 0     'Set screen mode to text
 COLOR 7, 0   'For some reason, Qb does not always clear the entire screen
 CLS          'in the right color, so just clear it again manually
 VIEW PRINT 1 TO 25
RETURN

ResetViewingScreen:
 SCREEN 13         'our favorite screen mode with 256 colors
 GOSUB SetPalette  'the colors will look wrong if we do not
 TilesRemain = TilesSquare  'viewing window needs to be redrawn
RETURN

GetFileName:
 LINE INPUT "FileName: ", file$: file$ = UCASE$(LTRIM$(file$))
 IF file$ = "" THEN RETURN
 IF INSTR(file$, "*") THEN SHELL "DIR " + file$: GOTO GetFileName
 ON ERROR GOTO ErrorHandler: ErrorNum = 0
 CHDIR file$
 ON ERROR GOTO 0
 IF ErrorNum = 0 THEN PRINT "Directory changed": GOTO GetFileName
RETURN

OpenBinaryFile:
 NewFileNum = FREEFILE
 ON ERROR GOTO ErrorHandler: ErrorNum = 0
 OPEN file$ FOR INPUT AS NewFileNum: CLOSE NewFileNum
 ON ERROR GOTO 0
 IF ErrorNum = 53 THEN PRINT "Could not find that file": RETURN ELSE IF ErrorNum THEN PRINT "Could not open that file": RETURN
 OPEN file$ FOR BINARY AS NewFileNum
RETURN

QuestionFileOverwrite:
 IF file$ = "" THEN RETURN ResetViewingScreen
 ON ERROR GOTO ErrorHandler: ErrorNum = 0
 NewFileNum = FREEFILE: OPEN file$ FOR INPUT AS NewFileNum: CLOSE NewFileNum
 ON ERROR GOTO 0
 IF ErrorNum = 0 THEN
  PRINT "Do you want to overwrite the existing one? Y/N"
  SLEEP: IF UCASE$(INKEY$) <> "Y" THEN ErrorNum = 1
 ELSEIF ErrorNum = 53 THEN ErrorNum = 0
 ELSE PRINT "Could not save to that file"
 END IF
RETURN

OpenOutputFile:
 ON ERROR GOTO ErrorHandler: ErrorNum = 0
 OPEN file$ FOR OUTPUT AS NewFileNum
 ON ERROR GOTO 0
 IF ErrorNum THEN
  PRINT "Could not write to that file, it might be read-only or a bad name"
 END IF
RETURN

ErrorHandler:
 ErrorNum = ERR
RESUME NEXT

EndProgram:
 CLOSE
 GOSUB ResetTextScreen
END

ShowHelp:
 GOSUB ResetTextScreen
 COLOR 12: PRINT "For scrolling and viewing:": COLOR 7
 PRINT "  Up Down Left Right PgUp PgDn  You probably have a good idea of what these do"
 PRINT "  1-8   Set the bit mode to that number, only modes 1,2,3,4,7,8 actually exist"
 PRINT "  + -   Move up or down a single byte (shift bitplanes, or pixels in mode 7)"
 PRINT "  * /   Change tile wrap width, not that useful most of the time since it is"
 PRINT "        already set to the most common (16), but sometimes it really helps"
 PRINT "  R T   Change Row/Tile alignment, never mind them, they only mess things up"
 PRINT "  G     Goto to byte position in file manually entered"
 COLOR 10: PRINT "Other very useful keys:": COLOR 7
 PRINT "  Enter  Select a different file to view"
 PRINT "  F1     Show this cheap help"
 PRINT "  F2-F7  Setting a generic palette, F2=User palette, F3=Gray, F4=Inverse gray"
 PRINT "         F5=Default video colors, F6=Rainbow color, F7=Another useless one"
 PRINT "  F9     Transfer screen palette into user palette (save your old one first)"
 PRINT "  L      Load a palette in from an image file (PCX GIF BMP) or a presaved PAL"
 PRINT "  V      View current palette / Edit the user palette by moving colors around"
 PRINT "  W P      Save snapshot of window or save current palette to PAL file"
 PRINT "  Ins/Del  Change current palette page, Ins=Forward, Del=Backward"
 PRINT "  F        Actually shift palette forward, different from simply changing page"
 COLOR 9: PRINT "Plane splicing, dicing, and filtering:": COLOR 7
 PRINT "  A  All bitplanes turned on, how many there are depends on the bitmode"
 PRINT "  S  Single bitplane, show only the current one and turn all others off"
 PRINT "  E  Except a bitplane, all are on but the current one"
 PRINT "  B  Set current bitplane, then just press the number of the plane"
 PRINT "     this only applies when you use single or exclude mode";
 WHILE INKEY$ = "": WEND
GOTO ResetViewingScreen

'The pcx header output by SnesView, in case some of you actually care
'a:b   a=number of bytes, b=default value

'1:10  Manufacturer - some type of standard pcx format, do not know who
'1:5   Version - means it is a 256 color pcx, standard for PaintBrush 3.0+
'1:1   Encoding - this type of rle (0-191 are colors, 192-255 are run prefixes)
'1:0   Bits per pixel - always 8 (were in screen mode 13)
'2:0   Top - not used
'2:0   Left - just as irrelevant
'2:128 Width - usually the right width, unless you change the tile wrap
'2:192 Height - always 192
'2:320 Horizontal resolution - same reoultion as the screen mode we're using
'2:200 Vertical resolution
'48:0  Ega palette - old palette not used any more, fill in with blank space
'1:0   Reserved blank - ? who knows...
'1:1   Color planes number - simple linear bitmap, no stupid plane interleaving
'2:128 Bytes per line - width * bitsperpixel \ 8 (in other words, the width)
'2:0   Palette type - don't know what it means, just set it to zero and it works
'58:0   Blank extra padding - no real purpose, just makes the header an even 128

'TILETRAN.COM
DATA 1566,-30379,-14875,2678,32452,-18418,-24576,-16242,20107,-30446,-11829
DATA 12003,-24693,224,28299,-19180,-30712,26312,-7743,-30704,26305,-16335
DATA 12646,11986,14083,-15487,2,11402,-4656,1907,-32410,202,0,-12287,29677
DATA 26119,-13695,0,1,-4656,1907,-32410,202,1,-12288,29677,26119,-13695,1,0
DATA -4656,1651,3430,0,256,-4656,1651,3430,0,1,-4656,1651,3430,256,0,-4656
DATA 1651,3430,1,0,-11930,26312,-13615,-13826,-26251,-16026,4329,-11418,9920
DATA -30362,26117,-15661,26150,21897,260,-273,4045,28805,24063,7943,3274,7680
DATA 21766,-6775,2225,30405,-15350,3710,28299,-32494,2285,26112,26277,-32347
DATA 2246,256,-273,30155,24050,7943,2762,0,242,242,242,274,322,242,242,242,386
DATA 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,15,-14,1,14,-13,1,13,-12,1,12,-11,1
DATA 11,-10,1,10,-9,1,9,-8,1,8,0,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1
DATA 15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,0,1,15,1,15,1,15,1,-47,1,15,1,15,1
DATA 15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1
DATA 15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,0

'Now that you have looked through it all and reached the bottom, did you get
'any use out of it? If you have any comments or bug reports, please tell me
'at FDwR@Juno.com. Note that criticism won't do any good, since nobody ever
'said you had to like this. Suggestions are nice, but SpriteView is not going
'to get much more advanced than this because that would sort of lose the
'point - it might as well be coded in C if it got any more serious. If you
'have any SNES or GameBoy (or even Sega) modes that SpriteView does not
'already have though, please tell me so they can be added. ;-)

