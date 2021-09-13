; PGFXHL.ASM - Plain Graphics High Level Functions (v3.0)
; These functions are called by application code,
; rather than the low level ones.
;
;______________________________________________________________________________
; Currently working on:                                                                    	
; -Image tiling, scaling, flipping
; -Font blitting, prerendered bitmap glyphs
; -Color/pattern fills, rectangular
; -Clipping, rectangular
; -Mouse cursors 32x32, animated, blend ops
; -Operations directly to screen or virtual buffers
; -Operations on color 32bit, 8bit mono, and 1bit masks
; -Selective screen updates to 8bit/16bit/24bit
; -Scrolling section of display
; -Palette setting
; -DirectDraw
;
; Supports:
; -Images opaque, colormapped, colorkeyed, translucent...
; -Blending operations addition, multiplication, and...
; -MMX
;
; Will not support:
; -Image rotation
; -Rarely used ROPs like XOR and NAND
; -True type fonts
; -Flood, elliptical, or polyline fills
; -Complex or bitmapped clipping regions
; -Cursors larger than 32x32
; -Hue/saturation/contrast operations
; -4/15/16/24bit operations
; -All combinations of operation and bitdepth
; -Vector graphics

; The compiler WILL complain about options.h missing at first.
; You should copy the file to your project directory to customize
; the options (rather changing the source files directly).
;
;______________________________________________________________________________

%define pgfxhl_asm
%include "pgfx.h"
%include "pgfxlayr.h"

section .data

; substitute default values for those not given
; (must use silly underscores because C processor dislikes periods)
%ifndef Display_pixelsDef
  %assign Display_pixelsDef 0
  ; point to NULL, since that is safest
%endif
%ifndef Display_widthDef
  %assign Display_widthDef 320
%endif
%ifndef Display_heightDef
  %assign Display_heightDef 240
%endif
%ifndef Display_bpplsDef
  %assign Display_bpplsDef 5
  %assign Display_bppDef 1<<Display_bpplsDef
  ; 2 << 5 = 32bpp
%endif
%ifndef Display_wrapDef
  ;%assign Display_wrapDef ((Display_widthDef << Display_bpplsDef)+31) >> 3
  %assign Display_wrapDef ((Display_widthDef << Display_bpplsDef)) >> 3
%endif


global PgfxDisplay.pixels
global PgfxDisplay.wrap
global PgfxDisplay.left
global PgfxDisplay.top
global PgfxDisplay.width
global PgfxDisplay.height
global PgfxDisplay.clipLeft
global PgfxDisplay.clipTop
global PgfxDisplay.clipRight
global PgfxDisplay.clipBottom
global PgfxDisplay.redrawLeft
global PgfxDisplay.redrawTop
global PgfxDisplay.redrawRight
global PgfxDisplay.redrawBottom
%ifdef _WINDOWS
global PgfxDisplay.hwnd
global PgfxDisplay.hdcc
global PgfxDisplay.hdib
%endif

align 4, db 0
csym PgfxDisplay
istruc PgtDisplayFull
; atl automatically checks the corresponding structure member
; and declares a full major.minor label for each.
atl .pixels,		dd Display_pixelsDef
atl .wrap,			dd Display_wrapDef
atl .left,			dd 0
atl .top,			dd 0
atl .width,			dd Display_widthDef
atl .height,		dd Display_heightDef
atl .clipLeft,		dd 0
atl .clipTop,		dd 0
atl .clipRight,		dd Display_widthDef
atl .clipBottom,	dd Display_heightDef
atl .redrawLeft,	dd 0
atl .redrawTop,		dd 0
atl .redrawRight,	dd Display_widthDef
atl .redrawBottom,	dd Display_heightDef
%ifdef _WINDOWS
atl .hwnd,			dd 0
atl .hdcc,			dd 0
atl .hdib,			dd 0
%endif
iend

%ifdef PlainUseCursor
; Notice there are no mouse specific variables in here. That's because the
; graphics routines have nothing to do with the mouse driver. They simply
; display the cursor. After all, it's possible for a cursor to exist without
; a mouse connected to the computer. Some games allow you to control the
; cursor with a joystick.

