DEFINT A-Z

DIM FastShow(0 TO 100)
p = VARPTR(FastShow(0)): DEF SEG = VARSEG(FastShow(0)): FOR I = 0 TO 40: READ J: POKE (p + I), J: NEXT I

'Show page: !!! parameters must be 2
DATA &h1E,&h06,&h55,&h89,&hE5,&h8B,&h5E,&h0A,&h8B,&h37,&h8B,&h5E,&hC,&h8E,&h1F,&hB8
DATA &h00,&hB8,&h8E,&hC0,&hBF,&h00,&h00,&hB9,&h80,&h07,&hFC,&hA4,&h47,&hE2,&hFC,&h5D
DATA &h07,&h1F,&hCA,&h04,&h00

'Show single word: !!! parameters must be 3
'DATA &h06,&h55,&h89,&hE5,&hB8,&h00,&hB8,&h8E,&hC0,&hBF,&h01,&h00,&h8b,&h76,&h8,&h8B
'DATA &h04,&h26,&h89,&h05,&h5D,&h07,&hCA,&h06,&h00

'Show entire string: !!! parameters must be 3
'DATA &h06,&h55,&h89,&hE5,&hB8,&h00,&hB8,&h8E,&hC0,&hBF,&h00,&h00,&hBE,&h00,&h00,&hB9
'DATA &h80,&h00,&h8A,&h02,&h26,&h88,&h05,&h83,&hC7,&h02,&h46,&hE2,&hF5,&h5D,&h07,&hCA
'DATA &h06,&h00

SCREEN 0: COLOR 15: CLS

b = 0
c = 0

RANDOMIZE TIMER
FOR a = 0 TO 500
 DEF SEG = VARSEG(FastShow(0))
 CALL ABSOLUTE(b, c, VARPTR(FastShow(0)))
 'CALL ABSOLUTE(b, b, c, VARPTR(FastShow(0)))
 'CALL ABSOLUTE(a, b, a, VARPTR(FastShow(0)))
 'CALL ABSOLUTE(b, b, c, VARPTR(FastShow(0)))
 b = b + 1
NEXT a

DATA 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

