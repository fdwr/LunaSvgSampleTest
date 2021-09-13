//----------------------------------------------------------------------------
//  Author:     Dwayne Robinson
//  History:    2015-06-19 Created
//----------------------------------------------------------------------------
#pragma once


// Helper to return multiple supported interfaces.
//
// Example:
//
//  STDMETHOD(QueryInterface)(IID const& iid, __out void** object) override
//  {
//      COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
//      COM_BASE_RETURN_INTERFACE(iid, IDWriteInlineObject, object);
//      COM_BASE_RETURN_NO_INTERFACE(object);
//  }
//
#define COM_BASE_RETURN_INTERFACE(iid, U, object) \
    if (iid == __uuidof(U)) \
    { \
        U* p = static_cast<U*>(this); \
        p->AddRef(); \
        *object = p; \
        return S_OK; \
    }

// For those cases when diamond inheritance causes the ambiguous cast compilation error.
#define COM_BASE_RETURN_INTERFACE_AMBIGUOUS(iid, U, object, subthis) \
    if (iid == __uuidof(U)) \
    { \
        U* p = static_cast<U*>(subthis); \
        p->AddRef(); \
        *object = p; \
        return S_OK; \
    }

#define COM_BASE_RETURN_NO_INTERFACE(object) \
        *object = nullptr; \
        return E_NOINTERFACE;


class ComObject : public IUnknown
{
public:
    // Default implementation for simple class.
    // Anything that implements more UUID's needs to override this method.
    //
    virtual HRESULT STDMETHODCALLTYPE QueryInterface(IID const& iid, _Out_ void** object) throw() override
    {
        if (iid == __uuidof(IUnknown))
        {
            *object = static_cast<IUnknown*>(this);
            AddRef();
            return S_OK;
        }
        *object = nullptr;
        return E_NOINTERFACE;
    }

    virtual ULONG STDMETHODCALLTYPE AddRef() throw() override
    {
        return InterlockedIncrement(&refCount_);
    }

    virtual ULONG STDMETHODCALLTYPE Release() throw() override
    {
        auto newRefCount = InterlockedDecrement(&refCount_);
        if (newRefCount == 0)
        {
            delete this;
        };
        return newRefCount;
    }

protected:
    // Ensure 'delete this' calls the destructor of the most derived class.
    virtual ~ComObject()
    { }

    ULONG refCount_ = 0;
};
