//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Common exceptions.
//
//----------------------------------------------------------------------------


class OsException : public std::exception
{
public:
    typedef std::exception Base;

    OsException(const char* message, HRESULT hr)
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
            throw OsException(message, hr);
    }

protected:
    HRESULT hr_;
};
