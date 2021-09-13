// pgfxoptions.h - Plain Graphics Options
//
// This file contains user options that customize the compile. It is included
// before any other headers so that definitions will be recognized.

//#undef PlainUseMMX	// do not include MMX code in compile
//version=PlainUseMMX; // include MMX code in compile
//version=PlainUseCursor;
//version=PgfxOptionsIncluded;

enum {
	PlainUseMMX=1, /// include MMX code in compile
	PlainUseCursor=1, /// use cursor code
}
