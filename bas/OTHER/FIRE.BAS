' ***************************************************************************
' ** FIRE created by:   Colin Hutchings    8-2-96                          **
' ***************************************************************************
DECLARE SUB AddSource ()
DECLARE SUB AnimateFlames ()
DECLARE SUB KindleFire ()
DECLARE SUB InitPal (ScrnMode%)
DECLARE SUB ChangeColor (ColNum%, Red%, Green%, Blue%)
DECLARE SUB SavePalette (Filename$)
DECLARE SUB LoadPalette (Filename$)

DIM SHARED PaletteColor%(255, 3)
DIM SHARED FireX%(2000), FireY(2000), FireColor(2000), FireMovRate(2000)

RANDOMIZE TIMER
InitPal 13

FOR Red% = 0 TO 60 STEP 2
      CurrClr% = CurrClr% + 1
      ChangeColor CurrClr%, Red%, (Red% / 5), 0
NEXT


DIM SHARED FireAmount%

FireAmount% = 1000

KindleFire
LINE (137, 97)-(185, 121), 33, B
COLOR 31: LOCATE 20, 12: PRINT "By Colin Hutchings"
1 AnimateFlames
GOTO 1

SUB AddSource
rand% = INT(23 * RND)
IF rand% > -1 AND vert% < 7 THEN vert% = 0
IF rand% > 6 AND vert% < 12 THEN vert% = 1
IF rand% > 11 AND vert% < 16 THEN vert% = 2
IF rand% > 15 AND vert% < 19 THEN vert% = 3
IF rand% > 18 AND vert% < 21 THEN vert% = 4
IF rand% > 20 AND vert% < 22 THEN vert% = 5
IF rand% = 22 THEN vert% = 6

PSET (INT(40 * RND) + 141, 120 - vert%), INT(10 * RND) + 22
END SUB

SUB AnimateFlames
FOR y% = 100 TO 120
FOR x% = 140 TO 182
      Clr% = POINT(x%, y%)
      IF Clr% > 1 THEN
Redo1:      RndAmt1% = (4 * RND)
            IF Clr% - RndAmt1% < 0 GOTO Redo1
Redo2:      RndAmt2% = (4 * RND)
            IF Clr% - RndAmt2% < 0 GOTO Redo2
Redo3:      RndAmt3% = (4 * RND)
            IF Clr% - RndAmt3% < 0 GOTO Redo3

            RndXamt1% = (2 * RND)
            RndXamt2% = (2 * RND)

            PSET (x%, y% - 1), Clr% - RndAmt3%
            PSET (x% - RndXamt1%, y% - 1), Clr% - RndAmt1%
            PSET (x% + RndXamt2%, y% - 1), Clr% - RndAmt2%
      END IF
NEXT x%
      IF INT(100 * RND) = 0 THEN AddSource
      IF INKEY$ <> "" THEN SCREEN 0: WIDTH 80, 25: END
NEXT y%
END SUB

SUB ChangeColor (ColNum%, Red%, Green%, Blue%)
IF PaletteColor%(0, 0) <> -1 THEN PRINT "Library not initialized (INITPAL)": GOTO EndIt
Colors% = PaletteColor%(1, 0)
IF ColNum% > Colors% THEN BEEP: PRINT "Color not supported by this screen mode": GOTO EndIt

IF ColNum% < 0 OR Red% < 0 OR Red% > 63 OR Green% < 0 OR Green% > 63 OR Blue% < 0 OR Blue% > 63 GOTO Err1
PaletteColor%(ColNum%, 1) = Red%
PaletteColor%(ColNum%, 2) = Green%
PaletteColor%(ColNum%, 3) = Blue%
PALETTE ColNum%, 65536 * Blue% + 256 * Green% + Red%
GOTO EndIt

Err1:
BEEP: PRINT "palette out of range"

EndIt:
END SUB

SUB InitPal (ScrnMode%)

