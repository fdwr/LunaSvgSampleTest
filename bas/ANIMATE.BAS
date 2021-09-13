DEFINT A-Z
DECLARE SUB WaitNextFrame ()

SCREEN 7
TYPE ItemTarget
 VrtPos AS INTEGER
 LftHrzPos AS INTEGER
 RitHrzPos AS INTEGER
 Speed AS INTEGER
 Active  AS INTEGER
END TYPE
TYPE ItemArrow
 VrtPos AS INTEGER
 HrzPos AS INTEGER
 Speed AS INTEGER
 Active  AS INTEGER
END TYPE
REDIM SHARED BmpArrow(0 TO 123), BmpArrowIn(0 TO 83), BmpTarget(0 TO 515), BmpTargetDown(0 TO 103), BmpFloorTile(0 TO 515)
'DATA 8,30,0,0,0,4,4,4,4,0,0,0,0,0,4,4,4,4,4,4,0,0,0,4,4,4,4,4,4,4,4,0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0,4,4,4,4,4,4,4,4,0,0,0,4,4,4,4,4,4,0,0,0,0,0,4,4,4,4,0,0,0,

DO
 'Check stuff and react
 'Animate items
  WaitNextFrame
  'Draw floor background on dirty tiles
   'Determine which tiles need to be redrawn
  'Draw all items, in order
   'Draw shield then each arrow
 'Check for keys
 SELECT CASE INKEY$
 CASE " "
 CASE CHR$(27): EXIT DO
 END SELECT
LOOP

SUB WaitNextFrame
WAIT &H3DA, 8, 8: WAIT &H3DA, 8
END SUB

