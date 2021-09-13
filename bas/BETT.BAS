SCREEN 0

COLOR 15: PRINT TAB(29); "*** Game of Guess ***"
COLOR 7: PRINT "    This very simple game will randomly select a number, 1 thru whatever"
PRINT "    limit you set (fifty by default). You get as many tries as the limit"
PRINT "    is divided in half. That means that you get 25 chances to get a number"
PRINT "    within 1 thru 50. Each time you guess, the game will tell you if you"
PRINT "    guessed the number or how close you came to guessing it. When you use"
PRINT "    up all of your chances, it will tell you what the number was and ask"
PRINT "    you if you want to play again. Press Esc at any time to quit this game."
COLOR 9: LOCATE , 29: PRINT "Press any key to start";
SLEEP 30: WHILE INKEY$ > "": WEND
LOCATE , 29: PRINT SPACE$(22)

GetLimit:
  COLOR 11: PRINT "    Choose a limit: "; : INPUT "", limit
  IF limit < 1 THEN limit = 50
  PRINT "    The range is 1 thru"; limit; CHR$(13)
  RANDOMIZE TIMER
  number = INT(RND * limit) + 1
  chance = 0
  chances = limit \ 2
GetGuess:
  result = 0
  DO
    COLOR 5: INPUT "--> ", guess
    IF guess = 0 GOTO EndGame
    IF guess > limit OR guess < 0 THEN COLOR 9: PRINT "    That number is not in range": GOTO GetGuess
    chance = chance + 1
    GOSUB EvaluateGuess
    IF result THEN SLEEP: IF INKEY$ = CHR$(27) GOTO EndGame ELSE PRINT : GOTO GetLimit
  LOOP
EvaluateGuess:
  IF guess = number THEN
    result = 2: COLOR 10: PRINT "    Good you got it! You took"; chance; "guesses"
  ELSE
    result = 0: COLOR 9: IF guess < number THEN PRINT "    That's too low" ELSE PRINT "    That's too high"
    IF chance >= chances THEN result = 1: COLOR 12: PRINT "    Sorry, your"; chances; "chances are up - the number was"; number
  END IF
RETURN
EndGame: COLOR 7, 0: PRINT : END

