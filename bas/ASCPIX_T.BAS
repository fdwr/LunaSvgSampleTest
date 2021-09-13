DEFINT A-Z
DECLARE SUB DrawBox (Urow, Drow, Lcol, Rcol)
DECLARE SUB SaveImage (File$, Image$, PictWdth, PictWdth)
DECLARE SUB PlotImageGraphic (Image$, Hite, Wdth)
DECLARE SUB ChngDrawColor (NewColor, PixColor, Mode)
DECLARE SUB MovePictCursor (newYrow, Yrow, newXcol, Xcol, Chng)
DECLARE SUB DrawPict (Image$, Yrow, Xcol, Mode)
DECLARE SUB LoadImage (File$, Image$, PictHite%, PictWdth%)
DECLARE SUB ShowKeyOptions ()
DECLARE FUNCTION GetPictPixColor% (Yrow%, Xcol%)
DECLARE FUNCTION GetFilName% (File$)

DIM SHARED PictWinUrow, PictWinDrow, PictWinLcol, PictWinRcol
DIM SHARED PictScrUrow, PictScrDrow, PictScrLcol, PictScrRcol
DIM SHARED ScrnColor, PictTileMode, PictWdth, PictHite, Image$, FilErr
ScrnColor = 7
PictWinUrow = 3: PictWinDrow = 13: PictWinLcol = 25: PictWinRcol = 48
PictScrUrow = 1: PictScrDrow = 8: PictScrLcol = 1: PictScrRcol = 8
PictTileMode = 0: Image$ = STRING$(64, 0)
PictHite = 8: PictWdth = 8

GOSUB DrawScreen
DO UNTIL UserDone
 key$ = INKEY$
 SELECT CASE key$
 CASE CHR$(0) + "H": MovePictCursor Yrow - 1, Yrow, -1, Xcol, Chng
 CASE CHR$(0) + "P": MovePictCursor Yrow + 1, Yrow, -1, Xcol, Chng
 CASE CHR$(0) + "K": MovePictCursor -1, Yrow, Xcol - 1, Xcol, Chng
 CASE CHR$(0) + "M": MovePictCursor -1, Yrow, Xcol + 1, Xcol, Chng
 CASE CHR$(0) + "s": ChngDrawColor PixColor - 1, PixColor, 0
 CASE CHR$(0) + "t": ChngDrawColor PixColor + 1, PixColor, 0
 CASE "s", "S": SaveImage File$, Image$, PictHite, PictWdth
 CASE "l", "L": LoadImage File$, Image$, PictHite, PictWdth
  DrawPict Image$, Yrow, Xcol, 1
  MovePictCursor Yrow, Yrow, Xcol, Xcol, Chng
 CASE "c", "C"
  Image$ = STRING$(PictWdth * PictHite, PixColor)
  DrawPict Image$, Yrow, Xcol, 1
  MovePictCursor Yrow, Yrow, Xcol, Xcol, Chng
 CASE CHR$(13)
  REDIM SpecImage(0 TO CINT(PictWdth / 4 + .1) * PictHite + 1)
  SCREEN 12
  LINE (0, 0)-(41, 169), 15, B
  PlotImageGraphic Image$, PictHite, PictWdth
  GET (PictScrLcol, PictScrUrow)-(PictScrRcol, PictScrDrow), SpecImage(0)
  FOR row = 0 TO 160 STEP 8
   FOR col = 0 TO 32 STEP 8
    PUT (PictScrLcol + col, PictScrUrow + row), SpecImage(0), PSET
  NEXT col, row
  FOR p = 0 TO UBOUND(SpecImage)
   LOCATE p MOD 30 + 1, p \ 30 + 7
   PRINT SpecImage(p);
  NEXT p
  WHILE INKEY$ = "": WEND
  GOSUB DrawScreen
 CASE CHR$(10)
  REDIM SpecImage(0 TO CINT(PictWdth / 4 + .1) * PictHite + 1)
  SCREEN 12
  PlotImageGraphic Image$, PictHite, PictWdth
  GET (PictScrLcol, PictScrUrow)-(PictScrRcol, PictScrDrow), SpecImage(0)
  SCREEN 0
  FOR p = 0 TO UBOUND(SpecImage)
   PRINT LTRIM$(STR$(SpecImage(p))); ",";
  NEXT p
  WHILE INKEY$ = "": WEND
  GOSUB DrawScreen
 CASE " ":
  MID$(Image$, ((Yrow MOD PictHite) * PictHite) + (Xcol MOD PictWdth) + 1, 1) = CHR$(PixColor)
  DrawPict Image$, Yrow, Xcol, 0
  MovePictCursor Yrow, Yrow, Xcol, Xcol, Chng
 CASE CHR$(27): UserDone = 1
 END SELECT

 IF Chng THEN
  Chng = 0
 END IF
