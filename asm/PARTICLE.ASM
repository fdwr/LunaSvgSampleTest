;Simple Tile Viewer

BITS 32				;flat addressing is great!
GLOBAL _WDOSXStart		;great (free!) extender

CodeSafety              equ 1

TitleParticle.Rows      equ 30
TitleParticle.Cols      equ 160
TitleParticle.PerRow    equ 20
TitleParticle.TopRow    equ 85
TitleParticle.Distance  equ 10
TitleParticle.Range     equ 1

LoopsBeforeKeyCheck     equ 200

;--------------------------------------------------
SECTION .text
_WDOSXStart:
        push ds
        pop es

        call SetVideoMode.Graphics
        call SetGrayPalette

ParticleLoop:
        ;draw left side
        push dword LeftParticles
        call Particles_Draw
        add esp,byte 4

        push dword RightParticles
        call Particles_Draw
        add esp,byte 4
        ;draw right side
        ;calculate amount to shift based on the timer difference
        ;possibly delay just a little while
        ;move all the particles
        ;check if particles were moved
        ;  decrement size if so
        ;erase blocks
        mov eax,65536
        call GetRandom
        cmp eax,65535
        ja RandomError
        inc byte [0A0000h+eax]
;        call PrintNum
        ;xor edx,edx             ;top row, left column
        ;mov eax,[DumbCount]
        ;call PrintNum2
        inc dword [DumbCount]
        dec byte [KeyCheckCounter]
        jnz ParticleLoop

        mov byte [KeyCheckCounter],LoopsBeforeKeyCheck
        mov ah,1                ;function to check for key presses
        int 16h
        jz ParticleLoop         ;zero flag set, no keys pressed

        xor ah,ah
        int 16h                 ;get rid of keypress

        call SetVideoMode.Text

ProgEnd:
        mov ax,4C00h
        int 21h

RandomError:
        int3
        jmp short ProgEnd

KeyCheckCounter:        db LoopsBeforeKeyCheck

;--------------------------------------------------
Particles_Draw:
.Draw:
.NextRow:
.NextParticle:
        ;Particle.PerRow
        ;jnz .Draw_NextParticle
        ret

.RowCount:      dd 1
.ColCount:      dd 1
.CurParticle:   dd 0

DrawSimpleSolidParticle:
        jmp DrawSimpleSolidParticle

;------------------------------
Particles_Move:
        ret

;------------------------------
; (eax=range) (eax=return value within range)
GetRandom:
        test eax,eax
        jz .End
        push ecx
        push edx
        mov ecx,[.LastValue]
        rol ecx,byte 1
        add ecx,1|2|4|16
;        ror ecx,cl
;        sub ecx,3526137215
        mov [.LastValue],ecx
        xchg eax,ecx
        xor edx,edx
        div ecx
        mov eax,edx
        pop ecx
        pop edx
.End:
        ret

.LastValue:     dd 0
;dd 1234567890
;------------------------------
; Cheap temporary function.
PrintNum:                       ;call here to print at a specific location
;        push eax                ;save number
;        xor ebx,ebx             ;page zero
;        mov ah,2                ;function to set cursor
;        int 10h                 ;call video BIOS
;        pop eax                 ;retrieve number
.AtCsr:                         ;call here to print at cursor location
        mov edi,Text.NumBuffer
        call MakeNumString
        mov edx,Text.NumBuffer
        mov ah,9
        int 21h
        ret

;----------
PrintNum2:
        push edx
        mov edi,Text.NumBuffer
        call MakeNumString
        push dword Text.NumBuffer+5
        call FontStandardCharString
        add esp,byte 8
        ret

;--------------------------------------------------
; GRAPHICS
;--------------------------------------------------
GraphicsDestination:    dd 0A0000h

;------------------------------
SetVideoMode:
.Graphics:
	mov ax,13h
	jmp short .Set
.Text:
	mov ax,3
;	jmp short .Set
.Set:
	int 10h
	ret

;------------------------------
SetGrayPalette:
        xor eax,eax
        mov dx,3C8h
        out dx,al
        inc dl
        xor cl,cl
.NextColor:
        mov al,ah
        shr al,2
        out dx,al
        out dx,al
        out dx,al
        inc ah
        dec cl
        jnz .NextColor
        ret

;------------------------------
; (TopRow, LftCol, FontCharPtr)
; Blits a single colored, transparent character to any 8bit destination.
;
align 16
FontMonochromeChar:
; Initial regs:
; +bl=pixel color
;  bh=character columns
;  bl=character rows
;  ch=row counter
;  cl=column counter
        mov ch,bl
        shr ebx,8
