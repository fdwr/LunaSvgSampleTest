; ClearScreen
; FontMonochromeChar
; PrintCharString
; PrintCharStringStd
; PrintControlString
; DrawBorder
; BlitLineFast
; DrawRect
; DrawPatternBox
; DisplayToScreen
; SaveSnapshot

;--------------------------------------------------
; GRAPHICS
;--------------------------------------------------

;------------------------------
; Works only for mode 13h:320x200 (eax=color dword)
ClearScreen:
    cld
    ;mov edi,0A0000h
    mov edi,[Display.BasePtr]
    mov ecx,(Screen.Height*Screen.Width)>>2
    rep stosd
    ret

;------------------------------
; (TopRow, BtmRow, LftCol, RitCol, RowOffset, ColOffset)
;
%if 0
ScrollScreenWindow:
    cld
    mov esi,0A0000h+321
    mov edi,0A0000h+321
    mov ebx,200
    mov eax,30
.NextLine:
    mov ecx,ebx
    shr ecx,2
    rep movsd
    mov ecx,ebx
    and ecx,3
    rep movsb
    add esi,edx
    add edi,edx
    dec eax
    jnz .NextLine
    ret
%endif

;------------------------------
; (esi, edi, ebx, edx)
; Blits a single colored, transparent character to any 8bit destination.
;
; Initial regs:
; esi=font character bitmask
; edi=destination on screen or buffer
; edx=destination width minus character width
;  bl=character rows
;  bh=character columns
; ebl=pixel color (0-255)
;
align 16
FontMonochromeChar:
    mov ch,bl
    shr ebx,8
; Regs:
;  bl=character columns
;  bh=pixel color
;  ch=row counter
;  cl=column counter
;  edi=screen destination
;  esi=character bits
;  edx=screen wrap
    cld                     ;set direction forward!
.NextRow:
    mov cl,bl
    lodsb
.NextCol:
    shl al,1
    jnc .ClearPixel
    mov [edi],bh
.ClearPixel:
    inc edi
    dec cl
    jnz .NextCol
    add edi,edx
    dec ch
    jnz .NextRow
.Clipped:
    ret

;------------------------------
; (TopRow, LftCol, FontSet)
; Blits a sequence of characters by calling the specified routine to blit each character.
;
PrintCharString:
    ;call [.BlitRoutine]
    ;next character
    ;add size of font character to pixel column
    ;ret

align 4
;.BlitRoutine:   dd FontMonochromeChar
.Attributes:    dw 8|(5<<8)             ;character height/width/
.Color:         dw 11                   ;and color

;------------------------------
; Print standard character string
; (TextPtr, TopRow, LftCol)
; Blits a sequence of characters by calling the specified routine to blit each character.
;
PrintCharStringStd:
    mov esi,[esp+4]         ;get text ptr
    movzx ecx,word [esp+8]  ;get row
    movzx edx,word [esp+10] ;get column
    mov edi,ecx             ;can only do this if screenwidth is 320 pix
    shl ecx,6               ;*64
    shl edi,8               ;plus *256
    add edi,ecx             ;makes *320
    add edi,edx             ;add left column to destination
    add edi,[Display.BasePtr]
    jmp short .FirstChar    ;test at bottom of loop
.NextChar:
    push edi
    push esi
    mov ebx,[PrintCharString.Attributes]
    mov edx,320-5
    lea esi,[GuiFont.Chars+eax*8]
    call FontMonochromeChar
    pop esi
    pop edi
    inc esi                 ;next character
    add edi,byte 6
.FirstChar:
    movzx eax,byte [esi]
    test eax,eax
    jnz .NextChar
.End:
    ret

;.BlitRoutine:   dd FontMonochromeChar
;.FontSet:       dd DefaultFont

;------------------------------
; (dword Source, word TopRow, word LftCol)
PrintControlString:
    mov esi,[esp+4]         ;get text ptr
    movzx ecx,word [esp+8]  ;get row
    movzx edx,word [esp+10] ;get column
    mov edi,ecx             ;can only do this if screenwidth is 320 pix
    shl ecx,6               ;*64
    shl edi,8               ;plus *256
    add edi,ecx             ;makes *320
    add edi,edx             ;add left column to destination
    add edi,[Display.BasePtr]
    mov [esp+8],edi         ;replace row/col with destination
    jmp short .FirstChar

