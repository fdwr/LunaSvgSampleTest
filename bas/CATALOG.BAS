DEFINT A-Z
DECLARE SUB DELETE (Text$, St%, Lg%)
DECLARE SUB INSERT (Text$, Part$, Ofset%)
DECLARE SUB PRINTROW (Urow%, Lcol%, Colr%, Text$)
DECLARE SUB DRAWBOX (Row1%, Row2%, Col1%, Col2%, Colr%, Side%, Side$, Titl$)
DECLARE SUB AdjustPT (ReferList$, Ofset%, Adjust%)
DECLARE SUB HelpLine (Text$, Mode%)
DECLARE SUB InfoLine (Mode%)
DECLARE FUNCTION NMBR$ (Number%, Spaces%)
DECLARE FUNCTION GetEntry$ (Row%, Col%, DataErr%)
'If change then Hide Cursor, Move screen the amount that it has changed,
'redraw the new portion of the screen, and draw the cursor

DIM SHARED EntryData$, ReferList$, EntryCols, Colors(0 TO 7), CurrRow, CurrCol
'SetScreen
SCREEN 0, 1, 0, 0: WIDTH 80, 25: VIEW PRINT 1 TO 25: LOCATE , , 0
Chng = -1
'Variables
EntryData$ = "Vincent's12541397.A03JanMethodist Hospital, I hate this place!"
ReferList$ = CHR$(10) + CHR$(0) + "" + CHR$(0) + CHR$(25) + CHR$(0)
EntryCols = 3: TopEntry = 4: LowEntry = 20
BoxDat$ = "³12541397.A03    ³   ³Methodist Hospital, This place is big                   ³"
REDIM Entry(0 TO EntryCols - 1, 0 TO 1)
Entry(0, 0) = 16: Entry(0, 1) = 1
Entry(1, 0) = 3: Entry(1, 1) = 18
Entry(2, 0) = 56: Entry(2, 1) = 22

'SetColors
Colors(0) = 0: Colors(1) = 7   'Normal Words
Colors(2) = 15: Colors(3) = 3 'Highlighted Words
Colors(4) = 0: Colors(5) = 1   'Inactive Title Bar
Colors(6) = 15: Colors(7) = 1  'Active Title Bar

COLOR Colors(0), Colors(1): LOCATE 1, 1: PRINT " Quit  File  Edit  Lines  Search  Help" + SPACE$(42);
COLOR Colors(6), Colors(5): LOCATE 2, 1: PRINT "     Filename     Month       Description (location, inspection, notes)        ";
HelpLine "Press the Menu key (Alt) for menu bar  <F1=Help>", -1
InfoLine -2

Entries = 1
LOCATE 3, 1, 0: COLOR Colors(5), Colors(1)
FOR t% = 3 TO 23
 LOCATE t%, 1
 PRINT "ÛÝ               ³     ³                                                      Þ"
NEXT t%

GOSUB ShowCursor
DO UNTIL Done
 Kbrd$ = INKEY$: IF Kbrd$ > "" THEN WHILE INKEY$ > "": WEND
 LastRow = LEN(ReferList$) \ EntryCols \ 2
 SELECT CASE Kbrd$
 CASE CHR$(9): IF CurrCol + 1 = EntryCols THEN IF CurrRow + 1 < LastRow THEN xc = 1 - EntryCols: yc = 1 ELSE  ELSE xc = 1
 CASE CHR$(0) + CHR$(15): IF CurrCol = 0 THEN IF CurrRow > 0 THEN xc = EntryCols - 1: yc = -1 ELSE  ELSE xc = -1
 CASE CHR$(0) + "P": IF CurrRow + 1 < LastRow THEN yc = 1
 CASE CHR$(0) + "H": IF CurrRow > 0 THEN yc = -1
 CASE "": Done = -1
 CASE ELSE: Chng = 0
 END SELECT
 IF xc OR yc THEN GOSUB HideCursor: CurrCol = CurrCol + xc: CurrRow = CurrRow + yc: GOSUB ShowCursor: xc = 0: yc = 0: HelpLine "", 2
LOOP
END

HideCursor:
 'IF Crsr AND CurrRow >= 0 AND CurrRow < Entries THEN
 ' Colr = Colors(1) * 16 + Colors(0)
 ' IF CurrRow - 1 = -1 THEN PRINTROW CurrRow + TopEntry, 1, Colr, BoxTop$ ELSE PRINTROW CurrRow + TopEntry, 1, Colr, BoxDat$
 ' PRINTROW 5 + CurrRow, 1, Colr, BoxDat$
 ' IF CurrRow + 1 = Entries THEN PRINTROW CurrRow + TopEntry + 2, 1, Colr, BoxBot$ ELSE PRINTROW CurrRow + TopEntry + 2, 1, Colr, BoxDat$
 'END IF
