; The tile and palette converting routines...
;
; TileWindowFill
; TransBplTile

; 2001-05-18
; 2004-02-22 add TransLinear24Bit

;============================================================
; Tile translators
;============================================================

UseTilePattern  equ 1   ;just in case tile pattern code fouls up

;------------------------------
; TileWindowFill (*) - No regs preserved
;
; Refreshes the tile window on the screen
; No parameters are passed on to it; they are all read from static variables.
;
TileWindowFill:
    ;determine height & width
	mov bx,[.TilesHeigh]		;get height and width (bytes)
	mov [.HeightCount],bl		;default is 24 rows heigh
    mov eax,[TileWrap]          ;get tile pixel wrap
    shr eax,3                   ;/8 !!temp
    ;test eax,eax               ;must be at least one column wide
    jz near .End                ;end if not
    cmp al,bh                   ;make sure it is not wider than the max
    jbe .UnderMaxWidth          ;if not, then okay
    mov al,bh                   ;clip to max width
.UnderMaxWidth:
    mov [.TilesPerRow],al       ;save clipped tile window width for later
    mov [.WidthCount],al        ;set width counter

   %if UseTilePattern
    ;get pattern tile
    ;bytes per col = tile pattern cols * tile bytes apart
    ;bytes per row = tile pattern height * cols * tile byte size
    ;bytes per pixel row = cols * tile bytes apart
    movzx eax,byte [TilePattern.Cols]
    movzx ecx,byte [TilePattern.Rows]
    mov [.PatternCol],al        ;set initial pattern column count
    mov [.PatternRow],cl        ;set initial pattern row count
    mov al,byte [TilePattern.Size]
    mov ebx,[TileWrap]          ;get tile pixel width
    mov edx,[TileBytesApart]    ;get bytes per single pixel row
    shr ebx,3                   ;/8 !!temp
    imul ecx,[TileByteSize]     ;pattern rows * tile byte size
    imul eax,edx                ;pattern cols * tile bytes apart
    imul ecx,ebx                ;{pattern rows * tile byte size} * tiles wide
    mov [.BytesPerCol],eax
    imul edx,ebx                ;tiles wide * tile bytes apart
    mov [.BytesPerRow],ecx
    xor eax,eax
    mov [TilePixRowBytes],edx
    mov [.PatternIdx],eax       ;zero pattern index
    mov [.PatternRowIdx],eax    ;zero pattern row index
   %else
    mov edx,[TileWrap]          ;get tile pixel wrap
    shr edx,3                   ;/8 !!temp
    mov ebx,edx                 ;copy tiles per row
    imul ebx,[TileBytesApart]   ;get bytes per pixel row
    mov [TilePixRowBytes],ebx
    imul edx,[TileByteSize]     ;multiply by bytes per tile
    mov [.BytesPerRow],edx      ;save for later
   %endif

    ;set source, source end, destination
	mov ebx,[.Dest]
    mov [.DestColumn],ebx       ;set row destination
    mov [.DestRow],ebx          ;set column destination
    mov eax,[TileBaseByte]      ;get offset in file image
    mov ebx,[LoadedFilePtr]
    add eax,ebx                 ;add ptr of file image to base
    add ebx,[LoadedFileLength]  ;get first byte after file image
	mov [.ByteAfterImage],ebx
    mov [.SourceRow],eax        ;set row source
    mov [.SourceColumn],eax     ;set column source

    push ebp                    ;save ebp since called routine may use it
    cld                         ;all routines read/write forward
.NextTile:
   %if UseTilePattern
    ;get pattern tile
    ;source == column source + pattern offset * tilesize
    mov edx,[.PatternIdx]
    movzx esi,byte [TilePattern+edx]  ;get pattern offset
    inc edx                     ;next pattern index
    imul esi,[TileBytesApart]   ;tile index from pattern * bytes per tile
    mov [.PatternIdx],edx
    add esi,[.SourceColumn]     ;get column source
   %else
    mov esi,[.SourceColumn]     ;get column source
   %endif
    mov edi,[.DestColumn]       ;get column destination
	cmp esi,dword 0
  .ByteAfterImage equ $-4
	jae near .PastFileImage

    call [TileConvertRoutine]   ;here is what does it
