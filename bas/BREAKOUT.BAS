' Start it all up
DEFINT A-Z

' Set values to constants and SUBs
TYPE ObjectInfo
Trow AS INTEGER
Brow AS INTEGER
Lcol AS INTEGER
Rcol AS INTEGER
Vdir AS INTEGER
Hdir AS INTEGER
frame AS INTEGER
Size AS INTEGER
END TYPE

DECLARE SUB Intro ()
DECLARE SUB MainMenu (ExitSign)
DECLARE SUB LoadLevel ()
DECLARE SUB PlaySim (ExitSign)
DECLARE SUB GameOver (ExitSign)

DECLARE SUB BallRepos (ball AS ObjectInfo)
DECLARE SUB BallBounce (ball AS ANY)
DECLARE SUB CrabRepos (Crab AS ObjectInfo, DirMessage)
DECLARE SUB BackRedraw (Coors AS ANY)
DECLARE SUB BallShow (ball AS ObjectInfo)
DECLARE SUB BlockShow (BlockRow, BlockCol)
DECLARE SUB BlockShowRange (Trow, Brow, Lcol, Rcol)
DECLARE SUB BlockBlast (BlockRow, BlockCol, ThkDir)
DECLARE SUB GridLine (VY1pos, HX1pos, VY2pos, HX2pos, ClrThk, DrawOn)
DECLARE SUB GridSquare (VY1pos, HX1pos, VY2pos, HX2pos, Filled, ClrThk, DrawOn)
DECLARE SUB GridText (Data$, Trow, Lcol, ClrThk, DrawOn)
DECLARE SUB GridBlock (Data$, Trow, Lcol, ClrThk, ClrOff, DrawOn)
DECLARE SUB SoundFXnew (Data$, Filled)
DECLARE SUB SoundFXplay ()
DECLARE SUB TextCenter (VYpos, Text$)

' Declare main variables
CONST FALSE = 0, TRUE = NOT FALSE, STARTOVER = 0, SAMELEVEL = 1, NEXTLEVEL = 2, CrabSpeed = 3, CrabWidth = 24, PearlWidth = 20
DIM SHARED SoundData$, SoundPos, GameInProgress, MenuFunction, CurLevel, LevelChange
DIM SHARED PlayerCrab AS ObjectInfo, ball AS ObjectInfo, CrabPicts(0 TO 575), Pearl(0 TO 43), Clam(0 TO 65)
REDIM SHARED LandGrid(0 TO 24, 0 TO 39), LandPicts(0 TO 3000)

'Get user inputs:
' Number of people that are playing

' Preset general difficulty speed
' Increase speed on hit with bricks
' Reset game or continue current game

' Set the screen mode and other stuff
SCREEN 7, , 0, 0
GOSUB ReadPicts

' Start the intro and wait for user
Intro

ExitSign = TRUE
DO
 SELECT CASE ExitSign
 CASE -1: MainMenu ExitSign
 CASE 0: PlaySim ExitSign
 CASE 1: LoadLevel
 CASE 2: GameOver ExitSign
 END SELECT
LOOP UNTIL ExitSign = -2
EndIt:
SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS
END

ReadPicts:
RESTORE ReadPicts
FOR ReadIn = 0 TO 43: READ Pearl(ReadIn): NEXT ReadIn

DATA 8,10,-15421,-15421,-32383,-32383,0,0,0,0,0,0,0,0,-32383,129,-15421,195,-1,-32257,-1,-15361
'DATA 8,10,15420,60,32382,12414,-258,31230,-258,31230,-258,12798,-258,510,31868,636,0,15360,0,0,0,0
DATA 8,10,15420,60,32382,14462,-1,31999,-1,31999,-1,31999,-1,14591,32382,126,15420,60,0,0,0,0
RETURN

SUB BackRedraw (Coors AS ObjectInfo)

BlockShowRange Coors.Trow \ 8, Coors.Brow \ 8, Coors.Lcol \ 8, Coors.Rcol \ 8

END SUB

