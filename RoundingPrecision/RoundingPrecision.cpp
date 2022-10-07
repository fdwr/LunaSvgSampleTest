// RoundingPrecision.cpp
// https://github.com/webmachinelearning/webnn/issues/265

#include "precomp.h"


enum class NumberType : uint32_t
{
    Undefined = 0,
    Float32m23e8s1 = 1,
    Float32 = Float32m23e8s1 , // starting from bit 0 - fraction:23 exponent:8 sign:1
    Uint8 = 2,
    Int8 = 3,
    Uint16 = 4,
    Int16 = 5,
    Int32 = 6,
    Int64 = 7,
    StringChar8 = 8,
    Bool8 = 9,
    Float16m10e5s1 = 10, // fraction:10 exponent:5 sign:1
    Float16 = Float16m10e5s1,
    Float64m52e11s1 = 11,
    Float64 = Float64m52e11s1, // fraction:52 exponent:11 sign:1
    Uint32 = 12,
    Uint64 = 13,
    Complex64 = 14,
    Complex128 = 15,
    Float16m7e8s1 = 16, // fraction:7 exponent:8 sign:1 (the 16-bit "brain" float with reduced precision but increased range)
    Bfloat16 = Float16m7e8s1,
    Fixed24f12i11s1 = 17,
    Fixed32f16i15s1 = 18,
    Fixed32f24i7s1 = 19,
    Float32As64 = 20,
    Float16As64 = 21,
    Bfloat16As64 = 22,
    Total = 23,
};

// Ensure IEEE format so that bitmasking works as expected.
static_assert(std::numeric_limits<float>::is_iec559);
static_assert(std::numeric_limits<float>::digits == 24);

using Fixed24f12i11s1 = FixedNumber<int24_t, 12, 12>;
using Fixed32f16i15s1 = FixedNumber<int32_t, 16, 16>;
using Fixed32f24i7s1  = FixedNumber<int32_t, 8, 24>;

union NumberUnion
{
    uint8_t         buffer[8];
    uint8_t         ui8;
    uint16_t        ui16;
    uint32_t        ui32;
    uint64_t        ui64;
    int8_t          i8;
    int16_t         i16;
    int32_t         i32;
    int64_t         i64;
    float16_t       f16;
    float16m7e8s1_t f16m7e8s1;
    float32_t       f32;
    float64_t       f64;
    Fixed24f12i11s1 x24f12i11s1;
    Fixed32f16i15s1 x32f16i15s1;
    Fixed32f24i7s1  x32f24i7s1;

    // Leave as aggregate POD.
    // NumberUnion() : ui64{0} {}
};

struct NumberFormatBitmask
{
     // Bits allocated to fraction part (e.g. 23 for float32, 52 for float64, 0 for uint32)
    uint64_t fractionMask;

    // Number of bits below the fractional part (only useful when low precision is stored within higher precision type,
    // like a float32 stored within a float64 (52-23 bits are subfraction bits).
    uint64_t subfractionMask;

    // Bits for integer part, zero for floating point. The implicit hidden one is not counted.
    uint64_t integerMask;

    // Bits for exponent part (8 for flota32, 11 for float64).
    uint64_t exponentMask;

    // Either 0 when unsigned or 1<<(totalBits-1) when signed.
    uint64_t signMask;
};

void CastNumberType(
    NumberType inputNumberType,
    NumberUnion const& inputNumberUnion,
    NumberType outputNumberType,
    /*out*/ NumberUnion& outputNumberUnion
);
NumberFormatBitmask const& GetNumberFormatBitmask(NumberType numberType);

// Round toward zero (or truncate) a higher precision value into a lower precision value.
NumberUnion RoundTowardZero(NumberUnion numberUnion, NumberFormatBitmask const& bitmask)
{
    // Zero any subfraction bits (leaving others intact).
    numberUnion.ui64 &= ~bitmask.subfractionMask;
    return numberUnion;
}

// Round toward positive or negative infinity a higher precision value into a lower precision value.
NumberUnion RoundTowardInfinity(NumberUnion numberUnion, NumberFormatBitmask const& bitmask)
{
     // If an exponent mask exists, then it should be in the more significant bits relative to the fraction.
    assert((bitmask.exponentMask == 0) || (bitmask.exponentMask > bitmask.fractionMask));

     // If an integer mask exists, then it should be in the more significant bits relative to the fraction.
    assert((bitmask.integerMask == 0) || (bitmask.integerMask > bitmask.fractionMask)); // If an integer/exponent mask exists, then it should be in the more significant bits relative to the fraction.

    // If subfraction bits exist, they should be less significant to the fraction bits.
    assert((bitmask.subfractionMask == 0) || (bitmask.fractionMask > bitmask.subfractionMask));

    uint64_t combinedIntegerExponentMask = bitmask.integerMask | bitmask.exponentMask;
    // Avoid further rounding if it would go beyond infinity, which would yield NaN.
    // Avoid rounding up if already rounded.
    if ((numberUnion.ui64 & combinedIntegerExponentMask) < combinedIntegerExponentMask
    &&  (numberUnion.ui64 & bitmask.subfractionMask))
    {
        numberUnion.ui64 |= bitmask.subfractionMask;
        ++numberUnion.ui64;
    }
    return numberUnion;
}

