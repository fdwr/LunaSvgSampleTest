/**
File: PaintConvert.cpp
Since: 2006-03-15
Remark: Image type conversions (8bit to true color, vector to angle).
*/

#include "PaintConvert.h"
#include <stdlib.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include <float.h>
#include <assert.h>

////////////////////////////////////////////////////////////////////////////////

enum { // MUST be contiguous, not sparse
	VarConvertSpecie,
	VarConvertTotal,
};

const static FracturedPainter::VarInfo varConvertInfo[] = {
	{	T("format_converter"), T("Format converter"),
		T("Converts a canvas pixel format to another kind."),
		-1, FracturedPainter::VarInfo::TypeLabel,
		0, 0,0
	},
	{	T("specie"), T("Specie"),
		T("Type of conversion."),
		VarConvertSpecie, FracturedPainter::VarInfo::TypeInt,
		PaintConvert::SpecieU8scale, 0,PaintConvert::SpecieTotal-1,
	},
	/*
	{	T("bail_out"), T("Bail out"),
		T("For divergent fractals (like Mandelbrot) this prevents ")
		T("unnecessary calculation by stopping once the iteration reaches a certain ")
		T("distance from the origin."),
		VarBailOut, FracturedPainter::VarInfo::TypeFloat,
		4.f, 0.f,FLT_MAX,
	},
	*/
	{	nullptr, nullptr,nullptr,	 0, 0,	 0, 0,0
	}
};


// private functions (these are useful enough, maybe should they be public?)

static private void HslToRgb( float hsl[3], float rgb[3], int wrapping );
static private void HsvToRgb( float hsv[3], float rgb[3], int wrapping );
static private void RgbToRgb( float hsv[3], float rgb[3], int wrapping );


#pragma warning(disable:4244) // conversion from 'double' to 'float', possible loss of data

static const FracturedPainter::CanvasInfo convertCanvasInfo[] = 
{
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u8 ),
	FracturedPainter::CanvasInfo()
};


PaintConvert::PaintConvert()
{
	specie = SpecieU8wrap;
	init();
}


PaintConvert::PaintConvert(int specie_)
{
	//if (specie_ >= SpecieTotal) specie_ = SpecieU8wrap;
	specie = specie_;
	init();
}


int PaintConvert::init()
{

	// do species specific initialization
	switch (specie) {
	case SpecieU8clip:
	case SpecieU8wrap:
	case SpecieU8scale:
	case SpecieU8scaleUnit:
	case SpecieU8angle:
	case SpecieF32clip:
	case SpecieF32wrap:
	case SpecieF32scale:
	case SpecieF32scaleUnit:
	case SpecieF32angle:
	break;
	}
	return 0;
}


int PaintConvert::draw (FracturedCanvas* fc, FracturedCanvas* fcin, int (*progress)(void* self, int current, int total))
{
	// copy code from paintpalette
	return 0;
}


int PaintConvert::next(FracturedCanvas* fcin)
{
	return 0;
}


int PaintConvert::load(Var* parms)
{
	return 0;
}


int PaintConvert::store(Var** parms)
{
	return 0;
}


const void* PaintConvert::supports (int element)
{
	return supportsStatic(element);
}

const void* PaintConvert::supportsStatic(int element)
{
	switch (element) {
	case SupportsCanvas:
		return convertCanvasInfo;

	case SupportsLayerFlags:
		{
			const static int flags = FracturedLayer::FlagSlow;
			return &flags;
		}
		break;
	default:
		return nullptr;
	}
}


////////////////////////////////////////////////////////////////////////////////

enum { // MUST be contiguous, not sparse
	VarPaletteSpecie,
	VarPaletteTotal,
};

const static FracturedPainter::VarInfo varPaletteInfo[] = {
	{	T("palette_converter"), T("Palette converter"),
		T("Maps monochromatic to colored using palette, or remaps ")
		T("colors intensities using palette."),
		-1, FracturedPainter::VarInfo::TypeLabel,
		0, 0,0
	},
	{	T("specie"), T("Specie"),
		T("Type of palette."),
		VarPaletteSpecie, FracturedPainter::VarInfo::TypeInt,
		PaintPalette::SpecieRgba, 0,PaintPalette::SpecieTotal-1,
	},
	/*
	{	T("bail_out"), T("Bail out"),
		T("For divergent fractals (like Mandelbrot) this prevents ")
		T("unnecessary calculation by stopping once the iteration reaches a certain ")
		T("distance from the origin."),
		VarBailOut, FracturedPainter::VarInfo::TypeFloat,
		4.f, 0.f,FLT_MAX,
	},
	*/
	{	nullptr, nullptr,nullptr,	 0, 0,	 0, 0,0
	}
};

