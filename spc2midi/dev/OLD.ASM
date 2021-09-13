; This file simply consists of old routines that no longer need to be part of
; the executable, but still may have some later value.
;
; **** This file is deletable ****

<SPC2MIDI.ASM>
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SeekNoteNext:
    mov esi,[NoteBufferPos]
    mov eax,[TickTime]
    mov edx,[NoteBufferEnd]
    mov [NoteBufferPrevPos],esi
    jmp short .First
.Next:
    cmp [NoteBuffer+esi],eax    ;is time when note was recorded greater than current time
    ja .End
    add esi,byte 8
.First:
    cmp esi,edx                 ;check current position with end
    jb .Next
.End:
    mov [StSongPos.Time],eax
    mov [NoteBufferPos],esi
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Seeks a specified position in the Note Buffer, appropriately setting which
; notes are on/off, which channels have changed, and what each pitch is.
; This is mainly used for the note display modes, to simplify their code so
; they do not need to read the note buffer.
;
; (edi=seek structure, edx=new time to seek)
; (esi=new position)
;
SeekNote:
    ;start from given position
    ;loop until buffer pos >= buffer end or note time >= specified time
    ;  if note on
    ;    set note is on, flag note was turned on
    ;    set channel's instrument and pitch
    ;  elif note off
    ;    set note is off, flag note was turned off
    ;  endif
    ;endloop

    xor ecx,ecx  ;also needed for loop below
    mov esi,[edi+SeekNoteStruct.Pos]
    push dword ecx  ;keys turned off
    mov dword [edi+SeekNoteStruct.Change],ecx  ;clear any key changes
    jmp short .Start

    ; start loop
.Next:
    mov eax,[NoteBuffer+esi+4]

    ;   if note on
    ;     get voice/channel
    ;     turn on channel
    ;     copy attributes from buffer to current channel attributes
    ;     flag change in channel
    ;   else...
    test al,15
    mov cl,al
    jnz .OnEnd
    shr ecx,4
    bts [edi+SeekNoteStruct.Used],ecx
    mov [edi+SeekNoteStruct.Atrs+ecx*4],eax
    bts [edi+SeekNoteStruct.Change],ecx
    jmp short .ToNext
.OnEnd:

    ;   elif note off
    ;     get voice/channel
    ;     turn off channel
    ;     flag change in channel
    ;     if not already turned off once before
    ;       copy current channel attributes to previous attributes
    ;       copy current channel pitch to previous pitch
    ;     endif
    ;   endif
    test al,14
    jnz .OffEnd
    shr ecx,4  ;get voice/channel
    btr [edi+SeekNoteStruct.Used],ecx
    bts [esp],ecx  ;if channel wasn't already turned off once already
    jc .OffEnd
    bts [edi+SeekNoteStruct.Change],ecx
    mov eax,[edi+SeekNoteStruct.Atrs+ecx*4]
    mov [edi+SeekNoteStruct.PrevAtrs+ecx*4],eax
    mov bl,[edi+SeekNoteStruct.Pitches+ecx]
    mov [edi+SeekNoteStruct.PrevPitches+ecx],bl
    ;jmp short .ToNext
.OffEnd:

    ;   next note event in buffer
    ; endloop while not beyond buffer end and note time < desired time
.ToNext:
    add esi,byte NoteBuffer.eSize       ;next note in buffer
.Start:
    cmp [NoteBufferEnd],esi     ;beyond end of buffer?
    jbe .EndLoop
    cmp [NoteBuffer+esi],edx    ;reached desired time yet?
    jb .Next
.EndLoop:

    ; flag change for any channels enabled or disabled by user since last call
    ; channels on     = channels changed & channels used
    ; new channels   |= ((channels on & channels enabled)
    ;                   ^ channels previously active)
    ; channels active = channels on & channels enabled
    ;!!!
    mov eax,[edi+SeekNoteStruct.Change]
    mov ebx,[edi+SeekNoteStruct.Used]   ;get which channels are on/off
    and eax,ebx                         ;get channels turned on
    ;and ebx,[MutedVoices]              ;turn off any user disabled channels
    mov [edi+SeekNoteStruct.Pos],esi    ;save new position in buffer
    mov ecx,ebx
    ;xor ebx,[edi+SeekNoteStruct.Active]
    mov [edi+SeekNoteStruct.Active],ecx
    mov [edi+SeekNoteStruct.On],eax
    ;mov [edi+SeekNoteStruct.Change],eax
    ;or [edi+SeekNoteStruct.Change],ebx

    ;(eax=notes turned on)
    ;mov eax,[edi+SeekNoteStruct.Change]
    xor ecx,ecx
    jmp short .FirstVoice
.NextVoice:
    mov edx,[edi+SeekNoteStruct.Atrs+ecx*4]  ;get voice/sample number/pitch
    shld ebx,edx,16+2
    and ebx,1111111100b         ;make ptr of sample number
    mov ebx,[BrrTable.AtrsIdx+ebx]
    sub dh,byte 207             ;reduce note value for 32khz playrate to 0
    add dh,[SampleList.HalfSemitone+ebx]
    shr dh,1                    ;note number = half-semitone / 2
    mov [edi+SeekNoteStruct.Pitches+ecx],dh
    ;mov [edi+SeekNoteStruct.Pitches+ecx],byte 0
.SkipVoice:
    inc ecx
.FirstVoice:
    shr eax,1
    jc .NextVoice
    jnz .SkipVoice

    add esp,byte 4              ;discard flags for channels turned off
    ret                         ;(esi=new position in buffer)

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ<SOUND.ASM> 
    mov esi,[NoteBufferPlayed]
    cmp [NoteBufferEnd],esi
    jbe near .End2
.NextNote:
    mov eax,[NoteBuffer+esi]    ;get cycle time when note was recorded
    cmp [TickTime],eax
    jb near .End
    movzx eax,byte [NoteBuffer+esi+4]   ;get voice number
.KeyOn:
    test al,15
    jnz .KeyOff
    shr eax,4                   ;select voice
    movzx ebx,byte [NoteBuffer+esi+6] ;get sample number
    bt dword [ActiveChannels],eax
    jnc .AfterKeyChange
    mov edi,[BrrTable.AtrsIdx+ebx*4]
    ;shl edi,SampleList.Shift
    mov bl,[SampleList.Instrument+edi]
    cmp [Sound.UsedFmPatches+eax*4],bl
    je .SameInstrument
    mov [Sound.UsedFmPatches+eax*4],bl
    push eax                    ;save voice
    push esi                    ;save pointer in note buffer
    shl ebx,4                   ;*16 get instrument information
    lea esi,[SbFm.PatchData+ebx];get ptr to instrument information in patch table
    call SetFmPatch
    pop esi
    pop eax
.SameInstrument:
    call SoundNoteOn
    jmp short .AfterKeyChange
    ;jmp short .DebugPause
.KeyOff:
    test al,14
    jnz .KeyPitchChange
    shr eax,4                   ;select voice
    bt dword [ActiveChannels],eax
    jnc .AfterKeyChange
    call SoundNoteOff
    ;jmp short .AfterKeyChange
.KeyPitchChange:
    ;call something...
.AfterKeyChange:
    add esi,byte 8
    cmp [NoteBufferEnd],esi     ;ptr < NoteBufferSize
    ja near .NextNote

.End:
    mov [NoteBufferPlayed],esi
.End2:
    ret


;====================
; Turns a channel on (using the current patch for that channel)
;
;(esi=ptr in note buffer, eax=voice)
SoundNoteOn:
    bts dword [Sound.ChannelsOn],eax    ;flag that voice was turned on recently
    btr dword [Sound.ChannelsOff],eax   ;clear that voice needs to be turned off
    bts dword [Sound.ChannelsUsed],eax  ;flag voice is in use
    mov edi,eax                 ;make copy of voice number
    jnc .AlreadyOff
    add al,0B0h                 ;DSP register, low byte of pitch
    ;xor ah,ah                   ;turn voice off
    call WriteSbReg
.AlreadyOff:

    mov dl,[NoteBuffer+esi+5]   ;get nearest half-semitone
    movzx ebx,byte [NoteBuffer+esi+6] ;get sample number
    mov ebx,[BrrTable.AtrsIdx+ebx*4]
    sub edx,207                 ;reduce playrate to centerpoint, for any samples at 32khz (~4096 rate)
    ;shl ebx,SampleList.Shift
    add dl,[SampleList.HalfSemitone+ebx]
    and edx,11111110b           ;get MIDI note number (*2)
    lea eax,[edi+0A0h]          ;DSP register, low byte of pitch
    mov ebx,[SbFreqTbl+edx]     ;get fnumber for note's pitch
    mov ah,bl
    call WriteSbReg
    lea eax,[edi+20B0h]         ;DSP register, high byte of pitch (20h turns voice on)
    mov [Sound.UsedFnumbers+edi],bh ;save fnumber/octave to eliminate click when turning voice off
    or ah,bh
    jmp WriteSbReg
;.End:
;    ret

;====================
;(esi=ptr in note buffer, eax=voice)
SoundNoteOff:
    bt dword [Sound.ChannelsOn],eax     ;was voice recently turned on
    jc .Later                           ;if so, turn if off the next call
.Now:
    btr dword [Sound.ChannelsUsed],eax  ;clear voice as being used
    mov ah,[Sound.UsedFnumbers+eax]     ;get previous fnumber/octave of voice, to prevent clicking sound
    add al,0B0h                         ;DSP register, low byte of pitch
    ;xor ah,ah                          ;turn voice off, as long as bit 20h is clear
    jmp WriteSbReg
.Later:
    bts dword [Sound.ChannelsOff],eax   ;simply flag voice as needing to be turned off
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ<DSPEMU.ASM>
;GetSampleWaveAttributes:
; My dream function that awaits completion! :)
; Not sure exactly how I'll get it to work... :(
;
; Scans from the start point to the end of the sample (usually starting at
; the loop point or beginning of the sample if there is none) to return the
; dominant frequency and average volume.
;
;  1  ÜÜÜ       ÜÜÜ         ÚÄÄÄÄ¿    ÚÄÄÄÄ¿
;  0 ßßßßßÜÜÜÜÜßßßßßÜÜÜÜÜ   Ùùùùù³ùùùù³ùùùù³ùùùùÚ
; -1       ßßß       ßßß         ÀÄÄÄÄÙ    ÀÄÄÄÄÙ
;    ³L ³³R ³³³³³³   LEFT - RIGHT = TOTAL
;    ÀÂÄÙÃÂÄÙ³³³³³        4 - -2 =  6    2+6+8 =  16  close
;     ÀÂÄÙÃÂÄÙ³³³³        4 - -4 =  8
;      ÀÂÄÙÃÂÄÙ³³³        2 - -4 =  6
;       ÀÂÄÙÃÂÄÙ³³        0 - -2 =  2
;        ÀÂÄÙÃÂÄÙ³       -2 -  0 = -2
;         ÀÄÄÙÀÄÄÙ       -4 -  2 = -6
;    ÀÄÄÄÙÀÄÄÄÙ           5 - -5 = 10    2+6+10 = 18  perfect resonance
;     ÀÄÄÄÙÀÄÄÄÙ          3 - -3 =  6
;      ÀÄÄÄÙÀÄÄÄÙ         1 - -1 =  2
;       ÀÄÄÄÙÀÄÄÄÙ       -1 -  1 = -2
;        ÀÄÄÄÙÀÄÄÄÙ      -3 -  3 = -6
;         ÀÄÄÄÙÀÄÄÄÙ     -5 -  5 = 10
;    ÀÄÄÄÄÙÀÄÄÄÄÙ         4 - -2 =  6    2+6+8 =  16  close
;     ÀÄÄÄÄÙÀÄÄÄÄÙ        2 -  0 =  2
;      ÀÄÄÄÄÙÀÄÄÄÄÙ       0 - -2 = -2
;       ÀÄÄÄÄÙÀÄÄÄÄÙ     -2 -  4 = -6
;        ÀÄÄÄÄÙÀÄÄÄÄÙ    -4 -  4 = -8
;         ÀÄÄÄÄÙÀÄÄÄÄÙ   -4 -  2 = -6
;    ÀÄÄÄÄÄÄÄÄÙÀÄÄÄÄÄÄÄÄÙ 0 -  0 =  0    0+0+0 = 0    complete cancellation
;   ret

<SPC2MIDI.ASM>
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; FM attributes for sound effects.
SoundFxList:
.Total              equ 300
.eSize              equ 64
.Shift              equ 4
.MultMod            resb 1  ;amp mod/vib/eg/key scale/multiple
.MultCar            resb 1
.LevelMod           resb 1  ;key scale level/volume
.LevelCar           resb 1
.AtkDecMod          resb 1  ;attack rate/decay rate
.AtkDecCar          resb 1
.StnRlsMod          resb 1  ;sustain level/release rate
.StnRlsCar          resb 1
.FormMod            resb 1  ;waveform
.FormCar            resb 1
.FeedBack           resb 1  ;feedback level/connection
.Name:              resb .eSize+$-SoundFxList
.NameSize           equ 30
                    resb ($-SoundFxList)*(.Total-1)
