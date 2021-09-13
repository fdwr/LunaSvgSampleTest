DEFINT A-Z
DECLARE SUB DrawDiamond (Angle!)
DECLARE SUB DrawBorder (Urow, Drow, Lcol, Rcol)

SCREEN 7: VIEW PRINT
SCREEN , , 1: GOSUB DrawPreScreen
SCREEN , , 0: GOSUB DrawPreScreen

Angle! = 0: Renew = 1
DO
 SELECT CASE INP(96)
 CASE 54: Angle! = Angle! + .0625: IF Angle! > 6.28 THEN Angle! = 0
 CASE 42: Angle! = Angle! - .0625: IF Angle! < 0 THEN Angle! = 6.25
 END SELECT
 Key$ = INKEY$: IF Key$ = " " THEN Renew = Renew XOR 1: SCREEN , , CurScreen XOR 1 ELSE IF Key$ = CHR$(27) THEN EXIT DO

 IF Renew THEN GOSUB ClearScreenNextScene

 LOCATE 2, 9: PRINT Angle!; TAB(17);
 LOCATE 3, 9: PRINT STR$(INT(Angle! * 57.6)); "ø  ";
 LINE (138, 15)-(COS(Angle!) * 10 + 138, SIN(Angle!) * 10 + 15), 12
 DrawDiamond Angle!
LOOP

'SCREEN 0, , 0, 0
'WIDTH 80, 25
END

ClearScreenNextScene:
 SCREEN , , CurrScreen, CurrScreen XOR 1
 WAIT &H3DA, 8
 LINE (60, 50)-(260, 150), 0, BF
 LINE (128, 5)-(148, 25), 0, BF
 CurrScreen = CurrScreen XOR 1
RETURN

DrawPreScreen:
VIEW (0, 0)-(319, 199), 7
DrawBorder 3, 27, 59, 150
LINE (60, 4)-(149, 26), 0, BF
DrawBorder 48, 152, 58, 262
LINE (59, 49)-(261, 151), 0, B
LINE (0, 183)-(319, 183), 8
LOCATE 24, 1: PRINT "Use left shift and right shift to rotate";
LOCATE 25, 1: PRINT "the crystal, press Space to create trail";
RETURN

SUB DrawBorder (Urow, Drow, Lcol, Rcol)
LINE (Lcol, Urow)-(Lcol, Drow), 8
LINE (Lcol, Drow)-(Rcol, Drow), 15
LINE (Rcol, Urow)-(Rcol, Drow), 15
LINE (Lcol, Urow)-(Rcol, Urow), 8
END SUB

SUB DrawDiamond (Angle!)

PointL = 160 + COS(Angle!) * 100
PointR = 160 + COS(Angle! + 3.14) * 100
PointU = 160 + COS(Angle! + 1.57) * 50
PointD = 160 + COS(Angle! + 4.71) * 50
PointI = 160 + COS(Angle! + 1.57) * 25
PointO = 160 + COS(Angle! + 4.71) * 25

LINE (PointU, 50)-(PointL, 100), 10 'Top four lines
LINE (PointU, 50)-(PointR, 100), 2
LINE (PointU, 50)-(PointI, 125), 1
LINE (PointU, 50)-(PointO, 75), 9
LINE (PointL, 100)-(PointI, 125), 4 'Four rim lines
LINE (PointL, 100)-(PointO, 75), 4
LINE (PointR, 100)-(PointI, 125), 12
LINE (PointR, 100)-(PointO, 75), 12
LINE (PointD, 150)-(PointL, 100), 10 'Bottom four lines
LINE (PointD, 150)-(PointR, 100), 2
LINE (PointD, 150)-(PointI, 125), 1
LINE (PointD, 150)-(PointO, 75), 9

'Dot = PSET (COS(Angle#) * 100 + 160, 100), Color?

END SUB

