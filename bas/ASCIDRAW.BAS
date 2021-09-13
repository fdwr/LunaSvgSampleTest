DEFINT A-Z
DECLARE SUB DrawChar (AsciChar%, Vof%, Hof%)
DECLARE FUNCTION AsciiCorner% (Crnr%)
LOCATE , , 1, 1, 16: Hof% = 39: Vof% = 11
ASCIIlist$ = "  b°B±n²NÛqÚw¿aÀsÙQÉW»AÈS¼eÕr¸dÔf¾EÖR·DÓF½tÂyÑgÁhÏTËYÒGÊHÐuÃi´jÆkµUÌI¹JÇK¶z³xÄZºXÍcÅvØCÎV×"

DO UNTIL Kbrd$ = ""
LOCATE Vof% + 1, Hof% + 1
Phf% = Hof%: Pvf% = Vof%

Kbrd$ = INKEY$: IF Kbrd$ > "" THEN Pdr$ = Dir$
DEF SEG = 0: Shft = PEEK(1047) AND 3: Caps = PEEK(1047) AND 64
SELECT CASE Kbrd$
CASE CHR$(0) + "H": IF Vof% > 0 THEN Vof% = Vof% - 1: Dir$ = "Up"
CASE CHR$(0) + "P": IF Vof% < 24 THEN Vof% = Vof% + 1: Dir$ = "Down"
CASE CHR$(0) + "K": IF Hof% > 0 THEN Hof% = Hof% - 1: Dir$ = "Left"
CASE CHR$(0) + "M": IF Hof% < 79 THEN Hof% = Hof% + 1: Dir$ = "Right"
CASE CHR$(13): COLOR 15, 0: CLS
CASE " ": DrawChar 0, Vof, Hof
CASE "": EXIT DO
CASE "":
CASE ELSE: IF INSTR(ASCIIlist$, Kbrd$) THEN DrawChar ASC(MID$(ASCIIlist$, INSTR(ASCIIlist$, Kbrd$) + 1, 1)), Vof, Hof
END SELECT

IF Shft AND Kbrd$ > "" THEN
 IF Dir$ = "Up" THEN
  IF Pdr$ = "Right" THEN Crnr = 7 ELSE IF Pdr$ = "Left" THEN Crnr = 6 ELSE Crnr = 1
 ELSEIF Dir$ = "Down" THEN
  IF Pdr$ = "Right" THEN Crnr = 5 ELSE IF Pdr$ = "Left" THEN Crnr = 4 ELSE Crnr = 1
 ELSEIF Dir$ = "Right" THEN
  IF Pdr$ = "Up" THEN Crnr = 4 ELSE IF Pdr$ = "Down" THEN Crnr = 6 ELSE Crnr = 2
 ELSEIF Dir$ = "Left" THEN
  IF Pdr$ = "Up" THEN Crnr = 5 ELSE IF Pdr$ = "Down" THEN Crnr = 7 ELSE Crnr = 2
 ELSE Crnr = 0
 END IF
 IF Caps THEN Crnr = Crnr + 16
 RealCrnr = AsciiCorner(Crnr)
 DrawChar RealCrnr, Pvf, Phf
'1=179 2=196 4=218 5=191 7=217 6=192
END IF
LOOP
END

FUNCTION AsciiCorner (Crnr)
'1=179 2=196 4=218 5=191 6=192 7=217
Corners$ = " ³Ä Ú¿ÀÙ         ºÍ É»È¼        "
IF Crnr > LEN(Corners$) OR Crnr < 0 THEN EXIT FUNCTION
AsciiCorner = ASC(MID$(Corners$, Crnr + 1, 1))
END FUNCTION

DEFSNG A-Z
SUB DrawChar (AsciChar%, Vof%, Hof%)
DEF SEG = &HB800: POKE ((Vof% * 80) + Hof%) * 2, AsciChar%
END SUB

