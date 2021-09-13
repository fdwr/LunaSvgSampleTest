;1999.12.29  Dwayne Robinson
;nasmw -f bin timetest.asm -o timetest.com

bits 16
org 100h

    ;added 2000.4.5
    TimerRate   equ 1193182/40

    ;Save current timer handler and set new one
    mov [DataSegment],ds
    push ds
    lds di,[TimerIntAdr]
    cli
    mov ax,[di]
    mov bx,[di+2]
    mov word [di],TimerIntHandler
    mov [di+2],cs
    sti
    pop ds
    mov [PreviousHandler],ax
    mov [PreviousHandler+2],bx

    ;Do nothing while waiting for key to be pressed
    mov dx,Text.NormalTime
    call KeyPressWait

    ;Speed up timer
    mov cx,TimerRate
    call SetTimerRate
    mov dx,Text.FasterTime
    call KeyPressWait

    ;Restore timer rate
    xor cx,cx
    call SetTimerRate

    ;Restore previous handler
    mov ax,[PreviousHandler]
    mov bx,[PreviousHandler+2]
    push ds
    lds di,[TimerIntAdr]
    cli
    mov [di],ax
    mov [di+2],bx
    sti
    pop ds

    ;End
    mov ax,4C00h
    int 21h

TimerIntHandler:
    push ds
    push es
    push ax
    push bx
    push cx
    push di

    mov ds,[cs:DataSegment]
    les di,[ScreenAdr]
    mov ax,[TickCount]
    call WriteNum
    inc ax
    mov [TickCount],ax

    mov ax,'/'
    stosw

    push ds
    xor bx,bx
    mov ds,bx                   ;BIOS segment (0)
    mov ax,[46Ch]
    pop ds
    call WriteNum

    add word [InterruptAccum],TimerRate
    pop di
    pop cx
    pop bx
    jc .Chain
    mov al,20h
    out 20h,al
    pop ax
    pop es
    pop ds
    iret
.Chain:
    pop ax
    pop es
    pop ds
    jmp far [cs:PreviousHandler]

;(ax=number, di=character cell, es=screen segment)
WriteNum:
    mov cx,4
.NextDigit:
    rol ax,4
    mov bx,ax
    and bx,15
    mov bl,[NumberTable+bx]
    mov [es:di],bl
    add di,byte 2
    loop .NextDigit
    ret

SetTimerRate:
    cli
    mov al,00110100b    ;(00:11:010:0) set counter 0, lsb/msb, mode 2, binary
    out 43h,al
    in al,61h           ;i/o delay
    mov al,cl
    out 40h,al          ;write counter low byte
    in al,61h           ;i/o delay
    mov al,ch
    out 40h,al          ;write counter high byte
    sti
    ret

KeyPressWait:
;(dx=message ptr)
    ;Do nothing while waiting for key to be pressed
    mov ah,9
    ;mov dx,Text...
    int 21h
    xor ax,ax
    int 16h
    ret

section .data
align 4
PreviousHandler:    dw 0,0FFFFh
TimerIntAdr:        dw 32,0
ScreenAdr:          dw 0,0B800h
TickCount:          dw 0
DataSegment:        dw 0
InterruptAccum:     dw 0
NumberTable:        db "0123456789ABCDEF"
section .text


;--------------------
SecondTimeTest:
    mov bx,5        ;number of seconds

SecondWait:
    mov cx,0h
    in al,61h
    and al,10h       ;mask bit 4
    mov ah,al
.CheckAgain:
    in al,61h
    and al,10h
    cmp al,ah
    jz .CheckAgain   ;no change then loop back
    mov ah,al
    dec cx
    jnz .CheckAgain
    dec bx
    jnz SecondWait

    mov ax,4C00h
    int 21h

section .data
Text:
.NormalTime:    db "Timer is running at normal speed (18.2Hz)",13,10,36
.FasterTime:    db "Timer rate has been increased (40Hz)",13,10,36
section .text