.Used:              resb .Total/8 ;bit flags to indicate which entries contain information


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ<DSPEMU.ASM>
BrrSampleExpand: ;(no filters)
...
.NextByte:
    mov dl,byte [SpcRam+esi]    ;get high and low nybble
    mov ebx,edx
    shl edx,28                  ;move low nybble to top of dword
    shl ebx,24                  ;move high nybble to top of dword
    sar edx,cl                  ;apply range to low nybble
    sar ebx,cl                  ;apply range to high nybble
    mov [edi],bx                ;high nybble is stored
    mov [edi+2],dx              ;before low nybble
    inc esi
    add edi,byte 4
    dec ch
    jg .NextByte

<DSPEMU.ASM>
; To debug the sample processing
    mov ecx,Screen.Height
    mov edi,Screen.Adr+(Screen.Width/2)
    mov esi,[.Ptr]
    mov edx,[.Acm]
    mov ebx,[.Mod]

    lea eax,[SamplesBuffer+esi*2]
.NextSample:
    ; Get sample and advance wave by playrate
    movsx eax,word [SamplesBuffer+esi*2]
    add edx,ebx
    adc esi,[.Inc]

    ; Merge voice into buffer
    ; (eax=sample value, edi=mix buffer ptr)
    xchg ah,[.Cols+ecx-1]
    movsx eax,ah
    mov byte [edi+eax],0
    movsx eax,byte [.Cols+ecx-1]
    mov byte [edi+eax],15

    ; Check for end of sample
    cmp [.End],esi
    jle .SampleEnd
.NotEnd:
    add edi,Screen.Width

    dec ecx
    jg .NextSample

    mov [.Ptr],esi
    mov [.Acm],edx
    mov [.Mod],ebx
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ<DSPEMU.ASM>
BrrSampleExpand:
    ; note this routine assumes the sample has already been checked for
    ; validity!
    mov dword [.PrevSample],0   ;previous sample before current one
    mov dword [.PrevSample2],0  ;sample two back from current one

    ; calculate desination in buffer (sample_offset / 9 * 32)
    mov eax,esi                 ;for the division
    mov ebx,9
    xor edx,edx
    push esi                    ;save sample base for later
    div ebx                     ;/9
    push dword 0                ;set sample length counter to zero
    shl eax,5                   ;*32
    lea edi,[SamplesBuffer+eax]
    xor eax,eax
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
                                ;and set counter for eight samples to follow
.NextByte:
    mov dl,byte [SpcRam+esi]    ;get high nybble
    and dl,0F0h                 ;mask out low nybble
    shl edx,24                  ;move high nybble to top of dword
    sar edx,cl                  ;apply range to high nybble

    ; apply filter to high nybble
    cmp eax,1000b
    jb .NoSecondFilter1
    mov ebx,[.PrevSample2]
    imul ebx,[.FilterTbl2+eax*4]
    sar ebx,8                   ;/256
    sub edx,ebx
.NoSecondFilter1:
    mov ebx,[.PrevSample]
    mov [.PrevSample2],ebx
    cmp eax,100b
    jb .NoFilter1
    imul ebx,[.FilterTbl+eax*4]
    sar ebx,8                   ;/256
    add edx,ebx
.NoFilter1:
    mov [.PrevSample],edx
    mov [edi],dx                ;store high nybble first

    mov bl,byte [SpcRam+esi]    ;get low nybble
    shl ebx,28                  ;move low nybble to top of dword
    sar ebx,cl                  ;apply range to low nybble

    ; apply filter to low nybble
    cmp eax,1000b
    jb .NoSecondFilter2
    mov edx,[.PrevSample2]
    imul edx,[.FilterTbl2+eax*4]
    sar edx,8                   ;/256
    sub ebx,edx
.NoSecondFilter2:
    mov edx,[.PrevSample]
    mov [.PrevSample2],edx
    cmp eax,100b
    jb .NoFilter2
    imul edx,[.FilterTbl+eax*4]
    sar edx,8                   ;/256
    add ebx,edx
.NoFilter2:
    mov [.PrevSample],ebx
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

    mov ecx,esi
    pop edx                     ;retrieve length in samples
    pop esi                     ;retrieve sample base
    sub ecx,esi                 ;[OR] byte_length = starting_offset - ending_offset
    ret


section bss
alignb 4
.PrevSample:    resd 1          ;previous sample before current one
.PrevSample2:   resd 1          ;sample two back from current one
section data
align 4
; All filter ratios are scaled up to a denominator of 256
; 15/16=240/256  61/32=488/256  115/64=460  13/16=208/256
.FilterTbl equ $-16             ;don't store any filter values for filter 0
    dd 240,240,240,240, 488,488,488,488, 460,460,460,460
.FilterTbl2 equ $-32            ;don't store any filter values for filter 0&1
    dd 240,240,240,240, 208,208,208,208
section code


<SOUND.ASM>
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Copies mixing buffer to sound card buffer. Ensures the output and DMA are
; synchronized, in you switch away to Windows, or in case the sound card does
; not have accurate timing (which I have found!). It tries to always stay
; one interrupt's buffer length ahead of the sound card.
;
; () ()
CopyMixBuffer: #1
    call GetDmaLag
%if 1
    mov [Sound.DmaPos],eax
    neg eax
    mov edx,[Sound.BufferPos]
    ;mov [Sound.BufferPre],edx
    add eax,edx
    and eax,Sound.BufferSize-1
    mov edx,[Sound.BufferDif]
    mov [Sound.BufferDif],eax
    sub eax,edx
    mov [Sound.BufferPre],eax
%endif

    mov edi,[Sound.BufferPtr]
    mov edx,[Sound.BufferPos]
    mov esi,MixBuffer
    mov ecx,[Sound.MixSamples]
    add edi,edx

    ; resync if necessary
    ;test byte [SoundFlags],SoundFlags.Resync
    ;jz

    ; check for buffer and wrap and transfer from mix buffer to sound buffer
    test byte [SoundFlags],SoundFlags.16bit
    jz .8bit
    shr edx,1                   ;/2 for words
    add edx,ecx                 ;buffer offset + number of mixed samples
    sub edx,(Sound.BufferSize/2) ;buffer end > buffer size?
    jl .16bitNoWrap
    sub ecx,edx
    call TransferWave16bit
    mov ecx,edx
    sub edi,Sound.BufferSize
    ;mov edi,[Sound.BufferPtr]
.16bitNoWrap:
    call TransferWave16bit
    jmp short .TransferDone
.8bit:
    add edx,ecx                 ;buffer offset + number of mixed samples
    sub edx,Sound.BufferSize    ;buffer end > buffer size?
    jl .8bitNoWrap
    sub ecx,edx
    call TransferWave8bit
    mov ecx,edx
    sub edi,Sound.BufferSize
    ;mov edi,[Sound.BufferPtr]
.8bitNoWrap:
    call TransferWave8bit
.TransferDone:

    sub edi,[Sound.BufferPtr]
    and edi,Sound.BufferSize-1
    mov [Sound.BufferPos],edi
    ret


<SOUND.ASM>
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Copies mixing buffer to sound card buffer. Ensures the output and DMA are
; synchronized, in case you switch away to Windows, or in if the sound card
; does not have accurate timing (which I have found!). It tries to always
; stay one interrupt's buffer length or more ahead of the sound card.
;
; () ()
CopyMixBuffer: #2
    push ebp
    call GetDmaLag              ; BufferPos - DmaPos should be ÷IntSamples
    mov [Sound.BufferDif],eax   ;*** debug ***

    ; check deviation difference
    ; Unnacceptable deviation is <=IntSamples*.5 | >=IntSamples*1.5
    ; Allowable deviation is >=IntSamples*(1/16)
    ;mov ecx,[Sound.MixSamples]
    mov ecx,[Sound.IntSamples]
    mov edx,ecx
    sub eax,ecx                 ;deviation = (buffer pos - DMA pos) - samples per int
    shr edx,1                   ;/2
    cmp eax,edx
    jbe .Synced                 ;difference < (samples per int / 2) unsigned
    jge .WayOff                 ;difference >= (samples per int / 2)
    neg eax
    cmp eax,edx                 ;-difference >= (samples per int / 2)
    jge .WayOff
    ;jmp short .Synced

.OffSync:
    ; Say we are playing at 22khz and are 80 samples behind, here's how to
    ; scale the contents of the MixBuffer to the output buffer.
    ;   22050hz / 30 frames per second = 735 samples per interrupt
    ;   735 / 16 minumum deviation percentage = 45 minimum deviation samples
    ;   80 samples behind - 45 minimum deviation = 35
    ;   35 + 735 samples per int = 770 samples to catch up
    ;   735 / 770 = .954 ratio
    ; Since decimal points are unuseable, shift up before the division.
    ; The maximum samples per interrupt (playrate of 64khz) is 2134, so shift
    ; up by the max amount that will keep it in 32 bits. 2^20
    ;   735 << 20 = 770703360
    ;   770703360 / 770 = 1000913
    ;   1000913 << (32-20) to put it at the very top of the dword
    ;   4099739648 / 4294967296
     ; Now every time the numerator is added and overflows, carry will be set
    ; and the source ptr will advance by one.

%if 0
    mov eax,[Sound.MixSamples]
    mov ecx,[Sound.IntSamples]
    inc ecx
    mov [Sound.IntSamples],ecx
    shl eax,20                  ;*1048576
    xor edx,edx
    div ecx                     ;samples per int / sb samples
    shl eax,12                  ;move bit 19 up to bit 31
    mov edx,eax
    jmp short .CopyBuffer

%else
    xchg eax,ecx                ;swap samples per int with samples behind
    ;xor eax,eax
    add ecx,eax                 ;sb samples = samples behind + samples per int
    shl eax,20                  ;*1048576
    xor edx,edx
    div ecx                     ;samples per int / sb samples
    shl eax,12                  ;move bit 19 up to bit 31
    mov edx,eax
    dec edx
    jmp short .CopyBuffer
%endif

.WayOff:
    ;inc dword [Sound.BufferPre] ;*** debug ***
    mov eax,[Sound.DmaPos]
    add eax,ecx                 ;+=Sound.MixSamples
    and eax,Sound.BufferSize-2  ;wrap within buffer to nearest word
    mov [Sound.BufferPos],eax

.Synced:
    mov edx,-1

; (ecx=buffer sample count, edx=modulus increment)
.CopyBuffer:
    ;mov esi,MixBuffer
    mov ebp,[Sound.DmaMod]      ;remainder accumulator
    mov ebx,[Sound.BufferPtr]
    mov edi,[Sound.BufferPos]
    ;shr esi,2                   ;/4
    xor esi,esi

    test byte [SoundFlags],SoundFlags.16bit
    jz .8bitNext

.16bitNext:
    and edi,Sound.BufferSize-2  ;wrap (to even word)
    mov eax,[esi*4]
    add ebp,edx
    adc esi,0
    cmp eax,32768
    jb .16bitValid
    cmp eax,-32768
    jae .16bitValid
    sar eax,31                  ;sign extend
    xor eax,32767
.16bitValid:
    mov [ebx+edi],ax
    add edi,byte 2
    dec ecx
    jg .16bitNext
    jmp short .End

.8bitNext:
    and edi,Sound.BufferSize-1  ;wrap
    mov eax,[esi*4+MixBuffer]
    cmp esi,[Sound.IntSamples]
    jb .ok
    inc dword [Sound.BufferPre] ;*** debug ***
.ok:
    add ebp,edx
    adc esi,0
    add eax,32768               ;toggle sign bit for conversion to 8bit
    test eax,0FFFF0000h
    jz .8bitValid
    sar eax,31                  ;sign extend
    not eax
.8bitValid:
    mov [ebx+edi],ah
    inc edi
    dec ecx
    jg .8bitNext

.End:
    mov [Sound.DmaMod],ebp
    and edi,Sound.BufferSize-1
    mov [Sound.BufferPos],edi
    pop ebp
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
<SOUND.ASM>
CopyMixBuffer #3

    push ebp
    call GetDmaLag
    mov dword [SoundDebug.Lag],eax

    ; check deviation difference
    ; BufferPos - DmaPos should be ÷MixSamples
    ; unnacceptable deviation is <=IntSamples*.5 | >=IntSamples*1.5
    mov edx,[Sound.MixSamples]
    mov ecx,edx
    jmp short .Synced ;***
    shr edx,1                   ;/2 half samples per interrupt
    sub eax,edx                 ;deviation = lag - (samples per int / 2)
    jle .OffSync                ;difference <= (samples per int / 2)
    cmp eax,ecx
    jb .Synced                  ;difference >= (samples per int / 2)

.OffSync:
    ; resync buffer position ahead of what DMA is currently reading
    ;mov edi,[Sound.BufferPos]

    mov edi,[Sound.DmaPos]
    add edi,ecx                 ;+=Sound.MixSamples
    and edi,Sound.BufferSize-2 ;wrap within buffer to nearest word
    inc dword [SoundDebug.Counter]
    jmp short .CopyBuffer

; (ecx=mixed samples to copy,)
.Synced:
    shr dword [Sound.MixedSamples],1
    shr dword [Sound.DmaSamples],1
    add [Sound.MixedSamples],ecx
    mov edi,[Sound.BufferPos]
    add [Sound.DmaSamples],ebx