RETURN

ShowCursor:
  'LOCATE 2, 1
  'COLOR 11, 3
  'IF CurrCol < 3 AND CurrCol >= 0 THEN l = Entry(CurrCol, 0): c = Entry(CurrCol, 1): Crsr = -1 ELSE Crsr = 0
  'IF Crsr AND CurrRow >= 0 AND CurrRow < Entries THEN
  ' DRAWBOX 4 + CurrRow, 6 + CurrRow, c, c + l + 1, Colors(3) + (Colors(1) * 16), 255, "ÜÜßßÜßÛÛ", ""
  ' LOCATE CurrRow + 5, c + 1: COLOR Colors(0), Colors(1): PRINT LEFT$(GetEntry$(CurrRow, CurrCol, 0), l)
  'END IF
RETURN

SUB AdjustPT (ReferList$, Ofset, Adjust)
IF Adjust = 0 THEN EXIT SUB
FOR Refer = Ofset TO LEN(ReferList$) STEP 2
MID$(ReferList$, Refer, 2) = MKI$(CVI(MID$(ReferList$, Refer, 2)) + Adjust)
NEXT Refer
END SUB

SUB DELETE (Text$, St, Lg)
IF SGN(Lg) = -1 THEN Lt = St + Lg: Rt = LEN(Text$) - St ELSE Lt = St: Rt = LEN(Text$) - (St + Lg)
IF Lt > LEN(Text$) THEN Lt = LEN(Text$) ELSE IF Lt < 0 THEN Lt = 0
IF Rt > LEN(Text$) THEN Rt = LEN(Text$) ELSE IF Rt < 0 THEN Rt = 0
Text$ = LEFT$(Text$, Lt) + RIGHT$(Text$, Rt)
END SUB

SUB DRAWBOX (Row1, Row2, Col1, Col2, Colr, Side, Tide$, Titl$)
IF Row1 > Row2 THEN SWAP Row1, Row2: Chng = Chng XOR 1
IF Col1 > Col2 THEN SWAP Col1, Col2: Chng = Chng XOR 2
BoxWidth = Col2 - Col1 + 1: Side$ = "Ú¿ְÙִִ³³ֱֲֳ´": MID$(Side$, 1, 12) = Tide$

IF (Side AND 256) AND Col1 < Col2 THEN FOR Vset = Row1 + 1 TO Row2 - 1: PRINTROW Vset, Col1 + 1, Colr, SPACE$(BoxWidth - 2): NEXT Vset
IF Side AND 1 THEN PRINTROW Row1, Col1, Colr, MID$(Side$, 1, 1)
IF Side AND 16 THEN IF Col1 = Col2 THEN PRINTROW Row1, Col1, Colr, "ֲ" ELSE PRINTROW Row1, Col1 + 1, Colr, STRING$(BoxWidth - 2, MID$(Side$, 5, 1))
IF Side AND 2 THEN PRINTROW Row1, Col2, Colr, MID$(Side$, 2, 1)
IF Side AND 64 THEN IF Row1 = Row2 THEN PRINTROW Row1, Col1, Colr, "ֳ" ELSE FOR Vset = Row1 + 1 TO Row2 - 1 STEP 1: PRINTROW Vset, Col1, Colr, MID$(Side$, 7, 1): NEXT Vset
IF Side AND 128 THEN IF Row1 = Row2 THEN PRINTROW Row1, Col2, Colr, "´" ELSE FOR Vset = Row1 + 1 TO Row2 - 1 STEP 1: PRINTROW Vset, Col2, Colr, MID$(Side$, 8, 1): NEXT Vset
IF Side AND 4 THEN PRINTROW Row2, Col1, Colr, MID$(Side$, 3, 1)
IF Side AND 32 THEN IF Col1 = Col2 THEN PRINTROW Row2, Col1, Colr, "ֱ" ELSE PRINTROW Row2, Col1 + 1, Colr, STRING$(BoxWidth - 2, MID$(Side$, 6, 1))
IF Side AND 8 THEN PRINTROW Row2, Col2, Colr, MID$(Side$, 4, 1)
'IF Side AND 16 THEN FOR Hset = Col1 + 1 TO Col2 - 1: LOCATE Row1, Hset: PRINT "ִ"; : NEXT Hset
'IF Side AND 32 THEN FOR Hset = Col1 + 1 TO Col2 - 1: LOCATE Row2, Hset: PRINT "ִ"; : NEXT Hset

