'This program sets the screen mode using the BIOS to the one you Enter

DEFINT A-Z
DECLARE SUB SetMode (VideoMode)
DECLARE SUB DrawChar (Char, CharColor)

DIM SHARED SetModeCode(0 TO 2), DrawCharCode(0 TO 6)
DEF SEG = VARSEG(SetModeCode(0)): p = VARPTR(SetModeCode(0)): DATA 184,0,0,205,16,203
FOR ReadArrayCode = 0 TO 5: READ CodeData: POKE p + ReadArrayCode, CodeData: NEXT ReadArrayCode
DEF SEG = VARSEG(DrawCharCode(0)): p = VARPTR(DrawCharCode(0)): DATA 183,0,176,32,179,7,185,1,0,180,9,205,16,203
FOR ReadArrayCode = 0 TO 13: READ CodeData: POKE p + ReadArrayCode, CodeData: NEXT ReadArrayCode

SCREEN 13
SetMode 3
GOSUB ShowProgramInfo
ScreenMode$ = "0"
DO
 LOCATE 1, 13: PRINT ScreenMode$; "  ";
 DO: kbrd$ = INKEY$: LOOP UNTIL kbrd$ > ""
 SELECT CASE kbrd$
 CASE "0" TO "9"
  IF LEN(ScreenMode$) < 3 THEN
   IF ScreenMode$ = "0" THEN ScreenMode$ = kbrd$ ELSE ScreenMode$ = ScreenMode$ + kbrd$
   IF VAL(ScreenMode$) > 255 THEN ScreenMode$ = "255"
  END IF
 CASE CHR$(8): IF LEN(ScreenMode$) > 1 THEN ScreenMode$ = LEFT$(ScreenMode$, LEN(ScreenMode$) - 1) ELSE ScreenMode$ = "0"
 CASE CHR$(0) + "K", CHR$(0) + "P": IF VAL(ScreenMode$) THEN ScreenMode$ = LTRIM$(STR$(VAL(ScreenMode$) - 1))
 CASE CHR$(0) + "M", CHR$(0) + "H": IF VAL(ScreenMode$) < 255 THEN ScreenMode$ = LTRIM$(STR$(VAL(ScreenMode$) + 1))
 CASE "+": newbardist = bardist + 1: GOSUB ShowBars
 CASE "-": IF bardist THEN newbardist = bardist - 1: GOSUB ShowBars
 CASE "*": newbardist = bardist + 10: GOSUB ShowBars
 CASE "/": IF bardist > 10 THEN newbardist = bardist - 10: GOSUB ShowBars
 CASE CHR$(27): EXIT DO
 CASE CHR$(13): VideoMode = VAL(ScreenMode$): SetMode VideoMode: GOSUB ShowProgramInfo
 CASE CHR$(32): SetMode 3: GOSUB ShowProgramInfo
 END SELECT
LOOP
END

ShowBars:
LINE (bardist, 100)-(newbardist, 150), 0, B
LINE (0, 100)-(newbardist, 150), 12, B
bardist = newbardist
LOCATE 8, 1: PRINT bardist
RETURN

ShowProgramInfo:
 FOR a = 0 TO 255
  LINE (a, 0)-(a, 50), a, BF
 NEXT a
 LOCATE 1, 1: PRINT "Screen mode"
 LOCATE 3, 2: PRINT "umber and Arrow keys change mode value"
 PRINT "ENTER sets screen to mode"
 PRINT "SPACE resets to text mode"
 PRINT "ESC quits this program"
 LOCATE 3, 1: DrawChar 78, 13
 GOSUB ShowBars
RETURN

SUB DrawChar (Char, CharColor)

DEF SEG = VARSEG(DrawCharCode(0))
p = VARPTR(DrawCharCode(0))
POKE p + 3, Char
POKE p + 5, CharColor
CALL ABSOLUTE(p)
DEF SEG

END SUB

SUB SetMode (VideoMode)

DEF SEG = VARSEG(SetModeCode(0))
p = VARPTR(SetModeCode(0))
POKE p + 1, VideoMode AND 255
CALL ABSOLUTE(p)
DEF SEG

END SUB

