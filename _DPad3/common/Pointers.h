//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Smart pointers.
//
//----------------------------------------------------------------------------


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

    // Release previous object, assign new one, and increment it's count.
    inline void Set(T* p)
    {
        Attach(p, true);
    }

    inline ComPtr& Clear()
    {
        Attach(NULL);
        return *this;
    }
};


// Helper to return multiple supported interfaces.
//
// Example:
//
//  STDMETHOD(QueryInterface)(IID const& iid, __out void** object) OVERRIDE
//  {
//      COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
//      COM_BASE_RETURN_INTERFACE(iid, IDWriteInlineObject, object);
//      COM_BASE_RETURN_NO_INTERFACE(object);
//  }
//
#define COM_BASE_RETURN_INTERFACE(iid, U, object) \
    if (iid == UUIDOF(U)) \
    { \
        U* p = static_cast<U*>(this); \
        p->AddRef(); \
        *object = p; \
        return S_OK; \
    }

#define COM_BASE_RETURN_NO_INTERFACE(object) \
        *object = NULL; \
        return E_NOINTERFACE;


// RefCountBase implementation for local reference-counted objects.
class RefCountBase
{
public:
    explicit RefCountBase(ULONG refValue = 0) throw() : refValue_(refValue)
    { }

    ULONG IncrementRef() throw()
    {
        return InterlockedIncrement(&refValue_);
    }

    ULONG DecrementRef() throw()
    {
        ULONG newCount = InterlockedDecrement(&refValue_);
        if (newCount == 0)
            delete this;
        return newCount;
    }

    virtual ~RefCountBase()
    { }

protected:
    ULONG refValue_;
};


// COM base implementation for IUnknown.
//
// Example:
//
//  class RenderTarget : public ComBase<IDWriteTextRenderer>
//
template <typename T = IUnknown>
class ComBase : public RefCountBase, public T
{
public:
    // IUnknown interface
    STDMETHOD(QueryInterface)(IID const& iid, __out void** object) OVERRIDE
    {
        COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
        COM_BASE_RETURN_NO_INTERFACE(object);
    }

    STDMETHOD_(ULONG, AddRef)() OVERRIDE
    {
        return IncrementRef();
    }

    STDMETHOD_(ULONG, Release)() OVERRIDE
    {
        return DecrementRef();
    }
};


template<typename T>
class SmartPtrBase
{
public:
    T& operator*()  const throw()   {   return *p_; }

    T* operator->() const throw()   {   return p_;  }

    operator T*()   const throw()   {   return p_;  }

protected:
    explicit SmartPtrBase(T* p = NULL) throw() : p_(p)
    { }

    // Disallow polymorphic deletion of the base smart pointer type to prevent memory leaks.
    ~SmartPtrBase() throw()
    { }

protected:
    T* p_;
};


// RefCountPtr
//      Reference-counted smart pointer where the reference count is part of
//      the pointed-to object.
//
template<typename T>
class RefCountPtr : public SmartPtrBase<T>
{
public:
    RefCountPtr() throw()
    {
    }

    explicit RefCountPtr(T* p) throw() : SmartPtrBase(p)
    {
        IncrementRef();
    }

    RefCountPtr(RefCountPtr<T> const& p) throw() : SmartPtrBase(p.p_)
    {
        IncrementRef();
    }

    ~RefCountPtr() throw()
    {
        DecrementRef();
    }

    RefCountPtr<T>& operator=(RefCountPtr<T> const& rhs) throw();

    T* Get() const throw()
    {
        return p_;
    }

    void Set(T* p) throw()
    {
        RefCountPtr<T> temp(p);
        swap(temp);
    }

    RefCountPtr& Clear() throw()
    {
        DecrementRef();
        p_ = NULL;
        return *this;
    }

    void swap(RefCountPtr<T>& rhs) throw()
    {
        using std::swap;
        swap(p_, rhs.p_);
    }

private:
    void IncrementRef() const throw()
    {
        if (p_ != NULL)
            p_->IncrementRef();
    }

    void DecrementRef() throw()
    {
        if (p_ != NULL)
            p_->DecrementRef();
    }
};

namespace std
{
    template<typename T>
    void swap(RefCountPtr<T>& lhs, RefCountPtr<T>& rhs) throw()
    {
        lhs.swap(rhs);
    }
}

template<typename T>
RefCountPtr<T>& RefCountPtr<T>::operator=(RefCountPtr<T> const& rhs) throw()
{
    rhs.IncrementRef();
    DecrementRef();
    p_ = rhs.p_;
    return *this;
}
