'PlayFreq
'Peekin
'2001-08-24
'http://fdwr.tripod.com/snes.htm
'FDwR@hotmail.com
'
'Simple FM frequency player. It assumes that the port base is at 388h, since I
'only intended for this to run on my own computer.

DEFINT A-Z
DECLARE SUB SbDataOut (Register, Value%)
DECLARE SUB SbInitChannel (Channel%)
DECLARE FUNCTION GetPitchNote% (Freq%)
DECLARE SUB PlayFreq (Hertz%, Reg%)

CONST True = -1, False = 0, ChromaticMultiple = 1.059469
CONST DefSbPortBase = &H388 'change to 228h for most
CONST HertzMax = 12543

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
bp AS INTEGER: si AS INTEGER: di AS INTEGER: fl AS INTEGER
Ds AS INTEGER: es AS INTEGER
END TYPE

DIM SHARED FreqTable(127) AS LONG, SbFmRegTable(8)
DIM SHARED Regs AS RegType
DIM SHARED SbPortBase

PRINT "Initializing tables..."

SbPortBase = DefSbPortBase
EnvStr$ = ENVIRON$("BLASTER")
CharPos = INSTR(EnvStr$, "A")
IF CharPos THEN SbPortBase = VAL("&H0" + MID$(EnvStr$, CharPos + 1)) + 8

'build note to fnumber table
Pitch# = 14080 * .9438743126816935# 'pitch of note just above G10
Octave = 7
OctaveMultiple# = .1647759272668758#
FOR Count = 127 TO 0 STEP -1
    Pitch# = Pitch# * .9438743126816935#
GetFnumber:
    Freq = Pitch# * OctaveMultiple#
    IF Freq > 1023 THEN
        FreqTable(Count) = &H1FFF
    ELSE
        IF Freq < 512 AND Octave > 0 THEN
            Octave = Octave - 1
            OctaveMultiple# = (2 ^ (20 - Octave)) / 49716
            GOTO GetFnumber
        END IF
        FreqTable(Count) = Freq OR (Octave * 1024)
    END IF
NEXT Count

'Clear all SB registers
'FOR Count = 0 TO 255: SbDataOut Count, &H0: NEXT Count
SbDataOut &HBD, &H0 'turn off rhythm mode
RESTORE ChannelRegData
FOR Count = 0 TO 8
    READ SbFmRegTable(Count)
    SbInitChannel Count
NEXT Count


'SCREEN 13
CLS

PRINT
PRINT
PRINT "Left/Right  one tone"
PRINT "Up/Down     octave (twelve tones)"
PRINT "+ -         one hertz"
PRINT "* /         ten hertz"
PRINT "0-9 BkSpc   type frequency"
PRINT "Enter       play frequency"
PRINT "Space       start/stop scale"

Hertz = 440
DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE CHR$(0) + "H": Hertz = Hertz * 2: IF Hertz <= 55 THEN Hertz = 55
    CASE CHR$(0) + "P": Hertz = Hertz \ 2
    CASE CHR$(0) + "K": Hertz = Hertz * .9438743126816935#
    CASE CHR$(0) + "M": Hertz = Hertz * 1.059463094359296#
    CASE CHR$(0) + "s", "-": Hertz = Hertz - 1
    CASE CHR$(0) + "t", "+": Hertz = Hertz + 1
    CASE CHR$(0) + "I", "/": Hertz = Hertz + 10
    CASE CHR$(0) + "Q", "*": Hertz = Hertz - 10
    CASE "0" TO "9": IF Hertz >= 1255 THEN Hertz = HertzMax ELSE Hertz = Hertz * 10 + VAL(Key$)
    CASE CHR$(8): Hertz = Hertz \ 10
    CASE CHR$(13): PlayFreq Hertz, 0
    CASE " ": PlayingScale = PlayingScale XOR -1
    CASE CHR$(27): EXIT DO
    END SELECT
    IF PlayingScale THEN
        IF TIMER - PreTime# > .1 THEN
            PreTime# = TIMER
            Hertz = Hertz * 1.059463094359296#
            Reg = (Reg + 1) AND 7
            IF Hertz > HertzMax THEN PlayingScale = 0 ELSE PlayFreq Hertz, Reg + 1
        END IF
    END IF
    IF Hertz < 0 THEN Hertz = 0 ELSE IF Hertz > HertzMax THEN Hertz = HertzMax

    LOCATE 1, 1: PRINT STR$(Hertz); "hz"; TAB(10);
