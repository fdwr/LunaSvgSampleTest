'$DYNAMIC
DEFINT A-Z

DECLARE SUB ScrIntro (Sign)
DECLARE SUB ScrPlayGame (PlayerNum, ExitSign, GamePause, Animals() AS ANY, Players() AS ANY)
DECLARE SUB ScrOptions (Sign, PlayerNum, PlayerLives, LevelType)
DECLARE SUB ScrPGShowScore (Players() AS ANY, PlayerNum)
DECLARE SUB ScrGameOver (Sign, Players() AS ANY, PlayerNum)
DECLARE SUB NewPlay (PlayerNum, PlayerLives, Players() AS ANY)
DECLARE SUB NewGame (PlayerNum, LevelType, Animals() AS ANY, Players() AS ANY)
DECLARE SUB TransUserKeys (kbrd$, PlayerNum, PlayerInput() AS ANY)
DECLARE SUB HXcenterText (Text$, VYpos)
DECLARE SUB PromptNum (Word$, KeyIn$, Lim, Row, Col)
DECLARE SUB TimerWait ()

DECLARE SUB ArenaReset ()
DECLARE SUB CreateSpider (Animal AS ANY, VYpos, HXpos, XYdir, Speed, Acolr, Playr)
DECLARE SUB ObjectFly (Animal AS ANY, DirInput AS ANY)
DECLARE SUB ObjectSpider (Animal AS ANY, DirInput AS ANY)
DECLARE SUB ObjectSpark (Animal AS ANY)
DECLARE SUB WebPointGet (VYpos, HXpos, WebSet)
DECLARE SUB WebPointPut (VYpos, HXpos, WebSet, DrawOn)
DECLARE SUB WebPointSee (VYpos, HXpos)
DECLARE SUB ThinkSpider ()

ON ERROR GOTO ScreenErr
SCREEN 7: VIEW PRINT: PALETTE
ON ERROR GOTO 0
PLAY "MB"

TYPE InputInfo: VYdir AS INTEGER: HXdir AS INTEGER: END TYPE
TYPE PlayerInfo: Score AS INTEGER: Lives AS INTEGER: Crash AS INTEGER: Exist AS INTEGER: Object AS INTEGER: END TYPE
TYPE AnimalInfo
Atype AS STRING * 3
Acolr AS INTEGER
Exist AS INTEGER
Playr AS INTEGER
Frame AS INTEGER
Speed AS INTEGER
VYpos AS INTEGER
HXpos AS INTEGER
VYdir AS INTEGER
HXdir AS INTEGER
END TYPE

CONST FALSE = 0, TRUE = NOT FALSE, ALIVE = 3, DYING = 2, DEAD = 1, ERASED = 0
DIM SHARED ScreenVYoff, ScreenHXoff
REDIM SHARED WebGrid(0 TO 179, 0 TO 15) AS INTEGER'180x240
REDIM Animals(1 TO 8) AS AnimalInfo, Players(1 TO 4) AS PlayerInfo
ScreenVYoff = 9: ScreenHXoff = 40

'Main Play Game Loop
ScrIntro Sign
IF Sign = -1 THEN
 GameDone = TRUE
ELSEIF Sign = 1 THEN
 ScrOptions Sign, PlayerNum, PlayerLives, LevelType: IF Sign = 2 THEN ExitSign = -2 ELSE IF Sign = 1 THEN ExitSign = 1 ELSE ExitSign = -3
ELSE
 PlayerNum = 2: PlayerLives = 3: LevelType = 1: ExitSign = -2
END IF
DO UNTIL GameDone
 SELECT CASE ExitSign
 CASE 0: ScrPlayGame PlayerNum, ExitSign, GamePause, Animals(), Players()
 CASE 1: ScrGameOver Sign, Players(), PlayerNum
  IF Sign = 2 THEN ExitSign = -2 ELSE IF Sign = 1 THEN ExitSign = 2 ELSE ExitSign = -3
 CASE 2: ScrOptions Sign, PlayerNum, PlayerLives, LevelType
  IF Sign = 2 THEN ExitSign = -2 ELSE IF Sign = 1 THEN ExitSign = 1 ELSE ExitSign = -3
 CASE -1: NewGame PlayerNum, LevelType, Animals(), Players(): ExitSign = 0
 CASE -2: NewPlay PlayerNum, PlayerLives, Players(): ExitSign = -1
 CASE -3: GameDone = TRUE
 CASE ELSE: BEEP: STOP: END
 END SELECT
