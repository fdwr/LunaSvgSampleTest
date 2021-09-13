' any color plane version
' LOZ 524801,560460,562832:3,562954:1,553233:3!,SMW 307851:3?,SM3231269?
' 295425items,459265font,688906??,885249samus,1188542?,1409537stuff,2006241?ball

' This sprite reader was programmed in QuickBasic so that
' almost any programmer should be able to understand how
' SNES sprites are encoded. Yes its sloppy, yes its slow
' but it also took me two minutes to write. And it gives
' you something to work on. :-)
DEFINT A-Z

DIM bitmodeTable(0 TO 23), bitmodeTablePtr(0 TO 8)
FOR a = 0 TO 23: READ b: bitmodeTable(a) = b: NEXT a
FOR a = 0 TO 8: READ b: bitmodeTablePtr(a) = b: NEXT a
tileswide = 16: tilesheigh = 24
curpalette = 0: allplanes = 1

COLOR 7, 0
CLS
PRINT "Quick-piece-of-junk SNES Sprite Reader (any color) v0.01"
PRINT "Programmed by VileWrath 1997 in two minutes."
PRINT "Edited and beefed-up by Dwayne"
PRINT
INPUT "FileName: ", f$
IF f$ = "" THEN f$ = "\dw\net\roms\mario.smc"
': : CHDIR "\dw\net\roms"
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
tile$ = SPACE$(512) '8x8x4bits = 256bits \ 8 = 32 bytes
x = 0: y = 0
filebase& = 289155
filepos& = filebase&
GOTO NewCode

EndProgram:
CLOSE
END

DefineArrays:

lastplane = bitplanes - 1
nexttile = 8 * bitplanes
tilessquare = 1'tileswide * tilesheigh
lastcol = tileswide * 8: lastrow = tilesheigh * 8
nextrow = tileswide * bitplanes * 8
nextpage& = tilesheigh * nextrow
ptrindex = bitmodeTablePtr(bitplanes)
LOCATE 2, 20: PRINT nexttile; nextpage&;
LOCATE 3, 20: PRINT tileheigh; tileswide;
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
  'filepos& = filebase&
  GOSUB DrawTile
  'x = x + 8: IF x >= lastcol THEN y = y + 8: x = 0
  'IF y >= lastrow THEN y = 0: filepos& = filebase&
  tilesremain = tilesremain - 1
  IF tilesremain = 0 THEN x = 0: y = 0: filepos& = filebase&
 END IF
 IF updatestatus THEN updatestatus = 0: LOCATE 25, 1: PRINT "Filepos:"; filebase&; "Bits:"; bitplanes;
LOOP

DecideKeyIput:
 SELECT CASE UCASE$(key$)
 CASE CHR$(27): END
 CASE CHR$(0) + "P": filebase& = filebase& + nextrow: filepos& = filepos& + nextrow: tilesremain = tilessquare
 CASE CHR$(0) + "H": IF filebase& - nextrow > 0 THEN filebase& = filebase& - nextrow: filepos& = filepos& - nextrow: tilesremain = tilessquare
 CASE CHR$(0) + "M": filebase& = filebase& + nexttile: filepos& = filepos& + nexttile: tilesremain = tilessquare
 CASE CHR$(0) + "K": IF filebase& - nexttile > 0 THEN filebase& = filebase& - nexttile: filepos& = filepos& - nexttile: tilesremain = tilessquare
 CASE CHR$(0) + "Q": filebase& = filebase& + nextpage&: filepos& = filepos& + nextpage&: tilesremain = tilessquare
 CASE CHR$(0) + "I": IF filebase& - nextpage& > 0 THEN filebase& = filebase& - nextpage&: filepos& = filepos& - nextpage&: tilesremain = tilessquare
 CASE "+": filebase& = filebase& + 1: filepos& = filepos& + 1: tilesremain = tilessquare
 CASE "-": IF filebase& > 0 THEN filebase& = filebase& - 1: filepos& = filepos& - 1: tilesremain = tilessquare
 CASE "G": LOCATE 1, 20: INPUT "Goto:", newbase&
  IF newbase& > 0 AND newbase& < filelen& THEN filebase& = newbase&: filepos& = filebase&: tilesremain = tilessquare
 CASE "S": IF allplanes THEN allplanes = 0 ELSE allplanes = 1
  tilesremain = tilessquare
 CASE "D": DO: key$ = INKEY$: LOOP UNTIL LEN(key$): desplane = VAL(key$): tilesremain = tilessquare
 CASE "1", "2", "3", "4", "8": bitplanes = VAL(key$): GOSUB ResizeViewingWindow: GOSUB DefineArrays: tilesremain = 1
 CASE CHR$(0) + ";": curpalette = 0: GOSUB SetPalette
 CASE CHR$(0) + "<": curpalette = 1: GOSUB SetPalette
 CASE CHR$(0) + "=": curpalette = 2: GOSUB SetPalette
 END SELECT
 updatestatus = 1
