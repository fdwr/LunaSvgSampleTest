;Tile translating, savestate loading, palette converting...
;------------------------------
;  SavestateParse
;  RenderCompleteScene
;  RenderBg.Bitplane
;  RenderBg.Mode7
;  RenderSpriteLayer
;  BlitTileImage
;  BlitTileImage.SetSize
;  ConvertToLinear.Mode7
;  ConvertToLinear.Bitplane
;  CacheReset
;  CgramPaletteConvert
;  SetColorBackground
;  CopyBufferToScreen
;  CopyPalettedBufferToScreen
;  VramTileFill
;  SeekVram
;  SeekVramTilesForward
;  SeekVramTilesBackward
;  VramTilesTotal
;  SetVramFormatRange
;  VramFormatReset
;  VramFormatMainParts
;  VramFormatSetPalettes
;------------------------------

; (todo)
; LoROM/HiROM determination:
;   First eliminate any invalid headers
;   Check for matching checksums
;   Default to low ROM is neither could be determined
;
;   assume low ROM, but check first
;   check for high ROM at 65472
;   if (ROM size > 13 || < 7) not high
;   if (SRAM size > 5) not high
;   if ((ROM makeup & 0Fh) != 1) not high
;   if checksum = ~inverse checksum then
;       definitely high ROM
;   else likely high ROM but not sure yet
;       assume high ROM, but make certain is isn't low ROM first
;       checksum for low ROM at 32704
;       if (ROM size > 13 || < 7) not low
;       if (SRAM size > 5) not low
;       if ((ROM makeup & 0Fh) != 0) not low
;       if checksum = ~inverse checksum then
;           definitely low ROM
;       else type could not be determined
;           assume low ROM
;       endif
;   endif

; HDMA Notes:
;   The HDMA transfer simulation itself does not actually write any bytes to
;   registers. Instead, it simply stores the bytes and ports they were
;   written to in a 15k table. That way the frame can be rerendered as many
;   times as needed at any given scanline, without needing to resimulate all
;   the HDMA transfers.
;
;   Since a game is likely to only read bytes for HDMA from the ROM or RAM,
;   and not a register, the memory mapper can be greatly simplified. It only
;   has to worry about if the ROM is low or high and whether the reqeusted
;   chunk is loaded into memory.
;
;   To render the scene with midframe changes, the registers are all reset to
;   their original values from when the savestate was first loaded. Then the
;   table is read, a single line is rendered, the table is read again, and
;   another line is rendered, until all 240 lines have been rendered. If the
;   register in the table is 0FFh, it is ignored, else the corresponding
;   value is written to that PPU register (2100h + Reg). The responding code
;   does little more than simply save the value to the appropriate variable.
;
; HDMA Initially:
;   count channel 0 to 7
;       zero line count
;       reset table source address
;   endcount
;
; HDMA Each Line 0-239:
;   count channel 0 to 7
;       if channel active
;           decrement line count
;           if underflow (sign change)
;               load next count
;               predecrement count
;               if count < 0 then
;                   set channel inactive
;               else
;                   if indirect
;                       set source address to [table adr + 1]
;                   else direct
;                       set source address to table adr + 1
;                   endif
;                   goto WriteByte
;               endif
;           elif count >= 128 (sign negative)
;             WriteByte:
;               switch transfer mode
;               case 0: read byte, write byte
;               case 1: read bytes, write word (low byte, high byte)
;               case 2: read bytes, write two bytes
;               case 3: read bytes, write two low bytes, two high bytes
;               case 4: read bytes, write dword (four consecutive bytes)
;               endswitch
;               dec/inc source address
;               if direct
;                   set table address to source address
;               endif
;           endif
;       endif
;   endcount
;
;
;   btr [HdmaActive],ecx
;
;   dec byte [HdmaCounts+ecx]
;   jo .CountEnd
;   jns .SkipChannel
;   mov esi,[HdmaSourcePtr+ecx*4]
;   jmp short .CountContinuous
;
;.CountEnd:
;   mov esi,[HdmaTablePtr+ecx*4]
;   mov bl,[esi]
;   sub bl,1
;   jnc .NotTableEnd
;   btr [HdmaActive],ecx
;   jmp short .SkipChannel
;.NotTableEnd:
;   mov [HdmaCounts+ecx],bl
;   inc esi
;   test [DmaControl+ecx],byte 8
;   jz .Direct
;   mov edx,[HdmaAdr]
;   mov dx,[edx]
;.Direct:
;   ;mov esi,esi //already set
;
;.CountContinuous:
;
;
;.SkipChannel:
;   dec ecx
;   jns .Next

;%define CodeTimed      1

;------------------------------
SECTION .bss
alignb 4
BgScene:
    .ImageBufferSize  equ 65536
	.ImageBuffer:	resb .ImageBufferSize	;buffer drawn scenes sections in
	.CacheBuffer:	resb 65536	;64k to hold tiles translated to bitmaps
	.CacheIndexes:	resw 15360	;CacheBuffer offsets to cached tiles (4096+2048+1024+512)*2; -1 if empty.
	.CacheList:		resw 1024	;id's of tiles currently in cache
;	.SpritePos:	resb 512	;small array to speed up sprite searching

	.Scroll:	;dword
	.ScrollY:	resw 1		;user's scroll in view scene
	.ScrollX:	resw 1
	.TopRow:	resw 1		;top row and left column of scene piece being rendered
	.LeftCol:	resw 1		;-< ! paired for a reason >-
	.BtmRow:	resw 1
	.RiteCol:	resw 1
	.Height:	resd 1		;height and width of scene piece being rendered
    .Width:     resd 1      ;used instead of passing parameters every call
	.CacheListPtr:	resd 1	;current circular offset in cache
	.VisiblePlanes:	resw 1	;which planes user has turned on/off
	.RenderPlanes:	resb 1	;which planes to actually render
	;.Scaling:	;word
	;.UpScaling:		resb 1	;enlargement or reduction of scene ratio
	;.DownScaling:	resb 1	;first byte for left shifting, second byte is right
	.BackgroundColor:	resb 1	;color in palette to use for scene background

SECTION .data
    align 4
	.CacheIndexPtrs:
        dd 0            ;2bit (4 color) tiles
        dd 4096*2       ;4bit (16 color) tiles
        dd (4096+2048)*2    ;8bit (256 color) tiles
        dd (4096+2048+1024)*2 ;4bit (16 color) sprites
	.Options:	db 0			;option flags
	.Options_InvertPalette	equ 1	;use inverted palette

SECTION .bss
alignb 4
TileImage:
	.ImgSource:	resd 1		;offset in cache of tile/sprite image
	.PixelRow:	resd 1		;pixel row of tile/sprite to blit
	.PixelCol:	resd 1		;pixel column of tile/sprite
    .RowPtr:    resd 1
    .ColPtr:    resd 1
    .Height:    resd 1      ;8/16/32/64
    .Width:     resd 1      ;8/16/32/64
    .SizeShift: resb 2      ;two bytes for height/width shift
    .Flip:      resb 1      ;flip current image?
	.Palette:	resb 1		;palette index to image
    .BitAttrs:              ;dword
	.BitDepth:	resb 1		;number of bits per pixel
    .BitShift:  resb 1      ;number of bits to shift data to get size
	.BitMask:	resw 1		;bit mask for pixels
	.PalBase:	resb 1		;only used for mode 0

alignb 4
VramFormat:
    .TableSize  equ 4096    ;size of vram (65k) / byte size of smallest tile (16 byte 2bitplane)
    .Table:         resb .TableSize * 2
    ; The table consists of two bytes, with the lower byte holding the tile
    ; format (0=2bpl, 1=4bpl, 2=8bpl, 3=mode 7, 4-7=ignorable) and the upper
    ; containing the palette (4-252 in increments of four).
    .UseGfxTable:   resb .TableSize / 8
    ; The UseGfx and UsePal tables a boolean tables (each tile is a bit)
    ; that states whether or not a specific tile format and/or palette is
    ; specified. If true, the palette/format is used from the table,
    ; otherwise the current palette and format are used.
    .UsePalTable:   resb .TableSize / 8
SECTION .data
    ; The tile formats are arranged:
    ; 2bpl,4bpl,8bpl,mode 7,ignored
    align 4
    ; Actual byte size for each type of tile:
    .TileSizes:     dd 16,32,64,128,64,64,64,64
    ; number of entries used in table for each type of tile:
    ; 2bpl,4bpl,8bpl,mode 7,2bpl,ignored,ignored,ignored
    .TileEntries:   dd 1,2,4,8,4,4,4,4
    .PaletteMasks:  dd 0FCFCFCFCh,0F0F0F0F0h,0,0,0,0,0,0
	.TileConverters:
	dd ConvertToLinear.Bitplane,ConvertToLinear.Bitplane,ConvertToLinear.Bitplane,ConvertToLinear.Mode7
    dd ConvertToLinear.Blank,ConvertToLinear.Blank,ConvertToLinear.Blank,ConvertToLinear.Blank
    .TileSize:      dd 32
    .BitDepth:      dd 4
    .TileEntry:     dd 2
    .PaletteBase:   db 0
    .TileFormat:    db 1

SECTION .text

DrawToScreen    equ 0

;------------------------------------------------------------
; SavestateParse (words file handle, savestate type) (cf=error)
;
; Loader that puts each part of the savestate into its correct place in the
; SnesState memory. It assumes that a file has already been opened for it.
; Some of the possible errors include not having enough memory to load the
; state, or trying to load something that is not an SNES state. When this
; returns, everything in the state is set up. The BgScene variables are
; not set by this function. Carry will be clear on success and al will
; contain info, otherwise it hold an error message value.
;
SavestateParse:
	;jump down to the right code for that format
	;currently only ZSNES is supported
	;other formats that hopefully will be supported are Snes9x and SneMul
    mov dword [BgScene.Height],200
    mov dword [BgScene.Width],320
    mov dword [BgScene.Scroll],((256-320)/2)<<16  ;reset user's scroll in view scene
	jmp ZSNES
;	jmp SNEQR

.ReadParts:
    mov edx,[ebx]               ;get number of blocks to transfer
    add ebx,byte 4              ;get first block in list
    mov eax,[.LoadedStatePtr]   ;get base of file image
    cld                         ;as always, go forward
.NextBlock:
    mov edi,[ebx]               ;get destination in SnesState
    mov esi,[ebx+4]             ;get file offset source
    mov ecx,[ebx+8]             ;get length, number of dwords to move
    add esi,eax                 ;add file image address to source
	rep movsd
    add ebx,byte 12             ;set position in list to after block just read
    dec edx                     ;one less block
	jnz .NextBlock
	ret

.ReadErrorEnd:
	Free [.LoadedStatePtr]	;free the memory used for the file image
    mov al,SavestateLoadReadErr
    stc
    ret
.MemoryErrorEnd:
    mov al,SavestateLoadMemoryErr
	ret

align 4
.LoadedStatePtr:	dd 0
.SavestateInfo:		dd 0

;------------------------------
ZSNES:
	;check header to make sure that pointed to file is indeed a savestate
	;check file size that is is greater than the minimum size (199698)
	;if savestate includes extra ram, store that size, and load it to
	;allocate enough memory to load the desired portions of the savestate into memory
	Malloc 199699,edx			;temporary space to hold file
	jc near SavestateParse.MemoryErrorEnd	;uh-oh
	mov [SavestateParse.LoadedStatePtr],edx	;save pointer to file image
	mov eax,3F00h				;DOS function: read file
	mov ebx,[esp+4]				;get file handle
	mov ecx,199699				;set number of bytes to read
						;destination (edx) is the newly allocated block
	int 21h					;call DOS (or actually WDOSX)
	jc near SavestateParse.ReadErrorEnd	;file could not be read?
