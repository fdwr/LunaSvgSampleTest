' Simulation of Cochlear Mechanics, Basilar Membrane Resonance
' Peekin 2000.8.1
' 14,21,22,25 dkc2.sp1
'
' -Problem-
' Instrument samples can be recorded at any pitch and at any sample rate,
' which makes it difficult for a music player to play notes using those
' instruments when the base pitch is not known. Rather than attempt to find
' a completely new algorithm, why not just imitate an existing model that
' works quite well, the human ear. It is, after all, our ear which determines
' the pitches we hear.
'
' -Purpose-
' Attempts to simulate the resonant response of the basilar membrane as
' sound waves pass over it. According to the place theory, different areas
' of the membrane are more attenuated to specific frequencies than others,
' allowing pitches to be distinguished. If this test program can accurately
' simluate a single area of the membrane (given tension, mass, and damping)
' then an algorithm can be developed that approximates the human ear's
' response to the whole spectrum. Then, hopefully, the dominant pitch of any
' sound sample (as would be heard by a person) can be determined.
'
' -Concept-
' These areas of the basilar membrane each have their own natural frequencies
' because of the variables tension, mass, damping. A waveform resonates most
' with an area of the basilar membrane when that waveform's frequency matches
' the membrane's natural frequency, or in other words, when the waveform
' is right on the thin line between too much resistance or too much tension.
'
' Too fast of acceleration (cresting early) is dampened by resistance. The
' waveform is attempting to move the membrane faster than it can overcome the
' membrane's mass. Too slow of acceleration (cresting late) is dampened by
' tension. The waveform is not moving the membrane fast enough to overcome
' the rebound pull back towards center (tension).
'
' For lower frequencies, the peak response occurs at the apex of the cochlea
' (the end of the membrane) because of high mass and low tension; while
' higher frequency response occurs near the cochlea's front, where mass is
' low but tension is high.
'
' A perfect sine wave will generate the best resonance, but since real-world
' sounds are generally complex, multi-overtoned, and imperfectly shaped, it's
' necessary to smooth out those irregularities or odd shapes (such as sqaure,
' triangle, and sawtooth) so that pitch can still be accurately determined.
' For that, high inertial resistance can applied to smooth out the uneven
' spots, so even a harsh square wave will induce a roughly sine wave movement
' in the membrane. Oddly, the sine waves seem much softer than other less
' perfect sounds, such as square and sawtooth waves.
'
' I've noticed that the stronger the resitance is, the finer the tuning is,
' but the slower it takes to respond to changes in the waveform. Weak
' resistances allow wider ranges through, but respond more quickly to changes.
'
'-Variables-
' stiffness - determines tension rate and natural frequency
' mass - determines resistance and frequency response rate
' tension - pull back towards the membrane's center from stiffness
' resistance - resistance to change in velocity because of mass
' velocity - membrane 's speed and direction of oscillation
' level - membrane 's distance from center
'
'-Formulas-
' I'm not completely sure if these are all in the right order. They may need
' to be shuffled around.
'
' membrane level += membrane velocity
' wave velocity = wave level - previous wave level
' membrane velocity += (wave velocity - membrane velocity) * resistance%
' membrane velocity -= membrane level * tension%
'
' -Progress-
' So far tension (stiffness) can be simulated to create near perfect sine
' wave oscillation.
' Mass is not yet simulated.
' Damping is not yet simulated.
'
DEFINT A-Z
DECLARE SUB SimulateBsm (Bsm AS ANY)
DECLARE SUB SimulateWave (Bsm AS ANY)
DECLARE SUB ImportSpc ()
DECLARE SUB ExpandSample (SampleNumber%)

TYPE BasMemSimType
Level   AS DOUBLE
Vel     AS DOUBLE
VelMod  AS INTEGER
Tension AS INTEGER
Resist  AS INTEGER
WaveLvl AS INTEGER
WavePvl AS INTEGER
END TYPE

TYPE BasMemWindowType
WavePos   AS INTEGER
TopRow    AS INTEGER
CenterRow AS INTEGER
LeftCol   AS INTEGER
ColWidth  AS INTEGER
RowHeight AS INTEGER
END TYPE

