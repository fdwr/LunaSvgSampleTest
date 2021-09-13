' This program sets the screen mode using the BIOS to whatever one you enter.
'Then it records the main screen register values for that mode and reports
'them to you.
' To enter a screen mode, simply type the value (0 - ?40) and then press
'Enter. The highest screen mode available (?40 or more) depends on the
'particular screen adapter card in the computer. To quit the program, just
'press Enter without typing in any number.

DEFINT A-Z
DECLARE SUB KeyWait ()
DECLARE SUB TextMode ()
DECLARE SUB SetMode (VideoMode)
DECLARE FUNCTION GetScreenAtr (Atr)

REDIM SHARED ScreenRegName$(0 TO 24), SetModeCode(0 TO 5)
REDIM ScreenRegSlot(0 TO 24)

FOR getRegNames = 0 TO 24
 READ ScreenRegName$(getRegNames)
NEXT getRegNames
DATA "Horizontal total","Horizontal display end","Start horizontal blanking","End horizontal blanking","Start horizontal retrace","End horizontal retrace","Vertical total","Overflow","Preset scan row","Maximum scan line","Cursor start","Cursor end"
DATA "Start address high","Start address low","Cursor location high","Cursor location low","Vertical retrace start","Vertical retrace end","Vertical display end","Offset","Underline location","Start vertical blank","End vertical blank","Mode control"
DATA "Line compare"

DO
 TextMode
GetScreenMode:
 LINE INPUT "Enter a screen mode:", ScreenMode$
 IF ScreenMode$ = "" THEN EXIT DO
 IF VAL(ScreenMode$) = 0 AND ScreenMode$ <> "0" THEN PRINT "That is not a valid number"; : KeyWait: CLS : GOTO GetScreenMode

 VideoMode = VAL(ScreenMode$)
 SetMode VideoMode
 FOR getScreenRegs = 0 TO 24
  ScreenRegSlot(getScreenRegs) = GetScreenAtr(getScreenRegs)
 NEXT getScreenRegs
 
 TextMode
 FOR showScreenRegs = 0 TO 24
  LOCATE showScreenRegs + 1, 1: PRINT ScreenRegName$(showScreenRegs); TAB(30); ScreenRegSlot(showScreenRegs);
 NEXT showScreenRegs
 DO
  Kbrd$ = INKEY$
  IF UCASE$(Kbrd$) = "S" THEN GOSUB SaveRegs
 LOOP UNTIL Kbrd$ > ""
LOOP
END

SaveRegs:
CLS
PRINT "Save register information, press Enter to cancel, type a filename to continue"
LINE INPUT FileName$
IF FileName$ = "" THEN RETURN
ON ERROR GOTO FileErr
OPEN FileName$ FOR OUTPUT AS #1
 FOR showScreenRegs = 0 TO 24
  PRINT #1, ScreenRegName$(showScreenRegs); TAB(30); ScreenRegSlot(showScreenRegs)
 NEXT showScreenRegs
CLOSE #1
RETURN

FileErr:
PRINT "That is a bad filename"
KeyWait
RESUME SaveRegs

FUNCTION GetScreenAtr (Atr)
 OUT &H3D4, Atr
 GetScreenAtr = INP(&H3D5)
END FUNCTION

SUB KeyWait
WHILE INKEY$ = "": WEND
END SUB

SUB SetMode (VideoMode)

DEF SEG = VARSEG(SetModeCode(0))
P = VARPTR(SetModeCode(0))
POKE P, 184
POKE P + 1, VideoMode AND 255
POKE P + 2, 0
POKE P + 3, 205
POKE P + 4, 16
POKE P + 5, 203
CALL ABSOLUTE(P)
DEF SEG

END SUB

SUB TextMode
SCREEN 0: SetMode 2: COLOR 7, 0: LOCATE 1, 1, 0
END SUB

