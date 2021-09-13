; PGFXLL.ASM - Plain Graphics Low Level Functions (v3.0)
; -These functions should generally not be called by application code,
;  but rather by other graphics functions.
; -Calling them directly means little overhead and fast execution, but
;  it's dangerous, since most of them depend on clipping and parameter
;  validation being done already by a high level function. So they assume
;  all pointers, dimensions, and offsets are valid.
;
;______________________________________________________________________________
; Functions to implement:
;
;<< Blending Functions (binary or trinary) >>
; BlitOpaque - copy solid image or fill rectangle with solid color
;   8i8i 32i32i 8i8c 32i32c
; BlitTrans - blit translucent image or given color|alpha constant (BGRA)
;   32i32i 32i32c 32i32ic
; BlitTransFast - for regions with holes but fast blit wanted
;   8i8i 32i32i 32i32if
; BlitMask - applies a mask to an image
;   8i8i 32i8i
; BlitPal - for palette mapping of indexed images or color transforms
;	8i8i8p 8i32i32p 32i8i32p 32i32i96p
;	can be used for effects like color mapping, greyscale, false color...
; BlitPalMap - converts true color image to indexed
;	8i32i32p
;	unlike BlitPal, this uses a dynamic palette rather than static.
;	also, this function needs to know the total number of palette entries
; BlitPalTrans? - hybrid for convenience
;	32i8i32p
; BlitAdd - add src or color constant to dest pixels
;	8i8i 32i32i 8i8c 32i32c
; BlitSub - subtract src from dest pixels
;	8x8 32x32
; BlitMul - multiply src or constant with dest pixels (0=black 255=full value)
;	8i8i 32i32i 32i8i 8i8c 32i32c
;	* BlitMul multiplies each channel in parallel
; BlitMulByAlpha - multiplies all pixels by alpha value to use add/sub
;	32i32i
; BlitAnd - boolean AND of pixels
;	1i1i 8i8i 32i32i
; BlitOr - boolean OR of pixels
;	1i1i 8i8i 32i32i
; BlitAndOr -  combination AND followed by OR for replacing single channels
;	8i8c8c 32i32c32c
; BlitGreater - choose the greater of source or destination pixel value
;	1i1i 8i8i 32i32i
; BlitLesser - choose the lesser of source or destination pixel value
;	1i1i 8i8i 32i32i
; BlitDecomp
;	Just a decompressor for compressed images.
;
;<< Effect Functions >>
; BlitGlow - build diffuse glow around opacity
;	8i8i8i 8i32i8i
;	dest, src, glowmask
;	You can not apply a glow directly to a 32bit image. Instead you must
;	build the 8bit glow mask, then apply a color to mask.
;
;<< Distortion Functions >>
; BlitTile - tile an image pattern (always opaque)
;	8i8i 32i32i
; BlitScale - strech/squash an image (always opaque)
;	8i8i 32i32i
; BlitSkew - skew, strech, rotate image (always opaque)
;	8i8i32dc32dc 32i32i
; BlitWarp - blit image using warp map (delta transformation)
;	32i32i32d
;	32i32i16d16d
;	want one that can warp along every single pixel, and one that can use two
;	arrays to shear along each axis.
;
;<< Text Functions >>
; BlitFont/BlitFontRight // builds glyphs into bitmap, left to right
;
;<< Questionable >>
; MapPalette - builds 8bit table from one palette to another
;	8x32x32
; convert alpha image to addable image by multiplying the three chroma RGB
;	by the alpha byte.
; expand single channel to one of four, either R|G|B|T.
; map monochrome image to color, given maximum color
; BlitMono - convert image to monochrome (weighted or balanced)
;   8x32 32x8 32x32 
;
;______________________________________________________________________________
; Notes:
;
; Performance:
;  -The MMX versions of each function offer a nearly 4x speed advantage.
;	The only reason why the non MMX versions exist is for non MMX machines or
;	unforeseen incompatibilities with certain processors. 20040107
;  -Prerender the alphatransparency if at all possible. The TransFast is nearly
;	5x faster than the alpha version, and opaque more than 6x faster.
;	Once compressed images are supported, alpha blitting will be just as fast
;	- assuming the images are mostly opaque and transparent, not translucent.
;	20040107
;  -Use addition/subtraction whenever possible for translucent effects like
;	glass, fog, or shadowing. It's 6x faster than calling Trans and 7x faster
;	than Mult. 20040107
;  -Try to make all image widths multiples of 8 bytes (so multiple of 8 for 
;	8bit images and even widths for 32bit images) to take advantage of memory
;	alignment for MMX operations.
;
; Capabilities:
;  -Many common graphics functions (like ellipse and line drawing) are ommitted
;   because the emphasis is using prerendered images rather than a sequence of
;   shape primitives.
;  -It is possible to use any Windows GDI function on the display buffer by
;   selecting the DIB section into a DC and passing that to the function.
;  -Tiling/streching is always opaque and can not simultaneously be combined
;   with colormapping/addition/alpha... However, the tiling/streching can be
;	done to a temporary image, which can then be combined in any way desired.
;
; Structures:
;  -All images are 2D rectangular arrays, right/down order, of discrete-valued
;   pixels, in gammaless RGB color space. Each color channel is 8bits (1bit is
;   only used a mask and never as pixels).
;  -Palettes and pixels are stored as BGRA (least significant blue to most sig
;   alpha) instead of Window's screwed up PALETTEENTRY.
;  -Indexed images have no inherent color information. They must explicitly map
;   indexes to colors via a palette.
;  -The alpha channel is always opacity (not transparency) so 255=fully opaque
;   and 0=fully transparent.
;
; Function parameters:
;  -Most blitters of the same 'class' accept exactly the same parameters.
;	Exceptions include complex ops like tiling/streching/warping, palette use,
;	and hybrid blitters that accept multiple source images.
;  -Parameters are always destination, source, additional sources (if any),
;	and additional parameters after.
;  -Most functions are binary and use the first image as both source and
;	destination (this way there are fewer pointers to keep track of and less
;	memory to footprint), but a few are trinary as a convenience, blending two
;	writing to a new destination. Any such functions are unnecessary (could
;	be accomplished with multiple binary functions) but exist for speed and
;	memory advantages.
;	  For example, the common operation of blitting a translucent color through
;	a mask (for fonts and glows) could be accomplished by colorizing the mask
;	using palette or multiply, then calling trans; but this requires an
;	additional temporary bitmap and uses twice the memory bandwidth.
;	  Less common operations like adding a color constant given a mask are not
;	important enough to warrant their own trinary functions, and must be done
;	by two separate calls.
;
; Functions:
;  -Most functions favor destination memory alignment over source alignment for
;   two reasons: Except complete opaqueness, most operations perform only a read
;   of the source but both read/write of the destination. Also, the destination
;   is slower memory if blitting directly to video memory - not recommended.
;  -Every operation has a public function and a private, raw function.
;	Calling the raw function can be slightly faster if clipping information and
;	image types are already known, but all memory pointers must be valid, size
;	positive, and wraps correct. Calling it with invalid pointers will GPF.
;   Calling it with zero or negative sizes is unlikely to GPF, but can draw
;   unpredictable results.
;  -Raw functions expect specific parameters, their type denoted by a suffix:
;	Function#x#x
;		8=8bit indexed or monochrome
;		32=32bit true color, BGRA or BGR_
; 		i=image  c=color constant  p=palette
;	BlitPal32i8i32p means blit 8bit image using 32bit palette to a 32bit image.
;
; Compression:
;  -All compression types are lossless, using a combination of run length
;	encoding and back references to previous pixel sequences.
;  -There two classes of compression, high compressesion that is slower to
;	decompress (meant for program startup or loading of new graphics) and a
;	faster low compression.
;  -The fast compression is actually not meant to save space but to increase
;	blitting speed. Since the blitter need not test every single pixel, it
;	can skip large transparent runs or treat a large run of opaque areas as
;	a direct copy.
;  -Blitting compressed images is slower though if the operation does not
;	support them natively, since the image must first be decompressed.
;  -Type 1 (fast 32bit)
;   Each run is preceded by an info dword consisting of the run length
;	(lower 16bits) and a few informative bits (flags in the upper 16).
;	Immediately after that comes the single pixel value to repeat or
;	pixel strip to copy.
;		If it a single pixel value to repeat:
;			Bytes	0-3    4-7     8-11        12
;			        [info] [pixel] [next info] [...
;		If it a pixel strip to copy directly (say 3 pixels):
;			Bytes	0-3    4-7     8-11    12-15   16-19       20
;			        [info] [pixel] [pixel] [pixel] [next info] [...
;		If it is a transparent run:
;			Bytes	0-3    8-11        12
;			        [info] [next info] [...
;		Info bits:
;			0-15:	length (1-#)
;			29:		opaque (following run is completely opaque)
;					This bit informs the blitter that it need not test every
;					pixel individually and can copy direct. If not set, the
;					blitter assumes all or at least one is translucent and does
;					the normal test on every pixel.
;			30:		transparent (skip the given run length of bytes)
;					There is no pixel before the next info dword, since the
;					value of 'transparent' is rather implicit ;)
;			31:		repeat single value (otherwise strip)
;					A single pixel value follows.
;  -Type 2 (fast 8bit)
;	Each run is preceded by an info byte consisting of the run length
;	(lower 6bits) and a few informative bits (flags in upper 2).
;	Immediately after that comes the single pixel value to repeat or
;	pixel strip to copy.
;		If it a single pixel value to repeat:
;			Bytes	0      1       2           3
;			        [info] [pixel] [next info] [...
;		If it a pixel strip to copy directly (say 3 pixels):
;			Bytes	0      1       2       3       4           5
;			        [info] [pixel] [pixel] [pixel] [next info] [...
;		If it is a transparent run:
;			Bytes	0      1           2
;			        [info] [next info] [...
;		Info bits:
;			0-5:	length (1-63)
;			6:		transparent (skip the given run length of bytes)
;					There is no pixel before the next info dword, since the
;					value of 'transparent' is rather implicit ;)
;			7:		repeat single value (otherwise strip)
;					A single pixel value follows.
;  -Type 3 (fast 1bit)
;	Each run is a single byte consisting of the run length (lower 7bits)
;	and an information bit (msb). Immediately after that comes the next
;	run.
;		Whether transparent or opaque:
;			Bytes	0      1      2      3
;			        [info] [info] [info] [...
;		Info bits:
;			0-6:	length (1-127)
;			7:		transparent (skip the given run length of bytes)
;					There is no pixel before the next info dword, since the
;					value of 'transparent' is rather implicit ;)
;  -Type 4 (slow but higher compression)
;	Umm... Undefined for now. This will be the compression used for style file
;	images - either ZLIB or a simple lossless format. This format will not be
;	supported directly by ANY operations and must be decompressed first. It
;	need only be decompressed during style loading.
;  -I may add more compression types, but for now I don't see any reason too
;	since these cover them all, and adding more makes my life harder. 
;______________________________________________________________________________
;
; Hmm:
; How to order parameters?
; BlitFont(dest..., string, font)
;
; information about the current destination buffer, whether it be a virtual
; buffer, temporary bitmap, or directly to the screen.
;
; 0F9B1A780H,0FC37H,011D8H,0B6H,0CDH,0CAH,087H,001H,00FH,036H,07EH
;______________________________________________________________________________

%define pgfxll_asm
%include "pgfx.h"

section .data

csym PgfxFlags,	dd .redraw|.cursorSet|.cursorMove ;.FlagsUseMMX|.FlagsSlowPc

section .bss
alignb 16
PgfxMulTbl:	resb 65536				; multiplication look up table

section .text


;//////////////////////////////////////////////////////////////////////////////
; Initializes the bare essentials to prevent crashes, nothing more.
; Further initialization occurs upon request or as needed.
csym PgfxInit

%if PlainUseMMX
	; Check processor MMX support
	; first see if CPUID is supported
	push ebx
	pushfd
	pop eax
	mov ecx,eax						; copy eflags for later comparison
	xor eax, 00200000h				; attempt to toggle ID bit (21)
	push eax
	popfd
	pushfd
	pop eax
	xor eax,ecx						; check changed bits
	test eax, 00200000h
	jz .NoMMX						; CPUID unsupported if unchanged

	; now check MMX capability
	xor eax,eax
	cpuid
	test eax,eax
	jz .NoMMX
	xor eax,eax
	inc eax
	cpuid
	test edx, 00800000h				; check MMX bit (24)
	jz .NoMMX

	or dword [PgfxFlags],PgfxFlags.hasMMX|PgfxFlags.useMMX
.NoMMX:
	pop ebx
%endif

	; always return success for now
	xor eax,eax
	ret


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
%ifdef UseBlitOpaque32i32i
csym BlitOpaque32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
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
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)

.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	;mov eax,[esi]					; grab next source pixel (second ignored)
	;dec ecx
	;add esi,byte 4
	;mov [edi],eax					; write single pixel
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
	movq [edi],mm0					; write both pixels
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movsd                           ; copy single pixel

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040827	created
; Blits right to left instead of the usual left to right which most all
; blitting functions use. Solely used for scrolling right (panning left),
; since BlitOpaque would overwrite the pixels. All other scroll directions
; call BlitOpaque.
;
%ifdef UseBlitOpaqueLeft32i32i ; not sure if I'll really use this one
csym BlitOpaqueLeft32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]
	add ecx,[esp+.destWidth@]		; adjust ptr to right side
	dec ecx							; fix by moving one pixel left
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]
	add ecx,[esp+.destWidth@]		; adjust ptr to right side
	dec ecx
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	std

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	add [.srcWrap],eax
	add [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

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
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	cld
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)

.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	;mov eax,[esi]					; grab next source pixel (second ignored)
	;dec ecx
	;add esi,byte 4
	;mov [edi],eax					; write single pixel
	;add edi,byte 4
	dec ecx
	movsd                           ; copy single pixel
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX

	; remaining 64bit pixels
.ColNextMMX:
	sub esi,byte 8
	sub edi,byte 8
	movq mm0,[esi]					; read next two source pixels
	sub ecx,byte 2					; count-=2 because two pixels at a time
	movq [edi],mm0					; write both pixels
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movsd                           ; copy single pixel

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040801	created
;
%ifdef UseBlitOpaque8i8i
csym BlitOpaque8i8i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	add edx,ecx						; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],edx
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	add edx,ecx						; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

	;cld
.RowNext: ;(edi=dest ptr, esi=src ptr, edx=col count)
	mov edx,dword [.destWidth]

	; first 0-3 pixels to align
.HeadNext:
	test edi,3
	jz .ColAligned
	movsb
	dec edx
	jg .HeadNext
    ; middle pixels, 4 at a time
.ColAligned:
	mov ecx,edx						; copy col count for later
	sar ecx,2						; width / 4 pixels at a time
	jle .Tail
	rep movsd
.Tail:
	; last 0-3 pixels (tail)
	mov ecx,edx
	and ecx,3|(1<<31)				; remaining 0-3 pixels
	jle .RowEnd
	rep movsb

.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)

