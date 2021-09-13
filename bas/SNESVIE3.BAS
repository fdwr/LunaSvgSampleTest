'LOZ 459265 524801 560460 562832:3 562954:1 553473:3! 726604:faces!
'731772:theEnd! 731966deer? 762308manBody? 770186bombSeller 782361treasure!
'767470girl 771262bird 772131flute note
'785603startOfItems 786448skullKey 794866girl? 769667thick! 732169cannonball
'760267thick! 760654knight 764424another knight 767470bee and girl
'SMW 307851:3? SM3231269? 262656? 265865? 266313? 268073? 277133?!
'286249:Flower 286572:flowerL 289155:messageBlock 286113feather:l
' MAS 33281:8!,1409537:8!
' SM3 13889m7?

' "This sprite reader was programmed in QuickBasic so that
'  almost any programmer should be able to understand how
'  SNES sprites are encoded. Yes its sloppy, yes its slow
'  but it also took me two minutes to write. And it gives
'  you something to work on. :-) Vilewrath"

'  And work on it I did, added more bitmodes, faster bit blitting,
'  user palettes, and the ability to scroll

' Added user defined palettes, including importing screenshot palettes from
'GIF, PCX or bitmap images, some cheap color editing, and saving your modified
'palettes to a PAL file for later use.
' A new pointer table idea cut down on the redundant code so that multiple
'routines (different ones for each bit mode, aack!) would not be necessary.
' Separation of the bitplanes and exclusion of certain ones was the feature
'that gave me the chance to understand 3bit mode for Zelda. Without this
'feature, I'd still be totally confused on it. Since there might be a few more
'modes left out there in other ROMs, I simply left these 'debugging' options
'on and added a user interface.
' After long nights of trial and error I got the 3bit mode completely figured
'out for Zelda (probably used in quite a few other games too).
' It's about time that you can scroll through this like any other viewer, just
'watching the pages go by or waiting for a page to fill up and then press a
'key was stupid and slow! So now it's up there with the others as far as user
'control. You can also change to any mode by using the number keys.

DEFINT A-Z

y = CSRLIN: x = POS(0): VIEW PRINT 1 TO 25: LOCATE y, x

DIM planeBase(0 TO 7), planeInc(0 TO 10), planepattern(0 TO 8), transcode(0 TO 20)
DIM userpalette(0 TO 383), paletteloaded'(768 / 2) - 1
'Planebase tells what byte the frist row of each plane starts on
planeBase(0) = 0:  planeBase(1) = 1
planeBase(2) = 16: planeBase(3) = 17
planeBase(4) = 32: planeBase(5) = 33
planeBase(6) = 48: planeBase(7) = 49
'Planeinc tells how many bytes it is to each plane's next row
'In bitmode one, each row is immediately after the prior so the spacing is one
'In bitmodes two, four, and eight, each row comes two bytes after the prior
'In bitmode three, the two spacing patterns are combined into 2,2,1
'The first two planes are interleaved so each row is two bytes apart,
'(like bitmode two) while in the third bitplane, each row comes immediately
'after the prior row so the spacing is one (like bitmode one)
FOR plane = 0 TO 9
 planeInc(plane) = 2
NEXT plane
planeInc(10) = 1
'plane pattern is an pointer array that determines which increment pattern
'to use, in other words where to point into planeinc(?)
planepattern(1) = 10
planepattern(2) = 0
planepattern(3) = 8
planepattern(4) = 0
planepattern(8) = 0

tileswide = 16: tilesheigh = 24: CurPalette = 0: bitplanes = 4

'IF COMMAND$ > "" THEN file$ = COMMAND$: GOTO CheckFileName

StartingScreen:
WIDTH 80, 25: SCREEN 0
COLOR 7, 0
PRINT
PRINT "SNES Sprite Reader (any color) v0.01"
PRINT "Programmed by Dwayne, starting on 2-98"
PRINT "Thanks to VileWrath for the example translation code"
PRINT
PRINT "Type in the filename of the ROM you want or type *.s?c to get a directory list"
DO
 GOSUB GetFileName 'Get name of the ROM from user
 IF file$ = "" GOTO EndProgram
CheckFileName:
 IF INSTR(file$, "MARIO") THEN
  FileBase& = 286249
 'ELSEIF INSTR(file$, "ZELDA") THEN
  'filebase& = 549825
  'filebase& = 541185
  'FileBase& = 529953
 ELSEIF file$ = "=" THEN
  IF LEN(ROMfileName$) THEN
   file$ = ROMfileName$
  ELSE
   filelen& = 0
   NewFileNum = 0
   EXIT DO
  END IF
 ELSE FileBase& = 1
 END IF
 'filebase& = 459265 for super metroid
 GOSUB OpenBinaryFile 'Try to open ROM, if can't then print an error message
LOOP WHILE FilErr 'If open is successful, exit loop

IF NewFileNum THEN
 ROMfileNum = NewFileNum
 ROMfileName$ = file$
 filelen& = LOF(1)
 FilePos& = FileBase&
END IF
allplanes = 0
'curpalette
'  0: Default sixteen colors
'  1: Dynamic gray
'  2: Inverse gray
'  3: User defined
'allplanes
'  0: All planes on and showing
'  1: Filter out all but one plane
'  2: Filter out a single plane
tile$ = SPACE$(64) '8x8x4bits = 256bits \ 8 = 32 bytes
x = 0: y = 0

SCREEN 13
GOSUB DefineArrays
LOCATE 25, 27: PRINT "Size:"; filelen&;

