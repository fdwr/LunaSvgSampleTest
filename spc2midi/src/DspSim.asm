; Spc2Midi - DSP Simulation (Wave/Sine/FM/MPU/GM/MIDI)
;
; Note these functions perform completely asynchronous to emulation (which
; can be found in spcemu.asm and dspemu.asm). They simply simulate the sound
; output. This allows the song position to be easily and (very quickly) be
; changed, without worrying about how it might affect the SPC700 code. The
; song position pointer can be instantly set to the front, back, or anywhere
; in between. It can even be played backwards (while emulation continues
; forward).
;
; Song positions are stored in structures that hold the complete state for
; that instant in time, tick count, state of each DSP register, and volumes
; and pitches for each voice. Each type of sound output has its own structure
; so they can function independantally.
;
; InitDspSim - initializes DSP simulation structures and flags
; PlaySounds - coordinates calling the other functions
; SeekSongPos - seeks in the buffer to a given tick time count
; SeekSongPos.Init - initializes a song position structure
; SeekSongPos.Copy - copies one song pos structure to another
; SeekSongPos.SetGivenKeys - sets volumes/instruments/pitches
; VoiceEmu - emulates DSP audio output (greatly simplified sample mixing)
; FmEmu - simulates DSP output with FM synthesis
; GmEmu - uses internal General MIDI synthesizer
; MpuEmu - sends equivalent MIDI commands through MPU (external MIDI port)
; SineEmu - simulates DSP output with sine waves rather than audio samples
; SampleEmu - plays a solo sample (can merge simultaneously with VoiceEmu)
; GenerateSquareWave - plays constant square wave
; GenerateSineWave - plays constant sine wave
; OutputMidiFile - outputs DSP register writes to MIDI events
;
; Highly dependant on variables defined in dspemu.asm, sound.asm, & midi.asm
;
; todo:
;   zoom.spc missing sounds
;   kingarth.zst voices 4&5 almost silent, may need inc envelope
;   TOP fiddler's theme sounds off pitch
;   Lemmings Tim 12 - 2 voice 5 should sound percussive because uses noise
;   happy.sp3 voice 3 clicks on sine wave emu
;   rudora~1.spc smp#14 clicks badly when paused/unpaused
;   check mine cart carnage static voice v7
;   add some form of interpolation
;   figure out why dkcfunky.spc sample #34 sounds so bad playrate 3164 22khz  (b20 Ad5 A60 937)
;
; fixed:
;   figured out why VoiceEmu stalls half a second when rewinding
;   discovered clicking in some voices had nothing do with DSP emulation
;    after all, but a peculiarity of the Crystal Audio sound card.
;   synced emulator timing to real SNES timing near exactly by putting
;    the two side by side
;   verified correct pitch by listening to the real thing some
;   average left & volume instead of only using left volume, so voices that
;    only use right volume will not be silent (terra.sp3 voice 5)
;
;
;-----------------------------------------------------------------------------
; Global structures
;-------------------

section data
align 2, db 0
HertzTbl:           incbin "gm2hzlut.dat"   ;130 words of nearest pitches
HertzNoteRle:       incbin "hz2gmlut.dat"   ;word rle encoded
%ifdef DosVer       ;FM only for DOS
 GmFnumberTbl:      incbin "gm2fnlut.dat"
 HertzFnumberTbl:   incbin "hz2fnlut.dat"
%endif
SineWaveTbl:        incbin "sinewave.dat"   ;1024 sample values
section bss
alignb 4
;MaxHertz           equ 12543
HertzNoteTbl:       resb MaxHertz*2+1  ;to convert frequency in hertz to MIDI note (0-127)

struc SongPos
; These structures hold note information for the current time position in the
; song. That info includes the pitch, volume, key on status, and sample
; number of each voice, along with an complete copy of DSP RAM. The static
; structure is updated after each emulation run and is used mainly by the
; different display modes to reflect the notes playing to the screen. The
; real time structure is used by the sound playing interrupt routine. The
; reason why there are separate structures is so that each can be independant
; of each other. MPU output is not dependant on wave output. FM output is not
; dependant on the visual display. Also, it would be a mess if the sound
; routine messed up the display window right in the middle of redrawing.
.DspRegs:           resb 128
.Pos:               resd 1      ;index to current DSP command in buffer
.Time:              resd 1      ;tick time the structure is positioned at
.Active:            equ 4Ch     ;voices currently on (same as DSP register)
.Enabled:           resb 1      ;voices enabled, not muted
                    resb 1      ;(alignment)
.Heard:             resb 2      ;voices active that are not muted
.Changed:                       ;byte group, voices that have changed on/off
.Kon:               resb 1      ;voices keyed on (Kon & Kof must be grouped!)
.Kof:               resb 1      ;voices keyed off
.Ton:               resb 1      ;voices toggled on (Ton & Tof must be grouped!)
.Tof:               resb 1      ;voices toggled off
.Pitch:             resb 8      ;current note of each voice
.Instrument:        resd 8      ;current instruments
.Volume:            resd 8      ;combined volumes of left & right channels
endstruc

%macro NewSongPos 1
alignb 4
%1:
.DspRegs            equ $+SongPos.DspRegs
.Pos                equ $+SongPos.Pos
.Time               equ $+SongPos.Time
.Active             equ $+SongPos.Active
.Enabled            equ $+SongPos.Enabled
.Heard              equ $+SongPos.Heard
.Changed            equ $+SongPos.Changed
.Kon                equ $+SongPos.Kon   ;Kon/Kof|Ton/Tof must be grouped!
.Kof                equ $+SongPos.Kof
.Ton                equ $+SongPos.Ton
.Tof                equ $+SongPos.Tof
.Pitch              equ $+SongPos.Pitch
.Instrument         equ $+SongPos.Instrument
.Volume             equ $+SongPos.Volume
                    resb SongPos_size
%endmacro

section bss
alignb 4
NewSongPos MainSongPos          ;used by display routines
NewSongPos FmSongPos
NewSongPos WaveSongPos
NewSongPos SineSongPos
NewSongPos MpuSongPos
%ifdef WinVer
NewSongPos GmSongPos
%endif
NewSongPos MidiSongPos

%if PlayThreaded
%ifdef WinVer
alignb 4
DspCriticalSection: resb CRITICAL_SECTION_size
%endif
%endif


;-----------------------------------------------------------------------------
section code

;-----------------------------------------------------------------------------
; Initializes DSP simulation structures and flags.
; Does NOT initialize sound output. Call this after the sound initialization
; functions. It won't crash if called before, but you might hear silence.
;
; () (none)
DspSim:
.Init:

    ; Expands the rle compressed pitch table, from 128 words to ~22k
    ; Each hertz frequency is rounded to the nearest MIDI note from 0 to 127.
    cld
    mov esi,HertzNoteRle
    xor ecx,ecx             ;zero extend counter
    mov edi,HertzNoteTbl
    xor eax,eax             ;zero current MIDI note
.NextNote:
    mov cx,[esi]            ;get RLE length
    rep stosb               ;fill table with current note
    add esi,byte 2          ;next strip
    inc al                  ;next MIDI note
    jns .NextNote           ;stop on 256 wrap

    ; Ensure some type of sound output is playing and
    ; turn off any sound outputs that could not be initialized.
    ; For example, if GM was specified but the MPU was busy, select another
    ; output mode so that you at least hear something. Otoh, perhaps the
    ; sound card would not reset, select simple FM. The preference order is
    ; digital audio, MIDI, then FM.
    mov ecx,[SoundFlags]
    mov edx,[PlayOptions]

    ; mute any sound outputs that could not be initialized
    test ecx,SoundFlags.Fm
    jnz .FmInit
    and edx,~PlayOptions.FmVoices
.FmInit:
    test ecx,SoundFlags.Gm
    jnz .GmInit
    and eax,~PlayOptions.GmVoices
.GmInit:
    test ecx,SoundFlags.Mpu
    jnz .MpuInit
    and eax,~PlayOptions.MpuVoices
.MpuInit:
    test ecx,SoundFlags.Da
    jnz .DaInit
    and edx,~(PlayOptions.AsVoices|PlayOptions.SineVoices|PlayOptions.DlsVoices|PlayOptions.TuningWave)
.DaInit:

    ; ensure at least one type of sound output is playing
    test edx,PlayOptions.FmVoices|PlayOptions.GmVoices|PlayOptions.MpuVoices|PlayOptions.AsVoices|PlayOptions.SineVoices|PlayOptions.DlsVoices
    jnz .SoundAlreadySet
    xor eax,eax                 ;no sound output mode in case no sound card

    mov eax,PlayOptions.AsVoices
    test ecx,SoundFlags.Da
    jnz .SetOutput
    mov eax,PlayOptions.GmVoices
    test ecx,SoundFlags.Gm
    jnz .SetOutput
    mov eax,PlayOptions.FmVoices
    test ecx,SoundFlags.Fm
    jnz .SetOutput
    mov eax,PlayOptions.MpuVoices
    test ecx,SoundFlags.Mpu
    jz .SoundAlreadySet
.SetOutput:
    or edx,eax
.SoundAlreadySet:
    mov [PlayOptions],edx

    ; initialize critical section object for multithreaded playing
  %ifdef WinVer
  %if PlayThreaded
    api InitializeCriticalSection, DspCriticalSection
  %endif
  %endif

    cld
    xor eax,eax                 ;eax=0

    mov edi,VoiceEmu.Vars
    mov ecx,VoiceEmu.VarsSize/4
    rep stosd

    mov edi,SineEmu.Vars
    mov ecx,SineEmu.VarsSize/4
    rep stosd

    mov edi,DlsEmu.Vars
    mov ecx,DlsEmu.VarsSize/4
    rep stosd

    dec eax                     ;eax=-1
    mov edi,FmEmu.Vars
    mov ecx,FmEmu.VarsSize/4
    rep stosd

    mov edi,MpuEmu.Vars
    mov ecx,MpuEmu.VarsSize/4
    rep stosd

  %ifdef WinVer
    mov edi,GmEmu.Vars
    mov ecx,GmEmu.VarsSize/4
    rep stosd
  %endif

    mov edi,OutputMidiFile.Vars
    mov ecx,OutputMidiFile.VarsSize/4
    rep stosd

    ; (fall through)

