DEFINT A-Z: SCREEN 12: lin% = 100: col% = 160: visible% = -1
DO
SELECT CASE INP(96)
CASE 72: vdir = -1
CASE 80: vdir = 1
CASE 75: hdir = -1
CASE 77: hdir = 1
CASE 170: vdir = 0: hdir = 0
END SELECT
lin = lin + vdir
col = col + hdir
SELECT CASE INKEY$
CASE CHR$(0) + "<": IF depth% < 32 THEN depth% = depth% + 1
CASE CHR$(0) + ";": IF depth% > -32 THEN depth% = depth% - 1
CASE " ": IF visible% <> 0 THEN visible% = 0 ELSE visible% = -1
CASE "": END
END SELECT

Rcol% = col% - depth%: Bcol% = col% + depth%
Rcheck% = POINT(Rcol%, lin%): Bcheck% = POINT(Bcol%, lin%)
IF Rcheck% = 1 OR Rcheck% = 5 THEN Rcolr% = 5 ELSE Rcolr% = 4
IF Bcheck% = 4 OR Bcheck% = 5 THEN Bcolr% = 5 ELSE Bcolr% = 1
IF (Rcol%) = (Bcol%) THEN Rcolr% = 5: Bcolr% = 5
 IF visible% THEN vis$ = "Visible" ELSE vis$ = "Hidden "
LOCATE 1, 1: PRINT "3D depth"; depth%; "Line"; lin%; "Column"; col%; vis$; "  "
IF visible% THEN
PSET (Rcol%, lin%), Rcolr%
PSET (Bcol%, lin%), Bcolr%
END IF
LOOP

