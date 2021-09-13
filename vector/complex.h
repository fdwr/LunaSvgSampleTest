// From Eric Mortenson at Oregon State University.
// Unknown if he derived it from another source.

#pragma once
#ifndef __complex_h
#define __complex_h

#define _USE_MATH_DEFINES
#include <math.h>
#undef complex

//#include "types.h"
#ifdef SINGLE_PRECISION
typedef float  Real;
#else
typedef double Real;
#endif

#ifdef COMPLEX_USE_STD_C
  #include <complex>
  typedef complex<Real> Complex;
#else
  class complex;
  typedef complex Complex;
#endif


////////////////////////////////////////////////////////////////////////////////
class complex {
public:
	union {
		struct {Real r, i;};
		struct {Real x, y;};
		struct {Real m, p;};
	};

	inline complex(Real real=0., Real imag=0.) : r(real), i(imag) { }

	Real    real() const { return r; }
	Real    imag() const { return i; }

	Real     abs() const { return  sqrt(r * r + i * i); }    // Magnitude.
	Real    norm() const { return       r * r + i * i;  }    // Magnitude squared.
	Real     arg() const { return atan2(i , r);         }    // Phase.

	// Complex conjugate.
	complex     conj   ()          const { return complex(r, -i); }
	complex&    conjEqu()                { i = -i;  return *this; }

	// Unary operators.
	complex  operator+ ()          const { return *this; }
	complex  operator- ()          const { return complex(-r, -i); }

	// Addition operators.
	complex  operator+ (Real    a) const { return complex(r + a, i); }
	inline complex& operator+=(Real    a)       { r += a; return *this; }

	complex  operator+ (complex z) const { return complex(r + z.r, i + z.i); }
	inline complex& operator+=(complex z)       { r += z.r; i+= z.i;  return *this; }

	// Subtraction operators.
	complex  operator- (Real    a) const { return complex(r - a, i); }
	inline complex& operator-=(Real    a)       { r -= a; return *this; }

	complex  operator- (complex z) const { return complex(r - z.r, i - z.i); }
	inline complex& operator-=(complex z)       { r -= z.r; i-= z.i;  return *this; }

	// Multiplication operators.
	complex  operator* (Real    a) const { return complex(r * a, i * a); }
	complex& operator*=(Real    a)       { r *= a; i *= a; return *this; }

	complex  operator* (complex z) const { return complex(r * z.r - i * z.i,
														r * z.i + i * z.r); }
	inline complex& operator*=(complex z){ Real tmp = r * z.r - i * z.i;
											i = r * z.i + i * z.r; r = tmp;
											return *this; }

	// Division operators.
	complex  operator/ (Real    a) const { return complex(r / a, i / a); }
	inline complex& operator/=(Real    a)       { r /= a; i /= a; return *this; }
	                                
	// Comparison operators.
	bool     operator==(Real    a) const { return r == a   && i == 0. ; }
	bool     operator==(complex z) const { return r == z.r && i == z.i; }

	bool     operator!=(Real    a) const { return r != a   || i != 0. ; }
	bool     operator!=(complex z) const { return r != z.r || i != z.i; }
};
/******************************************************************************/

/*----------------------------------------------------------------------------*/
inline complex euler(Real ang) { return complex(cos(ang), sin(ang)); }
/*----------------------------------------------------------------------------*/
inline complex polar(Real rad, Real ang) {
  return complex(rad * cos(ang), rad * sin(ang));
}
/*----------------------------------------------------------------------------*/
inline Real       abs(complex z) { return  sqrt(z.r * z.r + z.i * z.i);}
inline Real      norm(complex z) { return       z.r * z.r + z.i * z.i; }
inline Real       arg(complex z) { return atan2(z.i , z.r);            }
inline Real quadrance(complex z) { return       z.r * z.r + z.i * z.i; }

inline complex conj(complex z) { return complex(z.r, -z.i); }
/*----------------------------------------------------------------------------*/
inline complex operator+(Real a, const complex &z) {
  return complex(a + z.r, z.i);
}
/*----------------------------------------------------------------------------*/
inline complex operator-(Real a, const complex &z) {
  return complex(a - z.r, -z.i);
}
/*----------------------------------------------------------------------------*/
inline complex operator*(Real a, const complex &z) {
  return complex(a * z.r, a * z.i);
}
/*----------------------------------------------------------------------------*/
inline bool operator==(Real a, const complex &z) {
  return a == z.r && z.i == 0.;
}
/*----------------------------------------------------------------------------*/
inline bool operator!=(Real a, const complex &z) {
  return a != z.r || z.i != 0.;
}
/*----------------------------------------------------------------------------*/

#endif

