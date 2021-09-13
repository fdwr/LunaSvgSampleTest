DEFINT A-Z
DECLARE SUB DrawBox (Urow, Drow, Lcol, Rcol)
DECLARE SUB PlotPoint (Image$, Row, Col, Hite, Wdth, mode)
DECLARE SUB SaveImage (File$, Image$, Ylim, Xlim)
DECLARE SUB PlotImageGraphic (Image$, Hite, Wdth)

DIM SHARED PictWinUrow, PictWinDrow, PictWinLcol, PictWinRcol, PictScrUrow, PictScrDrow, PictScrLcol, PictScrRcol
PictWinUrow = 6: PictWinDrow = 13: PictWinLcol = 33: PictWinRcol = 48
PictScrUrow = 1: PictScrDrow = 8: PictScrLcol = 1: PictScrRcol = 8
Ylim = 8: Xlim = 8: Image$ = STRING$(64, 0)

GOSUB DrawScreen
DO UNTIL UserDone
 key$ = UCASE$(INKEY$)
 SELECT CASE key$
 CASE CHR$(0) + "H": IF Yrow > 0 THEN sYrow = Yrow - 1: Chng = 1
 CASE CHR$(0) + "P": IF Yrow < Ylim - 1 THEN sYrow = Yrow + 1: Chng = 1
 CASE CHR$(0) + "K": IF Xcol > 0 THEN sXcol = Xcol - 1: Chng = 1
 CASE CHR$(0) + "M": IF Xcol < Xlim - 1 THEN sXcol = Xcol + 1: Chng = 1
 CASE CHR$(0) + "O": IF Ylim < 20 THEN Ylim = Ylim + 1
 CASE CHR$(0) + "G": IF Ylim > 0 THEN Ylim = Ylim - 1
 CASE CHR$(0) + "S": IF Xlim < 20 THEN Xlim = Xlim + 1
 CASE CHR$(0) + "Q": IF Xlim > 0 THEN Xlim = Xlim - 1
 CASE CHR$(13)
  REDIM SpecImage(0 TO CINT(Xlim / 4 + .1) * Ylim + 1)
  SCREEN 12
  LINE (PictScrLcol - 1, PictScrUrow - 1)-(PictScrRcol + 9, PictScrDrow + 9), 15, B
  PlotImageGraphic Image$, Ylim, Xlim
  GET (PictScrLcol, PictScrUrow)-(PictScrRcol, PictScrDrow), SpecImage(0)
  PUT (PictScrLcol + 8, PictScrUrow), SpecImage(0)
  PUT (PictScrLcol, PictScrUrow + 8), SpecImage(0)
  PUT (PictScrLcol + 8, PictScrUrow + 8), SpecImage(0)
  FOR p = 0 TO UBOUND(SpecImage)
   LOCATE p MOD 28 + 3, p \ 28 + 1
   PRINT SpecImage(p);
  NEXT p
  WHILE INKEY$ = "": WEND
  GOSUB DrawScreen
 CASE CHR$(10)
  REDIM SpecImage(0 TO CINT(Xlim / 4 + .1) * Ylim + 1)
  SCREEN 12
  PlotImageGraphic Image$, Ylim, Xlim
  GET (PictScrLcol, PictScrUrow)-(PictScrRcol, PictScrDrow), SpecImage(0)
  SCREEN 0
  FOR p = 0 TO UBOUND(SpecImage)
   PRINT LTRIM$(STR$(SpecImage(p))); ",";
  NEXT p
  WHILE INKEY$ = "": WEND
  GOSUB DrawScreen
 CASE CHR$(9): Colr = (Colr + 1) MOD 16: GOSUB ShowColor
 CASE CHR$(0) + "": Colr = (Colr + 15) MOD 16: GOSUB ShowColor
 CASE " ":
  IF (Yrow * Ylim) + Xcol < LEN(Image$) THEN
   MID$(Image$, (Yrow * Ylim) + Xcol + 1, 1) = CHR$(Colr)
   PlotPoint Image$, Yrow, Xcol, Ylim, Xlim, 2
  END IF
 CASE CHR$(27): UserDone = 1
 CASE "0" TO "9", "A" TO "F": Colr = INSTR("0123456789ABCDEF", key$) - 1
  IF (Yrow * Ylim) + Xcol + 1 < LEN(Image$) THEN
   MID$(Image$, (Yrow * Ylim) + Xcol + 1, 1) = CHR$(Colr)
   PlotPoint Image$, Yrow, Xcol, Ylim, Xlim, 2: GOSUB ShowColor
  END IF
 END SELECT

 IF Chng THEN
  PlotPoint Image$, Yrow, Xcol, Ylim, Xlim, 1
  Yrow = sYrow: Xcol = sXcol
  PlotPoint Image$, Yrow, Xcol, Ylim, Xlim, 2
  Chng = 0
 END IF
