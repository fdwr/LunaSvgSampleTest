#pragma once

#include <exception>    // for std::bad_alloc
#include <new>          // for placement new

/// Summary:
///     Factored base for variable size array of complex items.
///     This contains little behavior, and mostly consists of the
///     shared fields and a few helpers to reallocate memory.
///
///     This class only has little knowledge of the memory implementation
///     at higher levels (which could utilize a fixed size buffer),
///     nor does it know the data type. This reduces template bloat.
///     It does require the memory to have been allocated using malloc
///     for the sake of resizability.
///
class AutoVectorBase
{
protected:
    void* pointer_;
    size_t size_;
    size_t capacity_;

    template <typename Type, bool useRaw>
    friend class AutoVectorInitializer;

protected:
    // Initializes to an empty (NULL) state.
    AutoVectorBase() throw()
    :   pointer_(),
        size_(),
        capacity_()
    {
    }

    AutoVectorBase(void* pointer, size_t size, size_t capacity) throw()
    :   pointer_(pointer),
        size_(size),
        capacity_(capacity)
    {
    }

private:
    // Disallow for now. Maybe there is use for it,
    // but it adds complexity I don't want to think about : )
    AutoVectorBase(const AutoVectorBase& other)
    {
        other; // for the nonsensical "unused parameter" warning.
    }

public:
    // Get the size of the memory block (number of elements).
    inline size_t GetSize() const throw()
    {
        return size_;
    }

    inline size_t size() const throw() // STL form
    {
        return GetSize();
    }

protected:
    void ReserveCapacity(
        size_t newCapacity,
        size_t sizeOfType,
        size_t maxCapacity
        )
    {
        if (newCapacity <= capacity_)
        {
            return; // nothing to do
        }

        if (newCapacity > maxCapacity)
        {
            throw std::bad_alloc(); // allocating more memory than possible
        }

        // Calculate the next growth step. Either jump straight to the new
        // size if large enough, or grow in increments to reduce reallocations.

        // * Ignore any overflow in the size * 2, since it doesn't matter.
        //   We'll still choose the larger of the two.
        size_t amortizedCapacity = std::max(newCapacity, (size_ * 2) + 8);
        if (amortizedCapacity < maxCapacity)
        {
            newCapacity = amortizedCapacity;
        }

        void* newPointer = realloc(pointer_, newCapacity * sizeOfType);
        if (newPointer == NULL)
        {
            throw std::bad_alloc();
        }

        // Assign the new block, but do not modify the current size (only capacity).
        pointer_  = newPointer;
        capacity_ = newCapacity;
    }

    void AllocateCapacity(
        size_t newCapacity,
        size_t sizeOfType,
        size_t maxCapacity,
        void* initialBytes
        )
    {
        // Note this replaces the value of pointer_, whatever it may equal.

        if (newCapacity > maxCapacity)
        {
            throw std::bad_alloc(); // allocating more memory than possible
        }

        // Allocate a block for the memory.
        // Note that if the size of the space requested is 0,
        // the malloc behavior is implementation-defined,
        // returning either a null pointer or a unique pointer.
        // So we also check that newCapacity was > 0 in addition
        // to checking for null before throwing. On VC2008,
        // calling malloc with 0 bytes yields a non-null pointer,
        // but calling realloc with 0 bytes yields null.
        void* newPointer = malloc(newCapacity * sizeOfType);
        if (newPointer == NULL && newCapacity > 0)
        {
            throw std::bad_alloc();
        }

        // Copy from the source to the heap (the source may be a local
        // fixed size heap or a buffer from the application).
        memcpy(newPointer, initialBytes, size_ * sizeOfType);

        pointer_  = newPointer;
        capacity_ = newCapacity;
    }

    void ShrinkCapacityToSize(size_t sizeOfType)
    {
        DWRITEX_ASSERT(capacity_ >= size_); // must have already been increased

        // Shrink the capacity to the actual size occupied.
        // This will reduce the memory block size.

        // * Can't overflow, since since we never had more than
        //   SIZE_MAX bytes in the first place.

        void* newPointer = realloc(pointer_, size_ * sizeOfType);
        if (newPointer == NULL && size_ > 0)
        {
            throw std::bad_alloc();
        }

        pointer_  = newPointer;
        capacity_ = size_;
    }

    void* Detach() throw()
    {
        void* p     = pointer_;
        pointer_    = NULL;
        size_       = 0;
        capacity_   = 0;
        return p;
    }
};


/// Summary:
///     The AutoVector allocator manages memory for the vector,
///     whether it be on the heap or in a fixed buffer. If the
///     stack size > 0, the fixed size buffer will be used until
///     it is exceeded. If = 0, only the heap will be used.
///
///     This class only has knowledge of the memory implementation, not of the
///     data type. This allows factoring and reduces template bloat. Because it
///     is unaware of the type, you would not would not call any of these
///     functions directly from an app, such as Clear(). Instead, you would
///     call Clear() on AutoVector, which is aware of the type, to destruct all
///     the elements and then call the allocator Clear() to free memory.
///
template <size_t SizeOfType, size_t StackSize>
class AutoVectorAllocator;


// Pure heap allocator
template <size_t SizeOfType>
class AutoVectorAllocator <SizeOfType, 0> : public AutoVectorBase
{
    // Declares no data members. Purely inherits.

public:
    enum { MaxCapacity = SIZE_MAX / SizeOfType };

protected:
    typedef AutoVectorBase Base;

    AutoVectorAllocator(void* pointer, size_t size, size_t capacity) throw()
    :   Base(pointer, size, capacity)
    { }

    AutoVectorAllocator() throw()
    :   Base(NULL, 0, 0)
    { }

public:
    // Gets the size of the memory block in bytes.
    inline size_t GetSizeInBytes() const throw()
    {
        // * Can't overflow because we never allocated more than
        //   SIZE_MAX bytes in the first place.
        return size_ * SizeOfType;
    }

    void ReserveCapacity(size_t newCapacity)
    {
        Base::ReserveCapacity(newCapacity, SizeOfType, MaxCapacity);
    }

    void ShrinkCapacityToSize()
    {
        Base::ShrinkCapacityToSize(SizeOfType);
    }

protected:
    void Clear() throw()
    {
        free(pointer_);
        pointer_    = NULL;
        size_       = 0;
        capacity_   = 0;
    }

    // Detach() - just use base class
};


// Stack allocator.
template <size_t SizeOfType, size_t StackSize>
class AutoVectorAllocator <SizeOfType, StackSize>: public AutoVectorBase
{
    // Fixed size stack space (can also be a class member).
    // Set to a reasonable size for the expected data quantity
    // to avoid heap allocations.
    uint8_t stackBuffer_[StackSize * SizeOfType];

public:
    enum { MaxCapacity = ~size_t(0) / SizeOfType };

protected:
    typedef AutoVectorBase Base;

    AutoVectorAllocator(void* pointer, size_t size, size_t capacity) throw()
    :   Base(pointer, size, capacity)
    { }

    AutoVectorAllocator() throw()
    :   Base(stackBuffer_, 0, StackSize)
    { }

public:
    // Gets the size of the memory block in bytes.
    inline size_t GetSizeInBytes() const throw()
    {
        // * Can't overflow because we never allocated more than
        //   SIZE_MAX bytes in the first place.
        return size_ * SizeOfType;
    }

    void ReserveCapacity(size_t newCapacity)
    {
        if (newCapacity <= capacity_)
            return; // already large enough
       
        if (pointer_ == stackBuffer_)
        {
            // Grown beyond the fixed buffer.
            Base::AllocateCapacity(newCapacity, SizeOfType, MaxCapacity, stackBuffer_);
        }
        else
        {
            Base::ReserveCapacity(newCapacity, SizeOfType, MaxCapacity);
        }
    }

    void ShrinkCapacityToSize()
    {
        if (pointer_ != stackBuffer_)
        {
            Base::ShrinkCapacityToSize(SizeOfType);
        }
        // Else we are still pointing the stack, so just leave capacity intact.
    }

protected:
    void Clear() throw()
    {
        // Free any allocated memory, and
        // reset to the stack buffer.
        if (pointer_ != stackBuffer_)
        {
            free(pointer_);
        }

        pointer_    = stackBuffer_;
        size_       = 0;
        capacity_   = StackSize;
    }

