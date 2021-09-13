'1998-10-03 FDwR

DEFLNG A-Z
DECLARE SUB KeyWait ()
DECLARE SUB ShowNumForms (NumFull&)
DECLARE FUNCTION GetNextNum& (NumPos&, Num$)

CLS
VIEW PRINT 1 TO 25

'PRINT "Dividend, Divisor, Shift"
'LINE INPUT " Numbers: ", Num$
'IF LEN(Num$) = 0 THEN END

'NumPos = 1
'NumFirst = VAL(Num$)
'IF GetNextNum(NumPos, Num$) THEN NumSecond = VAL(MID$(Num$, NumPos)) ELSE PRINT "No divisor given": END
'IF GetNextNum(NumPos, Num$) THEN NumFifth = VAL(MID$(Num$, NumPos)) ELSE NumFifth = 0
'
'IF NumSecond = 0 THEN PRINT "Infinite division, divisor must be non-zero": END

NumSecond = 320
FOR NumFirst = -320 TO 320 STEP 40
  GOSUB DrawShiftedScene
  IF INKEY$ = CHR$(27) THEN EXIT FOR
NEXT NumFirst
END

PRINT " Signed number:"; NumFirst
ShowNumForms NumFirst
PRINT "    Divided by:"; NumSecond
ShowNumForms NumSecond

NumThird = NumFirst \ NumSecond
PRINT "        Equals:"; NumThird
ShowNumForms NumThird
NumFourth = NumFirst MOD NumSecond
PRINT "       Modulus:"; NumFourth
ShowNumForms NumFourth

KeyWait
CLS

NumBase = NumFifth
Row = 1: Col = 1
FOR Count = 1 TO 96
  NumMod = NumMod + NumFirst
  NumInc = NumMod \ NumSecond
  NumMod = NumMod MOD NumSecond
  LOCATE Row, Col
  PRINT NumBase; NumInc; NumMod
  NumBase = NumBase + NumInc
  IF Row >= 24 THEN Row = 1: Col = Col + 20 ELSE Row = Row + 1
NEXT Count

KeyWait
SCREEN 13

FOR Count = 0 TO 255
  OUT &H3C8, Count
  ColorShade = Count \ 4
  OUT &H3C9, ColorShade
  OUT &H3C9, ColorShade
  OUT &H3C9, ColorShade
NEXT Count

FOR Count = 0 TO 255
  PSET (Count, 0), Count
NEXT Count

NumBase = NumFifth
IF NumFirst < 0 THEN BaseCol = 199 ELSE BaseCol = 4
FOR Count = 0 TO 319
  NumMod = NumMod + NumFirst
  NumInc = NumMod \ NumSecond
  NumMod = NumMod MOD NumSecond
  PSET (Count, 2), NumBase AND 255
  PSET (Count, (BaseCol + NumBase) AND 127), NumBase AND 255
  NumBase = NumBase + NumInc
NEXT Count

KeyWait

'Pixel=0
'---loop-top----
'plot element
'add Addend to Count
'add Count \ Limit to Pixel
'set Count to mod of Limit
'--loop-bottom--
'
'The above method, while maybe proper is not at all the fastest one. Since
'each consecutive loop is only slightly different from the one before it,
'just work out the difference between the loops rather than a complete
'recalculation using slow division. You would need to use division and
'modulus for calculations that were random or did not have any reference to
'prior calculations. Since though here we do have only minor differences
'through each pass, we can just build on that. Division and modulus would
'only need to be used once before the loop started and from then on, simple
'addition (which is of course a bit faster) could do the rest.
'
'Base=0
'Inc=Addend mod Limit
'BaseStep=Addend \ Limit
'---loop-top----
'plot element
'add Inc to Count
'if Count > Limit then add one to Base
'                    subtract Limit from Inc
'add BaseStep to Base
'--loop-bottom--
'
'While it actually looks more complicated, it uses simpler (and faster)
'calculations that end up saving time in those tight loops. It does a little
'setup before entering the loop and just a little logic in the loop to save
'from doing redundant work.
'
'Base= -Limit
'Inc=Addend mod Limit
'BaseStep=Addend \ Limit
'---loop-top----
'plot element
'add Inc to Count
'if positive sign then add one to base
'                      subtract Limit from Inc
'add BaseStep to Base
'--loop-bottom--

'This method is like the last one with a strange twist. Rather than testing
'if the count has exceeded or reached the limit, it checks if it has exceeded
'negative one - in other words, if it has a positive sign. It seems a bit
'strange, but saves another step by not comparing whether base is greater and
'simply using the flags from the previous addition for the logic.

DrawShiftedScene:
SCREEN 13

REDIM Pict(0 TO 32000) AS INTEGER
DEF SEG = VARSEG(Pict(0))
BLOAD "zsnesmap.pic", 0

RowNumerator = NumFirst
RowDenominator = NumSecond
FOR Row = 0 TO 199
  BytePos = Row * 320
  GOSUB DrawShiftedLine
NEXT Row

RETURN

DrawShiftedLine:
  RowCount = 0
  FOR Col = 0 TO 319
    PSET (Col, Row), PEEK(BytePos AND 65535)
    RowCount = RowCount + RowNumerator
    RowInc = RowCount \ RowDenominator
    RowCount = RowCount MOD RowDenominator
    BytePos = BytePos + RowInc * 320 + 1
  NEXT Col
RETURN

DrawShiftedLineFast:
'Base=0
'Inc=Addend mod Limit
'BaseStep=Addend \ Limit
'---loop-top----
'plot element
'add Inc to Count
'if Inc > Limit then add one to Base
'                    subtract Limit from Inc
'add BaseStep to Base
'--loop-bottom--
  Counter = 0
  CountInc = ABS(RowNumerator)
  CountLimit = ABS(RowDenominator)
  RowIncSmall = RowNumerator \ RowDenominator
  RowIncLarge = (RowIncSmall + SGN(RowNumerator MOD RowDenominator)) * 320
  RowIncSmall = RowIncSmall * 320
  FOR Col = 0 TO 319
    PSET (Col, Row), PEEK(BytePos AND 65535)
    Counter = Counter + CountInc
    IF Counter >= CountLimit THEN
      Counter = Counter - CountLimit
      BytePos = BytePos + RowIncLarge + 1
    ELSE
      BytePos = BytePos + RowIncSmall + 1
    END IF
  NEXT Col
RETURN

FUNCTION GetNextNum (NumPos, Num$)

FOR Count = NumPos TO LEN(Num$)
  IF MID$(Num$, Count, 1) = " " OR MID$(Num$, Count, 1) = "," GOTO GetNumNextPart
NEXT Count
EXIT FUNCTION

GetNumNextPart:
FOR Count = Count + 1 TO LEN(Num$)
  IF MID$(Num$, Count, 1) <> " " THEN NumPos = Count: GetNextNum = 1: EXIT FOR
NEXT Count

END FUNCTION

DEFINT A-Z
SUB KeyWait
  DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)
  IF Key$ = CHR$(27) THEN END
END SUB

DEFLNG A-Z
SUB ShowNumForms (NumFull)
  Num$ = STRING$(16, "0")
  BitMask = 1
  FOR CurBit = 16 TO 1 STEP -1
    IF NumFull AND BitMask THEN MID$(Num$, CurBit) = "1"
    BitMask = BitMask * 2
  NEXT CurBit
  PRINT "Unsigned 16bit:"; NumFull AND 65535
  PRINT "   and in 8bit:"; NumFull AND 255
  PRINT "     In binary: "; Num$
  PRINT
END SUB

