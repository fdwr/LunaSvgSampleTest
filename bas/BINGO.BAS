DECLARE SUB player1 ()
DECLARE SUB player2 ()
DECLARE SUB player3 ()
DECLARE SUB player4 ()
DECLARE SUB player5 ()
DECLARE SUB intro ()
'
'
'
'
'
'
'
'
'
'
'
'
SCREEN 8

DIM SHARED L%

DIM SHARED B%
DIM SHARED I%
DIM SHARED n%
DIM SHARED G%
DIM SHARED O%

DO

CLS

B% = 0
I% = 0
n% = 0
G% = 0
O% = 0

RANDOMIZE TIMER


  L% = INT(RND * 5) ' letter in b*i*n*g*o

IF L% = 0 THEN
  B% = INT(RND * 51)
END IF

IF L% = 1 THEN
  I% = INT(RND * 51)
END IF

IF L% = 2 THEN
  n% = INT(RND * 51)
END IF

IF L% = 3 THEN
  G% = INT(RND * 51)
END IF

IF L% = 4 THEN
  O% = INT(RND * 51)
END IF


CALL player1
CALL player2
CALL player3
CALL player4
CALL player5
LOOP

SUB intro

  A$ = "*    *    *    *    *    *    *    *    *    *    *    *    *    *    *    *    *    "
  WHILE INKEY$ <> "": WEND 'Clear keyboard buffer

  WHILE INKEY$ = ""
    FOR A = 1 TO 5
      LOCATE 1, 1                             'print horizontal sparkles
      PRINT MID$(A$, A, 80);
      LOCATE 22, 1
      PRINT MID$(A$, 6 - A, 80);

      FOR B = 2 TO 21                         'Print Vertical sparkles
        C = (A + B) MOD 5
        IF C = 1 THEN
          LOCATE B, 80
          PRINT "*";
          LOCATE 23 - B, 1
          PRINT "*";
        ELSE
          LOCATE B, 80
          PRINT " ";
          LOCATE 23 - B, 1
          PRINT " ";
        END IF
      NEXT B
    NEXT A
  WEND

END SUB

SUB player1
CLS
COLOR 15
DRAW "bl300 u90 r600 d180 l600 u180 r120 d180 r120 u180 r120 d180 r120 u180 r120 d36 l600 d36 r600 d36 l600 d36 r600"
COLOR 1
CALL intro
END SUB

SUB player2
CLS
COLOR 15
DRAW "bl300 u90 r600 d180 l600 u180 r120 d180 r120 u180 r120 d180 r120 u180 r120 d36 l600 d36 r600 d36 l600 d36 r600"
COLOR 2
CALL intro
END SUB

SUB player3
CLS
COLOR 15
DRAW "bl300 u90 r600 d180 l600 u180 r120 d180 r120 u180 r120 d180 r120 u180 r120 d36 l600 d36 r600 d36 l600 d36 r600"
COLOR 3
CALL intro
END SUB

SUB player4
CLS
COLOR 15
DRAW "bl300 u90 r600 d180 l600 u180 r120 d180 r120 u180 r120 d180 r120 u180 r120 d36 l600 d36 r600 d36 l600 d36 r600"
COLOR 4
CALL intro
END SUB

SUB player5
CLS
COLOR 15
DRAW "bl300 u90 r600 d180 l600 u180 r120 d180 r120 u180 r120 d180 r120 u180 r120 d36 l600 d36 r600 d36 l600 d36 r600"
COLOR 5
CALL intro
END SUB

