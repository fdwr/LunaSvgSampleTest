;2000-01-20 - Rainbow Plasma Ocean
;Peekin (Dwayne Robinson)
;2002-01-14
;
;Written to en-trance...

OceanWnd:
.Width  equ 320
.Height equ 200

Screen:
.Width  equ 320
.Height equ 200
.Seg    equ 0A000h

BiosTimer       equ 46Ch

    bits 16
    org 100h

SetScreen:
    ;set screen mode and palette
    mov ax,13h
    int 10h
    cld
    xor al,al
    mov dx,3C8h
    out dx,al
    inc dx
    mov cx,768
    mov si,RainbowPalette
    rep outsb

    %if 0 ;for a while line
    mov al,100
    dec dx
    out dx,al
    inc dx
    mov al,63
    out dx,al
    out dx,al
    out dx,al
    %endif

MainLoop:
    ; fill buffer with enough wave values to satisfy ocean width
    mov [Count],word OceanWnd.Width+159
.NextFill:
    call AdvanceWaves
    dec word [Count]
    jns .NextFill

    cld
    xor ax,ax
    mov cx,OceanTable.Size/2
    mov di,OceanTable
    rep stosw

    ; get timer
    ; do
    ;   do
    ;     simulate oceam
    ;   loop until timer lag-- = 0
    ;   call wave displayer
    ;   wait until timer <> pretimer or keypress
    ; loop until keypress
    ;
    ;call SimulateOcean

    xor bx,bx
    mov es,bx
    mov si,[es:BiosTimer]
    xor cx,cx

.Redraw:
    push si
    shl cx,3
    mov [Count],cx
.Simulate:
    call SimulateOcean
    call AdvanceWaves
    inc word [Count]
    js .Simulate
    call [OceanWnd.DisplayRtn]
    pop si
.NoKey:
    mov ah,1
    int 16h
    jnz .KeyPress
    mov cx,si
    sub cx,[es:BiosTimer]
    je .NoKey
    sub si,cx                   ;add difference to get current time
    cmp cx,-10
    jae .Redraw
    mov cx,-10
    jmp short .Redraw
.KeyPress:

EndProg:
    xor ah,ah                   ;waste leftover keypress
    int 16h
    mov ax,3h                   ;restore video mode to text
    int 10h
    mov ax,4C00h                ;die
    int 21h


AdvanceWaves:
    ; zero wave value
    ; calculate first sine wave
    ; calculate second sine wave (merging values)
    ; ...
    ;
    xor cx,cx                   ;zero wave value
    mov bx,WaveInfo1
    call AdvanceSineWave        ;calculate first wave
    add bx,byte 6               ;next sine wave info block
    call AdvanceSineWave        ;calculate second wave
    add bx,byte 6               ;next sine wave info block
    call AdvanceSineWave        ;calculate third wave
    mov bx,[WaveBuffer.Ptr]
    ;inc word [WaveBuffer]
    mov [WaveBuffer+bx],cx
    add bx,byte 2
    and bx,WaveBuffer.Size-2    ;wrap within circular buffer
    mov [WaveBuffer.Ptr],bx
    ret


%if 0
AdvanceWaves2:
    mov bx,[WaveBuffer.Ptr]
    inc word [WaveBuffer]; !!!
    inc word [WaveBuffer+bx]
    add bx,byte 2
    and bx,WaveBuffer.Size-2    ;wrap within circular buffer
    mov [WaveBuffer.Ptr],bx    
    ret
%endif


; calculates a sine wave value and advances phase
; (bx=wave info ptr, cx=wave value)
; (bx=, cx=new wave value)
AdvanceSineWave:
    mov dx,[bx]                 ;get phase
    mov si,dx
    add dx,[bx+2]               ;advance phase by increment (wavelength) automatically wraps within 64k
    shr si,6                    ;scale 0-65536 to 0-1024
    mov [bx],dx                 ;store phase
    shl si,1                    ;*2, clearing lowest bit
    mov ax,[bx+4]               ;get amplitude
    imul word [SineLut+si]      ;indexes 0-1023 yield -16384 to 16384
    shr ax,14                   ;select highest two bits (discarding lower ones)
    shl dx,2                    ;make space for lower two bits of result
    or ax,dx
    add cx,ax
    ret


; creates illusion of moving wave ocean by adding buffer to itself,
; shifted one to the right each call.
;
; Phase = 0
; do
;   OceanTable(Phase) += (WaveBuffer(BfrPtr + Phase) - WaveBuffer(BfrPtr))
; loop while Phase++ < Width
;
SimulateOcean:
    mov bx,[OceanBuffer.Ptr]

    xor di,di
.Next:
    mov ax,[WaveBuffer+bx]      ;WaveBuffer(BfrPtr)
    lea si,[bx+di+OceanWnd.Width] ;address for Ocean Table
    and si,WaveBuffer.Size-2
    sub ax,[WaveBuffer+si]      ;- WaveBuffer(BfrPtr + Phase)
    add [OceanTable+di],ax      ;OceanTable(Phase) += ...
    add di,byte 2
    cmp di,OceanWnd.Width*2
    jb .Next

    add bx,byte 2
    and bx,WaveBuffer.Size-2
    mov [OceanBuffer.Ptr],bx
    ret


DisplayWaves:
; allow room for other display formats here...

%if 0
.Pc:
    ; convert 16bit ocean values to 8bit for better speed in loop below
    std
    mov si,OceanWnd.Width*2-2+OceanTable
    mov di,OceanWnd.Width-1
.PcConvNext:
    lodsw
    sar ax,13                    ;scale down so waves are not so large
    mov [OceanTable2+di],al
    dec di
    jns .PcConvNext
%endif

.Npc:
    ; draw left to right, top to bottom
    push es
    les di,[OceanWnd.ScreenAdr]

    xor ax,ax
    xor bx,bx
.NpcNextCol:
    shl bx,1
    mov al,[OceanTable+bx+1]
    mov ah,[OceanTable+bx+3]
    ;add al,114
    ;add ah,114
    ;mov al,[WaveBuffer+bx]
    ;mov ah,[WaveBuffer+bx+2]
    shr bx,1    
    mov cx,OceanWnd.Height
    mov di,bx
.NpcNextRow:
    inc al
    inc ah
    mov [es:di],ax
    add di,Screen.Width
    dec cx
    jnz .NpcNextRow
    add bx,byte 2
    cmp bx,OceanWnd.Width
    jb .NpcNextCol              ;next column
    pop es
    ret


align 2
Count:      dw 0
;WaveInfo1:  dw 0,13*15,21
;WaveInfo2:  dw 0,21*15,32
;WaveInfo3:  dw 0,27*15,47
WaveInfo1:  dw 0,397,82
WaveInfo2:  dw 0,286,53
WaveInfo3:  dw 0,546,21
OceanWnd.DisplayRtn:    dw DisplayWaves.Npc
OceanWnd.ScreenAdr:     dw 0,Screen.Seg
WaveBuffer.Ptr:         dw 0
OceanBuffer.Ptr:        dw 0
RainbowPalette:         incbin "clrocean.pal"
SineLut:                incbin "sinetabl.dat"
.Len    equ 1024

;absolute $
section .bss
WaveBuffer: ;large circular buffer to hold simulated waves (16bit)
.Size   equ 2048
.Len    equ 1024
resb    .Size

OceanTable:  ;small buffer to hold ocean wave values (16bit)
.Size   equ OceanWnd.Width*2
resb    .Size

OceanTable2: ;copy of OceanTable (8bit)
.Size   equ OceanWnd.Width
resb    .Size
