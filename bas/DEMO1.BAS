DEFINT A-Z
DECLARE SUB DrawBox (Urow, Drow, Lcol, Rcol)
DECLARE SUB ParagraphText (Urow, Drow, Lcol, Rcol, Text$)

CLS

DrawBox 3, 12, 23, 56
ParagraphText 4, 11, 24, 55, "Testing of the subs\ Do they work?!\\The first sub is a boxdrawer\(Which drew my border)\\The second is a text paragrapher\(Which drew the text you read)"

SUB DrawBox (Urow, Drow, Lcol, Rcol)

Wdth = Rcol - Lcol - 1: IF Wdth < 0 THEN Wdth = 0

LOCATE Urow, Lcol: PRINT "Ú"; STRING$(Wdth, "Ä"); "¿";

FOR Row = Urow + 1 TO Drow - 1
 LOCATE Row, Lcol: PRINT "³"; STRING$(Wdth, " "); "³";
NEXT

LOCATE Drow, Lcol: PRINT "À"; STRING$(Wdth, "Ä"); "Ù";
END SUB

SUB ParagraphText (Urow, Drow, Lcol, Rcol, Text$)

Wdth = Rcol - Lcol + 1: IF Wdth < 0 THEN EXIT SUB

CurPos = 1
IF Text$ = "" THEN VoidLine = 1

FOR Row = Urow TO Drow
 IF VoidLine THEN
  LOCATE Row, Lcol: PRINT SPACE$(Wdth);
 ELSE
  NextPos = INSTR(CurPos, Text$, "\")
  IF NextPos = 0 THEN
   ShowWdth = LEN(Text$) - CurPos + 1
   VoidLine = 1 'Last line has been reached
  ELSE
   ShowWdth = NextPos - CurPos
   NextPos = NextPos + 1
  END IF
  IF ShowWdth > Wdth THEN ShowWdth = Wdth
  LOCATE Row, Lcol: PRINT MID$(Text$, CurPos, ShowWdth); SPACE$(Wdth - ShowWdth);
  CurPos = NextPos
 END IF
NEXT

END SUB