;	cmp eax,199699				;end if less than the size of a savestate
;	jb
    mov ebx,.SavestateFilePtrs              ;start with first part in a ZSNES savestate
    call SavestateParse.ReadParts           ;transfer all of them
	
	mov ebx,[SavestateParse.LoadedStatePtr]	;get base of file image

	mov dl,[ebx+ZsnesState.xpbt]			;get 65816c program bank (xx:----)
	mov [SnesState.ProgramBank],dl
	mov ax,[ebx+ZsnesState.xpc]		;get 65816c program counter (--:xxxx)
	mov [SnesState.ProgramCounter],ax

	mov dx,[ebx+ZsnesState.curypos]	;get currently rendered scanline
	mov [SnesState.ScanLine],dx

	mov ax,[ebx+ZsnesState.bgmode]		;get video mode and priority bit
	and ax,7|256				;in case of savestate error
    test dword [StartOptions],StartOptions.ZstVideoModeGiven
    jz .NoForcedMode
    mov al,[ZstVideoMode]
  .NoForcedMode:
	mov [SnesState.VideoMode],ax		;set video mode and priority
	movzx eax,al				;select video mode
	mov edx,[PlaneTypeTable+eax*4]	;get types for each of the four bgs
	mov edi,SnesState.BitDepth
	mov cl,4				;loop four bgs
	cld
  .NextBgBitdepth:
    mov al,dl                               ;get pointer to info on current bg
    mov esi,[PlaneInfoTable+eax*4]
    mov [edi],esi
	shr edx,8				;get next bitshift
    add edi,SnesState.BgInfo_Size           ;set write to next bg
	dec cl
	jnz .NextBgBitdepth

   ;<----- start loop -----
	;put each part of the bginfo into its place in the SnesState structure
	mov edi,SnesState.BgInfo+(SnesState.BgInfo_Size*3)
    mov ecx,3                   ;loop four bgs, starting from last
  .NextBg:
	mov ax,[ebx+ecx*2+ZsnesState.bg1ptr]	;get bg map base
    mov [edi+Bg.MapBase],ax

	mov ax,[ebx+ecx*2+ZsnesState.bg1objptr]	;get bg tile base
    mov [edi+Bg.TileBase],ax
	
	mov al,[ebx+ZsnesState.bgtilesz]	;get tile sizes of the bgs
    mov ah,8                    ;assume tile size of 8 pixels
    shr al,cl                   ;get first bit set to current bg
    shr al,1                    ;set carry flag to first bit
	jnc .SmallBgTile			;tile is small so just skip
    mov ah,16                   ;tile is large 16x16, pixels
  .SmallBgTile:
    mov al,ah                   ;copy tile size
    mov [edi+Bg.TileSizes],ax   ;set width and height to tilesize

	mov al,[ebx+ecx+ZsnesState.bg1scsize]	;get current bg map size (in tiles)
	mov dx,64|64<<8				;assume map size of 64x64 tiles
    shr al,1                    ;set carry flag to first bit
    jc .LargeWidthMap           ;width is large so just skip
    mov dh,32                   ;set width to 32 tiles
  .LargeWidthMap:
    shr al,1                    ;set carry flag to next bit
	jc .LargeHeightMap			;height is large so just skip
    mov dl,32                   ;set height to 32 tiles
  .LargeHeightMap:
    mov [edi+Bg.MapHeight],dx   ;set map width and height

	mov ax,[ebx+ecx*2+ZsnesState.bg1scrolx]	;get bg x scroll
	and ax,2047					;in case of error
    mov [edi+Bg.ScrollX],ax
	mov dx,[ebx+ecx*2+ZsnesState.bg1scroly]	;get bg y scroll
	and dx,2047					;in case of error
    mov [edi+Bg.ScrollY],dx

    sub edi,SnesState.BgInfo_Size ;set write to next bg (going backwards)
    dec ecx                     ;one less bg
    jns .NextBg                 ;continue if not negative (-1)
    ;>----- end loop -----

	mov ax,[ebx+ZsnesState.objsize1]
	mov dl,al
	call .GetOAMSize
	mov al,dl
	mov dl,ah
	call .GetOAMSize
	mov ah,dl
	mov [SnesState.OAMSmallSize],ax		;set small and large sprite size
	movzx eax,word [ebx+ZsnesState.objptr]
	mov [SnesState.OAMTileBase],eax

	mov ax,[ebx+ZsnesState.scrnon]		;get main screen and subscreen
;	and ax,1111100011111b				;in case of error
	mov [SnesState.MainScreen],ax
    test ax,ax
    jnz .LayersOn
    mov eax,1111100011111b              ;in case all layers are turned off
.LayersOn:
    mov [BgScene.VisiblePlanes],ax

	mov al,[ebx+ZsnesState.scaddtype]		;get main screens that are transparent
;	and al,11111b				;in case of error
	mov [SnesState.AddScreen],al

	mov eax,[ebx+ZsnesState.coladdr]
	mov [SnesState.FixedColor],eax

	;free memory used to load savestate file
	Free [SavestateParse.LoadedStatePtr]
;	jc .ErrorEndMemory

    mov al,SavestateLoadedVRAM
	clc
	ret

.GetOAMSize:
	push ecx				;save counter
	xor ecx,ecx				;set to zero in case no bits are found
	and edx,1010101b			;in case of savestate error
	bsf ecx,edx				;search for first bit
	mov dl,8				;sprite sizes are in multiples of 8
	shr cl,1				;divide find by 2
	shl dl,cl				;set 8 to power of cl
	pull ecx
	ret

.SavestateFilePtrs:				;Pointers to main parts of a ZSNES savestate file.
	;how many blocks need to be transferred, followed by a list of
        ;each part's file position, destination, and dword length.
	dd 4
        dd SnesState.VRAM, ZsnesState.vram,  65536/4   ;134163
        dd SnesState.WRAM, ZsnesState.wram7E,131072/4  ;3091
        dd SnesState.CGRAM,ZsnesState.cgram, 512/4     ;1560
        dd SnesState.OAM,  ZsnesState.oamram,544/4     ;536
;	dd 1
;       dd SnesState.ERAM,0,65536>>4

SNEQR:
;	ret

SneMul:
;	ret

Snes9x:
;	ret

;------------------------------------------------------------
; Main scene rendering routines
;------------------------------------------------------------
;------------------------------
; RenderCompleteScene
;
; Assumes that ScrollX/Y and Height/Width have already been set.
;
RenderCompleteScene:
    push ebp
    mov eax,[BgScene.Scroll]    ;get both ScrollY and ScrollX in one move
    and eax,2047|(2047<<16)
    mov [BgScene.TopRow],eax    ;set both BgScene.TopRow and BgScene.LeftCol
    mov ebx,[BgScene.Width]
    add eax,[BgScene.Height]
    shl ebx,16
    add eax,ebx
    mov [BgScene.BtmRow],eax    ;set both BgScene.BtmRow and BgScene.RiteCol

    ;wipe background with color constant
    mov al,[BgScene.BackgroundColor]
    mov ah,al               ;copy color color byte
    mov ecx,BgScene.ImageBufferSize/4
    shrd edx,eax,16         ;copy color word
	shld eax,edx,16			;dword now consists of four pixels of the same color
%if DrawToScreen=1
	mov edi,0A0000h
%else
    mov edi,BgScene.ImageBuffer
%endif
	cld
	rep stosd
    ;mov eax,ColorLrDark<<24|ColorLrBlack<<16|ColorLrDark<<8|ColorLrBlack
    ;mov bl,[BgScene.TopRow]
	;mov dl,200					;set height
    ;xor bl,[BgScene.LeftCol]
	;shr bl,byte 1				;check if even or odd by setting carry
	;jc .NoBackgroundRotate
	;rol eax,8					;roll background colors
	;cld
;.NoBackgroundRotate:
;.ClearNextLine:
	;mov ecx,320/4
	;rep stosd
	;rol eax,8
	;dec dl
	;jnz .ClearNextLine

    cmp byte [SnesState.VideoMode],7
    je near .Mode7
	;snesvideomode=highres

;Subscreens:
    mov ax,[BgScene.VisiblePlanes]
	not al			;get main screens NOT drawn
    and ah,al       ;only draw sub screens that are not also main screens
    mov [BgScene.RenderPlanes],ah
    RenderBplBg 3
    RenderBplBg 2
    RenderSprites 3
    RenderBplBg 3|RenderBgTilePriority
    test byte [SnesState.Bg3Priority],1
    jnz .SsBg3Priority
    RenderBplBg 2|RenderBgTilePriority
  .SsBg3Priority:
    RenderSprites 2
    RenderBplBg 1
    RenderBplBg 0
    RenderSprites 1
    RenderBplBg 1|RenderBgTilePriority
    RenderBplBg 0|RenderBgTilePriority
    RenderSprites 0
    test byte [SnesState.Bg3Priority],1
    jz .SsNoBg3Priority
    RenderBplBg 2|RenderBgTilePriority
  .SsNoBg3Priority:

;Mainscreens:
    mov al,[BgScene.VisiblePlanes]
    mov [BgScene.RenderPlanes],al
%ifdef CodeTimed
	cli
%endif
    RenderBplBg 3
    RenderBplBg 2
    RenderSprites 3
    RenderBplBg 3|RenderBgTilePriority
    test byte [SnesState.Bg3Priority],1
    jnz .MsBg3Priority
    RenderBplBg 2|RenderBgTilePriority
  .MsBg3Priority:
    RenderSprites 2
	RenderBplBg 1
    RenderBplBg 0
    RenderSprites 1
    RenderBplBg 1|RenderBgTilePriority
    RenderBplBg 0|RenderBgTilePriority
    RenderSprites 0
    test byte [SnesState.Bg3Priority],1
    jz .MsNoBg3Priority
    RenderBplBg 2|RenderBgTilePriority
  .MsNoBg3Priority:
%ifdef CodeTimed
	sti
%endif
    ;mov eax,[BgScene.CacheCurPtr]
	;call _DebugPrintValue
	pop ebp
	ret

.Mode7:
;	RenderSprites 3
;	RenderSprites 2
;	RenderSprites 1
    mov ax,[BgScene.VisiblePlanes]
	or al,ah
    mov [BgScene.RenderPlanes],al
	call RenderBg.Mode7
;	RenderSprites 0
	pop ebp
	ret

.UpdateScreen:
%if DrawToScreen=0
    mov esi,BgScene.ImageBuffer
	mov edi,0A0000h
	mov ecx,64000/4
	rep movsd
%endif
%ifdef CodeTimed
	mov eax,[RenderBg.RenderTime]
	mov ebx,[RenderBg.RenderedTimes]
	xor edx,edx
	div ebx
	DebugPrintValueNow eax
%endif
	ret

;------------------------------
; Unlike many emulators, this 'graphics engine' is tile based rather line
; based. It is a bit faster and just plain simpler than line by line; however
; it would not be able to do any realtime HDMA effects that change the scene
; during the frame. That's no big deal though since it can not do them anyway,
; as it can only work on frozen savestates.
;
RenderBg:

;------------------------------
; Renders a single layer (foreground or background) of a bitplane tile background.
; Source is the bg passed to it.
; Destination is BgScene.ImageBuffer.
; Top row, left column, height, & column are set in BgScene.
;
; (al = (bits 0-1 = plane) (bit 2 = main/sub screen) (bit 3 = tile priority))
;
.Bitplane:
	mov ecx,eax
    and ecx,3                   ;get plane only
    bt dword [BgScene.RenderPlanes],ecx   ;should plane be shown?
    jnc near .End               ;do not plot if not visible
	imul ebx,ecx,SnesState.BgInfo_Size
	add ebx,SnesState.BgInfo
	mov ecx,[ebx+Bg.BitDepth]	;get bitdepth, bitshift, and color mask of plane
    test cl,cl                  ;if bitdepth is 0 then end
	jz near .End
    ;cmp cl,8                   ;and <=8
	;ja near .End
	mov [.CurrentBgPtr],ebx		;save offset of current bg info block

	;(ecx is bitdepth, bitshift, colormask)
    mov [TileImage.BitAttrs],ecx
    shl cl,3                    ;bitdepth * 8
	mov [.TileByteSize],cl		;set tile size
    movzx ecx,ch                ;make bitshift into pointer
    mov esi,[BgScene.CacheIndexPtrs-4+ecx*4] ;get cache index base for current bitplane
	mov [.CacheIndexBase],esi	;store cache index base
    add cl,3                    ;add 3 to bitshift to multiply size times eight
	mov [.TileSizeShift],cl		;store tile size shift
	movzx edx,word [ebx+Bg.TileBase];get tile graphics base
	mov [.GraphicsBase],edx		;store graphics base for inner loop
    shr edx,cl                  ;divide graphics base by tilesize
	mov [.GraphicsBaseTile],edx	;store first tile of graphics base

	;(eax is still the screen mode)
    xor ecx,ecx                 ;assume back layer of bg
    test al,RenderBgTilePriority;test for which layer of bg to draw
	jz .BackLayer
    mov cl,BgTilePriority>>8    ;it was fore layer instead
.BackLayer:
	mov byte [.PriorityMask],cl	;save layer priority mask

	;if snesvideomode=0 then set bg palette base to plane*32 otherwise 0
	cmp byte [SnesState.VideoMode],0
	je .UsingMode0
    xor al,al                   ;not using mode 0
.UsingMode0:
    shl al,5                    ;bg*32 (will be zero anyway if not mode 0)
	mov [TileImage.PalBase],al

	;;check bg transparency and set
	;;set screen addition/subtraction or opaque by whether main or sub screen

	;figure starting tile row, tiles high, starting tile byte...
	;Depending on bg's scroll and the area to be displayed
	;All this setup looks terribly complex, but it is necessary to make the
	;inner loop faster. If it confuses you, that's alright; it would
	;confuse me just as much without all the comments.
	;row tile = (scrolly \ tileheight) and (mapheight - 1)
	movzx edx,word [ebx+Bg.ScrollY]		;get bg's vertical scroll
	movzx esi,byte [ebx+Bg.TileHeight]	;get tile height
    movzx eax,byte [ebx+Bg.MapHeight]   ;get tile map height
    add edx,[BgScene.TopRow]            ;add TopRow to scroll ^
    bsf ecx,esi         ;look for first bit in tile height
    mov edi,edx         ;copy vertical offset to edi
	;----------
    dec esi             ;make mask from tile pixel height (8=7|16=15)
    dec eax             ;make mask from tilemap height (64=63|32=31)
    and edi,esi         ;get row offset into current tile (0-7|0-15)
    shr edx,cl          ;divide vertical offset by tile height
    neg edi             ;get pixel row at top of tile
    and edx,eax         ;wrap tile offset to fit into bg height (32|64)
    mov [TileImage.PixelRow],edi ;set starting pixel row for tile blitter
    mov [.RowTile],dl   ;store strarting tile row
	;----------
    mov al,byte [ebx+Bg.MapWidth] ;get tile map width
	sub al,32			;make 32=0 and 64=32 to select the sixth bit
	and eax,edx			;mask out the sixth bit if not also set in RowTile
	add edx,eax			;add 32 to RowTile if BgWidth=64 and RowTile=>32
	shl edx,6			;multiply RowTile by 64
	add dx,[ebx+Bg.MapBase]
    mov [.TilemapRowPtr],dx     ;store tile base for current tile row
	;----------
    mov eax,[BgScene.Height]
    sub eax,edi                 ;add pixel row offset to height
    add eax,esi                 ;add tileheight minus one
    imul edi,[BgScene.Width]    ;StartingRow * SceneWidth = RowPtr
    shr eax,cl                  ;divide height of window by tileheight
    mov [.RowCounter],al        ;store number of rows to blit
    mov [TileImage.RowPtr],edi

	;figure tile column, tiles wide, starting tile byte...
	;col tile = (scrollx \ tilewidth) and (mapwidth - 1)
	movzx edx,word [ebx+Bg.ScrollX]		;get bg's vertical scroll
	movzx esi,byte [ebx+Bg.TileWidth]	;get tile width
	movzx eax,byte [ebx+Bg.MapWidth]	;get tile map width
    add edx,[BgScene.LeftCol]           ;add LeftCol to scroll ^
	bsf ecx,esi			;look for first bit in tile width
	mov edi,edx			;copy horizontal offset to edi
	dec eax				;make mask from tilemap width (64=63|32=31)
	shr edx,cl			;divide horizontal offset by tile width
	and edx,eax			;wrap offset to fit into bg width (32|64)
    mov [.StartingColTile],dl ;store strarting tile column
	dec esi				;make mask from tile pixel width (8=7|16=15)
	and edi,esi			;get pixel column offset into current tile (0-7|0-15)
	neg edi				;get pixel column of top of tile
    mov [.StartingColPixel],edi ;set starting pixel column for each row
    mov [TileImage.PixelCol],edi ;set starting pixel column for tile blitter
	;----------
    test edx,32                 ;check the sixth bit of RowTile
    jz .ColumnLessThan32        ;tile column is 0-31, not 31-63
    add edx,992                 ;jump to next 32x32 tile segment
.ColumnLessThan32:
    shl edx,1                   ;multiply ColumnTile by 2
    mov [.TilemapColPtr],dx     ;store tile base for current tile row
    add dx,[.TilemapRowPtr]     ;get complete tile address for row/column
    mov [.TilemapPtr],dx        ;store starting address
	;----------
    mov eax,[BgScene.Width]     ;^^
    sub eax,edi                 ;add pixel col offset to width
    add eax,esi                 ;add tilewidth minus one
    shr eax,cl                  ;divide width of window by tilesize
    mov [.StartingColCounter],al;store number of columns to blit

	cmp byte [ebx+Bg.TileHeight],16
    je near .LargeTiles
%ifdef CodeTimed
	rdtsc
	mov [.LastTime],eax
%endif

;------------------------------
;The loop starts here, rendering tiles from top to bottom, left to right
;
.Tilemap:;8x8 small tiles
    mov eax,03030808h           ;set tile height and width 8x8
	call BlitTileImage.SetSize
	mov dword [ConvertToLinear.DestWidth],8

.NextTileRow:
    mov eax,[.StartingTileCounters]  ;reset .ColCounter and .ColTile
    mov [.TileCounters],eax

.NextTileCol:
	movzx esi,word [.TilemapPtr]
	mov ax,[esi+SnesState.VRAM]		;get map tile word
	;check if tile is the desired priority
	xor ah,[.PriorityMask]			;invert layer priority bit with mask
	test ah,BgTilePriority>>8		;now test to see if on or off
    jnz near .Skip              ;do not blit if wrong layer

	mov byte [TileImage.Flip],ah		;store tile flip for BlitTileImage
	;tilepalbase = ((x and bgpalmask) >> colorshift) + bgpalbase
	mov cl,[TileImage.BitDepth]
	mov edx,eax
	and edx,BgTilePalette			;** temp
	shr edx,10
	shl edx,cl
	add dl,[TileImage.PalBase]		;add color base in case mode 0
	mov [TileImage.Palette],dl

	;get tile number
	;add tile base number
	;mod using and
	;check if present in buffer
	;first make tile if not
	;then draw tile
    mov esi,eax                     ;copy tile word
	and esi,BgTileNumber			;get ten bit tile character
	add esi,[.GraphicsBaseTile]		;add graphics base tile to tilename offset
	mov ebx,[.CacheIndexBase]		;get base of cache index
	and esi,[.CacheIndexMask]		;wrap tilename offset to fit in VRAM (and not outside of cache)
    movzx edi,word [BgScene.CacheIndexes+ebx+esi*2];get source of image in buffer from index
	cmp edi,65535				;check if not present (index = -1)
    jne .DrawCached             ;most of time the tile will have been cached
.MakeTile:
	;mov [TileImage.Palette],byte 128	;little visible flag to show new tiles
    mov edx,[BgScene.CacheListPtr]          ;get current tile in cache list
	lea ebx,[ebx+esi*2]			;get index pos
	and edx,1023				;wrap around since only 1024 8x8 tiles fit
	mov cl,[.TileSizeShift]			;get tile size shift value
    shl si,cl                   ;multiply by tile size to get VRAM address
	;and esi,65535				;wrap to fit in 64k
    movzx eax,word [BgScene.CacheList+edx*2];get tile already cached at current ptr
    cmp eax,65535               ;check if not present (index = -1)
	je .NoTileAlreadyCached
    mov word [BgScene.CacheIndexes+eax],-1  ;clear old tile
.NoTileAlreadyCached:
    mov [BgScene.CacheList+edx*2],bx        ;set cache list entry to current tile
    mov edi,edx                             ;copy current cache tile to destination
    shl edi,6                               ;*64
	inc edx					;next tile in cache (cache ptr +64)
    mov [BgScene.CacheIndexes+ebx],di       ;set source of tile image in index
	mov [TileImage.ImgSource],edi		;set source in cache for BlitTileImage
    mov [BgScene.CacheListPtr],edx          ;store new ptr
    add edi,BgScene.CacheBuffer             ;set destination to tile offset in cache buffer
	add esi,SnesState.VRAM			;set source to tile offset in VRAM
	movzx ecx,byte [TileImage.BitDepth]	;get bitplanes
	call ConvertToLinear.Bitplane
%if DrawToScreen=2
	call ShowEntireCache
.DrawCached:
%else
    jmp short .Draw
.DrawCached:
	mov [TileImage.ImgSource],edi
.Draw:
	call BlitTileImage
%endif
.Skip:                      ;jump to here if tile is not right priority

	;==move right to next column tile==
	inc byte [.ColTile]
	test byte [.ColTile],31
	jnz .NoWrapCol				;if (column and 31) = 0 then wrap column
	push dword .ReturnFromColWrap
	jmp .WrapCol
.NoWrapCol:
	add word [.TilemapPtr],byte 2		;proceed to next map tile (each one is two bytes)
.ReturnFromColWrap:				;return here from column wrap
	add dword [TileImage.PixelCol],byte 8;add tile width to pixel column
	dec byte [.ColCounter]			;one less tile across
	jnz near .NextTileCol			;continue to next tile if more left

	;==move down to next row of tiles==
	inc byte [.RowTile]
	test byte [.RowTile],31
	jnz .NoWrapRow			;if (row and 31) = 0 then wrap row
	push dword .ReturnFromRowWrap
	jmp .WrapRow
.NoWrapRow:
	add word [.TilemapRowPtr],byte 64	;proceed to next tile row
	mov dx,[.TilemapColPtr]
	add dx,[.TilemapRowPtr]
.ReturnFromRowWrap:				;return here from row wrap
	mov [.TilemapPtr],dx			;set tile ptr to value from above or WrapRow
    mov ecx,[.StartingColPixel]     ;get column at the start of each row
    mov edi,[BgScene.Width]         ;RowPtr += SceneWidth * 8
	add dword [TileImage.PixelRow],byte 8;add tile height to pixel row
    shl edi,3                       ;*8
    mov [TileImage.PixelCol],ecx    ;set pixel column to precolumn
    add [TileImage.RowPtr],edi
	dec byte [.RowCounter]			;one less tile row down
	jnz near .NextTileRow			;continue to next row if more left

%ifdef CodeTimed
	rdtsc
	sub eax,[.LastTime]
	add eax,[.RenderTime]
	inc dword [.RenderedTimes]
	mov [.RenderTime],eax
%endif
.End:
	ret

;------------------------------
.WrapCol:
    mov ebx,[.CurrentBgPtr]     ;get ptr to current bg
    mov ax,[.TilemapRowPtr]     ;get tile ptr for current row
	cmp byte [ebx+Bg.MapWidth],32
	je .WrapColToZero			;bg width is 32 tiles
	mov cl,byte [.ColTile]		;get current column tile
    and ecx,32                  ;select sixth bit only
    mov byte [.ColTile],cl      ;store result back
    shl ecx,6                   ;multiply ColTile by 64
    add ecx,eax                 ;add current row base to offset
    mov [.TilemapPtr],cx        ;proceed to next page
    ret                         ;return into loop
.WrapColToZero:
    mov byte [.ColTile],0       ;set current tile column to zero
    mov [.TilemapPtr],ax        ;set tilemap ptr to row base ptr
    ret                         ;return into loop

.WrapRow:
    mov ebx,[.CurrentBgPtr]     ;get ptr to current bg
	mov dx,[ebx+Bg.MapBase]
	cmp byte [ebx+Bg.MapHeight],32
	jbe .WrapRowToZero			;bg height is 32 tiles
    test byte [.RowTile],32     ;check if tile row is 0-31 or 32-63
	jz .WrapRowToZero			;tile row is 64 so wrap to top row
    movzx eax,byte [ebx+Bg.MapWidth] ;get tile map width
    shl eax,6                   ;multiply by 64
    add edx,eax                 ;add offset to MapBase
    mov [.TilemapRowPtr],dx     ;store tile ptr for current row
    add dx,[.TilemapColPtr]     ;get complete tile address for row/column
    ret                         ;return into loop
.WrapRowToZero:
	mov [.TilemapRowPtr],dx
	add dx,[.TilemapColPtr]
    mov byte [.RowTile],0       ;set current tile row to zero
    ret                         ;return into loop

;------------------------------
.LargeTiles:;16x16 large tiles
    mov eax,04041010h           ;set tile height and width 16x16
	call BlitTileImage.SetSize
	mov dword [ConvertToLinear.DestWidth],16
    add dword [.CacheIndexBase],16384 ;get base of 16x16 tile cache index

.NextTileRowLt:
    mov eax,[.StartingTileCounters] ;reset .ColCounter and .ColTile
    mov [.TileCounters],eax

