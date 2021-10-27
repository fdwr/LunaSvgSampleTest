//+---------------------------------------------------------------------------
//
//  File:       FontFaceHelpers.cpp
//
//  Author:     Dwayne Robinson (dwayner@microsoft.com)
//
//  History:    2013-10-24  dwayner     Adapted to FontCommandTool
//
//----------------------------------------------------------------------------
#pragma once


class CheckedFontPtrException : public std::exception
{
public:
    typedef std::exception Base;

    CheckedFontPtrException(void const* p)
        :   Base("Font file format has invalid sizes or offsets."),
            p_(p)
    { }

protected:
    const void* p_;
};


class FontCheckedPtr : public CheckedPtr<uint8_t, CheckedFontPtrException, uint32_t>
{
public:
    typedef CheckedPtr<uint8_t, CheckedFontPtrException, uint32_t> Base;
    typedef FontCheckedPtr Self;

    explicit FontCheckedPtr()
    { }

    explicit FontCheckedPtr(void* tableData, uint32_t tableSize)
        :   Base(reinterpret_cast<uint8_t*>(tableData), tableSize)
    { }

    explicit FontCheckedPtr(void* dataBegin, void* dataEnd)
        :   Base(reinterpret_cast<uint8_t*>(dataBegin), reinterpret_cast<uint8_t*>(dataEnd))
    {
        assert(dataBegin <= dataEnd);
    }

    template <typename T>
    FontCheckedPtr(array_ref<T> array)
        :   Base(array.begin(), array.end())
    {
        assert(array.begin() <= array.end());
    }

    FontCheckedPtr(byte_array_ref array)
    :   Base(array.begin(), array.end())
    {
        assert(array.begin() <= array.end());
    }
};


class FontTablePtr : public FontCheckedPtr
{
public:
    typedef FontCheckedPtr Base;
    typedef FontTablePtr Self;

    explicit FontTablePtr(
        IDWriteFontFace* fontFace,
        uint32_t openTypeTableTag
        );
        
    ~FontTablePtr();

protected:
    ComPtr<IDWriteFontFace> fontFace_;
    void* tableContext_ = nullptr;

private:
    Self(Self const&);
    Self& operator=(Self const&);
};
