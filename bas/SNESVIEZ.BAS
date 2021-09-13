' any color plane version
' zelda 524801,553233:3!,571665:3?,577050:?
' smw 286113feather:l,286249flower:u,286572flower:l

' This sprite reader was programmed in QuickBasic so that
' almost any programmer should be able to understand how
' SNES sprites are encoded. Yes its sloppy, yes its slow
' but it also took me two minutes to write. And it gives
' you something to work on. :-)
DEFINT A-Z

nextplane(0) = 0:  nextplane(1) = 1
nextplane(2) = 16: nextplane(3) = 17
nextplane(4) = 32: nextplane(5) = 33
nextplane(6) = 48: nextplane(7) = 49
tileswide = 16: tilesheigh = 24
curpalette = 0: allplanes = 1

COLOR 7, 0
CLS
PRINT "Quick-piece-of-junk SNES Sprite Reader (any color) v0.01"
PRINT "Programmed by VileWrath 1997 in two minutes."
PRINT "Edited and beefed-up by Dwayne"
PRINT
INPUT "FileName: ", f$
IF f$ = "" THEN f$ = "\dw\net\roms\zelda.sfc"
: : CHDIR "\dw\net\roms"
OPEN f$ FOR INPUT AS #1: CLOSE #1
'If the program stopped here, it means a file error
INPUT "Bitplanes:", bitplanes
IF bitplanes = 0 THEN bitplanes = 4
GOSUB DefineArrays
SCREEN 13
OPEN f$ FOR BINARY AS #1
filelen& = LOF(1)
'FOR a = 1 TO 14
'PALETTE a - 1, (a * 4) - 4
'NEXT a
tile$ = SPACE$(64) '8x8x4bits = 256bits \ 8 = 32 bytes
x = 0: y = 0
filebase& = 1
filepos& = filebase&
GOTO NewCode
DO WHILE NOT EOF(1)

 'Read in a whole tile, exact number of bytes depends on number of colors
 GET 1, filepos&, tile$
 bytepos = 1
 FOR rowcount = 0 TO 7
  c1 = 0: c2 = 0: c3 = 0: c4 = 0: c5 = 0: c6 = 0: c7 = 0: c8 = 0

  bitshift = 1
  FOR plane = 0 TO lastplane
   a = ASC(MID$(tile$, bytepos + nextplane(plane), 1))
   IF a AND 128 THEN c1 = c1 + bitshift
   IF a AND 64 THEN c2 = c2 + bitshift
   IF a AND 32 THEN c3 = c3 + bitshift
   IF a AND 16 THEN c4 = c4 + bitshift
   IF a AND 8 THEN c5 = c5 + bitshift
   IF a AND 4 THEN c6 = c6 + bitshift
   IF a AND 2 THEN c7 = c7 + bitshift
   IF a AND 1 THEN c8 = c8 + bitshift
   bitshift = bitshift * 2
  NEXT plane
 
  yrow = y + rowcount
  PSET (x, yrow), c1
  PSET (x + 1, yrow), c2
  PSET (x + 2, yrow), c3
  PSET (x + 3, yrow), c4
  PSET (x + 4, yrow), c5
  PSET (x + 5, yrow), c6
  PSET (x + 6, yrow), c7
  PSET (x + 7, yrow), c8
  filepos& = filepos& + 2
  bytepos = bytepos + 2
 NEXT rowcount
 filepos& = filepos& + nexttilerow

 x = x + 8
 IF x >= lastcol THEN y = y + 8: x = 0
 IF y >= lastrow THEN
   DO: key$ = INKEY$: LOOP UNTIL LEN(key$)
   SELECT CASE key$
   CASE "2": bitplanes = 2: GOSUB DefineArrays
   CASE "4": bitplanes = 4: GOSUB DefineArrays
   CASE CHR$(0) + "P": filebase& = filepos&: GOTO JumpNextPage
   CASE CHR$(27): EXIT DO
   END SELECT
   filepos& = filebase&