LOOP

'SbDataOut &HB0, &H0'    Turn the voices off
CLS
END

'FmFreqData:
'DATA &H16B,&H181,&H198,&H1B0,&H1CA,&H1E5
'C#=277.2  D=293.7  D#=311.1  E=329.6  F=349.2  F#=370.0
'DATA &H202,&H220,&H241,&H263,&H287,&H2AE
'G=392.0  G#=415.3  A=440.0  A#=466.2  B=493.9  C=523.3

ChannelRegData:
DATA 0,1,2,8,9,10,16,17,18

SUB PlayFreq (Hertz, Reg)
'2001-07-25

DIM FreqNumber, Frequency AS DOUBLE

SbDataOut &HB0 + Reg, &H0               'Turn the voice off

'The largest hertz input should never be more 12543hz because that is the
'highest MIDI note, however, the sound card further limits that range because
'it can not produce pitches higher than 6144hz (excluding modulator
'frequency multiplication).
IF Hertz > 6144 THEN
    SbDataOut &HA0 + Reg, &HFF 'Set voice frequency's LSB
    SbDataOut &HB0 + Reg, &H3F 'Turn the voice on; set the octave and freq MSB
    EXIT SUB
END IF

'sb frequency = hertz * 2^20
Frequency = Hertz * 1048576#
Octave = 0
DO WHILE Frequency > 50331648 '(48 * (2 ^ 20)) / 49716 < 1024
    Frequency = Frequency / 2
    Octave = Octave + 4
LOOP
FreqNumber = Frequency \ 49716

SbDataOut &HA0 + Reg, FreqNumber AND 255 'Set voice frequency's LSB
SbDataOut &HB0 + Reg, (FreqNumber \ 256) OR Octave OR &H20 'Turn the voice on; set the octave and freq MSB

END SUB

SUB SbDataOut (Register, Value)
    OUT SbPortBase, Register
    Dummy = INP(SbPortBase): Dummy = INP(SbPortBase): Dummy = INP(SbPortBase)
    OUT SbPortBase + 1, Value
    Dummy = INP(SbPortBase): Dummy = INP(SbPortBase): Dummy = INP(SbPortBase)
    Dummy = INP(SbPortBase): Dummy = INP(SbPortBase): Dummy = INP(SbPortBase)
END SUB

'Fill each channel with simple default sound
SUB SbInitChannel (Channel)
    Reg = SbFmRegTable(Channel)
    'SbDataOut &H20 + Reg, &H2  'Set the modulator's multiple to 1
    'SbDataOut &H40 + Reg, &H10 'Set the modulator's level to about 40 dB
    'SbDataOut &H60 + Reg, &H99  'Modulator attack: quick;   decay: long
    'SbDataOut &H80 + Reg, &H88 'Modulator sustain: medium;  release: medium
    'SbDataOut &H23 + Reg, &H1  'Set the carrier's multiple to 1
    'SbDataOut &H43 + Reg, &H0  'Set the carrier to maximum volume (about 47 dB)
    'SbDataOut &H63 + Reg, &H74 'Carrier attack:  quick;   decay:   long
    'SbDataOut &H83 + Reg, &HFF 'Carrier sustain: medium;  release: medium
   
    SbDataOut &H20 + Reg, &H3  'Set the modulator's multiple to 1
    SbDataOut &H40 + Reg, &H10 'Set the modulator's level to about 40 dB
    SbDataOut &H60 + Reg, &H99 'Modulator attack: quick;   decay: long
    SbDataOut &H80 + Reg, &H88 'Modulator sustain: medium;  release: medium
    SbDataOut &H23 + Reg, &H1  'Set the carrier's multiple to 1
    SbDataOut &H43 + Reg, &H0  'Set the carrier to maximum volume (about 47 dB)
    SbDataOut &H63 + Reg, &H75 'Carrier attack:  quick;   decay:   long
    SbDataOut &H83 + Reg, &H16 'Carrier sustain: medium;  release: medium
   
    '2 10 99 88 1 0 f4 ff   chirp whistle
    '2 10 88 88 1 0 f4 ff   glass blow
    '4 10 aa 88 1 0 f4 88   glock+vibraphone
    '1 10 88 33 1 0 c4 44   sitar
    '2 10 88 33 1 0 c4 44   carnival
    '2 10 f8 44 1 0 c4 44   wood glock+celesta
    '3 10 99 88 1 0 75 16   marimba
END SUB

