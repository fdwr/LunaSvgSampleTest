DEFINT A-Z
DECLARE FUNCTION SOUNDS ()
DECLARE FUNCTION WAITKEY$ ()
DECLARE SUB WaitMenu (Text$, UserChoice, Urow, Lcol, Rcol)
DECLARE FUNCTION STRNG2$ (Length%, Quote$)
DECLARE FUNCTION STRNG3$ (Leng!, Quote$)
DECLARE FUNCTION COUNTS (Text$, Element$)
DECLARE SUB MULTI (Urow, Lcol, Drow, Rcol, Fore, Back, TitC, TexC, Titl$, Text$)
DECLARE SUB DrawNewBox (Urow, Drow, Lcol, Rcol, Light, Dark, Area, Side)
DECLARE SUB EraseOldBox (Urow%, Drow%, Lcol%, Rcol%, OldUrow%, OldDrow%, OldLcol%, OldRcol%)
DECLARE SUB OptionBox (Vhit, Hwid, Title$, Urow, Drow, Lcol, Rcol)
DECLARE SUB ScoreBox (Sign$(), Score%(), Plrs%, Turn%, Mode%)
DECLARE SUB PlayBox (Vhit, Hwid, Urow, Drow, Lcol, Rcol)
DECLARE SUB ShowText (Text$, Urow, Drow, Lcol, Rcol)

DIM Sign$(0 TO 3), Score(0 TO 3), Plrs(0 TO 3)
CONST Free$ = "ÿ", MaxPts = 57, ColrHigh = 8, ColrLow = 7, ColrFore = 1, ColrBack = 3, ColrText = 15, ColrCrsr = 2
BrdWin = 3: BrdLen = 3: BrdHit = 3

'3x3 Norm "@ABCDEFGH@CFADGBEH@DHBDF"- 123 456 789 147 258 369 159 357
'Diagonal "@DBBDH@DFFDHAEGEGCGCACAE"- 153 359 157 759 268 684 842 426
RANDOMIZE TIMER
SCREEN 0: LOCATE , , 0
COLOR , ColrBack: CLS

GOSUB BrdClr
GOSUB CorrectSigns
GOSUB MakeBoard
ScoreBox Sign$(), Score(), Plrs, Turn, 1

MainMenu:
OptionBox 4, 26, "Main Menu", Urow, Drow, Lcol, Rcol
UserChoice = 0
DO
 WaitMenu "Start the game/Change players details/Define board dimensions/Stop wasting time/", UserChoice, Urow, Lcol, Rcol
 SELECT CASE UserChoice
 CASE -1, 3: SYSTEM
 CASE 0: EXIT DO
 CASE 1: GOSUB PlayerDetails: GOTO MainMenu
 CASE 2: GOSUB GetBoard: GOTO MainMenu
 CASE ELSE
 END SELECT
LOOP

WhoFirst:
OptionBox 4, 26, "Who Starts", Urow, Drow, Lcol, Rcol
UserChoice = 0
DO
 WaitMenu "Player" + STR$(Turn + 1) + " player starts/Random choose the first turn/Jump to next player/Return to main menu/", UserChoice, Urow, Lcol, Rcol
 SELECT CASE UserChoice
 CASE -1, 3: GOTO MainMenu
 CASE 0: EXIT DO
 CASE 1
  OptionBox 1, 24, "Bit Flip", Urow, Drow, Lcol, Rcol
  Turn = INT(RND * Plrs):
  ShowText " Player" + STR$(Turn + 1) + " goes first...", Urow, Drow, Lcol, Rcol
  a# = TIMER: DO: LOOP UNTIL INKEY$ > "" OR TIMER - a# > 3
  EXIT DO
 CASE 2
  IF Plrs THEN Turn = (Turn + 1) MOD Plrs
  ScoreBox Sign$(), Score(), Plrs, Turn, 0
 END SELECT
LOOP
GOSUB BrdClr: GOSUB BrdShow

