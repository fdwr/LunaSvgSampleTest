DEFINT A-Z
DECLARE SUB StatusBar (Text$)

RANDOMIZE TIMER
testfile$(1) = "town.pic": testfile$(0) = "pilot.pic"

SCREEN 13

ON ERROR GOTO FileOpenErr
 OPEN testfile$(0) FOR INPUT AS 1: CLOSE #1: IsPict(0) = NOT NoFile: NoFile = 0
 OPEN testfile$(1) FOR INPUT AS 1: CLOSE #1: IsPict(1) = NOT NoFile
ON ERROR GOTO 0

REDIM PilotPict(0 TO 7999) AS DOUBLE
IF IsPict(1) THEN
 DEF SEG = VARSEG(PilotPict(0))
 BLOAD testfile$(1), VARPTR(PilotPict(0))
END IF

REDIM PictPal(0 TO 95, 0 TO 1) AS DOUBLE
FOR CurPict = 0 TO 1
 IF IsPict(CurPict) THEN
  OPEN testfile$(CurPict) FOR BINARY AS 1
  FilPos& = LOF(1) - 767
  FOR count = 0 TO 95
   GET 1, FilPos&, PictPal(count, CurPict)
   FilPos& = FilPos& + 8
  NEXT count
  CLOSE 1
 END IF
NEXT CurPict

'  FOR count = 0 TO 95
'   OUT &H3C8, count
'   byte = ASC(INPUT$(1, 1)): OUT &H3C9, byte
'   byte = ASC(INPUT$(1, 1)): OUT &H3C9, byte
'   byte = ASC(INPUT$(1, 1)): OUT &H3C9, byte
'  NEXT count

REDIM HoleRecord(0 TO 255)

CreatePattern:
StatusBar "Creating random dissolve pattern"
REDIM HoleBitArray(0 TO 255)

LINE (0, 0)-(15, 15), 11, BF
FOR pixhole = 0 TO 255
 DO
  pixpos = INT(RND * 256)
 LOOP WHILE HoleBitArray(pixpos)
 HoleBitArray(pixpos) = 1
 HoleRecord(pixhole) = pixpos

 'LOCATE lastline + 4, 1: PRINT " ";
 'LOCATE curline + 4, 1: PRINT ""; pixhole; pixpos, pixpos AND 15; pixpos \ 16; TAB(30);
 'lastline = curline
 'curline = (curline + 1) MOD 20
 PSET (pixpos AND 15, pixpos \ 16), 1

NEXT pixhole
ERASE HoleBitArray

StatusBar "Ready to display pattern, press a key"
GOSUB GetKey
IF kbrd$ = CHR$(27) GOTO EndIt

RedrawHoles:
StatusBar "Dissolving background"
IF IsPict(0) THEN
 DEF SEG = &HA000
 BLOAD testfile$(0), 0
 pixhole = 0
 GOSUB BalancePalette
END IF
IF NoFile THEN
 LINE (0, 0)-(319, 191), 11, BF
END IF

FOR pixhole = 0 TO 255
 pixpos = HoleRecord(pixhole)
 row = pixpos \ 16: tmprow = row
 col = pixpos AND 15
 FOR currow = 0 TO 11
  tmpcol = col
  FOR curcol = 0 TO 19
   PSET (tmpcol, tmprow), 0
   tmpcol = tmpcol + 16
  NEXT curcol
  tmprow = tmprow + 16
 NEXT currow
 IF INP(96) = 1 THEN EXIT FOR
 'GOSUB BalancePalette
NEXT pixhole

StatusBar "ENTER=Dissolve again  SPACE=New pattern"
GOSUB GetKey
IF kbrd$ = CHR$(13) GOTO RedrawHoles
IF kbrd$ = " " GOTO CreatePattern

EndIt:
WIDTH 80, 25
END

BalancePalette:
 SourceSegment = VARSEG(PictPal(0, 0))
 DestSegment = VARSEG(PictPal(0, 1))
 SourcePos& = VARPTR(PictPal(0, 0))
 DestPos& = VARPTR(PictPal(0, 1))
 FOR count = 0 TO 255
  OUT &H3C8, count
  DEF SEG = SourceSegment: sourcebyte = PEEK(SourcePos&): SourcePos& = SourcePos& + 1
  DEF SEG = DestSegment: destbyte = PEEK(DestPos&): DestPos& = DestPos& + 1
  difference = destbyte - sourcebyte
  destbyte = sourcebyte + difference * (pixhole / 256)
  OUT &H3C9, destbyte
  DEF SEG = SourceSegment
  OUT &H3C9, PEEK(SourcePos&): SourcePos& = SourcePos& + 1
  OUT &H3C9, PEEK(SourcePos&): SourcePos& = SourcePos& + 1
  DestPos& = DestPos& + 2
 NEXT count
RETURN

GetKey:
 WHILE INKEY$ > "": WEND
 DO: kbrd$ = INKEY$: LOOP UNTIL kbrd$ > ""
RETURN

FileOpenErr:
 NoFile = -1
RESUME NEXT

'Smear
   ran = INT(RND * 7) - 1
   PSET (tmpcol, tmprow), POINT(tmpcol + ran, tmprow + ran)
'Gray
   PSET (tmpcol, tmprow), POINT(tmpcol, tmprow) AND 15
'Scatter
pixpos = HoleRecord(0)
oldrow = pixpos \ 16: tmpoldrow = row
oldcol = pixpos AND 15
prepix = POINT(oldcol, oldrow)
FOR pixhole = 1 TO 255
 pixpos = HoleRecord(pixhole)
 row = pixpos \ 16: tmprow = row
 col = pixpos AND 15
 FOR currow = 0 TO 11
  tmpcol = col
  tmpoldcol = oldcol
  FOR curcol = 0 TO 19
   PSET (tmpoldcol, tmpoldrow), POINT(tmpcol, tmprow)
   tmpcol = tmpcol + 16
   tmpoldcol = tmpoldcol + 16
  NEXT curcol
  tmprow = tmprow + 16
  tmpoldrow = tmpoldrow + 16
 NEXT currow
 oldrow = row: tmpoldrow = oldrow
 oldcol = col
NEXT pixhole
PSET (oldcol, oldrow), prepix

SUB StatusBar (Text$)

LOCATE 25, 1: PRINT LEFT$(Text$, 40);
IF LEN(Text$) < 40 THEN PRINT SPACE$(40 - LEN(Text$));

END SUB