IF Chng AND 1 THEN SWAP Row1, Row2
PRINTROW Row1, Col1 + (BoxWidth - LEN(LEFT$(Titl$, BoxWidth))) / 2, Colr, LEFT$(Titl$, BoxWidth)
IF Chng AND 2 THEN SWAP Col1, Col2
END SUB

FUNCTION GetEntry$ (Row, Col, DataErr)
IF Row < 0 THEN Row = CurrRow
IF Col < 0 THEN Col = CurrCol
IF Row < 0 OR Col < 0 OR Col > EntryCols - 1 THEN STOP: EXIT FUNCTION
AbsEnt& = (Row * EntryCols) + Col: RelPos& = (AbsEnt& * 2) + 1
IF RelPos& + 1 > LEN(ReferList$) THEN EXIT FUNCTION
Point1 = CVI(MID$(ReferList$, RelPos&, 2)): IF RelPos& + 1 = LEN(ReferList$) THEN Point2 = LEN(EntryData$) + 1 ELSE Point2 = CVI(MID$(ReferList$, RelPos& + 2, 2))
IF Point2 < Point1 THEN STOP: EXIT FUNCTION
GetEntry$ = MID$(EntryData$, Point1, Point2 - Point1)
END FUNCTION

SUB GetLines (TopLine, LowLine, ReferList$, EntryData$)
END SUB

SUB HelpLine (Text$, Mode)
CharColor = Colors(3) * 16
TextLen = LEN(Text$): IF TextLen > 78 THEN PRINTROW 25, 1, CharColor, " " + LEFT$(Text$, 78) + " " ELSE PRINTROW 25, 1, CharColor, " " + Text$ + SPACE$(79 - TextLen)
END SUB

SUB InfoLine (Mode)
CharColor = Colors(5) * 16 + Colors(6)
IF Mode = -2 THEN
 PRINTROW 24, 1, CharColor, "  Row ששש  Total ששש  Size ששששש  Name ששששששששששששששששששששששששששששששששששששששש "
 EXIT SUB
END IF
PRINTROW 24, 1, CharColor, "³ " + NMBR$(CurrRow + 1, 3) + ":" + NMBR$(LEN(ReferList$) \ EntryCols \ 2, 3) + " "
PRINTROW 24, 71, CharColor, " " + NMBR$(LEN(EntryData$) + LEN(ReferList$) + 8, 5) + " Bt "
END SUB

SUB INSERT (Text$, Part$, Ofset%)
IF Ofset% < 0 OR Ofset% > LEN(Text$) THEN EXIT SUB
Text$ = LEFT$(Text$, Ofset%) + Part$ + RIGHT$(Text$, LEN(Text$) - Ofset%)
END SUB

SUB LoadIDX (FileName$, ReferList$, DataEntry$, EntryCols, IndexType)
OPEN FileName$ FOR INPUT AS #1: CLOSE #1
OPEN FileName$ FOR BINARY AS #1
SEEK 1, 1: IF INPUT$(3, 1) <> "IDX" THEN GOTO UnknownType
HelpLine " Loading...", 1

SELECT CASE INPUT$(1, 1)
CASE "1": IF LOF(1) < 8 THEN GOTO UnknownType ELSE IndexType = 0
 MaxRows = ASC(INPUT$(1, 1)): EntryCols = ASC(INPUT$(1, 1)): Pointers = CVI(INPUT$(2, 1)) AND 32767
 ReferList$ = "": EntryData$ = "": ReferList$ = INPUT$(Pointers, 1): EntryData$ = INPUT$(LOF(1) - SEEK(1) + 1, 1)
CASE ELSE: GOTO UnknownType
END SELECT
CLOSE #1
EXIT SUB

UnknownType:
BEEP: CLOSE #1
END SUB

DEFSNG A-Z
FUNCTION NMBR$ (Number%, Spaces%)
NMBR$ = RIGHT$(STRING$(Spaces%, "0") + LTRIM$(STR$(Number%)), Spaces%)
END FUNCTION

DEFINT A-Z
SUB PRINTROW (Urow, Lcol, Colr, Text$)
DEF SEG = &HB800
Tset = (Urow - 1) * 80 + (Lcol - 2)
Cset = (Urow - 1) * 160 + (Lcol - 2) * 2 + 1
FOR Show = 1 TO LEN(Text$)
 POKE (Tset + Show) * 2, ASC(MID$(Text$, Show, 1))
 POKE Cset + (Show * 2), Colr