// Round toward positive or negative infinity depending on whichever even value is closer.
NumberUnion RoundTowardToNearestEven(NumberUnion numberUnion, NumberFormatBitmask const& bitmask)
{
    uint64_t value = numberUnion.ui64;
    uint64_t lsbValueMask = (bitmask.subfractionMask + 1); // To determine nearest even
    uint64_t halfValue = lsbValueMask >> 1;
    uint64_t roundingBits = value & bitmask.subfractionMask;

    if (roundingBits < halfValue)
    {
        // Round less if rounding bits below half value.
        numberUnion = RoundTowardZero(numberUnion, bitmask);
    }
    else if (roundingBits > halfValue)
    {
        // Round greater if rounding bits above half value.
        numberUnion = RoundTowardInfinity(numberUnion, bitmask);
    }
    // else roundingBits == halfValue
    else if (value & lsbValueMask)
    {
        // If least significant fraction bit is odd, then round toward infinity.
        numberUnion = RoundTowardInfinity(numberUnion, bitmask);
    }
    else // !(value & lsbValueMask)
    {
        // If already even, just truncate.
        numberUnion = RoundTowardZero(numberUnion, bitmask);
    }

    return numberUnion;
}

struct NumberRounded
{
    NumberType numberType = NumberType::Undefined;
    NumberUnion precise = {};
    NumberUnion roundedLow = {};
    NumberUnion roundedHigh = {};
    NumberUnion roundedEven = {};

    NumberRounded() = default;

    inline NumberRounded(float32_t value)
    {
        Set(value);
    }

    inline NumberRounded(float64_t value)
    {
        Set(value);
    }

    inline NumberRounded(NumberType newNumberType, NumberUnion value)
    {
        Set(newNumberType, value);
    }

    void Set(float64_t value)
    {
        numberType = NumberType::Float64;
        precise.f64 = value;
        roundedLow.f64 = value;
        roundedHigh.f64 = value;
        roundedEven.f64 = value;
    }

    void Set(int64_t value)
    {
        numberType = NumberType::Int64;
        precise.i64 = value;
        roundedLow.i64 = value;
        roundedHigh.i64 = value;
        roundedEven.i64 = value;
    }

    void Set(NumberType newNumberType, NumberUnion value)
    {
        numberType = newNumberType;
        precise = value;
        roundedLow = value;
        roundedHigh = value;
        roundedEven = value;
    }

    void Round()
    {
        Round(GetNumberFormatBitmask(this->numberType));
    }

    void Round(NumberFormatBitmask const& bitmask)
    {
        roundedLow = RoundTowardZero(roundedLow, bitmask);
        roundedHigh = RoundTowardInfinity(roundedHigh, bitmask);
        roundedEven = RoundTowardToNearestEven(roundedEven, bitmask);
    }

    void Zero()
    {
        precise.ui64     = 0;
        roundedLow.ui64  = 0;
        roundedHigh.ui64 = 0;
        roundedEven.ui64 = 0;
    }

    void Cast(NumberType newNumberType)
    {
        if (numberType == newNumberType)
        {
            return;
        }

        CastNumberType(numberType, precise,     newNumberType, /*out*/ precise);
        CastNumberType(numberType, roundedLow,  newNumberType, /*out*/ roundedLow);
        CastNumberType(numberType, roundedHigh, newNumberType, /*out*/ roundedHigh);
        CastNumberType(numberType, roundedEven, newNumberType, /*out*/ roundedEven);
        numberType = newNumberType;
    }

    // Apply unary function to a single number, respecting the data type
    // e.g. f = [](auto input) {return input + 1;}
    template<typename Functor>
    static void ApplyOperationUnaryToSingleNumber(
        Functor const& f,
        NumberType numberType,
        NumberUnion const& input,
        NumberUnion& output
        )
    {
        switch (numberType)
        {
        case NumberType::Bool8:
        case NumberType::Uint8:           output.ui8         = f(input.ui8 );         break;
        case NumberType::Int8:            output.i8          = f(input.i8  );         break;
        case NumberType::Uint16:          output.ui16        = f(input.ui16);         break;
        case NumberType::Int16:           output.i16         = f(input.i16 );         break;
        case NumberType::Uint32:          output.ui32        = f(input.ui32);         break;
        case NumberType::Int32:           output.i32         = f(input.i32 );         break;
        case NumberType::Uint64:          output.ui64        = f(input.ui64);         break;
        case NumberType::Int64:           output.i64         = f(input.i64 );         break;
        case NumberType::Float16:         output.f16         = f(input.f16);          break;
        case NumberType::Bfloat16:        output.f16m7e8s1   = f(input.f16m7e8s1);    break;
        case NumberType::Float32:         output.f32         = f(input.f32);          break;
        case NumberType::Float16As64:
        case NumberType::Bfloat16As64:
        case NumberType::Float32As64:
        case NumberType::Float64:         output.f64         = f(input.f64);          break;
        case NumberType::Fixed24f12i11s1: output.x24f12i11s1 = f(input.x24f12i11s1);  break;
        case NumberType::Fixed32f16i15s1: output.x32f16i15s1 = f(input.x32f16i15s1);  break;
        case NumberType::Fixed32f24i7s1:  output.x32f24i7s1  = f(input.x32f24i7s1);   break;
        }
    }

