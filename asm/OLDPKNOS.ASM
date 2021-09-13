; (very unfinished!)
;
; Depending on no operating system (except the BIOS), this program has all the
; necessary code to interect with required PC hardware. However, that by no
; means qualifies it as an operating system, as it provides no memory
; management and no file system. It is simply an example an independant
; program, like any console game or like old Commodore 64 programs.
;
; This is called from the boot sector. No basic setup is necessary, as the
; segment and stack registers have already been set up for it. Additional
; setup will be required though to set video mode and enter protected mode.
;
; Entry conditions:
;   ss:sp   9000:FE00 purposely set up high in memory
;   cs:ip   0000:0700 purposely set up low in memory
;   ds      0
;   es      0
;
;   The stack is set high so that as much data can be loaded in low as
;   possible. Of course, it is very unlikely the two would ever meet. The
;   program would have to be over 540k large, and not even the most bloated
;   OS cores are that large.
;
;   The code and data are loaded low so that they have easy access to the
;   BIOS information area and interrupt table.

SoftReboot      equ 0           ;no

bits 16
org 700h

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
CharLoop:
;
; print greeting message
; do
;   loop until key pressed
;   get keypress
;   print character
;   if escape pressed, goto reboot
;   if extended character
;     bring down scancode in upper byte
;   endif
;   if carriage return pressed
;     print an extra line feed to move cursor down one line
;   endif
; loop

    mov si,Text.Greeting
    call WriteString
.Top:
    mov ah,1                    ;Keyboard BIOS - check keypress
    int 16h
    ;(al=ASCII character)
    jz .Top                     ;no keypresses waiting
    xor ax,ax                   ;Keyboard BIOS - get keypress
    int 16h
    ; (ASCII character is in al)

    cmp al,27                   ;if escape
    je Reboot

    test al,al
    jnz .AsciiChar
    mov al,ah                   ;bring down scancode
.AsciiChar:
    call WriteCharacter
    cmp al,13                   ;if carriage return
    jne .Top
    mov al,10                   ;set character to line feed
    call WriteCharacter.Again
    jmp short .Top

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; There a few ways to reboot a computer. Besides the more obvious reset
; button and Ctrl+Alt+Del keypress, you can also execute the bootstrap loader
; or long jump to the BIOS ROM (as if the PC were reset). Depending on the
; method taken (soft/warm/cold), the BIOS will either do a full test or skip
; a few of them. Executing the bootstrap loader is the gentlest of them all,
; as it does not clear memory, retest RAM, blank the screen, or reset
; hardware. Unfortunately, it isn't always dependable.
Reboot:
%if SoftReboot
    mov dl,80h                  ;drive to boot from
    int 19h                     ;execute bootstrap loader
%else
    xor ax,ax
    mov ds,dx                   ;BIOS data segment
    mov word [0472h],1234h      ;indicate to BIOS to do soft reset
    jmp 0FFFFh:0
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes given character to current cursor position.
; (si=string ptr) (ax=character)
WriteCharacter:
    xor bx,bx                   ;page 0
.Again:
    push ax                     ;save keypress
    mov ah,0Eh                  ;Video BIOS - write character in teletype mode
    int 10h                     ;write character
    pop ax                      ;restore keypress
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (si=string ptr, cx=string length) (; si)
WriteString:
    mov ah,3                    ;Video BIOS Function - get cursor position
    xor bh,bh                   ;page zero
    int 10h
    mov ax,1301h                ;13 = Video BIOS Function - write string
                                ;01 = chars only, move cursor
    mov bx,000Bh                ;page 0, color 11 (turquoise)
    mov cx,[es:si-2]            ;get length of string
    mov bp,si                   ;copy string ptr for BIOS function
%if 0
    ; determine string length
    mov ax,1000h                ;set character to search for (null)
    mov cx,ax
    mov di,si
    rep scasb                   ;scan for null in string
    neg cx
    add cx,ax
%endif

    ;(cx=string length)
    ;(es already set)
    ;(dh=row, dl=column)
    int 10h
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MainLoop:
; enter protected mode
; set timer interval
; grab keyboard int
; grab timer int
; decompress bitmaps
; set video mode
; do
;   render scene
; loop until escape
; reboot

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (anything below this point is not done)

; set up global and local descriptor tables

; don't bother with unnecessary task state for multitasking

EnterProtMode:
    mov eax,cr0
    inc eax                     ;set bit 0 (PE)
    mov cr0,eax
    jmp dword 700h

bits 32

    ;set up interrupt table
    cli

    ;don't bother with io map since all hardware should be accessible

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Text:
            dw .End-.Greeting
.Greeting:  db 13,10,10
            db "System loaded. Type in your commands master...",13,10
            db "(not that they will do very much) ;-)",13,10
            db "Press Escape once bored and ready to reboot",13,10,10
.End:
