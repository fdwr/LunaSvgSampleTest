/**
\file	icAxisAngle.h
\author	Dwayne Robinson
\since	2005-08-02
\date	2005-08-02
\brief	Axis-angle container.

\remark	These members should all be public because this is more of a
		nicely encapsulated, glorified structure than a fully abstracted,
		unnecessarily polymorphic class.
*/

#pragma once
#ifndef icAxisAngle_h

#include "BasicTypes.h"

#define icAxisAngle_h
class icAxisAngle {
public:
	union {
		double array[4];
		struct {
			double degrees, x, y, z;
			// What order makes more sense?
			// degrees is really more of a fourth member added to it
			// but putting it before the others makes them all
			// line up nicely alphabetical.
			// Plus, this way it matches the order of the
			// quaternions and glRotate().

			// Degrees is purposefully not named degrees to avoid ambiguity.
			// Storing radians could have a little more numerical precision,
			// but radians are tedious for humans to work with, and the one
			// grahpics system that uses rotation about an arbitrary axis
			// (OpenGL) uses angles anyway.
		};
	};

	icAxisAngle();
	icAxisAngle(IN double degrees, IN double x, IN double y, IN double z);
	icAxisAngle& init();
	icAxisAngle& set(IN double degrees, IN double x, IN double y, IN double z);

	icAxisAngle operator *(IN icAxisAngle& b);
	icAxisAngle& operator *=(IN icAxisAngle& b);
	icAxisAngle& fromMatrix(IN double* mat);
	icAxisAngle& fromMatrixLite(IN double* mat);
	icAxisAngle& toMatrix(OUT double* mat);
	icAxisAngle& normalize();
	icAxisAngle& quantize();
};

#endif
