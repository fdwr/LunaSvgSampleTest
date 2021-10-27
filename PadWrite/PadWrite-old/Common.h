//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Common, application wide definitions.
//
//----------------------------------------------------------------------------
#pragma once

////////////////////////////////////////
// Common macro definitions:

#if !defined(NDEBUG) && !defined(DEBUG)
    #define DEBUG
#endif

#if (_MSC_VER >= 1400) // ensure that a virtual method overrides an actual base method.
    #define OVERRIDE override
#else
    #define OVERRIDE
#endif

#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
#endif

#ifndef IFR // If API call failed, return HRESULT code
#define IFR(exp) { HRESULT hr = (exp); if (FAILED(hr)) {return hr; } }
#endif

#ifndef IFRV // If API call failed, just return void
#define IFRV(exp) { HRESULT hr = (exp); if (FAILED(hr)) {return;} }
#endif

#ifndef IZR // If API call yielded zero, return the supplied error code.
#define IZR(exp, retval) { if ((exp) == 0) {return retval; } }
#endif

// Use the double macro technique to stringize the actual value of s
#define STRINGIZE_(s) STRINGIZE2_(s)
#define STRINGIZE2_(s) #s

#define FAILURE_LOCATION "\r\nFunction: " __FUNCTION__ "\r\nLine: " STRINGIZE_(__LINE__)

#if (_MSC_VER >= 1200) // want to use std::min and std::max
#undef min
#undef max
#define min(x,y) _cpp_min(x,y)
#define max(x,y) _cpp_max(x,y)
#endif

////////////////////////////////////////
// Application specific headers/functions:

#define APPLICATION_TITLE "PadWrite - DirectWrite layout SDK sample"

// Needed text editor backspace deletion.
inline bool IsSurrogate(UINT32 ch) throw()
{
    // 0xD800 <= ch <= 0xDFFF
    return (ch & 0xF800) == 0xD800;
}


inline bool IsHighSurrogate(UINT32 ch) throw()
{
    // 0xD800 <= ch <= 0xDBFF
    return (ch & 0xFC00) == 0xD800;
}


inline bool IsLowSurrogate(UINT32 ch) throw()
{
    // 0xDC00 <= ch <= 0xDFFF
    return (ch & 0xFC00) == 0xDC00;
}


////////////////////////////////////////
// COM help.

// COM pointer based on _com_ptr_t that declares the needed COM ID.
//
// Example:
//
//  ComPtr<IDWriteTextLayout> textLayout;
//
template <typename T>
class ComPtr : public _com_ptr_t<_com_IIID<T, &__uuidof(T)> >
{
public:
    ComPtr()
    { };

    ComPtr(T* p)
    {
        Attach(p, true);
    }
};


// Generic COM base implementation for classes, since DirectWrite uses
// callbacks for several different kinds of objects, particularly the
// text renderer and inline objects.
//
// Example:
//
//  class RenderTarget : public ComBase<QiList<IDWriteTextRenderer> >
//
template <typename InterfaceChain>
class ComBase : public InterfaceChain
{
public:
    explicit ComBase(ULONG refValue = 0) throw() : refValue_(refValue)
    { }

    // IUnknown interface
    STDMETHOD(QueryInterface)(IID const& iid, __out void** ppObject) OVERRIDE
    {
        *ppObject = NULL;
        InterfaceChain::QueryInterfaceInternal(iid, ppObject);
        if (*ppObject != NULL)
        {
            AddRef();
            return S_OK;
        }
        return E_NOINTERFACE;
    }

    STDMETHOD_(ULONG, AddRef)() OVERRIDE
    {
        return InterlockedIncrement(&refValue_);
    }

    STDMETHOD_(ULONG, Release)() OVERRIDE
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
    inline void QueryInterfaceInternal(IID const& iid, __out void** ppObject)
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
    // Note nonvirtual call.
    inline void QueryInterfaceInternal(IID const& iid, __out void** ppObject)
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
    // Note nonvirtual call.
    inline void QueryInterfaceInternal(IID const& iid, __out void** ppObject)
    {
        if (iid != __uuidof(InterfaceName))
            return;

        *ppObject = static_cast<InterfaceName*>(this);
    }
};


////////////////////////////////////////
// HRESULT based exception.

class HrException : public std::exception
{
public:
    typedef std::exception Base;

    HrException(HRESULT hr, const char* message)
        :   Base(message),
            hr_(hr)
    { }

    inline HRESULT GetErrorCode()
    {
        return hr_;
    }

    inline static void IfFailed(HRESULT hr, const char* message)
    {
        // Throws if the given HRESULT failed.
        if (FAILED(hr))
            throw HrException(hr, message);
    }

    inline static void IfFailed(HRESULT hr)
    {
        // Throws if the given HRESULT failed.
        if (FAILED(hr))
            throw HrException(hr, "API error");
    }

protected:
    HRESULT hr_;
};