    // Apply binary function to a single number, respecting the data type.
    // e.g. f = [](auto a, auto b) {return a + b;}
    template<typename Functor>
    static void ApplyOperationBinaryToSingleNumber(
        Functor const& f,
        NumberType numberType,
        NumberUnion const& a,
        NumberUnion const& b,
        NumberUnion& output
        )
    {
        switch (numberType)
        {
        case NumberType::Bool8:
        case NumberType::Uint8:           output.ui8         = f(a.ui8,  b.ui8);                break;
        case NumberType::Int8:            output.i8          = f(a.i8,   b.i8 );                break;
        case NumberType::Uint16:          output.ui16        = f(a.ui16, b.ui16);               break;
        case NumberType::Int16:           output.i16         = f(a.i16,  b.i16 );               break;
        case NumberType::Uint32:          output.ui32        = f(a.ui32, b.ui32);               break;
        case NumberType::Int32:           output.i32         = f(a.i32,  b.i32 );               break;
        case NumberType::Uint64:          output.ui64        = f(a.ui64, b.ui64);               break;
        case NumberType::Int64:           output.i64         = f(a.i64,  b.i64);                break;
        case NumberType::Float16:         output.f16         = f(a.f16,  b.f16);                break;
        case NumberType::Bfloat16:        output.f16m7e8s1   = f(a.f16m7e8s1, b.f16m7e8s1);     break;
        case NumberType::Float32:         output.f32         = f(a.f32,  b.f32);                break;
        case NumberType::Float32As64:
        case NumberType::Float16As64:
        case NumberType::Bfloat16As64:
        case NumberType::Float64:         output.f64         = f(a.f64,  b.f64);                break;
        case NumberType::Fixed24f12i11s1: output.x24f12i11s1 = f(a.x24f12i11s1, a.x24f12i11s1); break;
        case NumberType::Fixed32f16i15s1: output.x32f16i15s1 = f(a.x32f16i15s1, a.x32f16i15s1); break;
        case NumberType::Fixed32f24i7s1:  output.x32f24i7s1  = f(a.x32f24i7s1 , a.x32f24i7s1);  break;
        }
    }

    // Apply unary function directly onto this object.
    // e.g. f = [](NumberUnion const& input, NumberUnion& output) {output.f64 = sqrt(a.f64);}
    template<typename Functor>
    void ApplyOperationUnary(Functor const& f)
    {
        NumberRounded::ApplyOperationUnaryToSingleNumber(f, numberType, precise,     /*out*/ precise);
        NumberRounded::ApplyOperationUnaryToSingleNumber(f, numberType, roundedLow,  /*out*/ roundedLow);
        NumberRounded::ApplyOperationUnaryToSingleNumber(f, numberType, roundedHigh, /*out*/ roundedHigh);
        NumberRounded::ApplyOperationUnaryToSingleNumber(f, numberType, roundedEven, /*out*/ roundedEven);
        Round();
    }

    // Apply binary function and store result into this object.
    // e.g. f = [](NumberUnion const& a, NumberUnion const& b, NumberUnion& output) {output.i64 = a.i64 + b.i64;})
    template<typename Functor>
    void ApplyOperationBinary(Functor const& f, NumberRounded const& a, NumberRounded const& b)
    {
        NumberRounded::ApplyOperationBinaryToSingleNumber(f, numberType, a.precise,     b.precise,     /*out*/ precise);
        NumberRounded::ApplyOperationBinaryToSingleNumber(f, numberType, a.roundedLow,  b.roundedLow,  /*out*/ roundedLow);
        NumberRounded::ApplyOperationBinaryToSingleNumber(f, numberType, a.roundedHigh, b.roundedHigh, /*out*/ roundedHigh);
        NumberRounded::ApplyOperationBinaryToSingleNumber(f, numberType, a.roundedEven, b.roundedEven, /*out*/ roundedEven);
        Round();
    }
};

NumberRounded operator +(NumberRounded const& a, NumberRounded const& b)
{
    assert(a.numberType == b.numberType);
    NumberRounded result;
    result.numberType = a.numberType;

    auto f = [](auto a, auto b) {return a + b;};
    result.ApplyOperationBinary(f, a, b);
    return result;
}

NumberRounded operator -(NumberRounded const& a, NumberRounded const& b)
{
    assert(a.numberType == b.numberType);
    NumberRounded result;
    result.numberType = a.numberType;

    auto f = [](auto a, auto b) {return a - b;};
    result.ApplyOperationBinary(f, a, b);
    return result;
}

NumberRounded operator *(NumberRounded const& a, NumberRounded const& b)
{
    assert(a.numberType == b.numberType);
    NumberRounded result;
    result.numberType = a.numberType;

    auto f = [](auto a, auto b) {return a * b;};
    result.ApplyOperationBinary(f, a, b);
    return result;
}

NumberRounded operator /(NumberRounded const& a, NumberRounded const& b)
{
    assert(a.numberType == b.numberType);
    NumberRounded result;
    result.numberType = a.numberType;

    auto f = [](auto a, auto b) {return a / b;};
    result.ApplyOperationBinary(f, a, b);
    return result;
}

bool operator ==(NumberRounded const& a, NumberRounded const& b)
{
    return a.numberType       == b.numberType
        && a.precise.ui64     == b.precise.ui64
        && a.roundedLow.ui64  == b.roundedLow.ui64 
        && a.roundedHigh.ui64 == b.roundedHigh.ui64
        && a.roundedEven.ui64 == b.roundedEven.ui64;
}

