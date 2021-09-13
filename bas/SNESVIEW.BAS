' any color plane version

' This sprite reader was programmed in QuickBasic so that
' almost any programmer should be able to understand how
' SNES sprites are encoded. Yes its sloppy, yes its slow
' but it also took me two minutes to write. And it gives
' you something to work on. :-)

DEFINT A-Z
COLOR 7, 0
CLS
PRINT "Quick-piece-of-junk SNES Sprite Reader (any color) v0.01"
PRINT "Programmed by VileWrath 1997 in two minutes."
PRINT "Edited and beefed-up by Dwayne"
PRINT
INPUT "FileName: ", f$
IF f$ = "" THEN f$ = "\dw\net\roms\allstars.smc"
OPEN f$ FOR INPUT AS #1: CLOSE #1
'If the program stopped here, it means a file error
INPUT "Bitplanes:", bitplanes
IF bitplanes = 0 THEN bitplanes = 4
GOSUB DefineArrays
SCREEN 13
OPEN f$ FOR BINARY AS #1
'FOR a = 1 TO 14
'PALETTE a - 1, (a * 4) - 4
'NEXT a
GOTO SkipGreyPalette
OUT &H3C8, 0
FOR a = 0 TO 15
 rgb = a * 4
 OUT &H3C9, rgb
 OUT &H3C9, rgb
 OUT &H3C9, rgb
NEXT a
SkipGreyPalette:
tile$ = SPACE$(64) '8x8x4bits = 256bits \ 8 = 32 bytes
x = 0: y = 0
filebase& = 1
filepos& = filebase&
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
 filepos& = filepos& + nexttile

 x = x + 8
 IF x >= 128 THEN y = y + 8: x = 0
 IF y > 190 THEN
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
   x = 0: y = 0
 END IF

LOOP

EndProgram:
CLOSE
END

DefineArrays:
'DIM nextplane(0 TO 7)
nextplane(0) = 0:  nextplane(1) = 1
nextplane(2) = 16: nextplane(3) = 17
nextplane(4) = 32: nextplane(5) = 33
nextplane(6) = 48: nextplane(7) = 49
'bitplanes = 4
lastplane = bitplanes - 1
nexttile = 8 * bitplanes - 16
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

