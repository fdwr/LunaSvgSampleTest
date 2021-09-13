'5-5-98 3238 FDR
DEFINT A-Z
DECLARE SUB SetPalette (PaletteMode)

SCREEN 13
SetPalette 0

DIM MemDataToScreen AS STRING * 40 'length of code
FOR index = 1 TO LEN(MemDataToScreen)
  READ Char
  MID$(MemDataToScreen, index, 1) = CHR$(Char)
NEXT index

COLOR 170
PaletteMode = 0

MemPosition& = 0
index = 0
MaxMemPosition& = 1048575
PageSize& = 61440 '64000 - (8 * 320) reserve one line at bottom for status
DO
  DEF SEG = VARSEG(MemDataToScreen)
  CALL absolute(BYVAL MemPosition&, VARPTR(MemDataToScreen))
  index = index + 1: IF index > 8 THEN index = 0: LOCATE 25, 1: PRINT LTRIM$(STR$(MemPosition&)); TAB(10); HEX$(MemPosition&); TAB(16);
  WHILE INKEY$ > "": WEND
  SELECT CASE INP(96)
  CASE 81: IF MemPosition& < MaxMemPosition& THEN NewMemPosition& = MemPosition& + PageSize&: GOSUB SeekHighPosition
  CASE 73: IF MemPosition& > 0 THEN NewMemPosition& = MemPosition& - PageSize&: GOSUB SeekLowPosition
  CASE 80: IF MemPosition& < MaxMemPosition& THEN NewMemPosition& = MemPosition& + 320: GOSUB SeekHighPosition
  CASE 72: IF MemPosition& > 0 THEN NewMemPosition& = MemPosition& - 320: GOSUB SeekLowPosition
  CASE 77: IF MemPosition& < MaxMemPosition& THEN NewMemPosition& = MemPosition& + 1: GOSUB SeekHighPosition
  CASE 75: IF MemPosition& > 0 THEN NewMemPosition& = MemPosition& - 1: GOSUB SeekLowPosition
  CASE 55: IF MemPosition& < MaxMemPosition& THEN NewMemPosition& = MemPosition& + 8000: GOSUB SeekHighPosition
  CASE 53: IF MemPosition& > 0 THEN NewMemPosition& = MemPosition& - 8000: GOSUB SeekLowPosition
  CASE 57
    PaletteMode = (PaletteMode + 1) MOD 3
    SetPalette PaletteMode
    WHILE INP(96) = 57: WEND
  CASE 34
    LOCATE 25, 1: PRINT SPACE$(40);
    LOCATE 25, 1: LINE INPUT ; "Goto:", Position$
    IF LEN(Position$) THEN NewMemPosition& = VAL(Position$)
    GOSUB SeekNewPosition
  CASE 59
    GOSUB Help
    SCREEN 13
    SetPalette PaletteMode
    COLOR 170
  CASE 1: EXIT DO
  END SELECT
LOOP

END

SeekLowPosition:
  IF NewMemPosition& <= 0 THEN MemPosition& = 0 ELSE MemPosition& = NewMemPosition&
RETURN

SeekHighPosition:
  IF NewMemPosition& >= MaxMemPosition& THEN MemPosition& = MaxMemPosition& ELSE MemPosition& = NewMemPosition&
RETURN

SeekNewPosition:
  IF NewMemPosition& <= 0 THEN
  '  IF MemPosition& = 0 THEN RETURN ELSE MemPosition& = 0
     MemPosition& = 0
  ELSEIF NewMemPosition& >= MaxMemPosition& THEN
  '  IF MemPosition& = MaxMemPosition& THEN RETURN ELSE MemPosition& = MaxMemPosition&
    MemPosition& = MaxMemPosition&
  ELSE
    MemPosition& = NewMemPosition&
  END IF
RETURN

Help:
  WIDTH 80, 25
  PRINT "Memory pixel viewer, views RAM as pixels on the screen, May 5, 1998 by FDR"
  PRINT "(May be way too fast on a 586, this was written on a 386)"
  PRINT
  PRINT "The bottom line shows your current byte position and for those who know what"
  PRINT "hexadecimal even is, it is also down there for you."
  PRINT
  PRINT "Scrolling Keys:"
  PRINT "  Up Down     Simply scrolls one row u/d (do I even need to explain these?)"
  PRINT "  Left Right  Moves sideways one column l/r (you already knew that)"
  PRINT "  PgUp PgDn   Take your best guess"
  PRINT "  * /         These two are not so obvious, they scroll an eighth of a page"
  PRINT
  PRINT "Other miscellaneous"
  PRINT "  F1     The cheap help you are reading right now"
  PRINT "  G      Goto any specified byte position in memory"
  PRINT "  Space  Toggle between three palettes of two color and a monchrome"
  PRINT "         take your pick, in certain cases you might like one over another"
  PRINT "  Esc    Fine, be that way and leave, see if I care ):->"
  PRINT
  PRINT "Believe it or not, that's all, enjoy (:-)"
  DO: LOOP UNTIL LEN(INKEY$)
RETURN

'FILEPIXL.COM
DATA 30,6,85,137,229,102,139,70,10,137,198,102,193,232,4,142,216,129,230,15,0
DATA 184,0,160,142,192,49,255,185,0,60,243,102,165,93,7,31,202,4,0

SUB SetPalette (PaletteMode)
  OUT &H3C8, 0
  IF PaletteMode = 2 THEN
    FOR CurColor = 0 TO 255
      ColorRadian# = CurColor * .0245436953125#
      Redvalue = SIN(ColorRadian#) * 31 + 32
      GreenValue = SIN(ColorRadian# + 2.09439519620768#) * 31 + 32
      BlueValue = SIN(ColorRadian# + 4.188790639241536#) * 31 + 32
      OUT &H3C9, BlueValue
      OUT &H3C9, Redvalue
      OUT &H3C9, GreenValue
    NEXT CurColor
  ELSEIF PaletteMode = 1 THEN
    Redvalue = 63: RedInc = -1
    GreenValue = 0: GreenInc = 1
    BlueValue = 0: BlueInc = 0
    FOR CurColor = 0 TO 255
      OUT &H3C9, BlueValue
      OUT &H3C9, GreenValue
      OUT &H3C9, Redvalue
      Redvalue = Redvalue + RedInc
      GreenValue = GreenValue + GreenInc
      BlueValue = BlueValue + BlueInc
      IF Redvalue < 0 THEN RedInc = 0: Redvalue = 0: BlueInc = 1 ELSE IF Redvalue > 63 THEN RedInc = -1: Redvalue = 63
      IF GreenValue > 63 THEN GreenInc = -1: GreenValue = 63 ELSE IF GreenValue < 0 THEN GreenInc = 0: GreenValue = 0: RedInc = 1
      IF BlueValue > 63 THEN BlueInc = -1: BlueValue = 63 ELSE IF BlueValue < 0 THEN BlueInc = 0: BlueValue = 0: GreenInc = 1
    NEXT CurColor
  ELSE
    FOR CurColor = 0 TO 255
      rgb = CurColor \ 4
      OUT &H3C9, rgb
      OUT &H3C9, rgb
      OUT &H3C9, rgb
    NEXT CurColor
  END IF
END SUB

