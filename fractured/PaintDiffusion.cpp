/**
File: PaintDiffusion.cpp
Since: 2005-03-15
Remark: Reaction Diffusion Equates

todo: add Complex Ginzburg Landau http://www.cmp.caltech.edu/~mcc/STChaos/
todo: add Dwight Barkley - Bar Eiswirth model http://www.cmp.caltech.edu/~mcc/STChaos/
todo?: add Swift Hohenberg Equate ... mcc/Patterns/Demo4_3.html
todo: add Lifshitz Petrich ... mcc/Patterns/Demo4_6.html (crystal beads)

*/

#include "PaintCyclicAutomata.h"
#include "stdlib.h"
//#define _USE_MATH_DEFINES
//#include "math.h"
//#include "float.h"

////////////////////////////////////////////////////////////////////////////////

#pragma warning(disable:4244) // conversion from 'double' to 'float', possible loss of data

PaintCyclicAutomata::PaintCyclicAutomata()
{
	specie = 0;
	//PaintCyclicAutomata((int)(0));//Species::mandelbrot2));
	init();
}


PaintCyclicAutomata::PaintCyclicAutomata(int range_, int threshold_, int states_, int neighborhood_, int model_, bool wrapSides_)
: range(range), threshold(threshold_), states(states_), neighborhood(neighborhood_), model(model_), wrapSides(wrapSides_)
{
	// no need to init
}


/*PaintCyclicAutomata::PaintCyclicAutomata(int specie_)
{
	specie = specie_;
	switch (specie) {
	case 0:
		break;
	default:
		break;
	}
	reset();
}*/


int PaintCyclicAutomata::init()
{
	range = 1;
	threshold = 3;
	states = 3;
	neighborhood = NeighborhoodMoore;
	model = ModelNormal;
	wrapSides = true;
	return true;
}


int PaintCyclicAutomata::init(int range_, int threshold_, int states_, int neighborhood_, int model_, bool wrapSides_)
{
	range = range_;
	threshold = threshold_;
	states = states_;
	neighborhood = neighborhood_;
	model = model_;
	wrapSides = wrapSides_;
	return true;
}


int PaintLife::draw (FracturedCanvas* fc, FracturedCanvas* fcin, int (*progress)(int current, int total))
{
	int
		height = fc->height,
		width  = fc->width,
		heightIn = fcin->height,
		widthIn = fcin->width;
	int pixelFormat = fc->format & FracturedCanvas::Formats::mask;
	FracturedPixelPtr
		p, // pixel pointer
		pin; // pointer to cell values

	assert(fcin != nullptr);
	assert(fcin->pixels != nullptr);

	// for now, just copy pixel values directly
	// with no interpolated smoothing
	// later do call to smoother
	p.p = fc->pixels;
	pin.p = fcin->pixels;
	if (heightIn < height) height = heightIn;

	for (int i=0; i < height; i++) {

		switch (pixelFormat) {
		case FracturedCanvas::Formats::u8:
			for (int j=0; j < width; j++) {
				p.u8[j] = pin.u8[j];
			}
			break;

		case FracturedCanvas::Formats::u16:
			for (int j=0; j < width; j++) {
				p.u16[j] = pin.u8[j];
			}
			break;

		case FracturedCanvas::Formats::f32:
			for (int j=0; j < width; j++) {
				p.f32[j] = pin.u8[j];
			}
			break;

		}

		p.u8 += fc->wrap;
		pin.u8 += fcin->wrap;

		if (!progress(i, height)) break;
	}

	return 0;
}


