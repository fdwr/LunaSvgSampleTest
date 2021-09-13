// pgfxoptions.h - Plain Options
//
// This file contains user options that customize the compile. It is included
// before any other headers so that definitions will be recognized.

#ifndef _WINDOWS
#define _WINDOWS
#endif
//#define _DOS

//#undef PlainIncludeMMX	// do not include MMX code in compile
#define PlainIncludeMMX 1	// include MMX code in compile

#define Display_pixelsDef 0
#define Display_widthDef 300
#define Display_heightDef 300
#define Display_bpplsDef 5

#define imageWidth 300
#define imageHeight 300