.FromBlankTile:
    add dword [.DestColumn],byte 8  ;destination offset, one tile right

   %if UseTilePattern
    ;next column in tile pattern (next tile pattern index)
    dec byte [.PatternCol]
    jg .InPatternWidth
    mov al,[TilePattern.Cols]
    mov esi,[.BytesPerCol]      ;pattern size * bytes per tile
    mov edx,[.PatternRowIdx]
    add [.SourceColumn],esi     ;advance source ptr to next tile pattern
    mov [.PatternIdx],edx
    mov [.PatternCol],al        ;reset tile pattern columns left
.InPatternWidth:
   %else
    mov ebx,[TileBytesApart]    ;get size of each tile
    add dword [.DestColumn],byte 8  ;add destination offset
    add [.SourceColumn],ebx     ;next tile in column source
   %endif
    dec byte [.WidthCount]      ;one less column
    jg .NextTile

   %if UseTilePattern

    mov esi,[.SourceRow]
    dec byte [.PatternRow]
    jg .InPatternHeight
    ;reset tile pattern since last row
    ;row source ptr += pattern height * columns * bytes per tile
    mov al,[TilePattern.Rows]
    xor edx,edx
    add esi,[.BytesPerRow]      ;next source row
    mov [.PatternRowIdx],edx    ;zero pattern index
    mov [.SourceRow],esi
    mov [.PatternRow],al        ;reset tile pattern rows left
    jmp short .SetPatternRow
.InPatternHeight:
    ;next row in tile pattern
    ;row pattern index += 8
    mov edx,[.PatternRowIdx]    ;get row pattern index
    add edx,byte TilePattern.MaxCols
    mov [.PatternRowIdx],edx
.SetPatternRow:
    mov al,[TilePattern.Cols]
    mov [.PatternIdx],edx       ;set pattern index to row index or zero
    mov [.SourceColumn],esi     ;reset column source ptr
    mov [.PatternCol],al        ;reset tile pattern columns left
   %else
    ;advance
    mov esi,[.SourceRow]        ;get row source
    add esi,[.BytesPerRow]      ;move to next row down
    mov [.SourceRow],esi        ;set row source
    mov [.SourceColumn],esi     ;and column source
   %endif
    mov edi,[.DestRow]          ;get row destination
    add edi,8*320               ;next eight rows down in destination
    mov [.DestRow],edi          ;set row destination
    mov [.DestColumn],edi       ;and column destination
    mov al,[.TilesPerRow]       ;get column width
    mov [.WidthCount],al        ;refresh column counter
    dec byte [.HeightCount]     ;one less row
    jg near .NextTile
    pull ebp                    ;restore saved ebp
.End:
	ret

   %if UseTilePattern
.PastFileImage:
	call BlankTile
    jmp .FromBlankTile
   %else
.NextBlankTile:
    mov edi,[.DestColumn]       ;get column destination
.PastFileImage:
	call BlankTile
    add dword [.DestColumn],byte 8  ;add destination offset
    dec byte [.WidthCount]          ;one less column
	jnz .NextBlankTile

    mov edi,[.DestRow]          ;get row destination
    add edi,8*320               ;next eight rows down in destination
    mov [.DestRow],edi          ;set row destination
    mov [.DestColumn],edi       ;and column destination
    mov al,[.TilesPerRow]       ;get column width
    mov [.WidthCount],al        ;refresh column counter
    dec byte [.HeightCount]     ;one less row
	jnz near .NextBlankTile
    ret
   %endif

section .data
align 4
.Dest:          dd 0A0000h+(320*3+4)
.DestColumn:	dd 0A0000h
.DestRow:       dd 0A0000h
.SourceColumn:	dd 0
.SourceRow:     dd 0
.BytesPerRow:	dd 32*16
%if UseTilePattern
.BytesPerCol:   dd 32           ;total bytes in pattern
.PatternRowIdx: dd 0            ;tile index in pattern for current row
.PatternIdx:    dd 0            ;current tile index in pattern
.PatternCol:    db 1            ;columns left in pattern
.PatternRow:    db 1            ;columns rows in pattern
%endif
.TilesPerRow:	db 16
.HeightCount:	db 24
.WidthCount:	db 16
.TilesHeigh:    db ViewWindowMaxTileHeight
.TilesWide:     db ViewWindowMaxTileWidth

align 4
TileRoutineDestWidth:	dd 320
section .text

