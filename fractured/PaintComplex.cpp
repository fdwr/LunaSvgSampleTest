/**
File: PaintComplex.cpp
Since: 2005-11-30
Remark: Complex fractals, Mandelbrot, Julia.... and related
*/

#include <stdlib.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include <limits.h>
#include <float.h>
#include <stddef.h>

#include "PaintComplex.h"

enum { // MUST be contiguous, not sparse
	VarSpecie,
	VarBailOut,
	VarCre,
	VarCim,
	VarIterationsMax,
	VarTotal,
};

const static FracturedPainter::VarInfo varInfo[] = {
	{	T("complex_fractal"), T("Complex fractal"),
		T("These fractals apply simple equations to complex ")
		T("multiple iterations to create very complex, self similar, organic spirals. ")
		T("The complex space real is mapped to x and imaginary to y."),
		-1, FracturedPainter::VarInfo::TypeLabel,
		0, 0,0
	},
	{	T("specie"), T("Specie"),
		T("Type of complex fractal."),
		VarSpecie, FracturedPainter::VarInfo::TypeInt,
		PaintComplex::SpecieMandelbrot2, 0,PaintComplex::SpecieTotal-1,
	},
	{	T("bail_out"), T("Bail out"),
		T("For divergent fractals (like Mandelbrot) this prevents ")
		T("unnecessary calculation by stopping once the iteration reaches a certain ")
		T("distance from the origin."),
		VarBailOut, FracturedPainter::VarInfo::TypeFloat,
		4.f, 0.f,FLT_MAX,
	},
	{	T("iterations_max"), T("Iterations max"),
		T("Maximum number of iterations before stopping. ")
		T("Higher iterations show more detail, especially along the edges when ")
		T("zoomed in. However, more iterations means more time."),
		VarIterationsMax, FracturedPainter::VarInfo::TypeInt,
		20, 0,1000,
	},
	{	T("constant_real"), T("Constant real"),
		T("The real constant for Julia fractals (z^e + c.real). ")
		T("Changing this moves up and down in complex space (y axis). ")
		T("It is ignored by Mandelbrot fractals which instead use the starting point ")
		T("as the additive constant."),
		VarCre, FracturedPainter::VarInfo::TypeFloat,
		0.f, 0.f, FLT_MAX
	},
	{	T("constant_imaginary"), T("Constant imaginary"),
		T("The imaginary constant for Julia fractals (z^e + c.imag). ")
		T("Changing this moves left and right in complex space (x axis). ")
		T("It is ignored by Mandelbrot fractals which instead use the starting point ")
		T("as the additive constant."),
		VarCim, FracturedPainter::VarInfo::TypeFloat,
		0.f, 0.f, FLT_MAX
	},
	{	nullptr, nullptr,nullptr,	 0, 0,	 0, 0,0
	}
};

const static FracturedPainter::VarInfo varInfoMandelbrot[] = {
	{	nullptr, nullptr, nullptr,
		VarCre, FracturedPainter::VarInfo::TypeFloat | FracturedPainter::VarInfo::TypeDisabled,
		0.f, 0.f, FLT_MAX
	},
	{	nullptr, nullptr, nullptr,
		VarCim, FracturedPainter::VarInfo::TypeFloat | FracturedPainter::VarInfo::TypeDisabled,
		0.f, 0.f, FLT_MAX
	},
	{	nullptr, nullptr,nullptr,	 0, 0,	 0, 0,0
	}
};

static const FracturedPainter::CanvasInfo canvasInfo[] = 
{
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::f32 ),
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u8 ),
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::u16 ),
	FracturedPainter::CanvasInfo( FracturedCanvas::Formats::f32x2 ),
	FracturedPainter::CanvasInfo()
};

////////////////////////////////////////////////////////////////////////////////

#pragma warning(disable:4244) // conversion from 'double' to 'float', possible loss of data

PaintComplex::PaintComplex()
{
	specie = SpecieMandelbrot2;
	init();
}


PaintComplex::PaintComplex(int specie_)
{
	specie = specie_;
	init();
}


int PaintComplex::init()
{
	// do species specific initialization
	//switch (species) {
	//case SpecieMandelbrot2:
	//case SpecieJulia2:
	//case ...
	iterationsMax = 20;
	bailOut = 4;
	cre = 0.388158;
	cim = -0.125;
	return 0;
}


