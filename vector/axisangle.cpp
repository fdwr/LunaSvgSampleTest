/**
\file	axisangle.cpp
\author	Dwayne Robinson
\since	2005-08-02
\date	2005-08-02
\brief	Just some axis-angle functions.

\remark	All matrices are 4x4 (not useless 3x3), since those are the kind you
		will most likely use with either OpenGL or DirectX.
*/

#define _USE_MATH_DEFINES // should be default :-/

#define axisangle_cpp
#include "axisangle.h"
#include <math.h>
#include <float.h>
#include <assert.h>
#include "quat.h"

#pragma warning(disable: 4244) // stupid double to float warnings

axisangle::axisangle()
{
	// DO NOTHING - don't need to wastefully initialize values
	// that will just be replaced later anyway.
	// if you must, you can explicitly call init().
}


axisangle::axisangle(__in Real _x, __in Real _y, __in Real _z, __in Real _degrees)
{
	degrees = _degrees;
	x = _x;
	y = _y;
	z = _z;
}


axisangle& axisangle::init() // if you really want it
{
	x = 1;
	degrees = y = z = 0;
	return *this;
}



axisangle& axisangle::set(__in Real _x, __in Real _y, __in Real _z, __in Real _degrees)
{
	degrees = _degrees;
	x = _x;
	y = _y;
	z = _z;
	return *this;
}


/** Multiply
*/
axisangle axisangle::operator *(__in axisangle& b)
{
	quat q1, q2;
	axisangle r;
	q1.fromAxisAngle(degrees, x,y,z);
	q2.fromAxisAngle(b.degrees, b.x, b.y, b.z);
	q1 *= q2;
	q1.toAxisAngle(*this);

	return r;
}


axisangle& axisangle::operator *=(__in axisangle& b)
{
	quat q1, q2;
	axisangle r;
	q1.fromAxisAngle(degrees, x,y,z);
	q2.fromAxisAngle(b.degrees, b.x, b.y, b.z);
	q1 *= q2;
	q1.toAxisAngle(*this);

	return *this;
}


/** Normalize axis angle.

\remark	Does not 'fix' values or change signs.
\remark	Normalization of the axis is not really necessary since OpenGL
		will accept non normalized axes fine.
*/
axisangle& axisangle::normalize()
{
	Real magnitude = sqrt(x*x + y*y + z*z);
	if (magnitude > FLT_EPSILON) {
		x /= magnitude;
		y /= magnitude;
		z /= magnitude;
	}

	return *this;
}


/* Fixes angle axis values to look nice.

\remark	Rounds to nearest 90 multiple if close enough.
\remark	Makes degrees positive.
\remark	Forces other two axes to zero if close enough.
*/
axisangle& axisangle::quantize()
{
	// round to nearest if close enough
	if (fmod(90-abs(degrees), 90) <= .0001) degrees = floor(degrees+.5);
	if (degrees < 0) {
		degrees = -degrees;
		x = -x;
		y = -y;
		z = -z;
	}
	if (fabs(x) < FLT_EPSILON && fabs(y) < FLT_EPSILON) { if (z < 0) z = -1; else z = 1; }
	if (fabs(x) < FLT_EPSILON && fabs(z) < FLT_EPSILON) { if (y < 0) y = -1; else y = 1; }
	if (fabs(y) < FLT_EPSILON && fabs(z) < FLT_EPSILON) { if (x < 0) x = -1; else x = 1; }

	return *this;
}


/** Convert matrix to axis and angle form

\param[in]	m	matrix 4x4

newer version from http://www.gametutorials.com/gtstore/pc-79-1-md3-animation.aspx
earlier version from http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToAngle/index.htm
*/
axisangle& axisangle::fromMatrix(__in Real* mat)
{
	assert(mat != nullptr);

	quat q1;
	q1.fromMatrix(mat);
	q1.toAxisAngle(*this);
	return *this;
}

