'Traveling Wave Cochlea Simulation
'2000.10.10 Peekin
'
DEFINT A-Z
DECLARE SUB AdjustValue (ValueIn%, ValueOut%, AdjustMode%, ValueDif%)
DECLARE FUNCTION SoundInput% ()
DECLARE FUNCTION TestWaveInput% ()

CONST CochleaTop = 100, CochleaLeft = 0, CochleaWidthMax = 100
CONST EditModeWaveWidth = 0, EditModeWaveHeight = 1, EditModeWaveForm = 2, EditModeTotal = 3
CONST AdjustValueAdd = 1, AdjustValueAppend = 2, AdjustValueTrim = 3
CONST WaveFormSilence = 0, WaveFormBuffer = 1, WaveFormSine = 2, WaveFormSquare = 3, WaveFormSawTooth = 4, WaveFormSpike = 5
CONST RedrawCochlea = 1

DIM SHARED TestWaveLength, TestWaveHeight, TestWavePhase, TestWaveForm
DIM SHARED CochleaPoint(CochleaWidthMax * 2), CochleaWidth

GOSUB Init

Redraw = -1
DO
    Key$ = INKEY$
    SELECT CASE Key$
    CASE ""
        IF Redraw THEN GOSUB RedrawSimPage
    CASE "0" TO "9"
        AdjustValueMode = AdjustValueAppend
        Value = VAL(Key$)
    CASE CHR$(8)
        AdjustValueMode = AdjustValueTrim
    CASE CHR$(0) + "K"
        AdjustValueMode = AdjustValueAdd
        Value = -1
    CASE CHR$(0) + "M"
        AdjustValueMode = AdjustValueAdd
        Value = 1
    'EditMode=EditMode+EditModeTotal+1
    CASE "h": EditMode = EditModeWaveHeight: GOSUB ChangeEditMode
    CASE "w": EditMode = EditModeWaveWidth: GOSUB ChangeEditMode
    CASE "f": EditMode = EditModeWaveForm: GOSUB ChangeEditMode
    CASE "p": IF SimActive <> 1 THEN SimActive = 1 ELSE SimActive = 64
    CASE " ": SimActive = 128
    CASE CHR$(27): EXIT DO
    END SELECT

    IF AdjustValueMode THEN
        SELECT CASE EditMode
        CASE EditModeWaveWidth: AdjustValue TestWaveLength, TestWaveLength, AdjustValueMode, Value
        CASE EditModeWaveHeight: AdjustValue TestWaveHeight, TestWaveHeight, AdjustValueMode, Value
        CASE EditModeWaveForm
            IF AdjustValueMode = AdjustValueAppend THEN
                TestWaveForm = Value
            ELSE
                AdjustValue TestWaveForm, TestWaveForm, AdjustValueMode, Value
            END IF
        END SELECT
        AdjustValueMode = 0
    END IF

    IF SimActive = 1 THEN
        IF TIMER <> PreTime# THEN SimActive = SimActive OR 128
        PreTime# = TIMER
    END IF
    IF SimActive >= 64 THEN GOSUB AdvanceSim: SimActive = SimActive AND 127
LOOP

WIDTH 80, 25
END

Init:
    SCREEN 13
    OUT &H3C8, 128
    FOR Count = 0 TO 127
        OUT &H3C9, INT(SIN(Count / 81.48732) * 63) '6.283186
        OUT &H3C9, 0
        OUT &H3C9, INT(COS(Count / 81.48732) * 63) '6.283186
        'OUT &H3C9, INT(COS(Count / 20.37185) * 31) + 32
        'OUT &H3C9, INT(COS((Count + 43) / 20.37185) * 31) + 32
        'OUT &H3C9, INT(COS((Count + 85) / 20.37185) * 31) + 32
    NEXT Count
    LINE (0, 190)-(129, 199), 15, B
    FOR Count = 128 TO 255
        LINE (Count - 127, 191)-(Count - 127, 198), Count
    NEXT Count

    CochleaWidth = 100
    TestWaveForm = WaveFormSine
    TestWaveLength = 10
    TestWaveHeight = 30
    SimActive = 1
RETURN

ChangeEditMode:
    LOCATE 23, 1
    SELECT CASE EditMode
    CASE EditModeWaveWidth: PRINT "wave width ";
    CASE EditModeWaveHeight: PRINT "wave height";
    CASE EditModeWaveForm: PRINT "wave form  ";
    END SELECT
