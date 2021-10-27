//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Smart pointers.
//
//----------------------------------------------------------------------------
#pragma once


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

// For those cases when diamond inheritance causes the ambiguous cast compilation error.
#define COM_BASE_RETURN_INTERFACE_AMBIGUOUS(iid, U, object, subthis) \
    if (iid == UUIDOF(U)) \
    { \
        U* p = static_cast<U*>(subthis); \
        p->AddRef(); \
        *object = p; \
        return S_OK; \
    }

#define COM_BASE_RETURN_NO_INTERFACE(object) \
        *object = nullptr; \
        return E_NOINTERFACE;


// RefCountBase implementation for local reference-counted objects.
class RefCountBase
{
public:
    RefCountBase() throw()
    { };

    explicit RefCountBase(unsigned long refCount) throw()
    :   refCount_(refCount)
    { }

    unsigned long IncrementRef() throw()
    {
        return InterlockedIncrement(IN OUT &refCount_);
    }

    unsigned long DecrementRef() throw()
    {
        auto newCount = InterlockedDecrement(IN OUT &refCount_);
        if (newCount == 0)
            delete this;
        return newCount;
    }

    bool HasExclusiveAccess() const throw()
    {
        // True if the reference is held by exactly one owner.
        return InterlockedOr(IN OUT reinterpret_cast<long*>(&refCount_), 0) == 1;
    }

    // Ensure we have a v-table pointer and that the destructor is always
    // called on the most derived class.
    virtual ~RefCountBase()
    { }

protected:
    mutable unsigned long refCount_ = 0;
};


class RefCountBaseStatic : public RefCountBase
{
public:
    typedef RefCountBase Base;

    explicit RefCountBaseStatic() throw()
    :   Base()
    { }

    explicit RefCountBaseStatic(ULONG refValue) throw()
    :   Base(refValue)
    { }

    // Just use inherited IncrementRef.

    // Do not delete the reference.
    unsigned long DecrementRef() throw()
    {
        auto newCount = InterlockedDecrement(&refCount_);
        if (newCount == 0)
            Finalize();
        return newCount;
    }

    // Ensure we have a v-table pointer and that the finalizer is always
    // called on the most derived class. Even static singletons and
    // stacked based classes may have a distinction between the destructor
    // and all references being released.
    virtual void Finalize()
    { }
};


// COM base implementation for IUnknown.
//
// Example:
//
//  class RenderTarget : public ComBase<IDWriteTextRenderer>
//
template <typename T = IUnknown, typename RCB = RefCountBase>
class ComBase : public RCB, public T
{
public:
    typedef RCB Base;
    typedef T BaseInterface;

/*
** Leave the definition of QI to the subclass.
**
    // IUnknown interface
    STDMETHOD(QueryInterface)(IID const& iid, __out void** object) OVERRIDE
    {
        COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
        COM_BASE_RETURN_NO_INTERFACE(object);
    }
*/

    IFACEMETHODIMP_(unsigned long) AddRef()
    {
        return RCB::IncrementRef();
    }

    IFACEMETHODIMP_(unsigned long) Release()
    {
        return RCB::DecrementRef();
    }
};


struct RefCountResourceTypePolicy : public DefaultResourceTypePolicy<RefCountBase*>
{
    inline static void Acquire(RefCountBase* resource) throw()
    {
        if (resource != nullptr)
            resource->IncrementRef();
    }

    inline static void Release(RefCountBase* resource) throw()
    {
        if (resource != nullptr)
            resource->DecrementRef();
    }
};


template<typename ResourceType> using RefCountPtr = AutoResource<ResourceType*, RefCountResourceTypePolicy, RefCountBase*>;
#if 0
template<typename ResourceType>
class RefCountPtr : public AutoResource<ResourceType*, RefCountResourceTypePolicy, RefCountBase*>
{
public:
    typedef AutoResource<ResourceType*, RefCountResourceTypePolicy, RefCountBase*> Base;
    typedef RefCountPtr Self;

    // Necessary forwarders. Although this class adds no data members
    // whatsoever, we still need to forward everything along due to the
    // current lack of template typedefs in C++.

    inline Self() {};
    inline Self(ResourceType* resource) : Base(resource) {}
    inline Self(Self&& other) : Base(static_cast<Base&&>(other)) {}
    inline Self& operator=(ResourceType* resource) { Set(resource); return *this; }
};

#endif
