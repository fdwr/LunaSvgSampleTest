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
#ifndef __axisangle_h
#define __axisangle_h

#include "types.h"

class axisangle {
public:
	union {
		Real array[4];
		struct {
			Real degrees, x, y, z;
			// What order makes more sense?
			// degrees is really more of a fourth member added to it
			// but putting it before the others makes them all
			// line up nicely alphabetical.
			// Plus, this way it matches the order of the
			// quaternions and glRotate().

			// The angle is named degrees to avoid ambiguity.
			// Storing radians could have a little more numerical precision,
			// but radians are tedious for humans to work with, and the
			// grahpics system this is intended for (OpenGL) supports
			// rotation about an arbitrary axis using angles.
		};
	};

	axisangle();
	axisangle(__in Real x, __in Real y, __in Real z, __in Real degrees);
	axisangle& init();
	axisangle& set(__in Real x, __in Real y, __in Real z, __in Real degrees);

	axisangle operator *(__in axisangle& b);
	axisangle& operator *=(__in axisangle& b);
	axisangle& fromMatrix(__in Real* mat);
	axisangle& fromMatrixLite(__in Real* mat);
	axisangle& toMatrix(__out Real* mat);
	axisangle& normalize();
	axisangle& quantize();
};

#endif
