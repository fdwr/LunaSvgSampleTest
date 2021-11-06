// THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
// PARTICULAR PURPOSE.
//
// Copyright (c) Microsoft Corporation. All rights reserved
//
// Contents:    Shared definitions.
//
//----------------------------------------------------------------------------

#pragma once

// The following macros define the minimum required platform.  The minimum required platform
// is the earliest version of Windows, Internet Explorer etc. that has the necessary features to run 
// your application.  The macros work by enabling all features available on platform versions up to and 
// including the version specified.

// Modify the following defines if you have to target a platform prior to the ones specified below.
// Refer to MSDN for the latest info on corresponding values for different platforms.

#ifndef WINVER                  // Minimum platform is Windows 7
#define WINVER 0x0601
#endif

#ifndef _WIN32_WINNT            // Minimum platform is Windows 7
#define _WIN32_WINNT 0x0601
#endif

#ifndef _WIN32_WINDOWS          // Minimum platform is Windows 7
#define _WIN32_WINDOWS 0x0601
#endif

#ifndef WIN32_LEAN_AND_MEAN     // Exclude rarely-used stuff from Windows headers
#define WIN32_LEAN_AND_MEAN
#endif

#ifndef NOMINMAX                // Use the standard's templated min/max
#define NOMINMAX
#endif

#ifndef _USE_MATH_DEFINES       // want PI defined
#define _USE_MATH_DEFINES
#endif


#ifndef __FUNCTIONW__
#define __FUNCTIONW__ L""
#endif


////////////////////////////////////////
// Common headers:

// C headers:
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <math.h>

// C++ headers:
#include <algorithm>
#include <numeric>
#include <string>
#include <vector>
#include <utility>
#include <limits>

// Windows headers:

#include <windows.h>
#include <windowsx.h>
#include <unknwn.h>
#include <CommDlg.h>
#include <CommCtrl.h>

#include <dwrite_1.h>
#include <stdint.h>
#include <strsafe.h>


////////////////////////////////////////
// Common macro definitions:

#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
#endif

// Use the double macro technique to stringize the actual value of s
#define STRINGIZE_(s) STRINGIZE2_(s)
#define STRINGIZE2_(s) #s

#define FAILURE_LOCATION L"\r\nFunction: " TEXT(__FUNCTION__) L"\r\nFile: " TEXT(__FILE__) L"\r\nLine: " TEXT(STRINGIZE_(__LINE__))

#if (_MSC_VER >= 1200 && _MSC_VER < 1500) // want to use std::min and std::max
#undef min
#undef max
#define min(x,y) _cpp_min(x,y)
#define max(x,y) _cpp_max(x,y)
#endif

// Ignore unreferenced parameters, since they are very common
// when implementing callbacks.
#pragma warning(disable : 4100)


////////////////////////////////////////
// Application specific headers/functions:

#define APPLICATION_TITLE "CustomLayout - DirectWrite script layer SDK sample"


enum {
    UnicodeMax = 0x10FFFF
};

// Needed text editor backspace deletion.
inline bool IsSurrogate(UINT32 ch) throw()
{
    // 0xD800 <= ch <= 0xDFFF
    return (ch & 0xF800) == 0xD800;
}


inline bool IsLeadingSurrogate(UINT32 ch) throw()
{
    // 0xD800 <= ch <= 0xDBFF
    return (ch & 0xFC00) == 0xD800;
}


inline bool IsTrailingSurrogate(UINT32 ch) throw()
{
    // 0xDC00 <= ch <= 0xDFFF
    return (ch & 0xFC00) == 0xDC00;
}


inline UINT32 MakeUnicodeCodepoint(UINT32 leading, UINT32 trailing) throw()
{
    return ((leading & 0x03FF) << 10 | (trailing & 0x03FF)) + 0x10000;
}


// Maps exceptions to equivalent HRESULTs,
inline HRESULT ExceptionToHResult() throw()
{
    try
    {
        throw;  // Rethrow previous exception.
    }
    catch(std::bad_alloc&)
    {
        return E_OUTOFMEMORY;
    }
    catch (...)
    {
        return E_FAIL;
    }
}


