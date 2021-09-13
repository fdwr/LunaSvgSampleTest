'9-6-97   First write
'10-18-97 Add header info display
'4-10-98  Optimised for speed
'4-14-98  Added cheap directory listing
DEFINT A-Z
DECLARE SUB GetPcxInfo (PcxHeight, PcxWidth, Header$)
DECLARE FUNCTION OpenPcxFile (file$)
DECLARE SUB SetPalettePcxFile (BackgroundValue, BrightestColor, DimmestColor)
DECLARE SUB DrawPcxFile (PcxHeight, PcxWidth, RowBase, ColBase)

TYPE RegType
  ax AS INTEGER: bx AS INTEGER: cx AS INTEGER: dx AS INTEGER
  BP AS INTEGER: SI AS INTEGER: DI AS INTEGER: FLAGS AS INTEGER
  ds AS INTEGER: ES AS INTEGER
END TYPE

DIM SHARED PcxHeader$(0 TO 15), PcxHeaderLen(0 TO 15), ErrorNum, Regs AS RegType
FOR count = 0 TO 15
 READ PcxHeader$(count), PcxHeaderLen(count)
NEXT count
DATA "Manufacturer",1,"Version",1,"Encoding",1,"Bits per pixel",1,"Top",2
DATA "Left",2,"Width",2,"Height",2,"Horizontal resolution",2
DATA "Vertical resolution",2,"Ega palette",48,"Reserved blank",1,"Color planes number",1
DATA "Bytes per line",2,"Palette type",2,"Blank extra padding",58

ON ERROR GOTO ErrorHandler
file$ = LTRIM$(COMMAND$)
ON ERROR GOTO 0
Row = CSRLIN: Col = POS(0)
VIEW PRINT 1 TO 25
LOCATE Row, Col

IF LEN(file$) = 0 THEN
  PRINT "ViewPCX 0.21  Used to view 256 color pcx pictures from the command line"
  PRINT "By FDwR       Originally my Windows only had 16 colors so I had to make this"
  PRINT "              to see them in their true splendor. It is very simple and very"
  PRINT "              slow, but it works :-)"
  PRINT "              Updated on May 15,1998 (first version 9-6-1997)"
  PRINT
  IF ErrorNum THEN
    PRINT "Your version of Qbasic does not support command line passing"
  ELSE
    PRINT "Usage from the command prompt: VIEWPCX file"
  END IF
  PRINT "You can type in the filename here; use '*' for a generic directory listing"
GetFileName:
  PRINT
  LINE INPUT "Pcx filename:", file$
  IF LEN(file$) = 0 THEN END
  ON ERROR GOTO ErrorHandler: ErrorNum = 0
  CHDIR file$
  ON ERROR GOTO 0
  IF ErrorNum = 0 THEN PRINT "Directory changed": GOTO GetFileName
END IF

IF INSTR(file$, "*") OR INSTR(file$, "?") THEN
  SHELL "DIR " + file$
  GOTO GetFileName
END IF

IF OpenPcxFile(file$) THEN
  SCREEN 13
  GetPcxInfo PcxHeight, PcxWidth, Header$
  SetPalettePcxFile TextColor, BrightestColor, DimmestColor
  GOSUB ShowHeaderItemsScreen
  WHILE INKEY$ = "": WEND
  CLS
  DrawPcxFile PcxHeight, PcxWidth, RowBase, ColBase
  CLOSE #1
  WHILE LEN(INKEY$): WEND
  DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)
  WIDTH 80, 25
  COLOR 7, 0: CLS 'Seems sort of redundant to need this, oh well
  IF Key$ = CHR$(13) GOTO GetFileName
ELSE
  PRINT "Could not open that file for viewing"
  GOTO GetFileName
END IF

END

ErrorHandler:
  ErrorNum = ERR
RESUME NEXT

ShowHeaderItemsScreen:
  FOR count = 0 TO 255
    LINE (count, 8)-(count, 70), count
  NEXT count

  COLOR TextColor
  byte = 1
  FOR count = 0 TO 15
    LOCATE count + 10, 1: PRINT PcxHeader$(count);
    LOCATE , 25
    SELECT CASE PcxHeaderLen(count)
    CASE 1: PRINT ASC(MID$(Header$, byte, 1));
    CASE 2: PRINT CVI(MID$(Header$, byte, 2));
    CASE ELSE: PRINT " ÄÄ";
    END SELECT
    byte = byte + PcxHeaderLen(count)
  NEXT count
RETURN

SUB DrawPcxFile (PcxHeight, PcxWidth, RowBase, ColBase)

filcount& = LOF(1) - 896
IF filcount& < 0 THEN EXIT SUB
REDIM PictMap(0 TO 8191) AS LONG
DEF SEG = VARSEG(PictMap(0))

