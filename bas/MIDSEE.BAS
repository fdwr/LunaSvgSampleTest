'1999-06-29
DEFINT A-Z
DECLARE SUB FlipEndianInt (Num%)
DECLARE SUB FlipEndianLong (Num&)
DECLARE SUB CheckMidiHeader (FileHandle%, MidiFilePos&, HeaderError%)
DECLARE SUB PlayMidi (WindowDeltaTime%, CommandDeltaTime%, CommandPos AS LONG)
DECLARE SUB AdvanceMidiWindow (RowCount, DeltaTime&)
DECLARE SUB LoadMidiEvents (FileHandle%, MidiFilePos&)
DECLARE SUB SbDataOut (Register%, Value%)

CONST True = -1, False = 0, ChromaticMultiple = 1.059469
CONST MidiNoteOff = 8, MidiNoteOn = 9, MidiKeyAfterTouch = 10, MidiControlChange = 11, MidiPatchChange = 12, MidiChannelAfterTouch = 13, MidiPitchChange = 14, MidiMetaEvent = 15
CONST FileBufferSize = 8192, FileBase& = 1
CONST MusicFile$ = "c:\dwayne's\music\mktheme.mid", DesiredTrack = 6
'CONST MusicFile$ = "c:\dwayne's\music\mcvmidas.mid", DesiredTrack = 8
'CONST MusicFile$ = "c:\mirc\sounds\dream_on.mid", DesiredTrack = 1
CONST SbPortBase = &H388

TYPE MidiChannelType
Playing AS INTEGER
Note    AS INTEGER
Depress AS INTEGER
Release AS INTEGER
Active  AS INTEGER
END TYPE

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

DIM SHARED FileBuffer AS STRING * FileBufferSize, MidiEvents(16383) AS LONG, MidiLength AS LONG, EventPos AS LONG
DIM SHARED MidiHeader AS MidiHeaderType, MidiChannel(15) AS MidiChannelType, FreqTable(127) AS LONG
DIM SHARED WindowDensity, PlaySpeed

'KeyFreq& = 4096
'NoteFreq& = KeyFreq&
'NoteCount = 12
'FOR Count = 0 TO 127
'    FreqTable(Count) = NoteFreq&
'    NoteFreq& = NoteFreq& * ChromaticMultiple
'    NoteCount = NoteCount - 1
'    IF NoteCount <= 0 THEN
'        KeyFreq& = 4096'KeyFreq& * 2
'        NoteFreq& = KeyFreq&
'        NoteCount = 12
'    END IF
'NEXT Count

NoteCount = 12
Octave = 0
RESTORE FmFreqData
FOR Count = 0 TO 127
    READ Freq
    FreqTable(Count) = Freq + Octave
    NoteCount = NoteCount - 1
    IF NoteCount <= 0 THEN
        RESTORE FmFreqData
        NoteCount = 12
        Octave = Octave + 1024
    END IF
NEXT Count

'PRINT ENVIRON$("BLASTER")
'   REGISTER     VALUE     DESCRIPTION
SbDataOut &H20, &H0 '    Set the modulator's multiple to 1
SbDataOut &H40, &H10'    Set the modulator's level to about 40 dB
SbDataOut &H60, &H88  '    Modulator attack: quick;   decay: long
SbDataOut &H80, &H88'    Modulator sustain: medium;  release: medium
SbDataOut &H23, &H1 '    Set the carrier's multiple to 1
SbDataOut &H43, &H0 '    Set the carrier to maximum volume (about 47 dB)
SbDataOut &H63, &HF4'    Carrier attack:  quick;   decay:   long
SbDataOut &H83, &HFF'    Carrier sustain: medium;  release: medium
SbDataOut &H21, &H0 '    Set the modulator's multiple to 1
SbDataOut &H41, &H10'    Set the modulator's level to about 40 dB
SbDataOut &H61, &H88  '    Modulator attack: quick;   decay: long
SbDataOut &H81, &H88'    Modulator sustain: medium;  release: medium
SbDataOut &H24, &H1 '    Set the carrier's multiple to 1
SbDataOut &H44, &H0 '    Set the carrier to maximum volume (about 47 dB)
SbDataOut &H64, &HF4'    Carrier attack:  quick;   decay:   long
SbDataOut &H84, &HFF'    Carrier sustain: medium;  release: medium
'SbDataOut &HA0, &H98'    Set voice frequency's LSB (it'll be a D#)
'SbDataOut &HB0, &H31'    Turn the voice on; set the octave and freq MSB

