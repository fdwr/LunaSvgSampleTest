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
    Fixed24f12i12 = 17, // TODO: Make naming more consistent. Fixed24f12i12 vs Fixed12_12
    Fixed32f16i16 = 18,
    Fixed32f24i8 = 19,
    Total = 20,
};

// Ensure IEEE format so that bitmasking works as expected.
static_assert(std::numeric_limits<float>::is_iec559);
static_assert(std::numeric_limits<float>::digits == 24);

using Fixed24f12i12 = FixedNumber<int24_t, 12, 12>;
using Fixed32f16i16 = FixedNumber<int32_t, 16, 16>;
using Fixed32f24i8  = FixedNumber<int32_t, 8, 24>;

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
    Fixed24f12i12   x24f12i12;
    Fixed32f16i16   x32f16i16;
    Fixed32f24i8    x32f24i8;

    NumberUnion() : ui64{0} {}
};

struct NumberFormatBitmask
{
    uint64_t fractionMask;
    uint64_t integerMask;
    uint64_t exponentMask;
    uint64_t signMask;
};

NumberUnion RoundTowardZero(NumberUnion numberUnion, NumberFormatBitmask const& bitmask);
NumberUnion RoundTowardInfinity(NumberUnion numberUnion, NumberFormatBitmask const& bitmask);
NumberUnion RoundTowardToNearestEven(NumberUnion numberUnion, NumberFormatBitmask const& bitmask);
void WriteFromDouble(NumberType dataType, double value, /*out*/ void* data);
void WriteToDouble(NumberType dataType, void const* inputData, /*out*/ NumberUnion& number);
NumberFormatBitmask const& GetNumberFormatBitmask(NumberType numberType);

struct NumberRounded
{
    NumberType numberType;
    NumberUnion precise;
    NumberUnion roundedLow;
    NumberUnion roundedHigh;
    NumberUnion roundedEven;

    void SetValue(float64_t value)
    {
        numberType = NumberType::Float64;
        precise.f64 = value;
        roundedLow.f64 = value;
        roundedHigh.f64 = value;
        roundedEven.f64 = value;
    }

    void SetValue(int64_t value)
    {
        numberType = NumberType::Int64;
        precise.i64 = value;
        roundedLow.i64 = value;
        roundedHigh.i64 = value;
        roundedEven.i64 = value;
    }

    void SetValue(NumberType newNumberType, NumberUnion value)
    {
        numberType = newNumberType;
        precise = value;
        roundedLow = value;
        roundedHigh = value;
        roundedEven = value;
    }

