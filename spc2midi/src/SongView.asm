;Spc2Midi - Various display formats to view the notes
; 1999-06-10 / 2002-09-05
;
; SpcView.Init
; SpcView.NoteSheetHorz
; SpcView.VolumeBars
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

SongView:

section bss
alignb 4
; Offscreen pixel buffer which the display routine has full reign to draw in
; The 32k buffer is then later copied to the screen.
.Vars:
.Height         equ 128         ;buffer height in pixels (MUST be >=128)
.Width          equ 512         ;(MUST be power of two)
.WidthShl       equ 9
.BytesPerPixel  equ 2
.ByteStride     equ .Width * .BytesPerPixel
.Buffer_size equ .Height * .ByteStride + 4 ;h * w * 16bpp + 4 bytes for safety
.Buffer:        resb .Buffer_size

.DataCount      equ 16
.DataByteSize   equ .Width*16
.Data:          resd .DataByteSize
.Vols:          resb 128
.PreVols:       resb 128
.Colors:        resb 128
.PreColors:     resb 128
.Pitches:       resb 8
.Row:
.Col:           resd 1          ;current row or column for sliding visuals
;todo:delete .RedrawRange:   resd .Height*2  ; table to keep track of redrawn rows, span left to right
.Vars_size      equ $-.Vars

section data
align 4,db 0
.Handler:       dd .NoteSheetHorz

section code
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Init:
    mov edi,.Buffer
    mov ecx,.Vars_size/4
    cld
    xor eax,eax
    rep stosd
    ret

.InitNada:
    mov dword [.Handler],.DoNada
.DoNada:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; No visual.
; () (none)
; prefill roll sheet with future notes
.InitNone:
    mov dword [.Handler],.None
    ;or dword [GuiFlags],GuiFlags.Suspended
.None:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Horizontal Note Sheet rolls Left to right.
; () (none)
; prefill roll sheet with future notes
.InitNoteSheetHorz:
    mov dword [.Handler],.NoteSheetHorz
    call .Init
    mov edx,[PlayTime]
    push dword .Width
.InshNext:
    push edx
    call .NoteSheetHorzGiven
    pop edx
    add edx,[PlaySpeed]
    cmp [PlayLoopFinish],edx
    ja .InshNoLoop
    mov edx,[PlayLoopStart]
.InshNoLoop:
    dec dword [esp]
    jg .InshNext
    pop eax                     ;discard counter
    ret

; () (none)
.NoteSheetHorz:
    mov edx,[PlayTime]
.NoteSheetHorzGiven:
    push dword [MainSongPos.Time]
    mov edi,MainSongPos
    call SeekSongPos
    call SeekSongPos.SetAllKeys
    pop edx

    ; edx=previous time
    mov ax,(0xD<<10)|(0xD<<5)|(0xF<<0);16+15+15
    add edx,TicksPerFrame+1
    cmp [PlayLoopFinish],edx
    adc ax,0

; clear column at play position (al=color)
    mov edx,[.Col]
    mov ecx,.Height/2           ;plot pixel every other (even rows only)
    mov ebx,edx
    inc edx                     ;col = (col + 1) and (width - 1)
    and edx,.Width-1            ;width-1 makes mask (must be multiple of 2)
    lea edi,[.Buffer+ebx*.BytesPerPixel]
    mov [.Col],edx
.NshNextBar:
    mov [edi],word 0
    mov [edi+.ByteStride],ax
    add edi,.ByteStride*2
    dec ecx
    jnz .NshNextBar

; draw dashed song position bar immediately ahead of play
    mov ecx,.Height/2
    lea edi,[.Buffer+edx+.Width]
.NshNextHightlight:
    mov byte [edi],4
    add edi,.Width*2
    dec ecx
    jnz .NshNextHightlight

; draw colored note bars
    mov esi,[MainSongPos.Active]
    mov ecx,7
    lea edi,[.Buffer+ebx]
    and esi,[EnabledVoices]
    jmp short .NshFirstVoice