NEXT Show
END SUB

SUB PutEntry (Row, Col, Entry$, DataErr)
IF Row < 0 OR Col < 0 OR Col > EntryCols - 1 THEN STOP: EXIT SUB
AbsEnt& = (Row * EntryCols) + Col: RelPos& = (AbsEnt& * 2) + 1
IF RelPos& + 1 > LEN(ReferList$) THEN STOP: EXIT SUB
Point1 = CVI(MID$(ReferList$, RelPos&, 2)): IF RelPos& + 1 = LEN(ReferList$) THEN Point2 = LEN(EntryData$) + 1 ELSE Point2 = CVI(MID$(ReferList$, RelPos& + 2, 2))
LenAdj = LEN(Entry$) - (Point2 - Point1)
IF SGN(LenAdj) = 1 THEN INSERT EntryData$, SPACE$(LenAdj), Point1 - 1
IF SGN(LenAdj) = -1 THEN DELETE EntryData$, Point1 - 1, ABS(LenAdj)
IF Point1 < LEN(EntryData$) THEN MID$(EntryData$, Point1) = Entry$
AdjustPT ReferList$, RelPos& + 2, LenAdj
END SUB

SUB PutLines (TopLine, ReferList$, EntryData$)
END SUB

SUB RemLines (TopLine, LowLine)
END SUB

SUB SaveIDX (FileName$, ReferList$, DataEntry$, EntryCols, IndexType)
OPEN FileName$ FOR OUTPUT AS #1
HelpLine " Loading...", 1

SELECT CASE IndexType
CASE 0: PRINT #1, "IDX1"; CHR$(0); CHR$(EntryCols); MKI$(LEN(ReferList$)); ReferList$; EntryData$;
CASE 1
CASE 2
IF LEN(ReferList$) < 2 THEN PRINT #1, EntryData$ ELSE Entry1 = CVI(ReferList$): PRINT #1, MID$(EntryData$, 1, Entry1 - 1)
FOR Refer = 1 TO LEN(ReferList$) STEP 6
 Entry2 = CVI(MID$(ReferList$, Refer + 2, 2)): Entry3 = CVI(MID$(ReferList$, Refer + 4, 2)): IF Refer + 6 < LEN(ReferList$) THEN Entry4 = CVI(MID$(ReferList$, Refer + 6, 2)) ELSE Entry4 = LEN(EntryData$)
 PRINT #1, MID$(EntryData$, Entry1, Entry2 - Entry1), MID$(EntryData$, Entry2, Entry3 - Entry2), MID$(EntryData$, Entry3, Entry4 - Entry3): Entry1 = Entry4
NEXT Refer
END SELECT
CLOSE #1
END SUB

SUB SCROLLBAR (AF1, AF2, AT1, AT2, Side1, Side2, Lin, Mode)

TBL = ABS(Side2 - Side1 + SGN(Side2 - Side1)) - 2
ABL = ABS(AT1 - AT2 + SGN(AT1 - AT2))
 IF TBL% < 1 OR ABL = 0 THEN EXIT SUB
'TPL = TRUNC(ABS(AF2 - AF1 + SGN(AF2 - AF1)) * TBL / ABL, 1, 1)
'TPO = INT((TRUNC((AF1), (AF2), 0) - AT1) * TBL / ABL)

'RPO = TPO: RPL = TRUNC(TPL - TRUNC(TPO + TPL - TBL, 0, 1), 0, 1)
'IF TPO < 0 THEN RPL = TRUNC(TPL + TPO, 0, 1): RPO = 0 ELSE IF TPO >= TBL THEN RPO = 0
'Bar$ = STRING$(TBL, 176): MID$(Bar$, 1 + RPO, RPL%) = STRING$(RPL, "Û")

IF Mode% THEN
 LOCATE Side1, Lin: IF TPO < 0 THEN PRINT "";  ELSE PRINT "";
 LOCATE Side2, Lin: IF TPO + TPL > TBL THEN PRINT "";  ELSE PRINT "";
 FOR Vset = 1 TO TBL
  LOCATE Side1 + Vset, Lin
  PRINT MID$(Bar$, Vset, 1);
 NEXT Vset
ELSE
 LOCATE Lin, Side1: IF TPO < 0 THEN PRINT "®";  ELSE PRINT "";
 LOCATE Lin, Side2: IF TPO + TPL > TBL THEN PRINT "¯";  ELSE PRINT "";
 'LOCATE Lin, TRUNK(Side1%, Side2%, 0) + 1: PRINT Bar$;
END IF
END SUB