.RowNextMMX:
	mov ecx,dword [.destWidth]
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
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

unlocals
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
%ifdef UseBlitOpaque32i32c
csym BlitOpaque32i32c
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
params esp+4
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcColor						; color value constant

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push edi

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.destWrap],eax

	mov eax,[.srcColor]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
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
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	ret

%if PlainUseMMX
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
	movq [edi],mm0					; write both pixels
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count, mm0=color constant)
	jl .RowEndMMX					; count negative, so no tail
	stosd

.RowEndMMX:
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd

%endif

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040801	created
;
%ifdef UseBlitOpaque8i8c
csym BlitOpaque8i8c
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
params esp+4
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcColor						; color value constant

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	add edx,ecx						; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push edi

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	sub [.destWrap],eax

	movzx eax,byte [.srcColor]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

	mov ah,al						; XX.. ....	(eax ecx) replicate pixel 4 times
	mov ecx,eax						; XX.. XX..
	shl ecx,16						; XX.. ..XX
	or eax,ecx						; XXXX ..XX

.RowNext: ;(edi=dest ptr, eax=color constant X 4, edx=col count)
	mov ecx,dword [.destWidth]

	; first 0-3 pixels to align
.HeadNext:
	test edi,4
	jz .ColAligned
	stosb
	dec ecx
	jg .HeadNext
    ; middle pixels, 4 at a time
.ColAligned:
	mov edx,ecx						; copy col count for below
	sar ecx,2						; width / 4 pixels at a time
	jle .ColEnd
	rep stosd
.ColEnd:
	; last 0-3 pixels (tail)
	mov ecx,edx
	and ecx,3|(1<<31)				; remaining 0-3 pixels
	jle .RowEnd
	rep stosb

.RowEnd:
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, eax=8bit color constant X 4, edx=col count)
	and eax,255
	movd mm0,eax					; X.......	replicate pixel 8 times
	packuswb mm0,mm0				; X...X...	1 pixel becomes 2
	packuswb mm0,mm0				; X.X.X.X.	2 pixel becomes 4
	packuswb mm0,mm0				; XXXXXXXX	4 pixel becomes 8

.RowNextMMX:
	mov ecx,dword [.destWidth]
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
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; Draws translucently given opacity channel.
; dest = (src * opacity) + (dest * (1-opacity))
;
; Opacity: 0=Transparent 1-254=translucent 255=Opaque
;
; All variations accept both color channel(s) and an opacity channel, either
; as separate images or interleaved channels in a single image.
;
; If possible, preapply the alpha image to the background color or pattern, so
; you can copy the image opaque - which is several times faster. Don't
; precompute it though if you think the image will ever be put before another
; background (looks ugly, like some of the controls in XP when they are layed
; before uncommon background colors).
BlitTrans:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
BlitTransColor:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; Draws translucently given opacity constant.
; dest = (src * opacity_constant) + (dest * (1-opacity_constant))
;
; Opacity: 0=Transparent 1-254=translucent 255=Opaque
;
;BlitTrans32i32i32c:
;	int3 ;not finished!

;BlitTrans32i32i32i:	; combines two images given separate alpha channel
;BlitTrans32i32i32a:	; blends two images given alpha constant


;//////////////////////////////////////////////////////////////////////////////
; 20040828	created
;
%ifdef UseBlitTrans32i32i
csym BlitTrans32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
; There is no MMX version of this routine
; since it's actually more work to look up values
;%if PlainUseMMX
;	test dword [PgfxFlags],PgfxFlags.useMMX
;	jnz .MMX
;%endif
	test dword [PgfxFlags],PgfxFlags.mulInit
	jnz .MulInit
	call PgfxMulTblInit
.MulInit:

	xor edx,edx						; will be used as table index
.RowNext:
	mov ecx,[.destWidth]			; col count = pixel width
.ColNext:
	; separate each chroma and use precomputed look up table (64k)
	; for all multiplications
	mov ebx,[esi]					; get source pixel
	mov eax,[edi]
	shld edx,ebx,16					; get alpha in dh
	mov dl,bl
	sub dl,al						; blue src - dest
	jc .BlueNeg
	add al,[PgfxMulTbl+edx]			; get src*dest from LUT
	jmp short .BlueEnd
.BlueNeg:
	neg dl							; make difference positive
	sub al,[PgfxMulTbl+edx]			; get src*dest from LUT
.BlueEnd:
	mov dl,bh
	sub dl,ah						; green src - dest
	jc .GreenNeg
	add ah,[PgfxMulTbl+edx]			; get src*dest from LUT
	jmp short .GreenEnd
.GreenNeg:
	neg dl							; make difference positive
	sub ah,[PgfxMulTbl+edx]			; get src*dest from LUT
.GreenEnd:
	shr ebx,16
	rol eax,16						; rotate to [RA]BG
	add esi,byte 4
	mov dl,bl
	sub dl,al						; red src - dest
	jc .RedNeg
	add al,[PgfxMulTbl+edx]			; get src*dest from LUT
	jmp short .RedEnd
.RedNeg:
	neg dl							; make difference positive
	sub al,[PgfxMulTbl+edx]			; get src*dest from LUT
.RedEnd:
	xor edx,edx						; zero table index for next loop
	rol eax,16						; restore to BGRA
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret
	
unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040828	created
;
%ifdef UseBlitTrans32i32c
csym BlitTrans32i32c
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcColor						; color value constant

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push ebx
	push edi

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.destWrap],eax

	mov ebx,[.srcColor]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
; There is no MMX version of this routine
; since it's actually more work to look up values
;%if PlainUseMMX
;	test dword [PgfxFlags],PgfxFlags.useMMX
;	jnz .MMX
;%endif
	test dword [PgfxFlags],PgfxFlags.mulInit
	jnz .MulInit
	call PgfxMulTblInit
.MulInit:

	xor edx,edx						; will be used as table index
	shld edx,ebx,16					; get alpha in dh
.RowNext:
	mov ecx,[.destWidth]			; col count = pixel width
.ColNext:
	; separate each chroma and use precomputed look up table (64k)
	; for all multiplications
	mov eax,[edi]
	mov dl,bl
	sub dl,al						; blue src - dest
	jc .BlueNeg
	add al,[PgfxMulTbl+edx]			; get src*dest from LUT
	jmp short .BlueEnd
.BlueNeg:
	neg dl							; make difference positive
	sub al,[PgfxMulTbl+edx]			; get src*dest from LUT
.BlueEnd:
	mov dl,bh
	sub dl,ah						; green src - dest
	jc .GreenNeg
	add ah,[PgfxMulTbl+edx]			; get src*dest from LUT
	jmp short .GreenEnd
.GreenNeg:
	neg dl							; make difference positive
	sub ah,[PgfxMulTbl+edx]			; get src*dest from LUT
.GreenEnd:
	ror ebx,16						; rotate to [RA]BG
	rol eax,16						; rotate to [RA]BG
	mov dl,bl
	sub dl,al						; red src - dest
	jc .RedNeg
	add al,[PgfxMulTbl+edx]			; get src*dest from LUT
	jmp short .RedEnd
.RedNeg:
	neg dl							; make difference positive
	sub al,[PgfxMulTbl+edx]			; get src*dest from LUT
.RedEnd:
	ror ebx,16						; restore to [RA]BG
	rol eax,16						; restore to BGRA
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop ebx
	ret

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040902	created
;
; Fills solid color given opacity channel.
; dest = (color * opacity) + (dest * (1-opacity))
;
; Opacity: 0=Transparent 1-254=translucent 255=Opaque
; This hybrid function could be accomplished calls to other functions.
;
%ifdef UseBlitTrans32i8i32c
csym BlitTrans32i8i32c
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop, .srcColor
params esp+16
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop
param srcColor						; color value constant

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	add edx,ecx						; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx
	push ebp

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],edx
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	mov ebx,[.srcColor]
	;mov edx,[.destWidth]
; There is no MMX version of this routine
; since it's actually more work to look up values
;%if PlainUseMMX
;	test dword [PgfxFlags],PgfxFlags.useMMX
;	jnz .MMX
;%endif
	test dword [PgfxFlags],PgfxFlags.mulInit
	jnz .MulInit
	call PgfxMulTblInit