.NshNextVoice:
    btr esi,ecx
    mov edx,5                   ;initial decay
    bt dword [MainSongPos.Kon],ecx ;keyed on now?
    jc .NshSetDecay
    mov dl,[.Vols+ecx]          ;get note decay
    test dl,dl
    jle .NshNoMoreDecay
    dec dl                      ;decay--
.NshSetDecay:
    mov [.Vols+ecx],dl          ;set new note decay
.NshNoMoreDecay:
    movzx ebx,byte [MainSongPos.Pitch+ecx] ;get note value
    xor ebx,.Height-1           ;reverse vertically so that notes are not upside-down
    shl ebx,.WidthShl           ;*width of buffer
    mov al,[RainbowColorTable+ecx] ;color formula = { voice * 15 + 14 }
    add al,dl                   ;add voice's note decay to get rainbow shade
    add al,9                    ;make shade brighter
    mov [edi+ebx],al            ;set pixel
.NshFirstVoice:
    bsf ecx,esi
    jnz .NshNextVoice

%if 0
; display thin 'keyboard' blocks at bottom

; turn off old keys
    movzx edi,byte [MainSongPos.Tof]
    mov ecx,7                   ;start with last voice
    xor eax,eax
.NshkNextKof:
    movzx edx,byte [.Pitches+ecx] ;get previous pitch
    bt edi,ecx
    jc .NshkKof
    bt dword [MainSongPos.Active],ecx
    jnc .NshkSkipKof
    cmp [MainSongPos.Pitch+ecx],dl ;check if key changed
    je .NshkSkipKof
.NshkKof:
    shl edx,2                   ;col*4
    mov [.Buffer+((.Height-3)*.Width)+edx],eax
    mov [.Buffer+((.Height-2)*.Width)+edx],eax
    mov [.Buffer+((.Height-1)*.Width)+edx],eax
    ;bts dword [SongViewChanges],edx
.NshkSkipKof:
    dec ecx
    jns .NshkNextKof

; display new/changed keys
    movzx edi,byte [MainSongPos.Ton]
    mov ecx,7                   ;start with last voice
.NshkNextKon:
    bt edi,ecx
    jnc .NshkSkipKon
    mov al,[.Vols+ecx]          ;get note decay
    movzx edx,byte [MainSongPos.Pitch+ecx]
    cmp [.Pitches+ecx],dl       ;check if key changed
    jne .NshkKonChange
    cmp [.PreVols+ecx],al       ;compare with previous note decay
    je .NshkSkipKon
.NshkKonChange:
    mov [.PreVols+ecx],al       ;set note decay
    add al,9
    mov [.Pitches+ecx],dl
    add al,[RainbowColorTable+ecx] ;color formula = { voice * 15 + 14 }
    shl edx,2                   ;col*4
    mov ah,al
    mov [.Buffer+((.Height-3)*.Width)+edx],eax
    mov [.Buffer+((.Height-2)*.Width)+edx],eax
    mov [.Buffer+((.Height-1)*.Width)+edx],eax
    ;bts dword [SongViewChanges],edx

.NshkSkipKon:
    dec ecx
    jns .NshkNextKon
%endif

    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; () (none)
.InitVolumeBars:
    mov dword [.Handler],.VolumeBars
    jmp .Init

; () (none)
.VolumeBars:
    mov edx,[PlayTime]
    mov edi,MainSongPos
    call SeekSongPos
    call SeekSongPos.SetAllKeys

; Decrement volume of all columns
    mov ecx,127                         ;start from last column
.VbNextDec:
    mov al,[.PreVols+ecx]               ;get previous column height
    and al,11111000b                    ;round to multiple of 8
    ;test al,al
    jz .VbBase
    sub al,8                            ;decay pixels
.VbBase:
    mov [.Vols+ecx],al                  ;set new height
    dec ecx
    jns .VbNextDec

; Add volumes of any active voices
    mov ecx,7                           ;start with last voice
    mov edi,[MainSongPos.Active]
    or edi,[MainSongPos.Kof]
    and edi,[EnabledVoices]
