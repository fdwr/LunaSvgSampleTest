DEFINT A-Z

SCREEN 13

CONST FlysChase = 0, FlysRandom = 1, FlysEvade = 2, FlysPattern = 3
CONST TimerPtr = 1132, TimerClicks = 1: DEF SEG = 0

' Random fly patterns
REDIM FlyPatternX(0 TO 2, 0 TO 19), FlyPatternY(0 TO 2, 0 TO 19)
FOR ReadIn = 0 TO 19
 FOR ReadInPtrn = 0 TO 2
  READ FlyPatternX(ReadInPtrn, ReadIn), FlyPatternY(ReadInPtrn, ReadIn)
 NEXT ReadInPtrn
NEXT ReadIn
DATA 1,1,1,1,1,2,2,-1,-2,-3,-1,0,0,1,2,2,-2,-2,-1,0
DATA 0,0,1,2,3,4,5,4,3,2,1,3,3,3,3,2,1,-2,-2,-1
DATA 0,-1,-2,-3,-3,-2,-2,0,0,0,0,0,0,1,0,0,0,1,0,1
DATA 0,0,0,0,-1,-1,-1,-1,-1,0,0,0,0,0,2,2,2,2,2,2
DATA 1,1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,0,0,0,0
DATA 1,1,1,2,2,-1,-1,-1,-2,-2,-1,-1,0,0,0,1,1,1,1,1

px = 160: py = 100 'Start position of player
fx = 0: fy = 0     'Start position of fly
flySpeed = 1: playSpeed = 2
FlyState = FlyChase: FlyClicks = 20

' Enter main loop
DO
 opx = px: opy = py
 ofx = fx: ofy = fy

 WHILE INKEY$ > "": WEND
 SELECT CASE INP(96)
 CASE 72: py = py - playSpeed
 CASE 80: py = py + playSpeed
 CASE 75: px = px - playSpeed
 CASE 77: px = px + playSpeed
 CASE 1: EXIT DO
 END SELECT

 LOCATE 25, 1
 SELECT CASE FlyState
 CASE FlysChase
  PRINT "Chase  ";

  ' Chase the player
  IF px > fx THEN fx = fx + flySpeed ELSE IF px < fx THEN fx = fx - flySpeed
  IF py > fy THEN fy = fy + flySpeed ELSE IF py < fy THEN fy = fy - flySpeed

 CASE FlysRandom
  PRINT "Random ";

  ' Move according to a randomly chosen number
  fx = fx + FlyXv
  fy = fy + FlyYv

 CASE FlysEvade
  PRINT "Evade  ";
 
  ' Move away from the player
  IF px > fx THEN fx = fx - flySpeed ELSE fx = fx + flySpeed
  IF py > fy THEN fy = fy - flySpeed ELSE fy = fy + flySpeed

 CASE FlysPattern
  PRINT "Pattern";

  ' Move fly according to pattern in array
  fx = fx + FlyPatternX(FlyPattern, FlyPtElement)
  fy = fy + FlyPatternY(FlyPattern, FlyPtElement)

  FlyPtElement = (FlyPtElement + 1) MOD 20

 END SELECT

 IF FlyClicks < 1 THEN FlyNewState = 1 ELSE FlyClicks = FlyClicks - 2

 IF FlyNewState THEN
  dx& = px - fx: dy& = py - fy
  FlyPlayDist = SQR(.5 + ABS(dx& * dx& + dy& * dy&))

  IF FlyPlayDist > 5 AND FlyPlayDist < 15 AND INT(RND * 2) = 1 THEN
   FlyState = FlysPattern
   FlyPattern = INT(RND * 3)
   FlyPtElement = 0
   FlyClicks = 30

  ELSEIF FlyPlayDist < 10 THEN
   FlyState = FlysEvade
   FlyClicks = 20

  ELSEIF FlyPlayDist > 25 AND FlyPlayDist < 100 AND INT(RND * 3) = 1 THEN
   FlyState = FlysChase
   FlyClicks = 15

  ELSE
   FlyState = FlysRandom
   IF FlyPlayDist > 30 AND INT(RND * 2) = 1 THEN FlyClicks = 10 ELSE FlyClicks = 5

   FlyXv = -5 + INT(RND * 11)
   FlyYv = -5 + INT(RND * 11)

  END IF

  FlyNewState = 0

 END IF

 IF fx > 319 THEN fx = 319 ELSE IF fx < 0 THEN fx = 0
 IF fy > 199 THEN fy = 199 ELSE IF fy < 0 THEN fy = 0

 'Draw dots to represent characters; player and fly
 
 PSET (opx, opy), 0: PSET (px, py), 9
 PSET (ofx, ofy), 0: PSET (fx, fy), 12

 LastTime = PEEK(TimerPtr)
 WHILE ABS(PEEK(TimerPtr) - LastTime) < TimerClicks: WEND

LOOP

SCREEN 0

