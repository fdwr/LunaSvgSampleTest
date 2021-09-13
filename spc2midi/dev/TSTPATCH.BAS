'Test Patch 2000.12.12
'by Peekin (Dwayne Robinson)
'
'Used to play FM patch sounds. It does not create or edit patches, only load
'existing ones.
'
DEFINT A-Z
DECLARE SUB ResetSb ()
DECLARE SUB SbFmWrite (Register, Value)
DECLARE SUB SbDspWrite (Value%)
DECLARE SUB SetInsPatch (Channel, Instrument)
DECLARE SUB MpuReset ()
DECLARE SUB MpuWrite (Values AS STRING)
DECLARE FUNCTION MpuWait (Value)

CONST SbPort = &H220, FmPort = &H388, MpuPort = &H300
CONST SbPortReset = &H6, SbPortWrite = &HC, SbPortRead = &HA, SbPortRStatus = &HE
CONST MpuPortData = 0, MpuPortCmd = 1, MpuPortStatus = 1
CONST SbCmdMidiOut = &H38, MpuCmdReset = &HFF, MpuCmdUart = &H3F, MpuCmdAck = &HFE
CONST MidiNoteOff = &H80, MidiNoteOn = &H90, MidiKeyAfterTouch = &HA0
CONST MidiControlChange = &HB0, MidiPatchChange = &HC0, MidiAfterTouch = &HD0
CONST MidiPitchChange = &HE0, MidiMetaEvent = &HF0
CONST MaxInstruments = 256

CONST PatchFile$ = "tstpatch.dat", PatchFileInsWidth = 16
           
TYPE SbChannelType
Note       AS INTEGER
Instrument AS INTEGER
Reg        AS INTEGER
END TYPE

DIM SHARED SbFnumberTable(127), SbChannels(8) AS SbChannelType
DIM SHARED InstrumentPatches(MaxInstruments - 1, 16), PatchTable(15)
DIM SHARED MpuEnabled

DIM InstrumentNames(127) AS STRING
DIM KeysDown(127)
DIM KeypressNoteLut(127)

GOSUB Init
GOSUB LoadPatches
MpuReset

SCREEN 13

GOSUB ShowActiveChannels
GOSUB ShowActiveInstrument
GOSUB ShowNoteStrip
GOSUB ShowPatchAttributes
GOSUB ShowPatchMapping

DO
    Keypress = INP(96)
    IF Keypress <> LastKeypress THEN
        'do:print inp(96);:loop until inkey$=chr$(27)
        SELECT CASE Keypress
        CASE 1: EXIT DO
        CASE 77: Instrument = (Instrument + 1) MOD TotalInstruments: GOSUB ShowActiveInstrument: GOSUB ShowPatchMapping
        CASE 75: Instrument = (Instrument + TotalInstruments - 1) MOD TotalInstruments: GOSUB ShowActiveInstrument: GOSUB ShowPatchMapping
        CASE 73: Instrument = (Instrument + 16) MOD TotalInstruments: GOSUB ShowActiveInstrument: GOSUB ShowPatchMapping
        CASE 81: Instrument = (Instrument + TotalInstruments - 16) MOD TotalInstruments: GOSUB ShowActiveInstrument: GOSUB ShowPatchMapping
        CASE 71: Instrument = (Instrument XOR 128) MOD TotalInstruments: GOSUB ShowActiveInstrument: GOSUB ShowPatchMapping
        CASE 80: PatchIndex = (PatchIndex + 1) AND 15: GOSUB ShowPatchMapping
        CASE 72: PatchIndex = (PatchIndex - 1) AND 15: GOSUB ShowPatchMapping
        CASE 83: NewPatchIndex = (PatchIndex + 1) AND 15: GOSUB SwapPatchAttribs
        CASE 82: NewPatchIndex = (PatchIndex - 1) AND 15: GOSUB SwapPatchAttribs
        CASE 78: Inc = 4: GOSUB AdjustPatchAttrib
        CASE 74: Inc = -4: GOSUB AdjustPatchAttrib
        CASE 60: GOSUB SavePatches
        CASE 28
            IF DemoPlaying THEN
                FOR VoiceCount = 0 TO 8
                    Note = SbChannels(VoiceCount).Note
                    IF Note >= 0 THEN GOSUB NoteOff
                NEXT
                GOSUB ShowActiveChannels
                DemoPlaying = 0
            ELSE
                DemoPlaying = 1
            END IF
        CASE ELSE
            IF KeysDown(Keypress AND 127) <> Keypress THEN
                Note = KeypressNoteLut(Keypress AND 127)
                IF Note <> 255 THEN
                    IF Keypress AND 128 THEN
                        GOSUB NoteOff
                        GOSUB ShowActiveChannels
                    ELSE
                        GOSUB NoteOn
                        GOSUB ShowActiveChannels
                    END IF
                END IF
            END IF
        END SELECT
        KeysDown(Keypress AND 127) = Keypress
    END IF
    LastKeypress = Keypress
    Key$ = INKEY$

    IF DemoPlaying THEN
        IF DemoPlaying = 1 THEN
            RESTORE SongDemoData
            READ TimeWait
            DEF SEG = 0
            LastTime = PEEK(&H46C)
            DemoPlaying = 2
        END IF
        IF (PEEK(&H46C) - LastTime AND 255) >= TimeWait THEN
            LastTime = LastTime + TimeWait
            READ Note, TimeWait
            IF Note < 0 THEN
                Note = -Note
                GOSUB NoteOff
            ELSE
                GOSUB NoteOn
            END IF
            GOSUB ShowActiveChannels
            IF TimeWait < 0 THEN DemoPlaying = 1
        END IF
    END IF