// Common formats, including some low precision formats expressed in the bit layout of higher precision,
// like float32 in float64 layout.
constexpr NumberFormatBitmask bfloat16NumberMask        = {.fractionMask = (1ULL<< 7)-1,    .subfractionMask = 0,                   .integerMask = 0,                       .exponentMask = 0b11111111ULL << 7,     .signMask = 1ULL<<15};
constexpr NumberFormatBitmask float16NumberMask         = {.fractionMask = (1ULL<<10)-1,    .subfractionMask = 0,                   .integerMask = 0,                       .exponentMask = 0b11111ULL << 10,       .signMask = 1ULL<<15};
constexpr NumberFormatBitmask float32NumberMask         = {.fractionMask = (1ULL<<23)-1,    .subfractionMask = 0,                   .integerMask = 0,                       .exponentMask = 0b11111111ULL << 23,    .signMask = 1ULL<<31};
constexpr NumberFormatBitmask float64NumberMask         = {.fractionMask = (1ULL<<52)-1,    .subfractionMask = 0,                   .integerMask = 0,                       .exponentMask = 0b11111111111ULL << 52, .signMask = 1ULL<<63};
constexpr NumberFormatBitmask float16as64NumberMask     = {.fractionMask = (1ULL<<52)-1,    .subfractionMask = (1ULL<<(52-10))-1,   .integerMask = 0,                       .exponentMask = 0b11111111111ULL << 52, .signMask = 1ULL<<63};
constexpr NumberFormatBitmask bfloat16as64NumberMask    = {.fractionMask = (1ULL<<52)-1,    .subfractionMask = (1ULL<<(52- 7))-1,   .integerMask = 0,                       .exponentMask = 0b11111111111ULL << 52, .signMask = 1ULL<<63};
constexpr NumberFormatBitmask float32as64NumberMask     = {.fractionMask = (1ULL<<52)-1,    .subfractionMask = (1ULL<<(52-23))-1,   .integerMask = 0,                       .exponentMask = 0b11111111111ULL << 52, .signMask = 1ULL<<63};
constexpr NumberFormatBitmask uint8NumberMask           = {.fractionMask = 0,               .subfractionMask = 0,                   .integerMask = (1ULL<< 8)-1,            .exponentMask = 0,                      .signMask = 0ULL    };
constexpr NumberFormatBitmask uint16NumberMask          = {.fractionMask = 0,               .subfractionMask = 0,                   .integerMask = (1ULL<<16)-1,            .exponentMask = 0,                      .signMask = 0ULL    };
constexpr NumberFormatBitmask uint32NumberMask          = {.fractionMask = 0,               .subfractionMask = 0,                   .integerMask = (1ULL<<32)-1,            .exponentMask = 0,                      .signMask = 0ULL    };
constexpr NumberFormatBitmask uint64NumberMask          = {.fractionMask = 0,               .subfractionMask = 0,                   .integerMask = uint64_t(~0),            .exponentMask = 0,                      .signMask = 0ULL    };
constexpr NumberFormatBitmask int8NumberMask            = {.fractionMask = 0,               .subfractionMask = 0,                   .integerMask = (1ULL<< 7)-1,            .exponentMask = 0,                      .signMask = 1ULL<< 7};
constexpr NumberFormatBitmask int16NumberMask           = {.fractionMask = 0,               .subfractionMask = 0,                   .integerMask = (1ULL<<15)-1,            .exponentMask = 0,                      .signMask = 1ULL<<15};
constexpr NumberFormatBitmask int32NumberMask           = {.fractionMask = 0,               .subfractionMask = 0,                   .integerMask = (1ULL<<31)-1,            .exponentMask = 0,                      .signMask = 1ULL<<31};
constexpr NumberFormatBitmask int64NumberMask           = {.fractionMask = 0,               .subfractionMask = 0,                   .integerMask = (1ULL<<63)-1,            .exponentMask = 0,                      .signMask = 1ULL<<63};
constexpr NumberFormatBitmask fixed24f12i11s1NumberMask = {.fractionMask = (1ULL<<12)-1,    .subfractionMask = 0,                   .integerMask = (1ULL<<24)-(1ULL<<12),   .exponentMask = 0,                      .signMask = 1ULL<<63};
constexpr NumberFormatBitmask fixed32f16i15s1NumberMask = {.fractionMask = (1ULL<<16)-1,    .subfractionMask = 0,                   .integerMask = (1ULL<<32)-(1ULL<<16),   .exponentMask = 0,                      .signMask = 1ULL<<63};
constexpr NumberFormatBitmask fixed32f24i7s1NumberMask  = {.fractionMask = (1ULL<<24)-1,    .subfractionMask = 0,                   .integerMask = (1ULL<<32)-(1ULL<<24),   .exponentMask = 0,                      .signMask = 1ULL<<63};
constexpr NumberFormatBitmask bool8NumberMask           = {.fractionMask = 0,               .subfractionMask = 0,                   .integerMask = (1ULL<< 8)-1,            .exponentMask = 0,                      .signMask = 0ULL    };
                                                    
// The caller passes a data pointer of the given type.
void WriteFromDouble(NumberType dataType, double value, /*out*/ void* data)
{
    switch (dataType)
    {
    case NumberType::Float32:           *reinterpret_cast<float*>(data) = float(value);                     break;
    case NumberType::Uint8:             *reinterpret_cast<uint8_t*>(data) = uint8_t(value);                 break;
    case NumberType::Int8:              *reinterpret_cast<int8_t*>(data) = int8_t(value);                   break;
    case NumberType::Uint16:            *reinterpret_cast<uint16_t*>(data) = uint16_t(value);               break;
    case NumberType::Int16:             *reinterpret_cast<int16_t*>(data) = int16_t(value);                 break;
    case NumberType::Int32:             *reinterpret_cast<int32_t*>(data) = int32_t(value);                 break;
    case NumberType::Int64:             *reinterpret_cast<int64_t*>(data) = int64_t(value);                 break;
    case NumberType::StringChar8:       /* no change value for strings */                                   break;
    case NumberType::Bool8:             *reinterpret_cast<bool*>(data) = bool(value);                       break;
    case NumberType::Float16:           *reinterpret_cast<uint16_t*>(data) = half_float::detail::float2half<std::round_to_nearest, float>(float(value)); break;
    case NumberType::Bfloat16:          *reinterpret_cast<bfloat16_t*>(data) = bfloat16_t(float(value));    break;
    case NumberType::Float64:           *reinterpret_cast<double*>(data) = value;                           break;
    case NumberType::Float16As64:       *reinterpret_cast<double*>(data) = value;                           break;
    case NumberType::Bfloat16As64:      *reinterpret_cast<double*>(data) = value;                           break;
    case NumberType::Float32As64:       *reinterpret_cast<double*>(data) = value;                           break;
    case NumberType::Uint32:            *reinterpret_cast<uint32_t*>(data) = uint32_t(value);               break;
    case NumberType::Uint64:            *reinterpret_cast<uint64_t*>(data) = uint64_t(value);               break;
    case NumberType::Complex64:         throw std::invalid_argument("Complex64 type is not supported.");
    case NumberType::Complex128:        throw std::invalid_argument("Complex128 type is not supported.");
    case NumberType::Fixed24f12i11s1:   *reinterpret_cast<Fixed24f12i11s1*>(data) = float(value);           break;
    case NumberType::Fixed32f16i15s1:   *reinterpret_cast<Fixed32f16i15s1*>(data) = float(value);           break;
    case NumberType::Fixed32f24i7s1:;   *reinterpret_cast<Fixed32f24i7s1*>(data) = float(value);            break;
    default:                            assert(false);                                                      break;
    }

    // Use half_float::detail::float2half explicitly rather than the half constructor.
    // Otherwise values do not round-trip as expected.
    //
    // e.g. If you print float16 0x2C29, you get 0.0650024, but if you try to parse
    // 0.0650024, you get 0x2C28 instead. Then printing 0x2C28 shows 0.0649414,
    // but trying to parse 0.0649414 returns 0x2C27. Rounding to nearest fixes this.
}

// Just copy a single element from the input to output.
void WriteToDouble(NumberType dataType, void const* inputData, /*out*/ double& number)
{
    switch (dataType)
    {
    case NumberType::Float32:           number = float64_t(*reinterpret_cast<const float32_t*>(inputData));       break;
    case NumberType::Uint8:             number = float64_t(*reinterpret_cast<const uint8_t*>(inputData));         break;
    case NumberType::Int8:              number = float64_t(*reinterpret_cast<const int8_t*>(inputData));          break;
    case NumberType::Uint16:            number = float64_t(*reinterpret_cast<const uint16_t*>(inputData));        break;
    case NumberType::Int16:             number = float64_t(*reinterpret_cast<const int16_t*>(inputData));         break;
    case NumberType::Int32:             number = float64_t(*reinterpret_cast<const int32_t*>(inputData));         break;
    case NumberType::Int64:             number = float64_t(*reinterpret_cast<const int64_t*>(inputData));         break;
    case NumberType::StringChar8:       /* no change value for strings */                                         break;
    case NumberType::Bool8:             number = float64_t(*reinterpret_cast<const uint8_t*>(inputData));         break;
    case NumberType::Float16:           number = float64_t(*reinterpret_cast<const float16_t*>(inputData));       break;
    case NumberType::Bfloat16:          number = float64_t(*reinterpret_cast<const bfloat16_t*>(inputData));      break;
    case NumberType::Float64:           number = float64_t(*reinterpret_cast<const float64_t*>(inputData));       break;
    case NumberType::Float16As64:       number = float64_t(*reinterpret_cast<const float64_t*>(inputData));       break;
    case NumberType::Bfloat16As64:      number = float64_t(*reinterpret_cast<const float64_t*>(inputData));       break;
    case NumberType::Float32As64:       number = float64_t(*reinterpret_cast<const float64_t*>(inputData));       break;
    case NumberType::Uint32:            number = float64_t(*reinterpret_cast<const uint32_t*>(inputData));        break;
    case NumberType::Uint64:            number = float64_t(*reinterpret_cast<const uint64_t*>(inputData));        break;
    case NumberType::Complex64:         throw std::invalid_argument("Complex64 type is not supported.");
    case NumberType::Complex128:        throw std::invalid_argument("Complex128 type is not supported.");
    case NumberType::Fixed24f12i11s1:   number = float64_t(*reinterpret_cast<const Fixed24f12i11s1*>(inputData)); break;
    case NumberType::Fixed32f16i15s1:   number = float64_t(*reinterpret_cast<const Fixed32f16i15s1*>(inputData)); break;
    case NumberType::Fixed32f24i7s1:    number = float64_t(*reinterpret_cast<const Fixed32f24i7s1*>(inputData));  break;
    default:                            assert(false);                                                            break;
    }
}

void CastNumberType(
    NumberType inputNumberType,
    NumberUnion const& inputNumberUnion,
    NumberType outputNumberType,
    /*out*/ NumberUnion& outputNumberUnion
    )
{
    double temporary;
    WriteToDouble(inputNumberType, &inputNumberUnion, /*out*/ temporary);
    outputNumberUnion.ui64 = 0; // Zero out upper bits to avoid noise.
    WriteFromDouble(outputNumberType, temporary, /*out*/ &outputNumberUnion);
}