.MulInit:

	xor ebp,ebp						; will hold copy of alpha value
	xor edx,edx						; will be used as table index
	shld ebp,ebx,16					; get alpha in ah
.RowNext:
	mov ecx,[.destWidth]			; col count = pixel width
	mov eax,ebp						; copy color constant alpha value
.ColNext:
	; separate each chroma and use precomputed look up table (64k)
	; for all multiplications
	mov al,[esi]					; get mask value
	inc esi
	mov dh,[PgfxMulTbl+eax]			; color alpha * mask value
	mov eax,[edi]
	mov dl,bl
	sub dl,al						; blue src - dest
	jc .BlueNeg
	add al,[PgfxMulTbl+edx]			; get src*dest from LUT
	jmp short .BlueEnd
.BlueNeg:
	neg dl							; make difference positive
	sub al,[PgfxMulTbl+edx]			; get src*dest from LUT
.BlueEnd:
	mov dl,bh
	sub dl,ah						; green src - dest
	jc .GreenNeg
	add ah,[PgfxMulTbl+edx]			; get src*dest from LUT
	jmp short .GreenEnd
.GreenNeg:
	neg dl							; make difference positive
	sub ah,[PgfxMulTbl+edx]			; get src*dest from LUT
.GreenEnd:
	ror ebx,16						; rotate to [RA]BG
	rol eax,16						; rotate to [RA]BG
	mov dl,bl
	sub dl,al						; red src - dest
	jc .RedNeg
	add al,[PgfxMulTbl+edx]			; get src*dest from LUT
	jmp short .RedEnd
.RedNeg:
	neg dl							; make difference positive
	sub al,[PgfxMulTbl+edx]			; get src*dest from LUT
.RedEnd:
	cmp ah,dh
	ja .AlphaMore
	mov ah,dh						; HACK: for now, set alpha
.AlphaMore:
	ror ebx,16						; restore to [RA]BG
	rol eax,16						; restore to BGRA
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	mov eax,ebp						; precopy color constant alpha value
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebp
	pop ebx
	pop edi
	pop esi
	ret

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; Draws image with transparent 'keyed' areas (constants are implicit).
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
%ifdef UseBlitTransFast32i32i
csym BlitTransFast32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize

	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

	;cld
	mov edx,[.destHeight]
.RowNext: ;(edi=dest ptr, esi=src ptr, edx=row count)
	mov ecx,[.destWidth]			; col count = pixel width
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
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec edx
	jg .RowNext

.ImageEnd:
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)

.RowNextMMX:
	movq mm3,[.CompMask]			; get comparison mask

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	mov eax,[esi]					; get source pixel
	add esi,byte 4
	dec ecx
	cmp eax,192<<24					; alpha channel in top byte
	jb .HeadTransMMX
	mov [edi],eax					; opaque if >= 192
.HeadTransMMX:
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX

	; remaining 64bit pixels
.ColNextMMX:
	movq mm1,[esi]
	movq mm0,[edi]					; read next two dest pixels
	movq mm2,mm1					; copy src
	psrld mm2,1
	pcmpgtd mm2,mm3					; make pixel mask
	pand mm1,mm2					; src & mask
	pandn mm2,mm0					; !mask & dest
	add esi,byte 8
	por mm1,mm2						; src | dest
	movq [edi],mm1					; write both pixels
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
	jb .TailTransMMX
	mov [edi],eax					; opaque if >= 192
.TailTransMMX:
	add edi,byte 4

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp .ImageEnd

align 8, int3
.CompMask:	db 0FFh,0FFh,0FFh,191>>1, 0FFh,0FFh,0FFh,191>>1
%endif

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040802	created
;
%ifdef UseBlitTransFast8i8i
csym BlitTransFast8i8i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]
	;lea eax,[edx+ecx*1]				; dest offset = top*wrap + left*pixelsize
	add ecx,edx
	add [esp+.destPtr@],ecx
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]
	;lea eax,[edx+ecx*1]				; src offset = top*wrap + left*pixelsize
	add ecx,edx
	add [esp+.srcPtr@],ecx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx
	
	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	;mov edx,eax
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

	mov ebx,[.destHeight]
.RowNext: ;(edi=dest ptr, esi=src ptr, edx=row count)
	mov edx,[.destWidth]			; col count = pixel width
	
	; first 0-3 pixels to align
	mov eax,[esi]					; get 4 source pixels [1234]
.HeadNext:
	test esi,3
	jz .ColAligned
	inc esi
	test al,al
	jz .HeadTrans
	mov [edi],al
.HeadTrans:
	shr eax,8
	inc edi
	dec edx
	jg .HeadNext

    ; middle pixels, 4 at a time
.ColAligned:
	mov ecx,edx
	sar ecx,2						; width / 4 pixels at a time
	jle .Tail

.ColNext:
	mov eax,[esi]					; get 4 source pixels [1234]
	add esi,byte 4
	test al,al						; transparent if == 0
	jz .ColTrans0
	mov [edi],al
.ColTrans0:
	test ah,ah						; transparent if == 0
	jz .ColTrans1
	mov [edi+1],ah
.ColTrans1:
	shr eax,16
	test al, al						; transparent if == 0
	jz .ColTrans2
	mov [edi+2],al
.ColTrans2:
	test ah,ah						; transparent if == 0
	jz .ColTrans3
	mov [edi+3],ah
.ColTrans3:
	add edi,byte 4
	dec ecx
	jg .ColNext

	; last 0-3 pixels
.Tail:
	and edx,(1<<31)|3
	jle .RowEnd
	mov eax,[esi]
.TailNext:
	inc esi
	test al,al
	jz .TailTrans
	mov [edi],al
.TailTrans:
	shr eax,8
	inc edi
	dec edx
	jg .TailNext

.RowEnd:	
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec ebx
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%if PlainUseMMX

; TODO: finish

.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
	;movq mm3,[.CompMask]			; get comparison mask
	xor eax,eax
	movd mm3,eax

.RowNextMMX:
	mov ecx,[.destWidth]			; col count = pixel width

	; first 0-7 pixels (head of row)
.HeadNextMMX:
	test edi,7						; check if aligned yet
	jz .ColAlignedMMX
	mov al,[esi]
	test al,al
	jz .HeadTransMMX
	mov [edi],al
.HeadTransMMX:
	inc edi
	dec ecx							; cols--
	jg .RowEndMMX

.ColAlignedMMX:
	; middle pixels (64 bit destination aligned)
.ColMMX:
	mov edx,ecx						; copy remaining count
	sar edx,3
	jle .TailMMX
.ColNextMMX:
	movq mm2,[esi]					; read 8 source pixels
	movq mm0,[edi]
	movq mm1,mm2					; copy src
	pcmpeqb mm2,mm3					; make pixel mask
	pand mm1,mm2					; src & mask
	pandn mm2,mm0					; !mask & dest
	add esi,byte 8
	por mm1,mm2						; src | dest
	movq [edi],mm0					; write 8 pixels to dest
	add edi,byte 8
	dec edx
	jg .ColNextMMX					; continue while count > 0

    ; last 0-7 pixels (tail of row)
.TailMMX:
	and ecx,7|(1<<31)				; remaining 0-7 pixels
	jle .RowEndMMX
	movq mm2,[esi]					; read 8 source pixels
	movq mm0,[edi]
	movq mm1,mm2					; copy src
	pcmpeqb mm2,mm3					; make pixel mask
	pand mm2,[PgfxConstants.Mask0+ecx*8] ; mask unaffected pixels
	pand mm1,mm2					; src & mask
	pandn mm2,mm0					; !mask & dest
	add esi,ecx
	por mm1,mm2						; src | dest
	movq [edi],mm1					; write both pixels
	add edi,ecx

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp .ImageEnd

%ifndef MmxMasks
%define MmxMasks
section .data
align 8, db 0
PgfxConstants.Mask0: db	0,0,0,0,0,0,0,0
PgfxConstants.Mask1: db	255,0,0,0,0,0,0,0
PgfxConstants.Mask2: db	255,255,0,0,0,0,0,0
PgfxConstants.Mask3: db	255,255,255,0,0,0,0,0
PgfxConstants.Mask4: db	255,255,255,255,0,0,0,0
PgfxConstants.Mask5: db	255,255,255,255,255,0,0,0
PgfxConstants.Mask6: db	255,255,255,255,255,255,0,0
PgfxConstants.Mask7: db	255,255,255,255,255,255,255,0
section .text
%endif

%endif ; MMX

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; Maps an image using palette table, converting formats or convoluting colors.
; dest = palette[src]
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
%ifdef UseBlitAdd32i32i
csym BlitAdd32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
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
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
	;movq mm2,[.RgbMask]
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	movq mm0,[esi]					; grab next source pixel (second ignored)
	dec ecx
	;pand mm0,mm2					; mask off the alpha byte
	paddusb mm0,[edi]				; add BGR pixels
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX:
	movq mm0,[esi]					; read next two pixels
	;pand mm0,mm2					; mask off the alpha byte
	paddusb mm0,[edi]				; add BGR pixels
	add esi,byte 8
	movq [edi],mm0					; write both pixels
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movq mm0,[esi]					; grab next source pixel (second ignored)
	;pand mm0,mm2					; mask off the alpha byte
	paddusb mm0,[edi]				; add BGR pixels
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd

align 8
; This mask clears the top alpha byte so they are not added.
;.RgbMask: dd 00FFFFFFh,00FFFFFFFh
%endif

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040801	created
;
%ifdef UseBlitAdd8i8i
csym BlitAdd8i8i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	add edx,ecx						; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],edx
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	add edx,ecx						; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz near .MMX
%endif

.RowNext: ;(edi=dest ptr, esi=src ptr, edx=col count)
	mov ecx,dword [.destWidth]

	; first 0-3 pixels to align
	mov ebx,[esi]					; get src pixel
.HeadNext:
	test edi,3
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
	sar edx,2						; width / 4 pixels at a time
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
	;rol ebx,16						; restore first&second bytes
	mov [edi],eax
	add esi,byte 4
	add edi,byte 4
	dec edx
	jg .ColNext

	; last 0-3 pixels
.Tail:
	and ecx,3|(1<<31)
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
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)

.RowNextMMX:
	mov edx,dword [.destWidth]
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
; *** there are no jumps :) but more ops :( ***
;	mov bl,[esi]
;	add bl,[edi]					; dest pixel += constant
;	inc esi							; src ptr++
;	salc							; NOTE 'inc' does not affect carry
;	or bl,al						; saturate grey
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
	movq mm0,[esi]					; get 8 pixels
	add esi,byte 8
	paddusb mm0,[edi]				; add monochrome pixels
	movq [edi],mm0					; write 8 pixels
	add edi,byte 8
	dec ecx
	jg .ColNextMMX

    ; last 0-7 pixels (tail of row)
.TailMMX:
	and edx,7|(1<<31)
	jle .RowEndMMX
	movq mm0,[esi]					; get 8 pixels
	pand mm0,[PgfxConstants.Mask0+edx*8] ; mask unaffected pixels
	paddusb mm0,[edi]				; add monochrome pixels
	add esi,edx
	movq [edi],mm0					; write 8 pixels
	add edi,edx

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
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp .ImageEnd

%ifndef MmxMasks
%define MmxMasks
section .data
align 8, db 0
PgfxConstants.Mask0: db	0,0,0,0,0,0,0,0
PgfxConstants.Mask1: db	255,0,0,0,0,0,0,0
PgfxConstants.Mask2: db	255,255,0,0,0,0,0,0
PgfxConstants.Mask3: db	255,255,255,0,0,0,0,0
PgfxConstants.Mask4: db	255,255,255,255,0,0,0,0
PgfxConstants.Mask5: db	255,255,255,255,255,0,0,0
PgfxConstants.Mask6: db	255,255,255,255,255,255,0,0
PgfxConstants.Mask7: db	255,255,255,255,255,255,255,0
section .text
%endif

%endif ; MMX

unlocals
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
%ifdef UseBlitAdd32i32c
csym BlitAdd32i32c
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcColor						; color value constant

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push ebx
	push edi

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.destWrap],eax

	mov ebx,[.srcColor]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

	mov edx,ebx						; copy color value
	shr edx,16						; access red byte
	; (bx=blue & green, dl=red)