LOOP

EndIt:
SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS : SYSTEM

ScreenErr:
SCREEN 0: COLOR 7, 0: CLS
LOCATE 11, 14: PRINT "Your Video Adapter mode and options could not be set"
LOCATE 12, 14: PRINT "It must be a VGA adapter, having color and graphics"
RESUME EndIt

REM $STATIC
SUB ArenaReset
VIEW (0, 0)-(319, 199), 0
LINE (ScreenHXoff, ScreenVYoff)-(239 + ScreenHXoff, 179 + ScreenVYoff), 1, BF
REDIM WebGrid(0 TO 179, 0 TO 15)
END SUB

SUB CreateSpider (Animal AS AnimalInfo, VYpos, HXpos, XYdir, Speed, Acolr, Playr)
Animal.VYpos = VYpos
Animal.HXpos = HXpos
SELECT CASE XYdir
CASE 0: VYdir = -1: HXdir = 0
CASE 1: VYdir = 0: HXdir = 1
CASE 2: VYdir = 1: HXdir = 0
CASE 3: VYdir = 0: HXdir = -1
END SELECT
Animal.VYdir = VYdir: Animal.HXdir = HXdir
IF Speed = -1 THEN Animal.Speed = 6 ELSE Animal.Speed = Speed
Animal.Atype = "SPD"
Animal.Acolr = Acolr
Animal.Playr = Playr
Animal.Exist = ALIVE
END SUB

SUB HXcenterText (Text$, VYpos)
IF VYpos THEN LOCATE VYpos
IF LEN(Text$) > 40 THEN LOCATE , 1 ELSE LOCATE , (40 - LEN(Text$)) \ 2 + 1
PRINT LEFT$(Text$, 40);
END SUB

SUB NewGame (PlayerNum, LevelType, Animals() AS AnimalInfo, Players() AS PlayerInfo)
FOR Player = 1 TO PlayerNum
 Lives = Players(Player).Lives
 IF Players(Player).Exist = 0 THEN IF Lives > 0 THEN Players(Player).Exist = ALIVE: Players(Player).Lives = Lives - 1
 IF Players(Player).Exist THEN Players(Player).Object = Player: CreateSpider Animals(Player), 90, 120, Player - 1, -1, (Player MOD 6) + 9, Player
NEXT Player
ArenaReset
END SUB

SUB NewPlay (PlayerNum, PlayerLives, Players() AS PlayerInfo)
FOR InputGet = 1 TO PlayerNum
 Players(InputGet).Exist = 1: Players(InputGet).Object = InputGet: Players(InputGet).Lives = PlayerLives
NEXT InputGet
END SUB

SUB ObjectSpark (Animal AS AnimalInfo)
: EXIT SUB 'Under construction
VYpos = Animal.VYpos
HXpos = Animal.HXpos
VYdir = Animal.VYdir: HXdir = Animal.HXdir
WebPointSee VYpos, HXpos
WebPointGet VYpos, HXpos, WebSet
IF WebSet THEN
 REDIM Sides(0 TO 3)
 WebPointGet VYpos - 1, HXpos, WebSet: Sides(0) = WebSet
 WebPointGet VYpos, HXpos - 1, WebSet: Sides(1) = WebSet
 WebPointGet VYpos + 1, HXpos, WebSet: Sides(2) = WebSet
 WebPointGet VYpos, HXpos + 1, WebSet: Sides(3) = WebSet
 RXYdir = -1
 IF VYdir < 0 THEN XYdir = 0 ELSE IF VYdir > 0 THEN XYdir = 2 ELSE IF HXdir < 0 THEN XYdir = 1 ELSE IF HXdir > 0 THEN XYdir = 3
 FOR InputGet = 0 TO 3
  IF Sides(InputGet) = 1 AND (XYdir AND 1) <> (InputGet AND 1) THEN RXYdir = InputGet
 NEXT InputGet
 IF RXYdir = -1 THEN IF Sides(XYdir) = 1 THEN RXYdir = XYdir ELSE RXYdir = -XYdir
 SELECT CASE RXYdir
 CASE 0: VYdir = -1: HXdir = 0
 CASE 1: VYdir = 0: HXdir = -1
 CASE 2: VYdir = 1: HXdir = 0
 CASE 3: VYdir = 0: HXdir = 1
 END SELECT
