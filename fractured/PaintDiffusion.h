/**
File: PaintCCA.cpp
Since: 2005-01-14
Remark: Cyclic Cellular Automata

From http://www.mirekw.com/ca/rullex_cycl.html

Cyclic CA notation:
The notation of Cyclic Cellular Automata has the "R/T/C/N" form, where:
R - specifies the neighbourhood range (1..10).
T - specifies the threshold - minimal count of cells in the neighbourhood having the next color, necessary for the cell to advance to the next state.
C - specifies the count of states in the rule (0..C-1).
N - specifies the neighbourhood type: NM stands for extended Moore, NN for extended von Neumann.

Range 'R' von Neumann neighborhood includes all sites which can be
reached from the origin in at most R steps by N, S, E and W moves,
whereas range 'R' Moore neighbourhood also allows NE, SE, NW and
SW moves at each step.

In general Cyclic CA rules should be started from uniformly randomized boards.
*/

#include "fractured.h"

class PaintCyclicAutomata : public FracturedPainter {
public:
	enum {NeighborhoodMoore, NeighborhoodVonNeumann};
	enum {ModelNormal, ModelGreenbergHastings};
	enum {RangeMax=10};

	virtual int draw(FracturedCanvas* fc, FracturedCanvas* fcin, int (*progress)(int current, int total));
	virtual int next (FracturedCanvas* fcin);	/// animate next frame (used by cellular automata, reaction diffusion)
	virtual int init();	/// load default values
	virtual int load(void* parms);	/// load values into filter
	virtual int store(void* parms);	/// store values from filter (serializing if necessary?)
	virtual int variables();	/// get information on variables
	virtual const void* supports(int element);	/// query information like which canvasses are supported
	static const void* supportsStatic(int element);	/// query information like which canvasses are supported

	// static functions
	int init(int range_, int threshold_, int states_, int neighborhood_ = NeighborhoodMoore, int model_ = ModelNormal, bool wrapSides_ = true);

	////////////////////
	PaintCyclicAutomata();
	PaintCyclicAutomata(int species_);
	PaintCyclicAutomata(int range_, int threshold_, int states_, int neighborhood_ = NeighborhoodMoore, int model_ = ModelNormal, bool wrapSides_ = true);

	////////////////////
	//uint8* field;	/// array of cells (multiple values)
	//int width, height;	/// size of field (not size of layer!)

	int range;	/// neighborhood range
	int threshold;	/// minimal count of cells of next color, necessary for cells to advance to next state
	int states;	/// total states
	int neighborhood;	/// neighborhood type, Moore or Neumann (square or diamond)
	int model; /// Greenberg Hastings, normal, or other?
	bool wrapSides;	/// should wrap left to right, top to bottom

	//double bailOut;		// stop if magnitude of Z is outside escape region
	//int iterationsMax;	// stop if iterations greater
	//double cre, cim;	// constant real & imaginary, only applicable to Julia like fractals

	////////////////////
	/*enum Species {
		mandelbrot2,
		mandelbrot3,
		mandelbrot4,
		julia2,
		julia3,
		julia4,
	};*/

private:

};
