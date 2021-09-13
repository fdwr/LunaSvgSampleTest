; FIX the stack esp+8 in all routines!
; change ADD to add al,bl   dest+sub
; check all line labels
;
; PGFX.ASM - Plain Graphics Routines (v3.0)
;
; Currently working on:
; -Images colormapped, colorkeyed, translucent...
; -Image tiling, streching, flipping
; -Blending operations addition, multiplication, and...
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
; -MMX
;
; Supports:
; -Nothing yet
;
; Does not support:
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
;______________________________________________________________________________
;
; Functions to implement:
;
;<< Blending Functions (binary or trinary) >>
; BlitOpaque - for rectangular sections with no holes
;   8x8 32x32
; BlitOpaqueColor - fill a rectangular region with color
;   8x8 32x32
; BlitTrans - blit translucently given color and opacity channels
;   32x32 32x32x8
; BlitTransColor - blit single color given alpha channel
;   32x32x32 32x32x8
; BlitTransFast - for regions with holes but fast blit wanted
;   8x8 32x32
; BlitMap - for palette mapping of indexed images or color transforms
;	8x8 8x32 32x8 32x32
; BlitMapKey? - hybrid for convenience
;	32x8
; BlitAdd - add src to dest pixels
;	8x8 32x32
; BlitAddColor - add constant to dest pixels
;	8x8 32x32
; BlitSub - subtract src from dest pixels
;	8x8 32x32
; BlitMul - multiply src with dest pixels (0=blackness 255=original value)
;	8x8 32x8 32x32
; BlitMulColor - multiply all pixels by constant
;	8x8 32x8 32x32
; BlitAnd - boolean AND of of pixels
;	1x1 8x8 32x32
; BlitOr - boolean OR of pixels
;	1x1 8x8 32x32
; BlitGreater - choose the greater of source or destination pixel value
;	1x1 8x8 32x32
; BlitLesser - choose the lesser of source or destination pixel value
;	1x1 8x8 32x32
;
;<< Effect Functions (unary) >>
; BlitMono - convert image to monochrome
;   8x32 32x8 32x32
; BlitGlow - build diffuse glow around opacity
;	8x8 8x32
;
;<< Distortion Functions >>
; BlitTile - tile an image pattern (always opaque)
;	8x8 32x32
; BlitStrech - strech an image (always opaque)
;	8x8 32x32
; BlitSkew - skew, strech, rotate image (always opaque)
;	8x8 32x32
;
;<< Text Functions >>
; BlitFont/BlitFontRight // builds glyphs into bitmap, left to right
;
; MapPalette - builds 8bit table from one palette to another
;	8x32x32
;______________________________________________________________________________
;
; Layer operations:
;
; Opaque - image or solid color
; Map
; Alpha
; Add
; Sub
; Mul
; Nop - does nothing
; HitTest - defines hit test mask for cursor
; Palette - defines palette for following op
; Clip/Align? - additional clips
; If - conditional block
; Mono
;______________________________________________________________________________
;
; Notes on structures:
; -All images are 2D rectangular arrays, right/down order, of discrete-valued
;  pixels, in gammaless RGB color space. Each color channel is 8bits (1bit is
;  only used a mask and never as pixels).
; -Palettes and pixels are stored as BGRA (least significant blue to most sig
;  alpha) instead of Window's screwed up PALETTEENTRY.
; -Indexed images have no inherent color information. They must explicitly map
;  indexes to colors via a palette.
; -The alpha channel is always opacity (not transparency) so 255=fully opaque
;  and 0=fully transparent.
;
; Notes on capabilities:
; -Many common graphics functions (like ellipse and line drawing) are ommitted
;  because the emphasis is using prerendered images rather than a sequence of
;  shape primitives.
; -It is possible to use any Windows GDI function on the display buffer by
;  selecting the DIB section into a DC and passing that to the function.
; -Tiling/streching is always opaque and can not simultaneously be combined
;  with colormapping/addition/alpha... However, the tiling/streching can be done
;  to a temporary image, which can then be combined in any way desired.
;
; Notes on functions:
; -Blitting routines all accept very similar parameter lists. Exceptions include
;  special ops like tiling/streching and blitters that accept two source images.
; -Parameters are always destination first, source second.
; -Most functions favor destination memory alignment over source alignment for
;  two reasons: Except complete opaqueness, most operations perform only a read
;  of the source but both read/write of the destination. The destination more
;  often is slower memory (especially if the destination is directly to video
;  memory - which is not recommended).
; -Blends/Effects. Blends are binary operations that mathematically combine
;  source and destination. Effects are unary operations that apply only the
;  destination. You can think of them as binary operations that simply ignore
;  the destination in the calculation.
; -For every operation, there is a public function and a private, raw function.
;  Calling the raw function can be slightly faster if clipping information and
;  image types are already known, but it is essential that all memory pointers
;  are valid and sizes are positive. Calling it with invalid pointers will GPF.
;  Calling it with zero or negative sizes is unlikely to GPF, but can draw
;  unpredictable results.
;______________________________________________________________________________
;
; Hmm:
; How to order parameters?
; BlitFont(dest..., string, font)
; Fill(dest, map, color) or Fill(dest, color, map)
;
; information about the current destination buffer, whether it be a virtual
; buffer, temporary bitmap, or directly to the screen.
;______________________________________________________________________________

%define PlainIncludeMMX 1		; include MMX code in compile

%define ASM
%include "poptions.h"
%include "pgfx.h"

section .data

