;Grab Mode 13h Screen to Bitmap
;2000.8.9
;2001.3.6

bits 16
org 100h

%define ProgVersion "3.4"
GraphicsModes   equ 2

SECTION .text

StartProg:
;uncomment this line to debug the write image routine
    ;push cs
    ;pop es
    ;call ReadPalette
    ;call WriteImage
    ;jmp ProgEnd.Dead

;get height/width of screen from parameters
    mov si,81h
.NextChar:
    lodsb
    cmp al,32
    je .NextChar
    cmp al,13
    je .Info
    cmp al,'a'
    jb .Info
    cmp al,'a'+GraphicsModes
    jb .SetMode
.Info:
    mov dx,Text.ProgInfo
    jmp ProgEnd.WithMessage
.SetMode:
    mov bl,al
    xor bh,bh
    shl bx,2                    ;index into table *4
    add bx,VideoModeTable-('a'*4)
    mov dx,[bx]                 ;get height
    mov cx,[bx+2]               ;get width

;get/save keyboard interrupt
;(cx=width, dx=height)
    xor di,di
    mov ds,di                   ;set data segment to zero
    mov ax,[4*9]                ;get offset
    mov bx,[4*9+2]              ;get current keyboard interrupt segment
    push cs
    pop ds
    mov [PreviousKeyHandler],ax     ;save previous handler offset
    mov [PreviousKeyHandler+2],bx   ;save previous segment

;check if already loaded
;(ax=offset, bx=segment, cx=width, dx=height)
    cmp ax,CheckKeyPress        ;make sure it is not already loaded
    jne .NotAlreadyLoaded
    cld
    mov si,StartProg
    mov es,bx
    mov di,si
    mov cx,CodeLength/2
    repe cmpsw
    jne .NotAlreadyLoaded
    ;current key handler has been verified as an already loaded ScrnShot
    ;Set height and width of already loaded instance
    mov [es:Bitmap.Height],dx
    mov [es:Bitmap.Width],cx
    mov dx,Text.AlreadyLoaded
    jmp ProgEnd.WithMessage

.NotAlreadyLoaded:
;(cx=width, dx=height)
    mov [Bitmap.Height],dx
    mov [Bitmap.Width],cx

;steal keyboard interrupt
    ;mov ax,2509h
    ;mov dx,CheckKeyPress
    ;int 21h
    push cs
    cli
    xor di,di
    mov ds,di                       ;access zero segment again
    mov word [9*4],CheckKeyPress    ;set offset
    mov [9*4+2],cs                  ;set to code segment we're in
    sti
    pop ds                          ;restore data segment!

;get ptr to DOS safe-to-call flag
    mov ax,3400h
    int 21h
    mov [DosSafeToCall+2],es
    mov [DosSafeToCall],bx


ProgEnd:
.Resident:
;return to caller but remain resident
;   mov ax,3100h
;   xor dx,dx
;   int 21h
	mov ah,9
    mov dx,Text.ProgStarted
	int 21h
    mov dx,EndOfProgram
    int 27h

.WithMessage:
	mov ah,9
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
    je .GrabScreen
    pop ax
    ;else simply chain the request onto the previous handler
    jmp far [cs:PreviousKeyHandler] ;pass key onto BIOS

.GrabScreen:
    push ds
    push es
    push bp
    push bx
    push cx
    push dx
    push si
    push di
    mov ax,cs
    mov ds,ax
    mov es,ax

    call ReadPalette
    call WriteImage

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    pop es
    pop ds

    ;return to active program
    mov al,20h
    out 20h,al              ;acknowledge interrupt
    pop ax
    iret

ReadPalette:
    mov dx,3C7h             ;VGA color read register
    xor al,al               ;start with color zero
    out dx,al               ;set register
    mov dx,3C9h             ;VGA color data register

    mov di,PaletteData      ;set destination
    mov cx,256              ;total colors = 256 (8 bits)
    xor ax,ax
.NextColor:
    in al,dx                ;get red
    shl al,2                ;*4
    mov [di+2],ax           ;set red byte, and byte immediately above to 0
    in al,dx                ;get green
    mov ah,al
    in al,dx                ;get blue
    shl ax,2                ;*4
    mov [di],ax             ;don't ask me why Windows stores the RGB backwards
    add di,byte 4
    loop .NextColor
    ret


WriteImage:
    lds bx,[DosSafeToCall]
    test byte [bx],0            ;test INDOS flag
    jnz .DosUnsafe
    test byte [bx-1],0          ;test critical error handler flag
    jz .DosSafe
