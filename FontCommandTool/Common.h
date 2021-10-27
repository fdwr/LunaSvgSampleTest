// Include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
#pragma once

////////////////////////////////////////
// Basic application execution functions:

typedef unsigned char char8_t;

////////////////////////////////////////
// Basic application execution functions:

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


template<typename T> class vector;

template<typename T>
class array_ref
{
    // Enable constructors to read other variants, mainly for copy constructors
    // from a non-const to const array_ref.
    template <typename U>
    friend class array_ref;

public:
    // Types
    using value_type = T;
    using pointer = T*;
    using reference = T&;
    using iterator = pointer;
    using const_reference = T const&;
    using const_iterator = T const*;
    using reverse_iterator = std::reverse_iterator<iterator>;
    using const_reverse_iterator = std::reverse_iterator<const_iterator>;
    using size_type = size_t;
    using difference_type = ptrdiff_t;

    // construct/copy
    array_ref() = default;
    array_ref(array_ref const& other) = default;
    //array_ref(reference item) : begin_(&item), end_(begin_ + sizeof(T)) {}
    array_ref(pointer array, size_t length) : begin_(array), end_(array + length) {}
    array_ref(pointer begin, pointer end) : begin_(begin), end_(end) {}
    template<typename U> array_ref(array_ref<U> const& other) : begin_(other.begin_), end_(other.end_) {}
    template<size_t N> array_ref(const T(&a)[N]) : begin_(&a[0]), end_(begin_ + N) {}

    // Otherwise try to construct from a standard container like std::vector, std::string, std::array.
    // The const_cast is unfortunate, due to std::basic_string missing the non-const version of data()
    // like std::vector and std::array do. So, leaving until the issue is fixed.
    // http://www.open-std.org/jtc1/sc22/wg21/docs/lwg-active.html#2391
    template<typename V> array_ref(V& v)                        : begin_(const_cast<T*>(v.data())), end_(begin_ + v.size()) {}
    template<typename V> array_ref(V const& v)                  : begin_(v.data()), end_(begin_ + v.size()) {}

    template<typename U> array_ref& operator=(array_ref<U> const& other) { begin_ = other.begin_; end_ = other.end_; return *this; }

    // Most useful for recasting any array_ref into an uint8_t array.
    // Note you should use this with the same judiciousness as reinterpret_cast.
    template<typename V> static array_ref<T> reinterpret(V& v)
    {
        return array_ref<T>(
            reinterpret_cast<T*>(const_cast<V::pointer>(v.data())),
            reinterpret_cast<T*>(const_cast<V::pointer>(v.data() + v.size()))
            );
    }

    template<typename U>
    static array_ref<T> wrap(U& u)
    {
        array_ref<U> singleElementArray(std::addressof(u), std::addressof(u) + 1);
        return reinterpret(singleElementArray);
    }

    //template<typename V> static array_ref<T> reinterpret(V const& v)
    //{
    //    return array_ref<T>(
    //        reinterpret_cast<T*>(v.data()),
    //        reinterpret_cast<T*>(v.data() + v.size())
    //        );
    //}

    // Iterators
    iterator begin()                       { return begin_; }
    iterator end()                         { return end_; }
    const_iterator cbegin() const          { return begin_; }
    const_iterator cend() const            { return end_; };
    reverse_iterator rbegin()              { return reverse_iterator(begin_); }
    reverse_iterator rend()                { return reverse_iterator(end_); }
    const_reverse_iterator crbegin() const { return const_reverse_iterator(begin_); }
    const_reverse_iterator crend() const   { return const_reverse_iterator(end_); }

    // Capacity
    size_type size() const      { return end_ - begin_; };
    size_type max_size() const  { return size_t / sizeof(T); }
    bool empty() const          { return begin_ == end_; }

    // Element access
    T& operator[](size_t i)             { return begin_[i]; }
    T const& operator[](size_t i) const { return begin_[i]; }
    T& front()                          { return *begin_; }
    T const& front() const              { return *begin_; }
    T& back()                           { return *(end_ - 1); }
    T const& back() const               { return *(end_ - 1); }
    T* data()                           { return begin_; }
    T const* data() const               { return begin_; }

    // Outgoing conversion operators
    // explicit operator vector<T>() const ;
    // template<typename traits, typename Allocator>
    // explicit operator basic_string< T, traits, Allocator >() const ;

    // Mutators
    void clear()                    { begin_ = end_ = nullptr; }
    void remove_prefix(size_type n) { begin_ += n; assert(begin_ <= end_); }
    void remove_suffix(size_type n) { end_   -= n; assert(begin_ <= end_); };
    void pop_back()                 { --end_;   assert(begin_ <= end_); }
    void pop_front()                { ++begin_; assert(begin_ <= end_); }

protected:
    pointer begin_ = nullptr;
    pointer end_ = nullptr;
};


using byte_array_ref = array_ref<uint8_t>;
using const_byte_array_ref = array_ref<uint8_t const>;

#if 0
template<typename T>
byte_array_ref wrap_byte_array_ref(T& t)
{
    return array_ref<T>(std::addressof(T), std::addressof(T) + sizeof(T))
}

template<typename T, typename V>
array_ref<T> make_array_ref(V& v)
{
    return array_ref<T>(v.data(), std::addressof(T) + sizeof(T))
}
#endif


