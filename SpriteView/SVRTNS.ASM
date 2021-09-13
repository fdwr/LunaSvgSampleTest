; All of the little helper routines...
;
; GetStrLength
; MakeNumString
; SetVideoMode
; ResetScreenClips
; PaletteSet
; PaletteSetGuiColors
; DrawBox
; DrawBorder
; FontBlitChar
; FontBlitCharOpaque
; FontBlitStr
; KeyScanFor
; KeyGetPress
; UserWait

BITS 32

;============================================================
; STRING ROUTINES
;============================================================

;------------------------------
; Gets the length of a null-terminated string
;
; (esi) (eax) - Saves all other regs
GetStrLength:
	PushAll edi,ecx
	mov edi,esi		;copy source for string length search
        mov ecx,8192            ;maximum length of characters
	mov eax,ecx		;make a copy of max length for later
        ;null is set in al by moving 8192 into it, which the lower byte is 0
	cld			;as always, look forward
	repne scasb		;search for the end
	sub eax,ecx		;get length
	dec eax			;minus the null at the end
	PullAll edi,ecx
	ret

;------------------------------
; Turns a 32bit number into a decimal (or other) string, writing it to edi.
;
; (eax=number, edi=destination) () - No regs saved
MakeNumString:
	mov ecx,8		;maximum of eight characters
; (ecx=length)
.OfLength:
	mov ebx,10		;base of the decimal system
; (ebx=radix)
.OfRadix:
	xor edx,edx		;set top 32 bits of quotient to zero
	lea edi,[edi+ecx-1];start from right side of number
.NextChar:
	div ebx			;divide number by the decimal base
	mov dl,[.CharTable+edx]	;turn remainder into an ASCII character
	mov [edi],dl		;output result
	dec edi			;move backwards one character
	test eax,eax		;see if we are done with the number
	jz .FillInBlanks	;nothing but zeroes left
	xor dl,dl		;set edx to zero again for next division
	dec cl			;one less character to output
	jnz .NextChar
	ret

.FillInBlanks:
	mov al,' '		;fill in with spaces
        dec ecx                 ;one less than current count
        mov ebx,ecx             ;save copy of count
	std			;move backwards
	rep stosb		;for number of characters remaining
        mov ecx,ebx             ;return offset of first digit
	ret

.CharTable:	db '0123456789ABCDEF'

;------------------------------
; Turns a string representation of a number into a 32bit unsigned number.
; Ends at a non-numeric digit, including puncuation, extended characters,
; null, and any other control character. Returns zero for a an empty string.
;
; (esi=text source) (eax=value, zf=no number) - No regs saved
MakeStringNum:
        mov ecx,NumStringMaxLen ;default maximum of ten characters
; (ecx=length of string)
.AnyLength:                     ;since the largest 32bit is 4gb
	mov ebx,10              ;base of the decimal system
; (ebx=radix)
.AnyRadix:                      ;for hexadecimal and binary (even octal)
	xor edx,edx             ;set top 32 bits of digit place to zero
        mov edi,ecx             ;copy length
	xor eax,eax             ;set return value to zero
.NextChar:
	mov dl,[esi]            ;get digit
	sub dl,48               ;"0"=48->0  "9"=57->9
	jc .End                 ;character is less than '0'
	cmp dl,10
	jb .AddPlaceValue       ;digit is 0-9
        and dl,~32              ;make uppercase by turning off fifth bit
        cmp dl,'A'-48
	jb .End                 ;character is less than 'A'
        cmp dl,'F'-48
        ja .End                 ;character is greater than 'F' (15)
        sub dl,7                ;(65-48)+10  "A"=65->10  "F"=86->15
.AddPlaceValue:
        imul eax,ebx            ;multiply existing number by radix
	add eax,edx             ;add new digit
	inc esi                 ;move forwards one character
	dec cl                  ;one less character to check
	jnz .NextChar
.End:
        sub edi,ecx             ;set zero flag accordingly
        ;mov ecx,edi
	ret
.Hex:
        mov ecx,NumStringMaxLen ;default maximum of ten characters
        mov ebx,16              ;base of the hexadecimal system
        jmp short .AnyRadix

;============================================================
; SelectorAllocate (esi=base, ecx=limit) (cf=error) - Preserves all regs
;
; Allocate selectors for certain areas of memory
%if 0
SelectorAllocate:
	PushAll edx,ecx,ebx,eax
	xor eax,eax		;DPMI function 0, allocate selector
	mov ecx,1		;only one selector
	int 31h
	jc .ErrorAllocating	;uh-oh
	mov ebx,eax		;returned selector was in eax
	mov edx,[esp]		;get base address
	shld ecx,edx,16		;put upper 16 bits into ecx (cx:dx)
	mov eax,7		;DPMI function 7, set base address
	int 31h
	jc .ErrorSetting	;could not set base
	mov eax,8		;DPMI function 8, set segment limit
	mov edx,[esp+8]		;
	shld ecx,edx,16		;put upper 16 bits into ecx (cx:dx)
	int 31h
	jc .ErrorSetting	;could not set limit
	mov eax,ebx		;move selector into eax
	add esp,byte 4		;throw away old value of eax
	PullAll edx,ecx,ebx	;restore regs
	ret

.ErrorSetting:
	mov eax,1		;DPMI function 1, free selector
	int 31h			;ebx should still contain our selector
.ErrorAllocating:
	PullAll edx,ecx,ebx,eax
	ret
%endif

;============================================================
; VIDEO SETTING AND PALETTE ROUTINES
;============================================================
; These are not done yet

;------------------------------
; SetVideoMode (*) - Preserves all regs
;
; Silly set video mode (not done at all)
; When it supports VBE2, then it will be done :-)
; Hopefully it will be 640x480:15bit, me hopes
SetVideoMode:
	PushAll eax,ebx
	mov ax,13h			;For now 320x200:256 will do
	int 10h				;VGA BIOS function 0, set screen mode
	mov [ScreenPtr],dword 0A0000h	;video memory
	mov ax,[ScreenModesInfo+4]	;get bits per pixel
;	mov [ScreenBits],ax		;set current bits
	mov ax,[ScreenModesInfo]	;get screen mode height
	mov bx,[ScreenModesInfo+2]	;get screen mode width
	mov [ScreenHeight],ax		;set current height
	mov [ScreenWidth],bx		;set current width
	jmp short ResetScreenClips.ByRegs
					;reset clipped regions to maximum screen dimensions

SetExitVideoMode:
	mov ax,3			;boring text mode
	int 10h				;VGA BIOS function 0, set screen mode
	ret

;------------------------------
; ResetScreenClips (*) - Preserves all regs
;
; Resets the screen clippers used by graphics functions to the maximum screen extents
;
ResetScreenClips:
	PushAll eax,ebx
	mov ax,[ScreenHeight]		;screen mode height
	mov bx,[ScreenWidth]		;screen mode width
.ByRegs:				;called only from SetVideoMode
	dec ax				;clip is one less than size
	dec bx
	shl eax,16			;zero out bottom 16 bits
	shl ebx,16
	mov [ScreenClipTop],eax		;set both top and bottom
	mov [ScreenClipLeft],ebx	;set both left and right
	PullAll eax,ebx
	ret

;------------------------------
; PaletteSet (eax=first color, ecx=number of colors) () - Preserves all other regs
;
; Updates the VGA display to show the colors in the main palette
;
PaletteSet:
        PushAll esi,edx
        ;movzx eax,al            ;zero top 24 bits
        xor eax,eax              ;a cheap hack for now
	mov ecx,256
	mov esi,ScreenPalette	;get pointer to palette
	mov dx,3C8h		;palette index port
	out dx,al		;tell VGA adapter the color index to start setting
        ;lea eax,[eax+eax*2]     ;multiply index by three
        ;lea ecx,[ecx+ecx*2]     ;do the same with count
        ;mov dx,3C9h             ;select the VGA color palette port
        inc edx
        ;add esi,eax             ;get starting index in palette
        cld
.Next:
        lodsd
        shr eax,2
        and eax,3F3F3Fh
        out dx,al               ;port accepts color values as red, green, blue
        shr eax,8
        out dx,al
        shr eax,8
        out dx,al
        dec ecx
        jnz .Next
.End:
        PullAll esi,edx
	ret