CONST BsmViewCenter = 160, BsmViewTop = 100, BsmViewBtm = 149
CONST WaveViewCenter = 50, WaveViewTop = 0, WaveViewBtm = 99, WaveViewLeft = 0, WaveViewWidth = 320
CONST SampleBufferSize = 16000

DIM SHARED BasMemSimMode, WaveFormMode, WaveCycleLength, WaveCycleAmplitude, TotalVelDif, SampleBufferLength
DIM SHARED ErrorHandled
DIM SHARED SampleBuffer(SampleBufferSize - 1), SpcRam(16383) AS LONG, SampleBufferPos, PrevSampleHeight
DIM SHARED BrrSampleBase  AS LONG, BrrSampleLength, BrrSampleNumber, SampleTableBase&
DIM SHARED BsmRecord(100, 2) AS DOUBLE

DIM Bsm AS BasMemSimType, BasMemWnd AS BasMemWindowType
DIM BsmLevel AS DOUBLE, LastBsmLvl AS DOUBLE, CrestLevel AS DOUBLE, TrouphLevel AS DOUBLE, TotalLevel AS DOUBLE
DIM SimCount AS LONG, PeakCount AS LONG, PeakCycle AS LONG, PeakAmplitude AS LONG, PeakTotal AS DOUBLE
DIM WaveViewPos, WaveViewScale
DIM PreBsmViewColumn, PreWaveViewRow
DIM EditModeNames(2) AS STRING, EditModeHistory(2)

EditModeNames(0) = "Waveform"
EditModeNames(1) = "Simulate"
EditModeNames(2) = "Membrane"

GOSUB SetScreenMode
GOSUB InitBsmSim

PreBsmViewColumn = -1
SampleBufferLength = SampleBufferSize
EditModeChange = 3
FOR Count = 0 TO UBOUND(EditModeHistory)
    HistoryList(Count) = Count
NEXT Count
DO
    GOSUB AdvanceBsmSim

    key$ = INKEY$
    SELECT CASE key$
    CASE ""
        IF EditModeChange THEN
            IF EditModeChange <= 1 THEN
                Count = 0: GOSUB DisplayEditMode
            ELSE
                FOR Count = 0 TO UBOUND(EditModeHistory)
                    GOSUB DisplayEditMode
                NEXT Count
            END IF
            EditModeChange = 0
        END IF
    CASE CHR$(0) + "K", "/": EditModeAdjust = 0: Count = -1: GOSUB EditModeValue
    CASE CHR$(0) + "M", "*": EditModeAdjust = 0: Count = 1: GOSUB EditModeValue
    CASE CHR$(0) + "s": EditModeAdjust = 0: Count = -16: GOSUB EditModeValue
    CASE CHR$(0) + "t": EditModeAdjust = 0: Count = 16: GOSUB EditModeValue
    CASE CHR$(0) + "P", "-": EditModeAdjust = 1: Count = -1: GOSUB EditModeValue
    CASE CHR$(0) + "H", "+": EditModeAdjust = 1: Count = 1: GOSUB EditModeValue
    CASE CHR$(0) + "Q": EditModeAdjust = 1: Count = -16: GOSUB EditModeValue
    CASE CHR$(0) + "I": EditModeAdjust = 1: Count = 16: GOSUB EditModeValue
    CASE "1" TO "9": EditModeAdjust = 2: Count = ASC(key$) - 49: GOSUB EditModeValue
    CASE CHR$(13): Bsm.Level = BsmLevel: Bsm.Vel = 0
    CASE " "
        LOCATE 25, 35
        IF SimActive THEN PRINT "Paused";  ELSE PRINT "Active";
        SimActive = SimActive XOR 1
    CASE "i"
        CLS : LINE INPUT "Filename:", UserInput$
        GOSUB OpenImportFile
    CASE "d"
        CLS : PRINT "Previous sample:"; BrrSampleNumber
        LINE INPUT "DSP Sample number:", UserInput$
        IF LEN(UserInput$) THEN
            Sample = VAL(UserInput$)
            IF Sample >= 0 AND Sample <= 255 THEN
                PRINT "Expanding sample..."
                CALL ExpandSample(Sample)
                IF BrrSampleBase > 0 THEN
                    PRINT "Expanded"; BrrSampleNumber; "to"; BrrSampleLength; "samples from"; BrrSampleBase
                    SampleBufferLength = BrrSampleLength
                    DO: LOOP UNTIL LEN(INKEY$)
                ELSE
                    PRINT "No more samples"
                END IF
            ELSE
                PRINT "Sample must be 0-255"
            END IF
            SampleBufferPos = 0
        END IF
    CASE ""
        SampleBufferPos = 0
    CASE ".": Bsm.Tension = Bsm.Tension + 1
    CASE ",": Bsm.Tension = Bsm.Tension - 1
    CASE "w": NewEditMode = 0: GOSUB ChangeEditMode
    CASE "s": NewEditMode = 1: GOSUB ChangeEditMode
    CASE "m": NewEditMode = 2: GOSUB ChangeEditMode
    CASE CHR$(27): EXIT DO
    END SELECT