.NextCharBlit:
    push edi
    push esi
    mov ebx,[PrintCharString.Attributes]
    mov edx,320-5
    lea esi,[GuiFont.Chars+eax*8]
    call FontMonochromeChar
    pop esi
    pop edi
    add edi,byte 6

.NextChar:
    inc esi                 ;next character
.FirstChar:
    movzx eax,byte [esi]
    cmp al,1
    jns .NextCharBlit
    cmp al,129
    jne .NotNewLine
    dec byte [esp+12]       ;one less row
    jz .End
    add dword [esp+8],320*8 ;can only do this if screenwidth is 320 pix
    mov edi,[esp+8]
    jmp short .NextChar
.NotNewLine:
    jb .NotNewColor
    sub al,130
    mov [PrintCharString.Color],al
    jmp short .NextChar
.NotNewColor:
    cmp al,0
    jne .NextChar
.End:
    ret

;------------------------------
; DrawBox (words TopRow, BtmRow, LeftCol, RiteCol, Color) () - No regs preserved
;
; This routine clips finally (and beautifully too).
; It could theoretically work in any linear 8bit resolution.
;
DrawBox:
	movzx edi,word [esp+4]	;get top row
	mov edx,[Display.Width]
	movzx eax,word [esp+4+2]	;get left column
	imul edi,edx
	add edi,eax
	mov ebx,[esp+8]		;get width and height
	add edi,[Display.BasePtr];set to screen

.ByReg:	; (edi=destination, bx=height, upper ebx=width, edx=row stride)
	mov ecx,ebx		;copy width and height
	shr ecx,16		;get width
	neg ecx			;negate width
	add edx,ecx		;stride -= width

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
; (words toprow, leftcolumn, height, width)
;
DrawBorder:
    movzx ebx,word [esp+4]
    movzx edx,word [esp+6]
    movzx ecx,word [esp+10]
    dec ebx
    dec edx
    add ecx,byte 2
    mov al,GuiColorBtm
    call BlitLineFast.Horizontal
    ;dec ebx
    ;mov al,GuiColorMidBtm
    ;call BlitLineFast.Horizontal
    add bx,[esp+8]
    ;add ebx,byte 2
    inc ebx
    mov al,GuiColorTop
    call BlitLineFast.Horizontal
    ;inc ebx
    ;mov al,GuiColorMidTop
    ;call BlitLineFast.Horizontal

    mov bx,[esp+4]          ;get row
    mov cx,[esp+8]          ;get height
    ;dec ebx
    ;add ecx,byte 2
    mov al,GuiColorBtm
    call BlitLineFast.Vertical
    ;dec edx
    ;mov al,GuiColorMidBtm
    ;call BlitLineFast.Vertical
    add dx,[esp+10]
    ;add edx,byte 2
    inc edx
    mov al,GuiColorTop
    call BlitLineFast.Vertical
    ;inc edx
    ;mov al,GuiColorMidTop
    ;call BlitLineFast.Vertical
    ret

;------------------------------
; al=color, ebx=row, edx=column, ecx=line_length
;
BlitLineFast:
.Horizontal:
    mov ah,al
    shrd esi,eax,16
    shld eax,esi,16
;        cmp ebx,Screen.Height
;        jae .End
;        cmp edx,Screen.Width
;        jae .End
;        lea edi,[edx+ecx]
;        cmp
    push ecx                ;save row
    cld
    mov esi,ebx
    mov edi,ebx             ;can only do this if screenwidth is 320 pix
    shl esi,6               ;*64
    shl edi,8               ;plus *256
    add edi,esi             ;makes *320
    add edi,edx             ;add left column to destination
    add edi,[Display.BasePtr]
    mov esi,ecx             ;copy length
    shr ecx,2
    rep stosd
    mov ecx,esi             ;get length once more
    and ecx,3
    rep stosb
    pop ecx
    ret
.Vertical:
    push ecx
    mov esi,ebx
    mov edi,ebx             ;can only do this if screenwidth is 320 pix
    shl esi,6               ;*64
    shl edi,8               ;plus *256
    add edi,esi             ;makes *320
    add edi,edx             ;add left column with destination
    add edi,[Display.BasePtr]
    mov esi,[Display.Width]