.NextTileColLt:
	movzx esi,word [.TilemapPtr]
	mov ax,[esi+SnesState.VRAM]		;get map tile word
	;check if tile is the desired priority
	xor ah,[.PriorityMask]			;invert layer priority bit with mask
	test ah,BgTilePriority>>8		;now test to see if on or off
    jnz near .SkipLt                ;do not blit if wrong layer

    mov byte [TileImage.Flip],ah    ;store tile flip for BlitTileImage
	;tilepalbase = ((x and bgpalmask) >> colorshift) + bgpalbase
	mov cl,[TileImage.BitDepth]
	mov edx,eax
    and edx,BgTilePalette
	shr edx,10
	shl edx,cl
	add dl,[TileImage.PalBase]		;add color base in case mode 0
	mov [TileImage.Palette],dl

    ;mov cl,[BgScene.ColorShift]
	;shld edx,eax,cl
	;and edx,BgTilePalette
	;add dl,[TileImage.PalBase]			;add color base for mode 0
	;mov [TileImage.Palette],dl

	;get tile number
	;add tile base number
	;mod using and
	;check if present in buffer
	;first make tile if not
	;then draw tile
	mov esi,eax					;copy tile word
    and esi,BgTileNumber        ;get ten bit tile character
    add esi,[.GraphicsBaseTile] ;add graphics base tile to tilename offset
    mov ebx,[.CacheIndexBase]   ;get base of cache index
    and esi,[.CacheIndexMask]   ;wrap tilename offset to fit in VRAM (and not outside of cache)
    movzx edi,word [BgScene.CacheIndexes+ebx+esi*2];get source of image in buffer from index
	cmp edi,65535				;check if not present (index = -1)
	mov [TileImage.ImgSource],edi
    jne near .DrawLt            ;most of time the tile will have been cached
.MakeTileLt:
	;mov [TileImage.Palette],byte 128	;little visible flag to show new tiles
    mov edx,[BgScene.CacheListPtr]      ;get current tile in cache list
	lea ebx,[ebx+esi*2]			;get index pos
	and edx,1020				;wrap around since only 256 16x16 tiles fit
    mov cl,[.TileSizeShift]     ;get tile size shift value
	shl si,cl					;multiply by tile size to get VRAM location
	;and esi,65535				;wrap to fit in 64k
	mov edi,edx					;copy current cache tile to destination
	shl edi,6					;*64
	xor eax,eax					;get ready to clear old tiles
	mov ecx,4					;decache four tiles
.DecacheNextLt:
    mov ax,[BgScene.CacheList+edx*2]        ;get tile already cached at current ptr
	cmp eax,65535				;check if not present (index = -1)
    je .NoTileAlreadyCachedLt
    mov word [BgScene.CacheIndexes+eax],-1  ;clear old tile
.NoTileAlreadyCachedLt:
	inc edx					;next tile in list
	dec ecx
    jnz .DecacheNextLt
    mov [BgScene.CacheList-8+edx*2],bx      ;set cache list entry to current tile
    mov [BgScene.CacheIndexes+ebx],di       ;set source of tile image in index
    mov [BgScene.CacheListPtr],edx          ;store new ptr
	mov [TileImage.ImgSource],edi		;set source in cache for BlitTileImage

    add edi,BgScene.CacheBuffer             ;set destination to tile offset in cache buffer
	;16x16 tile converter
    call .BuildLt               ;top left of tile
	add edi,byte 8
	add esi,[.TileByteSize]
    call .BuildLt               ;top right
	mov eax,[.TileByteSize]
	add edi,(8*8)+(8*8)
	shl eax,4					;tilesize*16
	add esi,eax
    call .BuildLt               ;bottom right
	sub edi,byte 8
	sub esi,[.TileByteSize]
    call .BuildLt               ;bottom left
%if DrawToScreen=2
	call ShowEntireCache
%endif

.DrawLt:
	call BlitTileImage
.SkipLt:                        ;jump to here if tile is not right priority

	;==move right to next column tile==
	inc byte [.ColTile]
	test byte [.ColTile],31
    jnz .NoWrapColLt                ;if (column and 31) = 0 then wrap column
    push dword .ReturnFromColWrapLt
	jmp .WrapCol
.NoWrapColLt:
	add word [.TilemapPtr],byte 2		;proceed to next map tile (each one is two bytes)
.ReturnFromColWrapLt:               ;return here from column wrap
	add dword [TileImage.PixelCol],byte 16;add tile width to pixel column
	dec byte [.ColCounter]			;one less tile across
    jnz near .NextTileColLt         ;continue to next tile if more left

	;==move down to next row of tiles==
	inc byte [.RowTile]
	test byte [.RowTile],31
    jnz .NoWrapRowLt                ;if (column and 31) = 0 then wrap column
    push dword .ReturnFromRowWrapLt
	jmp .WrapRow
.NoWrapRowLt:
	add word [.TilemapRowPtr],byte 64	;proceed to next tile row
	mov dx,[.TilemapColPtr]
	add dx,[.TilemapRowPtr]
.ReturnFromRowWrapLt:               ;return here from row wrap
	mov [.TilemapPtr],dx			;set tile ptr to value from above or WrapRow
    mov ecx,[.StartingColPixel]     ;get column at the start of each row
    mov edi,[BgScene.Width]         ;RowPtr += SceneWidth * 8
	add dword [TileImage.PixelRow],byte 16;add tile height to pixel row
    shl edi,4                       ;*16
	mov [TileImage.PixelCol],ecx		;set pixel column to precolumn
    add [TileImage.RowPtr],edi
	dec byte [.RowCounter]			;one less tile row down
    jnz near .NextTileRowLt         ;continue to next row if more left

.EndLt:
	ret

.BuildLt:
	push edi
	and esi,65535				;wrap to fit in 64k
	push esi
	movzx ecx,byte [TileImage.BitDepth]	;get bitplanes
	add esi,SnesState.VRAM			;set source to tile offset in VRAM
	call ConvertToLinear.Bitplane
	pop esi
	pop edi
	ret

;--------------------
; Mode 7 Bg rendering () @dec 21 98
;
; The plane is projected flat without any rotation, shifting, or scaling.
; Source is always plane 1.
; Destination is BgScene.ImageBuffer.
; Top row, left column, height, & column are set in BgScene.
;
.Mode7:
	;mov ebx,SnesState.BgInfo
    test byte [BgScene.RenderPlanes],1
	jz near .End			;do not plot if not visible

    mov eax,03030808h           ;set tile height and width 8x8
	call BlitTileImage.SetSize
	;mov dword [ConvertToLinear.DestWidth],8

	mov byte [TileImage.Flip],0
	mov byte [TileImage.Palette],0			;palette index to 0
	mov [TileImage.ImgSource],dword 0

	;check bg transparency and set
	;set screen addition/subtraction or opaque by whether main or sub screen

	;figure starting tile row, tiles high, starting tile byte...
	;Depending on bg's scroll and the area to be displayed
	;All this setup looks terribly complex, but it is necessary to make the
	;inner loop faster. If it confuses you, that's alright; it would
	;confuse me just as much without all the comments.
	;row tile = (scrolly \ tileheight) and (mapheight - 1)
	movzx edx,word [SnesState.ScrollY]		;get bg's vertical scroll
    add edx,[BgScene.TopRow]        ;add TopRow to scroll !
	mov edi,edx			;copy vertical offset to edi
	shr edx,3			;divide vertical offset by tile height (always 8)
	and edx,127			;wrap offset to fit into bg height (always 128)
	mov [.RowTile],dl		;store strarting tile row
	and edi,7			;get pixel row offset into current tile (0-7)
	;---
    neg edi             ;get pixel row top of tile
	mov [TileImage.PixelRow],edi	;set starting pixel row for tile blitter
	shl edx,8			;multiply RowTile by 128*2
	mov [.TilemapRowPtr],dx		;store tile base for current tile row
	;---
    mov edx,[BgScene.Height]
	sub edx,edi			;add pixel row offset to height
	add edx,byte 7		;add tileheight minus one
    imul edi,[BgScene.Width]    ;StartingRow * SceneWidth = RowPtr
	shr edx,3			;divide height of window by tileheight
	mov [.RowCounter],dl		;store number of rows to blit
    mov [TileImage.RowPtr],edi

	;figure tile column, tiles wide, starting tile byte...
	;col tile = (scrollx \ tilewidth) and (mapwidth - 1)
	movzx edx,word [SnesState.ScrollX]		;get bg's vertical scroll
    add edx,[BgScene.LeftCol]       ;add LeftCol to scroll !
	mov edi,edx			;copy horizontal offset to edi
	shr edx,3			;divide horizontal offset by tile width (always 8)
	and edx,127			;wrap offset to fit into bg width (always 128)
    mov [.StartingColTile],dl ;store strarting tile column
	and edi,7			;get pixel column offset into current tile (0-7)
    neg edi             ;get pixel column left of tile
	shl edx,1			;multiply ColumnTile by 2
    mov [.StartingColPixel],edi  ;set starting pixel column for each row
    mov [TileImage.PixelCol],edi ;set starting pixel column for tile blitter
	;---
	mov [.TilemapColPtr],dx		;store tile base for current tile row
	add dx,[.TilemapRowPtr]		;get complete tile address for row/column
	mov [.TilemapPtr],dx		;store starting address
	;---
        mov edx,[BgScene.Width]
	sub edx,edi			;add pixel row offset to height
	add edx,byte 7		;add tileheight minus one
	shr edx,3			;divide width of window by tilewidth
    mov [.StartingColCounter],dl ;store number of columns to blit

	mov [TileImage.BitMask],byte 0FFh;store for BlitTileImage to use

	;check bg transparency and set
	;render from top to bottom, left to right
	;wrap at column 127
	;wrap at row 127

	;---now that all that is finally done, the loop starts here-----
	;rendering tiles from top to bottom, left to right

.NextTileRowM7:
    mov eax,[.StartingTileCounters]  ;reset .ColCounter and .ColTile
    mov [.TileCounters],eax

.NextTileColM7:
	movzx esi,word [.TilemapPtr]
	movzx eax,byte [esi+SnesState.VRAM]		;get tile number
	shl eax,7				;multiply by tile size to get graphic offset
	lea esi,[eax+SnesState.VRAM]		;add tile offset to VRAM
    mov edi,BgScene.CacheBuffer             ;set destination
	call ConvertToLinear.Mode7
	call BlitTileImage

	;--move right to next column tile--
	inc byte [.ColTile]
	test byte [.ColTile],127
	jz near .WrapColM7			;if (column and 127) = 0 then wrap column
	add word [.TilemapPtr],byte 2		;proceed to next tile, each is two bytes apart
.ReturnFromColWrapM7:				;return here from column wrap
	add dword [TileImage.PixelCol],byte 8;add tile width (always 8) to pixel column
	dec byte [.ColCounter]			;one less tile across
	jnz near .NextTileColM7			;continue to next tile if more left

	;--move down to next row of tiles--
	inc byte [.RowTile]
	test byte [.RowTile],127
	jz near .WrapRowM7			;if (row and 127) = 0 then wrap row
	mov esi,[.TilemapRowPtr]
	mov edx,[.TilemapColPtr]
	add esi,256				;proceed to next tile row
	add edx,esi
	mov [.TilemapRowPtr],si
.ReturnFromRowWrapM7:				;return here from row wrap
	mov [.TilemapPtr],dx			;set tile ptr to value from above or WrapRow
    mov ecx,[.StartingColPixel]     ;get column at the start of each row
    mov edi,[BgScene.Width]         ;RowPtr += SceneWidth * 8
	add dword [TileImage.PixelRow],byte 8;add tile height to pixel row
    shl edi,3                       ;*8
    mov [TileImage.PixelCol],ecx    ;set pixel column to precolumn
    add [TileImage.RowPtr],edi
	dec byte [.RowCounter]			;one less tile row down
	jnz near .NextTileRowM7			;continue to next row if more left
	ret

.WrapColM7:
	mov ax,[.TilemapRowPtr]			;get tile ptr for current row
	mov byte [.ColTile],0			;set current tile column to zero
	mov [.TilemapPtr],ax			;set tilemap ptr to row base ptr
	jmp .ReturnFromColWrapM7			;jump back into inner loop

.WrapRowM7:
	mov word [.TilemapRowPtr],0			;store tile ptr for current row
	mov dx,[.TilemapColPtr]			;get column offset
	mov byte [.RowTile],0			;set current tile row to zero
	jmp .ReturnFromRowWrapM7			;jump back into outer loop