LOOP

END

ChangeEditMode:
    EditMode = NewEditMode
    EditModeChange = 3
    'update history list
    FOR Count = 0 TO UBOUND(EditModeHistory)
        IF HistoryList(Count) = NewEditMode GOTO ShiftEditModes
    NEXT Count
    Count = UBOUND(HistoryList) - 2
ShiftEditModes:
    FOR Count = Count TO 1 STEP -1
        HistoryList(Count) = HistoryList(Count - 1)
    NEXT Count
    HistoryList(0) = NewEditMode
RETURN

DisplayEditMode:
    NewEditMode = HistoryList(Count)
    LOCATE 21 + Count, 1
    IF Count = 0 THEN COLOR 15 ELSE COLOR 3
    PRINT EditModeNames(NewEditMode); " ";
    SELECT CASE NewEditMode
    CASE 0: PRINT STR$(WaveFormMode + 1) + "/6="; MID$("Sine  SquareSampleSilentSaw   Spike", 6 * WaveFormMode + 1, 6); WaveCycleLength; WaveCycleAmplitude;
    CASE 1: PRINT STR$(BasMemSimMode + 1) + "/3="; MID$("ComplexSimple Scan", 7 * BasMemSimMode + 1, 7); Bsm.Tension; Bsm.Resist;
    CASE 2: PRINT BsmLevel; INT(Bsm.Vel);
    END SELECT
    PRINT TAB(33);
RETURN

EditModeValue:
    SELECT CASE EditMode
    CASE 0
        IF EditModeAdjust = 0 THEN
            WaveCycleLength = WaveCycleLength + Count
        ELSEIF EditModeAdjust = 1 THEN
            WaveCycleAmplitude = WaveCycleAmplitude + Count
        ELSEIF Count < 6 THEN
            WaveFormMode = Count
        END IF
    CASE 1
        IF EditModeAdjust = 0 THEN
            Bsm.Tension = Bsm.Tension + Count
        ELSEIF EditModeAdjust = 1 THEN
            Bsm.Resist = Bsm.Resist + Count
            'WaveViewScale = WaveViewScale + Count
            'IF WaveViewScale < 1 THEN WaveViewScale = 1
        ELSEIF Count < 3 THEN
            BasMemSimMode = Count
        END IF
    CASE 2
        IF EditModeAdjust = 0 THEN
            BsmLevel = INT(BsmLevel + Count): Bsm.Level = BsmLevel: Bsm.Vel = 0
        ELSEIF EditModeAdjust = 1 THEN
            Bsm.Vel = Bsm.Vel + Count
        END IF
    END SELECT
    EditModeChange = 1
RETURN

InitBsmSim:
    BasMemWnd.WavePos = 0
    BasMemWnd.TopRow = 49
    BasMemWnd.CenterRow = 160
    BasMemWnd.LeftCol = 0
    BasMemWnd.ColWidth = 320
    BasMemWnd.RowHeight = 100
    BsmLevel = 20
    Bsm.Level = BsmLevel
    Bsm.Vel = 0
    Bsm.Resist = 100' 1000 allows very accurate tuning
    Bsm.Tension = 5'162=80;10=20
    WaveCycleLength = 10
    WaveCycleAmplitude = 20
    WaveFormMode = 1
    PreBsmViewColumn = BsmViewCenter
    'PreWaveViewRow = WaveViewCenter
    WaveViewScale = 1
    SimActive = 1
