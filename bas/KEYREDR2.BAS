'1997-06-25 Displays ASCII key code and scan code from BIOS buffer.

DEFINT A-Z
DECLARE SUB BOX (h, w, l, c, f, b, t, i$)
SCREEN 0: PCOPY 0, 1: prer = CSRLIN: prec = POS(0): LOCATE , , 0

'Growing the window
FOR grow = 1 TO 72 STEP 3
 BOX 8, INT(grow), 10, INT(39 - (grow / 2)), 10, 3, 15, ""
 WAIT &H3DA, 8
NEXT grow
BOX 8, 72, 10, 3, 10, 3, 15, "Key Buffer Reader"

COLOR 0
LOCATE 17, 10: PRINT "Keylock status: Shift, Alt, Ctrl, plus Caps, Scroll, and Num Lock"
LOCATE 18, 10: PRINT "Key Input counter: 16 place range 30 - 60 Memory location 1050"
LOCATE 11, 36: PRINT "- ASCII symbol code": LOCATE , 36: PRINT "- Keyboard Scancode -"
COLOR 15, 0: FOR hole = 4 TO 35 STEP 2: LOCATE 11, hole: PRINT " ": LOCATE , hole: PRINT " "; : NEXT
COLOR 15, 3
DO: DEF SEG = 0
IF PEEK(1050) <> KeyCounter THEN IF KeyCounter >= 30 AND KeyCounter <= 60 THEN LOCATE 13, (KeyCounter - 30) + 4: PRINT " ";
KeyCounter = PEEK(1050): IF KeyCounter >= 30 AND KeyCounter <= 60 THEN LOCATE 13, (KeyCounter - 30) + 4: PRINT "";

LOCATE 15, 5: PRINT LEFT$(STR$(PEEK(1054)) + "  ", 4);
LOCATE 16, 5: PRINT LEFT$(STR$(PEEK(1055)) + "  ", 4);
LOCATE 17, 5: PRINT LEFT$(STR$(PEEK(1047)) + "  ", 4);
LOCATE 18, 5: PRINT LEFT$(STR$(KeyCounter) + "  ", 4);
IF INP(96) AND 128 THEN Stat$ = "" ELSE Stat$ = ""
LOCATE 12, 58: PRINT Stat$;
FOR look = 0 TO 31 STEP 2
DEF SEG = 0: buffer = PEEK(look + 1054)
DEF SEG = &HB864: POKE (3 + look) * 2, buffer
DEF SEG = 0: buffer = PEEK(look + 1055)
DEF SEG = &HB864: POKE (83 + look) * 2, buffer
NEXT look
LOOP UNTIL INKEY$ = ""

'Closing the window
PCOPY 1, 2: SCREEN , , 2, 0
FOR grow = 72 TO 1 STEP -3
 BOX 8, INT(grow), 10, INT(39 - (grow / 2)), 10, 3, 15, ""
 WAIT &H3DA, 8
 PCOPY 2, 0: PCOPY 1, 2
NEXT grow
PCOPY 1, 0: SCREEN , , 0, 0: LOCATE prer, prec
SYSTEM

SUB BOX (h, w, l, c, f, b, t, i$)

COLOR f, b
LOCATE l, c: PRINT "Ú"; STRING$(w, 196); "¿";
FOR Hset = 1 TO h
LOCATE l + Hset, c: PRINT "³"; STRING$(w, 32); "³";
NEXT Hset
LOCATE l + Hset, c: PRINT "À"; STRING$(w, 196); "Ù";

COLOR 0, 0: FOR Hset = 1 TO h + 1
LOCATE l + Hset, c + w + 2: PRINT "  ";
NEXT Hset
LOCATE l + Hset, c + 2: PRINT SPACE$(w + 2);

LOCATE l, c + 1 + (w - LEN(MID$(i$, 1, w))) / 2: COLOR t, b: PRINT LEFT$(i$, w)

END SUB

