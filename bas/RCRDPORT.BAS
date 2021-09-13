DEFINT A-Z
DECLARE FUNCTION NUM$ (NUM%, lim%)
DECLARE FUNCTION PROMPT$ (row%, col%, lim%, txt$)
DECLARE SUB HELP (txt$, rsp, lrp, mode)

SCREEN 0: WIDTH 80, 25
COLOR , 7: CLS

Start: GOSUB GetPortNumber: IF ExitKey = 1 GOTO Quit ELSE GOSUB RecordPortInput
GOSUB ScrollPortRecord: IF ExitKey = 1 GOTO Quit ELSE IF ExitKey = 2 GOTO Start

Quit: SYSTEM

GetPortNumber:
HELP " Requesting port number to record, press Enter to cancel", 0, 0, 3
COLOR 15, 0: prt$ = PROMPT(2, 3, 12, "Port:")
IF prt$ = "" THEN ExitKey = 1 ELSE prt& = VAL(prt$)
RETURN

RecordPortInput:
HELP " Recording port input, press Esc to cancel", 0, 0, 3
rcd$ = "": rcd$ = SPACE$(&HFFF)
lrp = 0
DO UNTIL lrp >= &HFFF OR INKEY$ = CHR$(27)
 lrp = lrp + 1
 MID$(rcd$, lrp, 1) = CHR$(INP(prt&))
LOOP
HELP "", 1, lrp, 2
RETURN

ScrollPortRecord:
IF rsp < 1 THEN rsp = 1 ELSE IF rsp > lcp THEN IF lcp < 1 THEN rsp = 1 ELSE rsp = lcp
rch = 1
ExitKey = 0
HELP " Use the cursor keys, press Esc to cancel", 0, 0, 1
DO UNTIL ExitKey
IF rch THEN GOSUB ShowPortRecord: HELP " Use the cursor keys, press Esc to cancel", rsp, lrp, 2: rch = 0
kbd$ = INKEY$
SELECT CASE kbd$
CASE CHR$(0) + "H": IF rsp > 1 THEN rsp = rsp - 1: rch = 1
CASE CHR$(0) + "P": IF rsp < lrp THEN rsp = rsp + 1: rch = 1
CASE CHR$(0) + "Q": rch = 1: IF rsp + 22 > lrp THEN rsp = lrp ELSE rsp = rsp + 22
CASE CHR$(0) + "I": rch = 1: IF rsp - 22 < 1 THEN rsp = 1 ELSE rsp = rsp - 22
CASE CHR$(27): ExitKey = 1
CASE CHR$(13): ExitKey = 2
END SELECT
LOOP
RETURN

ShowPortRecord:
COLOR 0, 3

rbl = 400 \ lrp: ofs = rsp \ CINT(lrp / 22): bar$ = STRING$(22, 176)
IF rbl < 1 THEN rbl = 1 ELSE IF rbl > 22 THEN rbl = 22
IF ofs >= 22 THEN ofs = 21
MID$(bar$, ofs + 1) = STRING$(rbl, 219)

FOR shw = 0 TO 21
 rrp = rsp + shw
 IF rrp <= lrp THEN prt$ = STR$(ASC(MID$(rcd$, rrp, 1))) ELSE prt$ = ""
 prt$ = LEFT$(prt$ + SPACE$(5), 5)
 LOCATE 2 + shw, 17: PRINT prt$;
 LOCATE shw + 2, 22: PRINT MID$(bar$, shw + 1, 1);
NEXT shw
LOCATE 2, 17: PRINT "";

RETURN

SUB HELP (txt$, rsp, lrp, mode)
IF mode AND 1 THEN COLOR 15, 3: LOCATE 25, 1: PRINT LEFT$(txt$ + SPACE$(68), 68);
IF mode AND 2 THEN COLOR 0, 3: LOCATE 25, 68: PRINT "³ "; NUM$(rsp, 4); " "; NUM$(lrp, 4); "  ";
END SUB

FUNCTION NUM$ (NUM, lim)
prt$ = LTRIM$(STR$(NUM))
IF LEN(prt$) < lim THEN NUM$ = prt$ + SPACE$(lim - (LEN(prt$))) ELSE NUM$ = LEFT$(prt$, lim)
END FUNCTION

FUNCTION PROMPT$ (row, col, lim, txt$)
LOCATE row, col: PRINT SPACE$(lim);
LOCATE row, col: PRINT txt$; : LINE INPUT prt$
PROMPT$ = prt$
END FUNCTION

