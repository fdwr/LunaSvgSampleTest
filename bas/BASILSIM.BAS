DEFINT A-Z
DECLARE SUB SimulateBasilMem ()
DECLARE SUB SimulateBasilMem2 (BasMemSim AS ANY)
DECLARE SUB ImportSpc ()
DECLARE SUB ExpandSample (SampleNumber%)

TYPE BasMemSimType
Level    AS DOUBLE
Inertia  AS DOUBLE
InMod    AS INTEGER
Accel    AS INTEGER
Resist   AS INTEGER
WavePos  AS INTEGER
WaveVal  AS INTEGER
END TYPE

TYPE BasMemWindowType
WavePos   AS INTEGER
TopRow    AS INTEGER
CenterRow AS INTEGER
LeftCol   AS INTEGER
ColWidth  AS INTEGER
RowHeight AS INTEGER
END TYPE

CONST BasilMemViewCenter = 160, BasilMemViewTop = 100, BasilMemViewBtm = 149
CONST WaveViewCenter = 50, WaveViewTop = 0, WaveViewBtm = 99, WaveViewLeft = 0, WaveViewWidth = 320
CONST SampleBufferSize = 8192

DIM BasMemSim AS BasMemSimType, BasMemWnd AS BasMemWindowType
DIM SHARED BasilMemLevel AS DOUBLE, BasilMemInertia AS DOUBLE, BasilMemMod, ResonanceLevel, BasMemSimMode
DIM SHARED SimCount AS LONG, PeakCount AS LONG, PeakDif
DIM SHARED WaveViewPos, WaveViewScale, WaveCycleLength, WaveResistLevel
DIM SHARED ErrorHandled
DIM PreBasilMemViewColumn, PreWaveViewRow
DIM SHARED SampleBuffer(SampleBufferSize - 1), SpcRam(16383) AS LONG, SampleBufferPos, SampleTableBase&, PrevSampleHeight
DIM SHARED BrrSampleBase, BrrSampleLength, BrrSampleNumber

GOSUB SetScreenMode
GOSUB InitBasilMemSim

DO
    GOSUB AdvanceBasilMemSim

    key$ = UCASE$(INKEY$)
    SELECT CASE key$
    CASE CHR$(27): EXIT DO
    CASE CHR$(0) + "K": BasMemSimLevel = INT(BasMemSimLevel - 1): BasMemSim.Level = BasMemSimLevel: BasMemSim.Inertia = 0
    CASE CHR$(0) + "M": BasMemSimLevel = INT(BasMemSimLevel + 1): BasMemSim.Level = BasMemSimLevel: BasMemSim.Inertia = 0
    CASE CHR$(0) + "S": BasMemSimLevel = BasMemSimLevel - 16: BasMemSim.Level = BasMemSimLevel: BasMemSim.Inertia = 0
    CASE CHR$(0) + "T": BasMemSimLevel = BasMemSimLevel + 16: BasMemSim.Level = BasMemSimLevel: BasMemSim.Inertia = 0
    CASE CHR$(0) + "H": IF WaveViewScale > 1 THEN WaveViewScale = WaveViewScale - 1
    CASE CHR$(0) + "P": WaveViewScale = WaveViewScale + 1
    CASE " "
        LOCATE 25, 20
        IF SimActive THEN PRINT "Paused";  ELSE PRINT "Active"; : BasilMemInertia = 0
        SimActive = SimActive XOR 1
    CASE "I"
        CLS : LINE INPUT "Filename:", UserInput$
        GOSUB OpenImportFile
    CASE "D"
        CLS : PRINT "Previous sample:"; BrrSampleNumber
        LINE INPUT "DSP Sample number:", UserInput$
        IF LEN(UserInput$) THEN
            Sample = VAL(UserInput$)
            IF Sample >= 0 AND Sample <= 255 THEN
                PRINT "Expanding sample..."
                CALL ExpandSample(Sample)
                IF BrrSampleBase > 0 THEN
                    PRINT "Expanded"; BrrSampleNumber; "to"; BrrSampleLength; "samples from"; BrrSampleBase
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
    CASE "1" TO "2"
        BasMemSimMode = ASC(key$) - 49
    CASE "+": WaveCycleLength = WaveCycleLength + 1
    CASE "-": WaveCycleLength = WaveCycleLength - 1
    END SELECT
LOOP

END

InitBasilMemSim:
    BasMemWnd.WavePos = 0
    BasMemWnd.TopRow = 49
    BasMemWnd.CenterRow = 160
    BasMemWnd.LeftCol = 0
    BasMemWnd.ColWidth = 320
    BasMemWnd.RowHeight = 100
    BasMemSim.Level = 0
    BasMemSim.Inertia = 20
    BasMemSim.Resist = 20
    WaveCycleLength = 10

    PreBasilMemViewColumn = BasilMemViewCenter
    PreWaveViewRow = WaveViewCenter
    WaveViewScale = 5
    ResonanceLevel = 100
    SimActive = 1
RETURN

