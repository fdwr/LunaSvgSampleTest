/**
file:	quat.cpp
author:	Dwayne Robinson
since:	2005-07-28
date:	2005-08-02
brief:	Just some quaternion functions.

remark:
	All matrices are 4x4 (not useless 3x3), since those are the kind you
	will most likely use with either OpenGL or DirectX.
remark:
	I do NOT trust all these functions yet. Although I assumed the copied
	formulas are accurate, they have not been verified for correctness;
	and my initial tests were dissappointing.
*/

#define quat_cpp
#include "quat.h"
#define _USE_MATH_DEFINES // should be default :-/
#include <math.h>
#include <float.h>
#include <assert.h>

#pragma warning(disable: 4244) // stupid double to float warnings

quat::quat(quat::uninitialized)
{
	// Do nothing - don't need to wastefully initialize values
	// that will just be replaced later anyway.
	// if you must, you can explicitly call init().
}


quat::quat()
: x(0), y(0), z(0), w(1)
{
}


quat::quat(__in Real _x, __in Real _y, __in Real _z, __in Real _w)
: x(_x), y(_y), z(_z), w(_w)
{
}


quat& quat::setIdentity() // if you need default values
{
	x = y = z = 0;
	w = 1;
	return *this;
}

quat& quat::set(__in Real _x, __in Real _y, __in Real _z, __in Real _w)
{
	x = _x; y = _y; z = _z; w = _w;
	return *this;
}


/** Multiply
*/
quat quat::operator *(__in quat& q)
{
	quat r;

	r.w = w*q.w - x*q.x - y*q.y - z*q.z;
	r.x = w*q.x + x*q.w + y*q.z - z*q.y;
	r.y = w*q.y + y*q.w + z*q.x - x*q.z;
	r.z = w*q.z + z*q.w + x*q.y - y*q.x;

	return r;
}

quat& quat::operator *=(__in quat& q)
{
	quat r;

	r.w = w*q.w - x*q.x - y*q.y - z*q.z;
	r.x = w*q.x + x*q.w + y*q.z - z*q.y;
	r.y = w*q.y + y*q.w + z*q.x - x*q.z;
	r.z = w*q.z + z*q.w + x*q.y - y*q.x;
	w = r.w;
	x = r.x;
	y = r.y;
	z = r.z;

	return *this;
}


/** Normalize quaternion.

formula from http://www.cprogramming.com/tutorial/3d/quaternions.html

There is rarely a need to normalize a unit quaternion (and since they just
express rotation, their magnitude should usually be one), but if the
floating point accuracy eventually degrades, you may need to need renormalize.

If the sum of (w*w + x*x + y*y + z*z) = 1 +-tolerance, there is no need to
do the square root.
*/
quat& quat::normalize()
{
	Real magnitude = sqrt(w*w + x*x + y*y + z*z);
	w /= magnitude;
	x /= magnitude;
	y /= magnitude;
	z /= magnitude;

	return *this;
}

/** Quaternion to matrix (more numerically stable).

revised to use http://www.gametutorials.com/gtstore/pc-79-1-md3-animation.aspx
works better than the light version

*/
quat& quat::fromMatrix(__in Real* mat)
{
	assert(mat != nullptr);

	// The next step, once we made sure we are dealing with a 4x4 matrix, is to check the
	// diagonal of the matrix.  This means that we add up all of the indices that comprise
	// the standard 1's in the identity matrix.  If you draw out the identity matrix of a
	// 4x4 matrix, you will see that they 1's form a diagonal line.  Notice we just assume
	// that the last index (15) is 1 because it is not effected in the 3x3 rotation matrix.

	// Find the diagonal of the matrix by adding up it's diagonal indices.
	// This is also known as the "trace", but I will call the variable diagonal.
	Real diagonal = mat[0] + mat[5] + mat[10] + 1;
	Real scale;

	// Below we check if the diagonal is greater than zero.  To avoid accidents with
	// floating point numbers, we substitute 0 with 0.00000001.  If the diagonal is
	// great than zero, we can perform an "instant" calculation, otherwise we will need
	// to identify which diagonal element has the greatest value.  Note, that it appears
	// that %99 of the time, the diagonal IS greater than 0 so the rest is rarely used.

	// If the diagonal is greater than zero
	if (diagonal > DBL_EPSILON) // 0.00000001)
	{
		// Calculate the scale of the diagonal
		scale = Real(sqrt(diagonal ) * 2);

		// Calculate the x, y, x and w of the quaternion through the respective equation
		x = ( mat[9] - mat[6] ) / scale;
		y = ( mat[2] - mat[8] ) / scale;
		z = ( mat[4] - mat[1] ) / scale;
		w = 0.25f * scale;
	}
	else 
	{
		// If the first element of the diagonal is the greatest value
		if ( mat[0] > mat[5] && mat[0] > mat[10] )  
		{	
			// Find the scale according to the first element, and double that value
			scale  = sqrt( 1.0 + mat[0] - mat[5] - mat[10] ) * 2.0;

			// Calculate the x, y, x and w of the quaternion through the respective equation
			x = 0.25f * scale;
			y = (mat[4] + mat[1] ) / scale;
			z = (mat[2] + mat[8] ) / scale;
			w = (mat[9] - mat[6] ) / scale;	
		} 
		// Else if the second element of the diagonal is the greatest value
		else if ( mat[5] > mat[10] ) 
		{
			// Find the scale according to the second element, and double that value
			scale  = sqrt( 1.0 + mat[5] - mat[0] - mat[10] ) * 2.0;
			
			// Calculate the x, y, x and w of the quaternion through the respective equation
			x = (mat[4] + mat[1] ) / scale;
			y = 0.25f * scale;
			z = (mat[9] + mat[6] ) / scale;
			w = (mat[2] - mat[8] ) / scale;
		} 
		// Else the third element of the diagonal is the greatest value
		else 
		{	
			// Find the scale according to the third element, and double that value
			scale  = sqrt( 1.0 + mat[10] - mat[0] - mat[5] ) * 2.0;

			// Calculate the x, y, x and w of the quaternion through the respective equation
			x = (mat[2] + mat[8] ) / scale;
			y = (mat[9] + mat[6] ) / scale;
			z = 0.25f * scale;
			w = (mat[4] - mat[1] ) / scale;
		}
	}


	return *this;
}

/** Quaternion to matrix (lighter and faster).

from http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm
*/
quat& quat::fromMatrixLite(__in Real* mat)
{
	assert(mat != nullptr);
	
	/*
    w = sqrt(1.0 + mat[0][0] + mat[1][1] + mat[2][2]) / 2.0;
	Real w4 = (4.0 * w);
	x = (mat[2][1] - mat[1][2]) / w4 ;
	y = (mat[0][2] - mat[2][0]) / w4 ;
	z = (mat[1][0] - mat[0][1]) / w4 ;
	*/
    w = sqrt(1.0 + mat[4*0+0] + mat[4*1+1] + mat[4*2+2]) / 2.0;
	Real w4 = (4.0 * w);
	x = (mat[4*2+1] - mat[4*1+2]) / w4 ;
	y = (mat[4*0+2] - mat[4*2+0]) / w4 ;
	z = (mat[4*1+0] - mat[4*0+1]) / w4 ;

	return *this;
}


/** Quaternion to matrix.

*/
Real* quat::toMatrix(__out Real* mat)
{
	/*
	// original formula from
	// http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=Quaternion_Camera_Class
	// First row
	pMatrix[ 0] = 1.0f - 2.0f * (y * y + z * z);
	pMatrix[ 1] =        2.0f * (x * y + z * w);
	pMatrix[ 2] =        2.0f * (x * z - y * w);
	pMatrix[ 3] =        0.0f;
	
	// Second row
	pMatrix[ 4] =        2.0f * (x * y - z * w);
	pMatrix[ 5] = 1.0f - 2.0f * (x * x + z * z);
	pMatrix[ 6] =        2.0f * (z * y + x * w);
	pMatrix[ 7] =        0.0f;

	// Third row
	pMatrix[ 8] =        2.0f * (x * z + y * w);
	pMatrix[ 9] =        2.0f * (y * z - x * w);
	pMatrix[10] = 1.0f - 2.0f * (x * x + y * y);
	pMatrix[11] =        0.0f;

	// Fourth row
	pMatrix[12] =        0;
	pMatrix[13] =        0;
	pMatrix[14] =        0;
	pMatrix[15] =      1.0f;
	*/

	/*
	// changed to this from
	// http://www.gametutorials.com/gtstore/pc-79-1-md3-animation.aspx
	// for OpenGL (seems the above flips some signs)
	Real* pMatrix = mat;

	// First row
	pMatrix[ 0] = 1.0f - 2.0f * ( y * y + z * z );  
	pMatrix[ 1] =        2.0f * ( x * y - w * z );  
	pMatrix[ 2] =        2.0f * ( x * z + w * y );  
	pMatrix[ 3] =        0.0f;  

	// Second row
	pMatrix[ 4] =        2.0f * ( x * y + w * z );  
	pMatrix[ 5] = 1.0f - 2.0f * ( x * x + z * z );  
	pMatrix[ 6] =        2.0f * ( y * z - w * x );  
	pMatrix[ 7] =        0.0f;  

	// Third row
	pMatrix[ 8] =        2.0f * ( x * z - w * y );  
	pMatrix[ 9] =        2.0f * ( y * z + w * x );  
	pMatrix[10] = 1.0f - 2.0f * ( x * x + y * y );  
	pMatrix[11] =        0.0f;  

	// Fourth row
	pMatrix[12] =        0;  
	pMatrix[13] =        0;  
	pMatrix[14] =        0;
	pMatrix[15] =      1.0f;
	*/

	assert(mat != nullptr);

	// rearranged the rows by putting similar expressions nearby
	mat[ 0] = 1.0 - 2.0 * ( y * y + z * z );  
	mat[ 5] = 1.0 - 2.0 * ( x * x + z * z );  
	mat[10] = 1.0 - 2.0 * ( x * x + y * y );  

	mat[ 1] = 2.0 * ( x * y - w * z );  
	mat[ 4] = 2.0 * ( x * y + w * z );  

	mat[ 2] = 2.0 * ( x * z + w * y );  
	mat[ 8] = 2.0 * ( x * z - w * y );  

	mat[ 6] = 2.0 * ( y * z - w * x );  
	mat[ 9] = 2.0 * ( y * z + w * x );  

	mat[ 3] = 0.0;  
	mat[ 7] = 0.0;  
	mat[11] = 0.0;  

	mat[12] = 0;  
	mat[13] = 0;  
	mat[14] = 0;  
	mat[15] = 1.0;

	// Now mat[] is a 4x4 homogeneous matrix that can be applied to an OpenGL Matrix
	return mat;
}


/** Angle on axis to quaternion.
*/
quat& quat::fromAxisAngle(__in Real ax, __in Real ay, __in Real az, __in Real degrees)
{
	/* original formula from
	// http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=Quaternion_Camera_Class
	*/

	// convert the degrees to radians
	Real halfAngle = degrees / (180.0*2) * M_PI;
	Real result = sin(halfAngle);
	w = cos(halfAngle);

	// Calculate the x, y and z of the quaternion
	x = ax * result;
	y = ay * result;
	z = az * result;

	return *this;;
}


/** Angle on axis to quaternion.
*/
quat& quat::fromAxisAngle(__in axisangle& axis)
{
	/* original formula from
	// http://nehe.gamedev.net/data/lessons/lesson.asp?lesson=Quaternion_Camera_Class
	*/
	return fromAxisAngle(axis.x, axis.y, axis.z, axis.degrees);
}


