#pragma once

using Microsoft::WRL::ComPtr;

////////////////////////////////////////////////////////////////////////////////
// Generic application-agnostic helper functions

#define RETURN_IF(expression, returnValue) if (expression) return (returnValue);
#define RETURN_IF_FAILED(expression) {auto hr_ = (expression); if (FAILED(hr_)) {return hr_;}}
#define RETURN_IF_FAILED_V(expression, returnValue) if (FAILED(expression)) return (returnValue);

// Union of D2D and DWrite's matrix to facilitate
// usage between them, while not breaking existing
// applications that use one or the other.
union Matrix3x2f
{
    // Explicity named fields for clarity.
    struct
    {
        FLOAT xx; // x affects x (horizontal scaling / cosine of rotation)
        FLOAT xy; // x affects y (vertical shear     / sine of rotation)
        FLOAT yx; // y affects x (horizontal shear   / negative sine of rotation)
        FLOAT yy; // y affects y (vertical scaling   / cosine of rotation)
        FLOAT dx; // displacement of x, always orthogonal regardless of rotation
        FLOAT dy; // displacement of y, always orthogonal regardless of rotation
    };
    struct // D2D Win7
    {
        FLOAT _11;
        FLOAT _12;
        FLOAT _21;
        FLOAT _22;
        FLOAT _31;
        FLOAT _32;
    };
    struct // DWrite Win7
    {
        FLOAT m11;
        FLOAT m12;
        FLOAT m21;
        FLOAT m22;
        FLOAT m31;
        FLOAT m32;
    };
    float m[6]; // Would [3][2] be better, more useful?

    __if_exists(DWRITE_MATRIX)
    {
        DWRITE_MATRIX dwrite;
    }
    __if_exists(D2D1_MATRIX_3X2_F)
    {
        D2D1_MATRIX_3X2_F d2d;
    }
    __if_exists(XFORM)
    {
        XFORM gdi;
    }
    __if_exists(DXGI_MATRIX_3X2_F)
    {
        DXGI_MATRIX_3X2_F dxgi;
    }
};

void ComputeInverseMatrix(
    _In_  Matrix3x2f const& matrix,
    _Out_ Matrix3x2f& result
);

float GetDeterminant(_In_ Matrix3x2f const& matrix);

// Redefine the bitmap header structs so inheritance works.
// Who needlessly prefixed every field with {bi, bc, bv5} so that generic
// code could not work with different versions of the structs? (sigh, face palm)
struct BITMAPHEADERv2 // BITMAPCOREHEADER
{
    DWORD        size;
    WORD         width;
    WORD         height;
    WORD         planes;
    WORD         bitCount;
};

struct BITMAPHEADERv3 // BITMAPINFOHEADER (not v3 is not backwards compatible with v2, as the width/height are LONG)
{
    DWORD        size;
    LONG         width;
    LONG         height;
    WORD         planes;
    WORD         bitCount;
    DWORD        compression;
    DWORD        sizeImage;
    LONG         xPelsPerMeter;
    LONG         yPelsPerMeter;
    DWORD        clrUsed;
    DWORD        clrImportant;
};

struct BITMAPHEADERv4 : BITMAPHEADERv3 // BITMAPV4HEADER
{
    DWORD        redMask;
    DWORD        greenMask;
    DWORD        blueMask;
    DWORD        alphaMask;
    DWORD        csType;
    CIEXYZTRIPLE endpoints;
    DWORD        gammaRed;
    DWORD        gammaGreen;
    DWORD        gammaBlue;
};

struct BITMAPHEADERv5 : BITMAPHEADERv4 // BITMAPV5HEADER
{
    DWORD        intent;
    DWORD        profileData;
    DWORD        profileSize;
    DWORD        reserved;
};

template <typename OriginalType, typename TargetType = OriginalType>
TargetType* AddByteOffset(OriginalType* p, size_t byteOffset) noexcept
{
    return reinterpret_cast<TargetType*>(reinterpret_cast<uint8_t*>(p) + byteOffset);
}

template <typename OriginalType, typename TargetType = OriginalType>
TargetType const* AddByteOffset(OriginalType const* p, size_t byteOffset) noexcept
{
    return reinterpret_cast<TargetType const*>(reinterpret_cast<uint8_t const*>(p) + byteOffset);
}

template<typename VariantType, typename T, std::size_t index = 0>
constexpr std::size_t variant_index()
{
    if constexpr (index == std::variant_size_v<VariantType>)
    {
        return index;
    }
    else if constexpr (std::is_same_v<std::variant_alternative_t<index, VariantType>, T>)
    {
        return index;
    }
    else
    {
        return variant_index<VariantType, T, index + 1>();
    }
}

// Why does std::variant have such an idiotic interface, with no intuitive get() or index_of_type() methods?
// So, we'll fix it with a more logical interface.
template <typename... Ts>
class variantex : public std::variant<Ts...>
{
public:
    using base = std::variant<Ts...>;

    using base::base;

    template<typename T>
    T& get()
    {
        return std::get<T>(*this);
    }

    template<typename T>
    bool is_type() const
    {
        return std::holds_alternative<T>(*this);
    }

    template<typename T>
    constexpr static size_t index_of_type()
    {
        return variant_index<base, T>();
    }

    template<typename T>
    void call(T& t)
    {
        base& b = *this;
        std::visit(t, b);
    }
};

template <typename FunctorType>
struct DeferCleanupType
{
public:
    explicit DeferCleanupType(FunctorType const& f) : f_(f) {}
    ~DeferCleanupType() { f_(); }

private:
    FunctorType f_;
};

template <typename FunctorType>
DeferCleanupType<FunctorType> inline DeferCleanup(FunctorType const& f) { return DeferCleanupType<FunctorType>(f); }

template <typename FunctorType>
struct DismissableCleanupType
{
public:
    explicit DismissableCleanupType(FunctorType const& f) : f_(f) {}
    ~DismissableCleanupType() { if (!isDismissed_) f_(); }
    void Dismiss() { isDismissed_ = true; }

private:
    FunctorType f_;
    bool isDismissed_ = false;
};

template <typename FunctorType>
DismissableCleanupType<FunctorType> inline DismissableCleanup(FunctorType const& f) { return DismissableCleanupType<FunctorType>(f); }
