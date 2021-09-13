/*

This file contains data structures that are used for matrix-related computatons.

Eugene Zhang  January 2005
Added 4x4 for OpenGL convenience - Dwayne Robinson

This is preferred over glh's because the functions names are easier and
because the entries are named. However, the glh version has some nice
functions still that should be adopted. There is another nice library that's
part of a parallax mapping demo that I really would rather use, but it
does not store the basis vectors in contiguous memory (so 12,13,14 are
not the translation entries).
*/

#ifndef matrix_is_defined
#define matrix_is_defined

#include <math.h>

class mat2x2;
class mat3x3;
class mat4x4;

#include "vec.h"

/*
#ifndef Real
#define Real float
#endif
*/
typedef double Real;

#pragma warning(push)
#pragma warning(disable : 4244)

// start for class mat2x2
class mat2x2 {
public:
	inline mat2x2();
	inline mat2x2(Real x);
	inline mat2x2(const mat2x2& that);

	inline mat2x2(
		Real M00, Real M01, 
		Real M10, Real M11);
	inline mat2x2(Real M[2][2]);

	inline mat2x2& set      (const Real d);
	inline mat2x2& operator=(const Real d);

	inline mat2x2& set      (const mat2x2& that);  
	inline mat2x2& operator=(const mat2x2& that); 

	inline mat2x2& set			 (Real M[2][2]);
	inline mat2x2& operator=(Real M[2][2]); 

	inline int operator!=(const mat2x2& that)const; 
	inline int operator==(const mat2x2& that)const; 

	inline int operator==(Real d) const;
	inline int operator!=(Real d) const;
		
	inline mat2x2& operator+=(Real d);
	inline mat2x2& operator-=(Real d);
	inline mat2x2& operator*=(Real d);

	// component-wise operations.
	inline mat2x2& operator+=(const mat2x2& that);
	inline mat2x2& operator-=(const mat2x2& that);
	inline mat2x2& operator*=(const mat2x2& that);

	// Left : this = that x this  
	// Right: this = this x that
	mat2x2& multiplyLeft(const mat2x2& that);
	mat2x2& multiplyRight(const mat2x2& that);

	inline mat2x2& setIdentity     ();

public:
	union {
		Real array[2][2];
		struct {
			vec2 x,y;
		};
		struct { // named entries for simplicity (and reduce mistakes)
			Real
				xx, xy,
				yx, yy;
		};
	};

};

inline mat2x2 operator+(const mat2x2& a, Real b);
inline mat2x2 operator-(const mat2x2& a, Real b);
inline mat2x2 operator*(const mat2x2& a, Real b);

inline mat2x2 operator+(const mat2x2& a, const mat2x2& b);
inline mat2x2 operator-(const mat2x2& a, const mat2x2& b);
inline mat2x2 operator*(const mat2x2& a, const mat2x2& b); 

inline mat2x2 multiply(const mat2x2& a, const mat2x2& b); 
inline vec2   operator*(const mat2x2& a, const vec2& b);
inline vec2   operator*(const vec2& a, const mat2x2& b);

inline Real determinant(const mat2x2& a);

inline mat2x2 transpose(const mat2x2& a);
inline mat2x2   inverse(const mat2x2& a);

inline mat2x2::mat2x2() {
  array[0][0] = 1;
  array[0][1] = 0;
  array[1][0] = 0;
  array[1][1] = 1;
}

inline mat2x2::mat2x2(Real x) {
  array[0][0] = x;
  array[0][1] = x;
  array[1][0] = x;
  array[1][1] = x;
}

inline mat2x2::mat2x2(Real M00, Real M01, 
				Real M10, Real M11) {
  array[0][0] = M00;
  array[0][1] = M01;
  array[1][0] = M10;
  array[1][1] = M11;
};

inline mat2x2::mat2x2(const mat2x2& that) {
  array[0][0] = that.array[0][0];
  array[0][1] = that.array[0][1];
  array[1][0] = that.array[1][0];
  array[1][1] = that.array[1][1];
};

inline mat2x2& mat2x2::set(const Real d) {
  return (*this)=d;
}

inline mat2x2& mat2x2::operator=(const Real d) {
  array[0][0] = d;
  array[0][1] = d;

  array[1][0] = d;
  array[1][1] = d;
  return (*this);
};

inline mat2x2& mat2x2::set(const mat2x2& that) {
  return (*this)=that;
}

inline mat2x2& mat2x2::operator=(const mat2x2& that) {
  array[0][0] = that.array[0][0];
  array[0][1] = that.array[0][1];

  array[1][0] = that.array[1][0];
  array[1][1] = that.array[1][1];
  return (*this);
};

inline mat2x2& mat2x2::set(Real M[2][2]) {
  return (*this)=M;
}

inline mat2x2& mat2x2::operator=(Real M[2][2]) {
  array[0][0] = M[0][0];
  array[0][1] = M[0][1];

  array[1][0] = M[1][0];
  array[1][1] = M[1][1];
  return (*this);
};

inline int mat2x2::operator==(Real d) const {
  return  ( (array[0][0] == d) &&
	    (array[0][1] == d) &&
	    (array[1][0] == d) &&
	    (array[1][1] == d) );
}

inline int mat2x2::operator!=(Real d) const {
  return  ( (array[0][0] != d) ||
	    (array[0][1] != d) ||
	    (array[1][0] != d) ||
	    (array[1][1] != d) );
}
  
inline int mat2x2::operator==(const mat2x2& that)const {
  return ( (array[0][0] == that.array[0][0]) &&
	   (array[0][1] == that.array[0][1]) &&
	   (array[1][0] == that.array[1][0]) &&
	   (array[1][1] == that.array[1][1]) );
}

inline int mat2x2::operator!=(const mat2x2& that)const {
  return ( (array[0][0] != that.array[0][0]) ||
	   (array[0][1] != that.array[0][1]) ||
	   (array[1][0] != that.array[1][0]) ||
	   (array[1][1] != that.array[1][1]) );
}

inline mat2x2& mat2x2::operator+=(Real d) {
  array[0][0] += d; array[1][0] += d; 
  array[0][1] += d; array[1][1] += d; 
  return (*this);
}

inline mat2x2& mat2x2::operator-=(Real d) {
  array[0][0] -= d; array[1][0] -= d; 
  array[0][1] -= d; array[1][1] -= d; 
  return (*this);
}

inline mat2x2& mat2x2::operator*=(Real d) {
  array[0][0] *= d; array[1][0] *= d; 
  array[0][1] *= d; array[1][1] *= d; 
  return (*this);
}

inline mat2x2& mat2x2::operator+=(const mat2x2& that) {
  array[0][0] += that.array[0][0]; array[1][0] += that.array[1][0]; 
  array[0][1] += that.array[0][1]; array[1][1] += that.array[1][1]; 
  return (*this);
}
  
inline mat2x2& mat2x2::operator-=(const mat2x2& that) {
  array[0][0] -= that.array[0][0]; array[1][0] -= that.array[1][0]; 
  array[0][1] -= that.array[0][1]; array[1][1] -= that.array[1][1]; 
  return (*this);
}

inline mat2x2& mat2x2::operator*=(const mat2x2& that) {
  array[0][0] *= that.array[0][0]; array[1][0] *= that.array[1][0]; 
  array[0][1] *= that.array[0][1]; array[1][1] *= that.array[1][1]; 
  return (*this);
}

inline mat2x2& mat2x2::multiplyLeft(const mat2x2& that){
	mat2x2 tmp(array[0][0], array[0][1], array[1][0], array[1][1]);
	
	array[0][0] = that.array[0][0] * tmp.array[0][0] + that.array[0][1] * tmp.array[1][0];
	array[0][1] = that.array[0][0] * tmp.array[0][1] + that.array[0][1] * tmp.array[1][1];
	array[1][0] = that.array[1][0] * tmp.array[0][0] + that.array[1][1] * tmp.array[1][0];
	array[1][1] = that.array[1][0] * tmp.array[0][1] + that.array[1][1] * tmp.array[1][1];
	return (*this);
};

