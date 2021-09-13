/**
File: PaintLife.cpp
Since: 2005-01-07
Remark: Jon Conway's game of life
*/

#include "PaintLife.h"
#include <string.h>
#include <assert.h>
#include <stdlib.h>
//#define _USE_MATH_DEFINES
//#include <math.h>
//#include <float.h>

////////////////////////////////////////////////////////////////////////////////

#pragma warning(disable:4244) // conversion from 'double' to 'float', possible loss of data

enum { // MUST be contiguous, not sparse
	VarSpecie,
	VarStates,
	VarWrapping,
	VarBirth,
	VarSurvival,
	VarTotal,
};

const static FracturedPainter::VarInfo varInfo[] = {
	{	T("life_automata"), T("Life automata"),
		T("Variations of the game of life (including the most famous one by John Conway)."),
		-1, FracturedPainter::VarInfo::TypeLabel,
		0, 0,0
	},
	{	T("specie"), T("Specie"),
		T("Type of life simulation (which preset)."),
		VarSpecie, FracturedPainter::VarInfo::TypeInt,
		//PaintLife::0, 0,PaintLife::SpecieTotal-1,
		0, 0,0,
	},
	{	T("states"), T("States"),
		T("Number of states for fade. The original Life had only 2 states."),
		VarStates, FracturedPainter::VarInfo::TypeInt,
		255, 0,255,
	},
	{	T("wrapping"), T("Wrapping"),
		T("How the cells react at the edges."),
		VarWrapping, FracturedPainter::VarInfo::TypeInt,
		PaintLife::WrappingTile, 0,PaintLife::WrappingTotal-1,
	},
	{	T("birth_rules"), T("Birth rules"),
		T("List of neighborhood sizes for which new life spawns. ")
		T("For example '25' would yield a new cell if it was surrounded by either 2 or 5 living neighbors."),
		VarBirth, FracturedPainter::VarInfo::TypeInt,
		3, 0, 876543210
	},
	{	T("survival_rules"), T("Survival rules"),
		T("List of neighborhood sizes for which cells can survive, balanced between overcrowding and loneliness. ")
		T("Conway's is just '23'."),
		VarSurvival, FracturedPainter::VarInfo::TypeInt,
		2, 0, 876543210
	},
	{	nullptr, nullptr,nullptr,	 0, 0,	 0, 0,0
	}
};

static const FracturedPainter::CanvasInfo canvasInfo[] = 
{
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u8 ),
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u16 ),
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::f32 ),
	FracturedPainter::CanvasInfo()
};

PaintLife::PaintLife()
{
	specie = 0;
	init();
}


PaintLife::PaintLife(int specie_)
{
	specie = specie_;
	init();
}


int PaintLife::init()
{
	// do species specific initialization
	//switch (species) {
	//case Species:::
	//case ...
	states = 255;
	wrapping = WrappingTile;
	// hard code Conway's rules for now
	const static bool birthRulesDefault[9] = {false, false, false, true, false, false, false, false, false};
	const static bool survivalRulesDefault[9] = {false, false, true, true, false, false, false, false, false};
	memcpy(birthRules, birthRulesDefault, sizeof(birthRules));
	memcpy(survivalRules, survivalRulesDefault, sizeof(survivalRules));
	return 0;
}


int PaintLife::init(int survivalFlags, int birthFlags)
{
	for (int i = 0; i < elmsof(birthRules); i++) {
		birthRules[i] = (birthFlags & 1) ? true : false;
		birthFlags >>= 1;
		survivalRules[i] = (survivalFlags & 1) ? true : false;
		survivalFlags >>= 1;
	}
	return 0;
}


int PaintLife::draw (FracturedCanvas* fc, FracturedCanvas* fcin, int (*progress)(void* self, int current, int total))
{
	int
		height = fc->height,
		width  = fc->width,
		heightIn = fcin->height,
		widthIn = fcin->width;
	int pixelFormat = fc->format & FracturedCanvas::Formats::Mask;
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

		if (!progress(this, i, height)) break;
	}

	return 0;
}