AdvanceBasilMemSim:
    WaveHeight = SampleBuffer(SampleBufferPos)
    IF SimActive THEN CALL SimulateBasilMem2(BasMemSim)
    'BarColor = 192 + BasilMemLevel \ 2
    BasilMemViewColumn = BasilMemViewCenter + BasMemSim.Level
    IF PreBasilMemViewColumn <> BasilMemViewColumn THEN
        LINE (PreBasilMemViewColumn, BasilMemViewTop)-(PreBasilMemViewColumn, BasilMemViewBtm), 0
    END IF
    LINE (BasilMemViewColumn, BasilMemViewTop)-(BasilMemViewColumn, BasilMemViewBtm), 15
    PreBasilMemViewColumn = BasilMemViewColumn
    LOCATE 25, 1: PRINT LEFT$(STR$(INT(BasMemSim.Level)) + "   ", 5);

    IF SimActive = 0 THEN RETURN
    SimCount = SimCount + 1
    WaveViewColumn = WaveViewPos + WaveViewLeft
    WaveViewRow = BasMemSim.Level \ WaveViewScale + WaveViewCenter
    LINE (WaveViewColumn, WaveViewTop)-(WaveViewColumn, WaveViewBtm), 0
    'LINE (WaveViewColumn, PreWaveViewRow)-(WaveViewColumn, WaveViewRow), 15
    IF WaveViewRow < WaveViewTop THEN WaveViewRow = WaveViewTop ELSE IF WaveViewRow > WaveViewBtm THEN WaveViewRow = WaveViewBtm
    LINE (WaveViewColumn, WaveViewCenter)-(WaveViewColumn, WaveViewRow), 9
    PSET (WaveViewColumn, WaveViewRow), 15
    PreWaveViewRow = WaveViewRow
    WaveViewPos = (WaveViewPos + 1) MOD WaveViewWidth

    IF BasMemSim.Level < TrouphLevel THEN TrouphLevel = BasMemSim.Level
    IF BasMemSim.Level > CrestLevel THEN CrestLevel = BasMemSim.Level
    IF BasMemSim.Level < 0 THEN
        PhaseTime = 0
    ELSE
        PhaseTime = PhaseTime + 1
        IF PhaseTime > PeakPhaseTime THEN PeakPhaseTime = PhaseTime
    END IF
    WaveLevel = WaveLevel + ABS(BasMemSim.Level)
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

SUB SimulateBasilMem
    'BasilMemLevel = ((BasilMemLevel + 51) MOD 100) - 50
    PreBasilMemLevel = BasilMemLevel: PreBasilMemInertia = BasilMemInertia
    SampleDif = SampleBuffer(SampleBufferPos)' - PrevSampleHeight
    'PrevSampleHeight = SampleBuffer(SampleBufferPos)
    BasilMemLevel = BasilMemLevel + BasilMemInertia' - SampleDif
    BasilMemInertia = (BasilMemInertia - BasilMemLevel / ResonanceLevel + SampleDif) * .95
    SampleBufferPos = SampleBufferPos + 1 AND SampleBufferSize - 1
    ' * .999
    IF SGN(BasilMemLevel) <> SGN(PreBasilMemLevel) THEN
        IF BasilMemLevel < PreBasilMemLevel THEN
            PeakDif = SimCount - PeakCount
            PeakCount = SimCount
            LOCATE 24, 1: PRINT PeakDif; "  ";
        END IF
    END IF
    'BasilMemIntertia = BasilMemInertia - (BasilMemLevel)
    'BasilMemInertia = BasilMemInertia - (BasilMemLevel + BasilMemMod) \ ResonanceLevel
    'BasilMemMod = BasilMemLevel MOD ResonanceLevel
END SUB

SUB SimulateBasilMem2 (BasMemSim AS BasMemSimType)

STATIC WaveCycles, WaveVal

SELECT CASE BasMemSimMode
CASE 1
    BasMemSim.Level = BasMemSim.Level + BasMemSim.Inertia
    IF BasMemSim.Level < 0 THEN
        BasMemSim.Inertia = BasMemSim.Inertia + 1
    ELSE
        BasMemSim.Inertia = BasMemSim.Inertia - 1
    END IF
CASE 0
    BasMemSim.Level = BasMemSim.Level + BasMemSim.Inertia
    BasMemSim.Accel = 80

    'Quadrupling the accelerator doubles the frequency
    'Accell f=x  40=20  160=40  360=60  640=80  1020=100
    'Accell x=f  2=5  4=7  8=9  16=13  32=18  64=25  128=35  256=50  512=71  1024=100  2048=142  4096=201

    'BasMemSim.InMod = (BasMemSim.Level + BasMemSim.InMod) MOD BasMemSim.Accel
    'BasMemSim.Inertia = BasMemSim.Inertia - (BasMemSim.Level + BasMemSim.InMod) \ BasMemSim.Accel

    WaveCycles = WaveCycles + 1
    IF WaveCycles > WaveCycleLength THEN
        IF WaveVal = 100 THEN WaveVal = -100 ELSE WaveVal = 100
        WaveCycles = 0
    END IF
    WaveInertia = WaveVal - BasMemSim.WaveVal
    WaveResistLevel = WaveResistLevel + ABS(BasMemSim.Inertia - WaveInertia)
    BasMemSim.Inertia = BasMemSim.Inertia - (BasMemSim.Inertia - WaveInertia) / BasMemSim.Resist
    BasMemSim.WaveVal = WaveVal
    BasMemSim.Inertia = BasMemSim.Inertia - BasMemSim.Level / BasMemSim.Accel

END SELECT

END SUB

