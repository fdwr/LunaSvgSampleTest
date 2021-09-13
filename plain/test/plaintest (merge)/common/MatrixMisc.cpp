#include "icVector.h"
#include "icMatrix.h"

// Take the matrix and result, and return the solution.
// ! This function modifies the parameters !
//
// Notes: entry[0][x] is the first row
//        entry[1][x] is the second row
//        entry[x][0] is the first column
//        entry[x][1] is the second column
void matrix_ge(icMatrix3x3* matrix, icVector3* vector)
{
	double x,y,z, ratio;

	// subtract first row from second
	ratio = matrix->entry[1][0] / matrix->entry[0][0];
	matrix->entry[1][0] -= matrix->entry[0][0] * ratio;
	matrix->entry[1][1] -= matrix->entry[0][1] * ratio;
	matrix->entry[1][2] -= matrix->entry[0][2] * ratio;
	vector->entry[1]    -= vector->entry[0]    * ratio;

	// subtract first row from third
	ratio = matrix->entry[2][0] / matrix->entry[0][0];
	matrix->entry[2][0] -= matrix->entry[0][0] * ratio;
	matrix->entry[2][1] -= matrix->entry[0][1] * ratio;
	matrix->entry[2][2] -= matrix->entry[0][2] * ratio;
	vector->entry[2]    -= vector->entry[0]    * ratio;

	// subtract part of second row from third
	ratio = matrix->entry[2][1] / matrix->entry[1][1];
	matrix->entry[2][1] -= matrix->entry[1][1] * ratio;
	matrix->entry[2][2] -= matrix->entry[1][2] * ratio;
	vector->entry[2]    -= vector->entry[1]    * ratio;

	// back substitution
	z =  vector->entry[2]                                                      / matrix->entry[2][2];
	y = (vector->entry[1]                           - matrix->entry[1][2] * z) / matrix->entry[1][1];
	x = (vector->entry[0] - matrix->entry[0][1] * y - matrix->entry[0][2] * z) / matrix->entry[0][0];
	
	vector->set(x,y,z);
}