; (ecx=mixed samples to copy, edi=buffer position)
.CopyBuffer:
    mov esi,MixBuffer
    mov ebp,[Sound.DmaSamples]
    mov ebx,[Sound.BufferPtr]
    mov edx,[Sound.DmaMod]      ;remainder accumulator
    sub ebp,[Sound.MixedSamples]  ;numerator = DMA samples - mixed samples
    mov dword [SoundDebug.DifSamples],ebp ;***

    ;***
    ;xor edx,edx
    mov dword [SoundDebug.OutSamples],0
    ;xor ebp,ebp
    ;mov ebp,[SoundDebug.SampleInc]
    ...


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
<SOUND.ASM>
SyncToDma:
    ; read address from 8237 DMA controller (weird configuration)
    mov edx,[Sound.DmaChannel]
    xor eax,eax                 ;zero address
    cmp dl,4
    jae .Hdma
    mov ecx,eax                 ;zero left shift
    out 0Ch,al                  ;clear flip-flop (value is irrelavant)
    shl edx,1                   ;*2 address port
    jmp short .ReadAddress
.Hdma:
    lea edx,[0C0h+edx*4-16]     ;address port
    out 0D8h,al                 ;clear flip-flop (value is irrelavant)
    mov cl,1                    ;set left shift (address*2)
.ReadAddress:
    in al,dx                    ;get address low byte
    mov ah,al
    in al,dx                    ;get address high byte
    xchg al,ah                  ;correct high/low byte order

    ; get offset in buffer & calculate lag
    shl eax,cl                  ;*2 for 16bit channel, *1 for 8bit channel
    ;mov edx,[Sound.IntSamples]
    mov edx,[Sound.MixSamples]
    sub eax,[Sound.BufferPtr]   ;buffer offset = DMA address - base ptr
    mov ecx,edx
    shr ecx,2                   ;/4
    mov ebx,[Sound.BufferPos]
    add eax,ecx                 ;+25% hack for Crystal Audio
    and eax,Sound.BufferSize-1
    sub ebx,eax                 ;lag = buffer pos - trailing DMA pos
    ; this does not use cl from above because some sound cards utilize low
    ; DMA channels for 16bit data
    and ebx,Sound.BufferSize-1
    test byte [SoundFlags],SoundFlags.Force8bit
    jnz .8bit
    shr ebx,1                   ;lag /2 for words
.8bit:

    ;mov [PrintDebugInfo.Value1],eax
    ;mov [PrintDebugInfo.Value2],ebx

    ; check deviation difference (BufferPos - DmaPos should be >=IntSamples)
    ; (eax=DMA buffer offset, ebx=lag, edx=int samples)
    sub ebx,edx                 ;lag < buffer size
    jb .Behind                  ;we're falling behind, DMA will soon beat us
    sub ebx,edx                 ;lag < (buffer size * 2)
    jb .InSync                  ;just fine
    cmp ebx,edx                 ;we're faster than DMA
    jb .Ahead

; somehow got way off (Alt+Tab probably to blame)
; (eax=DMA buffer offset, edx=buffer size)
.OffSync:
    ; resync buffer position ahead of what DMA is currently reading
    lea ebx,[edx+edx*2]         ;Sound.IntSamples*3
    test byte [SoundFlags],SoundFlags.Force8bit
    jnz .8bitResync
    shl ebx,1                   ;*2 if words, else bytes
.8bitResync:
    shr ebx,1                   ;/2  (*3/2 = 1.5)
    add ebx,eax                 ;(Sound.IntSamples*1.5)+Dma address
    and ebx,Sound.BufferSize-2  ;wrap within buffer to nearest word
    mov [Sound.BufferPos],ebx
.InSync:
    ret

; (edx=buffer size)
.Behind:
    lea edx,[edx+edx*2]         ;mix 1.5 buffers
.Ahead:
    shr edx,1                   ;mix .5 buffers
    ret



;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
<DSPEMU.ASM>
ValidateBrrSample:
    cmp esi,256                 ;sample should not start in direct page RAM
    jb .Invalid
    mov ah,[SpcRam+esi]         ;get header byte
    mov ecx,esi
    mov al,ah
    align 16
.CheckNext:
    xor al,ah
    test al,2                   ;is loop bit inconsistently set?
    jnz .Invalid
    cmp ecx,65463               ;sample should not overlap ROM
    ;cmp ecx,65536-9             ;sample should not wrap RAM
    ja .Invalid
    mov al,[SpcRam+ecx]         ;get header byte
    add ecx,byte 9              ;next BRR block
    cmp al,(13<<4)|15           ;range must be valid 0-12 (changed to 13 now)
    ja .Invalid                 ;some StarFox samples contain invalid ranges!
    test al,1
    jz .CheckNext
    sub ecx,esi
    ;(zero flag always clear)
    ret

.Invalid:
    xor ecx,ecx                 ;set byte length to 0
    ;(zero flag set)
    ret

<SOUND.ASM>
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%if 0
.PatchDefault:  db   2h,  1h;2
                db  10h,  0h
                db  99h,074h;f4
                db  88h,0FFh
                db   0h,  0h
                db   0h
%endif


<SPC2MIDI.ASM>
%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Set the title of a Windows DOS BOX. No longer necessary now that a Windows
; version of this program is in the works.
; (esi=asciiz text ptr) ()
SetWindowsTitle:
    call GetStringLength        ; (esi=source) (ecx=length)

    xor ebx,ebx
    mov [Regs.eax],dword 168Eh  ;set/get Window attribute
    mov [Regs.ecx],ecx          ;set string length (seems unnecessary)
    mov [Regs.ebx],ebx
    mov [Regs.edx],ebx          ;set window title
    mov [Regs.edi],ebx          ;zero string ptr
    mov [Regs.es],word 0BA00h
    ; just use untouched text memory for temp storage
    ; rather than hassle with allocating low DOS memory
    mov edi,0BA000h
    inc ecx                     ;include null
    cld
    rep movsb

    mov eax,0300h               ;simulate real mode interrupt
    mov ebx,2Fh                 ;DOS multiplex interrupt
    ;xor ecx,ecx                ;no stack copy
    mov edi,Regs
    int 31h

    ;bt dword [Regs.Flags],0    ;set carry if error
    ret
%endif

%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Simply wipes ranges of memory using a ptr/length list.
;
ZeroMemory:
.Next:
    cld
    xor eax,eax
.Next:
    mov edi,[esi]
    mov ecx,[esi+4]             ;must be in dwords (not bytes!)
    test edi,edi
    jz .End
    rep stosd
    ;mov ebx,ecx
    ;and ecx,3
    ;rep stosb
    add esi,byte 8
    jmp short .Next
    ret
%endif


%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; ()() zero based selector is stored in AbsoluteSelector
GetAbsoluteSelector:
    xor eax,eax                 ;DPMI function 0, allocate selector
    mov ecx,1                   ;only one selector
	int 31h
	jc .ErrorAllocating	;uh-oh
    mov [AbsoluteSelector],eax  ;store returned selector
    xor edx,edx                 ;set base address to zero
    mov ebx,eax                 ;copy selector
    xor ecx,ecx                 ;put upper 16 bits into ecx (cx:dx)
    mov eax,7                   ;DPMI function 7, set base address
	int 31h
    jc .ErrorSetting            ;could not set base
	xor edx,edx
    mov ecx,(1048576*2)>>16     ;put upper 16 bits into ecx (cx:dx)
    mov eax,8                   ;DPMI function 8, set segment limit
	int 31h
    jc .ErrorSetting            ;could not set limit
	ret

.ErrorSetting:
	mov ebx,[AbsoluteSelector]
	mov eax,1		;DPMI function 1, free selector
	int 31h			;ebx should still contain our selector
	stc
.ErrorAllocating:
	mov edx,Text.ErrorGettingSelector
	ret

align 4
AbsoluteSelector:       dd 0
%endif


<SOUND.ASM>
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Transfer mixing buffer to low memory for sound card, converting wave buffer
; data to 8bit unsigned and clipping.
;
; (esi=source data, edi=destination, ecx=samples)
; (esi=new source ptr, edi=new dest ptr; ebx,edx)
TransferWave8bit:
.Next:
    mov eax,[esi]
    add eax,32768               ;toggle sign bit for conversion to 8bit
    add esi,byte 4
    test eax,0FFFF0000h
    jz .Valid
    sar eax,31                  ;sign extend
    not eax
.Valid:
    mov [edi],ah
    inc edi
    dec ecx
    jg .Next
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Transfer mixing buffer to low memory for sound card, converting wave buffer
; data to 16bit signed and clipping.
;
; (esi=source data, edi=destination, ecx=samples)
; (esi=new source ptr, edi=new dest ptr; ebx,edx)
TransferWave16bit:
.Next:
    mov eax,[esi]
    add esi,byte 4
    cmp eax,32768
    jb .Valid
    cmp eax,-32768
    jae .Valid
    sar eax,31                  ;sign extend
    xor eax,32767
.Valid:
    mov [edi],ax
    add edi,byte 2
    dec ecx
    jg .Next
    ret
%endif

<SOUND.ASM>
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

    ; send recently mixed buffer to sound driver
  %if 0 ;****
    xor edi,edi
    bt dword [Sound.lpwh0+WAVEHDR.dwFlags],0
    rcl edi,4
    bt dword [Sound.lpwh1+WAVEHDR.dwFlags],0
    rcl edi,4
    bt dword [Sound.lpwh2+WAVEHDR.dwFlags],0
    rcl edi,4
    bt dword [Sound.lpwh3+WAVEHDR.dwFlags],0
    rcl edi,4
    shr edi,3
  %endif

  %if 0
    mov ebx,eax ;****
    api waveOutGetPosition, [Sound.hwo], Sound.MmTime,MMTIME_size
    xor ecx,ecx
    bt dword [Sound.lpwh0+WAVEHDR.dwFlags],0
    rcl ecx,4
    bt dword [Sound.lpwh1+WAVEHDR.dwFlags],0
    rcl ecx,4
    bt dword [Sound.lpwh2+WAVEHDR.dwFlags],0
    rcl ecx,4
    bt dword [Sound.lpwh3+WAVEHDR.dwFlags],0
    rcl ecx,4
    shr ecx,3
    debugwrite "  %d=wow ba=%X t=%d m=%d f=%04x->%04x",ebx,esi,[Sound.MmTime+MMTIME.sample],[Sound.MixTime],edi,ecx
  %endif

  %if 0
    mov ecx,[Sound.IntSamples]
    mov [Sound.MixTime],ecx
    mov esi,Sound.lpwh0
    mov dword [esi+WAVEHDR.dwFlags],WHDR_DONE|WHDR_BEGINLOOP|WHDR_ENDLOOP
    mov dword [esi+WAVEHDR.dwLoops],-1
    mov dword [esi+WAVEHDR.dwBufferLength],Sound.FrameSize
    api waveOutWrite, [Sound.hwo],esi,WAVEHDR_size
  %endif

  %if 0
    mov dword [Sound.MixTime],Sound.FrameSize/2
    mov esi,Sound.lpwh0
    mov dword [esi+WAVEHDR.dwBufferLength],Sound.FrameSize
    api waveOutWrite, [Sound.hwo],esi,WAVEHDR_size
    api Sleep,1000
  %endif

  %if 0
  .AgainAndAgainAndAgain:
    api waveOutGetPosition, [Sound.hwo], Sound.MmTime,MMTIME_size
    debugwrite "t=%d",[Sound.MmTime+MMTIME.sample]
    jmp short .AgainAndAgainAndAgain
  %endif

    ;test dword [esi+WAVEHDR.dwFlags],WHDR_DONE
    ;jz .WriteError

%if 0
    api waveOutGetPosition, [Sound.hwo], Sound.MmTime,MMTIME_size
    mov eax,[Sound.MmTime+MMTIME.sample]
    mov ecx,eax
    xchg [Sound.DmaLag],eax
    sub eax,[Sound.DmaLag]
    neg eax
    sub ecx,[Sound.MixTime]
    neg ecx
    debugwrite "mix=%d drv=%d dif=%d lag=%d",[Sound.MixTime],[Sound.DmaLag],ecx,eax
    ret
%endif

  %if 0
    mov ecx,[Sound.MmTime+MMTIME.sample]
    mov ebx,[Sound.MixTime]
    mov eax,ecx
    sub ecx,ebx
    debugwrite "mix=%d drv=%d dif=%d",ebx,eax,ecx
  %endif

%if 0 ;#3 almost but not quite
    api waveOutGetPosition, [Sound.hwo], Sound.MmTime,MMTIME_size
    mov ebx,[Sound.MmTime+MMTIME.sample]
    mov edx,[Sound.IntSamples]  ;- frame size
    cmp [Sound.DmaTime],ebx
    je .StalledDriver
    mov eax,ebx
    xchg [Sound.DmaTime],ebx
    sub ebx,[Sound.DmaTime]     ;previous time - current time
    add ebx,edx                 ;+ frame samples
    mov ecx,ebx;****
    xchg [Sound.DmaLag],ebx
    add ebx,[Sound.DmaLag]
    sar ebx,1                   ;lag = (current lag + previous lag) / 2
    add edx,ebx                 ;frame samples += lag
.StalledDriver:
%endif

%if 0 ;#4
    api waveOutGetPosition, [Sound.hwo], Sound.MmTime,MMTIME_size
    mov ebx,[Sound.MmTime+MMTIME.sample]
    mov edx,[Sound.IntSamples]  ;- frame size
    mov eax,ebx
    sub ebx,[Sound.MixTime]
    lea edx,[ebx+edx*2]
%endif

%if 0 ;#6
    mov ecx,[Sound.IntSamples]  ;- frame size
    shr ecx,1
    cmp edx,ecx
    jb .SetFs
    lea ecx,[ecx+ecx*2]
    cmp edx,ecx
    jbe .FsOk
.SetFs:
    mov edx,ecx
.FsOk:
%endif

%if 0
    cmp edx,Sound.MinMixSamples
    jg .AboveMin
    mov edx,Sound.MinMixSamples
.AboveMin:
    cmp edx,Sound.MaxMixSamples
    jbe .BelowMax
    mov edx,Sound.MaxMixSamples
.BelowMax:
%endif

    ;debugwrite "drv=%d mix=%d lag=%d edx=%d",eax,[Sound.MixTime],ebx,edx

    ret

%if 0
@   1000
-   1498
=   -498
+    500
=      2

@   1000
+    500
=   1500
-   1498
=      2


@   1000
+    500
=   1500
-   1502
=     -2

@     0
-     0
=     0
+   500
=   500
%endif

%if 0 ;failure #2 (works fine on DS-XG but not SB16)
    mov eax,[Sound.MmTime+MMTIME.sample]
    mov ebx,[Sound.MixTime]
    mov edx,[Sound.IntSamples]  ;- frame size
    ;mov edx,ecx
    ;shr ecx,1
    ;lea ecx,[ecx+ecx*2]
    sub ebx,eax                 ;mix time - sample pos
    ;js .Impossible
    sub ebx,edx                 ;- frame size
    js .Behind
    je .InSync
    ;ja .Ahead

.Ahead:
    ;xchg [Sound.DmaLag],ebx
    ;add ebx,[Sound.DmaLag]
    ;sar ebx,1
    mov [Sound.DmaLag],ebx ;***

    sub edx,ebx
    cmp edx,Sound.MinMixSamples
    jg .AboveMin
    mov edx,Sound.MinMixSamples
.AboveMin:
    debugwrite "ahead  drv=%d mix=%d lag=%d edx=%d",eax,[Sound.MixTime],[Sound.DmaLag],edx
    ret

.InSync:
    debugwrite "synced drv=%d mix=%d lag=%d edx=%d",eax,[Sound.MixTime],ebx,edx
    mov [Sound.DmaLag],ebx
    ret

.Behind:
    ;xchg [Sound.DmaLag],ebx
    ;add ebx,[Sound.DmaLag]
    ;sar ebx,1
    mov [Sound.DmaLag],ebx ;***

    sub edx,ebx
    cmp edx,Sound.MaxMixSamples
    jbe .BelowMax
    mov edx,Sound.MaxMixSamples
.BelowMax:
    debugwrite "behind drv=%d mix=%d lag=%d edx=%d",eax,[Sound.MixTime],[Sound.DmaLag],edx
    ret
%endif

%if 0
    mov edx,[Sound.MmTime+MMTIME.sample]
    mov eax,[Sound.MixTime]
    mov [Sound.MixTime],edx
    sub edx,eax
    mov [Sound.DmaLag],edx
    debugwrite "Time=%d DmaLag=%d",eax,edx
%endif

  %if 0                         ;doesn't seem to make any difference, the
    neg al                      ;pitch is still of at certain sampling rates
    imul dword [Sound.SampleRate]
    mov ebx,1000000
    imul dword [Sound.SampleRate]
    div ebx
    mov [Sound.MixRate],eax
  %endif


<SPCGUI.ASM>
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MainGuiLoop:
    push dword MainWindow       ;window data structure
    InitGui
    InitGfx
    xor eax,eax
    call SpcViewSetMode

; put somewhere
    ; advance position and update song structure
    cmp [MainSongPos.Time],edx
    je .NoChange
    mov edi,MainSongPos
    call SeekSongPos            ;seek time in edx
    ;mov edi,MainSongPos
   %if SupportPitchSlide
    call SeekSongPos.SetAllKeys ;all currently on voices
   %else
    call SeekSongPos.SetKeys    ;new keys only
   %endif

    ;call SpcViewSetMode.ClearTable
    ; draw next frame to song visualization
    ;call dword [SpcView.Handler]
    ;call dword [SpcView.ScreenCopier] ;this should later be moved to the GUI redraw



;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Top:
.GetKey:
    call GetKeyboardMsg
    jc .NoKeyChange             ;return value is irrelevant if cf set
    cmp ah,27
    je near .End
    ;push dword MainWindow      ;window data structure
    call SendKeyMsg             ;send keypress to active window
    ;lea esp,[esp+byte 4]
    jnc .GetKey
.NoKeyChange:

.GetMouse:
    call GetMouseMsg            ;press/release/move
    jc .NoMouseChange
    test eax,MouseFocusFlags.MouseMoved
    jz .NoMouseRedraw
    mov dword [Cursor.Redraw],-1
.NoMouseRedraw:
    push dword [Cursor.Col]
    push dword [Cursor.Row]
    push dword MainWindow       ;send mouse message to window cursor is over or window which grabbed focus
    call SendMouseMsg           ;click/move/enter/exit
    add esp,byte 12
.NoMouseChange:

    call SendTimeMsgs

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.NextEmuRun:
    test byte [PlayOptions],PlayOptions.Emulate
    jz .SkipEmu
    mov eax,83200               ;for normal playing (~1/30 second cycles)
    call SpcEmu.Start
    btr dword [DspFlags],DspFlags.NewValidVoiceb
    jnc .NoNewVoices
    call MatchBrrSamples.New
.NoNewVoices:
    cmp dword [DspBufferEnd],DspBufferSize    ;stop emulation if buffer full
    jb .SkipEmu
    and byte [PlayOptions],~PlayOptions.Emulate
.SkipEmu:

    ;test byte [PlayOptions],PlayOptions.MidiLog
    ;jz .NoMidiOutput
    ;call OutputMidiEvents