;------------------------------
; RemakeTilePattern ()
;
; Reconstructs the tile pattern based on the current size.
;
RemakeTilePattern:
    mov ebx,[TilePattern.Rows]
    mov eax,ebx
    imul bh                     ;al (rows) * bh (columns)
    cmp bl,1                    ;if row <= 1 then proceed horizontally
    mov [TilePattern.Size],al
    jbe .Start
    cmp bh,1                    ;if col <= 1 then proceed vertically
    jbe .Start
    ;(row > 1 && col > 1)
    cmp byte [TilePattern+1],1  ;check second tile in pattern
    jbe .Horz
    mov bh,1                    ;pattern is in vertical order
    jmp short .Start
.Horz:
    mov bl,1                    ;pattern is in horizontal order
.Start:
    cld
    mov edi,TilePattern
    mov ecx,TilePattern.MaxRows*TilePattern.MaxCols
    xor eax,eax
.NextRow:
    mov edx,TilePattern.MaxCols
.NextCol:
    stosb
    add al,bl
    dec ecx
    jle .End
    dec edx
    jg .NextCol
    add ah,bh
    mov al,ah
    jmp short .NextRow
.End:
    ret

;------------------------------
; TransBplTile (see registers below) - No regs preserved, not even ebp
;
; This routine works for any SNES bitplane format including 1,2,3,4, & 8. It
; can even work for NES and GameBoy graphics. The GameBoy graphics format is
; already implemented as SNES 2bpl format (since they are both exactly the
; same), while the 2bpl NES format would simply require the correct table to
; be included.
;
; Basically this function loops the number of bitplanes that are in the tile,
; ORing each bitplane onto the current pixel row and rolling them until the
; full color depth for eight pixel columns is achieved. This is not the
; fastest code for translation, but it is the most versatile, being able to
; handle any bitplane format without compromising on too much speed.
;
align 16
TransBplTile:
	mov ecx,[TileBits]			;get bitplanes
	mov ebx,[TileBplPattern]

	;cl=bitplanes
	;ebx=ptr to jump table
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	;edx=bitmap or screen width
	;ebp is destroyed

BitplaneToLinear:
	mov ch,8		;set row counter to 8 rows

.NextRow:
	;cl=bitplane counter
	;ch=data
	;eax=pixel columns 0-3 of current row
	;edx=pixel columns 4-7 of current row

	mov al,cl		;copy bitplanes
	shl ecx,16		;save bitplanes and row counter 
	mov cl,al		;set plane counter to number of planes
	xor edx,edx		;set row to zero
	xor eax,eax

.NextBitplane:
	movsx ebp,byte [ebx]	;move source to next bitplane (same row) using table
	add esi,ebp
	inc ebx
	mov ch,[esi]		;get next bitplane
	
	test ecx,256
	jz .1
	or edx,01000000h
.1:	test ecx,4096
	jz .2
	or eax,01000000h
.2:	test ecx,512
	jz .3
	or edx,00010000h
.3:	test ecx,8192
	jz .4
	or eax,00010000h
.4:	test ecx,1024
	jz .5
	or edx,00000100h
.5:	test ecx,16384
	jz .6
	or eax,00000100h
.6:	test ecx,2048
	jz .7
	or edx,00000001h
.7:	test ecx,32768
	jz .8
	or eax,00000001h