;------------------------------
; PaletteSetGuiColors (*) - Preserves all regs
;
; Sets the main palette to include the GUI colors
; Does not update the display palette
;
PaletteSetGuiColors:
	PushAll edi,esi,ecx
	mov edi,ScreenPalette	;dest is the palette
	mov esi,GuiColorsData	;source is the color constants
	mov ecx,GuiColorsNum	;number of GUI colors
        cld

.NextColor:
	movsw
	movsb
        add edi,byte 4*16-3     ;jump forward 16 rgb color entries
	dec ecx
	jnz .NextColor

	PullAll edi,esi,ecx
	ret

;------------------------------
; PaletteColormap (*) - No regs preserved
;
; Takes the source palette and remaps the colors to fit into the main palette
; used by GUI or background color constant to the nearest ones in the current palette,
; yielding a colormap
;
;PaletteColormap:
;        ret

;------------------------------
; SaveSnapshot () - No regs preserved
;
%if MyPersonalVersion           ;leave out this code for public release
SaveSnapshot:
        ;open file
	mov edx,.OutputFile     ;set ptr to filename for DOS call
	mov ax,3C00h            ;create new file (or overwrite existing)
	xor ecx,ecx             ;no special file attributes, set to zero
	int 21h                 ;call DOS to open file
        jc near .ErrorOpeningFile ;if error opening snapshot pcx for output
        sub esp,1028
        mov [esp+.SnapshotHandle],eax;save file hdnale

	;print header
	mov ebx,eax             ;copy file handle to ebx for next call
	mov edx,.Header         ;set source data for write
	mov ecx,.Header_Len     ;set bytes to write to length of header
	mov ax,4000h            ;function to write to file
	int 21h                 ;call DOS
        jc near .ErrorWritingToFile  ;just in case :-/

        ;write palette
        mov dx,3C7h             ;VGA color read register
        xor al,al               ;start with color zero
        out dx,al               ;set color index to first (0)
        mov dx,3C9h             ;VGA color data register
        cld
        mov edi,esp             ;set destination
        mov ecx,256             ;total colors
.NextColor:
        xor eax,eax
        in al,dx                ;read in color rgb from VGA data port
        shl eax,8
        in al,dx                ;read in color rgb from VGA data port
        shl eax,8
        in al,dx
        shl eax,2               ;multiply shade by 4
        stosd
        dec ecx
        jnz .NextColor
        mov ecx,1024            ;total colors = 256 * 4 (RGBx)
        mov edx,esp             ;set source data for write
	call .OutputFilePortion

        mov ebx,[esp+.SnapshotHandle];get snapshot file's handle
        mov esi,199*320+0A0000h
        mov edi,200             ;set number of rows
        mov ecx,320             ;set bytes to write per row
.NextRow:
        mov edx,esi             ;set source data for write
	mov ax,4000h            ;function to write to file
	int 21h                 ;call DOS
        sub esi,ecx
        dec edi
        jnz .NextRow

.ErrorWritingToFile:
	mov ax,3E00h            ;function to close file
        mov ebx,[esp+.SnapshotHandle];get snapshot file's handle
	int 21h                 ;call DOS
        add esp,1028
.ErrorOpeningFile:
	ret

.OutputFilePortion:
        mov ebx,[esp+.SnapshotHandle+4];get snapshot file's handle
	mov ax,4000h            ;function to write to file
	int 21h                 ;call DOS
	ret

.SnapshotHandle equ 1024

.OutputFile:
        db 'SnapShot.bmp',0
.Header:
;.PcxHeader
;        db 10,5,1,8     ;Manufacturer, Version, Encoding, Bits per pixel
;        dw 0,0,319,199  ;Top, Left, Width, Height
;        dw 320,200      ;Horizontal & Vertical resolution
;        times 49 db 0   ;Unused EGA palette plus a reserved blank
;        db 1            ;Color planes
;        dw 320,0        ;Bytes per row, Palette type
;        times 58 db 0   ;Blank extra padding
;.BmpHeader:
	db 'BM'
.BmpHeader_DwordFileSize:
	dd (1078+64000)/4	;file size in dwords
	dd 0			;reserved
        dd 1078                 ;byte offset to bitmap data

        dd 40                   ;size of header (Windows bitmap)
.BmpHeader_Width:
        dd 320                  ;width
.BmpHeader_Height:
        dd 200                  ;height
	dw 1			;pixel planes
	dw 8			;bits per pixel
	dd 0			;compression
.BmpHeader_ImageSize:
	dd 320*200		;byte size of image
        dd 0,0                  ;pixels per meter, X and Y
	dd 0			;all 256 colors used
	dd 0			;number of important colors, all of them

;.Header_Len equ 128             ;pcx
.Header_Len equ 54              ;bitmap
%endif

;============================================================
; GRAPHICS ROUTINES
;============================================================

;------------------------------
; DrawPixel (ax=color, di=dest) () - Preserves all regs
;
; Meant to be used by the line drawer (if I make it)
;
;align 16			;extra speed??
;_DrawPixel
;	push edi
;	and edi,0FFFFh		;fit into 64k
;	mov [edi+0A0000h],al	;single pixel written
;	pull edi
;	ret

;------------------------------
; DrawPixelAt (ax=color, ebx=row, ecx=col) () - Preserves all regs
;
; Does not clip (for speeds sake)
;
;align 16			;extra speed??
;_DrawPixelAt
;	PushAll edi,ebx
;	mov edi,ebx		;make a copy
;	shl ebx,6		;multiply by 64
;	shl edi,8		;now by 256
;	add edi,ebx		;multiplied by 320
;	add edi,ecx		;add left column
;	and edi,0FFFFh		;fit into 64k
;	mov [edi+0A0000h],al	;single pixel written
;	PullAll edi,ebx
;	ret

;------------------------------
; FontBlitChar (words Char, TopRow, LeftCol) () - No regs preserved
;
; Draws transparent 2bit (4 color) fonts to the screen
; It only draws 8x8 characters, but it would not be too hard to allow other sizes
; FontStylePtr points to the current font
; Will someday support clipping
;
;	esi=char bitmap in font set
;	edi=screen destination
;	ebx=four color table
;	cl=roll (not used yet)
;	ch=col
;	cl2=row (the upper bits 16-23)
;	ax=masked pixels
;	dx=char bitmap row
;	ebp=wrap width
%if 0
align 16			;extra speed??
_FontBlitChar:
	mov al,[esp+4]		;get character
        movzx edx,word [esp+6]  ;get toprow
        movzx ecx,word [esp+8]  ;get leftcolumn
_FontBlitChar.ByRegs:		;only called if regs are already setup!
	movzx eax,al		;make sure is in range 0-255
	shl eax,4		;multiply by 16 (16 bits per row)
	mov ebx,[FontStylePtr]	;the current font being used
	lea esi,[ebx+eax]	;point character bitmap in set
        ;movzx edx,dx            ;row
        ;movzx ecx,cx            ;left column
	mov edi,edx		;make a copy of row
	shl edx,6		;multiply by 64
	shl edi,8		;multiply by 256
	add edi,edx		;64+256=320
	add edi,ecx		;add left column
	and edi,0FFFFh		;just in case of a bad parameter
;	add edi,[ScreenPtr]
	add edi,0A0000h		;set to video memory
	push ebp		;save base pointer
	mov ebx,[FontColorsPtr]	;for now
	xor eax,eax		;zero out upper bits for loop
	mov ebp, 320-8		;wrap width (for now)
	mov cl,8		;8 rows to do
	cld			;as always, go forward

.NextRow:
	rol ecx,16		;get access to preroll and column counter
	mov ch,8		;8 columns to do
	mov dx,[esi]		;grab first row of char bitmap (16bits)
	add esi,byte 2		;for next row
;	rol edx,cl		;preroll for when off screen
.NextCol:
	mov al,dl		;make a copy
	shr edx,2		;adjust for next pixel
	and al,3		;filter bottom two bits
	jz .SkipCol		;skip to next pixel
	mov al,[ebx+eax*2]	;index into color table
	stosb			;single pixel written
	dec ch
	jnz .NextCol
	jmp short .ToNextRow
.SkipCol:
	inc di
	dec ch
	jnz .NextCol
.ToNextRow:	
	ror ecx,16		;get access to upper part of ecx
	add edi,ebp		;add wrap width to get to next row
	dec cl			;row counter
	jnz .NextRow		;still going

	pop ebp			;restore base pointer
	ret
%endif

