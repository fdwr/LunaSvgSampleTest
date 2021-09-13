/*

This file contains data structures that are used for vector-related computatons.

Dwayne Robinson June 2005
*/

#include "icVector.h"

// project another vector onto the current one
// the produced vector points exactly along the same line
// as the original, but is shortened, lengthened, or reversed.
void icVector3::project(const icVector3 &a)
{
	double selfdot = entry[0] * entry[0] // the vector length squared
	               + entry[1] * entry[1]
	               + entry[2] * entry[2];
	if (selfdot == 0) {
		entry[0] = 
		entry[1] =
		entry[2] = 0;
	} else {
		//this::operator*= dot(this, b) / lengthSqr;
		double product = (entry[0] * a.entry[0] + entry[1] * a.entry[1] + entry[2] * a.entry[2]) / selfdot;
		entry[0] *= product;
		entry[1] *= product;
		entry[2] *= product;
	}
	//return (icVector3*)this;??
}

