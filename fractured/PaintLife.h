/**
File: PaintLife.h
Since: 2005-01-07
Remark: Jon Conway's game of life

For a space that is 'populated': 
	Each cell with one or no neighbors dies, as if by loneliness. 
	Each cell with four or more neighbors dies, as if by overpopulation. 
	Each cell with two or three neighbors survives. 
For a space that is 'empty' or 'unpopulated' 
	Each cell with three neighbors becomes populated. 
*/

#include "fractured.h"

class PaintLife : public FracturedPainter {
public:
	FracturedPainter_StdMthds; // define standard methods here (in fractured.h)
	int init(int survivalFlags, int birthFlags);

	////////////////////
	PaintLife();
	PaintLife(int species_);

	////////////////////
	//uint8* field;	/// array of cells (one or zero, on or off)
	//int width, height;	/// size of field (not size of layer!)
	int states;	/// total states
	int wrapping;	/// should wrap left to right, top to bottom
	enum {
		WrappingNone, /// no wrapping at edges
		WrappingTile, /// wrap edges so tileable
		WrappingMirror, /// mirror edges back around so 4 tileable
		WrappingTotal,
	};
	bool birthRules[10];
	bool survivalRules[10];

	////////////////////
	/*enum Species {
	};*/

private:

};