    void* Detach()
    {
        if (pointer_ == stackBuffer_)
        {
            // Create a memory block (since we can't point to the fixed size
            // buffer), and copy the contents into it.
            Base::AllocateCapacity(size_, SizeOfType, MaxCapacity, stackBuffer_);
        }
        return Base::Detach();
    }
};


/// Summary:
///     The AutoVector initializer constructs/destructs elements.
///     The raw form is mostly a no-op. The complex one calls the
///     default constructor. You may use complex one for PODs,
///     but should not use the raw one for complex classes
///     (unless you like uninitialized garbage).
///
///     This class only has knowledge of the data type, none of
///     memory implementation.
///
template <typename Type, bool useRaw>
class AutoVectorInitializer;


// Raw buffer
template <typename Type>
class AutoVectorInitializer <Type, true>
{
public:
    // ** Consider using __is_pod() to test the type.

    static inline void Construct(void* elementAddress)
    {
        // Do nothing. Leave it raw.
    }

    static inline void Destruct(Type* elementAddress)
    {
        // Do nothing. Leave it raw.
    }

    static void GrowTail(__inout AutoVectorBase& vector, size_t newSize)
    {
        // Grows the tail of the vector, simply setting the new size. No initialization.

        DWRITEX_ASSERT(vector.capacity_ >= newSize); // must have already been increased

        vector.size_ = newSize;
        return;
    }

    static void TrimTail(__inout AutoVectorBase& vector, size_t newSize)
    {
        // Trims the tail of the vector, simply settting the new size. No finalization.

        DWRITEX_ASSERT(vector.capacity_ >= vector.size_);

        vector.size_ = newSize;
        return;
    }
};


// Complex buffer
template <typename Type>
class AutoVectorInitializer <Type, false>
{
public:
    static inline void Construct(void* elementAddress)
    {
        new(elementAddress) Type();
    }

    static inline void Destruct(Type* elementAddress)
    {
        elementAddress->~Type();
    }

    static void GrowTail(__inout AutoVectorBase& vector, size_t newSize)
    {
        // Grows the tail of the vector, constructing all the new elements.
        // Whether it's on the stack or heap does not matter.

        DWRITEX_ASSERT(vector.capacity_ >= newSize); // must have already been increased

        __ecount(vector.size_) Type* p = static_cast<Type*>(vector.pointer_);

        while (vector.size_ < newSize)
        {
            new(p + vector.size_) Type();
            ++vector.size_;
        }
    }

    static void TrimTail(__inout AutoVectorBase& vector, size_t newSize)
    {
        // Trims the tail of the vector, destructing all the old elements.
        // Whether it's on the stack or heap does not matter.

        DWRITEX_ASSERT(vector.capacity_ >= vector.size_);

        __ecount(size_) Type* p = static_cast<Type*>(vector.pointer_);

        while (vector.size_ > newSize)
        {
            --vector.size_;
            p[vector.size_].~Type();
        }
    }
};


#pragma warning(push)
#pragma warning(disable:4345)   // Yes, we're quite aware that POD's are default initialized.

