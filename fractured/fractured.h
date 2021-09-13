/**
File: fractured.h
Since: 2005-11-30
*/

#pragma once

#ifndef fracture_h
#define fracture_h

#pragma warning(disable:4482) // nonstandard extension used: enum 'xxx' used in qualified name (added for VS2005)

#include "basictypes.h"
#include <tchar.h> // for Unicode TCHAR

union FracturedMatrix {
	// Note these are arranged in normal order
	// unlike OpenGL's downward matrix
	// (which is better and why?)
	double matrix[16];
	double matrix2d[4][4];
	struct {
		// These aliases should reduce any
		// chaos if they are changed later.
		// Scale, shear, and translation are
		// supported. Rotation is implemented
		// as simultaneous shearing.
		double
			scalex,	shearx, x2,		transx,
			sheary, scaley, y2,		transy,
			z0,		z1,		scalez,	transz,
			w0,		w1,		w2,		w3;
	};
};

union FracturedColorMatrix {
	float matrix[25];
	float matrix2d[5][5];
	struct {
		// These aliases should reduce any
		// chaos if they are changed later.
		// r=red, g=green, b=blue, a=alpha
		float
			scaler,	r1,		r2,		r3,		transr,
			g0,		scaleg,	g2,		g3,		transg,
			b0,		b1,		scaleb, b3,		transb,
			a0,		a1,		a2,		scalea,	transa,
			w0,		w1,		w2,		w3,		w4;
	};
};

// A little simpler and more limited than the extendable MS bitmap format
// which supports variable bitmasks and gamma information.
// Some unique images are possible though with this that are not with
// bitmaps, like 2 component float direction vectors. Though the
// possibilities are numerous, realistically, each layer need only
// support 8bit mono/indexed, 32bit true color, or single float.
struct FracturedCanvas {
	void* pixels; // pixel data in linear format (standard top down, left to right)
	int width;
	int height;
	int wrap;	// byte wrap between rows; typically = bipp * width / 8 (but CAN be different for alignment needs)
	union {
		int32 format;
		struct {
			int8 bipp;	/// bits per pixel
			int8 bipc;	/// bits per component (8 for 256 shades, 16 for quality, 32 for HDR)
			int8 cpp;	/// components per pixel (1 for monochrome, 2 for complex numbers, 4 for BGRA)
			int8 ctype;	/// component type (indexed int / brightness int / float / exponential / alpha ...?)
			// Yes, one of the above is redundant and could be figured from the other two
			// (assuming all the bits of a word were always used), but it's easier on the filter.
			// The main limitation of implementing them as above is that all channels
			// have the same bitdepth. So you couldn't have 3 chroma channels of
			// 5 bits each with 1 alpha bit.
		};
	};
	#define MakeFormat(type,bipc,cpp) ((bipc)*(cpp))|((bipc)<<8)|((cpp)<<16)|(type<<24)
	enum Formats {
		Mask = 0xFFFFFFFF, /// uses all bits for now, but if more attributes are added later, may be useful
		MaskBipp = 0x000000FF,
		MaskBipc = 0x0000FF00,
		MaskCpp = 0x00FF0000,
		MaskCtype = 0xFF000000,
		CtypeUint = 1,	/// unsigned integer (common 0-255)
		CtypeSint = 2,	/// signed integer (uncommon for images but useful for vectors)
		CtypeFloat = 3,	/// floating point value (float or double)
		u8 =		MakeFormat(CtypeUint,8,1),	/// monochrome 256 shade grayscale (common)
		u8x4 =		MakeFormat(CtypeUint,8,4),	/// true color with 16mil plus alpha (common)
		s8x2 =		MakeFormat(CtypeSint,8,2),	///  small gradient map
		u16 =		MakeFormat(CtypeUint,16,1),	///  monochrome 65536 shade grayscale
		s16 =		MakeFormat(CtypeSint,16,1),	///  signed heightfield
		s16x2 =		MakeFormat(CtypeSint,16,2),	///  signed warp map
		f32 =		MakeFormat(CtypeFloat,32,1),	/// floating point depth component (common)
		f32x2 =		MakeFormat(CtypeFloat,32,2),	/// floating point complex number (common)
		f32x3 =		MakeFormat(CtypeFloat,32,3),	///  floating point high dynamic range
	};
	#undef MakeFormat

