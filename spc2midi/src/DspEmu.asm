; Spc2Midi - DSP Emulation
;
; Handles the emulation aspect of the DSP registers (not any sound output,
; which can be found in dspsim.asm). This mainly reacts to register writes
; and records them in the buffer.
;
; DspEmu - handles register writes and recording to the buffer
; DspEmu.Init - initializes DSP for emulation
; DecompressSample - decompresses a sample from the table, beginning and loop
; DecompressLocalSamples - decompresses all local samples
; DecompressAdpcm - decompresses 4-bit ADPCM data (aka BRR)
; GetAdpcmLength - finds length and validity of a compressed sample
; LocalSampleInfo - determines info of a single source directory entry, main and loop portions
; LocalSamplesInfo - determines info of all samples in the source directory table
; GetCheckSum - calculates the checksum for a range of data (mainly samples)
;
; todo:
;   l_king.sp3 allocates local sample=61 @FFFF:FFFF ?
;   l_king.sp3 does not release notes because checks for envelope==0
;   l_king.sp3 srcdir 31 clicks, perhaps another voice corrupts it
;   starfox monarch dodora boss music (bossmu|~5.spc) does not stop at end
;   find what the real SPC does for samples with range >12 (StarFox!)
;   don't record pitch waver used with most flute sounds (Zelda,FF3...)
;   do however record significant pitch slides (DKC Intro voice 3,
;    ChronoTrigger Frog's theme voice 1..). at least one song (Vortex:
;    Voltair Voice2) uses pitch sliding exclusively to change notes.
;   determine if pitch is sliding or merely being set for the next kon
;    (Macross final boss voice 5, Bof1 battle most voices). some games
;    depend on the envelope decay to silence a voice (rather than kof)
;    before its pitch is set for the kon.
;   Vortext "Big Beast" voice 4 (vortex13.spc) pitch is zero!? perhaps
;    used as a convenient way to keep a voice off? SpcTool also shows it
;    as zero.
;
; fixed:
;   learned SoulBlazer and ActRaiser both have the same sample loaded into
;    memory at two different offsets. one may simply be a phantom copy loaded
;    while playing a previous stage. whatever the reason, twas confusing me
;    because my code was choosing to play a sample at seemingly the wrong
;    offset, and yet it still sounded right because it was the SAME sample.
;   Zelda plays the same sample through different source numbers. 9&10
;    in light world.
;   learned GsMikami loads the same sample ptr into several entries.
;   Star wars ROTJ emperor's has sound. Game code was changing sample
;    pointers in the source directory while playing.
;   discovered why so many voices were silent. games have invalid ranges
;    or very short samples.
;
;
;-----------------------------------------------------------------------------
; Global DSP variables
;-------------------
section bss
alignb 4

;DspBufferSize      equ 262144*4 ;megabyte buffer to store DSP writes
DspBuffer:          resb DspBufferSize
; Holds all the notes generated from KeyOn and KeyOff writes to the DSP.
; Once the buffer is full, no more of the song can be played and emulation
; stops, but the buffer size should be large enough to hold any complete song.
; The longest song (non-repeating) I've heard so far is the Mario RPG ending,
; which fits fine. Vortex has really long songs too. Let me know IF you find
; any nonrepetitive ones that don't fit, stopping short of the end.

LocalSample:
; Information about each sound sample in the currently loaded SPC state,
; pointed to by the source directory. Each sample may have additional
; attributes associated with it from the GlobalSample list. There are a few
; reasons for this separation (rather than storing all attributes directly
; in this table):
; (1) Multiple source directory entries may point the same unique sample.
; (2) Games often remap entries in different levels, so attributes would be
;     wrongly associated to a directory entry number rather than the sample
;     itself.
; (3) Some games modify the entries while playing, so a given sample number
;     may actually play completely different samples between notes.
.Selected:          resd 1      ;selected sample
.Played:            resb 256/8  ;256 bit flags of samples have been keyed on by music code
.Valid:             resb 256/8  ;which srcdir entries seem valid based on various rules (even if they are not)
.GlobalIdx:         resd 256    ;ptrs into GlobalSample for more attributes about each sample
.Length:            resd 256    ;wave length in samples (not bytes), 0 if invalid sample
.LoopLen:           resd 256    ;length of loop portion in samples, 0 if no loop portion
.VoiceGlobalIdx:    resd 8      ;offsets of each current voice
.ClearSize         equ $-LocalSample
.Offset:            resd 256    ;word offsets of sample:loop
.Checksum:          resd 256    ;addition checksum of both sample and loop, any trailing odd bytes are zero extended

GlobalSample:
; Information/attributes for all game sound effects catalogued. These samples
; are uniquely identified by their length, loop length, and checksum. So when
; loading a new SPC state, all samples will be indentified and attributes
; will be carried over, regardless of how they are mapped in the source
; directory. Samples will even be crossmatched from different games, since
; different games by the same composers/producers may share common samples
; (like Actraiser and Soulblazer by Enix).
.Max                equ 512
.Played:            resb .Max/8 ;sample has been keyed on by game code
.Cached:            resb .Max/8 ;sample has been decompressed (only done when necessary)
.Disabled:          resb .Max/8 ;sample sound is disabled (0=enabled, 1=muted)
.Soloed:            resb .Max/8 ;sample is soloed (0=enabled, 1=muted)
.Selected:          resd 1      ;selected sample
.Offset:            resd 256    ;word offsets of sample:loop, indicates sample is contained locally in the current SPC state if nonzero
.LocalIdx:          resd .Max   ;matching BRR sample (if any)
.ReclearSize       equ $-GlobalSample    ;bytes to clear upon reinitialization
.Used:              resb .Max/8 ;contains data, otherwise empty slot
.Muted:             resb .Max/8 ;combined OR of dis&solo (0=enabled, 1=muted)
.Independant:       resb .Max/8 ;sample has own settings, not using default
.ClearSize         equ $-GlobalSample    ;bytes to clear upon initialization
.Entries:           resd 1      ;total number of entries in sample info list  >=1 (excludes empty entries)
.LastEntry:         resd 1      ;last entry (include empty entries)
.Length:            resd .Max   ;sample length (in samples, not bytes)
.LoopLen:           resd .Max   ;length of loop portion (in samples, not bytes) =0 if no loop portion
.Checksum:          resd .Max   ;addition checksum of both sample and loop
.Instrument:        resd .Max   ;MIDI instrument|patch|drum (program 0-127)|(drum 0-127<<8)|(bank<<16)
.Freq:              resd .Max   ;closest frequency when sample played at 32khz
.Volume:            resd .Max   ;volume relative to full MIDI volume
;.Interpolation:    resb .Max   ;simply for possible compatibility with SpcTool
.NameSize           equ 32
.NameMaxLen         equ 30 ;(size-2 for len byte and null char)
.NameShl            equ 5
.Name:              resb .Max  *.NameSize
.SizeOf             equ $-GlobalSample