.NoMidiOutput:
    btr dword [PlayOptions],PlayOptions.Interruptedb
    jnc .NoUpdate

    ; advance position and update song structure
    mov edx,[PlayTime]
    cmp [MainSongPos.Time],edx
    je .NoChange
    mov edi,MainSongPos
    call SeekSongPos            ;seek time in edx
    ;mov edi,MainSongPos
   %if SupportPitchSlide
    call SeekSongPos.SetAllKeys ;all currently on voices
   %else
    call SeekSongPos.SetKeys    ;new keys only
   %endif
.NoChange:

    ; play sounds da/fm/sine/mpu
   %if PlayInInterrupt=0
    call PlaySounds
   %endif
.NoUpdate:

    mov [PlayStall],dword 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; check if user clicked on Window close button
    ;mov eax,168Fh               ;Win32 VM interrupt
    ;mov edx,0100h               ;query close
    ;int 2Fh
    ;jc .NoQueryClose            ;function not supported
    ;cmp al,1                    ;close application
    ;ja .NoQueryClose
    ;ret
.NoQueryClose:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; tell any items that need to redraw themselves to do it now
    btr dword [Cursor.Redraw],0
    jc .CursorChanged
    test dword [MainWindow+GuiObj.Flags],GuiObj.Redraw
    jz .NoRedraw
.CursorChanged:
   %ifndef UseVirtualScreen
    call HideCursorImage
   %endif
    test dword [MainWindow+GuiObj.Flags],GuiObj.Redraw
    jz .RedrawCursor
    call SaveDisplay            ;save main window's display vars
    push dword MainWindow
    ;call SendRedrawMsgsLayered  ;redraw all main items, cascading down to each contained item
    call SendRedrawMsgs         ;redraw all main items, cascading down to each contained item
    pop ebx                     ;discard window ptr
    and dword [MainWindow+GuiObj.Flags],~GuiObj.Redraw
    call RestoreDisplay         ;restore main window's display vars
.RedrawCursor:
   %ifdef UseVirtualScreen
    call DrawCursorImage
    call TransferScreen
    call HideCursorImage
   %else
    call DrawCursorImage
   %endif
.NoRedraw:
    jmp .Top

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.End:
    and byte [PlayOptions],~PlayOptions.Timed
    call ClearSbBuffer

    ;push dword MainWindow      ;window data structure
    DeinitGui
    pop ebx
    ret
%endif


<DSPMISC.ASM>
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
OutputDspWrites:

    mov ah,3Ch                  ;create file
    xor ecx,ecx                 ;no attributes
    mov edx,DspFileName
    int 21h
    mov edx,Text.DspOutputError
    jc EndProgram.ErrorMessage  ;end program and print error message
    mov [DspFileHandle],eax
    mov ebx,eax
    mov ecx,128
    mov edx,DspRam
    mov ah,40h                  ;DOS: Write to file
    int 21h

    mov edi,[DspBufferEnd]
    mov esi,[DspBufferWritten]
    mov [DspBufferWritten],edi
    cmp edi,esi
    jz .End
    sub edi,esi
    mov ebx,[DspFileHandle]
    mov ecx,6
.Next:
    mov ah,40h                  ;DOS: Write to file
    lea edx,[DspBuffer+esi]
    int 21h
    add esi,byte 8
    sub edi,byte 8
    ja .Next
.End:

    mov ah,3Eh              ;close file
    mov ebx,[DspFileHandle]
    int 21h

    ret

DspFileName:        db "out.dsp",0

<SAMPLE.ASM>
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

%if 0
    push esi
    call NewSample.NextFreeIdx
    pop esi
    jc near .NoMoreSamples
    ;(eax=new sample index)

    ; copy BRR attributes to sample list and initialize other sample attrs
    ;debugwrite "mbrs gs=%-4d ls=%-3d",eax,esi
    mov ebx,[LocalSample.Checksum+esi*4]
    mov ecx,[LocalSample.Length+esi*4]
    mov edx,[LocalSample.LoopLen+esi*4]
    mov edi,[LocalSample.Offset+esi*4]
    push dword [DefaultVolume]
    push dword [DefaultGmPatch]
    push dword [DefaultFreq]
    mov [GlobalSample.Checksum+eax*4],ebx
    mov [GlobalSample.Length+eax*4],ecx
    mov [GlobalSample.LoopLen+eax*4],edx
    mov [GlobalSample.LocalIdx+eax*4],esi
    mov [GlobalSample.Offset+eax*4],edi
    pop dword [GlobalSample.Freq+eax*4]  ;DefaultSample.Freq       
    pop dword [GlobalSample.Instrument+eax*4]  ;DefaultSample.Instrument
    pop dword [GlobalSample.Volume+eax*4]
    btr [GlobalSample.Independant],eax
    btr [GlobalSample.Disabled],eax
    btr [GlobalSample.Soloed],eax
    btr [GlobalSample.Muted],eax  ;****
    ;mov byte  [GlobalSample.Interpolation+eax],DefaultSample.Interpolation

%if 0
    ; This was an attempt to automatically tune samples according to their
    ; loop length. It worked for a few songs, but made the majority of songs
    ; sound worse.
    push ecx
    push edx
    push eax
    cmp edx,16
    mov ecx,DefaultSample.Freq
    jb .DefaultHz
    mov ecx,edx
.KeepMainLen:
    test ecx,ecx
    jg .SampleLenNz
    mov ecx,16
.SampleLenNz:
    xor edx,edx
    mov eax,32000<<17
    div ecx
    mov ecx,17
.NextHigherHz:
    shr eax,1
    cmp eax,660
    jb .HertzOk
    shr eax,1
    dec ecx
    jg .NextHigherHz
.HertzOk:
    mov ecx,eax
.DefaultHz:
    pop eax
    mov [GlobalSample.Freq+eax*4],ecx
    pop edx
    pop ecx
%endif

    push esi
    jmp short .StartDupCheck
.NextCheckDupBrr:
    cmp [LocalSample.Checksum+esi*4],ebx
    jne .NotDup
    cmp [LocalSample.Length+esi*4],ecx
    jne .NotDup
    cmp [LocalSample.LoopLen+esi*4],edx
    jne .NotDup
.StartDupCheck:
    ; another BRR sample matched sample from list
    mov [LocalSample.GlobalIdx+esi*4],eax
.NotDup:
    inc esi
    cmp esi,256
    jb .NextCheckDupBrr
    pop esi

    ;(eax=new sample index)
    mov edi,eax                 ;get sample list index for name ptr
    shl edi,GlobalSample.NameShl
    ;mov eax,esi                 ;copy BRR sample number for name
    add edi,GlobalSample.Name
    bt [NewSample.NameFlags],esi
    push esi
    jc .CreateName
    call NewSample.NextNumberedName
.CreateName:
    call NewSample.CreateName
    pop esi
%endif