GamePrompt:
GameInProgress = -1
ScoreBox Sign$(), Score(), Plrs, Turn, 0
DO
 Title$ = "Player" + STR$(Turn + 1) + " for " + Sign$(Turn)
 IF COUNTS(Brd$, Free$) = 1 THEN
  Spot = INSTR(Brd$, Free$)
 ELSEIF Plrs THEN
  KeyDetect = 0
  IF Plrs(Turn) = 0 THEN GOSUB Comptr ELSE IF Plrs(Turn) = 1 THEN GOSUB GamePlayer
 END IF
 
 IF KeyDetect = 0 THEN kbrd$ = INKEY$
 SELECT CASE kbrd$
 CASE CHR$(0) + "=": GOSUB PlayerDetails: IF KeyDetect GOTO GamePrompt
 CASE CHR$(27): GameInProgress = 0: GOSUB BrdShow: GOTO WhoFirst
 CASE ELSE: IF KeyDetect GOTO GamePrompt
 END SELECT
 
 IF Spot > 0 AND Spot <= LEN(Brd$) THEN MID$(Brd$, Spot, 1) = Sign$(Turn)
 GOSUB BrdShow
 GOSUB WhoWon
 IF Win OR INSTR(1, Brd$, Free$) = 0 THEN
  GOSUB Winr
  IF Win THEN IF Score(Win - 1) + 1 > MaxPts THEN Score(Win - 1) = 1 ELSE Score(Win - 1) = Score(Win - 1) + 1
  ScoreBox Sign$(), Score(), Plrs, Turn, 0
  IF Win THEN Title$ = "Point for player " + Sign$(Win - 1) ELSE Title$ = "No wins"
  OptionBox 3, 22, Title$, Urow, Drow, Lcol, Rcol
  UserChoice = 0
  DO
   GameInProgress = 0
   WaitMenu "Play another game/Reset the options/Quit this silliness/", UserChoice, Urow, Lcol, Rcol
   SELECT CASE UserChoice
   CASE -1, 2: SYSTEM
   CASE 0: GOSUB BrdClr: GOSUB BrdShow: GOTO GamePrompt
   CASE 1: GOTO MainMenu
   END SELECT
  LOOP
  Win = 0
 END IF
 IF Plrs THEN Turn = (Turn + 1) MOD Plrs
LOOP
GOTO GamePrompt

GamePlayer:
InfoPage = 0: GOSUB GamePlayerShow
IF INSTR(1, Brd$, Free$) = 0 THEN RETURN
DO
 GOSUB BrdShow: kbrd$ = WAITKEY$
 SELECT CASE kbrd$
 CASE CHR$(0) + "P": IF BrdCrsr(1) < BrdHit - 1 THEN BrdCrsr(1) = BrdCrsr(1) + 1
 CASE CHR$(0) + "H": IF BrdCrsr(1) > 0 THEN BrdCrsr(1) = BrdCrsr(1) - 1
 CASE CHR$(0) + "M": IF BrdCrsr(0) < BrdLen - 1 THEN BrdCrsr(0) = BrdCrsr(0) + 1
 CASE CHR$(0) + "K": IF BrdCrsr(0) > 0 THEN BrdCrsr(0) = BrdCrsr(0) - 1
 CASE CHR$(0) + "<": GOSUB Comptr: BrdCrsr(1) = (Spot - 1) \ BrdLen: BrdCrsr(0) = Spot - (BrdCrsr(1) * BrdLen) - 1: GOTO GamePlayer
 CASE CHR$(0) + "Q": HelpPage = HelpPage XOR 1: GOSUB GamePlayerShow
 CASE CHR$(0) + "I": HelpPage = HelpPage XOR 1: GOSUB GamePlayerShow
 CASE CHR$(13), " ", Sign$(Turn): IF kbrd$ = CHR$(13) THEN EXIT DO ELSE WHILE INP(96) = 57: kbrd$ = INKEY$: WEND: IF INP(96) = 185 THEN EXIT DO
 CASE ELSE: KeyDetect = -1: RETURN
 END SELECT
LOOP
Spot = (BrdCrsr(1) * BrdLen) + BrdCrsr(0) + 1
IF MID$(Brd$, Spot, 1) <> Free$ THEN
 OptionBox 2, 32, "Malfunction in player's brain", Urow, Drow, Lcol, Rcol
 ShowText "Choose an other space/That one is already filled!", Urow, Drow, Lcol + 1, Rcol - 1
 kbrd$ = WAITKEY$: GOTO GamePlayer
END IF
KeyDetect = 0
RETURN
GamePlayerShow:
 OptionBox 4, 38, Title$, Urow, Drow, Lcol, Rcol
 SELECT CASE HelpPage
 CASE 0: Quote$ = "Player: Use the arrow keys to move/the your sign position, Enter or/Space to set it, or the Escape key/to abort this game.           PgDn"
 CASE 1: Quote$ = "PgUp/F1=Shows absolutely no help at all/F2=Gets a position from the program/F3=Lets you edit players details/"
 END SELECT
 ShowText Quote$, Urow, Drow, Lcol + 1, Rcol - 1
