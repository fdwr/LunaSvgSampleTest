; Catch FM
; By Peekin, 2000.1.15

; A simple INT3 interceptor that stores FM port writes in a small buffer.
; This program alone is unable to catch port writes. It requires some hacking
; of the desired music player (whether a MIDI driver or game) with a
; assembly hex-editor. Each "OUT DX,AL" needs to be replaced with "INT3",
; then everytime that the breakpoint is encountered, this program stores the
; write and returns.

; set interrupt 3 breakpoint address
; run desired program
;   upon breakpoint
;     if fm register write
;       set current fm register
;     elif fm port write
;       record data write
;     endif
;     return
;   end int
; (program is done)
; restore interrupt 3 breakpoint address
; display recorded notes
; (piping could be used above to capture to a file)
; play back recorded notes
; end

bits 16
org 100h

FmPort.Reg      equ 228h
FmPort.Data     equ 229h
FmBuffer.Size   equ 32768
MaxPathSize     equ 128
BiosTimer       equ 46Ch

ProgramStart    equ $-128

    mov ah,4Ah
    mov bx,ProgramPars
    ;mov es,cs
    int 21h

CheckParameters:
    mov si,81h
    cld
.NextSpace:
    ; skip any preceding spaces
    lodsb
    cmp al,' '
    je .NextSpace
    mov dx,si
    dec dx
    ; end if no parameter was given
    cmp al,13
    jne .NameGiven
    mov dx,Text.About
    jmp End.WithMsg
.NameGiven:
    mov di,ProgramName
.NextFileChar:
    ; change ending carriage return in null
    stosb
    lodsb
    cmp al,13
    je .EndFileChar
    cmp al,' '
    jne .NextFileChar
.EndFileChar:
    mov [di],byte 0
    sub si,byte 2
    xor ch,ch
    mov cl,[80h]
    add cl,80h
    sub cx,si
    mov [si],cl

    mov ax,CheckPort
    mov bx,cs
    call SetHandler
    mov [Int3Ofs],ax
    mov [Int3Seg],bx

LoadProgram:
    ; (si=ptr to parameters)
    mov ah,9
    mov dx,Text.LoadingPrg
    int 21h

    mov [Stack],sp
    mov ax,4B00h
    mov bx,ParameterBlock
    mov [ParameterBlock+2],si   ;command tail
    mov [ParameterBlock+4],cs   ;command tail
    mov [ParameterBlock+8],cs   ;default unopened FCB
    mov [ParameterBlock+0Ch],cs ;default unopened FCB
    mov dx,ProgramName
    int 21h
    mov bx,cs
    mov ds,bx
    mov ss,bx
    mov sp,[Stack]

    jnc .NoErr
    mov di,Text.LoadErrNum+3
    mov cx,4
    call NumToString
    mov ax,[Int3Ofs]
    mov bx,[Int3Seg]
    call SetHandler
    mov dx,Text.LoadErr
    jmp End.WithMsg
.NoErr:
    mov ax,[Int3Ofs]
    mov bx,[Int3Seg]
    call SetHandler

WriteBuffer:
    xor bx,bx
    jmp short .FirstIdx
.NextIdx:
    mov al,[FmBuffer+bx+1]      ;get FM register
    mov di,Text.FmWrite+1
    mov cx,2
    call NumToString
    mov al,[FmBuffer+bx]        ;get value written to that register
    mov di,Text.FmWrite+4
    mov cx,2
    call NumToString
    mov ah,9
    mov dx,Text.FmWrite
    int 21h
    add bx,byte 4
    test bx,31
    jnz .FirstIdx
    mov ah,9
    mov dx,Text.CrLf
    int 21h
.FirstIdx:
    cmp [FmBuffer.Idx],bx
    ja .NextIdx
    test bx,31
    jz .NoCrLf
    mov ah,9
    mov dx,Text.CrLf
    int 21h
.NoCrLf:

    mov ax,[FmBuffer.Idx]
    mov di,Text.BufferFill+3
    mov cx,4
    call NumToString
    mov ax,[FmPort]
    mov di,Text.FmPort+3
    mov cx,4
    call NumToString
    mov ah,9
    mov dx,Text.PrgInfo
    int 21h