static const FracturedPainter::CanvasInfo paletteCanvasInfo[] = 
{
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u8x4 ),
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u8 ),
	FracturedPainter::CanvasInfo()
};

PaintPalette::PaintPalette()
{
	specie = SpecieRgba;
	init();
}


PaintPalette::PaintPalette(int specie_)
{
	specie = specie_;
	init();
}


int PaintPalette::init()
{
	// do species specific initialization
	assert(SpecieTotal == 6); // to catch mismatch between header and here

	colorCount = 256;
	wrapping = WrappingMirror; //None;

	if (specie >= SpecieTotal || specie == SpecieNoInit) return 0;

	float const static defaultColors[][8] = {
		{0, 0,   0, 0,   0,0,   0,0}, /// reg,green,blue,alpha ranges
		{0, 255,   64, 192,   255,0,   255,255}, /// reg,green,blue,alpha ranges
		{0, 360,   .5, .5,   .75,1.0,   255,255}, /// hue,saturation,value,alpha ranges
		{0, 360,   .5, .5,   .75,1.0,   255,255}, /// hue,saturation,lightness,alpha ranges
		{0, 255,   64, 192,   255,0,   255,255}, /// cyan,magenta,yellow,alpha ranges
		{0, 95.7f,   0, 100,   0,108.8f,   255,255}, /// x,y,z,alpha
	};

	ranges.c1.low = defaultColors[specie][0];
	ranges.c1.high = defaultColors[specie][1];
	ranges.c2.low = defaultColors[specie][2];
	ranges.c2.high = defaultColors[specie][3];
	ranges.c3.low = defaultColors[specie][4];
	ranges.c3.high = defaultColors[specie][5];
	ranges.c4.low = defaultColors[specie][6];
	ranges.c4.high = defaultColors[specie][7];

	calcColors();
	return 0;
}


int PaintPalette::init(int specie_,
		float c1low, float c1high, float c2low, float c2high,
		float c3low, float c3high, float c4low, float c4high,
		int wrapping_
		)	/// initialize with given values (different according to species)
{
	specie = specie_;
	ranges.c1.low = c1low;
	ranges.c1.high = c1high;
	ranges.c2.low = c2low;
	ranges.c2.high = c2high;
	ranges.c3.low = c3low;
	ranges.c3.high = c3high;
	ranges.c4.low = c4low;
	ranges.c4.high = c4high;
	wrapping = wrapping_;

	calcColors();
	return 0;
}


int PaintPalette::draw (FracturedCanvas* fcd, FracturedCanvas* fcs, int (*progress)(void* self, int current, int total))
{
	int
		height = fcd->height,
		width  = fcd->width;
	int psType = fcs->format & FracturedCanvas::Formats::Mask,
		pdType = fcd->format & FracturedCanvas::Formats::Mask;

	FracturedPixelPtr ps, pd; // pixel source and pixel dest
	ps.p = fcs->pixels;
	pd.p = fcd->pixels;

	assert (height > 0 && width > 0 && ps.p != nullptr && pd.p != nullptr);

	for (int i=0; i < height; i++) {
		// convert row of pixels into destination pixel type
	
		switch (pdType) { // destination type
		case FracturedCanvas::Formats::u8:
			switch (psType) { // source canvas type
			case FracturedCanvas::Formats::u8: // monochromatic brightness remapping
				for (int j=0; j < width; j++) {
					pd.u8[j] = palette[ps.u8[j]].r;
				}
				break;
			case FracturedCanvas::Formats::f32: // monochromatic brightness remapping
				for (int j=0; j < width; j++) {
					float flum = abs(ps.f32[j]); // floating point luminance
					int lum1 = (int)flum & 255; // low luminance value
					int lum2 = (lum1+1) & 255; // high luminance value (clip or wrap?)
					#ifdef PaintPalette_UseLinear
					float t2 = fmod(flum, 1), t1 = 1-t2; // simple linear
					#else
					float t2 = fmod(flum,1); // get fractional part between luminances
					t2 = t2 * t2 * (3-2*t2); // s-curve interpolation, much smoother
					float t1 = 1-t2;
					#endif
					pd.u8[j] = (int)(palette[lum1].r * t1 + palette[lum2].r * t2);
				}
				break;
			case FracturedCanvas::Formats::u8x4: // down mapping from color to monochrome
				for (int j=0; j < width; j++) {
					pd.u8[j] = palette[ps.u8x4[j].r].r + palette[ps.u8x4[j].g].g + palette[ps.u8x4[j].b].b + palette[ps.u8x4[j].a].a;
				}
				break;
			}
			break;

		//case FracturedCanvas::Formats::u16:
		//	for (int j=0; j < width; j++) {
		//		p.u16[j] = rowValues[j].iterations;
		//	}
		//	break;
		//

		case FracturedCanvas::Formats::u8x4:
			switch (psType) { // source canvas type
			case FracturedCanvas::Formats::u8: // from monochrome to color
				for (int j=0; j < width; j++) {
					int lum = ps.u8[j]; // todo: change these constant shifts
					pd.u32[j] = (palette[lum].r << 16) | (palette[lum].g << 8) | (palette[lum].b << 0) | (palette[lum].a << 24);
				}
				break;
			case FracturedCanvas::Formats::f32: // from monochrome to color
				for (int j=0; j < width; j++) {
					float flum = abs(ps.f32[j]); // floating point luminance
					int lum1 = (int)flum & 255; // low luminance value
					int lum2 = (lum1+1) & 255; // high luminance value (clip or wrap?)
					#ifdef PaintPalette_UseLinear
					float t2 = fmod(flum, 1), t1 = 1-t2; // simple linear
					#else
					float t2 = fmod(flum,1); // get fractional part between luminances
					t2 = t2 * t2 * (3-2*t2); // s-curve interpolation, much smoother
					float t1 = 1-t2;
					#endif
					int
					color  = (int)(palette[lum1].r * t1 + palette[lum2].r * t2) << 16; // todo: change these constant shifts
					color |= (int)(palette[lum1].g * t1 + palette[lum2].g * t2) << 8;
					color |= (int)(palette[lum1].b * t1 + palette[lum2].b * t2) << 0;
					color |= (int)(palette[lum1].a * t1 + palette[lum2].a * t2) << 24;
					//color = (palette[lum1].r << 16) | (palette[lum1].g << 8) | (palette[lum1].b << 0) | (palette[lum1].a << 24);
					pd.u32[j] = color;
				}
				break;
			case FracturedCanvas::Formats::u8x4: // remaps each chroma to new brightness
				for (int j=0; j < width; j++) {
					int
					color  = (int)(palette[ps.u8x4[j].r].r) << 16; // todo: change these constant shifts
					color |= (int)(palette[ps.u8x4[j].g].g) << 8;
					color |= (int)(palette[ps.u8x4[j].b].b) << 0;
					color |= (int)(palette[ps.u8x4[j].a].a) << 24;
					pd.u32[j] = color;
				}
				break;
			}
			break;

		}

		ps.u8 += fcs->wrap;
		pd.u8 += fcd->wrap;

		if (!progress(this, i, height)) break;
	}

	return 0;
}


void PaintPalette::calcColors()
{
	void (*func)( float hsv[3], float rgb[3], int wrapping );

	switch (specie) {
	case SpecieNoInit:
		return;
	case SpecieRgba:
		func = &RgbToRgb;
		break;
	case SpecieHsva:
		func = &HsvToRgb;
		break;
	case SpecieHsla:
		func = &HslToRgb;
		break;
	case SpecieCmya:
		return;
		//func = &CmyToRgb;
		//break;
	case SpecieXyza:
		return;
		//func = &XyzToRgb;
		//break;
	default:
		return;
	//case SpecieTotal:
	}

	float c1low = ranges.c1.low,  c1dif = ranges.c1.high - c1low;
	float c2low = ranges.c2.low,  c2dif = ranges.c2.high - c2low;
	float c3low = ranges.c3.low,  c3dif = ranges.c3.high - c3low;
	float c4low = ranges.c4.low,  c4dif = ranges.c4.high - c4low;
	for (int i = 0; i < colorCount; i++) {
		float t = (float)i / colorCount;
		float rgb[3];
		float c123[3] = {t * c1dif + c1low, t * c2dif + c2low, t * c3dif + c3low};

		// color space conversion
		func( c123, rgb, wrapping);

		palette[i].r = rgb[0] * 255;
		palette[i].g = rgb[1] * 255;
		palette[i].b = rgb[2] * 255;
		palette[i].a = t * c4dif + c4low;
	}
}