;---------------------------------------
; Called when completely restarting a song or loading new SPC state
; () (none)
.Reinit:

    ; initialize song seek structures
    mov edi,MainSongPos
    call SeekSongPos.Init       ;used by FM output, note display, and voice
    mov esi,MainSongPos         ;emulation routines. updated during fast
    mov edi,FmSongPos           ;forward/reverse.
    call SeekSongPos.Copy
    mov edi,WaveSongPos
    call SeekSongPos.Copy
    mov edi,MpuSongPos
    call SeekSongPos.Copy
    mov edi,SineSongPos
    call SeekSongPos.Copy
  %ifdef WinVer
    mov edi,GmSongPos
    call SeekSongPos.Copy
  %endif
    mov edi,MidiSongPos
    call SeekSongPos.Copy

    ret


;-----------------------------------------------------------------------------
; This can actually be called directly by the main program; however it is
; intended to be called from within a dedicated thread or timer handler, and
; thus expects more precise timing and takes more precautions than it would
; otherwise need to.
PlaySounds:

  %ifdef WinVer
  %if PlayThreaded
    api EnterCriticalSection, DspCriticalSection
  %endif
  %endif

  %ifdef WinVer
  %if 0
    api timeGetTime
    mov ebx,eax
    sub ebx,[PlayThread.Tick]
    api waveOutGetPosition, [Sound.hwo], Sound.MmTime,MMTIME_size

    mov eax,[Sound.MmTime+MMTIME.sample]
    mov ecx,eax
    xchg [Sound.DmaLag],eax
    sub eax,[Sound.DmaLag]
    neg eax
    sub ecx,[Sound.MixTime]
    neg ecx
    debugwrite "time=%d mix=%d drv=%d dif=%d lag=%d",ebx,[Sound.DmaTime],[Sound.DmaLag],ecx,eax
  %endif
  %endif

    test byte [SoundFlags],SoundFlags.Da
    jz near .NoWave

    call SyncToWave
    mov [Sound.MixSamples],edx;dword 1066
    call ClearMixBuffer

    test dword [PlayOptions],PlayOptions.Pause|PlayOptions.Stop|PlayOptions.Suspend
    jnz .WavePaused
    test dword [PlayOptions],PlayOptions.AsVoices
    jz .NoAs
    call VoiceEmu
.NoAs:
    test dword [PlayOptions],PlayOptions.SineVoices
    jz .NoSine
    call SineEmu
.NoSine:
    test dword [PlayOptions],PlayOptions.DlsVoices
    jz .NoDls
    call DlsEmu
.NoDls:
.WavePaused:
    test dword [PlayOptions],PlayOptions.Sample
    jz .NoSample
    call SampleEmu
.NoSample:
    test dword [PlayOptions],PlayOptions.TuningWave
    jz .NoTuning
    call GenerateSineWave
.NoTuning:
    call CopyMixBuffer
    ;mov ecx,[Sound.IntSamples]
    ;add [Sound.MixTime],ecx
.NoWave:

    test dword [PlayOptions],PlayOptions.Pause|PlayOptions.Stop|PlayOptions.Suspend
    jnz .Paused

    test byte [SoundFlags],SoundFlags.Fm
    jz .NoFm
    ;call PlayFmSample
    test byte [PlayOptions],PlayOptions.FmVoices
    jz .NoFm
    call FmEmu
.NoFm:

    test dword [SoundFlags],SoundFlags.Mpu
    jz .NoMpu
    test byte [PlayOptions],PlayOptions.MpuVoices
    jz .NoMpu
    call MpuEmu
.NoMpu:

  %ifdef WinVer
    test byte [SoundFlags],SoundFlags.Gm
    jz .NoGm
    test dword [PlayOptions],PlayOptions.GmVoices
    jz .NoGm
    call GmEmu
.NoGm:
  %endif
.Paused:

    mov eax,[PlayTimeEnd]       ;end of previous time range becomes start of
    mov [PlayTimeStart],eax     ;next one

  %ifdef WinVer
  %if PlayThreaded
    api LeaveCriticalSection, DspCriticalSection
  %endif
  %endif

    ret


;-----------------------------------------------------------------------------
; Stops all playing sounds. Note it does NOT release any audio devices or
; disable an output mode - it simply silences them. They will resume playing
; as soon as PlaySounds is called again.
StopSounds:
    call OutputMidiFile.Stop
    test byte [SoundFlags],SoundFlags.Da
    jz .NoWave
    call ClearWaveBuffer
.NoWave:
    and dword [PlayOptions],~(PlayOptions.Sample|PlayOptions.TuningWave)
SilenceSounds:
  %ifdef WinVer
  %if PlayThreaded
    api EnterCriticalSection, DspCriticalSection
  %endif
  %elifdef DosVer
    or dword [PlayOptions],PlayOptions.Suspend
  %endif
    call FmEmu.Silence
  %ifdef WinVer
    call GmEmu.Silence
  %endif
    call MpuEmu.Silence
  %ifdef WinVer
  %if PlayThreaded
    api LeaveCriticalSection, DspCriticalSection
  %endif
  %elifdef DosVer
    and dword [PlayOptions],~PlayOptions.Suspend
  %endif
    ret

;-----------------------------------------------------------------------------
; Seeks to any point in the buffer, given a tick time count, updating the
; DSP registers and returning which voices were turned on or off. Used to
; seek small increments (inidividual frames) or large increments fast forward
; or reverse.
;
; SetKeys can then update the seek structure with any changes to their
; pitches, volumes, or instruments.
;
; To fit more in the dsp buffer, only the time information of
; important dsp writes is stored. The simple packing method uses the top
; byte to flag whether the dword is a timer value or register/value write.
; Since no song should ever exceed 18- hours, a value of 0FFh can safely
; indicate it is a write. Anything less than that should be considered
; time information.
;
; (edi=song pos struct, edx=new time in ticks)
; (bl=voices on, bh=voices off; edi)
SeekSongPos:
    ; if new time >= old time
    ;   seek forward
    ; elif time = 0
    ;   clear all variables in structure
    ; else new time < old time
    ;   seek backward
    ; endif

    xor ebx,ebx                 ;zero keys on & off
    mov esi,[edi+SongPos.Pos]
    xor ecx,ecx                 ;zero extend
    cmp [edi+SongPos.Time],edx
    je near .SetVoices
    mov [edi+SongPos.Time],edx
    jbe .Forward
    test edx,edx
    jle .Init
    jmp .Reverse

;---------------------------------------
; Initializes a song position structure
; Called after an SPC is first loaded or when the song position is reset back
; to the beginning.
; (edi=song pos struct, edx=new time in ticks)
; (; edi)
.Init:
    ; copy initial DSP RAM to seek structure
    push edi
    mov esi,FileDspRam
    cld
    mov ecx,128/4
    rep movsd

    ; reset  initial samples to zero
    lea ebx,[edi+SongPos.DspRegs+DspReg.SampleLow]
    mov ecx,8                   ;x8 voices
.InitNextSample:
    mov word [ebx],0
    add ebx,byte 16
    dec ecx
    jg .InitNextSample

    ; zero remaining portion of seek struct (vol,pitch,..)
    %if SongPos.DspRegs != 0
    %error "DspEmu.Init: DspRegs must come first in structure def."
    %endif
    xor eax,eax
    mov ecx,(SongPos_size-128)/4
    rep stosd
    pop edi

    ;mov bl,[edi+SongPos.DspRegs+DspReg.KeyOn]
    mov ebx,0FF00h              ;turn off all, turn on none
    ;mov al,[EnabledVoices]
    ;mov [edi+SongPos.Muted],al
    jmp short .SetVoices

;---------------------------------------
; (edi=seek structure, esi=buffer offset, edx=time, ebx&ecx=0)
    ; start from previous position
    ; loop until buffer pos >= buffer end or note time >= specified time
    ;   if note on
    ;     flag note was turned on
    ;   elif note off
    ;     flag note was turned off
    ;   else
    ;     set dsp register
    ;   endif
    ; endloop
    ; set instrument and pitch for all voices turned on

.Next:
    add esi,byte 4
.Forward:
    cmp [DspBufferEnd],esi      ;beyond end of buffer?
    jbe .EndLoop

    ; read next time value or register write
    mov eax,[DspBuffer+esi]
    cmp eax,0FF000000h          ;time value or register write?
    jb .CheckTime

    cmp al,DspReg.KeyOn
    je .Kon
    cmp al,DspReg.KeyOff
    je .Kof
    mov cl,al
    mov [edi+SongPos.DspRegs+ecx],ah
    jmp short .Next
.Kon:
    or bl,ah                    ;keys on |= new keys on
    ;not ah
    ;and bh,ah                  ;keys off &= !new keys on
    jmp short .Next
.Kof:
    or bh,ah                    ;keys off |= new keys off
    not ah
    and bl,ah                   ;keys on &= !new keys off
    jmp short .Next
.CheckTime:
    cmp eax,edx                 ;loop until >= desired time
    jb .Next
    ;jmp short .EndLoop (fall through)

;---------------------------------------
.EndLoop:
    mov [edi+SongPos.Pos],esi   ;store buffer position

; Set flags for any keys turned on and off
; Never keys off voices that are not on
; Never keys on voices already on, unless turned off first
; (bl=voices on, bh=voices off, edi=seek structure)
.SetVoices:
    and bh,[edi+SongPos.Active] ;voices off &= active voices
    xor [edi+SongPos.Active],bh ;turn off old voices
    or  [edi+SongPos.Active],bl ;turn on new voices
    mov eax,ebx
    mov [edi+SongPos.Kon],bx

    mov al,[edi+SongPos.Enabled]
    mov cl,[EnabledVoices]
    xor al,cl                   ;get voices toggled (muted/unmuted)
    mov [edi+SongPos.Enabled],cl
    mov ah,al
    and al,cl                   ;voices unmuted = toggled & enabled
    xor ah,al                   ;voices muted = toggled ^ unmuted
    or eax,ebx                  ;changed voices = toggled | key on/off
    and al,cl                   ;voices turned on = changed on & enabled
    and ah,[edi+SongPos.Heard]  ;voices turned off = changed off & heard
    and al,[edi+SongPos.Active] ;voices turned on = changed off & active
    mov [edi+SongPos.Ton],ax
    ret

;---------------------------------------
; Called immediately after seeking, it calculates the pitch and volume for
; each voice. This only needs to be called by routines that need such
; conversion, like the note display, FM, and MIDI. The wave routines do not
; use this.
;
.SetAllKeys:
    ; (edi=seek structure)
    mov bl,[edi+SongPos.Active]
    jmp short .SetGivenKeys
