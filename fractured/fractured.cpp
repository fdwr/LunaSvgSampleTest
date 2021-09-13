/**
File: fracture.cpp
Since: 2005-11-30
Remark: The main fractal calculations are here.
*/

#include <stdlib.h>
#include <math.h>
#include "fractured.h"

FracturedCanvas::FracturedCanvas()
{
	// everything else can stay garbage until initialized
	// but this member should be zeroed so init does not
	// try to free it.
	format = width = height = 0; // prevent potential crashes from reading before allocated
	pixels = nullptr;
}


/** Initializes a newly declared instance
	or reinitializes it to a new size.
*/
void FracturedCanvas::init(int width_, int height_, int format_)
{
	free();

	format = format_; // setting this also sets {bipp, bipc, cpp, ctype}
	width = width_;
	height = height_;
	wrap = ( ((width * bipp) >> 3) + 3) & -4; // bytes per row rounded up for 32bit alignment

	angle = 0;
	origx = origy = 0;
	shearx = sheary = 0;
	scalex = scaley = scalez = 1;

	// don't bother initializing the matrix and inverse
	// because they are recalculated each time a
	// filter redraws.
	//matrixCalc();

	if (height_ <= 0 || width_ <= 0 || wrap <= 0
	||  bipp <= 0 || bipc <= 0 || cpp <= 0 || bipc*cpp > bipp) {
		return; // error!
	}

	pixels = smalloc(uint8, height*wrap);
}

void FracturedCanvas::free()
{
	//width = 0; // for additional safety
	//wrap = 0;
	if (pixels)
		sfree(pixels);
}

void FracturedCanvas::matrixCalc()
{
	matrix.scalex  = scalex;
	matrix.scaley  = scaley;
	matrix.scalez  = scalez;
	inverse.scalex = 1/scalex;
	inverse.scaley = 1/scaley;
	inverse.scalez = 1/scalez;
	matrix.transx  = -origx + width*inverse.scalex/2;	// does not consider rotation yet
	matrix.transy  = -origy + height*inverse.scaley/2;
	matrix.transz  = -origz;
	inverse.transx = -matrix.transx;
	inverse.transy = -matrix.transy;
	inverse.transz = -matrix.transz;
	matrix.shearx  = shearx;
	matrix.sheary  = sheary;
	inverse.shearx = -shearx;
	inverse.sheary = -sheary;
	//double sx = sin(angle);
	//double sy = 0;

	/*	

	sx = sin(A)             // Setup - only done once
    cx = cos(A)
    sy = sin(B)
    cy = cos(B)
    sz = sin(C)
    cz = cos(C)
    x1 =  x * cz +  y * sz  // Rotation of each vertex
    y1 =  y * cz -  x * sz
    z1 =  z
    x2 = x1 * cy + z1 * sy
    y2 = z1
    z2 = z1 * cy - x1 * sy
    x3 = x2
    y3 = y2 * cx + z1 * sx
    z3 = z2 * cx - x1 * sx
    xr = x3 + D             // Translation of each vertex
    yr = y3 + E
    zr = z3 + F
	*/
}


// in case you have no callback
int FracturedPainter::dummyProgress(void* self, int current, int total)
{
	return true;
}


// todo: implement full scene graph...
void FracturedLayer::render(FracturedLayer* layers, int count, FracturedCanvas* bg, int (*progress)(void* self, int current, int total))
{
	bg->free();
	if (progress == nullptr) progress = &FracturedPainter::dummyProgress;
	for (int i = 0; i < count; i++) {
		// add more intelligent logic in here that can cache and convert formats
		if (layers->canvas.pixels == nullptr) {
			// allocate temporary canvas
			continue;
		}
		layers->painter->draw(&layers->canvas, nullptr, progress);
		layers->flags &= ~FracturedLayer::FlagModified;
		//layers->flags &= ~Flags::modified;
	}
	if (count > 0) {
		*bg = layers->canvas;
	}
}
