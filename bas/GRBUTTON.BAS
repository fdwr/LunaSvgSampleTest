DEFINT A-Z
DECLARE SUB ButtonDraw (ButtonInfo AS ANY, Mode)

TYPE ButtonDefs
LeftCol AS INTEGER
RiteCol AS INTEGER
TopRow  AS INTEGER
BotRow  AS INTEGER
END TYPE
DIM SHARED ButtonType

SCREEN 12
LINE (0, 0)-(639, 479), 7, BF

REDIM ThreeButtons(0 TO 2) AS ButtonDefs

FOR MakeButtons = 0 TO 2
ThreeButtons(MakeButtons).LeftCol = MakeButtons * 60 + 200
ThreeButtons(MakeButtons).RiteCol = MakeButtons * 60 + 229
ThreeButtons(MakeButtons).TopRow = 200
ThreeButtons(MakeButtons).BotRow = 229
NEXT MakeButtons

GOSUB DrawAllButtons
Refresh = 1
LastButton = 0
CurButton = 0
DO
 SELECT CASE INKEY$
 CASE CHR$(27), CHR$(13): EXIT DO
 CASE CHR$(0) + "H": ButtonType = (ButtonType + 3) MOD 2: GOSUB DrawAllButtons: Refresh = 1
 CASE CHR$(0) + "P": ButtonType = (ButtonType + 1) MOD 2: GOSUB DrawAllButtons: Refresh = 1
 CASE CHR$(0) + "K": CurButton = (CurButton + 5) MOD 3: Refresh = 1
 CASE CHR$(0) + "M": CurButton = (CurButton + 1) MOD 3: Refresh = 1
 END SELECT
 IF ButtonDown AND INP(96) <> 57 THEN ButtonDown = 0: Refresh = 1 ELSE IF ButtonDown = 0 AND INP(96) = 57 THEN ButtonDown = 1: Refresh = 1
 IF Refresh THEN
  IF CurButton <> LastButton THEN ButtonDraw ThreeButtons(LastButton), 0
  ButtonDraw ThreeButtons(CurButton), ButtonDown + 1
  LastButton = CurButton
  Refresh = 0
  WHILE INKEY$ > "": WEND
 END IF
LOOP

SCREEN 0
END

DrawAllButtons:
 LOCATE 1, 1
 SELECT CASE ButtonType
 CASE 0: PRINT "My own style";
 CASE 1: PRINT "Windows 3.1 style";
 END SELECT
 PRINT TAB(80); " ";
 ButtonDraw ThreeButtons(0), 0
 ButtonDraw ThreeButtons(1), 0
 ButtonDraw ThreeButtons(2), 0
RETURN

SUB ButtonDraw (ButtonInfo AS ButtonDefs, Mode)

LeftCol = ButtonInfo.LeftCol
RiteCol = ButtonInfo.RiteCol
TopRow = ButtonInfo.TopRow
BotRow = ButtonInfo.BotRow
SELECT CASE ButtonType
CASE 1: GOTO WindowsStyle
END SELECT

LINE (LeftCol + 1, TopRow)-(RiteCol - 1, TopRow), 8
LINE (LeftCol + 1, BotRow)-(RiteCol - 1, BotRow), 15
LINE (LeftCol, TopRow + 1)-(LeftCol, BotRow - 1), 8
LINE (RiteCol, TopRow + 1)-(RiteCol, BotRow - 1), 15
LINE (LeftCol + 1, TopRow + 1)-(RiteCol - 1, BotRow - 1), 0, B
IF Mode THEN
 LINE (LeftCol + 2, TopRow + 2)-(RiteCol - 2, BotRow - 2), 0, B
 LINE (LeftCol + 3, TopRow + 3)-(RiteCol - 3, BotRow - 3), 7, B
ELSE
 LINE (LeftCol + 2, TopRow + 2)-(RiteCol - 2, BotRow - 2), 7, BF
END IF

SELECT CASE Mode
CASE 0
 LINE (LeftCol + 2, TopRow + 2)-(RiteCol - 2, TopRow + 2), 15
 LINE (LeftCol + 2, BotRow - 2)-(RiteCol - 2, BotRow - 2), 8
 LINE (LeftCol + 2, TopRow + 3)-(LeftCol + 2, BotRow - 3), 15
 LINE (RiteCol - 2, TopRow + 3)-(RiteCol - 2, BotRow - 3), 8

