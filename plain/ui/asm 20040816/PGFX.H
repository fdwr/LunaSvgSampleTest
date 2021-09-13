// PGFX.H - Plain Graphics Functions header
//
// Intended for NASM compiler. Can by included in C too, but not all
// structures defined have C equivalents.

#define PigeonGfxVer 3,0,0,2004
#define PigeonGfxVerStr "3.0.0.2004"

#ifdef __NASM_MAJOR__
#define ASM
#endif

#ifndef ASM
#pragma pack(push, 1)     // for byte alignment
#endif

#ifdef ASM
; Images are arranged in rows, left to right, top to bottom
struc PgImage
.type:					; image, palette, font
.typeMask	equ 15
.typeImage	equ 0
.typeFont	equ 1
.typePal	equ 2
.typeLast	equ .typeMask ; indicates end of image list
.flags:		resb 1		; none for now
.flagsMask	equ 240
.bpp:					; bits per pixel, stored as exponent
.bppMask	equ 3		; 1<<0=1  1<<3=8  1<<5=32
.compression:resb 1		; none for now
.wrap:		resw 2		; bytes per row (always byte aligned)
.pixels:	resd 1
.left:		resw 1
.top:		resw 1
.height:	resw 1
.width:		resw 1

; Every layer has an source image, alignment flags, clipping dimensions, and
; a blending operation that determine how to combine it with the destination.
; Note that the layer dimensions are rarely the same as the actual images.
struc PgLayer
.blendOp:				; first byte is blending operation (add,sub..)
.flags:		resd 1		; followed by 24 flags
.image:		resd 1		; ptr to image (or image index 0-#)
.left:		resw 1		; pixel offset from given side, depending on flags
.top:		resw 1		; pixel offset from given side, depending on flags
.right:		resw 1		; offset from right, absolute right, or width
.bottom:	resw 1		; offset from bottom, absolute bottom, or height
.sizeShl	equ 4		; bits to shift left (each layer is 16 bytes)
endstruc

; Each palette entry is 32bits, 8 bits for each channel.
; Palettes are simply arrays of entries.
; Note this is the same as the Windows RGB Quad, except that the fourth byte
; is given a meaning instead of reserved.
struc PgPalEntry
.blue:		resb 1
.green:		resb 1
.red:		resb 1
.alpha:		resb 1		; opaque=255 transparent=0 (byte often ignored)
endstruc

Pgfx.FlagsSlowPc	equ 1	;slow machine so sacrifice quality to speed up
Pgfx.FlagsHasMMX	equ 2	;processor supports feature
Pgfx.FlagsUseMMX	equ 4	;user wants to use MMX (only CPU supports)

BlitOpaque32x32_parms equ 10
BlitOpaque8x8_parms equ 10
BlitOpaqueFill32x32_parms equ 7
BlitOpaqueFill8x8_parms equ 7
BlitTransKey32x32_parms equ 10
BlitAdd32x32_parms equ 10
BlitAdd8x8_parms equ 10
BlitAddFill32x32_parms equ 7
BlitAddFill8x8_parms equ 7
BlitSub32x32_parms equ 10

#else //C

typedef struct {
	union {
		unsigned char type;
		unsigned char flags;
	};
	union {
		unsigned char bpp;
		unsigned char compression;
	};
	unsigned short wrap;
	void* pixels;
	short left;
	short top;
	short height;
	short width;
} PgImage;

typedef struct {
	union {
		unsigned char blendOp;
		unsigned long flag;
	};
	PgImage* image;
	short left;
	short top;
	short right;
	short bottom;
} PgLayer;

typedef struct {
	unsigned char red;
	unsigned char green;
	unsigned char blue;
	unsigned char alpha;	// opaque=255 transparent=0 (byte often ignored)
} PgPalEntry;

#endif

//typedef enum
//{
//}

#ifndef ASM
#pragma pack(pop)     // for original alignment
#endif
