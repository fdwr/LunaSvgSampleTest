// Main.cpp

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <algorithm>

union int64_emulated
{
    struct
    {
        uint32_t low;
        uint32_t high;
    };
    int64_t i;

    void Negate()
    {
        low = -((int32_t)low);
        high = ~high + (low == 0);
    }

    void ShiftLeft(uint32_t shift)
    {
        uint32_t inverseShift = 32 - shift;
        int64_emulated result;
        result.low   = (shift        < 32) ? (low << shift) : 0;
        result.high  = (shift        < 32) ? (high << shift) : 0;
        result.high |= (inverseShift < 32) ? (low >> inverseShift) : 0;
        result.high |= (shift        > 32) ? (low << (shift - 32)) : 0;
        *this = result;
    }

    void ShiftRight(uint32_t shift)
    {
        uint32_t inverseShift = 32 - shift;
        int64_emulated result;
        result.high = (shift        < 32) ? (low << shift) : 0;
        result.low  = (shift        < 32) ? (high << shift) : 0;
        result.low |= (inverseShift < 32) ? (low >> inverseShift) : 0;
        result.low |= (shift        > 32) ? (low << (shift - 32)) : 0;
        *this = result;
    }
};

using float32_t = float;

inline int64_emulated CastToInt64(float32_t a)
{
    const uint32_t mantissaMask = 0x007FFFFF;
    const uint32_t mantissaHiddenOneBit = 0x00800000;
    const uint32_t mantissaShift = 0;
    const uint32_t mantissaBitSize = 23;
    const uint32_t signMask = 0x80000000;
    const uint32_t signShift = 31;
    const uint32_t exponentMask = 0x7F800000;
    const uint32_t exponentShift = 23;
    const uint32_t exponentBase = 127; // Identity exponent.
    const uint32_t exponentInfinity = 255;
    const uint32_t integerBitSize = 64;

    uint32_t rawFloat = reinterpret_cast<uint32_t&>(a);

    // Extract exponent -127 to 128, where 127 -> 0 identity.
    const uint32_t exponent = ((rawFloat & exponentMask) >> exponentShift);
    const int32_t shift = exponent - (exponentBase + mantissaBitSize);

    // Restore implicit leading one.
    const uint32_t rawMantissa = rawFloat & mantissaMask;
    const uint32_t fullMantissa = rawMantissa | (exponent ? mantissaHiddenOneBit : 0);

    const bool isNegative = (int32_t)rawFloat < 0;

    int64_emulated result = {};

    if (exponent >= exponentBase + integerBitSize - 1)
    {
        // Bigger than an integer can handle, including sign bit.
        result.low = 0xFFFFFFFF;
        result.high = 0x7FFFFFFF;
    }
    else if (exponent < exponentBase - 1)
    {
        // Smaller than 0.5 (and so cannot be an integer).
        result.low = 0;
        result.high = 0;
    }
    else if (exponent >= exponentBase + mantissaBitSize)
    {
        // Result is fully an integer. So just shift left.
        result.low = fullMantissa;
        result.ShiftLeft(shift);
    }
    else
    {
        // Otherwise fractional component.
        //uint32_t alignedMantissa = fullMantissa << (32 + shift);
        result.low = fullMantissa >> -shift;

        // Round to nearest integer or halves to nearest evens.
        //result.low += ((alignedMantissa > 0x80000000UL)
        //            | ((alignedMantissa == 0x80000000UL) & (result.low & 1)));
        result.high = 0;
    }

    if (isNegative) // Negate if needed.
    {
        result.Negate();
    }

    return result;
}

inline float32_t CastToFloat32(int64_emulated a)
{
    const uint32_t mantissaMask = 0x007FFFFF;
    const uint32_t mantissaHiddenOneBit = 0x00800000;
    const uint32_t mantissaShift = 0;
    const uint32_t mantissaBitSize = 23;
    const uint32_t signMask = 0x80000000;
    const uint32_t signShift = 31;
    const uint32_t exponentMask = 0x7F800000;
    const uint32_t exponentShift = 23;
    const uint32_t exponentBase = 127; // Identity exponent.
    const uint32_t exponentInfinity = 255;
    const uint32_t integerBitSize = 64;

    uint32_t rawFloat = 0;

//    // Extract exponent -127 to 128, where 127 -> 0 identity.
//    const uint32_t exponent = ((rawFloat & exponentMask) >> exponentShift);
//    const int32_t shift = exponent - (exponentBase + mantissaBitSize);
//
//    // Restore implicit leading one.
//    const uint32_t rawMantissa = rawFloat & mantissaMask;
//    const uint32_t fullMantissa = rawMantissa | (rawMantissa ? mantissaHiddenOneBit : 0);

    if (a.high == 0 && a.low == 0)
    {
        return 0;
    }

    const bool isNegative = (int32_t)a.high < 0;
    if (isNegative)
    {
        // Get absolute value.
        a.Negate();
        rawFloat = 0x80000000;
    }

    //uint32_t exponent = firstbithigh(a.high);
    unsigned long index = 0;
    _BitScanReverse(/*out*/ &index, a.high);
    if (((1 << index) & a.high))
    {
        index += 32;
    }
    else
    {
        _BitScanReverse(/*out*/ &index, a.low);
    }
    int32_t shift = index - mantissaBitSize;
    if (shift > 0)
    {
        a.ShiftRight(shift);
    }
    else
    {
        a.low <<= -shift;
        //a.ShiftLeft(-shift);
    }

    int32_t exponent = shift + mantissaBitSize + exponentBase;

    rawFloat |= exponent << exponentShift;
    rawFloat |= a.low & mantissaMask;

    return reinterpret_cast<float32_t&>(rawFloat);
}

void umul64to128(uint64_t a, uint64_t b, uint64_t* hi, uint64_t* lo)
{
    uint64_t a_lo = (uint64_t)(uint32_t)a;
    uint64_t a_hi = a >> 32;
    uint64_t b_lo = (uint64_t)(uint32_t)b;
    uint64_t b_hi = b >> 32;

    uint64_t p0 = a_lo * b_lo;
    uint64_t p1 = a_lo * b_hi;
    uint64_t p2 = a_hi * b_lo;
    uint64_t p3 = a_hi * b_hi;

    uint32_t cy = (uint32_t)(((p0 >> 32) + (uint32_t)p1 + (uint32_t)p2) >> 32);

    *lo = p0 + (p1 << 32) + (p2 << 32);
    *hi = p3 + (p1 >> 32) + (p2 >> 32) + cy;
}

union uint64as16x4_t
{
    struct
    {
        uint16_t a;
        uint16_t b;
        uint16_t c;
        uint16_t d;
    };
    uint64_t i;
};

void umul64wide2(int64_emulated a, int64_emulated b)
{
    uint64as16x4_t c, d;
    c.i = a.i;
    d.i = b.i;
    //... TODO ...
}

int main()
{
    float x = 42;//1e19;
    auto y = CastToInt64(x);
    auto zi32 = static_cast<int32_t>(x);
    auto zi64 = static_cast<int64_t>(x);
    float w = CastToFloat32(y);
    //int32_t y = static_cast<int32_t>(x);
    //printf("x = %u, y = %lld", x, y);
    printf("x = %f, yi64 = %lld, zi32 = %d, zi64 = %lld, w = %f", x, y.i, zi32, zi64, w);

    return EXIT_SUCCESS;
}