/** Quaternion to angle on axis.
formula from http://graphics.cs.uni-sb.de/Courses/ws0203/cg/folien/CG19Animation1.pdf
*/
/*
quat& quat::toAxisAngle(__out Real& ax, __out Real& ay, __out Real& az, __out Real& degrees)
{
	Real sum = x*x + y*y + z*z;
	if (sum > FLT_EPSILON) {
		ax = x / sum;
		ay = y / sum;
		az = z / sum;
		degrees = (2 * acos(w)) * -180.0 / M_PI;
	} else {
		ax = 1;
		ay =
		az =
		degrees = 0;
	}

	return *this;;
}
*/
axisangle& quat::toAxisAngle(__out axisangle& axis)
{
	Real sum = sqrt(x*x + y*y + z*z);
	if (sum > FLT_EPSILON) {
		axis.x = x / sum; // you could avoid the sqrt and divs
		axis.y = y / sum; // since OpenGL will normalize it anyway.
		axis.z = z / sum;
		axis.degrees = (2 * acos(w)) * 180.0 / M_PI;
	} else {
		axis.x = 1;
		axis.y =
		axis.z =
		axis.degrees = 0;
	}

	return axis;
}


/** SLERP :)
*/
quat& quat::slerp(__in quat& qa, __in quat& qb, __in Real t)
{
	//quat qr; // return result

	// Calculate angle beteen them.
	Real costheta = qa.w * qb.w + qa.x * qb.x + qa.y * qb.y + qa.z * qb.z;
	Real theta = acos(costheta);
	// if theta = 0 then return qa
	if (abs(theta) < 0.01){
		w = qa.w;
		x = qa.x;
		y = qa.y;
		z = qa.z;
		return *this;
	}
	// Calculate temporary values.
	Real sinTheta = sqrt(1.0 - costheta*costheta);
	// if theta*2 = 180 degrees then result is undefined
	if (abs(sinTheta) < 0.01){
		w = (qa.w * 0.5 + qb.w * 0.5);
		x = (qa.x * 0.5 + qb.x * 0.5);
		y = (qa.y * 0.5 + qb.y * 0.5);
		z = (qa.z * 0.5 + qb.z * 0.5);
		return *this;
	}
	Real ratioA = sin((1 - t) * theta) / sinTheta;
	Real ratioB = sin(t * theta) / sinTheta;
 
	//calculate Quaternion.
	w = (qa.w * ratioA + qb.w * ratioB);
	x = (qa.x * ratioA + qb.x * ratioB);
	y = (qa.y * ratioA + qb.y * ratioB);
	z = (qa.z * ratioA + qb.z * ratioB);

	return *this;
}



