'Pitches.bas
'Peekin
'2001-11-01
'http://fdwr.tripod.com/snes.htm
'FDwR@hotmail.com
'
'Generates several tables and exports them to files for Spc2Midi compilation
'
' The pitch of A5 is 440hz (note number 69, in the same key as middle C).
' A10 would be 440 * 2^5 (14080). The highest note in the MIDI scale is G10,
' which is two steps down. The sound card (using Yamaha OPL2) can only make
' frequency's up to 6211hz.
'
' C5 (261.625hz) is Middle C (MIDI note number 60)
' A5 (440hz)     is what tuning forks emit
' G10 (12543hz)  is the highest note in the MIDI scale
'
' Info on Human Hearing:
'   In human hearing, a note that is twelve semitones above another (or one
'   whole octave), is actually twice as high in frequency. If a note played
'   at rate of 4096 (32khz) sounded a middle C, 2048 would be one octave
'   below, and 8192 would be an octave above. This exponential curve must be
'   converted to a linear scale to obtain the MIDI note.
'
'   x * 1.059463094359296#  semitone up 11 zeroes
'   x * .9438743126816935#  semitone down
'   x * .971531941153606#   half semitone down
'
' Converting Play Rates
'   BRR sample play rates (0-16383) can't be converted directly to MIDI notes,
'   since each sample may be recorded at its own pitch. For example, a flute
'   instrument sound may be recorded at middle C, but a piano sound might be
'   recorded at G. I'm not sure why the music programmers choose these
'   seemingly arbitrary pitches rather than make them all have the same base
'   pitch. To compensate for this though, the play rates are multiplied by
'   their sample's apparent pitch. This is the pitch as heard by the human
'   ear (when played at actual recording speed of 32khz) rather than some
'   other frequency determinant like fourier analysis. This product (after
'   being shifted back down because of the multiplication) indexes into a
'   large table, to convert the exponential value into a linear note number.
'   The default apparent pitch for all samples is 440hz (A5).
'
'   PitchValue = (PlayRate * ApparentPitch) >> 12 [4096]
'   NoteNumber = HertzToNoteTbl [PitchValue]
'
' Converting Play Rates to MIDI Notes
'   MIDI notes (C0-G10 or 0-127) range in frequency from 8hz to 12543hz, with
'   any pitches outside that range constrained. So, it would make sense to
'   build a table from 0-12543, but because the lower frequencies are so
'   close (notes 4 and 5 can both be rounded to 10hz), I'd rather double the
'   table size for more precision.
'
'   PitchValue = (PlayRate * (ApparentPitch*2)) >> 13 [8192]
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

DEFINT A-Z

DIM HertzTbl(127), PitchTbl(12543 * 2), SbFnumberTbl(127), HzFnTbl(512)
DIM SineTbl(1023)

DIM LongValue AS LONG

VIEW PRINT 1 TO 25
CLS

'57=220 69=440
Pitch# = 220
Pitch# = 220 / 32
Row = 1: Col = 1
'FOR Count = 57 TO 127
FOR Count = -3 TO 129
    IF (Count MOD 12) = 9 THEN
        COLOR 15
        IF Pitch# >= 55 THEN Pitch# = INT(Pitch#)
        IF Count = 69 THEN GOSUB WaitForKey: CLS : Row = 1: Col = 1
    ELSE
        COLOR 7
    END IF
    LOCATE Row, Col
    PRINT Count; "="; Pitch#' * 2
    IF Row <= 23 THEN Row = Row + 1 ELSE Row = 1: Col = Col + 25
    Pitch# = Pitch# * 1.059463094359296#
NEXT
GOSUB WaitForKey

LOCATE 25, 1
PRINT "Building tables...";



'Build sound card fnumber table
'Any pitch above 388 (*2^20=406847488) makes the fnumber overflow
Pitch# = 14080 * .9438743126816935# 'A10 * semitone-constant = Gb9
Octave = 7
FOR Count = 127 TO 0 STEP -1
    Pitch# = Pitch# * .9438743126816935#
GetFnumber:
    SbFnumber = Pitch# * (2 ^ (20 - Octave)) / 49716
    IF SbFnumber > 1023 THEN
        'clip any notes to high
        SbFnumberTbl(Count) = &H1FFF
    ELSE
        IF SbFnumber < 512 AND Octave > 0 THEN
            'if fnumber is below the range of 512-1023 then move octave down
            '(which sets fnumber back into the range)
            Octave = Octave - 1
            GOTO GetFnumber
        END IF
        SbFnumberTbl(Count) = SbFnumber OR (Octave * 1024)
    END IF
NEXT Count



