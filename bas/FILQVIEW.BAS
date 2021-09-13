SCREEN 0: WIDTH 80, 50: CLS : LOCATE , , 0
FILES: PRINT
LINE INPUT "Filename:", f$
IF f$ = "" THEN END
ON ERROR GOTO FilErrHan
OPEN f$ FOR INPUT AS #1: CLOSE #1
OPEN f$ FOR BINARY AS #1
DEF SEG = &HB800
FOR readin = 1 TO LOF(1) STEP 80
 a$ = INPUT$(80, 1)
 verLine = 80 * (CSRLIN - 1)
 FOR show = 1 TO LEN(a$)
  POKE (verLine + show - 1) * 2, ASC(MID$(a$, show, 1))
 NEXT show
 IF readin + 80 < LOF(1) THEN PRINT
NEXT readin
endIt:
CLOSE #1
END

FilErrHan: PRINT "Could not open file": RESUME endIt