int PaintCyclicAutomata::next (FracturedCanvas* fcin)
{
 	assert(fcin != nullptr);
	assert(fcin->pixels != nullptr);
	assert(fcin->bipp == 8);
	assert(fcin->width > 0);
	assert(fcin->height > 0);

    // single frame of cell animation
    // use simple rules of life
    // 0-1 die, 2 survive, 3 populate, 4-8 die
	int height = fcin->height;
	int width = fcin->width;
	int wrap = fcin->wrap;
	int xlocs[RangeMax], ylocs[RangeMax*2+1];
	bool moore = (neighborhood == NeighborHoodMoore); // else von Neumann type

	uint8* cells = (uint8*)fcin->pixels;
	uint8* cellsTmp = smalloc(uint8, height*wrap);



   // single frame of cell animation
	/*
	public int OnePass(int sizX, int sizY, boolean isWrap, int ColoringMethod,
			short crrState[][], short tmpState[][]) {
		short bOldVal, bNewVal;
		int modCnt = 0;
		int i, j, iCnt;
		int xVector[] = new int[21]; // 0..9, 10, 11..20
		int yVector[] = new int[21]; // 0..9, 10, 11..20
		int colL, colR, rowT, rowB;
		int ic, ir, iTmp;
		short nxtStt;
		boolean fMoore; // Moore neighbourhood? Else von Neumann.

		fMoore = (iNgh == MJRules.NGHTYP_MOOR); // Moore neighbourhood? Else von Neumann.

		for (i = 0; i < sizX; i++) {
			for (j = 0; j < sizY; j++) {
				// prepare vectors holding proper rows and columns
				// of the n-range neighbourhood
				xVector[10] = i;
				yVector[10] = j;
				for (iTmp = 1; iTmp <= iRng; iTmp++) {
					colL = i - iTmp;
					if (colL >= 0)
						xVector[10 - iTmp] = colL;
					else
						xVector[10 - iTmp] = sizX + colL;

					colR = i + iTmp;
					if (colR < sizX)
						xVector[10 + iTmp] = colR;
					else
						xVector[10 + iTmp] = colR - sizX;

					rowT = j - iTmp;
					if (rowT >= 0)
						yVector[10 - iTmp] = rowT;
					else
						yVector[10 - iTmp] = sizY + rowT;

					rowB = j + iTmp;
					if (rowB < sizY)
						yVector[10 + iTmp] = rowB;
					else
						yVector[10 + iTmp] = rowB - sizY;
				}
				bOldVal = crrState[i][j];
				if (bOldVal >= (iClo - 1))
					nxtStt = 0;
				else
					nxtStt = (short) (bOldVal + 1);

				if ((!fGH) || (bOldVal == 0)) {
					bNewVal = bOldVal; // default - no change
					if (bNewVal >= iClo)
						bNewVal = (short) (iClo - 1);

					iCnt = 0; // count of neighbours with the next state
					for (ic = 10 - iRng; ic <= 10 + iRng; ic++) {
						for (ir = 10 - iRng; ir <= 10 + iRng; ir++) {
							if ((fMoore)
									|| ((Math.abs(ic - 10) + Math.abs(ir - 10)) <= iRng)) {
								if (crrState[xVector[ic]][yVector[ir]] == nxtStt) {
									iCnt++;
								}
							}
						}
					}
					if (iCnt >= iThr)
						bNewVal = nxtStt; // new cell status
				} else {
					bNewVal = nxtStt; // in GH all > 0 automatically advance
				}

				tmpState[i][j] = bNewVal;
				if (bNewVal != bOldVal) // change detected
				{
					modCnt++; // one more modified cell
				}
			} // for j
		} // for i

		return modCnt;
	}
	*/
	return 0;
}


int PaintCyclicAutomata::load (void* parms)
{
	return 0;
}


int PaintCyclicAutomata::store (void* parms)
{
	return 0;
}


int PaintCyclicAutomata::variables ()
{
	return 0;
}


const void* PaintCyclicAutomata::supports (int element)
{
	return supportsStatic(element);
}

const void* PaintCyclicAutomata::supportsStatic(int element)
{
	switch (element) {
	case SupportsLayerFlags:
		{
			const static int flags = FracturedLayer::FlagPreserve;
			return &flags;
		}
		break;
	default:
		return nullptr;
	}
}


////////////////////////////////////////////////////////////////////////////////

