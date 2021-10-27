//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2009. All rights reserved.
//
//  Contents:   Inline image for text layouts.
//
//----------------------------------------------------------------------------
#pragma once


struct IWICBitmapSource;


class DECLSPEC_UUID("1DE84D4E-1AD2-40ec-82B3-1B5B93471C65") InlineImage
    :   public ComBase<
            QiListSelf<InlineImage,
            QiList<IDWriteInlineObject
        > > >
{
public:
    InlineImage(
        IWICBitmapSource* image,
        unsigned int index
        );

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

    static HRESULT LoadImageFromResource(
        const wchar_t* resourceName,
        const wchar_t* resourceType,
        IWICImagingFactory* wicFactory,
        __out IWICBitmapSource** bitmap
        );

protected:
    ComPtr<IWICBitmapSource> image_;
    RectF rect_; // coordinates in image, similar to index of HIMAGE_LIST
    float baseline_;
};
