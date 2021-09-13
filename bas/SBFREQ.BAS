'1999.11.20 Dwayne Robinson
'
'Middle C = 261.625 (MIDI note number 60)
'F-Number = Music Frequency * 2^(20-Octave) / 49716 Hz
'
' Note    Frequency      Note   Frequency       Note   Frequency
' C  0    8.1757989156    12    16.3515978313    24    32.7031956626
' Db 1    8.6619572180    13    17.3239144361    25    34.6478288721
' D  2    9.1770239974    14    18.3540479948    26    36.7080959897
' Eb 3    9.7227182413    15    19.4454364826    27    38.8908729653
' E  4   10.3008611535    16    20.6017223071    28    41.2034446141
' F  5   10.9133822323    17    21.8267644646    29    43.6535289291
' Gb 6   11.5623257097    18    23.1246514195    30    46.2493028390
' G  7   12.2498573744    19    24.4997147489    31    48.9994294977
' Ab 8   12.9782717994    20    25.9565435987    32    51.9130871975
' A  9   13.7500000000    21    27.5000000000    33    55.0000000000
' Bb 10  14.5676175474    22    29.1352350949    34    58.2704701898
' B  11  15.4338531643    23    30.8677063285    35    61.7354126570
'
' C  36  65.4063913251    48   130.8127826503    60   261.6255653006
' Db 37  69.2956577442    49   138.5913154884    61   277.1826309769
' D  38  73.4161919794    50   146.8323839587    62   293.6647679174
' Eb 39  77.7817459305    51   155.5634918610    63   311.1269837221
' E  40  82.4068892282    52   164.8137784564    64   329.6275569129
' F  41  87.3070578583    53   174.6141157165    65   349.2282314330
' Gb 42  92.4986056779    54   184.9972113558    66   369.9944227116
' G  43  97.9988589954    55   195.9977179909    67   391.9954359817
' Ab 44  103.8261743950   56   207.6523487900    68   415.3046975799
' A  45  110.0000000000   57   220.0000000000    69   440.0000000000
' Bb 46  116.5409403795   58   233.0818807590    70   466.1637615181
' B  47  123.4708253140   59   246.9416506281    71   493.8833012561
'
' C  72  523.2511306012   84  1046.5022612024    96  2093.0045224048
' Db 73  554.3652619537   85  1108.7305239075    97  2217.4610478150
' D  74  587.3295358348   86  1174.6590716696    98  2349.3181433393
' Eb 75  622.2539674442   87  1244.5079348883    99  2489.0158697766
' E  76  659.2551138257   88  1318.5102276515   100  2637.0204553030
' F  77  698.4564628660   89  1396.9129257320   101  2793.8258514640
' Gb 78  739.9888454233   90  1479.9776908465   102  2959.9553816931
' G  79  783.9908719635   91  1567.9817439270   103  3135.9634878540
' Ab 80  830.6093951599   92  1661.2187903198   104  3322.4375806396
' A  81  880.0000000000   93  1760.0000000000   105  3520.0000000000
' Bb 82  932.3275230362   94  1864.6550460724   106  3729.3100921447
' B  83  987.7666025122   95  1975.5332050245   107  3951.0664100490
'
' C  108 4186.0090448096  120  8372.0180896192
' Db 109 4434.9220956300  121  8869.8441912599
' D  110 4698.6362866785  122  9397.2725733570
' Eb 111 4978.0317395533  123  9956.0634791066
' E  112 5274.0409106059  124 10548.0818212118
' F  113 5587.6517029281  125 11175.3034058561
' Gb 114 5919.9107633862  126 11839.8215267723
' G  115 6271.9269757080  127 12543.8539514160
' Ab 116 6644.8751612791
' A  117 7040.0000000000
' Bb 118 7458.6201842894
' B  119 7902.1328200980
'
'  16B  277.2  C#
'  181  293.7  D
'  198  311.1  D#
'  1B0  329.6  E
'  1CA  349.2  F
'  1E5  370.0  F#
'  202  392.0  G
'  220  415.3  G#
'  241  440.0  A
'  263  466.2  A#
'  287  493.9  B
'  2AE  523.3  C

