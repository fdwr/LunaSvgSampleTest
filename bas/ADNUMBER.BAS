DEFINT A-Z
DECLARE SUB AddNumbers (Radix%, Addend1$, Addend2$, Sum$)
CONST Numbers$ = "0123456789ABCDEFGHIJKLMNOPQRSTUVW"

SCREEN 0: VIEW PRINT: LOCATE , , 0

COLOR , 1: CLS : PRINT "This demo shows some of large numbers that the AddNumbers sub-program contained"
PRINT "in this file can work with. I have not yet equipped it to deal with decimals,"
PRINT "but it is able to do something else that is handy. It can deal with any integer"
PRINT "of any number system up to thirty-two. That includes binary, octal, decimal,"
PRINT "hexadecimal, and any other system you could need. The numbering for decimal is"
PRINT "obviously zero to nine and hexadecimal is zero to F. Number systems beyond that"
PRINT "are just a continuation of the alphabet up to W, a total range of zero to W."
GOSUB KeyWait

CLS : PRINT "Three from the first power to the fifth-seventh, in decimal"
Radix = 10: GOSUB ShowTriAddColumns: GOSUB KeyWait
CLS : PRINT "Three from the first power to the fifty-seventh, in hexadecimal"
Radix = 16: GOSUB ShowTriAddColumns: GOSUB KeyWait
CLS : PRINT "Two from the first power to the hundred-eightieth, in decimal, Press any key..."
GOSUB KeyWait: Radix = 10: Addend$ = "1": PRINT
FOR GetNumber = 0 TO 180
 AddNumbers Radix, Addend$, Addend$, Result1$
 PRINT Result1$
 Addend$ = Result1$
NEXT GetNumber
END

KeyWait:
DO: key$ = INKEY$: LOOP UNTIL key$ > ""
IF key$ = CHR$(27) THEN END
RETURN

ShowTriAddColumns:
Row = 30: Col = 0: ColCount = 0
Addend$ = "1"
FOR GetNumber = 0 TO 56
 IF Row >= 21 THEN Row = 3: Col = Col + ColCount + 2: ColCount = 0 ELSE Row = Row + 1
 AddNumbers Radix, Addend$, Addend$, Result1$
 AddNumbers Radix, Result1$, Addend$, Result2$
 Addend$ = Result2$
 LOCATE Row, Col: PRINT Addend$;
 IF LEN(Result2$) > ColCount THEN ColCount = LEN(Result2$)
NEXT GetNumber
RETURN

SUB AddNumbers (Radix, Addend1$, Addend2$, Sum$)

REDIM Addend$(0 TO 2), NumPtr(0 TO 1), Number(0 TO 2)
Sum$ = ""
Addend$(0) = Addend1$
Addend$(1) = Addend2$
NumPtr(0) = LEN(Addend1$)
NumPtr(1) = LEN(Addend2$)
CommaCount = -1

DO UNTIL NumPtr(0) = 0 AND NumPtr(1) = 0 AND Number(2) = 0
 IF CommaCount >= 2 THEN Sum$ = "," + Sum$: CommaCount = 0 ELSE CommaCount = CommaCount + 1
 FOR GetNum = 0 TO 1
  DO
   IF NumPtr(GetNum) THEN
    Number = INSTR(Numbers$, MID$(Addend$(GetNum), NumPtr(GetNum), 1))
    NumPtr(GetNum) = NumPtr(GetNum) - 1
    IF Number THEN Number(GetNum) = Number - 1: EXIT DO
   ELSE
    Number(GetNum) = 0
    EXIT DO
   END IF
  LOOP
 NEXT GetNum
 Number = Number(0) + Number(1) + Number(2)
 IF Number >= Radix THEN Number(2) = Number \ Radix: Number = Number MOD Radix ELSE Number(2) = 0
 Sum$ = MID$(Numbers$, Number + 1, 1) + Sum$
LOOP

END SUB