inline mat2x2& mat2x2::multiplyRight(const mat2x2& that){
	mat2x2 tmp(array[0][0], array[0][1], array[1][0], array[1][1]);

	array[0][0] = tmp.array[0][0] * that.array[0][0] + tmp.array[0][1] * that.array[1][0];
	array[0][1] = tmp.array[0][0] * that.array[0][1] + tmp.array[0][1] * that.array[1][1];
	array[1][0] = tmp.array[1][0] * that.array[0][0] + tmp.array[1][1] * that.array[1][0];
	array[1][1] = tmp.array[1][0] * that.array[0][1] + tmp.array[1][1] * that.array[1][1];
	return (*this);
};

inline mat2x2& mat2x2::setIdentity() {
  array[0][0] = 1; array[0][1] = 0; 
  array[1][0] = 0; array[1][1] = 1; 
  return (*this);
};

inline mat2x2 operator+(const mat2x2& a,Real b) {
  return (mat2x2(a)+=b);
}

inline mat2x2 operator-(const mat2x2& a,Real b) {
  return (mat2x2(a)-=b);
}

inline mat2x2 operator*(const mat2x2& a,Real b) {
  return (mat2x2(a)*=b);
}
 
inline mat2x2 operator+(Real a, const mat2x2& b) {
return b+a;
}

inline mat2x2 operator-(Real a, const mat2x2& b) {
  return mat2x2(a-b.array[0][0],a-b.array[0][1],
		     a-b.array[1][0],a-b.array[1][1]);
}

inline mat2x2 operator*(Real a, const mat2x2& b) {
  return b*a;
}
 
inline mat2x2 operator+(const mat2x2& a,const mat2x2& b) {
  return (mat2x2(a)+=b);
}
 
inline mat2x2 operator-(const mat2x2& a,const mat2x2& b) {
  return (mat2x2(a)-=b);
}

inline mat2x2 operator*(const mat2x2& a,const mat2x2& b) {
  return (mat2x2(a)*=b);
}

inline mat2x2 multiply(const mat2x2& a,const mat2x2& b) {
  mat2x2 tmp(a);
  tmp.multiplyRight(b);
  return tmp;
}

inline vec2 operator*(const mat2x2& a,const vec2 &b) {
  return vec2(b.array[0]*a.array[0][0] + b.array[1]*a.array[0][1],
		   b.array[0]*a.array[1][0] + b.array[1]*a.array[1][1]);
}

inline vec2 operator*(const vec2 &a,const mat2x2& b) {
  return vec2(a.array[0]*b.array[0][0] + a.array[1]*b.array[1][0],
		   a.array[0]*b.array[0][1] + a.array[1]*b.array[1][1]);
}

inline Real determinant(const mat2x2& a) {
  return ( a.array[0][0] * a.array[1][1] - a.array[0][1] * a.array[1][0] );
}

inline mat2x2 transpose(const mat2x2& a) {
  mat2x2 tmp(a);

	tmp.array[0][1] = a.array[1][0];
	tmp.array[1][0] = a.array[0][1];
  return tmp;
}

inline mat2x2 inverse(const mat2x2& a) {
	mat2x2 tmp;
	Real dmt;
	
	if ((dmt=determinant(a))!= 0.0) {
		tmp.array[0][0] = a.array[1][1]/dmt;
		tmp.array[0][1] = -a.array[0][1]/dmt;
		tmp.array[1][0] = -a.array[1][0]/dmt;
		tmp.array[1][1] = a.array[0][0]/dmt;
	}
	return tmp;
}


// start for class mat3x3
class mat3x3 {
public:
	inline mat3x3();
	inline mat3x3(Real x);
	inline mat3x3(const mat3x3& that);
	inline mat3x3(const vec3& v1, const vec3& v2, const vec3& v3);

	inline mat3x3(
		Real xx, Real xy, Real xz,
		Real yx, Real yy, Real yz,
		Real zx, Real zy, Real zz);
	inline mat3x3(Real M[3][3]);

	inline mat3x3& set      (const Real d);
	inline mat3x3& operator=(const Real d);

	inline mat3x3& set      (const mat3x3& that);  
	inline mat3x3& operator=(const mat3x3& that); 

	inline mat3x3& set			 (Real M[3][3]);
	inline mat3x3& operator=(Real M[3][3]); 

	inline mat3x3& setBasis	(const vec3& v1, const vec3& v2, const vec3& v3);
	inline mat3x3& setBasis (
		Real xx, Real xy, Real xz,
		Real yx, Real yy, Real yz,
		Real zx, Real zy, Real zz);

	inline mat3x3& setRotationXDeg(Real degrees);
	inline mat3x3& setRotationYDeg(Real degrees);
	inline mat3x3& setRotationZDeg(Real degrees);
	inline mat3x3& setRotationXRad(Real radians);
	inline mat3x3& setRotationYRad(Real radians);
	inline mat3x3& setRotationZRad(Real radians);
	inline int operator!=(const mat3x3& that)const; 
	inline int operator==(const mat3x3& that)const; 

	inline int operator==(Real d) const;
	inline int operator!=(Real d) const;

	inline mat3x3& operator+=(Real d);
	inline mat3x3& operator-=(Real d);
	inline mat3x3& operator*=(Real d);

	// component-wise operations.
	inline mat3x3& operator+=(const mat3x3& that);
	inline mat3x3& operator-=(const mat3x3& that);
	inline mat3x3& operator*=(const mat3x3& that);

	// Multiply Left : this = that x this  
	// Multiply Right: this = this x that
	mat3x3& multiplyLeft(const mat3x3& that);
	mat3x3& multiplyRight(const mat3x3& that);

	inline mat3x3& setIdentity();

	//inline Real  operator[](int index) const;
	//inline Real& operator[](int index);
	inline operator Real*();

public:
	union {
		Real array[3][3];
		struct {
			vec3 right, up, forward; // right, up, forward (confirm or deny?)
		};
		struct { // named entries for simplicity (and reduce mistakes)
			Real
				xs, yx, zx,
				xy, ys, zy,
				xt, yt, zs;
		};
	};
};

inline mat3x3 operator+(const mat3x3& a, Real b);
inline mat3x3 operator-(const mat3x3& a, Real b);
inline mat3x3 operator*(const mat3x3& a, Real b);

inline mat3x3 operator+(const mat3x3& a, const mat3x3& b);
inline mat3x3 operator-(const mat3x3& a, const mat3x3& b);
inline mat3x3 operator*(const mat3x3& a, const mat3x3& b); 

inline mat3x3 multiply(const mat3x3& a, const mat3x3& b); 
inline mat3x3 conjugate(const mat3x3& a, const mat3x3& b); 
inline mat3x3 othoconjugate(const mat3x3& a, const mat3x3& b); 
inline vec3   operator*(const mat3x3& a, const vec3& b);
inline vec3   operator*(const vec3& a, const mat3x3& b);

inline Real determinant(const mat3x3& a);

inline mat3x3 transpose(const mat3x3& a);
inline mat3x3   inverse(const mat3x3& a);

inline mat3x3::mat3x3() {
  array[0][0] = 1;
  array[0][1] = 0;
  array[0][2] = 0;
  array[1][0] = 0;
  array[1][1] = 1;
  array[1][2] = 0;
  array[2][0] = 0;
  array[2][1] = 0;
  array[2][2] = 1;
}

inline mat3x3::mat3x3(Real x) {
  array[0][0] = x;
  array[0][1] = x;
  array[0][2] = x;
  array[1][0] = x;
  array[1][1] = x;
  array[1][2] = x;
  array[2][0] = x;
  array[2][1] = x;
  array[2][2] = x;
}

