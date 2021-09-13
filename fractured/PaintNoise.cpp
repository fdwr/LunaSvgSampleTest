/**
File: PaintNoise.cpp
Since: 2005-11-30
Remark: Noise functions like Perlin and Plasma.
*/

#include "PaintNoise.h"
#include <math.h>

////////////////////////////////////////////////////////////////////////////////

enum { // MUST be contiguous, not sparse
	VarPerlinTotal,
};

const static FracturedPainter::VarInfo varPerlinInfo[] = {
	{	T("perlin_noise"), T("Perline Noise"),
		T("Interpolated noise can yield dozens of effects. ")
		T("Search for Ken Perlin for more information."),
		-1, FracturedPainter::VarInfo::TypeLabel,
		0, 0,0
	},
	{	nullptr, nullptr,nullptr,	 0, 0,	 0, 0,0
	}
};

static const FracturedPainter::CanvasInfo perlinCanvasInfo[] = 
{
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u8 ),
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u16 ),
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::f32 ),
	FracturedPainter::CanvasInfo()
};

int PaintPerlin::init()
{
	return 0;
}


int PaintPerlin::draw(FracturedCanvas* fs, FracturedCanvas* fsin, int (*progress)(void* self, int current, int total))
{
	FracturedVector2d v = {0,0};
	double
		dx = fs->inverse.scalex,
		dy = fs->inverse.scaley,
		dz = fs->inverse.scalez;

	int
		height = fs->height,
		width = fs->width;
	int pixelFormat = fs->format & FracturedCanvas::Formats::Mask;
	FracturedPixelPtr p; // pointer for row, and for column

	// simply march top down, left to right
	p.p = fs->pixels;
	for (int i=0; i < height; i++) {
		v.x=0;

		switch (pixelFormat) {
		case FracturedCanvas::Formats::u8:
			for (int j=0; j < width; j++, v.x += dx) {
				p.u8[j] = int( PerlinNoise2(v.v) * 128 + 128);
			}
			break;

		case FracturedCanvas::Formats::u16:
			for (int j=0; j < width; j++, v.x += dx) {
				p.u16[j] = (uint16) (PerlinNoise2(v.v) * 32768 + 32768);
			}
			break;

		case FracturedCanvas::Formats::f32:
			if (dz == 1) {
				for (int j=0; j < width; j++, v.x += dx) {
					p.f32[j] = (float) PerlinNoise2(v.v);
				}
			} else {
				for (int j=0; j < width; j++, v.x += dx) {
					p.f32[j] = (float) (PerlinNoise2(v.v) * dz);
				}
			}
			break;
		}
		p.u8 += fs->wrap;
		v.y += dy;

		if (!progress(this, i, height)) break;
	}
	return 0;
}


int PaintPerlin::next (FracturedCanvas* fcin)
{
	return 0;
}


int PaintPerlin::load(Var* parms)
{
	return 0;
}


int PaintPerlin::store(Var** parms)
{
	return 0;
}


const void* PaintPerlin::supports (int element)
{
	return supportsStatic(element);
}

const void* PaintPerlin::supportsStatic(int element)
{
	switch (element) {
	case SupportsCanvas:
		return perlinCanvasInfo;

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

static double PlasmaRand(double x, double y);

enum { // MUST be contiguous, not sparse
	VarPlasmaTotal,
};

const static FracturedPainter::VarInfo varPlasmaInfo[] = {
	{	T("plasma_noise"), T("Plasma Noise"),
		T("Common plasma noise you find in so many DOS graphics demos."),
		-1, FracturedPainter::VarInfo::TypeLabel,
		0, 0,0
	},
	{	nullptr, nullptr,nullptr,	 0, 0,	 0, 0,0
	}
};

static const FracturedPainter::CanvasInfo plasmaCanvasInfo[] = 
{
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u8 ),
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u16 ),
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::f32 ),
	FracturedPainter::CanvasInfo()
};

int PaintPlasma::init()
{
	return 0;
}


