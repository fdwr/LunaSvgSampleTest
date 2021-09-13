'DspPlay
'Peekin
'2000-11-20
'2001-11-01
'
'This program is temporary and merely put together to test whether or not
'DSP events were being written correctly. It was adapted from a cheap MIDI
'player I wrote, so some of the variable names and such may be out of place.
'It assumes that the port base is at 388h, since I only intended for this to
'run on my own computer. Don't expect to learn too much from it ;)
'It only exports to a MIDI file if the constant OutputFile$ is not null.

DEFINT A-Z
DECLARE FUNCTION PlayDsp (CommandDeltaTime%, SourcePtr AS LONG)
DECLARE SUB AdvanceSpeWindow (RowCount&, DeltaTime&)
DECLARE SUB LoadEvents (FileHandle%, MidiFilePos&)
DECLARE SUB LoadSampleSettings ()
DECLARE SUB SbDataOut (Register, Value%)
DECLARE SUB SbInitChannel (Channel%)
DECLARE SUB StartMidi ()
DECLARE SUB EndMidi ()
DECLARE SUB FlipEndianLong (Num AS LONG)
DECLARE FUNCTION GetPitchNote% (Freq%)

'Current song:
'CONST MusicFile$ = "out.dsp"
CONST OutputFile$ = "out.mid"'"ctbtl.mid"
CONST OutputCopyrightInfo$ = "ChronoTrigger: Enemy Battle. Converted to MIDI format by Peekin (FDwR@hotmail.com)."                                              _
'"DKC Opening Tune, (c)1991 Nintendo"'"Super Mario World opening tune, (C)1991 Nintendo. Converted to MIDI format by Peekin (FDwR@hotmail.com)."

CONST True = -1, False = 0, ChromaticMultiple = 1.059469
CONST SbPortBase = &H388, MidiBufferSize = 65532, DefaultHalfSemitone = 138
CONST MidiNoteOff = &H80, MidiNoteOn = &H90, MidiKeyAfterTouch = &HA0, MidiControlChange = &HB0, MidiPatchChange = &HC0, MidiAfterTouch = &HD0, MidiPitchChange = &HE0, MidiMetaEvent = &HF0

TYPE MidiHeaderType
Id     AS STRING * 4    'MThd
Length AS LONG          'always 00,00,00,06
Format AS INTEGER       '0=single track, 1=multiple synchronous, 2=multiple asynchronous
Tracks AS INTEGER       '1 or more
Ticks  AS INTEGER       'time ticks per quarter note
END TYPE

TYPE TrackHeaderType
Id     AS STRING * 4    'MTrk
Length AS LONG
END TYPE

TYPE DspVoiceType
Playing AS INTEGER
Note    AS INTEGER
FreqL   AS INTEGER
FreqH   AS INTEGER
Active  AS INTEGER
Sample  AS INTEGER
END TYPE

TYPE SampleInfoType
PitchMultiple AS LONG
Transpose     AS INTEGER
HighestPitch  AS INTEGER
Instrument    AS INTEGER
Volume        AS INTEGER
END TYPE

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
bp AS INTEGER: si AS INTEGER: di AS INTEGER: fl AS INTEGER
Ds AS INTEGER: es AS INTEGER
END TYPE

DIM SHARED ErrorHandled
DIM SHARED DspEvents(MidiBufferSize \ 4) AS LONG
DIM SHARED DspVoices(7) AS DspVoiceType, InitialVoices(7) AS DspVoiceType, MarkedVoices(7) AS DspVoiceType
DIM SHARED MidiLength AS LONG, WindowDensity, PlaySpeed AS LONG
DIM SHARED FreqTable(127) AS LONG, PitchTable(16384) AS INTEGER, SbFmRegTable(8)
DIM SHARED MidiFileHandle, Regs AS RegType, SampleTable(255) AS SampleInfoType, PreviousInstruments(7)
DIM SHARED MarkedPtr AS LONG, RecordMidi, SampleLock

MusicFile$ = COMMAND$

PlaySpeed = 2496000
WindowDensity = 30000

PRINT "Initializing tables..."

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