LOOP

FOR Count = 0 TO 8
    SbFmWrite &HB0 + Count, &H0   'turn the voice off
NEXT
IF MpuEnabled THEN IF MpuWait(64) THEN OUT MpuPort + MpuPortCmd, MpuCmdReset

WIDTH 80, 25
END

Init:
    'Build sound card fnumber table
    Pitch# = 14080 * .9438743126816935# 'A10 * semitone-constant = Gb10
    Octave = 7
    FOR Count = 127 TO 0 STEP -1
        Pitch# = Pitch# * .9438743126816935#
GetFnumber:
        SbFnumber = Pitch# * (2 ^ (20 - Octave)) / 49716
        IF SbFnumber > 1023 THEN
            'clip any notes to high
            SbFnumberTable(Count) = &H1FFF
        ELSE
            IF SbFnumber < 512 AND Octave > 0 THEN
                'if fnumber is below the range of 512-1023 then move octave down
                '(which sets fnumber back into the range)
                Octave = Octave - 1
                GOTO GetFnumber
            END IF
            SbFnumberTable(Count) = SbFnumber OR (Octave * 1024)
        END IF
    NEXT

    RESTORE ChannelRegData
    FOR Count = 0 TO 8
        SbChannels(Count).Note = -1
        SbChannels(Count).Instrument = -1
        READ SbChannels(Count).Reg
    NEXT

    FOR Count = 0 TO 15
        PatchTable(Count) = Count
    NEXT

    FOR Count = 0 TO 127
        KeypressNoteLut(Count) = 255
    NEXT
    FOR Count = 2 TO 14
        KeypressNoteLut(Count) = Count + 79
    NEXT
    FOR Count = 16 TO 27 'QWE...P[]
        KeypressNoteLut(Count) = Count + 53
    NEXT
    FOR Count = 16 TO 27 'QWE...P[]
        KeypressNoteLut(Count) = Count + 53
    NEXT
    FOR Count = 30 TO 40 'ASD...L;'
        KeypressNoteLut(Count) = Count + 27
    NEXT
    FOR Count = 44 TO 53 'ASD...L;'
        KeypressNoteLut(Count) = Count + 1
    NEXT

    RESTORE InstrumentNamesData
    FOR Count = 0 TO 127
        READ InstrumentNames(Count)
    NEXT

    SbFmWrite 1, &H20 'allow different waveforms
    SbFmWrite &H8, 0  'disable sine wave speech
    SbFmWrite &HBD, &HC 'disable rhythm mode, AM depth=4.8db, Vibrato=14cent
