DEFINT A-Z

SCREEN 12
RANDOMIZE TIMER
PreKey = INP(96)
LOCATE 1, 1: PRINT "Press ANY key to quit this timewaster - Even one of the shift keys"

t! = 2
DO UNTIL Done
 FOR t% = 1 TO 30
  t! = t! / 2.2
  CIRCLE (320, 240), 60, c, , , t!
  'CIRCLE (320, 240), 60, 0, , , t!
  c = (c + 1) AND 15
 NEXT t%
 IF INP(96) <> PreKey THEN EXIT DO
 FOR t% = 1 TO 30
  t! = t! * 2.2
  CIRCLE (320, 240), 60, c, , , t!
  'CIRCLE (320, 240), 60, 0, , , t!
  c = (c + 1) AND 15
 NEXT t%
 IF INP(96) <> PreKey THEN EXIT DO
LOOP

LOCATE 1, 1: PRINT SPACE$(70)
SYSTEM

