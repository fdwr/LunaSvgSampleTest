' Converted from fourierd.c - Don Cross <dcross@intersrv.com>
'
' http://www.intersrv.com/~dcross/fft.html
'
' Performs Fourier transforms, using arrays of type 'double'.
'
'=============================================================================

DEFINT A-Z

CONST NumSamples = 256

DIM RealIn(0 TO NumSamples - 1)  AS DOUBLE
DIM ImagIn(0 TO NumSamples - 1) AS DOUBLE
DIM RealOut(0 TO NumSamples - 1) AS DOUBLE
DIM ImagOut(0 TO NumSamples - 1) AS DOUBLE

SCREEN 13
GOSUB SineWave
GOSUB Fft
GOSUB ShowAmplitudes
WIDTH 80, 25
END

SineWave:
    WaveLength = 5
    Ratio# = WaveLength / 6.283186#
    FOR Count = 0 TO NumSamples - 1
        RealIn(Count) = COS(Count / Ratio#) * 2
    NEXT Count
    '7=10 14=5
    '7=80 14=160
    'FOR Count = 0 TO NumSamples - 1
    '    RealIn(Count) = RealIn(Count) + COS(Count / 5) * 1
    'NEXT Count
RETURN

ShowAmplitudes:
DIM Amplitude AS DOUBLE
DIM GreatestAmplitude AS DOUBLE

    CLS
    GreatestAmplitude = -1
    GreatestFreq = 0
    FOR Count = 0 TO NumSamples - 1
        Amplitude = RealOut(Count) * RealOut(Count) + ImagOut(Count) * ImagOut(Count)
        IF Amplitude > GreatestAmplitude THEN
            GreatestAmplitude = Amplitude
            GreatestFreq = Count
        END IF
        LINE (Count, 100)-(Count, Amplitude / 800 + 100), 9
    NEXT Count
    LINE (GreatestFreq - 1, 0)-(GreatestFreq + 1, 199), 7, B
    LOCATE 1, 1: PRINT "Max:"; GreatestFreq; "at"; GreatestAmplitude
    DO: LOOP UNTIL LEN(INKEY$)
RETURN

Fft:
DIM NumBits, BlockSize, BlockStep
DIM i, j, k, n

DIM DeltaAngle AS DOUBLE, TempReal AS DOUBLE, TempImag AS DOUBLE
DIM cmw AS DOUBLE
DIM sm1 AS DOUBLE, sm2 AS DOUBLE
DIM cm1 AS DOUBLE, cm2 AS DOUBLE
DIM ar1 AS DOUBLE, ar2 AS DOUBLE, ar3 AS DOUBLE
DIM ai1 AS DOUBLE, ai2 AS DOUBLE, ai3 AS DOUBLE

'void fft (unsigned NumSamples,double *RealIn,*ImagIn,*RealOut,*ImagOut)

Value = NumSamples
NumBits = 0
DO WHILE Value > 1
    NumBits = NumBits + 1
    Value = Value \ 2
LOOP

'**  Do simultaneous data copy and bit-reversal ordering into outputs...

FOR Count = 0 TO NumSamples - 1
    Mask = 1
    Value = 0
    FOR Bit = 1 TO NumBits
        Value = Value * 2
        IF Count AND Mask THEN Value = Value + 1
        Mask = Mask * 2
    NEXT Bit
    RealOut(Count) = RealIn(Count)
    ImagOut(Value) = 0       '(ImagIn == NULL) ? 0.0 : ImagIn[i]
    PSET (Value, RealOut(Value) + 100), 9
    'PSET (Count, RealOut(Count) + 100), 9
NEXT Count

DO: LOOP UNTIL LEN(INKEY$)
'**  Do the FFT itself...

BlockStep = 1
BlockSize = 2
DO WHILE BlockSize <= NumSamples
    DeltaAngle = 2 * 3.14159 / BlockSize
    sm1 = SIN(-DeltaAngle)
    sm2 = SIN(-2 * DeltaAngle)
    cm1 = COS(-DeltaAngle)
    cm2 = COS(-2 * DeltaAngle)
    cmw = 2 * cm1

    i = 0
    DO WHILE i < NumSamples
        ar1 = cm1: ar2 = cm2
        ai1 = sm1: ai2 = sm2

        j = i
        FOR n = 0 TO BlockStep - 1
            ar0 = cmw * ar1 - ar2
            ar2 = ar1: ar1 = ar0

            ai0 = cmw * ai1 - ai2
            ai2 = ai1: ai1 = ai0

            k = j + BlockStep
            tr = ar0 * RealOut(k) - ai0 * ImagOut(k)
            ti = ar0 * ImagOut(k) + ai0 * RealOut(k)

            RealOut(k) = RealOut(j) - tr
            ImagOut(k) = ImagOut(j) - ti
            LINE (k, 0)-(k, 199), 0
            PSET (k, RealOut(k) + 100), 9
            PSET (k, ImagOut(k) + 100), 12

            RealOut(j) = RealOut(j) + tr
            ImagOut(j) = ImagOut(j) + ti
            LINE (j, 0)-(j, 199), 0
            PSET (j, RealOut(j) + 100), 9
            PSET (j, ImagOut(j) + 100), 12
            j = j + 1
        NEXT n
        i = i + BlockSize
    LOOP
    DO: LOOP UNTIL LEN(INKEY$)
    BlockStep = BlockSize
    BlockSize = BlockSize * 2
LOOP

DO: LOOP UNTIL LEN(INKEY$)
RETURN

