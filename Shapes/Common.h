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
