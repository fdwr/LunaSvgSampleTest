; Spc2Midi - Random file of debugging snippets
;
; **** This file is deletable ****

section code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Ignore this debugging mess below...
PrintDebugInfo:
    pusha
    mov eax,[PlayTime]
    ;mov eax,[.Value1]
    ;mov eax,[WaveSongPos.Time]
    ;mov eax,[MainSongPos.Pos]
    ;mov eax,[Sound.MixedSamples]
    ;mov eax,[SoundDebug.DmaPos]
    ;mov eax,[DspBufferMinRes]
    ;mov ebx,64000
    ;xor edx,edx
    ;div ebx
    ;mov eax,[CatchAllIrqs.IntCount4]
    ;mov eax,[SineSongPos.Time]
    ;mov eax,[.Value1]
    mov edi,.CounterText
    mov ecx,9
    call NumToString.UseDLen
    ;mov ecx,32
    ;mov edi,.CounterText
    ;call MakeHexNum

    movzx eax,byte [SpcRam+SpcReg.Timer0]
    ;mov eax,[SpcEmu.TotalTime]
    ;mov eax,[WaveSongPos.Time]
    ;and eax,0FFh
    ;xor edx,edx
    ;mov ebx,64000
    ;div ebx
    ;mov eax,[Sound.UsedFmPatches]
    ;mov eax,[Sound.DmaSamples]
    ;mov eax,[Sound.BufferPos]
    ;mov eax,[PlayTime]
    ;mov eax,[SoundDebug.Counter2]
    ;movsx eax,byte [WaveSongPos.DspRegs+DspReg.VolLeft+(16*7)]
    ;movzx eax,word [WaveSongPos.DspRegs+DspReg.PitchLow+(16*3)]
    ;movzx eax,word [DspRam+DspReg.PitchLow+(16*0)]
    ;mov eax,[CatchAllIrqs.IntCount5]
    ;mov eax,[.Value2]
    mov edi,.CounterText+(10*1)
    ;mov ecx,32
    ;call MakeHexNum
    mov ecx,9
    call NumToString.UseDLen

    movzx eax,byte [SpcRam+SpcReg.Timer1]
    ;movzx eax,byte [DspRam+DspReg.SourceDirectory]
    ;and eax,0FFh
    ;xor edx,edx
    ;mov ebx,64000
    ;div ebx
    ;mov eax,[SoundDebug.DifSamples]
    ;mov eax,[SoundDebug.SampleInc]
    ;mov eax,[SoundDebug.Lag]
    ;mov eax,[WaveSongPos.Time]
    ;movzx eax,byte [WaveSongPos.DspRegs+DspReg.SourceNumber+(16*7)]
    ;movsx eax,byte [WaveSongPos.DspRegs+DspReg.VolRight+(16*7)]
    ;mov eax,[SpcEmu.TotalTime]
    ;mov eax,[CatchAllIrqs.IntCount6]
    ;mov eax,[.Value3]
    mov edi,.CounterText+(10*2)
    ;mov ecx,32
    ;call MakeHexNum
    mov ecx,9
    call NumToString.UseDLen

    movzx eax,byte [SpcRam+SpcReg.Timer2]
    ;mov eax,[DspBufferEnd]
    ;and eax,0FFh
    ;mov eax,[SoundDebug.Counter]
    ;mov eax,[SampleEmu.PlayRate]
    ;mov eax,[CatchAllIrqs.IntCount7]
    ;mov eax,[.Value4]
    mov edi,.CounterText+(10*3)
    ;mov ecx,32
    ;call MakeHexNum
    mov ecx,9
    call NumToString.UseDLen

%ifdef UseConsoleDebug
    mov edx,.CounterText
    call WriteString
%else
    debugwrite .CounterText
%endif
    popa
    ret

section data
.CounterText:   db "123456789 123456789 123456789 123456789"
                %ifdef UseConsoleDebug
                db 13
                %endif
                db 0
.Value1:        dd 0
.Value2:        dd 0
.Value3:        dd 0
.Value4:        dd 0
section code


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

%ifdef DosVer
%macro CatchIrq 1
    ; get old interrupt handler
    mov ax,0204h                ;get protected-mode interrupt
    %if CurIrq >= 8
        mov bl,%1+8             ;interrupt number
    %else
        mov bl,%1+70h           ;interrupt number
    %endif
    int 31h
    mov [.OldHandler%1],edx     ;save offset
    mov [.OldHandler%1+4],cx    ;save selector

    ; set new interrupt handler
    mov edx,.IrqCounter%1
    mov ax,0205h                ;set protected mode interrupt
    mov cx,cs                   ;pass our code selector
    int 31h
%endmacro