inline mat3x3::mat3x3(
	Real xx, Real xy, Real xz,
	Real yx, Real yy, Real yz,
	Real zx, Real zy, Real zz)
{
  array[0][0] = xx;
  array[0][1] = xy;
  array[0][2] = xz;
  array[1][0] = yx;
  array[1][1] = yy;
  array[1][2] = yz;
  array[2][0] = zx;
  array[2][1] = zy;
  array[2][2] = zz;
};

inline mat3x3::mat3x3(const mat3x3& that) {
  array[0][0] = that.array[0][0];
  array[0][1] = that.array[0][1];
  array[0][2] = that.array[0][2];
  array[1][0] = that.array[1][0];
  array[1][1] = that.array[1][1];
  array[1][2] = that.array[1][2];
  array[2][0] = that.array[2][0];
  array[2][1] = that.array[2][1];
  array[2][2] = that.array[2][2];
};

inline mat3x3::mat3x3(const vec3 &v1, const vec3 &v2, const vec3 &v3) {
	array[0][0] = v1.array[0];
	array[0][1] = v1.array[1];
	array[0][2] = v1.array[2];
	array[1][0] = v2.array[0];
	array[1][1] = v2.array[1];
	array[1][2] = v2.array[2];
	array[2][0] = v3.array[0];
	array[2][1] = v3.array[1];
	array[2][2] = v3.array[2];
}

inline mat3x3& mat3x3::set(const Real d) {
  return (*this)=d;
}

inline mat3x3& mat3x3::operator=(const Real d) {
  array[0][0] = d;
  array[0][1] = d;
  array[0][2] = d;

  array[1][0] = d;
  array[1][1] = d;
  array[1][2] = d;

  array[2][0] = d;
  array[2][1] = d;
  array[2][2] = d;

  return (*this);
};

inline mat3x3& mat3x3::set(const mat3x3& that) {
  return (*this)=that;
}

inline mat3x3& mat3x3::operator=(const mat3x3& that) {
  array[0][0] = that.array[0][0];
  array[0][1] = that.array[0][1];
  array[0][2] = that.array[0][2];
  array[1][0] = that.array[1][0];
  array[1][1] = that.array[1][1];
  array[1][2] = that.array[1][2];
  array[2][0] = that.array[2][0];
  array[2][1] = that.array[2][1];
  array[2][2] = that.array[2][2];
  return (*this);
};

inline mat3x3& mat3x3::set(Real M[3][3]) {
  return (*this)=M;
}

inline mat3x3& mat3x3::operator=(Real M[3][3]) {
  array[0][0] = M[0][0];
  array[0][1] = M[0][1];
  array[0][2] = M[0][2];

  array[1][0] = M[1][0];
  array[1][1] = M[1][1];
  array[1][2] = M[1][2];

  array[2][0] = M[2][0];
  array[2][1] = M[2][1];
  array[2][2] = M[2][2];
return (*this);
};

// Builds the matrix using basis vectors.
inline mat3x3& mat3x3::setBasis(const vec3 &vx, const vec3 &vy, const vec3 &vz) {
	array[0][0] = vx.x;
	array[0][1] = vx.y;
	array[0][2] = vx.z;
	array[1][0] = vy.x;
	array[1][1] = vy.y;
	array[1][2] = vy.z;
	array[2][0] = vz.x;
	array[2][1] = vz.y;
	array[2][2] = vz.z;
	return (*this);
}

// Builds the matrix using basis vectors.
inline mat3x3& mat3x3::setBasis (
	Real xx, Real xy, Real xz,
	Real yx, Real yy, Real yz,
	Real zx, Real zy, Real zz)
{
	array[0][0] = xx;
	array[0][1] = xy;
	array[0][2] = xz;
	array[1][0] = yx;
	array[1][1] = yy;
	array[1][2] = yz;
	array[2][0] = zx;
	array[2][1] = zy;
	array[2][2] = zz;
	return (*this);
}

// Yields a rotation matrix of the given degree.
// This function uses degrees rather than radians.
inline mat3x3& mat3x3::setRotationXDeg(Real degrees) {
	Real radians = (Real)(degrees * 0.017453292519943295769236907684886);
	return setRotationXRad(radians);
}

inline mat3x3& mat3x3::setRotationYDeg(Real degrees) {
	Real radians = (Real)(degrees * 0.017453292519943295769236907684886);
	return setRotationYRad(radians);
}

inline mat3x3& mat3x3::setRotationZDeg(Real degrees) {
	Real radians = (Real)(degrees * 0.017453292519943295769236907684886);
	return setRotationZRad(radians);
}

// Yields a rotation matrix of the given radians.
// This function uses radians.
inline mat3x3& mat3x3::setRotationXRad(Real radians) {
	array[0][1] = array[0][2] = array[1][0] = array[2][0] = 0;
	array[0][0] = 1;
	array[1][1] = array[2][2] = cos(radians);
	array[1][2] = -(array[2][1] = sin(radians));
	return (*this);
}

inline mat3x3& mat3x3::setRotationYRad(Real radians) {
	array[0][1] = array[1][0] = array[1][2] = array[2][1] = 0;
	array[1][1] = 1;
	array[0][0] = array[2][2] = cos(radians);
	array[2][0] = -(array[0][2] = sin(radians));
	return (*this);
}

inline mat3x3& mat3x3::setRotationZRad(Real radians) {
	array[0][2] = array[1][2] = array[2][0] = array[2][1] = 0;
	array[2][2] = 1;
	array[0][0] = array[1][1] = cos(radians);
	array[0][1] = -(array[1][0] = sin(radians));
	return (*this);
}

inline int mat3x3::operator==(Real d) const {
  return  ( (array[0][0] == d) && (array[0][1] == d) && (array[0][2] == d) &&
						(array[1][0] == d) && (array[1][1] == d) && (array[1][2] == d) && 
						(array[2][0] == d) && (array[2][1] == d) && (array[2][2] == d));
}

inline int mat3x3::operator!=(Real d) const {
  return  ( (array[0][0] != d) || (array[0][1] != d) || (array[0][2] != d) ||
						(array[1][0] != d) || (array[1][1] != d) || (array[1][2] != d) ||
						(array[2][0] != d) || (array[2][1] != d) || (array[2][2] != d));
}
  
inline int mat3x3::operator==(const mat3x3& that)const {
  return ( (array[0][0] == that.array[0][0]) && (array[0][1] == that.array[0][1]) && (array[0][2] == that.array[0][2]) &&
					 (array[1][0] == that.array[1][0]) && (array[1][1] == that.array[1][1]) && (array[1][2] == that.array[1][2]) &&
					 (array[2][0] == that.array[2][0]) && (array[2][1] == that.array[2][1]) && (array[2][2] == that.array[2][2]));
}

inline int mat3x3::operator!=(const mat3x3& that)const {
  return ( (array[0][0] != that.array[0][0]) || (array[0][1] != that.array[0][1]) || (array[0][2] != that.array[0][2]) ||
					 (array[1][0] != that.array[1][0]) || (array[1][1] != that.array[1][1]) || (array[1][2] != that.array[1][2]) ||
					 (array[2][0] != that.array[2][0]) || (array[2][1] != that.array[2][1]) || (array[2][2] != that.array[2][2]));
}

inline mat3x3& mat3x3::operator+=(Real d) {
  array[0][0] += d; array[0][1] += d; array[0][2] += d; 
  array[1][0] += d; array[1][1] += d; array[1][2] += d; 
  array[2][0] += d; array[2][1] += d; array[2][2] += d; 
  return (*this);
}

inline mat3x3& mat3x3::operator-=(Real d) {
  array[0][0] -= d; array[0][1] -= d; array[0][2] -= d; 
  array[1][0] -= d; array[1][1] -= d; array[1][2] -= d;
  array[2][0] -= d; array[2][1] -= d; array[2][2] -= d;
  return (*this);
}