END IF
Animal.VYpos = Animal.VYpos + VYdir
Animal.HXpos = Animal.HXpos + HXdir
Animal.VYdir = VYdir: Animal.HXdir = HXdir

WebPointPut VYpos, HXpos, 7, 1
END SUB

SUB ObjectSpider (Animal AS AnimalInfo, DirInput AS InputInfo)
IF DirInput.VYdir < 0 AND NOT (Animal.VYdir > 0) THEN Animal.VYdir = -1: Animal.HXdir = 0 ELSE IF DirInput.VYdir > 0 AND NOT (Animal.VYdir < 0) THEN Animal.VYdir = 1: Animal.HXdir = 0
IF DirInput.HXdir < 0 AND NOT (Animal.HXdir > 0) THEN Animal.HXdir = -1: Animal.VYdir = 0 ELSE IF DirInput.HXdir > 0 AND NOT (Animal.HXdir < 0) THEN Animal.HXdir = 1: Animal.VYdir = 0
IF Animal.Frame >= Animal.Speed THEN
 'IF DirInput.VYdir < 0 AND Animal.VYdir > -1 THEN Animal.VYdir = -1 ELSE IF DirInput.VYdir > 0 AND Animal.VYdir < 1 THEN Animal.VYdir = 1
 'IF DirInput.HXdir < 0 AND Animal.HXdir > -1 THEN Animal.HXdir = -1 ELSE IF DirInput.HXdir > 0 AND Animal.HXdir < 1 THEN Animal.HXdir = 1

 IF Animal.VYdir OR Animal.HXdir THEN WebPointPut Animal.VYpos, Animal.HXpos, Animal.Acolr, 1
 Animal.VYpos = Animal.VYpos + Animal.VYdir
 Animal.HXpos = Animal.HXpos + Animal.HXdir
 WebPointGet Animal.VYpos, Animal.HXpos, WebSet
 IF WebSet THEN Animal.Exist = DEAD

 Animal.Frame = 0
ELSE Animal.Frame = Animal.Frame + 1
END IF
'Animate spider onto screen
END SUB

SUB PromptNum (Word$, KeyIn$, Lim, Row, Col)

Chng = 1

SELECT CASE KeyIn$
CASE "0" TO "9": IF LEN(Word$) + LEN(KeyIn$) <= Lim THEN Word$ = Word$ + KeyIn$: Chng = 1
CASE CHR$(8): IF Word$ > "" THEN Word$ = LEFT$(Word$, LEN(Word$) - 1): Chng = 1
CASE ELSE: KeyOut$ = kbrd$: Done = 1
END SELECT

IF Chng THEN LOCATE Row, Col: PRINT LEFT$(Word$ + "Ý" + SPACE$(Lim), Lim + 1);
END SUB

SUB ScrGameOver (Sign, Players() AS PlayerInfo, PlayerNum)

COLOR 15: CLS
LOCATE 1, 15: PRINT "Player Scores";
LOCATE 3, 10: COLOR 7: PRINT "Player  Crashes  Score";
GOSUB MainOverScores
GOSUB MainOverList
Sign = 0
DO
 SELECT CASE INKEY$
 CASE CHR$(0) + "H": UserChoice = (UserChoice + 3) MOD 4: GOSUB MainOverList
 CASE CHR$(0) + "P": UserChoice = (UserChoice + 1) MOD 4: GOSUB MainOverList
 CASE CHR$(13)
  SELECT CASE UserChoice
  CASE 0: Sign = 2
  CASE 1: Sign = 1
  CASE 2: FOR InputGet = 1 TO PlayerNum: Players(InputGet).Score = 0: Players(InputGet).Crash = 0: NEXT InputGet: GOSUB MainOverScores
  CASE 3: Sign = -1
  END SELECT
 CASE CHR$(27): Sign = -3
 END SELECT
LOOP UNTIL Sign
EXIT SUB

MainOverScores:
PlayerAlive = 0
FOR Player = 1 TO PlayerNum
 IF Players(Player).Lives > PlayerAlive THEN PlayerAlive = Players(Player).Lives