////////////////////////////////////////
// COM inheritance helpers.


// Releases a COM object and nullifies pointer.
template <typename InterfaceType>
inline void SafeRelease(IN OUT InterfaceType** currentObject)
{
    if (*currentObject != nullptr)
    {
        (*currentObject)->Release();
        *currentObject = nullptr;
    }
}


// Acquires an additional reference, if non-null.
template <typename InterfaceType>
inline InterfaceType* SafeAcquire(InterfaceType* newObject)
{
    if (newObject != nullptr)
        newObject->AddRef();

    return newObject;
}


// Sets a new COM object, releasing the old one.
template <typename InterfaceType>
inline void SafeSet(IN OUT InterfaceType** currentObject, InterfaceType* newObject)
{
    SafeAcquire(newObject);
    SafeRelease(currentObject);
    *currentObject = newObject;
}


template <typename InterfaceTypeOld, typename InterfaceTypeNew>
inline HRESULT SafeQueryInterface(InterfaceTypeOld* oldObject, IN OUT InterfaceTypeNew** newObject)
{
    SafeRelease(newObject);
    if (oldObject != nullptr)
    {
        return oldObject->QueryInterface(__uuidof(**newObject), reinterpret_cast<void**>(newObject));
    }

    return S_OK;
}


// Generic COM base implementation for classes, since DirectWrite uses
// callbacks for several different kinds of objects, particularly the
// script analysis source/sink.
//
// Example:
//
//  class TextAnalysis : public ComBase<QiList<IDWriteTextAnalysisSink> >
//
template <typename InterfaceChain>
class ComBase : public InterfaceChain
{
public:
    explicit ComBase() throw()
    :   refValue_(0)
    { }

    // IUnknown interface
    IFACEMETHOD(QueryInterface)(IID const& iid, OUT void** ppObject)
    {
        *ppObject = nullptr;
        InterfaceChain::QueryInterfaceInternal(iid, ppObject);
        if (*ppObject == nullptr)
            return E_NOINTERFACE;

        AddRef();
        return S_OK;
    }

    IFACEMETHOD_(ULONG, AddRef)()
    {
        return InterlockedIncrement(&refValue_);
    }

    IFACEMETHOD_(ULONG, Release)()
    {
        ULONG newCount = InterlockedDecrement(&refValue_);
        if (newCount == 0)
            delete this;

        return newCount;
    }

    virtual ~ComBase()
    { }

protected:
    ULONG refValue_;

private:
    // No copy construction allowed.
    ComBase(const ComBase& b);
    ComBase& operator=(ComBase const&);
};


struct QiListNil
{
};


// When the QueryInterface list refers to itself as class,
// which hasn't fully been defined yet.
template <typename InterfaceName, typename InterfaceChain>
class QiListSelf : public InterfaceChain
{
public:
    inline void QueryInterfaceInternal(IID const& iid, OUT void** ppObject) throw()
    {
        if (iid != __uuidof(InterfaceName))
            return InterfaceChain::QueryInterfaceInternal(iid, ppObject);

        *ppObject = static_cast<InterfaceName*>(this);
    }
};


// When this interface is implemented and more follow.
template <typename InterfaceName, typename InterfaceChain = QiListNil>
class QiList : public InterfaceName, public InterfaceChain
{
public:
    inline void QueryInterfaceInternal(IID const& iid, OUT void** ppObject) throw()
    {
        if (iid != __uuidof(InterfaceName))
            return InterfaceChain::QueryInterfaceInternal(iid, ppObject);

        *ppObject = static_cast<InterfaceName*>(this);
    }
};


// When the this is the last implemented interface in the list.
template <typename InterfaceName>
class QiList<InterfaceName, QiListNil> : public InterfaceName
{
public:
    inline void QueryInterfaceInternal(IID const& iid, OUT void** ppObject) throw()
    {
        if (iid != __uuidof(InterfaceName))
            return;

        *ppObject = static_cast<InterfaceName*>(this);
    }
};
