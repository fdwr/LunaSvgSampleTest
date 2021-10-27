#pragma once

// Disable unknown pragma warnings (for when when compiling directly with VC)
// and not under build.exe.
#pragma warning(disable: 4068)

#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif

#include "sdkddkver.h"

// Modify the following defines if you have to target a platform prior to the ones specified below.
// Refer to MSDN for the latest info on corresponding values for different platforms.
#ifndef WINVER              // Allow use of features specific to Windows 7 or later.
#define WINVER 0x0701       // Change this to the appropriate value to target other versions of Windows.
#endif

#ifndef _WIN32_WINNT        // Allow use of features specific to Windows 7 or later.                   
#define _WIN32_WINNT 0x0601 // Change this to the appropriate value to target other versions of Windows.
#endif

#ifndef _WIN32_WINDOWS      // Allow use of features specific to Windows 98 or later.
#define _WIN32_WINDOWS 0x0710 // Change this to the appropriate value to target Windows Me or later.
#endif

#ifndef _WIN32_IE           // Allow use of features specific to IE 6.0 or later.
#define _WIN32_IE 0x0700    // Change this to the appropriate value to target other versions of IE.
#endif

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
#define NOMINMAX
#endif


#define INPUT_ASSERT_FAIL_MSG(expression)   {if (!(expression)) __debugbreak();}

#define INVARIANT_ASSERT(expression)        {if (!(expression)) __debugbreak();}

#ifndef NDEBUG
#define DEBUG_ASSERT(expression)            {if (!(expression)) __debugbreak();}
#else
#define DEBUG_ASSERT(expression)            (0)
#endif

#ifndef NDEBUG
#define DEBUG_ASSERT_FAIL_MSG(expression)   {if (!(expression)) __debugbreak();}
#else
#define DEBUG_ASSERT_FAIL_MSG(expression)   (0)
#endif

#ifndef BUILD_OPTIMIZATION_STRING
#if defined(DEBUG)
#define BUILD_OPTIMIZATION_STRING L"Debug"
#else
#define BUILD_OPTIMIZATION_STRING L"Release"
#endif
#endif

#ifndef BUILD_ARCHITECTURE_STRING 
#if defined(_M_IX86)
#define BUILD_ARCHITECTURE_STRING L"x86 32-bit"
#elif defined(_M_X64)
#define BUILD_ARCHITECTURE_STRING L"64-bit"
#else
#define BUILD_ARCHITECTURE_STRING L"Unknown"
#endif
#endif

#ifndef BUILD_TITLE_STRING
#define BUILD_TITLE_STRING L"FontCollectionViewer"
#endif

#ifndef APPLICATION_TITLE
#define APPLICATION_TITLE L"Font Collection Viewer"
#endif


//////////////////////////////

#include "Common/Macros.h"

//////////////////////////////
// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <xutility>
#include <math.h>
#include <new>
#include <algorithm>
#include <numeric>
#include <stdint.h>
#include <string>
#include <vector>
#include <assert.h>
#include <intrin.h>
#include <functional>
#include <map>
#include <set>

// Work around conflict in VS2010 of IntSafe.h conflicting with stdint.h
#define _INTSAFE_H_INCLUDED_

//////////////////////////////
// Windows Header Files:

#include <Windows.h>
#include <WindowsX.h>
#include <StrSafe.h>
#include <Shlwapi.h>
#include <CommCtrl.h>
#include <CommDlg.h>
#include <WinHttp.h>
#include <WinIoCtl.h>
#include <ShellApi.h>

//////////////////////////////
// DirectX, Uniscribe headers

#include <DWrite.h>
#include <DWrite_1.h>
#include <DWrite_2.h>
#include <DWrite_3.h>
//#include <DWriteP.h>
#include <D2d1.h>
#include <D2d1Helper.h>
#include <WinCodec.h>
#include <Usp10.h>

//////////////////////////////
// Common headers

#include "Common/Common.h"
#include "Common/AutoResource.h"
#include "Common/Pointers.h"
#include "Common/CheckedPtr.h"
#include "Common/ByteOrder.h"
#include "Common/Parser.h"
#include "Common/Exceptions.h"
#include "Common/FileHelpers.h"
#include "Common/Unicode.h"
#include "Common/Windowing.h"

//////////////////////////////
// Common DWrite/Font headers

#include "Font/DWritEx.h"
#include "Font/OpenTypeDefs.h"
//-#include "Font/FontFaceHelpers.h"
#include "Font/OpenTypeFaceData.h"

//////////////////////////////
// Specific Font headers

//-#include "WindowsFontCollection.h"
//-#include "GoogleFontCollection.h"

//////////////////////////////

#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
// If __ImageBase does not exist in your linker,
// try GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, &pObjectInModule, &handle) instead.
#endif
