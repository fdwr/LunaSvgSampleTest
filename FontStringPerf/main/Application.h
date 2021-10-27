//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Text Layout Experimental test app.
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2008-02-11   dwayner    Created
//
//----------------------------------------------------------------------------

#pragma once

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
#define BUILD_TITLE_STRING L"FontStringPerf"
#endif

#ifndef APPLICATION_TITLE
#define APPLICATION_TITLE L"FontStringPerf"
#endif

#ifndef NDEBUG
#define DEBUG_MESSAGE(...) Application::DebugLog(__VA_ARGS__)
#else
#define DEBUG_MESSAGE(...) (0)
#endif

class Application
{
public:
    static HINSTANCE g_hModule;
    static ModuleHandle g_DWriteModule;
    static ComPtr<IDWriteFactory> g_DWriteFactory;

    static MSG g_msg;
    static HWND g_mainHwnd;

    static void Dispatch();
    static int DisplayError(__in_z const wchar_t* message, __in_z_opt const wchar_t* formatString, int functionResult);
    static void Fail(__in_z const wchar_t* message, __in_z_opt const wchar_t* formatString, int functionResult);
    static void DebugLog(const wchar_t* logMessage, ...);
    static HRESULT ExceptionToHResult() throw();
};
