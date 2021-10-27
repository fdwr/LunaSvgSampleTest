// Include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
#pragma once

// Disable unknown pragma warnings (for when when compiling directly with VC)
#pragma warning(disable: 4068)

// Modify the following defines if you have to target a platform prior to the ones specified below.
// Refer to MSDN for the latest info on corresponding values for different platforms.
#ifndef WINVER				    // Allow use of features specific to Vista or later.
#define WINVER 0x0600		    // Change this to the appropriate value to target other versions of Windows.
#endif

#ifndef _WIN32_WINNT		    // Allow use of features specific to Vista or later.                   
#define _WIN32_WINNT 0x0600	    // Change this to the appropriate value to target other versions of Windows.
#endif						

#ifndef _WIN32_WINDOWS		    // Allow use of features specific to Windows 98 or later.
#define _WIN32_WINDOWS 0x0410   // Change this to the appropriate value to target Windows Me or later.
#endif

#ifndef _WIN32_IE			    // Allow use of features specific to IE 6.0 or later.
#define _WIN32_IE 0x0600	    // Change this to the appropriate value to target other versions of IE.
#endif

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers
#endif

#ifndef NOMINMAX
#define NOMINMAX
#endif

#ifndef _USE_MATH_DEFINES
#define _USE_MATH_DEFINES       // yes, we DO want PI defined
#endif

////////////////////////////////////////

// SAL annotations.
#include <specstrings.h>

// C headers:
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <utility>
#include <math.h>

// C++ headers:
#include <algorithm>
#include <cassert>
#include <cfloat>
#include <cmath>
#include <cstddef>
#include <ctime>
#include <exception>

#include <limits>
#include <memory>
#include <new>
#include <numeric>
#include <set>
#include <string>
#include <vector>
#include <map>

// Windows headers:

#include <windows.h>
#include <windowsx.h>
#include <winnls.h>
#include <unknwn.h>

#include <d2d1.h>
#include <d2d1helper.h>
#include <dwrite.h>
#include <wincodec.h>
#include <strsafe.h>
#include <comdef.h>
#include <usp10.h>

// GDI+ needs min/max
#undef min
#undef max
#define min(x,y) std::_cpp_min(x,y)
#define max(x,y) std::_cpp_max(x,y)

#include <gdiplus.h>

////////////////////////////////////////
// Common macro definitions:

#if !defined(NDEBUG) && !defined(DEBUG)
    #define DEBUG
#endif

#if (_MSC_VER >= 1400) // ensure that a virtual method overrides an actual base method.
    #define OVERRIDE override
#else
    #define OVERRIDE
#endif

#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
#endif

#ifndef UUIDOF
#define UUIDOF(iid) __uuidof(iid)
#endif

#define ARRAY_SIZE ARRAYSIZE

#ifndef RETURN_ON_FAIL // For any negative HRESULT code
#define RETURN_ON_FAIL(hrin, retval) { HRESULT hr = (hrin); if (FAILED(hr)) {return retval; } }
#endif

#ifndef RETURN_ON_ZERO // For null, zero, or false
#define RETURN_ON_ZERO(exp, retval) if (!(exp)) {return retval;}
#endif

// Use the double macro technique to stringize the actual value of s
#define STRINGIZE_(s) STRINGIZE2_(s)
#define STRINGIZE2_(s) #s

#define FAILURE_LOCATION "\r\nFunction: " __FUNCTION__ "\r\nLine: " STRINGIZE_(__LINE__)

#if (_MSC_VER >= 1200) // want std::min and std::max
#undef min
#undef max
#define min(x,y) _cpp_min(x,y)
#define max(x,y) _cpp_max(x,y)
#endif

////////////////////////////////////////
// Application specific headers/functions:

#define APPLICATION_TITLE "DPad - DirectWrite demo"

#include "Pointers.h"
#include "Exceptions.h"

extern void FailProgram(__in_z const char* message, int functionResult, __in_z_opt const char* format = NULL);
extern void DebugLog(const wchar_t* logMessage, ...);

inline bool IsSurrogate(UINT32 ch) throw()
{
    // 0xD800 <= ch <= 0xDFFF
    return (ch & 0xF800) == 0xD800;
}


inline bool IsHighSurrogate(UINT32 ch) throw()
{
    // 0xD800 <= ch <= 0xDBFF
    return (ch & 0xFC00) == 0xD800;
}


inline bool IsLowSurrogate(UINT32 ch) throw()
{
    // 0xDC00 <= ch <= 0xDFFF
    return (ch & 0xFC00) == 0xDC00;
}
