DEFINT A-Z
DECLARE SUB GetPcxInfo ()
DECLARE SUB SetPcxPalette ()

DIM SHARED PcxHeaders$(0 TO 15), PcxHeaderLen(0 TO 15)
FOR count = 0 TO 15
 READ PcxHeaders$(count), PcxHeaderLen(count)
NEXT count
DATA "Manufacturer",1,"Version",1,"Encoding",1,"Bits per pixel",1,"Top",2
DATA "Left",2,"Width",2,"Height",2,"Horizontal resolution",2
DATA "Vertical resolution",2,"Ega palette",48,"Reserved blank",1,"Color planes number",1
DATA "Bytes per line",2,"Palette type",2,"Blank extra padding",58

SCREEN 13

FOR count = 0 TO 255
 LINE (count, 8)-(count, 70), count
NEXT count

COLOR 15
FOR count = 0 TO 15
 LOCATE count + 10, 1: PRINT PcxHeaders$(count);
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

PcxFile$ = LCASE$(PcxFile$): LOCATE 1, 1: PRINT PcxFile$;

OPEN PcxFile$ FOR BINARY AS #1
GetPcxInfo
SetPcxPalette

SLEEP
OUT &H3C8, 0: OUT &H3C9, 0: OUT &H3C9, 0: OUT &H3C9, 0
OUT &H3C8, 15: OUT &H3C9, 63: OUT &H3C9, 63: OUT &H3C9, 63
GOTO GetName

ClearLine: LOCATE 1, 1: PRINT SPACE$(40); : RETURN

LoadPcxHandler: LoadErr = 1: RESUME NEXT

EndProgram:

SUB GetPcxInfo

SEEK 1, 1
header$ = INPUT$(128, 1)

byte = 1
FOR count = 0 TO 15
 LOCATE count + 10, 25
 SELECT CASE PcxHeaderLen(count)
 CASE 1: PRINT ASC(MID$(header$, byte, 1)); " ";
 CASE 2: PRINT CVI(MID$(header$, byte, 2)); "   ";
 CASE ELSE: PRINT " ÄÄ";
 END SELECT
 byte = byte + PcxHeaderLen(count)
NEXT count

END SUB

SUB SetPcxPalette

SEEK 1, LOF(1) - 767
FOR count = 0 TO 255
 OUT &H3C8, count
 byte = ASC(INPUT$(1, 1)): OUT &H3C9, byte \ 4
 byte = ASC(INPUT$(1, 1)): OUT &H3C9, byte \ 4
 byte = ASC(INPUT$(1, 1)): OUT &H3C9, byte \ 4
NEXT count

END SUB

