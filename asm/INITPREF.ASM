; Initialize Preferences
; Dwayne Robinson
; 2001-05-10
; 2003-12-31 Turned off character blink for bright backgrounds
;
; Simply sets keyboard and screen preferences,
; keyboard delay to minimum and repeat to max,
; screen size to 80x50 characters.

    bits 16
    org 100h

    ; (causes freeze when Dvorak keyboard layout loaded)
    ; set keyboard
    ;mov ax,0305h                ;Set typematic rate
    ;xor bx,bx                   ;bl=rate (0=250ms) bh=delay (0=30)
    ;int 16h                     ;Keyboard BIOS

    ; get current screen mode
    mov ah,0Fh                  ;ah=get video mode
    int 10h                     ;Video BIOS
    cmp al,03h
    je AlreadyText

    ; set screen mode to text
    mov ax,0003h                ;ah=set video mode, al=mode 3
    int 10h                     ;Video BIOS

AlreadyText:
    ; set screen row/col to 80x50
    mov ax,1112h                ;ah=set character font, al=8x8
    xor bx,bx                   ;table 0
    int 10h                     ;Video BIOS

    ; disable stupid blinking behaviour
    mov ax,1003h                ;toggle intensity/blinking bit
    xor bx,bx                   ;bl=00h-bright/01h-blink, bh=0 avoid problems
    int 10h                     ;Video BIOS

%if 1
    lds di,[ScreenPtr]
    mov cx,80*50
.NextChar:
    ;mov [di],byte 0Ah           ;bright green on black
    mov [di],byte 8Fh           ;bright white on gray
    add di,byte 2
    loop .NextChar
%endif

    ; that's all!
    mov ax,4C00h
    int 21h                     ;DOS: Terminate program

%if 1
align 2, db 0
ScreenPtr: dw 1,0B800h
%endif
