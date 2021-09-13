; Spc2Midi - MIDI file routines
;
; Contained here is a collection of generic MIDI file routines. Except for
; just a few variables in the main source, all these routines are fairly
; independant of the rest of the program; however, the DSP simulation is very
; dependant on these routines.
;
; CreateMidi
; CloseMidi
; WriteMidiEvent
; FlushMidiBuffer
;
; Note all the actual conversion from DSP buffer to MIDI events is done in
; DSPSIM.ASM, not here.
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
Midi:
.HeaderLen      equ 22  ;MIDI header (14) + Track header (8)
.Header:
    ;MIDI Header template
    ;Header ID, Length of six bytes, Format 0, Tracks 1, 250 delta ticks per beat
    db "MThd",0,0,0,6,0,0,0,1,0,250
    ;Followed by the track header, which the size of is later filled in,
    ;since the track size is unknown initially. After done recording, it is
    ;set by CloseMidi.
    db "MTrk",0,0,0,0
.TempoLen       equ 7
.Tempo:
    ;Tempo of one beat every 500,000 microseconds (two beats per second)
    db 0,0FFh,51h,3,7,0A1h,20h
.EndOfTrackLen  equ 4
.EndOfTrack:
    db 0,0FFh,02Fh,0
align 4,db 0
.DeltaDivisor:      dd 128  ;64000 ticks per second / 128 = 500 MIDI ticks ps

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section bss
.FileBufferSize     equ 2048
.Instruments:       resb 16 ;holds the last used instrument for that channel
.DeltaTime:         resd 1  ;last written delta time
.FileNamePtr:       resd 1
.FileHandle:        resd 1
.FileSize:          resd 1  ;file size in bytes, not including headers
.FileBufferPtr:     resd 1  ;point to write to next (also the number of bytes in it)
.FileBuffer:        resb Midi.FileBufferSize+256 ;(+256 for potential overflow)


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

.NoteOff        equ 080h
.NoteOn         equ 090h
.KeyAfterTouch  equ 0A0h
.ControlChange  equ 0B0h
.PatchChange    equ 0C0h
.ChanAfterTouch equ 0D0h
.PitchBend      equ 0E0h
.MetaEvent      equ 0F0h


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Creates a MIDI file and writes the initial header.
; Also resets all variables in the Midi section.
; Note that this function will overwrite any existing file of the given name.
;
; (esi=filename) (cf=error; none)
CreateMidiFile:
    ;open MIDI file
  %ifdef DosVer
    mov ah,3Ch                      ;create file, only writing is necessary
    mov ecx,32                      ;set archive attribute
    mov edx,esi                     ;filename
    int 21h
    jc near .End                    ;error opening
  %elifdef WinVer
    xor eax,eax
    api CreateFile, esi, GENERIC_WRITE,FILE_SHARE_READ, eax, CREATE_ALWAYS, eax,eax
    cmp eax,INVALID_HANDLE_VALUE
    stc
    je near .End
  %endif
    mov [Midi.FileHandle],eax

    ;A note on timing:
    ;
    ;The average precision for most games is 1/500th of a second as they
    ;usually set timer 0 (8000khz) to count once every 16 ticks (typical of
    ;Nintendo produced games). There is no need to have the delta time ticks
    ;more precise than this, since it would be humanly undetectable anyway.
    ;The absolute minimum resolution would 64000 ticks per second (timer 2 at
    ;smallest value).
    ;
    ;The default MIDI beats per minute is 120, making 2 beats per second. So
    ;500 ticks per second / 2 beats per second = 250 delta time ticks per
    ;beat.
    ;
    ;Common timer values
    ;16 zelda/mario/mario2/actraiser/gs mikami/mario kart/StarFox/Vortex/SNES Test/arcana
    ;32 Star Wars ESB/R-Type
    ;36 Secret of Mana/Treasure Hunter G
    ;39 Final Fantasy 6/Rudora No Hihou
    ;42 Chrono Trigger/Front Mission
    ;62 Mario RPG
    ;64 bof2/goof troop/terranigma
    ;76 SD3
    ;80 macross
    ;100 dkc/killer instinct
    ;125 Tales of Phantasia

    ;ouput MIDI header
    mov ebx,eax                     ;copy file handle from the above open
  %ifdef DosVer
    mov ecx,Midi.HeaderLen
    mov edx,Midi.Header
    mov ah,40h                      ;write to file
    int 21h
    jc .CloseEnd                    ;error writing header
  %elifdef WinVer
    api WriteFile, ebx,Midi.Header,Midi.HeaderLen, esp,NULL
    test eax,eax
    jz .CloseEnd                    ;FALSE error writing header
  %endif

    ;Reset variables
    mov dword [Midi.FileBufferPtr],Midi.FileBuffer
    xor eax,eax                     ;set to 0
    mov [Midi.FileSize],eax
    mov [Midi.DeltaTime],eax
    dec eax                         ;set to -1
    cld
    mov edi,Midi.Instruments        ;-1 is an impossible instrument, so a
    mov ecx,4                       ;program change will always occur
    rep stosd                       ;the first time.
    mov [Midi.Instruments],eax      
    mov [Midi.Instruments+4],eax    
    mov [Midi.FileNamePtr],esi

    ;set default tempo of two beats per second
    ;120bpm is the default anyway, but I'm explicitly setting just in case
    mov esi,Midi.Tempo
    mov ecx,Midi.TempoLen
    call WriteMidiEvent

    clc
