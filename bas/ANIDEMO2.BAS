DEFINT A-Z
DECLARE SUB AniFrame ()
DECLARE SUB AddObject (Object$, Param$)
DECLARE SUB DelObject (Object%, Param$)
DECLARE SUB Character (Object$, Param$)
DECLARE SUB DrawChar (Hite, Wdth, Urow, Lcol, Pict$)
DECLARE SUB GetCharInfo (Object$, Param$, Urow, Lcol, Hite, Wdth, Pict$)

TYPE KirbyType
Yrow AS INTEGER
Xcol AS INTEGER
Ydir AS INTEGER
Xdir AS INTEGER
END TYPE

AddObject "m", "" + MKI$(0)
AddObject "B", "A"
DIM SHARED Object, Objects$, Objects$(1 TO 256), Kbrd$, Del, Arena(0 TO 19, 0 TO 12)

SCREEN 7: VIEW PRINT

DO UNTIL Done
Kbrd$ = INKEY$
SELECT CASE Kbrd$
CASE " ": GOSUB Pause
CASE CHR$(27): Done = 1
END SELECT

'Call objects
'Give messages to them
'Decide on what is recieved
'Erase old rectangles
'Draw new frames to screen

AniFrame
LOOP
END

Pause:
COLOR 15: LOCATE 25, 34: PRINT "*** Paused ***": PCOPY 1, 0: WHILE INKEY$ = "": WEND
RETURN

SUB AddObject (Object$, AddParam$)
LastObject = LEN(Objects$)
Objects$ = Objects$ + Object$
Objects$(LastObject + 1) = AddParam$
END SUB

SUB AniFrame
WAIT &H3DA, 8, 8: WAIT &H3DA, 8
END SUB

SUB BirdSimulate
END SUB

SUB Character (Object$, Param$)
SELECT CASE Object$
CASE "m"
r = ASC(MID$(Param$, 1, 1)): c = ASC(MID$(Param$, 2, 1))
SELECT CASE Kbrd$
CASE CHR$(0) + "H": IF r > 1 THEN r = r - 3: MID$(Param$, 3, 2) = MKI$(3)
CASE CHR$(0) + "K": IF c > 0 THEN c = c - 1
CASE CHR$(0) + "M": IF c < 75 THEN c = c + 1
END SELECT
IF r > 50 THEN DelObject Object, Param$: EXIT SUB
j = CVI(MID$(Param$, 3, 2))
IF r < 43 THEN r = r - j: MID$(Param$, 3, 2) = MKI$(j - 1)
IF r > 43 THEN r = 43
IF r < 0 THEN r = 0
MID$(Param$, 1, 1) = CHR$(r): MID$(Param$, 2, 1) = CHR$(c)
CASE "B"
r = ASC(MID$(Param$, 1, 1)): c = ASC(MID$(Param$, 2, 1))
f = ASC(MID$(Param$, 3, 1)): MID$(Param$, 3, 1) = CHR$((f + 1) MOD 4)
e$ = MID$(Param$, 4, 1): IF e$ = "P" THEN AddObject "E", CHR$(r + 2) + CHR$(c + 2): MID$(Param$, 4, 1) = CHR$(0) ELSE MID$(Param$, 4, 1) = CHR$(ASC(e$) + 1)
d = ASC(MID$(Param$, 5, 1))
IF d THEN IF c >= 73 THEN d = 0 ELSE MID$(Param$, 2, 1) = CHR$(c + 1) ELSE IF c <= 0 THEN d = 1 ELSE MID$(Param$, 2, 1) = CHR$(c - 1)
MID$(Param$, 5, 1) = CHR$(d)

CASE "b"
r = ASC(MID$(Param$, 1, 1)): c = ASC(MID$(Param$, 2, 1))
e = ASC(MID$(Param$, 4, 1)): IF e < 20 THEN MID$(Param$, 4, 1) = CHR$(e + 1)
SELECT CASE Kbrd$
CASE CHR$(0) + "H": IF r > 0 THEN r = r - 1
CASE CHR$(0) + "P": IF r < 45 THEN r = r + 1
CASE CHR$(0) + "K": IF c > 0 THEN c = c - 1
CASE CHR$(0) + "M": IF c < 73 THEN c = c + 1
CASE CHR$(13): IF e >= 20 THEN AddObject "E", CHR$(r + 2) + CHR$(c + 2): MID$(Param$, 4, 1) = CHR$(0)
END SELECT
IF Kbrd$ > "" THEN MID$(Param$, 1, 1) = CHR$(r): MID$(Param$, 2, 1) = CHR$(c)
f = ASC(MID$(Param$, 3, 1)): IF r = 45 THEN MID$(Param$, 3, 1) = "" ELSE MID$(Param$, 3, 1) = CHR$((f + 1) MOD 4)
CASE "E"
r = ASC(MID$(Param$, 1, 1)): c = ASC(MID$(Param$, 2, 1))
IF r >= 49 THEN DelObject Object, Param$ ELSE MID$(Param$, 1, 1) = CHR$(r + 1)
END SELECT
END SUB

SUB DelObject (ObjectNum, Param$)
LastObject = LEN(Objects$): IF ObjectNum > LastObject OR ObjectNum < 1 THEN EXIT SUB
Objects$ = LEFT$(Objects$, ObjectNum - 1) + RIGHT$(Objects$, LastObject - ObjectNum)
FOR DelObs = ObjectNum TO LastObject - 1
  Objects$(DelObs) = Objects$(DelObs + 1)
NEXT DelObs
Objects$(LastObject) = ""
Param$ = Objects$(Object)
IF Object <= ObjectNum THEN Del = Del - 1
END SUB

SUB DrawChar (Hite, Wdth, Urow, Lcol, Pict$)
FOR Dr = 1 TO Hite
   IF Urow + Dr > 0 AND Urow + Dr < 25 AND Lcol < 40 THEN LOCATE Urow + Dr, Lcol + 1: PRINT MID$(Pict$, (Dr - 1) * Wdth + 1, Wdth);
NEXT Dr
END SUB

SUB GetCharInfo (Object$, Param$, Urow, Lcol, Hite, Wdth, Pict$)
SELECT CASE UCASE$(Object$)
CASE "M": COLOR 14: Hite = 7: Wdth = 5: j = CVI(MID$(Param$, 3, 2))
Urow = ASC(MID$(Param$, 1, 1)): Lcol = ASC(MID$(Param$, 2, 1))
IF j = 0 THEN Pict$ = "  л    л   ллл л л л  л   л л  л л " ELSE IF j > 0 THEN Pict$ = "  л    л   ллл  ллл   л   л л  л л " ELSE Pict$ = "  л  л л л ллл   л    л   л л  л л "
CASE "B": COLOR 1: Hite = 5: Wdth = 7: Urow = ASC(MID$(Param$, 1, 1)): Lcol = ASC(MID$(Param$, 2, 1))
SELECT CASE ASC(MID$(Param$, 3, 1))
CASE 0: Wing$ = "  ллл    ллл  "
CASE 1, 3: Wing$ = " ллллл   ллл  "
CASE 2: Wing$ = "ллллллл ллллл "
CASE 4: Wing$ = " ллллл  ллллл "
END SELECT
Pict$ = "   л   " + Wing$ + "  ллл    л л  "
CASE "E": Urow = ASC(MID$(Param$, 1, 1)): Lcol = ASC(MID$(Param$, 2, 1))
COLOR 15: Hite = 3: Wdth = 3: Pict$ = " л ллл л "
CASE ELSE: Hite = 0: Wdth = 0: Pict$ = ""
END SELECT
END SUB

SUB KirbySimulate
END SUB