.NextRow:
    mov [edi],al
    add edi,esi
    dec cl
    jnz .NextRow
    pop ecx
.End:
    ret

;------------------------------
; (TopRow, LeftCol, Height, Width, Color)
; Draws a singled colored box.
;
%if 0
DrawRect2.End:
    ret
DrawRect2:
    movsx edi,word [esp+4]  ;get TopRow
    movzx esi,word [esp+8]  ;get Height
    test edi,edi            ;check if row < 0
    jns .RowWithinTop       ;continue if row is positive
    add esi,edi             ;ClippedHeight = Height + TopRow
    jbe .End                ;end if width is zero or negative
    xor edi,edi             ;set top row to zero
  .RowWithinTop:
    lea ecx,[esi+edi]       ;BottomRow + 1 = TopRow + Height
    sub ecx,[Display.Height];get difference of bottom row and screen height
    jle .RowWithinBottom    ;continue if bottom row within screen height
    sub esi,ecx             ;ClippedHeight = Height - (BottomRow-ScreenHeight)
    jbe .End                ;end if width is zero negative
  .RowWithinBottom:

    mov edx,[Display.Width] ;get ScreenWidth
    movsx eax,word [esp+6]  ;get LeftColumn
    movzx ebx,word [esp+10] ;get Width
    imul edi,edx            ;Destination = TopRow * ScreenWidth
    test eax,eax            ;check if column < 0
    jns .ColumnWithinLeft   ;continue if column is positive
    add ebx,eax             ;ClippedWidth = Width + LeftColumn
    jbe .End                ;end if width is zero or negative
    xor eax,eax             ;set left column to zero
  .ColumnWithinLeft:
    lea ecx,[eax+ebx]       ;RightColumn = LeftColumn + Width
    sub ecx,edx             ;get difference of right column and screen width
    jle .ColumnWithinRight  ;continue if right column within width
    sub ebx,ecx             ;ClippedWidth = Width - (RightColumn-ScreenWidth)
    jbe .End                ;end if width is zero or negative
  .ColumnWithinRight:
    sub edx,ebx             ;WrapWidth = ScreenWidth - BoxWidth

    ;put width in high word of ebx and height in lower word
    shl ebx,16              ;keep width in safe upper part of ebx
    add edi,[Display.BasePtr]
    add edi,eax             ;add left column to Destination
    mov bx,si               ;keep height in bx

    mov al,[esp+12]         ;get color
.ByReg:                     ;calling by register can be a bit faster
    mov ah,al               ;copy color to second byte
    shrd esi,eax,16
    xor ecx,ecx             ;zero out top 17 bits for loop
    shld eax,esi,16
    ;eax now consists of four pixels all the same color
    cld                     ;as always, go forward
.NextLine:
    shld ecx,ebx,14         ;get width divided by 4
    rep stosd
    shld ecx,ebx,16         ;get width
    and ecx,3               ;get modulus 4
    rep stosb
    add edi,edx
    dec bx
    jnz .NextLine
    ret
%endif

DrawRect:
    mov bx,[esp+10]         ;get width
    mov edx,[Display.Width] ;get screen width
    xor ecx,ecx
    sub dx,bx               ;get wrap width
    movzx eax,word [esp+6]  ;get leftcol

    shl ebx,16              ;keep width in safe part of bx
    mov cx,[esp+4]          ;get toprow
    mov bx,[esp+8]          ;get height
    ;height is now in lower part and width in higher part of ebx

    mov edi,ecx             ;make a copy of toprow
    shl ecx,6               ;*64
    shl edi,8               ;plus *256
    add edi,ecx             ;makes *320
    add edi,eax             ;add left column to destination
    add edi,[Display.BasePtr]
    mov al,[esp+12]         ;get color
.ByReg:                     ;calling by register can be a bit faster
    mov ah,al               ;copy color to second byte
    shrd esi,eax,16
    xor ecx,ecx             ;zero out top 17 bits for loop
    shld eax,esi,16
    ;eax now consists of four pixels all the same color
    cld                     ;as always, go forward
.NextLine:
    shld ecx,ebx,14         ;get width divided by 4
    rep stosd
    shld ecx,ebx,16         ;get width
    and ecx,3               ;get modulus 4
    rep stosb
    add edi,edx
    dec bx
    jnz .NextLine