	/* transformations
	-While these three components (matrix, inverse, and scalars)
	 are actually redundant, they make the filters' jobs much easier
	 by having the transformations available in whatever form they
	 can best use (without needing to convert to another).
	 For example, the Lsystem filter can utilize the matrix while
	 the Mandelbrot set can better use the inverse.
	-Scalars are also more intuitive to the user than an obscure matrix.
	-Only some of these may actually used by a filter. For example,
	 origin z makes no sense for cellular automata (which are 2D).
	 However, it might make sense for some of the complex fractals.
	-By putting these directly here rather than as a post process,
	 the resolution is significantly higher (no bicubic
	 interpolation needed by an image editor afterward). Plus,
	 you don't have the blank edges you otherwise would have.
	*/
	double scalex, scaley, scalez;	// scale/zoom
	double origx, origy, origz;		// center origin
	double angle;					// standard 0-360
	double shearx, sheary;			// shear
	FracturedMatrix matrix;
	FracturedMatrix inverse;

	// maybe also add...
	// grouped layer (to composite a few together)
	// dependent layer (to chain one's output directly to another's input)

	////////////////////////////////////////
	FracturedCanvas();
	void init(int width_, int height_, int type_);
	void free();
	void matrixCalc(); /// calculates the transformation matrix from values above
};


/// abstract painter that all others are based on
class FracturedPainter {
public:
	/** Convenient union for setting filter variables.
	This holds no type information because
	that is obtained from the varinfo.
	*/
	union Value {
		int i; float f; char* sa; wchar_t* sw;
		#ifdef UNICODE
		wchar_t* s;
		#else
		char* s;
		#endif
		Value() {}; // nice, fast, efficient empty constructor
		Value(float f_) : f(f_) {};
		Value(int i_) : i(i_) {};
		//FracturedPainterValue(char* s_) : s(s_) {}; // force T("") and Unicode for now
		Value(wchar_t* sw_) : sw(sw_) {};
	};

	/** Variable id and value pair for setting filter variables.
	-When you know the exact painter class, you can just call the appropriate
	methods to set variables, but this abstraction is very useful for user
	interface and state storing/loading code because they have a universal
	means to communication variables without needing to know each
	type of class.
	-The last entry in an array of these must have id = 0.
	*/
	struct Var {
		int id; /// unique id of variable being set
		Value value;
	};

	/// -The filter returns a list of canvas types it supports.
	///  The last entry has all members zero to indicate end the list.
	/// -Every filter must support at least one and of any size.
	///  (yes, optimizations are possible with fixed sizes, but
	///   they are simply too limiting)
	/// -Any necessary color/bitdepth conversions will be
	///  performed automatically before combining a layer
	///  with others.
	/// -Always put the desired optimal canvas type first in the list.
	///  Complex fractals can draw to bytes, but floats are much better
	///  Cellular automata require at least 8bits of precision, but float
	///  would just be a waste of CPU.
	union CanvasInfo { // copied directly from FracturedCanvas
		int32 format;
		struct {
			int8 bipp;	/// bits per pixel
			int8 bipc;	/// bits per component (8 for 256 shades, 16 for quality, 32 for HDR)
			int8 cpp;	/// components per pixel (1 for monochrome, 2 for complex numbers, 4 for BGRA)
			int8 ctype;	/// component type (indexed int / brightness int / float / exponential / alpha ...?)
			// yes, one of the above is redundant and could be figured from the other two
			// (assuming all the bits of a word were always used), but it's easier on the filter.
		};
		/// hopefully your compiler is smart enough to realize that
		/// with such simple constructors, it is possible to declare
		/// static constants directly in the executable without initialization.
		CanvasInfo(int format_) : // format from FracturedCanvas::Formats
			format(format_) {};
		CanvasInfo() : // put end of list to terminate
			bipp(0), bipc(0), cpp(0), ctype(0) {};
		CanvasInfo(int ctype_, int bipc_, int cpp_) : 
			bipp(bipc_ * cpp_), bipc(bipc_), cpp(cpp_), ctype(ctype_) {};
		CanvasInfo(int ctype_, int bipp_, int bipc_, int cpp_) :
			bipp(bipp_), bipc(bipc_), cpp(cpp_), ctype(ctype_) {};
	};

