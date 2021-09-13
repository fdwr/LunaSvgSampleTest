; Initialize DA/FM
; By Peekin, 2002-08-27
;
; Simply loads a program from the command line, first resetting the sound
; card so that FM can be heard.

bits 16
org 100h

ProgramStart    equ $-128

Main:
    push ds
    pop es                      ;necessary?
    mov si,80h
    xor bx,bx
    mov bl,[si]
    mov [81h+bx],byte 0
.NextSpace:
    inc si
    cmp byte [si],' '
    je .NextSpace
    cmp byte [si],0
    jne .ParamPassed

    mov ah,9
    mov dx,Text.About
    int 21h
    mov ax,4C01h
    int 21h

.ParamPassed:

    mov ah,4Ah                  ;reduce memory so program to load has some
    mov bx,ProgramPars
    ;mov es,cs
    int 21h

    ;mov dx,220h
    ;out dx,al

    mov ah,9
    mov dx,Text.Loading
    int 21h

    mov ax,4B00h
    mov dx,si
    mov bx,ParameterBlock
    ;mov [ParameterBlock+2],si   ;command tail
    mov word [80h],0|(13<<8)
    mov [ParameterBlock+4],cs   ;command tail
    mov [ParameterBlock+8],cs   ;default unopened FCB
    mov [ParameterBlock+0Ch],cs ;default unopened FCB
    int 21h

    mov ah,al
    shr al,4
    and ax,0F0Fh
    add ax,'00'
    mov [Text.Loading],ax
    mov ah,9
    mov dx,Text.Loading
    int 21h

    mov ax,4C00h
    int 21h

ParameterBlock:
    dw 0    ;00 word   when AL=1, segment of env. or zero if using parents env.
            ;   word   when AL=3, segment of load point for overlay
    dd 80h  ;02 dword  when AL=1, pointer to cmd line at PSP 80h
            ;   word   when AL=3, relocation factor for EXE overlay
    dd 5Ch  ;06 dword  pointer to default FCB passed at PSP 5Ch
    dd 6Ch  ;0A   dword  pointer to default FCB passes at PSP 6Ch
    dd 0    ;0E   dword  value of program SS:SP
    dd 0    ;12   dword  value of program CS:IP

Text:
.About:
    db "Initialize Digital Audio/Frequency Modulation - Peekin 2002-08-27",13,10
    db "Resets sound card before loading specified program",13,10
    db "InitDAFM programfilename.exe",13
    db "$"
.Loading:
    db "Loading program$"

ProgramPars equ ($-ProgramStart+15+128)>>4