SUB BallBounce (ball AS ObjectInfo)
'Calculates the position of the ball, checks for collisions with walls and
'other obstacles, updates itself onto the screen. If the routine detects a
'wall between last position and next frame position, its direction will be
'perpendicularly deflected or in other words, ricochet and bounce off it.
'You could say this SUB is the ball itself, like an object with physical
'properties and characteristics of a real ball including: size, color, mass,
'inertia, and angular deflection. Between the two frame positions, test
'vertically and horizontally. Deflect whichever direction is closer. If
'deflected, then test again at next projected postion keep testing until
'deflection is no more or frame distance is zero

: ball.Size = 10
ball.Brow = ball.Trow + ball.Size - 1: ball.Rcol = ball.Lcol + ball.Size - 1
BackRedraw ball
IF SGN(ball.Vdir) = 1 THEN
 IF ball.Brow + ball.Vdir > 199 THEN ball.Trow = ball.Trow + 199 - ball.Brow - ball.Vdir: ball.Vdir = -ball.Vdir: SOUND 1024, .1 ELSE ball.Trow = ball.Trow + ball.Vdir
ELSE
 IF ball.Trow + ball.Vdir < 0 THEN ball.Trow = ABS(ball.Vdir + ball.Trow): ball.Vdir = -ball.Vdir: SOUND 1024, .1 ELSE ball.Trow = ball.Trow + ball.Vdir
END IF
IF SGN(ball.Hdir) = 1 THEN
 IF ball.Rcol + ball.Hdir > 319 THEN ball.Lcol = ball.Lcol + 319 - ball.Rcol - ball.Hdir: ball.Hdir = -ball.Hdir: SOUND 1024, .1 ELSE ball.Lcol = ball.Lcol + ball.Hdir
ELSE
 IF ball.Lcol + ball.Hdir < 0 THEN ball.Lcol = ABS(ball.Hdir + ball.Lcol): ball.Hdir = -ball.Hdir: SOUND 1024, .1 ELSE ball.Lcol = ball.Lcol + ball.Hdir
END IF
PUT (ball.Lcol, ball.Trow), Pearl, AND
PUT (ball.Lcol, ball.Trow), Pearl(22), OR

END SUB

SUB BallRepos (ball AS ObjectInfo)
'Calculates the position of the ball, checks for collisions with walls and
'other obstacles, updates itself onto the screen. If the routine detects a
'wall between last position and next frame position, its direction will be
'perpendicularly deflected or in other words, ricochet and bounce off it.
'You could say this SUB is the ball itself, like an object with physical
'properties and characteristics of a real ball including: size, color, mass,
'inertia, and angular deflection. Between the two frame positions, test
'vertically and horizontally. Deflect whichever direction is closer. If
'deflected, then test again at next projected postion keep testing until
'deflection is no more or frame distance is zero

ball.Brow = ball.Trow + PearlWidth + 1: ball.Rcol = ball.Lcol + PearlWidth - 1
Hdir = ball.Hdir: Vdir = ball.Vdir
'BackRedraw ball
ball.Brow = ball.Trow + PearlWidth - 1

'do loop until Hdir and Vdir reflections have both been exhausted to zero
'by either reflecting until there frame time momentum is out or no blocks are
'in the path
'Do
'compute vertical and horizontal trail hits, plus hit with crab
'compare hits to each other. Find first hit, deflect ball direction and reduce
'remaining momentum
'loop

'temp stuff:
'LINE (ball.Lcol, ball.Trow)-(ball.Lcol + Hdir, ball.Trow + Vdir), 11
'LINE (ball.Rcol, ball.Trow)-(ball.Rcol + Hdir, ball.Trow + Vdir), 10
'LINE (ball.Lcol, ball.Brow)-(ball.Lcol + Hdir, ball.Brow + Vdir), 13
'LINE (ball.Rcol, ball.Brow)-(ball.Rcol + Hdir, ball.Brow + Vdir), 14
'PUT (ball.Lcol, ball.Trow), Pearl, AND
'PUT (ball.Lcol, ball.Trow), Pearl(22), OR
LINE (ball.Lcol, ball.Trow)-(ball.Lcol + PearlWidth - 1, ball.Trow + PearlWidth - 1), 15, B