int PaintLife::next (FracturedCanvas* fcin)
{
	assert(fcin != nullptr);
	assert(fcin->pixels != nullptr);
	assert(fcin->bipp == 8);
	assert(fcin->width > 0);
	assert(fcin->height > 0);

    // single frame of cell animation
    // use simple rules of life
    // 0-1 die, 2 survival, 3 populate, 4-8 die
	int height = fcin->height;
	int width = fcin->width;
	int wrap = fcin->wrap;
	uint8* cells = (uint8*)fcin->pixels;
	uint8* cellsTmp = smalloc(uint8, height*wrap);

	// if type is ever modified, change wrap accordingly.
	//-(uint8*)( (uint8*)(cells+x)+(y*wrap) )
	//-(uint8*)(y*wrap)

	for (int y = 0; y < height; y++) {

		int yl, yh;
		if (wrapping == WrappingNone) {
			yl = y-1;	if (yl < 0) yl=0;
			yh = y+1;	if (yh >= height) yh = height-1;
		} else {
			yl = y-1;
			yh = y+1;
			if (wrapping == WrappingMirror) {
				if (yl < 0) yl = 1;
				if (yh >= height) yh = height-2;
			} else { // tile
				if (yl < 0) yl = height-1;
				if (yh >= height) yh = 0;
			}
		}

		for (int x = 0; x < width; x++) {
			int xy = y * wrap + x;
			int neighborCount = 0;
			int state = cells[xy];

			if (wrapping == WrappingNone) {
				int xl = x-1;	if (xl < 0) xl=0;
				int xh = x+1;	if (xh >= width) xh = width-1;
				for (int i = yl; i <= yh; i++) {
					for (int j = xl; j <= xh; j++) {
						if (cells[i * wrap + j] > 0) neighborCount++;
					}
				}
				if (state > 0) neighborCount--; // compensate for overcount
			} else {
				int xl = x-1;
				int xh = x+1;
				if (wrapping == WrappingMirror) {
					if (xl < 0) xl = 1;
					if (xh >= width) xh = width-2;
				} else { // tile
					if (xl < 0) xl = width-1;
					if (xh >= width) xh = 0;
				}
				#if 0 // simpler binary simulation
				if (cells[yl * wrap + xl]) neighborCount++;
				if (cells[yl * wrap + x]) neighborCount++;
				if (cells[yl * wrap + xh]) neighborCount++;
				if (cells[y * wrap + xl]) neighborCount++;
				if (cells[y * wrap + xh]) neighborCount++;
				if (cells[yh * wrap + xl]) neighborCount++;
				if (cells[yh * wrap + x]) neighborCount++;
				if (cells[yh * wrap + xh]) neighborCount++;
				#else
				int states = this->states;
				if (cells[yl * wrap + xl] >= states) neighborCount++;
				if (cells[yl * wrap + x] >= states) neighborCount++;
				if (cells[yl * wrap + xh] >= states) neighborCount++;
				if (cells[y * wrap + xl] >= states) neighborCount++;
				if (cells[y * wrap + xh] >= states) neighborCount++;
				if (cells[yh * wrap + xl] >= states) neighborCount++;
				if (cells[yh * wrap + x] >= states) neighborCount++;
				if (cells[yh * wrap + xh] >= states) neighborCount++;
				#endif
			}

			#if 0 // simple two color simulation
			if (state == 0) { // dead, so check for births
				if (birthRules[neighborCount])
					state = 255; // new cell
			} else {
				if (!survivalRules[neighborCount]) // if not survivng, then dying
					state = 0;
			}
			cellsTmp[xy] = state;
			#elif 1 // prettier one with fade
			if (state < states) { // dead, so check for births
				if (birthRules[neighborCount])
					state = states; // new cell
				else if (state > 0)
					state--; // fade some
			} else { // alive
				if (!survivalRules[neighborCount]) // if not survivng, then dying
					state--; // begin fade
			}
			cellsTmp[xy] = state;
			#elif 0
			// Conway's Life hardcoded for speed
			switch (neighborCount) {
			case 2: // survival
				cellsTmp[xy] = cells[xy];
				break;
			case 3: // populate
				cellsTmp[xy] = 255;
				break;
			case 0: case 1: // die of loneliness
			default: // too crowded
				cellsTmp[xy] = 0;
					break;
			}
			#endif
		}
	}

	// copy temporary back over
	memcpy(cells, cellsTmp, height*wrap*sizeof(*cells));
	sfree(cellsTmp);

	return 0;
}


int PaintLife::load(Var* vars)
{
	while (vars->id >= 0) {
		switch (vars->id) {
		case VarSpecie:
			specie = vars->value.i;
			//if (specie > SpecieTotal) specie = 0;
			break;
		case VarStates:
			states = vars->value.i;
			if (states < 1) states = 1;
			break;
		case VarWrapping:
			wrapping = vars->value.i;
			break;
		case VarBirth:
			{
				int x = vars->value.i;
				for (int i=0; i < elmsof(birthRules); i++)	birthRules[i] = false;
				while (x > 0) {
					birthRules[x % 10] = true;
					x /= 10;
				}
			}
			break;
		case VarSurvival:
			{
				int x = vars->value.i;
				for (int i=0; i < elmsof(survivalRules); i++)	survivalRules[i] = false;
				while (x > 0) {
					survivalRules[x % 10] = true;
					x /= 10;
				}
			}
			break;
		}
		vars++;
	}
	return 0;
}


int PaintLife::store(Var** pvars)
{
	Var* vars = new FracturedPainter::Var[VarTotal];
	for (int i=0; i < VarTotal; i++) {
		vars[i].id = i;
	}
	vars[VarSpecie].value.i = specie;
	vars[VarStates].value.i = states;
	vars[VarWrapping].value.i = wrapping;

	// turn bit flag array into decimal number
	// where each digit represents the number of cells
	// necessary to go to the next state.
	int birthNum=0, survivalNum=0;
	for (int i = elmsof(birthRules)-1; i >= 0; i--) {
		if (birthRules[i])	birthNum = birthNum * 10 + i;
		if (survivalRules[i])	survivalNum = survivalNum * 10 + i;
	}
	vars[VarBirth].value.i = birthNum;
	vars[VarSurvival].value.i = survivalNum;
	*pvars = vars;
	return 0;
}


const void* PaintLife::supports (int element)
{
	return supportsStatic(element);
}

const void* PaintLife::supportsStatic(int element)
{
	switch (element) {
	case SupportsCanvas:
		return canvasInfo;

	case SupportsLayerFlags:
		{
			const static int flags = FracturedLayer::FlagPreserve|FracturedLayer::FlagAnimated;
			return &flags;
		}
		break;

	case SupportsVars:
		return varInfo;

	default:
		return nullptr;
	}
}

////////////////////////////////////////////////////////////////////////////////