RETURN

Comptr:
OptionBox 3, 30, Title$, Urow, Drow, Lcol, Rcol
ShowText "Computer: Searching through the board patterns for an/add\block space to put sign", Urow, Drow, Lcol + 1, Rcol - 1
IF INSTR(1, Brd$, Free$) = 0 THEN RETURN ELSE Spot = 0
FOR Check = 0 TO Plrs - 1
 Sign$ = Sign$((Turn + Check) MOD Plrs)
 IF COUNTS(Brd$, Sign$) >= BrdWin - 1 THEN
  FOR Look = 1 TO LEN(Win$) STEP BrdWin
   Row$ = "": FOR ChkSign = 0 TO BrdWin - 1: Row$ = Row$ + MID$(Brd$, ASC(MID$(Win$, Look + ChkSign, 1)) - 63, 1): NEXT ChkSign
   IF INSTR(Row$, Free$) THEN
    FOR ChkSign = 1 TO BrdWin
     row2$ = STRING$(BrdWin, Sign$): MID$(row2$, ChkSign, 1) = Free$: IF row2$ = Row$ THEN Spot = ASC(MID$(Win$, Look + ChkSign - 1, 1)) - 63: RETURN
    NEXT
   END IF
  NEXT Look
 END IF
NEXT Check
IF Spot = 0 THEN DO: Spot = INT(RND * LEN(Brd$) + 1): LOOP UNTIL MID$(Brd$, Spot, 1) = Free$
RETURN

BrdShow:
COLOR ColrText, ColrFore
FOR Vrow = 0 TO BrdHit - 1
 FOR Hcol = 0 TO BrdLen - 1
  LOCATE Vrow * 2 + BrdUrow, Hcol * 4 + BrdLencol, 0
  PRINT " " + MID$(Brd$, Vrow * BrdLen + Hcol + 1, 1) + " "
NEXT Hcol, Vrow
IF GameInProgress AND BrdHit > 0 AND BrdLen > 0 THEN
 LOCATE BrdCrsr(1) * 2 + BrdUrow, BrdCrsr(0) * 4 + BrdLencol
 COLOR ColrFore, ColrCrsr: PRINT "Ý";
 COLOR ColrText: PRINT MID$(Brd$, BrdCrsr(1) * BrdLen + BrdCrsr(0) + 1, 1);
 COLOR ColrFore: PRINT "Þ";
END IF
RETURN

WhoWon:
Win = 0: WinRow$ = ""
FOR Look = 1 TO LEN(Win$) STEP BrdWin
 Row$ = "": FOR ChkSign = 0 TO BrdWin - 1: Row$ = Row$ + MID$(Brd$, ASC(MID$(Win$, Look + ChkSign, 1)) - 63, 1): NEXT ChkSign: Lef$ = LEFT$(Row$, 1)
 IF Row$ = STRING$(BrdWin, Lef$) THEN
  FOR ChkSign = 0 TO Plrs - 1
   IF Sign$(ChkSign) = Lef$ THEN Win = ChkSign + 1: FOR ChkSign = 0 TO BrdWin - 1: WinRow$ = WinRow$ + MID$(Win$, Look + ChkSign, 1): NEXT ChkSign: RETURN
  NEXT ChkSign
 END IF
NEXT Look
RETURN

Winr:
FOR Vrow = 0 TO BrdHit - 1
 FOR Hcol = 0 TO BrdLen - 1
  IF INSTR(WinRow$, CHR$(Vrow * BrdLen + Hcol + 64)) THEN LOCATE Vrow * 2 + BrdUrow, Hcol * 4 + BrdLencol + 1, 0: COLOR 12: PRINT MID$(Brd$, Vrow * BrdLen + Hcol + 1, 1)
NEXT Hcol, Vrow
IF SOUNDS THEN
 IF Win = 0 THEN FOR s = 2000 TO 1000 STEP -10: SOUND 37 + s, .023: NEXT: FOR s = 1001 TO 2000 STEP 10: SOUND 37 + s, .023: NEXT
 IF Win > 0 THEN IF Plrs(Win - 1) = 0 THEN FOR s = 1 TO 2000 STEP 10: SOUND 37 + s, .023: NEXT
 IF Win > 0 THEN FOR s = 2000 TO 1 STEP -10: SOUND 37 + s, .023: NEXT