global PgfxCursor.col
global PgfxCursor.row
global PgfxCursor.colOffset
global PgfxCursor.rowOffset

align 4, db 0
csym PgfxCursor
istruc PgtCursor
atl .col,			dd 16384		; (start off screen)
atl .row,			dd 16384		; current hotspot pixel position
atl .colOffset,		dd 15
atl .rowOffset,		dd 0			; amount cursor image is offset from actual
atl .colPrev,		dd 16384
atl .rowPrev,		dd 16384		; previous position of cursor + hotspot
atl .layer,			dd EmptyLayer	; pointer to last used cursor
atl .background,	dd .bgPixels	; pointer to image behind cursor
section .bss
.sizeDef			equ 32
.sizeSlDef			equ 5
.bbpDef				equ 4
.bppSlDef			equ 5			; bits per pixel shift left
.byteSize			equ .sizeDef*.sizeDef*.bbpDef
.bgPixels:	resb .byteSize			;section of screen behind cursor
section .data
iend
%endif

EmptyLayer:
istruc PgtLayer
atl .image,			dd 0
atl .flags,			dd PgtLayer.BopNop
iend

; an image struct so the display can be treated just like any other image
csym PgfxDisplayImage
DefPgtImage Display_pixelsDef, PgtImage.typeImage, Display_bpplsDef, Display_wrapDef, 0,0, Display_widthDef,Display_heightDef

;//////////////////////////////////////////////////////////////////////////////
;csym SomeFunc
; ...

section .text


;PgfxDisplayInit:
;	ret

%ifdef PlainUseCursor
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
csym PgfxCursorShow
	push ebx

	mov ecx,[PgfxCursor.col]
	mov edx,[PgfxCursor.row]
	sub ecx,[PgfxCursor.colOffset]	; effective row = hotspot row - row offset
	sub edx,[PgfxCursor.rowOffset]
	mov [PgfxCursor.colPrev],ecx
	mov [PgfxCursor.rowPrev],edx

	; save display behind cursor
	; (ecx=new col, edx=new row)
	and dword [PgfxFlags],~PgfxFlags.cursorHidden
	call PgfxCursorSwapBg			; pass ecx,edx

	; draw cursor image (potentially multiple layers)
	mov ecx,[PgfxCursor.colPrev]
	mov edx,[PgfxCursor.rowPrev]
	lea eax,[ecx+PgfxCursor.sizeDef] ; right = left+width
	lea ebx,[edx+PgfxCursor.sizeDef]

	callc DrawLayers, \
		[PgfxCursor.layer], \
		PgfxCursor.sizeDef, PgfxCursor.sizeDef, \
		ecx,edx,  eax,ebx, \
		NULL, 0

	pop ebx
	ret
%endif


%ifdef PlainUseCursor
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
csym PgfxCursorHide
	push ebx

	; if effective cursor position changed	
	;   set moved flag
	; endif
	mov eax,[PgfxCursor.col]
	mov ebx,[PgfxCursor.row]
	mov ecx,[PgfxCursor.colPrev]
	mov edx,[PgfxCursor.rowPrev]
	sub eax,[PgfxCursor.colOffset]	; effective row = hotspot row - row offset
	sub ebx,[PgfxCursor.rowOffset]
	cmp eax,ecx
	jne .Move
	cmp ebx,edx
	je .NoMove
.Move:
	or dword [PgfxFlags],PgfxFlags.cursorMove
.NoMove:

	; restore display behind cursor
	; (ecx=colPrev, edx=rowPrev)
	or dword [PgfxFlags],PgfxFlags.cursorHidden
	call PgfxCursorSwapBg			; pass ecx,edx

	pop ebx
	ret
%endif


