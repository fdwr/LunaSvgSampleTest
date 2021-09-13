; PGFXLAYR.ASM - Plain Graphics Layering Functions (v3.0)
; These functions are called by user control element code.
;  
;______________________________________________________________________________
; Layer operations: (spec in limbo)
;
; Nop - does nothing
; Opaque - image or solid color (can do palette if one defined)
; Trans - translucent (can do palette if one defined)
; TransFast
; Add
; AddUseAlpha - adds after calling MulByAlpha
; Sub
; SubUseAlpha - subtracts after calling MulByAlpha
; Mul
; MulUseAlpha - multiplies after calling MulByAlpha
; MulByAlpha
; And
; Or
; AndOr
; Greater
; Lesser
; Secondary - define secondary image used for complex ops
; HitTest - defines hit test mask for cursor
; Palette - defines palette for following op(s)
; Clip/Align? - additional clips for following op
; ClipReset - restores whatever clip may have limited
; If - conditional block for all following ops to next if
; Mask - define mask for following operation. anything outside mask ignored.
; Inclusive mask - define mask, anything outside mask blitted
;	mask can also be a constant, to define a transparency level
;
; Scrapped:
;
; Mono - converts color to single chroma
;	since it requires a look up table anyway (to avoid divisions), better to
;	use the existing palette functions.
;
;______________________________________________________________________________

%define pgfxlayr_asm
%include "pgfx.h"
%include "pgfxlayr.h"

	;%include "mywininc.asm"

;//////////////////////////////////////////////////////////////////////////////
; Draws multiple image layers to display.
; This routine draws clipped, relative to the display viewport.
; ** thinking of moving most functionality from here to BlitImage **
csym DrawLayers
; uce flags
; region
; additional images
; global images

params ebp+16+4	;16 bytes for saving 4 regs
param layerPtr		; pointer to layer array
param areaWidth		; pixel width of control
param areaHeight
param sectLeft		; pixel offset from left
param sectTop		; pixel offset from top
param sectRight		; pixel offset to right, from left
param sectBottom	; pixel offset to bottom, from to
param stateGeneric	; bit flags for state testing (common)
param stateSpecific	; additional bit flags for state testing (arbitrary) as convenience
param imagesPtr		; pointer to additional image array
param imagesNum		; number of images passed

	push ebx
	push esi
	push edi
	push ebp
	mov ebp,esp

locals ebp
;local clipLeft,4, clipTop,4, clipRight,4, clipBottom,4
;local maxLeft, 4, maxTop, 4, maxRight, 4, maxBottom ,4
local layerBottom,4 ; relative to dest offset
local layerRight,4
local layerTop,4
local layerLeft,4
local layerHeight,4
local layerWidth,4
local destTop,4 ; relative to absolute pixels
local destLeft,4
local destHeight,4
local destWidth,4
local srcTop,4
local srcLeft,4
local srcHeight,4
local srcWidth,4
local srcWrap,4
local srcPixels,4
local palettePtr,4
local srcImagePtr,4
local maskImagePtr,4
local destDisplay, PgtDisplay_size	; need a temporary dest occasionally
;local tempImage ,PgtImage_size

	sub esp,byte locals_size
	xor eax,eax
	mov edi,esp
	mov ecx,locals_size/4
	rep stosd

	mov esi,PgfxCurrentDisplay
	lea edi,[.destDisplay]
	mov ecx,PgtDisplay_size/4
	rep movsd

%if 0 ; debugging to show values
	mov eax,[.layerPtr]
	mov eax,[.areaWidth]
	mov eax,[.areaHeight]
	mov eax,[.sectLeft]

PgfxDisplay.left
	mov eax,[.clipLeft]
	mov eax,[.clipTop]
	mov eax,[.maxLeft]
	mov eax,[.maxTop]
%endif

	mov esi,[.layerPtr]
	test esi,esi
	jz .End
	jmp short .Start

.Next:	; loop top
	; behaviour depends on opcode
	; figure top/left based on alignment
	; if 8 bit blitting to 32 bit destination
	;   if palette given
	;   convert to 32 bit temp image
	; endif
	; if scaling or tiling, but not opaque (like add, sub, mask...)
	;   create temp image
	;   then do operation
	; endif
	; if usealpha flag
	;   apply MulByAlpha to temp image
	; endif
	add esi,byte PgtLayer_size
