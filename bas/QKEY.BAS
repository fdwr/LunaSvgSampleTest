'6-13-97
'2-23-99
DEFINT A-Z
DECLARE SUB xprint (text$, v, h)
CONST v = 16, h = 40

SCREEN 0, , 0, 0: VIEW PRINT: COLOR 7, 0: CLS : LOCATE , , 0
LOCATE 1, 1: PRINT "  This program displays ASCII characters recieved from the keyboard using the"
PRINT "QBasic INKEY$ function. It shows all characters including control characters,"
PRINT "since it directly updates the screen with a specially made xprint SUB. It does"
PRINT "not use the normal PRINT statement and SCRN device because of the irregular"
PRINT "(and somewhat annoying) control functions applied whenever control characters"
PRINT "are printed. Instead, it writes straight to text memory, segment B800 or 47104"
PRINT "in dec. Press any key on the keyboard to see its real character at the prompt"
PRINT "(except for any keystate shift keys like shift, ctrl, alt, caps, num, and scrl)"
PRINT "And you will not have to worry about the computer making an irritating beep at"
PRINT "you - no matter what you press (except Ctrl-Alt-Del, of course)."

GOSUB ShowKeyValue
DO
 kbrd$ = INKEY$: IF kbrd$ > "" THEN KeyDown = -1: GOSUB ShowKeyValue
 IF KeyDown THEN IF INP(96) AND 128 THEN kbrd$ = "": KeyDown = 0: GOSUB ShowKeyValue
LOOP UNTIL kbrd$ = CHR$(27)
END

ShowKeyValue:
 LOCATE v, h - 11: IF NOT KeyDown THEN PRINT "Key Up  ";  ELSE PRINT "Key Down"; : IF c < 32767 THEN c = c + 1
 LOCATE v, h - 1: PRINT "";
 COLOR 7, 0: PRINT SPACE$(LEN(kbrd));
 xprint kbrd$, v, h
 LOCATE v, h + LEN(kbrd$): PRINT "  ";
 LOCATE v, h + 4: PRINT c; TAB(h + 3);
RETURN

SUB xprint (text$, v, h)
 DEF SEG = &HB800: start = (v - 1) * 80 + h - 2
 FOR ofset = 1 TO LEN(text$)
  POKE (start + ofset) * 2, ASC(MID$(text$, ofset, 1))
 NEXT ofset
END SUB

