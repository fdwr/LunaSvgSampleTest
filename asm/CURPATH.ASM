;Clear Screen

bits 16
org 100h

SECTION .text

StartProg:
; check if already loaded by examining keyboard interrupt pointer
    push cs
    xor dx,dx
    mov ds,dx               ;set data segment to zero
    mov ax,[4*9]            ;get offset
    mov bx,[4*9+2]          ;get current keyboard interrupt segment
    cmp ax,CheckKeyPress    ;make sure it is not already loaded
    jne GoResident
    mov ds,bx
    cmp [ResidentID],word 'CL'
    jne GoResident
    cmp [ResidentID+2],word 'RS'
    jne GoResident
    pop ds                  ;restore data segment!

UnloadPrevious:
;(ax=offset of previous program, bx=segment)
    mov ah,9
    mov dx,Text.Unloading
    int 21h

    ; get original key handler
    mov ds,bx
    mov cx,[KeyHandler]
    mov dx,[KeyHandler+2]
    mov word [10],.Return           ;set terminate address in PSP
    mov [12],cs

    ; restore original key handler
    xor ax,ax
    mov ds,ax
    cli
    mov [9*4],cx                ;restore offset
    mov [9*4+2],dx              ;restore code segment
    sti
    jmp short .PrevPsp

    ; terminate previous instance, then terminate current one
.Return:
    mov bx,cs
.PrevPsp:
    mov ah,50h                  ;set current PSP
    int 21h
    mov ax,4C00h                ;terminate
    int 21h

GoResident:
; (dx=0, cs on stack)
    ; steal keyboard interrupt
    cli
    mov ds,dx                   ;access zero segment again
    mov word [9*4],CheckKeyPress ;set offset
    mov [9*4+2],cs              ;set to code segment we're in
    pop ds                      ;restore data segment!
    mov [KeyHandler],ax         ;save previous handler offset
    mov [KeyHandler+2],bx       ;save previous segment
    sti

    ; return to caller but remain resident
    mov ah,9
    mov dx,Text.ProgLoaded
    int 21h
    ;mov ax,3100h/xor dx,dx/int 21h
    mov dx,EndOfProgram
    int 27h

;when key is pressed, check scancode
;if desired scancode then grab pixels and palette

align 16
CheckKeyPress:
    push ax
    in al,60h                       ;read from keyboard port
    cmp al,76                       ;compare scan code with numpad 5
    jne .ContinueToHandler

    ;clear screen
    push ds
    push es
    push si
    push di
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ah,19h                  ;get current drive
    int 21h
    add al,'A'
    mov [CurPath],al
    mov si,CurPath+3
    mov ah,47h                  ;get current path
    xor dx,dx                   ;using current drive
    int 21h
    sub si,byte 3
    cld
    les di,[ScreenDest]
    mov ah,15
.Next:
    lodsb
    test al,al
    stosw
    jnz .Next
    pop di
    pop si
    pop es
    pop ds

    ;return to active program
    mov al,20h
    out 20h,al              ;acknowledge interrupt
    pop ax
    iret
.ContinueToHandler:
    ;else simply chain the request onto the previous handler
    pop ax
    jmp far [cs:KeyHandler] ;chain keypress onto BIOS or whatever else

align 4
ScreenDest:     dw 0,0B800h
KeyHandler:     db '8-)',0
ResidentID:     db 'CLRS'
CurPath:        db "x:\somepath\subfolder\somefile.ext"
                times 128-$+CurPath db 0

Text:
.ProgLoaded:    db 'Program started,',13,10,'Use numpad 5 key to activate.',13,10,'$'
.Unloading:     db 'Unloading previous instance...',13,10,'$'

EndOfProgram    equ $