/*
////////////////////////////////////////////////////////////////////////////////
Additional variations from various places...

----------------------------------------

void mul(Quat4d q1,Quat4d q2) {
    x =  q1.x * q2.w + q1.y * q2.z - q1.z * q2.y + q1.w * q2.x;
    y = -q1.x * q2.z + q1.y * q2.w + q1.z * q2.x + q1.w * q2.y;
    z =  q1.x * q2.y - q1.y * q2.x + q1.z * q2.w + q1.w * q2.z;
    w = -q1.x * q2.x - q1.y * q2.y - q1.z * q2.z + q1.w * q2.w;
}


// http://www.cprogramming.com/tutorial/3d/quaternions.html
// Q1 * Q2

Let Q1 and Q2 be two quaternions, which are defined, respectively, as (w1, x1, y1, z1) and (w2, x2, y2, z2).
(Q1 * Q2).w = (w1w2 - x1x2 - y1y2 - z1z2)
(Q1 * Q2).x = (w1x2 + x1w2 + y1z2 - z1y2)
(Q1 * Q2).y = (w1y2 - x1z2 + y1w2 + z1x2)
(Q1 * Q2).z = (w1z2 + x1y2 - y1x2 + z1w2 

----------------------------------------

public final void quatToMatrix(Quat4d q){
Real sqw = q.w*q.w;
Real sqx = q.x*q.x;
Real sqy = q.y*q.y;
Real sqz = q.z*q.z;
m00 = sqx - sqy - sqz + sqw; // since sqw + sqx + sqy + sqz =1
m11 = -sqx + sqy - sqz + sqw;
m22 = -sqx - sqy + sqz + sqw;

Real tmp1 = q.x*q.y;
Real tmp2 = q.z*q.w;
m10 = 2.0 * (tmp1 + tmp2);
m01 = 2.0 * (tmp1 - tmp2);

tmp1 = q.x*q.z;
tmp2 = q.y*q.w;
m20 = 2.0 * (tmp1 - tmp2);
m02 = 2.0 * (tmp1 + tmp2);
tmp1 = q1.y*q.z;
tmp2 = q1.x*q.w;
m21 = 2.0 * (tmp1 + tmp2);
m12 = 2.0 * (tmp1 - tmp2); 
} 

----------------------------------------

// http://www.cprogramming.com/tutorial/3d/quaternions.html
total = local_rotation * total //multiplication order matters on this line
//Before I try to explain that any more, I need to teach you how to generate local_rotation. You'll need to have the axis and angle prepared, and this will convert them to a quaternion. Here's the formula for generating the local_rotation quaternion.
//axis is a unit vector
local_rotation.w = cosf( fAngle/2)
local_rotation.x = axis.x * sinf( fAngle/2 )
local_rotation.y = axis.y * sinf( fAngle/2 )
local_rotation.z = axis.z * sinf( fAngle/2 )

----------------------------------------

// http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToMatrix/index.htm
public void AxisAngleToMatrix(AxisAngle4d a1) {

    Real c = Math.cos(a1.angle);
    Real s = Math.sin(a1.angle);
    Real t = 1.0 - c;
    m00 = c + a1.x*a1.x*t;
    m11 = c + a1.y*a1.y*t;
    m22 = c + a1.z*a1.z*t;


    Real tmp1 = a1.x*a1.y*t;
    Real tmp2 = a1.z*s;
    m10 = tmp1 + tmp2;
    m01 = tmp1 - tmp2;
    tmp1 = a1.x*a1.z*t;
    tmp2 = a1.y*s;
    m20 = tmp1 - tmp2;
    m02 = tmp1 + tmp2;
    tmp1 = a1.y*a1.z*t;
    tmp2 = a1.x*s;
    m21 = tmp1 + tmp2;
    m12 = tmp1 - tmp2;
}



http://www.edn.com/archives/1995/030295/05df3.htm#alg1
Algorithm 1
TX	=	Q2*Q2
TY	=	Q3*Q3
TZ	=	Q4*Q4
TQ	=	TY+TZ
if (TQ + TX + Q1*Q1) is not 0 then
TK = 2 / (TQ + TX + Q1*Q1)
else
TK	=	0
M11	=	1 - TK*TQ
M22	=	1 - TK*(TX + TZ)
M33	=	1 - TK*(TX + TY)
TX	=	TK*Q2
TY	=	TK*Q3
TQ	=	(TK*Q4)*Q1
TK	=	TX*Q3
M12	=	TK - TQ
M21	=	TK + TQ
TQ	=	TY*Q1
TK	=	TX*Q4
M13	=	TK+TQ
M31	=	TK-TQ
TQ	=	TX*Q1
TK	=	TY*Q4
M23	=	TK - TQ
M32	=	TK + TQ

Algorithm 1 normalizes the quaternion as a natural side effect of the
collection of terms, so you need not normalize Q before converting it to a
rotation matrix. You don't need to normalize quaternions before multiplying
them, so, if you use Algorithm 1 to convert a quaternion to a matrix, you need
not normalize quaternions. Omitting the unnecessary normalization saves time. 
*/
