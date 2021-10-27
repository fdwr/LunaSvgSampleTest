// Include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
#pragma once


////////////////////////////////////////
// Basic application execution functions:

template<typename T> void ZeroStructure(T& structure)
{
    memset(&structure, 0, sizeof(T));
}

bool TestBit(void const* memoryBase, size_t bitIndex) throw();
bool ClearBit(void* memoryBase, size_t bitIndex) throw();
bool SetBit(void* memoryBase, size_t bitIndex) throw();


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


HRESULT ReadTextFile(const wchar_t* filename, OUT std::wstring& text);
HRESULT ReadBinaryFile(const wchar_t* filename, OUT std::vector<uint8_t>& fileBytes);
HRESULT CopyToClipboard(const std::wstring& text);
HRESULT PasteFromClipboard(OUT std::wstring& text);

void TrimSpaces(IN OUT std::wstring& text);
