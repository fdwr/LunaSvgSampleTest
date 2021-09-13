DEFINT A-Z
port& = &H61: dat$ = "0": hexdat$ = "0": mode = 2
limit(0) = 5
limit(1) = 4
limit(2) = 3
limit(3) = 2

COLOR 15, 1: LOCATE 1, 1, 0: PRINT "ÚPortÄÄÄÄÄHexÄ¿   ÚValueÄÄÄHex¿"
DO
 kbrd$ = UCASE$(INKEY$)
 SELECT CASE kbrd$
 CASE CHR$(0) + "H": IF port& < 65535 THEN port& = port& + 1: chng = 1
 CASE CHR$(0) + "P": IF port& > 0 THEN port& = port& - 1: chng = 1
 CASE CHR$(0) + "K", CHR$(0) + "M"
  IF kbrd$ = CHR$(0) + "K" THEN mode = (mode + 3) MOD 4 ELSE mode = (mode + 1) MOD 4
  IF mode = 0 THEN num$ = LTRIM$(STR$(port&)) ELSE IF mode = 1 THEN num$ = HEX$(port&) ELSE IF mode = 2 THEN num$ = dat$ ELSE num$ = hexdat$
 CASE "0" TO "9": chng = 1: IF LEN(num$) < limit(mode) THEN IF num$ = "0" THEN num$ = kbrd$ ELSE num$ = num$ + kbrd$
 CASE "A" TO "F": chng = 1: IF mode AND 1 THEN IF LEN(num$) < limit(mode) THEN IF num$ = "0" THEN num$ = kbrd$ ELSE num$ = num$ + kbrd$
 CASE CHR$(8): chng = 1: IF LEN(num$) > 0 THEN num$ = LEFT$(num$, LEN(num$) - 1): IF num$ = "" THEN num$ = "0"
 CASE CHR$(13): dat = VAL(dat$): OUT port&, dat
 CASE CHR$(27): EXIT DO
 END SELECT
 IF chng THEN
  IF mode = 0 THEN
   port& = VAL(num$)
  ELSEIF mode = 1 THEN port& = VAL("&H" + num$)
  ELSEIF mode = 2 THEN IF LEN(num$) >= 3 AND num$ > "255" THEN dat$ = "255": num$ = "255" ELSE dat$ = num$
   hexdat$ = HEX$(VAL(dat$))
  ELSE hexdat$ = num$: dat$ = LTRIM$(STR$(VAL("&H" + hexdat$)))
  END IF
  IF port& > 65535 THEN port& = 65535
  chng = 0
 END IF
 
 bar$ = SPACE$(31): MID$(bar$, 1, 6) = STR$(port&): MID$(bar$, 11, 4) = HEX$(port&): MID$(bar$, 20, 3) = dat$: MID$(bar$, 29, 2) = hexdat$: LOCATE 2, 1: PRINT bar$;
 bar$ = SPACE$(31): MID$(bar$, mode * 9 + 2, 1) = "": LOCATE 3, 1: PRINT bar$;
LOOP

END