global Pgfx.Flags
Pgfx:
.Flags:		dd 0 ;.FlagsUseMMX|.FlagsSlowPc

PgDisplay:

section .text

;//////////////////////////////////////////////////////////////////////////////
; Copies source pixels directly to destination.
; dest = src
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitOpaque:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; 20040801	created
;
global BlitOpaque32i32i
BlitOpaque32i32i:
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
%define espbase esp+8
.destPtr equ 4						; base pointer
.destWrap equ 8						; bytes per row
.destLeft equ 12					; pixel offset from left of base
.destTop equ 16						; pixel offset from top of base
.destWidth equ 20					; pixels wide (preclipped)
.destHeight equ 24					; pixels high (preclipped)
.srcPtr equ 28
.srcWrap equ 32
.srcLeft equ 36
.srcTop equ 40

	mov edx,[esp+.destTop]
	mov ecx,[esp+.destLeft]
	imul edx,[esp+.destWrap]
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr],eax
	mov edx,[esp+.srcTop]
	mov ecx,[esp+.srcLeft]
	imul edx,[esp+.srcWrap]
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[esp+.destWidth]
	mov edx,eax
	shl eax,2
	sub [esp+.srcWrap],eax
	sub [esp+.destWrap],eax

	push esi
	push edi

	mov esi,[espbase+.srcPtr]
	mov edi,[espbase+.destPtr]
	;mov edx,[esp+.destWidth]
%ifdef PlainIncludeMMX
	test dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	jnz .MMX
%endif

	;cld
.RowNext: ;(edi=dest ptr, esi=src ptr, edx=col count)
	mov ecx,edx						; col count = pixel width
	rep movsd
;.ColNext:
	;mov eax,[esi]					; get source pixel
	;add esi,byte 4
	;mov [edi],eax
	;add edi,byte 4
	;dec edx
	;jg .RowNext
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop esi
	ret

%ifdef PlainIncludeMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)

.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	;mov eax,[esi]					; grab next source pixel (second ignored)
	;dec ecx
	;add esi,byte 4
	;mov [edi],eax					; write single pixel to dest
	;add edi,byte 4
	dec ecx
	movsd                           ; copy single pixel
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX

	; remaining 64bit pixels
.ColNextMMX:
	movq mm0,[esi]					; read next two source pixels
	add esi,byte 8
	movq [edi],mm0					; write both pixels to dest
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movsd                           ; copy single pixel

.RowEndMMX:
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

;//////////////////////////////////////////////////////////////////////////////
; 20040801	created
;
global BlitOpaque8i8i
BlitOpaque8i8i:
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
%define espbase esp+8
.destPtr equ 4						; base pointer
.destWrap equ 8						; bytes per row
.destLeft equ 12					; pixel offset from left of base
.destTop equ 16						; pixel offset from top of base
.destWidth equ 20					; pixels wide (preclipped)
.destHeight equ 24					; pixels high (preclipped)
.srcPtr equ 28
.srcWrap equ 32
.srcLeft equ 36
.srcTop equ 40

	mov edx,[esp+.destTop]
	mov ecx,[esp+.destLeft]
	imul edx,[esp+.destWrap]		; top * byte wrap
	add edx,ecx						; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr],edx
	mov edx,[esp+.srcTop]
	mov ecx,[esp+.srcLeft]
	imul edx,[esp+.srcWrap]			; top * byte wrap
	add edx,ecx						; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[esp+.destWidth]
	mov edx,eax
	sub [esp+.srcWrap],eax
	sub [esp+.destWrap],eax

	push esi
	push edi

	mov esi,[espbase+.srcPtr]
	mov edi,[espbase+.destPtr]
	;mov edx,[espbase+.destWidth]
%ifdef PlainIncludeMMX
	test dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	jnz .MMX
%endif

	;cld
.RowNext: ;(edi=dest ptr, esi=src ptr, edx=col count)
	mov ecx,dword [espbase+.destWidth]

	; first 0-3 pixels to align (head)
.HeadNext:
	test edi,4
	jz .ColAligned
	movsb
	dec ecx
	jg .HeadNext
    ; middle pixels, 4 at a time
.ColAligned:
	mov edx,edx						; copy col count for later
	sar ecx,2						; count / 4 pixels at a time
	jle .Tail
	rep movsd
.Tail:
	; last 0-3 pixels (tail)
	mov ecx,edx
	and ecx,3|(1<<31)				; remaining 0-3 pixels
	jle .RowEnd
	rep movsb

.RowEnd:
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop esi
	ret

%ifdef PlainIncludeMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)

.RowNextMMX:
	mov ecx,dword [espbase+.destWidth]
	cmp ecx,15						; don't bother with mem alignment
	jle .ColMMX						; if image to small to make difference

	; first 0-7 pixels (head of row)
	jmp short .HeadMMX
.HeadNextMMX:
	movsb
	dec ecx							; cols--
	jle .RowEndMMX					; end row if col count <= 0
.HeadMMX:
	test edi,7						; check if aligned yet
	jnz .HeadNextMMX				; loop until 8-byte aligned

	; middle pixels (64 bit destination aligned)
.ColMMX:
	mov edx,ecx						; copy remaining count
	sar edx,3
	jle .TailMMX
.ColNextMMX:
	movq mm0,[esi]					; read 8 pixels from src
	add esi,byte 8
	movq [edi],mm0					; write 8 pixels to dest
	add edi,byte 8
	dec edx
	jg .ColNextMMX

    ; last 0-7 pixels (tail of row)
