DECLARE SUB SbDataOut (Register%, Value%)
'FmNote
DEFINT A-Z

CONST SbPortBase = &H388

'PRINT ENVIRON$("BLASTER")
'   REGISTER     VALUE     DESCRIPTION
SbDataOut &H20, &H0 '    Set the modulator's multiple to 1
SbDataOut &H40, &H10'    Set the modulator's level to about 40 dB
SbDataOut &H60, &H66'    Modulator attack: quick;   decay: long
SbDataOut &H80, &HFF'    Modulator sustain: medium;  release: medium
SbDataOut &HA0, &H98'    Set voice frequency's LSB (it'll be a D#)
SbDataOut &H23, &H0 '    Set the carrier's multiple to 1
SbDataOut &H43, &H1 '    Set the carrier to maximum volume (about 47 dB)
SbDataOut &H63, &H70'    Carrier attack:  quick;   decay:   long
SbDataOut &H83, &HFF'    Carrier sustain: medium;  release: medium
SbDataOut &HB0, &H31'    Turn the voice on; set the octave and freq MSB

'PRINT "ready to begin pitch slide"
DO: LOOP UNTIL LEN(INKEY$)
'pretime# = TIMER
'FOR a = &H98 TO 0 STEP -5
'    SbDataOut &HA0, a'    Set voice frequency's LSB (it'll be a D#)
'    DO: LOOP UNTIL TIMER > pretime#: pretime# = pretime# + .1
'    IF LEN(INKEY$) THEN EXIT FOR
'NEXT a

SbDataOut &HB0, &H0 '    Turn the voice off

SUB SbDataOut (Register, Value)
    OUT SbPortBase, Register
    OUT SbPortBase + 1, Value
END SUB