static float wrapColorValue(float value, int wrapping) {
	/*
	Wrapping modes...
	In:	None:	Mirror:	Tile:
	-1.5	0.0	0.5	0.5
	-1.0	0.0	1.0	1.0
	-0.5	0.0	0.5	0.5
	 0.0	0.0	0.0	0.0
	 0.5	0.5	0.5	0.5
	 1.0	1.0	1.0	1.0
	 1.5	1.0	0.5	0.5
	 2.0	1.0	0.0	1.0
	 2.5	1.0	0.5	0.5
	*/

	switch (wrapping) {
	case PaintPalette::WrappingNone: // clamp range
		if (value < 0) value = 0;
		else if (value > 1) value = 1;
		break;
	case PaintPalette::WrappingMirror:
		// basically, if the value is 0-1, 2-3, 4-5... wrap normally into 0-1
		// but if 1-2, 3-4, 5-6 wrap backwards
		value = abs(value);
		if (value > 1) { // out of range, so wrap to double the range
			value = fmod(value,1*2);
			if (value > 1) // beyond 0-1 so mirror
				value = 2-value;
		}
		break;
	case PaintPalette::WrappingTile:
		if (value < 0) {
			value = 1-fmod(value,1); // wrap to 0-1 and correct negative
		} else if (value > 1) {
			value = fmod(value,1); // wrap to 0-1
			if (value == 0) value=1;
		}
		break;
	}
	return value;
}


static float wrapColorValue256(float value, int wrapping) {

	switch (wrapping) {
	case PaintPalette::WrappingNone: // clamp range
		if (value < 0) value = 0;
		else if (value > 255) value = 255; // or maybe 255.999...
		break;
	case PaintPalette::WrappingMirror:
		// basically, if the value is 0-255, 512-767... wrap into 0-255
		// but if 256-511, 768-1023 wrap backwards
		value = abs(value);
		if (value >= 256) { // out of range, so wrap to double the range
			value = fmod(value,256*2);
			if (value > 256) { // beyond 0-1 so mirror
				value = 512-value;
			} else if (value == 256) {
				value = 255;
			}
		}
		break;
	case PaintPalette::WrappingTile:
		if (value < 0) {
			value = 256-fmod(value,256); // wrap to 0-255 and correct negative
			if (value >= 256) value = 255;
		} else if (value > 255) {
			value = fmod(value,256); // wrap to 0-255
		}
		break;
	}
	return value;
}


// Modified from:  Foley, van Dam, Feiner, Hughes,
//		"Computer Graphics Principles and Practices,"
//		Additon-Wesley, 1990, pp592-593.
//
// h = 0-360;  s = 0-1;  v = 0-1
static void HsvToRgb( float hsv[3], float rgb[3], int wrapping )
{
	float h, s, v;			// hue, sat, value
	float r, g, b;			// red, green, blue
	float i, f, p, q, t;		// interim values

	// guarantee valid input:
	h = hsv[0] / 60.;
	if (h < 0)			h = 6+fmod(h,6);
	else if (h >= 6)	h = fmod(h,6); // h is always tiled regrardless of wrapping
	//while( h >= 6. )	h -= 6.;
	//while( h <  0. ) 	h += 6.;

	s = wrapColorValue(hsv[1], wrapping);

	v = wrapColorValue(hsv[2], wrapping);

	// if sat==0, then is a gray:
	if( s == 0.0 ) {
		rgb[0] = rgb[1] = rgb[2] = v;
		return;
	}

	// get an rgb from the hue itself:
	i = floor( h );
	f = h - i;
	p = v * ( 1. - s );
	q = v * ( 1. - s*f );
	t = v * ( 1. - ( s * (1.-f) ) );

	switch ( (int) i ) {
		case 0:	r = v;	g = t;	b = p;	break;
		case 1:	r = q;	g = v;	b = p;	break;
		case 2:	r = p;	g = v;	b = t;	break;
		case 3:	r = p;	g = q;	b = v;	break;
		case 4:	r = t;	g = p;	b = v;		break;
		case 5:	r = v;	g = p;	b = q;	break;
	}

	rgb[0] = r;
	rgb[1] = g;
	rgb[2] = b;
}