inline mat3x3& mat3x3::operator*=(Real d) {
  array[0][0] *= d; array[0][1] *= d; array[0][2] *= d; 
  array[1][0] *= d; array[1][1] *= d; array[1][2] *= d; 
  array[2][0] *= d; array[2][1] *= d; array[2][2] *= d; 
  return (*this);
}

inline mat3x3& mat3x3::operator+=(const mat3x3& that) {
  array[0][0] += that.array[0][0]; array[0][1] += that.array[0][1]; array[0][2] += that.array[0][2]; 
  array[1][0] += that.array[1][0]; array[1][1] += that.array[1][1]; array[1][2] += that.array[1][2]; 
  array[2][0] += that.array[2][0]; array[2][1] += that.array[2][1]; array[2][2] += that.array[2][2]; 
  return (*this);
}
  
inline mat3x3& mat3x3::operator-=(const mat3x3& that) {
  array[0][0] -= that.array[0][0]; array[0][1] -= that.array[0][1]; array[0][2] -= that.array[0][2]; 
  array[1][0] -= that.array[1][0]; array[1][1] -= that.array[1][1]; array[1][2] -= that.array[1][2]; 
  array[2][0] -= that.array[2][0]; array[2][1] -= that.array[2][1]; array[2][2] -= that.array[2][2]; 
  return (*this);
}

inline mat3x3& mat3x3::operator*=(const mat3x3& that) {
  array[0][0] *= that.array[0][0]; array[0][1] *= that.array[0][1]; array[0][2] *= that.array[0][2]; 
  array[1][0] *= that.array[1][0]; array[1][1] *= that.array[1][1]; array[1][2] *= that.array[1][2]; 
  array[2][0] *= that.array[2][0]; array[2][1] *= that.array[2][1]; array[2][2] *= that.array[2][2]; 
  return (*this);
}

inline mat3x3& mat3x3::multiplyLeft(const mat3x3& that){
	mat3x3 tmp(*this);
	
	// todo: break apart, and verify correctness
	array[0][0] = that.array[0][0]*tmp.array[0][0] + that.array[0][1]*tmp.array[1][0] + that.array[0][2]*tmp.array[2][0];
	array[0][1] = that.array[0][0]*tmp.array[0][1] + that.array[0][1]*tmp.array[1][1] + that.array[0][2]*tmp.array[2][1];
	array[0][2] = that.array[0][0]*tmp.array[0][2] + that.array[0][1]*tmp.array[1][2] + that.array[0][2]*tmp.array[2][2];

	array[1][0] = that.array[1][0]*tmp.array[0][0] + that.array[1][1]*tmp.array[1][0] + that.array[1][2]*tmp.array[2][0];
	array[1][1] = that.array[1][0]*tmp.array[0][1] + that.array[1][1]*tmp.array[1][1] + that.array[1][2]*tmp.array[2][1];
	array[1][2] = that.array[1][0]*tmp.array[0][2] + that.array[1][1]*tmp.array[1][2] + that.array[1][2]*tmp.array[2][2];

	array[2][0] = that.array[2][0]*tmp.array[0][0] + that.array[2][1]*tmp.array[1][0] + that.array[2][2]*tmp.array[2][0];
	array[2][1] = that.array[2][0]*tmp.array[0][1] + that.array[2][1]*tmp.array[1][1] + that.array[2][2]*tmp.array[2][1];
	array[2][2] = that.array[2][0]*tmp.array[0][2] + that.array[2][1]*tmp.array[1][2] + that.array[2][2]*tmp.array[2][2];
	return (*this);
};

inline mat3x3& mat3x3::multiplyRight(const mat3x3& that){
	mat3x3 tmp(*this);

	// todo: break apart, and verify correctness
	array[0][0] = tmp.array[0][0]*that.array[0][0] + tmp.array[0][1]*that.array[1][0] + tmp.array[0][2]*that.array[2][0];
	array[0][1] = tmp.array[0][0]*that.array[0][1] + tmp.array[0][1]*that.array[1][1] + tmp.array[0][2]*that.array[2][1];
	array[0][2] = tmp.array[0][0]*that.array[0][2] + tmp.array[0][1]*that.array[1][2] + tmp.array[0][2]*that.array[2][2];

	array[1][0] = tmp.array[1][0]*that.array[0][0] + tmp.array[1][1]*that.array[1][0] + tmp.array[1][2]*that.array[2][0];
	array[1][1] = tmp.array[1][0]*that.array[0][1] + tmp.array[1][1]*that.array[1][1] + tmp.array[1][2]*that.array[2][1];
	array[1][2] = tmp.array[1][0]*that.array[0][2] + tmp.array[1][1]*that.array[1][2] + tmp.array[1][2]*that.array[2][2];

	array[2][0] = tmp.array[2][0]*that.array[0][0] + tmp.array[2][1]*that.array[1][0] + tmp.array[2][2]*that.array[2][0];
	array[2][1] = tmp.array[2][0]*that.array[0][1] + tmp.array[2][1]*that.array[1][1] + tmp.array[2][2]*that.array[2][1];
	array[2][2] = tmp.array[2][0]*that.array[0][2] + tmp.array[2][1]*that.array[1][2] + tmp.array[2][2]*that.array[2][2];
	return (*this);
};

inline mat3x3& mat3x3::setIdentity() {
  array[0][0] = 1; array[0][1] = 0; array[0][2] = 0; 
  array[1][0] = 0; array[1][1] = 1; array[1][2] = 0; 
  array[2][0] = 0; array[2][1] = 0; array[2][2] = 1; 
  return (*this);
};

inline mat3x3 operator+(const mat3x3& a,Real b) {
  return (mat3x3(a)+=b);
}

inline mat3x3 operator-(const mat3x3& a,Real b) {
  return (mat3x3(a)-=b);
}

inline mat3x3 operator*(const mat3x3& a,Real b) {
  return (mat3x3(a)*=b);
}
 
inline mat3x3 operator+(Real a, const mat3x3& b) {
return b+a;
}

inline mat3x3 operator-(Real a, const mat3x3& b) {
	return mat3x3(
		a-b.array[0][0],a-b.array[0][1],a-b.array[0][2],
		a-b.array[1][0],a-b.array[1][1],a-b.array[1][2],
		a-b.array[2][0],a-b.array[2][1],a-b.array[2][2]);
}

inline mat3x3 operator*(Real a, const mat3x3& b) {
	return b*a;
}
 
inline mat3x3 operator+(const mat3x3& a,const mat3x3& b) {
	return (mat3x3(a)+=b);
}
 
inline mat3x3 operator-(const mat3x3& a,const mat3x3& b) {
	return (mat3x3(a)-=b);
}

inline mat3x3 operator*(const mat3x3& a,const mat3x3& b) {
	return (mat3x3(a)*=b);
}

inline mat3x3::operator Real*()
{
	return &array[0][0];
}

inline mat3x3 multiply(const mat3x3& a,const mat3x3& b) {
	mat3x3 tmp(a);
	tmp.multiplyRight(b);
	return tmp;
}

inline mat3x3 conjugate(const mat3x3 a, const mat3x3& b) {
	mat3x3 tmp(a);
	mat3x3 c = inverse(b);
	tmp.multiplyRight(b);
	tmp.multiplyLeft(c);
	return tmp;
}

inline mat3x3 othoconjugate(const mat3x3 a, const mat3x3& b) {
	mat3x3 tmp(a);
	mat3x3 c = transpose(b);
	tmp.multiplyRight(b);
	tmp.multiplyLeft(c);
	return tmp;
}

inline vec3 operator*(const mat3x3& a,const vec3 &b) {
	vec3 tmp;
	for (int i=0; i < 3; i++)
		tmp.array[i] =
			a.array[0][i] * b.x +
			a.array[1][i] * b.y +
			a.array[2][i] * b.z;
	return tmp;
}

