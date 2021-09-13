DEFINT A-Z
DECLARE SUB w ()
DECLARE SUB wi ()
DECLARE SUB DrawWin31 ()
DECLARE SUB DrawWinMine ()
DIM SHARED DrawDelay&

CurScreenMode = 0
CurWinStyle = 0
DrawDelay& = 100000
DrawDelayInc& = 1000
GOSUB SetScreenMode
GOSUB ShowDrawingStyle

DO
 SELECT CASE INKEY$
 CASE CHR$(27): EXIT DO
 CASE " ": CurWinStyle = CurWinStyle XOR 1: GOSUB ShowDrawingStyle
 CASE CHR$(13): GOSUB ShowDrawingStyle
 CASE CHR$(9)
  CurScreenMode = CurScreenMode XOR 1: GOSUB SetScreenMode: GOSUB ShowInfoStatus: GOSUB ShowDrawDelay
  DrawDelayTemp& = DrawDelay&: DrawDelay& = 0: GOSUB DrawCurStyle: DrawDelay& = DrawDelayTemp&
 CASE "+", CHR$(0) + "H": IF DrawDelay& < 800000 THEN DrawDelay& = DrawDelay& + DrawDelayInc&: GOSUB ShowDrawDelay
 CASE "-", CHR$(0) + "P": IF DrawDelay& > DrawDelayInc& - 1 THEN DrawDelay& = DrawDelay& - DrawDelayInc&: GOSUB ShowDrawDelay
 END SELECT
LOOP
END

ShowDrawDelay:
 LOCATE 1, 12: COLOR 15: PRINT DrawDelay& \ DrawDelayInc&;
RETURN

ShowDrawingStyle:
 DrawingWindow = 1: GOSUB ShowInfoStatus
 LOCATE 1, 1: COLOR 15: PRINT "Drawing...";
 IF CurWinStyle THEN PRINT "Dwayne's own style";  ELSE PRINT "Windows 3.1 style";
 LINE (98, 98)-(402, 202), 8, BF
 GOSUB DrawCurStyle
 LOCATE 1, 1: PRINT TAB(40);
 DrawingWindow = 0: GOSUB ShowInfoStatus
 GOSUB ShowDrawDelay
RETURN

DrawCurStyle:
 IF CurWinStyle THEN DrawWinMine ELSE DrawWin31
RETURN

ShowInfoStatus:
 COLOR 15: LOCATE 1, 1: PRINT "Draw delay:";
 IF DrawingWindow THEN COLOR 8 ELSE COLOR 7
 LOCATE 3, 1: PRINT "Press Enter to redraw";
 LOCATE 4, 1: PRINT "Space to toggle window style";
 LOCATE 5, 1: PRINT "Up or down to change draw delay";
 LOCATE 6, 1: PRINT "Tab to switch screen mode";
RETURN

SetScreenMode:
IF CurScreenMode THEN
 SCREEN 7
 WINDOW SCREEN (80, 0)-(400, 199)
ELSE
 SCREEN 12
END IF
RETURN

SUB DrawWin31

LINE (100, 100)-(400, 200), 0, B: w
LINE (103, 103)-(397, 197), 0, B: w
LINE (101, 101)-(399, 102), 2, BF: wi
LINE (101, 198)-(399, 199), 2, BF: wi
LINE (101, 102)-(102, 198), 2, BF: wi
LINE (398, 102)-(399, 198), 2, BF: w
LINE (122, 100)-(122, 103), 0: wi
LINE (378, 100)-(378, 103), 0: wi
LINE (100, 122)-(103, 122), 0: wi
LINE (397, 122)-(400, 122), 0: wi
LINE (100, 178)-(103, 178), 0: wi
LINE (397, 178)-(400, 178), 0: wi
LINE (122, 197)-(122, 200), 0: wi
LINE (378, 197)-(378, 200), 0: w
'Control box
LINE (122, 103)-(122, 122), 0: w
LINE (104, 104)-(121, 121), 7, BF: w
LINE (106, 111)-(118, 113), 0, B: wi
LINE (107, 112)-(117, 112), 15, BF: wi
LINE (107, 114)-(119, 114), 8: wi
LINE (119, 112)-(119, 113), 8: w
'Title bar
LINE (103, 122)-(397, 122), 0: w
LINE (123, 104)-(377, 121), 9, BF: w
'Minimize button
LINE (378, 103)-(378, 122), 0: w
LINE (379, 104)-(395, 104), 15: wi
LINE (379, 104)-(379, 120), 15: wi
LINE (380, 105)-(394, 119), 7, BF: wi
LINE (380, 120)-(395, 120), 8: wi
LINE (379, 121)-(396, 121), 8: wi
LINE (395, 105)-(395, 120), 8: wi
LINE (396, 104)-(396, 121), 8: w
LINE (384, 111)-(390, 111), 0: wi
LINE (390, 111)-(387, 114), 0: wi
LINE (384, 111)-(387, 114), 0: wi
PAINT (387, 112), 0, 0: w
'Menu Bar
LINE (104, 141)-(396, 141), 0: w
LINE (104, 123)-(396, 140), 7, BF: w
'Application workspace
LINE (104, 142)-(396, 196), 3, BF: w

END SUB

SUB DrawWinMine

LINE (100, 100)-(400, 200), 0, B: w
LINE (103, 103)-(397, 197), 0, B: w
LINE (101, 101)-(399, 102), 2, BF: wi
LINE (101, 198)-(399, 199), 2, BF: wi
LINE (101, 102)-(102, 198), 2, BF: wi
LINE (398, 102)-(399, 198), 2, BF: w
'Title bar
LINE (103, 122)-(397, 122), 0: w
LINE (104, 104)-(396, 121), 9, BF: w
'Control icon
'LINE (120, 105)-(120, 120), 8: wi 'Outside border
'LINE (105, 105)-(120, 105), 15: wi
'LINE (105, 105)-(105, 120), 15: wi
'LINE (105, 120)-(120, 120), 8: w
LINE (107, 111)-(117, 113), 0, B: wi 'Draw picture
LINE (108, 112)-(116, 112), 15, BF: wi
LINE (108, 114)-(118, 114), 1: wi
LINE (118, 112)-(118, 113), 1: w
'Minimize button
LINE (395, 105)-(395, 120), 8: wi
LINE (380, 105)-(395, 105), 15: wi
LINE (380, 105)-(380, 120), 15: wi
LINE (380, 120)-(395, 120), 8: w
LINE (383, 111)-(387, 115), 0: wi
LINE (383, 111)-(391, 111), 0: wi
LINE (391, 111)-(387, 115), 0: wi
LINE (391, 112)-(388, 115), 1: wi
PAINT (387, 112), 15, 0: w
'Menu Bar
LINE (104, 141)-(396, 141), 0: w
LINE (104, 123)-(396, 140), 7, BF: w
'Application workspace
LINE (104, 142)-(396, 196), 3, BF: w

END SUB

SUB w
 FOR a& = 0 TO DrawDelay&: NEXT a&
 DO
  key$ = INKEY$: IF key$ = CHR$(27) THEN END
 LOOP UNTIL key$ = ""
END SUB

SUB wi
 FOR a& = 0 TO 0: NEXT a&
 IF INKEY$ = CHR$(27) THEN END
END SUB

