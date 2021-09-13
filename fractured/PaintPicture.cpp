/**
File: PaintPicture.cpp
Since: 2005-01-07
Remark: Static picture loaded from image file
*/

#include "PaintPicture.h"
#include "math.h"

////////////////////////////////////////////////////////////////////////////////

int PaintPicture::init()
{
	return 0;
}


int PaintPicture::draw(FracturedCanvas* fs, FracturedCanvas* fsin, int (*progress)(void* self, int current, int total))
{
	/*
	FracturedVector2d v = {0,0};
	double
		dx = fs->inverse.scalex,
		dy = fs->inverse.scaley,
		dz = fs->inverse.scalez;

	int
		height = fs->height,
		width = fs->width;
	int pixelFormat = fs->type & FracturedCanvas::Formats::mask;
	FracturedPixelPtr p; // pointer for row, and for column

	// simply march top down, left to right
	p.p = fs->pixels;
	for (int i=0; i < height; i++) {
		v.x=0;

		switch (pixelFormat) {
		case FracturedCanvas::Formats::u8:
			for (int j=0; j < width; j++, v.x += dx) {
				p.u8[j] = (int) ( PerlinNoise2(v.v) * 128 + 128);
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

		if (!progress(i, height)) break;
	}
	*/
	return 0;
}


int PaintPicture::next(FracturedCanvas* fcin)
{
	return 0;
}


int PaintPicture::load(Var* parms)
{
	return 0;
}


int PaintPicture::store(Var** parms)
{
	return 0;
}


const void* PaintPicture::supports (int element)
{
	return supportsStatic(element);
}


const void* PaintPicture::supportsStatic(int element)
{
	switch (element) {
	//case SupportsCanvas:
	//	return canvasInfo;

	case SupportsLayerFlags:
		{
			const static int flags = FracturedLayer::FlagPreserve;
			return &flags;
		}
		break;
	}
	return nullptr;
}