/// <summary>
/// AutoVector - Variable size array of items, supporting fixed size stack
/// allocation with heap allocation on demand, either POD or complex items.
/// This is a pleasant hybrid between raw arrays (very fast), malloc'd
/// memory (no initialization needed), and STL vectors (type safety and
/// flexibility). Note a vector with custom allocator could also accomplish
/// the fixed sized stack aspect, but not be able to avoid unnecessary
/// initialization, nor supply the memmove optimization upon insertion,
/// which game libraries make use of.
///
/// Pros/cons of stack arrays:
///   + Avoids heap allocation for the common case (given heuristic size)
///   + Avoids initialization when not needed (just overwritten later)
///   + Automatically cleans up memory (the stack just unwinds)
///   + Uses recently touched memory (data locality)
///   - Need separate counter variable for current subsize
///   - Can't be resized greater than maximum
///   - Greater buffer overflow potential
///
/// Pros/cons of raw malloc:
///   + Avoids initialization when not needed (just overwritten later)
///   + Can easily resize actual byte capacity
///   - Little type safety, requiring casting and size calculations
///   - Complex types are not easily stored without extra work
///   - More prone to leaks (if not used with smart pointer)
///   - Always allocates on the heap
///
/// Pros/cons of STL vector:
///   + Can grow to any size (in memory limits)
///   + Properly initializes/finalizes complex types
///   + Automatically cleans up memory (the stack just unwinds)
///   + Direct compatibility with the STL algorithms
///   + Useful insertion/erasure/push/pop methods
///   - Always allocates on the heap (even for small sizes)
///   - Never reduces byte capacity (short of stupid swap trick)
///   - Always initializes (even if simply overwritten later)
///   - Depends on copy construction that permits auto_ptr mistakes
///   - Does not optimize memory moves for relocatable classes
///     (insertion/erasure uses copy/copy_backwards)
///
/// Auto-vector:
///   + Avoids heap allocation for the common case (given heuristic size)
///   + Can grow to any size (in memory limits)
///   + Automatically cleans up memory (the stack just unwinds)
///   + Uses recently touched memory (data locality)
///   + Avoids initialization when not needed (just overwritten later)
///   + Properly initializes/finalizes complex types
///   + Direct compatibility with the STL algorithms
///   + Optimizes memory moves for relocatable classes
///     (avoiding potentialy heavy copy constructor calls)
///   - Limited insertion/erasure/push/pop methods
///
/// Unnecessary copy construction of elements can be become noticeable
/// when the elements contain heavier objects or reference counted smart
/// pointers (which cause a cascade of AddRef/Release virtual calls that
/// traipse through distant memory). Even C++0x move semantics do not avoid
/// this. Implementations may optimize for simple POD types to use memmove,
/// but where this optimization matters most is exactly where it is avoided,
/// those complex types which have trivial relocatability but nontrivial
/// destruction/construction. Too bad C++ lacks the type_trait for such
/// (like EASTL's has_trivial_relocatability).
///
/// Note this also means you can safely store any smart pointers inside this
/// container without issue - even auto_ptr works right! The STL vector will,
/// much to one's initial surprise, potentially free all your objects. This
/// avoids the need for additional levels of indirection or ref-counted shared
/// pointers. Now, beware that calling STL algorithms, such as sort, on this
/// container is still unwise for the same reason as the vector, as these
/// algorithms may create temporary copies that transfer ownership to nowhere.
/// </summary>

template <typename Type, size_t StackSize = 16, bool useRawBuffers = false>
class AutoVector : public AutoVectorAllocator<sizeof(Type), StackSize>
{
public:
    typedef AutoVectorInitializer<Type, useRawBuffers> TypeInitializer;
    typedef AutoVectorAllocator<sizeof(Type), StackSize> TypeAllocator;
    typedef TypeAllocator Base;

    typedef Type* pointer;
    typedef const Type* const_pointer;
    typedef Type& reference;
    typedef const Type& const_reference;
    typedef pointer iterator;
    typedef const_pointer const_iterator;

    // Initializes to an empty (NULL) state.
    AutoVector() throw()
    { }

    // Initializes to an array of the specified size.
    explicit AutoVector(size_t size)
    {
        Resize(size);
    }

    // Initializes using an existing pointer which *must* have been allocated
    // using malloc or realloc. It assumes the elements have already been
    // constructed (unless using raw buffers).
    AutoVector(__ecount(size) Type* pointer, size_t size) throw()
    :   Base(pointer, size, size),
    { }

    ~AutoVector() throw()
    {
        Clear();
    }

    // Destroys elements and free memory (if any was allocated).
    void Clear()
    {
        TypeInitializer::TrimTail(*this, 0);
        TypeAllocator::Clear();
    }

    inline void clear() // STL compatible version.
    {
        Clear();
    }

    // Transfer ownership of the memory block to the caller and reset the
    // AutoVector array to NULL. The caller becomes responsible for later
    // destructing any elements.
    inline Type* Detach()
    {
        return static_cast<Type*>(TypeAllocator::Detach());
    }

    // Takes ownership of an array, which *must* have been allocated using
    // malloc/realloc. It assumes elements have already been constructed
    // (unless using raw buffers), such as being transferred from another
    // AutoVector.
    void Attach(__ecount(size) Type* pointer, size_t newSize)
    {
        // Clear previous elements.
        Clear();

        pointer_        = pointer;
        size_           = newSize;
        capacity_       = newSize;
        __analysis_assume(size_ == newSize);
    }

