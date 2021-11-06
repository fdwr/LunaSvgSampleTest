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
; (eax=color dword)
; Works only for 8-bit modes, like mode 13h:320x200.
ClearScreen:
    cld
    mov edi,[Display.BasePtr]
    mov ecx,[Display.Width]
    imul ecx,[Display.Height]
    shr ecx,2                   ; / 4 bytes per dword
    rep stosd
    ret

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


section data
align 4
PrintCharString.Attributes:    dw 8|(5<<8)             ;character height/width/
PrintCharString.Color:         dw 11                   ;and color
section code

;------------------------------
; Print standard character string
; (ptr32 TextPtr, uint16 TopRow, uint16 LftCol)
; Blits a sequence of characters by calling the specified routine to blit each character.
;
PrintCharStringStd:
    mov esi,[esp+4]         ;get text ptr
    movzx ecx,word [esp+8]  ;get row
    movzx edx,word [esp+10] ;get column
    mov edi,ecx
    imul edi,[Display.Width]
    add edi,edx             ;add left column to destination
    add edi,[Display.BasePtr]
    jmp short .FirstChar    ;test at bottom of loop
.NextChar:
    push edi
    push esi
    mov ebx,[PrintCharString.Attributes]
    mov edx,[Display.Width]
    add edx,byte -GuiFont.GlyphPixelWidth         ;each character is 5 pixels wide
    lea esi,[GuiFont.Chars+eax*8]
    call FontMonochromeChar
    pop esi
    pop edi
    inc esi                 ;next character
    add edi,byte GuiFont.GlyphPixelWidth + 1
.FirstChar:
    movzx eax,byte [esi]
    test eax,eax
    jnz .NextChar
.End:
    ret

;section data
;.BlitRoutine:   dd FontMonochromeChar
;.FontSet:       dd DefaultFont
;section code

;------------------------------
; (ptr32 Source, uint16 TopRow, uint16 LeftCol, uint16 height, uint16 width)
PrintControlString:
    mov esi,[esp+4]         ;get text ptr
    movzx ecx,word [esp+8]  ;get row
    movzx edx,word [esp+10] ;get column
    mov ebx,[Display.Width]
    mov edi,ecx
    imul edi,ebx
    add edi,edx             ;add left column to destination
    add edi,[Display.BasePtr]
    xor ecx,ecx             ;zero column counter
    mov [esp+8],edi         ;replace row/col with destination
    jmp short .FirstChar

.NextChar:
    inc esi                 ;next character
    inc ecx                 ;next column count
.FirstChar:
    movzx eax,byte [esi]
    cmp al,32
    jb .ControlCharacter
    test al,al
    js .ControlCode

; (esi=source, eax=character, ecx=column) (esi, ecx)
.BlitCharacter:
    cmp cl,[esp+14]         ;verify column within constrained width
    jae .NextChar
    push ecx
    push esi
    push edi
    push ebx                ;display width
    lea edx,[ebx-5]
    mov ebx,[PrintCharString.Attributes]
    lea esi,[GuiFont.Chars+eax*8]
    call FontMonochromeChar
    pop ebx
    pop edi
    pop esi
    pop ecx
    add edi,byte 6
    jmp short .NextChar

; (esi=source, eax=character, ecx=column) (esi, ecx)
.ControlCharacter:
    cmp al,10               ;carriage return
    je .IsNewLine
    test al,al              ;null
    je .End
    cmp al,13               ;carriage return
    jne .BlitCharacter      ;any other control character will be drawn
    cmp [esi+1],byte 10     ;check for trailing line feed for a CR LF pair
    jne .IsNewLine
    inc esi                 ;skip the LF to avoid a doubled line later
.IsNewLine:
    dec byte [esp+12]       ;one less row
    jz .End
    mov eax,ebx             ;get wrap width
    mov edi,[esp+8]
    imul eax,GuiFont.GlyphPixelHeight+1
    add edi,eax             ;next row
    xor ecx,ecx             ;zero column counter
    mov [esp+8],edi         ;retupdaterieve destination for the current row.
    jmp short .NextChar

; (esi=source, eax=character)
.ControlCode:
    sub al,128
    mov [PrintCharString.Color],al
    jmp short .NextChar
.NotNewColor:
    cmp al,0
    jne .NextChar

.End:
    ret

;------------------------------
; DrawBox (uint16 TopRow, uint16 BtmRow, uint16 LeftCol, uint16 RiteCol, uint8 Color) () - No regs preserved
;
; This routine clips finally (and beautifully too).
; It could theoretically work in any linear 8bit resolution.
;
DrawBox:
    movzx edi,word [esp+4]  ;get top row
    mov edx,[Display.Width]
    movzx eax,word [esp+4+2] ;get left column
    imul edi,edx
    add edi,eax
    mov ebx,[esp+8]         ;get width and height
    add edi,[Display.BasePtr];set to screen
    mov al,[esp+12]         ;get color

