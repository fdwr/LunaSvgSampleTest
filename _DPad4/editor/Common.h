//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Common routines.
//
//----------------------------------------------------------------------------
#pragma once

namespace DWritePad { namespace COMHelpers { 

    struct NilInterface
    {
    };

    //T should be an interface
    //T2 should be of type CNanoComObjectRoot
    //usage:  CNanoComObjectRoot<IInterface3, CNanoComObjectRoot<IInterface2, CNanoComObjectRoot<IInterface1> > >
    template<typename T, typename T2 = NilInterface>
    class CNanoComObjectRoot : public T, public T2
    {
    private:
        typedef typename T InterfaceName;

    public:
        using T2::AddRef;
        using T2::Release;
        using T2::QueryInterface;

        HRESULT STDMETHODCALLTYPE QueryInterface( 
            IID const& riid, 
            void** ppvObject 
            )
        {
            return T2::QueryInterface(riid, ppvObject);
        }

        unsigned long STDMETHODCALLTYPE AddRef()
        {
            return T2::AddRef();
        }

        unsigned long STDMETHODCALLTYPE Release()
        {
            return T2::Release();
        }

    protected:
        virtual HRESULT STDMETHODCALLTYPE QueryInterfaceInternal( 
            IID const& riid, 
            void** ppvObject 
            ) override
        {
            HRESULT hr = S_OK;

            if (__uuidof(InterfaceName) == riid)
            {
                *ppvObject = dynamic_cast<InterfaceName*>(this);

                //increment the ref count
                static_cast<IUnknown*>(*ppvObject)->AddRef();
                return hr;
            }
            else
            {
                return T2::QueryInterfaceInternal(riid, ppvObject);
            }
        }
    };

    // a nano-com base class for objects that implement only one interface 
    // this class should be sufficient for any of the test classes 
    template<typename T>
    class CNanoComObjectRoot<T, NilInterface> : public T
    {
    private:
        typedef typename T InterfaceName;

    private:
        UINT32 cRefCount_;

    protected:
        CNanoComObjectRoot()
            : cRefCount_(0)
        {
        }

        virtual ~CNanoComObjectRoot()
        {
        }

        virtual HRESULT STDMETHODCALLTYPE QueryInterfaceInternal( 
            IID const& riid, 
            void** ppvObject 
            )
        {
            HRESULT hr = S_OK;

            if (__uuidof(InterfaceName) == riid)
            {
                *ppvObject = dynamic_cast<InterfaceName*>(this);
            }
            else if (__uuidof(IUnknown) == riid)
            {
                *ppvObject = dynamic_cast<IUnknown*>(this);
            }
            else
            {
                //on failure, *ppvObject must be NULL on return
                *ppvObject = NULL;
                return E_NOINTERFACE;
            }

            //increment the ref count
            static_cast<IUnknown*>(*ppvObject)->AddRef();
            return hr;
        }

    public:
        HRESULT STDMETHODCALLTYPE QueryInterface( 
            IID const& riid, 
            void** ppvObject 
            )
        {
            return QueryInterfaceInternal(riid, ppvObject);
        }

        unsigned long STDMETHODCALLTYPE AddRef()
        {
            return ++cRefCount_;
        }

        unsigned long STDMETHODCALLTYPE Release()
        {
            unsigned long cRefCount = --cRefCount_;
            if (0 == cRefCount)
            {
                delete this;
            }
            return cRefCount;
        }
    };

} }