: tempTrow = ball.Trow
IF SGN(ball.Vdir) = 1 THEN
 'FB = (ball.Brow + 8) \ 8, LB = (ball.Brow + Vdir) \ 8
 NextBase = 8 - (ball.Brow AND 7)
 Hit = FALSE
 FOR Vrow = ball.Brow - (ball.Brow AND 7) + 8 TO ball.Brow + Vdir STEP 8
  ProH = CINT((Hdir * NextBase) / Vdir) + ball.Lcol: NextBase = NextBase + 8
  IF ProH > 0 AND ProH < 320 THEN
   FOR Hcol = ProH \ 8 TO (ProH + PearlWidth) \ 8
    IF LandGrid(Vrow \ 8, Hcol) THEN LandGrid(Vrow \ 8, Hcol) = 2: BlockShow Vrow \ 8, Hcol: Hit = TRUE
   NEXT Hcol
  END IF
  : PSET (ball.Lcol - 3, Vrow), 15
  : LINE (ProH, Vrow)-(ProH + PearlWidth - 1, Vrow), 12
  IF Hit THEN EXIT FOR
 NEXT Vrow
 PRINT TAB(40);
 IF ball.Brow + ball.Vdir > 183 THEN ball.Trow = ball.Trow + 183 - ball.Brow - ball.Vdir: ball.Vdir = -ball.Vdir ELSE ball.Trow = ball.Trow + ball.Vdir
ELSE
 IF ball.Trow + ball.Vdir < 10 THEN ball.Trow = ABS(ball.Vdir + ball.Trow): ball.Vdir = -ball.Vdir ELSE ball.Trow = ball.Trow + ball.Vdir
END IF
IF SGN(ball.Hdir) = 1 THEN
 'FB = (ball.Rcol + 8) \ 8, LB = (ball.Rcol + Hdir) \ 8
 NextBase = 8 - (ball.Rcol AND 7)
 Hit = FALSE
 FOR Hcol = ball.Rcol - (ball.Rcol AND 7) + 8 TO ball.Rcol + Hdir STEP 8
  ProV = CINT((Vdir * NextBase) / Hdir) + tempTrow: NextBase = NextBase + 8
  IF ProV > 0 AND ProV < 192 THEN
   FOR Vrow = ProV \ 8 TO (ProV + PearlWidth) \ 8
    IF LandGrid(Vrow, Hcol \ 8) THEN Hit = TRUE: LandGrid(Vrow, Hcol \ 8) = 3: BlockShow Vrow, Hcol \ 8
   NEXT Vrow
  END IF
  : PSET (Hcol, tempTrow - 3), 15
  : LINE (Hcol, ProV)-(Hcol, ProV + PearlWidth - 1), 12
  IF Hit THEN EXIT FOR
 NEXT Hcol
 'PRINT TAB(40);
 IF ball.Rcol + ball.Hdir > 311 THEN ball.Lcol = ball.Lcol + 311 - ball.Rcol - ball.Hdir: ball.Hdir = -ball.Hdir ELSE ball.Lcol = ball.Lcol + ball.Hdir
ELSE
 IF ball.Lcol + ball.Hdir < 10 THEN ball.Lcol = ABS(ball.Hdir + ball.Lcol): ball.Hdir = -ball.Hdir ELSE ball.Lcol = ball.Lcol + ball.Hdir
END IF

'PUT (ball.Lcol, ball.Trow), Pearl, AND
'PUT (ball.Lcol, ball.Trow), Pearl(22), OR

END SUB

SUB BallShow (ball AS ObjectInfo)
'Draws the ball onto the screen using a simple circle. It also erases the
'last ball position so that a string of balls is not created and there is a
'succesful animation. This can be called from anywhere but is generally by
'BallRepos while animating. It can however be used to refresh the screen
'with the ball object if the screen has been messed up by some menu.
'Default size of the ball is 15 pixels (screen points) across
END SUB

