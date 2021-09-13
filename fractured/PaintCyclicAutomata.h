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

	FracturedPainter_StdMthds; // define standard methods here (in fractured.h)

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
	int wrapping;	/// should wrap left to right, top to bottom
	enum {
		WrappingNone, /// no wrapping at edges
		WrappingTile, /// wrap edges so tileable
		WrappingMirror, /// mirror edges back around so 4 tileable
		WrappingTotal,
	};

	////////////////////
	/*enum Species {
	};*/

private:

};
