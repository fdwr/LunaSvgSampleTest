//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Render target for controls to draw to.
//
//----------------------------------------------------------------------------
#pragma once


class DECLSPEC_UUID("1CD7C44F-526B-492a-B780-EF9C4159B653") DrawingEffect
    :   public ComBase<
            QiList<IUnknown>
        >
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

    static inline UINT32 SwapRgb(UINT32 color) throw()
    {
        // Swaps bgra <-> rgba for usage by GDI vs D2D/GDI+.
        return (color & 0xFF000000) | RGB(GetBValue(color), GetGValue(color), GetRValue(color));
    }

protected:
    // The color is stored as BGRA, with blue in the lowest byte,
    // then green, blue, alpha; which is what D2D and GDI+ use.
    // GDI's COLORREF stores red as the lowest byte.
    UINT32 color_;
};
