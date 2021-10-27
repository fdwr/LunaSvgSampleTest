//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Render target for controls to draw to.
//
//----------------------------------------------------------------------------
#pragma once


class DECLSPEC_UUID("1CD7C44F-526B-492a-B780-EF9C4159B653") DrawingEffect : public ComBase<IUnknown>
{
public:
    DrawingEffect(
        UINT32 color
        )
    :   color_(color)
    { }

    inline UINT32 GetColor() const throw()
    {
        return color_;
    }

    STDMETHOD(QueryInterface)(IID const& iid, __out void** object) OVERRIDE
    {
        COM_BASE_RETURN_INTERFACE(iid, DrawingEffect, object);
        COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
        COM_BASE_RETURN_NO_INTERFACE(object);
    }

protected:
    UINT32 color_;
};
