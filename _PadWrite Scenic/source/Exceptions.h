//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Common exceptions.
//
//----------------------------------------------------------------------------


class HrException : public std::exception
{
public:
    typedef std::exception Base;

    HrException(HRESULT hr, const char* message)
        :   Base(message),
            hr_(hr)
    { }

    inline HRESULT GetErrorCode()
    {
        return hr_;
    }

    inline static void IfFailed(HRESULT hr, const char* message)
    {
        // Throws if the given HRESULT failed.
        if (FAILED(hr))
            throw HrException(hr, message);
    }

    inline static void IfFailed(HRESULT hr)
    {
        // Throws if the given HRESULT failed.
        if (FAILED(hr))
            throw HrException(hr, "API error");
    }

protected:
    HRESULT hr_;
};
