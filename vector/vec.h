/*
This file contains data structures that are used for vector-related computatons.

Eugene Zhang  January 2005
extended by Dwayne Robinson 2005-2007
*/

#pragma once
#ifndef vec_h
#define vec_h

// Templates are not supported yet (not much change needed though).
// So use this define for now.
//#define Real float
//typedef double Real;

class vec2;
class vec3;

extern "C" {
#define _USE_MATH_DEFINES
#include <math.h>
//#include <stdlib.h>
}

//-------------------------------------------------------------------
// Start class vec2

//template <Real>
class vec2
{
public:
	typedef double Real;

	inline vec2();
	inline vec2(Real d);
	inline vec2(Real d0,Real d1);

	inline vec2(const vec2& a);
	inline vec2(const Real* a);

	inline vec2& set(Real d);
	inline vec2& set(Real d0, Real d1);
	inline vec2& set(const vec2& a);
	inline vec2& set(const Real* a);

	inline Real  operator[](int index) const;
	inline Real& operator[](int index);
	inline operator Real*();

	inline vec2& operator=(Real d);
	inline vec2& operator=(const vec2& a);
	inline vec2& operator=(const Real* a);

	inline int operator==(const vec2& a) const;
	inline int operator!=(const vec2& a) const;

	inline int operator==(Real d) const;
	inline int operator!=(Real d) const;

	inline vec2& operator+=(Real d);
	inline vec2& operator-=(Real d);
	inline vec2& operator*=(Real d);
	inline vec2& operator/=(Real d);

	inline vec2& operator+=(const vec2& a);
	inline vec2& operator-=(const vec2& a);
	inline vec2& operator*=(const vec2& a);
	inline vec2& operator/=(const vec2& a);

	inline vec2& normalize();
	inline Real length() const;
	inline Real quadrance() const;
	inline Real dot(const vec2& b) const;
	inline vec2 cross() const;

	static void interpolateTriangle(vec2& p, vec2& a, vec2& b, vec2& c, vec3& w);

public:
	union {
		Real array[2]; /// all the vector entries (an additional alias added later)
		struct {
			Real x, y;
		};
		struct {
			Real s, t;
		};
	};
};

inline vec2 operator-(const vec2& a);

inline vec2 operator+(const vec2& a, const vec2& b);
inline vec2 operator-(const vec2& a, const vec2& b);

inline vec2 operator+(const vec2& a, vec2::Real b);
inline vec2 operator-(const vec2& a, vec2::Real b);
inline vec2 operator*(const vec2& a, vec2::Real b);

inline vec2 operator+(vec2::Real a, const vec2& b);
inline vec2 operator-(vec2::Real a, const vec2& b);
inline vec2 operator*(vec2::Real a, const vec2& b);

//-inline void    normalize(vec2& a);
//-inline Real length(const vec2& a);
//-inline Real quadrance(const vec2& a);
//-inline Real dot(const vec2& a,const vec2& b);
//-inline vec2 cross(const vec2& a);


inline vec2::vec2() {
  x = y = 0.0;
}
inline vec2::vec2(Real d) {
  x = y = d;
}

inline vec2::vec2(Real d0,Real d1) {
  x = d0;
  y = d1;
}

inline vec2::vec2(const vec2& a) {
  x = a.x;
  y = a.y;
}

inline vec2::vec2(const Real* a) {
  x = a[0];
  y = a[1];
}

inline vec2& vec2::set(Real d) {
  x = d;
  y = d;
  return *this;
}

inline vec2& vec2::set(Real d0, Real d1) {
  x = d0;
  y = d1;
  return *this;
}

inline vec2& vec2::set(const vec2& a) {
  x = a.x;
  y = a.y;
  return *this;
}

inline vec2& vec2::set(const Real* a) {
  x = a[0];
  y = a[1];
  return *this;
}

inline vec2 operator-(const vec2& a) {
  return vec2(-a.x,-a.y);
}

inline vec2& vec2::operator=(Real d) {
  return set(d);
}

inline vec2& vec2::operator=(const vec2& a) {
  return set(a);
}

inline vec2& vec2::operator=(const Real* a) {
  return set(a);
}

inline vec2::Real vec2::operator[](int index) const
{
	return (&x)[index];
}

inline vec2::Real& vec2::operator[](int index)
{
	return (&x)[index];
}

inline vec2::operator vec2::Real*()
{
	return array;
}

//-------------------------------------------------------------------

inline int vec2::operator==(const vec2& a) const {
  return ((x == a.x) && (y == a.y));
}

inline int vec2::operator!=(const vec2& a) const {
  return ((x != a.x) || (y != a.y));
}

inline int vec2::operator==(Real d) const {
  return ((x == d) && (y == d));
}

inline int vec2::operator!=(Real d) const {
  return ((x != d) || (y != d));
}

//-------------------------------------------------------------------

inline vec2& vec2::operator+=(Real d) {
	x += d;
	y += d;
	return *this;
}

inline vec2& vec2::operator-=(Real d) {
	x -= d;
	y -= d;
	return *this;
}

