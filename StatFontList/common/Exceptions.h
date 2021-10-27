#pragma once


class OsException : public std::exception
{
public:
    typedef std::exception Base;

    OsException(HRESULT hr, const char* message)
        :   Base(message),
            hr_(hr)
    { }

    inline HRESULT GetErrorCode()
    {
        return hr_;
    }

    static void ThrowOnFailure(HRESULT hr, const char* message)
    {
        if (FAILED(hr))
            throw OsException(hr, message);
    }

protected:
    HRESULT hr_;
};


class CheckedPtrException : OsException
{
public:
    typedef OsException Base;

    CheckedPtrException(const void* p)
        :   Base(E_POINTER, "Pointer out of range."),
            p_(p)
    { }

protected:
    const void* p_;
};


class FileFormatException : OsException
{
public:
    typedef OsException Base;

    FileFormatException()
        :   Base(DWRITE_E_FILEFORMAT, "File format exception.")
    { }
};