LOOP
END

DrawScreen:
 SCREEN 0: WIDTH 80, 25: VIEW PRINT: COLOR , 7: CLS : LOCATE , , 0
 COLOR 15, ScrnColor: DrawBox PictWinUrow - 1, PictWinDrow + 6, PictWinLcol - 1, PictWinRcol + 9
 ShowKeyOptions
 DrawPict Image$, 0, 0, 1
 ChngDrawColor PixColor, PixColor, 1
 MovePictCursor Yrow, Yrow, Xcol, Xcol, Chng
RETURN

FilErrHandler:
FilErr = ERR
RESUME NEXT

SUB ChngDrawColor (NewColor, PixColor, Mode) STATIC
'Mode is a boolean value
'0 = Change color only and redraw arrow
'1 = Redraw the color bar also

IF Mode THEN
 LOCATE 25, 25: FOR Hset = 0 TO 15: COLOR Hset: PRINT "лл"; : NEXT Hset
END IF
PixColor = NewColor AND 15
IF PixColor <> OldColor OR Mode THEN
 COLOR , ScrnColor: LOCATE 24, 25 + (OldColor * 2): PRINT " ";
 COLOR 15, ScrnColor: LOCATE 24, 25 + (PixColor * 2): PRINT "";
 OldColor = PixColor
END IF
END SUB

SUB DrawBox (Urow, Drow, Lcol, Rcol)

Hwid = Rcol - Lcol - 1
IF Hwid < 0 THEN Hwid = 0

LOCATE Urow, Lcol: PRINT "к"; STRING$(Hwid, 196); "П";
FOR row = Urow + 1 TO Drow - 1
 LOCATE row, Lcol: PRINT "Г";
 LOCATE row, Rcol: PRINT "Г";
NEXT row
LOCATE Drow, Lcol: PRINT "Р"; STRING$(Hwid, 196); "й";
END SUB

SUB DrawPict (Image$, Yrow, Xcol, Mode)

: IF (PictWdth * PictHite) > LEN(Image$) THEN STOP
IF Mode THEN
 FOR pictTile = 0 TO 3
  p = 1
  GOSUB getPictTileCoor
  FOR row = 0 TO PictHite - 1
   FOR col = 0 TO PictWdth - 1
    COLOR ASC(MID$(Image$, p, 1)) AND 15
    LOCATE row + tileRow, col * 2 + tileCol: PRINT "лл";
    p = p + 1
   NEXT col
  NEXT row
 NEXT pictTile
ELSE
 FOR pictTile = 0 TO 3
  GOSUB getPictTileCoor
  COLOR ASC(MID$(Image$, ((Yrow MOD PictHite) * PictHite) + (Xcol MOD PictWdth) + 1, 1)) AND 15
  LOCATE Yrow MOD PictHite + tileRow, (Xcol MOD PictWdth) * 2 + tileCol: PRINT "лл";
 NEXT pictTile
END IF
EXIT SUB

getPictTileCoor:
tileRow = (pictTile AND 2) * 4 + PictWinUrow
tileCol = (pictTile AND 1) * 16 + PictWinLcol
RETURN

END SUB

FUNCTION GetFilName (File$)

COLOR 15, ScrnColor
Chng = 1
DO
 key$ = INKEY$
 SELECT CASE UCASE$(key$)
 CASE "!" TO "џ"
  IF INSTR("?*+=<>|" + CHR$(34), key$) = 0 THEN
   IF LEN(File$) < 128 THEN File$ = File$ + key$
   Chng = 1
  END IF
 CASE CHR$(8): IF LEN(File$) THEN File$ = LEFT$(File$, LEN(File$) - 1): Chng = 1
 CASE CHR$(27): GetFilName = 1: EXIT DO
 CASE CHR$(13): EXIT DO
 END SELECT
 IF Chng THEN
  LOCATE 1, 29: PRINT RIGHT$(File$, 29); TAB(58);
  Chng = 0
 END IF
LOOP

END FUNCTION

FUNCTION GetPictPixColor (Yrow, Xcol)
GetPictPixColor = ASC(MID$(Image$, ((Yrow MOD PictHite) * PictHite) + (Xcol MOD PictWdth) + 1, 1)) AND 15
END FUNCTION

SUB LoadImage (File$, Image$, PictHite, PictWdth)

