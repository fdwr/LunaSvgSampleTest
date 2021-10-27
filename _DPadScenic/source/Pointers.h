//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
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

    // Explicitly clear whatever is held, regardless of
    // whether something is already set.
    inline ComPtr& Clear()
    {
        Attach(NULL);
        return *this;
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