LOOP
END

ShowColor: COLOR 10, 3: DrawBox 15, 17, 32, 49: LOCATE 17, 33 + Colr: PRINT ""; : LOCATE 16, 33: FOR Hset = 0 TO 15: COLOR Hset: PRINT "л"; : NEXT Hset: RETURN
DrawScreen:
 SCREEN 0: WIDTH 80, 25: VIEW PRINT: COLOR , 7: CLS : LOCATE , , 0
 COLOR 10, 3: DrawBox PictWinUrow - 1, PictWinDrow + 1, PictWinLcol - 1, PictWinRcol + 1
 PlotPoint Image$, 0, 0, Ylim, Xlim, 0
 GOSUB ShowColor: Chng = 1
RETURN

SUB DrawBox (Urow, Drow, Lcol, Rcol)

Hwid = Rcol - Lcol - 1
IF Hwid < 0 THEN Hwid = 0

LOCATE Urow, Lcol: PRINT "к"; STRING$(Hwid, 196); "П";
FOR Row = Urow + 1 TO Drow - 1
 LOCATE Row, Lcol: PRINT "Г";
 LOCATE Row, Rcol: PRINT "Г";
NEXT Row
LOCATE Drow, Lcol: PRINT "Р"; STRING$(Hwid, 196); "й";
END SUB

SUB PlotImageGraphic (Image$, Hite, Wdth)

p = 1
IF (Wdth * Hite) > LEN(Image$) THEN EXIT SUB
FOR Row = 0 TO Hite - 1
 FOR Col = 0 TO Wdth - 1
  PSET (Col + PictScrLcol, Row + PictScrUrow), ASC(MID$(Image$, p, 1)) AND 15
  p = p + 1
 NEXT Col
NEXT Row

END SUB

SUB PlotPoint (Image$, Row, Col, Hite, Wdth, mode)

IF mode = 0 THEN
 p = 1
 IF (Wdth * Hite) > LEN(Image$) THEN EXIT SUB
 FOR Row = 0 TO Hite - 1
  FOR Col = 0 TO Wdth - 1
   COLOR ASC(MID$(Image$, p, 1)) AND 15
   LOCATE Row + PictWinUrow, Col * 2 + PictWinLcol: PRINT "лл";
   p = p + 1
  NEXT Col
 NEXT Row
ELSE
 IF (Row * Hite) + Col + 1 > LEN(Image$) THEN EXIT SUB
 Colr = ASC(MID$(Image$, (Row * Hite) + Col + 1, 1)) AND 15
 LOCATE Row + PictWinUrow, Col * 2 + PictWinLcol
 IF mode = 2 THEN
  IF Colr = 0 THEN COLOR 15, 0: PRINT "";  ELSE COLOR Colr + 16, 0: PRINT "лл";
 ELSE
  COLOR Colr: PRINT "лл";
 END IF
END IF

END SUB

SUB SaveImage (File$, Image$, Ylim, Xlim)
OPEN File$ FOR OUTPUT AS #1
PRINT CHR$(8); "ASCIIPIX"; CHR$(Ylim); CHR$(Xlim); Image$;
END SUB