'RESTORE TestNotes
'DO
'    READ Note
'    IF Note < 0 THEN RESTORE TestNotes: READ Note
'    Note = Note + 50
'    DO: LOOP UNTIL TIMER - PreTime# > .1
'    SbDataOut &HB0, &H0: SbDataOut &HA0, FreqTable(Note) AND 255: SbDataOut &HB0, FreqTable(Note) \ 256 OR &H20
'    PreTime# = TIMER
'LOOP UNTIL LEN(INKEY$)
'END

SCREEN 13
CLS

PreTime# = TIMER
OPEN MusicFile$ FOR INPUT AS 1: CLOSE 1
OPEN MusicFile$ FOR BINARY AS 1
CheckMidiHeader 1, MidiFilePos&, HeaderError
IF HeaderError THEN
    END
END IF
LoadMidiEvents 1, MidiFilePos&
CLOSE 1
DO: LOOP UNTIL TIMER - PreTime# > 4 OR LEN(INKEY$)

WindowDensity = 8
PlaySpeed = MidiHeader.Ticks * 2
IF PlaySpeed < 1 THEN PlaySpeed = 120

PlayMidi WindowDeltaTime, CommandDeltaTime, EventPos

SbDataOut &HB0, &H0'    Turn the voice on; set the octave and freq MSB
END

FmFreqData:
DATA &H16B,&H181,&H198,&H1B0,&H1CA,&H1E5
'C#=277.2  D=293.7  D#=311.1  E=329.6  F=349.2  F#=370.0
DATA &H202,&H220,&H241,&H263,&H287,&H2AE
'G=392.0  G#=415.3  A=440.0  A#=466.2  B=493.9  C=523.3

'TestNotes:
'DATA 0,2,3,5,6,8,9,11,12,14,15,17,18,20,21,23,24
'DATA 23,21,20,18,17,15,14,12,11,9,8,6,5,3,2,-1
'DATA 0,1,3,4,7,8,10, 12,13,15,16,19,20,22,24
'DATA 22,20,19,16,15,13,12, 10,8,7,4,3,1,-1
'Hawaiian
'DATA 0,2,3,5,7,9,11,12,11,9,7,5,3,2,-1
'Hungarian Gypsy
'DATA 0,2,3,6,7,8,10,12,10,8,7,6,3,2,-1
'Egyptian
'DATA 0,2,5,7,8,11,12,11,8,7,5,2,-1

SUB AdvanceMidiWindow (Counter, DeltaTime&)
    Start = Counter \ WindowDensity
    Finish = (Counter + DeltaTime&) \ WindowDensity - 1
    IF Finish < Start THEN
        Finish = Start
    ELSEIF Btm >= 320 THEN
        Finish = 319
        GOSUB DrawMidiWindowPortion
        Start = 0
        Finish = Finish - 321
    END IF
    GOSUB DrawMidiWindowPortion
    Counter& = Counter + DeltaTime&
    IF Counter& >= WindowDensity * 320 THEN
        Counter = 0
        LINE (0, 5)-(319, 183), 0, BF
    ELSE
        Counter = Counter&
    'ELSEIF Counter >= WindowDensity * 95 THEN
    '    LINE (0, 95)-(319, 189), 0, BF
    END IF
    'Start = Counter \ WindowDensity + 1
    'LINE (0, TopRow)-(319, TopRow), 15, , &H5555
    EXIT SUB

DrawMidiWindowPortion:
    FOR Count = 0 TO 15
        IF MidiChannel(Count).Playing AND MidiChannel(Count).Active THEN
            Note = 183 - MidiChannel(Count).Note
            LINE (Start, Note)-(Finish, Note), Count * 2 + 48
            '(Note MOD 12) * 2 + 48 alternate coloring
        END IF
    NEXT Count
