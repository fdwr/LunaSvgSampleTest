/**
File: PaintConvert.h
Since: 2006-03-15
Remark: Image type conversions (8bit to true color, vector to angle).

*** barely started ***
*/

#include "fractured.h"

class PaintConvert : public FracturedPainter {
public:
	FracturedPainter_StdMthds; // define standard methods here (in fractured.h)

	////////////////////
	PaintConvert();
	PaintConvert(int species_);

	////////////////////

	////////////////////
	enum Species {
		/*
		clip - clips ends to new range (u16 to u8 would clip anything > 255 to 255)
		scale - rescale old range to new range (u16 to u8 rescales 0-65535 to 0-255)
		scaleUnit - same as scale for ints, but rescales floats 0-1 to 0-256
		wrap - old range modulus new range (u16 to u8 wraps anything > 255 to 0-255)
		angle - vector to angle (not degrees! utilizes full range if integral, 0-1 if float)
		*/
		SpecieU8clip,
		SpecieU8wrap,
		SpecieU8scale,
		SpecieU8scaleUnit,
		SpecieU8angle,
		SpecieF32clip,
		SpecieF32wrap,
		SpecieF32scale,
		SpecieF32scaleUnit,
		SpecieF32angle,
		SpecieTotal,
	};

private:
};


class PaintPalette : public FracturedPainter {
public:
	FracturedPainter_StdMthds; // define standard methods here (in fractured.h)
	int init(int specie_);	/// initialize with default values for specie
	int init(int specie_,
		float c1low, float c1high, float c2low, float c2high,
		float c3low, float c3high, float c4low, float c4high,
		int wrapping_);	/// initialize with given values (different according to species)

	void calcColors(); /// (re)builds the color table (palette) given the type and ranges

	////////////////////
	PaintPalette();	/// initialize default rgb
	PaintPalette(int specie_);	/// initialize with default values for specie

	////////////////////
	FracturedPaletteEntry palette[256]; /// fixed size
	int colorCount; /// number of colors actually in palette (always <= array size)
	int wrapping;	/// should wrap at ends
	enum {
		WrappingMirror, /// mirror edges back around so smoothly cyclicle
		WrappingNone, /// no wrapping at ends (so clamp range instead)
		WrappingTile, /// wrap edges so cyclicle (but may have discontinuity)
	};

	/// ranges for color generation with many aliases for convenience
	/// The intepretation of the values depend on the type of palette.
	/// For rgba, red is 0-255. For hsva, hue is 0-360 while saturation is 0-1.
	struct ComponentRange { float low, high; };
	union {
		ComponentRange range[4];
		struct {
			union {ComponentRange c1;	ComponentRange red;	ComponentRange hue; ComponentRange cyan; ComponentRange x;};
			union {ComponentRange c2;	ComponentRange green;	ComponentRange saturation; ComponentRange magenta; ComponentRange y;};
			union {ComponentRange c3;	ComponentRange blue;	ComponentRange value; ComponentRange lightness; ComponentRange yellow; ComponentRange z;};
			union {ComponentRange c4;	ComponentRange alpha;};
		};
	} ranges;

	////////////////////
	enum Species {
		// look at http://www.easyrgb.com/math.php?MATH=M21#text21 (20060315)
		// for conversion formulas
		// beware of changing the order of these!
		SpecieNoInit,	/// special value that says to initialize later
		SpecieRgba, /// reg,green,blue,alpha ranges
		SpecieHsva, /// hue,saturation,value,alpha ranges
		SpecieHsla,	/// hue,saturation,lightness,alpha ranges
		SpecieCmya,	/// cyan,magenta,yellow,alpha ranges
		SpecieXyza,	/// x,y,z,alpha
		SpecieTotal,
	};

private:
};
