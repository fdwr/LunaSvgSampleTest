// pgfxoptions.h - Plain Graphics Options
//
// This file contains user options that customize the compile. It is included
// before any other headers so that definitions will be recognized.

#define _WINDOWS
//#define _OLD

//#undef PlainUseMMX	// do not include MMX code in compile
#define PlainUseMMX 1	// include MMX code in compile

#undef PlainUseCursor

#define Display.PtrDef 0
#define Display.WidthDef 320
#define Display.PtrDef 240
#define Display.WrapDef 320*4