;------------------------------
; FontBlitCharOpaque (words Char, TopRow, LeftCol) () - No regs preserved
;
; This is different in only that it does have transparency
;
align 16			;extra speed??
_FontBlitCharOpaque:
	mov al,[esp+4]		;get character
        movzx edx,word [esp+6]  ;get toprow
        movzx ecx,word [esp+8]  ;get leftcolumn
_FontBlitCharOpaque.ByRegs:	;only called if regs are already setup!
	movzx eax,al		;make sure is in range 0-255
	shl eax,4		;multiply by 16 (16 bits per row)
	mov ebx,[FontStylePtr]	;the current font being used
	lea esi,[ebx+eax]	;point character bitmap in set
        ;movzx edx,dx            ;row
        ;movzx ecx,cx            ;left column
	mov edi,edx		;make a copy of row
	shl edx,6		;multiply by 64
	shl edi,8		;multiply by 256
	add edi,edx		;64+256=320
	add edi,ecx		;add left column
	and edi,0FFFFh		;just in case of a bad parameter
;	add edi,[ScreenPtr]
	add edi,0A0000h		;set to video memory
	push ebp		;save base pointer
	mov ebx,[FontColorsPtr]	;for now
	mov cl,8		;8 rows to do
	cld			;as always, go forward

.NextRow:
	;rol ecx,16		;get access to preroll and column counter
	mov dx,[esi]		;grab first row of char bitmap (16bits)
	add esi,byte 2		;for next row
	mov ch,4		;4 columns to do
.NextCol:
	mov eax,edx		;make a copy
	and eax,3		;filter bottom two bits
	mov al,[ebx+eax*2]	;index into color table
	shr edx,2		;adjust for next pixel
	shrd ebp,eax,8
	dec ch
	jnz .NextCol
	mov [edi],ebp
	mov ch,4		;4 more columns to do
.NextCol2:
	mov eax,edx		;make a copy
	and eax,3		;filter bottom two bits
	mov al,[ebx+eax*2]	;index into color table
	shr edx,2		;adjust for next pixel
	shrd ebp,eax,8
	dec ch
	jnz .NextCol2
	mov [edi+4],ebp

.ToNextRow:	
	;ror ecx,16		;get access to upper part of ecx
	add edi,320		;add wrap width to get to next row
	dec cl			;row counter
	jnz .NextRow		;still going

	pop ebp			;restore base pointer
	ret

;------------------------------
; FontBlitStr (dword String, words Length, TopRow, LeftCol, dwords FontSet, ColorTable) ()
; No regs preserved
;
; Simply calls font blitter in a tight loop
;
_FontBlitStr:
.NextChar:
	cmp word [esp+8],0	;test if there are any characters
	jz .End
	mov esi,[esp+4]		;get ptr to string
	mov al,[esi]		;grab next character
	inc dword [esp+4]	;for next character
        movzx edx,word [esp+10] ;get toprow
        movzx ecx,word [esp+12] ;get leftcol
	call [FontRoutine]	;calling by register saves from having to create a stack
				;and reread it for every call through the loop
	add word [esp+12],byte 8;next column is eight pixels to the right
	dec word[esp+8]		;one less character to output
	jnz .NextChar
.End:
	ret

%if 0
;------------------------------
; FontBlitCenteredStr (dword String, words Length, TopRow) () - No regs preserved
;
; Centers a string horizontally on whatever row specified.
;
_FontBlitCenteredStr:
	movzx eax,word [ScreenWidth]
	movzx ebx,word [esp+8];get length
	shl ebx,3		;multiply length by eight
	sub eax,ebx		;subtract length from screen width
	shr eax,1		;divide in half to get left column
	push ax			;put LeftCol
	push word [esp+12]	;put TopRow
	push word [esp+12]	;put string length
	push dword [esp+10]	;put string pointer
	call _FontBlitStr
	add esp,byte 10		;correct stack
	ret
%endif

;------------------------------
; FontBlitPar (dword String, words TopRow, LeftCol; dwords FontSet, ColorTable) ()
; No regs preserved
;
; Prints formatted text, calling font blitter in a tight loop.
;
_FontBlitPar:
        mov ax,[esp+10]
        mov [.LeftColumn],ax
.NextChar:
	mov esi,[esp+4]		;get ptr to string
	mov al,[esi]		;grab next character
	inc dword [esp+4]	;for next character
        cmp al,1
        js .ControlCharacter
        movzx edx,word [esp+8] ;get toprow
        movzx ecx,word [esp+10] ;get leftcol
	call [FontRoutine]	;calling by register saves from having to create a stack
				;and reread it for every call through the loop
        add word [esp+10],byte 8;next column is eight pixels to the right
        jmp short .NextChar
.ControlCharacter:
        test al,al
	jz .End
        cmp al,129
        ;ja .NotNewLine
        mov ax,[.LeftColumn]
        mov [esp+10],ax
        add word [esp+8],byte 9        ;next row is eight pixels down
        jmp short .NextChar
;.NotNewLine:
;        movzx eax,al
;        lea edi,[FontColors0-(130*8)+eax*8]
;        mov [FontColorsPtr],edi
;        jmp short .NextChar
.End:
        ret

.LeftColumn:    dw 0

;------------------------------
; DrawBox (words TopRow, BtmRow, LeftCol, RiteCol, Color) () - No regs preserved
;
; This routine clips finally (and beautifully too).
; It could theoretically work in any linear 8bit resolution.
;
_DrawBox:
	mov ax,[esp+8]		;get leftcol
	cmp ax,[ScreenClipLeft]	;check that not less
	jge .LeftColValid	;ok
	mov ax,[ScreenClipLeft]	;set it to clip
	mov [esp+8],ax		;and parameter
.LeftColValid:
        mov bx,[esp+10]         ;get right column
	cmp bx,[ScreenClipRite]	;check that not greater
	jle .RiteColValid	;ok
	mov bx,[ScreenClipRite]	;set it to clip
	mov [esp+10],bx		;and parameter
.RiteColValid:
	sub bx,ax		;get width
	js near .End		;negative width
	inc bx			;adjust by one

;	movzx edx,[ScreenWidth]
	mov edx,320		;get screen width
	sub dx,bx		;get wrap width

	shl ebx,16		;keep width in safe part of bx
	mov ax,[esp+4]		;get toprow
	cmp ax,[ScreenClipTop]	;check that not less
	jge .TopRowValid	;ok
	mov ax,[ScreenClipTop]	;set it to clip
	mov [esp+4],ax		;and parameter
.TopRowValid:
	mov bx,[esp+6]		;get btmrow
	cmp bx,[ScreenClipBtm]	;check that not greater
	jle .BtmRowValid	;ok
	mov bx,[ScreenClipBtm]	;set it to clip
	mov [esp+6],bx		;and parameter
.BtmRowValid:
	sub bx,ax		;get height
	js .End			;negative height
	inc bx			;adjust by one
	;height is now in lower part and width in higher part of ebx

	movzx eax,word ax	;zero out top 16 bits
	mov edi,eax		;make a copy
	shl eax,6		;multiply by 64
	shl edi,8		;now by 256
	add edi,eax		;multiplied by 320
;	imul ax,[ScreenWidth]
	movzx eax,word [esp+8]	;get left column
	lea edi,[0A0000h+eax+edi];add left column
;	add edi,[ScreenPtr]	;set to screen

	mov al,[esp+12]		;get color
	mov ah,al		;copy color to second byte
	mov ecx,eax		;make a copy
	shl eax,16		;shift into upper part
	mov ax,cx		;put copy back
	;eax now consists of four pixels all the same color

	xor ecx,ecx		;zero out top 17 bits
	cld			;as always, go forward
.NextLine:
	shld ecx,ebx,14		;get width divided by 4
	rep stosd
	shld ecx,ebx,16		;get width
        and ecx,3               ;get modulus 4
	rep stosb
	add edi,edx
	dec bx
	jnz .NextLine
.End:
	ret

;------------------------------
; RedrawBackground (words TopRow, BtmRow, LeftCol, RiteCol) () - No regs preserved
;
; Redraws an area of the background.
; Background is pointed to by BackgroundPtr.
;
;RedrawBackground:
;	ret
;
;	xor ecx,ecx		;zero out top 17 bits
;	cld			;as always, go forward
;.NextLine:
;	shld ecx,ebx,14		;get width divided by 4
;	rep movsd
;	shld ecx,ebx,16		;get width
;	and cl,3		;get modulus 4
;	rep movsb
;	add edi,edx
;	dec bx
;	jnz .NextLine
;.End

