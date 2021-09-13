DEFINT A-Z

CONST MaxParticles = 1500, DefParticleLifeSpan = 60, DefParticleSpeed = 4
CONST DefParticleStreamSpeed = 6, ParticleBounceBorder = 30
CONST ScreenHeight = 200, ScreenWidth = 320
DIM Particles(MaxParticles - 1, 5), ParticleRow, ParticleCol
DIM ParticleStreamRow, ParticleStreamCol

gosub SetScreenMode

FOR Particle = 0 TO MaxParticles - 1
    Particles(Particle, 4) = CLNG(Particle) * DefParticleLifeSpan \ MaxParticles
NEXT Particle
StreamChange = 1
DEF SEG = 0
DO
    PreTime = PEEK(1132)
    DEF SEG = &HA000
    FOR Particle = 0 TO MaxParticles - 1
        ParticleRow = Particles(Particle, 0): ParticleCol = Particles(Particle, 1)
        PreParticleRow = ParticleRow: PreParticleCol = ParticleCol
        ParticleRow = ParticleRow + Particles(Particle, 2)
        ParticleCol = ParticleCol + Particles(Particle, 3)
        ParticleLifeSpan = Particles(Particle, 4)
        IF ParticleLifeSpan > 0 THEN
            IF ParticleRow < 0 OR ParticleRow >= ScreenHeight THEN
                Particles(Particle, 0) = -Particles(Particle, 0)
                Particles(Particle, 2) = -Particles(Particle, 2)
            END IF
            IF ParticleCol < 0 OR ParticleCol >= ScreenWidth THEN
                Particles(Particle, 1) = -Particles(Particle, 1)
                Particles(Particle, 3) = -Particles(Particle, 3)
            END IF
            Particles(Particle, 4) = ParticleLifeSpan - 1
        ELSE
            'new particle
            ParticleAngle# = 6.283185308# * RND
            ParticleRow = ParticleStreamRow
            ParticleCol = ParticleStreamCol
            Particles(Particle, 2) = COS(ParticleAngle#) * DefParticleSpeed
            Particles(Particle, 3) = SIN(ParticleAngle#) * DefParticleSpeed
            Particles(Particle, 4) = DefParticleLifeSpan
            Particles(Particle, 5) = ParticleStreamColor
        END IF
        'PSET (PreParticleCol, PreParticleRow), 0
        'PSET (ParticleCol, ParticleRow), Particles(Particle, 5)
        POKE PreParticleRow * 320 + PreParticleCol, 0
        POKE ParticleRow * 320 + ParticleCol, Particles(Particle, 5)+128
        Particles(Particle, 0) = ParticleRow
        Particles(Particle, 1) = ParticleCol
    NEXT Particle
   
    ParticleStreamColor = (ParticleStreamColor + 1) AND 127
    ParticleStreamRow = ParticleStreamRow + ParticleStreamRowSpeed
    ParticleStreamCol = ParticleStreamCol + ParticleStreamColSpeed
    IF ParticleStreamRow < 0 OR ParticleStreamRow >= ScreenHeight THEN
        ParticleStreamRow = -ParticleStreamRow
        StreamChange = 1
    END IF
    IF ParticleStreamCol < 0 OR ParticleStreamCol >= ScreenWidth THEN
        ParticleStreamCol = -ParticleStreamCol
        StreamChange = 1
    END IF
    IF StreamChange THEN
        ParticleAngle# = 6.283185308# * RND
        ParticleStreamRowSpeed = COS(ParticleAngle#) * DefParticleStreamSpeed
        ParticleStreamColSpeed = SIN(ParticleAngle#) * DefParticleStreamSpeed
        IF ParticleStreamRow < ParticleBounceBorder THEN
            IF ParticleStreamRowSpeed < 0 THEN ParticleStreamRowSpeed = -ParticleStreamRowSpeed
        ELSEIF ParticleStreamRow > ScreenHeight - ParticleBounceBorder THEN
            IF ParticleStreamRowSpeed > 0 THEN ParticleStreamRowSpeed = -ParticleStreamRowSpeed
        END IF
        IF ParticleStreamCol < ParticleBounceBorder THEN
            IF ParticleStreamColSpeed < 0 THEN ParticleStreamColSpeed = -ParticleStreamColSpeed
        ELSEIF ParticleStreamCol > ScreenWidth - ParticleBounceBorder THEN
            IF ParticleStreamColSpeed > 0 THEN ParticleStreamColSpeed = -ParticleStreamColSpeed
        END IF
        StreamChange = 0
    END IF

    DEF SEG = 0
    DO: LOOP UNTIL PreTime <> PEEK(1132)
LOOP UNTIL LEN(INKEY$)

WIDTH 80, 25
SYSTEM

SetScreenMode:
    SCREEN 13
    OUT &H3C8, 128
    FOR Count = 0 TO 127
        OUT &H3C9, INT(COS(Count / 20.37185) * 31) + 32
        OUT &H3C9, INT(COS((Count + 43) / 20.37185) * 31) + 32
        OUT &H3C9, INT(COS((Count + 85) / 20.37185) * 31) + 32
    NEXT Count
RETURN
