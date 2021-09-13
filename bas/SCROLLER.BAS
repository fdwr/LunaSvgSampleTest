VIEW PRINT 1 TO 25
FOR mes% = 1 TO 2000
PRINT CHR$(INP(64) AND 248);
NEXT mes%

DIM ScrollUpAsm(1 TO 7)
  P = VARPTR(ScrollUpAsm(1)): DEF SEG = VARSEG(ScrollUpAsm(1))
  FOR I = 0 TO 13: READ J: POKE (P + I), J: NEXT I
DIM ScrollDnAsm(1 TO 7)
  P = VARPTR(ScrollDnAsm(1)): DEF SEG = VARSEG(ScrollDnAsm(1))
  FOR I = 0 TO 13: READ J: POKE (P + I), J: NEXT I
DO
DO: Kbrd$ = INKEY$: LOOP WHILE Kbrd$ = "": IF Kbrd$ = "" THEN END
  DEF SEG = VARSEG(ScrollDnAsm(1)): CALL ABSOLUTE(VARPTR(ScrollDnAsm(1)))
DO: Kbrd$ = INKEY$: LOOP WHILE Kbrd$ = "": IF Kbrd$ = "" THEN END
  DEF SEG = VARSEG(ScrollUpAsm(1)): CALL ABSOLUTE(VARPTR(ScrollUpAsm(1)))
LOOP
END
DATA &HB8,&H01,&H06,&HB9,&H01,&H06,&HBA,&H4E,&H16,&HB7,&H00,&HCD,&H10,&HCB
DATA &HB8,&H01,&H07,&HB9,&H01,&H06,&HBA,&H4E,&H16,&HB7,&H00,&HCD,&H10,&HCB