.End:
    ret

;------------------------------
; (edi=destination, edx=dest wrap, ebx=size, eax=color dword)
;
DrawPatternBox:
.ByReg:                         ;calling by register can be a bit faster
    cld                     ;as always, go forward
    mov ecx,edi
    shl cl,3                ;multiply odd bit times 8
    ;lea ecx,[edi*8]
    rol eax,cl              ;roll pixels if odd destination
    xor ecx,ecx             ;zero out top 17 bits for loop
.NextLine:
    shld ecx,ebx,14         ;get width divided by 4
    rep stosd
    shld ecx,ebx,16         ;get width
    and ecx,3               ;modulus 4
    jz .NoEndPixels
    push eax
.NextPixel:
    stosb
    shr eax,8
    dec ecx
    jnz .NextPixel
    pop eax
.NoEndPixels:
    add edi,edx
    rol eax,8
    dec bx
    jnz .NextLine
.End:
    ret

;------------------------------
;
DisplayToScreen:
    cld
    mov esi,Display.Buffer
    mov edi,0A0000h
    mov ecx,(Screen.Height*Screen.Width)/4
    rep movsd
    ret

;------------------------------
; Given a palette to reduce, the number of colors in the source, and the
; number of colors to reduce it to, it will produce a secondary palette and
; color pointer table. The table can be used to index a color to its nearest
; match in the output palette.
;
;PaletteReduce:
    ;start from first color looking for exact matches (matches with zero
    ;difference). add each find to small table. if the number of minimum
    ;difference finds plus those already found equals the number necessary
    ;to reduce the source palette to fit in the destination, then quit.
    ;ret

;------------------------------
%if Personal                ;leave out this code for public release
SaveSnapshot:
    ;open file
    mov edx,.OutputFile     ;set ptr to filename for DOS call
    mov ax,3C00h            ;create new file (or overwrite existing)
    xor ecx,ecx             ;no special file attributes, set to zero
    int 21h                 ;call DOS to open file
    jc near .ErrorOpeningFile ;if error opening snapshot pcx for output
    ;push eax                ;save file hdnale

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
    sub esp,1024            ;256 colors * 4 bytes per color entry
    mov edi,esp             ;set destination
    mov ecx,256             ;total colors
.NextColor:                     ;can't use insb because Window's bitmaps
    xor eax,eax             ; stores RGB as BGR instead
    in al,dx                ;get red
    shl eax,8
    in al,dx                ;get green
    shl eax,8
    in al,dx                ;get blue
    shl eax,2               ;multiply shade by 4
    stosd
    dec ecx
    jnz .NextColor
    mov ecx,1024            ;256 colors * 4 bytes per color entry
    mov edx,esp             ;set source data for write
    mov ax,4000h            ;function to write to file
    int 21h                 ;call DOS
    add esp,1024            ;256 colors * 4 bytes per color entry

    mov edx,199*320+0A0000h ;set source data for write
    mov edi,200             ;set number of rows
    mov ecx,320             ;set bytes to write per row
.NextRow:
    mov ax,4000h            ;function to write to file
    int 21h                 ;call DOS
    sub edx,ecx
    dec edi
    jnz .NextRow

.ErrorWritingToFile:
    mov ax,3E00h            ;function to close file
    ;pop ebx                 ;get snapshot file's handle
    int 21h                 ;call DOS
.ErrorOpeningFile:
    ret

.OutputFile:
    db 'snapshot.bmp',0
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
    dd (1078+64000)/4       ;file size in dwords
    dd 0                    ;reserved
    dd 1078                 ;byte offset to bitmap data

    dd 40                   ;size of header (Windows bitmap)
.BmpHeader_Width:
    dd 320                  ;width
.BmpHeader_Height:
    dd 200                  ;height
    dw 1                    ;pixel planes
    dw 8                    ;bits per pixel
    dd 0                    ;compression
.BmpHeader_ImageSize:
    dd 320*200              ;byte size of image
    dd 0,0                  ;pixels per meter, X and Y
    dd 0                    ;all 256 colors used
    dd 0                    ;number of important colors, all of them

;.Header_Len equ 128             ;pcx
.Header_Len equ 54
%endif