RETURN

END SUB

SUB CheckMidiHeader (FileHandle, MidiFilePos&, HeaderError)

STATIC TrackHeader AS TrackHeaderType

GET FileHandle, FileBase&, MidiHeader

FlipEndianLong MidiHeader.Length
FlipEndianInt MidiHeader.Format
FlipEndianInt MidiHeader.Tracks
FlipEndianInt MidiHeader.Ticks

HeaderError = 0
PRINT "File:   "; MusicFile$
PRINT "Size:  "; LOF(FileHandle)
PRINT "Header: "; MidiHeader.Id
PRINT "Length:"; MidiHeader.Length; "bytes"
IF MidiHeader.Id = "MThd" AND MidiHeader.Length = 6 THEN
    'if MidiHeader.Length =
    PRINT "Format:"; MidiHeader.Format
    IF MidiHeader.Tracks <> 1 THEN
        Text$ = "(can only play one)"
    END IF
    PRINT "Tracks:"; MidiHeader.Tracks; Text$
    PRINT "Ticks: "; MidiHeader.Ticks
    PRINT
    MidiFilePos& = FileBase& + 14
    IF DesiredTrack >= MidiHeader.Tracks THEN LastTrack = MidiHeader.Tracks - 1 ELSE LastTrack = DesiredTrack
    FOR Track = 0 TO LastTrack - 1
        GET FileHandle, MidiFilePos&, TrackHeader
        FlipEndianLong TrackHeader.Length
        MidiFilePos& = MidiFilePos& + TrackHeader.Length + 8
    NEXT Track
ELSE
    PRINT "Not a midi file."
    HeaderError = 1
END IF

END SUB

SUB FlipEndianInt (Num)

'TempNum$ = MKI$(Num)
'MID$(TempNum$, 1, 1) = MID$(TempNum$, 2, 1)
'MID$(TempNum$, 2, 1) = CHR$(Num AND 255)
'Num = CVI(TempNum$)

Num = CVI(MKL$(((Num AND 255) * 256) OR (Num AND 65280) \ 256))

END SUB

SUB FlipEndianLong (Num&)

Text$ = MKL$(Num&)
Text$ = MID$(Text$, 4, 1) + MID$(Text$, 3, 1) + MID$(Text$, 2, 1) + MID$(Text$, 1, 1)
Num& = CVL(Text$)

END SUB

SUB LoadMidiEvents (FileHandle, MidiFilePos&)

STATIC TrackHeader AS TrackHeaderType

GET FileHandle, MidiFilePos&, TrackHeader
FlipEndianLong TrackHeader.Length
MidiLength = TrackHeader.Length
IF MidiLength > 65536 THEN MidiLength = 65536: Text$ = "(will only load 65536 bytes)" ELSE Text$ = ""

PRINT "Track:  "; TrackHeader.Id
PRINT "Length:"; TrackHeader.Length; Text$
PRINT "Loading MIDI file.";

Dest = 0
LastDest = (MidiLength + 3) \ 4
DO UNTIL Dest >= LastDest
    GET FileHandle, , FileBuffer
    Source = 1
    Count = FileBufferSize \ 4
    DO
        MidiEvents(Dest) = CVL(MID$(FileBuffer, Source, 4))
        MidiEvents(Dest + 1) = CVL(MID$(FileBuffer, Source + 4, 4))
        Source = Source + 8: Dest = Dest + 2: Count = Count - 2
    LOOP WHILE Count
    PRINT ".";
    IF INKEY$ = CHR$(27) THEN EXIT DO
LOOP
PRINT

END SUB

SUB PlayMidi (WindowDeltaTime, CommandDeltaTime, CommandPos AS LONG)

DIM CurrentDeltaTime AS LONG, DeltaTime AS LONG

'default is that 9-15 are off, since they are often so annoying
FOR Count = 0 TO 8
    MidiChannel(Count).Active = True
NEXT Count

CLS
'LINE (0, 0)-(319, 199), 7, BF
GOSUB DisplayActiveChannels

DEF SEG = VARSEG(MidiEvents(0))