SECTION .data
align 4
.CurrentBgPtr:      dd SnesState.BgInfo ;height, width, bitdepth, tilesize...
.GraphicsBase:      dd 0        ;the graphics base of the current bg
.GraphicsBaseTile:  dd 0
.CacheIndexBase:    dd 0        ;BgScene.CacheIndexes+4096
.CacheIndexMask:	dd (65536/16)-1
.TileByteSize:      dd 32       ;size in bytes of tiles
.StartingColPixel:  dd 0        ;starting pixel column each row
.TilemapPtr:        dw 0        ;ptr to current map tile (each is two bytes) in VRAM
.TilemapRowPtr:     dw 0        ;beginning tile of current row
.TilemapColPtr:     dw 0        ;offset from row tile ptr
.StartingTileCounters:          ;paired dword
.RowTile:           db 0        ;current tile row in playfield
.RowCounter:        db 16       ;number of tile rows remaining
.StartingColTile:   db 0        ;starting tile column each row
.StartingColCounter:db 16       ;number of tile columns per row
.TileCounters:                  ;paired dword
                    db 0,0      ;dummies for RowTile and RowCounter
.ColTile:           db 0        ;current tile column in playfield
.ColCounter:        db 16       ;number of tile columns remaining
.PriorityMask:      db 0        ;mask to xor tile data with
.TileSizeShift:     db 4        ;amount to shift tile number to get graphic address
%ifdef CodeTimed
.LastTime:		dd 0
.RenderTime:	dd 0		;hack test timer
.RenderedTimes:	dd 0
%endif
SECTION .text

;------------------------------
; RenderSprites (words layer)
;
; It searches through all 128 sprites searching for ones of the specified layer, then
; creates them and renders them. If the sprite is set to the bottom of the screen, it
; will correctly the split the sprite into top half and bottom half (or maybe that
; should be bottom half and top half).
;
; Destination is BgScene.ImageBuffer.
; Top row, left column, height, & column are not passed as parameters but are
; set before calling.
;
RenderSpriteLayer:
	;set bitdepth of sprites to 4
	;check sprite transparency and set
	;set current sprite to 0
	;compare current sprite layer with desired layer
	;if not matched then next sprite
	;convert sprite to a linear bitmap
	;check to see if sprite is in the scene piece
	;if not then next sprite
	;get sprite number byte position and small/large size
	;call MakeBplArrayImage (words source, size)
	;get sprite palette and flip
	;if sprite transparency palette is 4-7 set to addition/subtraction
	;otherwise to opaque
	;blit sprite image into scene
	;if sprite is vertically split then blit bottom half of sprite into scene
	;next sprite until past 127
	;ret

;------------------------------
; BlitTileImage (palettebase, size)
;
; This is the most essential routine of scene rendering; without it, nothing
; would work. It should support opaque blitting for both 8bit and 15bit,
; additive transparency and subtractive transparency for 15bit, and possibly
; 16x8 streching. Should perform clipping.
;
; Destination is BgScene.ImageBuffer
; Source is in BgScene.CacheBuffer
; Top row, left column, height, & column are not passed as parameters but
; are set before calling.
; Addition/subtraction/opaque is also set before calling. It is irrelevant
; if the 8bit routine is called.
; Height and width are always square
;
;------------------------------
BlitTileImage:
	.DefaultTileSize	equ 16
%if DrawToScreen=1
	.BufferDest	equ 0A0000h
%else
    .BufferDest     equ BgScene.ImageBuffer
%endif
	;clip left and right
	;clip top and bottom
	;calculate starting pixel
	;jump to 8 bit or 15 bit routine
	;--8bit--
	;--15bit--
    ;double starting pixel because each pixel is two bytes
	;jump to correct additive/subtractive/opaque routine

	mov esi,[TileImage.ImgSource]		;get offset in cache of image to blit
	mov eax,[TileImage.PixelRow]
    mov edi,[TileImage.RowPtr]
    add esi,BgScene.CacheBuffer             ;turn offset into pointer
	mov ecx,[TileImage.PixelCol]
	cmp eax,200-.DefaultTileSize
	.BottomClip	equ $-4
	ja near .Clipped
	cmp ecx,320-.DefaultTileSize
	.RightClip	equ $-4
	ja near .Clipped
    add edi,ecx                 ;RowPtr += Column

    xor edx,edx
    test byte [TileImage.Flip],BgTileVflip>>8
    jz .NoVflip
    add esi,.DefaultTileSize-1
    .TileFlipSize   equ $-4
    mov edx,[TileImage.Width]
    shl edx,1
.NoVflip:

	mov bl,[TileImage.Palette]	;get palette index base
	mov bh,bl
	shrd ecx,ebx,16
	shld ebx,ecx,16			;make word into dword
    mov [.PaletteDword],ebx
	mov ecx,((.DefaultTileSize-1)<<16)|(.DefaultTileSize/4)
	.TileSize equ $-4			;upper ecx = (height-1), cl = (height/4)
	cld
    mov ch,[TileImage.BitMask]

	test byte [TileImage.Flip],BgTileHflip>>8
    jnz near .Hflipped

   ;cmp edi,BgScene.ImageBufferSize;64000
   ;jb .ok
   ;int3
   ;.ok:

.NextRow:
    push edi
    mov cl,[.TileSize]  ;8/4=2 16/4=4 .. 64/4=16
.NextCol:
    ;cmp edi,BgScene.ImageBufferSize
    ;jb .ok1
    ;int3
   ;.ok1:
	lodsd			;read dword from tile image source
	test eax,eax
	jz .SkipPixels
    add eax,[.PaletteDword]
	mov ebx,[edi+.BufferDest]	;read dword from destination
	test al,ch		;check first pixel
	jnz .SkipPixel0	;skip if not transparent
	mov al,bl
.SkipPixel0:
	test ah,ch		;check second pixel
	jnz .SkipPixel1
	mov ah,bh
.SkipPixel1:
	rol eax,16		;get access to third and fourth pixels
	shr ebx,16
	test al,ch		;check third pixel
	jnz .SkipPixel2
	mov al,bl
.SkipPixel2:
	test ah,ch		;check fourth pixel
	jnz .SkipPixel3
	mov ah,bh
.SkipPixel3:
	rol eax,16
	mov [edi+.BufferDest],eax	;four pixels written to buffer
.SkipPixels:
	add edi,byte 4
	dec cl
	jnz .NextCol

    pop edi
    sub esi,edx
    add edi,[BgScene.Width]     ;next row
	sub ecx,65536
	jnc .NextRow
	ret

.Hflipped:
    add edi,[TileImage.Width]
.HfNextRow:
    push edi
	mov cl,[.TileSize]	;8/4=2 16/4=4
.HfNextCol:
    ;cmp edi,BgScene.ImageBufferSize
    ;jb .ok2
    ;int3
   ;.ok2:
	lodsd			;read dword from tile image source
	sub edi,byte 4
	test eax,eax
	jz .HfSkipPixels
    add eax,[.PaletteDword]
	rol eax,16		;swap pixels 1&2 with 3&4
	mov ebx,[edi+.BufferDest]	;read dword from destination
	xchg al,ah		;reverse third and fourth
	test al,ch		;check first pixel
	jnz .HfSkipPixel0
	mov al,bl
.HfSkipPixel0:
	test ah,ch		;check second pixel
	jnz .HfSkipPixel1
	mov ah,bh
.HfSkipPixel1:
	rol eax,16		;get access to first and second pixels
	shr ebx,16
	xchg al,ah		;reverse third and fourth
	test al,ch		;check third pixel
	jnz .HfSkipPixel2
	mov al,bl
.HfSkipPixel2:
	test ah,ch		;check fourth pixel
	jnz .HfSkipPixel3
	mov ah,bh
.HfSkipPixel3:
	rol eax,16		;arrange pixels 1&2 3&4 correctly
	mov [edi+.BufferDest],eax	;four pixels written to buffer
.HfSkipPixels:
	dec cl
	jnz .HfNextCol

    pop edi
    sub esi,edx
    add edi,[BgScene.Width]     ;next row
	sub ecx,65536
	jnc .HfNextRow
.End:
	ret

;(eax=row, ecx=col)
.Clipped:       ;should not be directly called
    mov edx,[TileImage.Width]
    test byte [TileImage.Flip],BgTileVflip>>8
    jz .ClippedNoVflip
    add esi,[.TileFlipSize]
    neg edx
.ClippedNoVflip:

    mov ebx,[TileImage.Height]
    test eax,eax
    jns .RowTopOk
    xor edi,edi
    add ebx,eax                 ;tileheight + -row
    jle .End                    ;end if height negative or zero
    push ecx
    push eax
    test byte [TileImage.Flip],BgTileVflip>>8
    mov cl,[TileImage.SizeShift+1];get width shift
    jnz .RowVflip
    neg eax                     ;make negative row into positive
.RowVflip:
    shl eax,cl
    add esi,eax                 ;source + row
    pop eax
    pop ecx
.RowTopOk:
    sub eax,[.BottomClip]       ;bottom clip - row
    jle .RowBtmOk
    sub ebx,eax                 ;height - bottom clip + row
    jbe .End                    ;end if height negative or zero
.RowBtmOk:

    mov eax,[TileImage.Width]
    test ecx,ecx
    jns .ColLeftOk
    add eax,ecx                 ;tilewidth + -col
    jle .End                    ;end if width negative or zero
    test byte [TileImage.Flip],BgTileHflip>>8
    jnz .ColHflip
    sub esi,ecx                 ;source - -column (x - -y = x + y)
    jmp short .CheckColRight    ;leave edi alone
.ColHflip:
    add esi,ecx                 ;source + -column (x + -y = x - y)
    jmp short .CheckColRight    ;leave edi alone
.ColLeftOk:
    add edi,ecx
.CheckColRight:
    sub ecx,[.RightClip]        ;right clip - column
    jle .ColRightOk
    sub eax,ecx                 ;width - right clip + column
    jbe .End                    ;end if width negative or zero
.ColRightOk:
    mov ecx,eax

    test byte [TileImage.Flip],BgTileHflip>>8
    mov ah,[TileImage.Palette]  ;get palette index base
    jnz .ClHflipped

;(ebx=height, ecx=width)
    sub edx,ecx                 ;wrap - width
    mov ch,[TileImage.BitMask]
.ClNextRow:
    mov bh,cl
    push edi
.ClNext:
    ;cmp edi,BgScene.ImageBufferSize
    ;jb .ok3
    ;int3
   ;.ok3:
    mov al,[esi]
    test al,ch
    jz .ClSkipPixel
    add al,ah
    mov [.BufferDest+edi],al
.ClSkipPixel:
    inc esi
    inc edi
    dec bh
    jnz .ClNext
    pop edi
    add esi,edx
    add edi,[BgScene.Width]
    dec bl
    jnz .ClNextRow
    ret

.ClHflipped:
;(ebx=height, ecx=width)
    add edx,ecx                 ;wrap + width
    add esi,[TileImage.Width]   ;flip horizontally
    dec esi
    mov ch,[TileImage.BitMask]
.ClHfNextRow:
    mov bh,cl
    push edi
.ClHfNext:
    ;cmp edi,BgScene.ImageBufferSize
    ;jb .ok4
    ;int3
   ;.ok4:
    mov al,[esi]
    test al,ch
    jz .ClHfSkipPixel
    add al,ah
    mov [.BufferDest+edi],al
.ClHfSkipPixel:
    dec esi
    inc edi
    dec bh
    jnz .ClHfNext
    pop edi
    add esi,edx
    add edi,[BgScene.Width]
    dec bl
    jnz .ClHfNextRow
    ret

SECTION .data
align 4
.PaletteDword:  dd 0
SECTION .text

;--------------------
; (al=height, ah=width, eal=height shift, eah=width shift)
;
.SetSize:
    movzx ebx,al        ;extend height
    movzx ecx,ah        ;extend width
    shr eax,16          ;access height/width size shifts
    mov [TileImage.Height],ebx
    mov [TileImage.SizeShift],ax
    mov eax,ebx         ;copy height
    mov [TileImage.Width],ecx
    imul eax,ecx        ;(Height*Width)-Width
    lea edx,[ebx-1]     ;copy height
    sub eax,ecx
    shl edx,16          ;move height into upper word
    mov [.TileFlipSize],eax
    mov dl,cl           ;width into low byte
    shr dl,2            ;/4
    neg ebx
    mov [.TileSize],edx
	neg ecx
    add ebx,[BgScene.Height] ;height-tileheight
    add ecx,[BgScene.Width]  ;width-tilewidth
    mov [.BottomClip],ebx    ;default is 200-8
    mov [.RightClip],ecx     ;           320-8
	ret

