'WaveFreq.bas by Peekin
'2000-03-13/2000-09-05
'http://FDwR.tripod.com/snes.htm
'FDwR@hotmail.com
'
'Test program to search through a sound sample and find the perceived pitch,
'in other words, the dominant frequency. Unfortunately it does not identify
'it correctly.
'
'Can generate sine or square waves,
'Import from wave files or SPC samples.
'
'Wave playing functions used from DMA Play By Mike Huff (1996)
'  http://www.ocf.berkeley.edu/~horie
'
DEFINT A-Z
DECLARE SUB DisplaySampleBuffer (BaseIndex, StartingIndex, EndingIndex)
DECLARE SUB GenerateSineWave (CycleWidth#, Amplitude)
DECLARE SUB GenerateSquareWave (WaveLength#, Amplitude)
DECLARE SUB GenerateSpikeWave (CycleWidth#, Amplitude)
DECLARE SUB GenerateSawtoothWave (WaveLength AS DOUBLE, Amplitude%)
DECLARE SUB ClearSampleBuffer ()
DECLARE SUB FindWaveRepeatPoints ()
DECLARE SUB TallyWaveResonance (StartingIndex)
DECLARE SUB TallyCycleScores ()
DECLARE SUB SingleWaveResonance (StartingIndex%)
DECLARE SUB DisplayFreqScores (StartingIndex%, EndingIndex%)
DECLARE SUB ShowCycleDifferences ()
DECLARE SUB KeyOptionPrint (Text$, HighlightText$)
DECLARE SUB ExportWave (FileName$)
DECLARE SUB ImportWave ()
DECLARE SUB ImportSpc ()
DECLARE SUB ExpandSample (SampleNumber%)
DECLARE SUB PlaySample (Replay)
DECLARE SUB DisplayOverlayWave ()
DECLARE FUNCTION CyclePeakTotal& (WaveLength)
DECLARE SUB TallyCyclePeakTotals ()
DECLARE FUNCTION WaveLengthLowest% ()
DECLARE FUNCTION WaveLengthHighest% ()

DECLARE FUNCTION ResetDSP% ()
DECLARE SUB WriteDSP (Byte)
DECLARE SUB GetBLASTER (DMA%, BasePort%, IRQ%)
DECLARE FUNCTION ReadDSP% ()
DECLARE SUB DMAPlay (Segment&, offset&, Length&, Freq&)


TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
Bp AS INTEGER: Si AS INTEGER: Di AS INTEGER: Fl AS INTEGER
Ds AS INTEGER: Es AS INTEGER
END TYPE

CONST SampleBufferSize = 16000, MaxCycleWidth = 320, DefaultDownScaling = 200
CONST DefaultPlayFreq = 11025
DIM SHARED BasePort, LenPort, AdrPort, Channel, DspVersion, PlayFreq AS LONG, Regs AS RegType
DIM SHARED SampleBuffer(SampleBufferSize + SampleBufferSize - 1), WavePlayBuffer(SampleBufferSize - 1), WaveBufferSeg AS LONG
DIM SHARED CycleScoreTable(-1 TO MaxCycleWidth - 1) AS LONG, OldScores(MaxCycleWidth - 1) AS LONG
DIM SHARED Left(MaxCycleWidth - 1) AS LONG, Right(MaxCycleWidth - 1) AS LONG
DIM SHARED SampleTableBase&, BrrSampleNumber, BrrSampleBase AS LONG, BrrSampleLength AS LONG
DIM SHARED SamplePos, CurWaveLength, HighestCycleScore AS LONG, CurDownScaling AS LONG, ErrorHandled
DIM SHARED FreqScoreDisplayMode, SampleDisplayMode, WaveResonanceDisplayMode, CyclePeakTotalMode, CycleScoreMode
REDIM SHARED SpcRam(16383) AS LONG

CurWaveLength = 16
StepSize = 16
CurDownScaling = DefaultDownScaling
PlayFreq = DefaultPlayFreq

GOSUB Init

GOSUB DisplayMainMenuChoices
IF LEN(COMMAND$) THEN
    UserInput$ = COMMAND$
    GOSUB OpenImportFile
END IF

DO
    KeyPress$ = INKEY$
    SELECT CASE KeyPress$
    CASE "s", "q", "k", "t"
        LINE INPUT "Cycles width (in samples):", UserInput$
        IF LEN(UserInput$) THEN
            CycleWidth# = VAL(UserInput$)
            CurWaveLength = INT(CycleWidth#)
            LINE INPUT "Amplitude (sample height):", UserInput$
            IF LEN(UserInput$) THEN
                CycleHeight = VAL(UserInput$)
                IF CycleHeight = 0 THEN CycleHeight = 32
                IF KeyPress$ = "s" THEN
                    PRINT "Generating sine wave...";
                    CALL GenerateSineWave(CycleWidth#, CycleHeight)
                ELSEIF KeyPress$ = "q" THEN
                    PRINT "Generating square wave...";
                    CALL GenerateSquareWave(CycleWidth#, CycleHeight)
                ELSEIF KeyPress$ = "t" THEN
                    PRINT "Generating sawtooth wave...";
                    CALL GenerateSawtoothWave(CycleWidth#, CycleHeight)
                ELSE
                    PRINT "Generating spike wave...";
                    CALL GenerateSpikeWave(CycleWidth#, CycleHeight)
                END IF
                PRINT "Done"
            END IF
        END IF
    CASE "v"
        GOSUB ViewSoundSampleBuffer
        GOSUB DisplayMainMenuChoices
    CASE "c"
        CALL ClearSampleBuffer
        PRINT "Sample buffer cleared"
    CASE "a"
        CLS
        CALL KeyOptionPrint("Simulate basilar membrane", "1")
        CALL KeyOptionPrint("Find repeat points", "2")
        CALL KeyOptionPrint("Compare sliding windows", "3")
        CALL KeyOptionPrint("Add phase totals", "4")
        CALL KeyOptionPrint("Add phase range totals", "5")
        CALL KeyOptionPrint("Add adjusting phase totals", "6")
        DO
            KeyPress$ = INKEY$
            SELECT CASE KeyPress$
            CASE "1" TO "6"
                CycleScoreMode = ASC(KeyPress$) - 49
                GOTO RepeatTallyScores
            CASE CHR$(27): EXIT DO
            END SELECT
        LOOP
        GOSUB DisplayMainMenuChoices
    CASE "r"
RepeatTallyScores:
        CurDownScaling = DefaultDownScaling
        CLS
        CALL TallyCycleScores
        GOSUB ViewFreqScores
        GOSUB DisplayMainMenuChoices
    CASE "f"
        CLS
        GOSUB ViewFreqScores
        GOSUB DisplayMainMenuChoices
    CASE "e"
        PRINT "Exporting wave...";
        CALL ExportWave("wavefreq.wav")
        PRINT "Done"
    CASE "i"
        LINE INPUT "Filename:", UserInput$
        GOSUB OpenImportFile
    CASE "d", "n"
        IF KeyPress$ = "n" THEN
            Sample = BrrSampleNumber + 1
            GOTO ExpandSampleNow
        END IF
        PRINT "Previous sample:"; BrrSampleNumber
        LINE INPUT "DSP Sample number:", UserInput$
        IF LEN(UserInput$) THEN
            Sample = VAL(UserInput$)
            IF Sample >= 0 AND Sample <= 255 THEN
ExpandSampleNow:
                PRINT "Expanding sample"; Sample
                CALL ExpandSample(Sample)
                IF BrrSampleBase > 0 THEN PRINT "Expanded"; BrrSampleLength; "samples from"; BrrSampleBase
            ELSE
                PRINT "Sample must be 0-255"
            END IF
        END IF
    CASE "w"
        GOSUB ViewWaves
        GOSUB DisplayMainMenuChoices
    CASE "y"
        LINE INPUT "Wave frequency:", UserInput$
        'IF VAL(UserInput$) >= 8000 THEN
        IF VAL(UserInput$) >= 3900 THEN
            PlayFreq = VAL(UserInput$)
            PRINT "Frequency set to"; PlayFreq
        END IF
    CASE "p", "P": PlaySample KeyPress$ = "P": PRINT
    CASE "I"
        GOSUB ShowWaveInfo
    CASE CHR$(27): EXIT DO
    END SELECT
LOOP
IF DspVersion > 0 THEN WriteDSP &HD3 'speaker off
CLS
END

DisplayMainMenuChoices:
    CLS
    CALL KeyOptionPrint("Generate sine wave (merges)", "s")
    CALL KeyOptionPrint("Generate square wave", "q")
    CALL KeyOptionPrint("Generate saw tooth", "t")
    CALL KeyOptionPrint("View sound sample buffer", "v")
    CALL KeyOptionPrint("Clear sound sample buffer", "c")
    PRINT
    CALL KeyOptionPrint("Analyze frequencies", "a")
    CALL KeyOptionPrint("Repeat last analysis", "r")
    CALL KeyOptionPrint("View frequency scores", "f")
    CALL KeyOptionPrint("View wave ocean", "w")
    PRINT
    CALL KeyOptionPrint("Import from wave file or SPC", "i")
    CALL KeyOptionPrint("Export to wave file (wavefreq.wav)", "e")
    CALL KeyOptionPrint("Expand DSP sample", "d")
    CALL KeyOptionPrint("Next DSP sample", "n")
    CALL KeyOptionPrint("Play wave", "p")
    CALL KeyOptionPrint("Set play rate (in hertz)", "y")
    CALL KeyOptionPrint("Wave Info", "I")
    PRINT
RETURN

ViewFreqScores:
    'CLS
    IF CurWaveLength <= 0 THEN CurWaveLength = WaveLengthLowest
    GOSUB DisplayAllFreqs
    DO
        KeyPress$ = INKEY$
        SELECT CASE KeyPress$
        CASE CHR$(0) + "K": NewWaveLength = CurWaveLength - 1: GOSUB ChangeCycleWidth
        CASE CHR$(0) + "M": NewWaveLength = CurWaveLength + 1: GOSUB ChangeCycleWidth
        CASE CHR$(0) + "s": NewWaveLength = CurWaveLength - StepSize: GOSUB ChangeCycleWidth
        CASE CHR$(0) + "t": NewWaveLength = CurWaveLength + StepSize: GOSUB ChangeCycleWidth
        CASE "-": IF StepSize > 10 THEN StepSize = StepSize - 1: GOSUB DisplayWaveLength
        CASE "+": IF StepSize < 319 THEN StepSize = StepSize + 1: GOSUB DisplayWaveLength
        CASE CHR$(0) + "H": IF CurDownScaling > 20 THEN CurDownScaling = CurDownScaling * .9: GOSUB DisplayAllFreqs
        CASE CHR$(0) + "P": IF CurDownScaling < 100000 THEN CurDownScaling = CurDownScaling * 1.1: GOSUB DisplayAllFreqs
        CASE CHR$(0) + "G": NewWaveLength = 0: GOSUB ChangeCycleWidth
        CASE CHR$(0) + "O": NewWaveLength = MaxCycleWidth - 1: GOSUB ChangeCycleWidth
        CASE "1" TO "3"
            FreqScoreDisplayMode = ASC(KeyPress$) - 49
            CALL DisplayFreqScores(0, 319)
        CASE "1": CALL DisplayOverlayWave
        CASE CHR$(0) + "S": NewWaveLength = WaveLengthLowest: GOSUB ChangeCycleWidth
        CASE CHR$(0) + "R": NewWaveLength = WaveLengthHighest: GOSUB ChangeCycleWidth
        CASE CHR$(27): EXIT DO
        END SELECT
    LOOP
RETURN

DisplayAllFreqs:
    CALL DisplayFreqScores(0, 319)
    GOTO DisplayCycleWidth
ChangeCycleWidth:
    NewWaveLength = (NewWaveLength + MaxCycleWidth) MOD MaxCycleWidth
    SWAP NewWaveLength, CurWaveLength
    CALL DisplayFreqScores(CurWaveLength, CurWaveLength)
    CALL DisplayFreqScores(NewWaveLength, NewWaveLength)
DisplayCycleWidth:
    LOCATE 25, 1: PRINT "Cycle width:"; CurWaveLength; "="; CycleScoreTable(CurWaveLength); TAB(30);
RETURN

ViewSoundSampleBuffer:
    GOSUB DisplayBufferPage
    DO
        KeyPress$ = INKEY$
        SELECT CASE KeyPress$
        CASE CHR$(0) + "K": NewSamplePos = SamplePos - 1: GOSUB ChangeBufferPos
        CASE CHR$(0) + "M": NewSamplePos = SamplePos + 1: GOSUB ChangeBufferPos
        CASE CHR$(0) + "H": SampleBuffer(SamplePos) = SampleBuffer(SamplePos) - 256: GOSUB DisplayBufferPage
        CASE CHR$(0) + "P": SampleBuffer(SamplePos) = SampleBuffer(SamplePos) + 256: GOSUB DisplayBufferPage
        CASE CHR$(0) + "s": NewSamplePos = SamplePos - CurWaveLength: GOSUB ChangeBufferPos
        CASE CHR$(0) + "t": NewSamplePos = SamplePos + CurWaveLength: GOSUB ChangeBufferPos
        CASE "-": IF CurWaveLength > 1 THEN CurWaveLength = CurWaveLength - 1: GOSUB ChangeWaveLength
        CASE "+": IF CurWaveLength < 319 THEN CurWaveLength = CurWaveLength + 1: GOSUB ChangeWaveLength
        CASE CHR$(0) + "I": NewSamplePos = SampleBase - 256: GOSUB ChangeBufferPage
        CASE CHR$(0) + "Q": NewSamplePos = SampleBase + 256: GOSUB ChangeBufferPage
        CASE CHR$(0) + "R"
            FOR Count = UBOUND(SampleBuffer) TO SamplePos + 1 STEP -1
                SampleBuffer(Count) = SampleBuffer(Count - 1)
            NEXT
            GOSUB DisplayBufferPage
        CASE CHR$(0) + "S"
            FOR Count = SamplePos TO UBOUND(SampleBuffer) - 1
                SampleBuffer(Count) = SampleBuffer(Count + 1)
            NEXT
            GOSUB DisplayBufferPage
        CASE CHR$(0) + "G"
            IF SamplePos = SampleBase THEN
                NewSamplePos = 0: GOSUB ChangeBufferPage
            ELSE
                NewSamplePos = SampleBase: GOSUB ChangeBufferPos
            END IF
        CASE CHR$(0) + "O"
            IF SamplePos = SampleBase + 255 THEN
                NewSamplePos = SampleBufferSize - 256: GOSUB ChangeBufferPage
            ELSE
                NewSamplePos = SampleBase + 255: GOSUB ChangeBufferPos
            END IF
        CASE "1" TO "5"
            SampleDisplayMode = ASC(KeyPress$) - 49
            GOSUB DisplayBufferPage
        CASE "9"
            CyclePeakTotalMode = (CyclePeakTotalMode + 1) MOD 5
            LOCATE 1, 1: PRINT "Peak total mode:"; CyclePeakTotalMode; TAB(40);
        CASE "0"
            'LOCATE 1, 1: PRINT CurWaveLength; "="; CyclePeakTotal(CurWaveLength); "using mode"; CyclePeakTotalMode; TAB(40);
            'CyclePeakTotalMode = 3
            LOCATE 1, 1: PRINT CurWaveLength; "="; CyclePeakTotal(CurWaveLength); ":";
            'CyclePeakTotalMode = 4
            'PRINT CyclePeakTotal(CurWaveLength); TAB(40);
        CASE " ": SampleBase = SamplePos: GOSUB DisplayBufferPage
        CASE "p", "P"
            LOCATE 25, 1
            PlaySample KeyPress$ = "P"
            GOSUB DisplaySamplePos
        CASE "n"
            Sample = BrrSampleNumber + 1
            CALL ExpandSample(Sample)
            GOSUB DisplayBufferPage
        CASE "e"
            CALL ExportWave("wavefreq.wav")
        CASE CHR$(27): EXIT DO
        END SELECT
    LOOP
RETURN

ChangeBufferPage:
    NewSamplePos = (NewSamplePos + SampleBufferSize) MOD SampleBufferSize
    SamplePos = (SamplePos - SampleBase + NewSamplePos + SampleBufferSize) MOD SampleBufferSize
    SampleBase = NewSamplePos
DisplayBufferPage:
    CALL DisplaySampleBuffer(SampleBase, SampleBase, SampleBase + 319)
    GOTO DisplaySamplePos

ChangeBufferPos:
    NewSamplePos = (NewSamplePos + SampleBufferSize) MOD SampleBufferSize
    SWAP NewSamplePos, SamplePos
    CALL DisplaySampleBuffer(SampleBase, SamplePos, SamplePos)
    CALL DisplaySampleBuffer(SampleBase, NewSamplePos, NewSamplePos)
DisplaySamplePos:
    LOCATE 25, 1: PRINT "Buffer Sample:"; SamplePos; SamplePos - SampleBase; "="; SampleBuffer(SamplePos); TAB(40);
    DO: LOOP WHILE LEN(INKEY$)
RETURN

ChangeWaveLength:
    IF SampleDisplayMode >= 1 THEN GOSUB DisplayBufferPage
DisplayWaveLength:
    LOCATE 25, 1: PRINT "Step size:"; CurWaveLength; TAB(40);
RETURN

ViewWaves:
    GOSUB ResetFreqScores
    CurDownScaling = 10
    DO
        KeyPress$ = INKEY$
        SELECT CASE KeyPress$
        CASE CHR$(0) + "K": NewWaveLength = CurWaveLength - 1: GOSUB ChangeCycleWidth2
        CASE CHR$(0) + "M": NewWaveLength = CurWaveLength + 1: GOSUB ChangeCycleWidth2
        CASE CHR$(0) + "s": NewWaveLength = CurWaveLength - 16: GOSUB ChangeCycleWidth2
        CASE CHR$(0) + "t": NewWaveLength = CurWaveLength + 16: GOSUB ChangeCycleWidth2
        CASE CHR$(0) + "G": NewWaveLength = 0: GOSUB ChangeCycleWidth2
        CASE CHR$(0) + "O": NewWaveLength = MaxCycleWidth - 1: GOSUB ChangeCycleWidth2
        CASE CHR$(0) + "S": CurWaveLength = WaveLengthLowest
        CASE CHR$(0) + "R": CurWaveLength = WaveLengthHighest
        CASE "1" TO "4": WaveResonanceDisplayMode = ASC(KeyPress$) - 49
        CASE CHR$(8): GOSUB ResetFreqScores
        CASE CHR$(27): EXIT DO
        END SELECT

        CALL TallyWaveResonance(Count)
        GOSUB DisplayCycleWidth
        IF Count >= SampleBufferSize - MaxCycleWidth - 1 THEN
            GOSUB ResetFreqScores
        ELSE
            Count = Count + 1
        END IF
    LOOP
RETURN

ResetFreqScores:
    FOR Count = 0 TO MaxCycleWidth - 1
        CycleScoreTable(Count) = 0
    NEXT Count
    Count = 0
RETURN

ChangeCycleWidth2:
    NewWaveLength = (NewWaveLength + MaxCycleWidth) MOD MaxCycleWidth
    SWAP NewWaveLength, CurWaveLength
RETURN

ShowWaveInfo:
    'CLS
    PRINT "DMA ="; Channel
    PRINT "Port = "; HEX$(BasePort)
    PRINT "IRQ ="; IRQ
    PRINT "DSP version ="; DspVersion
    PRINT "Frequency ="; PlayFreq
RETURN

OpenImportFile:
    IF LEN(UserInput$) THEN
        ON ERROR GOTO ErrorHandler: ErrorHandled = 0
        OPEN UserInput$ FOR INPUT AS 1: CLOSE 1
        ON ERROR GOTO 0
        IF ErrorHandled = 0 THEN
            OPEN UserInput$ FOR BINARY AS 1
            IF UCASE$(RIGHT$(UserInput$, 4)) = ".WAV" THEN
                PRINT "Importing wave...";
                CALL ImportWave
                PRINT "Press V to view waveform"
                SampleBase = 0: SamplePos = 0
            ELSEIF UCASE$(LEFT$(RIGHT$(UserInput$, 4), 3)) = ".SP" THEN
                PRINT "Importing SPC..."
                CALL ImportSpc
                PRINT "Press D to select DSP sample"
            ELSE
                PRINT "Unrecognized filetype"
            END IF
            CLOSE 1
        ELSE
            PRINT "Open error"
        END IF
    END IF
RETURN

Init:
    'set screen mode and rainbow colored palette
    SCREEN 13
    PRINT "Setting screen"
    OUT &H3C8, 128
    FOR Count = 0 TO 127
        OUT &H3C9, INT(COS(Count / 20.37185) * 31) + 32
        OUT &H3C9, INT(COS((Count + 43) / 20.37185) * 31) + 32
        OUT &H3C9, INT(COS((Count + 85) / 20.37185) * 31) + 32
    NEXT Count

    PRINT "Resetting sound card"
    GetBLASTER Channel, BasePort, IRQ
    IF BasePort > 100 THEN
        Count = ResetDSP
        IF DspVersion > 0 THEN
            WriteDSP &HD1'speaker on
            WaveBufferSeg = VARSEG(WavePlayBuffer(0)) * 16& + VARPTR(WavePlayBuffer(0))
            IF (WaveBufferSeg AND 65535) + SampleBufferSize > 65536 THEN
                WaveBufferSeg = (WaveBufferSeg + 65536) AND -65536
            END IF
            WaveBufferSeg = WaveBufferSeg \ 16
        END IF
    END IF
RETURN

ErrorHandler:
    ErrorHandled = ERR
RESUME NEXT

SUB ClearSampleBuffer
    FOR Count = 0 TO SampleBufferSize - 1 STEP 2
        SampleBuffer(Count) = 0
        SampleBuffer(Count + 1) = 0
    NEXT Count
END SUB

FUNCTION CyclePeakTotal& (WaveLength)
    DIM CrestValue AS LONG, TrouphValue AS LONG, TotalValue AS LONG

    FOR Phase = 0 TO WaveLength
        Left(Phase) = 0
    NEXT Phase
   
    Phase = 0: TotalValue = 0
    SELECT CASE CyclePeakTotalMode
    CASE 0'Peak addition
        FOR Count = 0 TO SampleBufferSize - 1
            Left(Phase) = Left(Phase) + SampleBuffer(Count)
            Phase = Phase + 1
            IF Phase >= WaveLength THEN Phase = 0
        NEXT Count
        FOR Phase = 0 TO WaveLength - 1
            TotalValue = TotalValue + ABS(Left(Phase))
        NEXT Phase
    CASE 1'Peak range addition
        Index = -WaveLength * 4
        FOR Count = 0 TO SampleBufferSize - 1
            Value = Left(Phase)
            IF Index >= 0 THEN Value = Value - SampleBuffer(Index)
            Value = Value + SampleBuffer(Count)
            Left(Phase) = Value
            TotalValue = TotalValue + ABS(Value)
            Phase = Phase + 1: IF Phase >= WaveLength THEN Phase = 0
            Index = Index + 1
        NEXT Count
    CASE 2'Adjusting peak addition
        CrestValue = 0: TrouphValue = 0
        PhaseCrest = WaveLength \ 2
        PhaseTrouph = WaveLength + PhaseCrest   'wavlen + (wavlen \ 2)
        PhaseWrap = WaveLength + WaveLength     'wavlen * 2
        FOR Count = 0 TO SampleBufferSize - 1
            Value = SampleBuffer(Count)
            IF Value > 0 THEN
                IF Phase < WaveLength THEN
                    CrestValue = CrestValue + Value
                    Phase = Phase + 2
                ELSE 'Phase >= WaveLength
                    IF Phase < PhaseTrouph THEN
                        Phase = Phase + 1
                    ELSE 'Phase >= PhaseTrouph
                        Phase = Phase + 3
                    END IF
                END IF
            ELSEIF Value < 0 THEN
                IF Phase >= WaveLength THEN
                    TrouphValue = TrouphValue + Value
                    Phase = Phase + 2
                ELSE 'Phase < WaveLength
                    IF Phase < PhaseCrest THEN
                        Phase = Phase + 1
                    ELSE 'Phase >= PhaseCrest
                        Phase = Phase + 3
                    END IF
                END IF
            ELSE 'Value=0
                Phase = Phase + 2
            END IF
            'if positive/negative
            'if left/right
            'if ahead/behind
            IF Phase >= PhaseWrap THEN Phase = Phase - PhaseWrap
        NEXT Count
        TotalValue = CrestValue - TrouphValue
    CASE 3'Absolute peak addition, for determining amplitude of a range
        FOR Count = SamplePos TO SamplePos + CurWaveLength - 1
            'TotalValue = TotalValue + ABS(SampleBuffer(Count AND SampleBufferSize - 1))
        NEXT Count
    CASE 4'Peak fluctuation, for determining variance of a range
        FOR Count = SamplePos TO SamplePos + CurWaveLength - 1
            'TotalValue = TotalValue + ABS(SampleBuffer(Count AND SampleBufferSize - 1) - SampleBuffer(Count + 1 AND SampleBufferSize - 1))
        NEXT Count
    END SELECT

    CyclePeakTotal = TotalValue
END FUNCTION

SUB DisplayFreqScores (StartingIndex, EndingIndex)
    SELECT CASE FreqScoreDisplayMode
    CASE 0
        'Histogram
        FOR WaveLength = StartingIndex TO EndingIndex
            IF WaveLength = CurWaveLength THEN
                LineColor = 15
                BackColor = 7
            ELSE
                LineColor = (WaveLength AND 127) + 128
                BackColor = 0
            END IF
            'IF WaveLength = 0 THEN WaveLength = WaveLength + 1
            'Sample& = 191 - (CycleScoreTable(WaveLength) + CycleScoreTable(WaveLength - 1)) \ CurDownScaling
            'Sample& = 100 - (CycleScoreTable(WaveLength) - CycleScoreTable(WaveLength - 1)) \ 50
            Sample& = 191 - CycleScoreTable(WaveLength) \ CurDownScaling
            IF Sample& < 0 THEN Row = 0 ELSE Row = Sample&
            LINE (WaveLength, 0)-(WaveLength, Row), BackColor
            LINE (WaveLength, Row + 1)-(WaveLength, 191), LineColor
        NEXT WaveLength
    CASE 1
        'Average histogram
        IF EndingIndex >= 319 THEN EndingIndex = 318
        FOR WaveLength = StartingIndex TO EndingIndex
            IF WaveLength = CurWaveLength THEN
                LineColor = 15
                BackColor = 7
            ELSE
                LineColor = (WaveLength AND 127) + 128
                BackColor = 0
            END IF
            Sample& = 191 - (CycleScoreTable(WaveLength) + CycleScoreTable(WaveLength + 1)) \ CurDownScaling \ 2
            IF Sample& < 0 THEN Row = 0 ELSE Row = Sample&
            LINE (WaveLength, 0)-(WaveLength, Row), BackColor
            LINE (WaveLength, Row + 1)-(WaveLength, 191), LineColor
        NEXT WaveLength
    CASE 2
        'Vertical color bars
        FOR WaveLength = StartingIndex TO EndingIndex
            IF WaveLength = CurWaveLength THEN
                LineColor = 15
            ELSE
                LineColor = CycleScoreTable(WaveLength) \ CurDownScaling + 128
                IF LineColor > 255 THEN LineColor = 255
            END IF
            LINE (WaveLength, 0)-(WaveLength, 191), LineColor
        NEXT WaveLength
    END SELECT
END SUB

SUB DisplayOverlayWave
    CosRatio# = WaveLength / 6.283186#
    IF CosRatio# < .1 THEN CosRatio# = 1

    LastRow = 100
    FOR Count = 0 TO 319
        Row = INT(COS(CSNG(Count / CosRatio#)) * 30) + 100
        LINE (Count, LastRow)-(Count, Row), 15
        LastRow = Row
    NEXT Count
END SUB

SUB DisplaySampleBuffer (BaseIndex, StartingIndex, EndingIndex)

    CurIndex = StartingIndex
    LastIndex = EndingIndex
    IF EndingIndex >= SampleBufferSize THEN
        LastIndex = SampleBufferSize - 1
        LINE (SampleBufferSize - BaseIndex, 0)-(319, 191), 0, BF
    END IF

    SELECT CASE SampleDisplayMode
    CASE 0
        FOR Count = StartingIndex - BaseIndex TO LastIndex - BaseIndex
            IF CurIndex = SamplePos THEN LineColor = 15: BackColor = 7 ELSE LineColor = ((SampleBuffer(CurIndex) AND 32512) \ 256) + 128: BackColor = 0
            LINE (Count, 0)-(Count, 191), BackColor
            Value = SampleBuffer(CurIndex) \ 256 + 100
            IF offset >= 0 THEN
                LINE (Count, 100)-(Count, Value), LineColor
            ELSE
                LINE (Count, 99)-(Count, Value), LineColor
            END IF
            CurIndex = CurIndex + 1
        NEXT Count
    CASE 1
        IF CurIndex > 0 THEN
            PreValue = SampleBuffer(CurIndex - 1) \ 256
        ELSE
            PreValue = SampleBuffer(CurIndex) \ 256
        END IF
        FOR Count = (StartingIndex - BaseIndex) * 4 TO (LastIndex - BaseIndex) * 4 STEP 4
            Value = SampleBuffer(CurIndex) \ 256
            IF CurIndex = SamplePos THEN LineColor = 15: BackColor = 7 ELSE LineColor = (SampleBuffer(CurIndex) AND 127) + 128: BackColor = 0
            LINE (Count, 0)-(Count + 3, 191), BackColor, BF
            IF SampleBuffer(CurIndex) >= 0 THEN
                'LINE (Count, 100)-(Count, Value + ((PreValue - Value) * 3 + 3) \ 4 + 100), LineColor
                LINE (Count + 1, 100)-(Count + 1, (Value + PreValue) \ 2 + 100), LineColor
                'LINE (Count + 2, 100)-(Count + 2, Value - (Value - PreValue + 3) \ 4 + 100), LineColor
                LINE (Count + 3, 100)-(Count + 3, Value + 100), LineColor
            ELSE
                'LINE (Count, 99)-(Count, Value + ((PreValue - Value) * 3 + 3) \ 4 + 100), LineColor
                LINE (Count + 1, 99)-(Count + 1, (Value + PreValue) \ 2 + 100), LineColor
                'LINE (Count + 2, 99)-(Count + 2, Value - (Value - PreValue + 3) \ 4 + 100), LineColor
                LINE (Count + 3, 99)-(Count + 3, Value + 100), LineColor
            END IF
            PreValue = Value
            CurIndex = CurIndex + 1
        NEXT Count
    CASE 2
        'TotalValue& = 0
        FOR Count = StartingIndex - BaseIndex TO LastIndex - BaseIndex
            IF CurWaveLength + CurIndex > SampleBufferSize THEN
                Value = SampleBuffer(CurIndex)
            ELSE
                Value = SampleBuffer(CurIndex) + SampleBuffer(CurIndex + CurWaveLength)
            END IF
            IF CurIndex = SamplePos THEN LineColor = 15: BackColor = 7 ELSE LineColor = (SampleBuffer(CurIndex) AND 127) + 128: BackColor = 0
            LINE (Count, 0)-(Count, 191), BackColor
            IF Value >= 0 THEN
                LINE (Count, 100)-(Count, Value + 100), LineColor
            ELSE
                LINE (Count, 99)-(Count, Value + 100), LineColor
            END IF
            'TotalValue& = TotalValue& + ABS(Value)
            CurIndex = CurIndex + 1
        NEXT Count
    CASE 3
        CosRatio# = CurWaveLength / 6.283186#
        IF CosRatio# < .1 THEN CosRatio# = 1
        FOR Count = StartingIndex - BaseIndex TO LastIndex - BaseIndex
            Value = SampleBuffer(CurIndex) + INT(COS(CSNG(Count / CosRatio#)) * 30)
            IF CurIndex = SamplePos THEN LineColor = 15: BackColor = 7 ELSE LineColor = (SampleBuffer(CurIndex) AND 127) + 128: BackColor = 0
            LINE (Count, 0)-(Count, 191), BackColor
            IF Value >= 0 THEN
                LINE (Count, 100)-(Count, Value + 100), LineColor
            ELSE
                LINE (Count, 99)-(Count, Value + 100), LineColor
            END IF
            'TotalValue& = TotalValue& + ABS(Value)
            CurIndex = CurIndex + 1
        NEXT Count
    CASE 4
        TotalValue& = 0
        TotalValue2& = 0
        FOR Count = StartingIndex - BaseIndex TO LastIndex - BaseIndex
            Index = BaseIndex - Count + CurWaveLength * 2 - 1
            IF CurIndex = SamplePos THEN BackColor = 7 ELSE BackColor = 0
            LINE (Count, 0)-(Count, 191), BackColor
            Value = SampleBuffer(CurIndex)
            PSET (Count, 100 + Value), 12
            IF Index >= 0 THEN
                PSET (Count, 100 + SampleBuffer(Index)), 9
                Value = SampleBuffer(Index) + Value
                PSET (Count, 100 + Value), 15
                TotalValue& = TotalValue& + ABS(Value)
                TotalValue2& = TotalValue2& + Value
            END IF
            CurIndex = CurIndex + 1
        NEXT Count
        LINE (CurWaveLength, 0)-(CurWaveLength, 191), 1
    END SELECT
    'LOCATE 1, 1: PRINT TotalValue&; TotalValue2&;
END SUB

SUB DMAPlay (Segment&, offset&, Length&, Freq&)
' Transfers and plays the contents of the buffer.
Length& = Length& - 1
MemLoc& = Segment& * 16 + offset&
SELECT CASE Channel%
    CASE 0
       PgPort = &H87
       AdrPort = &H0
    CASE 1
       PgPort = &H83
       AdrPort = &H2
    CASE 2
       PgPort = &H81
       AdrPort = &H4
    CASE 3
       PgPort = &H82
       AdrPort = &H6
    CASE ELSE
       PRINT "DMA channels 0-3 only are supported."
       EXIT SUB
END SELECT

LenPort = AdrPort + 1
OUT &HA, &H4 OR Channel%    'disable channel for programming
OUT &HC, &H0                'clear flip-flop
OUT &HB, &H48 OR Channel%   'set mode
OUT AdrPort, MemLoc& AND &HFF
OUT AdrPort, (MemLoc& AND &HFF00&) \ &H100
OUT LenPort, Length& AND &HFF
OUT LenPort, (Length& AND &HFF00&) \ &H100
Page% = (MemLoc& AND 983040) \ 65536
OUT PgPort%, Page%
OUT &HA, Channel%           'enable channel for transfer

IF Freq& <= 32000 THEN
   TimeConst% = 256 - 1000000 \ Freq&
   WriteDSP &H40
   WriteDSP TimeConst%
   WriteDSP &H14
   WriteDSP Length& AND &HFF
   WriteDSP ((Length& AND &HFF00&) \ &H100)
ELSE
   IF DspVersion >= 300 THEN
      TimeConst% = ((65536 - 256000000 \ Freq&) AND &HFF00&) \ &H100
      WriteDSP &H40
      WriteDSP TimeConst%
      WriteDSP Length& AND &HFF
      WriteDSP ((Length& AND &HFF00&) \ &H100)
      WriteDSP &H91
   ELSE
      PRINT "You need a Sound Blaster with a DSP v3.x+ to play at high speed."
      EXIT SUB
   END IF
END IF
END SUB

SUB ExpandSample (SampleNumber)
    DIM BytePos AS LONG
    DIM ShiftTable(15)

    Shift = 1
    FOR Count = 0 TO 12
        ShiftTable(Count) = Shift
        Shift = Shift * 2
    NEXT Count

    'Check that sample in table is valid
    'If it has a value of -1, starts in direct page RAM, or starts in the
    'ROM, then it is considered invalid. Other possible verifications could
    'include checking that each sample at least x samples long, and that each
    'sample contains valid BRR ranges (that the shift is not >12).
    BrrSampleIdx = (SampleTableBase& \ 4 + SampleNumber) AND 16383
    BrrSampleNumber = SampleNumber
    BrrSampleLength = 0
    DO
        BytePos = SpcRam(BrrSampleIdx) AND 65535
        IF BytePos >= 256 AND BytePos < 65472 THEN EXIT DO
        BrrSampleIdx = BrrSampleIdx + 1
        BrrSampleNumber = BrrSampleNumber + 1
        IF BrrSampleNumber >= 256 THEN
            PRINT "No more samples"
            BrrSampleBase = -1
            EXIT SUB
        END IF
    LOOP
    BrrSampleBase = BytePos

    IF BrrSampleNumber <> SampleNumber THEN
        PRINT "Next available sample:"; BrrSampleNumber
    END IF

    DEF SEG = VARSEG(SpcRam(0))
    FOR Count = 0 TO SampleBufferSize - 1 STEP 16
        IF Header AND 1 THEN
            IF Header AND 2 THEN
                BytePos = ((SpcRam(BrrSampleIdx) AND -65536) \ 65536) AND 65535
                IF BytePos < 256 OR BytePos >= 65472 THEN GOTO SilenceRemainingBuffer
            ELSE
SilenceRemainingBuffer:
                FOR SubCount = Count TO SampleBufferSize - 1
                    SampleBuffer(SubCount) = 0
                NEXT SubCount
                EXIT FOR
            END IF
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

SUB ExportWave (FileName AS STRING)
    DIM FileData AS STRING * 16

    OPEN FileName FOR OUTPUT AS 1
    PRINT #1, "RIFF"; MKL$(4 + 24 + 8 + SampleBufferSize);
    PRINT #1, "WAVEfmt "; MKL$(16); MKI$(1); MKI$(1); MKL$(PlayFreq); MKL$(PlayFreq); MKI$(1); MKI$(8);
    '00h  fId               4   Contains the characters "fmt"
    '04h  fLen              4   Length of data in the format chunk
    '08h  wFormatTag        2   *
    '0Ah  nChannels         2   Number of channels, 1=mono, 2=stereo
    '0Ch  nSamplesPerSec    4   Playback frequency
    '10h  nAvgBytesPerSec   4   **
    '14h  nBlockAlign       2   ***
    '16h  FormatSpecific    2   Format specific data area
    PRINT #1, "data"; MKL$(SampleBufferSize);
    FOR Count = 0 TO SampleBufferSize - 1 STEP 16
        FOR SubCount = 0 TO 15
            MID$(FileData, SubCount + 1) = CHR$((SampleBuffer(Count + SubCount) + 32768) \ 256)
        NEXT SubCount
        PRINT #1, FileData;
    NEXT Count
    CLOSE 1
END SUB

SUB GenerateSawtoothWave (WaveLength AS DOUBLE, Amplitude)
    DIM Phase AS DOUBLE
    Phase = WaveLength * 2
    FOR Count = 0 TO SampleBufferSize - 1
        IF Phase <= 0 THEN Phase = Phase + WaveLength * 2
        SampleBuffer(Count) = SampleBuffer(Count) - Amplitude + Phase * Amplitude / WaveLength
        Phase = Phase - 2
    NEXT Count
END SUB

'WaveLength - Whole number indicating how far apart (in samples) each
'   crest/trouph should be spaced
SUB GenerateSineWave (WaveLength AS DOUBLE, Amplitude)
    Ratio# = WaveLength / 6.283186#
    IF Ratio# < .1 THEN Ratio# = 1

    FOR Count = 0 TO SampleBufferSize - 1
        SampleBuffer(Count) = SampleBuffer(Count) + (SIN(CSNG(Count / Ratio#)) * Amplitude)
    NEXT Count
END SUB

SUB GenerateSpikeWave (WaveLength AS DOUBLE, Amplitude)
    DIM Phase AS DOUBLE
    Phase = WaveLength
    FOR Count = 0 TO SampleBufferSize - 1
        Phase = Phase - 1
        IF Phase <= 0 THEN
            Value = -Amplitude
            Phase = Phase + WaveLength
        ELSEIF Phase <= 1 THEN
            Value = Amplitude
        ELSE
            Value = 0
        END IF
        SampleBuffer(Count) = SampleBuffer(Count) + Value
    NEXT Count
END SUB

SUB GenerateSquareWave (WaveLength AS DOUBLE, Amplitude)
    DIM HalfCycleWidth AS DOUBLE
    HalfCycleWidth = WaveLength / 2
    FOR Count = 0 TO SampleBufferSize - 1
        IF INT(Count / HalfCycleWidth) AND 1 THEN Sample = -Amplitude ELSE Sample = Amplitude
        SampleBuffer(Count) = SampleBuffer(Count) + Sample
    NEXT Count
END SUB

' This subroutine parses the BLASTER environment string and returns settings.
SUB GetBLASTER (DMA, BasePort, IRQ)
    Text$ = ENVIRON$("BLASTER")
    IF LEN(Text$) = 0 THEN PRINT "BLASTER environment variable not set.": EXIT SUB
    FOR Length = 1 TO LEN(Text$)
        SELECT CASE MID$(Text$, Length, 1)
        CASE "A": BasePort = VAL("&H0" + MID$(Text$, Length + 1, 3))
        CASE "I": IRQ = VAL(MID$(Text$, Length + 1, 1))
        CASE "D": DMA = VAL(MID$(Text$, Length + 1, 1))
        END SELECT
    NEXT
END SUB

'Import RAM from an SPC
'File handle is understood to be one
'
SUB ImportSpc
    'DIM FileData AS STRING * 32

    'SEEK 1, &H101
    'FOR Count = 0 TO 16383
    '    GET 1, , SpcRam(Count)
    'NEXT Count

    SEEK 1, &H101
    'FOR Count = 0 TO 16383 STEP 8
    '    GET 1, , FileData
    '    FOR SubCount = 0 TO 7
    '        SpcRam(Count + SubCount) = CVL(MID$(FileData, SubCount * 4 + 1, 4))
    '    NEXT SubCount
    'NEXT Count

    SEEK 1, &H101
    Regs.Bx = FILEATTR(1, 2)
    Regs.Cx = 8192
    Regs.Ds = VARSEG(SpcRam(0))
    FOR Count = 0 TO 16383 STEP 2048
        Regs.Ax = &H3F00 'DOS function: read from file
        Regs.Dx = VARPTR(SpcRam(Count))
        CALL interruptx(&H21, Regs, Regs)
    NEXT Count

    GET 1, &H1015D, SampleTableBase&
    SampleTableBase& = SampleTableBase& AND 65280
END SUB

'Imports 8/16-bit, mono/stereo waves
'File handle is understood to be one
'Chunks must come in the order RIFF/WAVE/fmt
'Intervening chunks between the format and data are skipped
'
SUB ImportWave
    DIM FileData AS STRING * 32
    DIM ChunkId AS STRING * 4
    DIM FileEnd AS LONG
    DIM ChunkLength AS LONG
    WaveLoaded = 0

    GET 1, , ChunkId
    IF ChunkId = "RIFF" THEN
        GET 1, , FileEnd
        GET 1, , ChunkId
        FileEnd = FileEnd + 8
        IF ChunkId = "WAVE" THEN
            GET 1, , ChunkId
            IF ChunkId = "fmt " THEN
                GET 1, , ChunkLength
                HeaderOffset = SEEK(1)
                GET 1, HeaderOffset + 2, Channels
                GET 1, HeaderOffset + 14, SampleBits
                SEEK 1, HeaderOffset + ChunkLength
                DO UNTIL SEEK(1) > FileEnd
                    GET 1, , ChunkId
                    GET 1, , ChunkLength
                    IF ChunkId = "data" THEN EXIT DO
                    SEEK 1, SEEK(1) + ChunkLength
                LOOP
                IF ChunkId = "data" THEN
                    IF SampleBits = 8 THEN
                        IF Channels = 1 THEN
                            FOR Count = 0 TO SampleBufferSize - 1 STEP 32
                                GET 1, , FileData
                                FOR SubCount = 0 TO 31
                                    SampleBuffer(Count + SubCount) = ASC(MID$(FileData, SubCount + 1, 1)) * 256& - 32768
                                NEXT SubCount
                            NEXT Count
                        ELSE
                            FOR Count = 0 TO SampleBufferSize - 1 STEP 16
                                GET 1, , FileData
                                FOR SubCount = 0 TO 15
                                    SampleBuffer(Count + SubCount) = ASC(MID$(FileData, SubCount * 2 + 1, 1)) * 256& - 32768
                                NEXT SubCount
                            NEXT Count
                        END IF
                        WaveLoaded = 1
                    ELSEIF SampleBits = 16 THEN
                        IF Channels = 1 THEN
                            FOR Count = 0 TO SampleBufferSize - 1 STEP 16
                                GET 1, , FileData
                                FOR SubCount = 0 TO 15
                                    SampleBuffer(Count + SubCount) = CVI(MID$(FileData, SubCount * 2 + 1, 2))
                                NEXT SubCount
                            NEXT Count
                        ELSE
                            FOR Count = 0 TO SampleBufferSize - 1 STEP 8
                                GET 1, , FileData
                                FOR SubCount = 0 TO 7
                                    SampleBuffer(Count + SubCount) = CVI(MID$(FileData, SubCount * 4 + 1, 2))
                                NEXT SubCount
                            NEXT Count
                        END IF
                        WaveLoaded = 1
                    END IF
                    FOR Count = SampleBufferSize - 1 TO 0 STEP -1
                        IF SampleBuffer(Count) <> -32768 THEN EXIT FOR
                        SampleBuffer(Count) = 0
                    NEXT Count
                END IF
            END IF
        END IF
    END IF
    IF WaveLoaded THEN PRINT "Loaded" ELSE PRINT "Error in file"
END SUB

SUB KeyOptionPrint (Text$, HighlightText$)
    HighlightPos = INSTR(Text$, HighlightText$)
    IF HighlightPos = 0 THEN HighlightPos = 1
    COLOR 15: PRINT HighlightText$ + " ";
    COLOR 3: PRINT LEFT$(Text$, HighlightPos - 1);
    COLOR 9: PRINT MID$(Text$, HighlightPos, 1);
    COLOR 3: PRINT MID$(Text$, HighlightPos + 1)
END SUB

SUB PlaySample (Replay)

DIM Adr AS LONG, PrevAdr AS LONG

IF DspVersion <= 0 THEN EXIT SUB
PRINT "Playing sound,";

'copy 16bit sample buffer to 8bit sound buffer for playing
IF NOT Replay THEN
    DEF SEG = WaveBufferSeg
    'BytePos = VARPTR(WavePlayBuffer(0))
    FOR Count = 0 TO SampleBufferSize - 1
        POKE Count, SampleBuffer(Count) \ 256 + 128
    NEXT Count
END IF

'WriteDSP &HD1 'speaker on
DMAPlay WaveBufferSeg, 0, BrrSampleLength, PlayFreq
DO: LOOP UNTIL LEN(INKEY$) OR ((INP(LenPort) + 1) * CLNG(INP(LenPort) + 1) - 1) >= &HFFFF&
'DO: PRINT (NOT (INP(LenPort) + INP(LenPort) * 256&)) AND &HFFFF&: LOOP UNTIL LEN(INKEY$)
'DO: PRINT INP(AdrPort) + INP(AdrPort) * 256&: SLEEP: LOOP UNTIL LEN(INKEY$)
OUT &HA, &H4 + Channel     'disable DMA channel
'Acknowledge the DSP interrupt by reading the DATA AVAILABLE port once
Count = INP(BasePort + &HE)    'DSP Available address
WriteDSP &HD0 'pause !very important! without it, the program can freeze
'              'because it is waiting for the DSP to be ready again
'WriteDSP &HDA 'exit io transfer (redundant)
'DMA Transfer is Now Complete
'WriteDSP &HD3 'speaker off

PRINT " done";

END SUB

' Reads a byte from the DSP
FUNCTION ReadDSP

DO: LOOP UNTIL INP(BasePort + 14) AND &H80
ReadDSP = INP(BasePort + 10)

END FUNCTION

' Resets the DSP
FUNCTION ResetDSP%

    OUT BasePort + &H6, 1   'reset
    FOR Count = 1 TO 4
       Temp = INP(BasePort + &H6)
    NEXT
    OUT BasePort + &H6, 0
   'This really should read the Data Available port until bit 7 is set
   'which takes about 100 micro seconds...
    PreTime! = TIMER
    DO: LOOP UNTIL (INP(BasePort + &HE) AND &H80) OR TIMER - PreTime! > .5
    IF INP(BasePort + &HE) AND &H80 = &H80 AND INP(BasePort + 10) = &HAA THEN
       ResetDSP = -1

        'get DSP version number
        WriteDSP &HE1
        DspVersion = ReadDSP + ReadDSP * 100
    ELSE
       ResetDSP = 0
    END IF

END FUNCTION

SUB TallyCycleScores
    SELECT CASE CycleScoreMode
    CASE 0'simulate basilar membrane movement

    CASE 1'find repeat points in wave
        FOR Count = 0 TO MaxCycleWidth - 1
            CycleScoreTable(Count) = 0
            OldScores(Count) = -1
        NEXT Count

        FOR Count = 0 TO SampleBufferSize - MaxCycleWidth - 2
            FOR WaveLength = 3 TO MaxCycleWidth - 1
                CycleScoreTable(WaveLength) = CycleScoreTable(WaveLength) + ABS(SampleBuffer(Count) - SampleBuffer(Count + WaveLength))
                NewScore& = CycleScoreTable(WaveLength) \ CurDownScaling
                IF NewScore& <> OldScores(WaveLength) THEN
                    PSET (WaveLength, 192 - NewScore&), (WaveLength AND 127) + 128
                END IF
            NEXT WaveLength
            IF LEN(INKEY$) THEN EXIT FOR
        NEXT Count
    CASE 2'compare sliding windows
        FOR Count = 0 TO MaxCycleWidth - 1
            CycleScoreTable(Count) = 0
            Left(Count) = 0
            Right(Count) = 0
            OldScores(Count) = -1
        NEXT Count

        Left(1) = SampleBuffer(0): Right(1) = SampleBuffer(1)
        FOR WaveLength = 2 TO MaxCycleWidth - 1
            Value = SampleBuffer(WaveLength - 1)
            Left(WaveLength) = Left(WaveLength - 1) + Value
            Right(WaveLength) = Right(WaveLength - 1) - Value + SampleBuffer(WaveLength * 2 - 2) + SampleBuffer(WaveLength * 2 - 1)
        NEXT WaveLength

        FOR Count = 0 TO SampleBufferSize - MaxCycleWidth - 2
            FOR WaveLength = 3 TO MaxCycleWidth - 1
                CycleScoreTable(WaveLength) = CycleScoreTable(WaveLength) + ABS(Left(WaveLength) - Right(WaveLength))

                'Advance windows
                Value = SampleBuffer(Count + WaveLength)
                Left(WaveLength) = Left(WaveLength) - SampleBuffer(Count) + Value
                Right(WaveLength) = Right(WaveLength) - Value + SampleBuffer(Count + WaveLength * 2)

                NewScore& = (CycleScoreTable(WaveLength) / CurDownScaling)' \ WaveLength
                IF NewScore& <> OldScores(WaveLength) THEN
                    IF WaveLength = CurWaveLength THEN LineColor = 15 ELSE LineColor = (WaveLength AND 127) + 128
                    PSET (WaveLength, 192 - NewScore&), LineColor
                END IF
                'LINE (WaveLength, 0)-(WaveLength, 99 - Dif), 0
                'LINE (WaveLength, 100 - Dif)-(WaveLength, 199), (WaveLength AND 127) + 128
            NEXT WaveLength
            IF LEN(INKEY$) THEN EXIT FOR
        NEXT Count

        'FOR WaveLength = 2 TO MaxCycleWidth - 1
        '    CycleScoreTable(WaveLength) = CycleScoreTable(WaveLength) \ WaveLength
        'NEXT WaveLength
    CASE 3 TO 5
        CyclePeakTotalMode = CycleScoreMode - 2
        FOR WaveLength = 2 TO MaxCycleWidth - 1
            CycleScoreTable(WaveLength) = CyclePeakTotal(WaveLength)
            Row = 191 - CycleScoreTable(WaveLength) \ CurDownScaling
            LINE (WaveLength, 0)-(WaveLength, Row), 0
            LINE (WaveLength, Row + 1)-(WaveLength, 191), (WaveLength AND 127) + 128
            LOCATE 25, 1: PRINT WaveLength; "="; CycleScoreTable(WaveLength);
            IF LEN(INKEY$) THEN EXIT FOR
        NEXT WaveLength
    END SELECT
END SUB

SUB TallyWaveResonance (StartingIndex)
    STATIC Col

    IF WaveResonanceDisplayMode < 2 THEN
        FOR WaveLength = 0 TO 319
            CycleScoreTable(WaveLength) = CycleScoreTable(WaveLength) + SampleBuffer(StartingIndex) - SampleBuffer(StartingIndex + WaveLength)
        NEXT WaveLength
    END IF

    SELECT CASE WaveResonanceDisplayMode
    CASE 0
        FOR WaveLength = 0 TO 319
            IF WaveLength = CurWaveLength THEN
                LineColor = 15: BackColor = 7
            ELSE
                LineColor = (WaveLength AND 127) + 128: BackColor = 0
            END IF
            Row = 100 - CycleScoreTable(WaveLength) \ CurDownScaling
            LINE (WaveLength, 0)-(WaveLength, Row), BackColor
            LINE (WaveLength, Row + 1)-(WaveLength, 191), LineColor
        NEXT WaveLength
    CASE 1
        Row = 100 - CycleScoreTable(CurWaveLength) \ CurDownScaling
        LINE (Col, 0)-(Col, Row), 0
        LINE (Col, Row + 1)-(Col, 191), (Col AND 127) + 128
        Col = (Col + 1) MOD 320
    CASE 2
        IF CurWaveLength > 1 THEN
            WaveLength = StartingIndex MOD CurWaveLength
            Value = CycleScoreTable(WaveLength) + SampleBuffer(StartingIndex) + SampleBuffer(StartingIndex + CurWaveLength)
            'IF Value > HighestCycleScore THEN
            '    HighestCycleScore = Value
            '    CurDownScaling = HighestCycleScore \ 180
            'END IF
            CycleScoreTable(WaveLength) = Value
            Row = 191 - CycleScoreTable(WaveLength) \ CurDownScaling
            LINE (WaveLength, 0)-(WaveLength, Row), 0
            LINE (WaveLength, Row + 1)-(WaveLength, 191), (WaveLength AND 127) + 128
        END IF
    END SELECT
END SUB

FUNCTION WaveLengthHighest
    'Find the highest table entry
    OldScore& = 0
    FOR WaveLength = 3 TO MaxCycleWidth - 1
        IF CycleScoreTable(WaveLength) > OldScore& THEN
            Count = WaveLength
            OldScore& = CycleScoreTable(WaveLength)
        END IF
    NEXT WaveLength
    WaveLengthHighest = Count
END FUNCTION

FUNCTION WaveLengthLowest
    Count = 3
    OldScore& = 0
    'Skip all of the initially low values at the front of the table
    FOR WaveLength = 3 TO MaxCycleWidth - 1
        IF CycleScoreTable(WaveLength) < OldScore& THEN EXIT FOR
        OldScore& = CycleScoreTable(WaveLength)
    NEXT WaveLength

    'Now find the lowest one afterwards
    OldScore& = 2147483647 'largest value a signed dword can hold
    FOR WaveLength = WaveLength TO MaxCycleWidth - 1
        IF CycleScoreTable(WaveLength) < OldScore& THEN
            Count = WaveLength
            OldScore& = CycleScoreTable(WaveLength)
        END IF
    NEXT WaveLength
    WaveLengthLowest = Count

END FUNCTION

' Writes a byte to the DSP
SUB WriteDSP (Byte)
    DO: LOOP WHILE INP(BasePort + &HC) AND &H80
    OUT BasePort + &HC, Byte
END SUB