.TailMMX:
	and ecx,7|(1<<31)				; remaining 0-7 pixels
	jle .RowEndMMX
	rep movsb
	; *** maybe faster ***
	;mov mm0,[edi]
	;mov mm2,[+ecx*4]
	;pcmpgtb
	;pand mm0,mm2
	;pand mm2,[esi]
	;por mm0,mm2
	;movq [edi],mm0
	;add esi,ecx
	;add edi,ecx

.RowEndMMX:
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

;//////////////////////////////////////////////////////////////////////////////
; Fills solid color to destination.
; dest = color
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			color and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitOpaqueColor:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; 20040801	created
;
global BlitOpaque32i32c
BlitOpaque32i32c:
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
%define espbase esp+4
.destPtr equ 4						; base pointer
.destWrap equ 8						; bytes per row
.destLeft equ 12					; pixel offset from left of base
.destTop equ 16						; pixel offset from top of base
.destWidth equ 20					; pixels wide (preclipped)
.destHeight equ 24					; pixels high (preclipped)
.srcColor equ 28					; color value constant

	mov edx,[esp+.destTop]
	mov ecx,[esp+.destLeft]
	imul edx,[esp+.destWrap]
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[esp+.destWidth]
	mov edx,eax
	shl eax,2
	sub [esp+.destWrap],eax

	push edi

	mov eax,[espbase+.srcColor]
	mov edi,[espbase+.destPtr]
	;mov edx,[esp+.destWidth]
%ifdef PlainIncludeMMX
	test dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	jnz .MMX
%endif

	;cld
.RowNext: ;(edi=dest ptr, eax=32bit color constant BGRA, edx=col count)
	mov ecx,edx						; col count = pixel width
	rep stosd
;.ColNext:
	;mov [edi],eax
	;add edi,byte 4
	;dec ecx
	;jg .ColNext
.RowEnd:
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	ret

%ifdef PlainIncludeMMX
.MMX: ;(edi=dest ptr, eax=32bit color constant BGRA, edx=col count)
	movd mm0,eax					; make 64bit reg = 2 32bit pixels
	movq mm1,mm0
	psllq mm1,32
	por mm0,mm1
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	dec ecx
	stosd
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX: ;(mm0=color constant)
	movq [edi],mm0					; write both pixels to dest
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count, mm0=color constant)
	jl .RowEndMMX					; count negative, so no tail
	stosd

.RowEndMMX:
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd


%endif

;//////////////////////////////////////////////////////////////////////////////
; 20040801	created
;
global BlitOpaque8i8c
BlitOpaque8i8c:
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
%define espbase esp+4
.destPtr equ 4						; base pointer
.destWrap equ 8						; bytes per row
.destLeft equ 12					; pixel offset from left of base
.destTop equ 16						; pixel offset from top of base
.destWidth equ 20					; pixels wide (preclipped)
.destHeight equ 24					; pixels high (preclipped)
.srcColor equ 28

	mov edx,[esp+.destTop]
	mov ecx,[esp+.destLeft]
	imul edx,[esp+.destWrap]
	;lea eax,[edx+ecx*1]			; dest offset = top*wrap + left*pixelsize
	add edx,ecx
	add [esp+.destPtr],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[esp+.destWidth]
	mov edx,eax
	sub [esp+.destWrap],eax

	push edi

	mov eax,[espbase+.srcColor]
	mov edi,[espbase+.destPtr]
	;mov edx,[esp+.destWidth]
%ifdef PlainIncludeMMX
	test dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	jnz .MMX
%endif

	mov ah,al						; XX.. ....	replicate pixel 4 times
	mov ecx,eax						; XX.. XX..
	shl ecx,16						; XX.. ..XX
	or eax,ecx						; XXXX ..XX

.RowNext: ;(edi=dest ptr, eax=color constant X 4, edx=col count)
	mov ecx,dword [espbase+.destWidth]

	; first 0-3 pixels to align (head)
.HeadNext:
	test edi,4
	jz .ColAligned
	stosb
	dec ecx
	jg .HeadNext
    ; middle pixels, 4 at a time
.ColAligned:
	mov edx,ecx						; copy col count for below
	sar ecx,2						; count / 4 pixels at a time
	jle .ColEnd
	rep stosd
.ColEnd:
	; last 0-3 pixels (tail)
	mov ecx,edx
	and ecx,3|(1<<31)				; remaining 0-3 pixels
	jle .RowEnd
	rep stosb

.RowEnd:
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	ret

%ifdef PlainIncludeMMX
.MMX: ;(edi=dest ptr, eax=8bit color constant X 4, edx=col count)
	and eax,255
	movd mm0,eax					; X.......	replicate pixel 8 times
	packuswb mm0,mm0				; X...X...	1 pixel becomes 2
	packuswb mm0,mm0				; X.X.X.X.	2 pixel becomes 4
	packuswb mm0,mm0				; XXXXXXXX	4 pixel becomes 8

.RowNextMMX:
	mov ecx,dword [espbase+.destWidth]
	cmp ecx,15						; don't bother with mem alignment
	jle .ColMMX						; if image to small to make difference

	; first 0-7 pixels (head of row)
	jmp short .HeadMMX
.HeadNextMMX:
	stosb
	dec ecx							; cols--
	jle .RowEndMMX					; end row if col count <= 0
.HeadMMX:
	test edi,7						; check if aligned yet
	jnz .HeadNextMMX				; loop until 8-byte aligned

	; middle pixels (64 bit destination aligned)
.ColMMX:
	mov edx,ecx						; copy remaining count
	sar edx,3
	jle .TailMMX
