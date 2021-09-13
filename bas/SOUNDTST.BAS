'1998-10-25
CLS
PRINT "Press a key to start sound test"
DO: LOOP UNTIL LEN(INKEY$)

EndTime# = TIMER
DO
  READ Duration#
  IF Duration# = 0 THEN EXIT DO
  READ Freq&
  PRINT "Frequency"; Freq&; "for"; Duration#; "clicks"
  PitchLow = Freq& AND 255
  PitchHigh = Freq& \ 256
  EndTime# = EndTime# + Duration#
  GOSUB SetSound
  DO: LOOP UNTIL TIMER >= EndTime#
LOOP
OUT &H61, INP(&H61) AND -3

END

SetSound:
  OUT &H43, &HB6    'set speaker timer
  OUT &H42, PitchLow
  OUT &H42, PitchHigh
  OUT &H61, INP(&H61) OR 3
RETURN

DATA .2,4000, .1,2, .2,2000, .1,2, .2,1000, .2,2
DATA .4,2000, .1,2, .2,1000, .1,2, .2,500, .1,2, 0