'NoteCount = 12
'Octave = 0
'RESTORE FmFreqData
'FOR Count = 0 TO 127
'    READ Freq
'    FreqTable(Count) = Freq + Octave
'    NoteCount = NoteCount - 1
'    IF NoteCount <= 0 THEN
'        RESTORE FmFreqData
'        NoteCount = 12
'        Octave = Octave + 1024
'    END IF
'NEXT Count
'PitchBase& = 1950
'PitchInc& = 512
'FOR Count = 0 TO 127
'    PitchTable(Count) = PitchBase& \ 3900
'    'PRINT PitchBase& \ 3900;PitchInc&;
'    PitchInc& = PitchInc& * .99455
'    PitchBase& = PitchBase& + PitchInc&
'NEXT Count

'Build pitch to half semitone table
Pitch# = 16384
PreviousPitch = 16383
'PRINT "Initial value:"; Pitch#
FOR HalfSemitone = 255 TO 0 STEP -1
    Pitch# = Pitch# * .971531941153606#
    FOR Count = INT(Pitch#) TO PreviousPitch
        PitchTable(Count) = HalfSemitone
    NEXT Count
    IF (HalfSemitone + 8) MOD 24 = 0 THEN Pitch# = INT(Pitch#)
    PreviousPitch = INT(Pitch#) - 1
    SampleTable(HalfSemitone).Transpose = DefaultHalfSemitone
NEXT HalfSemitone

'Pitch# = 263.6112760779898#'131.8056380389949# 'start half a chromatic step above 128
'PreviousPitch = 127
'FOR MidiNote = 12 TO 1 STEP -1
'    Pitch# = Pitch# * .9438743126816935#
'    FOR Count = INT(Pitch#) - 128 TO PreviousPitch
'        PitchTable(Count) = MidiNote
'    NEXT Count
'    PreviousPitch = INT(Pitch#) - 129
'NEXT MidiNote
'IF (MidiNote + 4) MOD 12 = 0 THEN Pitch# = INT(Pitch#)

'PRINT ENVIRON$("BLASTER")
'Clear all SB registers
'FOR Count = 0 TO 255: SbDataOut Count, &H0: NEXT Count
SbDataOut &HBD, &H0
RESTORE ChannelRegData
FOR Count = 0 TO 7
    READ SbFmRegTable(Count)
    InitialVoices(Count).Active = True
    SbInitChannel Count
    PreviousInstruments(Count) = -1
NEXT Count

'For testing note sounds
' Note = 60
' &HB0, &H0                           'Turn the voice off
' &HA0, FreqTable(Note) AND 255       'Set voice frequency's LSB
' &HB0, FreqTable(Note) \ 256 OR &H20 'Turn the voice on; set the octave and freq MSB
' Note = 60:SbDataOut &HB0, &H0:SbDataOut &HA0, FreqTable(Note) AND 255:SbDataOut &HB0, FreqTable(Note) \ 256 OR &H20

SCREEN 13
CLS

PRINT "Spc-Dsp-Event Player Test"
PRINT
PRINT "1-8    Turn on/off channels"
PRINT "9/0    All on or all off"
PRINT "Space  Skip to next event"
PRINT "Enter  Restart"
PRINT "Esc    Quit playing"
PRINT

ON ERROR GOTO FileErrorHandler
OPEN MusicFile$ FOR INPUT AS 1: CLOSE 1
ON ERROR GOTO 0
OPEN MusicFile$ FOR BINARY AS 1
LoadEvents 1, MidiFilePos&
CLOSE 1
LoadSampleSettings
IF LEN(OutputFile$) THEN
    OPEN OutputFile$ FOR OUTPUT AS 1
    MidiFileHandle = 1
END IF
PRINT "Press any key..."
DO: LOOP UNTIL LEN(INKEY$)

IF MidiFileHandle THEN StartMidi
'!!! move the following reset code into the loop
FOR Count = 0 TO 7
    DspVoices(Count) = InitialVoices(Count)
NEXT Count
DO
    CommandDeltaTime = 0
LOOP WHILE PlayDsp(CommandDeltaTime, 0)
IF MidiFileHandle THEN
    EndMidi
    CLOSE MidiFileHandle
END IF

'SbDataOut &HB0, &H0'    Turn the voice off
END

FileErrorHandler:
    PRINT
    PRINT "Could not load: "; MusicFile$
    PRINT "Please make sure it exists."
    DO: LOOP UNTIL LEN(INKEY$)
END

ErrorHandler:
    ErrorHandled = ERR
RESUME NEXT

FmFreqData:
DATA &H16B,&H181,&H198,&H1B0,&H1CA,&H1E5
'C#=277.2  D=293.7  D#=311.1  E=329.6  F=349.2  F#=370.0
DATA &H202,&H220,&H241,&H263,&H287,&H2AE
'G=392.0  G#=415.3  A=440.0  A#=466.2  B=493.9  C=523.3

ChannelRegData:
DATA 0,1,2,8,9,10,16,17,18

SUB AdvanceSpeWindow (Counter AS LONG, DeltaTime&)
    Top = Counter \ WindowDensity
    Btm = (Counter + DeltaTime&) \ WindowDensity - 1
    IF Btm < Top THEN
        Btm = Top
    ELSEIF Btm >= 320 THEN
        Btm = 319
        GOSUB DrawMidiWindowPortion
        Top = 0
        Btm = Btm - 321
    END IF
    GOSUB DrawMidiWindowPortion
    Temp& = Counter + DeltaTime&
    IF Temp& >= WindowDensity * 320& THEN
        Counter = 0
        LINE (0, 13)-(319, 183), 0, BF
    ELSE
        Counter = Temp&
    END IF
    'ELSEIF Counter >= WindowDensity * 95 THEN
    '    LINE (0, 95)-(319, 189), 0, BF
    'END IF
    Top = Counter \ WindowDensity + 1
    'LINE (0, TopRow)-(319, TopRow), 15, , &H5555
    EXIT SUB

DrawMidiWindowPortion:
    FOR Count = 0 TO 7
        IF DspVoices(Count).Playing AND InitialVoices(Count).Active THEN
            Note = 183 - DspVoices(Count).Note
            LINE (Top, Note)-(Btm, Note), Count * 3 + 48
            '(Note MOD 12) * 2 + 48 alternate coloring
        END IF
    NEXT Count
RETURN

END SUB

SUB EndMidi

    FOR Count = 0 TO 7
        IF DspVoices(Count).Playing AND InitialVoices(Count).Active <> 0 THEN
            Note = DspVoices(Count).Note
            PRINT #MidiFileHandle, CHR$(0);
            PRINT #MidiFileHandle, CHR$(MidiNoteOff OR Count); CHR$(Note); "`";
        END IF
    NEXT Count

    PRINT #MidiFileHandle, CHR$(0); CHR$(255); CHR$(&H2F); CHR$(0);
    MidiLength = LOF(MidiFileHandle) - 22
    'length is in stupid reverse format
    FlipEndianLong MidiLength
    SEEK MidiFileHandle, 19
    PRINT #MidiFileHandle, MKL$(MidiLength);

END SUB

SUB FlipEndianLong (Num AS LONG)

Text$ = MKL$(Num)
Text$ = MID$(Text$, 4, 1) + MID$(Text$, 3, 1) + MID$(Text$, 2, 1) + MID$(Text$, 1, 1)
Num = CVL(Text$)

END SUB

FUNCTION GetPitchNote (Freq)
    GetPitchNote = PitchTable(Freq)
END FUNCTION

SUB LoadEvents (FileHandle, MidiFilePos&)

DIM FileLength AS LONG
DIM DspRam AS STRING * 128

FileLength = LOF(FileHandle)
MidiLength = FileLength - 128
IF MidiLength > MidiBufferSize THEN MidiLength = MidiBufferSize: Text$ = "(will only load 65532 bytes)" ELSE Text$ = ""
PRINT "SPE File Length:"; FileLength; Text$
'PRINT "Loading.";
PRINT

DspRam = INPUT$(128, 1)
SourcePtr = 0
FOR Count = 0 TO 7
    InitialVoices(Count).Playing = False
    InitialVoices(Count).Sample = ASC(MID$(DspRam, SourcePtr + 5, 1))
    InitialVoices(Count).FreqL = ASC(MID$(DspRam, SourcePtr + 3, 1))
    InitialVoices(Count).FreqH = ASC(MID$(DspRam, SourcePtr + 4, 1))
    SourcePtr = SourcePtr + 16
NEXT Count
'MarkedVoices = InitialVoices

IF MidiLength > 0 THEN
    Regs.Ax = &H3F00
    Regs.Bx = FILEATTR(FileHandle, 2)
    Regs.Ds = VARSEG(DspEvents(0))
    Regs.Dx = 0
    IF MidiLength > 32767 THEN
        Regs.Cx = MidiLength - 65536
    ELSE
        Regs.Cx = MidiLength
    END IF
    CALL InterruptX(&H21, Regs, Regs)
ELSE
    MidiLength = 0      'in case negative
END IF

END SUB

SUB LoadSampleSettings
    
    ON ERROR GOTO ErrorHandler
    ErrorHandled = 0
    OPEN "default.sps" FOR INPUT AS 2
    ON ERROR GOTO 0
    IF ErrorHandled THEN EXIT SUB
    Count = 0
    DO
        IF EOF(2) THEN
            NewCount = 256
        ELSE
            INPUT #2, NewCount, Note, Instrument, Volume
            SampleTable(NewCount).Transpose = Note
            SampleTable(NewCount).Instrument = Instrument
            SampleTable(NewCount).Volume = Volume
        END IF
        FOR Count = Count TO NewCount - 1
            SampleTable(Count).Transpose = DefaultHalfSemitone
        NEXT Count
        Count = Count + 1
    LOOP UNTIL Count > 255
    CLOSE 2
END SUB

FUNCTION PlayDsp (CommandDeltaTime, SourcePtr AS LONG)

DIM CurrentDeltaTime AS LONG, DeltaTime AS LONG, MidiWindowRowCount AS LONG
DIM LastOutputDeltaTime AS LONG

PlayDsp = 1         'default is to continue, unless told otherwise
FullSpeed = 0
DEF SEG = VARSEG(DspEvents(0))

CLS 'LINE (0, 0)-(319, 199), 7, BF
SelectedSample = DspVoices(SelectedChannel).Sample
GOSUB DisplayActiveChannels
Text$ = "Press space..."
GOSUB DisplayMessage

'Export all instruments
'FOR Count = 0 TO 127
'    PRINT #MidiFileHandle, CHR$(0); CHR$(MidiPatchChange); CHR$(Count);
'    DeltaTime = 25: GOSUB PutGivenDeltaTime
'    PRINT #MidiFileHandle, CHR$(MidiNoteOn); CHR$(60); "`";
'    DeltaTime = 100: GOSUB PutGivenDeltaTime
'    PRINT #MidiFileHandle, CHR$(MidiNoteOn); CHR$(64); "`";
'    DeltaTime = 100: GOSUB PutGivenDeltaTime
'    PRINT #MidiFileHandle, CHR$(MidiNoteOn); CHR$(67); "`";
'    DeltaTime = 100: GOSUB PutGivenDeltaTime
'    PRINT #MidiFileHandle, CHR$(MidiNoteOff); CHR$(60); "`";
'    DeltaTime = 100: GOSUB PutGivenDeltaTime
'    PRINT #MidiFileHandle, CHR$(MidiNoteOff); CHR$(64); "`";
'    DeltaTime = 100: GOSUB PutGivenDeltaTime
'    PRINT #MidiFileHandle, CHR$(MidiNoteOff); CHR$(67); "`";
'NEXT Count

CurrentEventRow = 10
CurrentEventPixelRow = 0
CurrentDeltaTime = CommandDeltaTime
LastOutputDeltaTime = CommandDeltaTime
PrePcTime# = TIMER
GOSUB GetDeltaTime
NextPcTime# = 100000 'NextPcTime# = PrePcTime# + DeltaTime / PlaySpeed
DO
    IF TIMER >= NextPcTime# THEN
        GOSUB DoCommand
        IF TIMER - NextPcTime# > 1 THEN
            PrePcTime# = TIMER
        ELSE
            PrePcTime# = NextPcTime#
        END IF
        IF SourcePtr >= MidiLength THEN EXIT DO
        GOSUB GetDeltaTime
        IF FullSpeed THEN
            NextPcTime# = TIMER
        ELSE
            NextPcTime# = PrePcTime# + DeltaTime / PlaySpeed
        END IF
        IF SignificantChange = True THEN
            AdvanceSpeWindow MidiWindowRowCount, DeltaTime
            SignificantChange = False
        END IF
    END IF
    Key$ = INKEY$
    IF LEN(Key$) THEN
        SELECT CASE Key$
        CASE "`"
            FullSpeed = FullSpeed XOR 1
        CASE "1" TO "8"
            Channel = ASC(Key$) - 49
            Note = DspVoices(Channel).Note
            GOSUB TurnOff
            InitialVoices(Channel).Active = InitialVoices(Channel).Active XOR True
            GOSUB DisplayActiveChannels
        CASE "0", "9"
            IF Key$ = "0" THEN Count = 0 ELSE Count = -1
            FOR Channel = 0 TO 7
                InitialVoices(Channel).Active = Count
            NEXT Channel
            GOSUB DisplayActiveChannels
        CASE CHR$(0) + "K"
            SelectedChannel = (SelectedChannel - 1) AND 7
            SelectedSample = DspVoices(SelectedChannel).Sample
            GOSUB DisplayActiveChannels
        CASE CHR$(0) + "M"
            SelectedChannel = (SelectedChannel + 1) AND 7
            SelectedSample = DspVoices(SelectedChannel).Sample
            GOSUB DisplayActiveChannels
        CASE CHR$(0) + "s"
            SelectedSample = SelectedSample - 1 AND 255
            GOSUB DisplayActiveChannels
        CASE CHR$(0) + "t"
            SelectedSample = SelectedSample + 1 AND 255
            GOSUB DisplayActiveChannels
        CASE CHR$(0) + "H"
            SampleTable(SelectedSample).Transpose = SampleTable(SelectedSample).Transpose + 1
            GOSUB DisplayActiveChannels
        CASE CHR$(0) + "P"
            SampleTable(SelectedSample).Transpose = SampleTable(SelectedSample).Transpose - 1
            GOSUB DisplayActiveChannels
        CASE CHR$(0) + "I"
            SampleTable(SelectedSample).Transpose = SampleTable(SelectedSample).Transpose + 24
            GOSUB DisplayActiveChannels
        CASE CHR$(0) + "Q"
            SampleTable(SelectedSample).Transpose = SampleTable(SelectedSample).Transpose - 24
            GOSUB DisplayActiveChannels
        CASE "i"
            SampleTable(SelectedSample).Instrument = (SampleTable(SelectedSample).Instrument + 1) AND 127
            GOSUB DisplayActiveChannels
        CASE "I"
            SampleTable(SelectedSample).Instrument = (SampleTable(SelectedSample).Instrument - 1) AND 127
            GOSUB DisplayActiveChannels
        'CASE "A"
            'IF SampleTable(SelectedChannel).HighestPitch THEN
            '    SampleTable(SelectedChannel).HighestPitch = 0
            'ELSE
            '    SampleTable(SelectedChannel).HighestPitch = 1
            'END IF
        CASE "m"
            MarkedPtr = SourcePtr
            FOR Count = 0 TO 7
                MarkedVoices(Count) = DspVoices(Count)
            NEXT Count
        CASE "r"
            IF MidiFileHandle THEN
                RecordMidi = RecordMidi XOR 1
            END IF
            GOSUB DisplayActiveChannels
        CASE "l"
            SampleLock = SampleLock XOR -1
            GOSUB DisplayActiveChannels
        CASE CHR$(8)
            SourcePtr = MarkedPtr
            FOR Count = 0 TO 7
                DspVoices(Count) = MarkedVoices(Count)
            NEXT Count
            GOSUB GetDeltaTime
            GOSUB DisplayActiveChannels
            IF NextPcTime# < 100000 THEN NextPcTime# = TIMER
            Text$ = "Reset"
            GOSUB DisplayMessage
        CASE CHR$(13)
            EXIT DO         '<-- exit point
        CASE " "
            IF NextPcTime# >= 100000 THEN
                Text$ = "Playing"
                NextPcTime# = TIMER
            ELSE
                Text$ = "Paused"
                NextPcTime# = 100000
            END IF
            GOSUB DisplayMessage
        CASE "W"
            OPEN "default.sps" FOR OUTPUT AS 2
            FOR Count = 0 TO 255
                Note = SampleTable(Count).Transpose
                IF Note <> DefaultHalfSemitone THEN
                    WRITE #2, Count, Note, SampleTable(Count).Instrument, SampleTable(Count).Volume
                END IF
            NEXT Count
            CLOSE 2
            'OPEN "Pitches.txt" FOR OUTPUT AS 2
            'PRINT #2, "list of spc pitches:"
            'FOR Freq = 0 TO 16383
                'IF PitchRecord(Freq) THEN
                '    PRINT #2, LTRIM$(STR$(Freq)) + ":";
                '    Byte = PitchRecord(Freq)
                '    FOR Count = 1 TO 8
                '         IF Byte AND 1 THEN PRINT #2, STR$(Count);
                '         Byte = Byte \ 2
                '    NEXT Count
                '    PRINT #2,
                'END IF
            'NEXT Freq
            'CLOSE 2
        CASE "q"
            LoadSampleSettings
        CASE CHR$(27)
            PlayDsp = 0
            EXIT DO         '<-- exit point
        END SELECT
    END IF
LOOP
EXIT FUNCTION

GetDeltaTime:
    Time& = PEEK(SourcePtr) + PEEK(SourcePtr + 1) * 256& + PEEK(SourcePtr + 2) * 65536 + PEEK(SourcePtr + 3) * 16777216
    DeltaTime = Time& - CurrentDeltaTime
    CurrentDeltaTime = Time&
RETURN

DoCommand:
    IF SourcePtr >= 65530 THEN RETURN
    Byte = PEEK(SourcePtr + 4)
    Command = Byte AND 15: Channel = (Byte AND 240) \ 16
    RegValue = PEEK(SourcePtr + 5)
    SELECT CASE Command
    CASE 2
        DspVoices(Channel).FreqL = RegValue
        'Text$ = "pitch low " + STR$(Channel) + ":" + STR$(RegValue)
    CASE 3
        DspVoices(Channel).FreqH = RegValue
        'Text$ = "pitch high" + STR$(Channel) + ":" + STR$(RegValue)
    CASE 4
        IF DspVoices(Channel).Sample <> RegValue THEN
            DspVoices(Channel).Sample = RegValue
            IF NOT SampleLock AND Channel = SelectedChannel THEN
                SelectedSample = RegValue
                GOSUB DisplayActiveChannels
            END IF
            'Text$ = "sample" + STR$(Channel) + ":" + STR$(RegValue)
        END IF
    CASE 12
        IF Channel = 4 THEN
            FOR Channel = 0 TO 7
                IF RegValue AND 1 THEN
                    DspVoices(Channel).Playing = 1
                    Freq = ((DspVoices(Channel).FreqH AND 63) * 256) OR DspVoices(Channel).FreqL
                    'IF Freq > SampleTable(Channel).HighestPitch THEN
                        'SampleTable(Channel).HighestPitch = Freq
                        'IF Freq > SampleTable(Channel).HighestPitch THEN
                        '    SampleTable(Channel).PitchMultiple = 268435456 \ Freq
                        '
                        'END IF
                        'Freq = Freq * SampleTable(Channel).PitchMultiple \ 65536
                        'Note = GetPitchNote(Freq, SbFreq) + SampleTable(Channel).Transpose
                    'END IF
                    '-69 -35
                    Note = (GetPitchNote(Freq) + SampleTable(DspVoices(Channel).Sample).Transpose - 208) \ 2
                    IF Note < 0 THEN Note = 0 ELSE IF Note > 127 THEN Note = 127
                    DspVoices(Channel).Note = Note
                    GOSUB TurnOn
                    SignificantChange = True
                END IF
                RegValue = RegValue \ 2
            NEXT Channel
        ELSEIF Channel = 5 THEN
            'Text$ = "off"
            FOR Channel = 0 TO 7
                IF RegValue AND 1 THEN
                    DspVoices(Channel).Playing = 0
                    'Text$ = Text$ + STR$(Channel)
                    Note = DspVoices(Channel).Note
                    GOSUB TurnOff
                    SignificantChange = True
                END IF
                RegValue = RegValue \ 2
            NEXT Channel
        ELSE GOTO UnknownCommand
        END IF
    CASE ELSE
UnknownCommand:
        Text$ = "Command: " + HEX$(Byte)
    END SELECT
    SourcePtr = SourcePtr + 6
    'LOCATE 25, 1
    'PRINT STR$(CurrentDeltaTime); ":"; TAB(15); Text$; TAB(40);
RETURN

TurnOn:
    IF InitialVoices(Channel).Active THEN
        COLOR Channel * 3 + 48
        LINE (Note, 8)-(Note, 12)
        LOCATE 1, 1 + Channel * 5: PRINT LEFT$(HEX$(Freq) + "    ", 5);
        'Text$ = Text$ + STR$(Channel)' + ":" + STR$(Note) + "(" + STR$(Freq) + ")"
        'PitchRecord(Freq) = PitchRecord(Freq) OR 2 ^ Channel
        Reg = Channel
        SbDataOut &HB0 + Reg, &H0                           'Turn the voice off
        SbDataOut &HA0 + Reg, FreqTable(Note) AND 255       'Set voice frequency's LSB
        SbDataOut &HB0 + Reg, FreqTable(Note) \ 256 OR &H20 'Turn the voice on; set the octave and freq MSB
        IF RecordMidi THEN
            Count = SampleTable(DspVoices(Channel).Sample).Instrument
            IF Count <> PreviousInstruments(Channel) THEN
                PreviousInstruments(Channel) = Count
                PRINT #MidiFileHandle, CHR$(0); CHR$(MidiPatchChange OR Channel); CHR$(Count);
            END IF
            GOSUB PutDeltaTime
            PRINT #MidiFileHandle, CHR$(MidiNoteOn OR Channel); CHR$(Note); "`";
        END IF
    END IF
RETURN

TurnOff:
    IF InitialVoices(Channel).Active THEN
        LINE (Note, 8)-(Note, 12), 0
        'SOUND 0, 0
        'SbDataOut &HB0, &H1    'Turn the voice off; set the octave and freq MSB
        IF RecordMidi THEN
            GOSUB PutDeltaTime
            PRINT #MidiFileHandle, CHR$(MidiNoteOff OR Channel); CHR$(Note); "`";
        END IF
    END IF
RETURN

PutDeltaTime:
    DeltaTime = (CurrentDeltaTime - LastOutputDeltaTime) \ 4996
    LastOutputDeltaTime = CurrentDeltaTime
   
PutGivenDeltaTime:
    Byte = 0
    IF DeltaTime > 2080768 THEN
        PRINT #MidiFileHandle, CHR$(((DeltaTime AND 266338304) \ 2097152) OR 128);
    END IF
    IF DeltaTime > 16256 THEN
        PRINT #MidiFileHandle, CHR$(((DeltaTime AND 2080768) \ 16384) OR 128);
    END IF
    IF DeltaTime > 127 THEN
        PRINT #MidiFileHandle, CHR$(((DeltaTime AND 16256) \ 128) OR 128);
    END IF
    PRINT #MidiFileHandle, CHR$(DeltaTime AND 127);
RETURN

DisplayMessage:
    COLOR 15: LOCATE 25, 26: PRINT Text$; TAB(40);
RETURN

DisplayActiveChannels:
    LOCATE 25, 1
    ColorCount = 48
    FOR Count = 0 TO 7
        IF Count = SelectedChannel THEN COLOR 15 ELSE COLOR ColorCount
        IF InitialVoices(Count).Active THEN
            PRINT MID$("12345678", Count + 1, 1);
        ELSE
            PRINT "ù";
        END IF
        ColorCount = ColorCount + 3
    NEXT Count
    COLOR (SelectedChannel * 3) + 48
    Count = SampleTable(SelectedSample).Transpose
    PRINT STR$(SelectedSample) + " t" + LTRIM$(STR$(Count \ 2));
    IF Count AND 1 THEN PRINT "«";
    PRINT " i" + LTRIM$(STR$(SampleTable(SelectedSample).Instrument + 1));
    Text$ = "  "
    IF RecordMidi THEN MID$(Text$, 1, 1) = "R"
    IF SampleLock THEN MID$(Text$, 2, 1) = "L"
    PRINT TAB(23); Text$;
RETURN

END FUNCTION

SUB PlayFreq (Hertz, Reg)
'2001-07-25

DIM FreqNumber, Frequency AS DOUBLE

'The largest hertz input should never be more 12543hz

'sb frequency = hertz * 2^20
Frequency = Hertz * 1048576
Octave = 0
DO WHILE Frequency > 50331648 '(48 * (2 ^ 20)) / 49716 < 1024
    Frequency = Frequency / 2
    Octave = Octave + 4
LOOP
FreqNumber = Frequency \ 49716

SbDataOut &HB0 + Reg, &H0               'Turn the voice off
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
    SbDataOut &H20 + Reg, &H2  'Set the modulator's multiple to 1
    SbDataOut &H40 + Reg, &H10 'Set the modulator's level to about 40 dB
    SbDataOut &H60 + Reg, &H99  'Modulator attack: quick;   decay: long
    SbDataOut &H80 + Reg, &H88 'Modulator sustain: medium;  release: medium
    SbDataOut &H23 + Reg, &H1  'Set the carrier's multiple to 1
    SbDataOut &H43 + Reg, &H0  'Set the carrier to maximum volume (about 47 dB)
    SbDataOut &H63 + Reg, &H74 'Carrier attack:  quick;   decay:   long
    SbDataOut &H83 + Reg, &HFF 'Carrier sustain: medium;  release: medium
    '2 10 99 88 1 0 f4 ff   chirp whistle
    '2 10 88 88 1 0 f4 ff   glass blow
    '4 10 aa 88 1 0 f4 88   glock+vibraphone
    '1 10 88 33 1 0 c4 44   sitar
    '2 10 88 33 1 0 c4 44   carnival
    '2 10 f8 44 1 0 c4 44   wood glock+celesta
    '3 10 99 88 1 0 75 16   marimba
END SUB

SUB StartMidi

'MIDI header ID
'header length of 6
'single track format
'time ticks per quarter note (2496000 / (8000 * 16))
'the average precision for most games is 1/500th of a second.
'the default beats per minute is 120, making beats per second 2.
'so the delta ticks per beat would be 250 (500/2).

DIM MidiHeader AS MidiHeaderType
DIM TrackHeader AS TrackHeaderType

MidiHeader.Id = "MThd"
MidiHeader.Length = &H6000000   'always 00,00,00,06 bytes
MidiHeader.Format = 0           '0=single track, 1=multiple synchronous, 2=multiple asynchronous
MidiHeader.Tracks = &H100       '1 or more
MidiHeader.Ticks = &HFA00       'time ticks per quarter note
TrackHeader.Id = "MTrk"
'TrackHeader.Length = ###       'length is not known until song is complete

'PUT #MidiFileHandle, , MidiHeader
'PUT #MidiFileHandle, , TrackHeader
PRINT #MidiFileHandle, MidiHeader.Id; MKL$(MidiHeader.Length); MKI$(MidiHeader.Format); MKI$(MidiHeader.Tracks); MKI$(MidiHeader.Ticks); TrackHeader.Id; MKL$(0);

'set tempo to 500,000 microseconds
PRINT #MidiFileHandle, CHR$(0); CHR$(255); CHR$(&H51); MKL$(&H20A10703);
'print copyright info
IF LEN(OutputCopyrightInfo$) THEN
    PRINT #MidiFileHandle, CHR$(0); CHR$(255); CHR$(2); CHR$(LEN(OutputCopyrightInfo$)); OutputCopyrightInfo$;
END IF

END SUB