inline vec3 operator*(const vec3 &a,const mat3x3& b) {
	vec3 tmp;
	for (int i=0; i < 3; i++)
		tmp.array[i] =
			b.array[i][0] * a.x +
			b.array[i][1] * a.y +
			b.array[i][2] * a.z;
	return tmp;
}

inline Real determinant(const mat3x3& a) {
  return (
	  a.array[0][0] * a.array[1][1] * a.array[2][2] - a.array[2][0] * a.array[1][1] * a.array[0][2]
	+ a.array[1][0] * a.array[2][1] * a.array[0][2] - a.array[0][0] * a.array[2][1] * a.array[1][2]
	+ a.array[2][0] * a.array[0][1] * a.array[1][2] - a.array[1][0] * a.array[0][1] * a.array[2][2]);
}

inline mat3x3 transpose(const mat3x3& a) {
	mat3x3 tmp(a);

	tmp.array[0][1] = a.array[1][0];
	tmp.array[1][0] = a.array[0][1];

	tmp.array[0][2] = a.array[2][0];
	tmp.array[2][0] = a.array[0][2];

	tmp.array[2][1] = a.array[1][2];
	tmp.array[1][2] = a.array[2][1];
  return tmp;
}

inline mat3x3 inverse(const mat3x3& a) {
	mat3x3 tmp;
	Real dmt;
	
	if ((dmt=determinant(a))!= 0.0) {
		tmp.array[0][0] = (a.array[1][1] * a.array[2][2] - a.array[2][1] * a.array[1][2])/dmt;
		tmp.array[0][1] = (a.array[2][1] * a.array[0][2] - a.array[0][1] * a.array[2][2])/dmt;
		tmp.array[0][2] = (a.array[0][1] * a.array[1][2] - a.array[1][1] * a.array[0][2])/dmt;

		tmp.array[1][0] = (a.array[1][2] * a.array[2][0] - a.array[2][2] * a.array[1][0])/dmt;
		tmp.array[1][1] = (a.array[2][2] * a.array[0][0] - a.array[0][2] * a.array[2][0])/dmt;
		tmp.array[1][2] = (a.array[0][2] * a.array[1][0] - a.array[1][2] * a.array[0][0])/dmt;

		tmp.array[2][0] = (a.array[1][0] * a.array[2][1] - a.array[2][0] * a.array[1][1])/dmt;
		tmp.array[2][1] = (a.array[2][0] * a.array[0][1] - a.array[0][0] * a.array[2][1])/dmt;
		tmp.array[2][2] = (a.array[0][0] * a.array[1][1] - a.array[1][0] * a.array[0][1])/dmt;
	}
	return tmp;
}


// start for class mat4x4
//
// ! THIS IS NOT A FULL 4x4 CLASS YET !
//
// I just copied the 3x3, renamed it, and extended the few necessary functions
// like the constructor. Everything else still works on the 3x3 subportion of it.
class mat4x4 {
public:
	inline mat4x4();
	inline mat4x4(Real x);
	inline mat4x4(const Real* that);
	inline mat4x4(const mat4x4& that);
	inline mat4x4(const vec3& v1, const vec3& v2, const vec3& v3);

	inline mat4x4(
		Real M00, Real M01, Real M02,
		Real M10, Real M11, Real M12,
		Real M20, Real M21, Real M22);
	//inline mat4x4(Real M[3][3]);
	inline mat4x4(float M[4][4]);

	inline mat4x4& set      (const Real d);
	inline mat4x4& operator=(const Real d);

	inline mat4x4& set      (const mat4x4& that);  
	inline mat4x4& operator=(const mat4x4& that); 

	//inline mat4x4& set			 (Real M[3][3]);
	//inline mat4x4& operator=(Real M[3][3]); 
	inline mat4x4& set			 (float M[4][4]);
	inline mat4x4& operator=(float M[4][4]); 

	inline mat4x4& setIdentity();

	inline mat4x4& setBasis (const vec3& v1, const vec3& v2, const vec3& v3, const vec3& v4);
	inline mat4x4& setBasis (
		Real Xx, Real Xy, Real Xz,
		Real Yx, Real Yy, Real Yz,
		Real Zx, Real Zy, Real Zz);
	inline mat4x4& setRotationXDeg(Real degrees);
	inline mat4x4& setRotationYDeg(Real degrees);
	inline mat4x4& setRotationZDeg(Real degrees);
	mat4x4& setRotationXRad(Real radians);
	mat4x4& setRotationYRad(Real radians);
	mat4x4& setRotationZRad(Real radians);
	mat4x4& setRotation(Real degrees, Real ax, Real ay, Real az);
	inline int operator!=(const mat4x4& that)const; 
	inline int operator==(const mat4x4& that)const; 

	inline int operator==(Real d) const;
	inline int operator!=(Real d) const;

	inline mat4x4& operator+=(Real d);
	inline mat4x4& operator-=(Real d);
	inline mat4x4& operator*=(Real d);

	// component-wise operations.
	inline mat4x4& operator+=(const mat4x4& that);
	inline mat4x4& operator-=(const mat4x4& that);
	inline mat4x4& operator*=(const mat4x4& that);

	// Left : this = that x this  
	// Right: this = this x that
	mat4x4& multiplyLeft(const mat4x4& that);
	mat4x4& multiplyRight(const mat4x4& that);
	vec3 multiplyPoint(const vec3 &b) const;
	vec3 multiplyVector(const vec3 &b) const;

	inline mat4x4& transpose();
	mat4x4& translate(Real x, Real y, Real z);
	mat4x4& rotate(Real degrees, Real ax, Real ay, Real az);

	inline operator Real*();

public:
	union {
		Real f[16];
		Real m[4][4];
		struct { // named entries for simplicity (and reduce mistakes)
			Real
				xx, xy, xz, xw,
				yx, yy, yz, yw,
				zx, zy, zz, zw,
				dx, dy, dz, dw;
		};
		struct {
			vec4 right, up, forward, translate;
		};
		/*
		OpenGL:

		m00 m01 m02 m03    x
		m10 m11 m12 m13    y
		m20 m21 m22 m23    z
		m30 m31 m32 m33    1

		 xx  yx  zx  dx    x
		 xy  yy  zy  dy    y
		 xz  yz  zz  dz    z
		 xw  yw  zw  dw    1

		| 1 0 0 x |
		| 0 1 0 y |
		| 0 0 1 z |
		| 0 0 0 1 | -> {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, y, z, 1}

		|  1  4  8 12 |
		|  1  5  9 13 |
		|  2  6 10 14 |
		|  3  7 11 15 | translation 12,13,14 = m03,m13,m23

		NewX = x * m00 + y * m01 + z * m02 + m03 * 1;
		NewY = x * m10 + y * m11 + z * m12 + m13 * 1;
		NewZ = x * m20 + y * m21 + z * m22 + m23 * 1;
		NewW = x * m30 + y * m31 + z * m32 + m33 * 1;

		NewX = x * xx + y * xy + z * xz + xd * 1;
		NewY = x * yx + y * yy + z * yz + yd * 1;
		NewZ = x * zx + y * zy + z * zz + zd * 1;
		NewW = x * wx + y * wy + z * wz + wd * 1;

		NewX = xx * x + xy * y + xz * z + xd * 1;
		NewY = yx * x + yy * y + yz * z + yd * 1;
		NewZ = zx * x + zy * y + zz * z + zd * 1;
		NewW = wx * x + wy * y + wz * z + wd * 1;


		DirectX:
		          m00 m01 m02 m03
		          m10 m11 m12 m13
		x y z 1   m20 m21 m22 m23
		          m30 m31 m32 m33

		           xx  xy  xz  xw
		           yx  yy  yz  yw
		x y z 1    zx  zy  zz  zw
		           dx  dy  dz  dw

		| 1 0 0 0 |
		| 0 1 0 0 |
		| 0 0 1 0 |
		| x y z 1 | -> {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, y, z, 1}

		|  1  2  3  4 |
		|  5  6  7  8 |
		|  9 10 11 12 |
		|  2 13 14 15 | translation 12,13,14 = m30,m31,m32

		NewX = x * m00 + y * m10 + z * m20 + m30 * 1;
		NewY = x * m01 + y * m11 + z * m21 + m31 * 1;
		NewZ = x * m02 + y * m12 + z * m22 + m32 * 1;
		NewW = x * m03 + y * m13 + z * m23 + m33 * 1;

		NewX = x * xx + y * yx + z * zx + dx * 1;
		NewY = x * xy + y * yy + z * zy + dy * 1;
		NewZ = x * xz + y * yz + z * zz + dz * 1;
		NewW = x * xw + y * yw + z * zw + dw * 1;
		*/
	};
};

