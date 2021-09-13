; simply displays the command line parameters passed to it

bits 16
org 100h

ProgramStart    equ $-128

    mov ah,4Ah
    mov bx,ProgramPars
    ;mov es,cs
    int 21h

CheckParameters:
    mov si,80h

    xor bx,bx
.NextChar:
    cld
    lodsb
    mov bl,al

    mov cx,2
    mov di,Text.ParamChar+1
    call NumToString
    cmp bl,13
    mov al,bl
    ja .ValidChar
    mov al,'ú'
.ValidChar:
    mov [Text.ParamChar+4],al
    mov ah,9
    mov dx,Text.ParamChar
    int 21h

    cmp bl,13
    jne .NextChar

    mov ax,[2Ch]
    mov cx,4
    mov di,Text.EnvSeg+3
    call NumToString

    ; get size of largest memory block
    mov ah,48h
    mov bx,0FFFFh
    int 21h
    mov ax,bx
    mov cx,4
    mov di,Text.MaxMcb+3
    call NumToString

    mov ah,9
    mov dx,Text.MiscInfo
    int 21h

    mov ax,4C00h
    int 21h

NumToString:
    mov dx,ax
    std
.NextDigit:
    and al,15
    add al,'0'
    cmp al,'9'
    jbe .DigitOk
    add al,'A'-'0'-10
.DigitOk:
    shr dx,4
    stosb
    mov al,dl
    loop .NextDigit
    ret

Text:
.ParamChar: db "xx 'x'",13,10,"$"
.MiscInfo:
            db "Environment segment:"
.EnvSeg:    db "xxxx",13,10
            db "Largest memory block:"
.MaxMcb:    db "xxxx",13,10,"$"

ProgramPars equ ($-ProgramStart+15+128)>>4


%if 0
; Show parameters
; 2001-05-03 / 2002-02-16
;
; Simply echoes the passed parameters to the screen. This simply program was
; written to find what values Windows was passing to Explorer when opening a
; new window.

bits 16
org 100h

    xor cx,cx
    mov dx,81h                  ;ptr to parameters
    mov ah,40h                  ;DOS: Write to file
    mov cl,[80h]                ;get parameters byte length
    mov bx,1                    ;console output handle
	int 21h
    xor ax,ax                   ;wait for keypress
    int 16h
    mov ax,4C00h
    int 21h
%endif
