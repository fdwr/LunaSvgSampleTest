/**
Author:	Dwayne Robinson
Date:	2005-10-31
Since:	2005-10-31
Remark:	Graphics definitions and functions
*/
module pgfx.pgfxdefs;

//#define PlainGfxVer 3,0,0,2004
//#define PlainGfxVerStr "3.0.0.2004"

// The compiler WILL complain about pgfxoptions.h missing at first.
// You should copy the file to your project directory to customize
// the options (rather changing the source files directly).
public import PgfxConfig;
//package import stdint;
version(Windows) import common.windows;

package alias  byte   int8;
package alias ubyte  uint8;
package alias  short  int16;
package alias ushort uint16;
package alias  int    int32;
package alias uint   uint32;
package alias  long   int64;
package alias ulong  uint64;
static assert (int8.sizeof == 1 && int16.sizeof == 2 && int32.sizeof == 4 && int64.sizeof == 8);


/**
Author:	Dwayne Robinson
Date:	2005-10-31
Since:	2005-10-31
Remark:	Global definitions.
*/

/*
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
*/


////////////////////////////////////////////////////////////////////////////////
// structures and constants

////////////////////////////////////////
enum PgfxFlags {
	slowPc=1<<0,		/// slow machine so sacrifice quality to speed up
	hasMMX=1<<1,		/// processor supports feature
	useMMX=1<<2,		/// user wants to use MMX (only CPU supports)
	mulInit=1<<3,		/// multiplication look up table initialized
	redraw=1<<8,		/// something needs redrawing
	cursorMove=1<<16,	/// cursor was moved
	cursorSet=1<<17,	/// new cursor set
	cursorHidden=1<<18,	/// not visible now
}

enum PgfxBop {
	nop,				/// no operation
	hitTest,			/// just hit test information
	state,				/// flag test (basic if statement)
	clip,				/// clip region to rectangle (inclusive)
	clipReset,			/// reset clipping region to max bounds
	opaque,				/// draw opaque
	trans,				/// draw translucent (with alpha)
	transFast,			/// draw transparent (with binary yes/no on alpha threshold)
	add,				/// add chroma to destination
	sub,				/// subtract chroma from destination
	mul,				/// multiply each chroma with destination
	mulByAlpha,			/// ???
	and,				/// and chroma with destination
	or,					/// or chroma with destination
	andOr,				/// and/or with destination
	greater,			/// choose greater of destination or source
	lesser,				/// choose lesser of destination or source
	mask,				/// ???
	maskInc,			/// ???
	setDest,			/// ???
	transMask,			/// ???
}

enum {
	maxCoordinate=16384
}

////////////////////////////////////////
// STRUCTURES
// * most of these should be byte precise, since they may be stored in files

align(1) struct PgfxRect {
	int32 left;					// pixels from left
	int32 top;					// pixels from top
	int32 right;				// usually up to but not including given coordinate
	int32 bottom;
}								// same as Windows RECT

align(1) struct PgfxDisplay {
	void* pixels;				// pointer to image top/left
	uint32 wrap;				// byte wrap between rows, including width and padding
	int32 left;					// current window column offset
	int32 top;					// current window row offset
	int32 width;				// pixel width (may have alignment padding)
	int32 height;				// pixel height
	PgfxRect clip;					// clip, pixels from absolute left,top
}

align(1) struct PgfxDisplayFull {
	union {
		struct {
			void* pixels;		// pointer to image top/left
			uint32 wrap;		// byte wrap between rows, including width and padding
			int32 left;			// current window column offset
			int32 top;			// current window row offset
			int32 width;		// pixel width (may have alignment padding)
			int32 height;		// pixel height
			PgfxRect clip;
		}
		PgfxDisplay display;
	}
	PgfxRect redraw;				// redraw bound, pixels from absolute left
	version(Windows) {
		HWND hwnd;				// owning window
		HDC hdcc;				// compatible device context
		HBITMAP hdib;			// graphics buffer
	}
}