SUB BlockBlast (BlockRow, BlockCol, ThkDir)
'Changes the value of a colored block to a high or lower value depending on
'what value "ThkDir" contains and correspondingly changes the shape of it and
'updates the screen with its current state. If the value goes zero or below,
'then the block will break. It also changes the surrounding blocks that are
'touching it, so that they are non connected.
END SUB

SUB BlockShow (BlockRow, BlockCol)
 realTop = BlockRow * 8
 realLeft = BlockCol * 8
 realBot = realTop + 7
 realRight = realLeft + 7
 ClrThk = LandGrid(BlockRow, BlockCol)
 IF ClrThk = 0 THEN
  LINE (realLeft, realTop)-(realRight, realBot), 0, BF
 ELSEIF ClrThk >= 255 THEN
  LINE (realLeft, realTop)-(realRight, realBot), 7, B
  LINE (realLeft, realTop)-(realRight, realBot), 7
  LINE (realRight, realTop)-(realLeft, realBot), 7
 ELSE
  RealColor = (ClrThk AND 7)
  LINE (realLeft, realTop)-(realRight, realTop), 7
  LINE (realLeft, realTop)-(realLeft, realBot), RealColor + 8
  LINE (realRight, realTop)-(realRight, realBot), 8
  LINE (realLeft, realBot)-(realRight, realBot), 8
  LINE (realLeft + 1, realTop + 1)-(realRight - 1, realBot - 1), RealColor, BF
 END IF
END SUB

SUB BlockShowRange (Trow, Brow, Lcol, Rcol)

FOR BlockRow = Trow TO Brow
 FOR BlockCol = Lcol TO Rcol
  realTop = BlockRow * 8: realBot = realTop + 7
  realLeft = BlockCol * 8: realRight = realLeft + 7
  ClrThk = LandGrid(BlockRow, BlockCol)
  IF ClrThk = 0 THEN
   LINE (realLeft, realTop)-(realRight, realBot), 0, BF
  ELSEIF ClrThk >= 255 THEN
   LINE (realLeft, realTop)-(realRight, realBot), 7, B
   LINE (realLeft, realTop)-(realRight, realBot), 7
   LINE (realRight, realTop)-(realLeft, realBot), 7
  ELSE
   RealColor = (ClrThk AND 7)
   LINE (realLeft, realTop)-(realRight, realTop), 7
   LINE (realLeft, realTop)-(realLeft, realBot), RealColor + 8
   LINE (realRight, realTop)-(realRight, realBot), 8
   LINE (realLeft, realBot)-(realRight, realBot), 8
   LINE (realLeft + 1, realTop + 1)-(realRight - 1, realBot - 1), RealColor, BF
  END IF
 NEXT BlockCol
NEXT BlockRow

END SUB

SUB CrabRepos (Crab AS ObjectInfo, DirMessage)

'Under construction
SELECT CASE DirMessage
CASE 1: IF Crab.Lcol - CrabSpeed > 0 THEN Crab.Lcol = Crab.Lcol - CrabSpeed ELSE Crab.Lcol = 0
 Crab.frame = (Crab.frame + 1) MOD 3
CASE 2: IF Crab.Lcol + CrabSpeed + CrabWidth < 320 THEN Crab.Lcol = Crab.Lcol + CrabSpeed ELSE Crab.Lcol = 320 - CrabWidth
 Crab.frame = (Crab.frame + 5) MOD 3
CASE 3:
CASE 4:
END SELECT
LOCATE 1, 1: PRINT Crab.Lcol, Crab.frame

END SUB

SUB GameOver (ExitSign)
END SUB

