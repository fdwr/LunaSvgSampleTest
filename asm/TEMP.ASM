section .text public use32
section .data public use32
section .bss  public use32

section .text
bits 32
global Main
global _WdosxStart

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
Main:
_WdosxStart:

%if 1
    push dword 5
    push word 5
    nop
    push dword word word word 5
    push word dword 5
    nop

%elif 0
Main:
    times 70000 nop
section .data
    times 70000 dd 1234
section .text

%elif 0
    sub ebx,3
    sub ebx,byte 3

%elif 0
    Msg.Activate    equ 255
    Msg.Select      equ 254
    Msg.Create      equ 1
    Msg.Finish      equ 2
    %assign JumpTableLow Msg.Activate-128^-128
    mov eax,JumpTableLow
    %assign JumpTableLow Msg.Select-128^-128
    mov eax,JumpTableLow
    %assign JumpTableLow Msg.Create-128^-128
    mov eax,JumpTableLow
    %assign JumpTableLow Msg.Finish-128^-128
    mov eax,JumpTableLow
%elif 0
.loop:
    hlt
    mov ah,1
    int 16h
    jz .loop
    xor eax,eax
    int 16h
    mov eax,4C00h
    int 21h

    mov ax,168Fh                ;Win32 VM interrupt
    mov dx,0001h                ;enable application close
    int 2Fh

    xor ax,ax
    int 16h

%endif

    mov eax,4C00h
    int 21h