.VbNextKon:
.VbKon:
    bt edi,ecx
    jnc .VbSkipVoice

    mov bl,[RainbowColorTable+ecx]      ;color formula = voice * 15 + 14
    movzx edx,byte [.Pitches+ecx]
    add bl,9                            ;color+9
    mov [.Colors+edx],bl
    bt dword [MainSongPos.Kof],ecx
    jc .VbKof

    movzx edx,byte [MainSongPos.Pitch+ecx]
    add bl,5                            ;Key on so color+5
    mov eax,[MainSongPos.Volume+ecx*4]
    shr eax,1+8                         ;volume/2 (/256 because shifted up)
    bt dword [MainSongPos.Kon],ecx
    jnc .VbNoKon
    add eax,byte 4                      ;spike initial attack
.VbNoKon:
    cmp eax,.Height
    jb .VbKonVolOk
    mov al,.Height-1
.VbKonVolOk:
    mov [.Vols+edx],al
    mov [.Pitches+ecx],dl
.VbKof:
    mov [.Colors+edx],bl

.VbSkipVoice:
    dec ecx
    jns .VbNextKon

; Redraw columns
    xor ecx,ecx                         ;ensure top 24bits always zero
    mov edx,127                         ;start from last column

.VbNextCol:
    ;xor ecx,ecx

    ; if color changed, erase column
    mov al,[.Colors+edx]                ;get color
    cmp [.PreColors+edx],al             ;compare with previous color
    je .VbColorSame
    mov [.PreColors+edx],al             ;set previous color
    ;bts dword [SongViewChanges],edi    ;flag column as changed
    mov [.PreVols+edx],byte 0           ;zero previous column
    xor esi,esi                         ;black
    lea edi,[.Buffer+edx*(.Width/128)]
    mov ecx,.Height
.VbNextClrRow:
    mov [edi],esi
    add edi,.Width                      ;+=width  (row++)
    dec ecx
    jg .VbNextClrRow
.VbColorSame:

    ; if column height changed, redraw difference
    mov cl,[.Vols+edx]          ;get new column height
    mov ebx,ecx                 ;copy volume
    sub cl,[.PreVols+edx]       ;get height difference
    mov [.PreVols+edx],bl       ;set previous to new
    je .VbSameVol
    ;mov al,[.Colors+edx];get voice color
    jnc .VbVolGreater
    sub bl,cl                   ;previous column - dif
    xor al,al                   ;erase column
    neg cl                      ;negative to positive
.VbVolGreater:
    not ebx                     ;invert vertical (top=bottom)
    shl ebx,.WidthShl
    and ebx,127<<.WidthShl
    ;bts dword [SongViewChanges],edi ;flag column as changed
    lea edi,[.Buffer+ebx+edx*(.Width/128)]
    mov ah,al                   ;make color word
    push ax
    shl eax,16
    pop ax

.VbNextVolRow:
    mov [edi],eax
    add edi,.Width              ;+=Width  (row++)
    dec ecx
    jg .VbNextVolRow
.VbSameVol:
    dec edx
    jns .VbNextCol
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; horizontal sweep, one wave point per column
; () (none)
.InitDaWaveClear:
    mov dword [.Handler],.DaWaveClear
    jmp .Init

; () (none)
.DaWaveClear:
    mov ebx,[.Col]
    xor eax,eax
    mov ecx,[Sound.MixSamples]
    mov esi,MixBuffer+1         ; +1 to access top byte
    cmp ecx,.Width
    jb .DawNotWider
    mov ecx,.Width
.DawNotWider:
.DawNextPoint:
    mov al,[.Data+ebx]
    mov edi,eax
    shl edi,.WidthShl           ;row
    add edi,ebx                 ;+=col
    mov [.Buffer+edi*.BytesPerPixel],word 0

    mov al,[esi]                ;get top byte of wave sample
    xor al,128                  ;reverse vertically, so not upside down
    shr al,1
    mov [.Data+ebx],al          ;store row for next time
    mov edi,eax
    shl edi,.WidthShl           ;row
    add edi,ebx                 ;+=col
    mov [.Buffer+edi*.BytesPerPixel],word (0*15)+16+14

    inc ebx
    add esi,byte 4
    cmp ebx,.Width
    jb .DawNoWrap
    xor ebx,ebx
.DawNoWrap:
    dec ecx
    jg .DawNextPoint

    mov [.Col],ebx
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; horizontal sweep, top/bottom colors meet in ocean
; () (none)
.InitDaWaveOcean:
    mov dword [.Handler],.DaWaveOcean
    jmp .Init

; () (none)
.DaWaveOcean:
    mov ebx,[.Col]
    mov ecx,[Sound.MixSamples]
    mov esi,MixBuffer+1         ; +1 to access top byte
    cmp ecx,.Width
    jb .Dw2NotWider
    mov ecx,.Width
.Dw2NotWider:
.Dw2NextPoint:

    movzx edx,byte [esi]        ;get top byte of wave sample
    xor edx,128                 ;reverse vertically, so not upside down
    shr edx,1
    push edx
    lea edi,[.Buffer+ebx*.BytesPerPixel]

    test edx,edx
    jz .Dw2NoTop
    mov eax,0
    push ebx
.Dw2NextTop:
	mov ebx,eax
	shr ebx,2
    mov [edi],bx
    inc eax
    add edi,.ByteStride
    dec edx
    jg .Dw2NextTop
    pop ebx
.Dw2NoTop:
    pop edx

    xor edx,127
    mov eax,0
    lea edi,[.Buffer + ebx*.BytesPerPixel + ((.Height-1)*.ByteStride)]
    push ebx
.Dw2NextBtm:
    cmp edi,.Buffer+.Buffer_size
    jb .okok
    int3;
    .okok:
	mov ebx,eax
	shr ebx,2
	and ebx,31<<5
    mov [edi],bx
    add eax,byte 1<<5
    sub edi,.ByteStride
    dec edx
    jge .Dw2NextBtm
    pop ebx

    inc ebx
    add esi,byte 4
    cmp ebx,.Width
    jb .Dw2NoWrap
    xor ebx,ebx
.Dw2NoWrap:
    dec ecx
    jg .Dw2NextPoint

    mov [.Col],ebx
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; horizontal sweep, one wave point per column, multiple fading
; () (none)
.InitDaWaveFaded:
    mov dword [.Handler],.DaWaveFaded
    jmp .Init

; () (none)
.DaWaveFaded:
    mov ebx,[.Col]
    mov ecx,[Sound.MixSamples]
    mov esi,MixBuffer+1         ; +1 to access top byte
    xor eax,eax
    cmp ecx,.Width
    jb .Dw3NotWider
    mov ecx,.Width
.Dw3NotWider:
.Dw3NextPoint:

    ; Fade all pixels in current line
    lea edi,[.Buffer+ebx*.BytesPerPixel]
    mov edx,.Height
.Dw3NextFade:
    mov ax,[edi]
    test eax,eax
    jz .Dw3NoFade
    dec eax
    and eax,30                  ;blue only
    mov word [edi],ax
.Dw3NoFade:
    add edi,.ByteStride
    dec edx
    jg .Dw3NextFade

    ; Draw the new waveform
    mov al,[esi]                ;get top byte of wave sample
    xor eax,128                 ;reverse vertically, so not upside down
    shr eax,1
    mov edi,eax
    shl edi,.WidthShl           ;row
    add edi,ebx                 ;+=col
    mov word [.Buffer+edi*.BytesPerPixel],31+(31<<5)  ;(0*15)+16+14

    inc ebx
    add esi,byte 4
    cmp ebx,.Width
    jb .Dw3NoWrap
    xor ebx,ebx
.Dw3NoWrap:
    dec ecx
    jg .Dw3NextPoint

    mov [.Col],ebx
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; show correlation between wave and itself at different strides
; () (none)
.InitSignalCorrelationMap:
    mov dword [.Handler],.SignalCorrelationMap
    jmp .Init

; () (none)
.SignalCorrelationMap:
    mov edi,.Buffer
    mov ecx,[Sound.MixSamples]
    xor edx,edx                 ; row
    cmp ecx,.Width
    jb .ScmNotWider
    mov ecx,.Width