.ColNextMMX:
	movq [edi],mm0					; write 8 pixels to dest
	add edi,byte 8
	dec edx
	jg .ColNextMMX

    ; last 0-7 pixels (tail of row)
.TailMMX:
	and ecx,7|(1<<31)				; remaining 0-7 pixels
	jle .RowEndMMX
	rep stosb

.RowEndMMX:
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

;//////////////////////////////////////////////////////////////////////////////
; Draws translucently given opacity channel.
; dest = (src * opacity) + (dest * (1-opacity))
;
; Opacity: 0=Transparent 1-254=translucent 255=Opaque
;
BlitTrans:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; Fills solid color given opacity channel.
; dest = (color * opacity) + (dest * (1-opacity))
;
; Opacity: 0=Transparent 1-254=translucent 255=Opaque
;
BlitTransColor:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; Draws image with transparent 'keyed' areas.
; dest = (src > 0) ? src : dest
; dest = (src_alpha > 191) ? src : dest
;
; For 32bit images with an alpha channel: 0-191=Transparent 192-255=Opaque
; For 8bit images with keyed pixels:      0=Transparent     1-255=Opaque
;
; This routine can blit alpha-channeled images faster BlitTrans because it
; either writes the pixel or doesn't, no blending; but that means the edges
; are rough.
;
BlitTransFast:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; 20040802	created
;
global BlitTransFast32i32i
BlitTransFast32i32i:
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
%define espbase esp+8
.destPtr equ 4						; base pointer
.destWrap equ 8						; bytes per row
.destLeft equ 12					; pixel offset from left of base
.destTop equ 16						; pixel offset from top of base
.destWidth equ 20					; pixels wide (preclipped)
.destHeight equ 24					; pixels high (preclipped)
.srcPtr equ 28
.srcWrap equ 32
.srcLeft equ 36
.srcTop equ 40

	mov edx,[esp+.destTop]
	mov ecx,[esp+.destLeft]
	imul edx,[esp+.destWrap]
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr],eax
	mov edx,[esp+.srcTop]
	mov ecx,[esp+.srcLeft]
	imul edx,[esp+.srcWrap]
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[esp+.destWidth]
	mov edx,eax
	shl eax,2
	sub [esp+.srcWrap],eax
	sub [esp+.destWrap],eax

	push esi
	push edi

	mov esi,[espbase+.srcPtr]
	mov edi,[espbase+.destPtr]
	;mov edx,[espbase+.destWidth]
%ifdef PlainIncludeMMX
	test dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	jnz .MMX
%endif

	;cld
	mov edx,[espbase+.destHeight]
.RowNext: ;(edi=dest ptr, esi=src ptr, edx=row count)
	mov ecx,[espbase+.destWidth]        ; col count = pixel width
.ColNext:
	mov eax,[esi]					; get source pixel
	add esi,byte 4
	cmp eax,192<<24					; alpha channel in top byte
	jb .ColTrans
	mov [edi],eax					; opaque if >= 192
.ColTrans:
	add edi,byte 4
	dec ecx
	jg .ColNext
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec edx
	jg .RowNext

.ImageEnd:
	pop edi
	pop esi
	ret

%ifdef PlainIncludeMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)

.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	mov eax,[esi]					; get source pixel
	add esi,byte 4
	dec ecx
	cmp eax,192<<24					; alpha channel in top byte
	jae .HeadTransMMX
	mov [edi],eax					; opaque if >= 192
.HeadTransMMX:
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX

	; remaining 64bit pixels
	movq mm3,[.AlphaComp]			; get comparison mask
.ColNextMMX:
	movq mm1,[esi]
	movq mm0,[edi]					; read next two dest pixels
	movq mm2,mm1					; copy src
	psrld mm2,1
	pcmpgtd mm2,mm3					; make pixel mask
	pand mm1,mm2					; src & !mask
	pandn mm2,mm0					; dest & mask
	add esi,byte 8
	por mm1,mm2						; src | dest
	movq [edi],mm1					; write both pixels to dest
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	mov eax,[esi]					; get source pixel
	add esi,byte 4
	dec ecx
	cmp eax,192<<24					; alpha channel in top byte
	jae .TailTransMMX
	mov [edi],eax					; opaque if >= 192
.TailTransMMX:
	add edi,byte 4

.RowEndMMX:
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd

align 8
.AlphaComp:	db 0FFh,0FFh,0FFh,191>>1, 0FFh,0FFh,0FFh,191>>1
%endif


;//////////////////////////////////////////////////////////////////////////////
; Maps an image using palette table, converting formats or convoluting colors.
; dest = palette[src]
;
; For 32bit images with an alpha channel: 0-191=Transparent 192-255=Opaque
; For 8bit images with keyed pixels:      0=Transparent     1-255=Opaque
;
BlitMap:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; <Not sure I'll implement this one. In most cases, it is not worth it>
;
; Maps an image using palette table, either converting to another format or
; convoluting the colors. This convenient hybrid considerskey
;BlitMapKey:
;	int3 ;not finished!

