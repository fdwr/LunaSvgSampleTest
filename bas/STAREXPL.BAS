DEFINT A-Z
OPTION BASE 0

TYPE StarType
Row AS INTEGER
Col AS INTEGER
RowSpeed AS INTEGER
ColSpeed AS INTEGER
PixColor AS INTEGER
BackColor AS INTEGER
Visible AS INTEGER
END TYPE

SCREEN 13

CONST LastStar = 299, StarMinSpeed = 1, StarSpeedRange = 200
CONST StarSpeedMidrange = StarSpeedRange \ 2, StarDistance = 100
CONST StarRowExtent = 101 * StarDistance, StarColExtent = 161 * StarDistance

NewExplosion:
GOSUB DrawFieldBackground
DO: LOOP UNTIL LEN(INKEY$)

REDIM Stars(LastStar) AS StarType
RANDOMIZE TIMER

DO
  FOR CurStar = 0 TO LastStar
    IF NOT Stars(CurStar).Visible THEN
      Stars(CurStar).RowSpeed = INT(RND * StarSpeedRange) - StarSpeedMidrange
      Stars(CurStar).ColSpeed = INT(RND * StarSpeedRange) - StarSpeedMidrange
      IF ABS(Stars(CurStar).RowSpeed) + ABS(Stars(CurStar).ColSpeed) < StarMinSpeed GOTO SkipStar
      Stars(CurStar).PixColor = INT(RND * 16) + 64
      StarBirths = StarBirths + 1
      IF StarBirths > 32000 THEN StarBirths = 0
      Stars(CurStar).Visible = -1
    END IF
    'StarRow = Stars(CurStar).Row \ StarDistance + 100
    'StarCol = Stars(CurStar).Col \ StarDistance + 160
    'Stars(CurStar).BackColor = POINT(StarCol, StarRow)
    'PSET (Stars(CurStar).Col \ StarDistance + 160, Stars(CurStar).Row \ StarDistance + 100), 0
    PSET (Stars(CurStar).Col \ StarDistance + 160, Stars(CurStar).Row \ StarDistance + 100), Stars(CurStar).BackColor
    Stars(CurStar).Row = Stars(CurStar).Row + Stars(CurStar).RowSpeed
    Stars(CurStar).Col = Stars(CurStar).Col + Stars(CurStar).ColSpeed
    IF ABS(Stars(CurStar).Row) > StarRowExtent OR ABS(Stars(CurStar).Col) > StarColExtent THEN
      Stars(CurStar).Visible = 0
      Stars(CurStar).Row = 0
      Stars(CurStar).Col = 0
      GOTO SkipStar
    END IF
    StarRow = Stars(CurStar).Row \ StarDistance + 100
    StarCol = Stars(CurStar).Col \ StarDistance + 160
    Stars(CurStar).BackColor = POINT(StarCol, StarRow)
    PSET (StarCol, StarRow), Stars(CurStar).PixColor
SkipStar:
  NEXT CurStar
 
  'StarRedraws = StarRedraws + 1
  'IF StarRedraws >= 23 THEN
  '  LOCATE 1, 1: PRINT StarBirths;
  '  StarRedraws = 0
  'END IF
  Key$ = INKEY$
  IF LEN(Key$) THEN
    IF Key$ = CHR$(13) GOTO NewExplosion ELSE EXIT DO
  END IF
LOOP

END

DrawFieldBackground:
  FOR Row = 0 TO 160
    LINE (159 - Row, 99 - Row)-(160 + Row, 99 + Row), Row \ 8 + 128, B
  NEXT Row
RETURN

