//---------------------------------------------------------------------------
//
//  No copyright. No rights reserved. No royalties nor permission needed.
//
//  - You may explicitly use the code in parts or as a whole for both
//    commercial and non-commercial projects.
//  - You may freely redistribute the code modified or unchanged, or
//    you can leave your changes isolated.
//
// *This library is not produced by, endorsed by, or supported by Microsoft.
//  It is merely a supplementary library, dependent on the real DirectWrite,
//  written to augment and fill in functionality holes.
//
//  Feel free to use it for any projects, commercial or not, as a whole or in
//  parts. No warranty or guarantees of correctness! You have the code. Come
//  to your own conclusion regarding the robustness.
//
//----------------------------------------------------------------------------

#pragma once
#include "BaseTsd.h"

////////////////////////////////////////////////////////////////////////////////

namespace DWritEx
{

template<typename T>
class SmartPtrBase
{
public:
    SmartPtrBase(T* p) throw() : p_(p) {};
    ~SmartPtrBase() throw() {};

    inline operator T*() const throw()
    {
        return p_;
    }

    T* p_;
};

template<typename T>
class ComPtr : SmartPtr
{
public:
    ComPtr() throw() {}

    explicit ComPtr(T* p) throw() : SmartPtrBase(p)
    {
        IncrementRef();
    }

    ~ComPtr() throw()
    {
        DecrementRef();
    }

    T** operator&() throw()
    {
        return &p_;
    }

    void Clear() throw()
    {
        DecrementRef();
        p_ = NULL;
    }

    T* Abandon() throw()
    {
        T* p = p_;
        p_ = NULL;
        return p;
    }

    // todo: assignment, copy constructor...

private:
    void IncrementRef() const throw()
    {
        if (p_ != NULL)
            p_->AddRef();
    }

    void DecrementRef() throw()
    {
        if (p_ != NULL)
            p_->Release();
    }
}

} // namespace DWritEx