.Start: ; loop entry
	movzx eax,byte [esi+PgtLayer.blendOp]
	cmp eax,PgtLayer.BopLast
	ja .Skip
	push dword .Skip
	jmp dword [.Jtbl+eax*4]
.Abort:
	lea esp,[ebp-locals_size]			; fix stack from emergengy return
	;api MessageBeep, 0;MB_OK
.Skip:
	test dword [esi+PgtLayer.flags],PgtLayer.FlagMore
	jnz .Next

.End:
	mov esp,ebp
	pop ebp
	pop edi
	pop esi
	pop ebx
	ret


align 4
%if PgtLayer.BopVer != 20051115
	%error "Blend operations have changed. Remember to update this code!"
%endif
.Jtbl:
	dd .BopNop
	dd .BopHitTest
	dd .BopStateGeneric
	dd .BopStateSpecific
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

;///////////////////////////////////////
; (esi=layer ptr)
;
; This WHOLE section below is VERY messy because
; I haven't yet determined exactly how I want to
; implement it - in a way that is consistent and
; sensible.
.BopNop:
.BopHitTest:
.BopClip:
.BopClipReset:
	ret

.BopStateGeneric:
; (esi=layer ptr)
; (esi=adjusted layer ptr) !changes the layer ptr
	; if the right flags are set that should be set
	; and all the flags are clear that should be clear
	mov edi,[.stateGeneric]
	mov eax,[esi+PgtLayer.ifClear]
	test eax,edi
	jnz .BopSGSkip
	mov eax,[esi+PgtLayer.ifSet]
	xor edi,eax
	test edi,eax
	jnz .BopSGSkip
	ret

; skip until next state test bop reached, or end of list
.BopSGNext:
	cmp byte [esi+PgtLayer.blendOp+PgtLayer_size], PgtLayer.BopStateGeneric
	je .BopSGRet
	add esi,byte PgtLayer_size
.BopSGSkip:
; (esi=layer ptr)
; (esi=adjusted layer ptr) !changes the layer ptr
	test dword [esi+PgtLayer.flags],PgtLayer.FlagMore
	jnz .BopSGNext ; end of list, abort
.BopSGRet:
	ret

.BopStateSpecific:
; (esi=layer ptr)
; (esi=adjusted layer ptr) !changes the layer ptr
	; if the right flags are set that should be set
	; and all the flags are clear that should be clear
	mov edi,[.stateSpecific]
	mov eax,[esi+PgtLayer.ifClear]
	test eax,edi
	jnz .BopSSSkip
	mov eax,[esi+PgtLayer.ifSet]
	xor edi,eax
	test edi,eax
	jnz .BopSSSkip
	ret

; skip until next state test bop reached, or end of list
.BopSSNext:
	cmp byte [esi+PgtLayer.blendOp+PgtLayer_size], PgtLayer.BopStateSpecific
	je .BopSSRet
	add esi,byte PgtLayer_size
.BopSSSkip:
; (esi=layer ptr)
; (esi=adjusted layer ptr) !changes the layer ptr
	test dword [esi+PgtLayer.flags],PgtLayer.FlagMore
	jnz .BopSSNext	; end of list, abort
.BopSSRet:
	ret

.BopOpaque:
	call .CalcLayerEdges
	call .SetSourceAtrs
	call .ClipImage1
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopOpaqueScale
.BopOpaqueNormal:
	callc BlitOpaque32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	;hmm - callc BlitOpaque .destImage, .destLeft, .destTop, .destClips .srcImage
	ret
.BopOpaqueScale:
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopOpaqueFill
	callc BlitScale32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],    [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap], \
		0,           0,             [.srcWidth], [.srcHeight], \
		[.layerLeft],[.layerRight], [.layerWidth], [.layerHeight]
	
	ret
.BopOpaqueFill:
	mov edi,[.srcPixels]
	callc BlitOpaque32i32c, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop], [.destWidth], [.destHeight], \
		[edi]
	ret

.BopTrans:
	call .CalcLayerEdges
	call .SetSourceAtrs
	call .ClipImage1
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopTransScale
.BopTransNormal:
	callc BlitTrans32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	;hmm - callc BlitOpaque .destImage, .destLeft, .destTop, .destClips .srcImage
	ret
