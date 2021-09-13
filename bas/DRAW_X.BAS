'Get letter under position and save it
'Put the 'x' at the position
'Restore the saved letter to the position

CurX = 1: CurY = 1: PosChng = 1

DO UNTIL Done
 IF PosChng THEN        'Respond to change in position
  GOSUB SaveLetter
  GOSUB PutXatPosition
  PosChng = 0
 END IF
 SELECT CASE INKEY$     'Respond to key input properly
 CASE CHR$(0) + "K": IF CurX > 1 THEN CurX = CurX - 1: PosChng = 1
 CASE CHR$(0) + "M": IF CurX < 80 THEN CurX = CurX + 1: PosChng = 1
 CASE CHR$(0) + "H": IF CurY > 1 THEN CurY = CurY - 1: PosChng = 1
 CASE CHR$(0) + "P": IF CurY < 25 THEN CurY = CurY + 1: PosChng = 1
 CASE CHR$(27): PosChng = 1: Done = 1
 END SELECT
 IF PosChng THEN GOSUB RestoreLetter
LOOP
END

SaveLetter:
 PreX = CurX: PreY = CurY
 Lcolor = SCREEN(CurY, CurX, 1)
 Letter = SCREEN(CurY, CurX, 0)
RETURN

PutXatPosition:
 LOCATE CurY, CurX
 COLOR 15, (SCREEN(CurY, CurX, 1) AND 240) \ 16
 PRINT "X";
RETURN

RestoreLetter:
 LOCATE PreY, PreX
 COLOR Lcolor AND 15, (Lcolor AND 240) \ 16
 PRINT CHR$(Letter);
RETURN