.End:
    ret

; (ebx=file handle)
.CloseEnd:
  %ifdef DosVer
    mov ah,3Eh          ;close file
    int 21h
  %elifdef WinVer
    api CloseHandle, [Midi.FileHandle]
  %endif
    stc    
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes any unwritten MIDI events to file, turns off any notes still on,
; writes the end of MIDI track event, sets the size in the header, and
; closes the file.
;
CloseMidiFile:
    ;end MIDI with end of track event
    mov esi,Midi.EndOfTrack
    mov ecx,Midi.EndOfTrackLen
    call WriteMidiEvent
    call FlushMidiBuffer

  %ifdef DosVer
    ; set track length
    mov eax,4200h       ;set file position
    mov ebx,[Midi.FileHandle]
    xor ecx,ecx
    mov edx,18          ;offset in file of track length
    int 21h
    mov ecx,[Midi.FileSize]
    xchg cl,ch          ;set to stupid big-endian order
    rol ecx,16
    xchg cl,ch
    push ecx
    mov ah,40h          ;write to file
    mov edx,esp         ;source is big-endian file size saved on stack
    mov ecx,4           ;dword
    int 21h
    pop ecx

    ; close MIDI file
    mov ah,3Eh          ;close file
    ;mov ebx,[Midi.FileHandle]
    int 21h
  %elifdef WinVer
    ; set track length
    mov ebx,[Midi.FileHandle]
    api SetFilePointer, ebx, 18,NULL,FILE_BEGIN
    mov ecx,[Midi.FileSize]
    xchg cl,ch          ;set to stupid big-endian order
    rol ecx,16
    xchg cl,ch
    mov [Midi.FileSize],ecx
    api WriteFile, ebx,Midi.FileSize,4, esp,NULL

    api CloseHandle, ebx
  %endif
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Can be called to write an individual event, such as the track title, author
; name, or end of MIDI. The delta-time must be included with the event.
; This is mainly called by outside routines. Small MIDI events can be handled
; directly, such as delta times and note on/off.
;
; (esi=source, ecx=event length)
WriteMidiEvent:
    ;if (FileBufferIndex + length of MIDI instruction > filebuffersize) then
    ;   write buffer to file
    ;endif
    ;copy event to buffer

    mov edi,[Midi.FileBufferPtr]
    ;debugwrite "WriteMidiEvent esi=%X ecx=%d edi=%X",esi,ecx,edi
    lea eax,[edi+ecx]
    cmp eax,Midi.FileBuffer+Midi.FileBufferSize
    jbe .NoFlush
    push ecx                    ;save length of event
    call FlushMidiBuffer        ;start with new buffer
    pop ecx
.NoFlush:
    ;copy event to buffer
    ;cmp ecx,Midi.FileBufferSize
    ;jbe .EventSizeOk
    ;mov ecx,Midi.FileBufferSize
    ;.EventSizeOk
    cld
    rep movsb
    mov [Midi.FileBufferPtr],edi
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes any events still in buffer to file and adjusts the midi filesize.
;
; () (edi=front of buffer; esi)
FlushMidiBuffer:
    ;if BufferIndex > 0 then
    ;   write buffer to file for .FileBufferIndex length bytes
    ;   .FileSize += .FileBufferIndex
    ;   .FileBufferIndex = 0
    ;endif

    mov ecx,[Midi.FileBufferPtr]
    mov edi,Midi.FileBuffer
    sub ecx,edi
    ;debugwrite "FlushMidiBuffer ecx=%d",ecx
    jz .End
    add [Midi.FileSize],ecx
    mov dword [Midi.FileBufferPtr],edi
  %ifdef DosVer
    mov ebx,[Midi.FileHandle]
    mov edx,edi
    mov ah,40h          ;write to file
    int 21h
  %elifdef WinVer
    api WriteFile, [Midi.FileHandle],edi,ecx, esp,NULL
  %endif
.End:
    ret
