//+---------------------------------------------------------------------------
//
//  Contents:   Automatic resource management.
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2008-02-09   dwayner    Created
//
//----------------------------------------------------------------------------
#pragma once


template <
    typename ResourceType,  // type of the resource held onto
    typename ActualType,    // type as known by the resource releaser (like HGDIOBJ vs HBITMAP)
    typename ReturnType,    // return value from resource releaser
    ReturnType (*ResourceReleaser)(ActualType) // function to release object
    >
class AutoResource
{
public:
    // You *could* make this private, but then you just have
    // add an unnecessary getter onto what is simply a
    // thin class whose sole purpose is the later destruction
    // of the object and adds no other additional value.

    ResourceType resource_; // could be void*, HANDLE, GDIOBJ...

    typedef AutoResource<ResourceType, ActualType, ReturnType, ResourceReleaser> Self;

    AutoResource(ResourceType resource)
    :   resource_(resource)
    {}

    AutoResource()
    :   resource_(0)
    {}

    operator ResourceType()
    {
        return resource_;
    }

    inline ResourceType operator =(ResourceType resource)
    {
        return Set(resource);
    }

    inline ResourceType Set(ResourceType resource)
    {
        Clear();
        resource_ = resource;
        return resource;
    }

    void Clear()
    {
        // Most resources (pointers to memory, HGLOBALS, HGDIOBJ...)
        // are indicated as empty by setting to 0/NULL. If a resource
        // has special semantics, override this method. If it becomes
        // desirable to use more complex, aggregrate resources (where
        // the assignment of 0 is meaningless) this may need to be
        // revised to use a global function like IsCleared(Type)
        // rather than testing directly.
        if (resource_ != 0)
        {
            ResourceReleaser(static_cast<ActualType>(resource_));
            resource_ = 0;
        }
    }

    inline void Abandon()
    {
        resource_ = 0;
    }

    void swap(Self& other)
    {
        std::swap(resource_, other.resource_);
    }

    ~AutoResource()
    {
        Clear();
    }
};


typedef AutoResource<HDC, HDC, BOOL, &DeleteDC> GdiDeviceContext;
typedef AutoResource<HPEN, HGDIOBJ, BOOL, &DeleteObject> GdiPenHandle;
typedef AutoResource<HFONT, HGDIOBJ, BOOL, &DeleteObject> GdiFontHandle;
typedef AutoResource<HBITMAP, HGDIOBJ, BOOL, &DeleteObject> GdiBitmapHandle;
typedef AutoResource<HGLOBAL, HGLOBAL, HGLOBAL, &GlobalFree> GlobalMemoryResource;