/* // alternate code from http://www.easyrgb.com/math.php?MATH=M1#text1
HSV —> RGB
 
if ( S == 0 )                       //HSV values = 0 ÷ 1
{
   R = V * 255
   G = V * 255
   B = V * 255
}
else
{
   var_h = H * 6
   if ( var_h == 6 ) var_h = 0      //H must be < 1
   var_i = int( var_h )             //Or ... var_i = floor( var_h )
   var_1 = V * ( 1 - S )
   var_2 = V * ( 1 - S * ( var_h - var_i ) )
   var_3 = V * ( 1 - S * ( 1 - ( var_h - var_i ) ) )

   if      ( var_i == 0 ) { var_r = V     ; var_g = var_3 ; var_b = var_1 }
   else if ( var_i == 1 ) { var_r = var_2 ; var_g = V     ; var_b = var_1 }
   else if ( var_i == 2 ) { var_r = var_1 ; var_g = V     ; var_b = var_3 }
   else if ( var_i == 3 ) { var_r = var_1 ; var_g = var_2 ; var_b = V     }
   else if ( var_i == 4 ) { var_r = var_3 ; var_g = var_1 ; var_b = V     }
   else                   { var_r = V     ; var_g = var_1 ; var_b = var_2 }

   R = var_r * 255                  //RGB results = 0 ÷ 255
   G = var_g * 255
   B = var_b * 255
   }
}
*/


static float HueToRgb( float v1, float v2, float vH )
{
   if ( vH < 0 ) vH += 1;
   if ( vH > 1 ) vH -= 1;
   if ( ( 6 * vH ) < 1 ) return ( v1 + ( v2 - v1 ) * 6 * vH );
   if ( ( 2 * vH ) < 1 ) return ( v2 );
   if ( ( 3 * vH ) < 2 ) return ( v1 + ( v2 - v1 ) * ( ( 2. / 3 ) - vH ) * 6 );
   return v1;
}

// modified from http://www.easyrgb.com/math.php?MATH=M1#text1
// h = 0-360;  s = 0-1;  v = 0-1
static void HslToRgb( float hsl[3], float rgb[3], int wrapping )
{
	/*
	float h = hsl[0] / 60.;
	if (h < 0)			h = 6+fmod(h,6);
	else if (h >= 6)	h = fmod(h,6); // h is always tiled regrardless of wrapping
	*/
	float h = hsl[0] / 360.;
	if (h < 0)			h = 1+fmod(h,1);
	else if (h >= 1)	h = fmod(h,1); // h is always tiled regrardless of wrapping

	float s = wrapColorValue(hsl[1], wrapping);

	float L = wrapColorValue(hsl[2], wrapping);

	if ( s == 0 ) {	//HSL values = 0 ÷ 1
		rgb[0] = L;	//RGB results = 0 ÷ 1
		rgb[1] = L;
		rgb[2] = L;
	} else {
		float var_2 = (L < 0.5)  ?  L * (1+s)  :  (L+s) - (s*L);
		float var_1 = 2 * L - var_2;
		rgb[0] = HueToRgb( var_1, var_2, h + ( 1. / 3 ) );
		rgb[1] = HueToRgb( var_1, var_2, h );
		rgb[2] = HueToRgb( var_1, var_2, h - ( 1. / 3 ) );
	} 
}


static void RgbToRgb( float rgbin[3], float rgbout[3], int wrapping )
{
	rgbout[0] = wrapColorValue256(rgbin[0], wrapping);
	rgbout[1] = wrapColorValue256(rgbin[1], wrapping);
	rgbout[2] = wrapColorValue256(rgbin[2], wrapping);
}


int PaintPalette::next(FracturedCanvas* fcin)
{
	return 0;
}


int PaintPalette::load(Var* parms)
{
	return 0;
}


int PaintPalette::store(Var** parms)
{
	return 0;
}


const void* PaintPalette::supports (int element)
{
	return supportsStatic(element);
}