;------------------------------
; DrawClearScreen (al=color) () - Preserves all regs except modifying upper 24 bits of eax
;
; Simply clears the screen
;
DrawClearScreen:
	PushAll edi,cx
	mov ah,al		;copy color to second byte
	mov cx,ax		;make a copy
	shl eax,16		;shift into upper part
	mov ax,cx		;put copy back
	mov ecx,64000/4		;320x200=64000
	mov edi,0A0000h		;base of video memory
	cld			;as always, go forward
	rep stosd		;here we go
	PullAll edi,cx
	ret

;------------------------------
; DrawBorder (words TopRow, BtmRow, LeftCol, RiteCol, Mode) - No regs preserved
;
; For drawing all those windows, menus, buttons, and borders. Clipping is automatically
; implemented as a byproduct of using DrawBox.
;
; Mode:  1=swap colors  2=fill in
;
_DrawBorder:
        ;mov eax,GuiColorTop
        ;mov ebx,GuiColorBottom
        ;test byte [esp+12],1    ;is border in or out?
        ;jz .ConvexBorder        ;border is normal
        ;xchg eax,ebx            ;swap border colors
        mov eax,GuiColorTop|(GuiColorBottom<<16)
        test byte [esp+12],1    ;is border in or out?
        jz .ConvexBorder        ;border is normal
        rol eax,16              ;swap border colors
.ConvexBorder:
        ;push bx                 ;save two colors: forecolor, backcolor
        ;push ax
        push eax

;Left border
	mov dx,[esp+12]		;get leftcol
	mov cx,[esp+10]		;get btmrow
	mov bx,[esp+8]		;get toprow
	push ax			;set box forecolor
	push dx			;set box ritecol to leftcol
	push dx			;set box leftcol
	push cx			;set box btmrow
	push bx			;set box toprow
	call _DrawBox		;destroys all regs!

;Right border
	mov ax,[esp+12]		;get backcolor
	mov [esp+8],ax		;set box backcolor
        mov dx,[esp+24]         ;get ritecol
	mov [esp+4],dx		;set box leftcol to ritecol
	mov [esp+6],dx		;set box ritecol
				;don't bother changing toprow or btmrow
	call _DrawBox

;Top border
	mov ax,[esp+10]		;get forecolor
	mov [esp+8],ax		;set box forecolor
	mov bx,[esp+18]	;get toprow
	mov dx,[esp+22]	;get leftcol
	mov [esp],bx		;set box toprow
	mov [esp+2],bx		;set box btmrow to toprow
	mov [esp+4],dx		;set box leftcol
	call _DrawBox

;Bottom border
	mov ax,[esp+12]		;get backcolor
	mov [esp+8],ax		;set box backcolor
	mov bx,[esp+20]	;get btmrow
	mov [esp],bx		;set box toprow to btmrow
	mov [esp+2],bx		;set box btmrow
				;don't bother changing leftcol or ritecol
	call _DrawBox

;Inner area (if set)
	test byte [esp+26],2	;is border filled in?
	jz .NoInnerArea		;just an outline
	add esp,byte 10		;clear prior stack
	mov dx,[esp+14]		;get ritecol
	mov cx,[esp+12]		;get leftcol
	mov bx,[esp+10]		;get btmrow
	mov ax,[esp+8]		;get toprow
	dec dx			;move box inside border by one pixel
	inc cx
	dec bx
	inc ax
	push word GuiColorFront	;set box color to window area
	push dx			;set box ritecol
	push cx			;set box leftcol
	push bx			;set box btmrow
	push ax			;set box toprow
	call _DrawBox
.NoInnerArea:

	add esp,byte 14		;clear stack for DrawBox and two saved colors
	ret

;------------------------------
; SpliceScreenEffect (*) - No regs preserved
;
; Cheap effect takes each horizontal screen line and shifts it left or right by four pixels.
;
%if 0
SpliceScreenEffect:
	mov ebx,0A0000h
	mov edx,200/2
.NextTwoRows:
	mov ecx,316/4
	mov esi,ebx
	mov edi,ebx
	cld
	lodsd
	rep movsd
	mov [edi],eax
	add ebx,320

	mov ecx,316/4
	lea esi,[ebx+316]
	lea edi,[ebx+316]
	std
	lodsd
	rep movsd
	mov [edi],eax
	add ebx,320

	dec edx
	jnz .NextTwoRows
%endif
;============================================================
; INPUT ROUTINES
;============================================================

;------------------------------
; (esi=keylist struct) (cf=error-keypress not found ecx=keynumber)
;
; Pass a scan structure to it, which points to a list of keys, number of normal keys, and
; number of extended.
;
KeyScanFor:
	cld
	mov edi,[esi]
	movzx ecx,byte [esi+4]
	test al,al
	jz .ExtendedKey
	repne scasb
	jnz .NotFound
	not cl
	add cl,[esi+4]
	clc
	ret

.ExtendedKey:
	add edi,ecx
	mov al,ah
	mov cl,[esi+5]
	repne scasb
	jnz .ExtendedKeyNotFound
	not cl
	add cl,[esi+5]
	xor al,al		;put null back into al
	add cl,[esi+4]
	clc
	ret

.ExtendedKeyNotFound:
	xor al,al		;put null back into al
.NotFound:
	stc
	ret

;------------------------------
; KeyGetPress () (ax=last keypress, cf=key or keys pressed) - Preserves all other regs
;
; Besides simply returning key input, it also clears the keyboard buffer if there is more
; than one press waiting, so that annoying beeping won't ever happen on slower machines.
;
KeyGetPress:
	PushAll ecx,ebx
	mov ecx,16	;maximum count of 16 loops to clear buffer
	xor ebx,ebx	;set initial keypress to null
.CheckKey:
	mov ah,1	;BIOS function 1, check key status
	int 16h
	jz .NoneWaiting	;zero flag set if nothing has been pressed
	mov ah,0	;BIOS function 0, get last key press
	int 16h
%if MyPersonalVersion           ;leave out for public release
        cmp ax,'q'<<8           ;Alt+F10 for grabbing screenshots :)
        jne .NoSnapshot
        push eax                ;save keypress
	call SaveSnapshot
        pop eax
.NoSnapshot:
%endif
	mov ebx,eax	;save KeyPress since calling for key status again destroys it
%if Debug
	PushAll ecx,ebx
	mov [.LastPress],bx
	FontBlitStr .LastPress, 2, 9, 100
	PullAll ecx,ebx
%endif
	dec ecx		;one less key to clear
	jnz .CheckKey	;loop until no keys are waiting or count is up
.NoneWaiting:
	cmp ecx,16	;if count equals original value, nothing changed and carry is clear
	mov eax,ebx
	PullAll ecx,ebx
	ret

%if Debug
	.LastPress:	dw 0
%endif

;------------------------------
; UserWait () (ax=exiting keypress or mouse press, cf=set if keypress caused exit)
; Preserves all other regs
;
; Waits for a key or mouse button to be pressed before proceding
;
UserWait:
        call KeyGetPress        ;clears any waiting keys
.CheckKey:
	call MouseGetInfo
	cmp al,2		;greater than mouse movement?
	jae .End		;user clicked a button so exit (carry is clear)
%if Debug
	FontBlitStr MouseCol, 2, 0, 0
%endif
	mov ah,1		;BIOS function 1, check key status
	int 16h
	jz .CheckKey		;no keys pressed yet
	mov ah,0		;BIOS function 0, get last key press
	int 16h
%if MyPersonalVersion           ;leave out for public release
        cmp ax,'q'<<8           ;Alt+F10 for grabbing screenshots :)
        jne .NoSnapshot
        push eax                ;save keypress
	call SaveSnapshot
        pop eax
        jmp .CheckKey
.NoSnapshot:
%endif
%if Debug
	mov [KeyGetPress.LastPress],ax
	FontBlitStr KeyGetPress.LastPress, 2, 9, 0
%endif
	stc
.End:
	ret

