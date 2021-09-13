//+---------------------------------------------------------------------------
//
//  Copyright (c) Microsoft, 2008. All rights reserved.
//
//  Contents:   Inline image for text layouts.
//
//----------------------------------------------------------------------------
#include "precomp.h"


InlineImage::InlineImage(
    IWICBitmapSource* image,
    unsigned int index,
    bool wantBaselineCentered
    )
    :   image_(image),
        wantBaselineCentered_(wantBaselineCentered)
{
    // This form is useful for toolbar icons, where we don't want to load a ton
    // of little images, nor do we want to remember precise coordinates.
    // Instead, just pass the index, and (given the assumption that toolbar
    // icons are almost always square) it will calculate the location for you.
    UINT imageWidth = 0, imageHeight = 0;

    if (image != NULL)
        image->GetSize(&imageWidth, &imageHeight);

    bool isVertical = imageHeight > imageWidth;
    float size = isVertical ? float(imageWidth) : float(imageHeight);
    rect_.w = size;
    rect_.h = size;

    float offset = index * size;
    rect_.x = isVertical ? 0 : offset;
    rect_.y = isVertical ? offset : 0;

    baseline_ = rect_.h;
}


void InlineImage::CenterBaselineIfNeeded(IDWriteTextLayout* textLayout, UINT32 textPosition)
{
    if (!wantBaselineCentered_)
        return; // have an explicit baseline, so do nothing

    DWRITE_TEXT_METRICS textMetrics;
    textLayout->GetMetrics(&textMetrics);
    UINT32 lineCount = textMetrics.lineCount;
    if (lineCount <= 0)
        return; // nothing to center

    // Retrieve the line metrics to know where the baseline is.
    std::vector<DWRITE_LINE_METRICS> lineMetrics(lineCount);
    textLayout->GetLineMetrics(&lineMetrics.front(), lineCount, &lineCount);

    // Find which line the given position is on.
    UINT32 matchingLine = 0;
    UINT32 nextPosition = 0;
    for (UINT32 i = 0; i < lineCount; i++)
    {
        nextPosition += lineMetrics[i].length;
        if (textPosition < nextPosition)
        {
            matchingLine = i;
            break;
        }
    }

    float height = lineMetrics[matchingLine].height;
    float baseline = lineMetrics[matchingLine].baseline;

    // Center image's baseline, flooring the result, since otherwise
    // we can get blurry images if it yields a fractional offset.
    baseline_ = (height - rect_.h) / -2 + baseline;
}


HRESULT STDMETHODCALLTYPE InlineImage::Draw(
    __maybenull void* clientDrawingContext,
    IDWriteTextRenderer* renderer,
    FLOAT originX,
    FLOAT originY,
    BOOL isSideways,
    BOOL isRightToLeft,
    IUnknown* clientDrawingEffect
    )
{
    // Go from the text renderer interface back to the actual render target.
    ComPtr<RenderTarget> renderTarget;
    renderer->QueryInterface(UUIDOF(RenderTarget), reinterpret_cast<void**>(&renderTarget));

    Position destRect = {originX, originY, rect_.w, rect_.h};
    renderTarget->DrawImage(image_, rect_, destRect);

    return S_OK;
}


HRESULT STDMETHODCALLTYPE InlineImage::GetMetrics(
    __out DWRITE_INLINE_OBJECT_METRICS* metrics
    )
{
    DWRITE_INLINE_OBJECT_METRICS inlineMetrics = {0};
    inlineMetrics.width = rect_.w;
    inlineMetrics.height = rect_.h;
    inlineMetrics.baseline = baseline_;
    *metrics = inlineMetrics;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE InlineImage::GetOverhangMetrics(
    __out DWRITE_OVERHANG_METRICS* overhangs
    )
{
    overhangs->left      = 0;
    overhangs->top       = 0;
    overhangs->right     = 0;
    overhangs->bottom    = 0;
    return S_OK;
}


HRESULT STDMETHODCALLTYPE InlineImage::GetBreakConditions(
    __out DWRITE_BREAK_CONDITION* breakConditionBefore,
    __out DWRITE_BREAK_CONDITION* breakConditionAfter
    )
{
    *breakConditionBefore = DWRITE_BREAK_CONDITION_NEUTRAL;
    *breakConditionAfter  = DWRITE_BREAK_CONDITION_NEUTRAL;
    return S_OK;
}