inline vec2& vec2::operator*=(Real d) {
	x *= d;
	y *= d;
	return *this;
}

inline vec2& vec2::operator/=(Real d) {
	x /= d;
	y /= d;
	return *this;
}

inline vec2& vec2::operator+=(const vec2& a) {
	x += a.x;
	y += a.y;
	return *this;
}

inline vec2& vec2::operator-=(const vec2& a) {
	x -= a.x;
	y -= a.y;
	return *this;
}

inline vec2& vec2::operator*=(const vec2& a) {
	x *= a.x;
	y *= a.y;
	return *this;
}

inline vec2& vec2::operator/=(const vec2& a) {
	x /= a.x;
	y /= a.y;
	return *this;
}

//-------------------------------------------------------------------

inline vec2 operator+(const vec2& a,const vec2& b) {
  return vec2(a.x + b.x, a.y + b.y);
}

inline vec2 operator-(const vec2& a,const vec2& b) {
  return vec2(a.x - b.x, a.y - b.y);
}

inline vec2 operator+(const vec2& a,vec2::Real b){
  return vec2(a.x + b, a.y + b);
}

inline vec2 operator-(const vec2& a,vec2::Real b){
  return vec2(a.x - b, a.y - b);
}

inline vec2 operator*(const vec2& a,vec2::Real b){
  return vec2(a.x * b, a.y * b);
}

inline vec2 operator+(vec2::Real a,const vec2& b){
  return vec2(a + b.x, a + b.y);
}

inline vec2 operator-(vec2::Real a,const vec2& b){
  return vec2(a - b.x, a - b.y);
}

inline vec2 operator*(vec2::Real a,const vec2& b){
  return vec2(a * b.x, a * b.y);
}

inline vec2::Real vec2::length() const {
  return sqrt(x*x + y*y);
}

// quadrance (rational trigonometry) is essentially a self dot product
inline vec2::Real vec2::quadrance() const {
  return x*x + y*y;
}

inline vec2& vec2::normalize() {
  register Real m = length();
  if (m != 0) {
	  *this *= (1/m);
  }
  return *this;
}

inline vec2::Real vec2::dot(const vec2& b) const {
  return x * b.x + y * b.y;
}

// this function makes no sense...
inline vec2 vec2::cross() const {
  return vec2(-y, x);
}



//-------------------------------------------------------------------
// Start class vec3

//template <Real>
class vec3
{
public:
	typedef double Real;

	inline vec3();
	inline vec3(Real d);
	inline vec3(Real d0,Real d1,Real d2);

	inline vec3(const vec3& a);
	inline vec3(const vec2& a);
	inline vec3(const Real*    a);

	inline Real  operator[](int index) const;
	inline Real& operator[](int index);
	inline operator Real*();

	inline vec3& set(Real d);
	inline vec3& set(Real d0, Real d1,Real d2);

	inline vec3& set(const vec3& a);
	inline vec3& set(const Real*    a);

	inline vec3& operator=(Real d);
	inline vec3& operator=(const vec3& a);
	inline vec3& operator=(const Real* a);

	inline int operator==(const vec3& a) const;
	inline int operator!=(const vec3& a) const;

	inline int operator==(Real d) const;
	inline int operator!=(Real d) const;

	inline vec3& operator+=(Real d);
	inline vec3& operator-=(Real d);
	inline vec3& operator*=(Real d);
	inline vec3& operator/=(Real d);

	inline vec3& operator+=(const vec3& a);
	inline vec3& operator-=(const vec3& a);
	inline vec3& operator*=(const vec3& a);
	inline vec3& operator/=(const vec3& a);

	inline vec3& normalize();
	inline Real length() const;
	inline Real quadrance() const;
	inline Real dot(const vec3& b) const;
	inline vec3 cross(const vec3& b) const;
	void          project(const vec3& b);

public:
	union {
		Real array[3]; /// all the vector entries (an additional alias added later)
		struct {
			Real x,y,z;
		};
		struct {
			Real s,t,u;
		};
	};
};

inline vec3 operator-(const vec3& a);

inline vec3 operator+(const vec3& a, const vec3& b);
inline vec3 operator-(const vec3& a, const vec3& b);

inline vec3 operator+(const vec3& a, vec3::Real b);
inline vec3 operator-(const vec3& a, vec3::Real b);
inline vec3 operator*(const vec3& a, vec3::Real b);

inline vec3 operator+(vec3::Real a, const vec3& b);
inline vec3 operator-(vec3::Real a, const vec3& b);
inline vec3 operator*(vec3::Real a, const vec3& b);

//-inline void normalize(vec3& a);
//-inline Real length(const vec3& a);
//-inline Real quadrance(const vec3& a);

//-inline Real dot(const vec3& a,const vec3& b);
//-inline vec3 cross(const vec3& a, const vec3& b);

inline vec3::vec3() {
	// keep this constructor primitive
	// so it can be used in agglomerates.
  //x = y = z = 0.0;
}
inline vec3::vec3(Real d) {
  x = y = z = d;
}

inline vec3::vec3(Real d0,Real d1,Real d2) {
  x = d0;
  y = d1;
  z = d2;
}

