/**
File: PaintCCA.cpp
Since: 2005-01-14
Remark: Cyclic Cellular Automata

todo: add Belousov-Zhabotinsky from http://www.vbaccelerator.com/home/VB/Code/vbMedia/Algorithmic_Images/Hodge_Podge/article.asp

*/

#include "PaintCyclicAutomata.h"
#include <stdlib.h>
#include <assert.h>
#include <string.h>
//#define _USE_MATH_DEFINES
//#include "math.h"
//#include "float.h"

////////////////////////////////////////////////////////////////////////////////

#pragma warning(disable:4244) // conversion from 'double' to 'float', possible loss of data

enum { // MUST be contiguous, not sparse
	VarSpecie,
	VarStates,
	VarRange,
	VarThreshold,
	VarNeighborhood,
	VarModel,
	VarWrapping,
	VarTotal,
};

const static FracturedPainter::VarInfo varInfo[] = {
	{	T("complex_fractal"), T("Complex fractal"),
		T("These fractals apply simple equations to complex ")
		T("multiple iterations to create very complex, self similar, organic spirals. ")
		T("The complex space real is mapped to x and imaginary to y."),
		-1, FracturedPainter::VarInfo::TypeLabel,
		0, 0,0
	},
	{	T("specie"), T("Specie"),
		T("Type of cellular automata (preset)."),
		VarSpecie, FracturedPainter::VarInfo::TypeInt,
		//PaintComplex::SpecieMandelbrot2, 0,PaintComplex::SpecieTotal-1,
		0,0,0
	},
	{	T("states"), T("States"),
		T("Number of states for fade. The original Life had only 2 states."),
		VarStates, FracturedPainter::VarInfo::TypeInt,
		255, 0,255,
	},
	{	T("range"), T("Range"),
		T("How large a neighborhood to consider."),
		VarWrapping, FracturedPainter::VarInfo::TypeInt,
		1, 0,PaintCyclicAutomata::RangeMax,
	},
	{	T("threshold"), T("Threshold"),
		T("Necessary number of neighbors to adance state."),
		VarThreshold, FracturedPainter::VarInfo::TypeInt,
		3, 0,PaintCyclicAutomata::RangeMax*PaintCyclicAutomata::RangeMax,
	},
	{	T("neighborhood"), T("Neighborhood type"),
		T("Use Von Neumann or Moore shaped neighborhood."),
		VarNeighborhood, FracturedPainter::VarInfo::TypeBool,
		PaintCyclicAutomata::NeighborhoodMoore, 0,1,
	},
	{	T("model"), T("Model type"),
		T("Use Greenberg Hastings model or not."),
		VarModel, FracturedPainter::VarInfo::TypeBool,
		PaintCyclicAutomata::ModelGreenbergHastings, 0,1,
	},
	{	T("wrapping"), T("Wrapping"),
		T("How the cells react at the edges."),
		VarWrapping, FracturedPainter::VarInfo::TypeInt,
		PaintCyclicAutomata::WrappingTile, 0,PaintCyclicAutomata::WrappingTotal-1,
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

PaintCyclicAutomata::PaintCyclicAutomata()
{
	specie = 0;
	init();
}


PaintCyclicAutomata::PaintCyclicAutomata(int range_, int threshold_, int states_, int neighborhood_, int model_, bool wrapSides_)
: range(range), threshold(threshold_), states(states_), neighborhood(neighborhood_), model(model_), wrapping(wrapSides_)
{
	specie = 0;
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
	wrapping = WrappingTile;
	return true;
}


int PaintCyclicAutomata::init (int range_, int threshold_, int states_, int neighborhood_, int model_, bool wrapping_)
{
	range = range_;
	threshold = threshold_;
	states = states_;
	neighborhood = neighborhood_;
	model = model_;
	wrapping = wrapping_;
	return true;
}


int PaintCyclicAutomata::draw (FracturedCanvas* fc, FracturedCanvas* fcin, int (*progress)(void* self, int current, int total))
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


int PaintCyclicAutomata::next (FracturedCanvas* fcin)
{
 	assert(fcin != nullptr);
	assert(fcin->pixels != nullptr);
	assert(fcin->bipp == 8);
	assert(fcin->width > 0);
	assert(fcin->height > 0);

    // single frame of cell animation
	int height = fcin->height;
	int width = fcin->width;
	int wrap = fcin->wrap;
	int changeCount = 0;
	int xmap[RangeMax*2+1];	// 0..9 left, 10 is center, 11-20 right
	int ymap[RangeMax*2+1];	// 0..9 up, 10 is center, 11-20 down
	bool moore = (neighborhood == NeighborhoodMoore); // else von Neumann type
	bool greenberg = (model == ModelGreenbergHastings); // else normal model

	uint8* cells = (uint8*)fcin->pixels;
	uint8* cellsTmp = smalloc(uint8, height*wrap);

	for (int y = 0; y < height; y++) {
		for (int x = 0; x < width; x++) {
			//int self = y * wrap + x;
			//int neighborCount = 0;

			// prepare vectors holding proper rows and columns
			// of the n-range neighbourhood
			xmap[RangeMax] = x;
			ymap[RangeMax] = y;
			for (int distance = 1; distance <= range; distance++) {
				//if (wrapping == WrappingTile) {
				//}
				int left = x - distance;
				xmap[RangeMax - distance] = (left >= 0) ? left : width + left;

				int right = x + distance;
				xmap[RangeMax + distance] = (right < width) ? right : right - width;

				int top = y - distance;
				ymap[RangeMax - distance] = (top >= 0) ? top : height + top;

				int bottom = y + distance;
				ymap[RangeMax + distance] = (bottom < height) ? bottom : bottom - height;
			}


			int state, stateNext;
			int xy = y*wrap + x;
			state = cells[xy];
			stateNext = state + 1;
			if (stateNext >= states) stateNext = 0;

			if (!greenberg || state == 0) {
				int neighborCount = 0; // count of neighbours with the next state
				for (int yc = RangeMax - range; yc <= RangeMax + range; yc++) {
					int y2 = ymap[yc] * wrap;
					for (int xc = RangeMax - range; xc <= RangeMax + range; xc++) {
						if (moore
						|| (abs(xc - RangeMax) + abs(yc - RangeMax)) <= range) {
							if (cells[y2 + xmap[xc]] == stateNext) {
								neighborCount++;
							}
						}
					}
				}
				if (neighborCount < threshold)
					stateNext = state; // restore original state because not enough neighbors
				// else >= threshold so next state
			}
			// else in GH all cells > 0 automatically advance
			//*/

			cellsTmp[xy] = stateNext;
			if (stateNext != state) changeCount++; // changed so count another cell

		} // x
	} // y

	// copy temporary back over
	memcpy(cells, cellsTmp, height*wrap*sizeof(*cells));
	sfree(cellsTmp);

	return changeCount;
}


int PaintCyclicAutomata::load (Var* vars)
{
	while (vars->id >= 0) {
		switch (vars->id) {
		case VarSpecie:
			specie = vars->value.i;
			//if (specie > SpecieTotal) specie = SpecieMandelbrot2;
			break;
		case VarStates:
			states = vars->value.i;
			if (states < 1) states = 1;
			break;
		case VarRange:
			range = vars->value.i;
			break;
		case VarThreshold:
			threshold = vars->value.i;
			break;
		case VarNeighborhood:
			neighborhood = vars->value.i;
			break;
		case VarModel:
			model = vars->value.i;
			break;
		case VarWrapping:
			wrapping = vars->value.i;
			break;
		}
		vars++;
	}
	return 0;
}


int PaintCyclicAutomata::store (Var** pvars)
{
	Var* vars = new FracturedPainter::Var[VarTotal];
	for (int i=0; i < VarTotal; i++) {
		vars[i].id = i;
	}
	vars[VarSpecie].value.i = specie;
	vars[VarStates].value.i = states;
	vars[VarRange].value.i = range;
	vars[VarThreshold].value.i = threshold;
	vars[VarNeighborhood].value.i = neighborhood;
	vars[VarModel].value.i = model;
	vars[VarWrapping].value.i = wrapping;
	*pvars = vars;
	return 0;
}


const void* PaintCyclicAutomata::supports (int element)
{
	return supportsStatic(element);
}

const void* PaintCyclicAutomata::supportsStatic(int element)
{
	switch (element) {
	case SupportsCanvas:
		return canvasInfo;

	case SupportsLayerFlags:
		{
			const static int flags = FracturedLayer::FlagPreserve|FracturedLayer::FlagAnimated|FracturedLayer::FlagLowColor;
			return &flags;
		}
		break;

	case SupportsVars:
		return varInfo;

	}
	return nullptr;
}


////////////////////////////////////////////////////////////////////////////////

/* todo: convert vb into c

Public Sub Step()
Dim x As Long
Dim y As Long
Dim tSALast As SAFEARRAY2D
Dim tSA As SAFEARRAY2D
Dim bDibLast() As Byte
Dim bDibNext() As Byte
Dim lOldStateInc As Long
Dim i As Long
Dim j As Long
Dim lOffset As Long
Dim infectedNeighbours As Long
Dim illNeighbours As Long
Dim neighbouringSickness As Long
Dim newState As Long
   
   With tSALast
       .cbElements = 1
       .cDims = 2
       .Bounds(0).lLbound = 0
       .Bounds(0).cElements = m_cDibLast.Height
       .Bounds(1).lLbound = 0
       .Bounds(1).cElements = m_cDibLast.BytesPerScanLine()
       .pvData = m_cDibLast.DIBSectionBitsPtr
   End With
   CopyMemory ByVal VarPtrArray(bDibLast()), VarPtr(tSALast), 4

   With tSA
       .cbElements = 1
       .cDims = 2
       .Bounds(0).lLbound = 0
       .Bounds(0).cElements = m_cDib.Height
       .Bounds(1).lLbound = 0
       .Bounds(1).cElements = m_cDib.BytesPerScanLine()
       .pvData = m_cDib.DIBSectionBitsPtr
   End With
   CopyMemory ByVal VarPtrArray(bDibNext()), VarPtr(tSA), 4

   ' Run the hodge podge step:
   For x = 0 To m_cDib.Width - 1
      For y = 0 To m_cDib.Height - 1
         
         infectedNeighbours = 0
         illNeighbours = 0
         neighbouringSickness = bDibLast(x, y)
         
         For lOffset = 0 To 8
            If (m_tNeighbourOffset(lOffset).bUse) Then
            
               i = x + m_tNeighbourOffset(lOffset).x
               If (i < 0) Then i = m_cDib.Width - 1
               If (i >= m_cDib.Width) Then i = 0
               j = y + m_tNeighbourOffset(lOffset).y
               If (j < 0) Then j = m_cDib.Height - 1
               If (j >= m_cDib.Height) Then j = 0
                  
               If (bDibLast(i, j) < m_lStates) Then
                  If (bDibLast(i, j) > 0) Then
                     infectedNeighbours = infectedNeighbours + 1
                  End If
               Else
                  illNeighbours = illNeighbours + 1
               End If
               neighbouringSickness = neighbouringSickness + bDibLast(i, j)
               
            End If
         Next lOffset
         
         If (bDibLast(x, y) > 0) Then
            infectedNeighbours = infectedNeighbours + 1
         End If
         
         ' healthy cell
         If (bDibLast(x, y) = 0) Then
            bDibNext(x, y) = infectedNeighbours / m_lWeighting1 + illNeighbours
             / m_lWeighting2
         ' infected cell
         ElseIf (bDibLast(x, y) > 0 And bDibLast(x, y) < m_lStates) Then
            newState = (neighbouringSickness \ infectedNeighbours) +
             m_lInfectionRate
            If (newState > m_lStates) Then
               newState = m_lStates
            End If
            bDibNext(x, y) = newState
         ' ill cell
         ElseIf (bDibLast(x, y) = m_lStates) Then
            bDibNext(x, y) = 0
         End If
         
      Next y
   Next x
   
   ' Copy New -> Old
   m_cDib.PaintPicture m_cDibLast.hdc

   ' Clear the temporary array descriptor
   CopyMemory ByVal VarPtrArray(bDibNext), 0&, 4
   CopyMemory ByVal VarPtrArray(bDibLast), 0&, 4

End Sub
*/