DEFINT A-Z
DECLARE SUB SbDataOut (Register%, Value%)

CONST SbPortBase% = &H388

SbDataOut &H20, &H0   'Set the modulator's multiple to 1
SbDataOut &H40, &H10  'Set the modulator's level to about 40 dB
SbDataOut &H60, &H88  'Modulator attack: quick;   decay: long
SbDataOut &H80, &H88  'Modulator sustain: medium;  release: medium
SbDataOut &H23, &H1   'Set the carrier's multiple to 1
SbDataOut &H43, &H0   'Set the carrier to maximum volume (about 47 dB)
SbDataOut &H63, &HF4  'Carrier attack:  quick;   decay:   long
SbDataOut &H83, &HFF  'Carrier sustain: medium;  release: medium

'SbDataOut &HB0, &H0
'SbDataOut &HA0, 100
'SbDataOut &HB0, 12 OR  OR &H20

CLS
LOCATE 3, 1
PRINT "Up/Down         = Pitch by octave (*2 /2)"
PRINT "Left/Right      = Pitch fnumber (+1 -1)"
PRINT "Ctrl+Right/Left = Pitch by note (+1 -1)"
PRINT "+ -             = Octave number"
PRINT
PRINT "Enter           = Type in absolute frequency"
PRINT "Esc             = Quit"

Change = 1
DO
    key$ = INKEY$
    SELECT CASE key$
    CASE CHR$(0) + "H": Freq = Freq * 2: Change = 2
    CASE CHR$(0) + "P": Freq = Freq \ 2: Change = 2
    CASE CHR$(0) + "t": Freq = Freq * 1.059463094359296#: Change = 2
    CASE CHR$(0) + "s": Freq = Freq * .9438743126816935#: Change = 2
    CASE CHR$(0) + "M": Freq = Freq + 1: Change = 2
    CASE CHR$(0) + "K": Freq = Freq - 1: Change = 2
    CASE "+": Octave = Octave + 1: Change = 2
    CASE "-": Octave = Octave - 1: Change = 2
    CASE " ": Change = 2
    CASE CHR$(13)
        LOCATE 1, 1: PRINT SPACE$(30);
        LOCATE 1, 1: INPUT ; "Frequency:", Frequency#
        Freq = Frequency# * (2 ^ (20 - Octave)) / 49716
        Change = 2
    CASE CHR$(27): EXIT DO
    END SELECT
    IF Change THEN
        Octave = Octave AND 7
        Freq = Freq AND 1023
        IF Change > 1 THEN
            'Turn the voice off
            SbDataOut &HB0, &H0
            'Set frequency's LSB
            'SbDataOut &HA0, 4504
            SbDataOut &HA0, Freq
            'Frequency MSB, Octave, and turn the voice on
            'SbDataOut &HB0, (408 \ 256) OR (Octave * 4) OR &H20
            SbDataOut &HB0, ((Freq \ 256) AND 3) OR (Octave * 4) OR &H20
            Change = 0
        END IF
        LOCATE 1, 1: PRINT "Fnumber:"; Freq; " Octave:"; Octave; TAB(30);
    END IF
LOOP

END

SUB SbDataOut (Register, Value)
    OUT SbPortBase, Register
    Dummy = INP(SbPortBase): Dummy = INP(SbPortBase): Dummy = INP(SbPortBase)
    OUT SbPortBase + 1, Value
    Dummy = INP(SbPortBase): Dummy = INP(SbPortBase): Dummy = INP(SbPortBase)
    Dummy = INP(SbPortBase): Dummy = INP(SbPortBase): Dummy = INP(SbPortBase)
END SUB

