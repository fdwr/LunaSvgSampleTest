DEFINT A-Z
DECLARE SUB NPROMPT (Frst$, Last$, KeyOut$, lim, Vis, Row, Col, Curp, Done)
DECLARE SUB SKIPLINE ()
SCREEN 0

LOCATE , , 0: COLOR 15: PRINT CHR$(13); TAB(27); "***** Game of Guess *****"
COLOR 7: PRINT "    This very simple game will randomly select a number, 1 thru whatever"
PRINT "    limit you set (fifty by default). You get as many tries as the limit"
PRINT "    is divided in half. That means that you get 25 chances to get a number"
PRINT "    within 1 thru 50. Each time you guess, the game will tell you if you"
PRINT "    guessed the number or wether you were too low or too high. When you use"
PRINT "    up all of your chances, it will tell you what the number was and ask"
PRINT "    you if you want to play again. Press Esc at any time to quit this game,"
PRINT "    or get help on what to do at any time by pressing the F1 key."
COLOR 15: LOCATE , 29: PRINT "Press any key to start";
SLEEP 30: WHILE INKEY$ > "": WEND
LOCATE , 29: PRINT SPACE$(22)

GetLimit:
  gameMode = 1: needRefresh = 1: Curp = -1
  DO
   IF needRefresh THEN COLOR 11: PRINT "    Choose an upper limit: "; : needRefresh = 0
   NPROMPT lim$, lim$, Key$, 5, 6, 0, 0, Curp, 0
   GOSUB KeyRespond
  LOOP UNTIL Key$ = CHR$(13): IF lim$ = "" THEN PRINT "50" ELSE PRINT
  IF LEN(lim$) >= 5 AND lim$ > "32767" THEN limit = 32767 ELSE limit = VAL(lim$)
  IF lim$ = "" OR limit < 1 THEN limit = 50
  PRINT CHR$(13); "    The range is 1 thru"; limit: PRINT "    Take your first guess"; CHR$(13)
  RANDOMIZE TIMER
  number = INT(RND * limit) + 1
  chances = limit \ 2
  preGes$ = ""
GuessIt:
  result = 0: Curp = -1: chance = 0
  DO
    gameMode = 2: needRefresh = 2
    DO
     IF needRefresh THEN COLOR 13: IF needRefresh = 2 THEN PRINT "ÄÄ ";  ELSE PRINT "À-> ";
     IF needRefresh THEN needRefresh = 0
     NPROMPT ges$, ges$, Key$, 5, 6, 0, 0, Curp, 0
     GOSUB KeyRespond
    LOOP UNTIL Key$ = CHR$(13) AND ges$ > ""
    preGes$ = ges$
    IF LEN(ges$) >= 5 AND ges$ > "32767" THEN result = -1 ELSE guess = VAL(ges$): GOSUB EvaluateGuess
    ges$ = ""
    IF result >= 0 THEN chance = chance + 1
    GOSUB ReactGuess
    IF result > 0 THEN SLEEP: IF INKEY$ = CHR$(27) GOTO EndGame ELSE PRINT : GOTO GetLimit
  LOOP
EvaluateGuess:
  IF guess = number THEN
    result = 2
  ELSEIF guess > limit OR guess < 1 THEN result = -1
  ELSE result = 0: IF chance >= chances - 1 THEN result = 1
  END IF
RETURN
ReactGuess:
  COLOR 7: LOCATE , 30
  SELECT CASE result
  CASE -1: PRINT "Out of range"
  CASE 0, 1
    IF guess < number THEN PRINT "Too low    (<)" ELSE PRINT "Too high   (>)"
    IF result THEN COLOR 12: PRINT "    Sorry, your"; chances; "chances are up - the number was"; number
  CASE 2: PRINT "Just right (=)": COLOR 9: PRINT "    You got it! You took"; chance; "guesses"
  END SELECT
RETURN
KeyRespond:
  IF Key$ = CHR$(0) + ";" THEN
    COLOR 7: SKIPLINE: needRefresh = 1
    SELECT CASE gameMode
    CASE 1: PRINT "   Enter a maximum number for the guessing range (the minimum is always 1)"
            PRINT "   Press Enter to confirm the number and procede, or if you simply press"
            PRINT "    Enter without a number in it, it will select a game of one thru fifty"
            PRINT "   Press Esc to quit this funny little game and go do other things"
    CASE 2: PRINT "   Type in your guess for the secret number and press Enter"
            PRINT "   Press up to recall your last guess and put it into the prompt"
            PRINT "   Press Esc to go back to setting the number limit"
            PRINT "   The current guessing range is 1 thru"; limit
            PRINT "   You have used"; chance; "guesse(s) so far"
    END SELECT
    PRINT
  ELSEIF Key$ = CHR$(27) THEN IF gameMode = 2 THEN SKIPLINE: RETURN GetLimit ELSE IF gameMode = 1 THEN RETURN EndGame
  ELSEIF Key$ = CHR$(0) + "H" AND gameMode = 2 THEN ges$ = preGes$: Curp = -1
  END IF
RETURN
EndGame: CLEAR : COLOR 7, 0: PRINT : END

SUB NPROMPT (Frst$, Last$, KeyOut$, lim, Vis, Row, Col, Curp, Done)
Chng = 1
Rslt$ = Frst$

IF Row = 0 THEN Row = CSRLIN
IF Col = 0 THEN Col = POS(0)
IF Curp = -1 THEN Curp = LEN(Rslt$)

DO
 Leng = LEN(Rslt$)

 Kbrd$ = INKEY$
 SELECT CASE Kbrd$
 CASE ""
 CASE "0" TO "9"
  IF LEN(Kbrd$) + LEN(Rslt$) <= lim THEN
   Rslt$ = LEFT$(Rslt$, Curp) + Kbrd$ + RIGHT$(Rslt$, LEN(Rslt$) - Curp)
   Curp = Curp + LEN(Kbrd$): Chng = 1
  ELSE SOUND 1024, .1
  END IF
 CASE CHR$(8): IF Curp > 0 AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp - 1) + RIGHT$(Rslt$, Leng - Curp): Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "S": IF Curp < Leng AND Rslt$ > "" THEN Rslt$ = LEFT$(Rslt$, Curp) + RIGHT$(Rslt$, Leng - Curp - 1): Chng = 1
 CASE CHR$(0) + "K": IF Curp > 0 THEN Curp = Curp - 1: Chng = 1
 CASE CHR$(0) + "M": IF Curp < Leng THEN Curp = Curp + 1: Chng = 1
 CASE CHR$(0) + "G": Curp = 0: Chng = 1
 CASE CHR$(0) + "O": Curp = Leng: Chng = 1
 CASE ELSE: KeyOut$ = Kbrd$: LOCATE Row, Col: Done = 1
 END SELECT

 IF Chng THEN
  Leng = LEN(Rslt$)
  IF Curp > Leng THEN Curp = Leng ELSE IF Curp < 0 THEN Curp = 0
  IF Curp < Ofst THEN Ofst = Curp ELSE IF Curp >= Ofst + Vis THEN Ofst = Curp - Vis + 1
  text$ = MID$(Rslt$ + SPACE$(Vis), Ofst + 1, Vis)
  LOCATE , , 0: LOCATE Row, Col: PRINT text$;
  LOCATE Row + ((Curp - Ofst) \ 80), Col + ((Curp - Ofst) MOD 80)
  LOCATE , , 1, 14, 15
  Chng = 0
 END IF

LOOP UNTIL Done

Last$ = Rslt$
END SUB

DEFSNG A-Z
SUB SKIPLINE
PRINT CHR$(13)
END SUB

