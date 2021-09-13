#pragma once


/// <summary>
/// Vector allocator that can alias an existing fixed-size
/// array yet grow on demand.
/// </summary>
template<typename T, typename S = size_t>
class FixedVectorAllocator : private NonCopyable
{
public:
    typedef T value_type;
    typedef S size_type;

    typedef value_type*         pointer;
    typedef const value_type*   const_pointer;
    typedef size_type           difference_type;
    typedef value_type&         reference;
    typedef const value_type&   const_reference;

private:
    __ecount(bufferCount_) pointer buffer_;
    size_type bufferCount_;

public:

    // Constructors/Destructors

    // No default constructor. Must initialize buffer and count.
    // No explicit destructor, since the container's destructor will call deallocate().

    inline explicit FixedVectorAllocator(pointer buffer, size_type bufferCount) throw()
        :   buffer_(buffer),
            bufferCount_(bufferCount)
    { }

    inline explicit FixedVectorAllocator(const FixedVectorAllocator& other) throw()
        :   buffer_(other.buffer_),
            bufferCount_(other.bufferCount_)
    { }

    template<typename Other>
	FixedVectorAllocator(const FixedVectorAllocator<Other>& other)
        :   buffer_(other.buffer_),
            bufferCount_(other.bufferCount_)
    { }

    // Max count of elements that can be allocated.

    inline size_type max_size() const throw()
    {
        // Return whichever is smaller, the maximum count or
        // maximum number of items allocatable in memory.
        size_t memoryMax = SIZE_MAX / sizeof(T);
        size_t countMax  = std::numeric_limits<size_type>::max();
        return static_cast<size_type>((memoryMax < countMax) ? memoryMax : countMax);
    }

    template<typename U>
    struct rebind
    { 
        typedef FixedVectorAllocator<U> other; 
    };

    // Allocate/Deallocate/Construct/Destroy

    pointer allocate(size_type n, const void* = NULL)
    {
        // Return the static buffer, unless the demand is larger.
        if (n <= bufferCount_)
            return buffer_;
        else
            return static_cast<pointer>( ::operator new(n * sizeof(T)) );
    }
    
    void deallocate(pointer p, size_t n)
    {
        // Delete the pointer, only if it is not our static buffer.
        if (p != buffer_)
            ::operator delete(static_cast<void*>(p));
    }

    // ********************
    // These methods are unused by vector, but best to leave
    // them infor the possibility of other containers or even
    // STL implementation changes.
    // ********************

    void construct(pointer p, const T& t)
    {
        new( static_cast<void*>(p) ) T(t);
    }

    void destroy(pointer p)
    {
        p->~T();
    }

    // Return address of values

    inline pointer address(reference value) const 
    {
        return &value;
    }
    
    inline const_pointer address(const_reference value) const 
    {
        return &value;
    }
};

// No instances of this allocator are interchangeable.

template<typename T1, typename T2>
inline bool operator==( const FixedVectorAllocator<T1>& lhs, const FixedVectorAllocator<T2>& rhs)
{ 
    return false;
}

template<typename T1, typename T2>
inline bool operator!=( const FixedVectorAllocator<T1>& lhs, const FixedVectorAllocator<T2>& rhs)
{ 
    return !(lhs == rhs);
}


/// <summary>
/// A vector optimized for small, short-lived buffers, where a good estimate is
/// known ahead of time but sometimes exceeded. Allocations of up to N elements
/// are satisified using a fixed-size array.
///
/// It can also be useful for basic_string, but gains nothing for node-based
/// containers like std::list.
/// </summary>
template<class T, uint32_t N>
class FixedVector : public std::vector<T, FixedVectorAllocator<T, uint32_t> >
{
    COMPILE_ASSERT(N > 0);

private:
    T buffer_[N];
public:
    FixedVector() : vector(FixedVectorAllocator<T, uint32_t>(buffer_, N))
    {
        // Make sure the first allocation makes full use of the fixed buffer.
        reserve(N);
    }

private:
    // Disallow swapping
    void swap(FixedVector& other)
    {  }
};


template<uint32_t N>
class FixedString : public std::basic_string<wchar_t, std::char_traits<wchar_t>, FixedVectorAllocator<wchar_t, uint32_t> >
{
    COMPILE_ASSERT(N > 0);

private:
    wchar_t buffer_[N];
public:
    FixedString() : vector(FixedVectorAllocator<wchar_t, uint32_t>(buffer_, N))
    {
        // Make sure the first allocation makes full use of the fixed buffer.
        reserve(N);
    }

private:
    // Disallow swapping
    void swap(FixedString& other)
    {  }
};
