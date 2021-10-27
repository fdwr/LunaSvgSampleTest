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
#define _WIN32_WINDOWS 0x0601 // Change this to the appropriate value to target Windows Me or later.
#endif

#ifndef _WIN32_IE           // Allow use of features specific to IE 6.0 or later.
#define _WIN32_IE 0x0700    // Change this to the appropriate value to target other versions of IE.
#endif

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
#define NOMINMAX
#endif


#define DEBUG_ASSERT(expression)            (0)
#define INPUT_ASSERT_FAIL_MSG(expression)   (0)
#define INVARIANT_ASSERT(expression)        (0)
#define DEBUG_ASSERT_FAIL_MSG(expression)   (0)

//////////////////////////////

#include "common\Macros.h"

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
#include <map>
#include <vector>
#include <assert.h>
#include <intrin.h>
#include <functional>

// Work around conflict in VS2010 of IntSafe.h conflicting with stdint.h
#define _INTSAFE_H_INCLUDED_

//////////////////////////////
// Windows Header Files:

#include <Windows.h>
#include <WindowsX.h>
#include <CommCtrl.h>
#include <StrSafe.h>

#include <ShlObj.h>
#include <ShlWApi.h>
#include <Knownfolders.h>       // for font folder path
#include <CommDlg.h>
#include <ShellApi.h>

//////////////////////////////
// DirectX headers
#include <DWrite.h>
#include <D2d1.h>
#include <D2d1Helper.h>
#include <WinCodec.h>
#include <Usp10.h>

//////////////////////////////
// Common headers

#include "common\Common.h"
#include "common\AutoResource.h"
#include "common\AttributeList.h"
#include "common\Pointers.h"
#include "common\TextAnalysis.h"
#include "common\Unicode.h"
#include "common\Exceptions.h"
#include "common\CheckedPtr.h"
#include "common\ByteOrder.h"
#include "common\Parser.h"

//////////////////////////////
// Application specific - font related

#include "main\OpenTypeDefs.h"
#include "main\OpenTypeFaceData.h"
#include "main\FontTableTree.h"
#include "main\FontFaceFeatures.h"

#ifdef PRIVATE_BUILD
#include "Private\PrivateFunctions.h"
#endif

//////////////////////////////
// Application specific - UI related

#include "main\Application.h"
#include "main\Windowing.h"
#include "main\MainWindow.h"
#include "main\MessageBoxShaded.h"

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

#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
// If __ImageBase does not exist in your linker,
// try GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, &pObjectInModule, &handle) instead.
#endif