END IF
RETURN

BrdClr: Brd$ = STRING$(BrdHit * BrdLen, Free$): RETURN

CorrectSigns:
Plrs = 0
FOR Chk = 0 TO 3
 IF Sign$(Chk) = "" THEN
  FOR ChkSign = Chk + 1 TO 3
   IF Sign$(ChkSign) > "" THEN SWAP Sign$(Chk), Sign$(ChkSign): SWAP Plrs(Chk), Plrs(ChkSign): SWAP Score(Chk), Score(ChkSign): Plrs = Plrs + 1: EXIT FOR
  NEXT
 ELSE Plrs = Plrs + 1
 END IF
NEXT Chk
IF Sign$(0) = "" THEN Sign$(0) = "X": Plrs(0) = 1: Plrs = Plrs + 1
IF Sign$(1) = "" THEN Plrs(1) = 0: Plrs = Plrs + 1: IF Sign$(0) = "X" THEN Sign$(1) = "O" ELSE Sign$(1) = "X"
'IF Turn > Plrs THEN Turn = Plrs
RETURN

MakeBoard:
GOSUB BrdClr
FOR Spot = 1 TO LEN(Brd$)
 FOR Rows = 1 TO 4
  Row$ = "": Chk = Spot
  FOR Look = 1 TO BrdWin
   Yes = 0
   SELECT CASE Rows
   CASE 1: Sign = 1: IF INT((Chk - 1) / BrdLen) = INT((Spot - 1) / BrdLen) THEN Yes = -1
   CASE 2: Sign = BrdLen: IF Chk MOD BrdLen = Spot MOD BrdLen THEN Yes = -1
   CASE 3: Sign = BrdLen + 1: IF INT((Chk - 1) / BrdLen) - ((Chk - 1) MOD BrdLen) = INT((Spot - 1) / BrdLen) - ((Spot - 1) MOD BrdLen) THEN Yes = -1
   CASE 4: Sign = BrdLen - 1: IF INT((Chk - 1) / BrdLen) + ((Chk - 1) MOD BrdLen) = INT((Spot - 1) / BrdLen) + ((Spot - 1) MOD BrdLen) THEN Yes = -1
   END SELECT
   IF Yes AND Chk > 0 AND Chk <= LEN(Brd$) THEN Row$ = Row$ + CHR$(Chk + 63) ELSE EXIT FOR
   Chk = Chk + Sign
  NEXT Look
  IF LEN(Row$) = BrdWin THEN
   FOR Look = 1 TO LEN(Win$) STEP BrdWin
    IF MID$(Win$, Look, BrdWin) = Row$ THEN Yes = 0: EXIT FOR ELSE Yes = -1
   NEXT Look
   IF Yes THEN Win$ = Win$ + Row$
  END IF
 NEXT Rows
NEXT Spot
PlayBox BrdHit * 2 - 1, BrdLen * 4 - 1, BrdUrow, BrdDrow, BrdLencol, BrdRcol
ShowText STRNG3$(BrdHit - .5, "   " + STRNG2$((BrdLen - 1) * 4, "³   ") + "ÄÄ" + STRNG2$((BrdLen - 1) * 4, "ÄÅÄÄ") + "Ä"), BrdUrow, BrdDrow, BrdLencol, BrdRcol
RETURN