;============================================================
align 16
ConvertToLinear:
;------------------------------
; Converts VRAM 8x8 bitplane tiles to a linear bitmap.
; This routine works for any bitplane mode, including 1,2,3,4, & 8.
; It even works for NES and GameBoy graphics, with the right table.
;
; Basically this function loops the number of bitplanes that are in the tile,
; ORing each bitplane onto the current pixel row and rolling them until the
; full color depth for eight pixel columns is achieved. This is not the
; fastest code for translation, but it is the most versatile, being able to
; handle any bitplane format without compromising on too much speed.
;
; (esi=raw tile source, edi=linear destination, ecx=bitdepth) ()
;   No regs preserved, not even ebp
;
.Bitplane:
    ;ecx=bitplanes
	;ebx=ptr to jump table
	;esi=ptr to raw source data
	;edi=ptr to linear bitmap or screen
	;ebp is destroyed

	mov ebx,[.BitplanePtrTable+ecx*4]
	mov ch,8	;set row counter to 8 rows

.BplNextRow:
    ;cl=bitplanes
    ;ch=row counter
	;eax=pixel columns 0-3 of current row
	;edx=pixel columns 4-7 of current row

    mov eax,ecx ;copy bitplanes
	shl ecx,16	;save bitplanes and row counter 
    or ecx,eax  ;set plane counter to number of planes
	xor edx,edx
	xor eax,eax	;set both to zero

.NextBitplane:
	;cl=bitplane counter
	;ch=data
	movsx ebp,byte [ebx]	;move source to next bitplane (same row) using table
	inc ebx
	add esi,ebp
	mov ch,[esi]	;get next bitplane
	
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
	ror eax,1	;roll pixels left to not let the next bitplane clobber this one
	ror edx,1	;rolling right would reverse the the bits, not desirable

	dec cl
	jnz .NextBitplane

	shr ecx,16	;get access to bitplanes and row counter
	rol eax,cl	;compensate for the prior ror's by rolling it left by an equal
	rol edx,cl	;number of times it was rolled right above (which is the number of bitplanes)
	;add eax,[TileRoutines.Palette]
	;add edx,[TileRoutines.Palette]
	mov [edi],eax	;write first four left pixels
	mov [edi+4],edx	;write second four right pixels
	add edi,[ConvertToLinear.DestWidth] ;add bitmap width to dest for next row down

	dec ch
	jnz near .BplNextRow

	ret

;------------------------------
; Makes a single 8x8 linear bitmap from an SNES interleaved mode 7 tile.
; Source is always VRAM; Destination is BgScene.CacheBuffer
;
; (esi=source, edi=linear destination)
;
.Mode7:
	inc esi
	mov ch,8
.NextRow:
	mov cl,4
.NextCol:
	movsb
	inc esi
	movsb
	inc esi
	dec cl
	jnz .NextCol
	dec ch
	jnz .NextRow
	ret

%ifdef codeready
        mov edi,BgScene.CacheBuffer           ;set destination
	mov ch,8
.NextRow:
	mov eax,[esi+4]			;get third and fourth pixels
	mov ebx,[esi]			;get first and second pixels
	mov ah,al				;move third pixel closer to fourth
	shl eax,8				;shift two pixels into top of dword
	mov al,bl				;copy first pixel into ebx
	shr ebx,8				;get access to second pixel in eax
	mov ah,bh				;copy second pixel into ebx
	;mov [edi],eax			;store first four pixels of merged dword
	stosd
	mov eax,[esi+12]			;get seventh and eighth pixels
	mov edx,[esi+8]			;get fifth and sixth pixels
	mov ah,al				;move seventh pixel closer to eighth
	shl eax,8				;shift two pixels into top of dword
	mov al,dl				;copy fourth pixel into ebx
	shr edx,8				;get access to fifth pixel in edx
	mov ah,dh				;copy fifth pixel into ebx
	;mov [edi+4],edx			;store second four pixels of merged dword
	stosd
	add esi,byte 16
	dec ch
	jnz .NextRow
	ret
%endif

.Blank:
    mov esi,.BlankTilePattern
	mov ecx,64/4
	cld
    rep movsd
	ret

SECTION .data
align 4
.DestWidth:	dd 320
.BitplanePtrTable:
        dd .8x8_1,.8x8_1,.8x8_2,.8x8_3,.8x8_4,.8x8_4,.8x8_4,.8x8_4,.8x8_8
.8x8_1:
.8x8_2:	db 0,1,1,1,1,1,1,1,  1,1,1,1,1,1,1,1
.8x8_3:	;db 0,1,15,-14,1,14,-13,1,13,-12,1,12,-11,1,11,-10,1,10,-9,1,9,-8,1,8
.8x8_4:	db 0,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1
.8x8_8:	db 0,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1
;note that SNES bit modes 1 and 2 (and even the GameBoy) all use the same first table

align 4
.BlankTilePattern:
        db 48,32,48,32,48,32,48,16
        db 32,48,32,48,32,48,16,48
        db 48,32,48,32,48,16,48,16
        db 32,48,32,48,16,48,16,48
        db 48,32,48,16,48,16,48,16
        db 32,48,16,48,16,48,16,48
        db 48,16,48,16,48,16,48,00
        db 16,48,16,48,16,48,00,48
SECTION .text

;------------------------------
CacheReset:
        xor eax,eax
        mov [BgScene.CacheListPtr],eax  ;reset both pointers
	mov [TileImage.ImgSource],eax

        dec eax                         ;set to -1
	cld
        mov edi,BgScene.CacheIndexes    ;.CacheList too
	mov ecx,(15360+1024)/2
        rep stosd                       ;wipe out index and list
	ret

;------------------------------------------------------------
;------------------------------
;
CgramPaletteConvert:
    mov esi,SnesState.CGRAM     ;SNES colors in 15-bit format
    mov edi,[ScreenPalettePtr]  ;dest is the palette
    test edi,edi                ;has one been allocated?
    jz .End
    xor ebx,ebx                 ;assume normal palette
    test byte [BgScene.Options],BgScene.Options_InvertPalette
    jz .PaletteNotInverted
    dec ebx                     ;inverted palette
.PaletteNotInverted:
    mov edx,256                 ;the SNES has a 256-color palette
    mov cl,2                    ;for now, just turn 32 shade SNES into 64 shade VGA
    cld                         ;as always, go forward
.NextColor:
    lodsw                       ;get BGR color tuple (the SNES color is reversed from normal)
    xor eax,ebx
    shl eax,3                   ;isolate red
    shr al,cl                   ;divide by factor
    stosb                       ;save red to destination
    shr eax,5                   ;get green and blue
    and eax,(31<<3)|(31<<8)     ;mask out any extra bits
    shl ah,3                    ;move blue higher
    shr eax,cl                  ;divide both by factor
    stosw                       ;store green and blue
    dec edx
    jnz .NextColor
.End:
	ret

;------------------------------
; Gets result of any color plus background color constant
;
; (edi=64 shade color to be added to) (eax=result)
;
SetColorBackground:
	mov eax,[edi]
.GivenColor:
; (eax=64 shade color to add to, edi=destination) (eax=result)
	mov ebx,[SnesState.FixedColor]
	lea eax,[eax+ebx*2]	;add background color (*2) to dest color
	mov ecx,3
.Next:
	cmp al,64
	jb .ValidColor
	mov al,63			;otherwise limit to brightest value
.ValidColor:
	ror eax,8
	dec ecx
	jnz .Next
	mov [edi],ah		;set color value
	shr eax,16
	mov [edi+1],ax		;set other two color values
	ret

;------------------------------------------------------------
;------------------------------
; Fills scene buffer with VRAM tiles.
;
; ()() - No regs saved
;
VramTileFill:
    mov bl,[VramFormat.PaletteBase]
    movzx eax,byte [VramFormat.TileFormat]  ;make ptr of tile format
    mov bh,bl                               ;make palette base into word
    shrd ecx,ebx,16
    shld ebx,ecx,16                         ;and now palette dword
	mov edx,[VramFormat.TileConverters+eax*4]
    mov [.DefaultPalette],ebx               ;set palette base dword
    mov ecx,[VramFormat.PaletteMasks+eax*4] ;palette mask for default tile format
	mov [.TileConverter],edx
    mov [.PaletteMask],ecx                  ;set palette mask
    push ebp
	mov dword [ConvertToLinear.DestWidth],8
    push dword [.Dimensions]
    push dword BgScene.ImageBuffer
    push dword BgScene.ImageBuffer
	push dword [.SourceTile]

.NextTile:
    mov esi,[esp]                   ;get source in VRAM
    mov edi,BgScene.ImageBuffer + BgScene.ImageBufferSize - 64  ;set destination for tile converter
    mov ebx,esi
    shr ebx,4                       ;from address to table index
    mov eax,[VramFormat.Table+ebx*2];get tile format/palette word

    bt dword [VramFormat.UsePalTable],ebx
    jc .UseTablePalette             ;use palette in table
    mov edx,[.DefaultPalette]
    jmp short .SetPalette
.UseTablePalette:
    mov edx,eax
    mov dl,dh                       ;make palette base into word
    shrd ecx,edx,16
    shld edx,ecx,16                 ;and now dword
.SetPalette:
    bt dword [VramFormat.UseGfxTable],ebx
    jnc .UseCurrentGfx              ;don't use table, just the current tile format
    and eax,7                       ;make ptr of tile format
    and edx,[VramFormat.PaletteMasks+eax*4] ;mask palette to tile colors
    mov ecx,[VramFormat.TileSizes+eax*4]    ;get tile size in bytes
    mov [.PaletteDword],edx         ;save for later
    add esi,SnesState.VRAM
    add [esp],cx                    ;move forward in VRAM by increment
    shr ecx,3                       ;/8 tile size to bitplane depth
    call dword [VramFormat.TileConverters+eax*4]
    jmp short .DrawTile
.UseCurrentGfx:
    and edx,[.PaletteMask]          ;mask palette to tile colors
    mov ecx,[VramFormat.BitDepth]   ;bitdepth (or number of bitplanes)
    mov [.PaletteDword],edx         ;save for later
    mov edx,[VramFormat.TileSize]
    add esi,SnesState.VRAM
    add [esp],dx                    ;move forward in VRAM by increment
    call [.TileConverter]

.DrawTile:
    mov edi,[esp+4]                 ;get destination
    mov esi,BgScene.ImageBuffer + BgScene.ImageBufferSize - 64
    mov ebx,[.PaletteDword]
    mov ecx,8
.NextPixelRow:
    mov eax,[esi]
    add eax,ebx
    mov [edi],eax
    mov eax,[esi+4]
    add eax,ebx
    mov [edi+4],eax
    add esi,byte 8
    add edi,128
    dec ecx
    jnz .NextPixelRow

    add dword [esp+4],byte 8        ;add destination offset
    dec byte [esp+12]               ;column counter
    jnz near .NextTile

    mov edi,[esp+8]                 ;get column destination
    add edi,8*128                   ;next eight rows down in destination
    mov [esp+4],edi                 ;set column destination
    mov [esp+8],edi                 ;and row destination
    mov byte [esp+12],.Columns      ;refresh column counter
    dec byte [esp+14]               ;row counter
    jnz near .NextTile

    add esp,byte 16                 ;restore stack
    pop ebp
	ret

align 4
.SourceTile:	dd 0
.PaletteDword:	dd 0
.DefaultPalette:dd 0
.PaletteMask:   dd 0
.TileConverter:	dd ConvertToLinear.Bitplane
.Rows		equ 23
.Columns	equ 16
.Dimensions:    dd .Columns | (.Rows<<16)

;------------------------------
; Seeks to a new position in VRAM forwards.
;
; (esi=starting byte, ecx=tiles to seek) (esi=new position, ecx=tiles left, zf=no change)
;
; Upon returning, ecx is 0 if new position was reached. If position could not
; be set because of reaching the beginning, ecx contains the number of tiles
; left. zf is set if no change and new position equals.
;
SeekVramTilesForward:
	;mov esi,[VramTileFill.SourceTile]
	cmp esi,(VramFormat.TableSize-1)*16
	jae .AfterVram
    shr esi,4                               ;/16 from address to index
    mov eax,esi                             ;make copy of index
.NextTile:
    bt dword [VramFormat.UseGfxTable],esi
    jc .UseTableGfx
    add eax,[VramFormat.TileEntry]          ;move forward by size of tile
    jmp short .UsedCurrentGfx