NumberFormatBitmask const& GetNumberFormatBitmask(NumberType numberType)
{
    constexpr static NumberFormatBitmask emptyFormatBitmask = {};

    switch (numberType)
    {
    case NumberType::Float32:           return float32NumberMask; break;
    case NumberType::Uint8:             return uint8NumberMask; break;
    case NumberType::Int8:              return int8NumberMask; break;
    case NumberType::Uint16:            return uint16NumberMask; break;
    case NumberType::Int16:             return int16NumberMask; break;
    case NumberType::Int32:             return int32NumberMask; break;
    case NumberType::Int64:             return int64NumberMask; break;
    case NumberType::StringChar8:       throw std::invalid_argument("StringChar8 type is not supported.");
    case NumberType::Bool8:             return bool8NumberMask; break;
    case NumberType::Float16:           return float16NumberMask; break;
    case NumberType::Bfloat16:          return bfloat16NumberMask; break;
    case NumberType::Float64:           return float64NumberMask; break;
    case NumberType::Float16As64:       return float16as64NumberMask;  break;
    case NumberType::Bfloat16As64:      return bfloat16as64NumberMask;  break;
    case NumberType::Float32As64:       return float32as64NumberMask;  break;
    case NumberType::Uint32:            return uint32NumberMask; break;
    case NumberType::Uint64:            return uint64NumberMask; break;
    case NumberType::Complex64:         throw std::invalid_argument("Complex64 type is not supported.");
    case NumberType::Complex128:        throw std::invalid_argument("Complex128 type is not supported.");
    case NumberType::Fixed24f12i11s1:   return fixed24f12i11s1NumberMask; break;
    case NumberType::Fixed32f16i15s1:   return fixed32f16i15s1NumberMask; break;
    case NumberType::Fixed32f24i7s1:    return fixed32f24i7s1NumberMask; break;
    default:                            return emptyFormatBitmask; assert(false); break;
    }
}

void PrintNumberValues(NumberRounded const& value)
{
    NumberRounded castedValue = value;

    switch (value.numberType)
    {
    case NumberType::Float16:
    case NumberType::Bfloat16:
    case NumberType::Float32:
    case NumberType::Float64:
    case NumberType::Float32As64:
    case NumberType::Float16As64:
    case NumberType::Bfloat16As64:
    case NumberType::Fixed24f12i11s1:
    case NumberType::Fixed32f16i15s1:
    case NumberType::Fixed32f24i7s1:
        castedValue.Cast(NumberType::Float64);
        printf(
            "precise/rz/ri/rne: %f (%08llX), %f (%08llX), %f (%08llX), %f (%08llX)\n",
            castedValue.precise.f64,
            castedValue.precise.ui64,
            castedValue.roundedLow.f64,
            castedValue.roundedLow.ui64,
            castedValue.roundedHigh.f64,
            castedValue.roundedHigh.ui64,
            castedValue.roundedEven.f64,
            castedValue.roundedEven.ui64
        );
        break;

    case NumberType::Bool8:
    case NumberType::Int8:
    case NumberType::Int16:
    case NumberType::Int32:
    case NumberType::Int64:
        castedValue.Cast(NumberType::Int64);
        printf(
            "precise/rz/ri/rne: %lld (%08llX), %lld (%08llX), %lld (%08llX), %lld (%08llX)\n",
            castedValue.precise.i64,
            castedValue.precise.ui64,
            castedValue.roundedLow.i64,
            castedValue.roundedLow.ui64,
            castedValue.roundedHigh.i64,
            castedValue.roundedHigh.ui64,
            castedValue.roundedEven.i64,
            castedValue.roundedEven.ui64
        );
        break;

    case NumberType::Uint8:
    case NumberType::Uint16:
    case NumberType::Uint32:
    case NumberType::Uint64:
        castedValue.Cast(NumberType::Uint64);
        printf(
            "precise/rz/ri/rne: %llu (%08llX), %llu (%08llX), %llu (%08llX), %llu (%08llX)\n",
            castedValue.precise.ui64,
            castedValue.precise.ui64,
            castedValue.roundedLow.ui64,
            castedValue.roundedLow.ui64,
            castedValue.roundedHigh.ui64,
            castedValue.roundedHigh.ui64,
            castedValue.roundedEven.ui64,
            castedValue.roundedEven.ui64
        );
        break;

    default:
        assert(false);
        printf("Printing type not supported yet\n");
    }
}

void PrintUlpDifferences(
    size_t valueIndex,
    size_t loopIndex,
    NumberRounded const& value,
    NumberRounded const& valueCasted,
    bool printForCsv = false
    )
{
    uint64_t ulpDiffLow  = abs(valueCasted.precise.i64 - valueCasted.roundedLow.i64);
    uint64_t ulpDiffHigh = abs(valueCasted.precise.i64 - valueCasted.roundedHigh.i64);
    uint64_t ulpDiffEven = abs(valueCasted.precise.i64 - valueCasted.roundedEven.i64);
    if (printForCsv)
    {
        printf(
            "%u,%u,%f,0x%08llX,0,%f,0x%08llX,%llu,%f,0x%08llX,%llu,%f,0x%08llX,%llu\n",
            uint32_t(valueIndex),
            uint32_t(loopIndex),
            value.precise.f64,
            valueCasted.precise.ui64,
            value.roundedLow.f64,
            valueCasted.roundedLow.ui64,
            ulpDiffLow,
            value.roundedHigh.f64,
            valueCasted.roundedHigh.ui64,
            ulpDiffHigh,
            value.roundedEven.f64,
            valueCasted.roundedEven.ui64,
            ulpDiffEven
        );
    }
    else
    {
        printf(
            "Precise: %f (0x%08llX, 0 ULP), RTZ: %f (0x%08llX, %llu ULP), RTI: %f (0x%08llX, %llu ULP), RTNE: %f (0x%08llX, %llu ULP)\n",
            value.precise.f64,
            valueCasted.precise.ui64,
            value.roundedLow.f64,
            valueCasted.roundedLow.ui64,
            ulpDiffLow,
            value.roundedHigh.f64,
            valueCasted.roundedHigh.ui64,
            ulpDiffHigh,
            value.roundedEven.f64,
            valueCasted.roundedEven.ui64,
            ulpDiffEven
        );
    }
}