%ifdef PlainUseCursor
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Set the cursor image (can be multiple layers)
params esp+4
param layerPtr						; ptr to layers
scsym PgfxCursorSet

	mov edx,[.layerPtr]
	cmp edx,[PgfxCursor.layer]
	je .Same
	mov eax,[edx+PgtLayer.image]
	mov [PgfxCursor.layer],edx
	movsx ecx, word [eax+PgtImage.left]
	movsx edx, word [eax+PgtImage.top]
	mov [PgfxCursor.colOffset],ecx
	mov [PgfxCursor.rowOffset],edx
	or dword [PgfxFlags],PgfxFlags.cursorSet
.Same:

	ret params_size

	unlocals
%endif


%ifdef PlainUseCursor
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Swaps the background behind the cursor, either saving to the display if
; showing or restoring to the display if hiding.
; Given a row and column, figures clipped row, column, height, width, and
; display destination. If the cursor is off screen completely, this routine
; will return without any drawing.
;
; (ecx=col, edx=row)
; ()
PgfxCursorSwapBg:
	push ebx,esi,edi,ebp
	locals esp+locals_size
	local rect,PgtRect_size, sub esp,PgtRect_size

    mov ebx,PgfxCursor.sizeDef		; set height
    mov edi,[PgfxDisplay.height]
    ;xor esi,esi						; zero initial source offset
    mov eax,ebx						; copy size for width

    ; clip vertically
    sub edi,ebx						; display height - cursor size
    test edx,edx
    jge .TopOk
    add ebx,edx						; cursor height += negative cursor row
    jle near .Offscreen
    ;sub esi,edx						; source offset += -(row)
    xor edx,edx						; clip row top (0)
    ;shl esi,PgfxCursor.sizeSlDef
    ;jmp short .BtmOk
.TopOk:
    sub edi,edx
    jge .BtmOk
    add ebx,edi						; cursor height += negative cursor row right side
    jle near .Offscreen
.BtmOk:
	; (ebx=clipped height, esi=source offset)

    ; clip horizontally
    mov edi,[PgfxDisplay.width]
    sub edi,eax						; display width - cursor size
    test ecx,ecx
    jge .LeftOk
    add eax,ecx						; cursor width += negative cursor col
    jle near .Offscreen
    ;sub esi,ecx						; source offset += negative cursor col
    xor ecx,ecx						; clip row top (0)
    ;jmp short .RightOk
.LeftOk:
    sub edi,ecx
    jge .RightOk
    add eax,edi						; cursor width += negative cursor col right side
    jle near .Offscreen
.RightOk:
	; (ebx=clipped height, esi=source offset)

    ; dest ptr = (row * display width) + col
    mov edi,edx
    imul edi,[PgfxDisplay.wrap]
    ;add edi,ecx
	lea edi,[edi+ecx*4]
    ;shl esi,PgfxCursor.bppSlDef-3
    add esi,PgfxCursor.bgPixels
    add edi,[PgfxDisplay.pixels]

    mov esi,PgfxCursor.bgPixels
    ;mov edi,[PgfxDisplay.pixels]

.Transfer:
	; Transfers the area behind the cursor either from or to the display,
	; depending on whether it is being shown or hidden.

    ; set invalidated rectangle
	; (eax=clipped width, ebx=clipped height,
	;  ecx=clipped col, edx=clipped row,
	;  esi=source ptr, edi=display ptr)
	test dword [PgfxFlags],PgfxFlags.cursorSet|PgfxFlags.cursorMove
	jz .NoMove
    mov [.rect+PgtRect.left],ecx
    mov [.rect+PgtRect.top],edx
    add ecx,eax						; right = left+width
    add edx,ebx						; bottom = top+height
    mov [.rect+PgtRect.right],ecx
    mov [.rect+PgtRect.bottom],edx