PlayerDetails:
OptionBox 4, 76, "Player Details", Urow, Drow, Lcol, Rcol
ShowText "Arrow keys move cursor/Alphanumeric keys edit player details/Enter accepts settings/Esc returns to menu", Urow, Drow, Lcol + 27, Lcol + 49
UserChoice = 0: UserCol = 1: GOSUB PlayerDetailsShowAll
DO
 kbrd$ = WAITKEY$
 SELECT CASE kbrd$
 CASE "", CHR$(13): EXIT DO
 CASE CHR$(0) + "H": IF UserChoice > 0 THEN UserChoice = UserChoice - 1: GOSUB PlayerDetailsShow: MenuChoice = UserChoice: GOSUB PlayerDetailsShow
 CASE CHR$(0) + "P": IF UserChoice < 3 THEN UserChoice = UserChoice + 1: GOSUB PlayerDetailsShow: MenuChoice = UserChoice: GOSUB PlayerDetailsShow
 CASE CHR$(0) + "K": UserCol = (UserCol + 7) MOD 4: GOSUB PlayerDetailsShow
 CASE CHR$(0) + "M": UserCol = (UserCol + 1) MOD 4: GOSUB PlayerDetailsShow
 CASE "": IF NOT GameInProgress AND UserCol = 1 THEN Sign$(UserChoice) = "": GOSUB PlayerDetailsShow
 CASE " "
  IF UserCol = 2 THEN
   Plrs(UserChoice) = Plrs(UserChoice) XOR 1: GOSUB PlayerDetailsShow
  ELSEIF UserCol = 3 THEN
   Score(UserChoice) = 0: GOSUB PlayerDetailsShow
   ScoreBox Sign$(), Score(), Plrs, Turn, 1
  END IF
 CASE "!" TO "þ"
  IF UserCol = 0 THEN
   Chk = VAL(kbrd$) - 1
   IF Chk > -1 AND Chk < 4 AND Chk <> UserChoice THEN
    SWAP Sign$(UserChoice), Sign$(Chk): SWAP Plrs(UserChoice), Plrs(Chk): SWAP Score(Chk), Score(UserChoice)
    UserChoice = Chk: GOSUB PlayerDetailsShowAll
   END IF
  ELSEIF UserCol = 1 AND NOT GameInProgress THEN
   Chk = -1
   FOR ChkSign = 0 TO 3
    IF Sign$(ChkSign) = kbrd$ THEN Chk = ChkSign: EXIT FOR
   NEXT ChkSign
   IF Sign$(UserChoice) <> kbrd$ AND Chk = -1 THEN
    FOR ChkSign = 1 TO LEN(Brd$)
     IF MID$(Brd$, ChkSign, 1) = Sign$(UserChoice) THEN MID$(Brd$, ChkSign, 1) = kbrd$
    NEXT ChkSign
    Sign$(UserChoice) = kbrd$
    GOSUB PlayerDetailsShow
   ELSEIF Chk > -1 THEN
    FOR ChkSign = 1 TO LEN(Brd$)
     IF MID$(Brd$, ChkSign, 1) = Sign$(UserChoice) THEN MID$(Brd$, ChkSign, 1) = Sign$(Chk) ELSE IF MID$(Brd$, ChkSign, 1) = Sign$(Chk) THEN MID$(Brd$, ChkSign, 1) = Sign$(UserChoice)
    NEXT ChkSign
    SWAP Sign$(UserChoice), Sign$(Chk): GOSUB PlayerDetailsShowAll
   END IF
  END IF
 END SELECT
LOOP
GOSUB CorrectSigns
GOSUB BrdShow
ScoreBox Sign$(), Score(), Plrs, Turn, 1
RETURN
PlayerDetailsShowAll:
FOR MenuChoice = 0 TO 3: GOSUB PlayerDetailsShow: NEXT MenuChoice: MenuChoice = UserChoice
RETURN
PlayerDetailsShow:
FOR MenuCol = 0 TO 3
 SELECT CASE MenuCol
 CASE 0: TextCol = 1: Quote$ = LTRIM$(STR$(MenuChoice + 1)) + "."
 CASE 1: TextCol = 5: Quote$ = LEFT$("(" + Sign$(MenuChoice) + ")" + " ", 3)
 CASE 2: TextCol = 10: IF Plrs(MenuChoice) THEN Quote$ = "Player " ELSE Quote$ = "Program"
 CASE 3: TextCol = 20: Quote$ = RIGHT$(STR$(Score(MenuChoice)), 2)
 END SELECT
 LOCATE Urow + MenuChoice, TextCol + Lcol
 IF MenuCol = UserCol AND MenuChoice = UserChoice THEN
  COLOR ColrFore, ColrCrsr: PRINT "Ý";
  COLOR ColrText: PRINT Quote$;
  COLOR ColrFore: PRINT "Þ";
 ELSE
  COLOR ColrText, ColrFore: PRINT " "; Quote$; " ";
 END IF
NEXT MenuCol
SELECT CASE UserCol
CASE 0: Quote$ = "Press a number to / move player details / to an other position"
CASE 1: Quote$ = "Any character within/ normal typing range/ is valid for a sign/": IF NOT GameInProgress THEN Quote$ = Quote$ + "BckSpc removes player"
CASE 2: Quote$ = "Press space to toggle/ between program and/ player"
CASE 3: Quote$ = "Press space to reset/ the score"
END SELECT
ShowText Quote$, Urow, Drow, Lcol + 53, Rcol
RETURN

