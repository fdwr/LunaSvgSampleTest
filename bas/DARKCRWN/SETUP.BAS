DECLARE SUB Center (Sentence$, Y!)
DECLARE SUB CPUSpeed ()
DECLARE SUB DrawBox (Y1!, Y2!)
DECLARE SUB TextSpeed ()

DIM SHARED AnimeSpeed AS INTEGER
DIM SHARED Flag1 AS INTEGER
DIM SHARED GameSpeed AS INTEGER
DIM SHARED Text AS INTEGER
DIM SHARED WaterSpeed AS INTEGER

COLOR 15, 4

CLS
CALL Center("Lianne in... The Dark Crown", 1)
CALL Center("Qbasic Version 1.00", 2)
CALL Center("Created by: DarkDread", 21)
CALL Center("(c) 1997 DarkDreams  Software", 23)

COLOR 14, 3
CALL DrawBox(5, 14)
COLOR 14, 3
CALL Center("Speed Config", 6)
LOCATE 8, 12
PRINT "Please enter the type of computer you have so the program"
LOCATE 9, 12
PRINT "may determine what speed to run at.  Note: If you have a "
LOCATE 10, 12
PRINT "286 or lower, try the first choice and the game might run"
CALL Center("1. 386 2. 486 below 66mhz  3. 486 above 66mhz", 12)
CALL Center("4. 586 below 100mhz  5. 586 above 100mhz or 6x86", 13)
CALL Center("6. Don't know", 14)
CALL CPUSpeed

COLOR 14, 3
CALL DrawBox(5, 14)
COLOR 14, 3
CALL Center("Text Speed", 6)
LOCATE 8, 12
PRINT "Please enter a speed for the text scroll."
CALL Center("1. Slow  2.  Normal  3.  Fast  4.  No Delay", 11)
CALL TextSpeed

OPEN "SETUP.DAT" FOR OUTPUT AS #1
  WRITE #1, GameSpeed
  WRITE #1, Text
  WRITE #1, AnimeSpeed
  WRITE #1, WaterSpeed
CLOSE #1

COLOR 14, 3
CALL DrawBox(5, 14)
COLOR 14, 3
CALL Center("Thank You", 6)
LOCATE 9, 12
PRINT "The setup is now finished.  If the game plays too slow or"
LOCATE 10, 12
PRINT "too fast then please run this setup program again."
LOCATE 11, 12
PRINT "Thank you for trying Lianne in... The Dark Crown, please"
LOCATE 12, 12
PRINT "run the 'DC1.BAS' file in Qbasic(or QB4.5, or PDS7.1) to"
LOCATE 13, 12
PRINT "play."

WHILE INKEY$ = "": WEND
COLOR 7, 0
CLS
SYSTEM

SUB Center (Sentence$, Y)
  Sentence = INT(LEN(Sentence$) / 2)
  X = 40 - Sentence
  LOCATE Y, X
  PRINT Sentence$
END SUB

SUB CPUSpeed
  DO
    SELECT CASE INKEY$
      CASE IS = "1"
        GameSpeed = 0
        AnimeSpeed = 200
        WaterSpeed = 100
        Flag1 = 1
      CASE IS = "2"
        GameSpeed = 5
        AnimeSpeed = 400
        WaterSpeed = 200
        Flag1 = 1
      CASE IS = "3", "6"
        GameSpeed = 5
        AnimeSpeed = 600
        WaterSpeed = 400
        Flag1 = 1
      CASE IS = "4"
        GameSpeed = 10
        AnimeSpeed = 1000
        WaterSpeed = 800
        Flag1 = 1
      CASE IS = "5"
        GameSpeed = 15
        AnimeSpeed = 1200
        WaterSpeed = 1000
        Flag1 = 1
    END SELECT
  LOOP UNTIL Flag1 = 1
  PLAY "l40 mn a"
  Flag1 = 0
END SUB

SUB DrawBox (Y1, Y2)
  LOCATE Y1, 10
  PRINT CHR$(218)
  LOCATE Y1, 70
  PRINT CHR$(191)
  LOCATE Y2, 10
  PRINT CHR$(192)
  LOCATE Y2, 70
  PRINT CHR$(217)
  FOR Y = Y1 + 1 TO Y2 - 1
    LOCATE Y, 10
    PRINT CHR$(179)
    LOCATE Y, 70
    PRINT CHR$(179)
  NEXT Y
  LOCATE Y1 + 2, 10
  PRINT CHR$(195)
  LOCATE Y1 + 2, 70
  PRINT CHR$(180)
  FOR Y = Y1 TO Y2
    LOCATE Y, 11
    PRINT SPACE$(59)
  NEXT Y
  FOR I = 11 TO 69
    LOCATE Y1, I
    PRINT CHR$(196)
    LOCATE Y1 + 2, I
    PRINT CHR$(196)
    LOCATE Y2, I
    PRINT CHR$(196)
  NEXT I
  COLOR 0, 4
  FOR I = Y1 + 1 TO Y2
    LOCATE I, 71
    PRINT CHR$(219)
  NEXT I
  FOR I = 11 TO 71
    LOCATE Y2 + 1, I
    PRINT CHR$(223)
  NEXT I
END SUB

SUB TextSpeed
  DO
    SELECT CASE INKEY$
      CASE IS = "1"
        Text = 30
        Flag1 = 1
      CASE IS = "2"
        Text = 15
        Flag1 = 1
      CASE IS = "3"
        Text = 5
        Flag1 = 1
      CASE IS = "4"
        Text = 0
        Flag1 = 1
    END SELECT
  LOOP UNTIL Flag1 = 1
  PLAY "l40 mn a"
  Flag1 = 0
END SUB

