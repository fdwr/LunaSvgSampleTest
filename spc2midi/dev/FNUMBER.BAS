'1999-12-28
' C5 (261.625hz) is Middle C (MIDI note number 60)
' A5 (440hz)     is what tuning forks emit
' G10 (12543hz)  is the highest note in the MIDI scale
'
' The pitch of A5 is 440hz (note number 69, in the same key as middle C).
' The highest note in the MIDI scale is G10 (12543hz), but the sound card can
' only output frequency's up to 6211hz
' so anything above 7 is clipped.
'
' 1.059463094359296#  semitone constant (accuracy ~11 zeroes)
'
'
' These values were copied from a document by Jeffrey S. Lee 1992
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
'
' This formula is from the SB documentation and seems slightly off. To my
' ears at least, it is just the slightest bit flat. After comparing the FM
' notes with my Roland, A440 should really be closer to 244h instead of 241h.
'
'   FreqNumber = Hertz * 1048576 / (2 ^ Octave) / 50000
'
' Don't remember where I got this formula below from, but it's better
'
'   F-Number = Music Frequency * 2^(20-Block) / 49716 Hz


DEFDBL A-Z
DIM FreqNumberInt AS LONG

PRINT "Fnumber        Octave"
PRINT

PRINT "Middle C"
Hertz = 261.625
Octave = 4   '0-7
GOSUB PrintFreq

PRINT "Highest frequency OPL2 FM on sound card can produce"
Hertz = 6211
Octave = 7   '0-7
GOSUB PrintFreq

PRINT "Highest frequency in first octave"
Hertz = 48.52
Octave = 0   '0-7
GOSUB PrintFreq

PRINT "A5 which tuning forks emit"
Hertz = 440
Octave = 4   '0-7
GOSUB PrintFreq

END

PrintFreq:
    FreqNumber = Hertz * (2 ^ (20 - Octave)) / 49716
    FreqNumberInt = CINT(FreqNumber + .0000001)
    PRINT FreqNumberInt; HEX$(FreqNumberInt) + "h", Octave; FreqNumber
    PRINT
RETURN