GetBoard:
OptionBox 4, 30, "Player Details", Urow, Drow, Lcol, Rcol
UserChoice = 0: UserCol = 1: Hwid = Rcol - Lcol - 1: GOSUB GetBoardShowAll
DO
 kbrd$ = WAITKEY$
 SELECT CASE kbrd$
 CASE "", CHR$(13): EXIT DO
 CASE CHR$(0) + "H": IF UserChoice > 0 THEN UserChoice = UserChoice - 1: GOSUB GetBoardShow: MenuChoice = UserChoice: GOSUB GetBoardShow
 CASE CHR$(0) + "P": IF UserChoice < 3 THEN UserChoice = UserChoice + 1: GOSUB GetBoardShow: MenuChoice = UserChoice: GOSUB GetBoardShow
 CASE "1" TO "8"
  Chk = VAL(kbrd$)
  SELECT CASE UserChoice
  CASE 0: IF Chk < 7 THEN BrdHit = Chk ELSE BrdHit = 6
  CASE 1: IF Chk < 9 THEN BrdLen = Chk ELSE BrdLen = 8
  CASE 2: IF Chk <= BrdHit OR Chk <= BrdLen AND Chk <> BrdWin THEN BrdWin = Chk
  END SELECT
  GOSUB GetBoardShow
  IF UserChoice <> 2 THEN
   IF BrdHit > BrdLen THEN Chk = BrdHit ELSE Chk = BrdLen
   IF BrdWin > Chk THEN BrdWin = Chk: MenuChoice = 2: GOSUB GetBoardShow: MenuChoice = UserChoice
  END IF
 END SELECT
LOOP
GOSUB MakeBoard
RETURN
GetBoardShowAll:
FOR MenuChoice = 0 TO 3: GOSUB GetBoardShow: NEXT MenuChoice: MenuChoice = UserChoice
RETURN
GetBoardShow:
SELECT CASE MenuChoice
CASE 0: Quote$ = "Board Height ùùùùù" + STR$(BrdHit) + " (1-6)"
CASE 1: Quote$ = "Board Length ùùùùù" + STR$(BrdLen) + " (1-8)"
CASE 2: Quote$ = "Row win length ùùù" + STR$(BrdWin) + " (1-?)"
CASE 3: Quote$ = "Return to main menu"
END SELECT
LOCATE Urow + MenuChoice, Lcol
IF MenuChoice = UserChoice THEN
 COLOR ColrFore, ColrCrsr: PRINT "Ý";
 COLOR ColrText: PRINT LEFT$(Quote$ + SPACE$(Hwid), Hwid);
 COLOR ColrFore: PRINT "Þ";
ELSE
 COLOR ColrText, ColrFore: PRINT " "; LEFT$(Quote$ + SPACE$(Hwid), Hwid); " ";
END IF
RETURN

FUNCTION COUNTS (Text$, Element$)
s = 1: e = LEN(Text$)
DO
 IF INSTR(s, Text$, Element$) THEN c = c + 1: s = INSTR(s, Text$, Element$) + 1 ELSE EXIT DO
LOOP UNTIL s >= e
COUNTS = c
END FUNCTION

SUB DrawNewBox (Urow, Drow, Lcol, Rcol, Light, Dark, Area, Side)

BorderWidth = Rcol - Lcol + 1
IF Side THEN
 COLOR Light, Area: LOCATE Urow, Lcol: PRINT "Û"; STRING$(BorderWidth - 2, 223); : COLOR Light, Dark: PRINT "ß";
 COLOR Light, Dark: LOCATE Drow, Lcol: PRINT "ß"; : COLOR Dark, Area: PRINT STRING$(BorderWidth - 2, 220); "Û";
ELSE
 COLOR Light, Area: LOCATE Urow, Lcol: PRINT STRING$(BorderWidth, 220);
 COLOR Dark: LOCATE Drow, Lcol: PRINT STRING$(BorderWidth, 223);
END IF
COLOR Light, Light
FOR Vrow = Urow + 1 TO Drow - 1: LOCATE Vrow, Lcol: PRINT "Û"; : NEXT Vrow
COLOR Dark, Dark
FOR Vrow = Urow + 1 TO Drow - 1: LOCATE Vrow, Rcol: PRINT "Û"; : NEXT Vrow
COLOR Area, Area
FOR Vrow = Urow + 1 TO Drow - 1: LOCATE Vrow, Lcol + 1: PRINT SPACE$(BorderWidth - 2); : NEXT Vrow

