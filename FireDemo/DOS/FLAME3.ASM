; 2000.4.20 Dwayne Robinson

; from flame, 128 byte fire          
; copyright 1997 Gaffer/prometheus     
; gaffer@zip.com.au             
;
; optimization contribution:        
; goblin,icepick,mf,patrik sundberg,pgeist   


ORG 100h

; INITIALIZATION: setup video mode & palette
; ------------------------------------------

FlameWidth      equ 320
ShadeRange      equ 80
ShadeSeparation equ 40
;AddShapes      equ 1

Main:
; GENERATE PALETTE
    cld
    mov di,Buffer
    mov cx,768/4
    xor eax,eax
    rep stosd

    mov di,Buffer
    mov dx,3
PaletteGen:                           ; alternate palette generation
    xor ax,ax                         ; (Patrick Sundberg)
    push di
    mov cl,ShadeRange-1
.L1:
    mov [di],al
    add bx,4194304/ShadeRange
    adc ax,0
    add di,3
    loop .L1
    mov cl,256-ShadeRange+1
.L2:
    mov [di],al
    add di,3
    loop .L2
    pop di
    add di,ShadeSeparation*3+1
    xor bx,bx
    dec dx
    jnz PaletteGen


; INIT VGA MODE 13h
    mov ax,13h
    int 10h


%if 0
; DRAW COLOR BARS
    push ds
    push 0A000h
    pop ds
    xor ax,ax
    xor di,di
.NextPixel:
    mov [di],al
    mov [di+320],al
    mov [di+640],al
    mov [di+960],al
    inc di
    inc al
    jnz .NextPixel
    pop ds
    xor bx,bx
%endif

; SET PALETTE
    ;mov ax,1012h
    ;cwd                               ; equivalent to 'xor dx,dx'
    ;mov cx,255
    ;int 10h
    mov si,Buffer
    xor ax,ax
    mov cx,768
    mov dx,3C8h
    out dx,al
    inc dx
    rep outsb


;Clear buffer and ready for main loop
    mov di,Buffer
    xor bx,bx
    mov cx,320*203/4
    xor eax,eax
    rep stosd
    push word 0A000h            ; SETUP VGA SEGMENT
    pop es


; MAIN LOOP: Cycle through flame animation until keypress
; -------------------------------------------------------
MainLoop:
    mov ax,ds
    push es
    mov es,ax                         ; set es=ds to use stos

; FLAME ANIMATION
    xor dx,dx
    mov cx,FlameWidth
    mov di,Buffer
    mov bl,99
.L3:
    mov ax,[di+639]                   
    add al,ah                         
    setc ah
    mov dl,[di+641]
    add ax,dx
    mov dl,[di+1280]
    add ax,dx
    shr ax,2
    jz .ZERO                         ; cool a bit...
    dec ax
.ZERO:
    stosb
    add ax,dx                         ; double the height
    shr ax,1                          
    mov [di+319],al                   
    loop .L3
    mov cx,FlameWidth           ;default width is 320
%if FlameWidth = 320
    add di,cx
%else
    add di,(320-FlameWidth)+320
%endif
    dec bx
    jnz .L3
    mov cx,320


; FLAME GENERATOR BAR
    ; assumes cx=320
    ; assumes di=generator bar offset (bottom of flame buffer)
.L4:
    ;in ax,40h                         ; read from timer
    ;push ax
    ;add ax,[100h]
    ;pop word [100h]                   ; "seed" is first two bytes of code
    ;mov ah,al
    mov ax,33797
    mul word [100h]
    inc ax
    mov [100h],ax
    and ah,03Fh
    add ah,100;0CFh
    mov al,ah
    stosw
    stosw
    loop .L4

%ifdef AddShapes
    call AddShape
%endif

    pop es                            ; restore es=A000h
; OUTPUT FLAME TO SCREEN
    xor di,di
    mov si,Buffer+320
    mov ch,60                         ; assumes cl=0
    rep movsd
                                      
; CHECK FOR KEYPRESS
    in al,60h
    cmp al,1
    jne MainLoop
    ;mov ah,1
    ;int 16h
    ;jz MainLoop


; DOS EXIT CODE: Switch to textmode, return to DOS
; ------------------------------------------------

    mov ax,03h
    int 10h
    ret                               

%ifdef AddShapes
AddShape:
ZigZag:
    mov di,Buffer+320*100
    mov bx,(320/20)/2
.NextPiece:
    mov cx,20/2
.NextPixelDown:
    add word [di],1010h     ;16
    add word [di+320],1010h
    add word [di+640],1010h
    add word [di+960],1010h
    add di,322
    loop .NextPixelDown
    mov cx,20/2
.NextPixelUp:
    add word [di],1313h     ;19
    add word [di+320],1313h
    add word [di+640],1313h
    add word [di+960],1313h
    sub di,318
    loop .NextPixelUp
    dec bx
    jnz .NextPiece
    ret

HotSpots:
    mov di,Buffer+320*100
    mov cx,320/20
.NextPixel:
    add word [di],30|(30<<8)
    add di,20
    loop .NextPixel
    ret

Triangle:
    mov di,Buffer+320*100
    mov bx,20
.NextLine:
    mov cx,bx
.NextPixel:
    add byte [di],5
    inc di
    loop .NextPixel
    add di,320
    sub di,bx
    dec bx
    jnz .NextLine
    ret
%endif


section .bss
alignb 4
Buffer:     resb 320*203
