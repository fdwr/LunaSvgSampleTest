;FM Patch Test
;Peekin
;Began 2000-08-16
;Updated 2001-01-17
;http://fdwr.tripod.com/snes.htm
;FDwR@hotmail.com
;
;Simple patch player. Use the arrow keys to select and space to play.
BITS 32
SECTION .text
GLOBAL _WdosxStart

;Fnumber equ 244h        ;A 440hz
Fnumber equ 159h        ;C 261.625 (infamous middle C)
;Fnumber equ 110h


_WdosxStart:

    push ds
    pop es

    mov ah,9
    mov edx,Text.About
    int 21h

    mov eax,2001h       ;enable different waveforms
    call WriteSbReg
    mov esi,PatchData
    call SetVoicePatch
    call ShowPatch

.LoopTop:
	mov ah,1
	int 16h
    jz .EndKeyCheck
    xor eax,eax
    int 16h             ;get key press
    cmp al,27
    je near .End
    cmp al,13
    jne .NotEnter
    call PatchDemo
    jmp short .EndKeyCheck
.NotEnter:
    mov ebx,1
    cmp eax,'M'<<8
    je .PatchChange
    neg ebx
    cmp eax,'K'<<8
    je .PatchChange
    mov ebx,16
    cmp eax,'H'<<8
    je .PatchChange
    neg ebx
    cmp eax,'P'<<8
    jne .NoPatchChange
.PatchChange:
    call SetVoiceOff
    mov esi,[CurrentPatch]
    add esi,ebx
    and esi,127
    mov [CurrentPatch],esi
    shl esi,4                   ;*16
    add esi,PatchData
    call SetVoicePatch
    call ShowPatch
    call SetVoiceOn
    bts dword [VoiceOn],0
    jmp .LoopTop
.NoPatchChange:
    ;jmp short .EndKeyCheck

.EndKeyCheck:
    in al,60h
    cmp al,57
    je .NoteOn
    cmp al,57|80h
    jne .EndNoteCheck
.NoteOff:
    btr dword [VoiceOn],0
    jnc .EndNoteCheck
    call SetVoiceOff
    jmp short .EndNoteCheck
.NoteOn:
    bts dword [VoiceOn],0
    jc .EndNoteCheck
    call SetVoiceOn
    ;jmp short .EndNoteCheck
.EndNoteCheck:
    jmp .LoopTop

.End:
    call SetVoiceOff
    mov ax,4C00h
    int 21h


ShowPatch:
    mov esi,[CurrentPatch]
    imul esi,Text.InstrumentNameLen
    add esi,Text.InstrumentList
    mov edi,Text.CurInstrument
    mov ecx,Text.InstrumentNameLen
    rep movsb
    mov edx,Text.CurInstrument
    mov ah,9
    int 21h
    ret


PatchDemo:
    mov esi,PatchData
    push dword 128
.Next:
    mov ecx,10000
    call TimedWait
    call SetVoiceOff
    call SetVoicePatch
    call SetVoiceOn
    add esi,byte 16
	mov ah,1
	int 16h
    jnz .End
    dec dword [esp]
    jnz .Next
.End:
    pop eax             ;discard counter
    ret

;====================
; (al=sb reg, ah=value) - preserves esi,edi,ebx
;
WriteSbReg:
    mov edx,[Sound.MidiPort]
    out dx,al
    shl eax,8               ;keep value safe
    mov ecx,2
    call TimedWait          ;delays 15-30ms
    inc edx
    shr eax,16              ;get saved value
    out dx,al
    mov ecx,3               ;delays 30-45ms
    ;jmp TimedWait

;====================
; Quote from "CPU Independant Timer"
;
; "the perfect anwser.  It seems that there is a timer connected to port 61h
;  at bit 4.  This bit toggles every 15.085 u sec (micro sec)."
;
; (ecx=number of 15.085 microsecond loops) () - Only changes ax and ecx
;
TimedWait:
    in al,61h
    and al,10h              ;mask bit 4
    mov ah,al
.CheckAgain:
    in al,61h
    and al,10h
    cmp al,ah
    jz .CheckAgain          ;no change so loop back
    mov ah,al
    dec ecx
    jnz .CheckAgain
    ret

;====================
; (esi=patch info)
SetVoicePatch:
    xor ebx,ebx
    jmp short .FirstReg
.NextReg:
    mov ah,[esi+ebx]
    inc ebx
    call WriteSbReg
.FirstReg:
    mov al,[PatchRegs+ebx]
    test al,al
    jnz .NextReg
.End:
    ret

;====================
SetVoiceOn:
    mov eax,(Fnumber<<8)|000A0h ;set fnumber
    call WriteSbReg
    mov eax,(Fnumber & 65280)|030B0h ;20h turns on key
    jmp WriteSbReg
    ;ret

;====================
SetVoiceOff:
    mov eax,(Fnumber & 65280)|010B0h ;20h is clear
    jmp WriteSbReg
    ;ret

;==============================
section .data
align 4

CurrentPatch:   dd 26
VoiceOn:        db 0

Sound:
.MidiPort:      dw 388h

PatchRegs:
db 20h,23h      ;multiplier
db 40h,43h      ;level
db 60h,63h      ;attack/decay
db 80h,83h      ;sustain/release
db 0E0h,0E3h    ;waveform
db 0C0h         ;feedback
db 0            ;null (end)

PatchData:
incbin "patches.dat"

Text:
.About:             db "FmTest .001, 2000-08-16, Peekin",13,10
                    db "Use arrow keys to change instrument and Space to play/stop.",13,10,10,"$"
