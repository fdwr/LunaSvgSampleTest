// PGFX.H - Plain Graphics Functions header
//
// Intended for NASM compiler or MSVC.
////////////////////////////////////////////////////////////////////////////////

#ifndef pgfx_h
#define pgfx_h

#define PlainGfxVer 3,0,0,2004
#define PlainGfxVerStr "3.0.0.2004"

// The compiler WILL complain about pgfxoptions.h missing at first.
// You should copy the file to your project directory to customize
// the options (rather changing the source files directly).
#include "pgfxconfig.h" // <-- read above

#ifndef PlainUseMMX
#define PlainUseMMX 1
#endif

#ifndef _WINDOWS
#ifndef _DOS
#error "Either _DOS or _WINDOWS must be defined. Copy pgfxoptions.h to your main project folder, and add #define _WINDOWS."
#endif
#endif

;////////////////////////////////////////
#ifdef __NASM_MAJOR__
	%define ASM
	%include "macros32.inc"

	; This below is ONLY necessary when compiling to OBJ format,
	; since NASM otherwise makes the segments 16 bit.
	; Any other format (COFF/WIN32) automatically assumes 32 bit.
	[bits 32]
	[segment .data use32]
	[segment .text use32]
	[segment .bss  use32]

	%ifdef _WINDOWS
	%define UseWindowAll
	%include "winnasm.inc"
	%endif

#else //C

	#include "basictypes.h"

	#if defined(_WINDOWS) && !defined(_WINDOWS_)
	#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
	#include <windows.h>
	#endif

	#pragma pack(push, 1)     // for byte alignment

#endif


////////////////////////////////////////////////////////////////////////////////
// for now, just define these explicitly.
// later, only define the ones necessary so no unnecessary
// code is included.

#define UseBlitOpaque32i32i
#define UseBlitOpaque8i8i
#define UseBlitOpaque32i32c
#define UseBlitOpaque8i8c
#define UseBlitOpaqueLeft32i32i

#define UseBlitTrans32i32i
#define UseBlitTrans32i32c
#define UseBlitTrans32i8i32c
#define UseBlitTransFast32i32i
#define UseBlitTransFast8i8i

#define UseBlitAdd32i32i
#define UseBlitAdd8i8i
#define UseBlitAdd32i32c
#define UseBlitAdd8i8c

#define UseBlitSub32i32i

#define UseBlitMul32i32i
#define UseBlitMul8i8i
#define UsePgfxMulTblInit

#define UseBlitGreater32i32i
#define UseBlitGreater8i8i
#define UseBlitGreater32i32c
#define UseBlitGreater8i8c

#define UseBlitLesser32i32i
#define UseBlitLesser8i8i
#define UseBlitLesser32i32c
#define UseBlitLesser8i8c

#define UseBlitAnd32i32i
#define UseBlitOr32i32i
#define UseBlitAndOr32i32c32c

#define UseBlitPal32i8i32p
#define UseBlitPal8i32i32p
#define UseBlitPal32i32i32p

#define UseBlitScale32i32i

//#define UseBlitDist32i32i

////////////////////////////////////////////////////////////////////////////////
// structures and constants

////////////////////////////////////////
#ifdef ASM
	PgfxCurrentFlags.slowPc	 equ 1<<0	; slow machine so sacrifice quality to speed up
	PgfxCurrentFlags.hasMMX	 equ 1<<1	; processor supports feature
	PgfxCurrentFlags.useMMX	 equ 1<<2	; user wants to use MMX (only CPU supports)
	PgfxCurrentFlags.mulInit	 equ 1<<3	; multiplication look up table initialized
	PgfxCurrentFlags.redraw	 equ 1<<8	; something needs redrawing
	PgfxCurrentFlags.cursorMove equ 1<<16	; cursor was moved
	PgfxCurrentFlags.cursorSet	 equ 1<<17	; new cursor set
	PgfxCurrentFlags.cursorHidden equ 1<<18

	PgtBop.Nop equ 0
	PgtBop.HitTest equ 1
	PgtBop.If equ 2
	PgtBop.Clip equ 3
	PgtBop.ClipReset equ 4
	PgtBop.Opaque equ 5
	PgtBop.Trans equ 6
	PgtBop.TransFast equ 7
	PgtBop.Add equ 8
	PgtBop.Sub equ 9
	PgtBop.Mul equ 10
	PgtBop.MulByAlpha equ 11
	PgtBop.And equ 12
	PgtBop.Or equ 13
	PgtBop.AndOr equ 14
	PgtBop.Greater equ 15
	PgtBop.Lesser equ 16
	PgtBop.Mask equ 17
	PgtBop.MaskInc equ 18
	PgtBop.SetDest equ 19
	PgtBop.Last equ 19

	PgtLargeCoordinate equ 16384
