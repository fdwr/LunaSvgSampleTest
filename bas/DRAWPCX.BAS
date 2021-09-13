DEFINT A-Z
DECLARE SUB GetPcxInfo (PcxHeight, PcxWidth)
DECLARE SUB DrawPcxFile (PcxHeight, PcxWidth, RowBase, ColBase)

SCREEN 13: CLS

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
LOCATE 25, 1: PRINT SPACE$(40);
LOCATE 25, 1: PRINT PcxWidth; "x"; PcxHeight; "="; PcxWidth * CLNG(PcxHeight);
IF PcxHeight > 192 THEN RowBase = 0 ELSE RowBase = 8
DrawPcxFile PcxHeight, PcxWidth, RowBase, ColBase

SLEEP
GOTO GetName

ClearLine: LOCATE 1, 1: PRINT SPACE$(40); : RETURN

LoadPcxHandler: LoadErr = 1: RESUME NEXT

EndProgram:

SUB DrawPcxFile (PcxHeight, PcxWidth, RowBase, ColBase)

total& = PcxWidth * CLNG(PcxHeight)

SEEK 1, 129
count& = 0
WHILE count& < total&
 byte = ASC(INPUT$(1, 1))

 IF byte > 191 THEN
  numBytes = byte - 192
  byte = ASC(INPUT$(1, 1))
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

END SUB

SUB GetPcxInfo (PcxHeight, PcxWidth)

GET 1, 9, PcxWidth
GET 1, 11, PcxHeight
PcxWidth = PcxWidth + 1
PcxHeight = PcxHeight + 1

END SUB