.RowNext:
	mov ecx,[.destWidth]			; col count = pixel width
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
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop ebx
	ret

%if PlainUseMMX
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
	movd [edi],mm0					; write single pixel
    movq mm0,mm1					; precopy color constant
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX: ;(mm0&mm1=color constant)
	paddusb mm0,[edi]				; add BGR pixels
	movq [edi],mm0					; write both pixels
	add edi,byte 8
	movq mm0,mm1					; precopy color constant for next loop
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count, mm0&mm1=color constant)
	jl .RowEndMMX					; count negative, so no tail
    ;movq mm0,mm1 (redundant)		; copy color constant
	paddusb mm0,[edi]				; add BGR pixels
	movd [edi],mm0					; write single pixel
	add edi,byte 4

.RowEndMMX:
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040723	created
;
%ifdef UseBlitAdd8i8c
csym BlitAdd8i8c
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcColor						; color value constant

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	add edx,ecx						; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push ebx
	push edi

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	sub [.destWrap],eax

	mov ebx,[.srcColor]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

.RowNext: ;(edi=dest ptr, bl=color, edx=col count)
	mov ecx,edx						; col count = pixel width
	sar ecx,2						; width / 4 pixels at a time
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
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop ebx
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, bl=8bit color constant, edx=col count)
	and ebx,255
	movd mm1,ebx					; X.......	replicate pixel 8 times
	packuswb mm1,mm1				; X...X...	1 pixel becomes 2
	packuswb mm1,mm1				; X.X.X.X.	2 pixel becomes 4
	packuswb mm1,mm1				; XXXXXXXX	4 pixel becomes 8

.RowNextMMX:
	mov edx,dword [.destWidth]
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
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp .ImageEnd

%if 0 ;*** old code ***
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
%endif ;old code

%endif

unlocals
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
%ifdef UseBlitSub32i32i
csym BlitSub32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
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
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
	;movq mm2,[.RgbMask]
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	movq mm0,[edi]
	;pand mm0,mm2					; mask off the alpha byte
	dec ecx
	psubusb mm0,[esi]				; dest -= src
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX:
	movq mm0,[edi]					; read next two source pixels
	;pand mm0,mm2					; mask off the alpha byte
	psubusb mm0,[esi]				; subtract BGR pixels
	add esi,byte 8
	movq [edi],mm0					; write both pixels
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movq mm0,[edi]
	;pand mm0,mm2					; mask off the alpha byte
	psubusb mm0,[esi]				; subtract BGR pixels
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd

;align 8, int3
; This mask clears the top alpha byte so they are not added.
;.RgbMask: dd 00FFFFFFh,00FFFFFFFh
%endif

unlocals
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
; 32bit images have each chroma multiplying including alpha channels
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
; 20040816	created
;
%ifdef UseBlitMul32i32i
csym BlitMul32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
; There is no MMX version of this routine
; since it's actually more work to look up values
;%if PlainUseMMX
;	test dword [PgfxFlags],PgfxFlags.useMMX
;	jnz .MMX
;%endif
	test dword [PgfxFlags],PgfxFlags.mulInit
	jnz .MulInit
	call PgfxMulTblInit
.MulInit:

	xor edx,edx						; will be used as table index
.RowNext:
	mov ecx,[.destWidth]			; col count = pixel width
.ColNext:
	; separate each chroma and use precomputed look up table (64k)
	; for all multiplications
	mov ebx,[esi]					; get source pixel
	mov eax,[edi]

  %if 0
	; Alternate code that may be faster, since it uses fewer byte
	; operations and has fewer dependencies. It does use more
	; instructions though.
	mov edx,eax
	mov ebp,ebx
	and eax,00FF00FFh
	and ebx,00FF00FFh
	xor eax,edx
	xor ebp,ebx
	lea ecx,[eax+edx]
	;lea ecx,[eax+edx]
	and ecx,0FFFFh
	mov al,[PgfxMulTbl+ecx]
	lea ecx,[ebp+ebx]
	shr ecx,8
	and ecx,0FFFFh
	mov ah,[PgfxMulTbl+edx]
  %endif

	mov dh,bl						; blue
	mov dl,al
	mov al,[PgfxMulTbl+edx]			; get src*dest from LUT
	mov dh,bh						; green
	mov dl,ah
	mov ah,[PgfxMulTbl+edx]			; get src*dest from LUT
	shr ebx,16
	rol eax,16						; rotate to [RA]BG
	add esi,byte 4
	mov dh,bl						; blue
	mov dl,al
	mov al,[PgfxMulTbl+edx]			; get src*dest from LUT
	mov dh,bh						; alpha
	mov dl,ah
	mov ah,[PgfxMulTbl+edx]			; get src*dest from LUT
	rol eax,16						; restore to BGRA
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040823	created
;
%ifdef UseBlitMul8i8i
csym BlitMul8i8i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+16
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	;lea eax,[edx+ecx*1]			; dest offset = top*wrap + left*pixelsize
	add ecx,edx
	add [esp+.destPtr@],ecx
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	;lea eax,[edx+ecx*1]			; src offset = top*wrap + left*pixelsize
	add ecx,edx
	add [esp+.srcPtr@],ecx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx
	push ebp

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
; There is no MMX version of this routine
; since it's actually more work to look up values
;%if PlainUseMMX
;	test dword [PgfxFlags],PgfxFlags.useMMX
;	jnz .MMX
;%endif
	test dword [PgfxFlags],PgfxFlags.mulInit
	jnz .MulInit
	call PgfxMulTblInit
.MulInit:

	xor edx,edx						; will be used as table index
.RowNext:
	mov ebp,[.destWidth]			; col count = pixel width
	
	; first 0-3 pixels to align
.HeadNext:
	test edi,3
	jz .ColAligned
	mov dl,[esi]					; get source pixel
	mov dh,[edi]
	inc esi
	mov al,[PgfxMulTbl+edx]			; get src*dest from LUT
	mov [edi],al
	inc edi	
	dec ebp
	jg .HeadNext

	; middle pixels, 4 at a time
.ColAligned:
	mov ecx,ebp						; copy col count for later
	sar ecx,2						; width / 4 pixels at a time
	jle .Tail
	
.ColNext:
	; use precomputed look up table for all multiplications
	mov ebx,[esi]					; get 4 source pixels [1234]
	mov eax,[edi]
	mov dh,bl						; 1rst
	mov dl,al
	mov al,[PgfxMulTbl+edx]			; get src*dest from LUT
	mov dh,bh						; 2nd
	mov dl,ah
	mov ah,[PgfxMulTbl+edx]			; get src*dest from LUT
	shr ebx,16
	rol eax,16						; rotate to [34]12
	add esi,byte 4
	mov dh,bl						; 3rd
	mov dl,al
	mov al,[PgfxMulTbl+edx]			; get src*dest from LUT
	mov dh,bh						; 4rth
	mov dl,ah
	mov ah,[PgfxMulTbl+edx]			; get src*dest from LUT
	rol eax,16						; restore to 1234
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext

.Tail:	
	and ebp,3|(1<<31)				; remaining 0-3 pixels
	jle .RowEnd
.TailNext:
	mov dl,[esi]					; get source pixel
	mov dh,[edi]
	inc esi
	mov al,[PgfxMulTbl+edx]			; get src*dest from LUT
	mov [edi],al
	inc edi	
	dec ebp
	jg .TailNext

.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg near .RowNext

.ImageEnd:
	pop ebp
	pop ebx
	pop edi
	pop esi
	ret

unlocals
%endif


