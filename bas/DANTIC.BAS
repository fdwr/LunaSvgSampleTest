DECLARE SUB IntroScr ()
SCREEN 7
IntroScr

SUB IntroScr

LOCATE 25, 4: PRINT "Press Any Freaking Key To Move On"
Title$ = "Daniel's Tic-Tac-Toe"
Music$ = "aaccggbbddggcc>aaccggbbddggcc>aaccggbbddggcc<ccggddbbggcccccc"

PLAY "MB L15o2"
PlayPointer = 1
DO
 LOCATE 13, 11
 COLOR INT(RND * 16)
 PRINT Title$;
 IF PlayPointer < LEN(Music$) THEN IF PLAY(0) < 1 THEN PLAY MID$(Music$, PlayPointer, 1): PlayPointer = PlayPointer + 1
LOOP UNTIL INKEY$ > ""
END SUB