DefaultSample:
.Length             equ 0
.LoopLen            equ 0
.Checksum           equ 0
.LocalIdx           equ -1
.Instrument         equ 46 ;46=orchestral strings
.Patch              equ 46 ;46=orchestral strings
.Bank               equ 0
.Track              equ 0
.Freq               equ 440
.Volume             equ 512 ;set higher than 127 because most voices are low
.Interpolation      equ 0


SamplesBufferSize   equ 232992  ;64k * (8/9) * 4
SamplesBuffer:      resb SamplesBufferSize


;-----------------------------------------------------------------------------
; DSP emulation constants
;-------------------

DspReg:
; DSP special registers, all are both read and write
; (the following apply to each of the 8 voices)
.VolLeft                equ 0   ;       VOLL volume of left channel, 8bits signed
.VolRight               equ 1   ;       VOLR volume of right channel, 8bits signed
.PitchLow               equ 2   ;       PL low byte of 14bit sample pitch
.PitchHigh              equ 3   ;       PH high byte, 1000h is 32khz
.SourceNumber           equ 4   ;       SRCN sample to play 0-255
.AttackDecay            equ 5   ;       Attack and decay rate
.Sustain                equ 6   ;       Sustain level and rate
.Gain                   equ 7   ;       GAIN ??
  .Gain_Amount          equ 224 ;       bits 0-4
  .Gain_Type            equ 31  ;       bits 5-7
  .Gain_Direct          equ 0
  .Gain_IncLinear       equ 128+64
  .Gain_IncBentLine     equ 128+64+32
  .Gain_DecLinear       equ 128+0
  .Gain_DecExponent     equ 128+32
.Envelope               equ 8   ; r     ENVX
.Outx                   equ 9   ; r     ??
.SampleLow              equ 0Ah ;       ! these registers are unused in SPC
.SampleHigh             equ 0Bh ;       ! so I use them for my own purposes
.Filter                 equ 0Fh ;
; (these apply to all channels)
.MainVolLeft            equ 0Ch ;       MVOL L
.MainVolRight           equ 1Ch ;       MVOL R
.EchoVolLeft            equ 2Ch ;       EVOL L
.EchoVolRight           equ 3Ch ;       EVOL R
.KeyOn                  equ 4Ch ;       KON voices 0-7, turn on
.KeyOff                 equ 5Ch ;       KOF voices 0-7, mute
.Flags                  equ 6Ch ;       FLG
  .Flags_SoftReset      equ 128
  .Flags_MuteAll        equ 64  ;       turns off all voices when true
  .Flags_Ecen           equ 32  ;       ECEN external memory echo ??
  .Flags_NoiseClock     equ 31  ;       NCK bits 0-4, noise generator clock
.Endx                   equ 7Ch ;       ENDX voices 0-7, flag voice sample has ended
.EchoFeedBack           equ 0Dh ;       EFB voices 0-7
;.Unused                equ 1Dh ;       --
.PitchModulation        equ 2Dh ;       PMOD voices 1-7 (voice 0 not affected)
.NoiseOnOff             equ 3Dh ;       NON voices 0-7
.EchoOnOff              equ 4Dh ;       EON voices 0-7
.SourceDirectory        equ 5Dh ;       DIR address of source directory * 256
.EchoDirectory          equ 6Dh ;       ESA address of echo region * 256 ??
.EchoDelay              equ 7Dh ;       EDL bits 0-3 ??


;-----------------------------------------------------------------------------
section code

DspEmu:
;
; What each register holds during emulation:
;
; al  = emulated flags
; ah  = temp flags, otherwise free
; bl  = A
; bh  = Y
; bx+ = instruction counter    (upper 16 bits)
; ecx = free for opcodes
; ch  = used byte read/write to return and set bytes
; dx  = free for opcode pointer use   (upper 16 bits must remain zero!)
; si  = current opcode pointer (upper 16 bits must remain zero!)
; edi = free for opcodes and register functions
; ebp = keeps current time as cycle counter
;
; X, direct page, and stack pointer are not kept in registers.
;
; Opcode routines may use ecx,edx,edi,ah.
; Read/write routines may only use ah,edi. All others must be saved.
; edx must be reset to F3h before returning (address of the dsp data
; register) before returning.
; Some instructions require the use of specific registers, such as cl for
; shifting and ax for multiplying. For these, the registers may be saved
; (push) or temporarily swapped with another (xchg).

;---------------------------------------
; () (!none)
.Init:
    mov dword [GlobalSample.Entries],1
    mov dword [GlobalSample.LastEntry],0
    mov dword [GlobalSample.Length],DefaultSample.Length
    mov dword [GlobalSample.LoopLen],DefaultSample.LoopLen
    mov dword [GlobalSample.Checksum],DefaultSample.Checksum
    mov dword [GlobalSample.LocalIdx],DefaultSample.LocalIdx

    mov eax,[DefaultInstrument]
    mov ebx,[DefaultVolume]
    mov ecx,[DefaultFreq]
    mov dword [GlobalSample.Instrument],eax ;DefaultSample.Instrument
    mov dword [GlobalSample.Volume],ebx ;DefaultSample.Volume
    mov dword [GlobalSample.Freq],ecx ;DefaultSample.Freq

    ;mov byte  [GlobalSample.Interpolation],DefaultSample.Interpolation
    mov dword [GlobalSample.Name],('(de'<<8)|9
    mov dword [GlobalSample.Name+4], 'faul'
    mov dword [GlobalSample.Name+8], 't)'

    cld
    xor eax,eax
    mov ecx,GlobalSample.ClearSize/4
    mov edi,GlobalSample
    rep stosd
    bts dword [GlobalSample.Used],eax
    ret