; Regs:
;  bh=character columns
;  bl=pixel color
;  ch=row counter
;  cl=column counter
;  edi=screen destination
;  esi=character bits
;  edx=screen wrap
        cld                     ;set direction forward!
        mov ah,7
.NextRow:
        mov cl,bl
        lodsb
.NextCol:
        shl al,1
        jnc .ClearPixel
        mov [edi],bh
        inc edi
        dec cl
        jnz .NextCol
        jmp short .AfterRowComplete
.ClearPixel:
        mov [edi],ah
        inc edi
        dec cl
        jnz .NextCol
.AfterRowComplete:
        add edi,edx
        dec ch
        jnz .NextRow
.Clipped:
        ret

;------------------------------
; (Source, TopRow, LftCol)
; Blits a sequence of characters by calling the specified routine to blit each character.
;
FontStandardCharString:
        mov esi,[esp+4]
        movzx ebx,word [esp+8]  ;get row
        movzx edx,word [esp+10] ;get column
        mov edi,ebx             ;can only do this if screenwidth is 320 pix
        shl ebx,6
        shl edi,8
        add ebx,edx             ;add column to rowbase
        lea edi,[edi+ebx+0A0000h] ;assuming destination is screen
%ifdef CodeSafety
        cmp edi,0B0000h
        jb .ok
        int3
.ok:
%endif
        xor eax,eax
        jmp short .FirstChar
.NextChar:
        push edi
        push esi
        mov ebx,[.Attributes]
        mov edx,320-8
        lea esi,[0FFA6Eh+eax*8]
        call FontMonochromeChar
        pop esi
        pop edi
        xor eax,eax
        inc esi                 ;next character
        add edi,8
.FirstChar:
        mov al,byte [esi]
        test al,al
        jnz .NextChar
.End:
	ret

align 4
.BlitRoutine:   dd FontMonochromeChar
.Attributes:    dd 8|(8<<8)|(11<<16)    ;character height/width/color

;------------------------------
;
DrawBorder:
        dec word [esp+4]
        dec word [esp+6]
        inc word [esp+8]
        inc word [esp+10]
        mov bx,[esp+4]
        mov dx,[esp+6]
        mov cx,[esp+10]
        inc dx
        mov al,8
        call BlitLineFast.Horizontal
        mov bx,[esp+4]
        mov dx,[esp+6]
        mov cx,[esp+10]
        add bx,[esp+8]
        mov al,15
        call BlitLineFast.Horizontal
        mov bx,[esp+4]
        mov dx,[esp+6]
        mov cx,[esp+8]
        mov al,8
        call BlitLineFast.Vertical
        mov dx,[esp+6]
        mov bx,[esp+4]
        mov cx,[esp+8]
        add dx,[esp+10]
        inc bx
        mov al,15
        call BlitLineFast.Vertical
        ret
;------------------------------
; al=color, bx=row, dx=column, cx=line_length
;
BlitLineFast:
.Horizontal:
        mov ah,al
        and ebx,0FFFFh
        shrd esi,eax,16
        and ecx,0FFFFh
        shld eax,esi,16
        and edx,0FFFFh
;        cmp ebx,Screen.Height
;        jae .End
;        cmp edx,Screen.Width
;        jae .End
;        lea edi,[edx+ecx]
;        cmp
        mov edi,ebx             ;can only do this if screenwidth is 320 pix
        shl ebx,6
        shl edi,8
        add ebx,edx
        cld                     ;set direction forward!
        mov edx,ecx
        lea edi,[edi+ebx+0A0000h] ;assuming destination is screen
        shr ecx,2
        rep stosd
        mov cl,dl
        and cl,3
        rep stosb
        ret
.Vertical:
        and ebx,0FFFFh
        and edx,0FFFFh
        mov edi,ebx             ;can only do this if screenwidth is 320 pix
        and ecx,0FFFFh
        shl ebx,6
        shl edi,8
        add ebx,edx
        lea edi,[edi+ebx+0A0000h] ;assuming destination is screen
        mov edx,320
.NextRow:
        mov [edi],al
        add edi,edx
        dec cl
        jnz .NextRow
.End:
        ret