CurrentEventRow = 10
CurrentEventPixelRow = 0
CurrentDeltaTime = CommandDeltaTime
PrePcTime# = TIMER
NeedDeltaTime = True
DO UNTIL CommandPos >= MidiLength
    IF NeedDeltaTime THEN
        GOSUB GetDeltaTime
        NextPcTime# = PrePcTime# + DeltaTime& / PlaySpeed
        NeedDeltaTime = False
    END IF
    IF TIMER >= NextPcTime# THEN
        LOCATE 25, 1
        CurrentDeltaTime = CurrentDeltaTime + DeltaTime&
        PRINT STR$(CurrentDeltaTime); ":"; TAB(10);
        GOSUB DoCommand
        IF TIMER - NextPcTime# > 1 THEN
            PrePcTime# = TIMER
        ELSE
            PrePcTime# = NextPcTime#
        END IF
        AdvanceMidiWindow MidiWindowRowCount, DeltaTime&
        NeedDeltaTime = True
        'LOCATE CurrentEventRow, 1: PRINT "";
        'IF SignificantChange = True THEN
        '    SignificantChange = False
        'END IF
        'RunCount = RunCount - 1
        'IF RunCount <= 0 THEN
        '    DO: Key$ = INKEY$: LOOP UNTIL LEN(Key$)
        '    IF Key$ = CHR$(27) THEN EXIT DO
        '    IF Key$ = CHR$(0) + "M" THEN RunCount = 16 ELSE RunCount = 1
        'END IF
        'LOCATE CurrentEventRow, 1: PRINT " ";
        'CurrentEventRow = CurrentEventRow + 1: IF CurrentEventRow >= 20 THEN CurrentEventRow = 10
    END IF
    Key$ = INKEY$
    IF LEN(Key$) THEN
        Key$ = UCASE$(Key$)
        SELECT CASE Key$
        CASE "0" TO "9"
            Count = ASC(Key$) - 48
            MidiChannel(Count).Active = MidiChannel(Count).Active XOR True
            GOSUB DisplayActiveChannels
        CASE "A" TO "F"
            Count = ASC(Key$) - 55
            MidiChannel(Count).Active = MidiChannel(Count).Active XOR True
            GOSUB DisplayActiveChannels
        CASE CHR$(27)
            EXIT DO
        CASE " "
            NextPcTime# = TIMER
        END SELECT
    END IF
LOOP
EXIT SUB

GetDeltaTime:
    Byte = PEEK(CommandPos)                    'at least one byte long
    CommandPos = CommandPos + 1
    IF Byte AND 128 THEN
        DeltaTime& = (Byte AND 127) * 128
        Byte = PEEK(CommandPos)                'at least two bytes long
        CommandPos = CommandPos + 1
        IF Byte AND 128 THEN
            DeltaTime& = (DeltaTime& OR (Byte AND 127)) * 128
            Byte = PEEK(CommandPos)            'at least three bytes long
            CommandPos = CommandPos + 1
            IF Byte AND 128 THEN
                DeltaTime& = (DeltaTime& OR (Byte AND 127)) * 128 OR PEEK(CommandPos)
                CommandPos = CommandPos + 1
            ELSE
                DeltaTime& = DeltaTime& OR Byte 'three bytes long
            END IF
        ELSE
            DeltaTime& = DeltaTime& OR Byte     'two bytes long
        END IF
    ELSE
        DeltaTime& = Byte                       'one byte long
    END IF
    'PRINT STR$(DeltaTime&); ":"; TAB(10);
RETURN

