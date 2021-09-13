'1998-10-19

'This is a two step numeric string compiler that turns a string mathematical
'expression into a basic set of variable references and 'opcodes'.
'It is very simple, only able to do addition, subtraction, multiplication,
'and division, but it might give an idea of how to do something more
'advanced. After making this one of my own, I definitely have more respect
'for Qbasic's parser.

'It includes a graphics mode that using a formula and the variables ys and xs
'will display a line, curve, or whatever comes up. Ys and xs are used to
'curve the, so that very large values will still show up on the screen. Note
'that the way values are assigned will seem a bit mixed up. For the sake of
'simplicity, it actually assigns to the right. So to yscale (ys) to 2.5, you
'would write 2.5=ys. It is also possible to assign a variable a value in the
'middle of an expression. For example (180 \ 3.14159 = con) * deg = rad.
'Since it only executes that last expression, each one being separated by a
'semicolon, it is possible to set constant values before it, such as
'3.14159 = pi; deg * 180 \ pi = rad.

'It is a two step process
'  1. The first step parses the string into all of its parts indentifying
'  each piece as it procedes left to right.
'  It is responsible for allocating variables, defining constants, counting
'  parenthesis, and translating ASCII operators into little codes.
'  It is also responsible for detecting syntax errors before passing anything
'  onto the second phase.
'  2. The second step simply reorganizes the codes by parenthetical order
'  so that the correct result comes out when executed
'
'  Even complex equations are sorted out with ease (ya right!)

DEFINT A-Z
OPTION BASE 0

