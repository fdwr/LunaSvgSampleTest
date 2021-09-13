'Simple starfield renderer -- Dwayne R.D.

'  This program renders a 3D Milky Way on your screen using red and blue
'color separation. You may need some 3D glasses to get the 3D effect;
'however, other simple color filters can also work. For example, I have used
'Lego shields and windows instead and have still seen it in full depth. The
'field should appear to collapse into the center where a middle ring seems to
'project itself toward you. If it does not look this way, but opposite, the
'problem is probably that the filters are backwards - just swap them around.
'  Press Enter to create a new star scene, Space to overlay more stars onto
'the existing field, or Esc to exit the program.

DEFINT A-Z
SCREEN 7
GOSUB StarField
DO
 kbrd$ = INKEY$
 IF kbrd$ = CHR$(13) THEN
  CLS : GOSUB StarField
 ELSEIF kbrd$ = " " THEN GOSUB StarField
 ELSEIF kbrd$ = CHR$(27) THEN EXIT DO
 END IF
LOOP
END

StarField:
stars = 5
FOR row = 0 TO 94
 depth = row \ 10
 GOSUB StarLine
NEXT row
FOR row = 105 TO 199
 depth = (row - 200) \ -10
 GOSUB StarLine
NEXT row
depth = -1
stars = 10
FOR row = 95 TO 104
 GOSUB StarLine
NEXT row
RETURN

StarLine:
FOR star = 1 TO stars
 col = INT(RND * 320)
 redCheck = POINT(col - depth, row)
 bluCheck = POINT(col + depth, row)
 IF depth THEN
  PSET (col - depth, row), redCheck OR 12
  PSET (col + depth, row), bluCheck OR 9
 ELSE PSET (col, row), redCheck OR bluCheck OR 13
 END IF
NEXT star
RETURN