PcxWidth = PcxWidth + (PcxWidth AND 1)
RowWidth = PcxWidth - 1
Total& = PcxWidth * CLNG(PcxHeight)
count& = 0
Filepos& = 129
Row = RowBase
Col = ColBase

'For the DOS function to read a file
DosFile = FILEATTR(1, 2)
DIM SpareRegs AS RegType
SpareRegs.ax = &H3F00
SpareRegs.bx = DosFile
SpareRegs.cx = -32768
SpareRegs.ds = VARSEG(PictMap(0))
SpareRegs.dx = VARPTR(PictMap(0))

GOSUB LoadPictureSegment

WHILE count& < Total&
 byte = PEEK(bytepos&): IF bytepos& < 32767 THEN bytepos& = bytepos& + 1 ELSE GOSUB LoadPictureSegment

 IF byte > 191 THEN
  numBytes = byte - 192
  byte = PEEK(bytepos&): IF bytepos& < 32767 THEN bytepos& = bytepos& + 1 ELSE GOSUB LoadPictureSegment
  count& = count& + numBytes
  WHILE numBytes > 0
   PSET (Col, Row), byte
   IF Col < RowWidth THEN Col = Col + 1 ELSE Col = ColBase: Row = Row + 1: IF INP(96) = 1 THEN EXIT SUB
   numBytes = numBytes - 1
  WEND
 ELSE
  PSET (Col, Row), byte
  IF Col < RowWidth THEN Col = Col + 1 ELSE Col = ColBase: Row = Row + 1: IF INP(96) = 1 THEN EXIT SUB
  count& = count& + 1
 END IF
WEND
 'PSET (count& MOD PcxWidth + ColBase, count& \ PcxWidth + RowBase), byte
EXIT SUB

LoadPictureSegment:
 IF filcount& > 32768 THEN filcount& = filcount& - 32768: tmptotal& = 32768 ELSE tmptotal& = filcount&: filcount& = 0

 bytepos& = VARPTR(PictMap(0))
 'Let's cheat a little and directly call DOS, bypassing Qb
 'FOR bytes = 0 TO (tmptotal& + 7) \ 8 - 1
 ' GET 1, Filepos&, PictMap(bytes)
 ' Filepos& = Filepos& + 8
 'NEXT bytes

 SEEK 1, Filepos&
 Regs = SpareRegs
 CALL interruptx(&H21, Regs, Regs)
 Filepos& = Filepos& + 32768
RETURN

END SUB

SUB GetPcxInfo (PcxHeight, PcxWidth, Header$)

SEEK 1, 1
Header$ = INPUT$(128, 1)

GET 1, 9, PcxWidth
GET 1, 11, PcxHeight
PcxWidth = PcxWidth + 1    'Width is stored as 1 less than the actual width
PcxHeight = PcxHeight + 1  'Height is stored as 1 less than the actual height

END SUB

FUNCTION OpenPcxFile (file$)
 
  ON ERROR GOTO ErrorHandler: ErrorNum = 0
  OPEN file$ FOR INPUT AS 1: CLOSE 1
  IF ErrorNum THEN
    ON ERROR GOTO ErrorHandler: ErrorNum = 0
    OPEN file$ + ".pcx" FOR INPUT AS 1: CLOSE 1
    IF ErrorNum = 0 THEN
      OPEN file$ + ".pcx" FOR BINARY AS 1
      OpenPcxFile = -1
      file$ = file$ + ".pcx"
    END IF
  ELSE
    OPEN file$ FOR BINARY AS #1
    OpenPcxFile = -1
  END IF
  ON ERROR GOTO 0

END FUNCTION

SUB SetPalettePcxFile (ForegroundColor, BrightestColor, DimmestColor)

BrightestValue = 0
DimmestValue = 255

SEEK 1, LOF(1) - 767
BackgroundValue = ASC(INPUT$(1, 1)) + ASC(INPUT$(1, 1)) + ASC(INPUT$(1, 1))

SEEK 1, LOF(1) - 767
FOR count = 0 TO 255
 OUT &H3C8, count
 RedValue = ASC(INPUT$(1, 1)): OUT &H3C9, RedValue \ 4
 GreenValue = ASC(INPUT$(1, 1)): OUT &H3C9, GreenValue \ 4
 BlueValue = ASC(INPUT$(1, 1)): OUT &H3C9, BlueValue \ 4
 RGBvalue = RedValue + GreenValue + BlueValue
 IF RGBvalue < DimmestValue THEN DimmestValue = RGBvalue: DimmestColor = count
 IF RGBvalue > BrightestValue THEN BrightestValue = RGBvalue: BrightestColor = count
NEXT count

IF ABS(BackgroundValue - DimmestValue) > ABS(BackgroundValue - BrightestValue) THEN ForegroundColor = DimmestColor ELSE ForegroundColor = BrightestColor

END SUB