;//////////////////////////////////////////////////////////////////////////////
; Adds source to destination, saturating each chroma to 255.
; dest = dest + src
;
; 32bit images have each chroma added excluding alpha channels
; 8bit images are treated as grayscale
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitAdd:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; 20040715	created
; 20040723	added MMX 8 byte destination alignment
;
global BlitAdd32i32i
BlitAdd32i32i:
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
%define espbase esp+12
.destPtr equ 4						; base pointer
.destWrap equ 8						; bytes per row
.destLeft equ 12					; pixel offset from left of base
.destTop equ 16						; pixel offset from top of base
.destWidth equ 20					; pixels wide (preclipped)
.destHeight equ 24					; pixels high (preclipped)
.srcPtr equ 28
.srcWrap equ 32
.srcLeft equ 36
.srcTop equ 40

	mov edx,[esp+.destTop]
	mov ecx,[esp+.destLeft]
	imul edx,[esp+.destWrap]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr],eax
	mov edx,[esp+.srcTop]
	mov ecx,[esp+.srcLeft]
	imul edx,[esp+.srcWrap]			; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[esp+.destWidth]
	mov edx,eax
	shl eax,2
	sub [esp+.srcWrap],eax
	sub [esp+.destWrap],eax

	push esi
	push edi
	push ebx

	mov esi,[espbase+.srcPtr]
	mov edi,[espbase+.destPtr]
	;mov edx,[espbase+.destWidth]
%ifdef PlainIncludeMMX
	test dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	jnz .MMX
%endif

.RowNext:
	mov ecx,edx						; col count = pixel width
.ColNext:
	mov eax,[esi]					; get source pixel
	mov ebx,[edi]
	add al,bl
	jnc .BlueOk						; add each component
	mov al,255						; saturate blue
.BlueOk:
	add ah,bh
	jnc .GreenOk
	mov ah,255						; saturate green
.GreenOk:
	ror eax,16						; access third bytes (red) RABG
	shr ebx,16
	add al,bl
	jnc .RedOk
	mov al,255						; saturate red
.RedOk:								; note alphas are NOT added
	rol eax,16						; restore to BGRA
	add esi,byte 4
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%ifdef PlainIncludeMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
	movq mm2,[.RgbMask]
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	movq mm0,[esi]					; grab next source pixel (second ignored)
	dec ecx
	pand mm0,mm2					; mask off the alpha byte
	paddusb mm0,[edi]				; add BGR pixels
	add esi,byte 4
	movd [edi],mm0					; write single pixel to dest
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX:
	movq mm0,[esi]					; read next two pixels
	pand mm0,mm2					; mask off the alpha byte
	paddusb mm0,[edi]				; add BGR pixels
	add esi,byte 8
	movq [edi],mm0					; write both pixels to dest
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movq mm0,[esi]					; grab next source pixel (second ignored)
	pand mm0,mm2					; mask off the alpha byte
	paddusb mm0,[edi]				; add BGR pixels
	add esi,byte 4
	movd [edi],mm0					; write single pixel to dest
	add edi,byte 4

.RowEndMMX:
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd

align 8
; This mask clears the top alpha byte so they are not added.
.RgbMask: dd 00FFFFFFh,00FFFFFFFh
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040801	created
;
global BlitAdd8i8i
BlitAdd8i8i:
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
%define espbase esp+12
.destPtr equ 4						; base pointer
.destWrap equ 8						; bytes per row
.destLeft equ 12					; pixel offset from left of base
.destTop equ 16						; pixel offset from top of base
.destWidth equ 20					; pixels wide (preclipped)
.destHeight equ 24					; pixels high (preclipped)
.srcPtr equ 28
.srcWrap equ 32
.srcLeft equ 36
.srcTop equ 40

	mov edx,[esp+.destTop]
	mov ecx,[esp+.destLeft]
	imul edx,[esp+.destWrap]		; top * byte wrap
	add edx,ecx						; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr],edx
	mov edx,[esp+.srcTop]
	mov ecx,[esp+.srcLeft]
	imul edx,[esp+.srcWrap]			; top * byte wrap
	add edx,ecx						; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[esp+.destWidth]
	mov edx,eax
	sub [esp+.srcWrap],eax
	sub [esp+.destWrap],eax

	push esi
	push edi
	push ebx

	mov esi,[espbase+.srcPtr]
	mov edi,[espbase+.destPtr]
	;mov edx,[espbase+.destWidth]
%ifdef PlainIncludeMMX
	test dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	jnz near .MMX
%endif

.RowNext: ;(edi=dest ptr, esi=src ptr, edx=col count)
	mov ecx,dword [espbase+.destWidth]

	; first 0-3 pixels to align (head)
	mov ebx,[esi]					; get src pixel
.HeadNext:
	test edi,4
	jz .ColAligned
	add [edi],bl					; dest += color
	jnc .HeadOk
	mov [edi],byte 255				; saturate grey
.HeadOk:
	inc esi
	shr ebx,8						; next src pixel
	inc edi
	dec ecx
	jg .HeadNext

    ; middle pixels, 4 at a time
.ColAligned:
	mov edx,ecx
	sar edx,2						; count / 4 pixels at a time
	jle .Tail

.ColNext:
	mov eax,[edi]					; get dest pixel
	mov ebx,[esi]					; get src pixel
	; ** check if this would be faster **
	;	add cl,bl
	;	salc
	;	or cl,al
	;	add ch,bh
	;	salc
	;	or ch,al
	;	...
	add al,bl
	jnc .Ok1
	mov al,255						; saturate first byte
.Ok1:
	add ah,bh
	jnc .Ok2
	mov ah,255						; saturate second byte
.Ok2:
	ror ebx,16						; access third&fourth bytes
	ror eax,16						; access third&fourth bytes
	add al,bl
	jnc .Ok3
	mov al,255						; saturate third byte
.Ok3:
	add ah,bh
	jnc .Ok4
	mov ah,255						; saturate fourth byte
