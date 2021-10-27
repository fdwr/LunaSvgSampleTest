//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2006. All rights reserved.
//
//  File:       CheckedPtr.h
//
//  Contents:   Pointer with associated count for bounds checking.
//
//  Author:     Niklas Borson (niklasb@microsoft.com)
//
//  History:    08-08-2006   niklasb    Created
//
//----------------------------------------------------------------------------

#pragma once


/// <summary>
/// CheckedPtr is a pointer with associated count for bounds checking. This is
/// not a container, as no ownership is implied.
/// </summary>
template<typename T, typename FailT, typename S = uint32_t>
class CheckedPtr
{
public:
    typedef T value_type;
    typedef CheckedPtr<T,FailT,S> Self;
    typedef FailT FailurePolicy;
    typedef S SizeType;


    /// <summary>
    /// Create a null CheckedPtr.
    /// </summary>
    CheckedPtr() throw()
    :   p_(nullptr),
        count_(0)
    {
    }


    /// <summary>
    /// Create a CheckedPtr from a pointer and count.
    /// </summary>
    CheckedPtr(__in_ecount(count) T* p, SizeType count) throw()
    :   p_(p),
        count_(count)
    {
    }

    /// <summary>
    /// Create a CheckedPtr from a raw buffer. The template parameter U must be void or void const,
    /// otherwise a compile-time error results.
    /// </summary>
    template <typename U>
    static Self CreateFromBuffer(__in_bcount(count) U* p, SizeType count) throw()
    {
        // We want to give an error if U is not void* or void const*. We know U* can be converted to T* via static_cast
        // otherwise the code below would yield an error. This leaves only void or a type derived from T.
        // The following compile-time assertion rules out the latter.
        //COMPILE_ASSERT_POD(U);

        // No need to do an alignment check because this is used only for types that have no alignment requirements.
        //COMPILE_ASSERT(ALIGNOF(T) == 1);

        return CheckedPtr(static_cast<T*>(p), count / sizeof(T));
    }

    /// <summary>
    /// Conversion constructor for CheckedPtr of different but compatible type.
    /// </summary>
    template<typename T2, typename FailT2> 
    CheckedPtr(CheckedPtr<T2,FailT2,S> const& rhs) throw() : p_(rhs.GetBegin()), count_(rhs.GetCount())
    {
        // The types must not only be assignment compatible, but also of the same size.
        static_assert(sizeof(T2) == sizeof(T), "Types must be the same size.");
    }

    /// <summary>
    /// Returns true if the pointer is null, false if not.
    /// </summary>
    bool IsNull() const throw()
    {
        return p_ == nullptr;
    }


    /// <summary>
    /// Returns the pointer count.
    /// </summary>
    SizeType GetCount() const throw()
    {
        return count_;
    }


    /// <summary>
    /// Returns an unchecked pointer to the beginning of the sequence.
    /// </summary>
    __ecount(this->count_) T* GetBegin() const throw()
    {
        return p_;
    }


    /// <summary>
    /// Returns an unchecked pointer to the beginning of the sequence.
    /// </summary>
    __ecount(*count) T* GetBegin(__out SizeType* count) const throw()
    {
        *count = count_;
        return p_;
    }


    /// <summary>
    /// Returns an unchecked pointer to the end of the sequence.
    /// </summary>
    __ecount(0) T* GetEnd() const throw()
    {
        return p_ + count_;
    }


    /// <summary>
    /// Returns whether a pointer is within the range.
    /// </summary>
    bool Contains(void const* p) const throw()
    {
        return p >= p_
            && p < p_ + count_;
    }


    /// <summary>
    /// Returns a reference to the element at the specified index.
    /// </summary>
    T& operator[](size_t i) const
    {
        if (i >= count_)
        {
            FailOutOfRange();
        }
        return p_[i];
    }


    /// <summary>
    /// Returns a reference to the pointee.
    /// </summary>
    T& operator*() const
    {
        if (count_ == 0)
        {
            FailOutOfRange();
        }
        return *p_;
    }


    /// <summary>
    /// Returns the raw pointer.
    /// </summary>
    __ecount(this->count_) T* operator->() const
    {
        if (count_ == 0)
        {
            FailOutOfRange();
        }
        return p_;
    }

    Self& operator+=(size_t offset)
    {
        if (offset > count_)
        {
            FailOutOfRange();
        }
        p_ += offset;
        count_ -= static_cast<SizeType>(offset);
        return *this;
    }


    /// <summary>
    /// Returns a checked pointer to a range of elements.
    /// </summary>
    Self GetRange(size_t offset, size_t length) const
    {
        if (count_ < offset || count_ - offset < length)
        {
            FailOutOfRange();
        }

        return Self(p_ + offset, static_cast<SizeType>(length));
    }