.UseTableGfx:
    movzx ebx,byte [VramFormat.Table+esi*2] ;make ptr of tile format
    add eax,[VramFormat.TileEntries+ebx*4]  ;move forward by size of tile (actually number of entries used)
.UsedCurrentGfx:
    cmp eax,VramFormat.TableSize            ;check that not past end of table
	jae .AtEnd
    mov esi,eax                             ;now that we're sure position is ok, copy to esi
    dec ecx                                 ;one less tile
	jnz .NextTile
.AtEnd:
    shl esi,4                               ;*16 from index to address
.End:
	cmp esi,[VramTileFill.SourceTile]
	ret

.AfterVram:
	mov esi,(VramFormat.TableSize-1)*16
	jmp short .End

    ;mov eax,[VramTileFill.BitDepth]
    ;imul ecx                                        ;bitsize * tiles
    ;lea eax,[esi+eax*8]                     ;source + bytes forward
    ;cmp eax,VramFormat.TableSize*16
    ;jae .End                                        ;new position is invalid so cancel
    ;mov esi,eax                                     ;now that we're sure position is ok, copy to esi

;------------------------------
; Seeks to a new position in VRAM. If tile count is negative, then seek
; backwards otherwise seek forwards.
;
; (esi=starting byte, ecx=tiles to seek) (esi=new position, ecx=tiles left, zf=no change)
;
SeekVramTiles:
	test ecx,ecx
    jz SeekVramTilesForward.End
	jns near SeekVramTilesForward

;------------------------------
; Seeks to a new position in VRAM backwards.
;
; (esi=source, ecx=negative tiles to seek) (esi=new position, ecx=tiles left, zf=no change)
;
; Upon returning, ecx is 0 if new position was reached. If position could not
; be set because of reaching the beginning, ecx contains the number of
; negative tiles left. zf is set if no change and new position equals.
;
SeekVramTilesBackward:
	;mov esi,[VramTileFill.SourceTile]
    shr esi,4                               ;/16 from address to index
    dec esi                                 ;move to tile just before
    cmp esi,VramFormat.TableSize*16
    jae .BeforeVram
.NextTile:
    bt dword [VramFormat.UseGfxTable],esi
    jc .UseTableGfx
    sub esi,[VramFormat.TileEntry]          ;move backward by size of tile
    jmp short .UsedCurrentGfx
.UseTableGfx:
    movzx ebx,byte [VramFormat.Table+esi*2] ;make ptr of tile format
    sub esi,[VramFormat.TileEntries+ebx*4]  ;move backward by size of tile (actually number of entries used)