.Ok4:
	rol eax,16						; restore first&second bytes
	rol ebx,16						; restore first&second bytes
	mov [edi],eax
	add esi,byte 4
	add edi,byte 4
	dec edx
	jg .ColNext

.Tail:
	and ecx,3|(1<<31)				; remaining 0-3 pixels
	jle .RowEnd
	mov ebx,[esi]					; get src pixel
	add esi,ecx
.TailNext:
	add [edi],bl					; dest += color
	jnc .TailOk
	mov [edi],byte 255				; saturate grey
.TailOk:
	shr ebx,8						; next src pixel
	inc edi
	dec ecx
	jg .TailNext

.RowEnd:
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%ifdef PlainIncludeMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)

.RowNextMMX:
	mov edx,dword [espbase+.destWidth]
	cmp edx,15						; don't bother with mem alignment
	jle .ColMMX						; if image to small to make difference

	; first 0-7 pixels (head of row)
	jmp short .HeadMMX
.HeadNextMMX:
	mov al,[esi]					; get src pixel
	inc esi							; src ptr++
	add [edi],al					; dest += src
	jnc .HeadOkMMX
	mov [edi],byte 255				; saturate grey
.HeadOkMMX:
	inc edi							; dest ptr++
	dec edx							; cols--
	jle .RowEndMMX					; end row if col count <= 0
.HeadMMX:
	test edi,7						; check if aligned yet
	jnz .HeadNextMMX				; loop until 8-byte aligned
; *** check if this would be faster ***
;	mov al,[esi]
;	add al,[edi]					; dest pixel += constant
;	inc esi							; src ptr++
;	salc
;	or al,cl						; saturate grey
;	mov [edi],al
;	inc edi							; dest ptr++
;	dec edx							; cols--
;	jle .RowEndMMX					; end row if col count <= 0

	; middle pixels (64 bit destination aligned)
.ColMMX:
	mov ecx,edx						; copy remaining count
	sar ecx,3						; count / 8 pixels at a time
	jle .TailMMX
.ColNextMMX:
	movq mm0,[esi]					; get 8 src pixels
	add esi,byte 8
	paddusb mm0,[edi]				; add monochrome pixels
	movq [edi],mm0					; write 8 dest pixels
	add edi,byte 8
	dec ecx
	jg .ColNextMMX

    ; last 0-7 pixels (tail of row)
.TailMMX:
	test edx,7|(1<<31)
	jle .RowEndMMX
	movq mm2,[.0]					; get comparison sequence
	movq mm0,[esi]					; get 8 src pixels
	pcmpgtb mm2,[.0+ecx*8]			; make pixel mask
	pand mm0,mm2					; zero upper unused bytes
	paddusb mm0,[edi]				; add monochrome pixels
	add esi,ecx
	movq [edi],mm0					; write 8 dest pixels
	add edi,ecx

; *** old tail code ***
;	and edx,7|(1<<31)
;	jle .RowEndMMX
;.TailNextMMX:
;	mov al,[esi]					; get src pixel
;	inc esi							; src ptr++
;	add [edi],al					; dest += src
;	jnc .TailOkMMX
;	mov [edi],byte 255				; saturate grey
;.TailOkMMX:
;	inc edi							; dest ptr++
;	dec edx							; cols--
;	jg .TailNextMMX					; end row if col count <= 0

.RowEndMMX:
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd

align 8
.0:	db 0,1,2,3,4,5,6,7
.1: db 1,1,1,1,1,1,1,1
.2: db 2,2,2,2,2,2,2,2
.3: db 3,3,3,3,3,3,3,3
.4: db 4,4,4,4,4,4,4,4
.5: db 5,5,5,5,5,5,5,5
.6: db 6,6,6,6,6,6,6,6
.7: db 7,7,7,7,7,7,7,7
%endif


;//////////////////////////////////////////////////////////////////////////////
; Adds color constant to destination, saturating each chroma to 255.
; dest = dest + color
;
; 32bit images have each chroma added INCLUDING alpha channels (if alpha > 0)
; 8bit images are treated as grayscale
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			color and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitAddColor:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; 20040723	created
;
global BlitAdd32i32c
BlitAddFill32i32c:
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
%define espbase esp+8
.destPtr equ 4						; base pointer
.destWrap equ 8						; bytes per row
.destLeft equ 12					; pixel offset from left of base
.destTop equ 16						; pixel offset from top of base
.destWidth equ 20					; pixels wide (preclipped)
.destHeight equ 24					; pixels high (preclipped)
.srcColor equ 28

	mov edx,[esp+.destTop]
	mov ecx,[esp+.destLeft]
	imul edx,[esp+.destWrap]
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[esp+.destWidth]
	mov edx,eax
	shl eax,2
	sub [esp+.destWrap],eax

	push ebx
	push edi

	mov ebx,[espbase+.srcColor]
	mov edi,[espbase+.destPtr]
	;mov edx,[esp+.destWidth]
%ifdef PlainIncludeMMX
	test dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	jnz .MMX
%endif

	mov edx,ebx						; copy color value
	shr edx,16						; access red byte
	; (bx=blue & green, dl=red)
.RowNext:
	mov ecx,[espbase+.destWidth]	; col count = pixel width
.ColNext:
	mov eax,[edi]					; get dest pixel
	add al,bl
	jnc .BlueOk						; add each component
	mov al,255						; saturate blue
.BlueOk:
	add ah,bh
	jnc .GreenOk
	mov ah,255						; saturate green
.GreenOk:
	ror eax,16						; access third bytes (red) RABG
	add al,dl
	jnc .RedOk
	mov al,255						; saturate red