	/** Information about a variable.
	-Sufficient information is available to store/load a value and show the user
	what the variable's purpose is.
	*/
	struct VarInfo {
		/// Short string name without spaces (like iterations, bail_out...) suitable
		/// for writing key/value pairs to a text file.
		/// Must never change once decided. Otherwise later versions may be unable
		/// to read earlier files.
		TCHAR* name;
		/// Display name of variable (like Iterations, Bail-out, Saturation...).
		/// May change later. May vary according to language.
		/// If null, it can be derived from the case decorated name.
		TCHAR* label;
		/// Longer description of variable's purpose (few sentences).
		/// State any assumptions and tell what difference low verse
		/// high values make in rendering.
		TCHAR* description;
		/// Unique id of variable being set - only meant for internal use.
		/// They are usually contiguous (but need not be).
		/// Different painters have completely different ids for a similar variable.
		/// The values are not static between program versions (but the name is).
		int id;
		int type; /// the variable data type (int, float, string...)

		Value def; /// default value (like bail out = 4)
		Value low; /// low value
		Value high; /// high value
		enum {
			TypeEol=0, /// indicates end of list
			//TypeNone, /// no type given but entry exists
			TypeBool, /// true,false; yes,no
			TypeInt, /// integer signed
			TypeFloat, /// floating point
			TypeDouble, /// double precision
			TypeList, /// list of choices (like palette type RGB, HSL, Grey...)
			TypeString, /// editable array of characters
			TypeLabel, /// informational string, not editable
			TypeAction, /// an action specific to the filter (like Reset)
			TypeMask=255,
			//TypeSection, /// section divider, for grouping properties
			//TypeSubsection, /// separator, just for user's visual benefit

			TypeClamped=1<<8, /// numeric value is clamped
			TypeCyclic=1<<9, /// numeric value wraps at ends (like 0 to 359 for degrees)
			TypeDisabled=1<<10, /// property is not relevant to current mode/species
			
		};
		struct ListEntry { // id/title pairs for TypeList
			int id;
			TCHAR* title;
		};
	};

public:
	// declare the standard interface methods (abstract)
	virtual int draw(FracturedCanvas* fc, FracturedCanvas* fcin, int (*progress)(void* self, int current, int total)) = nullptr;
	virtual int next (FracturedCanvas* fcin) = nullptr;	/** animate next frame (used by cellular automata, reaction diffusion) */
	virtual int init() = nullptr;	/** load default values */
	virtual int load(Var* vars) = nullptr;	/** load values into filter*/
	virtual int store(Var** vars) = nullptr;	/** store values from filter (serializing if necessary?) */
	virtual const void* supports(int element) = nullptr;	/** query information like which canvasses are supported */
	static const void* supportsStatic(int element);	/** query information like which canvasses are supported */

	#define FracturedPainter_StdMthds \
		virtual int draw(FracturedCanvas* fc, FracturedCanvas* fcin, int (*progress)(void* self, int current, int total));\
		virtual int next (FracturedCanvas* fcin);	/** animate next frame (used by cellular automata, reaction diffusion) */\
		virtual int init();	/** load default values */\
		virtual int load(Var* vars);	/** load values into filter*/\
		virtual int store(Var** vars);	/** store values from filter (serializing if necessary?) */\
		virtual const void* supports(int element);	/** query information like which canvasses are supported */\
		static const void* supportsStatic(int element);	/** query information like which canvasses are supported */

	/*
	virtual int draw(FracturedCanvas* fc, FracturedCanvas* fcin, int (*progress)(void* self, int current, int total)) = nullptr;	/// draw onto canvas
	virtual int next (FracturedCanvas* fcin) = nullptr;	/// animate next frame (used by cellular automata, reaction diffusion)
	virtual int init() = nullptr;	/// load default values
	virtual int load(void* vars) = nullptr;	/// load values into filter
	virtual int store(void** vars) = nullptr;	/// store values from filter, serializing if necessary
	virtual const void* supports(int element) = nullptr;	/// query information like which canvasses are supported
	*/
	virtual ~FracturedPainter() {};
	//void* supportsStatic(int element);	/// query information like which canvasses are supported