inline mat4x4 operator+(const mat4x4& a, Real b);
inline mat4x4 operator-(const mat4x4& a, Real b);
inline mat4x4 operator*(const mat4x4& a, Real b);

inline mat4x4 operator+(const mat4x4& a, const mat4x4& b);
inline mat4x4 operator-(const mat4x4& a, const mat4x4& b);
inline mat4x4 operator*(const mat4x4& a, const mat4x4& b); 

inline mat4x4 multiply(const mat4x4& a, const mat4x4& b); 
inline mat4x4 conjugate(const mat4x4& a, const mat4x4& b); 
inline mat4x4 othoconjugate(const mat4x4& a, const mat4x4& b); 
inline vec3   operator*(const mat4x4& a, const vec3  & b);
inline vec3   operator*(const vec3  & a, const mat4x4& b);

inline Real determinant(const mat4x4& a);

inline mat4x4 transpose(const mat4x4& a);
inline mat4x4   inverse(const mat4x4& a);

inline mat4x4::mat4x4() {
	this->setIdentity();
}

inline mat4x4::mat4x4(Real x) {
	{	for (int i =0; i < 4*4; i++) array[0][i] = x;	}
}

inline mat4x4::mat4x4(
	Real M00, Real M01, Real M02,
	Real M10, Real M11, Real M12,
	Real M20, Real M21, Real M22)
{
	array[0][0] = M00;
	array[0][1] = M01;
	array[0][2] = M02;
	array[1][0] = M10;
	array[1][1] = M11;
	array[1][2] = M12;
	array[2][0] = M20;
	array[2][1] = M21;
	array[2][2] = M22;
	array[0][3] = 
	array[1][3] = 
	array[2][3] = 
	array[3][0] = 
	array[3][1] = 
	array[3][2] = 
	array[3][3] = 0;
};

inline mat4x4::mat4x4(const mat4x4& that) {
	for (int i =0; i < 4*4; i++)
		array[0][i] = that.array[0][i];
};

inline mat4x4::mat4x4(const Real* that) {
	for (int i =0; i < 4*4; i++)
		array[0][i] = that[i];
}

inline mat4x4::mat4x4(const vec3& v1, const vec3& v2, const vec3& v3) {
	array[0][0] = v1.array[0];
	array[0][1] = v1.array[1];
	array[0][2] = v1.array[2];
	array[1][0] = v2.array[0];
	array[1][1] = v2.array[1];
	array[1][2] = v2.array[2];
	array[2][0] = v3.array[0];
	array[2][1] = v3.array[1];
	array[2][2] = v3.array[2];
	array[0][3] = 
	array[1][3] = 
	array[2][3] = 
	array[3][0] = 
	array[3][1] = 
	array[3][2] = 
	array[3][3] = 0;
}

inline mat4x4::mat4x4(float M[4][4]) {
	{	for (int i =0; i < 4*4; i++) array[0][i] = M[0][i];	}
}

inline mat4x4& mat4x4::set(const Real d) {
	return (*this)=d;
}

inline mat4x4& mat4x4::operator=(const Real d) {
	{	for (int i =0; i < 4*4; i++) array[0][i] = d;	}
	return (*this);
};

inline mat4x4& mat4x4::set(const mat4x4& that) {
  return (*this)=that;
}

inline mat4x4& mat4x4::operator=(const mat4x4& that) {
	{	for (int i =0; i < 4*4; i++) array[0][i] = that.array[0][i];	}
	return (*this);
};

//inline mat4x4& mat4x4::set(Real M[3][3]) {
//  return (*this)=M;
//}

inline mat4x4& mat4x4::set(float M[4][4]) {
  return (*this)=M;
}

inline mat4x4& mat4x4::operator=(float M[4][4]) {
	{	for (int i = 0; i < 4*4; i++) array[0][i] = M[0][i];	}
	return (*this);
};

// Builds the matrix using the basis vectors.
inline mat4x4& mat4x4::setBasis(const vec3& v1, const vec3& v2, const vec3& v3, const vec3& v4) {
	for (int i=0; i < 4; i++) {
		array[i][0] = v1.array[0];
		array[i][1] = v1.array[1];
		array[i][2] = v1.array[2];
		array[i][3] = 0;
	}
	return (*this);
}

// Builds the matrix using basis vectors.
// Does not change the translation component, so set to identity first if you want.
inline mat4x4& mat4x4::setBasis (
	Real Xx, Real Xy, Real Xz,
	Real Yx, Real Yy, Real Yz,
	Real Zx, Real Zy, Real Zz)
{
	array[0][0] = Xx;
	array[0][1] = Xy;
	array[0][2] = Xz;
	array[1][0] = Yx;
	array[1][1] = Yy;
	array[1][2] = Yz;
	array[2][0] = Zx;
	array[2][1] = Zy;
	array[2][2] = Zz;
	array[2][0] = Zx;
	array[2][1] = Zy;
	array[2][2] = Zz;
	return (*this);
}

// Yields a rotation matrix of the given degree.
// This function uses degrees rather than radians
inline mat4x4& mat4x4::setRotationXDeg(Real degrees) {
	Real radians = (float)(degrees * 0.017453292519943295769236907684886);
	return setRotationXRad(radians);
}

inline mat4x4& mat4x4::setRotationYDeg(Real degrees) {
	Real radians = (float)(degrees * 0.017453292519943295769236907684886);
	return setRotationYRad(radians);
}

inline mat4x4& mat4x4::setRotationZDeg(Real degrees) {
	Real radians = (float)(degrees * 0.017453292519943295769236907684886);
	return setRotationZRad(radians);
}

inline int mat4x4::operator==(Real d) const {
  return  ( (array[0][0] == d) && (array[0][1] == d) && (array[0][2] == d) &&
						(array[1][0] == d) && (array[1][1] == d) && (array[1][2] == d) && 
						(array[2][0] == d) && (array[2][1] == d) && (array[2][2] == d));
}

inline int mat4x4::operator!=(Real d) const {
  return  ( (array[0][0] != d) || (array[0][1] != d) || (array[0][2] != d) ||
						(array[1][0] != d) || (array[1][1] != d) || (array[1][2] != d) ||
						(array[2][0] != d) || (array[2][1] != d) || (array[2][2] != d));
}
  
inline int mat4x4::operator==(const mat4x4& that)const {
  return ( (array[0][0] == that.array[0][0]) && (array[0][1] == that.array[0][1]) && (array[0][2] == that.array[0][2]) &&
					 (array[1][0] == that.array[1][0]) && (array[1][1] == that.array[1][1]) && (array[1][2] == that.array[1][2]) &&
					 (array[2][0] == that.array[2][0]) && (array[2][1] == that.array[2][1]) && (array[2][2] == that.array[2][2]));
}

inline int mat4x4::operator!=(const mat4x4& that)const {
  return ( (array[0][0] != that.array[0][0]) || (array[0][1] != that.array[0][1]) || (array[0][2] != that.array[0][2]) ||
					 (array[1][0] != that.array[1][0]) || (array[1][1] != that.array[1][1]) || (array[1][2] != that.array[1][2]) ||
					 (array[2][0] != that.array[2][0]) || (array[2][1] != that.array[2][1]) || (array[2][2] != that.array[2][2]));
}

inline mat4x4& mat4x4::operator+=(Real d) {
  array[0][0] += d; array[0][1] += d; array[0][2] += d; 
  array[1][0] += d; array[1][1] += d; array[1][2] += d; 
  array[2][0] += d; array[2][1] += d; array[2][2] += d; 
  return (*this);
}

inline mat4x4& mat4x4::operator-=(Real d) {
  array[0][0] -= d; array[0][1] -= d; array[0][2] -= d; 
  array[1][0] -= d; array[1][1] -= d; array[1][2] -= d;
  array[2][0] -= d; array[2][1] -= d; array[2][2] -= d;
  return (*this);
}

inline mat4x4& mat4x4::operator*=(Real d) {
  array[0][0] *= d; array[0][1] *= d; array[0][2] *= d; 
  array[1][0] *= d; array[1][1] *= d; array[1][2] *= d; 
  array[2][0] *= d; array[2][1] *= d; array[2][2] *= d; 
  return (*this);
}

inline mat4x4& mat4x4::operator+=(const mat4x4& that) {
  array[0][0] += that.array[0][0]; array[0][1] += that.array[0][1]; array[0][2] += that.array[0][2]; 
  array[1][0] += that.array[1][0]; array[1][1] += that.array[1][1]; array[1][2] += that.array[1][2]; 
  array[2][0] += that.array[2][0]; array[2][1] += that.array[2][1]; array[2][2] += that.array[2][2]; 
  return (*this);
}
  
inline mat4x4& mat4x4::operator-=(const mat4x4& that) {
  array[0][0] -= that.array[0][0]; array[0][1] -= that.array[0][1]; array[0][2] -= that.array[0][2]; 
  array[1][0] -= that.array[1][0]; array[1][1] -= that.array[1][1]; array[1][2] -= that.array[1][2]; 
  array[2][0] -= that.array[2][0]; array[2][1] -= that.array[2][1]; array[2][2] -= that.array[2][2]; 
  return (*this);
}

inline mat4x4& mat4x4::operator*=(const mat4x4& that) {
	for (int i=0; i < 4*4; i++) {
		array[0][i] *= that.array[0][i];
	}
	/* full expansion
	array[0][0] *= that.array[0][0]; array[0][1] *= that.array[0][1]; array[0][2] *= that.array[0][2]; 
	array[1][0] *= that.array[1][0]; array[1][1] *= that.array[1][1]; array[1][2] *= that.array[1][2]; 
	array[2][0] *= that.array[2][0]; array[2][1] *= that.array[2][1]; array[2][2] *= that.array[2][2]; 
	*/
	return (*this);
}

inline mat4x4& mat4x4::multiplyLeft(const mat4x4& that){
	mat4x4 tmp(*this);
	for (int i=0; i < 4; i++) {
		for (int j=0; j < 4; j++) {
			array[i][j] =
				tmp.array[i][0] * that.array[0][j] +
				tmp.array[i][1] * that.array[1][j] +
				tmp.array[i][2] * that.array[2][j] +
				tmp.array[i][3] * that.array[3][j];
		}
	}
	return (*this);

	/* full expansion
	array[0][0] = that.array[0][0] * tmp.array[0][0] + that.array[0][1] * tmp.array[1][0] + that.array[0][2] * tmp.array[2][0];
	array[0][1] = that.array[0][0] * tmp.array[0][1] + that.array[0][1] * tmp.array[1][1] + that.array[0][2] * tmp.array[2][1];
	array[0][2] = that.array[0][0] * tmp.array[0][2] + that.array[0][1] * tmp.array[1][2] + that.array[0][2] * tmp.array[2][2];

	array[1][0] = that.array[1][0] * tmp.array[0][0] + that.array[1][1] * tmp.array[1][0] + that.array[1][2] * tmp.array[2][0];
	array[1][1] = that.array[1][0] * tmp.array[0][1] + that.array[1][1] * tmp.array[1][1] + that.array[1][2] * tmp.array[2][1];
	array[1][2] = that.array[1][0] * tmp.array[0][2] + that.array[1][1] * tmp.array[1][2] + that.array[1][2] * tmp.array[2][2];

	array[2][0] = that.array[2][0] * tmp.array[0][0] + that.array[2][1] * tmp.array[1][0] + that.array[2][2] * tmp.array[2][0];
	array[2][1] = that.array[2][0] * tmp.array[0][1] + that.array[2][1] * tmp.array[1][1] + that.array[2][2] * tmp.array[2][1];
	array[2][2] = that.array[2][0] * tmp.array[0][2] + that.array[2][1] * tmp.array[1][2] + that.array[2][2] * tmp.array[2][2];
	*/
};

inline mat4x4& mat4x4::multiplyRight(const mat4x4& that){
	mat4x4 tmp(*this);
	for (int i=0; i < 4; i++) {
		for (int j=0; j < 4; j++) {
			array[i][j] =
				tmp.array[0][j] * that.array[i][0] +
				tmp.array[1][j] * that.array[i][1] +
				tmp.array[2][j] * that.array[i][2] +
				tmp.array[3][j] * that.array[i][3];
		}
	}
	return (*this);

	/* full expansion
	array[0][0] = tmp.array[0][0] * that.array[0][0] + tmp.array[0][1] * that.array[1][0] + tmp.array[0][2] * that.array[2][0];
	array[0][1] = tmp.array[0][0] * that.array[0][1] + tmp.array[0][1] * that.array[1][1] + tmp.array[0][2] * that.array[2][1];
	array[0][2] = tmp.array[0][0] * that.array[0][2] + tmp.array[0][1] * that.array[1][2] + tmp.array[0][2] * that.array[2][2];

	array[1][0] = tmp.array[1][0] * that.array[0][0] + tmp.array[1][1] * that.array[1][0] + tmp.array[1][2] * that.array[2][0];
	array[1][1] = tmp.array[1][0] * that.array[0][1] + tmp.array[1][1] * that.array[1][1] + tmp.array[1][2] * that.array[2][1];
	array[1][2] = tmp.array[1][0] * that.array[0][2] + tmp.array[1][1] * that.array[1][2] + tmp.array[1][2] * that.array[2][2];

	array[2][0] = tmp.array[2][0] * that.array[0][0] + tmp.array[2][1] * that.array[1][0] + tmp.array[2][2] * that.array[2][0];
	array[2][1] = tmp.array[2][0] * that.array[0][1] + tmp.array[2][1] * that.array[1][1] + tmp.array[2][2] * that.array[2][1];
	array[2][2] = tmp.array[2][0] * that.array[0][2] + tmp.array[2][1] * that.array[1][2] + tmp.array[2][2] * that.array[2][2];
	*/
};

inline mat4x4& mat4x4::setIdentity() {
	// clear all to zeroes
	for (int i = 1; i < 4*4; i++)
		array[0][i] = 0.;

	// and set ones along diagonal
	array[0][0] =
	array[1][1] =
	array[2][2] =
	array[3][3] = 1.;
	//array[2][3] = 1. for perspective

	/* manual expansion
	array[0][0] = 1; array[0][1] = 0; array[0][2] = 0; array[0][3] = 1;
	array[1][0] = 0; array[1][1] = 1; array[1][2] = 0; array[1][3] = 1;
	array[2][0] = 0; array[2][1] = 0; array[2][2] = 1; array[2][3] = 1;
	array[3][0] = 0; array[3][1] = 0; array[3][2] = 1; array[3][3] = 1;
	*/

	return (*this);
};

inline mat4x4 operator+(const mat4x4& a,Real b) {
	return (mat4x4(a)+=b);
}

inline mat4x4 operator-(const mat4x4& a,Real b) {
	return (mat4x4(a)-=b);
}