.NoMove:

    ; calculate transfer ptrs and wraps
	; (eax=clipped width, ebx=clipped height,
	;  esi=source ptr, edi=display ptr)
    shl eax,PgfxCursor.bppSlDef-3
    mov edx,[PgfxDisplay.wrap]
    mov ebp,PgfxCursor.sizeDef<<(PgfxCursor.bppSlDef-3)
    sub edx,eax
    sub ebp,eax
    shr eax,PgfxCursor.bppSlDef-3
    ; (ebp=cursor wrap, edx=display wrap, ...)

    ; swap them if hiding cursor (else showing)
    test dword [PgfxFlags],PgfxFlags.cursorHidden
    jnz .Hidden
    xchg esi,edi					; swap source and dest ptrs
    xchg ebp,edx					; swap source and dest wraps
.Hidden:

    ; transfer pixels, either from display to bg, or vice-versa
.NextRow:
    mov ecx,eax						; set width
    ;shr ecx,PgfxCursor.bppSlDef-3
    rep movsd						; first transfer dwords
	;rep stosd						; first transfer dwords
    ;mov ecx,eax
    ;and ecx,1
    ;rep movsw						; then any remaining bytes
    add esi,ebp						; source ptr += source wrap
    add edi,edx						; dest ptr += dest wrap
    dec ebx
    jg .NextRow

    ; invalidate region around cursor if necessary
    test dword [PgfxFlags],PgfxFlags.cursorSet|PgfxFlags.cursorMove
    jz .NoChange
  %ifdef PlainUseDisplayBuffer
    mov esi,Display.Redraws
    call AddClipsToRedrawRange.Given
  %endif
  %ifdef _WINDOWS
	lea eax,[.rect]
    api InvalidateRect, [PgfxDisplay.hwnd],eax,FALSE
  %endif
.NoChange:

.Offscreen:

    xor eax,eax
	add esp,locals_size
	pop ebx,esi,edi,ebp
    ret

	unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; Draws single image to display.
; This routine draws clipped, relative to the display viewport.

; ** Thinking of extending the funtionality of this function greatly **
; ** to include many features of layers, like tiling

; These three routines map to the same call.
;csym BlitImagePal
;	test dword [esp+4],
;csym BlitImageTile
;	or dword [esp+4],.tiled|
;csym BlitImageScale
;	or dword [esp+4],.scaled|
;csym BlitImageNormal

csym BlitImage

params ebp+16+4
param pop			; pixel operation
param destLeft
param destTop
param destWidth
param destHeight
param srcColor,0
param srcPtr		; PgtImage*
param srcLeft
param srcTop
param srcColor2,0

param palPtr,0		; PgtPalEntry* [16-1024]

param scaleLeft
param scaleTop
param scaleWidth
param scaleHeight

	push ebx
	push esi
	push edi
	push ebp
	mov ebp,esp

locals ebp
local srcWidth,4
local srcHeight,4
local srcWrap,4
local srcPixels,4

	sub esp,byte locals_size

	mov eax,[.pop]
	mov esi,[.srcPtr]
	mov ebx,[esi+PgtImage.pixels]
	movzx edi,word [esi+PgtImage.wrap]
	movzx ecx,word [esi+PgtImage.width]
	movzx edx,word [esi+PgtImage.height]
	mov [.srcPixels],ebx
	mov [.srcWrap],edi
	mov [.srcWidth],ecx
	mov [.srcHeight],edx

;///////////////////
; (eax=flags, esi=layer ptr)
	; clip horizontally
	;test eax,PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz
	;jnz .Ciht

;///////////////////
; horizontal normal
; (eax=flags, esi=image ptr)
.Cihn:
	; for horizontally normal images

	; clip to image width
	; otherwise garbage will be drawn
	mov edi,[.srcLeft]
	mov ecx,[.srcWidth]
	mov edx,[.destWidth]
	test edi,edi
	js .CihnOfsNeg
	sub ecx,edi							; if src offset positive, src width -= src left
	jmp short .CihnOfsSet
.CihnOfsNeg:
	sub [.destLeft],edi					; if negative, dest left += -src left
	add edx,edi							; dest width -= -src left
.CihnOfsSet:
	cmp edx,ecx
	jl .CihnWidthOk
	mov edx,ecx