SUB GridBlock (Data$, Trow, Lcol, ClrThk, ClrOff, DrawOn)
FOR Make = 1 TO LEN(Data$)
 Data1 = ASC(MID$(Data$, Make, 1))
 BlockCol = Lcol + Make - 1
 FOR Make2 = 0 TO 7
  Data2 = Data1 \ (2 ^ Make2) AND 1
  BlockRow = Trow + Make2
  IF Data2 THEN
   LandGrid(BlockRow, BlockCol) = ClrThk
  ELSEIF ClrOff <> -1 THEN LandGrid(BlockRow, BlockCol) = ClrOff
  END IF
  IF DrawOn THEN BlockShow BlockRow, BlockCol
NEXT Make2, Make
END SUB

SUB GridLine (VY1pos, HX1pos, VY2pos, HX2pos, ClrThk, DrawOn)
VYdir = VY2pos - VY1pos
HXdir = HX2pos - HX1pos
IF SGN(VYdir) > SGN(HXdir) THEN
 FOR Make = 0 TO VYdir STEP SGN(VYdir) OR 1
  BlockRow = Make + VY1pos
  BlockCol = HX1pos
  LandGrid(BlockRow, BlockCol) = ClrThk
  IF DrawOn THEN BlockShow BlockRow, BlockCol
 NEXT Make
ELSE
 FOR Make = 0 TO HXdir STEP SGN(HXdir) OR 1
  BlockCol = Make + HX1pos
  BlockRow = VY1pos
  LandGrid(BlockRow, BlockCol) = ClrThk
  IF DrawOn THEN BlockShow BlockRow, BlockCol
 NEXT Make
END IF
END SUB

SUB GridSquare (VY1pos, HX1pos, VY2pos, HX2pos, Filled, ClrThk, DrawOn)
VYdir = SGN(VY2pos - VY1pos) OR 1
HXdir = SGN(HX2pos - HX1pos) OR 1
IF Filled THEN
 FOR BlockRow = VY1pos TO VY2pos STEP VYdir
  FOR BlockCol = HX1pos TO HX2pos STEP HXdir
   LandGrid(BlockRow, BlockCol) = ClrThk
   IF DrawOn THEN BlockShow BlockRow, BlockCol
  NEXT BlockCol
 NEXT BlockRow
ELSE
 FOR BlockCol = HX1pos TO HX2pos STEP HXdir: LandGrid(VY1pos, BlockCol) = ClrThk: IF DrawOn THEN BlockShow VY1pos, BlockCol
 NEXT BlockCol
 FOR BlockCol = HX1pos TO HX2pos STEP HXdir: LandGrid(VY2pos, BlockCol) = ClrThk: IF DrawOn THEN BlockShow VY2pos, BlockCol
 NEXT BlockCol
 FOR BlockRow = VY1pos TO VY2pos STEP VYdir: LandGrid(BlockRow, HX1pos) = ClrThk: IF DrawOn THEN BlockShow BlockRow, HX1pos
 NEXT BlockRow
 FOR BlockRow = VY1pos TO VY2pos STEP VYdir: LandGrid(BlockRow, HX2pos) = ClrThk: IF DrawOn THEN BlockShow BlockRow, HX2pos
 NEXT BlockRow
END IF
END SUB

SUB GridText (Data$, Trow, Lcol, ClrThk, DrawOn)
DEF SEG = &HF000
Data1 = ASC(Data$)
FOR Make = 0 TO 6
 Data2 = PEEK(&HFA6E + (Data1 * 8) + Make)
 BlockRow = Trow + Make
 FOR Make2 = 1 TO 7
  Data3 = Data2 \ (2 ^ Make2) AND 1
  BlockCol = Lcol + 7 - Make2
  IF Data3 THEN LandGrid(BlockRow, BlockCol) = ClrThk
NEXT Make2, Make
IF DrawOn THEN BlockShowRange Trow, Trow + 6, Lcol, Lcol + 6
END SUB

SUB Intro

SCREEN , , 1, 0
GridSquare 0, 0, 23, 39, 0, 7, 1
Text$ = "CRAB"
FOR Make = 1 TO LEN(Text$)
 GridText MID$(Text$, Make, 1), 5, Make * 8 - 3, 1, 1
