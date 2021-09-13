DIM FastShow(0 TO 19)
p = VARPTR(FastShow(0)): DEF SEG = VARSEG(FastShow(0)): FOR I = 0 TO 36: READ J: POKE (p + I), J: NEXT I
DATA &h1e,&h06,&h55,&h89,&he5,&h8b,&h76,&h06,&h8e,&h1c,&h8b,&h76,&h08,&h8b
DATA &h34,&hb8,&h00,&hb8,&h8e,&hc0,&hbf,&h00,&h00,&hb9,&h80,&h07,&hfc,&ha4
DATA &h47,&he2,&hfc,&h5d,&h07,&h1f,&hca,&h04,&h00

SCREEN 0: COLOR 3, 0: CLS : LOCATE , , 0

DEF SEG = VARSEG(FastShow(0))
CALL ABSOLUTE(a, b, VARPTR(FastShow(0)))

