CONST pi = 3.141592654#

Restart:
SCREEN 0: WIDTH 80, 25: CLS
PRINT "Simple polygon drawer, originally created by Stephen Beats, edited by Dwayne"
PRINT : PRINT "Press Enter to quit or type the number of sides for polyhedron"
PRINT : PRINT "While viewing, you can press Escape to cancel, or Shift to pause"
PRINT "Once you press shift, you must press another key to resume, or"
PRINT "hold shift and another key to procede one frame at a time"
GetNumber:
LOCATE 8, 1: PRINT : PRINT "Sides:"; TAB(80);
LOCATE , 7: LINE INPUT ""; sides$
IF sides$ = "" OR VAL(sides$) = 0 THEN END
sides$ = LTRIM$(sides$): IF LEN(sides$) > 5 THEN sides = 10001 ELSE sides = VAL(sides$)
IF sides > 10000 THEN PRINT "Too many sides for polygon, must be less than ten thousand or less"; : SLEEP: LOCATE , 1: PRINT SPACE$(66): GOTO GetNumber
GOSUB DrawSpiral
GOTO Restart


DrawSpiral:
SCREEN 7: DEF SEG = 0
mp = 100
FOR j = 0 TO 2.56 * pi STEP pi / 20
 FOR k = j TO 2 * pi + j + .1 STEP 2 * pi / sides
  x = INT(mp * 1.2 * SIN(k) + 160)
        '1.2 is for the screen aspect correction
  y = INT(mp * COS(k) + 100)
        '160 and 100 are values to center the drawing
  IF k > j THEN LINE (x1, y1)-(x, y), 15
  x1 = x: y1 = y
 NEXT k
 IF PEEK(1047) AND 1 THEN DO: kbrd$ = INKEY$: LOOP UNTIL kbrd$ > "" ELSE kbrd$ = INKEY$
 IF kbrd$ = CHR$(27) THEN RETURN
 mp = mp - 2
NEXT
LOCATE 1, 1: PRINT "Done";
WHILE (INP(96) AND 128) XOR 128: kbrd$ = INKEY$: WEND
WHILE INKEY$ = "": WEND
RETURN

'YinYang
FOR j = 0 TO 2.54 * pi STEP pi / 20
 FOR k = j TO pi + j + .1 STEP pi / sides
  x = INT(mp * 1.3 * SIN(k) + 160)
  y = INT(mp * COS(k) + 100)
  '''
 NEXT k
 IF PEEK(1047) AND 1 THEN DO: kbrd$ = INKEY$: LOOP UNTIL kbrd$ > "" ELSE kbrd$ = INKEY$
 IF kbrd$ = CHR$(27) THEN RETURN
 mp = mp - 2
NEXT

'SpinAround
FOR j = 0 TO 2.54 * pi STEP pi / 20
 FOR k = j TO 2 * pi + j + .1 STEP 2 * pi / sides
  x = INT(mp * 1.3 * SIN(k) + 160)
  y = INT(100 * COS(k) + 100)
  '''
 NEXT k
 '''
 mp = mp - 4
NEXT

'WorldBend
FOR j = 0 TO 2.54 * pi STEP pi / 20
 FOR k = j TO pi + j + .1 STEP pi / sides
  x = INT(mp * 1.3 * SIN(k) + 160)
  y = INT(100 * COS(k) + 100)
  '''
 NEXT k
 '''
 mp = mp - 4
NEXT

'CrabGrip
FOR j = 0 TO 2.54 * pi STEP pi / 20
 FOR k = j TO pi + j + .1 STEP pi / sides
  x = INT(mp * 1.3 * SIN(k) + 160)
  y = INT(100 * COS(k) + 100)
  '''
 NEXT k
 '''
 mp = mp - 4
NEXT

'Rebound - first in, then back out
FOR j = 0 TO 2.54 * pi STEP pi / 20
 FOR k = j TO 2 * pi + j + .1 STEP 2 * pi / sides
  x = INT(mp * 1.3 * SIN(k) + 160)
  y = INT(mp * COS(k) + 100)
  '''
 NEXT k
 '''
 mp = mp - 4
NEXT

'Normal
FOR j = 0 TO 2.54 * pi STEP pi / 20
 FOR k = j TO 2 * pi + j + .1 STEP 2 * pi / sides
  x = INT(mp * 1.3 * SIN(k) + 160)
  y = INT(mp * COS(k) + 100)
  '''
 NEXT k
 '''
 mp = mp - 2
NEXT

'Extra thick flower
FOR j = 0 TO 2.54 * pi STEP pi / 160
 FOR k = j TO 2 * pi + j + .1 STEP 2 * pi / sides
  x = INT(mp * 1.2 * SIN(k) + 160)
  y = INT(mp * COS(k) + 100)
  '''
 NEXT k
 '''
 mp = mp - 1
NEXT

'Slow slide in
FOR j = 0 TO .63 * pi STEP pi / 160
 FOR k = j TO 2 * pi + j + .1 STEP 2 * pi / sides
  x = INT(mp * 1.2 * SIN(k) + 160)
  y = INT(mp * COS(k) + 100)
  '''
 NEXT k
 '''
 mp = mp - 1
NEXT