'Build nearest pitch table
Pitch# = (14080 * 2) * .9438743126816935#
'PRINT "Initial value:"; Pitch#
FOR Note = 127 TO 0 STEP -1
    Pitch# = Pitch# * .9438743126816935#
    HertzTbl(Note) = INT(Pitch# / 2)
    IF (Note MOD 12 = 9) AND Pitch# >= 55 THEN Pitch# = INT(Pitch#): COLOR 15 ELSE COLOR 7
    PRINT Note; Pitch# / 2,
NEXT
'PRINT "Loop"; Note; TAB(15); Pitch#
PRINT "Showing nearest pitch table, gm2hz"
GOSUB WaitForKey



'Build hertz to note number table
Pitch# = (14080 * 2) * .9438743126816935#
PitchHigh = 12543 * 2
'PRINT "Initial value:"; Pitch#
FOR Note = 127 TO 0 STEP -1
    Pitch# = Pitch# * .9438743126816935#
    IF (Note MOD 12 = 9) AND Pitch# >= 55 THEN Pitch# = INT(Pitch#): COLOR 15 ELSE COLOR 7
    PitchLow = INT(Pitch# + .5) * .971531941153606#

    'IF Note >= 69 THEN
    PRINT Note; Pitch#; TAB(30); PitchLow; PitchHigh': IF ((Note + 3) MOD 12 = 0) THEN SLEEP
 
    FOR Count = PitchLow TO PitchHigh
        PitchTbl(Count) = Note
        'LINE (Note, Pitch# \ 82)-(Note, PitchHigh \ 82 - 1)
    NEXT
    PitchHigh = PitchLow - 1
NEXT
'The few lowest numbers are a little off because of rounding, so tweak them
PitchTbl(23) = 6
PitchTbl(22) = 5
PitchTbl(18) = 2
PitchTbl(17) = 1
PRINT
FOR Count = 50 TO 0 STEP -1
    PRINT Count; PitchTbl(Count),
NEXT Count
GOSUB WaitForKey



'Build hertz to fnumber table
'This table only contains values for hertz 0-511. The remaining higher
'frequencies are just shifted down.
PRINT "Hertz to fnumber"
Octave = 0
FOR Count = 0 TO 511
GetFnumber2:
    SbFnumber = CINT(CDBL(Count) * (2 ^ (20 - Octave)) / 49716 + .0000001)
    IF SbFnumber > 1023 THEN
        'clip any notes to high
        Octave = Octave + 1
        GOTO GetFnumber2
    END IF
    PRINT SbFnumber; Octave,
    HzFnTbl(Count) = SbFnumber OR (Octave * 1024)
NEXT


'2001-11-19
'Build sine wave table
'PI*2 = 6.283185307179586#
'1024 / 6.283185307179586# = ~162.9746617261008
DIM SineValue AS DOUBLE
FOR Count = 0 TO 1023
    LongValue = SIN(Count / 162.9746617261008#) * 16384
    'SineValue = SIN(Count / 162.9746617261008#)
    'LongValue = (SineValue * SIN(Count * 8 / 162.9746617261008#) + SineValue) * 16384
    'LongValue = SIN(Count / 162.9746617261008#) * SIN(Count * 4 / 162.9746617261008#) * 32768
    IF LongValue > 32767 THEN LongValue = 32767
    'LongValue = SIN(Count / 162.9746617261008#) * 16384
    'IF Count < 512 THEN LongValue = LongValue + 8192 ELSE LongValue = LongValue - 8192
    SineTbl(Count) = LongValue
    PRINT Count; LongValue,
NEXT
GOSUB WaitForKey
PRINT



PRINT "Done. Press W to write data."; TAB(80);
GOSUB WaitForKey
IF Key$ = "W" THEN
    PRINT "Writing..."
   
    OPEN "gm2fnlut.dat" FOR OUTPUT AS 1
    FOR Count = 0 TO 127
        PRINT #1, MKI$(SbFnumberTbl(Count));
    NEXT Count
    CLOSE 1
   
    OPEN "gm2hzlut.dat" FOR OUTPUT AS 1
    'PRINT #1, MKI$(0);
    FOR Count = 0 TO 127
        PRINT #1, MKI$(HertzTbl(Count));
    NEXT Count
    'PRINT #1, MKI$(16384);
    CLOSE 1

    OPEN "hz2gmlut.dat" FOR OUTPUT AS 1
    RunLength = 0
    PreviousValue = 0
    FOR Count = 0 TO UBOUND(PitchTbl)
        Value = PitchTbl(Count)
        IF Value = PreviousValue THEN
            RunLength = RunLength + 1
        ELSE
            PRINT #1, MKI$(RunLength);
            FOR Note = PreviousValue + 1 TO Value - 1
                PRINT #1, MKI$(0);
            NEXT
            RunLength = 1
            PreviousValue = Value
        END IF
    NEXT Count
    PRINT #1, MKI$(RunLength);
    CLOSE 1

    OPEN "hz2fnlut.dat" FOR OUTPUT AS 1
    FOR Count = 0 TO 511
        PRINT #1, MKI$(HzFnTbl(Count));
    NEXT Count
    CLOSE 1

    OPEN "sinewave.dat" FOR OUTPUT AS 1
    FOR Count = 0 TO 1023
        PRINT #1, MKI$(SineTbl(Count));
    NEXT Count
    CLOSE 1
END IF

END

WaitForKey:
    DO: LOOP WHILE LEN(INKEY$)
    DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)
RETURN