RETURN

LoadPatches:
    GOSUB CatchErr
    OPEN PatchFile$ FOR INPUT AS 1: CLOSE 1
    ON ERROR GOTO 0
    TotalInstruments = 0
    IF ErrHandled = 0 THEN
        OPEN PatchFile$ FOR BINARY AS 1
        FileBuffer$ = SPACE$(PatchFileInsWidth)
        DO UNTIL TotalInstruments >= MaxInstruments
            GET 1, , FileBuffer$
            IF EOF(1) THEN EXIT DO
            FOR Count = 0 TO PatchFileInsWidth - 1
                InstrumentPatches(TotalInstruments, Count) = ASC(MID$(FileBuffer$, Count + 1, 1))
            NEXT
            TotalInstruments = TotalInstruments + 1
        LOOP
        CLOSE 1
    ELSE
        RESTORE DefaultPatch
        FOR Count = 0 TO 7
            READ InstrumentPatches(0, Count)
        NEXT
    END IF
    IF TotalInstruments < 1 THEN TotalInstruments = 1
RETURN

SavePatches:
    FileBuffer$ = SPACE$(16)
    OPEN PatchFile$ FOR OUTPUT AS 1: CLOSE 1
    OPEN PatchFile$ FOR BINARY AS 1
    FOR TotalInstruments = 0 TO TotalInstruments - 1
        FOR Count = 0 TO 15
            MID$(FileBuffer$, Count + 1, 1) = CHR$(InstrumentPatches(TotalInstruments, PatchTable(Count)))
        NEXT
        PUT 1, , FileBuffer$
    NEXT
    CLOSE 1
    FOR Count = 0 TO 15
        PatchTable(Count) = Count
    NEXT
    GOSUB ShowPatchMapping
RETURN

NoteOn:
    COLOR 60
    LOCATE 1, 1: PRINT "On: "; Note;
    LINE (Note * 2, 8)-(Note * 2 + 1, 15), (Note MOD 12) * 2 + 48, BF

    FOR Count = 0 TO 8
        IF SbChannels(Count).Note < 0 THEN
            SbChannels(Count).Note = Note
            IF SbChannels(Count).Instrument <> Instrument THEN
                SbChannels(Count).Instrument = Instrument
                SetInsPatch Count, Instrument
                IF MpuEnabled THEN MpuWrite CHR$(0) + CHR$(MidiPatchChange OR Count) + CHR$(Instrument)
            END IF
            SbFmWrite &HA0 + Count, SbFnumberTable(Note) AND 255       'Set voice frequency's LSB
            SbFmWrite &HB0 + Count, SbFnumberTable(Note) \ 256 OR &H20 'Set the octave and freq MSB, 20h turns the voice on
            IF MpuEnabled THEN MpuWrite CHR$(0) + CHR$(MidiNoteOn OR Count) + CHR$(Note) + "'"
            EXIT FOR
        END IF
    NEXT Count
RETURN

NoteOff:
    COLOR 54
    LOCATE 1, 1: PRINT "Off:"; Note;
    LINE (Note * 2, 8)-(Note * 2 + 1, 15), 0, BF
    LINE (Note * 2, 12)-(Note * 2 + 1, 12), (Note MOD 12) * 2 + 48
   
    FOR Count = 0 TO 8
        IF SbChannels(Count).Note = Note THEN
            SbChannels(Count).Note = -1
            'SbFmWrite &HB0 + Count, &H0   'turn the voice off
            SbFmWrite &HB0 + Count, SbFnumberTable(Note) \ 256 'turn voice off without clicking noise
            IF MpuEnabled THEN MpuWrite CHR$(0) + CHR$(MidiNoteOff OR Count) + CHR$(Note) + "'"
        END IF
    NEXT Count
RETURN

AdjustPatchAttrib:
    Count = PatchTable(PatchIndex)
    InstrumentPatches(Instrument, Count) = (InstrumentPatches(Instrument, Count) + Inc) AND 255
    FOR Count = 0 TO 8
        SbChannels(Count).Instrument = -1
    NEXT
GOTO ShowPatchMapping