.CihnWidthOk:
	; (edx=image clipped width)

	; calc left and right edges of image on display
	mov ecx,[.destLeft]
	add ecx,[PgfxDisplay.left]
	add edx,ecx							; right = left + width
	; (ecx=left edge, edx=right edge)

	; clip to display clips
	mov edi,ecx
	sub edi,[PgfxDisplay.clipLeft]		; left clipped by display?
	jge .CihnLeftOk2
	sub [.srcLeft],edi					; adjust source offset
	mov ecx,[PgfxDisplay.clipLeft]
.CihnLeftOk2:
	mov [.destLeft],ecx
	cmp edx,[PgfxDisplay.clipRight]		; right clipped by display?
	jle .CihnRightOk2
	mov edx,[PgfxDisplay.clipRight]
.CihnRightOk2:
	sub edx,ecx							; width = right - left
	jle .Abort							; width negative or zero! 
	; (edx=display clipped width)
	mov [.destWidth],edx
	;jmp .CiHorzSet

;///////////////////
; (esi=layer ptr)
	; clip vertically
	;test eax,PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	;jnz .Civt

;///////////////////
; vertical normal
; (eax=flags, esi=image ptr)
.Civn:
	; for vertically normal images

	; clip to image height
	mov edi,[.srcTop]
	mov ecx,[.srcHeight]
	mov edx,[.destHeight]
	test edi,edi
	js .CivnOfsNeg
	sub ecx,edi							; if src offset positive, src height -= src top
	jmp short .CivnOfsSet
.CivnOfsNeg:
	sub [.destTop],edi					; if negative, dest top += -src top
	add edx,edi							; dest height -= -src top
.CivnOfsSet:
	cmp edx,ecx
	jl .CihnHeightOk
	mov edx,ecx
.CihnHeightOk:
	; (edx=image clipped height)

	; calc top and bottom edges of image on display
	mov ecx,[.destTop]
	add ecx,[PgfxDisplay.top]
	add edx,ecx							; bottom = top + height
	; (ecx=top edge, edx=bottom edge)

	; clip to display clips
	mov edi,ecx
	sub edi,[PgfxDisplay.clipTop]		; top clipped by display?
	jge .CivnTopOk2
	sub [.srcTop],edi					; adjust source offset
	mov ecx,[PgfxDisplay.clipTop]
.CivnTopOk2:
	mov [.destTop],ecx
	cmp edx,[PgfxDisplay.clipBottom]	; bottom clipped by display?
	jle .CivnBottomOk2
	mov edx,[PgfxDisplay.clipBottom]
.CivnBottomOk2:
	sub edx,ecx							; height = bottom - top
	jle .Abort							; height negative or zero! 
	; (edx=display clipped height)
	mov [.destHeight],edx
	;jmp .CiVertSet

;///////////////////
; blit image
; (eax=flags, esi=layer ptr)

	movzx edx,byte [.pop]
	cmp edx,PgtLayer.BopLast
	ja .Abort
	push dword .End
	jmp dword [.Jtbl+edx*4]

.End:
	xor eax,eax
	mov esp,ebp
	pop ebp
	pop edi
	pop esi
	pop ebx
	ret

.Abort:
	mov eax,-1
	jmp short .End

align 4
%if PgtLayer.BopVer != 20050414
	%error "Blend operations have changed. Remember to update this code!"
%endif
.Jtbl:
	dd .BopNop
	dd .BopHitTest
	dd .BopIf
	dd .BopClip
	dd .BopClipReset
	dd .BopOpaque
	dd .BopTrans
	dd .BopTransFast
	dd .BopAdd
	dd .BopSub
	dd .BopMul
	dd .BopMulByAlpha
	dd .BopAnd
	dd .BopOr
	dd .BopAndOr
	dd .BopGreater
	dd .BopLesser
	dd .BopMask
	dd .BopMaskInc
	dd .BopSetDest
	dd .BopTransMask

.BopNop:
.BopHitTest:
.BopIf:
.BopClip:
.BopClipReset:
	ret

.BopOpaque:
	test eax,PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopOpaqueScale
.BopOpaqueNormal:
	callc BlitOpaque32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	;hmm - callc BlitOpaque .destImage, .destLeft, .destTop, .destClips .srcImage
	ret
.BopOpaqueScale:
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopOpaqueFill
	callc BlitScale32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],    [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap], \
		0,           0,             [.srcWidth], [.srcHeight], \
		[.scaleLeft],[.scaleTop], [.scaleWidth], [.scaleHeight]
	
	ret
.BopOpaqueFill:
	;mov edi,[.srcPixels]
	callc BlitOpaque32i32c, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop], [.destWidth], [.destHeight], \
		[.srcColor]
	ret

.BopTrans:
	test eax,PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopTransScale
.BopTransNormal:
	callc BlitTrans32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	;hmm - callc BlitOpaque .destImage, .destLeft, .destTop, .destClips .srcImage
	ret
.BopTransScale:
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopTransFill
	;callc BlitScale32i32i, \
	;	[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
	;	[.destLeft], [.destTop],    [.destWidth], [.destHeight], \
	;	[.srcPixels],[.srcWrap], \
	;	0,           0,             [.srcWidth], [.srcHeight], \
	;	[.layerLeft],[.layerRight], [.layerWidth], [.layerHeight]
	ret
.BopTransFill:
	;mov edi,[.srcPixels]
	callc BlitTrans32i32c, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop], [.destWidth], [.destHeight], \
		[.srcColor]
	ret

.BopTransFast:
	;test eax,PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	;jnz .BopTransFastScale
.BopTransFastNormal:
	callc BlitTransFast32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret

.BopTransMask:
	callc BlitTrans32i8i32c, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop], \
		[.srcColor2]
	ret

.BopAdd:
	cmp dword [ebx+PgtImage.size],00010001h
	jne .BopAddNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopAddFill
.BopAddNormal:
	callc BlitAdd32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopAddFill:
	;mov edi,[.srcPixels]
	callc BlitAdd32i32c, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop], [.destWidth], [.destHeight], \
		[.srcColor]
	ret

.BopSub:
	cmp dword [ebx+PgtImage.size],00010001h
	jne .BopSubNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopSubFill
.BopSubNormal:
	callc BlitSub32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopSubFill:
	;mov edi,[.srcPixels]
	;callc BlitSub32i32c, \
	;	[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret

.BopMul:
	cmp dword [ebx+PgtImage.size],00010001h
	jne .BopMulNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopMulFill
.BopMulNormal:
	callc BlitMul32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopMulFill:
	;mov edi,[.srcPixels]
	;callc BlitMul32i32c, \
	;	[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret

.BopMulByAlpha:
	ret
	
.BopAnd:
	cmp dword [ebx+PgtImage.size],00010001h
	jne .BopAndNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopAndFill
.BopAndNormal:
	callc BlitAnd32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopAndFill:
	;mov edi,[.srcPixels]
	;callc BlitAnd32i32c, \
	;	[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret
	
.BopOr:
	cmp dword [ebx+PgtImage.size],00010001h
	jne .BopOrNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopOrFill
.BopOrNormal:
	callc BlitOr32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopOrFill:
	;mov edi,[.srcPixels]
	;callc BlitOr32i32c, \
	;	[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret

.BopAndOr:
	ret
	
.BopGreater:
	cmp dword [ebx+PgtImage.size],00010001h
	jne .BopGreaterNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopGreaterFill
.BopGreaterNormal:
	callc BlitGreater32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopGreaterFill:
	;mov edi,[.srcPixels]
	;callc BlitGreater32i32c, \
	;	[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret

.BopLesser:
	cmp dword [ebx+PgtImage.size],00010001h
	jne .BopLesserNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopLesserFill
.BopLesserNormal:
	callc BlitLesser32i32i, \
		[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopLesserFill:
	;mov edi,[.srcPixels]
	;callc BlitLesser32i32c, \
	;	[PgfxDisplay.pixels], [PgfxDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret

.BopMask:
.BopMaskInc:
.BopSetDest:
	ret

	unlocals