inline mat4x4 operator*(const mat4x4& a,Real b) {
	return (mat4x4(a)*=b);
}
 
inline mat4x4 operator+(Real a, const mat4x4& b) {
	return b+a;
}

inline mat4x4 operator-(Real a, const mat4x4& b) {
	return mat4x4(
		a-b.array[0][0],a-b.array[0][1],a-b.array[0][2],
		a-b.array[1][0],a-b.array[1][1],a-b.array[1][2],
		a-b.array[2][0],a-b.array[2][1],a-b.array[2][2]);
}

inline mat4x4 operator*(Real a, const mat4x4& b) {
	return b*a;
}
 
inline mat4x4 operator+(const mat4x4& a,const mat4x4& b) {
	return (mat4x4(a)+=b);
}
 
inline mat4x4 operator-(const mat4x4& a,const mat4x4& b) {
	return (mat4x4(a)-=b);
}

inline mat4x4 operator*(const mat4x4& a,const mat4x4& b) {
	return (mat4x4(a)*=b);
}

inline mat4x4 multiply(const mat4x4& a,const mat4x4& b) {
	mat4x4 tmp(a);
	tmp.multiplyRight(b);
	return tmp;
}

inline mat4x4 conjugate(const mat4x4 a, const mat4x4& b) {
	mat4x4 tmp(a);
	mat4x4 c = inverse(b);
	tmp.multiplyRight(b);
	tmp.multiplyLeft(c);
	return tmp;
}

inline mat4x4 othoconjugate(const mat4x4 a, const mat4x4& b) {
	mat4x4 tmp(a);
	mat4x4 c = transpose(b);
	tmp.multiplyRight(b);
	tmp.multiplyLeft(c);
	return tmp;
}

// assumes point and sets fourth element (w) to 1
inline vec3 mat4x4::multiplyVector(const vec3 &b) const {
	vec3 tmp;
	for (int i=0; i < 3; i++)
		tmp.array[i] =
			array[0][i] * b.x +
			array[1][i] * b.y +
			array[2][i] * b.z;
			// no translation component (elements 12,13,14)
	return tmp;

	/* dot product expansion
	return vec3(
		b.array[0]*a.array[0][0] + b.array[1]*a.array[0][1] + b.array[2]*a.array[0][2], 
		b.array[0]*a.array[1][0] + b.array[1]*a.array[1][1] + b.array[2]*a.array[1][2],
		b.array[0]*a.array[2][0] + b.array[1]*a.array[2][1] + b.array[2]*a.array[2][2]);
	*/
}

// assumes point and sets fourth element (w) to 1
inline vec3 mat4x4::multiplyPoint(const vec3 &b) const {
	vec3 tmp;
	for (int i=0; i < 3; i++)
		tmp.array[i] =
			array[0][i] * b.x +
			array[1][i] * b.y +
			array[2][i] * b.z +
			array[3][i]; // translation component (elements 12,13,14)
	return tmp;

	/* dot product expansion
	return vec3(
		b.array[0]*a.array[0][0] + b.array[1]*a.array[0][1] + b.array[2]*a.array[0][2], 
		b.array[0]*a.array[1][0] + b.array[1]*a.array[1][1] + b.array[2]*a.array[1][2],
		b.array[0]*a.array[2][0] + b.array[1]*a.array[2][1] + b.array[2]*a.array[2][2]);
	*/
}

// assumes point and sets fourth element (w) to 1
inline vec3 operator*(const mat4x4& a,const vec3 &b) {
	return a.multiplyPoint(b);
}

// assumes point and sets fourth element (w) to 1
//inline vec3 operator*(const vec3 &a,const mat4x4& b) {
//	return multiplyPoint(b);
//}

inline mat4x4::operator Real*()
{
	return &array[0][0];
}

inline Real determinant(const mat4x4& a) {
	return (
		a.array[0][0] * a.array[1][1] * a.array[2][2] - a.array[2][0] * a.array[1][1] * a.array[0][2] +
		a.array[1][0] * a.array[2][1] * a.array[0][2] - a.array[0][0] * a.array[2][1] * a.array[1][2] +
		a.array[2][0] * a.array[0][1] * a.array[1][2] - a.array[1][0] * a.array[0][1] * a.array[2][2]);
}

#define simpleswap(a,b) {Real temp=array[a][b]; array[a][b] = array[b][a]; array[b][a]=temp;}
inline mat4x4& mat4x4::transpose() {
	simpleswap(0,1);
	simpleswap(0,2);
	simpleswap(0,3);
	simpleswap(1,2);
	simpleswap(1,3);
	simpleswap(2,3);
	return (*this);
}
#undef simpleswap

// does not currently return inverse
// considering translation, only the sub 3x3
inline mat4x4 inverse(const mat4x4& a) {
	mat4x4 tmp;
	Real dmt;
	
	if ((dmt=determinant(a))!= 0.0) {
		tmp.array[0][0] = (a.array[1][1] * a.array[2][2] - a.array[2][1] * a.array[1][2])/dmt;
		tmp.array[0][1] = (a.array[2][1] * a.array[0][2] - a.array[0][1] * a.array[2][2])/dmt;
		tmp.array[0][2] = (a.array[0][1] * a.array[1][2] - a.array[1][1] * a.array[0][2])/dmt;

		tmp.array[1][0] = (a.array[1][2] * a.array[2][0] - a.array[2][2] * a.array[1][0])/dmt;
		tmp.array[1][1] = (a.array[2][2] * a.array[0][0] - a.array[0][2] * a.array[2][0])/dmt;
		tmp.array[1][2] = (a.array[0][2] * a.array[1][0] - a.array[1][2] * a.array[0][0])/dmt;

		tmp.array[2][0] = (a.array[1][0] * a.array[2][1] - a.array[2][0] * a.array[1][1])/dmt;
		tmp.array[2][1] = (a.array[2][0] * a.array[0][1] - a.array[0][0] * a.array[2][1])/dmt;
		tmp.array[2][2] = (a.array[0][0] * a.array[1][1] - a.array[1][0] * a.array[0][1])/dmt;
	}
	return tmp;
}


/* // taken from SGI's OpenGL sample implementation
static int __gluInvertMatrixd(const GLdouble src[16], GLdouble inverse[16])
{
    int i, j, k, swap;
    double t;
    GLdouble temp[4][4];

    for (i=0; i<4; i++) {
	for (j=0; j<4; j++) {
	    temp[i][j] = src[i*4+j];
	}
    }
    __gluMakeIdentityd(inverse);

    for (i = 0; i < 4; i++) {
	// Look for largest element in column
	swap = i;
	for (j = i + 1; j < 4; j++) {
	    if (fabs(temp[j][i]) > fabs(temp[i][i])) {
		swap = j;
	    }
	}

	if (swap != i) {
	    // Swap rows.
	    for (k = 0; k < 4; k++) {
		t = temp[i][k];
		temp[i][k] = temp[swap][k];
		temp[swap][k] = t;

		t = inverse[i*4+k];
		inverse[i*4+k] = inverse[swap*4+k];
		inverse[swap*4+k] = t;
	    }
	}

	if (temp[i][i] == 0) {
	    // No non-zero pivot.  The matrix is singular, which shouldn't
	    // happen.  This means the user gave us a bad matrix.
	    return GL_FALSE;
	}

	t = temp[i][i];
	for (k = 0; k < 4; k++) {
	    temp[i][k] /= t;
	    inverse[i*4+k] /= t;
	}
	for (j = 0; j < 4; j++) {
	    if (j != i) {
		t = temp[j][i];
		for (k = 0; k < 4; k++) {
		    temp[j][k] -= temp[i][k]*t;
		    inverse[j*4+k] -= inverse[i*4+k]*t;
		}
	    }
	}
    }
    return GL_TRUE;
}
*/

#pragma warning(pop)

#endif