.RedOk:								; note alphas ARE added
	rol eax,16						; restore to BGRA
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop ebx
	ret

%ifdef PlainIncludeMMX
.MMX: ;(edi=dest ptr, ebx=32bit color constant BGRA, edx=col count)
	movd mm1,ebx					; make 64bit reg = 2 32bit pixels
	movq mm2,mm1
	psllq mm2,32
	por mm1,mm2
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
    movq mm0,mm1					; copy color constant
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
    movq mm0,mm1					; copy color constant
	paddusb mm0,[edi]				; add BGR pixels
	dec ecx
	movd [edi],mm0					; write single pixel to dest
    movq mm0,mm1					; precopy color constant
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX: ;(mm0&mm1=color constant)
	paddusb mm0,[edi]				; add BGR pixels
	movq [edi],mm0					; write both pixels to dest
	add edi,byte 8
	movq mm0,mm1					; precopy color constant for next loop
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count, mm0&mm1=color constant)
	jl .RowEndMMX					; count negative, so no tail
    ;movq mm0,mm1 (redundant)		; copy color constant
	paddusb mm0,[edi]				; add BGR pixels
	movd [edi],mm0					; write single pixel to dest
	add edi,byte 4

.RowEndMMX:
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040723	created
;
global BlitAdd8i8c
BlitAdd8i8c:
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
%define espbase esp+8
.destPtr equ 4						; base pointer
.destWrap equ 8						; bytes per row
.destLeft equ 12					; pixel offset from left of base
.destTop equ 16						; pixel offset from top of base
.destWidth equ 20					; pixels wide (preclipped)
.destHeight equ 24					; pixels high (preclipped)
.srcColor equ 28

	mov edx,[esp+.destTop]
	mov ecx,[esp+.destLeft]
	imul edx,[esp+.destWrap]
	;lea eax,[edx+ecx*1]			; dest offset = top*wrap + left*pixelsize
	add edx,ecx
	add [esp+.destPtr],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[esp+.destWidth]
	mov edx,eax
	sub [esp+.destWrap],eax

	push ebx
	push edi

	mov ebx,[espbase+.srcColor]
	mov edi,[espbase+.destPtr]
	;mov edx,[esp+.destWidth]
%ifdef PlainIncludeMMX
	test dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	jnz .MMX
%endif

.RowNext: ;(edi=dest ptr, bl=color, edx=col count)
	mov ecx,edx						; col count = pixel width
	sar ecx,2						; count / 4 pixels at a time
	jle .Tail
.ColNext:
	mov eax,[edi]					; get dest pixel
	add al,bl
	jnc .Ok1
	mov al,255						; saturate first byte
.Ok1:
	add ah,bl
	jnc .Ok2
	mov ah,255						; saturate second byte
.Ok2:
	ror eax,16						; access third&fourth bytes
	add al,bl
	jnc .Ok3
	mov al,255						; saturate third byte
.Ok3:
	add ah,bl
	jnc .Ok4
	mov ah,255						; saturate fourth byte
.Ok4:
	rol eax,16						; restore first&second bytes
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .ColNext
.ColEnd:
	mov ecx,edx
	and ecx,3|(1<<31)				; remaining 0-3 pixels
	jle .RowEnd
.Tail:
.TailNext:
	add [edi],bl
	jnc .TailOk
	mov [edi],byte 255
.TailOk:
	inc edi
	dec ecx
	jg .TailNext
.RowEnd:
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop ebx
	ret

%ifdef PlainIncludeMMX
.MMX: ;(edi=dest ptr, bl=8bit color constant, edx=col count)
	and ebx,255
	movd mm1,ebx					; X.......	replicate pixel 8 times
	packuswb mm1,mm1				; X...X...	1 pixel becomes 2
	packuswb mm1,mm1				; X.X.X.X.	2 pixel becomes 4
	packuswb mm1,mm1				; XXXXXXXX	4 pixel becomes 8

.RowNextMMX:
	mov edx,dword [espbase+.destWidth]
	cmp edx,15						; don't bother with mem alignment
	jle .ColMMX						; if image to small to make difference

	; first 0-7 pixels (head of row)
	jmp short .HeadMMX
.HeadNextMMX:
	add [edi],bl					; dest pixel += constant
	jnc .HeadOkMMX
	mov [edi],byte 255				; saturate grey
.HeadOkMMX:
	inc edi							; dest ptr++
	dec edx							; cols--
	jle .RowEndMMX					; end row if col count <= 0
.HeadMMX:
	test edi,7						; check if aligned yet
	jnz .HeadNextMMX				; loop until 8-byte aligned

	; middle pixels (64 bit destination aligned)
.ColMMX:
	mov ecx,edx						; copy remaining count
	movq mm0,mm1					; precopy color constant
	sar ecx,3						; count / 8 pixels at a time
	jle .TailMMX
.ColNextMMX:
	paddusb mm0,[edi]				; add monochrome pixels
	movq [edi],mm0					; write 8 pixels to dest
	add edi,byte 8
	movq mm0,mm1					; precopy color constant for next loop
	dec ecx
	jg .ColNextMMX

    ; last 0-7 pixels (tail of row)
.TailMMX:
	and edx,7|(1<<31)
	jle .RowEndMMX
.TailNextMMX:
	add [edi],bl					; dest pixel += constant
	jnc .TailOkMMX
	mov [edi],byte 255				; saturate grey
.TailOkMMX:
	inc edi							; dest ptr++
	dec edx							; cols--
	jg .TailNextMMX					; end row if col count <= 0

