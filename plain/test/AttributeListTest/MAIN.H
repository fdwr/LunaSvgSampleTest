/*
File: main.h
Project: test_atrblist
Date: 2005-06-25

Main header file.
*/

#if defined(_WINDOWS) && !defined(_WINDOWS_)
#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#include <windows.h>
#endif

#include "pgfx.h"
#include "pgfxlayr.h"
#include "guidefs.h"

//#include <math.h>

//#include <stdio.h>
//#include <stdarg.h>
//#include <stdlib.h>

//#include "resource.h"

#define malloc(size) GlobalAlloc(GMEM_FIXED, size)
#define freemem(ptr) GlobalFree(ptr)

//extern "C" int strmatch(const char *string, const char *matches);
//extern "C" const char *strfileext(const char *filename);