#else //C
enum {
	PgfxCurrentFlags_slowPc=1<<0,		// slow machine so sacrifice quality to speed up
	PgfxCurrentFlags_hasMMX=1<<1,		// processor supports feature
	PgfxCurrentFlags_useMMX=1<<2,		// user wants to use MMX (only CPU supports)
	PgfxCurrentFlags_mulInit=1<<3,		// multiplication look up table initialized
	PgfxCurrentFlags_redraw=1<<8,		// something needs redrawing
	PgfxCurrentFlags_cursorMove=1<<16,	// cursor was moved
	PgfxCurrentFlags_cursorSet=1<<17,	// new cursor set
	PgfxCurrentFlags_cursorHidden=1<<18
};

enum {
	PgtBop_nop,
	PgtBop_hitTest,
	PgtBop_if,
	PgtBop_clip,
	PgtBop_clipReset,
	PgtBop_opaque,
	PgtBop_trans,
	PgtBop_transFast,
	PgtBop_add,
	PgtBop_sub,
	PgtBop_mul,
	PgtBop_mulByAlpha,
	PgtBop_and,
	PgtBop_or,
	PgtBop_andOr,
	PgtBop_greater,
	PgtBop_lesser,
	PgtBop_mask,
	PgtBop_maskInc,
	PgtBop_setDest,
	PgtBop_transMask,
	PgtBop_Last=PgtBop_transMask
};

#endif

////////////////////////////////////////
#ifdef ASM
struc PgtRect
.left:			resd 1			; pixels from left
.top:			resd 1			; pixels from top
.right:			resd 1			; usually up to but not including given coordinate
.bottom:		resd 1
endstruc

struc PgtDisplay
.pixels:        resd 1          ; pointer to image top/left
.wrap:			resd 1			; byte wrap between rows, including width and padding
.left:          resd 1          ; current window column offset
.top:           resd 1          ; current window row offset
.width          resd 1			; pixel width (may have alignment padding)
.height:        resd 1			; pixel height
.clipLeft:      resd 1          ; clip, pixels from absolute left
.clipTop:       resd 1          ; clip, pixels from absolute top
.clipRight:     resd 1
.clipBottom:    resd 1
endstruc

; includes additional members
struc PgtDisplayFull
.pixels:        resd 1          ; pointer to image top/left
.wrap:			resd 1			; byte wrap between rows, including width and padding
.left:          resd 1          ; current window column offset
.top:           resd 1          ; current window row offset
.width          resd 1			; pixel width (may have alignment padding)
.height:        resd 1			; pixel height
.clipLeft:      resd 1          ; clip, pixels from absolute left
.clipTop:       resd 1          ; clip, pixels from absolute top
.clipRight:     resd 1
.clipBottom:    resd 1
.redrawLeft:    resd 1          ; redraw bound, pixels from absolute left
.redrawTop:     resd 1          ; redraw bound, pixels from absolute top
.redrawRight:   resd 1
.redrawBottom:  resd 1
#ifdef _WINDOWS
.hwnd:			resd 1			; owning window
.hdcc:			resd 1			; compatible device context
.hdib:			resd 1			; graphics buffer
#endif
endstruc

#else //C

typedef struct {
	int32 left;					// pixels from left
	int32 top;					// pixels from top
	int32 right;				// usually up to but not including given coordinate
	int32 bottom;
} PgtRect;						// same as Windows RECT

typedef struct {
	void* pixels;				// pointer to image top/left
	unsigned int wrap;			// byte wrap between rows, including width and padding
	int32 left;					// current window column offset
	int32 top;					// current window row offset
	int32 width;				// pixel width (may have alignment padding)
	int32 height;				// pixel height
	PgtRect clip;				// clip, pixels from absolute left,top
} PgtDisplay;

typedef struct {
	union {
		struct {
			void* pixels;		// pointer to image top/left
			unsigned int wrap;	// byte wrap between rows, including width and padding
			int32 left;			// current window column offset
			int32 top;			// current window row offset
			int32 width;		// pixel width (may have alignment padding)
			int32 height;		// pixel height
			PgtRect clip;
		};
		PgtDisplay display;
	};
	PgtRect redraw;				// redraw bound, pixels from absolute left
   #ifdef _WINDOWS
	HWND hwnd;					// owning window
	HDC hdcc;					// compatible device context
	HBITMAP hdib;				// graphics buffer
   #endif
} PgtDisplayFull;
#endif

////////////////////////////////////////
// PgtImage and PgtLayer are in pgfxlayr.h
#include "pgfxlayr.h"