    // Get a pointer to the memory block.
    inline __ecount(this->size_) Type* GetData() const throw()
    {
        return static_cast<Type*>(pointer_);
    }

    inline __ecount(this->size_) Type* data() const throw() // STL form
    {
        return GetData();
    }

    // For passing type as a function parameter or use with []
    __ecount(this->size_) operator Type*() const throw()
    {
        return GetData();
    }

    iterator begin() const throw()
    {
        return static_cast<Type*>(pointer_);
    }

    iterator end() const throw()
    {
        return static_cast<Type*>(pointer_) + size_;
    }

    reference front() const throw()
    {
        return *begin();
    }

    reference back() const throw()
    {
        return *end();;
    }

    inline void reserve(size_t newCapacity) // STL form
    {
        TypeAllocator::ReserveCapacity(newCapacity);
    }

    inline void shrink_to_fit() // STL form
    {
        TypeAllocator::ShrinkCapacityToSize();
    }

    // Resizes the block, constructing/destructing any elements at the tail.
    // This may change the pointer, size, and capacity. Note this does not
    // reduce the capacity if the number of elements is less. You must then
    // later call ShrinkCapacityToSize.
    void Resize(size_t newSize)
    {
        if (newSize < size_)
        {
            // Destroy any elements beyond the new size.   
            // * No need to reallocate, regardless of whether we are
            //   using the stack buffer or an allocated one, since we
            //   know the capacity to be larger than the size.
            TypeInitializer::TrimTail(*this, newSize);
        }
        else if (newSize > size_)
        {
            // Increase capacity and create any elements behind the new size.
            TypeAllocator::ReserveCapacity(newSize);
            TypeInitializer::GrowTail(*this, newSize);
        }
    }

    void resize(size_t newSize) // STL form
    {
        Resize(newSize);
    }

    bool IsEmpty() const throw()
    {
        return size_ == 0;
    }

    bool empty() const throw()
    {
        return IsEmpty();
    }

    void push_back(const Type& newObject)
    {
        // Increase capacity by one, copy object, and increase size.

        TypeAllocator::ReserveCapacity(size_ + 1);
        GetData()[size_] = newObject;
        ++size_;
    }

    void pop_back()
    {
        --size_;
        TypeInitializer::Destruct(&GetData()[size_]);
    }

    void Insert(size_t index)
    {
        // Inserts a default element at the given position.

        DWRITEX_ASSERT(index < size_);

        // Increase capacity by one.
        // * It's not necessary to check for integer overflow here,
        //   since the only data type that could overflow is uint8_t,
        //   and only if all of memory could be allocated, which can
        //   never happen since there must be at least some address
        //   space already mapped in for this code to even execute.
        TypeAllocator::ReserveCapacity(size_ + 1);

        // Initialize object on the stack (using default initialization),
        // to avoid the cost of an exception, which would require try/catch,
        // destruction of the object, and unshifting everything back.
        // If an exception occurs during construction, the constructor just
        // undoes any partially constructed elements, and we propagate the
        // exception up. The AutoVector state is intact.

        uint8_t stackObject[sizeof(Type)];
        TypeInitializer::Construct(&stackObject);

        Type* insertedElement   = &GetData()[index];
        size_t tailSizeInBytes  = (size_ - index) * sizeof(Type);

        // Shift everything over one and increase size.
        memmove(insertedElement + 1, insertedElement, tailSizeInBytes);
        ++size_;

        // Place the new object. The stackObject[] goes out of scope after
        // this, but no destructor is called because it was transferred
        // to the array.
        memcpy(insertedElement, stackObject, sizeof(Type));
    }

    void Erase(size_t index)
    {
        DWRITEX_ASSERT(index < size_);

        Type* erasedElement     = &GetData()[index];
        size_t tailSizeInBytes  = (size_ - index - 1) * sizeof(Type);

        // Destruct the single object, shift everything down one,
        // and decrement size.
        TypeInitializer::Destruct(erasedElement);

        memmove(erasedElement, erasedElement + 1, tailSizeInBytes);

        --size_;
    }
};
#pragma warning(pop)

extern void AutoVectorUnitTests();
