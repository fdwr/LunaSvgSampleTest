// include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
#pragma once

// Disable unknown pragma warnings (for when when compiling directly with VC)
// and not under build.exe.
#pragma warning(disable: 4068)

// Modify the following defines if you have to target a platform prior to the ones specified below.
// Refer to MSDN for the latest info on corresponding values for different platforms.
#ifndef WINVER              // Allow use of features specific to Windows XP or later.
#define WINVER 0x0601       // Change this to the appropriate value to target other versions of Windows.
#endif

#ifndef _WIN32_WINNT        // Allow use of features specific to Windows XP or later.                   
#define _WIN32_WINNT 0x0601 // Change this to the appropriate value to target other versions of Windows.
#endif

#ifndef _WIN32_WINDOWS      // Allow use of features specific to Windows 98 or later.
#define _WIN32_WINDOWS 0x0410 // Change this to the appropriate value to target Windows Me or later.
#endif

#ifndef _WIN32_IE           // Allow use of features specific to IE 6.0 or later.
#define _WIN32_IE 0x0600    // Change this to the appropriate value to target other versions of IE.
#endif

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
#define NOMINMAX
#endif

#ifndef GDIPVER
// Want the latest GDI+ 1.1 version.
#define GDIPVER 0x0110
#endif

// The C++0x keyword is supported in Visual Studio 2010
#if _MSC_VER < 1600
#ifndef nullptr
#define nullptr 0
#endif
#endif

// The static assertion keyword is supported in Visual Studio 2010
#if _MSC_VER < 1600
#ifndef static_assert
#define static_assert(exp,msg) COMPILE_ASSERT((exp))
#endif
#endif

#include "std.h"

// Windows Header Files:
#include <windowsx.h>

#include <shlobj.h>
#include <Knownfolders.h>       // for font folder path
#include <CommDlg.h>

// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <xutility>
#include <math.h>
#include <new>
#include "strsafe.h"

// DirectX headers
#include <DWrite1.h>
#include <d2d1.h>
#include <d2d1helper.h>
#include <wincodec.h>

#include <usp10.h>

// Internal headers

#include "DllInit.h"

#include "ComHelpers.h"
#include "Unicode.h"
#include "UcdProperties.h"
#include "SafeInt.hpp"

// Application specific.

#include "AutoResource.h"
#include "AttributeList.h"

// since RefCount is actually the inherited object
template<typename T> class RefCountPtr : public IntrusivePtr<T>
{
public:
    inline void Set(T* p)
    {
        IntrusivePtr<T>::Attach(p);
    }
};

void DebugLog(const wchar_t* logMessage, ...);

#define min std::min
#define max std::max
#include <gdiplus/gdiplus.h>
#undef min
#undef max

//////////////////////////////
// The actual layout code

#include "GlyphLayoutSource.h"
#include "LayoutEditor.h"

//////////////////////////////
// UI related

#include "LayoutCanvas.h"
#include "LayoutViewWindow.h"
#include "LayoutInputWindow.h"
#include "LayoutOutputWindow.h"
#include "SystemFontsWindow.h"
#include "MainWindow.h"

//////////////////////////////
// Factory related

#include "../../ApiImpl/ApiImpl.h"

// Remove if switched to DLL.
#define DWriteCreateFactory CreateFactory

//////////////////////////////
// ...

// Need this for common controls.
// Otherwise the app either looks ugly,
// or it doesn't show anything at all
// (except an empty window).
#ifdef _UNICODE
    #if defined _M_IX86
        #pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='x86' publicKeyToken='6595b64144ccf1df' language='*'\"")

    #elif defined _M_IA64
        #pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='ia64' publicKeyToken='6595b64144ccf1df' language='*'\"")

    #elif defined _M_X64
        #pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='amd64' publicKeyToken='6595b64144ccf1df' language='*'\"")

    #else
        #pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

    #endif
#endif
