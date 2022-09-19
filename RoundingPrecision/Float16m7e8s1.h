//-----------------------------------------------------------------------------
//
//  The typical 'half' float16 data type (IEEE 754-2008) uses the following bit
//  allocation: mantissa:10 exponent:5 sign:1.
//  https://en.wikipedia.org/wiki/Half-precision_floating-point_format
//
//  An alternate float16 is essentially float32 (IEEE 754-2008) with the lowest
//  16 of 23 mantissa bits chopped off: mantissa:7 exponent:8 sign:1
//  https://en.wikipedia.org/wiki/Bfloat16_floating-point_format
//
//-----------------------------------------------------------------------------

#pragma once

struct float16m7e8s1_t
{
    float16m7e8s1_t() = default;
    float16m7e8s1_t(const float16m7e8s1_t&) = default;
    float16m7e8s1_t(float16m7e8s1_t&&) = default;

    float16m7e8s1_t(float floatValue) noexcept
    {
        value = reinterpret_cast<uint32_t&>(floatValue) >> 16;
    }

    float16m7e8s1_t& operator =(const float16m7e8s1_t&) = default;

    float16m7e8s1_t& operator =(float floatValue) noexcept
    {
        value = reinterpret_cast<uint32_t&>(floatValue) >> 16;
        return *this;
    }

    operator float() const noexcept
    {
        float floatValue = 0.0;
        reinterpret_cast<uint32_t&>(floatValue) = value << 16;
        return floatValue;
    }

    uint16_t value;
};

inline float16m7e8s1_t operator +(float16m7e8s1_t a, float16m7e8s1_t b) noexcept { return float(a) + float(b); }
inline float16m7e8s1_t operator -(float16m7e8s1_t a, float16m7e8s1_t b) noexcept { return float(a) - float(b); }
inline float16m7e8s1_t operator *(float16m7e8s1_t a, float16m7e8s1_t b) noexcept { return float(a) * float(b); }
inline float16m7e8s1_t operator /(float16m7e8s1_t a, float16m7e8s1_t b) noexcept { return float(a) / float(b); }
inline float16m7e8s1_t operator +(float16m7e8s1_t a, double b) noexcept { return float(a) + float(b); }
inline float16m7e8s1_t operator -(float16m7e8s1_t a, double b) noexcept { return float(a) - float(b); }
inline float16m7e8s1_t operator *(float16m7e8s1_t a, double b) noexcept { return float(a) * float(b); }
inline float16m7e8s1_t operator /(float16m7e8s1_t a, double b) noexcept { return float(a) / float(b); }
inline float16m7e8s1_t operator +(double a, float16m7e8s1_t b) noexcept { return float(a) + float(b); }
inline float16m7e8s1_t operator -(double a, float16m7e8s1_t b) noexcept { return float(a) - float(b); }
inline float16m7e8s1_t operator *(double a, float16m7e8s1_t b) noexcept { return float(a) * float(b); }
inline float16m7e8s1_t operator /(double a, float16m7e8s1_t b) noexcept { return float(a) / float(b); }
inline float16m7e8s1_t& operator +=(float16m7e8s1_t& a, float16m7e8s1_t b) noexcept { return a = (float(a) + float(b)); }
inline float16m7e8s1_t& operator -=(float16m7e8s1_t& a, float16m7e8s1_t b) noexcept { return a = (float(a) - float(b)); }
inline float16m7e8s1_t& operator *=(float16m7e8s1_t& a, float16m7e8s1_t b) noexcept { return a = (float(a) * float(b)); }
inline float16m7e8s1_t& operator /=(float16m7e8s1_t& a, float16m7e8s1_t b) noexcept { return a = (float(a) / float(b)); }
inline float16m7e8s1_t& operator ++(float16m7e8s1_t& a) noexcept { return a = float(a) + 1; }
inline float16m7e8s1_t& operator --(float16m7e8s1_t& a) noexcept { return a = float(a) + 1; }
inline bool operator==(float16m7e8s1_t lhs, float16m7e8s1_t rhs) noexcept { return float(lhs) == float(rhs); }
inline bool operator!=(float16m7e8s1_t lhs, float16m7e8s1_t rhs) noexcept { return float(lhs) != float(rhs); }
inline bool operator< (float16m7e8s1_t lhs, float16m7e8s1_t rhs) noexcept { return float(lhs) <  float(rhs); }
inline bool operator> (float16m7e8s1_t lhs, float16m7e8s1_t rhs) noexcept { return float(lhs) >  float(rhs); }
inline bool operator<=(float16m7e8s1_t lhs, float16m7e8s1_t rhs) noexcept { return float(lhs) <= float(rhs); }
inline bool operator>=(float16m7e8s1_t lhs, float16m7e8s1_t rhs) noexcept { return float(lhs) >= float(rhs); }
