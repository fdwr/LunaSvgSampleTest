DEFINT A-Z
DECLARE FUNCTION WaveForm (WavePos%, WaveLen%)

SCREEN 12
FOR WaveType = 0 TO 4
 TopRow = TopRow + 50
 GOSUB DrawWave
NEXT WaveType

TopRow = TopRow + 100
FOR WaveType = 0 TO 4
 GOSUB DrawWave
NEXT WaveType

END

DrawWave:
 SELECT CASE WaveType
 CASE 0: WaveLen1 = 60: WaveLen2 = 0: WaveColor = 12
 CASE 1: WaveLen1 = 20: WaveLen2 = 0: WaveColor = 14
 CASE 2: WaveLen1 = 10: WaveLen2 = 52: WaveColor = 10
 CASE 3: WaveLen1 = 20: WaveLen2 = 52: WaveColor = 9
 CASE 4: WaveLen1 = 10: WaveLen2 = 12: WaveColor = 13
 END SELECT

 FOR WavePos = 0 TO 639
  PSET (WavePos, WaveForm(WavePos, WaveLen1) + WaveForm(WavePos, WaveLen2) + TopRow), WaveColor
 NEXT WavePos
 IF INKEY$ > "" THEN END
RETURN

FUNCTION WaveForm (WavePos, WaveLen)
IF WaveLen = 0 THEN WaveForm = 0: EXIT FUNCTION
TempForm = WavePos MOD WaveLen
TempSin! = (TempForm * 6.28) / WaveLen
WaveForm = INT(SIN(TempSin!) * 10)
END FUNCTION