// Each palette entry is 32bits, 8 bits for each of the 4 channels.
// Note they are in BGRA order instead of RGB, since Windows and seemingly most
// video cards actually lay out their pixel memory in that order.
align(1) union PgfxPalEntry {
	uint32 bgra;
	struct {
		uint8 blue;
		uint8 green;
		uint8 red;
		uint8 alpha;	// opaque=255 transparent=0 (byte often ignored)
	}
}

align(1) union PgfxPixel {
	uint8  i8;
	uint16 i16;
	uint32 i32;
	//struct {
	//	uint i16b : 5;
	//	uint i16g : 5;
	//	uint i16r : 5;
	//};
	struct {
		uint8 i16l;
		uint8 i16h;
	}
	struct {
		uint16 i32l;
		uint16 i32h;
	}
	struct {
		int16   s32l;
		int16   s32h;
	}
	struct {
		uint8 i32b;
		uint8 i32g;
		uint8 i32r;
		uint8 i32a;
	}
}

align(1) union PgfxPixelPtr {
	void*		v;
	uint8*     i8;
	uint16*   i16;
	uint32*   i32;
	PgfxPixel*   p;
}

//static if (PgfxOptions.PlainUseCursor == 1) {
align(1) struct PgfxCursor {
	int32 x, y;				// current hotspot pixel position
	int32 xOffset, yOffset;	// amount cursor image is offset from actual
	int32 xPrev, yPrev;		// previous position of cursor + hotspot
	PgfxLayer image;				// pointer to last used cursor
	void* background;			// pointer to image behind cursor
	enum {maxSize = 32};
}
//}

// Images are arranged in rows, left to right, top to bottom.
// (Not retarded upside down bitmap format)
align(1) struct PgfxLayerImage {
	void* pixels;	// pointer to first pixel (top left)
	union {
		uint8 type;	// image/palette/font
		uint8 flags;	// misc flags?
		uint8 compression;	// few basic RLE types
		enum {
			typeMask=15,
			typeImage=0,
			typeFont=1,
			typePal=2,
			typeLast=typeMask,	// indicates end of image list
			flagsMask=240,
		};
	};
	union {
		uint8 bpp;	// bits per pixel
	};
	uint16 wrap;	// bytes per row (rows are always byte aligned and usually 32bit aligned)
	int16 width;	// pixel height
	int16 height;	// pixel width
	int16 xorg;	// can be interpreted as cursor hotspot
	int16 yorg;	// or imagelist size
} ;