    /// <summary>
    /// Gets a single value of the specified type at the specified byte offset.
    /// Return false if the read is out of range.
    /// </summary>
    template<typename U>
    bool TryReadAt(size_t offset, __deref_out_bcount(sizeOfU) U const** u, size_t sizeOfU = sizeof(U)) const throw()
    {
        // Bounds check.
        if (count_ < offset || count_ - offset < sizeOfU)
        {
            *u = nullptr;
            return false;
        }

        // This must be a checked pointer to uint8_t.
        uint8_t const* p = p_ + offset;

        // Alignment check. We do this on the pointer rather than the offset in case the original pointer
        // used to construct the CheckedPtr does not meet the alignment requirements of U.
        if (reinterpret_cast<size_t>(p) % ALIGNOF(U) != 0)
        {
            *u = nullptr;
            return false;
        }

        // The type we're casting to must be a POD (plain-old-data) type.
        //COMPILE_ASSERT_POD(U);
        *u = reinterpret_cast<U const*>(p);
        return true;
    }

    /// <summary>
    /// Gets a single value of the specified type at the specified byte offset.
    /// The annotation should have been __out_bcount, but Prefast doesn't handle this with templates yet.
    /// </summary>
    template<class U>
    /*__xcount(sizeOfU)*/ U const& ReadAt(size_t offset, size_t sizeOfU = sizeof(U)) const
    {
        U const* u;
        if (!TryReadAt(offset, &u, sizeOfU))
        {
            FailOutOfRange();
        }

        return *u;
    }

    /// <summary>
    /// Similar to ReadAt except that the type is returned by value instead of by reference, and
    /// is not required to be aligned in the buffer.
    /// </summary>
    template<class U>
    U ReadValueAt(size_t offset) const
    {
        U result;
        memcpy(&result, ReadArrayAt<uint8_t>(offset, sizeof(U)), sizeof(U));
        return result;
    }

    /// <summary>
    /// Gets a pointer to an array of values of the specified type at the specified
    /// byte offset.
    /// </summary>
    // The annotation should have been elemReadableTo, but Prefast doesn't understand template parameters yet.
    template<typename U> 
    bool TryReadArrayAt(size_t offset, __deref_out_ecount(count) U const** u, size_t count) const throw()
    {
        // We use division instead of multiplication below to avoid potential for
        // arithmetic overflow.
        if (count_ < offset || (count_ - offset) / sizeof(U) < count)
        {
            *u = nullptr;
            return false;
        }

        // This must be a checked pointer to uint8_t.
        uint8_t const* p = p_ + offset;

        // Alignment check. We do this on the pointer rather than the offset in case the original pointer
        // used to construct the CheckedPtr does not meet the alignment requirements of U.
        if (reinterpret_cast<size_t>(p) % ALIGNOF(U) != 0)
        {
            *u = nullptr;
            return false;
        }

        // The type we're casting to must be a POD (plain-old-data) type.
        //COMPILE_ASSERT_POD(U);
        *u = reinterpret_cast<U const*>(p);
        return true;
    }


    /// <summary>
    /// Gets a pointer to an array of values of the specified type at the specified
    /// byte offset.
    /// </summary>
    // The annotation should have been elemReadableTo, but Prefast doesn't understand template parameters yet.
    template<typename U> __xcount(count) U const* ReadArrayAt(size_t offset, size_t count) const
    {
        U const* u;
        if (!TryReadArrayAt(offset, &u, count))
        {
            FailOutOfRange();
        }

        return u;
    }


    /// <summary>
    /// Non-const version of ReadArrayAt.
    /// </summary>
    template<typename U> __xcount(count) U* GetArrayAt(size_t offset, size_t count) const
    {
        if (count_ < offset || (count_ - offset) / sizeof(U) < count)
        {
            FailOutOfRange();
        }

        uint8_t* p = p_ + offset;

        // Alignment check. We do this on the pointer rather than the offset in case the original pointer
        // used to construct the CheckedPtr does not meet the alignment requirements of U.
        if (reinterpret_cast<size_t>(p) % ALIGNOF(U) != 0)
        {
            FailOutOfRange();
        }
        //COMPILE_ASSERT_POD(U);
        return reinterpret_cast<U*>(p);
    }


    /// <summary>
    /// Report bounds violation according to the failure policy of the checked pointer.
    /// </summary>
    DECLSPEC_NORETURN void FailOutOfRange() const
    {
        throw FailT(p_);
    }

private:
    __field_ecount(count_) T* p_;
    SizeType count_;
};


template<typename T, typename FailT, typename S>
inline CheckedPtr<T,FailT,S> operator+(CheckedPtr<T,FailT,S> left, size_t right)
{
    return left += right;
}
