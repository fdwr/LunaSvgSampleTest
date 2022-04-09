// header.h : include file for standard system include files,
// or project specific include files

#pragma once

// Including SDKDDKVer.h defines the highest available Windows platform.
// If you wish to build your application for a previous Windows platform, include WinSDKVer.h and
// set the _WIN32_WINNT macro to the platform you wish to support before including SDKDDKVer.h.
#include <SDKDDKVer.h>

//#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
//#define NOMINMAX
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif

// Windows Header Files
#include <windows.h>
#include <windowsx.h>
#include <commctrl.h> // for tooltip
#include <commdlg.h> // GetOpenFileName
#include <shellapi.h> // DragQueryFile
#include <rpcndr.h> // for GDI+
#include <gdiplus.h>
#undef min // Need to leave defined above for gdiplus which uses the bad macros :/.
#undef max

/*

    #include <cderr.h>
    #include <dde.h>
    #include <ddeml.h>
    #include <dlgs.h>
    #ifndef _MAC
        #include <lzexpand.h>
        #include <mmsystem.h>
        #include <nb30.h>
        #include <rpc.h>
    #endif
    #include <shellapi.h>
    #ifndef _MAC
        #include <winperf.h>
        #include <winsock.h>
    #endif
    #ifndef NOCRYPT
        #include <wincrypt.h>
        #include <winefs.h>
        #include <winscard.h>
    #endif

    #ifndef NOGDI
        #ifndef _MAC
            #include <winspool.h>
            #ifdef INC_OLE1
                #include <ole.h>
            #else
                #include <ole2.h>
            #endif // !INC_OLE1
        #endif // !MAC
        #include <commdlg.h>
    #endif // !NOGDI
*/



// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <assert.h>

#include <cmath>
#include <array>
#include <charconv>
#include <optional>
#include <algorithm>
#include <numeric>
#include <vector>
#include <span>