RETURN

AdvanceBsmSim:
    'WaveHeight = SampleBuffer(SampleBufferPos)
    IF SimActive THEN
        CALL SimulateWave(Bsm)
        CALL SimulateBsm(Bsm)
    END IF
    BsmViewColumn = BsmViewCenter + Bsm.Level
    IF PreBsmViewColumn <> BsmViewColumn THEN
        LINE (PreBsmViewColumn, BsmViewTop)-(PreBsmViewColumn, BsmViewBtm), 0
        LINE (BsmViewColumn, BsmViewTop)-(BsmViewColumn, BsmViewBtm), 15
    END IF
    PreBsmViewColumn = BsmViewColumn

    IF Bsm.Level < TrouphLevel THEN TrouphLevel = Bsm.Level
    IF Bsm.Level > CrestLevel THEN CrestLevel = Bsm.Level
    IF LastBsmLvl < 0 AND Bsm.Level >= 0 THEN
        PeakCycle = SimCount - PeakCount
        PeakCount = SimCount
        PeakAmplitude = CrestLevel - TrouphLevel
        PeakTotal = TotalLevel
        CrestLevel = 0
        TrouphLevel = 0
        TotalLevel = 0
    END IF
    LastBsmLvl = Bsm.Level
    TotalLevel = TotalLevel + ABS(Bsm.Level)
    
    LOCATE 25, 1: COLOR 15: PRINT INT(Bsm.Level); TAB(7); INT(Bsm.Vel); TAB(13); PeakCycle; TAB(19); PeakAmplitude; TAB(25); INT(PeakTotal);
   
    IF SimActive = 0 THEN RETURN
    SimCount = SimCount + 1
    WaveViewColumn = WaveViewPos + WaveViewLeft
   
    SELECT CASE BasMemSimMode
    CASE 2
        FOR Count = 0 TO UBOUND(BsmRecord)
            PixClr = BsmRecord(Count, 0) * 3 AND 127
            PSET (WaveViewColumn, WaveViewTop + Count), PixClr + 128
        NEXT Count
    CASE ELSE
        WaveViewRow = Bsm.Level \ WaveViewScale + WaveViewCenter
        LINE (WaveViewColumn, WaveViewTop)-(WaveViewColumn, WaveViewBtm), 0
        'LINE (WaveViewColumn, PreWaveViewRow)-(WaveViewColumn, WaveViewRow), 15
        IF WaveViewRow < WaveViewTop THEN WaveViewRow = WaveViewTop ELSE IF WaveViewRow > WaveViewBtm THEN WaveViewRow = WaveViewBtm
        LINE (WaveViewColumn, WaveViewCenter)-(WaveViewColumn, Bsm.WaveLvl \ WaveViewScale + WaveViewCenter), 1
        LINE (WaveViewColumn, WaveViewCenter)-(WaveViewColumn, WaveViewRow), (Bsm.Level AND 127) + 128
        PSET (WaveViewColumn, WaveViewRow), 15
        'PreWaveViewRow = WaveViewRow
    END SELECT
    WaveViewPos = (WaveViewPos + 1) MOD WaveViewWidth

    RETURN
    IF Bsm.Level < 0 THEN
        PhaseTime = 0
    ELSE
        PhaseTime = PhaseTime + 1
        IF PhaseTime > PeakPhaseTime THEN PeakPhaseTime = PhaseTime
    END IF
    WaveLevel = WaveLevel + ABS(Bsm.Level)
    MonitorCounter = MonitorCounter + 1
    IF MonitorCounter > 200 THEN
        PRINT ">"; CrestLevel; "<"; TrouphLevel; "^"; PeakPhaseTime; TAB(38);
        LOCATE 24, 1: PRINT "+-"; WaveCycleLength; "="; WaveLevel; "!="; WaveResistLevel;
        WaveLevel = 0
        WaveResistLevel = 0
        CrestLevel = 0
        TrouphLevel = 0
        MonitorCounter = 0
        PeakPhaseTime = 0
    END IF