int PaintComplex::draw (FracturedCanvas* fc, FracturedCanvas* fcin, int (*progress)(void* self, int current, int total))
{
	double
		dx = fc->inverse.scalex,
		dy = fc->inverse.scaley;
	double x,y;
	int iterations;	// number of iterations so far per pixel
	double bailOutSqrd = bailOut * bailOut; // faster, to avoid sqrt in bailout test

	int
		height = fc->height,
		width  = fc->width;
	int pixelFormat = fc->format & FracturedCanvas::Formats::Mask;
	FracturedPixelPtr p; // pointer for row, and for column

	IterationValues* rowValues = smalloc(IterationValues, fc->width); // list of final values for current row

	// for each row, accumulate values then convert
	// splitting into two phases does slow it down some
	// but the code is MUCH simpler and more readable.
	p.p = fc->pixels;
	y = fc->inverse.transy;
	for (int i=0; i < height; i++, y += dy) {
		//p.pv = prow.pv; // reset for next row

		// accumulate values into list for entire current row
		x = fc->inverse.transx;
		for (int j=0; j < width; j++, x += dx) {
			double zre,zim;	// z real & imaginary
			iterations=0;

			// do specific formula
			switch (specie) {
			case SpecieMandelbrot2:
			default:
				zre = x;
				zim = y;
				for (; iterations < iterationsMax; iterations++) {
					// z = c = [x,y]
					// z = z^2 + c
					double zrs  = zre * zre;
					double zis  = zim * zim;
					double zri = 2.0 * zre * zim;
					zre = zrs - zis + x;
					zim = zri + y;
					if (zrs + zis > bailOutSqrd) break;
				}
				break;

			case SpecieJulia2:
				zre = x;
				zim = y;
				for (; iterations < iterationsMax; iterations++) {
					// z = [x,y], c = [creal, cimag]
					// z = z^2 + c
					double zrs  = zre * zre;
					double zis  = zim * zim;
					double zri = 2.0 * zre * zim;
					zre = zrs - zis + cre;
					zim = zri + cim;
					if (zrs + zis > bailOutSqrd) break;
				}
				break;

			case SpecieMandelbrot3:
				zre = x;
				zim = y;
				for (; iterations < iterationsMax; iterations++) {
					// z = c = [x,y]
					// z = z^3 + c
					double zre1 = zre, zim1 = zim;
					double zrs  = zre * zre;
					double zis  = zim * zim;
					double zri = 2.0 * zre * zim;
					zre = zrs - zis;
					zim = zri;

					zrs = zre * zre1;
					zis = zim * zim1;
					zri = zre * zim1 + zre1 * zim;

					zre = zrs - zis + x;
					zim = zri + y;

					if (zrs + zis > bailOutSqrd) break;
				}
				break;

			case SpecieJulia3:
				zre = x;
				zim = y;
				for (; iterations < iterationsMax; iterations++) {
					// z = [x,y], c = [creal, cimag]
					// z = z^3 + c
					double zre1 = zre, zim1 = zim;
					double zrs  = zre * zre;
					double zis  = zim * zim;
					double zri = 2.0 * zre * zim;
					zre = zrs - zis;
					zim = zri;

					zrs = zre * zre1;
					zis = zim * zim1;
					zri = zre * zim1 + zre1 * zim;

					zre = zrs - zis + cre;
					zim = zri + cim;

					if (zrs + zis > bailOutSqrd) break;
				}
				break;

			case SpecieMandelbrot4:
				zre = x;
				zim = y;
				for (; iterations < iterationsMax; iterations++) {
					// z = c = [x,y]
					// z = z^4 + c
					double zrs  = zre * zre;
					double zis  = zim * zim;
					double zri = 2.0 * zre * zim;
					zre = zrs - zis;
					zim = zri;
					zrs  = zre * zre;
					zis  = zim * zim;
					zri = 2.0 * zre * zim;
					zre = zrs - zis + x;
					zim = zri + y;
					if (zrs + zis > bailOutSqrd) break;
				}
				break;

			case SpecieJulia4:
				zre = x;
				zim = y;
				for (; iterations < iterationsMax; iterations++) {
					// z = [x,y], c = [creal, cimag]
					// z = z^4 + c
					double zrs  = zre * zre;
					double zis  = zim * zim;
					double zri = 2.0 * zre * zim;
					zre = zrs - zis;
					zim = zri;
					zrs  = zre * zre;
					zis  = zim * zim;
					zri = 2.0 * zre * zim;
					zre = zrs - zis + cre;
					zim = zri + cim;
					if (zrs + zis > bailOutSqrd) break;
				}
				break;

			}

			rowValues[j].zre = zre;
			rowValues[j].zim = zim;
			rowValues[j].iterations = iterations;
		}

		// convert row of calculated values into pixel type
		//prow.pu8 += fc->wrap;
		//v.y += dy;
	
		switch (pixelFormat) {
		case FracturedCanvas::Formats::u8:
			for (int j=0; j < width; j++) {
				#if 0 // integral
				// While this is much faster, the colors are highly dependent on the
				// number of iterations, potentially shifting the whole palette off.
				p.u8[j] = rowValues[j].iterations;
				#else // smooth
				// This correction will show the right colors regardless of the count.
				// Higher counts simply increase the detail.
				double zre = rowValues[j].zre;
				double zim = rowValues[j].zim;
				double magnitude = sqrt (zre*zre + zim*zim);
				//if (rowValues[j].iterations == iterationsMax)
				//double mu = rowValues[j].iterations - (log(log(magnitude)))/ log (2.0);
				double maglog = log(magnitude);
				if (maglog <= 1 || !_finite(maglog)) {
					p.u8[j] = rowValues[j].iterations; // log(log(e)) = 0
				} else {
					p.u8[j] = rowValues[j].iterations + 1 - (log(maglog) / M_LN2);
				};
				#endif
			}
			break;

		case FracturedCanvas::Formats::u16:
			for (int j=0; j < width; j++) {
				#if 0 // integral
				// While this is much faster, the colors are highly dependent on the
				// number of iterations, potentially shifting the whole palette off.
				p.u16[j] = rowValues[j].iterations;
				#else // smooth
				// This correction will show the right colors regardless of the count.
				// Higher counts simply increase the detail.
				double zre = rowValues[j].zre;
				double zim = rowValues[j].zim;
				double magnitude = sqrt (zre*zre + zim*zim);
				//if (rowValues[j].iterations == iterationsMax)
				//double mu = rowValues[j].iterations - (log(log(magnitude)))/ log (2.0);
				double maglog = log(magnitude);
				if (maglog <= 1 || !_finite(maglog)) {
					p.u16[j] = rowValues[j].iterations; // log(log(e)) = 0
				} else {
					p.u16[j] = rowValues[j].iterations + 1 - (log(maglog) / M_LN2);
				};
				#endif
			}
			break;

		case FracturedCanvas::Formats::f32:
			for (int j=0; j < width; j++) {
				double zre = rowValues[j].zre;
				double zim = rowValues[j].zim;
				double magnitude = sqrt (zre*zre + zim*zim);
				double maglog = log(magnitude);
				double mu;
				// log( x<0 ) is bad, and really large numbers multiplied are bad too :)
				if (maglog <= 1 || !_finite(maglog)) {
					mu = rowValues[j].iterations; // log(log(e)) = 0
				} else {
					mu = rowValues[j].iterations + 1 - (log(maglog) / M_LN2);
				}
				p.f32[j] = mu;
				//mu = N + 1 - log (log  |Z(N)|) / log 2
				//http://linas.org/art-gallery/escape/smooth.html
				//http://linas.org/art-gallery/escape/escape.html
			}
			break;

		case FracturedCanvas::Formats::f32x2:
			for (int j=0; j < width; j++) {
				p.f32x2[j].x = rowValues[j].zre;
				p.f32x2[j].y = rowValues[j].zim;
			}
			break;
		}

		p.u8 += fc->wrap;

		if (!progress(this, i, height)) break;
	}

	free(rowValues);

	return 0;
}