RETURN

DrawTile:
 'Read in a whole tile, exact number of bytes depends on number of colors
 GET 1, filepos&, tile$
 bytepos = 1
 bitshift = 1
 FOR rowcount = 0 TO 64
  c1 = 1: c2 = 1: c3 = 1: c4 = 1: c5 = 1: c6 = 1: c7 = 1: c8 = 1

  a = ASC(MID$(tile$, rowcount + 1, 1))
  IF a AND 128 THEN c1 = c1 + bitshift
  IF a AND 64 THEN c2 = c2 + bitshift
  IF a AND 32 THEN c3 = c3 + bitshift
  IF a AND 16 THEN c4 = c4 + bitshift
  IF a AND 8 THEN c5 = c5 + bitshift
  IF a AND 4 THEN c6 = c6 + bitshift
  IF a AND 2 THEN c7 = c7 + bitshift
  IF a AND 1 THEN c8 = c8 + bitshift
 
  yrow = y + rowcount
  PSET (0, yrow), c1
  PSET (1, yrow), c2
  PSET (2, yrow), c3
  PSET (3, yrow), c4
  PSET (4, yrow), c5
  PSET (5, yrow), c6
  PSET (6, yrow), c7
  PSET (7, yrow), c8
 NEXT rowcount
 tempindex = ptrindex
 tempy = 0
 FOR planes = 1 TO bitplanes
  bytepos = bitmodeTable(tempindex) + 1
  bytejump = bitmodeTable(tempindex + 1)
  tempindex = tempindex + 2
  FOR rowcount = 0 TO 7
   c1 = 1: c2 = 1: c3 = 1: c4 = 1: c5 = 1: c6 = 1: c7 = 1: c8 = 1

  a = ASC(MID$(tile$, bytepos, 1))
  IF a AND 128 THEN c1 = c1 + bitshift
  IF a AND 64 THEN c2 = c2 + bitshift
  IF a AND 32 THEN c3 = c3 + bitshift
  IF a AND 16 THEN c4 = c4 + bitshift
  IF a AND 8 THEN c5 = c5 + bitshift
  IF a AND 4 THEN c6 = c6 + bitshift
  IF a AND 2 THEN c7 = c7 + bitshift
  IF a AND 1 THEN c8 = c8 + bitshift

  yrow = tempy + rowcount
  PSET (10, yrow), c1
  PSET (11, yrow), c2
  PSET (12, yrow), c3
  PSET (13, yrow), c4
  PSET (14, yrow), c5
  PSET (15, yrow), c6
  PSET (16, yrow), c7
  PSET (17, yrow), c8
  bytepos = bytepos + bytejump
  NEXT rowcount
  tempy = tempy + 9
 NEXT planes
 filepos& = filepos& + nexttile
RETURN

SetPalette:
 SELECT CASE curpalette
 CASE 0: PALETTE 'Default palette
 CASE 1 'Grey palette
  OUT &H3C8, 0
  colors = 2 ^ bitplanes
  colorfactor! = 64 / colors
  FOR a = 1 TO colors
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
 LINE (10, 0)-(17, 71), 0, BF
RETURN

'bitmodetable data
'    0 1 2 3 4  5 6  7 8  9 10 11 2 3 4  5 6 7 8 9 20 1 2 3
DATA 0,2,1,2,16,2,17,2,32,2,33,2,48,2,49,2,0,2,1,2,16,1,0,1
'table pointer data
DATA 0,22,0,16,0,0,0,0,0

