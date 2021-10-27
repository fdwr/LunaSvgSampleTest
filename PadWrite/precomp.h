// Include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
#pragma once

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

#ifndef WIN32_LEAN_AND_MEAN     // Exclude rarely-used stuff from Windows headers
#define WIN32_LEAN_AND_MEAN
#endif

#ifndef NOMINMAX                // Use STL's templated min/max
#define NOMINMAX
#endif

#ifndef _USE_MATH_DEFINES       // we do want PI defined
#define _USE_MATH_DEFINES
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
#include <exception>

#include <limits>
#include <memory>
#include <new>
#include <numeric>
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
#include <comip.h>
#include <comdef.h>
#include <commdlg.h>

// Application shared:

#include "Common.h"

// Rendering:
#include "DrawingEffect.h"
#include "RenderTarget.h"
#include "InlineImage.h"

// Text editing/layout:
#include "EditableLayout.h"
#include "TextEditor.h"

// Main application
#include "resource.h"
#include "Application.h"