////////////////////////////////////////
#ifdef PlainUseCursor

#ifdef ASM
struc PgtCursor
.x:			resd 1			; current hotspot pixel position
.y:			resd 1
.xOffset:		resd 1			; amount cursor image is offset from actual
.yOffset:		resd 1
.xPrev:		resd 1			; previous position of cursor + hotspot
.yPrev:		resd 1
.layer:			resd 1			; pointer to last used cursor
.background:	resd 1			; pointer to image behind cursor
endstruc
#else

typedef struct {
	int32 col, row;
	int32 colOffset, rowOffset;
	int32 colPrev, rowPrev;
	void* PgtLayer;
	void* background;
} PgtCursor;
#endif

#endif

////////////////////////////////////////
#ifdef ASM
; Each palette entry is 32bits, 8 bits for each of the 4 channels.
; Note they are in BGRA order instead of RGB, since Windows and seemingly most
; video cards actually lay out their pixel memory in that order.
struc PgtPalEntry
.blue:		resb 1
.green:		resb 1
.red:		resb 1
.alpha:		resb 1		; opaque=255 transparent=0 (byte often ignored)
endstruc

%macro DefPalEntry1 1
  %if %1 > 0 && %1 <= 00FFFFFFh
    dd %1 | 0FF000000h	; or with full opacity
  %else
	dd 1				; otherwise assume correct alpha given 
  %endif
%endmacro
#else //C
typedef struct {
  union {
	uint32 bgra;
	struct {
		uint8 blue;
		uint8 green;
		uint8 red;
		uint8 alpha;	// opaque=255 transparent=0 (byte often ignored)
	};
  };
} PgtPalEntry;

typedef struct {
  union {
    uint8  i8;
    uint16 i16;
	uint32 i32;
	struct {
		unsigned int i16b : 5;
		unsigned int i16g : 5;
		unsigned int i16r : 5;
	};
	struct {
		unsigned int i16l : 8;
		unsigned int i16h : 8;
    };
	struct {
		unsigned int i32l : 16;
		unsigned int i32h : 16;
    };
	struct {
		signed int   s32l : 16;
		signed int   s32h : 16;
    };
	struct {
		unsigned int i32b : 8;
		unsigned int i32g : 8;
		unsigned int i32r : 8;
		unsigned int i32a : 8;
    };
  };
} PgtPixel;

typedef struct {
  union {
	void*		v;
    uint8*     i8;
    uint16*   i16;
	uint32*   i32;
	PgtPixel*   p;
  };
} PgtPixelPtr;


#endif

////////////////////////////////////////
#ifdef ASM
BlitOpaque32i32i_parms equ 10
BlitOpaque8i8i_parms equ 10
BlitOpaque32i32c_parms equ 7
BlitOpaque8i8c_parms equ 7
BlitOpaqueLeft32i32i_parms equ 10

BlitTrans32i32i_parms equ 10
BlitTrans32i32c_parms equ 7
BlitTrans32i8i32c_parms equ 11
BlitTransFast32i32i_parms equ 10
BlitTransFast8i8i_parms equ 10

BlitAdd32i32i_parms equ 10
BlitAdd8i8i_parms equ 10
BlitAdd32i32c_parms equ 7
BlitAdd8i8c_parms equ 7

BlitSub32i32i_parms equ 10

BlitMul32i32i_parms equ 10
BlitMul8i8i_parms equ 10

BlitGreater32i32i_parms equ 10
BlitGreater8i8i_parms equ 10
BlitGreater32i32c_parms equ 7
BlitGreater8i8c_parms equ 7

BlitLesser32i32i_parms equ 10
BlitLesser8i8i_parms equ 10
BlitLesser32i32c_parms equ 7
BlitLesser8i8c_parms equ 7

BlitAnd32i32i_parms equ 10
BlitOr32i32i_parms equ 10
BlitAndOr32i32c32c_parms equ 8

BlitPal32i8i32p_parms equ 11
BlitPal8i32i32p_parms equ 11
BlitPal32i32i32p_parms equ 11

UseBlitScale32i32i_parms equ 16
#endif

////////////////////////////////////////////////////////////////////////////////
// function prototypes

