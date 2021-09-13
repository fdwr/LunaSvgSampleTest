; Blank Screen
; Dwayne Robinson
; 2001-09-05
;
; Simply blanks screen to save power and monitor life. Similar to but better
; than the Blank screensaver that comes with Windows, because rather than
; simply clearing the screen black, it actually disables the video card
; refresh. In other words, its even blacker than black.
;
; Curiousity: Also slightly reduces my television static while active.

    bits 16
    org 100h

    ;mov ax,13h
    ;int 10h

    mov ah,1                   ;set cursor type
    mov ecx,2000h              ;turn off cursor
    int 10h

    ; Blank screen
    mov ax,1201h
    mov bl,36h
    int 10h                     ;Video BIOS: Disable refresh

    ; Keep blank & low power mode until user presses key

%if 1 ;suspend code until interrupt & wait until key buffer tail ptr changes

    xor ax,ax
    mov ds,ax
    mov ax,[041Ch]              ;get initial tail ptr
WaitMore:
    hlt                         ;do nothing until interrupt
    cmp [041Ch],ax
    je WaitMore

    xor ax,ax
    int 16h                     ;Keyboard BIOS: Waste keypress

%elif 0 ;disable interrupts and wait for keypress by reading port directly

    cli
WaitMore:
    ;hlt
    in al,60h
    cmp al,1
    jne WaitMore
    sti

%elif 0 ;simply wait for keypress, no interrupt disable or lower power mode
    xor ax,ax
    int 16h                     ;Keyboard BIOS: Wait for keypress

%endif

    ;mov ax,3h
    ;int 10h

    ; Restore screen
    mov ax,1200h
    mov bl,36h
    int 10h                     ;Video BIOS: Enable refresh

    ; Restore cursor
    mov ah,1                    ;set cursor type
    mov ecx,0D0Eh               ;turn on cursor for VGA mode
    int 10h

    ; that's all!
    mov ax,4C00h
    int 21h                     ;DOS: Terminate program