.UsedCurrentGfx:
    js .BeforeVram                          ;check that not before end of table
    inc ecx                                 ;one less tile (we're counting up!)
	jnz .NextTile
    inc esi                                 ;adjust to next tile
    shl esi,4                               ;*16 from index to address
.End:
	cmp esi,[VramTileFill.SourceTile]
	ret

.BeforeVram:
	xor esi,esi
	jmp short .End

;------------------------------
; Returns the total number of tiles in VRAM given the current tile format
; or the table if it is being used.
;
; ()(eax=total tiles)
;
VramTilesTotal:
    xor eax,eax
	xor esi,esi
.NextTile:
    bt dword [VramFormat.UseGfxTable],esi
    jc .UseTableGfx
    add esi,[VramFormat.TileEntry]
    jmp short .UsedCurrentGfx
.UseTableGfx:
    movzx ebx,byte [VramFormat.Table+esi*2] ;make ptr of tile format
    add esi,[VramFormat.TileEntries+ebx*4]  ;move forward by size of tile (actually number of entries used)
.UsedCurrentGfx:
    inc eax                                 ;count one more tile to the total
    cmp esi,VramFormat.TableSize            ;check that not past end of table
    jb .NextTile
	ret

;------------------------------
; Sets a range of tiles in VRAM to use a certain format.
;
; (esi=first byte in VRAM, ecx=number of bytes, al=tile format)()
;
SetVramFormatRange:
    and eax,7               ;make pointer from tile format
    ;mov ebx,[VramFormat.TileSizes+eax*4]      ;get tile size
    add ecx,esi             ;get last byte in range
    mov dl,[VramFormat.PaletteMasks+eax*4]
    ;lea ecx,[ecx+ebx-1]     ;add (tilesize-1) to last byte
    add ecx,1023            ;add (tilesize-1) to last byte
    ;neg ebx                 ;make AND mask
    mov ebx,~1023
    and esi,ebx             ;round starting byte down
    and ecx,ebx             ;round ending byte up
    cmp esi,65536-15        ;if not in range, end
    jae .End
    cmp ecx,65536-15
    jb .RangeOkay
    mov ecx,65536
.RangeOkay:
    sub ecx,esi             ;difference between ending and starting byte makes the length
    shr esi,4               ;/16 starting byte to starting table index
    shr ecx,4               ;/16 length to number of indexes
    jz .End
.NextTile:
    mov ah,[VramFormat.Table+1+esi*2] ;get tile palette
    and ah,dl               ;mask old palette
    mov [VramFormat.Table+esi*2],ax
    bts dword [VramFormat.UseGfxTable],esi
    inc esi
    dec ecx
    jnz .NextTile
.End:
    ret

;------------------------------
; Sets a range of tile's palettes.
;
; (esi=first byte in VRAM, ecx=number of bytes, al=palette)
;
;SetVramPaletteRange:
;    shr esi,4               ;/16 starting byte to starting table index
;    and esi,VramFormat.TableSize-1          ;wrap index within table
;    jmp short SetVramTilePalette.NextTile

;------------------------------
; Sets a single tile's palette.
;
; (esi=first byte in VRAM, al=palette)
;
SetVramTilePalette:
    shr esi,4               ;/16 starting byte to starting table index
    and esi,VramFormat.TableSize-1          ;wrap index within table
    bt dword [VramFormat.UseGfxTable],esi
    jc .UseTableGfx
    mov ecx,[VramFormat.TileEntry]          ;get number of entries for current tile format
    jmp short .UsedCurrentGfx
.UseTableGfx:
    movzx ebx,byte [VramFormat.Table+esi*2] ;make ptr of tile format
    mov ecx,[VramFormat.TileEntries+ebx*4]  ;get number of entries for format of tile at position
.UsedCurrentGfx:
.NextTile:
    bts dword [VramFormat.UsePalTable],esi  ;mark palette as set
    mov [VramFormat.Table+esi*2+1],al       ;set new palette
    inc esi
    and esi,VramFormat.TableSize-1          ;wrap index within table
    dec ecx
    jnz .NextTile
.End:
    ret

;------------------------------
; Returns the palette at a specified location in VRAM.
;
; (esi=byte in VRAM)(al=palette)
;
GetVramTilePalette:
    shr esi,4               ;/16 starting byte to starting table index
    and esi,VramFormat.TableSize-1          ;wrap index within table
    bt dword [VramFormat.UsePalTable],esi
    jc .UseTableGfx
    mov al,[VramFormat.PaletteBase]         ;get current palette
    jmp short .UsedCurrentGfx
.UseTableGfx:
    mov al,[VramFormat.Table+esi*2+1]       ;get palette of tile at position
.UsedCurrentGfx:
    ret

;------------------------------
; Sets current tile format for VRAM tiles that do not have specific tile
; format specified.
;
; (al=tile format)() - No regs saved
;
VramFormatDefault:
    mov [VramFormat.TileFormat],al
    and eax,7               ;make ptr of tile format
    mov ecx,[VramFormat.TileSizes+eax*4]
    mov edx,[VramFormat.TileEntries+eax*4]
    mov ebx,ecx
    neg ebx
    mov [VramFormat.TileSize],ecx
    and [VramTileFill.SourceTile],ebx
    shr ecx,3               ;/8 tile byte size to bitdepth
    mov [VramFormat.TileEntry],edx
    mov [VramFormat.BitDepth],ecx
    ret

;------------------------------
; Clears bit tables for both graphics and palettes so that only the current
; tile format and palette are used.
;
; ()() - Regs not saved
VramReset:
    push dword .WipeTable
.Format:
    mov edi,VramFormat.UseGfxTable
    jmp short .WipeTable
.Palette:
    mov edi,VramFormat.UsePalTable
    ;jmp short .WipeTable
.WipeTable:
    mov ecx,VramFormat.TableSize / 32
    xor eax,eax                     ;set to zero to turn off table use
    cld
    rep stosd                       ;wipe out gfx and/or pal tables
	ret

;------------------------------
; Formats VRAM, by sectioning it into different parts of graphics formats.
;
; ()() - Regs not saved
VramFormatMainParts:
    mov edx,[BgScene.VisiblePlanes];main screen and subscreen (.MainScreen)
    or dl,dh                        ;gets all bgs active
    mov [BgScene.RenderPlanes],dl

    mov esi,-1              ;get first section, including anything that
    call .GetNextBase       ;might start at offset 0 in VRAM
    push eax                ;tile format of first part
    push esi                ;address of first part
.NextPart:
    call .GetNextBase
    xchg [esp],esi          ;save new address and get old one
    xchg [esp+4],eax        ;save new tile format and get previous one
    ;ecx = range count
    call SetVramFormatRange
    mov esi,[esp]
    cmp esi,65536
    jb .NextPart
    add esp,byte 8
    ret

; Checks mode 7 graphics, each bg 1-4 graphics base, sprites, and lastly each
; bg 1-4 tilemap base.
;
; (esi=starting VRAM address) (esi=next base, al=tile format)
.GetNextBase:
    mov ecx,65536                   ;initially point to end of VRAM
    movzx ebx,byte [SnesState.VideoMode]

    xor edi,edi                     ;start at offset 0 in VRAM
    mov eax,101h                    ;default tile format of 4bpl
    cmp bl,7
    jne .NotMode7
    mov ah,3                        ;use mode 7 tile format
    call .CheckPartPosition
.NotMode7:

    mov dl,[BgScene.RenderPlanes]
    ;and dl,[PlaneMasks+ebx]        ;not necessary, also causes some graphics to be missed
    test dl,1
    jz .NoBg1
    mov ah,[PlaneVramFormatTable+ebx*4]     ;get tile format for bg1
    mov di,[SnesState.BgInfo+Bg.TileBase]   ;get tile graphics base
    call .CheckPartPosition
.NoBg1:
    test dl,2
    jz .NoBg2
    mov ah,[PlaneVramFormatTable+1+ebx*4]
    mov di,[SnesState.BgInfo2+Bg.TileBase]
    call .CheckPartPosition
.NoBg2:
    test dl,4
    jz .NoBg3
    mov ah,[PlaneVramFormatTable+2+ebx*4]
    mov di,[SnesState.BgInfo3+Bg.TileBase]
    call .CheckPartPosition
.NoBg3:
    test dl,8
    jz .NoBg4
    mov ah,[PlaneVramFormatTable+3+ebx*4]
    mov di,[SnesState.BgInfo4+Bg.TileBase]
    call .CheckPartPosition
.NoBg4:

    test dl,16
    jz .NoSprites
    mov ah,1                        ;4bpl for sprites
    mov di,[SnesState.OAMTileBase]
    call .CheckPartPosition
.NoSprites:

    mov ah,5                        ;blank tile format
    test dl,1
    jz .NoMap1
    mov di,[SnesState.BgInfo+Bg.MapBase]    ;get tilemap base
    call .CheckPartPosition
.NoMap1:
    test dl,2
    jz .NoMap2
    mov di,[SnesState.BgInfo2+Bg.MapBase]
    call .CheckPartPosition
.NoMap2:
    test dl,4
    jz .NoMap3
    mov di,[SnesState.BgInfo3+Bg.MapBase]
    call .CheckPartPosition
.NoMap3:
    test dl,8
    jz .NoMap4
    mov di,[SnesState.BgInfo4+Bg.MapBase]
    call .CheckPartPosition
.NoMap4:
    mov ah,1                        ;default tile format of 4bpl
    xor edi,edi                     ;in case nothing above matches
    call .CheckPartPosition

    sub ecx,esi
    add esi,ecx
    ret

.CheckPartPosition:
    cmp edi,esi             ;ignore if less than current base
    jle .IgnorePosition
    cmp edi,ecx             ;ignore if greater than or equal to next base
    jae .IgnorePosition     ;already found
    mov ecx,edi             ;set new next base
    mov al,ah               ;set tile format
.IgnorePosition:
    ret

;------------------------------
; Searches through entire, finding all palettes used by sprites and bgs.
; It only searches through bg's that are active and sprites that are not
; offscreen (with Y set to line 240).
VramFormatSetPalettes:
    push ebp
    mov edx,[BgScene.VisiblePlanes];main screen and subscreen (.MainScreen)
    or dl,dh                ;gets all bgs active
    mov [BgScene.RenderPlanes],dl
    cld

    mov ebx,SnesState.BgInfo
    xor edx,edx             ;set starting plane to 0 (bg1)
.NextBg:
    bt dword [BgScene.RenderPlanes],edx
    jnc near .SkipBg
    mov ecx,[ebx+Bg.BitDepth] ;get bit depth, bit shift, and color mask
    test ch,ch              ;check bitdepth
    jz near .EndBgLoop      ;end if bitdepth 0
    push edx                ;save current plane number
    push ebx                ;save ptr to info for current bg

    movzx eax,word [ebx+Bg.MapSize]
    imul ah
    movzx esi,word [ebx+Bg.MapBase] ;get bg's map base address
    mov edx,eax             ;set total tiles counter
    movzx ebp,word [ebx+Bg.TileBase] ;get bg's graphics base address
    xchg cl,ch              ;reverse bitshift and bitdepth
    sub ecx,201h            ;bitdepth - 2, bitshift - 1
    mov eax,[ebx+Bg.TileSizes]
    shr eax,3               ;/8 tilesize pixel size to tile size (8=1,16=2)
    and eax,1100000011b     ;mask only tile height and width
    movzx edi,ah            ;extend tile width
    shl ah,cl               ;get number of tile entries, 1 << bitshift
    neg edi
    and edi,15              ;get 16-tile width
    push eax                ;save tilesize
    shl edi,cl
    push edi                ;save tiles per row
    shr ebp,4               ;/16 to get table index
    push ecx                ;save bitshift and bitdepth

.NextTile:
    mov edi,[SnesState.VRAM+esi] ;get tilemap word
    mov eax,edi             ;copy tileword for palette later
    and edi,1023            ;select tile address
    shl edi,cl              ;apply bitshift
    add edi,ebp             ;add current bg's graphics base to index
    and edi,VramFormat.TableSize-1  ;wrap index within table
    add si,2                ;next word (with 64k wrap)
    bt dword [VramFormat.UsePalTable],edi
    jc .IgnoreTile
    mov cl,ch               ;move bitdepth to lower byte for shifting
    and eax,1110000000000b  ;select 3bit palette
    shl eax,cl              ;apply bitdepth to palette
    mov ecx,[esp+8]         ;get tile height/width
.NextTableEntry:
    bts dword [VramFormat.UsePalTable],edi  ;mark palette as set
    mov [VramFormat.Table+edi*2+1],ah       ;set palette
    inc edi
    and edi,VramFormat.TableSize-1  ;wrap index within table
    dec ch                  ;one less column
    jnz .NextTableEntry
    mov ch,[esp+9]          ;get tile width
    add edi,[esp+4]
    dec cl                  ;one less row
    jnz .NextTableEntry
    mov ecx,[esp]           ;retrieve bitshift and bitdepth
.IgnoreTile:
    dec edx                 ;one less tilemap word
    jnz .NextTile

    add esp,byte 12
    pop ebx                 ;get ptr to info for current bg
    pop edx                 ;get current plane
.SkipBg:
    add ebx,SnesState.BgInfo_Size ;next bg info block
    inc edx                 ;next plane
    cmp edx,4
    jb near .NextBg
.EndBgLoop:

    test byte [BgScene.RenderPlanes],16
    jz near .IgnoreSprites
.ScanSprites:
    movzx ebp,word [SnesState.OAMTileBase] ;get sprite's graphics base address
    xor esi,esi             ;set starting sprite
    shr ebp,4               ;VRAM address to index
    push dword 2010402h
.NextSprite:
    mov di,[SnesState.OAM+esi*2+2]
;   if y=240 ignore sprite
    cmp byte [SnesState.OAM+esi*2+1],240
    je .IgnoreSprite
    mov eax,edi
    and edi,511
    shl edi,1               ;apply 4bpl bitshift to index
    add edi,ebp             ;add sprite's graphics base to index
    and edi,VramFormat.TableSize-1  ;wrap index within table
    bt dword [VramFormat.UsePalTable],edi ;check if palette already set
    jc .IgnoreSprite
    and eax,111000000000b   ;select 3bit palette from sprite word
    or eax,1000000000000b   ;adjust palette range to 128-255 and set tile format to 4bpl
    shl eax,3               ;apply 4bit depth to palette
    ; check whether small size or large size sprite
    mov ecx,[esp]           ;get sprite size height/width
    bt [SnesState.OAM+512],esi
    jc .LargeSprite
;    rol ecx,16              ;set to small sprite
.LargeSprite:
    mov ebx,edi
.NextSpriteTile:
    bts dword [VramFormat.UsePalTable],edi  ;mark palette as set
    mov [VramFormat.Table+edi*2+1],ah       ;set palette
    inc edi
    and edi,VramFormat.TableSize-1 ;wrap index within table
    dec ch
    jnz .NextSpriteTile
    mov ch,[esp+1]            ;get tile width
    add ebx,16*2
    mov edi,ebx
    dec cl
    jnz .NextSpriteTile
;.NextTableEntry:
;    inc edi
;    dec cl                  ;one less column
;       shl ah,2
;       or al,ah                ;set tile format 4bpl
;       mov [edi],ax
;       bts [VramFormat.UsePalTable],edi
;       inc edi
;       bts [VramFormat.UsePalTable],edi
;.NextTileRow
;       inc edi                 ;next tile to the right
;       and edi,VramFormat.TableSize-1
;       pop edi
;       add edi,byte 32         ;
;       and edi,VramFormat.TableSize-1
;       loop .NextTileRow
;       mov ah,al
;       mov [edi],ax
.IgnoreSprite:
;       bts  inc edi  bts
    add esi,byte 2
    cmp esi,256
    jb .NextSprite
;       dec 128
    pop ecx
.IgnoreSprites:
    pop ebp
    ret

;------------------------------
; (esi, edi, ecx=size:height,width, bl=palette, edx=dest wrap)
;
CopyPalettedBufferToScreen:
	mov bh,bl			;copy color byte
	shrd eax,ebx,16		;copy color word
	shld ebx,eax,16		;dword now consists of four pixels of the same color
	push ebp			;save base pointer
	movzx ebp,cx		;copy height
	test ebp,ebp
	jz .End
	;shr ecx,16			;get access to width
	;shl cx,6			;get width / 4 into ch (won't work if >= 1024)
	shr ecx,10			;down shift, 16-6=10
	shr cl,6			;get width mod 4 into cl
	push ecx
.NextRow:
	mov ecx,[esp]		;get width
.NextColumnBlock:
	lodsd
	add eax,ebx
	stosd
	dec ch
	jnz .NextColumnBlock
	test cl,cl
	jz .RowComplete
.NextColumnPixel:
	lodsb
	add al,bl
	stosb
	dec cl
	jnz .NextColumnPixel

.RowComplete:
	add edi,edx			;jump to next row in destination
	dec ebp
	jnz .NextRow

	pull ecx
.End:
	pull ebp
	ret

;------------------------------
; (esi, edi, ecx=size:height,width, edx=dest wrap)
;
CopyBufferToScreen:
	push ebp			;save base pointer
	movzx ebp,cx		;copy height
	test ebp,ebp
	jz .End
	;shr ecx,16			;get access to width
	;shl cx,6			;get width / 4 into ch (won't work if >= 1024)
    shr ecx,16          ;bring down width
    mov ebx,ecx         ;make copy
.NextRow:
    mov ecx,ebx
    shr ecx,2           ;get width / 4
    rep movsd
    mov ecx,ebx
    and ecx,3           ;get width mod 4
    rep movsb
	add edi,edx			;jump to next row in destination
	dec ebp
	jnz .NextRow
.End:
	pull ebp
	ret

;============================================================
%ifdef useoldcode
.Rows		equ 23
.Columns	equ 16
	mov dword [ConvertToLinear.DestWidth],128
	push dword .Columns | (.Rows<<16)
        push dword BgScene.ImageBuffer
        push dword BgScene.ImageBuffer
	mov ecx,[.BitDepth]
	shl ecx,3
	mov [.TileByteSize],ecx
	mov eax,[.SourceTile]
	add eax,SnesState.VRAM
	push eax
.NextTile:
	mov esi,[esp]			;get source
	mov edi,[esp+4]			;get destination
	mov ecx,[.BitDepth]		;number of bitplanes
	call ConvertToLinear.Bitplane
	mov eax,[.TileByteSize]
	add dword [esp+4],byte 8	;add destination offset
	add dword [esp],eax		;next tile in source
	dec byte [esp+12]		;column counter
	jnz .NextTile
	mov edi,[esp+8]		;get column destination
	add edi,8*128		;next eight rows down in destination
	mov [esp+4],edi		;set column destination
	mov [esp+8],edi		;and row destination
	mov byte [esp+12],.Columns	;refresh column counter
	dec byte [esp+14]			;row counter
	jnz .NextTile
	add esp,byte 16		;restore stack
	ret
%endif

;------------------------------
%ifdef codeready
;given a starting source, byte/word size, number of units to read,
;starting pixel in BgScene.Buffer, buffer pixel wrap, mask operation,
;tile size, and type of tile to output, it will fill BgScene.Buffer with the
;pixels of the tile row.
BuildTileRow:
.NextTile:
	dec byte [esp]
	jnz .NextTile
	ret

;read source unit and perform mask operation on it or none
;if style is snes_bitplane (2,3,8) then call bitplane tile converter
;if style is snes_linear (mode 7) then call linear tile converter
;if style is special tileset then use it instead
;if style is anything else then call internal colored block blitter
;advance to next pixel in buffer
;loop until all tiles have been blit

.TilePixelHeight:	db 16		;8/16
.TilePixelWidth:	db 16		;8/16
.BufferPixelWrap:	dd 128	;width of bitmap
.TileStyle:	db 0			;outputs either a colored block or graphic tile from VRAM
.OperationMask:	dw 1023	;default uses lower 10 bits of word to get tile number
.OperationShift:	db 0		;normally no shifting needs to be done
.UnitSize:		db 2		;bytes per unit, 1 for bytes, 2 for words
%endif

;------------------------------

;------------------------------------------------------------
%ifdef useoldcode
DumbTileSpeedTest:
	mov dword [.SourceTile],0
	mov eax,[Timer]
	mov [.StartTime],eax
.NextPage:
	push dword 16 | (25<<16)
	push dword 0A0000h+(320-128)
	push dword 0A0000h+(320-128)
	push dword [.SourceTile]
	add dword [esp],SnesState.VRAM
.NextTile:
	mov esi,[esp]			;get source
	mov edi,[esp+4]			;get destination
	mov ecx,4				;bitplanes
	call ConvertToLinear.Bitplane
	add dword [esp],byte 32		;next tile in source
	add dword [esp+4],byte 8	;add destination offset
	dec byte [esp+12]		;column counter
	jnz .NextTile
	mov edi,[esp+8]		;get column destination
	add edi,8*320		;next eight rows down in destination
	mov [esp+4],edi		;set column destination
	mov [esp+8],edi		;and row destination
	mov byte [esp+12],16		;refresh column counter
	dec byte [esp+14]			;row counter
	jnz .NextTile

	add esp,byte 16			;free stack variables
	mov eax,[.SourceTile]
	inc eax
	mov [.SourceTile],eax
	cmp eax,2048
	jb .NextPage

	mov eax,[Timer]
	mov [.EndTime],eax
	sub eax,[.StartTime]
	mov [.TotalTime],eax
	mov edi,.MessageTotalTime
	call MakeNumString
    DrawBox 170,199,0,140,ColorLrGray
	FontBlitStr .MessageTotalTime,15,180,0
	ret

.SourceTile:	dd 0
.StartTime:		dd 0
.EndTime:		dd 0
.TotalTime:		dd 0

.MessageTotalTime:	db '         clicks'
%endif

%if DrawToScreen=2
ShowEntireCache:
	pusha
    mov esi,BgScene.CacheBuffer
	mov edi,0A0000h
	cld
	mov dl,25
.NextTileRow:
	mov dh,40
.NextTileCol:
	mov cl,8
.NextPixelRow:
    movsd
    movsd
	add edi,320-8
	dec cl
	jnz .NextPixelRow
	sub edi,(320*8)-8
	dec dh
	jnz .NextTileCol
	add edi,320*7
	dec dl
	jnz .NextTileRow
	popa
	ret
%endif
