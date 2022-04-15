// PGFXLAYR.H - Plain Graphics Layer Constants/Structures header
//
// Intended for NASM compiler or MSVC.
////////////////////////////////////////////////////////////////////////////////

//#include "pgfx.h"

#ifndef pgfxlayr_h
#define pgfxlayr_h

//#ifndef pgfx_h
//#error "Include pgfx.h first!"
//#endif

#ifdef __NASM_MAJOR__
  %define ASM
#endif

////////////////////////////////////////////////////////////////////////////////
// structures and constants

////////////////////////////////////////
#ifdef ASM
; Images are arranged in rows, left to right, top to bottom.
; (Not retarded upside down bitmap format)
struc PgtImage
.pixels:	resd 1		; pointer to first pixel (top left)
.type:					; image, palette, font
 .typeMask	equ 15
 .typeImage	equ 0
 .typeFont	equ 1
 .typePal	equ 2
 .typeLast	equ .typeMask ; indicates end of image list
.compression:		; a few basic RLE types?
.flags:		resb 1		; none for now
 .flagsMask	equ 240
.bpp:		resb 1			; bits per pixel
// .bppMask	equ 3		; 1<<0=1  1<<3=8  1<<5=32
.wrap:		resw 1		; bytes per row (always byte aligned)
.size:					; both height & width as dword
.width:		resw 1		; image pixel size
.height:	resw 1
.xorg:		resw 1		; can be interpreted as cursor hotspot
.yorg:		resw 1		;   or imagelist size
endstruc

; (1pixels, 2type&flags, 3bpp, 4wrap, 5width, 6height, 7xorg, 8yorg)
%macro DefPgtImage_deprecated 8
	dd %1	; pixel ptr
	%if ((%2) & PgtImage.typeMask)
		%error "Type should always be image. Leave it unspecified, and only include flags."
	%endif
	db PgtImage.typeImage|(%2)	;type&flags
	db %3	; bpp
	dw (%3)*(%4)/8	; byte wrap = (bpp*wrap)/8
	dw %5,%6	; dimensions
	dw %7,%8	; x,y origin
%endmacro
; (1pixels, 2type&flags, 3bpp, 4width, 5height, 6xorg, 7yorg)
; sets wrap based on width and bpp
%macro DefPgtImage 7
	dd %1
	%if ((%2) & PgtImage.typeMask)
		%error "Type should always be image. Leave it unspecified, and only include flags."
	%endif
	db PgtImage.typeImage|(%2)	; type&flags
	db %3	; bpp
	dw (%3)*(%4)/8	; byte wrap = (bpp*width)/8
	dw %4,%5	; dimensions
	dw %6,%7	; x,y origin
%endmacro
; (1pixels, 2type&flags, 3bpp, 4wrap, 5left, 6top, 7width, 8height, 9xorg, 10yorg)
; note:
; wrap is in element count, not byte count.
; the pixels are adjusted by the left and top coordinate (so pass the unadjusted base image).
; computes left and top offset
%macro DefPgtImage 10
	dd %1+((%6)*(%4) + (%5)) * (%3) / 8	; (top*wrap + left) * bpp / 8
	%if ((%2) & PgtImage.typeMask)
		%error "Type should always be image. Leave it unspecified, and only include flags."
	%endif
	db PgtImage.typeImage|(%2)	; type&flags
	db %3	; bpp
	dw (%3)*(%4)/8	; byte wrap = (bpp*wrap)/8
	dw %7,%8	; dimensions
	dw %9,%10	; x,y origin
%endmacro

#else //C
typedef struct {
	void* pixels;	// pointer to first pixel (top left)
	union {
		unsigned char type;	// image/palette/font
		unsigned char flags;	// misc flags?
		unsigned char compression;	// few basic RLE types
	};
	enum {
		typeMask=15,
		typeImage=0,
		typeFont=1,
		typePal=2,
		typeLast=typeMask,	// indicates end of image list
		flagsMask=240,
	};
	union {
		unsigned char bpp;	// bits per pixel
	};
	unsigned short wrap;	// bytes per row (rows are always byte aligned and usually 32bit aligned)
	short width;	// pixel height
	short height;	// pixel width
	short xorg;	// can be interpreted as cursor hotspot
	short yorg;	// or imagelist size
} PgtImage;
#endif

