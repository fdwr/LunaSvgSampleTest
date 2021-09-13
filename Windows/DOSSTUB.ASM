; Custom DOS stub for Windows PEs

;%include "exebinpe.mac"
%include "\src\nasm\exebin.mac"

EXE_begin

section .text
    push cs
    pop ds
    mov ah,09
    mov dx,NoDosMsg
    int 21h
    mov ax,4C00h
    int 21h
NoDosMsg:
    db "This program is the 32bit Windows version.$"

    ; ALINK clips off the last few bytes without some
    ; extra dummy space to compensate for it
    align 8
    times 29 db 0

EXE_end