;------------------------------
; (ax=mouse function) () - Preserves all not passed back by the mouse driver function
;
; Most most calls can just be done directly since they only require a 'mov' and 'int'.
; This simply makes sure that the mouse was detected by MouseInitialize before calling.
; Be sure not to use show or hide functions with the mouse driver since the mouse driver's
; pointer always remains hidden; the only pointer is the one that comes with this prog.
; Using this routine for any functions that would cause the mouse pointer to move will not
; automatically update the pointer. Use PointerMoveMouse instead for repositioning it.
;
MouseFunction:
	cmp byte [MouseExists],0	;check that mouse detected
	jz .End				;simply quit if no mouse
	int 33h				;mouse driver call
.End:
	ret

;------------------------------
; () (al=status, ah=buttons pressed since last call) - No regs preserved
; *not finished
;
; Responsible for checking whether or not the mouse has moved or a button has been pressed or
; released. Returns the current status of it in al (0=nothing  1=mouse move  2=mouse press).
; Anything non-zero means a change, then the other variables tell more info.
; It also moves the pointer if the mouse has been moved. Since BgMapper draws the pointer
; rather than the mouse driver, and since there is no handler called when mouse events happen,
; this function must be polled to keep the pointer active. It is possible that this function
; could miss a mouse click if not called at the right time, but most loops are tight enough
; to not worry about that.
;
align 16				;extra speed??
MouseGetInfo:
	cmp byte [MouseExists],0	;check that a mouse does exist
	jz .End				;simply quit if no mouse
	mov ax,3			;mouse driver function 3, get status
	int 33h				;mouse driver call
	xor al,al			;assume no change
	mov ah,[MouseBtnsDown]		;get previous buttons down
	not ah				;flip bits of previous presses
	and ah,bl			;compare the two and mask out only new presses
	mov [MouseBtnsDown],bl		;store buttons down in presses
	mov [MouseBtnsPressed],ah	;store new buttons pressed
	jz .NoPresses			;skip section if no buttons were pressed
	mov esi,[Timer]			;get current timer value
	mov ebx,esi			;make a copy
	sub ebx,[MouseLastClick]	;get time between clicks
	mov [MouseLastClick],esi	;save time of last click
	mov [MouseClickTime],ebx	;for detecting 'double clicks'
	or al,2				;flag button press
.NoPresses:
	shr cx,1			;divide column in half while in 320x200 mode
	cmp dx,[MouseRow]		;has row changed?
	jne .MouseMove
	cmp cx,[MouseCol]		;has column changed?
	je .NoMouseMove
.MouseMove:
	or al,1				;flag mouse movement
	mov [MouseRow],dx		;save row and column for next call
	mov [MouseCol],cx
	push ax				;save mouse change flags
;	call PointerMove
	pull ax				;retrieve mouse change flags
.NoMouseMove:
	ret
.End:
	xor al,al
	ret

section .bss
alignb 4

MouseExists:		resb 1		;who would not want to use a mouse?
MouseButtons:		resb 1		;number of buttons mouse has
MouseBtnsPressed:	resb 1		;which buttons were pressed since the last call
MouseBtnsDown:		resb 1		;which buttons are currently down (or at least a while ago)
MouseRow:		resw 1		;mouse row last time called
MouseCol:		resw 1		;mouse column last time called
MouseLastClick:		resd 1		;when the last press occurred (using the timer)
MouseClickTime:		resd 1		;time between latest click and last click

section .text

;------------------------------------------------------------
; POINTER ROUTINES
;------------------------------------------------------------
; The pointer is actually drawn by this program rather than by the mouse driver, since it
; doesn't support SVGA modes. Because of this, the pointer can be visible even if there was
; no mouse detected. That is how there can still be a cursor. It also allows the cursor
; image to have three shades of color plus transparency.
;
;------------------------------
; MouseInitialize () (ax=TRUE if mouse present, cf=if no mouse driver) - No regs preserved
;
; Called to check for existance of mouse, and must be called before mouse routines.
; Resets mouse driver if found and sets MouseExists to TRUE, otherwise MouseExists is FALSE.
; It flags an initialization error if there was no mouse driver detected. This also sets up
; a default cursor image for when the pointer is moved. However the pointer is hidden and
; not shown until PointerShow is called.
;
MouseInitialize:
	mov dword [PointerBitmapPtr],PointerImage.Default
				;make cursor image out of packed image
	xor eax,eax		;mouse driver function 0, reset
	int 33h			;mouse driver call
	cmp ax,0FFFFh		;should be -1 (true)
	jne .NoMouseDriver	;no mouse driver
	mov [MouseExists],al	;yes, mouse exists
	mov [MouseButtons],bl	;2/3 buttons
	call MouseGetInfo	;call to set initial mouse row and column
	ret
.NoMouseDriver:
	mov byte [MouseExists],0;no mouse exists
	ret

;				**********
%if Complete

PointerShow:			;draws the cursor over screen
PointerHide:			;redraws the screen background
PointerMoveMouse:		;moves the true mouse cursor too and adjust MousePriorRow...
PointerMove:			;redraws background and then cursor in new position
	ret			;if cursor was in a hidden area, it
PointerChange:			;changes to a new cursor by first creating the new cursor and
				;mask, then it simply redraws the background and new cursor
PointerSaveBackground:

;------------------------------
align 16			;extra speed??
PointerDraw:
	;calculate starting row and number of rows
	;determine starting shift block if clipped
	;adjust esi & edi accordingly
Col1:
	mov eax,[edi]
	and eax,[esi]
	or eax,[esi+4]
	mov [edi],eax
Col2:
	mov eax,[edi+4]
	and eax,[esi+8]
	or eax,[esi+12]
	mov [edi+4],eax
Col3:
	mov eax,[edi+8]
	and eax,[esi+16]
	or eax,[esi+20]
	mov [edi+8],eax
Col4:
	mov eax,[edi+12]
	and eax,[esi+24]
	or eax,[esi+28]
	mov [edi+12],eax
	;finish off any remaining pixels
	;esi=esi + cursor bytes per row
	;edi=edi+ (screen width - cursor with)
	;next row

;------------------------------
; Tests for a point being inside a list of areas.
; If the pointer was not it any area searched, carry is set,
; otherwise the area is returned with reduced coordinates to that area.
;
; CheckPointerAreas (ptr to list of areas structure, starting area) (area pointer was in,
; reduced toprow, btmrow, cf=error)
;
;CheckPointerAreas:
;	stc
;	ret
%endif
;				**********

section .bss
alignb 4

PointerRow:		resw 1		;the pointer image's last coordinates
PointerCol:		resw 1
PointerBitmapPtr:	resd 1		;address of current packed cursor image
PointerBitmap:		resb 1024	;current cursor image
PointerBackground:	resb 512	;screen behind pointer

section .text

;============================================================
; OBJECT CODE
;============================================================
;The object code is not all written yet, so it is not used

;				**********
%if Complete
;------------------------------------------------------------
; Window object code
;------------------------------
;
WindowCreate:
	;creates a window based on coordinates, height/width, or whatever else
	;windows can left/right, top/bottom oriented or centered
	;allocates space for ptr to window title, window clips, and edges
	;returns ptr to memory
WindowGetInfo:
	;returns window coordinates / height&width / title
WindowDestroy:
	;deallocates resources and redraws background behind window

;------------------------------------------------------------
; List object code
;------------------------------
;
ListSetChoice:
	;sets the current choice in a list to a different one
	;adjusts variables properly
ListReceiveKey:
	;responds to arrow keys and other scroll keys
	;adjusts variables properly
ListReceiveMouse:
	;only responds to mouse clicks
	;also passes on input to the scroll bar
ListDraw:
	;generic list drawer
	;updates the scroll bar (if there is one)
	;it can either redraw the entire list
	;redraw the entire list
	;or just redraw what has changed

;------------------------------------------------------------
; Menu object code
;------------------------------
; MenuCreate (words expected number of choices, menu type) (cf=failure, eax=to menu structure)
; No regs preserved
;
; Allocate the memory necessary for menu structures and sets variables to initial values
;
_MenuCreate:
	;allocate memory for menu structure
	Malloc Size_Menu,eax		;allocate memory for menu structure
	jc .End				;memory error!
	movzx ecx,byte [esp+4]		;number of expected choices in menu
	shl ecx,3			;multiply by eight
	Malloc ecx,edi			;allocate memory for list structure
	jc .Error			;memory error!
	mov [eax+Menu.ListSize],ecx	;save list size
	mov [eax+Menu.ListPtr],edi	;save list pointer
	mov word [eax+Menu.NumChoices],0;there are no choices yet
	mov edi,[FontStylePtr]		;get current font style
	mov [eax+Menu.FontPtr],edi	;save font style
	mov word [eax+Menu.ChoiceHeight],9;height of an individual choice
	mov cl,[esp+6]			;get attributes
	mov [eax+Menu.Attribs],cl	;set general attributes of menu
	mov byte [eax+Menu.Redraw],-1	;full redraw
