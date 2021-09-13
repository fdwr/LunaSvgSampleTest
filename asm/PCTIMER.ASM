;2000.2.20  Dwayne Robinson
;nasmw -f bin xyz.asm -o xyz.com

org 100h
bits 16

    push ds
    lds si,[TimerIntOffset]
    cli
    mov ax,[si]                 ;get offset
    mov bx,[si+2]               ;get segment
    mov [cs:PreviousHandler],ax ;save offset
    mov [cs:PreviousHandler+2],bx;save segment
    mov [si],word IntHandler    ;set offset
    mov [si+2],cs               ;set segment
    sti
    pop ds
    mov dx,EndOfProgram
    int 27h
;    mov ax,4C00h
;    int 21h

IntHandler:
    push ds
    push es
    push si
    push di
    push ax
    push bx
    push dx

    lds si,[cs:TimerIntOffset]
    les di,[cs:ScreenOffset]
    cld
    jmp short .FirstWord

.NextWord:
    add si,2
    mov [es:di],byte ':'
    add di,2
.FirstWord:
    mov dx,[si]
    mov ah,4
.NextChar:
    rol dx,4
    mov bx,dx
    and bx,0Fh
    mov al,[cs:HexTable+bx]
    stosb
    inc di                      ;skip color attribute
    dec ah
    jnz .NextChar
    cmp si,8*4
    jbe .NextWord

    push cs
    pop ds
    mov di,[ScreenDotPtr]
    cmp byte [es:di],4
    jne .DotOverwritten
    mov ax,[PreviousScreenChar]
    mov [es:di],ax
.DotOverwritten:
    add di,2
    cmp di,25*80*2
    jb .DotOnScreen
    xor di,di                   ;reset dot to top/left
.DotOnScreen:
    mov ax,[es:di]
    mov [ScreenDotPtr],di
    mov [PreviousScreenChar],ax
    mov word [es:di],0F04h      ;white on black diamond

    pop dx
    pop bx
    pop ax
    pop di
    pop si
    pop es
    pop ds
    jmp far [cs:PreviousHandler]
    ;iret

;    mov ax,[PreviousHandler]    ;get offset
;    mov bx,[PreviousHandler+2]  ;get segment
;    mov [es:di],ax              ;restore offset
;    mov [es:di+2],bx            ;restore segment

HexTable:           db "0123456789ABCDEF"
ScreenDotPtr:       dw 0
PreviousScreenChar: dw 0
TimerIntOffset:     dw 8*4,0
ScreenOffset:       dw 0,0B800h
PreviousHandler:    dw 0,0

EndOfProgram:
