; SpriteView - console graphics viewer
;   (c)2003 Peekin (Dwayne Robinson)
;   Compiled with Nasm 0.97 and WdosX 0.95
;
; The main code is in 'sv.asm' (the one you are reading right now).
; Essential definitions and macros are in 'sv.mac'
; All of the helper routines for this prog are contained in 'sv.inc'.
; And the tile converting routines are in 'svtile.inc'
;
; The memory and system exiting functions are contained in 'memory.inc' and
; 'system.inc'. Thanks to Gaz for them.
;
; Most routines do not save all the registers; it is up to the caller to do that.
; The selectors are always preserved, and ebp is also preserved unless specified.
;
; This contains all the large functions and most of the needed data at the
; end...

;------------------------------------------------------------
; MAIN CODE
;------------------------------------------------------------
BITS 32
GLOBAL _WDOSXStart              ;great (free!) extender
GLOBAL Main                     ;great (free!) extender

%define ProgVersion     ".166"
MyPersonalVersion   equ 0       ;set to true for snapshot output and such
%define Debug           0
%define Complete        0

%include "sv.mac"               ;essential definitions and macros
%include "system.mac"			;used for a clean exit
%include "memory.mac"			;used for memory allocation

NumStringMaxLen equ 10

FileType:
.ZsnesSavestate equ 0
.Rom            equ 1
.Bitmap         equ 2
.Gif            equ 3
.Other          equ 4

SECTION .text
_WDOSXStart:
Main:
					;save command line parameters
	mov [StartOptCount],esi		;the number of parameters
	mov [StartOptPtrs],edi		;array of pointers to each one
	mov [StartOptEnv],ebp		;command environment strings
	mov [StartOptSelector],es	;save selector
    push ds                     ;now that es is saved, make sure es equals ds
    pull es                     ;we don't want any crashes!
	call StartOptionsCheck		;interpret what commandline parameters say
    jc near ErrorEnd            ;edx should already be set to error message

    test byte [StartOptions],StartOptions.FileGiven
    jz near ErrorNoFilename
    HeapInit 0                  ;make some memory available
	jc near ErrorHeapInit		;if such a thing would ever happen?

    call LoadFile               ;try to load file given
    jc near ErrorEnd            ;end if error loading

    test byte [StartOptions],StartOptions.PaletteGiven
    jz .NoPaletteFile
	call LoadPalette
    jnc .AfterPaletteLoaded
    call ErrorPrint
    ;jmp short .NoPalette
    .NoPaletteFile:
    cmp byte [LoadedFileType],FileType.ZsnesSavestate
    jne .NoPalette
    mov esi,[LoadedFilePtr]     ;get pointer to file image
    add esi,1560                ;add offset of CGRAM
	mov edi,Palette.User
    call PaletteConvertSnesCgram.AnyDest
.AfterPaletteLoaded:
    mov byte [PaletteType],PaletteType.User ;set current palette to user palette
.NoPalette:

;	set variables
;	  if file is ROM with header then set base to 512
;	  if file is Zsnes savestate then set base to VRAM (134163)
    cmp dword [TileBaseByte],0
    ja .SetPosEnd
	mov eax,[LoadedFileLength]
	mov ebx,512
	and eax,32767
	cmp eax,ebx
    jne .SetPosNoRomHeader
    mov [TileBaseByte],ebx
.SetPosNoRomHeader:
    cmp byte [LoadedFileType],FileType.ZsnesSavestate
    jne .SetPosNotSavestate
    mov dword [TileBaseByte],134163
.SetPosNotSavestate:
.SetPosEnd:

    call SetVideoMode           ;set to mode 13h
    AtExit SetExitVideoMode     ;make sure text mode is restored later

	;Set up things for the GUI, like the colors it needs and the mouse pointer
    mov al,[PaletteType]
	call PaletteMake
    call PaletteSetGuiColors    ;set GUI colors
	call PaletteSet
;	call MouseInitialize		;check for a mouse and set up pointer variables
;	mov ax,1
;	int 33h

	call ViewWindowLoop

    Exit                        ;call all exit routines before dying
    mov ax,4C00h                ;DOS function to terminate
    int 21h                     ;bye-bye :-)

ErrorPrint:
    mov ah,9                    ;and print out string
	int 21h
    jmp UserWait
ErrorNoFilename:
	mov edx,Messages.HelpText
	jmp short ErrorEnd
ErrorHeapInit:
	mov edx,Messages.HeapInitErr
	jmp short ErrorEnd
ErrorEnd:
    push edx                    ;save message ptr
    Exit                        ;call all exit routines, but do not die yet
    pop edx                     ;retrieve message and ptr
    mov ah,9                    ;and print out string
	int 21h
    mov ax,4C01h                ;DOS function to terminate
    int 21h                     ;bye-bye

ViewWindowMaxTileWidth  equ 32
ViewWindowMaxTileHeight equ 22
;------------------------------
; ViewWindowLoop
;
; Waits for the user to press a key and scrolls or changes the palette,
; Then redraws the page and info.
;
ViewWindowLoop:
	push dword .ScrollUpdate
	jmp .RedrawScreen

.GetKeysPressed:
	call KeyGetPress
	jnc .GetKeysPressed
	mov esi,.KeyCharTable			;set comparison table
	call KeyScanFor
	jc .GetKeysPressed			;error, key with no response
	jmp [.KeyJumpTable+ecx*4]		;jump to the right response

.0:	mov edx,-1
	jmp .ScrollByByte
.1:	mov edx,1
	jmp .ScrollByByte
.2:	mov edx,-1
	jmp .ScrollByTile
.3:	mov edx,1
	jmp .ScrollByTile
.4:	mov edx,-1
	jmp .ScrollByRow
.5:
    mov edx,1
	jmp .ScrollByRow
.6:
    mov edx,-16
	jmp .ScrollByRow
.7:
    mov edx,16
	jmp .ScrollByRow
.20:
    mov edx,-32768
	jmp .ScrollByByte
.21:
    mov edx,32768
	jmp .ScrollByByte
.8:
    mov eax,-8
    jmp .ChangeTileWrapRelative
.9:
    mov eax,8
    jmp .ChangeTileWrapRelative
.WrapHalf:
    mov eax,[TileWrap]
    shr eax,1
    and eax,01111111000b
	jmp .ChangeTileWrap
.WrapDouble:
    mov eax,[TileWrap]
    shl eax,1
    and eax,11111111000b
	jmp .ChangeTileWrap
.10:	mov dl,-1
	jmp short .11_End
.11:	mov dl,1
.11_End:
        add dl,[PaletteType]     ;add to current palette
	push dword .ScrollUpdate
	jmp .ChangePalette
.14:
    sub al,49-GraphicsMode.SNES     ;turn ASCII character into numbered mode
    cmp al,GraphicsMode.SNES+1
    je .ToggleBplLnr2bit
    cmp al,GraphicsMode.SNES+2
    je .ToggleSnesVb
    cmp al,GraphicsMode.SNES+3
    je .ToggleBplLnr4bit
    cmp al,GraphicsMode.SNES+7
    jne near .ChangeMode
.ToggleBplLnr8bit:
    mov ah,GraphicsMode.Linear8bit
    mov ebx,ModeToggle.BplLnr8bit
    jmp .ToggleMode
.ToggleBplLnr2bit:
    mov ah,GraphicsMode.Linear2bit
    mov ebx,ModeToggle.BplLnr2bit
    jmp .ToggleMode
.ToggleSnesVb:
    mov ah,GraphicsMode.Vb
    mov ebx,ModeToggle.SnesVb
    jmp .ToggleMode
.ToggleBplLnr4bit:
    mov ah,GraphicsMode.Linear4bit
    mov ebx,ModeToggle.BplLnr4bit
    jmp .ToggleMode
.15:
    mov ax,GraphicsMode.SegaGenesis|(GraphicsMode.NES<<8)
    mov ebx,ModeToggle.SegaNES
    jmp .ToggleMode
.16:
    mov ax,GraphicsMode.N64Gfx15bit|(GraphicsMode.N64Gfx24bit<<8)
    mov ebx,ModeToggle.N64Gfx
    jmp .ToggleMode
.12:
    mov ax,GraphicsMode.Mode7Linear|(GraphicsMode.Mode7IntOdd<<8)
    mov ebx,ModeToggle.Mode7
    jmp .ToggleMode
.22:
    mov ax,GraphicsMode.FxGfxLow|(GraphicsMode.FxGfxHigh<<8)
    mov ebx,ModeToggle.FxGfx
    jmp .ToggleMode
.18:
    mov al,-1
	jmp short .ChangeUserPaletteBase
.19:
    mov al,1
.ChangeUserPaletteBase:
	mov cl,[TileBits]		;get bitdepth
	mov bl,[UserPaletteBase]
	shr bl,cl			;clear any lower bits
	add bl,al			;next page or previous page
	shl bl,cl
	mov [UserPaletteBase],bl
	push dword .ScrollUpdate
	jmp .ChangePaletteNow
.13:
	mov al,16
	cmp [PosRadix],al
	jne .UsingDec
	mov al,10
    .UsingDec:
	mov [PosRadix],al
	jmp .UpdateInfoText
.24:;home
    xor edx,edx                 ;set to beginning of image
	jmp .ScrollCheck
.25:;end
    mov edx,[LoadedFileLength]  ;set to end of image
	dec edx
	jmp .ScrollCheck
.DecTpRows:
    mov eax,255                 ;row-1
    jmp .ChangeTpSize
.IncTpRows:
    mov eax,1                   ;row+1
    jmp .ChangeTpSize
.DecTpCols:
    mov eax,65280               ;col-1
    jmp .ChangeTpSize
.IncTpCols:
    mov eax,256                 ;col+1
    jmp .ChangeTpSize
;.16:
;	mov edx,320/4
;.16_NextSplice:
;	push edx
;	call SpliceScreenEffect
;	pull edx
;	dec edx
;	jnz .16_NextSplice
;	jmp .GetKeysPressed
;.18:
;	mov edi,0A0000h
;	mov ecx,64000/4
;	xor eax,eax
;	cld
;	rep stosd
;	jmp .GetKeysPressed
.17:
	ret
.Help:
    call HelpPage
	push dword .ScrollUpdate
	jmp .RedrawScreen
.ToggleMode:
;(al=first mode, ah=second mode, bh=mask)
    mov cl,[GraphicsMode]
    cmp cl,al
    je .UsingMode
    cmp cl,ah
    jne .NotUsingMode
.UsingMode:
    xor [ModeToggle],ebx
.NotUsingMode:
    test [ModeToggle],ebx
    jz .UsingFirstMode
    mov al,ah
.UsingFirstMode:
	jmp .ChangeMode

;(edx=scroll adjustment +-)
.ScrollByRow:
    ;!!temp
    mov ebx,[TileWrap]
    ;imul edx,[TileWrap]             ;multiply by number of tiles per row
    shr ebx,3
    imul edx,ebx
    movzx eax,byte [TilePattern.Rows]
	imul edx,[TileByteSize]			;multiply jump by bytes per tile
    imul edx,eax
	jmp short .ScrollByByte
.ScrollByTile:
    movzx eax,byte [TilePattern.Size]
	imul edx,[TileBytesApart]		;multiply jump by bytes between rows
    imul edx,eax
.ScrollByByte:
	add edx,[TileBaseByte]			;get top row source
;(edx=new position)
.ScrollCheck:
	mov ebx,[LoadedFileLength]
	cmp edx,ebx					;check not beyond image length
	jb .ScrollSet
	cmp [TileBaseByte],ebx
	jb near .GetKeysPressed
	mov edx,ebx					;set pos to file length
	dec ebx					;minus one
	;jmp short .ScrollSet

;	if scroll base byte is by even multiple of tilesize,
;	  scroll existing data in window
;	  if length > wrap
;	    length
;	  redraw window top or bottom for length of change
;	    if bottom then calculate bottom basebyte
;	else completely redraw
;	if mode or tilewrap change then completely redraw
;	if palette change
;	  redraw to screen
;	  if colors needed <= 248
;	    set blitting to upper palette
;	  else
;	    set blitting to full palette
;	    if colors are in palette
;	      remap palette to needed colors
;	    else
;	      remap palette to new colors
;	  adjust screen palette
.ScrollSet:
	mov [TileBaseByte],edx
.ScrollUpdate:
	call TileWindowFill
	%assign .InfoTextRightColumn 320-(8*8)-5
.UpdateInfoText:
    ;movzx ebx,byte [PosRadix]               ;decimal or hex offset
    ;mov eax,[LoadedFileLength]
    ;mov ecx,.InfoLineSizeLen
    ;mov edi,.InfoLine+.InfoLineSizeAt
    ;call MakeNumString.OfRadix
    ;FontBlitStr .InfoTextNum,8,4,.InfoTextRightColumn 
	movzx ebx,byte [PosRadix]		;decimal or hex offset
	mov eax,[TileBaseByte]
    mov ecx,.InfoLinePosLen
    mov edi,.InfoLine+.InfoLinePosAt
	call MakeNumString.OfRadix
    ;FontBlitStr .InfoTextNum,8,13,.InfoTextRightColumn
    ;MakeNumber [TileWrap], .InfoTextNum
    mov eax,[TileWrap]
    mov ecx,.InfoLineWrapLen
    mov edi,.InfoLine+.InfoLineWrapAt
    call MakeNumString.OfLength
    mov dword [.InfoLinePartCounter],0
    mov esi,[TileFormatStringPtr]
    call .CopyInfoLineNextPart
    mov al,[TilePattern.Rows]
    add al,'0'
    mov [.InfoLine+.InfoLineTpoAt],al
    mov al,[TilePattern.Cols]
    add al,'0'
    mov [.InfoLine+.InfoLineTpoAt+2],al
    ;FontBlitStr .InfoTextNum+5,3,22,.InfoTextRightColumn+(8*5)
    ;FontBlitStr [TileFormatStringPtr],9,31,.InfoTextRightColumn-8
    mov al,[PaletteType]            ;get current palette
    call PaletteGetString           ;get name of current palette
    call .CopyInfoLineNextPart
    ;FontBlitStr esi,ax,40,320-5-(12*8)
    FontBlitStr .InfoLine,.InfoLineLen,188,5
	jmp .GetKeysPressed

.CopyInfoLineNextPart:
    mov ebx,[.InfoLinePartCounter]
    mov edi,[.InfoLinePartTable+ebx*8]
    mov ecx,[.InfoLinePartTable+4+ebx*8]
    cld
    rep movsb
    inc dword [.InfoLinePartCounter]
    ret

;(al=tile mode)
.ChangeMode:
    call SetGraphicsMode
	je .DoNotRemakePalette			;last bitdepth and new one are the same
	call .ChangePaletteNow
.DoNotRemakePalette:
	jmp .ScrollUpdate

;(eax=relative adjustment)
.ChangeTileWrapRelative:
    add eax,[TileWrap]              ;add to current tilewidth
;(eax=new wrap)
.ChangeTileWrap:
    cmp eax,8
    jb near .GetKeysPressed
    ;jz near .GetKeysPressed         ;make sure it is not equal to zero
    cmp eax,1024                     ;or over 32 tiles wide or negative
	ja near .GetKeysPressed
    cmp [TileWrap],eax
    mov [TileWrap],eax              ;set current tilewidth
    jbe near .ScrollUpdate          ;simply redraw tiles
    add eax,byte 4                  ;otherwise fill in reclaimed window area
    DrawBox 3,2+(8*ViewWindowMaxTileHeight),ax,3+(8*ViewWindowMaxTileWidth),GuiColorBack
	jmp .ScrollUpdate

;(dl=palette adjustment +-)
.ChangePalette:
    cmp dl,PaletteType.Total                ;check that not greater
	jb .PaletteChangeOk			;new palette is in range
;!	test dl,dl
	jns .PaletteChangeNotNegative		;if not negative
    mov dl,PaletteType.Total-1              ;else set to last palette
	jmp short .PaletteChangeOk
.PaletteChangeNotNegative:
	xor dl,dl				;set to first palette
.PaletteChangeOk:
    mov [PaletteType],dl             ;set new palette
.ChangePaletteNow:
    mov al,[PaletteType]     ;get current palette scheme
	call PaletteMake
    call PaletteSetGuiColors                ;set GUI colors
	call PaletteSet
	call .MakeColorBar
	ret

.ChangeTileHeight:			;do nothing for now
	ret

.ChangeTpSize:
    mov ecx,[TilePattern.Rows]
    add cl,al
    jz near .GetKeysPressed
    cmp cl,TilePattern.MaxRows
    ja near .GetKeysPressed
    mov [TilePattern.Rows],cl
    add ch,ah
    jz near .GetKeysPressed
    cmp ch,TilePattern.MaxCols
    ja near .GetKeysPressed
    mov [TilePattern.Cols],ch
    call RemakeTilePattern
    jmp .ScrollUpdate

.RedrawScreen:
	mov al,GuiColorBack
	call DrawClearScreen

	%assign .InfoTextLeftColumn 11+(8*ViewWindowMaxTileWidth)
	%assign .RightPageLeftColumn 9+(8*ViewWindowMaxTileWidth)
    DrawBorder 2,3+(8*ViewWindowMaxTileHeight),3,4+(8*ViewWindowMaxTileWidth),1
    ;DrawBorder 2,4+45,.RightPageLeftColumn,320-4,1
    DrawBorder 200-19,200-16,3,4+256,1
    DrawBorder 200-14,200-3,3,320-3,1
    ;FontBlitStr .TextFileSize,4,4,.InfoTextLeftColumn
    ;FontBlitStr .TextPos,3,13,.InfoTextLeftColumn
    ;FontBlitStr .TextWrap,4,22,.InfoTextLeftColumn
    ;FontBlitStr .TextMode,4,31,.InfoTextLeftColumn
    ;FontBlitStr .TextPal,3,40,.InfoTextLeftColumn
;	%assign .ButtonLeftCol .RightPageLeftColumn
;	%rep 9
;	  DrawBorder 53,67,.ButtonLeftCol,.ButtonLeftCol+17,0
;	%assign .ButtonLeftCol .ButtonLeftCol+20
;	%endrep
;	DrawBorder 70,200-4,.RightPageLeftColumn,320-4,1
	call .MakeColorBar
	ret

.MakeColorBar:
    mov edi,320*182+4+0A0000h
    xor eax,eax     ;zero pixel color and color counter
	mov cl,[TileBits]
	mov ch,1
	;dec cl
    shl ch,cl       ;get increment per pixel
	test ch,ch
	jnz .LongColorBars
	dec ch		;set to 255
	inc ah		;set color counter to 1
.LongColorBars:
    xor cl,cl       ;set counter to 256
.NextColor:
	mov [edi],al
	mov [edi+320],al
	inc edi
	add ah,ch
	adc al,0
	dec cl
	jnz .NextColor
	ret

section .data
alignb 4
.InfoLinePartCounter:   dd 0
.InfoLinePartTable:
                dd .InfoLine+.InfoLineModeAt
                dd .InfoLineModeLen
                dd .InfoLine+.InfoLinePalAt
                dd .InfoLinePalLen
.KeyJumpTable:  dd .8,.9, .18,.19, .DecTpRows,.IncTpRows, .DecTpCols,.IncTpCols, .WrapHalf,.WrapDouble, .11,.10, .14,.14,.14,.14,.14,.15,.22,.12,.16, .13, .17,  .4,.5, .6,.7, .2,.3, .0,.1, .20,.21, .24,.25, .Help
.KeyCharTable:	dd .KeyChars
                db 23
                db 13
.KeyChars:      db '[],./*-+{}pP123485679h',27,'HPIQKMstÑvGO;'

.InfoLine:              db '0000000 0000 $$$$$$$$$ $$$$$$$$$$$$ 9x9'
.InfoLineLen            equ $-.InfoLine
.InfoLinePosAt          equ 0
.InfoLinePosLen         equ 7
.InfoLineWrapAt         equ 8
.InfoLineWrapLen        equ 4
.InfoLineModeAt         equ 13
.InfoLineModeLen        equ 9
.InfoLinePalAt          equ 23
.InfoLinePalLen         equ 12
.InfoLineTpoAt          equ 36
.InfoLineTpoLen         equ 3
section .text

;------------------------------
; (al=mode) (zf=bitdepth of last mode and new mode were the same)
SetGraphicsMode:
	movzx eax,al
        cmp al,GraphicsMode.Total
        jae .ErrorEnd
        mov [GraphicsMode],al
	jmp [eax*4+.ModeJumpTable]
.ErrorEnd:
        test al,al      ;al would be anything but zero to have arrived here
	ret
.NES:
        mov al,2                                        ;set bitdepth
	mov [TileConvertRoutine],dword TransBplTile	;set routine to bitplane converter
	mov [TileBplPattern],dword BitplanePtrTable.8x8_2NES ;set bit pattern for converter
        mov [TileFormatStringPtr],dword GraphicsModeStrings.NES
        jmp .SetTileByteSize
.SNES:
	mov ebx,[BitplanePtrTable+eax*4]		;get corresponding bit pattern
	mov [TileConvertRoutine],dword TransBplTile	;set routine to bitplane converter
	mov [TileBplPattern],ebx			;set bit pattern for converter
        mov esi,GraphicsModeStrings.SNESGB
	cmp al,2
        je .GameBoy
        mov esi,GraphicsModeStrings.SNES
        mov dl,al
        add dl,48
        mov byte [GraphicsModeStrings.SNESbpl],dl
    .GameBoy:
	mov [TileFormatStringPtr],esi
        jmp .SetTileByteSize
.Mode7Linear:
	mov al,8
        mov byte [TransMode7Tile.Mode7Spacing],1        ;linear bitmap
        mov [TileConvertRoutine],dword TransMode7Tile   ;set routine
        mov [TileFormatStringPtr],dword GraphicsModeStrings.Mode7Linear
        jmp .SetTileByteSize
.Mode7IntOdd:
	mov al,8					;set tile bitdepth
        mov [TransMode7Tile.Mode7Spacing],byte 2        ;interleaved linear bitmap
        mov [TileByteSize],dword 128                    ;set bytes per tile
	mov [TileBytesApart],byte 128
        mov [TileConvertRoutine],dword TransMode7Tile   ;set routine
        mov [TileFormatStringPtr],dword GraphicsModeStrings.Mode7IntOdd
	jmp .ChangeMode
.SegaGenesis:
        mov al,4                                        ;set bitdepth
	mov [TileConvertRoutine],dword TransNibbleTile	;set to routine for Genesis tiles
        mov [TileFormatStringPtr],dword GraphicsModeStrings.SegaGenesis
        jmp .SetTileByteSize
.Vb:
        mov al,2                                        ;set bitdepth
        mov [TileConvertRoutine],dword TransVbTile      ;set to routine for Genesis tiles
        mov [TileFormatStringPtr],dword GraphicsModeStrings.VbTile
        jmp .SetTileByteSize
.Linear2bit:
        mov eax,2|(2<<8)                                ;set bitdepth and bytes per row
        mov [TileConvertRoutine],dword TransLinear2bit  ;set routine
        mov [TileFormatStringPtr],dword GraphicsModeStrings.Linear2bit
        jmp .SetLinearByteSize
.Linear4bit:
        mov eax,4|(4<<8)                                ;set bitdepth and bytes per row
        mov [TileConvertRoutine],dword TransLinear4bit  ;set routine
        mov [TileFormatStringPtr],dword GraphicsModeStrings.Linear4bit
        ;mov [TileByteSize],dword 32                     ;set bytes per tile
        ;mov [TileBytesApart],byte 4
        jmp .SetLinearByteSize
.Linear8bit:
        mov eax,8|(8<<8)                                ;set bitdepth and bytes per row
        mov [TileConvertRoutine],dword TransLinear8bit  ;set routine
        mov [TileFormatStringPtr],dword GraphicsModeStrings.Linear8bit
        jmp .SetLinearByteSize
.FxGfxLow:
        mov [TileFormatStringPtr],dword GraphicsModeStrings.FxGfxLow
	xor cl,cl
	jmp short .FxGfx
.FxGfxHigh:
        mov [TileFormatStringPtr],dword GraphicsModeStrings.FxGfxHigh
	mov cl,4
.FxGfx:
	mov [TransFxGfxTile.Shift],cl
        mov eax,4|(8<<8)                                ;set bitdepth and bytes per row
        mov [TileConvertRoutine],dword TransFxGfxTile   ;set routine
        ;mov [TileByteSize],dword 64                     ;set bytes per tile
        ;mov [TileBytesApart],byte 8
        ;mov [TileWrap],byte 32
        jmp .SetLinearByteSize
.N64Gfx24bit:
        mov eax,8|(32<<8)                               ;set bitdepth and bytes per row
        mov [TileConvertRoutine],dword TransN64Gfx24bit ;set routine
        mov [TileFormatStringPtr],dword GraphicsModeStrings.N64Gfx24bit
        ;mov [TileByteSize],dword 256                    ;set bytes per tile
        ;mov [TileBytesApart],byte 32
        ;mov [PaletteType],Palette.TrueColor
        jmp .SetLinearByteSize
        ; <hack for 24bit>
        ;mov eax,8|(24<<8)                               ;set bitdepth and bytes per row
        ;mov [TileConvertRoutine],dword TransLinear24Bit ;set routine
        ;mov [TileFormatStringPtr],dword GraphicsModeStrings.N64Gfx24bit
        ;mov [TileByteSize],dword 256                    ;set bytes per tile
        ;mov [TileBytesApart],byte 32
        ;mov [PaletteType],Palette.TrueColor
        ;jmp .SetLinearByteSize
.N64Gfx15bit:
        mov eax,8|(16<<8)                               ;set bitdepth and bytes per row
        mov [TileConvertRoutine],dword TransN64Gfx15bit ;set routine
        mov [TileFormatStringPtr],dword GraphicsModeStrings.N64Gfx15bit
        ;mov [TileByteSize],dword 128                    ;set bytes per tile
        ;mov [TileBytesApart],byte 16
        ;mov [PaletteType],Palette.TrueColor
        jmp .SetLinearByteSize
.SetLinearByteSize:
;(ah=bytes per row)
        movzx edx,ah
        mov [TileBytesApart],edx
        shl edx,3                                       ;*8
        mov [TileByteSize],edx                          ;set bytes per tile
        jmp short .ChangeMode
.SetTileByteSize:
;(al=bitdepth)
        movzx edx,al
        shl edx,3                               ;multiply by eight
        mov [TileByteSize],edx                  ;set bytes per tile
        mov [TileBytesApart],edx
.ChangeMode:
	cmp [TileBits],al			;check if we need to remake the palette
	mov [TileBits],al			;set tilebits
	ret

.ModeJumpTable:	dd .NES,.SNES,.SNES,.SNES,.SNES,.SNES,.SNES,.SNES,.SNES,
                dd .SegaGenesis,.Mode7Linear,.Mode7IntOdd,.FxGfxLow,.FxGfxHigh
                dd .N64Gfx24bit,.N64Gfx15bit,.Linear2bit,.Linear4bit,.Linear8bit
                dd .Vb

;------------------------------
; PaletteMake (al=palette)
;
; Fills the palette with the current palette colors
;
PaletteMake:
	movzx eax,al
	cmp eax,PaletteType.Total       ;check that not out of range
	jae .End
	mov cl,[TileBits]		;get bitdepth
	cmp cl,8			;maximum bitdepth is 8 (256 colors)
	ja .End
	mov ebx,1
	shl ebx,cl			;raise to the power of the current bitdepth
	dec ebx				;one less than total colors
	mov edi,ScreenPalette		;destination is main palette
	cld				;make sure direction flag is set forward!
	jmp [.JumpTable+eax*4]		;jump to the right palette code
.End:
	ret

.DefaultSet:
	mov esi,Palette.Default
	mov ecx,256
	jmp .CopyPalette

.RainbowSet:
	mov esi,Palette.Rainbow
	neg cl				;make bitdepth negative
	add cl,8			;subtract bitdepth from 8
	mov edx,1
	shl edx,cl			;raise to the power of the inverse bitdepth
	dec edx				;one less color than color jump
	lea edx,[edx*2+edx]		;multiply edx by three
.RainbowNextColor:
	movsw
	movsb
	inc edi
	add esi,edx
	dec ebx
	jns .RainbowNextColor
    ret

.InverseGraySet:
	lea edi,[edi+ebx*4]
	mov edx,-4
	jmp short .GraySetBegin
.GraySet:
    mov edx,4
.GraySetBegin:
	mov eax,1010100h
	shr eax,cl
	xor ecx,ecx
.GrayNextColor:
	mov [edi],ecx                   ;red, green, blue
	add edi,edx
	add ecx,eax
	dec ebx
	jns .GrayNextColor
        ret

.UserPalSet:
	movzx esi,byte [UserPaletteBase] ;get base color index into user palette
	lea edx,[ebx+esi]		;get base color plus total colors
	cmp edx,256			;check that they do not go past the palette
	jae .UserPalCopyAll
	lea ecx,[ebx+1]                 ;restore original count
	lea esi,[esi+esi*2]             ;multiply base color index times three
	add esi,Palette.User		;indexed source
	jmp .CopyPalette
.UserPalCopyAll:
	mov esi,Palette.User
	mov ecx,256
	jmp .CopyPalette

.TrueColorSet:
	xor eax,eax     ;al=red  ah=green  eal=blue
.TrueColorNextColor:
	stosd
	add al,43
	jnc .TrueColorNoWrap
	xor al,al
	add ah,43
	jnc .TrueColorNoWrap
	xor ah,ah
	add eax,43<<16
	cmp eax,0FFFFFFh
	jb .TrueColorNoWrap
	and eax,0FFFFh
.TrueColorNoWrap:
	dec ebx
	jns .TrueColorNextColor
	ret

.CopyPalette:
    mov eax,[esi]
    and eax,0FFFFFFh
    add esi,byte 3
    stosd
    dec ecx
    jnz .CopyPalette
    ret

align 4,db 0
.JumpTable:     dd .DefaultSet,.RainbowSet,.GraySet,.InverseGraySet,.TrueColorSet,.UserPalSet

;------------------------------
; PaletteGetString (eax=current palette) (esi=palette name ptr, eax=string length)
;
; Returns a string name of the current palette, including a ptr to it and its length
;
PaletteGetString:
	movzx eax,al
    cmp eax,PaletteType.Total       ;check that not out of range
	jae near .InvalidPalette
    cmp eax,PaletteType.User        ;check if user palette
	jne .NotUserPalette
    mov edi,.User+9
	movzx eax,byte [UserPaletteBase]
	mov ecx,3
	call MakeNumString.OfLength
    mov esi,.User
	jmp .End
.NotUserPalette:
	mov esi,[.Names+eax*4]
	;call GetStrLength
.End:
	mov eax,12
    ;clc
	ret
.InvalidPalette:
    mov esi,.1
	xor eax,eax
    ;stc
	ret

section .data
align 4
.Names: dd .0, .1, .2, .3, .4, .User
.0:     db " Default VGA",0
.1:     db "     Rainbow",0
.2:     db "        Gray",0
.3:     db "Inverse gray",0
.4:     db "  True color",0
.User:  db "    User:000"
.6:     db 0
section .text

;------------------------------------------------------------
; HelpPage ()
;
HelpPage:
	mov al,GuiColorBack
	call DrawClearScreen
    DrawBorder 2,197,3,316,1
    FontBlitPar Messages.KeyHelp,4,5
    call UserWait
    ret

;------------------------------------------------------------
; LoadFile () (cf=error, al=filetype OR error message, edx=error msg ptr)
;
LoadFile:
    mov ax,3D00h                ;DOS function: open file, access mode=0
    mov edx,Filename            ;what else, the filename
    int 21h                     ;call DOS (actually WDOSX)
    jc near .ErrorFileLoad      ;in case of file error, usually bad filename
    mov [.FileHandle],ax        ;store file handle
    
    mov ebx,eax                 ;get file handle
    mov eax,4202h               ;seek from end of file
    xor ecx,ecx                 ;set offset to zero
    xor edx,edx
    int 21h
    jc near .ErrorFileLoad
    
    shl edx,16                  ;make dword
    mov dx,ax
    test edx,edx                ;make sure it is not a zero size file
    jz near .ErrorFileNull
    
    mov [LoadedFileLength],edx      ;save file length
    
    Malloc edx,edx                  ;space to hold file
    jc near .ErrorNotEnoughMemory   ;uh-oh
    mov [LoadedFilePtr],edx         ;save pointer to file image
    
    mov eax,4200h                   ;seek from beginning
    xor ecx,ecx                     ;set offset to zero
    xor edx,edx
    int 21h
    
    ;prethrash memory by writing single byte in 4k increments
    ;load individual megabytes sequentially
    mov edi,[LoadedFileLength]  ;get a copy of length
    mov edx,[LoadedFilePtr]     ;get pointer to file image
    mov ecx,1048576             ;assume a megabyte
.NextMeg:
    cmp edi,ecx
    jae .LoadMeg
    mov ecx,edi
.LoadMeg:

    mov eax,ecx
    shr eax,12                  ;/4096 for 4k page size
    mov esi,edx
.NextPage:
    mov byte [esi],0
    add esi,4096
    dec eax
    jg .NextPage

    mov eax,3F00h               ;DOS function: read file
    ;                           ;set number of bytes to read (ecx) already set
    ;                           ;destination (edx) is the newly allocated block
    ;                           ;file handle is in bx
    int 21h                     ;call DOS (or actually WDOSX)
    jc .ErrorFileRead           ;file could not be read?

    push edx
    mov eax,0200h               ;DOS function: output character
    mov dl,'.'
    int 21h
    pop edx

    add edx,1048576             ;dest ptr += 1MB
    sub edi,ecx
    ja .NextMeg

    %if 0
    mov ecx,[LoadedFileLength]      ;get a copy of length
    mov edx,[LoadedFilePtr]         ;get pointer to file image
    mov eax,3F00h                   ;DOS function: read file
    ;                               ;set number of bytes to read (ecx) already set
    ;                               ;destination (edx) is the newly allocated block
    ;                               ;file handle is in bx
    int 21h                         ;call DOS (or actually WDOSX)
    jc .ErrorFileRead               ;file could not be read?
    %endif

    ;mov ebx,[.FileHandle]       ;get file handle
	mov ax,3E00h			;DOS function: close file
	int 21h				;call DOS (actually WDOSX)
    ;jc .ErrorFileRead

    mov esi,Filename
    call DetermineFiletype
    mov [LoadedFileType],al
    clc
	ret

.ErrorFileLoad:
	mov edx,Messages.FileLoadReadErr
	ret

.ErrorFileRead:
    Free [LoadedFilePtr]            ;free file image memory
	mov edx,Messages.FileLoadReadErr
    stc
	ret

.ErrorFileNull:
	mov edx,Messages.FileLoadNull
	stc
	ret

.ErrorNotEnoughMemory:
	mov bx,[.FileHandle]		;get file handle
	mov ax,3E00h			;DOS function: close file
	int 21h				;call DOS (actually WDOSX)
	mov edx,Messages.FileLoadMemErr
    stc
	ret

section .bss
.FileHandle:    resd 0
section .text

;------------------------------------------------------------
; LoadPalette ():(cf=error, edx=error msg ptr)
;
LoadPalette:
	mov ax,3D00h			;DOS function: open file, access mode=0
	mov edx,PaletteFilename		;what else, the filename
	int 21h				;call DOS (actually WDOSX)
    mov edx,Messages.PaletteLoadErr ;in case of file error, usually bad filename
    jc near .LoadErr
	mov [LoadFile.FileHandle],eax	;store file handle
    sub esp,1024                    ;space to hold file palette

	mov esi,PaletteFilename
	call DetermineFiletype
    mov esi,esp
	mov edi,Palette.User
	;jc .UnknownType
	;cmp al,FileType.Bitmap
	;mov edx,54
	;call .SetPosition
	;mov ecx,1024
	;call .ReadBytes
	;jmp short .End
;.NotABitmap:
	;cmp al,FileType.Gif
	;jne .NotAGif
	;mov edx,54
	;call .SetPosition
	;mov ecx,768
	;call .ReadBytes
	;jmp short .End
;.NotAGif:
	cmp al,FileType.ZsnesSavestate
	jne .UnknownType
	mov edx,1560
	call .SetPosition
	mov ecx,512
    mov edx,esp
	call .ReadBytes
    call PaletteConvertSnesCgram.AnyDest
.End:
    add esp,1024
.CloseFile:
	mov ebx,[LoadFile.FileHandle]	;get file handle
	mov ax,3E00h			;DOS function: close file
	int 21h				;call DOS (actually WDOSX)
.LoadErr:
	ret

.UnknownType:
        call .CloseFile
        add esp,1024
        mov edx,Messages.PaletteFileUnknown
	stc				;flag error
	ret

;(edx=position)
.SetPosition:
	mov eax,4200h			;seek from beginning of file
	mov ecx,edx			;copy offset
	mov ebx,[LoadFile.FileHandle]	;get file handle
	shr ecx,16			;set high word of offset
	int 21h
	;jc .ErrorFileLoad		;position could not be set?
	ret

;(ecx=length, edx=destination)
.ReadBytes:
	mov eax,3F00h			;DOS function: read file
	mov ebx,[LoadFile.FileHandle]	;get file handle
	int 21h				;call DOS (or actually WDOSX)
	;jc .ErrorFileLoad		;file could not be read?
	ret

;------------------------------------------------------------
; Returns the type of file based on the extension.
;
; (esi=filename ptr):(al=type, cf=unknown)
DetermineFiletype:
	call GetStrLength
	cmp eax,5
	jb near .UnknownType
	mov eax,[esi+eax-3]
    mov ecx,4
.NextChar:
    cmp al,'A'
    jb .NoLowerCase
    cmp al,'Z'
    ja .NoLowerCase
    or al,32
.NoLowerCase:
    rol eax,8
    dec ecx
    jnz .NextChar
    cmp eax,"bmp"
	jne .NotABitmap
	mov al,FileType.Bitmap
	ret
.NotABitmap:
    cmp eax,"gif"
    jne .NotAGif
    mov al,FileType.Gif
    ret
.NotAGif:
    mov edx,"zst"
	call .CheckZstType
	je .IsAZst
    mov edx,"zmv"
	call .CheckZstType
	jne .NotAZst
.IsAZst:
	mov al,FileType.ZsnesSavestate
	ret
.NotAZst:
;       determine if ROM
.UnknownType:
	mov al,FileType.Other
	;stc				;flag unknown type (already set by comparison above)
	ret

;(eax=file extension, edx=extension to compare with):(zf=match)
.CheckZstType:			;example extensions               (zst zs2 zs9 zsu zu2 zit zs&)
        cmp ax,dx               ;do first two letters match?      (zst zs2 zs9 zsu zs&) ->(zu2 zit)
	jne .CheckZstTypeEnd
        cmp eax,edx             ;does whole extension match?      (zs2 zs9 zsu zs&) =>(zst)
	je .CheckZstTypeEnd
	cmp eax,'1'<<16		;is last digit at least number 1? (zs2 zs9 zsu) ->(zs&)
	jb .CheckZstTypeEnd
	cmp eax,('9'<<16)|65535	;is last digist at most number 9? (zs2 zs9) ->(zsu)
	ja .CheckZstTypeEnd
        cmp eax,eax             ;set zero flag to indicate equality (to use jne)
.CheckZstTypeEnd:
	ret

;============================================================
; PARAMETER CHECKING
;============================================================
; StartOptionsCheck () - No regs preserved
;
; Checks the command line parameters and sets StartOptions accordingly
;
StartOptionsCheck:
%if 0
        mov esi,[StartOptPtrs]  ;get pointer to table
        mov edi,[esi+4]         ;get pointer to first string
        mov ecx,8192+13         ;maximum length of characters, look for cr
        mov edx,edi
	mov eax,ecx		;make a copy of max length for later
	cld			;as always, look forward
	repne scasb		;search for the end
	sub eax,ecx		;get length
        mov byte [edx+eax-1],'$'
        mov ah,9
        int 21h
        xor eax,eax
        int 16h
%endif

	mov edx,1			;start with first parameter
	push eax			;make storage for dword
	cld				;as always, go forward
.NextParameter:
	call .GetNextParameter		;get next parameter option
        jbe .NoneLeft                   ;checked them all
	cmp al,'-'			;is it an option?
	jne near .FileNameFound		;if not, assume it is the filename
	inc esi				;next character
	mov [esp],esi			;make a copy
	xor ebx,ebx			;set compare option to first one
	mov edi,.List			;set option string pointer to first one
	movzx ecx,byte [edi]		;get length of option string
.CompareNextOption:
        inc edi                         ;move to first character
        lea eax,[edi+ecx]               ;get next option string after this one
	repe cmpsb			;compare parameter with current option string
	je .DoOption			;there is a match
	inc ebx				;no match, next compare option
	mov esi,[esp]			;reset parameter character to first one
	mov edi,eax			;next option string
	movzx ecx,byte [edi]		;get length of option string
	test ecx,ecx			;check that we have not reached last option
	jnz .CompareNextOption		;keep on comparing
	mov edx,Messages.ParameterInvalid
.Exit:
	pull eax			;cheap restore stack
	stc				;flag error, unkown parameter
	ret

.NoneLeft:
	pull eax			;cheap restore stack
	clc				;no errors, all parameters were ok
	ret

.DoOption:
	;option match is given a number in ebx
	;using a jump table, the option is jumped directly too
	;then it either exits with an error or returns to get the next parameter
        cmp ebx,.StartOptionsTotal	;just in case of something weird
        jae short .NextParameter	;bad option passed on
        jmp [.JumpTable+ebx*4]		;jump to the right response
;    .Nada:
;        mov edx,Messages.ParameterNotSupportedYet ;set text message ptr
;        jmp short .Exit
    .Help:
        mov edx,Messages.HelpText	;set text message ptr
	jmp short .Exit
    .AboutInfo:
        mov edx,Messages.AboutInfo      ;set text message ptr
	jmp short .Exit
    .GotoPosition:
        call .GetNextParameter  ;sets esi
        jbe near .NextParameter
        push edx
        call MakeStringNum.Hex  ;get value from string
        mov [TileBaseByte],eax
        pop edx
        jmp .NextParameter
;    .VideoMode:
;        cmp edx,[StartOptCount]         ;check that a video mode is given
;        jae .VideoModeError
;        call .GetNextParameter
;        sub al,48                       ;turn ASCII number into real one
;        cmp al,ScreenModesNum           ;make sure it is a valid one
;        jae .VideoModeError
;        or byte [StartOptions],StartOptions.VideoModeGiven ;flag that video mode was given
;       mov [ScreenListMode],al		;save screen mode for later reading
;        jmp .NextParameter
;    .VideoModeError:
;        mov edx,Messages.InvalidScrnMode ;set text message ptr
;        jmp short .Exit
;    .LongFilenames:
;       or byte [StartOptions],StartOptions.LongFilenamesSet|StartOptions.LongFilenamesUse
;	jmp .NextParameter
;    .NoLongFilenames:
;       or byte [StartOptions],StartOptions.LongFilenamesSet
;	jmp .NextParameter
    .LoadPalette:
	call .GetNextParameter
        jbe near .NextParameter
        or byte [StartOptions],StartOptions.PaletteGiven ;flag that palette was specified
	mov edi,PaletteFilename
        jmp short .FilenameCopyText
    .FileNameFound:
	mov edi,Filename
        or byte [StartOptions],StartOptions.FileGiven
        ;jmp short .FilenameCopyText
    .FilenameCopyText:
	mov ecx,256/4			;copy up to 256 bytes from source
	rep movsd
	jmp .NextParameter

.GetNextParameter:
        cmp [StartOptCount],edx         ;check that not greater than last one
        jbe .NoMoreParameters           ;checked them all
	mov esi,[StartOptPtrs]		;get pointer to table
	mov esi,[esi+edx*4]		;get pointer to string
	mov al,[esi]			;get first character of parameter
	inc edx				;for next parameter
.NoMoreParameters:
	ret

section .data
.StartOptionsTotal equ 4
.List:
	;first byte is length of string plus null
	;following bytes are the option string and null
        ;db 2,'v',0                      ;video mode
	;db 3,'fw',0			;Windows 95 long filenames
	;db 4,'fwn',0			;do not use long filenames
        db 2,"?",0                      ;help
        db 2,"h",0                      ;also help
        db 2,"p",0                      ;palette specified
        db 2,"g",0                      ;goto position
	db 0				;the last option is a zero counter
align 4
.JumpTable:
        dd .AboutInfo,.Help,.LoadPalette,.GotoPosition

section .bss
	StartOptCount:		resd 1	;number of parameters
	StartOptPtrs:		resd 1	;array of pointers to each one
	StartOptEnv:		resd 1	;command environment strings
	StartOptSelector: 	resw 1	;command environment selector
section .text

;------------------------------------------------------------
; HELPER ROUTINES
;------------------------------------------------------------
%include "svrtns.asm"   ;most of my helper routines
%include "svtile.asm"   ;the tile converting and related routines
%include "memory.inc"	;gaz's protected mode routines
%include "system.inc"

;------------------------------------------------------------
; DATA CONSTANTS AND VARIABLES
;------------------------------------------------------------
section .data

Palette:
        .RedTable:      incbin "colortbl.dat"
        .GreenTable equ .RedTable+256
        .BlueTable  equ .RedTable+512
        .Rainbow:       incbin "rainbow.pal"
        .Default:       incbin "default.pal"
        .User:          incbin "zelda.pal"

;------------------------------
; GUI data
;------------------------------
GuiColorsNum equ 5			;the GUI colors use five out of 256
GuiColorsData:
        db 0,0,0, 72,72,92, 112,112,160, 192,192,255, 255,255,255
					;black, dark gray, gray, light gray, white.
	GuiColorBlack	equ 0		;color definitions for 256 color mode
	GuiColorDark	equ 16
	GuiColorGray	equ 32
	GuiColorLight	equ 48
	GuiColorWhite	equ 64

	GuiColorBack	equ GuiColorGray
	GuiColorFront	equ GuiColorGray
	GuiColorTop	equ GuiColorLight
	GuiColorBottom	equ GuiColorDark

align 4,db 0
FontColors:					;Various font color palettes
.Default:
.BiDo:	dw GuiColorFront,GuiColorWhite,GuiColorBlack,0
.LiDo:	dw 0,GuiColorLight,GuiColorBlack,9
.GiDo:	dw 0,GuiColorDark,GuiColorBlack,0

;MenuColors:
;	dw 0,GuiColorLight,GuiColorBlack,0	;inactive choice
;	dw 0,GuiColorWhite,GuiColorLight,0	;active choice
;	dw 0,GuiColorGray,GuiColorBlack,0	;inactive disabled
;	dw 0,GuiColorWhite,GuiColorBlack,0	;active disabled

; Mouse cursor images are saved as a font file because they have the same format as the 2bit
; fonts are, except of course that they are 16x16 instead of 8x8.
;
PointerImage:
.Default:
;.Arrow: ;incbin "mous_csr.fnt"

; I've always wondered where all these people get the fonts for their graphics programs.
; This one, which some may recognize, was taken from DKC1 (using another little SNES
; prog I wrote) and edited a little to look better.
;
FontStyle:
.Outline equ $-(32*16)	;fonts start at space character
	incbin "font1.fnt"		;each is 8x8 and 16 bytes in size

;------------------------------
; Main static variables
;------------------------------
align 4
MainOptions:    dd 0    ;up to 32 flags for various options
StartOptions:   dd 0    ;up to 32 flags to hold command line options

TileBaseByte:   dd 0    ;9225968 starfox64; 881A20h zelda64
TileBits:       dd 4
TileByteSize:   dd 32
TileBytesApart:	dd 32
TileHeight:     dd 8
TileWrap:       dd 128
TilePixRowBytes:dd 128
TileConvertRoutine:	dd TransBplTile
TileBplPattern:		dd BitplanePtrTable.8x8_4
TileFormatStringPtr:    dd GraphicsModeStrings.SNES
%if UseTilePattern
TilePattern:
.MaxRows    equ 8
.MaxCols    equ 8
db 0,1,0,0,0,0,0,0
db 2,3,0,0,0,0,0,0
db 4,5,0,0,0,0,0,0
db 6,7,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0
db 0,0,0,0,0,0,0,0
.Rows:  db 1
.Cols:  db 1
.Size:  db 1                    ;rows * cols
%endif
PaletteType:    db 0
.Total          equ 6
.User           equ 5
GraphicsMode:   db 4;(.SNES+3)
.Total          equ 20
.NES            equ 0
.SNES           equ 1
.SegaGenesis	equ 9
.Mode7Linear	equ 10
.Mode7IntOdd	equ 11
.FxGfxLow       equ 12
.FxGfxHigh      equ 13
.N64Gfx24bit    equ 14
.N64Gfx15bit    equ 15
.Linear2bit     equ 16
.Linear4bit     equ 17
.Linear8bit     equ 18
.Vb             equ 19
UserPaletteBase:db 0
ModeToggle:     dd 0
.Mode7		equ 1
.FxGfx		equ 2
.SnesNes2       equ 4
.N64Gfx         equ 8
.SegaNES        equ 16
.BplLnr2bit     equ 32
.BplLnr4bit     equ 64
.BplLnr8bit     equ 128
.SnesVb         equ 256
PosRadix:       db 16

;------------------------------
; GUI variables
;------------------------------
FontStylePtr:	dd FontStyle.Outline		;the current font table being used
FontColorsPtr:	dd FontColors.Default		;the current font colormap
FontRoutine:	dd _FontBlitCharOpaque.ByRegs	;the routine called by FontBlitStr

;------------------------------
; Basic screen mode info
;------------------------------
ScreenModesNum equ 1		;currently there is only mode 13h
ScreenModesInfo:
	dw 200,320,8		;mode 13h 320x200:256
;	dw 240,320,8		;all others are vesa modes
;	dw 480,640,8
;	dw 240,320,15
;	dw 480,640,15

;------------------------------
; Various strings used for messages
;------------------------------
GraphicsModeStrings:
.SNES:          db "   SNES 4",0  ;Super Nintendo Entertainment System
.SNESbpl        equ $-2
.SNESGB:        db "SNES/GB 2",0  ;SNES or GameBoy
.NES:           db "    NES 2",0  ;The old 8bit version
.Mode7Linear:   db "Mode7 l 8",0
.Mode7IntOdd:   db "Mode7 i 8",0  ;graphics interleaved with tiles every odd byte
.FxGfxLow:      db "FxGfx l 4",0
.FxGfxHigh:     db "FxGfx h 4",0
.SegaGenesis:   db "SegaGen 4",0
.N64Gfx24bit:   db " N64 true",0
.N64Gfx15bit:   db " N64 high",0
.Linear2bit:    db " Linear 2",0
.Linear4bit:    db " Linear 4",0
.Linear8bit:    db " Linear 8",0
.VbTile:        db "Vb Tile 2",0

Messages:
.HeapInitErr:           db "Could not allocate memory for main environment.$"
.FileLoadReadErr:       db "Could not load viewing file.$"
.FileLoadMemErr:        db "Not enough memory for file.$"
.FileLoadNull:          db "File is empty.$"
.PaletteFileUnknown:    db "Unknown palette file type.$"
.PaletteLoadErr:        db "Could not open palette file.$"
;.NoMouse:               db 'No mouse was detected.',0
.ParameterInvalid:      db "Unknown parameter.$"
;.InvalidScrnMode:       db "Only one screen mode is currently supported$"

.HelpText:
        db "SpriteView ",ProgVersion," - Savestate/ROM Graphics Viewer",13,10
        db "(c)2003 PeekinSoüt (-? for more info)",13,10
	db 10
        db "Usage: sv FileToView [-g HexOffset] [-p SavestatePalette]",13,10
        db 10
        db "FileToView can be any file with one of the many console graphics formats in it",10,13
        db "that SpriteView supports, including SNES, GB, N64, NES, VB, and Sega Genesis.",10,13
        db "Some formats may also reveal game's images from other systems or PC games.",10,13
        db 10
        db "SavestatePalette is a ZSNES savestate from a time in the game when it has the",13,10
        db "desired palette you want in it. The palette will be automatically loaded from",13,10
        db "the FileToView if it is a savestate.",13,10
        db "$"
.KeyHelp:
        db "Moving the viewing window:",129
        db "  Up Down Left Right  row or tile",129
        db "  PgUp PgDn           sixteen rows",129
        db "  Ctrl+(Left Right)   single byte",129
        db "  Ctrl+(PgUp PgDn)    32k bank",129
        db 129
        db "Changing tile format:",129
        db "  1         monochrome bitdepth",129
        db "  2,4,8     SNES bitplane / linear",129
        db "  3         SNES bitplane / VB",129
        db "  5         Sega Genesis  / NES",129
        db "  6         fx chip graphics low/high",129
        db "  7         mode 7 linear/interleaved",129
        db "  9         N64 graphics high/true",129
        db "  [ ]  { }  change tile wrap",129
        db "  + -  * /  change block width/height",129
        db 129
        db "Other keys:",129
        db "  p P       select palette among five",129
        db "  , .       change user palette page",129
        db "  Esc       see ya!",0
.KeyHelpEnd:
.AboutInfo:
        db "Built with the NASM compiler and WDOSX extender.",13,10
        db "Written by Dwayne Robinson, to spy into game's graphics.",13,10
        db 10
        db "    email:    FDwR@hotmail.com",13,10
        db "    homepage: http://fdwr.tripod.com/snes.htm",13,10
        db "$"

;PaletteMenuChoices	equ 6
;PaletteMenuList:
;	MenuChoice .0,0,MenuListDisabled
;	MenuChoice .1,1,MenuListDisabled
;	MenuChoice .2,2,MenuListDivider | MenuListDisabled
;	MenuChoice .3,3,0
;	MenuChoice .4,4,0
;	MenuChoice .5,5,0
;	MenuChoice .6,6,0
;	.0: db 'Load',0
;	.1: db 'Export',0
;	.2: db 'Save',0
;	.3: db 'VGA default',0
;	.4: db 'Grayscale',0
;	.5: db 'Rainbow',0
;	.6: db 'Inverse Gray',0

;	.0: db 'Monochrome bitplane',0
;	.1: db 'SNES/GB 2bitplane',0
;	.2: db 'NES 2bitplane',0
;	.3: db 'SNES 3bitplane',0
;	.4: db 'SNES 4bitplane',0
;	.5: db 'SNES 8bitplane',0
;	.6: db 'SNES Linear bitmap 8bit',0
;	.6: db 'SNES Linear mode 7 8bit',0
;	.6: db 'Sega Linear 4bit',0

;Copy image
;Paste image
;Edit in template
;Jump to last edit
;Flip vertically
;Flip horizontally
;Rotate left
;Rotate right
;Clear
;Transparent
;Select whole page
;Select none
;Export image
;Export tiles

;------------------------------
; VARIABLE SPACE SECTION (initialized upon startup)
;------------------------------
section .bss
	Filename: 		resb 256;full path and filename of file being viewed
        PaletteFilename:        resb 256;filename of palette
	alignb 4
	LoadedFilePtr:		resd 1
	LoadedFileLength:	resd 1
        LoadedFileType:         resb 1

;Video mode info--
	alignb 4
	ScreenPtr:	resd 1	;pointer to video memory (not used yet)
	ScreenHeight:	resw 1	;200/240/480
	ScreenWidth:	resw 1	;320/640
;	ScreenBits:	resb 1	;8/15
;	ScreenPixByte:	resb 1	;0=byte per pixel  1=two bytes per pixel
;	ScreenMode:	resb 1	;VESA mode used
;	ScreenListMode:	resb 1	;mode used from list (0-4)
;	ScreenSetError:	resb 1	;if there was an error setting the mode
;	ScreenChange:	resw 1	;a simple counter that is incremented when the video mode
				;changes so that graphics routines can know and change
				;their variables accordingly - the results of an 8bit blit
				;would not look good in a 15bit mode!

;Used by the graphics routines--
	alignb 4
	ScreenBuffer:	resd 1	;where to output screen writes, can be either directly to
				;visible screen or to a temporary buffer
	ScreenClipTop:	resw 1	;0
	ScreenClipBtm:	resw 1	;ScreenHeight-1
	ScreenClipLeft:	resw 1	;0
	ScreenClipRite:	resw 1	;ScreenWidth-1

        ScreenPalette:  resb 1024               ;points to 256 color palette
	TileBuffer:	resb (8*16)*(8*24+15)	;holds translated tiles
