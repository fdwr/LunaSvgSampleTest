'2001-10-06
'Samples out should equal samples to output, but will never be less than
'samples in.
DEFLNG A-Z

SampleMultiplier = 1
SamplesToMix = 735
SamplesToDma = 735 + &H1E
SamplesDmad = SamplesToDma
SamplesMixed = SamplesToMix

CountRatio:
CLS

CountInc = SamplesDmad - SamplesMixed
SamplesOut = 0
FOR Sample = 1 TO SamplesToMix
    Count = Count + CountInc
    IF Count >= SamplesMixed THEN
        Count = Count - SamplesMixed
        SamplesOut = SamplesOut + 1
    END IF
    SamplesOut = SamplesOut + 1
NEXT

PRINT "samples in:"; SamplesMixed
PRINT "desired out:"; SamplesDmad
PRINT "actually out:"; SamplesOut
PRINT "count:"; Count
PRINT "inc:"; CountInc

SamplesMixed = SamplesMixed + SamplesToMix
SamplesDmad = SamplesDmad + SamplesToDma + INT(RND * 11) - 5

DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)
IF Key$ = CHR$(13) GOTO CountRatio