.ScmNotWider:

.ScmNextRow:
    xor ebx,ebx                 ; column
.ScmNextCol:
    lea esi,[MixBuffer+ebx*4]
    mov eax,[esi]
    sub eax,[esi+edx*4]
    shl eax,2
    js .ScmNegative
    cmp eax,65535
    jb .ScmPositiveWithinRange
    mov eax,65535
.ScmPositiveWithinRange:
    shr eax,16-5-0
    and eax,31<<0
    jmp near .ScmDrawPixel
.ScmNegative:
    neg eax
    cmp eax,65535
    jb .ScmNegativeWithinRange
    mov eax,65535
.ScmNegativeWithinRange:
    shr eax,16-5-10
    and eax,31<<10
.ScmDrawPixel:
    push ebx
    mov ebx,[esi]
    imul ebx,[esi+edx*4]
    test ebx,ebx
    jns .ScmPositiveMultiply
    neg ebx
.ScmPositiveMultiply:
    shr ebx,16+6
    cmp ebx,31
    jb .ScmMultiplyInRange
    mov ebx,31
.ScmMultiplyInRange:
    shl ebx,4
    and ebx,31<<5
    or eax,ebx
    pop ebx

    mov [edi+ebx*.BytesPerPixel],ax
    inc ebx
    cmp ebx,ecx
    jb .ScmNextCol
    add edi,.ByteStride
    inc edx
    cmp edx,.Height
    jb .ScmNextRow
	
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; show correlation between wave and itself at different strides
; () (none)
.InitSignalCorrelationBars:
    mov dword [.Handler],.SignalCorrelationBars
    jmp .Init

; () (none)
.SignalCorrelationBars:
    mov edi,.Buffer
    mov edx,[Sound.MixSamples]
    cmp edx,.Width
    jb .ScbNotWider
    mov edx,.Width
.ScbNotWider:
    xor ebx,ebx                 ; column
.ScbNextCol:

    ; Sum up the differences at this frequency stride
    xor edi,edi                 ; total sum
    xor ecx,ecx                 ; buffer offset
.ScbNextSample:
    lea esi,[MixBuffer+ecx*4]
    mov eax,[esi]
    sub eax,[esi+ebx*4]
    jns .ScbPositive
    neg eax
.ScbPositive:
    add edi,eax
    inc ecx
    cmp ecx,edx
    jb .ScbNextSample
    mov esi,edi
    shr esi,16                  ; a reasonable scale down
    mov eax,esi
    neg esi
    add esi,.Height

    ; Draw the bar as long as the total was
    lea edi,[.Buffer+ebx*.BytesPerPixel]
    xor ecx,ecx

    ; Determine the color
    shr eax,2
    cmp eax,31
    jb .ScbColorOkay
    mov eax,31
.ScbColorOkay:
    shl eax,5
    or eax,(3<<10)|(10<<0)
.ScbNextRow:
    cmp ecx,esi
    jle .ScbDrawPixelBlack
    mov [edi],eax
    jmp near .ScbDrewPixel
.ScbDrawPixelBlack:
    mov [edi],dword 0
.ScbDrewPixel:
    add edi,.ByteStride
    inc ecx
    cmp ecx,.Height
    jb .ScbNextRow

    inc ebx
    cmp ebx,edx
    jb .ScbNextCol

    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; show correlation between wave and itself at different strides
; () (none)
.InitSignalCorrelationHistogram:
    mov dword [.Handler],.SignalCorrelationHistogram
    jmp .Init

; () (none)
.SignalCorrelationHistogram:
    cld

    mov edi,.Buffer
    mov edx,[Sound.MixSamples]
    cmp edx,.Width
    jb .SchNotWider
    mov edx,.Width
.SchNotWider:
    xor ebx,ebx                 ; row
.SchNextRow:

    ; Each row is a different frequency stride
    ; Draw downward from the top
    ; It uses two data slots, for positive and negative differences.

    ; Clear the histogram buckets
    push edi

    xor eax,eax
    mov edi,.Data
    mov ecx,.Width * 2
    rep stosd

    ; Sum up the differences at this frequency stride
    xor ecx,ecx                 ; buffer offset
