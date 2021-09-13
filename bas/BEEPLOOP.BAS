DO
  High = INT(RND * 256)
  Low = INT(RND * 256)
  OUT &H43, 182
  OUT &H42, High
  OUT &H42, Low
LOOP UNTIL LEN(INKEY$)