;---------------------------------------
; Call this after loading a new savestate or SPC.
; Must be called AFTER SpcEmu.Init
; Clears all local sample indexes to point to "Default"
; Clears certain variables from global table
; Clears decompreessed sample cache
; () (!none)
.Reinit:

    cld
    xor eax,eax

    mov ecx,GlobalSample.ReclearSize/4
    mov edi,GlobalSample
    rep stosd
    mov edi,LocalSample
    mov ecx,LocalSample.ClearSize/4
    rep stosd
    mov edi,SamplesBuffer
    mov ecx,SamplesBufferSize/4
    rep stosd

    mov dword [DspBufferEnd],eax
    mov dword [DspBufferTime],eax
    ;bts dword [DspFlags],DspFlags.NewVoiceBit

    xor ecx,ecx
    xchg byte [DspRam+DspReg.KeyOn],ch
    jmp DspEmu.wReg4C
    ;ret


;---------------------------------------
align 4
.ReadRegJumpTable:
; (empty for now)

.WriteRegJumpTable:
dd .wReg00,.wReg01,.wReg02,.wReg03,.wReg04,.wReg05,.wReg06,.wReg07,.wReg08,.wReg09,.wReg0A,.wReg0B,.wReg0C,.wReg0D,.wReg0E,.wReg0F
dd .wReg00,.wReg01,.wReg02,.wReg03,.wReg04,.wReg05,.wReg06,.wReg07,.wReg08,.wReg09,.wReg0A,.wReg0B,.wReg0C,.wReg0D,.wReg0E,.wReg0F
dd .wReg00,.wReg01,.wReg02,.wReg03,.wReg04,.wReg05,.wReg06,.wReg07,.wReg08,.wReg09,.wReg0A,.wReg0B,.wReg0C,.wReg0D,.wReg0E,.wReg0F
dd .wReg00,.wReg01,.wReg02,.wReg03,.wReg04,.wReg05,.wReg06,.wReg07,.wReg08,.wReg09,.wReg0A,.wReg0B,.wReg0C,.wReg0D,.wReg0E,.wReg0F
dd .wReg00,.wReg01,.wReg02,.wReg03,.wReg04,.wReg05,.wReg06,.wReg07,.wReg08,.wReg09,.wReg0A,.wReg0B,.wReg4C,.wReg0D,.wReg0E,.wReg0F
dd .wReg00,.wReg01,.wReg02,.wReg03,.wReg04,.wReg05,.wReg06,.wReg07,.wReg08,.wReg09,.wReg0A,.wReg0B,.wReg5C,.wReg5D,.wReg0E,.wReg0F
dd .wReg00,.wReg01,.wReg02,.wReg03,.wReg04,.wReg05,.wReg06,.wReg07,.wReg08,.wReg09,.wReg0A,.wReg0B,.wReg0C,.wReg0D,.wReg0E,.wReg0F
dd .wReg00,.wReg01,.wReg02,.wReg03,.wReg04,.wReg05,.wReg06,.wReg07,.wReg08,.wReg09,.wReg0A,.wReg0B,.wReg7C,.wReg0D,.wReg0E,.wReg0F
dd .wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX
dd .wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX
dd .wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX
dd .wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX
dd .wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX
dd .wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX
dd .wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX
dd .wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX,.wRegXX

;---------------------------------------
; (edx=register read/written, ch=value read/written)
; (edx=F3h; !ah)
;
; if pitch change (ignore if same value)
;   if key on (ignore if key off)
;     store new pitch value
;   endif
; endif
;
.wReg03: ;pitch, high 6bits of 14bit pitch, 1000h is 32khz
    and ch,3Fh
.wReg02: ;pitch, low 8bits of 14bit pitch, 1000h is 32khz
%if SupportPitchSlide
    mov edi,edx
    cmp [DspRam+edx],ch
    je .wReg02Same
    shr edi,4                   ;get voice #
    push ebx
    mov bh,[DspRam+edx]         ;get old value from register
    bt dword [DspRam+DspReg.KeyOn],edi
    mov [DspRam+edx],ch         ;save new value to register
    jnc .wReg02Ignore           ;ignore pitch change if voice off
    mov [DspRamCopy+edx],ch
    mov bl,ch
    ;mov edi,[DspBufferEnd]     ;get position in dsp buffer
    push edx
    call .RecordDspTime
    pop edx
    call .RecordDspRegVal
    mov [DspBufferEnd],edi      ;save position in dsp buffer
.wReg02Ignore:
    pop ebx
.wReg02Same:
    mov edx,0F3h                ;restore DSP data address
    ret
%endif

.wReg7C:;endx
    mov [DspRam+DspReg.Endx],byte 0  ;clear endx bits
    mov edx,0F3h                ;restore DSP data address
    ret

.wReg00:;left volume
.wReg01:;left volume
.wReg04:;sample source number
.wReg05:
.wReg06:
.wReg07:
.wReg08:
.wReg09:
.wReg0A:
.wReg0B:
.wReg0C:
.wReg0D:
.wReg0E:
.wReg0F:
.wReg5D:;source directory
    mov [DspRam+edx],ch         ;store new value to register
.wIgnore:
    mov edx,0F3h                ;restore DSP data address
    ret