.End:
	ret
.Error:
	Free eax			;free menu structure
	stc				;flag error
	ret

;------------------------------
; MenuAddChoices (dwords ptr to menu structure, ptr to new list, word number of choices) ()
; No regs preserved
;
; Adds (appends) a list of choices to an existing menu structure
; Note that a menu can not hold more than 255 choices - not like that would ever happen
; though.
;
_MenuAddChoices:
	mov ebx,[esp+4]			;get menu structure
	mov esi,[esp+8]			;get new list pointer
	mov edi,[ebx+Menu.ListPtr]	;get list structure
	movzx ecx,byte [esp+12]		;get number of new choices
	test ecx,ecx			;make sure we have some choices
	jz .End				;if no choices, don't bother
	movzx edx,byte [ebx+Menu.NumChoices] ;get current number of choices
	lea eax,[ecx+edx]		;get old choices plus new ones
;	jo ...				;in case over 255 choices added
	shl eax,3			;multiply total choices by eight
	cmp [ebx+Menu.ListSize],eax	;if space needed is greater than size then expand it
	jae .EnoughListRoom		;already enough space so just continue
	cmp cl,8			;reallocate only for every eight choices
	ja .EnoughChoices		;there are more than enough
	lea eax,[edx*8+64]		;get new size
.EnoughChoices:
	Realloc edi,eax,edi		;reallocate list structure to new size
	jc near .End			;memory error!
	mov [ebx+Menu.ListPtr],edi	;save new list pointer
.EnoughListRoom:
	lea edi,[edi+edx*8]		;get to choice directly after last choice
	lea eax,[edx+ecx]		;add new choices to old ones
	mov [ebx+Menu.NumChoices],al	;save new total number of choices
.NextChoice:
	movsd				;transfer choice string
	movsw				;transfer attributes and ID
	add edi,byte 2			;menu list choices are eight bytes
	dec cl				;do until no more choices
	jnz .NextChoice
.End:
	clc
	ret

;------------------------------
; MenuSetChoiceAttribs (dword ptr to menu structure, words basechoice, count, attributes) (cf=error)
; No regs preserved
;
; Sets the attributes of a single choice or several choices, depending on count
; It might be easier to simply parse all the choices and then set the attributes for each one
; or a group of ones. This is mainly meant for setting which choices are disabled, but could
; also set the divider and submenu option.
; It starts from the last choice and works forward if basechoice = -1 (255)
; Attributes consist of an AND mask (high) and an OR mask (low). A value of FF00 would not
; change anything.
;
_MenuSetChoiceAttribs:
	mov ebx,[esp+4]			;get menu structure
	movzx eax,byte [esp+8]		;get choice to be set or group base
	mov cl,[esp+10]			;get count of choices
	mov ch,[ebx+Menu.NumChoices]	;get number of menu choices
	cmp al,255			;is last choice to be set?
	jne .StartFromBase		;no, start from base given
	mov al,ch			;set choice to be set to last choice
	sub al,cl			;start on first choice
.StartFromBase:
	cmp al,ch			;check that base is not past last choice
	jae .ErrorEnd			;just end (carry will be set)
	xor dl,dl			;set error indicator to zero
	add cl,al			;add count to choice to get last choice
	jc .SetLastChoice		;last choice went past number of choices
	cmp cl,ch			;check that last choice is not past last choice
	jbe .CountOkay			;count did not go past last choice
.SetLastChoice:
	inc dl				;set error
	mov cl,ch			;set last choice to number of choices
.CountOkay:
	mov edi,[ebx+Menu.ListPtr]	;get ptr to menu list
	lea edi,[edi+eax*8]		;get address of choice in list to be set
	sub cl,al			;get loop count by subtracting first from last
	jz .End				;zero choices to add (not considered an error)
	mov ax,[esp+12]			;get attributes
.NextChoice:
	and [edi+MenuList.Attribs],ah	;filter out attributes
	or [edi+MenuList.Attribs],al	;set attributes
	add edi,byte Size_MenuList
	dec cl
	jnz .NextChoice
	shr dl,1			;get carry by testing error indicator
.End:					;if set, not all choices were changed
	ret
.ErrorEnd:
	stc
	ret

;------------------------------
; MenuOpen (dword ptr to menu structure, words toprow, leftcol, mode) (dword to dimensions)
; No regs preserved
; *not finished
;
; Constructs the menu and depending on whether it to be a full or embedded menu
; Sets the menu's top row and left column based on the info passed to it
; It will save the background and let MenuDraw know that it should draw the back border
; before drawing the menu choices
;
MenuOpen:
	mov ebx,[esp+4]			;get ptr to menu structure
	mov ax,[esp+8]			;get top row
	mov dx,[esp+10]			;get left col
	mov [ebx+Menu.TopRow],ax	;set top row of menu
	mov [ebx+Menu.LeftCol],dx	;set left column of menu
	add ax,byte 3
	add dx,byte 3
	mov [ebx+Menu.ChoiceTopRow],ax	;set top row of menu choices
	mov [ebx+Menu.ChoiceLeftCol],dx	;set left column of menu choices
;	test [ebx+Menu.Attribs],MenuAttribEmbedded
;	add ax,byte 2			;get toprow of choices
;	add dx,byte 2			;get left column of choices
	call MenuConstruct.ByReg	;construct the menu before proceding
	ret

;------------------------------
; MenuConstruct (dword ptr to menu structure) (*?eax=menu height/width)
; No regs preserved
;
; 'Builds' the menu by figuring its height and width by each of the choices in it
;
MenuConstruct:
	mov ebx,[esp+4]			;get menu structure
.ByReg:
	mov edi,[ebx+Menu.ListPtr]	;get list structure
	xor ecx,ecx			;set menu attributes to nada
	xor edx,edx			;set menu height to one
	mov cl,[ebx+Menu.NumChoices]	;get current number of choices
	mov [ebx+Menu.Width],word 0	;initially set menu width to zero
	test cl,cl			;make sure there some choices
	jz .End				;nope, just skip to end
.NextChoice:
	test ch,MenuListDivider		;check whether last choice had a divider
	jz .NoDivider			;choice had none
	add edx,byte 5			;add divider pixel size
    .NoDivider:
	mov [edi+MenuList.Pos],dx	;save choices top row to position
	mov esi,[edi+MenuList.Text]	;get text ptr
	call GetStrLength		;get choice string length (in ax)
	shl ax,3			;multiply string length by character width
	cmp [ebx+Menu.Width],ax		;increase menu width if choice will not fit
	jae .WideEnough			;menu is already wide enough, so don't worry about it
	mov [ebx+Menu.Width],ax		;adjust menu width to fit choice
    .WideEnough:
	mov ch,[edi+MenuList.Attribs]	;get new choice attributes and ID
	add edi,byte Size_MenuList	;menu list choices are eight bytes
	add edx,[ebx+Menu.ChoiceHeight];add choice height to menu height
	dec cl				;do until no more choices
	jnz .NextChoice
.End:
	mov ax,[ebx+Menu.Width]		;get final width
	mov [ebx+Menu.ChoiceWidth],ax	;copy width to choice width
	mov [ebx+Menu.Height],dx	;adjust total menu height
	ret

;------------------------------
; MenuDestroy (dword ptr to menu structure) (cf=failure) - No regs preserved
;
; Frees the memory used by the menu structures
; Also calls MenuClose to restore the background
;
_MenuDestroy:
	call _MenuClose			;restore background and free image memory
	mov esi,[esp+4]			;get menu structure
	mov edi,[esi+Menu.ListPtr]	;get list pointer
	Free edi			;free memory for list structure
	Free esi			;free memory for menu structure
.End:
	ret

;------------------------------
; MenuClose (dwords ptr to menu structure) () - No regs preserved
;
; Restores the background if a full menu was created, otherwise returns
; Frees the memory used to hold that image
;
_MenuClose:
	ret