JumpNextPage:
   WHILE INKEY$ > "": WEND
   LOCATE 25, 1: PRINT "File pos:"; filepos&;
   y = 0
 END IF

LOOP

EndProgram:
CLOSE
END

DefineArrays:
'DIM nextplane(0 TO 7)
lastplane = bitplanes - 1
nexttile = 8 * bitplanes
nexttilerow = 8 * bitplanes
tilessquare = tileswide * tilesheigh
lastcol = tileswide * 8: lastrow = tilesheigh * 8
nextrow = tileswide * bitplanes * 8
nextpage& = tilesheigh * nextrow
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
 'byte 16 = plane 2
 'byte 17 = plane 3
 'byte 32 = plane 4
 '... out to a max of eight planes

 'So the the order would go like this for a normal four-bit (16 color) tile:
 '(row 0) 0,1,16,17 (1) 2,3,18,19   (2) 4,5,20,21   (3) 6,7,22,23
 '(row 4) 8,9,24,25 (5) 10,11,26,27 (6) 12,13,28,29 (7) 14,15,30,31

NewCode:
tilesremain = tilessquare
updatestatus = 1
DO
 key$ = INKEY$
 IF LEN(key$) THEN GOSUB DecideKeyIput
 IF tilesremain THEN
  GOSUB DrawTile
  x = x + 8: IF x >= lastcol THEN y = y + 8: x = 0
  IF y >= lastrow THEN y = 0: filepos& = filebase&
  tilesremain = tilesremain - 1
  IF tilesremain = 0 THEN x = 0: y = 0: filepos& = filebase&
 END IF
 IF updatestatus THEN updatestatus = 0: LOCATE 25, 1: PRINT "Filepos:"; filebase&; "Bits:"; bitplanes;
LOOP

DecideKeyIput:
 SELECT CASE UCASE$(key$)
 CASE CHR$(27): END
 CASE CHR$(0) + "P": IF filebase& + nextrow < filelen& THEN filebase& = filebase& + nextrow: filepos& = filepos& + nextrow: tilesremain = tilessquare
 CASE CHR$(0) + "H": IF filebase& - nextrow > 0 THEN filebase& = filebase& - nextrow: filepos& = filepos& - nextrow: tilesremain = tilessquare
 CASE CHR$(0) + "M": IF filebase& + nexttile < filelen& THEN filebase& = filebase& + nexttile: filepos& = filepos& + nexttile: tilesremain = tilessquare
 CASE CHR$(0) + "K": IF filebase& - nexttile > 0 THEN filebase& = filebase& - nexttile: filepos& = filepos& - nexttile: tilesremain = tilessquare
 CASE CHR$(0) + "Q": IF filebase& + nextpage& < filelen& THEN filebase& = filebase& + nextpage&: filepos& = filepos& + nextpage&: tilesremain = tilessquare
 CASE CHR$(0) + "I": IF filebase& - nextpage& > 0 THEN filebase& = filebase& - nextpage&: filepos& = filepos& - nextpage&: tilesremain = tilessquare
 CASE "+": IF filebase& < filelen& THEN filebase& = filebase& + 1: filepos& = filepos& + 1: tilesremain = tilessquare
 CASE "-": IF filebase& > 1 THEN filebase& = filebase& - 1: filepos& = filepos& - 1: tilesremain = tilessquare
 CASE "G": LOCATE 1, 20: INPUT "Goto:", newbase&
  IF newbase& > 0 AND newbase& < filelen& THEN filebase& = newbase&: filepos& = filebase&: tilesremain = tilessquare
 CASE "S": IF allplanes THEN allplanes = 0 ELSE allplanes = 1
  tilesremain = tilessquare
 CASE "D": DO: key$ = INKEY$: LOOP UNTIL LEN(key$): desplane = VAL(key$): tilesremain = tilessquare
 CASE "1", "2", "3", "4", "8": bitplanes = VAL(key$): GOSUB DefineArrays: filepos& = filebase&: x = 0: y = 0: tilesremain = tilessquare
 CASE CHR$(0) + ";": curpalette = 0: GOSUB SetPalette
 CASE CHR$(0) + "<": curpalette = 1: GOSUB SetPalette
 CASE CHR$(0) + "=": curpalette = 2: GOSUB SetPalette
 CASE "*": IF tileswide < 32 THEN newtileswide = tileswide + 1: GOSUB ResizeViewingWindow: GOSUB DefineArrays
 CASE "/": IF tileswide > 0 THEN newtileswide = tileswide - 1: GOSUB ResizeViewingWindow: GOSUB DefineArrays
 END SELECT
 updatestatus = 1