RETURN

AdvanceSim:
    'FOR Count = CochleaWidthMax + CochleaWidth - 1 TO CochleaWidthMax + 1 STEP -1
    '    CochleaPoint(Count) = CochleaPoint(Count - 1)
    'NEXT Count
    'CochleaPoint(CochleaWidthMax) = CochleaPoint(CochleaWidth - 1)
    FOR Count = CochleaWidthMax TO CochleaWidthMax + CochleaWidth - 2
        CochleaPoint(Count) = CochleaPoint(Count + 1)
    NEXT Count
    CochleaPoint(Count) = CochleaPoint(CochleaWidth - 1)
    FOR Count = CochleaWidth - 1 TO 1 STEP -1
        CochleaPoint(Count) = CochleaPoint(Count - 1)
    NEXT Count
    CochleaPoint(0) = TestWaveInput
   
    PeakDif = 0
    PeakDifPoint = 0
    FOR Count = 0 TO CochleaWidth - 1
        Value = ABS(CochleaPoint(Count) - CochleaPoint(Count + CochleaWidthMax))
        IF Value > PeakDif THEN PeakDifPoint = Count: PeakDif = Value
    NEXT Count

    Redraw = Redraw OR RedrawCochlea
RETURN

RedrawSimPage:
    FOR Count = 0 TO CochleaWidth - 1
        LINE (Count + CochleaLeft, CochleaTop - 60)-(Count + CochleaLeft, CochleaTop + 60), 0
        LINE (Count + CochleaLeft, CochleaTop)-(Count + CochleaLeft, CochleaTop + CochleaPoint(Count) - CochleaPoint(CochleaWidthMax + Count)), DifColor + 128
        PSET (Count + CochleaLeft, CochleaTop - 1), CochleaPoint(Count) + 192
        PSET (Count + CochleaLeft, CochleaTop + 1), CochleaPoint(CochleaWidthMax + Count) + 192
        IF Count = PeakDifPoint THEN PSET (CochleaLeft + PeakDifPoint, CochleaTop), 15
    NEXT Count
    'LINE (CochleaLeft, CochleaTop)-(CochleaLeft + CochleaWidthMax, CochleaTop), 0
    
    LOCATE 25, 20: PRINT CochleaPoint(0); PeakDifPoint; TestWaveLength;
    DifColor = (DifColor + 4) AND 127
    Redraw = 0
RETURN

SUB AdjustValue (ValueIn, ValueOut, AdjustMode, ValueDif)

SELECT CASE AdjustMode
CASE AdjustValueAdd: ValueOut = ValueIn + ValueDif
CASE AdjustValueAppend: ValueOut = ValueIn * 10 + ValueDif
CASE AdjustValueTrim: ValueOut = ValueIn \ 10
END SELECT

END SUB

FUNCTION TestWaveInput

IF TestWaveLength <= 0 THEN EXIT FUNCTION

SELECT CASE TestWaveForm
CASE WaveFormSilence
    TestWaveInput = 0
CASE WaveFormSine
    TestWaveInput = COS(TestWavePhase / TestWaveLength * 6.28318) * TestWaveHeight
    IF TestWavePhase <= 0 THEN TestWavePhase = TestWaveLength
    TestWavePhase = TestWavePhase - 1
CASE WaveFormSquare
    IF TestWavePhase < TestWaveLength \ 2 THEN
        TestWaveInput = TestWaveHeight
        IF TestWavePhase <= 0 THEN TestWavePhase = TestWaveLength
    ELSE
        TestWaveInput = -TestWaveHeight
    END IF
    TestWavePhase = TestWavePhase - 1
CASE WaveFormSawTooth
    IF TestWavePhase <= 0 THEN TestWavePhase = TestWavePhase + TestWaveLength * 2
    TestWaveInput = -TestWaveHeight + TestWavePhase * TestWaveHeight / TestWaveLength
    TestWavePhase = TestWavePhase - 2
CASE WaveFormSpike
    IF TestWavePhase <= 0 THEN
        TestWaveInput = -TestWaveHeight
        TestWavePhase = TestWaveLength
    ELSEIF Phase = 1 THEN
        TestWaveInput = TestWaveHeight
    ELSE
        TestWaveInput = 0
    END IF
    TestWavePhase = TestWavePhase - 1
END SELECT

END FUNCTION

