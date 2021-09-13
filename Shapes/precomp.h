// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#include "targetver.h"

////////////////////////////////////////

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
#endif

#define NOMINMAX

#ifndef GDIPVER
// Want the latest GDI+ 1.1 version.
#define GDIPVER 0x0110
#endif

#define _USE_MATH_DEFINES

////////////////////////////////////////

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
// Windows Header Files:
#include <windows.h>

// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <vector>
#include <stdint.h>
#include <algorithm>
#include <numeric>

////////////////////////////////////////

#include <dwrite.h>
#include <d2d1.h>
#include <wincodec.h>

#define min std::min
#define max std::max
#include <gdiplus.h>
#undef min
#undef max

////////////////////////////////////////

#include "Common.AutoResource.h"
#include "Common.CommonObjectModel.h"

#include "DrawingCanvas.h"
#include "ShapeList.h"
#include "ShapeUtility.h"