NEXT Player
FOR Player = 1 TO PlayerNum
 IF Players(Player).Exist AND Players(Player).Lives = PlayerAlive THEN COLOR 15: LOCATE Player + 4, 4: PRINT "WINNER";  ELSE COLOR 7
 LOCATE Player + 4, 11: PRINT "#" + LTRIM$(STR$(Player)); TAB(19); LEFT$(STR$(Players(Player).Crash), 3); TAB(28); STR$(Players(Player).Score); "   ";
NEXT Player
RETURN

MainOverList:
FOR InputGet = 0 TO 3
 IF InputGet = UserChoice THEN COLOR 15 ELSE COLOR 7
 LOCATE 19 + InputGet, 16: PRINT MID$("Play game   Set options Clear scoresQuit game", InputGet * 12 + 1, 12);
NEXT InputGet
RETURN
END SUB

SUB ScrIntro (Sign)

COLOR 15: CLS
LOCATE 1, 16: PRINT "WebWeave 1";
REDIM Animals(0 TO 7) AS AnimalInfo, AnimalInput(0 TO 7) AS InputInfo, Count(0 TO 7, 0 TO 1), Letr$(0 TO 7)
REDIM WebGrid(0 TO 179, 0 TO 15)
CreateSpider Animals(0), 21, 71, -1, 0, 12, 0: Letr$(0) = "¦LB•L&À€@"
CreateSpider Animals(1), 21, 134, -1, 0, 14, 0: Letr$(1) = "Ü‘\‚Ü‘\€À"
CreateSpider Animals(2), 60, 139, -1, 0, 10, 0: Letr$(2) = "&\‘×‚W‘Ü"
CreateSpider Animals(3), 65, 37, -1, 0, 12, 0: Letr$(3) = "¦LB•L&À€@"
CreateSpider Animals(4), 65, 100, -1, 0, 14, 0: Letr$(4) = "Ü‘\‚Ü‘\€À"
CreateSpider Animals(5), 104, 105, -1, 0, 10, 0: Letr$(5) = "BV‘B”ÂÙ"
CreateSpider Animals(6), 65, 139, -1, 0, 9, 0: Letr$(6) = "ŒEŒEŒDEEÀ€@"
CreateSpider Animals(7), 65, 202, -1, 0, 13, 0: Letr$(7) = "Ü‘\‚Ü‘\€À"
COLOR 7: HXcenterText "Created by Dwayne Robinson", 25
GOSUB MainIntroList
Sign = 0
DO
 FOR InputGet = 0 TO 7
  Count = Count(InputGet, 1)
  IF Count(InputGet, 0) THEN
   Count(InputGet, 0) = Count(InputGet, 0) - 1
  ELSEIF Count < LEN(Letr$(InputGet)) THEN
   Count(InputGet, 1) = Count + 1
   DirInput = ASC(MID$(Letr$(InputGet), Count + 1, 1))
   SELECT CASE DirInput \ 64
   CASE 0: AnimalInput(InputGet).VYdir = -1: AnimalInput(InputGet).HXdir = 0
   CASE 1: AnimalInput(InputGet).VYdir = 0: AnimalInput(InputGet).HXdir = 1
   CASE 2: AnimalInput(InputGet).VYdir = 1: AnimalInput(InputGet).HXdir = 0
   CASE 3: AnimalInput(InputGet).VYdir = 0: AnimalInput(InputGet).HXdir = -1
   END SELECT
   Count(InputGet, 0) = DirInput AND 63
  END IF
 NEXT InputGet
 FOR AnimalAlive = 0 TO 7
  IF Animals(AnimalAlive).Exist = ALIVE THEN ObjectSpider Animals(AnimalAlive), AnimalInput(AnimalAlive)
 NEXT AnimalAlive
 SELECT CASE INKEY$
 CASE CHR$(0) + "H": UserChoice = (UserChoice + 2) MOD 3: GOSUB MainIntroList
 CASE CHR$(0) + "P": UserChoice = (UserChoice + 1) MOD 3: GOSUB MainIntroList
 CASE CHR$(13): SELECT CASE UserChoice: CASE 0: Sign = 2: CASE 1: Sign = 1: CASE 2: Sign = -1: END SELECT
 CASE CHR$(27): Sign = -1
 END SELECT
 TimerWait
LOOP UNTIL Sign
EXIT SUB
MainIntroList:
FOR InputGet = 0 TO 2
 IF InputGet = UserChoice THEN COLOR 15 ELSE COLOR 7
 LOCATE 19 + InputGet, 16: PRINT MID$("Start Game Set OptionsQuit Game", InputGet * 11 + 1, 11);