%ifdef UsePgfxMulTblInit
;//////////////////////////////////////////////////////////////////////////////
; Initializes the multiplication table used by BlitMul and BlitTrans
; (a 256x256 matrix holding the products of all byte combinations).
; Rules:
;	A*0 = 0
;	A*255 = A
;	A*B = B*A (have not confirmed this yet)
;	Round any errors down (that don't conflict with the prior rules)
PgfxMulTblInit:
params 0

	push ebx
	push esi
	push edi
	;mov ebx,256<<24
	xor ebx,ebx
	mov edx,256<<16
	mov edi,PgfxMulTbl+65536-4

.NextRow:
	mov ecx,256/4
.NextCol:
	sub ebx,edx
	shld eax,ebx,8					; shift byte product into packed dword
	sub ebx,edx
	shld eax,ebx,8					; shift byte product into packed dword
	sub ebx,edx
	shld eax,ebx,8					; shift byte product into packed dword
	sub ebx,edx
	shld eax,ebx,8					; shift byte product into packed dword
	mov [edi],eax
	;debugwrite "%X",eax
	sub edi,byte 4
	dec ecx
	jg .NextCol

	;mov [edi+4],byte 0				; correct (0*anything) to = 0
	;cmp edi,PgfxMulTbl
	;jae .Ok
	sub edx,1<<16
	cmp edx,65536
	jbe .EndMul
	mov ebx,edx
	;sub ebx,1<<16
	shl ebx,8
	jmp short .NextRow
.EndMul:
	mov ecx,256/4
	std
	xor eax,eax
	rep stosd
	cld							; set back or else USER32.DLL will crash
	
	pop edi
	pop esi
	pop ebx
	or dword [PgfxFlags],PgfxFlags.mulInit
	ret

unlocals
%endif


%if 0
;//////////////////////////////////////////////////////////////////////////////
; ** old version **  rounds values up which is a good thing, but is not
; symmetric. I want AxB == BxA always.
; Initializes the multiplication table.
BlitMulInitOld:
params 0

	push ebx
	push esi
	push edi
	mov ebx,255<<24
	mov edx,(255+1)<<16
	mov edi,PgfxMulTbl+65536-4

.NextRow:	
	mov ecx,256/4
.NextCol:
	shld eax,ebx,8					; shift byte product into packed dword
	sub ebx,edx
	shld eax,ebx,8					; shift byte product into packed dword
	sub ebx,edx
	shld eax,ebx,8					; shift byte product into packed dword
	sub ebx,edx
	shld eax,ebx,8					; shift byte product into packed dword
	sub ebx,edx
	mov [edi],eax
	sub edi,byte 4
	dec ecx
	jg .NextCol

	mov [edi+4],byte 0				; correct (0*anything) to = 0
	cmp edi,PgfxMulTbl
	sub edx,1<<16
	cmp edx,65536
	jbe .EndMul
	mov ebx,edx
	;sub ebx,1<<16
	shl ebx,8
	jmp short .NextRow
.EndMul:
	mov ecx,256/4
	std
	xor eax,eax
	rep stosd
	cld							; set back or else USER32.DLL will crash
	
	pop edi
	pop esi
	pop ebx
	or dword [PgfxFlags],PgfxFlags.mulInit
	ret

unlocals
%endif ;old code

	
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
; 20040816	created
;
%ifdef UseBlitAnd32i32i
csym BlitAnd32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

.RowNext:
	mov ecx,edx ;[.destWidth]		; col count = pixel width
.ColNext:
	; separate each chroma and use precomputed look up table (64k)
	; for all multiplications
	mov eax,[esi]					; get source pixel
	add esi,byte 4
	and [edi],eax					; dest &= source
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	movq mm0,[edi]
	dec ecx
	pand mm0,[esi]					; dest &= src
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX:
	movq mm0,[edi]					; read next two source pixels
	pand mm0,[esi]					; dest &= src
	add esi,byte 8
	movq [edi],mm0					; write both pixels
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movq mm0,[edi]
	pand mm0,[esi]					; dest &= src
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; Ors destination with source.
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
; 20040828	created
;
%ifdef UseBlitOr32i32i
csym BlitOr32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

.RowNext:
	mov ecx,edx ;[.destWidth]		; col count = pixel width
.ColNext:
	; separate each chroma and use precomputed look up table (64k)
	; for all multiplications
	mov eax,[esi]					; get source pixel
	add esi,byte 4
	or [edi],eax					; dest &= source
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	movq mm0,[edi]
	dec ecx
	por mm0,[esi]					; dest &= src
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX:
	movq mm0,[edi]					; read next two source pixels
	por mm0,[esi]					; dest &= src
	add esi,byte 8
	movq [edi],mm0					; write both pixels
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movq mm0,[edi]
	por mm0,[esi]					; dest &= src
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040828	created
;
%if 0;def UseBlitAndOr32i32c32c
csym BlitAndOr32i32c32c
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcAnd, .srcOr
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcAnd
param srcOr

	int3 ; !!untested
	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	;mov edx,eax
	shl eax,2
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

	xor edx,edx						; will be used as table index
.RowNext:
	mov ecx,[.destWidth]			; col count = pixel width
.ColNext:
	; separate each chroma and use precomputed look up table (64k)
	; for all multiplications
	mov eax,[edi]					; get source pixel
	and eax,ebx						; dest &= source
	or eax,edx						; dest |= source
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	movq mm0,[edi]
	dec ecx
	por mm0,[esi]					; dest &= src
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4
.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX:
	movq mm0,[edi]					; read next two source pixels
	por mm0,[esi]					; dest &= src
	add esi,byte 8
	movq [edi],mm0					; write both pixels
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movq mm0,[edi]
	por mm0,[esi]					; dest &= src
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp short .ImageEnd
%endif

unlocals
%endif


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
; 20040925	created
;
%ifdef UseBlitGreater32i32i
csym BlitGreater32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

.RowNext:
	mov ecx,edx						; col count = pixel width
.ColNext:
	mov eax,[esi]					; get source pixel
	mov ebx,[edi]
	cmp al,bl
	jae .BlueOk
	mov al,bl						; pick dest blue
.BlueOk:
	cmp ah,bh
	jae .GreenOk
	mov ah,bh						; pick dest green
.GreenOk:
	ror eax,16						; access third bytes (red) RABG
	shr ebx,16
	cmp al,bl
	jae .RedOk
	mov al,bl						; pick dest red
.RedOk:
	cmp ah,bh
	jae .AlphaOk
	mov ah,bh						; pick dest alpha
.AlphaOk:

	rol eax,16						; restore to BGRA
	add esi,byte 4
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
	movq mm3,[PgfxConstants.MmxMidPoint]
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	movq mm1,[esi]					; read next src pixel  (second ignored)
	dec ecx
	movq mm0,[edi]					; read next dest pixel (second ignored)
	movq mm2,mm0					; copy dest
	psubb mm1,mm3					; sign pixels
	psubb mm2,mm3					; sign pixels
	pcmpgtb mm2,mm1					; make pixel mask
	paddb mm1,mm3					; unsign pixels
	pand mm0,mm2					; dest & mask
	pandn mm2,mm1					; !mask & src
	por mm0,mm2						; src | dest
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4

.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX:
	movq mm1,[esi]					; read next two src pixels
	movq mm0,[edi]					; read next two dest pixels
	movq mm2,mm0					; copy dest
	psubb mm1,mm3					; sign pixels
	psubb mm2,mm3					; sign pixels
	pcmpgtb mm2,mm1					; make pixel mask
	paddb mm1,mm3					; unsign pixels
	pand mm0,mm2					; dest & mask
	pandn mm2,mm1					; !mask & src
	por mm0,mm2						; src | dest
	add esi,byte 8
	movq [edi],mm0					; write both pixels
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movq mm1,[esi]					; read next src pixel  (second ignored)
	movq mm0,[edi]					; read next dest pixel (second ignored)
	movq mm2,mm0					; copy dest
	psubb mm1,mm3					; sign pixels
	psubb mm2,mm3					; sign pixels
	pcmpgtb mm2,mm1					; make pixel mask
	paddb mm1,mm3					; unsign pixels
	pand mm0,mm2					; dest & mask
	pandn mm2,mm1					; !mask & src
	por mm0,mm2						; src | dest
	add esi,byte 4
	movd [edi],mm0					; write single pixel
	add edi,byte 4

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp .ImageEnd

%ifndef MmxMidPoint
%define MmxMidPoint
section .data
align 8, db 0
PgfxConstants.MmxMidPoint: db 128,128,128,128, 128,128,128,128
section .text
%endif

%endif ; MMX

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040926	created
;
%ifdef UseBlitGreater8i8i
csym BlitGreater8i8i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	add edx,ecx						; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],edx
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	add edx,ecx						; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz near .MMX
%endif

.RowNext: ;(edi=dest ptr, esi=src ptr, edx=col count)
	mov ecx,dword [.destWidth]

	; first 0-3 pixels to align
	mov eax,[esi]					; get src pixels
	mov ebx,[edi]					; get dest pixels
.HeadNext:
	test edi,3
	jz .ColAligned
	cmp al,bl
	jb .HeadOk
	mov [edi],al					; dest = src
.HeadOk:
	shr eax,8						; next dest pixel
	inc esi
	shr ebx,8						; next src pixel
	inc edi
	dec ecx
	jg .HeadNext

    ; middle pixels, 4 at a time
.ColAligned:
	mov edx,ecx
	sar edx,2						; width / 4 pixels at a time
	jle .Tail

.ColNext:
	mov eax,[esi]					; get src pixels
	mov ebx,[edi]					; get dest pixels
	cmp al,bl
	ja .Ok1
	mov al,bl						; pixel 1: dest = src
.Ok1:
	cmp ah,bh
	ja .Ok2
	mov ah,bh						; pixel 2: dest = src
.Ok2:
	ror ebx,16						; access third&fourth bytes
	ror eax,16						; access third&fourth bytes
	cmp al,bl
	ja .Ok3
	mov al,bl						; pixel 3: dest = src
.Ok3:
	cmp ah,bh
	ja .Ok4
	mov ah,bh						; pixel 4: dest = src
.Ok4:
	rol eax,16						; restore first&second bytes
	;rol ebx,16						; restore first&second bytes
	add esi,byte 4
	mov [edi],eax
	add edi,byte 4
	dec edx
	jg .ColNext

	; last 0-3 pixels
.Tail:
	and ecx,3|(1<<31)
	jle .RowEnd
	mov eax,[esi]					; get src pixels
	mov ebx,[edi]					; get dest pixels
	add esi,ecx
.TailNext:
	cmp al,bl
	jb .TailOk
	mov [edi],al					; dest = src
.TailOk:
	shr eax,8						; next dest pixel
	inc edi
	shr ebx,8						; next src pixel
	dec ecx
	jg .TailNext

.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
	movq mm3,[PgfxConstants.MmxMidPoint]

.RowNextMMX:
	mov edx,dword [.destWidth]
	cmp edx,15						; don't bother with mem alignment
	jle .ColMMX						; if image to small to make difference

	; first 0-7 pixels (head of row)
	jmp short .HeadMMX
.HeadNextMMX:
	mov al,[esi]					; get src pixel
	inc esi							; src ptr++
	cmp [edi],al
	jae .HeadOkMMX
	mov [edi],al					; dest = src
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
	sar ecx,3						; count / 8 pixels at a time
	jle .TailMMX
.ColNextMMX:
	movq mm1,[esi]					; read 8 src pixels
	movq mm0,[edi]					; read 8 dest pixels
	movq mm2,mm1					; copy src
	movq mm4,mm0					; copy dest
	psubb mm2,mm3					; sign pixels
	psubb mm4,mm3					; sign pixels
	pcmpgtb mm2,mm4					; make pixel mask
	pand mm1,mm2					; src & mask
	pandn mm2,mm0					; !mask & dest
	por mm1,mm2						; src | dest
	add esi,byte 8
	movq [edi],mm1					; write 8 pixels
	add edi,byte 8
	dec ecx
	jg .ColNextMMX

    ; last 0-7 pixels (tail of row)
.TailMMX:
	and edx,7|(1<<31)
	jle .RowEndMMX
	movq mm1,[esi]					; read 8 src pixels
	movq mm0,[edi]					; read 8 dest pixels
	movq mm2,mm1					; copy src
	movq mm4,mm0					; copy dest
	psubb mm2,mm3					; sign pixels
	psubb mm4,mm3					; sign pixels
	pcmpgtb mm2,mm4					; make pixel mask
	pand mm2,[PgfxConstants.Mask0+edx*8] ; mask unaffected pixels
	pand mm1,mm2					; src & mask
	pandn mm2,mm0					; !mask & dest
	por mm1,mm2						; src | dest
	add esi,edx
	movq [edi],mm1					; write 8 pixels
	add edi,edx

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp .ImageEnd

%ifndef MmxMidPoint
%define MmxMidPoint
section .data
align 8, db 0
PgfxConstants.MmxMidPoint: db 128,128,128,128, 128,128,128,128
section .text
%endif

%ifndef MmxMasks
%define MmxMasks
section .data
align 8, db 0
PgfxConstants.Mask0: db	0,0,0,0,0,0,0,0
PgfxConstants.Mask1: db	255,0,0,0,0,0,0,0
PgfxConstants.Mask2: db	255,255,0,0,0,0,0,0
PgfxConstants.Mask3: db	255,255,255,0,0,0,0,0
PgfxConstants.Mask4: db	255,255,255,255,0,0,0,0
PgfxConstants.Mask5: db	255,255,255,255,255,0,0,0
PgfxConstants.Mask6: db	255,255,255,255,255,255,0,0
PgfxConstants.Mask7: db	255,255,255,255,255,255,255,0
section .text
%endif

%endif ; MMX

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040926	created
;
%ifdef UseBlitGreater8i8c
csym BlitGreater8i8c
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcColor						; color value constant

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	add edx,ecx						; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	sub [.destWrap],eax

	mov ebx,[.srcColor]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz near .MMX
%endif

.RowNext: ;(edi=dest ptr, bl=color, edx=col count)
	mov ecx,dword [.destWidth]

	; first 0-3 pixels to align
	mov eax,[edi]					; get dest pixels
.HeadNext:
	test edi,3
	jz .ColAligned
	cmp al,bl
	ja .HeadOk
	mov [edi],bl					; dest = constant
.HeadOk:
	shr eax,8						; next dest pixel
	inc edi
	dec ecx
	jg .HeadNext

    ; middle pixels, 4 at a time
.ColAligned:
	mov edx,ecx
	sar edx,2						; width / 4 pixels at a time
	jle .Tail

.ColNext:
	mov eax,[edi]					; get dest pixels
	cmp al,bl
	ja .Ok1
	mov al,bl						; pixel 1: dest = constant