ON ERROR GOTO FilErrHandler
DO
 COLOR 15, ScrnColor: LOCATE 1, 24: PRINT "Load:";
 IF GetFilName(File$) THEN ON ERROR GOTO 0: GOSUB LoadBlankLine: EXIT SUB
 FilErr = 0: OPEN File$ FOR INPUT AS #1: CLOSE #1
 IF FilErr THEN
  GOSUB LoadErr
 ELSE
  OPEN File$ FOR BINARY AS #1
  IF INPUT$(9, 1) <> CHR$(8) + "ASCIIPIX" THEN GOSUB LoadWrongType ELSE EXIT DO
  CLOSE #1
 END IF
LOOP

PictHite = ASC(INPUT$(1, 1))
PictWdth = ASC(INPUT$(1, 1))
Image$ = INPUT$(PictHite * PictWdth, 1)
CLOSE #1
ON ERROR GOTO 0
GOSUB LoadBlankLine

EXIT SUB

LoadBlankLine:
LOCATE 1, 24: PRINT TAB(58);
RETURN

LoadErr:
LOCATE 1, 24: PRINT "Error loading specified file"; TAB(58);
WHILE INKEY$ = "": WEND
RETURN

LoadWrongType:
LOCATE 1, 24: PRINT "This file is not an ASCII picture"; TAB(58);
WHILE INKEY$ = "": WEND
RETURN

END SUB

SUB MovePictCursor (newYrow, Yrow, newXcol, Xcol, Chng)

IF newYrow >= 0 AND newYrow < (PictHite * 2) THEN Chng = 1
IF newXcol >= 0 AND newXcol < (PictWdth * 2) THEN Chng = Chng OR 2
IF Chng THEN
 DrawPict Image$, Yrow, Xcol, 0
ELSE EXIT SUB
END IF

IF Chng AND 1 THEN Yrow = newYrow
IF Chng AND 2 THEN Xcol = newXcol

COLOR 15, GetPictPixColor(Yrow, Xcol)
LOCATE Yrow + PictWinUrow, Xcol * 2 + PictWinLcol: PRINT "";

END SUB

SUB PlotImageGraphic (Image$, Hite, Wdth)

p = 1
IF (Wdth * Hite) > LEN(Image$) THEN EXIT SUB
FOR row = 0 TO Hite - 1
 FOR col = 0 TO Wdth - 1
  PSET (col + PictScrLcol, row + PictScrUrow), ASC(MID$(Image$, p, 1)) AND 15
  p = p + 1
 NEXT col
NEXT row

END SUB

SUB SaveImage (File$, Image$, PictHite, PictWdth)

ON ERROR GOTO FilErrHandler
DO
 COLOR 15, ScrnColor: LOCATE 1, 24: PRINT "Save:";
 IF GetFilName(File$) THEN ON ERROR GOTO 0: GOSUB SaveBlankLine: EXIT SUB
 FilErr = 0: OPEN File$ FOR INPUT AS #1: CLOSE #1
 IF FilErr <> 53 AND FilErr > 0 THEN
  GOSUB SaveNameErr
 ELSEIF FilErr = 0 THEN
  LOCATE 1, 24: PRINT "Overwrite existing file, [y/n]?"; TAB(58);
  DO: key$ = INKEY$: LOOP UNTIL key$ > ""
  IF UCASE$(key$) = "Y" OR key$ = CHR$(13) THEN EXIT DO
 END IF
LOOP

FilErr = 0
OPEN File$ FOR OUTPUT AS #1
IF FilErr THEN GOSUB SaveNameErr: EXIT SUB
PRINT #1, CHR$(8); "ASCIIPIX"; CHR$(PictHite); CHR$(PictWdth); Image$;
CLOSE #1
ON ERROR GOTO 0
GOSUB SaveBlankLine

EXIT SUB

SaveBlankLine:
LOCATE 1, 24: PRINT TAB(58);
RETURN

SaveNameErr:
LOCATE 1, 24: PRINT "Error saving to specified file"; TAB(58);
WHILE INKEY$ = "": WEND
RETURN

END SUB

SUB ShowKeyOptions

text$ = "_Load/_Save/_Clear//_Arrow keys move cursor/_Ctrl and left or right/ change current color/_Esc quits program/_Enter views picture/_Ctrl+Enter views data"
p = 1
COLOR , ScrnColor
DO
 row = row + 1
 IF p > LEN(text$) THEN EXIT DO
 n = INSTR(p, text$, "/"): IF n = 0 THEN n = LEN(text$) + 2
 LOCATE row, 1
 IF MID$(text$, p, 1) = "_" THEN COLOR 15: PRINT MID$(text$, p + 1, 1); : p = p + 2
 COLOR 8: PRINT MID$(text$, p, n - p);
 p = n + 1
LOOP
END SUB