void ApplyRoundedNumericOperation(
    uint32_t loopCount,
    NumberType numberType,
    std::span<NumberUnion const> initialValues,
    std::function<NumberRounded(NumberRounded const&)> operation,
    bool printForCsv = false
    )
{
    for (size_t valueIndex = 0, valueIndices = initialValues.size(); valueIndex < valueIndices; ++valueIndex)
    {
        auto& initialValue = initialValues[valueIndex];
        NumberRounded value = {};
        NumberRounded valueCasted = {};
        value.Set(numberType, initialValue);

        if (printForCsv)
        {
            printf("Iteration,Precise Value,Precise Hex,RTZ Value,RTZ Hex,RTZ ULP,RTI Value,RTI Hex,RTI ULP,RTNE Value,RTNE Hex,RTNE ULP\n");
        }
        else
        {
            printf("--------------------------------------------------------------------------------\n");
            printf("raw     ");
            PrintNumberValues(value);
        }

        for (size_t loopIndex = 0; loopIndex < loopCount; ++loopIndex)
        {
            if (!printForCsv)
            {
                printf("Iteration %u:%u\n", uint32_t(valueIndex), uint32_t(loopIndex));
            }
            value = operation(value);

            if (!printForCsv)
            {
                printf("full    ");
                PrintNumberValues(value);
            }

            valueCasted = value;
            valueCasted.Cast(NumberType::Float32);
            if (!printForCsv)
            {
                printf("float32 ");
                PrintNumberValues(valueCasted);
            }

            PrintUlpDifferences(valueIndex, loopIndex, value, valueCasted, printForCsv);
        }
    }
}

template<typename T>
std::span<T const> WrapElementInSpan(T const& t)
{
    return std::span<T const>(std::addressof(t), size_t(1));
}

template<typename ContainerType>
auto MakeSpan(ContainerType& container) -> std::span<typename std::remove_reference_t<decltype(*std::data(container))>>
{
    using T = typename std::remove_reference_t<decltype(*std::data(container))>;
    return std::span<T>(std::data(container), std::size(container));
}

template<typename NewType, typename ContainerType>
auto ReinterpretSpan(ContainerType& container) -> std::span<NewType>
{
    size_t oldSize = std::size(container);
    size_t newSize = oldSize;

    using OldType = typename std::remove_reference_t<decltype(*std::data(container))>;
    if constexpr (sizeof(NewType) != sizeof(OldType))
    {
        newSize = oldSize * sizeof(OldType) / sizeof(NewType);
    }
    return std::span<NewType>(reinterpret_cast<NewType*>(std::data(container)), newSize);
}

template <typename T, typename O>
T& CastReferenceAs(O& o)
{
    static_assert(sizeof(O) == sizeof(T));
    return reinterpret_cast<T&>(*std::launder(&o));
}

template <typename T, typename O>
const T& CastReferenceAs(O const& o)
{
    static_assert(sizeof(O) == sizeof(T));
    return reinterpret_cast<const T&>(*std::launder(&o));
}

