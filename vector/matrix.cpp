/*

This file contains data structures that are used for matrix-related computatons.

Dwayne Robinson

This is preferred over glh's because the functions names are easier and
because the entries are named. However, the glh version has some nice
functions still that should be adopted. There is another nice library that's
part of a parallax mapping demo that I really would rather use, but it
does not store the basis vectors in contiguous memory (so 12,13,14 are
not the translation entries).
*/

#include "matrix.h"

// Yields a rotation matrix of the given degree.
// This function uses radians
mat4x4& mat4x4::setRotationXRad(Real radians) {
	array[0][1] = array[0][2] = array[1][0] = array[2][0] = 0;
	array[0][0] = 1;
	array[1][1] = array[2][2] = cos(radians);
	array[1][2] = -(array[2][1] = sin(radians));
	array[3][0] =
	array[3][1] =
	array[3][2] =
	array[3][3] =
	array[0][3] =
	array[1][3] =
	array[2][3] = 0;
	return (*this);
}

mat4x4& mat4x4::setRotationYRad(Real radians) {
	array[0][1] = array[1][0] = array[1][2] = array[2][1] = 0;
	array[1][1] = 1;
	array[0][0] = array[2][2] = cos(radians);
	array[2][0] = -(array[0][2] = sin(radians));
	array[3][0] =
	array[3][1] =
	array[3][2] =
	array[3][3] =
	array[0][3] =
	array[1][3] =
	array[2][3] = 0;
	return (*this);
}

mat4x4& mat4x4::setRotationZRad(Real radians) {
	array[0][2] = array[1][2] = array[2][0] = array[2][1] = 0;
	array[2][2] = 1;
	array[0][0] = array[1][1] = cos(radians);
	array[0][1] = -(array[1][0] = sin(radians));
	array[3][0] =
	array[3][1] =
	array[3][2] =
	array[3][3] =
	array[0][3] =
	array[1][3] =
	array[2][3] = 0;
	return (*this);
}

/// set rotation to arbitrary axis and angle
mat4x4& mat4x4::setRotation(Real degrees, Real ax, Real ay, Real az)
{
	Real radians, sine, cosine, ab, bc, ca, t;
	Real axis[4];

	axis[0] = ax;
	axis[1] = ay;
	axis[2] = az;
	axis[3] = 0;
	(*((vec3*)axis)).normalize();

	radians = (Real)(degrees * 0.017453292519943295769236907684886);
	sine = sin(radians);
	cosine = cos(radians);
	ab = axis[0] * axis[1] * (1 - cosine);
	bc = axis[1] * axis[2] * (1 - cosine);
	ca = axis[2] * axis[0] * (1 - cosine);

	setIdentity();
	t = axis[0] * axis[0];
	array[0][0] = t + cosine * (1 - t);
	array[2][1] = bc - axis[0] * sine;
	array[1][2] = bc + axis[0] * sine;

	t = axis[1] * axis[1];
	array[1][1] = t + cosine * (1 - t);
	array[2][0] = ca + axis[1] * sine;
	array[0][2] = ca - axis[1] * sine;

	t = axis[2] * axis[2];
	array[2][2] = t + cosine * (1 - t);
	array[1][0] = ab - axis[2] * sine;
	array[0][1] = ab + axis[2] * sine;

	//if (ax == __glZero && ay == __glZero) {
	//m.matrixType = __GL_MT_IS2D;
	//} else {
	//m.matrixType = __GL_MT_W0001;
	//}
	return (*this);
}

// direct from SGI OpenGL sample implementation,
// so I KNOW it works right.
mat4x4& mat4x4::translate(Real x, Real y, Real z) {
	/*
	// so obviously it's more difficult than just this
	array[0][12] += x;
	array[0][13] += y;
	array[0][14] += z;
	*/
    Real m30, m31, m32, m33;

	m30 = x * array[0][0] + y * array[1][0] + z * array[2][0] + array[3][0];
	m31 = x * array[0][1] + y * array[1][1] + z * array[2][1] + array[3][1];
	m32 = x * array[0][2] + y * array[1][2] + z * array[2][2] + array[3][2];
	m33 = x * array[0][3] + y * array[1][3] + z * array[2][3] + array[3][3];
	array[3][0] = m30;
	array[3][1] = m31;
	array[3][2] = m32;
	array[3][3] = m33;

	return (*this);
}

// direct from SGI OpenGL sample implementation,
// so I KNOW it works right.
mat4x4& mat4x4::rotate(Real degrees, Real ax, Real ay, Real az)
{
	mat4x4 m; // temp matrix
	m.setRotation(degrees, ax,ay,az);

	//if (ax == __glZero && ay == __glZero) {
	//m.matrixType = __GL_MT_IS2D;
	//} else {
	//m.matrixType = __GL_MT_W0001;
	//}

	multiplyRight(m);
	return (*this);
}