'MainLoop
tilesremain = tilessquare
updatestatus = 1
DO
 key$ = INKEY$
 IF LEN(key$) THEN GOSUB DecideKeyIput
 IF tilesremain THEN
  GOSUB DrawTile
  x = x + 8: IF x >= lastcol THEN y = y + 8: x = 0: FilePos& = FilePos& + rowalignment
  IF y >= lastrow THEN y = 0: FilePos& = FileBase&
  tilesremain = tilesremain - 1
  IF tilesremain = 0 THEN x = 0: y = 0: FilePos& = FileBase&
 END IF
 IF updatestatus THEN
  LOCATE 25, 1: PRINT "Filepos:"; FileBase&; "Bits:"; bitplanes; "Jump:"; rowalignment; TAB(40); '27
  LOCATE 6, 20: PRINT "Planes:"; MID$("all    single exclude", allplanes * 7 + 1, 7); : LOCATE 7, 20: PRINT "Current plane:"; curplane;
  updatestatus = 0
 END IF
LOOP

DecideKeyIput:
 SELECT CASE UCASE$(key$)
 CASE CHR$(0) + "P": FileBase& = FileBase& + nextrow: FilePos& = FilePos& + nextrow: tilesremain = tilessquare
 CASE CHR$(0) + "H": IF FileBase& - nextrow > 0 THEN FileBase& = FileBase& - nextrow: FilePos& = FilePos& - nextrow: tilesremain = tilessquare
 CASE CHR$(0) + "M": FileBase& = FileBase& + nexttile: FilePos& = FilePos& + nexttile: tilesremain = tilessquare
 CASE CHR$(0) + "K": IF FileBase& - nexttile > 0 THEN FileBase& = FileBase& - nexttile: FilePos& = FilePos& - nexttile: tilesremain = tilessquare
 CASE CHR$(0) + "Q": FileBase& = FileBase& + nextpage&: FilePos& = FilePos& + nextpage&: tilesremain = tilessquare
 CASE CHR$(0) + "I": IF FileBase& - nextpage& > 0 THEN FileBase& = FileBase& - nextpage&: FilePos& = FilePos& - nextpage&: tilesremain = tilessquare
 CASE "+": FileBase& = FileBase& + 1: FilePos& = FilePos& + 1: tilesremain = tilessquare
 CASE "-": IF FileBase& > 1 THEN FileBase& = FileBase& - 1: FilePos& = FilePos& - 1: tilesremain = tilessquare
 CASE "*": IF tileswide < 32 THEN newtileswide = tileswide + 1: GOSUB ResizeViewingWindow
 CASE "/": IF tileswide > 0 THEN newtileswide = tileswide - 1: GOSUB ResizeViewingWindow
 CASE "G": LOCATE 1, 20: INPUT "Goto:", newbase&: LOCATE 1, 20: PRINT SPACE$(20);
  IF newbase& > 0 AND newbase& < filelen& THEN FileBase& = newbase&: FilePos& = FileBase&: tilesremain = tilessquare
 CASE "A": allplanes = 0: tilesremain = tilessquare 'all
 CASE "S": allplanes = 1: tilesremain = tilessquare 'single
 CASE "E": allplanes = 2: tilesremain = tilessquare 'exclude
 CASE "L": GOSUB LoadInPalette
 CASE "N": GOSUB TransposePaletteBlock
 CASE "C": GOSUB EditPaletteColors
 CASE "B": LOCATE 1, 20: PRINT "Plane:Û"; : DO: key$ = INKEY$: LOOP UNTIL LEN(key$): LOCATE 1, 20: PRINT SPACE$(20); : IF key$ >= "0" AND key$ <= "7" THEN curplane = VAL(key$): tilesremain = tilessquare
 CASE "R": LOCATE 1, 20: LINE INPUT "Row align:", key$: LOCATE 1, 20: PRINT SPACE$(20); : IF key$ >= "0" THEN rowalignment = VAL(key$): tilesremain = tilessquare
 CASE "P": GOSUB SavePalette
 CASE "W": GOSUB SaveToPcx
 CASE "1", "2", "3", "4", "7", "8": bitplanes = VAL(key$): FilePos& = FileBase&: x = 0: y = 0: tilesremain = tilessquare: GOSUB DefineArrays
 CASE CHR$(0) + ";": GOSUB ShowHelp
 CASE CHR$(0) + "<": CurPalette = 0: GOSUB SetPalette
 CASE CHR$(0) + "=": CurPalette = 1: GOSUB SetPalette
 CASE CHR$(0) + ">": CurPalette = 2: GOSUB SetPalette
 CASE CHR$(0) + "?": CurPalette = 3: GOSUB SetPalette
 CASE CHR$(0) + "@": CurPalette = 4: GOSUB SetPalette
 CASE CHR$(0) + "A": CurPalette = 5: GOSUB SetPalette
 CASE CHR$(0) + "B": CurPalette = 6: GOSUB SetPalette
 CASE CHR$(13): CLOSE ROMfileNum: GOTO StartingScreen
 CASE CHR$(27): GOTO EndProgram
 END SELECT
 updatestatus = 1
RETURN