.ByReg: ; (edi=destination, bx=height, upper ebx=width, edx=row stride, al=color)
    mov ecx,ebx             ;copy width and height
    shr ecx,16              ;get width
    neg ecx                 ;negate width
    add edx,ecx             ;stride -= width

    mov ah,al               ;copy color to second byte
    mov ecx,eax             ;make a copy
    shl eax,16              ;shift into upper part
    mov ax,cx               ;put copy back
    ;eax now consists of four pixels all the same color

    xor ecx,ecx             ;zero out top 17 bits
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
; (uint16 toprow, uint16 leftcolumn, uint16 height, uint16 width)
;
DrawBorder:
;!!! todo:
.Top equ 4
.Left equ 6
.Height equ 8
.Width equ 10
.Color equ 12   ; 4 bytes, top, left, bottom, right
    movzx ebx,word [esp+.Top]
    movzx edx,word [esp+.Left]
    movzx ecx,word [esp+.Width]
    dec ebx
    dec edx
    ; Draw top line
    add ecx,byte 2
    mov al,GuiColorBottom
    call BlitLineFast.Horizontal
    ;dec ebx
    ;mov al,GuiColorMidBottom
    ;call BlitLineFast.Horizontal
    add bx,[esp+.Height]
    ;add ebx,byte 2
    ; Draw bottom line
    inc ebx
    ;mov al,GuiColorTop
    mov al,GuiColorMidTop
    call BlitLineFast.Horizontal
    ;inc ebx
    ;mov al,GuiColorMidTop
    ;call BlitLineFast.Horizontal

    movzx ebx,word [esp+.Top]
    movzx ecx,word [esp+.Height]
    ;dec ebx
    ;add ecx,byte 2
    ; Draw left line
    mov al,GuiColorBottom
    call BlitLineFast.Vertical
    ;dec edx
    ;mov al,GuiColorMidBottom
    ;call BlitLineFast.Vertical
    add dx,[esp+.Width]
    ;add edx,byte 2
    ; Draw right line
    inc edx
    mov al,GuiColorTop
    call BlitLineFast.Vertical
    ;inc edx
    ;mov al,GuiColorMidTop
    ;call BlitLineFast.Vertical
    ret

;------------------------------
; (al=color, ebx=row, edx=column, ecx=line_length) ()
;
BlitLineFast:
.Horizontal:
    mov ah,al
    shrd esi,eax,16
    shld eax,esi,16
    cmp ebx,[Display.Height]
    jae .End
    cmp edx,[Display.Width]
    jae .End
    lea edi,[edx+ecx]
    cmp edi,[Display.Width]
    ja .End
    push ecx                ;save row
    cld
    mov edi,ebx             ;row*width
    imul edi,[Display.Width]
    add edi,edx             ;add left column to destination
    mov esi,ecx             ;copy length to spare register
    add edi,[Display.BasePtr]
    shr ecx,2
    rep stosd
    mov ecx,esi             ;get length once more
    and ecx,3               ;write any odd leftover bytes after the 32bit words.
    rep stosb
    pop ecx
    ret
.Vertical:
    push ecx
    mov esi,[Display.Width]
    mov edi,ebx
    imul edi,[Display.Width]
    add edi,edx             ;add left column with destination
    add edi,[Display.BasePtr]
.NextRow:
    mov [edi],al
    add edi,esi
    dec ecx
    jnz .NextRow
    pop ecx
.End:
    ret

;------------------------------
; (uint16 TopRow, uint16 LeftCol, uint16 Height, uint16 Width, uint8 Color)
; Draws a singled colored box.
;
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
    imul edi,[Display.Width];plus *256
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
.ByReg:                     ;calling by register can be a bit faster
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
    shr eax,8               ;next color byte in color dword
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
    mov edi,[WinDos.displayMemoryBase]
    mov ecx,[Display.Width]
    imul ecx,[Display.Height]
    shr ecx,2                   ; / 4 bytes per dword
    rep movsd
    %ifdef WinVer
        api InvalidateRect, [WinDos.hwnd], NULL, 0
        debugwrite "DisplayToScreen"
    %endif
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
    mov ecx,[Display.Width] ;set number of columns (and bytes to write per row)
    mov edx,[Display.Height] ;set number of rows
    mov [.BmpHeader_Width],ecx
    mov [.BmpHeader_Height],edx

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
.NextColor:                 ;can't use insb because Window's bitmaps
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

    mov edi,[.BmpHeader_Height] ;set number of rows
    mov ecx,[.BmpHeader_Width] ;set bytes to write per row
    lea edx,[edi-1]         ;subtract one from height because we start from the bottom row
    imul edx,ecx            ;(height-1)*width
    add edx,[Display.BasePtr] ;set source data for file write
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

section data
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
section code
%endif