.8:
    ror eax,1   ;roll pixels left to not let the next bitplane clobber this one
	ror edx,1	;rolling right would reverse the the bits, not desirable

	dec cl
	jnz .NextBitplane

	shr ecx,16	;get access to bitplanes and row counter
	rol eax,cl	;you need to compensate for the prior ror's by rolling it
			;left by an equal number of times it was rolled right above,
			;which is the number of bitplanes
	mov [edi],eax	;write first four left pixels
	rol edx,cl	;it stinks that you can not use anything but cl \:-(
	mov [edi+4],edx	;write second four right pixels
	add edi,[TileRoutineDestWidth] ;add bitmap width to dest for next row down

	dec ch
	jnz near .NextRow

	ret

BitplanePtrTable:
		dd .8x8_1,.8x8_1,.8x8_2,.8x8_3,.8x8_4,.8x8_4,.8x8_4,.8x8_4,.8x8_8
.8x8_2NES:	db 0,8,-7,8,-7,8,-7,8,-7,8,-7,8,-7,8,-7,8,1,8,-7,8,-7,8,-7,8,-7,8,-7,8,-7,8,-7,8
.8x8_1:
.8x8_2:		db 0,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1	;eight extra patterns for
		db 1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1	;using taller tile sizes
.8x8_3:		db 0,1,15,-14,1,14,-13,1,13,-12,1,12,-11,1,11,-10,1,10,-9,1,9,-8,1,8
.8x8_4:		db 0,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1
.8x8_8:		db 0,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1

;note that SNES bit modes 1, 2, and GameBoy all use the same table

;------------------------------
; TransMode7Tile (esi,edi) - No regs preserved, not even ebp
;
; Converts SNES mode 7 tiles to a linear bitmap. It does not need to do
; much work though since they already are made of linear 8bit pixels.
;
TransMode7Tile:
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	mov ch,8
;	mov dl,[LinearWidth]
;	shr dl,2			;divide by four
;       mov dl,8/4
        movzx ebx,byte [.Mode7Spacing]
	mov ebp,[TileRoutineDestWidth]
	sub ebp,byte 8
	;cl=column counter
	;ch=row counter
	;dl=column count
	;ebx=interleaved spacing
	;ebp=bitmap or screen width
	;eax=linear data
.NextRow:
;        mov cl,dl               ;copy width to counter
        mov cl,8/4
.NextFourColumns:
	mov al,[esi]	;grab first pixel
	ror eax,8
	mov al,[esi+ebx]
	lea esi,[esi+ebx*2]
	ror eax,8
	mov al,[esi]
	ror eax,8
	mov al,[esi+ebx]
	lea esi,[esi+ebx*2]
	ror eax,8
	stosd			;write group of four column pixels
	dec cl
	jnz .NextFourColumns

	add edi,ebp		;add bitmap width to dest for next row down
	dec ch
	jnz .NextRow
	
	ret

.Mode7Spacing:  db 1

;------------------------------
; TransNibbleTile (esi,edi) - No regs preserved, not even ebp
;
; Seems to work with savestate graphics, but most of the gfx in ROMs are
; annoyingly compressed. 581632 sonic3.smd
;
TransNibbleTile:
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	mov ebp,[TileRoutineDestWidth]
        xor eax,eax
	sub ebp,byte 8
	mov ch,8	;set row counter to 8 rows
	;cl=column counter
	;ch=row counter
	;eax=pixel columns 0-3 of current row
	;ebp=bitmap or screen width
.NextRow:
        mov cl,4
        mov ebx,[esi]
.NextCol:
        mov ah,bl
        shr eax,4
        ror ebx,8
        shr al,4
        xchg al,ah
        stosw
        dec cl
        jnz .NextCol
        add esi,byte 4
	add edi,ebp		;add bitmap width to dest for next row down
	dec ch
	jnz near .NextRow

	ret

%if 0
TransNibbleTile2:
	mov ch,8	;set row counter to 8 rows

.NextRow:
	mov cl,4
	mov ebx,[esi]
	add esi,4
.NextCol:
	mov al,bl
	ror ebx,16
	mov ah,bl
	and ax,0F0Fh
	stosw
	rol ebx,12
	dec cl
	jnz .NextCol

	add edi,320-8 ;add bitmap width to dest for next row down

	dec ch
	jnz near .NextRow

	ret
%endif

;------------------------------
; TransFxGfxTile (esi,edi) - No regs preserved
;
; Converts SNES fx chip graphics into a linear bitmap.
;
TransFxGfxTile:
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
    mov ebp,[TileRoutineDestWidth]
	mov ch,8
	mov cl,[.Shift]
    mov edx,[TilePixRowBytes]
	;cl=shift
	;ch=row counter
    ;edx=source wrap
    ;ebp=bitmap or screen width
	;eax=linear data
.NextRow:
	mov eax,[esi]
	shr eax,cl
	and eax,0F0F0F0Fh
	mov [edi],eax
	mov eax,[esi+4]
	shr eax,cl
	and eax,0F0F0F0Fh
	mov [edi+4],eax
    ;add esi,256
    add esi,edx
    add edi,ebp             ;add bitmap width to dest for next row down
	dec ch
	jnz .NextRow
	ret

.Shift:	db 0

;------------------------------
; TransN64Gfx24bit (esi,edi) - No regs preserved
;
; Converts N64 true color graphics into a 216 color bitmap.
;
TransN64Gfx24bit:
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	mov ebp,[TileRoutineDestWidth]
	sub ebp,byte 8
    mov edx,[TilePixRowBytes]
    sub edx,byte 32
    xor ebx,ebx
    ;cl=column counter
	;ch=row counter
    ;edx=source wrap
    ;ebp=bitmap or screen width
    ;eax=rgb pixel data
    mov ch,8
.NextRow:
    mov cl,8
.NextCol:
    lodsd
    mov bl,ah
    mov ah,[Palette.GreenTable+ebx]
    mov bl,al
    add ah,[Palette.RedTable+ebx]
    shr eax,8
    mov bl,ah
    add al,[Palette.BlueTable+ebx]
    stosb
    dec cl
    jnz .NextCol
    add esi,edx
	add edi,ebp		;add bitmap width to dest for next row down
	dec ch
	jnz .NextRow
        ret

;------------------------------
; TransN64Gfx15bit (esi,edi) - No regs preserved
;
; Converts N64 high color graphics into a 216 color bitmap.
;
; bit 0 = transparency   bits 1-5 = blue   bits 6-10 = green   bits 11-15 = red
;
TransN64Gfx15bit:
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	mov ebp,[TileRoutineDestWidth]
	sub ebp,byte 8
    mov edx,[TilePixRowBytes]
    sub edx,byte 16
    xor ebx,ebx
    ;cl=column counter
	;ch=row counter
    ;edx=source wrap
    ;ebp=bitmap or screen width
    ;eax=rgb pixel data
    mov ch,8
.NextRow:
    mov cl,8
.NextCol:
    lodsw
    mov bl,al
    and bl,111110b
    shl ebx,2
    mov al,[Palette.BlueTable+ebx]
    mov ebx,eax
    and ebx,11111000000b
    shr ebx,3
    add al,[Palette.GreenTable+ebx]
    mov bl,ah
    and bl,11111000b
    add al,[Palette.RedTable+ebx]
    stosb
    dec cl
    jnz .NextCol
    add esi,edx
	add edi,ebp		;add bitmap width to dest for next row down
	dec ch
	jnz .NextRow
    ret

;------------------------------
; TransLinear2Bit (esi,edi) - No regs preserved
;
; Expands packed 2bit pixels into 8bit.
;
TransLinear2bit:
%if 1;BigEndian
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	mov ebp,[TileRoutineDestWidth]
	sub ebp,byte 8
    mov edx,[TilePixRowBytes]
    xor eax,eax
    ;cl=column counter
	;ch=row counter
    ;ebp=bitmap or screen width
    ;edx=source wrap
    ;eax=rgb pixel data
    mov ch,8
.NextRow:
    mov cl,2
    mov bx,[esi]
    shl ebx,8
.NextCol:
    mov bl,bh
    mov eax,ebx
    shr al,2
    rol eax,16
    mov ax,bx
    shr al,6
    shr ah,4
    and eax,03030303h
    stosd
    shr ebx,8
    dec cl
    jnz .NextCol
    add esi,edx
	add edi,ebp		;add bitmap width to dest for next row down
	dec ch
	jnz .NextRow
    ret
%else
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	mov ebp,[TileRoutineDestWidth]
	sub ebp,byte 8
    mov edx,[TilePixRowBytes]
    xor eax,eax
    ;cl=column counter
	;ch=row counter
    ;ebp=bitmap or screen width
    ;edx=source wrap
    ;eax=rgb pixel data
    mov ch,8
.NextRow:
    mov cl,2
    mov bx,[esi]
    shl ebx,8
.NextCol:
    mov bl,bh
    mov eax,ebx
    shr al,4
    shr ah,6
    rol eax,16
    mov ax,bx
    shr ah,2
    ;shr ah,4
    and eax,03030303h
    stosd
    shr ebx,8
    dec cl
    jnz .NextCol
    add esi,edx
	add edi,ebp		;add bitmap width to dest for next row down
	dec ch
	jnz .NextRow
    ret
%endif

;------------------------------
; TransLinear4Bit (esi,edi) - No regs preserved
;
; Expands packed 4bit pixels into 8bit.
;
; bits 0-3 = right pixel  bits 4-7 = left pixel
;
TransLinear4bit:
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	mov ebp,[TileRoutineDestWidth]
	sub ebp,byte 8
    mov edx,[TilePixRowBytes]
    xor eax,eax
    ;cl=column counter
	;ch=row counter
    ;ebp=bitmap or screen width
    ;edx=source wrap
    ;eax=rgb pixel data
    mov ch,8
.NextRow:
    mov cl,4
    mov ebx,[esi]
.NextCol:
    mov ah,bl
    shr eax,4
    ror ebx,8
    shr al,4
    xchg al,ah
    stosw
    dec cl
    jnz .NextCol
    add esi,edx
	add edi,ebp		;add bitmap width to dest for next row down
	dec ch
	jnz .NextRow
    ret

;------------------------------
; TransLinear8Bit (esi,edi) - No regs preserved
;
; Doesn't do much except a straight blit.
;
TransLinear8bit:
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
    mov edx,[TilePixRowBytes]
	mov ebp,[TileRoutineDestWidth]
    sub edx,byte 8
	sub ebp,byte 8
    ;cl=row counter
    ;ebp=bitmap or screen width
    ;edx=source wrap
    mov cl,8
.NextRow:
    movsd
    movsd
    add esi,edx
	add edi,ebp		;add bitmap width to dest for next row down
    dec cl
	jnz .NextRow
    ret

;------------------------------
; TransLinear24Bit (esi,edi) - No regs preserved
;
; Converts N64 true color graphics into a 216 color bitmap.
;
TransLinear24Bit:
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	mov ebp,[TileRoutineDestWidth]
	sub ebp,byte 8
    mov edx,[TilePixRowBytes]
    sub edx,byte 32
    xor ebx,ebx
    ;cl=column counter
	;ch=row counter
    ;edx=source wrap
    ;ebp=bitmap or screen width
    ;eax=rgb pixel data
    mov ch,8
.NextRow:
    mov cl,8
.NextCol:
    lodsd
    mov bl,ah
    mov ah,[Palette.GreenTable+ebx]
    mov bl,al
    add ah,[Palette.RedTable+ebx]
    shr eax,8
    mov bl,ah
    add al,[Palette.BlueTable+ebx]
    dec esi         ;one byte back
    stosb
    dec cl
    jnz .NextCol
    add esi,edx
	add edi,ebp		;add bitmap width to dest for next row down
	dec ch
	jnz .NextRow
    ret

;------------------------------
; TransVbTile (esi,edi) - No regs preserved
;
; Expands packed 2bit pixels into 8bit.
;
TransVbTile:
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	mov ebp,[TileRoutineDestWidth]
    xor eax,eax
	sub ebp,byte 8
	mov ch,8	;set row counter to 8 rows
	;cl=column counter
	;ch=row counter
	;eax=pixel columns 0-3 of current row
	;ebp=bitmap or screen width
.NextRow:
    mov cl,2
    mov bx,[esi]
    shl ebx,8
.NextCol:
    mov bl,bh
    mov eax,ebx
    shr al,4
    shr ah,6
    rol eax,16
    mov ax,bx
    shr ah,2
    ;shr ah,4
    and eax,03030303h
    stosd
    shr ebx,8
    dec cl
    jnz .NextCol
    add esi,byte 2
	add edi,ebp		;add bitmap width to dest for next row down
	dec ch
	jnz near .NextRow
	ret

;------------------------------
; BlankTile - No regs preserved, except ebp
;
BlankTile:
	mov ecx,8
	mov eax,(GuiColorGray)|(GuiColorBlack<<8)|(GuiColorGray<<16)|(GuiColorBlack<<24)
	mov edx,[TileRoutineDestWidth]
.NextRow:
	mov dword [edi],eax
	mov dword [edi+4],eax
	add edi,edx
	rol eax,8
	dec ecx
	jnz .NextRow
	ret

;============================================================
; Palette Conversion
;============================================================

;------------------------------
; PaletteConvertSnesCgram - (esi=source)
;
; Converts a 15bit (32 RGB shade) SNES savestate palette to a 24bit (64 RGB
; shade) palette. CGRAM is located at 1560 in a ZSNES savestate.
;
PaletteConvertSnesCgram:
	mov edi,ScreenPalette	;dest is the palette
    ;test edi,edi            ;has one been allocated?
    ;jz .End                 ;croak if not
.AnyDest:
	mov edx,256			;the SNES has a 256-color palette
    ;mov cl,2                        ;for now, just turn 32 shade SNES into 64 shade VGA
	cld				;as always, go forward
.NextColor:
	lodsw				;get BGR color tuple (the SNES color is reversed from normal)
	shl eax,3			;isolate red
    ;shr al,cl                       ;divide by factor
	stosb				;save red to destination
	shr eax,5			;get green and blue
    and eax,(31<<3)|(31<<8)         ;mask out any extra bits
	shl ah,3			;move blue higher
    ;shr eax,cl                      ;divide both by factor
	stosw				;store green and blue
	dec edx
	jnz .NextColor
.End:
	ret
