'RGB Color Rainbow Palette
'Dwayne Robinson
'1998.4.21
'
'Display two rainbow palettes, one created by a linear zigzag and another
'smoother one created using sine.
DEFINT A-Z
CONST TotalColors = 256 - 1

SCREEN 13

OUT &H3C8, 0
OUT &H3C9, 45
OUT &H3C9, 45
OUT &H3C9, 45

FOR CurColor = 0 TO TotalColors
  LINE (CurColor, 0)-(CurColor, 100), CurColor
NEXT CurColor

DO
  Redvalue = 63: RedInc = -1
  GreenValue = 0: GreenInc = 1
  BlueValue = 0: BlueInc = 0
  OUT &H3C8, 1
  FOR CurColor = 1 TO TotalColors
    OUT &H3C9, Redvalue
    OUT &H3C9, GreenValue
    OUT &H3C9, BlueValue
    Redvalue = Redvalue + RedInc
    GreenValue = GreenValue + GreenInc
    BlueValue = BlueValue + BlueInc
    IF Redvalue < 0 THEN RedInc = 0: Redvalue = 0: BlueInc = 1 ELSE IF Redvalue > 63 THEN RedInc = -1: Redvalue = 63
    IF GreenValue > 63 THEN GreenInc = -1: GreenValue = 63 ELSE IF GreenValue < 0 THEN GreenInc = 0: GreenValue = 0: RedInc = 1
    IF BlueValue > 63 THEN BlueInc = -1: BlueValue = 63 ELSE IF BlueValue < 0 THEN BlueInc = 0: BlueValue = 0: GreenInc = 1
  NEXT CurColor
  DO: k$ = INKEY$: LOOP UNTIL LEN(k$)
  IF k$ = CHR$(27) THEN EXIT DO
  OUT &H3C8, 1
  FOR CurColor = 1 TO TotalColors
    ColorRadian# = CurColor * .0245436953125#
    Redvalue = SIN(ColorRadian#) * 31 + 32
    GreenValue = SIN(ColorRadian# + 2.09439519620768#) * 31 + 32
    BlueValue = SIN(ColorRadian# + 4.188790639241536#) * 31 + 32
    OUT &H3C9, Redvalue
    OUT &H3C9, GreenValue
    OUT &H3C9, BlueValue
  NEXT CurColor
  DO: k$ = INKEY$: LOOP UNTIL LEN(k$)
  IF k$ = CHR$(27) THEN EXIT DO
LOOP

'Pi=3.141593
'MaxRadians=6.283186=360*(Pi#/180)
'MaxRadians/256 .0245436953125#)

