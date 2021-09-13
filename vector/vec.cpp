/*
This file contains helper functions used for vector-related computatons
that are too big to put into an inline header.

Dwayne Robinson, 2007
*/

#define vec_cpp
#include "vec.h"

// Project another vector onto the current one
// the produced vector points exactly along the same line
// as the original, but is shortened, lengthened, or reversed.
//
// So if v points north and a points northwest,
// v.project(a) causes v to point up with less magnitude.
// If a points south, a will reverse 180 degrees.
//
void vec3::project(const vec3 &b)
{
	// the vector length squared or quadrance (rational trig)
	Real selfdot = (x*x) + (y*y) +	(z*z);

	if (selfdot == 0) {
		x = y = z = 0;
	} else {
		//this::operator*= dot(this, b) / lengthSqr;
		Real product = (Real)(
			( x*b.x	+ y*b.y + z*b.z)
			/ selfdot
			);
		x *= product;
		y *= product;
		z *= product;
	}
	//return (icVector3*)this;??
}


/*
Given three points on a triangle and a point within,
it returns the relative weights of corner.

-If inside the triangle, all weights range from 0 to 1, and the sum of all weights = 1;
-If b1, b2, and b3 are all > 0, (x0,y0) is strictly inside the triangle;
-If bi = 0 and the other two coordinates are positive, (x0,y0) lies on the edge opposite (xi,yi);
-If bi and bj = 0, (x0,y0) lies on (xk,yk); if bi < 0, (x0,y0) lies outside the edge opposite (xi,yi);
-If all three coordinates are negative, something else is wrong.
-This method does not depend on the cyclic order of the vertices. 
*/
void vec2::interpolateTriangle(
	vec2& p,	// point to interpolate
	vec2& a,	// triangle corner
	vec2& b,	// triangle corner
	vec2& c,	// triangle corner
	vec3& w		// weights back out
)
{
	// from: http://steve.hollasch.net/cgindex/math/barycentric.html
	// (David Watson)
	Real b0 =  (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
	w.array[0] = ((b.x - p.x) * (c.y - p.y) - (c.x - p.x) * (b.y - p.y)) / b0;
	w.array[1] = ((c.x - p.x) * (a.y - p.y) - (a.x - p.x) * (c.y - p.y)) / b0;
	w.array[2] = ((a.x - p.x) * (b.y - p.y) - (b.x - p.x) * (a.y - p.y)) / b0;
}