DrawTile:
 'Read in a whole tile, exact number of bytes depends on number of colors
 IF ROMfileNum <= 0 THEN RETURN
 GET ROMfileNum, FilePos&, tile$
 IF allplanes THEN filterplane = curplane ELSE filterplane = -1
 IF allplanes AND 1 THEN inverseplanes = -1 ELSE inverseplanes = 0
 'Reset plane pointers
 planeStepOfset = planepattern(bitplanes)
 FOR plane = 0 TO lastPlane
  planePointer(plane) = planeBase(plane)
  planeStep(plane) = planeInc(plane + planeStepOfset)
 NEXT plane
  'call absolute(byval sadd(tile$), planePointer(), planeStep(), dest, varptr(transcode))
  'mov di,dest
  'Mode 7
 IF bitplanes = 7 THEN
  DEF SEG = VARSEG(tile$)
  BytePos = SADD(tile$)
  FOR rowcount = 0 TO 7
   FOR plane = 0 TO 7
    'IF plane <> filterplane XOR inverseplanes THEN
    yrow = y + rowcount
    PSET (x, yrow), PEEK(BytePos)
    PSET (x + 1, yrow), PEEK(BytePos + 2)
    PSET (x + 2, yrow), PEEK(BytePos + 4)
    PSET (x + 3, yrow), PEEK(BytePos + 6)
    PSET (x + 4, yrow), PEEK(BytePos + 8)
    PSET (x + 5, yrow), PEEK(BytePos + 10)
    PSET (x + 6, yrow), PEEK(BytePos + 12)
    PSET (x + 7, yrow), PEEK(BytePos + 14)
    'END IF
   NEXT plane
   BytePos = BytePos + 16
  NEXT rowcount
  FilePos& = FilePos& + 128 'next 8x8
  RETURN
 END IF

 FOR rowcount = 0 TO 7
  p1 = 0: p2 = 0: p3 = 0: p4 = 0: p5 = 0: p6 = 0: p7 = 0: p8 = 0

  bitshift = 1
  FOR plane = 0 TO lastPlane
   IF plane <> filterplane XOR inverseplanes THEN
   a = ASC(MID$(tile$, planePointer(plane) + 1, 1))
   IF a AND 128 THEN p1 = p1 + bitshift
   IF a AND 64 THEN p2 = p2 + bitshift
   IF a AND 32 THEN p3 = p3 + bitshift
   IF a AND 16 THEN p4 = p4 + bitshift
   IF a AND 8 THEN p5 = p5 + bitshift
   IF a AND 4 THEN p6 = p6 + bitshift
   IF a AND 2 THEN p7 = p7 + bitshift
   IF a AND 1 THEN p8 = p8 + bitshift
   END IF
   planePointer(plane) = planePointer(plane) + planeStep(plane)
   bitshift = bitshift * 2
  NEXT plane

  yrow = y + rowcount
  PSET (x, yrow), p1
  PSET (x + 1, yrow), p2
  PSET (x + 2, yrow), p3
  PSET (x + 3, yrow), p4
  PSET (x + 4, yrow), p5
  PSET (x + 5, yrow), p6
  PSET (x + 6, yrow), p7
  PSET (x + 7, yrow), p8
  'filepos& = filepos& + 2
 NEXT rowcount
 FilePos& = FilePos& + nexttile
RETURN

'The plane depth (number of colors) can change but tiles are always 8x8
'So use the formula (8 * 8 * colors) \ 8 (same as just 8 * colors) for size
'The tile is arranged from right to left (reverse bits), top to bottom
'Each byte represents one row of eight pixel bits (not complete pixels)
'The number of bytes needed for a single complete row depends on the color
'depth, or actually the number of bits needed to represent that many colors
'The plane rows are interlaced with each other in a strange format
'The second rowplane comes immediately after the first, but the third comes
'16 bytes after the first. Then the fourth comes immediately after the third,
'and the fifth comes 16 after the third (32 after the first) and so on...

'How the planes of each row are separated:
'byte 0  = plane 0 (columns 0 - 7)
'byte 1  = plane 1
'byte 2  = plane 0
'byte 3  = plane 1
'...
'byte 16 = plane 2
'byte 17 = plane 3
'byte 32 = plane 4
'byte 33 = plane 5
'byte 48 = plane 6
'byte 49 = plane 7
'The tile usually only uses the first four planes (sixteen colors)

'So the the order would go like this for a normal four-bit (16 color) tile:
'(row 0) 0,1,16,17 (1) 2,3,18,19   (2) 4,5,20,21   (3) 6,7,22,23
'(row 4) 8,9,24,25 (5) 10,11,26,27 (6) 12,13,28,29 (7) 14,15,30,31

DefineArrays:
 lastPlane = bitplanes - 1
 nexttile = 8 * bitplanes
 tilessquare = tileswide * tilesheigh
 lastcol = tileswide * 8: lastrow = tilesheigh * 8
 nextrow = tileswide * bitplanes * 8 + rowalignment
 nextpage& = tilesheigh * CLNG(nextrow)
 LOCATE 2, 20: PRINT "Tile size:"; nexttile;
 LOCATE 3, 20: PRINT "Page size:"; nextpage&;
 LOCATE 4, 20: PRINT "Window size:"; tilesheigh; tileswide;
RETURN

