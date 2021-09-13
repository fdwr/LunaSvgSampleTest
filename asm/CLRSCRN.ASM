;Clear Screen

bits 16
org 100h

SECTION .text

StartProg:
;get and save keyboard interrupt
;	mov ax,3509h
;	int 21h
;	mov [PreviousKeyHandler],bx
;	mov [PreviousKeyHandler+2],es
        push cs
        xor dx,dx
        mov ds,dx               ;set data segment to zero
        mov ax,[4*9]            ;get offset
        mov bx,[4*9+2]          ;get current keyboard interrupt segment
        cmp ax,CheckKeyPress    ;make sure it is not already loaded
        jne .NotAlreadyLoaded
        mov ds,bx
        cmp [ResidentID],word 'CL'
        jne .NotAlreadyLoaded
        cmp [ResidentID+2],word 'RS'
        jne .NotAlreadyLoaded
        pop ds                  ;restore data segment!
        jmp short ProgEnd.AlreadyLoaded
.NotAlreadyLoaded:
        ;steal keyboard interrupt
        ;mov ax,2509h
        ;mov dx,CheckKeyPress
        ;int 21h
        cli
        mov ds,dx                       ;access zero segment again
        mov word [9*4],CheckKeyPress    ;set offset
        mov [9*4+2],cs                  ;set to code segment we're in
        sti

        pop ds                          ;restore data segment!
        mov [PreviousKeyHandler],ax     ;save previous handler offset
        mov [PreviousKeyHandler+2],bx   ;save previous segment

        mov ah,9
        mov dx,Text.ProgStarted
        int 21h

;return to caller but remain resident
ProgEnd:
.Resident:
;        mov ax,3100h
;        xor dx,dx
;        int 21h
        mov dx,EndOfProgram
        int 27h

.AlreadyLoaded:
        mov ah,9
        mov dx,Text.AlreadyLoaded
        int 21h
.Dead:
        mov ax,4C00h
        int 21h

;when key is pressed, check scancode
;if desired scancode then grab pixels and palette

align 16
CheckKeyPress:
        push ax
        in al,60h                       ;read from keyboard port
        cmp al,76                       ;compare scan code with numpad 5
        jne .ContinueToHandler

        ;clear screen
        push es
        push di
        push cx
        cld
        les di,[cs:ScreenDest]
        mov ax,0F00h
        mov cx,ScreenSize/2
        rep stosw
        pop cx
        pop di
        pop es

        ;return to active program
        mov al,20h
        out 20h,al              ;acknowledge interrupt
        pop ax
        iret
.ContinueToHandler:
        ;else simply chain the request onto the previous handler
        pop ax
        jmp far [cs:PreviousKeyHandler] ;pass key onto BIOS

align 4
PreviousKeyHandler:     db '8-)',0
ResidentID:             db 'CLRS'
;ScreenDest:             dw 0,0A000h     ;0,0B800h
;ScreenSize              equ 320*200     ;25*80*2
ScreenDest:             dw 0,0B800h
ScreenSize              equ 25*80*2

Text:
.ProgStarted:           db 'ClearScreen started, use numpad 5 key to clear contents.$'
.AlreadyLoaded:         db 'Already loaded$'

EndOfProgram    equ $