;---------------------------------------
.wReg4C:;key on
    test ch,ch                  ;a lot of games send pointless commands
    jz .wIgnore                 ;like turning on zero keys
    push ebx
    push ecx
    push esi

    call .RecordDspTime

    ; turn off any keys already playing before turning them on again
    ; some games send another key on without keying off playing voices
    mov dh,ch
    and dh,[DspRam+DspReg.KeyOn]
    jz .KonAllNew
    ;xor [DspRam+DspReg.KeyOn],dh (unnecessary)
    mov dl,DspReg.KeyOff        ;set key_off address
    call .RecordDspAndRet
.KonAllNew:

    ; set kon & kof register bits
    mov ah,ch                   ;copy for loop below
    or [DspRam+DspReg.KeyOn],ch ;set new keys on
    not ch                      ;make mask
    and [DspRam+DspReg.KeyOff],ch  ;clear corresponding keys off
    and [DspRam+DspReg.Endx],ch ;clear endx bits

;-------------------
    ; Record pitch, volume, and brr source # in DSP buffer
    xor edx,edx                 ;start with volume register of first voice
    jmp .KonCheck
.KonNext:
    ;(ah=keyed voices, edx=DSP register base, edi=buffer dest ptr)
    call .RecordDspReg          ;left volume
    inc edx
    call .RecordDspReg          ;right volume
    inc edx
    call .RecordDspReg          ;pitch low
    inc edx
    call .RecordDspReg          ;pitch high
    inc edx
    call .RecordDspReg          ;source directory number

;-------------------
    ; get srcdir entry offset
    ; if offset differs previous offset
    ;   if sample of matching offset found
    ;     copy attributes from sample to srcdir entry
    ;   else
    ;     get source dir attributes (length, loop len, checksum)
    ;     if sample of matching attributes found (skip default)
    ;       set srcdir offset into sample
    ;     else
    ;       create new sample
    ;       !if no empty spots, use default as cheap hack, flag error
    ;       copy srcdir entry attributes to sample
    ;       flag to main loop new sample added, to add name
    ;     endif
    ;   endif
    ; endif

    ; check if voice's sample changed, either different number or offset
    movzx ebx,byte [DspRam+edx] ;get voice's current sample number
    movzx esi,byte [DspRam+DspReg.SourceDirectory]
    bts [LocalSample.Played],ebx  ;mark srcdir entry as being keyed on
    shl esi,8                   ;*256
    mov esi,[SpcRam+esi+ebx*4]  ;get sample offset from table *4 (two words per entry)
    cmp [LocalSample.Offset+ebx*4],esi
    jne .KonOffsetDif           ;sample offset altered by game code
    cmp dword [LocalSample.GlobalIdx+ebx*4],0
    jg near .KonOffsetSame      ;same offset

.KonOffsetDif:
    ; (ebx=srcdir entry, esi=spc sample ptr, edx=dsp reg X4)
    mov [LocalSample.Offset+ebx*4],esi
    ; ...add check for invalid sample starting at 0 or FFFFh...
    ; so that ROTJ doesn't allocate dummy samples
    bts [LocalSample.Valid],ebx     ;if used by the game, then it MUST be valid (even if it breaks one of the rules)

;---------
    ; first try to find a global sample of matching offset
    mov ecx,1                   ;start on second sample, skip default
.KonOfsMatchNext:
    cmp [GlobalSample.Offset+ecx*4],esi
    je .KonOfsMatch
    inc ecx
    cmp ecx,[GlobalSample.LastEntry]
    jbe .KonOfsMatchNext
    jmp short .KonOfsMatchNone
.KonOfsMatch:
    ; copy attributes from global to local sample
    push dword [GlobalSample.Length+ecx*4]
    push dword [GlobalSample.LoopLen+ecx*4]
    push dword [GlobalSample.Checksum+ecx*4]
    mov  dword [GlobalSample.LocalIdx+ecx*4],ebx
    mov  dword [LocalSample.GlobalIdx+ebx*4],ecx
    pop  dword [LocalSample.Checksum+ebx*4]
    pop  dword [LocalSample.LoopLen+ebx*4]
    pop  dword [LocalSample.Length+ebx*4]
    ;debugwrite "kon offset match s%d b%d",ecx,ebx
    jmp .KonOffsetSame
.KonOfsMatchNone:

    pusha