	int static dummyProgress(void* self, int current, int total);

	enum Supports {
		SupportsCanvas, /// get canvas size/types supported
		SupportsLayerFlags, /// get flags for layer
		SupportsVars, /// list of configurable parameters/variables
		SupportsVarsSpecie, /// additional/overlaid parameters specific to current specie
	};

	int specie;	/// exact specie of the class (like the mandelbrot or julia of the complex class)

	// here on is specific to the subclass ...
};


// Layers consist of a painter that paints the contents,
// a canvas (pixels) to paint into, and blending flags that
// specify how to blend this layer with others.
struct FracturedLayer {
	int id; /// unique autoincrementing id that never changes
	/// Recommend using the simple formula (GetTickCount + layer index)
	/// so that each layer will be different.
	FracturedCanvas canvas; /// destination for the painter to paint into (maybe cached or discardable)
	FracturedPainter* painter; /// draws into the layer's canvas (only one per layer)
	int mode;		/// blending mode with lower layers
	enum {
		ModeOpaque,
		ModeTrans,
		ModeAdd,
		ModeMultiply,
	};
	int flags;			/// informational flags
	enum {
		FlagModified=1<<0,	/// needs redrawing by filter
		FlagFilter=1<<1,	/// is a filter, operating on another layer as input and drawing into this one
		FlagPointOperator=1<<2, /// indicates filter can use same source and destination (for simple operations like brightness, but not smoothing)
		FlagSelected=1<<3,	/// useful to UI, not renderer
		FlagPreserve=1<<4,	/// keep layer pixels, never discard (upon storing or loading)
		FlagSlow=1<<5,	/// the painter is slow so cache the canvas pixels (redrawing would be too slow otherwise) 
		FlagAnimated=1<<6,	/// painter supports multiple iterations (like Conway's Life or reaction diffusion)
		FlagLowColor=1<<7,	/// few colors so pick a default palette accordingly (like many Cellular automata)
	};


	void render(FracturedLayer* layers, int count, FracturedCanvas* bg, int (*progress)(void* self, int current, int total));

	FracturedLayer() : painter(nullptr) {};
};


union FracturedPixel {
	uint8 u8;
	struct {uint8 b,g,r,a;} u8x4;
	struct {int8 x,y;} s8x2;
	uint16 u16;
	int16  s16;
	struct {int16 x,y;} s16x2;
	float f32;
	struct {float x,y;} f32x2;
	union {struct {float x,y,z;}; struct {float r,g,b;};} f32x3;
};


union FracturedPaletteEntry {
	struct {uint8 b,g,r,a;};
	uint32 u32;
};


union FracturedVector2d {
	double v[2];
	struct {double x,y;};
};


union FracturedPixelPtr {
	void* p;
	uint8* u8;
	struct {uint8 b,g,r,a;}* u8x4;
	struct {int8 x,y;}* s8x2;
	uint16* u16;
	int16*  s16;
	struct {int16 x,y;}* s16x2;
	uint32* u32;
	float* f32;
	struct {float x,y;}* f32x2;
	union {struct {float x,y,z;}; struct {float r,g,b;};}* f32x3;
};


// The families of supported fractals.
// Do not change the order of these constants, only
// add more to them. Once they are stored to a file,
// they must be read back the same.
struct FracturedFamily {
// Declared inside a struct because tarded C++ brings
// all the members up into the global namespace.
// That's just stoopid.
enum {
	nop,		// uhm, nothing
	complex,	// complex numbers like Mandelbrot and Julia
	perlin,		// Perlin noise
	plasma,		// recursive plasma
	ifs,		// iterated function system
	flame,		// flame algorithm (maybe should be merged with above)
	diffusion,	// reaction diffusion
	lsystem,	// simple repetitive Lindenmeyer systems
	automata,	// cellular automata (like life)
	image,		// simply a loaded raster image
	life,
};
};


#if defined(_DEBUG) && !defined(dbgbreak)
#define dbgbreak(expr) if (expr) {_asm{int 3}};
#endif

#endif