RETURN

OpenImportFile:
    IF LEN(UserInput$) THEN
        ON ERROR GOTO ErrorHandler: ErrorHandled = 0
        OPEN UserInput$ FOR INPUT AS 1: CLOSE 1
        ON ERROR GOTO 0
        IF ErrorHandled = 0 THEN
            OPEN UserInput$ FOR BINARY AS 1
            IF UCASE$(LEFT$(RIGHT$(UserInput$, 4), 3)) = ".SP" THEN
                PRINT "Importing SPC...";
                CALL ImportSpc
                PRINT "Done"
            ELSE
                PRINT "Unrecognized filetype"
            END IF
            CLOSE 1
        ELSE
            PRINT "Open error"
        END IF
    END IF
RETURN

SetScreenMode:
    SCREEN 13
    OUT &H3C8, 128
    FOR Count = 0 TO 127
        OUT &H3C9, INT(COS(Count / 20.37185) * 31) + 32
        OUT &H3C9, INT(COS((Count + 43) / 20.37185) * 31) + 32
        OUT &H3C9, INT(COS((Count + 85) / 20.37185) * 31) + 32
    NEXT Count
RETURN

ErrorHandler:
    ErrorHandled = ERR
RESUME NEXT

SUB ExpandSample (SampleNumber)
    DIM BytePos AS LONG
    DIM ShiftTable(15)

    Shift = 1
    FOR Count = 0 TO 12
        ShiftTable(Count) = Shift \ 256
        Shift = Shift * 2
    NEXT Count

    'Check that sample in table is valid
    'If it has a value of -1, starts in direct page RAM, or starts in the
    'ROM, then it is considered invalid. Other possible verifications could
    'include checking that each sample at least x samples long, and that each
    'sample contains valid BRR ranges (that the shift is not >12).
    BrrSampleBase = (SampleTableBase& \ 4 + SampleNumber) AND 16383
    BrrSampleNumber = SampleNumber
    BrrSampleLength = 0
    DO
        BytePos = SpcRam(BrrSampleBase) AND 65535
        IF BytePos >= 256 AND BytePos < 65472 THEN EXIT DO
        BrrSampleBase = BrrSampleBase + 1
        BrrSampleNumber = BrrSampleNumber + 1
        IF BrrSampleNumber >= 256 THEN
            BrrSampleBase = -1
            EXIT SUB
        END IF
    LOOP
    BrrSampleBase = BytePos

    DEF SEG = VARSEG(SpcRam(0))
    FOR Count = 0 TO SampleBufferSize - 1 STEP 16
        IF Header AND 1 THEN
            FOR SubCount = Count TO SampleBufferSize - 1
                SampleBuffer(SubCount) = 0
            NEXT SubCount
            EXIT FOR
        END IF
        Header = PEEK(BytePos)
        Shift = ShiftTable((Header AND 240) \ 16)
        BytePos = BytePos + 1
        FOR SubCount = Count TO Count + 15 STEP 2
            Byte = PEEK(BytePos)
            IF Byte AND 128 THEN Sample = (Byte AND -16) OR -256 ELSE Sample = Byte AND 112
            SampleBuffer(SubCount) = (Sample \ 16) * Shift
            IF Byte AND 8 THEN Sample = Byte OR -16 ELSE Sample = Byte AND 15
            SampleBuffer(SubCount + 1) = Sample * Shift
            BytePos = BytePos + 1
        NEXT SubCount
        BrrSampleLength = BrrSampleLength + 16
    NEXT Count
END SUB

SUB ImportSpc
    DIM FileData AS STRING * 32

    'SEEK 1, &H101
    'FOR Count = 0 TO 16383
    '    GET 1, , SpcRam(Count)
    'NEXT Count

    SEEK 1, &H101
    FOR Count = 0 TO 16383 STEP 8
        GET 1, , FileData
        FOR SubCount = 0 TO 7
            SpcRam(Count + SubCount) = CVL(MID$(FileData, SubCount * 4 + 1, 4))
        NEXT SubCount
    NEXT Count

    GET 1, &H1015D, SampleTableBase&
    SampleTableBase& = SampleTableBase& AND 65280