.SchCountNextSample:
    lea esi,[MixBuffer+ecx*4]
    mov eax,[esi]
    mov edi,.Data               ; assume first row for positive values
    sub eax,[esi+ebx*4]
    jns .SchPositive
    neg eax
    add edi,.Width*4            ; .Data + .Width*4, second row of data for negative values
.SchPositive:
    shr eax,6                   ; scale down the difference
    cmp eax,.Width
    jb .SchSampleClamped
    mov eax,.Width-1
.SchSampleClamped:
    inc dword [edi+eax*4]
    inc ecx
    cmp ecx,edx
    jb .SchCountNextSample

    pop edi

    ; Draw the histogram values
    xor ecx,ecx                 ; buffer offset
.SchDrawNextCount:
    mov eax,[.Data + .Width*4*0 + ecx*4]
    mov esi,[.Data + .Width*4*1 + ecx*4]
    shl eax,1
    shl esi,1
    cmp eax,31
    jb .SchPositiveCountClamped
    mov eax,31
.SchPositiveCountClamped:
    cmp esi,31
    jb .SchNegativeCountClamped
    mov esi,31
.SchNegativeCountClamped:
    shl esi,10                  ; make blue
    or eax,esi
    mov [edi+ecx*.BytesPerPixel],ax
    inc ecx
    cmp ecx,.Width
    jb .SchDrawNextCount

    add edi,.ByteStride

    inc ebx
    cmp ebx,.Height
    jb .SchNextRow

    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; () (none)

section data
.ViString:  db "...# .....p -... ...l ...r .....@ .....@ .....x .....x "
            times GlobalSample.NameSize db 32
.ViStrLen   equ $-.ViString
section code

.InitVoiceInfo:
    mov dword [.Handler],.VoiceInfo
    jmp .Init
    ;mov eax,'    '
    ;mov edi,.Data
    ;mov ecx,(.ViStrLen+3)/4
    ;rep stosd
    ;ret

; () (none)
.VoiceInfo:
    ; clear background behind numbers
    xor eax,eax                 ; black
    mov ecx,.Buffer_size/4
    mov edi,.Buffer
    cld
    rep stosd

    mov edx,[PlayTime]
    mov edi,MainSongPos
    call SeekSongPos
    call SeekSongPos.SetAllKeys

    call SaveDisplayVars
    xor ecx,ecx
    mov dword [Display.Ptr],.Buffer
    mov dword [Display.Width],.Width
    mov byte [NumToString.FillChar],' '

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    push dword MainSongPos.DspRegs  ;starting DSP register voice 0
.ViNext:
    push ecx                        ;save current voice

    ; set color based on whether voice on/off
    mov dl,[RainbowColorTable+ecx]  ;color formula = { voice * 15 + 14 }
    add dl,2
    bt [MainSongPos.Active],ecx
    jnc .ViKof
    add dl,2
    bt [EnabledVoices],ecx
    jnc .ViKof
    add dl,2                        ;voice on so make brighter
.ViKof:
    mov dh,dl
    add edx,0507h
    mov [Font.Colors],edx

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%if 0
    ; clear background behind numbers
    shl ecx,FontDefHshift+.WidthShl
    xor eax,eax
    mov ebx,FontDefHeight
    lea edi,[.Buffer+ecx]
    cld