.RowEndMMX:
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd

%if 0
*** old code ***
	mov ecx,edx						; col count = pixel width
	sar ecx,3						; count / 8 pixels at a time
	jle .ColEndMMX
	movq mm0,mm1					; copy color constant
.ColNextMMX:
	paddusb mm0,[edi]				; add monochrome pixels
	movq [edi],mm0					; write 8 pixels to dest
	add edi,byte 8
	movq mm0,mm1					; precopy color constant
	dec ecx
	jg .ColNextMMX
.ColEndMMX:
	mov ecx,edx						; col count = pixel width
	and ecx,3|(1<<31)				; remaining 0-7 pixels
	jle .RowEndMMX
.ColEndNextMMX:
	add [edi],bl
	jnc .OkMMX
	mov [edi],byte 255
.OkMMX:
	inc edi
	dec ecx
	jg .ColEndNextMMX
%endif

%endif


;//////////////////////////////////////////////////////////////////////////////
; Subtracts source from destination, saturating each chroma to 0.
; dest = dest - src
;
; 32bit images have each chroma added excluding alpha channels
; 8bit images are treated as grayscale
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitSub:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; 20040803	created
;
global BlitSub32i32i
BlitSub32i32i:
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
%define espbase esp+12
.destPtr equ 4						; base pointer
.destWrap equ 8						; bytes per row
.destLeft equ 12					; pixel offset from left of base
.destTop equ 16						; pixel offset from top of base
.destWidth equ 20					; pixels wide (preclipped)
.destHeight equ 24					; pixels high (preclipped)
.srcPtr equ 28
.srcWrap equ 32
.srcLeft equ 36
.srcTop equ 40

	mov edx,[esp+.destTop]
	mov ecx,[esp+.destLeft]
	imul edx,[esp+.destWrap]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr],eax
	mov edx,[esp+.srcTop]
	mov ecx,[esp+.srcLeft]
	imul edx,[esp+.srcWrap]			; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[esp+.destWidth]
	mov edx,eax
	shl eax,2
	sub [esp+.srcWrap],eax
	sub [esp+.destWrap],eax

	push esi
	push edi
	push ebx

	mov esi,[espbase+.srcPtr]
	mov edi,[espbase+.destPtr]
	;mov edx,[espbase+.destWidth]
%ifdef PlainIncludeMMX
	test dword [Pgfx.Flags],Pgfx.FlagsUseMMX
	jnz .MMX
%endif

.RowNext:
	mov ecx,edx						; col count = pixel width
.ColNext:
	mov ebx,[esi]					; get source pixel
	mov eax,[edi]
	sub al,bl
	jnc .BlueOk						; add each component
	xor al,al						; saturate blue
.BlueOk:
	sub ah,bh
	jnc .GreenOk
	xor ah,ah						; saturate green
.GreenOk:
	ror eax,16						; access third bytes (red) RABG
	shr ebx,16
	sub al,bl
	jnc .RedOk
	xor al,al						; saturate red
.RedOk:								; note alphas are NOT added
	rol eax,16						; restore to BGRA
	add esi,byte 4
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%ifdef PlainIncludeMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
	movq mm2,[.RgbMask]
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	movq mm0,[esi]					; grab next source pixel (second ignored)
	dec ecx
	pand mm0,mm2					; mask off the alpha byte
	psubusb mm0,[edi]				; add BGR pixels
	add esi,byte 4
	movd [edi],mm0					; write single pixel to dest
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX:
	movq mm0,[edi]					; read next two source pixels
	pand mm0,mm2					; mask off the alpha byte
	psubusb mm0,[esi]				; subtract BGR pixels
	add esi,byte 8
	movq [edi],mm0					; write both pixels to dest
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movq mm0,[esi]					; grab next source pixel (second ignored)
	pand mm0,mm2					; mask off the alpha byte
	psubusb mm0,[edi]				; add BGR pixels
	add esi,byte 4
	movd [edi],mm0					; write single pixel to dest
	add edi,byte 4

.RowEndMMX:
	add esi,[espbase+.srcWrap]
	add edi,[espbase+.destWrap]
	dec dword [espbase+.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd

align 8
; This mask clears the top alpha byte so they are not added.
.RgbMask: dd 00FFFFFFh,00FFFFFFFh
%endif


;//////////////////////////////////////////////////////////////////////////////
; Subtracts color constant from destination, saturating each chroma to 0.
; dest = dest - color
;
; 32bit images have each chroma added INCLUDING alpha channels
; 8bit images are treated as grayscale
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitSubColor:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; Multiplies destination by source, reducing each chroma toward 0.
; dest = dest * src
;
; 32bit images have each chroma added excluding alpha channels
; 8bit images are treated as grayscale
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitMul:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; Multiplies destination by color constant, reducing each chroma toward 0.
; dest = dest * color
;
; 32bit images have each chroma added excluding alpha channels
; 8bit images are treated as grayscale
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitMulColor:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; Ands destination with source.
; dest = dest & src
;
; All bits are ANDed including alpha channel, so keep that in mind.
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitAnd:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; Ands destination with source.
; dest = dest | src
;
; All bits are ORed including alpha channel, so keep that in mind.
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitOr:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; Picks the greater value of destination or source.
; dest = max(dest, src)
;
; Each chroma is compared individually.
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitGreater:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; Picks the lesser value of destination or source.
; dest = min(dest, src)
;
; Each chroma is compared individually.
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitLesser:
	int3 ;not finished!