;------------------------------
; MenuDraw (dwords ptr to menu structure) () - No regs preserved
;
; Draws the menu border and menu choices
; It has three modes:
; A complete redraw, menu and all choices
; Full redraw, draw all choices
; and partial redraw that only draws choices that have changed
; Resets priorchoice to current choice
;
MenuDraw:
	;hide mouse pointer
	mov ebx,[esp+4]				;get menu structure
	test byte [ebx+Menu.Redraw],MenuDrawComplete ;complete redraw?
	jz near .ChoicesOnly			;do not draw background, just choices
;draws the menu border and face
;	cmp [ebx+Menu.Attribs],MenuAttribEmbedded
	sub esp,byte 10
	mov [esp+8],word 2			;convex border with solid face
	mov cx,[ebx+Menu.LeftCol]		;get menu's left column
	mov [esp+4],cx
	add cx,[ebx+Menu.Width]			;get right column
	add cx,byte 5				;plus width of border
	mov [esp+6],cx
	mov dx,[ebx+Menu.TopRow]		;get menu's top row
	mov [esp],dx
	add dx,[ebx+Menu.Height]		;get bottom row
	add dx,byte 3				;plus width of border
	mov [esp+2],dx
	call _DrawBorder			;draw background menu face
	add esp,byte 10
	mov ebx,[esp+4]				;get menu structure again

;loop through all the choices checking for dividers
;draws a horizontal bar wherever one is found
	mov cl,[ebx+Menu.NumChoices]		;get number of menu choices
	mov esi,[ebx+Menu.ListPtr]		;get ptr to menu choice list
	sub cl,1				;draw one less than the total number of choices
						;could not use DEC because it did not update carry
	jc near .End				;end if no choices in menu
	jz near .NextRow			;if the menu had just one choice, just show it
	sub esp, byte 14			;make variable storage for words and DrawLine
	mov [esp+10],cl				;save count
	mov cx,[ebx+Menu.ChoiceLeftCol]		;get menu's left column
	mov [esp+4],cx				;set left column
	add cx,[ebx+Menu.ChoiceWidth]		;add width to get right side
	dec cx					;adjust one pixel to the left
	mov [esp+6],cx				;set right column
	mov dx,[ebx+Menu.ChoiceTopRow]		;get choices top row
	add dx,[ebx+Menu.ChoiceHeight]
	mov [esp+12],dx
.NextChoice:
	test byte [esi+MenuList.Attribs],MenuListDivider ;choice has a divider?
	jz .NoDivider				;no divider
	mov cx,[esi+MenuList.Pos]		;get choices row position
;	mov [esp+14],esi			;save menu choice source ptr
	mov [esp+8],word 0			;set color black
	lea edx,[edx+ecx+1]			;get true pixel row
	mov [esp],dx				;set top row
	mov [esp+2],dx				;set bottom row
	call _DrawBox
	inc word [esp]				;next top row
	inc word [esp+2]			;next bottom row
	mov [esp+8],word 32			;set color black
	call _DrawBox
	mov ebx,[esp+18]			;get menu structure again
;	mov esi,[esp+14]			;get menu choice source again
	mov dx,[esp+12]				;get menu choice's top row
    .NoDivider:
	add esi,byte Size_MenuList		;get next menu choice
	dec byte [esp+10]			;do until no more choices
	jnz .NextChoice				;more choices left
	add esp,byte 14				;free stack variable space
	xor byte [ebx+Menu.Redraw],MenuDrawComplete ;turn off complete redraw

;redraw choices, either all or just the two that have changed
.ChoicesOnly:
	test byte [ebx+Menu.Redraw],MenuDrawFull
	jnz .Full						;redraw all choices

;a full redraw actually starts with the last choice and go backwards for simplicity
.Full:
	xor byte [ebx+Menu.Redraw],MenuDrawFull	;turn off full choice redraw
	movzx ecx,byte [ebx+Menu.NumChoices]	;get count
	dec ecx					;start out with one less than total choices
	jc .End					;are there choices to display?
.NextRow:
	call .PrintChoice			;print out choice
	dec ecx					;was last choice printed?
	jns .NextRow				;no negative sign so more choices to go
	mov cl,[ebx+Menu.CurChoice]		;get current choice
	mov [ebx+Menu.PriorChoice],cl		;set prior choice to current choice
.End:
	;show mouse pointer
	ret

; ecx is expected to contain the choice to display, ebx points to the menu structure
; they are preserved, all other registers are not
.PrintChoice:
	mov edi,[ebx+Menu.ListPtr]		;get ptr to list structure
	lea esi,[edi+ecx*8]			;get ptr to choice in list
	mov al,[esi+MenuList.Attribs]		;get attributes
	and eax,MenuListDisabled		;mask out all but disabled flag bit
	cmp [ebx+Menu.CurChoice],cl		;is choice to be drawn the current choice?
	jnz .NotCurrentChoice			;no
	or al,1					;it is the active choice, set to highlighted color
    .NotCurrentChoice:
	lea eax,[MenuColors+eax*8]		;get color set
	mov [FontColorsPtr],eax			;set current font color set
	PushAll ebx,ecx				;save ptr to menu structure and counter
	mov dx,[esi+MenuList.Pos]		;get vertical choice position
	mov cx,[ebx+Menu.ChoiceLeftCol]		;get menu's left column
	add dx,[ebx+Menu.ChoiceTopRow]		;add menu's top row to position
	mov esi,[esi+MenuList.Text]		;get ptr to choice text
	call GetStrLength			;find choice's text length (in ax)
	FontBlitStr esi, ax, dx, cx		;print out the choice
	PullAll ebx,ecx				;restore ptr to menu structure and counter
	ret

;------------------------------
; MenuSetCurrentChoice (dword ptr to menu structure, word new choice) (al=change, ah=choice)
; No regs preserved
;
; Sets the current choice in a menu, which can be used by the main program or other menu
; routines. If it is called by other menu routines, the choice number is passed on to it,
; otherwise a choice number or a choice's ID can be passed to it, depending on bit eight of
; the new choice passed on (set=by number, clear=by ID). If the menu is staticly created,
; passing absolute choice numbers is fine, but otherwise ID's should be passed since the
; choices can be moved around and passing a number might set the wrong choice.
; Handy if a menu should be opened starting at a specific choice.
;
_MenuSetCurrentChoice:
	mov ebx,[esp+4]
	movzx ecx,byte [esp+8]			;get new choice
	xor eax,eax				;clear return status
	test byte [esp+9],1			;are we setting by choice number or choice ID?
	jnz .ByChoiceNum2			;by the choice's number
;otherwise by ID, loop through choices looking for the one with the desired ID
	mov ah,cl				;copy ID to ah
	movzx ecx,byte [ebx+Menu.NumChoices]	;get total count of choices
	mov esi,[ebx+Menu.ListPtr]		;get ptr to menu choices
	test cl,cl				;are there any choices?
	jz .NoChange				;there aren't any choices to search
	dec cl					;start out with one less than total choices
	lea esi,[esi+ecx*8]			;get address of last choice
.NextChoice:
	cmp [esi+MenuList.ChoiceID],ah	;does this choice have the desired ID
	je .IdMatch			;yes, so onward to setting the current choice
	sub esi,byte Size_MenuList	;on to the previous choice
	dec ecx				;has the last one been checked?
	jns .NextChoice			;no negative sign so more choices to go
.NoChange:				;search failed, no choice had the desired ID
	ret
.ByChoiceNum:					;called only from other menu routines
	and al,~MenuChngSelect
.ByChoiceNum2:					;status is already clear
	cmp cl,[ebx+Menu.NumChoices]		;is new choice is out of range?
	jae .ChoiceError			;greater than or equal to total choices
.IdMatch:					;skip the last choice check
	cmp [ebx+Menu.CurChoice],cl		;is new choice different than current choice?
	je .NoChange				;choices are the same
	mov esi,[ebx+Menu.ListPtr]		;get ptr to menu choice list
	mov [ebx+Menu.CurChoice],cl		;set current choice to new choice
	or al,MenuChngSelect			;let caller know the choice has changed
	mov ah,[esi+ecx*8+MenuList.ChoiceID]	;get choice's numeric ID and return it
	ret
.ChoiceError:					;!? Choice given is out of bounds
	movzx ecx,byte [ebx+Menu.NumChoices]	;get total count of choices
	sub ecx,byte 1				;one less choice than the total
	jnc .IdMatch				;if there was at least one choice then return
	ret

