#pragma once

/******************************************************************
*                                                                 *
*  Macros                                                         *
*                                                                 *
******************************************************************/


namespace DWritePad { namespace Exception 
{
    class ExceptionBase : public std::exception
    {
    protected:
        ExceptionBase() {}

    public:
        virtual HRESULT GetHResult() = 0;
    };

    class BadHResultException : public ExceptionBase
    {
    private:
        const HRESULT hr_;

    public:
        BadHResultException(HRESULT hr)
            : hr_(hr)
        {
        }

        HRESULT GetHResult()
        {
            return hr_;
        }
    };

    template <HRESULT hResult>
    class OperationFailureException : public ExceptionBase
    {
    public:
        HRESULT GetHResult()
        {
            return hResult;
        }
    };

} }

namespace DWritePad { namespace ErrorCheck { 

void ThrowIfFailedHR(HRESULT hr);

} }