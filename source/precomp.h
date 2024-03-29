// header.h : include file for standard system include files,
// or project specific include files

#pragma once

// Including SDKDDKVer.h defines the highest available Windows platform.
// If you wish to build your application for a previous Windows platform, include WinSDKVer.h and
// set the _WIN32_WINNT macro to the platform you wish to support before including SDKDDKVer.h.
#include <SDKDDKVer.h>

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
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
#include <rpc.h>
#include <rpcndr.h> // for GDI+
#include <combaseapi.h> // for GDI+
#include <wtypes.h> // for GDI+
#include <gdiplus.h>
#include <WinCodec.h>
#include <wrl/client.h>
#undef min // Need to leave defined above for gdiplus which uses the bad macros :/.
#undef max


// WinCodec_Proxy.h appears to be missing from Visual Studio's include path??
extern "C"
{
    HRESULT WINAPI WICCreateImagingFactory_Proxy(
        __in UINT32 sdkVersion,
        __deref_out IWICImagingFactory** wicImagingFactory
    );
}

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
#include <filesystem>
#include <variant>
#include <format>
