DEFINT A-Z
DECLARE SUB LineBreak (Text$)
DECLARE FUNCTION Math$ (Oper1$, Oper2$, Operator$)
SCREEN 0: WIDTH 80, 25: v = CSRLIN: h = POS(0): VIEW PRINT 1 TO 25: LOCATE v, h, , 14, 15
PRINT : LineBreak " Simple Calculator Ä 1.1 ": PRINT

DIM SHARED Oper$(0 TO 2), Operator$, Operators$, OperatorNames$, CalcDegr
Operators$ = "+-*öû#!&@"
OperatorNames$ = "AddSubMulDivModExpOr XorAndEqv"
OptrName$ = "Nul"
CalcDegr = 16

GOSUB ShowCalc

GetKey:
DO
Kbrd$ = INKEY$
IF LEN(Kbrd$) > 0 THEN
 SELECT CASE Kbrd$
 CASE "": EXIT DO
 CASE "	": CalcMode = CalcMode XOR -1: IF CalcMode = 0 THEN ShowOptr = 1
 CASE CHR$(0) + ";"
  ON ERROR GOTO HlpFileHan: HelpErr = 0
  OPEN "SIMCALC.HLP" FOR INPUT AS #1
  PRINT CHR$(13)
  IF HelpErr THEN
   PRINT "Cannot find help file? SIMCALC.HLP"
  ELSE
   LineBreak "": a = 0
   WHILE NOT EOF(1)
    LINE INPUT #1, a$: a = a + 1
    IF INSTR(a$, "Ä") THEN COLOR 0, 7 ELSE COLOR 7, 0
    PRINT a$;
    IF a >= 24 THEN WHILE INKEY$ = "": WEND: a = 0
    COLOR , 0: PRINT
   WEND
   LineBreak ""
  END IF
  CLOSE #1
  PRINT
 CASE IS < "ÿ"
  IF CalcMode THEN
   SELECT CASE Kbrd$
   CASE CHR$(13)
    PRINT : CalcOperand = 0: FOR AddItUp = 1 TO LEN(KbrdList$): CalcPart$ = MID$(KbrdList$, AddItUp, 1): GOSUB EditCalc: GOSUB ShowCalc: NEXT AddItUp: PRINT
   CASE ""
    IF LEN(KbrdList$) > 0 THEN KbrdList$ = LEFT$(KbrdList$, LEN(KbrdList$) - 1)
   CASE CHR$(127)
    KbrdList$ = ""
   CASE IS > CHR$(31)
    IF LEN(KbrdList$) < 64 THEN KbrdList$ = KbrdList$ + Kbrd$
   END SELECT
  ELSE
   CalcPart$ = Kbrd$: GOSUB EditCalc
  END IF
 END SELECT
 IF CalcMode THEN LOCATE , 1: PRINT LEFT$(KbrdList$ + SPACE$(64), 64);  ELSE GOSUB ShowCalc
END IF
LOOP
COLOR 7, 0
SYSTEM

EditCalc:
Oper$ = Oper$(CalcOperand): CalcPart$ = UCASE$(CalcPart$)
SELECT CASE CalcPart$
CASE "0" TO "9", ".": GOSUB AddToOper: Oper$(CalcOperand) = Oper$
CASE "+", "-", "*", "/", "\", "^", "#", "!", "&", "@"
 IF CalcOperand THEN
  Oper$(2) = LEFT$(Math$(Oper$(0), Oper$(1), Operator$), CalcDegr)
  CalcOperand = 2: GOSUB ShowCalc
  Oper$(0) = Oper$(2)
  ShowNewEqua = 1
  CalcOperand = 1
  ShowOptr = 1
 ELSE
  Oper$(0) = Oper$
  ShowOptr = 1
  CalcOperand = 1
 END IF
 OperandLit = 1
 Operator$ = MID$(Operators$, INSTR("+-*/\^#!&@", CalcPart$), 1)
 OptrName$ = MID$(OperatorNames$, (INSTR(Operators$, Operator$) - 1) * 3 + 1, 3)
CASE "Q", "I"
 SELECT CASE CalcPart$
 CASE "Q": Oper$(CalcOperand) = LEFT$(Math$(Oper$, ".5", "û"), CalcDegr)
 CASE "I": IF INSTR(Oper$, ".") THEN Oper$(CalcOperand) = LEFT$(Oper$, INSTR(Oper$, ".") - 1)
 END SELECT
 OperandLit = 0
