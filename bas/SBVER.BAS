DEFINT A-Z

SbEnv$ = ENVIRON$("BLASTER")
CharPos = INSTR(SbEnv$, "A")
IF CharPos THEN
    SbPort = VAL("&H" + MID$(SbEnv$, CharPos + 1))
    DO: LOOP WHILE INP(SbPort + &HC) AND 128: OUT SbPort + &HC, &HE1
    DO: LOOP UNTIL INP(SbPort + &HE) AND 128: MajorVer = INP(SbPort + &HA)
    DO: LOOP UNTIL INP(SbPort + &HE) AND 128: MinorVer = INP(SbPort + &HA)
    PRINT "Sound card version:"; STR$(MajorVer); "."; LTRIM$(STR$(MinorVer))
ELSE
    PRINT "BLASTER environment variable not set"
END IF

