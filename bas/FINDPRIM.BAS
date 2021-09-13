DEFLNG A-Z

SCREEN 12
CLS
'PRINT "-- Prime number lister --"
'PRINT "This program generates a list of prime numbers"
'PRINT "in the range of 1 to 524256"

'PRINT
'PRINT "Allocating 65k for prime table"
DIM PrimeTable(0 TO 32766) AS INTEGER
DIM QuickShift(0 TO 7)
CONST Max = 524256

NumberPos = 1
FOR CreateCheat = 0 TO 7
 QuickShift(CreateCheat) = NumberPos
 NumberPos = NumberPos * 2
NEXT CreateCheat

DEF SEG = VARSEG(PrimeTable(0))
IF VARPTR(PrimeTable(0)) <> 0 THEN PRINT "Oops": END

FOR CurPrime = 2 TO Max
 NumberPos = CurPrime
 GOSUB GetTableOfset
 'LOCATE 7, 1: PRINT "Current number"; CurPrime;
 IF (PEEK(ByteOfset) AND QuickShift(BitOfset%)) = 0 THEN
  'LOCATE 8, 1: PRINT "Prime"; CurPrime;
  WHILE Max - NumberPos > CurPrime
   NumberPos = NumberPos + CurPrime
   'LOCATE 9, 1: PRINT "Eliminating multiple"; NumberPos; TAB(30);
   PSET (NumberPos MOD 640, NumberPos \ 640), 7
   GOSUB GetTableOfset
   POKE ByteOfset, PEEK(ByteOfset) OR QuickShift(BitOfset%)
  WEND
 END IF
 IF INP(96) = 1 THEN EXIT FOR
NEXT CurPrime

END

GetTableOfset:
 ByteOfset = NumberPos \ 8
 BitOfset% = NumberPos AND 7
RETURN