;---------
    ; no match found, so get sample attributes
    ; (ebx=source directory entry #)
    push ebx                    ;pass source dir entry #
    call LocalSampleInfo
    pop ebx
    mov eax,[LocalSample.Length+ebx*4]
    mov edx,[LocalSample.LoopLen+ebx*4]
    mov edi,[LocalSample.Checksum+ebx*4]

;---------
    ; second try to find global sample of matching attributes
    ; (ebx=source directory entry #)
    xor ecx,ecx                 ;start on second sample, skip default
.KonAtrMatchNext:
    inc ecx
    cmp ecx,[GlobalSample.LastEntry]
    ja .KonAtrMatchNone
    cmp [GlobalSample.Checksum+ecx*4],edi
    jne .KonAtrMatchNext
    cmp [GlobalSample.Length+ecx*4],eax
    jne .KonAtrMatchNext
    cmp [GlobalSample.LoopLen+ecx*4],edx
    jne .KonAtrMatchNext
.KonAtrMatch:
    ;debugwrite "kon atr match s%d b%d",ecx,ebx
    mov esi,[LocalSample.Offset+ebx*4]
    mov [LocalSample.GlobalIdx+ebx*4],ecx  ;set which global sample the local maps to
    mov [GlobalSample.LocalIdx+ecx*4],ebx
    mov [GlobalSample.Offset+ecx*4],esi
    jmp short .KonOffsetSet
.KonAtrMatchNone:

;---------
    ; still no match, so third add a new sample
    ; (ebx=source directory entry #)
    push ebx
    call NewSample
    pop ebx

.KonOffsetSet:
    popa
.KonOffsetSame:

;-------------------
    ; if current sample low byte !=
    ;   record sample low byte in reg 0Ah
    ; endif
    ; if current sample high byte !=
    ;  record sample high byte in reg 0Bh
    ; endif

    ; record if voice uses different sample
    ; (ebx=srcdir entry of current voice, edx=DSP reg base +4)
    mov esi,edx                 ;copy DSP reg base
    mov ecx,[LocalSample.GlobalIdx+ebx*4]
  %if 0;def debug
    push edi
    mov edi,ecx
    shl edi,GlobalSample.NameShl
    add edi,GlobalSample.Name+1
    debugwrite "dsp=%X brr=%d sample=%d name=%s",edx,ebx,ecx,edi
    pop edi
  %endif
    shr esi,4                   ;get voice 0-7 from DSP reg base
    mov ebx,ecx                 ;copy current sample
    xchg [LocalSample.VoiceGlobalIdx+esi*4],ecx  ;swap old for new

    ; record low&high bytes of different sample
    ; (ebx=new sample number, ecx=old sample number)
    add edx,byte 0Ah-4
    cmp bl,cl
    je .KonSsLow
    ;debugwrite "low sample byte=%d dsp=%X",ebx,edx
    push ebx
    mov bh,cl
    call .RecordDspRegVal
    pop ebx
.KonSsLow:
    inc edx                     ;set reg xBh
    cmp bh,ch
    je .KonSsHigh
    ;debugwrite "high sample byte=%d dsp=%X",ebx,edx
    mov bl,bh
    mov bh,ch
    call .RecordDspRegVal
.KonSsHigh:
    add edx,byte 16-0Bh         ;next voice

.KonCheck:
    shr ah,1                    ;was key turned on?
    jc near .KonNext
    lea edx,[edx+16]
    jnz .KonCheck               ;any more keys turned on?

;-------------------
    pop esi
    pop ecx
    pop ebx

    ; Record key on bits
    mov dl,DspReg.KeyOn         ;restore key_on address
    mov dh,ch                   ;copy value sent to register
    jmp short .RecordDspAndRet

%if 0
    call .RecordDspAndRet   ;was trying to figure out a voice that used
    pusha                   ;pitch sliding in Vortex
  .wait:
    mov ah,1
    int 16h
    jz .wait
    popa
    ret
%endif

;---------------------------------------
.wReg5C:;key off
    mov ah,[DspRam+DspReg.KeyOn];compare channels currently on
    and ah,ch                   ;with channels to turn off
    jz near .wIgnore            ;skip if command affects nothing
    xor [DspRam+DspReg.KeyOn],ah;clear any channels turned off
    or [DspRam+DspReg.KeyOff],ah;set voices as off

    call .RecordDspTime

    mov dl,DspReg.KeyOff        ;restore key_off address
    mov dh,ah                   ;copy value sent to register
    ;jmp short .RecordDspAndRet (fall through)

;---------------------------------------
; Records the value being written to a DSP register. Can either be called
; or jumped to. This routine does not record the previous value of the
; register, only the new one.
; Note the value actually written to the register by SPC code and the value
; to record may be different.
;
; (dl=dsp register,
;  dh=register value to record,
;  ch=value actually written,
;  edi=buffer ptr)
; (edx=F3h, edi+=4; *)
.RecordDspAndRet:
  %if 0;SpcDebugIoPrint
    pusha
    mov edi,Text.DspWrite
    call SpcEmu.PrintBreakWithValue
    popa
  %endif

    cmp edi,DspBufferSize-4     ;do not write past end of buffer
    jb .RdtNotFull
    push dword .RdtEnd
    jmp short .BufferEnd
.RdtNotFull:

    or edx,0FF000000h
    mov [DspBuffer+edi],edx     ;record register address & value
    add edi,byte 4              ;next event slot
.RdtEnd:
    mov edx,0F3h                ;restore DSP data address
    mov [DspBufferEnd],edi      ;save position in dsp buffer
    ret

;---------------------------------------
; Jumped to when buffer is full to insert an ending key off.
;
; (flags="cmp edi,DspBufferSize-4")
; (; edx)
.BufferEnd:
    ja .BufferFull              ;already was full
    push edx
    mov edi,[DspBufferTime]     ;get tick count of previous write
    mov edx,0FF000000h|DspReg.KeyOff
    inc edi
    mov dh,[DspRam+DspReg.KeyOn]
    mov [DspBufferTime],edi
    mov [DspBuffer+DspBufferSize-4],edx
    mov edi,DspBufferSize
    pop edx
.BufferFull:
    ret

;---------------------------------------
; Records the tick count of write.
;
; ()
; (edi=buffer ptr+4, edx=dsp buffer time; *)
.RecordDspTime:
    mov edi,[DspBufferEnd]      ;get end position in DSP buffer
    mov edx,[SpcEmu.TotalTime]  ;get tick count of write
    cmp edi,DspBufferSize-4     ;do not write past end of buffer
    jae .BufferEnd
    cmp [DspBufferTime],edx     ;very unlikely two events will have the
    je .RdtmEnd                 ;same time, but just in case..
    mov [DspBufferTime],edx     ;set latest time
    mov [DspBuffer+edi],edx     ;store tick time of dsp write
    add edi,byte 4
.RdtmEnd:
    ret


;---------------------------------------
; Records the value from a specified DSP register, other than the one
; currently being written to. Only new DSP values are recorded. If the
; register value between now and the last call are the same, nothing happens.
;
; (edx=dsp register to get value from, edi=buffer ptr)
; (edi+=4; edx,!ebx)
.RecordDspReg:
    mov bl,[DspRam+edx]
    mov bh,[DspRamCopy+edx]
    cmp bl,bh
    je .RdrEnd
    mov [DspRamCopy+edx],bl
; (bl=current value, bh=previous value)
.RecordDspRegVal:               ;call here for no check
  %if 0;SpcDebugIoPrint
    push ecx
    mov ch,[DspRam+edx]
    pusha
    mov edi,Text.DspWrite
    call SpcEmu.PrintBreakWithValue
    popa
    pop ecx
  %endif
    cmp edi,DspBufferSize-4     ;do not write past end of buffer
    jae .BufferEnd

    shl ebx,8                   ;move previous register value to third byte
    or ebx,edx                  ;copy register address to low byte
    or ebx,0FF000000h           ;flag that dword is a register write (and not timer value)
    mov [DspBuffer+edi],ebx     ;save both register address and value
    add edi,byte 4              ;next entry
.RdrEnd:
    ret

;---------------------------------------
.wRegXX:
    debugwrite "write reg xx"
    pusha
	mov [SpcEmu.AY],bx
	mov [SpcEmu.Pc],si
	mov [SpcEmu.Flags],al
    mov edi,MakeOperandString.Buffer
	call MakeOperandString
    mov edx,MakeOperandString.Buffer
	call WriteString
    mov edi,Text.DspWriteIllegal
    call SpcEmu.PrintBreakWithValue
    popa
    ret


;-----------------------------------------------------------------------------
; Reads all samples pointed to by the directory, setting their attributes.
; Also tests for validity.
;
; () (!)
LocalSamplesInfo:

; do not check if no SPC loaded
    cmp byte [DspRam+DspReg.SourceDirectory],0
    ja .ValidSrcDir
    ret
.ValidSrcDir:

    mov esi,Text.ValidatingSamples
    call StatusMessage

    xor ecx,ecx                 ;set starting sample
.Next:
    push ecx
    call LocalSampleInfo
    pop ecx
    inc cl
    jnz .Next
    ret


;-----------------------------------------------------------------------------
; Gets attributes of a single sample from the source directory, contained
; locally in the loaded SPC state. Gets info for both main and loop portions.
;
; (dword sample number) (!)
LocalSampleInfo:
.SampleNumber   equ 4

    mov ecx,[esp+.SampleNumber]
    shl ecx,2                   ;*4 (two words per entry)
    add ch,[DspRam+DspReg.SourceDirectory]  ;*256
    mov esi,[SpcRam+ecx]        ;get sample offset from table
    push esi                    ;save sample offsets

    and esi,65535               ;bottom word only for sample
    call GetAdpcmLength
    mov [.Loop],al              ;save header byte
    lea edi,[esi+ecx]           ;figure end byte
    push edx                    ;save sample length
    add esi,SpcRam              ;GetCheckSum requires an absolute address
    call GetCheckSum
    test byte [.Loop],2         ;check header byte for if sample is looped
    jnz .Looped

    cmp [esp],dword 16*3        ;sample must be at least 3 blocks long (48 samples)
    jae .SizeOk
    inc ebx                     ;or else consider it garbage
.SizeOk:
    push dword 0                ;zero loop length
    jmp short .SampleEnd

.Looped:
    ; check that main and loop portions are aligned
    movzx esi,word [esp+4+2]    ;retrieve sample offset of loop portion
    sub edi,esi                 ;last byte after main <= loop portion
    jbe .LoopSeparate
    cmp [esp+4],si              ;starting portion > loop portion
    ja .LoopSeparate
    ; (eax=checksum, edi=loop length in bytes)
    xchg eax,edi                ;swap checksum with byte after main portion
    mov ecx,9                   ;9 bytes per 4bit ADPCM block
    xor edx,edx
    div ecx
    test edx,edx
    mov eax,edi                 ;restore checksum into eax again
    jz .LoopSeparate
    inc ebx                     ;main portion and loop portion aren't aligned

.LoopSeparate:
; (eax=sample checksum, esi=loop offset, ebx=number of errors)
    push eax                    ;save checksum of main portion
    call GetAdpcmLength.GivenErrors
    mov [.Loop],al              ;save header byte
    pop eax                     ;get previous checksum of sample
    push edx                    ;save sample length of loop portion
    add esi,SpcRam              ;GetCheckSum requires an absolute address
    call GetCheckSum.StartingWith
    test byte [.Loop],2         ;check header byte for if sample is looped
    jnz .SampleEnd              ;if it is, then ok
    inc ebx                     ;else loop portion is not looped!
.SampleEnd:

    ; if no errors in either main or loop portion, mark as valid
    mov ecx,[esp+12+.SampleNumber]   ;get sample number
    test ebx,ebx
    jnz .SampleInvalid
    bts [LocalSample.Valid],ecx
    jmp short .SampleValid
.SampleInvalid:
    btr [LocalSample.Valid],ecx
.SampleValid:

    ; set length, loop length, offsets, and checksum
    shl ecx,2                   ;sample number*4
    mov [LocalSample.Checksum+ecx],eax  ;save checksum of both sample and loop portion
    pop dword [LocalSample.LoopLen+ecx] ;set sample loop length in table
    pop dword [LocalSample.Length+ecx]  ;set sample length in table
    pop dword [LocalSample.Offset+ecx]  ;set offsets of sample and loop portion

    ret

section bss
.Loop:  resb 1
section code


;-----------------------------------------------------------------------------
; Returns info about a portion of BRR data including: byte length, sample
; length, its last block header, and the data's validity. Simply determines
; attributes, does not decompress. Returns the length of only the portion
; given. For the length of the loop portion too, the loop portion offset in
; RAM must be passed to it separately.
;
; Performs several tests on the sample to determine whether it is valid or
; just random junk, returning the number of errors found.
;
; Disqualifying conditions include:
;   Starting in direct page RAM (0-1FFh)
;   Overlapping the ROM (FFC0h-FFFFh)
;   Invalid shift range (>12)
;   Loop bit inconsistently set
;   If part of main sample, loop portion must align (MOD 9)
;   Unlooped sample too short (<48)
;   Loop portion does not have loop bit set
;
; Hopefully there are no games that violate any of these expected rules.
; In some ways, Spc2Midi is much more selective than SpcTool, which helps
; eliminate more garbage samples, but in other cases, SpcTool is more
; disriminating.
;
; Already found out that at least one game that breaks a rule. StarFox has a
; sample with a shift range of 13, and a loop portion of only 16 samples.
;
; Some of these rules are implemented by this routine; other rules are tested
; elsewhere.
;
; Other possible conditions unimplemented:
;   Loop portion not being within main sample
;   Using a filter in the first block
;
; Generally the loop portion is simply the tail end of the main sample, but
; there is no guarantee that all games do this. Although I've never seen it,
; some game might use different attacks that share the same sustain portion.
; If, however, the loop IS within main sample, the loop must align to it
; (evenly divisible by 9).
;
; Since filters are always dependant on samples that came before them, a
; filter in the first block wouldn't make sense, since there aren't any
; preceding it. In case a game does, I simply zero the two 'previous' point
; values.
;
; Very rarely are samples shorter than 48 points. You can almost be certain
; (almost) that any unlooped sample only 16 or 32 points is invalid. The only
; sample I've ever that was so short was a looped 16 point square wave from
; Star Fox.
;
; (esi=sample offset in SPC RAM)
; (al=header byte of last block
;  ebx=number of errors,
;  ecx=sample byte length,
;  esi=sample offset unchanged)
GetAdpcmLength:
    xor ebx,ebx                 ;initially no invalidating errors
.GivenErrors: ;(ebx=continued error count)
    mov ah,[SpcRam+esi]         ;get header byte
    xor edx,edx                 ;zero point length
    mov ecx,esi
    cmp esi,512                 ;sample should not start in direct page RAM
    jae .LoopValid
    inc ebx                     ;count error++
    xor eax,eax                 ;return zero header byte
    jmp short .Abort
    align 16
.CheckNext:
    xor al,ah
    test al,2                   ;loop bit consistently set?
    jz .LoopValid
    inc ebx                     ;count error++
  .LoopValid:
    ;cmp ecx,65463              ;sample should not overlap ROM
    ;jbe .PtrValid
    cmp ecx,65536-9             ;sample must not wrap RAM
    jbe .PtrValid
    inc ebx                     ;count error++
    jmp short .Abort
  .PtrValid:
    mov al,[SpcRam+ecx]         ;get header byte
    add ecx,byte 9              ;next BRR block
    cmp al,(13<<4)|15           ;range must be valid 0-12 (changed to 13 now)
    jbe .ValidRange             ;some StarFox samples contain invalid ranges!
    inc ebx                     ;count error++
  .ValidRange:
    add edx,byte 16             ;count another 16 sample points from block
    test al,1
    jz .CheckNext

.Abort:
    sub ecx,esi
    ;test ebx,ebx               ;set zero flag
    ret


;-----------------------------------------------------------------------------
; Buffers all 256 samples from source directory into sound wave buffer,
; checking that each one is valid before expanding.
;
; () (!)
DecompressLocalSamples:
    mov esi,Text.BufferingSamples
    call StatusMessage

    xor ecx,ecx
.Next:
    bt [LocalSample.Valid],ecx
    jnc .SkipSample
    push ecx
    call DecompressSample.Local
    pop ecx
.SkipSample:
    inc cl
    jnz .Next

    ret


;-----------------------------------------------------------------------------
; Decompresses a whole sample, including both the main and loop portion of it.
;
; (dword sample number) (!)
DecompressSample.Local:
    ; get local sample's offset in SPC RAM from source directory
    xor ebx,ebx
    mov ecx,[esp+4]             ;get source directory entry number
    mov bh,[DspRam+DspReg.SourceDirectory]  ;*256
    mov esi,[SpcRam+ebx+ecx*4]  ;get sample address from directory table
    jmp short DecompressSample.GivenOffset

DecompressSample:
    ; get global sample's offset
    mov ecx,[esp+4]             ;get source directory entry number
    mov esi,[GlobalSample.Offset+ecx*4]

.GivenOffset: ;(esi=offset pair sample|loop<<16)
    push esi                    ;save sample offsets

    ; expand starting sample into wave buffer
    and esi,65535               ;bottom word only for sample
    call DecompressAdpcm
    test al,2
    pop edi                     ;retrieve sample offsets
    jz .SampleEnd

    ; expand loop portion into wave buffer
    mov ebx,edi                 ;copy main portion offset
    shr edi,16                  ;sample offset of loop portion is top word
    cmp di,si                   ;loop portion >= last byte after main
    jae .LoopSeparate
    cmp di,bx                   ;loop portion < starting portion
    jb .LoopSeparate            ;if loop portion is part of main sample
.SampleEnd:                     ; then don't bother to decompress again
    ret

.LoopSeparate:
    mov esi,edi
    jmp DecompressAdpcm.Loop    ;start given previous filters
    ;ret

.Loop   equ LocalSampleInfo.Loop


;-----------------------------------------------------------------------------
; Decompresses a 4bit ADPCM sample into the buffer. Filters are implemented.
;
; This routine assumes the sample has already been checked for validity and
; isn't just random data (which makes a nice static sound). If it is invalid,
; the routine will happily decompress the garbage data anyway (just in case
; it really is valid wave data but was misidentified).
;
; What to do about blocks with invalid ranges with seems to be a matter of
; disagreement among various SPC players. I chose to clip the range to the
; maximum 12, but later found that SpcTool sets the range to zero, while
; ZSNES uses the valid shift of the previous block. Only the real SNES can
; say which is best.
;
; (esi=sample offset in SPC RAM)
; (eax=header byte of last block
;  ecx=byte length,
;  edx=sample length,
;  esi=offset at end of sample)
DecompressAdpcm:
    ; zero previous samples used by filters
    xor eax,eax
    mov dword [.PrevSample],eax ;previous sample before current one
    mov dword [.PrevSample2],eax;sample two back from current one

.Loop:
    ; calculate desination in buffer (sample_offset / 9 * 32)
    push ebp
    mov ebx,9
    mov eax,esi                 ;for the division
    xor edx,edx
    push esi                    ;save sample base for later
    div ebx                     ;/9
    push dword 0                ;set sample length counter to zero
    shl eax,5                   ;*32
    lea edi,[SamplesBuffer+eax]

    xor eax,eax
    mov ebx,[.PrevSample]       ;previous sample before current one
    align 16
.Next:
;(eax<=255!, esi=brr source, edi=buffer dest)
    mov al,[SpcRam+esi]         ;get header byte
    inc esi
    mov ecx,eax                 ;copy header byte
    and eax,15                  ;isolate filter and end bits only
    shr ecx,4                   ;get range from top four bits
    not ecx
    add ecx,29|(8<<8)           ;get 28-range  (!range+29)
    ;cmp cl,16
    ;jae .RangeOk
    ;mov cl,16
    ;;mov cl,31
.RangeOk:
                                ;and set counter for eight bytes to follow
.NextByte:
    mov dl,byte [SpcRam+esi]    ;get high nybble
    and dl,0F0h                 ;mask out low nybble
    shl edx,24                  ;move high nybble to top of dword
    sar edx,cl                  ;apply range to high nybble

    ; if any filters needed
    ;   if two filters
    ;     filters = filter1 * [current sample-1]
    ;             - filter2 * [current sample-2]
    ;   else one filter
    ;     filters = filter1 * [current sample-1]
    ;   endif
    ;   sample += filters
    ; endif

    ; apply filter to high nybble
    cmp eax,1000b
    jb .NoSecondFilter1
    mov ebp,ebx                 ;copy previous sample
    xchg [.PrevSample2],ebx     ;get second sample back & swap with previous
    imul ebp,[.FilterTbl+eax*4]
    imul ebx,[.FilterTbl2+eax*4]
    add ebx,ebp                 ;filter1 + -filter2
    jmp short .AddFilter1
.NoSecondFilter1:
    ;mov ebx,[.PrevSample]      ;(unnecessary)
    mov [.PrevSample2],ebx
    cmp eax,100b
    jb .NoFilter1
    imul ebx,[.FilterTbl+eax*4]
.AddFilter1:
    sar ebx,8                   ;/256
    add edx,ebx                 ;sample value + filters
    cmp edx,32768               ;check for sample overflow
    jb .NoFilter1               ;-32768 - 32767
    cmp edx,-32768
    jae .NoFilter1
    sar edx,31                  ;extend sign down
    xor edx,32767
.NoFilter1:
    ;mov [.PrevSample],edx      ;(unnecessary)
    mov [edi],dx                ;store high nybble first

    mov bl,byte [SpcRam+esi]    ;get low nybble
    shl ebx,28                  ;move low nybble to top of dword
    sar ebx,cl                  ;apply range to low nybble

    ; apply filter to low nybble
    cmp eax,1000b
    jb .NoSecondFilter2
    mov ebp,edx                 ;copy previous sample
    xchg [.PrevSample2],edx     ;get second sample back & swap with previous
    imul ebp,[.FilterTbl+eax*4]
    imul edx,[.FilterTbl2+eax*4]
    add edx,ebp                 ;filter1 + -filter2
    jmp short .AddFilter2
.NoSecondFilter2:
    ;mov edx,[.PrevSample]      ;(unnecessary)
    mov [.PrevSample2],edx
    cmp eax,100b
    jb .NoFilter2
    imul edx,[.FilterTbl+eax*4]
.AddFilter2:
    sar edx,8                   ;/256
    add ebx,edx                 ;sample value + filters
    cmp ebx,32768               ;check for sample overflow
    jb .NoFilter2               ;-32768 - 32767
    cmp ebx,-32768
    jae .NoFilter2
    sar ebx,31                  ;extend sign down
    xor ebx,32767
.NoFilter2:
    ;mov [.PrevSample],ebx      ;(unnecessary)
    mov [edi+2],bx              ;store low nybble last

    inc esi
    add edi,byte 4
    dec ch
    jg near .NextByte

    add dword [esp],byte 16     ;sample count+=16
    test eax,1
    jnz .BrrEnd
    cmp esi,65536-9
    jbe near .Next
.BrrEnd:

    pop edx                     ;retrieve length in samples
    pop ecx                     ;retrieve sample base
    pop ebp
    sub ecx,esi                 ;byte_length = -(ending_offset - starting_offset)
    mov [.PrevSample],ebx       ;for next call (if loop exists)
    neg ecx
    ret


section bss
alignb 4
.PrevSample:    resd 1          ;previous sample before current one
.PrevSample2:   resd 1          ;sample two back from current one
section data
align 4
; All filter ratios are scaled up to a common denominator of 256
; 15/16=240/256  61/32=488/256  115/64=460  13/16=208/256
.FilterTbl equ $-16             ;don't store any filter values for filter 0
    dd 240,240,240,240, 488,488,488,488, 460,460,460,460
.FilterTbl2 equ $-32            ;don't store any filter values for filter 0&1
    dd -240,-240,-240,-240, -208,-208,-208,-208
section code


;-----------------------------------------------------------------------------
; This function's purpose is for uniquely identifying a given sample,
; although it could actually checksum anything. The checksum that it returns
; is the dword sum of the raw sample, not the expanded sample. The final
; dword (for any samples with lengths not an even multiple of four) will be
; masked to exclude the last few bytes which are not part of the sample, then
; added to the checksum. For a looped sample, this function must be called
; twice for a complete checksum, once for the sample beginning and again for
; the loop portion.
;
; (esi=source, ecx=byte length)
; (eax=addition checksum; ebx,edi)
GetCheckSum:
    xor eax,eax                 ;zero checksum
;(eax=existing checksum)
.StartingWith:
    mov edx,ecx                 ;copy length
    shr ecx,2                   ;/4 get dwords
    jz .LastBytes
.NextDword:
    add eax,[esi]               ;add to checksum
    add esi,byte 4
    loop .NextDword
.LastBytes:
    and edx,3                   ;%4 get leftover bytes
    jz .NoLastBytes
    shl edx,3                   ;*8
    bts ecx,edx                 ;set bit in ecx (which is zero from the loop above)
    dec ecx                     ;make mask, = 1 << ((sampleLength and 3) * 8)
    and ecx,[esi]               ;get final dword
    add eax,ecx                 ;add final few bytes to checksum
.NoLastBytes:
    ret