////////////////////////////////////////
#ifdef ASM
; - Every layer has an source image, alignment flags, clipping dimensions, and
;	a blending operation that determine how to combine it with the destination.
; - Note that the layer dimensions are rarely the same as the actual images.
;	If the image is larger than the layer, the part out of bounds will be
;	clipped. If smaller, the empty area will be transparent.
; - Not all layers have an associated images. Some operations like Clip have
;	only clipping information.
struc PgtLayer
.image:		resd 1		; ptr to image (or image index 0-#) not direct pixels
.blendOp:				; first byte is blending operation (add,sub..)
.flags:		resd 1		; followed by 24 flags
.ifSet:	;resd1			; if flags are set
.left:		resw 1		; pixel offset from given side, depending on flags
.top:		resw 1		; pixel offset from given side, depending on flags
.ifClear:	;resd1			; if flags are clear
.right:		resw 1		; offset from right, absolute right, or width
.bottom:	resw 1		; offset from bottom, absolute bottom, or height
.sizeShl	equ 4		; bits to shift left (each layer is 16 bytes)
endstruc

; The blend ops and flags may change

; Blend operations
PgtLayer.blendOpMask equ 255
PgtLayer.BopNop equ 0
PgtLayer.BopHitTest equ 1
PgtLayer.BopStateGeneric equ 2
PgtLayer.BopStateSpecific equ 3
PgtLayer.BopClip equ 4
PgtLayer.BopClipReset equ 5
PgtLayer.BopOpaque equ 6
PgtLayer.BopTrans equ 7
PgtLayer.BopTransFast equ 8
PgtLayer.BopAdd equ 9
PgtLayer.BopSub equ 10
PgtLayer.BopMul equ 11
PgtLayer.BopMulByAlpha equ 12
PgtLayer.BopAnd equ 13
PgtLayer.BopOr equ 14
PgtLayer.BopAndOr equ 15
PgtLayer.BopGreater equ 16
PgtLayer.BopLesser equ 17
PgtLayer.BopMask equ 18
PgtLayer.BopMaskInc equ 19
PgtLayer.BopSetDest equ 20
PgtLayer.BopTransMask equ 21
PgtLayer.BopLast equ 22
PgtLayer.BopVer equ 20051115

PgtLayer.FlagMore			equ 1<<8	; more layers follow (clear on last layer)
PgtLayer.FlagImageIndex		equ 1<<9	; image is NOT ptr but index instead
PgtLayer.FlagDestIndex		equ 1<<10	; image is NOT ptr but index instead
PgtLayer.FlagUseAlpha		equ 1<<11	; consider alpha when adding,
										; subtracting, oring (Hmm...)
; How to draw the image...
PgtLayer.FlagModeMaskHorz	equ 3<<12
PgtLayer.FlagModeMaskShift	equ    12	; number of bits offset
PgtLayer.FlagNormalHorz		equ 0<<12	; pixels are 1:1, drawn only once
PgtLayer.FlagScaleHorz		equ 1<<12	; image is streched between l&r. t&b
PgtLayer.FlagTileHorz		equ 2<<12	; image is tiled, repeated at edges
PgtLayer.FlagModeMaskVert	equ 3<<14
PgtLayer.FlagNormalVert		equ 0<<14	; pixels are 1:1, drawn only once
PgtLayer.FlagScaleVert		equ 1<<14	; image is streched between l&r. t&b
PgtLayer.FlagTileVert		equ 2<<14	; image is tiled, repeated at edges
PgtLayer.FlagNormal			equ PgtLayer.FlagNormalHorz|PgtLayer.FlagNormalVert
PgtLayer.FlagScale			equ PgtLayer.FlagScaleHorz|PgtLayer.FlagScaleVert
PgtLayer.FlagTile			equ PgtLayer.FlagTileHorz|PgtLayer.FlagTileVert
; How to intepret the four layer coordinates... with the default for each
; being pixel offsets from their corresponding section edge.
; The value in .left can be interpreted as:
;   Offset Column: column is pixel offset from same edge
;     x = section_left + layer_left
;   Opposite offset: column is instead pixel offset from opposite edge
;     x = section_right - layer_left
;   Size: interpret right as absolute coordinate to compute pixel width
;     x = layer_right - layer_left
;   Percent: interpret as percentage between section sides
;     x = section_left + (layer_left/1024) * section_width
; They are essentially the same for right, top, and bottom, except that
; corresponding variables are used and some signs are reversed.
PgtLayer.FlagLeftMask		equ 3<<16
 PgtLayer.FlagLeftOffset		equ 0<<16 ;The amount inset from the left edge
 PgtLayer.FlagLeftOpposite		equ 1<<16
 PgtLayer.FlagLeftSize			equ 2<<16
 PgtLayer.FlagLeftPercent		equ 3<<16
PgtLayer.FlagTopMask		equ 3<<18
 PgtLayer.FlagTopOffset			equ 0<<18
 PgtLayer.FlagTopOpposite		equ 1<<18
 PgtLayer.FlagTopSize			equ 2<<18
 PgtLayer.FlagTopPercent		equ 3<<18
PgtLayer.FlagRightMask		equ 3<<20
 PgtLayer.FlagRightOffset		equ 0<<20
 PgtLayer.FlagRightOpposite		equ 1<<20
 PgtLayer.FlagRightSize			equ 2<<20
 PgtLayer.FlagRightPercent		equ 3<<20
PgtLayer.FlagBottomMask		equ 3<<22
 PgtLayer.FlagBottomOffset		equ 0<<22
 PgtLayer.FlagBottomOpposite	equ 1<<22
 PgtLayer.FlagBottomSize		equ 2<<22
 PgtLayer.FlagBottomPercent		equ 3<<22
PgtLayer.FlagLTRB			equ PgtLayer.FlagLeftOffset|PgtLayer.FlagTopOffset|PgtLayer.FlagRightOffset|PgtLayer.FlagBottomOffset
PgtLayer.FlagLTLT		equ PgtLayer.FlagLeftOffset|PgtLayer.FlagTopOffset|PgtLayer.FlagRightOpposite|PgtLayer.FlagBottomOpposite
PgtLayer.FlagLBLB		equ PgtLayer.FlagLeftOffset|PgtLayer.FlagTopOpposite|PgtLayer.FlagRightOpposite|PgtLayer.FlagBottomOffset
PgtLayer.FlagLTRT			equ PgtLayer.FlagLeftOffset|PgtLayer.FlagTopOffset|PgtLayer.FlagRightOffset|PgtLayer.FlagBottomOpposite
PgtLayer.FlagLBRB			equ PgtLayer.FlagLeftOffset|PgtLayer.FlagTopOpposite|PgtLayer.FlagRightOffset|PgtLayer.FlagBottomOffset
PgtLayer.FlagLTLB			equ PgtLayer.FlagLeftOffset|PgtLayer.FlagTopOffset|PgtLayer.FlagRightOpposite|PgtLayer.FlagBottomOffset
PgtLayer.FlagRTRB			equ PgtLayer.FlagLeftOpposite|PgtLayer.FlagTopOffset|PgtLayer.FlagRightOffset|PgtLayer.FlagBottomOffset
PgtLayer.FlagRTRT		equ PgtLayer.FlagLeftOpposite|PgtLayer.FlagTopOffset|PgtLayer.FlagRightOffset|PgtLayer.FlagBottomOpposite
PgtLayer.FlagRBRB		equ PgtLayer.FlagLeftOpposite|PgtLayer.FlagTopOpposite|PgtLayer.FlagRightOffset|PgtLayer.FlagBottomOffset
PgtLayer.FlagLTWH			equ PgtLayer.FlagLeftOffset|PgtLayer.FlagTopOffset|PgtLayer.FlagRightSize|PgtLayer.FlagBottomSize

; How to align image...
; These only apply for normal and tiled images
; Scaling has no need for these flags, so their meaning could be different
PgtLayer.FlagAlignHorzMask	equ 3<<24
PgtLayer.FlagAlignLeft		equ 0<<24	; left side to left column
PgtLayer.FlagAlignRight		equ 1<<24	; right side to right column
PgtLayer.FlagAlignHorzMid	equ 2<<24	; image edge centered between left and right columns
PgtLayer.FlagAlignHorz		equ 3<<24	; image centered between left and right columns
PgtLayer.FlagAlignVertMask	equ 3<<26
PgtLayer.FlagAlignTop		equ 0<<26	; top side to top row
PgtLayer.FlagAlignBottom	equ 1<<26	; bottom side to bottom row
PgtLayer.FlagAlignVertMid	equ 2<<26	; image edge centered between top and bottom rows
PgtLayer.FlagAlignVert		equ 3<<26	; image centered between top and bottom rows
PgtLayer.FlagAbsoluteVert	equ 1<<28	; layer top/bottom not relative to section
PgtLayer.FlagAbsoluteHorz	equ 1<<29	; layer left/right not relative to section


; (1image ptr, 2op&flags, 3left,4top, 5right,6bottom)
%macro DefPgtLayer1 6
	dd %1
	dd (%2) | PgtLayer.FlagMore
	dw %3,%4,%5,%6
%endmacro

; (1op&flags, 2ifSet, 3ifClear)
%macro DefPgtLayerState 3
	dd 0 ; always null since no image
	dd (%1) | PgtLayer.FlagMore
	dd %2	; if set bit flags
	dd %3	; if clear bit flags
%endmacro

%macro DefPgtLayerEnd 0
	dd 0
	dd PgtLayer.BopNop ; not PgtLayer.FlagMore
	;dw 0,0,0,0 <- these are technically ignored anyway
%endmacro

; todo: These conditional macros are unfinished
%assign DefPgtLayerGS 0	; general set
%assign DefPgtLayerGC 0	; general clear
%assign DefPgtLayerSS 0	; specific set
%assign DefPgtLayerSC 0	; specific clear

%macro DefPgtLayerIf 3

	%ifidni %1,generic
		%push DefPgtLayerGS
		%assign %$DefPgtLayerGS %$$DefPgtLayerGS | %2
	%elifidni %ifidni %1,specific
	    %push pgtlayerifs
	%else
		%error "Must be either a generic or specific flag"
	%endif
    ;j%-1  %$ifnot 

%endmacro 

%macro DefPgtLayerNif 1 

    %push pgtlayernif
    j%-1  %$ifnot 

%endmacro 

%macro DefPgtLayerElse 0 

  %ifctx if 
        %repl   else 
        jmp     %$ifend 
        %$ifnot: 
  %else 
        %error  "expected `if' before `else'" 
  %endif 

%endmacro 

%macro DefPgtLayerEndif 0 

  %ifctx if 
        %$ifnot: 
        %pop 
  %elifctx      else 
        %$ifend: 
        %pop 
  %else 
        %error  "expected `if' or `else' before `endif'" 
  %endif 

%endmacro






#else //C

typedef struct {
	PgtImage* image;
	union {
		unsigned char blendOp;
		unsigned long flag;
	};
	short left;
	short top;
	short right;
	short bottom;
} PgtLayer;

// (pixels, type&flags, bpp, left, top, height, width)
//#define DefPgtImage(p,f,b,l,t,h,w) {p,f,b,w<<(b-3),l,t,h,w}

#endif

////////////////////////////////////////////////////////////////////////////////
#ifndef pgfx_layer_data // only interested in definitions and macros, not exports
#ifndef pgfxlayr_asm	// do not refer to own functions
#ifndef pgfxll_asm	// low level routines do not need to call any high lever ones
#ifdef ASM
	extern DrawLayers
	;extern foo...
#else	// C
	extern "C" void DrawLayers(
		PgtLayer* layerPtr,	// pointer to layer array
		int areaWidth,		// pixel width of control
		int areaHeight,
		int sectLeft,		// pixel offset from left
		int sectTop,		// pixel offset from top
		int sectRight,		// pixel offset from right
		int sectBottom,		// pixel offset from bottom
		PgtImage* imagesPtr,// pointer to additional image array
		int imagesNum		// number of images passed
	);
#endif
#endif
#endif
#endif

#endif