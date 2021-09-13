DEFINT A-Z
DECLARE SUB BIOSLETR (Letr, Vrow, Hcol, Fore, Back)
DIM DrawCharCode(0 TO 80) '0 to 76
DEF SEG = VARSEG(DrawCharCode(0))
p = VARPTR(DrawCharCode(0))
FOR t = 0 TO 76
 READ byte
 POKE p + t, byte
NEXT t
'DATA &h1E,&h06,&h55,&h89,&hE5,&hB8,&h00,&hF0,&h8E,&hD8,&hB8,&h00,&hA0,&h8E,&hC0,&h8B
DATA &h1E,&h06,&h55,&h89,&hE5,&hB8,&h00,&hF0,&h8E,&hD8,&hB8,&h00,&hA0,&h8E,&hC0,&h8B
DATA &h5E,&h06,&h8B,&h37,&hB1,&h06,&hD3,&hE6,&h81,&hC6,&h6E,&hFA,&h8B,&h5E,&h08,&h8B
DATA &h07,&h85,&hC0,&h79,&h09,&h29,&hC6,&h05,&h08,&h00,&h31,&hFF,&hEB,&h12,&hBF,&h40
DATA &h01,&hF7,&hE7,&hF7,&hD8,&h05,&hC8,&h00,&h3D,&h08,&h00,&h78,&h03,&hB8,&h08,&h00
DATA &h3D,&h01,&h00,&h78,&h27,&h8B,&h5E,&h10,&h8B,&h1F,&h85,&hDB,&h79,&h09,&h89,&hD9
DATA &hF7,&hD9,&h83,&hC3,&h08,&hEB,&h12,&h01,&hDF,&h30,&hC9,&hF7,&hDB,&h81,&hC3,&h40
DATA &h01,&h83,&hFB,&h08,&h78,&h03,&hBB,&h08,&h00,&h83,&hFB,&h01,&h78,&h27,&hBA,&h40
DATA &h01,&h29,&hDA,&h88,&hDF,&h88,&hC3,&h8A,&h46,&h12,&hFC,&hAC,&hD2,&hE4,&hD0,&hE4
DATA &h73,&h07,&hAA,&hFE,&hCF,&h75,&hF7,&hEB,&h05,&h47,&hFE,&hCF,&h75,&hF0,&h46,&h01
DATA &hD7,&hFE,&hCB,&h75,&hE6,&h5D,&h07,&h1F,&hCA,&h08,&h00

SCREEN 13: CLS

DEF SEG = VARSEG(DrawCharCode(0))
'CALL ABSOLUTE(2, -9, -9, 11, VARPTR(DrawCharCode(0)))

FOR t = 1 TO 24
 BIOSLETR ASC(MID$("Type in something below:", t, 1)), Vrow, Hcol, 3, 0
 Hcol = Hcol + 1
NEXT t
PLAY "MBL20CCCEp10GGG>C"
'WIDTH 80, 25
'END

DO UNTIL Done
Kbrd$ = INKEY$
DEF SEG = 0: CtrlOff = (PEEK(1047) XOR 4) AND 4
Hcol = LEN(List$) MOD 40
Vrow = LEN(List$) \ 40 + 1
IF CtrlOff = 0 AND Kbrd$ > "" THEN IF INSTR(CHR$(13) + "", Kbrd$) THEN List$ = List$ + Kbrd$: BIOSLETR ASC(Kbrd$), Vrow, Hcol, 1, 2: Kbrd$ = ""
SELECT CASE Kbrd$
CASE CHR$(27), CHR$(13): Done = -1
CASE CHR$(8): IF LEN(List$) > 0 THEN List$ = LEFT$(List$, LEN(List$) - 1): BIOSLETR 32, LEN(List$) \ 40 + 1, (Hcol + 39) MOD 40, 0, 0
CASE ""
CASE ELSE: List$ = List$ + Kbrd$: BIOSLETR ASC(Kbrd$), Vrow, Hcol, 1, 2
END SELECT
LOOP

SUB BIOSLETR (Letr, Vrow, Hcol, Fore, Back)
'Small  8x8 (0-127): F000h+FA6E
'Small  8x8 (0-255): C000h+41EC
'Large 14x8 (0-255): C000h+32BF
'Large 16x8 (0-255): C000h+49EC

h = 8: w = 8: al = (Vrow * h): ar = Hcol * w + w
DEF SEG = &HC000: o = &H41EC + (Letr * h)
FOR r = 0 TO h - 1
 l = PEEK(o + r)
 FOR c = 0 TO 7
  IF l AND (2 ^ c) THEN B = Fore ELSE B = Back
  IF B >= 0 THEN PSET (ar - c, al + r), B
NEXT c, r
END SUB

