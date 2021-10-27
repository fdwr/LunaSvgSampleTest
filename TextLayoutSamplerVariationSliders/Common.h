//----------------------------------------------------------------------------
//  Author:     Dwayne Robinson
//  History:    2015-06-19 Created
//----------------------------------------------------------------------------
#pragma once


#ifndef IFR
#define IFR(hrIn) { HRESULT hrOut = (hrIn); if (FAILED(hrOut)) {return hrOut; } }
#endif

#ifndef ISR
#define ISR(hrIn) { HRESULT hrOut = (hrIn); if (SUCCEEDED(hrOut)) {return hrOut; } }
#endif

#ifndef IFRV
#define IFRV(hrIn) { HRESULT hrOut = (hrIn); if (FAILED(hrOut)) {return; } }
#endif

#ifndef RETURN_ON_ZERO // For null, zero, or false
#define RETURN_ON_ZERO(exp, retval) if (!(exp)) {return (retval);}
#endif

bool ThrowIf(bool value, _In_opt_z_ char const* message = nullptr);

#define DEBUG_ASSERT assert

template <typename T, size_t N>
constexpr size_t countof(T(&a)[N])
{
    return N;// _countof(a);
}

template<typename T> void ZeroStructure(T& structure)
{
    memset(&structure, 0, sizeof(T));
}

bool TestBit(void const* memoryBase, uint32_t bitIndex) throw();
bool ClearBit(void* memoryBase, uint32_t bitIndex) throw();
bool SetBit(void* memoryBase, uint32_t bitIndex) throw();

template<typename T>
T* PtrAddByteOffset(T* p, size_t offset)
{
    return reinterpret_cast<T*>(reinterpret_cast<unsigned char*>(p) + offset);
}

template<typename T>
const T* PtrAddByteOffset(const T* p, size_t offset)
{
    return reinterpret_cast<const T*>(reinterpret_cast<const unsigned char*>(p) + offset);
}

template <typename FunctorType>
struct DeferCleanupType
{
public:
    explicit DeferCleanupType(FunctorType f) : f_(f) {}
    ~DeferCleanupType() { f_(); }

private:
    FunctorType f_;
};

template <typename FunctorType>
DeferCleanupType<FunctorType> DeferCleanup(FunctorType f) { return DeferCleanupType<FunctorType>(f); }


// Range of iterators that can be used in a ranged for loop.
template<typename ForwardIteratorType>
class iterator_range
{
public: // types
    using iterator = ForwardIteratorType;
    using const_iterator = ForwardIteratorType;
    using size_type = size_t;

public: // construction, assignment
    template<typename iterator>
    iterator_range(iterator begin, iterator end)
        : begin_(begin), end_(end)
    { }

    template<typename IteratorRangeType>
    iterator_range(const IteratorRangeType& range)
        : begin_(range.begin()), end_(range.end())
    { }

    template<typename IteratorRangeType>
    iterator_range& operator=(const IteratorRangeType& range)
    {
        begin_ = range.begin();
        end_ = range.end();
        return *this;
    }

    iterator const& begin() const
    {
        return begin_;
    }

    iterator const& end() const
    {
        return end_;
    }

    bool equals(const iterator_range& other) const
    {
        return begin_ == other.begin_ && end_ == other.end_;
    }

    bool operator ==(const iterator_range& other) const
    {
        return equals(other);
    }

    bool empty() const
    {
        return begin_ == end_;
    }

    size_type size() const
    {
        return std::distance(begin_, end_);
    }

protected:
    iterator begin_;
    iterator end_;
};


template<typename T>
iterator_range<T> make_iterator_range(T begin, T end)
{
    return iterator_range<T>(begin, end);
}


template<typename T>
iterator_range<T> make_iterator_range(T p, size_t beginIndex, size_t endIndex)
{
    return iterator_range<T>(p + beginIndex, p + endIndex);
}


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