.DosUnsafe:
    ;push cs
    ;pop ds
    ret
.DosSafe:
    push cs
    pop ds

.OpenFile:                      ;Open output file
    mov ax,3C00h|2|64           ;create output file
    xor cx,cx                   ;no attributes to set
    mov dx,File.DefaultName
    ;int 21h
    ;jnc .FileOpened
    ret
.FileOpened:
    mov [File.Handle],ax        ;save file handle
    mov bx,ax                   ;copy file handle

;write bitmap dimensions
    mov ax,[Bitmap.Height]
    imul word [Bitmap.Width]    ;height * width
    mov [Bitmap.ImageSize],ax   ;set image size in bytes
    mov [Bitmap.ImageSize+2],dx
    add ax,54+1024              ;add header size (plus three to round up to nearest whole dword)
    adc dx,0
    mov [Bitmap.DwordFileSize],ax   ;set total file size
    mov [Bitmap.DwordFileSize+2],dx ;set total file size

    mov ah,40h                  ;DOS: write file
    mov dx,Bitmap.Header        ;set file data offset to bitmap header
    mov cx,54                   ;bitmap header size
    ;int 21h
    ;jc .CloseFile
.FileWriteOk:
 
;write palette to file
;(bx=file handle)
    mov ah,40h                  ;DOS: write file
    ;mov bx,[File.Handle]        ;get file handle
    mov dx,PaletteData
    mov cx,1024
    ;int 21h

;write screen to file
;(bx=file handle)
    push cs
    mov di,[Bitmap.Height]      ;get number of rows
    mov cx,[Bitmap.Width]       ;get bytes to write per row
    lds dx,[Bitmap.Source]      ;set source to video memory (dx=zero offset)
    add dx,[cs:Bitmap.ImageSize];start from bottom of screen
.NextRow:
    mov ax,4000h            ;function to write to file
    sub dx,cx               ;move one line up
    ;int 21h                 ;call DOS
    dec di
    jnz .NextRow
    pop ds

;Close output file
.CloseFile:
;(bx=file handle)
    mov ah,3Eh
    ;mov bx,[File.Handle]
    ;int 21h
    ret

align 2
CodeLength  equ $-StartProg


;SECTION .data

align 4
PreviousKeyHandler:     db '8-)',0

Bitmap:
.Source:		dw 0,0A000h
.Header:
	db 'BM'
.DwordFileSize:
    dd 1078+64000               ;entire file size
    dd 0                        ;reserved
    dd 1078                     ;byte offset to bitmap data

    dd 40                       ;size of header (windows/os2)
.Width:
    dd 320                      ;pixel width
.Height:
    dd 200                      ;pixel height
    dw 1                        ;pixel planes
    dw 8                        ;bits per pixel (always 256 color for this program)
    dd 0                        ;compression (none)
.ImageSize:
    dd 320*200                  ;byte size of image (height*width*pixelbytes)
    dd 0,0                      ;pixels per meter, X and Y
    dd 0                        ;all 256 colors used
    dd 0                        ;number of important colors, all of them

DosSafeToCall:  dd 0            ;ptr to INDOS flag
VideoMode:      dw 0
VideoModeTable: dw 200,320
                dw 256,256

File:
.Handle:                dw 0
.DefaultName:           db '\scrnshot.bmp',0

Text:
.ProgInfo:              db "<-ScreenShot ",ProgVersion,"->",13,10
                        db 10
                        db "Purpose: TSR that takes snapshots of the current program's screen.",13,10
                        db "Usage:   scrnshot mode",13,10
                        db "Modes:   a = 320x200:256",13,10
                        db "         b = 256x256:256",13,10
                        db "$"
.ProgStarted:           db "<-ScreenShot ",ProgVersion,"->",13,10
                        db 10
                        db "Previous handler saved,",13,10
                        db "Keyboard Interrupt hooked,",13,10
                        db "INDOS flag ptr gotten",13,10
                        db 10
                        db "Use numpad 5 key to save snapshot to '\scrnshot.bmp'"
                        db "$"
.AlreadyLoaded:         db "Already loaded, new mode set..."
                        db "$"


align 4
;BitmapData:            ;times 64000/4 dd "ABCD"
PaletteData:            times 1024/4  dd "RGB "
;Grayscale palette
;    %assign PalWord 0
;    %rep 256
;        dd PalWord
;        %assign PalWord PalWord+10101h
;    %endrep
;EndOfProgram    equ $
EndOfProgram    equ $
