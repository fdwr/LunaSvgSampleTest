//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Automatic resource management.
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2007-07-30   dwayner    Created
//              2008-02-09   dwayner    Ported to DWrite
//              2009-12-16   dwayner    Updated to support __cdecl too (fclose)
//              2010-07-08   dwayner    Updated to handle ref counting policies
//
//----------------------------------------------------------------------------
#pragma once


// Example usage:
//
//  GdiPenHandle gdiPenHandle;
//  WaitHandleResource waitHandle;
//  ComPtr<IDWriteTextLayout> ComPtr;


template <typename ResourceType = void*> // type of the resource held onto
struct DefaultResourceTypePolicy
{
    inline static void InitializeEmpty(__out ResourceType* resource) throw()
    {
        // Most resources (pointers to memory, HGLOBALS, HGDIOBJ...)
        // are indicated as empty by setting to 0/NULL. If a resource
        // has special semantics, override this method, or supply a
        // different policy class.

        *resource = 0;
    }

    inline static bool IsNull(ResourceType resource) throw()
    {
        // I'm avoiding using nullptr here since we could only then use it
        // with pointer types.
        return (resource == 0);
    }

    inline static void Acquire(ResourceType resource) throw()
    {
        // Do nothing.
        // For handles, we could duplicate the handle.
        // For subclassed ref-count objects, we could increase the count.
    }

    inline static void Release(ResourceType resource) throw()
    {
        // Do nothing.
        // For handles, we close the handle.
        // For subclassed ref-count objects, we could decrease the count.
    }
};


// Holds either a simple non-ref counted resource, such as a handle, raw
// memory, or a ref-counted interface, freeing it upon destruction (or not,
// depending on the policy implementation).
template <
    typename ResourceType = void*, // type of the resource held onto
    typename ResourceTypePolicy = DefaultResourceTypePolicy<ResourceType>,
    typename BaseResourceType = ResourceType // type as known by the resource releaser (like HGDIOBJ vs HBITMAP)
    >
class AutoResource
{
public:
    typedef AutoResource<ResourceType, ResourceTypePolicy, BaseResourceType> Self;

    AutoResource(ResourceType resource)
    :   resource_(resource)
    {
        // This is generally a no-op, but it matters for ref-counted objects.
        ResourceTypePolicy::Acquire(resource_);
    }

    AutoResource(Self const& other) // Copy constructor
    :   resource_(other.resource_)
    {
        // This is generally a no-op, but it matters for ref-counted objects.
        ResourceTypePolicy::Acquire(resource_);
    }

    AutoResource(Self&& other) // Move constructor
    :   resource_(other.resource_)
    {
        ResourceTypePolicy::InitializeEmpty(Cast(&other.resource_));
    }

    inline AutoResource() // Default constructor generally zeroes it.
    {
        ResourceTypePolicy::InitializeEmpty(Cast(&resource_));
    }

    inline ~AutoResource() throw()
    {
        // Notice we merely free the resource and do not zero the resource,
        // since we actually prefer to leave the value intact, not because
        // it's one fewer write back out to memory, but because it leaves a
        // more debuggable trace). If the derived class is a non-owning pointer,
        // the free is a no-op.

        ResourceTypePolicy::Release(resource_);
    }

    // Compiler generated assignment and copy construction do the right thing
    // here, since simple resources don't have any complex behavior.

    // Implicitly promote to the resource type for all the times the resource
    // handle/pointer is passed by value to a function.
    inline operator ResourceType() const throw()
    {
        return resource_;
    }

    // Explicit getter for times when the compiler becomes confused
    // during overload resolution.
    inline ResourceType Get() const throw()
    {
        return resource_;
    }

    // Implicitly promote to a reference to the resource type for when passed
    // to functions that want a reference, and for swapping resources in/out.
    // If modified directly, the caller is responsible for managing the object.
    // This intentionally does NOT have evil behavior of freeing the resource
    // since needing the address of a resource is not only for the sake of
    // out params - it's perfectly legitimate as an in param too, such as with
    // WaitForMultipleObjects().
    inline operator ResourceType&() throw()
    {
        return resource_;
    }

    // Used when passed as an out parameter to any function,
    // or when the caller needs a pointer to a pointer.
    // If modified directly, the caller is responsible for managing the object.
    inline ResourceType* operator&() throw()
    {
        return &resource_;
    }

    // Explicitly named form.
    inline ResourceType* Address() throw()
    {
        return &resource_;
    }

    // Explicitly named form.
    inline ResourceType& Reference() throw()
    {
        return resource_;
    }

    // For calling methods of an interface.
    //
    // ComPtr<IFoo> foo;
    // foo->Bar();
    inline ResourceType operator->() const throw()
    {
        return resource_;
    }

    // Set a new resource, acquiring the new resource before releasing the
    // old one, to prevent premature freeing issues with ref-counted objects
    // and because acquiring a resource is more likely to fail (with a
    // potential exception) than realising. For non-ref-counted objects,
    // the acquire is generally a no-op.
    inline ResourceType Set(ResourceType resource)
    {
        if (resource != resource_)
        {
            ResourceTypePolicy::Acquire(resource);
            ResourceTypePolicy::Release(resource_);
            resource_ = resource;
        }
        return resource_;
    }

    inline Self& operator=(ResourceType resource)
    {
        Set(resource);
        return *this;
    }

    inline Self& operator=(const Self& other)
    {
        Set(other.resource_);
        return *this;
    }

    // No check. Just set it directly.
    inline ResourceType SetDirectly(ResourceType resource)
    {
        DEBUG_ASSERT(IsNull());
        resource_ = resource;
        return resource_;
    }

    void Clear()
    {
        ResourceTypePolicy::Release(resource_);
        ResourceTypePolicy::InitializeEmpty(Cast(&resource_));
    }

    // Abandon the resource without freeing it.
    inline void Abandon() throw()
    {
        ResourceTypePolicy::InitializeEmpty(Cast(&resource_));
    }

    // Like ATL's CComPtr, VS's _com_ptr_t, and the CLR's ptr::Attach,
    // this Attach does not increment the ref count, which is symmetric
    // to Detach().
    // * No self-assignment checking is done here.
    ResourceType Attach(ResourceType resource) throw()
    {
        std::swap(resource_, resource);
        ResourceTypePolicy::Release(resource);
        return resource_;
    }

    // Lets go of the resource without freeing it, but returning it
    // to the caller.
    ResourceType Detach() throw()
    {
        ResourceType resource = resource_;
        ResourceTypePolicy::InitializeEmpty(Cast(&resource_));
        return resource;
    }

    // For the common transfer usage, where one container directly steals another,
    // it simplifies to:
    //
    //  p1.Attach(p2.Detach())   ->   p1.Steal(p2)
    //
    inline void Steal(Self& other) throw()
    {
        swap(other);
        other.Clear();
    }

    inline bool IsNull() const throw()
    {
        return ResourceTypePolicy::IsNull(resource_);
    }

    inline bool IsSet() const throw()
    {
        return !ResourceTypePolicy::IsNull(resource_);
    }

    ////////////////////
    // STL aliases

    inline void clear()
    {
        Clear();
    }

    inline void swap(ResourceType& resource) throw()
    {
        std::swap(resource_, resource);
    }

    inline void reset(ResourceType resource)
    {
        Set(resource);
    }

    // there is no 'release' alias, since the C++ auto_ptr does something
    // different than typically expected (detaches rather than frees).

protected:
    inline BaseResourceType* Cast(ResourceType* resource)
    {
        // Cast resource to the base type, such as an interface:
        //      IDWriteFont/IDWriteTextLayout/IShellFolder -> IUnknown
        // or handle:
        //      HBITMAP/HPEN/HFONT -> HGDIOBJ.
        //
        // Such an explicit cast isn't normally needed since the resource
        // is passed by pointer and implicitly castable, but a pointer to
        // a pointer is not directly castable. Trying to pass IShellFolder**
        // to a function that takes IUnknown** is normally a compile error
        // (even though it would actually work just fine).

        return reinterpret_cast<BaseResourceType*>(resource);
    }

    ResourceType resource_; // could be void*, HANDLE, FILE*, GDIOBJ...
};


// Overload std::swap for AutoResource<T> so that it can work with standard algorithms.
namespace std
{
    template <
        typename ResourceType,          // type of the resource held onto
        typename ResourceTypePolicy,    // policy for acquiring/releasing this resource
        typename BaseResourceType       // type as known by the resource releaser (like HGDIOBJ vs HBITMAP)
        >
    void swap(
        AutoResource<ResourceType, ResourceTypePolicy, BaseResourceType>& lhs,
        AutoResource<ResourceType, ResourceTypePolicy, BaseResourceType>& rhs
        ) throw()
    {
        lhs.swap(rhs);
    }
}


////////////////////////////////////////
// Various handle types

template <
    typename ResourceType,                      // type of the resource held onto
    typename ResourceReleaserSignature,         // function prototype of the releasing function
    ResourceReleaserSignature ResourceReleaser  // address of function to release object
>
struct HandleResourceTypePolicy : public DefaultResourceTypePolicy<ResourceType>
{
    inline static void Release(ResourceType resource) throw()
    {
        if (resource != 0)
        {
            ResourceReleaser(resource);
        }
    }
};


typedef AutoResource<HDC,     HandleResourceTypePolicy<HDC,     BOOL (WINAPI*)(HDC),           &DeleteDC> >                GdiDeviceContext;
typedef AutoResource<HPEN,    HandleResourceTypePolicy<HGDIOBJ, BOOL (WINAPI*)(HGDIOBJ),       &DeleteObject>, HGDIOBJ>    GdiPenHandle;
typedef AutoResource<HFONT,   HandleResourceTypePolicy<HGDIOBJ, BOOL (WINAPI*)(HGDIOBJ),       &DeleteObject>, HGDIOBJ>    GdiFontHandle;
typedef AutoResource<HBITMAP, HandleResourceTypePolicy<HGDIOBJ, BOOL (WINAPI*)(HGDIOBJ),       &DeleteObject>, HGDIOBJ>    GdiBitmapHandle;
typedef AutoResource<HRGN,    HandleResourceTypePolicy<HGDIOBJ, BOOL (WINAPI*)(HGDIOBJ),       &DeleteObject>, HGDIOBJ>    GdiRegionHandle;
typedef AutoResource<HGLOBAL, HandleResourceTypePolicy<HGLOBAL, HGLOBAL (WINAPI*)(HGLOBAL),    &GlobalFree> >              GlobalMemoryResource;
typedef AutoResource<HLOCAL,  HandleResourceTypePolicy<HLOCAL,  HLOCAL (WINAPI*)(HLOCAL),      &LocalFree> >               LocalMemoryResource;
typedef AutoResource<HANDLE,  HandleResourceTypePolicy<HANDLE,  BOOL (WINAPI*)(HANDLE),        &CloseHandle> >             FileHandle;
typedef AutoResource<FILE*,   HandleResourceTypePolicy<FILE*,   int (__cdecl *)(FILE*),        &fclose> >                  CstdioFileHandle;
typedef AutoResource<void*,   HandleResourceTypePolicy<void*,   void (__cdecl *)(void*),       &free> >                    ScopedMemory;
typedef AutoResource<HMODULE, HandleResourceTypePolicy<HMODULE, BOOL (WINAPI*)(HMODULE),       &FreeLibrary> >             ModuleHandle;
typedef AutoResource<HWND,    HandleResourceTypePolicy<HWND,    BOOL (WINAPI*)(HWND),          &DestroyWindow> >           WindowHandle;
typedef AutoResource<void*,   HandleResourceTypePolicy<void*,   BOOL (WINAPI*)(void const*),   &UnmapViewOfFile> >         MemoryViewResource;
typedef AutoResource<HANDLE,  HandleResourceTypePolicy<HANDLE,  BOOL (WINAPI*)(HANDLE),        &CloseHandle> >             MemorySectionResource;


// There are two ways to use resources whose cleanup functions take multiple
// parameters. One is to define your own policy using inheritance. The simpler
// way is to just declare a short free function.
inline void WaitHandleUnregister(HANDLE handle) throw()
{
    UnregisterWaitEx(handle, nullptr); // return value unactionable
}


struct WaitHandleResourcePolicy : public DefaultResourceTypePolicy<HANDLE>
{
    inline static void Free(HANDLE resource) throw()
    {
        if (resource != nullptr)
        {
            UnregisterWaitEx(resource, nullptr); // return value unactionable
        }
    }
};
typedef HandleResourceTypePolicy<HANDLE, void (*)(HANDLE), &WaitHandleUnregister> WaitHandleResourcePolicy2;

typedef AutoResource<HANDLE, WaitHandleResourcePolicy> WaitHandleResource;
typedef AutoResource<HANDLE, WaitHandleResourcePolicy2> WaitHandleResource2;


#ifdef NOT_USED
struct NtHandleResourcePolicy : public DefaultResourceTypePolicy<HANDLE>
{
    inline static void Release(HANDLE resource) throw()
    {
        if (resource != nullptr)
        {
            // NtClose should always succeed.
            NTSTATUS status = NtClose(resource);

            DEBUG_ASSERT(status == STATUS_SUCCESS);
        }
    }
};

typedef AutoResource<HANDLE, NtHandleResourcePolicy> NtHandleResource;
#endif


////////////////////////////////////////
// Basic COM pointer.

