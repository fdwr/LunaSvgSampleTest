;sets video mode 3 on keypress

bits 16
org 100h

SECTION .text

StartProg:
;get and save keyboard interrupt
;	mov ax,3509h
;	int 21h
;	mov [PreviousKeyHandler],bx
;	mov [PreviousKeyHandler+2],es
	xor dx,dx
        mov es,dx               ;set data segment to zero
        mov ax,[es:4*9]         ;get offset
        mov bx,[es:4*9+2]       ;get current keyboard interrupt segment
        cmp ax,CheckKeyPress    ;make sure it is not already loaded
        jne .NotAlreadyLoaded
        mov es,bx
        cmp word [es:ResidentID],'Hi'
        jne .NotAlreadyLoadedId
        cmp word [es:ResidentID+2],':)'
        ;jne .NotAlreadyLoadedId
        je ProgEnd.AlreadyLoaded
.NotAlreadyLoadedId:
        mov es,dx               ;set data segment to zero again
.NotAlreadyLoaded:
        mov [PreviousKeyHandler],ax
        mov [PreviousKeyHandler+2],bx

;steal keyboard interrupt
;	mov ax,2509h
;	mov dx,CheckKeyPress
;	int 21h
        cli
        mov word [es:9*4],CheckKeyPress ;set offset
        mov [es:9*4+2],cs               ;set to code segment we're in
        sti

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
        mov word [ResidentID],'By'
        mov word [ResidentID+2],':('
	mov ah,9
        mov dx,Text.AlreadyLoaded
	int 21h
.Dead:
	mov ax,4C00h
	int 21h

;when key is pressed, check scancode
;if desired scancode then attempt to open file
;print out 64000 bytes
align 16
CheckKeyPress:
        push ax
        in al,60h                       ;read from keyboard port
        cmp al,76                       ;compare scan code with numpad 5
        jne .ContinueToHandler
        call ChangeScreen
.ContinueToHandler:
        pop ax
        jmp far [cs:PreviousKeyHandler] ;pass key onto BIOS

ChangeScreen:
        push ds
        push es
        push bp
        push bx
        push cx
        push dx
        push si
        push di

        mov ax,3
        int 10h
        mov ax,1201h
        mov bl,30h
        int 10h

        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop bp
        pop es
        pop ds
        ret

align 4
PreviousKeyHandler:     db '8-)',0
ResidentID:             db 'Hi:)'

Text:
.ProgStarted:           db 'Set screen mode 3 started, use numpad 5 key.$'
.AlreadyLoaded:         db 'Already loaded.$'

EndOfProgram:
