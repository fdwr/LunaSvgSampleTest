//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Inline image for text layouts.
//
//----------------------------------------------------------------------------
#pragma once


struct IWICBitmapSource;


class DECLSPEC_UUID("1DE84D4E-1AD2-40ec-82B3-1B5B93471C65") InlineImage : public ComBase<IDWriteInlineObject>
{
public:
    InlineImage(
        IWICBitmapSource* image,
        const Position& rect,
        float baseline
        )
        :   image_(image),
            rect_(rect),
            baseline_(baseline),
            wantBaselineCentered_(false)
    { }

    InlineImage(
        IWICBitmapSource* image,
        unsigned int index,
        bool wantBaselineCentered = true
        );

    // Centers the image's baseline vertically to the given position in the
    // layout, if no explicit baseline was given.
    void CenterBaselineIfNeeded(IDWriteTextLayout* textLayout, UINT32 textPosition);

    STDMETHOD(Draw)(
        __maybenull void* clientDrawingContext,
        IDWriteTextRenderer* renderer,
        FLOAT originX,
        FLOAT originY,
        BOOL isSideways,
        BOOL isRightToLeft,
        IUnknown* clientDrawingEffect
        ) OVERRIDE;

    STDMETHOD(GetMetrics)(
        __out DWRITE_INLINE_OBJECT_METRICS* metrics
        ) OVERRIDE;

    STDMETHOD(GetOverhangMetrics)(
        __out DWRITE_OVERHANG_METRICS* overhangs
        ) OVERRIDE;

    STDMETHOD(GetBreakConditions)(
        __out DWRITE_BREAK_CONDITION* breakConditionBefore,
        __out DWRITE_BREAK_CONDITION* breakConditionAfter
        ) OVERRIDE;

    STDMETHOD(QueryInterface)(IID const& iid, __out void** object) OVERRIDE
    {
        COM_BASE_RETURN_INTERFACE(iid, InlineImage, object);
        COM_BASE_RETURN_INTERFACE(iid, IDWriteInlineObject, object);
        COM_BASE_RETURN_INTERFACE(iid, IUnknown, object);
        COM_BASE_RETURN_NO_INTERFACE(object);
    }

protected:
    ComPtr<IWICBitmapSource> image_;
    Position rect_; // coordinates in image, similar to index of HIMAGE_LIST
    float baseline_;
    bool wantBaselineCentered_; // explicit baseline supplied, so don't mess with it
};