IF ScrnMode% <> 7 AND ScrnMode% <> 8 AND ScrnMode% <> 9 AND ScrnMode% <> 12 AND ScrnMode% <> 13 THEN BEEP: PRINT "valid screen modes include: 7,8,9,12,13": END
IF ScrnMode% < 13 THEN Colors% = 16 ELSE Colors% = 256

SCREEN ScrnMode%

PaletteColor%(0, 0) = -1
PaletteColor%(1, 0) = Colors%

END SUB

SUB KindleFire
FOR a% = 1 TO FireAmount%
      rand% = INT(23 * RND)
      IF rand% > -1 AND vert% < 7 THEN vert% = 0
      IF rand% > 6 AND vert% < 12 THEN vert% = 1
      IF rand% > 11 AND vert% < 16 THEN vert% = 2
      IF rand% > 15 AND vert% < 19 THEN vert% = 3
      IF rand% > 18 AND vert% < 21 THEN vert% = 4
      IF rand% > 20 AND vert% < 22 THEN vert% = 5
      IF rand% = 22 THEN vert% = 6
                                
      PSET (INT(47 * RND) + 138, 120 - vert%), INT(10 * RND) + 22
NEXT
END SUB

SUB LoadPalette (Filename$)
IF PaletteColor%(0, 0) <> -1 THEN PRINT "Library not initialized (INITPAL)": GOTO EndSub1
IF Filename$ = "" THEN BEEP: PRINT "invalid filename": GOTO EndSub1

OPEN Filename$ FOR BINARY AS 1
IF LOF(1) = 0 THEN CLOSE : BEEP: PRINT "file doesn't exists": GOTO EndSub1

DIM Byte1 AS STRING * 1

GET 1, 1, Byte1
PaletteColor%(1, 0) = ASC(Byte1)
IF PaletteColor%(1, 0) = 15 OR PaletteColor%(1, 0) = 255 GOTO Ok ELSE CLOSE : BEEP: PRINT "Invalid palette file": GOTO EndSub1

Ok:
CurrLine% = 2

FOR CurrColor% = 0 TO 255
      FOR RGB% = 1 TO 3
            CurrLine% = CurrLine% + 1
            GET 1, CurrLine%, Byte1
            PaletteColor%(CurrColor%, RGB%) = ASC(Byte1)
      NEXT RGB%
      ChangeColor CurrColor%, PaletteColor%(CurrColor%, 1), PaletteColor%(CurrColor%, 2), PaletteColor%(CurrColor%, 3)
NEXT CurrColor%
CLOSE

EndSub1:
END SUB

SUB SavePalette (Filename$)
IF PaletteColor%(0, 0) <> -1 THEN PRINT "Library not initialized (INITPAL)": GOTO EndSub
IF Filename$ = "" THEN BEEP: PRINT "invalid filename": GOTO EndSub

OPEN Filename$ FOR BINARY AS 1
IF LOF(1) = 0 GOTO Ok2
IF LOF(1) = 50 OR LOF(1) = 770 GOTO Ok1 ELSE CLOSE : BEEP: PRINT "file already exists and is not a palette file": GOTO EndSub

Ok1:
CLOSE
KILL Filename$
OPEN Filename$ FOR BINARY AS 1


Ok2:
DIM Byte1 AS STRING * 1

Byte1 = CHR$(PaletteColor%(1, 0) - 1)
PUT 1, 1, Byte1
Byte1 = CHR$(0)
PUT 1, 2, Byte1
CurrLine% = 2

FOR CurrColor% = 0 TO (PaletteColor%(1, 0) - 1)
      FOR RGB% = 1 TO 3
            CurrLine% = CurrLine% + 1
            Byte1 = CHR$(PaletteColor%(CurrColor%, RGB%))
            PUT 1, CurrLine%, Byte1
      NEXT RGB%
NEXT CurrColor%
CLOSE

EndSub:
END SUB