.ViClearNext:
    mov ecx,((.ViStrLen*(FontDefAvgWidth+FontDefSep))+3)/4
    rep stosd
    add edi,.Width-(((.ViStrLen*(FontDefAvgWidth+FontDefSep))+3) & -4)
    dec ebx
    jg .ViClearNext
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; form numeric string
    mov esi,[esp+4]
    mov edi,.ViString+0
    mov ecx,3
    movzx eax,byte [esi+DspReg.SourceNumber]
    call NumToString.UseDLen

    mov esi,[esp+4]
    mov edi,.ViString+5
    mov ecx,5
    movzx eax,word [esi+DspReg.PitchLow]
    call NumToString.UseDLen

    mov esi,[esp+4]
    mov edi,.ViString+12
    movzx edx,word [esi+DspReg.SampleLow]
    movzx eax,word [esi+DspReg.PitchLow]
    mov ecx,4
    imul eax,[GlobalSample.Freq+edx*4]
    shr eax,11                  ;>>(12-1)
    cmp eax,MaxHertz*2          ;> highest MIDI note's frequency (G10)
    jbe .ViPitchOk
    mov eax,MaxHertz*2
    mov ebx,127                 ;limit to highest MIDI note
    jmp short .ViPitchSet
.ViPitchOk:
    movzx ebx,byte [HertzNoteTbl+eax]
.ViPitchSet:
    shr eax,1
    sub ax,[HertzTbl+ebx*2]
    pushf
    jns .ViPitchPos
    neg ax                      ;make positive
.ViPitchPos:
     call NumToString.UseDLen
    popf
    mov al,'+'
    jns .ViPitchPos2
    mov al,'-'
.ViPitchPos2:
    mov byte [esi-1],al

    mov esi,[esp+4]
    mov edi,.ViString+17
    mov ecx,3
    movzx eax,byte [esi+DspReg.VolLeft]
    call NumToString.UseDLen

    mov esi,[esp+4]
    mov edi,.ViString+22
    mov ecx,3
    movzx eax,byte [esi+DspReg.VolRight]
    call NumToString.UseDLen

    mov esi,[esp+4]
    mov edi,.ViString+27
    movzx edx,word [esi+DspReg.SampleLow]
    mov ecx,5
    mov eax,[GlobalSample.Offset+edx*4]
    push eax
    and eax,65535
     call NumToString.UseDLen   ;sample start offset, lower word only
    pop eax

    mov esi,[esp+4]
    mov edi,.ViString+34
    mov ecx,5
    shr eax,16
    call NumToString.UseDLen   ;sample loop offset, higher word only

    mov esi,[esp+4]
    mov edi,.ViString+41
    movzx edx,word [esi+DspReg.SampleLow]
    mov ecx,5
    mov eax,[GlobalSample.Length+edx*4]
    push dword [GlobalSample.LoopLen+edx*4]
    call NumToString.UseDLen   ;sample length
    pop eax
    mov edi,.ViString+48
    mov ecx,5
    call NumToString.UseDLen   ;sample loop length

    cld
    mov esi,[esp+4]
    movzx esi,word [esi+DspReg.SampleLow]
    mov edi,.ViString+55
    shl esi,GlobalSample.NameShl
    add esi,GlobalSample.Name
    mov edx,GlobalSample.NameSize
    movzx ecx,byte [esi]
    sub edx,ecx
    inc esi
    rep movsb                   ;copy name
    mov al,' '
    mov ecx,edx
    rep stosb                   ;blank remaining trailer with space

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; draw string into offscreen buffer
    mov ecx,[esp]
    push dword .ViStrLen        ;string length
    push dword .ViString        ;chars ptr
    shl ecx,FontDefHshift
    push dword ecx              ;top row|left col
    call BlitString
    add esp,byte 12

    pop ecx
    inc ecx                     ;next voice
    add dword [esp],byte 16     ;next DSP register set
    cmp ecx,8
    jb near .ViNext
    pop eax                     ;discard DSP reg ptr

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    call RestoreDisplayVars
    ret

%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Vertical Note Sheet
;
; Top to bottom.
.Vns:
    ;call .NsReadBuffer
    cld
    mov ebx,[SongView.Pos]
    ;bts dword [SongViewChanges],ebx
    mov edx,ebx
    shl ebx,8                   ;*256
    inc edx                     ;row = (row + 1) and 127
    lea edi,[SongViewBuffer+ebx]
    and edx,127
    mov ecx,256/4
    mov [SongView.Pos],edx
    mov eax,00080008h           ;gray/black/gray/black
    rep stosd

    mov ecx,7
