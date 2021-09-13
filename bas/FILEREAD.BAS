DECLARE SUB PRT (Vset%, Hset%, Text$)
ON ERROR GOTO ert
PRINT : PRINT "ÄÄÄ FileReader 1.0 ÄÄÄ";
pr:
IF POS(0) <> 1 THEN PRINT
PRINT : LINE INPUT "Filename:", fl$
IF fl$ = "" THEN SYSTEM
IF INSTR(fl$, "") THEN SHELL "DIR " + RIGHT$(fl$, LEN(fl$) - 1): GOTO pr
ChangDir: try = 0: CHDIR fl$: PRINT "Directory Changed To:"; fl$; "": GOTO pr
OpenFile: CLOSE #1: OPEN fl$ FOR INPUT AS #1: CLOSE #1: OPEN fl$ FOR BINARY AS #1
FOR lk& = 1 TO INT(LOF(1) / 16384)
 R$ = "": R$ = STRING$(16384, 32): GET #1, (lk& - 1) * 16384 + 1, R$
 FOR s% = 1 TO 16384
  PRT CSRLIN, POS(0), MID$(R$, s%, 1)
  IF POS(0) = 80 THEN PRINT  ELSE LOCATE , POS(0) + 1
  IF INP(96) = 1 THEN COLOR 15: PRINT "MORE": COLOR 7: GOTO pr
 NEXT s%
NEXT lk&
R$ = "": R$ = STRING$(LOF(1) MOD 16384, 32): GET #1, INT(LOF(1) / 16384) * 16384 + 1, R$
FOR s% = 1 TO LEN(R$)
 PRT CSRLIN, POS(0), MID$(R$, s%, 1)
 IF POS(0) = 80 THEN PRINT  ELSE LOCATE , POS(0) + 1
 IF INP(96) = 1 THEN COLOR 15: PRINT "MORE": COLOR 7: GOTO pr
NEXT s%
R$ = "": COLOR 15: PRINT "EOF": COLOR 7
GOTO pr
ert:
IF try = 0 THEN try = 1: RESUME OpenFile
PRINT
SELECT CASE ERR
CASE 53: PRINT "File Not Found"
CASE 64: PRINT "Bad File Name"
CASE 69: PRINT "Device Unavailable"
CASE 75: PRINT "Path Not Found"
CASE ELSE:
END SELECT
PRINT "Type 'Ctrl+D' with any parameters and then press 'ENTER' for a list of files"
RESUME pr

SUB PRT (Vset%, Hset%, Text$)
DEF SEG = &HB800: POKE (Vset% - 1) * (160) + (Hset% - 1) * 2, ASC(Text$)
END SUB

