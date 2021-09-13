DECLARE SUB SetupSinCosTables ()
DECLARE SUB DrawPoints (Colour%)
DECLARE SUB SetupBall ()
DECLARE SUB Rotate ()

'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
'screen setup
'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

DEFINT A-Z
SCREEN 7

'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
'constant values
'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

CONST Scale = 50    ' x and y are multiplied by scale and divided by distance
CONST Radius = 100   ' mystery constant
CONST DelayTime = 1 ' Delay(DelayTime) to slow it down..
CONST Slices = 12   ' number of slices
CONST PPS = 20      ' points per slice
CONST Pi = 3.14

'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
'type setups for the ball points
'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

TYPE PointType
  x AS INTEGER
  y AS INTEGER
  Z AS INTEGER
END TYPE

DIM SHARED points(1 TO Slices, 1 TO PPS) AS PointType
DIM SHARED Ball(1 TO Slices, 1 TO PPS) AS PointType

'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
'dimensions
'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

DIM SHARED SinTable(0 TO 255)  AS INTEGER
DIM SHARED CosTable(0 TO 255)  AS INTEGER

DIM SHARED XAngle, YAngle, ZAngle
DIM SHARED Distance, Dir

'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
'Setup the sin & cos tables, and setup the ball
'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

  SetupSinCosTables
 
  SetupBall

'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
'set up the starting variables
'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

  Distance = 100: Dir = -3
  XAngle = 0
  YAngle = 0
  ZAngle = 0

'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
'do the main loop
'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

  DO
   
    PCOPY 3, 2
    SCREEN , , 2, 0
   
    Rotate
   
    DrawPoints 15
   
    XAngle = XAngle + 3
    YAngle = YAngle + 2
    ZAngle = ZAngle + 1
    Distance = Distance + Dir
   
    IF XAngle > 250 THEN XAngle = 0
    IF YAngle > 250 THEN YAngle = 0
    IF ZAngle > 250 THEN ZAngle = 0
    IF Distance >= 300 THEN Dir = -3
    IF Distance <= 30 THEN Dir = 2
   
    PCOPY 2, 0
    SCREEN , , 2, 0

  LOOP UNTIL INKEY$ <> ""

'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл
'finish the program
'лллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллллл

CLS
SCREEN 0

END

SUB DrawPoints (Colour)
 
  FOR i = 1 TO Slices
    FOR i2 = 1 TO PPS
      IF (points(i, i2).Z >= 0) AND (points(i, i2).x <= 319) AND (points(i, i2).x >= 0) AND (points(i, i2).y >= 0) AND (points(i, i2).y < 199) THEN
        PSET (points(i, i2).x, points(i, i2).y), Colour
      END IF
    NEXT i2
  NEXT i

END SUB

SUB Rotate
'UPDATES all (X,Y,Z) coordinates according to XAngle,YAngle,ZAngle
 
  FOR i = 1 TO Slices
    FOR i2 = 1 TO PPS
                     '{rotate on X-axis}
      TempY = (Ball(i, i2).y * CosTable(XAngle) - Ball(i, i2).Z * SinTable(XAngle)) / 128
      TempZ = (Ball(i, i2).y * SinTable(XAngle) + Ball(i, i2).Z * CosTable(XAngle)) / 128
                    ' {rotate on y-anis}
      TempX = (Ball(i, i2).x * CosTable(YAngle) - TempZ * SinTable(YAngle)) / 128
      TempZ = (Ball(i, i2).x * SinTable(YAngle) + TempZ * CosTable(YAngle)) / 128
                     '{rotate on z-axis}
      OldTempX = TempX
      TempX = (TempX * CosTable(ZAngle) - TempY * SinTable(ZAngle)) / 128
      TempY = (OldTempX * SinTable(ZAngle) + TempY * CosTable(ZAngle)) / 128
      points(i, i2).x = (TempX * Scale) / Distance + 320 / 2
      points(i, i2).y = (TempY * Scale) / Distance + 200 / 2
      points(i, i2).Z = TempZ
    NEXT i2
  NEXT i
END SUB

SUB SetupBall
 
  'sets up the ball's data..
 
  FOR SliceLoop = 1 TO Slices
      Phi! = Pi / Slices * SliceLoop        ' 0 <= Phi <= Pi
     
      FOR PPSLoop = 1 TO PPS
          Theta! = 2 * Pi / PPS * PPSLoop   ' 0 <= Theta <= 2*Pi
              'convert Radius,Thetha,Phi to (x,y,z) coordinates

          Ball(SliceLoop, PPSLoop).y = INT(Radius * SIN(Phi!) * COS(Theta!))
          Ball(SliceLoop, PPSLoop).x = INT(Radius * SIN(Phi!) * SIN(Theta!))
          Ball(SliceLoop, PPSLoop).Z = INT(Radius * COS(Phi!))
      NEXT PPSLoop

 NEXT SliceLoop

END SUB

SUB SetupSinCosTables
 
  FOR i = 0 TO 255
      SinTable(i) = INT(SIN(2 * Pi / 255 * i) * 128)
      CosTable(i) = INT(COS(2 * Pi / 255 * i) * 128)
  NEXT i

END SUB