NEXT
Text$ = "SHOT"
FOR Make = 1 TO LEN(Text$)
 GridText MID$(Text$, Make, 1), 13, Make * 8 - 3, 4, 1
NEXT

TextCenter 25, "Press almost any key to continue"
PLAY "L15MB": SoundFXnew "CCEEFEC", 1: SoundFXplay

ball.Trow = 50: ball.Lcol = 3: ball.Vdir = 17: ball.Hdir = 21
DO
 BallRepos ball
 WAIT &H3DA, 8: PCOPY 1, 0
 WHILE INKEY$ = "": WEND
LOOP UNTIL INP(96) = 1
'PCOPY 1, 0

END SUB

SUB LoadLevel
END SUB

SUB MainMenu (ExitSign)

SELECT CASE MenuFunction
END SELECT
ExitSign = 0
END SUB

SUB PlaySim (ExitSign)

SCREEN , , 1, 0

DO
CheckKeys:
 SELECT CASE INKEY$
 CASE CHR$(27): MenuFunction = 0: ExitSign = -2: EXIT DO
 CASE " ": Pause = Pause XOR 1: GOSUB PlaySimPause
 END SELECT
 IF Pause THEN GOTO CheckKeys

 SELECT CASE INP(96)
 CASE 75: DirMessage = 1
 CASE 77: DirMessage = 2
 CASE ELSE: DirMessage = 0
 END SELECT
'Check keyboard stuff

 CrabRepos PlayerCrab, DirMessage

'Move ball
'Check ball to see if it has gone beyond level
 GOSUB CopyScreen
LOOP
EXIT SUB

PlaySimPause:
IF Pause THEN
 DRAW "C15BM110,89M+6,+25M+6,-2M-3,-11M+7,-2M+3,-8M-9,-6M-9,+3 BM117,92M+1,+3M+4,-2M-5,-2BM-1,+0P12,15"
 DRAW "C15BM128,110M+8,-25M+7,+1M+6,+26M-6,+2M-2,-9M-5,+0M-2,+7M-5,-2 BM137,100M+2,-5M+2,+5M-3,+0BM-1,+1P14,15"
 DRAW "C15BM150,88M+2,+19M+9,+7M+9,-8M-3,-19M-5,+1M+1,+15M-5,+1M-2,-18M-6,+2BM+1,+0P10,15"
 DRAW "C15BM+22,+21M+2,+5M+14,-2M+2,-11M-11,-7M+11,-3M-5,-6M-14,+7M+9,+12M+0,+3M-7,+2BM+1,+0P9,15"
 DRAW "C15BM194,89M-1,+20M+12,+5M+4,-7M-9,-2M+0,-3M+9,+0M+0,-6M-9,+0M+0,-2M+9,-3M-5,-6M-9,+4BM+1,+0P13,15"
 GOSUB CopyScreen
 DO UNTIL INP(96) <> 57: null$ = INKEY$: LOOP
ELSE
 DO UNTIL INP(96) <> 57: null$ = INKEY$: LOOP
 BlockShowRange 10, 14, 13, 26
 GOSUB CopyScreen
END IF
RETURN

CopyScreen: WAIT &H3DA, 8: PCOPY 1, 0: RETURN

END SUB

SUB SoundFXnew (Data$, Filled) STATIC
IF Filled THEN SoundData$ = Data$: SoundPos = 0 ELSE SoundData$ = SoundData$ + Data$
PLAY ON
END SUB

SUB SoundFXplay
IF PLAY(0) < 10 THEN REM PLAY MID$(SoundData$, SoundPos + 1, 1)
IF SoundPos >= LEN(SoundData$) THEN PLAY OFF ELSE SoundPos = SoundPos + 1
END SUB

SUB TextCenter (VYpos, Text$)
IF LEN(Text$) > 40 THEN LOCATE VYpos, 1: PRINT LEFT$(Text$, 40);  ELSE LOCATE VYpos, (40 - LEN(Text$)) \ 2 + 1: PRINT Text$;
END SUB