SwapPatchAttribs:
    SWAP PatchTable(PatchIndex), PatchTable(NewPatchIndex)
    FOR Count = 0 TO 8
        SbChannels(Count).Instrument = -1
    NEXT
    PatchIndex = NewPatchIndex
GOTO ShowPatchMapping

ShowActiveChannels:
    LOCATE 1, 10
    ColorCount = 48
    FOR Count = 0 TO 8
        COLOR ColorCount
        IF SbChannels(Count).Note < 0 THEN
            PRINT "ù";
        ELSE
            PRINT MID$("123456789", Count + 1, 1);
        END IF
        ColorCount = ColorCount + 3
    NEXT Count
RETURN

ShowActiveInstrument:
    COLOR 59
    LOCATE 3, 1
    PRINT Instrument; InstrumentNames(Instrument AND 127); TAB(30);
RETURN

ShowNoteStrip:
    FOR Count = 0 TO 255 STEP 2
        PSET (Count, 12), Count MOD 24 + 48
        PSET (Count + 1, 12), Count MOD 24 + 48
    NEXT
RETURN

ShowPatchAttributes:
    COLOR 59
    LOCATE 4
    PRINT "AmpMod/Vib/Eg/KeyScl/Mult Mod 20="
    PRINT "AmpMod/Vib/Eg/KeyScl/Mult Car 23="
    PRINT "KeyScale/Volume Mod           40="
    PRINT "KeyScale/Volume Car           43="
    PRINT "Attack/Decay Mod              60="
    PRINT "Attack/Decay Car              63="
    PRINT "Sustain/Release Mod           80="
    PRINT "Sustain/Release Car           83="
    PRINT "Wave Select Mod               E0="
    PRINT "Wave Select Car               E3="
    PRINT "Feedback/Connection Both      C0="
RETURN

ShowPatchMapping:
    FOR Count = 0 TO 15
        IF Count = PatchIndex THEN COLOR 15 ELSE COLOR 54
        LOCATE Count + 5, 35
        PRINT RIGHT$("0" + HEX$(InstrumentPatches(Instrument, PatchTable(Count))), 2); PatchTable(Count);
    NEXT
RETURN

CatchErr:
    ErrHandled = 0
    ON ERROR GOTO ErrHandler
RETURN

ErrHandler:
    ErrHandled = ERR
RESUME NEXT

ChannelRegData:
DATA 0,1,2,8,9,10,16,17,18

DefaultPatch:
'Set the modulator's multiple to 1
'Set the modulator's level to about 40 dB
'Modulator attack: quick;   decay: long
'Modulator sustain: medium;  release: medium
'Set the carrier's multiple to 1
'Set the carrier to maximum volume (0 = about 47 dB)
'Carrier attack:  quick;   decay:   long
'Carrier sustain: medium;  release: medium
'DATA &H2,&H10,&H99,&H88,&H1,0,&H74,&HFF
DATA &H2,&H1,&H10,0,&H99,&H74,&H88,&HFF