.Ok1:
	cmp ah,bl
	ja .Ok2
	mov ah,bl						; pixel 2: dest = constant
.Ok2:
	ror eax,16						; access third&fourth bytes
	cmp al,bl
	ja .Ok3
	mov al,bl						; pixel 3: dest = constant
.Ok3:
	cmp ah,bl
	ja .Ok4
	mov ah,bl						; pixel 4: dest = constant
.Ok4:
	rol eax,16						; restore first&second bytes
	mov [edi],eax
	add edi,byte 4
	dec edx
	jg .ColNext

	; last 0-3 pixels
.Tail:
	and ecx,3|(1<<31)
	jle .RowEnd
	mov eax,[edi]					; get dest pixels
.TailNext:
	cmp al,bl
	ja .TailOk
	mov [edi],bl					; dest = constant
.TailOk:
	shr eax,8						; next dest pixel
	inc edi
	dec ecx
	jg .TailNext

.RowEnd:
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	ret

%if PlainUseMMX

%define mmDest mm0
%define mmSrc mm1
%define mmDestS mm2
%define mmMask mm2
%define mmSrcS mm3
%define mmBaseS mm4

.MMX: ;(edi=dest ptr, bl=8bit color constant, edx=col count)
	and ebx,255
	movq mmBaseS,[PgfxConstants.MmxMidPoint]
	movd mmSrcS,ebx				; X.......	replicate pixel 8 times
	packuswb mmSrcS,mmSrcS		; X...X...	1 pixel becomes 2
	packuswb mmSrcS,mmSrcS		; X.X.X.X.	2 pixel becomes 4
	packuswb mmSrcS,mmSrcS		; XXXXXXXX	4 pixel becomes 8
	movq mmSrc,mmSrcS			; copy constant
	psubb mmSrcS,mmBaseS		; sign pixels

.RowNextMMX:
	mov edx,dword [.destWidth]
	cmp edx,15						; don't bother with mem alignment
	jle .ColMMX						; if image to small to make difference

	; first 0-7 pixels (head of row)
	jmp short .HeadMMX
.HeadNextMMX:
	cmp [edi],bl
	jae .HeadOkMMX
	mov [edi],bl					; dest = src
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
	sar ecx,3						; count / 8 pixels at a time
	jle .TailMMX
.ColNextMMX:
	movq mmDest,[edi]				; read 8 dest pixels
	movq mmDestS,mmDest
	psubb mmDestS,mmBaseS			; sign dest
	pcmpgtb mmDestS,mmSrcS			; make pixel mask
	pand mmDest,mmMask
	pandn mmMask,mmSrc
	por mmDest,mmMask
	movq [edi],mmDest
	add edi,byte 8
	dec ecx
	jg .ColNextMMX

    ; last 0-7 pixels (tail of row)
.TailMMX:
	and edx,7|(1<<31)
	jle .RowEndMMX
	movq mmDest,[edi]				; read 8 dest pixels
	movq mmDestS,mmDest
	psubb mmDestS,mmBaseS			; sign dest
	pcmpgtb mmDestS,mmSrcS			; make pixel mask
	por mmMask,[PgfxConstants.MaskI0+edx*8] ; mask unaffected pixels
	pand mmDest,mmMask
	pandn mmMask,mmSrc
	por mmDest,mmMask
	movq [edi],mmDest
	add edi,edx
.RowEndMMX:
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp .ImageEnd

%ifndef MmxMidPoint
%define MmxMidPoint
section .data
align 8, db 0
PgfxConstants.MmxMidPoint: db 128,128,128,128, 128,128,128,128
section .text
%endif

%ifndef MmxMasksI
%define MmxMasksI ; inverted masks
section .data
align 8, db 0
PgfxConstants.MaskI0: db	255,255,255,255,255,255,255,255
PgfxConstants.MaskI1: db	0,255,255,255,255,255,255,255
PgfxConstants.MaskI2: db	0,0,255,255,255,255,255,255
PgfxConstants.MaskI255: db	0,0,0,255,255,255,255,255
PgfxConstants.MaskI4: db	0,0,0,0,255,255,255,255
PgfxConstants.MaskI5: db	0,0,0,0,0,255,255,255
PgfxConstants.MaskI6: db	0,0,0,0,0,0,255,255
PgfxConstants.MaskI7: db	0,0,0,0,0,0,0,255
section .text
%endif

%endif ; MMX

unlocals
%endif


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


;//////////////////////////////////////////////////////////////////////////////
; 20040925	created
;
%ifdef UseBlitLesser32i32i
csym BlitLesser32i32i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz .MMX
%endif

.RowNext:
	mov ecx,edx						; col count = pixel width
.ColNext:
	mov eax,[esi]					; get source pixel
	mov ebx,[edi]
	cmp al,bl
	jbe .BlueOk
	mov al,bl						; pick dest blue
.BlueOk:
	cmp ah,bh
	jbe .GreenOk
	mov ah,bh						; pick dest green
.GreenOk:
	ror eax,16						; access third bytes (red) RABG
	shr ebx,16
	cmp al,bl
	jbe .RedOk
	mov al,bl						; pick dest red
.RedOk:
	cmp ah,bh
	jbe .AlphaOk
	mov ah,bh						; pick dest alpha
.AlphaOk:

	rol eax,16						; restore to BGRA
	add esi,byte 4
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
	movq mm3,[PgfxConstants.MmxMidPoint]
.RowNextMMX:

	; first 32bit pixel (if destination misaligned)
	test edi,4						; check if even/odd dword
	mov ecx,edx						; col count = pixel width
	jz .HeadEndMMX					; already 8-byte aligned
	movq mm1,[esi]					; read next src pixel  (second ignored)
	dec ecx
	movq mm0,[edi]					; read next dest pixel (second ignored)
	movq mm2,mm0					; copy dest
	psubb mm1,mm3					; sign pixels
	psubb mm2,mm3					; sign pixels
	pcmpgtb mm2,mm1					; make pixel mask
	paddb mm1,mm3					; unsign pixels
	pand mm1,mm2					; src & mask
	pandn mm2,mm0					; !mask & dest
	por mm1,mm2						; src | dest
	add esi,byte 4
	movd [edi],mm1					; write single pixel
	add edi,byte 4

.HeadEndMMX:
	dec ecx							; predecrement to simplify later logic
	jle .TailMMX					; <-this is NOT a loop

	; remaining 64bit pixels
.ColNextMMX:
	movq mm1,[esi]					; read next two src pixels
	movq mm0,[edi]					; read next two dest pixels
	movq mm2,mm0					; copy dest
	psubb mm1,mm3					; sign pixels
	psubb mm2,mm3					; sign pixels
	pcmpgtb mm2,mm1					; make pixel mask
	paddb mm1,mm3					; unsign pixels
	pand mm1,mm2					; src & mask
	pandn mm2,mm0					; !mask & dest
	por mm1,mm2						; src | dest
	add esi,byte 8
	movq [edi],mm1					; write both pixels
	add edi,byte 8
	sub ecx,byte 2					; count-=2 because two pixels at a time
	jg .ColNextMMX					; continue while count > 0

	; last 32bit pixel (for odd widths)
.TailMMX: ;(flags=comp with col count)
	jl .RowEndMMX					; count negative, so no tail
	movq mm1,[esi]					; read next src pixel  (second ignored)
	movq mm0,[edi]					; read next dest pixel (second ignored)
	movq mm2,mm0					; copy dest
	psubb mm1,mm3					; sign pixels
	psubb mm2,mm3					; sign pixels
	pcmpgtb mm2,mm1					; make pixel mask
	paddb mm1,mm3					; unsign pixels
	pand mm1,mm2					; src & mask
	pandn mm2,mm0					; !mask & dest
	por mm1,mm2						; src | dest
	add esi,byte 4
	movd [edi],mm1					; write single pixel
	add edi,byte 4

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp .ImageEnd

%ifndef MmxMidPoint
%define MmxMidPoint
align 8
PgfxConstants.MmxMidPoint: db 128,128,128,128, 128,128,128,128
%endif

%endif ; MMX

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040926	created
;
%ifdef UseBlitLesser8i8i
csym BlitLesser8i8i
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	add edx,ecx						; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],edx
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	add edx,ecx						; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	sub [.srcWrap],eax
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz near .MMX
%endif

.RowNext: ;(edi=dest ptr, esi=src ptr, edx=col count)
	mov ecx,dword [.destWidth]

	; first 0-3 pixels to align
	mov eax,[esi]					; get src pixels
	mov ebx,[edi]					; get dest pixels
.HeadNext:
	test edi,3
	jz .ColAligned
	cmp al,bl
	ja .HeadOk
	mov [edi],al					; dest = src
.HeadOk:
	shr eax,8						; next dest pixel
	inc esi
	shr ebx,8						; next src pixel
	inc edi
	dec ecx
	jg .HeadNext

    ; middle pixels, 4 at a time
.ColAligned:
	mov edx,ecx
	sar edx,2						; width / 4 pixels at a time
	jle .Tail

.ColNext:
	mov eax,[esi]					; get src pixels
	mov ebx,[edi]					; get dest pixels
	cmp al,bl
	jb .Ok1
	mov al,bl						; pixel 1: dest = src
.Ok1:
	cmp ah,bh
	jb .Ok2
	mov ah,bh						; pixel 2: dest = src
.Ok2:
	ror ebx,16						; access third&fourth bytes
	ror eax,16						; access third&fourth bytes
	cmp al,bl
	jb .Ok3
	mov al,bl						; pixel 3: dest = src
.Ok3:
	cmp ah,bh
	jb .Ok4
	mov ah,bh						; pixel 4: dest = src
.Ok4:
	rol eax,16						; restore first&second bytes
	;rol ebx,16						; restore first&second bytes
	add esi,byte 4
	mov [edi],eax
	add edi,byte 4
	dec edx
	jg .ColNext

	; last 0-3 pixels
.Tail:
	and ecx,3|(1<<31)
	jle .RowEnd
	mov eax,[esi]					; get src pixels
	mov ebx,[edi]					; get dest pixels
	add esi,ecx
.TailNext:
	cmp al,bl
	ja .TailOk
	mov [edi],al					; dest = src
.TailOk:
	shr eax,8						; next dest pixel
	inc edi
	shr ebx,8						; next src pixel
	dec ecx
	jg .TailNext

.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

%if PlainUseMMX
.MMX: ;(edi=dest ptr, esi=src ptr, edx=col count)
	movq mm3,[PgfxConstants.MmxMidPoint]

.RowNextMMX:
	mov edx,dword [.destWidth]
	cmp edx,15						; don't bother with mem alignment
	jle .ColMMX						; if image to small to make difference

	; first 0-7 pixels (head of row)
	jmp short .HeadMMX
.HeadNextMMX:
	mov al,[esi]					; get src pixel
	inc esi							; src ptr++
	cmp [edi],al
	jbe .HeadOkMMX
	mov [edi],al					; dest = src
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
	sar ecx,3						; count / 8 pixels at a time
	jle .TailMMX
.ColNextMMX:
	movq mm1,[esi]					; read 8 src pixels
	movq mm0,[edi]					; read 8 dest pixels
	movq mm2,mm1					; copy src
	movq mm4,mm0					; copy dest
	psubb mm2,mm3					; sign pixels
	psubb mm4,mm3					; sign pixels
	pcmpgtb mm2,mm4					; make pixel mask
	pand mm0,mm2					; dest & mask
	pandn mm2,mm1					; !mask & src
	por mm0,mm2						; src | dest
	add esi,byte 8
	movq [edi],mm0					; write 8 pixels
	add edi,byte 8
	dec ecx
	jg .ColNextMMX

    ; last 0-7 pixels (tail of row)
