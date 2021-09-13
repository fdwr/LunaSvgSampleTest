DEFINT A-Z
DECLARE SUB prompt (row, col, leng, curp, txt$, key$)
SCREEN 7
VIEW PRINT

Refresh = 1
DO
 kbrd = INP(96)
 SELECT CASE kbrd
 CASE 1: EXIT DO
 CASE 77: IF CurX < 180 THEN CurX = CurX + 1: Refresh = 1
 CASE 75: IF CurX > -180 THEN CurX = CurX - 1: Refresh = 1
 CASE 72: IF CurY < 180 THEN CurY = CurY + 1: Refresh = 1
 CASE 80: IF CurY > -180 THEN CurY = CurY - 1: Refresh = 1
 END SELECT
 k$ = INKEY$
 SELECT CASE UCASE$(k$)
 CASE "W": IF CurY < 180 THEN CurY = CurY + 1: Refresh = 1
 CASE "D": IF CurX < 180 THEN CurX = CurX + 1: Refresh = 1
 CASE "S": IF CurY > -180 THEN CurY = CurY - 1: Refresh = 1
 CASE "A": IF CurX > -180 THEN CurX = CurX - 1: Refresh = 1
 END SELECT
 IF Refresh THEN GOSUB UpdateLine: Refresh = 0
LOOP

DEF SEG = 0: POKE 1047, 0: DEF SEG
END

UpdateLine:
LINE (160, 180)-(OldX + 160, 180 - OldY), 0
CIRCLE (OldX + 160, 180 - OldY), 10, 0
CIRCLE (160, 180), 10, 3
LINE (160, 180)-(160 + CurX, 180 - CurY), 15
CIRCLE (160 + CurX, 180 - CurY), 10, 3
OldX = CurX: OldY = CurY
LOCATE 25, 1: PRINT CurY; TAB(10); CurX; TAB(20); SQR(CSNG(CurX * CurX) + CSNG(CurY * CurY)); TAB(30); CurX * CurY; TAB(40);
RETURN

SUB prompt (row, col, leng, curp, txt$, key$)

SELECT CASE key$
CASE CHR$(0) + "K": IF curp > 0 THEN curp = curp - 1
CASE CHR$(0) + "M": IF curp < LEN(txt$) THEN curp = curp + 1
CASE CHR$(0) + "G": curp = 0
CASE CHR$(0) + "O": curp = LEN(txt$)
CASE "0" TO "9": IF LEN(txt$) + LEN(key$) <= leng THEN GOSUB promptInsert
CASE ".": IF INSTR(txt$, ".") = 0 THEN GOSUB promptInsert
CASE "": IF LEN(txt$) > 0 THEN GOSUB promptDelete
END SELECT

bar$ = SPACE$(leng + 1)
MID$(bar$, 1) = txt$
LOCATE row, col: PRINT bar$; : LOCATE row, col + curp: PRINT "Ý";
EXIT SUB
promptInsert:
txt$ = LEFT$(txt$, curp) + key$ + RIGHT$(txt$, LEN(txt$) - curp)
curp = curp + LEN(key$)
RETURN
promptDelete:
IF curp > 0 THEN txt$ = LEFT$(txt$, curp - 1) + RIGHT$(txt$, LEN(txt$) - curp): curp = curp - 1
RETURN
END SUB