END SUB

SUB EraseOldBox (Urow, Drow, Lcol, Rcol, OldUrow, OldDrow, OldLcol, OldRcol)
COLOR ColrBack, ColrBack
IF Urow > OldUrow THEN RealUrow = Urow ELSE RealUrow = OldUrow
IF Drow < OldDrow THEN RealDrow = Drow ELSE RealDrow = OldDrow

IF Urow > OldUrow THEN FOR Vrow = OldUrow TO Urow - 1: LOCATE Vrow, OldLcol: PRINT SPACE$(OldRcol - OldLcol + 1); : NEXT
IF Lcol > OldLcol THEN FOR Vrow = RealUrow TO RealDrow: LOCATE Vrow, OldLcol: PRINT SPACE$(Lcol - OldLcol); : NEXT Vrow
IF Rcol < OldRcol THEN FOR Vrow = RealUrow TO RealDrow: LOCATE Vrow, Rcol + 1: PRINT SPACE$(OldRcol - Rcol); : NEXT Vrow
IF Drow < OldDrow THEN FOR Vrow = Drow + 1 TO OldDrow: LOCATE Vrow, OldLcol: PRINT SPACE$(OldRcol - OldLcol + 1); : NEXT

END SUB

SUB OptionBox (Vhit, Hwid, Title$, Urow, Drow, Lcol, Rcol) STATIC

Urow = 3: Drow = Vhit + 4
Lcol = 40 - (Hwid \ 2): Rcol = Lcol + Hwid + 1
OldLcol = 40 - (OldHwid \ 2): OldRcol = OldLcol + OldHwid + 1
OldUrow = 3: OldDrow = 4 + OldVhit

DrawNewBox Urow, Drow, Lcol, Rcol, ColrHigh, ColrLow, ColrFore, 1
EraseOldBox Urow, Drow, Lcol, Rcol, OldUrow, OldDrow, OldLcol, OldRcol

COLOR ColrText, ColrBack
LOCATE 2, 40 - (TitleLen \ 2): PRINT SPACE$(TitleLen);
IF Title$ > "" THEN LOCATE 2, 40 - (LEN(Title$) \ 2): PRINT Title$;

TitleLen = LEN(Title$)
OldHwid = Hwid
OldVhit = Vhit
Urow = Urow + 1
Drow = Drow - 1
Lcol = Lcol + 1
Rcol = Rcol - 1

END SUB

SUB PlayBox (Vhit, Hwid, Urow, Drow, Lcol, Rcol) STATIC

Urow = 12: Drow = Vhit + 13
Lcol = 40 - (Hwid \ 2): Rcol = Lcol + Hwid + 1
OldLcol = 40 - (OldHwid \ 2): OldRcol = OldLcol + OldHwid + 1
OldUrow = 12: OldDrow = 13 + OldVhit

DrawNewBox Urow, Drow, Lcol, Rcol, ColrHigh, ColrLow, ColrBack, 0
EraseOldBox Urow, Drow, Lcol, Rcol, OldUrow, OldDrow, OldLcol, OldRcol

COLOR ColrText, ColrBack
LOCATE 11, 35: PRINT "Playing Board";

OldHwid = Hwid
OldVhit = Vhit
Urow = Urow + 1
Drow = Drow - 1
Lcol = Lcol + 1
Rcol = Rcol - 1

END SUB

SUB ScoreBox (Sign$(), Score(), Plrs, Turn, Mode)

