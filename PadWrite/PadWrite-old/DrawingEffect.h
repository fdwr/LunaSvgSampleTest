//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Drawing effect that holds a single color.
//
//----------------------------------------------------------------------------
#pragma once


class DECLSPEC_UUID("1CD7C44F-526B-492a-B780-EF9C4159B653") DrawingEffect
:   public ComBase<QiList<IUnknown> >
{
public:
    DrawingEffect(UINT32 color)
    :   color_(color)
    { }

    inline UINT32 GetColor() const throw()
    {
        // Returns the BGRA value for D2D.
        return color_;
    }

    inline COLORREF GetColorRef() const throw()
    {
        // Swaps color order (bgra <-> rgba) from D2D/GDI+'s to GDI's.
        // This also leaves the top byte 0, since alpha is ignored anyway.
        return RGB(GetBValue(color_), GetGValue(color_), GetRValue(color_));
    }

protected:
    // The color is stored as BGRA, with blue in the lowest byte,
    // then green, blue, alpha; which is what D2D and GDI+ use.
    // GDI's COLORREF stores red as the lowest byte.
    UINT32 color_;
};