PlayNotes:
    push es
    xor bx,bx                   ;zero buffer ptr
    mov es,bx
    mov word [FmBuffer+2],2     ;set time delay of first event
    mov dx,FmPort.Reg
    mov si,[es:BiosTimer]
    jmp short .First

.Next:
    mov ax,[FmBuffer+bx]
    call WriteFm
    add bx,byte 4
.First:; (bx=0)
    cmp [FmBuffer.Idx],bx
    jbe .Last

    add si,[FmBuffer+bx+2]
.NoKeyPress:
    cmp [es:BiosTimer],si
    jns .Next
    mov ah,1
    int 16h
    jz .NoKeyPress
    xor ah,ah
    int 16h
.Last:
    pop es

    mov bx,0B000h
.NextOff:
    mov ax,bx
    call WriteFm
    inc bh
    cmp bh,0B9h
    jbe .NextOff

End:
    mov ax,4C00h
    int 21h
.WithMsg:
    mov ah,9
    int 21h
    mov ax,4C01h
    int 21h

;CheckPort2:
;    out dx,al
;    add word [cs:FmBuffer.Idx],byte 2
;    iret

CheckPort:
    cmp word [cs:FmBuffer.Idx],FmBuffer.Size
    jae .Ignore
    mov [cs:FmPort],dx
    cmp dx,FmPort.Reg           ;ignore int3 if not fm port
    jb .Ignore
    cmp dx,FmPort.Data
    ja .Ignore

    push ds
    pusha
    push cs
    pop ds
    cmp dx,FmPort.Reg
    jne .RecordData
    mov [FmBuffer.Reg],al
    jmp short .EndRecordData
.RecordData:
    push es
    xor cx,cx
    mov es,cx
    mov bx,[es:BiosTimer]
    mov cx,bx
    xchg bx,[FmBuffer.Tick]
    sub cx,bx
    pop es
    mov bx,[FmBuffer.Idx]
    mov ah,[FmBuffer.Reg]
    ;push es
    ;mov cx,0A000h
    ;mov es,cx
    ;mov [es:bx],ax
    ;pop es
    mov [FmBuffer+bx],ax        ;set reg/value pair
    mov [FmBuffer+bx+2],cx      ;set time difference
    add bx,byte 4
    mov [FmBuffer.Idx],bx
.EndRecordData:
    popa
    pop ds

.Ignore:
    out dx,al
    iret

SetHandler:
    xor cx,cx
    push ds
    mov ds,cx
    cli
    xchg ax,[3*4]
    xchg bx,[3*4+2]
    sti
    pop ds
    ret

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

; (dx=fm port, ah=reg, al=value)
WriteFm:
    xchg al,ah
    out dx,al
    mov cx,6
.RegWait:
    in al,dx
    loop .RegWait
    inc dx                      ;inc to data port
    mov al,ah
    out dx,al
    dec dx
    mov cx,2Ah;36
.DataWait:
    in al,dx
    loop .DataWait
    ret


Text:
.About:     db "Catch Fm 0.0",13,10,10
            db "Usage: CatchFm program.exe [parameters]",13,10,"$"
.LoadErr:   db "Could not load specified program (DOS ERROR:"
.LoadErrNum:db "xxxx)",13,10,"$"
.LoadingPrg:db "Loading program...",13,10,"$"
.PrgInfo:   db "Buffer filled:"
.BufferFill:db "xxxx",13,10
            db "Program last used port:"
.FmPort:    db "xxxx"
.CrLf:      db 13,10,"$"
.FmWrite:   db "xx:xx $"

align 2
Stack:          dw 0
Int3Ofs:        dw 0
Int3Seg:        dw 0
ParameterBlock: dw 0,80h,0,5Ch,0,6Ch,0
FmPort:         dw 0
FmBuffer.Reg:   dw 0    ;last used FM register
FmBuffer.Idx:   dw 0    ;current index in buffer
FmBuffer.Tick:  dw 0    ;last tick time of register write
ProgramName:    times MaxPathSize db 0

align 2
FmBuffer:   times FmBuffer.Size db 0FFh

ProgramPars equ ($-ProgramStart+15+128)>>4
