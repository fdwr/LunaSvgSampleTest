//----------------------------------------------------------------------------
//  Author:     Dwayne Robinson
//  History:    2015-06-19 Created
//----------------------------------------------------------------------------
#pragma once

#ifndef BUILD_OPTIMIZATION_STRING
#if defined(DEBUG) || defined(_DEBUG)
#define BUILD_OPTIMIZATION_STRING L"Debug"
#else
#define BUILD_OPTIMIZATION_STRING L"Release"
#endif
#endif

#if defined(_M_IX86)
#define BUILD_ARCHITECTURE_STRING L"x86 32-bit"
#elif defined(_M_X64)
#define BUILD_ARCHITECTURE_STRING L"64-bit"
#elif defined(_M_ARM_FP)
#define BUILD_ARCHITECTURE_STRING L"ARM"
#else
#define BUILD_ARCHITECTURE_STRING L"Unknown"
#endif

#ifndef NDEBUG
#define DEBUG_MESSAGE(...) Application::DebugLog(__VA_ARGS__)
#else
#define DEBUG_MESSAGE(...) (0)
#endif

#if !defined(APPLICATION_TITLE)
#define APPLICATION_TITLE L"Variation Slider Demo (displays text with various text layout/rendering API's and variable font values)"
#endif

#if !defined(BUILD_TITLE_STRING)
#define BUILD_TITLE_STRING \
        APPLICATION_TITLE L", "\
        TEXT(__DATE__) L", "\
        BUILD_ARCHITECTURE_STRING L", "\
        BUILD_OPTIMIZATION_STRING
#endif


class Application
{
public:
    static HINSTANCE g_hModule;
    static MSG g_msg;
    static HWND g_mainHwnd;

    static void Dispatch();
    static int DisplayError(__in_z const char16_t* message, __in_z_opt const char16_t* formatString, int functionResult);
    static void Fail(__in_z const char16_t* message, __in_z_opt const char16_t* formatString, int functionResult);
    static void DebugLog(const char16_t* logMessage, ...);
    static HRESULT ExceptionToHResult() throw();
};