int PaintPlasma::draw(FracturedCanvas* fs, FracturedCanvas* fsin, int (*progress)(void* self, int current, int total))
{
	FracturedVector2d v;
	double
		dx, //= fs->inverse.scalex,
		dy; //= fs->inverse.scaley;

	int
		height = fs->height,
		width = fs->width,
		stepwrap; // byte wrap per step size
	int pixelFormat = fs->format & FracturedCanvas::Formats::Mask;
	FracturedPixelPtr p; // pointer for row, and for column

	// Find a step size that rounds down to the next nearest power of two
	// so 257->256, 256->128, 254->128
	// Want to find one that rounds up, but there is currently a problem
	// with blending two values when only one exists and the other is
	// off the canvas. :-/
	int step, size = (width > height) ? width : height;
	for (step = 1<<16; (unsigned)step > (unsigned)size; step >>= 1);
	//for (step = 1; step < width; step <<= 1); // round up instead
	if (step > 64) step = 64;

	// initial seeds
	p.p = fs->pixels;
	stepwrap = (fs->wrap) * step;
	dx = fs->inverse.scalex * step;
	dy = fs->inverse.scaley * step;
	v.y = 0;
	for (int i = 0; i < height; i+=step) {
		v.x=0;

		switch (pixelFormat) {
		case FracturedCanvas::Formats::u8:
			for (int j = 0; j < width; j+=step, v.x += dx) {
				p.u8[j] = int( PlasmaRand(v.x, v.y) * 256 );
			}
			break;
		case FracturedCanvas::Formats::u16:
			for (int j = 0; j < width; j+=step, v.x += dx) {
				p.u16[j] = (uint16) (PerlinNoise2(v.v) * 32768 + 32768);
			}
			break;
		case FracturedCanvas::Formats::f32:
			for (int j = 0; j < width; j+=step, v.x += dx) {
				p.f32[j] = (float) PerlinNoise2(v.v);
			}
			break;
		}
		p.u8 += stepwrap;
		v.y += dy;
	}

	// determine weight for each iteration
	// weight is halved each phase (so smaller regions have less difference)
	double weight = 1;
	switch (pixelFormat) {
	case FracturedCanvas::Formats::u8:	weight = 256/8;	break;
	case FracturedCanvas::Formats::u16:	weight = 65536/8;	break;
	case FracturedCanvas::Formats::f32:	weight = 1;		break;
	}

	// recursively (actually, iteratively) fill in between the lines
	for (; step > 1; step >>= 1, weight /= 2) {
		int halfstep = step>>1;
		int halfwrap = (fs->wrap) * halfstep;	// byte wrap per half step size, useful for center pixels
		stepwrap = halfwrap * 2;
		p.p = fs->pixels;
		dx = fs->inverse.scalex * step;
		dy = fs->inverse.scaley * step;

		p.p = fs->pixels;
		v.y = 0;
		for (int i = 0; i < height; i+=step) {
			// each quadrant is filled in order:
			//	1. horizontal middle of each row
			//	2. vertical middle of each column
			//	3. center of each quadrant

			//v.x=0;

			//
			switch (pixelFormat) {
			case FracturedCanvas::Formats::u8:
				// top middle dots
				v.x = 0;
				for (int j = 0; j < width; j+=step, v.x += dx) {
						p.u8[j+halfstep] = // (left + right) / 2 + (little randomness * weight)
							((p.u8[j] + p.u8[j+step]) >> 1)
							+ int( PlasmaRand(v.x, v.y) * weight );
				}
				if (i >= step) {
					v.x = halfstep * dx;
					for (int j = 0; j < width; j+=step, v.x += dx) {
						(p.u8-halfwrap)[j] = // (top + bottom) / 2 + (little randomness * weight)
							((p.u8[j] + (p.u8-stepwrap)[j]) >> 1)
							+ int( PlasmaRand(v.x, v.y) * weight );
					}
					v.x = halfstep * dx;
					for (int j = 0; j < width; j+=step, v.x += dx) {
						(p.u8-halfwrap)[j-halfstep] = // (top + bottom) / 2 + (little randomness * weight)
							((p.u8[j] + p.u8[j-step] + (p.u8-stepwrap)[j] + (p.u8-stepwrap)[j-step]) >> 2)
							+ int( PlasmaRand(v.x, v.y) * weight );
					}
				}
				break;
			}
			p.u8 += stepwrap;
			v.y += dy;
		}
		if (!progress(this, step, size)) break;
	}
	
	return 0;
}


int PaintPlasma::next (FracturedCanvas* fcin)
{
	return 0;
}


int PaintPlasma::load(Var* parms)
{
	return 0;
}


int PaintPlasma::store(Var** parms)
{
	return 0;
}


const void* PaintPlasma::supports (int element)
{
	return supportsStatic(element);
}

const void* PaintPlasma::supportsStatic(int element)
{
	switch (element) {
	case SupportsCanvas:
		return plasmaCanvasInfo;

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


static double PlasmaRand(double x, double y)
{
	double z = x*y;//*54851729;
	return fmod(((z * 214013L + 2531011L) / 1), 65536) / 0xFFFF;
}