/** Convert matrix to axis and angle form

\param[in]	m	matrix 4x4

**** This alternate code fails for certain orientations ****
**** If it could be fixed though, might be both faster  ****
**** and more accurate than converting to and from quat ****

*/
/*
void MatrixToAxisAngle(Real m[][4], Real& angle, Real& x, Real& y, Real& z)
{
	Real epsilon = 0.01;
	if (abs(m[0][1]-m[1][0]) < epsilon && abs(m[0][2]-m[2][0]) < epsilon && abs(m[1][2]-m[2][1])< epsilon) {
		// singularity found
		if (abs(m[0][1]+m[1][0]) < epsilon && abs(m[0][2]+m[2][0]) < epsilon && abs(m[1][2]+m[2][1]) < 0.1) {
			// this singularity is identity matrix so angle = 0
			// note epsilon is greater in this case since we only have to distinguish between 0 and 180 degrees
			angle = 0;
			x = 1; // axis is arbitrary
			y = 0;
			z = 0;
			return;
		}
		// otherwise this singularity is angle = 180
		angle = M_PI;
		x = (m[0][0]+1)/2;
		if (x > 0) { // can only take square root of positive number, always true for orthogonal matrix
			x = sqrt(x);
		} else {
			x = 0; // in case matrix has become de-orthogonalised
		}
		y = (m[1][1]+1)/2;
		if (y > 0) { // can only take square root of positive number, always true for orthogonal matrix
			y = sqrt(y);
		} else {
			y = 0; // in case matrix has become de-orthogonalised
		}
		z = (m[2][2]+1)/2;
		if (z > 0) { // can only take square root of positive number, always true for orthogonal matrix
			z = sqrt(z);
		} else {
			z = 0; // in case matrix has become de-orthogonalised
		}
		bool xZero = (abs(x)<epsilon);
		bool yZero = (abs(y)<epsilon);
		bool zZero = (abs(z)<epsilon);
		bool xyPositive = (m[0][1] > 0);
		bool xzPositive = (m[0][2] > 0);
		bool yzPositive = (m[1][2] > 0);
		if (xZero && !yZero && !zZero) y = -y;
		else if (yZero && !zZero) z = -z;
		else if (zZero) x = -x;
		else if (xyPositive && xzPositive && yzPositive) return;
		else if (yzPositive) x=-x;
		else if (xzPositive) y=-y;
		else if (xyPositive) z=-z;
		return;
	}
	Real s = sqrt((m[2][1] - m[1][2])*(m[2][1] - m[1][2])+(m[0][2] - m[2][0])*(m[0][2] - m[2][0])+(m[1][0] - m[0][1])*(m[1][0] - m[0][1])); // used to normalise
	if (abs(s) < 0.001) s=1; // prevent divide by zero, should not happen if matrix is orthogonal and should be
		// caught by singularity test above, but I've left it in just in case
	angle = acos(( m[0][0] + m[1][1] + m[2][2] - 1)/2) * (180.0*2) / (M_PI*-2);
	x = (m[2][1] - m[1][2])/s;
	y = (m[0][2] - m[2][0])/s;
	z = (m[1][0] - m[0][1])/s;
}
*/



/*
void EulerToAxisAngle(Real heading, Real attitude, Real bank) {
	// Assuming the angles are in radians.
	Real c1 = Math.cos(heading/2);
	Real s1 = Math.sin(heading/2);
	Real c2 = Math.cos(attitude/2);
	Real s2 = Math.sin(attitude/2);
	Real c3 = Math.cos(bank/2);
	Real s3 = Math.sin(bank/2);
	Real c1c2 = c1*c2;
	Real s1s2 = s1*s2;
	w =c1c2*c3 - s1s2*s3;
	x =c1c2*s3 + s1s2*c3;
	y =s1*c2*c3 + c1*s2*s3;
	z =c1*s2*c3 - s1*c2*s3;
	angle = 2 * Math.acos(w);
	Real norm = x*x+y*y+z*z;
	if (norm < 0.001) { // when all euler angles are zero angle =0 so
		// we can set axis to anything to avoid divide by zero
		x=1;
		y=z=0;
	} else {
		norm = Math.sqrt(norm);
    	x /= norm;
    	y /= norm;
    	z /= norm;
	}
}
*/


/** Axis angle to matrix (lighter and faster).

from http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm
*/
axisangle& axisangle::fromMatrixLite(__in Real* mat)
{
	assert(mat != nullptr);

	quat q1;
	q1.fromMatrixLite(mat);
	q1.toAxisAngle(*this);
	return *this;
}


/** Axis angle to matrix.

\remark	Simply converts to quaternion and then to matrix, rather than
		trying to rotate on an arbitrary axis. You really don't need
		to use this function though since glRotate() uses the values
		exactly as is (degrees,x,y,z).
*/
axisangle& axisangle::toMatrix(__out Real* mat)
{
	quat quat;
	quat.fromAxisAngle(*this);
	quat.toMatrix(mat);

	// Now mat[] is a 4x4 homogeneous matrix that can be applied to an OpenGL Matrix
	return *this;
}