const void* PaintPalette::supportsStatic(int element)
{
	switch (element) {
	case SupportsCanvas:
		return paletteCanvasInfo;

	case SupportsLayerFlags:
		{
			const static int flags = 0; //FracturedLayer::FlagSlow;
			return &flags;
		}
		break;
	default:
		return nullptr;
	}
}


/*
Reference formulas from http://www.easyrgb.com/math.php?MATH=M1#text1

XYZ —> RGB
 
 
//Observer = 2°, Illuminant = D65
var_X = X / 100        //Where X = 0 ÷  95.047
var_Y = Y / 100        //Where Y = 0 ÷ 100.000
var_Z = Z / 100        //Where Z = 0 ÷ 108.883

var_R = var_X *  3.2406 + var_Y * -1.5372 + var_Z * -0.4986
var_G = var_X * -0.9689 + var_Y *  1.8758 + var_Z *  0.0415
var_B = var_X *  0.0557 + var_Y * -0.2040 + var_Z *  1.0570

if ( var_R > 0.0031308 ) var_R = 1.055 * ( var_R ^ ( 1 / 2.4 ) ) - 0.055
else                     var_R = 12.92 * var_R
if ( var_G > 0.0031308 ) var_G = 1.055 * ( var_G ^ ( 1 / 2.4 ) ) - 0.055
else                     var_G = 12.92 * var_G
if ( var_B > 0.0031308 ) var_B = 1.055 * ( var_B ^ ( 1 / 2.4 ) ) - 0.055
else                     var_B = 12.92 * var_B

R = var_R * 255
G = var_G * 255
B = var_B * 255 
 



HSL —> RGB

if ( S == 0 )                       //HSL values = 0 ÷ 1
{
   R = L * 255                      //RGB results = 0 ÷ 255
   G = L * 255
   B = L * 255
}
else
{
   if ( L < 0.5 ) var_2 = L * ( 1 + S )
   else           var_2 = ( L + S ) - ( S * L )

   var_1 = 2 * L - var_2

   R = 255 * Hue_2_RGB( var_1, var_2, H + ( 1 / 3 ) ) 
   G = 255 * Hue_2_RGB( var_1, var_2, H )
   B = 255 * Hue_2_RGB( var_1, var_2, H - ( 1 / 3 ) )
} 


--------------------------------------------------------------------------------

Hue_2_RGB( v1, v2, vH )             //Function Hue_2_RGB
{
   if ( vH < 0 ) vH += 1
   if ( vH > 1 ) vH -= 1
   if ( ( 6 * vH ) < 1 ) return ( v1 + ( v2 - v1 ) * 6 * vH )
   if ( ( 2 * vH ) < 1 ) return ( v2 )
   if ( ( 3 * vH ) < 2 ) return ( v1 + ( v2 - v1 ) * ( ( 2 / 3 ) - vH ) * 6 )
   return ( v1 )
}
 


HSV —> RGB
 
if ( S == 0 )                       //HSV values = 0 ÷ 1
{
   R = V * 255
   G = V * 255
   B = V * 255
}
else
{
   var_h = H * 6
   if ( var_h == 6 ) var_h = 0      //H must be < 1
   var_i = int( var_h )             //Or ... var_i = floor( var_h )
   var_1 = V * ( 1 - S )
   var_2 = V * ( 1 - S * ( var_h - var_i ) )
   var_3 = V * ( 1 - S * ( 1 - ( var_h - var_i ) ) )

   if      ( var_i == 0 ) { var_r = V     ; var_g = var_3 ; var_b = var_1 }
   else if ( var_i == 1 ) { var_r = var_2 ; var_g = V     ; var_b = var_1 }
   else if ( var_i == 2 ) { var_r = var_1 ; var_g = V     ; var_b = var_3 }
   else if ( var_i == 3 ) { var_r = var_1 ; var_g = var_2 ; var_b = V     }
   else if ( var_i == 4 ) { var_r = var_3 ; var_g = var_1 ; var_b = V     }
   else                   { var_r = V     ; var_g = var_1 ; var_b = var_2 }

   R = var_r * 255                  //RGB results = 0 ÷ 255
   G = var_g * 255
   B = var_b * 255
   }
}

 

CMY —> RGB
  
//CMY values = 0 ÷ 1
//RGB values = 0 ÷ 255

R = ( 1 - C ) * 255
G = ( 1 - M ) * 255
B = ( 1 - Y ) * 255
 

 

*/