CASE 1
 LINE (LeftCol + 3, TopRow + 3)-(RiteCol - 3, TopRow + 3), 15
 LINE (LeftCol + 3, BotRow - 3)-(RiteCol - 3, BotRow - 3), 8
 LINE (LeftCol + 3, TopRow + 4)-(LeftCol + 3, BotRow - 4), 15
 LINE (RiteCol - 3, TopRow + 4)-(RiteCol - 3, BotRow - 4), 8

CASE 2
 LINE (LeftCol + 3, TopRow + 3)-(RiteCol - 3, TopRow + 3), 8
 LINE (LeftCol + 3, BotRow - 3)-(RiteCol - 3, BotRow - 3), 15
 LINE (LeftCol + 3, TopRow + 4)-(LeftCol + 3, BotRow - 4), 8
 LINE (RiteCol - 3, TopRow + 4)-(RiteCol - 3, BotRow - 4), 15

END SELECT

EXIT SUB

WindowsStyle:
LINE (LeftCol + 1, TopRow)-(RiteCol - 1, TopRow), 0
LINE (LeftCol + 1, BotRow)-(RiteCol - 1, BotRow), 0
LINE (LeftCol, TopRow + 1)-(LeftCol, BotRow - 1), 0
LINE (RiteCol, TopRow + 1)-(RiteCol, BotRow - 1), 0
IF Mode THEN
 LINE (LeftCol + 1, TopRow + 1)-(RiteCol - 1, BotRow - 1), 0, B
 LINE (LeftCol + 2, TopRow + 2)-(RiteCol - 2, BotRow - 2), 7, BF
ELSE
 LINE (LeftCol + 1, TopRow + 1)-(RiteCol - 1, BotRow - 1), 7, BF
END IF

SELECT CASE Mode
CASE 0
 LINE (LeftCol + 1, TopRow + 1)-(RiteCol - 1, TopRow + 1), 15
 LINE (LeftCol + 1, BotRow - 1)-(RiteCol - 1, BotRow - 1), 8
 LINE (LeftCol + 1, TopRow + 2)-(LeftCol + 1, BotRow - 2), 15
 LINE (RiteCol - 1, TopRow + 2)-(RiteCol - 1, BotRow - 2), 8
 LINE (LeftCol + 2, TopRow + 2)-(RiteCol - 2, TopRow + 2), 15
 LINE (LeftCol + 2, BotRow - 2)-(RiteCol - 2, BotRow - 2), 8
 LINE (LeftCol + 2, TopRow + 3)-(LeftCol + 2, BotRow - 3), 15
 LINE (RiteCol - 2, TopRow + 3)-(RiteCol - 2, BotRow - 3), 8

CASE 1
 LINE (LeftCol + 2, TopRow + 2)-(RiteCol - 2, TopRow + 2), 15
 LINE (LeftCol + 2, BotRow - 2)-(RiteCol - 2, BotRow - 2), 8
 LINE (LeftCol + 2, TopRow + 3)-(LeftCol + 2, BotRow - 3), 15
 LINE (RiteCol - 2, TopRow + 3)-(RiteCol - 2, BotRow - 3), 8
 LINE (LeftCol + 3, TopRow + 3)-(RiteCol - 3, TopRow + 3), 15
 LINE (LeftCol + 3, BotRow - 3)-(RiteCol - 3, BotRow - 3), 8
 LINE (LeftCol + 3, TopRow + 4)-(LeftCol + 3, BotRow - 4), 15
 LINE (RiteCol - 3, TopRow + 4)-(RiteCol - 3, BotRow - 4), 8

CASE 2
 LINE (LeftCol + 2, TopRow + 2)-(RiteCol - 2, TopRow + 2), 8
 LINE (LeftCol + 2, BotRow - 2)-(RiteCol - 2, BotRow - 2), 0
 LINE (LeftCol + 2, TopRow + 3)-(LeftCol + 2, BotRow - 3), 8
 LINE (RiteCol - 2, TopRow + 3)-(RiteCol - 2, BotRow - 3), 0
 LINE (LeftCol + 3, TopRow + 3)-(RiteCol - 3, TopRow + 3), 8
 LINE (LeftCol + 3, BotRow - 3)-(RiteCol - 3, BotRow - 3), 0
 LINE (LeftCol + 3, TopRow + 4)-(LeftCol + 3, BotRow - 4), 8
 LINE (RiteCol - 3, TopRow + 4)-(RiteCol - 3, BotRow - 4), 0

END SELECT

END SUB

