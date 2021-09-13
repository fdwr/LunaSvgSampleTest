'Dwayne's velocity pointer
DEFINT A-Z
DECLARE SUB DrawVelPoints (VelPoints() AS ANY, DrawMode, Center)
DECLARE SUB MoveVelPoints (VelPoints() AS ANY)

TYPE VelPoint
Yrow AS INTEGER
Xcol AS INTEGER
Yvel AS INTEGER
Xvel AS INTEGER
VpId AS INTEGER
END TYPE

SCREEN 7
CONST ScrnHite = 200, ScrnWdth = 320, ScrnHalfHite = 100, ScrnHalfWdth = 160

'Request to define the number of points to be created, what type each one is,
'where each starts, and the velocity of each
'Also ask what the relativity point is, absolute to coordinates or to a point
REDIM VelPoints(0 TO 3) AS VelPoint
FOR CurVelPoint = 0 TO UBOUND(VelPoints)
 READ VelPoints(CurVelPoint).Yrow, VelPoints(CurVelPoint).Xcol, VelPoints(CurVelPoint).Yvel, VelPoints(CurVelPoint).Xvel
NEXT CurVelPoint
DATA 0,0,0,0,-1000,-1000,5,0
DATA 0,0,-5,2,0,0,5,5
CenterPoint = 0

DrawVelPoints VelPoints(), 1, CenterPoint
DO
 WAIT &H3DA, 8
 DrawVelPoints VelPoints(), 0, CenterPoint

 MoveVelPoints VelPoints()
 DrawVelPoints VelPoints(), 1, CenterPoint

 IF INKEY$ > "" THEN EXIT DO
LOOP

END

SUB DrawVelPoints (VelPoints() AS VelPoint, DrawMode, Center)

IF Center >= 0 THEN
 CenterRow = VelPoints(Center).Yrow \ 32
 CenterCol = VelPoints(Center).Xcol \ 32
END IF
CenterRow = ScrnHalfHite - CenterRow
CenterCol = ScrnHalfWdth - CenterCol

IF DrawMode THEN COLOR 15 ELSE COLOR 4

FOR CurVelPoint = 0 TO UBOUND(VelPoints)
 PSET (VelPoints(CurVelPoint).Xcol \ 32 + CenterCol, VelPoints(CurVelPoint).Yrow \ 32 + CenterRow)
NEXT CurVelPoint

END SUB

SUB MoveVelPoints (VelPoints() AS VelPoint)

FOR CurVelPoint = 0 TO UBOUND(VelPoints)
 VelPoints(CurVelPoint).Yrow = VelPoints(CurVelPoint).Yrow + VelPoints(CurVelPoint).Yvel
 VelPoints(CurVelPoint).Xcol = VelPoints(CurVelPoint).Xcol + VelPoints(CurVelPoint).Xvel
NEXT CurVelPoint

END SUB