CASE "=", CHR$(13)
 Oper$(2) = LEFT$(Math$(Oper$(0), Oper$(1), Operator$), CalcDegr)
 CalcOperand = 2: GOSUB ShowCalc
 Oper$(0) = Oper$(2)
 ShowNewEqua = 1
 CalcOperand = 0
 OperandLit = 1
CASE "_": OperandLit = 0: IF LEFT$(Oper$, 1) = "-" THEN Oper$(CalcOperand) = RIGHT$(Oper$, LEN(Oper$) - 1) ELSE Oper$(CalcOperand) = "-" + Oper$
CASE ";": OperandLit = 0
CASE "": IF Oper$ > "" THEN Oper$(CalcOperand) = LEFT$(Oper$, LEN(Oper$) - 1): OperandLit = 0
CASE ""
 IF CalcOperand THEN
  OperandLit = 0
 ELSE
  Oper$(0) = "": Oper$(1) = "": Operator$ = "":
 END IF
 CalcOperand = 0
 ShowNewEqua = 1
CASE "M": MemOper$ = Oper$
CASE "R": Oper$(CalcOperand) = MemOper$
END SELECT
RETURN

AddToOper:
IF OperandLit THEN
 Oper$ = CalcPart$: OperandLit = 0
ELSEIF LEN(Oper$) < CalcDegr THEN
 IF CalcPart$ = "." THEN
  IF INSTR(Oper$, ".") = 0 THEN Oper$ = Oper$ + CalcPart$
 ELSE
  IF Oper$ = "0" THEN Oper$ = CalcPart$ ELSE Oper$ = Oper$ + CalcPart$
 END IF
END IF
RETURN

ShowCalc:
COLOR 7, 0
IF ShowNewEqua THEN
 LOCATE , 1: PRINT SPACE$(CalcDegr + 10 + CalcDegr);
 ShowNewEqua = 0
END IF
IF Oper$(CalcOperand) = "" THEN Oper$(CalcOperand) = "0"
IF Oper$(CalcOperand) = "." THEN Oper$(CalcOperand) = "0."
IF CalcOperand = 0 THEN
 LOCATE , 8: PRINT SPACE$(CalcDegr);
 IF OperandLit THEN COLOR 0, 7
 LOCATE , 8: PRINT LEFT$(Oper$(0), CalcDegr);
ELSEIF CalcOperand = 1 THEN
 IF ShowOptr THEN LOCATE , 2: PRINT OptrName$; "   "; Oper$(0); " "; Operator$; : ShowOptr = 0
 CalcOperOfset = LEN(OptrName$ + Oper$(0) + Operator$) + 7
 LOCATE , CalcOperOfset: PRINT SPACE$(CalcDegr);
 IF OperandLit THEN COLOR 0, 7
 LOCATE , CalcOperOfset: PRINT LEFT$(Oper$(1), CalcDegr);
ELSEIF CalcOperand = 2 THEN
 LOCATE , 2: PRINT OptrName$; "   "; Oper$(0); " "; Operator$; " "; Oper$(1); " = "; Oper$(2); SPACE$(12)
END IF

COLOR 7, 0
RETURN

OverFlowErr:
SOUND 1024, 1
Oper$(0) = "0"
RESUME NEXT

HlpFileHan:
HelpErr = 1
RESUME NEXT

SUB LineBreak (Text$)
MaxLen = LEN(Text$)
IF MaxLen > 68 THEN MaxLen = 68
PRINT "ÄÄÄÄÄÄ"; LEFT$(Text$, MaxLen); STRING$(74 - MaxLen, 196)
END SUB

FUNCTION Math$ (Oper1$, Oper2$, Operator$)
ON ERROR GOTO OverFlowErr
Oper1# = VAL(Oper1$)
Oper2# = VAL(Oper2$)
SELECT CASE Operator$
CASE "+": Rslt# = Oper1# + Oper2#
CASE "-": Rslt# = Oper1# - Oper2#
CASE "*": Rslt# = Oper1# * Oper2#
CASE "ö": Rslt# = Oper1# / Oper2#
CASE "": Rslt# = Oper1# - (Oper2# * INT(Oper1# / Oper2#))
CASE "û": Rslt# = Oper1# ^ Oper2#
CASE "#": Rslt# = Oper1# OR Oper2#
CASE "@": Rslt# = Oper1# EQV Oper2#
CASE "&": Rslt# = Oper1# AND Oper2#
CASE "!": Rslt# = Oper1# XOR Oper2#
CASE ELSE: Rslt# = Oper1#
END SELECT
Math$ = LTRIM$(STR$(Rslt#))
ON ERROR GOTO 0
END FUNCTION