NEXT InputGet
RETURN
END SUB

SUB ScrOptions (Sign, PlayerNum, PlayerLives, LevelType)

COLOR 15: CLS
LOCATE 1, 18: PRINT "Options";
COLOR 7
FOR UserChoice = 0 TO 5
 GOSUB MainOptsList: GOSUB RsltCorrect: LOCATE Row, Col: GOSUB MainOptsChShow
NEXT UserChoice
GOSUB MainOptsList

ExitMenu = FALSE: Sign = 0
ChoiceChng = TRUE: NewChoice = 0
DO
 kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE ""
 CASE CHR$(0) + "H": ChoiceChng = TRUE: NewChoice = (UserChoice + 5) MOD 6
 CASE CHR$(0) + "P": ChoiceChng = TRUE: NewChoice = (UserChoice + 1) MOD 6
 CASE CHR$(0) + "K": ChoiceChng = TRUE: Word$ = LTRIM$(STR$(VAL(Word$) - 1))
 CASE CHR$(0) + "M": ChoiceChng = TRUE: Word$ = LTRIM$(STR$(VAL(Word$) + 1))
 CASE CHR$(13)
  SELECT CASE UserChoice: CASE 0 TO 3: Sign = 2: CASE 4: Sign = 1: CASE 5: Sign = -1: END SELECT: ExitMenu = TRUE
 CASE CHR$(27): Sign = FALSE: ExitMenu = TRUE
 END SELECT
 IF ChoiceChng OR ExitMenu THEN
  GOSUB RsltCorrect
  IF UserChoice <> NewChoice THEN
   GOSUB MainOptsChShow
   UserChoice = NewChoice: GOSUB MainOptsList
  END IF
  GOSUB MainOptsChShow
  ChoiceChng = FALSE
 END IF
LOOP UNTIL ExitMenu
EXIT SUB

RsltCorrect:
SELECT CASE UserChoice
CASE 0: IF Word$ > "4" THEN Word$ = "4" ELSE IF Word$ < "2" THEN Word$ = "2"
 PlayerNum = VAL(Word$)
CASE 1: IF VAL(Word$) < 1 THEN Word$ = "1" ELSE IF VAL(Word$) > 20 THEN Word$ = "20"
 PlayerLives = VAL(Word$)
CASE 2: IF VAL(Word$) < 1 THEN Word$ = "1"
 LevelType = VAL(Word$)
END SELECT
RETURN

MainOptsChShow:
 LOCATE Row, Col
 IF UserChoice <> NewChoice THEN
  COLOR 7: PRINT Text$;
  IF Lim THEN PRINT ": "; Word$; " ";
 ELSE
  COLOR 15: PRINT Text$;
  IF Lim THEN PRINT " "; Word$; " ";
 END IF
RETURN

MainOptsList:
SELECT CASE UserChoice
CASE 0: Row = 4: Lim = 1: Col = 12: Text$ = "Number of players": Word$ = LTRIM$(STR$(PlayerNum))
CASE 1: Row = 6: Lim = 2: Col = 8: Text$ = "Extra lives to start with": Word$ = LTRIM$(STR$(PlayerLives))
CASE 2: Row = 8: Lim = 1: Col = 15: Text$ = "Level type": Word$ = LTRIM$(STR$(LevelType))
CASE 3: Row = 19: Lim = 0: Col = 14: Text$ = "Accept Settings": Word$ = ""
CASE 4: Row = 20: Lim = 0: Col = 16: Text$ = "View Scores": Word$ = ""
CASE 5: Row = 22: Lim = 0: Col = 17: Text$ = "Quit Game": Word$ = ""
END SELECT
RETURN
END SUB