END SUB

SUB SimulateBsm (Bsm AS BasMemSimType)

DIM WaveVel AS DOUBLE, BsmVel AS DOUBLE, BsmLevel AS DOUBLE

SELECT CASE BasMemSimMode
CASE 0
    Bsm.Level = Bsm.Level + Bsm.Vel

    'Quadrupling the tension doubles the frequency
    ' 20=28 30=34 40=40 50=44 60=49 70=53 80=56 160=79 640=159
    'Accell f=x  40=20  160=40  360=60  640=80  1020=100

    'Bsm.InMod = (Bsm.Level + Bsm.InMod) MOD Bsm.Tension
    'Bsm.Vel = Bsm.Vel - (Bsm.Level + Bsm.InMod) \ Bsm.Tension

    WaveVel = Bsm.WaveLvl - Bsm.WavePvl: Bsm.WavePvl = Bsm.WaveLvl
    'TotalVelDif = TotalVelDif + ABS(Bsm.Vel - WaveVel)
    Bsm.Vel = Bsm.Vel + (WaveVel - Bsm.Vel) / Bsm.Resist
    Bsm.Vel = Bsm.Vel - Bsm.Level / Bsm.Tension
    'Bsm.Level = Bsm.Level + Bsm.Vel

CASE 1
    Bsm.Level = Bsm.Level + Bsm.Vel
    IF Bsm.Level < 0 THEN
        Bsm.Vel = Bsm.Vel + 1
    ELSE
        Bsm.Vel = Bsm.Vel - 1
    END IF

CASE 2
    WaveVel = Bsm.WaveLvl - Bsm.WavePvl: : Bsm.WavePvl = Bsm.WaveLvl
    FOR Count = 0 TO UBOUND(BsmRecord)
        BsmLevel = BsmRecord(Count, 0)
        BsmVel = BsmRecord(Count, 1)

        BsmLevel = BsmLevel + BsmVel
        BsmVel = BsmVel + (WaveVel - BsmVel) / Bsm.Resist
        BsmVel = BsmVel - BsmLevel / (Count + 1)
       
        BsmRecord(Count, 0) = BsmLevel
        BsmRecord(Count, 1) = BsmVel
    NEXT Count
END SELECT

END SUB

SUB SimulateWave (Bsm AS BasMemSimType)

STATIC WaveLvl, Phase

SELECT CASE WaveFormMode
CASE 0 'Sine
    Bsm.WaveLvl = COS(Phase / WaveCycleLength * 6.28318) * WaveCycleAmplitude
    IF Phase <= 0 THEN Phase = WaveCycleLength
    Phase = Phase - 1

CASE 1 'Square
    IF Phase < WaveCycleLength \ 2 THEN
        Bsm.WaveLvl = WaveCycleAmplitude
        IF Phase = 0 THEN Phase = WaveCycleLength
    ELSE
        Bsm.WaveLvl = -WaveCycleAmplitude
    END IF
    Phase = Phase - 1

CASE 2 'Sample from wave buffer
    Bsm.WaveLvl = SampleBuffer(SampleBufferPos)
    SampleBufferPos = SampleBufferPos + 1
    IF SampleBufferPos >= SampleBufferLength THEN SampleBufferPos = 0

CASE 3 'Silence, for testing response time and vibration halflife
    Bsm.WaveLvl = 0

CASE 4
    IF Phase <= 0 THEN Phase = Phase + WaveCycleLength * 2
    Bsm.WaveLvl = -WaveCycleAmplitude + Phase * WaveCycleAmplitude / WaveCycleLength
    Phase = Phase - 2
   
CASE 5
    IF Phase <= 0 THEN
        Bsm.WaveLvl = -WaveCycleAmplitude
        Phase = WaveCycleLength
    ELSEIF Phase = 1 THEN
        Bsm.WaveLvl = WaveCycleAmplitude
    ELSE
        Bsm.WaveLvl = 0
    END IF
    Phase = Phase - 1
END SELECT

END SUB