FOR Plyr = 0 TO 3
 IF Plyr AND 2 THEN Urow = 18 ELSE Urow = 12
 IF Plyr AND 1 THEN Lcol = 59 ELSE Lcol = 2
 Rcol = Lcol + 20: Drow = Urow + 4
 IF Plyr < Plrs THEN
  IF Mode THEN DrawNewBox Urow, Drow, Lcol, Rcol, ColrHigh, ColrLow, ColrBack, 0
  ShowText LEFT$(STRING$(Score(Plyr), "\") + SPACE$(38), 38), Urow + 1, Drow - 1, Lcol + 1, Rcol - 1
  IF Plyr = Turn THEN COLOR , ColrCrsr ELSE COLOR , ColrBack
  LOCATE Urow - 1, Lcol + 5: PRINT " Player " + Sign$(Plyr); " ";
  COLOR , ColrBack: PRINT " ";
 ELSEIF Mode THEN
  COLOR , ColrBack
  FOR Vrow = Urow TO Drow
   LOCATE Vrow, Lcol: PRINT SPACE$(22);
  NEXT Vrow
  LOCATE Urow - 1, Lcol + 5: PRINT "          ";
 END IF
NEXT Plyr

END SUB

SUB ShowText (Text$, Urow, Drow, Lcol, Rcol)

COLOR ColrText, ColrFore
Hwid = Rcol - Lcol + 1: Spos = 1: IF Hwid < 1 THEN Hwid = 0
FOR Vrow = Urow TO Drow
 LOCATE Vrow, Lcol
 Quote$ = MID$(Text$, Spos, Hwid + 1)
 ChoicePos = INSTR(Quote$, "/")
 IF ChoicePos THEN
  PRINT MID$(Quote$, 1, ChoicePos - 1); SPACE$(Hwid - ChoicePos + 1);
  Spos = ChoicePos + Spos
 ELSE
  PRINT LEFT$(Quote$ + SPACE$(Hwid), Hwid);
  IF Spos < LEN(Text$) THEN Spos = Spos + Hwid
 END IF
NEXT Vrow

END SUB

DEFSNG A-Z
FUNCTION SOUNDS%
DEF SEG = 0: SOUNDS = (PEEK(1047) AND 64)
END FUNCTION

FUNCTION STRNG2$ (Leng%, Quote$)
DO UNTIL LEN(Result$) + LEN(Quote$) > Leng%
Result$ = Result$ + Quote$
LOOP
IF Leng% > 0 THEN STRNG2$ = Result$ + LEFT$(Quote$, Leng% - LEN(Result$))
END FUNCTION

FUNCTION STRNG3$ (Leng!, Quote$)
FOR s = 1 TO INT(Leng!)
 Result$ = Result$ + Quote$
NEXT s
IF INT(Leng!) <> Leng! THEN Result$ = Result$ + LEFT$(Quote$, LEN(Quote$) * (Leng! - INT(Leng!)))
STRNG3$ = Result$
END FUNCTION

FUNCTION WAITKEY$
WHILE kbrd$ = "": kbrd$ = INKEY$: WEND
WAITKEY$ = kbrd$
END FUNCTION

DEFINT A-Z
SUB WaitMenu (Text$, UserChoice, Urow, Lcol, Rcol)

DO
 ChoicePos = INSTR(ChoicePos + 1, Text$, "/")
 IF ChoicePos = 0 THEN EXIT DO ELSE ChoicePos = ChoicePos + 1
 ChoicePos$ = ChoicePos$ + CHR$(ChoicePos)
LOOP
Hwid = Rcol - Lcol - 1: IF Hwid < 0 THEN Hwid = 0

FOR MenuChoice = 0 TO LEN(ChoicePos$) - 1: GOSUB ShowMenu: NEXT MenuChoice

DO
 SELECT CASE INKEY$
 CASE CHR$(0) + "H": MenuChoice = UserChoice: IF UserChoice > 0 THEN UserChoice = UserChoice - 1: GOSUB ShowMenu: MenuChoice = UserChoice: GOSUB ShowMenu
 CASE CHR$(0) + "P": MenuChoice = UserChoice: IF UserChoice < LEN(ChoicePos$) - 1 THEN UserChoice = UserChoice + 1: GOSUB ShowMenu: MenuChoice = UserChoice: GOSUB ShowMenu
 CASE CHR$(13): EXIT DO
 CASE CHR$(27): UserChoice = -1: EXIT DO
 END SELECT
LOOP
EXIT SUB

ShowMenu:
 IF MenuChoice < 1 THEN ChoicePos = 1 ELSE ChoicePos = ASC(MID$(ChoicePos$, MenuChoice, 1))
 Quote$ = MID$(Text$, ChoicePos, ASC(MID$(ChoicePos$, MenuChoice + 1, 1)) - ChoicePos - 1)
 IF UserChoice = MenuChoice THEN COLOR , ColrCrsr ELSE COLOR , ColrFore
 LOCATE MenuChoice + Urow, Lcol: COLOR ColrFore: PRINT "Ý";
 COLOR ColrText: PRINT LEFT$(Quote$ + SPACE$(Hwid), Hwid);
 COLOR ColrFore: PRINT "Þ"
RETURN

END SUB