;------------------------------
; (TopRow, LeftCol, Height, Width, Color)
; What else, it draws a singled colored box.
;
DrawBox:
        xor eax,eax
        mov bx,[esp+10]         ;get width
	mov edx,320		;get screen width
        xor ecx,ecx
	sub dx,bx		;get wrap width
        mov ax,[esp+6]          ;get leftcol

	shl ebx,16		;keep width in safe part of bx
        mov cx,[esp+4]          ;get toprow
        mov bx,[esp+8]          ;get height
	;height is now in lower part and width in higher part of ebx

        mov edi,ecx             ;make a copy
        shl ecx,6               ;multiply by 64
	shl edi,8		;now by 256
        add edi,ecx             ;multiplied by 320
        lea edi,[0A0000h+eax+edi] ;add left column to destination
%ifdef CodeSafety
        cmp edi,0B0000h
        jb .ok
        int3
.ok:
%endif
	mov al,[esp+12]		;get color
.ByReg:                         ;calling by register can be a bit faster
	mov ah,al		;copy color to second byte
        shrd esi,eax,16
        xor ecx,ecx             ;zero out top 17 bits for loop
        shld eax,esi,16
	;eax now consists of four pixels all the same color
	cld			;as always, go forward
.NextLine:
	shld ecx,ebx,14		;get width divided by 4
	rep stosd
	shld ecx,ebx,16		;get width
	and ecx,3		;get modulus 4
	rep stosb
	add edi,edx
	dec bx
	jnz .NextLine
.End
	ret

;--------------------------------------------------
; USER INPUT
;--------------------------------------------------
;------------------------------
; () (cf=keypress, eax=<scan code and ASCII char>or<zero for nothing>)
; Gets a single keypress from BIOS (not stupid DOS).
;
align 16
GetKeyPress:
	mov ah,1		;function to check key buffer status
	int 16h			;call BIOS
	jz .NoneWaiting		;zero flag is set, no keys are in buffer
	mov ah,0		;function to get first key press
	int 16h			;call BIOS
	stc			;set carry flag to indicate keypress
	ret

.NoneWaiting:
	xor eax,eax
	clc
	ret

;--------------------------------------------------
; STRING MANIPULATION
;--------------------------------------------------
;------------------------------
; (eax=value, edi=text destination, ?ecx=max string length, ?ebx=radix)
; Turns a 32bit signed number into a decimal string, writing it to edi.
; Potential problems: It does not check that radix passed to it is valid, so
; passing a negative radix could have unpredictable results, or passing it
; zero could cause a divide overflow. Passing a string length longer than the
; destination really is will cause it to overwrite data. 4294967295 is the
; largest number it can handle.
;
MakeNumString:
        mov ecx,10              ;default maximum of ten characters
.AnyLength:                     ;since the largest 32bit is 4gb
	mov ebx,10		;base of the decimal system
.AnyRadix:                      ;for hexadecimal and binary (even octal)
	xor edx,edx		;set top 32 bits of quotient to zero
        lea edi,[edi+ecx-1]     ;start from rightmost character in number
.NextChar:
	div ebx			;divide number by the decimal base
        add dl,48              ;make remainder into an ASCII character
	mov [edi],dl		;output result
	dec edi			;move backwards one character
	test eax,eax		;see if we are done with the number
	jz .FillInBlanks	;nothing but zeroes left
	xor dl,dl		;set edx to zero again for next division
	dec cl			;one less character to output
	jnz .NextChar
	ret

.FillInBlanks:
        mov al,'0'              ;fill in with spaces
	dec cl			;one less than current count
	std			;move backwards
	rep stosb		;for number of characters remaining
	ret

;--------------------------------------------------
; CONSTANTS, VARIABLES, TEXT MESSAGES, FONTS...
;--------------------------------------------------
SECTION .data
Text:
.ProgTitle:     db 'Particle Ripper Demo$'
.NumBuffer:     db '__________',13,10,'$',0

Particle.Rows           equ 0   ;number of particle strips
Particle.Cols           equ 2   ;visible particle window
Particle.PerRow         equ 4   ;particles per row
Particle.Distance       equ 5   ;average distance between adjacent particles
Particle.Range          equ 6   ;maximum strech a particle has
Particle.ShiftCount     equ 7   ;counter to know when to add new row

LeftParticles:
        dw TitleParticle.Rows
        dw TitleParticle.Cols
        db TitleParticle.PerRow
        db TitleParticle.Distance
        db TitleParticle.Range

RightParticles:
        dw TitleParticle.Rows
        dw TitleParticle.Cols
        db TitleParticle.PerRow
        db TitleParticle.Distance
        db TitleParticle.Range
        db 0

DumbCount:      dd 0

;--------------------------------------------------
; UNITIALIZED VARIABLES (could be set to anything)
;--------------------------------------------------
SECTION .bss

VirtualScreenBuffer:    resb 65536
