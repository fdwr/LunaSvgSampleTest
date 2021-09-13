#pragma once


template <
    typename ResourceType,          // type of the resource held onto
    typename ActualType,            // type as known by the resource releaser (like HGDIOBJ vs HBITMAP)
    typename ResourceReleaserType,  // function prototype of the releasing function
    ResourceReleaserType ResourceReleaser // address of function to release object
    >
class AutoResource
{
public:
    // You *could* make this private, but then you just have
    // add an unnecessary getter onto what is simply a
    // thin class whose sole purpose is the later destruction
    // of the object and adds no other additional value.

    ResourceType resource_; // could be void*, HANDLE, FILE*, GDIOBJ...

    typedef AutoResource<ResourceType, ActualType, ResourceReleaserType, ResourceReleaser> Self;

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

    // Used when passed as an out parameter to any function.
    // The caller is responsible for clearing the existing object.
    inline ResourceType* operator&() throw()
    {
        return &resource_;
    }

    // Explicit getter for times when the compiler becomes confused
    // during overload resolution.
    inline ResourceType Get()
    {
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


typedef AutoResource<HDC, HDC, BOOL (WINAPI*)(HDC), &DeleteDC> GdiDeviceContext;
typedef AutoResource<HPEN, HGDIOBJ, BOOL (WINAPI*)(HGDIOBJ), &DeleteObject> GdiPenHandle;
typedef AutoResource<HFONT, HGDIOBJ, BOOL (WINAPI*)(HGDIOBJ), &DeleteObject> GdiFontHandle;
typedef AutoResource<HBITMAP, HGDIOBJ, BOOL (WINAPI*)(HGDIOBJ), &DeleteObject> GdiBitmapHandle;
typedef AutoResource<HGLOBAL, HGLOBAL, HGLOBAL (WINAPI*)(HGLOBAL), &GlobalFree> GlobalMemoryResource;
typedef AutoResource<HANDLE, HANDLE, BOOL (WINAPI*)(HANDLE), &CloseHandle> FileHandle;
typedef AutoResource<FILE*, FILE*, int (__cdecl *)(FILE*), &fclose> CstdioFileHandle;
typedef AutoResource<HMODULE, HMODULE, BOOL (WINAPI*)(HMODULE), &FreeLibrary> ModuleHandle;
