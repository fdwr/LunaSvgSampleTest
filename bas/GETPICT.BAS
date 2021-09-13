SCREEN 13

DIM PicArray(0 TO 16380) AS INTEGER
SizeChange = 1
NewWdth = 19
NewHite = 19

DO
  IF SizeChange THEN
    LINE (0, 0)-(Wdth, Hite), 0, B
    LINE (0, 0)-(NewWdth, NewHite), 12, B
    Wdth = NewWdth: Hite = NewHite
    GET (0, 0)-(Wdth, Hite), PicArray
    LOCATE 1, 1: PRINT Hite + 1; Wdth + 1, PicArray(0); PicArray(1);
    SizeChange = 0
  END IF

  k$ = INKEY$
  SELECT CASE k$
  CASE CHR$(0) + "H": IF Hite > 0 THEN NewHite = Hite - 1: SizeChange = 1
  CASE CHR$(0) + "P": IF Hite < 199 THEN NewHite = Hite + 1: SizeChange = 1
  CASE CHR$(0) + "K": IF Wdth > 0 THEN NewWdth = Wdth - 1: SizeChange = 1
  CASE CHR$(0) + "M": IF Wdth < 319 THEN NewWdth = Wdth + 1: SizeChange = 1
  CASE CHR$(0) + "I": IF Hite > 10 THEN NewHite = Hite - 10: SizeChange = 1
  CASE CHR$(0) + "Q": IF Hite < 189 THEN NewHite = Hite + 10: SizeChange = 1
  CASE CHR$(0) + "G": IF Wdth > 10 THEN NewWdth = Wdth - 10: SizeChange = 1
  CASE CHR$(0) + "O": IF Wdth < 309 THEN NewWdth = Wdth + 10: SizeChange = 1

  CASE CHR$(27): EXIT DO
  END SELECT
LOOP

WIDTH 80, 25
CLS