DoCommand:
    IF CommandPos > 65533 THEN RETURN
    Byte = PEEK(CommandPos)
    IF Byte AND 128 THEN Command = Byte \ 16: Channel = Byte AND 15: CommandPos = CommandPos + 1
    SELECT CASE Command
    CASE MidiNoteOff
        MidiChannel(Channel).Playing = 0
        MidiChannel(Channel).Release = PEEK(CommandPos + 1)
        Note = PEEK(CommandPos)
        MidiChannel(Channel).Note = Note
        SignificantChange = True
        CommandPos = CommandPos + 2
        PRINT "off"; Channel; ":"; MidiChannel(Channel).Note;
        GOSUB TurnOff
    CASE MidiNoteOn
        MidiChannel(Channel).Playing = 1
        MidiChannel(Channel).Depress = PEEK(CommandPos + 1)
        Note = PEEK(CommandPos + 0)
        MidiChannel(Channel).Note = Note
        SignificantChange = True
        CommandPos = CommandPos + 2
        PRINT "on "; Channel; ":"; MidiChannel(Channel).Note;
        GOSUB TurnOn
    CASE MidiKeyAfterTouch
        'MidiChannel(Channel).Note = PEEK(CommandPos + 0)
        'MidiChannel(Channel).Depress = PEEK(CommandPos + 1)
        'SignificantChange = True
        CommandPos = CommandPos + 2
    CASE MidiControlChange
        PRINT "Control change"; Channel;
        CommandPos = CommandPos + 2
    CASE MidiPitchChange
        PRINT "Pitch set/change"; Channel;
        CommandPos = CommandPos + 2
    CASE MidiPatchChange
        PRINT "Program change"; Channel;
        CommandPos = CommandPos + 1
    CASE MidiChannelAfterTouch
        CommandPos = CommandPos + 1
    'CASE MidiPitchChange
    CASE MidiMetaEvent
        IF Byte = 255 THEN
            'move forward by number of bytes in data plus the meta-event
            'signature, event command, and byte count.
            Byte = PEEK(CommandPos)
            SELECT CASE Byte
            CASE 1: PRINT "Text"
            CASE 3: PRINT "Track name";
            CASE &H2F
                'PRINT "End of track";
                DO UNTIL LEN(INKEY$): LOOP
            CASE &H51: PRINT "Set tempo";
            CASE &H58: PRINT "Time signature";
            CASE &H59: PRINT "Key signature";
            END SELECT
            CommandPos = CommandPos + 2 + PEEK(CommandPos + 1)
        END IF
    END SELECT
    PRINT TAB(30);
    'GOSUB SeekNextEvent
RETURN

SeekNextEvent:
    'DO UNTIL CommandPos >= MidiLength OR (PEEK(CommandPos) AND 128)
    '    CommandPos = CommandPos + 1
    'LOOP
    IF CommandPos >= MidiLength THEN RETURN
SeekNextMsb:
    IF PEEK(CommandPos) AND 128 THEN RETURN
    CommandPos = CommandPos + 1
    IF CommandPos < MidiLength GOTO SeekNextMsb
RETURN

TurnOn:
    IF MidiChannel(Channel).Active THEN
        LINE (Note, 0)-(Note, 4), Channel * 2 + 48
        'SOUND 0, 0
        'SOUND FreqTable(Note) \ 128, 10
        Reg = Channel AND 1
        SbDataOut &HB0 + Reg, &H0'    Turn the voice off; set the octave and freq MSB
        SbDataOut &HA0 + Reg, FreqTable(Note) AND 255'    Set voice frequency's LSB (it'll be a D#)
        SbDataOut &HB0 + Reg, FreqTable(Note) \ 256 OR &H20'    Turn the voice on; set the octave and freq MSB
    END IF
RETURN

TurnOff:
    IF MidiChannel(Channel).Active THEN
        LINE (Note, 0)-(Note, 4), 0
        'SOUND 0, 0
        'SbDataOut &HB0, &H1'    Turn the voice off; set the octave and freq MSB
    END IF
RETURN

DisplayActiveChannels:
    LOCATE 24, 1
    ColorCount = 48
    FOR Count = 0 TO 15
        COLOR ColorCount
        ColorCount = ColorCount + 2
        IF MidiChannel(Count).Active THEN
            PRINT MID$("0123456789ABCDEF", Count + 1, 1);
        ELSE
            PRINT "ù";
        END IF
    NEXT Count
RETURN

END SUB

SUB SbDataOut (Register, Value)
    OUT SbPortBase, Register
    Dummy = INP(SbPortBase)
    Dummy = INP(SbPortBase)
    Dummy = INP(SbPortBase)
    OUT SbPortBase + 1, Value
END SUB

