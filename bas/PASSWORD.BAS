DEFINT A-Z
DECLARE SUB TrailTest (Trail$, GridR%, GridC%)
DECLARE FUNCTION TrailSpot% (Trail$, TestR%, TestC%)
DECLARE SUB VerifyPassword (Trail$, PassWordOK%, Response$)
DECLARE SUB GetCoordinates (GridH%, GridL%, GridR%, GridC%)
DECLARE FUNCTION STRNG$ (Leng%, Qote$)
DIM SHARED GridH, GridL, OriginalGridRowPos, OriginalGridColumn

RANDOMIZE TIMER: COLOR 15, 3: CLS : LOCATE , , 0

Start:
GetCoordinates GridH, GridL, OriginalGridRowPos, OriginalGridColumn
GridR = OriginalGridRowPos
GridC = OriginalGridColumn
PgrdR = GridR: PgrdC = GridC: Trail$ = ""
LftOf = 9: TopOf = 5

COLOR 0, 7: DotString$ = STRNG$(GridL * 2 + 1, " ")
FOR past% = 0 TO 15
 LOCATE past% + TopOf, LftOf - 1
 IF past% > GridH THEN
  COLOR , 3: PRINT SPACE$(65);
 ELSE
  COLOR 7, 3: PRINT "Þ";
  COLOR 0, 7: PRINT DotString$;
  COLOR 7, 3: PRINT "Ý";
  PRINT SPACE$(62 - (GridL * 2));
 END IF
NEXT past%

WHILE INKEY$ > "": WEND: Done = 0
DO UNTIL Done
 AddSign = 0
 Kbrd$ = INKEY$
 IF Kbrd$ > "" THEN
  SELECT CASE Kbrd$
  CASE CHR$(0) + "H": Sign$ = "": AddSign = -1
  CASE CHR$(0) + "P": Sign$ = "": AddSign = -1
  CASE CHR$(0) + "M": Sign$ = "": AddSign = -1
  CASE CHR$(0) + "K": Sign$ = "": AddSign = -1
  CASE CHR$(13): Done = 1
  CASE CHR$(27): Done = -1
  CASE CHR$(8): IF Trail$ > "" THEN Trail$ = LEFT$(Trail$, LEN(Trail$) - 1)
  END SELECT
 END IF

 IF AddSign THEN IF LEN(Trail$) >= 128 THEN SOUND 860, .03 ELSE Trail$ = Trail$ + Sign$
 TrailTest Trail$, GridR, GridC
 LOCATE 1, 1: COLOR 15, 3: PRINT " Height"; GridH + 1, "Length"; GridL + 1, "Row"; OriginalGridRowPos + 1; "to"; GridR + 1, "Col"; OriginalGridColumn + 1; "to"; GridC + 1, "Trail"; LEN(Trail$);
 LOCATE 25, 1: PRINT LEFT$(Trail$ + SPACE$(80), 80);

 IF PgrdR <> GridR OR PgrdC <> GridC THEN
  LOCATE PgrdR + TopOf, (PgrdC * 2) + LftOf
  IF AddSign THEN
   COLOR 11, 7: PRINT "þ";
  ELSEIF TrailSpot(Trail$, PgrdR, PgrdC) THEN
   COLOR 11, 7: PRINT "þ";
  ELSE
   COLOR 0, 7: PRINT "";
  END IF
  PgrdR = GridR: PgrdC = GridC
 END IF
 LOCATE GridR + TopOf, (GridC * 2) + LftOf: COLOR 15, 7: PRINT "";
LOOP

IF Done = -1 THEN
 SYSTEM
ELSEIF Done = 1 THEN
 VerifyPassword Trail$, PassWordOK, Response$
 LOCATE 3, 1: COLOR 15, 3
 IF PassWordOK THEN
  SOUND 1024, 1: SOUND 0, 1: SOUND 1024, 1
  PRINT " Password acceptedÄÄÄÄÄ>"; Response$
  WHILE INKEY$ > "": WEND: WHILE INKEY$ = "": WEND: SYSTEM
 ELSE
  SOUND 256, 1
  PRINT " Password not acceptedÄ>"; Response$
  GOTO Start
 END IF
END IF

SUB GetCoordinates (GridH, GridL, GridR, GridC)
GridH = INT(RND * 13) + 3
GridL = INT(RND * 19) + 13
GridR = INT(RND * GridH)
GridC = INT(RND * GridL)
IF GridR = 3 THEN GridR = 2
END SUB

DEFSNG A-Z
FUNCTION STRNG$ (Leng%, Qote$)
DO UNTIL LEN(Rslt$) + LEN(Qote$) > Leng%
 Rslt$ = Rslt$ + Qote$
LOOP
STRNG$ = Rslt$ + LEFT$(Qote$, Leng% - LEN(Rslt$))
END FUNCTION

DEFINT A-Z
FUNCTION TrailSpot (Trail$, TestR, TestC)
GridR = OriginalGridRowPos
GridC = OriginalGridColumn
FOR TestTrail = 1 TO LEN(Trail$)
 SELECT CASE MID$(Trail$, TestTrail, 1)
 CASE "": IF GridR < GridH THEN GridR = GridR + 1
 CASE "": IF GridR > 0 THEN GridR = GridR - 1
 CASE "": IF GridC < GridL THEN GridC = GridC + 1
 CASE "": IF GridC > 0 THEN GridC = GridC - 1
 END SELECT
IF GridR = TestR AND GridC = TestC THEN TrailSpot = TestTrail: EXIT FUNCTION
NEXT TestTrail
TrailSpot = 0
END FUNCTION

SUB TrailTest (Trail$, GridR, GridC)
GridR = OriginalGridRowPos
GridC = OriginalGridColumn
FOR TestTrail = 1 TO LEN(Trail$)
 SELECT CASE MID$(Trail$, TestTrail, 1)
 CASE "": IF GridR < GridH THEN GridR = GridR + 1
 CASE "": IF GridR > 0 THEN GridR = GridR - 1
 CASE "": IF GridC < GridL THEN GridC = GridC + 1
 CASE "": IF GridC > 0 THEN GridC = GridC - 1
 END SELECT
NEXT TestTrail
END SUB

SUB VerifyPassword (Trail$, PassWordOK, Response$)
 TrueGridRowPos = 3
 TrueGridColumn = 6
 MockGridRowPos = OriginalGridRowPos
 MockGridColumn = OriginalGridColumn

 TrailTest Trail$, MockGridRowPos, MockGridColumn
 IF MockGridColumn = TrueGridColumn AND MockGridRowPos = TrueGridRowPos THEN PassWordOK = -1: Response$ = ":) WELCOME" ELSE PassWordOK = 0: Response$ = ";( BYE-BYE"
END SUB