.InstrumentNameLen  equ 28
.CurInstrument:     times .InstrumentNameLen db "."
                    db 13,"$"
.InstrumentList:    ;each instrument name is <= 22 (+6) characters
; PIANO
db "000 - Acoustic Grand        "
db "001 - Bright Acoustic       "
db "002 - Electric Grand        "
db "003 - Honky-Tonk            "
db "004 - Electric Piano 1      "
db "005 - Electric Piano 2      "
db "006 - Harpsichord           "
db "007 - Clavinet              "
; CHROMATIC PERCUSSION
db "008 - Celesta               "
db "009 - Glockenspiel          "
db "010 - Music Box             "
db "011 - Vibraphone            "
db "012 - Marimba               "
db "013 - Xylophone             "
db "014 - Tubular Bells         "
db "015 - Dulcimer              "
; ORGAN
db "016 - Drawbar Organ         "
db "017 - Percussive Organ      "
db "018 - Rock Organ            "
db "019 - Church Organ          "
db "020 - Reed Organ            "
db "021 - Accordian             "
db "022 - Harmonica             "
db "023 - Tango Accordian       "
; GUITAR
db "024 - Nylon String Guitar   "
db "025 - Steel String Guitar   "
db "026 - Electric Jazz Guitar  "
db "027 - Electric Clean Guitar "
db "028 - Electric Muted Guitar "
db "029 - Overdriven Guitar     "
db "030 - Distortion Guitar     "
db "031 - Guitar Harmonics      "
; BASS
db "032 - Acoustic Bass         "
db "033 - Electric Bass (finger)"
db "034 - Electric Bass (pick)  "
db "035 - Fretless Bass         "
db "036 - Slap Bass 1           "
db "037 - Slap Bass 2           "
db "038 - Synth Bass 1          "
db "039 - Synth Bass 2          "
; SOLO STRINGS
db "040 - Violin                "
db "041 - Viola                 "
db "042 - Cello                 "
db "043 - Contrabass            "
db "044 - Tremolo Strings       "
db "045 - Pizzicato Strings     "
db "046 - Orchestral Strings    "
db "047 - Timpani               "
; ENSEMBLE
db "048 - String Ensemble 1     "    
db "049 - String Ensemble 2     "    
db "050 - SynthStrings 1        "    
db "051 - SynthStrings 2        "    
db "052 - Choir Aahs            "    
db "053 - Voice Oohs            "    
db "054 - Synth Voice           "    
db "055 - Orchestra Hit         "    
; BRASS
db "056 - Trumpet               "
db "057 - Trombone              "
db "058 - Tuba                  "
db "059 - Muted Trumpet         "
db "060 - French Horn           "
db "061 - Brass Section         "
db "062 - SynthBrass 1          "
db "063 - SynthBrass 2          "
; REED
db "064 - Soprano Sax           "
db "065 - Alto Sax              "
db "066 - Tenor Sax             "
db "067 - Baritone Sax          "
db "068 - Oboe                  "
db "069 - English Horn          "
db "070 - Bassoon               "
db "071 - Clarinet              "
; PIPE
db "072 - Piccolo               "
db "073 - Flute                 "
db "074 - Recorder              "
db "075 - Pan Flute             "
db "076 - Blown Bottle          "
db "077 - Skakuhachi            "
db "078 - Whistle               "
db "079 - Ocarina               "
; SYNTH LEAD
db "080 - Lead 1 (square)       "
db "081 - Lead 2 (sawtooth)     "
db "082 - Lead 3 (calliope)     "
db "083 - Lead 4 (chiff)        "
db "084 - Lead 5 (charang)      "
db "085 - Lead 6 (voice)        "
db "086 - Lead 7 (fifths)       "
db "087 - Lead 8 (bass+lead)    "
; SYNTH PAD
db "088 - Pad 1 (new age)       "
db "089 - Pad 2 (warm)          "
db "090 - Pad 3 (polysynth)     "
db "091 - Pad 4 (choir)         "
db "092 - Pad 5 (bowed)         "
db "093 - Pad 6 (metallic)      "
db "094 - Pad 7 (halo)          "
db "095 - Pad 8 (sweep)         "
; SYNTH EFFECTS
db "096 - FX 1 (rain)           "
db "097 - FX 2 (soundtrack)     "
db "098 - FX 3 (crystal)        "
db "099 - FX 4 (atmosphere)     "
db "100 - FX 5 (brightness)     "
db "101 - FX 6 (goblins)        "
db "102 - FX 7 (echoes)         "
db "103 - FX 8 (sci-fi)         "
; ETHNIC
db "104 - Sitar                 "
db "105 - Banjo                 "
db "106 - Shamisen              "
db "107 - Koto                  "
db "108 - Kalimba               "
db "109 - Bagpipe               "
db "110 - Fiddle                "
db "111 - Shanai                "
; PERCUSSIVE
db "112 - Tinkle Bell           "
db "113 - Agogo                 "
db "114 - Steel Drums           "
db "115 - Woodblock             "
db "116 - Taiko Drum            "
db "117 - Melodic Tom           "
db "118 - Synth Drum            "
db "119 - Reverse Cymbal        "
; SOUND EFFECTS
db "120 - Guitar Fret Noise     "
db "121 - Breath Noise          "
db "122 - Seashore              "
db "123 - Bird Tweet            "
db "124 - Telephone Ring        "
db "125 - Helicopter            "
db "126 - Applause              "
db "127 - Gunshot               "
