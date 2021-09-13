'added use of up to eight channels
'moved advance window to after second get delta time
DEFINT A-Z
DECLARE SUB FlipEndianInt (Num%)
DECLARE SUB FlipEndianLong (Num&)
DECLARE SUB CheckMidiHeader (FileHandle%, MidiFilePos&, HeaderError%)

CONST True = -1, False = 0
CONST FileBufferSize = 8192, FileBase& = 1

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

TYPE RegType
Ax AS INTEGER: Bx AS INTEGER: Cx AS INTEGER: Dx AS INTEGER
bp AS INTEGER: si AS INTEGER: di AS INTEGER: fl AS INTEGER
Ds AS INTEGER: es AS INTEGER
END TYPE

DIM SHARED FileBuffer AS STRING
DIM SHARED MidiHeader AS MidiHeaderType, TrackHeader AS TrackHeaderType
DIM SHARED MidiLength AS LONG
DIM SHARED Regs AS RegType


InpFile$ = COMMAND$ + ".xmi"
OutFile$ = COMMAND$ + ".mid"

OPEN InpFile$ FOR INPUT AS 1: CLOSE 1
OPEN InpFile$ FOR BINARY AS 1
OPEN OutFile$ FOR OUTPUT AS 2: CLOSE 2
OPEN OutFile$ FOR BINARY AS 2

InpFileLen = LOF(1)
PRINT "XMI to MIDI (2000.12.10)"
PRINT "Opened input " + InpFile$ + STR$(InpFileLen) + " bytes"
PRINT "Opened output " + OutFile$

'GET FileHandle, FileBase&, MidiHeader

MidiHeader.Id = "MThd"
MidiHeader.Length = 6: FlipEndianLong MidiHeader.Length
MidiHeader.Format = 0: FlipEndianInt MidiHeader.Format
MidiHeader.Tracks = 1: FlipEndianInt MidiHeader.Tracks
MidiHeader.Ticks = 120: FlipEndianInt MidiHeader.Ticks
PUT #2, , MidiHeader
TrackHeader.Id = "MTrk"
TrackHeader.Length = InpFileLen
FlipEndianLong TrackHeader.Length
PUT #2, , TrackHeader
FOR Count = 1 TO InpFileLen STEP FileBufferSize
    FileBuffer = INPUT$(FileBufferSize, 1)
    PUT #2, , FileBuffer
NEXT

PRINT "Done"
CLOSE 1, 2

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

