/**
file:	quat.h
author:	Dwayne Robinson
since:	2005-07-28
brief:	Just some quaternion functions.

todo:
	finish changing order to x,y,z,w instead of current w,x,y,z.
	The alphabetical order looks nicer and goes in the same order
	as glRotate, but ultimately it does not fit as well with vertices
	and matrices (who both set w as the last member).

remark:
	These members should all be public because this is more of a
	nicely encapsulated, glorified structure than a fully abstracted,
	unnecessarily polymorphic class.

remark:
	These pass quaternions by reference rather than value, since forcing
	the caller to push 32 bytes every call is ridiculous (4*8 if double).
	The code is just as short on this side (using maybe esi instead of esp)
	but shortens the caller side to a single dword.

remark:
	w  x  y  z  Description  
	1  0  0  0  Identity quaternion, no rotation  
	0  1  0  0  180' turn around X axis  
	0  0  1  0  180' turn around Y axis  
	0  0  0  1  180' turn around Z axis  
	sqrt(0.5)  sqrt(0.5)  0  0  90' rotation around X axis  
	sqrt(0.5)  0  sqrt(0.5)  0  90' rotation around Y axis  
	sqrt(0.5)  0  0  sqrt(0.5)  90' rotation around Z axis  
	sqrt(0.5)  -sqrt(0.5)  0  0  -90' rotation around X axis  
	sqrt(0.5)  0  -sqrt(0.5)  0  -90' rotation around Y axis  
	sqrt(0.5)  0  0  -sqrt(0.5)  -90' rotation around Z axis  

*/

#pragma once
#ifndef __quat_h
#define __quat_h

#include "types.h" // for SAL annotation inference
#include "axisangle.h"

//#ifndef axisangle_h
//class icAxisAngle;
//#endif

struct quat {
public:
	union {
		Real array[4];
		struct {
			Real x, y, z, w;
			// what order makes more sense?
			// w is really more of a fourth member added to it
			// but putting it before the others makes them all
			// line up nicely alphabetical.
		};
	};

	enum uninitialized {};

	quat();
	quat(__in Real _x, __in Real _y, __in Real _z, __in Real _w);
	quat(quat::uninitialized);

	//quat(__in Real ax, __in Real ay, __in Real az, __in Real degrees);
	quat& init();
	quat& set(__in Real _x, __in Real _y, __in Real _z, __in Real _w); // for convenience

	quat operator *(__in quat& q);
	quat& operator *=(__in quat& q);

	quat& fromAxisAngle(__in Real ax, __in Real ay, __in Real az, __in Real degrees);
	quat& fromAxisAngle(__in axisangle& axis);
	axisangle& toAxisAngle(__out axisangle& axis);

	quat& fromMatrix(__in Real* mat); // 4x4 matrix, 16 values
	quat& fromMatrixLite(__in Real* mat); // 4x4 matrix, 16 values
	Real* toMatrix(__out Real* mat); // 4x4 matrix, 16 values

	quat& normalize();

	quat& slerp(__in quat& qa, __in quat& qb, __in Real t);
};

#endif
