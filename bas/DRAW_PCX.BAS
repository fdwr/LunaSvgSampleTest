DEFINT A-Z
DECLARE SUB GetPcxInfo (PcxHeight, PcxWidth)
DECLARE SUB DrawPcxFile (PcxHeight, PcxWidth, RowBase, ColBase)

SCREEN 13: CLS

DIM SHARED PcxHeader$(0 TO 15), PcxHeaderLen(0 TO 15)
FOR count = 0 TO 15
 READ PcxHeader$(count), PcxHeaderLen(count)
NEXT count
DATA "Manufacturer",1,"Version",1,"Encoding",1,"Bits per pixel",1,"Top",2
DATA "Left",2,"Width",2,"Height",2,"Horizontal resolution",2
DATA "Vertical resolution",2,"Ega palette",48,"Reserved blank",1,"Color planes number",1
DATA "Bytes per line",2,"Palette type",2,"Blank extra padding",58

FOR count = 0 TO 15
 LOCATE count + 5, 1: PRINT PcxHeader$(count);
NEXT count

GetName:
GOSUB ClearLine
LOCATE 1, 1: LINE INPUT PcxFile$
IF PcxFile$ = "" GOTO EndProgram

ON ERROR GOTO LoadPcxHandler
LoadErr = 0: OPEN PcxFile$ FOR INPUT AS #1: CLOSE #1
IF LoadErr AND LCASE$(RIGHT$(PcxFile$, 4)) <> ".pcx" THEN
 LoadErr = 0: OPEN PcxFile$ + ".pcx" FOR INPUT AS #1: CLOSE #1
 IF LoadErr = 0 THEN PcxFile$ = PcxFile$ + ".pcx"
END IF
IF LoadErr THEN
 GOSUB ClearLine
 LOCATE 1, 1: PRINT "Can not find that file";
 WHILE INKEY$ = "": WEND
 GOSUB ClearLine
 GOTO GetName
END IF
ON ERROR GOTO 0

OPEN PcxFile$ FOR BINARY AS #1

LINE (0, RowBase)-(PcxWidth - 1, PcxHeight + RowBase - 1), 0, BF
PcxFile$ = LCASE$(PcxFile$): LOCATE 1, 1: PRINT PcxFile$;
GetPcxInfo PcxHeight, PcxWidth
IF PcxHeight > 192 THEN RowBase = 0 ELSE RowBase = 8
DrawPcxFile PcxHeight, PcxWidth, RowBase, ColBase

SLEEP
GOTO GetName

ClearLine: LOCATE 1, 1: PRINT SPACE$(40); : RETURN

LoadPcxHandler: LoadErr = 1: RESUME NEXT

EndProgram:

SUB DrawPcxFile (PcxHeight, PcxWidth, RowBase, ColBase)

filcount& = LOF(1) - 896
IF filcount& < 0 THEN EXIT SUB
REDIM PictMap(0 TO 8191) AS DOUBLE
DEF SEG = VARSEG(PictMap(0))
total& = PcxWidth * CLNG(PcxHeight)
count& = 0
filepos& = 129

GOSUB LoadPictureSegment

WHILE count& < total&
 byte = PEEK(bytepos&): IF bytepos& < 65535 THEN bytepos& = bytepos& + 1 ELSE GOSUB LoadPictureSegment

 IF byte > 191 THEN
  numBytes = byte - 192
  byte = PEEK(bytepos&): IF bytepos& < 65535 THEN bytepos& = bytepos& + 1 ELSE GOSUB LoadPictureSegment
  WHILE numBytes > 0
   PSET (count& MOD PcxWidth + ColBase, count& \ PcxWidth + RowBase), byte
   count& = count& + 1
   numBytes = numBytes - 1
  WEND
 ELSE
  PSET (count& MOD PcxWidth + ColBase, count& \ PcxWidth + RowBase), byte
  count& = count& + 1
 END IF
WEND

SEEK 1, LOF(1) - 767
FOR count = 0 TO 255
 OUT &H3C8, count
 byte = ASC(INPUT$(1, 1)): OUT &H3C9, byte \ 4
 byte = ASC(INPUT$(1, 1)): OUT &H3C9, byte \ 4
 byte = ASC(INPUT$(1, 1)): OUT &H3C9, byte \ 4
NEXT count

EXIT SUB

LoadPictureSegment:
 IF filcount& > 65536 THEN filcount& = filcount& - 65536: tmptotal& = 65536 ELSE tmptotal& = filcount&: filcount& = 0
 FOR bytes& = 0 TO (tmptotal& + 7) \ 8 - 1
  GET 1, filepos&, PictMap(bytes&)
  filepos& = filepos& + 8
 NEXT bytes&
 bytepos& = VARPTR(PictMap(0))
RETURN

END SUB

SUB GetPcxInfo (PcxHeight, PcxWidth)

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

END SUB

