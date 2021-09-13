/**
\file	icQuat.h
\author	Dwayne Robinson
\since	2005-07-28
\brief	Just some quaternion functions.

\remark	These members should all be public because this is more of a
		nicely encapsulated, glorified structure than a fully abstracted,
		unnecessarily polymorphic class.

\remark	These pass quaternions by reference rather than value, since forcing
		the caller to push 32 bytes every call is ridiculous (4*8 if double).
		The code is just as short on this side (using maybe esi instead of esp)
		but shortens the caller side to a single dword.

\remark	w  x  y  z  Description  
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
#ifndef icQuat_h

#include "BasicTypes.h"
#include "icAxisAngle.h"

#define icQuat_h
//#ifndef icAxisAngle_h
//class icAxisAngle;
//#endif

class icQuat {
public:
	union {
		double array[4];
		struct {
			double w, x, y, z;
			// what order makes more sense?
			// w is really more of a fourth member added to it
			// but putting it before the others makes them all
			// line up nicely alphabetical.
		};
	};

	icQuat();
	icQuat(IN double w, IN double x, IN double y, IN double z);
	//icQuat(IN double ax, IN double ay, IN double az, IN double degrees);
	icQuat& init();

	icQuat operator *(IN icQuat& q);
	icQuat& operator *=(IN icQuat& q);

	icQuat& fromAxisAngle(IN double degrees, IN double ax, IN double ay, IN double az);
	icQuat& fromAxisAngle(IN icAxisAngle& axis);
	icAxisAngle& toAxisAngle(OUT icAxisAngle& axis);

	icQuat& fromMatrix(IN double* mat);
	icQuat& fromMatrixLite(IN double* mat);
	double* toMatrix(OUT double* mat);

	icQuat& normalize();
};

#endif