.SetNewKeys:
    ; (edi=seek structure)
    mov bl,[edi+SongPos.Kon]
.SetGivenKeys:
    ; (edi=seek structure, bl=keys on) (; edi)
    ; calculate pitches for new notes turned on
    ; don't care about notes that were turned off

    push ebp
    xor ecx,ecx                 ;start with voice 0
    mov esi,edi
    jmp .KonStart
.KonSet:
    ;ebx=voice bits
    ;esi=DSP register base
    ;edi=seek structure
    ;ecx=voice counter
    ;edx=sample index

    movzx edx,word [esi+SongPos.DspRegs+DspReg.SampleLow] ;get sample number

    ; map frequency (play rate * apparent pitch) to MIDI note
    ; MIDI note = HertzNoteTbl[ (DspPitch * Frequency) >> 12 ]
    movzx eax,word [SongPos.DspRegs+esi+DspReg.PitchLow]
    imul eax,[GlobalSample.Freq+edx*4]
    shr eax,11                  ;>>(12-1)
    cmp eax,MaxHertz*2          ;> highest MIDI note's frequency (G10)
    jbe .PitchOk
    mov al,127                  ;limit to highest MIDI note
    jmp short .PitchSet
.PitchOk:
    mov al,[HertzNoteTbl+eax]
.PitchSet:
    mov [edi+SongPos.Pitch+ecx],al

    ; set GM instrument for sample
    mov eax,[GlobalSample.Instrument+edx*4]
    mov [edi+SongPos.Instrument+ecx*4],eax

    ; get combined volume of left & right channels
    movsx ebp,byte [esi+DspReg.VolLeft]
    movsx eax,byte [esi+DspReg.VolRight]
    push ebp
    xor ebp,eax
    pop ebp
    jns .SameVolSign            ;left and right volume have same sign
    neg eax                     ;make right volume same sign as left
.SameVolSign:
    add eax,ebp                 ;left + right
    jns .VolPositive
    neg eax                     ;make volume value positive
.VolPositive:
    imul eax,[GlobalSample.Volume+edx*4]
    mov [edi+SongPos.Volume+ecx*4],eax

.KonNext:
    inc ecx                     ;next voice
    add esi,byte 16             ;next register set
.KonStart:
    shr bl,1
    jc near .KonSet
    jnz .KonNext
    pop ebp
    ret

;---------------------------------------
; (edi=seek structure, esi=buffer offset, edx=time, ebx&ecx=0)
.Reverse:
    push esi
.RevValidTime:
    mov ecx,esi
.RevScanNext:
    sub esi,byte 4
    jl .RevScanEnd
    mov eax,[DspBuffer+esi]
    cmp eax,0FF000000h          ;time value or register write?
    jae .RevScanNext
    cmp eax,edx                 ;loop until >= desired time
    jae .RevValidTime
.RevScanEnd:
    pop esi

    xor edx,edx
.RevNext:
    cmp esi,ecx
    jbe near .EndLoop
    sub esi,byte 4
    mov eax,[DspBuffer+esi]
    cmp eax,0FF000000h          ;time value or register write?
    jb .RevNext
    cmp al,DspReg.KeyOn         ;note that reverse seek also flips on->off
    je .RevKof
    cmp al,DspReg.KeyOff        ;..and off->on
    je .RevKon
    mov dl,al
    shr eax,8
    mov [edi+SongPos.DspRegs+edx],ah
    jmp short .RevNext
.RevKon:
    or bl,ah                    ;keys on |= new keys on
    ;not ah
    ;and bh,ah                   ;keys off &= !new keys on
    jmp short .RevNext
.RevKof:
    or bh,ah                    ;keys off |= new keys off
    not ah
    and bl,ah                   ;keys on &= !new keys off
    jmp short .RevNext

;---------------------------------------
; Copies one song pos structure to another
; (esi=src song pos struct, edi=dest song pos struct)
; (; esi)
.Copy:
    cld
    mov ecx,SongPos_size/4
    rep movsd
    sub esi,SongPos_size
    ret