// Range of iterators that can be used in a ranged for loop.
template<typename ForwardIteratorType>
class iterator_range
{
public: // types
    typedef ForwardIteratorType iterator;
    typedef ForwardIteratorType const_iterator;
    typedef size_t size_type;

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


struct Range
{
    uint32_t begin;         // first position
    uint32_t end;           // one-past last 

    typedef uint32_t iterator;

    Range(uint32_t initialBegin, uint32_t initialEnd)
    :   begin(initialBegin),
        end(initialEnd)
    { }

    Range()
    :   begin(0),
        end(UINT32_MAX)
    { }

    static Range FromCount(uint32_t initialBegin, uint32_t initialCount) throw()
    {
        return Range(initialBegin, initialBegin + initialCount);
    }

    uint32_t GetCount() const throw()
    {
        // Empty ranges are clamped to zero.
        return IsEmpty() ? 0 : end - begin;
    }

    void SetCount(uint32_t count) throw()
    {
        end = begin + count; // no overflow check
    }

    uint32_t size() const throw()
    {
        return GetCount();
    }

    void clear() throw()
    {
        begin = end = 0;
    }

    bool IsEmpty() const throw()
    {
        return end <= begin;
    }

    bool empty() const throw()
    {
        return IsEmpty();
    }

    bool IsWellOrdered() const throw()
    {
        return end >= begin;
    }

    void MakeWellOrdered() throw()
    {
        if (!IsWellOrdered())
            std::swap(begin, end);
    }

    void ClampToLowValue(uint32_t lowValue) throw()
    {
        if (begin < lowValue)  begin = lowValue;
        if (end   < lowValue)  end   = lowValue;
    }

    void ClampToHighValue(uint32_t highValue) throw()
    {
        if (begin > highValue) begin = highValue;
        if (end   > highValue) end   = highValue;
    }

    bool ContainsInclusive(uint32_t value) const throw()
    {
        return value >= begin && value <= end;
    }

    bool IsWithin(uint32_t beginLimit, uint32_t endLimit) const throw()
    {
        return begin >= beginLimit && end <= endLimit;
    }

    bool IsWithin(const Range& range) const throw()
    {
        return IsWithin(range.begin, range.end);
    }

    static Range Intersect(const Range& left, const Range& right) throw()
    {
        // * Returns inverted empty ranges if the ranges do not overlap.
        return Range(left).Intersect(right);
    }

    Range& Intersect(const Range& right) throw()
    {
        begin = std::max(begin, right.begin);
        end   = std::min(end,   right.end);

        return *this;
    }

    Range& operator+=(uint32_t offset) throw()
    {
        begin += offset;
        end   += offset;
        return *this;
    }

    Range& OffsetAndIntersect(const Range& right) throw()
    {
        operator+=(right.begin);
        Intersect(right);
        return *this;
    }

    static Range Union(const Range& left, const Range& right) throw()
    {
        return Range(left).Union(right);
    }

    Range& Union(const Range& right) throw()
    {
        begin = std::min(begin, right.begin);
        end   = std::max(end,   right.end);

        return *this;
    }
};

inline bool operator ==(Range const& lhs, Range const& rhs) throw()
{
    return lhs.begin == rhs.begin && lhs.end == rhs.end;
}

inline bool operator !=(Range const& lhs, Range const& rhs) throw()
{
    return !(lhs == rhs);
}


template <typename T>
void ShiftDataUp(byte_array_ref bytes, size_t startingIndex, size_t count)
{
    // Similar to an insert operation in a std::vector.
    size_t bytesShifted = count * sizeof(T);
    uint8_t* source     = &bytes[startingIndex * sizeof(T)];
    uint8_t* dest       = &bytes[startingIndex * sizeof(T) + bytesShifted];
    uint8_t* end        = bytes.end();

    if (dest < end) // Clamp if the count is greater than the array window.
    {
        memmove(dest, source, size_t(end - dest));
        // memset(source, 0, bytesShifted);
    }
}


template <typename T>
void ShiftDataDown(byte_array_ref bytes, size_t startingIndex, size_t count)
{
    // Similar to an erase operation in a std::vector.
    size_t bytesShifted = count * sizeof(T);
    uint8_t* dest       = &bytes[startingIndex * sizeof(T)];
    uint8_t* source     = &bytes[startingIndex * sizeof(T) + bytesShifted];
    uint8_t* end        = bytes.end();

    if (source < end) // Clamp if the count is greater than the array window.
    {
        memmove(dest, source, size_t(end - source));
    }
}


template <typename T>
void MemMove(T& dest, T const& source)
{
    memmove(&dest, &source, sizeof(T));
}

template <typename T>
void MemMoveCount(T* dest, T const* source, size_t count)
{
    size_t byteSize = count * sizeof(T);
    if (byteSize >= count)
    {
        memmove(dest, source, byteSize);
    }
}


// Format into a std::string rather than raw character buffer or ios stream.
void GetFormattedString(OUT std::wstring& returnString, const wchar_t* formatString, ...);
void AppendFormattedString(IN OUT std::wstring& returnString, const wchar_t* formatString, ...);


HRESULT CopyToClipboard(const std::wstring& text);
HRESULT PasteFromClipboard(OUT std::wstring& text);


void TrimSpaces(IN OUT std::wstring& text);
void GetCommandLineArguments(_Inout_ std::wstring& commandLine);
void ConvertText(array_ref<char const> utf8text, OUT std::wstring& char16text);
void ConvertText(array_ref<wchar_t const> char16text, OUT std::vector<char>& utf8text);
