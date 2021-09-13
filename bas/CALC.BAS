'3444 10-27-96
'     6-10-98
DEFINT A-Z
DECLARE FUNCTION Bin$ (Oper$)
DECLARE FUNCTION Math$ (Oper1$, Oper2$, Operator$)
SCREEN 0: WIDTH 80, 25: LOCATE , , 0, 14, 15: PRINT CHR$(13); "ÄÄÄ Simple Calculator ÄÄÄ"; CHR$(13)

DIM SHARED Oper$(0 TO 1), Operator$, Operators$, OperatorNames$, CalcSolv, CalcDegr
Operators$ = "+-*öû#!&@"
OperatorNames$ = "AddSubMulDivModExpOr XorAndEqv"
CalcDegr = 16

GOSUB ShowCalc

GetKey:
DO
Kbrd$ = INKEY$
IF Kbrd$ > "" THEN
 SELECT CASE Kbrd$
 CASE "": EXIT DO
 CASE ELSE: IF LEN(Kbrd$) = 1 THEN CalcPart$ = Kbrd$: GOSUB EditCalc: GOSUB ShowCalc
 END SELECT
END IF
LOOP
COLOR 7, 0
SYSTEM

EditCalc:
Oper$ = Oper$(CalcOper)
CalcSolv = 0
SELECT CASE UCASE$(CalcPart$)
CASE "0" TO "9", ".": GOSUB AddToOper: Oper$(CalcOper) = Oper$
CASE "I": CalcOperNew = 0
 IF INSTR(Oper$, ".") THEN Oper$(CalcOper) = LEFT$(Oper$, INSTR(Oper$, ".") - 1)
CASE "+", "-", "*", "/", "\", "^", "#", "!", "&", "@"
 IF CalcOper THEN
  Oper$(0) = LEFT$(Math$(Oper$(0), Oper$(1), Operator$), CalcDegr)
  CalcOperNew = 1
 ELSE
  Oper$(0) = Oper$
  CalcOper = 1
  CalcOperNew = 1
 END IF
 Operator$ = MID$(Operators$, INSTR("+-*/\^#!&@", CalcPart$), 1)
 OperatorName$ = MID$(OperatorNames$, (INSTR(Operators$, Operator$) - 1) * 3 + 1, 3)
CASE "=", CHR$(13)
  Oper$(0) = LEFT$(Math$(Oper$(0), Oper$(1), Operator$), CalcDegr)
  CalcOperNew = 1
  CalcOper = 0
CASE "_": CalcOperNew = 0: IF LEFT$(Oper$, 1) = "-" THEN Oper$(CalcOper) = RIGHT$(Oper$, LEN(Oper$) - 1) ELSE Oper$(CalcOper) = "-" + Oper$
CASE " ": CalcOperNew = 0
CASE "": IF Oper$ > "" THEN Oper$(CalcOper) = LEFT$(Oper$, LEN(Oper$) - 1): CalcOperNew = 0
CASE "": Oper$(0) = "": Oper$(1) = "": Operator$ = "": CalcOper = 0: CalcOperNew = 1
END SELECT
RETURN

AddToOper:
IF CalcOperNew THEN
 Oper$ = CalcPart$: CalcOperNew = 0
ELSEIF LEN(Oper$) < CalcDegr THEN
 IF CalcPart$ = "." THEN
  IF INSTR(Oper$, ".") = 0 THEN Oper$ = Oper$ + CalcPart$
 ELSE
  IF Oper$ = "0" THEN Oper$ = CalcPart$ ELSE Oper$ = Oper$ + CalcPart$
 END IF
END IF
RETURN

ShowCalc:
IF Oper$(CalcOper) = "" THEN Oper$(CalcOper) = "0"
IF CalcOper = 0 OR CalcSolv THEN
 COLOR 7, 0
 IF CalcSolv THEN
  IF LastCalc = 0 THEN PRINT : LOCATE , 2: PRINT LEFT$(Operator$ + " " + OperatorName$ + " " + Oper$(1) + SPACE$(12), 23) ELSE PRINT
  PRINT STRING$(24, "Ä"): LastCalc = 0
 END IF
 Oper$ = Oper$(0)
 IF CalcOperNew THEN COLOR 0, 7
 LOCATE , 8: PRINT LEFT$(Oper$, CalcDegr); TAB(30); Bin$(Oper$);
END IF
IF CalcOper = 1 THEN
 COLOR 7, 0
 IF (LastCalc = 0) OR CalcSolv THEN PRINT : LastCalc = 1
 LOCATE , 2: PRINT LEFT$(Operator$ + " " + OperatorName$, 5); " ";
 Oper$ = Oper$(1)
 IF CalcOperNew THEN COLOR 0, 7
 LOCATE , 8: PRINT LEFT$(Oper$, CalcDegr); TAB(30); Bin$(Oper$);
END IF

RETURN

OverFlowErr:
SOUND 1024, 1
Oper$(0) = "0"
RESUME NEXT

'Used for returning the string of a number in binary. (13-->1011) Note that
'this returns it in little endian format (for easier reading) meaning that
'the lowest bits are on the left and the they grow higher to the right.
'Surprised that Qbasic does not have its own native function for something
'like this, even though they have OCT$ and HEX$.
FUNCTION Bin$ (Number$)
  IF (LEN(Number$) = 10 AND Number$ > "2147483647") OR LEN(Number$) > 10 THEN
    Number& = VAL(RIGHT$(Number$, 9))
  ELSE Number& = VAL(Number$)
  END IF
 
  Text$ = STRING$(15, 48)
  bitmask = 16384
  FOR count = 1 TO 15
    IF Number& AND bitmask THEN MID$(Text$, count) = "1"
    bitmask = bitmask \ 2
  NEXT count
  Bin$ = Text$
END FUNCTION

FUNCTION Math$ (Oper1$, Oper2$, Operator$)
ON ERROR GOTO OverFlowErr
Oper1# = VAL(Oper1$)
Oper2# = VAL(Oper2$)
CalcSolv = 1
SELECT CASE Operator$
CASE "+": Rslt# = Oper1# + Oper2#
CASE "-": Rslt# = Oper1# - Oper2#
CASE "*": Rslt# = Oper1# * Oper2#
CASE "ö": Rslt# = Oper1# / Oper2#
CASE "": Rslt# = Oper1# - (Oper2# * INT(Oper1# / Oper2#))
CASE "û": Rslt# = Oper1# ^ Oper2#
CASE "@": Rslt# = Oper1# OR Oper2#
CASE "&": Rslt# = Oper1# AND Oper2#
CASE "!": Rslt# = Oper1# XOR Oper2#
CASE "#": Rslt# = Oper1# EQV Oper2#
CASE ELSE: Rslt# = Oper1#: CalcSolv = 0
END SELECT
Math$ = LTRIM$(STR$(Rslt#))
ON ERROR GOTO 0
END FUNCTION