DECLARE SUB GetVariable (Var$, Index)
DECLARE SUB GetConstant (Value#, Index)
DECLARE SUB ClearMathDataSpace ()
DECLARE SUB CompileExpression (Expression$, ErrorPos)
DECLARE SUB EndProgram ()
DECLARE SUB PromptText (Text$, Attrs AS ANY, Key$)
DECLARE SUB PromptMake (Attrs AS ANY, Csr, Lim, Row, Col)
DECLARE SUB WaitForExpression ()
DECLARE SUB SilentExecuteMath ()
DECLARE SUB ClearMathConstants ()
DECLARE SUB ExecuteExpression ()
DECLARE SUB CompileExprLine (Expression$, ErrorPos, SilentCompile)
DECLARE SUB SilentCompileExpr (Expression$, ErrorPos)
DECLARE SUB SilentExecuteExpr ()
DECLARE SUB CompileExprError (ErrorNum, ErrorPos)
DECLARE SUB ClearScreenWindow ()
DECLARE SUB PrintMathOperation (MathCode)
DECLARE SUB PrintAllVariables ()
DECLARE FUNCTION StrTrim$ (Num%)

CONST ExprSav = 0, ExprOpen = 1, ExprAdd = 2, ExprSub = 3, ExprMul = 4
CONST ExprDiv = 5, ExprNeg = 6, ExprAsn = 7, ExprClose = 8, ExprSep = 9
CONST ExprSet = 10

'variable names can be longer than a single character.
'they can include numbers after and in the name but must start with a letter.
'they are case insensitive (hypotenuse2=HYPOtenuSe2).

TYPE PromptAttrsType
Csr AS INTEGER 'cursor position in text
Lim AS INTEGER 'maximum characters limit
Row AS INTEGER 'screen row
Col AS INTEGER 'screen col
Change AS INTEGER 'flag whether a change has occurred
END TYPE

TYPE RegisterType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Flags AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

TYPE MathCodesType
Operation AS INTEGER
Parameter AS INTEGER
END TYPE

TYPE MathDataSpaceType
Value AS DOUBLE         'double precision numeric value
State AS INTEGER        'whether element is free or used, variable or constant
END TYPE

DIM SHARED Regs AS RegisterType, GraphicsMode, MousePresent
DIM SHARED ExprPrompt AS PromptAttrsType, ExprText$
DIM SHARED ExprCodes(31) AS MathCodesType, ExprCodesTotal, ExprData(31) AS MathDataSpaceType
DIM SHARED ExprVars$(31), ExprVarsPtrs(31), ExprStack(31) AS DOUBLE

SCREEN 0: WIDTH 80, 25: VIEW PRINT 1 TO 25: CLS : LOCATE , , , 12, 13

LOCATE 2, 1
PRINT "Pres Enter to see the steps as the expression is parsed,"
PRINT "Ctrl+Enter to execute the expression and see the variable values,"
PRINT "Or Tab to switch to graphics mode and graph the equation."
PRINT "While in graphics mode, you can move the mouse around to get the value of x."

'ExprText$ = "97 = y; 320 = b; 12 * (6 + y) / (100 - y) = x; 2301 + (x * (x - b) = z) = w"
'ExprText$ = "256=b; 97=y; 12*(b-107+(x*y))=x; x=w +12=z"
'ExprText$ = "329 + (45 - 5) * dkfs"
'ExprText$ = "1=s; y+(y*(100-y/120.71069))=x"
'ExprText$ = "7*3-(8+(9/(3))-2)+1"

ExprText$ = ".00416666667=ys; 700=xs; y-(y*y*y)=x"

WaitForExpression

EndProgram

SUB ClearMathConstants

FOR Index = 0 TO 31
  IF ExprData(Index).State <> 3 THEN ExprData(Index).State = 0
NEXT Index

END SUB

SUB ClearMathDataSpace

FOR Index = 0 TO 31
  ExprData(Index).State = 0
  ExprVars$(Index) = ""
NEXT Index

END SUB

SUB ClearScreenWindow

IF GraphicsMode THEN LINE (0, 16)-(639, 479), 0, BF: LOCATE 2, 1 ELSE CLS

END SUB

SUB CompileExprError (ErrorNum, ErrorPos)
 
SELECT CASE ErrorNum
CASE 0: Text$ = "Closing parenthesis without opening"
CASE 1: Text$ = "Operation was not closed with parenthesis"
CASE 2: Text$ = "Unrecognised operator character"
CASE 3: Text$ = "Number, variable or expression expected"
CASE 4: Text$ = "Operation was not completed before ending"
CASE 5: Text$ = "Operator is expected between expressions"
CASE 6: Text$ = "Assignment must point to a variable"
END SELECT

LOCATE , 1: COLOR 12
PRINT "Error"; ErrorNum; "while compiling, at character"; ErrorPos; TAB(80);
PRINT Text$; TAB(80);

END SUB

SUB CompileExpression (Expression$, ErrorPos)

REDIM ExprTempCodes(127) AS INTEGER, ExprTempStack(31, 1) AS INTEGER

COLOR 1: ClearScreenWindow
PRINT "--Parsing--"

OperandNext = -1: CharPtr = 1
ExprTempCodesTotal = 0
DO UNTIL CharPtr > LEN(Expression$)
  'get first character and decide whether it is a variable or number
  Char$ = MID$(Expression$, CharPtr, 1)
  IF Char$ = " " THEN CharPtr = CharPtr + 1: GOTO EndOfLoop
 
  SELECT CASE UCASE$(Char$)
  CASE "0" TO "9", ".": ElementFound = 0'a numeric constant
  CASE "A" TO "Z": ElementFound = 1 'variable name
  CASE "(": ElementFound = 2        'opening parenthesis
  CASE ")": ElementFound = 3        'closing parenthesis
  CASE ELSE: ElementFound = 4       'operation assumed
  END SELECT
 
  IF OperandNext THEN
    SELECT CASE ElementFound
    CASE 0
      GOSUB GetExprConstant
      GOSUB SetExprIndent
      Value# = VAL(Char$)
      GetConstant Value#, Index
      PRINT "Get constant #"; StrTrim(Index); " ("; Char$; ")"
      TempCode = ExprSav: GOSUB PushExprTempCode
      TempCode = Index: GOSUB PushExprTempCode
      OperandNext = 0
    CASE 1
      GOSUB GetExprVariable
      GOSUB SetExprIndent
      GetVariable Char$, Index
      PRINT "Get variable #"; StrTrim(Index); " ("; Char$; ")"
      TempCode = ExprSav: GOSUB PushExprTempCode
      TempCode = Index: GOSUB PushExprTempCode
      OperandNext = 0
    CASE 2
      GOSUB SetExprIndent
      PRINT "Open expression"
      ParenthesisLevel = ParenthesisLevel + 1
      TempCode = ExprOpen: GOSUB PushExprTempCode
    CASE 3
      IF ParenthesisLevel < 1 THEN ErrorNum = 0: GOTO CompileError
      ErrorNum = 4: GOTO CompileError
    CASE 4
      ErrorNum = 3: GOTO CompileError
    END SELECT
  ELSE
    SELECT CASE ElementFound
    CASE 0, 1, 2: ErrorNum = 5: GOTO CompileError
    CASE 3
      IF ParenthesisLevel < 1 THEN ErrorNum = 0: GOTO CompileError
      ParenthesisLevel = ParenthesisLevel - 1
      GOSUB SetExprIndent
      PRINT "Close expression"
      TempCode = ExprClose: GOSUB PushExprTempCode
    CASE 4
      GOSUB SetExprIndent
      SELECT CASE Char$
      CASE "+": PRINT "Add"
        TempCode = ExprAdd
      CASE "-": PRINT "Subtract"
        TempCode = ExprSub
      CASE "*": PRINT "Multiply"
        TempCode = ExprMul
      CASE "/": PRINT "Divide"
        TempCode = ExprDiv
      CASE "=": PRINT "Assign"
        TempCode = ExprAsn
      CASE ",": PRINT "Separator"
        TempCode = ExprSep
      CASE ELSE
        ErrorNum = 2: GOTO CompileError
      END SELECT
      GOSUB PushExprTempCode
      OperandNext = 1
    END SELECT
  END IF
  CharPtr = CharPtr + 1

EndOfLoop:
LOOP

IF ParenthesisLevel THEN ErrorNum = 1: GOTO CompileError
IF OperandNext > 0 THEN ErrorNum = 4: GOTO CompileError
ErrorPos = 0

DO: LOOP UNTIL LEN(INKEY$)
COLOR 9: ClearScreenWindow
PRINT "--Rearranging--"

ExprTempStackTotal = 0
ExprCodesTotal = 0
ParenthesisLevel = 0
NewOperator = 1
FOR CharPtr = 0 TO ExprTempCodesTotal - 1
  MathCode = ExprTempCodes(CharPtr)
  SELECT CASE MathCode
  CASE ExprSav
    PRINT "GET, output ";
    IF NewOperator THEN MathCode = ExprSet: NewOperator = 0: PRINT "GET";  ELSE PRINT "SAVE&GET";
    MathParm = ExprTempCodes(CharPtr + 1): GOSUB PushExprCode
    PRINT MathParm
    CharPtr = CharPtr + 1
  CASE ExprAdd, ExprSub, ExprMul, ExprDiv, ExprAsn
    PrintMathOperation MathCode
    PRINT ", following operand is ";
    IF ExprTempCodes(CharPtr + 1) = ExprSav THEN
      PRINT "simple, output ";
      PrintMathOperation MathCode
      MathParm = ExprTempCodes(CharPtr + 2): GOSUB PushExprCode
      PRINT MathParm
      'IF ExprData(MathParm).State <> 3 THEN ErrorNum = 6: GOSUB CompileError
      CharPtr = CharPtr + 2
    ELSE 'IF MathCode <> ExprAsn THEN
      PRINT "complex, saving operation";
      IF ExprTempStackTotal >= 31 THEN ERROR 200
      ExprTempStack(ExprTempStackTotal, 0) = MathCode
      ExprTempStack(ExprTempStackTotal, 1) = ParenthesisLevel
      ExprTempStackTotal = ExprTempStackTotal + 1
      PRINT " (stack:"; StrTrim(ExprTempStackTotal); ")"
    'ELSE ErrorNum = 6: GOSUB CompileError
    END IF
  CASE ExprOpen
    ParenthesisLevel = ParenthesisLevel + 1
    'push current math code onto stack
    PRINT "OPEN, opening expression parenthesis (depth:"; StrTrim(ParenthesisLevel); ")"
  CASE ExprClose
    ParenthesisLevel = ParenthesisLevel - 1
    PRINT "CLOSE, closing parenthesis (depth:"; StrTrim(ParenthesisLevel); ")"
    IF ExprTempStackTotal THEN
      IF ParenthesisLevel <= ExprTempStack(ExprTempStackTotal - 1, 1) THEN
        ExprTempStackTotal = ExprTempStackTotal - 1
        PRINT "  output saved operation (stack:"; StrTrim(ExprTempStackTotal); "), ";
        MathCode = ExprTempStack(ExprTempStackTotal, 0): MathParm = 255
        GOSUB PushExprCode
        PrintMathOperation MathCode
        PRINT " -1 (use stack for source)"
      END IF
    END IF
  CASE ExprSep: NewOperator = 1
  END SELECT
NEXT CharPtr

DO: LOOP UNTIL LEN(INKEY$)

EXIT SUB

GetExprConstant:
  NextCharPtr = CharPtr
  DecimalPoint = 0
  FOR NextCharPtr = CharPtr + 1 TO LEN(Expression$)
    Char = ASC(MID$(Expression$, NextCharPtr, 1))
    IF (Char < 48 OR Char > 57) AND Char <> 46 THEN EXIT FOR ELSE IF Char = 46 THEN IF DecimalPoint THEN EXIT FOR ELSE DecimalPoint = 1
  NEXT NextCharPtr
  Char$ = MID$(Expression$, CharPtr, NextCharPtr - CharPtr)
  CharPtr = NextCharPtr - 1
RETURN

GetExprVariable:
  NextCharPtr = CharPtr
  FOR NextCharPtr = CharPtr + 1 TO LEN(Expression$)
    Char = ASC(UCASE$(MID$(Expression$, NextCharPtr, 1)))
    IF (Char < 48 OR Char > 57) AND (Char < 65 OR Char > 90) THEN EXIT FOR
  NEXT NextCharPtr
  Char$ = MID$(Expression$, CharPtr, NextCharPtr - CharPtr)
  CharPtr = NextCharPtr - 1
RETURN

SetExprIndent:
  LOCATE , ParenthesisLevel * 2 + 1
RETURN

PushExprTempCode:
  IF ExprTempCodesTotal > 127 THEN ERROR 200
  ExprTempCodes(ExprTempCodesTotal) = TempCode
  ExprTempCodesTotal = ExprTempCodesTotal + 1
RETURN

PushExprCode:
  IF ExprCodesTotal > 31 THEN ERROR 200
  ExprCodes(ExprCodesTotal).Operation = MathCode
  ExprCodes(ExprCodesTotal).Parameter = MathParm
  ExprCodesTotal = ExprCodesTotal + 1
RETURN

CompileError:
  ErrorPos = CharPtr
  CompileExprError ErrorNum, ErrorPos
'in a time long ago, a terrible disaster was prevented by discovering passion
'winds from the cold north were tormenting the peaceful people
'all they could do was stay inside and as dress warmly as possible
'never before had such a chill been felt in this normally tropical land
'this was not acceptable as crops were dying and people were starving
'so king xenefre had a contest to see who could make the largest fire
'everyone tried but there was one that burned brighter than any other
'xenefre's rewarded the young loving couple for bringing warmth to the land

END SUB

SUB CompileExprLine (Expression$, ErrorPos, SilentCompile)

ClearMathDataSpace
VIEW PRINT 2 TO 25
IF GraphicsMode = 0 THEN COLOR , 0: LOCATE , , 0

CharPtr = 1
DO
  NextCharPtr = INSTR(CharPtr, Expression$, ";")
  IF NextCharPtr THEN ExprPart$ = MID$(Expression$, CharPtr, NextCharPtr - CharPtr) ELSE ExprPart$ = MID$(Expression$, CharPtr)
  IF SilentCompile THEN SilentCompileExpr ExprPart$, ErrorPos ELSE CompileExpression ExprPart$, ErrorPos
  IF ErrorPos THEN ErrorPos = ErrorPos + CharPtr - 1: EXIT DO
  IF SilentCompile THEN SilentExecuteExpr ELSE ExecuteExpression
  ClearMathConstants
  IF NextCharPtr THEN CharPtr = NextCharPtr + 1 ELSE EXIT DO
  IF NOT SilentCompile THEN DO: LOOP UNTIL LEN(INKEY$)
LOOP

Row = CSRLIN: Col = POS(0)
VIEW PRINT
LOCATE Row, Col

END SUB

SUB EndProgram

SCREEN 0: COLOR 7, 0: CLS
END

END SUB

SUB ExecuteExpression

COLOR 5: ClearScreenWindow
PRINT "--Executing final form--"

Accumalator# = 0
FOR CharPtr = 0 TO ExprCodesTotal - 1
  MathCode = ExprCodes(CharPtr).Operation
  PrintMathOperation MathCode
  MathParm = ExprCodes(CharPtr).Parameter
  IF MathParm < 255 THEN
    IF ExprData(MathParm).State AND 2 THEN PRINT " variable";  ELSE PRINT " constant";
    PRINT " #"; StrTrim(MathParm);
    Operand# = ExprData(MathParm).Value
  ELSE
    PRINT " saved value with accumalator";
    IF ExprStackTotal <= 0 THEN ERROR 200
    ExprStackTotal = ExprStackTotal - 1
    Operand# = Accumalator#
    Accumalator# = ExprStack(ExprStackTotal)
  END IF
  GOSUB ExecuteOperation
NEXT CharPtr

EXIT SUB

ExecuteOperation:
  PreAccumalator# = Accumalator#
  SELECT CASE MathCode
  CASE ExprSav
    IF ExprStackTotal >= 31 THEN ERROR 200
    ExprStack(ExprStackTotal) = Accumalator#
    ExprStackTotal = ExprStackTotal + 1
    Accumalator# = Operand#
  CASE ExprSet: Accumalator# = Operand#
  CASE ExprAdd: Accumalator# = Accumalator# + Operand#: Char$ = "+"
  CASE ExprSub: Accumalator# = Accumalator# - Operand#: Char$ = "-"
  CASE ExprMul: Accumalator# = Accumalator# * Operand#: Char$ = "*"
  CASE ExprDiv: Accumalator# = Accumalator# / Operand#: Char$ = "/"
  CASE ExprAsn: IF MathParm < 32 THEN ExprData(MathParm).Value = Accumalator#
  END SELECT
  PRINT TAB(39);
  IF MathCode <> ExprSet AND MathCode <> ExprSav AND MathCode <> ExprAsn THEN
    PRINT PreAccumalator#; Char$; Operand#; "="; Accumalator#
  ELSE
    PRINT Accumalator#
  END IF
RETURN

END SUB

SUB GetConstant (Value#, Index)
'simply looks for an empty spot to place a constant value and returns its
'index in ExprData.

FOR Index = 0 TO 31
  IF ExprData(Index).State = 0 THEN ExprData(Index).Value = Value#: ExprData(Index).State = 1: EXIT FOR
NEXT Index

END SUB

SUB GetVariable (Var$, Index)
'searches through the variable list for one matching Var$. if found, it simply
'returns its index in ExprData. otherwise it allocates a spot for it and
'returns the new index, assuming there is space to.

FOR Temp = 0 TO 31
  IF MID$(ExprVars$(Temp), 2) = Var$ THEN ElementFound = 1: EXIT FOR
NEXT Temp

IF ElementFound THEN
  Index = ASC(LEFT$(ExprVars$(Temp), 1))
ELSE
  ElementFound = 0
  FOR Index = 0 TO 31
    IF ExprData(Index).State = 0 THEN ElementFound = 1: EXIT FOR
  NEXT Index
  IF ElementFound THEN
    ExprData(Index).Value = 0
    ExprData(Index).State = 3
    ElementFound = 0
    FOR Temp = 0 TO 31
      IF LEN(ExprVars$(Temp)) = 0 THEN ElementFound = 1: EXIT FOR
    NEXT Temp
    IF ElementFound THEN ExprVars$(Temp) = CHR$(Index) + Var$ ELSE ERROR 200
  ELSE ERROR 200
  END IF
END IF

END SUB

SUB PrintAllVariables

FOR Temp = 0 TO 31
  Temp$ = MID$(ExprVars$(Temp), 2)
  IF LEN(Temp$) = 0 THEN EXIT FOR
  Index = ASC(LEFT$(ExprVars$(Temp), 1))
  PRINT Temp$ + "=" + LTRIM$(STR$(ExprData(Index).Value)); " ";
NEXT Temp

END SUB

SUB PrintMathOperation (MathCode)

SELECT CASE MathCode
CASE ExprSav: PRINT "SAVE&GET";
CASE ExprSet: PRINT "GET";
CASE ExprAdd: PRINT "ADD";
CASE ExprSub: PRINT "SUBTRACT";
CASE ExprMul: PRINT "MULTIPLY";
CASE ExprDiv: PRINT "DIVIDE";
CASE ExprAsn: PRINT "ASSIGN";
END SELECT

END SUB

SUB PromptMake (Attrs AS PromptAttrsType, Csr, Lim, Row, Col)

Attrs.Csr = Csr
Attrs.Lim = Lim
Attrs.Row = Row
Attrs.Col = Col
Attrs.Change = 1

END SUB

SUB PromptText (Text$, Attrs AS PromptAttrsType, Key$)

TxtLen = LEN(Text$)
SELECT CASE Key$
CASE " " TO "ÿ": IF TxtLen < Attrs.Lim THEN Text$ = LEFT$(Text$, Attrs.Csr) + Key$ + MID$(Text$, Attrs.Csr + 1): Attrs.Csr = Attrs.Csr + 1: Change = 3
CASE "": IF Attrs.Csr > 0 THEN Text$ = LEFT$(Text$, Attrs.Csr - 1) + MID$(Text$, Attrs.Csr + 1): Attrs.Csr = Attrs.Csr - 1: Change = 3
CASE CHR$(0) + "K": IF Attrs.Csr > 0 THEN Attrs.Csr = Attrs.Csr - 1: Change = 1
CASE CHR$(0) + "M": IF Attrs.Csr < TxtLen THEN Attrs.Csr = Attrs.Csr + 1: Change = 1
CASE CHR$(0) + "S": IF Attrs.Csr < TxtLen THEN Text$ = LEFT$(Text$, Attrs.Csr) + MID$(Text$, Attrs.Csr + 2): Change = 3
CASE CHR$(0) + "G": Attrs.Csr = 0: Change = 1
CASE CHR$(0) + "O": Attrs.Csr = TxtLen: Change = 1
END SELECT

IF Change THEN Attrs.Change = Attrs.Change OR Change
IF Attrs.Change THEN
  LOCATE Attrs.Row, Attrs.Col, 0
  IF GraphicsMode THEN COLOR 15 ELSE COLOR 15, 1
  PRINT Text$;
  Temp = Attrs.Lim - LEN(Text$)
  IF Temp > 0 THEN PRINT SPACE$(Temp);
  IF Attrs.Csr < Attrs.Lim THEN
    IF GraphicsMode THEN Col = (Attrs.Col + Attrs.Csr - 1) * 8: Row = Attrs.Row * 16 - 1: LINE (Col, Row - 1)-(Col + 7, Row), 15, BF ELSE LOCATE Attrs.Row, Attrs.Col + Attrs.Csr, 1
  END IF
  Attrs.Change = Attrs.Change AND -2
END IF

END SUB

SUB SilentCompileExpr (Expression$, ErrorPos)

REDIM ExprTempCodes(127) AS INTEGER, ExprTempStack(31, 1) AS INTEGER

OperandNext = -1: CharPtr = 1
ExprTempCodesTotal = 0
DO UNTIL CharPtr > LEN(Expression$)
  Char$ = MID$(Expression$, CharPtr, 1)
  IF Char$ = " " THEN CharPtr = CharPtr + 1: GOTO EndOfSilentCompileLoop

  SELECT CASE UCASE$(Char$)
  CASE "0" TO "9", ".": ElementFound = 0'a numeric constant
  CASE "A" TO "Z": ElementFound = 1 'variable name
  CASE "(": ElementFound = 2        'opening parenthesis
  CASE ")": ElementFound = 3        'closing parenthesis
  CASE ELSE: ElementFound = 4       'operation assumed
  END SELECT

  IF OperandNext THEN
    SELECT CASE ElementFound
    CASE 0
      GOSUB GetSlntExprConstant
      Value# = VAL(Char$)
      GetConstant Value#, Index
      TempCode = ExprSav: GOSUB PushSlntExprTempCode
      TempCode = Index: GOSUB PushSlntExprTempCode
      OperandNext = 0
    CASE 1
      GOSUB GetSlntExprVariable
      GetVariable Char$, Index
      TempCode = ExprSav: GOSUB PushSlntExprTempCode
      TempCode = Index: GOSUB PushSlntExprTempCode
      OperandNext = 0
    CASE 2
      ParenthesisLevel = ParenthesisLevel + 1
      TempCode = ExprOpen: GOSUB PushSlntExprTempCode
    CASE 3
      IF ParenthesisLevel < 1 THEN ErrorNum = 0: GOTO CompileSlntError
      ErrorNum = 4: GOTO CompileSlntError
    CASE 4
      ErrorNum = 3: GOTO CompileSlntError
    END SELECT
  ELSE
    SELECT CASE ElementFound
    CASE 0, 1, 2: ErrorNum = 5: GOTO CompileSlntError
    CASE 3
      IF ParenthesisLevel < 1 THEN ErrorNum = 0: GOTO CompileSlntError
      ParenthesisLevel = ParenthesisLevel - 1
      TempCode = ExprClose: GOSUB PushSlntExprTempCode
    CASE 4
      SELECT CASE Char$
      CASE "+": TempCode = ExprAdd
      CASE "-": TempCode = ExprSub
      CASE "*": TempCode = ExprMul
      CASE "/": TempCode = ExprDiv
      CASE "=": TempCode = ExprAsn
      CASE ",": TempCode = ExprSep
      CASE ELSE: ErrorNum = 2: GOTO CompileSlntError
      END SELECT
      GOSUB PushSlntExprTempCode
      OperandNext = 1
    END SELECT
  END IF
  CharPtr = CharPtr + 1

EndOfSilentCompileLoop:
LOOP

IF ParenthesisLevel THEN ErrorNum = 1: GOTO CompileSlntError
IF OperandNext > 0 THEN ErrorNum = 4: GOTO CompileSlntError
ErrorPos = 0

ExprTempStackTotal = 0
ExprCodesTotal = 0
ParenthesisLevel = 0
NewOperator = 1
FOR CharPtr = 0 TO ExprTempCodesTotal - 1
  MathCode = ExprTempCodes(CharPtr)
  SELECT CASE MathCode
  CASE ExprSav
    IF NewOperator THEN MathCode = ExprSet: NewOperator = 0
    MathParm = ExprTempCodes(CharPtr + 1): GOSUB PushSlntExprCode
    CharPtr = CharPtr + 1
  CASE ExprAdd, ExprSub, ExprMul, ExprDiv, ExprAsn
    IF ExprTempCodes(CharPtr + 1) = ExprSav THEN
      MathParm = ExprTempCodes(CharPtr + 2): GOSUB PushSlntExprCode
      CharPtr = CharPtr + 2
    ELSE 'IF MathCode <> ExprAsn THEN
      IF ExprTempStackTotal >= 31 THEN ERROR 200
      ExprTempStack(ExprTempStackTotal, 0) = MathCode
      ExprTempStack(ExprTempStackTotal, 1) = ParenthesisLevel
      ExprTempStackTotal = ExprTempStackTotal + 1
    'ELSE ErrorNum = 6: GOSUB CompileError
    END IF
  CASE ExprOpen
    ParenthesisLevel = ParenthesisLevel + 1
  CASE ExprClose
    ParenthesisLevel = ParenthesisLevel - 1
    IF ExprTempStackTotal THEN
      IF ParenthesisLevel <= ExprTempStack(ExprTempStackTotal - 1, 1) THEN
        ExprTempStackTotal = ExprTempStackTotal - 1
        MathCode = ExprTempStack(ExprTempStackTotal, 0): MathParm = 255
        GOSUB PushSlntExprCode
      END IF
    END IF
  CASE ExprSep: NewOperator = 1
  END SELECT
NEXT CharPtr

EXIT SUB

GetSlntExprConstant:
  NextCharPtr = CharPtr
  DecimalPoint = 0
  FOR NextCharPtr = CharPtr + 1 TO LEN(Expression$)
    Char = ASC(MID$(Expression$, NextCharPtr, 1))
    IF (Char < 48 OR Char > 57) AND Char <> 46 THEN EXIT FOR ELSE IF Char = 46 THEN IF DecimalPoint THEN EXIT FOR ELSE DecimalPoint = 1
  NEXT NextCharPtr
  Char$ = MID$(Expression$, CharPtr, NextCharPtr - CharPtr)
  CharPtr = NextCharPtr - 1
RETURN

GetSlntExprVariable:
  NextCharPtr = CharPtr
  FOR NextCharPtr = CharPtr + 1 TO LEN(Expression$)
    Char = ASC(UCASE$(MID$(Expression$, NextCharPtr, 1)))
    IF (Char < 48 OR Char > 57) AND (Char < 65 OR Char > 90) THEN EXIT FOR
  NEXT NextCharPtr
  Char$ = MID$(Expression$, CharPtr, NextCharPtr - CharPtr)
  CharPtr = NextCharPtr - 1
RETURN

PushSlntExprTempCode:
  IF ExprTempCodesTotal > 127 THEN ERROR 200
  ExprTempCodes(ExprTempCodesTotal) = TempCode
  ExprTempCodesTotal = ExprTempCodesTotal + 1
RETURN

PushSlntExprCode:
  IF ExprCodesTotal > 31 THEN ERROR 200
  ExprCodes(ExprCodesTotal).Operation = MathCode
  ExprCodes(ExprCodesTotal).Parameter = MathParm
  ExprCodesTotal = ExprCodesTotal + 1
RETURN

CompileSlntError:
  ErrorPos = CharPtr
  CompileExprError ErrorNum, ErrorPos

END SUB

SUB SilentExecuteExpr

Accumalator# = 0
FOR CharPtr = 0 TO ExprCodesTotal - 1
  MathCode = ExprCodes(CharPtr).Operation
  MathParm = ExprCodes(CharPtr).Parameter
  IF MathParm < 255 THEN
    Operand# = ExprData(MathParm).Value
  ELSE
    IF ExprStackTotal <= 0 THEN ERROR 200
    ExprStackTotal = ExprStackTotal - 1
    Operand# = Accumalator#
    Accumalator# = ExprStack(ExprStackTotal)
  END IF
  GOSUB SilentExecuteOperation
NEXT CharPtr

EXIT SUB

SilentExecuteOperation:
  SELECT CASE MathCode
  CASE ExprSav
    IF ExprStackTotal >= 31 THEN ERROR 200
    ExprStack(ExprStackTotal) = Accumalator#
    ExprStackTotal = ExprStackTotal + 1
    Accumalator# = Operand#
  CASE ExprSet: Accumalator# = Operand#
  CASE ExprAdd: Accumalator# = Accumalator# + Operand#
  CASE ExprSub: Accumalator# = Accumalator# - Operand#
  CASE ExprMul: Accumalator# = Accumalator# * Operand#
  CASE ExprDiv: Accumalator# = Accumalator# / Operand#
  CASE ExprAsn: IF MathParm < 32 THEN ExprData(MathParm).Value = Accumalator#
  END SELECT
RETURN

END SUB

FUNCTION StrTrim$ (Num)
StrTrim = LTRIM$(STR$(Num))
END FUNCTION

SUB WaitForExpression

DIM Xlines(639) AS DOUBLE
PromptMake ExprPrompt, LEN(ExprText$), 80, 1, 1
RefreshPrompt = 1
DO
  Key$ = INKEY$
  SELECT CASE Key$
  CASE CHR$(27): EXIT DO
  CASE "~"
  CASE CHR$(13)
    IF GraphicsMode THEN Regs.Ax = 2: CALL INTERRUPT(&H33, Regs, Regs): SilentCompile = -1 ELSE SilentCompile = 0
    CompileExprLine ExprText$, ErrorPos, SilentCompile
    IF ErrorPos GOTO ErrorInExpression
    IF GraphicsMode THEN
      GOSUB GraphicsDemo
      Regs.Ax = 1: CALL INTERRUPT(&H33, Regs, Regs)
      IF ErrorPos GOTO ErrorInExpression
      PointerRow = -1
    ELSE
      RefreshPrompt = 1
    END IF
  CASE CHR$(10)
    CompileExprLine ExprText$, ErrorPos, -1
    IF ErrorPos GOTO ErrorInExpression
    IF GraphicsMode = 0 THEN
      VIEW PRINT 2 TO 25
      COLOR , 0: CLS
      VIEW PRINT
    ELSE
      LINE (0, 16)-(639, 479), 0, BF
    END IF
    LOCATE 2, 1, 0
    COLOR 10
    PrintAllVariables
    RefreshPrompt = 1
  CASE CHR$(9)
    GraphicsMode = GraphicsMode XOR -1
    IF GraphicsMode THEN
      SCREEN 12
      Regs.Ax = 0'reset mouse
      CALL INTERRUPT(&H33, Regs, Regs)
      MousePresent = Regs.Ax
      IF MousePresent THEN Regs.Ax = 1: CALL INTERRUPT(&H33, Regs, Regs)
    ELSE
      SCREEN 0
      LOCATE , , , 12, 13
    END IF
    RefreshPrompt = 1
  CASE IS > "": PromptText ExprText$, ExprPrompt, Key$
  END SELECT
WFEEndSelect:

  IF GraphicsMode AND MousePresent THEN
    Regs.Ax = 3
    CALL INTERRUPT(&H33, Regs, Regs)
    IF Regs.Dx <> PointerRow THEN
      PointerRow = Regs.Dx
      COLOR 15: LOCATE 1, 1: PRINT "Y ="; (PointerRow - 240) * Yscale#; TAB(40); "X ="; Xlines(PointerRow); TAB(80);
    END IF
  END IF

  IF RefreshPrompt THEN
    ExprPrompt.Change = -1
    PromptText ExprText$, ExprPrompt, ""
    RefreshPrompt = 0
  END IF
LOOP

EXIT SUB

GraphicsDemo:
  ClearMathConstants
  GetVariable "y", Yindex
  GetVariable "x", Xindex
  GetVariable "xs", XSindex
  GetVariable "ys", YSindex
 
  CharPtr = 1
  DO
    NextCharPtr = INSTR(CharPtr, ExprText$, ";")
    IF NextCharPtr = 0 THEN ExprPart$ = MID$(ExprText$, CharPtr): EXIT DO
    CharPtr = NextCharPtr + 1
  LOOP
  SilentCompileExpr ExprPart$, ErrorPos
  IF ErrorPos THEN RETURN
 
  ClearScreenWindow
  SilentExecuteExpr
 
  LINE (320, 238)-(320, 242), 15
  LINE (318, 240)-(322, 240), 15

  XScale# = ExprData(XSindex).Value
  Yscale# = ExprData(YSindex).Value
  IF XScale# = 0 THEN XScale# = 1
  IF Yscale# = 0 THEN Yscale# = 3.2
  FOR PixelRow = 16 TO 480
    Yoffset# = (PixelRow - 240) * Yscale#
    ExprData(Yindex).Value = Yoffset#
    SilentExecuteExpr
    Xlines(PixelRow) = ExprData(Xindex).Value * XScale#
    Xoffset# = Xlines(PixelRow) + 320
    IF ABS(Xoffset#) <= 65535 THEN PSET (INT(Xoffset#), PixelRow), 9
  NEXT
RETURN

ErrorInExpression:
  ExprPrompt.Csr = ErrorPos - 1
  RefreshPrompt = 1
GOTO WFEEndSelect

END SUB

