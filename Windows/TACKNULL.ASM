;Dwayne Robinson
;2002-03-14
;Simply tacks a zero dword onto the end of a file after discovering that
;Windows 95 needed it in the relocation section.

org 100h

Main:
    xor bx,bx
    mov bl,[80h]
    mov ax,3D01h                ;open for write only
    mov dx,81h
    mov [81h+bx],byte 0         ;put null on end of filename
    cmp [81h],byte ' '
    jne .NoPreSpc
    inc dx
.NoPreSpc:
    int 21h
    mov dx,OpenErr
    jc .ErrMsg

    ; jump to end of file
    mov bx,ax
    xor cx,cx
    mov ax,4202h
    xor dx,dx
    int 21h

    ; write zero dword
    mov ah,40h
    mov cx,4                    ;write four bytes
    mov dx,NullTack
    int 21h

    pushf
    mov ah,3Eh
    int 21h
    popf
    mov dx,WriteErr
    jc .ErrMsg                  ;end if write failed

    mov ax,4C00h                ;end no errors
    int 21h

.ErrMsg:
    mov ah,9                    ;print string
    int 21h
    mov ax,4C01h                ;end with error
    int 21h

NullTack:   dd 0
OpenErr:    db "Could not open file$"
WriteErr:   db "Could not write to file$"