InstrumentNamesData:
'Piano, Chromatic Percussion, Organ, Guitar, Bass, Solo Strings, Ensemble, Reed, Pipe, Synth Lead, Synth Pad, Synth Effects, Ethnic, Percussive, Sound Effects
DATA "Acoustic Grand","Bright Acoustic","Electric Grand","Honky-Tonk","Electric Piano 1","Electric Piano 2","Harpsichord","Clavinet"
DATA "Celesta","Glockenspiel","Music Box","Vibraphone","Marimba","Xylophone","Tubular Bells","Dulcimer"
DATA "Drawbar Organ","Percussive Organ","Rock Organ","Church Organ","Reed Organ","Accordian","Harmonica","Tango Accordian"
DATA "Nylon String Guitar","Steel String Guitar","Electric Jazz Guitar","Electric Clean Guitar","Electric Muted Guitar","Overdriven Guitar","Distortion Guitar","Guitar Harmonics"
DATA "Acoustic Bass","Electric Bass (finger)","Electric Bass (pick)","Fretless Bass","Slap Bass 1","Slap Bass 2","Synth Bass 1","Synth Bass 2"
DATA "Violin","Viola","Cello","Contrabass","Tremolo Strings","Pizzicato Strings","Orchestral Strings","Timpani"
DATA "String Ensemble 1","String Ensemble 2","SynthStrings 1","SynthStrings 2","Choir Aahs","Voice Oohs","Synth Voice","Orchestra Hit"
DATA "Trumpet","Trombone","Tuba","Muted Trumpet","French Horn","Brass Section","SynthBrass 1","SynthBrass 2"
DATA "Soprano Sax","Alto Sax","Tenor Sax","Baritone Sax","Oboe","English Horn","Bassoon","Clarinet"
DATA "Piccolo","Flute","Recorder","Pan Flute","Blown Bottle","Skakuhachi","Whistle","Ocarina"
DATA "Lead 1 (square)","Lead 2 (sawtooth)","Lead 3 (calliope)","Lead 4 (chiff)","Lead 5 (charang)","Lead 6 (voice)","Lead 7 (fifths)","Lead 8 (bass+lead)"
DATA "Pad 1 (new age)","Pad 2 (warm)","Pad 3 (polysynth)","Pad 4 (choir)","Pad 5 (bowed)","Pad 6 (metallic)","Pad 7 (halo)","Pad 8 (sweep)"
DATA "FX 1 (rain)","FX 2 (soundtrack)","FX 3 (crystal)","FX 4 (atmosphere)","FX 5 (brightness)","FX 6 (goblins)","FX 7 (echoes)","FX 8 (sci-fi)"
DATA "Sitar","Banjo","Shamisen","Koto","Kalimba","Bagpipe","Fiddle","Shanai"
DATA "Tinkle Bell","Agogo","Steel Drums","Woodblock","Taiko Drum","Melodic Tom","Synth Drum","Reverse Cymbal"
DATA "Guitar Fret Noise","Breath Noise","Seashore","Bird Tweet","Telephone Ring","Helicopter","Applause","Gunshot"

SongDemoData:
'Mary had a little lamb
DATA 0,76, 4,74, 0,-76, 4,72, 0,-74, 4,74, 0,-72, 4,-74, 0,76, 4,-76, 0,76, 4,-76, 0,76, 8,-76
DATA 0,74, 4,-74, 0,74, 4,-74, 0,74, 8,-74, 0,76, 4,79, 0,-76, 4,-79, 0,79, 8,-79
DATA 0,76, 4,74, 0,-76, 4,72, 0,-74, 4,74, 0,-72, 4,-74, 0,76, 4,-76, 0,76, 4,-76, 0,76, 4,-76, 0,76, 4,-76
DATA 0,74, 4,-74, 0,74, 4,-74, 0,76, 4,-76, 0,74, 4,-74, 0,72, 16,-72
'Little clip from Star Wars
DATA 0,69, 7,-69, 1,69, 2,74, 16,-74, 0,76, 16,-76, 0,77, 2,-77, 0,79, 2,-79, 0,77, 0,-69, 20,-77
DATA 0,69, 7,-69, 1,69, 2,74, 16,-74, 0,76, 4,-76, 0,77, 4,-77, 0,74, 4,-74, 0,77, 3,-77, 0,74, 3,-74, 0,81, 3,-81, 0,79, 16,-79, 0,57, 0,69, 16,-57, 0,-69
'end of demo
DATA -1

SUB MpuReset
    IF MpuWait(64) THEN
        OUT MpuPort + MpuPortCmd, MpuCmdReset
        IF MpuWait(128) THEN
            IF INP(MpuPort + MpuPortData) = MpuCmdAck THEN
                IF MpuWait(64) THEN
                    OUT MpuPort + MpuPortCmd, MpuCmdUart
                    IF MpuWait(128) THEN
                        IF INP(MpuPort + MpuPortData) = MpuCmdAck THEN MpuEnabled = -1
                    END IF
                END IF
            END IF
        END IF
    END IF
END SUB

FUNCTION MpuWait (Value)
    'waits until either data is ready to be written or data is available to
    'read, depending on the bits set in Value.

    Count = 10000
    DO UNTIL (INP(MpuPort + MpuPortStatus) AND Value) = 0 OR Count <= 0
        Count = Count - 1
    LOOP
    MpuWait = Count
END FUNCTION

SUB MpuWrite (Values AS STRING)
    FOR Count = 1 TO LEN(Values)
        DO UNTIL (INP(MpuPort + MpuPortStatus) AND 64) = 0: LOOP
        OUT MpuPort + MpuPortData, ASC(MID$(Values, Count, 1))
    NEXT
END SUB

SUB ResetSb
    OUT SbPort + SbPortReset, 1: Count = INP(SbPortRead)
    OUT SbPort + SbPortReset, 0: Count = INP(SbPortRead)
    DO UNTIL INP(SbPort + SbPortRStatus) AND 128: LOOP
    IF INP(SbPort + SbPortRead) = &HAA THEN
       'sound card was reset
        SoundEnabled = -1
    END IF
END SUB

SUB SbDspWrite (Value)
    IF SoundEnabled THEN
        DO UNTIL (INP(SbPort + SbPortWrite) AND 128) = 0: LOOP
        OUT SbPort + SbPortWrite, Value
    END IF
END SUB

SUB SbFmWrite (Register, Value)
    OUT FmPort, Register
    Dummy = INP(FmPort): Dummy = INP(FmPort): Dummy = INP(FmPort)
    OUT FmPort + 1, Value
    Dummy = INP(FmPort): Dummy = INP(FmPort): Dummy = INP(FmPort)
    Dummy = INP(FmPort): Dummy = INP(FmPort): Dummy = INP(FmPort)
END SUB

SUB SetInsPatch (Channel, Instrument)

    Reg = SbChannels(Channel).Reg
    SbFmWrite &H20 + Reg, InstrumentPatches(Instrument, PatchTable(0))'Modulator's multiple
    SbFmWrite &H23 + Reg, InstrumentPatches(Instrument, PatchTable(1))'Carrier's multiple to 1
    SbFmWrite &H40 + Reg, InstrumentPatches(Instrument, PatchTable(2))'Modulator's level
    SbFmWrite &H43 + Reg, 0'InstrumentPatches(Instrument, PatchTable(3))'Set the carrier volume
    SbFmWrite &H60 + Reg, InstrumentPatches(Instrument, PatchTable(4))'Modulator attack
    SbFmWrite &H63 + Reg, InstrumentPatches(Instrument, PatchTable(5))'Carrier attack
    SbFmWrite &H80 + Reg, InstrumentPatches(Instrument, PatchTable(6))'Modulator sustain
    SbFmWrite &H83 + Reg, InstrumentPatches(Instrument, PatchTable(7))'Carrier sustain
    'SbFmWrite &HE0 + Reg, InstrumentPatches(Instrument, PatchTable(8)) AND &H3'Carrier sustain
    'SbFmWrite &HE3 + Reg, InstrumentPatches(Instrument, PatchTable(9)) AND &H3'Carrier sustain
    'SbFmWrite &HC0 + Reg, InstrumentPatches(Instrument, PatchTable(10)) AND &HF'Carrier sustain
    SbFmWrite &HE0 + Reg, InstrumentPatches(Instrument, PatchTable(8))'Carrier sustain
    SbFmWrite &HE3 + Reg, InstrumentPatches(Instrument, PatchTable(9))'Carrier sustain
    SbFmWrite &HC0 + Reg, InstrumentPatches(Instrument, PatchTable(10))'Carrier sustain

'2 10 99 88 1 0 f4 ff   chirp whistle
'2 10 88 88 1 0 f4 ff   glass blow
'4 10 aa 88 1 0 f4 88   glock+vibraphone
'1 10 88 33 1 0 c4 44   sitar
'2 10 88 33 1 0 c4 44   carnival
'2 10 f8 44 1 0 c4 44   wood glock+celesta
'3 10 99 88 1 0 75 16   marimba

'db 20h,23h      ;multiplier
'db 40h,43h      ;level
'db 60h,63h      ;attack/decay
'db 80h,83h      ;sustain/release
'db 0E0h,0E3h    ;waveform
'db 0C0h         ;feedback
'db 0            ;null (end)

END SUB