    void CopyPreciseToRounded(NumberFormatBitmask const& bitmask)
    {
        roundedLow = precise;
        roundedHigh = precise;
        roundedEven = precise;
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

    void SetToFloat64FromType(NumberType numberType, NumberRounded const& source)
    {
        WriteToDouble(numberType, &source.precise,     /*out*/ precise);
        WriteToDouble(numberType, &source.roundedLow,  /*out*/ roundedLow);
        WriteToDouble(numberType, &source.roundedHigh, /*out*/ roundedHigh);
        WriteToDouble(numberType, &source.roundedEven, /*out*/ roundedEven);
    }

    void SetToTypeFromFloat64(NumberType numberType, NumberRounded const& source)
    {
        WriteFromDouble(numberType, source.precise.f64,     /*out*/ &precise);
        WriteFromDouble(numberType, source.roundedLow.f64,  /*out*/ &roundedLow);
        WriteFromDouble(numberType, source.roundedHigh.f64, /*out*/ &roundedHigh);
        WriteFromDouble(numberType, source.roundedEven.f64, /*out*/ &roundedEven);
    }

    template<typename Functor>
    static void ApplyOperationUnnary(NumberRounded const& a, NumberRounded& output, Functor f)
    {
        f(a.precise,     output.precise);
        f(a.roundedLow,  output.roundedLow);
        f(a.roundedHigh, output.roundedHigh);
        f(a.roundedEven, output.roundedEven);
    }

    template<typename Functor>
    static void ApplyOperationBinary(NumberRounded const& a, NumberRounded const& b, NumberRounded& output, Functor f)
    {
        f(a.precise,     b.precise,     output.precise);
        f(a.roundedLow,  b.roundedLow,  output.roundedLow);
        f(a.roundedHigh, b.roundedHigh, output.roundedHigh);
        f(a.roundedEven, b.roundedEven, output.roundedEven);
    }
};

// Common formats, including some low precision formats expressed in the bit layout of higher precision,
// like float32 in float64 layout.
constexpr NumberFormatBitmask bfloat16NumberMask     = {.fractionMask = (1ULL<<7)-1,       .exponentMask = 0b11111111ULL << 7,     .signMask = 1ULL<<15};
constexpr NumberFormatBitmask float16NumberMask      = {.fractionMask = (1ULL<<10)-1,      .exponentMask = 0b11111ULL << 10,       .signMask = 1ULL<<15};
constexpr NumberFormatBitmask float32NumberMask      = {.fractionMask = (1ULL<<23)-1,      .exponentMask = 0b11111111ULL << 23,    .signMask = 1ULL<<31};
constexpr NumberFormatBitmask float64NumberMask      = {.fractionMask = (1ULL<<52)-1,      .exponentMask = 0b11111111111ULL << 52, .signMask = 1ULL<<63};
constexpr NumberFormatBitmask bfloat16as64NumberMask = {.fractionMask = (1ULL<<(52-7))-1,  .exponentMask = 0b11111111111ULL << 52, .signMask = 1ULL<<63};
constexpr NumberFormatBitmask float16as64NumberMask  = {.fractionMask = (1ULL<<(52-10))-1, .exponentMask = 0b11111111111ULL << 52, .signMask = 1ULL<<63};
constexpr NumberFormatBitmask float32as64NumberMask  = {.fractionMask = (1ULL<<(52-23))-1, .exponentMask = 0b11111111111ULL << 52, .signMask = 1ULL<<63};
constexpr NumberFormatBitmask uint8NumberMask        = {.integerMask  = (1ULL<<8)-1,       .signMask = 0ULL    };
constexpr NumberFormatBitmask uint16NumberMask       = {.integerMask  = (1ULL<<16)-1,      .signMask = 0ULL    };
constexpr NumberFormatBitmask uint32NumberMask       = {.integerMask  = (1ULL<<32)-1,      .signMask = 0ULL    };
constexpr NumberFormatBitmask uint64NumberMask       = {.integerMask  = uint64_t(~0),      .signMask = 0ULL    };
constexpr NumberFormatBitmask int8NumberMask         = {.integerMask  = (1ULL<<7)-1,       .signMask = 1ULL<<7};
constexpr NumberFormatBitmask int16NumberMask        = {.integerMask  = (1ULL<<15)-1,      .signMask = 1ULL<<15};
constexpr NumberFormatBitmask int32NumberMask        = {.integerMask  = (1ULL<<31)-1,      .signMask = 1ULL<<31};
constexpr NumberFormatBitmask int64NumberMask        = {.integerMask  = (1ULL<<63)-1,      .signMask = 1ULL<<63};

// Round toward zero (or truncate).
NumberUnion RoundTowardZero(NumberUnion numberUnion, NumberFormatBitmask const& bitmask)
{
    numberUnion.ui64 &= ~bitmask.fractionMask;
    return numberUnion;
}

// Round toward positive or negative infinity.
NumberUnion RoundTowardInfinity(NumberUnion numberUnion, NumberFormatBitmask const& bitmask)
{
    uint64_t combinedIntegerExponentMask = bitmask.integerMask | bitmask.exponentMask;
    if ((numberUnion.ui64 & combinedIntegerExponentMask) < combinedIntegerExponentMask)
    {
        numberUnion.ui64 |= bitmask.fractionMask;
        assert((bitmask.exponentMask == 0) || (bitmask.exponentMask > bitmask.integerMask)); // If an integer/exponent mask exists, then it should be in the more significant bits relative to the fraction.
        assert((bitmask.integerMask == 0) || (bitmask.integerMask > bitmask.fractionMask)); // If an integer/exponent mask exists, then it should be in the more significant bits relative to the fraction.
        ++numberUnion.ui64;
    }
    return numberUnion;
}

// Round toward positive or negative infinity depending on whichever even value is closer.
NumberUnion RoundTowardToNearestEven(NumberUnion numberUnion, NumberFormatBitmask const& bitmask)
{
    uint64_t value = numberUnion.ui64;
    uint64_t lsbValueMask = (bitmask.fractionMask + 1); // To determine nearest even
    uint64_t halfValue = lsbValueMask >> 1;
    uint64_t roundingBits = value & bitmask.fractionMask;

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
    // else !(value & lsbValueMask)
    {
        // If already even, just truncate.
        numberUnion = RoundTowardZero(numberUnion, bitmask);
    }

    return numberUnion;
}

NumberRounded operator +(NumberRounded const& a, NumberRounded const& b)
{
    NumberRounded result;
    assert(b.numberType == a.numberType);
    result.numberType = a.numberType;

    switch (a.numberType)
    {
    case NumberType::Int64:   NumberRounded::ApplyOperationBinary(a, b, result, [](auto const& a, auto const& b, auto& c){c.i64 = a.i64 + b.i64;});
    case NumberType::Float64: NumberRounded::ApplyOperationBinary(a, b, result, [](auto const& a, auto const& b, auto& c){c.f64 = a.f64 + b.f64;});
    }
    result.Round(GetNumberFormatBitmask(result.numberType));
    return result;
}

NumberRounded operator *(NumberRounded const& a, NumberRounded const& b)
{
    NumberRounded result;
    assert(b.numberType == a.numberType);
    result.numberType = a.numberType;

    switch (a.numberType)
    {
    case NumberType::Int64:   NumberRounded::ApplyOperationBinary(a, b, result, [](auto const& a, auto const& b, auto& c){c.i64 = a.i64 * b.i64;});
    case NumberType::Float64: NumberRounded::ApplyOperationBinary(a, b, result, [](auto const& a, auto const& b, auto& c){c.f64 = a.f64 * b.f64;});
    }
    result.Round(GetNumberFormatBitmask(result.numberType));
    return result;
}

void PrintNumberValues(NumberRounded const& value, NumberType numberType)
{
    switch (numberType)
    {
    case NumberType::Float64:
        printf(
            "float64 precise/rz/ri/rne: %f (%08llX), %f (%08llX), %f (%08llX), %f (%08llX)\n",
            value.precise.f64,
            value.precise.ui64,
            value.roundedLow.f64,
            value.roundedLow.ui64,
            value.roundedHigh.f64,
            value.roundedHigh.ui64,
            value.roundedEven.f64,
            value.roundedEven.ui64
        );
        break;

    case NumberType::Float32:
        printf(
            "float32 precise/rz/ri/rne: %f (%08X), %f (%08X), %f (%08X), %f (%08X)\n",
            value.precise.f32,
            value.precise.ui32,
            value.roundedLow.f32,
            value.roundedLow.ui32,
            value.roundedHigh.f32,
            value.roundedHigh.ui32,
            value.roundedEven.f32,
            value.roundedEven.ui32
        );
        break;

    default:
        printf("Printing type not supported yet\n");
    }
}

// The caller passes a data pointer of the given type.
void WriteFromDouble(NumberType dataType, double value, /*out*/ void* data)
{
    switch (dataType)
    {
    case NumberType::Float32:           *reinterpret_cast<float*>(data) = float(value);             break;
    case NumberType::Uint8:             *reinterpret_cast<uint8_t*>(data) = uint8_t(value);         break;
    case NumberType::Int8:              *reinterpret_cast<int8_t*>(data) = int8_t(value);           break;
    case NumberType::Uint16:            *reinterpret_cast<uint16_t*>(data) = uint16_t(value);       break;
    case NumberType::Int16:             *reinterpret_cast<int16_t*>(data) = int16_t(value);         break;
    case NumberType::Int32:             *reinterpret_cast<int32_t*>(data) = int32_t(value);         break;
    case NumberType::Int64:             *reinterpret_cast<int64_t*>(data) = int64_t(value);         break;
    case NumberType::StringChar8:       /* no change value for strings */                           break;
    case NumberType::Bool8:             *reinterpret_cast<bool*>(data) = bool(value);               break;
    case NumberType::Float16:           *reinterpret_cast<uint16_t*>(data) = half_float::detail::float2half<std::round_to_nearest, float>(float(value)); break;
    case NumberType::Bfloat16:          *reinterpret_cast<bfloat16_t*>(data) = bfloat16_t(float(value)); break;
    case NumberType::Float64:           *reinterpret_cast<double*>(data) = value;                   break;
    case NumberType::Uint32:            *reinterpret_cast<uint32_t*>(data) = uint32_t(value);       break;
    case NumberType::Uint64:            *reinterpret_cast<uint64_t*>(data) = uint64_t(value);       break;
    case NumberType::Complex64:         throw std::invalid_argument("Complex64 type is not supported.");
    case NumberType::Complex128:        throw std::invalid_argument("Complex128 type is not supported.");
    case NumberType::Fixed24f12i12:     *reinterpret_cast<Fixed24f12i12*>(data) = float(value);     break;
    case NumberType::Fixed32f16i16:     *reinterpret_cast<Fixed32f16i16*>(data) = float(value);     break;
    case NumberType::Fixed32f24i8:;     *reinterpret_cast<Fixed32f24i8*>(data) = float(value);      break;
    default:                            assert(false);                                              break;
    }

    // Use half_float::detail::float2half explicitly rather than the half constructor.
    // Otherwise values do not round-trip as expected.
    //
    // e.g. If you print float16 0x2C29, you get 0.0650024, but if you try to parse
    // 0.0650024, you get 0x2C28 instead. Then printing 0x2C28 shows 0.0649414,
    // but trying to parse 0.0649414 returns 0x2C27. Rounding to nearest fixes this.
}

// Just copy a single element from the input to output.
void WriteToDouble(NumberType dataType, void const* inputData, /*out*/ NumberUnion& number)
{
    switch (dataType)
    {
    case NumberType::Float32:       number.f64 = float64_t(*reinterpret_cast<const float32_t*>(inputData));     break;
    case NumberType::Uint8:         number.f64 = float64_t(*reinterpret_cast<const uint8_t*>(inputData));       break;
    case NumberType::Int8:          number.f64 = float64_t(*reinterpret_cast<const int8_t*>(inputData));        break;
    case NumberType::Uint16:        number.f64 = float64_t(*reinterpret_cast<const uint16_t*>(inputData));      break;
    case NumberType::Int16:         number.f64 = float64_t(*reinterpret_cast<const int16_t*>(inputData));       break;
    case NumberType::Int32:         number.f64 = float64_t(*reinterpret_cast<const int32_t*>(inputData));       break;
    case NumberType::Int64:         number.f64 = float64_t(*reinterpret_cast<const int64_t*>(inputData));       break;
    case NumberType::StringChar8:   /* no change value for strings */                                           break;
    case NumberType::Bool8:         number.f64 = float64_t(*reinterpret_cast<const uint8_t*>(inputData));       break;
    case NumberType::Float16:       number.f64 = float64_t(*reinterpret_cast<const float16_t*>(inputData));     break;
    case NumberType::Bfloat16:      number.f64 = float64_t(*reinterpret_cast<const bfloat16_t*>(inputData));    break;
    case NumberType::Float64:       number.f64 = float64_t(*reinterpret_cast<const float64_t*>(inputData));     break;
    case NumberType::Uint32:        number.f64 = float64_t(*reinterpret_cast<const uint32_t*>(inputData));      break;
    case NumberType::Uint64:        number.f64 = float64_t(*reinterpret_cast<const uint64_t*>(inputData));      break;
    case NumberType::Complex64:     throw std::invalid_argument("Complex64 type is not supported.");
    case NumberType::Complex128:    throw std::invalid_argument("Complex128 type is not supported.");
    case NumberType::Fixed24f12i12: number.f64 = float64_t(*reinterpret_cast<const Fixed24f12i12*>(inputData)); break;
    case NumberType::Fixed32f16i16: number.f64 = float64_t(*reinterpret_cast<const Fixed32f16i16*>(inputData)); break;
    case NumberType::Fixed32f24i8:  number.f64 = float64_t(*reinterpret_cast<const Fixed32f24i8*>(inputData));  break;
    default:                        assert(false);                                                              break;
    }
}

NumberFormatBitmask const& GetNumberFormatBitmask(NumberType numberType)
{
    constexpr static NumberFormatBitmask emptyFormatBitmask = {};

    switch (numberType)
    {
    case NumberType::Float32:           return float32as64NumberMask; break;
    case NumberType::Uint8:             assert(false); return emptyFormatBitmask; break;
    case NumberType::Int8:              assert(false); return emptyFormatBitmask; break;
    case NumberType::Uint16:            assert(false); return emptyFormatBitmask; break;
    case NumberType::Int16:             assert(false); return emptyFormatBitmask; break;
    case NumberType::Int32:             assert(false); return emptyFormatBitmask; break;
    case NumberType::Int64:             assert(false); return emptyFormatBitmask; break;
    case NumberType::StringChar8:       assert(false); return emptyFormatBitmask; break;
    case NumberType::Bool8:             assert(false); return emptyFormatBitmask; break;
    case NumberType::Float16:           return float16as64NumberMask; break;
    case NumberType::Bfloat16:          return bfloat16as64NumberMask; break;
    case NumberType::Float64:           return float64NumberMask; break;
    case NumberType::Uint32:            assert(false); return emptyFormatBitmask; break;
    case NumberType::Uint64:            assert(false); return emptyFormatBitmask; break;
    case NumberType::Complex64:         throw std::invalid_argument("Complex64 type is not supported.");
    case NumberType::Complex128:        throw std::invalid_argument("Complex128 type is not supported.");
    case NumberType::Fixed24f12i12:     assert(false); return emptyFormatBitmask; break;
    case NumberType::Fixed32f16i16:     assert(false); return emptyFormatBitmask; break;
    case NumberType::Fixed32f24i8:;     assert(false); return emptyFormatBitmask; break;
    default:                            assert(false); return emptyFormatBitmask; break;
    }
}

void ApplyRoundedNumericOperation(
    uint32_t loopCount,
    bool printForCsv,
    NumberType numberType,
    std::span<NumberUnion const> initialValues,
    std::function<void(float64_t&)> operation
    )
{
    auto floatNumberMask = GetNumberFormatBitmask(numberType);

    for (auto& initialValue : initialValues)
    {
        NumberRounded valueFull = {};
        NumberRounded valueCasted = {};
        NumberRounded valueFullRecasted = {};
        valueFull.SetValue(initialValue.f64);

        if (printForCsv)
        {
            printf("Iteration,Precise Value,Precise Hex,Low Value,Low Hex,Low ULP,High Value,High Hex,High ULP,Even Value,Even Hex,Even ULP\n");
        }
        else
        {
            printf("--------------------------------------------------------------------------------\n");
        }

        for (uint32_t i = 0; i < loopCount; ++i)
        {
            if (!printForCsv)
            {
                printf("Iteration %u\n", i);
            }
            operation(valueFull.precise.f64);
            operation(valueFull.roundedLow.f64);
            operation(valueFull.roundedHigh.f64);
            operation(valueFull.roundedEven.f64);

            if (!printForCsv)
            {
                printf("float64 ");
                PrintNumberValues(valueFull, NumberType::Float64);
            }

            valueFull.Round(floatNumberMask);
            if (!printForCsv)
            {
                printf("rounded ");
                PrintNumberValues(valueFull, NumberType::Float64);
            }

            valueCasted.Zero();
            valueCasted.SetToTypeFromFloat64(numberType, valueFull);
            valueFullRecasted.SetToFloat64FromType(numberType, valueCasted);
            if (!printForCsv)
            {
                printf("float32 ");
                PrintNumberValues(valueCasted, NumberType::Float32);
            }

            uint64_t ulpDiffLow  = abs(valueCasted.precise.i64 - valueCasted.roundedLow.i64);
            uint64_t ulpDiffHigh = abs(valueCasted.precise.i64 - valueCasted.roundedHigh.i64);
            uint64_t ulpDiffEven = abs(valueCasted.precise.i64 - valueCasted.roundedEven.i64);
            if (printForCsv)
            {
                printf(
                    "%f,%08llX,%f,%08llX,%llu,%f,%08llX,%llu,%f,%08llX,%llu\n",
                    valueFullRecasted.precise.f64,
                    valueCasted.precise.ui64,
                    valueFullRecasted.roundedLow.f64,
                    valueCasted.roundedLow.ui64,
                    ulpDiffLow,
                    valueFullRecasted.roundedHigh.f64,
                    valueCasted.roundedHigh.ui64,
                    ulpDiffHigh,
                    valueFullRecasted.roundedEven.f64,
                    valueCasted.roundedEven.ui64,
                    ulpDiffEven
                );
            }
            else
            {
                printf(
                    "ULP diff for precise %f (%08llX), low %f (%08llX -> %llu ULP), high %f (%08llX -> %llu ULP), even %f (%08llX -> %llu ULP)\n"
                    "\n",
                    valueFullRecasted.precise.f64,
                    valueCasted.precise.ui64,
                    valueFullRecasted.roundedLow.f64,
                    valueCasted.roundedLow.ui64,
                    ulpDiffLow,
                    valueFullRecasted.roundedHigh.f64,
                    valueCasted.roundedHigh.ui64,
                    ulpDiffHigh,
                    valueFullRecasted.roundedEven.f64,
                    valueCasted.roundedEven.ui64,
                    ulpDiffEven
                );
            }
        }
    }
}

template<typename T>
std::span<T const> wrap_span(T const& t)
{
    return std::span<T const>(std::addressof(t), size_t(1));
}

template<typename ContainerType, typename T = std::remove_reference_t<decltype(*ContainerType{}.data())>>
std::span<T const> make_span(ContainerType const& container)
{
    return std::span<T const>(container.data(), container.size());
}

template <typename T, typename O>
T& CastReferenceAs(O& o)
{
    return reinterpret_cast<T&>(o);
}

template <typename T, typename O>
const T& CastReferenceAs(O const& o)
{
    return reinterpret_cast<const T&>(o);
}

int main(int argc, char* argv[])
{
    NumberUnion initialValueZero; initialValueZero.f64 = 0.0;
    NumberUnion initialValueOne;  initialValueOne.f64 = 1.0;
    NumberUnion initialValuePi;   initialValuePi.f64 = M_PI;

    // Pi added repeatedly.
    // ULP diff for low 314.158447 (439D1448 -> 27 ULP), high 314.159851 (439D1476 -> 19 ULP), even 314.159210 (439D1461 -> 2 ULP)
    // ULP diff for low 414.157867 (43CF1435 -> 46 ULP), high 414.160095 (43CF147E -> 27 ULP), even 414.159454 (43CF1469 -> 6 ULP)
    // ULP diff for low 1314.148438 (44A444C0 -> 89 ULP), high 1314.160156 (44A44520 -> 7 ULP), even 1314.160156 (44A44520 -> 7 ULP)

#if 1
    ApplyRoundedNumericOperation(100, /*CSV*/ false, NumberType::Float32, wrap_span(initialValueZero), [](float64_t& value) {return value += M_PI;});
#endif
#if 0
    ApplyRoundedNumericOperation(50, /*CSV*/ true, NumberType::Float32, wrap_span(initialValueOne),  [](float64_t& value) {return value *= M_PI;});
#endif
#if 0
    ApplyRoundedNumericOperation(100, /*CSV*/ true, NumberType::Float32, wrap_span(initialValueOne),  [](float64_t& value) {return value = (value * 1.001) + 1.0;});
#endif
#if 0
    ApplyRoundedNumericOperation(100, /*CSV*/ false, NumberType::Float32, wrap_span(initialValuePi),  [](float64_t& value) {return value = sqrt(value);});
#endif
#if 0
    ApplyRoundedNumericOperation(100, /*CSV*/ false, NumberType::Float32, wrap_span(initialValuePi), [](float64_t& value) {return value = exp(value); });
#endif
#if 0
    std::vector<float64_t> v = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0};
    std::span<float64_t const> f = make_span(v);
    auto& nu = CastReferenceAs<std::span<NumberUnion const>>(f);
    ApplyRoundedNumericOperation(1, false, NumberType::Float32, nu, [](float64_t& value) {return value = exp(value) * M_PI;});
#endif

    return EXIT_SUCCESS;
}