.TailMMX:
	and edx,7|(1<<31)
	jle .RowEndMMX
	movq mm1,[esi]					; read 8 src pixels
	movq mm0,[edi]					; read 8 dest pixels
	movq mm4,mm1					; copy src
	movq mm2,mm0					; copy dest
	psubb mm4,mm3					; sign pixels
	psubb mm2,mm3					; sign pixels
	pcmpgtb mm2,mm4					; make pixel mask
	pand mm2,[PgfxConstants.Mask0+edx*8] ; mask unaffected pixels
	pand mm1,mm2					; src & mask
	pandn mm2,mm0					; !mask & dest
	por mm1,mm2						; src | dest
	add esi,edx
	movq [edi],mm1					; write 8 pixels
	add edi,edx

.RowEndMMX:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp .ImageEnd

%ifndef MmxMidPoint
%define MmxMidPoint
section .data
align 8, db 0
PgfxConstants.MmxMidPoint: db 128,128,128,128, 128,128,128,128
section .text
%endif

%ifndef MmxMasks
%define MmxMasks
section .data
align 8, db 0
PgfxConstants.Mask0: db	0,0,0,0,0,0,0,0
PgfxConstants.Mask1: db	255,0,0,0,0,0,0,0
PgfxConstants.Mask2: db	255,255,0,0,0,0,0,0
PgfxConstants.Mask3: db	255,255,255,0,0,0,0,0
PgfxConstants.Mask4: db	255,255,255,255,0,0,0,0
PgfxConstants.Mask5: db	255,255,255,255,255,0,0,0
PgfxConstants.Mask6: db	255,255,255,255,255,255,0,0
PgfxConstants.Mask7: db	255,255,255,255,255,255,255,0
section .text
%endif

%endif ; MMX

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040926	created
;
%ifdef UseBlitLesser8i8c
csym BlitLesser8i8c
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight, .srcColor
params esp+8
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcColor						; color value constant

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	add edx,ecx						; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	sub [.destWrap],eax

	mov ebx,[.srcColor]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
%if PlainUseMMX
	test dword [PgfxFlags],PgfxFlags.useMMX
	jnz near .MMX
%endif

.RowNext: ;(edi=dest ptr, bl=color, edx=col count)
	mov ecx,dword [.destWidth]

	; first 0-3 pixels to align
	mov eax,[edi]					; get dest pixels
.HeadNext:
	test edi,3
	jz .ColAligned
	cmp al,bl
	jb .HeadOk
	mov [edi],bl					; dest = constant
.HeadOk:
	shr eax,8						; next dest pixel
	inc edi
	dec ecx
	jg .HeadNext

    ; middle pixels, 4 at a time
.ColAligned:
	mov edx,ecx
	sar edx,2						; width / 4 pixels at a time
	jle .Tail

.ColNext:
	mov eax,[edi]					; get dest pixels
	cmp al,bl
	jb .Ok1
	mov al,bl						; pixel 1: dest = constant
.Ok1:
	cmp ah,bl
	jb .Ok2
	mov ah,bl						; pixel 2: dest = constant
.Ok2:
	ror eax,16						; access third&fourth bytes
	cmp al,bl
	jb .Ok3
	mov al,bl						; pixel 3: dest = constant
.Ok3:
	cmp ah,bl
	jb .Ok4
	mov ah,bl						; pixel 4: dest = constant
.Ok4:
	rol eax,16						; restore first&second bytes
	mov [edi],eax
	add edi,byte 4
	dec edx
	jg .ColNext

	; last 0-3 pixels
.Tail:
	and ecx,3|(1<<31)
	jle .RowEnd
	mov eax,[edi]					; get dest pixels
.TailNext:
	cmp al,bl
	jb .TailOk
	mov [edi],bl					; dest = constant
.TailOk:
	shr eax,8						; next dest pixel
	inc edi
	dec ecx
	jg .TailNext

.RowEnd:
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	ret

%if PlainUseMMX

%define mmDest mm0
%define mmSrc mm1
%define mmDestS mm2
%define mmSrcS mm3
%define mmBaseS mm4
%define mmSrcS2 mm5
%define mmMask mm5

.MMX: ;(edi=dest ptr, bl=8bit color constant, edx=col count)
	and ebx,255
	movq mmBaseS,[PgfxConstants.MmxMidPoint]
	movd mmSrcS,ebx				; X.......	replicate pixel 8 times
	packuswb mmSrcS,mmSrcS		; X...X...	1 pixel becomes 2
	packuswb mmSrcS,mmSrcS		; X.X.X.X.	2 pixel becomes 4
	packuswb mmSrcS,mmSrcS		; XXXXXXXX	4 pixel becomes 8
	movq mmSrc,mmSrcS			; copy constant
	psubb mmSrcS,mmBaseS		; sign pixels

.RowNextMMX:
	mov edx,dword [.destWidth]
	cmp edx,15						; don't bother with mem alignment
	jle .ColMMX						; if image to small to make difference

	; first 0-7 pixels (head of row)
	jmp short .HeadMMX
.HeadNextMMX:
	cmp [edi],bl
	jbe .HeadOkMMX
	mov [edi],bl					; dest = src
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
	sar ecx,3						; count / 8 pixels at a time
	jle .TailMMX
.ColNextMMX:
	movq mmDest,[edi]				; read 8 dest pixels
	movq mmSrcS2,mmSrcS
	movq mmDestS,mmDest
	psubb mmDestS,mmBaseS			; sign dest
	pcmpgtb mmSrcS2,mmDestS			; make pixel mask
	pand mmDest,mmMask
	pandn mmMask,mmSrc
	por mmDest,mmMask
	movq [edi],mmDest
	add edi,byte 8
	dec ecx
	jg .ColNextMMX

    ; last 0-7 pixels (tail of row)
.TailMMX:
	and edx,7|(1<<31)
	jle .RowEndMMX
	movq mmDest,[edi]				; read 8 dest pixels
	movq mmSrcS2,mmSrcS
	movq mmDestS,mmDest
	psubb mmDestS,mmBaseS			; sign dest
	pcmpgtb mmSrcS2,mmDestS			; make pixel mask
	por mmMask,[PgfxConstants.MaskI0+edx*8] ; mask unaffected pixels
	pand mmDest,mmMask
	pandn mmMask,mmSrc
	por mmDest,mmMask
	movq [edi],mmDest
	add edi,edx
.RowEndMMX:
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNextMMX

	emms
	jmp .ImageEnd

%ifndef MmxMidPoint
%define MmxMidPoint
section .data
align 8, db 0
PgfxConstants.MmxMidPoint: db 128,128,128,128, 128,128,128,128
section .text
%endif

%ifndef MmxMasksI
%define MmxMasksI ; inverted masks
section .data
align 8, db 0
PgfxConstants.MaskI0: db	255,255,255,255,255,255,255,255
PgfxConstants.MaskI1: db	0,255,255,255,255,255,255,255
PgfxConstants.MaskI2: db	0,0,255,255,255,255,255,255
PgfxConstants.MaskI3: db	0,0,0,255,255,255,255,255
PgfxConstants.MaskI4: db	0,0,0,0,255,255,255,255
PgfxConstants.MaskI5: db	0,0,0,0,0,255,255,255
PgfxConstants.MaskI6: db	0,0,0,0,0,0,255,255
PgfxConstants.MaskI7: db	0,0,0,0,0,0,0,255
section .text
%endif

%endif ; MMX

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040822	created
; Convert 8bit to 32bit using palette.
;
%ifdef UseBlitPal32i8i32p
csym BlitPal32i8i32p
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop, .palPtr
params esp+12
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop
param palPtr						; palette (32bit BGRA array) pointer

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],eax
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	add edx,ecx
	;lea edx,[edx+ecx*1]			; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],edx

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2						; width * 4 bytes per pixel
	sub [.srcWrap],edx				; source wrap -= width
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	mov ebx,[.palPtr]
	;mov edx,[.destWidth]
; There is no MMX version of this routine
; since it's actually more work to look up values
;%if PlainUseMMX
;	test dword [PgfxFlags],PgfxFlags.useMMX
;	jnz .MMX
;%endif

	xor edx,edx						; will be used as table index
.RowNext:
	mov ecx,[.destWidth]			; col count = pixel width
.ColNext:
	; map each 8bit pixel to a 32bit pixel using palette
	mov dl,[esi]					; get source pixel
	inc esi
	mov eax,[ebx+edx*4]				; read 32bit pixel from palette
	mov [edi],eax
	add edi,byte 4
.ColEnd:
	dec ecx
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebx
	pop edi
	pop esi
	ret

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20040822	created
; Reduces 32bit to 8bit using a map. Note this reduction function does NOT do
; a palette lookup. The interpretation of the palette is that entry maps to
; a byte value for that color.
;
; byte = pal[B] + pal[G] + pal[R] + pal[A]

%ifdef UseBlitPal8i32i32p
csym BlitPal8i32i32p
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop, .palPtr
params esp+16
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop
param palPtr						; palette (32bit BGRA array) pointer

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	add ecx,edx
	;lea eax,[edx+ecx*1]			; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],ecx
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx
	push ebp

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2						; width * 4 bytes per pixel
	sub [.srcWrap],eax				; source wrap -= width
	sub [.destWrap],edx

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	mov ebx,[.palPtr]
	;mov edx,[.destWidth]
; There is no MMX version of this routine
; since it's actually more work to look up values
;%if PlainUseMMX
;	test dword [PgfxFlags],PgfxFlags.useMMX
;	jnz .MMX
;%endif

	xor edx,edx						; will be used as table index
.RowNext:
	mov ebp,[.destWidth]			; col count = pixel width
.ColNext:
	; Map each 32bit pixel to a 8bit pixel using palette.
	; Only works with palettes of fixed allocations
	; so the components can simply be added together, like
	; 256-color monochrome, 216-color web, or 3:3:2 palette.
	mov eax,[esi]					; get source pixel
	xor ecx,ecx
	add esi,byte 4
	mov dl,al
	mov cl,[ebx+edx*4+0]			; blue
	mov dl,ah
	shr eax,16
	add cl,[ebx+edx*4+1]			; green
	mov dl,al
	add cl,[ebx+edx*4+2]			; red
	mov dl,ah
	add cl,[ebx+edx*4+3]			; alpha (can set all zero if ignorable)
	mov [edi],cl
	inc edi
.ColEnd:
	dec ebp
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebp
	pop ebx
	pop edi
	pop esi
	ret

unlocals
%endif



;//////////////////////////////////////////////////////////////////////////////
; 20050404	created
; Maps 32bit to 32bit using chroma map. The unusual palette passed to this
; function has 1024 entries, consisting of four palettes concatenated, one
; for each chroma.
;
; dword = pal[B] + pal[G] + pal[R] + pal[A]
;
; Potential uses include:
; -convoluting colors
; -determining distance (R^2+G^2+B^2)
; -converting to high precision monochrome (.30R+.59G+.11B)
;
%ifdef UseBlitPal32i32i32p
csym BlitPal32i32i32p
;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop, .palPtr
params esp+16
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop
param palPtr						; palette (32bit BGRA array) pointer

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea ecx,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	mov edx,[esp+.srcTop@]
	add [esp+.destPtr@],ecx
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx
	push ebp

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2						; width * 4 bytes per pixel
	sub [.srcWrap],eax				; source wrap -= width
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	mov ebx,[.palPtr]
	;mov edx,[.destWidth]