SUB ScrPGShowScore (Players() AS PlayerInfo, PlayerNum)
PlayerOfset = LBOUND(Players)
COLOR 15
LOCATE 2, 1: PRINT "Lives"; : LOCATE , 36: PRINT "Score";
LOCATE 14, 1: PRINT "Alive"; : LOCATE , 36: PRINT "Crash";
FOR Show = 0 TO UBOUND(Players) - PlayerOfset
 LOCATE 3 + Show, 1
 IF Show < PlayerNum THEN
  Player = Show + PlayerOfset
  IF Players(Player).Lives > 0 OR (Players(Player).Lives >= 0 AND Players(Player).Exist) THEN PRINT LEFT$(STR$(Players(Player).Lives), 3);  ELSE PRINT " --";
  LOCATE , 37: PRINT RIGHT$("  " + STR$(Players(Player).Score), 3);
  LOCATE 15 + Show, 1: IF Players(Player).Exist THEN PRINT "û Yes";  ELSE PRINT "X No ";
  LOCATE , 37: PRINT RIGHT$("  " + STR$(Players(Player).Crash), 3);
 ELSE PRINT "   "; : LOCATE , 37: PRINT "   ";
 END IF
NEXT Show
END SUB

SUB ScrPlayGame (PlayerNum, ExitSign, GamePause, Animals() AS AnimalInfo, Players() AS PlayerInfo)

ExitSign = 0
AnimalFirst = LBOUND(Animals)
AnimalLast = UBOUND(Animals)
REDIM PlayerInput(0 TO PlayerNum) AS InputInfo
DIM AnimalInput AS InputInfo
FOR InputGet = 1 TO PlayerNum
 Object = Players(InputGet).Object
 IF Object THEN Animals(Object).Playr = InputGet
NEXT InputGet
ScrPGShowScore Players(), PlayerNum
GamePause = TRUE: GOSUB MainPlayPause

'Get user inputs from the keyboard
MainPlayInputs:
 DO
  kbrd$ = INKEY$
  IF kbrd$ = "" THEN IF GamePause GOTO MainPlayInputs ELSE EXIT DO
  SELECT CASE kbrd$
  CASE CHR$(32): IF GamePause THEN GamePause = FALSE ELSE GamePause = TRUE
   GOSUB MainPlayPause
  CASE CHR$(27): ExitSign = 1
  CASE CHR$(0) + "G": ExitSign = 2
  CASE CHR$(0) + "_": ExitSign = -3
  END SELECT
'Check for an escape key, for menu or to quit game
  IF ExitSign THEN EXIT SUB
'Translate key presses into usable language
  TransUserKeys kbrd$, PlayerNum, PlayerInput()
 LOOP

'Animate all animals and objects
FOR AnimalAlive = AnimalFirst TO AnimalLast
 IF Animals(AnimalAlive).Exist = ALIVE THEN
  Player = Animals(AnimalAlive).Playr
  IF Player THEN
   SELECT CASE Animals(AnimalAlive).Atype
   CASE "SPD": ObjectSpider Animals(AnimalAlive), PlayerInput(Player)
   'CASE "SPK": ObjectSpark Animals(AnimalAlive)
   END SELECT
   PlayerInput(Player).VYdir = 0: PlayerInput(Player).HXdir = 0
  ELSE
   SELECT CASE Animals(AnimalAlive).Atype
   CASE "SPD": ObjectSpider Animals(AnimalAlive), PlayerInput(Player)
   'CASE "SPK": ObjectSpark Animals(AnimalAlive)
   END SELECT
  END IF
 END IF
NEXT AnimalAlive

'Update the player info if one has died including lives, score, and level
PlayerAlive = 0
FOR Player = 1 TO PlayerNum
 Object = Players(Player).Object
 IF Object THEN
  IF Animals(Object).Exist = DEAD THEN
   'PLAY "L64GECF"
   Players(Player).Exist = FALSE
   Players(Player).Crash = Players(Player).Crash + 1
   FOR InputGet = 1 TO PlayerNum
    IF InputGet <> Player AND Players(InputGet).Exist THEN Players(InputGet).Score = (Players(InputGet).Score + 1) MOD &H3E8
   NEXT InputGet
   ScrPGShowScore Players(), PlayerNum
  END IF
 END IF
 IF Players(Player).Exist THEN PlayerAlive = PlayerAlive + 1
NEXT Player

'Erase any `dead` animals from the list
FOR Animallive = AnimalFirst TO AnimalLast
 IF Animals(Animallive).Exist = DEAD THEN Animals(Animallive).Exist = ERASED
NEXT Animallive
IF PlayerAlive < 2 THEN GOTO MainPlayNextRound

'Wait for timer to tell the next anima-frame
TimerWait

GOTO MainPlayInputs
EXIT SUB