.BopTransScale:
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopTransFill
	;callc BlitScale32i32i, \
	;	[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
	;	[.destLeft], [.destTop],    [.destWidth], [.destHeight], \
	;	[.srcPixels],[.srcWrap], \
	;	0,           0,             [.srcWidth], [.srcHeight], \
	;	[.layerLeft],[.layerRight], [.layerWidth], [.layerHeight]
	ret
.BopTransFill:
	mov edi,[.srcPixels]
	callc BlitTrans32i32c, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop], [.destWidth], [.destHeight], \
		[edi]
	ret

.BopTransFast:
	call .CalcLayerEdges
	call .SetSourceAtrs
	call .ClipImage1
	;test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	;jnz .BopTransFastScale
.BopTransFastNormal:
	callc BlitTransFast32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret

.BopTransMask:
	callc BlitTrans32i8i32c, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop], \
		80FFFFFFh ; TEMP:
	ret

.BopAdd:
	call .CalcLayerEdges
	call .SetSourceAtrs
	call .ClipImage1
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopAddNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopAddFill
.BopAddNormal:
	callc BlitAdd32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopAddFill:
	mov edi,[.srcPixels]
	callc BlitAdd32i32c, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop], [.destWidth], [.destHeight], \
		[edi]
	ret

.BopSub:
	call .CalcLayerEdges
	call .SetSourceAtrs
	call .ClipImage1
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopSubNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopSubFill
.BopSubNormal:
	callc BlitSub32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopSubFill:
	mov edi,[.srcPixels]
	;callc BlitSub32i32c, \
	;	[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret

.BopMul:
	call .CalcLayerEdges
	call .SetSourceAtrs
	call .ClipImage1
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopMulNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopMulFill
.BopMulNormal:
	callc BlitMul32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopMulFill:
	mov edi,[.srcPixels]
	;callc BlitMul32i32c, \
	;	[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret

.BopMulByAlpha:
	ret
	
.BopAnd:
	call .CalcLayerEdges
	call .SetSourceAtrs
	call .ClipImage1
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopAndNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopAndFill
.BopAndNormal:
	callc BlitAnd32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopAndFill:
	mov edi,[.srcPixels]
	;callc BlitAnd32i32c, \
	;	[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret
	
.BopOr:
	call .CalcLayerEdges
	call .SetSourceAtrs
	call .ClipImage1
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopOrNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopOrFill
.BopOrNormal:
	callc BlitOr32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopOrFill:
	mov edi,[.srcPixels]
	;callc BlitOr32i32c, \
	;	[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret

.BopAndOr:
	ret
	
.BopGreater:
	call .CalcLayerEdges
	call .SetSourceAtrs
	call .ClipImage1
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopGreaterNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopGreaterFill
.BopGreaterNormal:
	callc BlitGreater32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopGreaterFill:
	mov edi,[.srcPixels]
	;callc BlitGreater32i32c, \
	;	[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret

.BopLesser:
	call .CalcLayerEdges
	call .SetSourceAtrs
	call .ClipImage1
	cmp dword [ebx+PgtImage.size],00010001h
	je .BopLesserNormal
	test dword [esi+PgtLayer.flags],PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz|PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .BopLesserFill
.BopLesserNormal:
	callc BlitLesser32i32i, \
		[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
		[.destLeft], [.destTop],  [.destWidth], [.destHeight], \
		[.srcPixels],[.srcWrap],  [.srcLeft],[.srcTop]
	ret
.BopLesserFill:
	mov edi,[.srcPixels]
	;callc BlitLesser32i32c, \
	;	[.destDisplay+PgtDisplay.pixels], [.destDisplay+PgtDisplay.wrap], \
	;	[.destLeft], [.destTop], [.destWidth], [.destHeight], \
	;	[edi]
	ret

.BopMask:
.BopMaskInc:
.BopSetDest:
	ret

;///////////////////////////////////////
; Determines the four edges of a layer: left, top, right, bottom
; Sets .layerXXX variables.
; (esi=layer ptr)
.CalcLayerEdges:
	push ebx
	push edi

	; ensure flags have not changed so that code below will work as expected
	%if (PgtLayer.FlagLeftOffset != 0) || (PgtLayer.FlagLeftOpposite > PgtLayer.FlagLeftSize) || (PgtLayer.FlagLeftSize > PgtLayer.FlagLeftPercent)
	  %error "DrawLayers.CalcLayerEdges: Flag values have changed. Update code here."
	%endif

	mov eax,[esi+PgtLayer.flags]

	; horizontal check, whether absolute layer or relative to section
	test eax,PgtLayer.FlagAbsoluteHorz
	jnz .ClehAbs
	mov ecx,[.sectLeft]
	mov edx,[.sectRight]
	jmp short .ClehSet
.ClehAbs:
	xor ecx,ecx
	mov edx,[.areaWidth]
.ClehSet:

	; left edge
	; (eax=flags, ecx=section left, edx=section right, esi=layer ptr)
	movsx ebx,word [esi+PgtLayer.left]
.ClelCheckOffset:
	test eax,~PgtLayer.FlagLeftOffset & PgtLayer.FlagLeftMask
	jnz .ClelCheckOffsetRight
	add ebx,ecx
	jmp short .ClelCalced
.ClelCheckOffsetRight:
	test eax,~PgtLayer.FlagLeftOpposite & PgtLayer.FlagLeftMask
	jnz .ClelCheckSize
	add ebx,edx
	jmp short .ClelCalced
.ClelCheckSize:
	test eax,~PgtLayer.FlagLeftSize & PgtLayer.FlagLeftMask
	jz .ClelCalced ; not actually calced, but can't do it right now
	; fall through since only other option is percentage
;.ClelCheckPercent:
	mov edi,edx
	sub edi,ecx
	imul ebx,edi
	sar ebx,10
	add ebx,ecx
	;jmp short .ClelCalced
.ClelCalced:
	mov [.layerLeft],ebx

	; right edge
	; (eax=flags, ecx=section left, edx=section right, esi=layer ptr)
	movsx ebx,word [esi+PgtLayer.right]
.DerCheckOffset:
	test eax,~PgtLayer.FlagRightOffset & PgtLayer.FlagRightMask
	jnz .DerCheckOffsetLeft
	add ebx,edx
	jmp short .DerCalced
.DerCheckOffsetLeft:
	test eax,~PgtLayer.FlagRightOpposite & PgtLayer.FlagRightMask
	jnz .DerCheckSize
	add ebx,ecx
	jmp short .DerCalced
.DerCheckSize:
	test eax,~PgtLayer.FlagRightSize & PgtLayer.FlagRightMask
	jnz .DerCheckPercent
	add ebx,[.layerLeft]
	jmp short .DerCalced
.DerCheckPercent:
	mov edi,edx
	sub edi,ecx
	imul ebx,edi
	sar ebx,10
	add ebx,edx
	;jmp short .DerCalced
.DerCalced:
	mov [.layerRight],ebx

	; recheck whether left was size, since was dependant on right side
	; (eax=flags, ebx=layer right, ecx=section left, edx=section right, esi=layer ptr)
	xor eax,PgtLayer.FlagLeftSize
	test eax,PgtLayer.FlagLeftMask
	jnz .ClelNotSize
	sub ebx,[.layerLeft]
	mov [.layerLeft],ebx
.ClelNotSize:

	; vertical check, whether absolute layer or relative to section
	test eax,PgtLayer.FlagAbsoluteVert
	jnz .ClevAbs
	mov ecx,[.sectTop]
	mov edx,[.sectBottom]
	jmp short .ClevSet
.ClevAbs:
	xor ecx,ecx
	mov edx,[.areaHeight]
.ClevSet:

	; top edge
	; (eax=flags, ecx=section top, edx=section bottom, esi=layer ptr)
	movsx ebx,word [esi+PgtLayer.top]
.CletCheckOffset:
	test eax,~PgtLayer.FlagTopOffset & PgtLayer.FlagTopMask
	jnz .CletCheckOffsetBottom
	add ebx,ecx
	jmp short .CletCalced
.CletCheckOffsetBottom:
	test eax,~PgtLayer.FlagTopOpposite & PgtLayer.FlagTopMask
	jnz .CletCheckSize
	add ebx,edx
	jmp short .CletCalced
.CletCheckSize:
	test eax,~PgtLayer.FlagTopSize & PgtLayer.FlagTopMask
	jz .CletCalced ; not actually calced, but can't do it right now
	; fall through since only other option is percentage
;.CletCheckPercent:
	mov edi,edx
	sub edi,ecx
	imul ebx,edi
	sar ebx,10
	add ebx,ecx
	;jmp short .CletCalced
.CletCalced:
	mov [.layerTop],ebx

	; bottom edge
	; (eax=flags, ecx=section top, edx=section bottom, esi=layer ptr)
	movsx ebx,word [esi+PgtLayer.bottom]
.ClebCheckOffset:
	test eax,~PgtLayer.FlagBottomOffset & PgtLayer.FlagBottomMask
	jnz .ClebCheckOffsetTop
	add ebx,edx
	jmp short .ClebCalced
.ClebCheckOffsetTop:
	test eax,~PgtLayer.FlagBottomOpposite & PgtLayer.FlagBottomMask
	jnz .ClebCheckSize
	add ebx,ecx
	jmp short .ClebCalced
.ClebCheckSize:
	test eax,~PgtLayer.FlagBottomSize & PgtLayer.FlagBottomMask
	jnz .ClebCheckPercent
	add ebx,[.layerTop]
	jmp short .ClebCalced
.ClebCheckPercent:
	mov edi,edx
	sub edi,ecx
	imul ebx,edi
	sar ebx,10
	add ebx,edx
	;jmp short .ClebCalced
.ClebCalced:
	mov [.layerBottom],ebx

	; recheck whether top was size, since was dependant on bottom side
	; (eax=flags, ebx=layer bottom, ecx=section top, edx=section bottom, esi=layer ptr)
	xor eax,PgtLayer.FlagTopSize
	test eax,PgtLayer.FlagTopMask
	jnz .CletNotSize
	sub ebx,[.layerTop]
	mov [.layerTop],ebx
.CletNotSize:

	pop edi
	pop ebx
	ret

;///////////////////////////////////////
; Gets attributes of the source image and sets its alignment in the layer.
; * Does no clipping.
; * Must be called after CalcLayerEdges
; (esi=layer ptr)
; (ebx=source image ptr, .srcImagePtr, .srcPixels, .srcWrap, .srcWidth, .srcHeight)
.SetSourceAtrs:
	;push ebx

	mov eax,[esi+PgtLayer.flags]
	mov ebx,[esi+PgtLayer.image]

	; check if source image is really a ptr
	test eax,PgtLayer.FlagImageIndex|PgtLayer.FlagDestIndex
	jz .AiNotIndex
	jmp .Abort ;! NOT handled yet
	
	;test eax,PgtLayer.FlagDestIndex
	;jnz near .AiEnd ;! NOT handled yet
	;cmp ebx,[.imagesNum]				; image >= num images
	;jae near .AiEnd                     ; bad image index, avoid GPF
	;mov edx,[.imagesPtr]
	; undecided yet whether should be pointer to array of images
	; or pointer to array of pointers
	;lea ebx,[edx+ebx*4]
	;mov ebx,[ebx]      					; get address of image from pointer array
	;shl ebx,16
	;add ebx,edx							; get address of image from array
.AiNotIndex:
	mov [.srcImagePtr],ebx
	mov ecx,[ebx+PgtImage.pixels]
	movzx edx,word [ebx+PgtImage.wrap]
	mov [.srcPixels],ecx
	mov [.srcWrap],edx
	mov [.srcLeft],dword 0				; default to top/left of source unless clipped
	mov [.srcTop],dword 0

	; all edges of layer have been calculated
	; now align the image to the layer edges

	; align horizontally
	; (eax=flags, ebx=source image ptr, esi=layer ptr)
	movzx ecx,word [ebx+PgtImage.width]
	test eax,PgtLayer.FlagAlignHorzMask
	mov [.srcWidth],ecx
	jnz .AihNotLeft
	mov edx,[.layerLeft]
	jmp short .AihSet
.AihNotLeft:
	mov edx,[.layerRight]
	test eax,PgtLayer.FlagAlignRight
	jz .AihNotRight
	sub edx,ecx							; right - width
.AihNotRight:
	test eax,PgtLayer.FlagAlignHorzMid
	jz .AihSet
.AihAlignHorz:
	sub edx,[.layerLeft]				; (right - [width] - left)
	sar edx,1							; / 2
	add edx,[.layerLeft]				; (right - [width] - left)/2 + left
.AihSet:
	mov [.destLeft],edx

	; align vertically
	; (eax=flags, ebx=source image ptr, esi=layer ptr)
	movzx ecx,word [ebx+PgtImage.height]
	test eax,PgtLayer.FlagAlignVertMask
	mov [.srcHeight],ecx
	jnz .AivNotTop
	mov edx,[.layerTop]
	jmp short .AivSet
.AivNotTop:
	mov edx,[.layerBottom]
	test eax,PgtLayer.FlagAlignBottom
	jz .AivNotBottom
	sub edx,ecx							; bottom - height
.AivNotBottom:
	test eax,PgtLayer.FlagAlignVertMid
	jz .AivSet
.AivAlignVert:
	sub edx,[.layerTop]					; (bottom - [height] - top)
	sar edx,1							; / 2
	add edx,[.layerTop]					; (bottom - [height] - top)/2 + top
.AivSet:
	mov [.destTop],edx

.AiEnd:
	; return source image ptr in ebx
	;pop ebx
	ret

;///////////////////////////////////////
; Clips a normal/tiled/scaled image to the destination layer.
; * Must be called after SetSourceAtrs
; * Note that before this function is called, all coordinates are
;   relative to the current region of the destination. Upon return,
;   all coordinates are adjusted to absolute values and sizes are
;   limited to drawable area.
; (esi=layer ptr)
; (.srcLeft, .srcTop, .destWidth, .destHeight, .destLeft, .destTop
;  .layerWidth - if horizontally scaled,
;  .layerHeight - if vertically scaled)
.ClipImage1:
	push edi
	mov eax,[esi+PgtLayer.flags]
	
;///////////////////
; (esi=layer ptr)
	; clip horizontally
	test eax,PgtLayer.FlagScaleHorz|PgtLayer.FlagTileHorz
	jnz .Ciht

;///////////////////
; horizontal normal
; (eax=flags, esi=layer ptr)
.Cihn:
	; for horizontally normal images
	; clip image to layer	
	mov ecx,[.destLeft]
	mov edx,[.srcWidth]
	mov edi,ecx
	add edx,ecx							; right = left + width

	sub edi,[.layerLeft]				; image left clipped by layer?
	jge .CihnLeftOk
	sub [.srcLeft],edi					; adjust source offset
	mov ecx,[.layerLeft]
.CihnLeftOk:
	cmp edx,[.layerRight]				; image right clipped by layer?
	jle .CihnRightOk
	mov edx,[.layerRight]
.CihnRightOk:

	; now clip layer to display extents
	; (ecx=left edge, edx=right edge)
	add ecx,[.destDisplay+PgtDisplay.left]
	add edx,[.destDisplay+PgtDisplay.left]

	mov edi,ecx
	sub edi,[.destDisplay+PgtDisplay.clipLeft] ; layer left clipped by display?
	jge .CihnLeftOk2
	sub [.srcLeft],edi					; adjust source offset
	mov ecx,[.destDisplay+PgtDisplay.clipLeft]
.CihnLeftOk2:
	mov [.destLeft],ecx
	cmp edx,[.destDisplay+PgtDisplay.clipRight] ; layer right clipped by display?
	jle .CihnRightOk2
	mov edx,[.destDisplay+PgtDisplay.clipRight]
.CihnRightOk2:
	sub edx,ecx							; width = right - left
	mov [.destWidth],edx
	jle .Abort							; width negative or zero! 
	jmp .CiHorzSet

;///////////////////
; horizontal tiled
; (eax=flags, esi=layer ptr)
.Ciht:
	; for horizontally tiled or scaled images
	; clip layer to display extents
	mov edx,[.layerRight]
	mov ecx,[.layerLeft]
	mov edi,edx
	sub edi,ecx							; layer width = right - left
	add ecx,[.destDisplay+PgtDisplay.left]
	add edx,[.destDisplay+PgtDisplay.left]
	mov [.layerWidth],edi

	; (ecx=left edge, edx=right edge)
	cmp ecx,[.destDisplay+PgtDisplay.clipLeft] ; layer left clipped by display?
	jge .CihtLeftOk
	mov ecx,[.destDisplay+PgtDisplay.clipLeft]
.CihtLeftOk:
	mov [.destLeft],ecx
	cmp edx,[.destDisplay+PgtDisplay.clipRight] ; layer right clipped by display?
	jle .CihtRightOk
	mov edx,[.destDisplay+PgtDisplay.clipRight]
.CihtRightOk:
	sub edx,ecx							; width = right - left
	mov [.destWidth],edx
	jle .Abort							; width negative or zero! 
	;jmp .CiHorzSet
.CiHorzSet:

;///////////////////
; (esi=layer ptr)
	; clip vertically
	test eax,PgtLayer.FlagScaleVert|PgtLayer.FlagTileVert
	jnz .Civt

;///////////////////
; vertical normal
; (eax=flags, esi=layer ptr)
.Civn:
	; for vertically normal images
	; clip image to layer	
	mov ecx,[.destTop]
	mov edx,[.srcHeight]
	mov edi,ecx
	add edx,ecx							; bottom = top + height

	sub edi,[.layerTop]					; image top clipped by layer?
	jge .CivnTopOk
	sub [.srcTop],edi					; adjust source offset
	mov ecx,[.layerTop]
.CivnTopOk:
	cmp edx,[.layerBottom]				; image bottom clipped by layer?
	jle .CivnBottomOk
	mov edx,[.layerBottom]
.CivnBottomOk:

	; now clip layer to display extents
	; (ecx=top edge, edx=bottom edge)
	add ecx,[.destDisplay+PgtDisplay.top]
	add edx,[.destDisplay+PgtDisplay.top]

	mov edi,ecx
	sub edi,[.destDisplay+PgtDisplay.clipTop] ; layer top clipped by display?
	jge .CivnTopOk2
	sub [.srcTop],edi					; adjust source offset
	mov ecx,[.destDisplay+PgtDisplay.clipTop]
.CivnTopOk2:
	mov [.destTop],ecx
	cmp edx,[.destDisplay+PgtDisplay.clipBottom] ; layer bottom clipped by display?
	jle .CivnBottomOk2
	mov edx,[.destDisplay+PgtDisplay.clipBottom]
.CivnBottomOk2:
	sub edx,ecx							; height = bottom - top
	mov [.destHeight],edx
	jle .Abort							; height negative or zero! 
	jmp .CiVertSet

;///////////////////
; vertical tiled
; (eax=flags, esi=layer ptr)
.Civt:
	; for vertically tiled or scaled images
	; clip layer to display extents
	mov edx,[.layerBottom]
	mov ecx,[.layerTop]
	mov edi,edx
	sub edi,ecx							; layer height = right - left
	add ecx,[.destDisplay+PgtDisplay.top]
	add edx,[.destDisplay+PgtDisplay.top]
	mov [.layerHeight],edi

	; (ecx=top edge, edx=bottom edge)
	cmp ecx,[.destDisplay+PgtDisplay.clipTop] ; layer top clipped by display?
	jge .CivtTopOk
	mov ecx,[.destDisplay+PgtDisplay.clipTop]
.CivtTopOk:
	mov [.destTop],ecx
	cmp edx,[.destDisplay+PgtDisplay.clipBottom] ; layer bottom clipped by display?
	jle .CivtBottomOk
	mov edx,[.destDisplay+PgtDisplay.clipBottom]
.CivtBottomOk:
	sub edx,ecx							; height = bottom - top
	mov [.destHeight],edx
	jle .Abort							; height negative or zero! 
	;jmp .CiVertSet
.CiVertSet:

.CiEnd:
 	pop edi
	ret

;///////////////////////////////////////
; Gets attributes of the destination layer.
; * For now, can only blit to display (no temp images)
; -* Must be called after CalcLayerEdges
; (esi=layer ptr)
; (.srcImagePtr, .srcWidth, .srcHeight, .destLeft, .destTop)
.SetDestAtrs:
	; STUB
	ret
	
;///////////////////////////////////////

unlocals

;//////////////////////////////////////////////////////////////////////////////
