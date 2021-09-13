// Convert.asm - conversion functions from one image pixel data to another
//
// 20040815 Dwayne Robinson

#ifndef CONVERT_H
#define CONVERT_H
#ifndef CONVERT_ASM

extern void ConvertRgbToBgr(void* dest, void *src, int count);

#endif
#endif

#ifdef CONVERT_ASM

	%macro gsym 1
	  global _%1
	  _%1:
	  global %1
	  %1:
	%endmacro

	%macro enumnew 0
	  %assign enumvalue 0
	%endmacro

	%macro enumnew 1
	  %assign enumvalue %1
	%endmacro

	%macro enum 1
	  %define %1 enumvalue
	  %assign enumvalue enumvalue+1
	%endmacro

	%macro enum 2
	  %define %1 %2
	  %assign enumvalue %2+1
	%endmacro

	enum PixelType_LE1,0
	enum PixelType_BE1		// black and white
	enum PixelType_LE2
	enum PixelType_BE2		// 4 color
	enum PixelType_LE4
	enum PixelType_BE4		// 16 color
	enum PixelType_LE8
	enum PixelType_BE8		// 256 color
	enum PixelType_LE16
	enum PixelType_BE16		// raw 16bit
	enum PixelType_LE32
	enum PixelType_BE32		// raw 32bit
	enum PixelType_BGRA5551
	enum PixelType_RGBA5551	// 15bit with 1bit alpha
	enum PixelType_BGR565
	enum PixelType_RGB565	// 16bit
	enum PixelType_BGR888
	enum PixelType_RGB888	// 24bit
	enum PixelType_BGRA8888
	enum PixelType_RGBA8888	// 32bit with alpha

#else

enum {	PixelType_LE1,		PixelType_BE1,		// black and white
		PixelType_LE2,		PixelType_BE2,		// 4 color
		PixelType_LE4,		PixelType_BE4,		// 16 color
		PixelType_LE8,		PixelType_BE8,		// 256 color
		PixelType_LE16,		PixelType_BE16,		// raw 16bit
		PixelType_LE32,		PixelType_BE32,		// raw 32bit
		PixelType_BGRA5551,	PixelType_RGBA5551,	// 15bit with 1bit alpha
		PixelType_BGR565,	PixelType_RGB565,	// 16bit
		PixelType_BGR888,	PixelType_RGB888,	// 24bit
		PixelType_BGRA8888,	PixelType_RGBA8888	// 32bit with alpha
};
#define PixelType_Last 20

//#ifdef __CPLUSPLUS

extern ConvertFormatFrom(dest, src, count, format, alpha);
extern ConvertFormatTo(dest, src, count, format, alpha);
extern ConvertRgbToIndexed(dest, src, count, pal);
extern ConvertIndexedToRgb(dest, src, count, pal);


#endif