struct ComResourceTypePolicy : public DefaultResourceTypePolicy<IUnknown*>
{
    inline static void Acquire(__inout_opt IUnknown* resource) throw()
    {
        if (resource != nullptr)
        {
            resource->AddRef();
        }
    }

    inline static void Release(__inout_opt IUnknown* resource) throw()
    {
        if (resource != nullptr)
        {
            resource->Release();
        }
    }
};


template<typename ResourceType>
class ComPtr : public AutoResource<ResourceType*, ComResourceTypePolicy, IUnknown*>
{
public:
    typedef AutoResource<ResourceType*, ComResourceTypePolicy, IUnknown*> Base;
    typedef ComPtr Self;

    // Necessary forwarders. Although this class adds no data members
    // whatsoever, we still need to forward everything along due to the
    // current lack of template typedefs in C++.

    inline Self() {};
    inline Self(ResourceType* resource) : Base(resource) {}
    // inline Self(Self&& other) : Base(static_cast<Base&&>(other)) {}
    inline Self& operator=(ResourceType* resource) { Set(resource); return *this; }
};


////////////////////////////////////////
// Raw unowned pointer, which is not notably useful, but it can be used as a
// template argument without the caller/container worrying about whether it
// is raw or owned, and the reader is clear that it's a weak pointer.

template<typename ResourceType>
class UnownedMemoryPointer : public AutoResource<ResourceType*, DefaultResourceTypePolicy<void*>, void*>
{
    static_assert(sizeof(ResourceType*) == sizeof(void*), "Expect both pointers have same size, void* and resourceType*");

public:
    typedef AutoResource<ResourceType*, DefaultResourceTypePolicy<void*>, void*> Base;
    typedef UnownedMemoryPointer Self;

    // Necessary forwarders.
    inline Self() {};
    inline Self(ResourceType* resource) : Base(resource) {}
    inline Self& operator=(ResourceType* resource) { Set(resource); return *this; }
};


////////////////////////////////////////
// Scoped object pointer.
// * like auto_ptr, it should be used on the stack or as class members,
//   not a resizable container since it has no ref-count.

template <typename ResourceType>
struct OwnedPointerResourceTypePolicy : public DefaultResourceTypePolicy<ResourceType>
{
    inline static void Release(ResourceType resource) throw()
    {
        if (resource != nullptr)
        {
            delete resource;
        }
    }
};

template<typename ResourceType>
class AutoPointer : public AutoResource<ResourceType*, OwnedPointerResourceTypePolicy<ResourceType*> >
{
public:
    typedef AutoResource<ResourceType*, OwnedPointerResourceTypePolicy<ResourceType*> > Base;
    typedef AutoPointer Self;

    // Necessary forwarders.
    inline Self() {};
    inline Self(ResourceType* resource) : Base(resource) {}
    inline Self& operator=(ResourceType* resource) { Base::Set(resource); return *this; }
    inline ResourceType* Set(ResourceType* resource)  { return Base::Set(resource); }

private:
    // Disallowed. Use Attach or Adopt to transfer from another memory pointer
    // (discourage auto_ptr-like surprises and use in STL containers). This
    // could be allowed again if we add C++0x move semantics.
    inline Self(Self const& other);
    inline ResourceType Set(Self const& other);
};


////////////////////////////////////////
// Scoped raw array.
// * probably better to just use std::vector in most cases.

template <typename ResourceType>
struct OwnedArrayResourceTypePolicy : public DefaultResourceTypePolicy<ResourceType>
{
    inline static void Release(ResourceType resource) throw()
    {
        if (resource != nullptr)
        {
            delete [] resource;
        }
    }
};

template<typename ResourceType>
class AutoArray : public AutoResource<ResourceType*, OwnedArrayResourceTypePolicy<ResourceType*> >
{
public:
    typedef AutoResource<ResourceType*, OwnedArrayResourceTypePolicy<ResourceType*> > Base;
    typedef AutoArray Self;

    // Necessary forwarders.
    inline Self() {};
    inline Self(ResourceType* resource) : Base(resource) {}
    inline Self& operator=(ResourceType* resource) { Base::Set(resource); return *this; }
    inline ResourceType* Set(ResourceType* resource)  { return Base::Set(resource); }

private:
    // Disallowed. Use Attach or Adopt to transfer from another memory pointer
    // (discourage auto_ptr-like surprises and use in STL containers). This
    // could be allowed again if we add C++0x move semantics.
    inline Self(Self const& other);
    inline ResourceType Set(Self const& other);
};
