// Include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
#pragma once


////////////////////////////////////////
// Common macro definitions:

// Disable unknown pragma warnings (for when when compiling directly with VC)
#pragma warning(disable: 4068)

// The C++0x keyword is supported in Visual Studio 2010
#if _MSC_VER < 1600
#ifndef nullptr
#define nullptr 0
#endif
#endif

// The static assertion keyword is supported in Visual Studio 2010
#if _MSC_VER < 1600
#ifndef static_assert
#define static_assert(exp,msg)
#endif
#endif

#ifndef _USE_MATH_DEFINES
#define _USE_MATH_DEFINES       // yes, we DO want PI defined
#endif

#if !defined(DEBUG) && !defined(NDEBUG)
#define DEBUG
#endif

#if (_MSC_VER >= 1400) // ensure that a virtual method overrides an actual base method.
#define OVERRIDE override
#else
#define OVERRIDE
#endif

#ifndef UUIDOF
#define UUIDOF(iid) __uuidof(iid)
#endif

#ifndef ARRAY_SIZE 
#define ARRAY_SIZE ARRAYSIZE
#endif

#ifndef IFR
#define IFR(exp) { HRESULT hrInternal = (exp); if (FAILED(hrInternal)) {return hrInternal; } }
#endif

#ifndef RETURN_ON_FAIL // For any negative HRESULT code
#define RETURN_ON_FAIL(exp, retval) { HRESULT hrInternal = (exp); if (FAILED(hrInternal)) {return (retval); } }
#endif

#ifndef RETURN_ON_ZERO // For null, zero, or false
#define RETURN_ON_ZERO(exp, retval) if (!(exp)) {return (retval);}
#endif

#ifndef INPUT_ASSERT_FAIL_MSG
#define INPUT_ASSERT_FAIL_MSG(expression)   {if (!(expression)) __debugbreak();}
#endif

#ifndef INVARIANT_ASSERT
#define INVARIANT_ASSERT(expression)        {if (!(expression)) __debugbreak();}
#endif

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

// Use the double macro technique to stringize the actual value of s
#ifndef STRINGIZE_
#define STRINGIZE_(s) STRINGIZE2_(s)
#define STRINGIZE2_(s) #s
#endif

#ifndef __LPREFIX
#define __LPREFIX2(x) L ## x
#define __LPREFIX(x) __LPREFIX(x)
#endif

// Weird... windowsx.h lacks this function
#ifndef SetWindowStyle
#define SetWindowStyle(hwnd, value) ((DWORD)SetWindowLong(hwnd, GWL_STYLE, value))
#endif

#ifndef FAILURE_LOCATION 
#define FAILURE_LOCATION L"\r\nFunction: " TEXT(__FUNCTION__) L"\r\nFile: " TEXT(__FILE__) L"\r\nLine: " TEXT(STRINGIZE_(__LINE__))
#endif

#ifndef ALIGNOF
// ALIGNOF macro yields the byte alignment of the specified type.
// Replace with C++11 standard keyword 'alignof' once the compiler supports it.
#ifdef _MSC_VER
// Use Microsoft language extension
#define ALIGNOF(T) __alignof(T)
#else
// Use GCC language extension
#define ALIGNOF(T) __alignof__(T)
#endif
#endif

#define COMPILE_ASSERT(exp) static_assert((exp), "Assertion failed")

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN // Exclude rarely-used stuff from Windows headers
#define NOMINMAX
#endif

#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
