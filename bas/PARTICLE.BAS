DEFINT A-Z
DECLARE SUB DrawParticleWindow (ParticleLocs&(), LowLimit%, HighLimit%, DrawType)

CONST StreamWidth = 4, StreamHeight = 50, StreamRange = 60, ParticleSeparation = 30
DIM ParticleLocs(StreamWidth * StreamHeight) AS LONG

SCREEN 13

LowLimit = 90: HighLimit = 150
FOR CurParticle = 0 TO StreamWidth * StreamHeight - 1
  ParticleLocs(CurParticle) = INT(RND * StreamRange) + LowLimit + ParticleInStream * ParticleSeparation
  IF ParticleInStream < StreamWidth - 1 THEN ParticleInStream = ParticleInStream + 1 ELSE ParticleInStream = 0
NEXT CurParticle

LowLimit = 90: HighLimit = 150
DrawParticleWindow ParticleLocs(), LowLimit, HighLimit, 13
LINE (0, 0)-(HighLimit - LowLimit + 4, StreamHeight + 1), 15, B
DO: LOOP UNTIL LEN(INKEY$)

DO
  DrawParticleWindow ParticleLocs(), LowLimit, HighLimit, 0
  LowLimit = LowLimit + 1: HighLimit = HighLimit + 1
  DrawParticleWindow ParticleLocs(), LowLimit, HighLimit, 13
LOOP UNTIL LEN(INKEY$)

SUB DrawParticleWindow (ParticleLocs() AS LONG, LowLimit, HighLimit, DrawColor)

CurParticle = 0
FOR ParticleStream = 0 TO StreamHeight - 1
  TempLowLimit = LowLimit
  LowLimitOffset = 0
  FOR ParticleInStream = 0 TO StreamWidth - 1
    IF ParticleLocs(CurParticle) < HighLimit THEN
      IF ParticleLocs(CurParticle) < LowLimit THEN StreamOffset = LowLimitOffset ELSE StreamOffset = ParticleLocs(CurParticle) - TempLowLimit
      PSET (StreamOffset + 1, ParticleStream + 1), DrawColor
    END IF
    CurParticle = CurParticle + 1
    TempLowLimit = TempLowLimit - 1
    LowLimitOffset = LowLimitOffset + 1
  NEXT ParticleInStream
NEXT ParticleStream

END SUB

