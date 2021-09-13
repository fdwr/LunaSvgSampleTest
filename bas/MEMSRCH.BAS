DEFINT A-Z

DIM ByteTable(0 TO 255) AS LONG
SCREEN 13
PRINT "Searching byte:";

MemPos& = 0: MemSeg& = 0: DEF SEG = MemSeg&
ReadNextByte:
DO
  Index = PEEK(MemPtr)
  ByteTable(Index) = ByteTable(Index) + 1
  MemPtr = MemPtr + 1
LOOP UNTIL MemPtr >= 16384
MemPos& = MemPos& + MemPtr
MemSeg& = MemPos& \ 16
MemPtr = MemPos& AND 15
IF MemSeg& <= 65535 THEN
    DEF SEG = MemSeg&
    LOCATE 1, 16: PRINT MemPos&
    IF INKEY$ <> CHR$(27) GOTO ReadNextByte
END IF
ExitReadByteLoop:

LeastCount& = 2147483647
MostCount& = 0
FOR Index = 0 TO 255
  IF ByteTable(Index) < LeastCount& THEN RarestByte = Index: LeastCount& = ByteTable(Index)
  IF ByteTable(Index) > MostCount& THEN CommonByte = Index: MostCount& = ByteTable(Index)
NEXT Index

LOCATE 1, 1: PRINT "Rarest byte,"; RarestByte; "was found"; LeastCount&; "times";
LOCATE 2, 1: PRINT "Most common,"; CommonByte; "was found"; MostCount&; "times";
LOCATE 4, 1: PRINT "Press any key to display graph..."
DO: LOOP UNTIL LEN(INKEY$)
CLS

ScaleSize# = MostCount& * 10
CurIndex = CommonByte
Change = 1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE CHR$(27): EXIT DO
  CASE CHR$(0) + "K": CurIndex = (CurIndex - 1) AND 255: Change = 1
  CASE CHR$(0) + "M": CurIndex = (CurIndex + 1) AND 255: Change = 1
  CASE CHR$(0) + "P": CurIndex = (CurIndex - 16) AND 255: Change = 1
  CASE CHR$(0) + "H": CurIndex = (CurIndex + 16) AND 255: Change = 1
  END SELECT

  IF Change = 1 THEN
    ChangeTime# = TIMER
    Change = 2
    ScaleBase& = INT(ScaleSize#)
    ScaleDif& = ByteTable(CurIndex) - ScaleBase&
    LOCATE 1, 33: PRINT "Index:";
    LOCATE 2, 34: PRINT CurIndex;
    IF CurIndex > 31 THEN PRINT CHR$(CurIndex);
  ELSEIF Change = 2 THEN
    'based on time between now and when changed, calculate new scale
    TimeDif# = TIMER - ChangeTime#
    IF TimeDif# > 1 THEN
      ScaleSize# = ByteTable(CurIndex)
      Change = 0
    ELSE
      ScaleSize# = ScaleBase& + ScaleDif& * TimeDif#
    END IF
    GOSUB DrawScaleBars
  END IF
LOOP

END

DrawScaleBars:
  IF ScaleSize# = 0 THEN ScaleSize# = 1
  FOR Index = 0 TO 255
    Scale& = INT(ByteTable(Index) * 160 / ScaleSize#)
    IF Scale& > 199 THEN Scale& = 199
    IF Index = CurIndex THEN BarColor = 15 ELSE BarColor = 32 + Index \ 8
    LINE (Index, 0)-(Index, Scale&), BarColor
    LINE (Index, Scale& + 1)-(Index, 199), 0
  NEXT Index
RETURN

