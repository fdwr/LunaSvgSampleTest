/**
File: PaintConvert.h
Since: 2005-11-30
Remark: Complex fractals, Mandelbrot, Julia.... and related
*/

#include "fractured.h"

class PaintComplex : public FracturedPainter {
public:
	FracturedPainter_StdMthds; // define standard methods here (in fractured.h)

	////////////////////
	PaintComplex();
	PaintComplex(int specie_);

	////////////////////
	double cre, cim;	// constant real & imaginary, only applicable to Julia like fractals
	double bailOut;		// stop if magnitude of Z is outside escape region
	int iterationsMax;	// stop if iterations greater

	////////////////////
	enum Species {
		SpecieMandelbrot2,
		SpecieMandelbrot3,
		SpecieMandelbrot4,
		SpecieJulia2,
		SpecieJulia3,
		SpecieJulia4,
		SpecieTotal,
	};

private:
	typedef struct IterationValues { // holds results of an iteration
		double zre;
		double zim;
		int iterations;
	} IterationValues;
};