int main(int argc, char* argv[])
{
#if 0
    for (int i = 0; i < 64; ++i)
    {
        printf("%u\t", i);

        float absoluteTolerance = 8;
        float relativeTolerance = 1.0 / 4;
        uint32_t ulp = 1<<21;

        float fi = float(i);
        float fiLow;
        float fiHigh;

        printf("atol\t");
        fiLow = fi - absoluteTolerance;
        fiHigh = fi + absoluteTolerance;
        printf("%f\t", fi);
        printf("%f\t", fiLow);
        printf("%f\t", fiHigh);
        printf("%f\t", (float(rand()) / RAND_MAX) * (fiHigh - fiLow) + fiLow);

        printf("rtol\t");
        fiLow = fi - (fi * relativeTolerance);
        fiHigh = fi + (fi * relativeTolerance);
        printf("%f\t", fi);
        printf("%f\t", fiLow);
        printf("%f\t", fiHigh);
        printf("%f\t", (float(rand()) / RAND_MAX) * (fiHigh - fiLow) + fiLow);

        printf("ulp\t");
        uint32_t& fbits = CastReferenceAs<uint32_t>(fi);
        uint32_t fbitsLow = (fbits - ulp);
        uint32_t fbitsHigh = (fbits + ulp);
        fiLow = CastReferenceAs<float32_t>(fbitsLow);
        fiHigh = CastReferenceAs<float32_t>(fbitsHigh);
        printf("%f\t", fi);
        printf("%f\t", fiLow);
        printf("%f\t", fiHigh);
        printf("%f\t", (float(rand()) / RAND_MAX) * (fiHigh - fiLow) + fiLow);

        printf("\n");
    }
#endif

#if 1

    NumberUnion initialValueZero = {.f64 = 0.0};
    NumberUnion initialValueOne = {.f64 = 1.0};
    NumberUnion initialValuePi = {.f64 = M_PI};
    NumberUnion initialValue1000 = {.f64 = 1000};
    float64_t initialValuesData[] = {0.0001, 0.5, 1.0, M_PI, 4.0, 100.0, 1000.0};
    auto initialValues = ReinterpretSpan<NumberUnion>(initialValuesData);

    // Pi added repeatedly.
    // ULP diff for low 314.158447 (439D1448 -> 27 ULP), high 314.159851 (439D1476 -> 19 ULP), even 314.159210 (439D1461 -> 2 ULP)
    // ULP diff for low 414.157867 (43CF1435 -> 46 ULP), high 414.160095 (43CF147E -> 27 ULP), even 414.159454 (43CF1469 -> 6 ULP)
    // ULP diff for low 1314.148438 (44A444C0 -> 89 ULP), high 1314.160156 (44A44520 -> 7 ULP), even 1314.160156 (44A44520 -> 7 ULP)

#if 0 // Random numbers, reduction via serial addition
    std::vector<float64_t> randomValues(100);
    for (auto& r : randomValues)
    {
        r = float64_t(10 * float(rand()) / RAND_MAX);
    }
    size_t randomValueIndex = 0;
    auto f = [&](NumberRounded const& value) -> NumberRounded
    {
        NumberRounded randomValue = {NumberType::Float32As64, NumberUnion{.f64 = randomValues[randomValueIndex]}};
        randomValueIndex = (randomValueIndex + 1) % randomValues.size();
        return value + randomValue;
    };
    ApplyRoundedNumericOperation(100, /*CSV*/ false, NumberType::Float32As64, WrapElementInSpan(initialValueZero), f);
#endif

#if 1 // Random numbers, reduction via pairwise iteration
    std::vector<NumberRounded> randomValues(128);
    for (auto& value : randomValues)
    {
        float64_t r = (float64_t(rand()) / RAND_MAX) * 10;
        NumberUnion nu = {.f64 = float64_t(float32_t(r))};
        value = NumberRounded{NumberType::Float32As64, nu};
    }

    auto f = [&](NumberRounded const& a, NumberRounded const& b) -> NumberRounded
    {
        return a + b;
    };

    //NumberRounded value = {NumberType::Float32As64, initialValueZero};
    //for (auto const& v : randomValues)
    //{
    //    value = value + v;
    //}
    size_t loopIndex = 0;
    while (randomValues.size() > 1)
    {
        printf("%u values\n", uint32_t(randomValues.size()));
        for (size_t valueIndex = 0; valueIndex < randomValues.size(); ++valueIndex)
        {
            NumberRounded& value = randomValues[valueIndex];
            NumberRounded valueCasted = value;
            valueCasted.Cast(NumberType::Float32);
            printf("    "); PrintUlpDifferences(valueIndex, loopIndex, value, valueCasted);
        }

        size_t halfSizeRoundedDown = randomValues.size() / 2u;
        size_t halfSizeRoundedUp = (randomValues.size() + 1) / 2u;
        for (size_t i = 0; i < halfSizeRoundedDown; ++i)
        {
            randomValues[i] = f(randomValues[i], randomValues[i + halfSizeRoundedUp]);
        }
        randomValues.resize(halfSizeRoundedUp);
        ++loopIndex;
    }
    NumberRounded value = randomValues.front();
    NumberRounded valueCasted = value;
    valueCasted.Cast(NumberType::Float32);
    PrintUlpDifferences(/*valueIndex*/ 0, /*loopIndex*/ 0, value, valueCasted);
#endif

#if 0
    auto f = [](NumberRounded const& value) -> NumberRounded
    {
        NumberRounded pi = {NumberType::Float32As64, NumberUnion{.f64 = M_PI}};
        return value + pi;
    };
    ApplyRoundedNumericOperation(100, /*CSV*/ false, NumberType::Float32As64, WrapElementInSpan(initialValueZero), f);
#endif

#if 0
    auto f = [](NumberRounded const& value) -> NumberRounded
    {
        NumberRounded pi = {NumberType::Float32As64, NumberUnion{.f64 = M_PI}};
        return value * pi;
    };
    ApplyRoundedNumericOperation(50, /*CSV*/ false, NumberType::Float32As64, WrapElementInSpan(initialValueOne), f);
#endif

#if 0
    auto f = [](NumberRounded const& value) -> NumberRounded
    {
        NumberRounded scale = {NumberType::Float32As64, NumberUnion{.f64 = 1.001}};
        NumberRounded bias = {NumberType::Float32As64, NumberUnion{.f64 = 1.0}};
        return (value * scale) + bias;
    };
    ApplyRoundedNumericOperation(100, /*CSV*/ true, NumberType::Float32As64, WrapElementInSpan(initialValueOne), f);
#endif

#if 0
    auto f = [](NumberRounded const& value) -> NumberRounded
    {
        NumberRounded output = value;
        auto f = [](auto input) -> decltype(input) {return static_cast<decltype(input)>(sqrt(input));};
        output.ApplyOperationUnary(f);
        return output;
    };
    ApplyRoundedNumericOperation(100, /*CSV*/ true, NumberType::Float32As64, WrapElementInSpan(initialValue1000), f);
#endif

#if 0
    float64_t expValuesData[] = {22.620644348144452, 24.878306448588418, 1.84147599931147, 24.46251196998665, 6.695826149584278};
    auto expValues = ReinterpretSpan<NumberUnion>(expValuesData);

    auto f = [](NumberRounded const& value) -> NumberRounded
    {
        NumberRounded output = value;
        auto f = [](auto input) -> decltype(input) {return static_cast<decltype(input)>(exp(input));};
        output.ApplyOperationUnary(f);
        return output;
    };
    ApplyRoundedNumericOperation(1, /*CSV*/ false, NumberType::Float32As64, expValues, f);
#endif

#if 0
    std::vector<float64_t> v = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0};
    std::span<float64_t const> f = make_span(v);
    auto& nu = CastReferenceAs<std::span<NumberUnion const>>(f);
    ApplyRoundedNumericOperation(1, false, NumberType::Float32As64, nu, [](float64_t& value) {return value = exp(value) * M_PI;});
#endif

#endif

    return EXIT_SUCCESS;
}