;-----------------------------------------------------------------------------
; This greatly simplified voice sample mixer simply exists so you can hear
; the audio samples for comparison. It does not even attempt to sound like
; the real thing, or even other SPC players.
;
; Like the other routines, this too can play backwards, but the timing will
; not be exact (limited to about 1/30 second). It will however play at exact
; tick time with variable speeds forward.
;
; Precision is only tick timer exact, not cycle exact, because (1) it would
; be pointless, (2) the waveform can only change every 1/32000 a second
; anyway, and (3) the buffer could not be as long.
;
; Supported:
;   Voice volume
;   Initial pitch and slide
;
; Unsupported:
;   ADSR/Gain Envelopes (will support!)
;   Echo (neat effect but not necessary)
;   FIR Filter? (don't know what it is)
;   Pitch modulation (one voice affects another)
;   Independant channels (left+right)
;   Global volume
;
VoiceEmu:

    ; check if song position needs to reseeked
    ; if start time < wave time || start time - wave time > significant dif
    ;   use SeekSongPos
    mov ecx,[PlayTimeEnd]
    mov eax,[PlayTimeStart]
    mov edx,ecx
    sub ecx,eax                 ;ending time < starting time (playing backwards)
    ;jb .Reseek
    mov [.TimeNextSample],dword 0;tick time after next sample
    cmp ecx,TicksPerFrame*6     ;reseek if played > 6*
    ja .Reseek
    cmp [WaveSongPos.Time],eax
    mov [.TimeNextSample],eax   ;tick time after next sample
    je .NoSeek
    mov edx,eax
.Reseek:
    mov edi,WaveSongPos
    call SeekSongPos
    ; call key off for any old voices
    mov ah,bh
    ;mov ah,[WaveSongPos.Kof]
    call .KeyOff
    ; call key on for any new voices
    mov ah,[WaveSongPos.Kon]
    call .KeyOn
    ; set ratio to 0
.NoSeek:

    ; determine time/sample ratio
    mov eax,[PlayTimeEnd]
    xor edx,edx
    mov [WaveSongPos.Time],eax
    sub eax,[PlayTimeStart]     ;ending play time - starting play time
    mov ecx,[Sound.MixSamples]
    jns .NotBackwards
    xor eax,eax
.NotBackwards:
    div ecx
    ; If emulating a 1/30 of a second:
    ; 2133 ticks / 735 samples to mix (22khz/30frames)
    ; time increment = 2 (2.902040816327)
    ; time mod = 663
    mov edi,MixBuffer
    mov [.SamplesLeft],ecx
    mov [.TimeInc],eax          ;increment between sample outputs
    mov [.TimeMod],edx          ;modulus of time / sample rate
    add [.TimeNextSample],eax   ;tick time after next sample
    mov [.TimeAcm],edx          ;remainder accumulator
    mov esi,[WaveSongPos.Pos]   ;get ptr
    jmp short .ReadBuffer

;---------------------------------------
; Read next DSP register value stored in write buffer
; (esi=buffer ptr offset, edi=mix buffer ptr)
.NextBufferReg:
    add esi,byte 4
.ReadBuffer:
    mov eax,-1                  ;in case last command
    cmp [DspBufferEnd],esi      ;beyond end of buffer?
    jbe .EndBuffer

.ReadBufferNoCheck:
    ; read next time value or register write
    mov eax,[DspBuffer+esi]
    cmp eax,0FF000000h          ;time value or register write?
    jb .CheckTime

    push dword .NextBufferReg
    cmp al,DspReg.KeyOn
    je near .KeyOn
    cmp al,DspReg.KeyOff
    je near .KeyOff
    movzx ecx,al
    mov [WaveSongPos.DspRegs+ecx],ah
   %if SupportPitchSlide ;to enable pitch slide after key on
    mov ebx,ecx
    and bl,1110b
    cmp bl,2
    je near .ChangePitch
   %endif
    ret
.CheckTime:
    cmp [.TimeNextSample],eax   ;next dsp time > command time
    ja .NextBufferReg

.EndBuffer:
    mov [.TimeNextReg],eax
    mov [WaveSongPos.Pos],esi   ;save pffset

;---------------------------------------
; Emulate <=8 sampled voices
; (edi=mix buffer ptr)
.AdvancesVoices:
    mov ecx,7                   ;start with last voice
    ;mov ebx,WaveSongPos.DspRegs+(16*7)

.NextVoice:
    bt [WaveSongPos.Active],ecx
    jnc near .VoiceOff

    ; Calculate new envelope...

    ; Get sample and advance wave by playrate
    mov esi,[.Ptr+ecx*4]
    mov edx,[.Mod+ecx*4]
    movsx eax,word [SamplesBuffer+esi*2]
    add [.Acm+ecx*4],edx
    adc esi,[.Inc+ecx*4]

    ; Adjust envelope...

    bt dword [EnabledVoices],ecx
    jnc .VoiceMuted

    ; Amplify volume...
    imul eax,[.Vol+ecx*4]
    sar eax,8

    ; Merge voice into buffer
    ; (eax=sample value, ecx=current voice, edi=mix buffer ptr)
    add [edi],eax
.VoiceMuted:

    cmp [.End+ecx*4],esi
    jg .NotVoiceEnd
    cmp dword [.Len+ecx*4],0
    jg .Looped
.EndVoice:
    ; end of sample
    btr [WaveSongPos.Active],ecx
    jmp short .VoiceOff
.Looped:
    sub esi,[.End+ecx*4]        ;get amount that voice went past end
    mov eax,[.Loop+ecx*4]       ;start of loop portion
    add esi,eax                 ;loop start + remainder from first portion
    add eax,[.Len+ecx*4]        ;loop start + loop len = end
    mov [.End+ecx*4],eax
.NotVoiceEnd:
    mov [.Ptr+ecx*4],esi
.VoiceOff:

    ;sub ebx,byte 16
    dec ecx
    jge near .NextVoice

    ; dsp time += inc
    ; acm += mod
    ; if acm => sample to mix
    ;   acm -= sample to mix
    ;   dsp time ++
    ; endif

    ; if event time <= current time, do command from dsp buffer

    add edi,byte 4
    dec dword [.SamplesLeft]
    jle .Exit

    mov ebx,[.TimeAcm]
    mov eax,[.TimeNextSample]
    add ebx,[.TimeMod]
    mov ecx,[Sound.MixSamples]
    add eax,[.TimeInc]
    cmp ebx,ecx                 ;acm => samples to mix (check overflow)
    jb .EvenTime
    sub ebx,ecx                 ;acm -= samples to mix
    inc eax                     ;dsp time ++
.EvenTime:
    mov [.TimeNextSample],eax
    mov [.TimeAcm],ebx
    cmp [.TimeNextReg],eax      ;next dsp write time >= next sample time
    jae near .AdvancesVoices
    mov esi,[WaveSongPos.Pos]   ;get ptr
    jmp .NextBufferReg

.Exit:
    ret

;---------------------------------------
; (ah=new keys on) (; esi, edi)
.KeyOn:
    push esi
    push edi
    xor ecx,ecx
    mov esi,WaveSongPos.DspRegs
    or [WaveSongPos.Active],ah
.CheckKon:
    shr ah,1
    jc .VoiceKon
    jz .NoMoreKon
.NextKon:
    add esi,byte 16             ;next set of DSP registers for voice
    add ecx,byte 4
    jmp short .CheckKon
.NoMoreKon:
    pop edi
    pop esi
    ret

.VoiceKon:
    push eax                    ;save key on bitflags

    ; set sample offset in cached buffer
    movzx ebx,word [esi+DspReg.SampleLow]
    bts dword [GlobalSample.Cached],ebx
    jc .AlreadyCached
    push esi
    push ecx
    push ebx
  %ifdef debug
    movzx edi,byte [esi+DspReg.SourceNumber]
    mov ecx,ebx
    shl ecx,GlobalSample.NameShl
    add ecx,GlobalSample.Name+1
    debugwrite "VoiceEmu.decomp gs=%-4d ls=%-3d gof=%-08X lof=%-08X name=%s",ebx,edi,[GlobalSample.Offset+ebx*4],[LocalSample.Offset+edi*4],ecx
  %endif
    call DecompressSample
    pop ebx
    pop ecx
    pop esi
.AlreadyCached:

    ; calc sample and loop offsets in cache
    ; (ebx=sample number)
    shl ebx,2                   ;sample info offset = sample number * 4
    mov edi,9                   ;9 bytes per 4bit ADPCM block
    movzx eax,word [GlobalSample.Offset+ebx] ;get sample start
    xor edx,edx
    div edi                     ;/9
    shl eax,4                   ;*16 (32/2 to use ADC)
    mov [.Ptr+ecx],eax
    ;debugwrite "voiceemu keyon srcdir=%d voice=%d ptr=%d",ebx,ecx,eax
    add eax,[GlobalSample.Length+ebx]
    mov edx,[GlobalSample.LoopLen+ebx]
    mov [.End+ecx],eax
    mov [.Len+ecx],edx
    movzx eax,word [GlobalSample.Offset+ebx+2] ;then sample loop portion
    xor edx,edx
    div edi
    shl eax,4                   ;*16 (32/2 to use ADC)
    mov [.Loop+ecx],eax

    ; calculate wave sample increment and modulus based on sound output rate
    ;((PlayRate * 256000) / SampleRate) / 32768
    movzx ebx,word [esi+DspReg.PitchLow]
    mov eax,256000
    imul ebx
    xor edx,edx
    div dword [Sound.MixRate]
    mov dword [.Acm+ecx],0
    cmp eax,16<<15
    jb .IncOk
    mov eax,16<<15
.IncOk:
    mov edx,eax
    shr eax,15
    shl edx,17
    mov [.Inc+ecx],eax
    mov [.Mod+ecx],edx

    ; get combined volume of left & right channels
    movsx ebx,byte [esi+DspReg.VolLeft]
    movsx edx,byte [esi+DspReg.VolRight]
    mov eax,ebx
    xor ebx,edx                 ;top bit will be set if different signs
    jns .SameVolSign            ;left and right volume have same sign
    neg edx                     ;make right volume same sign as left
.SameVolSign:
    add edx,eax                 ;left + right
    mov [.Vol+ecx],edx

    pop eax
    jmp .NextKon

;---------------------------------------
; (ah=keys off) (; esi,edi)
.KeyOff:
    ; set decay mode to key off...

    ; just turn it completely off for now
    not ah
    and [WaveSongPos.Active],ah
    ret

%if SupportPitchSlide
;---------------------------------------
; (al=register, ah=value, ecx=also register) (; esi,edi)
.ChangePitch:
    test dword [DspFlags],DspFlags.PitchSlide
    jz .IgnorePitch

    and ecx,01110000b           ;get voice
    movzx eax,word [WaveSongPos.DspRegs+ecx+DspReg.PitchLow]
    shr ecx,2                   ;/4 for index

    ; calculate wave sample increment and modulus based on sound output rate
    ;((PlayRate * 256000) / SampleRate) / 32768
    mov ebx,256000
    imul ebx
    xor edx,edx
    div dword [Sound.MixRate]
    cmp eax,16<<15
    jb .IncOk2
    mov eax,16<<15
.IncOk2:
    mov edx,eax
    shr eax,15
    shl edx,17
    mov [.Inc+ecx],eax
    mov [.Mod+ecx],edx
.IgnorePitch:
    ret
%endif

section bss
alignb 4
.Vars:
.Ptr:           resd 8          ;current sample pointer
.Inc:           resd 8          ;sample increment
.Mod:           resd 8          ;modulus (PlayRate / SampleRate)
.Acm:           resd 8          ;modulus accumulator
.Loop:          resd 8          ;loop start pointer
.End:           resd 8          ;sample end pointer
.Len:           resd 8          ;loop length
.Vol:           resd 8          ;voice volume
.Env:           resd 8          ;present envelope value
.Dir:           resd 8          ;envelope direction
.VarsSize       equ $-.Vars
.SamplesLeft:   resd 1          ;samples remaining to mix
.TimeInc:       resd 1          ;tick time increment between sample outputs
.TimeAcm:       resd 1          ;remainder accumulator
.TimeMod:       resd 1          ;modulus of (time / sample rate)
.TimeNextReg:   resd 1          ;tick time of next dsp write to a register
.TimeNextSample:resd 1          ;tick time after next sample
section code


;-----------------------------------------------------------------------------
; Sends MIDI commands through MPU or MIDI device.
;
; (SongPos structure, device output handle) (none)
%macro MidiEmu 3

    mov edx,[PlayTime]
    mov edi,%1
    call SeekSongPos
    ;mov edi,%1
    call SeekSongPos.SetGivenKeys

; (seek structure contains key on/off bits already set)
.Given:
    movzx ebx,byte [%1.Tof]
    xor [%1.Heard],bl
.NextKof:
    bsf edi,ebx                 ;find next voice to turn off
    jz .NoKofs
    btr ebx,edi                 ;reset voice's bit

    ;lea eax,[edi+Midi.NoteOff+(96<<16)]  ;form byte command|channel|velocity off (arbitrary)
    mov eax,0F0h+(96<<16)       ;form byte command|channel|velocity off (arbitrary)
    add al,[.Commands+edi]      ;combine with last sent kon|channel command
   %ifdef DosVer
    mov esi,MidiEmu.MpuString
    mov ah,[.Pitches+edi]       ;note number or percussive instrument
    mov ecx,3                   ;send three byte string
    mov [esi],eax
    call WriteMpuString
   %elifdef WinVer
    mov ah,[.Pitches+edi]
    api midiOutShortMsg, [Sound.%2],eax
   %endif
    jmp short .NextKof
.NoKofs:

;Turn on new voices
    movzx ebx,byte [%1.Ton]
    or [%1.Heard],bl
.NextKon:
    bsf edi,ebx                 ;find next voice to turn on
    jz near .EndKon
    btr ebx,edi                 ;reset voice's bit

    ; change current bank if necessary
    mov eax,32                  ;set controller 32 (bank lsb)
    mov ah,byte [%1.Instrument+edi*4+2] ;bank lsb 0-127
    cmp [.BanksLsb+edi],ah
    je .SameBankLsb
    mov [.BanksLsb+edi],ah
    shl eax,8                   ;shift controller number and value <<8
    lea eax,[eax+edi+Midi.ControlChange] ;form byte command|channel
   %ifdef DosVer
    mov esi,MidiEmu.MpuString
    mov ecx,3                   ;send two byte string
    mov [esi],eax               ;patch change command byte
    call WriteMpuString
   %elifdef WinVer
    api midiOutShortMsg, [Sound.%2],eax
   %endif
.SameBankLsb:
    xor eax,eax                 ;set controller 0 (bank msb)
    mov ah,byte [%1.Instrument+edi*4+3] ;bank msb 0-127
    cmp [.BanksMsb+edi],ah
    je .SameBankMsb
    mov [.BanksMsb+edi],ah
    shl eax,8                   ;shift controller number and value <<8
    lea eax,[eax+edi+Midi.ControlChange] ;form byte command|channel
   %ifdef DosVer
    mov esi,MidiEmu.MpuString
    mov ecx,3                   ;send two byte string
    mov [esi],eax               ;patch change command byte
    call WriteMpuString
   %elifdef WinVer
    api midiOutShortMsg, [Sound.%2],eax
   %endif
.SameBankMsb:


    ; change current instrument if necessary
    lea eax,[edi+Midi.PatchChange] ;form byte command|channel
    mov ah,byte [%1.Instrument+edi*4] ;patch 0-127
    cmp [.Patches+edi],ah
    je .SameInstrument
    mov [.Patches+edi],ah
   %ifdef DosVer
    mov esi,MidiEmu.MpuString
    mov ecx,2                   ;send two byte string
    mov [esi],eax               ;patch change command byte
    call WriteMpuString
   %elifdef WinVer
    api midiOutShortMsg, [Sound.%2],eax
   %endif
.SameInstrument:

    ; check if voice is percussive or instrumental
    mov ah,byte [%1.Instrument+edi*4+1] ;drum 1-127, 0 means none
    test ah,ah
    jz .Instrumental
    mov al,Midi.NoteOn+9       ;form byte command|percussion channel
    ;and eax,0FFFFh
    jmp short .Percussive
.Instrumental:
    lea eax,[edi+Midi.NoteOn]   ;form byte command|channel
    mov ah,byte [%1.Pitch+edi]  ;get MIDI note number
.Percussive: ;(eax=command byte|instrument)

    ; set volume
    mov ecx,[%1.Volume+edi*4]   ;get mono volume  (l+r *256)
   %ifdef DosVer
    mov esi,MidiEmu.MpuString
   %endif
   %if 1
    cmp ecx,127<<8
    jbe .VolOk
   %endif
    mov ecx,127<<8              ;limit volume to max (0-127)
.VolOk:

    ; sound note
    ; (eax=command byte|instrument, ecx=volume)
    mov [.Commands+edi],al      ;store last sent MIDI command on channel
    mov [.Pitches+edi],ah       ;note number or percussive instrument
   %ifdef DosVer
    mov [esi],eax
    mov [esi+2],ch              ;note velocity (volume)
    mov ecx,3                   ;send three byte string
    call WriteMpuString
   %elifdef WinVer
    push eax
    mov [esp+2],ch              ;note velocity (volume)
    api midiOutShortMsg, [Sound.%2];,eax
   %endif

    jmp .NextKon
.EndKon:

    ret

; Silences all notes
; () (none)
.Silence:
    test dword [SoundFlags],SoundFlags.%3
    jz .SaNoKofs
    xor ebx,ebx
    mov [%1.Active],bl
    xchg [%1.Heard],bl
.SaNextKof:
    bsf edi,ebx                 ;find next voice to turn off
    jz .SaNoKofs
    btr ebx,edi                 ;reset voice's bit

    ;lea eax,[edi+Midi.NoteOff+(96<<16)]  ;form byte command|channel|velocity off (arbitrary)
    mov eax,0F0h+(96<<16)       ;form byte command|channel|velocity off (arbitrary)
    add al,[.Commands+edi]      ;combine with last sent kon|channel command
  %ifdef DosVer
    mov esi,MidiEmu.MpuString
    mov ah,[.Pitches+edi]       ;note number or percussive instrument
    mov ecx,3                   ;send three byte string
    mov [esi],eax
    call WriteMpuString
  %elifdef WinVer
    mov ah,[.Pitches+edi]
    api midiOutShortMsg, [Sound.%2],eax
  %endif
    jmp short .SaNextKof
.SaNoKofs:
    ret

section bss
alignb 4
.Vars:
.Pitches:       resb 8          ;last used pitches for each voice
.Patches:       resb 8          ;last used instrument
.BanksLsb:      resb 8          ;low byte of currently selected bank
.BanksMsb:      resb 8          ;high byte of bank
.Commands:      resb 8
.VarsSize       equ $-.Vars
section code

%endmacro

%ifdef DosVer
section bss
alignb 4
MidiEmu.MpuString:  resb 4
section code
%endif


;-----------------------------------------------------------------------------
; Simulates DSP output with FM synthesis rather than digital audio samples.
;
; () (none)
FmEmu:

%ifdef DosVer
    ; seek new position in song
    ; check for notes that are different between this call and the last
    ; sound any new notes, release old notes
    ; if note press
    ;   if voice's instrument is different from the one last used, then set patch
    ;   set volume accordingly
    ;   set pitch
    ;   turn on note
    ; if note release
    ;   turn off note
    ; if pitch change
    ;   set note's new pitch
    ;   turn on note

    mov edx,[PlayTime]
    mov edi,FmSongPos
    call SeekSongPos
    ;mov edi,FmSongPos
    call SeekSongPos.SetGivenKeys

; (seek structure contains key on/off bits already set)
.Given:

; Turn off old voices
    movzx ebx,byte [FmSongPos.Tof]
    xor [FmSongPos.Heard],bl
.NextKof:
    bsf edi,ebx
    jz .NoKofs
    mov eax,edi                 ;copy voice for FM
    btr ebx,edi
    mov ah,[.Fnumbers+edi]      ;get previous fnumber/octave of voice, to prevent clicking sound
    add al,0B0h                 ;DSP register, low byte of pitch, voice off
    call WriteFmReg
    jmp short .NextKof
.NoKofs:


;Turn on new voices
    movzx edi,byte [FmSongPos.Ton]
    or [FmSongPos.Heard],di
.NextKon:
    bsf esi,edi
    jz near .EndKon
    btr edi,esi

    ; set voice's instrument
    movzx eax,byte [FmSongPos+SongPos.Instrument+esi*4]
    cmp [.Patches+esi*4],al
    je .SameInstrument
    mov [.Patches+esi*4],al
    push esi                    ;save counter
    mov ecx,esi
    xchg eax,esi
    shl esi,4                   ;*16 get instrument patch information
    add esi,SbFm.PatchData      ;get ptr to instrument information in patch table
    mov dl,[esi+3]
    mov [.Volumes+ecx],dl
    call SetFmPatch
    pop esi
.SameInstrument:

    ; set volume
    ; (fm volume scale seems to be skewed oddly)
    mov eax,[FmSongPos+SongPos.Volume+esi*4]  ;get mono volume  (l+r *256)
    shr eax,1
    cmp eax,64<<8
    jb .VolOk
    mov ah,63
.VolOk:
    not ah                      ;OPL2 volume is backwards (63=silent, 0=loudest)
    and ah,03Fh                 ;mask off top two bits (scaling level) to select only carrier volume
    ;or ah,[.Volumes+esi]
    mov al,[SbFm.VoiceTable+esi]
    add al,43h                  ;carrier volume register
    ;call WriteFmReg

    ; get MIDI note number
    ;movzx edx,byte [FmSongPos.Pitch+esi]
    ;lea eax,[esi+0A0h]          ;DSP register, low byte of pitch
    ;mov ebx,[GmFnumberTbl+edx*2]  ;get fnumber for midi note
    ;mov ah,bl
    ;call WriteFmReg
    ;lea eax,[esi+20B0h]        ;DSP register, high byte of pitch (20h turns voice on)
    ;mov [.Fnumbers+esi],bh     ;save fnumber/octave to eliminate click when turning voice off
    ;or ah,bh
    ;call WriteFmReg

    jmp .NextKon
.EndKon:

    ; Each fnumber ranges 0-1023, with an octave shift 0-7. The SB
    ; documentation gives this formula to convert hz to fnumber:
    ;
    ;   fn=(long)f * 1048576 / b / m /50000L;
    ;   where f is the frequency in Hz,
    ;         b is the block (octave) number between 0 and 7 inclusive, and
    ;         m is the multiple number between 0 and 15 inclusive.
    ;
    ; The nice thing about that formula is that it doesn't work ;(
    ; Well, it does work if (they don't mention) the block, or rather octave,
    ; is a power of two and the multiple isn't 11-15 or zero. Plus, when I
    ; compare the FM notes with my Roland, the freqs are a little flat.
    ; A better one (which I don't remember where I found) is:
    ;
    ;   F-Number = Music Frequency * 2^(20-Block) / 49716 Hz
    ;
    ; C 261.625hz = 158h
    ; A 440hz     = 244h
    ;
    ; for voice=0 to 7
    ;   if key on or pitch changed
    ;     calculate fnumber from pitch
    ;     write fm pitch
    ;     turn on key
    ;   endif
    ; endfor

; Turn on old voices
    mov edi,[FmSongPos.Active]
    mov esi,7                   ;start with voice 7
    and edi,[EnabledVoices]

.NextPon:
    bt edi,esi                  ;ignore if voice is off
    jnc near .SamePitch
    mov ebx,esi
    shl ebx,4                   ;dsp base reg = voice * 16
    movzx edx,word [FmSongPos.DspRegs+ebx+DspReg.SampleLow] ;get sample number
    movzx eax,word [FmSongPos.DspRegs+ebx+DspReg.PitchLow]
    bt dword [FmSongPos.Kon],esi ;set immediately if voice was turned on
    jc .SetPitch
    test dword [DspFlags],DspFlags.PitchSlide
    jz .SamePitch
    cmp [.Pitches+esi*4],eax    ;is pitch same as last time
    je .SamePitch

.SetPitch: ;(eax=pitch, edx=sample number)
    ; fnumber = HertzFnumberTbl[ (DspPitch * Frequency) >> 12 ]
    mov [.Pitches+esi*4],eax
    mul dword [GlobalSample.Freq+edx*4]
    shr eax,12

    xor ecx,ecx                 ;in case of no shift
    cmp eax,512
    jb .NoFreqShift
    cmp eax,6211                ;OPL2 FM can not produce freqs any higher
    jb .FreqOk
    mov ebx,1FFFh
    jmp short .SetFreq
.FreqOk:
    bsr ecx,eax                 ;get highest bit in frequency
    sub ecx,byte 8              ;9->1
    shr eax,cl
    shl ecx,10                  ;move into upper byte, bit 2
.NoFreqShift:
    mov ebx,[HertzFnumberTbl+eax*2] ;get fnumber for frequency
    add ebx,ecx

.SetFreq: ;(ebx=frequency)
    lea eax,[esi+0A0h]          ;DSP register, low byte of pitch
    mov ah,bl
    call WriteFmReg
    lea eax,[esi+20B0h]         ;DSP register, high byte of pitch (20h turns voice on)
    mov [.Fnumbers+esi],bh      ;save fnumber/octave to reduce click turning voice off
    or ah,bh
    call WriteFmReg

.SamePitch:
    dec esi
    jns near .NextPon
.IgnorePitch:

    ret

; Turn off all voices
; () (none)
.Silence:
    test dword [SoundFlags],SoundFlags.Fm
    jz .SaNoKofs
    xor ebx,ebx
    mov [FmSongPos.Active],bl
    xchg [FmSongPos.Heard],bl
.SaNextKof:
    bsf edi,ebx
    jz .SaNoKofs
    mov eax,edi                 ;copy voice for FM
    btr ebx,edi
    mov ah,[.Fnumbers+edi]      ;get previous fnumber/octave of voice, to prevent clicking sound
    add al,0B0h                 ;DSP register, low byte of pitch, voice off
    call WriteFmReg
    jmp short .SaNextKof
.SaNoKofs:
    ret

section bss
alignb 4
.Vars:
.Pitches:       resd 8          ;last used pitches
.Patches:       resd 8          ;last used instrument for that voice
.Volumes:       resb 8          ;last used volume of a voice
.Fnumbers:      resb 8          ;last used fnumber of a voice
.VarsSize       equ $-.Vars
section code

;---------------------------------------
%elifdef WinVer
    MidiEmu FmSongPos, hfmo, Fm

%endif


;-----------------------------------------------------------------------------
; Sends equivalent MIDI commands through MPU.
;
; () (none)
MpuEmu:
    MidiEmu MpuSongPos, hmpo, Mpu


%ifdef WinVer
;-----------------------------------------------------------------------------
; Sends equivalent MIDI commands through MPU.
;
; () (none)
GmEmu:
    MidiEmu GmSongPos, hgmo, Gm
%endif


;-----------------------------------------------------------------------------
; Simulates DSP output with sine waves rather than digital audio samples.
; The code is almost EXACTLY the same as VoiceEmu.
;
; () (none)
SineEmu:
    ; check if song position needs to reseeked
    ; if start time < wave time || start time - wave time > significant dif
    ;   use SeekSongPos
    mov ecx,[PlayTimeEnd]
    mov eax,[PlayTimeStart]
    mov edx,ecx
    sub ecx,eax                 ;ending time < starting time (playing backwards)
    ;jb .Reseek
    mov [.TimeNextSample],dword 0;tick time after next sample
    cmp ecx,TicksPerFrame*6     ;reseek if played > 6*
    ja .Reseek
    cmp [SineSongPos.Time],eax
    mov [.TimeNextSample],eax   ;tick time after next sample
    je .NoSeek
    mov edx,eax
.Reseek:
    mov edi,SineSongPos
    call SeekSongPos
    ; call key off for any old voices
    mov ah,bh
    ;mov ah,[SineSongPos.Kof]
    call .KeyOff
    ; call key on for any new voices
    mov ah,[SineSongPos.Kon]
    call .KeyOn
    ; set ratio to 0
.NoSeek:

    ; determine time/sample ratio
    mov eax,[PlayTimeEnd]
    xor edx,edx
    mov [SineSongPos.Time],eax
    sub eax,[PlayTimeStart]     ;ending play time - starting play time
    mov ecx,[Sound.MixSamples]
    jns .NotBackwards
    xor eax,eax
.NotBackwards:
    div ecx
    ; If emulating a 1/30 of a second:
    ; 2133 ticks / 735 samples to mix (22khz/30frames)
    ; time increment = 2 (2.902040816327)
    ; time mod = 663
    mov edi,MixBuffer
    mov [.SamplesLeft],ecx
    mov [.TimeInc],eax          ;increment between sample outputs
    mov [.TimeMod],edx          ;modulus of time / sample rate
    add [.TimeNextSample],eax   ;tick time after next sample
    mov [.TimeAcm],edx          ;remainder accumulator
    mov esi,[SineSongPos.Pos]   ;get ptr
    jmp short .ReadBuffer

;---------------------------------------
; Read next DSP register value stored in write buffer
; (esi=buffer ptr offset, edi=mix buffer ptr)
.NextBufferReg:
    add esi,byte 4
.ReadBuffer:
    mov eax,-1                  ;in case last command
    cmp [DspBufferEnd],esi      ;beyond end of buffer?
    jbe .EndBuffer

.ReadBufferNoCheck:
    ; read next time value or register write
    mov eax,[DspBuffer+esi]
    cmp eax,0FF000000h          ;time value or register write?
    jb .CheckTime
    push dword .NextBufferReg
    cmp al,DspReg.KeyOn
    je near .KeyOn
    cmp al,DspReg.KeyOff
    je near .KeyOff
    movzx ecx,al
    mov [SineSongPos.DspRegs+ecx],ah
   %if SupportPitchSlide ;to enable pitch slide after key on
    mov ebx,ecx
    and bl,1110b
    cmp bl,2
    je near .ChangePitch
   %endif
    ret
.CheckTime:
    cmp [.TimeNextSample],eax   ;next dsp time > command time
    ja .NextBufferReg

.EndBuffer:
    mov [.TimeNextReg],eax
    mov [SineSongPos.Pos],esi   ;save offset

;---------------------------------------
; Emulate <=8 sampled voices
; (edi=mix buffer ptr)
.AdvancesVoices:
    mov ecx,7                   ;start with last voice

.NextVoice:
    cmp [.Vol+ecx*4],dword 0    ;check if volume is 0
    je near .VoiceOff

    ; (ecx=current voice, edi=mix buffer ptr)
    mov esi,[.Ptr+ecx*4]
    mov edx,[.Mod+ecx*4]
    movsx eax,word [SineWaveTbl+esi*2]
    add [.Acm+ecx*4],edx
    adc esi,[.Inc+ecx*4]
    imul eax,[.Vol+ecx*4]       ;multiply by volume
    bt dword [SineSongPos.Active],ecx
    jc .VoiceOn
    cmp esi,1024
    jb .VoiceOn
    mov [.Vol+ecx*4],dword 0    ;check if volume is 0
    mov [.Ptr+ecx*4],dword 0
.VoiceOn:
    and esi,1023
    sar eax,8
    mov [.Ptr+ecx*4],esi

    bt dword [EnabledVoices],ecx
    jnc .VoiceMuted
    add [edi],eax               ;merge voice into buffer
.VoiceMuted:

    ; Get sample and advance wave by playrate
    mov edx,[.SMod+ecx*4]
    mov ebx,[.Dec+ecx*4]
    add [.SAcm+ecx*4],edx
    sbb [.Left+ecx*4],ebx
    ja .NotVoiceEnd
.EndVoice:
    ; end of sample
    btr [SineSongPos.Active],ecx
.NotVoiceEnd:
.VoiceOff:

    dec ecx
    jge near .NextVoice

    ; dsp time += inc
    ; acm += mod
    ; if acm => sample to mix
    ;   acm -= sample to mix
    ;   dsp time ++
    ; endif

    ; if event time <= current time, do command from dsp buffer

    add edi,byte 4
    dec dword [.SamplesLeft]
    jle .Exit

    mov ebx,[.TimeAcm]
    mov eax,[.TimeNextSample]
    add ebx,[.TimeMod]
    mov ecx,[Sound.MixSamples]
    add eax,[.TimeInc]
    cmp ebx,ecx                 ;acm => samples to mix (check overflow)
    jb .EvenTime
    sub ebx,ecx                 ;acm -= samples to mix
    inc eax                     ;dsp time ++
.EvenTime:
    mov [.TimeNextSample],eax
    mov [.TimeAcm],ebx
    cmp [.TimeNextReg],eax      ;next dsp write time >= next sample time
    jae near .AdvancesVoices
    mov esi,[SineSongPos.Pos]   ;get ptr
    jmp .NextBufferReg

.Exit:
    ret

;---------------------------------------
; (ah=new keys on) (; esi, edi)
.KeyOn:
    push esi
    xor ecx,ecx
    mov esi,SineSongPos.DspRegs
    or [SineSongPos.Active],ah
.CheckKon:
    shr ah,1
    jc .VoiceKon
    jz .NoMoreKon
.NextKon:
    add esi,byte 16             ;next set of DSP registers for voice
    add ecx,byte 4
    jmp short .CheckKon
.NoMoreKon:
    pop esi
    ret

.VoiceKon: ;(esi=dsp regsiter base ptr, ecx=voice*4) (; eax,ecx,esi)
    movzx ebx,word [esi+DspReg.SampleLow]
    push eax                    ;save
    shl ebx,2
    push ebx                    ;keep sample*4 for later

    ; set sample length
    mov edx,[GlobalSample.LoopLen+ebx]
    mov eax,[GlobalSample.Length+ebx]
    movzx ebx,word [esi+DspReg.PitchLow]
    test edx,edx
    jz .CalcSampleDec

    mov dword [.Left+ecx],-1    ;infinite length because looped
    mov dword [.SMod+ecx],0
    mov dword [.Dec+ecx],0
    jmp short .EndCsd

.CalcSampleDec: ;(eax=sample length, ebx=pitch)
    ; calculate wave sample decrement and modulus based on sound output rate
    ;((PlayRate * 256000) / SampleRate) / 32768
    mov [.Left+ecx],eax
    mov eax,256000
    imul ebx
    xor edx,edx
    div dword [Sound.MixRate]
    mov dword [.SAcm+ecx],0     ;zero modulus accumulator
    mov edx,eax
    shr eax,15
    shl edx,17
    mov [.Dec+ecx],eax
    mov [.SMod+ecx],edx
.EndCsd:

    ; calculate sine wave increment
    ; (playrate * sample freq / 4096) * 1024 / sb sampling rate
    ; (ebx=pitch, ecx=voice)

    ; 16383 * 12543 = 205491969, / 4096 = 50168
    ; (4096 * 440) / 4096 = 440
    ; 440 * 1024 = 450560

    ;(ebx=pitch)
    mov eax,[esp]               ;get sample source number * 4
    mov eax,[GlobalSample.Freq+eax]
    imul ebx
    ;cmp eax,16000*4096         ;impossible to have freq higher than 32khz/2
    ;jb .KonFreqOk
    ;mov eax,16000*4096
.KonFreqOk:
    xor edx,edx
    shl eax,6                   ;*64  (2^32 / 16000 / 4096 = 64)
    mov dword [.Acm+ecx],edx    ;zero modulus accumulator
    div dword [Sound.MixRate]
    ;mov [.Ptr+ecx],dword 0

    mov edx,eax
    shr eax,8
    shl edx,24
    mov [.Inc+ecx],eax          ;sine wave increment
    mov [.Mod+ecx],edx          ;modulus

    ; get combined volume of left & right channels
    movsx ebx,byte [esi+DspReg.VolLeft]
    movsx edx,byte [esi+DspReg.VolRight]
    mov eax,ebx
    xor ebx,edx                 ;top bit will be set if different signs
    jns .SameVolSign            ;left and right volume have same sign
    neg edx                     ;make right volume same sign as left
.SameVolSign:
    pop ebx
    add eax,edx                 ;left + right
    imul eax,[GlobalSample.Volume+ebx]
    sar eax,9
    mov [.Vol+ecx],eax

    ;pop ebx
    pop eax
    jmp .NextKon

;---------------------------------------
; (ah=keys off) (; esi,edi)
.KeyOff:
    ; set decay mode to key off...

    ; just turn it completely off for now
    not ah
    and [SineSongPos.Active],ah
    ret

%if SupportPitchSlide
;---------------------------------------
; (al=register, ah=value, ecx=also register) (; esi,edi)
.ChangePitch:
    test dword [DspFlags],DspFlags.PitchSlide
    jz .AcceptPitch
    ret
.AcceptPitch:

    and ecx,01110000b           ;register & E0h = voice * 16
    movzx eax,word [SineSongPos.DspRegs+ecx+DspReg.SampleLow]
    movzx ebx,word [SineSongPos.DspRegs+ecx+DspReg.PitchLow]
    shl eax,2                   ;sample source number * 4
    shr ecx,2                   ;/4 for index
    push eax

    ; calculate wave sample decrement and modulus based on sound output rate
    ;((PlayRate * 256000) / SampleRate) / 32768
    cmp [.Left+ecx],dword -1
    je .CpLooped
    mov eax,256000
    imul ebx
    xor edx,edx
    div dword [Sound.MixRate]
    mov edx,eax
    shr eax,15
    shl edx,17
    mov [.Dec+ecx],eax
    mov [.SMod+ecx],edx
.CpLooped:

    ; calculate sine wave increment
    ; (playrate * sample freq / 4096) * 1024 / sb sampling rate
    ; (ebx=pitch, ecx=voice)

    ; 16383 * 12543 = 205491969, / 4096 = 50168
    ; (4096 * 440) / 4096 = 440
    ; 440 * 1024 = 450560

    pop eax                     ;get sample source number * 4
    mov eax,[GlobalSample.Freq+eax]
    imul ebx
    ;cmp eax,16000*4096          ;impossible to have freq higher than 32khz/2
    ;jb .KonFreqOk
    ;mov eax,16000*4096
.CpFreqOk:
    xor edx,edx
    shl eax,6                   ;*64  (2^32 / 16000 / 4096 = 64)
    div dword [Sound.MixRate]
    mov edx,eax
    shr eax,8
    shl edx,24
    mov [.Inc+ecx],eax          ;sine wave increment
    mov [.Mod+ecx],edx          ;modulus

    ret
%endif

section bss
alignb 4
.Vars:
.Ptr:           resd 8          ;sine wave pointer
.Inc:           resd 8          ;sine wave increment
.Mod:           resd 8          ;modulus (PlayRate / SampleRate)
.Acm:           resd 8          ;modulus accumulator
.Left:          resd 8          ;sample length remaining
.Dec:           resd 8          ;sample length decrement
.SMod:          resd 8          ;sample modulus (PlayRate / SampleRate)
.SAcm:          resd 8          ;sapmle modulus accumulator
.Vol:           resd 8          ;voice volume
.VarsSize       equ $-.Vars
.SamplesLeft:   resd 1          ;samples remaining to mix
.TimeInc:       resd 1          ;tick time increment between sample outputs
.TimeAcm:       resd 1          ;remainder accumulator
.TimeMod:       resd 1          ;modulus of (time / sample rate)
.TimeNextReg:   resd 1          ;tick time of next dsp write to a register
.TimeNextSample:resd 1          ;tick time after next sample
section code


;-----------------------------------------------------------------------------
; Simulates DSP output with DLS instruments rather than the default audio
; samples contained with the SPC.
;
; () (none)
DlsEmu:
    ret

section bss
alignb 4
.Vars:
.Ptr:           resd 8          ;current sample pointer
.Inc:           resd 8          ;sample increment
.Mod:           resd 8          ;modulus (PlayRate / SampleRate)
.Acm:           resd 8          ;modulus accumulator
.Loop:          resd 8          ;loop start pointer
.End:           resd 8          ;sample end pointer
.Len:           resd 8          ;loop length
.Vol:           resd 8          ;voice volume
.VarsSize       equ $-.Vars
.SamplesLeft:   resd 1          ;samples remaining to mix
.TimeInc:       resd 1          ;tick time increment between sample outputs
.TimeAcm:       resd 1          ;remainder accumulator
.TimeMod:       resd 1          ;modulus of (time / sample rate)
.TimeNextReg:   resd 1          ;tick time of next dsp write to a register
.TimeNextSample:resd 1          ;tick time after next sample
section code


;-----------------------------------------------------------------------------
; To hear a single sample.
SampleEmu:
    mov ecx,[Sound.MixSamples]
    mov edi,MixBuffer
    mov esi,[.Ptr]
    mov edx,[.Acm]
    mov ebx,[.Mod]

.NextSample:
    ; Get sample and advance wave by playrate
    movsx eax,word [SamplesBuffer+esi*2]
    add edx,ebx
    adc esi,[.Inc]

    ; Merge voice into buffer
    ; (eax=sample value, edi=mix buffer ptr)
    imul eax,[.Vol]
    sar eax,8
    add [edi],eax

    ; Check for end of sample
    cmp [.End],esi
    jle .SampleEnd
.NotEnd:
    add edi,byte 4

    dec ecx
    jg .NextSample

    mov [.Ptr],esi
    mov [.Acm],edx
    ret

.SampleEnd:
    cmp dword [.Len],0          ;if no loop portion, stop playing
    jle .Stop
    sub esi,[.End]
    mov eax,[.Loop]
    add esi,eax                 ;sample point = current - end + loop base
    add eax,[.Len]
    mov [.End],eax              ;end = loop base + loop length
    jmp short .NotEnd

;---------------------------------------
; () (none)
.Stop:
    ; end of sample
    ;mov [.Ptr],esi
    and dword [PlayOptions],~PlayOptions.Sample
    ret

;(originally I was using a division here to constrain the sample ptr within
; its length; but there doesn't seem to be the need.

;---------------------------------------
; (esi=sample number)
.Start:
    cmp esi,GlobalSample.Max
    jb .StartContinue
    ret
.StartContinue:
    push esi
    call DecompressSample
    pop ebx

    ; in case a sample is already playing, turn it off for a moment
    and dword [PlayOptions],~PlayOptions.Sample

    ; calc sample and loop offsets in cache
    shl ebx,2                   ;table offset=sample number*4
    mov edi,9                   ;9 bytes per 4bit ADPCM block
    movzx eax,word [GlobalSample.Offset+ebx] ;get sample start first
    xor edx,edx
    div edi
    shl eax,4                   ;*16 (32/2 to use ADC)
    mov [.Ptr],eax
    add eax,[GlobalSample.Length+ebx]
    mov edx,[GlobalSample.LoopLen+ebx]
    mov [.End],eax
    mov [.Len],edx
    movzx eax,word [GlobalSample.Offset+ebx+2] ;then sample loop portion
    xor edx,edx
    div edi
    shl eax,4                   ;*16 (32/2 to use ADC)
    mov [.Loop],eax

    mov dword [.Acm],0
;---------------------------------------
; () (none)
.ChangeRate:
    ; calculate wave sample increment and modulus
    mov eax,256000
    imul dword [.PlayRate]
    xor edx,edx
    div dword [Sound.MixRate]
    mov edx,eax
    shr eax,15
    shl edx,17
    mov [.Inc],eax
    mov [.Mod],edx

    or dword [PlayOptions],PlayOptions.Sample
.IgnoreStart:
    ret


section data
align 4,db 0
.PlayRate:      dd 2048         ;4096=direct playrate 1:1
.Vol:           dd 128
section bss
alignb 4
.Ptr:           resd 1          ;current sample point
.Inc:           resd 1          ;sample increment
.Mod:           resd 1          ;sample increment modulus
.Acm:           resd 1          ;sample accumulator
.Loop:          resd 1          ;loop point
.End:           resd 1          ;end of sample point
.Len:           resd 1          ;loop length
section code


;-----------------------------------------------------------------------------
; Simply generates a square wave of a given tone.
; Useful for tuning.
;
; () ()
GenerateSquareWave:
    mov eax,[.Peak]
    mov ecx,[Sound.MixSamples]
    mov edx,[.Acm]
    mov ebx,[.Mod]
    mov edi,MixBuffer

.NextSample:
    add [edi],eax
    add edx,ebx
    jnc .SameSign
    neg eax
.SameSign:
    add edi,byte 4
    dec ecx
    jg .NextSample

    mov [.Acm],edx
    mov [.Peak],eax
    ret

;32000/440=72 samples
;440/32000=0.01375

.Start:
    mov eax,[.Hertz]
    mov ebx,[.Vol]
    shl eax,17                  ;move to top of dword
    xor edx,edx
    div dword [Sound.MixRate]
    mov [.Peak],ebx             ;set initial peak phase to volume
    shl eax,15
    mov [.Acm],dword 0
    mov [.Mod],eax
    ret

;.Stop:
;    ret


section data
align 4,db 0
.Hertz:         dd 440          ;A (max=32000)
.Vol:           dd 6800         ;good volume to constrast most samples
.Peak:          dd 6800
section bss
alignb 4
.Mod:           resd 1
.Acm:           resd 1
section code


;-----------------------------------------------------------------------------
; Simply generates a sine wave of a given tone.
; Useful for tuning.
;
; () ()
GenerateSineWave:
    mov ecx,[Sound.MixSamples]
    mov edx,[.Acm]
    mov ebx,[.Mod]
    mov esi,[.Ptr]
    mov edi,MixBuffer

.NextSample:
    ; Get sample and advance wave by playrate
    movsx eax,word [SineWaveTbl+esi*2]
    add edx,ebx
    adc esi,[.Inc]
    imul eax,[.Vol]
    sar eax,8
    add [edi],eax               ; Merge voice into buffer
    and esi,1023
    add edi,byte 4
    dec ecx
    jg .NextSample

    mov [.Ptr],esi
    mov [.Acm],edx
    ret

.Start:
    mov eax,[.Hertz]
    xor edx,edx
    shl eax,18                  ;move to top of dword
    mov [.Acm],edx              ;zero modulus accumulator
    mov [.Ptr],edx
    div dword [Sound.MixRate]
    mov edx,eax
    shr eax,8
    shl edx,24
    mov [.Inc],eax          ;sine wave increment
    mov [.Mod],edx          ;modulus

    ret

;.Stop:
;    ret


section data
align 4,db 0
.Hertz:         dd 440          ;A (max=32000)
.Vol:           dd 128
section bss
alignb 4
.Ptr:           resd 1          ;current sample point
.Inc:           resd 1          ;sample increment
.Mod:           resd 1          ;sample increment modulus
.Acm:           resd 1          ;sample accumulator
section code


;-----------------------------------------------------------------------------
; Reads the note buffer for new notes, converts them each into delta times and
; MIDI events, and records them to the file buffer.
; Since emulation is usually ahead of actual time, or since it might
; be recording from the note buffer already filled,it only reads the note
; buffer up to notes that are less than or equal to the current playing time,
; not the cycles simply emulated.
;
OutputMidiFile:
    ;start from last point in buffer
    ;read forward to end of buffer
    ;  if time that note should be played is less than cycle time then
    ;    if note is different from last note, set patch
    ;    if note is percussion, set channel to 10 and note value to instrument
    ;    commit the note to the MIDI file
    ;  elseif note time is greater than current time, exit loop

    mov edi,[Midi.FileBufferPtr];get ptr in MIDI buffer
    mov esi,[MidiSongPos.Pos]   ;get offset in DSP buffer
    ;debugwrite "at esi=%X",esi
    jmp short .ReadBuffer

;---------------------------------------
; Read next DSP register value stored in write buffer
; (esi=DSP buffer offset, edi=MIDI buffer ptr)
.NextFlushCheck:
    cmp edi,Midi.FileBuffer+Midi.FileBufferSize
    jb .NextBufferReg
    push esi
    mov [Midi.FileBufferPtr],edi
    call FlushMidiBuffer        ;start with new buffer
    pop esi
.NextBufferReg:
    add esi,byte 4
.ReadBuffer:
    cmp [DspBufferEnd],esi      ;beyond end of buffer?
    jbe .EndBuffer

.ReadBufferNoCheck:
    ; read next time value or register write
    mov eax,[DspBuffer+esi]
    cmp eax,0FF000000h          ;time value or register write?
    jb .CheckTime
    push dword .NextFlushCheck
    cmp al,DspReg.KeyOn
    je near .KeyOn
    cmp al,DspReg.KeyOff
    je near .KeyOff
    pop edx                     ;discard return address
    movzx ecx,al
    mov [MidiSongPos.DspRegs+ecx],ah
    jmp short .NextBufferReg
.CheckTime:
    mov [MidiSongPos.Time],eax
    cmp [PlayTimeEnd],eax       ;next dsp time > command time
    ja .NextBufferReg

.EndBuffer:
    mov [MidiSongPos.Pos],esi   ;save offset
    mov [Midi.FileBufferPtr],edi;save ptr in MIDI buffer
    ;mov eax,[PlayTimeEnd]
    ;mov [MidiSongPos.Time],eax
    ret

;---------------------------------------
; if note on
;   mark channel as on
;   get sample number
;   get instrument
;   if program different
;     write new program number
;   endif
;   if percussive
;     set channel to 10
;   else instrumental
;     store status byte
;     write zero delta time
;   endif
;   if note number out of range, limit to 0-127
;   if run mode, check if status byte is the same
;   write Midi.NoteOn, note number, velocity
;   store status byte, note number
; (ah=keys on, edi=MIDI buffer ptr) (edi=new buffer ptr; esi)
.KeyOn:
    mov bl,ah
    or [MidiSongPos.Active],ah  ;keys on |= new keys on
    and ebx,[EnabledVoices]
    or [MidiSongPos.Heard],bl   ;keys off &= keys heard on
    push edi                    ;save MIDI buffer ptr
    push esi                    ;save DSP buffer offset
    push ebx                    ;save keys on
    mov edi,MidiSongPos
    call SeekSongPos.SetGivenKeys
    pop ebx
    pop esi
    pop edi

.NextKon:
    bsf ecx,ebx                 ;find next voice to turn on
    jz near .EndKon
    btr ebx,ecx                 ;reset voice's bit

    call .WriteDeltaTime

    ; change current bank if necessary
    mov eax,32                  ;set controller 32 (bank lsb)
    mov ah,byte [MidiSongPos.Instrument+ecx*4+2] ;bank lsb 0-127
    cmp [.BanksLsb+ecx],ah
    je .SameBankLsb
    mov [.BanksLsb+ecx],ah
    shl eax,8                   ;shift controller number and value <<8
    lea eax,[eax+ecx+Midi.ControlChange] ;form byte command|channel
    mov [edi],eax               ;write command|controller|value|zero tick time
    add edi,byte 4
.SameBankLsb:
    xor eax,eax                 ;set controller 0 (bank msb)
    mov ah,byte [MidiSongPos.Instrument+ecx*4+3] ;bank msb 0-127
    cmp [.BanksMsb+ecx],ah
    je .SameBankMsb
    mov [.BanksMsb+ecx],ah
    shl eax,8                   ;shift controller number and value <<8
    lea eax,[eax+ecx+Midi.ControlChange] ;form byte command|channel
    mov [edi],eax               ;write command|controller|value|zero tick time
    add edi,byte 4
.SameBankMsb:

    ; change current program number if necessary
    lea eax,[ecx+Midi.PatchChange] ;form byte command|channel
    mov ah,byte [MidiSongPos.Instrument+ecx*4] ;patch 0-127
    cmp [.Patches+ecx],ah
    je .SameInstrument
    mov [.Patches+ecx],ah
    mov [edi],eax               ;write command|patch|zero tick time
    add edi,byte 3
.SameInstrument:

    ; check if voice is percussive or instrumental
    lea eax,[ecx+Midi.NoteOn]   ;form byte command|channel
    mov edx,[MidiSongPos.Volume+ecx*4]   ;get mono volume  (l+r *256)
    mov ah,byte [MidiSongPos.Instrument+ecx*4+1] ;drum 1-127, 0 means none
    test ah,ah
    jz .Instrumental
    mov al,Midi.NoteOn+9       ;form byte command|percussion channel
    jmp short .Percussive
.Instrumental:
    mov ah,byte [MidiSongPos.Pitch+ecx]  ;get MIDI note number
.Percussive: ;(eax=command byte|instrument)

    ; set volume (edx=volume)
    cmp edx,127<<8
    jbe .VolOk
    mov edx,127<<8              ;limit volume to max (0-127)
.VolOk:

    ; record note key on
    ; (eax=command byte|instrument, edx=volume)
    mov [.Commands+ecx],al      ;store last sent MIDI command on channel
    mov [.Pitches+ecx],ah       ;note number or percussive instrument
    mov [edi],eax               ;store command|note number
    mov [edi+2],dh              ;note velocity (volume)
    add edi,byte 3

    jmp .NextKon
.EndKon:

    ret

;---------------------------------------
; elif note off
;   mark channel as off
;   get status byte, note number
;   write Midi.NoteOff, note number, velocity
; endif
; (ah=keys off, edi=MIDI buffer ptr) (edi=new buffer ptr; esi)
.KeyOff:
    movzx ebx,ah
    not ah
    and bl,[MidiSongPos.Heard]  ;keys off &= keys heard on
    and [MidiSongPos.Active],ah ;keys on &= !new keys off
    xor [MidiSongPos.Heard],bl  ;keys heard ^= keys heard off

.KeyOffGiven:

.NextKof:
    bsf ecx,ebx                 ;find next voice to turn off
    jz .NoKofs
    ;debugwrite "note off ecx=%d ebx=%X",ecx,ebx
    btr ebx,ecx                 ;reset voice's bit

    call .WriteDeltaTime

    ;lea eax,[ecx+Midi.NoteOff+(96<<16)]
    mov eax,0F0h+(96<<16)       ;form byte command|channel|velocity off (arbitrary)
    add al,[.Commands+ecx]      ;combine with last sent kon|channel command
    mov ah,[.Pitches+ecx]       ;note number or percussive instrument
    mov [edi],eax               ;store command|note number|velocity
    add edi,byte 3
    jmp short .NextKof
.NoKofs:
    ret

;---------------------------------------
.WriteDeltaTime:
; (edi=MIDI buffer ptr) (edi=new ptr; esi,ebx,ecx)
    mov eax,[MidiSongPos.Time]

.WriteDeltaTimeGiven:
; (eax=tick time, edi=MIDI buffer ptr) (edi=new ptr; esi,ebx,ecx)

    ; writes big-endian delta time
    push ebx
    xor edx,edx
    div dword [Midi.DeltaDivisor]  ;time / divisor
    mov ebx,edi
    xchg [Midi.DeltaTime],eax
    sub eax,[Midi.DeltaTime]    ;previous time - now
    neg eax
    jns .DeltaTimeAbs
    xor eax,eax                 ;zero if delta time negative
.DeltaTimeAbs:

    inc edi
    mov edx,eax
    cmp eax,128
    jb .DeltaTimeDone
    and dl,7Fh
    shr eax,7
    shl edx,8
    inc edi
    mov dl,al
    or dl,80h
    cmp eax,128
    jb .DeltaTimeDone
    shr eax,7
    shl edx,8
    inc edi
    mov dl,al
    or dl,80h
.DeltaTimeDone:
    mov [ebx],edx
    pop ebx
    ret

;---------------------------------------
.StartIfEnabled:
    btr dword [PlayOptions],PlayOptions.MidiLogBit
    jnc .IgnoreStart
.Start:
    mov esi,Text.OpeningMidi
    call StatusMessage.Pending

    ; copy SPC/ZST filename to MIDI
    mov edi,MidiFileName
    mov esi,SpcFileName
    mov ecx,FilePathMaxLen/4
    push edi
    cld
    rep movsd

    ; replace file extension with .MID
    pop esi ;mov esi,MidiFileName
    call GetFileName            ;find filename in path
    cmp esi,MidiFileName+FilePathMaxLen-5
    ja .StartError
.NextFileChar:
    lodsb
    test al,al
    jz .FoundExt
    cmp al,'.'
    jne .NextFileChar
.FoundExt:
    mov dword [esi-1],'.mid'
    mov byte [esi+3],0

    ; attempt open
    mov esi,MidiFileName
    call CreateMidiFile
    jc .StartError
    ;mov esi,.Copyright
    ;mov ecx,.Copyright_size
    ;call WriteMidiEvent
    mov esi,Text.OpenedMidi
    call StatusMessage
    mov edi,MidiSongPos
    call SeekSongPos.Init
    or dword [PlayOptions],PlayOptions.MidiLog
    ret
.StartError:
    mov esi,Text.MidiOpenError
    call StatusMessage
.IgnoreStart:
    ret

;---------------------------------------
.Stop:
    btr dword [PlayOptions],PlayOptions.MidiLogBit
    jnc .IgnoreStop
    mov esi,Text.ClosingMidi
    call StatusMessage
    movzx ebx,byte [MidiSongPos.Heard]  ;keys off &= keys heard on
    mov edi,[Midi.FileBufferPtr]
    call .KeyOffGiven
    mov [Midi.FileBufferPtr],edi
    jmp CloseMidiFile
.IgnoreStop:
    ret

section bss
alignb 4
.Vars:
.Pitches:           resb 8      ;last used pitches for each voice
.Patches:           resb 8      ;last used instrument
.BanksLsb:          resb 8      ;low byte of currently selected bank
.BanksMsb:          resb 8      ;high byte of bank
.Commands:          resb 8
.VarsSize           equ $-.Vars
section text
.noteOff:           db 0,Midi.NoteOff,0,80
.Copyright:         db 1,0FFh,02h,7,"Unknown"
.Copyright_size     equ $-.Copyright
Text.OpeningMidi:   db "Opening MIDI file...",0
Text.ClosingMidi:   db "Closing MIDI file",0
Text.OpenedMidi:    db "Opened",0
Text.MidiOpenError: db "Error creating",0
section code