;------------------------------
; MenuAcceptChoice (ebx=ptr to menu structure, ecx=choice) (al=change, ah=choice)
; No regs preserved
;
; Returns the necessary values for a choice being accepted. It also will not return a choice
; as being accepted if it is disabled.
; Only called by other menu routines
;
MenuAcceptChoice:
	and al,~MenuChngAccept			;clear return status
	cmp cl,[ebx+Menu.NumChoices]		;check if new choice is out of range
	jae .NoChange				;is greater than or equal to total choices
	mov esi,[ebx+Menu.ListPtr]		;get ptr to menu choice list
	test byte [esi+ecx*8+MenuList.Attribs],MenuListDisabled
	jnz .NoChange				;do not allow disabled choices to be accepted
	or al,MenuChngAccept			;flag choice was accepted
	mov ah,[esi+ecx*8+MenuList.ChoiceID];get choice's numeric ID and return it
.NoChange:
	ret

;------------------------------
; MenuReceiveKey (dword ptr to menu structure, word key) (al=change, ah=choice)
; No regs preserved
;
; Decides what to do with key input directed to the menu
; Either selects a different choice or lets the caller know a choice was chosen
; Calls MenuSetCurrentChoice to change the choice and return status
; If the choice was changed, al contains a flag that indicates a change and ah contains the
; byte ID of that choice, otherwise it is null
;
MenuReceiveKey:
	mov ebx,[esp+4]				;get menu structure
	xor eax,eax				;set return value to nada
	movzx ecx,byte [ebx+Menu.CurChoice]	;get current choice with top 24 bits zeroed
	mov dx,[esp+8]				;get keypress

.0:	cmp dx,'P'<<8				;compare keypress to down key
	jne .1
	inc cl					;one choice down
	cmp [ebx+Menu.NumChoices],cl		;choice greater than last one?
	ja near _MenuSetCurrentChoice.ByChoiceNum;no, choice is in range
	xor cl,cl				;set choice to first one
	jmp _MenuSetCurrentChoice.ByChoiceNum
.1:	cmp dx,'H'<<8				;up key?
	jne .2
	test cl,cl				;are we on the first choice?
	jnz .ChoiceNotFirst			;no, choice is in range
	mov cl,[ebx+Menu.NumChoices]		;set choice to number of choices
    .ChoiceNotFirst:
	dec cl					;one choice up
	jmp _MenuSetCurrentChoice.ByChoiceNum
.2:	cmp dl,' '				;is key space or above?
	jb .3					;no if control character
	cmp dl,'~'				;is key tilde or below?
	ja .4					;no if extended character, ignore keypress
	inc cl					;start one choice after current choice
	mov ah,[ebx+Menu.NumChoices]		;get number of choices
	cmp cl,ah				;starting choice isn't past last choice?
	jb .CountOkay				;nope, just continue with current choice
	xor cl,cl				;set starting choice to zero
.CountOkay:
	mov esi,[ebx+Menu.ListPtr]		;get ptr to list of choices
	lea esi,[esi+ecx*8]			;get current choice in list
	mov ch,ah				;make a copy for count
	sub ah,1				;one fewer choices than total
	jc .4					;total choices is zero, just end
	call .MakeUppercase			;for comparison in loop
	mov dh,dl				;move letter to dh
.NextChoice:
	mov edi,[esi+MenuList.Text]		;get choice's text ptr
	mov dl,[edi]				;get first letter of choice
	call .MakeUppercase
	cmp dl,dh				;compare the first letter of the choice with KeyPress
	je .ChoiceMatch				;letters match
.ReturnFromMatch:
	cmp cl,ah				;if last choice has been reach, wrap around to the first
	je .WrapChoice
	inc cl					;next choice
	add esi,Size_MenuList			;next choice in list
.ReturnFromWrap:
	dec ch					;one less choice to check
	jnz .NextChoice
	test al,al				;is key match flag set?
	jz .4					;no, so just end
	movzx ecx,byte [.ChoiceFound]
	jmp MenuAcceptChoice
.ChoiceMatch:
	test al,al				;if this is the second choice matched
	jnz .ChoiceMatched			;set as current choice
	mov [.ChoiceFound],cl			;otherwise, store choice found for later
	or al,1					;flag a choice find
	test byte [esi+MenuList.Attribs],MenuListDisabled	;disabled choice?
	jz .ReturnFromMatch			;return to loop to look for more
.ChoiceMatched:
	movzx ecx,byte [.ChoiceFound]		;get choice number that was
	jmp _MenuSetCurrentChoice.ByChoiceNum
.WrapChoice:
	mov esi,[ebx+Menu.ListPtr]		;set choice in list to first one
	xor cl,cl				;set choice to first one
	jmp short .ReturnFromWrap
.3:	cmp dl,13				;Enter pressed?
	je near MenuAcceptChoice		;yes, current choice was accepted
.4:
	ret					;simply return

.MakeUppercase:
	cmp dl,'z'				;if the character is above 'z'
	ja .AlreadyUppercase
	cmp dl,'a'				;or below 'a'
	jb .AlreadyUppercase			;it is already uppercase
	sub dl,32				;otherwise make it uppercase
.AlreadyUppercase:
	ret

.ChoiceFound:	db 0

;------------------------------
; MenuReceiveMouse (dword ptr to menu structure, word mouse row, presses)
; (al=change, ah=choice) - No regs preserved
;
; Decides how to react to mouse input, both movements and clicks
; Moving the mouse over the menu will change to the choice the mouse is over
; Reduced mouse coordinates are passed onto it rather than it directly checking the coordinates
;
MenuReceiveMouse:
%ifdef Debug
	mov [FontColorsPtr],dword FontColors2
	inc word [.MessageWasCalled]
	FontBlitStr .MessageWasCalled,8,170,1
%endif
	mov ebx,[esp+4]				;get menu structure
	mov ax,[esp+8]				;get row
	cmp byte [ebx+Menu.NumChoices],0	;are there any choices in the menu?
	jz near .NoChange			;just return without any change
	movzx ecx,byte [ebx+Menu.CurChoice]	;get current menu choice
	mov esi,[ebx+Menu.ListPtr]		;get ptr to menu choice list
;check pointer to see if it is already over the current choice
	mov dx,[esi+ecx*8+MenuList.Pos]		;get current menu choice's position (toprow)
	cmp ax,dx				;is pointer above choice
	jb .CheckChoices			;look for another choice
	add dx,[ebx+Menu.ChoiceHeight]		;get choice's bottom row
	cmp ax,dx				;is the pointer below the choice
	jge .CheckChoices			;look for another choice
	xor eax,eax				;set return value to null
;check for mouse button presses - if over a valid choice
.CheckButtons:
	test byte [esp+10],1			;check for left mouse button
	jz .End
%ifdef Debug
	PushAll eax,ebx,ecx
	inc word [.MessageChange]
	FontBlitStr .MessageChange,8,190,1
	PullAll eax,ebx,ecx
%endif
	jmp MenuAcceptChoice			;accept the choice
.NoChange:
	xor eax,eax
.End:
	ret

;it looks through all the choices for the choice the pointer is closest to
;starting with last choice and going towards the first
.CheckChoices:
%ifdef Debug
	PushAll eax,esi,ebx
	inc word [.MessageChecked]
	FontBlitStr .MessageChecked,8,180,1
	PullAll eax,esi,ebx
%endif
	movzx ecx,byte [ebx+Menu.NumChoices];get total menu choices
	dec ecx					;start out with one less choice than total
	lea esi,[esi+ecx*8]			;get address of last choice
.NextChoice
	cmp ax,[esi+MenuList.Pos]		;is pointer greater than choice's position
	jae .CheckHeight			;exit loop and check if pointer is not too low
	sub esi,byte Size_MenuList
	dec ecx					;has the last one been checked?
	jns .NextChoice				;no negative sign so more choices to go
	jmp short .NoChange			;!? somehow all choices were checked but no matches
.CheckHeight:
	sub ax,[ebx+Menu.ChoiceHeight]		;get pointer below menu choice's position
	cmp ax,[esi+MenuList.Pos]		;is choice's position less or equal to pointer
	jge .NoChange				;pointer is above choice
	xor eax,eax
	call _MenuSetCurrentChoice.ByChoiceNum ;set the current choice to under the pointer
	jmp .CheckButtons

%ifdef Debug
.MessageWasCalled:	db '00 Call '
.MessageChecked:	db '00 Check'
.MessageChange:		db '00 Change'
%endif
%endif
;				**********