MainPlayPause:
LOCATE 1, 16: COLOR 15: IF GamePause = TRUE THEN PRINT "GAME PAUSED";  ELSE IF GamePause THEN PRINT "NEXT ROUND!" ELSE PRINT " Web Weave ";
RETURN

'Figure how many players are still in the game and whether to continue or quit
MainPlayNextRound:
GamePause = -2: GOSUB MainPlayPause: NowTime# = TIMER: DO UNTIL TIMER - NowTime# > 2 OR INKEY$ = " ": LOOP
Player = 0
FOR InputGet = 1 TO PlayerNum
 IF Players(InputGet).Exist THEN Player = Player + 1 ELSE IF Players(InputGet).Lives > 0 THEN Player = Player + 1
NEXT InputGet
IF Player < 2 THEN ExitSign = 1 ELSE ExitSign = -1
END SUB

SUB ThinkSpider
END SUB

DEFSNG A-Z
SUB TimerWait STATIC
 IF TimeStep THEN WAIT &H3DA, 8, 8: WAIT &H3DA, 8
 TimeStep = TimeStep XOR 1
END SUB

DEFINT A-Z
SUB TransUserKeys (kbrd$, PlayerNum, PlayerInput() AS InputInfo)
kbrd$ = UCASE$(kbrd$)
Player = 0
SELECT CASE kbrd$
CASE CHR$(0) + "H", CHR$(0) + "P", CHR$(0) + "K", CHR$(0) + "M": Player = 1
CASE "W", "S", "A", "D": Player = 2
CASE "I", "J", "K", "L": Player = 3
CASE "8", "5", "4", "6": Player = 4
END SELECT
IF Player < 1 OR Player > PlayerNum THEN EXIT SUB
SELECT CASE kbrd$
CASE CHR$(0) + "H", "W", "I", "8": PlayerInput(Player).VYdir = -1
CASE CHR$(0) + "P", "S", "K", "5": PlayerInput(Player).VYdir = 1
CASE CHR$(0) + "K", "A", "J", "4": PlayerInput(Player).HXdir = -1
CASE CHR$(0) + "M", "D", "L", "6": PlayerInput(Player).HXdir = 1
END SELECT
END SUB

SUB WebPointGet (VYpos, HXpos, WebSet)
IF VYpos >= LBOUND(WebGrid, 1) AND VYpos <= UBOUND(WebGrid, 1) THEN
 IF HXpos >= LBOUND(WebGrid, 2) * 15 AND HXpos < UBOUND(WebGrid, 2) * 15 + 15 THEN
  HXabs = HXpos \ 15
  HXmod = HXpos MOD 15
  WebSet = (WebGrid(VYpos, HXabs) \ (2& ^ HXmod)) AND 1
 ELSE WebSet = TRUE
 END IF
ELSE WebSet = TRUE
END IF
END SUB

SUB WebPointPut (VYpos, HXpos, WebSet, DrawOn)
IF VYpos >= LBOUND(WebGrid, 1) AND VYpos <= UBOUND(WebGrid, 1) THEN
 IF HXpos >= LBOUND(WebGrid, 2) * 15 AND HXpos < UBOUND(WebGrid, 2) * 15 + 15 THEN
  HXabs = HXpos \ 15
  HXmod = HXpos MOD 15
  IF WebSet THEN WebGrid(VYpos, HXabs) = WebGrid(VYpos, HXabs) OR 2& ^ HXmod ELSE WebGrid(VYpos, HXabs) = WebGrid(VYpos, HXabs) AND NOT (2& ^ HXmod)
  IF DrawOn THEN PSET (HXpos + ScreenHXoff, VYpos + ScreenVYoff), WebSet
 END IF
END IF
END SUB

SUB WebPointSee (VYpos, HXpos)
IF VYpos >= LBOUND(WebGrid, 1) AND VYpos <= UBOUND(WebGrid, 1) THEN
 IF HXpos >= LBOUND(WebGrid, 2) * 15 AND HXpos < UBOUND(WebGrid, 2) * 15 + 15 THEN
  HXabs = HXpos \ 15: HXmod = HXpos MOD 15
  WebSet = (WebGrid(VYpos, HXabs) \ (2& ^ HXmod)) AND 1
  IF WebSet THEN PSET (HXpos + ScreenHXoff, VYpos + ScreenVYoff), 15 ELSE PSET (HXpos + ScreenHXoff, VYpos + ScreenVYoff), 0
 END IF
END IF
END SUB

