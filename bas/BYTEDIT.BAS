DECLARE SUB MainHelpLine (Text$, Mode%)

CONST TRUE = -1, FALSE = 0
CONST RSHFT = 1, LSHFT = 2, CTRL = 4, ALT = 8, SCRL = 16, NUM = 32, CAPS = 64, NSRT = 128

SCREEN 0, 1, 0, 0: WIDTH 80, 25: VIEW PRINT: LOCATE , , 0

COLOR 0, 7: CLS
COLOR 15, 3: LOCATE 1, 1: PRINT " Exit  Copy  Paste  Find  Edit  Mark  Goto  Special  Load  Save" + SPACE$(17);
COLOR 7, 0: LOCATE 2, 1: PRINT " C:\WINDOWS\MY_FIRST.WRI     ³ Row:00001  Col:06  Abs:00006 ³ Size:00124 ³ CNIS ";
COLOR 0, 7
FOR Show = 3 TO 4
 READ Data$: LOCATE Show, 1: PRINT Data$;
NEXT Show
DATA "This not a fully functional program but is just a test","To see what the eventual product of the BytEdit program will look like"
COLOR 15: PRINT "þ";
MainHelpLine "Press the F1 for help or the Alt key to activate the menu", 1
LOCATE , , 1, 7, 8
'Create Editor
DO
 IF CallEnu THEN menu
 DataEditor Data$
UserWantsToQuit = 1
LOOP UNTIL UserWantsToQuit

SUB MainHelpLine (Text$, Mode%)
STATIC Help$
IF Mode% = 2 THEN
 Text$ = Help$
ELSEIF Mode% = 0 OR Mode% = 1 THEN
 IF Mode% THEN Help$ = MID$(Text$, 1, 78)
 COLOR 15, 3: LOCATE 25, 1: PRINT " "; Help$; SPACE$(79 - LEN(Help$));
END IF
END SUB

