; Spc2Midi - Sound card functions (DA/FM/MPU/GM)
;
; Contained here is a collection of generic sound routines that I copied from
; another program. Except for just a few variables in the main source, all
; these routines are fairly independant of the rest of the program; however,
; the DSP simulation is very dependant on these routines.
;
; GetBlasterVars - get blaster variables from environment string
; InitFmSound - initialize OPL2 frequency modulation registers
; WriteFmReg - write value to FM register
; TimedWait - wait multiple of 15.085 microseconds (for FM and DA init)
; SilenceFm - silence all FM voices
; SetFmPatch - sets carrier/modulator registers for a voice
; InitDaSound - initialize digital audio
; SoundHandler - acknowledge sound card interrupt
; ReadSbDsp - read byte from DSP
; WriteSbDsp - write byte to DSP
; InitDmaTransfer - start digital audio transfer, setting DMA channels
; ClearWaveBuffer - wipe sound card's sound buffer (8/16bit large circular)
; ClearMixBuffer - wipe mixing buffer (32bit small linear)
; CopyMixBuffer - copy and clip mixing buffer to sound card buffer
; SyncToWave - resynchronize mixing and sound card output
; InitMpu - initialize MPU401 external MIDI port
; WaitMpu - wait until port is ready for data
; WriteMpu - write single byte
; WriteMpuString - write variable string of bytes
; InitGm - initialize general MIDI internal synthesizer
;
; Note all the actual conversion from DSP buffer to sound is done in
; DSPSIM.ASM, not here.
;
; Todo:
;   eliminate FM clicking! (example: voice 0 of SD3 "Swivel")
;    hhm, the clicking is less on my newer SB16, the old 8bit is bad
;   try to silence audio clicking when initialized or ended (if possible)
;
; Fm Synthesis:
;   Notes are output (on/off) every 1/30 of a second. This seems to be
;   accurate enough even for dense songs.
;
; Wave Output:
;   Once turned on, it stays on. Rather than bother with turning the speaker
;   on/off or starting/stopping auto-init, the sound is simply always playing.
;   Even when everything is paused, it is still playing, but playing silence
;   (the sound buffer is cleared). This makes the sound code easier and also
;   eliminates some clicking.
;
;   To make things simpler, I decided to make all sound output mono (for
;   stereo, try any one of several other SPC players). That way, the only
;   complication is whether to play 8bit or 16bit. 16bit is used if supported
;   unless for some reason 8bit is forced.
;
; Progressive buffering
;   Instead of double buffering (with only two halves), it uses 'progressive'
;   buffering, picking up right where it left off the last transfer and
;   wrapping if necessary. This means the buffer size can always be the same,
;   regardless of the sample rate. If for any reason the buffer ptr and the
;   DMA output become unsynchronized, it will compensate for the difference.
;   This helps if for any reason the sound processing lags or if the user
;   switches away using a multi-tasking OS like MS Windows and then back.
;
; Premixing
;   All sound output is first combined into a mixing buffer using 32bit
;   precision, to increase accuracy, to lessen overflow problems, to merge
;   multiple sounds sources (playing voices and a sample at the same time,
;   plus anything else I might later want to add) and last, greatly simplify
;   things for me! After everything has been mixed that needs to be, the mix
;   buffer is downsampled to either 8bit or 16bit and copied to the sound
;   card's buffer in low memory.
;
; Sound card interrupt
;   Unlike other sound playing programs (almost every one in existance) this
;   one gets its timing solely from the pc timer, not the sound card. As a
;   matter of fact, it completely ignores any interrupts generated from the
;   card. This is done for several reasons. The PIT is more accurate than the
;   sound card sampling rate, letting this program and the real SNES sync
;   better. The two processes (FM synthesis and wave output) are always
;   coordinated; and the program will play realtime even with no sound card.
;   Of course, this brings up other timing issues with the sound card that
;   requires it to periodically resynchronize to DMA.
;
; Imprecise sound cards
;   It seems (after carefully checking and rechecking my code) that sound
;   card time constants are rather innaccurrate. Setting a direct sampling
;   rate works great and is near perfectly synchronized, but only SB4.0 or
;   better supports that command :( At first I thought my time constant
;   calculation was off, but even using the formula their own documentation
;   specifies, the play rate is still slightly off. Add to that, the same
;   time constant yields slightly different sampling rates on different sound
;   cards. I've read on that cheap sound cards using low precision quartz
;   timers are to blame for the inaccuracy.
;
; Compensating for lost time
;   The problem happens when the DMA and sound generation routine become so
;   out of sync that the two cross streams (like shearing on a VGA screen
;   when a game's update and the adapter refresh meet) causing a short but
;   annoying static sound. The solution? If the mixing falls behind DMA,
;   simply generate more sound for a brief time to catch up. If
;   mixing advances too far ahead of DMA, skip some mixing.
;
;=============================================================================

;---------------------------------------
section data
align 4, db 0

%ifdef DosVer
SbAdr:
.Reset          equ 6
.Fm             equ 8
.Read           equ 0Ah
.Write          equ 0Ch
.WriteStatus    equ 0Ch
.ReadStatus     equ 0Eh
.Ack8bit        equ 0Eh
.Ack16bit       equ 0Fh

SbFmAdr:
;.Timer1Count    equ 2   ;incremented every 80 microseconds
;.Timer2Count    equ 3   ;incremented every 320 microseconds
;.TimerControl   equ 4
;.TimerReset     equ 128 ;clears timer expired flags in port 388h
;.Timer1Mask     equ 64
;.Timer2Mask     equ 32
;.Timer1Start    equ 1
;.Timer2Start    equ 2

SbCmd:
.MidiOut        equ 38h
.ExitDma8bit    equ 0DAh
.ExitDma16bit   equ 0D9h
.PauseDma8bit   equ 0D0h
.PauseDma16bit  equ 0D5h
.GetVersion     equ 0E1h

Pic:
.Mode1          equ  20h
.Mode2          equ 0A0h
.Mask1          equ  21h
.Mask2          equ 0A1h

MpuCmd:
;Data port is 330h, Command port is 331h, Status port is 331h read only
.Reset          equ 0FFh
.Uart           equ 3Fh
.MaskOut        equ 64          ;MPU is ready to accept data or command
.MaskIn         equ 128         ;data is available to read
.RespAck        equ 0FEh
%endif

;---------
align 4,db 0
Sound:

%ifdef DosVer
; hardware specifics

.IoPort:        dd 220h         ;220/240..
.FmPort:        dd 388h         ;228/388
.MpuPort:       dd 330h         ;300/330
;.MixerPort:    dd 220h
.CardVersion:   dd 0            ;2/3/4
.Ldma:          dd 4            ;8bit memory channel (sentinel value set to 4 because DMA channel 4 is invalid)
.Hdma:          dd 4            ;16bit memory channel
.DmaChannel:    dd 4            ;last used channel
.PicMaskPort:   dd 21h          ;PIC mask port for given IRQ 21=1-7, A1=8-15
.DaInt:         dd 0Dh          ;interrupt number of given IRQ (wave audio)
.Irq:           dd 5            ;IRQ to clear

;---------
%elifdef WinVer
; driver specifics

.hwo:           dd 0            ;open wave out device handle
.hfmo:          dd 0            ;frequency modulation MIDI device handle
.hmpo:          dd 0            ;MIDI port device handle
.hgmo:          dd 0            ;internal synthesizer device handle

.wfx:                           ;wave format header extended
istruc WAVEFORMATEX
at WAVEFORMATEX.wFormatTag,     dw 1    ; format type
at WAVEFORMATEX.nChannels,      dw 1    ; number of channels (i.e. mono, stereo...)
at WAVEFORMATEX.nSamplesPerSec, dd 32000;; sample rate
at WAVEFORMATEX.nAvgBytesPerSec,dd 64000; for buffer estimation
at WAVEFORMATEX.nBlockAlign,    dw 2    ; block size of data
at WAVEFORMATEX.wBitsPerSample, dw 16   ; number of bits per sample of mono data
at WAVEFORMATEX.cbSize,         dw 0    ; the count in bytes of the size of
; no extra information (after cbSize)
iend

.lpwh:
.lpwh0:
istruc WAVEHDR
at WAVEHDR.lpData,              dd WaveBuffer       ;pointer to locked data buffer
at WAVEHDR.dwBufferLength,      dd .FrameSize       ;length of data buffer
at WAVEHDR.dwBytesRecorded,     dd 0                ;used for input only
at WAVEHDR.dwUser,              dd 0                ;for client's use
at WAVEHDR.dwFlags,             dd WHDR_DONE        ;assorted flags
at WAVEHDR.dwLoops,             dd 0                ;loop control counter
at WAVEHDR.lpNext,              dd 0                ;reserved for driver
at WAVEHDR.reserved,            dd 0                ;reserved for driver
iend

.lpwh1: dd WaveBuffer+(.FrameSize*1), .FrameSize, 0,0, WHDR_DONE,0, 0,0
.lpwh2: dd WaveBuffer+(.FrameSize*2), .FrameSize, 0,0, WHDR_DONE,0, 0,0
.lpwh3: dd WaveBuffer+(.FrameSize*3), .FrameSize, 0,0, WHDR_DONE,0, 0,0
.lpwh4: dd WaveBuffer+(.FrameSize*4), .FrameSize, 0,0, WHDR_DONE,0, 0,0
.lpwh5: dd WaveBuffer+(.FrameSize*5), .FrameSize, 0,0, WHDR_DONE,0, 0,0
.lpwh6: dd WaveBuffer+(.FrameSize*6), .FrameSize, 0,0, WHDR_DONE,0, 0,0
.lpwh7: dd WaveBuffer+(.FrameSize*7), .FrameSize, 0,0, WHDR_DONE,0, 0,0

.MmTime:
istruc MMTIME
at MMTIME.wType,    dd TIME_SAMPLES ;time format
at MMTIME.sample,   dd 0
iend

section bss
.woc:
.moc:           resb MIDIOUTCAPS_size
                resb ($-.woc)-WAVEOUTCAPS_size
section data

%endif

;---------
%ifdef DosVer
.BufferSize     equ 16384       ;4k samples * 2 bytes per 16bit sample * 2 for wrap padding (must be EVEN exponentt of 2)
.BufferPtr:     dd 0            ;address to base of sound buffer
.BufferSel:     dd 0            ;selector to sound buffer
.TransferSize   equ 65534       ;size given to sound card (for fewer pointless interrupts)
%elifdef WinVer
.MaxFrames      equ 8
.FrameSize      equ 8192        ;maximum size for a single block in a frame
.FrameSizeShl   equ 13
.BufferSize     equ .FrameSize*.MaxFrames
.BufferPtr:     dd WaveBuffer   ;address to base of sound buffer (not mixing buffer)
%endif
.BufferPos:     dd 0            ;offset within buffer of last wave data write
.DmaTime:       dd 0            ;where sound is currently at
.DmaLag:        dd 0            ;previous lag difference, (DMA-Mixing)-buffer size

%ifdef DosVer
.SampleRate:    dd 32000        ;sound card rate (sound cards are innaccurate)
%elifdef WinVer
.SampleRate:    equ .wfx+WAVEFORMATEX.nSamplesPerSec
%endif
.MinSampleRate  equ 5000
.HighSampleRate equ 23000       ;anything above rate this requires high speed mode (unless DSP >= 4)
.MaxSampleRate  equ 64000       ;most sound cards don't support this anyway
.MixRate:       dd  32000       ;mixing rate (may be different from SampleRate)
.MinMixRate     equ 2000        ;below this is pointless and can cause a division overflow
.MaxMixRate     equ 200000      ;above this is pointless (and could cause the program to crash)

.FramesPerSec   equ 30
.IntSamples:    dd 735          ;samples to mix per frame (interrupt/thread call)
.MixSamples:    dd 735          ;samples to mix this frame (usually same as IntSamples, but may be less if ahead, more if behind)
.MinMixSamples  equ 100         ;min samples generated per interrupt; 100 is just an arbitrary value of no special meaning
.MaxMixSamples  equ 4095        ;max samples generated per interrupt; fit enough samples for the maximum playrate (64000/30=2133.33)
.MixSize        equ 4095*4      ;max mix samples * 4 for dwords (! < FrameSize)

SoundFlags:                     ;which sound capabilities should be used
.Da             equ 1
.DaBit          equ 0
.Fm             equ 2           ;believe it or not, some cards completely lack FM synthesis
.FmBit          equ 1
.Mpu            equ 4
.MpuBit         equ 2
.Gm             equ 8           ;general MIDI internal synthesizer
.GmBit          equ 3
.Force8bit      equ 16          ;force 8bit instead (even if 16bit supported)
.Supports16bit  equ 32          ;>=SB4 is capable of 16bit (even if not used)
.HighSpeed      equ 64          ;card is using high speed mode for given
.HighSpeedBt    equ 6           ; frequency
.NeedHighSpeed  equ 128         ;old sound card requires high speed
;.Resync        equ 64          ;flags that resync is needed with DMA
;.Stereo        equ 16          ;stereo/mono
;.ClearedBuffer equ 128         ;sb buffer is clear
            %ifdef DosVer
                dd .Da|.Fm
            %elifdef WinVer
                dd .Da ;|.Gm
            %else
                dd 0
            %endif
%ifdef DosVer
section text
BlasterString:  db "BLASTER=",0
%endif

; The sound buffer is set in low memory (<16Mb) pointed to by BufferPtr.
; The mixing buffer is where multiple sounds are scaled, amplified, and merged
; before being moved to the sound card buffer. All sample calculations
; internally are 32bit, which must be clipped and converted (8bit/16bit).
; This can allow the program to play 8bit sound, but record 16bit audio.
; Physical memory reserved for it is actually twice as large as the buffer
; alone, just in case part of the allocated block crosses a 64k page.

section bss
alignb 4
WaveBuffer:     resb Sound.BufferSize
MixBuffer:      resb Sound.MixSize

%ifdef DosVer
SbFm:
section bss
alignb 4
.Regs:          resb 256        ;there aren't actually a full 256
section data
; a table to compensate for the OPL2's weird register configuration
.VoiceTable:    db 0,1,2,8,9,10,16,17,18,24,25,26
; all the registers necessary to set attributes for a voice
.PatchRegs:     db 20h,23h      ;multiplier
                db 40h,43h      ;level
                db 60h,63h      ;attack/decay
                db 80h,83h      ;sustain/release
                db 0E0h,0E3h    ;waveform
                db 0C0h         ;feedback
                db 0            ;null (end)
align 4,db 0
.PatchData:     incbin "patches.dat"
%endif

section code

%ifdef DosVer
;-----------------------------------------------------------------------------
; Reads variables from BLASTER string. Assumes all settings are correct, and
; that the address, IRQ, & DMA are valid. Don't tell the user an annoying
; message like "invalid blaster setting", because as many different
; computers and different configurations are there are out there, nothing
; can be accepted as standard. However, in the unlikely event the specified
; settings are incorrect (which can happen in the wonderful world of Windows),
; prepare to crash! :/ Well, not neccessarily. Some do... Some don't...
GetBlasterVars:
    ;get DOS environment string (db "BLASTER",0)
    ;get parts  Address,Dma,Interrupt,HighDma,Mpu

%if 1
    mov esi,BlasterString
    call GetEnvVar
    jnc .VariableFound

    mov esi,Text.NoBlasterVars
    call StatusMessage
    and byte [SoundFlags],~SoundFlags.Da
    stc
    ret
.VariableFound:

%else ;use this code if the GetEnvVar routine is not present
    ; search through environment for BLASTER variable
    cld
    mov ebx,[Program.Env]
    jmp short .FirstVariable
.NextVariable:
    add ebx,byte 4
    cmp dword [esi],'BLAS'
    jne .FirstVariable
    cmp dword [esi+4],'TER='
    je .VariableFound
.FirstVariable:
    mov esi,[ebx]
    test esi,esi
    jnz .NextVariable

    mov esi,Text.NoBlasterVars
    call StatusMessage
    and byte [SoundFlags],~SoundFlags.Da
    stc
    ret
.VariableFound:
    add esi,byte 8              ;skip "BLASTER=" variable name

%endif

.NextElement:
    mov bl,[esi]
    test bl,bl
    je near .End
    inc esi
    cmp bl,32
    je .NextElement

;Converts hex number string in environment variable to number
;(esi=ptr to hex number string) (bl=letter)
.GetNum:
    xor eax,eax             ;set return value to zero
.NextDigit:
    mov dl,[esi]            ;get digit
    sub dl,48               ;"0"=48->0  "9"=57->9
    jc .LastDigit           ;character is less than '0'
    cmp dl,10
    jb .AddPlaceValue       ;digit is 0-9
    and dl,~32              ;make uppercase by turning off fifth bit
    cmp dl,'A'-48
    jb .LastDigit           ;character is less than 'A'
    cmp dl,'F'-48
    ja .LastDigit           ;character is greater than 'F' (15)
    sub dl,7                ;(65-48)+10  "A"=65->10  "F"=86->15
.AddPlaceValue:
    shl eax,4               ;multiply existing number by radix (16)
    inc esi                 ;move forwards one character
    or al,dl                ;add new digit
    jmp short .NextDigit
.LastDigit:

;(eax=number) (bl=letter)
    and bl,~32                  ;make uppercase
    cmp bl,'A'
    jne .SkipAdr
    mov [Sound.IoPort],eax      ;set DSP command reg and FM port
    add eax,byte SbAdr.Fm
    mov [Sound.FmPort],eax
.SkipAdr:
    cmp bl,'D'
    jne .SkipDma
    mov [Sound.Ldma],al         ;DMA Channels 0-3
.SkipDma:
    cmp bl,'H'
    jne .SkipHdma
    mov [Sound.Hdma],al         ;High DMA 4-7
.SkipHdma:
    cmp bl,'I'
    jne .SkipInt
    cmp al,16                   ;compensate for hexadecimal conversion
    jb .IrqOk
    sub al,6                    ;16->10, 21->15
.IrqOk:
    cmp al,2                    ;hack exception for cascaded IRQ 2
    jne .NotIrq2
    mov al,9                    ;force 2 to 9
.NotIrq2:
    mov [Sound.Irq],al
    ; get interrupt number based on IRQ
    cmp al,8
    jb .LowIrq
    and al,7
    add al,[Program.PicBaseSlave]
    jmp short .SetInt
.LowIrq:
    add al,[Program.PicBaseMaster]
.SetInt:
    mov [Sound.DaInt],al        ;keep interrupt number
.SkipInt:
    cmp bl,'P'
    jne .SkipMpu
    mov [Sound.MpuPort],eax
.SkipMpu:
;    cmp bl,'M'
;    jne .SkipMixer
;    mov [Sound.MixerPort],eax
;.SkipMixer:
;    cmp bl,'T'
;    jne .SkipType
;    mov [Sound..],eax
;.SkipType:
    jmp .NextElement

.End:
    clc
    ret

section text
Text.NoBlasterVars:     db "! No 'BLASTER' variable set",0
section code
%endif


;-----------------------------------------------------------------------------
; Enables different waveforms, disables rhythm mode to make use of all 9
; channels.
;
; ()
; ([SoundFlags.Fm])

%ifdef DosVer
InitFmSound.IfEnabled:
    test byte [SoundFlags],SoundFlags.Fm
    jnz InitFmSound
    ret

InitFmSound:
    and byte [SoundFlags],~SoundFlags.Fm
    mov esi,Text.InitializingFm
    call StatusMessage.Pending

    ; detect existance
    ; attempt to clear timer flags, then check if they are clear

    mov eax,0004h               ;stop timers
    call WriteFmReg
    mov eax,8004h               ;clear timer flags
    call WriteFmReg
    ;mov edx,[Sound.FmPort]
    dec edx
    in al,dx
    test al,0E0h                ;all timer flags should be clear
    jnz near .Fail

    ; attempt to start timer count, then check if they are set
    mov eax,0FF02h              ;set minimum timer 1 delay
    call WriteFmReg
    mov eax,0104h               ;start timer 1
    call WriteFmReg
    mov ecx,8                   ;delay at least 80 microseconds
    call TimedWait              ;delays 15-30us each count
    ;mov edx,[Sound.FmPort]
    dec edx
    in al,dx
    and al,0E0h                 ;mask only timer flags
    cmp al,0C0h                 ;timer 1 flag should be set
    jne .Fail

    mov eax,0004h               ;stop timers once again so they're not
    call WriteFmReg             ;just endlessly counting on
    mov eax,8004h               ;clear timer flags
    call WriteFmReg

    ; ack possible IRQ from timer overflow (unnecessary on most sound cards)
    mov al,[Sound.Irq]          ;needed for TeleSound 3D, or else audio
    or al,60h                   ;loops inifinitely after returning to Windows
    btr eax,3                   ;if IRQ 8-15
    jnc .LowIrq
    out Pic.Mode2,al
    mov al,62h                  ;specific EOI for chained IRQ 2
.LowIrq:
    out Pic.Mode1,al

.IgnoreDetect:                  ;call here to override
    ;mov ebx,4                  ;zero all registers (may be unnecessary)
    xor ebx,ebx
.NextRegZero:
    mov eax,ebx
    call WriteFmReg             ;destroys eax,ecx,edx
    inc bl                      ;next voice
    jnz .NextRegZero

    mov eax,2001h               ;enable different waveforms
    call WriteFmReg
    mov eax,00BDh               ;disable rhythm mode
    call WriteFmReg

; <The code below isn't really necessary since the patches will be set when
;  the notes are turned on anyway>
%if 0
    ; set default patch for all voices
    mov edi,9-1                 ;start with last voice
    mov esi,SbFm.PatchDefault
.NextVoicePatch:
    mov eax,edi
    call SetFmPatch
    dec edi
    jns .NextVoicePatch

    ; turn off all vaoices
    mov ebx,00B0h               ;turn off voices
.NextVoiceOff:
    mov eax,ebx
    call WriteFmReg             ;destroys eax,ecx,edx
    inc ebx                     ;next voice
    cmp bl,0B8h
    jbe .NextVoiceOff

    cld
    mov edi,SbFm.UsedPatches
    mov eax,-1
    mov ecx,9
    rep stosd
%endif

    mov esi,Text.InitializedFm
    call StatusMessage
    or byte [SoundFlags],SoundFlags.Fm
.End:
    ret

.Fail:
    mov esi,Text.FmNotReset
    jmp StatusMessage
    ;ret

;---------------------------------------
.Release:
    btr dword [SoundFlags],SoundFlags.FmBit
    jnc .End
    mov esi,Text.ReleasingFm
    call StatusMessage

    mov ebx,00B0h               ;turn off voices
.NextVoiceOff:
    mov eax,ebx
    ;mov ah,[SbFm.UsedFnumbers+ebx-0B0h] ;get previous fnumber/octave of voice, to prevent clicking sound
    ;and ah,~20h                 ;clear bit to set off
    call WriteFmReg             ;destroys eax,ecx,edx
    inc ebx                     ;next voice
    cmp bl,0B8h
    jbe .NextVoiceOff
    ret

;---------------------------------------
; Opens FM MIDI audio device (Windows)
;
; ()
; ([SoundFlags.Fm])
%elifdef WinVer

InitFmSound.IfEnabled:
    test byte [SoundFlags],SoundFlags.Fm
    jnz InitFmSound
    ret

InitFmSound:
    and byte [SoundFlags],~SoundFlags.Fm
    mov esi,Text.InitializingFm
    call StatusMessage.Pending

    xor ebx,ebx
.Next:
    api midiOutGetDevCaps, ebx, Sound.moc,MIDIOUTCAPS_size
    test eax,eax
    jnz .NotFound
    cmp word [Sound.moc+MIDIOUTCAPS.wTechnology],MOD_FMSYNTH
    je .FmFound
    inc ebx
    jmp short .Next
.NotFound:
    mov esi,Text.NoFmAudio
    jmp StatusMessage

.FmFound:
    xor eax,eax
    api midiOutOpen, Sound.hfmo,ebx, eax, eax, eax ;NULL,0,CALLBACK_NULL
    test eax,eax
    mov esi,Text.FmBusy
    jnz near  StatusMessage

    mov esi,Sound.moc+MIDIOUTCAPS.szPname
    call StatusMessage
    or byte [SoundFlags],SoundFlags.Fm
.End:
    ret

;---------------------------------------
; Closes FM MIDI audio device. This function assumes all audio
; threads have already been suspended or terminated.
.Release:
    btr dword [SoundFlags],SoundFlags.FmBit
    jnc .End
    mov esi,Text.ReleasingFm
    call StatusMessage
    api midiOutReset, [Sound.hfmo]
    api midiOutClose, [Sound.hfmo]
    mov dword [Sound.hfmo],0
    ret

%endif

section text
Text.InitializingFm:    db "Initializing FM synthesis...",0
%ifdef DosVer
Text.InitializedFm:     db "OPL2 registers initialized",0
Text.FmNotReset:        db "FM either busy or unsupported !",0
Text.ReleasingFm:       db "Silencing FM voices",0
%else
Text.NoFmAudio:         db "No FM audio device found !",0
Text.FmBusy:            db "Could not open FM audio !",0
Text.ReleasingFm:       db "Releasing FM audio device",0
%endif
section code


%ifdef DosVer
;-----------------------------------------------------------------------------
;
; Quote from "Programming the AdLib/Sound Blaster" by Jeffrey S. Lee (1992)
;
; After writing to the register port, you must wait twelve cycles before
; sending the data; after writing the data, eighty-four cycles must elapse
; before any other sound card operation may be performed.
;
; The AdLib manual gives the wait times in microseconds: three point three
; (3.3) microseconds for the address, and twenty-three (23) microseconds
; for the data.
;
; The most accurate method of producing the delay is to read the register
; port six times after writing to the register port, and read the register
; port thirty-five times after writing to the data port.
;
; (al=sb reg, ah=value)
; (edx=fm port+1; ebx,esi,edi)
;
WriteFmReg:
    movzx ecx,al
    mov edx,[Sound.FmPort]
    mov [SbFm.Regs+ecx],ah
    out dx,al       ;set register to write to
    mov ecx,2
    shl eax,8       ;preserve register value in upper dword
    call TimedWait  ;delays 15-30us
    shr eax,16      ;restore register value from upper dword
    inc edx
    out dx,al       ;write value to selected register
    mov ecx,3       ;delays 30-45us
    ;jmp TimedWait
%endif


%ifdef DosVer
;---------------------------------------
; Quote from "CPU Independant Timer"
;
; "the perfect anwser.  It seems that there is a timer connected to port 61h
;  at bit 4.  This bit toggles every 15.085 u sec (micro sec)."
;
; (ecx=number of 15.085 microsecond loops)
; (; !ax,ecx)
;
TimedWait:
    in al,61h
    and al,10h          ;mask bit 4
    mov ah,al
.CheckAgain:
    in al,61h
    and al,10h
    cmp al,ah
    jz .CheckAgain      ;no change so loop back
    mov ah,al
    dec ecx
    jg .CheckAgain
    ret
%endif


%if 0
;-----------------------------------------------------------------------------
; Rather than just abruptly turn off all the notes, it first sets the release
; rates so that they fade out.
SilenceFm:
    test byte [SoundFlags],SoundFlags.Fm
    jz .End

    mov ebx,0080h
.Next:
    mov eax,ebx
    mov ah,054h                 ;sustain/release
    call WriteFmReg             ;destroys eax,ecx,edx
    mov ah,075h                 ;attack/decay
    call WriteFmReg             ;destroys eax,ecx,edx
    inc ebx                     ;next voice
    cmp bl,060h+31
    jbe .Next
.End:
    ret
%endif


%ifdef DosVer
;-----------------------------------------------------------------------------
; (esi=patch info, al=voice)
; (; esi, edi)
; Voices are zero based.
SetFmPatch:
    movzx eax,al
    xor ebx,ebx                 ;start with first attribute
    push dword [SbFm.VoiceTable+eax] ;save voice operator offset
    jmp short .FirstReg
.NextReg:
    add al,[esp]                ;add voice operator offset
    mov ah,[esi+ebx]            ;get voice attribute value
    inc ebx                     ;next voice attribute
    call WriteFmReg
.FirstReg:
    mov al,[SbFm.PatchRegs+ebx]
    test al,al
    jnz .NextReg
.End:
    pop eax                     ;release saved operator offset
    ret
%endif


;-----------------------------------------------------------------------------
; Resets/detects sound card, allocates sound buffer, and sets IRQ interrupt
; handler. If the sound card does not exist, is at the wrong address, will
; not reset (because some other program already has control of it), or the
; sound buffer could not be allocated, the routine will return failure.
;
; Does absolutely nothing to initialize DMA channels, nor does it send any
; commands the sound card for transfer. That is all taken care of by
; InitDmaTransfer.
;
; write 1 to reset
; wait 3us
; write 0 to reset
; check for 0AAh from read port
; get sound card DSP version
; allocate's wave buffer
; clear buffer
;
; ()
; ([SoundFlags.Da])

%ifdef DosVer
InitDaSound.IfEnabled:
    test byte [SoundFlags],SoundFlags.Da
    jnz InitDaSound
    ret

InitDaSound:
    and byte [SoundFlags],~(SoundFlags.Da|SoundFlags.HighSpeed|SoundFlags.NeedHighSpeed)
    mov esi,Text.InitializingWave
    call StatusMessage.Pending

    ; detect sound card's existance and willingness to reset
    mov edx,[Sound.IoPort]
    mov al,1
    add dl,SbAdr.Reset
    out dx,al                   ;write 1 to reset port
    mov ecx,2                   ;delays 15-30us (need 3us)
    call TimedWait
    xor al,al
    out dx,al

    add dl,SbAdr.ReadStatus-SbAdr.Reset
    mov ecx,67                  ;although really only 100 microseconds are
.Wait:                          ;needed, allow for timeout of 1 millisecond
    in al,dx                    ;67 = .001 / .000015085
    test al,al
    jns .NotReady
    add dl,SbAdr.Read-SbAdr.ReadStatus
    in al,dx
    sub dl,SbAdr.Read-SbAdr.ReadStatus
    cmp al,0AAh
    je .Success

.NotReady:
    in al,61h                   ; Read timer connected to port 61h at bit 4
    and al,10h                  ; This bit toggles every 15.085 (micro sec)
    cmp al,ah
    je .Wait
    mov ah,al
    dec ecx
    jg .Wait
.Fail:
    mov esi,Text.SbNotReset
    jmp StatusMessage
    ret

.Success:
    ; get sound card's DSP version
    mov al,SbCmd.GetVersion
    call WriteSbDsp
    call ReadSbDsp
    cmp al,2                    ;need at least SB2 for auto init
    jb .Fail                    ;and 2.1 for high speed

    cmp al,4                    ;>=4.xx for direct play rate (no high speed)
    mov cl,[SoundFlags]
    jae .LowSpeed
    or cl,SoundFlags.NeedHighSpeed
.LowSpeed:
    test cl,SoundFlags.Supports16bit
    jnz .SetFlags
    cmp byte [Sound.Hdma],4     ;need HDMA for 16bit
    jne .16bit
    or cl,SoundFlags.Force8bit
    jmp short .SetFlags
.16bit:
    or cl,SoundFlags.Supports16bit
.SetFlags:
    mov [SoundFlags],cl
    mov bh,al

    call ReadSbDsp
    mov bl,al
    mov [Sound.CardVersion],bx

    ; allocate sound buffer
    mov eax,0100h               ;allocate low memory
    mov ebx,(Sound.BufferSize*2)/16 ;paragraphs to grab
    int 31h
    jc .Fail
    shl eax,4
    mov [Sound.BufferSel],dx
    mov [Sound.BufferPtr],eax

    ; ensure buffer doesn't cross 64k boundary
    or eax,0FFFF0000h           ;set all bits above 64k (DMA page)
    add eax,Sound.BufferSize-1
    jnc .NoWrap
    add dword [Sound.BufferPtr],Sound.BufferSize
.NoWrap:

    ; get old interrupt handler
    mov ax,0204h                ;get protected-mode interrupt
    mov bl,[Sound.DaInt]        ;wave audio interrupt
    int 31h
    mov [.OldHandler],edx       ;save offset
    mov [.OldHandler+4],cx      ;save selector

    ; set new interrupt handler
    mov edx,SoundHandler
    ;mov bl,[Sound.DaInt]       ;wave audio interrupt
    mov ax,0205h                ;set protected mode interrupt
    mov cx,cs                   ;pass our code selector
    int 31h

    ; enable interrupt by setting IRQ bit in PIC
    mov cl,[Sound.Irq]
    mov bl,254
    mov edx,Pic.Mode1           ;default to PIC1, for IRQs 0-7
    cli
    cmp cl,8
    jb .EnableLowIrq
    mov al,60h|2                ;specific EOI, in case some other program left one
    out dx,al
    in al,Pic.Mask1             ;dx=Pic.Mask1
    and al,11111011b            ;unmask IRQ 2 also because of cascaded IRQs
    out Pic.Mask1,al            ;enable slave 8259 for high IRQs
    mov dl,Pic.Mode2            ;use PIC2 instead, for IRQs 8-15
.EnableLowIrq:
    mov al,cl
    and al,7
    or al,60h                   ;specific EOI, in case some other program left one
    out dx,al                   ;a few times after playing SpcTool then starting my own player, a spurious initial interrupt would occur
    inc dx                      ;mask register = mode reg + 1
    rol bl,cl                   ;enable (unmask) channel
    in al,dx
    and al,bl
    out dx,al
    mov [Sound.PicMaskPort],edx
    sti

    mov al,0D1h                 ;turn on speaker just in case needed
    call WriteSbDsp

    mov al,[Sound.CardVersion]
    aam
    shl eax,16
    mov al,[Sound.CardVersion+1]
    add eax,'0.00'
    mov [Text.InitializedDa+3],eax
    mov edx,' 8bi'
    test byte [SoundFlags],SoundFlags.Force8bit
    jnz .Forced8bit
    add edx,'16bi'-' 8bi'
.Forced8bit:
    mov [Text.InitializedDa+19],edx

    mov esi,Text.InitializedDa
    call StatusMessage

    or byte [SoundFlags],SoundFlags.Da
.End:
    ret

;---------------------------------------
.Release:
    btr dword [SoundFlags],SoundFlags.DaBit
    jnc .End
    mov esi,Text.ReleasingWave
    call StatusMessage

    mov al,0D3h                 ;turn off speaker to silence any low hiss
    call WriteSbDsp
    ;mov edx,[Sound.IoPort]      ;reset sound card one last time just in case
    ;mov al,1                    ;something was left unresolved
    ;add dl,SbAdr.Reset
    ;out dx,al

    ; disable interrupt
    mov edx,[Sound.PicMaskPort]
    mov cl,[Sound.Irq]
    cmp cl,9
    je .KeepIrq                 ;leave chained IRQ2 enabled or SpcTool 0.6
    mov bl,1                    ;won't know how to handle it (total silence)
    rol bl,cl
    in al,dx
    or al,bl
    out dx,al
.KeepIrq:

    ; restore old interrupt handler
    mov bl,[Sound.DaInt]        ;wave audio interrupt
    mov ax,0205h                ;set protected mode interrupt
    mov cx,[.OldHandler+4]      ;get selector
    mov edx,[.OldHandler]       ;get offset
    int 31h

    ; free buffer
    mov ax,0101h                ;deallocate low memory
    mov dx,[Sound.BufferSel]
    int 31h

    ret


section bss
alignb 4
.OldHandler:    resd 1
                resw 1

;---------------------------------------
; Opens wave audio device (Windows)
; If there is only one wave out device, it simply opens that one. If two or
; more, it uses the wave mapper to determine which.
;
; ()
; ([SoundFlags.Da])
%elifdef WinVer

InitDaSound.IfEnabled:
    test byte [SoundFlags],SoundFlags.Da
    jnz InitDaSound
    ret

InitDaSound:
    and byte [SoundFlags],~SoundFlags.Da
    mov esi,Text.InitializingWave
    call StatusMessage.Pending

    api waveOutGetNumDevs
    dec eax
    js near .End                ;no wave out devices
    jz .OpenFirstDev            ;only one, so open first device
    mov eax,WAVE_MAPPER
.OpenFirstDev:

    ; setup wave format structure
    mov ecx,[Sound.SampleRate]
    mov edx,1
    test byte [SoundFlags],SoundFlags.Force8bit
    jnz .8bit
    shl ecx,1                   ;bytes per second * 2
    shl edx,1                   ;byte -> word
.8bit:
    mov [Sound.wfx+WAVEFORMATEX.nAvgBytesPerSec],ecx ;for buffer estimation
    mov [Sound.wfx+WAVEFORMATEX.nBlockAlign],dx ;byte size of complete sample
    shl edx,3
    mov [Sound.wfx+WAVEFORMATEX.wBitsPerSample],dx ;bits per sample of mono data

    ; open audio device (eax=audio device number)
    api waveOutOpen, Sound.hwo,eax, Sound.wfx,0,0, WAVE_ALLOWSYNC
    ;debugpause "waveform output handle = %X",[Sound.hwo]
    test eax,eax
    mov esi,Text.NoWaveAudio
    jnz near StatusMessage

    ; prepare memory for buffers
    call ClearWaveBuffer.NoCheck
    mov ebx,[Sound.hwo]
    mov edi,Sound.lpwh0
    mov esi,Text.WaveAllocError
.PrepNext:
    mov dword [edi+WAVEHDR.dwBufferLength],Sound.FrameSize
    api waveOutPrepareHeader, ebx, edi,WAVEHDR_size
    ;debugwrite "woph = %d @%d",eax,edi
    add edi,WAVEHDR_size
    test eax,eax
    jnz near .ErrorClose
    cmp edi,Sound.lpwh0+((Sound.MaxFrames-1)*WAVEHDR_size)
    jbe .PrepNext

    ; calculate samples per frame
    mov eax,[Sound.SampleRate]
    ;mov [Sound.MixRate],eax
    xor edx,edx
    mov ecx,Sound.FramesPerSec  ;frames per second (aka thread calls)
    div ecx                     ;samples per sec = sample rate / frames
    mov [Sound.IntSamples],eax  ;constant samples to generate per interrupt
    mov [Sound.MixSamples],eax  ;variable samples to mix and send to sound card (depending on sync)
    ; there is no need to set the buffer sizes because CopyMixBuffer will

    xor eax,eax
    mov [Sound.DmaTime],eax
    mov [Sound.DmaLag],eax

    ; print name of driver to indicate success
    api waveOutGetDevCaps, ebx, Sound.woc, WAVEOUTCAPS_size
    mov esi,Sound.woc+WAVEOUTCAPS.szPname
    call StatusMessage
    or byte [SoundFlags],SoundFlags.Da

.End:
    ret

; Very rare error but has happened on my system before when memory was low,
; and the silence really, really confused me
; (esi=error msg)
.ErrorClose:
    api waveOutClose, ebx
    ;api waveOutGetErrorText, eax,WriteDebugFormula.TextBuffer,MAXERRORLENGTH
    ;debugpause "waveOutError=%s",WriteDebugFormula.TextBuffer
    ;mov esi,Text.ErrorMsg
    jmp StatusMessage

;---------------------------------------
; Closes wave audio device. This function assumes all audio threads
; have already been suspended or terminated. If not, ...!
.Release:
    btr dword [SoundFlags],SoundFlags.DaBit
    jnc .End
    call ClearWaveBuffer.NoCheck
    mov esi,Text.ReleasingWave
    call StatusMessage

    mov ebx,[Sound.hwo]
    api waveOutReset, ebx
    mov edi,Sound.lpwh0
.UnprepNext:
    api waveOutUnprepareHeader, ebx, edi,WAVEHDR_size
    add edi,byte WAVEHDR_size
    cmp edi,Sound.lpwh0+(Sound.MaxFrames-1)*WAVEHDR_size
    jbe .UnprepNext

    api waveOutClose, ebx
    mov dword [Sound.hwo],0
    ret

%endif

section text
Text.InitializingWave:  db "Initializing wave audio...",0
%ifdef DosVer
Text.InitializedDa:     db "SB x.xx compatible ##bit",0
Text.SbNotReset:        db "Sound card would not reset !",0
Text.ReleasingWave:     db "Releasing wave audio resources",0
%else
Text.NoWaveAudio:       db "Could not open wave audio !",0
Text.ReleasingWave:     db "Releasing wave audio device",0
Text.WaveAllocError:    db "Could not allocate buffer memory !??",0
%endif
section code


%ifdef DosVer
;-----------------------------------------------------------------------------
; Near pointless function whose sole function is to simply acknowledge the
; unused sound card generated interrupts and return. Not much, but it is very
; important for some computers. On mine, the sound simply stops playing,
; while some actually triple-fault! Yeah, the entire stupid computer reboots
; just because the sound card was not acknowledged. The dumbest thing is that
; it happens even when the IRQ channel is disabled.
SoundHandler:
    push eax
    push edx
    push ds

    mov ds,[cs:Program.DataSelector]
    ;inc dword [0B8000h+160] ; increment character on screen for debugging

%if 0
    ; acknowledge MPU
    test byte [SoundFlags],SoundFlags.Mpu
    jz .NoMpu
    mov edx,[Sound.MpuPort]
    in al,dx
.NoMpu:
%endif

    ; Acknowledge the SB's interrupt so it doesn't send it again
    ; Doing this simple step below is gravely important. Without it, the sound
    ; card may continue sending endless interrupts to the point that the
    ; stack overflows and the pc triple faults - most annoying!
    mov edx,[Sound.IoPort]
    add dl,SbAdr.Ack8bit
    in al,dx
    inc edx
    in al,dx
    ;bt dword [SoundFlags],SoundFlags.Force8bitBit
    ;adc dl,SbAdr.Ack8bit
    ;in al,dx

    ; allow the PIC to signal more interrupts
    cmp byte [Sound.Irq],8
    mov al,20h
    jb .LowIrq
    out Pic.Mode2,al
.LowIrq:
    out Pic.Mode1,al
    pop ds
    pop edx
    pop eax
    iret
%endif


%ifdef DosVer
;-----------------------------------------------------------------------------
; Reads single byte from sound card. Many program's sound routines just have
; a tight loop here, so that if anything goes wrong, you're stuck in one of
; those great infinite loops. Personally, I can't stand the thought of such
; code, so I provide a timeout by using the 15us timer. If timeout occurs,
; the routine ignores the fact that the card isn't ready and just reads it
; anyway.
;
; ()
; (al=data, ecx=success if nonzero; !edx)
ReadSbDsp:
    mov edx,[Sound.IoPort]
    add dl,SbAdr.ReadStatus
    mov ecx,67                  ;set timeout to 1 millisecond just in case
.Wait:                          ;67 = .001 / .000015085
    in al,dx
    test al,al
    js .Ready
    in al,61h                   ; Read timer connected to port 61h at bit 4
    and al,10h                  ; This bit toggles every 15.085 (micro sec)
    cmp al,ah
    je .Wait
    mov ah,al
    dec ecx
    jg .Wait

.Ready:
    add dl,SbAdr.Read-SbAdr.ReadStatus
    in al,dx
    ret
%endif


%ifdef DosVer
;-----------------------------------------------------------------------------
; Writes single byte to sound card. If timeout occurs, the routine ignores
; the fact that the card isn't ready and just writes it anyway.
;
; (al=data)
; (ecx=success if nonzero; !ecx,edx)
WriteSbDsp:
    push eax
    mov edx,[Sound.IoPort]
    add dl,SbAdr.WriteStatus
    mov ecx,67                  ;set timeout to 1 millisecond just in case
.Wait:                          ;67 = .001 / .000015085
    in al,dx
    test al,al
    jns .Ready
    in al,61h                   ; Read timer connected to port 61h at bit 4
    and al,10h                  ; This bit toggles every 15.085 (micro sec)
    cmp al,ah
    je .Wait
    mov ah,al
    dec ecx
    jg .Wait

.Ready:
    pop eax
    ;add dl,SbAdr.Write-SbAdr.WriteStatus  ;same port
    out dx,al
    ret
%endif


%ifdef DosVer
;-----------------------------------------------------------------------------
; Separate from InitDaSound so that it can be called multiple times. That way
; the sample rate, bits, and stereo options can be changed within the program
; without needing to exit and restart it. Supports 8bit, high speed 8bit, and
; 16bit, but all of them in mono only (didn't care enough for stereo).
;
; Note while the DMA controller is programmed with the true buffer size, the
; sound card is given a ridiculously large value so that it signals the
; minimum frequency of pointless interrupts, since none of the sound
; processing even occurs in the handler. The handler's only purpose is to
; simply acknowledge the interrupts and return.
;
; Oddly, some sound cards always generate at least one interrupt per buffer
; transfer, regardless of the transfer size given to it (Crystal Audio 1999).
; I think what is happening is that the legacy emulator is intercepting all
; sound related port writes (even to the DMA) and choosing to do whatever it
; wants. No big deal though...
;
InitDmaTransfer:
    test byte [SoundFlags],SoundFlags.Da
    jz near .IgnoreCall
    mov esi,Text.StartingSound
    call StatusMessage

    ; clear the sound buffer and reset its position offset
    mov dword [Sound.BufferPos],0
    call ClearWaveBuffer.NoCheck

    ; The reason the convolution immediately below is that some sound cards
    ; setups can actually use the 8bit DMA channels for 16bit output. Another
    ; reason is that they sometimes 'forget' to set the H parameter in the
    ; BLASTER variable.

    mov ebx,[Sound.Hdma]
    cmp bl,4
    je .UseLdma
    test byte [SoundFlags],SoundFlags.Force8bit
    jz .UseHdma
.UseLdma:
    mov bl,[Sound.Ldma]
.UseHdma:
    mov [Sound.DmaChannel],bl
    cmp bl,4
    jae .SetupHdma

; (ebx=dma channel)
.SetupDma:
    ; set up transfer on DMA side
    mov al,bl
    or al,4
    out 0Ah,al                  ;mask DMA channel for programming
    ;mov al,bl                  ;just done above
    xor al,58h | 4
    out 0Bh,al                  ;set transfer mode (single/autoinit/write)
    ;xor al,al                  ;unnecessary since any value will work
    out 0Ch,al                  ;reset flip-flop

    mov eax,[Sound.BufferPtr]
    lea edx,[ebx*2]             ;port for address and length
    out dx,al                   ;set address low byte
    mov al,ah
    out dx,al                   ;set address high byte
    inc dl
    mov al,(Sound.BufferSize-1) & 255
    out dx,al                   ;set buffer size low byte
    mov al,(Sound.BufferSize-1) >> 8
    out dx,al                   ;set buffer size high byte
    mov dx,[.DmaPageTbl+ebx*2]  ;get page register for channel
    shr eax,16                  ;get top four bits of buffer ptr for page
    out dx,al                   ;set page
    mov al,bl
    out 0Ah,al                  ;reenable channel for transfer

    jmp short .SetupSb

;(ebx=dma channel)
.SetupHdma:
    ; set up transfer on DMA side
    mov al,bl
    ;or al,4                    ;bit is already set anyway
    out 0D4h,al                 ;mask DMA channel for programming
    ;mov al,bl                  ;just done above
    xor al,58h | 4
    out 0D6h,al                 ;set transfer mode (single/autoinit/write)
    ;xor al,al                  ;unnecessary since any value will work
    out 0D8h,al                 ;reset flip-flop

    mov eax,[Sound.BufferPtr]
    lea edx,[ebx*4+0C0h-16]     ;port for address and length
    shr eax,1                   ;both page and offset / 2
    out dx,al                   ;set address low byte
    mov al,ah
    out dx,al                   ;set address high byte
    add dl,2
    mov al,(Sound.BufferSize/2-1) & 255
    out dx,al                   ;set buffer size low byte
    mov al,(Sound.BufferSize/2-1) >> 8
    out dx,al                   ;set buffer size high byte
    mov dx,[.DmaPageTbl+ebx*2]  ;get page register for channel
    shr eax,15                  ;get top four bits of buffer ptr for page
    out dx,al                   ;set page
    mov al,bl
    and al,3
    out 0D4h,al                 ;reenable channel for transfer

.SetupSb:
    ; determine number of samples to generate per timer interrupt. A common
    ; rate like 22050hz would require 735 per interrupt (30 ints per second).
    mov eax,[Sound.SampleRate]
    xor edx,edx
    mov ebx,Sound.FramesPerSec  ;PIT interrupts per second
    div ebx                     ;samples per sec = sample rate / frames
    mov [Sound.IntSamples],eax  ;constant samples to generate per interrupt
    mov [Sound.MixSamples],eax  ;variable samples to mix and send to sound card (depending on sync)

    ; tell the sound card the sampling rate
    cmp dword [Sound.CardVersion],400h  ;>= 4.x supports direct sample rate
    jb .SetTimeConstant         ;instead of dumb time constants
    mov al,41h
    call WriteSbDsp
    mov eax,[Sound.SampleRate]
    ;mov [Sound.MixRate],eax
    xchg al,ah                  ;high byte then low... why?
    call WriteSbDsp
    mov al,ah
    call WriteSbDsp
    jmp short .SampleRateSet
.SetTimeConstant:
    ; the SB documentation gives the formula: 65536-(256000000/SampleRate)
    ; but this is one slightly more accurate: 256-(1000000/SampleRate) using
    ; the first formula and playing this program alongside the real SNES
    ; sounds terrible (the off pitch hurts my ears :)
    mov al,040h                 ;set time constant
    call WriteSbDsp             ;TimeConstant = 65536-(256000000/SampleRate) or 256-(1000000/SampleRate)
    xor edx,edx                 ;11025hz=A5 22050=D2 32000=E0 44100=E9
    ;mov eax,256000000
    mov eax,1000000
    mov ebx,eax
    div dword [Sound.SampleRate]
    neg al                      ;same as 256-x
    ;neg eax                    ;same as 65536-x
    ;mov al,ah
    call WriteSbDsp

.SampleRateSet:

    ; set up transfer on SB side
    test byte [SoundFlags],SoundFlags.Force8bit
    jz .16bit

.8bit:
    mov al,048h                 ;set transfer size
    call WriteSbDsp
    ;mov eax,[Sound.IntSamples]
    mov al,Sound.TransferSize & 255
    call WriteSbDsp             ;low byte first
    ;mov al,ah
    mov al,Sound.TransferSize >> 8
    call WriteSbDsp             ;high byte next

    ; if DSP version < 4 and sample rate > 23000, enter high speed mode
    ; if you try play 23001-44100hz without entering high speed, the sample
    ; rate is clipped to its maximum 23000hz by the card.
    cmp dword [Sound.SampleRate],Sound.HighSampleRate
    jbe .NoHighSpeed
    test byte [SoundFlags],SoundFlags.NeedHighSpeed
    jz .NoHighSpeed             ;>= 4.x need not high speed mode
    or byte [SoundFlags],SoundFlags.HighSpeed
    mov al,90h                  ;begin high-speed 8bit PCM output
    jmp WriteSbDsp
    ;ret
.NoHighSpeed:
    mov al,01Ch                 ;begin 8bit PCM output
    jmp WriteSbDsp
    ;ret

.16bit:
    mov al,10110110b            ;begin 16bit PCM output, fifo on
    call WriteSbDsp
    mov al,10h                  ;mode=16bit signed mono
    call WriteSbDsp
    ;mov eax,[Sound.IntSamples]
    mov al,Sound.TransferSize & 255
    call WriteSbDsp             ;low byte first
    ;mov al,ah
    mov al,Sound.TransferSize >> 8
    jmp WriteSbDsp              ;high byte next
    ;ret

;---------------------------------------
.Stop:
    test byte [SoundFlags],SoundFlags.Da
    jz .IgnoreCall
    mov esi,Text.StoppingSound
    call StatusMessage

    ; one dumb sound card (Crystal Audio Codec) does not stop playing when
    ; you TELL it to stop. No, you tell it to exit, pause, disable the DMA
    ; channel, or even reset it, and it still keeps playing! So, the least
    ; we can do is silence it.
    call ClearWaveBuffer.NoCheck

    ; stop sound card transfer
    ; if in high speed mode
    ;   reset sound card
    ; elseif 8bit
    ;   pause 8bit dma
    ; else 16bit
    ;   pause 16bit dma
    ; endif
    btr dword [SoundFlags],SoundFlags.HighSpeedBt
    jnc .StopLowSpeed
    mov edx,[Sound.IoPort]      ;reset sound card to exit high speed mode
    mov al,1
    add dl,SbAdr.Reset
    out dx,al                   ;write 1 to reset port
    mov ecx,2                   ;delays 15-30us (need 3us)
    call TimedWait
    ;xor al,al
    ;out dx,al                   ;write 0 to reset
    ;mov ecx,7                   ;delay 100 microseconds
    ;call TimedWait              ;7 = .0001 / .000015085
    ;jmp short .Stopped
.StopLowSpeed:
    test byte [SoundFlags],SoundFlags.Force8bit
    mov al,SbCmd.PauseDma8bit
    jnz .Pause8bit
    mov al,SbCmd.PauseDma16bit
.Pause8bit:
    call WriteSbDsp
.Stopped:

%if 0
    test byte [SoundFlags],SoundFlags.Force8bit
    mov al,SbCmd.ExitDma8bit
    jnz .Exit8bit
    mov al,SbCmd.ExitDma16bit
.Exit8bit:
    call WriteSbDsp
%endif

    ; disable DMA channel
    mov al,[Sound.DmaChannel]
    cmp al,4
    jb .DisableDma
    ;or al,4 ;unnecessary since bit 2 is already set
    out 0D4h,al                 ;mask DMA channel for programming
    ret
    ;jmp short .DmaDisabled
.DisableDma:
    or al,4
    out 0Ah,al                  ;disable DMA channel
.DmaDisabled:
.IgnoreCall:
    ret


section data
align 2
.DmaPageTbl:    dw 87h,83h,81h,82h, 8Fh,8Bh,89h,8Ah
section text
Text.StartingSound:     db "Starting sound transfer",0
Text.StoppingSound:     db "Stopping sound transfer",0
section code
%endif


;-----------------------------------------------------------------------------
; Simply clears the sound card buffer (not mixing buffer). Used whenever
; silence should be heard, like when the sound card is first initialized
; and no song is playing yet, or when everything is paused.
;
ClearWaveBuffer:
    test byte [SoundFlags],SoundFlags.Da
    jz .IgnoreCall
.NoCheck:
    cld
    mov edi,[Sound.BufferPtr]
    xor eax,eax                 ;0 is silence for 16bit
    test byte [SoundFlags],SoundFlags.Force8bit
    jz .Clear16bit
    ;mov eax,81818181h           ;128 (80h) is silence for 8bit
    mov eax,81818181h           ;128 (80h) is silence for 8bit
.Clear16bit:                    ;but for some odd reason, 81h reduces static
    mov ecx,Sound.BufferSize/4  ;hiss, the barely audible high pitch tone,
    rep stosd                   ;and faint crackling sounds
.IgnoreCall:
    ret


%if 0 ;saw wave
    mov edi,[Sound.BufferPtr]
    xor eax,eax
    mov ecx,Sound.BufferSize
.ClearNext:
    mov [edi],ah
    add eax,byte 111
    inc edi
    dec ecx
    jg .ClearNext
%endif


;-----------------------------------------------------------------------------
; Simply clears the 32bit mixing buffer (not sound card buffer). Used before
; mixing digital audio of voices and sample together
;
; () ()
ClearMixBuffer:
    xor eax,eax
    mov edi,MixBuffer
    ;mov ecx,[Sound.MixSamples]
    ;add ecx,byte 3
    ;shr ecx,2                   ;/4
    mov ecx,Sound.MixSize/4
    cld
    rep stosd
    ret


;-----------------------------------------------------------------------------
; Keeps sound card output and mixing synchronized. The DOS version uses
; progressive buffering, always staying at least one frame ahead of DMA. The
; Windows version stays enough blocks ahead that other program's actions do
; not affect it significantly, but close enough to realtime to minimize the
; delay between pressing a key and hearing the result.
;
; The mixing rate and the sound card's rate are not exactly the same since
; the sound generation is tied to the PIT for more accurate timing, rather
; than an imprecise output rate that varies from card to card.
;
; Both the DOS and Windows version return a suggested number of samples to
; resynchronize if necessary. The returned buffer size (samples not bytes)
; is the standard frequency/frames precalculated when the device was
; initialized, plus the average deviation per frame - current buffer lag
; averaged with previous buffer lags (if ahead or behind).
;
; Under Windows, there is some expected waiver between the mixing position
; and sound position because of multithreading (so averaging). Under DOS, the
; PIT timing is very accurate.
;
SyncToWave:

%ifdef DosVer
; () (eax=DMA address, edx=suggested buffer size in samples)
;
; Ensures the output and DMA are synchronized, in case you switch away to
; Windows, or if the sound card does not have accurate timing (which I
; have found!). For most sound cards, the mixing can safely stay just ahead
; of the sound output (closer timing), but for at least one (Crystal Audio)
; any less than a 1/30 second causes annoying clicks. So, this routine
; ensures the mixing is always one interrupt's buffer length ahead of DMA.
; That 1/30 second lag isn't even noticeable though, except when both FM and
; digital audio are played simultaneously, making it audible that the FM
; attack comes before the wave.
;
; When either process drifts apart (mixing ahead of DMA, or DMA faster than
; mixing), the routine will routine return a suggested buffer size to bring
; them closer together. If somehow the two get too far apart from each other,
; it will resynchronize the buffer position to the current DMA address.
;
; The visual below is more for my sake than yours. Envisioning it all in my
; mind was a little complicated.
;
; We're fine, DMA is a full buffer behind us
;             |----------|
;   ------*---|----------*----------|
;      DMA            MIX @4268
;
; We've fallen behind somehow and DMA is catching up
; Mix larger buffers to make up for it
;  |---------------------|
;   -*--------*----------|----------*
;   DMA      MIX @4268         NEW MIX @12804
;
; The next interrupt, the distance is fine again
;                        |----------|
;   ----------|-*--------|----------*
;              DMA                 MIX @12804

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
    mov edx,[Sound.IntSamples]
    sub eax,[Sound.BufferPtr]   ;buffer offset = DMA address - base ptr
    mov ecx,edx
    shr ecx,2                   ;/4
    mov ebx,[Sound.BufferPos]
    add eax,ecx                 ;+25% hack for dumb Crystal Audio card
    and eax,Sound.BufferSize-1
    sub ebx,eax                 ;lag = buffer pos - trailing DMA pos
    ; this does not use cl from above because some sound cards utilize low
    ; DMA channels for 16bit data
    and ebx,Sound.BufferSize-1
    test byte [SoundFlags],SoundFlags.Force8bit
    jnz .8bit
    shr ebx,1                   ;lag /2 for words
.8bit:

    ;push dword [Sound.BufferPos]
    ;mov [PrintDebugInfo.Value1],eax
    ;pop dword [PrintDebugInfo.Value2]
    ;mov [PrintDebugInfo.Value3],ebx

    ; check deviation difference (BufferPos - DmaPos should be >=IntSamples)
    ; (eax=DMA buffer offset, ebx=lag, edx=int samples)
    sub ebx,edx                 ;lag < buffer size
    je .InSync                  ;just fine
    jb .Behind                  ;falling behind, DMA will eventually pass us
    cmp ebx,edx                 ;we're faster than DMA
    jb .Ahead

; somehow got way off (Alt+Tab probably to blame)
; (eax=DMA buffer offset, edx=buffer size)
.OffSync:
    ; resync buffer position ahead of what DMA is currently reading
    ;inc dword [PrintDebugInfo.Value4]
    mov ecx,edx                 ;Sound.IntSamples*2
    test byte [SoundFlags],SoundFlags.Force8bit
    jnz .8bitResync
    shl ecx,1                   ;*2 if words, else bytes
.8bitResync:
    add ecx,eax                 ;Sound.MixSamples+Dma address
    and ecx,Sound.BufferSize-2  ;wrap within buffer to nearest word
    mov [Sound.BufferPos],ecx
    ret
.InSync:
    mov [Sound.DmaLag],ebx
    ret

.Behind:
    ;inc dword [PrintDebugInfo.Value4]
    xchg [Sound.DmaLag],ebx
    add ebx,[Sound.DmaLag]
    sar ebx,1

    sub edx,ebx
    cmp edx,Sound.MaxMixSamples
    jbe .BelowMax
    mov edx,Sound.MaxMixSamples
.BelowMax:
    ret

.Ahead:
    ;inc dword [PrintDebugInfo.Value3]
    xchg [Sound.DmaLag],ebx
    add ebx,[Sound.DmaLag]
    sar ebx,1

    sub edx,ebx
    cmp edx,Sound.MinMixSamples
    jae .AboveMin
    mov edx,Sound.MinMixSamples
.AboveMin:
    ret

;---------------------------------------
; () (edx=suggested buffer size in samples)
%elifdef WinVer

  %if 0 ;determine timer/sample accuracy
    api timeGetTime
    api waveOutGetPosition, [Sound.hwo], Sound.MmTime,MMTIME_size
    debugwrite "waveOutGetPosition time=%d wave=%d",eax,[Sound.MmTime+MMTIME.sample]
    ret
  %endif

    ;attempt #7 finally worked
    xor eax,eax
    mov esi,Sound.lpwh0+WAVEHDR.dwFlags
    xor ecx,ecx
    mov ebx,[Sound.IntSamples]  ;- frame size
.CountNext:
    bt dword [esi],eax
    adc ecx,eax
    add esi,byte WAVEHDR_size
    cmp esi,Sound.lpwh0+Sound.MaxFrames*WAVEHDR_size
    jb .CountNext
    ;debugwrite "free frames = %d/%d",ecx,Sound.MaxFrames

    mov edx,ebx                 ;copy frame size
    shr ebx,3                   ;int samples/8
    cmp ecx,7
    xchg [Sound.DmaLag],ecx
    jae .Behind
    ;add ecx,[Sound.DmaLag]
    cmp ecx,5
    je .InSync
    ;cmp ecx,3
    ;je .InSync
    ja .Behind
.Ahead:
    neg ebx ;-/+
.Behind:
    add edx,ebx
.InSync:

    ;debugwrite "sync freewb=%d bufsiz=%d",ecx,edx
    ret

%endif


;-----------------------------------------------------------------------------
; Copies mixing buffer to sound card buffer in low memory, converting the
; 32bit samples to either 8bit or 16bit, and clipping out of range samples.
; How many samples it copies depends on whether it is ahead or behind (the
; suggested buffer returned by SyncToWave).
;
; () ()
CopyMixBuffer:

    mov esi,MixBuffer
    mov ebx,[Sound.BufferPtr]
    mov edi,[Sound.BufferPos]
    mov ecx,[Sound.MixSamples]

    test byte [SoundFlags],SoundFlags.Force8bit
    jnz .8bitNext

.16bitNext:
    mov eax,[esi]
  %ifdef DosVer
    and edi,Sound.BufferSize-2  ;wrap (to even word)
  %endif
    cmp eax,32768
    jb .16bitValid
    cmp eax,-32768
    jae .16bitValid
    sar eax,31                  ;sign extend
    xor eax,32767
.16bitValid:
    mov [ebx+edi],ax
    add esi,byte 4
    add edi,byte 2
    dec ecx
    jg .16bitNext
    jmp short .End

.8bitNext:
    mov eax,[esi]
  %ifdef DosVer
    and edi,Sound.BufferSize-1  ;wrap to byte
  %endif
    add eax,32768               ;toggle sign bit for conversion to 8bit
    add esi,byte 4
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

%ifdef DosVer
    and edi,Sound.BufferSize-1
    mov [Sound.BufferPos],edi
    ret

%elifdef WinVer

    mov esi,edi
    shr esi,Sound.FrameSizeShl
    shl esi,5                   ;*32 (WAVEHDR_size)
    and edi,Sound.FrameSize-1
    add esi,Sound.lpwh
    mov [esi+WAVEHDR.dwBufferLength],edi

    ; write current buffer and cycle to next
    api waveOutWrite, [Sound.hwo],esi,WAVEHDR_size
    ;debugwrite "  %d=wow esi=%X buflen=%d",eax,esi,edi
    add dword [Sound.BufferPos],Sound.FrameSize
    cmp dword [Sound.BufferPos],Sound.FrameSize*(Sound.MaxFrames-1)
    jbe .NoBufferWrap
    mov dword [Sound.BufferPos],0
.NoBufferWrap:

    ret

%endif


;-----------------------------------------------------------------------------
; Detects MPU, resets it, and enters UART mode.
; Be sure reset the MPU before quitting the program, or else you may
; experience strange side effects like Window's sound effects looping
; infinitely??? Maybe because the MPU and wave audio share the same
; interrupt, and the sound driver becomes confused.
;
; ()
; ([SoundFlags.Mpu])

%ifdef DosVer
InitMpu.IfEnabled:
    test byte [SoundFlags],SoundFlags.Mpu
    jnz InitMpu
    ret

InitMpu:
    mov esi,Text.InitializingMpu
    call StatusMessage.Pending

    ; try to reset MPU
    mov esi,Text.MpuNotReset
    call WaitMpu.Out            ;wait until device ready
    jc .Fail                    ;never became ready before time out
    mov al,MpuCmd.Reset
    out dx,al                   ;reset MPU
    ;dec edx
    ;in al,dx                    ;acknowledge any pending interrupt (some cards do)
    call WaitMpu.In             ;wait for success/fail response
    dec edx                     ;MPU data port
    in al,dx                    ;get response
    jc .Fail
    cmp al,MpuCmd.RespAck       ;successful reset?
    jne .Fail

    ; once reset, enter UART mode
    mov esi,Text.MpuNoUart
    call WaitMpu.Out
    jc .Fail
    mov al,MpuCmd.Uart
    out dx,al                   ;enter UART mode
    call WaitMpu.In             ;wait for success/fail response
    dec edx                     ;MPU data port
    in al,dx                    ;get response
    jc .Fail
    cmp al,MpuCmd.RespAck       ;successful reset?
    jne .Fail

    or byte [SoundFlags],SoundFlags.Mpu
    mov esi,Text.InitializedMpu
    jmp StatusMessage

.End:
    ret

.Fail: ;(esi=msg ptr)
    and byte [SoundFlags],~SoundFlags.Mpu
    jmp StatusMessage
    ;ret

;---------------------------------------
; !always call this before exiting the program!
; if the MPU has been initialized but is not reset before exiting, sound may
; not play at all in other programs. don't ask me why... :/
.Release:
    btr dword [SoundFlags],SoundFlags.MpuBit
    jnc .End
    mov esi,Text.ReleasingMpu
    call StatusMessage
    call WaitMpu.Out
    mov al,MpuCmd.Reset
    out dx,al                   ;reset MPU
    ret

;---------------------------------------
; Opens MIDI port in Windows
;
; ()
; ([SoundFlags.Mpu])
%elifdef WinVer

InitMpu.IfEnabled:
    test byte [SoundFlags],SoundFlags.Mpu
    jnz InitMpu
    ret

InitMpu:
    and byte [SoundFlags],~SoundFlags.Mpu
    mov esi,Text.InitializingMpu
    call StatusMessage.Pending

    xor ebx,ebx
.Next:
    api midiOutGetDevCaps, ebx, Sound.moc,MIDIOUTCAPS_size
    test eax,eax
    jnz .NotFound
    cmp word [Sound.moc+MIDIOUTCAPS.wTechnology],MOD_MIDIPORT
    je .MpuFound
    inc ebx
    jmp short .Next
.NotFound:
    mov esi,Text.NoMpuAudio
    jmp StatusMessage

.MpuFound:
    xor eax,eax
    api midiOutOpen, Sound.hmpo,ebx, eax, eax, eax ;NULL,0,CALLBACK_NULL
    test eax,eax
    mov esi,Text.MpuBusy
    jnz near  StatusMessage

    ;debugpause "midi output handle = %X",[Sound.hmpo]
    mov esi,Sound.moc+MIDIOUTCAPS.szPname
    call StatusMessage
    or byte [SoundFlags],SoundFlags.Mpu
.End:
    ret

;---------------------------------------
; Closes the MIDI port. This function assumes all audio
; threads have already been suspended or terminated.
.Release:
    btr dword [SoundFlags],SoundFlags.MpuBit
    jnc .End
    mov esi,Text.ReleasingMpu
    call StatusMessage
    api midiOutReset, [Sound.hmpo]
    api midiOutClose, [Sound.hmpo]
    mov dword [Sound.hmpo],0
    ret

%endif

section text
Text.InitializingMpu:   db "Initializing external MIDI port...",0
%ifdef DosVer
Text.InitializedMpu:    db "Initialized MPU401",0
Text.MpuNotReset:       db "Busy or wrong IO address !",0
Text.MpuNoUart:         db "MPU would not enter UART mode !",0
Text.ReleasingMpu:      db "Stopping MPU output",0
%elifdef WinVer
Text.NoMpuAudio:        db "No MIDI port device found !",0
Text.MpuBusy:           db "Could not open MIDI port !",0
Text.ReleasingMpu:      db "Releasing MIDI port device",0
%endif
section code


%ifdef DosVer
;-----------------------------------------------------------------------------
; ()
; (cf=error, edx=mpu cmd port; esi,edi,ecx)
;
; waits until either data is ready to be written or is available to read,
; depending on the bits set in the mask.
WaitMpu.In:
    mov eax,0FFFF0000h | (MpuCmd.MaskIn << 8)
    jmp short WaitMpu.Given
WaitMpu.Out:
    ; set counter to 65535, and mask to either in or out bit
    mov eax,0FFFF0000h | (MpuCmd.MaskOut << 8)
WaitMpu.Given:
    mov edx,[Sound.MpuPort]
    inc edx
WaitMpu.Next:
    in al,dx
    test al,ah
    jz WaitMpu.Done             ;status bit is clear, not busy anymore
    sub eax,1<<16
    jnc WaitMpu.Next
    ;stc                        ;error
WaitMpu.Done: ;(cf=0)
    ret
%endif


%ifdef DosVer
;-----------------------------------------------------------------------------
; (al=value) (; ebx,esi,edi,al)
WriteMpu:
    mov ecx,eax
    call WaitMpu.Out
    jc .Err
    ;(edx=mpu port+1 from call)
    ;mov edx,[Sound.MpuPort]
    mov eax,ecx
    dec edx
    out dx,al                   ;send to data port
.Err:
    ret
%endif


%ifdef DosVer
;-----------------------------------------------------------------------------
; (esi=data string ptr, ecx=number bytes) (; ebx,edi)
WriteMpuString:
    cld
.Next:
    call WaitMpu.Out
    jc .Err
    ;(edx=mpu port+1 from call)
    ;mov edx,[Sound.MpuPort]
    lodsb
    dec edx
    out dx,al                   ;send to data port
    dec ecx
    jnz .Next
.Err:
    ret
%endif


%ifdef WinVer
;-----------------------------------------------------------------------------
; Opens default MIDI device (Windows only)
;
; ()
; ([SoundFlags.Gm])

InitGm.IfEnabled:
    test byte [SoundFlags],SoundFlags.Gm
    jnz InitGm
    ret

InitGm:
    and byte [SoundFlags],~SoundFlags.Gm
    mov esi,Text.InitializingGm
    call StatusMessage.Pending

    xor ebx,ebx
.Next:
    api midiOutGetDevCaps, ebx, Sound.moc,MIDIOUTCAPS_size
    test eax,eax
    jnz .NotFound
  %ifdef debug
    ; stupid CrystalWave synth returns it is an external MIDI port when
    ; it is NOT
    movzx eax,word [Sound.moc+MIDIOUTCAPS.wTechnology]
    debugwrite "midi tech=%d",eax
    movzx eax,word [Sound.moc+MIDIOUTCAPS.wPid]
    debugwrite "midi pid=%d",eax
  %endif
    cmp word [Sound.moc+MIDIOUTCAPS.wTechnology],MOD_SYNTH
    je .GmFound
    inc ebx
    jmp short .Next
.NotFound:
    mov esi,Text.NoGmAudio
    jmp StatusMessage

.GmFound:
    xor eax,eax
    api midiOutOpen, Sound.hgmo,ebx, eax, eax, eax ;NULL,0,CALLBACK_NULL
    test eax,eax
    mov esi,Text.GmBusy
    jnz near  StatusMessage

    ;debugpause "midi output handle = %X",[Sound.hgmo]
    mov esi,Sound.moc+MIDIOUTCAPS.szPname
    call StatusMessage
    or byte [SoundFlags],SoundFlags.Gm
.End:
    ret

;---------------------------------------
; Closes the MIDI synthesizer. This function assumes all audio
; threads have already been suspended or terminated.
.Release:
    btr dword [SoundFlags],SoundFlags.GmBit
    jnc .End
    mov esi,Text.ReleasingGm
    call StatusMessage
    api midiOutReset, [Sound.hgmo]
    api midiOutClose, [Sound.hgmo]
    mov dword [Sound.hgmo],0
    ret

section text
Text.InitializingGm:    db "Initializing internal synthesizer...",0
Text.NoGmAudio:         db "No synthesizer device found !",0
Text.GmBusy:            db "Could not open synthesizer !",0
Text.ReleasingGm:       db "Releasing internal synthesizer device",0
section code

%endif