%macro ReleaseIrq 1
    ; restore old interrupt handler
    %if CurIrq >= 8
        mov bl,%1+8             ;interrupt number
    %else
        mov bl,%1+70h           ;interrupt number
    %endif
    mov ax,0205h                ;set protected mode interrupt
    mov cx,[.OldHandler%1+4]    ;get selector
    mov edx,[.OldHandler%1]     ;get offset
    int 31h
%endmacro

%macro DefIrqCounter 1
.IrqCounter%1:
  %if 0
    push eax
    mov al,20h
    out 20h,al
    pop eax
    iret
  %else
    pushf
    push ds
    mov ds,[cs:Program.DataSelector]
    ;inc dword [.IntCount%1]
    inc dword [0B8000h+%1*160]
    pop ds
    popf
    jmp far [cs:.OldHandler%1]
  %endif

section bss
alignb 4                                                
.OldHandler%1:  resd 1
                resd 1
section data
.IntCount%1:    dd 0
section code
%endmacro

CatchAllIrqs:
    pusha
  %assign CurIrq 0
  %rep 16
    CatchIrq CurIrq
    %assign CurIrq CurIrq+1
  %endrep
    popa
    ret

.Release:
    pusha
  %assign CurIrq 0
  %rep 16
    ReleaseIrq CurIrq
    %assign CurIrq CurIrq+1
  %endrep
    popa
    ret

  %assign CurIrq 0
  %rep 16
    DefIrqCounter CurIrq
    %assign CurIrq CurIrq+1
  %endrep
%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
ShowDaWave:

; horizontal sweep, one wave point per column
.1:
    mov edi,[.SamplePtr]
    xor eax,eax
    mov ecx,[Sound.MixSamples]
    mov esi,MixBuffer+1
    cmp ecx,320
    jb .NotWider
    mov ecx,320
.NotWider:
.NextPoint:
    mov al,[.SampleHeights+edi]
    mov ebx,eax
    mov edx,eax
    shl ebx,6
    shl edx,8
    add ebx,edx
    mov [0A0000h+(36*320)+edi+ebx],byte 0

    mov al,[esi]
    xor al,128
    shr al,1
    mov [.SampleHeights+edi],al
    mov ebx,eax
    mov edx,eax
    shl ebx,6
    shl edx,8
    add ebx,edx
    mov [0A0000h+(36*320)+edi+ebx],byte 15

    inc edi
    add esi,byte 4
    cmp edi,320
    jb .NoWrap
    xor edi,edi
.NoWrap:
    dec ecx
    jg .NextPoint

    mov [.SamplePtr],edi
    ret

; horizontal sweep, multiple wave points per column
.2:
    mov edi,[.SamplePtr]
    xor eax,eax
    mov esi,MixBuffer+1
    lea ebx,[0A0000h+edi]
    mov ecx,200
.NextBlack:
    mov [ebx],byte 0
    add ebx,320
    dec ecx
    jg .NextBlack
    mov ecx,[Sound.MixSamples]
.NextPoint2:
    mov al,[esi]
    xor al,128
    shr al,1
    mov ebx,eax
    mov edx,eax
    shl ebx,6
    shl edx,8
    add ebx,edx
    mov [0A0000h+(36*320)+edi+ebx],byte 15

    add esi,byte 4
    dec ecx
    jg .NextPoint2

    inc edi
    cmp edi,320
    jb .NoWrap2
    xor edi,edi
.NoWrap2:
    mov [.SamplePtr],edi
    ret

.3:
; horizontal sweep, one wave point per column
    mov edx,[Sound.MixSamples]
    mov edi,[.SamplePtr]
    mov esi,MixBuffer+1
    cmp edx,320
    jb .NotWider3
    mov edx,320
.NotWider3:

.NextPoint3:
    ;mov ebx,edi
    xor ebx,ebx
    mov al,[esi]
    mov ecx,200
    mov ah,al

    ; draw one column of sample comparisons
    push edi
.NextSmpCmp:
    dec ebx
    jns .NoSmpWrap
    mov ebx,319
.NoSmpWrap:
    sub al,[.SampleHeights+ebx] ;sample value - previous sample
    sar al,1
    ;rcr al,1
    xor al,128                  ;make gray centerpoint
    mov [0A0000h+edi],al
    mov al,ah                   ;restore sample value
    add edi,320                 ;row down
    dec ecx
    jg .NextSmpCmp
    pop edi

    mov [.SampleHeights+edi],al

    inc edi
    add esi,byte 4
    cmp edi,320
    jb .NoWrap3
    xor edi,edi
.NoWrap3:
    dec edx
    jg .NextPoint3

    mov [.SamplePtr],edi
    ret


section data
align 4
.SampleHeights: times 320 db 0
.SamplePtr:     dd 0
section code

