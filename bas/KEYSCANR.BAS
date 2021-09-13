DEFINT A-Z
DIM KillBiosCode, ResumeBiosCode
KillBiosCode = -13318: ResumeBiosCode = -13317

SCREEN 13

'SetColors
FOR PalColor = 0 TO 127
 LitColor = PalColor \ 2 + 32
 GrnColor = (PalColor MOD 4) * 21
 OUT &H3C8, PalColor: OUT &H3C9, LitColor: OUT &H3C9, GrnColor: OUT &H3C9, 0
 OUT &H3C8, PalColor + 128: OUT &H3C9, 0: OUT &H3C9, GrnColor: OUT &H3C9, LitColor
NEXT PalColor

DEF SEG = VARSEG(KillBiosCode): CALL absolute(VARPTR(KillBiosCode))

PriorLine = -1: CurSeg = 0: DEF SEG = &HA000: ScrnPoint = 0
DO
 Inpt = INP(96)
 POKE ScrnPoint, Inpt
 IF ScrnPoint \ 320 <> PriorLine THEN
  PriorLine = ScrnPoint \ 320
  LINE (1, NextLine)-(320, NextLine), 63, BF
  NextLine = (NextLine + 1) MOD 190
 END IF
 IF ScrnPoint > 30080 THEN
  ScrnPoint = 0
  IF CurSeg THEN DEF SEG = &HA000: CurSeg = 0 ELSE DEF SEG = &HA758: CurSeg = 1
 ELSE ScrnPoint = ScrnPoint + 1
 END IF
 IF Inpt = 1 THEN EXIT DO
LOOP

DEF SEG = VARSEG(ResumeBiosCode): CALL absolute(VARPTR(ResumeBiosCode))