RETURN

DrawTile:
 'Read in a whole tile, exact number of bytes depends on number of colors
 GET 1, filepos&, tile$
 bytepos = 1
 bytepos2 = 17
 FOR rowcount = 0 TO 7
  c1 = 0: c2 = 0: c3 = 0: c4 = 0: c5 = 0: c6 = 0: c7 = 0: c8 = 0

  bitshift = 1
  FOR plane = 0 TO 1
   a = ASC(MID$(tile$, bytepos + nextplane(plane), 1))
   IF a AND 128 THEN c1 = c1 + bitshift
   IF a AND 64 THEN c2 = c2 + bitshift
   IF a AND 32 THEN c3 = c3 + bitshift
   IF a AND 16 THEN c4 = c4 + bitshift
   IF a AND 8 THEN c5 = c5 + bitshift
   IF a AND 4 THEN c6 = c6 + bitshift
   IF a AND 2 THEN c7 = c7 + bitshift
   IF a AND 1 THEN c8 = c8 + bitshift
   bitshift = bitshift * 2
  NEXT plane
  a = ASC(MID$(tile$, bytepos2, 1))
  IF a AND 128 THEN c1 = c1 + 4
  IF a AND 64 THEN c2 = c2 + 4
  IF a AND 32 THEN c3 = c3 + 4
  IF a AND 16 THEN c4 = c4 + 4
  IF a AND 8 THEN c5 = c5 + 4
  IF a AND 4 THEN c6 = c6 + 4
  IF a AND 2 THEN c7 = c7 + 4
  IF a AND 1 THEN c8 = c8 + 4
 
  yrow = y + rowcount
  PSET (x, yrow), c1
  PSET (x + 1, yrow), c2
  PSET (x + 2, yrow), c3
  PSET (x + 3, yrow), c4
  PSET (x + 4, yrow), c5
  PSET (x + 5, yrow), c6
  PSET (x + 6, yrow), c7
  PSET (x + 7, yrow), c8
  bytepos = bytepos + 2
  bytepos2 = bytepos2 + 1
 NEXT rowcount
 filepos& = filepos& + nexttilerow
RETURN

SetPalette:
 SELECT CASE curpalette
 CASE 0: PALETTE 'Default palette
 CASE 1 'Grey palette
  OUT &H3C8, 0
  colors = 2 ^ bitplanes
  colorfactor! = 64 / colors
  LOCATE 2, 20: PRINT "Colors:"; colors;
  FOR a = 0 TO colors - 1
   rgb = INT(a * colorfactor!)
   OUT &H3C9, rgb
   OUT &H3C9, rgb
   OUT &H3C9, rgb
  NEXT a
 CASE ELSE 'Inverse grey palette
  OUT &H3C8, 0
  FOR a = 0 TO 15
   rgb = 60 - a * 4
   OUT &H3C9, rgb
   OUT &H3C9, rgb
   OUT &H3C9, rgb
  NEXT a
 END SELECT
RETURN

ResizeViewingWindow:
 IF newtileswide < tileswide THEN
  LINE (lastcol, 0)-(newtileswide * 8, lastrow), 0, BF
 END IF
 tileswide = newtileswide
 filepos& = filebase&: x = 0: y = 0: tilesremain = tilessquare
RETURN