int PaintComplex::next(FracturedCanvas* fcin)
{
	return 0;
}


int PaintComplex::load(Var* vars)
{
	while (vars->id >= 0) {
		switch (vars->id) {
		case VarSpecie:
			specie = vars->value.i;
			//if (specie > SpecieTotal) specie = SpecieMandelbrot2;
			break;
		case VarBailOut:
			bailOut = vars->value.f;
			if (bailOut <= 0) bailOut = 4;
			break;
		case VarCre:
			cre = vars->value.f;
			break;
		case VarCim:
			cim = vars->value.f;
			break;
		case VarIterationsMax:
			iterationsMax = vars->value.i;
			if (iterationsMax > 10000) iterationsMax = 10000;
			elif (iterationsMax <= 0) iterationsMax = 1;
			break;
		}
		vars++;
	}
	return 0;
}


int PaintComplex::store(Var** pvars)
{
	Var* vars = new FracturedPainter::Var[VarTotal];
	for (int i=0; i < VarTotal; i++) {
		vars[i].id = i;
	}
	vars[VarSpecie].value.i = specie;
	vars[VarBailOut].value.f = bailOut;
	vars[VarCre].value.f = cre;
	vars[VarCim].value.f = cim;
	vars[VarIterationsMax].value.i = iterationsMax;
	*pvars = vars;
	return 0;
}


const void* PaintComplex::supports (int element)
{
	// support any instance specific elements
	switch (element) {
	case SupportsVarsSpecie:
		{
			switch (specie) {
			case SpecieMandelbrot2:
			case SpecieMandelbrot3:
			case SpecieMandelbrot4:
				return varInfoMandelbrot;
			case SpecieJulia2:
			case SpecieJulia3:
			case SpecieJulia4:
				//return varInfoJulia;
			default:
				break;
			}
		}
		break;
	}

	// otherwise support a static element (for which no instance need exist)
	return supportsStatic(element);
}

const void* PaintComplex::supportsStatic(int element)
{
	switch (element) {
	case SupportsCanvas:
		return canvasInfo;

	case SupportsLayerFlags:
		{
			const static int flags = FracturedLayer::FlagSlow;
			return &flags;
		}

	case SupportsVars:
		return varInfo;

	}
	return nullptr;
}


////////////////////////////////////////////////////////////////////////////////