inline vec3::vec3(const vec3& a) {
  x = a.x;
  y = a.y;
  z = a.z;
}

inline vec3::vec3(const vec2& a) {
  x = a.x;
  y = a.y;
  z = 0;
}

inline vec3::vec3(const Real* a) {
  x = a[0];
  y = a[1];
  z = a[2];
}

//-------------------------------------------------------------------

inline vec3& vec3::set(Real d) {
  x = d;
  y = d;
  z = d;
  return *this;
}

inline vec3& vec3::set(Real d0, Real d1, Real d2) {
  x = d0;
  y = d1;
  z = d2;
  return *this;
}

inline vec3& vec3::set(const vec3& a) {
  x = a.x;
  y = a.y;
  z = a.z;
  return *this;
}

inline vec3& vec3::set(const Real* a) {
  x = a[0];
  y = a[1];
  z = a[2];
  return *this;
}

inline vec3 operator-(const vec3& a) {
  return vec3(-a.x,-a.y,-a.z);
}

inline vec3& vec3::operator=(Real d) {
  return set(d);
}

inline vec3& vec3::operator=(const vec3& a) {
  return set(a);
}

inline vec3& vec3::operator=(const Real* a) {
  return set(a);
}

inline vec3::Real vec3::operator[](int index) const
{
	return (&x)[index];
}

inline vec3::Real& vec3::operator[](int index)
{
	return (&x)[index];
}

inline vec3::operator vec3::Real*()
{
	return array;
}

//-------------------------------------------------------------------

inline int vec3::operator==(const vec3& a) const {
  return (
	  (x == a.x) &&
	  (y == a.y) &&
	  (z == a.z));
}

inline int vec3::operator!=(const vec3& a) const {
  return (
	  (x != a.x) ||
	  (y != a.y) ||
	  (z != a.z));
}

inline int vec3::operator==(Real d) const {
  return (
	  (x == d) &&
	  (y == d) &&
	  (z == d));
}

inline int vec3::operator!=(Real d) const {
  return (
	  (x != d) ||
	  (y != d) ||
	  (z != d));
}

//-------------------------------------------------------------------

inline vec3& vec3::operator+=(Real d) {
  x += d;
  y += d;
  z += d;
  return *this;
}

inline vec3& vec3::operator-=(Real d) {
  x -= d;
  y -= d;
  z -= d;
  return *this;
}

inline vec3& vec3::operator*=(Real d) {
  x *= d;
  y *= d;
  z *= d;
  return *this;
}

inline vec3& vec3::operator/=(Real d) {
  x /= d;
  y /= d;
  z /= d;
  return *this;
}

inline vec3& vec3::operator+=(const vec3& a) {
  x += a.x;
  y += a.y;
  z += a.z;
  return *this;
}

inline vec3& vec3::operator-=(const vec3& a) {
  x -= a.x;
  y -= a.y;
  z -= a.z;
  return *this;
}

inline vec3& vec3::operator*=(const vec3& a) {
  x *= a.x;
  y *= a.y;
  z *= a.z;
  return *this;
}

inline vec3& vec3::operator/=(const vec3& a) {
  x /= a.x;
  y /= a.y;
  z /= a.z;
  return *this;
}

//-------------------------------------------------------------------

inline vec3 operator+(const vec3& a,const vec3& b) {
  return vec3(a.x+b.x,  a.y+b.y,  a.z+b.z);
}

inline vec3 operator-(const vec3& a,const vec3& b) {
  return vec3(a.x-b.x,  a.y-b.y,  a.z-b.z);
}

inline vec3 operator+(const vec3& a,vec3::Real b){
  return vec3(a.x+b,  a.y+b,  a.z+b);
}

inline vec3 operator-(const vec3& a,vec3::Real b){
  return vec3(a.x-b,  a.y-b,  a.z-b);
}

inline vec3 operator*(const vec3& a,vec3::Real b){
	return vec3(a.x*b,  a.y*b,  a.z*b);
}

inline vec3 operator+(vec3::Real a,const vec3& b){
	return vec3(a+b.x,  a+b.y,  a+b.z);
}

inline vec3 operator-(vec3::Real a,const vec3& b){
	return vec3(a-b.x,  a-b.y,  a-b.z);
}

inline vec3 operator*(vec3::Real a,const vec3& b){
	return vec3(a*b.x,  a*b.y,  a*b.z);
}

inline vec3::Real vec3::length() const {
	return sqrt(x*x + y*y + z*z);
}

// quadrance (rational trigonometry) is essentially a self dot product
inline vec3::Real vec3::quadrance() const {
	return x*x + y*y + z*z;
}

inline vec3& vec3::normalize() {
	register Real m = length();
	if (m != 0) {
		*this *= (1/m);
	}
	return *this;
}

inline vec3::Real vec3::dot(const vec3& b) const {
	return (x*b.x + y*b.y + z*b.z);
}

inline vec3 vec3::cross(const vec3& b) const {
	return vec3(
		y * b.z - z * b.y,
		z * b.x - x * b.z,
		x * b.y - y * b.x);
}

#endif