; There is no MMX version of this routine
; since it's actually more work to look up values
;%if PlainUseMMX
;	test dword [PgfxFlags],PgfxFlags.useMMX
;	jnz .MMX
;%endif

	xor edx,edx						; will be used as table index
.RowNext:
	mov ebp,[.destWidth]			; col count = pixel width
.ColNext:
	; Map each 32bit pixel to a 8bit pixel using palette.
	; Only works with palettes of fixed allocations
	; so the components can simply be added together, like
	; 256-color monochrome, 216-color web, or 3:3:2 palette.

	mov eax,[esi]					; get source pixel
	xor ecx,ecx
	add esi,byte 4
	mov dl,al
	mov ecx,[ebx+edx*4+0]			; blue
	mov dl,ah
	shr eax,16
	add ecx,[ebx+edx*4+1024]		; green
	mov dl,al
	add ecx,[ebx+edx*4+2048]		; red
	mov dl,ah
	add ecx,[ebx+edx*4+3072]		; alpha (can set linear ramp zero if unchanged)
	mov [edi],ecx
	add edi,byte 4
.ColEnd:
	dec ebp
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebp
	pop ebx
	pop edi
	pop esi
	ret

unlocals
%endif



;//////////////////////////////////////////////////////////////////////////////
; Streches source pixels to destination.
; dest = src[x*xf,y*yf]
;
; Assumes:	all ptrs valid and preclipped
;			sizes >0
;			src and dest same pixel format
;			src and dest 4-byte aligned (if 32bit images)
;
BlitScale:
	int3 ;not finished!


;//////////////////////////////////////////////////////////////////////////////
; 20041230	created
; Streches and tiles an image opaquely.
; -Can strech, squash, tile, and flip
; -The scale size and offset are actually fixed point integers (16.16).
; -Since this routine does no rotation or scaling, it just needs scale size
;  and offset, but with a full 2x3 matrix it could do every possible 2D image
;  transformation.
;
%ifdef UseBlitScale32i32i
csym BlitScale32i32i

; hotondo dake dekimasita!

;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft,.srcTop, .srcWidth,.srcHeight, .scaleLeft,.scaleTop, .scaleWidth,.scaleHeight
params esp+16+locals_size
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop
param srcWidth
param srcHeight
param scaleLeft						; fixed point 16.16
param scaleTop						; ..
param scaleWidth					; ..
param scaleHeight					; ..

.flagsHorzStrech	equ 1			; streched horizontally, not 1:1
.flagsVertStrech	equ 2			; streched vertically, not 1:1

	cmp dword [esp+.srcHeight@],4096 ; ensure source shorter than max rows
	jae near .Return

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea ecx,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	add [esp+.destPtr@],ecx
	mov edx,[esp+.srcTop@]
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx
	push ebp

	; allocate locals
	locals esp+locals_size
	local rowPtrs,4096*4			; table of pointers to previous rows
	local flags,4
	sub esp,locals_size
	;mov ecx,locals_size/4
	mov ecx,[.srcHeight]
	mov edi,esp
	xor eax,eax
	inc ecx							; clear flags too
	mov [.rowPtrs+4096*3],eax		; pretrigger page, otherwise Windows thinks
	mov [.rowPtrs+4096*2],eax		; skipped too far down the stack and raises GPF
	mov [.rowPtrs+4096*1],eax
	rep stosd

	; see if scaled horizontally and wrap left col
	mov ecx,[.srcWidth]
	shl ecx,16						; set lower decimal portion zero
	cmp ecx,[.scaleWidth]
	jne .NoHorzStrech
	or dword [.flags],.flagsHorzStrech
.NoHorzStrech:
	xor edx,edx
	mov eax,[.scaleLeft]
	div ecx							; left % source width
	mov [.scaleLeft],edx

	; see if scaled vertically and wrap top row
	mov ecx,[.srcHeight]
	shl ecx,16						; set lower decimal portion zero
	cmp ecx,[.scaleHeight]
	jne .NoVertStrech
	or dword [.flags],.flagsVertStrech
.NoVertStrech:
	xor edx,edx
	mov eax,[.scaleTop]
	div ecx							; top % source height
	mov [.scaleTop],edx


	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	shl eax,2						; width * 4 bytes per pixel
	;sub [.srcWrap],eax				; source wrap -= width
	sub [.destWrap],eax

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	;mov edx,[.destWidth]
; There is no MMX version of this routine
; since it's actually more work to look up values
;%if PlainUseMMX
;	test dword [PgfxFlags],PgfxFlags.useMMX
;	jnz .MMX
;%endif

	mov edx,[.scaleTop]
	mov ecx,[.scaleLeft]
	shr edx,16						; reduce 16.16 to integer
	shr ecx,16
	imul edx,[.srcWrap]				; top * byte wrap
	add esi,edx
	lea esi,[esi+ecx*4]				; src offset = top*wrap + left*pixelsize

.RowNext:
	mov ecx,[.destWidth]			; col count = pixel width
.ColNext:
	local source,4, push esi
	local row,4,    push edx

	; if if width == 1, mem fill
	; if row already blit before, just mem copy it again
	; if if no horizontal, tile
	; else scale
	cmp dword [.srcWidth],1
	jle .FillRow
	mov eax,[.rowPtrs+edx*4]
	test eax,eax
	jnz .RecopyRow
	mov [.rowPtrs+edx*4],edi		; save row pointer for later
	;test dword [.flags],.flagsHorzStrechRev
	;jnz .HorzStrechRev
	test dword [.flags],.flagsHorzStrech
	jnz .HorzStrech

.TileRow:
	; TODO: fix this so it actually tiles
	; add left offset?
	;cld
	;mov eax,[.scaleLeft]
	;add esi,eax
	rep movsd
	jmp short .RowEnd

; this copies an existing row, which is faster than tiling
; or streching again.
.RecopyRow:
; (esi=src, edi=dest, ecx=cols, eax=pointer to previous row, ...)
	mov esi,eax
	rep movsd
	jmp short .RowEnd

; fill the row with a single color, which is a special case of
; 1 pixel wide images (tiling would be slow for this case).
.FillRow:
; (esi=src, edi=dest, ecx=cols)
	mov eax,[esi]
	rep stosd
	jmp short .RowEnd

; streches and tiles the source image
.HorzStrech:
	;jmp short .RowEnd

; (maybe unnecessary) streches and tiles the source image in reverse
.HorzStrechRev:
	;jmp short .RowEnd

;.ColEnd:
;	dec ecx
;	jg .ColNext

.RowEnd: ; (esi=src, edi=dest, edx=row)
	unlocal pop edx
	unlocal pop esi

	; if height == 1, no change
	; row += row increment
	; if row < 0, row += height
	; if row > height, row %= height
	mov ecx,[.srcHeight]
	cmp ecx,1
	jle .SameSrcRow
	;add ecx ...
	test edx,edx
	jns .SrcRowPositive
	add edx,ecx
.SrcRowPositive:
	cmp eax,ecx
	; TODO: division and increment
	inc edx
	add esi,[.srcWrap]

.SameSrcRow:
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	add esp,locals_size
	pop ebp
	pop ebx
	pop edi
	pop esi
.Return:
	ret

unlocals
%endif


;//////////////////////////////////////////////////////////////////////////////
; 20050412	created
; Performs distance function between RGB color values. Was written for one
; specific case, a homework assignment in graphics processing CS419.
;
; Uses include:
; -luminance using sqr(R^2+G^2+B^2)
; -distance between colors sqr((R1-R2)^2+(G1-G2)^2+(B1-B2)^2)
;
%ifdef UseBlitDist32i32i
csym BlitDist32i32i

;params .destPtr, .destWrap, .destLeft, .destTop, .destWidth, .destHeight,  .srcPtr, .srcWrap, .srcLeft, .srcTop
params esp+16
param void,4 
param destPtr						; base pointer
param destWrap						; bytes per row
param destLeft						; pixel offset from left of base
param destTop						; pixel offset from top of base
param destWidth						; pixels wide (preclipped)
param destHeight					; pixels high (preclipped)
param srcPtr
param srcWrap
param srcLeft
param srcTop
param palPtr						; palette (32bit BGRA array) pointer

	mov edx,[esp+.destTop@]
	mov ecx,[esp+.destLeft@]
	imul edx,[esp+.destWrap@]		; top * byte wrap
	lea ecx,[edx+ecx*4]				; dest offset = top*wrap + left*pixelsize
	mov edx,[esp+.srcTop@]
	add [esp+.destPtr@],ecx
	mov ecx,[esp+.srcLeft@]
	imul edx,[esp+.srcWrap@]		; top * byte wrap
	lea eax,[edx+ecx*4]				; src offset = top*wrap + left*pixelsize
	add [esp+.srcPtr@],eax

.Raw: ; dest and source ptrs have been precalculated, top/left ignored
	push esi
	push edi
	push ebx
	push ebp

	; build the color table
	; use the following pattern to build a table of squares
	;  +1 +3 +5 +7 +11
    ; 0  1  4  9  16  25
    ;cld
    mov edi,.ColorTable
    mov ecx,256
    mov edx,-1
    xor eax,eax
.NextColor:
    add edx,byte 2
    stosd
    add eax,edx
    dec ecx
    jg .NextColor

	; preadjust byte wraps to compensate for ptr advancement each row
	mov eax,[.destWidth]
	mov edx,eax
	shl eax,2						; width * 4 bytes per pixel
	sub [.srcWrap],eax				; source wrap -= width
	sub [.destWrap],eax

	fild dword [.Factor]			; load factor to scale back down to 0-255 range

	mov esi,[.srcPtr]
	mov edi,[.destPtr]
	mov ebx,.ColorTable
	;mov edx,[.destWidth]
; There is no MMX version of this routine
; since it's actually more work to look up values
;%if PlainUseMMX
;	test dword [PgfxFlags],PgfxFlags.useMMX
;	jnz .MMX
;%endif

	xor edx,edx						; will be used as table index
.RowNext:
	mov ebp,[.destWidth]			; col count = pixel width
.ColNext:
	; Map each 32bit pixel to a 8bit pixel using palette.
	; Only works with palettes of fixed allocations
	; so the components can simply be added together, like
	; 256-color monochrome, 216-color web, or 3:3:2 palette.

	mov eax,[esi]					; get source pixel
	xor ecx,ecx
	add esi,byte 4
	mov dl,al
	mov ecx,[ebx+edx*4+0]			; blue
	mov dl,ah
	shr eax,16
	add ecx,[ebx+edx*4]				; green
	mov dl,al
	add ecx,[ebx+edx*4]				; red
	mov dl,ah
	add ecx,[ebx+edx*4]				; alpha (perhaps should increase variance)
	; now have the sum of R^2 + G^2 + B^2 with a max sum of 65025*3 = 195075
	; compute square root and scale up to range of 0-2^31
	mov [edi],dword 440;ecx
	fild dword [edi]
	fsqrt
	fmul st1						; scale to full 0-255 range
	fistp dword [edi]
	add edi,byte 4
.ColEnd:
	dec ebp
	jg .ColNext
.RowEnd:
	add esi,[.srcWrap]
	add edi,[.destWrap]
	dec dword [.destHeight]
	jg .RowNext

.ImageEnd:
	pop ebp
	pop ebx
	pop edi
	pop esi
	ret

section .data
align 8, db 0
.Factor:
;dd 9724315.7823774081609638882551144 ; <- NASM does not seem to interpret this right??
dd 0.57961438789233017927192975611177

section .bss
.ColorTable:
resd 256							; 256 levels per chroma
section .text

unlocals
%endif
