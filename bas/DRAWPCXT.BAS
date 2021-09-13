'10-18-97 FDwR
'4-10-98  Optimised for speed
'4-14-98  Added cheap directory listing
DEFINT A-Z
DECLARE SUB GetPcxInfo (PcxHeight, PcxWidth, Header$)
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

GetName:
GOSUB ClearLine
COLOR 7: LOCATE 1, 1: LINE INPUT PcxFile$
IF PcxFile$ = "" GOTO EndProgram ELSE PcxFile$ = LCASE$(PcxFile$)
IF INSTR(PcxFile$, "*") THEN CLS : SHELL "dir " + PcxFile$: WHILE INKEY$ = "": WEND: GOTO GetName

ON ERROR GOTO LoadPcxHandler
LoadErr = 0: OPEN PcxFile$ FOR INPUT AS #1: CLOSE #1
IF LoadErr AND LCASE$(RIGHT$(PcxFile$, 4)) <> ".pcx" THEN
 LoadErr = 0: OPEN PcxFile$ + ".pcx" FOR INPUT AS #1: CLOSE #1
 IF LoadErr = 0 THEN PcxFile$ = PcxFile$ + ".pcx"
END IF
IF LoadErr THEN
 GOSUB ClearLine
 LOCATE 1, 1: PRINT "Can not find that file"; LoadErr;
 WHILE INKEY$ = "": WEND
 GOSUB ClearLine
 GOTO GetName
END IF
ON ERROR GOTO 0

OPEN PcxFile$ FOR BINARY AS #1

CLS
'LINE (0, RowBase)-(PcxWidth - 1, PcxHeight + RowBase - 1), 0, BF
LOCATE 1, 1: PRINT PcxFile$;
GetPcxInfo PcxHeight, PcxWidth, Header$
GOSUB PrintHeaderItems

IF PcxHeight > 192 THEN RowBase = 0 ELSE RowBase = 8
DrawPcxFile PcxHeight, PcxWidth, RowBase, ColBase

'DEF SEG = &HA000
'BSAVE "", 0, 64000

CLOSE 1
SLEEP

GOSUB BrightenStats
GOTO GetName

ClearLine: LOCATE 1, 1: PRINT SPACE$(40); : RETURN

LoadPcxHandler: LoadErr = ERR: RESUME NEXT

PrintHeaderItems:
COLOR 7
byte = 1
FOR count = 0 TO 15
 LOCATE count + 5, 1: PRINT PcxHeader$(count);
 LOCATE , 25
 SELECT CASE PcxHeaderLen(count)
 CASE 1: PRINT ASC(MID$(Header$, byte, 1));
 CASE 2: PRINT CVI(MID$(Header$, byte, 2));
 CASE ELSE: PRINT " ÄÄ";
 END SELECT
 byte = byte + PcxHeaderLen(count)
NEXT count
RETURN

BrightenStats:
OUT &H3C8, 7: OUT &H3C9, 43: OUT &H3C9, 43: OUT &H3C9, 43
RETURN

EndProgram:
WIDTH 80, 25

SUB DrawPcxFile (PcxHeight, PcxWidth, RowBase, ColBase)

filcount& = LOF(1) - 896
IF filcount& < 0 THEN EXIT SUB
REDIM PictMap(0 TO 8191) AS DOUBLE
DEF SEG = VARSEG(PictMap(0))
PcxWidth = PcxWidth + (PcxWidth AND 1)
total& = PcxWidth * CLNG(PcxHeight)
count& = 0
filepos& = 129
Row = RowBase
Col = ColBase
RowWidth = PcxWidth - 1

GOSUB LoadPictureSegment

WHILE count& < total&
 byte = PEEK(bytepos&): IF bytepos& < 65535 THEN bytepos& = bytepos& + 1 ELSE GOSUB LoadPictureSegment

 IF byte > 191 THEN
  numBytes = byte - 192
  byte = PEEK(bytepos&): IF bytepos& < 65535 THEN bytepos& = bytepos& + 1 ELSE GOSUB LoadPictureSegment
  count& = count& + numBytes
  WHILE numBytes > 0
   PSET (Col, Row), byte
   IF Col < RowWidth THEN Col = Col + 1 ELSE Col = ColBase: Row = Row + 1
   numBytes = numBytes - 1
  WEND
 ELSE
  PSET (Col, Row), byte
  IF Col < RowWidth THEN Col = Col + 1 ELSE Col = ColBase: Row = Row + 1
  count& = count& + 1
 END IF
WEND
 'PSET (count& MOD PcxWidth + ColBase, count& \ PcxWidth + RowBase), byte

'SEEK 1, LOF(1) - 767
'FilePalette$ = INPUT$(768, 1)
'DEF SEG = VARSEG(FilePalette$)
'BSAVE "", SADD(FilePalette$), 768
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
 FOR bytes = 0 TO (tmptotal& + 7) \ 8 - 1
  GET 1, filepos&, PictMap(bytes)
  filepos& = filepos& + 8
 NEXT bytes
 bytepos& = VARPTR(PictMap(0))
RETURN

END SUB

SUB GetPcxInfo (PcxHeight, PcxWidth, Header$)

GET 1, 9, PcxWidth
GET 1, 11, PcxHeight
PcxWidth = PcxWidth + 1
PcxHeight = PcxHeight + 1

SEEK 1, 1
Header$ = INPUT$(128, 1)

END SUB