SetPalette:
 OUT &H3C8, 0
 colors = 2 ^ bitplanes
 IF CurPalette + paletteloaded = 0 THEN CurPalette = 3
 SELECT CASE CurPalette
 CASE 0
  DEF SEG = VARSEG(userpalette(0))
  BytePos = VARPTR(userpalette(0))
  FOR CurColor = BytePos TO 767 + BytePos STEP 3'colors * 3 - 1 + bytepos
   OUT &H3C9, PEEK(CurColor) \ 4
   OUT &H3C9, PEEK(CurColor + 1) \ 4
   OUT &H3C9, PEEK(CurColor + 2) \ 4
  NEXT CurColor
 CASE 1 'Grey palette
  colorfactor! = 64 / colors
  FOR CurColor = 0 TO colors - 1
   RGB = INT(CurColor * colorfactor!)
   OUT &H3C9, RGB
   OUT &H3C9, RGB
   OUT &H3C9, RGB
  NEXT CurColor
 CASE 2 'Inverse grey palette
  colorfactor! = 64 / colors
  FOR CurColor = 0 TO colors - 1
   RGB = 63 - INT(CurColor * colorfactor!)
   OUT &H3C9, RGB
   OUT &H3C9, RGB
   OUT &H3C9, RGB
  NEXT CurColor
 CASE 3: PALETTE 'Default palette
 CASE 4
  DEF SEG = VARSEG(userpalette(0))
  BytePos = VARPTR(userpalette(0))
  Rcolor = 0: Gcolor = 0: Bcolor = 0
  FOR CurColor = 0 TO 255
   POKE BytePos, Rcolor * 51
   POKE BytePos + 1, Gcolor * 51
   POKE BytePos + 2, Bcolor * 51
   Rcolor = Rcolor + 1: IF Rcolor > 5 THEN Rcolor = 0: Gcolor = Gcolor + 1: IF Gcolor > 5 THEN Gcolor = 0: Bcolor = Bcolor + 1
   BytePos = BytePos + 3
  NEXT CurColor
  CurPalette = 0
  paletteloaded = 1
  GOTO SetPalette
 CASE 5
  OUT &H3C9, 45 'Set background to light gray
  OUT &H3C9, 45
  OUT &H3C9, 45
  Rcolor = 63: RedInc = -1
  Gcolor = 0: GreenInc = 1
  Bcolor = 0: BlueInc = 0
  FOR CurColor = 1 TO 255
   OUT &H3C9, Rcolor: Rcolor = Rcolor + RedInc
   OUT &H3C9, Gcolor: Gcolor = Gcolor + GreenInc
   OUT &H3C9, Bcolor: Bcolor = Bcolor + BlueInc
   IF Rcolor < 0 THEN RedInc = 0: Rcolor = 0: BlueInc = 1 ELSE IF Rcolor > 63 THEN RedInc = -1: Rcolor = 63
   IF Gcolor > 63 THEN GreenInc = -1: Gcolor = 63 ELSE IF Gcolor < 0 THEN GreenInc = 0: Gcolor = 0: RedInc = 1
   IF Bcolor > 63 THEN BlueInc = -1: Bcolor = 63 ELSE IF Bcolor < 0 THEN BlueInc = 0: Bcolor = 0: GreenInc = 1
  NEXT CurColor
 CASE 6
  OUT &H3C9, 45 'Set background to light gray
  OUT &H3C9, 45
  OUT &H3C9, 45
  FOR CurColor = 1 TO 255
    RGB# = CurColor * .0245436953125#
    Redvalue = SIN(RGB#) * 31 + 32
    GreenValue = SIN(RGB# + 2.09439519620768#) * 31 + 32
    BlueValue = SIN(RGB# + 4.188790639241536#) * 31 + 32
    OUT &H3C9, Redvalue
    OUT &H3C9, GreenValue
    OUT &H3C9, BlueValue
  NEXT CurColor
 END SELECT
RETURN

ResizeViewingWindow:
 IF newtileswide < tileswide THEN
  LINE (lastcol, 0)-(newtileswide * 8, lastrow), 0, BF
 END IF
 tileswide = newtileswide
 FilePos& = FileBase&: x = 0: y = 0
 GOSUB DefineArrays
 tilesremain = tilessquare
RETURN

LoadInPalette:
 WIDTH 80, 25: COLOR 7, 0: CLS
 PRINT "Type in the filename of the picture or palette you want to grab a palette from"
 PRINT "It can be any one of these file types: GIF, BMP, PCX, PAL"
 DO
  GOSUB GetFileName
  IF file$ = "" GOTO ResetViewingScreen
  IF INSTR(".BMP.GIF.PCX.PAL", RIGHT$(file$, 4)) AND LEN(file$) > 4 THEN
   GOSUB OpenBinaryFile
  ELSE
   PRINT "Unsupported picture format, please stick to one of the more common ones": FilErr = -1
  END IF
 LOOP WHILE FilErr

 IF RIGHT$(file$, 4) = ".BMP" THEN
  FilePalette$ = SPACE$(1024)
  GET NewFileNum, 55, FilePalette$ 'standard windows bmpinfosize = 40 + 15
  DEF SEG = VARSEG(userpalette(0))
  Index = VARPTR(userpalette(0))
  FOR BytePos = 1 TO 1024 STEP 4
   POKE Index, ASC(MID$(FilePalette$, BytePos, 1))'\4
   POKE Index + 1, ASC(MID$(FilePalette$, BytePos + 1, 1))'\4
   POKE Index + 2, ASC(MID$(FilePalette$, BytePos + 2, 1))'\4
   Index = Index + 3
  NEXT BytePos
 ELSEIF RIGHT$(file$, 4) = ".PAL" THEN
  IF LOF(NewFileNum) < 768 THEN FilePalette$ = SPACE$(LOF(NewFileNum)) ELSE FilePalette$ = SPACE$(768)
  GET NewFileNum, 1, FilePalette$
  Index = 0
  FOR BytePos = 1 TO LEN(FilePalette$) STEP 2
   userpalette(Index) = CVI(MID$(FilePalette$, BytePos, 2))
   Index = Index + 1
  NEXT BytePos
 ELSE
  FilePalette$ = SPACE$(768)
  IF RIGHT$(file$, 4) = ".PCX" THEN 'standard 256-color pcx palette
   GET NewFileNum, LOF(NewFileNum) - 767, FilePalette$
  ELSE 'standard 256-color gif palette
   GET NewFileNum, 13, FilePalette$
  END IF
  DEF SEG = VARSEG(userpalette(0))
  Index = VARPTR(userpalette(0))
  FOR BytePos = 1 TO 768 STEP 3
   POKE Index, ASC(MID$(FilePalette$, BytePos, 1))'\4
   POKE Index + 1, ASC(MID$(FilePalette$, BytePos + 1, 1))'\4
   POKE Index + 2, ASC(MID$(FilePalette$, BytePos + 2, 1))'\4
   Index = Index + 3
  NEXT BytePos
 END IF
 CLOSE NewFileNum

 PRINT "Colors loaded into user palette from "; file$; LEN(FilePalette$) \ 3
 FilePalette$ = ""
 paletteloaded = 1
 DO: LOOP UNTIL LEN(INKEY$)
 CurPalette = 0'Set to the current palette to the one just loaded in
GOTO ResetViewingScreen

SavePalette:
 WIDTH 80, 25: COLOR 7, 0: CLS
 PRINT "Type in the filename to save this palette as, or nothing to cancel"
 DO
  GOSUB GetFileName
  GOSUB QuestionFileOverwrite
 LOOP WHILE FilErr
 OPEN file$ FOR OUTPUT AS NewFileNum
 FOR a = 0 TO 383 '+-(768 \ 2) RGB values
  PRINT #NewFileNum, MKI$(userpalette(a));
 NEXT a
 CLOSE NewFileNum
GOTO ResetViewingScreen

TransposePaletteBlock: 'shift next sixteen colors into first block
 FOR BytePos = 0 TO 23
  colors = userpalette(BytePos)
  FOR a = BytePos TO 336 + BytePos STEP 24
   userpalette(a) = userpalette(a + 24)
  NEXT a
  userpalette(360 + BytePos) = colors
 NEXT BytePos
 IF CurPalette = 0 THEN GOSUB SetPalette
RETURN

EditPaletteColors:
 CLS
 'DrawColorBlocks
 colors = 0
 FOR rowcount = 0 TO 180 STEP 12
  FOR a = 0 TO 240 STEP 16
   LINE (a, rowcount)-(a + 15, rowcount + 11), colors, BF
   colors = colors + 1
  NEXT a
 NEXT rowcount
 IF CurPalette <> 0 OR paletteloaded = 0 THEN
  LOCATE 25, 1
  PRINT "Only the user palette can be edited..."; TAB(40);
  DO: LOOP UNTIL LEN(INKEY$)
  GOTO ReturnFromPaletteEditor
  'IF INPUT$(1) = CHR$(13) GOTO LoadInPalette ELSE RETURN
 END IF
 colors = 0
 CursorLocked = 0
 RedrawCell = 1
 DO
  SELECT CASE INKEY$
  CASE CHR$(0) + "H": OldCursorIndex = CursorColorIndex: CursorColorIndex = CursorColorIndex - 16 AND 255
  CASE CHR$(0) + "P": OldCursorIndex = CursorColorIndex: CursorColorIndex = CursorColorIndex + 16 AND 255
  CASE CHR$(0) + "K": OldCursorIndex = CursorColorIndex: CursorColorIndex = CursorColorIndex - 1 AND 255
  CASE CHR$(0) + "M": OldCursorIndex = CursorColorIndex: CursorColorIndex = CursorColorIndex + 1 AND 255
  CASE "": CursorLocked = 0: RedrawCell = 1
  CASE " ": RedrawCell = 1: IF CursorLocked THEN OverWriteColor = 0: GOSUB MoveColors: CursorLocked = 0 ELSE CursorLocked = 1: LockedColorIndex = CursorColorIndex
  CASE CHR$(0) + "R": RedrawCell = 1: IF CursorLocked THEN OverWriteColor = 1: GOSUB MoveColors: CursorLocked = 0 ELSE CursorLocked = 1: LockedColorIndex = CursorColorIndex
  CASE CHR$(13), CHR$(27): EXIT DO
  END SELECT
  IF OldCursorIndex <> CursorColorIndex OR RedrawCell THEN
   rowcount = (OldCursorIndex \ 16) * 12
   a = (OldCursorIndex AND 15) * 16
   LINE (a, rowcount)-(a + 15, rowcount + 11), OldCursorIndex, BF
   OldCursorIndex = CursorColorIndex
   RedrawCell = 0
   DEF SEG = VARSEG(userpalette(0))
   rowcount = VARPTR(userpalette(0)) + (CursorColorIndex * 3)
   LOCATE 25, 1: PRINT PEEK(rowcount); PEEK(rowcount + 1); PEEK(rowcount + 2); TAB(20);
  END IF
  IF TIMER <> lasttime% THEN
   rowcount = (CursorColorIndex \ 16) * 12
   a = (CursorColorIndex AND 15) * 16
   IF CursorLocked THEN
    LINE (a + 4, rowcount + 4)-(a + 11, rowcount + 7), LockedColorIndex, BF
    LINE (a + 3, rowcount + 3)-(a + 12, rowcount + 8), colors, B
   ELSE
    LINE (a, rowcount)-(a + 15, rowcount + 11), colors, B
   END IF
   colors = colors + 1 AND 255
   'LOCATE 25, 1: PRINT CursorLocked; colors;
  END IF
 LOOP
ReturnFromPaletteEditor:
 CLS
 tilesremain = tilessquare
RETURN

SetSingleColor:
 DEF SEG = VARSEG(userpalette(0))
 BytePos = VARPTR(userpalette(0)) + (CursorColorIndex * 3)
 IF Rcolor > 63 THEN Rcolor = 63 ELSE IF Rcolor < 0 THEN Rcolor = 0
 IF Gcolor > 63 THEN Gcolor = 63 ELSE IF Gcolor < 0 THEN Gcolor = 0
 IF Bcolor > 63 THEN Bcolor = 63 ELSE IF Bcolor < 0 THEN Bcolor = 0
 OUT &H3C8, CursorColorIndex
 POKE BytePos, Rcolor * 4: OUT &H3C9, Rcolor
 POKE BytePos, Rcolor * 4: OUT &H3C9, PEEK(a + 1) \ 4
 POKE BytePos, Rcolor * 4: OUT &H3C9, PEEK(a + 2) \ 4
RETURN

MoveColors:
 DEF SEG = VARSEG(userpalette(0))
 BytePos = VARPTR(userpalette(0)) + (LockedColorIndex * 3)
 rowcount = VARPTR(userpalette(0)) + (CursorColorIndex * 3)
 'LOCATE 25, 1: PRINT LockedColorIndex; CursorColorIndex; bytepos; VARPTR(userpalette(0)) + (CursorColorIndex * 3); rowcount;
 IF OverWriteColor THEN
  POKE rowcount, PEEK(BytePos)
  POKE rowcount + 1, PEEK(BytePos + 1)
  POKE rowcount + 2, PEEK(BytePos + 2)
 ELSE
  a = PEEK(BytePos): POKE BytePos, PEEK(rowcount): POKE rowcount, a
  a = PEEK(BytePos + 1): POKE BytePos + 1, PEEK(rowcount + 1): POKE rowcount + 1, a
  a = PEEK(BytePos + 2): POKE BytePos + 2, PEEK(rowcount + 2): POKE rowcount + 2, a
 END IF
 GOSUB SetPalette
RETURN

SaveToPcx:
 WIDTH 80, 25: COLOR 7, 0: CLS
 IF ROMfileNum < 1 THEN
  PRINT "Save an empty picture?? Y/N"
  SLEEP: IF UCASE$(INKEY$) <> "Y" GOTO ResetViewingScreen
 END IF
 PRINT "Type in the pcx filename to save the screen window to, or nothing to cancel"
 DO
  GOSUB GetFileName
  GOSUB QuestionFileOverwrite
 LOOP WHILE FilErr

 SCREEN 13

 rowbytes = tileswide * 8
 REDIM imageBuffer(0 TO 8191) AS DOUBLE
 DEF SEG = VARSEG(imageBuffer(0))
 Index& = VARPTR(imageBuffer(0))

 IF ROMfileNum < 1 GOTO StartCompressing
 LOCATE 1, 1: PRINT "Loading and translating tiles"
 FilePos& = FileBase&: tiles = 0
 IF allplanes THEN filterplane = curplane ELSE filterplane = -1
 IF allplanes AND 1 THEN inverseplanes = -1 ELSE inverseplanes = 0
 FOR row = 0 TO 23
  FOR col = 1 TO 16'tileswide
   'Reset plane pointers
   planeStepOfset = planepattern(bitplanes)
   FOR plane = 0 TO lastPlane
    planePointer(plane) = planeBase(plane)
    planeStep(plane) = planeInc(plane + planeStepOfset)
   NEXT plane
   GET ROMfileNum, FilePos&, tile$
   FOR rowcount = 0 TO 7
    p1 = 0: p2 = 0: p3 = 0: p4 = 0: p5 = 0: p6 = 0: p7 = 0: p8 = 0
    bitshift = 1
    FOR plane = 0 TO lastPlane
     IF plane <> filterplane XOR inverseplanes THEN
      a = ASC(MID$(tile$, planePointer(plane) + 1, 1))
      IF a AND 128 THEN p1 = p1 + bitshift
      IF a AND 64 THEN p2 = p2 + bitshift
      IF a AND 32 THEN p3 = p3 + bitshift
      IF a AND 16 THEN p4 = p4 + bitshift
      IF a AND 8 THEN p5 = p5 + bitshift
      IF a AND 4 THEN p6 = p6 + bitshift
      IF a AND 2 THEN p7 = p7 + bitshift
      IF a AND 1 THEN p8 = p8 + bitshift
     END IF
     planePointer(plane) = planePointer(plane) + planeStep(plane)
     bitshift = bitshift * 2
    NEXT plane

    yrow = y + rowcount
    POKE Index&, p1
    POKE Index& + 1, p2
    POKE Index& + 2, p3
    POKE Index& + 3, p4
    POKE Index& + 4, p5
    POKE Index& + 5, p6
    POKE Index& + 6, p7
    POKE Index& + 7, p8
    Index& = Index& + rowbytes
   NEXT rowcount
   Index& = Index& - rowbytes * 8 + 8
   FilePos& = FilePos& + nexttile
  NEXT col
  Index& = Index& + rowbytes * 7
  tiles = tiles + 100
  LOCATE 2, 1: PRINT "%"; LTRIM$(STR$(tiles \ 24));
 NEXT row

StartCompressing:
 PRINT
 PRINT "Compressing and saving to "; file$
 OPEN file$ FOR OUTPUT AS NewFileNum
 PRINT #NewFileNum, CHR$(10); CHR$(5); CHR$(1); CHR$(8); MKL$(0); MKI$(rowbytes - 1); MKI$(191); MKI$(320); MKI$(200); STRING$(49, 0); CHR$(1); MKI$(rowbytes); MKI$(0); STRING$(58, 0);
 'PRINT "BM"; STRING$(6, 0); MKL$(822); MKL$(40); MKL$(rowbytes); MKL$(192); MKI$(1); MKI$(8); MKL$(0);

 Index& = VARPTR(imageBuffer(0))
 totalbytes& = rowbytes * 192
 WHILE Index& < totalbytes&
  rowlong& = Index& + rowbytes
  rowrle = 0
  lastchar = PEEK(Index&)
  rlecount = 1
  DO
continuecompression:
   Index& = Index& + 1
   IF Index& < rowlong& THEN
     char = PEEK(Index&)
     IF char = lastchar THEN
       IF rlecount < 63 THEN
         rlecount = rlecount + 1
         GOTO continuecompression
       END IF
     END IF
   END IF
   IF lastchar > 192 THEN
     PRINT #NewFileNum, CHR$(192 + rlecount); CHR$(lastchar);
     'PRINT 192 + rlecount; lastchar;
   ELSE
     IF rlecount > 2 THEN PRINT #NewFileNum, CHR$(192 + rlecount); CHR$(lastchar);  ELSE PRINT #NewFileNum, STRING$(rlecount, lastchar);
     'IF rlecount > 2 THEN PRINT "#"; LTRIM$(STR$(rlecount)); lastchar;  ELSE PRINT lastchar; : IF rlecount > 1 THEN PRINT lastchar;
   END IF
   rowrle = rowrle + rlecount
   rlecount = 1
   IF char <> lastchar THEN lastchar = char
  LOOP WHILE Index& < rowlong&
  'PRINT "ÛÛ<"; rowrle; ">";
 WEND

 PRINT "Writing 256 color palette"
 DEF SEG = VARSEG(userpalette(0))
 Index = VARPTR(userpalette(0))
 PRINT #NewFileNum, CHR$(12);
 FOR BytePos = 1 TO 768 STEP 3
  PRINT #NewFileNum, CHR$(PEEK(Index));
  PRINT #NewFileNum, CHR$(PEEK(Index + 1));
  PRINT #NewFileNum, CHR$(PEEK(Index + 2));
  Index = Index + 3
 NEXT BytePos

 PRINT "Done..."

 CLOSE NewFileNum
 ERASE imageBuffer
 FilePos& = FileBase&

 SLEEP 2: WHILE INKEY$ > "": WEND
GOTO ResetViewingScreen

ResetViewingScreen:
 SCREEN 13
 GOSUB SetPalette
 tilesremain = tilessquare
RETURN

GetFileName:
 ON ERROR GOTO FilErrHan
 LINE INPUT "FileName: ", file$: file$ = UCASE$(LTRIM$(file$))
 IF file$ = "" THEN ON ERROR GOTO 0: RETURN
 IF INSTR(file$, "*") THEN SHELL "dir " + file$: GOTO GetFileName
 ON ERROR GOTO FilErrHan
 FilErr = 0
 CHDIR file$
 IF FilErr = 0 THEN PRINT "Directory changed": GOTO GetFileName
 ON ERROR GOTO 0
RETURN

OpenBinaryFile:
 ON ERROR GOTO FilErrHan
 FilErr = 0
 NewFileNum = FREEFILE
 OPEN file$ FOR INPUT AS NewFileNum: CLOSE NewFileNum
 ON ERROR GOTO 0
 IF FilErr = 53 THEN PRINT "Could not find that file": RETURN ELSE IF FilErr THEN PRINT "Could not open that file": RETURN
 OPEN file$ FOR BINARY AS NewFileNum
RETURN

QuestionFileOverwrite:
 IF file$ = "" THEN RETURN ResetViewingScreen
 ON ERROR GOTO FilErrHan: FilErr = 0
 NewFileNum = FREEFILE: OPEN file$ FOR INPUT AS NewFileNum
 CLOSE NewFileNum: ON ERROR GOTO 0
 IF FilErr = 0 THEN
  PRINT "Do you want to overwrite the existing one? Y/N"
  SLEEP: IF UCASE$(INKEY$) <> "Y" THEN FilErr = 1
 ELSEIF FilErr = 53 THEN FilErr = 0
 ELSE PRINT "Could not save to that file"
 END IF
RETURN

FilErrHan:
FilErr = ERR
RESUME NEXT

EndProgram:
CLOSE
WIDTH 80, 25
SCREEN 0
END

ShowHelp:
 WIDTH 80, 25: SCREEN 0: VIEW PRINT 1 TO 25
 PRINT "For scrolling:"
 PRINT "         You probably have a good idea of what these do"
 PRINT "  PgUp PgDn  These aren't too hard to guess either"
 PRINT "  + -        Move up or down a byte, like any other tile viewer"
 PRINT "  G          Goto to byte position, just type in the byte number and press Enter"
 PRINT "The other usual features:"
 PRINT "  F1    Show this cheap help"
 PRINT "  F2-F7 Setting a generic palette, F2=User palette, F3=Gray, F4=Inverse gray"
 PRINT "        F5=Default video colors, F6=Rainbow color, F7=Another useless one"
 PRINT "  1-8   Set the bit mode to that number, actually only modes 1,2,3,4,7,8 exist"
 PRINT "  * /   Change tile wrap width, not that useful most of the time since it is"
 PRINT "        already set to the most common (16), but sometimes it really helps"
 PRINT "  L     Load a palette in from an image file (PCX GIF BMP) or a presaved PAL"
 PRINT "  W P   Save snapshot of window or save current palette to PAL file"
 PRINT "  C     View current palette \ Edit the user palette by moving colors around"
 PRINT "Plane splicing, dicing, and filtering"
 PRINT "  A  All bitplanes turned on, how many there are depends on the bitmode"
 PRINT "  S  Single bitplane, show only the current one and turn all others off"
 PRINT "  E  Except a bitplane, all are on but the current one"
 PRINT "  B  Set current bitplane, then just press the number of the plane"
 PRINT "     this only applies when you use single or exclude mode"
 PRINT
 PRINT "When you're done using it, press Esc to quit"
 PRINT "Programmed by Dwayne, starting on 2-98"
 PRINT "Thanks to Vilewrath for the example in Qbasic";
 WHILE INKEY$ = "": WEND
GOTO ResetViewingScreen

'-------+--------+--- General Picture information starts here---------
'  0    |   2    | (BM) - Tells us that the picture is in bmp format
'  2    |   4    | Size of the file (without header?)
'  6    |   2    | (0) Reserved1 - Must be zero
'  8    |   2    | (0) Reserved2 - Must be zero
'  10   |   4    | Number of bytes offset of the picture data
'-------+--------+--- Information Header starts here -----------------
'  14   |   4    | (40/12) Size of information header (Win3.1/OS2)
'  18   |   4    | Picture width in pixels
'  22   |   4    | Picture height in pixels
'  26   |   2    | (1) Number of planes, must be 1
'  28   |   2    | Number of bits per pixel (bpp), must be 1,4,8 or 24
'  30   |   4    | (0) Compression - 0 means no compression, 1,2 are RLEs
'  34   |   4    | Image size in bytes
'  38   |   4    | picture width in pels per metre
'  42   |   4    | picture height in pels per metre
'  46   |   4    | (0) Number of colours used in the picture, 0 means all
'  50   |   4    | (0) Number of important colours, 0 means all
'-------+--------+--- Palette data starts here -----------------------
'  54   |   1    | (b) - blue intensity component, color 0 - range 0 to 255
'  55   |   1    | (g) - green intensity component, color 0 - range 0 to 255
'  56   |   1    | (r) - red intensity component, color 0 - range 0 to 255
'  57   |   1    | (0) - unused
'  58   |   1    | (b) - blue intensity component, color 0 - range 0 to 255
'  ...  | ...    |
'  54   | 4*2^bpp| total range of palette
'-------+--------+--- Image data starts here -------------------------
'54+    | width* | Bitmap data starting at lower left portion of the
'(4*2^n)| height*| image moving from left towards right. Moving up 1
'       | (8/bpp)| pixel when at the right hand side of the image, starting
'       |        | from the left side again, until the top right of the
'       |        | image is reached

'Note that this format is slightly different for a OS/2 Bitmap.
'The header is the same up to (but not including) bit 30-
'The palette colour values follow at bit 30, with the form...
'1 byte blue intensity
'1 byte green intensity
'1 byte red intensity
'For each colour of the picture.
'Bitmapped image data follows the colour tables

'8 bit pictures use 1 byte per pixel. Each byte of image data
'represents one of 256 colours.

'24 bit pictures express colour values by using 3 bytes and each has a
'value between 0 and 255. The first byte is for red, the second is for
'green and the third is for blue. Thus (256)^3 or 2^24 of 16777216 different
'colours.

'ELSEIF nbits = 4 THEN
'   y = picheight - 1
'   x = 0
'   dat$ = " "
'   WHILE y >= 0
'      WHILE x < picwidth
'        GET 1, , dat$
'        LOCATE 1, 1
'        p1 = ASC(dat$) AND 15
'        p2 = ASC(dat$) AND 240 / 16
'        PSET (x, y), p1
'        PSET (x + 1, y), p2
'        x = x + 2
'      WEND
'      y = y - 1
'      x = 0
'   WEND
'END IF

'10  Manufacturer - some type of standard pcx format, do not know who
'5   Version - means it is a 256 color pcx, standard for PaintBrush 3.0+
'1   Encoding - this type of rle (0-191 are colors, 192-255 are run prefixes)
'0   Bits per pixel - always 8 (were in screen mode 13)
'0   Top - not used
'0   Left - just as irrelevant
'128 Width - usually the right width, unless you change the tile wrap
'192 Height - always 192
'320 Horizontal resolution - same reoultion as the screen mode we're using
'200 Vertical resolution
'58  Ega palette - old palette not used any more, fill in with blank space
'59  Reserved blank - ? who knows...
'1   Color planes number - simple linear bitmap, no stupid plane interleaving
'128 Bytes per line - width * bitsperpixel \ 8 (in other words, the width)
'0   Palette type - don't know what it means, just set it to zero and it works
'0   Blank extra padding - no real purpose, just makes the header an even 128

DIM SHARED PcxHeader$(0 TO 15), PcxHeaderLen(0 TO 15)
FOR count = 0 TO 15
 READ PcxHeader$(count), PcxHeaderLen(count)
NEXT count
DATA "Manufacturer",1,"Version",1,"Encoding",1,"Bits per pixel",1,"Top",2
DATA "Left",2,"Width",2,"Height",2,"Horizontal resolution",2
DATA "Vertical resolution",2,"Ega palette",48,"Reserved blank",1,"Color planes number",1
DATA "Bytes per line",2,"Palette type",2,"Blank extra padding",58

GET 1, 9, PcxWidth
GET 1, 11, PcxHeight
PcxWidth = PcxWidth + 1
PcxHeight = PcxHeight + 1

SEEK 1, 1
header$ = INPUT$(128, 1)
byte = 1
FOR count = 0 TO 15
 LOCATE count + 5, 25
 SELECT CASE PcxHeaderLen(count)
 CASE 1: PRINT ASC(MID$(header$, byte, 1));
 CASE 2: PRINT CVI(MID$(header$, byte, 2));
 CASE ELSE: PRINT " ÄÄ";
 END SELECT
 byte = byte + PcxHeaderLen(count)
NEXT count