.VnsNextVoice:
    mov ebx,[SongViewTable+ecx*4];get voice's note
    test ebx,ebx                ;test if null
    jz .VnsSkipVoice
    mov eax,ecx
    shl eax,1
    add eax,byte 32
    mov ah,al
    mov [edi-256 +ebx*2-2],ax
.VnsSkipVoice:
    dec ecx
    jns .VnsNextVoice
    ret
%endif


%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.SampleSheet:
    mov edx,[PlayTime]
    mov edi,MainSongPos
    call SeekSongPos
    call SeekSongPos.SetAllKeys

; turn off all voices (gray pixels)
    mov ecx,7
.SsNextKof:
    mov ebx,[.Data+ecx*4]
    test ebx,ebx
    jz .SsNoTof
    mov dword [.Buffer+ebx],GuiClrGray|(GuiClrGray<<8)|(GuiClrGray<<16)|(GuiClrGray<<24)
    mov dword [.Data+ecx*4],0
.SsNoTof:
    dec ecx
    jns .SsNextKof

; turn on all voices (color pixels)
    mov ecx,7
    xor esi,esi
.SsNextKon:
    bt dword [MainSongPos.Active],ecx
    jnc .SsNoTon

    mov bl,[MainSongPos.DspRegs+esi+DspReg.SourceNumber]  ;get sample number
    mov al,[RainbowColorTable+ecx]  ;color formula = voice * 15 + 14
    ;mov al,5
    bt dword [EnabledVoices],ecx
    jnc .SsNoKon
    add al,14
.SsNoKon:

    and ebx,.Height-1
    shl ebx,7
    mov ah,al
    or bl,[MainSongPos.Pitch+ecx]
    mov edx,eax
    shl eax,16
    shl ebx,2
    mov ax,dx

    mov [.Buffer+ebx],eax
    mov [.Data+ecx*4],ebx
.SsNoTon:
    add esi,byte 16             ;next voice in dsp regs
    dec ecx
    jns .SsNextKon

    ret
%endif


%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Temporary function until the GUI is completed.
SongViewCopy:
.Complete:
    cld
    mov ebx,128
    mov esi,SongViewBuffer
    mov edi,Screen.Buffer
.NextPixelRow:
    mov ecx,256/4
    rep movsd
    add edi,byte 64
    dec ebx
    jnz .NextPixelRow
    ret

.PartialV:
    cld
    push dword 128
    mov ebx,SongViewBuffer
    mov edx,Screen.Buffer
.NextRow:
    xor ecx,ecx
.NextStrip:
    mov eax,[SongViewChanges+ecx]
    mov esi,ebx
    mov edi,edx
.Next:
    test eax,15
    jz .SkipBlit
    movsd
    shr eax,4
    jnz .Next
    jmp short .AfterStripBlit
.SkipBlit:
    add esi,byte 4
    add edi,byte 4
    shr eax,4
    jnz .Next
.AfterStripBlit:
    add ebx,byte 32
    add edx,byte 32
    add ecx,byte 4
    cmp ecx,32
    jb .NextStrip
    add edx,byte 64
;    cmp edi,0B0000h
;    jb .ok
;    int3;
;.ok:
    dec dword [esp]
    jnz .NextRow
    pop ecx

;Reset change flags
    cld
    xor eax,eax
    ;mov ecx,SongViewChanges.SizeOf/4
    mov ecx,256/4
    mov edi,SongViewChanges
    rep stosd
    ret
%endif

%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Temporary function until the GUI is completed.
; This does not belong in here.

ShowMutedVoices:
    mov edi,Screen.Buffer+(129*320)
    xor ecx,ecx
    mov ebx,10101010h
.NextChannel:
    bt dword [MutedVoices],ecx
    mov eax,ebx
    jnc .MutedChannel
    add eax,0E0E0E0Eh
.MutedChannel:
    mov [edi],eax
    mov [edi+320],eax
    shr eax,8
    mov [edi+4],eax
    mov [edi+324],eax

    inc ecx
    add edi,byte 8
    add ebx,1E1E1E1Eh
    cmp ecx,8
    jb .NextChannel
    ret
%endif
