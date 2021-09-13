DEFINT A-Z
SCREEN 12
RANDOMIZE TIMER

vStrech = 50: hStrech = 50: PixRow = 0: PixCol = 0: GOSUB GetStrDif
LOCATE 1, 1: PRINT "Use the arrow keys to move the `brush' around on the screen, Space pauses"
PRINT "The + and - change the 3d depth, Home and End adjust the vertical strech,"
PRINT "Page up and Page down adjust the horizontal strech, Press Escape to quit"
'Vertical Strech  Del/PagDn-Horizontal Strech"
DO
user$ = INKEY$
SELECT CASE user$
CASE ""
CASE "+": depth = depth + 1
CASE "-": depth = depth - 1
CASE CHR$(0) + "G": vStrech = vStrech + 1: GOSUB GetStrDif
CASE CHR$(0) + "O": vStrech = vStrech - 1: GOSUB GetStrDif
CASE CHR$(0) + "I": hStrech = hStrech + 1: GOSUB GetStrDif
CASE CHR$(0) + "Q": hStrech = hStrech - 1: GOSUB GetStrDif
CASE CHR$(0) + "P": PixRow = PixRow + 1
CASE CHR$(0) + "H": PixRow = PixRow - 1
CASE CHR$(0) + "M": PixCol = PixCol + 1
CASE CHR$(0) + "K": PixCol = PixCol - 1
CASE " ": IF paused THEN paused = 0 ELSE paused = -1
CASE "": EXIT DO
END SELECT

LOCATE 30, 1: PRINT "Depth"; depth, "Line"; PixRow, "Column"; PixCol, "V-Strech"; vStrech, "H-Strech"; hStrech; "   ";
IF NOT paused THEN GOSUB RandmPoint
LOOP
END

RandmPoint:
row = PixRow + INT(RND * vStrech) - vStrDif
col = PixCol + INT(RND * hStrech) - hStrDif

redCheck = POINT(col - depth + 320, row + 240)
bluCheck = POINT(col + depth + 320, row + 240)
IF depth THEN
 PSET (col - depth + 320, row + 240), redCheck OR 12
 PSET (col + depth + 320, row + 240), bluCheck OR 9
ELSE
 PSET (col + 320, row + 240), redCheck OR bluCheck OR 13
END IF
RETURN

GetStrDif:
vStrDif = vStrech \ 2
hStrDif = hStrech \ 2
RETURN