#ifndef pgfx_layer_data // only interested in definitions and macros, not exports
#ifndef pgfxll_asm
#ifdef ASM
	extern PgfxCurrentFlags

	extern PgfxInit
	
	extern BlitOpaque32i32i
	extern BlitOpaque8i8i
	extern BlitOpaque32i32c
	extern BlitOpaque8i8c
	extern BlitOpaqueLeft32i32i

	extern BlitTrans32i32i
	extern BlitTrans32i32c
	extern BlitTrans32i8i32c
	extern BlitTransFast32i32i
	extern BlitTransFast8i8i

	extern BlitAdd32i32i
	extern BlitAdd8i8i
	extern BlitAdd32i32c
	extern BlitAdd8i8c
	
	extern BlitSub32i32i
	
	extern BlitMul32i32i
	extern BlitMul8i8i
	
	extern BlitGreater32i32i
	extern BlitGreater8i8i
	;extern BlitGreater32i32c
	extern BlitGreater8i8c
	
	extern BlitLesser32i32i
	extern BlitLesser8i8i
	;extern BlitLesser32i32c
	extern BlitLesser8i8c
	
	extern BlitAnd32i32i
	extern BlitOr32i32i

	;extern BlitAndOr32i32c32c
	extern BlitPal32i8i32p
	extern BlitPal8i32i32p
	extern BlitPal32i32i32p
	
	extern BlitScale32i32i
		
#else	// C
	extern "C" int PgfxCurrentFlags;

	extern "C" int PgfxInit();

	extern "C" void BlitOpaque32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitOpaque32i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);
	extern "C" void BlitOpaqueLeft32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitOpaque8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitOpaque8i8c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);

	extern "C" void BlitTrans32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitTrans32i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);
	extern "C" void BlitTrans32i8i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop, int srcColor);
	extern "C" void BlitTransFast32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitTransFast8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);

	extern "C" void BlitAdd32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitAdd32i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);
	extern "C" void BlitAdd8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitAdd8i8c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);

	extern "C" void BlitSub32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);

	extern "C" void BlitMul32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitMul8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);

	extern "C" void BlitGreater32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitGreater8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitGreater32i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);
	extern "C" void BlitGreater8i8c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);

	extern "C" void BlitLesser32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitLesser8i8i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitLesser32i32c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);
	extern "C" void BlitLesser8i8c(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, int srcColor);

	extern "C" void BlitAnd32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
	extern "C" void BlitOr32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);

	extern "C" void BlitScale32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop, int srcWidth, int srcHeight, int scaleLeft, int scaleTop, int scaleWidth, int scaleHeight);
	//extern "C" void BlitAndOr32i32c32c

	extern "C" void BlitPal32i8i32p(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop, PgtPalEntry* palPtr);
	extern "C" void BlitPal8i32i32p(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop, PgtPalEntry* palPtr);
	extern "C" void BlitPal32i32i32p(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop, PgtPalEntry* palPtr);

	extern "C" void BlitDist32i32i(void* destPtr, int destWrap, int destLeft, int destTop, int destWidth, int destHeight, void* srcPtr, int srcWrap, int srcLeft, int srcTop);
#endif
#endif


////////////////////////////////////////////////////////////////////////////////
#ifndef pgfxhl_asm	// do not refer to own functions
#ifndef pgfxll_asm	// low level routines do not need to call any high lever ones
#ifdef ASM
	extern PgfxCurrentDisplay
	extern PgfxCurrentDisplay.pixels
	extern PgfxCurrentDisplay.wrap
	extern PgfxCurrentDisplay.left
	extern PgfxCurrentDisplay.top
	extern PgfxCurrentDisplay.height
	extern PgfxCurrentDisplay.width
	extern PgfxCurrentDisplay.clipLeft
	extern PgfxCurrentDisplay.clipTop
	extern PgfxCurrentDisplay.clipRight
	extern PgfxCurrentDisplay.clipBottom
	extern PgfxCurrentDisplay.redrawLeft
	extern PgfxCurrentDisplay.redrawTop
	extern PgfxCurrentDisplay.redrawRight
	extern PgfxCurrentDisplay.redrawBottom
	extern PgfxCurrentDisplayImage
#ifdef PlainUseCursor
		extern PgfxCurrentCursor
#endif
#else	// C
	extern "C" PgtDisplayFull PgfxCurrentDisplay;
	extern "C" PgtImage PgfxDisplayImage;
	#ifdef PlainUseCursor
		extern "C" PgtCursor PgfxCurrentCursor;
		extern "C" void PgfxCursorShow();
		extern "C" void PgfxCursorHide();
		extern "C" __stdcall PgfxCursorSet(PgtLayer* layer);
	#endif
	extern "C" void BlitImage(int pop, int destLeft, int destTop, int destWidth, int destHeight, PgtImage* srcPtr, int srcLeft, int srcTop, ...);
#endif
#endif
#endif
#endif

////////////////////////////////////////////////////////////////////////////////

#ifndef ASM
#pragma pack(pop)     // for original alignment
#endif

#endif // pgfx_h