/*
-	Every layer has an source image, alignment flags, clipping dimensions, and
	a blending operation that determine how to combine it with the destination.
-	Note that the layer dimensions are rarely the same as the actual images.
	If the image is larger than the layer, the part out of bounds will be
	clipped. If smaller, the empty area will be transparent.
-	Not all layers have an associated images. Some operations like Clip have
	only clipping information.
*/
struct PgfxLayer {
	enum {BlendOpMask =255}
	enum Bops : uint8 { // Blending operations (! The blend ops and flags may change later !)
		nop = 0,
		hitTest,
		stateGeneric, /// flag state test uses ifSet and ifClear members. Following ops are skipped or performed until the next test. (set both ifSet =0 & ifClear = 0 to reset the if)
		stateSpecific,
		clip,
		clipReset,
		opaque,
		trans,
		transFast,
		add,
		sub,
		mul,
		mulByAlpha,
		and,
		or,
		andOr,
		greater,
		lesser,
		mask,
		maskInc,
		setDest,
		transMask,
		//versionDate = 20050414,
	}
	enum Flags : uint32 { // Attribute flags (! The blend ops and flags may change later !)
		more			= 1<<8,	// more layers follow in sequence (clear on last layer)
		imageIndex		= 1<<9,	// image is NOT ptr but index instead
		destIndex		= 1<<10,	// image is NOT ptr but index instead
		useAlpha		= 1<<11,	// consider alpha when adding,
												// subtracting, oring (Hmm...)
		// How to draw the image...
		modeMaskHorz	= 3<<12,
		modeMaskShift	=    12,	// number of bits offset
		normalHorz		= 0<<12,	// pixels are 1:1, drawn only once
		scaleHorz		= 1<<12,	// image is streched between l&r. t&b
		tileHorz		= 2<<12,	// image is tiled, repeated at edges
		modeMaskVert	= 3<<14,
		normalVert		= 0<<14,	// pixels are 1:1, drawn only once
		scaleVert		= 1<<14,	// image is streched between l&r. t&b
		tileVert		= 2<<14,	// image is tiled, repeated at edges
		normal			= normalHorz|normalVert,
		scale			= scaleHorz|scaleVert,
		tile			= tileHorz|tileVert,
		// How to intepret the four layer coordinates... with the default for each
		// being pixel offsets from their corresponding section edge.
		// The value in .left can be interpreted as:
		//   Offset Column: column is pixel offset from same edge
		//     x = section_left + layer_left
		//   Opposite offsett: column is instead pixel offset from opposite edge
		//     x = section_right - layer_left
		//   Size: interpret as pixel width
		//     x = layer_right - layer_left
		//   Percent: interpret as percentage between section sides
		//     x = section_left + (layer_left/1024) * section_width
		// They are essentially the same for right, top, and bottom, except that
		// corresponding variables are used and some signs are reversed.
		leftMask		= 3<<16,
		 leftOffset		= 0<<16,
		 leftOpposite		= 1<<16,
		 leftSize			= 2<<16,
		 leftPercent		= 3<<16,
		topMask		= 3<<18,
		 topOffset			= 0<<18,
		 topOpposite		= 1<<18,
		 topSize			= 2<<18,
		 topPercent		= 3<<18,
		rightMask		= 3<<20,
		 rightOffset		= 0<<20,
		 rightOpposite		= 1<<20,
		 rightSize			= 2<<20,
		 rightPercent		= 3<<20,
		bottomMask		= 3<<22,
		 bottomOffset		= 0<<22,
		 bottomOpposite	= 1<<22,
		 bottomSize		= 2<<22,
		 bottomPercent		= 3<<22,
		allOffset			= leftOffset|topOffset|rightOffset|bottomOffset,
		allCartesian		= leftOffset|topOffset|rightOpposite|bottomOpposite,
		allRect			= leftOffset|topOffset|rightSize|bottomSize,
		
		// How to align image...
		// These only apply for normal and tiled images
		// Scaling has no need for these flags, so their meaning could be different
		alignHorzMask	= 3<<24,
		alignLeft		= 0<<24,	// left side to left column
		alignRight		= 1<<24,	// right side to right column
		alignHorzMid	= 2<<24,	// image edge centered between left and right columns
		alignHorz		= 3<<24,	// image centered between left and right columns
		alignVertMask	= 3<<26,
		alignTop		= 0<<26,	// top side to top row
		alignBottom	= 1<<26,	// bottom side to bottom row
		alignVertMid	= 2<<26,	// image edge centered between top and bottom rows
		alignVert		= 3<<26,	// image centered between top and bottom rows
		absoluteVert	= 1<<28,	// layer top/bottom not relative to section
		absoluteHorz	= 1<<29,	// layer left/right not relative to section
	}
	
	PgfxLayerImage* image;	// ptr to image, not direct pixels (or image index 0-#)
	union {
		Bops blendOp;	/// first byte is blending operation (add,sub..)
		Flags flags;	/// followed by 24 flags
	};
	union {
		struct { // used for nearly every bop except state
			int16 left;	/// pixel offset from given side, depending on flags
			int16 top;	/// pixel offset from given side, depending on flags
			int16 right;	/// offset from right, absolute right, or width
			int16 bottom;	/// offset from bottom, absolute bottom, or height
		}
		struct { // valid only with the state bop
			uint32 ifSet;	/// flags that must be set
			uint32 ifClear; /// flags that must be clear
		}
	}
}

/*
; (image ptr, blend&flags, left,top, right,bottom)
%macro DefPgtLayer1 6
	dd %1
	dd %2
	dw %3,%4,%5,%6
%endmacro

%macro DefPgtLayerEnd 0
	dd 0
	dd PgtLayer.BopNop|PgtLayer.FlagLast
	;dw 0,0,0,0 <- these are technically ignored anyway
%endmacro
*/



////////////////////////////////////////////////////////////////////////////////

public import pgfx.pgfxdefsext;

////////////////////////////////////////////////////////////////////////////////
